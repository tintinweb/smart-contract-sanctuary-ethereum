/**
 *Submitted for verification at Etherscan.io on 2022-05-10
*/

/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**

Lottery sells 10,000 tickets at 0.01 eth each and picks a winner after 10,000th ticket is sold, then restarts lottery. 
Winner can be chosen early if game has been active without selling 10,000 tickets for 3 days.
Anyone can call the function to end the game early and pick a winner after 3 day time period.
1% Fee paid to house. No limit to the amount of tickets you can buy. More tickets, more likelihood of winning.

**/


contract Lottery {
    mapping(address => mapping(uint => uint)) public ticketsPurchasedOfGame;
    mapping(uint => mapping(uint => address)) public ticketOwnerOfGame;
    mapping(uint => bool) public gameCompleted;
    mapping(uint => address) public winnerOfGame;

    uint public ticketNumber;
    uint public currentGame = 0;
    uint public costPerTicket = 0.01 ether;
    uint public chooseWinnerAt = 10000;
    uint public failSafeTime = 7 days;
    uint public gameStartTime = block.timestamp;
    uint public endEarlyEligibleTime = block.timestamp + failSafeTime;

    uint256 nonce;
    address winner;
    address house;

    constructor (address _house) {
        house = _house;
        startNewGame();
    }

    function startNewGame() internal {
        ticketNumber = 0; //resets ticket number
        currentGame++; //adds to game count
        gameStartTime = block.timestamp; //resets game start time
        endEarlyEligibleTime = block.timestamp + failSafeTime;
    }


    function generateRandom(uint betweenOneAnd___) internal returns (uint) {
        uint randomnumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % (betweenOneAnd___ - 1); //returns a "random" number between 0 and 99
        randomnumber = randomnumber + 1; //changes result to add 1, resulting in a random number between 1 and 100.
        nonce += 1;
        return randomnumber;
    }

    function chooseWinner() internal {
        uint winningTicket = generateRandom(ticketNumber);
        winner = ticketOwnerOfGame[winningTicket][currentGame];
        winnerOfGame[currentGame] = winner;
        distributeWinnings();
        
    }

    function distributeWinnings() internal {
        uint winnings = address(this).balance;
        uint houseFee = winnings * 10/100;
        (bool a, ) = winner.call{value: winnings-houseFee}("");
        require(a, "Address: unable to send value, recipient may have reverted");
        (bool b, ) = house.call{value: houseFee}("");
        require(b, "Address: unable to send value, recipient may have reverted");
        gameCompleted[currentGame] = true;
        startNewGame();
        
    }

    function purchaseTicket(uint _quantity) public payable {
        require(msg.value == _quantity * costPerTicket, "insufficient funds");
        require(_quantity <= chooseWinnerAt - ticketNumber, "There aren't enough tickets left in this game. Buy less or wait til next game.");
        for(uint i=0; i<_quantity; i++) {
            ticketNumber++;
            ticketsPurchasedOfGame[msg.sender][currentGame]++;
            ticketOwnerOfGame[ticketNumber][currentGame] = msg.sender;
        }
        if(ticketNumber == chooseWinnerAt) {
            chooseWinner();
            
        }
        
    }

    function endGameEarly() public payable{
        require(block.timestamp > endEarlyEligibleTime, "This game is still in progress and not eligible to end early.");
        chooseWinner();
    } 

}