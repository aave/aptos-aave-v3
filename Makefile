# Conditionally include .env file if not running in CI/CD environment
ifndef GITHUB_ACTIONS
  -include .env
endif

# ===================== PROFILES ====================== #

# aave base profiles
AAVE_BASE_PROFILES_KEY_MAP = aave_acl=$(AAVE_ACL_PRIVATE_KEY) \
                 aave_config=$(AAVE_CONFIG_PRIVATE_KEY) \
                 aave_math=$(AAVE_MATH_PRIVATE_KEY) \
                 aave_oracle=$(AAVE_ORACLE_PRIVATE_KEY) \
                 aave_pool=$(AAVE_POOL_PRIVATE_KEY) \
                 aave_large_packages=$(AAVE_LARGE_PACKAGES_PRIVATE_KEY) \
				 aave_mock_underlyings=$(AAVE_MOCK_UNDERLYING_TOKENS_PRIVATE_KEY) \
                 aave_data=$(AAVE_DATA_PRIVATE_KEY)

ifeq ($(APTOS_NETWORK), local)
  AAVE_PROFILES_KEY_MAP = $(AAVE_BASE_PROFILES_KEY_MAP) data_feeds=$(AAVE_DATA_FEEDS_PRIVATE_KEY) platform=$(AAVE_PLATFORM_PRIVATE_KEY)
else
  AAVE_PROFILES_KEY_MAP = $(AAVE_BASE_PROFILES_KEY_MAP)
endif

AAVE_PROFILES := $(shell echo $(AAVE_PROFILES_KEY_MAP) | tr ' ' '\n' | cut -d '=' -f1)

# test user profiles
TEST_PROFILES_KEY_MAP = test_account_0=$(TEST_ACCOUNT_0_PRIVATE_KEY) \
                      test_account_1=$(TEST_ACCOUNT_1_PRIVATE_KEY) \
                      test_account_2=$(TEST_ACCOUNT_2_PRIVATE_KEY) \
                      test_account_3=$(TEST_ACCOUNT_3_PRIVATE_KEY) \
                      test_account_4=$(TEST_ACCOUNT_4_PRIVATE_KEY) \
                      test_account_5=$(TEST_ACCOUNT_5_PRIVATE_KEY)

TEST_PROFILES := $(shell echo $(TEST_PROFILES_KEY_MAP) | tr ' ' '\n' | cut -d '=' -f1)

# ===================== NAMED ADDRESSES ===================== #

# resource named addresses
AAVE_ORACLE_ADDRESS := $(shell [ -f .aptos/config.yaml ] && yq '.profiles.aave_oracle.account' .aptos/config.yaml || echo "")
AAVE_DATA_ADDRESS := $(shell [ -f .aptos/config.yaml ] && yq '.profiles.aave_data.account' .aptos/config.yaml || echo "")
LARGE_PACKAGE_ADDRESS := $(shell [ -f .aptos/config.yaml ] && yq '.profiles.aave_large_packages.account' .aptos/config.yaml || echo "")

RESOURCE_NAMED_ADDRESSES := aave_oracle_racc_address=$(shell \
    [ -n "$(AAVE_ORACLE_ADDRESS)" ] && \
    aptos account derive-resource-account-address \
        --address "$(AAVE_ORACLE_ADDRESS)" \
        --seed "AAVE_ORACLE" \
        --seed-encoding "Utf8" | jq -r '.Result' || \
    echo "")

ORACLE_NAMED_ADDRESSES := $(shell \
  if [ -n "$(CHAINLINK_DATA_FEEDS)" ] && [ -n "$(CHAINLINK_PLATFORM)" ]; then \
    echo ", data_feeds=$(CHAINLINK_DATA_FEEDS), platform=$(CHAINLINK_PLATFORM)"; \
  else \
    echo ""; \
  fi)

define AAVE_NAMED_ADDRESSES
$(foreach profile,$(AAVE_PROFILES),$(profile)=$(profile),) \
$(RESOURCE_NAMED_ADDRESSES) \
$(ORACLE_NAMED_ADDRESSES)
endef

# ======================= CLEAN ====================== #

clean-package-%:
	cd ./aave-core/aave-$* && rm -rf build

