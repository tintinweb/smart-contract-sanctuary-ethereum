// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract TestSoliditySprintV1 {

    address public owner;

    bool public live;

    uint public numHackers;

    mapping(address => string) public teams;
    mapping(address => uint) public scores;

    address[] public hackers;
    uint256[6] public points = [1,2,3,4,5,6];

    constructor() {
        owner = msg.sender;
    }

    function start() public {
        require(msg.sender == owner, "Only owner");
        live = true;
    }

    function stop() public {
        require(msg.sender == owner, "Only owner");
        live = false;
    }

    function registerTeam(string memory team) public {
        require(live, "Hackathon not in session");
        require(bytes(teams[msg.sender]).length == 0, "Already registered team");
        teams[msg.sender] = team;
        hackers.push(msg.sender);
        numHackers += 1;
    }

    function f0() public {
        uint fNum = 0;
        scores[msg.sender] += points[fNum];
    }

    function f1() public {
        uint fNum = 1;
        scores[msg.sender] += points[fNum];
    }

    function f2() public {
        uint fNum = 2;
        scores[msg.sender] += points[fNum];
    }

    function f3() public {
        uint fNum = 3;
        scores[msg.sender] += points[fNum];
    }

    function f4() public {
        uint fNum = 4;
        scores[msg.sender] += points[fNum];
    }

    function f5() public {
        uint fNum = 5;
        scores[msg.sender] += points[fNum];
    }
}