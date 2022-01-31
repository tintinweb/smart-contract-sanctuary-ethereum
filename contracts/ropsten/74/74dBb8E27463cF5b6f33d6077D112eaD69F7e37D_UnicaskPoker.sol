/**
 *Submitted for verification at Etherscan.io on 2022-01-30
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract UnicaskPoker {

    struct PersonCard {
        uint256 gameNo;
        uint8 drawTimes;
        mapping(uint8 => bool) cards;
    }

    event ShowCard(address player, uint8 drawTimes, uint8 cardNo);

    uint256 public _gameNo = 1;
    uint256 public _drawCount = 5;
    uint256 public _usedBlockNo;
    address public _owner;
    mapping(address => PersonCard) public _personCards;

    constructor() {
        _usedBlockNo = block.number;
        _owner = msg.sender;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function isNewBlockNoNotUsed() public view returns (bool) {
        return block.number > _usedBlockNo;
    }


    modifier onlyOwner() {
        require(isOwner(), "caller is not the owner");
        _;
    }

    modifier blockNoNotUsed() {
        require(isNewBlockNoNotUsed(), "please wait to a new block");
        _;
    }

    function newGame() public onlyOwner {
        _gameNo = _gameNo + 1;
        _usedBlockNo = block.number;
    }

    function newGame(uint256 drawCount) public onlyOwner {
        require(drawCount > 0, "the draw count should bigger than 0.");
        _gameNo = _gameNo + 1;
        _drawCount = drawCount;
        _usedBlockNo = block.number;
    }

    // return 1~52
    function draw() public {

        // init for new game
        if (_gameNo > _personCards[msg.sender].gameNo){
            delete _personCards[msg.sender];
            _personCards[msg.sender].gameNo = _gameNo;
        } else {
            // one game ,one address could draw _drawCount times
            require(_personCards[msg.sender].drawTimes < _drawCount, "you have draw too many times");
        }

        uint8 randomNo = uint8(uint256(keccak256(abi.encodePacked(_gameNo, msg.sender, _personCards[msg.sender].drawTimes, block.timestamp, block.difficulty, block.coinbase))) % 52) + 1;
        require(!_personCards[msg.sender].cards[randomNo], "you draw a same card, please draw once time later.");

        _personCards[msg.sender].cards[randomNo] = true;
        _personCards[msg.sender].drawTimes = _personCards[msg.sender].drawTimes + 1;
        _usedBlockNo = block.number;
        emit ShowCard(msg.sender, _personCards[msg.sender].drawTimes, randomNo);
    }
}