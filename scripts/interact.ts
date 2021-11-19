import { task } from "hardhat/config";

import {
  callFrom,
  getAddress,
  parseCalldataL1,
  parseCalldataL2,
} from "./utils";

task("invoke:l2", "Invoke an L2 contract")
  .addParam("contract", "Contract to call")
  .addParam("func", "Function to call")
  .addOptionalParam("calldata", "Inputs to the function")
  .addOptionalParam("name", "Account name to execute from")
  .setAction(async ({ contract, func, calldata, name }, hre) => {
    const NETWORK = hre.network.name;
    console.log(`Calling on ${NETWORK}`);
    const address = getAddress(contract, NETWORK);
    const contractFactory = await hre.starknet.getContractFactory(contract);
    const contractInstance = contractFactory.getContractAt(address);
    const _name = name || "auth";
    const accountAddress = getAddress(`account-${_name}`, NETWORK);
    const accountFactory = await hre.starknet.getContractFactory("account");
    const accountInstance = accountFactory.getContractAt(accountAddress);

    const _calldata = parseCalldataL2(calldata, NETWORK, contract, func);
    const res = await callFrom(
      accountInstance,
      contractInstance,
      func,
      _calldata
    );
    console.log("Response:", res);
  });

task("call:l2", "Call an L2 contract")
  .addParam("contract", "Contract to call")
  .addParam("func", "Function to call")
  .addOptionalParam("calldata", "Inputs to the function")
  .setAction(async ({ contract, func, calldata }, hre) => {
    const NETWORK = hre.network.name;
    console.log(`Calling on ${NETWORK}`);
    const address = getAddress(contract, NETWORK);
    const contractFactory = await hre.starknet.getContractFactory(contract);
    const contractInstance = contractFactory.getContractAt(address);

    const _calldata = parseCalldataL2(calldata, NETWORK, contract, func);
    const res = await contractInstance.call(func, _calldata);
    console.log("Response:", res);
  });

task("call:l1", "Call an L1 contract")
  .addParam("contract", "Contract to call")
  .addParam("func", "Function to call")
  .addOptionalParam("calldata", "Inputs to the function")
  .setAction(async ({ contract, func, calldata }, hre) => {
    const contractAbiName = contract === "DAI" ? "DAIMock" : contract;
    const NETWORK = hre.network.name;
    console.log(`Calling on ${NETWORK}`);
    const address = getAddress(contract, NETWORK);
    const contractFactory = (await hre.ethers.getContractFactory(
      contractAbiName
    )) as any;
    const contractInstance = await contractFactory.attach(address);

    const _calldata = parseCalldataL1(calldata, NETWORK);
    // @ts-ignore
    const res = await contractInstance[func](..._calldata);
    console.log("Response:", res);
  });