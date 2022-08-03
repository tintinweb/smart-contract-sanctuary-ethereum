// SPDX-License-Identifier: MIT
pragma solidity 0.8.7; // Latest 0.8.12

contract SimpleStorage {
  // Types: boolean, uint, int, address, bytes    bool hasFavoriteNumber = true;

  // This gets initialized to 0
  // uint256 public favoriteNumber;
  uint256 favoriteNumber;

  // People public person = People({
  //     favoriteNumber: 2,
  //     name: "Majd"
  // });

  People[] public people;

  mapping(string => uint256) public nameToFavoriteNumber;

  struct People {
    string name;
    uint256 favoriteNumber;
  }

  function store(uint256 _favoriteNumber) public virtual {
    favoriteNumber = _favoriteNumber;
  }

  // view or pure <-- does not spend gas
  // unless called from a function that costs
  // pure does, additionally, not allow read
  function retrieve() public view returns (uint256) {
    return favoriteNumber;
  }

  function add(uint256 x, uint256 y) public pure returns (uint256) {
    return x + y;
  }

  function addPerson(string memory _name, uint256 _favoriteNumber) public {
    // People memory newPerson = People({
    //     name: _name,
    //     favoriteNumber: _favoriteNumber
    // });
    // people.push(newPerson);
    people.push(People(_name, _favoriteNumber));
    nameToFavoriteNumber[_name] = _favoriteNumber;
  }

  // calldata, memory, storage <-- types of storing data
  // memory: temporary variables that cannot be modified
  // calldata: temporary variables that can be modified
  // storage: stored variables that can be modified
}