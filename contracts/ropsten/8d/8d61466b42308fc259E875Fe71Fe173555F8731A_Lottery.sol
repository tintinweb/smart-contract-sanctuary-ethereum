/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;
contract Lottery{
    uint private trackMappping;
    mapping(uint256=>mapping(address=>uint256)) private trackPlayers;
    address public manager;
    uint256 private immutable minContribution;
    address[] private players;
    event playerEntry(address indexed player);
    event winnerPicked(address indexed winner);
    bool public isOpen=true;
    constructor(uint256 _amount){
        minContribution=_amount;
        manager=msg.sender;
    }
    function enterLottery() public payable{
        if(msg.value<=minContribution){
            revert("your value is less than minimium contribution");
        }else if(!isOpen){
            revert("Lottery is closed");
        }
        else if(trackPlayers[trackMappping][msg.sender]==0){
            players.push(msg.sender);
        }
        trackPlayers[trackMappping][msg.sender]+=msg.value;
        emit playerEntry(msg.sender);
    }
    function getminContribution()public view returns(uint256){
        require(isOpen, "Lottery Closed!");
        return minContribution;
    }
    function random() internal view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }
    function pickWinner()public{
        require(isOpen,"Lottery has been closed");
        require(msg.sender==manager,"You aren't the manager of this smart contract");
        require(players.length>3,"Can't declare winner with less than 4 players");
        uint count=random();
        uint winner=count%players.length;
        (bool success,)=payable(players[winner]).call{value:address(this).balance}("");
        if(!success){
            revert("Transfer failed due to some error");
        }
        emit winnerPicked(players[winner]);
        delete players;
        trackMappping++;
        isOpen=false;
        
    }
    function getBalance() public view returns (uint256){
        require(isOpen,"Lottery has been closed");
        return address(this).balance;
    }
    function getParticipants()public view returns(uint256){
        require(isOpen,"Lottery has been closed");
        return players.length;
    }
    function startLottery() public{
        require(msg.sender==manager,"You aren't the manager of this smart contract");
        isOpen=true;
    }



    
}