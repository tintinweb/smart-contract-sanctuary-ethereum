// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyImplementationV1 {
    uint public x;

    function inc() public {
        x += 1;
    }

    function inc3() public {
        x += 3;
    }

    function inc5() public {
        x += 5;
    }
}