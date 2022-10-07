// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Child {
  string public name;
  string public gender;

  constructor(string memory _name, string memory _gender) {
    name = _name; //params[0];
    gender = _gender; //params[1];
  }
}

contract ChildFactory {
  event ChildCreated(address indexed childAddress, address indexed parentAddress, string[] indexed name);

  Child public childContract;

  function createChild(string[] memory params) public returns (Child) {
    childContract = new Child(params[0], params[1]); // creating new contract inside another parent contract
    emit ChildCreated(address(childContract), msg.sender, params);

    return childContract;
  }

  function getChild() external view returns (Child) {
    return childContract;
  }
}