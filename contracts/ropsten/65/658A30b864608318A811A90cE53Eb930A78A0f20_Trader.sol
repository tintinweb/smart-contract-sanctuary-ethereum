/**
 *Submitted for verification at Etherscan.io on 2022-03-10
*/

// SPDX-License-Identifier: MIT
pragma solidity >0.7.0 <0.9.0;
contract EtherBank{
    mapping(address=>uint) party;
    function collect() external payable{
        party[msg.sender]+=msg.value;
    }

    function trasferTo(address payable to,uint amount) external{
        (bool sent,)=to.call{value:amount}(""); //send equvalent ether to target user
        require(sent,"revert, no fallback or receive at callee");
    }
}
contract Trader {
    mapping (address=>uint) Balances;
    EtherBank public etherbank;

    constructor(address _etherbankAddress) {
        etherbank=EtherBank(_etherbankAddress);
    }

    function deposit() external payable{
        Balances[msg.sender]+=msg.value;
        etherbank.collect{value:msg.value}(); //immediate sending ether when trader give once
    }

    function withdrawAll(address payable reciever) external{
        require(Balances[reciever]>0,"No Balance");
        require(reciever==msg.sender,"Only sender can withdraw, Not other address");
        uint amount=Balances[msg.sender];
        Balances[msg.sender]=0;
        etherbank.trasferTo(reciever, amount);
    }
}