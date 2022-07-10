/**
 *Submitted for verification at Etherscan.io on 2022-07-10
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract SimpleStorage {
  uint256 favNumb;

  struct People {
    uint256 favNumb;
    string name;
  }

  mapping(string => uint256) public nameToFavoriteNumber;

  People[] public people;

  function store(uint256 _favNumb) public virtual {
    favNumb = _favNumb;
    retrieve();
  }

  function retrieve() public view returns (uint256) {
    return favNumb;
  }

  function addPerson(string memory _name, uint256 _favNumb) public {
    people.push(People(_favNumb, _name));
    nameToFavoriteNumber[_name] = _favNumb;
  }
}