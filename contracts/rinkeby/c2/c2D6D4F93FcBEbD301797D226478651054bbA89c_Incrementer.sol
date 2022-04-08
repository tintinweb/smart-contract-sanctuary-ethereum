//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract Incrementer {
    uint private counter;

    function increment() public {
        counter += 1;
    }
}