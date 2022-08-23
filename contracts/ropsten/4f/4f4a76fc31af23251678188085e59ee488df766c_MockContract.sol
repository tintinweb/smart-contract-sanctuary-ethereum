// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity =0.8.16;

contract MockContract {

    uint public constant PERIOD = 10 minutes;
    uint public blockTimestampLast;

    constructor() {
        blockTimestampLast = block.timestamp;
    }

    function update() external {
        require(msg.sender == tx.origin, "only EOA");
        uint blockTimestamp = block.timestamp;
        uint timeElapsed = blockTimestamp - blockTimestampLast;
        require(timeElapsed >= PERIOD, 'Mock: PERIOD_NOT_ELAPSED');
        blockTimestampLast = blockTimestamp;
    }

}