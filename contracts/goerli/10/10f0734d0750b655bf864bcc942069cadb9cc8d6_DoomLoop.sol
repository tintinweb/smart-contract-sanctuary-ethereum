/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface FooFighter {
    function FOOFIGHTER_attack(uint256 attackerId, uint256 defenderId) external;
}

contract DoomLoop {
    address public FOOFIGHTER_CONTRACT = 0x9490165195503fcF6A0FD20aC113223fEfb66eD5;
    
    FooFighter ff;

    constructor() {
        ff = FooFighter(FOOFIGHTER_CONTRACT);
    }

    function doom(uint256 _victim, uint256[] memory attackers) external {
        for (uint i = 0; i < attackers.length; i++) {
            ff.FOOFIGHTER_attack(_victim, attackers[i]);
        }
    }
}