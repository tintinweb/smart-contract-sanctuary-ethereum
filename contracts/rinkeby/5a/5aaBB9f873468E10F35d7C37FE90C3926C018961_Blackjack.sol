// SPDX-License-Identifier: GPL v3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./CasinoGame.sol";

struct BlackjackHand {
    bool isBust;
    bool isBlackjack;
    bool isDoubledDown;
    bool fromSplit; // If fromSplit is true, don't allow fur further splitting if double Aces
    uint256 bet;
    string[] cVals;
    string[] cSuits;
}

struct BlackjackPlayer {
    mapping (uint => BlackjackHand) hands;
    uint numHands;
}

struct BlackjackGame {
    BlackjackPlayer player;
    BlackjackPlayer dealer;
}

/* The Blackjack contract defines specific state variables
*  and functions for a user to play Blackjack at the Casino.
*/
contract Blackjack is Ownable, CasinoGame {

    // State variables
    mapping (address => BlackjackGame) private bjGames;
    string[13] private cardValues = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"];
    string[4] private cardSuits = ["Diamonds", "Clubs", "Hearts", "Spades"];
    uint8 private numDecks;
    uint256 private nonce = 0;

    // Events (to be emitted)
    event NewRound(address player, uint256 initialBet);
    event PlayerCardsUpdated(address player, BlackjackHand hand1, BlackjackHand hand2, BlackjackHand hand3, BlackjackHand hand4, uint numHands);
    event DealerCardsUpdated(address player, BlackjackHand hand);
    event PlayerBetUpdated(address player, uint256 newBet);
    event PlayerTurnEnd(address player);
    event PlayerBlackjack(address player);
    event DealerBlackjack(address player);
    event RoundResult(address player, uint256 payout);

    // Constructor for initial state values, including calling parent constructor
    constructor(uint256 _minBet, uint256 _maxBet, uint8 _numDecks) CasinoGame(_minBet, _maxBet) {
        numDecks = _numDecks;
    }

    // Updates the value of numDecks, the number of decks to play with
    function setNumDecks(uint8 _decks) public onlyOwner {
        require(_decks > 0, "At least one deck required.");
        numDecks = _decks;
    }

    // Getters
    function getNumDecks() public view returns (uint8) {return numDecks;}

    // Handles the initial start of a blackjack round. First pays the initial bet
    // to the contract, then sets the state of the round in progress to true.
    // Finishes by calling the deal() function to begin the game.
    function playRound(uint256 _betAmount) external {
        // Only start the round if player is not in the middle of a game or an existing round.
        // Check that the paid bet is large enough.
        require(roundInProgress[msg.sender] == false, "Already playing game.");
        require(_betAmount >= minimumBet, "Bet is too small.");
        require(_betAmount <= maximumBet, "Bet is too large.");

        // Place the user's initial bet using a CasinoGame parent function
        payContract(msg.sender, _betAmount);

        //  Initialize new game round
        setRoundInProgress(msg.sender, true);

        // Let front end know a new round has begun
        emit NewRound(msg.sender, _betAmount);

        // Handle initial dealing of cards
        deal(msg.sender, _betAmount);
    }

    // ******* FOR TESTING PURPOSES *****
    function getHand(address _player) public view returns (string[] memory, string[] memory) {
        return (bjGames[_player].player.hands[0].cVals, bjGames[_player].player.hands[0].cSuits);
    }
    function getDealerHand(address _player) public view returns (string[] memory, string[] memory) {
        return (bjGames[_player].dealer.hands[0].cVals, bjGames[_player].dealer.hands[0].cSuits);
    }
    function getHighestHandVal(address _player) public view returns (uint16) {
        return getHighestHandValue(bjGames[_player].player.hands[0]);
    }

    // Emits the current hands for the round
    function emitRoundHands(address _player) external {
        emit PlayerCardsUpdated(_player, bjGames[_player].player.hands[0], bjGames[_player].player.hands[1],
            bjGames[_player].player.hands[2], bjGames[_player].player.hands[3], bjGames[_player].player.numHands);
        emit DealerCardsUpdated(_player, bjGames[_player].dealer.hands[0]);
    }

    // Handles the end of a blackjack round. It sets the roundInProgress
    // attributes to false. Then, it resets the BlackjackGame attributes.
    function endRound(address _playerAddress) public {
        require(roundInProgress[_playerAddress] == true, "Not playing round.");

        // Handle any payouts from the round based on player.totalbet
        BlackjackGame storage game = bjGames[_playerAddress];
        uint256 totalPayout = 0;

        /* Non-split win rules:
            - if player has natural blackjack, they win an amount equivalent to 1.5*initial bet + initial bet back
            - if player has blackjack or higher hand without busting, they win an amount equivalent to initial bet + initial bet back
            - if player has same hand as dealer, they win their initial bet back (push)
            - if player doubled down and wins, they win an amount equivalent to double their doubled bet + doubled bet back
        */
        /* Split win rules:
            - if player wins (blackjack or higher hand without busting) both hands, they win an amount equivalent to their doubled bet + doubled bet back (1:1 payout)
            - if player wins only one hand, they win an amount equivalent to half their doubled bet + half their doubled bet back (1:1 payout)
            - natural blackjacks only pay out 1:1 instead of 3:2
            - doubling down is still allowed on each separate hand
        */

        for(uint i = 0; i < game.player.numHands; i++) {
            BlackjackHand memory hand = game.player.hands[i];

            if(!hand.isBust) {
                uint16 playerHandVal = getHighestHandValue(hand);
                if(hand.isBlackjack) {
                    if(game.dealer.hands[0].isBlackjack) {
                        // If both player and dealer have blackjack, then push
                        totalPayout += hand.bet;
                    } else {
                        // If hand is not from a split, natural blackjack pays 3:2, otherwise pays 1:1
                        if(!hand.fromSplit) {
                            totalPayout += (hand.bet * 3) / 2;
                        } else {
                            totalPayout += hand.bet * 2;
                        }
                    }
                } else if(!game.dealer.hands[0].isBust) {
                    uint16 dealerHandVal = getHighestHandValue(game.dealer.hands[0]);
                    if(playerHandVal > dealerHandVal) {
                        // If the player has a higher hand, payout is 1:1
                        totalPayout += hand.bet * 2;
                    } else if (playerHandVal == dealerHandVal) {
                        // Push pays back original bet
                        totalPayout += hand.bet;
                    }
                } else {
                    // Hand still in when dealer busts pays 1:1
                    totalPayout += hand.bet * 2;
                }
            }
        }

        rewardUser(_playerAddress, totalPayout);
        emit RoundResult(_playerAddress, totalPayout);

        setRoundInProgress(_playerAddress, false);
        resetBJGame(_playerAddress);
    }

    // Handles the first deal of cards to player and dealer.
    function deal(address _playerAddress, uint256 _bet) private {
        require(roundInProgress[_playerAddress] == true, "Not playing round.");
        BlackjackGame storage game = bjGames[_playerAddress];

        // Initialize starting hand and deal first set of cards.
        string[] memory pVals;
        string[] memory pSuits; 
        string[] memory dVals; 
        string[] memory dSuits;
        BlackjackHand memory playerHand = BlackjackHand(false, false, false, false, _bet, pVals, pSuits);
        BlackjackHand memory dealerHand = BlackjackHand(false, false, false, false, 0, dVals, dSuits);
        game.player.hands[game.player.numHands++] = playerHand;
        game.dealer.hands[game.dealer.numHands++] = dealerHand;
        dealSingleCard(game, game.player.hands[0]);
        dealSingleCard(game, game.dealer.hands[0]);
        dealSingleCard(game, game.player.hands[0]);
        dealSingleCard(game, game.dealer.hands[0]);

        // Let front end know the player and dealer hands
        emit PlayerCardsUpdated(_playerAddress, game.player.hands[0], game.player.hands[1], game.player.hands[2], game.player.hands[3], game.player.numHands);
        emit DealerCardsUpdated(_playerAddress, game.dealer.hands[0]);

        // Check if player has natural blackjack
        if(hasBlackjack(game.player.hands[0])) {
            game.player.hands[0].isBlackjack = true;
            emit PlayerBlackjack(_playerAddress);
        } else if (hasBlackjack(game.dealer.hands[0])) {
            game.dealer.hands[0].isBlackjack = true; // Only a single player, so no need for dealer to continue playing after this
            emit DealerBlackjack(_playerAddress);
        }
    }

    function doublePlayerBet(address _address, BlackjackGame storage _game, uint8 _handInd) private {
        // Double the user's bet using a CasinoGame parent function
        payContract(_address, _game.player.hands[_handInd].bet);
        _game.player.hands[_handInd].bet = _game.player.hands[_handInd].bet * 2;

        emit PlayerBetUpdated(_address, getTotalBet(_game.player));
    }

    // Handles splitting cards from a player's hand.
    function splitPlayerHand(uint8 _handInd) public {
        require(roundInProgress[msg.sender] == true, "Not playing round.");

        BlackjackGame storage game = bjGames[msg.sender];
        require(game.player.hands[_handInd].cVals.length == 2, "Invalid number of cards.");
        require(!game.player.hands[_handInd].isBust, "Already lost round.");
        require(!game.player.hands[_handInd].isBlackjack, "Already won round.");
        require(!game.player.hands[_handInd].isDoubledDown, "Already doubled down.");
        require(game.player.numHands < 4, "Max number of splits reached.");

        // Have player pay double the current hand's bet
        doublePlayerBet(msg.sender, game, _handInd);

        // Handle splitting logic
        // Create new BlackjackHand to store second value
        string[] memory pVals2;
        string[] memory pSuits2; 

        // Add new values and hand to hands array
        BlackjackHand storage newHand2 = game.player.hands[game.player.numHands++];
        newHand2.fromSplit = true;
        newHand2.bet = game.player.hands[_handInd].bet/2;
        newHand2.cVals = pVals2;
        newHand2.cSuits = pSuits2;

        // game.player.hands.push(newHand2);
        game.player.hands[_handInd+1].cVals.push(game.player.hands[_handInd].cVals[1]);
        game.player.hands[_handInd+1].cSuits.push(game.player.hands[_handInd].cSuits[1]);

        // Adjust existing array to act as first split hand
        delete game.player.hands[_handInd].cVals[1];
        delete game.player.hands[_handInd].cSuits[1];
        game.player.hands[_handInd].fromSplit = true;
        game.player.hands[_handInd].bet = game.player.hands[_handInd].bet/2;

        // Finally, deal cards to these new hands
        dealSingleCard(game, game.player.hands[_handInd]);
        dealSingleCard(game, game.player.hands[_handInd+1]);

        emit PlayerCardsUpdated(msg.sender, bjGames[msg.sender].player.hands[0], bjGames[msg.sender].player.hands[1],
            bjGames[msg.sender].player.hands[2], bjGames[msg.sender].player.hands[3], bjGames[msg.sender].player.numHands);
    }

    // Handles doubling down on a player's hand.
    // function doubleDown(BlackjackHand memory _hand, uint8 handInd) public {
    function doubleDown(uint8 handInd) public {
        require(roundInProgress[msg.sender] == true, "Not playing round.");

        BlackjackGame storage game = bjGames[msg.sender];
        BlackjackHand memory hand = game.player.hands[handInd];
        require(hand.cVals.length == 2, "Invalid number of cards.");
        require(getLowestHandValue(hand) <= 11, "Hand is too high.");
        require(!hand.isBust, "Already lost round.");
        require(!hand.isBlackjack, "Already won round.");
        require(!hand.isDoubledDown, "Already doubled down.");

        // Double the user's bet using a CasinoGame parent function
        doublePlayerBet(msg.sender, game, handInd);

        // Hit a single time, then end the player's turn
        hitPlayerAuto(msg.sender, handInd);
        emit PlayerCardsUpdated(msg.sender, bjGames[msg.sender].player.hands[0], bjGames[msg.sender].player.hands[1],
            bjGames[msg.sender].player.hands[2], bjGames[msg.sender].player.hands[3], bjGames[msg.sender].player.numHands);
        endPlayerTurn(msg.sender);
    }

    function hitPlayerAuto(address _playerAddress, uint8 handInd) private {
        require(roundInProgress[_playerAddress] == true, "Not playing round.");
        
        BlackjackGame storage game = bjGames[_playerAddress];
        require(game.player.hands[handInd].cVals.length >= 2, "Not yet dealt cards.");
        require(!game.player.hands[handInd].isBust, "Already lost round.");
        require(!game.player.hands[handInd].isBlackjack, "Already won round.");
        require(!game.player.hands[handInd].isDoubledDown, "Already doubled down.");

        dealSingleCard(game, game.player.hands[handInd]);
        emit PlayerCardsUpdated(_playerAddress, bjGames[_playerAddress].player.hands[0], bjGames[_playerAddress].player.hands[1],
            bjGames[_playerAddress].player.hands[2], bjGames[_playerAddress].player.hands[3], bjGames[_playerAddress].player.numHands);

        // Check if player has gone over 21
        uint32 handVal = getLowestHandValue(game.player.hands[handInd]);
        if(handVal  > 21)
           game.player.hands[handInd].isBust = true;
        endPlayerTurn(msg.sender);
    }

    // Handles dealing another card to the player.
    function hitPlayer(uint8 handInd) public {
        require(roundInProgress[msg.sender] == true, "Not playing round.");
        
        BlackjackGame storage game = bjGames[msg.sender];
        require(game.player.hands[handInd].cVals.length >= 2, "Not yet dealt cards.");
        require(!game.player.hands[handInd].isBust, "Already lost round.");
        require(!game.player.hands[handInd].isBlackjack, "Already won round.");
        require(!game.player.hands[handInd].isDoubledDown, "Already doubled down.");

        dealSingleCard(game, game.player.hands[handInd]);
        emit PlayerCardsUpdated(msg.sender, bjGames[msg.sender].player.hands[0], bjGames[msg.sender].player.hands[1],
            bjGames[msg.sender].player.hands[2], bjGames[msg.sender].player.hands[3],  bjGames[msg.sender].player.numHands);

        // Check if player has gone over 21
        uint32 handVal = getLowestHandValue(game.player.hands[handInd]);
        if(handVal  > 21) {
            game.player.hands[handInd].isBust = true;
            endPlayerTurn(msg.sender);
        }
    }

    function standPlayer() public {
        require(roundInProgress[msg.sender] == true, "Not playing round.");
        endPlayerTurn(msg.sender);
    }

    // Handles finishing a player's turn.
    function endPlayerTurn(address _playerAddress) public {
        require(roundInProgress[_playerAddress] == true, "Not playing round.");

        BlackjackGame storage game = bjGames[_playerAddress];
        require(game.player.numHands > 0 && game.player.hands[0].cVals.length >= 2, "Not yet dealt cards.");

        emit PlayerTurnEnd(_playerAddress);
        
        // Begin dealer's turn
        dealerPlay(_playerAddress);
    }

    // Handles logic for the dealer's turn
    function dealerPlay(address _playerAddress) private {
        require(roundInProgress[_playerAddress] == true, "Not playing round.");
        BlackjackGame storage game = bjGames[_playerAddress];

        // Dealer hits on soft 17
        // Dealer stands on 17 or above
        while(!game.dealer.hands[0].isBust && !game.dealer.hands[0].isBlackjack && getLowestHandValue(game.dealer.hands[0]) < 17) {
            hitDealer(_playerAddress, game);
            // Check if dealer has gone over 21 or has hit 21
            uint32 handVal = getLowestHandValue(game.dealer.hands[0]);
            if(handVal  > 21) {
                game.dealer.hands[0].isBust = true;
            } else if(handVal >= 17) {
                break;
            }
        }

        // Dealer's turn is complete, and so is the game
        endRound(_playerAddress);
    }

    // Handles dealing another card to the dealer.
    function hitDealer(address _playerAddress, BlackjackGame storage game) private {
        dealSingleCard(game, game.dealer.hands[0]);
        emit DealerCardsUpdated(_playerAddress, bjGames[_playerAddress].dealer.hands[0]);
    }

    // Handles selecting and dealing a single card to the specified player.
    function dealSingleCard(BlackjackGame storage _game, BlackjackHand storage _hand) private {
        require(roundInProgress[msg.sender] == true, "Not playing round.");

        bool validCard = false;
        uint tries = 0;
        string memory cv;
        string memory cs;

        while(!validCard) {
            // Select random card value from deck
            cv = cardValues[rand(cardValues.length)];
            // Select random suit from deck
            cs = cardSuits[rand(cardSuits.length)];
            // Verify card selection is valid
            validCard = cardLeftInDeck(_game, cv, cs);

            // With a single player, all cards in the deck should never be dealt.
            // However, just in case, break out of the loop if all cards have been dealt.
            tries++;
            require(tries <= numDecks*52, "No cards left to deal.");
        }

        // Update value and suit, then add to specified hand
        _hand.cVals.push(cv);
        _hand.cSuits.push(cs);

        require(_hand.cVals.length == _hand.cSuits.length, "Error dealing card.");
    }

    // Resets a BlackjackGame and all the internal attributes.
    // Currently not sure if we need to delete the arrays in the structs, and/or the hands array
    //  before deleting bjGames[_playerAddress] to avoid memory leaks?
    function resetBJGame(address _playerAddress) private {
        BlackjackGame storage game = bjGames[_playerAddress];
        // Reset player attributes
        for(uint i = 0; i < game.player.numHands; i++) {
            delete game.player.hands[i].cVals;
            delete game.player.hands[i].cSuits;
            delete game.player.hands[i];
        }

        // Reset dealer attributes
        for(uint i = 0; i < game.dealer.numHands; i++) {
            delete game.dealer.hands[i].cVals;
            delete game.dealer.hands[i].cSuits;
            delete game.dealer.hands[i];
        }

        // Delete game entry in mapping
        delete bjGames[_playerAddress];
    }

    // Returns true if the hand has a natural blackjack, otherwise false.
    function hasBlackjack(BlackjackHand memory _hand) private pure returns (bool) {
        require(_hand.cVals.length == 2, "Incorrect amount of cards.");
        bool hasAce = false;
        bool hasFace = false;
        for (uint i = 0; i < _hand.cVals.length; i++) {
            uint16 cardVal = getCardValue(_hand.cVals[i]);
            if(cardVal == 10)
                hasFace = true;
            else if(cardVal == 0)
                hasAce = true;
        }

        return hasAce && hasFace;
    }

    // Returns the total sum of a player's bets.
    function getTotalBet(BlackjackPlayer storage _player) private view returns (uint256) {
        uint256 total = 0;
        for(uint i = 0; i < _player.numHands; i++) {
            total += _player.hands[i].bet;
        }
        return total;
    }

    // Returns the lowest numerical value of a player's hand. Always assumes Ace is 1.
    function getLowestHandValue(BlackjackHand memory _hand) private pure returns (uint32) {
        uint32 totalVal = 0;
        for (uint i = 0; i < _hand.cVals.length; i++) {
            uint16 cardVal = getCardValue(_hand.cVals[i]);
            if(cardVal == 0)
                totalVal += 1;
            else
                totalVal += cardVal;
        }

        return totalVal;
    }
    
    // Returns the highest numerical value of a hand, trying to avoid going over 21.
    function getHighestHandValue(BlackjackHand memory _hand) private pure returns (uint16) {
        uint16 totalVal = 0;
        uint8 numAces = 0;
        // First count non-Aces, keeping track of number of aces.
        for(uint i = 0; i < _hand.cVals.length; i++) {
            uint16 cardVal = getCardValue(_hand.cVals[i]);
            if(cardVal == 0) {
                numAces++;
            } else
                totalVal += cardVal;
        }
        // For Aces, first assume each Ace is 1.
        totalVal += (1 * numAces);
        // Attempt to add another 10 for each Ace, to give each a total of 11 for each, without going over 21.
        for(uint i = 0; i < numAces; i++) {
            if(totalVal + 10 <= 21)
                totalVal += 10;
            else
                break;
        }
        return totalVal;
    }

    // Returns the integer value of a card. Returns 0 for Ace. Returns type(uint16).max if 
    // _card is uninitialized.
    function getCardValue(string memory _value) public pure returns (uint16) {
        if(bytes(_value).length > 0) {
            if(isAlphaUpper(_value)) {
                if(keccak256(abi.encodePacked((_value))) == keccak256(abi.encodePacked(("A"))))
                    return 0;
                else
                    return 10;
            } else
                return uint16(safeParseInt(_value));
        }
        return type(uint16).max;
    }

    // Checks if a card has not yet been dealt in the provided game. Returns true if it has
    // not yet been dealt, otherwise false.
    function cardLeftInDeck(BlackjackGame storage _game, string memory _cardVal, string memory _cardSuit) private view returns (bool) {
        uint8 occurrences = 0;
        // Check player cards
        for (uint i = 0; i < _game.player.numHands; i++) {
            for (uint j = 0; j < _game.player.hands[i].cVals.length; j++) {
                if(keccak256(abi.encodePacked((_game.player.hands[i].cVals[j]))) == keccak256(abi.encodePacked((_cardVal))) && 
                    keccak256(abi.encodePacked((_game.player.hands[i].cSuits[j]))) == keccak256(abi.encodePacked((_cardSuit))))
                    occurrences++;  
            }
        }
        // Check dealer cards
        for (uint i = 0; i < _game.dealer.numHands; i++) {
            for (uint j = 0; j < _game.dealer.hands[i].cVals.length; j++) {
                if(keccak256(abi.encodePacked((_game.dealer.hands[i].cVals[j]))) == keccak256(abi.encodePacked((_cardVal))) && 
                    keccak256(abi.encodePacked((_game.dealer.hands[i].cSuits[j]))) == keccak256(abi.encodePacked((_cardSuit))))
                    occurrences++;  
            }
        }

        return occurrences < numDecks;
    }

    // Returns true if a string contains only uppercase alphabetic characters
    function isAlphaUpper(string memory _str) public pure returns (bool) {
        bytes memory b = bytes(_str);

        for(uint i; i< b .length; i++){
            bytes1 char = b[i];

            if(!(char >= 0x41 && char <= 0x5A))
                return false;
        }
        return true;
    }

    // Generates a random number, 0 to _upper (non-inclusive), to be used for card selection.
    // Not truly random, but good enough for the needs of this project.
    // A mainnet application should use something like Chainlink VRF for this task instead.
    function rand(uint256 _upper) public returns(uint256) {
    uint256 seed = uint256(keccak256(abi.encodePacked(
        block.timestamp + block.difficulty +
        ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
        block.gaslimit + 
        ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
        block.number + nonce
    )));

    nonce++;

    return (seed - ((seed / _upper) * _upper));
}

    /*
    Copyright (c) 2015-2016 Oraclize SRL
    Copyright (c) 2016-2019 Oraclize LTD
    Copyright (c) 2019-2020 Provable Things Limited
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
    */
    function safeParseInt(string memory _a) internal pure returns (uint _parsedInt) {
        return safeParseInt(_a, 0);
    }

    function safeParseInt(string memory _a, uint _b) internal pure returns (uint _parsedInt) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i = 0; i < bresult.length; i++) {
            if ((uint(uint8(bresult[i])) >= 48) && (uint(uint8(bresult[i])) <= 57)) {
                if (decimals) {
                   if (_b == 0) break;
                    else _b--;
                }
                mint *= 10;
                mint += uint(uint8(bresult[i])) - 48;
            } else if (uint(uint8(bresult[i])) == 46) {
                require(!decimals, "More than one decimal found!");
                decimals = true;
            } else {
                revert("Non-numeral character found!");
            }
        }
        if (_b > 0) {
            mint *= 10 ** _b;
        }
        return mint;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: GPL v3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

