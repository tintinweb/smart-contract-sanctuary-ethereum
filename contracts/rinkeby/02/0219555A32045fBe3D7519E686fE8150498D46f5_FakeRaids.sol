/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

pragma solidity 0.8.7;

contract FakeRaids {

    mapping (uint256 => Raid) public locations;

    uint256 public constant HND_PCT = 10_000;

    struct Raid {
        uint16 minLevel;  uint16 maxLevel;  uint16 duration; uint16 cost;
        uint16 grtAtMin;  uint16 grtAtMax;  uint16 supAtMin; uint16 supAtMax;
        uint16 regReward; uint16 grtReward; uint16 supReward;uint16 minPotions; uint16 maxPotions; // Rewards are scale down to 100(= 1BS & 1=0.01) to fit uint16. 
    } 

    constructor() {
         Raid memory crookedCrabBeach = Raid({ minLevel:  5, maxLevel: 5,  duration:  48, cost: 60, grtAtMin: 0, grtAtMax: 0, supAtMin: 400, supAtMax: 400, regReward: 100, grtReward: 100, supReward: 3000, minPotions: 0, maxPotions: 0});
        Raid memory twistedPirateCove = Raid({ minLevel:  15, maxLevel: 25,  duration:  30, cost: 45, grtAtMin: 0, grtAtMax: 0, supAtMin: 200, supAtMax: 400, regReward: 100, grtReward: 100, supReward: 2000, minPotions: 0, maxPotions: 0});
        Raid memory warpedSpiderDen = Raid({ minLevel:  25, maxLevel: 35,  duration:  72, cost: 110, grtAtMin: 1000, grtAtMax: 1500, supAtMin: 0, supAtMax: 500, regReward: 200, grtReward: 1000, supReward: 3000, minPotions: 0, maxPotions: 1});
        Raid memory toxicQuagmire = Raid({ minLevel:  45, maxLevel: 45,  duration:  96, cost: 195, grtAtMin: 0, grtAtMax: 0, supAtMin: 0, supAtMax: 0, regReward: 900, grtReward: 900, supReward: 900, minPotions: 1, maxPotions: 1});
        Raid memory evilMerfolkCastle = Raid({ minLevel:  50, maxLevel: 75,  duration:  144, cost: 275, grtAtMin: 1500, grtAtMax: 3000, supAtMin: 200, supAtMax: 1500, regReward: 1000, grtReward: 1600, supReward: 2400, minPotions: 3, maxPotions: 3});

        Raid memory werewolf = Raid({ minLevel:  90, maxLevel: 90,  duration:  144, cost: 90, grtAtMin: 1500, grtAtMax: 2500, supAtMin: 500, supAtMax: 1500, regReward: 300, grtReward: 500, supReward: 1000, minPotions: 0, maxPotions: 4});
        Raid memory frenziedSpiderlord = Raid({ minLevel:  100, maxLevel: 125,  duration:  144, cost: 240, grtAtMin: 1500, grtAtMax: 2500, supAtMin: 500, supAtMax: 1500, regReward: 800, grtReward: 1600, supReward: 2800, minPotions: 2, maxPotions: 4});       
        Raid memory leviathan = Raid({ minLevel:  150, maxLevel: 175,  duration:  192, cost: 365, grtAtMin: 1500, grtAtMax: 2500, supAtMin: 500, supAtMax: 1500, regReward: 1000, grtReward: 2600, supReward: 6000, minPotions: 3, maxPotions: 5});
        Raid memory lavaTitan = Raid({ minLevel:  190, maxLevel: 200,  duration:  216, cost: 275, grtAtMin: 1500, grtAtMax: 2500, supAtMin: 500, supAtMax: 2000, regReward: 1200, grtReward: 1800, supReward: 2600, minPotions: 6, maxPotions: 6});

        locations[10] = crookedCrabBeach;
        locations[11] = twistedPirateCove;
        locations[12] = warpedSpiderDen;
        locations[13] = toxicQuagmire;
        locations[14] = evilMerfolkCastle; 
        locations[15] = werewolf;
        locations[16] = frenziedSpiderlord;
        locations[17] = leviathan;
        locations[18] = lavaTitan;
    }

    function _getReward(uint256 raidId, uint256 orcLevel, uint256 ramdom) external view returns(uint176 reward) {
        Raid memory raid = locations[raidId];
        
        uint256 rdn = ramdom % 10_000 + 1;

        uint256 greatProb  = _getBaseOutcome(raid.minLevel, raid.maxLevel, raid.grtAtMin, raid.grtAtMax, orcLevel) + _getLevelBonus(raid.maxLevel, orcLevel);
        uint256 superbProb = _getBaseOutcome(raid.minLevel, raid.maxLevel, raid.supAtMin, raid.supAtMax, orcLevel);

        reward = uint176(rdn <= superbProb ? raid.supReward  : rdn <= greatProb + superbProb ? raid.grtReward : raid.regReward) * 1e16;
    }

    function _getBaseOutcome(uint256 minLevel, uint256 maxLevel, uint256 minProb, uint256 maxProb, uint256 orcishLevel) internal pure returns(uint256 prob) {
        orcishLevel = orcishLevel > maxLevel ? maxLevel : orcishLevel;
        prob = minProb + ((orcishLevel - minLevel) * (maxProb - minProb)/(maxLevel == minLevel ? 1 : (maxLevel - minLevel))) ;
    }

    function _getLevelBonus(uint256 maxLevel, uint256 orcishLevel) internal pure returns (uint256 prob){
        if(orcishLevel <= maxLevel) return 0;
        if (orcishLevel <= maxLevel + 20) return ((orcishLevel - maxLevel) * HND_PCT / 20 * 500) / HND_PCT;
        prob = 500;
    }
}