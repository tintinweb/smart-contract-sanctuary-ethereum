/**
 *Submitted for verification at Etherscan.io on 2022-12-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract Events {
    event Transfer(address indexed _from, address indexed _to, uint256 value);

    function emitTransfer(address _to) public {
        emit Transfer(msg.sender, _to, 7);
    }
}