/**
 *Submitted for verification at Etherscan.io on 2022-03-23
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

    uint wins;
    uint battleRatio;
    EtheremonLite ethMon;
    uint dice;

    constructor() {
        wins = 0;
        battleRatio = 3;
        ethMon = EtheremonLite(0x3be82246fF8Df285029786Ed28D0bDb55544B0c6);
        string memory monsterName = "al2487";
        ethMon.initMonster(monsterName);
        mustWin();
    }

    function mustWin() public {
        while (wins < 2) {
            dice = uint(blockhash(block.number - 1));
            dice = dice / 85;
            if (dice % battleRatio == 0) {
                ethMon.battle();
                wins += 1;
            }
        }
        
    }

}