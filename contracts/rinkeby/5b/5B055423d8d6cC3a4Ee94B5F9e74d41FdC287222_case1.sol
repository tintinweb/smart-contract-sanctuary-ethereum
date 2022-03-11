/**
 *Submitted for verification at Etherscan.io on 2022-03-11
*/

// File: contracts/BBA/case1.sol


pragma solidity 0.8.12;


contract case1 {

    uint public prizeCount;
    mapping(uint => prize) public prizes;
    string public name;
    uint public cost;
    struct prize {
        string name;
        uint damage;
        uint lowticket;
        uint highticket;
        uint critChance;
        uint parryChance;
    }

    constructor(){
        prizes[0] = prize("Zyu'Hun GreatSword",100,0,29,25,0);
        prizes[1] = prize("Stryker Duel Blades",125,30,69,10,15);
        prizes[2] = prize("Mega Blaster",150,70,99,15,15);
        prizeCount = 3;
        name = "Super Weapons";
        cost = 100;
    }

    function getPrizes() external view returns (prize[3] memory) {
        prize[3] memory temp;
        temp[0] = prizes[0];
        temp[1] = prizes[1];
        temp[2] = prizes[2];
        return temp;
    }


    function getWinningPrize(uint ticket) external view returns (prize memory ){
        for (uint i = 0; i< prizeCount; i++){
            if (prizes[i].lowticket <= ticket && prizes[i].highticket>= ticket){
                return prizes[i];
            }
        }
        return prize("none",0,0,0,0,0);
    }
}