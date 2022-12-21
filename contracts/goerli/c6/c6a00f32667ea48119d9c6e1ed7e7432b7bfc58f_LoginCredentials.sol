/**
 *Submitted for verification at Etherscan.io on 2022-12-21
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

contract LoginCredentials {
    mapping(string => bytes) public loginCredentials;

    function saveLoginCredentials(string memory website, bytes memory encryptedCredentials) public {
        loginCredentials[website] = encryptedCredentials;
    }

    function getLoginCredentials(string memory website) public view returns (bytes memory) {
        return loginCredentials[website];
    }
}