clean-core:
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
	aptos node run-localnet \
	--assume-yes \
	--no-txn-stream \
	--force-restart \
	--faucet-port 8081 \
	--performance

local-testnet-with-indexer:
	aptos node run-localnet \
	--assume-yes \
	--force-restart \
	--faucet-port 8081 \
	--performance \
	--with-indexer-api

local-testnet-docker:
	aptos node run-localnet \
	--performance \
	--with-indexer-api \
	--indexer-api-port 8090 \
	--faucet-port 8081 \
	--use-host-postgres \
	--host-postgres-host "postgres" \
	--host-postgres-port 5432 \
	--host-postgres-password "postgres" \
	--postgres-user "postgres" \
	--postgres-database "indexer" \
	--existing-hasura-url http://hasura:8080

ts-test:
	cd aave-test-suite && \
	@pnpm i && \
	@pnpm run deploy:init-data && \
	@pnpm run deploy:core-operations && \
	@pnpm run test

test-all:
	make test-acl
	make test-config
	make test-math
	make test-chainlink-platform
	make test-chainlink-data-feeds
	make test-mock-underlyings
	make test-oracle
	make test-pool

# ===================== PROFILES ===================== #

init-profiles:
	@echo "Using fixed aave profiles"
	@for profile in $(shell echo $(AAVE_PROFILES_KEY_MAP) | tr ' ' '\n' | cut -d '=' -f 1); do \
		PRIVATE_KEY=$$(echo $(AAVE_PROFILES_KEY_MAP) | tr ' ' '\n' | grep "^$$profile=" | cut -d '=' -f2); \
		echo "Initializing profile: $$profile ..."; \
		echo | aptos init --profile $$profile --network $(APTOS_NETWORK) --assume-yes --skip-faucet --private-key $$PRIVATE_KEY; \
	done

init-test-profiles:
	@echo "Using fixed test profiles"
	@for profile in $(shell echo $(TEST_PROFILES_KEY_MAP) | tr ' ' '\n' | cut -d '=' -f 1); do \
		PRIVATE_KEY=$$(echo $(TEST_PROFILES_KEY_MAP) | tr ' ' '\n' | grep "^$$profile=" | cut -d '=' -f2); \
		echo "Initializing test profile: $$profile ..."; \
		echo | aptos init --profile $$profile --network $(APTOS_NETWORK) --assume-yes --skip-faucet --private-key $$PRIVATE_KEY; \
	done

fund-profiles:
	@for profile in $(AAVE_PROFILES); do \
		aptos account fund-with-faucet --account $$profile --amount $(DEFAULT_FUND_AMOUNT) --profile $$profile; \
	done

fund-test-profiles:
	@for profile in $(TEST_PROFILES); do \
		aptos account fund-with-faucet --account $$profile --amount $(DEFAULT_FUND_AMOUNT) --profile $$profile; \
	done

top-up-profiles:
	@for profile in $(AAVE_PROFILES); do \
		aptos account transfer --account $$profile --amount $(DEFAULT_FUND_AMOUNT) --assume-yes --private-key $(DEFAULT_FUNDER_PRIVATE_KEY); \
	done

top-up-test-profiles:
	@for profile in $(TEST_PROFILES); do \
		aptos account transfer --account $$profile --amount $(DEFAULT_FUND_AMOUNT) --assume-yes --private-key $(DEFAULT_FUNDER_PRIVATE_KEY); \
	done

# ===================== PACKAGE AAVE-ACL ===================== #

compile-acl:
	cd aave-core && aptos move compile \
	--included-artifacts $(ARTIFACTS_LEVEL) \
	--save-metadata \
	--package-dir "aave-acl" \
	--skip-fetch-latest-git-deps \
	--language-version "$(MOVE_VERSION)" \
	--compiler-version "$(COMPILER_VERSION)" \
	--named-addresses "${AAVE_NAMED_ADDRESSES}"

publish-acl:
	cd aave-core && aptos move publish --assume-yes \
	--package-dir "aave-acl" \
	--included-artifacts $(ARTIFACTS_LEVEL) \
	--sender-account aave_acl \
	--profile aave_acl \
	--skip-fetch-latest-git-deps \
	--language-version "$(MOVE_VERSION)" \
	--compiler-version "$(COMPILER_VERSION)" \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" \
	--gas-unit-price 100 \
	--max-gas 10000

