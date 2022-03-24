/**
 *Submitted for verification at Etherscan.io on 2022-03-23
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
/*
purchase.
restock.

*/
contract Do{

    address public owner;
    mapping(address => uint) public donutBalances;

    //0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2

    constructor(){
        owner = msg.sender;
        donutBalances[address(this)] = 100;
    }

    function GetVendingMachineBalance()public view returns(uint){
        return donutBalances[address(this)];
    }
    
    function restock(uint amount)public{
        require(msg.sender == owner, "only owner restock");
        donutBalances[address(this)] += amount;
    }


    function purchase(uint amount)public payable{
        require(msg.value >= amount + 0.01 gwei,"you must pay 1 ETH donut");
        require(donutBalances[address(this)] >= amount, "no donuts stock sorry");
        donutBalances[address(this)] -= amount;
        donutBalances[msg.sender] += amount;
    }

///////////////////////////////////////////////////////////
    function DoSomething()external payable{
        require(msg.value >= 0.001 ether,"where is the money");

        //função transferir o que ele pago
       // transferSomething() função

    }
}