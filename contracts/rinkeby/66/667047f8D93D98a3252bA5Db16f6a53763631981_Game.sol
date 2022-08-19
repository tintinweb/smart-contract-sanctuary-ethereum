/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

//SPDX-License-Identifier:MIT
pragma solidity>=0.8.0;

contract Game
{
    address owner;
    //Player Info
    struct Player{
        uint256 tokenID;
        uint256 score;
    }

    mapping(address => mapping(address => bool)) Match;
    mapping(address => Player) addressToPlayer;
    address[] MatchQueue;

    constructor()
    {
        owner = msg.sender;
    }

    function JoinQueue(address _player,uint256 _tokenID,uint256 _score) public 
    {
        require(_player == msg.sender || msg.sender == owner,"You are not the owner of this address");
        if(MatchQueue.length == 0)
        {
        Player memory temp;
        temp.tokenID = _tokenID;
        temp.score = _score;
        addressToPlayer[msg.sender] = temp;
        MatchQueue.push(_player);
        }
        else
        {
            require(MatchQueue[0] != msg.sender,"This person is already in the queue");
            Player memory temp;
        temp.tokenID = _tokenID;
        temp.score = _score;
        addressToPlayer[msg.sender] = temp;
        MatchQueue.push(_player);

        if(addressToPlayer[MatchQueue[0]].score < addressToPlayer[MatchQueue[1]].score )
        {
            Match[MatchQueue[1]][MatchQueue[0]] = true;
            Match[MatchQueue[0]][MatchQueue[1]] = false;
        }
        else
        {
            Match[MatchQueue[0]][MatchQueue[1]] = true;
            Match[MatchQueue[1]][MatchQueue[0]] = false;
        }

        MatchQueue.pop();
        MatchQueue.pop();

        }

    }

    function isPersonInQueue(address _player)public view returns(bool)
    {
        if(MatchQueue.length !=0)
        {
            if(MatchQueue[0] == _player)
            {
                return true;
            }
            else{
                return false;
            }
        }
        else
        {
            return false;
        }
    }

    function CheckResult(address opponentAddress) public view returns(bool)
    {
        require(opponentAddress != msg.sender,"The opponents address is the same as yours");
        return Match[msg.sender][opponentAddress];
    }

    function GetPlayer(address _player) public view returns(Player memory) 
    {
        return addressToPlayer[_player];
    }

}