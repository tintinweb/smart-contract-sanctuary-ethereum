// SPDX-License-Identifier: MIT
pragma solidity 0.8.4; //Do not change the solidity version as it negativly impacts submission grading

import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;

    mapping(address => uint) public balances;
    event Stake(address sender, uint amount);
    uint public deadline = block.timestamp + 72 hours;
    uint public threshold = 1 ether;
    bool public openForWithdraw;
    bool public isExecutionCompleted;

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    modifier notCompleted() {
        require(!isExecutionCompleted, "Example Contract is already executed!");
        _;
    }

    modifier deadlinePassed() {
        require(block.timestamp < deadline, "Deadline Passed!");
        _;
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    // ( Make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
    function stake() public payable notCompleted deadlinePassed {
        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, balances[msg.sender]);
    }

    // After some `deadline` allow anyone to call an `execute()` function
    // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
    function execute() public notCompleted {
        if (block.timestamp >= deadline && address(this).balance >= threshold) {
            isExecutionCompleted = true;
            exampleExternalContract.complete{value: address(this).balance}();
        }
    }

    // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
    function withdraw() public notCompleted {
        if (address(this).balance < threshold) {
            openForWithdraw = true;
            uint amt = balances[msg.sender];
            balances[msg.sender] = 0;
            (bool success, ) = msg.sender.call{value: amt}("");
            require(success, "Unable to withdraw!!");
        }
    }

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
    function timeLeft() public view returns (uint time) {
        uint duration = 0;
        if (block.timestamp < deadline) {
            duration = deadline - block.timestamp;
        }
        return duration;
    }

    // Add the `receive()` special function that receives eth and calls stake()
    receive() external payable {
        stake();
    }
}