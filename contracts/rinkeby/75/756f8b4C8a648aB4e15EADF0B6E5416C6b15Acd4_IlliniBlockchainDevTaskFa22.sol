/**
 *Submitted for verification at Etherscan.io on 2022-09-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract IlliniBlockchainDevTaskFa22 {

    event Task(string data, address sender, address origin);

    bytes public publicKey;

    constructor(bytes memory _publicKey) {
        publicKey = _publicKey;
    }

    function sendTask(string calldata data) public {
        require(msg.sender != tx.origin, "Must call from a smart contract!");
        emit Task(data, msg.sender, tx.origin);
    }

}