/**
 *Submitted for verification at Etherscan.io on 2023-03-18
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Vulnerable {
    mapping (address => uint) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint amount) public {
        require(balances[msg.sender] >= amount);
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success);
        balances[msg.sender] -= amount;
    }

    function getBalance() public view returns (uint) {
        return balances[msg.sender];
    }
}