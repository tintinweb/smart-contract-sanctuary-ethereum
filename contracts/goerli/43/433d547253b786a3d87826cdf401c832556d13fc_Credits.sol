/**
 *Submitted for verification at Etherscan.io on 2022-12-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract Credits{
    address public manager;
    string[] public credits;
    address sender=msg.sender;
      constructor() {
        manager=msg.sender;
    }
    function setCredit(string memory _s)public{
        require(msg.sender==manager,"Only the manager can send the message.");
        credits.push(_s);
    }
    function getCredits()public view returns(string[] memory){
        return credits;
    }
    function deleteCredit(uint _x)public{
        require(msg.sender==manager,"Only the manager can send the message.");
        delete(credits[_x]);
    }
    function updateCredit(uint _x,string memory str) public{
        require(msg.sender==manager,"Only the manager can send the message.");
        credits[_x]=str;
    }
}