// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Metadata {

    function name() public view virtual returns (string memory) {
        return "Artifacts";
    }

    function symbol() public view virtual returns (string memory) {
        return "ARTIFACTS";
    }

}