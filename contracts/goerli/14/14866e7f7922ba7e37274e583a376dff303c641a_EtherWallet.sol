/**
 *Submitted for verification at Etherscan.io on 2022-11-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract EtherWallet {
    address payable public owner;
    
    constructor() {
        owner = payable (msg.sender);
    }

    receive() external payable {}

    function withdraw(uint _amount, address _address) external {
        require(msg.sender == owner, "Only the owner can call this method.");
        payable(_address). transfer (_amount);
    }

    function getBalance() external view returns (uint) {
        return address(this). balance;

    }
}