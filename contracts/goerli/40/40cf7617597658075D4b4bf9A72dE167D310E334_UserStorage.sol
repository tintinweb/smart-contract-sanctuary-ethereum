// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract UserStorage {
  uint256 id;

  struct User {
    uint256 id;
    string name;
    uint8 age;
  }

  User[] public users;

  mapping(string => uint8) public nameToAge;
  mapping(uint256 => User) public idToUser;

  function count() public view returns (uint256) {
    return id;
  }

  function addUser(string memory _name, uint8 _age) public {
    id++;

    User memory user = User(id, _name, _age);

    users.push(user);
    nameToAge[_name] = _age;
    idToUser[id] = user;
  }

  function clearAllUsers() public {
    for (uint256 i = 0; i < users.length; i++) {
      delete nameToAge[users[i].name];
      delete idToUser[users[i].id];
    }

    delete users;
    id = 0;
  }

  function getAllUsers() public view returns (User[] memory) {
    return users;
  }

  function getUserById(uint256 _id) public view returns (User memory) {
    return idToUser[_id];
  }

  function getAgeByName(string memory _name) public view returns (uint8) {
    return nameToAge[_name];
  }
}