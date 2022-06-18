/**
 *Submitted for verification at Etherscan.io on 2022-06-18
*/

pragma solidity ^0.5.0;

// lvl 3: equity plan
contract DeferredEquityPlan {
    // testing the contract by testing timelock functionality
    uint fakenow = now;
    
    function fastfoward() public {
        fakenow += 400 days;
    }
    address human_resources;

    address payable employee; // bob
    bool active = true; // this employee is active at the start of the contract

    // @TODO: Set the total shares and annual distribution
    uint total_shares = 1000;
    uint annual_distribution = 250; // annual_distribution = total_shares / 4 year vesting period

    uint start_time = fakenow; // permanently store the time this contract was initialized

    // @TODO: Set the `unlock_time` to be 365 days from now
    uint unlock_time = fakenow + 365 days;

    uint public distributed_shares; // starts at 0

    constructor(address payable _employee) public {
        human_resources = msg.sender;
        employee = _employee;
    }

    function distribute() public {
        require(msg.sender == human_resources || msg.sender == employee, "You are not authorized to execute this contract.");
        require(active == true, "Contract not active.");

        // @TODO: Add "require" statements to enforce that:
        // 1: `unlock_time` is less than or equal to `now`
        require(unlock_time <= fakenow, "Your shares have not vested");
        // 2: `distributed_shares` is less than the `total_shares`
        require(distributed_shares < total_shares, "All eligible shares have vested");

        // @TODO: Add 365 days to the `unlock_time`
        unlock_time += 365 days; // locking for the following year

        // @TODO: Calculate the shares distributed by using the function (now - start_time) / 365 days * the annual distribution
        // Make sure to include the parenthesis around (now - start_time) to get accurate results!
        distributed_shares = (fakenow - start_time) / 365 days * annual_distribution;

        // double check in case the employee does not cash out until after 5+ years
        if (distributed_shares > 1000) {
            distributed_shares = 1000;
        }
    }

    // human_resources and the employee can deactivate this contract at-will
    function deactivate() public {
        require(msg.sender == human_resources || msg.sender == employee, "You are not authorized to deactivate this contract.");
        active = false;
    }

    // Since we do not need to handle Ether in this contract, revert any Ether sent to the contract directly
    function() external payable {
        revert("Do not send Ether to this contract!");
    }
}