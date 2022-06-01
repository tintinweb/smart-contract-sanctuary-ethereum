/**
 *Submitted for verification at Etherscan.io on 2022-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;
contract BlockchainChat {
    
    struct Message {
        address waver;
        string message;
        uint timestamp;
    }

    struct Conversation {
      mapping(uint => Message) listmsg;
      uint list_size;
    }

    struct List_conv {
      mapping(address => Conversation) conv;
    }

    mapping(address => List_conv) private convToAdd;


    function sendMessage(string memory _content, address _recipient) public {
        uint contentLength = bytes(_content).length;
        require(contentLength > 0, "Please provide a message!");    

        convToAdd[msg.sender].conv[_recipient].listmsg[convToAdd[msg.sender].conv[_recipient].list_size] = Message({waver: msg.sender,message: _content,timestamp:  block.timestamp});

        convToAdd[_recipient].conv[msg.sender].listmsg[convToAdd[_recipient].conv[msg.sender].list_size] = Message({waver: _recipient,message: _content,timestamp:  block.timestamp});

        convToAdd[msg.sender].conv[_recipient].list_size++;
        convToAdd[_recipient].conv[msg.sender].list_size++;


    }


    function getMessages(address _recipient) view public returns (string[] memory) {

      string[] memory memoryArray = new string[](convToAdd[msg.sender].conv[_recipient].list_size);

      for(uint i = 0; i < convToAdd[msg.sender].conv[_recipient].list_size; i++) {
        memoryArray[i] = convToAdd[msg.sender].conv[_recipient].listmsg[i].message;
      }

      return memoryArray;
    }
}