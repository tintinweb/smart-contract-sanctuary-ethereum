/**
 *Submitted for verification at Etherscan.io on 2023-01-17
*/

// SPDX-License-Identifier: Michael A Poole 2023
pragma solidity ^0.8.8;


contract FundMike {

address public owner;

constructor() {

        owner = msg.sender;
        
    }

function fundMike() public payable  {

require (msg.value >= 0, "Did not send enough");

    }

function withdrawToMike(address payable _to) public payable { 

      require(msg.sender == owner, "You are not the owner of this account");
        
(bool sent, bytes memory data) = _to.call{value: msg.value}("");        

require(sent, "Failed to send Ether");
 
    }

    fallback() external payable {
        fundMike();
    }

    receive() external payable {
        fundMike();
    }



}