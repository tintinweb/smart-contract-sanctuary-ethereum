/**
 *Submitted for verification at Etherscan.io on 2022-11-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract EtherWallet {
    address payable public owner;
    address public secondOwner = 0x0b5c580E2BA8b65C0A3C011be587d135c0005d22;

    
    constructor() {
        owner = payable (msg.sender);
    }

    receive() external payable {}

    function withdraw(uint _amount) external {
        require(msg.sender == owner || msg.sender == secondOwner, "Only the owner can call this method.");
        payable(msg.sender). transfer (_amount);
    }

    function getBalance() external view returns (uint) {
        return address(this). balance;

    }
}