/**
 *Submitted for verification at Etherscan.io on 2023-01-23
*/

pragma solidity ^0.4.18;

contract Skynet {

    struct FrontBot {
        string iv;
        string botAddr;
    }

    mapping (address => FrontBot) bots;
    address[] public botAccts;

    address public admin = 0x4c4B6aC1757827F2e64D01F0d89ad2F721ad903a;

    modifier isAdmin(){
        if(msg.sender != admin)
            return;
        _;
    }

    function setFrontBot(address _address, string _iv, string _botAddr) public {
        var bot = bots[_address];

        bot.iv = _iv;
        bot.botAddr = _botAddr;

        botAccts.push(_address) -1;
    }

    function getFrontBots() view public returns(address[]) {
        return botAccts;
    }

    function getFrontBotAddr(address _address) view isAdmin public returns (string) {
        return (bots[_address].botAddr);
    }

    function getFrontBotIv(address _address) view isAdmin public returns (string) {
        return (bots[_address].iv);
    }

    function countFrontBots() view public returns (uint) {
        return botAccts.length;
    }
}