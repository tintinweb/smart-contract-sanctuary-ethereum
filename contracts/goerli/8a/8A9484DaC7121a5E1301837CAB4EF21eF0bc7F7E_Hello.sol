/**
 *Submitted for verification at Etherscan.io on 2022-11-24
*/

// 許可證
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Hello {
    string public name;
    // mapping(address=>uint) public message;

    constructor() {
        name = "James 0.8.0";
    }

    // all above versions above 0.5.0 need to specify to storage variable location
    // memory - sotre data in chain memory, after finish function, the data will remove 
    //.       - 32byte read or write need cost 3 gas
    // storage - sotre data in blockchain
    //.        - use 32byte storage space need cost 20000 gas
    //.        - update existing data need cost 5000 gas
    // calldata - like memory, but read only, mostly use for parameter passing
    function setName(string memory _name) public {
        name = _name;
    }

    // get blockchain time
    function getBlockChainTime() public view returns(uint256) {
        return(block.timestamp);
    }

    struct message {
        address author;
        string content;
        uint256 createdTime;
    }

    message[] public messages;
    // mapping(uint=>message) public messages;

    function sendMessage(string memory content) public {
        // messages[address(this)] = message(content, getBlockChainTime());
        messages.push(message(address(this), content, getBlockChainTime()));
    }

    // function getMessages() public returns(address) {
    //     for (uint i = 0 ; i <= messages.length ; i ++) {
    //         return messages[i].author;
    //     }
    // }
}