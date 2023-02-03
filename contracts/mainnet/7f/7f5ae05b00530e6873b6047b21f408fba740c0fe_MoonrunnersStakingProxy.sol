/**
 *Submitted for verification at Etherscan.io on 2023-02-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface MoonrunnersStaking {
    function stakeExists(address owner) external view returns (bool);
}

contract MoonrunnersStakingProxy {
    function balanceOf(address owner) public view returns (uint256) {
        bool isStaked = MoonrunnersStaking(address(0x717C6dD66Be92E979001aee2eE169aAA8D6D4361)).stakeExists(owner);
        if (isStaked) {
            return 1;
        } else {
            return 0;
        }
    }
}