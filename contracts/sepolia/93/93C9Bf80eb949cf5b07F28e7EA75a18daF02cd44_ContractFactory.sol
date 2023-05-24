// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

contract ContractFactory {
  function deployContract(bytes memory bytecode, uint256 salt) public returns (address) {
    address contractAddress;

    assembly {
      contractAddress := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
    }

    return contractAddress;
  }
}