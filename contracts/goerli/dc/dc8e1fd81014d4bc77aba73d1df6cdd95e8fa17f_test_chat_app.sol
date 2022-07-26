/**
 *Submitted for verification at Etherscan.io on 2022-07-26
*/

//"SPDX-License-Identifier: MIT"

pragma solidity ^0.8.7;

contract test_chat_app {

    // we define a struct for the representation of the Message
    struct MessageWithAttachable{
        uint message_id;
        address sender_address;
        string message_content;
        string attachable_url;  // this field allows a front end to locate an  
                                // attachable from an external server (like an image or video) 
                                // without directly storing it within the blockchain (too expensive)
        uint timestamp;
    }

    // we define the state variable that contains all the Messages for this dApp
    MessageWithAttachable[] array_messages;

    // sends a message, we use calldata for optimization purposes
    function sendMessage(string calldata _message_content, string calldata _attachable_url) public {
        array_messages.push( 
            MessageWithAttachable(
                array_messages.length+1, msg.sender,  //msg is a global variable, msg.sender allows me to get the address of the sender
                _message_content, _attachable_url,
                block.timestamp  // block.timestamp gives me the seconds since unix epoch. Easily converted in a front-end
                                 // This is a less storage intensive approach than using a string with a Date.
            )
        );
    }

    // gets ALL MESSAGES EVER
    function getAllMessages() view public returns (MessageWithAttachable[] memory){  
        return array_messages;
    }

    // gets a message by its respective ID. Useful as a tool to quote a previous message from the front-end
    function getMessageById(uint _message_id) view public returns (MessageWithAttachable memory){
        return array_messages[_message_id-1];
    }

}