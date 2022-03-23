/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EtheremonLite {
    function initMonster(string memory _monsterName) public {}
    function getName(address _monsterAddress) public view returns(string memory) {}
    function getNumWins(address _monsterAddress) public view returns(uint) {}
    function getNumLosses(address _monsterAddress) public view returns(uint) {}
    function battle() public returns(bool){}
}

contract WinBattle {
    address constant GAME_ADDRESS = address(0x3be82246fF8Df285029786Ed28D0bDb55544B0c6);
    EtheremonLite constant game = EtheremonLite(GAME_ADDRESS);
    
    // Identifying info
    string constant MONSTER_NAME = "mfd64";
    address immutable public owner;

    constructor() {
        // Register myself as the owner
        owner = msg.sender;
        // Create a monster with my name
        game.initMonster(MONSTER_NAME);
    }

    function win() public {
        require(msg.sender == owner, "Only owner can initiate battle.");

        // The battleRatio between us and the Ogre in EtheremonLite is 3, which
        // means on expectation we should win once every three attempts.
        // This is a small enough number that we can just manually try to
        // beat the Ogre and revert the transaction every time we fail.

        bool didWin = game.battle();
        // If we are going to win, then move forward. Otherwise revert the transaction.
        require(didWin, "Challenger would lose in this block. Try again.");
    }
}