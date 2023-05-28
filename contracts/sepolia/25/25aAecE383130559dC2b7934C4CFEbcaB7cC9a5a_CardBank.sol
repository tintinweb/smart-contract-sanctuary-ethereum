/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract CardBank {
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

    mapping(address => mapping(string => Deck)) public decks;
    mapping(address => string[]) public factions;

    function setDeck(string memory faction, string memory title, uint leader, uint board, uint[] memory ids, uint[] memory quantities) public {
        require(ids.length == quantities.length, "ids and quantities array lengths must match");

        Deck storage deck = decks[msg.sender][faction];
        require(bytes(deck.faction).length == 0, "Deck for this faction already exists");

        deck.faction = faction;
        deck.title = title;
        deck.leader = leader;
        deck.board = board;

        for (uint i = 0; i < ids.length; i++) {
            deck.cards.push(Card(ids[i], quantities[i]));
        }

        factions[msg.sender].push(faction);
    }

    function updateDeckCards(string memory faction, uint[] memory ids, uint[] memory quantities) public {
        require(ids.length == quantities.length, "ids and quantities array lengths must match");

        Deck storage deck = decks[msg.sender][faction];
        require(bytes(deck.faction).length > 0, "No deck for this faction exists");

        delete deck.cards;

        for (uint i = 0; i < ids.length; i++) {
            deck.cards.push(Card(ids[i], quantities[i]));
        }
    }

    function getFactions() public view returns (string[] memory) {
        return factions[msg.sender];
    }

    function getDeck(string memory faction) public view returns (string memory, string memory, uint, uint, uint[] memory, uint[] memory) {
        Deck storage deck = decks[msg.sender][faction];
        require(bytes(deck.faction).length > 0, "No deck for this faction exists");

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