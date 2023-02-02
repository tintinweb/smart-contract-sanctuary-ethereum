// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Deployer {
  event Deployed(address addr);

  // we need bytecode to deploy a contract
  function deploy(bytes memory _bytecode) external payable returns (address addr) {
    assembly {
      // we cannot access to msg.value here. we use `callvalue()`
      // when code is loaded first 32 bytes encodes the length of the code. actual code starts after 32 bytes. 0x20=32 in hexadecimal
      // the size of the code is stored in the first 32 bytes
      addr := create(callvalue(), add(_bytecode, 0x20), mload(_bytecode))
      // we get the address and load contract using address in remix
    }
    // zero address means that there was an error creating the code
    require(addr != address(0), 'deploy failed');
    emit Deployed(addr);
  }
}