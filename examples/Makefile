# Conditionally include .env file if not running in CI/CD environment
ifndef GITHUB_ACTIONS
  -include ../.env
endif

compile-scripts-testnet:
		aptos move compile \
		--included-artifacts none \
		--save-metadata \
		--skip-fetch-latest-git-deps \
		--language-version "$(MOVE_VERSION)" \
		--compiler-version "$(COMPILER_VERSION)" \
		--named-addresses "aave_acl=0xb23539ad6490a465e92e751943a3eaedf4b48d7d844ff59adf2ae66bcb09f53d,aave_config=0x4fb5d8348c8873295f97136bbe1c43d976fb18a4a966a85e21d16958eaecef99,aave_math=0xf6f896cefd7b1b1e85ff56033981cf92dcd5d6e93b1349a7ab5003761c52498d,aave_oracle=0xcb9eb79a52f41933192c2e1e37a9e72bfd726fdb9a687cd6cfe45527e52f4e41,aave_pool=0xbd7912c555a06809c2e385eab635ff0ef52b1fa062ce865c785c67694a12bb12,aave_large_packages=0x0e1ca3011bdd07246d4d16d909dbb2d6953a86c4735d5acf5865d962c630cce7,aave_mock_underlyings=0xe2b42cab2f84bf57edaf87bcaffee409c2b3d5243e3def00d9d2f7dec568d867,aave_data=0xb0ec364235f47ad2a8eb52d639c80579b11497d0711879840f1ce51c885b165f,data_feeds=0xf1099f135ddddad1c065203431be328a408b0ca452ada70374ce26bd2b32fdd3,platform=0x516e771e1b4a903afe74c27d057c65849ecc1383782f6642d7ff21425f4f9c99,aave_oracle_racc_address=0x3836084d178459c08f27620462d531f5b5b23d14ddbf4f47c4a72d404d87bcb4,gho=0x111,gho_config=0x112,gho_acl=0x113"

compile-scripts-mainnet:
		aptos move compile \
		--included-artifacts none \
		--save-metadata \
		--skip-fetch-latest-git-deps \
		--language-version "$(MOVE_VERSION)" \
		--compiler-version "$(COMPILER_VERSION)" \
		--named-addresses "aave_acl=0x34c3e6af238f3a7fa3f3b0088cbc4b194d21f62e65a15b79ae91364de5a81a3a,aave_config=0x531069f4741cdead39d70b76e5779863864654fae6db8a752a244ff2f9916c15,aave_math=0xc0338eea778de2a5348824ddbfcec033c7f7cbe18da6da40869562906b63c78c,aave_oracle=0x249676f3faddb83d64fd101baa3f84a171ae02505d796e3edbf4861038a4b5cc,aave_pool=0x39ddcd9e1a39fa14f25e3f9ec8a86074d05cc0881cbf667df8a6ee70942016fb,aave_large_packages=0x0e1ca3011bdd07246d4d16d909dbb2d6953a86c4735d5acf5865d962c630cce7,aave_mock_underlyings=0x12b05c42ac3209a3c6ffadff4ebb6c3e983e5115f26031d56652815b49a14245,aave_data=0x5eb5cc775c5a446db0f3a1c944e11563b97e6a7e1387b9fb459aa26168f738dc,data_feeds=0x3f985798ce4975f430ef5c75776ff98a77b9f9d0fb38184d225adc9c1cc6b79b,platform=0x9976bb288ed9177b542d568fa1ac386819dc99141630e582315804840f41928a,aave_oracle_racc_address=0x3836084d178459c08f27620462d531f5b5b23d14ddbf4f47c4a72d404d87bcb4,gho=0x111,gho_config=0x112,gho_acl=0x113"

execute-flashloan-simple-dry-run:
	aptos move run-script \
	--local \
	--assume-yes \
	--compiled-script-path ./build/Examples/bytecode_scripts/flashloan_simple.mv \
	--language-version "$(MOVE_VERSION)" \
	--compiler-version "$(COMPILER_VERSION)" \
	--sender-account "$(FLASHLOANER)" \
	--profile "$(FLASHLOANER)" \
	--args address:$(FLASHLOAN_ASSET) u256:$(FLASHLOAN_AMOUNT)

execute-flashloan-complex-dry-run:
	aptos move run-script \
	--local \
	--assume-yes \
	--compiled-script-path ./build/Examples/bytecode_scripts/flashloan_complex.mv \
	--language-version "$(MOVE_VERSION)" \
	--compiler-version "$(COMPILER_VERSION)" \
	--sender-account "$(FLASHLOANER)" \
	--profile "$(FLASHLOANER)" \
	--args address:$(FLASHLOAN_ASSET) u256:$(FLASHLOAN_AMOUNT)

execute-flashloan-simple:
	aptos move run-script \
	--assume-yes \
	--compiled-script-path ./build/Examples/bytecode_scripts/flashloan_simple.mv \
	--language-version "$(MOVE_VERSION)" \
	--compiler-version "$(COMPILER_VERSION)" \
	--sender-account "$(FLASHLOANER)" \
	--profile "$(FLASHLOANER)" \
	--args address:$(FLASHLOAN_ASSET) u256:$(FLASHLOAN_AMOUNT)

execute-flashloan-complex:
	aptos move run-script \
	--assume-yes \
	--compiled-script-path ./build/Examples/bytecode_scripts/flashloan_complex.mv \
	--language-version "$(MOVE_VERSION)" \
	--compiler-version "$(COMPILER_VERSION)" \
	--sender-account "$(FLASHLOANER)" \
	--profile "$(FLASHLOANER)" \
	--args address:$(FLASHLOAN_ASSET) u256:$(FLASHLOAN_AMOUNT)

fmt-scripts:
	aptos move fmt \
	--package-path "." \
	--config-path ../movefmt.toml \
	--emit-mode "overwrite" \
	-v

# ------------------------------------------------------------
# Common
# ------------------------------------------------------------

compile:
	make compile-scripts-testnet
	make compile-scripts-mainnet

fmt:
	make fmt-scripts

clean: rm -rf build
