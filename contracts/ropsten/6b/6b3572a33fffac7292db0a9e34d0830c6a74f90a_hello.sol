/**
 *Submitted for verification at Etherscan.io on 2022-04-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract hello {

address owner;
string text;

constructor () {
    owner = msg.sender;
    text = '';
}

   function setText(string memory newtext) public{
       require(owner == msg.sender);
       text = newtext;

   }

    function getText() public view returns(string memory) {
return text;
    }

function giveOwnership(address ownertext) public{
           require(owner == msg.sender);
    owner = ownertext;

}

}