interface CasinoInterface {
    function payWinnings(address _to, uint256 _amount) external;
    function transferFrom(address _from, uint256 _amount) external;
}

interface ChipInterface {
    function balanceOf(address account) external view returns (uint256);
    function casinoTransferFrom(address _from, address _to, uint256 _value) external;
}

/* The CasinoGame contract defines top-level state variables
*  and functions that all casino games must have. More game-specific
*  variables and functions will be defined in subclasses that inherit it.
*/
abstract contract CasinoGame is Ownable {

    // State variables
    CasinoInterface private casinoContract;
    ChipInterface private chipContract;
    uint256 internal minimumBet;
    uint256 internal maximumBet;
    mapping (address => bool) internal roundInProgress;
    
    // Events (to be emitted)
    event ContractPaid(address player, uint256 amount);
    event RewardPaid(address player, uint256 amount);

    // Constructor for initial state values
    constructor(uint256 _minBet, uint256 _maxBet) {
        minimumBet = _minBet;
        maximumBet = _maxBet;
    }

    // Sets the address of the Casino contract.
    function setCasinoContractAddress(address _address) external onlyOwner {
        casinoContract = CasinoInterface(_address);
    }

    // Sets the address of the Chip contract.
    function setChipContractAddress(address _address) external onlyOwner {
        chipContract = ChipInterface(_address);
    }


    // Sets the minimum bet required for all casino games.
    function setMinimumBet(uint256 _bet) external onlyOwner {
        require(_bet >= 0, "Bet is too low.");
        minimumBet = _bet;
    }
    
    // Sets the maximum bet allowed for all casino games.
    function setMaximumBet(uint256 _bet) external onlyOwner {
        require(_bet >= 0, "Bet is too high.");
        maximumBet = _bet;
    }

     // Sets the value of roundInProgress to true or false for a player.
    function setRoundInProgress(address _address, bool _isPlaying) internal {
        roundInProgress[_address] = _isPlaying;
    }

    // Getters
    function getCasinoContractAddress() public view returns (address) {return address(casinoContract);}
    function getChipContractAddress() public view returns (address) {return address(chipContract);}
    function getMinimumBet() public view returns (uint256) {return minimumBet;}
    function getMaximumBet() public view returns (uint256) {return maximumBet;}
    function getRoundInProgress(address _address) public view returns (bool) {return roundInProgress[_address];}

    // Rewards the user for the specified amount if they have won
    // anything from a casino game. Uses the Casino contract's payWinnings
    // function to achieve this.
    function rewardUser(address _user, uint256 _amount) internal {
        require(_amount >= 0, "Not enough to withdraw.");
        casinoContract.payWinnings(_user, _amount);
        emit RewardPaid(_user, _amount);
    }

    // Allows a user to place a bet by paying the contract the specified amount.
    function payContract(address _address, uint256 _amount) internal {
        require(chipContract.balanceOf(_address) >= _amount, "Not enough tokens.");
        casinoContract.transferFrom(_address, _amount);
        emit ContractPaid(_address, _amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}