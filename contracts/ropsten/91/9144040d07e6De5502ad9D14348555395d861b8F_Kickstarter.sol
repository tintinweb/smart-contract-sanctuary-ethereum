// SPDX-License-Identifier: ISC

// Specifies the version of Solidity, using semantic versioning.
pragma solidity ^0.8.9;

contract Kickstarter {

    // Funded project type
    struct Project {
        address payable owner;
        string name;
        uint256 goal;
        uint256 deadline;
        uint256 raised;
        State state;
    }

    // State of the project
    enum State { Running, Funded, Refunded }

    // Event to let frontend know the price has moved
    event FundingChanged(uint256 oldPrice, uint256 newPrice);

    // Raising is still going
    error TooEarly(uint256 time);
    // Deadline was met
    error TooLate(uint256 time);

    // Validating inputs to check that it is before deadline
    modifier onlyBefore(uint256 time) {
        if (block.timestamp > time) revert TooLate(time);
        _;
    }

    // Validating inputs to check that it is after deadline
    modifier onlyAfter(uint256 time) {
        if (block.timestamp <= time) revert TooEarly(time);
        _;
    }

    Project public project;

    mapping(address => uint256) public funders;

    // Constructor accepts three arguments - _name (name of the project), daysToRun (days the crowdfunding runs for) and target (target price / goal)
    // Using different variable names because of solidity not accepting same variable names
    constructor(string memory _name, uint64 daysToRun, uint256 target) {
        project.owner = payable(msg.sender);
        project.name = _name;
        project.deadline = block.timestamp + (daysToRun * 1 days);
        project.goal = target;
        project.raised = 0;
        project.state = State.Running;
    }

    // Function to call when donating to the fund - available only before deadline
    function donate(uint256 amount) external payable onlyBefore(project.deadline) {
        require(amount > 0);

        uint256 newPrice = project.raised + amount;

        emit FundingChanged(project.raised, newPrice);

        funders[msg.sender] += amount;

        project.raised = newPrice;

        if (project.raised >= project.goal) {
            project.state = State.Funded;
        }
    }

    // Function to claim raised money out of a fund - available only after deadline
    function claim() external payable onlyAfter(project.deadline) {
        require(project.raised >= project.goal); // redundant
        require(project.state == State.Funded);
        require(msg.sender == project.owner);

        project.owner.transfer(address(this).balance);
    }

    // Function to get a refund when the target was not met
    function getRefund() external payable onlyAfter(project.deadline) {
        require(project.raised < project.goal);
        require(funders[msg.sender] > 0);

        uint256 donated = funders[msg.sender];
        uint256 newRaisedAmount = project.raised - donated;

        emit FundingChanged(project.raised, newRaisedAmount);

        project.raised = newRaisedAmount;

        funders[msg.sender] = 0;
    }

    // Function to get the donation value of a funder
    function donationOf(address funder) public view returns (uint256) {
        return funders[funder];
    }

    // Function to get address of a contract owner
    function owner() external view returns (address) {
        return project.owner;
    }

    // Function to get the amount of raised funds
    function raised() external view returns (uint256) {
        return project.raised;
    }

    // Function used only for testing - moves the deadline to yesterday
    // Shouldn't be used in production, but I implemented a check that only contract owner can use it,
    // therefore it won't make a real life impact - if the funds are not raised, it is refundable
    function moveDeadline() external {
        require(project.owner == msg.sender);

        project.deadline = block.timestamp - 1 days;
    }
}