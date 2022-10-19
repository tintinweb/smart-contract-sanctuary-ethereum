// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { Modifiers } from "../Modifiers.sol";
import { Entity } from "../AppStorage.sol";
import { LibAdmin } from "../libs/LibAdmin.sol";
import { LibConstants } from "../libs/LibConstants.sol";
import { LibHelpers } from "../libs/LibHelpers.sol";
import { LibObject } from "../libs/LibObject.sol";
import { LibACL } from "../libs/LibACL.sol";
import { LibEntity } from "../libs/LibEntity.sol";

/**
 * @title System
 * @notice Use it to perform system level operations
 * @dev Use it to perform system level operations
 */
contract SystemFacet is Modifiers {
    /**
     * @notice Create an entity
     * @dev An entity can be created with a zero max capacity! This is in the event where an entity cannot write any policies.
     * @param _entityId Unique ID for the entity
     * @param _entityAdmin Unique ID of the entity administrator
     * @param _entityData remaining entity metadata
     * @param _dataHash hash of the offchain data
     */
    function createEntity(
        bytes32 _entityId,
        bytes32 _entityAdmin,
        Entity memory _entityData,
        bytes32 _dataHash
    ) external assertSysMgr {
        LibEntity._createEntity(_entityId, _entityAdmin, _entityData, _dataHash);
    }

    /**
     * @notice Convert a string type to a bytes32 type
     * @param _strIn a string
     */
    function stringToBytes32(string memory _strIn) external pure returns (bytes32 result) {
        result = LibHelpers._stringToBytes32(_strIn);
    }

    /**
     * @dev Get whether given id is an object in the system.
     * @param _id object id.
     * @return true if it is an object, false otherwise
     */
    function isObject(bytes32 _id) external view returns (bool) {
        return LibObject._isObject(_id);
    }

    /**
     * @dev Get meta of given object.
     * @param _id object id.
     * @return parent object parent
     * @return dataHash object data hash
     * @return tokenSymbol object token symbol
     */
    function getObjectMeta(bytes32 _id)
        external
        view
        returns (
            bytes32 parent,
            bytes32 dataHash,
            bytes32 tokenSymbol
        )
    {
        return LibObject._getObjectMeta(_id);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

/// @notice modifiers

import { LibMeta } from "../shared/libs/LibMeta.sol";
import { LibAdmin } from "./libs/LibAdmin.sol";
import { LibConstants } from "./libs/LibConstants.sol";
import { LibHelpers } from "./libs/LibHelpers.sol";
import { LibACL } from "./libs/LibACL.sol";

/**
 * @title Modifiers
 * @notice Function modifiers to control access
 * @dev Function modifiers to control access
 */
contract Modifiers {
    modifier assertSysAdmin() {
        require(
            LibACL._isInGroup(LibHelpers._getIdForAddress(LibMeta.msgSender()), LibAdmin._getSystemId(), LibHelpers._stringToBytes32(LibConstants.GROUP_SYSTEM_ADMINS)),
            "not a system admin"
        );
        _;
    }

    modifier assertSysMgr() {
        require(
            LibACL._isInGroup(LibHelpers._getIdForAddress(LibMeta.msgSender()), LibAdmin._getSystemId(), LibHelpers._stringToBytes32(LibConstants.GROUP_SYSTEM_MANAGERS)),
            "not a system manager"
        );
        _;
    }

    modifier assertEntityAdmin(bytes32 _context) {
        require(
            LibACL._isInGroup(LibHelpers._getIdForAddress(LibMeta.msgSender()), _context, LibHelpers._stringToBytes32(LibConstants.GROUP_ENTITY_ADMINS)),
            "not the entity's admin"
        );
        _;
    }

    modifier assertIsInGroup(
        bytes32 _objectId,
        bytes32 _contextId,
        bytes32 _group
    ) {
        require(LibACL._isInGroup(_objectId, _contextId, _group), "not in group");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

/// @notice storage for nayms v3 decentralized insurance platform

import "./interfaces/FreeStructs.sol";

struct AppStorage {
    //// NAYMS ERC20 TOKEN ////
    mapping(address => uint256) nonces; //is this used?
    mapping(address => mapping(address => uint256)) allowance;
    uint256 totalSupply;
    mapping(bytes32 => bool) internalToken;
    mapping(address => uint256) balances;
    //// Object ////
    mapping(bytes32 => bool) existingObjects; // objectId => is an object?
    mapping(bytes32 => bytes32) objectParent; // objectId => parentId
    mapping(bytes32 => bytes32) objectDataHashes;
    mapping(bytes32 => bytes32) objectTokenSymbol;
    mapping(bytes32 => bool) existingEntities; // entityId => is an entity?
    mapping(bytes32 => bool) existingSimplePolicies; // simplePolicyId => is a simple policy?
    //// ENTITY ////
    mapping(bytes32 => Entity) entities; // objectId => Entity struct
    //// SIMPLE POLICY ////
    mapping(bytes32 => SimplePolicy) simplePolicies; // objectId => SimplePolicy struct
    // External Tokens
    // mapping(bytes32 => bool) externalTokens; // bytes32 ID of external token => is external token?
    mapping(address => bool) externalTokenSupported;
    address[] supportedExternalTokens;
    //// TokenizedObject ////
    mapping(bytes32 => mapping(bytes32 => uint256)) tokenBalances; // tokenId => (ownerId => balance)
    mapping(bytes32 => uint256) tokenSupply; // tokenId => Total Token Supply
    //    mapping(address => uint256) permitExternalDepositNonce; // Is this used?
    // limit to three when updating???

    //// Dividends ////
    uint8 maxDividendDenominations;
    mapping(bytes32 => bytes32[]) dividendDenominations; // object => tokenId of the dividend it allows
    mapping(bytes32 => mapping(bytes32 => uint8)) dividendDenominationIndex; // entity ID => (token ID => index of dividend denomination)
    mapping(bytes32 => mapping(uint8 => bytes32)) dividendDenominationAtIndex; // entity ID => (token ID => index of dividend denomination)
    mapping(bytes32 => mapping(bytes32 => uint256)) totalDividends; // token ID => (denomination ID => total dividend)
    mapping(bytes32 => mapping(bytes32 => mapping(bytes32 => uint256))) withdrawnDividendPerOwner; // entity => (tokenId => (owner => total withdrawn dividend)) NOT per share!!! this is TOTAL
    // // Keep track of the different dividends issued on chain
    // mapping(bytes32 => mapping(bytes32 => uint8)) issuedDividendsTokensIndex; // ownerId => dividendTokenId => index
    // mapping(bytes32 => mapping(uint8 => bytes32)) issuedDividendTokens; // ownerId => index => dividendTokenId
    // mapping(bytes32 => uint8) numIssuedDividends; //starts at 1. 0 means no dividends issued
    // //// DIVIDEND PAYOUT LOGIC ////
    // mapping(bytes32 => mapping(bytes32 => uint256)) divPerTokens; // entity ID => token ID => dividend per token ratio
    // mapping(bytes32 => mapping(bytes32 => EntityDividendInfo)) dividendInfos; // entity ID => token ID => dividend info

    // When a dividend is payed, you divide by the total supply and add it to the totalDividendPerToken
    // Dividends are held by the diamond contract LibHelpers._getIdForAddress(address(this))
    // When dividends are paid, they are transfered OUT of the diamond contract.
    //
    //
    // To calculate withdrawableDividiend = ownedTokens * totalDividendPerToken - totalWithdrawnDividendPerOwner
    //
    // When a dividend is collected you set the totalWithdrawnDividendPerOwner to the total amount the owner withdrew
    //
    // When you trasnsfer, you pay out all dividends to previous owner first, then transfer ownership
    // !!!YOU ALSO TRANSFER totalWithdrawnDividendPerOwner for those shares!!!
    // totalWithdrawnDividendPerOwner(for new owner) += numberOfSharesTransfered * totalDividendPerToken
    // totalWithdrawnDividendPerOwner(for previous owner) -= numberOfSharesTransfered * totalDividendPerToken (can be optimized)
    //
    // When minting
    // Add the token balance to the new owner
    // totalWithdrawnDividendPerOwner(for new owner) += numberOfSharesMinted * totalDividendPerToken
    //
    // When doing the division theser will be dust. Leave the dust in the diamond!!!

    //// ACL Configuration////
    mapping(bytes32 => mapping(bytes32 => bool)) groups; //role => (group => isRoleInGroup)
    mapping(bytes32 => bytes32) canAssign; //role => Group that can assign/unassign that role
    string[][] groupsConfig;
    string[][] canAssignConfig;
    //// User Data ////
    mapping(bytes32 => mapping(bytes32 => bytes32)) roles; // userId => (contextId => role)
    //// ACL Non Essential ////
    //these are only for user viewing. They can be removed.

    //// MARKET ////
    uint256 lastOfferId;
    mapping(uint256 => MarketInfo) offers; // offer Id => MarketInfo struct
    mapping(bytes32 => mapping(bytes32 => uint256)) bestOfferId; // sell token => buy token => best offer Id
    mapping(bytes32 => mapping(bytes32 => uint256)) span; // sell token => buy token => span
    ////  STAKING  ////
    mapping(bytes32 => LockedBalance) userLockedBalances; // userID => LockedBalance struct todo NOT YET READY TO BE REMOVED
    mapping(bytes32 => uint256) userLockedEndTime; // userID => locked end time
    mapping(uint256 => StakingCheckpoint) globalStakingCheckpointHistory; // epoch => StakingCheckpoint struct
    mapping(bytes32 => mapping(uint256 => StakingCheckpoint)) userStakingCheckpointHistory; // userID => epoch => StakingCheckpoint
    mapping(bytes32 => uint256) userStakingCheckpointEpoch; // userID => user_epoch
    mapping(uint256 => int128) stakingSlopeChanges; // timestamp => signed slope change
    uint256 stakingEpoch;
    // Keep track of the different tokens owned on chain
    mapping(bytes32 => mapping(bytes32 => uint8)) ownedTokenIndex; // ownerId => tokenId => index
    mapping(bytes32 => mapping(uint8 => bytes32)) ownedTokenAtIndex; // ownerId => index => tokenId
    mapping(bytes32 => uint8) numOwnedTokens; //starts at 1. 0 means no tokens owned
    // issuedDividendsIndex
    // issuedDividendsAtIndex
    // numIssuedDividends

    // mapping(ownerid => tokenid => index =) issuedDividends
    // mapping() numIssuedDividends //starts at 0

    ////
    //// FROM HERE ON, EVERYTHING IS DEPRECATED. MOVE TO USING THE SAME VARIABLE IN THE "Settings" STRUCTURE
    //// Use LibAdminFunctions._getSettings() to get the instance of settings you need
    ////

    // //// FEE BANK ////
    // bytes32 feeBankId;
    // bytes32 naymsLtdId;
    // bytes32 brokerFeeBankId; // the internal address that the fees all brokers have earned get distribuited to
    // bytes32 marketplaceBankId;
    // bytes32 dividendBankId;
    // bytes32 ndfBankId;
    ////  NDF  ////
    uint256 equilibriumLevel;
    uint256 actualDiscount;
    uint256 maxDiscount;
    uint256 actualNaymsAllocation;
    uint256 targetNaymsAllocation;
    address discountToken;
    uint24 poolFee;
    //// SSF ////
    uint256 rewardsCoefficient;
    mapping(bytes32 => uint256) userRewards;
    //// LP ////
    address lpAddress;
    ////  NAYMS  ////
    string wrappedTokenName;
    string wrappedTokenSymbol;
    uint8 wrappedTokenDecimals;
    address naymsToken; // represents the address key for this NAYMS token in AppStorage 1155 system
    bytes32 naymsTokenId; // represents the bytes32 key for this NAYMS token in AppStorage 1155 system
    //Token addresses for quotes and swaps
    address token0;
    address token1;
    //address token2;
    address pool;
    address uniswapFactory;
    /// Trading Commissions (all in basis points) ///
    uint16 tradingCommissionTotalBP; // the total amount that is deducted for trading commissions (BP)
    // The total commission above is further divided as follows:
    uint16 tradingCommissionNaymsLtdBP;
    uint16 tradingCommissionNDFBP;
    uint16 tradingCommissionSTMBP;
    uint16 tradingCommissionMakerBP;
    // Premium Commissions
    uint16 premiumCommissionNaymsLtdBP;
    uint16 premiumCommissionNDFBP;
    uint16 premiumCommissionSTMBP;
    // A policy can pay out additional commissions on premiums to entities having a variety of roles on the policy

    mapping(bytes32 => mapping(bytes32 => uint256)) marketLockedBalances; // to keep track of an owner's tokens that are on sale in the marketplace, ownerId => lockedTokenId => amount
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { AppStorage, LibAppStorage } from "../AppStorage.sol";
import { LibConstants } from "./LibConstants.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibObject } from "./LibObject.sol";

library LibAdmin {
    event BalanceUpdated(uint256 oldBalance, uint256 newBalance);
    event EquilibriumLevelUpdated(uint256 oldLevel, uint256 newLevel);
    event MaxDividendDenominationsUpdated(uint8 oldMax, uint8 newMax);
    event MaxDiscountUpdated(uint256 oldDiscount, uint256 newDiscount);
    event TargetNaymsAllocationUpdated(uint256 oldTarget, uint256 newTarget);
    event DiscountTokenUpdated(address oldToken, address newToken);
    event PoolFeeUpdated(uint256 oldFee, uint256 newFee);
    event CoefficientUpdated(uint256 oldCoefficient, uint256 newCoefficient);
    event RoleGroupUpdated(string role, string group, bool roleInGroup);
    event RoleCanAssignUpdated(string role, string group);
    event SupportedTokenAdded(address tokenAddress);

    function _getSystemId() internal pure returns (bytes32) {
        return LibHelpers._stringToBytes32(LibConstants.SYSTEM_IDENTIFIER);
    }

    function _getEmptyId() internal pure returns (bytes32) {
        return LibHelpers._stringToBytes32(LibConstants.EMPTY_IDENTIFIER);
    }

    function _updateMaxDividendDenominations(uint8 _newMaxDividendDenominations) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(_newMaxDividendDenominations > s.maxDividendDenominations, "_updateMaxDividendDenominations: cannot reduce");
        uint8 old = s.maxDividendDenominations;
        s.maxDividendDenominations = _newMaxDividendDenominations;

        emit MaxDividendDenominationsUpdated(old, _newMaxDividendDenominations);
    }

    function _getMaxDividendDenominations() internal view returns (uint8) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.maxDividendDenominations;
    }

    function _setEquilibriumLevel(uint256 _newLevel) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 oldLevel = s.equilibriumLevel;
        s.equilibriumLevel = _newLevel;

        emit EquilibriumLevelUpdated(oldLevel, _newLevel);
    }

    function _setMaxDiscount(uint256 _newDiscount) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 oldDiscount = s.maxDiscount;
        s.maxDiscount = _newDiscount;

        emit MaxDiscountUpdated(oldDiscount, _newDiscount);
    }

    function _setTargetNaymsAllocation(uint256 _newTarget) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 oldTarget = s.targetNaymsAllocation;
        s.targetNaymsAllocation = _newTarget;

        emit TargetNaymsAllocationUpdated(oldTarget, _newTarget);
    }

    function _setDiscountToken(address _newToken) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        address oldToken = s.discountToken;
        s.discountToken = _newToken;

        emit DiscountTokenUpdated(oldToken, _newToken);
    }

    function _setPoolFee(uint24 _newFee) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 oldFee = s.poolFee;
        s.poolFee = _newFee;

        emit PoolFeeUpdated(oldFee, _newFee);
    }

    function _setCoefficient(uint256 _newCoefficient) internal {
        require(_newCoefficient <= 1000, "Coefficient too high");

        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 oldCoefficient = s.rewardsCoefficient;

        s.rewardsCoefficient = _newCoefficient;

        emit CoefficientUpdated(oldCoefficient, s.rewardsCoefficient);
    }

    function _updateRoleAssigner(string memory _role, string memory _assignerGroup) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.canAssign[LibHelpers._stringToBytes32(_role)] = LibHelpers._stringToBytes32(_assignerGroup);
        emit RoleCanAssignUpdated(_role, _assignerGroup);
    }

    function _updateRoleGroup(
        string memory _role,
        string memory _group,
        bool _roleInGroup
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.groups[LibHelpers._stringToBytes32(_role)][LibHelpers._stringToBytes32(_group)] = _roleInGroup;
        emit RoleGroupUpdated(_role, _group, _roleInGroup);
    }

    function _isSupportedExternalToken(bytes32 _tokenId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.externalTokenSupported[LibHelpers._getAddressFromId(_tokenId)];
    }

    function _addSupportedExternalToken(address _tokenAddress) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bool alreadyAdded;
        s.externalTokenSupported[_tokenAddress] = true;

        // Supported tokens cannot be removed because they may exist in the system!
        for (uint256 i = 0; i < s.supportedExternalTokens.length; i++) {
            if (s.supportedExternalTokens[i] == _tokenAddress) {
                alreadyAdded = true;
                break;
            }
        }
        if (!alreadyAdded) {
            LibObject._createObject(LibHelpers._getIdForAddress(_tokenAddress));
            s.supportedExternalTokens.push(_tokenAddress);

            emit SupportedTokenAdded(_tokenAddress);
        }
    }

    function _getSupportedExternalTokens() internal view returns (address[] memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // Supported tokens cannot be removed because they may exist in the system!
        return s.supportedExternalTokens;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { LibHelpers } from "./LibHelpers.sol";

/**
 * @dev Settings keys.
 */
library LibConstants {
    //Reserved IDs
    string internal constant EMPTY_IDENTIFIER = "";
    string internal constant SYSTEM_IDENTIFIER = "System";
    string internal constant NDF_IDENTIFIER = "NDF";
    string internal constant STM_IDENTIFIER = "Staking Mechanism";
    string internal constant SSF_IDENTIFIER = "SSF";
    string internal constant NAYM_TOKEN_IDENTIFIER = "NAYM"; //This is the ID in the system as well as the token ID
    string internal constant DIVIDEND_BANK_IDENTIFIER = "Dividend Bank"; //This will hold all the dividends
    string internal constant NAYMS_LTD_IDENTIFIER = "Nayms Ltd";

    //Roles
    string internal constant ROLE_SYSTEM_ADMIN = "System Admin";
    string internal constant ROLE_SYSTEM_MANAGER = "System Manager";
    string internal constant ROLE_ENTITY_ADMIN = "Entity Admin";
    string internal constant ROLE_ENTITY_MANAGER = "Entity Manager";
    string internal constant ROLE_BROKER = "Broker";
    string internal constant ROLE_INSURED_PARTY = "Insured";
    string internal constant ROLE_UNDERWRITER = "Underwriter";
    string internal constant ROLE_CAPITAL_PROVIDER = "Capital Provider";
    string internal constant ROLE_CLAIMS_ADMIN = "Claims Admin";
    string internal constant ROLE_TRADER = "Trader";

    //Groups
    string internal constant GROUP_SYSTEM_ADMINS = "System Admins";
    string internal constant GROUP_SYSTEM_MANAGERS = "System Managers";
    string internal constant GROUP_ENTITY_ADMINS = "Entity Admins";
    string internal constant GROUP_ENTITY_MANAGERS = "Entity Managers";
    string internal constant GROUP_APPROVED_USERS = "Approved Users";
    string internal constant GROUP_BROKERS = "Brokers";
    string internal constant GROUP_INSURED_PARTIES = "Insured Parties";
    string internal constant GROUP_UNDERWRITERS = "Underwriters";
    string internal constant GROUP_CAPITAL_PROVIDERS = "Capital Providers";
    string internal constant GROUP_CLAIMS_ADMINS = "Claims Admins";
    string internal constant GROUP_TRADERS = "Traders";

    /*///////////////////////////////////////////////////////////////////////////
                        Market Fee Schedules
    ///////////////////////////////////////////////////////////////////////////*/

    /**
     * @dev Standard fee is charged.
     */
    uint256 internal constant FEE_SCHEDULE_STANDARD = 1;
    /**
     * @dev Platform-initiated trade, e.g. token sale or buyback.
     */
    uint256 internal constant FEE_SCHEDULE_PLATFORM_ACTION = 2;

    /*///////////////////////////////////////////////////////////////////////////
                        MARKET OFFER STATES
    ///////////////////////////////////////////////////////////////////////////*/

    uint256 internal constant OFFER_STATE_ACTIVE = 1;
    uint256 internal constant OFFER_STATE_CANCELLED = 2;
    uint256 internal constant OFFER_STATE_FULFILLED = 3;

    uint256 internal constant DUST = 1;

    /*///////////////////////////////////////////////////////////////////////////
                        SIMPLE POLICY STATES
    ///////////////////////////////////////////////////////////////////////////*/

    uint256 internal constant SIMPLE_POLICY_STATE_CREATED = 0;
    uint256 internal constant SIMPLE_POLICY_STATE_APPROVED = 1;
    uint256 internal constant SIMPLE_POLICY_STATE_ACTIVE = 2;
    uint256 internal constant SIMPLE_POLICY_STATE_MATURED = 3;
    uint256 internal constant SIMPLE_POLICY_STATE_CANCELLED = 4;
    uint256 internal constant STAKING_WEEK = 7 days;
    uint256 internal constant STAKING_MINTIME = 60 days; // 60 days min lock
    uint256 internal constant STAKING_MAXTIME = 4 * 365 days; // 4 years max lock
    uint256 internal constant SCALE = 1e18; //10 ^ 18

    /// _depositFor Types for events
    int128 internal constant STAKING_DEPOSIT_FOR_TYPE = 0;
    int128 internal constant STAKING_CREATE_LOCK_TYPE = 1;
    int128 internal constant STAKING_INCREASE_LOCK_AMOUNT = 2;
    int128 internal constant STAKING_INCREASE_UNLOCK_TIME = 3;

    string internal constant VE_NAYM_NAME = "veNAYM";
    string internal constant VE_NAYM_SYMBOL = "veNAYM";
    uint8 internal constant VE_NAYM_DECIMALS = 18;
    uint8 internal constant INTERNAL_TOKEN_DECIMALS = 18;
    address internal constant DAI_CONSTANT = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

/// @notice Pure functions
library LibHelpers {
    function _getIdForObjectAtIndex(uint256 _index) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_index));
    }

    function _getIdForAddress(address _addr) internal pure returns (bytes32) {
        return bytes32(bytes20(_addr));
    }

    function _getSenderId() internal view returns (bytes32) {
        return _getIdForAddress(msg.sender);
    }

    function _getAddressFromId(bytes32 _id) internal pure returns (address) {
        return address(bytes20(_id));
    }

    // Conversion Utilities

    function _addressToBytes32(address addr) internal pure returns (bytes32 result) {
        return _bytesToBytes32(abi.encode(addr));
    }

    function _stringToBytes32(string memory strIn) internal pure returns (bytes32 result) {
        return _bytesToBytes32(bytes(strIn));
    }

    function _bytes32ToString(bytes32 bytesIn) internal pure returns (string memory) {
        return string(_bytes32ToBytes(bytesIn));
    }

    function _bytesToBytes32(bytes memory source) internal pure returns (bytes32 result) {
        if (source.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(source, 32))
        }
    }

    function _bytes32ToBytes(bytes32 input) internal pure returns (bytes memory) {
        bytes memory b = new bytes(32);
        assembly {
            mstore(add(b, 32), input)
        }
        return b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { AppStorage, LibAppStorage } from "../AppStorage.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibAdmin } from "./LibAdmin.sol";

/// @notice Contains internal methods for core Nayms system functionality
library LibObject {
    function _createObject(
        bytes32 _objectId,
        bytes32 _parentId,
        bytes32 _dataHash
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // check if the id has been used (has a parent account associated with it) and revert if it has
        require(!s.existingObjects[_objectId], "object already exists");

        s.existingObjects[_objectId] = true;
        s.objectParent[_objectId] = _parentId;
        s.objectDataHashes[_objectId] = _dataHash;
    }

    function _createObject(bytes32 _objectId, bytes32 _dataHash) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(!s.existingObjects[_objectId], "object already exists");

        s.existingObjects[_objectId] = true;
        s.objectDataHashes[_objectId] = _dataHash;
    }

    function _createObject(bytes32 _objectId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(!s.existingObjects[_objectId], "object already exists");

        s.existingObjects[_objectId] = true;
    }

    function _setDataHash(bytes32 _objectId, bytes32 _dataHash) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(s.existingObjects[_objectId], "setDataHash: object doesn't exist");
        s.objectDataHashes[_objectId] = _dataHash;
    }

    function _getDataHash(bytes32 _objectId) internal view returns (bytes32 objectDataHash) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.objectDataHashes[_objectId];
    }

    function _getParent(bytes32 _objectId) internal view returns (bytes32) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.objectParent[_objectId];
    }

    function _getParentFromAddress(address addr) internal view returns (bytes32) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        bytes32 objectId = LibHelpers._getIdForAddress(addr);
        return s.objectParent[objectId];
    }

    function _setParent(bytes32 _objectId, bytes32 _parentId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.objectParent[_objectId] = _parentId;
    }

    function _isObjectTokenizable(bytes32 _objectId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return (s.objectTokenSymbol[_objectId] != LibAdmin._getEmptyId());
    }

    function _enableObjectTokenization(bytes32 _objectId, string memory _symbol) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(bytes(_symbol).length < 16, "symbol more than 16 characters");
        require(s.objectTokenSymbol[_objectId] == LibAdmin._getEmptyId(), "object already tokenized");

        s.objectTokenSymbol[_objectId] = LibHelpers._stringToBytes32(_symbol);
    }

    function _isObject(bytes32 _id) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.existingObjects[_id];
    }

    function _getObjectMeta(bytes32 _id)
        internal
        view
        returns (
            bytes32 parent,
            bytes32 dataHash,
            bytes32 tokenSymbol
        )
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        parent = s.objectParent[_id];
        dataHash = s.objectDataHashes[_id];
        tokenSymbol = s.objectTokenSymbol[_id];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { AppStorage, LibAppStorage } from "../AppStorage.sol";
