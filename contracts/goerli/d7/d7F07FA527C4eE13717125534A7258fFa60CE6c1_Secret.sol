/**
 *Submitted for verification at Etherscan.io on 2022-11-09
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Secret {
    uint256 public number;
    string private secret;

    constructor(string memory _secret) {
        secret = _secret;
    }

    function setNumber(uint256 newNumber, string memory password) public {
        require(
            keccak256(bytes(password)) == keccak256(bytes(secret)),
            "Unauthorized!"
        );

        number = newNumber;
    }

    function increment() public {
        number++;
    }
}