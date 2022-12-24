/**
 *Submitted for verification at Etherscan.io on 2022-12-24
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract SimpleStorage {
  uint256 public favouriteNumber;
  string public nickName;
  People[] public person;
  mapping (string => uint256) public nameToFavNumber;

  /**
   * Struct creates a custom Data Type
   */
  struct People {
    uint256 favouriteNumber;
    string name;
  }

  /**
   * WRITE FUNCTIONS
   */
  function addPerson(uint256 _favouriteNumber, string memory _name) public {
    People memory Person = People(_favouriteNumber, _name);

    person.push(Person);
    nameToFavNumber[_name] = _favouriteNumber;
  }


  function storeNumber(uint256 _favouriteNumber) public virtual {
    favouriteNumber = _favouriteNumber;
  }

  function storeName(string memory _name) public {
    nickName = _name;
  }


  /**
   * READ FUNCTIONS
   */

  function retreiveFavNumber() public view returns (uint256) {
    return favouriteNumber;
  }

  function retreiveNickName() public view  returns (string memory) {
    return nickName;
  }
 

 
}