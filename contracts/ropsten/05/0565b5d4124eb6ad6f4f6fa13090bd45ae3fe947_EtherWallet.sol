/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: UNLICENSED
contract EtherWallet {
    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }

    receive() external payable {}

    function withdraw(uint amount) external {
        require(owner == msg.sender, "Error: Not owner");
        payable(msg.sender).transfer(amount);
    }

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }
}