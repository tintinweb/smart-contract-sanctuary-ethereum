/**
 *Submitted for verification at Etherscan.io on 2022-02-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

contract Bank {
    mapping(address => uint) private _balance;

    function deposit() public payable {
        _balance[msg.sender] += msg.value;
    }

    function withdraw(uint withdrawAmount) public {
        require(withdrawAmount > 0 && withdrawAmount <= _balance[msg.sender], "not enough money");
        payable(msg.sender).transfer(withdrawAmount);
        _balance[msg.sender] -= withdrawAmount;
    }

    function getBankBalance() public view returns (uint balance){
        return _balance[msg.sender];
    }
}