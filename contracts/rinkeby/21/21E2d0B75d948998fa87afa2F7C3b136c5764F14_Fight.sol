/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

//SPDX-License-Identifier:MIT
pragma solidity>=0.8.0;

contract Fight 
{
    //Player Info
    struct Player{
        uint256 tokenID;
        uint256 score;
    }

    mapping(address => mapping(address => bool)) Match;

    //Queue to keep track of who has joined the queue to fight
    Player[] Match_Making_Queue;
    address[] Players;

    //If a player wishes to battle with another player they must join the queue


    function Battle_players(address _player1,address _player2) internal
    {
        if(Match_Making_Queue[0].score > Match_Making_Queue[1].score)
        {
            Match[_player1][_player2] = true;
            Match[_player2][_player1] = false;
        }
        else if(Match_Making_Queue[0].score < Match_Making_Queue[1].score)
        {
            Match[_player2][_player1] = true;
            Match[_player1][_player2] = false;
        }
        else
        {
            
                Match[_player1][_player2] = true;
                 Match[_player2][_player1] = false;
           
        }

        Match_Making_Queue.pop();
        Match_Making_Queue.pop();
        Players.pop();
        Players.pop();
    }

    function JoinQueue(address _player,uint256 _tokenID,uint256 _score) public 
    {
        if(Match_Making_Queue.length == 0)
        {
        Player memory temp;
        temp.tokenID = _tokenID;
        temp.score = _score;
        Players.push(_player);
        Match_Making_Queue.push(temp);
        }
        else if(Match_Making_Queue.length == 1)
        {
        Player memory temp;
        temp.tokenID = _tokenID;
        temp.score = _score;
        Players.push(_player);
        Match_Making_Queue.push(temp);
        Battle_players(Players[0],_player);
        }
        
    }

    function CheckResult(address _player1,address _player2) public view returns(bool)
    {
        return Match[_player1][_player2];
    }
    
   
}