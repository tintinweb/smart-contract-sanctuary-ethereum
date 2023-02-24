/**
 *Submitted for verification at Etherscan.io on 2023-02-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract State{
	mapping(string => bytes32) dataByKey;
	//there is no easy way to traverse trie so we keep separate array of data.
	bytes32[] allData;

	function read(string memory key) public returns(bytes32){
		return dataByKey[key];
	}

	function getAllData() public returns(bytes32[] memory){
		return allData;
	}

	function write(string memory key, bytes32 data) public returns(bool success){
		if(dataByKey[key].length == 0){
			return false;
		}

		dataByKey[key] = data;
		allData.push(data);
		return true;
	}

}