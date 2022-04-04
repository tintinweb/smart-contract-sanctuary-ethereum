/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Bank {
    mapping(address => uint) _balances;

    function deposit () public payable {
        _balances[msg.sender] += msg.value;
    }

    function withdraw (uint amount) public {
        require(amount > 0 && amount <= _balances[msg.sender],'insufficiant balance');
        payable(msg.sender).transfer(amount);
        _balances[msg.sender] -= amount;

    }

    function Balance() public view returns(uint){
        return _balances[msg.sender];
    }

    function checkBalance(address owner) public view returns(uint){
        return _balances[owner];
    }
}