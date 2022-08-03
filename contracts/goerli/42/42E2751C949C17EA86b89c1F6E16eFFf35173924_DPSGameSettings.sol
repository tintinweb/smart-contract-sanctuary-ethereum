//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/DPSStructs.sol";
import "./interfaces/DPSInterfaces.sol";

contract DPSGameSettings is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /**
     * @notice Voyage config per each voyage type
     */
    mapping(uint256 => CartographerConfig) public voyageConfigPerType;

    /**
     * @notice multiplication skills per each part. each level multiplies by this base skill points
     */
    mapping(FLAGSHIP_PART => uint16) public skillsPerFlagshipPart;

    /**
     * @notice dividing each flagship part into different skills type
     */
    mapping(uint8 => FLAGSHIP_PART[]) public partsForEachSkillType;

    /**
     * @notice flagship base skills
     */
    uint16 public flagshipBaseSkills;

    /**
     * @notice max points a sail can have per skill: strength, luck, navigation.
     * if any goes above this point, then this will act as a hard cap
     */
    uint16 public maxSkillsCap = 630;

    /**
     * @notice max points the causality can generate
     */
    uint16 public maxRollCap = 700;

    /**
     * @notice max points the causality can generate for awarding LockBoxes
     */
    uint16 public maxRollCapLockBoxes = 101;

    /**
     * @notice tmap per buying a voyage
     */
    mapping(uint256 => uint256) public tmapPerVoyage;

    /**
     * @notice gap between 2 consecutive buyVoyages, in seconds.
     */
    uint256 public gapBetweenVoyagesCreation;

    /**
     * @notice in case of emergency to pause different components of the protocol
     * index meaning:
     * - 0 - pause swap tmaps for doubloons
     * - 1 - pause swap doubloons for tmaps
     * - 2 - pause buy a voyage using tmaps
     * - 3 - pause burns a voyage
     * - 4 - pause locks voyages
     * - 5 - pause claiming rewards on Docks
     * - 6 - pause lockToClaimRewards from chests
     * - 7 - pause lock locked boxes
     * - 8 - pause claim locked chests
     * - 9 - pause claiming locked lock boxes
     * - 10 - pause claiming a flagship
     * - 11 - pause repairing a damaged ship
     * - 12 - pause upgrade parts of flagship for doubloons
     * - 13 - pause buy support ships
     */
    uint8[] public paused;

    /**
     * @notice tmaps per doubloons, in wei
     */
    uint256 public tmapPerDoubloon;

    /**
     * @notice max lock boxes that someone can open at a time
     */
    uint256 public maxOpenLockBoxes;

    /**
     * @notice repair flagship cost in doubloons
     */
    uint256 public repairFlagshipCost;

    /**
     * @notice doubloons needed to buy 1 support ship of type SUPPORT_SHIP_TYPE
     */
    mapping(SUPPORT_SHIP_TYPE => uint256) public doubloonsPerSupportShipType;

    /**
     * @notice skill boosts per support ship type
     */
    mapping(SUPPORT_SHIP_TYPE => uint16) public supportShipsSkillBoosts;

    /**
     * @notice skill boosts per artifact type
     */
    mapping(ARTIFACT_TYPE => uint16) public artifactsSkillBoosts;

    /**
     * @notice the max no of ships you can attach per voyage type
     */
    mapping(uint256 => uint8) public maxSupportShipsPerVoyageType;

    /**
     * @notice the amount of doubloons that can be rewarded per chest opened
     */
    mapping(uint256 => uint256) public chestDoubloonRewards;

    /**
     * @notice max rollout that can win a lockbox per chest type (Voyage type)
     * what this means is that out of a roll between 0-10000 if a number between 0 and maxRollPerChest is rolled then
     * the user won a lockbox of the type corresponding with the chest type
     */
    mapping(uint256 => uint256) public maxRollPerChest;

    /**
     * @notice out of 102 distribution of how we will determine the artifact rewards
     */
    mapping(ARTIFACT_TYPE => uint16[2]) public lockBoxesDistribution;

    /**
     * @notice debuffs for every voyage type
     */
    mapping(uint256 => uint16) public voyageDebuffs;

    /**
     * @notice max number of artifacts per voyage type
     */
    mapping(uint16 => uint256) public maxArtifactsPerVoyage;

    /**
     * @notice doubloon price in wei per upgrade part of the flagship per each level as each level can have a diff price
     */
    mapping(uint256 => uint256) public doubloonPerFlagshipUpgradePerLevel;

    event TokenRecovered(address indexed _token, address _destination, uint256 _amount);
    event SetContract(string indexed _target, address _contract);
    event Debug(uint256);

    constructor() {
        voyageConfigPerType[0].minNoOfChests = 4;
        voyageConfigPerType[0].maxNoOfChests = 4;
        voyageConfigPerType[0].minNoOfStorms = 1;
        voyageConfigPerType[0].maxNoOfStorms = 1;
        voyageConfigPerType[0].minNoOfEnemies = 1;
        voyageConfigPerType[0].maxNoOfEnemies = 1;
        voyageConfigPerType[0].totalInteractions = 6;
        voyageConfigPerType[0].gapBetweenInteractions = 60;

        voyageConfigPerType[1].minNoOfChests = 4;
        voyageConfigPerType[1].maxNoOfChests = 6;
        voyageConfigPerType[1].minNoOfStorms = 3;
        voyageConfigPerType[1].maxNoOfStorms = 4;
        voyageConfigPerType[1].minNoOfEnemies = 3;
        voyageConfigPerType[1].maxNoOfEnemies = 4;
        voyageConfigPerType[1].totalInteractions = 12;
        voyageConfigPerType[1].gapBetweenInteractions = 60;

        voyageConfigPerType[2].minNoOfChests = 6;
        voyageConfigPerType[2].maxNoOfChests = 8;
        voyageConfigPerType[2].minNoOfStorms = 5;
        voyageConfigPerType[2].maxNoOfStorms = 6;
        voyageConfigPerType[2].minNoOfEnemies = 5;
        voyageConfigPerType[2].maxNoOfEnemies = 6;
        voyageConfigPerType[2].totalInteractions = 18;
        voyageConfigPerType[2].gapBetweenInteractions = 60;

        voyageConfigPerType[3].minNoOfChests = 8;
        voyageConfigPerType[3].maxNoOfChests = 12;
        voyageConfigPerType[3].minNoOfStorms = 7;
        voyageConfigPerType[3].maxNoOfStorms = 8;
        voyageConfigPerType[3].minNoOfEnemies = 7;
        voyageConfigPerType[3].maxNoOfEnemies = 8;
        voyageConfigPerType[3].totalInteractions = 24;
        voyageConfigPerType[3].gapBetweenInteractions = 60;

        skillsPerFlagshipPart[FLAGSHIP_PART.CANNON] = 10;
        skillsPerFlagshipPart[FLAGSHIP_PART.HULL] = 10;
        skillsPerFlagshipPart[FLAGSHIP_PART.SAILS] = 10;
        skillsPerFlagshipPart[FLAGSHIP_PART.HELM] = 10;
        skillsPerFlagshipPart[FLAGSHIP_PART.FLAG] = 10;
        skillsPerFlagshipPart[FLAGSHIP_PART.FIGUREHEAD] = 10;

        flagshipBaseSkills = 250;

        partsForEachSkillType[uint8(SKILL_TYPE.LUCK)] = [FLAGSHIP_PART.FLAG, FLAGSHIP_PART.FIGUREHEAD];
        partsForEachSkillType[uint8(SKILL_TYPE.NAVIGATION)] = [FLAGSHIP_PART.SAILS, FLAGSHIP_PART.HELM];
        partsForEachSkillType[uint8(SKILL_TYPE.STRENGTH)] = [FLAGSHIP_PART.CANNON, FLAGSHIP_PART.HULL];

        tmapPerVoyage[0] = 1 * 1e18;
        tmapPerVoyage[1] = 2 * 1e18;
        tmapPerVoyage[2] = 3 * 1e18;
        tmapPerVoyage[3] = 4 * 1e18;

        paused.push(0);
        paused.push(0);
        paused.push(0);
        paused.push(0);
        paused.push(0);
        paused.push(0);
        paused.push(0);
        paused.push(0);
        paused.push(0);
        paused.push(0);
        paused.push(0);
        paused.push(0);
        paused.push(0);
        paused.push(0);

        tmapPerDoubloon = 10;

        maxOpenLockBoxes = 1;

        repairFlagshipCost = 35 * 1e18;

        doubloonsPerSupportShipType[SUPPORT_SHIP_TYPE.SLOOP_STRENGTH] = 15 * 1e18;
        doubloonsPerSupportShipType[SUPPORT_SHIP_TYPE.SLOOP_LUCK] = 15 * 1e18;
        doubloonsPerSupportShipType[SUPPORT_SHIP_TYPE.SLOOP_NAVIGATION] = 15 * 1e18;

        doubloonsPerSupportShipType[SUPPORT_SHIP_TYPE.CARAVEL_STRENGTH] = 30 * 1e18;
        doubloonsPerSupportShipType[SUPPORT_SHIP_TYPE.CARAVEL_LUCK] = 30 * 1e18;
        doubloonsPerSupportShipType[SUPPORT_SHIP_TYPE.CARAVEL_NAVIGATION] = 30 * 1e18;

        doubloonsPerSupportShipType[SUPPORT_SHIP_TYPE.GALLEON_STRENGTH] = 50 * 1e18;
        doubloonsPerSupportShipType[SUPPORT_SHIP_TYPE.GALLEON_LUCK] = 50 * 1e18;
        doubloonsPerSupportShipType[SUPPORT_SHIP_TYPE.GALLEON_NAVIGATION] = 50 * 1e18;

        supportShipsSkillBoosts[SUPPORT_SHIP_TYPE.SLOOP_STRENGTH] = 10;
        supportShipsSkillBoosts[SUPPORT_SHIP_TYPE.SLOOP_LUCK] = 10;
        supportShipsSkillBoosts[SUPPORT_SHIP_TYPE.SLOOP_NAVIGATION] = 10;

        supportShipsSkillBoosts[SUPPORT_SHIP_TYPE.CARAVEL_STRENGTH] = 30;
        supportShipsSkillBoosts[SUPPORT_SHIP_TYPE.CARAVEL_LUCK] = 30;
        supportShipsSkillBoosts[SUPPORT_SHIP_TYPE.CARAVEL_NAVIGATION] = 30;

        supportShipsSkillBoosts[SUPPORT_SHIP_TYPE.GALLEON_STRENGTH] = 50;
        supportShipsSkillBoosts[SUPPORT_SHIP_TYPE.GALLEON_LUCK] = 50;
        supportShipsSkillBoosts[SUPPORT_SHIP_TYPE.GALLEON_NAVIGATION] = 50;

        maxSupportShipsPerVoyageType[0] = 2;
        maxSupportShipsPerVoyageType[1] = 3;
        maxSupportShipsPerVoyageType[2] = 4;
        maxSupportShipsPerVoyageType[3] = 5;

        artifactsSkillBoosts[ARTIFACT_TYPE.NONE] = 0;
        artifactsSkillBoosts[ARTIFACT_TYPE.COMMON_STRENGTH] = 40;
        artifactsSkillBoosts[ARTIFACT_TYPE.COMMON_LUCK] = 40;
        artifactsSkillBoosts[ARTIFACT_TYPE.COMMON_NAVIGATION] = 40;

        artifactsSkillBoosts[ARTIFACT_TYPE.RARE_STRENGTH] = 60;
        artifactsSkillBoosts[ARTIFACT_TYPE.RARE_LUCK] = 60;
        artifactsSkillBoosts[ARTIFACT_TYPE.RARE_NAVIGATION] = 60;

        artifactsSkillBoosts[ARTIFACT_TYPE.EPIC_STRENGTH] = 90;
        artifactsSkillBoosts[ARTIFACT_TYPE.EPIC_LUCK] = 90;
        artifactsSkillBoosts[ARTIFACT_TYPE.EPIC_NAVIGATION] = 90;

        artifactsSkillBoosts[ARTIFACT_TYPE.LEGENDARY_STRENGTH] = 140;
        artifactsSkillBoosts[ARTIFACT_TYPE.LEGENDARY_LUCK] = 140;
        artifactsSkillBoosts[ARTIFACT_TYPE.LEGENDARY_NAVIGATION] = 140;

        chestDoubloonRewards[0] = 45 * 1e18;
        chestDoubloonRewards[1] = 65 * 1e18;
        chestDoubloonRewards[2] = 85 * 1e18;
        chestDoubloonRewards[3] = 105 * 1e18;

        maxRollPerChest[0] = 4;
        maxRollPerChest[1] = 5;
        maxRollPerChest[2] = 8;
        maxRollPerChest[3] = 12;

        lockBoxesDistribution[ARTIFACT_TYPE.COMMON_STRENGTH] = [0, 21];
        lockBoxesDistribution[ARTIFACT_TYPE.COMMON_LUCK] = [22, 43];
        lockBoxesDistribution[ARTIFACT_TYPE.COMMON_NAVIGATION] = [44, 65];

        lockBoxesDistribution[ARTIFACT_TYPE.RARE_STRENGTH] = [66, 72];
        lockBoxesDistribution[ARTIFACT_TYPE.RARE_LUCK] = [73, 79];
        lockBoxesDistribution[ARTIFACT_TYPE.RARE_NAVIGATION] = [80, 86];

        lockBoxesDistribution[ARTIFACT_TYPE.EPIC_STRENGTH] = [87, 89];
        lockBoxesDistribution[ARTIFACT_TYPE.EPIC_LUCK] = [90, 92];
        lockBoxesDistribution[ARTIFACT_TYPE.EPIC_NAVIGATION] = [93, 95];

        lockBoxesDistribution[ARTIFACT_TYPE.LEGENDARY_STRENGTH] = [96, 97];
        lockBoxesDistribution[ARTIFACT_TYPE.LEGENDARY_LUCK] = [98, 99];
        lockBoxesDistribution[ARTIFACT_TYPE.LEGENDARY_NAVIGATION] = [100, 101];

        voyageDebuffs[0] = 0;
        voyageDebuffs[1] = 100;
        voyageDebuffs[2] = 180;
        voyageDebuffs[3] = 260;

        maxArtifactsPerVoyage[uint16(VOYAGE_TYPE.EASY)] = 3;
        maxArtifactsPerVoyage[uint16(VOYAGE_TYPE.MEDIUM)] = 3;
        maxArtifactsPerVoyage[uint16(VOYAGE_TYPE.HARD)] = 3;
        maxArtifactsPerVoyage[uint16(VOYAGE_TYPE.LEGENDARY)] = 3;
        maxArtifactsPerVoyage[uint16(VOYAGE_TYPE.CUSTOM)] = 3;

        doubloonPerFlagshipUpgradePerLevel[0] = 0;
        doubloonPerFlagshipUpgradePerLevel[1] = 0;
        doubloonPerFlagshipUpgradePerLevel[2] = 300 * 1e18;
        doubloonPerFlagshipUpgradePerLevel[3] = 415 * 1e18;
        doubloonPerFlagshipUpgradePerLevel[4] = 530 * 1e18;
        doubloonPerFlagshipUpgradePerLevel[5] = 645 * 1e18;
        doubloonPerFlagshipUpgradePerLevel[6] = 760 * 1e18;
        doubloonPerFlagshipUpgradePerLevel[7] = 875 * 1e18;
        doubloonPerFlagshipUpgradePerLevel[8] = 990 * 1e18;
        doubloonPerFlagshipUpgradePerLevel[9] = 1105 * 1e18;
        doubloonPerFlagshipUpgradePerLevel[10] = 1220 * 1e18;
    }

    function setVoyageConfig(CartographerConfig calldata config, uint256 _type) external onlyOwner {
        voyageConfigPerType[_type] = config;
    }

    function setTmapPerVoyage(uint256 _type, uint256 _amount) external onlyOwner {
        tmapPerVoyage[_type] = _amount;
    }

    function setTmapPerDoubloon(uint256 _amount) external onlyOwner {
        tmapPerDoubloon = _amount;
    }

    function setDoubloonPerFlagshipUpgradePerLevel(uint256 _level, uint256 _amount) external onlyOwner {
        doubloonPerFlagshipUpgradePerLevel[_level] = _amount;
    }

    function setVoyageConfigPerType(uint256 _type, CartographerConfig calldata _config) external onlyOwner {
        voyageConfigPerType[_type].minNoOfChests = _config.minNoOfChests;
        voyageConfigPerType[_type].maxNoOfChests = _config.maxNoOfChests;
        voyageConfigPerType[_type].minNoOfStorms = _config.minNoOfStorms;
        voyageConfigPerType[_type].maxNoOfStorms = _config.maxNoOfStorms;
        voyageConfigPerType[_type].minNoOfEnemies = _config.minNoOfEnemies;
        voyageConfigPerType[_type].maxNoOfEnemies = _config.maxNoOfEnemies;
        voyageConfigPerType[_type].totalInteractions = _config.totalInteractions;
        voyageConfigPerType[_type].gapBetweenInteractions = _config.gapBetweenInteractions;
    }

    function setSkillsPerFlagshipPart(FLAGSHIP_PART _part, uint16 _amount) external onlyOwner {
        skillsPerFlagshipPart[_part] = _amount;
    }

    function setGapBetweenVoyagesCreation(uint256 _newGap) external onlyOwner {
        gapBetweenVoyagesCreation = _newGap;
    }

    function setMaxSkillsCap(uint16 _newCap) external onlyOwner {
        maxSkillsCap = _newCap;
    }

    function setMaxRollCap(uint16 _newCap) external onlyOwner {
        maxRollCap = _newCap;
    }

    function setDoubloonsPerSupportShipType(SUPPORT_SHIP_TYPE _type, uint256 _amount) external onlyOwner {
        doubloonsPerSupportShipType[_type] = _amount;
    }

    function setSupportShipsSkillBoosts(SUPPORT_SHIP_TYPE _type, uint16 _skillPoinst) external onlyOwner {
        supportShipsSkillBoosts[_type] = _skillPoinst;
    }

    function setArtifactSkillBoosts(ARTIFACT_TYPE _type, uint16 _skillPoinst) external onlyOwner {
        artifactsSkillBoosts[_type] = _skillPoinst;
    }

    function setLockBoxesDistribution(ARTIFACT_TYPE _type, uint16[2] calldata _limits) external onlyOwner {
        lockBoxesDistribution[_type] = _limits;
    }

    function setChestDoubloonRewards(uint256 _type, uint256 _rewards) external onlyOwner {
        chestDoubloonRewards[_type] = _rewards;
    }

    function setMaxRollCapLockBoxes(uint16 _maxRollCap) external onlyOwner {
        maxRollCapLockBoxes = _maxRollCap;
    }

    function setMaxRollPerChest(uint256 _type, uint256 _roll) external onlyOwner {
        maxRollPerChest[_type] = _roll;
    }

    function setMaxSupportShipsPerVoyageType(uint256 _type, uint8 _max) external onlyOwner {
        maxSupportShipsPerVoyageType[_type] = _max;
    }

    function setMaxOpenLockBoxes(uint256 _newMax) external onlyOwner {
        maxOpenLockBoxes = _newMax;
    }

    function setRepairFlagshipCost(uint256 _newCost) external onlyOwner {
        repairFlagshipCost = _newCost;
    }

    function setVoyageDebuffs(uint256 _type, uint16 _newDebuff) external onlyOwner {
        voyageDebuffs[_type] = _newDebuff;
    }

    function setMaxArtifactsPerVoyage(VOYAGE_TYPE _type, uint256 _newMax) external onlyOwner {
        maxArtifactsPerVoyage[uint16(_type)] = _newMax;
    }

    function pauseComponent(uint8 _component, uint8 _pause) external onlyOwner {
        paused[_component] = _pause;
    }

    function getSkillTypeOfEachFlagshipPart() public view returns (uint8[7] memory skillTypes) {
        for (uint8 i; i < 3; ++i) {
            for (uint8 j = 0; j < partsForEachSkillType[i].length; ++j) {
                skillTypes[uint256(partsForEachSkillType[i][j])] = i;
            }
        }
    }

    function getSkillsPerFlagshipParts() public view returns (uint16[7] memory skills) {
        skills[uint256(FLAGSHIP_PART.CANNON)] = skillsPerFlagshipPart[FLAGSHIP_PART.CANNON];
        skills[uint256(FLAGSHIP_PART.HULL)] = skillsPerFlagshipPart[FLAGSHIP_PART.HULL];
        skills[uint256(FLAGSHIP_PART.SAILS)] = skillsPerFlagshipPart[FLAGSHIP_PART.SAILS];
        skills[uint256(FLAGSHIP_PART.HELM)] = skillsPerFlagshipPart[FLAGSHIP_PART.HELM];
        skills[uint256(FLAGSHIP_PART.FLAG)] = skillsPerFlagshipPart[FLAGSHIP_PART.FLAG];
        skills[uint256(FLAGSHIP_PART.FIGUREHEAD)] = skillsPerFlagshipPart[FLAGSHIP_PART.FIGUREHEAD];
    }

    function getLockBoxesDistribution(ARTIFACT_TYPE _type) external view returns (uint16[2] memory) {
        return lockBoxesDistribution[_type];
    }

    function isPaused(uint8 _component) external nonReentrant returns (uint8) {
        return paused[_component];
    }

    function isPausedNonReentrant(uint8 _component) external view {
        if (paused[_component] == 1) revert Paused();
    }

    /**
     * @notice Recover NFT sent by mistake to the contract
     * @param _nft the NFT address
     * @param _destination where to send the NFT
     * @param _tokenId the token to want to recover
     */
    function recoverNFT(
        address _nft,
        address _destination,
        uint256 _tokenId
    ) external onlyOwner {
        require(_destination != address(0), "Destination !address(0)");
        IERC721(_nft).safeTransferFrom(address(this), _destination, _tokenId);
        emit TokenRecovered(_nft, _destination, _tokenId);
    }

    /**
     * @notice Recover TOKENS sent by mistake to the contract
     * @param _token the TOKEN address
     * @param _destination where to send the NFT
     */
    function recoverERC20(address _token, address _destination) external onlyOwner {
        require(_destination != address(0), "Destination !address(0)");
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(_destination, amount);
        emit TokenRecovered(_token, _destination, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./DPSInterfaces.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

enum VOYAGE_TYPE {
    EASY,
    MEDIUM,
    HARD,
    LEGENDARY,
    CUSTOM
}

enum SUPPORT_SHIP_TYPE {
    SLOOP_STRENGTH,
    SLOOP_LUCK,
    SLOOP_NAVIGATION,
    CARAVEL_STRENGTH,
    CARAVEL_LUCK,
    CARAVEL_NAVIGATION,
    GALLEON_STRENGTH,
    GALLEON_LUCK,
    GALLEON_NAVIGATION
}

enum ARTIFACT_TYPE {
    NONE,
    COMMON_STRENGTH,
    COMMON_LUCK,
    COMMON_NAVIGATION,
    RARE_STRENGTH,
    RARE_LUCK,
    RARE_NAVIGATION,
    EPIC_STRENGTH,
    EPIC_LUCK,
    EPIC_NAVIGATION,
    LEGENDARY_STRENGTH,
    LEGENDARY_LUCK,
    LEGENDARY_NAVIGATION
}

enum INTERACTION {
    NONE,
    CHEST,
    STORM,
    ENEMY
}

enum FLAGSHIP_PART {
    HEALTH,
    CANNON,
    HULL,
    SAILS,
    HELM,
    FLAG,
    FIGUREHEAD
}

enum SKILL_TYPE {
    LUCK,
    STRENGTH,
    NAVIGATION
}

struct VoyageConfig {
    VOYAGE_TYPE typeOfVoyage;
    uint8 noOfInteractions;
    uint16 noOfBlockJumps;
    // 1 - Chest 2 - Storm 3 - Enemy
    uint8[] sequence;
    uint256 boughtAt;
    uint256 gapBetweenInteractions;
}

struct VoyageConfigV2 {
    uint16 typeOfVoyage;
    uint8 noOfInteractions;
    // 1 - Chest 2 - Storm 3 - Enemy
    uint8[] sequence;
    uint256 boughtAt;
    uint256 gapBetweenInteractions;
    bytes uniqueId;
}

struct CartographerConfig {
    uint8 minNoOfChests;
    uint8 maxNoOfChests;
    uint8 minNoOfStorms;
    uint8 maxNoOfStorms;
    uint8 minNoOfEnemies;
    uint8 maxNoOfEnemies;
    uint8 totalInteractions;
    uint256 gapBetweenInteractions;
}

struct RandomInteractions {
    uint256 randomNoOfChests;
    uint256 randomNoOfStorms;
    uint256 randomNoOfEnemies;
    uint8 generatedChests;
    uint8 generatedStorms;
    uint8 generatedEnemies;
    uint256[] positionsForGeneratingInteractions;
    uint256 randomPosition;
}

struct CausalityParams {
    uint256[] blockNumber;
    bytes32[] hash1;
    bytes32[] hash2;
    uint256[] timestamp;
    bytes[] signature;
}

struct LockedVoyage {
    uint8 totalSupportShips;
    VOYAGE_TYPE voyageType;
    ARTIFACT_TYPE artifactId;
    uint8[9] supportShips; //this should be an array for each type, expressing the quantities he took on a trip
    uint8[] sequence;
    uint16 navigation;
    uint16 luck;
    uint16 strength;
    uint256 voyageId;
    uint256 dpsId;
    uint256 flagshipId;
    uint256 lockedBlock;
    uint256 lockedTimestamp;
    uint256 claimedTime;
}

struct LockedVoyageV2 {
    uint8 totalSupportShips;
    uint16 voyageType;
    uint16[13] artifactIds;
    uint8[9] supportShips; //this should be an array for each type, expressing the quantities he took on a trip
    uint8[] sequence;
    uint16 navigation;
    uint16 luck;
    uint16 strength;
    uint256 voyageId;
    uint256 dpsId;
    uint256 flagshipId;
    uint256 lockedBlock;
    uint256 lockedTimestamp;
    uint256 claimedTime;
    bytes uniqueId;
    DPSVoyageIV2 voyage;
    IERC721Metadata pirate;
    DPSFlagshipI flagship;
}

struct VoyageResult {
    uint16 awardedChests;
    uint8[9] destroyedSupportShips;
    uint8 totalSupportShipsDestroyed;
    uint8 healthDamage;
    uint16 skippedInteractions;
    uint16[] interactionRNGs;
    uint8[] interactionResults;
    uint8[] intDestroyedSupportShips;
}

struct VoyageStatusCache {
    uint256 strength;
    uint256 luck;
    uint256 navigation;
    string entropy;
}

error AddressZero();
error Paused();
error WrongParams(uint256 _location);
error WrongState(uint256 _state);
error Unauthorized();
error NotEnoughTokens();
error Unhealthy();
error ExternalCallFailed();
error NotFulfilled();

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "./DPSStructs.sol";

interface DPSVoyageI is IERC721Enumerable {
    function mint(
        address _owner,
        uint256 _tokenId,
        VoyageConfig calldata config
    ) external;

    function burn(uint256 _tokenId) external;

    function getVoyageConfig(uint256 _voyageId) external view returns (VoyageConfig memory config);

    function tokensOfOwner(address _owner) external view returns (uint256[] memory);

    function exists(uint256 _tokenId) external view returns (bool);

    function maxMintedId() external view returns (uint256);

    function maxMintedId(uint16 _voyageType) external view returns (uint256);
}

interface DPSVoyageIV2 is IERC721Enumerable {
    function mint(
        address _owner,
        uint256 _tokenId,
        VoyageConfigV2 calldata config
    ) external;

    function burn(uint256 _tokenId) external;

    function getVoyageConfig(uint256 _voyageId) external view returns (VoyageConfigV2 memory config);

    function tokensOfOwner(address _owner) external view returns (uint256[] memory);

    function exists(uint256 _tokenId) external view returns (bool);

    function maxMintedId() external view returns (uint256);

    function maxMintedId(uint16 _voyageType) external view returns (uint256);
}

interface DPSRandomI {
    function getRandomBatch(
        address _address,
        uint256[] memory _blockNumber,
        bytes32[] memory _hash1,
        bytes32[] memory _hash2,
        uint256[] memory _timestamp,
        bytes[] calldata _signature,
        string[] calldata _entropy,
        uint256 _min,
        uint256 _max
    ) external view returns (uint256[] memory randoms);

    function getRandomUnverifiedBatch(
        address _address,
        uint256[] memory _blockNumber,
        bytes32[] memory _hash1,
        bytes32[] memory _hash2,
        uint256[] memory _timestamp,
        string[] calldata _entropy,
        uint256 _min,
        uint256 _max
    ) external pure returns (uint256[] memory randoms);

    function getRandom(
        address _address,
        uint256 _blockNumber,
        bytes32 _hash1,
        bytes32 _hash2,
        uint256 _timestamp,
        bytes calldata _signature,
        string calldata _entropy,
        uint256 _min,
        uint256 _max
    ) external view returns (uint256 randoms);

    function getRandomUnverified(
        address _address,
        uint256 _blockNumber,
        bytes32 _hash1,
        bytes32 _hash2,
        uint256 _timestamp,
        string calldata _entropy,
        uint256 _min,
        uint256 _max
    ) external pure returns (uint256 randoms);

    function checkCausalityParams(
        CausalityParams calldata _causalityParams,
        VoyageConfigV2 calldata _voyageConfig,
        LockedVoyageV2 calldata _lockedVoyage
    ) external pure;
}

interface DPSGameSettingsI {
    function voyageConfigPerType(uint256 _type) external view returns (CartographerConfig memory);

    function maxSkillsCap() external view returns (uint16);

    function maxRollCap() external view returns (uint16);

    function flagshipBaseSkills() external view returns (uint16);

    function maxOpenLockBoxes() external view returns (uint256);

    function getSkillsPerFlagshipParts() external view returns (uint16[7] memory skills);

    function getSkillTypeOfEachFlagshipPart() external view returns (uint8[7] memory skillTypes);

    function tmapPerVoyage(uint256 _type) external view returns (uint256);

    function gapBetweenVoyagesCreation() external view returns (uint256);

    function isPaused(uint8 _component) external returns (uint8);

    function isPausedNonReentrant(uint8 _component) external view;

    function tmapPerDoubloon() external view returns (uint256);

    function repairFlagshipCost() external view returns (uint256);

    function doubloonPerFlagshipUpgradePerLevel(uint256 _level) external view returns (uint256);

    function voyageDebuffs(uint256 _type) external view returns (uint16);

    function maxArtifactsPerVoyage(uint16 _type) external view returns (uint256);

    function chestDoubloonRewards(uint256 _type) external view returns (uint256);

    function doubloonsPerSupportShipType(SUPPORT_SHIP_TYPE _type) external view returns (uint256);

    function supportShipsSkillBoosts(SUPPORT_SHIP_TYPE _type) external view returns (uint16);

    function maxSupportShipsPerVoyageType(uint256 _type) external view returns (uint8);

    function maxRollPerChest(uint256 _type) external view returns (uint256);

    function maxRollCapLockBoxes() external view returns (uint16);

    function lockBoxesDistribution(ARTIFACT_TYPE _type) external view returns (uint16[2] memory);

    function getLockBoxesDistribution(ARTIFACT_TYPE _type) external view returns (uint16[2] memory);

    function artifactsSkillBoosts(ARTIFACT_TYPE _type) external view returns (uint16);
}

interface DPSGameEngineI {
    function sanityCheckLockVoyages(
        LockedVoyageV2 memory existingVoyage,
        LockedVoyageV2 memory finishedVoyage,
        LockedVoyageV2 memory lockedVoyage,
        VoyageConfigV2 memory voyageConfig,
        uint256 totalSupportShips,
        DPSFlagshipI _flagship
    ) external view;

    function computeVoyageState(
        LockedVoyageV2 memory _lockedVoyage,
        uint8[] memory _sequence,
        uint256 _randomNumber
    ) external view returns (VoyageResult memory);

    function rewardChest(
        uint256 _randomNumber,
        uint256 _amount,
        uint256 _voyageType,
        address _owner
    ) external;

    function rewardLockedBox(
        uint256 _randomNumber,
        uint256 _amount,
        address _owner
    ) external;
}

interface DPSPirateFeaturesI {
    function getTraitsAndSkills(uint16 _dpsId) external view returns (string[8] memory, uint16[3] memory);
}

interface DPSSupportShipI is IERC1155 {
    function burn(
        address _from,
        uint256 _type,
        uint256 _amount
    ) external;

    function mint(
        address _owner,
        uint256 _type,
        uint256 _amount
    ) external;
}

interface DPSFlagshipI is IERC721 {
    function mint(address _owner, uint256 _id) external;

    function burn(uint256 _id) external;

    function upgradePart(
        FLAGSHIP_PART _trait,
        uint256 _tokenId,
        uint8 _level
    ) external;

    function getPartsLevel(uint256 _flagshipId) external view returns (uint8[7] memory);

    function tokensOfOwner(address _owner) external view returns (uint256[] memory);

    function exists(uint256 _tokenId) external view returns (bool);
}

interface DPSCartographerI {
    function viewVoyageConfiguration(uint256 _voyageId, DPSVoyageIV2 _voyage)
        external
        view
        returns (VoyageConfigV2 memory voyageConfig);

    function buyers(uint256 _voyageId) external view returns (address);
}

interface DPSChestsI is IERC1155 {
    function mint(
        address _to,
        uint16 _voyageType,
        uint256 _amount
    ) external;

    function burn(
        address _from,
        uint16 _voyageType,
        uint256 _amount
    ) external;
}

interface DPSChestsIV2 is IERC1155 {
    function mint(
        address _to,
        uint256 _type,
        uint256 _amount
    ) external;

    function burn(
        address _from,
        uint256 _type,
        uint256 _amount
    ) external;
}

interface MintableBurnableIERC1155 is IERC1155 {
    function mint(
        address _to,
        uint256 _type,
        uint256 _amount
    ) external;

    function burn(
        address _from,
        uint256 _type,
        uint256 _amount
    ) external;
}

interface DPSDocksI {
    function getFinishedVoyagesForOwner(
        address _owner,
        uint256 _start,
        uint256 _stop
    ) external view returns (LockedVoyageV2[] memory finished);

    function getLockedVoyagesForOwner(
        address _owner,
        uint256 _start,
        uint256 _stop
    ) external view returns (LockedVoyageV2[] memory locked);
}

interface DPSQRNGI {
    function makeRequestUint256(bytes calldata _uniqueId) external;

    function makeRequestUint256Array(uint256 _size, bytes32 _uniqueId) external;

    function getRandomResult(bytes calldata _uniqueId) external view returns (uint256);

    function getRandomResultArray(bytes32 _uniqueId) external view returns (uint256[] memory);

    function getRandomNumber(
        uint256 _randomNumber,
        uint256 _blockNumber,
        string calldata _entropy,
        uint256 _min,
        uint256 _max
    ) external pure returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}