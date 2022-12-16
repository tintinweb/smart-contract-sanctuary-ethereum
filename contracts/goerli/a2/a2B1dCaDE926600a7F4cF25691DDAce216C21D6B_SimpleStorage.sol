// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

// EVM, Ethereum Virtual Machine
// Avalanche, Fantom, Polygon

contract SimpleStorage {
  uint256 favoriteNumber; // This get initialized to zero!

  struct People {
    uint256 favoriteNumber;
    string name;
  }

  mapping(string => uint256) public nameToFavoriteNumber;

  People[] public people;

  function store(uint256 _favoriteNumber) public virtual {
    favoriteNumber = _favoriteNumber;
  }

  // calldata -> can't be modified, memory -> can be modified, storage -> exists even outside of function execution
  function addPerson(string calldata _name, uint256 _favoriteNumber) public {
    people.push(People(_favoriteNumber, _name));
    nameToFavoriteNumber[_name] = _favoriteNumber;
  }

  // view: free
  function retrieve() public view returns (uint256) {
    return favoriteNumber;
  }

  // pure: free
  function add(uint256 toAdd) public pure returns (uint256) {
    return (1 + toAdd);
  }
}