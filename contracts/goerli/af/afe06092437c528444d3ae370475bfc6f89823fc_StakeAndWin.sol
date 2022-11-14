/**
 *Submitted for verification at Etherscan.io on 2022-11-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StakeAndWin {
    address payable public owner;
    uint public counter = 1;
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

    receive() external payable{}

    function getOwner() external view returns (address) {
        return owner;
    }

    function getEntryFee() external view returns (uint) {
        return entryFee;
    }

    function getCounter() external view returns (uint) {
        return counter;
    }

    function setEntryFee(uint _value) external onlyOwner{
        entryFee = _value;
    }

    function transferOwnership(address payable _newOwner) external onlyOwner {
        owner = _newOwner;
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