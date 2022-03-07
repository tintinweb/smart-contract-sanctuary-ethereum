pragma solidity ^0.8.11;


contract Score {

    mapping(address => uint8) score;
    address teacher;
    address owner;

    constructor() {
        teacher = address(new Teacher(address(this)));
        owner = msg.sender;
    }

    modifier _teacherOnly() {
        require(msg.sender == teacher, "onlyTeacher do it");
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