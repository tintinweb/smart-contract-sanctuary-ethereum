/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Donation
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */

contract Donation {
    mapping (address => uint256) public receipts;

    event Donated(address indexed sender, address indexed receipt, uint256 amount);
    event Withdrawn(address indexed receipt, uint256 amount);

    function donate(address recipient) external payable {
        require(recipient != address(0), "Invalid recipient");
        receipts[recipient] += msg.value;
        emit Donated(msg.sender, recipient, msg.value);
    }

    function withdraw(uint256 amount) public {
        uint256 balance = receipts[msg.sender];
        require(amount <= balance, "No enough balance");

        receipts[msg.sender] -= amount; // block re-entrancy
        payable(msg.sender).transfer(amount);

        emit Withdrawn(msg.sender, amount);
    }
}