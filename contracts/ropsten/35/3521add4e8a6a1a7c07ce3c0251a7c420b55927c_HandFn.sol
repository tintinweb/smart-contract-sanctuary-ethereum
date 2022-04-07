// SPDX-License-Identifier: MIT
// by Hwakyeom Kim(=just-do-halee)
pragma solidity ^0.8.7;

enum Card {
    ROCK,
    PAPER,
    SCISSORS
}

struct Hand {
    Card card;
    uint256 encryptedCard;
}

enum Result {
    WIN,
    LOSE,
    DRAW
}

library HandFn {
    function New(uint256 encrypted) public pure returns (Hand memory) {
        return Hand({
            card: Card.ROCK,
            encryptedCard: encrypted
        });
    }

    function resultToString(Result result) public pure returns (string memory) {
        if (result == Result.WIN) {
            return "win";
        } else if (result == Result.LOSE) {
            return "lose";
        } else if (result == Result.DRAW) {
            return "draw";
        } else {
            return "";
        }
    }

    function reset(Hand storage hand) internal {
        hand.card = Card.ROCK;
        hand.encryptedCard = 0x0;
    }

    function encrypt(Hand memory hand, uint128 password) internal pure returns (uint256) {
        hand.encryptedCard = uint256(keccak256(bytes.concat(bytes16(password), bytes1(uint8(hand.card)))));
        hand.card = Card.ROCK;
        return hand.encryptedCard;
    }

    function isEncrypted(Hand storage hand) internal view returns (bool) {
        return hand.encryptedCard != 0x0;
    }

    function decrypt(Hand storage hand, Card card, uint128 password) internal view returns (bool) {
        return keccak256(bytes.concat(bytes16(password), bytes1(uint8(card)))) == bytes32(hand.encryptedCard);
    }

    function isWinning(Hand storage hand, Card enemy) internal view returns (Result) {
        uint8 myCard = uint8(hand.card);
        uint8 enemyCard = uint8(enemy);

        if (myCard == enemyCard) {

            return Result.DRAW;

        } else if ((enemyCard + 1) % 3 == myCard) {

            return Result.WIN;

        } else if ((myCard + 1) % 3 == enemyCard) {

            return Result.LOSE;

        } else {
            
            revert("ERROR.");
            
        }
    } 

    function toString(Hand storage hand) internal view returns (string memory) {
        if (isEncrypted(hand)) return "encrypted";

        Card card = hand.card;

        if (card == Card.ROCK) {
            return "rock";
        } else if (card == Card.PAPER) {
            return "paper";
        } else if (card == Card.SCISSORS) {
            return "scissors";
        } else {
            return "";
        }
    }
}