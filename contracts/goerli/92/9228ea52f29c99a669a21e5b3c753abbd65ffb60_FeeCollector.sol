/**
 *Submitted for verification at Etherscan.io on 2022-09-20
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// Hands on Task (Beginner Level): Build and Deploy an Ether-Store Smart Contract with Remix IDE
// 0xbabacA9617a2cC30bC34A18E5F251F4Bd8CAbfac
contract FeeCollector {
    address public owner;
    uint public balance;

    constructor() {
        owner = msg.sender;
    }
    receive() external payable {
        balance += msg.value;
    }

    function withdraw(uint amount, address payable destAddr) public {
        require(msg.sender == owner, "Only owner can withdraw");
        require(amount <= balance, "Insufficient balance");

        destAddr.transfer(amount);
        balance -= amount;
    }
    
}