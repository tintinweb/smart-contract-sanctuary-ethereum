/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract EthPool {

    function sendViaSend(address payable _to) public payable {
        // Send returns a boolean value indicating success or failure.
        // This function is not recommended for sending Ether.
        bool sent = _to.send(msg.value);
        require(sent, "Failed to send Ether");
    }
}