/**
 *Submitted for verification at Etherscan.io on 2023-06-03
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
        Card[] bank;
    }

    mapping(address => mapping(string => Deck)) public decks;
    mapping(address => string[]) public factions;

    function setDeck(
        string memory faction,
        string memory title,
        uint leader,
        uint board,
        uint[] memory deckCardIds,
        uint[] memory deckCardQuantities,
        uint[] memory bankCardIds,
        uint[] memory bankCardQuantities
    ) public {
        require(deckCardIds.length == deckCardQuantities.length, "Deck card ids and quantities array lengths must match");
        require(bankCardIds.length == bankCardQuantities.length, "Bank card ids and quantities array lengths must match");

        Deck storage deck = decks[msg.sender][faction];
        require(bytes(deck.faction).length == 0, "Deck for this faction already exists");

        deck.faction = faction;
        deck.title = title;
        deck.leader = leader;
        deck.board = board;

        for (uint i = 0; i < deckCardIds.length; i++) {
            deck.cards.push(Card(deckCardIds[i], deckCardQuantities[i]));
        }

        for (uint i = 0; i < bankCardIds.length; i++) {
            deck.bank.push(Card(bankCardIds[i], bankCardQuantities[i]));
        }

        factions[msg.sender].push(faction);
    }

    function updateDeckAndBankCards(
        string memory faction,
        uint[] memory deckCardIds,
        uint[] memory deckCardQuantities,
        uint[] memory bankCardIds,
        uint[] memory bankCardQuantities
    ) public {
        require(deckCardIds.length == deckCardQuantities.length, "Deck card ids and quantities array lengths must match");
        require(bankCardIds.length == bankCardQuantities.length, "Bank card ids and quantities array lengths must match");

        Deck storage deck = decks[msg.sender][faction];
        require(bytes(deck.faction).length > 0, "No deck for this faction exists");

        delete deck.cards;
        delete deck.bank;

        for (uint i = 0; i < deckCardIds.length; i++) {
            deck.cards.push(Card(deckCardIds[i], deckCardQuantities[i]));
        }

        for (uint i = 0; i < bankCardIds.length; i++) {
            deck.bank.push(Card(bankCardIds[i], bankCardQuantities[i]));
        }
    }

    function getFactions() public view returns (string[] memory) {
        return factions[msg.sender];
    }

    function getDeck(string memory faction) public view returns (string memory, string memory, uint, uint, uint[] memory, uint[] memory, uint[] memory, uint[] memory) {
        Deck storage deck = decks[msg.sender][faction];
        require(bytes(deck.faction).length > 0, "No deck for this faction exists");

        uint deckLength = deck.cards.length;
        uint bankLength = deck.bank.length;
        uint[] memory deckCardIds = new uint[](deckLength);
        uint[] memory deckCardQuantities = new uint[](deckLength);
        uint[] memory bankCardIds = new uint[](bankLength);
        uint[] memory bankCardQuantities = new uint[](bankLength);

        for (uint i = 0; i < deckLength; i++) {
            deckCardIds[i] = deck.cards[i].id;
            deckCardQuantities[i] = deck.cards[i].quantity;
        }

        for (uint i = 0; i < bankLength; i++) {
            bankCardIds[i] = deck.bank[i].id;
            bankCardQuantities[i] = deck.bank[i].quantity;
        }

        return (
            deck.faction,
            deck.title,
            deck.leader,
            deck.board,
            deckCardIds,
            deckCardQuantities,
            bankCardIds,
            bankCardQuantities
        );
    }
}