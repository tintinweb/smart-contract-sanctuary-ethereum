/**
 *Submitted for verification at Etherscan.io on 2022-10-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Bank {
    mapping(address => uint256) public balances;

    uint256 public balance;

    function deposit() public payable {
        uint256 amount = msg.value;
        balances[msg.sender] += amount;
    }

    function withdraw(uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance.");
        address to = msg.sender;
        balances[msg.sender] -= amount;
        (bool success, ) = to.call{value: amount}("");
        require(success, "Transfer success");
    }
}