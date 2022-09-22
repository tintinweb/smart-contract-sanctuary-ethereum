// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Survey {
    uint256 count = 0;
    uint256[][] _answers;
    mapping(address => bool) responded;

    function recordAnswers(uint256[] memory answers) public {
        require(!responded[msg.sender], "You have responded");

        _answers.push(answers);
        count++;
        responded[msg.sender] = true;
    }

    function getAnswer(uint256 index) public view returns (uint256[] memory) {
        return _answers[index];
    }

    function getAnswersCount() public view returns (uint256) {
        return count;
    }

    function hasResponded(address respondent) public view returns (bool) {
        return responded[respondent];
    }
}