/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Hello {
  string private hello;

  event SetValue(string indexed val, uint256 indexed time);

  constructor(string memory helloYou) {
    hello = helloYou;
    emit SetValue(helloYou, block.timestamp);
  }

  function getValue() public view returns (string memory){
    return hello;
  }

  function setValue(string memory helloYou) public {
    hello = helloYou;
    emit SetValue(hello, block.timestamp);
  }

  function setValueWithError(string memory helloYou) public {
    hello = helloYou;
    emit SetValue((hello), block.timestamp);
    revert(string.concat("Can not set supplied value: ", helloYou));
  }
}