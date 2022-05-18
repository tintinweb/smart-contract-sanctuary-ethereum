/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract UnicaskCardOpenV02 {

    struct PersonCard {
        uint256 gameNo; // the number of game
        uint8 cardMax; // draw the number from cardMax. such as 100
        uint256 drawTimes;
        mapping(uint8 => bool) cards;
    }

    event ShowCard(address player, uint256 gameNo, uint256 drawTimes, uint8 cardNo);
    event DropCard(address player, uint256 gameNo, uint256 drawTimes, uint8 cardNo);

    address public _owner;
    mapping(address => PersonCard) public _personCards;

    constructor() {
        _owner = msg.sender;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "caller is not the owner");
        _;
    }

    function newGame(uint8 cardMax) public {
        uint256 gameNoBefore = _personCards[msg.sender].gameNo;
        PersonCard storage cardBefore = _personCards[msg.sender];
        for (uint8 i = 1; i <= cardBefore.cardMax; i++) {
            delete cardBefore.cards[i];
        }
        delete _personCards[msg.sender];
        PersonCard storage card = _personCards[msg.sender];
        card.cardMax = cardMax;
        card.gameNo = gameNoBefore + 1;
    }

    function draw() public {
        PersonCard storage card = _personCards[msg.sender];
        require(card.gameNo > 0, "you must start a new game first");
        require(card.drawTimes < card.cardMax, "you have draw too many times");

        uint8 randomNo = uint8(uint256(keccak256(abi.encodePacked(card.gameNo, card.drawTimes, msg.sender, block.timestamp, block.difficulty, block.coinbase))) % card.cardMax) + 1;
        require(!_personCards[msg.sender].cards[randomNo], "you draw a same card, please draw once time later.");

        card.cards[randomNo] = true;
        card.drawTimes = card.drawTimes + 1;
        emit ShowCard(msg.sender, card.gameNo, card.drawTimes, randomNo);
    }

    function drawNoFail() public {
        PersonCard storage card = _personCards[msg.sender];
        require(card.gameNo > 0, "you must start a new game first");
        require(card.drawTimes < card.cardMax, "you have draw too many times");
        uint8 randomNo = uint8(uint256(keccak256(abi.encodePacked(card.gameNo, card.drawTimes, msg.sender, block.timestamp, block.difficulty, block.coinbase))) % (card.cardMax - card.drawTimes)) + 1;

        for (uint8 i = 1; i <= card.cardMax; i++) {
            if (card.cards[i] == true) {
                randomNo++;
            }
            if (i >= randomNo) {
                break;
            }
        }

        card.cards[randomNo] = true;
        card.drawTimes = card.drawTimes + 1;
        emit ShowCard(msg.sender, card.gameNo, card.drawTimes, randomNo);
    }

    function drawMultiNoFail(uint drawCount) public {
        PersonCard storage card = _personCards[msg.sender];
        require(card.gameNo > 0, "you must start a new game first");
        require(drawCount > 0, "you need to draw at least one number");
        require(card.drawTimes + drawCount <= card.cardMax, "you have draw too many times");

        uint loopIndex = drawCount;

        while (loopIndex > 0) {
            drawNoFail();
            loopIndex = loopIndex - 1;
        }
    }

    function dropNo(uint8 cardNo) public {
        PersonCard storage card = _personCards[msg.sender];
        require(card.gameNo > 0, "you must start a new game first");
        require(cardNo <= card.cardMax, "card no out of limit");

        if (!card.cards[cardNo]) {
            card.cards[cardNo] = true;
            card.drawTimes = card.drawTimes + 1;
            emit DropCard(msg.sender, card.gameNo, card.drawTimes, cardNo);
        }
    }

    function dropNos(uint8[] memory cardNos) public {
        PersonCard storage card = _personCards[msg.sender];
        require(card.gameNo > 0, "you must start a new game first");
        require(cardNos.length > 0, "you must input the cardNo");
        for (uint i = 0; i < cardNos.length; i++) {
            require(cardNos[i] <= card.cardMax, "one of card no out of limit");
        }

        for (uint i = 0; i < cardNos.length; i++) {
            dropNo(cardNos[i]);
        }
    }
}