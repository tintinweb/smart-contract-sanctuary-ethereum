/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract LuckyNumber{
    address public manager;
    string public status;
    mapping(address => uint32) public luckyNumbers;

    constructor(){
        manager = msg.sender;
    }

    function setStatus(string memory _status) public {
        require(msg.sender == manager, "You are not a manager!");
        status = _status;
    }

    function setLuckyNumber(uint32 _luckyNumber) public {
        luckyNumbers[msg.sender] = _luckyNumber;
    }
}