/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


contract Variables {

    string public text = "hello";
    uint public num = 123;


    function doAnything() public {
        uint i = 456;

        uint timestamp = block.timestamp;
        address sender = msg.sender;
    }



}