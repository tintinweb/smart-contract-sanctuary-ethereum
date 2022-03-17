// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./interfaces/IMonster.sol";


contract Monster is IMonster {
    struct Monster {
        string name;
        uint256 percent;
        uint256 attack_power;
        uint256 reward;
    }
    mapping (uint8 => Monster) monsterData;
    constructor () {
        initiateMonsterData();
    }

    function initiateMonsterData() internal {
        monsterData[1].name = "bat";
        monsterData[1].percent = 85;
        monsterData[1].attack_power = 200000;
        monsterData[1].reward = 65000;
        monsterData[2].name = "wereshark";
        monsterData[2].percent = 82;
        monsterData[2].attack_power = 500000;
        monsterData[2].reward = 160000;
        monsterData[3].name = "rhinark";
        monsterData[3].percent = 78;
        monsterData[3].attack_power = 800000;
        monsterData[3].reward = 260000;
        monsterData[4].name = "lacodon";
        monsterData[4].percent = 75;
        monsterData[4].attack_power = 1000000;
        monsterData[4].reward = 325000;
        monsterData[5].name = "oliphant";
        monsterData[5].percent = 72;
        monsterData[5].attack_power = 1300000;
        monsterData[5].reward = 440000;
        monsterData[6].name = "ogre";
        monsterData[6].percent = 68;
        monsterData[6].attack_power = 1700000;
        monsterData[6].reward = 605000;
        monsterData[7].name = "werewolf";
        monsterData[7].percent = 65;
        monsterData[7].attack_power = 2000000;
        monsterData[7].reward = 740000;
        monsterData[8].name = "orc";
        monsterData[8].percent = 62;
        monsterData[8].attack_power = 2200000;
        monsterData[8].reward = 850000;
        monsterData[9].name = "cyclops";
        monsterData[9].percent = 59;
        monsterData[9].attack_power = 2500000;
        monsterData[9].reward = 1010000;
        monsterData[10].name = "gargoyle";
        monsterData[10].percent = 55;
        monsterData[10].attack_power = 2800000;
        monsterData[10].reward = 1210000;
        monsterData[11].name = "golem";
        monsterData[11].percent = 52;
        monsterData[11].attack_power = 3100000;
        monsterData[11].reward = 1410000;
        monsterData[12].name = "land dragon";
        monsterData[12].percent = 49;
        monsterData[12].attack_power = 3400000;
        monsterData[12].reward = 1620000;
        monsterData[13].name = "chimera";
        monsterData[13].percent = 45;
        monsterData[13].attack_power = 3700000;
        monsterData[13].reward = 1900000;
        monsterData[14].name = "earthworm";
        monsterData[14].percent = 42;
        monsterData[14].attack_power = 4000000;
        monsterData[14].reward = 2150000;
        monsterData[15].name = "hydra";
        monsterData[15].percent = 41;
        monsterData[15].attack_power = 4200000;
        monsterData[15].reward = 2450000;
        monsterData[16].name = "rancor";
        monsterData[16].percent = 41;
        monsterData[16].attack_power = 4700000;
        monsterData[16].reward = 2950000;
        monsterData[17].name = "cerberus";
        monsterData[17].percent = 41;
        monsterData[17].attack_power = 5000000;
        monsterData[17].reward = 3250000;
        monsterData[18].name = "titan";
        monsterData[18].percent = 39;
        monsterData[18].attack_power = 5300000;
        monsterData[18].reward = 3800000;
        monsterData[19].name = "forest dragon";
        monsterData[19].percent = 39;
        monsterData[19].attack_power = 5600000;
        monsterData[19].reward = 4300000;
        monsterData[20].name = "ice dragon";
        monsterData[20].percent = 39;
        monsterData[20].attack_power = 6000000;
        monsterData[20].reward = 4900000;
        monsterData[21].name = "undead dragon";
        monsterData[21].percent = 37;
        monsterData[21].attack_power = 15000000;
        monsterData[21].reward = 12850000;
        monsterData[22].name = "volcano dragon";
        monsterData[22].percent = 35;
        monsterData[22].attack_power = 25000000;
        monsterData[22].reward = 23000000;
        monsterData[23].name = "fire demon";
        monsterData[23].percent = 30;
        monsterData[23].attack_power = 30000000;
        monsterData[23].reward = 33000000;
        monsterData[24].name = "invisible";
        monsterData[24].percent = 15;
        monsterData[24].attack_power = 50000000;
        monsterData[24].reward = 150000000;
    }
    
    function getMonsterInfo(uint8 monsterId) external override view returns(string memory, uint256, uint256, uint256) {
        require(monsterId>0&&monsterId<25, "Monster is not registered");
        return (monsterData[monsterId].name, monsterData[monsterId].percent, monsterData[monsterId].attack_power, monsterData[monsterId].reward);
    }

    function getAllMonsters() public view returns (Monster[] memory){
        Monster[] memory monsters = new Monster[](24);
        for (uint8 i = 0; i < 24; i++) {
            Monster storage monster = monsterData[i+1];
            monsters[i] = monster;
        }
        return monsters;
    }

    function getMonsterToHunt(uint256 ap) external override view returns(uint8) {
        for(uint8 i=1;i<25;i++) {
            if(ap>monsterData[i].attack_power) return i-1;
        }
        return 0;
    } 
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMonster {
    function getMonsterInfo(uint8 monsterId) external view returns(string memory, uint256, uint256, uint256);
    function getMonsterToHunt(uint256 ap) external view returns(uint8);
}