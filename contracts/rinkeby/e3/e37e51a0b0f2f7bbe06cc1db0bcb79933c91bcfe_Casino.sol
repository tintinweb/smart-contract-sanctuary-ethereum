/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

contract Casino {
    Game[] public games;

    Gambler[] public gamblersRegistered;
    mapping(address => Gambler) public gamblers;

    event newGame(
        Game game
    );

    event gamblerRegistered(
        Gambler gambler
    );

    //
    // Games Management
    //

    function createGame(Gambler gambler) public payable {
        Game game = new Game();

        // send bet to the game contract
        game.start{value: msg.value}(gambler);

        // Store game in log
        games.push(game);

        emit newGame(game);
    }

    function getGames() public view returns (Game[] memory) {
        return games;
    }

    function getGameCount() public view returns (uint256) {
        return games.length;
    }

    //
    // Gamblers Management
    //

    function getGambler(address gamblerAddress) public view returns (Gambler) {
        Gambler gambler = gamblers[gamblerAddress];
        require(address(gambler) != address(0), 'Gambler not found. Please consider registering');
        return gambler;
    }

    function registerGambler(string memory name) public {
        require(address(gamblers[msg.sender]) == address(0), 'Gambler already registered');

        Gambler gambler = new Gambler(msg.sender, name);

        gamblersRegistered.push(gambler);
        gamblers[msg.sender] = gambler;

        emit gamblerRegistered(gambler);
    }

    function getGamblers() public view returns (Gambler[] memory) {
        return gamblersRegistered;
    }
}


contract Game {

    event gameFinished(
        Gambler winner
    );

    uint public minAmount = 10000;
    uint public betAmount;

    bool public finished = false;

    Gambler public player1;
    Gambler public player2;

    Gambler public winner;

    modifier notFinished {
        require(!finished, 'Game is finished');
        _;
    }

    function start(Gambler gambler) public payable {
        require(msg.value >= minAmount, 'You have to bet more than the minimum amount');
        player1 = gambler;
        betAmount = msg.value;
    }

    // The user who finishes the game is going to pay more gas.
    function play(Gambler gambler) public payable notFinished {
        require(address(player1) != address(0), "Starter is not set");
        require(player1.addr() != gambler.addr(), "Player already in the game");
        require(msg.value == betAmount, "You have to send the bet amount");

        finished = true;
        player2 = gambler;

        uint8 winnerIndex = random() % 2;

        if (winnerIndex == 0) {
            winner = player2;
        } else {
            winner = player1;
        }

        winner.receivePrize{value: address(this).balance}(this);

        emit gameFinished(winner);
    }

    // Un-safe random function
    function random() private view returns (uint8) {
        return uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)))%251);
    }
}


contract Gambler {
    Game[] public gamblerGames;
    Game[] public gamesWon;

    uint256 public amountWon = 0;

    address public addr;
    string public name;
    bool private withdrawing = false;

    constructor(address gamblerAddress, string memory gamblerName) {
        addr = gamblerAddress;
        name = gamblerName;
    }

    function registerGame(Game game) public {
        gamblerGames.push(game);
    }

    function receivePrize(Game gameWon) public payable {
        require(msg.value > 0, 'no prize received');
        amountWon += msg.value;
        gamesWon.push(gameWon);
    }

    function withdraw() public {
        uint256 amount = address(this).balance;

        require(msg.sender == addr, 'you are not allow to withdraw the funds');
        require(!withdrawing, 'Transacting in progress');
        require(amount > 0, 'nothing to withdraw');

        withdrawing = true;
        payable(addr).transfer(amount);
        withdrawing = false;
    }

    function numGamesWon() public view returns (uint256) {
        return gamesWon.length;
    }

    function getGamesWon() public view returns (Game[] memory) {
        return gamesWon;
    }

    function getGames() public view returns (Game[] memory) {
        return gamblerGames;
    }
}