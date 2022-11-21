/**
 *Submitted for verification at Etherscan.io on 2022-11-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StakeAndWin {
    address payable public owner;
    uint public counter;
    uint public entryFee;
    uint public winningNumber;
    address payable[] public winners;

    enum GAME_STATE {
        OPEN,
        CLOSE
    }
    GAME_STATE public game_state;

    mapping (uint => address payable) public players;
    mapping (uint => uint) public guessedNumber;

    constructor(uint _entryFee) {
        owner = payable(msg.sender);
        entryFee = _entryFee;
        counter = 1;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Only Owner can call this function");
        _;
    }

    receive() external payable {}
    
    fallback() external payable {}

    function setEntryFee(uint _value) external onlyOwner{
        entryFee = _value;
    }

    function transferOwnership(address payable _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function getWinnersList() external view returns (address payable[] memory) {
        return winners;
    }

    function addPlayer(address payable _playerAddress, uint _guessedNumber) external {
        require(game_state == GAME_STATE.OPEN, "Game state should be open");
        players[counter] = _playerAddress;
        guessedNumber[counter] = _guessedNumber;
        counter ++;
    }

    function closeGameState() external onlyOwner {
        require(counter > 2, "Atleast 2 players are required");
        game_state = GAME_STATE.CLOSE;
    } 
            
    function endGame(address payable[] memory _newWinners, uint _winningNumber) external onlyOwner {
    	require(game_state == GAME_STATE.CLOSE, "Game state should be closed");
        winningNumber = _winningNumber;
        winners = _newWinners;

        if (_newWinners.length > 0) {
    	    uint winningAmount = ((address(this).balance) * 80) / 100;
    	    uint winnerAmount = winningAmount / winners.length;
    	
        	for(uint i = 0; i < winners.length; i++) {
                winners[i].transfer(winnerAmount);
            }
        }
    	   	
        owner.transfer(address(this).balance);
        counter = 1;
        game_state = GAME_STATE.OPEN;
    }
}