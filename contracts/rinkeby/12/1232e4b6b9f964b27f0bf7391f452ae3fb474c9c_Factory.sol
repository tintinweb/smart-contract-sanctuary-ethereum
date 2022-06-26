//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./Recovery.sol";

contract Factory {
  mapping (address => address) public recoveryContracts;

  function createRecoveryContract(bytes32 _hashedPassword) external returns (address recoveryContractAddress) {
    require(recoveryContracts[msg.sender] == address(0), "Recovery Contract Exists");
    recoveryContractAddress = address(new Recovery(_hashedPassword));
    recoveryContracts[msg.sender] = recoveryContractAddress;
    return recoveryContractAddress;
  }
}