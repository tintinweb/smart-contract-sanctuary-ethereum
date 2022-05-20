// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.2;

contract Lottery {

    address public owner;
    address payable[] public players;
    address public lastWinner;
    uint public etherDepositAmount;
    uint public numberDeposits;
    uint public minDeposits;

    constructor(uint _weiAmount, uint _minDeposits) {
        etherDepositAmount = _weiAmount;
        minDeposits = _minDeposits;
        owner = msg.sender;
    }

    function deposit() public payable {
        require(msg.value == etherDepositAmount);
        players.push(payable(msg.sender));
        numberDeposits += 1;
    }

    function getBalance() public view returns(uint){
        return address(this).balance;
    }
    
    function generateRandomNumber() public view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }

    function pickWiner() public {
        require(numberDeposits >= minDeposits || msg.sender == owner);

        uint randomNumber = generateRandomNumber();
        address payable winner;
        uint index = randomNumber % players.length;
        winner = players[index];
        lastWinner = winner;
        delete players;
        winner.transfer(address(this).balance);
    }

}