pragma solidity 0.8.9;
//SPDX-License-Identifier: MIT
// Version 1.00

        
contract Bridge
{
		address public immutable owner;
		uint256 public blockNumber;
		bytes32 public blockHash;
		
		event Blockhash(uint256 blocknumber, bytes32 blockhash);
		
		constructor(address _owner) {
        	owner = _owner;
   		}

		function seal(uint256 _blocknumber, bytes32 _blockhash) public
		{ 
			 require(owner == msg.sender , "not a owner"); 	
			 blockNumber = _blocknumber;
			 blockHash = _blockhash;
			 emit Blockhash(blockNumber, blockHash); 
		}
}