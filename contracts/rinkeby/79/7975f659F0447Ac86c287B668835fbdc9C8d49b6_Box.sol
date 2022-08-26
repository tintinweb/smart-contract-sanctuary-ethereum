// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract Box {
  string favouriteDish = "Cola";

  struct People {
    string favouriteDish;
    string name;
    uint256 age;
    address addr;
  }

  // Array of People
  People[] public people;

  mapping(address => string) public addressToFavouriteDish;

  function store(string memory _favouriteDish) public {
    favouriteDish = _favouriteDish;
  }

  function addPerson(
    string memory _favouriteDish,
    string memory _name,
    uint256 _age
  ) public {
    people.push(People(_favouriteDish, _name, _age, msg.sender));
    addressToFavouriteDish[msg.sender] = _favouriteDish;
  }

  function retrieve() public view returns (string memory) {
    return favouriteDish;
  }
}