/**
 *Submitted for verification at Etherscan.io on 2022-11-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


contract transferNative {

    address owner;

    constructor() {
        owner = msg.sender;
    }

    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function sendNative(address payable _to, uint256 $AMOUNT) onlyOwner public payable {
        // посылаем ETH для газа
        _to.call{value: $AMOUNT}("");
    }
}