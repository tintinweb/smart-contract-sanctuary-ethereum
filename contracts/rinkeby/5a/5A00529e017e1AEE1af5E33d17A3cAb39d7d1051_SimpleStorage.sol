// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;
pragma experimental ABIEncoderV2;

contract SimpleStorage {
  uint256 favoriteNumber;

  // This is a comment!
  struct People {
    uint256 favoriteNumber;
    string name;
  }

  People[] public people;
  mapping(string => uint256) public nameToFavoriteNumber;

  function store(uint256 _favoriteNumber) public {
    favoriteNumber = _favoriteNumber;
  }

  function retrieve() public view returns (uint256) {
    return favoriteNumber;
  }

  function retrievePerson(uint256 _i) public view returns (People memory) {
    return people[_i];
  }

  function addPerson(string memory _name, uint256 _favoriteNumber) public {
    people.push(People(_favoriteNumber, _name));
    nameToFavoriteNumber[_name] = _favoriteNumber;
  }
}