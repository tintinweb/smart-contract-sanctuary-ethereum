/**
 *Submitted for verification at Etherscan.io on 2022-06-14
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
        uint endTimeReward;
        uint startTimeSpin;
    }

    mapping(address => uint) public balance;
    uint public roomId;
    uint public maxPlayerNumbers;
    uint private ticketPrice;
    address payable owner; 
    uint private reward;
    uint private feeReward;
    mapping(uint => Room) room;
    mapping(address => uint[]) listRoomOfPlayer; 

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

    function checkExistInRoom(uint currentPlayerNumbers, uint roomId) public view returns(bool){
        for(uint i=0; i < currentPlayerNumbers; i++) {
            if(room[roomId].addressPlayers[i] == msg.sender) {
                return true;
            }
        }
        return false;
    }

    function getLastRoomOfPlayer() public view returns(uint){
        uint roomsOfPlayer = listRoomOfPlayer[msg.sender].length;
        if(roomsOfPlayer == 0) {
            return 0;
        } else {
            uint roomId = listRoomOfPlayer[msg.sender][roomsOfPlayer-1];
            if(room[roomId].addressPlayers.length == maxPlayerNumbers) {
                return 0;
            } else {
                return listRoomOfPlayer[msg.sender][roomsOfPlayer-1];   
            }
        }
    }

    function joinGame() public payable  notOwner() {
        uint currentPlayerNumbers = room[roomId].addressPlayers.length;

        if(currentPlayerNumbers == maxPlayerNumbers) {
            roomId++;
            currentPlayerNumbers = 0;
        }
        if(!checkExistInRoom(currentPlayerNumbers, roomId) && currentPlayerNumbers < maxPlayerNumbers) {
            require(msg.value == ticketPrice);
            room[roomId].addressPlayers.push(msg.sender);
            listRoomOfPlayer[msg.sender].push(roomId);
            emit addPlayer(msg.sender);
            currentPlayerNumbers++;
            balance[address(this)] = address(this).balance;    
            if(currentPlayerNumbers == maxPlayerNumbers) {
                room[roomId].startTimeSpin = block.timestamp;
                pickwinner();
            }
        } 
    }
    
    function random() public view returns(uint) {
        return uint(keccak256(abi.encode(block.difficulty, block.timestamp, room[roomId], block.number)));
    }
    
    function pickwinner() public payable {
        uint win = random() % room[roomId].addressPlayers.length;
        room[roomId].winner = payable(room[roomId].addressPlayers[win]);
        room[roomId].isClaimed = true;
        room[roomId].endTimeReward = block.timestamp + 250;
        owner.transfer(feeReward);
        balance[owner] += feeReward;
        balance[address(this)] -= feeReward;
        emit transfer(address(this), owner, feeReward);
        
    }

    function claimReward(uint roomId) public payable noReentrant onlyWinner(roomId){
        require(block.timestamp < room[roomId].endTimeReward && room[roomId].isClaimed, "Oops! Time off. You can not get reward.");
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
}