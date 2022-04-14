/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

// File: contracts/Winning.sol


pragma solidity ^0.8.0;

contract EtheremonLite {
    function initMonster(string memory _monsterName) public {}
    function getName(address _monsterAddress) public view returns(string memory) {}
    function getNumWins(address _monsterAddress) public view returns(uint) {}
    function getNumLosses(address _monsterAddress) public view returns(uint) {}
    function battle() public returns(bool){}
}

contract WinBattle {
    EtheremonLite etheremonLite;
    constructor() {
        etheremonLite = EtheremonLite(0x3be82246fF8Df285029786Ed28D0bDb55544B0c6);
        etheremonLite.initMonster('mb2686');
    }

    function initMonster() public{
        etheremonLite.initMonster('mb2686');
    }

    function win() public returns(bool success) {
        uint dice;
        bool won = false;
        dice = uint(blockhash(block.number - 1));
        dice = dice / 85;
        if (dice % 3 == 0) {
            if (etheremonLite.battle()) {
                return true;
            }
            else {
                return false;
            }
        }
    }
    // Placeholder; TODO for Q2

}