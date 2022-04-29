// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract MetaAndMagic {

    uint256 constant public precision = 1e12;

    address heroesAddress;
    address itemsAddress;

    uint256 public currentBoss;

    mapping(uint256 => Heroes) public heroes;
    mapping(uint256 => Boss)   public bosses;
    mapping(bytes32 => Fight)  public fights;     

    mapping(uint256 => uint256) public requests;  
    mapping(uint256 => uint256) public prizeValues;
    mapping(uint256 => address) public prizeTokens;

    // Oracle information
    address VRFcoord;
    uint64  subId;
    bytes32 keyhash;

     /*///////////////////////////////////////////////////////////////
                            DATA STRUCTURES
    //////////////////////////////////////////////////////////////*/

    struct Heroes { address owner; uint16 lastBoss; uint32 highestScore;}

    struct Fight  { uint16 heroId; uint16 boss; bytes10 items; uint32 start; uint32 count; bool claimedScore; bool claimedBoss; }
    
    struct Boss   { bytes8 stats; uint16 topScorers; uint56 highestScore; uint56 entries; uint56 winIndex; }

    struct Combat { uint256 hp; uint256 phyDmg; uint256 mgkDmg; uint256 phyRes; uint256 mgkRes; }

    enum Stat { HP, PHY_DMG, MGK_DMG, MGK_RES, MGK_PEN, PHY_RES, PHY_PEN, ELM }

    event FightResult(address sender, uint256 hero, uint256 boss, bytes10 items, uint256 score, bytes32 id);


    /*///////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
        @dev Initialize contract 
    */
    function initialize(address heroes_, address items_) external {
        require(msg.sender == _owner());

        heroesAddress = heroes_;
        itemsAddress  = items_;
    }

    /**
        @dev Initialize oracle information 
    */
    function setUpOracle(address vrf_, bytes32 keyHash, uint64 subscriptionId) external {
        require(msg.sender == _owner());

        VRFcoord = vrf_;
        keyhash  = keyHash;
        subId    = subscriptionId;
    }

    /**
        @dev Add next week boss and move it 
    */
    function addBoss(address prizeToken, uint256 halfPrize, uint256 hp_, uint256 atk_, uint256 mgk_, uint256 mod_, uint256 element_) external {
        require(msg.sender == _owner(), "not allowed");
        uint256 boss = currentBoss + 1;

        prizeValues[boss] = halfPrize;
        prizeTokens[boss] = prizeToken;

        bosses[boss] = Boss({stats: bytes8(abi.encodePacked(uint16(hp_),uint16(atk_),uint16(mgk_), uint8(element_), uint8(mod_))), topScorers:0, highestScore: 0, entries:0, winIndex:0});
    }

    function moveBoss() external {
        require(msg.sender == _owner(), "not allowed");

        require(bosses[currentBoss + 1].stats != bytes8(0), "not set");

        currentBoss++;
    }

    /*///////////////////////////////////////////////////////////////
                            STAKING FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
        @dev Stake and or unstake a list of heroes
    */
    function manageHero(uint256[] calldata toStake, uint256[] calldata toUnstake) external {
        uint256 len = toStake.length;
        for (uint256 i = 0; i < len; i++) {
            stake(toStake[i]);
        }

        len = toUnstake.length;
        for (uint256 i = 0; i < len; i++) {
            unstake(toUnstake[i]);
        }
    }

    /**
        @dev Stake a single hero 
    */
    function stake(uint256 heroId) public {
        require(currentBoss != 0, "not started");
        _pull(heroesAddress, heroId);
        heroes[heroId] = Heroes(msg.sender, 0, 0);
    }

    /**
        @dev Unstake a single hero 
    */
    function unstake(uint256 heroId) public {
        Heroes memory hero = heroes[heroId];

        require(msg.sender == hero.owner,   "not owner");
        require(hero.lastBoss < currentBoss,"alredy entered");
        // transfer NFT
        _push(heroesAddress, hero.owner, heroId);

        delete heroes[heroId];
    }

    /*///////////////////////////////////////////////////////////////
                            FIGHT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
        @dev Fight this week's boss
    */
    function fight(uint256 heroId, bytes10 items) public returns(bytes32 fightId) {
        Heroes memory hero = heroes[heroId];
        require(msg.sender == hero.owner, "not owner");

        _validateItems(items);

        uint256 currBoss = currentBoss;
        Boss memory boss = bosses[currBoss];

        require(boss.stats != bytes8(0), "invalid boss");

        uint256 score = _calculateScore(currBoss, boss.stats, heroId, items, msg.sender);

        if (hero.lastBoss < currBoss) {
            hero.lastBoss     = uint16(currBoss);
            hero.highestScore = 0;
        }

        fightId = getFightId(heroId, currBoss, items, msg.sender);
        require(fights[fightId].heroId == 0, "already fought");

        Fight memory fh = Fight(uint16(heroId), uint16(currBoss), items, 0, 0, false, false);

        if (score == boss.highestScore) boss.topScorers++; // Tied to the highest score;
        
        // This is a new highscore, so we reset the leaderboard
        if (score > boss.highestScore) {
            boss.highestScore = uint32(score);
            boss.topScorers   = 1;
        }

        // Getting Raffle tickets
        if (score > hero.highestScore) {
            uint32 diff = uint32(score - hero.highestScore);  

            fh.start = uint32(boss.entries) + 1;
            fh.count = diff;

            boss.entries += diff;            
            hero.highestScore = uint32(score);
        }

        bosses[currBoss] = boss;
        heroes[heroId]   = hero;
        fights[fightId]  = fh;

        emit FightResult(msg.sender, heroId, currBoss, items, score, fightId);
    }

    /**
        @dev Get the boss drop item from this week 
    */
    function getBossDrop(uint256 heroId_, uint boss_, bytes10 items_) external returns (uint256 bossItemId){
        bytes32 fightId = getFightId(heroId_, boss_, items_, msg.sender);

        Fight memory fh = fights[fightId];

        require(fh.boss == currentBoss, "claim over");
        require(fh.heroId != 0,         "non existent fight");
        require(!fh.claimedBoss,        "already claimed");

        uint256 score = _calculateScore(fh.boss, bosses[fh.boss].stats, fh.heroId, fh.items, msg.sender);
        require(score > 0, "not won");

        uint16[5] memory _items = _unpackItems(fh.items);
        for (uint256 i = 0; i < 5; i++) {
            if (_items[i] == 0) break;
            // Burn the item  if it's not burnt already
            if (IERC721(itemsAddress).ownerOf(_items[i]) != address(0)) require(MetaAndMagicLike(itemsAddress).burnFrom(msg.sender, _items[i]), "burn failed");
        }

        fights[fightId].claimedBoss = true;
        // Boss drops supplies are checked at the itemsAddress
        bossItemId = MetaAndMagicLike(fh.boss == 10 ? heroesAddress : itemsAddress).mintDrop(boss_, msg.sender);
    }

    /**
        @dev Get the prize for having the highest score
    */
    function getPrize(uint256 heroId_, uint256 boss_, bytes10 items_) external {
        bytes32 fightId = getFightId(heroId_, boss_, items_, msg.sender);
        
        Fight memory fh   = fights[fightId];
        Boss  memory boss = bosses[fh.boss];

        require(fh.boss < currentBoss, "not finished");
        require(!fh.claimedScore,      "already claimed");
    
        uint256 score  = _calculateScore(fh.boss, boss.stats, fh.heroId, fh.items, msg.sender);

        require(score == boss.highestScore && boss.highestScore != 0, "not high score");

        fights[fightId].claimedScore = true;

        require(IERC20(prizeTokens[fh.boss]).transfer(msg.sender, prizeValues[fh.boss] / boss.topScorers));
    }

    /**
        @dev Get the raffle prize
    */
    function getRafflePrize(uint256 heroId_, uint256 boss_, bytes10 items_) external {
        bytes32 fightId = getFightId(heroId_, boss_, items_, msg.sender);
        
        Fight memory fh   = fights[fightId];
        Boss  memory boss = bosses[fh.boss];

        require(fh.boss < currentBoss, "not finished");
        require(boss.highestScore > 0, "not fought");
        require(boss.winIndex != 0,    "not raffled");

        require(fh.start <= boss.winIndex && (fh.start + fh.count > boss.winIndex), "not winner");

        fights[fightId].count = 0;
        require(IERC20(prizeTokens[fh.boss]).transfer(msg.sender, prizeValues[fh.boss]));
    }

    /**
        @dev Request chainlink oracle for the week's raffle
    */
    function requestRaffleResult(uint256 boss_) external {
        require(boss_ < currentBoss,  "not finished");
        require(requests[boss_] == 0 || msg.sender == _owner(), "already requested");

        uint256 reqId = VRFCoordinatorV2Interface(VRFcoord).requestRandomWords(keyhash, subId, 3, 200000, 1);
        requests[boss_] = reqId;
    }

    /**
        @dev Chainlink specific function to fulfill the randomness request 
    */
    function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
        require(msg.sender == VRFcoord, "not allowed");
        for (uint256 index = currentBoss; index > 0; index--) {
            if (requests[index] == requestId) {
                Boss memory boss = bosses[index];

                bosses[index].winIndex = uint56(randomWords[0] % uint256(boss.entries) + 1); // 1 -> raffleEntry
            }
        }
   }

    /*///////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getScore(bytes32 fightId, address player) external view returns(uint256 score) {
        Fight memory fh   = fights[fightId];
        require(fh.boss != 0);
        score = _calculateScore(fh.boss, bosses[fh.boss].stats, fh.heroId, fh.items,player);
    }

    function getFightId(uint256 hero_, uint256 boss_, bytes10 items_, address owner_) public pure returns (bytes32 id) {
        id = keccak256(abi.encode(hero_, boss_, items_, owner_));
    }

    /*///////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _calculateScore(uint256 boss, bytes8 bossStats, uint256 heroId, bytes10 packedItems, address fighter) internal view virtual returns (uint256) {
        bytes10[6] memory stats = MetaAndMagicLike(heroesAddress).getStats(heroId);

        // Start with empty combat
        Combat memory combat = Combat(0,0,0,precision,precision);
        
        // Tally Hero modifies the combat memory inplace
        _tally(combat, stats, bossStats);

        uint16[5] memory items_ = _unpackItems(packedItems);
        for (uint256 i = 0; i < 5; i++) {
            if (items_[i] == 0) break;
            stats = MetaAndMagicLike(itemsAddress).getStats(items_[i]);
            _tally(combat, stats, bossStats);
        }
        
        uint256 crit = _critical(heroId,boss,packedItems,fighter);
        return _getResult(combat, bossStats, crit);
    }

    function _getResult(Combat memory combat, bytes10 bossStats, uint256 crit) internal pure returns (uint256) {        
        uint256 bossAtk         = combat.phyRes * _get(bossStats, Stat.PHY_DMG) / precision;
        uint256 bossMgk         = combat.mgkRes * _get(bossStats, Stat.MGK_DMG) / precision;
        uint256 totalHeroAttack = combat.phyDmg + combat.mgkDmg + ((combat.phyDmg + combat.mgkDmg) * crit / 1e18);
        
        if (bossAtk + bossMgk > combat.hp || totalHeroAttack < _get(bossStats, Stat.HP)) return 0;

        return totalHeroAttack - _get(bossStats, Stat.HP) + combat.hp - bossAtk + bossMgk;
    }

     /// @dev This is the core function for calculating scores
    function _tally(Combat memory combat, bytes10[6] memory stats , bytes8 bossStats) internal pure {
        uint256 bossPhyPen = _get(bossStats, Stat.PHY_PEN);
        uint256 bossMgkPen = _get(bossStats, Stat.MGK_PEN);
        bool    bossPhyRes = _get(bossStats, Stat.PHY_RES) == 1;
        bool    bossMgkRes = _get(bossStats, Stat.MGK_RES) == 1;

        uint256 itemElement = _get(stats[5], Stat.ELM);
        uint256 bossElement = uint8(uint64(bossStats) >> 8);

        for (uint256 i = 0; i < 6; i++) {
            // Sum HP
            combat.hp += _get(stats[i], Stat.HP);

            combat.phyDmg += _sumAtk(stats[i], Stat.PHY_DMG, Stat.PHY_PEN, bossPhyRes);

            uint256 mgk = _sumAtk(stats[i], Stat.MGK_DMG, Stat.MGK_PEN, bossMgkRes);
            uint256 adv = _getAdv(itemElement, bossElement);

            combat.mgkDmg += adv == 3 ?  0 : mgk * (adv == 1 ? 2 : 1) / (adv == 2 ? 2 : 1);

            combat.phyRes = _stack(combat.phyRes, stats[i], Stat.PHY_RES, bossPhyPen);
            combat.mgkRes = _stack(combat.mgkRes, stats[i], Stat.MGK_RES, bossMgkPen);

            combat.mgkRes = stackElement(combat.mgkRes, itemElement, bossElement);
        }
    }      

    function _critical(uint256 hero_, uint256 boss_, bytes10 items_, address fighter) internal pure returns (uint256 draw) {
        draw = uint256(getFightId(hero_, boss_, items_, fighter)) % 0.25e18 + 1;
    }

    function _get(bytes10 src, Stat stat) internal pure returns (uint256) {
        uint8 st = uint8(stat);

        if (st == 7) return uint8(uint80(src)); // Element
        if (st < 3)  return uint16(bytes2(src << (st * 16))); // Hp, PhyDmg or MgkDmg

        return (uint16(bytes2(src << (48))) & (1 << st - 3)) >> st - 3;
    }

    function _getAdv(uint256 ele, uint256 oppEle) internal pure returns (uint256 adv) {
        // Returns 0 if elements don't iteract
        if (ele == 0 || oppEle == 0) return 0;

        // Returns 1 if ele has advantage
        if (ele == oppEle - 1 || (ele == 4 && oppEle == 1)) return adv = 1;
        // // Returns 2 if ele has disavantage
        if (ele - 1 == oppEle || (ele == 1 && oppEle == 4)) return adv = 2;
        // Returns 3 if ele is the same
        if (ele == oppEle) return adv = 3;
    }

    function stackElement(uint256 val, uint256 ele, uint256 oppEle) internal pure returns (uint256) {
        uint256 adv = _getAdv(ele, oppEle);
        if (adv == 0) return val;

        if (adv == 3) return 0;

        if (adv == 1) return val * precision / (2 * precision);

        return val * 2 * precision / precision;
    }

    function _sumAtk(bytes10 src, Stat stat, Stat pen, bool bossRes) internal pure returns (uint256 sum) {
        sum  = _get(src, stat) / (((_get(src, pen) == 0) && bossRes) ? 2 : 1);
    }

    function _stack(uint256 val, bytes10 src, Stat res, uint256 oppPen) internal pure returns (uint256) {
        return _stack(val, _get(src, res), oppPen);
    }

    function _stack(uint256 val, uint256 res, uint256 oppPen) internal pure returns (uint256 ret) {
        ret = val * ((oppPen == 0) && (res == 1) ? 0.5e12: precision) / precision;
    }

    function _getPackedItems(uint16[5] memory items) internal pure returns(bytes10 packed) {
        packed = bytes10(abi.encodePacked(items[0], items[1], items[2], items[3], items[4]));
    }

    function _validateItems(bytes10 packedItems) internal view {
        uint16[5] memory items = _unpackItems(packedItems);
        
        for (uint256 i = 1; i < items.length; i++) {
            require(items[i - 1] == 0 ? items[i] == 0 : items[i - 1] > items[i], "invalid items"); 
            if (items[i] != 0) require(IERC721(itemsAddress).ownerOf(items[i]) == msg.sender, "not item owner");
        }
    }

    function _unpackItems(bytes10 items) internal pure returns(uint16[5] memory unpacked) {
        unpacked[0] = uint16(bytes2(items));
        unpacked[1] = uint16(bytes2(items << 16));
        unpacked[2] = uint16(bytes2(items << 32));
        unpacked[3] = uint16(bytes2(items << 48));
        unpacked[4] = uint16(bytes2(items << 64));
    }

    function _pull(address token, uint256 id) internal {
        require(IERC721(token).transferFrom(msg.sender, address(this), id), "failed transfer");
    }

    function _push(address token, address to_, uint256 id) internal {
        require(IERC721(token).transferFrom(address(this), address(to_), id), "transfer failed");
    }

    function _owner() internal view returns (address owner_) {
        bytes32 slot = bytes32(0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103);
        assembly {
            owner_ := sload(slot)
        }
    } 
}

interface MetaAndMagicLike {
    function getStats(uint256 id_) external view returns(bytes10[6] memory stats);
    function mintDrop(uint256 bossId, address to_) external returns(uint256 id);
    function burnFrom(address from, uint256 id) external returns (bool);
}

interface IERC721 {
    function transferFrom(address from_, address to_, uint256 id_) external returns(bool);
    function ownerOf(uint256 id) external view returns(address);
}

interface IERC20 {
    function transfer(address to_, uint256 id_) external returns(bool);
}

interface VRFCoordinatorV2Interface {
    function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);
}