import type { Config } from "jest";

const config: Config = {
  verbose: true,
  testEnvironment: "node",
  preset: "ts-jest",
  roots: ["<rootDir>"],
  testMatch: ["**/*.spec.ts"],
  transform: {
    "^.+\\.ts$": "ts-jest",
  },
  moduleNameMapper: {
    "@/(.*)": "<rootDir>/src/$1",
  },
  moduleFileExtensions: ["ts", "js", "json"],
  collectCoverage: true,
  setupFiles: ["dotenv/config"],
  // coverageThreshold: {
  //   global: {
  //     branches: 50, // 90,
  //     functions: 50, // 95,
  //     lines: 50, // 95,
  //     statements: 50, // 95,
  //   },
  // },
  testTimeout: 15000, // Add global timeout here
  // To help avoid exhausting all the available fds.
  maxWorkers: 4,
};

export default config;
