// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract CallTestContract {
    uint public number;

    function counter() external {
        number += 1;
    }
}