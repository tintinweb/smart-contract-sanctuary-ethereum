// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;  //Do not change the solidity version as it negativly impacts submission grading

contract ExampleExternalContract {

  bool public completed;

  function complete() public payable {
    completed = true;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ExampleExternalContract.sol";

contract Staker {
    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    ExampleExternalContract public exampleExternalContract;

    mapping(address => uint256) public balances;

    bool public executeCalled;
    bool public openForWithdraw;
    uint256 public constant threshold = 1 ether;
    uint256 public deadline = block.timestamp + 1 minutes;

    event Stake(address indexed sender, uint256 amount);
    event Withdraw(address indexed sender, uint256 amount);

    event Received(address, uint256);

    receive() external payable {
        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
        emit Received(msg.sender, msg.value);
    }

    modifier deadlineReached() {
        uint256 timeRemaining = timeLeft();
        require(timeRemaining == 0, "Deadline is not reached yet");
        _;
    }

    modifier deadlineRemaining() {
        uint256 timeRemaining = timeLeft();
        require(timeRemaining > 0, "Deadline is already reached");
        _;
    }

    modifier stakeNotCompleted() {
        bool completed = exampleExternalContract.completed();
        require(!completed, "staking process already completed");
        _;
    }

    function stake() public payable deadlineRemaining stakeNotCompleted {
        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
    }

    function withdraw() public stakeNotCompleted deadlineReached {
        uint256 userBalance = balances[msg.sender];
        require(userBalance > 0, "You don't have balance to withdraw");

        require(address(this).balance < threshold,"Threshold Reached, You cannot withdraw");

        (bool sent, ) = msg.sender.call{value: userBalance}("");
        require(sent, "Failed to send user the left out balance");
        balances[msg.sender] = 0;

        emit Withdraw(msg.sender, userBalance);
    }

    function execute() public stakeNotCompleted deadlineReached {
        uint256 contractBalance = address(this).balance;

        require(address(this).balance >= threshold, "Threshold not reached");
        require(executeCalled == false, "Execute is called");

        (bool sent, ) = address(exampleExternalContract).call{
            value: contractBalance
        }(abi.encodeWithSignature("complete()"));

        require(sent, "exampleExternalContract.complete failed");
    }

    function timeLeft() public view returns (uint256 timeleft) {
        if (block.timestamp >= deadline) {
            return 0;
        } else {
            return deadline - block.timestamp;
        }
    }
}