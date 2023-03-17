// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Score {
    address public owner;
    mapping(address => uint) public scores;

    error ValueError();

    constructor(){
        owner = msg.sender;
    }

    function setScore(address addr, uint score) external onlyTeacher {
        if (score > 100) revert ValueError();
        scores[addr] = score;
    }

    modifier onlyTeacher(){
        require(msg.sender == owner, "this function is restricted to the Teacher");
        _;
        // will be replaced by the code of the function
    }
}

interface IScore {
    function setScore(address, uint) external;
}

contract Teacher {
    address public owner;
    address[] public scoreArray;

    constructor(){
        owner = msg.sender;
    }

    function createScore() public onlyOwner {
        Score score = new Score();
        scoreArray.push(address(score));
    }

    function setScore(address addr, uint score) public {
        IScore(address(scoreArray[scoreArray.length - 1])).setScore(addr, score);
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "this function is restricted to the owner");
        _;
        // will be replaced by the code of the function
    }

}