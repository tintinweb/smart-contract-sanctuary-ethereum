// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import './libraries/RandomUtil.sol';
import './interfaces/IRagmon.sol';
import './interfaces/IMonsterGene.sol';

contract MonsterGene is IMonsterGene {
  IRagmon private _ragmon;
  using RandomUtil for uint256;
  using RandomUtil for uint16;

  bool public isMonsterGene = true;

  uint256 private constant MONSTER_GRADE_SHIFT = 240;
  uint256 private constant MONSTER_TYPE_SHIFT = 224;
  uint256 private constant RACE_SHIFT = 216;
  uint256 private constant ELEMENT_SHIFT = 208;
  uint256 private constant SIZE_SHIFT = 200;
  uint256 private constant RANGE_ATTACK_SHIFT = 199;

  uint256 private constant STATS_START_SHIFT = 183;
  uint256 private constant STAT_SIZE = 16;
  uint256 private constant NUM_STATS = 6;

  /**
   * @dev Generates a random monster gene based on a monster prototype and a seed.
   * @param prototype The monster prototype to generate the gene for.
   * @param signature The signature to use for the random generation.
   * @return _genes The generated monster gene.
   */
  function generate(
    IRagmon.MonsterPrototype memory prototype,
    string memory signature
  ) public view returns (uint256 _genes) {
    uint256 hashedSeed = RandomUtil.generateSeed(signature);

    _genes = _encodePrototype(prototype);
    _genes = _encodeStats(_genes, hashedSeed, prototype.statRanges);
    _genes = _encodeRemaining(_genes, hashedSeed);
  }

  /**
   * @dev Decodes a monster gene into a decoded monster based on a monster prototype.
   * @param genes The monster gene to decode.
   * @return monster The decoded monster.
   */
  function decode(
    uint256 genes
  ) public pure returns (IRagmon.DecodedMonster memory monster) {
    monster = _decodePrototype(genes);
    monster.stats = _decodeStats(genes).stats;
  }

  /**
   * @dev Merges two genes and returns the resulting gene.
   * The first 6 attributes (str, int, agi, dex, con, luk) are averaged.
   * For the race, element, and size attributes, the resulting gene
   * will have the smaller value if they are different, otherwise
   * it will keep the same value.
   * For the range attack attribute, both parent genes must have a
   * range attack for the resulting gene to have it as well.
   *
   * @param gene1 The first gene to be merged.
   * @param gene2 The second gene to be merged.
   * @return mergedGene The resulting gene after the merge.
   */
  function merge(
    uint256 gene1,
    uint256 gene2,
    string memory signature
  ) public view returns (uint256 mergedGene) {
    uint256 random = RandomUtil.generateSeed(signature).slice(2, 0);
    IRagmon.DecodedMonster memory monster = _decodePrototype(
      random == 0 ? gene1 : gene2
    );

    mergedGene = uint256(monster.monsterGrade);
    mergedGene = (mergedGene << 16) | uint256(monster.monsterType);
    mergedGene = (mergedGene << 8) | uint256(monster.race);
    mergedGene = (mergedGene << 8) | uint256(monster.element);
    mergedGene = (mergedGene << 8) | uint256(monster.size);
    mergedGene = (mergedGene << 1) | uint256(monster.rangeAttack ? 1 : 0);

    // Merge the first 6 stat attributes (strength, intelligence, agility, dexterity, constitution, luck)
    uint256 shift;
    uint256 value1;
    uint256 value2;
    uint256 newValue;
    for (uint256 i = 0; i < NUM_STATS; i++) {
      shift = STATS_START_SHIFT - i * STAT_SIZE;
      value1 = (gene1 >> shift) & 0xFFFF;
      value2 = (gene2 >> shift) & 0xFFFF;
      newValue = (value1 + value2) / 2;

      mergedGene |= (newValue << shift);
    }
  }

  /**
   * @dev Gets the monster type from a monster gene.
   * @param genes The monster gene
   * @return The monster type.
   */
  function decodeMonsterGrade(uint256 genes) public pure returns (uint8) {
    return uint8(genes >> MONSTER_GRADE_SHIFT);
  }

  /**
   * @dev Gets the monster type from a monster gene.
   * @param genes The monster gene
   * @return The monster type.
   */
  function decodeMonsterType(uint256 genes) public pure returns (uint16) {
    return uint16((genes >> MONSTER_TYPE_SHIFT) & 0xFFFF);
  }

  /**
   * @dev Gets dummy genes from a monster gene.
   * @param genes The monster gene
   */
  function decodeMonsterDummyGenes(
    uint256 genes
  ) public pure returns (uint256 dummyGenes) {
    uint256 dummyGenesCount = 256 - (1 + 1) * 16 - (8 + 8 + 8 + 1);
    dummyGenes = genes & ((1 << dummyGenesCount) - 1);
  }

  /**
   * @dev Internal functions to encode or decode a monster gene.
   */

  function _encodePrototype(
    IRagmon.MonsterPrototype memory prototype
  ) internal pure returns (uint256 _genes) {
    _genes = uint256(prototype.monsterGrade);
    _genes = (_genes << 16) | uint256(prototype.monsterType);
    _genes = (_genes << 8) | uint256(prototype.race);
    _genes = (_genes << 8) | uint256(prototype.element);
    _genes = (_genes << 8) | uint256(prototype.size);
    _genes = (_genes << 1) | uint256(prototype.rangeAttack ? 1 : 0);
  }

  function _encodeStats(
    uint256 _genes,
    uint256 hashedSeed,
    uint16[2][6] memory statRanges
  ) internal pure returns (uint256) {
    uint16 clampedValue;
    for (uint256 i = 0; i < NUM_STATS; i++) {
      clampedValue = RandomUtil.clamp(
        RandomUtil.get16Bits(hashedSeed, i),
        statRanges[i][0],
        statRanges[i][1]
      );

      _genes = (_genes << 16) | clampedValue;
    }

    return _genes;
  }

  function _encodeRemaining(
    uint256 _genes,
    uint256 hashedSeed
  ) internal pure returns (uint256) {
    uint256 remainingCount = 256 - (1 + 1) * 16 - (8 + 8 + 8 + 1) - (6 * 16);
    uint256 remaining = RandomUtil.slice(hashedSeed, 6, remainingCount);
    _genes = (_genes << remainingCount) | remaining;

    return _genes;
  }

  function _decodePrototype(
    uint256 genes
  ) internal pure returns (IRagmon.DecodedMonster memory monster) {
    monster.monsterGrade = uint8(genes >> MONSTER_GRADE_SHIFT);
    monster.monsterType = uint16((genes >> MONSTER_TYPE_SHIFT) & 0xFFFF);
    monster.race = uint8((genes >> RACE_SHIFT) & 0xFF);
    monster.element = uint8((genes >> ELEMENT_SHIFT) & 0xFF);
    monster.size = uint8((genes >> SIZE_SHIFT) & 0xFF);
    monster.rangeAttack = (genes >> RANGE_ATTACK_SHIFT) & 0x1 == 1;
  }

  function _decodeStats(
    uint256 genes
  ) internal pure returns (IRagmon.DecodedMonster memory monster) {
    for (uint256 i = 0; i < NUM_STATS; i++) {
      monster.stats[i] = uint16(
        (genes >> (STATS_START_SHIFT - STAT_SIZE * i)) & 0xFFFF
      );
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface IBalanceSheet {
  function isBalanceSheet() external view returns (bool);

  function getCost(uint16 monsterType) external view returns (uint);

  function setCost(uint16 monsterType, uint8 cost) external;

  function getMergeRate(uint8 monsterGrade) external view returns (uint16);

  function setMergeRate(uint8 monsterGrade, uint16 mergeRate) external;

  function getMergeCost(uint8 monsterGrade) external view returns (uint16);

  function setMergeCost(uint8 monsterGrade, uint16 mergeCost) external;

  function getMaxMonsterGrade() external view returns (uint8);

  function setMaxMonsterGrade(uint8 _maxMonsterGrade) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import './IRagmon.sol';

interface IMonsterGene {
  function isMonsterGene() external view returns (bool);

  function generate(
    IRagmon.MonsterPrototype memory prototype,
    string memory signature
  ) external view returns (uint256);

  function decode(
    uint256 gene
  ) external view returns (IRagmon.DecodedMonster memory);

  function merge(
    uint256 gene1,
    uint256 gene2,
    string memory signature
  ) external view returns (uint256);

  function decodeMonsterGrade(uint256 genes) external pure returns (uint8);

  function decodeMonsterType(uint256 genes) external pure returns (uint16);

  function decodeMonsterDummyGenes(
    uint256 genes
  ) external pure returns (uint256 dummyGenes);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/interfaces/IERC721.sol';
import './IBalanceSheet.sol';
import './IMonsterGene.sol';

interface IRagmon is IERC721 {
  struct Monster {
    uint8 monsterGrade;
    uint16 monsterType;
    uint256 genes;
  }

  struct MonsterPrototype {
    string name;
    uint8 monsterGrade;
    uint16 monsterType;
    uint8 race;
    uint8 element;
    uint8 size;
    bool rangeAttack;
    uint16[2][6] statRanges;
  }

  enum Race {
    Angel,
    Brute,
    DemiHuman,
    Demon,
    Dragon,
    Fish,
    Formless,
    Insect,
    Plant,
    Undead
  }

  enum Element {
    Dark,
    Earth,
    Fire,
    Holy,
    Water,
    Wind
  }

  enum Size {
    Large,
    Medium,
    Small
  }

  struct DecodedMonster {
    string name;
    uint8 monsterGrade;
    uint16 monsterType;
    uint8 race;
    uint8 element;
    uint8 size;
    bool rangeAttack;
    uint16[6] stats; // STR, AGI, LUK, INT, DEX, CON
  }

  function isRagmon() external view returns (bool);

  function balanceSheet() external view returns (IBalanceSheet);

  function monsterGene() external view returns (IMonsterGene);

  function setBaseURI(string calldata baseTokenURI) external;

  function mintMonster(
    uint8 monsterGrade,
    uint16 monsterType,
    uint256 genes
  ) external returns (uint256);

  function mintMonster(
    uint8 monsterGrade,
    uint16 monsterType,
    uint256 genes,
    address receiver
  ) external returns (uint256);

  function burn(uint256 tokenId) external;

  function getMonster(uint256 tokenId) external view returns (Monster memory);

  function setAllowedMonsterType(
    uint8 monsterGrade,
    uint16 monsterType,
    bool enabled
  ) external;

  function getAllowedMonsterTypes(
    uint8 monsterGrade
  ) external view returns (uint16[] memory);

  function setMinter(address minter, bool enabled) external;

  function isMinter(address account) external view returns (bool);

  function getPrototype(
    uint16 monsterType
  ) external view returns (MonsterPrototype memory);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

library RandomUtil {
  function generateSeed(
    string memory _signature
  ) internal view returns (uint256) {
    return
      uint256(
        keccak256(
          abi.encodePacked(
            block.timestamp,
            block.difficulty,
            msg.sender,
            _signature
          )
        )
      );
  }

  /**
   * @dev given a number get a slice of any bits, at certain offset
   * @param _input a number to be sliced
   * @param _nbits how many bits long is the new number
   * @param _offset how many bits to skip
   */
  function slice(
    uint256 _input,
    uint256 _nbits,
    uint256 _offset
  ) internal pure returns (uint256) {
    // mask is made by shifting left an offset number of times
    uint256 mask = uint256((2 ** _nbits) - 1) << _offset;
    // AND n with mask, and trim to max of _nbits bits
    return uint256((_input & mask) >> _offset);
  }

  function clamp(
    uint16 _input,
    uint16 _min,
    uint16 _max
  ) internal pure onlyProperRange(_min, _max) returns (uint16) {
    return (_input % (_max - _min + 1)) + _min;
  }

  function get16Bits(
    uint256 _input,
    uint256 _slot
  ) internal pure returns (uint16) {
    return uint16(slice(_input, uint256(16), _slot * 16));
  }

  function determineRandomValue(
    uint256 _input,
    uint256 _min,
    uint256 _max
  ) internal pure onlyProperRange(_min, _max) returns (uint256) {
    return (_input % (_max - _min + 1)) + _min;
  }

  modifier onlyProperRange(uint256 _min, uint256 _max) {
    require(
      _min <= _max,
      'Min value should be less than or equal to max value'
    );
    _;
  }
}