/**
 *Submitted for verification at Etherscan.io on 2022-09-02
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


contract HelloWorldV2 {
    address private owner;
    string private greetingMsg;
    constructor() {
        owner = msg.sender;
        greetingMsg = "hello world";
    }

    function GetOwner() public view returns(address local){
        return owner;
    }

    function Greet() public view returns(string memory){
        return greetingMsg;
    }
}