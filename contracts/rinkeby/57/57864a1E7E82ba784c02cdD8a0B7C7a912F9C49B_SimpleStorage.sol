/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; // 0.8.12

// EVM,
// Avalanche, Fantom, Polygom

contract SimpleStorage {
  // this creates a getter view funcion
  uint256 favoriteNumber;
  // People public person = People({ favoriteNumber: 21, name: "Jeremy" });
  People[] public people;
  // People[100] public people;
  mapping(string => uint256) public nameToFaveNumber;

  // "virtual" to be able to override
  function store(uint256 _favoriteNumber) public virtual {
    favoriteNumber = _favoriteNumber;
  }

  // view and pure functions dont use gas since they dont really
  // modify the state of the blockchain. They dont do anything
  // but return something fixed

  // view functions dont use gas unless they are called inside another
  // function that does use gas, they they do need to be payed
  function retrieve() public view returns (uint256) {
    return favoriteNumber;
  }

  struct People {
    uint256 favoriteNumber;
    string name;
  }

  // calldata: temporary on function that cant be modified
  // memory: temporary on function that can be modified
  // storage: Permanent and modifiable
  function addPerson(string memory _name, uint256 _favoriteNumber) public {
    People memory newPerson = People({
      favoriteNumber: _favoriteNumber,
      name: _name
    });
    people.push(newPerson);
    nameToFaveNumber[_name] = _favoriteNumber;
  }
}

// Address of my first deployed contract:
// 0xd9145CCE52D386f254917e481eB44e9943F39138