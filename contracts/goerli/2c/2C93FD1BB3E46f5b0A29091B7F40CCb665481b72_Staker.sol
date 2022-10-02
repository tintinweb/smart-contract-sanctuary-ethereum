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
  ExampleExternalContract public exampleExternalContract;

  constructor(address exampleExternalContractAddress) public {
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
    deadline = block.timestamp + 72 hours;
  }

  mapping(address => uint256) public balances;

  uint256 public constant threshold = 1 ether;
  uint256 public deadline;
  bool openForWithdrawal = false;

  event Stake(address indexed staker, uint256 amount);

  modifier notCompleted() {
    require(!exampleExternalContract.completed(), 'Already completed');
    _;
  }

  function stake() external payable notCompleted {
    require(block.timestamp < deadline, 'Deadline has passed');
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }

  function execute() external notCompleted {
    if (address(this).balance > threshold) {
      exampleExternalContract.complete{value: address(this).balance}();
    } else {
      openForWithdrawal = true;
    }
  }

  function withdraw() external notCompleted {
    require(address(this).balance < threshold, 'Threshhold met');
    require(openForWithdrawal, 'Not open for withdrawal');
    uint256 amount = balances[msg.sender];
    balances[msg.sender] = 0;
    (bool ok, ) = payable(msg.sender).call{value: amount}('');
    require(ok);
  }

  function timeLeft() public view returns (uint256) {
    return block.timestamp < deadline ? deadline - block.timestamp : 0;
  }

  // TODO: Add the `receive()` special function that receives eth and calls stake()
  receive() external payable {
    this.stake();
  }
}