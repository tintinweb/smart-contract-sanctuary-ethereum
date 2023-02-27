// contracts/MyContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract MyContract {
    string public message;
    string public name;

    constructor(string memory _message, string memory _name) {
        message = _message;
        name = _name;
    }
}