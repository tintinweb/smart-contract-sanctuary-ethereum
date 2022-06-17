/**
 *Submitted for verification at Etherscan.io on 2022-06-17
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Bank {
    
    mapping(address => uint) _balances;
    uint _total;

    function deposit() public payable {
        _balances[msg.sender] += msg.value;
        _total += msg.value;
    }

    function withdraw(uint amount) public payable {
        require(amount <= _balances[msg.sender], "Amount exceed balance.");
        payable(msg.sender).transfer(amount); //transfer from smart contract to sender
        _balances[msg.sender] -= amount;
        _total -= amount;
    }

    function getBalance() public view returns (uint) {
        return _balances[msg.sender];
    }

    function getTotal() public view returns (uint) {
        return _total;
    }

}