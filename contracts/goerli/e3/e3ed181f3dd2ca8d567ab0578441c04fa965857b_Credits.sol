/**
 *Submitted for verification at Etherscan.io on 2022-12-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Credits{

    address public manager;

    string[] public credits;

    address sender=msg.sender;

    constructor() {
        manager=msg.sender;
    }
    function setCredits(string memory _s)public{
        require(msg.sender==manager,"Only the manager can send the message.");
        credits.push(_s);
    }
    function getCredits()public view returns(string[] memory){
        require(msg.sender==manager,"Only the manager can send the credits");
        return credits;
    }
}