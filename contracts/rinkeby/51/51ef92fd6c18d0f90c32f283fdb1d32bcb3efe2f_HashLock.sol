/**
 *Submitted for verification at Etherscan.io on 2022-06-01
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
    contract HashLock {
        bytes32 public constant hashLock = bytes32(0xF2BA4D055054D94941B32BE11C41C6CAC5D7D81E9001CD79D03A9538CCC0DF64);
        receive() external payable {}
        function claim(string memory _WhatIsTheMagicKey) public {
            require(sha256(abi.encodePacked(_WhatIsTheMagicKey)) == hashLock);
            selfdestruct(msg.sender);
        }
    }