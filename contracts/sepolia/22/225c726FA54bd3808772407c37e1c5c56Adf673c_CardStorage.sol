/**
 *Submitted for verification at Etherscan.io on 2023-05-26
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract CardStorage {
    struct Card {
        uint id;
        uint quantity;
    }

    struct Deck {
        string faction;
        string title;
        uint leader;
        uint board;
        Card[] cards;
    }

    mapping(address => Deck) public decks;

    function setDeck(string memory faction, string memory title, uint leader, uint board, uint[] memory ids, uint[] memory quantities) public {
        require(ids.length == quantities.length, "ids and quantities array lengths must match");

        Deck storage deck = decks[msg.sender];
        deck.faction = faction;
        deck.title = title;
        deck.leader = leader;
        deck.board = board;

        for (uint i = 0; i < ids.length; i++) {
            deck.cards.push(Card(ids[i], quantities[i]));
        }
    }

    function getDeck() public view returns (string memory, string memory, uint, uint, uint[] memory, uint[] memory) {
        Deck storage deck = decks[msg.sender];
        uint length = deck.cards.length;

        uint[] memory ids = new uint[](length);
        uint[] memory quantities = new uint[](length);

        for (uint i = 0; i < length; i++) {
            ids[i] = deck.cards[i].id;
            quantities[i] = deck.cards[i].quantity;
        }

        return (deck.faction, deck.title, deck.leader, deck.board, ids, quantities);
    }
}