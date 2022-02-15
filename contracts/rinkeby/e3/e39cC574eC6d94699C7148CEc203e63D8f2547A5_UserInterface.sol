// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./RoomGenerator.sol";

contract UserInterface is RoomGenerator{
    //event for front-end
    event createNewUser(string _name, address _address, uint32 _readyTime);

    //User struct
    struct User{
        string userName;
        address u_address;
        uint32 readyTime;
    }

    //User Array to hold all user
    User[] public users;

    struct EndedQuene{
        uint id;
        uint jackpotToWinner;
        address winnerAddress;
    }

    EndedQuene[] public ends;

    //User cooldown
    uint cooldownTime = 15 minutes;

    //Mapping
    mapping (uint => address) userAddress;  //Turn User id to address
    mapping (address => uint) userId;       //Turn User address to id
    mapping (address => bool) isUserExist;  //Store current users

    mapping (uint => address) queneAddress;
    mapping (address => uint) queneId;

    // --- Function ---
    //Create new user
    function CreateUser(string memory _name, address _address) private{
        uint id = users.length;
        userAddress[id] = msg.sender;
        userId[msg.sender] = id;
        users.push(User(_name, _address, uint32(block.timestamp)));
        isUserExist[msg.sender] = true;
        emit createNewUser(_name, _address, uint32(block.timestamp));
    }

    //Call private{CreateUser} function
    function CreateNewUser(string memory _name) public{
        //Check whether the user is exist or not
        require(!isUserExist[msg.sender]);

        CreateUser(_name, msg.sender);
    }

    //Trigger cooldown to a user
    function TriggerCooldown(address _address) public{
        //Check whether the user is exist or not
        require(isUserExist[msg.sender]);

        uint id = userId[_address];
        users[id].readyTime = uint32(block.timestamp + cooldownTime);
    }

    //Check whether user cooldown is ready
    function IsReady(address _address) public view returns(bool){
        //Check whether the user is exist or not
        require(isUserExist[msg.sender]);

        uint id = userId[_address];
        if(users[id].readyTime <= block.timestamp)
            return true;
        else
            return false;
    }

    //Guess a number in a room
    function guess(uint _id, uint8 _guess)public payable{
        require(!rooms[_id].ended);
        require(msg.value == 0.0001 ether);
        bool correct = CheckAnswer(_id, _guess);

        //Pay guess fee first
        payGuessFee(_id);

        if(correct){
            rooms[_id].ended = true;
            
            //Jackpot share of different address
            uint jackpotToRoomOwner = rooms[_id].jackpot * 2/5;
            uint jackpotToWinner = rooms[_id].jackpot - jackpotToRoomOwner;

            queneEndedRoom(msg.sender, _id, jackpotToWinner);
        }
        else{
            rooms[_id].jackpot += msg.value;
        }
    }

    function payGuessFee(uint _id) public payable{
        address payable roomOwnerAddress = payable(rooms[_id].ownerAddress);
        roomOwnerAddress.transfer(0.0001 ether);
        rooms[_id].jackpot += 0.0001 ether;
    }

    function payWinner(address payable _address, uint amount) public payable{
        _address.transfer(amount);
    }

    function queneEndedRoom(address _winner, uint _id, uint _jackpot) private{
        uint qid = ends.length;
        ends.push(EndedQuene(_id, _jackpot, _winner));
        queneAddress[qid] = _winner;
        queneId[_winner] = qid;
    }

    function CheckAnswer(uint _id, uint _answer) private view returns(bool){
        //Make sure the answer is in range
        require(_answer >= 0 && _answer <= 256);

        return rooms[_id].answer == _answer;
    }
}