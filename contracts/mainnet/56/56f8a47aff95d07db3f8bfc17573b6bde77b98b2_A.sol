/**
 *Submitted for verification at Etherscan.io on 2022-11-19
*/

// File: contract-014578df74.sol


pragma solidity ^0.8.9;

contract A {
    function b(uint256 c) public pure returns (uint256) {
		uint256 d = 0;
		uint256 e = 0;

		for (uint256 i = 0; i < 64; i++) {
			if(c > i * 1024 && c <= (i + 1) * 1024) {
				d = (i * 1024) + 1;
				e = d + 1024;

				break;
			}
		}

		uint256 f = 0;

		for (uint256 i = d; i < e; i++) {
			f++;

			if (i == c) {
				break;
			}

			if (f == 1024) {
				f = 0;
			}
		}
		
		return f;
	}
}