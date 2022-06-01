/**
 *Submitted for verification at Etherscan.io on 2022-06-01
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <= 0.9.0;

contract BellRang{
    uint public bellCnt;
    address public admin; 

    constructor(){
        admin = msg.sender;
        bellCnt = 0;
    }

    function ringTheBell() public{
        bellCnt++;
    }

    function resetBellCnt() public{
        bellCnt = 0;
    }
}