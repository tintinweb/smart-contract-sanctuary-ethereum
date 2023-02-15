// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Ownable.sol";

contract Wordl3 is Ownable {

    uint8[5] private word;
    uint256 public endTime;
    mapping(address => uint8) public attemptsToday;
    mapping(address => bool) public won;
    mapping(address => uint256) public lastAttempt;
    mapping(address => uint256[]) public record;

    event guessed(address indexed player, uint8[5] guess, uint8[5] result, uint256 attempts, bool won);

    function setWord(uint8[5] calldata letters) public onlyOwner {
        endTime = block.timestamp + 86400;
        word = letters;
    }

    function guess(uint8[5] calldata letters) external returns(uint8[5] memory) {
        require(block.timestamp < endTime, "No Active Game");
        
        if(lastAttempt[_msgSender()] < endTime - 86400) {
            won[_msgSender()] = false;
            attemptsToday[_msgSender()] = 0;
        }
        require(!won[_msgSender()], "Already Won");
        require(attemptsToday[_msgSender()] < 6, "Can only attempt 6 times/day");

        lastAttempt[_msgSender()] = block.timestamp;
        attemptsToday[_msgSender()] += 1;

        uint8[5] memory result = check(letters);

        if(occurences(result, 1) == 5){
            won[_msgSender()] = true;
            record[_msgSender()].push(attemptsToday[_msgSender()]);
        }

        emit guessed(_msgSender(), letters, result, attemptsToday[_msgSender()], won[_msgSender()]);

        return result;
    }

    function check(uint8[5] calldata letters) private view returns(uint8[5] memory) {
        uint8[5] memory results = [0, 0, 0, 0, 0];
        uint8[26] memory accounted = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ,0 ,0];

        for(uint i = 0; i < word.length; i++) {
            if(letters[i] == word[i] && accounted[letters[i]] < occurences(word, letters[i])) {
                results[i] = 1;
                accounted[letters[i]]++;
            } else if(includes(word, letters[i])){
                if(accounted[letters[i]] < occurences(word, letters[i])){
                    accounted[letters[i]]++;
                    results[i] = 2;
                } else {
                    results[i] == 0;
                }
            } else {
                results[i] = 0;
            }
        }

        return results;
    }

    function includes(uint8[5] memory baseArray, uint value) public pure returns(bool) {
        for(uint i = 0; i < baseArray.length; i++) {
            if(baseArray[i] == value) {
                return true;
            }
        }

        return false;
    }

    function occurences(uint8[5] memory baseArray, uint value) public pure returns(uint) {
        uint occurs= 0;
        for(uint i = 0; i < baseArray.length; i++) {
            if(baseArray[i] == value) {
                occurs++;
            }
        }

        return occurs;
    }
}