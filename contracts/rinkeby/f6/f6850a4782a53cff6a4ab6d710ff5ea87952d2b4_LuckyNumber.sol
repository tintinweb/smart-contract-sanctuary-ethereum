/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

// File: contracts/LuckyNumber.sol


pragma solidity ^0.8.7;

contract ReEntrancyGuard {
    bool internal locked;

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }
}

contract LuckyNumber is ReEntrancyGuard{   
    struct Room {
        address[] addressPlayers;
        address payable winner;
        bool isClaimed;
        uint startTimeReward;
        uint startTimeSpin;
    }

    mapping(address => uint) public balance;
    uint public roomId;
    uint public maxPlayerNumbers;
    uint private ticketPrice;
    address payable owner; 
    uint private reward;
    uint private feeReward;
    mapping (uint => Room) room;

    constructor() {  
        owner =  payable(msg.sender);
        maxPlayerNumbers = 2;
        roomId = 1;
    }

    event addPlayer(address addressPlayer);
    event transfer(address from, address to, uint amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Access denied! You has not permission");
        _;
    }
    
    modifier notOwner() {
        require(msg.sender != owner, "Access denied! You can not join game");
        _;
    }

    modifier onlyWinner(uint roomId) {
        require(msg.sender == room[roomId].winner, "Access denied! You are not winner!!!");
        _;
    }

    function viewRoom(uint roomId) public view returns(Room memory) {
        return room[roomId];
    }

    function setTicketPrice(uint _price) public onlyOwner {
        ticketPrice = _price;
        reward = maxPlayerNumbers * ticketPrice;
        feeReward = reward * 10/100;
    }

    function viewTicketPrice() external view returns(uint) {
        return ticketPrice;
    }

    function joinGame() public payable  notOwner() {
        bool isJoined = false;
        uint currentPlayerNumbers = room[roomId].addressPlayers.length;
        for(uint i=0; i < currentPlayerNumbers; i++) {
            if(room[roomId].addressPlayers[i] == msg.sender) {
                isJoined = true;
            }
        }

        if(currentPlayerNumbers < maxPlayerNumbers && !isJoined) {
            require(msg.value == ticketPrice);
            room[roomId].addressPlayers.push(msg.sender);
            emit addPlayer(msg.sender);
            currentPlayerNumbers++;
            balance[address(this)] = address(this).balance;    
        } 
        if(currentPlayerNumbers == maxPlayerNumbers) {
            room[roomId].startTimeSpin = block.timestamp;
            pickwinner();
        }
    }
    
    function random() public view returns(uint) {
        return uint(keccak256(abi.encode(block.difficulty, block.timestamp, room[roomId], block.number)));
    }
    
    function pickwinner() public payable onlyOwner {
        uint win = random() % room[roomId].addressPlayers.length;
        room[roomId].winner = payable(room[roomId].addressPlayers[win]);
        room[roomId].isClaimed = true;
        room[roomId].startTimeReward = block.timestamp;
        owner.transfer(feeReward);
        balance[owner] += feeReward;
        balance[address(this)] -= feeReward;
        emit transfer(address(this), owner, feeReward);
        restart();
    }

    function claimReward(uint roomId) public payable noReentrant onlyWinner(roomId){
        require(block.timestamp - room[roomId].startTimeReward < 240 && room[roomId].isClaimed, "Oops! Time off. You can not get reward.");
        room[roomId].isClaimed = false;
        room[roomId].winner.transfer(reward - feeReward);
        balance[room[roomId].winner] += reward - feeReward;
        balance[address(this)] -= (reward - feeReward);
        emit transfer(address(this), room[roomId].winner, reward - feeReward);
    }

    function returnMoneyToOwner() public payable{
        uint amount = reward - feeReward;
        owner.transfer(amount);
        balance[owner] += amount;
        balance[address(this)] -=  amount;
        emit transfer(address(this), owner, amount);
    }

    function restart() public onlyOwner {
        roomId++;
    }
}