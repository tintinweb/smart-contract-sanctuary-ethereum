// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// import "hardhat/console.sol"; // DEBUG

/**
 * @title Rafflebot
 * @author Max Petretta (maxpetretta.eth)
 * @notice A smart contract based daily raffle platform, secured by WorldID
 * @dev Only in MVP stage!
 */
contract Rafflebot {
    uint256 public id;
    uint256 public endTime;
    uint256 private seed;
    address[] public entrants;
    mapping(address => uint256) public entries;
    mapping(uint256 => address) public winners;

    event NewEntry(address indexed from, uint256 indexed id, uint256 timestamp);

    event NewWinner(
        address indexed winner,
        uint256 indexed id,
        uint256 timestamp
    );

    event NewRaffle(uint256 indexed id, uint256 endTime);

    /// @notice Thrown when the sender has already entered the raffle
    error AlreadyEntered();

    /// @notice Thrown when the current raffle has not expired yet
    error RaffleNotOver();

    constructor() {
        id = 1;
        endTime = block.timestamp + 15 minutes;
        seed = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));

        emit NewRaffle(id, endTime);
    }

    function enter() public {
        if (entries[msg.sender] == id) revert AlreadyEntered();

        entrants.push(msg.sender);
        entries[msg.sender] = id;

        emit NewEntry(msg.sender, id, block.timestamp);
    }

    function end() public {
        if (endTime > block.timestamp) revert RaffleNotOver();

        if (entrants.length > 0) {
            address winner = raffle();
            winners[id] = winner;
            emit NewWinner(winner, id, block.timestamp);
        }

        reset();
    }

    function raffle() private returns (address) {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, seed)));
        uint256 index = randomNumber % entrants.length;
        
        address winner = entrants[index];
        seed = randomNumber;

        return winner;
    }

    function reset() private {
        delete entrants;
        endTime = block.timestamp + 24 hours;
        id++;

        emit NewRaffle(id, endTime);
    }

    function getID() public view returns (uint256) {
        return id;
    }

    function getEndTime() public view returns (uint256) {
        return endTime;
    }

    function getEntrants() public view returns (address[] memory) {
        return entrants;
    }

    function getWinner(uint256 _id) public view returns (address) {
        return winners[_id];
    }
}