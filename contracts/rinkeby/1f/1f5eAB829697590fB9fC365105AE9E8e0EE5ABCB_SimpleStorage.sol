// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// EVM, Ethereum Virtual Machine
// Avalanche, Fantom, Polygon

contract SimpleStorage {
  // Data types: bool, int256, uint256, address, string,
  // This gets initialized to zero!
  uint256 favoriteNumber;

  mapping(string => uint256) public nameToFavoriteNumber;

  struct People {
    uint256 favoriteNumber;
    string name;
  }

  uint256 favoriteNumbersList;
  People[] public people;

  function store(uint256 _favoriteNumber) public virtual {
    favoriteNumber = _favoriteNumber;
    retrieve();
  }

  // view, pure functions dont have to spend gas
  // They dissallow modifying the state.
  function retrieve() public view returns (uint256) {
    return favoriteNumber;
  }

  // calldata, memory, storage
  function addPerson(string memory _name, uint256 _favoriteNumber) public {
    people.push(People(_favoriteNumber, _name));
    nameToFavoriteNumber[_name] = _favoriteNumber;
  }
}

// 0xd9145CCE52D386f254917e481eB44e9943F39138