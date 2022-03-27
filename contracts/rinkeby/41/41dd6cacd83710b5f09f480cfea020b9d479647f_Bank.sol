/**
 *Submitted for verification at Etherscan.io on 2022-03-27
*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

contract Bank {

    mapping(address => uint) _balances;
    uint _totalSupply;

    function deposit() public payable {
        _balances[msg.sender] += msg.value;
        _totalSupply += msg.value;
    }

    function withdraw(uint amount) public payable {
        require(amount <= _balances[msg.sender], "insufficient money");

        payable(msg.sender).transfer(amount);   // add sender with amount
        _balances[msg.sender] -= amount;        // decrease value of this address
        _totalSupply -= amount;
    }

    function checkBalance() public view returns(uint balance) {
        return _balances[msg.sender];
    }

    function checkTotalSupply() public view returns(uint totalSupply) {
        return _totalSupply;
    }
}