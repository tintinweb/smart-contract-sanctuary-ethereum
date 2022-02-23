pragma solidity >=0.8.0 <0.9.0;

//SPDX-License-Identifier: MIT

contract ExampleExternalContract {

    bool public completed;

    function complete() public payable {
        completed = true;
    }
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import './ExampleExternalContract.sol';

contract Staker {
  event Stake(address staker, uint256 stakedAmount);

  ExampleExternalContract public exampleExternalContract;
  mapping(address => uint256) public balances;
  uint256 public constant threshold = 1 ether;
  uint256 public deadline = block.timestamp + 1 weeks; // hardcoded deadline makes this hard to test

  modifier notCompleted() {
    bool isCompleted = exampleExternalContract.completed();
    require(!isCompleted, 'Already completed');
    _;
  }

  constructor(address exampleExternalContractAddress) {
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  function stake() public payable notCompleted {
    require(block.timestamp <= deadline, 'Failed to stake (after the deadline)');

    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, balances[msg.sender]);
  }

  function execute() public notCompleted {
    if (block.timestamp > deadline && address(this).balance >= threshold) {
      exampleExternalContract.complete{value: address(this).balance}();
    }
  }

  // This is a weird function interface. It means someone can "undo" your stake whenever they want lmao
  // Probably only want an admin to have this ability, and have a vanilla version that sends balance back to msg.sender
  function withdraw(address payable staker) public notCompleted {
    if (address(this).balance < threshold && balances[staker] > 0) {
      uint256 stakedAmount = balances[staker];
      balances[staker] = 0; // zero out the balance before sending, unsure if possible re-entrancy
      bool success = staker.send(stakedAmount);
      require(success, 'Failed to withdraw');

      emit Stake(msg.sender, balances[staker]);
    }
  }

  function timeLeft() public view returns (uint256) {
    return block.timestamp >= deadline ? 0 : deadline - block.timestamp;
  }

  receive() external payable {
    stake();
  }
}