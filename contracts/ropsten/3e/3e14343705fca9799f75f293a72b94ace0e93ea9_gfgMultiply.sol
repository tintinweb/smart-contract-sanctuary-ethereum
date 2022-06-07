/**
 *Submitted for verification at Etherscan.io on 2022-06-06
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract gfgMultiply {

	int128 firstNo ;
	int128 secondNo ;
	
	function firstNoSet(int128 x) public {
		firstNo = x;
	}
	
	function secondNoSet(int128 y) public {
		secondNo = y;
	}
	
	function multiply() view public returns (int128) {
		int128 answer = firstNo * secondNo ;
		return answer;
	}

}