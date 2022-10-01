// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Journey {

    //A human is locked in a room with no escape! There is 1 door with a 5 digit passcode needed to unlock the door. 
    //Find the passcode and unlock the door

    //Address of the deployer of the contract
    address public owner;

    //Rabdom uint256 values
    uint256 public flaskInWater = 7;
    uint256 public dieInTog = 9;
    uint256 public noDogAnywhere = 4;

    //Store how many humans have been created
    uint256 public numberOfHumans = 0;

    //Answer to the riddle
    uint256 private answer;
    
    //Mappings holding values needed for solving the passcode
    mapping(uint256 => uint256) public passCode;
    mapping(uint256 => uint256) public pastPlayersAge;
    mapping(string => uint256) public humansNameToPosition;
    mapping(uint256 => Human) public humans;

    //Enum to store if a user human is alive or dead
    enum ALIVE_STATUS{
        ALIVE,
        DEAD
    }

    //Data structure to hold information about a human
    struct Human {
        string name;
        uint256 age;
        uint256 timeSpentInRoom;
        ALIVE_STATUS status;
    }

    //Called on creation of the contract
    constructor(){
        owner = msg.sender;
    }

    //Creating a human
    //Only callable by deployer of contract
    function createHuman(string memory _name, uint256 _age, uint256 _timeSpentInRoom, ALIVE_STATUS _status) public onlyOwner(msg.sender) {
        humans[numberOfHumans] = Human({
            name: _name,
            age: _age,
            timeSpentInRoom: _timeSpentInRoom,
            status: _status
        });

        humansNameToPosition[_name] = numberOfHumans;

        numberOfHumans++;
    }

    //Setting the answer
    //Only callable by deployer of contract
    function setAnswer(uint256 _answer) public {
        answer = _answer;
    }

    //Call to get clue 1
    function getClueOne() public pure returns (string memory) {
        return "Your first digit in the passcode is hiding in 1 of the variables";
    }

    //Call to get clue 2
    function getClueTwo() public pure returns (string memory) {
        return "Your first passcode digit is the KEY to understanding who played before you and their age";
    }

    //Call to get clue 3
    function getClueThree() public pure returns (string memory) {
        return "The time spent in the room for john";
    }

    //Call to get clue 4
    function getClueFour() public pure returns (string memory) {
        return "The ID of the only dead human";
    }

    //Call to get clue 5
    function getClueFive() public pure returns (string memory) {
        return "The amount of bytes used in state variable storage";
    }

    //Getting a position of a human in the corresponding mapping based on name
    function getHumanPosition(string memory _name) public view returns (uint256) {
        return humansNameToPosition[_name];
    }

    //Getting all a humans information based on its ID
    function getHuman(uint256 _position) public view returns (Human memory) {
        return humans[_position];
    }
    
    //Call to check your answer
    function checkAnswer() public view returns (string memory){

        uint256 total;

        for(uint256 x = 0; x < 7; x++){
            total += passCode[x];
        }

        if(answer == total){
            return "YOU WIN";
        }else{
            return "YOU LOSE";
        }

    }

    //There are 5 positions in the passcode mapping
    //Add your answer to each clue in the relative order
    //EXAMPLE: clue 1 answer is 12, _digit will = 12 and _position will = 0
    function addDigit(uint256 _digit, uint256 _position) public {
        passCode[_position] = _digit;
    }

    //Modifier to make sure certain functions can only be called by deployer
    modifier onlyOwner(address _sender){
        require(_sender == owner, "Only Owner");
        _;
    }

}