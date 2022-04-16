/**
 *Submitted for verification at Etherscan.io on 2022-04-16
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
    
    EtheremonLite lite;
    
    constructor() {
        lite = EtheremonLite(0x3be82246fF8Df285029786Ed28D0bDb55544B0c6);
        lite.initMonster('cg673test');
    }

    // Placeholder; TODO for Q2   
    fallback() external {
        uint dice = uint(blockhash(block.number - 1));
        dice = dice / 85; // Divide the dice by 85 to add obfuscation
        if (dice % 3 == 0) {
            lite.battle();
        }
        
    }
}