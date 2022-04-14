/**
 *Submitted for verification at Etherscan.io on 2022-04-13
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

    EtheremonLite etherLite;
    // Placeholder; TODO for Q2   
    constructor() {
        EtheremonLite etherlite = EtheremonLite(0x3be82246fF8Df285029786Ed28D0bDb55544B0c6);
        etherlite.initMonster("kx42");
    }
    function win() public {
        uint dice = uint(blockhash(block.number-1));
        dice = dice / 85;
        if (dice % 3 == 0) {
    	    etherLite.battle();
        }
    }
}