// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

interface IAlternactf {
    function checkWordWithHint(string calldata word, uint8 wordIndex) external view returns (string memory);

    function checkSolution(string[] calldata words) external view returns (bool);
}

contract AlternactfProxy {
    IAlternactf private alternactf;

    constructor(address _alternactf) {
        alternactf = IAlternactf(_alternactf);
    }

    function wordOne(string calldata word) external view returns (string memory) {
        string memory hint = alternactf.checkWordWithHint(word, 0);
        return hint;
    }

    function wordTwo(string calldata word) external view returns (string memory) {
        string memory hint = alternactf.checkWordWithHint(word, 1);
        return hint;
    }

    function wordThree(string calldata word) external view returns (string memory) {
        string memory hint = alternactf.checkWordWithHint(word, 2);
        return hint;
    }

    function wordFour(string calldata word) external view returns (string memory) {
        string memory hint = alternactf.checkWordWithHint(word, 3);
        return hint;
    }

    function wordFive(string calldata word) external view returns (string memory) {
        string memory hint = alternactf.checkWordWithHint(word, 4);
        return hint;
    }

    function wordSix(string calldata word) external view returns (string memory) {
        string memory hint = alternactf.checkWordWithHint(word, 5);
        return hint;
    }

    function wordSeven(string calldata word) external view returns (string memory) {
        string memory hint = alternactf.checkWordWithHint(word, 6);
        return hint;
    }

    function wordEight(string calldata word) external view returns (string memory) {
        string memory hint = alternactf.checkWordWithHint(word, 7);
        return hint;
    }

    function checkSolution(string[] calldata words) external view returns (bool) {
        bool isCorrect = alternactf.checkSolution(words);
        return isCorrect;
    }

    fallback() external {
        revert();
    }

    receive() external payable {
        revert();
    }
}