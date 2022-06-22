/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract log{
    event log(address indexed challenger, string message);

    function ping() public {
        emit log(msg.sender, "text");
    }
}