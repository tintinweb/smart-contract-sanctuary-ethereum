/**
 *Submitted for verification at Etherscan.io on 2022-12-09
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract Coin {
    //The keyword "Public " makes variables 
    // Accessiblle from other contracts 

    address public minter;
    mapping (address => uint) public balances;

    //Events allow clients to react to spicific 
    // contract changes you declare

    event Sent(address from ,address to , uint amount);

    // Construcctor code is only run when the contract is created

    // require karta hai if else ka kaam 
    // modifier karta hai value ko update karne ka kaam 
    // event karta hai kisi bhi value pass jo hame deploy k baad fucition chalane hote hai or ye direct blockchain par kaam karta hai 
    // uint = + -  
    // msg.value m store kartae hai balanceko 
    // msg.sender m store karate hai address ko 
    // payable function use karet hai jab hame koi transactio nkarani ho 
    // block.timestamp iska kaam jaha  ye lag gaya us function ka time assign ya fix kar deta hai.
    // enum 

    constructor(){
        minter = msg.sender;
    }

    function mint(address receiver , uint amount) public {
        require(msg.sender == minter);
        balances[receiver] += amount;
    }

    error InsufficientBalance(uint requested , uint available);

    function send(address receiver , uint amount)  public{
        require (amount > balances[msg.sender], "InsufficientBalance");

        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        emit Sent(msg.sender , receiver ,amount);
    }

}