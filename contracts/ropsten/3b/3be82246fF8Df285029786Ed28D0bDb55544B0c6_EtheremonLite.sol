/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EtheremonLite {
     struct Monster {
        uint weight;
        uint wins;
        uint losses;
        string name;
        bool created;
    }
    
    mapping(address => Monster) monsters;
    address Ogre;
    
    event battleResult(address chall, bool challWins);
    event monsterCreated(string monsterName, address owner);
    
    constructor() {
        Ogre = address(0xfeed);
        monsters[Ogre].wins = 0;
        monsters[Ogre].losses = 0;
        monsters[Ogre].weight = 3;
        monsters[Ogre].name = "Fearsome Ogre";
        monsters[Ogre].created = true;
    }

    
    function initMonster(string memory _monsterName) public {
        monsters[msg.sender].wins = 0;
        monsters[msg.sender].losses = 0;
        monsters[msg.sender].weight = 1;
        monsters[msg.sender].name = _monsterName;
        monsters[msg.sender].created = true;
        emit monsterCreated(_monsterName, msg.sender);
    }
    
    
    function getName(address _monsterAddress) public view returns(string memory) {
        return monsters[_monsterAddress].name;
    }
    
    function getNumWins(address _monsterAddress) public view returns(uint) {
        return monsters[_monsterAddress].wins;
    }
    
    function getNumLosses(address _monsterAddress) public view returns(uint) {
        return monsters[_monsterAddress].losses;
    }
    
    function battle() public returns(bool){
        address challenger = msg.sender;
        require(monsters[challenger].created  && monsters[Ogre].created);
        bool challengerWins = false;
        uint battleRatio = monsters[Ogre].weight / monsters[challenger].weight;
        uint dice = uint(blockhash(block.number - 1));
        dice = dice / 85; // Divide the dice by 85 to add obfuscation
        if (dice % battleRatio == 0) {
            monsters[challenger].wins += 1;
            monsters[Ogre].losses += 1;
            challengerWins = true;
        }
        else {
            monsters[challenger].losses += 1;
            monsters[Ogre].wins += 1;
        }
        emit battleResult(challenger, challengerWins);
        return challengerWins;
    }
    
}