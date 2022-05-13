/**
 *Submitted for verification at Etherscan.io on 2022-05-13
*/

// File contracts/ExampleExternalContract.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract ExampleExternalContract {

  bool public completed;

  function complete() public payable {
    completed = true;
  }

}


// File contracts/Staker.sol


contract Staker {
    ExampleExternalContract public exampleExternalContract;

    event Stake(address, uint256);

    mapping(address => uint256) public balances;

    uint256 public constant threshold = 1 ether;

    uint256 public deadline = block.timestamp + 100 hours;

    modifier notCompleted() {
        bool completed = exampleExternalContract.completed();
        require(!completed, "staking has not finished yet");
        _;
    }

    modifier deadlineReached(bool requireReached) {
        uint256 timeRemaining = timeLeft();
        if (requireReached) {
            require(timeRemaining == 0, "Deadline not reached yet");
        } else {
            require(timeRemaining > 0, "Deadline already reached");
        }
        _;
    }

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
    function stake() public payable deadlineReached(false) {
        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
    }

    // After some `deadline` allow anyone to call an `execute()` function
    //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
    // NOTE: annoying - test will fail if use require statement instead of if statement.
    function execute() public deadlineReached(true) {
        uint256 balanceOfContract = address(this).balance;
        if (balanceOfContract >= threshold) {
            exampleExternalContract.complete{value: address(this).balance}();
        }
    }

    // if the `threshold` was not met, allow everyone to call a `withdraw()` function
    function withdraw() public deadlineReached(true) notCompleted {
        uint256 userBalance = balances[msg.sender];
        require(userBalance >= 0, "Cannot withdraw - no funds left");

        balances[msg.sender] = 0;
        (bool sent, ) = msg.sender.call{value: userBalance}("");

        require(sent, "Failed to send balance back to user");
    }

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
    function timeLeft() public view returns (uint256 timeleft) {
        if (block.timestamp >= deadline) {
            return 0;
        } else {
            return deadline - block.timestamp;
        }
    }

    // Add the `receive()` special function that receives eth and calls stake()
    receive() external payable {
        stake();
    }
}