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

// import 'hardhat/console.sol';
import './ExampleExternalContract.sol';

contract Staker {
  ExampleExternalContract public exampleExternalContract;

  mapping(address => uint256) public balances;

  uint256 public constant threshold = 0.003 * 10**18;
  // uint256 public deadline = block.timestamp + 30 seconds;
  uint256 public deadline = block.timestamp + 72 hours;

  event Stake(address indexed sender, uint256 amount);
  event Withdraw(address indexed sender, uint256 amount);

  constructor(address exampleExternalContractAddress) public {
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  modifier deadlineReached() {
    uint256 timeRemaining = timeLeft();
    require(timeRemaining == 0, 'Deadline is not reached yet');
    _;
  }

  modifier deadlineRemaining() {
    uint256 timeRemaining = timeLeft();
    require(timeRemaining > 0, 'Deadline is already reached');
    _;
  }

  /**
   * @notice Modifier that require the external contract to not be completed
   */
  modifier stakeNotCompleted() {
    bool completed = exampleExternalContract.completed();
    require(!completed, 'staking process already completed');
    _;
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  function stake() public payable deadlineRemaining stakeNotCompleted {
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }

  // if the `threshold` was not met, allow everyone to call a `withdraw()` function
  function withdraw(address payable withdrawer) public deadlineReached stakeNotCompleted {
    require(balances[withdrawer] > 0, "You don't have balance to withdraw");

    uint256 amount = balances[withdrawer];
    balances[msg.sender] = 0;

    (bool sent, ) = withdrawer.call{value: amount}('');
    require(sent, 'Failed to send user balance back to the user');

    emit Withdraw(withdrawer, amount);
  }

  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
  function execute() public stakeNotCompleted deadlineReached {
    require(address(this).balance >= threshold, 'Threshold not reached');

    exampleExternalContract.complete{value: address(this).balance}();
  }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns (uint256 timeleft) {
    if (block.timestamp >= deadline) {
      return 0;
    } else {
      return deadline - block.timestamp;
    }
  }
}