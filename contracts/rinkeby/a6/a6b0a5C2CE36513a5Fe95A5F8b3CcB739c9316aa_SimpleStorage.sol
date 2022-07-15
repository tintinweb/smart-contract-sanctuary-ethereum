// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract SimpleStorage {
  uint256 favoriteNumber;
  uint256 specialValue = 5;

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

  function setSpecialValue(uint256 _specialValue) public {
    specialValue = _specialValue;
  }

  function favoriteNumberWithSpecialValue(uint _newSpecialValue) public {
    favoriteNumber += _newSpecialValue;
  }

  function addPerson(string memory _name, uint256 _favoriteNumber) public {
    people.push(People(_favoriteNumber, _name));
    nameToFavoriteNumber[_name] = _favoriteNumber;
  }
}