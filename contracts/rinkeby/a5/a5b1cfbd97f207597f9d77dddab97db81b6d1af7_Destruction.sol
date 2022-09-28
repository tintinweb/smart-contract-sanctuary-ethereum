// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Destruction {
    function destruct(address a) public {
        selfdestruct(payable(a));
    }

    fallback() external payable {}

    receive() external payable {}
}