json-acl:
	cd aave-core && aptos move build-publish-payload --assume-yes \
	--package-dir "aave-acl" \
	--skip-fetch-latest-git-deps \
	--json-output-file acl_output.json \
	--named-addresses "${AAVE_NAMED_ADDRESSES}"

test-acl:
	cd aave-core && aptos move test \
	--ignore-compile-warnings \
	--skip-attribute-checks \
	--package-dir "aave-acl" \
	--skip-fetch-latest-git-deps \
	--language-version "$(MOVE_VERSION)" \
	--compiler-version "$(COMPILER_VERSION)" \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" \
  	--coverage

coverage-acl:
	cd aave-core && aptos move coverage summary \
	--skip-attribute-checks \
	--package-dir "aave-acl" \
	--skip-fetch-latest-git-deps \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" \
	--csv 2>&1 | tee ../coverage/aave-acl.csv

doc-acl:
	cd aave-core && aptos move document \
	--skip-attribute-checks \
	--package-dir "aave-acl" \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" && \
	mkdir -p ../my-docs/docs/aave-acl && \
	cp aave-acl/doc/* ../my-docs/docs/aave-acl

fmt-acl:
	aptos move fmt \
	--package-path "aave-core/aave-acl" \
	--config-path ./movefmt.toml \
	--emit-mode "overwrite" \
	-v

# ===================== PACKAGE AAVE-CONFIG ===================== #

compile-config:
	cd aave-core && aptos move compile \
	--included-artifacts $(ARTIFACTS_LEVEL) \
	--save-metadata \
	--package-dir "aave-config" \
	--skip-fetch-latest-git-deps \
	--language-version "$(MOVE_VERSION)" \
	--compiler-version "$(COMPILER_VERSION)" \
	--named-addresses "${AAVE_NAMED_ADDRESSES}"

publish-config:
	cd aave-core && aptos move publish --assume-yes \
	--package-dir "aave-config" \
	--included-artifacts $(ARTIFACTS_LEVEL) \
	--sender-account aave_config \
	--profile aave_config \
	--skip-fetch-latest-git-deps \
	--language-version "$(MOVE_VERSION)" \
	--compiler-version "$(COMPILER_VERSION)" \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" \
	--gas-unit-price 100 \
	--max-gas 50000

json-config:
	cd aave-core && aptos move build-publish-payload --assume-yes \
	--package-dir "aave-config" \
	--skip-fetch-latest-git-deps \
	--json-output-file config_output.json \
	--named-addresses "${AAVE_NAMED_ADDRESSES}"

test-config:
	cd aave-core && aptos move test \
	--ignore-compile-warnings \
	--skip-attribute-checks \
	--package-dir "aave-config" \
	--skip-fetch-latest-git-deps \
	--language-version "$(MOVE_VERSION)" \
	--compiler-version "$(COMPILER_VERSION)" \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" \
  	--coverage

coverage-config:
	cd aave-core && aptos move coverage summary \
	--skip-attribute-checks \
	--package-dir "aave-config" \
	--skip-fetch-latest-git-deps \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" \
	--csv 2>&1 | tee ../coverage/aave-config.csv

doc-config:
	cd aave-core && aptos move document \
	--skip-attribute-checks \
	--package-dir "aave-config" \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" && \
	mkdir -p ../my-docs/docs/aave-config && \
	cp aave-config/doc/* ../my-docs/docs/aave-config

fmt-config:
	aptos move fmt \
	--package-path "aave-core/aave-config" \
	--config-path ./movefmt.toml \
	--emit-mode "overwrite" \
	-v

# ===================== PACKAGE AAVE-LARGE-PACKAGES ===================== #

compile-large-packages:
	cd aave-core && aptos move compile \
	--included-artifacts $(ARTIFACTS_LEVEL) \
	--save-metadata \
	--package-dir "aave-large-packages" \
	--skip-fetch-latest-git-deps \
	--language-version "$(MOVE_VERSION)" \
	--compiler-version "$(COMPILER_VERSION)" \
	--named-addresses "${AAVE_NAMED_ADDRESSES}"

