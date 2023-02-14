// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @notice storage for nayms v3 decentralized insurance platform

import "./interfaces/FreeStructs.sol";

struct AppStorage {
    // Has this diamond been initialized?
    bool diamondInitialized;
    //// EIP712 domain separator ////
    uint256 initialChainId;
    bytes32 initialDomainSeparator;
    //// Reentrancy guard ////
    uint256 reentrancyStatus;
    //// NAYMS ERC20 TOKEN ////
    string name;
    mapping(address => mapping(address => uint256)) allowance;
    uint256 totalSupply;
    mapping(bytes32 => bool) internalToken;
    mapping(address => uint256) balances;
    //// Object ////
    mapping(bytes32 => bool) existingObjects; // objectId => is an object?
    mapping(bytes32 => bytes32) objectParent; // objectId => parentId
    mapping(bytes32 => bytes32) objectDataHashes;
    mapping(bytes32 => string) objectTokenSymbol;
    mapping(bytes32 => string) objectTokenName;
    mapping(bytes32 => address) objectTokenWrapper;
    mapping(bytes32 => bool) existingEntities; // entityId => is an entity?
    mapping(bytes32 => bool) existingSimplePolicies; // simplePolicyId => is a simple policy?
    //// ENTITY ////
    mapping(bytes32 => Entity) entities; // objectId => Entity struct
    //// SIMPLE POLICY ////
    mapping(bytes32 => SimplePolicy) simplePolicies; // objectId => SimplePolicy struct
    //// External Tokens ////
    mapping(address => bool) externalTokenSupported;
    address[] supportedExternalTokens;
    //// TokenizedObject ////
    mapping(bytes32 => mapping(bytes32 => uint256)) tokenBalances; // tokenId => (ownerId => balance)
    mapping(bytes32 => uint256) tokenSupply; // tokenId => Total Token Supply
    //// Dividends ////
    uint8 maxDividendDenominations;
    mapping(bytes32 => bytes32[]) dividendDenominations; // object => tokenId of the dividend it allows
    mapping(bytes32 => mapping(bytes32 => uint8)) dividendDenominationIndex; // entity ID => (token ID => index of dividend denomination)
    mapping(bytes32 => mapping(uint8 => bytes32)) dividendDenominationAtIndex; // entity ID => (index of dividend denomination => token id)
    mapping(bytes32 => mapping(bytes32 => uint256)) totalDividends; // token ID => (denomination ID => total dividend)
    mapping(bytes32 => mapping(bytes32 => mapping(bytes32 => uint256))) withdrawnDividendPerOwner; // entity => (tokenId => (owner => total withdrawn dividend)) NOT per share!!! this is TOTAL
    //// ACL Configuration////
    mapping(bytes32 => mapping(bytes32 => bool)) groups; //role => (group => isRoleInGroup)
    mapping(bytes32 => bytes32) canAssign; //role => Group that can assign/unassign that role
    //// User Data ////
    mapping(bytes32 => mapping(bytes32 => bytes32)) roles; // userId => (contextId => role)
    //// MARKET ////
    uint256 lastOfferId;
    mapping(uint256 => MarketInfo) offers; // offer Id => MarketInfo struct
    mapping(bytes32 => mapping(bytes32 => uint256)) bestOfferId; // sell token => buy token => best offer Id
    mapping(bytes32 => mapping(bytes32 => uint256)) span; // sell token => buy token => span
    address naymsToken; // represents the address key for this NAYMS token in AppStorage
    bytes32 naymsTokenId; // represents the bytes32 key for this NAYMS token in AppStorage
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
    mapping(bytes32 => mapping(bytes32 => uint256)) lockedBalances; // keep track of token balance that is locked, ownerId => tokenId => lockedAmount
    /// Simple two phase upgrade scheme
    mapping(bytes32 => uint256) upgradeScheduled; // id of the upgrade => the time that the upgrade is valid until.
    uint256 upgradeExpiration; // the period of time that an upgrade is valid until.
    uint256 sysAdmins; // counter for the number of sys admin accounts currently assigned
}