import { Modifiers } from "../Modifiers.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibAdmin } from "./LibAdmin.sol";
import { LibObject } from "./LibObject.sol";

library LibACL {
    /**
     * @dev Emitted when a role gets updated. Empty roleId is assigned upon role removal
     * @param objectId The user or object that was assigned the role.
     * @param contextId The context where the role was assigned to.
     * @param roleId The ID of the role which got unassigned. (empty ID when unassigned)
     * @param functionName The function performing the action
     */
    event RoleUpdate(bytes32 indexed objectId, bytes32 contextId, bytes32 roleId, string functionName);

    function _assignRole(
        bytes32 _objectId,
        bytes32 _contextId,
        bytes32 _roleId
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.roles[_objectId][_contextId] = _roleId;
        emit RoleUpdate(_objectId, _contextId, _roleId, "_assignRole");
    }

    function _unassignRole(bytes32 _objectId, bytes32 _contextId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        emit RoleUpdate(_objectId, _contextId, s.roles[_objectId][_contextId], "_unassignRole");
        delete s.roles[_objectId][_contextId];
    }

    function _isInGroup(
        bytes32 _objectId,
        bytes32 _contextId,
        bytes32 _groupId
    ) internal view returns (bool ret) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // Check for the role in the context
        bytes32 objectRoleInContext = s.roles[_objectId][_contextId];

        if (s.groups[objectRoleInContext][_groupId]) {
            ret = true;
        } else {
            // A role in the context of the system covers all objects
            bytes32 objectRoleInSystem = s.roles[_objectId][LibAdmin._getSystemId()];

            if (s.groups[objectRoleInSystem][_groupId]) {
                ret = true;
            }
        }
    }

    function _isParentInGroup(
        bytes32 _objectId,
        bytes32 _contextId,
        bytes32 _groupId
    ) internal view returns (bool) {
        bytes32 parentId = LibObject._getParent(_objectId);
        return _isInGroup(parentId, _contextId, _groupId);
    }

    /// Can a user (or object) assign a role in a given context
    function _canAssign(
        bytes32 _assignerId,
        bytes32 _objectId,
        bytes32 _contextId,
        bytes32 _roleId
    ) internal view returns (bool) {
        // we might impose additional restrictions on _objectId in the future
        require(_objectId != "", "invalid object ID");
        bool ret = false;
        AppStorage storage s = LibAppStorage.diamondStorage();
        bytes32 assignerGroup = s.canAssign[_roleId];

        // Check for group membership in the given context
        if (_isInGroup(_assignerId, _contextId, assignerGroup)) {
            ret = true;
        } else {
            // A role in the context of the system covers all objects
            if (_isParentInGroup(_assignerId, LibAdmin._getSystemId(), assignerGroup)) {
                ret = true;
            }
        }
        return ret;
    }

    function _getRoleInContext(bytes32 _objectId, bytes32 _contextId) internal view returns (bytes32) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.roles[_objectId][_contextId];
    }

    function _isRoleInGroup(string memory role, string memory group) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.groups[LibHelpers._stringToBytes32(role)][LibHelpers._stringToBytes32(group)];
    }

    function _canGroupAssignRole(string memory role, string memory group) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.canAssign[LibHelpers._stringToBytes32(role)] == LibHelpers._stringToBytes32(group);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { LibAppStorage, AppStorage } from "../AppStorage.sol";