publish-large-packages:
	cd aave-core && aptos move publish --assume-yes \
	--package-dir "aave-large-packages" \
	--included-artifacts $(ARTIFACTS_LEVEL) \
	--sender-account aave_large_packages \
	--profile aave_large_packages \
	--skip-fetch-latest-git-deps \
	--language-version "$(MOVE_VERSION)" \
	--compiler-version "$(COMPILER_VERSION)" \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" \
	--gas-unit-price 100 \
	--max-gas 10000

json-large-packages:
	cd aave-core && aptos move build-publish-payload --assume-yes \
	--package-dir "aave-large-packages" \
	--skip-fetch-latest-git-deps \
	--json-output-file large_packages_output.json \
	--named-addresses "${AAVE_NAMED_ADDRESSES}"

clear-staging-large-packages:
	cd aave-core && aptos move clear-staging-area --assume-yes \
	--large-packages-module-address "$(LARGE_PACKAGE_ADDRESS)" \
	--sender-account aave_large_packages \
	--profile aave_large_packages \
	--gas-unit-price 100 \
	--max-gas 10000

test-large-packages:
	cd aave-core && aptos move test \
	--ignore-compile-warnings \
	--skip-attribute-checks \
	--package-dir "aave-large-packages" \
	--skip-fetch-latest-git-deps \
	--language-version "$(MOVE_VERSION)" \
	--compiler-version "$(COMPILER_VERSION)" \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" \
  	--coverage

doc-large-packages:
	cd aave-core && aptos move document \
	--skip-attribute-checks \
	--package-dir "aave-large-packages" \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" && \
	mkdir -p ../my-docs/docs/aave-large-packages && \
	cp aave-large-packages/doc/* ../my-docs/docs/aave-large-packages

fmt-large-packages:
	aptos move fmt \
	--package-path "aave-core/aave-large-packages" \
	--config-path ./movefmt.toml \
	--emit-mode "overwrite" \
	-v

# ===================== PACKAGE AAVE-MATH ===================== #

compile-math:
	cd aave-core && aptos move compile \
	--included-artifacts $(ARTIFACTS_LEVEL) \
	--save-metadata \
	--package-dir "aave-math" \
	--skip-fetch-latest-git-deps \
	--language-version "$(MOVE_VERSION)" \
	--compiler-version "$(COMPILER_VERSION)" \
	--named-addresses "${AAVE_NAMED_ADDRESSES}"

publish-math:
	cd aave-core && aptos move publish --assume-yes \
	--package-dir "aave-math" \
	--included-artifacts $(ARTIFACTS_LEVEL) \
	--sender-account aave_math \
	--profile aave_math \
	--skip-fetch-latest-git-deps \
	--language-version "$(MOVE_VERSION)" \
	--compiler-version "$(COMPILER_VERSION)" \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" \
	--gas-unit-price 100 \
	--max-gas 10000

json-math:
	cd aave-core && aptos move build-publish-payload --assume-yes \
	--package-dir "aave-math" \
	--skip-fetch-latest-git-deps \
	--json-output-file math_output.json \
	--named-addresses "${AAVE_NAMED_ADDRESSES}"

test-math:
	cd aave-core && aptos move test \
	--ignore-compile-warnings \
	--skip-attribute-checks \
	--package-dir "aave-math" \
	--skip-fetch-latest-git-deps \
	--language-version "$(MOVE_VERSION)" \
	--compiler-version "$(COMPILER_VERSION)" \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" \
  	--coverage

coverage-math:
	cd aave-core && aptos move coverage summary \
	--skip-attribute-checks \
	--package-dir "aave-math" \
	--skip-fetch-latest-git-deps \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" \
	--csv 2>&1 | tee ../coverage/aave-math.csv

doc-math:
	cd aave-core && aptos move document \
	--skip-attribute-checks \
	--package-dir "aave-math" \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" && \
	mkdir -p ../my-docs/docs/aave-math && \
	cp aave-math/doc/* ../my-docs/docs/aave-math

fmt-math:
	aptos move fmt \
	--package-path "aave-core/aave-math" \
	--config-path ./movefmt.toml \
	--emit-mode "overwrite" \
	-v

# ===================== PACKAGE AAVE-DATA ===================== #

