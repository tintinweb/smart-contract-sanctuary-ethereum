// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Child {
  string public name;
  string public gender;
  string public age;

  constructor(
    string memory _name,
    string memory _gender,
    string memory _age
  ) {
    name = _name; //params[0];
    gender = _gender; //params[1];
    age = _age;
  }
}

contract ChildFactory {
  event ChildCreated(address indexed childAddress, address indexed parentAddress, string[] indexed name);

  Child public childContract;

  function createChild(string[] memory params) public returns (Child) {
    childContract = new Child(params[0], params[1], params[2]); // creating new contract inside another parent contract
    emit ChildCreated(address(childContract), msg.sender, params);

    return childContract;
  }

  function getChild() external view returns (Child) {
    return childContract;
  }
}