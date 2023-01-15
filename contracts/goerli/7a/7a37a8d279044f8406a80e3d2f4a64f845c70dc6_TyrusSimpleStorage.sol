/**
 *Submitted for verification at Etherscan.io on 2023-01-15
*/

// SPDX-License-Identifier: MIT
pragma solidity >0.8.7 <0.9.0; //0.8.17

contract TyrusSimpleStorage {
  // boolean, unint, int, address, bytes
  address myaddress = 0x743B8b3288ee87D754091F7a4D02dd46D50860f9;
  bytes32 favoriteBytes = "cat";
  uint public favoriteNumber;

  People[] public people;
  mapping(string => uint256) public nameToFavoriteNumber;

  struct People {
    uint256 itsfavoriteNumebr;
    string name;
  }

  function store(uint256 _favoriteNumber) public virtual {
    favoriteNumber = _favoriteNumber;
  }

  function retrieve() public view returns (uint256) {
    return favoriteNumber;
  }

  function add() public pure returns (uint256) {
    return (1 + 1);
  }

  function addPeople(uint256 _favoriteNumber, string memory _name) public {
    //people.push(People(_favoriteNumber, _name));
    People memory newPerson = People({
      itsfavoriteNumebr: _favoriteNumber,
      name: _name
    });
    people.push(newPerson);
    nameToFavoriteNumber[_name] = _favoriteNumber;
  }
}