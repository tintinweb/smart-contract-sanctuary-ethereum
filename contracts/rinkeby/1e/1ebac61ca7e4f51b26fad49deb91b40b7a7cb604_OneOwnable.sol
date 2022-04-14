/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract OneOwnable {
    string Hello = "Hello world";
    string World = "Hello Master";
    address public owner;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owner,"not owner");
        _;
    }

    function setOwner(address _newOwner) external onlyOwner{
        require(_newOwner != address(0),"invalid address");
        owner = _newOwner;
    }

    function anyOneCall() external returns(string memory){
        return Hello;
    }

    function onlyOwnerCall() external onlyOwner returns(string memory)  {
        return World;
    }

}