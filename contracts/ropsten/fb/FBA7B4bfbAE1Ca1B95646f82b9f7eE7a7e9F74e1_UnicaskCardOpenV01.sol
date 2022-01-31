/**
 *Submitted for verification at Etherscan.io on 2022-01-31
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract UnicaskCardOpenV01 {

    struct PersonCard {
        uint256 gameNo;
        uint8 cardMax;
        uint256 drawTimes;
        mapping(uint8 => bool) cards;
    }

    event ShowCard(address player, uint256 gameNo, uint256 drawTimes, uint8 cardNo);

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
}