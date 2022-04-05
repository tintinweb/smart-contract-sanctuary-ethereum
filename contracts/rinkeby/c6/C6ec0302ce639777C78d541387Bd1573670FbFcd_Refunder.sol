// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Refunder {
    event SomeWork();

    function doWork() external {
        uint gasStart = gasleft();
        for (uint i = 0; i < 100; i++) {
            emit SomeWork();
        }

        uint gasSpent = gasStart - gasleft();
        uint etherSpent = (28921 + gasSpent) * tx.gasprice;

        // solhint-disable avoid-low-level-calls, reason-string
        (bool refunded, ) = msg.sender.call{gas: 21000, value: etherSpent}("");
        require(refunded);
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}  
}