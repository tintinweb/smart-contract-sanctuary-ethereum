// contracts/MyContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract MyContract {
    string public message;

    constructor(string memory _message) {
        message = _message;
    }
}