// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
// Smart contract for a project
// Author: @hoafnguyeexn
contract Project {

    struct Backer {
        address backer;
        uint256 amount;
    }

    mapping (address => Backer) public backers;
    address payable public creator; // Creator address
    uint256 public fundingGoal; // Funding goal as wei
    bool public isGoalReached = false; // Whether the funding goal has been reached
    uint256 public totalCollected = 0; // Total amount collected

    event FundingGoalReached(uint256 totalCollected);
    event Payout(address payable recipient, uint256 amount);
    event Withdraw(address payable backer, uint256 amount);
    event Deduct(address payable creator, uint256 amount);

    function init(address payable _projectCreator, uint256 _goal) public {
        // This function is used to set the project details
        creator = _projectCreator;
        fundingGoal = _goal;
    }

    function pledge() external payable  {
        require(msg.sender != creator, "Creator cannot pledge"); // Creator cannot contribute to their own campaign
        require(msg.value > 0, "You must pledge some ETH");
        backers[msg.sender].backer = msg.sender;
        backers[msg.sender].amount += msg.value;
        totalCollected += msg.value;

        if (totalCollected >= fundingGoal) {
            isGoalReached = true; // Goal has been reached
        }
    }

    function deduct(uint256 value) external {
        // This function is used for transfering the deducted funds to the creator's wallet address
        require(msg.sender == creator, "Only the creator can deduct funds");
        require(value <= address(this).balance, "Cannot deduct more than the available balance");
        creator.transfer(value);
        emit Deduct(creator, value);
    }

    function payout() external  {
        // This function is used for paying out creator if the project is closed and the funding goal is reached AUTOMATICALLY
        require(isGoalReached, "The project did not reach its funding goal");
        require(msg.sender == creator, "Only the project creator can receive the funds");
        uint256 amount = address(this).balance;
        creator.transfer(amount);
        emit Payout(creator, amount);
    }

    function withdraw() external {
        // this function is used for contributors to withdraw their funds if the project is still live
        require(msg.sender != creator, "Creator cannot withdraw"); // Creator cannot contribute to their own campaign
        require(backers[msg.sender].amount > 0, "Backer did not pledge to the project");
        uint256 amount = backers[msg.sender].amount;
        backers[msg.sender].amount = 0;
        totalCollected -= amount;

        if (totalCollected < fundingGoal) {
            isGoalReached = false; // Goal has not been reached
        }

        payable(msg.sender).transfer(amount);
    }
}