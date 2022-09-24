/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Survival {

    uint256 public round;

    struct Survivor {
        string name;
        uint256 studentId;
        uint256 power;
        uint256 kills;
        uint256 lives;
    }

    // Returns uint
    // Close  - 0
    // Open  - 1
    enum Status {
        Close,
        Open
    }

    Status public status;

    function close() public onlyOwner {
        status = Status.Close;
    }

    function open() public onlyOwner {
        status = Status.Open;
    }

    mapping(address=>Survivor) survivorList;
    mapping(address=>bool) registerStatus;
    mapping(uint256=>bool) idUsed;
    mapping(address=>bool) public godList;
    mapping(uint256=>mapping(address=>bool)) public isAction;
    address[] participants;
    address public owner;

    constructor() {
        status = Status.Close;
        owner = msg.sender;
        round = 1;
    }

    function nextRound() public onlyOwner {
        round++;
    }

    function register(
        string memory _name,
        uint256 _studentId
    ) public {

        require(status == Status.Open, "Close");
        require(registerStatus[msg.sender] == false, "This address already used.");
        require(idUsed[_studentId] == false, "This ID already used.");
        registerStatus[msg.sender] = true;

        participants.push(msg.sender);

        survivorList[msg.sender] = Survivor(
            _name, //name
            _studentId, //studentId
            random()*10**8, //power XX
            0, //kills
            3); //lives
    }

    function yourStatus() public view returns(Survivor memory) {
        return survivorList[msg.sender];
    }

    function attack(address _target) public {

        require(isAction[round][msg.sender] != true, "You're already make an action.");
        require(survivorList[msg.sender].lives > 0, "You are dead.");
        require(survivorList[_target].lives > 0, "Target is dead.");

        isAction[round][msg.sender] = true;

        if(survivorList[msg.sender].power > survivorList[_target].power) {
            survivorList[msg.sender].power /= 2;
            survivorList[_target].power /= 2;
            survivorList[msg.sender].power += survivorList[_target].power;
            survivorList[_target].lives -= 1;
        }

        else if(survivorList[msg.sender].power < survivorList[_target].power) {
            survivorList[msg.sender].power /= 2;
            survivorList[_target].power /= 2;
            survivorList[_target].power += survivorList[msg.sender].power;
            survivorList[msg.sender].lives -= 1;
        }

        else {
            survivorList[msg.sender].power /= 2;
            survivorList[_target].power /= 2;
            survivorList[msg.sender].lives -= 1;
            survivorList[_target].lives -= 1;
        }
    }

    function powerUp() public {
        require(isAction[round][msg.sender] != true, "You're already make an action.");
        require(survivorList[msg.sender].lives > 0, "You are dead.");
        isAction[round][msg.sender] = true;
        survivorList[msg.sender].power += random()*10**8;
    }

    function heal() public {
        require(isAction[round][msg.sender] != true, "You're already make an action.");
        require(survivorList[msg.sender].lives > 0, "You are dead.");
        isAction[round][msg.sender] = true;
        survivorList[msg.sender].lives += 1;
    }

    function showList() public view returns(address[] memory){
        return(participants);
    }


    function random() public view returns(uint){
        uint number = uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,msg.sender))) % 100;

        if (number >= 10) {
            return number;
        }
        else {
            return 10;
        }
    }

    function revive() public onlyGod {
        survivorList[msg.sender].lives = 1;
    }

    receive() external payable {
        godList[msg.sender] = true;
    }

    modifier onlyGod {
        require(godList[msg.sender] == true, "You are not god.");
        _;
    }

    modifier onlyOwner {
        require(owner == msg.sender, "You are not owner.");
        _;
    }
}