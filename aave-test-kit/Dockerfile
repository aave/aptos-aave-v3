#syntax=docker/dockerfile:1.4

FROM --platform=linux/amd64 debian:bookworm-slim

# Install required packages
RUN apt-get update -y \
  && apt-get upgrade -y \
  && apt-get install -y python3 python3-pip curl make wget git jq \
  && wget https://github.com/mikefarah/yq/releases/download/v4.34.1/yq_linux_amd64 -O /usr/local/bin/yq \
  && chmod +x /usr/local/bin/yq \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Aptos CLI
RUN curl -fsSL "https://aptos.dev/scripts/install_cli.py" | python3

ENV HOME="/root"
ENV PATH="$PATH:${HOME}/.local/bin"

# Set default environment variables, which can be overridden
ENV APTOS_NETWORK=local \
  ARTIFACTS_LEVEL=all \
  DEFAULT_FUND_AMOUNT=100000000 \
  MOVE_VERSION=2.1 \
  COMPILER_VERSION=2.0 \
  DEFAULT_FUNDER_PRIVATE_KEY=0x0 \
  AAVE_ACL_PRIVATE_KEY=0x0 \
  AAVE_CONFIG_PRIVATE_KEY=0x0 \
  AAVE_MATH_PRIVATE_KEY=0x0 \
  AAVE_ORACLE_PRIVATE_KEY=0x0 \
  AAVE_POOL_PRIVATE_KEY=0x0 \
  AAVE_MOCK_UNDERLYINGS_PRIVATE_KEY=0x0 \
  AAVE_LARGE_PACKAGES_PRIVATE_KEY=0x0 \
  AAVE_DATA_PRIVATE_KEY=0x0 \
  AAVE_DATA_FEEDS_PRIVATE_KEY=0x0 \
  AAVE_PLATFORM_PRIVATE_KEY=0x0 \
  DATA_FEEDS_PRIVATE_KEY=0x0 \
  PLATFORM_PRIVATE_KEY=0x0 \
  DEFAULT_PRIVATE_KEY=0x0 \
  TEST_ACCOUNT_0_PRIVATE_KEY=0x0 \
  TEST_ACCOUNT_1_PRIVATE_KEY=0x0 \
  TEST_ACCOUNT_2_PRIVATE_KEY=0x0 \
  TEST_ACCOUNT_3_PRIVATE_KEY=0x0 \
  TEST_ACCOUNT_4_PRIVATE_KEY=0x0 \
  TEST_ACCOUNT_5_PRIVATE_KEY=0x0

# Expose necessary ports
EXPOSE 8070 8080 8081 8090 9101 50051

# Set working directory to root, so "." can refer to root context
WORKDIR /

# Copy files to root directory of container
COPY . .

# Script to run the testnet and other make commands
COPY aave-test-kit/entrypoint.sh ./entrypoint.sh
RUN chmod +x ./entrypoint.sh

# Use the script as the entry point
ENTRYPOINT ["./entrypoint.sh"]
