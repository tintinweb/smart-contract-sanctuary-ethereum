/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Leaderboard {
    bool public isActive;
    uint256 public ticketPrice;
    string public gameStartTime;
    string public gameEndTime;
    address public lastWinner;

    address public owner;
    constructor(uint256 newTicketPrice, string memory startTime, string memory endTime) {
        owner = msg.sender;
        ticketPrice = newTicketPrice;
        gameStartTime = startTime;
        gameEndTime = endTime;
    }

    address[] public users;
    struct Entry {
        uint256 value;
        uint256 bestScore;
        bool hasValue;
    }
    mapping(address => Entry) public scores;

    function AddScore(address user, uint256 score) public {
        require(msg.sender == owner || IsManager(msg.sender), "Only the owner or managers can inject more scores.");
        if (!scores[user].hasValue) users.push(user);
        scores[user].hasValue = true;
        if (scores[user].bestScore < score) scores[user].bestScore = score;
    }

    function GetUserBestScore(address user) public view returns(uint256) {
        return scores[user].bestScore;
    }

    function GetLeaderboardBestScore() public view returns(uint256) {
        uint256 bestScore = 0;
        for (uint i=0; i < users.length; i++){
            if (scores[users[i]].bestScore > bestScore) bestScore = scores[users[i]].bestScore;
        }
        return bestScore;
    }

    function GetUsersCount() public view returns(uint256) {
        return users.length;
    }

    function StartGame() public {
        require(msg.sender == owner || IsManager(msg.sender), "Only the owner or managers can change game state.");
        isActive = true;
    }

    function EndGame() public {
        require(msg.sender == owner || IsManager(msg.sender), "Only the owner or managers can change game state.");
        isActive = false;
        uint256 bestScore = GetLeaderboardBestScore();
        for (uint i=0; i < users.length; i++){
            if (scores[users[i]].bestScore == bestScore){ 
                lastWinner = users[i];
                break;
            }
        }
        Clear();
    }

    function Clear() private {
        for (uint i=0; i < users.length; i++) delete scores[users[i]];
        delete users;
    }

    // Managers----------------------------------------------------
    address[] public managers;

    function IsManager(address manager) private view returns(bool) {
        for (uint i=0; i<managers.length; i++){
            if (manager == managers[i]) return true;
        }
        return false;
    }

    function AddManager(address manager) public {
        require(msg.sender == owner, "Only the owner is allowed to add new managers.");
        if (!IsManager(manager)) managers.push(manager);
    }

    function RemoveManager(address manager) public {
        require(msg.sender == owner, "Only the owner is allowed to remove managers.");
        for (uint i=0; i<managers.length; i++) {
            if (managers[i] == manager) delete managers[i];
        }
    }
}