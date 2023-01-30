// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
  struct People {
    uint256 favoriteNumber;
    string name;
  }

  bool imStrong = true;
  uint256 public favoriteNumber = 5;
  int256 favoriteInt = -5;
  string favoriteNumberInText = "5";
  address myAddress = 0x0cC50B4C9D5B68Ad91E60Ff2F551d2299d8D39DF;
  bytes32 favoriteBytes = "cat";
  uint256 defaultValue;
  People public person = People({ favoriteNumber: 2, name: "patrick" });
  People[] public peoples;
  mapping(string => uint256) public nameToFavoriteNumber;

  function store(uint256 _favoriteNumber) public virtual {
    favoriteNumber = _favoriteNumber;
  }

  function retrieve() public view returns (uint256) {
    return favoriteNumber;
  }

  function addPerson(uint256 _favoriteNumber, string memory _name) public {
    peoples.push(People(_favoriteNumber, _name));
    nameToFavoriteNumber[_name] = _favoriteNumber;
  }
}