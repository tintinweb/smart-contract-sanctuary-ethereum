/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract MyContract {

//private

    string _name;
    uint _balance;

constructor(string memory name, uint balance) {
    require(balance>0, "balance > 0");
    _name = name;
    _balance = balance;
}


function getBalance() public view returns(uint balance) {
    return _balance;
}


/*
function getBalance() public pure returns(uint balance) {
    return 50;
}
*/

function deposit(uint amount) public {
    _balance+=amount;
}

function withdrawal(uint amount) public {
    _balance-=amount;
    }

function transfer_to(uint amount) public {
    _balance-=amount;
    }

function transferred_from(uint amount) public {
    _balance+=amount;
    }

}