pragma solidity ^0.8.11;


contract Score {

    mapping(address => uint8) score;
    mapping(address => bool) public teachers;
    address owner;
    uint256 teachersNum;

    constructor() {
        teachers[address(new Teacher(address(this)))] = true;
        owner = msg.sender;
    }

    modifier _teacherOnly() {
        require(teachers[msg.sender], "onlyTeacher do it");
        _;
    }

    modifier _ownerOnly() {
        require(msg.sender == owner);
        _;
    }

    function add(address student, uint8 num) external _teacherOnly {
        require(score[student] + num <= 100, "can not be less 100");
        score[student] += num;
    }

    function sub(address student, uint8 num) external _teacherOnly {
        score[student] -= num;
    }

    function addTeacher() public _ownerOnly {
        teachers[address(new Teacher(address(this)))] = true;
        teachersNum++;
    }

    function removeTeacher(address teacher) public _ownerOnly {
        if (teachers[teacher]) {
            teachers[teacher] = false;
            teachersNum--;
        }
    }
}


interface IScore {
    function add(address student, uint8 num) external;

    function sub(address student, uint8 num) external;
}


contract Teacher {
    IScore score;

    constructor(address _score) {
        score = IScore(_score);
    }

    function add(address student, uint8 num) external {
        score.add(student, num);
    }

    function sub(address student, uint8 num) external {
        score.sub(student, num);
    }
}