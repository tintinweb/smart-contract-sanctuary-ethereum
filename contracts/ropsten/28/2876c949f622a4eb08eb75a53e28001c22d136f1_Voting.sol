/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Voting {
    event Vote(address voter, uint alpha, uint beta);

    uint alpha;
    uint beta;

    constructor() {
        alpha += 1;
        beta += 2;
        emit Vote(msg.sender, alpha, beta);
    }

    function voteAlpha() external {
        alpha += 1;
        emit Vote(msg.sender, alpha, beta);
    }

    function voteBeta() external {
        beta += 1;
        emit Vote(msg.sender, alpha, beta);
    }

    
    function getAlpha() external view returns (uint) {
        return alpha;
    }

    function getBeta() external view returns (uint) {
        return beta;
    }
}