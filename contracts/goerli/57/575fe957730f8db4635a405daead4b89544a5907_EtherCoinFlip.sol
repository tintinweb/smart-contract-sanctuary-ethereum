/**
 *Submitted for verification at Etherscan.io on 2023-02-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract EtherCoinFlip {

    struct EtherCoinFlipStruct {
        uint256 ID;
        address payable betStarter;
        uint256 startingWager;
        address payable betEnder;
        uint256 endingWager;
        uint256 etherTotal;
        address payable winner;
        address payable loser;
    }

    uint256 numCoinFlips = 300;
    mapping(uint256 => EtherCoinFlipStruct) public EtherCoinFlipStructs;

    event startedCoinfFlip(uint256 indexed theCoinFlipID);

    // Start the Ether coin flip
    function newCoinFlip() public payable returns (uint256 coinFlipID) {
        address theBetStarter = msg.sender;
        address payable player1 = payable(theBetStarter);
        coinFlipID = numCoinFlips++;
        EtherCoinFlipStructs[coinFlipID] = EtherCoinFlipStruct(
            coinFlipID,
            player1,
            msg.value,
            player1,
            msg.value,
            0,
            player1,
            player1
        );
        emit startedCoinfFlip(coinFlipID);
    }

    event finishedCoinFlip(address indexed winner);

    // End the coin flip
    function endCoinFlip(uint256 coinFlipID) public payable {
        EtherCoinFlipStruct storage c = EtherCoinFlipStructs[coinFlipID];
        address theBetender = msg.sender;
        address payable player2 = payable(theBetender);

        require(coinFlipID == c.ID, "Invalid coin flip ID");
        require(msg.value == c.startingWager, "Invalid wager amount");

        c.betEnder = player2;
        c.endingWager = msg.value;
        c.etherTotal = c.startingWager + c.endingWager;

        uint256 randomResult = block.difficulty + block.chainid + block.gaslimit + block.number + block.timestamp;

        if ((randomResult % 2) == 0) {
            c.winner = c.betStarter;
        } else {
            c.winner = c.betEnder;
        }

        c.winner.transfer(c.etherTotal);
        emit finishedCoinFlip(c.winner);
    }
}