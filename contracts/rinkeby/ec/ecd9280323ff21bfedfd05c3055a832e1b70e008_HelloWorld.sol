/**
 *Submitted for verification at Etherscan.io on 2022-03-13
*/

// SPDX-License-Identifier: MIT

// pragma solidity 0.8.0;
// pragma solidity ^0.8.0;

// pragma solidity >=0.4.22 <0.9.0;

pragma solidity 0.8.10;

contract HelloWorld{
    string public greeting = "Hello World";
    // greeting()
    // uint age = 20;
    // int age1 = 22;


    constructor(){
    greeting = "Hello World";

}

function getMessage() public view returns (string memory ) {
    return greeting;
}
  function setMessage( string memory _greeting) public{
      greeting = _greeting;
  }
  
}