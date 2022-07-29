//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Simple {
  //this get initialized to zero!
  uint256 private favoriteNumber;

  struct People {
    uint256 age;
    string name;
  }

  People[] private man;

  function store(uint256 _favoriteNumber) public virtual {
    favoriteNumber = _favoriteNumber;
  }

  //view,pure don't spend gas to run
  function retrieveUnit() public view returns (uint256) {
    return favoriteNumber;
  }

  //calldate, memory, storage
  function addMan(uint256 _age, string memory _name) public {
    man.push(People(_age, _name));
  }

  function findMan(uint256 _index)
    public
    view
    returns (uint256, string memory)
  {
    return (man[_index].age, man[_index].name);
  }

  struct Strawberry {
    address sender;
    string date;
    string info;
  }
  Strawberry[] private straw;

  function addStraw(string memory _date, string memory _info) public {
    straw.push(Strawberry(msg.sender, _date, _info));
  }

  function findStraw(uint256 _index)
    public
    view
    returns (
      address,
      string memory,
      string memory
    )
  {
    return (straw[_index].sender, straw[_index].date, straw[_index].info);
  }
}