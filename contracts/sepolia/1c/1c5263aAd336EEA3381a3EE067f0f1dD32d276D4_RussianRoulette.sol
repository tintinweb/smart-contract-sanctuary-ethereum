/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

/// @title A contract for a Russian Roulette game
contract RussianRoulette {
    // Emit events for front-ends and/or external systems monitoring the game status
    event PlayerJoined(address player);
    event RoundResult(address player, bool survived);
    event GameFinished(address winner);
    event GameStarted(bool);
    
    // State variables
    address payable public owner; // the owner of the game who can withdraw the house pool
    uint256 public ownerPool; // the pool amount that goes to the owner
    uint256 constant BLOCKS_PER_ROUND = 20;  // The number of blocks per round, adjustable as needed.
    uint256 public nextRoundBlock; // The block number when the next round can be triggered
    mapping(uint => address payable) public players; // the players in the current game
    uint public playerCount = 0; // count of current players in the game
    address payable public winnerAddress; // address of the winner of the game
    bool public gameStarted = false; // flag to indicate if the game is in progress

    constructor() {
        owner = payable(msg.sender); // set the contract deployer as the owner
    }
    
    // Function for a player to join the game
    function joinGame() external payable {
        require(msg.value >= 0.05 ether, "Insufficient bet amount");
        require(gameStarted == false, "Game already started");
        require(players[playerCount] != msg.sender, "Address already joined the game");
        ownerPool += 0.01 ether;
        players[playerCount] = payable(msg.sender);
        playerCount++;
        emit PlayerJoined(msg.sender);
        
        // Automatically start the game when 4 players join
        if(playerCount == 4){
            startGame();
        }
    }

    // Function to start the game
    function startGame() public {
        require(playerCount >= 2, "Not enough players");
        gameStarted = true;
        nextRoundBlock = block.number + BLOCKS_PER_ROUND;
        emit GameStarted(true);
    }

    // Function to start the next round
    function startNextRound() external {
        require(gameStarted, "Game hasn't started");
        require(block.number >= nextRoundBlock, "Can't start new round yet");
        uint256 loserIndex = uint256(blockhash(block.number-1)) % playerCount;
        emit RoundResult(players[loserIndex], false);
        players[loserIndex] = players[playerCount-1];
        playerCount--;
        if(playerCount == 1) {
            gameFinished(players[0]);
        } else {
            nextRoundBlock = block.number + BLOCKS_PER_ROUND;
        }
    }

    // Private function to finish the game
    function gameFinished(address _winner) private {
        gameStarted = false;
        winnerAddress = payable(_winner);
        emit GameFinished(_winner);
    }

    // Function for the winner to withdraw the prize
    function withdraw() external {
        require(msg.sender == winnerAddress, "Only winner can withdraw");
        uint256 prize = address(this).balance - ownerPool;
        require(prize > 0, "No prize to withdraw");
        winnerAddress.transfer(prize);
    }

    // Function for the owner to withdraw the house pool
    function ownerWithdraw() external {
        require(msg.sender == owner, "Only owner can withdraw");
        require(ownerPool > 0, "No owner pool to withdraw");
        owner.transfer(ownerPool);
        ownerPool = 0;
    }
}