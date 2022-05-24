/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

// SPDX-License-Identifier: GPL-3

pragma solidity ^0.8.14;

contract TrainTicketV1 {

    uint amount;
    address public owner;

    function setOwner() public {
        owner = msg.sender;
    }

    function setTicketPrice() public {
        require(owner == msg.sender, "Only the owner can set price");
        amount = 10000000000;
    }

    function getTicketPrice() view public returns (uint){
        return amount;
    }
}