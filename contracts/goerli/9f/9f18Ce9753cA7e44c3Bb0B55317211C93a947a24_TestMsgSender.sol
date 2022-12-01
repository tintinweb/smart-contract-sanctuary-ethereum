// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract TestMsgSender {

    function getVewMsgSender() public view returns(address){
        return msg.sender;
    }

    function getMsgSender() public returns(address){
        return msg.sender;
    }
}