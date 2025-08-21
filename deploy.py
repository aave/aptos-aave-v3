#!/usr/bin/env python3

import argparse
import json
import logging
import os
import pathlib
import subprocess
import tempfile
from datetime import datetime, UTC
from threading import Thread, Lock
from typing import Optional, List, Dict, Tuple, IO, AnyStr

APTOS_BIN = "aptos"
PROJECT_DIR = pathlib.Path(__file__).parent.resolve()

#
# Utilities to execute a command and also log its output
#


class AtomicBool:
    """
    A minimal atomic boolean implementation
    """

    def __init__(self) -> None:
        self.flag = False
        self.lock = Lock()

    def set(self) -> None:
        with self.lock:
            self.flag = True

    def get(self) -> bool:
        with self.lock:
            return self.flag


def _poll_stream(tag: str, stream: IO[AnyStr], completed: AtomicBool) -> List[str]:
    output = []
    while not completed.get():
        for line in stream:
            line = line.rstrip()
            logging.debug(f"[{tag}] {line}")
            output.append(line)
    return output


class StreamPollingThread(Thread):
    """
    A thread that automatically polls an IO stream and also accumulates the text
    """

    def __init__(self, tag: str, stream: IO[AnyStr], completed: AtomicBool):
        Thread.__init__(self, target=_poll_stream, args=(tag, stream, completed))
        self._return = None

    def run(self):
        if self._target is not None:
            self._return = self._target(*self._args, **self._kwargs)

    def join(self, *args) -> List[str]:
        Thread.join(self, *args)
        return self._return


def _checked_execute(
    command: List[str],
    cwd: Optional[str | pathlib.Path] = None,
) -> Tuple[List[str], List[str]]:
    # log the command
    logging.debug(f"Executing command: {command}")

    # start the process
    kwargs = {}
    if cwd is not None:
        kwargs["cwd"] = cwd

    proc = subprocess.Popen(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        universal_newlines=True,
        **kwargs,
    )
    flag = AtomicBool()

    # spawn threads to read the streams
    thread_stdout = StreamPollingThread("stdout", proc.stdout, flag)
    thread_stdout.start()
    thread_stderr = StreamPollingThread("stderr", proc.stderr, flag)
    thread_stderr.start()

    # wait for the completion of the process
    proc.wait()

    # inform the threads to stop
    flag.set()
    captured_stdout = thread_stdout.join()
    captured_stderr = thread_stderr.join()

    # raise an exception if the command fails
    if proc.returncode != 0:
        raise subprocess.CalledProcessError(
            returncode=proc.returncode,
            cmd=command,
            output="\n".join(captured_stdout),
            stderr="\n".join(captured_stderr),
        )

    # return the outputs
    return captured_stdout, captured_stderr


#
# Generic publication logic
#


def clear_staging_area(
    deployer: str,
    fullnode: str,
    multisig_address: Optional[str] = None,
    large_packages_module_address: Optional[str] = None,
) -> None:
    """
    Clear the staging area for chunked publication

    :param deployer: profile name of the account who initializes the deployment
    :param fullnode: fullnode URL of the chain
    :param multisig_address: multisig address of the account (if needed)
    :param large_packages_module_address: large packages module address
    """

    if multisig_address is None:
        commands = [
            APTOS_BIN,
            "move",
            "clear-staging-area",
            "--profile",
            deployer,
            "--url",
            fullnode,
        ]
    else:
        commands = [
            APTOS_BIN,
            "multisig",
            "create-transaction",
            "--multisig-address",
            multisig_address,
            "--profile",
            deployer,
            "--url",
            fullnode,
            "--sender-account",
            deployer,
            "--function-id",
            f"{large_packages_module_address}::large_packages::cleanup_staging_area",
        ]
    _checked_execute(commands, cwd=PROJECT_DIR)


def _get_deployed_address(package_name: str) -> str:
    """
    Retrieve the deployed (object) address of a package

    :param package_name: name of the package
    :return: address of the deployed package
    """
    with open(PROJECT_DIR / f"deploy-{package_name}-object.txt", "r") as f:
        return f.read().strip()


def _set_deployed_address(package_name: str, deployed_address: str) -> None:
    """
    Store the deployed (object) address of a package in a file

    :param package_name: name of the package
    :param deployed_address: address of the deployed package
    """
    with open(PROJECT_DIR / f"deploy-{package_name}-object.txt", "w") as f:
        f.write(deployed_address)


def _publish(
    deployer: str,
    fullnode: str,
    upgrade: bool,
    package_path: str | pathlib.Path,
    address_name: str,
    object_named_addresses: List[str],
    preset_named_addresses: Optional[Dict[str, str]] = None,
    chunked_publish: bool = False,
    max_gas: Optional[int] = 100_0000,
    fetch_latest_git_deps: bool = False,
) -> None:
    """
    Publish a Move package on-chain via the deploy-object model

    :param deployer: profile name of the account who initializes the deployment
    :param fullnode: fullnode URL of the chain
    :param upgrade: whether this is to publish a new package or upgrade an existing one
    :param package_path: local filesystem path of the package to be published
    :param address_name: the main named address of the package
    :param object_named_addresses: dependencies that are previously deployed as objects
    :param preset_named_addresses: other named addresses needed to build the package
    :param chunked_publish: whether to publish in chunks or in one transaction
    :param max_gas: if set, limit gas consumption but also skip local simulation
    """

    # log the action
    logging.info(
        f"Starting to %s package %s",
        "upgrade" if upgrade else "publish",
        address_name,
    )

    # build the command
    named_address_list = [
        "{}={}".format(i, _get_deployed_address(i)) for i in object_named_addresses
    ]
    if preset_named_addresses is not None:
        named_address_list.extend(
            [f"{k}={v}" for k, v in preset_named_addresses.items()]
        )

    commands = [
        APTOS_BIN,
        "move",
        "upgrade-object" if upgrade else "deploy-object",
        "--profile",
        deployer,
        "--url",
        fullnode,
        "--included-artifacts",
        "sparse",
        "--address-name",
        address_name,
    ]
    if upgrade:
        commands.extend(["--object-address", _get_deployed_address(address_name)])
    if len(named_address_list) != 0:
        commands.extend(["--named-addresses", ",".join(named_address_list)])

    if chunked_publish:
        commands.append("--chunked-publish")
    if max_gas is not None:
        commands.extend(["--max-gas", str(max_gas)])
    if not fetch_latest_git_deps:
        commands.append("--skip-fetch-latest-git-deps")

    # execute the deployment
    output, _ = _checked_execute(commands, cwd=package_path)

    # parse the output only on publishing
    if upgrade:
        needle = "Code was successfully upgraded at object address "
    else:
        needle = "Code was successfully deployed to object address "

    deployed_address = None
    for line in output:
        line = line.lstrip()
        if line.startswith(needle):
            # rare case, just to be caution
            if deployed_address is not None:
                raise RuntimeError(
                    f"Package {address_name} is deployed "
                    f"but we find more than one deployment addresses in the output"
                )
            deployed_address = line.removeprefix(needle)

    if deployed_address is None:
        raise RuntimeError(
            f"Package {address_name} is deployed "
            f"but we are unable to find deployment address in the output"
        )

    # set the deployment address
    if upgrade:
        assert deployed_address == _get_deployed_address(address_name)
        logging.info("Package '%s' upgraded at %s", address_name, deployed_address)
    else:
        _set_deployed_address(address_name, deployed_address)
        logging.info("Package '%s' deployed at %s", address_name, deployed_address)


def _create_chunks(data: bytes, chunk_size: int) -> List[bytes]:
    """
    Split bytes (byte array) into chunks of requested sizes

    :param data: bytes or bytes array
    :param chunk_size: desired chunk size
    :return: a list of chunks (in bytes)
    """

    total_size = len(data)
    accumulated = 0
    result = []
    while accumulated < total_size:
        chunk = data[accumulated : accumulated + chunk_size]
        result.append(chunk)
        accumulated += chunk_size
    return result


