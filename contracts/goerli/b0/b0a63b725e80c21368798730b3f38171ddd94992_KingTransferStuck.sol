// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract KingTransferStuck {
    function strucktransfer(address payable _address) public payable {
        (bool sent, ) = _address.call{value:msg.value}("");
        require(sent, "Failed to send value!");
    }
}