/**
 *Submitted for verification at Etherscan.io on 2022-09-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

contract texasHoldEm {

    mapping(address => uint) public userBalance;
    mapping(address => uint) public userClaimed;
    mapping(uint => address) public rmIdToUser; //get owner from room id
    mapping(uint => uint8) public rmIdToType; //get room type from room id
    mapping(address => mapping(uint8 => uint[])) public userRms; //get user owned room from room type and address
    mapping(address => mapping(uint8 => uint)) public userOwnedRmsNum; //get user owned room number from room type and address

    event Deposit(address user, uint value);
    event Withdraw(address user, uint value);
    event CreateRoom(address user, uint8 roomType, uint roomId);

    address public owner;
    uint256 public processFee;
    uint256 public largeRmFee;
    uint256 public middleRmFee;
    uint256 public smallRmFee;
    uint256 internal _roomCreated = 0;

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        processFee = 1 * 10 ** 15;
        smallRmFee = 1 * 10 ** 15;
        middleRmFee = 1 * 10 ** 16;
        largeRmFee = 1 * 10 ** 17;
    }

    function deposit() public payable {
        userBalance[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(address _claimer, uint256 _fee) public onlyOwner {
        payable(owner).transfer(processFee);
        payable(_claimer).transfer(_fee - processFee);
        userClaimed[_claimer] += _fee;
        emit Withdraw(_claimer, _fee);
    }

    function updateProcessFee(uint256 _fee) public onlyOwner {
        processFee = _fee;
    }

    function updateRoomFee(uint256 _fee, uint8 _roomType) public onlyOwner {
        //1 = small, 2 = middle, 3 = large
        if(_roomType == 1) {
            smallRmFee = _fee;
        }

        if(_roomType == 2) {
            middleRmFee = _fee;
        }

        if(_roomType == 3) {
            largeRmFee = _fee;
        }
    }

    function createRoom(uint8 _roomType) public payable{
        //1 = small, 2 = middle, 3 = large
        if(_roomType == 1) {
            require(msg.value == smallRmFee, "price is too low");
        }

        if(_roomType == 2) {
            require(msg.value == middleRmFee, "price is too low");
        }

        if(_roomType == 3) {
            require(msg.value == largeRmFee, "price is too low");
        }

        //generate a random id to the room
        uint _roomId = _random();
        while(rmIdToUser[_roomId] != address(0) || _roomId < 10000 || _roomId > 99999) {
            _roomId = _random();
        }

        require(rmIdToUser[_roomId] == address(0), "roomId is existed");

        rmIdToUser[_roomId] = msg.sender;
        rmIdToType[_roomId] = _roomType;
        userRms[msg.sender][_roomType].push(_roomId);
        userOwnedRmsNum[msg.sender][_roomType]++;

        emit CreateRoom(msg.sender, _roomType, _roomId);
    }

    //generate 10 random cards
    function _random() internal returns(uint){
        uint randomnumber = uint(keccak256(abi.encodePacked(_roomCreated, msg.sender))) % 90000;
        randomnumber = randomnumber + 10000;
        _roomCreated++;
        return randomnumber;
    }
}