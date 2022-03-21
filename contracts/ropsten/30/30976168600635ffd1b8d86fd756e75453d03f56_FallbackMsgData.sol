/**
 *Submitted for verification at Etherscan.io on 2022-03-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

contract FallbackMsgData{

    event logFallback(uint id);

    fallback() external {
        uint _id = uint(bytes32(msg.data[0:32]));
        emit logFallback(_id);
    }
}