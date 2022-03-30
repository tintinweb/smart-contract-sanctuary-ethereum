/**
 *Submitted for verification at Etherscan.io on 2022-03-30
*/

//SPDX-License-Identifier:MIT
pragma solidity >=0.6.0 <0.9.0;

contract SoccerPlayer {
    event PlayerCreation(string name, uint8 age, string position, bool rightFoot);
    struct Player {
        string name;
        uint8 age;
        string position;
        bool rightFoot;
    }

    Player[] public Players;
    mapping(address => uint256) public ownerPlayerCount;


    function createPlayer(string memory _name) public {
        Players.push(Player(_name,12,"Center",true));
        ownerPlayerCount[msg.sender]++;
        emit PlayerCreation(_name,12,"Center",true);
    }
}