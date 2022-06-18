// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MockTargetContract {
    string public message = "Nothing to Show";

    function foo() external {
        message = "Otrar was successfully pitched";
    }
}