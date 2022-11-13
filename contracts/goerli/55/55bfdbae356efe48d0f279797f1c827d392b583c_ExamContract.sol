/**
 *Submitted for verification at Etherscan.io on 2022-11-13
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.17;

contract ExamContract {
    struct Answer {
        uint index;
        string phase;
        // string password;
    }
    mapping(uint256 => bytes32) answers;
    mapping(address => uint256[]) public questions;
    // address owner;

    // modifier onlyOwner {
    //     require(msg.sender == owner);
    //     _;
    // }

    // constructor () {
    //     owner = msg.sender;
    // }

    // insert answer at _input
    function input (uint _index, string memory _phase, string memory _choice) public {
        bytes32 _inputEntropy = keccak256(abi.encodePacked(msg.sender, _index, _phase));
        uint256 _nonce = uint256(_inputEntropy);
        answers[_nonce] = keccak256(abi.encodePacked(_choice));
        questions[msg.sender].push(_nonce);
    }

    function getAnswer (uint _index, string memory _phase) public view returns(bytes32) {
        return answers[uint256(keccak256(abi.encodePacked(msg.sender, _index, _phase)))];
    }

    function lookupAnswers () public view returns(uint256[] memory) {
        return questions[msg.sender];
    }
}