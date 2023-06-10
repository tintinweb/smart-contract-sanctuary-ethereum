/**
 *Submitted for verification at Etherscan.io on 2023-06-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

//events
//mappings
//transfer X
//receive
//modifier
//constructor
//requires X

//1) poder enviar ETH a una address
//2) buscar forma de que el contrato tenga ETH
//3) validar tiempo entre envios para que no vacien el faucet
//4) tiene que poder enviar cantidad fija de eth


contract FaucetIT {
    
    uint public amountToSend;
    address public owner;

    event Transfer(address sender, uint contractBalance);

    constructor() {
        amountToSend=100000000000000000;
        owner=msg.sender;
    }

    function setAmount(uint _amountToSend) public{
        require(msg.sender==owner, "You aren't the owner");
        amountToSend=_amountToSend;
    }

    //2)
    function deposit() public payable{}


    //1)
    function sendETH(address payable receiver) public{
        require(address(this).balance>0,"Contract without balance");
        receiver.transfer(amountToSend);
        emit Transfer(receiver,address(this).balance);
    }

}