// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

interface IScore {    
    function updateScore(address student, uint256 score) external;
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

import "./IScore.sol";

contract Score is IScore {
    
    mapping (address=>uint256) public scores;

    address public teacher;

    address public owner;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyTeacher(){
        require(msg.sender == teacher, "Not Teacher");
        _;
    }

    function updateScore(address student, uint256 score) external onlyTeacher{
        require(score >= 0 && score <= 100, "Score entered incorrectly");
        scores[student] = score;
    }

    function setTeacher(address _teacher) external {
        require(msg.sender == owner, "Not Owner");
        teacher = _teacher;
    }

}