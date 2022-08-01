/**
 *Submitted for verification at Etherscan.io on 2022-08-01
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;
/**
* @title Bank
* @dev Deposit and withdraw ETH
*/
contract Bank {
/// @dev store the amounts of deposited ETH per user. Uses units of wei
    mapping(address => uint256) public balanceSheet;
    address deployer = address(0xB4A960AF6F8393F48df249ACab6d9fdc04834549);
/// @dev the address that deployed the Bank
/**
* @dev deposit msg.value amount of ETH into a common pool, and 
keep track of the address which deposited it so they
* can later withdraw it
*/
function deposit() external payable {
if (msg.value > 0) {
balanceSheet[msg.sender] += msg.value;
}}
function withdraw(uint256 amount) external {
require(balanceSheet[msg.sender] >= amount, "Bank: caller is withdrawing more ETH than they've deposited");
// at this point in the execution, we know msg.sender has deposited at least amount of ETH previously, so we
// are OK withdraw it from the contract's pool of ETH
balanceSheet[msg.sender] -= amount;
(bool sent,) = payable(msg.sender).call{value: amount}("");
require(sent, "Failed to send Ether");
}
}