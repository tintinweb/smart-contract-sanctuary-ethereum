/**
 *Submitted for verification at Etherscan.io on 2022-06-15
*/

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

contract YourContract {
  constructor() payable {
    // what should we do on deploy?
  }

  // to support receiving ETH by default
  receive() external payable {}
  fallback() external payable {}

  function getSVG1() public pure returns (string memory) {
    string memory text = 'start';
      
    for (uint i = 0; i < 1; i++) {  //for loop example
      text = string(bytes.concat(bytes(text), " ", bytes("aaa")));
    }

    return text;
  }

  function getSVG10() public pure returns (string memory) {
    string memory text = 'start';
      
    for (uint i = 0; i < 10; i++) {  //for loop example
      text = string(bytes.concat(bytes(text), " ", bytes("aaa")));
    }

    return text;
  }

  function getSVG100() public pure returns (string memory) {
    string memory text = 'start';
      
    for (uint i = 0; i < 100; i++) {  //for loop example
      text = string(bytes.concat(bytes(text), " ", bytes("aaa")));
    }

    return text;
  }

  function getSVG1000() public pure returns (string memory) {
    string memory text = 'start';
      
    for (uint i = 0; i < 1000; i++) {  //for loop example
      text = string(bytes.concat(bytes(text), " ", bytes("aaa")));
    }

    return text;
  }

  function getSVG10000() public pure returns (string memory) {
    string memory text = 'start';
      
    for (uint i = 0; i < 10000; i++) {  //for loop example
      text = string(bytes.concat(bytes(text), " ", bytes("aaa")));
    }

    return text;
  }

  function getSVG100000() public pure returns (string memory) {
    string memory text = 'start';
      
    for (uint i = 0; i < 100000; i++) {  //for loop example
      text = string(bytes.concat(bytes(text), " ", bytes("aaa")));
    }

    return text;
  }

  function generate(uint limit) public pure returns (string memory) {
    string memory text = 'gen';
      
    for (uint i = 0; i < limit; i++) {  //for loop example
      text = string(bytes.concat(bytes(text), " ", bytes("gg")));
    }

    return text;
  }
}