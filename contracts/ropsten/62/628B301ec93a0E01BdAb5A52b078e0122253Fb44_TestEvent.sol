/**
 *Submitted for verification at Etherscan.io on 2022-02-22
*/

pragma solidity ^0.8.0;

contract TestEvent {
    uint256 id;

    event ChangeId(address indexed from, uint256 oldId, uint256 newId);

    constructor (uint256 id_) {
        id = id_;
    }

    function changeId(uint256 newId_) public {
        uint256 oldId = id;
        id = newId_;
        emit ChangeId(msg.sender, oldId, newId_);
    }

    function getInput(uint256 input_) public pure returns (uint256) {
        return input_;
    } 
}