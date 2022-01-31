pragma solidity ^0.8.0;

contract Lottery {
    address public manager;
    address[] public players;

    constructor() {
        setManager();
        players.push(0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db);
    }

    modifier onlyOwner() {
        require(msg.sender == manager, "Only owner can perform this action");
        _;
    }

    function setManager() private {
        manager = msg.sender;
    }

    function enter() public payable {
        if (msg.value > 1000000000000000) {
            players.push(msg.sender);
        }
    }

    function chooseWinner() public onlyOwner {
        uint256 winner = uint256(block.timestamp) % players.length;
        uint256 balance = address(this).balance;
        payable(players[winner]).transfer(balance);
    }
}