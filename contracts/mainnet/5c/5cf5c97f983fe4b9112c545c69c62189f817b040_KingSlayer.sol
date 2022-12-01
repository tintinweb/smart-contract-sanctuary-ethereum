// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface MessageKingOfTheHill {
    function publish(string memory proposedMessage) external payable;
}

contract KingSlayer {

    MessageKingOfTheHill kingOfTheHill = MessageKingOfTheHill(0xB256Fc468ad910EefC447b070E4256f7bBddC8eE);

    constructor() payable{
        kingOfTheHill.publish{value:0.2 ether}("Arjun was the king, but Frankie is the slayer");
    }
}