compile-data:
	cd aave-core && aptos move compile \
	--included-artifacts $(ARTIFACTS_LEVEL) \
	--save-metadata \
	--package-dir "aave-data" \
	--skip-fetch-latest-git-deps \
	--language-version "$(MOVE_VERSION)" \
	--compiler-version "$(COMPILER_VERSION)" \
	--named-addresses "${AAVE_NAMED_ADDRESSES}"

publish-data:
	cd aave-core && aptos move publish --assume-yes \
	--package-dir "aave-data" \
	--included-artifacts $(ARTIFACTS_LEVEL) \
	--chunked-publish \
	--sender-account aave_data \
	--profile aave_data \
	--skip-fetch-latest-git-deps \
	--language-version "$(MOVE_VERSION)" \
	--compiler-version "$(COMPILER_VERSION)" \
	--large-packages-module-address "$(LARGE_PACKAGE_ADDRESS)" \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" \
	--chunk-size 45000 \
	--gas-unit-price 100 \
	--max-gas 300000

test-data:
	cd aave-core && aptos move test \
	--ignore-compile-warnings \
	--skip-attribute-checks \
	--package-dir "aave-data" \
	--skip-fetch-latest-git-deps \
	--language-version "$(MOVE_VERSION)" \
	--compiler-version "$(COMPILER_VERSION)" \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" \
  	--coverage

fmt-data:
	aptos move fmt \
	--package-path "aave-core/aave-data" \
	--config-path ./movefmt.toml \
	--emit-mode "overwrite" \
	-v

# ===================== PACKAGES CHAINLINK ===================== #

compile-chainlink-platform:
	cd aave-core && aptos move compile \
	--included-artifacts $(ARTIFACTS_LEVEL) \
    --save-metadata \
	--package-dir "chainlink-platform" \
	--skip-fetch-latest-git-deps \
	--language-version "$(MOVE_VERSION)" \
	--compiler-version "$(COMPILER_VERSION)" \
	--named-addresses "${AAVE_NAMED_ADDRESSES}"

test-chainlink-platform:
	cd aave-core && aptos move test \
	--ignore-compile-warnings \
	--skip-attribute-checks \
	--package-dir "chainlink-platform" \
	--skip-fetch-latest-git-deps \
	--language-version "$(MOVE_VERSION)" \
	--compiler-version "$(COMPILER_VERSION)" \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" \
  	--coverage

publish-chainlink-platform:
	cd aave-core && aptos move publish --assume-yes \
	--package-dir "chainlink-platform" \
	--included-artifacts $(ARTIFACTS_LEVEL) \
	--sender-account platform \
	--profile platform \
	--skip-fetch-latest-git-deps \
	--language-version "$(MOVE_VERSION)" \
	--compiler-version "$(COMPILER_VERSION)" \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" \
	--gas-unit-price 100 \
	--max-gas 30000

json-chainlink-platform:
	cd aave-core && aptos move build-publish-payload --assume-yes \
	--package-dir "chainlink-platform" \
	--skip-fetch-latest-git-deps \
	--json-output-file chainlink_platform_output.json \
	--named-addresses "${AAVE_NAMED_ADDRESSES}"

compile-chainlink-data-feeds:
	cd aave-core && aptos move compile \
	--included-artifacts $(ARTIFACTS_LEVEL) \
    --save-metadata \
	--package-dir "chainlink-data-feeds" \
	--skip-fetch-latest-git-deps \
	--language-version "$(MOVE_VERSION)" \
	--compiler-version "$(COMPILER_VERSION)" \
	--named-addresses "${AAVE_NAMED_ADDRESSES}"

test-chainlink-data-feeds:
	cd aave-core && aptos move test \
	--ignore-compile-warnings \
	--skip-attribute-checks \
	--package-dir "chainlink-data-feeds" \
	--skip-fetch-latest-git-deps \
	--language-version "$(MOVE_VERSION)" \
	--compiler-version "$(COMPILER_VERSION)" \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" \
  	--coverage

publish-chainlink-data-feeds:
	cd aave-core && aptos move publish --assume-yes \
	--package-dir "chainlink-data-feeds" \
	--included-artifacts $(ARTIFACTS_LEVEL) \
	--sender-account data_feeds \
	--profile data_feeds \
	--skip-fetch-latest-git-deps \
	--language-version "$(MOVE_VERSION)" \
	--compiler-version "$(COMPILER_VERSION)" \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" \
	--gas-unit-price 100 \
	--max-gas 30000

