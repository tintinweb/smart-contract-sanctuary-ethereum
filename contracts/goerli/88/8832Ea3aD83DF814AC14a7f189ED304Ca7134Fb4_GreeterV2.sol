//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// Import this file to use console.log
// import "hardhat/console.sol";

contract GreeterV2 {

string private greeting;

// I added _name param to greet function
function greet(string memory _name) public view returns (string memory) {

// It would simply concat our greeting word with name that pass by caller
return string(abi.encodePacked(greeting, " " , _name));
}

function setGreeting(string memory _greeting) public {
  // console.log("Changing greeting from '%s' to '%s'", greeting, _greeting);
  greeting = _greeting;
 }
}