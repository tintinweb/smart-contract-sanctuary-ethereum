//SPDX-License-Identifier: UNLICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.9;

contract IHasher{
	
    constructor() {
    }
    
    function MiMCSponge(uint256 xL_in,uint256 xR_in,uint256 k) external pure returns (uint256, uint256){
    	return (xL_in,xR_in);
    }
}