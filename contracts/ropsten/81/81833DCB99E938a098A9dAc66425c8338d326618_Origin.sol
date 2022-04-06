/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Origin{
    mapping(address=>bool) public spender;
    address public owner;

    constructor(){
        owner = msg.sender;
    }

    function newspender(address agent) external{
        require(owner == msg.sender,"not an owner");
        spender[agent] = true;
    }

    function transfer(address payable to, uint amount) external{
        require(spender[msg.sender] == true,"not a valid spender");
        (bool spend,) = to.call{value:amount}("");
        require(spend,"revert, no fallback or receive at callee");
    }

    function proxycontract(address payable upgrade) external{
        require(owner == msg.sender,"not an owner");
        require(upgrade != address(0));
        bool spend = upgrade.send(address(this).balance);
        require(spend,"revert");
    }

    fallback() external payable{}
    receive() external payable{}
}