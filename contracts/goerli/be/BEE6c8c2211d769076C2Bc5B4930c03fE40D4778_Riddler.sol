/**
 *Submitted for verification at Etherscan.io on 2023-03-04
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Riddler {
    address owner;
    uint256 minDepositToPlay;
    //we need some way to store the riddles
    // we can define one as a Riddle struct

    struct Riddle {
        string question;
        bytes32 answer;
        bool isSolved;
        uint256 totalBadGuessCollected;
        uint256 createRiddleRewardAmount;
    }
    //store all of our riddles in this array
    Riddle[] riddles;

    //emit an event when a riddle is created
    event RiddleCreated(string question, string answer);

    event correctGuess(address guesser, string answer, uint256 rewardAmount);

    //send ETH to this contract to serve as a reward for the correct guess
    constructor() payable {
        owner = msg.sender;
        minDepositToPlay = 1 wei;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can do that thang");
        _;
    }

    function getMinDepositAmount() external view returns (uint256) {
        return minDepositToPlay;
    }

    function createRiddle(
        string memory question,
        string memory answer
    ) public payable onlyOwner {
        bytes32 hashedAnswer = keccak256(abi.encodePacked(answer));
        Riddle memory riddle = Riddle(
            question,
            hashedAnswer,
            false,
            0,
            msg.value
        );
        riddles.push(riddle);
    }

    function getRiddles() public view returns (Riddle[] memory) {
        return riddles;
    }

    function guess(
        uint256 index,
        string memory answer
    ) external payable returns (bool) {
        Riddle memory riddle = riddles[index];
        require(!riddle.isSolved, "riddle already solved");
        require(msg.value == minDepositToPlay, "need more money");
        if (riddle.answer == keccak256(abi.encodePacked(answer))) {
            riddles[index].isSolved = true;
            // payable(msg.sender).transfer(address(this).balance);
            //let's pay the winner
            emit correctGuess(
                msg.sender,
                answer,
                riddle.totalBadGuessCollected + riddle.createRiddleRewardAmount
            );
            payable(msg.sender).transfer(
                riddle.totalBadGuessCollected + riddle.createRiddleRewardAmount
            );
            return true;
        } else {
            //wrong guess
            riddles[index].totalBadGuessCollected += msg.value;
        }
    }

    //withdraw lets me take all the money in the contract
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}