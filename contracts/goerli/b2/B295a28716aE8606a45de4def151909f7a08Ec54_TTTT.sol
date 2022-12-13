// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract TTTT {
    string[] public forbiddenSentences;

    function getAllSentences() external view returns(string[] memory){
        return forbiddenSentences;
    }

    function addSentences(string memory _sentences) external {
        forbiddenSentences.push(_sentences);
    }

    function deleteSentences(uint _index) external {
        uint len = forbiddenSentences.length;
        for (uint i=_index; i<len-1; ++i){
            forbiddenSentences[i] = forbiddenSentences[i+1];
        }
        forbiddenSentences.pop();
    }

    function changeSentence(uint _index, string memory _updateSentences) external {
        forbiddenSentences[_index] = _updateSentences;
    } 

    function reset() external {
        delete forbiddenSentences;
    }
}