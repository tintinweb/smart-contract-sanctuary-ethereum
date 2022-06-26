/**
 *Submitted for verification at Etherscan.io on 2022-06-26
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// Needs to be some way to fund the contract, and people to put ether, so other people can play

// There would have to be a way to someone retrieve the funds that this contract here will have

// But we will leave that out and only focus on the actual game function

contract Casino {
  // We are going to use a randomness as we have previously discussed with a future block hash

  // The amount of ether(wei) that people are playing
  mapping(address => uint256) public gameWeiValues;

  // Here we will keep track of the number of the blockhash that is supposed to be used for each game
  mapping(address => uint256) public blockHashesToBeUsed;

  address[] public lastThreeWinners;

  address public owner;

  event FundsWithdrawn(address indexed sender, uint256 indexed amount);
  event FundsDeposited(address indexed sender, uint256 indexed amount);
  event BetPlaced(uint256 indexed amount);
  event BetWon(uint256 indexed randomNumber, uint256 indexed amount);
  event BetLost(uint256 indexed randomNumber, uint256 indexed amount);

  constructor() {
    owner = msg.sender;
  }

  function withdrawFunds(uint256 amount) external {
    require(msg.sender == owner, "Lottery: Only the owner can withdraw funds");
    require(amount <= address(this).balance, "Lottery: Can not withdraw more funds than there is in the Casino");

    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "Lottery: ETH withdrawal failed");

    emit FundsWithdrawn(msg.sender, amount);
  }

  function getCasinoBalance() external view returns (uint256) {
    return address(this).balance;
  }

  function playGame() external payable {
    // We have to figure out if the game is called for the first time. If this is zero we know he has called it for first time
    if(blockHashesToBeUsed[msg.sender] == 0) {
      // We are not playing yet we are just determining which block hash to be used for the randomness. Two should be enough so thath this block Hash is not known, the time
      // when msg.sender is calling play game the first time
      blockHashesToBeUsed[msg.sender] = block.number + 2;

      // We are keeping the amount he sends in the contract
      // This will later determine the amount that he wins and how much should he win if he wins
      gameWeiValues[msg.sender] = msg.value;

      emit BetPlaced(msg.value);
      return;
    }

    // Otherwise we are playing the game this is the second time he is calling this function

    // He should not send any ether because he already did it the first time
    require(msg.value == 0, "Lottery: Finish current game before starting new one");

    // We have to check that the block is actually mined
    require(blockhash(blockHashesToBeUsed[msg.sender]) != 0, "Lottery: Block not mined yet");

    // If we come to here we now that the block is mined and we can safely calculate a random number
    // and we have random uint256 number that we can use
    uint256 randomNumber = uint256(blockhash(blockHashesToBeUsed[msg.sender]));

    // How we determine if he wins

    // If the random number turns to be even he wins
    if(randomNumber % 2 == 0) {
      uint256 winningAmount = gameWeiValues[msg.sender] * 2;
      (bool success,) = msg.sender.call{value: winningAmount}("");
      require(success, "Lottery: Winning payout failed");

      lastThreeWinners.push(msg.sender);

      if(lastThreeWinners.length > 3) {
        removeAtIndex(0);
      }

      emit BetWon(randomNumber, winningAmount);
    } else {
      // else if he looses we don't have to do anything
      emit BetLost(randomNumber, gameWeiValues[msg.sender]);
    }


    //at the end we are reseting the state so he can play again
    blockHashesToBeUsed[msg.sender] = 0;
    gameWeiValues[msg.sender] = 0;
  }

  // Executed when no other function signatures matches the data sent to the contract

  // receive always has to be payable function, the code that we write inside receive
  // will be executed whenever someone sends ether to the contract address without any data
  receive() external payable {
    emit FundsDeposited(msg.sender, msg.value);
  }

  // fallback is called whenever someone sends anything to the contract that doesn't match
  // any existing functionality, so that usually means sending data which has function selector
  // that the contract doesn't now


  function removeAtIndex(uint256 i) private {
    lastThreeWinners[i] = lastThreeWinners[lastThreeWinners.length -1];
    lastThreeWinners.pop();
  }
}