def _large_packages_stage_code_chunk_via_multisig(
    deployer: str,
    fullnode: str,
    multisig_address: str,
    metadata_chunk: bytes,
    code_indices: List[int],
    code_chunks: List[bytes],
    large_packages_module_address: str,
) -> None:
    """
    Stage metadata and/or code chunks via multisig

    :param deployer: profile name of the deployer
    :param fullnode: fullnode URL of the chain
    :param multisig_address: address of the multisig account
    :param metadata_chunk: metadata chunk bytes to be staged, if any
    :param code_indices: code indices to be staged, if any
    :param code_chunks: code chunks to be staged, if any
    :param large_packages_module_address: address of the large packages module
    """

    commands = [
        APTOS_BIN,
        "multisig",
        "create-transaction",
        "--multisig-address",
        multisig_address,
        "--profile",
        deployer,
        "--url",
        fullnode,
        "--sender-account",
        deployer,
        "--function-id",
        f"{large_packages_module_address}::large_packages::stage_code_chunk",
        "--args",
        "u8:[]" if len(metadata_chunk) == 0 else "hex:0x" + metadata_chunk.hex(),
        "u16:[{}]".format(",".join([str(i) for i in code_indices])),
        "hex:[{}]".format(
            ",".join(['"0x' + code_chunk.hex() + '"' for code_chunk in code_chunks])
        ),
    ]
    _checked_execute(commands, cwd=PROJECT_DIR)


def _execute_multisig_chunked_upgrade_workflow(
    deployer: str,
    fullnode: str,
    owner_multisig: str,
    object_address: str,
    tx_json: str | pathlib.Path,
    chunk_size: int,
    large_packages_module_address: str,
) -> int:
    """
    Upgrade a package (deployer at an object address that is owned by a multisig account)
    via chynked publishing

    :param deployer: profile name of the deployer
    :param fullnode: fullnode URL of the chain
    :param owner_multisig: address of the multisig account that owns the package
    :param object_address: address of the object address that hosts the package
    :param tx_json: path to the transaction json file that holds the transaction
    :param chunk_size: desired chunk size
    :param large_packages_module_address: address of the large packages module
    :return: number of multisig transactions sequenced
    """

    with open(tx_json, "r") as f:
        tx_details = json.load(f)

    # sanity checks
    assert tx_details["function_id"] == "0x1::code::publish_package_txn"
    assert len(tx_details["args"]) == 2

    # chunks the metadata
    arg0 = tx_details["args"][0]
    assert arg0["type"] == "hex"
    assert arg0["value"].startswith("0x")
    metadata = bytes.fromhex(arg0["value"].removeprefix("0x"))
    metadata_chunks = _create_chunks(metadata, chunk_size)

    # special handling for last metadata chunk
    last_metadata_chunk = metadata_chunks.pop()

    # stage metadata chunks first
    counter = 0
    for chunk in metadata_chunks:
        logging.debug("staging chunk %d", counter)
        _large_packages_stage_code_chunk_via_multisig(
            deployer,
            fullnode,
            owner_multisig,
            chunk,
            [],
            [],
            large_packages_module_address,
        )
        counter += 1

    # stage code chunks now
    taken_size = len(last_metadata_chunk)
    code_indices = []
    code_chunks = []

    arg1 = tx_details["args"][1]
    assert arg1["type"] == "hex"

    code_vec = arg1["value"]
    for idx, hex_repr in enumerate(code_vec):
        assert hex_repr.startswith("0x")
        module_code = bytes.fromhex(hex_repr.removeprefix("0x"))
        for chunk in _create_chunks(module_code, chunk_size):
            if taken_size + len(chunk) > chunk_size:
                logging.debug("staging chunk %d", counter)
                _large_packages_stage_code_chunk_via_multisig(
                    deployer,
                    fullnode,
                    owner_multisig,
                    last_metadata_chunk,
                    code_indices,
                    code_chunks,
                    large_packages_module_address,
                )
                counter += 1

                # clear the accumulation
                last_metadata_chunk = bytes()
                taken_size = 0
                code_indices.clear()
                code_chunks.clear()

            # accumulate
            code_indices.append(idx)
            code_chunks.append(chunk)
            taken_size += len(chunk)

    # send the final transaction
    commands = [
        APTOS_BIN,
        "multisig",
        "create-transaction",
        "--multisig-address",
        owner_multisig,
        "--profile",
        deployer,
        "--url",
        fullnode,
        "--sender-account",
        deployer,
        "--function-id",
        f"{large_packages_module_address}::large_packages::stage_code_chunk_and_upgrade_object_code",
        "--args",
        (
            "u8:[]"
            if len(last_metadata_chunk) == 0
            else "hex:0x" + last_metadata_chunk.hex()
        ),
        "u16:[{}]".format(",".join([str(i) for i in code_indices])),
        "hex:[{}]".format(
            ",".join(['"0x' + code_chunk.hex() + '"' for code_chunk in code_chunks])
        ),
        f"address:{object_address}",
    ]
    _checked_execute(commands, cwd=PROJECT_DIR)
    return counter + 1


def _upgrade_via_multisig(
    deployer: str,
    fullnode: str,
    owner_multisig: str,
    package_path: str | pathlib.Path,
    address_name: str,
    object_named_addresses: List[str],
    preset_named_addresses: Optional[Dict[str, str]] = None,
    chunked_publish: Optional[Tuple[int, str]] = None,
    max_gas: Optional[int] = 100_0000,
    fetch_latest_git_deps: bool = False,
) -> int:
    # log the action
    logging.info(f"Starting to upgrade package %s via multisig", address_name)

    # everything occurs inside a temp dir
    with tempfile.TemporaryDirectory() as tmpdir:
        tx_json = os.path.join(tmpdir, "tx.json")

        # create the transaction
        object_address = _get_deployed_address(address_name)
        named_address_list = [f"{address_name}={object_address}"]
        named_address_list.extend(
            [
                "{}={}".format(i, _get_deployed_address(i))
                for i in object_named_addresses
            ]
        )
        if preset_named_addresses is not None:
            named_address_list.extend(
                [f"{k}={v}" for k, v in preset_named_addresses.items()]
            )

        commands = [
            APTOS_BIN,
            "move",
            "build-publish-payload",
            "--profile",
            deployer,
            "--url",
            fullnode,
            "--included-artifacts",
            "sparse",
            "--json-output-file",
            tx_json,
            "--named-addresses",
            ",".join(named_address_list),
        ]
        if chunked_publish is not None:
            # NOTE: until Aptos CLI has support for chunked publication for multisig, we
            #       need to implement this ourselves, hence not using `--chunked-publish`
            commands.append("--override-size-check")
        if max_gas is not None:
            commands.extend(["--max-gas", str(max_gas)])
        if not fetch_latest_git_deps:
            commands.append("--skip-fetch-latest-git-deps")

        _checked_execute(commands, cwd=package_path)

        # special flow for chunked publication
        if chunked_publish is not None:
            chunk_size, large_packages_module_address = chunked_publish
            number_of_transactions = _execute_multisig_chunked_upgrade_workflow(
                deployer,
                fullnode,
                owner_multisig,
                object_address,
                tx_json,
                chunk_size,
                large_packages_module_address,
            )
            # short-circuit, as the rest is normal upgrading flow
            return number_of_transactions

        # modify the transaction json file
        with open(tx_json, "r") as f1:
            tx_details = json.load(f1)
            assert tx_details["function_id"] == "0x1::code::publish_package_txn"
            tx_details["function_id"] = "0x1::object_code_deployment::upgrade"
            assert len(tx_details["args"]) == 2
            tx_details["args"].append(
                {
                    "type": "address",
                    "value": object_address,
                }
            )

        with open(tx_json, "w") as f2:
            json.dump(tx_details, f2)

        # send the transaction to the multisig account
        _create_multisig_transaction_with_json_payload(
            deployer, fullnode, owner_multisig, tx_json
        )
        return 1


#
# Logics per each package
#


def publish_aave_config(deployer: str, fullnode: str, upgrade: bool) -> None:
    _publish(
        deployer,
        fullnode,
        upgrade,
        PROJECT_DIR / "aave-core" / "aave-config",
        "aave_config",
        [],
    )


def upgrade_aave_config_multisig(
    deployer: str,
    fullnode: str,
    owner_multisig: str,
) -> int:
    return _upgrade_via_multisig(
        deployer,
        fullnode,
        owner_multisig,
        PROJECT_DIR / "aave-core" / "aave-config",
        "aave_config",
        [],
    )


def publish_aave_acl(deployer: str, fullnode: str, upgrade: bool) -> None:
    _publish(
        deployer,
        fullnode,
        upgrade,
        PROJECT_DIR / "aave-core" / "aave-acl",
        "aave_acl",
        ["aave_config"],
    )


def upgrade_aave_acl_multisig(
    deployer: str,
    fullnode: str,
    owner_multisig: str,
) -> int:
    return _upgrade_via_multisig(
        deployer,
        fullnode,
        owner_multisig,
        PROJECT_DIR / "aave-core" / "aave-acl",
        "aave_acl",
        ["aave_config"],
    )