json-chainlink-data-feeds:
	cd aave-core && aptos move build-publish-payload --assume-yes \
	--package-dir "chainlink-data-feeds" \
	--skip-fetch-latest-git-deps \
	--json-output-file chainlink_data_feeds_output.json \
	--named-addresses "${AAVE_NAMED_ADDRESSES}"

# ===================== PACKAGE MOCK UNDERLYINGS ===================== #

compile-mock-underlyings:
	cd aave-core && aptos move compile \
	--included-artifacts $(ARTIFACTS_LEVEL) \
    --save-metadata \
	--package-dir "aave-mock-underlyings" \
	--skip-fetch-latest-git-deps \
	--language-version "$(MOVE_VERSION)" \
	--compiler-version "$(COMPILER_VERSION)" \
	--named-addresses "${AAVE_NAMED_ADDRESSES}"

test-mock-underlyings:
	cd aave-core && aptos move test \
	--ignore-compile-warnings \
	--skip-attribute-checks \
	--package-dir "aave-mock-underlyings" \
	--skip-fetch-latest-git-deps \
	--language-version "$(MOVE_VERSION)" \
	--compiler-version "$(COMPILER_VERSION)" \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" \
  	--coverage

publish-mock-underlyings:
	cd aave-core && aptos move publish --assume-yes \
	--package-dir "aave-mock-underlyings" \
	--included-artifacts $(ARTIFACTS_LEVEL) \
	--sender-account aave_mock_underlyings \
	--profile aave_mock_underlyings \
	--skip-fetch-latest-git-deps \
	--language-version "$(MOVE_VERSION)" \
	--compiler-version "$(COMPILER_VERSION)" \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" \
	--gas-unit-price 100 \
	--max-gas 30000

json-mock-underlyings:
	cd aave-core && aptos move build-publish-payload --assume-yes \
	--package-dir "aave-mock-underlyings" \
	--skip-fetch-latest-git-deps \
	--json-output-file mock_underlyings_output.json \
	--named-addresses "${AAVE_NAMED_ADDRESSES}"

doc-mock-underlyings:
	cd aave-core && aptos move document \
	--skip-attribute-checks \
	--package-dir "aave-mock-underlyings" \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" && \
	mkdir -p ../my-docs/docs/aave-mock-underlyings && \
	cp aave-mock-underlyings/doc/* ../my-docs/docs/aave-mock-underlyings

fmt-mock-underlyings:
	aptos move fmt \
	--package-path "aave-core/aave-mock-underlyings" \
	--config-path ./movefmt.toml \
	--emit-mode "overwrite" \
	-v

# ===================== PACKAGE AAVE-ORACLE ===================== #

compile-oracle:
	cd aave-core && aptos move compile \
	--included-artifacts $(ARTIFACTS_LEVEL) \
    --save-metadata \
	--package-dir "aave-oracle" \
	--skip-fetch-latest-git-deps \
	--language-version "$(MOVE_VERSION)" \
	--compiler-version "$(COMPILER_VERSION)" \
	--named-addresses "${AAVE_NAMED_ADDRESSES}"

publish-oracle:
	cd aave-core && aptos move publish --assume-yes \
	--package-dir "aave-oracle" \
	--included-artifacts $(ARTIFACTS_LEVEL) \
	--sender-account aave_oracle \
	--profile aave_oracle \
	--skip-fetch-latest-git-deps \
	--language-version "$(MOVE_VERSION)" \
	--compiler-version "$(COMPILER_VERSION)" \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" \
	--gas-unit-price 100 \
	--max-gas 20000

json-oracle:
	cd aave-core && aptos move build-publish-payload --assume-yes \
	--package-dir "aave-oracle" \
	--skip-fetch-latest-git-deps \
	--json-output-file oracle_output.json \
	--named-addresses "${AAVE_NAMED_ADDRESSES}"

test-oracle:
	cd aave-core && aptos move test \
	--ignore-compile-warnings \
	--skip-attribute-checks \
	--package-dir "aave-oracle" \
	--skip-fetch-latest-git-deps \
	--language-version "$(MOVE_VERSION)" \
	--compiler-version "$(COMPILER_VERSION)" \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" \
  	--coverage

