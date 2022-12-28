/**
 *Submitted for verification at Etherscan.io on 2022-12-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract Da2namic {

    function simple() public payable{

    }

    function withdraw() public{
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    }
}