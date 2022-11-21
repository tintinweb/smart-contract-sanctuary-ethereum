// SPDX-License-Identifier: MIT
pragma solidity 0.8.4; //Do not change the solidity version as it negatively impacts submission grading

contract ExampleExternalContract {
    bool public completed;

    constructor() {
        completed = false;
    }

    function complete() public payable {
        completed = true;
    }
}