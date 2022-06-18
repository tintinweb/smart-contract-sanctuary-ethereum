// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Metadata {

    function name() public view virtual returns (string memory) {
        return "Typenauts";
    }

    function symbol() public view virtual returns (string memory) {
        return "TYPENAUTS";
    }

}