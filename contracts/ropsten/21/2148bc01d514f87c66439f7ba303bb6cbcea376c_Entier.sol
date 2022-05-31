/**
 *Submitted for verification at Etherscan.io on 2022-05-31
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Entier {
    uint256 private entier;
    constructor () {
        entier = 0;
    }
    function getEntier() public view returns (uint256) {
        return entier;
    }
    function setEntier (uint256 _entier) public {
        entier=_entier;
    }
}