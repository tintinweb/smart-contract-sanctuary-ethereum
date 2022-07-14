/**
 *Submitted for verification at Etherscan.io on 2022-07-14
*/

pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

contract MarinaBay { // 0xf629644c1955ebDfA53b1D335D19A1a0Ca7Fea4e
    address public owner;
    uint256 public balance;

    constructor() {
        owner = msg.sender;

    }

    receive() payable external {
        balance += msg.value;
    }

    function withdraw(uint amount, address payable destAddr) public {
        require(msg.sender == owner, "only owner can withdraw");
        require(amount <= balance, "Insufficient funds");
        
        destAddr.transfer(amount);
        balance -= amount;
    }
}