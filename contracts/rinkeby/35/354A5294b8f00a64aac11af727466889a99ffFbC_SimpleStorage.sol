// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

// x.y.z - exactly this version
// ^x.y.z = version x.y.z and above
// >= 1.2.3 <2.3.4 = version ranges

contract SimpleStorage {
	//TYPES
	// bool hasFavoriteNumber = false;
	// string favoriteNumberInText = "five";
	// int256 favoriteInt = -5;
	// address myAddress = 0xBf639FfACbb1B4D597ae22efefe33d5D86fAD6c9;
	// bytes32 favoriteBytes = "cat";   //bytes32 is max; ex: bytes64 throws error

	uint256 public favoriteNumber; //uint default is 0 if not initialized
	// 2 ways of instantiating a contract
	People public person = People({favoriteNumber: 2, name: "Patrick"});
	People public person2 = People(2, "asd");

	mapping(string => uint256) public nameToFavoriteNumber;

	// struct properties are indexed; favoriteNumber is going to have index 0 and name index 1;
	// same rule applies to contracts; favoriteNumber will have index 0, person index 1 and person2 index 2
	struct People {
		uint256 favoriteNumber;
		string name;
	}

	People[] public people;

	function store(uint256 _favoriteNumber) public virtual {
		favoriteNumber = _favoriteNumber;
	}

	// equivalent to the get function created automatically because favoriteNumber is declared as public
	// functions can be view or pure, which both mean they consume no gas (they appear as blue in the Deploy window on the left; those that consume gas are orange); none of them permit change of state
	// (ex: changing favoriteNumber, which is stored on the blockchain); pure functions also do not permit accessing things on the blockchain
	function retrieve() public view returns (uint256) {
		return favoriteNumber;
	}

	// pure function example
	function addOnePlusTwo() public pure returns (uint256) {
		return (1 + 2); // trying to use favoriteNumber here would result in an error because it is stored on the blockchain
	}

	function add(uint256 a, uint256 b) public pure returns (uint256) {
		return a + b; // this works as a and b are parameters, which are not stored anywhere
	}

	function addPerson(string memory _name, uint256 _favoriteNumber) public {
		people.push(People(_favoriteNumber, _name));
		nameToFavoriteNumber[_name] = _favoriteNumber;
	}
	// test... ignore
}