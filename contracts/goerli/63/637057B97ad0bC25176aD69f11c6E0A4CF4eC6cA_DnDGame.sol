/**
 *Submitted for verification at Etherscan.io on 2023-03-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DnDGame {

    struct Character {
        string name;
        uint level;
        uint experience;
        uint health;
        uint strength;
        uint defense;
    }

    struct Quest {
        string name;
        uint difficulty;
        uint reward;
        uint monsterLevel;
    }

    mapping(address => Character) public characters;
    Quest[] public quests;

    event NewCharacter(address player, string name);
    event NewQuest(string name, uint difficulty, uint reward, uint monsterLevel);

    constructor() {
        // initial quests
        quests.push(Quest("Pest Control - Clear out rats.", 1, 1000, 10));
        quests.push(Quest("Wolf Hunt - Track down wolves.", 5, 100000, 50));
        quests.push(Quest("Theives Den - Kill theives.", 10, 100000, 75));
    }

    function createCharacter(string memory _name) public {
        require(characters[msg.sender].level == 0, "You already have a character!");
        characters[msg.sender] = Character(_name, 1, 0, 100, 10, 5);
        emit NewCharacter(msg.sender, _name);
    }

    function startQuest(uint _questIndex) public {
        require(characters[msg.sender].level >= quests[_questIndex].difficulty, "You are not high enough level to attempt this quest!");
        require(characters[msg.sender].health > 0, "You are dead and cannot go on quests!");
        uint monsterLevel = quests[_questIndex].monsterLevel;
        uint reward = quests[_questIndex].reward;
        characters[msg.sender].experience += reward;
        if (characters[msg.sender].level * 2 < monsterLevel) {
            characters[msg.sender].health = 0;
            return;
        }
        bool won = battle(characters[msg.sender].strength, characters[msg.sender].defense, monsterLevel);
        if (won) {
            characters[msg.sender].level += 1;
            characters[msg.sender].health = 100;
            characters[msg.sender].strength += 2;
            characters[msg.sender].defense += 1;
        } else {
            characters[msg.sender].health = 0;
        }
    }

    function addQuest(string memory _name, uint _difficulty, uint _reward, uint _monsterLevel) public {
        quests.push(Quest(_name, _difficulty, _reward, _monsterLevel));
        emit NewQuest(_name, _difficulty, _reward, _monsterLevel);
    }

    function battle(uint _playerStrength, uint _playerDefense, uint _monsterLevel) internal pure returns (bool) {
        uint totalStrength = _playerStrength + _playerDefense;
        uint monsterStrength = _monsterLevel * 3;
        if (totalStrength > monsterStrength) {
            return true;
        } else {
            return false;
        }
    }

    function bury() public {
    require(characters[msg.sender].level > 0, "You do not have a character!");
    delete characters[msg.sender];
}

}