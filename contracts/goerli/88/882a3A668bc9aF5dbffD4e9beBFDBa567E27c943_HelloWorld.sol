/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

contract HelloWorld{

    string private text;
    address public owner;

    error NotOwner();

    constructor(){
        text = "Hello World!";
        owner = msg.sender;
    }
 
    function helloWorld() public view returns(string memory){
        return text;
    }

    function setText(string calldata newText) public {
        if(msg.sender != owner) revert NotOwner();
        text = newText;
    }

    function transferOwnership(address newOwner) public {
        if(msg.sender != owner) revert NotOwner();
        owner = newOwner;
    }

}