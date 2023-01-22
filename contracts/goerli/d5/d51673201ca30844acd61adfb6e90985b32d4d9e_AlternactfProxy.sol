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

    function checkWord1(string calldata word) external view returns (string memory) {
        string memory hint = alternactf.checkWordWithHint(word, 0);
        return hint;
    }

    function checkWord2(string calldata word) external view returns (string memory) {
        string memory hint = alternactf.checkWordWithHint(word, 1);
        return hint;
    }

    function checkWord3(string calldata word) external view returns (string memory) {
        string memory hint = alternactf.checkWordWithHint(word, 2);
        return hint;
    }

    function checkWord4(string calldata word) external view returns (string memory) {
        string memory hint = alternactf.checkWordWithHint(word, 3);
        return hint;
    }

    function checkWord5(string calldata word) external view returns (string memory) {
        string memory hint = alternactf.checkWordWithHint(word, 4);
        return hint;
    }

    function checkWord6(string calldata word) external view returns (string memory) {
        string memory hint = alternactf.checkWordWithHint(word, 5);
        return hint;
    }

    function checkWord7(string calldata word) external view returns (string memory) {
        string memory hint = alternactf.checkWordWithHint(word, 6);
        return hint;
    }

    function checkWord8(string calldata word) external view returns (string memory) {
        string memory hint = alternactf.checkWordWithHint(word, 7);
        return hint;
    }

    function checkAllWords(string[] calldata words) external view returns (bool) {
        bool isCorrect = alternactf.checkSolution(words);
        return isCorrect;
    }

    fallback() external {
        revert();
    }
}