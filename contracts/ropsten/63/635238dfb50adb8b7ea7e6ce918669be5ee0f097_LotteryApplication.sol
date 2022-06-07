/**
 *Submitted for verification at Etherscan.io on 2022-06-07
*/

// SPDX-License-Identifier: GPL-3.1.0

pragma solidity >=0.7.0 <0.9.0;
contract LotteryApplication {
    address payable public admin;
    address payable [] public players;
    address [] public winners;
    uint startTime;
    uint endTime;
    bool started;

    constructor (){

    }
    function Lottery() public {
        //msg.sender is deployer of the contract who deploys this contract.
        admin = payable(msg.sender);
    }

    function startLottery() public restricted{
        require(started == false);
        startTime = block.timestamp;
        endTime = startTime + 10 days;
        started = true;
    }
    
    function register() public payable {
        require(started == true);
        require(msg.value >= 0.01 ether);
        players.push(payable(msg.sender));
    }
    
    function random() private view returns (uint) {
        require(getPlayers().length > 0,"There are no players registered in lottery");
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }
    
    /**
      only admin can call the pickWinner function.
    */
    function pickWinner() public restricted {
        require(block.timestamp > endTime, "Lottery is not ended yet.");
        uint index = random() % players.length;
        players[index].transfer(address(this).balance);
        winners.push(players[index]);
        players = new address payable[](0);
        
    }
    
    modifier restricted() {
        require(msg.sender == admin, "You are not admin");
        _;
    }
    
    function getPlayers() public view returns (address[] memory) {
        /**
          players is storage type and function is to return memory type
          so, it needs to be converted to memory type
        */
        address [] memory playerList = new address[](players.length);
        for(uint i=0; i < players.length; i++) {
           playerList[i] = players[i];
        }
        return playerList;
    }

    function getWinners() public view returns (address[] memory) {
        return winners;       
    }
 }