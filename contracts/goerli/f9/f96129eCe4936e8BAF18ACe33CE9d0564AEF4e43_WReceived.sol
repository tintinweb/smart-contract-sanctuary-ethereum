/**
 *Submitted for verification at Etherscan.io on 2023-02-21
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0 <0.9.0;

// This contract keeps all Ether sent to it with no way
// to get it back.
contract WReceived {
    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}