// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Refunder {
    event SomeWork();

    function doWork() external payable {
        uint gasStart = gasleft();
        for (uint i = 0; i < 100; i++) {
            emit SomeWork();
        }

        uint gasSpent = gasStart - gasleft();
        uint etherSpent = gasSpent * tx.gasprice;

        // solhint-disable reason-string, avoid-low-level-calls, reason-string
        require(msg.value >= etherSpent);
        (bool refunded, ) = msg.sender.call{gas: 21000, value: etherSpent}("");
        require(refunded);
    }
}