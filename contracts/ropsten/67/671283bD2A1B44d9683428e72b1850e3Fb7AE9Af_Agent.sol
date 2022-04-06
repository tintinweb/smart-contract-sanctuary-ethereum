/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Origin{
    mapping(address=>bool) private spender;
    address private owner;

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

contract Agent{
    mapping (address=>uint) private asset;
    Origin private origin;
    address private owner;

    event Payin(uint _timestamp, address spender, uint value);
    event Payout(uint _timestamp, address spender, uint value);

    constructor(address payable _origin){
        owner = msg.sender;
        origin = Origin(_origin);
    }

    function payin() external payable{
        asset[msg.sender] += msg.value;
        (bool spend,) = address(origin).call{value:msg.value}("");
        require(spend,"revert, no fallback or receive at callee");
        emit Payin(block.timestamp, msg.sender, msg.value);
    }

    function payout(uint amount) external{
        require(amount <= asset[msg.sender],"No Balance");
        origin.transfer(payable(msg.sender), amount);
        asset[msg.sender] -= amount;
        emit Payout(block.timestamp, msg.sender, amount);
    }
}