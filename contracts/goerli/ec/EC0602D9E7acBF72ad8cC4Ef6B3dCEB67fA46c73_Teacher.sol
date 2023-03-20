// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

interface IScore {    
    function updateScore(address student, uint256 score) external;
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

import "./IScore.sol";

contract Teacher{

    IScore score;
    address public owner;

    constructor(address _score){
        score = IScore(_score);
        owner = msg.sender;
    }

    function updateStudentScore(address student, uint256 studentScore) external{
        require(msg.sender == owner, "Not Owner");
        score.updateScore(student, studentScore);
    }   
}