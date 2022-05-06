// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.1;

contract Guess_Number {
    address payable player;
    uint private secretNumber;
    enum State {OPEN, CLOSED}
    State public currState;

    event TryAgain(uint guessNumber, State state);
    event Success(uint guessNumber, State state);

    constructor(uint _secretNumber) payable {
        require(msg.value >= 10000 , "Contract needs to be funded atleast with 10000 Wei");
        secretNumber = _secretNumber;
        currState = State.OPEN;   
    }

    function getBalance() public view returns (uint){
        return(address(this).balance);
    }

    function play(uint guessNumber) external payable{
        require(msg.value >= 1000, "Player Needs to pay atleast 1000 Wei to play");
        require(currState == State.OPEN);
        player = payable(msg.sender);
        if (guessNumber == secretNumber){
            player.transfer(address(this).balance);
            currState = State.CLOSED;   
            emit Success(guessNumber, currState);
        }
        else {
            emit TryAgain(guessNumber, currState);
        }
    }
}