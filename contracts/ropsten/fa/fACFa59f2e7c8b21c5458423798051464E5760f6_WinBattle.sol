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
    //address monst = address(this);
    // example block that will always win: 
    // get contract from this block : 12165540 (12165540 % 255 = 0)
    address monst = 0x96D52FFCEe0bbf2222D3a2a04d5D0EeF00A8376D;
    event monsterCreated(string monsterName);
    uint win;
    uint loss;
    event battleWins(uint wins);
    event battleLoses(uint loses);

    constructor() {
        winningMonst = EtheremonLite(monst);
    }

    function createMonster() public { 
        
        // create monster, emit name 
        winningMonst.initMonster("aew227");
        emit monsterCreated(winningMonst.getName(address(this)));
    }
        // initialize stats to check 
        // uint dice = uint(blockhash(block.number - 1));
        // dice = dice / 85;
        // uint battleRatio = 3 / 1;
    function beatOgre() public {
        // attack twice 
        uint dice = uint(blockhash(block.number - 1));
        dice = dice / 85; // Divide the dice by 85 to add obfuscation
        if (dice % 3 == 0) {
            winningMonst.battle();
        }
        win = winningMonst.getNumWins(address(this));
        emit battleWins(win);
        loss = winningMonst.getNumLosses(address(this));
        emit battleLoses(loss);
    }

}