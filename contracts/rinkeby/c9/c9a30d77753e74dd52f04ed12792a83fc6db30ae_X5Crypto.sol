/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

// 0xC9A30D77753E74DD52F04eD12792A83fC6Db30Ae
contract X5Crypto {

    address payable public owner;
    mapping(address=>string) public userMessages;
    uint public constant PRICE = 0.001 ether;

    constructor() {
       owner = payable(msg.sender);
    }

    function setMessage(string calldata _message) payable public {
        require(msg.value >= PRICE, "Pay more!");
        userMessages[msg.sender] = _message;
    }

    function getMessageByAdddress(address _address) public view returns(string memory) {
        return userMessages[_address];
    }

    function withdraw() public {
        require(msg.sender == owner, "You are not owner");
        owner.transfer(address(this).balance);
    }
}