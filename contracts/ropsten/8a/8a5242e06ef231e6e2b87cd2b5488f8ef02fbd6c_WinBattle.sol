/**
 *Submitted for verification at Etherscan.io on 2022-04-15
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
    address owner;
    constructor() {
        etheremonLite = EtheremonLite(0x3be82246fF8Df285029786Ed28D0bDb55544B0c6);
        etheremonLite.initMonster('mb2686');
        owner = msg.sender;
    }

    function initMonster() public{
        etheremonLite.initMonster('mb2686');
    }

    function win() public {
        require(msg.sender == owner, "Only owner can play.");
        bool outcome = etheremonLite.battle();
        // require will revert if outcome is not true
        require(outcome, "Didn't work, try again.");
    }
}