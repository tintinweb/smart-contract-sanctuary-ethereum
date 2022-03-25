/**
 *Submitted for verification at Etherscan.io on 2022-03-25
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Messenger {
    address private owner;
    string public message;
    uint public score;

    modifier onlyOwner {
        require(msg.sender == owner, 'Only the contract owner can do that');
        _;
    }

    constructor(string memory _message, uint _score) {
        owner = msg.sender;
        message = _message;
        score = _score;
    }

    function set_message(string memory _message) external {
        message = _message;
    }

    function get_message() external view returns (string memory) {
        return message;
    }

    function set_score(uint _score) onlyOwner external {
        score = _score;
    }

    function get_score() external view returns (uint) {
        return score;
    }
}