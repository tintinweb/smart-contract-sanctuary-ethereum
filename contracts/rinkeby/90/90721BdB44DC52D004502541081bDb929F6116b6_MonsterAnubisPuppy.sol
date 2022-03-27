// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../../interface/IChamberController.sol";
import "../../base/MonsterBase.sol";


contract MonsterAnubisPuppy is MonsterBase {

  // ---- CONSTANTS ----

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant VERSION = "1.0.0";
  string internal constant _CHAMBER_NAME = "Anubis Puppy";
  string internal constant _URI = "https://raw.githubusercontent.com/tetu-io/tetu-game-assets/master/enemies/1/anubis_puppy.png";
  uint internal constant _CHAMBER_TYPE = uint(IChamberController.ChamberType.ENEMY_NPC_RARE);
  /// @dev Should be relevant to dungeon level (with StatLib.DUNGEON_LEVEL_STEP)
  uint internal constant _CHAMBER_LEVEL = 1;

  // ---- INITIALIZER ----

  function init(
    address controller_,
    address[] memory mintItems_,
    uint[] memory mintItemsChances_
  ) external override initializer {

    IStatController.Attributes memory attributes = IStatController.Attributes({
    // no need for monsters
    strength : 0,
    dexterity : 0,
    vitality : 0,
    energy : 0,
    // adjustable attributes
    damageMin : 2,
    damageMax : 4,
    attackRating : 100,
    defense : 50,
    blockRating : 0,
    life : 30,
    mana : 0,
    // static
    fireResistance : 0,
    coldResistance : 30,
    lightningResistance : 10
    });

    IStatController.ChangeableStats memory stats = IStatController.ChangeableStats({
    level : _CHAMBER_LEVEL * StatLib.DUNGEON_LEVEL_STEP - 2,
    experience : 2000,
    life : attributes.life,
    mana : attributes.mana
    });

    __MonsterBase_init(
      controller_,
      IFightCalculator.FighterInfo({
    fighterAttributes : attributes,
    fighterStats : stats,
    attackType : IFightCalculator.AttackType.MELEE,
    attackToken : address(0),
    attackTokenId : 0
    }),
      mintItems_,
      mintItemsChances_
    );
  }

  function chamberType() external pure override returns (uint) {
    return _CHAMBER_TYPE;
  }

  /// @dev Should be relevant dungeon level (with StatLib.DUNGEON_LEVEL_STEP)
  function chamberLevel() external pure override returns (uint) {
    return _monsterLevel();
  }

  function _monsterLevel() internal pure override returns (uint) {
    return _CHAMBER_LEVEL;
  }

  function chamberName() external pure override returns (string memory) {
    return _CHAMBER_NAME;
  }

  function URI() external pure override returns (string memory) {
    return _URI;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IChamberController {

  enum ChamberType {
    UNKNOWN, // 0
    ENEMY_NPC, // 1
    ENEMY_NPC_RARE, // 2
    BOSS, // 3
    SHRINE, // 4
    CHEST, // 5
    SLOT_6,
    SLOT_7,
    SLOT_8,
    SLOT_9,
    SLOT_10,
    SLOT_11,
    SLOT_12,
    SLOT_13,
    SLOT_14,
    SLOT_15,
    SLOT_16,
    SLOT_17,
    SLOT_18,
    SLOT_19,
    SLOT_20,
    SLOT_21,
    SLOT_22,
    SLOT_23,
    SLOT_24,
    SLOT_25,
    SLOT_26,
    SLOT_27,
    SLOT_28,
    SLOT_29,
    SLOT_30
  }

  function validChambers(address chamber) external view returns (bool);

  function chambersByTypeAndLevel(uint cType, uint level, uint index) external view returns (address);

  function chambersByTypeAndLevelLength(uint cType, uint level) external view returns (uint);

  function getRandomChamber(uint[] memory cTypes, uint[] memory chances, uint dungeonLevel) external returns (address);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./ChamberBase.sol";
import "../interface/IHero.sol";
import "../interface/IItem.sol";
import "../interface/IBuffItem.sol";
import "../interface/IDungeonFactory.sol";
import "../interface/IFightCalculator.sol";
import "../interface/IMonster.sol";
import "../lib/StatLib.sol";
import "../openzeppelin/IERC721.sol";

abstract contract MonsterBase is ChamberBase, IMonster {

  // ---- CONSTANTS ----

  uint public constant MAX_FIGHT_CYCLES = 100;

  // ---- VARIABLES ----
  IFightCalculator.FighterInfo public monsterInfo;
  address[] public mintItems;
  uint[] public mintItemsChances;

  // ---- EVENTS ----
  event FightersInfo(IFightCalculator.FighterInfo heroInfo, IFightCalculator.FighterInfo monsterInfo);
  event AttackInfo(IFightCalculator.AttackInfo info);
  event MintItemsChanged(address[] mintItems_, uint[] mintItemsChances_);

  // ---- INITIALIZER ----

  function __MonsterBase_init(
    address controller_,
    IFightCalculator.FighterInfo memory monsterInfo_,
    address[] memory mintItems_,
    uint[] memory mintItemsChances_
  ) internal onlyInitializing {
    __ChamberBase_init(controller_);
    monsterInfo = monsterInfo_;
    _checkItem(mintItems_, mintItemsChances_);
    mintItems = mintItems_;
    mintItemsChances = mintItemsChances_;
  }

  // ---- VIEWS ----

  function _fightCalculator() internal view returns (IFightCalculator) {
    return IFightCalculator(IController(_controller()).fightCalculator());
  }

  function _monsterLevel() internal view virtual returns (uint);

  // ---- ACTIONS ----

  function setMintItems(
    address[] memory mintItems_,
    uint[] memory mintItemsChances_
  ) external {
    require(_isGovernance(msg.sender) || _isController(msg.sender), "Not gov or controller");
    require(mintItems.length == mintItemsChances.length, "Wrong input");
    _checkItem(mintItems_, mintItemsChances_);
    mintItems = mintItems_;
    mintItemsChances = mintItemsChances_;
    emit MintItemsChanged(mintItems_, mintItemsChances_);
  }

  function _action(
    address heroToken_,
    uint heroTokenId_,
    bytes memory data_
  ) internal override returns (ChamberResult memory) {
    require(IHero(heroToken_).isReadyToFight(heroTokenId_), "Fight delay");

    uint manaConsumed;
    uint monsterRarity;
    IStatController.ChangeableStats memory heroStats = IHero(heroToken_).stats(heroTokenId_);
    IFightCalculator.FightResult memory fightResult;
    IFightCalculator.FighterInfo memory _monsterPureInfo = monsterInfo;
    IFightCalculator.FighterInfo memory heroFightInfo;
    IFightCalculator.FighterInfo memory monsterFightInfo;
    {
      IFightCalculator.AttackInfo memory attackInfo = _decodeAndCheckAttackInfo(
        data_,
        IERC721(heroToken_).ownerOf(heroTokenId_)
      );

      (IStatController.Attributes memory heroAttributes, uint manaConsumedToBuff) =
      IStatController(IController(_controller()).statController()).buffHero(
        heroToken_,
        heroTokenId_,
        heroStats.level,
        attackInfo.skillTokens,
        attackInfo.skillTokenIds
      );
      manaConsumed += manaConsumedToBuff;

      heroFightInfo = IFightCalculator.FighterInfo({
      fighterAttributes : heroAttributes,
      fighterStats : heroStats,
      attackType : attackInfo.attackType,
      attackToken : attackInfo.attackToken,
      attackTokenId : attackInfo.attackTokenId
      });

      (IStatController.Attributes memory monsterAttributes, uint amplifier) =
      _generateMonster(_monsterPureInfo.fighterAttributes);
      monsterRarity = amplifier;

      monsterFightInfo = IFightCalculator.FighterInfo({
      fighterAttributes : monsterAttributes,
      fighterStats : IStatController.ChangeableStats({
      level : _monsterPureInfo.fighterStats.level
        + (StatLib.DUNGEON_LEVEL_STEP * monsterRarity / _MAX_AMPLIFIER),
      experience : _monsterPureInfo.fighterStats.experience,
      life : monsterAttributes.life,
      mana : monsterAttributes.mana
      }),
      attackType : attackInfo.attackType,
      attackToken : attackInfo.attackToken,
      attackTokenId : attackInfo.attackTokenId
      });

      emit FightersInfo(heroFightInfo, monsterFightInfo);

      fightResult = _fightCalculator().fight(heroFightInfo, monsterFightInfo);
    }
    {
      bool isDead = fightResult.attackerHealth == 0;
      uint damage;
      if (!isDead) {
        // attacker health can not be higher than hero health
        damage = heroStats.life - fightResult.attackerHealth;
      } else {
        damage = heroStats.life;
      }

      return ChamberResult({
      chamber : address(this),
      heroToken : heroToken_,
      heroTokenId : heroTokenId_,
      kill : isDead,
      experience : _monsterPureInfo.fighterStats.experience
        + _monsterPureInfo.fighterStats.experience * monsterRarity / _MAX_AMPLIFIER,
      heal : 0,
      manaRegen : 0,
      damage : damage,
      manaConsumed : fightResult.attackerManaConsumed + manaConsumed,
      mintItems : _mintRandomItems(monsterRarity),
      attackerDmgHistory : fightResult.attackerDmgHistory,
      defenderDmgHistory : fightResult.defenderDmgHistory,
      heroInfo : heroFightInfo,
      monsterInfo : monsterFightInfo
      });
    }
  }

  function _generateMonster(IStatController.Attributes memory base) internal returns (IStatController.Attributes memory, uint) {
    uint amplifier = _oracle().getRandomNumber(_MAX_AMPLIFIER);
    uint dungeonMultiplier = IController(_controller()).dungeonMultiplierByLevel(_monsterLevel());

    return (IStatController.Attributes({
    // no need for monsters
    strength : 0,
    dexterity : 0,
    vitality : 0,
    energy : 0,
    // adjustable attributes
    damageMin : _amplify(base.damageMin, amplifier, dungeonMultiplier),
    damageMax : _amplify(base.damageMax, amplifier, dungeonMultiplier),
    attackRating : _amplify(base.attackRating, amplifier, dungeonMultiplier),
    defense : _amplify(base.defense, amplifier, dungeonMultiplier),
    blockRating : _amplify(base.blockRating, amplifier, dungeonMultiplier),
    life : _amplify(base.life, amplifier, dungeonMultiplier),
    mana : _amplify(base.mana, amplifier, dungeonMultiplier),
    // static
    fireResistance : _amplify(base.fireResistance, amplifier, dungeonMultiplier),
    coldResistance : _amplify(base.coldResistance, amplifier, dungeonMultiplier),
    lightningResistance : _amplify(base.lightningResistance, amplifier, dungeonMultiplier)
    }), amplifier);
  }

  function _amplify(uint value, uint amplifier, uint dungeonMultiplier) internal pure returns (uint){
    if (value == 0) {
      return 0;
    }
    return value + (value * amplifier / _MAX_AMPLIFIER) + (value * dungeonMultiplier / _MAX_AMPLIFIER);
  }

  function _mintRandomItems(uint monsterRarity) internal returns (address[] memory) {
  unchecked{
    uint length = mintItems.length;
    address[] memory minted = new address[](length);

    uint mintedLength;
    for (uint i; i < length; ++i) {
      uint chance = mintItemsChances[i] + mintItemsChances[i] * monsterRarity / _MAX_AMPLIFIER;
      if (_oracle().getRandomNumber(_ITEM_MAX_CHANCE) < chance) {
        minted[i] = mintItems[i];
        ++mintedLength;
      }
    }

    address[] memory mintedAdjusted = new address[](mintedLength);
    uint j;
    for (uint i; i < length; ++i) {
      if (minted[i] != address(0)) {
        mintedAdjusted[j] = minted[i];
        ++j;
      }
    }

    return mintedAdjusted;
  }
  }

  function _decodeAndCheckAttackInfo(bytes memory data, address heroOwner) internal returns (IFightCalculator.AttackInfo memory) {
    (IFightCalculator.AttackInfo memory attackInfo) = abi.decode(data, (IFightCalculator.AttackInfo));


    if (attackInfo.attackToken != address(0)) {
      require(IController(_controller()).validItems(attackInfo.attackToken), "Attack token not registered");
      require(IItem(attackInfo.attackToken).equipped(attackInfo.attackTokenId), "Attack token not equipped");
      require(IItem(attackInfo.attackToken).isOwner(heroOwner, attackInfo.attackTokenId), "Not your attack item");
    }

    // skill tokens should be checked later in StatController.buffHero()

    emit AttackInfo(attackInfo);
    return attackInfo;
  }

  /**
* @dev This empty reserved space is put in place to allow future versions to add new
* variables without shifting down storage in the inheritance chain.
* See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
*/
  uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../interface/IOracle.sol";
import "../interface/IStatController.sol";
import "../interface/IChamber.sol";
import "./Controllable.sol";

abstract contract ChamberBase is Controllable, IChamber {
  using SlotsLib for bytes32;

  // ---- CONSTANTS ----

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant CHAMBER_BASE_VERSION = "1.0.0";
  uint internal constant _ITEM_MAX_CHANCE = 1e18;
  uint internal constant _MAX_AMPLIFIER = 1e18;

  // ---- EVENTS ----

  event ChamberResultEvent(
    address dungeon,
    address hero,
    uint heroId,
    bytes data,
    ChamberResult result
  );

  // ---- INITIALIZER ----

  function __ChamberBase_init(
    address controller_
  ) internal onlyInitializing {
    __Controllable_init(controller_);
  }

  // ---- RESTRICTIONS ----

  function onlyDungeon() internal view {
    require(IController(_controller()).validDungeons(msg.sender), "Not dungeon");
  }

  // ---- VIEWS ----

  function isChamber() external pure override returns (bool) {
    return true;
  }

  function _statController() internal view returns (IStatController) {
    return IStatController(IController(_controller()).statController());
  }

  function _oracle() internal view returns (IOracle) {
    return IOracle(IController(_controller()).oracle());
  }

  function _checkItem(
    address[] memory mintItems_,
    uint[] memory mintItemsChances_
  ) internal pure {
    uint length = mintItems_.length;
    for (uint i; i < length;) {
      require(mintItems_[i] != address(0), "Zero address");
      require(mintItemsChances_[i] != 0, "Zero chance");
      require(mintItemsChances_[i] <= _ITEM_MAX_CHANCE, "Too high chance");
    unchecked{++i;}
    }
  }

  // ---- ACTIONS ----

  function open(
    address heroToken,
    uint heroTokenId,
    bytes calldata data
  ) external virtual override returns (ChamberResult memory) {
    onlyDungeon();
    require(IController(_controller()).validHeroes(heroToken), "Hero not registered");
    ChamberResult memory r = _action(heroToken, heroTokenId, data);
    emit ChamberResultEvent(
      msg.sender,
      heroToken,
      heroTokenId,
      data,
      r
    );
    return r;
  }

  function _action(
    address heroToken,
    uint heroTokenId,
    bytes memory data
  ) internal virtual returns (ChamberResult memory);

  /**
 * @dev This empty reserved space is put in place to allow future versions to add new
 * variables without shifting down storage in the inheritance chain.
 * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
 */
  uint256[50] private __gap;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./IStatController.sol";

interface IHero {

  struct TokenTreasury {
    uint id;
    address token;
    uint amount;
    uint blockNumber;
    uint timestamp;
  }

  function init(
    address controller_,
    address payToken_,
    uint payTokenAmount_
  ) external;

  function attributes(uint tokenId) external view returns (IStatController.Attributes memory);

  function lastFightTs(uint tokenId) external view returns (uint);

  function stats(uint tokenId) external view returns (IStatController.ChangeableStats memory);

  function currentDungeon(uint tokenId) external view returns (address);

  function isOwner(address account, uint256 tokenId) external view returns (bool);

  function isHero() external view returns (bool);

  function payToken() external view returns (address);

  function payTokenAmount() external view returns (uint);

  function heroClass() external view returns (uint);

  function killRewardForOwner(uint tokenId) external view returns (uint);

  function isReadyToFight(uint tokenId) external view returns (bool);

  function isAlive(uint tokenId) external view returns (bool);

  function create() external returns (uint);

  function kill(uint heroId) external returns (IStatController.NftItem[] memory);

  function levelUp(uint tokenId, IStatController.CoreAttributes calldata change) external;

  function changeCurrentDungeon(uint tokenId, address dungeon) external;

  function refreshLastFight(uint tokenId) external;

  function changeCurrentStats(
    uint tokenId,
    IStatController.ChangeableStats calldata change,
    bool increase
  ) external;

  function tokenTreasures(uint tokenId) external view returns (TokenTreasury memory);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./IStatController.sol";

interface IItem {

  enum ItemRarity {
    NORMAL,
    MAGIC,
    RARE,
    SET,
    UNIQUE
  }

  enum ItemType {
    NO_SLOT, // 0
    HEAD, // 1
    BODY, // 2
    GLOVES, // 3
    BELT, // 4
    AMULET, // 5
    RING, // 6
    __STUB, // 7
    BOOTS, // 8
    ONE_HAND, // 9
    TWO_HAND, // 10
    SKILL // 11
  }

  function init(
    address controller_,
    address augmentToken_,
    uint augmentTokenAmount_
  ) external;

  function isOwner(address account, uint256 tokenId) external view returns (bool);

  function augmentationLevel(uint tokenId) external view returns (uint);

  function itemRarity(uint tokenId) external view returns (uint);

  function equipped(uint tokenId) external view returns (bool);

  function isItem() external pure returns (bool);

  function isAttackItem() external view returns (bool);

  function isBuffItem() external view returns (bool);

  function isConsumableItem() external pure returns (bool);

  function augmentToken() external returns (address);

  function augmentTokenAmount() external returns (uint);

  function itemLevel() external returns (uint);

  function itemType() external returns (uint);

  function itemAttributes(uint tokenId) external view returns (IStatController.Attributes memory);

  function mint() external returns (uint tokenId);

  function equip(uint tokenId, address heroToken, uint heroTokenId, uint itemSlot) external;

  function takeOff(uint tokenId, address heroToken, uint heroTokenId, uint itemSlot, address destination) external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./IStatController.sol";

interface IBuffItem {

  function buff(uint tokenId) external view returns (IStatController.Attributes memory attributes, uint manaConsume);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IDungeonFactory {

  function addFreeDungeon(address dungeon_) external;

  function removeFreeDungeon(address dungeon_) external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./IStatController.sol";

interface IFightCalculator {

  enum AttackType {
    UNKNOWN, // 0
    MELEE, // 1
    MAGIC, // 2
    SLOT_3,
    SLOT_4,
    SLOT_5,
    SLOT_6,
    SLOT_7,
    SLOT_8,
    SLOT_9,
    SLOT_10
  }

  struct AttackInfo {
    AttackType attackType;
    address attackToken;
    uint attackTokenId;
    address[] skillTokens;
    uint[] skillTokenIds;
  }

  struct FighterInfo {
    IStatController.Attributes fighterAttributes;
    IStatController.ChangeableStats fighterStats;
    AttackType attackType;
    address attackToken;
    uint attackTokenId;
  }

  struct FightResult {
    uint attackerHealth;
    uint defenderHealth;
    uint attackerManaConsumed;
    uint defenderManaConsumed;
    uint[] attackerDmgHistory;
    uint[] defenderDmgHistory;
  }

  function fight(
    FighterInfo memory attackerInfo,
    FighterInfo memory defenderInfo
  ) external returns (FightResult memory);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IMonster {

  function init(
    address controller_,
    address[] memory mintItems_,
    uint[] memory mintItemsChances_
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../interface/IStatController.sol";
import "../openzeppelin/Math.sol";

library StatLib {

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant STAT_LIB_VERSION = "1.0.0";
  uint public constant MAX_LEVEL = 99;
  uint public constant BASE_EXPERIENCE = 100_000;
  uint public constant DUNGEON_LEVEL_STEP = 5;

  struct BaseMultiplier {
    uint minDamage;
    uint maxDamage;
    uint attackRating;
    uint defense;
    uint blockRating;
    uint life;
    uint mana;
  }

  struct LevelUp {
    uint life;
    uint mana;
  }

  uint private constant _PRECISION = 1e18;

  // --------- BASE -----------

  // --- HERO 1 ---

  function initialCoreHero1() internal pure returns (IStatController.CoreAttributes memory) {
    return IStatController.CoreAttributes({
    strength : 30,
    dexterity : 20,
    vitality : 25,
    energy : 10
    });
  }

  function multiplierHero1() internal pure returns (BaseMultiplier memory) {
    return BaseMultiplier({
    minDamage : 2e17,
    maxDamage : 5e17,
    attackRating : 3e18,
    defense : 15e17,
    blockRating : 5e16,
    life : 2e18,
    mana : 5e17
    });
  }

  function levelUpHero1() internal pure returns (LevelUp memory) {
    return LevelUp({
    life : 2e18,
    mana : 1e18
    });
  }

  // ------

  function initialCore(uint heroClass) internal pure returns (IStatController.CoreAttributes memory){
    if (heroClass == 1) {
      return initialCoreHero1();
    } else {
      revert("Unknown class");
    }
  }

  function multipliers(uint heroClass) internal pure returns (BaseMultiplier memory){
    if (heroClass == 1) {
      return multiplierHero1();
    } else {
      revert("Unknown class");
    }
  }

  function levelUps(uint heroClass) internal pure returns (LevelUp memory){
    if (heroClass == 1) {
      return levelUpHero1();
    } else {
      revert("Unknown class");
    }
  }

  // --------- CALCULATIONS -----------

  function minDamage(uint strength, uint heroClass) internal pure returns (uint){
    return strength * multipliers(heroClass).minDamage / _PRECISION;
  }

  function maxDamage(uint strength, uint heroClass) internal pure returns (uint){
    return strength * multipliers(heroClass).maxDamage / _PRECISION;
  }

  function attackRating(uint dexterity, uint heroClass) internal pure returns (uint){
    return dexterity * multipliers(heroClass).attackRating / _PRECISION;
  }

  function defense(uint dexterity, uint heroClass) internal pure returns (uint){
    return dexterity * multipliers(heroClass).defense / _PRECISION;
  }

  function blockRating(uint dexterity, uint heroClass) internal pure returns (uint){
    return Math.min(dexterity * multipliers(heroClass).blockRating / _PRECISION, 75);
  }

  function life(uint vitality, uint heroClass, uint level) internal pure returns (uint){
    return (vitality * multipliers(heroClass).life / _PRECISION)
    + (level * levelUps(heroClass).life / _PRECISION);
  }

  function mana(uint energy, uint heroClass, uint level) internal pure returns (uint){
    return (energy * multipliers(heroClass).mana / _PRECISION)
    + (level * levelUps(heroClass).mana / _PRECISION);
  }

  function levelExperience(uint level) internal pure returns (uint) {
    require(level <= MAX_LEVEL, "Max level");
    return level * BASE_EXPERIENCE * (67e17 - log2((MAX_LEVEL - level + 2) * 1e18)) / 1e18;
  }

  function chanceToHit(
    uint attackersAttackRating,
    uint defendersDefenceRating,
    uint attackersLevel,
    uint defendersLevel
  ) internal pure returns (uint) {
    uint base = 2e18
    * (attackersAttackRating * 1e18 / (attackersAttackRating + defendersDefenceRating))
    * (attackersLevel * 1e18 / (attackersLevel + defendersLevel))
    / 1e36;
    return Math.max(Math.min(base, 95e17), 5e16);
  }

  /*********************************************
  *              PRB-MATH                      *
  *   https://github.com/hifi-finance/prb-math *
  **********************************************/

  /// @notice Calculates the binary logarithm of x.
  ///
  /// @dev Based on the iterative approximation algorithm.
  /// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
  ///
  /// Requirements:
  /// - x must be greater than or equal to SCALE, otherwise the result would be negative.
  ///
  /// Caveats:
  /// - The results are nor perfectly accurate to the last decimal,
  ///   due to the lossy precision of the iterative approximation.
  ///
  /// @param x The unsigned 60.18-decimal fixed-point number for which
  ///           to calculate the binary logarithm.
  /// @return result The binary logarithm as an unsigned 60.18-decimal fixed-point number.
  function log2(uint256 x) public pure returns (uint256 result) {
    require(x >= 1e18, "x too low");

    // Calculate the integer part of the logarithm
    // and add it to the result and finally calculate y = x * 2^(-n).
    uint256 n = mostSignificantBit(x / 1e18);

    // The integer part of the logarithm as an unsigned 60.18-decimal fixed-point number.
    // The operation can't overflow because n is maximum 255 and SCALE is 1e18.
    uint256 rValue = n * 1e18;

    // This is y = x * 2^(-n).
    uint256 y = x >> n;

    // If y = 1, the fractional part is zero.
    if (y == 1e18) {
      return rValue;
    }

    // Calculate the fractional part via the iterative approximation.
    // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
    for (uint256 delta = 5e17; delta > 0; delta >>= 1) {
      y = (y * y) / 1e18;

      // Is y^2 > 2 and so in the range [2,4)?
      if (y >= 2 * 1e18) {
        // Add the 2^(-m) factor to the logarithm.
        rValue += delta;

        // Corresponds to z/2 on Wikipedia.
        y >>= 1;
      }
    }
    return rValue;
  }

  /// @notice Finds the zero-based index of the first one in the binary representation of x.
  /// @dev See the note on msb in the "Find First Set"
  ///      Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
  /// @param x The uint256 number for which to find the index of the most significant bit.
  /// @return msb The index of the most significant bit as an uint256.
  //noinspection NoReturn
  function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
    if (x >= 2 ** 128) {
      x >>= 128;
      msb += 128;
    }
    if (x >= 2 ** 64) {
      x >>= 64;
      msb += 64;
    }
    if (x >= 2 ** 32) {
      x >>= 32;
      msb += 32;
    }
    if (x >= 2 ** 16) {
      x >>= 16;
      msb += 16;
    }
    if (x >= 2 ** 8) {
      x >>= 8;
      msb += 8;
    }
    if (x >= 2 ** 4) {
      x >>= 4;
      msb += 4;
    }
    if (x >= 2 ** 2) {
      x >>= 2;
      msb += 2;
    }
    if (x >= 2 ** 1) {
      // No need to shift x any more.
      msb += 1;
    }
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
  /**
   * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
   */
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

  /**
   * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
   */
  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

  /**
   * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
   */
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  /**
   * @dev Returns the number of tokens in ``owner``'s account.
   */
  function balanceOf(address owner) external view returns (uint256 balance);

  /**
   * @dev Returns the owner of the `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function ownerOf(uint256 tokenId) external view returns (address owner);

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
   * are aware of the ERC721 protocol to prevent tokens from being forever locked.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  /**
   * @dev Transfers `tokenId` token from `from` to `to`.
   *
   * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must be owned by `from`.
   * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  /**
   * @dev Gives permission to `to` to transfer `tokenId` token to another account.
   * The approval is cleared when the token is transferred.
   *
   * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
   *
   * Requirements:
   *
   * - The caller must own the token or be an approved operator.
   * - `tokenId` must exist.
   *
   * Emits an {Approval} event.
   */
  function approve(address to, uint256 tokenId) external;

  /**
   * @dev Returns the account approved for `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function getApproved(uint256 tokenId) external view returns (address operator);

  /**
   * @dev Approve or remove `operator` as an operator for the caller.
   * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
   *
   * Requirements:
   *
   * - The `operator` cannot be the caller.
   *
   * Emits an {ApprovalForAll} event.
   */
  function setApprovalForAll(address operator, bool _approved) external;

  /**
   * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
   *
   * See {setApprovalForAll}
   */
  function isApprovedForAll(address owner, address operator) external view returns (bool);

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IOracle {

  function getRandomNumber(uint max) external returns (uint);

  function getRandomNumberInRange(uint min, uint max) external returns (uint);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IStatController {

  struct Attributes {
    // core
    uint strength;
    uint dexterity;
    uint vitality;
    uint energy;
    // attributes
    uint damageMin;
    uint damageMax;
    uint attackRating;
    uint defense;
    uint blockRating;
    uint life;
    uint mana;
    // resistance
    uint fireResistance;
    uint coldResistance;
    uint lightningResistance;
  }

  struct CoreAttributes {
    uint strength;
    uint dexterity;
    uint vitality;
    uint energy;
  }

  struct ChangeableStats {
    uint level;
    uint experience;
    uint life;
    uint mana;
  }

  enum MagicAttackType {
    UNKNOWN, // 0
    FIRE, // 1
    COLD, // 2
    LIGHTNING, // 3
    CHAOS // 4
  }

  struct MagicAttack {
    MagicAttackType aType;
    uint min;
    uint max;
    CoreAttributes attribute;
    uint attributeFactor;
    uint manaConsume;
  }

  enum ItemSlots {
    UNKNOWN, // 0
    HEAD, // 1
    BODY, // 2
    GLOVES, // 3
    BELT, // 4
    AMULET, // 5
    BOOTS, // 6
    RIGHT_RING, // 7
    LEFT_RING, // 8
    RIGHT_HAND, // 9
    LEFT_HAND, // 10
    TWO_HAND, // 11
    SKILL_1, // 12
    SKILL_2, // 13
    SKILL_3, // 14
    SLOT_15, // 15
    SLOT_16, // 16
    SLOT_17, // 17
    SLOT_18, // 18
    SLOT_19, // 19
    SLOT_20, // 20
    SLOT_21, // 21
    SLOT_22, // 22
    SLOT_23, // 23
    SLOT_24, // 24
    SLOT_25, // 25
    SLOT_26, // 26
    SLOT_27, // 27
    SLOT_28, // 28
    SLOT_29, // 29
    SLOT_30 // 30
  }

  struct NftItem {
    address token;
    uint tokenId;
  }

  function initNewHero(address token, uint tokenId, uint heroClass) external;

  function heroAttributes(address token, uint tokenId) external view returns (Attributes memory);

  function heroStats(address token, uint tokenId) external view returns (ChangeableStats memory);

  function heroItemSlot(address token, uint tokenId, uint itemSlot) external view returns (NftItem memory);

  function isHeroAlive(address heroToken, uint heroTokenId) external view returns (bool);

  function levelUp(address token, uint tokenId, uint heroClass, CoreAttributes calldata change) external;

  function changeHeroItemSlot(
    address heroToken,
    uint heroTokenId,
    uint itemType,
    uint itemSlot,
    address itemToken,
    uint itemTokenId,
    bool equip
  ) external;

  function changeCurrentStats(
    address token,
    uint tokenId,
    ChangeableStats calldata change,
    bool increase
  ) external;

  function changeTemporallyAttributes(
    address heroToken,
    uint heroTokenId,
    Attributes calldata changeAttributes,
    bool increase
  ) external;

  function clearTemporallyAttributes(address heroToken, uint heroTokenId) external;

  function addBonusAttributes(
    address token,
    uint tokenId,
    Attributes calldata bonus
  ) external;

  function removeBonusAttributes(
    address token,
    uint tokenId,
    Attributes calldata bonus
  ) external;

  function buffHero(
    address heroToken,
    uint heroTokenId,
    uint heroLevel,
    address[] memory skillTokens,
    uint[] memory skillTokenIds
  ) external view returns (Attributes memory attributes, uint manaConsumed);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./IFightCalculator.sol";

interface IChamber {

  struct ChamberResult {
    address chamber;
    address heroToken;
    uint heroTokenId;
    bool kill;
    uint experience;
    uint heal;
    uint manaRegen;
    uint damage;
    uint manaConsumed;
    address[] mintItems;
    uint[] attackerDmgHistory;
    uint[] defenderDmgHistory;
    IFightCalculator.FighterInfo heroInfo;
    IFightCalculator.FighterInfo monsterInfo;
  }

  function isChamber() external pure returns (bool);

  function chamberName() external view returns (string memory);

  function URI() external view returns (string memory);

  function chamberType() external view returns (uint);

  function chamberLevel() external view returns (uint);

  function open(address heroToken, uint heroTokenId, bytes calldata data) external returns (ChamberResult memory);

}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "../openzeppelin/Initializable.sol";
import "../interface/IControllable.sol";
import "../interface/IController.sol";
import "../lib/SlotsLib.sol";

/// @title Implement basic functionality for any contract that require strict control
/// @dev Can be used with upgradeable pattern.
///      Require call __Controllable_init() in any case.
/// @author belbix
abstract contract Controllable is Initializable, IControllable {
  using SlotsLib for bytes32;

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant CONTROLLABLE_VERSION = "1.0.0";

  bytes32 internal constant _CONTROLLER_SLOT = bytes32(uint256(keccak256("eip1967.controllable.controller")) - 1);
  bytes32 internal constant _CREATED_SLOT = bytes32(uint256(keccak256("eip1967.controllable.created")) - 1);
  bytes32 internal constant _CREATED_BLOCK_SLOT = bytes32(uint256(keccak256("eip1967.controllable.created_block")) - 1);
  bytes32 internal constant _REVISION_SLOT = bytes32(uint256(keccak256("eip1967.controllable.revision")) - 1);
  bytes32 internal constant _PREVIOUS_LOGIC_SLOT = bytes32(uint256(keccak256("eip1967.controllable.prev_logic")) - 1);

  event ContractInitialized(address controller, uint ts, uint block);
  event RevisionIncreased(uint value, address oldLogic);

  /// @notice Initialize contract after setup it as proxy implementation
  ///         Save block.timestamp in the "created" variable
  /// @dev Use it only once after first logic setup
  /// @param controller_ Controller address
  function __Controllable_init(address controller_) public onlyInitializing {
    require(controller_ != address(0), "Zero controller");
    _CONTROLLER_SLOT.set(controller_);
    _CREATED_SLOT.set(block.timestamp);
    _CREATED_BLOCK_SLOT.set(block.number);
    emit ContractInitialized(controller_, block.timestamp, block.number);
  }

  /// @dev Return true if given address is controller
  function isController(address _value) external override view returns (bool) {
    return _isController(_value);
  }

  function _isController(address _value) internal view returns (bool) {
    return _value == _controller();
  }

  /// @notice Return true if given address is setup as governance in Controller
  function isGovernance(address _value) external override view returns (bool) {
    return _isGovernance(_value);
  }

  function _isGovernance(address _value) internal view returns (bool) {
    return IController(_controller()).governance() == _value;
  }

  /// @dev Contract upgrade counter
  function revision() external view returns (uint){
    return _REVISION_SLOT.getUint();
  }

  /// @dev Previous logic implementation
  function previousImplementation() external view returns (address){
    return _PREVIOUS_LOGIC_SLOT.getAddress();
  }

  // ************* SETTERS/GETTERS *******************

  /// @notice Return controller address saved in the contract slot
  function controller() external view override returns (address) {
    return _controller();
  }

  function _controller() internal view returns (address result) {
    return _CONTROLLER_SLOT.getAddress();
  }

  /// @notice Return creation timestamp
  /// @return Creation timestamp
  function created() external view override returns (uint256) {
    return _CREATED_SLOT.getUint();
  }

  /// @notice Return creation block number
  /// @return Creation block number
  function createdBlock() external override view returns (uint256) {
    return _CREATED_BLOCK_SLOT.getUint();
  }

  /// @dev Revision should be increased on each contract upgrade
  function increaseRevision(address oldLogic) external override {
    require(msg.sender == address(this), "Increase revision forbidden");
    uint r = _REVISION_SLOT.getUint() + 1;
    _REVISION_SLOT.set(r);
    _PREVIOUS_LOGIC_SLOT.set(oldLogic);
    emit RevisionIncreased(r, oldLogic);
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private _initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private _initializing;

  /**
   * @dev Modifier to protect an initializer function from being invoked twice.
   */
  modifier initializer() {
    // If the contract is initializing we ignore whether _initialized is set in order to support multiple
    // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
    // contract may have been reentered.
    require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

    bool isTopLevelCall = !_initializing;
    if (isTopLevelCall) {
      _initializing = true;
      _initialized = true;
    }

    _;

    if (isTopLevelCall) {
      _initializing = false;
    }
  }

  /**
   * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
   * {initializer} modifier, directly or indirectly.
   */
  modifier onlyInitializing() {
    require(_initializing, "Initializable: contract is not initializing");
    _;
  }

  function _isConstructor() private view returns (bool) {
    return !Address.isContract(address(this));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IControllable {

  function isController(address _contract) external view returns (bool);

  function isGovernance(address _contract) external view returns (bool);

  function created() external view returns (uint256);

  function createdBlock() external view returns (uint256);

  function controller() external view returns (address);

  function increaseRevision(address oldLogic) external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IController {

  function governance() external view returns (address);

  function statController() external view returns (address);

  function chamberController() external view returns (address);

  function oracle() external view returns (address);

  function treasury() external view returns (address);

  function fightCalculator() external view returns (address);

  function dungeonFactory() external view returns (address);

  function fightDelay() external view returns (uint);

  function dungeonMultiplierByLevel(uint level) external view returns (uint);

  function validHeroes(address hero) external view returns (bool);

  function validDungeons(address dungeon) external view returns (bool);

  function validItems(address item) external view returns (bool);

  function heroes(uint id) external view returns (address);

  function dungeons(uint id) external view returns (address);

  function items(uint id) external view returns (address);

  function heroesLength() external view returns (uint);

  function dungeonsLength() external view returns (uint);

  function itemsLength() external view returns (uint);

  function dungeonImplementationsByLevel(uint level, uint index) external view returns (address);

  function dungeonImplementationsLength(uint level) external view returns (uint);

  function registerDungeon(address dungeon_) external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/// @title Library for setting / getting slot variables (used in upgradable proxy contracts)
/// @author bogdoslav
library SlotsLib {

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant SLOT_LIB_VERSION = "1.0.0";

  // ************* GETTERS *******************

  /// @dev Gets a slot as bytes32
  function getBytes32(bytes32 slot) internal view returns (bytes32 result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot as an address
  function getAddress(bytes32 slot) internal view returns (address result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot as uint256
  function getUint(bytes32 slot) internal view returns (uint result) {
    assembly {
      result := sload(slot)
    }
  }

  // ************* ARRAY GETTERS *******************

  /// @dev Gets an array length
  function arrayLength(bytes32 slot) internal view returns (uint result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot array by index as address
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function addressAt(bytes32 slot, uint index) internal view returns (address result) {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      result := sload(pointer)
    }
  }

  // ************* SETTERS *******************

  /// @dev Sets a slot with bytes32
  /// @notice Check address for 0 at the setter
  function set(bytes32 slot, bytes32 value) internal {
    assembly {
      sstore(slot, value)
    }
  }

  /// @dev Sets a slot with address
  /// @notice Check address for 0 at the setter
  function set(bytes32 slot, address value) internal {
    assembly {
      sstore(slot, value)
    }
  }

  /// @dev Sets a slot with uint
  function set(bytes32 slot, uint value) internal {
    assembly {
      sstore(slot, value)
    }
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
  /**
   * @dev Returns true if `account` is a contract.
   *
   * [IMPORTANT]
   * ====
   * It is unsafe to assume that an address for which this function returns
   * false is an externally-owned account (EOA) and not a contract.
   *
   * Among others, `isContract` will return false for the following
   * types of addresses:
   *
   *  - an externally-owned account
   *  - a contract in construction
   *  - an address where a contract will be created
   *  - an address where a contract lived, but was destroyed
   * ====
   */
  function isContract(address account) internal view returns (bool) {
    // This method relies on extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.

    uint256 size;
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }

  /**
   * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
   * `recipient`, forwarding all available gas and reverting on errors.
   *
   * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
   * of certain opcodes, possibly making contracts go over the 2300 gas limit
   * imposed by `transfer`, making them unable to receive funds via
   * `transfer`. {sendValue} removes this limitation.
   *
   * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
   *
   * IMPORTANT: because control is transferred to `recipient`, care must be
   * taken to not create reentrancy vulnerabilities. Consider using
   * {ReentrancyGuard} or the
   * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
   */
  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");

    (bool success, ) = recipient.call{value: amount}("");
    require(success, "Address: unable to send value, recipient may have reverted");
  }

  /**
   * @dev Performs a Solidity function call using a low level `call`. A
   * plain `call` is an unsafe replacement for a function call: use this
   * function instead.
   *
   * If `target` reverts with a revert reason, it is bubbled up by this
   * function (like regular Solidity function calls).
   *
   * Returns the raw returned data. To convert to the expected return value,
   * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
   *
   * Requirements:
   *
   * - `target` must be a contract.
   * - calling `target` with `data` must not revert.
   *
   * _Available since v3.1._
   */
  function functionCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionCall(target, data, "Address: low-level call failed");
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
   * `errorMessage` as a fallback revert reason when `target` reverts.
   *
   * _Available since v3.1._
   */
  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, 0, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but also transferring `value` wei to `target`.
   *
   * Requirements:
   *
   * - the calling contract must have an ETH balance of at least `value`.
   * - the called Solidity function must be `payable`.
   *
   * _Available since v3.1._
   */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
  }

  /**
   * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
   * with `errorMessage` as a fallback revert reason when `target` reverts.
   *
   * _Available since v3.1._
   */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(address(this).balance >= value, "Address: insufficient balance for call");
    require(isContract(target), "Address: call to non-contract");

    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
    return functionStaticCall(target, data, "Address: low-level static call failed");
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    require(isContract(target), "Address: static call to non-contract");

    (bool success, bytes memory returndata) = target.staticcall(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a delegate call.
   *
   * _Available since v3.4._
   */
  function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionDelegateCall(target, data, "Address: low-level delegate call failed");
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
   * but performing a delegate call.
   *
   * _Available since v3.4._
   */
  function functionDelegateCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(isContract(target), "Address: delegate call to non-contract");

    (bool success, bytes memory returndata) = target.delegatecall(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
   * revert reason using the provided one.
   *
   * _Available since v4.3._
   */
  function verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      // Look for revert reason and bubble it up if present
      if (returndata.length > 0) {
        // The easiest way to bubble the revert reason is using memory via assembly

        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
  /**
   * @dev Returns the largest of two numbers.
   */
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  /**
   * @dev Returns the smallest of two numbers.
   */
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  /**
   * @dev Returns the average of two numbers. The result is rounded towards
   * zero.
   */
  function average(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b) / 2 can overflow.
    return (a & b) + (a ^ b) / 2;
  }

  /**
   * @dev Returns the ceiling of the division of two numbers.
   *
   * This differs from standard division with `/` in that it rounds up instead
   * of rounding down.
   */
  function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b - 1) / b can overflow on addition, so we distribute.
    return a / b + (a % b == 0 ? 0 : 1);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
  /**
   * @dev Returns true if this contract implements the interface defined by
   * `interfaceId`. See the corresponding
   * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
   * to learn more about how these ids are created.
   *
   * This function call must use less than 30 000 gas.
   */
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}