coverage-oracle:
	cd aave-core && aptos move coverage summary \
	--skip-attribute-checks \
	--package-dir "aave-oracle" \
	--skip-fetch-latest-git-deps \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" \
	--csv 2>&1 | tee ../coverage/aave-oracle.csv

doc-oracle:
	cd aave-core && aptos move document \
	--skip-attribute-checks \
	--package-dir "aave-oracle" \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" && \
	mkdir -p ../my-docs/docs/aave-oracle && \
	cp aave-oracle/doc/* ../my-docs/docs/aave-oracle

fmt-oracle:
	aptos move fmt \
	--package-path "aave-core/aave-oracle" \
	--config-path ./movefmt.toml \
	--emit-mode "overwrite" \
	-v

# ===================== PACKAGE AAVE-POOL ===================== #

compile-pool:
	cd aave-core && aptos move compile \
	--included-artifacts $(ARTIFACTS_LEVEL) \
	--save-metadata \
	--skip-fetch-latest-git-deps \
	--language-version "$(MOVE_VERSION)" \
	--compiler-version "$(COMPILER_VERSION)" \
	--named-addresses "${AAVE_NAMED_ADDRESSES}"

publish-pool:
	cd aave-core && aptos move publish --assume-yes \
	--included-artifacts $(ARTIFACTS_LEVEL) \
	--chunked-publish \
	--sender-account aave_pool \
	--profile aave_pool \
	--skip-fetch-latest-git-deps \
	--language-version "$(MOVE_VERSION)" \
	--compiler-version "$(COMPILER_VERSION)" \
	--large-packages-module-address "$(LARGE_PACKAGE_ADDRESS)" \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" \
	--chunk-size 45000 \
	--gas-unit-price 100 \
	--max-gas 300000

json-pool:
	cd aave-core && aptos move build-publish-payload --assume-yes \
	--package-dir "aave-pool" \
	--skip-fetch-latest-git-deps \
	--json-output-file pool_output.json \
	--named-addresses "${AAVE_NAMED_ADDRESSES}"

publish-pool-local:
	cd aave-test-suite && \
	pnpm run publish-pool-package

test-pool:
	cd aave-core && aptos move test \
	--ignore-compile-warnings \
	--skip-attribute-checks \
	--skip-fetch-latest-git-deps \
	--language-version "$(MOVE_VERSION)" \
	--compiler-version "$(COMPILER_VERSION)" \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" \
  	--coverage

coverage-pool:
	cd aave-core && aptos move coverage summary \
	--skip-attribute-checks \
	--skip-fetch-latest-git-deps \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" \
	--csv 2>&1 | tee ../coverage/aave-pool.csv

doc-pool:
	cd aave-core && aptos move document \
	--skip-attribute-checks \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" && \
	mkdir -p ../my-docs/docs/aave-pool && \
	cp doc/* ../my-docs/docs/aave-pool

fmt-pool:
	aptos move fmt \
	--package-path "aave-core" \
	--config-path ./movefmt.toml \
	--emit-mode "overwrite" \
	-v

# ===================== AAVE-CONFIGURATOR ===================== #

configure-acl:
	aptos move run \
	--assume-yes \
	--sender-account aave_acl \
	--profile aave_acl \
	--function-id '0x${AAVE_DATA_ADDRESS}::v1_deployment::configure_acl' \
	--args string:testnet

configure-emodes:
	aptos multisig create-transaction \
	--assume-yes \
	--multisig-address ${AAVE_POOL_ADMIN_MULTISIG_ADDRESS} \
	--private-key ${AAVE_POOL_ADMIN_PRIVATE_KEY} \
	--function-id '0x${AAVE_DATA_ADDRESS}::v1_deployment::configure_emodes' \
	--args string:$(APTOS_NETWORK)

create-reserves:
	aptos multisig create-transaction \
	--assume-yes \
	--multisig-address ${AAVE_POOL_ADMIN_MULTISIG_ADDRESS} \
	--private-key ${AAVE_POOL_ADMIN_PRIVATE_KEY} \
	--function-id '0x${AAVE_DATA_ADDRESS}::v1_deployment::create_reserves' \
	--args string:$(APTOS_NETWORK)

