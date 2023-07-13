/**
 *Submitted for verification at Etherscan.io on 2023-07-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Bot {

struct BotInfo {
string iv;
string botAddr;
bool active;
}

address public admin;
address[] public botAddresses;
mapping(address => BotInfo) public bots;

event BotAdded(address indexed botAddress);
event BotToggled(address indexed botAddress, bool active);
event FlashSwapInitiated(address indexed caller, uint amountWETH, uint amountDAI);

constructor() {
admin = msg.sender;
}

modifier onlyAdmin() {
require(msg.sender == admin, "Only admin can call this function.");
_;
}

function setAdmin(address _admin) public onlyAdmin {
admin = _admin;
}

function setBot(address _botAddress, string memory _iv, string memory _botAddr) public payable onlyAdmin {
require(!botExists(_botAddress), "Bot already exists.");
bots[_botAddress] = BotInfo(_iv, _botAddr, true);
botAddresses.push(_botAddress);
emit BotAdded(_botAddress);
}

function toggleBotActive(address _botAddress) public payable onlyAdmin {
require(botExists(_botAddress), "Bot does not exist.");
bots[_botAddress].active = !bots[_botAddress].active;
emit BotToggled(_botAddress, bots[_botAddress].active);
}

function botExists(address _botAddress) public view returns (bool) {
return bots[_botAddress].active;
}

function countBots() public view returns (uint256) {
return botAddresses.length;
}

function getBot(address _address) public view returns (string memory, string memory, bool) {
BotInfo memory bot = bots[_address];
return (bot.iv, bot.botAddr, bot.active);
}

function getBotAddr(address _address) public view returns (address) {
return bytesToAddress(bytes(bots[_address].botAddr));
}

function getBotIv(address _address) public view returns (string memory) {
return bots[_address].iv;
}

function bytesToAddress(bytes memory bys) private pure returns (address addr) {
assembly {
addr := mload(add(bys, 20))
}
}

function receiveFlashSwap(address caller, uint amountWETH, uint amountDAI) external {
    // Take action based on the information in the event
    }

function listenForFlashSwaps() public {
    // Listen for the FlashSwapInitiated event
    }
}