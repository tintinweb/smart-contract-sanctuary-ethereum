pragma solidity ^0.8.9;

contract WordFlip {
    uint[] public deck;
    mapping(uint => string) public cardRanks;
    mapping(uint => string) public cardSuits;

    function shuffle() public {
        // Get the timestamp of the current block
        uint seed = uint(block.timestamp);

        // Fisher-Yates shuffle algorithm
        for (uint i = 51; i > 0; i--) {
            uint j = uint(seed % (i + 1));
            seed = seed / (i + 1);
            uint temp = deck[i];
            deck[i] = deck[j];
            deck[j] = temp;
        }
    }

    function printDeck() public {
        shuffle();
        for (uint i = 0; i < 52; i++) {
            uint card = deck[i];
            emit LogCard(cardRanks[card], cardSuits[card]);
        }
    }
    function init() public {
        for(uint i = 0; i < 52; i++) {
            deck[i] = i;
            if (i < 13) {
                cardSuits[i] = "Clubs";
            } else if (i < 26) {
                cardSuits[i] = "Diamonds";
            } else if (i < 39) {
                cardSuits[i] = "Hearts";
            } else {
                cardSuits[i] = "Spades";
            }
            if (i == 0) {
                cardRanks[i] = "Ace";
            } else if (i % 13 == 0) {
                cardRanks[i] = "2";
            } else if (i % 13 == 1) {
                cardRanks[i] = "3";
            } else if (i % 13 == 2) {
                cardRanks[i] = "4";
            } else if (i % 13 == 3) {
                cardRanks[i] = "5";
            } else if (i % 13 == 4) {
                cardRanks[i] = "6";
            } else if (i % 13 == 5) {
                cardRanks[i] = "7";
            } else if (i % 13 == 6) {
                cardRanks[i] = "8";
            } else if (i % 13 == 7) {
                cardRanks[i] = "9";
            } else if (i % 13 == 8) {
                cardRanks[i] = "10";
            } else if (i % 13 == 9) {
                cardRanks[i] = "Jack";
            } else if (i % 13 == 10) {
                cardRanks[i] = "Queen";
            } else if (i % 13 == 11) {
                cardRanks[i] = "King";
            } else if (i % 13 == 12) {
                cardRanks[i] = "Ace";
            }
        }
    }
    function callPrintDeck() public {
        shuffle();
        printDeck();
    }
    event LogCard(string rank, string suit);
}