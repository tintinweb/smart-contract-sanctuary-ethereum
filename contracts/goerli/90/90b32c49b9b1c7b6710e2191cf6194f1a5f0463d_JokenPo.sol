/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

//Rock Paper Scissors
//Rock > Scissors > Paper > Rock

contract JokenPo {
    enum Options{NONE, ROCK, PAPER, SCISSORS}
    Options private choicePlayer1 = Options.NONE;
    address private player1;
    string public status;
    address payable private immutable owner;

    struct Player {
        address wallet;
        uint32 wins;
    }

    Player[] public winners;

    constructor(){
        owner = payable(msg.sender);
    }

    function updateWinner(address winner) private {
        for(uint i = 0; i < winners.length; i++){
            if(winners[i].wallet == winner){
                winners[i].wins++;
                return;
            }
        }

        winners.push(Player(winner, 1));
    }

    function finishGame(string memory newStatus, address winner) private{
        address contractAddress = address(this);
        payable(winner).transfer((contractAddress.balance/100)*90);
        owner.transfer(contractAddress.balance);

        updateWinner(winner);

        status = newStatus;
        choicePlayer1 = Options.NONE;
        player1 = address(0);
    }

    function getBalance() public view returns (uint) {
        require(owner == msg.sender, "You don't have permission!");
        return address(this).balance;
    }

    function play(Options choice) public payable {
        require(choice != Options.NONE, "Invalid choice!");
        require(player1 != msg.sender, "Wait another player!");
        require(msg.value >= 0.01 ether, "Invalid bid!");
        
        if(choicePlayer1 == Options.NONE){
            player1 = msg.sender;
            choicePlayer1 = choice;
            status = "Player 1 chose his option! Waiting player 2!";
        }
        else if(choicePlayer1 == Options.PAPER && choice == Options.ROCK)
           finishGame("PAPER wrapes ROCK! PLAYER 1 WON!!!", player1);
        else if(choicePlayer1 == Options.ROCK && choice == Options.SCISSORS)
            finishGame("ROCK breakes SCISSORS! PLAYER 1 WON!!!", player1);
        else if (choicePlayer1 == Options.SCISSORS && choice == Options.PAPER)
            finishGame("SCISSORS cuts PAPER! PLAYER 1 WON!!!", player1);
        else if (choicePlayer1 == Options.PAPER && choice == Options.SCISSORS)
            finishGame("SCISSORS cuts PAPER! PLAYER 2 WON!!!", msg.sender);
        else if(choicePlayer1 == Options.ROCK && choice == Options.PAPER)
            finishGame("PAPER wrapes ROCK! PLAYER 2 WON!!!", msg.sender);
        else if(choicePlayer1 == Options.SCISSORS && choice == Options.ROCK) 
            finishGame("ROCK breakes SCISSORS! PLAYER 2 WON!!!", msg.sender);
        else{
            status = "It was a DRAW GAME!!! Accumulated balance!";
            choicePlayer1 = Options.NONE;
            player1 = address(0);
        }       
    }

    function getLeaderboard() public view returns(Player[] memory){
        if(winners.length < 2) return winners;

        Player[] memory arr = new Player[](winners.length);

        for(uint i = 0; i < winners.length; i++)
            arr[i] = winners[i];
        
        for(uint i = 0; i < arr.length - 1; i++){
            for(uint j = 1; j < arr.length; j++){
                if(arr[i].wins < arr[j].wins){
                    Player memory change = arr[i];
                    arr[i] = arr[j];
                    arr[j] = change;
                }
            }
        }

        return arr;
    }
}