def publish_aave_math(deployer: str, fullnode: str, upgrade: bool) -> None:
    _publish(
        deployer,
        fullnode,
        upgrade,
        PROJECT_DIR / "aave-core" / "aave-math",
        "aave_math",
        ["aave_config"],
    )


def upgrade_aave_math_multisig(
    deployer: str,
    fullnode: str,
    owner_multisig: str,
) -> int:
    return _upgrade_via_multisig(
        deployer,
        fullnode,
        owner_multisig,
        PROJECT_DIR / "aave-core" / "aave-math",
        "aave_math",
        ["aave_config"],
    )


def publish_mock_underlyings(deployer: str, fullnode: str, upgrade: bool) -> None:
    _publish(
        deployer,
        fullnode,
        upgrade,
        PROJECT_DIR / "aave-core" / "aave-mock-underlyings",
        "aave_mock_underlyings",
        ["aave_config"],
    )


def upgrade_mock_underlyings_multisig(
    deployer: str,
    fullnode: str,
    owner_multisig: str,
) -> int:
    return _upgrade_via_multisig(
        deployer,
        fullnode,
        owner_multisig,
        PROJECT_DIR / "aave-core" / "aave-mock-underlyings",
        "aave_mock_underlyings",
        ["aave_config"],
    )


def publish_chainlink_platform(deployer: str, fullnode: str, upgrade: bool) -> None:
    _publish(
        deployer,
        fullnode,
        upgrade,
        PROJECT_DIR / "aave-core" / "chainlink-platform",
        "platform",
        [],
        preset_named_addresses={"aave_oracle_racc_address": "0x0"},
    )


def publish_chainlink_data_feeds(deployer: str, fullnode: str, upgrade: bool) -> None:
    _publish(
        deployer,
        fullnode,
        upgrade,
        PROJECT_DIR / "aave-core" / "chainlink-data-feeds",
        "data_feeds",
        ["platform"],
        preset_named_addresses={"aave_oracle_racc_address": "0x0"},
    )


def publish_aave_oracle(deployer: str, fullnode: str, upgrade: bool) -> None:
    _publish(
        deployer,
        fullnode,
        upgrade,
        PROJECT_DIR / "aave-core" / "aave-oracle",
        "aave_oracle",
        [
            "aave_config",
            "aave_acl",
            "aave_math",
            "platform",
            "data_feeds",
        ],
        preset_named_addresses={"aave_oracle_racc_address": "0x0"},
    )


def upgrade_aave_oracle_multisig(
    deployer: str,
    fullnode: str,
    owner_multisig: str,
) -> int:
    return _upgrade_via_multisig(
        deployer,
        fullnode,
        owner_multisig,
        PROJECT_DIR / "aave-core" / "aave-oracle",
        "aave_oracle",
        [
            "aave_config",
            "aave_acl",
            "aave_math",
            "platform",
            "data_feeds",
        ],
        preset_named_addresses={"aave_oracle_racc_address": "0x0"},
    )


def publish_aave_core(deployer: str, fullnode: str, upgrade: bool) -> None:
    _publish(
        deployer,
        fullnode,
        upgrade,
        PROJECT_DIR / "aave-core",
        "aave_pool",
        [
            "aave_config",
            "aave_acl",
            "aave_math",
            "aave_oracle",
            "platform",
            "data_feeds",
        ],
        preset_named_addresses={"aave_oracle_racc_address": "0x0"},
        chunked_publish=True,
    )


def upgrade_aave_core_multisig(
    deployer: str,
    fullnode: str,
    owner_multisig: str,
    chunk_size: int,
    large_packages_module_address: str,
) -> int:
    return _upgrade_via_multisig(
        deployer,
        fullnode,
        owner_multisig,
        PROJECT_DIR / "aave-core",
        "aave_pool",
        [
            "aave_config",
            "aave_acl",
            "aave_math",
            "aave_oracle",
            "platform",
            "data_feeds",
        ],
        preset_named_addresses={"aave_oracle_racc_address": "0x0"},
        chunked_publish=(chunk_size, large_packages_module_address),
    )


def publish_aave_data(deployer: str, fullnode: str, upgrade: bool) -> None:
    _publish(
        deployer,
        fullnode,
        upgrade,
        PROJECT_DIR / "aave-core" / "aave-data",
        "aave_data",
        [
            "aave_config",
            "aave_acl",
            "aave_math",
            "aave_mock_underlyings",
            "aave_oracle",
            "aave_pool",
            "platform",
            "data_feeds",
        ],
        preset_named_addresses={"aave_oracle_racc_address": "0x0"},
        chunked_publish=True,
    )


def upgrade_aave_data_multisig(
    deployer: str,
    fullnode: str,
    owner_multisig: str,
    chunk_size: int,
    large_packages_module_address: str,
) -> int:
    return _upgrade_via_multisig(
        deployer,
        fullnode,
        owner_multisig,
        PROJECT_DIR / "aave-core" / "aave-data",
        "aave_data",
        [
            "aave_config",
            "aave_acl",
            "aave_math",
            "aave_mock_underlyings",
            "aave_oracle",
            "aave_pool",
            "platform",
            "data_feeds",
        ],
        preset_named_addresses={"aave_oracle_racc_address": "0x0"},
        chunked_publish=(chunk_size, large_packages_module_address),
    )


def deploy_all_localnet(
    deployer: str,
    fullnode: str,
    upgrade: bool,
) -> None:
    """
    Deploy all packages on-chain

    :param deployer: profile name of the account who initializes the deployment
    :param fullnode: fullnode URL of the chain
    :param upgrade: if True, upgrade packages instead of initially publishign them
    """

    publish_aave_config(deployer, fullnode, upgrade)
    publish_aave_acl(deployer, fullnode, upgrade)
    publish_aave_math(deployer, fullnode, upgrade)
    publish_mock_underlyings(deployer, fullnode, upgrade)
    publish_chainlink_platform(deployer, fullnode, upgrade)
    publish_chainlink_data_feeds(deployer, fullnode, upgrade)
    publish_aave_oracle(deployer, fullnode, upgrade)
    publish_aave_core(deployer, fullnode, upgrade)
    publish_aave_data(deployer, fullnode, upgrade)


#
# Initialize scripts
#


def change_ownership(
    deployer: str,
    fullnode: str,
    package_name: str,
    new_owner_address: str,
) -> None:
    """
    Change ownership of the object where the package is deployed at
    :param deployer: profile name of the previous owner of the object
    :param fullnode: fullnode URL of the chain
    :param package_name: name of the package
    :param new_owner_address: address of the new owner
    """

    logging.info(
        "Changing ownership for package '%s' from deployer '%s' to address %s",
        package_name,
        deployer,
        new_owner_address,
    )

    deployed_address = _get_deployed_address(package_name)
    commands = [
        APTOS_BIN,
        "move",
        "run",
        "--profile",
        deployer,
        "--url",
        fullnode,
        "--sender-account",
        deployer,
        "--function-id",
        "0x1::object::transfer",
        "--type-args",
        "0x1::object::ObjectCore",
        "--args",
        f"address:{deployed_address}",
        f"address:{new_owner_address}",
    ]
    _checked_execute(commands, cwd=PROJECT_DIR)


def configure_acl(
    deployer: str, fullnode: str, multisig_aave_acl: str, network: str
) -> None:
    # log the action
    logging.info("Setup: ACL")

    # run the configuration as super admin
    aave_data_address = _get_deployed_address("aave_data")
    commands = [
        APTOS_BIN,
        "move",
        "run",
        "--profile",
        deployer,
        "--url",
        fullnode,
        "--sender-account",
        deployer,
        "--function-id",
        f"{aave_data_address}::v1_deployment::configure_acl",
        "--args",
        f"string:{network}",
    ]
    _checked_execute(commands, cwd=PROJECT_DIR)

    # renounce and transfer the super admin role to the AaveACL multisig
    aave_acl_address = _get_deployed_address("aave_acl")
    commands = [
        APTOS_BIN,
        "move",
        "run",
        "--profile",
        deployer,
        "--url",
        fullnode,
        "--sender-account",
        deployer,
        "--function-id",
        f"{aave_acl_address}::acl_manage::add_default_admin",
        "--args",
        f"address:{multisig_aave_acl}",
    ]
    _checked_execute(commands, cwd=PROJECT_DIR)

    commands = [
        APTOS_BIN,
        "move",
        "run",
        "--profile",
        deployer,
        "--url",
        fullnode,
        "--sender-account",
        deployer,
        "--function-id",
        f"{aave_acl_address}::acl_manage::renounce_default_admin",
    ]
    _checked_execute(commands, cwd=PROJECT_DIR)


