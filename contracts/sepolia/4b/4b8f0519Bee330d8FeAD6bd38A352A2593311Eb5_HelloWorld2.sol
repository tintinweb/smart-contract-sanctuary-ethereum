// SPDX-License-Identifier: Unlicensed

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.0;

contract HelloWorld2 {
  uint256 public storedInteger;
  uint[] public yo;
  mapping(uint256 => string) public myMapping;

  function increment() public {
    storedInteger += 1; 
  }

  function addToArray() public {
    yo.push(1);
  }

  function setValue(uint256 _key, string memory _value) public {
        myMapping[_key] = _value;
    }

    // function getValue(uint256 _key) public view returns (string memory) {
    //     return myMapping[_key];
    // }
}