/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

    contract MyFirstContract {

        mapping (address=>bool) public users;
        string public messageOfTheDay="initial message";
        event eventNewMessage(address sender, string newMessage);

        constructor(){
            users[0x36Da800118e7b9C3773F3C463a7344f67Cdc08e3]=true;
        }

        function changeMessageOfTheDay(string memory _newMessage) public {
            require(users[msg.sender]==true,"Not an owner!");
            messageOfTheDay=_newMessage;
            emit eventNewMessage(msg.sender, messageOfTheDay);
            return;
        }

    }