// I'm a comment!
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

// pragma solidity ^0.8.0;
// pragma solidity >=0.8.0 <0.9.0;

contract SimpleStorage {
  //Initialized to zero
  uint256 public favoriteNumber; //default is internal type / first
  uint256 public brotherFavoriteNumber; //default is internal type / second
  // can check trasaction cost in console
  struct People {
    uint256 favoriteNumber;
    string name;
  }

  // People public person = People({favoriteNumber : 2, name : "James"});
  // People public person = People({favoriteNumber : 7, name : "Alice"});

  // uint256[] public anArray;
  // dynamic array
  People[] public people;

  mapping(string => uint256) public nameToFavoriteNumber;

  function store(uint256 _favoriteNumber) public virtual {
    favoriteNumber = _favoriteNumber;
  }

  function retrieve() public view returns (uint256) {
    return favoriteNumber;
  }

  // calldata, memory,(temporary) storage
  // string is array
  function addPerson(string calldata _name, uint256 _favoriteNumber) public {
    //People memory newPersion = People({favoriteNumber : _favoriteNumber, name : _name});
    //people.push(newPerson);
    people.push(People(_favoriteNumber, _name));
    nameToFavoriteNumber[_name] = _favoriteNumber;
  }
}