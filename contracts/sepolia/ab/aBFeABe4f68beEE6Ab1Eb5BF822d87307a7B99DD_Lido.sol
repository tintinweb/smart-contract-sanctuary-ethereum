// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface stETH{
    function mint(address _to,uint _amount) external;
    function burn(address _from,uint _amount) external; 
}
contract Lido {
    mapping (address => uint) stakedETHAmount;
    stETH LSTTOken;
    constructor (address _lstAddress) {
        LSTTOken = stETH(_lstAddress);
    }

    function deposit() external payable {
        require(msg.value> 0,"Ether value should be greater than 0");
        stakedETHAmount[msg.sender] +=msg.value;
        LSTTOken.mint(msg.sender,msg.value);
    }
    function withdraw(uint _amount) external {
        require(stakedETHAmount[msg.sender] > _amount,"Msg sender has 0 staked ETH");
        stakedETHAmount[msg.sender] -=_amount;
        LSTTOken.burn(msg.sender,_amount);
        (bool success,)=msg.sender.call{value:_amount}("");
        require (success,"ETH transfer failed!");
    }
}