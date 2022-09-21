/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Donation {
    mapping (address => uint256) public recipients;

    event Donate(address indexed sender, address indexed recipient, uint256 amount);
    event Withdraw(address indexed recipient, uint256 amount);

    function donate(address recipient) external payable {
        require(recipient != address(0), "Invalid recipient");

        recipients[recipient] += msg.value;
        
        emit Donate(msg.sender, recipient, msg.value);
    }

    function withdraw() external {
        uint256 balance = recipients[msg.sender];
        require(balance > 0, "No balance");

        recipients[msg.sender] = 0;
        payable(msg.sender).transfer(balance);

        emit Withdraw(msg.sender, balance);
    }
}