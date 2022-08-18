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

    //Queue to keep track of who has joined the queue to fight
    address[] Match_Making_Queue;

    //Mapping is used instead of array to save gas and each player will be mapped by their address
    mapping (address => Player) Players;

    //If a player wishes to battle with another player they must join the queue

    function JoinQueue(address _player,uint256 _tokenID,uint256 _score) public 
    {
        if(Match_Making_Queue.length == 1)
        {
        address temp = Match_Making_Queue[0];
        Match_Making_Queue.pop();
        Battle(temp,_player);    
        }
        else
        {
        Player memory temp;
        temp.tokenID = _tokenID;
        temp.score = _score;

        Players[_player] = temp;
        Match_Making_Queue.push(_player);
        }
    }

    function CheckResult(address _player1,address _player2)public view returns(address)
    {
        if(Players[_player1].flag == true)
        {
            return _player1;
        }
        else
        {
            return _player2;
        }
    }

    function Battle(address _player1, address _player2) internal
    {    
        if(Players[_player1].score > Players[_player2].score)
        {
            Players[_player1].flag = true;
            Players[_player2].flag = false;
        }
        else if(Players[_player1].score < Players[_player2].score)
        {
            Players[_player2].flag = true;
            Players[_player1].flag = false;
        }
        else
        {
            Players[_player1].flag = true;
            Players[_player2].flag = false;
        }
    }

    
   
}