/**
 *Submitted for verification at Etherscan.io on 2022-06-18
*/

pragma solidity ^0.5.0;

// lvl 3: equity plan
contract DeferredEquityPlan {
    // @TODO: Set the total shares and annual distribution
    // Your code here!
    uint fakenow = now;
    address human_resources;

    address payable employee;
    bool active = true;

    uint total_shares = 1000;
    uint annual_distribution = 250;

    uint start_time = now;
    uint unlock_time = now + 365 days;

    uint public distributed_shares;

    // @TODO: Set the `unlock_time` to be 365 days from now
    // Your code here!

    constructor(address payable _employee) public {
        human_resources = msg.sender;
        employee = _employee;
    }

    function distribute() public {
        require(msg.sender == human_resources || msg.sender == employee, "Not authorized");
        require(active == true, "Contract is not active");
        require(unlock_time <= fakenow, "Shares have vested yet");
        require(distributed_shares < total_shares, "All shares have been distributed");
        require(address(this).balance == 0, "Issue");

        // @TODO: Add "require" statements to enforce that:
        // 1: `unlock_time` is less than or equal to `now`
        // 2: `distributed_shares` is less than the `total_shares`
        // Your code here!
        unlock_time += 365 days;
        distributed_shares = (fakenow - start_time) / 365 days * annual_distribution;

        // @TODO: Add 365 days to the `unlock_time`
        // Your code here!

        // @TODO: Calculate the shares distributed by using the function (now - start_time) / 365 days * the annual distribution
        // Make sure to include the parenthesis around (now - start_time) to get accurate results!
        // Your code here!
        if (distributed_shares > 1000) {
            distributed_shares = 1000;
        }

        // double check in case the employee does not cash out until after 5+ years
    }

    // @TODO: human_resources and the employee can deactivate this contract at-will
    function deactivate() public {
        require(msg.sender == human_resources || msg.sender == employee, "Not authorized");
        active = false;
    }

    // @TODO: Since we do not need to handle Ether in this contract, revert any Ether sent to the contract directly
    function() external payable {
        revert("Revert Either");
    }

    function fastforward() public {
        fakenow += 400 days;
    }

}