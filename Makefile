# Conditionally include .env file if not running in CI/CD environment
ifndef GITHUB_ACTIONS
  -include .env
endif

# default env values
APTOS_NETWORK ?= local
ARTIFACTS_LEVEL ?= all
DEFAULT_FUND_AMOUNT ?= 100000000
DEFAULT_FUNDER_PRIVATE_KEY ?= 0x0
PYTH_HERMES_URL ?= https://hermes-beta.pyth.network
PYTH_CONTRACT_ACCOUNT ?= 0x0
PYTH_DEPLOYER_ACCOUNT ?= 0x0
PYTH_WORMHOLE ?= 0x0

# ===================== PRIVATE KEYS ===================== #

LARGE_PACKAGES_ACCOUNT_PRIVATE_KEY := 0xc9680e7b29b0a03344fb7e774f9919e5a99b62d25f4c00d91542571dde0e56e6

# ===================== PROFILES ===================== #

PROFILES := aave_acl \
            aave_config \
            aave_math \
            aave_oracle \
            aave_mock_oracle \
            aave_pool \
            a_tokens \
            underlying_tokens \
            variable_tokens \
            deployer_pm \
            resource_pm

TEST_PROFILES := test_account_0 \
                 test_account_1 \
                 test_account_2 \
                 test_account_3 \
                 test_account_4 \
                 test_account_5

ORACLE_PROFILES := pyth=$(PYTH_CONTRACT_ACCOUNT),deployer=$(PYTH_DEPLOYER_ACCOUNT),wormhole=$(PYTH_WORMHOLE)

LARGE_PACKAGES_PROFILE := aave_large_packages=aave_large_packages

# ===================== NAMED ADDRESSES ===================== #

define APTOS_NAMED_ADDRESSES
$(foreach profile,$(PROFILES),$(profile)=$(profile),)$(ORACLE_PROFILES),$(LARGE_PACKAGES_PROFILE)
endef

# ======================= CLEAN ====================== #
clean-package-%:
	cd ./aave-core/aave-$* && rm -rf build

clean-root:
	cd ./aave-core && rm -rf build
# ===================== CONFIG ===================== #

set-workspace-config:
	aptos config set-global-config \
	--config-type workspace \
	--default-prompt-response yes

init-workspace-config:
	@echo | aptos init \
	--network $(APTOS_NETWORK) \
	--private-key $(DEFAULT_FUNDER_PRIVATE_KEY) \
	--skip-faucet \
	--assume-yes

# ===================== TESTING ===================== #

local-testnet:
	aptos node run-local-testnet --with-faucet --force-restart

ts-test:
	cd test-suites && \
	@pnpm i && \
	@pnpm run init-data && \
	@pnpm run core-operations && \
	@pnpm run test

test-all:
	make test-acl
	make test-config
	make test-math
	make test-mock-oracle
	make test-pool

# ===================== PROFILES ===================== #

init-profiles:
	@for profile in $(PROFILES); do \
		echo | aptos init --profile $$profile --network $(APTOS_NETWORK) --assume-yes --skip-faucet; \
	done
	aptos init --profile aave_large_packages --network $(APTOS_NETWORK) --assume-yes --skip-faucet --private-key $(LARGE_PACKAGES_ACCOUNT_PRIVATE_KEY);

init-test-profiles:
	@for profile in $(TEST_PROFILES); do \
		echo | aptos init --profile $$profile --network $(APTOS_NETWORK) --assume-yes --skip-faucet; \
	done

fund-profiles:
	@for profile in $(PROFILES); do \
		aptos account fund-with-faucet --account $$profile --amount $(DEFAULT_FUND_AMOUNT) --profile $$profile  && sleep 5; \
	done
	aptos account fund-with-faucet --account aave_large_packages --amount $(DEFAULT_FUND_AMOUNT) --profile aave_large_packages;

fund-test-profiles:
	@for profile in $(TEST_PROFILES); do \
		aptos account fund-with-faucet --account $$profile --amount $(DEFAULT_FUND_AMOUNT) --profile $$profile  && sleep 5; \
	done

top-up-profiles:
	@for profile in $(PROFILES); do \
		aptos account transfer --account $$profile --amount $(DEFAULT_FUND_AMOUNT) --assume-yes --private-key $(DEFAULT_FUNDER_PRIVATE_KEY) && sleep 5; \
	done

top-up-test-profiles:
	@for profile in $(TEST_PROFILES); do \
		aptos account transfer --account $$profile --amount $(DEFAULT_FUND_AMOUNT) --assume-yes --private-key $(DEFAULT_FUNDER_PRIVATE_KEY) && sleep 5; \
	done

# ===================== PACKAGE AAVE-ACL ===================== #

