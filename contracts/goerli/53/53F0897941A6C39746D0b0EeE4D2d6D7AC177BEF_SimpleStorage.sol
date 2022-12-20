/**
 *Submitted for verification at Etherscan.io on 2022-12-20
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
  uint256 favoriteNumber; //People public person = People({favoriteNumber: 2, name: "Jeff"});

  mapping(string => uint256) public nameToFavoriteNumber;

  struct People {
    uint256 favoriteNumber;
    string name;
  }

  uint256[] favoriteNumbersList;
  People[] public people;

  function store(uint256 _favoriteNumber) public virtual {
    favoriteNumber = _favoriteNumber;
    //retrieve();
  }

  function retrieve() public view returns (uint256) {
    return favoriteNumber;
  }

  // calldata, memory, storage
  function addPerson(string memory _name, uint256 _favoriteNumber) public {
    people.push(People(_favoriteNumber, _name));
    nameToFavoriteNumber[_name] = _favoriteNumber;
  }
  //    function add() public pure returns(uint256) {
  //      return 1 + 1;
  //}
}
//0x358AA13c52544ECCEF6B0ADD0f801012ADAD5eE3