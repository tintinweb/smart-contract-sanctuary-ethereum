/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

interface IChallenge {
    function sendTask(string calldata data) external;
}

contract Challenge1Aswr {
    address challengeAddr;

    function setChallengeAddr(address _t) public {
        challengeAddr = _t;
    }

    function sendTask(string calldata data) public {
        IChallenge(challengeAddr).sendTask(data);
    }
}