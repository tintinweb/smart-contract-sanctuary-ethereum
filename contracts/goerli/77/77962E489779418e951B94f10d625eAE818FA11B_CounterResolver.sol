// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ICounter {
    function increaseCount(uint256 amount) external;

    function lastExecuted() external view returns (uint256);
}

// solhint-disable not-rely-on-time
contract CounterResolver {
    bool isPriceOkay;
    ICounter public immutable counter;

    constructor(ICounter _counter) {
        counter = _counter;
        isPriceOkay = false;
    }

    function togglePrice() public {
        isPriceOkay = !isPriceOkay;
    }


    function checker()
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {

        canExec = isPriceOkay;

        execPayload = abi.encodeCall(ICounter.increaseCount, (1));
    }
}