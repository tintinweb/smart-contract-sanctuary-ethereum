/**
 *Submitted for verification at Etherscan.io on 2022-01-27
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.7.0;
pragma experimental ABIEncoderV2;

contract Fruits {
	string[] myFruits;
	function addFruit(string memory fruitName) public {
		myFruits.push(fruitName);
	}
	function updateFruit(string memory oldFruitName, string memory fruitName) public returns (bool) {
		for (uint i = 0; i < myFruits.length; ++i) {
			if (keccak256(bytes(oldFruitName)) == keccak256(bytes(myFruits[i]))) {
				myFruits[i] = fruitName;
				return true;
			}
		}
		return false;
	}
	function deleteFruit(string memory fruitName) public returns (bool) {
		uint location = 0;
		bool found = false;
		for (uint i = 0; i < myFruits.length; ++i) {
			if (keccak256(bytes(fruitName)) == keccak256(bytes(myFruits[i]))) {
				myFruits[i] = fruitName;
				location = i;
				found = true;
				break;
			}
		}
		if (!found) return false;
		for (uint i = location; i < myFruits.length - 1; ++i) {
			myFruits[i] = myFruits[i+1];
		}
		if (myFruits.length > 0) myFruits.pop();
		return true;
	}

	function getFruits() public view returns (string[] memory) {
		return myFruits;
	}

	function getFruit(uint index) public view returns (string memory) {
		if (index < myFruits.length)
			return myFruits[index];
		else
			return "";
	}

}