import { Entity, SimplePolicy, Stakeholders } from "../AppStorage.sol";
import { LibConstants } from "./LibConstants.sol";
import { LibAdmin } from "./LibAdmin.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibObject } from "./LibObject.sol";
import { LibACL } from "./LibACL.sol";
import { LibTokenizedVault } from "./LibTokenizedVault.sol";
import { LibMarket } from "./LibMarket.sol";

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library LibEntity {
    using ECDSA for bytes32;
    /**
     * @notice New entity has been created
     * @dev Thrown when entity is created
     * @param entityId Unique ID for the entity
     * @param entityAdmin Unique ID of the entity administrator
     */
    event EntityCreated(bytes32 entityId, bytes32 entityAdmin);
    event EntityUpdated(bytes32 entityId);
    event SimplePolicyCreated(bytes32 indexed id, bytes32 entityId);
    event TokenSaleStarted(bytes32 indexed entityId, uint256 offerId);

    /**
     * @dev If an entity passes their checks to create a policy, ensure that the entity's capacity is appropriately decreased by the amount of capital that will be tied to the new policy being created.
     */
    function _validateSimplePolicyCreation(bytes32 _entityId, SimplePolicy calldata simplePolicy) internal view returns (uint256 updatedUtilizedCapacity) {
        // The policy's limit cannot be 0. If a policy's limit is zero, this essentially means the policy doesn't require any capital, which doesn't make business sense.
        require(simplePolicy.limit > 0, "limit not > 0");

        bool isEntityAdmin = LibACL._isInGroup(LibHelpers._getSenderId(), _entityId, LibHelpers._stringToBytes32(LibConstants.GROUP_ENTITY_ADMINS));
        require(isEntityAdmin, "must be entity admin");

        AppStorage storage s = LibAppStorage.diamondStorage();
        Entity memory entity = s.entities[_entityId];

        // todo: ensure that the capital raised is >= max capacity. Probably want to do this check when the trade is made.

        // note: An entity cannot be created / updated to have a 0 collateral ratio, 0 max capacity, so no need to check this here.
        // require(entity.collateralRatio > 0 && entity.maxCapacity > 0, "currency disabled");

        // Calculate the entity's utilized capacity after it writes this policy.
        updatedUtilizedCapacity = entity.utilizedCapacity + simplePolicy.limit;

        // The entity must have enough capacity available to write this policy.
        // An entity is not able to write an additional policy that will utilize its capacity beyond its assigned max capacity.
        require(entity.maxCapacity >= updatedUtilizedCapacity, "not enough available capacity");

        // Calculate the entity's required capital for its capacity utilization based on its collateral requirements.
        uint256 capitalRequirementForUpdatedUtilizedCapacity = (updatedUtilizedCapacity * entity.collateralRatio) / 1000;

        require(LibAdmin._isSupportedExternalToken(simplePolicy.asset), "external token is not supported");

        // The entity's balance must be >= to the updated capacity requirement
        // todo: business only wants to count the entity's balance that was raised from the participation token sale and not its total balance
        require(LibTokenizedVault._internalBalanceOf(_entityId, simplePolicy.asset) >= capitalRequirementForUpdatedUtilizedCapacity, "not enough capital");

        require(simplePolicy.startDate >= block.timestamp, "start date < block.timestamp");
        require(simplePolicy.maturationDate > simplePolicy.startDate, "start date > maturation date");

        uint256 commissionReceiversArrayLength = simplePolicy.commissionReceivers.length;
        require(commissionReceiversArrayLength > 0, "must have commission receivers");

        uint256 commissionBasisPointsArrayLength = simplePolicy.commissionBasisPoints.length;
        require(commissionBasisPointsArrayLength > 0, "must have commission basis points");
        require(commissionReceiversArrayLength == commissionBasisPointsArrayLength, "commissions lengths !=");

        uint256 totalBP;
        for (uint256 i; i < commissionBasisPointsArrayLength; ++i) {
            totalBP += simplePolicy.commissionBasisPoints[i];
        }
        require(totalBP <= 1000, "bp cannot be > 1000");
    }

    function _createSimplePolicy(
        bytes32 _policyId,
        bytes32 _entityId,
        Stakeholders calldata _stakeholders,
        SimplePolicy calldata _simplePolicy,
        bytes32 _dataHash
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(_stakeholders.entityIds.length == _stakeholders.signatures.length, "incorrect number of signatures");

        // note: An entity's updated utilized capacity <= max capitalization check is done in _validateSimplePolicyCreation().
        // Update state with the entity's updated utilized capacity.
        s.entities[_entityId].utilizedCapacity = _validateSimplePolicyCreation(_entityId, _simplePolicy);

        LibObject._createObject(_policyId, _entityId, _dataHash);
        s.simplePolicies[_policyId] = _simplePolicy;
        s.simplePolicies[_policyId].fundsLocked = true;

        uint256 rolesCount = _stakeholders.roles.length;

        for (uint256 i = 0; i < rolesCount; i++) {
            address signer = ECDSA.recover(ECDSA.toEthSignedMessageHash(_policyId), _stakeholders.signatures[i]);
            bytes32 signerId = LibHelpers._getIdForAddress(signer);

            require(LibACL._isInGroup(signerId, _stakeholders.entityIds[i], LibHelpers._stringToBytes32(LibConstants.GROUP_ENTITY_ADMINS)), "invalid stakeholder");
            LibACL._assignRole(_stakeholders.entityIds[i], _policyId, _stakeholders.roles[i]);
        }

        emit SimplePolicyCreated(_policyId, _entityId);
    }

    function _updateAllowSimplePolicy(bytes32 _entityId, bool _allow) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.entities[_entityId].simplePolicyEnabled = _allow;
    }

    /// @param _amount the amount of entity token that is minted and put on sale
    /// @param _totalPrice the buy amount
    function _startTokenSale(
        bytes32 _entityId,
        uint256 _amount,
        uint256 _totalPrice
    ) internal {
        require(_amount > 0, "mint amount must be > 0");
        require(_totalPrice > 0, "total price must be > 0");

        AppStorage storage s = LibAppStorage.diamondStorage();
        Entity memory entity = s.entities[_entityId];

        LibTokenizedVault._internalMint(_entityId, _entityId, _amount);

        (uint256 offerId, , ) = LibMarket._executeLimitOffer(_entityId, _entityId, _amount, entity.assetId, _totalPrice, LibConstants.FEE_SCHEDULE_STANDARD);

        emit TokenSaleStarted(_entityId, offerId);
    }

    function _createEntity(
        bytes32 _entityId,
        bytes32 _entityAdmin,
        Entity memory _entity,
        bytes32 _dataHash
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        validateEntity(_entity);

        LibObject._createObject(_entityId, _dataHash);
        LibObject._setParent(_entityAdmin, _entityId);
        s.existingEntities[_entityId] = true;

        LibACL._assignRole(_entityAdmin, _entityId, LibHelpers._stringToBytes32(LibConstants.ROLE_ENTITY_ADMIN));

        // An entity starts without any capacity being utilized
        delete _entity.utilizedCapacity;

        s.entities[_entityId] = _entity;

        emit EntityCreated(_entityId, _entityAdmin);
    }

    function _updateEntity(bytes32 _entityId, Entity memory _entity) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        validateEntity(_entity);

        s.entities[_entityId] = _entity;

        emit EntityUpdated(_entityId);
    }

    function validateEntity(Entity memory _entity) internal view {
        if (_entity.assetId != 0) {
            // entity has an underlying asset, which means it's a cell

            // External token must be whitelisted by the platform
            require(LibAdmin._isSupportedExternalToken(_entity.assetId), "external token is not supported");

            // Collateral ratio must be in acceptable range of 1 to 1000 basis points (0.01% to 100% collateralized).
            // Cannot ever be completely uncollateralized (0 basis points), if entity is a cell.
            require(1 <= _entity.collateralRatio && _entity.collateralRatio <= 1000, "collateral ratio should be 1 to 1000");

            // Max capacity is the capital amount that an entity can write across all of their policies.
            // note: We do not directly use the value maxCapacity to determine if the entity can or cannot write a policy.
            //       First, we use the bool simplePolicyEnabled to control and dictate whether an entity can or cannot write a policy.
            //       If an entity has this set to true, then we check if an entity has enough capacity to write the policy.
            require(!_entity.simplePolicyEnabled || (_entity.maxCapacity > 0), "max capacity should be greater than 0 for policy creation");
        } else {
            // non-cell entity
            require(_entity.collateralRatio == 0, "only cell has collateral ratio");
            require(!_entity.simplePolicyEnabled, "only cell can issue policies");
            require(_entity.maxCapacity == 0, "only calls have max capacity");
        }
    }

    function _getEntityInfo(bytes32 _entityId) internal view returns (Entity memory entity) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        entity = s.entities[_entityId];
    }

    function _isEntity(bytes32 _entityId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.existingEntities[_entityId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

library LibMeta {
    function msgSender() internal view returns (address sender_) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender_ := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender_ = msg.sender;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

struct MarketInfo {
    bytes32 creator; // entity ID
    bytes32 sellToken;
    uint256 sellAmount;
    uint256 sellAmountInitial;
    bytes32 buyToken;
    uint256 buyAmount;
    uint256 buyAmountInitial;
    // uint256 averagePrice;
    uint256 feeSchedule;
    uint256 state;
    uint256 rankNext;
    uint256 rankPrev;
}

struct TokenAmount {
    bytes32 token;
    uint256 amount;
}

struct MultiToken {
    string tokenUri;
    // kp NOTE todo: what is this struct for?
    mapping(uint256 => mapping(bytes32 => uint256)) tokenBalances; // token ID to account balance
    mapping(bytes32 => mapping(bytes32 => bool)) tokenOpApprovals; // account to operator approvals
}

/**
 * @param maxCapacity Maxmimum allowable amount of capacity that an entity is given. Denominated by assetId.
 * @param utilizedCapacity The utilized capacity of the entity. Denominated by assetId.
 */
struct Entity {
    bytes32 assetId;
    uint256 collateralRatio;
    uint256 maxCapacity;
    uint256 utilizedCapacity;
    bool simplePolicyEnabled;
}

struct SimplePolicy {
    uint256 startDate;
    uint256 maturationDate;
    bytes32 asset;
    uint256 limit;
    bool fundsLocked;
    uint256 claimsPaid;
    uint256 premiumsPaid;
    bytes32[] commissionReceivers;
    uint256[] commissionBasisPoints;
    uint256 sponsorCommissionBasisPoints; //underwriter is parent
}

struct PolicyCommissionsBasisPoints {
    uint16 premiumCommissionNaymsLtdBP;
    uint16 premiumCommissionNDFBP;
    uint16 premiumCommissionSTMBP;
}

struct Stakeholders {
    bytes32[] roles;
    bytes32[] entityIds;
    bytes[] signatures;
}

// Used in StakingFacet
struct LockedBalance {
    uint256 amount;
    uint256 endTime;
}

struct StakingCheckpoint {
    int128 bias;
    int128 slope; // - dweight / dt
    uint256 ts; // timestamp
    uint256 blk; // block number
}

struct FeeRatio {
    uint256 brokerShareRatio;
    uint256 naymsLtdShareRatio;
    uint256 ndfShareRatio;
}

struct TradingCommissions {
    uint256 roughCommissionPaid;
    uint256 commissionNaymsLtd;
    uint256 commissionNDF;
    uint256 commissionSTM;
    uint256 commissionMaker;
    uint256 totalCommissions;
}

struct TradingCommissionsBasisPoints {
    uint16 tradingCommissionNaymsLtdBP;
    uint16 tradingCommissionNDFBP;
    uint16 tradingCommissionSTMBP;
    uint16 tradingCommissionMakerBP;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { AppStorage, LibAppStorage } from "../AppStorage.sol";
import { LibAdmin } from "./LibAdmin.sol";
import { LibConstants } from "./LibConstants.sol";
import { LibHelpers } from "./LibHelpers.sol";

library LibTokenizedVault {
    /**
     * @notice Entity funds deposit
     * @dev Thrown when entity is funded
     * @param caller address of the funder
     * @param receivingEntityId Unique ID of the entity receiving the funds
     * @param assetId Unique ID of the asset being deposited
     * @param shares Amount deposited
     */
    event EntityDeposit(address indexed caller, bytes32 indexed receivingEntityId, bytes32 assetId, uint256 shares);

    /**
     * @notice Entity funds withdrawn
     * @dev Thrown when entity funds are withdrawn
     * @param caller address of the account initiating the transfer
     * @param receiver address of the account receiving the funds
     * @param assetId Unique ID of the asset being transferred
     * @param shares Withdrawn amount
     */
    event EntityWithdraw(address indexed caller, address indexed receiver, address assetId, uint256 shares);

    /**
     * @dev Emitted when a token balance gets updated.
     * @param ownerId Id of owner
     * @param tokenId ID of token
     * @param newAmountOwned new amount owned
     * @param functionName Function name
     * @param msgSender msg.sende
     */
    event InternalTokenBalanceUpdate(bytes32 indexed ownerId, bytes32 tokenId, uint256 newAmountOwned, string functionName, address msgSender);

    /**
     * @dev Emitted when a token supply gets updated.
     * @param tokenId ID of token
     * @param newTokenSupply New token supply
     * @param functionName Function name
     * @param msgSender msg.sende
     */
    event InternalTokenSupplyUpdate(bytes32 indexed tokenId, uint256 newTokenSupply, string functionName, address msgSender);

    /**
     * @dev Emitted when a dividend gets payed out.
     * @param guid divident distribution ID
     * @param from distribution intiator
     * @param to distribution receiver
     * @param amount distributed amount
     */
    event DividendDistribution(bytes32 indexed guid, bytes32 from, bytes32 to, bytes32 dividendTokenId, uint256 amount);

    function _internalBalanceOf(bytes32 _ownerId, bytes32 _tokenId) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.tokenBalances[_tokenId][_ownerId];
    }

    function _internalTokenSupply(bytes32 _objectId) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.tokenSupply[_objectId];
    }

    function _internalTransfer(
        bytes32 _from,
        bytes32 _to,
        bytes32 _tokenId,
        uint256 _amount
    ) internal returns (bool success) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (s.marketLockedBalances[_from][_tokenId] > 0) {
            require(s.tokenBalances[_tokenId][_from] - s.marketLockedBalances[_from][_tokenId] >= _amount, "_internalTransferFrom: tokens for sale in mkt");
        } else {
            require(s.tokenBalances[_tokenId][_from] >= _amount, "_internalTransferFrom: must own the funds");
        }
        _withdrawAllDividends(_from, _tokenId);
        s.tokenBalances[_tokenId][_from] -= _amount;
        s.tokenBalances[_tokenId][_to] += _amount;

        emit InternalTokenBalanceUpdate(_from, _tokenId, s.tokenBalances[_tokenId][_from], "_internalTransferFrom", msg.sender);
        emit InternalTokenBalanceUpdate(_to, _tokenId, s.tokenBalances[_tokenId][_to], "_internalTransferFrom", msg.sender);

        success = true;
    }

    function _internalMint(
        bytes32 _to,
        bytes32 _tokenId,
        uint256 _amount
    ) internal {
        require(_to != "", "MultiToken: mint to zero address");
        require(_amount > 0, "MultiToken: mint zero tokens");

        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 supply = _internalTokenSupply(_tokenId);

        // This must be done BEFORE the supply increases!!!
        // This will calcualte the hypothetical dividends that would correspond to this number of shares.
        // It must be added to the withdrawn dividend for every denomination for the user who receives the minted tokens
        bytes32[] memory dividendDenominations = s.dividendDenominations[_tokenId];

        for (uint256 i = 0; i < dividendDenominations.length; ++i) {
            bytes32 dividendDenominationId = dividendDenominations[i];
            uint256 totalDividend = s.totalDividends[_tokenId][dividendDenominationId];
            uint256 withdrawnSoFar = s.withdrawnDividendPerOwner[_tokenId][dividendDenominationId][_to];

            (, uint256 dividendDeduction) = _getWithdrawableDividendAndDeductionMath(_amount, supply, totalDividend, withdrawnSoFar);
            s.withdrawnDividendPerOwner[_tokenId][dividendDenominationId][_to] += dividendDeduction;
        }

        // Now you can bump the token supply and the balance for the user
        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        s.tokenSupply[_tokenId] += _amount;
        s.tokenBalances[_tokenId][_to] += _amount;

        emit InternalTokenSupplyUpdate(_tokenId, s.tokenSupply[_tokenId], "_internalMint", msg.sender);
        emit InternalTokenBalanceUpdate(_to, _tokenId, s.tokenBalances[_tokenId][_to], "_internalMint", msg.sender);
    }

    function _internalBurn(
        bytes32 _from,
        bytes32 _tokenId,
        uint256 _amount
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (s.marketLockedBalances[_from][_tokenId] > 0) {
            require(s.tokenBalances[_tokenId][_from] - s.marketLockedBalances[_from][_tokenId] >= _amount, "_internalBurn: tokens for sale in mkt");
        } else {
            require(s.tokenBalances[_tokenId][_from] >= _amount, "_internalBurn: must own the funds");
        }

        _withdrawAllDividends(_from, _tokenId);
        s.tokenSupply[_tokenId] -= _amount;
        s.tokenBalances[_tokenId][_from] -= _amount;

        emit InternalTokenSupplyUpdate(_tokenId, s.tokenSupply[_tokenId], "_internalBurn", msg.sender);
        emit InternalTokenBalanceUpdate(_from, _tokenId, s.tokenBalances[_tokenId][_from], "_internalBurn", msg.sender);
    }

    function _withdrawDividend(
        bytes32 _ownerId,
        bytes32 _tokenId,
        bytes32 _dividendTokenId
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        bytes32 dividendBankId = LibHelpers._stringToBytes32(LibConstants.DIVIDEND_BANK_IDENTIFIER);

        uint256 amountOwned = s.tokenBalances[_tokenId][_ownerId];
        uint256 supply = _internalTokenSupply(_tokenId);
        uint256 totalDividend = s.totalDividends[_tokenId][_dividendTokenId];
        uint256 withdrawnSoFar = s.withdrawnDividendPerOwner[_tokenId][_dividendTokenId][_ownerId];

        (uint256 withdrawableDividend, uint256 dividendDeduction) = _getWithdrawableDividendAndDeductionMath(amountOwned, supply, totalDividend, withdrawnSoFar);
        // require(withdrawableDividend > 0, "_withdrawDividend: no dividend");
        if (withdrawableDividend > 0) {
            // Bump the withdrawn dividends for the owner
            s.withdrawnDividendPerOwner[_tokenId][_dividendTokenId][_ownerId] += dividendDeduction;

            // Move the dividend
            s.tokenBalances[_dividendTokenId][dividendBankId] -= withdrawableDividend;
            s.tokenBalances[_dividendTokenId][_ownerId] += withdrawableDividend;

            emit InternalTokenBalanceUpdate(dividendBankId, _dividendTokenId, s.tokenBalances[_dividendTokenId][dividendBankId], "_withdrawDividend", msg.sender);
            emit InternalTokenBalanceUpdate(_ownerId, _dividendTokenId, s.tokenBalances[_dividendTokenId][_ownerId], "_withdrawDividend", msg.sender);
        }
    }

    function _getWithdrawableDividend(
        bytes32 _ownerId,
        bytes32 _tokenId,
        bytes32 _dividendTokenId
    ) internal view returns (uint256 withdrawableDividend_) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 amount = s.tokenBalances[_tokenId][_ownerId];
        uint256 supply = _internalTokenSupply(_tokenId);
        uint256 totalDividend = s.totalDividends[_tokenId][_dividendTokenId];
        uint256 withdrawnSoFar = s.withdrawnDividendPerOwner[_tokenId][_dividendTokenId][_ownerId];

        (withdrawableDividend_, ) = _getWithdrawableDividendAndDeductionMath(amount, supply, totalDividend, withdrawnSoFar);
    }

    function _withdrawAllDividends(bytes32 _ownerId, bytes32 _tokenId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32[] memory dividendDenominations = s.dividendDenominations[_tokenId];
        bytes32 dividendDenominationId;

        for (uint256 i = 0; i < dividendDenominations.length; ++i) {
            dividendDenominationId = dividendDenominations[i];
            _withdrawDividend(_ownerId, _tokenId, dividendDenominationId);
        }
    }

    function _payDividend(
        bytes32 _guid,
        bytes32 _from,
        bytes32 _to,
        bytes32 _dividendTokenId,
        uint256 _amount
    ) internal {
        require(_amount > 0, "dividend amount must be > 0");
        require(LibAdmin._isSupportedExternalToken(_dividendTokenId), "must be supported dividend token");

        AppStorage storage s = LibAppStorage.diamondStorage();
        bytes32 dividendBankId = LibHelpers._stringToBytes32(LibConstants.DIVIDEND_BANK_IDENTIFIER);

        // If no tokens are issued, then deposit directly.
        if (_internalTokenSupply(_to) == 0) {
            _internalTransfer(_from, _to, _dividendTokenId, _amount);
        }
        // Otherwise pay as dividend
        else {
            // issue dividend. if you are owed dividends on the _dividendTokenId, they will be collected
            // Check for possible infinite loop, but probably not
            _internalTransfer(_from, dividendBankId, _dividendTokenId, _amount);
            s.totalDividends[_to][_dividendTokenId] += _amount;

            // keep track of the dividend denominations
            // if dividend has not yet been issued in this token, add it to the list and update mappings
            if (s.dividendDenominationIndex[_to][_dividendTokenId] == 0) {
                // We must limit the number of different tokens dividends are paid in
                if (s.dividendDenominations[_to].length > LibAdmin._getMaxDividendDenominations()) {
                    revert("exceeds max div denominations");
                }

                s.dividendDenominationIndex[_to][_dividendTokenId] = uint8(s.dividendDenominations[_to].length);
                s.dividendDenominationAtIndex[_to][uint8(s.dividendDenominations[_to].length)] = _dividendTokenId;
                s.dividendDenominations[_to].push(_dividendTokenId);
            }
        }
        // Events are emitted from the _internalTransfer()
        emit DividendDistribution(_guid, _from, _to, _dividendTokenId, _amount);
    }

    function _getWithdrawableDividendAndDeductionMath(
        uint256 _amount,
        uint256 _supply,
        uint256 _totalDividend,
        uint256 _withdrawnSoFar
    ) internal pure returns (uint256 _withdrawableDividend, uint256 _dividendDeduction) {
        // The holder dividend is: holderDividend = (totalDividend/tokenSupply) * _amount. The remainer (dust) is lost.
        // To get a smaller remainder we re-arrange to: holderDividend = (totalDividend * _amount) / _supply
        uint256 totalDividendTimesAmount = _totalDividend * _amount;
        uint256 holderDividend = _supply == 0 ? 0 : (totalDividendTimesAmount / _supply);

        _withdrawableDividend = (_withdrawnSoFar >= holderDividend) ? 0 : holderDividend - _withdrawnSoFar;
        _dividendDeduction = _withdrawableDividend;

        // If there is a remainder, add 1 to the _dividendDeduction
        if (totalDividendTimesAmount > _withdrawableDividend * _supply) {
            _dividendDeduction += 1;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { AppStorage, LibAppStorage } from "../AppStorage.sol";
import { MarketInfo, TokenAmount, TradingCommissions } from "../AppStorage.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibAdmin } from "./LibAdmin.sol";
import { LibTokenizedVault } from "./LibTokenizedVault.sol";
import { LibConstants } from "./LibConstants.sol";
import { LibFeeRouter } from "./LibFeeRouter.sol";

library LibMarket {
    /// @notice order has been added
    event OrderAdded(
        uint256 indexed orderId,
        bytes32 indexed maker,
        bytes32 indexed sellToken,
        uint256 sellAmount,
        uint256 sellAmountInitial,
        bytes32 buyToken,
        uint256 buyAmount,
        uint256 buyAmountInitial,
        uint256 state
    );

    /// @notice order has been executed
    event OrderExecuted(uint256 indexed orderId, bytes32 indexed taker, bytes32 indexed sellToken, uint256 sellAmount, bytes32 buyToken, uint256 buyAmount, uint256 state);

    /// @notice order has been canceled
    event OrderCancelled(uint256 indexed orderId, bytes32 indexed taker, bytes32 sellToken);

    struct MatchingOfferResult {
        uint256 remainingBuyAmount;
        uint256 remainingSellAmount;
        uint256 buyTokenCommissionsPaid;
        uint256 sellTokenCommissionsPaid;
    }

    function _getBestOfferId(bytes32 _sellToken, bytes32 _buyToken) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        return s.bestOfferId[_sellToken][_buyToken];
    }

    function _insertOfferIntoSortedList(uint256 _offerId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // check that offer is NOT in the sorted list
        require(!_isOfferInSortedList(_offerId), "offer already in sorted list");

        bytes32 sellToken = s.offers[_offerId].sellToken;
        bytes32 buyToken = s.offers[_offerId].buyToken;

        uint256 prevId;

        // find position of next highest offer
        uint256 top = s.bestOfferId[sellToken][buyToken];
        uint256 oldTop;

        while (top != 0 && _isOfferPricedLtOrEq(_offerId, top)) {
            oldTop = top;
            top = s.offers[top].rankPrev;
        }

        uint256 pos = oldTop;

        // insert offer at position
        if (pos != 0) {
            prevId = s.offers[pos].rankPrev;
            s.offers[pos].rankPrev = _offerId;
            s.offers[_offerId].rankNext = pos;
        }
        // else this is the new best offer, so insert at top
        else {
            prevId = s.bestOfferId[sellToken][buyToken];
            s.bestOfferId[sellToken][buyToken] = _offerId;
        }

        if (prevId != 0) {
            // requirement below is satisfied by statements above
            // require(!_isOfferPricedLtOrEq(_offerId, prevId));
            s.offers[prevId].rankNext = _offerId;
            s.offers[_offerId].rankPrev = prevId;
        }

        s.span[sellToken][buyToken]++;
    }

    function _removeOfferFromSortedList(uint256 _offerId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // check that offer is in the sorted list
        require(_isOfferInSortedList(_offerId), "offer not in sorted list");

        bytes32 sellToken = s.offers[_offerId].sellToken;
        bytes32 buyToken = s.offers[_offerId].buyToken;

        require(s.span[sellToken][buyToken] > 0, "token pair list does not exist");

        // if offer is not the highest offer
        if (_offerId != s.bestOfferId[sellToken][buyToken]) {
            uint256 nextId = s.offers[_offerId].rankNext;
            require(s.offers[nextId].rankPrev == _offerId, "sort check failed");
            s.offers[nextId].rankPrev = s.offers[_offerId].rankPrev;
        }
        // if offer is the highest offer
        else {
            s.bestOfferId[sellToken][buyToken] = s.offers[_offerId].rankPrev;
        }

        // if offer is not the lowest offer
        if (s.offers[_offerId].rankPrev != 0) {
            uint256 prevId = s.offers[_offerId].rankPrev;
            require(s.offers[prevId].rankNext == _offerId, "sort check failed");
            s.offers[prevId].rankNext = s.offers[_offerId].rankNext;
        }

        // nullify
        delete s.offers[_offerId].rankNext;
        delete s.offers[_offerId].rankPrev;

        s.span[sellToken][buyToken]--;
    }

    function _isOfferPricedLtOrEq(uint256 _lowOfferId, uint256 _highOfferId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 lowSellAmount = s.offers[_lowOfferId].sellAmount;
        uint256 lowBuyAmount = s.offers[_lowOfferId].buyAmount;

        uint256 highSellAmount = s.offers[_highOfferId].sellAmount;
        uint256 highBuyAmount = s.offers[_highOfferId].buyAmount;

        return lowBuyAmount * highSellAmount >= highBuyAmount * lowSellAmount;
    }

    function _isOfferInSortedList(uint256 _offerId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32 sellToken = s.offers[_offerId].sellToken;
        bytes32 buyToken = s.offers[_offerId].buyToken;

        return _offerId != 0 && (s.offers[_offerId].rankNext != 0 || s.offers[_offerId].rankPrev != 0 || s.bestOfferId[sellToken][buyToken] == _offerId);
    }

    function _matchToExistingOffers(
        bytes32 _fromEntityId,
        bytes32 _sellToken,
        uint256 _sellAmount,
        bytes32 _buyToken,
        uint256 _buyAmount
    ) internal returns (MatchingOfferResult memory result) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        result.remainingBuyAmount = _buyAmount;
        result.remainingSellAmount = _sellAmount;

        // _buyAmount == 0  means it's a market offer

        while (result.remainingSellAmount != 0) {
            // there is at least one offer stored for token pair
            uint256 bestOfferId = s.bestOfferId[_buyToken][_sellToken];
            if (bestOfferId == 0) {
                break;
            }

            uint256 bestBuyAmount = s.offers[bestOfferId].buyAmount;
            uint256 bestSellAmount = s.offers[bestOfferId].sellAmount;

            // check if price is better or same as the one taker is willing to pay, within error margin
            // Ugly hack to work around rounding errors. Based on the idea that
            // the furthest the amounts can stray from their "true" values is 1.
            // Ergo the worst case has `sellAmount` and `bestSellAmount` at +1 away from
            // their "correct" values and `bestBuyAmount` and `buyAmount` at -1.
            // Since (c - 1) * (d - 1) > (a + 1) * (b + 1) is equivalent to
            // c * d > a * b + a + b + c + d, we write...
            //
            // (For detailed breakdown see https://hiddentao.com/archives/2019/09/08/maker-otc-on-chain-orderbook-deep-dive)
            //
            if (
                bestBuyAmount * result.remainingBuyAmount >
                result.remainingSellAmount * bestSellAmount + bestBuyAmount + result.remainingBuyAmount + result.remainingSellAmount + bestSellAmount
            ) {
                break;
            }

            // ^ The `rounding` parameter is a compromise borne of a couple days of discussion.

            // avoid stack-too-deep
            {
                // do the buy
                uint256 finalSellAmount = bestBuyAmount < result.remainingSellAmount ? bestBuyAmount : result.remainingSellAmount;
                (uint256 nextBuyTokenCommissionsPaid, uint256 nextSellTokenCommissionsPaid) = _buy(bestOfferId, _fromEntityId, finalSellAmount);

                // Keep track of total commissions
                result.buyTokenCommissionsPaid += nextBuyTokenCommissionsPaid;
                result.sellTokenCommissionsPaid += nextSellTokenCommissionsPaid;

                // calculate how much is left to buy/sell
                uint256 sellAmountOld = result.remainingSellAmount;
                result.remainingSellAmount = result.remainingSellAmount - finalSellAmount;
                result.remainingBuyAmount = (result.remainingSellAmount * result.remainingBuyAmount) / sellAmountOld;
            }
        }
    }

    function _createOffer(
        bytes32 _creator,
        bytes32 _sellToken,
        uint256 _sellAmount,
        uint256 _sellAmountInitial,
        bytes32 _buyToken,
        uint256 _buyAmount,
        uint256 _buyAmountInitial,
        uint256 _feeSchedule
    ) internal returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 lastOfferId = ++s.lastOfferId;

        MarketInfo memory marketInfo = s.offers[lastOfferId];
        marketInfo.creator = _creator;
        marketInfo.sellToken = _sellToken;
        marketInfo.sellAmount = _sellAmount;
        marketInfo.sellAmountInitial = _sellAmountInitial;
        marketInfo.buyToken = _buyToken;
        marketInfo.buyAmount = _buyAmount;
        marketInfo.buyAmountInitial = _buyAmountInitial;
        marketInfo.feeSchedule = _feeSchedule;

        if (_sellAmount <= LibConstants.DUST) {
            marketInfo.state = LibConstants.OFFER_STATE_FULFILLED;
        } else {
            marketInfo.state = LibConstants.OFFER_STATE_ACTIVE;

            // lock tokens!
            s.marketLockedBalances[_creator][_sellToken] += _sellAmount;
        }

        s.offers[lastOfferId] = marketInfo;
        emit OrderAdded(lastOfferId, marketInfo.creator, _sellToken, _sellAmount, _sellAmountInitial, _buyToken, _buyAmount, _buyAmountInitial, marketInfo.state);

        return lastOfferId;
    }

    function _buy(
        uint256 _offerId,
        bytes32 _takerId,
        uint256 _requestedBuyAmount
    ) internal returns (uint256 buyTokenCommissionsPaid_, uint256 sellTokenCommissionsPaid_) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // (a / b) * c = c * a / b  -> multiply first, to avoid underflow
        uint256 actualSellAmount = (_requestedBuyAmount * s.offers[_offerId].sellAmount) / s.offers[_offerId].buyAmount; // nWETH

        // check bounds and update balances
        _checkBoundsAndUpdateBalances(_offerId, actualSellAmount, _requestedBuyAmount);

        // Check before paying commissions
        if (s.offers[_offerId].feeSchedule == LibConstants.FEE_SCHEDULE_STANDARD) {
            // Fees are paid by the taker, maker pays no fees
            // Fees are paid only in external token
            // If the _buyToken is external, commissions are paid from _buyAmount in _buyToken.
            // If the _buyToken is internal and the _sellToken is external, commissions are paid from _sellAmount in _sellToken.
            if (LibAdmin._isSupportedExternalToken(s.offers[_offerId].buyToken)) {
                buyTokenCommissionsPaid_ = LibFeeRouter._payTradingCommissions(s.offers[_offerId].creator, _takerId, s.offers[_offerId].buyToken, _requestedBuyAmount);
            } else {
                sellTokenCommissionsPaid_ = LibFeeRouter._payTradingCommissions(s.offers[_offerId].creator, _takerId, s.offers[_offerId].sellToken, actualSellAmount);
            }
        }

        s.marketLockedBalances[s.offers[_offerId].creator][s.offers[_offerId].sellToken] -= actualSellAmount;

        LibTokenizedVault._internalTransfer(s.offers[_offerId].creator, _takerId, s.offers[_offerId].sellToken, actualSellAmount);
        LibTokenizedVault._internalTransfer(_takerId, s.offers[_offerId].creator, s.offers[_offerId].buyToken, _requestedBuyAmount);

        // cancel offer if it has become dust
        if (s.offers[_offerId].sellAmount < LibConstants.DUST) {
            s.offers[_offerId].state = LibConstants.OFFER_STATE_FULFILLED;
            _cancelOffer(_offerId);
        }

        emit OrderExecuted(
            _offerId,
            _takerId,
            s.offers[_offerId].sellToken,
            s.offers[_offerId].sellAmount,
            s.offers[_offerId].buyToken,
            s.offers[_offerId].buyAmount,
            s.offers[_offerId].state
        );
    }

    function _checkBoundsAndUpdateBalances(
        uint256 _offerId,
        uint256 _sellAmount,
        uint256 _buyAmount
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        (TokenAmount memory offerSell, TokenAmount memory offerBuy) = _getOfferTokenAmounts(_offerId);

        _assertAmounts(_sellAmount, _buyAmount);

        require(_buyAmount <= offerBuy.amount, "requested buy amount too large");
        require(_sellAmount <= offerSell.amount, "calculated sell amount too large");

        // update balances
        s.offers[_offerId].sellAmount = offerSell.amount - _sellAmount;
        s.offers[_offerId].buyAmount = offerBuy.amount - _buyAmount;
    }

    function _cancelOffer(uint256 _offerId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        if (_isOfferInSortedList(_offerId)) {
            _removeOfferFromSortedList(_offerId);
        }

        MarketInfo memory marketInfo = s.offers[_offerId];

        // unlock the remaining sell amount back to creator
        if (marketInfo.sellAmount > 0) {
            // note nothing is transferred since tokens for sale are UN-escrowed. Just unlock!
            s.marketLockedBalances[s.offers[_offerId].creator][s.offers[_offerId].sellToken] -= marketInfo.sellAmount;
        }

        // don't emit event stating market order is canceled if the market order was executed and fulfilled
        if (marketInfo.state != LibConstants.OFFER_STATE_FULFILLED) {
            s.offers[_offerId].state = LibConstants.OFFER_STATE_CANCELLED;
            emit OrderCancelled(_offerId, marketInfo.creator, marketInfo.sellToken);
        }
    }

    function _assertAmounts(uint256 _sellAmount, uint256 _buyAmount) internal pure {
        require(uint128(_sellAmount) == _sellAmount, "sell amount exceeds uint128 limit");
        require(uint128(_buyAmount) == _buyAmount, "buy amount exceeds uint128 limit");
        require(_sellAmount > 0, "sell amount must be >0");
        require(_buyAmount > 0, "buy amount must be >0");
    }

    function _assertValidOffer(
        bytes32 _entityId,
        bytes32 _sellToken,
        uint256 _sellAmount,
        bytes32 _buyToken,
        uint256 _buyAmount,
        uint256 _feeSchedule
    ) internal view {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(_entityId != 0 && s.existingEntities[_entityId], "must belong to entity to make an offer");

        bool sellTokenIsEntity = s.existingEntities[_sellToken];
        bool sellTokenIsSupported = s.externalTokenSupported[LibHelpers._getAddressFromId(_sellToken)];
        bool buyTokenIsEntity = s.existingEntities[_buyToken];
        bool buyTokenIsSupported = s.externalTokenSupported[LibHelpers._getAddressFromId(_buyToken)];

        _assertAmounts(_sellAmount, _buyAmount);

        require(sellTokenIsEntity || sellTokenIsSupported, "sell token must be valid");
        require(buyTokenIsEntity || buyTokenIsSupported, "buy token must be valid");
        require(_sellToken != _buyToken, "cannot sell and buy same token");
        require((sellTokenIsEntity && buyTokenIsSupported) || (sellTokenIsSupported && buyTokenIsEntity), "must be one platform token");

        // note: add restriction to not be able to sell tokens that are already for sale
        // maker must own sell amount and it must not be locked
        require(s.tokenBalances[_sellToken][_entityId] - s.marketLockedBalances[_entityId][_sellToken] >= _sellAmount, "tokens locked in market");

        // must have a valid fee schedule
        require(_feeSchedule == LibConstants.FEE_SCHEDULE_PLATFORM_ACTION || _feeSchedule == LibConstants.FEE_SCHEDULE_STANDARD, "fee schedule invalid");
    }

    function _getOfferTokenAmounts(uint256 _offerId) internal view returns (TokenAmount memory sell_, TokenAmount memory buy_) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        sell_.token = s.offers[_offerId].sellToken;
        sell_.amount = s.offers[_offerId].sellAmount;
        buy_.token = s.offers[_offerId].buyToken;
        buy_.amount = s.offers[_offerId].buyAmount;
    }

    function _executeLimitOffer(
        bytes32 _creator,
        bytes32 _sellToken,
        uint256 _sellAmount,
        bytes32 _buyToken,
        uint256 _buyAmount,
        uint256 _feeSchedule
    )
        internal
        returns (
            uint256 offerId_,
            uint256 buyTokenCommissionsPaid_,
            uint256 sellTokenCommissionsPaid_
        )
    {
        _assertValidOffer(_creator, _sellToken, _sellAmount, _buyToken, _buyAmount, _feeSchedule);

        MatchingOfferResult memory result = _matchToExistingOffers(_creator, _sellToken, _sellAmount, _buyToken, _buyAmount);
        buyTokenCommissionsPaid_ = result.buyTokenCommissionsPaid;
        sellTokenCommissionsPaid_ = result.sellTokenCommissionsPaid;

        offerId_ = _createOffer(_creator, _sellToken, result.remainingSellAmount, _sellAmount, _buyToken, result.remainingBuyAmount, _buyAmount, _feeSchedule);

        // if still some left
        if (result.remainingBuyAmount > 0 && result.remainingSellAmount > 0 && result.remainingSellAmount >= LibConstants.DUST) {
            // ensure it's in the right position in the list
            _insertOfferIntoSortedList(offerId_);
        }
    }

    function _getOffer(uint256 _offerId) internal view returns (MarketInfo memory _offerState) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.offers[_offerId];
    }

    function _getLastOfferId() internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.lastOfferId;
    }

    function _isActiveOffer(uint256 _offerId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.offers[_offerId].state == LibConstants.OFFER_STATE_ACTIVE;
    }

    function _getBalanceOfTokensForSale(bytes32 _entityId, bytes32 _tokenId) internal view returns (uint256 amount) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.marketLockedBalances[_entityId][_tokenId];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { AppStorage, LibAppStorage, SimplePolicy, TokenAmount, PolicyCommissionsBasisPoints, TradingCommissions, TradingCommissionsBasisPoints } from "../AppStorage.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibObject } from "./LibObject.sol";
