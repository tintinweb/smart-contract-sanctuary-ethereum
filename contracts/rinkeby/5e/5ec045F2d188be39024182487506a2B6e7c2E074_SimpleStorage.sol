// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 currentChapter;

    struct Learners {
        uint256 currentChapter;
        string learner;
    }

    // uint256[] public anArray;
    Learners[] public learners;

    mapping(string => uint256) public learnerToCurrentChapter;

    function store(uint256 _currentChapter) public {
        currentChapter = _currentChapter;
    }

    function retrieve() public view returns (uint256) {
        return currentChapter;
    }

    function addLearner(string memory _learner, uint256 _currentChapter)
        public
    {
        learners.push(Learners(_currentChapter, _learner));
        learnerToCurrentChapter[_learner] = _currentChapter;
    }
}