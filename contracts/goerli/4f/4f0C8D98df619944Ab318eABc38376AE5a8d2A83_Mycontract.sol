/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
contract Mycontract{

    string _name;
    uint _price;

    constructor(string memory name, uint price){
        require(price > 0, "price incorrect");
        _name = name;
        _price = price;
    }

    function GetBalance() public view returns(uint price){
        return _price;
    }

    // function Deposite(uint amount) public{
    //     _price += amount;
    // } 

    

}