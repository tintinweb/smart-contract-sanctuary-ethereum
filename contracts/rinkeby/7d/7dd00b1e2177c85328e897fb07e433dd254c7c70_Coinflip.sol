/**
 *Submitted for verification at Etherscan.io on 2022-04-02
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

contract Coinflip {

    struct CoinflipGame {
        uint block;
        // Player[] players;
        uint blocktimestamp;
        uint nonce;
    }

    struct Player {
        address addr;
        string side;
        uint256 amount;
    }

    enum GameSides {
        T,
        CT
    }

    enum GameStates {
        Pending,
        InProgress,
        Cancelled,
        Finished
    }

    address public owner;

    CoinflipGame[] games;
    CoinflipGame newGame;

    mapping(string => GameStates) private states;

    event Create(address player, uint256 amount, string side);

    constructor() {

        owner = msg.sender;

    }

    function create(uint256 _amount, string memory _side) payable public {

        require(msg.value >= _amount, "Not enough balance");

        uint nonce = totalGames();

        newGame = CoinflipGame(
            block.number,
            block.timestamp,
            nonce
        );

        games.push(newGame);

        emit Create(msg.sender, _amount, _side);

    }

    function getGames() public view returns (CoinflipGame[] memory) {
        
        return games;

    }

    function totalGames() public view returns (uint256) {
        return games.length;
    }

}