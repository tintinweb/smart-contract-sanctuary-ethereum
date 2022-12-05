/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
	contract HashLock 
    {
	    // type=byte32, "public", constant=final
        // ref: (https://emn178.github.io/online-tools/sha256.html)
        // bytes32 public constant hashLock = bytes32(HASH_VALUE_OF_KEY);
        bytes32 public constant hashLock = bytes32(0x0f8ef3377b30fc47f96b48247f463a726a802f62f3faa03d56403751d2f66c67);
	    
        // receive: default function for deposit money to contract
        // external: call by outside this constract
        // payable: for transfer money
        receive() external payable {}
	    
        // claim function
        // if hash of  incoming string = lock (encrypted) string
        // --> he/she is the owner, send everything back to him/her
        function claim(string memory _WhatIsTheMagicKey) public 
        {
            // require: if x == y
            // if sha256 of incoming string = hashLock
	        require(sha256(abi.encodePacked(_WhatIsTheMagicKey)) == hashLock);
            // address of sender
	        selfdestruct(msg.sender);
	    }
	}