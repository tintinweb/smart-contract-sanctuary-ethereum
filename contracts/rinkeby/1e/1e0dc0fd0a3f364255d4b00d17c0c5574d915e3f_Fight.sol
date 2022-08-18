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
        bool flag;
    }

    mapping(address => mapping(address => bool)) Match;

    //Queue to keep track of who has joined the queue to fight
    Player[] Match_Making_Queue;

    //Mapping is used instead of array to save gas and each player will be mapped by their address
    mapping (address => uint) PlayerID;
    uint256 playerCount = 0;

    //If a player wishes to battle with another player they must join the queue

    function JoinQueue(address _player,uint256 _tokenID,uint256 _score) public 
    {
        
        Player memory temp;
        temp.tokenID = _tokenID;
        temp.score = _score;
        PlayerID[_player] = playerCount;
        Match_Making_Queue.push(temp);
        playerCount++;
        
    }

    function Battle(address _player1,address _player2)public
    {
        if(Match_Making_Queue[PlayerID[_player1]].score > Match_Making_Queue[PlayerID[_player2]].score)
        {
            Match[_player1][_player2] = true;
            Match[_player2][_player1] = false;
        }
        else if(Match_Making_Queue[PlayerID[_player1]].score < Match_Making_Queue[PlayerID[_player2]].score)
        {
            Match[_player2][_player1] = true;
            Match[_player1][_player2] = false;
        }
        else
        {
            if(PlayerID[_player1]<PlayerID[_player2])
            {
                Match[_player1][_player2] = true;
                 Match[_player2][_player1] = false;
            }
            else
            {
                Match[_player2][_player1] = true;
                Match[_player1][_player2] = false;
            }
        }

        delete Match_Making_Queue[PlayerID[_player1]];
        delete Match_Making_Queue[PlayerID[_player2]];

    }

    function CheckResult(address _player1,address _player2) public view returns(bool)
    {
        return Match[_player1][_player2];
    }
    
   
}