// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract SimpleStorage {
  string private message;

    constructor(string memory initialMessage){
      message = initialMessage;
    }

  function setMsg(string memory _msg) public {
  message = _msg;
  }


}