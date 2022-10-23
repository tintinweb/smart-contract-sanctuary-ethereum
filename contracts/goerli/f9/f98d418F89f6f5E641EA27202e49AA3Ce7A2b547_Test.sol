// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Test {
    bool private inited;
    string public version;

    constructor() {
        inited = true;
        version = "Test only purposed";
    }
}