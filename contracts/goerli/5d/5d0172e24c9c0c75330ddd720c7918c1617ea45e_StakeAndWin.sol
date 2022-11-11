/**
 *Submitted for verification at Etherscan.io on 2022-11-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StakeAndWin {
    address payable public owner;
    uint public counter = 1;
    uint public playerCounter = 5;

    uint public checkBal = 1;

    uint public balance;
    uint public entryFee;

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
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Only Owner can call this function");
        _;
    }

    modifier checkGameState(GAME_STATE _gameState) {
        require(game_state == _gameState);
        _;
    }

    receive() external payable{}

    function receiveMoney() public payable {
        balance += msg.value;
    }

    function setEntryFee(uint _value) external onlyOwner{
        entryFee = _value;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function destroyContract() external onlyOwner {
        selfdestruct(owner);
    }

    function transferOwnership(address payable _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function setPlayerCounter(uint _value) external onlyOwner checkGameState(GAME_STATE.CLOSE) {
        require(_value >= 2, "Player counter value must be greater than 1");
        playerCounter = _value;
    }

    function addPlayer(address payable _playerAddress, uint _guessedNumber) external checkGameState(GAME_STATE.OPEN) {
        require(counter <= playerCounter, "Game already full.");
        players[counter] = _playerAddress;
        guessedNumber[counter] = _guessedNumber;
        counter ++;
    }

    function changeGameState() external onlyOwner {
        require(counter > 2, "Atleast 2 players are required");
        game_state = GAME_STATE.CLOSE;
    } 

    function endGame(address payable[] memory _winners) external onlyOwner {
        owner.transfer((address(this).balance * 20) / 100);
        uint winnerAmount = address(this).balance / _winners.length;
        for(uint i=0; i<_winners.length; i++) {
            _winners[i].transfer(winnerAmount);
        }
        counter = 1;
        game_state = GAME_STATE.OPEN;
    }
}