// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
	uint256 favoriteNumber;

	mapping(string => uint256) public nameToFavoriteNumber;

	// Adding a type outside of the standard types
	struct People {
		uint256 favoriteNumber;
		string name;
	}

	// uint256[] public favoriteNumbersList;
	People[] public people;

	// Dynamic array, it is not fixed size of a list
	// Array is indexed, 0: 666, Juan 1: 777, Cheyanne

	// Function that will store the execution of applying a favorite number
	function store(uint256 _favoriteNumber) public virtual {
		favoriteNumber = _favoriteNumber;
	}

	// view and pure are gasfree functions to read the contract
	function retrieve() public view returns (uint256) {
		return favoriteNumber;
	}

	// calldata temporary variable no modify, memory temporary variable modify, storage perm variable modify,
	// calldata and memory are temporary to the call variable
	// storage live outside of the functions execution
	function addPerson(string memory _name, uint256 _favoriteNumber) public {
		People memory newPerson = People({
			favoriteNumber: _favoriteNumber,
			name: _name
		});
		// People memory newPerson = People(_favoriteNumber, _name); (adding the parameters as they are shown in the struct, same as the code above, but less explicit)
		// people.push(People(_favoriteNumber, _name)); (dont save the variable)
		people.push(newPerson);
		// Pushed new people to the array
		nameToFavoriteNumber[_name] = _favoriteNumber;
	}
}