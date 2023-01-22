pragma solidity ^0.8.9;

contract WordFlip {
    event Log(uint timestamp, uint[] deck);
    uint[] public deck;
    string[] cardRanks = ["Ace","2","3","4","5","6","7","8","9","10","Jack","Queen","King"];
    string[] cardSuits = ["Spades","Hearts","Diamonds","Clubs"];

    constructor() public {
        // Initialize the deck
        for (uint i = 0; i < 52; i++) {
            deck.push(i);
        }
    }
    function swap(uint i, uint j) private {
        uint temp = deck[i];
        deck[i] = deck[j];
        deck[j] = temp;
    }
    function shuffle() public {
        // shuffle the deck
        for (uint i = 0; i < 52; i++) {
            uint randomIndex = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % (52 - i);
            swap(i, i + randomIndex);
        }
        emit Log(block.timestamp, deck);
    }
    function getFirstTwoCards() public view returns (string memory rank1, string memory suit1, string memory rank2, string memory suit2) {
        uint card1 = deck[0];
        uint card2 = deck[1];
        rank1 = cardRanks[card1 % 13];
        suit1 = cardSuits[card1 / 13];
        rank2 = cardRanks[card2 % 13];
        suit2 = cardSuits[card2 / 13];
        return (rank1, suit1, rank2, suit2);
    }
}