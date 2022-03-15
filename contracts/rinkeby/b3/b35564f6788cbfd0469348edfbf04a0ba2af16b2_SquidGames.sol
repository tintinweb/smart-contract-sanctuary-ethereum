/**
 *Submitted for verification at Etherscan.io on 2022-03-15
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
    Game[] public games;
    uint public currentGame;
    uint public currentDay;
    bool public isActive;
    function AddGame(string memory id, uint time, uint lifes, uint peopleMoving) onlyAuth public {
        games.push(Game(id, games.length, time, lifes, peopleMoving));
    }
    function RemoveGame(string memory id) onlyAuth public {
        for (uint i=0; i < games.length; i++) {
            if (CompareStrings(games[i].id, id)) delete games[i];
        }
    }
    function StartGame() onlyAuth() public {
        require(games.length > 0, "Managers must add games in order to start the series.");
        if (!isActive) {
            isActive = true;
            currentDay = 0;
            for (uint i=0; i < users.length; i++) {
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
            for (uint i=0; i < users.length; i++) {
                if (leaderboard[users[i]].active && leaderboard[users[i]].score == 0) leaderboard[users[i]].active = false;
            }
            currentGame++;
            insertOrder = 0;
            ResetUsers();
            if (currentGame >= games.length) CrownWinner(orderedActiveUser);
        }
    }
    function CrownWinner(address[] memory orderedUsers) private {
        uint totalValueToSend = CalculatePercentage(currentPot, 80);
        (bool sent, ) = orderedUsers[0].call{value: totalValueToSend}("");
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
        require(isActive, "Game is not active.");
        require(IsUserEnrolled(user), "User must be enrolled in order to add a score.");
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
    function IsUserActive(address user) public view returns(bool) {
        return leaderboard[user].active;
    }
    function GetUsersCount() public view returns(uint) {
        return users.length;
    }
    function GetActiveUsersInOrder() private view returns(address[] memory) {
        uint activeUsers = 0;
        for (uint i=0; i < users.length; i++) {
            if (leaderboard[users[i]].active && leaderboard[users[i]].score != 0) activeUsers++;
        }
        address[] memory orderedUsers = new address[](activeUsers);
        uint usersAdded = 0;
        for (uint i=0; i < users.length; i++) {
            if (leaderboard[users[i]].active && leaderboard[users[i]].score != 0) { 
                orderedUsers[usersAdded] = users[i];
                usersAdded++;
            }
        }
        for (uint i=0; i < orderedUsers.length; i++) {
            if (i + 1 >= orderedUsers.length) break;
            address currentUser = orderedUsers[i];
            address bestUserFound = currentUser;
            uint bestUserPosition = i + 1;
            uint bestScoreFound = leaderboard[currentUser].score;
            for (uint j=i+1; j < orderedUsers.length; j++) {
                if (bestScoreFound > leaderboard[orderedUsers[j]].score || 
                (bestScoreFound == leaderboard[orderedUsers[j]].score && leaderboard[bestUserFound].insertOrder > leaderboard[orderedUsers[j]].insertOrder)) {
                    bestUserFound = orderedUsers[j];
                    bestUserPosition = j;
                    bestScoreFound = leaderboard[bestUserFound].score;
                }
            }
            if (currentUser != bestUserFound) {
                orderedUsers[i] = bestUserFound;
                orderedUsers[bestUserPosition] = currentUser;
            }
        }
        return orderedUsers;
    }
    function ResetUsers() private {
        for (uint i=0; i < users.length; i++) { 
            leaderboard[users[i]].tickets = 0;
            leaderboard[users[i]].levels = "";
            leaderboard[users[i]].eulerAngles = "";
            leaderboard[users[i]].frameClicks = "";
            leaderboard[users[i]].clickPositions = "";
        }
    }

    // Enroll-----------------------------------------------------
    uint public enrollPrice;
    function Enroll(string memory id) public payable {
        require(msg.value == enrollPrice, "Wrong ETH amount.");
        require(isActive, "Game must be active to buy new tickets.");
        require(currentGame == 0, "You are only allowed to enroll during the first game of the series.");
        require(!IsUserEnrolled(msg.sender), "User is already enrolled.");
        leaderboard[msg.sender].id = id;
        leaderboard[msg.sender].tickets = games[currentGame].ticketsAvailable;
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