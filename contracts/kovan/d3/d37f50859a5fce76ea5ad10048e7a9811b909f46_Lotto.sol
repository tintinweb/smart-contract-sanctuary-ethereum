/**
 *Submitted for verification at Etherscan.io on 2022-02-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Lotto {
    struct Bet {
        uint numberFromOneToTen;
        uint256 amountBet;
    }

    mapping(uint => uint256) internal amountBetOnNumber;
    mapping(address => Bet) internal bets;
    address payable[] internal players;
    address internal owner;

    event Payment(address, uint256);
    event PrintWinnerNumber(uint);

    modifier isOwner {
        require(owner == msg.sender, "Only owner can perform this action.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function bet(uint numberFromOneToTen) public payable {    
        require(numberFromOneToTen > 0 && numberFromOneToTen <= 10, "Bet must be a number from 1 to 10");
        require(msg.value > 0, "You must bet at least one wei");
        require(bets[msg.sender].numberFromOneToTen == 0, "You already played!");

        players.push(payable(msg.sender));

        amountBetOnNumber[numberFromOneToTen] += msg.value;

        bets[msg.sender] = Bet({
            amountBet: msg.value,
            numberFromOneToTen: numberFromOneToTen
        });
    }

    function getWinningNumber() public view returns(uint256) {
        return block.timestamp % 10 + 1;
    }

    function payoutWinners() public isOwner {
        uint winningNumber = this.getWinningNumber();
        uint256 potAmount = address(this).balance;

        emit PrintWinnerNumber(winningNumber);

        for (uint i=0; i<players.length; i++) {
            address payable player = players[i];
            if (bets[player].numberFromOneToTen == winningNumber) {
                uint256 payout = potAmount * bets[player].amountBet / amountBetOnNumber[winningNumber];
                emit Payment(player, payout);
                player.transfer(payout);
            }
            bets[player] = Bet({
                amountBet: 0,
                numberFromOneToTen: 0
            });
        }
        for (uint i=1; i<=10; i++) {
            amountBetOnNumber[i] = 0;
        }
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
}