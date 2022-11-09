// SPDX-License-Identifier: GNU GPLv2
pragma solidity ^0.8.17;

import "./A.sol";

contract B is A {
    function spam() public pure override {
        // ...
    }

    function ham() public pure override {
        // ...
    }
}