/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Voting {
    uint alpha;
    uint beta;

    function voteAlpha() external {
        alpha += 1;
    }

    function voteBeta() external {
        beta += 1;
    }

    function getAlpha() external view returns (uint) {
        return alpha;
    }

    function getBeta() external view returns (uint) {
        return beta;
    }
}