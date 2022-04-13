/**
 *Submitted for verification at Etherscan.io on 2022-04-12
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
    // Placeholder; TODO for Q2   

    EtheremonLite winningMonst;
    address monst = 0x3be82246fF8Df285029786Ed28D0bDb55544B0c6; //0x96D52FFCEe0bbf2222D3a2a04d5D0EeF00A8376D;
    event monsterCreated(string monsterName);
    event diceNum(uint dice);

    constructor() {
        winningMonst = EtheremonLite(monst);
    }

    function beatOgre() public returns(bool) {
        
        // create monster, emit name 
        winningMonst.initMonster("aew227");
        emit monsterCreated(winningMonst.getName(address(this)));
        
        // attack twice 
        uint dice = uint(blockhash(block.number - 1));
        emit diceNum(dice);
        if ((dice / 85) % 3 == 0) {
            return winningMonst.battle();
        } 
        else {
            return false;
        }
    }
}