// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../lib/StatLib.sol";

contract StatReader {

  function chanceToHit(
    uint attackersAttackRating,
    uint defendersDefenceRating,
    uint attackersLevel,
    uint defendersLevel
  ) external pure returns (uint) {
    return StatLib.chanceToHit(
      attackersAttackRating,
      defendersDefenceRating,
      attackersLevel,
      defendersLevel
    );
  }

  function levelExperience(uint level) external pure returns (uint) {
    return StatLib.levelExperience(level);
  }

  function startHeroAttributes(uint heroClass) external pure returns (
    IStatController.CoreAttributes memory,
    StatLib.BaseMultiplier memory,
    StatLib.LevelUp memory
  ) {
    return (
    StatLib.initialCore(heroClass),
    StatLib.multipliers(heroClass),
    StatLib.levelUps(heroClass)
    );
  }

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