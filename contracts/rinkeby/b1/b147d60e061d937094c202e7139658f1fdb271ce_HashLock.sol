/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

pragma solidity ^0.7.0;
	contract HashLock {
	    bytes32 public constant hashLock = bytes32(0xDA2876B3EB31EDB4436FA4650673FC6F01F90DE2F1793C4EC332B2387B09726F);
	    receive() external payable {}
	    function claim(string memory _WhatIsTheMagicKey) public {
	        require(sha256(abi.encodePacked(_WhatIsTheMagicKey)) == hashLock);
	        selfdestruct(msg.sender);
	    }
	}