/**
 *Submitted for verification at Etherscan.io on 2022-02-27
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract hodl{
    address payable public owner;
    uint public startTime;
    bool public initialized=false;

    function initialize(address payable owneraddress) public{
        if(initialized==true)revert();
        owner=owneraddress;
        startTime=block.timestamp;
        initialized=true;
    }

    function store()payable public{
        if(initialized==false)revert();
    }

    function end() public{
        if(msg.sender!=owner || block.timestamp < (startTime+31536000))revert();
        owner.transfer(address(this).balance);
    }

   
}