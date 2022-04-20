/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

// File: contracts/PlayingCards.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;


contract PlayingCards {
    // a playing card
    struct Card {
        uint8 number; // 0 - 12, maps on to numbers array
        uint8 suit; // 0 - 3, maps on to suits array
    }

    // text representation of spades, clubs, hearts, diamonds
    string[] public suits = [
        "c", "d", "h", "s"
    ];

    // text representation of card numbers/characters
    string[] public numbers = [
        "2", "3", "4", "5", "6", "7", "8", "9", "T", "J", "Q", "K", "A"
    ];

    // array of the 52 playable the cards in a deck
    Card[52] public cards;

    /*
     * EVENTS
     */

    event CardsInitialised();

    /*
     * CONSTRUCTOR
     */

    /**
     * @dev constructor initialises the 52 card deck and emits the CardsInitialised event
     */
    constructor()
    {
        uint8 cardIdx = 0;
        for (uint8 i = 0; i < numbers.length; i++) {
            for (uint8 j = 0; j < suits.length; j++) {
                cards[cardIdx] = Card(i, j);
                cardIdx = cardIdx + 1;
            }
        }
        emit CardsInitialised();
    }

    /*
     * PUBLIC GETTERS
     */

    /**
     * @dev getCardNumberAsUint returns the number value for a card as an array idx
     * @dev that can be passed to the numbers[] array or used in calculations
     *
     * @param cardId uint8 ID of the card from 0 - 51
     * @return uint8
     */
    function getCardNumberAsUint(uint8 cardId) public validCardId(cardId) view returns (uint8) {
        return cards[cardId].number;
    }

    /**
     * @dev getCardSuitAsUint returns the suit value for a card as an array idx
     * @dev that can be passed to the suits[] array or used in calculations
     *
     * @param cardId uint8 ID of the card from 0 - 51
     * @return uint8
     */
    function getCardSuitAsUint(uint8 cardId) public validCardId(cardId) view returns (uint8) {
        return cards[cardId].suit;
    }

    /**
     * @dev getCardNumberAsStr returns the string value for a card's number, for example "A" (Ace)
     *
     * @param cardId uint8 ID of the card from 0 - 51
     * @return string
     */
    function getCardNumberAsStr(uint8 cardId) public validCardId(cardId) view returns (string memory) {
        return numbers[cards[cardId].number];
    }

    /**
     * @dev getCardSuitAsStr returns the string value for a card's suit, for example "s" (Spade)
     *
     * @param cardId uint8 ID of the card from 0 - 51
     * @return string
     */
    function getCardSuitAsStr(uint8 cardId) public validCardId(cardId) view returns (string memory) {
        return suits[cards[cardId].suit];
    }

    /**
     * @dev getCardAsString returns the string value for a card, for example "As" (Ace of Spades)
     *
     * @param cardId uint8 ID of the card from 0 - 51
     * @return string
     */
    function getCardAsString(uint8 cardId) public validCardId(cardId) view returns (string memory) {
        return string(abi.encodePacked(numbers[cards[cardId].number], suits[cards[cardId].suit]));
    }

    /**
     * @dev getCardAsComponents returns the number and suit IDs for a card, as stored in numbers and suits arrays
     *
     * @param cardId uint8 ID of the card from 0 - 51
     * @return number uint8 number/figure ID of card (0 - 12)
     * @return suit uint8 suit ID of card (0 - 3)
     */
    function getCardAsComponents(uint8 cardId) public validCardId(cardId) view returns (uint8 number, uint8 suit) {
        return (cards[cardId].number, cards[cardId].suit);
    }

    /**
     * @dev getCardAsSvg returns the SVG XML for a card, which can be rendered as an img src in a UI
     *
     * @param cardId uint8 ID of the card from 0 - 51
     * @return string SVG XML of card
     */
    function getCardAsSvg(uint8 cardId) public validCardId(cardId) view returns (string memory) {
        // based on https://commons.wikimedia.org/wiki/Category:SVG_playing_cards
        string[3] memory parts;
        parts[0] = "<svg xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" viewBox=\"0 0 72 62\" width=\"2.5in\" height=\"2.147in\">";
        parts[1] = getCardBody(cards[cardId].number, cards[cardId].suit, 7, 32, 1);
        parts[2] = "</svg>";
        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2]));
        return output;
    }

    /**
     * @dev getCardBody will generate the internal SVG elements for the given card ID
     *
     * @param numberId uint8 number id as per the numbers array
     * @param suitId uint8 suit id as per the suits array
     * @param fX uint256 x coordinate for the number/figure
     * @param sX uint256 x coordinate for the suit
     * @param rX uint256 x coordinate for the surrounding rectangle
     * @return string SVG elements
     */
    function getCardBody(uint8 numberId, uint8 suitId, uint256 fX, uint256 sX, uint256 rX)
    validSuitId(suitId) validNumberId(numberId)
    public pure returns (string memory) {
        string memory colour = "red";
        if (suitId == 0 || suitId == 3) {
            colour = "#000";
        }

        string[25] memory parts;
        parts[0] = "<symbol id=\"S";
        parts[1] = toString(suitId);
        parts[2] = "\" viewBox=\"-600 -600 1200 1200\">";
        parts[3] = getSuitPath(suitId);
        parts[4] = "</symbol>";
        parts[5] = "<symbol id=\"F";
        parts[6] = toString(numberId);
        parts[7] = "\" viewBox=\"-600 -600 1200 1200\">";
        parts[8] = getNumberPath(numberId);
        parts[9] = "</symbol>";
        parts[10] = "<rect width=\"70\" height=\"60\" x=\"";
        parts[11] = toString(rX);
        parts[12] = "\" y=\"1\" rx=\"6\" ry=\"6\" fill=\"white\" stroke=\"black\"/>";
        parts[13] = "<use xlink:href=\"#F";
        parts[14] = toString(numberId);
        parts[15] = "\" height=\"32\" width=\"32\" x=\"";
        parts[16] = toString(fX);
        parts[17] = "\" y=\"16\" stroke=\"";
        parts[18] = colour;
        parts[19] = "\"/>";
        parts[20] = "<use xlink:href=\"#S";
        parts[21] = toString(suitId);
        parts[22] = "\" height=\"32\" width=\"32\" x=\"";
        parts[23] = toString(sX);
        parts[24] = "\" y=\"16\"/>";

        string memory output = string(
            abi.encodePacked(
                parts[0],
                parts[1],
                parts[2],
                parts[3],
                parts[4],
                parts[5],
                parts[6],
                parts[7],
                parts[8]
            )
        );
        output = string(
            abi.encodePacked(
                output,
                parts[9],
                parts[10],
                parts[11],
                parts[12],
                parts[13],
                parts[14],
                parts[15],
                parts[16]
            )
        );
        output = string(
            abi.encodePacked(
                output,
                parts[17],
                parts[18],
                parts[19],
                parts[20],
                parts[21],
                parts[22],
                parts[23],
                parts[24]
            )
        );

        return output;
    }

    /**
     * @dev getSuitPath will generate the internal SVG path element for the given suit ID
     *
     * @param suitId uint8 suit id as per the suits array
     * @return string SVG path element
     */
    function getSuitPath(uint8 suitId) public validSuitId(suitId) pure returns (string memory) {
        if (suitId == 0) {
            // club
            return "<path d=\"M30 150c5 235 55 250 100 350h-260c45-100 95-115 100-350a10 10 0 0 0-20 0 210 210 0 1 1-74-201 10 10 0 0 0 14-14 230 230 0 1 1 220 0 10 10 0 0 0 14 14 210 210 0 1 1-74 201 10 10 0 0 0-20 0Z\" fill=\"#000\"/>";
        } else if (suitId == 1) {
            // diamond
            return "<path d=\"M-400 0C-350 0 0-450 0-500 0-450 350 0 400 0 350 0 0 450 0 500 0 450-350 0-400 0Z\" fill=\"red\"/>";
        } else if (suitId == 2) {
            // heart
            return "<path d=\"M0-300c0-100 100-200 200-200s200 100 200 250C400 0 0 400 0 500 0 400-400 0-400-250c0-150 100-250 200-250S0-400 0-300Z\" fill=\"red\"/>";
        } else if (suitId == 3) {
            // spade
            return "<path d=\"M0-500c100 250 355 400 355 685a150 150 0 0 1-300 0 10 10 0 0 0-20 0c0 200 50 215 95 315h-260c45-100 95-115 95-315a10 10 0 0 0-20 0 150 150 0 0 1-300 0c0-285 255-435 355-685Z\" fill=\"#000\"/>";
        }
        return "";
    }

    /**
     * @dev getNumberPath will generate the internal SVG path element for the given number ID
     *
     * @param numberId uint8 number id as per the numbers array
     * @return string SVG path element
     */
    function getNumberPath(uint8 numberId) public validNumberId(numberId) pure returns (string memory) {
        string[3] memory parts;
        parts[0] = "<path d=\"";
        if (numberId == 0) {
            // 2
            parts[1] = "M-225-225c-20-40 25-235 225-235s225 135 225 235c0 200-450 385-450 685h450V300";
        } else if (numberId == 1) {
            // 3
            parts[1] = "M-250-320v-140h450L-110-80c10-10 60-40 110-40 200 0 250 120 250 270 0 200-80 310-280 310s-230-160-230-160";
        } else if (numberId == 2) {
            // 4
            parts[1] = "M50 460h200m-100 0v-920l-450 635v25h570";
        } else if (numberId == 3) {
            // 5
            parts[1] = "M170-460h-345l-35 345s10-85 210-85c100 0 255 120 255 320S180 460-20 460s-235-175-235-175";
        } else if (numberId == 4) {
            // 6
            parts[1] = "M-250 100a250 250 0 0 1 500 0v110a250 250 0 0 1-500 0v-420A250 250 0 0 1 0-460c150 0 180 60 200 85";
        } else if (numberId == 5) {
            // 7
            parts[1] = "M-265-320v-140h530C135-200-90 100-90 460";
        } else if (numberId == 6) {
            // 8
            parts[1] = "M-1-50a205 205 0 1 1 2 0h-2a255 255 0 1 0 2 0Z";
        } else if (numberId == 7) {
            // 9
            parts[1] = "M250-100a250 250 0 0 1-500 0v-110a250 250 0 0 1 500 0v420A250 250 0 0 1 0 460c-150 0-180-60-200-85";
        } else if (numberId == 8) {
            // 10
            parts[1] = "M-260 430v-860M-50 0v-310a150 150 0 0 1 300 0v620a150 150 0 0 1-300 0Z";
        } else if (numberId == 9) {
            // jack
            parts[1] = "M50-460h200m-100 0v710a100 100 0 0 1-400 0v-30";
        } else if (numberId == 10) {
            // queen
            parts[1] = "M-260 100c300 0 220 360 520 360M-175 0v-285a175 175 0 0 1 350 0v570a175 175 0 0 1-350 0Z";
        } else if (numberId == 11) {
            // king
            parts[1] = "M-285-460h200m-100 0v920m-100 0h200M85-460h200m-100 20-355 595M85 460h200m-100-20L-10-70";
        } else if (numberId == 12) {
            // ace
            parts[1] = "M-270 460h160m-90-10L0-460l200 910m-90 10h160m-390-330h240";
        }

        parts[2] = "\" stroke-width=\"80\" stroke-linecap=\"square\" stroke-miterlimit=\"1.5\" fill=\"none\"/>";

        string memory output = string(
            abi.encodePacked(parts[0], parts[1], parts[2])
        );
        return output;
    }

    /*
     * PRIVATE FUNCTIONS
     */

    /**
     * @dev toString converts a given uint256 to a string. Primarily used in SVG, JSON, string name,
     * @dev and hash generation
     *
     * @param value uint256 number to convert
     * @return string number as a string
     */
    function toString(uint256 value) private pure returns (string memory) {
        // Inspired by OraclizeAPI"s implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
        uint256 _tmpN = value;
        if (_tmpN == 0) {
            return "0";
        }
        uint256 temp = _tmpN;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (_tmpN != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(_tmpN % 10)));
            _tmpN /= 10;
        }
        return string(buffer);
    }

    /*
     * MODIFIERS
     */

    /**
     * @dev validCardId ensures a given card Id is valid
     *
     * @param cardId uint8 id of card
     */
    modifier validCardId(uint8 cardId) {
        require(cardId >= 0 && cardId < 52, "invalid cardId");
        _;
    }

    /**
     * @dev validSuitId ensures a given suit Id is valid (0 - 3)
     *
     * @param suitId uint8 id of suit
     */
    modifier validSuitId(uint8 suitId) {
        require(suitId >= 0 && suitId < 4, "invalid suitId");
        _;
    }

    /**
     * @dev validNumberId ensures a given number Id is valid (0 - 12)
     *
     * @param numberId uint8 id of suit
     */
    modifier validNumberId(uint8 numberId) {
        require(numberId >= 0 && numberId < 13, "invalid numberId");
        _;
    }

}