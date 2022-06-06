// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

error NotOwner();

contract Greet {
    address private owner;
    string private greet;

    constructor() {
        owner = msg.sender;
    }

    modifier isOwner() {
        if (msg.sender != owner) {
            revert NotOwner();
        }

        _;
    }

    function setGreet(string calldata _greet) public isOwner {
        greet = _greet;
    }

    function getGreet() external view returns (string memory) {
        return greet;
    }
}