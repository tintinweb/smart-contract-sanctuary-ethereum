/**
 *Submitted for verification at Etherscan.io on 2022-12-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Verification {

    mapping(address => uint) public balance;

    constructor() {
        balance[msg.sender] = 100;
    }

    function transfer(address _to, uint _amount) public payable {
        balance[msg.sender] -= _amount;
        balance[_to] += _amount;
    }

    function getBalance(address userAddress) public view returns (uint) {
        return balance[userAddress];
    }
}