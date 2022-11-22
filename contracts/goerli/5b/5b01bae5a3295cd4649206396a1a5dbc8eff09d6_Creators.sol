// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ICreators} from "./interfaces/ICreators.sol";
import {IMetadata} from "./interfaces/IMetadata.sol";
import {IProjects} from "./interfaces/IProjects.sol";
import {IRaises} from "./interfaces/IRaises.sol";
import {IMetadataResolver} from "./interfaces/IMetadataResolver.sol";
import {ICreatorAuth} from "./interfaces/ICreatorAuth.sol";
import {IControllable} from "./interfaces/IControllable.sol";
import {Controllable} from "./abstract/Controllable.sol";
import {RaiseToken} from "./libraries/RaiseToken.sol";
import {RaiseParams} from "./structs/Raise.sol";
import {TierParams} from "./structs/Tier.sol";

/// @title Creators - Creator interface
/// @notice Creators interact with this contract to create projects, configure
/// mints, and manage token metadata.
contract Creators is ICreators, Controllable {
    using RaiseToken for uint256;

    string public constant NAME = "Creators";
    string public constant VERSION = "0.0.1";

    address public creatorAuth;
    address public metadata;
    address public projects;
    address public raises;

    modifier onlyCreator() {
        if (ICreatorAuth(creatorAuth).denied(msg.sender)) {
            revert Forbidden();
        }
        _;
    }

    modifier onlyProjectOwner(uint32 projectId) {
        if (msg.sender != IProjects(projects).ownerOf(projectId)) {
            revert Forbidden();
        }
        _;
    }

    modifier onlyPendingOwner(uint32 projectId) {
        if (msg.sender != IProjects(projects).pendingOwnerOf(projectId)) {
            revert Forbidden();
        }
        _;
    }

    constructor(address _controller) Controllable(_controller) {}

    /// @inheritdoc ICreators
    function createProject() external override onlyCreator returns (uint32) {
        return IProjects(projects).create(msg.sender);
    }

    /// @inheritdoc ICreators
    function transferOwnership(uint32 projectId, address newOwner)
        external
        override
        onlyCreator
        onlyProjectOwner(projectId)
    {
        if (ICreatorAuth(creatorAuth).denied(newOwner)) revert Forbidden();
        return IProjects(projects).transferOwnership(projectId, newOwner);
    }

    /// @inheritdoc ICreators
    function acceptOwnership(uint32 projectId) external override onlyCreator onlyPendingOwner(projectId) {
        return IProjects(projects).acceptOwnership(projectId);
    }

    /// @inheritdoc ICreators
    function createRaise(uint32 projectId, RaiseParams memory params, TierParams[] memory tiers)
        external
        override
        onlyCreator
        onlyProjectOwner(projectId)
        returns (uint32)
    {
        return IRaises(raises).create(projectId, params, tiers);
    }

    /// @inheritdoc ICreators
    function updateRaise(uint32 projectId, uint32 raiseId, RaiseParams memory params, TierParams[] memory tiers)
        external
        override
        onlyCreator
        onlyProjectOwner(projectId)
    {
        IRaises(raises).update(projectId, raiseId, params, tiers);
    }

    /// @inheritdoc ICreators
    function cancelRaise(uint32 projectId, uint32 raiseId) external override onlyCreator onlyProjectOwner(projectId) {
        IRaises(raises).cancel(projectId, raiseId);
    }

    /// @inheritdoc ICreators
    function closeRaise(uint32 projectId, uint32 raiseId) external override onlyCreator onlyProjectOwner(projectId) {
        IRaises(raises).close(projectId, raiseId);
    }

    /// @inheritdoc ICreators
    function withdrawRaiseFunds(uint32 projectId, uint32 raiseId, address receiver)
        external
        override
        onlyCreator
        onlyProjectOwner(projectId)
    {
        IRaises(raises).withdraw(projectId, raiseId, receiver);
    }

    /// @inheritdoc ICreators
    function setCustomURI(uint256 tokenId, string memory customURI)
        external
        override
        onlyCreator
        onlyProjectOwner(tokenId.projectId())
    {
        IMetadata(metadata).setCustomURI(tokenId, customURI);
    }

    /// @inheritdoc ICreators
    function setCustomResolver(uint256 tokenId, IMetadataResolver customResolver)
        external
        override
        onlyCreator
        onlyProjectOwner(tokenId.projectId())
    {
        IMetadata(metadata).setCustomResolver(tokenId, customResolver);
    }

    /// @inheritdoc IControllable
    function setDependency(bytes32 _name, address _contract)
        external
        override (Controllable, IControllable)
        onlyController
    {
        if (_contract == address(0)) revert ZeroAddress();
        else if (_name == "creatorAuth") _setCreatorAuth(_contract);
        else if (_name == "metadata") _setMetadata(_contract);
        else if (_name == "projects") _setProjects(_contract);
        else if (_name == "raises") _setRaises(_contract);
        else revert InvalidDependency(_name);
    }

    function _setCreatorAuth(address _creatorAuth) internal {
        emit SetCreatorAuth(creatorAuth, _creatorAuth);
        creatorAuth = _creatorAuth;
    }

    function _setMetadata(address _metadata) internal {
        emit SetMetadata(metadata, _metadata);
        metadata = _metadata;
    }

    function _setProjects(address _projects) internal {
        emit SetProjects(projects, _projects);
        projects = _projects;
    }

    function _setRaises(address _raises) internal {
        emit SetRaises(raises, _raises);
        raises = _raises;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IControllable} from "../interfaces/IControllable.sol";

/// @title Controllable - Controller management functions
/// @notice An abstract base contract for contracts managed by the Controller.
abstract contract Controllable is IControllable {
    address public controller;

    modifier onlyController() {
        if (msg.sender != controller) {
            revert Forbidden();
        }
        _;
    }

    constructor(address _controller) {
        if (_controller == address(0)) {
            revert ZeroAddress();
        }
        controller = _controller;
    }

    /// @inheritdoc IControllable
    function setDependency(bytes32 _name, address) external virtual onlyController {
        revert InvalidDependency(_name);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

uint256 constant ONE_BYTE = 0x8;
uint256 constant ONE_BYTE_MASK = type(uint8).max;

uint256 constant FOUR_BYTES = 0x20;
uint256 constant FOUR_BYTE_MASK = type(uint32).max;

uint256 constant THIRTY_BYTES = 0xf0;
uint256 constant THIRTY_BYTE_MASK = type(uint240).max;

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IControllable} from "./IControllable.sol";

interface IAllowList is IControllable {
    event Allow(address caller);
    event Deny(address caller);

    /// @notice Check whether the given `caller` address is allowed.
    /// @param caller The caller address.
    /// @return True if caller is allowed, false if caller is denied.
    function allowed(address caller) external view returns (bool);

    /// @notice Check whether the given `caller` address is denied.
    /// @param caller The caller address.
    /// @return True if caller is denied, false if caller is allowed.
    function denied(address caller) external view returns (bool);

    /// @notice Add a caller address to the allowlist.
    /// @param caller The caller address.
    function allow(address caller) external;

    /// @notice Remove a caller address from the allowlist.
    /// @param caller The caller address.
    function deny(address caller) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IAnnotated {
    /// @notice Get contract name.
    /// @return Contract name.
    function NAME() external returns (string memory);

    /// @notice Get contract version.
    /// @return Contract version.
    function VERSION() external returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ICommonErrors {
    /// @notice The provided address is the zero address.
    error ZeroAddress();
    /// @notice The attempted action is not allowed.
    error Forbidden();
    /// @notice The requested entity cannot be found.
    error NotFound();
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ICommonErrors} from "./ICommonErrors.sol";

interface IControllable is ICommonErrors {
    /// @notice The dependency with the given `name` is invalid.
    error InvalidDependency(bytes32 name);

    /// @notice Get controller address.
    /// @return Controller address.
    function controller() external returns (address);

    /// @notice Set a named dependency to the given contract address.
    /// @param _name bytes32 name of the dependency to set.
    /// @param _contract address of the dependency.
    function setDependency(bytes32 _name, address _contract) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IAllowList} from "./IAllowList.sol";
import {IAnnotated} from "./IAnnotated.sol";

interface ICreatorAuth is IAllowList, IAnnotated {}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IControllable} from "./IControllable.sol";
import {IAnnotated} from "./IAnnotated.sol";
import {IMetadataResolver} from "./IMetadataResolver.sol";
import {RaiseParams} from "../structs/Raise.sol";
import {TierParams} from "../structs/Tier.sol";

interface ICreators is IControllable, IAnnotated {
    event SetCreatorAuth(address oldCreatorAuth, address newCreatorAuth);
    event SetMetadata(address oldMetadata, address newMetadata);
    event SetRaises(address oldRaises, address newRaises);
    event SetProjects(address oldProjects, address newProjects);

    /// @notice Create a new project. May only be called by approved creators.
    /// @return Created project ID.
    function createProject() external returns (uint32);

    /// @notice Transfer project ownership to new owner. The proposed owner must
    /// call `acceptOwnership` to complete the transfer. May only be called by
    /// current project owner.
    /// @param projectId uint32 project ID.
    /// @param newOwner address of proposed new owner.
    function transferOwnership(uint32 projectId, address newOwner) external;

    /// @notice Accept a proposed ownership transfer. May only be called by the
    /// proposed project owner address.
    /// @param projectId uint32 project ID.
    function acceptOwnership(uint32 projectId) external;

    /// @notice Create a new raise by project ID. May only be called by
    /// approved creators.
    /// @param projectId uint32 project ID.
    /// @param params RaiseParams raise configuration parameters struct.
    /// @param tiers TierParams[] array of tier configuration parameters structs.
    /// @return Created raise ID.
    function createRaise(uint32 projectId, RaiseParams memory params, TierParams[] memory tiers)
        external
        returns (uint32);

    /// @notice Update an existing raise by project ID and raise ID. May only be
    /// called by approved creators. May only be called while the raise's state is
    /// Active and phase is Scheduled.
    /// @param projectId uint32 project ID.
    /// @param raiseId uint32 raise ID.
    /// @param params RaiseParams raise configuration parameters struct.
    /// @param tiers TierParams[] array of tier configuration parameters structs.
    function updateRaise(uint32 projectId, uint32 raiseId, RaiseParams memory params, TierParams[] memory tiers)
        external;

    /// @notice Cancel a raise. May only be called by project owner. May only be
    /// called while raise state is Active. Sets state to Cancelled.
    /// @param projectId uint32 project ID.
    /// @param raiseId uint32 raise ID.
    function cancelRaise(uint32 projectId, uint32 raiseId) external;

    /// @notice Close a raise. May only be called by project owner. May only be
    /// called if raise state is Active and raise goal is met. Sets state to Funded.
    /// @param projectId uint32 project ID.
    /// @param raiseId uint32 raise ID.
    function closeRaise(uint32 projectId, uint32 raiseId) external;

    /// @notice Withdraw raise funds to given `receiver` address. May only be called
    /// by project owner. May only be called if raise state is Funded.
    /// @param projectId uint32 project ID.
    /// @param raiseId uint32 raise ID.
    /// @param receiver address send funds to this address.
    function withdrawRaiseFunds(uint32 projectId, uint32 raiseId, address receiver) external;

    /// @notice Set a custom metadata URI for the given token ID. May only be
    /// called by project owner
    /// @param tokenId uint256 token ID.
    /// @param customURI string metadata URI.
    function setCustomURI(uint256 tokenId, string memory customURI) external;

    /// @notice Set a custom metadata resolver contract for the given token ID.
    /// May only be called by project owner.
    /// @param tokenId uint256 token ID.
    /// @param customResolver IMetadataResolver address of a contract
    /// implementing IMetadataResolver interface.
    function setCustomResolver(uint256 tokenId, IMetadataResolver customResolver) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IControllable} from "./IControllable.sol";
import {IMetadataResolver} from "./IMetadataResolver.sol";
import {IAnnotated} from "./IAnnotated.sol";
import {ICommonErrors} from "./ICommonErrors.sol";
import {IPausable} from "./IPausable.sol";

interface IMetadata is IMetadataResolver, IPausable, IControllable, IAnnotated {
    event SetCustomURI(uint256 indexed tokenId, string customURI);
    event SetCustomResolver(uint256 indexed tokenId, IMetadataResolver customResolver);
    event SetCollectionOwner(address collection, address owner);
    event SetCreators(address oldCreators, address newCreators);
    event SetTokenURIBase(string oldBaseURI, string newBaseURI);
    event SetContractURIBase(string oldBaseURI, string newBaseURI);
    event SetDefaultCollectionOwner(address oldOwner, address newOwner);

    /// @notice Contract metadata URI for the given contract address.
    /// @param _contract address of contract.
    /// @return Metadata URI string.
    function contractURI(address _contract) external view returns (string memory);

    /// @notice Metadata URI for the given token ID.
    /// @param tokenId uint256 token ID.
    /// @return Metadata URI string.
    function uri(uint256 tokenId) external view returns (string memory);

    /// @notice Set a custom metadata URI for the given token ID. May only be
    /// called by `creators` contract.
    /// @param tokenId uint256 token ID.
    /// @param customURI string metadata URI.
    function setCustomURI(uint256 tokenId, string memory customURI) external;

    /// @notice Set a custom metadata resolver contract for the given token ID.
    /// May only be called by `creators` contract.
    /// @param tokenId uint256 token ID.
    /// @param customResolver IMetadataResolver address of a contract
    /// implementing IMetadataResolver interface.
    function setCustomResolver(uint256 tokenId, IMetadataResolver customResolver) external;

    /// @notice Set the token metadata base URI. Base URI will be concatenated
    /// with token ID and '.json' to produce a full metadata URI.
    /// May only be called by `controller` contract.
    /// @param _tokenURIBase Default URI string.
    function setTokenURIBase(string memory _tokenURIBase) external;

    /// @notice Set the contract metadata base URI. Base URI will be concatenated
    /// with contract address in hex and '.json' to produce a full metadata URI.
    /// May only be called by `controller` contract.
    /// @param _contractURIBase Default URI string.
    function setContractURIBase(string memory _contractURIBase) external;

    /// @notice Set the default collection owner. Emint1155 tokens will return
    /// this address as their owner by default. The owner address has no special
    /// permissions at the contract level, but may manage the collection on
    /// storefronts like OpenSea. May only be called by `controller` contract.
    /// @param _owner address of default owner.
    function setDefaultCollectionOwner(address _owner) external;

    /// @notice Set the collection owner for a specific collection by address.
    /// Used to override the default owner if necessary. May only be called by
    /// `controller` contract.
    /// @param collection address of token contract.
    /// @param _owner address of owner.
    function setCollectionOwner(address collection, address _owner) external;

    /// @notice Get the owner of a collection by address.
    /// @param collection address of token contract.
    /// @return address of owner.
    function owner(address collection) external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IMetadataResolver {
    /// @notice Metadata URI for the given token ID.
    /// @param tokenId uint256 token ID.
    /// @return Metadata URI string.
    function uri(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPausable {
    /// @notice Pause the contract.
    function pause() external;

    /// @notice Unpause the contract.
    function unpause() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IAnnotated} from "./IAnnotated.sol";
import {ICommonErrors} from "./ICommonErrors.sol";
import {IPausable} from "./IPausable.sol";
import {IAllowList} from "./IAllowList.sol";

interface IProjects is IAllowList, IPausable, IAnnotated {
    event CreateProject(uint32 id);
    event TransferOwnership(uint32 indexed projectId, address indexed owner, address indexed newOwner);
    event AcceptOwnership(uint32 indexed projectId, address indexed owner, address indexed newOwner);

    /// @notice Create a new project owned by the given `owner`.
    /// @param owner address of project owner.
    /// @return uint32 Project ID.
    function create(address owner) external returns (uint32);

    /// @notice Start transfer of `projectId` to `newOwner`. The new owner must
    /// accept the transfer in order to assume ownership of the project.
    /// @param projectId uint32 project ID.
    /// @param newOwner address of proposed new owner.
    function transferOwnership(uint32 projectId, address newOwner) external;

    /// @notice Transfer ownership of `projectId` to `pendingOwner`.
    /// @param projectId uint32 project ID.
    function acceptOwnership(uint32 projectId) external;

    /// @notice Get owner of project by ID.
    /// @param projectId uint32 project ID.
    /// @return address of project owner.
    function ownerOf(uint32 projectId) external view returns (address);

    /// @notice Get pending owner of project by ID.
    /// @param projectId uint32 project ID.
    /// @return address of pending project owner.
    function pendingOwnerOf(uint32 projectId) external view returns (address);

    /// @notice Check whether project exists by ID.
    /// @param projectId uint32 project ID.
    /// @return True if project exists, false if project does not exist.
    function exists(uint32 projectId) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IControllable} from "./IControllable.sol";
import {IAnnotated} from "./IAnnotated.sol";
import {IPausable} from "./IPausable.sol";
import {Raise, RaiseParams, RaiseState, Phase} from "../structs/Raise.sol";
import {Tier, TierParams} from "../structs/Tier.sol";

interface IRaises is IPausable, IControllable, IAnnotated {
    /// @notice Minting token would exceed the raise's configured maximum amount.
    error ExceedsRaiseMaximum();
    /// @notice The raise's goal has not been met.
    error RaiseGoalNotMet();
    /// @notice The given currency address is unknown, invalid, or denied.
    error InvalidCurrency();
    /// @notice The provided payment amount is incorrect.
    error InvalidPaymentAmount();
    /// @notice The provided Merkle proof is invalid.
    error InvalidProof();
    /// @notice This caller address has minted the maximum number of tokens allowed per address.
    error AddressMintedMaximum();
    /// @notice The raise is not in Cancelled state.
    error RaiseNotCancelled();
    /// @notice The raise is not in Funded state.
    error RaiseNotFunded();
    /// @notice The raise has ended.
    error RaiseEnded();
    /// @notice The raise is no longer in Active state.
    error RaiseInactive();
    /// @notice The raise has not yet ended.
    error RaiseNotEnded();
    /// @notice The raise has started and is no longer in Scheduled phase.
    error RaiseNotScheduled();
    /// @notice The raise has not yet started and is in the Scheduled phase.
    error RaiseNotStarted();
    /// @notice This token tier is sold out, or an attempt to mint would exceed the maximum supply.
    error RaiseSoldOut();
    /// @notice The caller's token balance is zero.
    error ZeroBalance();

    event CreateRaise(uint32 indexed projectId, uint32 raiseId, RaiseParams params, TierParams[] tiers, address fanToken, address brandToken);
    event UpdateRaise(uint32 indexed projectId, uint32 indexed raiseId, RaiseParams params, TierParams[] tiers);
    event Mint(
        uint32 indexed projectId,
        uint32 indexed raiseID,
        uint32 indexed tierId,
        address minter,
        uint256 amount,
        bytes32[] proof
    );
    event SettleRaise(uint32 indexed projectId, uint32 indexed raiseId, RaiseState newState);
    event CancelRaise(uint32 indexed projectId, uint32 indexed raiseId, RaiseState newState);
    event CloseRaise(uint32 indexed projectId, uint32 indexed raiseId, RaiseState newState);
    event WithdrawRaiseFunds(
        uint32 indexed projectId, uint32 indexed raiseId, address indexed receiver, address currency, uint256 amount
    );
    event Redeem(
        uint32 indexed projectId,
        uint32 indexed raiseID,
        uint32 indexed tierId,
        address receiver,
        uint256 tokenAmount,
        address owner,
        uint256 refundAmount
    );
    event WithdrawFees(address indexed receiver, address currency, uint256 amount);

    event SetCreators(address oldCreators, address newCreators);
    event SetProjects(address oldProjects, address newProjects);
    event SetMinter(address oldMinter, address newMinter);
    event SetDeployer(address oldDeployer, address newDeployer);
    event SetTokens(address oldTokens, address newTokens);
    event SetTokenAuth(address oldTokenAuth, address newTokenAuth);

    /// @notice Create a new raise by project ID. May only be called by
    /// approved creators.
    /// @param projectId uint32 project ID.
    /// @param params RaiseParams raise configuration parameters struct.
    /// @param _tiers TierParams[] array of tier configuration parameters structs.
    /// @return raiseId Created raise ID.
    function create(uint32 projectId, RaiseParams memory params, TierParams[] memory _tiers)
        external
        returns (uint32 raiseId);

    /// @notice Update a Scheduled raise by project ID and raise ID. May only be
    /// called while the raise's state is Active and phase is Scheduled.
    /// @param projectId uint32 project ID.
    /// @param raiseId uint32 raise ID.
    /// @param params RaiseParams raise configuration parameters struct.
    /// @param _tiers TierParams[] array of tier configuration parameters structs.
    function update(uint32 projectId, uint32 raiseId, RaiseParams memory params, TierParams[] memory _tiers) external;

    /// @notice Mint `amount` of tokens to caller for the given `projectId`,
    /// `raiseId`, and `tierId`. Caller must provide ETH or approve ERC20 amount
    /// equal to total cost.
    /// @param projectId uint32 project ID.
    /// @param raiseId uint32 raise ID.
    /// @param tierId uint32 tier ID.
    /// @param amount uint256 quantity of tokens to mint.
    /// @return tokenId uint256 Minted token ID.
    function mint(uint32 projectId, uint32 raiseId, uint32 tierId, uint256 amount)
        external
        payable
        returns (uint256 tokenId);

    /// @notice Mint `amount` of tokens to caller for the given `projectId`,
    /// `raiseId`, and `tierId`. Caller must provide a Merkle proof. Caller must
    /// provide ETH or approve ERC20 amount equal to total cost.
    /// @param projectId uint32 project ID.
    /// @param raiseId uint32 raise ID.
    /// @param tierId uint32 tier ID.
    /// @param amount uint256 quantity of tokens to mint.
    /// @param proof bytes32[] Merkle proof of inclusion on tier allowlist.
    /// @return tokenId uint256 Minted token ID.
    function mint(uint32 projectId, uint32 raiseId, uint32 tierId, uint256 amount, bytes32[] memory proof)
        external
        payable
        returns (uint256 tokenId);

    /// @notice Settle a raise in the Active state and Ended phase. Sets raise
    /// state to Funded if the goal has been met. Sets raise state to Cancelled
    /// if the goal has not been met.
    /// @param projectId uint32 project ID.
    /// @param raiseId uint32 raise ID.
    function settle(uint32 projectId, uint32 raiseId) external;

    /// @notice Cancel a raise, setting its state to Cancelled. May only be
    /// called by `creators` contract. May only be called while raise state is Active.
    /// @param projectId uint32 project ID.
    /// @param raiseId uint32 raise ID.
    function cancel(uint32 projectId, uint32 raiseId) external;

    /// @notice Close a raise. May only be called by `creators` contract. May
    /// only be called if raise state is Active and raise goal is met. Sets
    /// state to Funded.
    /// @param projectId uint32 project ID.
    /// @param raiseId uint32 raise ID.
    function close(uint32 projectId, uint32 raiseId) external;

    /// @notice Withdraw raise funds to given `receiver` address. May only be
    /// called by `creators` contract. May only be called if raise state is Funded.
    /// @param projectId uint32 project ID.
    /// @param raiseId uint32 raise ID.
    /// @param receiver address send funds to this address.
    function withdraw(uint32 projectId, uint32 raiseId, address receiver) external;

    /// @notice Redeem `amount` of tokens from caller for the given `projectId`,
    /// `raiseId`, and `tierId` and return ETH or ERC20 tokens to caller. May
    /// only be called when raise state is Cancelled.
    /// @param projectId uint32 project ID.
    /// @param raiseId uint32 raise ID.
    /// @param tierId uint32 tier ID.
    /// @param amount uint256 quantity of tokens to redeem.
    function redeem(uint32 projectId, uint32 raiseId, uint32 tierId, uint256 amount) external;

    /// @notice Withdraw accrued protocol fees for given `currency` to given
    /// `receiver` address. May only be called by `controller` contract.
    /// @param currency address ERC20 token address or special sentinel value for ETH.
    /// @param receiver address send funds to this address.
    function withdrawFees(address currency, address receiver) external;

    /// @notice Get a raise by project ID and raise ID.
    /// @param projectId uint32 project ID.
    /// @param raiseId uint32 raise ID.
    /// @return Raise struct.
    function getRaise(uint32 projectId, uint32 raiseId) external view returns (Raise memory);

    /// @notice Get a raise's current Phase by project ID and raise ID.
    /// @param projectId uint32 project ID.
    /// @param raiseId uint32 raise ID.
    /// @return Phase enum member.
    function getPhase(uint32 projectId, uint32 raiseId) external view returns (Phase);

    /// @notice Get all tiers for a given raise by project ID and raise ID.
    /// @param projectId uint32 project ID.
    /// @param raiseId uint32 raise ID.
    /// @return Array of Tier structs.
    function getTiers(uint32 projectId, uint32 raiseId) external view returns (Tier[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {TokenCodec} from "./codecs/TokenCodec.sol";
import {RaiseCodec} from "./codecs/RaiseCodec.sol";
import {TokenData, TokenType} from "../structs/TokenData.sol";
import {RaiseData, TierType} from "../structs/RaiseData.sol";

//   |------------ Token data is encoded in 32 bytes ---------------|
// 0x0000000000000000000000000000000000000000000000000000000000000000
//   1 byte token type                                             tt
//   1 byte encoding version                                     vv
//   |------- Raise token data is encoded in 30 bytes ----------|
//   4 byte project ID                                   pppppppp
//   4 byte raise ID                             rrrrrrrr
//   4 byte tier ID                      tttttttt
//   1 byte tier type                  TT
//   |------- 17 empty bytes --------|

/// @title RaiseToken - Raise token encoder/decoder
/// @notice Converts numeric token IDs to TokenData/RaiseData structs.
library RaiseToken {
    function encode(TierType _tierType, uint32 _projectId, uint32 _raiseId, uint32 _tierId)
        internal
        pure
        returns (uint256)
    {
        RaiseData memory raiseData =
            RaiseData({tierType: _tierType, projectId: _projectId, raiseId: _raiseId, tierId: _tierId});
        TokenData memory tokenData =
            TokenData({tokenType: TokenType.Raise, encodingVersion: 0, data: RaiseCodec.encode(raiseData)});
        return TokenCodec.encode(tokenData);
    }

    function decode(uint256 tokenId) internal pure returns (TokenData memory, RaiseData memory) {
        TokenData memory token = TokenCodec.decode(tokenId);
        RaiseData memory raise = RaiseCodec.decode(token.data);
        return (token, raise);
    }

    function projectId(uint256 tokenId) internal pure returns (uint32) {
        (, RaiseData memory raise) = decode(tokenId);
        return raise.projectId;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {RaiseData, TierType} from "../../structs/RaiseData.sol";
import {ONE_BYTE, ONE_BYTE_MASK, FOUR_BYTES, FOUR_BYTE_MASK} from "../../constants/Codecs.sol";

// |-------- Raise token data is encoded in 30 bytes -----------|
// 0x000000000000000000000000000000000000000000000000000000000000
// 4 byte project ID                                     pppppppp
// 4 byte raise ID                               rrrrrrrr
// 4 byte tier ID                        tttttttt
// 1 byte tier type                    TT
//   ----------------------------------  17 empty bytes reserved

uint240 constant PROJECT_ID_SIZE = uint240(FOUR_BYTES);
uint240 constant RAISE_ID_SIZE = uint240(FOUR_BYTES);
uint240 constant TIER_ID_SIZE = uint240(FOUR_BYTES);
uint240 constant TIER_TYPE_SIZE = uint240(ONE_BYTE);

uint240 constant RAISE_ID_OFFSET = PROJECT_ID_SIZE;
uint240 constant TIER_ID_OFFSET = RAISE_ID_OFFSET + RAISE_ID_SIZE;
uint240 constant TIER_TYPE_OFFSET = TIER_ID_OFFSET + TIER_ID_SIZE;

uint240 constant PROJECT_ID_MASK = uint240(FOUR_BYTE_MASK);
uint240 constant RAISE_ID_MASK = uint240(FOUR_BYTE_MASK) << RAISE_ID_OFFSET;
uint240 constant TIER_ID_MASK = uint240(FOUR_BYTE_MASK) << TIER_ID_OFFSET;
uint240 constant TIER_TYPE_MASK = uint240(ONE_BYTE_MASK) << TIER_TYPE_OFFSET;

bytes17 constant RESERVED_REGION = 0x0;

/// @title RaiseCodec - Raise token encoder/decoder
/// @notice Converts between token data bytes and RaiseData struct.
library RaiseCodec {
    function encode(RaiseData memory raise) internal pure returns (bytes30) {
        bytes memory encoded =
            abi.encodePacked(RESERVED_REGION, raise.tierType, raise.tierId, raise.raiseId, raise.projectId);
        return bytes30(encoded);
    }

    function decode(bytes30 tokenData) internal pure returns (RaiseData memory) {
        uint240 bits = uint240(tokenData);

        uint32 projectId = uint32(bits & PROJECT_ID_MASK);
        uint32 raiseId = uint32((bits & RAISE_ID_MASK) >> RAISE_ID_OFFSET);
        uint32 tierId = uint32((bits & TIER_ID_MASK) >> TIER_ID_OFFSET);
        TierType tierType = TierType((bits & TIER_TYPE_MASK) >> TIER_TYPE_OFFSET);

        return RaiseData({tierType: tierType, tierId: tierId, raiseId: raiseId, projectId: projectId});
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {TokenData, TokenType} from "../../structs/TokenData.sol";
import {ONE_BYTE, ONE_BYTE_MASK, THIRTY_BYTE_MASK} from "../../constants/Codecs.sol";

//   |------------ Token data is encoded in 32 bytes ---------------|
// 0x0000000000000000000000000000000000000000000000000000000000000000
//   1 byte token type                                             tt
//   1 byte encoding version                                     vv
//   |------------------ 30 byte data region -------------------|

uint256 constant TOKEN_TYPE_SIZE = ONE_BYTE;
uint256 constant ENCODING_SIZE = ONE_BYTE;

uint256 constant ENCODING_OFFSET = TOKEN_TYPE_SIZE;
uint256 constant DATA_OFFSET = ENCODING_OFFSET + ENCODING_SIZE;

uint256 constant TOKEN_TYPE_MASK = ONE_BYTE_MASK;
uint256 constant ENCODING_VERSION_MASK = ONE_BYTE_MASK << ENCODING_OFFSET;
uint256 constant DATA_REGION_MASK = THIRTY_BYTE_MASK << DATA_OFFSET;

/// @title RaiseCodec - Token encoder/decoder
/// @notice Converts between token ID and TokenData struct.
library TokenCodec {
    function encode(TokenData memory token) internal pure returns (uint256) {
        bytes memory encoded = abi.encodePacked(token.data, token.encodingVersion, token.tokenType);
        return uint256(bytes32(encoded));
    }

    function decode(uint256 tokenId) internal pure returns (TokenData memory) {
        TokenType tokenType = TokenType(tokenId & TOKEN_TYPE_MASK);
        uint8 encodingVersion = uint8((tokenId & ENCODING_VERSION_MASK) >> ENCODING_OFFSET);
        bytes30 data = bytes30(uint240((tokenId & DATA_REGION_MASK) >> DATA_OFFSET));

        return TokenData({tokenType: tokenType, encodingVersion: encodingVersion, data: data});
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Tier} from "./Tier.sol";

/// @param goal Target amount to raise. If a raise meets its goal amount, the
/// raise settles as Funded, users keep their tokens, and the owner may withdraw
/// the collected funds. If a raise fails to meet its goual the raise settles as
/// Cancelled and users may redeem their tokens for a refund.
/// @param max Maximum amount to raise.
/// @param presaleStart Start timestamp of the presale phase. During this phase,
/// allowlisted users may mint tokens by providing a Merkle proof.
/// @param presaleEnd End timestamp of the presale phase.
/// @param publicSaleStart Start timestamp of the public sale phase. During this
/// phase, any user may mint a token.
/// @param publicSaleEnd End timestamp of the public sale phase.
/// @param currency Currency for this raise, either an ERC20 token address, or
/// the "dolphin address" for ETH. ERC20 tokens must be allowed by TokenAuth.
struct RaiseParams {
    uint256 goal;
    uint256 max;
    uint64 presaleStart;
    uint64 presaleEnd;
    uint64 publicSaleStart;
    uint64 publicSaleEnd;
    address currency;
}

/// @notice A raise may be in one of three states, depending on whether it has
/// ended and has or has not met its goal:
/// - An Active raise has not yet ended.
/// - A Funded raise has ended and met its goal.
/// - A Cancelled raise has ended and did not meet its goal.
enum RaiseState {
    Active,
    Funded,
    Cancelled
}

/// @param goal Target amount to raise. If a raise meets its goal amount, the
/// raise settles as Funded, users keep their tokens, and the owner may withdraw
/// the collected funds. If a raise fails to meet its goual the raise settles as
/// Cancelled and users may redeem their tokens for a refund.
/// @param max Maximum amount to raise.
/// @param presaleStart Start timestamp of the presale phase. During this phase,
/// allowlisted users may mint tokens by providing a Merkle proof.
/// @param presaleEnd End timestamp of the presale phase.
/// @param publicSaleStart Start timestamp of the public sale phase. During this
/// phase, any user may mint a token.
/// @param publicSaleEnd End timestamp of the public sale phase.
/// @param currency Currency for this raise, either an ERC20 token address, or
/// the "dolphin address" for ETH. ERC20 tokens must be allowed by TokenAuth.
/// @param state State of the raise. All new raises begin in Active state.
/// @param projectId Integer ID of the project associated with this raise.
/// @param raiseId Integer ID of this raise.
/// @param fanToken Address of this raise's ERC1155 fan token.
/// @param brandToken Address of this raise's ERC1155 brand token.
/// @param raised Total amount of ETH or ERC20 token contributed to this raise.
/// @param balance Creator's share of the total amount raised.
/// @param fees Protocol fees from this raise. raised = balance + fees
struct Raise {
    uint256 goal;
    uint256 max;
    uint64 presaleStart;
    uint64 presaleEnd;
    uint64 publicSaleStart;
    uint64 publicSaleEnd;
    address currency;
    RaiseState state;
    uint32 projectId;
    uint32 raiseId;
    RaiseTokens tokens;
    uint256 raised;
    uint256 balance;
    uint256 fees;
}

struct RaiseTokens {
    address fanToken;
    address brandToken;
}

/// @notice A raise may be in one of four phases, depending on the timestamps of
/// its presale and public sale phases:
/// - A Scheduled raise is not open for minting. If a raise is Scheduled, it is
/// currently either before the Presale phase or between Presale and PublicSale.
/// - The Presale phase is between the presale start and presale end timestamps.
/// - The PublicSale phase is between the public sale start and public sale end
/// timestamps. PublicSale must be after Presale, but the raise may return to
/// the Scheduled phase in between.
/// - After the public sale end timestamp, the raise has Ended.
enum Phase {
    Scheduled,
    Presale,
    PublicSale,
    Ended
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {TierType} from "./Tier.sol";

/// @param projectId Integer ID of the project associated with this raise token.
/// @param raiseId Integer ID of the raise associated with this raise token.
/// @param tierId Integer ID of the tier associated with this raise token.
/// @param tierType Enum indicating whether this is a "fan" or "brand" token.
struct RaiseData {
    uint32 projectId;
    uint32 raiseId;
    uint32 tierId;
    TierType tierType;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @notice Enum indicating whether a token is a "fan" or "brand" token. Fan
/// tokens are intended for purchase by project patrons and have a lower protocol
/// fee and royalties than brand tokens.
enum TierType {
    Fan,
    Brand
}

/// @param tierType Whether this tier is a "fan" or "brand" token.
/// @param supply Maximum token supply in this tier.
/// @param price Price per token.
/// @param limitPerAddress Maximum number of tokens that may be minted by address.
/// @param allowListRoot Merkle root of an allowlist for the presale phase.
struct TierParams {
    TierType tierType;
    uint256 supply;
    uint256 price;
    uint256 limitPerAddress;
    bytes32 allowListRoot;
}

/// @param tierType Whether this tier is a "fan" or "brand" token.
/// @param supply Maximum token supply in this tier.
/// @param price Price per token.
/// @param limitPerAddress Maximum number of tokens that may be minted by address.
/// @param allowListRoot Merkle root of an allowlist for the presale phase.
/// @param minted Total number of tokens minted in this tier.
struct Tier {
    TierType tierType;
    uint256 supply;
    uint256 price;
    uint256 limitPerAddress;
    bytes32 allowListRoot;
    uint256 minted;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @notice Enum representing token types. The V1 protocol supports only one
/// token type, "Raise," which represents a crowdfund contribution. However,
/// new token types may be added in the future.
enum TokenType {Raise}

/// @param data 30-byte data region containing encoded token data. The specific
/// format of this data depends on encoding version and token type.
/// @param encodingVersion Encoding version of this token.
/// @param tokenType Enum indicating type of this token. (e.g. Raise)
struct TokenData {
    bytes30 data;
    uint8 encodingVersion;
    TokenType tokenType;
}