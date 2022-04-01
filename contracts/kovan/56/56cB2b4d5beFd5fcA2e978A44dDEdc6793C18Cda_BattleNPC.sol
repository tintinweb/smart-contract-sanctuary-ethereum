/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

// File: contracts/npc.sol


pragma solidity ^0.8.12;
contract BattleNPC {

    uint public prize;
    uint public cost;
    uint public damage;
    uint public crit;
    uint public parry;
    constructor(){
        prize = 100;
        cost = 50;
        damage = 175;
        crit = 12;
        parry = 12;
    }
}