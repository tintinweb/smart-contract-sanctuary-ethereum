/**
 *Submitted for verification at Etherscan.io on 2022-11-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract Implementation {
    uint public x;
    bool public isBase;
    address public owner;

    modifier onlyOwner(){
        require(msg.sender == owner,"Only Owner");
        _;
    }

    constructor(){
        isBase = true;
    }

    function initialize (address _owner) external {
        require(isBase ==  false ,"cannot initialize");
        require(owner == address(0));
        owner = _owner;
    }

    function setX(uint _newX) external onlyOwner{
        x = _newX;
    }
}