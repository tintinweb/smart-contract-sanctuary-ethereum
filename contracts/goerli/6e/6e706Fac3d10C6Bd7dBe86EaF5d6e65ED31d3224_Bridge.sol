pragma solidity 0.8.9;
//SPDX-License-Identifier: MIT
// Version 1.00

        
contract Bridge
{
		address public immutable owner;
		uint256 public blockNumber;
		uint256 public blockTimestamp;
		bytes32 public blockHash;
		
		event Blockhash(uint256 blocknumber, uint256 blocktimestamp, bytes32 blockhash);
		
		constructor(address _owner) {
        	owner = _owner;
   		}

		function seal(uint256 _blocknumber, uint256 _blocktimestamp, bytes32 _blockhash) public
		{ 
			 require(owner == msg.sender , "not a owner"); 	
			 blockNumber = _blocknumber;
			 blockTimestamp = _blocktimestamp; 
			 blockHash = _blockhash;

			 emit Blockhash(blockNumber, blockTimestamp, blockHash); 
		}
}