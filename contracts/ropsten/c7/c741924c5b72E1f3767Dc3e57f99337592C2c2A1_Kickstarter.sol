// SPDX-License-Identifier: ISC

// Specifies the version of Solidity, using semantic versioning.
pragma solidity ^0.8.9;

contract Kickstarter {

    // Funded project type
    struct Project {
        address payable owner;
        string name;
        uint goal;
        uint deadline;
        uint raised;
        State state;
    }

    // Funder type
    struct Funder {
        address payable funderAddress;
        uint donated;
    }

    // State of the project
    enum State { Running, Funded, Refunded }

    // Raising is still going
    error TooEarly(uint time);
    // Deadline was met
    error TooLate(uint time);

    // Validating inputs to check that it is before deadline
    modifier onlyBefore(uint time) {
        if (block.timestamp > time) revert TooLate(time);
        _;
    }

    // Validating inputs to check that it is after deadline
    modifier onlyAfter(uint time) {
        if (block.timestamp <= time) revert TooEarly(time);
        _;
    }

    Project public project;
    Funder[] public funders;

    // Constructor accepts three arguments - _name (name of the project), daysToRun (days the crowdfunding runs for) and target (target price / goal)
    // Using different variable names because of solidity intellisense
    constructor(string memory _name, uint daysToRun, uint target) {
        project.owner = payable(msg.sender);
        project.name = _name;
        project.deadline = block.timestamp + (daysToRun * 1 days);
        project.goal = target;
        project.raised = 0;
        project.state = State.Running;
    }

    // Function to call when donating to the fund - available only before deadline
    function donate(uint amount) external payable onlyBefore(project.deadline) {
        require(msg.value == amount);
        require(msg.value > 0);

        Funder memory newFunder = Funder({ funderAddress: payable(msg.sender), donated: msg.value });
        funders.push(newFunder);

        project.raised += amount;

        if (project.raised >= project.goal) {
            project.state = State.Funded;
        }
    }

    // Function to claim raised money out of a fund - available only after deadline
    function claim() external payable onlyAfter(project.deadline) {
        require(project.raised >= project.goal); // redundant
        require(project.state == State.Funded);
        require(msg.sender == project.owner);

        project.owner.transfer(project.raised);
    }

    // Function to refund money out of a fund to all funders - available only after deadline
    function refund() external onlyAfter(project.deadline) {
        require(project.raised < project.goal);

        project.state = State.Refunded;

        for(uint i = 0; i < funders.length; i++) {
            funders[i].funderAddress.transfer(funders[i].donated);
        }
    }
}