// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// Simplified StarkPerpetual contract to emit the monitored events.
contract StarkPerpetual {
    // Monitored events.
    event LogOperatorAdded(address operator);
    event LogOperatorRemoved(address operator);

    function registerOperator(address newOperator) external {
        emit LogOperatorAdded(newOperator);
    }

    function unregisterOperator(address removedOperator) external {
        emit LogOperatorRemoved(removedOperator);
    }
}