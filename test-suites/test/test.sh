#!/bin/bash

# Run Jest tests with a delay between each test
jest test/aave-oracle.spec.ts && sleep 5
jest test/acl-manager.spec.ts && sleep 5
jest test/atoken-delegation-aware.spec.ts && sleep 5
jest test/atoken-event-accounting.spec.ts && sleep 5
jest test/atoken-events.spec.ts && sleep 5
jest test/atoken-modifiers.spec.ts && sleep 5
jest test/atoken-permit.spec.ts && sleep 5
jest test/configurator.spec.ts && sleep 5
jest test/liquidation-atoken.spec.ts && sleep 5
jest test/liquidation-edge.spec.ts && sleep 5
jest test/liquidation-emode-interest.spec.ts && sleep 5
jest test/liquidation-emode.spec.ts && sleep 5
jest test/liquidation-with-fee.spec.ts && sleep 5
jest test/liquidity-indexes.spec.ts && sleep 5
jest test/ltv-validation.spec.ts && sleep 5
jest test/mint-to-treasury.spec.ts && sleep 5
jest test/pool-drop-reserve.spec.ts && sleep 5
jest test/pool-edge.spec.ts && sleep 5
jest test/pool-get-reserve-address-by-id.spec.ts && sleep 5
jest test/rate-strategy.spec.ts && sleep 5
jest test/supply.spec.ts && sleep 5
jest test/variable-debt-token-events.spec.ts && sleep 5
jest test/variable-debt-token.spec.ts && sleep 5
jest test/wadraymath.spec.ts && sleep 5