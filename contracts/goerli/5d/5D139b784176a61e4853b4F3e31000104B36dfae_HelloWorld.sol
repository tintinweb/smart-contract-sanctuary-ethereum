/**
 *Submitted for verification at Etherscan.io on 2023-06-06
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract HelloWorld {
    event UpdateMessages(string oldStrg, string newStrg);

    string public message;

    constructor (string memory initMessage){
        message = initMessage;
    }

    function update(string memory newMessage)  public {
        string memory oldMessage = message;
        message = newMessage;
        emit UpdateMessages(oldMessage, newMessage);

        
    }


}