compile-acl:
	cd aave-core && aptos move compile \
	--included-artifacts $(ARTIFACTS_LEVEL) \
	--save-metadata \
	--package-dir "aave-acl" \
	--named-addresses "${APTOS_NAMED_ADDRESSES}"

publish-acl:
	cd aave-core && aptos move publish --assume-yes \
	--package-dir "aave-acl" \
	--included-artifacts $(ARTIFACTS_LEVEL) \
	--sender-account aave_acl \
	--profile aave_acl \
	--named-addresses "${APTOS_NAMED_ADDRESSES}"

test-acl:
	cd aave-core && aptos move test \
	--ignore-compile-warnings \
	--skip-attribute-checks \
	--package-dir "aave-acl" \
	--named-addresses "${APTOS_NAMED_ADDRESSES}" \
  	--coverage

doc-acl:
	cd aave-core && aptos move document \
	--skip-attribute-checks \
	--package-dir "aave-acl" \
	--named-addresses "${APTOS_NAMED_ADDRESSES}"

# ===================== PACKAGE AAVE-CONFIG ===================== #

compile-config:
	cd aave-core && aptos move compile \
	--included-artifacts $(ARTIFACTS_LEVEL) \
	--save-metadata \
	--package-dir "aave-config" \
	--named-addresses "${APTOS_NAMED_ADDRESSES}"

publish-config:
	cd aave-core && aptos move publish --assume-yes \
	--package-dir "aave-config" \
	--included-artifacts $(ARTIFACTS_LEVEL) \
	--sender-account aave_config \
	--profile aave_config \
	--named-addresses "${APTOS_NAMED_ADDRESSES}"

test-config:
	cd aave-core && aptos move test \
	--ignore-compile-warnings \
	--skip-attribute-checks \
	--package-dir "aave-config" \
	--named-addresses "${APTOS_NAMED_ADDRESSES}" \
  	--coverage

doc-config:
	cd aave-core && aptos move document \
	--skip-attribute-checks \
	--package-dir "aave-config" \
	--named-addresses "${APTOS_NAMED_ADDRESSES}"

# ===================== PACKAGE AAVE-LARGE-PACKAGES ===================== #

compile-large-packages:
	cd aave-core && aptos move compile \
	--included-artifacts $(ARTIFACTS_LEVEL) \
	--save-metadata \
	--package-dir "aave-large-packages" \
	--named-addresses "${APTOS_NAMED_ADDRESSES}"

publish-large-packages:
	cd aave-core && aptos move publish --assume-yes \
	--package-dir "aave-large-packages" \
	--included-artifacts $(ARTIFACTS_LEVEL) \
	--sender-account aave_large_packages \
	--profile aave_large_packages \
	--named-addresses "${APTOS_NAMED_ADDRESSES}"

test-large-packages:
	cd aave-core && aptos move test \
	--ignore-compile-warnings \
	--skip-attribute-checks \
	--package-dir "aave-large-packages" \
	--named-addresses "${APTOS_NAMED_ADDRESSES}" \
  	--coverage

doc-large-packages:
	cd aave-core && aptos move document \
	--skip-attribute-checks \
	--package-dir "aave-large-packages" \
	--named-addresses "${APTOS_NAMED_ADDRESSES}"

# ===================== PACKAGE AAVE-MATH ===================== #

compile-math:
	cd aave-core && aptos move compile \
	--included-artifacts $(ARTIFACTS_LEVEL) \
	--save-metadata \
	--package-dir "aave-math" \
	--named-addresses "${APTOS_NAMED_ADDRESSES}"

publish-math:
	cd aave-core && aptos move publish --assume-yes \
	--package-dir "aave-math" \
	--included-artifacts $(ARTIFACTS_LEVEL) \
	--sender-account aave_math \
	--profile aave_math \
	--named-addresses "${APTOS_NAMED_ADDRESSES}"

test-math:
	cd aave-core && aptos move test \
	--ignore-compile-warnings \
	--skip-attribute-checks \
	--package-dir "aave-math" \
	--named-addresses "${APTOS_NAMED_ADDRESSES}" \
  	--coverage

doc-math:
	cd aave-core && aptos move document \
	--skip-attribute-checks \
	--package-dir "aave-math" \
	--named-addresses "${APTOS_NAMED_ADDRESSES}"

# ===================== PACKAGE AAVE-ORACLE ===================== #

compile-oracle:
	cd aave-core && aptos move compile \
	--included-artifacts $(ARTIFACTS_LEVEL) \
    --save-metadata \
	--package-dir "aave-oracle" \
	--named-addresses "${APTOS_NAMED_ADDRESSES}"

publish-oracle:
	cd aave-core && aptos move publish --assume-yes \
	--package-dir "aave-oracle" \
	--included-artifacts $(ARTIFACTS_LEVEL) \
	--sender-account aave_oracle \
	--profile aave_oracle \
	--named-addresses "${APTOS_NAMED_ADDRESSES}"

