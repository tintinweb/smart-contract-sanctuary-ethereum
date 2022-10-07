/**
 *Submitted for verification at Etherscan.io on 2022-10-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Gamadi {

    mapping(address => uint8) public owners;
    string public message;

    event UpdateMessage(address sender, string newMessage);

    // hocu da dozvolim samo mojoj adresi da pristupi ovom contractu
    constructor(){
        owners[0x44c10c00513a1800Aa0772729339ED0D82F4fD7a] = 1;
        message = "init msg";
    }

    function updateMessage(string memory newMessage) public{
        //memory - kao da kaze da mi ne cuva ovu prom posle zavrsetka fn dok storage cuva(stack heap)
        //if(owners[msg.sender] == 1) - efikasnije sa require - proveri uslov i ukoliko nije ispunjen zabodi tu
        require(owners[msg.sender] == 1, "Not an owner");
        message = newMessage;

        emit UpdateMessage(msg.sender, message); // okini event

        return;
    }

}