// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// This contract generates a random number between 1 and 100000

interface ITRC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract SimpleFight {
    ITRC20 controlether;
    ITRC20 controltoken;
    event FinishedOneFight(address winner, uint256 roomnum);
    event EnterFirstroom(address enterer, uint256 roomnum);

    struct Roominfo {
        bool status;
        address[] fighters;
        uint256[] randoms;
    }

    mapping(address => uint256) public reward;
    mapping(uint256 => Roominfo) public roominfo;

    uint256 public firstrandom;
    uint256 public secondrandom;
    uint256 public maxroomnum;
    uint256 public firstether;
    uint256 public secondether;
    uint256 public firstlink;
    uint256 public secondlink;
    
    address public testaddress = 0x7af963cF6D228E564e2A0aA0DdBF06210B38615D;
    address public chainlinkaddress = 0xd14838A68E8AFBAdE5efb411d5871ea0011AFd28;

    constructor () {
        controlether = ITRC20(testaddress);
        controltoken = ITRC20(chainlinkaddress);
    }

    function enterroom(uint256 _roomnum) public payable {
        require(msg.value >= 10, "You don't have enough balance!");
        firstether = msg.value;
        firstlink = controltoken.balanceOf(msg.sender);
        if(_roomnum > maxroomnum) {
            maxroomnum = _roomnum;
            roominfo[_roomnum] = Roominfo({
                status: false,
                randoms: new uint256[](0),
                fighters: new address[](0)
            });
            firstrandom = 0;
            secondrandom = 0;
        }
        firstrandom = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 100000 + 1;
        roominfo[_roomnum].fighters.push(msg.sender);
        emit EnterFirstroom(msg.sender, _roomnum);
    }

    function fight(uint256 _roomnum) public payable {
        secondether = msg.value;
        secondlink = controltoken.balanceOf(msg.sender);
        require(msg.value >= 10, "You don't have enough balance!");
        require(roominfo[_roomnum].status != true, "This betting game is already finished!");
        require(roominfo[_roomnum].fighters.length != 2, "There are already enough players!");
        roominfo[_roomnum].fighters.push(msg.sender);
        require(roominfo[_roomnum].fighters.length == 2, "There aren't enough players!");
        secondrandom = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 100000 + 1;
        if(firstrandom > secondrandom) {
            reward[roominfo[_roomnum].fighters[0]] += 20;
        } else {
            reward[roominfo[_roomnum].fighters[1]] += 20;
        }
        roominfo[_roomnum].status = true;
        emit FinishedOneFight(roominfo[_roomnum].fighters[0], _roomnum);
    }
}