/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract SimpleStorage {
  uint256 favoriteNumber;
  address owner;
  User[] public users;
  mapping(string => uint256) public nameToFavoriteNumber;

  struct User {
    string name;
    uint256 amount;
  }

  constructor() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "you are not an owner!");
    _;
  }

  function applyUser(string calldata _name, uint256 _amount) public {
    users.push(User(_name, _amount));
    nameToFavoriteNumber[_name] = _amount;
  }

  function retrieve() external view onlyOwner returns (uint256) {
    return favoriteNumber;
  }

  function store(uint256 _favoriteNumber) public {
    favoriteNumber = _favoriteNumber;
  }
}