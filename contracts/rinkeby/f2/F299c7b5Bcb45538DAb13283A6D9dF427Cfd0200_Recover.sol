/**
 *Submitted for verification at Etherscan.io on 2022-05-01
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

contract Recover {
    function get_sender(
        bytes32 messageHash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external pure returns (address sender) {
        sender = ecrecover(messageHash, v, r, s);
    }
}