configure-reserves:
	aptos multisig create-transaction \
	--assume-yes \
	--multisig-address ${AAVE_POOL_ADMIN_MULTISIG_ADDRESS} \
	--private-key ${AAVE_POOL_ADMIN_PRIVATE_KEY} \
	--function-id '0x${AAVE_DATA_ADDRESS}::v1_deployment::configure_reserves' \
	--args string:$(APTOS_NETWORK)

configure-interest-rates:
	aptos multisig create-transaction \
	--assume-yes \
	--multisig-address ${AAVE_POOL_ADMIN_MULTISIG_ADDRESS} \
	--private-key ${AAVE_POOL_ADMIN_PRIVATE_KEY} \
	--function-id '0x${AAVE_DATA_ADDRESS}::v1_deployment::configure_interest_rates' \
	--args string:$(APTOS_NETWORK)

configure-price-feeds:
	aptos multisig create-transaction \
	--assume-yes \
	--multisig-address ${AAVE_POOL_ADMIN_MULTISIG_ADDRESS} \
	--private-key ${AAVE_POOL_ADMIN_PRIVATE_KEY} \
	--function-id '0x${AAVE_DATA_ADDRESS}::v1_deployment::configure_price_feeds' \
	--args string:$(APTOS_NETWORK)

# ===================== GLOBAL COMMANDS ===================== #

ifeq ($(APTOS_NETWORK), local)
COMPILE_CHAINLINK_TARGETS := compile-chainlink-platform compile-chainlink-data-feeds
PUBLISH_CHAINLINK_TARGETS := publish-chainlink-platform publish-chainlink-data-feeds
else
COMPILE_CHAINLINK_TARGETS :=
PUBLISH_CHAINLINK_TARGETS :=
endif

compile-all:
	make compile-config
	make compile-acl
	make compile-large-packages
	make compile-math
	@for target in $(COMPILE_CHAINLINK_TARGETS); do \
	    make $$target; \
	done
	make compile-oracle
	make compile-mock-underlyings
	make compile-pool
	make compile-data

publish-all:
	make publish-config
	make publish-acl
	make publish-large-packages
	make publish-math
	@for target in $(PUBLISH_CHAINLINK_TARGETS); do \
	    make $$target; \
	done
	make publish-oracle
	make publish-mock-underlyings
	make publish-pool
	make publish-data

json-all:
	make json-config
	make json-acl
	make json-large-packages
	make json-math
	make json-chainlink-platform
	make json-chainlink-data-feeds
	make json-oracle
	make json-mock-underlyings
	make json-pool

doc-all:
	make doc-config
	make doc-acl
	make doc-large-packages
	make doc-math
	make doc-oracle
	make doc-mock-underlyings
	make doc-pool

clean-all:
	make clean-package-config
	make clean-package-acl
	make clean-package-large-packages
	make clean-package-math
	make clean-chainlink-platform
	make clean-chainlink-data-feeds
	make clean-package-oracle
	make clean-mock-underlyings
	make clean-core
	make clean-data

# ------------------------------------------------------------
# Coverage
# ------------------------------------------------------------

coverage-all:
	make coverage-config
	make coverage-acl
	make coverage-math
	make coverage-oracle
	make coverage-pool

# ------------------------------------------------------------
# Formatting
# ------------------------------------------------------------

fmt: fmt-move fmt-prettier fmt-markdown

# fmt & lint all directories
fmt-move:
	make fmt-acl
	make fmt-config
	make fmt-large-packages
	make fmt-math
	make fmt-oracle
	make fmt-pool
	make fmt-mock-underlyings
	make fmt-data

fmt-prettier:
	pnpm prettier:fix

fmt-markdown:
	pnpm md:fix

# ------------------------------------------------------------
# Validate code
# ------------------------------------------------------------

lint-prettier:
	pnpm prettier:validate

lint-markdown:
	pnpm md:lint

lint-codespell: ensure-codespell
	codespell --skip "*.json"

ensure-codespell:
	@if ! command -v codespell &> /dev/null; then \
		echo "codespell not found. Please install it by running the command `pip install codespell` or refer to the following link for more information: https://github.com/codespell-project/codespell" \
		exit 1; \
    fi

lint:
	make lint-prettier && \
	make lint-markdown && \
	make fmt && \
	make lint-codespell

fix-lint:
	make fmt
