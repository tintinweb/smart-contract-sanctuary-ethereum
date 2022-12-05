/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
	contract HashLock {
	    bytes32 public constant hashLock = bytes32(0x819cc910cee7381ff24362a496c7c1bfa6d8cfaf4b28dff9e99dcd3ba3968c35);
	    receive() external payable {}
	    function claim(string memory _WhatIsTheMagicKey) public {
	        require(sha256(abi.encodePacked(_WhatIsTheMagicKey)) == hashLock);
	        selfdestruct(msg.sender);
	    }
	}