test-oracle:
	cd aave-core && aptos move test \
	--ignore-compile-warnings \
	--skip-attribute-checks \
	--package-dir "aave-oracle" \
	--named-addresses "${APTOS_NAMED_ADDRESSES}" \
  	--coverage

doc-oracle:
	cd aave-core && aptos move document \
	--skip-attribute-checks \
	--package-dir "aave-oracle" \
	--named-addresses "${APTOS_NAMED_ADDRESSES}"

# ===================== PACKAGE AAVE-MOCK-ORACLE ===================== #

compile-mock-oracle:
	cd aave-core && aptos move compile \
	--included-artifacts $(ARTIFACTS_LEVEL) \
    --save-metadata \
	--package-dir "aave-mock-oracle" \
	--named-addresses "${APTOS_NAMED_ADDRESSES}"

publish-mock-oracle:
	cd aave-core && aptos move publish --assume-yes \
	--package-dir "aave-mock-oracle" \
	--included-artifacts $(ARTIFACTS_LEVEL) \
	--sender-account aave_mock_oracle \
	--profile aave_mock_oracle \
	--named-addresses "${APTOS_NAMED_ADDRESSES}"

test-mock-oracle:
	cd aave-core && aptos move test \
	--ignore-compile-warnings \
	--skip-attribute-checks \
	--package-dir "aave-mock-oracle" \
	--named-addresses "${APTOS_NAMED_ADDRESSES}" \
  	--coverage

doc-mock-oracle:
	cd aave-core && aptos move document \
	--skip-attribute-checks \
	--package-dir "aave-mock-oracle" \
	--named-addresses "${APTOS_NAMED_ADDRESSES}"

# ===================== PACKAGE AAVE-POOL ===================== #

compile-pool:
	cd aave-core && aptos move compile \
	--included-artifacts $(ARTIFACTS_LEVEL) \
	--save-metadata \
	--named-addresses "${APTOS_NAMED_ADDRESSES}"

publish-pool:
	cd aave-core && aptos move publish --assume-yes \
	--included-artifacts $(ARTIFACTS_LEVEL) \
	--chunked-publish \
	--sender-account aave_pool \
	--profile aave_pool \
	--named-addresses "${APTOS_NAMED_ADDRESSES}"

publish-pool-local:
	cd test-suites && \
	pnpm run publish-pool-package

test-pool:
	cd aave-core && aptos move test \
	--ignore-compile-warnings \
	--skip-attribute-checks \
	--named-addresses "${APTOS_NAMED_ADDRESSES}" \
  	--coverage

doc-pool:
	cd aave-core && aptos move document \
	--skip-attribute-checks \
	--named-addresses "${APTOS_NAMED_ADDRESSES}"

# ===================== PACKAGE AAVE-SCRIPTS ===================== #

compile-scripts:
	cd aave-core && aptos move compile \
	--included-artifacts $(ARTIFACTS_LEVEL) \
    --save-metadata \
	--package-dir "aave-scripts" \
	--named-addresses "${APTOS_NAMED_ADDRESSES}"

run-script-post-publish:
	cd aave-core && \
    aptos move run-script \
    --assume-yes \
    --compiled-script-path aave-scripts/build/AaveScripts/bytecode_scripts/post_publish.mv \
    --sender-account=aave_acl \
    --profile=aave_acl

run-script-xxx:
	cd aave-core && \
    aptos move run-script \
    --assume-yes \
    --script-path aave-scripts/sources/post-publish.move \
    --sender-account=aave_acl \
    --profile=aave_acl

# ===================== GLOBAL COMMANDS ===================== #

compile-all:
	make compile-acl
	make compile-config
	@if [ "$(APTOS_NETWORK)" = "local" ]; then \
		make compile-large-packages; \
	else \
		echo "Skipping compile-large-packages for APTOS_NETWORK different to local"; \
	fi
	make compile-math
	make compile-mock-oracle
	make compile-pool

publish-all:
	make publish-acl
	make publish-config
	@if [ "$(APTOS_NETWORK)" = "local" ]; then \
		make publish-large-packages; \
	else \
		echo "Skipping publish-large-packages for APTOS_NETWORK different than local"; \
	fi
	make publish-math
	make publish-mock-oracle
	make publish-pool

doc-all:
	make doc-acl
	make doc-config
	make doc-large-packages
	make doc-math
	make doc-mock-oracle
	make doc-pool

clean-all:
	make clean-package-acl
	make clean-package-config
	make clean-large-packages
	make clean-package-math
	make clean-package-mock-oracle
	make clean-package-oracle
	make clean-root

# fmt & lint all directories
fmt-all:
	movefmt --config-path=./movefmt.toml --emit "files" -v