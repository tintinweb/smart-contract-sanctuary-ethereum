/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Bank {

    mapping(address => uint) public balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint amt) external {
        require(amt <= balances[msg.sender],"Not enough funds!");
        payable(msg.sender).transfer(amt);
        balances[msg.sender] -= amt;
    }
}