// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract StarkPerpetual {
    // Monitored events.
    event LogFrozen();
    event LogUnFrozen();

    function freeze() external {
        emit LogFrozen();
    }

    function unFreeze() external {
        emit LogUnFrozen();
    }
}