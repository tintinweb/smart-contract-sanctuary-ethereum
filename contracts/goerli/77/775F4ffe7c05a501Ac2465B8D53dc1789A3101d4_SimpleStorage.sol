/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

// pragma solidity ^0.8.0;
// pragma solidity >=0.8.0 <0.9.0;

contract SimpleStorage {
	uint256 favoriteNumber;

	struct Person {
		uint256 favoriteNumber;
		string name;
	}
	// array of people (Person[]) stored in the contract's store
	Person[] public people;

	mapping(string => uint256) public nameToFavoriteNumber;

	// this function writes to the contract's state, it spends gas
	// more computational power needed for the function to run => more gas spent
	// virtual keyword for the method to ve overridable by a child contract
	function storeFavoriteNumber(uint256 _favoriteNumber) public virtual {
		favoriteNumber = _favoriteNumber;
		// this call of the add function costs gas
		// because it's being called from a function that's not pure/view
		// add(2, 4);
	}

	// view, pure functions don't cost gas
	// UNLESS you call them from a function that costs gas

	// view function only reads from the state, no gas spent
	function retrieveFavoriteNumber() public view returns (uint256) {
		return favoriteNumber;
	}

	// pure function only does some computation, no gas spent
	function add(uint256 _a, uint256 _b) public pure returns (uint256) {
		return _a + _b;
	}

	// calladta, memory, storage, (stack, code, logs)
	// are places were you can store and access data in Solidity
	// storage: permanent. eg. favoriteNumber or people
	// calldata: temporary and can't be modified
	// memory: temporary and can be modified
	// structs (People), maps (nameToFavoriteNumber) and arrays (strings included)
	// need to be given the memory or calldata keyword
	function addPerson(string memory _name, uint256 _favoriteNumber) public {
		people.push(Person(_favoriteNumber, _name));
		nameToFavoriteNumber[_name] = _favoriteNumber;
	}
}