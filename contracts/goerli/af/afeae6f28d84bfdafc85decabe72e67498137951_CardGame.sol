// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.11;

import {IVerifier} from "./IVerifier.sol";

contract CardGame {
    IVerifier public immutable verifierCP;
    IVerifier public immutable verifierCR;

    struct Card {
        uint256 t1Commit; // Hash of trait 1
        uint256 t2Commit; // Hash of trait 2
    }
    mapping(uint256 => Card) cards;
    mapping(address => uint256[]) hand; // For checking cards owned by a player

    event CardPicked(uint256 cardCommit);
    event CardRevealed(uint256 cardCommit, uint256 traitNum, uint256 traitVal);

    /**
        @dev The constructor
        @param _verifierCP the address of SNARK verifier for card pick
        @param _verifierCR the address of SNARK verifier for card reveal
    */
    constructor(IVerifier _verifierCP, IVerifier _verifierCR) public {
        verifierCP = _verifierCP;
        verifierCR = _verifierCR;
    }

    function pickCard(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[3] memory input
    ) public {
        require(
            verifierCP.verifyProof(a, b, c, input),
            "Invalid SNARK proof for card pick."
        );
        require(cards[input[2]].t1Commit == 0, "Card already drawn.");

        cards[input[2]].t1Commit = input[0];
        cards[input[2]].t2Commit = input[1];

        hand[msg.sender].push(input[2]);

        emit CardPicked(input[2]);
    }

    function revealCard(
        uint256 cardCommit,
        uint8 traitNum,
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[2] memory input
    ) public {
        require(
            verifierCR.verifyProof(a, b, c, input),
            "Invalid SNARK proof for card reveal."
        );

        if (traitNum == 1) {
            require(
                cards[cardCommit].t1Commit == input[0],
                "Trait commit does not match with record."
            );
            emit CardRevealed(cardCommit, 1, input[1]);
        } else if (traitNum == 2) {
            require(
                cards[cardCommit].t2Commit == input[0],
                "Trait commit does not match with record."
            );
            emit CardRevealed(cardCommit, 2, input[1]);
        } else {
            revert("Invalid trait number.");
        }
    }
}