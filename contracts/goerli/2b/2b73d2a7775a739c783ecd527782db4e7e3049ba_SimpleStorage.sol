/**
 *Submitted for verification at Etherscan.io on 2022-11-05
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// same as Class in other language
contract SimpleStorage {
  //boolean, uint, int, address, bytes
  bool hasFavoriteNumber = true;
  uint256 favoriteNumber; //this gets initialized to 0 or default to null in solidity
  // People public person =People({favoriteNumber: 2, name:"Dan"});

  // dictionary, hashmap or hashtable
  mapping(string => uint256) public nameToFavoriteNumber;

  //complex data type with multiple properties
  struct People {
    uint256 favoriteNumber;
    string name;
  }

  People[] public people;

  // uint256[] public favoriteNumberList;    # array or list

  function store(uint256 _favortiteNumber) public virtual {
    favoriteNumber = _favortiteNumber;
    // favoriteNumber= _favortiteNumber + 1;
  }

  // view, pure functions, when called alone, don't spend gas, disallow modification of state. Pure disallow reading from blockchain
  function retrieve() public view returns (uint256) {
    return favoriteNumber;
  }

  // calldata, memory (temproary), storage (permenant)
  function addPerson(string memory _name, uint256 _favortiteNumber) public {
    People memory newPerson = People({
      favoriteNumber: _favortiteNumber,
      name: _name
    });
    people.push(newPerson);

    nameToFavoriteNumber[_name] = _favortiteNumber;
  }
}