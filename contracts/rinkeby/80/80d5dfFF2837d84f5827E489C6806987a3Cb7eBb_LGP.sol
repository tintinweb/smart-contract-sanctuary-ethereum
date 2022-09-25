/**
 *Submitted for verification at Etherscan.io on 2022-09-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract LGP {
    mapping(address=>uint) public balanceOf;
    constructor(uint initSupply) public {
        balanceOf[msg.sender] = initSupply;
    }

    function send(address receiver, uint amount)public {
        require(balanceOf[msg.sender] >= amount);
        require(balanceOf[receiver] + amount >= balanceOf[receiver]);
        balanceOf[msg.sender] -=amount;
        balanceOf[receiver]+=amount;
    }
}