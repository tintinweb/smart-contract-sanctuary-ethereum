/**
 *Submitted for verification at Etherscan.io on 2022-09-26
*/

/**
 *Submitted for verification at Etherscan.io on 2022-09-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract CryptoSurvival {

    uint256 public round;
    uint256 public maxKills;
    uint256 public gods;

    struct Survivor {
        string name;
        uint256 studentId;
        uint256 power;
        uint256 kills;
        uint256 lives;
    }

    bytes32 pass;

    string[] seed = [
        "satoshi",
        "vitalik",
        "nuttakit",
        "charles",
        "garvin",
        "nick",
        "snowden",
        "john",
        "tim",
        "cz"
    ];

    // Returns uint
    // Close  - 0
    // Open  - 1
    enum Status {
        Close,
        Open
    }

    Status public regis;

    function close() public onlyOwner {
        regis = Status.Close;
    }

    function open() public onlyOwner {
        regis = Status.Open;
    }

    mapping(address=>Survivor) survivorList;
    mapping(address=>bool) registerStatus;
    mapping(uint256=>bool) idUsed;
    mapping(address=>bool) public godList;
    mapping(address=>bool) public banList;
    mapping(uint256=>mapping(address=>bool)) public isAction;
    address[] participants;
    string[] winnerList;
    address public owner;

    constructor() {
        regis = Status.Open;
        owner = msg.sender;
        godList[msg.sender] = true;
        gods++;
        round = 1;
        pass = keccak256(abi.encodePacked((seed[random()%10])));
    }

    function nextRound() public onlyOwner {
        round++;
        pass = keccak256(abi.encodePacked((seed[random()%10])));
    }

    //Just in case
    function setRound(uint i) public onlyOwner {
        round = i;
        pass = keccak256(abi.encodePacked((seed[random()%10])));
    }

    function register(
        string memory _name,
        uint256 _studentId
    ) public {

        require(regis == Status.Open, "Close.");
        require(registerStatus[msg.sender] == false, "This address already used.");
        require(idUsed[_studentId] == false, "This ID already used.");

        registerStatus[msg.sender] = true;
        idUsed[_studentId] = true;

        participants.push(msg.sender);

        survivorList[msg.sender] = Survivor(
            _name, //name
            _studentId, //studentId
            random()*10**8, //power XX
            0, //kills
            3); //lives
    }

    //Check your status.
    function yourStatus() public view returns(Survivor memory) {
        return survivorList[msg.sender];
    }

    //Look other status.
    //But you need to get into godList first.
    function godEyes(address _addr) public onlyGod view returns(Survivor memory) {
        require(round >= 5, "You can't use this move until 5th round.");
        return survivorList[_addr];
    }

    //Make your attack.
    //Kill or get kill.
    //Make sure you have a fight with someone weaker.
    function attack(address _target) public {

        require(isAction[round][msg.sender] != true, "You're already make an action.");
        require(survivorList[msg.sender].lives > 0, "You are dead.");
        require(survivorList[_target].lives > 0, "Target is dead or not exist.");
        require(banList[msg.sender] != true, "User get ban.");
        require(round >= 3, "You can't attack until 3rd round.");
        require(regis == Status.Close, "Game is not start yet.");

        isAction[round][msg.sender] = true;

        //1. After your finish your attack your power will devide by 2.
        //2. If you win the battle you will get kills point.
        //3. Your enemy will lost thier lives for 1.
        if(survivorList[msg.sender].power > survivorList[_target].power) {
            survivorList[msg.sender].power /= 2;
            survivorList[_target].lives -= 1;
            survivorList[msg.sender].kills += 1;
        }

        //Beware to battle with someone who stringer than you.
        //You will lost your power, your lives and gain their kills point for notthing.
        else if(survivorList[msg.sender].power < survivorList[_target].power) {
            survivorList[msg.sender].power /= 2;
            survivorList[_target].power /= 2;
            survivorList[msg.sender].lives -= 1;
            survivorList[_target].kills += 1;
        }
        winner();
    }

    //Increase your power once per turn.
    function powerUp() public {

        require(banList[msg.sender] != true, "User get ban.");
        require(isAction[round][msg.sender] != true, "You're already make an action.");
        require(survivorList[msg.sender].lives > 0, "You are dead.");
        require(regis == Status.Close, "Game is not start yet.");

        isAction[round][msg.sender] = true;

        survivorList[msg.sender].power += random()*10**8;
    }

    //Increase your lives once per turn.
    //But it doesn't mean you will survive if you got one turn kill.
    function heal() public {
        require(banList[msg.sender] != true, "User get ban.");
        require(isAction[round][msg.sender] != true, "You're already make an action.");
        require(survivorList[msg.sender].lives > 0, "You are dead.");
        require(regis == Status.Close, "Game is not start yet.");

        isAction[round][msg.sender] = true;
        survivorList[msg.sender].lives += 1;
    }

    //???
    function superPowerUp(bytes32 _pass) public {

        require(banList[msg.sender] != true, "User get ban.");
        require(isAction[round][msg.sender] != true, "You're already make an action.");
        require(survivorList[msg.sender].lives > 0, "You are dead.");
        require(pass == _pass, "Wrong Pass.");
        require(round >= 5, "You can't use this move until 5th round.");
        require(regis == Status.Close, "Game is not start yet.");

        isAction[round][msg.sender] = true;

        survivorList[msg.sender].power += 99*10**8;
    }

    //???
    function revive() public onlyGod {
        require(banList[msg.sender] != true, "User get ban.");
        require(survivorList[msg.sender].lives == 0, "You are alive!.");
        require(round >= 5, "You can't use this move until 5th round.");
        require(regis == Status.Close, "Game is not start yet.");
        survivorList[msg.sender].lives = 1;
    }

    //Game Changer
    function lastAttack(address[3] memory _target) public {

        require(isAction[round][msg.sender] != true, "You're already make an action.");
        require(survivorList[msg.sender].lives > 0, "You are dead.");
        require(banList[msg.sender] != true, "User get ban.");
        require(round == 10, "You can't lastAttack until 10th round.");
        require(regis == Status.Close, "Game is not start yet.");
        require(survivorList[_target[0]].lives > 0, "Target is dead or not exist.");
        require(survivorList[_target[1]].lives > 0, "Target is dead or not exist.");
        require(survivorList[_target[2]].lives > 0, "Target is dead or not exist.");

        for(uint i=0; i<3; i++) {
            //1. After your finish your attack your power will devide by 2.
            //2. If you win the battle you will get kills point.
            //3. Your enemy will lost thier lives for 1.
            if(survivorList[msg.sender].power > survivorList[_target[i]].power) {
                survivorList[msg.sender].power = survivorList[msg.sender].power * 8/10;
                survivorList[_target[i]].lives -= 1;
                survivorList[msg.sender].kills += 1;
            }

            //Beware to battle with someone who stringer than you.
            //You will lost your power, your lives and gain their kills point for notthing.
            else if(survivorList[msg.sender].power < survivorList[_target[i]].power) {
                survivorList[msg.sender].power = survivorList[msg.sender].power * 8/10;
                survivorList[_target[i]].power = survivorList[_target[i]].power * 8/10;
                survivorList[msg.sender].lives -= 1;
                survivorList[_target[i]].kills += 1;
            }

        }
        isAction[round][msg.sender] = true;
        winner();
    }

    //Do not cheat or get BAN!!.
    function ban(address _addr) public onlyOwner{
        banList[_addr] = true;
    }

    //You can check your friend address to make an attack here.
    function showList() public view returns(address[] memory){
        return(participants);
    }

    //Find max value of kills.
    //I use internal because I want to show how it work.
    //Internal Function only work in contract. 
    //You need to call it from other function in this contract.
    function calMaxKills() internal {

        for(uint i=0; i<participants.length; i++) {
            if(survivorList[participants[i]].kills > maxKills) {
                maxKills = survivorList[participants[i]].kills;
            }
        }
    }

    //Use for loop to get list of winners.
    //It could be more than one winners if they have equal total kills.
    function winner() internal {
        calMaxKills(); //We use it here.
        delete winnerList;
        for(uint i=0; i<participants.length; i++) {
            if(survivorList[participants[i]].kills == maxKills) {
                winnerList.push(survivorList[participants[i]].name);
            }
        }
    }

    function showWinner() public view returns(string[] memory) {
        return winnerList;
    }

    //Nothing is nature random in digital world. 
    //It's just some input that we already had on blockchain combine together in keccak256 function.
    //If you understand how keccak256 work and all of value of input you can predict out put so easily.
    //btw you don't have to try in this workshop. You don't have enough of time.
    function random() public view returns(uint){
        uint number = uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,msg.sender))) % 100;

        if (number >= 10) {
            return number;
        }
        else {
            return 10;
        }
    }

    //???
    receive() external payable {
        godList[msg.sender] = true;
        gods++;
    }
    //???
    modifier onlyGod {
        require(godList[msg.sender] == true, "You are not god.");
        _;
    }
    //Access Control for owner
    modifier onlyOwner {
        require(owner == msg.sender, "You are not owner.");
        _;
    }
}