/**
 *Submitted for verification at Etherscan.io on 2022-11-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract Deck {
    struct Card {
        uint8 suit;
        uint8 number;
    }
    event DeckShuffled(uint48 timestamp);

    mapping(uint8 => mapping(uint8 => uint8)) dealtCards;

    uint8[] cardNumbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13];
    uint8[] cardSuits = [1, 2, 3, 4];
    uint8 numberOfDecks;
    uint16 totalCards;
    uint256 seedsViewed;
    uint256 seed;
    uint256 lastSeedStamp;
    constructor(uint8 _numberOfDecks) {
        numberOfDecks = _numberOfDecks;
        totalCards = uint16(numberOfDecks * cardSuits.length * cardNumbers.length);
    }

    function randomSeed() internal returns (uint256) {
        if (block.timestamp != lastSeedStamp) {
        seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.difficulty +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / (block.timestamp)) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                            (block.timestamp)) +
                        block.number +
                        seedsViewed
                )
            )
        );
        lastSeedStamp = block.timestamp;
        }
        seedsViewed++;
        return (((seed + seedsViewed) - (((seed+seedsViewed) / 1000) * 1000)));
    }

    function randomCardNumber() internal returns (uint8) {
        return uint8((randomSeed() % 13) + 1);
    }

    function randomSuit() internal returns (uint8) {
        return uint8((randomSeed() % 4) + 1);
    }

    function notDealt(uint8 _number, uint8 _suit) internal view returns (bool) {
        return dealtCards[_number][_suit] < numberOfDecks;
    }

    function selectRandomCard() internal returns (Card memory card) {
        card.suit = randomSuit();
        card.number = randomCardNumber();
        return card;
    }

    function nextCard() internal returns (Card memory card) {
        card = selectRandomCard();
        if (!notDealt(card.number, card.suit)) while (!notDealt(card.number, card.suit)) card = selectRandomCard();
        dealtCards[card.number][card.suit]++;
        totalCards--;
    }

    function shuffleDeck() internal {
        for (uint8 i = 0; i < cardNumbers.length; i++) {
            for (uint8 j = 0; j < cardSuits.length; j++) {
                dealtCards[cardNumbers[i]][cardSuits[j]] = 0;
            }
        }
        totalCards = uint16(
            numberOfDecks * cardSuits.length * cardNumbers.length
        );
        emit DeckShuffled(uint48(block.timestamp));
    }
}

contract Deal is Deck {
    constructor(uint8 _numberOfCards) Deck(_numberOfCards) {
        dealer.revealed = true;
    }

    event DealtPlayerCard(
        address player,
        uint8 cardNumber,
        uint8 cardSuit,
        uint8 splitNumber
    );
    event DealtDealerCard(uint8 cardNumber, uint8 cardSuit);
    event DealerRevealedCard(uint8 cardNumber, uint8 cardSuit);
    event DealerBust(uint8 dealerCardsTotal, uint8 dealerCardCount);
    event DealerBlackJack(uint48 timestamp);
    event DealerStand(uint8 dealerCardsTotal, uint8 dealerCardCount);
    event PlayerWin(
        address player,
        uint48 amount,
        uint8 playerCardsTotal,
        uint8 dealerCardsTotal,
        uint8 splitNumber
    );
    event PlayerBust(
        address player,
        uint48 amount,
        uint8 playerCardsTotal,
        uint8 playerCardCount,
        uint8 splitNumber
    );
    event PlayerLost(
        address player,
        uint48 amount,
        uint8 playerCardsTotal,
        uint8 playerCardCount,
        uint8 splitNumber
    );
    event PlayerPush(
        address player,
        uint48 amount,
        uint8 playerCardsTotal,
        uint8 playerCardCount,
        uint8 splitNumber
    );
    event PlayerHit(
        address player,
        uint8 cardNumber,
        uint8 cardSuit,
        uint8 splitNumber
    );
    event PlayerDoubleDown(
        address player,
        uint48 amount,
        uint8 cardNumber,
        uint8 cardSuit
    );
    event PlayerStand(
        address player,
        uint8 playerCardsTotal,
        uint8 playerCardCount
    );
    event PlayerBlackJack(address player);
    event PlayerSplit(
        address player,
        uint8 cardNumber,
        uint8 cardSuit1,
        uint8 cardSuit2,
        uint8 splitNumber
    );
    uint48 public bettingPeriod = 60 * 10;
    uint48 public lastHandTime;
    address public actingPlayer;
    uint48 public playerActionPeriod = 60 * 5;
    uint48 public lastPlayerActionTime;
    uint8 public playersBet;
    mapping(address => Player) public players;
    address[] public playerAddresses;
    Dealer public dealer;
    Card dealerUnrevealed;

    struct PlayerCard {
        Card card;
        uint8 splitNumber;
    }

    struct Player {
        bool atTable;
        uint48 bet;
        PlayerCard[] cards;
        bool doubledDown;
        bool split;
        uint8 highestSplitNumber;
        uint8 splitNumber;
        bool finishedActing;
    }

    struct Dealer {
        Card[] cards;
        bool revealed;
    }

    function joinTable() public {
        require(
            !players[msg.sender].atTable,
            "You are already sitting at the table."
        );
        players[msg.sender].atTable = true;
        playerAddresses.push(msg.sender);
        seedsViewed++;
    }

    function play() public {
        players[msg.sender].bet = 10;
        dealCards();
    }

    function getNextCard() public returns (Card memory card) {
        card = nextCard();
        emit DealtPlayerCard(msg.sender, card.number, card.suit, 0);
    }

    function dealCards() internal {
        if (totalCards - (12 + playerAddresses.length * 12) < 1) shuffleDeck();
        require(
            totalCards - (12 + playerAddresses.length * 12) > 0,
            "Invalid deck size, add more decks."
        );
        delete dealer.cards;
        dealer.revealed = false;
        for (uint8 i = 0; i < uint8(playerAddresses.length); i++) {
            delete players[playerAddresses[i]].cards;
            players[playerAddresses[i]].doubledDown = false;
            players[playerAddresses[i]].split = false;
            players[playerAddresses[i]].highestSplitNumber = 0;
            players[playerAddresses[i]].splitNumber = 0;
            players[playerAddresses[i]].finishedActing = false;
            if (players[playerAddresses[i]].bet > 0) {
                Card memory next = nextCard();
                players[playerAddresses[i]].cards.push(
                    PlayerCard({card: next, splitNumber: 0})
                );
                emit DealtPlayerCard(
                    playerAddresses[i],
                    next.number,
                    next.suit,
                    players[playerAddresses[i]].splitNumber
                );
            }
        }
        dealer.cards.push(nextCard());
        emit DealtDealerCard(dealer.cards[0].number, dealer.cards[0].suit);
        for (uint8 i = 0; i < uint8(playerAddresses.length); i++) {
            if (players[playerAddresses[i]].bet > 0) {
                Card memory next = nextCard();
                players[playerAddresses[i]].cards.push(
                    PlayerCard({card: next, splitNumber: 0})
                );
                emit DealtPlayerCard(
                    playerAddresses[i],
                    next.number,
                    next.suit,
                    players[playerAddresses[i]].splitNumber
                );
                if (
                    (players[playerAddresses[i]].cards[0].card.number == 1 &&
                        players[playerAddresses[i]].cards[1].card.number >=
                        10) ||
                    (players[playerAddresses[i]].cards[0].card.number >= 10 &&
                        players[playerAddresses[i]].cards[1].card.number == 1)
                ) {
                    emit PlayerBlackJack(playerAddresses[i]);
                }
            }
        }
        dealerUnrevealed = nextCard();
        bool dealerBlackjack = (dealer.cards[0].number == 1 &&
            dealerUnrevealed.number >= 10) ||
            (dealer.cards[0].number >= 10 && dealerUnrevealed.number == 1);
        if (dealerBlackjack) {
            dealer.cards.push(dealerUnrevealed);
            dealer.revealed = true;
            emit DealerRevealedCard(
                dealerUnrevealed.number,
                dealerUnrevealed.suit
            );
            emit DealerBlackJack(uint48(block.timestamp));
        }
        for (uint8 i; i < uint8(playerAddresses.length); i++) {
            if (players[playerAddresses[i]].bet > 0) {
                uint8 cardTotal = playerCardsTotal(
                    players[playerAddresses[i]].cards,
                    0
                );
                if (dealerBlackjack) {
                    if (
                        (players[playerAddresses[i]].cards[0].card.number ==
                            1 &&
                            players[playerAddresses[i]].cards[1].card.number >=
                            10) ||
                        (players[playerAddresses[i]].cards[0].card.number >=
                            10 &&
                            players[playerAddresses[i]].cards[1].card.number ==
                            1)
                    ) {
                        emit PlayerPush(
                            playerAddresses[i],
                            players[playerAddresses[i]].bet,
                            cardTotal,
                            uint8(players[playerAddresses[i]].cards.length),
                            players[playerAddresses[i]].splitNumber
                        );
                    } else {
                        emit PlayerLost(
                            playerAddresses[i],
                            players[playerAddresses[i]].bet,
                            cardTotal,
                            uint8(players[playerAddresses[i]].cards.length),
                            players[playerAddresses[i]].splitNumber
                        );
                    }
                    players[playerAddresses[i]].finishedActing = true;
                    players[playerAddresses[i]].bet = 0;
                } else {
                    if (
                        (players[playerAddresses[i]].cards[0].card.number ==
                            1 &&
                            players[playerAddresses[i]].cards[1].card.number >=
                            10) ||
                        (players[playerAddresses[i]].cards[0].card.number >=
                            10 &&
                            players[playerAddresses[i]].cards[1].card.number ==
                            1)
                    ) {
                        emit PlayerBlackJack(playerAddresses[i]);
                        uint48 winnings = (players[playerAddresses[i]].bet *
                            3) / 2;
                        emit PlayerWin(
                            playerAddresses[i],
                            winnings,
                            cardTotal,
                            uint8(players[playerAddresses[i]].cards.length),
                            players[playerAddresses[i]].splitNumber
                        );
                        players[playerAddresses[i]].bet = 0;
                        players[playerAddresses[i]].finishedActing = true;
                    } else if (actingPlayer != address(0)) {
                        actingPlayer = playerAddresses[i];
                        lastPlayerActionTime = uint48(block.timestamp);
                    }
                }
            }
        }
        dealerTurn();
    }

    function cardsTotal(Card[] memory cards)
        internal
        pure
        returns (uint8 cardTotal)
    {
        uint8 aceCount;
        for (uint8 i = 0; i < uint8(cards.length); i++) {
            if (cards[i].number == 1) {
                aceCount++;
            } else {
                cardTotal += cards[i].number < 10 ? cards[i].number : 10;
            }
        }
        if (aceCount > 0) {
            for (uint8 i = aceCount; i >= 0; i--) {
                if (cardTotal + 11 <= 21) {
                    cardTotal += 11;
                } else {
                    cardTotal += 1;
                }
            }
        }
    }

    function playerCardsTotal(PlayerCard[] memory cards, uint8 splitToPlay)
        internal
        pure
        returns (uint8 cardTotal)
    {
        uint8 aceCount;
        for (uint8 i = 0; i < uint8(cards.length); i++) {
            if (cards[i].splitNumber == splitToPlay) {
                if (cards[i].card.number == 1) {
                    aceCount++;
                } else {
                    cardTotal += cards[i].card.number < 10
                        ? cards[i].card.number
                        : 10;
                }
            }
        }
        if (aceCount > 0) {
            for (uint8 i = aceCount; i >= 0; i--) {
                if (cardTotal + 11 <= 21) {
                    cardTotal += 11;
                } else {
                    cardTotal += 1;
                }
            }
        }
    }

    function cardsOfSplit(PlayerCard[] memory cards, uint8 splitToPlay)
        internal
        pure
        returns (uint8 count)
    {
        for (uint256 i = 0; i < cards.length; i++) {
            if (cards[i].splitNumber == splitToPlay) {
                count++;
            }
        }
    }

    function dealerTurn() internal {
        dealer.revealed = true;
        emit DealerRevealedCard(dealerUnrevealed.number, dealerUnrevealed.suit);
        dealer.cards.push(dealerUnrevealed);
        uint8 dealerCardTotal = cardsTotal(dealer.cards);
        if (dealerCardTotal >= 17) {
            emit DealerStand(dealerCardTotal, uint8(dealer.cards.length));
        }
        while (dealerCardTotal < 17) {
            Card memory next = nextCard();
            dealer.cards.push(next);
            dealerCardTotal = cardsTotal(dealer.cards);
        }
        if (dealerCardTotal > 21) {
            emit DealerBust(dealerCardTotal, uint8(dealer.cards.length));
        } else {
            emit DealerStand(dealerCardTotal, uint8(dealer.cards.length));
        }
        address firstPlayer = address(
            playerAddresses[playerAddresses.length - 1]
        );
        for (uint8 i = 0; i < uint8(playerAddresses.length); i++) {
            if (players[playerAddresses[i]].bet > 0) {
                for (
                    uint8 z = 0;
                    z <= players[playerAddresses[i]].splitNumber;
                    z++
                ) {
                    uint8 cardTotal = playerCardsTotal(
                        players[playerAddresses[i]].cards,
                        z
                    );
                    uint8 splitCardCount = cardsOfSplit(
                        players[playerAddresses[i]].cards,
                        z
                    );
                    if (dealerCardTotal > 21) {
                        uint48 winnings = players[playerAddresses[i]].split
                            ? (players[playerAddresses[i]].bet /
                                players[playerAddresses[i]].splitNumber) * 2
                            : players[playerAddresses[i]].bet * 2;
                        emit PlayerWin(
                            playerAddresses[i],
                            winnings,
                            cardTotal,
                            splitCardCount,
                            z
                        );
                    } else {
                        if (cardTotal > dealerCardTotal) {
                            uint48 winnings = players[playerAddresses[i]].split
                                ? (players[playerAddresses[i]].bet /
                                    players[playerAddresses[i]].splitNumber) * 2
                                : players[playerAddresses[i]].bet * 2;
                            emit PlayerWin(
                                playerAddresses[i],
                                winnings,
                                cardTotal,
                                splitCardCount,
                                z
                            );
                        } else if (cardTotal == dealerCardTotal) {
                            emit PlayerPush(
                                playerAddresses[i],
                                players[playerAddresses[i]].bet,
                                cardTotal,
                                splitCardCount,
                                z
                            );
                        } else {
                            emit PlayerLost(
                                playerAddresses[i],
                                players[playerAddresses[i]].bet,
                                cardTotal,
                                splitCardCount,
                                z
                            );
                        }
                    }
                }
                players[playerAddresses[i]].bet = 0;
                if (i == playerAddresses.length - 1) {
                    playerAddresses[i] = firstPlayer;
                } else {
                    playerAddresses[i] = playerAddresses[i + 1];
                }
            }
        }
        lastHandTime = uint48(block.timestamp);
        playersBet = 0;
    }
}