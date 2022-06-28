/**
 *Submitted for verification at Etherscan.io on 2022-06-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// We need to have a way to fund this contract, and people to put ether in it

// Also there would have to be a way someone to retrieve the funds from this smart contract

// First we will focus on the actual game function

contract Casino {
    
    // The amount of ether(wei) that people are playing
    mapping(address => uint256) public gameWeiValues;

    // Here we will keep track of the number of the blockhash that is supposed to be user
    // for each game
    mapping(address => uint256) public blockHashesToBeUsed;

    address public owner;


    address[] public lastThreeWinners;


    event FundsDeposited(address indexed sender, uint256 amount);
    event FundsWithdrawan(address indexed sender, uint256 amount);
    event BetPlaced(address indexed sender, uint256 amount);
    event BetFinished(address indexed sender, uint256 indexed randomNumber, uint256 indexed amount);

    constructor() {
        owner = msg.sender;
    }

    function withdrawFunds(uint256 amount) external {
        require(msg.sender == owner, "Lottery: Only the owner can withdraw funds");
        require(amount <= address(this).balance, "Lottery: Can not withdraw more funds than there is in the Casino");

        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Lottery: ETH withdrawal failed");

        emit FundsWithdrawan(msg.sender, amount);
    }

    function getCasinoBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function playGame() external payable {

        // We have to figure out if the game is called for first time.
        // If this is zero we know the player has called playGame for first time.
        if(blockHashesToBeUsed[msg.sender] == 0) {


            // We are not playing yet, we are just determining which blockhash to be used for the randomness.
            // block.number + 2 should be enough so that this blockhash is not known yet, the time msg.sender is calling playGame for first time.
            blockHashesToBeUsed[msg.sender] = block.number + 2;


            // We are keeping the amount the player has send in the contract.
            // This will later determine the amount that the player wins and how much he will get.
            gameWeiValues[msg.sender] = msg.value;

            emit BetPlaced(msg.sender, msg.value);

            return;
        }

        // We are checking the result.

        // The player should not send any ether because he already did it the first time.
        require(msg.value == 0, "Lottery: Finish current game before starting new one");

        require(blockhash(blockHashesToBeUsed[msg.sender]) != 0, "Lottery: Block not mined yet, or 256 blocks have passed");


        // If the exectuion goes to here we now that the block is mined and we can safely calculate a random number.
        // We have to cast the number to uint256 becuse blockchash function returns bytes array.
        uint256 randomNumber = uint256(blockhash(blockHashesToBeUsed[msg.sender]));


        // Determining win or loose


        uint256 winningAmount;
        // Checking if number is even
        if(randomNumber % 2 == 0) {
            winningAmount = gameWeiValues[msg.sender] * 2;

            (bool success,) = msg.sender.call{value: winningAmount}("");
            require(success, "Lottery: Winning payout failed");

            lastThreeWinners.push(msg.sender);

            if(lastThreeWinners.length > 3) {
                _removeAtIndex(0);
            }
        }


        // We are reseting the state so the player can play again.
        blockHashesToBeUsed[msg.sender] = 0;
        gameWeiValues[msg.sender] = 0;

        emit BetFinished(msg.sender, randomNumber, winningAmount);
    }

    // receive always has to be a payable function, the code inside receive is executed
    // whenever someone sends ether to the contract address without any data
    receive() external payable {
        emit FundsDeposited(msg.sender, msg.value);
    }

    function _removeAtIndex(uint256 i) private {
        lastThreeWinners[i] = lastThreeWinners[lastThreeWinners.length - 1];
        lastThreeWinners.pop();
    }

}