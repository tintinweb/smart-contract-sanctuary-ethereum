/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract SquidGames {
    // Global-----------------------------------------------------
    uint public currentPot;

    // Const------------------------------------------------------
    uint MAX_UINT = 2**256 - 1;

    // Constructor------------------------------------------------
    constructor (uint startEnrollPrice) {
        owner = msg.sender;
        enrollPrice = startEnrollPrice;
        isActive = false;
    }

    // Game-------------------------------------------------------
    struct Game {
        string id;
        uint order;
        uint upTime;
        uint ticketsAvailable;
        uint peopleMovingForward;
    }
    Game[] games;
    uint public currentGame;
    uint public totalGames;
    uint public currentDay;
    bool public isActive;
    function AddGame(string memory id, uint time, uint lifes, uint peopleMoving) onlyAuth public {
        games.push(Game(id, games.length, time, lifes, peopleMoving));
        totalGames++;
    }
    function RemoveGame(string memory id) onlyAuth public {
        for (uint i=0; i < totalGames; i++) {
            if (CompareStrings(games[i].id, id)) delete games[i];
        }
    }
    function StartGame() onlyAuth() public {
        require(games.length > 0, "Managers must add games in order to start the series.");
        if (!isActive) {
            currentDay = 0;
            isActive = true;
            for (uint i=0; i < users.length; i++){
                leaderboard[users[i]].score = 0;
                if (leaderboard[users[i]].active) leaderboard[users[i]].tickets = games[currentGame].ticketsAvailable;
            }
        }
        else currentDay++;
    }
    function EndGame() onlyAuth() public {
        require(isActive, "Game must be active in order to end it.");
        if (currentGame >= games.length) return;
        if (currentDay >= games[currentGame].upTime - 1) {
            isActive = false;
            address[] memory orderedActiveUser = GetActiveUsersInOrder();
            for (uint i=0; i < orderedActiveUser.length; i++) {
                if (i >= games[currentGame].peopleMovingForward) leaderboard[orderedActiveUser[i]].active = false;
            }
            currentGame++;
            insertOrder = 0;
            DeleteAllTickets();
            if (currentGame >= games.length) CrownWinner();
        }
    }
    function CrownWinner() private {
        uint bestScore = GetLeaderboardBestScore();
        User memory bestUser;
        address bestAddress;
        uint lowestInsertFound = MAX_UINT;
        for (uint i=0; i < users.length; i++) {
            if (leaderboard[users[i]].score == bestScore && leaderboard[users[i]].insertOrder < lowestInsertFound){
                bestAddress = users[i];
                bestUser = leaderboard[bestAddress];
                lowestInsertFound = bestUser.insertOrder;
                break;
            }
        }
        uint totalValueToSend = CalculatePercentage(currentPot, 80);
        (bool sent, ) = bestAddress.call{value: totalValueToSend}("");
        require(sent, "Failed to send ETH.");
    }
    function GetGamesCount() public view returns(uint) {
        return games.length;
    }
    function ClearEverything() onlyAuth() public {
        for (uint i=0; i < users.length; i++) delete leaderboard[users[i]];
        delete users;
        delete games;
    }

    // Users-------------------------------------------------------
    struct User {
        string id;
        uint score;
        uint skinId;
        bool active;
        string levels;
        uint tickets;
        uint insertOrder;
        string eulerAngles;
        string frameClicks;
        string clickPositions;
    }
    uint private insertOrder;
    address[] public users;
    mapping (address => User) public leaderboard;
    function AddScore(address user, uint score, uint skinId, string memory clickPositions, string memory levels, string memory eulerAngles, string memory frameClicks) onlyAuth() public {
        require(isActive, "Game is not active. Wait for a new beginning.");
        if (leaderboard[user].score == 0 || leaderboard[user].score > score) {
            leaderboard[user].clickPositions = clickPositions;
            leaderboard[user].insertOrder = insertOrder;
            leaderboard[user].eulerAngles = eulerAngles;
            leaderboard[user].frameClicks = frameClicks;
            leaderboard[user].levels = levels;
            leaderboard[user].skinId = skinId;
            leaderboard[user].score = score;
            insertOrder++;
        }
    }
    function GetLeaderboardBestScore() public view returns(uint) {
        uint bestScore = MAX_UINT;
        for (uint i=0; i < users.length; i++){
            if (leaderboard[users[i]].score < bestScore) bestScore = leaderboard[users[i]].score;
        }
        return bestScore;
    }
    function IsUserActive(address user) public view returns(bool) {
        return leaderboard[user].active;
    }
    function GetUsersCount() public view returns(uint) {
        return users.length;
    }
    function GetActiveUsersInOrder() private view returns(address[] memory) {
        uint activeUsers = 0;
        for (uint i=0; i < users.length; i++) {
            if (leaderboard[users[i]].active) activeUsers++;
        }
        address[] memory orderedUsers = new address[](activeUsers);
        for (uint i=0; i < users.length; i++) {
            if (leaderboard[users[i]].active) orderedUsers[i] = users[i];
        }
        for (uint i=0; i < orderedUsers.length; i++) {
            if (i + 1 >= orderedUsers.length) break;
            address currentUser = orderedUsers[i];
            if (leaderboard[currentUser].score > leaderboard[orderedUsers[i + 1]].score) {
                orderedUsers[i] = orderedUsers[i + 1];
                orderedUsers[i + 1] = currentUser;
            }
        }
        for (uint i=0; i < orderedUsers.length; i++) {
            if (i + 1 >= orderedUsers.length) break;
            address currentUser = orderedUsers[i];
            address nextUser = currentUser;
            uint bestInsertOrder = leaderboard[currentUser].score;
            for (uint j=i+1; j < orderedUsers.length; j++){
                if (leaderboard[currentUser].score != leaderboard[orderedUsers[j]].score) break;
                if (bestInsertOrder > leaderboard[orderedUsers[j]].insertOrder) {
                    nextUser = orderedUsers[j];
                    bestInsertOrder = leaderboard[nextUser].insertOrder;
                }
            }
            if (currentUser != nextUser) {
                orderedUsers[i] = nextUser;
                orderedUsers[i + 1] = currentUser;
            }
        }
        return orderedUsers;
    }

    // Enroll-----------------------------------------------------
    uint public enrollPrice;
    function Enroll(string memory id) public payable {
        require(msg.value == enrollPrice, "Wrong ETH amount.");
        require(isActive, "Game must be active to buy new tickets.");
        require(currentGame == 0, "You are only allowed to enroll during the first game of the series.");
        require(!IsUserEnrolled(msg.sender), "User is already enrolled.");
        leaderboard[msg.sender].id = id;
        leaderboard[msg.sender].tickets = 10;
        leaderboard[msg.sender].active = true;
        currentPot += msg.value;
        users.push(msg.sender);
    }
    function IsUserEnrolled(address user) public view returns(bool) {
        for (uint i=0; i < users.length; i++){
            if (users[i] == user) return true;
        }
        return false;
    }

    //Tickets------------------------------------------------------
    function RemoveTicket(address user) onlyAuth() public {
        require(leaderboard[user].tickets > 0, "User doesn't own anymore tickets.");
        leaderboard[user].tickets--;
    }
    function GetTicketsPurchased(address user) public view returns(uint) {
        return leaderboard[user].tickets;
    }
    function DeleteAllTickets() private {
        for (uint i=0; i < users.length; i++) leaderboard[users[i]].tickets = 0;
    }

    // Managers----------------------------------------------------
    address public owner;
    address[] public managers;
    modifier onlyOwner() {
        require(owner == msg.sender, "Not authorized.");
        _;
    }
    modifier onlyAuth() {
        require(msg.sender == owner || IsManager(msg.sender), "Only the owner or managers have the clearance.");
        _;
    }
    function IsManager(address manager) private view returns(bool) {
        for (uint i=0; i < managers.length; i++){
            if (manager == managers[i]) return true;
        }
        return false;
    }
    function AddManager(address manager) onlyOwner() public {
        if (!IsManager(manager)) managers.push(manager);
    }
    function RemoveManager(address manager) onlyOwner() public {
        for (uint i=0; i < managers.length; i++) {
            if (managers[i] == manager) delete managers[i];
        }
    }

    // Utilities------------------------------------------------------
    function CompareStrings(string memory a, string memory b) private pure returns (bool){
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
    function CalculatePercentage(uint value, uint percentage) private pure returns (uint){
        return value * percentage / 100;
    }
}