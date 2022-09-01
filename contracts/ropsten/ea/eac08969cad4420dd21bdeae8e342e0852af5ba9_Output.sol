/**
 *Submitted for verification at Etherscan.io on 2022-08-31
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

// import 'hardhat/console.sol';

contract Output {
    struct Entry {
        string name;
        uint256 points;
    }

    mapping (uint256 => Entry) entries;

    constructor() {
        entries[0] = Entry("hello", 1);
        entries[1] = Entry("world", 2);
    } 

    function test() public pure returns (string[] memory names, uint256[] memory points) {
        names = new string[](2);
        names[0] = "hello";
        names[1] = "world";

        points = new uint256[](2);
        points[0] = 1;
        points[1] = 2;
    } 

    function test2() public view returns (Entry[] memory values) {
        values = new Entry[](2);
        values[0] = entries[0];
        values[1] = entries[1];
    }
}