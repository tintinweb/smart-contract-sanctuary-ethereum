/**
 *Submitted for verification at Etherscan.io on 2022-06-14
*/

// File: Matrix.sol

pragma solidity ^0.8.7;

//SPDX-License-Identifier: UNLICENSED

interface IMatrix {
    function itersOf(address account) external view returns (uint256);
    function addUserToQueue(address account) external;   
}

contract MiniMatrix {
    address public myParant;

    mapping(uint256 => address) public Queue;
    mapping(uint256 => uint256) public Cycles;

    uint256 public QueueFinish = 0;

    mapping(address => bool) public User;
    mapping(uint256 => uint256) public Parent;
    mapping(uint256 => mapping(uint256 => uint256)) public Childrens;

    mapping(address => uint256) public Referal;
    address public owner;

    uint256 public payValue;
    uint256 private startTime;

    constructor(uint256 value, uint256 timeStamp, address Owner) {
        owner = Owner;
        Queue[QueueFinish++] = owner;

        Parent[0] = 0;
        Cycles[0] = 2**256 - 1;

        payValue = value;
        startTime = timeStamp;

        Referal[owner] = (QueueFinish - 1); 

        myParant = msg.sender;
        User[owner] = true;
    }

    function changeOwner(address newOwner ) public
    {
        require(msg.sender == owner);
        owner = newOwner;
    } 

    function random(uint256 number) public view returns(uint256)
    {
        return uint256(keccak256(abi.encodePacked(block.timestamp,block.difficulty,  
        msg.sender))) % number;
    }

    function isUser(address a) public view returns(bool)
    {
        return User[a];
    }

    function addUser(uint256 ReferalNumber, address user)
        private
        returns (uint256)
    {
        require(!User[user]);
        User[user] = true;

        Childrens[ReferalNumber][++(Childrens[ReferalNumber][0])] = QueueFinish;

        Parent[QueueFinish] = ReferalNumber;
        Queue[QueueFinish] = user;

        IMatrix ip = IMatrix(myParant);

        Cycles[QueueFinish] = ip.itersOf(user);
        Referal[user] = QueueFinish; 

        ip.addUserToQueue(user);  

        QueueFinish++;

        return Referal[user];
    }

    function addUser(uint256 ReferalNumber)
        public   
        payable
        returns (uint256)
    {
        require(ReferalNumber < QueueFinish);
        require(block.timestamp > startTime);
        require(msg.value == payValue);        

        uint256 rand;
        do{
            rand = random(QueueFinish);
        } while(Cycles[rand] == 0);

        Cycles[rand]--;
        
        (bool success, ) = Queue[rand].call{value: ((74 * payValue)/100)}("");        
        require(success);
        (success, ) = Queue[ReferalNumber].call{value: ((13 * payValue)/100)}("");        
        require(success);
        (success, ) = Queue[Parent[ReferalNumber]].call{value: ((8 * payValue)/100)}("");        
        require(success);
        (success, ) = Queue[Parent[Parent[ReferalNumber]]].call{value: ((5 * payValue)/100)}("");        
        require(success);

        addUser(ReferalNumber, msg.sender);

        return Referal[msg.sender];
    }

    function addUsers(uint256[] memory ReferalNumbers, address[] memory newUsers, uint256 size)
        public   
    {
        require(msg.sender == owner);
        for(uint256 i = 0; i < size; i++)
        {
            addUser(ReferalNumbers[i], newUsers[i]);
        }
    }

    function addUserToQueue(address newUser)
        public           
    {
        require(msg.sender == myParant);
        Cycles[Referal[newUser]] = 2**256 - 1;
    }
}

contract Matrix is IMatrix{
    mapping(uint256 => address) public NumLevels;
    mapping(address => uint256) public Levels;
    uint256 public iter = 0;

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function newLevel(uint256 value, uint256 timeStamp) external
    {
        require(msg.sender == owner);

        MiniMatrix mm = new MiniMatrix(value, timeStamp, msg.sender);
        NumLevels[++iter] = address(mm);
        Levels[NumLevels[iter]] = iter;
    }

    function itersOf(address account) override external view returns (uint256)
    {
        require(Levels[msg.sender] > 0, "7");

        if(Levels[msg.sender] == 1)
            return 2**256 - 1;

        MiniMatrix mm = MiniMatrix(NumLevels[Levels[msg.sender] - 1]);
        if(mm.isUser(account))
            return 2**256 - 1;

        return 2;
    }

    function addUserToQueue(address account) override external                   
    {
        require(Levels[msg.sender] > 0, "8");
        if(Levels[msg.sender] + 1 <= iter)
        {
            MiniMatrix mm = MiniMatrix(NumLevels[Levels[msg.sender] + 1]);
            if(mm.isUser(account))
                mm.addUserToQueue(account);        
        }
    }
}