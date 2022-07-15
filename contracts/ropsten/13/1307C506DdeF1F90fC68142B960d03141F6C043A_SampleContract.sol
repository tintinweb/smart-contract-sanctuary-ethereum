// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract SampleContract {
    event SampleEvent(string);

    function emitEvent(string memory data) external {
        emit SampleEvent(data);
    }
}