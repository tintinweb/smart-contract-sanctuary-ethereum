/// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// EVM compatible : Avalanche, Fantom, Polygon.. meaning Solidity can be used to deployt to those blockchains

contract SimpleStorage {
  uint256 favoriteNumber; // not initialized so its 0

  // way to look at mapping is: its an INFINTIE array of ALL possible STRINGS. in addPerson we assign a number to where the index of the string we search for is.
  // Mapping is like a dictionary in a way
  mapping(string => uint256) public nameToFavoriteNumber;

  struct People {
    uint256 favoriteNumber;
    string name;
  }

  People[] public people;

  // must set function specifier to virtual since it is overidden in an inheritance contract... ExtraStorage.sol
  // in ExtraStorage.sol we added override to the function to complete the override and thus make a... virtual override!
  function store(uint256 _favoriteNumber) public virtual {
    favoriteNumber = _favoriteNumber;
    retrieve();
  }

  // view, pure functions do not use gas when called by a user. Only when a gas costing function internally calls retrieve() does a gas cost increase incur
  // returns specifies what the function will return
  function retrieve() public view returns (uint256) {
    return favoriteNumber;
  }

  // calldata, memory, storage... calldata: the argument cannot be modified in the function(error thrown). memory: argument variables can be modified. storage: permanent argument variables that can be modified
  // uint256 _favoriteNumber does not need memory since Solidity knows that uint256 go to memory... while strings a more complex so they need a destination like memory
  function addPerson(string memory _name, uint256 _favoriteNumber) public {
    people.push(People(_favoriteNumber, _name));
    nameToFavoriteNumber[_name] = _favoriteNumber;
  }
}