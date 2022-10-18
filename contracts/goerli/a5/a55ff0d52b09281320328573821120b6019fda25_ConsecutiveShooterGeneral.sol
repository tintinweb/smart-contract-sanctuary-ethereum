// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IGeneral.sol";

contract ConsecutiveShooterGeneral is IGeneral {
    address private _owner;

    constructor() {
        _owner = msg.sender;
    }

    function name() external pure override returns (string memory) {
        return "straight-shooter";
    }

    function owner() external view override returns (address) {
        return _owner;
    }

    function fire(
        uint256, /* myBoard */
        uint256, /* myAttacks */
        uint256, /* opponentsAttacks */
        uint256 myLastMove,
        uint256, /* opponentsLastMove */
        uint256 /* opponentsDiscoveredFleet */
    ) external pure override returns (uint256) {
        if (myLastMove == 255) {
            // game just started
            return 0;
        }
        if (myLastMove == 63) {
            return 63;
        }
        return myLastMove + 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IGeneral {
    // nickname of your general
    function name() external view returns (string memory);

    // must be the address you will be calling the Game contract from.
    // this value is to check that no one else is using your code to play. credit: 0xBeans
    function owner() external view returns (address);

    // this function needs to return an index into the 8x8 board, i.e. a value between [0 and 64).
    // a shell will be fired at this location. if you return >= 64, you're TKO'd
    // you're constrained by gas in this function. Check Game contract for max_gas
    // check Board library for the layout of bits of myBoard
    // check Attacks library for the layout of bits of attacks
    // check Fleet library for the layout of bits of fleet. Non-discovered fleet will have both,
    // the start and end coords =0
    function fire(
        uint256 myBoard,
        uint256 myAttacks,
        uint256 opponentsAttacks,
        uint256 myLastMove,
        uint256 opponentsLastMove,
        uint256 opponentsDiscoveredFleet
    ) external returns (uint256);
}