def configure_acl_localnet(
    deployer: str, fullnode: str, multisig_pool_admin: str
) -> None:
    # log the action
    logging.info("Setup: ACL")

    # use a simplified ACL configuration process
    aave_acl_address = _get_deployed_address("aave_acl")
    commands = [
        APTOS_BIN,
        "move",
        "run",
        "--profile",
        deployer,
        "--url",
        fullnode,
        "--sender-account",
        deployer,
        "--function-id",
        f"{aave_acl_address}::acl_manage::add_pool_admin",
        "--args",
        f"address:{multisig_pool_admin}",
    ]
    _checked_execute(commands, cwd=PROJECT_DIR)


def _query_next_multisig_sequence_number(
    deployer: str,
    fullnode: str,
    multisig_address: str,
) -> int:
    """
    Query the next transaction sequence number for the multisig account

    :param deployer: profile name of the account who creates the transaction
    :param fullnode: fullnode URL of the chain
    :param multisig_address: address of the multisig account
    :return: the sequence number of the transaction in the multisig account
    """
    commands = [
        APTOS_BIN,
        "account",
        "list",
        "--account",
        multisig_address,
        "--profile",
        deployer,
        "--url",
        fullnode,
    ]
    output, _ = _checked_execute(commands, cwd=PROJECT_DIR)

    # parse the output
    needle_prefix = '"next_sequence_number": "'
    needle_suffix = '",'
    sequence_number = None

    for line in output:
        line = line.lstrip()
        if line.startswith(needle_prefix) and line.endswith(needle_suffix):
            # rare case, just to be caution
            if sequence_number is not None:
                raise RuntimeError("More than one sequence numbers in the output")
            sequence_number = line.removeprefix(needle_prefix).removesuffix(
                needle_suffix
            )

    if sequence_number is None:
        raise RuntimeError("Unable to find the sequence number in the output")

    return int(sequence_number)


def _create_multisig_transaction(
    deployer: str,
    fullnode: str,
    multisig_address: str,
    function_id: str,
    args: List[str],
) -> int:
    """
    Create a multisig transaction and send it to the multisig account

    :param deployer: profile name of the account who creates the transaction
    :param fullnode: fullnode URL of the chain
    :param multisig_address: address of the multisig account
    :param function_id: fully qualified name of the function to be invoked
    :param args: arguments of this function
    :return: the sequence number of the transaction in the multisig account
    """

    # create and send the transaction to the multisig account
    commands = [
        APTOS_BIN,
        "multisig",
        "create-transaction",
        "--multisig-address",
        multisig_address,
        "--profile",
        deployer,
        "--url",
        fullnode,
        "--sender-account",
        deployer,
        "--function-id",
        function_id,
    ]
    if len(args) != 0:
        commands.append("--args")
        commands.extend(args)

    _checked_execute(commands, cwd=PROJECT_DIR)

    # return the sequence number for this transaction
    seq = _query_next_multisig_sequence_number(deployer, fullnode, multisig_address)
    return seq - 1


def _create_multisig_transaction_with_json_payload(
    deployer: str,
    fullnode: str,
    multisig_address: str,
    json_file: str | pathlib.Path,
) -> int:
    """
    Create a multisig transaction via json and send it to the multisig account

    :param deployer: profile name of the account who creates the transaction
    :param fullnode: fullnode URL of the chain
    :param multisig_address: address of the multisig account
    :param json_file: path to the json payload file
    :return: the sequence number of the transaction in the multisig account
    """

    # create the transaction
    commands = [
        APTOS_BIN,
        "multisig",
        "create-transaction",
        "--multisig-address",
        multisig_address,
        "--profile",
        deployer,
        "--url",
        fullnode,
        "--sender-account",
        deployer,
        "--json-file",
        json_file,
    ]
    _checked_execute(commands, cwd=PROJECT_DIR)

    # return the sequence number for this transaction
    seq = _query_next_multisig_sequence_number(deployer, fullnode, multisig_address)
    return seq - 1


def setup_configure_emodes(
    deployer: str, fullnode: str, multisig_pool_admin: str, network: str
) -> int:
    logging.info("Setup: eModes")

    aave_data_address = _get_deployed_address("aave_data")
    return _create_multisig_transaction(
        deployer,
        fullnode,
        multisig_pool_admin,
        f"{aave_data_address}::v1_deployment::configure_emodes",
        [f"string:{network}"],
    )


def setup_create_reserves(
    deployer: str, fullnode: str, multisig_pool_admin: str, network: str
) -> int:
    logging.info("Setup: reserve creation")

    aave_data_address = _get_deployed_address("aave_data")
    return _create_multisig_transaction(
        deployer,
        fullnode,
        multisig_pool_admin,
        f"{aave_data_address}::v1_deployment::create_reserves",
        [f"string:{network}"],
    )


def setup_configure_reserves(
    deployer: str, fullnode: str, multisig_pool_admin: str, network: str
) -> int:
    logging.info("Setup: reserve configuration")

    aave_data_address = _get_deployed_address("aave_data")
    return _create_multisig_transaction(
        deployer,
        fullnode,
        multisig_pool_admin,
        f"{aave_data_address}::v1_deployment::configure_reserves",
        [f"string:{network}"],
    )


def setup_configure_interest_rates(
    deployer: str, fullnode: str, multisig_pool_admin: str, network: str
) -> int:
    logging.info("Setup: interest rates")

    aave_data_address = _get_deployed_address("aave_data")
    return _create_multisig_transaction(
        deployer,
        fullnode,
        multisig_pool_admin,
        f"{aave_data_address}::v1_deployment::configure_interest_rates",
        [f"string:{network}"],
    )


def setup_configure_price_feeds(
    deployer: str, fullnode: str, multisig_pool_admin: str, network: str
) -> int:
    logging.info("Setup: price feeds")

    aave_data_address = _get_deployed_address("aave_data")
    return _create_multisig_transaction(
        deployer,
        fullnode,
        multisig_pool_admin,
        f"{aave_data_address}::v1_deployment::configure_price_feeds",
        [f"string:{network}"],
    )


def setup_all_localnet(
    deployer: str, fullnode: str, multisig_pool_admin: str, network: str
) -> None:
    """
    Prepare and execute multisig transactions for steps on localnet (with ACL configured)

    :param deployer: profile name of the deployer who sends these transactions
    :param fullnode: fullnode URL of the chain
    :param multisig_pool_admin: address of the pool_admin multisig account
    :param network: values to use for the setup ("testnet" or "mainnet")
    """

    setup_configure_emodes(deployer, fullnode, multisig_pool_admin, network)
    execute_multisig_on_localnet(deployer, fullnode, multisig_pool_admin)

    setup_create_reserves(deployer, fullnode, multisig_pool_admin, network)
    execute_multisig_on_localnet(deployer, fullnode, multisig_pool_admin)

    setup_configure_reserves(deployer, fullnode, multisig_pool_admin, network)
    execute_multisig_on_localnet(deployer, fullnode, multisig_pool_admin)

    setup_configure_interest_rates(deployer, fullnode, multisig_pool_admin, network)
    execute_multisig_on_localnet(deployer, fullnode, multisig_pool_admin)

    setup_configure_price_feeds(deployer, fullnode, multisig_pool_admin, network)
    execute_multisig_on_localnet(deployer, fullnode, multisig_pool_admin)


#
# Utilities on deployment to local testnet
#


def launch_localnet() -> subprocess.Popen:
    """
    Create a background process that runs a local testnet

    :return: the process handle of the local testnet
    """

    proc = subprocess.Popen(
        [APTOS_BIN, "node", "run-local-testnet", "--with-faucet", "--force-restart"]
    )
    input('Press Enter when localnet is deployed (i.e., until "Setup is complete"): ')
    return proc


def init_deployer_on_localnet(deployer: str, fullnode: str, faucet: str) -> None:
    """
    Create and fund the deployer account on a local testnet

    :param deployer: name of the deployer account
    :param fullnode: fullnode URL of the chain
    :param faucet: faucet URL of the chain
    """

    # NOTE: here we explicitly use subprocess for user interaction
    subprocess.check_call(
        [
            APTOS_BIN,
            "init",
            "--network",
            "local",
            "--profile",
            deployer,
            "--assume-yes",
        ],
        cwd=PROJECT_DIR,
    )

    # now fund the account from faucet
    _checked_execute(
        [
            APTOS_BIN,
            "account",
            "fund-with-faucet",
            "--profile",
            deployer,
            "--url",
            fullnode,
            "--faucet-url",
            faucet,
            "--amount",
            str(1_0000_0000 * 1000),
        ],
        cwd=PROJECT_DIR,
    )


