/**
 *Submitted for verification at Etherscan.io on 2023-03-01
*/

// File: contracts/Assistance.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Assistance{

    uint256 id;
    uint256 period = 5; // Tiempo en segundos
    uint256 timer;
    address owner;
    mapping(uint256 => mapping(address => bool)) user_assistances;

    modifier isOwner(){
        require(msg.sender == owner, "you are not the owner");
        _;
    }

    constructor(){
        owner = msg.sender;
        timer = block.timestamp;
    }

    function getClass() public view returns(uint256){
        return id;
    }

    function assisted() external {
        require(!user_assistances[id][msg.sender], "you already checked this class");
        require(block.timestamp - timer <= period , "time is over");
        user_assistances[id][msg.sender] = true;
    }

    function createClass() external isOwner() {
        timer = block.timestamp;
        id++;
    }

    function checkAssistance(uint256 id_, address alumn) view public isOwner() returns(bool) {
        require(id_ <= id, "this class does not exist");
        return user_assistances[id_][alumn];
    }
}