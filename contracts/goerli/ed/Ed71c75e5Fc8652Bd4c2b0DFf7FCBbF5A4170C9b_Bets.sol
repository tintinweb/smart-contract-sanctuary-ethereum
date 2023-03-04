/**
 *Submitted for verification at Etherscan.io on 2023-03-04
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
        if (games[gameId].winner == 0)
            return false;
        if (block.timestamp >= games[gameId].finish_timestamp)
            return false;
        return true;
    }

    modifier hasFinished(uint256 gameId) {
        require(_hasFinished(gameId) == false);
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

        uint256 totalAmount = game.bet[0] + game.bet[1];
        uint256 earnings;
        if (game.bet[0] < game.bet[1])
            earnings = game.bet[1] - game.bet[0];
        else
            earnings = game.bet[0] - game.bet[1];
        uint256 fee = earnings / 10;
        (bool success, ) = owner.call{value: fee}("");
        totalAmount -= earnings;

        game.bet[0] -= totalAmount * fee / game.bet[0];
        game.bet[1] -= totalAmount * fee / game.bet[1];
        require(success == true, "Transaction failded");
    }

    function bet(uint256 gameId, uint8 option) public payable {
        require(_hasFinished(gameId) == false);
        require(0 < option && option < 3, "Invalid option");

        userBets[gameId][msg.sender][option - 1] += msg.value;
        games[gameId].bet[option - 1] += msg.value;
    }

    //Arreglar bug de claimeo infinito
    function claimReward(uint256 gameId) public hasFinished(gameId) {
        Game storage game = games[gameId];

        uint8 winnerId = game.winner - 1;
        uint256 bettedAmount = userBets[gameId][msg.sender][winnerId];
        uint256 totalAmount = game.bet[0] + game.bet[1];
        // Actualizamos el valor de la apuesta a 0

        uint256 owedAmount = totalAmount * bettedAmount / game.bet[winnerId];
        require(owedAmount > 0, "Nothing is owned to you");

        (bool success, ) = msg.sender.call{value: owedAmount}("");
        require(success == true, "Transaction failed");

        userBets[gameId][msg.sender][winnerId] = 0;
    }

    receive() external payable {}
}