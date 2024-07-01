import { Aptos, AptosConfig } from "@aptos-labs/ts-sdk";
import path from "path";
import dotenv from "dotenv";
import { AptosProvider } from "../wrappers/aptosProvider";

const envPath = path.resolve(__dirname, "../../.env");
dotenv.config({ path: envPath });

// Initialize Aptos instance
const aptosProvider = new AptosProvider();
const config = new AptosConfig({ network: aptosProvider.getNetwork() });
export const aptos = new Aptos(config);
