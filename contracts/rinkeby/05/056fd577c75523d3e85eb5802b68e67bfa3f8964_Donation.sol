/**
 *Submitted for verification at Etherscan.io on 2022-07-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Write a smart contract that accepts donation from any user.
// Only contract admin can withdraw specific amount to specific address.

contract Donation {
    address admin;

    constructor () {
        admin = msg.sender;
    }

    event Donated(address user, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    function donate() external payable {
        address donator = msg.sender;
        uint256 amount = msg.value; // value in wei
        emit Donated(donator, amount);
    }

    function withdraw(uint256 amount, address payable receiver) 
        external 
        onlyOwner 
    {
        receiver.transfer(amount);
    }
}