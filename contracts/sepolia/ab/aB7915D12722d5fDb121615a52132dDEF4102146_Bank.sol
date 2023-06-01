/**
 *Submitted for verification at Etherscan.io on 2023-05-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Bank {    
    mapping(address => uint) _balances;
    // _balances[some adress] = 1eth

    event Deposit(address indexed owner, uint amount);
    event Withdrow(address indexed owner, uint amount);

    function deposit() public payable {
        require(msg.value > 0, "deposit money is zero");

        _balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);        
    }

    function withdraw(uint amount) public {
        require(amount > 0 && amount <= _balances[msg.sender], "not enough month");

        payable(msg.sender).transfer(amount); // smart contract transfer to payable(msg.sender)
        _balances[msg.sender] -= amount;
        emit Withdrow(msg.sender, amount);
    }

    function balance() public view returns(uint) {
        return _balances[msg.sender];        
    }

    function balanceOf(address owner) public view returns(uint) {
        return _balances[owner];
    }
    
}