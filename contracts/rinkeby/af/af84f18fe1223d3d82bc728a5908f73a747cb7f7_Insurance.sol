/**
 *Submitted for verification at Etherscan.io on 2022-08-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Insurance {
    address payable public owner;
    constructor() payable {
        owner = payable(msg.sender);
    }
    address payable public user;

    function deposit(uint _amount) public payable{
        if(_amount == 4){
            user = payable(msg.sender);
        }
    }
    bool public flag;

    function isLate(bool _val) public {
        require(msg.sender ==user,"Only user can call this function");
        flag = _val;
        if(flag == true){
            (bool success,) = owner.call{value: 10500 }("");
            require(success,"Failed to send Ether");
        }
    }

}