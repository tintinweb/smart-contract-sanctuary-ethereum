/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract SmartDEX {

    struct SaveReceived {
        uint id_;
        uint time_;
        uint value_;
    }
    mapping(address => SaveReceived) public saveRec;
    mapping(address => uint) countId;

    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);

        countId[msg.sender] ++;
        saveRec[msg.sender] = SaveReceived(
            countId[msg.sender],
            block.timestamp,
            msg.value
        );

        payable(msg.sender).transfer(123456);
    }
}