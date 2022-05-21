/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0 <0.9.0;

contract Sink{
    event Received(address, uint);
    receive() external payable{
        emit Received(msg.sender, msg.value);
    }
}