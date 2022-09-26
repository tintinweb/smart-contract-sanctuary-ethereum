// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EventMaker {
    event TestEvent(uint256 indexed a, uint256 indexed b, uint256 indexed c);

    function emitEvent(uint256 a, uint256 b, uint256 c) external {
        emit TestEvent(a, b, c);
    }

    function emitManyEvents(uint256 b, uint256 c) external {
        for (uint256 i = 0; i < b; i++) {
            emit TestEvent(i, b, c);
        }
    }
}