// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;

contract C {

    function one() public {
        two();
    }

    function two() public {
        three();
    }

    function three() public {
        four();
    }

    function four() public {}
}