/**
 *Submitted for verification at Etherscan.io on 2022-11-01
*/

// SPDX-License-Identifier: MIXED

// Sources flattened with hardhat v2.11.2 https://hardhat.org

// File contracts/GOLRandom.sol

// License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract GOLRandom {
	uint256 immutable W;
	uint256 immutable H;
	uint256 immutable P;
	uint256 immutable BITS_OUT_OF;
	
	constructor (uint256 _W, uint256 _H, uint256 _P, uint256 _BITS_OUT_OF) {
		W = _W;
		H = _H;
		P = _P;
		BITS_OUT_OF = _BITS_OUT_OF;
	}

	function random(uint256 salt) external view returns (uint256) {
		uint256 rnd = uint256(keccak256(abi.encodePacked(block.timestamp)));
		return weightedBits(W * H, rnd, P, BITS_OUT_OF);
	}
	
	// works for len < 256 (technically 257 - bits_out_of, and the last bits would have much higher probabilities)
	// NOTE: len is bit length of result, rnd needs at least len + bitsOutOf - 1 random bits
	function weightedBits(uint256 len, uint256 rnd, uint256 p, uint256 bitsOutOf) public pure returns (uint256 result) {
		uint256 mask = (2 ** bitsOutOf) - 1;

		for (uint256 i = 0; i < len; i++) {
			uint256 roll = (rnd >> i) & mask;
			if (roll < p) {
				result += 2 ** i;
			} 
		}
	} 
}