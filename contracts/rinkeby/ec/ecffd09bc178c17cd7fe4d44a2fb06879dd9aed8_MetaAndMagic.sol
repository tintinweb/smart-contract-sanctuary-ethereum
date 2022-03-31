/**
 *Submitted for verification at Etherscan.io on 2022-03-31
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract MetaAndMagic {

    address heroesAddress;
    address itemsAddress;

    uint256 currentBoss;

    mapping(uint256 => Heroes) public heroes;
    mapping(uint256 => Boss)   public bosses;
    mapping(bytes32 => Fight)  public fights;     

    mapping(uint256 => uint256) public requests;  
    mapping(uint256 => uint256) public prizeValues;
    mapping(uint256 => address) public prizeTokens;

    // Oracle information
    address VRFcoord;
    uint64 subId;
    bytes32 keyhash;

    struct Heroes { address owner; uint16 lastBoss; uint32 highestScore;}

    struct Fight  { uint16 heroId; uint16 boss; bytes10 items_; uint32 start; uint32 count; bool claimedScore; bool claimedBoss; }
    
    struct Boss   { bytes8 stats; uint16 drops; uint16 topScorers; uint56 highestScore; uint56 entries; uint56 winIndex; }

    struct Combat { uint256 hp; uint256 phyDmg; uint256 mgkDmg; uint256 phyRes; uint256 mgkRes; uint256 bossPhyRes; uint256 bossMgkRes; }

    enum Stat { HP, PHY_DMG, MGK_DMG, MGK_RES, MGK_PEN, PHY_RES, PHY_PEN, ELM }

    uint256 constant public precision = 1e12;

    function initialize(address heroes_, address items_) external {
        require(msg.sender == _owner());

        heroesAddress = heroes_;
        itemsAddress  = items_;
        
        currentBoss = 1; // start at current boss
    }

    function setUpOracle(address vrf_, bytes32 keyHash, uint64 subscriptionId) external {
        require(msg.sender == _owner());

        VRFcoord = vrf_;
        keyhash  = keyHash;
        subId    = subscriptionId;
    }

    function addBoss(address prizeToken, uint256 halfPrize, uint256 drops, uint256 hp_, uint256 atk_, uint256 mgk_, uint256 mod_, uint256 element_) external {
        require(msg.sender == _owner(), "not allowed");
        uint256 boss = ++currentBoss;

        prizeValues[boss] = halfPrize;
        prizeTokens[boss] = prizeToken;

        bosses[boss] = Boss({stats: bytes8(abi.encodePacked(uint16(hp_),uint16(atk_),uint16(mgk_), uint8(element_), uint8(mod_))), topScorers:0, drops: uint16(drops), highestScore: 0, entries:0, winIndex:0});
    }

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

    function stake(uint256 heroId) public {
        _pull(heroesAddress, heroId);
        heroes[heroId] = Heroes(msg.sender, 0, 0);
    }

    function unstake(uint256 heroId) public {
        Heroes memory hero = heroes[heroId];

        require(msg.sender == hero.owner,   "not owner");
        require(hero.lastBoss < currentBoss,"alredy entered");
        // transfer NFT
        _push(heroesAddress, hero.owner, heroId);

        delete heroes[heroId];
    }

    function _fight(uint256 heroId, bytes10 items) public returns(bytes32 fightId) {
        Heroes memory hero = heroes[heroId];
        require(msg.sender == hero.owner, "not owner");

        _validateItems(items);

        uint256 currBoss = currentBoss;
        Boss memory boss = bosses[currBoss];

        require(boss.stats != bytes8(0), "invalid boss");

        uint256 score = _calculateScore(boss.stats, heroId, items);

        if (hero.lastBoss < currBoss) {
            hero.lastBoss     = uint16(currBoss);
            hero.highestScore = 0;
        }

        fightId = keccak256(abi.encode(heroId, currBoss, items, msg.sender));
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
        heroes[heroId]  = hero;
        fights[fightId] = fh;
    }

    function getBossDrop(uint256 heroId, uint boss_, bytes10 items) external returns (uint256 bossItemId){
        bytes32 fightId = keccak256(abi.encode(heroId, boss_, items, msg.sender));

        Fight memory fh = fights[fightId];

        require(fh.heroId != 0,  "non existent fight");
        require(!fh.claimedBoss, "already claimed");

        uint256 score = _calculateScore(bosses[boss_].stats, heroId, items);
        require(score > 0, "not won");

        uint16[5] memory items_ = _unpackItems(items);
        for (uint256 i = 0; i < 5; i++) {
            if (items_[i] == 0) break;
            // Burn the item  if it's not burnt already
            if (IERC721(itemsAddress).ownerOf(items_[i]) != address(0)) require(MetaAndMagicLike(itemsAddress).burnFrom(msg.sender, items_[i]), "burn failed");
        }

        fights[fightId].claimedBoss = true;
        // Boss drops supplies are checked at the itemsAddress
        bossItemId = MetaAndMagicLike(itemsAddress).mintDrop(boss_, msg.sender);
    }

    function getPrize(uint256 heroId, uint256 boss_, bytes10 items) external {
        require(boss_ < currentBoss, "not finished");

        bytes32 fightId = keccak256(abi.encode(heroId, boss_, items, msg.sender));

        Fight memory fh   = fights[fightId];
        Boss  memory boss = bosses[currentBoss];
        
        require(!fh.claimedScore, "already claimed");
    
        uint256 score  = _calculateScore(bosses[boss_].stats, heroId, fh.items_);

        require(score == boss.highestScore && boss.highestScore != 0, "not high score");

        fights[fightId].claimedScore = true;

        require(IERC20(prizeTokens[boss_]).transfer(msg.sender, prizeValues[boss_] / boss.topScorers));
    }

    function getRafflePrize(uint256 heroId, uint256 boss_, bytes10 items) external {
        require(boss_ < currentBoss, "not finished");

        bytes32 fightId = keccak256(abi.encode(heroId, boss_, items, msg.sender));
        
        Fight memory fh   = fights[fightId];
        Boss  memory boss = bosses[currentBoss];
        
        require(boss_ < currentBoss,  "not finished");
        require(boss.highestScore > 0, "invalid");
        require(boss.winIndex != 0,    "invalid");
        require(fh.start >= boss.winIndex && (fh.start + fh.count < boss.winIndex), "not the winner");

        fights[fightId].count= 0;
        require(IERC20(prizeTokens[boss_]).transfer(msg.sender, prizeValues[boss_]));
    }

    function requestRaffleResult(uint256 boss_) external {
        require(boss_ < currentBoss,  "not finished");
        require(requests[boss_] == 0, "already requested");

        uint256 reqId = VRFCoordinatorV2Interface(VRFcoord).requestRandomWords(keyhash, subId, 1, 200000, 1);
        requests[boss_] = reqId;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWord) external {
        require(msg.sender == VRFcoord, "not allowed");

        for (uint256 index = currentBoss; index > 0; index--) {
            if (requests[index] == requestId) {
                Boss memory boss = bosses[index];

                bosses[index].winIndex = uint56(randomWord[0] % uint256(boss.entries) + 1); // 1 -> raffleEntry
            }
        }
    }

    function _calculateScore(bytes8 bossStats, uint256 heroId, bytes10 packedItems) internal virtual returns (uint256) {
        (bytes32 s1_, bytes32 s2_) = MetaAndMagicLike(heroesAddress).getStats(heroId);

        // Start with empty combat
        Combat memory combat = Combat(0,0,0,precision,precision,precision,precision);
        
        // Tally Hero modifies the combat memory inplace
        _tally(combat, s1_, s2_, bossStats);
        uint16[5] memory items_ = _unpackItems(packedItems);
        for (uint256 i = 0; i < 5; i++) {
            if (items_[i] == 0) break;
            (s1_, s2_) = MetaAndMagicLike(itemsAddress).getStats(items_[i]);
            _tally(combat, s1_, s2_, bossStats);
        }

        return _getResult(combat, bossStats);
    }

    function _getResult(Combat memory combat, bytes8 bossStats) internal pure returns (uint256) {
        uint256 bossAtk = combat.phyRes * _get(bossStats, Stat.PHY_DMG) / precision;
        uint256 bossMgk = combat.mgkRes * _get(bossStats, Stat.MGK_DMG) / precision;

        uint256 totalHeroAttack = (combat.phyDmg * combat.bossPhyRes / precision) + (combat.mgkDmg * combat.bossMgkRes / precision); // total boss HP
        if (bossAtk + bossMgk > combat.hp || totalHeroAttack < _get(bossStats, Stat.HP)) return 0;

        return totalHeroAttack - _get(bossStats, Stat.HP) + combat.hp - bossAtk + bossMgk;
    }

    /// @dev This is the core function for calculating scores
    function _tally(Combat memory combat, bytes32 s1_, bytes32 s2_, bytes8 bossStats) internal pure {
        uint256 bossPhyPen = _get(bossStats, Stat.PHY_PEN);
        uint256 bossPhyRes = _get(bossStats, Stat.PHY_RES);
        uint256 bossMgkPen = _get(bossStats, Stat.MGK_PEN);
        uint256 bossMgkRes = _get(bossStats, Stat.MGK_RES);

        // Plain sum elements
        combat.hp     += _sum(Stat.HP,      s1_) + _sum(Stat.HP,      s2_);
        combat.phyDmg += _sum(Stat.PHY_DMG, s1_) + _sum(Stat.PHY_DMG, s2_);
        combat.mgkDmg += _sum(Stat.MGK_DMG, s1_) + _sum(Stat.MGK_DMG, s2_);

        // TODO this looks bad, figure it out a way to optimize it
        // Stacked Elements
        combat.phyRes = _stack(Stat.PHY_RES, combat.phyRes, s1_, bossPhyPen);
        combat.phyRes = _stack(Stat.PHY_RES, combat.phyRes, s2_, bossPhyPen);

        combat.mgkRes = _stack(Stat.MGK_RES, combat.mgkRes, s1_, bossMgkPen);
        combat.mgkRes = _stack(Stat.MGK_RES, combat.mgkRes, s2_, bossMgkPen);

        combat.bossPhyRes = _stack(Stat.PHY_PEN, combat.bossPhyRes, bossPhyRes, s1_);
        combat.bossPhyRes = _stack(Stat.PHY_PEN, combat.bossPhyRes, bossPhyRes, s2_);

        combat.bossMgkRes = _stack(Stat.MGK_PEN, combat.bossMgkRes, bossMgkRes, s1_);
        combat.bossMgkRes = _stack(Stat.MGK_PEN, combat.bossMgkRes, bossMgkRes, s2_);

        // Stack elements into modifiers (but with 0.5 / 2 instead of 0.5 / 1)
        uint256 itemElement = _get(s2_, Stat.ELM);
        uint256 bossElement = uint8(uint64(bossStats) >> 8);

        combat.mgkRes     = stackElement(combat.mgkRes, itemElement, bossElement);
        combat.bossMgkRes = stackElement(combat.bossMgkRes, bossElement, itemElement);
    }

    function stackElement(uint256 val, uint256 ele, uint256 oppEle) internal pure returns (uint256) {
        if (ele == 0 || oppEle == 0 || ele == oppEle) return val;
        if (ele == oppEle + 1 || (ele == 1 && oppEle == 4)) return val * 2 * precision / precision;
        if (ele + 1 == oppEle || (ele == 4 && oppEle == 1)) return val * 1 * precision / 2 * precision;
        return val;
    }

    function _sum(Stat st, bytes32 src) internal pure returns (uint256 sum) {
        sum = _get(src, st, 0) + _get(src, st, 1) + _get(src, st, 2);
    }

    function _stack(Stat st, uint256 val, bytes32 s1_, uint256 oppPen) internal pure returns (uint256) {
        (uint256 v1, uint256 v2, uint256 v3) = _getAll(s1_, st);
        return _stack(_stack(_stack(val, oppPen, v3), oppPen, v2), oppPen, v1);
    }

    function _stack(Stat st, uint256 val, uint256 res, bytes32 oppPens) internal pure returns (uint256) {
        (uint256 v1, uint256 v2, uint256 v3) = _getAll(oppPens, st);
        return _stack(_stack(_stack(val, v3, res),v2, res), v1, res);
    }

    function _get(bytes32 src, Stat stat) internal pure returns(uint256) {
        return _get(src, stat, 0);
    }

    /// @dev Function to get a stat given the source, the index and which stat it is.
    function _get(bytes32 src, Stat sta, uint256 index) internal pure returns (uint256) {
        uint8 st = uint8(sta);

        if (st == 7) return uint64(uint256(src)); // Element
        
        bytes8 att = bytes8((src) << (index * 64));

        if (st < 3)  return uint16(bytes2(att << (st * 16))); // Hp, PhyDmg or MgkDmg

        return (uint16(bytes2(att << (48))) & (1 << st - 3)) >> st - 3;
    }

    function _getAll(bytes32 src, Stat st) internal pure returns (uint256 val1, uint256 val2, uint256 val3) {
        (val1, val2, val3) = (_get(src, st,0),_get(src, st,1),_get(src, st,2));
    }

    function _stack(uint256 val, uint256 oppPen, uint256 res) internal pure returns (uint256 ret) {
        ret = val * ((oppPen == 0) && (res == 1) ? 0.5e12: precision) / precision;
    }

    function _getPackedItems(uint16[5] memory items) internal pure returns(bytes10 packed) {
        packed = bytes10(abi.encodePacked(items[0], items[1], items[2], items[3], items[4]));
    }

    function _validateItems(bytes10 packedItems) internal view {
        uint16[5] memory items = _unpackItems(packedItems);
        
        // Check 0 index
        require(items[0] != 0, "invalid items");
        require(IERC721(itemsAddress).ownerOf(items[0]) == msg.sender, "not item owner");
        
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
    function getStats(uint256 id_) external view returns(bytes32, bytes32);
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