//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SaySomething {
    string private message;

    function getMsg() public view returns (string memory) {
        return message;
    }

    function setMsg(string memory _msg) public {
        message = _msg;
    }
}