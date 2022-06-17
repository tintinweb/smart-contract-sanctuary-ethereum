/**
 *Submitted for verification at Etherscan.io on 2022-06-17
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract LuckyNumber {

    mapping (address => uint) public addressToLuckyNumber;
    mapping (address => bool) public isChanged;

    modifier onlyOnce() {
        require (isChanged[msg.sender] == false,  "You have already left your lucky number :(");
        _;
    }
    function SaveMyNumber(uint _num) public onlyOnce {
        addressToLuckyNumber[msg.sender] = _num;
        isChanged[msg.sender] = true;
    }
}