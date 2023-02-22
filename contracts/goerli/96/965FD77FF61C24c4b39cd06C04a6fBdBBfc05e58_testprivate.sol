/**
 *Submitted for verification at Etherscan.io on 2023-02-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract testprivate {
    address payable public owner;
    bool public enableTrading;
    bool public enableMaxContribution;
    uint public maxContribution;
    mapping(address => uint) public balances;

    constructor() {
        owner = payable(msg.sender);
        enableTrading = false;
        enableMaxContribution = false;
        maxContribution = 0;
    }

    function contribute() external payable {
        require(enableTrading, "Trading is currently disabled");
        if (enableMaxContribution) {
            require(msg.value <= maxContribution, "Contribution exceeds maximum value");
        }
        balances[msg.sender] += msg.value;
    }

    function withdraw() external {
        require(msg.sender == owner, "Only owner can withdraw funds");
        uint amount = address(this).balance;
        require(amount > 0, "No funds available for withdrawal");
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    function startTrading() external {
        require(msg.sender == owner, "Only owner can enable trading");
        enableTrading = true;
    }

    function disableTrading() external {
        require(msg.sender == owner, "Only owner can disable trading");
        enableTrading = false;
    }

    function startMaxContribution(uint _maxContribution) external {
        require(msg.sender == owner, "Only owner can enable max contribution");
        enableMaxContribution = true;
        maxContribution = _maxContribution;
    }

    function disableMaxContribution() external {
        require(msg.sender == owner, "Only owner can disable max contribution");
        enableMaxContribution = false;
        maxContribution = 0;
    }
}