def init_multisig_on_localnet(deployer: str, fullnode: str, faucet: str) -> str:
    """
    Create and fund a multisig account on a local testnet

    :param deployer: name of the deployer profile that initializes the transaction
    :param fullnode: fullnode URL of the chain
    :param faucet: faucet URL of the chain
    :return: address of the multisig account
    """

    # create the account
    output, _ = _checked_execute(
        [
            APTOS_BIN,
            "multisig",
            "create",
            "--num-signatures-required",
            "1",
            "--url",
            fullnode,
            "--profile",
            deployer,
            "--assume-yes",
        ],
        cwd=PROJECT_DIR,
    )

    # parse the output
    needle_prefix = '"multisig_address": "'
    needle_suffix = '",'
    multisig_address = None

    for line in output:
        line = line.lstrip()
        if line.startswith(needle_prefix) and line.endswith(needle_suffix):
            # rare case, just to be caution
            if multisig_address is not None:
                raise RuntimeError(
                    f"Multisig account is created "
                    f"but we find more than one addresses in the output"
                )
            multisig_address = line.removeprefix(needle_prefix).removesuffix(
                needle_suffix
            )
            multisig_address = f"0x{multisig_address}"

    if multisig_address is None:
        raise RuntimeError(
            f"Multisig account is deployed "
            f"but we are unable to find the address in the output"
        )

    # fund the account
    _checked_execute(
        [
            APTOS_BIN,
            "account",
            "fund-with-faucet",
            "--account",
            multisig_address,
            "--profile",
            deployer,
            "--url",
            fullnode,
            "--faucet-url",
            faucet,
            "--amount",
            str(1_0000_0000 * 1000),
        ],
        cwd=PROJECT_DIR,
    )

    # return the address
    return multisig_address


def execute_multisig_on_localnet(
    deployer: str,
    fullnode: str,
    multisig_address: str,
    max_gas: Optional[int] = 100_0000,
) -> None:
    """
    Execute a multisig account on a local testnet

    :param deployer: profile name of the deployer account
    :param fullnode: fullnode URL of the chain
    :param multisig_address: address of the multisig account
    :param max_gas: maximum gas to allow, also disables simulation
    """

    command = [
        APTOS_BIN,
        "multisig",
        "execute",
        "--multisig-address",
        multisig_address,
        "--url",
        fullnode,
        "--profile",
        deployer,
        "--assume-yes",
    ]
    if max_gas is not None:
        command.extend(["--max-gas", str(max_gas)])

    _checked_execute(command, cwd=PROJECT_DIR)


def init_mulltisig_and_transfer_code_ownership_on_localnet(
    deployer: str, fullnode: str, faucet: str, package_name: str
) -> str:
    """
    Initialize a multisig account and transfer the ownership of package to that account
    on localnet

    :param deployer: profile name of the deployer who sends these transactions
    :param fullnode: fullnode URL of the chain
    :param faucet: faucet URL of the account
    :param package_name: name of the package to transfer
    :return: the address of the multisig account
    """

    multisig = init_multisig_on_localnet(deployer, fullnode, faucet)
    change_ownership(deployer, fullnode, package_name, multisig)
    return multisig


def transfer_and_upgrade_all_packages_on_localnet(
    deployer: str,
    fullnode: str,
    faucet: str,
    chunk_size: int = 40000,
    large_packages_module_address: str = "0x7",
) -> None:
    """
    Transfer all packages to newly created multisig accounts and also try an upgrade there

    :param deployer: profile name of the deployer who sends these transactions
    :param fullnode: fullnode URL of the chain
    :param faucet: faucet URL of the account
    :param chunk_size: desired chunk size for chunked publication
    :param large_packages_module_address: address of the large package module
    """

    # aave-config
    multisig_aave_config = init_mulltisig_and_transfer_code_ownership_on_localnet(
        deployer, fullnode, faucet, "aave_config"
    )
    txn_count = upgrade_aave_config_multisig(deployer, fullnode, multisig_aave_config)
    assert txn_count == 1
    execute_multisig_on_localnet(deployer, fullnode, multisig_aave_config)

    # aave-acl
    multisig_aave_acl = init_mulltisig_and_transfer_code_ownership_on_localnet(
        deployer, fullnode, faucet, "aave_acl"
    )
    txn_count = upgrade_aave_acl_multisig(deployer, fullnode, multisig_aave_acl)
    assert txn_count == 1
    execute_multisig_on_localnet(deployer, fullnode, multisig_aave_acl)

    # aave-math
    multisig_aave_math = init_mulltisig_and_transfer_code_ownership_on_localnet(
        deployer, fullnode, faucet, "aave_math"
    )
    txn_count = upgrade_aave_math_multisig(deployer, fullnode, multisig_aave_math)
    assert txn_count == 1
    execute_multisig_on_localnet(deployer, fullnode, multisig_aave_math)

    # aave-mock-underlyings
    multisig_mock_underlyings = init_mulltisig_and_transfer_code_ownership_on_localnet(
        deployer, fullnode, faucet, "aave_mock_underlyings"
    )
    txn_count = upgrade_mock_underlyings_multisig(
        deployer, fullnode, multisig_mock_underlyings
    )
    assert txn_count == 1
    execute_multisig_on_localnet(deployer, fullnode, multisig_mock_underlyings)

    # aave-oracle
    multisig_aave_oracle = init_mulltisig_and_transfer_code_ownership_on_localnet(
        deployer, fullnode, faucet, "aave_oracle"
    )
    txn_count = upgrade_aave_oracle_multisig(deployer, fullnode, multisig_aave_oracle)
    assert txn_count == 1
    execute_multisig_on_localnet(deployer, fullnode, multisig_aave_oracle)

    # aave-pool
    multisig_aave_pool = init_mulltisig_and_transfer_code_ownership_on_localnet(
        deployer, fullnode, faucet, "aave_pool"
    )
    txn_count = upgrade_aave_core_multisig(
        deployer,
        fullnode,
        multisig_aave_pool,
        chunk_size,
        large_packages_module_address,
    )
    for _ in range(txn_count):
        execute_multisig_on_localnet(deployer, fullnode, multisig_aave_pool)

    # aave-data
    multisig_aave_data = init_mulltisig_and_transfer_code_ownership_on_localnet(
        deployer, fullnode, faucet, "aave_data"
    )
    txn_count = upgrade_aave_data_multisig(
        deployer,
        fullnode,
        multisig_aave_data,
        chunk_size,
        large_packages_module_address,
    )
    for _ in range(txn_count):
        execute_multisig_on_localnet(deployer, fullnode, multisig_aave_pool)


#
# Logging
#


def start_logging() -> None:
    # setup logging
    log_formatter = logging.Formatter("%(asctime)s [%(levelname)-5.5s]  %(message)s")
    root_logger = logging.getLogger()
    root_logger.setLevel(logging.DEBUG)

    file_handler = logging.FileHandler(
        "deploy-{}.log".format(datetime.now(UTC).isoformat())
    )
    file_handler.setFormatter(log_formatter)
    file_handler.setLevel(logging.DEBUG)
    root_logger.addHandler(file_handler)

    verbose = os.getenv("VERBOSE")
    console_handler = logging.StreamHandler()
    console_handler.setFormatter(log_formatter)
    console_handler.setLevel(logging.DEBUG if verbose == "1" else logging.INFO)
    root_logger.addHandler(console_handler)


