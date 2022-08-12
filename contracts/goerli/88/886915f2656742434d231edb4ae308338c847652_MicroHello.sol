/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract MicroHello {
  bool public done;
  uint256 public size;

  function setHello(address helloAddress) public returns (bool) {
    bytes4 selector = bytes4(keccak256("sayHi()"));
    (bool success, bytes memory result) = helloAddress.call(abi.encodeWithSelector(selector));
    if (success && keccak256(abi.decode(result, (bytes))) == keccak256(bytes("hello statemind"))) {
        if (helloAddress.code.length < 160) {
          done = true;
        }
        size = helloAddress.code.length;
    }

    return done;
  }
}