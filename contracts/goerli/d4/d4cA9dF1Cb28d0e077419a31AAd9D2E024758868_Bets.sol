/**
 *Submitted for verification at Etherscan.io on 2023-03-06
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

struct Game {
    uint256[2] bet;
    uint256 finish_timestamp;
    uint8 winner; //0, 1, 2
}

contract Bets {
    Game[] public games;
    mapping(uint256 => mapping(address => uint256[2])) public userBets; //gameId => wallet => bet
    address public owner;
    mapping(address => bool) public isAdmin;
    mapping(address => bool) public isRegistered;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyAdmin() {
        require(isAdmin[msg.sender] == true, "Not admin");
        _;
    }

    function _hasFinished(uint256 gameId) private view returns(bool) {
        if (block.timestamp >= games[gameId].finish_timestamp)
            return true;
        return false;
    }

    modifier hasFinished(uint256 gameId) {
        require(_hasFinished(gameId) == true);
        _;
    }

    constructor() {
        owner = tx.origin;
        isAdmin[msg.sender] = true;
    }

    function addAdmin(address wallet) public onlyOwner {
        require(isAdmin[wallet] == false, "Already admin");
        isAdmin[wallet] = true;
    }

    function removeAdmin(address wallet) public onlyOwner {
        require(isAdmin[wallet] == true, "Not admin");
        require(wallet != msg.sender, "Cannot remove yourself");
        isAdmin[wallet] = false;
    }

    function transferOwnership(address wallet) public onlyOwner {
        require(wallet != address(0), "Cannot transfer ownership to null");
        owner = wallet;
    }

    function createGame(uint256 h, uint256 m, uint256 s) public onlyOwner {
        Game memory game;
        game.finish_timestamp = block.timestamp + h * 1 hours + m * 1 minutes + s * 1 seconds;
        games.push(game);
    }

    function setWinner(uint256 gameId, uint8 option) public onlyAdmin hasFinished(gameId) {
        Game storage game = games[gameId];
        require(0 < option && option < 3, "Invalid option");
        game.winner = option;
    }

    function bet(uint256 gameId, uint8 option) public payable {
        require(_hasFinished(gameId) == false);
        require(0 < option && option < 3, "Invalid option");

        userBets[gameId][msg.sender][option - 1] += msg.value;
        games[gameId].bet[option - 1] += msg.value;
    }

    function claimReward(uint256 gameId) public hasFinished(gameId) {
        Game storage game = games[gameId];

        uint8 winnerId = game.winner - 1;
        uint256 bettedAmount = userBets[gameId][msg.sender][winnerId];
        uint256 totalAmount = game.bet[0] + game.bet[1];

        uint256 owedAmount = totalAmount * bettedAmount / game.bet[winnerId];
        require(owedAmount > 0, "Nothing is owned to you");

        (bool successOwner, ) = owner.call{value: owedAmount / 10}("");
        (bool successUser, ) = msg.sender.call{value: (owedAmount * 90) / 100}("");
        require(successOwner == true && successUser == true, "Transaction failed");

        // Actualizamos el valor de la apuesta a 0
        userBets[gameId][msg.sender][winnerId] = 0;
    }

    receive() external payable {}
}