def main() -> None:
    # setup the argument parser
    parser = argparse.ArgumentParser(
        description="Utility script to deploy AAVE Aptos packages",
    )
    subparsers = parser.add_subparsers(
        dest="chain",
        help="chain to deploy on",
    )

    # options for localnet
    parser_localnet = subparsers.add_parser(
        "localnet",
        help="deploy on localnet",
    )
    parser_localnet.add_argument(
        "--deployer",
        default="deployer",
        help="deployer profile name",
    )
    parser_localnet.add_argument(
        "--fullnode",
        default="http://localhost:8080",
        help="fullnode url",
    )
    parser_localnet.add_argument(
        "--faucet",
        default="http://localhost:8081",
        help="faucet url",
    )

    # options for testnet
    parser_testnet = subparsers.add_parser(
        "testnet",
        help="deploy on testnet",
    )
    parser_testnet.add_argument(
        "--deployer",
        required=True,
        help="deployer profile name",
    )
    parser_testnet.add_argument(
        "--fullnode",
        default="https://fullnode.testnet.aptoslabs.com",
        help="fullnode url",
    )

    parser_testnet.add_argument(
        "--large-packages-module",
        default="0x0e1ca3011bdd07246d4d16d909dbb2d6953a86c4735d5acf5865d962c630cce7",
        help="Aptos LargePackages module address",
    )
    parser_testnet.add_argument(
        "--chainlink-platform",
        default="0x516e771e1b4a903afe74c27d057c65849ecc1383782f6642d7ff21425f4f9c99",
        help="ChainlinkPlatform module address",
    )
    parser_testnet.add_argument(
        "--chainlink-data-feeds",
        default="0xf1099f135ddddad1c065203431be328a408b0ca452ada70374ce26bd2b32fdd3",
        help="ChainlinkDataFeeds module address",
    )
    parser_testnet.add_argument(
        "--multisig-pool-admin",
        default="0x859d111e05bd4deed6fc1a94cec995e12ac2ad7bbe7cec425ef6aaebfaf5238c",
        help="Multisig account PoolAdmin address",
    )
    parser_testnet.add_argument(
        "--multisig-aave-config",
        default="0xf62a5a73423621a47f3a606bf725fc08c4051967bd34fffc7a713f0fc7e4d2be",
        help="Multisig account AaveConfig address",
    )
    parser_testnet.add_argument(
        "--multisig-aave-acl",
        default="0x85c7d9eb8c44dc353f999b9091e1b125890e2f18074f26407b6e1d52bb5e23f9",
        help="Multisig account AaveACL address",
    )
    parser_testnet.add_argument(
        "--multisig-aave-math",
        default="0x9b4ca390cedd6424f82ec9afaa59bdd6b0ae59de4d1ea3d9b478927ed2a967a9",
        help="Multisig account AaveMath address",
    )
    parser_testnet.add_argument(
        "--multisig-mock-underlyings",
        default="0x3d802c82f2df813778adbf6c2e1c503c4b4b6710b63c6d19aae3db3b0838853b",
        help="Multisig account AaveMockUnderlyings address",
    )
    parser_testnet.add_argument(
        "--multisig-aave-oracle",
        default="0x7b41f4d510b968a4d5104ce4036a8697ef363d04cf4061bb12b7f7caa1e66312",
        help="Multisig account AaveOracle address",
    )
    parser_testnet.add_argument(
        "--multisig-aave-core",
        default="0xe3be2d728688ac509be29f42d8009c78864225fe2bbd859d07bd2759647ce412",
        help="Multisig account AavePool address",
    )
    parser_testnet.add_argument(
        "--multisig-aave-data",
        default="0x108e14107cfe3d6d706fd208654e26ecc8b7a7f06ee82c4535477ba13aa03b52",
        help="Multisig account AaveData address",
    )

    parser_testnet_command = parser_testnet.add_subparsers(dest="testnet_command")

    parser_testnet_clear_staging_area = parser_testnet_command.add_parser(
        "clear-staging-area",
        help="clear staging area of the deployer for chunked publishing",
    )
    parser_testnet_clear_staging_area.add_argument(
        "--multisig-account",
        default=None,
        help="Clean up the staging area of a multisig account",
    )

    parser_testnet_command.add_parser(
        "publish-config",
        help="publish the aave-config package to a newly created object",
    )
    parser_testnet_command.add_parser(
        "publish-acl",
        help="publish the aave-acl package to a newly created object",
    )
    parser_testnet_command.add_parser(
        "publish-math",
        help="publish the aave-math package to a newly created object",
    )
    parser_testnet_command.add_parser(
        "publish-mock-underlyings",
        help="publish the aave-mock-underlyings package to a newly created object",
    )
    parser_testnet_command.add_parser(
        "publish-oracle",
        help="publish the aave-oracle package to a newly created object",
    )
    parser_testnet_command.add_parser(
        "publish-core",
        help="publish the aave-pool package to a newly created object",
    )
    parser_testnet_command.add_parser(
        "publish-data",
        help="publish the aave-data package to a newly created object",
    )

    parser_testnet_command.add_parser(
        "configure-acl",
        help="configure the access control list (ACL) for the initial launch",
    )
    parser_testnet_command.add_parser(
        "setup-configure-emodes",
        help="configure the eMode categories for the initial launch",
    )
    parser_testnet_command.add_parser(
        "setup-create-reserves",
        help="create reserves for the initial launch",
    )
    parser_testnet_command.add_parser(
        "setup-configure-reserves",
        help="configure reserves for the initial launch",
    )
    parser_testnet_command.add_parser(
        "setup-configure-interest-rates",
        help="configure interest rates for the initial launch",
    )
    parser_testnet_command.add_parser(
        "setup-configure-price-feeds",
        help="configure price feeds for the initial launch",
    )

    parser_testnet_command.add_parser(
        "change-owner-config",
        help="Change the ownership of the aave-config package",
    )
    parser_testnet_command.add_parser(
        "change-owner-acl",
        help="Change the ownership of the aave-acl package",
    )
    parser_testnet_command.add_parser(
        "change-owner-math",
        help="Change the ownership of the aave-math package",
    )
    parser_testnet_command.add_parser(
        "change-owner-mock-underlyings",
        help="Change the ownership of the aave-mock-underlyings package",
    )
    parser_testnet_command.add_parser(
        "change-owner-oracle",
        help="Change the ownership of the aave-oracle package",
    )
    parser_testnet_command.add_parser(
        "change-owner-core",
        help="Change the ownership of the aave-pool package",
    )
    parser_testnet_command.add_parser(
        "change-owner-data",
        help="Change the ownership of the aave-data package",
    )

    parser_testnet_command.add_parser(
        "upgrade-config",
        help="upgrade the already published aave-config package owned by the deployer",
    )
    parser_testnet_command.add_parser(
        "upgrade-acl",
        help="upgrade the already published aave-acl package owned by the deployer",
    )
    parser_testnet_command.add_parser(
        "upgrade-math",
        help="upgrade the already published aave-math package owned by the deployer",
    )
    parser_testnet_command.add_parser(
        "upgrade-mock-underlyings",
        help="upgrade the already published aave-mock-underlyings package owned by the deployer",
    )
    parser_testnet_command.add_parser(
        "upgrade-oracle",
        help="upgrade the already published aave-oracle package owned by the deployer",
    )
    parser_testnet_command.add_parser(
        "upgrade-core",
        help="upgrade the already published aave-pool package owned by the deployer",
    )
    parser_testnet_command.add_parser(
        "upgrade-data",
        help="upgrade the already published aave-data package owned by the deployer",
    )

    # options for mainnet
    parser_mainnet = subparsers.add_parser(
        "mainnet",
        help="deploy on mainnet",
    )
    parser_mainnet.add_argument(
        "--deployer",
        required=True,
        help="deployer profile name",
    )
    parser_mainnet.add_argument(
        "--fullnode",
        default="https://fullnode.mainnet.aptoslabs.com",
        help="fullnode url",
    )

    parser_mainnet.add_argument(
        "--large-packages-module",
        default="0x0e1ca3011bdd07246d4d16d909dbb2d6953a86c4735d5acf5865d962c630cce7",
        help="Aptos LargePackages module address",
    )
    parser_mainnet.add_argument(
        "--chainlink-platform",
        default="0x9976bb288ed9177b542d568fa1ac386819dc99141630e582315804840f41928a",
        help="ChainlinkPlatform module address",
    )
    parser_mainnet.add_argument(
        "--chainlink-data-feeds",
        default="0x3f985798ce4975f430ef5c75776ff98a77b9f9d0fb38184d225adc9c1cc6b79b",
        help="ChainlinkDataFeeds module address",
    )
    parser_mainnet.add_argument(
        "--multisig-pool-admin",
        default="0x6b8d9c9f788bc100c2688ae5bddd849d5bd7308cb493f245b12e56a2d8c3ebec",
        help="Multisig account PoolAdmin address",
    )
    parser_mainnet.add_argument(
        "--multisig-aave-config",
        default="0xf417afab0311d4af56757c1927456e0a85fe79180d45f75441c5d61ac493cbd7",
        help="Multisig account AaveConfig address",
    )
    parser_mainnet.add_argument(
        "--multisig-aave-acl",
        default="0x50dd0012a77fc9884b4bc460ec5c8249992e9a3d3e422b89883b4a982bfdcec9",
        help="Multisig account AaveACL address",
    )
    parser_mainnet.add_argument(
        "--multisig-aave-math",
        default="0x056d32138643b7d247be191d6e27f0d1f5352b4049a1129e2fc69eba66296361",
        help="Multisig account AaveMath address",
    )
    parser_mainnet.add_argument(
        "--multisig-mock-underlyings",
        default="0x00af70319d7b1adea014e941d07bf9276c969abd76d0f0134616025bed4061fe",
        help="Multisig account AaveMockUnderlyings address",
    )
    parser_mainnet.add_argument(
        "--multisig-aave-oracle",
        default="0x766178015cb41f3e780d3950a20a7c91254a5f10f0c5fd373f78f36d0b7b480e",
        help="Multisig account AaveOracle address",
    )
    parser_mainnet.add_argument(
        "--multisig-aave-core",
        default="0xf8a3ea771666a366450100f9e4a54dc05fd756a778bd95253c7fe419404bc4e9",
        help="Multisig account AavePool address",
    )
    parser_mainnet.add_argument(
        "--multisig-aave-data",
        default="0xd68e3dbbc1295081bffce9a530ac5e17c37707e818512131f7e5078b9a59e6cb",
        help="Multisig account AaveData address",
    )

    parser_mainnet_command = parser_mainnet.add_subparsers(dest="mainnet_command")

    parser_mainnet_clear_staging_area = parser_mainnet_command.add_parser(
        "clear-staging-area",
        help="clear staging area of the deployer for chunked publishing",
    )
    parser_mainnet_clear_staging_area.add_argument(
        "--multisig-account",
        default=None,
        help="Clean up the staging area of a multisig account",
    )

    parser_mainnet_command.add_parser(
        "publish-config",
        help="publish the aave-config package to a newly created object",
    )
    parser_mainnet_command.add_parser(
        "publish-acl",
        help="publish the aave-acl package to a newly created object",
    )
    parser_mainnet_command.add_parser(
        "publish-math",
        help="publish the aave-math package to a newly created object",
    )
    parser_mainnet_command.add_parser(
        "publish-mock-underlyings",
        help="publish the aave-mock-underlyings package to a newly created object",
    )
    parser_mainnet_command.add_parser(
        "publish-oracle",
        help="publish the aave-oracle package to a newly created object",
    )
    parser_mainnet_command.add_parser(
        "publish-core",
        help="publish the aave-pool package to a newly created object",
    )
    parser_mainnet_command.add_parser(
        "publish-data",
        help="publish the aave-data package to a newly created object",
    )

    parser_mainnet_command.add_parser(
        "configure-acl",
        help="configure the access control list (ACL) for the initial launch",
    )
    parser_mainnet_command.add_parser(
        "setup-configure-emodes",
        help="configure the eMode categories for the initial launch",
    )
    parser_mainnet_command.add_parser(
        "setup-create-reserves",
        help="create reserves for the initial launch",
    )
    parser_mainnet_command.add_parser(
        "setup-configure-reserves",
        help="configure reserves for the initial launch",
    )
    parser_mainnet_command.add_parser(
        "setup-configure-interest-rates",
        help="configure interest rates for the initial launch",
    )
    parser_mainnet_command.add_parser(
        "setup-configure-price-feeds",
        help="configure price feeds for the initial launch",
    )

    parser_mainnet_command.add_parser(
        "change-owner-config",
        help="Change the ownership of the aave-config package",
    )
    parser_mainnet_command.add_parser(
        "change-owner-acl",
        help="Change the ownership of the aave-acl package",
    )
    parser_mainnet_command.add_parser(
        "change-owner-math",
        help="Change the ownership of the aave-math package",
    )
    parser_mainnet_command.add_parser(
        "change-owner-mock-underlyings",
        help="Change the ownership of the aave-mock-underlyings package",
    )
    parser_mainnet_command.add_parser(
        "change-owner-oracle",
        help="Change the ownership of the aave-oracle package",
    )
    parser_mainnet_command.add_parser(
        "change-owner-core",
        help="Change the ownership of the aave-pool package",
    )
    parser_mainnet_command.add_parser(
        "change-owner-data",
        help="Change the ownership of the aave-data package",
    )

    parser_mainnet_command.add_parser(
        "upgrade-config",
        help="upgrade the already published aave-config package owned by the deployer",
    )
    parser_mainnet_command.add_parser(
        "upgrade-acl",
        help="upgrade the already published aave-acl package owned by the deployer",
    )
    parser_mainnet_command.add_parser(
        "upgrade-math",
        help="upgrade the already published aave-math package owned by the deployer",
    )
    parser_mainnet_command.add_parser(
        "upgrade-mock-underlyings",
        help="upgrade the already published aave-mock-underlyings package owned by the deployer",
    )
    parser_mainnet_command.add_parser(
        "upgrade-oracle",
        help="upgrade the already published aave-oracle package owned by the deployer",
    )
    parser_mainnet_command.add_parser(
        "upgrade-core",
        help="upgrade the already published aave-pool package owned by the deployer",
    )
    parser_mainnet_command.add_parser(
        "upgrade-data",
        help="upgrade the already published aave-data package owned by the deployer",
    )

    # parse arguments
    args = parser.parse_args()

    # switch by network type
    if args.chain == "localnet":
        # start logging
        start_logging()
        logging.info(
            "Starting deployment on localnet using deployer profile '%s'",
            args.deployer,
        )

        # prepare the local testnet
        proc = launch_localnet()
        try:
            # first initialize the deployer account
            init_deployer_on_localnet(args.deployer, args.fullnode, args.faucet)

            # deploy all contracts
            deploy_all_localnet(args.deployer, args.fullnode, upgrade=False)

            # initialize pool_admin multisig account
            multisig_pool_admin = init_multisig_on_localnet(
                args.deployer, args.fullnode, args.faucet
            )

            # run configuration scripts
            configure_acl_localnet(args.deployer, args.fullnode, multisig_pool_admin)
            setup_all_localnet(
                args.deployer, args.fullnode, multisig_pool_admin, "testnet"
            )

            # upgrade all contracts
            deploy_all_localnet(args.deployer, args.fullnode, upgrade=True)

            # transfer ownership of contracts, which also triggers upgrades
            transfer_and_upgrade_all_packages_on_localnet(
                args.deployer, args.fullnode, args.faucet
            )
        except Exception as ex:
            # terminate the local testnet on any error
            proc.terminate()
            raise ex

        # on normal termination
        proc.terminate()

    elif args.chain == "testnet":
        # start logging
        start_logging()
        logging.info(
            "Starting deployment on testnet using deployer profile '%s'",
            args.deployer,
        )

        # provision chainlink addresses
        _set_deployed_address("platform", args.chainlink_platform)
        _set_deployed_address("data_feeds", args.chainlink_data_feeds)

        # handle miscellaneous commands
        if args.testnet_command == "clear-staging-area":
            clear_staging_area(
                args.deployer,
                args.fullnode,
                args.multisig_account,
                args.large_packages_module,
            )

        # handle publishing commands
        elif args.testnet_command == "publish-config":
            publish_aave_config(args.deployer, args.fullnode, upgrade=False)
        elif args.testnet_command == "publish-acl":
            publish_aave_acl(args.deployer, args.fullnode, upgrade=False)
        elif args.testnet_command == "publish-math":
            publish_aave_math(args.deployer, args.fullnode, upgrade=False)
        elif args.testnet_command == "publish-mock-underlyings":
            publish_mock_underlyings(args.deployer, args.fullnode, upgrade=False)
        elif args.testnet_command == "publish-oracle":
            publish_aave_oracle(args.deployer, args.fullnode, upgrade=False)
        elif args.testnet_command == "publish-core":
            publish_aave_core(args.deployer, args.fullnode, upgrade=False)
        elif args.testnet_command == "publish-data":
            publish_aave_data(args.deployer, args.fullnode, upgrade=False)

        # handle configuration commands
        elif args.testnet_command == "configure-acl":
            configure_acl(
                args.deployer,
                args.fullnode,
                args.multisig_aave_acl,
                "testnet",
            )
        elif args.testnet_command == "setup-configure-emodes":
            setup_configure_emodes(
                args.deployer,
                args.fullnode,
                args.multisig_pool_admin,
                "testnet",
            )
        elif args.testnet_command == "setup-create-reserves":
            setup_create_reserves(
                args.deployer,
                args.fullnode,
                args.multisig_pool_admin,
                "testnet",
            )
        elif args.testnet_command == "setup-configure-reserves":
            setup_configure_reserves(
                args.deployer,
                args.fullnode,
                args.multisig_pool_admin,
                "testnet",
            )
        elif args.testnet_command == "setup-configure-interest-rates":
            setup_configure_interest_rates(
                args.deployer,
                args.fullnode,
                args.multisig_pool_admin,
                "testnet",
            )
        elif args.testnet_command == "setup-configure-price-feeds":
            setup_configure_price_feeds(
                args.deployer,
                args.fullnode,
                args.multisig_pool_admin,
                "testnet",
            )

        # handle ownership commands
        elif args.testnet_command == "change-owner-config":
            change_ownership(
                args.deployer,
                args.fullnode,
                "aave_config",
                args.multisig_aave_config,
            )
        elif args.testnet_command == "change-owner-acl":
            change_ownership(
                args.deployer,
                args.fullnode,
                "aave_acl",
                args.multisig_aave_acl,
            )
        elif args.testnet_command == "change-owner-math":
            change_ownership(
                args.deployer,
                args.fullnode,
                "aave_math",
                args.multisig_aave_math,
            )
        elif args.testnet_command == "change-owner-mock-underlyings":
            change_ownership(
                args.deployer,
                args.fullnode,
                "aave_mock_underlyings",
                args.multisig_mock_underlyings,
            )
        elif args.testnet_command == "change-owner-oracle":
            change_ownership(
                args.deployer,
                args.fullnode,
                "aave_oracle",
                args.multisig_aave_oracle,
            )
        elif args.testnet_command == "change-owner-core":
            change_ownership(
                args.deployer,
                args.fullnode,
                "aave_pool",
                args.multisig_aave_core,
            )
        elif args.testnet_command == "change-owner-data":
            change_ownership(
                args.deployer,
                args.fullnode,
                "aave_data",
                args.multisig_aave_data,
            )

        # handle upgrading commands
        elif args.testnet_command == "upgrade-config":
            upgrade_aave_config_multisig(
                args.deployer,
                args.fullnode,
                args.multisig_aave_config,
            )
        elif args.testnet_command == "upgrade-acl":
            upgrade_aave_acl_multisig(
                args.deployer,
                args.fullnode,
                args.multisig_aave_acl,
            )
        elif args.testnet_command == "upgrade-math":
            upgrade_aave_math_multisig(
                args.deployer,
                args.fullnode,
                args.multisig_aave_math,
            )
        elif args.testnet_command == "upgrade-mock-underlyings":
            upgrade_mock_underlyings_multisig(
                args.deployer,
                args.fullnode,
                args.multisig_mock_underlyings,
            )
        elif args.testnet_command == "upgrade-oracle":
            upgrade_aave_oracle_multisig(
                args.deployer,
                args.fullnode,
                args.multisig_aave_oracle,
            )
        elif args.testnet_command == "upgrade-core":
            upgrade_aave_core_multisig(
                args.deployer,
                args.fullnode,
                args.multisig_aave_core,
                chunk_size=40000,
                large_packages_module_address=args.large_packages_module,
            )
        elif args.testnet_command == "upgrade-data":
            upgrade_aave_data_multisig(
                args.deployer,
                args.fullnode,
                args.multisig_aave_data,
                chunk_size=40000,
                large_packages_module_address=args.large_packages_module,
            )

        # print help in case of an invalid command
        else:
            parser_testnet.print_help()

    elif args.chain == "mainnet":
        # start logging
        start_logging()
        logging.info(
            "Starting deployment on mainnet using deployer profile '%s'",
            args.deployer,
        )

        # provision chainlink addresses
        _set_deployed_address("platform", args.chainlink_platform)
        _set_deployed_address("data_feeds", args.chainlink_data_feeds)

        # handle miscellaneous commands
        if args.mainnet_command == "clear-staging-area":
            clear_staging_area(
                args.deployer,
                args.fullnode,
                args.multisig_account,
                args.large_packages_module,
            )

        # handle publishing commands
        elif args.mainnet_command == "publish-config":
            publish_aave_config(args.deployer, args.fullnode, upgrade=False)
        elif args.mainnet_command == "publish-acl":
            publish_aave_acl(args.deployer, args.fullnode, upgrade=False)
        elif args.mainnet_command == "publish-math":
            publish_aave_math(args.deployer, args.fullnode, upgrade=False)
        elif args.mainnet_command == "publish-mock-underlyings":
            publish_mock_underlyings(args.deployer, args.fullnode, upgrade=False)
        elif args.mainnet_command == "publish-oracle":
            publish_aave_oracle(args.deployer, args.fullnode, upgrade=False)
        elif args.mainnet_command == "publish-core":
            publish_aave_core(args.deployer, args.fullnode, upgrade=False)
        elif args.mainnet_command == "publish-data":
            publish_aave_data(args.deployer, args.fullnode, upgrade=False)

        # handle configuration commands
        elif args.mainnet_command == "configure-acl":
            configure_acl(
                args.deployer,
                args.fullnode,
                args.multisig_aave_acl,
                "mainnet",
            )
        elif args.mainnet_command == "setup-configure-emodes":
            setup_configure_emodes(
                args.deployer,
                args.fullnode,
                args.multisig_pool_admin,
                "mainnet",
            )
        elif args.mainnet_command == "setup-create-reserves":
            setup_create_reserves(
                args.deployer,
                args.fullnode,
                args.multisig_pool_admin,
                "mainnet",
            )
        elif args.mainnet_command == "setup-configure-reserves":
            setup_configure_reserves(
                args.deployer,
                args.fullnode,
                args.multisig_pool_admin,
                "mainnet",
            )
        elif args.mainnet_command == "setup-configure-interest-rates":
            setup_configure_interest_rates(
                args.deployer,
                args.fullnode,
                args.multisig_pool_admin,
                "mainnet",
            )
        elif args.mainnet_command == "setup-configure-price-feeds":
            setup_configure_price_feeds(
                args.deployer,
                args.fullnode,
                args.multisig_pool_admin,
                "mainnet",
            )

        # handle ownership commands
        elif args.mainnet_command == "change-owner-config":
            change_ownership(
                args.deployer,
                args.fullnode,
                "aave_config",
                args.multisig_aave_config,
            )
        elif args.mainnet_command == "change-owner-acl":
            change_ownership(
                args.deployer,
                args.fullnode,
                "aave_acl",
                args.multisig_aave_acl,
            )
        elif args.mainnet_command == "change-owner-math":
            change_ownership(
                args.deployer,
                args.fullnode,
                "aave_math",
                args.multisig_aave_math,
            )
        elif args.mainnet_command == "change-owner-mock-underlyings":
            change_ownership(
                args.deployer,
                args.fullnode,
                "aave_mock_underlyings",
                args.multisig_mock_underlyings,
            )
        elif args.mainnet_command == "change-owner-oracle":
            change_ownership(
                args.deployer,
                args.fullnode,
                "aave_oracle",
                args.multisig_aave_oracle,
            )
        elif args.mainnet_command == "change-owner-core":
            change_ownership(
                args.deployer,
                args.fullnode,
                "aave_pool",
                args.multisig_aave_core,
            )
        elif args.mainnet_command == "change-owner-data":
            change_ownership(
                args.deployer,
                args.fullnode,
                "aave_data",
                args.multisig_aave_data,
            )

        # handle upgrading commands
        elif args.mainnet_command == "upgrade-config":
            upgrade_aave_config_multisig(
                args.deployer,
                args.fullnode,
                args.multisig_aave_config,
            )
        elif args.mainnet_command == "upgrade-acl":
            upgrade_aave_acl_multisig(
                args.deployer,
                args.fullnode,
                args.multisig_aave_acl,
            )
        elif args.mainnet_command == "upgrade-math":
            upgrade_aave_math_multisig(
                args.deployer,
                args.fullnode,
                args.multisig_aave_math,
            )
        elif args.mainnet_command == "upgrade-mock-underlyings":
            upgrade_mock_underlyings_multisig(
                args.deployer,
                args.fullnode,
                args.multisig_mock_underlyings,
            )
        elif args.mainnet_command == "upgrade-oracle":
            upgrade_aave_oracle_multisig(
                args.deployer,
                args.fullnode,
                args.multisig_aave_oracle,
            )
        elif args.mainnet_command == "upgrade-core":
            upgrade_aave_core_multisig(
                args.deployer,
                args.fullnode,
                args.multisig_aave_core,
                chunk_size=40000,
                large_packages_module_address=args.large_packages_module,
            )
        elif args.mainnet_command == "upgrade-data":
            upgrade_aave_data_multisig(
                args.deployer,
                args.fullnode,
                args.multisig_aave_data,
                chunk_size=40000,
                large_packages_module_address=args.large_packages_module,
            )

        # print help in case of an invalid command
        else:
            parser_mainnet.print_help()

    else:
        parser.print_help()


if __name__ == "__main__":
    main()
