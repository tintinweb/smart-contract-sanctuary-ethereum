/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract Bank{
    //  uint _balance;  // uint _***-> unsigned private value
    mapping(address => uint) _balances;

    // function deposit (uint amount) public {
    //     // _balance += amount;  // everyone able to add
    //     _balance[msg.sender] += amount;
    // }

    function deposit () public payable{
        _balances[msg.sender] += msg.value;
    }

    function withdraw(uint amount) public {
        // _balance -= amount;
        // _balances[msg.sender] -= amount;
        require(amount <= _balances[msg.sender], "Not enough money"); //If less than the balance amount
        payable(msg.sender).transfer(amount); //transfer from contract to wallet
        _balances[msg.sender] -=amount;

    }

    function checkBalance() public view returns (uint balance) {
        // return _balance;
        return _balances[msg.sender];
    }
    

}