// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {UUPSUpgradeV} from "UDS/proxy/UUPSUpgradeV.sol";
import {OwnableUDS} from "UDS/OwnableUDS.sol";

import {IERC721} from "./interfaces/IERC721.sol";

// import {GangWarBase} from "./GangWarBase.sol";
// import {GMCMarket} from "./GMCMarket.sol";
// import {ds, settings, District, Gangster} from
import "./GangWarStorage.sol";
import "./GangWarRewards.sol";
import "./GangWarBase.sol";
// import {GangWarGameLogic} from "./GangWarGameLogic.sol";
import "./GangWarGameLogic.sol";

/* ============= Error ============= */

contract GangWar is UUPSUpgradeV(1), OwnableUDS, GangWarStorage, GangWarGameLogic, GangWarLoot {
    constructor(
        address coordinator,
        bytes32 keyHash,
        uint64 subscriptionId,
        uint16 requestConfirmations,
        uint32 callbackGasLimit
    ) VRFConsumerV2(coordinator, keyHash, subscriptionId, requestConfirmations, callbackGasLimit) {}

    function init(address gmc) external initializer {
        __Ownable_init();
        __GangWarBase_init(gmc);
        __GangWarGameLogic_init();
        __GangWarLoot_init();
    }

    /* ------------- Owner ------------- */

    function setDistrictsInitialOwnership(uint256[] calldata districtIds, GANG[] calldata gangs) external onlyOwner {
        for (uint256 i; i < districtIds.length; ++i) {
            ds().districts[districtIds[i]].occupants = gangs[i];
        }
    }

    function addDistrictConnections(uint256[] calldata districtsA, uint256[] calldata districtsB) external onlyOwner {
        for (uint256 i; i < districtsA.length; ++i) {
            assert(districtsA[i] < districtsB[i]);
            ds().districtConnections[districtsA[i]][districtsB[i]] = true;
        }
    }

    function removeDistrictConnections(uint256[] calldata districtsA, uint256[] calldata districtsB)
        external
        onlyOwner
    {
        for (uint256 i; i < districtsA.length; ++i) {
            assert(districtsA[i] < districtsB[i]);
            ds().districtConnections[districtsA[i]][districtsB[i]] = false;
        }
    }

    /* ------------- Internal ------------- */

    function multiCall(bytes[] calldata calldata_) external {
        for (uint256 i; i < calldata_.length; ++i) address(this).delegatecall(calldata_[i]);
    }

    /* ------------- Internal ------------- */

    function _afterDistrictTransfer(
        GANG attackers,
        GANG defenders,
        uint256 id
    ) internal override {}

    function _authorizeUpgrade() internal override onlyOwner {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC1822Versioned, ERC1822Versioned} from "./ERC1822Versioned.sol";
import {ERC1967Versioned, DIAMOND_STORAGE_ERC1967_UPGRADE} from "./ERC1967VersionedUDS.sol";

/* ============= Storage ============= */

// keccak256("diamond.storage.uups.versioned.upgrade") == 0x84baf5225d2c25e851ba08f5463fbda2857188d63388c0dc9b62907467b54b47;
bytes32 constant DIAMOND_STORAGE_UUPS_VERSIONED_UPGRADE = 0x84baf5225d2c25e851ba08f5463fbda2857188d63388c0dc9b62907467b54b47;

struct UUPSUpgradeVDS {
    uint256 version;
}

function ds() pure returns (UUPSUpgradeVDS storage diamondStorage) {
    assembly {
        diamondStorage.slot := DIAMOND_STORAGE_UUPS_VERSIONED_UPGRADE
    }
}

/* ============= Errors ============= */

error OnlyProxyCallAllowed();
error DelegateCallNotAllowed();

/* ============= UUPSUpgradeV ============= */

abstract contract UUPSUpgradeV is ERC1967Versioned, ERC1822Versioned {
    address private immutable __implementation = address(this);
    uint256 private immutable __version;

    constructor(uint256 version) {
        __version = version;
    }

    function proxiableVersion() public view override returns (uint256) {
        return __version;
    }

    /* ------------- External ------------- */

    function upgradeTo(address logic) external payable {
        _authorizeUpgrade();
        _upgradeToAndCall(logic, "");
    }

    function upgradeToAndCall(address logic, bytes calldata data) external payable {
        _authorizeUpgrade();
        _upgradeToAndCall(logic, data);
    }

    /* ------------- View ------------- */

    function proxiableUUID() external view notDelegated returns (bytes32) {
        return DIAMOND_STORAGE_ERC1967_UPGRADE;
    }

    /* ------------- Virtual ------------- */

    function _authorizeUpgrade() internal virtual;

    /* ------------- Modifier ------------- */

    modifier onlyProxy() {
        if (address(this) == __implementation) revert OnlyProxyCallAllowed();
        _;
    }

    modifier notDelegated() {
        if (address(this) != __implementation) revert DelegateCallNotAllowed();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {InitializableUDS} from "./InitializableUDS.sol";

/* ============= Storage ============= */

// keccak256("diamond.storage.ownable") == 0x87917b04fc43108fc3d291ac961b425fe1ddcf80087b2cb7e3c48f3e9233ea33;
bytes32 constant DIAMOND_STORAGE_OWNABLE = 0x87917b04fc43108fc3d291ac961b425fe1ddcf80087b2cb7e3c48f3e9233ea33;

struct OwnableDS {
    address owner;
}

function ds() pure returns (OwnableDS storage diamondStorage) {
    assembly {
        diamondStorage.slot := DIAMOND_STORAGE_OWNABLE
    }
}

/* ============= Errors ============= */

error CallerNotOwner();

/* ============= OwnableUDS ============= */

abstract contract OwnableUDS is InitializableUDS {
    address private immutable deployer;

    constructor() {
        deployer = msg.sender; // fallback owner
    }

    function __Ownable_init() internal initializer {
        ds().owner = msg.sender;
    }

    /* ------------- External ------------- */

    function owner() public view returns (address) {
        address _owner = ds().owner;
        return _owner != address(0) ? _owner : deployer;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        ds().owner = newOwner;
    }

    /* ------------- Modifier ------------- */

    modifier onlyOwner() {
        if (msg.sender != owner()) revert CallerNotOwner();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721UDS} from "UDS/ERC721UDS.sol";
// import "./GangWarBase.sol";

/* ============= Constants ============= */
// uint256 constant STATUS_IDLE = 0;
// uint256 constant STATUS_ATTACK = 1;
// uint256 constant STATUS_DEFEND = 2;
// uint256 constant STATUS_RECOVERY = 3;
// uint256 constant STATUS_LOCKUP = 4;

/* ============= Storage ============= */

// keccak256("diamond.storage.gang.war") == 0x1465defc4302777e9f3331026df5b673e1fdbf0798e6f23608defa528993ece8;
bytes32 constant DIAMOND_STORAGE_GANG_WAR = 0x1465defc4302777e9f3331026df5b673e1fdbf0798e6f23608defa528993ece8;

// keccak256("diamond.storage.gang.war.settings") == 0x8888f95c81e8a85148526340bc32f8046bd9cdfc432a8ade56077881a62383a9;
bytes32 constant DIAMOND_STORAGE_GANG_WAR_SETTINGS = 0x8888f95c81e8a85148526340bc32f8046bd9cdfc432a8ade56077881a62383a9;

/* ============= Enum ============= */

enum GANG {
    NONE,
    YAKUZA,
    CARTEL,
    CYBERP
}

enum DISTRICT_STATE {
    IDLE,
    REINFORCEMENT,
    GANG_WAR,
    POST_GANG_WAR,
    TRUCE
}

enum PLAYER_STATE {
    IDLE,
    ATTACK,
    ATTACK_LOCKED,
    DEFEND,
    DEFEND_LOCKED,
    INJURED,
    LOCKUP
}

/* ============= Struct ============= */

struct Gangster {
    uint256 roundId;
    uint256 location;
}

struct GangsterView {
    GANG gang;
    PLAYER_STATE state;
    int256 stateCountdown;
    uint256 roundId;
    uint256 location;
}

struct District {
    GANG occupants;
    GANG attackers;
    uint256 roundId;
    uint256 attackDeclarationTime;
    uint256 baronAttackId;
    uint256 baronDefenseId;
    uint256 lastUpkeepTime;
    uint256 lastOutcomeTime;
    uint256 lockupTime;
    uint256 yield;
}

struct GangWarDS {
    ERC721UDS gmc;
    mapping(uint256 => District) districts;
    mapping(uint256 => Gangster) gangsters;
    /*   districtId => districtIds  */
    mapping(uint256 => uint256[]) requestIdToDistrictIds;
    /*   districtId =>     roundId     => outcome  */
    mapping(uint256 => mapping(uint256 => uint256)) gangWarOutcomes;
    /*   districtId =>     roundId     =>         GANG => numForces */
    mapping(uint256 => mapping(uint256 => mapping(GANG => uint256))) districtAttackForces;
    mapping(uint256 => mapping(uint256 => mapping(GANG => uint256))) districtDefenseForces;
    mapping(uint256 => mapping(uint256 => bool)) districtConnections;
    mapping(GANG => uint256) gangYield;
}

struct ConstantsDS {
    uint256 TIME_TRUCE;
    uint256 TIME_LOCKUP;
    uint256 TIME_GANG_WAR;
    uint256 TIME_RECOVERY;
    uint256 TIME_REINFORCEMENTS;
    uint256 DEFENSE_FAVOR_LIM;
    uint256 BARON_DEFENSE_FORCE;
    uint256 ATTACK_FAVOR;
    uint256 DEFENSE_FAVOR;
}

function ds() pure returns (GangWarDS storage diamondStorage) {
    assembly {
        diamondStorage.slot := DIAMOND_STORAGE_GANG_WAR
    }
}

function constants() pure returns (ConstantsDS storage diamondStorage) {
    assembly {
        diamondStorage.slot := DIAMOND_STORAGE_GANG_WAR_SETTINGS
    }
}

abstract contract GangWarStorage {
    /* ------------- View ------------- */

    // function getDistrict(uint256 districtId) external view returns (District memory) {
    //     return ds().districts[districtId];
    // }

    function getDistrict(uint256 districtId) external view returns (District memory) {
        return ds().districts[districtId];
    }

    function getDistrictConnections(uint256 districtA, uint256 districtB) external view returns (bool) {
        return ds().districtConnections[districtA][districtB];
    }

    function getDistrictAttackForces(
        uint256 districtId,
        uint256 roundId,
        GANG gang
    ) external view returns (uint256) {
        return ds().districtAttackForces[districtId][roundId][gang];
    }

    function getDistrictDefenseForces(
        uint256 districtId,
        uint256 roundId,
        GANG gang
    ) external view returns (uint256) {
        return ds().districtDefenseForces[districtId][roundId][gang];
    }

    function getGangWarOutcome(uint256 districtId, uint256 roundId) external view returns (uint256) {
        return ds().gangWarOutcomes[districtId][roundId];
    }

    function getConstants() external pure returns (ConstantsDS memory) {
        return constants();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {UUPSUpgradeV} from "UDS/proxy/UUPSUpgradeV.sol";
import {OwnableUDS} from "UDS/OwnableUDS.sol";
import {ERC721UDS} from "UDS/ERC721UDS.sol";

// import {GangWarBase} from "./GangWarBase.sol";
// import {GMCMarket} from "./GMCMarket.sol";
// import {ds, settings, District, Gangster} from
import "./GangWarStorage.sol";
// import "./GangWarBase.sol";

import "forge-std/console.sol";

/* ============= Error ============= */

// error BaronMustDeclareInitialAttack();

abstract contract GangWarLoot {
    /* ------------- Internal ------------- */

    function __GangWarLoot_init() internal {
        uint256 yield;
        for (uint256 id; id < 21; ++id) {
            GANG occupants = ds().districts[id].occupants;
            yield = ds().districts[id].yield;
            ds().gangYield[occupants] += yield;

            assert(occupants != GANG.NONE);
            assert(yield > 0);
        }
    }

    function updateGangRewards(
        GANG attackers,
        GANG defenders,
        uint256 districtId
    ) internal {
        uint256 yield = ds().districts[districtId].yield;

        ds().gangYield[attackers] += yield;
        ds().gangYield[defenders] -= yield;
    }

    /* ------------- View ------------- */

    function getGangYields()
        external
        view
        returns (
            uint256 yieldYakuza,
            uint256 yieldCartel,
            uint256 yieldCyberpunk
        )
    {
        yieldYakuza = ds().gangYield[GANG.YAKUZA];
        yieldCartel = ds().gangYield[GANG.CARTEL];
        yieldCyberpunk = ds().gangYield[GANG.CYBERP];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import {UUPSUpgradeV} from "UDS/proxy/UUPSUpgradeV.sol";
// import {OwnableUDS} from "UDS/OwnableUDS.sol";
import {IERC721} from "./interfaces/IERC721.sol";

import "./GangWarStorage.sol";

/* ============= Error ============= */

error CallerNotOwner();

abstract contract GangWarBase {
    IERC721 gmc;

    function __GangWarBase_init(address gmc_) internal {
        gmc = IERC721(gmc_);
    }

    /* ------------- View ------------- */

    function isBaron(uint256 tokenId) internal pure returns (bool) {
        return tokenId >= 1000;
    }

    function gangOf(uint256 id) public pure returns (GANG) {
        return id == 0 ? GANG.NONE : GANG(((id < 1000 ? id - 1 : id - 1001) % 3) + 1);
    }

    function _validateOwnership(address owner, uint256 tokenId) internal view {
        if (gmc.ownerOf(tokenId) != owner) revert CallerNotOwner();
    }

    function isConnecting(uint256 districtA, uint256 districtB) internal view returns (bool) {
        return
            districtA < districtB
                ? ds().districtConnections[districtA][districtB]
                : ds().districtConnections[districtB][districtA]; // prettier-ignore
    }

    function _afterDistrictTransfer(
        GANG attackers,
        GANG defenders,
        uint256 id
    ) internal virtual;

    /* ------------- Public ------------- */

    /* ------------- Internal ------------- */
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {UUPSUpgradeV} from "UDS/proxy/UUPSUpgradeV.sol";
import {OwnableUDS} from "UDS/OwnableUDS.sol";
import {ERC721UDS} from "UDS/ERC721UDS.sol";

// import {ds, settings, District, Gangster} from
import "./GangWarStorage.sol";
import "./GangWarBase.sol";

// import "forge-std/console.sol";

import "./lib/ArrayUtils.sol";
import {VRFConsumerV2} from "./lib/VRFConsumerV2.sol";

/* ============= Error ============= */

error BaronMustDeclareInitialAttack();
error IdsMustBeOfSameGang();
error ConnectingDistrictNotOwnedByGang();
error GangsterInactionable();
error BaronInactionable();
error InvalidConnectingDistrict();

error MoveOnCooldown();
error TokenMustBeGangster();
error TokenMustBeBaron();
error BaronAttackAlreadyDeclared();
error CannotAttackDistrictOwnedByGang();

function gangWarWonProb(
    uint256 attackForce,
    uint256 defenseForce,
    bool baronDefense,
    uint256 c_attackFavor,
    uint256 c_defenseFavor,
    uint256 c_defenseFavorLim,
    uint256 c_baronDefenseForce
) pure returns (uint256) {
    attackForce += 1;
    defenseForce += 1;

    uint256 s = attackForce < c_defenseFavorLim
            ? ((1 << 32) - (attackForce << 32) / c_defenseFavorLim)**2
            : 0; // prettier-ignore

    defenseForce = ((s * c_defenseFavor + ((1 << 64) - s) * c_attackFavor) * defenseForce) / 100;

    if (baronDefense) defenseForce += c_baronDefenseForce << 64;

    uint256 p = (attackForce << 128) / ((attackForce << 64) + defenseForce);

    if (p > 1 << 63) p = (1 << 192) - ((((1 << 64) - p)**3) << 2);
    else p = (p**3) << 2;

    return p >> 64; // >> 128
}

abstract contract GangWarGameLogic is GangWarBase, VRFConsumerV2 {
    function __GangWarGameLogic_init() internal {
        constants().TIME_GANG_WAR = 100;
        constants().TIME_LOCKUP = 100;
        constants().TIME_TRUCE = 100;
        constants().TIME_RECOVERY = 100;
        constants().TIME_REINFORCEMENTS = 100;

        constants().DEFENSE_FAVOR_LIM = 150;
        constants().BARON_DEFENSE_FORCE = 50;
        constants().ATTACK_FAVOR = 65;
        constants().DEFENSE_FAVOR = 200;

        for (uint256 id; id < 21; ++id) {
            ds().districts[id].roundId = 1;
            ds().districts[id].occupants = GANG((id % 3) + 1);
            ds().districts[id].yield = 100 + (id / 3);
        }
    }

    /* ------------- Public ------------- */

    function baronDeclareAttack(
        uint256 connectingId,
        uint256 districtId,
        uint256 tokenId
    ) external {
        GANG gang = gangOf(tokenId);
        District storage district = ds().districts[districtId];

        // console.log('occupants', ds().districts[connecting])

        _validateOwnership(msg.sender, tokenId);

        if (!isBaron(tokenId)) revert TokenMustBeBaron();
        if (district.baronAttackId != 0) revert BaronAttackAlreadyDeclared();
        if (ds().districts[districtId].occupants == gang) revert CannotAttackDistrictOwnedByGang();
        if (ds().districts[connectingId].occupants != gang) revert ConnectingDistrictNotOwnedByGang();
        if (districtId == connectingId || !isConnecting(connectingId, districtId)) revert InvalidConnectingDistrict();

        (PLAYER_STATE state, ) = _gangsterStateAndCountdown(tokenId);

        if (state != PLAYER_STATE.IDLE) revert BaronInactionable();

        Gangster storage baron = ds().gangsters[tokenId];

        baron.location = districtId;
        baron.roundId = ds().districts[districtId].roundId;

        district.attackers = gang;
        district.baronAttackId = tokenId;
        district.attackDeclarationTime = block.timestamp;
    }

    function joinGangAttack(
        uint256 connectingId,
        uint256 districtId,
        uint256[] calldata tokenIds
    ) public {
        GANG gang = gangOf(tokenIds[0]);
        District storage district = ds().districts[districtId];

        if (ds().districts[connectingId].occupants != gang) revert InvalidConnectingDistrict();
        if (gangOf(district.baronAttackId) != gang) revert BaronMustDeclareInitialAttack();
        if (districtId == connectingId || !ds().districtConnections[connectingId][districtId])
            revert InvalidConnectingDistrict();

        _joinGangWar(districtId, tokenIds);
    }

    function joinGangDefense(uint256 districtId, uint256[] calldata tokenIds) public {
        GANG gang = gangOf(tokenIds[0]);

        if (ds().districts[districtId].occupants != gang) revert InvalidConnectingDistrict();

        _joinGangWar(districtId, tokenIds);
    }

    function _joinGangWar(uint256 districtId, uint256[] calldata tokenIds) internal {
        uint256 tokenId;
        Gangster storage gangster;
        District storage district = ds().districts[districtId];

        GANG gang = gangOf(tokenIds[0]);

        uint256 districtRoundId = district.roundId;

        for (uint256 i; i < tokenIds.length; ++i) {
            tokenId = tokenIds[i];

            if (isBaron(tokenId)) revert TokenMustBeGangster();
            if (gang != gangOf(tokenId)) revert IdsMustBeOfSameGang();
            _validateOwnership(msg.sender, tokenId);

            gangster = ds().gangsters[tokenId];

            (PLAYER_STATE state, ) = _gangsterStateAndCountdown(tokenId);

            if (
                state == PLAYER_STATE.ATTACK_LOCKED ||
                state == PLAYER_STATE.DEFEND_LOCKED ||
                state == PLAYER_STATE.INJURED ||
                state == PLAYER_STATE.LOCKUP
            ) revert GangsterInactionable();

            gangster.location = districtId;
            gangster.roundId = districtRoundId;

            // @remove from old district
        }

        ds().districtAttackForces[districtId][districtRoundId][gang] += tokenIds.length;
    }

    /* ------------- Internal ------------- */

    function getGangster(uint256 tokenId) external view returns (GangsterView memory gangster) {
        Gangster storage gangsterStore = ds().gangsters[tokenId];

        (gangster.state, gangster.stateCountdown) = _gangsterStateAndCountdown(tokenId);
        gangster.roundId = gangsterStore.roundId;
        gangster.location = gangsterStore.location;
    }

    function getDistrictAndState(uint256 districtId) external view returns (District memory, DISTRICT_STATE) {
        return (ds().districts[districtId], _districtStatus(ds().districts[districtId]));
    }

    function _gangsterStateAndCountdown(uint256 gangsterId) internal view returns (PLAYER_STATE, int256) {
        Gangster storage gangster = ds().gangsters[gangsterId];

        uint256 districtId = gangster.location;
        District storage district = ds().districts[districtId];

        GANG gang = gangOf(gangsterId);

        uint256 roundId = district.roundId;

        // gangster not in sync with district => IDLE
        if (gangster.roundId != roundId) return (PLAYER_STATE.IDLE, 0);

        bool attacking;

        if (district.attackers == gang) attacking = true;
        else assert(district.occupants == gang);
        // else if (district.occupants == gang) {
        //     attacking = false;
        // }

        int256 stateCountdown;

        // -------- check lockup
        stateCountdown = int256(constants().TIME_LOCKUP) - int256(block.timestamp - district.lockupTime);
        if (stateCountdown > 0) return (PLAYER_STATE.LOCKUP, stateCountdown);

        // -------- check gang war outcome
        stateCountdown =
            int256(constants().TIME_REINFORCEMENTS) -
            int256(block.timestamp - district.attackDeclarationTime);
        uint256 outcome = ds().gangWarOutcomes[districtId][roundId];

        // player in attack/defense mode; not committed yet
        if (stateCountdown > 0) return (attacking ? PLAYER_STATE.ATTACK : PLAYER_STATE.DEFEND, stateCountdown);

        stateCountdown += int256(constants().TIME_GANG_WAR);

        // outcome can only be triggered by upkeep after additional TIME_GANG_WAR has passed
        // this will release players from lock after injury has been checked
        if (outcome == 0) return (attacking ? PLAYER_STATE.ATTACK_LOCKED : PLAYER_STATE.DEFEND_LOCKED, stateCountdown);

        // -------- check injury
        bool injured = outcome & 1 == 0;

        if (!injured) return (PLAYER_STATE.IDLE, 0);

        stateCountdown = int256(constants().TIME_RECOVERY) + stateCountdown;
        if (stateCountdown > 0) return (PLAYER_STATE.INJURED, stateCountdown);

        return (PLAYER_STATE.IDLE, 0);
    }

    function _districtStatus(District storage district) internal view returns (DISTRICT_STATE) {
        uint256 attackDeclarationTime = district.attackDeclarationTime;

        // console.log("atk", attackDeclarationTime);
        // console.log("upk", district.lastUpkeepTime);

        if (attackDeclarationTime == 0 || attackDeclarationTime < district.lastOutcomeTime) {
            if (block.timestamp - district.lastOutcomeTime < constants().TIME_TRUCE) return DISTRICT_STATE.TRUCE;

            return DISTRICT_STATE.IDLE;
        }
        uint256 timeDelta = block.timestamp - attackDeclarationTime;
        if (timeDelta < constants().TIME_REINFORCEMENTS) {
            return DISTRICT_STATE.REINFORCEMENT;
        }
        timeDelta -= constants().TIME_REINFORCEMENTS;
        if (timeDelta < constants().TIME_GANG_WAR) {
            return DISTRICT_STATE.GANG_WAR;
        }
        return DISTRICT_STATE.POST_GANG_WAR;
    }

    /* ------------- Upkeep ------------- */

    uint256 private constant UPKEEP_INTERVAL = 1 minutes;

    function checkUpkeep(bytes calldata) external view returns (bool, bytes memory) {
        bool upkeepNeeded;
        District storage district;

        uint256[] memory districtUpkeepIds;

        for (uint256 id; id < 21; ++id) {
            district = ds().districts[id];

            if (
                _districtStatus(district) == DISTRICT_STATE.POST_GANG_WAR &&
                block.timestamp - district.lastUpkeepTime > UPKEEP_INTERVAL // at least wait 1 minute for re-run
            ) {
                upkeepNeeded = true;
                districtUpkeepIds = ArrayUtils.extend(districtUpkeepIds, id);
            }
        }

        return (upkeepNeeded, abi.encode(districtUpkeepIds));
    }

    // @note could exceed gas limits
    // optimize
    function performUpkeep(bytes calldata performData) external {
        uint256[] memory districtIds = abi.decode(performData, (uint256[]));

        uint256 length = districtIds.length;

        for (uint256 i; i < length; ++i) {
            uint256 districtId = districtIds[i];
            District storage district = ds().districts[districtId];

            if (
                _districtStatus(district) == DISTRICT_STATE.POST_GANG_WAR &&
                block.timestamp - district.lastUpkeepTime > UPKEEP_INTERVAL // at least wait 1 minute for re-run
            ) {
                district.lastUpkeepTime = block.timestamp;
                uint256 requestId = requestRandomWords(1);
                ds().requestIdToDistrictIds[requestId] = districtIds;
            }
        }
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        uint256[] storage districtIds = ds().requestIdToDistrictIds[requestId];
        uint256 length = districtIds.length;
        uint256 rand = randomWords[0];

        for (uint256 i; i < length; ++i) {
            uint256 districtId = districtIds[i];

            District storage district = ds().districts[districtId];

            if (_districtStatus(district) == DISTRICT_STATE.POST_GANG_WAR) {
                GANG occupants = district.occupants;
                GANG attackers = district.attackers;

                uint256 roundId = district.roundId++;

                uint256 r = uint256(keccak256(abi.encode(rand, i)));

                ds().gangWarOutcomes[districtId][roundId] = r;
                district.lastOutcomeTime = block.timestamp;

                if (gangWarWon(districtId, roundId, r)) {
                    _afterDistrictTransfer(attackers, occupants, districtId);

                    district.occupants = attackers;
                    district.attackers = GANG.NONE;
                }

                district.attackDeclarationTime = 0;
                district.baronAttackId = 0;
                district.baronDefenseId = 0;
            }
        }

        delete ds().requestIdToDistrictIds[requestId];
    }

    /* ------------- Private ------------- */

    function gangWarWon(
        uint256 districtId,
        uint256 roundId,
        uint256 rand
    ) private view returns (bool) {
        District storage district = ds().districts[districtId];

        uint256 attackForce = ds().districtAttackForces[districtId][roundId][district.attackers];
        uint256 defenseForce = ds().districtDefenseForces[districtId][roundId][district.occupants];

        bool baronDefense = district.baronDefenseId != 0;

        uint256 c_defenseFavorLim = constants().DEFENSE_FAVOR_LIM;
        uint256 c_baronDefenseForce = constants().BARON_DEFENSE_FORCE;
        uint256 c_attackFavor = constants().ATTACK_FAVOR;
        uint256 c_defenseFavor = constants().DEFENSE_FAVOR;

        return
            rand >> 128 <
            gangWarWonProb(
                attackForce,
                defenseForce,
                baronDefense,
                c_attackFavor,
                c_defenseFavor,
                c_defenseFavorLim,
                c_baronDefenseForce
            );
    }

    /* ------------- Internal ------------- */
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC1822Versioned {
    function proxiableVersion() external view returns (uint256);

    function proxiableUUID() external view returns (bytes32);
}

abstract contract ERC1822Versioned is IERC1822Versioned {
    function proxiableVersion() public view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC1822Versioned} from "./ERC1822Versioned.sol";

/* ============= Storage ============= */

// keccak256("eip1967.proxy.implementation") - 1 = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
bytes32 constant DIAMOND_STORAGE_ERC1967_UPGRADE = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

struct ERC1967VersionedUpgradeDS {
    address implementation;
    uint256 version;
}

function ds() pure returns (ERC1967VersionedUpgradeDS storage diamondStorage) {
    assembly {
        diamondStorage.slot := DIAMOND_STORAGE_ERC1967_UPGRADE
    }
}

/* ============= Errors ============= */

error InvalidUUID();
error InvalidOwner();
error NotAContract();
error InvalidUpgradeVersion();

/* ============= ERC1967Versioned ============= */

abstract contract ERC1967Versioned {
    event Upgraded(address indexed implementation, uint256 indexed version);

    function _upgradeToAndCall(address logic, bytes memory data) internal {
        if (logic.code.length == 0) revert NotAContract();

        bytes32 uuid = IERC1822Versioned(logic).proxiableUUID();
        uint256 newVersion = IERC1822Versioned(logic).proxiableVersion();

        if (ds().version >= newVersion) revert InvalidUpgradeVersion();
        if (uuid != DIAMOND_STORAGE_ERC1967_UPGRADE) revert InvalidUUID();

        emit Upgraded(logic, newVersion);

        if (data.length != 0) {
            (bool success, bytes memory returndata) = logic.delegatecall(data);

            if (!success) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            }
        }

        ds().version = newVersion;
        ds().implementation = logic;
    }
}

/* ------------- ERC1967Proxy ------------- */

contract ERC1967Proxy is ERC1967Versioned {
    constructor(address logic, bytes memory data) payable {
        _upgradeToAndCall(logic, data);
    }

    fallback() external payable {
        assembly {
            calldatacopy(0, 0, calldatasize())

            let success := delegatecall(gas(), sload(DIAMOND_STORAGE_ERC1967_UPGRADE), 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch success
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC1822Versioned} from "./proxy/ERC1822Versioned.sol";
import {ds as erc1967DS} from "./proxy/ERC1967VersionedUDS.sol";

/* ============= Errors ============= */

error NotInitializing();
error ProxyCallRequired();
error InvalidInitializerVersion();

/* ============= InitializableUDS ============= */

abstract contract InitializableUDS is ERC1822Versioned {
    address private immutable __implementation = address(this);

    /* ------------- Modifier ------------- */

    modifier initializer() {
        if (address(this) == __implementation) revert ProxyCallRequired();
        if (proxiableVersion() <= erc1967DS().version) revert InvalidInitializerVersion();

        _;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {InitializableUDS} from "./InitializableUDS.sol";
import {EIP712PermitUDS} from "./EIP712PermitUDS.sol";

/* ============= Storage ============= */

struct ERC721DS {
    string name;
    string symbol;
    mapping(uint256 => address) owners;
    mapping(address => uint256) balances;
    mapping(uint256 => address) getApproved;
    mapping(address => mapping(address => bool)) isApprovedForAll;
}

// keccak256("diamond.storage.erc721") == 0xf2dec0acaef95de6625646379d631adff4db9f6c79b84a31adcb9a23bf6cea78;
bytes32 constant DIAMOND_STORAGE_ERC721 = 0xf2dec0acaef95de6625646379d631adff4db9f6c79b84a31adcb9a23bf6cea78;

function ds() pure returns (ERC721DS storage diamondStorage) {
    assembly {
        diamondStorage.slot := DIAMOND_STORAGE_ERC721
    }
}

/* ============= Errors ============= */

error CallerNotOwnerNorApproved();
error NonexistentToken();
error NonERC721Receiver();

error BalanceOfZeroAddress();

error MintExistingToken();
error MintToZeroAddress();
error MintZeroQuantity();
error MintExceedsMaxSupply();
error MintExceedsMaxPerWallet();

error TransferFromIncorrectOwner();
error TransferToZeroAddress();

/* ============= ERC721UDS ============= */

/// @notice Adapted for usage with Diamond Storage
/// @author phaze (https://github.com/0xPhaze)
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721UDS is InitializableUDS, EIP712PermitUDS {
    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event Approval(address indexed owner, address indexed spender, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /* ------------- Init ------------- */

    function __ERC721UDS_init(string memory name_, string memory symbol_) internal initializer {
        ds().name = name_;
        ds().symbol = symbol_;
    }

    /* ------------- View ------------- */

    function tokenURI(uint256 id) public view virtual returns (string memory);

    function name() external view returns (string memory) {
        return ds().name;
    }

    function symbol() external view returns (string memory) {
        return ds().symbol;
    }

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        if ((owner = ds().owners[id]) == address(0)) revert NonexistentToken();
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        if (owner == address(0)) revert BalanceOfZeroAddress();

        return ds().balances[owner];
    }

    function getApproved(uint256 id) public view returns (address) {
        return ds().getApproved[id];
    }

    function isApprovedForAll(address operator, address owner) public view returns (bool) {
        return ds().isApprovedForAll[operator][owner];
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /* ------------- Public ------------- */

    function approve(address spender, uint256 id) public virtual {
        address owner = ds().owners[id];

        if (msg.sender != owner && !ds().isApprovedForAll[owner][msg.sender]) revert CallerNotOwnerNorApproved();

        ds().getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        ds().isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        if (to == address(0)) revert TransferToZeroAddress();
        if (from != ds().owners[id]) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (msg.sender == from ||
            ds().isApprovedForAll[from][msg.sender] ||
            ds().getApproved[id] == msg.sender);

        if (!isApprovedOrOwner) revert CallerNotOwnerNorApproved();

        unchecked {
            ds().balances[from]--;
            ds().balances[to]++;
        }

        ds().owners[id] = to;

        delete ds().getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        if (
            to.code.length != 0 &&
            ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") !=
            ERC721TokenReceiver.onERC721Received.selector
        ) revert NonERC721Receiver();
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        if (
            to.code.length != 0 &&
            ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) !=
            ERC721TokenReceiver.onERC721Received.selector
        ) revert NonERC721Receiver();
    }

    // EIP-4494 permit; differs from the current EIP
    function permit(
        address owner,
        address operator,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        if (_usePermit(owner, operator, 1, deadline, v, r, s)) {
            ds().isApprovedForAll[owner][operator] = true;
            emit ApprovalForAll(owner, operator, true);
        }
    }

    /* ------------- Internal ------------- */

    function _mint(address to, uint256 id) internal virtual {
        if (to == address(0)) revert MintToZeroAddress();
        if (ds().owners[id] != address(0)) revert MintExistingToken();

        unchecked {
            ds().balances[to]++;
        }

        ds().owners[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = ds().owners[id];

        if (owner == address(0)) revert NonexistentToken();

        unchecked {
            ds().balances[owner]--;
        }

        delete ds().owners[id];
        delete ds().getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        if (
            to.code.length != 0 &&
            ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") !=
            ERC721TokenReceiver.onERC721Received.selector
        ) revert NonERC721Receiver();
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        if (
            to.code.length != 0 &&
            ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) !=
            ERC721TokenReceiver.onERC721Received.selector
        ) revert NonERC721Receiver();
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

library console {
    address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

    function _sendLogPayload(bytes memory payload) private view {
        uint256 payloadLength = payload.length;
        address consoleAddress = CONSOLE_ADDRESS;
        /// @solidity memory-safe-assembly
        assembly {
            let payloadStart := add(payload, 32)
            let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
        }
    }

    function log() internal view {
        _sendLogPayload(abi.encodeWithSignature("log()"));
    }

    function logInt(int p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(int)", p0));
    }

    function logUint(uint p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
    }

    function logString(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function logBool(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function logAddress(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function logBytes(bytes memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
    }

    function logBytes1(bytes1 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
    }

    function logBytes2(bytes2 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
    }

    function logBytes3(bytes3 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
    }

    function logBytes4(bytes4 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
    }

    function logBytes5(bytes5 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
    }

    function logBytes6(bytes6 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
    }

    function logBytes7(bytes7 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
    }

    function logBytes8(bytes8 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
    }

    function logBytes9(bytes9 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
    }

    function logBytes10(bytes10 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
    }

    function logBytes11(bytes11 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
    }

    function logBytes12(bytes12 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
    }

    function logBytes13(bytes13 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
    }

    function logBytes14(bytes14 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
    }

    function logBytes15(bytes15 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
    }

    function logBytes16(bytes16 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
    }

    function logBytes17(bytes17 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
    }

    function logBytes18(bytes18 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
    }

    function logBytes19(bytes19 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
    }

    function logBytes20(bytes20 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
    }

    function logBytes21(bytes21 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
    }

    function logBytes22(bytes22 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
    }

    function logBytes23(bytes23 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
    }

    function logBytes24(bytes24 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
    }

    function logBytes25(bytes25 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
    }

    function logBytes26(bytes26 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
    }

    function logBytes27(bytes27 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
    }

    function logBytes28(bytes28 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
    }

    function logBytes29(bytes29 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
    }

    function logBytes30(bytes30 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
    }

    function logBytes31(bytes31 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
    }

    function logBytes32(bytes32 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
    }

    function log(uint p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
    }

    function log(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function log(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function log(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function log(uint p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
    }

    function log(uint p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
    }

    function log(uint p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
    }

    function log(uint p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
    }

    function log(string memory p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
    }

    function log(string memory p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
    }

    function log(string memory p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
    }

    function log(string memory p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
    }

    function log(bool p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
    }

    function log(bool p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
    }

    function log(bool p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
    }

    function log(bool p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
    }

    function log(address p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
    }

    function log(address p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
    }

    function log(address p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
    }

    function log(address p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
    }

    function log(uint p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
    }

    function log(uint p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
    }

    function log(uint p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
    }

    function log(uint p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
    }

    function log(uint p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
    }

    function log(uint p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
    }

    function log(uint p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
    }

    function log(uint p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
    }

    function log(uint p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
    }

    function log(uint p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
    }

    function log(uint p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
    }

    function log(uint p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
    }

    function log(string memory p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
    }

    function log(string memory p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
    }

    function log(string memory p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
    }

    function log(string memory p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
    }

    function log(bool p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
    }

    function log(bool p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
    }

    function log(bool p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
    }

    function log(bool p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
    }

    function log(bool p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
    }

    function log(bool p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
    }

    function log(bool p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
    }

    function log(bool p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
    }

    function log(bool p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
    }

    function log(bool p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
    }

    function log(bool p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
    }

    function log(bool p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
    }

    function log(address p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
    }

    function log(address p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
    }

    function log(address p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
    }

    function log(address p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
    }

    function log(address p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
    }

    function log(address p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
    }

    function log(address p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
    }

    function log(address p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
    }

    function log(address p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
    }

    function log(address p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
    }

    function log(address p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
    }

    function log(address p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
    }

    function log(address p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
    }

    function log(address p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
    }

    function log(address p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
    }

    function log(address p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
    }

    function log(uint p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/console.sol";

/// @notice utils for array manipulation
/// @author phaze (https://github.com/0xPhaze)
library ArrayUtils {
    /* ------------- utils ------------- */

    function slice(
        uint256[] memory arr,
        uint256 from,
        uint256 to
    ) internal pure returns (uint256[] memory ret) {
        assert(from <= to);
        assert(to <= arr.length);

        uint256 n = to - from;
        ret = new uint256[](n);

        unchecked {
            for (uint256 i = 0; i < n; ++i) ret[i] = arr[from + i];
        }
    }

    function _slice(
        uint256[] memory arr,
        uint256 from,
        uint256 to
    ) internal pure returns (uint256[] memory ret) {
        assert(from <= to);
        assert(to <= arr.length);

        assembly {
            ret := add(arr, mul(0x20, from))
            mstore(ret, sub(to, from))
        }
    }

    function range(uint256 from, uint256 to) internal pure returns (uint256[] memory ret) {
        assert(from <= to);

        unchecked {
            ret = new uint256[](to - from);
            for (uint256 i; i < to - from; ++i) ret[i] = from + i;
        }
    }

    function copy(uint256[] memory arr) internal pure returns (uint256[] memory) {
        return _copy(arr, new uint256[](arr.length));
    }

    function _copy(uint256[] memory from, uint256[] memory to) internal pure returns (uint256[] memory) {
        uint256 n = from.length;

        unchecked {
            for (uint256 i = 0; i < n; ++i) to[i] = from[i];
        }

        return to;
    }

    function shuffle(uint256[] memory arr, uint256 rand) internal pure returns (uint256[] memory ret) {
        return _shuffle(copy(arr), rand);
    }

    function _shuffle(uint256[] memory arr, uint256 rand) internal pure returns (uint256[] memory ret) {
        ret = arr;

        uint256 n = ret.length;
        uint256 r = rand;
        uint256 c;

        unchecked {
            for (uint256 i; i < n; ++i) {
                c = i + (uint256(keccak256(abi.encode(r, i))) % (n - i));
                (ret[i], ret[c]) = (ret[c], ret[i]);
            }
        }
    }

    function shuffledRange(
        uint256 from,
        uint256 to,
        uint256 rand
    ) internal pure returns (uint256[] memory ret) {
        ret = new uint256[](to);

        uint256 r = rand;
        uint256 c;

        unchecked {
            for (uint256 i = 1; i < to; ++i) {
                c = uint256(keccak256(abi.encode(r, i))) % (i + 1);
                (ret[c], ret[i]) = (from + i, ret[c]);
            }
        }
    }

    function randomSubset(
        uint256[] memory arr,
        uint256 n,
        uint256 rand
    ) internal pure returns (uint256[] memory ret) {
        return _randomSubset(copy(arr), n, rand);
    }

    function _randomSubset(
        uint256[] memory arr,
        uint256 n,
        uint256 rand
    ) internal pure returns (uint256[] memory ret) {
        uint256 arrLength = arr.length;
        assert(n <= arrLength);

        ret = arr;

        uint256 r = rand;
        uint256 c;

        unchecked {
            for (uint256 i; i < n; ++i) {
                c = i + (uint256(keccak256(abi.encode(r, i))) % (arrLength - i));
                (ret[i], ret[c]) = (ret[c], ret[i]);
            }
        }
        ret = _slice(ret, 0, n);
    }

    // /// Optimized; reduces randomness to range [0,2^16)
    // function shuffledRangeOpt(
    //     uint256 from,
    //     uint256 to,
    //     uint256 rand
    // ) internal pure returns (uint256[] memory ret) {
    //     ret = new uint256[](to);

    //     uint256 r = rand;
    //     uint256 c;

    //     unchecked {
    //         for (uint256 i = 1; i < to; ++i) {
    //             uint256 slot = (i & 0xf) << 4;
    //             if (slot == 0 && i != 0) r = uint256(keccak256(abi.encode(r, i)));
    //             c = ((r >> slot) & 0xffff) % (i + 1);
    //             (ret[c], ret[i]) = (from + i, ret[c]);
    //         }
    //     }
    // }

    function extend(uint256[] memory arr, uint256 value) internal pure returns (uint256[] memory ret) {
        uint256 n = arr.length;
        ret = _copy(arr, new uint256[](n + 1));
        ret[n] = value;
    }

    function includes(uint256[] memory arr, uint256 num) internal pure returns (bool) {
        for (uint256 i; i < arr.length; ++i) if (arr[i] == num) return true;
        return false;
    }

    /* ------------- address ------------- */

    function includes(address[] memory arr, address address_) internal pure returns (bool) {
        for (uint256 i; i < arr.length; ++i) if (arr[i] == address_) return true;
        return false;
    }

    /* ------------- uint8 ------------- */

    function toMemory32(uint8[1] memory arr) internal pure returns (uint32[] memory out) {
        unchecked {
            out = new uint32[](1);
            for (uint256 i; i < 1; ++i) out[i] = arr[i];
        }
    }

    function toMemory32(uint8[2] memory arr) internal pure returns (uint32[] memory out) {
        unchecked {
            out = new uint32[](2);
            for (uint256 i; i < 2; ++i) out[i] = arr[i];
        }
    }

    function toMemory32(uint8[3] memory arr) internal pure returns (uint32[] memory out) {
        unchecked {
            out = new uint32[](3);
            for (uint256 i; i < 3; ++i) out[i] = arr[i];
        }
    }

    function toMemory32(uint8[4] memory arr) internal pure returns (uint32[] memory out) {
        unchecked {
            out = new uint32[](4);
            for (uint256 i; i < 4; ++i) out[i] = arr[i];
        }
    }

    function toMemory32(uint8[5] memory arr) internal pure returns (uint32[] memory out) {
        unchecked {
            out = new uint32[](5);
            for (uint256 i; i < 5; ++i) out[i] = arr[i];
        }
    }

    function toMemory32(uint8[6] memory arr) internal pure returns (uint32[] memory out) {
        unchecked {
            out = new uint32[](6);
            for (uint256 i; i < 6; ++i) out[i] = arr[i];
        }
    }

    function toMemory32(uint8[7] memory arr) internal pure returns (uint32[] memory out) {
        unchecked {
            out = new uint32[](7);
            for (uint256 i; i < 7; ++i) out[i] = arr[i];
        }
    }

    function toMemory32(uint8[8] memory arr) internal pure returns (uint32[] memory out) {
        unchecked {
            out = new uint32[](8);
            for (uint256 i; i < 8; ++i) out[i] = arr[i];
        }
    }

    function toMemory32(uint8[9] memory arr) internal pure returns (uint32[] memory out) {
        unchecked {
            out = new uint32[](9);
            for (uint256 i; i < 9; ++i) out[i] = arr[i];
        }
    }

    function toMemory32(uint8[10] memory arr) internal pure returns (uint32[] memory out) {
        unchecked {
            out = new uint32[](10);
            for (uint256 i; i < 10; ++i) out[i] = arr[i];
        }
    }

    /* ------------- uint16 ------------- */

    function toMemory32(uint16[1] memory arr) internal pure returns (uint32[] memory out) {
        unchecked {
            out = new uint32[](1);
            for (uint256 i; i < 1; ++i) out[i] = arr[i];
        }
    }

    function toMemory32(uint16[2] memory arr) internal pure returns (uint32[] memory out) {
        unchecked {
            out = new uint32[](2);
            for (uint256 i; i < 2; ++i) out[i] = arr[i];
        }
    }

    function toMemory32(uint16[3] memory arr) internal pure returns (uint32[] memory out) {
        unchecked {
            out = new uint32[](3);
            for (uint256 i; i < 3; ++i) out[i] = arr[i];
        }
    }

    function toMemory32(uint16[4] memory arr) internal pure returns (uint32[] memory out) {
        unchecked {
            out = new uint32[](4);
            for (uint256 i; i < 4; ++i) out[i] = arr[i];
        }
    }

    function toMemory32(uint16[5] memory arr) internal pure returns (uint32[] memory out) {
        unchecked {
            out = new uint32[](5);
            for (uint256 i; i < 5; ++i) out[i] = arr[i];
        }
    }

    function toMemory32(uint16[6] memory arr) internal pure returns (uint32[] memory out) {
        unchecked {
            out = new uint32[](6);
            for (uint256 i; i < 6; ++i) out[i] = arr[i];
        }
    }

    function toMemory32(uint16[7] memory arr) internal pure returns (uint32[] memory out) {
        unchecked {
            out = new uint32[](7);
            for (uint256 i; i < 7; ++i) out[i] = arr[i];
        }
    }

    function toMemory32(uint16[8] memory arr) internal pure returns (uint32[] memory out) {
        unchecked {
            out = new uint32[](8);
            for (uint256 i; i < 8; ++i) out[i] = arr[i];
        }
    }

    function toMemory32(uint16[9] memory arr) internal pure returns (uint32[] memory out) {
        unchecked {
            out = new uint32[](9);
            for (uint256 i; i < 9; ++i) out[i] = arr[i];
        }
    }

    function toMemory32(uint16[10] memory arr) internal pure returns (uint32[] memory out) {
        unchecked {
            out = new uint32[](10);
            for (uint256 i; i < 10; ++i) out[i] = arr[i];
        }
    }

    /* ------------- uint8 ------------- */

    function toMemory(uint8[1] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](1);
            for (uint256 i; i < 1; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint8[2] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](2);
            for (uint256 i; i < 2; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint8[3] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](3);
            for (uint256 i; i < 3; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint8[4] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](4);
            for (uint256 i; i < 4; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint8[5] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](5);
            for (uint256 i; i < 5; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint8[6] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](6);
            for (uint256 i; i < 6; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint8[7] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](7);
            for (uint256 i; i < 7; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint8[8] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](8);
            for (uint256 i; i < 8; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint8[9] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](9);
            for (uint256 i; i < 9; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint8[10] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](10);
            for (uint256 i; i < 10; ++i) out[i] = arr[i];
        }
    }

    /* ------------- uint16 ------------- */

    function toMemory(uint16[1] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](1);
            for (uint256 i; i < 1; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint16[2] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](2);
            for (uint256 i; i < 2; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint16[3] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](3);
            for (uint256 i; i < 3; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint16[4] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](4);
            for (uint256 i; i < 4; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint16[5] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](5);
            for (uint256 i; i < 5; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint16[6] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](6);
            for (uint256 i; i < 6; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint16[7] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](7);
            for (uint256 i; i < 7; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint16[8] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](8);
            for (uint256 i; i < 8; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint16[9] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](9);
            for (uint256 i; i < 9; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint16[10] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](10);
            for (uint256 i; i < 10; ++i) out[i] = arr[i];
        }
    }

    /* ------------- uint256 ------------- */

    function toMemory(uint256[1] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](1);
            for (uint256 i; i < 1; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint256[2] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](2);
            for (uint256 i; i < 2; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint256[3] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](3);
            for (uint256 i; i < 3; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint256[4] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](4);
            for (uint256 i; i < 4; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint256[5] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](5);
            for (uint256 i; i < 5; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint256[6] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](6);
            for (uint256 i; i < 6; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint256[7] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](7);
            for (uint256 i; i < 7; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint256[8] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](8);
            for (uint256 i; i < 8; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint256[9] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](9);
            for (uint256 i; i < 9; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint256[10] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](10);
            for (uint256 i; i < 10; ++i) out[i] = arr[i];
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ---------- Constants

address constant COORDINATOR_RINKEBY = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;
bytes32 constant KEYHASH_RINKEBY = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;

address constant COORDINATOR_MUMBAI = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;
bytes32 constant KEYHASH_MUMBAI = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;

address constant COORDINATOR_POLYGON = 0xAE975071Be8F8eE67addBC1A82488F1C24858067;
bytes32 constant KEYHASH_POLYGON = 0x6e099d640cde6de9d40ac749b4b594126b0169747122711109c9985d47751f93;

address constant COORDINATOR_MAINNET = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
bytes32 constant KEYHASH_MAINNET = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;

// ---------- Interfaces

interface IVRFCoordinatorV2 {
    function requestRandomWords(
        bytes32 keyHash,
        uint64 subId,
        uint16 minimumRequestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords
    ) external returns (uint256 requestId);
}

// ---------- Errors

error CallerNotCoordinator();

// ---------- Contracts

abstract contract VRFConsumerV2 {
    address private immutable coordinator;
    bytes32 private immutable keyHash;
    uint64 private immutable subscriptionId;
    uint16 private immutable requestConfirmations;
    uint32 private immutable callbackGasLimit;

    constructor(
        address coordinator_,
        bytes32 keyHash_,
        uint64 subscriptionId_,
        uint16 requestConfirmations_,
        uint32 callbackGasLimit_
    ) {
        coordinator = coordinator_;
        subscriptionId = subscriptionId_;
        keyHash = keyHash_;
        requestConfirmations = requestConfirmations_;
        callbackGasLimit = callbackGasLimit_;
    }

    function requestRandomWords(uint32 numWords) internal virtual returns (uint256) {
        return
            IVRFCoordinatorV2(coordinator).requestRandomWords(
                keyHash,
                subscriptionId,
                requestConfirmations,
                callbackGasLimit,
                numWords
            );
    }

    function rawFulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) external payable {
        if (msg.sender != coordinator) revert CallerNotCoordinator();

        fulfillRandomWords(requestId, randomWords);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {InitializableUDS} from "./InitializableUDS.sol";

/* ============= Storage ============= */

struct EIP2612DS {
    mapping(address => uint256) nonces;
}

// keccak256("diamond.storage.eip-2612") == 0x849c7f5b4ebbadaf9ded81b9b15e8a309fe7876a607687fda84fe7e7355a02ee;
bytes32 constant DIAMOND_STORAGE_EIP_2612 = 0x849c7f5b4ebbadaf9ded81b9b15e8a309fe7876a607687fda84fe7e7355a02ee;

function ds() pure returns (EIP2612DS storage diamondStorage) {
    assembly {
        diamondStorage.slot := DIAMOND_STORAGE_EIP_2612
    }
}

/* ============= Errors ============= */

error InvalidSigner();
error PermitDeadlineExpired();

/* ============= EIP712PermitUDS ============= */

abstract contract EIP712PermitUDS is InitializableUDS {
    // uint256 internal immutable INITIAL_CHAIN_ID;

    // bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    // function __EIP2612_init() internal initializer {
    //     INITIAL_CHAIN_ID = block.chainid;
    //     INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    // }

    /* ------------- Public ------------- */

    function nonces(address owner) public view returns (uint256) {
        return ds().nonces[owner];
    }

    // FIX check gas usage on these
    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        // return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
        return computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256("ERC721"),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /* ------------- internal ------------- */

    function _usePermit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal virtual returns (bool) {
        if (deadline < block.timestamp) revert PermitDeadlineExpired();

        uint256 nonce = ds().nonces[owner]++;

        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonce,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            if (recoveredAddress == address(0) || recoveredAddress != owner) revert InvalidSigner();
        }

        return true;
    }
}