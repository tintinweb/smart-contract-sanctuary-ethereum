// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

contract SimpleStorage {
  // boolean, uint, string, int, address, bytes

  // bool hasFavoriteNumber = true;
  // uint256 favoriteNumber = 5;
  // string favoriteNumberInText = "Five";
  // int256 favoriteInt = -5;
  // address favoriteAddress = 0x0BB03a041899d1967A10D661c080BEB770062C23;
  // bytes32 favoriteBytes = "cat";

  // <- This means that this section is a comment!
  // uint256 public favoriteNumber; // This gets intiialized to zero. All variables when created are initialized with a default value;

  uint256 favoriteNumber;

  // People public person = People({favoriteNumber: 2, name: "Ayush"});

  mapping(string => uint256) public nameToFavoriteNumber; // Initialized all value to default that is 0.

  struct People {
    uint256 favoriteNumber;
    string name;
  }

  // uint256[] public favoriteNumberList;

  People[] public people; // Don't write number to make it dynamic sized array. Arbitray number of people.

  function store(uint256 _favoriteNumber) public virtual {
    favoriteNumber = _favoriteNumber; // The more "stuff" in your function the more gas it costs. Because it is computationally expensive.
    // uint256 public testVar = 5; // Cannot do this because of scope constraints.
    // retrieve(); // If we call view or pure functions from gas requiring functions then it will take additional gas to call view or pure functions.
  }

  // function something() public {
  //     testVar = 10; // Doesn't work because this testVar cannot access the declaration because the declaration is inside another funciton.
  // }

  // View and Pure don't take gas when called. View and Pure functions disallow modifications of state on blockchain.
  // They also disallow to read from the blockchain state.
  function retrieve() public view returns (uint256) {
    return favoriteNumber;
  }

  // function add() public pure returns(uint256) {
  //     return(1+1);
  // }

  // calldata, memory, storage: variables can only stored in these three.
  // calldata -> temporary variables that cannot be modified.
  // memory -> temporary variables that can be modified.
  // storage -> permanent variables that can be modified.
  // Datalocation can only be specified for array, struct and mapping as these are special types in solidity.

  function addPerson(string memory _name, uint256 _favoriteNumber) public {
    people.push(People(_favoriteNumber, _name));
    // People memory newPerson = People({favoriteNumber: _favoriteNumber, name: _name}); Alternate way of doing it.
    // People memory newPerson = People(_favoriteNumber,_name); Alternate way of doing it.
    // people.push(newPerson);
    nameToFavoriteNumber[_name] = _favoriteNumber;
  }
}