import { LibConstants } from "./LibConstants.sol";
import { LibTokenizedVault } from "./LibTokenizedVault.sol";

library LibFeeRouter {
    event TradingCommissionsPaid(bytes32 indexed takerId, bytes32 tokenId, uint256 amount);
    event PremiumCommissionsPaid(bytes32 indexed policyId, bytes32 indexed entityId, uint256 amount);

    function _payPremiumCommissions(bytes32 _policyId, uint256 _premiumPaid) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        SimplePolicy memory simplePolicy = s.simplePolicies[_policyId];
        bytes32 policyEntityId = LibObject._getParent(_policyId);

        uint256 commissionsCount = simplePolicy.commissionReceivers.length;
        for (uint256 i = 0; i < commissionsCount; i++) {
            uint256 commission = (_premiumPaid * simplePolicy.commissionBasisPoints[i]) / 1000;
            LibTokenizedVault._internalTransfer(policyEntityId, simplePolicy.commissionReceivers[i], simplePolicy.asset, commission);
        }

        uint256 commissionNaymsLtd = (_premiumPaid * s.premiumCommissionNaymsLtdBP) / 1000;
        uint256 commissionNDF = (_premiumPaid * s.premiumCommissionNDFBP) / 1000;
        uint256 commissionSTM = (_premiumPaid * s.premiumCommissionSTMBP) / 1000;

        LibTokenizedVault._internalTransfer(policyEntityId, LibHelpers._stringToBytes32(LibConstants.NAYMS_LTD_IDENTIFIER), simplePolicy.asset, commissionNaymsLtd);
        LibTokenizedVault._internalTransfer(policyEntityId, LibHelpers._stringToBytes32(LibConstants.NDF_IDENTIFIER), simplePolicy.asset, commissionNDF);
        LibTokenizedVault._internalTransfer(policyEntityId, LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER), simplePolicy.asset, commissionSTM);

        emit PremiumCommissionsPaid(_policyId, policyEntityId, _premiumPaid);
    }

    function _getPremiumCommissionBasisPoints() internal view returns (PolicyCommissionsBasisPoints memory bp) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        bp.premiumCommissionNaymsLtdBP = s.premiumCommissionNaymsLtdBP;
        bp.premiumCommissionNDFBP = s.premiumCommissionNDFBP;
        bp.premiumCommissionSTMBP = s.premiumCommissionSTMBP;
    }

    function _payTradingCommissions(
        bytes32 _makerId,
        bytes32 _takerId,
        bytes32 _tokenId,
        uint256 _requestedBuyAmount
    ) internal returns (uint256 commissionPaid_) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(s.tradingCommissionNaymsLtdBP + s.tradingCommissionNDFBP + s.tradingCommissionSTMBP + s.tradingCommissionMakerBP <= 1000, "commissions sum over 1000 bp");
        require(s.tradingCommissionTotalBP <= 1000, "commission total must be<1000bp");

        TradingCommissions memory tc = _calculateTradingCommissions(_requestedBuyAmount);
        // The rough commission deducted. The actual total might be different due to integer division

        // Pay Nayms, LTD commission
        LibTokenizedVault._internalTransfer(_takerId, LibHelpers._stringToBytes32(LibConstants.NAYMS_LTD_IDENTIFIER), _tokenId, tc.commissionNaymsLtd);

        // Pay Nayms Discretionsry Fund commission
        LibTokenizedVault._internalTransfer(_takerId, LibHelpers._stringToBytes32(LibConstants.NDF_IDENTIFIER), _tokenId, tc.commissionNDF);

        // Pay Staking Mechanism commission
        LibTokenizedVault._internalTransfer(_takerId, LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER), _tokenId, tc.commissionSTM);

        // Pay market maker commission
        LibTokenizedVault._internalTransfer(_takerId, _makerId, _tokenId, tc.commissionMaker);

        // Work it out again so the math is precise, ignoring remainers
        commissionPaid_ = tc.totalCommissions;

        emit TradingCommissionsPaid(_takerId, _tokenId, commissionPaid_);
    }

    function _calculateTradingCommissions(uint256 buyAmount) internal view returns (TradingCommissions memory tc) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // The rough commission deducted. The actual total might be different due to integer division
        tc.roughCommissionPaid = (s.tradingCommissionTotalBP * buyAmount) / 1000;

        // Pay Nayms, LTD commission
        tc.commissionNaymsLtd = (s.tradingCommissionNaymsLtdBP * tc.roughCommissionPaid) / 1000;

        // Pay Nayms Discretionsry Fund commission
        tc.commissionNDF = (s.tradingCommissionNDFBP * tc.roughCommissionPaid) / 1000;

        // Pay Staking Mechanism commission
        tc.commissionSTM = (s.tradingCommissionSTMBP * tc.roughCommissionPaid) / 1000;

        // Pay market maker commission
        tc.commissionMaker = (s.tradingCommissionMakerBP * tc.roughCommissionPaid) / 1000;

        // Work it out again so the math is precise, ignoring remainers
        tc.totalCommissions = tc.commissionNaymsLtd + tc.commissionNDF + tc.commissionSTM + tc.commissionMaker;
    }

    function _getTradingCommissionsBasisPoints() internal view returns (TradingCommissionsBasisPoints memory bp) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        bp.tradingCommissionNaymsLtdBP = s.tradingCommissionNaymsLtdBP;
        bp.tradingCommissionNDFBP = s.tradingCommissionNDFBP;
        bp.tradingCommissionSTMBP = s.tradingCommissionSTMBP;
        bp.tradingCommissionMakerBP = s.tradingCommissionMakerBP;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}