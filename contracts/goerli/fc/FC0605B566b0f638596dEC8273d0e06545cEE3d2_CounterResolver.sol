// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ICounter {
    function increaseCount(uint256 amount) external;

    function lastExecuted() external view returns (uint256);
}

// solhint-disable not-rely-on-time
contract CounterResolver {
    ICounter public immutable counter;

    constructor(ICounter _counter) {
        counter = _counter;
    }

    function checker()
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        uint256 lastExecuted = counter.lastExecuted();

        canExec = (block.timestamp - lastExecuted) > 180;

        execPayload = abi.encodeCall(ICounter.increaseCount, (100));
    }
}