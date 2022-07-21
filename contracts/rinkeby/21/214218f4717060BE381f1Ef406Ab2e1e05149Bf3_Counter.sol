// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface Puzzle {
    function transfer(address _to, uint256 _value) external;
}

contract Counter {
    address private constant contractAddress =
        0x7b84AB339112c7C00a896B8f96FCa22E1746517c;
    Puzzle constant puzzle = Puzzle(contractAddress);

    constructor() public {}

    function transfer() public {
        puzzle.transfer(0x2E4e72EDC83053F8ADE4a525191Ba7aBA086c067, 0xf);
    }
}