library LibAppStorage {
    bytes32 internal constant NAYMS_DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.nayms.storage");

    function diamondStorage() internal pure returns (AppStorage storage ds) {
        bytes32 position = NAYMS_DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// solhint-disable no-empty-blocks

import { IDiamondCut } from "../shared/interfaces/IDiamondCut.sol";
import { IDiamondLoupe } from "../shared/interfaces/IDiamondLoupe.sol";
import { IERC165 } from "../shared/interfaces/IERC165.sol";
import { IERC173 } from "../shared/interfaces/IERC173.sol";

import { IACLFacet } from "./interfaces/IACLFacet.sol";
import { IUserFacet } from "./interfaces/IUserFacet.sol";
import { IAdminFacet } from "./interfaces/IAdminFacet.sol";
import { ISystemFacet } from "./interfaces/ISystemFacet.sol";
import { INaymsTokenFacet } from "./interfaces/INaymsTokenFacet.sol";
import { ITokenizedVaultFacet } from "./interfaces/ITokenizedVaultFacet.sol";
import { ITokenizedVaultIOFacet } from "./interfaces/ITokenizedVaultIOFacet.sol";
import { IMarketFacet } from "./interfaces/IMarketFacet.sol";
import { IEntityFacet } from "./interfaces/IEntityFacet.sol";
import { ISimplePolicyFacet } from "./interfaces/ISimplePolicyFacet.sol";
import { IGovernanceFacet } from "./interfaces/IGovernanceFacet.sol";

/**
 * @title Nayms Diamond
 * @notice Everything is a part of one big diamond.
 * @dev Every facet should be cut into this diamond.
 */
interface INayms is
    IDiamondCut,
    IDiamondLoupe,
    IERC165,
    IERC173,
    IACLFacet,
    IAdminFacet,
    IUserFacet,
    ISystemFacet,
    INaymsTokenFacet,
    ITokenizedVaultFacet,
    ITokenizedVaultIOFacet,
    IMarketFacet,
    IEntityFacet,
    ISimplePolicyFacet,
    IGovernanceFacet
{

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @notice modifiers

import { LibMeta } from "../shared/libs/LibMeta.sol";
import { LibAdmin } from "./libs/LibAdmin.sol";
import { LibConstants } from "./libs/LibConstants.sol";
import { LibHelpers } from "./libs/LibHelpers.sol";
import { LibObject } from "./libs/LibObject.sol";
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

    modifier assertPolicyHandler(bytes32 _context) {
        require(
            LibACL._isInGroup(LibObject._getParentFromAddress(LibMeta.msgSender()), _context, LibHelpers._stringToBytes32(LibConstants.GROUP_POLICY_HANDLERS)),
            "not a policy handler"
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

    modifier assertERC20Wrapper(bytes32 _tokenId) {
        (, , , , address erc20Wrapper) = LibObject._getObjectMeta(_tokenId);
        require(msg.sender == erc20Wrapper, "only wrapper calls allowed");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/
import { LibDiamond } from "../shared/libs/LibDiamond.sol";
import { DiamondCutFacet } from "../shared/facets/DiamondCutFacet.sol";
import { DiamondLoupeFacet } from "../shared/facets/DiamondLoupeFacet.sol";
import { NaymsOwnershipFacet } from "src/diamonds/shared/facets/NaymsOwnershipFacet.sol";

contract Nayms {
    constructor(address _contractOwner) payable {
        LibDiamond.setContractOwner(_contractOwner);
        LibDiamond.addDiamondFunctions(address(new DiamondCutFacet()), address(new DiamondLoupeFacet()), address(new NaymsOwnershipFacet()));
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    // solhint-disable no-complex-fallback
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        // get facet from function selector
        address facet = address(bytes20(ds.facets[msg.sig]));
        // require(facet != address(0), "Diamond: Function does not exist"); - don't need to do this since we check for code below
        LibDiamond.enforceHasContractCode(facet, "Diamond: Facet has no code");
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    // solhint-disable no-empty-blocks
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @dev Passing in a missing role when trying to assign a role.
error RoleIsMissing();

/// @dev Passing in a missing group when trying to assign a role to a group.
error AssignerGroupIsMissing();

/// @dev Passing in a missing address when trying to add a token address to the supported external token list.
error CannotAddNullSupportedExternalToken();

/// @dev Cannot add a ERC20 token to the supported external token list that has more than 18 decimal places.
error CannotSupportExternalTokenWithMoreThan18Decimals();

/// @dev Passing in a missing address when trying to assign a new token address as the new discount token.
error CannotAddNullDiscountToken();

/// @dev The entity does not exist when it should.
error EntityDoesNotExist(bytes32 objectId);
/// @dev Cannot create an entity that already exists.
error CreatingEntityThatAlreadyExists(bytes32 entityId);

/// @dev (non specific) the object is not enabled to be tokenized.
error ObjectCannotBeTokenized(bytes32 objectId);

/// @dev Passing in a missing symbol when trying to enable an object to be tokenized.
error MissingSymbolWhenEnablingTokenization(bytes32 objectId);

/// @dev Passing in 0 amount for deposits is not allowed.
error ExternalDepositAmountCannotBeZero();

/// @dev Passing in 0 amount for withdraws is not allowed.
error ExternalWithdrawAmountCannotBeZero();

/// @dev Cannot create a simple policy with policyId of 0
error PolicyIdCannotBeZero();

/// @dev Policy commissions among commission receivers cannot sum to be greater than 10_000 basis points.
error PolicyCommissionsBasisPointsCannotBeGreaterThan10000(uint256 calculatedTotalBp);

/// @dev When validating an entity, the utilized capacity cannot be greater than the max capacity.
error UtilizedCapacityGreaterThanMaxCapacity(uint256 utilizedCapacity, uint256 maxCapacity);

/// @dev Policy stakeholder signature validation failed
error SimplePolicyStakeholderSignatureInvalid(bytes32 signingHash, bytes signature, bytes32 signerId, bytes32 signersParent, bytes32 entityId);

/// @dev When creating a simple policy, the total claims paid should start at 0.
error SimplePolicyClaimsPaidShouldStartAtZero();

/// @dev When creating a simple policy, the total premiums paid should start at 0.
error SimplePolicyPremiumsPaidShouldStartAtZero();

/// @dev The cancel bool should not be set to true when creating a new simple policy.
error CancelCannotBeTrueWhenCreatingSimplePolicy();

/// @dev (non specific) The policyId must exist.
error PolicyDoesNotExist(bytes32 policyId);

/// @dev There is a duplicate address in the list of signers (the previous signer in the list is not < the next signer in the list).
error DuplicateSignerCreatingSimplePolicy(address previousSigner, address nextSigner);

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

struct MarketInfo {
    bytes32 creator; // entity ID
    bytes32 sellToken;
    uint256 sellAmount;
    uint256 sellAmountInitial;
    bytes32 buyToken;
    uint256 buyAmount;
    uint256 buyAmountInitial;
    uint256 feeSchedule;
    uint256 state;
    uint256 rankNext;
    uint256 rankPrev;
}

struct TokenAmount {
    bytes32 token;
    uint256 amount;
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
    bool cancelled;
    uint256 claimsPaid;
    uint256 premiumsPaid;
    bytes32[] commissionReceivers;
    uint256[] commissionBasisPoints;
}

struct SimplePolicyInfo {
    uint256 startDate;
    uint256 maturationDate;
    bytes32 asset;
    uint256 limit;
    bool fundsLocked;
    bool cancelled;
    uint256 claimsPaid;
    uint256 premiumsPaid;
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
    uint16 tradingCommissionTotalBP;
    uint16 tradingCommissionNaymsLtdBP;
    uint16 tradingCommissionNDFBP;
    uint16 tradingCommissionSTMBP;
    uint16 tradingCommissionMakerBP;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Access Control List
 * @notice Use it to authorize various actions on the contracts
 * @dev Use it to (un)assign or check role membership
 */
interface IACLFacet {
    /**
     * @notice Assign a `_roleId` to the object in given context
     * @dev Any object ID can be a context, system is a special context with highest priority
     * @param _objectId ID of an object that is being assigned a role
     * @param _contextId ID of the context in which a role is being assigned
     * @param _role Name of the role being assigned
     */
    function assignRole(
        bytes32 _objectId,
        bytes32 _contextId,
        string memory _role
    ) external;

    /**
     * @notice Unassign object from a role in given context
     * @dev Any object ID can be a context, system is a special context with highest priority
     * @param _objectId ID of an object that is being unassigned from a role
     * @param _contextId ID of the context in which a role membership is being revoked
     */
    function unassignRole(bytes32 _objectId, bytes32 _contextId) external;

    /**
     * @notice Checks if an object belongs to `_group` group in given context
     * @dev Assigning a role to the object makes it a member of a corresponding role group
     * @param _objectId ID of an object that is being checked for role group membership
     * @param _contextId Context in which membership should be checked
     * @param _group name of the role group
     * @return true if object with given ID is a member, false otherwise
     */
    function isInGroup(
        bytes32 _objectId,
        bytes32 _contextId,
        string memory _group
    ) external view returns (bool);

    /**
     * @notice Check whether a parent object belongs to the `_group` group in given context
     * @dev Objects can have a parent object, i.e. entity is a parent of a user
     * @param _objectId ID of an object whose parent is being checked for role group membership
     * @param _contextId Context in which the role group membership is being checked
     * @param _group name of the role group
     * @return true if object's parent is a member of this role group, false otherwise
     */
    function isParentInGroup(
        bytes32 _objectId,
        bytes32 _contextId,
        string memory _group
    ) external view returns (bool);

    /**
     * @notice Check whether a user can assign specific object to the `_role` role in given context
     * @dev Check permission to assign to a role
     * @param _assignerId The object ID of the user who is assigning a role to  another object.
     * @param _objectId ID of an object that is being checked for assigning rights
     * @param _contextId ID of the context in which permission is checked
     * @param _role name of the role to check
     * @return true if user the right to assign, false otherwise
     */
    function canAssign(
        bytes32 _assignerId,
        bytes32 _objectId,
        bytes32 _contextId,
        string memory _role
    ) external view returns (bool);

    /**
     * @notice Get a user's (an objectId's) assigned role in a specific context
     * @param objectId ID of an object that is being checked for its assigned role in a specific context
     * @param contextId ID of the context in which the objectId's role is being checked
     * @return roleId objectId's role in the contextId
     */
    function getRoleInContext(bytes32 objectId, bytes32 contextId) external view returns (bytes32);

    /**
     * @notice Get whether role is in group.
     * @dev Get whether role is in group.
     * @param role the role.
     * @param group the group.
     * @return true if role is in group, false otherwise.
     */
    function isRoleInGroup(string memory role, string memory group) external view returns (bool);

    /**
     * @notice Get whether given group can assign given role.
     * @dev Get whether given group can assign given role.
     * @param role the role.
     * @param group the group.
     * @return true if role can be assigned by group, false otherwise.
     */
    function canGroupAssignRole(string memory role, string memory group) external view returns (bool);

    /**
     * @notice Update who can assign `_role` role
     * @dev Update who has permission to assign this role
     * @param _role name of the role
     * @param _assignerGroup Group who can assign members to this role
     */
    function updateRoleAssigner(string memory _role, string memory _assignerGroup) external;

    /**
     * @notice Update role group memebership for `_role` role and `_group` group
     * @dev Update role group memebership
     * @param _role name of the role
     * @param _group name of the group
     * @param _roleInGroup is member of
     */
    function updateRoleGroup(
        string memory _role,
        string memory _group,
        bool _roleInGroup
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { PolicyCommissionsBasisPoints, TradingCommissionsBasisPoints } from "./FreeStructs.sol";

/**
 * @title Administration
 * @notice Exposes methods that require administrative priviledges
 * @dev Use it to configure various core parameters
 */
interface IAdminFacet {
    /**
     * @notice Set `_newMax` as the max dividend denominations value.
     * @param _newMax new value to be used.
     */
    function setMaxDividendDenominations(uint8 _newMax) external;

    /**
     * @notice Update policy commission basis points configuration.
     * @param _policyCommissions policy commissions configuration to set
     */
    function setPolicyCommissionsBasisPoints(PolicyCommissionsBasisPoints calldata _policyCommissions) external;

    /**
     * @notice Update trading commission basis points configuration.
     * @param _tradingCommissions trading commissions configuration to set
     */
    function setTradingCommissionsBasisPoints(TradingCommissionsBasisPoints calldata _tradingCommissions) external;

    /**
     * @notice Get the max dividend denominations value
     * @return max dividend denominations
     */
    function getMaxDividendDenominations() external view returns (uint8);

    /**
     * @notice Is the specified tokenId an external ERC20 that is supported by the Nayms platform?
     * @param _tokenId token address converted to bytes32
     * @return whether token issupported or not
     */
    function isSupportedExternalToken(bytes32 _tokenId) external view returns (bool);

    /**
     * @notice Add another token to the supported tokens list
     * @param _tokenAddress address of the token to support
     */
    function addSupportedExternalToken(address _tokenAddress) external;

    /**
     * @notice Get the supported tokens list as an array
     * @return array containing address of all supported tokens
     */
    function getSupportedExternalTokens() external view returns (address[] memory);

    /**
     * @notice Gets the System context ID.
     * @return System Identifier
     */
    function getSystemId() external pure returns (bytes32);

    /**
     * @notice Check if object can be tokenized
     * @param _objectId ID of the object
     */
    function isObjectTokenizable(bytes32 _objectId) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { SimplePolicy, Entity, Stakeholders } from "./FreeStructs.sol";

/**
 * @title Entities
 * @notice Used to handle policies and token sales
 * @dev Mainly used for token sale and policies
 */
interface IEntityFacet {
    /**
     * @dev Returns the domain separator for the current chain.
     */
    function domainSeparatorV4() external view returns (bytes32);

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function hashTypedDataV4(bytes32 structHash) external view returns (bytes32);

    /**
     * @notice Create a Simple Policy
     * @param _policyId id of the policy
     * @param _entityId id of the entity
     * @param _stakeholders Struct of roles, entity IDs and signatures for the policy
     * @param _simplePolicy policy to create
     * @param _dataHash hash of the offchain data
     */
    function createSimplePolicy(
        bytes32 _policyId,
        bytes32 _entityId,
        Stakeholders calldata _stakeholders,
        SimplePolicy calldata _simplePolicy,
        bytes32 _dataHash
    ) external;

    /**
     * @notice Enable an entity to be tokenized
     * @param _entityId ID of the entity
     * @param _symbol The symbol assigned to the entity token
     * @param _name The name assigned to the entity token
     */
    function enableEntityTokenization(
        bytes32 _entityId,
        string memory _symbol,
        string memory _name
    ) external;

    /**
     * @notice Start token sale of `_amount` tokens for total price of `_totalPrice`
     * @dev Entity tokens are minted when the sale is started
     * @param _entityId ID of the entity
     * @param _amount amount of entity tokens to put on sale
     * @param _totalPrice total price of the tokens
     */
    function startTokenSale(
        bytes32 _entityId,
        uint256 _amount,
        uint256 _totalPrice
    ) external;

    /**
     * @notice Check if an entity token is wrapped as ERC20
     * @param _entityId ID of the entity
     */
    function isTokenWrapped(bytes32 _entityId) external view returns (bool);

    /**
     * @notice Update entity metadata
     * @param _entityId ID of the entity
     * @param _entity metadata of the entity
     */
    function updateEntity(bytes32 _entityId, Entity calldata _entity) external;

    /**
     * @notice Get the the data for entity with ID: `_entityId`
     * @dev Get the Entity data for a given entityId
     * @param _entityId ID of the entity
     * @return Entity struct with metadata of the entity
     */
    function getEntityInfo(bytes32 _entityId) external view returns (Entity memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IGovernanceFacet {
    /**
     * @notice Approve the following upgrade hash: `id`
     * @dev The diamondCut() has been modified to check if the upgrade has been scheduled. This method needs to be called in order
     *      for an upgrade to be executed.
     * @param id This is the keccak256(abi.encode(cut)), where cut is the array of FacetCut struct, IDiamondCut.FacetCut[].
     */
    function createUpgrade(bytes32 id) external;

    /**
     * @notice Update the diamond cut upgrade expiration period.
     * @dev When createUpgrade() is called, it allows a diamondCut() upgrade to be executed. This upgrade must be executed before the
     *      upgrade expires. The upgrade expires based on when the upgrade was scheduled (when createUpgrade() was called) + AppStorage.upgradeExpiration.
     * @param duration The duration until the upgrade expires.
     */
    function updateUpgradeExpiration(uint256 duration) external;

    /**
     * @notice Cancel the following upgrade hash: `id`
     * @dev This will set the mapping AppStorage.upgradeScheduled back to 0.
     * @param id This is the keccak256(abi.encode(cut)), where cut is the array of FacetCut struct, IDiamondCut.FacetCut[].
     */
    function cancelUpgrade(bytes32 id) external;

    /**
     * @notice Get the expiry date for provided upgrade hash.
     * @dev This will get the value from AppStorage.upgradeScheduled  mapping.
     * @param id This is the keccak256(abi.encode(cut)), where cut is the array of FacetCut struct, IDiamondCut.FacetCut[].
     */
    function getUpgrade(bytes32 id) external view returns (uint256 expiry);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { MarketInfo, TradingCommissions, TradingCommissionsBasisPoints } from "./FreeStructs.sol";

/**
 * @title Matching Market (inspired by MakerOTC: https://github.com/nayms/maker-otc/blob/master/contracts/matching_market.sol)
 * @notice Trade entity tokens
 * @dev This should only be called through an entity, never directly by an EOA
 */
interface IMarketFacet {
    /**
     * @notice Execute a limit offer.
     *
     * @param _sellToken Token to sell.
     * @param _sellAmount Amount to sell.
     * @param _buyToken Token to buy.
     * @param _buyAmount Amount to buy.
     * @return offerId_ returns >0 if a limit offer was created on the market because the offer couldn't be totally fulfilled immediately. In this case the return value is the created offer's id.
     * @return buyTokenCommissionsPaid_ The amount of the buy token paid as commissions on this particular order.
     * @return sellTokenCommissionsPaid_ The amount of the sell token paid as commissions on this particular order.
     */
    function executeLimitOffer(
        bytes32 _sellToken,
        uint256 _sellAmount,
        bytes32 _buyToken,
        uint256 _buyAmount
    )
        external
        returns (
            uint256 offerId_,
            uint256 buyTokenCommissionsPaid_,
            uint256 sellTokenCommissionsPaid_
        );

    /**
     * @notice Cancel offer #`_offerId`. This will cancel the offer so that it's no longer active.
     *
     * @dev This function can be frontrun: In the scenario where a user wants to cancel an unfavorable market offer, an attacker can potentially monitor and identify
     *       that the user has called this method, determine that filling this market offer is profitable, and as a result call executeLimitOffer with a higher gas price to have
     *       their transaction filled before the user can have cancelOffer filled. The most ideal situation for the user is to not have placed the unfavorable market offer
     *       in the first place since an attacker can always monitor our marketplace and potentially identify profitable market offers. Our UI will aide users in not placing
     *       market offers that are obviously unfavorable to the user and/or seem like mistake orders. In the event that a user needs to cancel an offer, it is recommended to
     *       use Flashbots in order to privately send your transaction so an attack cannot be triggered from monitoring the mempool for calls to cancelOffer. A user is recommended
     *       to change their RPC endpoint to point to https://rpc.flashbots.net when calling cancelOffer. We will add additional documentation to aide our users in this process.
     *       More information on using Flashbots: https://docs.flashbots.net/flashbots-protect/rpc/quick-start/
     *
     * @param _offerId offer ID
     */
    function cancelOffer(uint256 _offerId) external;

    /**
     * @notice Get current best offer for given token pair.
     *
     * @dev This means finding the highest sellToken-per-buyToken price, i.e. price = sellToken / buyToken
     *
     * @return offerId, or 0 if no current best is available.
     */
    function getBestOfferId(bytes32 _sellToken, bytes32 _buyToken) external view returns (uint256);

    /**
     * @dev Get last created offer.
     *
     * @return offer id.
     */
    function getLastOfferId() external view returns (uint256);

    /**
     * @dev Get the details of the offer #`_offerId`
     * @param _offerId ID of a particular offer
     * @return _offerState details of the offer
     */
    function getOffer(uint256 _offerId) external view returns (MarketInfo memory _offerState);

    /**
     * @dev Check if the offer #`_offerId` is active or not.
     * @param _offerId ID of a particular offer
     * @return active or not
     */
    function isActiveOffer(uint256 _offerId) external view returns (bool);

    /**
     * @dev Calculate the trading commissions based on a buy amount.
     * @param buyAmount The amount that the commissions payments are calculated from.
     * @return tc TradingCommissions struct with metadata regarding the trade commission payment amounts.
     */
    function calculateTradingCommissions(uint256 buyAmount) external view returns (TradingCommissions memory tc);

    /**
     * @notice Get the marketplace's trading commissions basis points.
     * @return bp - TradingCommissionsBasisPoints struct containing the individual basis points set for each marketplace commission receiver.
     */
    function getTradingCommissionsBasisPoints() external view returns (TradingCommissionsBasisPoints memory bp);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Nayms token facet.
 * @dev Use it to access and manipulate Nayms token.
 */
interface INaymsTokenFacet {
    /**
     * @dev Get total supply of token.
     * @return total supply.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Get token balance of given wallet.
     * @param addr wallet whose balance to get.
     * @return balance of wallet.
     */
    function balanceOf(address addr) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { SimplePolicy, SimplePolicyInfo, PolicyCommissionsBasisPoints } from "./FreeStructs.sol";

/**
 * @title Simple Policies
 * @notice Facet for working with Simple Policies
 * @dev Simple Policy facet
 */
interface ISimplePolicyFacet {
    /**
     * @dev Generate a simple policy hash for singing by the stakeholders
     * @param _startDate Date when policy becomes active
     * @param _maturationDate Date after which policy becomes matured
     * @param _asset ID of the underlying asset, used as collateral and to pay out claims
     * @param _limit Policy coverage limit
     * @param _offchainDataHash Hash of all the important policy data stored offchain
     * @return signingHash_ hash for signing
     */
    function getSigningHash(
        uint256 _startDate,
        uint256 _maturationDate,
        bytes32 _asset,
        uint256 _limit,
        bytes32 _offchainDataHash
    ) external view returns (bytes32 signingHash_);

    /**
     * @dev Pay a premium of `_amount` on simple policy
     * @param _policyId Id of the simple policy
     * @param _amount Amount of the premium
     */
    function paySimplePremium(bytes32 _policyId, uint256 _amount) external;

    /**
     * @dev Pay a claim of `_amount` for simple policy
     * @param _claimId Id of the simple policy claim
     * @param _policyId Id of the simple policy
     * @param _insuredId Id of the insured party
     * @param _amount Amount of the claim
     */
    function paySimpleClaim(
        bytes32 _claimId,
        bytes32 _policyId,
        bytes32 _insuredId,
        uint256 _amount
    ) external;

    /**
     * @dev Get simple policy info
     * @param _id Id of the simple policy
     * @return Simple policy metadata
     */
    function getSimplePolicyInfo(bytes32 _id) external view returns (SimplePolicyInfo memory);

    /**
     * @notice Get the policy premium commissions basis points.
     * @return PolicyCommissionsBasisPoints struct containing the individual basis points set for each policy commission receiver.
     */
    function getPremiumCommissionBasisPoints() external view returns (PolicyCommissionsBasisPoints memory);

    /**
     * @dev Check and update simple policy state
     * @param _id Id of the simple policy
     */
    function checkAndUpdateSimplePolicyState(bytes32 _id) external;

    /**
     * @dev Cancel a simple policy
     * @param _policyId Id of the simple policy
     */
    function cancelSimplePolicy(bytes32 _policyId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Entity } from "./FreeStructs.sol";

/**
 * @title System
 * @notice Use it to perform system level operations
 * @dev Use it to perform system level operations
 */
interface ISystemFacet {
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
    ) external;

    /**
     * @notice Convert a string type to a bytes32 type
     * @param _strIn a string
     */
    function stringToBytes32(string memory _strIn) external pure returns (bytes32 result);

    /**
     * @dev Get whether given id is an object in the system.
     * @param _id object id.
     * @return true if it is an object, false otherwise
     */
    function isObject(bytes32 _id) external view returns (bool);

    /**
     * @dev Get meta of given object.
     * @param _id object id.
     * @return parent object parent
     * @return dataHash object data hash
     * @return tokenSymbol object token symbol
     * @return tokenName object token name
     * @return tokenWrapper object token ERC20 wrapper address
     */
    function getObjectMeta(bytes32 _id)
        external
        view
        returns (
            bytes32 parent,
            bytes32 dataHash,
            string memory tokenSymbol,
            string memory tokenName,
            address tokenWrapper
        );

    /**
     * @notice Wrap an object token as ERC20
     * @param _objectId ID of the tokenized object
     */
    function wrapToken(bytes32 _objectId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ITokenizedVaultFacet {
    /**
     * @notice Gets balance of an account within platform
     * @dev Internal balance for given account
     * @param tokenId Internal ID of the asset
     * @return current balance
     */
    function internalBalanceOf(bytes32 accountId, bytes32 tokenId) external view returns (uint256);

    /**
     * @notice Current supply for the asset
     * @dev Total supply of platform asset
     * @param tokenId Internal ID of the asset
     * @return current balance
     */
    function internalTokenSupply(bytes32 tokenId) external view returns (uint256);

    /**
     * @notice Internal transfer of `amount` tokens
     * @dev Transfer tokens internally
     * @param to token receiver
     * @param tokenId Internal ID of the token
     */
    function internalTransferFromEntity(
        bytes32 to,
        bytes32 tokenId,
        uint256 amount
    ) external;

    /**
     * @notice Internal transfer of `amount` tokens `from` -> `to`
     * @dev Transfer tokens internally between two IDs
     * @param from token sender
     * @param to token receiver
     * @param tokenId Internal ID of the token
     */
    function wrapperInternalTransferFrom(
        bytes32 from,
        bytes32 to,
        bytes32 tokenId,
        uint256 amount
    ) external;

    function internalBurn(
        bytes32 from,
        bytes32 tokenId,
        uint256 amount
    ) external;

    /**
     * @notice Get withdrawable dividend amount
     * @dev Divident available for an entity to withdraw
     * @param _entityId Unique ID of the entity
     * @param _tokenId Unique ID of token
     * @param _dividendTokenId Unique ID of dividend token
     * @return _entityPayout accumulated dividend
     */
    function getWithdrawableDividend(
        bytes32 _entityId,
        bytes32 _tokenId,
        bytes32 _dividendTokenId
    ) external view returns (uint256 _entityPayout);

    /**
     * @notice Withdraw available dividend
     * @dev Transfer dividends to the entity
     * @param ownerId Unique ID of the dividend receiver
     * @param tokenId Unique ID of token
     * @param dividendTokenId Unique ID of dividend token
     */
    function withdrawDividend(
        bytes32 ownerId,
        bytes32 tokenId,
        bytes32 dividendTokenId
    ) external;

    /**
     * @notice Withdraws a user's available dividends.
     * @dev Dividends can be available in more than one dividend denomination. This method will withdraw all available dividends in the different dividend denominations.
     * @param ownerId Unique ID of the dividend receiver
     * @param tokenId Unique ID of token
     */
    function withdrawAllDividends(bytes32 ownerId, bytes32 tokenId) external;

    /**
     * @notice Pay `amount` of dividends
     * @dev Transfer dividends to the entity
     * @param guid Globally unique identifier of a dividend distribution.
     * @param amount the mamount of the dividend token to be distributed to NAYMS token holders.
     */
    function payDividendFromEntity(bytes32 guid, uint256 amount) external;

    /**
     * @notice Get the amount of tokens that an entity has for sale in the marketplace.
     * @param _entityId  Unique platform ID of the entity.
     * @param _tokenId The ID assigned to an external token.
     * @return amount of tokens that the entity has for sale in the marketplace.
     */
    function getLockedBalance(bytes32 _entityId, bytes32 _tokenId) external view returns (uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Token Vault IO
 * @notice External interface to the Token Vault
 * @dev Used for external transfers. Adaptation of ERC-1155 that uses AppStorage and aligns with Nayms ACL implementation.
 *      https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/token/ERC1155
 */
interface ITokenizedVaultIOFacet {
    /**
     * @notice Deposit funds into msg.sender's Nayms platform entity
     * @dev Deposit from msg.sender to their associated entity
     * @param _externalTokenAddress Token address
     * @param _amount deposit amount
     */
    function externalDeposit(address _externalTokenAddress, uint256 _amount) external;

    /**
     * @notice Withdraw funds out of Nayms platform
     * @dev Withdraw from entity to an external account
     * @param _entityId Internal ID of the entity the user is withdrawing from
     * @param _receiverId Internal ID of the account receiving the funds
     * @param _externalTokenAddress Token address
     * @param _amount amount to withdraw
     */
    function externalWithdrawFromEntity(
        bytes32 _entityId,
        address _receiverId,
        address _externalTokenAddress,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Users
 * @notice Manage user entity
 * @dev Use manage user entity
 */
interface IUserFacet {
    /**
     * @notice Get the platform ID of `addr` account
     * @dev Convert address to platform ID
     * @param addr Account address
     * @return userId Unique platform ID
     */
    function getUserIdFromAddress(address addr) external pure returns (bytes32 userId);

    /**
     * @notice Get the token address from ID of the external token
     * @dev Convert the bytes32 external token ID to its respective ERC20 contract address
     * @param _externalTokenId The ID assigned to an external token
     * @return tokenAddress Contract address
     */
    function getAddressFromExternalTokenId(bytes32 _externalTokenId) external pure returns (address tokenAddress);

    /**
     * @notice Set the entity for the user
     * @dev Assign the user an entity. The entity must exist in order to associate it with a user.
     * @param _userId Unique platform ID of the user account
     * @param _entityId Unique platform ID of the entity
     */
    function setEntity(bytes32 _userId, bytes32 _entityId) external;

    /**
     * @notice Get the entity for the user
     * @dev Gets the entity related to the user
     * @param _userId Unique platform ID of the user account
     * @return entityId Unique platform ID of the entity
     */
    function getEntity(bytes32 _userId) external view returns (bytes32 entityId);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { AppStorage, LibAppStorage } from "../AppStorage.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibAdmin } from "./LibAdmin.sol";
import { LibObject } from "./LibObject.sol";
import { LibConstants } from "./LibConstants.sol";
import { RoleIsMissing, AssignerGroupIsMissing } from "src/diamonds/nayms/interfaces/CustomErrors.sol";

library LibACL {
    /**
     * @dev Emitted when a role gets updated. Empty roleId is assigned upon role removal
     * @param objectId The user or object that was assigned the role.
     * @param contextId The context where the role was assigned to.
     * @param assignedRoleId The ID of the role which got (un)assigned. (empty ID when unassigned)
     * @param functionName The function performing the action
     */
    event RoleUpdate(bytes32 indexed objectId, bytes32 contextId, bytes32 assignedRoleId, string functionName);
    /**
     * @dev Emitted when a role group gets updated.
     * @param role The role name.
     * @param group the group name.
     * @param roleInGroup whether the role is now in the group or not.
     */
    event RoleGroupUpdated(string role, string group, bool roleInGroup);
    /**
     * @dev Emitted when a role assigners gets updated.
     * @param role The role name.
     * @param group the name of the group that can now assign this role.
     */
    event RoleCanAssignUpdated(string role, string group);

    function _assignRole(
        bytes32 _objectId,
        bytes32 _contextId,
        bytes32 _roleId
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(_objectId != "", "invalid object ID");
        require(_contextId != "", "invalid context ID");
        require(_roleId != "", "invalid role ID");

        s.roles[_objectId][_contextId] = _roleId;

        if (_contextId == LibAdmin._getSystemId() && _roleId == LibHelpers._stringToBytes32(LibConstants.ROLE_SYSTEM_ADMIN)) {
            unchecked {
                s.sysAdmins += 1;
            }
        }

        emit RoleUpdate(_objectId, _contextId, _roleId, "_assignRole");
    }

    function _unassignRole(bytes32 _objectId, bytes32 _contextId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32 roleId = s.roles[_objectId][_contextId];
        if (_contextId == LibAdmin._getSystemId() && roleId == LibHelpers._stringToBytes32(LibConstants.ROLE_SYSTEM_ADMIN)) {
            require(s.sysAdmins > 1, "must have at least one system admin");
            unchecked {
                s.sysAdmins -= 1;
            }
        }

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

        if (objectRoleInContext != 0 && s.groups[objectRoleInContext][_groupId]) {
            ret = true;
        } else {
            // A role in the context of the system covers all objects
            bytes32 objectRoleInSystem = s.roles[_objectId][LibAdmin._getSystemId()];

            if (objectRoleInSystem != 0 && s.groups[objectRoleInSystem][_groupId]) {
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

    /**
     * @notice Checks if assigner has the authority to assign object to a role in given context
     * @dev Any object ID can be a context, system is a special context with highest priority
     * @param _assignerId ID of an account wanting to assign a role to an object
     * @param _objectId ID of an object that is being assigned a role
     * @param _contextId ID of the context in which a role is being assigned
     * @param _roleId ID of a role being assigned
     */
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

        // assigners group undefined
        if (assignerGroup == 0) {
            ret = false;
        }
        // Check for assigner's group membership in given context
        else if (_isInGroup(_assignerId, _contextId, assignerGroup)) {
            ret = true;
        }
        // Otherwise, check his parent's membership in system context
        // if account itself does not have the membership in given context, then having his parent
        // in the system context grants him the privilege needed
        else if (_isParentInGroup(_assignerId, LibAdmin._getSystemId(), assignerGroup)) {
            ret = true;
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

    function _updateRoleAssigner(string memory _role, string memory _assignerGroup) internal {
        if (bytes32(bytes(_role)) == "") {
            revert RoleIsMissing();
        }
        if (bytes32(bytes(_assignerGroup)) == "") {
            revert AssignerGroupIsMissing();
        }
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
        if (bytes32(bytes(_role)) == "") {
            revert RoleIsMissing();
        }
        if (bytes32(bytes(_group)) == "") {
            revert AssignerGroupIsMissing();
        }

        s.groups[LibHelpers._stringToBytes32(_role)][LibHelpers._stringToBytes32(_group)] = _roleInGroup;
        emit RoleGroupUpdated(_role, _group, _roleInGroup);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { AppStorage, LibAppStorage } from "../AppStorage.sol";
import { LibConstants } from "./LibConstants.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibObject } from "./LibObject.sol";
import { LibERC20 } from "src/erc20/LibERC20.sol";

import { CannotAddNullDiscountToken, CannotAddNullSupportedExternalToken, CannotSupportExternalTokenWithMoreThan18Decimals } from "src/diamonds/nayms/interfaces/CustomErrors.sol";

library LibAdmin {
    event MaxDividendDenominationsUpdated(uint8 oldMax, uint8 newMax);
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

    function _isSupportedExternalTokenAddress(address _tokenId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.externalTokenSupported[_tokenId];
    }

    function _isSupportedExternalToken(bytes32 _tokenId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.externalTokenSupported[LibHelpers._getAddressFromId(_tokenId)];
    }

    function _addSupportedExternalToken(address _tokenAddress) internal {
        if (LibERC20.decimals(_tokenAddress) > 18) {
            revert CannotSupportExternalTokenWithMoreThan18Decimals();
        }
        AppStorage storage s = LibAppStorage.diamondStorage();

        bool alreadyAdded = s.externalTokenSupported[_tokenAddress];
        if (!alreadyAdded) {
            s.externalTokenSupported[_tokenAddress] = true;
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
pragma solidity 0.8.17;

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
    string internal constant ROLE_SEGREGATED_ACCOUNT = "Segregated Account";
    string internal constant ROLE_SERVICE_PROVIDER = "Service Provider";

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
    string internal constant GROUP_SEGREGATED_ACCOUNTS = "Segregated Accounts";
    string internal constant GROUP_SERVICE_PROVIDERS = "Service Providers";
    string internal constant GROUP_POLICY_HANDLERS = "Policy Handlers";

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
    uint256 internal constant BP_FACTOR = 10000;

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
pragma solidity 0.8.17;

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

    function _addressToBytes32(address addr) internal pure returns (bytes32) {
        return _bytesToBytes32(abi.encode(addr));
    }

    function _stringToBytes32(string memory strIn) internal pure returns (bytes32) {
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
pragma solidity 0.8.17;

import { AppStorage, LibAppStorage } from "../AppStorage.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibAdmin } from "./LibAdmin.sol";
import { EntityDoesNotExist, MissingSymbolWhenEnablingTokenization } from "src/diamonds/nayms/interfaces/CustomErrors.sol";

import { ERC20Wrapper } from "../../../erc20/ERC20Wrapper.sol";

/// @notice Contains internal methods for core Nayms system functionality
library LibObject {
    event TokenWrapped(bytes32 indexed entityId, address tokenWrapper);

    function _createObject(
        bytes32 _objectId,
        bytes32 _parentId,
        bytes32 _dataHash
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // Check if the objectId is already being used by another object
        require(!s.existingObjects[_objectId], "objectId is already being used by another object");

        s.existingObjects[_objectId] = true;
        s.objectParent[_objectId] = _parentId;
        s.objectDataHashes[_objectId] = _dataHash;
    }

    function _createObject(bytes32 _objectId, bytes32 _dataHash) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(!s.existingObjects[_objectId], "objectId is already being used by another object");

        s.existingObjects[_objectId] = true;
        s.objectDataHashes[_objectId] = _dataHash;
    }

    function _createObject(bytes32 _objectId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(!s.existingObjects[_objectId], "objectId is already being used by another object");

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
        return (bytes(s.objectTokenSymbol[_objectId]).length != 0);
    }

    function _enableObjectTokenization(
        bytes32 _objectId,
        string memory _symbol,
        string memory _name
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (bytes(_symbol).length == 0) {
            revert MissingSymbolWhenEnablingTokenization(_objectId);
        }

        // Ensure the entity exists before tokenizing the entity, otherwise revert.
        if (!s.existingEntities[_objectId]) {
            revert EntityDoesNotExist(_objectId);
        }

        require(!_isObjectTokenizable(_objectId), "object already tokenized");
        require(bytes(_symbol).length < 16, "symbol must be less than 16 characters");

        s.objectTokenSymbol[_objectId] = _symbol;
        s.objectTokenName[_objectId] = _name;
    }

    function _isObjectTokenWrapped(bytes32 _objectId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return (s.objectTokenWrapper[_objectId] != address(0));
    }

    function _wrapToken(bytes32 _entityId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(_isObjectTokenizable(_entityId), "must be tokenizable");
        require(!_isObjectTokenWrapped(_entityId), "must not be wrapped already");

        ERC20Wrapper tokenWrapper = new ERC20Wrapper(_entityId);
        address wrapperAddress = address(tokenWrapper);

        s.objectTokenWrapper[_entityId] = wrapperAddress;

        emit TokenWrapped(_entityId, wrapperAddress);
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
            string memory tokenSymbol,
            string memory tokenName,
            address tokenWrapper
        )
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        parent = s.objectParent[_id];
        dataHash = s.objectDataHashes[_id];
        tokenSymbol = s.objectTokenSymbol[_id];
        tokenName = s.objectTokenName[_id];
        tokenWrapper = s.objectTokenWrapper[_id];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { LibDiamond } from "../libs/LibDiamond.sol";

contract DiamondCutFacet is IDiamondCut {
    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 originalSelectorCount = ds.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;
        // Check if last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8"
        if (selectorCount & 7 > 0) {
            // get last selectorSlot
            // "selectorCount >> 3" is a gas efficient division by 8 "selectorCount / 8"
            selectorSlot = ds.selectorSlots[selectorCount >> 3];
        }
        // loop through diamond cut
        for (uint256 facetIndex = 0; facetIndex < _diamondCut.length; facetIndex++) {
            (selectorCount, selectorSlot) = LibDiamond.addReplaceRemoveFacetSelectors(
                selectorCount,
                selectorSlot,
                _diamondCut[facetIndex].facetAddress,
                _diamondCut[facetIndex].action,
                _diamondCut[facetIndex].functionSelectors
            );
        }
        if (selectorCount != originalSelectorCount) {
            ds.selectorCount = uint16(selectorCount);
        }
        // If last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8"
        if (selectorCount & 7 > 0) {
            // "selectorCount >> 3" is a gas efficient division by 8 "selectorCount / 8"
            ds.selectorSlots[selectorCount >> 3] = selectorSlot;
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        LibDiamond.initializeDiamondCut(_init, _calldata);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import { LibDiamond } from "../libs/LibDiamond.sol";
import { IDiamondLoupe } from "../interfaces/IDiamondLoupe.sol";
import { IERC165 } from "../interfaces/IERC165.sol";

contract DiamondLoupeFacet is IDiamondLoupe, IERC165 {
    // Diamond Loupe Functions
    ////////////////////////////////////////////////////////////////////
    /// These functions are expected to be called frequently by tools.
    //
    // struct Facet {
    //     address facetAddress;
    //     bytes4[] functionSelectors;
    // }
    /// @notice Gets all facets and their selectors.
    /// @return facets_ Facet
    function facets() external view override returns (Facet[] memory facets_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facets_ = new Facet[](ds.selectorCount);
        uint8[] memory numFacetSelectors = new uint8[](ds.selectorCount);
        uint256 numFacets;
        uint256 selectorIndex;
        // loop through function selectors
        for (uint256 slotIndex; selectorIndex < ds.selectorCount; slotIndex++) {
            bytes32 slot = ds.selectorSlots[slotIndex];
            for (uint256 selectorSlotIndex; selectorSlotIndex < 8; selectorSlotIndex++) {
                selectorIndex++;
                if (selectorIndex > ds.selectorCount) {
                    break;
                }
                bytes4 selector = bytes4(slot << (selectorSlotIndex << 5));
                address facetAddress_ = address(bytes20(ds.facets[selector]));
                bool continueLoop;
                for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
                    if (facets_[facetIndex].facetAddress == facetAddress_) {
                        facets_[facetIndex].functionSelectors[numFacetSelectors[facetIndex]] = selector;
                        // probably will never have more than 256 functions from one facet contract
                        require(numFacetSelectors[facetIndex] < 255);
                        numFacetSelectors[facetIndex]++;
                        continueLoop = true;
                        break;
                    }
                }
                if (continueLoop) {
                    continue;
                }
                facets_[numFacets].facetAddress = facetAddress_;
                facets_[numFacets].functionSelectors = new bytes4[](ds.selectorCount);
                facets_[numFacets].functionSelectors[0] = selector;
                numFacetSelectors[numFacets] = 1;
                numFacets++;
            }
        }
        for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
            uint256 numSelectors = numFacetSelectors[facetIndex];
            bytes4[] memory selectors = facets_[facetIndex].functionSelectors;
            // setting the number of selectors
            assembly {
                mstore(selectors, numSelectors)
            }
        }
        // setting the number of facets
        assembly {
            mstore(facets_, numFacets)
        }
    }

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_ The selectors associated with a facet address.
    function facetFunctionSelectors(address _facet) external view override returns (bytes4[] memory facetFunctionSelectors_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 numSelectors;
        facetFunctionSelectors_ = new bytes4[](ds.selectorCount);
        uint256 selectorIndex;
        // loop through function selectors
        for (uint256 slotIndex; selectorIndex < ds.selectorCount; slotIndex++) {
            bytes32 slot = ds.selectorSlots[slotIndex];
            for (uint256 selectorSlotIndex; selectorSlotIndex < 8; selectorSlotIndex++) {
                selectorIndex++;
                if (selectorIndex > ds.selectorCount) {
                    break;
                }
                bytes4 selector = bytes4(slot << (selectorSlotIndex << 5));
                address facet = address(bytes20(ds.facets[selector]));
                if (_facet == facet) {
                    facetFunctionSelectors_[numSelectors] = selector;
                    numSelectors++;
                }
            }
        }
        // Set the number of selectors in the array
        assembly {
            mstore(facetFunctionSelectors_, numSelectors)
        }
    }

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view override returns (address[] memory facetAddresses_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetAddresses_ = new address[](ds.selectorCount);
        uint256 numFacets;
        uint256 selectorIndex;
        // loop through function selectors
        for (uint256 slotIndex; selectorIndex < ds.selectorCount; slotIndex++) {
            bytes32 slot = ds.selectorSlots[slotIndex];
            for (uint256 selectorSlotIndex; selectorSlotIndex < 8; selectorSlotIndex++) {
                selectorIndex++;
                if (selectorIndex > ds.selectorCount) {
                    break;
                }
                bytes4 selector = bytes4(slot << (selectorSlotIndex << 5));
                address facetAddress_ = address(bytes20(ds.facets[selector]));
                bool continueLoop;
                for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
                    if (facetAddress_ == facetAddresses_[facetIndex]) {
                        continueLoop = true;
                        break;
                    }
                }
                if (continueLoop) {
                    continue;
                }
                facetAddresses_[numFacets] = facetAddress_;
                numFacets++;
            }
        }
        // Set the number of facet addresses in the array
        assembly {
            mstore(facetAddresses_, numFacets)
        }
    }

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view override returns (address facetAddress_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetAddress_ = address(bytes20(ds.facets[_functionSelector]));
    }

    // This implements ERC-165.
    function supportsInterface(bytes4 _interfaceId) external view override returns (bool) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.supportedInterfaces[_interfaceId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { LibACL } from "src/diamonds/nayms/libs/LibACL.sol";
import { LibHelpers } from "src/diamonds/nayms/libs/LibHelpers.sol";
import { LibConstants } from "src/diamonds/nayms/libs/LibConstants.sol";
import { LibDiamond } from "src/diamonds/shared/libs/LibDiamond.sol";
import { OwnershipFacet } from "src/diamonds/shared/facets/OwnershipFacet.sol";
import { Modifiers } from "src/diamonds/nayms/Modifiers.sol";

contract NaymsOwnershipFacet is OwnershipFacet, Modifiers {
    function transferOwnership(address _newOwner) public override assertSysAdmin {
        bytes32 systemID = LibHelpers._stringToBytes32(LibConstants.SYSTEM_IDENTIFIER);
        bytes32 newAcc1Id = LibHelpers._getIdForAddress(_newOwner);

        require(!LibACL._isInGroup(newAcc1Id, systemID, LibHelpers._stringToBytes32(LibConstants.GROUP_SYSTEM_ADMINS)), "NEW owner MUST NOT be sys admin");
        require(!LibACL._isInGroup(newAcc1Id, systemID, LibHelpers._stringToBytes32(LibConstants.GROUP_SYSTEM_MANAGERS)), "NEW owner MUST NOT be sys manager");

        super.transferOwnership(_newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { LibDiamond } from "../libs/LibDiamond.sol";
import { IERC173 } from "../interfaces/IERC173.sol";

contract OwnershipFacet is IERC173 {
    function transferOwnership(address _newOwner) public virtual override {
        LibDiamond.setContractOwner(_newOwner);
    }

    function owner() external view override returns (address owner_) {
        owner_ = LibDiamond.contractOwner();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0 is ERC165
interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { IDiamondLoupe } from "../interfaces/IDiamondLoupe.sol";
import { IERC165 } from "../interfaces/IERC165.sol";
import { IERC173 } from "../interfaces/IERC173.sol";

library LibDiamond {
    bytes32 internal constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct DiamondStorage {
        // maps function selectors to the facets that execute the functions.
        // and maps the selectors to their position in the selectorSlots array.
        // func selector => address facet, selector position
        mapping(bytes4 => bytes32) facets;
        // array of slots of function selectors.
        // each slot holds 8 function selectors.
        mapping(uint256 => bytes32) selectorSlots;
        // The number of function selectors in selectorSlots
        uint16 selectorCount;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    function addDiamondFunctions(
        address _diamondCutFacet,
        address _diamondLoupeFacet,
        address _ownershipFacet
    ) internal {
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](3);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({ facetAddress: _diamondCutFacet, action: IDiamondCut.FacetCutAction.Add, functionSelectors: functionSelectors });
        functionSelectors = new bytes4[](5);
        functionSelectors[0] = IDiamondLoupe.facets.selector;
        functionSelectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
        functionSelectors[2] = IDiamondLoupe.facetAddresses.selector;
        functionSelectors[3] = IDiamondLoupe.facetAddress.selector;
        functionSelectors[4] = IERC165.supportsInterface.selector;
        cut[1] = IDiamondCut.FacetCut({ facetAddress: _diamondLoupeFacet, action: IDiamondCut.FacetCutAction.Add, functionSelectors: functionSelectors });
        functionSelectors = new bytes4[](2);
        functionSelectors[0] = IERC173.transferOwnership.selector;
        functionSelectors[1] = IERC173.owner.selector;
        cut[2] = IDiamondCut.FacetCut({ facetAddress: _ownershipFacet, action: IDiamondCut.FacetCutAction.Add, functionSelectors: functionSelectors });
        diamondCut(cut, address(0), "");
    }

    event DiamondCut(IDiamondCut.FacetCut[] diamondCut, address init, bytes _calldata);

    bytes32 internal constant CLEAR_ADDRESS_MASK = bytes32(uint256(0xffffffffffffffffffffffff));
    bytes32 internal constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));

    // Internal function version of diamondCut
    // This code is almost the same as the external diamondCut,
    // except it is using 'Facet[] memory _diamondCut' instead of
    // 'Facet[] calldata _diamondCut'.
    // The code is duplicated to prevent copying calldata to memory which
    // causes an error for a two dimensional array.
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        DiamondStorage storage ds = diamondStorage();
        uint256 originalSelectorCount = ds.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;
        // Check if last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8"
        if (selectorCount & 7 > 0) {
            // get last selectorSlot
            // "selectorSlot >> 3" is a gas efficient division by 8 "selectorSlot / 8"
            selectorSlot = ds.selectorSlots[selectorCount >> 3];
        }
        // loop through diamond cut
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            (selectorCount, selectorSlot) = addReplaceRemoveFacetSelectors(
                selectorCount,
                selectorSlot,
                _diamondCut[facetIndex].facetAddress,
                _diamondCut[facetIndex].action,
                _diamondCut[facetIndex].functionSelectors
            );
        }
        if (selectorCount != originalSelectorCount) {
            ds.selectorCount = uint16(selectorCount);
        }
        // If last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8"
        if (selectorCount & 7 > 0) {
            // "selectorSlot >> 3" is a gas efficient division by 8 "selectorSlot / 8"
            ds.selectorSlots[selectorCount >> 3] = selectorSlot;
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addReplaceRemoveFacetSelectors(
        uint256 _selectorCount,
        bytes32 _selectorSlot,
        address _newFacetAddress,
        IDiamondCut.FacetCutAction _action,
        bytes4[] memory _selectors
    ) internal returns (uint256, bytes32) {
        DiamondStorage storage ds = diamondStorage();
        require(_selectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        if (_action == IDiamondCut.FacetCutAction.Add) {
            enforceHasContractCode(_newFacetAddress, "LibDiamondCut: Add facet has no code");
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                require(address(bytes20(oldFacet)) == address(0), "LibDiamondCut: Can't add function that already exists");
                // add facet for selector
                ds.facets[selector] = bytes20(_newFacetAddress) | bytes32(_selectorCount);
                // "_selectorCount & 7" is a gas efficient modulo by eight "_selectorCount % 8"
                uint256 selectorInSlotPosition = (_selectorCount & 7) << 5;
                // clear selector position in slot and add selector
                _selectorSlot = (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) | (bytes32(selector) >> selectorInSlotPosition);
                // if slot is full then write it to storage
                if (selectorInSlotPosition == 224) {
                    // "_selectorSlot >> 3" is a gas efficient division by 8 "_selectorSlot / 8"
                    ds.selectorSlots[_selectorCount >> 3] = _selectorSlot;
                    _selectorSlot = 0;
                }
                _selectorCount++;
            }
        } else if (_action == IDiamondCut.FacetCutAction.Replace) {
            enforceHasContractCode(_newFacetAddress, "LibDiamondCut: Replace facet has no code");
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                address oldFacetAddress = address(bytes20(oldFacet));
                // only useful if immutable functions exist
                require(oldFacetAddress != address(this), "LibDiamondCut: Can't replace immutable function");
                require(oldFacetAddress != _newFacetAddress, "LibDiamondCut: Can't replace function with same function");
                require(oldFacetAddress != address(0), "LibDiamondCut: Can't replace function that doesn't exist");
                // replace old facet address
                ds.facets[selector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(_newFacetAddress);
            }
        } else if (_action == IDiamondCut.FacetCutAction.Remove) {
            require(_newFacetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
            // "_selectorCount >> 3" is a gas efficient division by 8 "_selectorCount / 8"
            uint256 selectorSlotCount = _selectorCount >> 3;
            // "_selectorCount & 7" is a gas efficient modulo by eight "_selectorCount % 8"
            uint256 selectorInSlotIndex = _selectorCount & 7;
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                if (_selectorSlot == 0) {
                    // get last selectorSlot
                    selectorSlotCount--;
                    _selectorSlot = ds.selectorSlots[selectorSlotCount];
                    selectorInSlotIndex = 7;
                } else {
                    selectorInSlotIndex--;
                }
                bytes4 lastSelector;
                uint256 oldSelectorsSlotCount;
                uint256 oldSelectorInSlotPosition;
                // adding a block here prevents stack too deep error
                {
                    bytes4 selector = _selectors[selectorIndex];
                    bytes32 oldFacet = ds.facets[selector];
                    require(address(bytes20(oldFacet)) != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
                    // only useful if immutable functions exist
                    require(address(bytes20(oldFacet)) != address(this), "LibDiamondCut: Can't remove immutable function");
                    // replace selector with last selector in ds.facets
                    // gets the last selector
                    lastSelector = bytes4(_selectorSlot << (selectorInSlotIndex << 5));
                    if (lastSelector != selector) {
                        // update last selector slot position info
                        ds.facets[lastSelector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(ds.facets[lastSelector]);
                    }
                    delete ds.facets[selector];
                    uint256 oldSelectorCount = uint16(uint256(oldFacet));
                    // "oldSelectorCount >> 3" is a gas efficient division by 8 "oldSelectorCount / 8"
                    oldSelectorsSlotCount = oldSelectorCount >> 3;
                    // "oldSelectorCount & 7" is a gas efficient modulo by eight "oldSelectorCount % 8"
                    oldSelectorInSlotPosition = (oldSelectorCount & 7) << 5;
                }
                if (oldSelectorsSlotCount != selectorSlotCount) {
                    bytes32 oldSelectorSlot = ds.selectorSlots[oldSelectorsSlotCount];
                    // clears the selector we are deleting and puts the last selector in its place.
                    oldSelectorSlot = (oldSelectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) | (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                    // update storage with the modified slot
                    ds.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
                } else {
                    // clears the selector we are deleting and puts the last selector in its place.
                    _selectorSlot = (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) | (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                }
                if (selectorInSlotIndex == 0) {
                    delete ds.selectorSlots[selectorSlotCount];
                    _selectorSlot = 0;
                }
            }
            _selectorCount = selectorSlotCount * 8 + selectorInSlotIndex;
        } else {
            revert("LibDiamondCut: Incorrect FacetCutAction");
        }
        return (_selectorCount, _selectorSlot);
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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
pragma solidity 0.8.17;

// solhint-disable func-name-mixedcase

import { IERC20 } from "./IERC20.sol";
import { INayms } from "../diamonds/nayms/INayms.sol";
import { LibHelpers } from "../diamonds/nayms/libs/LibHelpers.sol";
import { LibConstants } from "../diamonds/nayms/libs/LibConstants.sol";
import { ReentrancyGuard } from "../utils/ReentrancyGuard.sol";

contract ERC20Wrapper is IERC20, ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/
    bytes32 internal immutable tokenId;
    INayms internal immutable nayms;
    mapping(address => mapping(address => uint256)) public allowances;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/
    uint256 internal immutable INITIAL_CHAIN_ID;
    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;
    mapping(address => uint256) public nonces;

    constructor(bytes32 _tokenId) {
        // ensure only diamond can instantiate this
        nayms = INayms(msg.sender);

        require(nayms.isObjectTokenizable(_tokenId), "must be tokenizable");
        require(!nayms.isTokenWrapped(_tokenId), "must not be wrapped already");

        tokenId = _tokenId;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    function name() external view returns (string memory) {
        (, , , string memory tokenName, ) = nayms.getObjectMeta(tokenId);
        return tokenName;
    }

    function symbol() external view returns (string memory) {
        (, , string memory tokenSymbol, , ) = nayms.getObjectMeta(tokenId);
        return tokenSymbol;
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function totalSupply() external view returns (uint256) {
        return nayms.internalTokenSupply(tokenId);
    }

    function balanceOf(address who) external view returns (uint256) {
        return nayms.internalBalanceOf(LibHelpers._getIdForAddress(who), tokenId);
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return allowances[owner][spender];
    }

    function transfer(address to, uint256 value) external nonReentrant returns (bool) {
        bytes32 fromId = LibHelpers._getIdForAddress(msg.sender);
        bytes32 toId = LibHelpers._getIdForAddress(to);

        emit Transfer(msg.sender, to, value);

        nayms.wrapperInternalTransferFrom(fromId, toId, tokenId, value);

        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowances[msg.sender][spender] = value;
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external nonReentrant returns (bool) {
        if (value == 0) {
            revert();
        }
        uint256 allowed = allowances[from][msg.sender]; // Saves gas for limited approvals.
        require(allowed >= value, "not enough allowance");

        if (allowed != type(uint256).max) allowances[from][msg.sender] = allowed - value;

        bytes32 fromId = LibHelpers._getIdForAddress(from);
        bytes32 toId = LibHelpers._getIdForAddress(to);

        emit Transfer(from, to, value);

        nayms.wrapperInternalTransferFrom(fromId, toId, tokenId, value);

        return true;
    }

    // refer to https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol#L116
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowances[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(LibHelpers._bytes32ToBytes(tokenId)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * See https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/token/ERC20
 */
interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/******************************************************************************\
* Author: Nick Mudge
*
/******************************************************************************/

import { IERC20 } from "./IERC20.sol";

library LibERC20 {
    function decimals(address _token) internal returns (uint8) {
        uint256 size;
        assembly {
            size := extcodesize(_token)
        }
        require(size > 0, "LibERC20: ERC20 token address has no code");
        (bool success, bytes memory result) = _token.call(abi.encodeWithSelector(IERC20.decimals.selector));
        if (success) {
            return abi.decode(result, (uint8));
        } else {
            revert("LibERC20: call to decimals() failed");
        }
    }

    function balanceOf(address _token, address _who) internal returns (uint256) {
        uint256 size;
        assembly {
            size := extcodesize(_token)
        }
        require(size > 0, "LibERC20: ERC20 token address has no code");
        (bool success, bytes memory result) = _token.call(abi.encodeWithSelector(IERC20.balanceOf.selector, _who));
        if (success) {
            return abi.decode(result, (uint256));
        } else {
            revert("LibERC20: call to balanceOf() failed");
        }
    }

    function transferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _value
    ) internal {
        uint256 size;
        assembly {
            size := extcodesize(_token)
        }
        require(size > 0, "LibERC20: ERC20 token address has no code");
        (bool success, bytes memory result) = _token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, _from, _to, _value));
        handleReturn(success, result);
    }

    function transfer(
        address _token,
        address _to,
        uint256 _value
    ) internal {
        uint256 size;
        assembly {
            size := extcodesize(_token)
        }
        require(size > 0, "LibERC20: ERC20 token address has no code");
        (bool success, bytes memory result) = _token.call(abi.encodeWithSelector(IERC20.transfer.selector, _to, _value));
        handleReturn(success, result);
    }

    function handleReturn(bool _success, bytes memory _result) internal pure {
        if (_success) {
            if (_result.length > 0) {
                require(abi.decode(_result, (bool)), "LibERC20: transfer or transferFrom returned false");
            }
        } else {
            if (_result.length > 0) {
                // bubble up any reason for revert
                // see https://github.com/OpenZeppelin/openzeppelin-contracts/blob/c239e1af8d1a1296577108dd6989a17b57434f8e/contracts/utils/Address.sol#L201
                assembly {
                    revert(add(32, _result), mload(_result))
                }
            } else {
                revert("LibERC20: transfer or transferFrom reverted");
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { LibAppStorage } from "src/diamonds/nayms/AppStorage.sol";

// From OpenZeppellin: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol

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

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(LibAppStorage.diamondStorage().reentrancyStatus != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        LibAppStorage.diamondStorage().reentrancyStatus = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        LibAppStorage.diamondStorage().reentrancyStatus = _NOT_ENTERED;
    }
}