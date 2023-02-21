// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "prb-math/contracts/PRBMath.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import '@openzeppelin/contracts/utils/math/SafeCast.sol';
import '@paulrberg/contracts/math/PRBMath.sol';
import './abstract/JBOperatable.sol';
import './interfaces/IJBController3_1.sol';
import './interfaces/IJBMigratable.sol';
import './interfaces/IJBOperatorStore.sol';
import './interfaces/IJBPaymentTerminal.sol';
import './interfaces/IJBProjects.sol';
import './libraries/JBConstants.sol';
import './libraries/JBFundingCycleMetadataResolver.sol';
import './libraries/JBOperations.sol';
import './libraries/JBSplitsGroups.sol';

/**
  @notice
  Stitches together funding cycles and project tokens, making sure all activity is accounted for and correct.

  @dev
  Adheres to -
  IJBController3_1: General interface for the generic controller methods in this contract that interacts with funding cycles and tokens according to the protocol's rules.
  IJBMigratable: Allows migrating to this contract, with a hook called to prepare for the migration.

  @dev
  Inherits from -
  JBOperatable: Several functions in this contract can only be accessed by a project owner, or an address that has been preconfifigured to be an operator of the project.
  ERC165: Introspection on interface adherance. 

  @dev
  This Controller has the same functionality as JBController3_1, except it is not backwards compatible with the original IJBController view methods.
*/
contract JBController3_1 is JBOperatable, ERC165, IJBController3_1, IJBMigratable {
  // A library that parses the packed funding cycle metadata into a more friendly format.
  using JBFundingCycleMetadataResolver for JBFundingCycle;

  //*********************************************************************//
  // --------------------------- custom errors ------------------------- //
  //*********************************************************************//

  error BURN_PAUSED_AND_SENDER_NOT_VALID_TERMINAL_DELEGATE();
  error CANT_MIGRATE_TO_CURRENT_CONTROLLER();
  error FUNDING_CYCLE_ALREADY_LAUNCHED();
  error INVALID_BALLOT_REDEMPTION_RATE();
  error INVALID_REDEMPTION_RATE();
  error INVALID_RESERVED_RATE();
  error MIGRATION_NOT_ALLOWED();
  error MINT_NOT_ALLOWED_AND_NOT_TERMINAL_DELEGATE();
  error NO_BURNABLE_TOKENS();
  error NOT_CURRENT_CONTROLLER();
  error OVERFLOW_ALERT();
  error ZERO_TOKENS_TO_MINT();

  //*********************************************************************//
  // --------------------- internal stored properties ------------------ //
  //*********************************************************************//

  /**
    @notice
    Data regarding the distribution limit of a project during a configuration.

    @dev
    bits 0-231: The amount of token that a project can distribute per funding cycle.

    @dev
    bits 232-255: The currency of amount that a project can distribute.

    _projectId The ID of the project to get the packed distribution limit data of.
    _configuration The configuration during which the packed distribution limit data applies.
    _terminal The terminal from which distributions are being limited.
    _token The token for which distributions are being limited.
  */
  mapping(uint256 => mapping(uint256 => mapping(IJBPaymentTerminal => mapping(address => uint256))))
    internal _packedDistributionLimitDataOf;

  /**
    @notice
    Data regarding the overflow allowance of a project during a configuration.

    @dev
    bits 0-231: The amount of overflow that a project is allowed to tap into on-demand throughout the configuration.

    @dev
    bits 232-255: The currency of the amount of overflow that a project is allowed to tap.

    _projectId The ID of the project to get the packed overflow allowance data of.
    _configuration The configuration during which the packed overflow allowance data applies.
    _terminal The terminal managing the overflow.
    _token The token for which overflow is being allowed.
  */
  mapping(uint256 => mapping(uint256 => mapping(IJBPaymentTerminal => mapping(address => uint256))))
    internal _packedOverflowAllowanceDataOf;

  //*********************************************************************//
  // --------------- public immutable stored properties ---------------- //
  //*********************************************************************//

  /**
    @notice
    Mints ERC-721's that represent project ownership.
  */
  IJBProjects public immutable override projects;

  /**
    @notice
    The contract storing all funding cycle configurations.
  */
  IJBFundingCycleStore public immutable override fundingCycleStore;

  /**
    @notice
    The contract that manages token minting and burning.
  */
  IJBTokenStore public immutable override tokenStore;

  /**
    @notice
    The contract that stores splits for each project.
  */
  IJBSplitsStore public immutable override splitsStore;

  /** 
    @notice
    A contract that stores fund access constraints for each project. 
  */
  IJBFundAccessConstraintsStore public immutable override fundAccessConstraintsStore;

  /**
    @notice
    The directory of terminals and controllers for projects.
  */
  IJBDirectory public immutable override directory;

  //*********************************************************************//
  // --------------------- public stored properties -------------------- //
  //*********************************************************************//

  /**
    @notice
    The current undistributed reserved token balance of.

    _projectId The ID of the project to get a reserved token balance of.
  */
  mapping(uint256 => uint256) public override reservedTokenBalanceOf;

  //*********************************************************************//
  // ------------------------- external views -------------------------- //
  //*********************************************************************//

  /** 
    @notice
    A project's funding cycle for the specified configuration along with its metadata.

    @param _projectId The ID of the project to which the funding cycle belongs.
  
    @return fundingCycle The funding cycle.
    @return metadata The funding cycle's metadata.
  */
  function getFundingCycleOf(uint256 _projectId, uint256 _configuration)
    external
    view
    override
    returns (JBFundingCycle memory fundingCycle, JBFundingCycleMetadata memory metadata)
  {
    fundingCycle = fundingCycleStore.get(_projectId, _configuration);
    metadata = fundingCycle.expandMetadata();
  }

  /** 
    @notice
    A project's latest configured funding cycle along with its metadata and the ballot state of the configuration.

    @param _projectId The ID of the project to which the funding cycle belongs.
  
    @return fundingCycle The latest configured funding cycle.
    @return metadata The latest configured funding cycle's metadata.
    @return ballotState The state of the configuration.
  */
  function latestConfiguredFundingCycleOf(uint256 _projectId)
    external
    view
    override
    returns (
      JBFundingCycle memory fundingCycle,
      JBFundingCycleMetadata memory metadata,
      JBBallotState ballotState
    )
  {
    (fundingCycle, ballotState) = fundingCycleStore.latestConfiguredOf(_projectId);
    metadata = fundingCycle.expandMetadata();
  }

  /** 
    @notice
    A project's current funding cycle along with its metadata.

    @param _projectId The ID of the project to which the funding cycle belongs.
  
    @return fundingCycle The current funding cycle.
    @return metadata The current funding cycle's metadata.
  */
  function currentFundingCycleOf(uint256 _projectId)
    external
    view
    override
    returns (JBFundingCycle memory fundingCycle, JBFundingCycleMetadata memory metadata)
  {
    fundingCycle = fundingCycleStore.currentOf(_projectId);
    metadata = fundingCycle.expandMetadata();
  }

  /** 
    @notice
    A project's queued funding cycle along with its metadata.

    @param _projectId The ID of the project to which the funding cycle belongs.
  
    @return fundingCycle The queued funding cycle.
    @return metadata The queued funding cycle's metadata.
  */
  function queuedFundingCycleOf(uint256 _projectId)
    external
    view
    override
    returns (JBFundingCycle memory fundingCycle, JBFundingCycleMetadata memory metadata)
  {
    fundingCycle = fundingCycleStore.queuedOf(_projectId);
    metadata = fundingCycle.expandMetadata();
  }

  //*********************************************************************//
  // -------------------------- public views --------------------------- //
  //*********************************************************************//

  /**
    @notice
    Gets the current total amount of outstanding tokens for a project.

    @param _projectId The ID of the project to get total outstanding tokens of.

    @return The current total amount of outstanding tokens for the project.
  */
  function totalOutstandingTokensOf(uint256 _projectId) public view override returns (uint256) {
    // Add the reserved tokens to the total supply.
    return tokenStore.totalSupplyOf(_projectId) + reservedTokenBalanceOf[_projectId];
  }

  /**
    @notice
    Indicates if this contract adheres to the specified interface.

    @dev 
    See {IERC165-supportsInterface}.

    @param _interfaceId The ID of the interface to check for adherance to.
  */
  function supportsInterface(bytes4 _interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165)
    returns (bool)
  {
    return
      _interfaceId == type(IJBController3_1).interfaceId ||
      _interfaceId == type(IJBController3_0_1).interfaceId ||
      _interfaceId == type(IJBMigratable).interfaceId ||
      _interfaceId == type(IJBOperatable).interfaceId ||
      super.supportsInterface(_interfaceId);
  }

  //*********************************************************************//
  // ---------------------------- constructor -------------------------- //
  //*********************************************************************//

  /**
    @param _operatorStore A contract storing operator assignments.
    @param _projects A contract which mints ERC-721's that represent project ownership and transfers.
    @param _directory A contract storing directories of terminals and controllers for each project.
    @param _fundingCycleStore A contract storing all funding cycle configurations.
    @param _tokenStore A contract that manages token minting and burning.
    @param _splitsStore A contract that stores splits for each project.
    @param _fundAccessConstraintsStore A contract that stores fund access constraints for each project.
  */
  constructor(
    IJBOperatorStore _operatorStore,
    IJBProjects _projects,
    IJBDirectory _directory,
    IJBFundingCycleStore _fundingCycleStore,
    IJBTokenStore _tokenStore,
    IJBSplitsStore _splitsStore,
    IJBFundAccessConstraintsStore _fundAccessConstraintsStore
  ) JBOperatable(_operatorStore) {
    projects = _projects;
    directory = _directory;
    fundingCycleStore = _fundingCycleStore;
    tokenStore = _tokenStore;
    splitsStore = _splitsStore;
    fundAccessConstraintsStore = _fundAccessConstraintsStore;
  }

  //*********************************************************************//
  // --------------------- external transactions ----------------------- //
  //*********************************************************************//

  /**
    @notice
    Creates a project. This will mint an ERC-721 into the specified owner's account, configure a first funding cycle, and set up any splits.

    @dev
    Each operation within this transaction can be done in sequence separately.

    @dev
    Anyone can deploy a project on an owner's behalf.

    @param _owner The address to set as the owner of the project. The project ERC-721 will be owned by this address.
    @param _projectMetadata Metadata to associate with the project within a particular domain. This can be updated any time by the owner of the project.
    @param _data Data that defines the project's first funding cycle. These properties will remain fixed for the duration of the funding cycle.
    @param _metadata Metadata specifying the controller specific params that a funding cycle can have. These properties will remain fixed for the duration of the funding cycle.
    @param _mustStartAtOrAfter The time before which the configured funding cycle cannot start.
    @param _groupedSplits An array of splits to set for any number of groups. 
    @param _fundAccessConstraints An array containing amounts that a project can use from its treasury for each payment terminal. Amounts are fixed point numbers using the same number of decimals as the accompanying terminal. The `_distributionLimit` and `_overflowAllowance` parameters must fit in a `uint232`.
    @param _terminals Payment terminals to add for the project.
    @param _memo A memo to pass along to the emitted event.

    @return projectId The ID of the project.
  */
  function launchProjectFor(
    address _owner,
    JBProjectMetadata calldata _projectMetadata,
    JBFundingCycleData calldata _data,
    JBFundingCycleMetadata calldata _metadata,
    uint256 _mustStartAtOrAfter,
    JBGroupedSplits[] calldata _groupedSplits,
    JBFundAccessConstraints[] calldata _fundAccessConstraints,
    IJBPaymentTerminal[] memory _terminals,
    string memory _memo
  ) external virtual override returns (uint256 projectId) {
    // Keep a reference to the directory.
    IJBDirectory _directory = directory;

    // Mint the project into the wallet of the owner.
    projectId = projects.createFor(_owner, _projectMetadata);

    // Set this contract as the project's controller in the directory.
    _directory.setControllerOf(projectId, address(this));

    // Configure the first funding cycle.
    uint256 _configuration = _configure(
      projectId,
      _data,
      _metadata,
      _mustStartAtOrAfter,
      _groupedSplits,
      _fundAccessConstraints
    );

    // Add the provided terminals to the list of terminals.
    if (_terminals.length > 0) _directory.setTerminalsOf(projectId, _terminals);

    emit LaunchProject(_configuration, projectId, _memo, msg.sender);
  }

  /**
    @notice
    Creates a funding cycle for an already existing project ERC-721.

    @dev
    Each operation within this transaction can be done in sequence separately.

    @dev
    Only a project owner or operator can launch its funding cycles.

    @param _projectId The ID of the project to launch funding cycles for.
    @param _data Data that defines the project's first funding cycle. These properties will remain fixed for the duration of the funding cycle.
    @param _metadata Metadata specifying the controller specific params that a funding cycle can have. These properties will remain fixed for the duration of the funding cycle.
    @param _mustStartAtOrAfter The time before which the configured funding cycle cannot start.
    @param _groupedSplits An array of splits to set for any number of groups. 
    @param _fundAccessConstraints An array containing amounts that a project can use from its treasury for each payment terminal. Amounts are fixed point numbers using the same number of decimals as the accompanying terminal. The `_distributionLimit` and `_overflowAllowance` parameters must fit in a `uint232`.
    @param _terminals Payment terminals to add for the project.
    @param _memo A memo to pass along to the emitted event.

    @return configuration The configuration of the funding cycle that was successfully created.
  */
  function launchFundingCyclesFor(
    uint256 _projectId,
    JBFundingCycleData calldata _data,
    JBFundingCycleMetadata calldata _metadata,
    uint256 _mustStartAtOrAfter,
    JBGroupedSplits[] calldata _groupedSplits,
    JBFundAccessConstraints[] memory _fundAccessConstraints,
    IJBPaymentTerminal[] memory _terminals,
    string memory _memo
  )
    external
    virtual
    override
    requirePermission(projects.ownerOf(_projectId), _projectId, JBOperations.RECONFIGURE)
    returns (uint256 configuration)
  {
    // If there is a previous configuration, reconfigureFundingCyclesOf should be called instead
    if (fundingCycleStore.latestConfigurationOf(_projectId) > 0)
      revert FUNDING_CYCLE_ALREADY_LAUNCHED();

    // Set this contract as the project's controller in the directory.
    directory.setControllerOf(_projectId, address(this));

    // Configure the first funding cycle.
    configuration = _configure(
      _projectId,
      _data,
      _metadata,
      _mustStartAtOrAfter,
      _groupedSplits,
      _fundAccessConstraints
    );

    // Add the provided terminals to the list of terminals.
    if (_terminals.length > 0) directory.setTerminalsOf(_projectId, _terminals);

    emit LaunchFundingCycles(configuration, _projectId, _memo, msg.sender);
  }

  /**
    @notice
    Proposes a configuration of a subsequent funding cycle that will take effect once the current one expires if it is approved by the current funding cycle's ballot.

    @dev
    Only a project's owner or a designated operator can configure its funding cycles.

    @param _projectId The ID of the project whose funding cycles are being reconfigured.
    @param _data Data that defines the funding cycle. These properties will remain fixed for the duration of the funding cycle.
    @param _metadata Metadata specifying the controller specific params that a funding cycle can have. These properties will remain fixed for the duration of the funding cycle.
    @param _mustStartAtOrAfter The time before which the configured funding cycle cannot start.
    @param _groupedSplits An array of splits to set for any number of groups. 
    @param _fundAccessConstraints An array containing amounts that a project can use from its treasury for each payment terminal. Amounts are fixed point numbers using the same number of decimals as the accompanying terminal. The `_distributionLimit` and `_overflowAllowance` parameters must fit in a `uint232`.
    @param _memo A memo to pass along to the emitted event.

    @return configuration The configuration of the funding cycle that was successfully reconfigured.
  */
  function reconfigureFundingCyclesOf(
    uint256 _projectId,
    JBFundingCycleData calldata _data,
    JBFundingCycleMetadata calldata _metadata,
    uint256 _mustStartAtOrAfter,
    JBGroupedSplits[] calldata _groupedSplits,
    JBFundAccessConstraints[] calldata _fundAccessConstraints,
    string calldata _memo
  )
    external
    virtual
    override
    requirePermission(projects.ownerOf(_projectId), _projectId, JBOperations.RECONFIGURE)
    returns (uint256 configuration)
  {
    // Configure the next funding cycle.
    configuration = _configure(
      _projectId,
      _data,
      _metadata,
      _mustStartAtOrAfter,
      _groupedSplits,
      _fundAccessConstraints
    );

    emit ReconfigureFundingCycles(configuration, _projectId, _memo, msg.sender);
  }

  /**
    @notice
    Mint new token supply into an account, and optionally reserve a supply to be distributed according to the project's current funding cycle configuration.

    @dev
    Only a project's owner, a designated operator, one of its terminals, or the current data source can mint its tokens.

    @param _projectId The ID of the project to which the tokens being minted belong.
    @param _tokenCount The amount of tokens to mint in total, counting however many should be reserved.
    @param _beneficiary The account that the tokens are being minted for.
    @param _memo A memo to pass along to the emitted event.
    @param _preferClaimedTokens A flag indicating whether a project's attached token contract should be minted if they have been issued.
    @param _useReservedRate Whether to use the current funding cycle's reserved rate in the mint calculation.

    @return beneficiaryTokenCount The amount of tokens minted for the beneficiary.
  */
  function mintTokensOf(
    uint256 _projectId,
    uint256 _tokenCount,
    address _beneficiary,
    string calldata _memo,
    bool _preferClaimedTokens,
    bool _useReservedRate
  ) external virtual override returns (uint256 beneficiaryTokenCount) {
    // There should be tokens to mint.
    if (_tokenCount == 0) revert ZERO_TOKENS_TO_MINT();

    // Define variables that will be needed outside scoped section below.
    // Keep a reference to the reserved rate to use
    uint256 _reservedRate;

    // Scoped section prevents stack too deep. `_fundingCycle` only used within scope.
    {
      // Get a reference to the project's current funding cycle.
      JBFundingCycle memory _fundingCycle = fundingCycleStore.currentOf(_projectId);

      // Minting limited to: project owner, authorized callers, project terminal and current funding cycle data source
      _requirePermissionAllowingOverride(
        projects.ownerOf(_projectId),
        _projectId,
        JBOperations.MINT,
        directory.isTerminalOf(_projectId, IJBPaymentTerminal(msg.sender)) ||
          msg.sender == address(_fundingCycle.dataSource())
      );

      // If the message sender is not a terminal or a datasource, the current funding cycle must allow minting.
      if (
        !_fundingCycle.mintingAllowed() &&
        !directory.isTerminalOf(_projectId, IJBPaymentTerminal(msg.sender)) &&
        msg.sender != address(_fundingCycle.dataSource())
      ) revert MINT_NOT_ALLOWED_AND_NOT_TERMINAL_DELEGATE();

      // Determine the reserved rate to use.
      _reservedRate = _useReservedRate ? _fundingCycle.reservedRate() : 0;

      // Override the claimed token preference with the funding cycle value.
      _preferClaimedTokens = _preferClaimedTokens == true
        ? _preferClaimedTokens
        : _fundingCycle.preferClaimedTokenOverride();
    }

    if (_reservedRate != JBConstants.MAX_RESERVED_RATE) {
      // The unreserved token count that will be minted for the beneficiary.
      beneficiaryTokenCount = PRBMath.mulDiv(
        _tokenCount,
        JBConstants.MAX_RESERVED_RATE - _reservedRate,
        JBConstants.MAX_RESERVED_RATE
      );

      // Mint the tokens.
      tokenStore.mintFor(_beneficiary, _projectId, beneficiaryTokenCount, _preferClaimedTokens);
    }

    // Add reserved tokens if needed
    if (_reservedRate > 0)
      reservedTokenBalanceOf[_projectId] += _tokenCount - beneficiaryTokenCount;

    emit MintTokens(
      _beneficiary,
      _projectId,
      _tokenCount,
      beneficiaryTokenCount,
      _memo,
      _reservedRate,
      msg.sender
    );
  }

  /**
    @notice
    Burns a token holder's supply.

    @dev
    Only a token's holder, a designated operator, or a project's terminal can burn it.

    @param _holder The account that is having its tokens burned.
    @param _projectId The ID of the project to which the tokens being burned belong.
    @param _tokenCount The number of tokens to burn.
    @param _memo A memo to pass along to the emitted event.
    @param _preferClaimedTokens A flag indicating whether a project's attached token contract should be burned first if they have been issued.
  */
  function burnTokensOf(
    address _holder,
    uint256 _projectId,
    uint256 _tokenCount,
    string calldata _memo,
    bool _preferClaimedTokens
  )
    external
    virtual
    override
    requirePermissionAllowingOverride(
      _holder,
      _projectId,
      JBOperations.BURN,
      directory.isTerminalOf(_projectId, IJBPaymentTerminal(msg.sender))
    )
  {
    // There should be tokens to burn
    if (_tokenCount == 0) revert NO_BURNABLE_TOKENS();

    // Get a reference to the project's current funding cycle.
    JBFundingCycle memory _fundingCycle = fundingCycleStore.currentOf(_projectId);

    // If the message sender is a terminal, the current funding cycle must not be paused.
    if (
      _fundingCycle.burnPaused() &&
      !directory.isTerminalOf(_projectId, IJBPaymentTerminal(msg.sender))
    ) revert BURN_PAUSED_AND_SENDER_NOT_VALID_TERMINAL_DELEGATE();

    // Burn the tokens.
    tokenStore.burnFrom(_holder, _projectId, _tokenCount, _preferClaimedTokens);

    emit BurnTokens(_holder, _projectId, _tokenCount, _memo, msg.sender);
  }

  /**
    @notice
    Distributes all outstanding reserved tokens for a project.

    @param _projectId The ID of the project to which the reserved tokens belong.
    @param _memo A memo to pass along to the emitted event.

    @return The amount of minted reserved tokens.
  */
  function distributeReservedTokensOf(uint256 _projectId, string calldata _memo)
    external
    virtual
    override
    returns (uint256)
  {
    return _distributeReservedTokensOf(_projectId, _memo);
  }

  /**
    @notice
    Allows other controllers to signal to this one that a migration is expected for the specified project.

    @dev
    This controller should not yet be the project's controller.

    @param _projectId The ID of the project that will be migrated to this controller.
    @param _from The controller being migrated from.
  */
  function prepForMigrationOf(uint256 _projectId, address _from) external virtual override {
    _projectId; // Prevents unused var compiler and natspec complaints.
    _from; // Prevents unused var compiler and natspec complaints.
  }

  /**
    @notice
    Allows a project to migrate from this controller to another.

    @dev
    Only a project's owner or a designated operator can migrate it.

    @param _projectId The ID of the project that will be migrated from this controller.
    @param _to The controller to which the project is migrating.
  */
  function migrate(uint256 _projectId, IJBMigratable _to)
    external
    virtual
    override
    requirePermission(projects.ownerOf(_projectId), _projectId, JBOperations.MIGRATE_CONTROLLER)
  {
    // Keep a reference to the directory.
    IJBDirectory _directory = directory;

    // This controller must be the project's current controller.
    if (_directory.controllerOf(_projectId) != address(this)) revert NOT_CURRENT_CONTROLLER();

    // Get a reference to the project's current funding cycle.
    JBFundingCycle memory _fundingCycle = fundingCycleStore.currentOf(_projectId);

    // Migration must be allowed.
    if (!_fundingCycle.controllerMigrationAllowed()) revert MIGRATION_NOT_ALLOWED();

    // All reserved tokens must be minted before migrating.
    if (reservedTokenBalanceOf[_projectId] != 0) _distributeReservedTokensOf(_projectId, '');

    // Make sure the new controller is prepped for the migration.
    _to.prepForMigrationOf(_projectId, address(this));

    // Set the new controller.
    _directory.setControllerOf(_projectId, address(_to));

    emit Migrate(_projectId, _to, msg.sender);
  }

  //*********************************************************************//
  // ------------------------ internal functions ----------------------- //
  //*********************************************************************//

  /**
    @notice
    Distributes all outstanding reserved tokens for a project.

    @param _projectId The ID of the project to which the reserved tokens belong.
    @param _memo A memo to pass along to the emitted event.

    @return tokenCount The amount of minted reserved tokens.
  */
  function _distributeReservedTokensOf(uint256 _projectId, string memory _memo)
    internal
    returns (uint256 tokenCount)
  {
    // Keep a reference to the token store.
    IJBTokenStore _tokenStore = tokenStore;

    // Get the current funding cycle to read the reserved rate from.
    JBFundingCycle memory _fundingCycle = fundingCycleStore.currentOf(_projectId);

    // Get a reference to the number of tokens that need to be minted.
    tokenCount = reservedTokenBalanceOf[_projectId];

    // Reset the reserved token balance
    reservedTokenBalanceOf[_projectId] = 0;

    // Get a reference to the project owner.
    address _owner = projects.ownerOf(_projectId);

    // Distribute tokens to splits and get a reference to the leftover amount to mint after all splits have gotten their share.
    uint256 _leftoverTokenCount = tokenCount == 0
      ? 0
      : _distributeToReservedTokenSplitsOf(
        _projectId,
        _fundingCycle.configuration,
        JBSplitsGroups.RESERVED_TOKENS,
        tokenCount
      );

    // Mint any leftover tokens to the project owner.
    if (_leftoverTokenCount > 0)
      _tokenStore.mintFor(_owner, _projectId, _leftoverTokenCount, false);

    emit DistributeReservedTokens(
      _fundingCycle.configuration,
      _fundingCycle.number,
      _projectId,
      _owner,
      tokenCount,
      _leftoverTokenCount,
      _memo,
      msg.sender
    );
  }

  /**
    @notice
    Distribute tokens to the splits according to the specified funding cycle configuration.

    @param _projectId The ID of the project for which reserved token splits are being distributed.
    @param _domain The domain of the splits to distribute the reserved tokens between.
    @param _group The group of the splits to distribute the reserved tokens between.
    @param _amount The total amount of tokens to mint.

    @return leftoverAmount If the splits percents dont add up to 100%, the leftover amount is returned.
  */
  function _distributeToReservedTokenSplitsOf(
    uint256 _projectId,
    uint256 _domain,
    uint256 _group,
    uint256 _amount
  ) internal returns (uint256 leftoverAmount) {
    // Keep a reference to the token store.
    IJBTokenStore _tokenStore = tokenStore;

    // Set the leftover amount to the initial amount.
    leftoverAmount = _amount;

    // Get a reference to the project's reserved token splits.
    JBSplit[] memory _splits = splitsStore.splitsOf(_projectId, _domain, _group);

    //Transfer between all splits.
    for (uint256 _i; _i < _splits.length; ) {
      // Get a reference to the split being iterated on.
      JBSplit memory _split = _splits[_i];

      // The amount to send towards the split.
      uint256 _tokenCount = PRBMath.mulDiv(
        _amount,
        _split.percent,
        JBConstants.SPLITS_TOTAL_PERCENT
      );

      // Mints tokens for the split if needed.
      if (_tokenCount > 0) {
        _tokenStore.mintFor(
          // If an allocator is set in the splits, set it as the beneficiary.
          // Otherwise if a projectId is set in the split, set the project's owner as the beneficiary.
          // If the split has a beneficiary send to the split's beneficiary. Otherwise send to the msg.sender.
          _split.allocator != IJBSplitAllocator(address(0))
            ? address(_split.allocator)
            : _split.projectId != 0
            ? projects.ownerOf(_split.projectId)
            : _split.beneficiary != address(0)
            ? _split.beneficiary
            : msg.sender,
          _projectId,
          _tokenCount,
          _split.preferClaimed
        );

        // If there's an allocator set, trigger its `allocate` function.
        if (_split.allocator != IJBSplitAllocator(address(0)))
          _split.allocator.allocate(
            JBSplitAllocationData(
              address(_tokenStore.tokenOf(_projectId)),
              _tokenCount,
              18,
              _projectId,
              _group,
              _split
            )
          );

        // Subtract from the amount to be sent to the beneficiary.
        leftoverAmount = leftoverAmount - _tokenCount;
      }

      emit DistributeToReservedTokenSplit(
        _projectId,
        _domain,
        _group,
        _split,
        _tokenCount,
        msg.sender
      );

      unchecked {
        ++_i;
      }
    }
  }

  /**
    @notice
    Configures a funding cycle and stores information pertinent to the configuration.

    @param _projectId The ID of the project whose funding cycles are being reconfigured.
    @param _data Data that defines the funding cycle. These properties will remain fixed for the duration of the funding cycle.
    @param _metadata Metadata specifying the controller specific params that a funding cycle can have. These properties will remain fixed for the duration of the funding cycle.
    @param _mustStartAtOrAfter The time before which the configured funding cycle cannot start.
    @param _groupedSplits An array of splits to set for any number of groups. 
    @param _fundAccessConstraints An array containing amounts that a project can use from its treasury for each payment terminal. Amounts are fixed point numbers using the same number of decimals as the accompanying terminal.

    @return configuration The configuration of the funding cycle that was successfully reconfigured.
  */
  function _configure(
    uint256 _projectId,
    JBFundingCycleData calldata _data,
    JBFundingCycleMetadata calldata _metadata,
    uint256 _mustStartAtOrAfter,
    JBGroupedSplits[] memory _groupedSplits,
    JBFundAccessConstraints[] memory _fundAccessConstraints
  ) internal returns (uint256) {
    // Make sure the provided reserved rate is valid.
    if (_metadata.reservedRate > JBConstants.MAX_RESERVED_RATE) revert INVALID_RESERVED_RATE();

    // Make sure the provided redemption rate is valid.
    if (_metadata.redemptionRate > JBConstants.MAX_REDEMPTION_RATE)
      revert INVALID_REDEMPTION_RATE();

    // Make sure the provided ballot redemption rate is valid.
    if (_metadata.ballotRedemptionRate > JBConstants.MAX_REDEMPTION_RATE)
      revert INVALID_BALLOT_REDEMPTION_RATE();

    // Configure the funding cycle's properties.
    JBFundingCycle memory _fundingCycle = fundingCycleStore.configureFor(
      _projectId,
      _data,
      JBFundingCycleMetadataResolver.packFundingCycleMetadata(_metadata),
      _mustStartAtOrAfter
    );

    // Set splits for the group.
    splitsStore.set(_projectId, _fundingCycle.configuration, _groupedSplits);

    // Set the funds access constraints.
    fundAccessConstraintsStore.setFor(
      _projectId,
      _fundingCycle.configuration,
      _fundAccessConstraints
    );

    return _fundingCycle.configuration;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import './../interfaces/IJBOperatable.sol';

/** 
  @notice
  Modifiers to allow access to functions based on the message sender's operator status.

  @dev
  Adheres to -
  IJBOperatable: General interface for the methods in this contract that interact with the blockchain's state according to the protocol's rules.
*/
abstract contract JBOperatable is IJBOperatable {
  //*********************************************************************//
  // --------------------------- custom errors -------------------------- //
  //*********************************************************************//
  error UNAUTHORIZED();

  //*********************************************************************//
  // ---------------------------- modifiers ---------------------------- //
  //*********************************************************************//

  /** 
    @notice
    Only allows the speficied account or an operator of the account to proceed. 

    @param _account The account to check for.
    @param _domain The domain namespace to look for an operator within. 
    @param _permissionIndex The index of the permission to check for. 
  */
  modifier requirePermission(
    address _account,
    uint256 _domain,
    uint256 _permissionIndex
  ) {
    _requirePermission(_account, _domain, _permissionIndex);
    _;
  }

  /** 
    @notice
    Only allows the speficied account, an operator of the account to proceed, or a truthy override flag. 

    @param _account The account to check for.
    @param _domain The domain namespace to look for an operator within. 
    @param _permissionIndex The index of the permission to check for. 
    @param _override A condition to force allowance for.
  */
  modifier requirePermissionAllowingOverride(
    address _account,
    uint256 _domain,
    uint256 _permissionIndex,
    bool _override
  ) {
    _requirePermissionAllowingOverride(_account, _domain, _permissionIndex, _override);
    _;
  }

  //*********************************************************************//
  // ---------------- public immutable stored properties --------------- //
  //*********************************************************************//

  /** 
    @notice 
    A contract storing operator assignments.
  */
  IJBOperatorStore public immutable override operatorStore;

  //*********************************************************************//
  // -------------------------- constructor ---------------------------- //
  //*********************************************************************//

  /** 
    @param _operatorStore A contract storing operator assignments.
  */
  constructor(IJBOperatorStore _operatorStore) {
    operatorStore = _operatorStore;
  }

  //*********************************************************************//
  // -------------------------- internal views ------------------------- //
  //*********************************************************************//

  /** 
    @notice
    Require the message sender is either the account or has the specified permission.

    @param _account The account to allow.
    @param _domain The domain namespace within which the permission index will be checked.
    @param _permissionIndex The permission index that an operator must have within the specified domain to be allowed.
  */
  function _requirePermission(
    address _account,
    uint256 _domain,
    uint256 _permissionIndex
  ) internal view {
    if (
      msg.sender != _account &&
      !operatorStore.hasPermission(msg.sender, _account, _domain, _permissionIndex) &&
      !operatorStore.hasPermission(msg.sender, _account, 0, _permissionIndex)
    ) revert UNAUTHORIZED();
  }

  /** 
    @notice
    Require the message sender is either the account, has the specified permission, or the override condition is true.

    @param _account The account to allow.
    @param _domain The domain namespace within which the permission index will be checked.
    @param _domain The permission index that an operator must have within the specified domain to be allowed.
    @param _override The override condition to allow.
  */
  function _requirePermissionAllowingOverride(
    address _account,
    uint256 _domain,
    uint256 _permissionIndex,
    bool _override
  ) internal view {
    if (
      !_override &&
      msg.sender != _account &&
      !operatorStore.hasPermission(msg.sender, _account, _domain, _permissionIndex) &&
      !operatorStore.hasPermission(msg.sender, _account, 0, _permissionIndex)
    ) revert UNAUTHORIZED();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum JBBallotState {
  Active,
  Approved,
  Failed
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './../structs/JBFundAccessConstraints.sol';
import './../structs/JBFundingCycleData.sol';
import './../structs/JBFundingCycleMetadata.sol';
import './../structs/JBGroupedSplits.sol';
import './../structs/JBProjectMetadata.sol';
import './IJBDirectory.sol';
import './IJBFundingCycleStore.sol';
import './IJBMigratable.sol';
import './IJBPaymentTerminal.sol';
import './IJBSplitsStore.sol';
import './IJBTokenStore.sol';

interface IJBController is IERC165 {
  event LaunchProject(uint256 configuration, uint256 projectId, string memo, address caller);

  event LaunchFundingCycles(uint256 configuration, uint256 projectId, string memo, address caller);

  event ReconfigureFundingCycles(
    uint256 configuration,
    uint256 projectId,
    string memo,
    address caller
  );

  event SetFundAccessConstraints(
    uint256 indexed fundingCycleConfiguration,
    uint256 indexed fundingCycleNumber,
    uint256 indexed projectId,
    JBFundAccessConstraints constraints,
    address caller
  );

  event DistributeReservedTokens(
    uint256 indexed fundingCycleConfiguration,
    uint256 indexed fundingCycleNumber,
    uint256 indexed projectId,
    address beneficiary,
    uint256 tokenCount,
    uint256 beneficiaryTokenCount,
    string memo,
    address caller
  );

  event DistributeToReservedTokenSplit(
    uint256 indexed projectId,
    uint256 indexed domain,
    uint256 indexed group,
    JBSplit split,
    uint256 tokenCount,
    address caller
  );

  event MintTokens(
    address indexed beneficiary,
    uint256 indexed projectId,
    uint256 tokenCount,
    uint256 beneficiaryTokenCount,
    string memo,
    uint256 reservedRate,
    address caller
  );

  event BurnTokens(
    address indexed holder,
    uint256 indexed projectId,
    uint256 tokenCount,
    string memo,
    address caller
  );

  event Migrate(uint256 indexed projectId, IJBMigratable to, address caller);

  event PrepMigration(uint256 indexed projectId, address from, address caller);

  function projects() external view returns (IJBProjects);

  function fundingCycleStore() external view returns (IJBFundingCycleStore);

  function tokenStore() external view returns (IJBTokenStore);

  function splitsStore() external view returns (IJBSplitsStore);

  function directory() external view returns (IJBDirectory);

  function reservedTokenBalanceOf(uint256 _projectId, uint256 _reservedRate)
    external
    view
    returns (uint256);

  function distributionLimitOf(
    uint256 _projectId,
    uint256 _configuration,
    IJBPaymentTerminal _terminal,
    address _token
  ) external view returns (uint256 distributionLimit, uint256 distributionLimitCurrency);

  function overflowAllowanceOf(
    uint256 _projectId,
    uint256 _configuration,
    IJBPaymentTerminal _terminal,
    address _token
  ) external view returns (uint256 overflowAllowance, uint256 overflowAllowanceCurrency);

  function totalOutstandingTokensOf(uint256 _projectId, uint256 _reservedRate)
    external
    view
    returns (uint256);

  function getFundingCycleOf(uint256 _projectId, uint256 _configuration)
    external
    view
    returns (JBFundingCycle memory fundingCycle, JBFundingCycleMetadata memory metadata);

  function latestConfiguredFundingCycleOf(uint256 _projectId)
    external
    view
    returns (
      JBFundingCycle memory,
      JBFundingCycleMetadata memory metadata,
      JBBallotState
    );

  function currentFundingCycleOf(uint256 _projectId)
    external
    view
    returns (JBFundingCycle memory fundingCycle, JBFundingCycleMetadata memory metadata);

  function queuedFundingCycleOf(uint256 _projectId)
    external
    view
    returns (JBFundingCycle memory fundingCycle, JBFundingCycleMetadata memory metadata);

  function launchProjectFor(
    address _owner,
    JBProjectMetadata calldata _projectMetadata,
    JBFundingCycleData calldata _data,
    JBFundingCycleMetadata calldata _metadata,
    uint256 _mustStartAtOrAfter,
    JBGroupedSplits[] memory _groupedSplits,
    JBFundAccessConstraints[] memory _fundAccessConstraints,
    IJBPaymentTerminal[] memory _terminals,
    string calldata _memo
  ) external returns (uint256 projectId);

  function launchFundingCyclesFor(
    uint256 _projectId,
    JBFundingCycleData calldata _data,
    JBFundingCycleMetadata calldata _metadata,
    uint256 _mustStartAtOrAfter,
    JBGroupedSplits[] memory _groupedSplits,
    JBFundAccessConstraints[] memory _fundAccessConstraints,
    IJBPaymentTerminal[] memory _terminals,
    string calldata _memo
  ) external returns (uint256 configuration);

  function reconfigureFundingCyclesOf(
    uint256 _projectId,
    JBFundingCycleData calldata _data,
    JBFundingCycleMetadata calldata _metadata,
    uint256 _mustStartAtOrAfter,
    JBGroupedSplits[] memory _groupedSplits,
    JBFundAccessConstraints[] memory _fundAccessConstraints,
    string calldata _memo
  ) external returns (uint256);

  function mintTokensOf(
    uint256 _projectId,
    uint256 _tokenCount,
    address _beneficiary,
    string calldata _memo,
    bool _preferClaimedTokens,
    bool _useReservedRate
  ) external returns (uint256 beneficiaryTokenCount);

  function burnTokensOf(
    address _holder,
    uint256 _projectId,
    uint256 _tokenCount,
    string calldata _memo,
    bool _preferClaimedTokens
  ) external;

  function distributeReservedTokensOf(uint256 _projectId, string memory _memo)
    external
    returns (uint256);

  function migrate(uint256 _projectId, IJBMigratable _to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './../structs/JBFundAccessConstraints.sol';
import './../structs/JBFundingCycleData.sol';
import './../structs/JBFundingCycleMetadata.sol';
import './../structs/JBGroupedSplits.sol';
import './../structs/JBProjectMetadata.sol';
import './IJBController.sol';
import './IJBDirectory.sol';
import './IJBFundingCycleStore.sol';
import './IJBMigratable.sol';
import './IJBPaymentTerminal.sol';
import './IJBSplitsStore.sol';
import './IJBTokenStore.sol';

interface IJBController3_0_1 {
  function reservedTokenBalanceOf(uint256 _projectId) external view returns (uint256);
  function totalOutstandingTokensOf(uint256 _projectId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './../structs/JBFundAccessConstraints.sol';
import './../structs/JBFundingCycleData.sol';
import './../structs/JBFundingCycleMetadata.sol';
import './../structs/JBGroupedSplits.sol';
import './../structs/JBProjectMetadata.sol';
import './IJBController3_0_1.sol';
import './IJBDirectory.sol';
import './IJBFundAccessConstraintsStore.sol';
import './IJBFundingCycleStore.sol';
import './IJBMigratable.sol';
import './IJBPaymentTerminal.sol';
import './IJBSplitsStore.sol';
import './IJBTokenStore.sol';

interface IJBController3_1 is IJBController3_0_1, IERC165 {
  event LaunchProject(uint256 configuration, uint256 projectId, string memo, address caller);

  event LaunchFundingCycles(uint256 configuration, uint256 projectId, string memo, address caller);

  event ReconfigureFundingCycles(
    uint256 configuration,
    uint256 projectId,
    string memo,
    address caller
  );

  event DistributeReservedTokens(
    uint256 indexed fundingCycleConfiguration,
    uint256 indexed fundingCycleNumber,
    uint256 indexed projectId,
    address beneficiary,
    uint256 tokenCount,
    uint256 beneficiaryTokenCount,
    string memo,
    address caller
  );

  event DistributeToReservedTokenSplit(
    uint256 indexed projectId,
    uint256 indexed domain,
    uint256 indexed group,
    JBSplit split,
    uint256 tokenCount,
    address caller
  );

  event MintTokens(
    address indexed beneficiary,
    uint256 indexed projectId,
    uint256 tokenCount,
    uint256 beneficiaryTokenCount,
    string memo,
    uint256 reservedRate,
    address caller
  );

  event BurnTokens(
    address indexed holder,
    uint256 indexed projectId,
    uint256 tokenCount,
    string memo,
    address caller
  );

  event Migrate(uint256 indexed projectId, IJBMigratable to, address caller);

  event PrepMigration(uint256 indexed projectId, address from, address caller);

  function projects() external view returns (IJBProjects);

  function fundingCycleStore() external view returns (IJBFundingCycleStore);

  function tokenStore() external view returns (IJBTokenStore);

  function splitsStore() external view returns (IJBSplitsStore);

  function fundAccessConstraintsStore() external view returns (IJBFundAccessConstraintsStore);

  function directory() external view returns (IJBDirectory);

  function reservedTokenBalanceOf(uint256 _projectId) external view returns (uint256);

  function totalOutstandingTokensOf(uint256 _projectId) external view returns (uint256);

  function getFundingCycleOf(uint256 _projectId, uint256 _configuration)
    external
    view
    returns (JBFundingCycle memory fundingCycle, JBFundingCycleMetadata memory metadata);

  function latestConfiguredFundingCycleOf(uint256 _projectId)
    external
    view
    returns (
      JBFundingCycle memory,
      JBFundingCycleMetadata memory metadata,
      JBBallotState
    );

  function currentFundingCycleOf(uint256 _projectId)
    external
    view
    returns (JBFundingCycle memory fundingCycle, JBFundingCycleMetadata memory metadata);

  function queuedFundingCycleOf(uint256 _projectId)
    external
    view
    returns (JBFundingCycle memory fundingCycle, JBFundingCycleMetadata memory metadata);

  function launchProjectFor(
    address _owner,
    JBProjectMetadata calldata _projectMetadata,
    JBFundingCycleData calldata _data,
    JBFundingCycleMetadata calldata _metadata,
    uint256 _mustStartAtOrAfter,
    JBGroupedSplits[] memory _groupedSplits,
    JBFundAccessConstraints[] memory _fundAccessConstraints,
    IJBPaymentTerminal[] memory _terminals,
    string calldata _memo
  ) external returns (uint256 projectId);

  function launchFundingCyclesFor(
    uint256 _projectId,
    JBFundingCycleData calldata _data,
    JBFundingCycleMetadata calldata _metadata,
    uint256 _mustStartAtOrAfter,
    JBGroupedSplits[] memory _groupedSplits,
    JBFundAccessConstraints[] memory _fundAccessConstraints,
    IJBPaymentTerminal[] memory _terminals,
    string calldata _memo
  ) external returns (uint256 configuration);

  function reconfigureFundingCyclesOf(
    uint256 _projectId,
    JBFundingCycleData calldata _data,
    JBFundingCycleMetadata calldata _metadata,
    uint256 _mustStartAtOrAfter,
    JBGroupedSplits[] memory _groupedSplits,
    JBFundAccessConstraints[] memory _fundAccessConstraints,
    string calldata _memo
  ) external returns (uint256);

  function mintTokensOf(
    uint256 _projectId,
    uint256 _tokenCount,
    address _beneficiary,
    string calldata _memo,
    bool _preferClaimedTokens,
    bool _useReservedRate
  ) external returns (uint256 beneficiaryTokenCount);

  function burnTokensOf(
    address _holder,
    uint256 _projectId,
    uint256 _tokenCount,
    string calldata _memo,
    bool _preferClaimedTokens
  ) external;

  function distributeReservedTokensOf(uint256 _projectId, string memory _memo)
    external
    returns (uint256);

  function migrate(uint256 _projectId, IJBMigratable _to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IJBFundingCycleStore.sol';
import './IJBPaymentTerminal.sol';
import './IJBProjects.sol';

interface IJBDirectory {
  event SetController(uint256 indexed projectId, address indexed controller, address caller);

  event AddTerminal(uint256 indexed projectId, IJBPaymentTerminal indexed terminal, address caller);

  event SetTerminals(uint256 indexed projectId, IJBPaymentTerminal[] terminals, address caller);

  event SetPrimaryTerminal(
    uint256 indexed projectId,
    address indexed token,
    IJBPaymentTerminal indexed terminal,
    address caller
  );

  event SetIsAllowedToSetFirstController(address indexed addr, bool indexed flag, address caller);

  function projects() external view returns (IJBProjects);

  function fundingCycleStore() external view returns (IJBFundingCycleStore);

  function controllerOf(uint256 _projectId) external view returns (address);

  function isAllowedToSetFirstController(address _address) external view returns (bool);

  function terminalsOf(uint256 _projectId) external view returns (IJBPaymentTerminal[] memory);

  function isTerminalOf(uint256 _projectId, IJBPaymentTerminal _terminal)
    external
    view
    returns (bool);

  function primaryTerminalOf(uint256 _projectId, address _token)
    external
    view
    returns (IJBPaymentTerminal);

  function setControllerOf(uint256 _projectId, address _controller) external;

  function setTerminalsOf(uint256 _projectId, IJBPaymentTerminal[] calldata _terminals) external;

  function setPrimaryTerminalOf(
    uint256 _projectId,
    address _token,
    IJBPaymentTerminal _terminal
  ) external;

  function setIsAllowedToSetFirstController(address _address, bool _flag) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './../structs/JBFundAccessConstraints.sol';
import './IJBPaymentTerminal.sol';

interface IJBFundAccessConstraintsStore is IERC165 {
  event SetFundAccessConstraints(
    uint256 indexed fundingCycleConfiguration,
    uint256 indexed projectId,
    JBFundAccessConstraints constraints,
    address caller
  );

  function distributionLimitOf(
    uint256 _projectId,
    uint256 _configuration,
    IJBPaymentTerminal _terminal,
    address _token
  ) external view returns (uint256 distributionLimit, uint256 distributionLimitCurrency);

  function overflowAllowanceOf(
    uint256 _projectId,
    uint256 _configuration,
    IJBPaymentTerminal _terminal,
    address _token
  ) external view returns (uint256 overflowAllowance, uint256 overflowAllowanceCurrency);

  function setFor(
    uint256 _projectId,
    uint256 _configuration,
    JBFundAccessConstraints[] memory _fundAccessConstaints
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './../enums/JBBallotState.sol';

interface IJBFundingCycleBallot is IERC165 {
  function duration() external view returns (uint256);

  function stateOf(
    uint256 _projectId,
    uint256 _configuration,
    uint256 _start
  ) external view returns (JBBallotState);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../enums/JBBallotState.sol';
import './../structs/JBFundingCycle.sol';
import './../structs/JBFundingCycleData.sol';

interface IJBFundingCycleStore {
  event Configure(
    uint256 indexed configuration,
    uint256 indexed projectId,
    JBFundingCycleData data,
    uint256 metadata,
    uint256 mustStartAtOrAfter,
    address caller
  );

  event Init(uint256 indexed configuration, uint256 indexed projectId, uint256 indexed basedOn);

  function latestConfigurationOf(uint256 _projectId) external view returns (uint256);

  function get(uint256 _projectId, uint256 _configuration)
    external
    view
    returns (JBFundingCycle memory);

  function latestConfiguredOf(uint256 _projectId)
    external
    view
    returns (JBFundingCycle memory fundingCycle, JBBallotState ballotState);

  function queuedOf(uint256 _projectId) external view returns (JBFundingCycle memory fundingCycle);

  function currentOf(uint256 _projectId) external view returns (JBFundingCycle memory fundingCycle);

  function currentBallotStateOf(uint256 _projectId) external view returns (JBBallotState);

  function configureFor(
    uint256 _projectId,
    JBFundingCycleData calldata _data,
    uint256 _metadata,
    uint256 _mustStartAtOrAfter
  ) external returns (JBFundingCycle memory fundingCycle);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJBMigratable {
  function prepForMigrationOf(uint256 _projectId, address _from) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IJBOperatorStore.sol';

interface IJBOperatable {
  function operatorStore() external view returns (IJBOperatorStore);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../structs/JBOperatorData.sol';

interface IJBOperatorStore {
  event SetOperator(
    address indexed operator,
    address indexed account,
    uint256 indexed domain,
    uint256[] permissionIndexes,
    uint256 packed
  );

  function permissionsOf(
    address _operator,
    address _account,
    uint256 _domain
  ) external view returns (uint256);

  function hasPermission(
    address _operator,
    address _account,
    uint256 _domain,
    uint256 _permissionIndex
  ) external view returns (bool);

  function hasPermissions(
    address _operator,
    address _account,
    uint256 _domain,
    uint256[] calldata _permissionIndexes
  ) external view returns (bool);

  function setOperator(JBOperatorData calldata _operatorData) external;

  function setOperators(JBOperatorData[] calldata _operatorData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';

interface IJBPaymentTerminal is IERC165 {
  function acceptsToken(address _token, uint256 _projectId) external view returns (bool);

  function currencyForToken(address _token) external view returns (uint256);

  function decimalsForToken(address _token) external view returns (uint256);

  // Return value must be a fixed point number with 18 decimals.
  function currentEthOverflowOf(uint256 _projectId) external view returns (uint256);

  function pay(
    uint256 _projectId,
    uint256 _amount,
    address _token,
    address _beneficiary,
    uint256 _minReturnedTokens,
    bool _preferClaimedTokens,
    string calldata _memo,
    bytes calldata _metadata
  ) external payable returns (uint256 beneficiaryTokenCount);

  function addToBalanceOf(
    uint256 _projectId,
    uint256 _amount,
    address _token,
    string calldata _memo,
    bytes calldata _metadata
  ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import './../structs/JBProjectMetadata.sol';
import './IJBTokenUriResolver.sol';

interface IJBProjects is IERC721 {
  event Create(
    uint256 indexed projectId,
    address indexed owner,
    JBProjectMetadata metadata,
    address caller
  );

  event SetMetadata(uint256 indexed projectId, JBProjectMetadata metadata, address caller);

  event SetTokenUriResolver(IJBTokenUriResolver indexed resolver, address caller);

  function count() external view returns (uint256);

  function metadataContentOf(uint256 _projectId, uint256 _domain)
    external
    view
    returns (string memory);

  function tokenUriResolver() external view returns (IJBTokenUriResolver);

  function createFor(address _owner, JBProjectMetadata calldata _metadata)
    external
    returns (uint256 projectId);

  function setMetadataOf(uint256 _projectId, JBProjectMetadata calldata _metadata) external;

  function setTokenUriResolver(IJBTokenUriResolver _newResolver) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import '../structs/JBSplitAllocationData.sol';

/**
  @title
  Split allocator

  @notice
  Provide a way to process a single split with extra logic

  @dev
  Adheres to:
  IERC165 for adequate interface integration

  @dev
  The contract address should be set as an allocator in the adequate split
*/
interface IJBSplitAllocator is IERC165 {
  /**
    @notice
    This function is called by JBPaymentTerminal.distributePayoutOf(..), during the processing of the split including it

    @dev
    Critical business logic should be protected by an appropriate access control. The token and/or eth are optimistically transfered
    to the allocator for its logic.
    
    @param _data the data passed by the terminal, as a JBSplitAllocationData struct:
                  address token;
                  uint256 amount;
                  uint256 decimals;
                  uint256 projectId;
                  uint256 group;
                  JBSplit split;
  */
  function allocate(JBSplitAllocationData calldata _data) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../structs/JBGroupedSplits.sol';
import './../structs/JBSplit.sol';
import './IJBDirectory.sol';
import './IJBProjects.sol';

interface IJBSplitsStore {
  event SetSplit(
    uint256 indexed projectId,
    uint256 indexed domain,
    uint256 indexed group,
    JBSplit split,
    address caller
  );

  function projects() external view returns (IJBProjects);

  function directory() external view returns (IJBDirectory);

  function splitsOf(
    uint256 _projectId,
    uint256 _domain,
    uint256 _group
  ) external view returns (JBSplit[] memory);

  function set(
    uint256 _projectId,
    uint256 _domain,
    JBGroupedSplits[] memory _groupedSplits
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJBToken {
  function projectId() external view returns (uint256);

  function decimals() external view returns (uint8);

  function totalSupply(uint256 _projectId) external view returns (uint256);

  function balanceOf(address _account, uint256 _projectId) external view returns (uint256);

  function mint(
    uint256 _projectId,
    address _account,
    uint256 _amount
  ) external;

  function burn(
    uint256 _projectId,
    address _account,
    uint256 _amount
  ) external;

  function approve(
    uint256,
    address _spender,
    uint256 _amount
  ) external;

  function transfer(
    uint256 _projectId,
    address _to,
    uint256 _amount
  ) external;

  function transferFrom(
    uint256 _projectId,
    address _from,
    address _to,
    uint256 _amount
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IJBFundingCycleStore.sol';
import './IJBProjects.sol';
import './IJBToken.sol';

interface IJBTokenStore {
  event Issue(
    uint256 indexed projectId,
    IJBToken indexed token,
    string name,
    string symbol,
    address caller
  );

  event Mint(
    address indexed holder,
    uint256 indexed projectId,
    uint256 amount,
    bool tokensWereClaimed,
    bool preferClaimedTokens,
    address caller
  );

  event Burn(
    address indexed holder,
    uint256 indexed projectId,
    uint256 amount,
    uint256 initialUnclaimedBalance,
    uint256 initialClaimedBalance,
    bool preferClaimedTokens,
    address caller
  );

  event Claim(
    address indexed holder,
    uint256 indexed projectId,
    uint256 initialUnclaimedBalance,
    uint256 amount,
    address caller
  );

  event Set(uint256 indexed projectId, IJBToken indexed newToken, address caller);

  event Transfer(
    address indexed holder,
    uint256 indexed projectId,
    address indexed recipient,
    uint256 amount,
    address caller
  );

  function tokenOf(uint256 _projectId) external view returns (IJBToken);

  function projects() external view returns (IJBProjects);

  function fundingCycleStore() external view returns (IJBFundingCycleStore);

  function unclaimedBalanceOf(address _holder, uint256 _projectId) external view returns (uint256);

  function unclaimedTotalSupplyOf(uint256 _projectId) external view returns (uint256);

  function totalSupplyOf(uint256 _projectId) external view returns (uint256);

  function balanceOf(address _holder, uint256 _projectId) external view returns (uint256 _result);

  function issueFor(
    uint256 _projectId,
    string calldata _name,
    string calldata _symbol
  ) external returns (IJBToken token);

  function setFor(uint256 _projectId, IJBToken _token) external;

  function burnFrom(
    address _holder,
    uint256 _projectId,
    uint256 _amount,
    bool _preferClaimedTokens
  ) external;

  function mintFor(
    address _holder,
    uint256 _projectId,
    uint256 _amount,
    bool _preferClaimedTokens
  ) external;

  function claimFor(
    address _holder,
    uint256 _projectId,
    uint256 _amount
  ) external;

  function transferFrom(
    address _holder,
    uint256 _projectId,
    address _recipient,
    uint256 _amount
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJBTokenUriResolver {
  function getUri(uint256 _projectId) external view returns (string memory tokenUri);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
  @notice
  Global constants used across Juicebox contracts.
*/
library JBConstants {
  uint256 public constant MAX_RESERVED_RATE = 10_000;
  uint256 public constant MAX_REDEMPTION_RATE = 10_000;
  uint256 public constant MAX_DISCOUNT_RATE = 1_000_000_000;
  uint256 public constant SPLITS_TOTAL_PERCENT = 1_000_000_000;
  uint256 public constant MAX_FEE = 1_000_000_000;
  uint256 public constant MAX_FEE_DISCOUNT = 1_000_000_000;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import './../structs/JBFundingCycle.sol';
import './../structs/JBFundingCycleMetadata.sol';
import './../structs/JBGlobalFundingCycleMetadata.sol';
import './JBConstants.sol';
import './JBGlobalFundingCycleMetadataResolver.sol';

library JBFundingCycleMetadataResolver {
  function global(JBFundingCycle memory _fundingCycle)
    internal
    pure
    returns (JBGlobalFundingCycleMetadata memory)
  {
    return JBGlobalFundingCycleMetadataResolver.expandMetadata(uint8(_fundingCycle.metadata >> 8));
  }

  function reservedRate(JBFundingCycle memory _fundingCycle) internal pure returns (uint256) {
    return uint256(uint16(_fundingCycle.metadata >> 24));
  }

  function redemptionRate(JBFundingCycle memory _fundingCycle) internal pure returns (uint256) {
    // Redemption rate is a number 0-10000. It's inverse was stored so the most common case of 100% results in no storage needs.
    return JBConstants.MAX_REDEMPTION_RATE - uint256(uint16(_fundingCycle.metadata >> 40));
  }

  function ballotRedemptionRate(JBFundingCycle memory _fundingCycle)
    internal
    pure
    returns (uint256)
  {
    // Redemption rate is a number 0-10000. It's inverse was stored so the most common case of 100% results in no storage needs.
    return JBConstants.MAX_REDEMPTION_RATE - uint256(uint16(_fundingCycle.metadata >> 56));
  }

  function payPaused(JBFundingCycle memory _fundingCycle) internal pure returns (bool) {
    return ((_fundingCycle.metadata >> 72) & 1) == 1;
  }

  function distributionsPaused(JBFundingCycle memory _fundingCycle) internal pure returns (bool) {
    return ((_fundingCycle.metadata >> 73) & 1) == 1;
  }

  function redeemPaused(JBFundingCycle memory _fundingCycle) internal pure returns (bool) {
    return ((_fundingCycle.metadata >> 74) & 1) == 1;
  }

  function burnPaused(JBFundingCycle memory _fundingCycle) internal pure returns (bool) {
    return ((_fundingCycle.metadata >> 75) & 1) == 1;
  }

  function mintingAllowed(JBFundingCycle memory _fundingCycle) internal pure returns (bool) {
    return ((_fundingCycle.metadata >> 76) & 1) == 1;
  }

  function terminalMigrationAllowed(JBFundingCycle memory _fundingCycle)
    internal
    pure
    returns (bool)
  {
    return ((_fundingCycle.metadata >> 77) & 1) == 1;
  }

  function controllerMigrationAllowed(JBFundingCycle memory _fundingCycle)
    internal
    pure
    returns (bool)
  {
    return ((_fundingCycle.metadata >> 78) & 1) == 1;
  }

  function shouldHoldFees(JBFundingCycle memory _fundingCycle) internal pure returns (bool) {
    return ((_fundingCycle.metadata >> 79) & 1) == 1;
  }

  function preferClaimedTokenOverride(JBFundingCycle memory _fundingCycle)
    internal
    pure
    returns (bool)
  {
    return ((_fundingCycle.metadata >> 80) & 1) == 1;
  }

  function useTotalOverflowForRedemptions(JBFundingCycle memory _fundingCycle)
    internal
    pure
    returns (bool)
  {
    return ((_fundingCycle.metadata >> 81) & 1) == 1;
  }

  function useDataSourceForPay(JBFundingCycle memory _fundingCycle) internal pure returns (bool) {
    return (_fundingCycle.metadata >> 82) & 1 == 1;
  }

  function useDataSourceForRedeem(JBFundingCycle memory _fundingCycle)
    internal
    pure
    returns (bool)
  {
    return (_fundingCycle.metadata >> 83) & 1 == 1;
  }

  function dataSource(JBFundingCycle memory _fundingCycle) internal pure returns (address) {
    return address(uint160(_fundingCycle.metadata >> 84));
  }

  function metadata(JBFundingCycle memory _fundingCycle) internal pure returns (uint256) {
    return uint256(uint8(_fundingCycle.metadata >> 244));
  }

  /**
    @notice
    Pack the funding cycle metadata.

    @param _metadata The metadata to validate and pack.

    @return packed The packed uint256 of all metadata params. The first 8 bits specify the version.
  */
  function packFundingCycleMetadata(JBFundingCycleMetadata memory _metadata)
    internal
    pure
    returns (uint256 packed)
  {
    // version 1 in the bits 0-7 (8 bits).
    packed = 1;
    // global metadta in bits 8-23 (16 bits).
    packed |=
      JBGlobalFundingCycleMetadataResolver.packFundingCycleGlobalMetadata(_metadata.global) <<
      8;
    // reserved rate in bits 24-39 (16 bits).
    packed |= _metadata.reservedRate << 24;
    // redemption rate in bits 40-55 (16 bits).
    // redemption rate is a number 0-10000. Store the reverse so the most common case of 100% results in no storage needs.
    packed |= (JBConstants.MAX_REDEMPTION_RATE - _metadata.redemptionRate) << 40;
    // ballot redemption rate rate in bits 56-71 (16 bits).
    // ballot redemption rate is a number 0-10000. Store the reverse so the most common case of 100% results in no storage needs.
    packed |= (JBConstants.MAX_REDEMPTION_RATE - _metadata.ballotRedemptionRate) << 56;
    // pause pay in bit 72.
    if (_metadata.pausePay) packed |= 1 << 72;
    // pause tap in bit 73.
    if (_metadata.pauseDistributions) packed |= 1 << 73;
    // pause redeem in bit 74.
    if (_metadata.pauseRedeem) packed |= 1 << 74;
    // pause burn in bit 75.
    if (_metadata.pauseBurn) packed |= 1 << 75;
    // allow minting in bit 76.
    if (_metadata.allowMinting) packed |= 1 << 76;
    // allow terminal migration in bit 77.
    if (_metadata.allowTerminalMigration) packed |= 1 << 77;
    // allow controller migration in bit 78.
    if (_metadata.allowControllerMigration) packed |= 1 << 78;
    // hold fees in bit 79.
    if (_metadata.holdFees) packed |= 1 << 79;
    // prefer claimed token override in bit 80.
    if (_metadata.preferClaimedTokenOverride) packed |= 1 << 80;
    // useTotalOverflowForRedemptions in bit 81.
    if (_metadata.useTotalOverflowForRedemptions) packed |= 1 << 81;
    // use pay data source in bit 82.
    if (_metadata.useDataSourceForPay) packed |= 1 << 82;
    // use redeem data source in bit 83.
    if (_metadata.useDataSourceForRedeem) packed |= 1 << 83;
    // data source address in bits 84-243.
    packed |= uint256(uint160(address(_metadata.dataSource))) << 84;
    // metadata in bits 244-252 (8 bits).
    packed |= _metadata.metadata << 244;
  }

  /**
    @notice
    Expand the funding cycle metadata.

    @param _fundingCycle The funding cycle having its metadata expanded.

    @return metadata The metadata object.
  */
  function expandMetadata(JBFundingCycle memory _fundingCycle)
    internal
    pure
    returns (JBFundingCycleMetadata memory)
  {
    return
      JBFundingCycleMetadata(
        global(_fundingCycle),
        reservedRate(_fundingCycle),
        redemptionRate(_fundingCycle),
        ballotRedemptionRate(_fundingCycle),
        payPaused(_fundingCycle),
        distributionsPaused(_fundingCycle),
        redeemPaused(_fundingCycle),
        burnPaused(_fundingCycle),
        mintingAllowed(_fundingCycle),
        terminalMigrationAllowed(_fundingCycle),
        controllerMigrationAllowed(_fundingCycle),
        shouldHoldFees(_fundingCycle),
        preferClaimedTokenOverride(_fundingCycle),
        useTotalOverflowForRedemptions(_fundingCycle),
        useDataSourceForPay(_fundingCycle),
        useDataSourceForRedeem(_fundingCycle),
        dataSource(_fundingCycle),
        metadata(_fundingCycle)
      );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import './../structs/JBFundingCycleMetadata.sol';

library JBGlobalFundingCycleMetadataResolver {
  function setTerminalsAllowed(uint8 _data) internal pure returns (bool) {
    return (_data & 1) == 1;
  }

  function setControllerAllowed(uint8 _data) internal pure returns (bool) {
    return ((_data >> 1) & 1) == 1;
  }

  function transfersPaused(uint8 _data) internal pure returns (bool) {
    return ((_data >> 2) & 1) == 1;
  }

  /**
    @notice
    Pack the global funding cycle metadata.

    @param _metadata The metadata to validate and pack.

    @return packed The packed uint256 of all global metadata params. The first 8 bits specify the version.
  */
  function packFundingCycleGlobalMetadata(JBGlobalFundingCycleMetadata memory _metadata)
    internal
    pure
    returns (uint256 packed)
  {
    // allow set terminals in bit 0.
    if (_metadata.allowSetTerminals) packed |= 1;
    // allow set controller in bit 1.
    if (_metadata.allowSetController) packed |= 1 << 1;
    // pause transfers in bit 2.
    if (_metadata.pauseTransfers) packed |= 1 << 2;
  }

  /**
    @notice
    Expand the global funding cycle metadata.

    @param _packedMetadata The packed metadata to expand.

    @return metadata The global metadata object.
  */
  function expandMetadata(uint8 _packedMetadata)
    internal
    pure
    returns (JBGlobalFundingCycleMetadata memory metadata)
  {
    return
      JBGlobalFundingCycleMetadata(
        setTerminalsAllowed(_packedMetadata),
        setControllerAllowed(_packedMetadata),
        transfersPaused(_packedMetadata)
      );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library JBOperations {
  uint256 public constant RECONFIGURE = 1;
  uint256 public constant REDEEM = 2;
  uint256 public constant MIGRATE_CONTROLLER = 3;
  uint256 public constant MIGRATE_TERMINAL = 4;
  uint256 public constant PROCESS_FEES = 5;
  uint256 public constant SET_METADATA = 6;
  uint256 public constant ISSUE = 7;
  uint256 public constant SET_TOKEN = 8;
  uint256 public constant MINT = 9;
  uint256 public constant BURN = 10;
  uint256 public constant CLAIM = 11;
  uint256 public constant TRANSFER = 12;
  uint256 public constant REQUIRE_CLAIM = 13; // unused in v3
  uint256 public constant SET_CONTROLLER = 14;
  uint256 public constant SET_TERMINALS = 15;
  uint256 public constant SET_PRIMARY_TERMINAL = 16;
  uint256 public constant USE_ALLOWANCE = 17;
  uint256 public constant SET_SPLITS = 18;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library JBSplitsGroups {
  uint256 public constant ETH_PAYOUT = 1;
  uint256 public constant RESERVED_TOKENS = 2;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../interfaces/IJBPaymentTerminal.sol';

/** 
  @member terminal The terminal within which the distribution limit and the overflow allowance applies.
  @member token The token for which the fund access constraints apply.
  @member distributionLimit The amount of the distribution limit, as a fixed point number with the same number of decimals as the terminal within which the limit applies.
  @member distributionLimitCurrency The currency of the distribution limit.
  @member overflowAllowance The amount of the allowance, as a fixed point number with the same number of decimals as the terminal within which the allowance applies.
  @member overflowAllowanceCurrency The currency of the overflow allowance.
*/
struct JBFundAccessConstraints {
  IJBPaymentTerminal terminal;
  address token;
  uint256 distributionLimit;
  uint256 distributionLimitCurrency;
  uint256 overflowAllowance;
  uint256 overflowAllowanceCurrency;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../interfaces/IJBFundingCycleBallot.sol';

/** 
  @member number The funding cycle number for the cycle's project. Each funding cycle has a number that is an increment of the cycle that directly preceded it. Each project's first funding cycle has a number of 1.
  @member configuration The timestamp when the parameters for this funding cycle were configured. This value will stay the same for subsequent funding cycles that roll over from an originally configured cycle.
  @member basedOn The `configuration` of the funding cycle that was active when this cycle was created.
  @member start The timestamp marking the moment from which the funding cycle is considered active. It is a unix timestamp measured in seconds.
  @member duration The number of seconds the funding cycle lasts for, after which a new funding cycle will start. A duration of 0 means that the funding cycle will stay active until the project owner explicitly issues a reconfiguration, at which point a new funding cycle will immediately start with the updated properties. If the duration is greater than 0, a project owner cannot make changes to a funding cycle's parameters while it is active – any proposed changes will apply to the subsequent cycle. If no changes are proposed, a funding cycle rolls over to another one with the same properties but new `start` timestamp and a discounted `weight`.
  @member weight A fixed point number with 18 decimals that contracts can use to base arbitrary calculations on. For example, payment terminals can use this to determine how many tokens should be minted when a payment is received.
  @member discountRate A percent by how much the `weight` of the subsequent funding cycle should be reduced, if the project owner hasn't configured the subsequent funding cycle with an explicit `weight`. If it's 0, each funding cycle will have equal weight. If the number is 90%, the next funding cycle will have a 10% smaller weight. This weight is out of `JBConstants.MAX_DISCOUNT_RATE`.
  @member ballot An address of a contract that says whether a proposed reconfiguration should be accepted or rejected. It can be used to create rules around how a project owner can change funding cycle parameters over time.
  @member metadata Extra data that can be associated with a funding cycle.
*/
struct JBFundingCycle {
  uint256 number;
  uint256 configuration;
  uint256 basedOn;
  uint256 start;
  uint256 duration;
  uint256 weight;
  uint256 discountRate;
  IJBFundingCycleBallot ballot;
  uint256 metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../interfaces/IJBFundingCycleBallot.sol';

/** 
  @member duration The number of seconds the funding cycle lasts for, after which a new funding cycle will start. A duration of 0 means that the funding cycle will stay active until the project owner explicitly issues a reconfiguration, at which point a new funding cycle will immediately start with the updated properties. If the duration is greater than 0, a project owner cannot make changes to a funding cycle's parameters while it is active – any proposed changes will apply to the subsequent cycle. If no changes are proposed, a funding cycle rolls over to another one with the same properties but new `start` timestamp and a discounted `weight`.
  @member weight A fixed point number with 18 decimals that contracts can use to base arbitrary calculations on. For example, payment terminals can use this to determine how many tokens should be minted when a payment is received.
  @member discountRate A percent by how much the `weight` of the subsequent funding cycle should be reduced, if the project owner hasn't configured the subsequent funding cycle with an explicit `weight`. If it's 0, each funding cycle will have equal weight. If the number is 90%, the next funding cycle will have a 10% smaller weight. This weight is out of `JBConstants.MAX_DISCOUNT_RATE`.
  @member ballot An address of a contract that says whether a proposed reconfiguration should be accepted or rejected. It can be used to create rules around how a project owner can change funding cycle parameters over time.
*/
struct JBFundingCycleData {
  uint256 duration;
  uint256 weight;
  uint256 discountRate;
  IJBFundingCycleBallot ballot;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './JBGlobalFundingCycleMetadata.sol';

/** 
  @member global Data used globally in non-migratable ecosystem contracts.
  @member reservedRate The reserved rate of the funding cycle. This number is a percentage calculated out of `JBConstants.MAX_RESERVED_RATE`.
  @member redemptionRate The redemption rate of the funding cycle. This number is a percentage calculated out of `JBConstants.MAX_REDEMPTION_RATE`.
  @member ballotRedemptionRate The redemption rate to use during an active ballot of the funding cycle. This number is a percentage calculated out of `JBConstants.MAX_REDEMPTION_RATE`.
  @member pausePay A flag indicating if the pay functionality should be paused during the funding cycle.
  @member pauseDistributions A flag indicating if the distribute functionality should be paused during the funding cycle.
  @member pauseRedeem A flag indicating if the redeem functionality should be paused during the funding cycle.
  @member pauseBurn A flag indicating if the burn functionality should be paused during the funding cycle.
  @member allowMinting A flag indicating if minting tokens should be allowed during this funding cycle.
  @member allowTerminalMigration A flag indicating if migrating terminals should be allowed during this funding cycle.
  @member allowControllerMigration A flag indicating if migrating controllers should be allowed during this funding cycle.
  @member holdFees A flag indicating if fees should be held during this funding cycle.
  @member preferClaimedTokenOverride A flag indicating if claimed tokens should always be prefered to unclaimed tokens when minting.
  @member useTotalOverflowForRedemptions A flag indicating if redemptions should use the project's balance held in all terminals instead of the project's local terminal balance from which the redemption is being fulfilled.
  @member useDataSourceForPay A flag indicating if the data source should be used for pay transactions during this funding cycle.
  @member useDataSourceForRedeem A flag indicating if the data source should be used for redeem transactions during this funding cycle.
  @member dataSource The data source to use during this funding cycle.
  @member metadata Metadata of the metadata, up to uint8 in size.
*/
struct JBFundingCycleMetadata {
  JBGlobalFundingCycleMetadata global;
  uint256 reservedRate;
  uint256 redemptionRate;
  uint256 ballotRedemptionRate;
  bool pausePay;
  bool pauseDistributions;
  bool pauseRedeem;
  bool pauseBurn;
  bool allowMinting;
  bool allowTerminalMigration;
  bool allowControllerMigration;
  bool holdFees;
  bool preferClaimedTokenOverride;
  bool useTotalOverflowForRedemptions;
  bool useDataSourceForPay;
  bool useDataSourceForRedeem;
  address dataSource;
  uint256 metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** 
  @member allowSetTerminals A flag indicating if setting terminals should be allowed during this funding cycle.
  @member allowSetController A flag indicating if setting a new controller should be allowed during this funding cycle.
  @member pauseTransfers A flag indicating if the project token transfer functionality should be paused during the funding cycle.
*/
struct JBGlobalFundingCycleMetadata {
  bool allowSetTerminals;
  bool allowSetController;
  bool pauseTransfers;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './JBSplit.sol';

/** 
  @member group The group indentifier.
  @member splits The splits to associate with the group.
*/
struct JBGroupedSplits {
  uint256 group;
  JBSplit[] splits;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** 
  @member operator The address of the operator.
  @member domain The domain within which the operator is being given permissions. A domain of 0 is a wildcard domain, which gives an operator access to all domains.
  @member permissionIndexes The indexes of the permissions the operator is being given.
*/
struct JBOperatorData {
  address operator;
  uint256 domain;
  uint256[] permissionIndexes;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** 
  @member content The metadata content.
  @member domain The domain within which the metadata applies.
*/
struct JBProjectMetadata {
  string content;
  uint256 domain;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../interfaces/IJBSplitAllocator.sol';

/** 
  @member preferClaimed A flag that only has effect if a projectId is also specified, and the project has a token contract attached. If so, this flag indicates if the tokens that result from making a payment to the project should be delivered claimed into the beneficiary's wallet, or unclaimed to save gas.
  @member preferAddToBalance A flag indicating if a distribution to a project should prefer triggering it's addToBalance function instead of its pay function.
  @member percent The percent of the whole group that this split occupies. This number is out of `JBConstants.SPLITS_TOTAL_PERCENT`.
  @member projectId The ID of a project. If an allocator is not set but a projectId is set, funds will be sent to the protocol treasury belonging to the project who's ID is specified. Resulting tokens will be routed to the beneficiary with the claimed token preference respected.
  @member beneficiary An address. The role the of the beneficary depends on whether or not projectId is specified, and whether or not an allocator is specified. If allocator is set, the beneficiary will be forwarded to the allocator for it to use. If allocator is not set but projectId is set, the beneficiary is the address to which the project's tokens will be sent that result from a payment to it. If neither allocator or projectId are set, the beneficiary is where the funds from the split will be sent.
  @member lockedUntil Specifies if the split should be unchangeable until the specified time, with the exception of extending the locked period.
  @member allocator If an allocator is specified, funds will be sent to the allocator contract along with all properties of this split.
*/
struct JBSplit {
  bool preferClaimed;
  bool preferAddToBalance;
  uint256 percent;
  uint256 projectId;
  address payable beneficiary;
  uint256 lockedUntil;
  IJBSplitAllocator allocator;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './JBSplit.sol';

/** 
  @member token The token being sent to the split allocator.
  @member amount The amount being sent to the split allocator, as a fixed point number.
  @member decimals The number of decimals in the amount.
  @member projectId The project to which the split belongs.
  @member group The group to which the split belongs.
  @member split The split that caused the allocation.
*/
struct JBSplitAllocationData {
  address token;
  uint256 amount;
  uint256 decimals;
  uint256 projectId;
  uint256 group;
  JBSplit split;
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivFixedPointOverflow(uint256 prod1);

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivOverflow(uint256 prod1, uint256 denominator);

/// @notice Emitted when one of the inputs is type(int256).min.
error PRBMath__MulDivSignedInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows int256.
error PRBMath__MulDivSignedOverflow(uint256 rAbs);

/// @notice Emitted when the input is MIN_SD59x18.
error PRBMathSD59x18__AbsInputTooSmall();

/// @notice Emitted when ceiling a number overflows SD59x18.
error PRBMathSD59x18__CeilOverflow(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__DivInputTooSmall();

/// @notice Emitted when one of the intermediary unsigned results overflows SD59x18.
error PRBMathSD59x18__DivOverflow(uint256 rAbs);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathSD59x18__ExpInputTooBig(int256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathSD59x18__Exp2InputTooBig(int256 x);

/// @notice Emitted when flooring a number underflows SD59x18.
error PRBMathSD59x18__FloorUnderflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format overflows SD59x18.
error PRBMathSD59x18__FromIntOverflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format underflows SD59x18.
error PRBMathSD59x18__FromIntUnderflow(int256 x);

/// @notice Emitted when the product of the inputs is negative.
error PRBMathSD59x18__GmNegativeProduct(int256 x, int256 y);

/// @notice Emitted when multiplying the inputs overflows SD59x18.
error PRBMathSD59x18__GmOverflow(int256 x, int256 y);

/// @notice Emitted when the input is less than or equal to zero.
error PRBMathSD59x18__LogInputTooSmall(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__MulInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__MulOverflow(uint256 rAbs);

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__PowuOverflow(uint256 rAbs);

/// @notice Emitted when the input is negative.
error PRBMathSD59x18__SqrtNegativeInput(int256 x);

/// @notice Emitted when the calculating the square root overflows SD59x18.
error PRBMathSD59x18__SqrtOverflow(int256 x);

/// @notice Emitted when addition overflows UD60x18.
error PRBMathUD60x18__AddOverflow(uint256 x, uint256 y);

/// @notice Emitted when ceiling a number overflows UD60x18.
error PRBMathUD60x18__CeilOverflow(uint256 x);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathUD60x18__ExpInputTooBig(uint256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathUD60x18__Exp2InputTooBig(uint256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format format overflows UD60x18.
error PRBMathUD60x18__FromUintOverflow(uint256 x);

/// @notice Emitted when multiplying the inputs overflows UD60x18.
error PRBMathUD60x18__GmOverflow(uint256 x, uint256 y);

/// @notice Emitted when the input is less than 1.
error PRBMathUD60x18__LogInputTooSmall(uint256 x);

/// @notice Emitted when the calculating the square root overflows UD60x18.
error PRBMathUD60x18__SqrtOverflow(uint256 x);

/// @notice Emitted when subtraction underflows UD60x18.
error PRBMathUD60x18__SubUnderflow(uint256 x, uint256 y);

/// @dev Common mathematical functions used in both PRBMathSD59x18 and PRBMathUD60x18. Note that this shared library
/// does not always assume the signed 59.18-decimal fixed-point or the unsigned 60.18-decimal fixed-point
/// representation. When it does not, it is explicitly mentioned in the NatSpec documentation.
library PRBMath {
    /// STRUCTS ///

    struct SD59x18 {
        int256 value;
    }

    struct UD60x18 {
        uint256 value;
    }

    /// STORAGE ///

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @dev Largest power of two divisor of SCALE.
    uint256 internal constant SCALE_LPOTD = 262144;

    /// @dev SCALE inverted mod 2^256.
    uint256 internal constant SCALE_INVERSE =
        78156646155174841979727994598816262306175212592076161876661_508869554232690281;

    /// FUNCTIONS ///

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    /// @dev Has to use 192.64-bit fixed-point numbers.
    /// See https://ethereum.stackexchange.com/a/96594/24693.
    /// @param x The exponent as an unsigned 192.64-bit fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // Start from 0.5 in the 192.64-bit fixed-point format.
            result = 0x800000000000000000000000000000000000000000000000;

            // Multiply the result by root(2, 2^-i) when the bit at position i is 1. None of the intermediary results overflows
            // because the initial result is 2^191 and all magic factors are less than 2^65.
            if (x & 0x8000000000000000 > 0) {
                result = (result * 0x16A09E667F3BCC909) >> 64;
            }
            if (x & 0x4000000000000000 > 0) {
                result = (result * 0x1306FE0A31B7152DF) >> 64;
            }
            if (x & 0x2000000000000000 > 0) {
                result = (result * 0x1172B83C7D517ADCE) >> 64;
            }
            if (x & 0x1000000000000000 > 0) {
                result = (result * 0x10B5586CF9890F62A) >> 64;
            }
            if (x & 0x800000000000000 > 0) {
                result = (result * 0x1059B0D31585743AE) >> 64;
            }
            if (x & 0x400000000000000 > 0) {
                result = (result * 0x102C9A3E778060EE7) >> 64;
            }
            if (x & 0x200000000000000 > 0) {
                result = (result * 0x10163DA9FB33356D8) >> 64;
            }
            if (x & 0x100000000000000 > 0) {
                result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }
            if (x & 0x80000000000000 > 0) {
                result = (result * 0x10058C86DA1C09EA2) >> 64;
            }
            if (x & 0x40000000000000 > 0) {
                result = (result * 0x1002C605E2E8CEC50) >> 64;
            }
            if (x & 0x20000000000000 > 0) {
                result = (result * 0x100162F3904051FA1) >> 64;
            }
            if (x & 0x10000000000000 > 0) {
                result = (result * 0x1000B175EFFDC76BA) >> 64;
            }
            if (x & 0x8000000000000 > 0) {
                result = (result * 0x100058BA01FB9F96D) >> 64;
            }
            if (x & 0x4000000000000 > 0) {
                result = (result * 0x10002C5CC37DA9492) >> 64;
            }
            if (x & 0x2000000000000 > 0) {
                result = (result * 0x1000162E525EE0547) >> 64;
            }
            if (x & 0x1000000000000 > 0) {
                result = (result * 0x10000B17255775C04) >> 64;
            }
            if (x & 0x800000000000 > 0) {
                result = (result * 0x1000058B91B5BC9AE) >> 64;
            }
            if (x & 0x400000000000 > 0) {
                result = (result * 0x100002C5C89D5EC6D) >> 64;
            }
            if (x & 0x200000000000 > 0) {
                result = (result * 0x10000162E43F4F831) >> 64;
            }
            if (x & 0x100000000000 > 0) {
                result = (result * 0x100000B1721BCFC9A) >> 64;
            }
            if (x & 0x80000000000 > 0) {
                result = (result * 0x10000058B90CF1E6E) >> 64;
            }
            if (x & 0x40000000000 > 0) {
                result = (result * 0x1000002C5C863B73F) >> 64;
            }
            if (x & 0x20000000000 > 0) {
                result = (result * 0x100000162E430E5A2) >> 64;
            }
            if (x & 0x10000000000 > 0) {
                result = (result * 0x1000000B172183551) >> 64;
            }
            if (x & 0x8000000000 > 0) {
                result = (result * 0x100000058B90C0B49) >> 64;
            }
            if (x & 0x4000000000 > 0) {
                result = (result * 0x10000002C5C8601CC) >> 64;
            }
            if (x & 0x2000000000 > 0) {
                result = (result * 0x1000000162E42FFF0) >> 64;
            }
            if (x & 0x1000000000 > 0) {
                result = (result * 0x10000000B17217FBB) >> 64;
            }
            if (x & 0x800000000 > 0) {
                result = (result * 0x1000000058B90BFCE) >> 64;
            }
            if (x & 0x400000000 > 0) {
                result = (result * 0x100000002C5C85FE3) >> 64;
            }
            if (x & 0x200000000 > 0) {
                result = (result * 0x10000000162E42FF1) >> 64;
            }
            if (x & 0x100000000 > 0) {
                result = (result * 0x100000000B17217F8) >> 64;
            }
            if (x & 0x80000000 > 0) {
                result = (result * 0x10000000058B90BFC) >> 64;
            }
            if (x & 0x40000000 > 0) {
                result = (result * 0x1000000002C5C85FE) >> 64;
            }
            if (x & 0x20000000 > 0) {
                result = (result * 0x100000000162E42FF) >> 64;
            }
            if (x & 0x10000000 > 0) {
                result = (result * 0x1000000000B17217F) >> 64;
            }
            if (x & 0x8000000 > 0) {
                result = (result * 0x100000000058B90C0) >> 64;
            }
            if (x & 0x4000000 > 0) {
                result = (result * 0x10000000002C5C860) >> 64;
            }
            if (x & 0x2000000 > 0) {
                result = (result * 0x1000000000162E430) >> 64;
            }
            if (x & 0x1000000 > 0) {
                result = (result * 0x10000000000B17218) >> 64;
            }
            if (x & 0x800000 > 0) {
                result = (result * 0x1000000000058B90C) >> 64;
            }
            if (x & 0x400000 > 0) {
                result = (result * 0x100000000002C5C86) >> 64;
            }
            if (x & 0x200000 > 0) {
                result = (result * 0x10000000000162E43) >> 64;
            }
            if (x & 0x100000 > 0) {
                result = (result * 0x100000000000B1721) >> 64;
            }
            if (x & 0x80000 > 0) {
                result = (result * 0x10000000000058B91) >> 64;
            }
            if (x & 0x40000 > 0) {
                result = (result * 0x1000000000002C5C8) >> 64;
            }
            if (x & 0x20000 > 0) {
                result = (result * 0x100000000000162E4) >> 64;
            }
            if (x & 0x10000 > 0) {
                result = (result * 0x1000000000000B172) >> 64;
            }
            if (x & 0x8000 > 0) {
                result = (result * 0x100000000000058B9) >> 64;
            }
            if (x & 0x4000 > 0) {
                result = (result * 0x10000000000002C5D) >> 64;
            }
            if (x & 0x2000 > 0) {
                result = (result * 0x1000000000000162E) >> 64;
            }
            if (x & 0x1000 > 0) {
                result = (result * 0x10000000000000B17) >> 64;
            }
            if (x & 0x800 > 0) {
                result = (result * 0x1000000000000058C) >> 64;
            }
            if (x & 0x400 > 0) {
                result = (result * 0x100000000000002C6) >> 64;
            }
            if (x & 0x200 > 0) {
                result = (result * 0x10000000000000163) >> 64;
            }
            if (x & 0x100 > 0) {
                result = (result * 0x100000000000000B1) >> 64;
            }
            if (x & 0x80 > 0) {
                result = (result * 0x10000000000000059) >> 64;
            }
            if (x & 0x40 > 0) {
                result = (result * 0x1000000000000002C) >> 64;
            }
            if (x & 0x20 > 0) {
                result = (result * 0x10000000000000016) >> 64;
            }
            if (x & 0x10 > 0) {
                result = (result * 0x1000000000000000B) >> 64;
            }
            if (x & 0x8 > 0) {
                result = (result * 0x10000000000000006) >> 64;
            }
            if (x & 0x4 > 0) {
                result = (result * 0x10000000000000003) >> 64;
            }
            if (x & 0x2 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
            if (x & 0x1 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }

            // We're doing two things at the same time:
            //
            //   1. Multiply the result by 2^n + 1, where "2^n" is the integer part and the one is added to account for
            //      the fact that we initially set the result to 0.5. This is accomplished by subtracting from 191
            //      rather than 192.
            //   2. Convert the result to the unsigned 60.18-decimal fixed-point format.
            //
            // This works because 2^(191-ip) = 2^ip / 2^191, where "ip" is the integer part "2^n".
            result *= SCALE;
            result >>= (191 - (x >> 64));
        }
    }

    /// @notice Finds the zero-based index of the first one in the binary representation of x.
    /// @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
    /// @param x The uint256 number for which to find the index of the most significant bit.
    /// @return msb The index of the most significant bit as an uint256.
    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The multiplicand as an uint256.
    /// @param y The multiplier as an uint256.
    /// @param denominator The divisor as an uint256.
    /// @return result The result as an uint256.
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
            unchecked {
                result = prod0 / denominator;
            }
            return result;
        }

        // Make sure the result is less than 2^256. Also prevents denominator == 0.
        if (prod1 >= denominator) {
            revert PRBMath__MulDivOverflow(prod1, denominator);
        }

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
        unchecked {
            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 lpotdod = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by lpotdod.
                denominator := div(denominator, lpotdod)

                // Divide [prod1 prod0] by lpotdod.
                prod0 := div(prod0, lpotdod)

                // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one.
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * lpotdod;

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

    /// @notice Calculates floor(x*y÷1e18) with full precision.
    ///
    /// @dev Variant of "mulDiv" with constant folding, i.e. in which the denominator is always 1e18. Before returning the
    /// final result, we add 1 if (x * y) % SCALE >= HALF_SCALE. Without this, 6.6e-19 would be truncated to 0 instead of
    /// being rounded to 1e-18.  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717.
    ///
    /// Requirements:
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    /// - It is assumed that the result can never be type(uint256).max when x and y solve the following two equations:
    ///     1. x * y = type(uint256).max * SCALE
    ///     2. (x * y) % SCALE >= SCALE / 2
    ///
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function mulDivFixedPoint(uint256 x, uint256 y) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= SCALE) {
            revert PRBMath__MulDivFixedPointOverflow(prod1);
        }

        uint256 remainder;
        uint256 roundUpUnit;
        assembly {
            remainder := mulmod(x, y, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }

        if (prod1 == 0) {
            unchecked {
                result = (prod0 / SCALE) + roundUpUnit;
                return result;
            }
        }

        assembly {
            result := add(
                mul(
                    or(
                        div(sub(prod0, remainder), SCALE_LPOTD),
                        mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1))
                    ),
                    SCALE_INVERSE
                ),
                roundUpUnit
            )
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev An extension of "mulDiv" for signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - None of the inputs can be type(int256).min.
    /// - The result must fit within int256.
    ///
    /// @param x The multiplicand as an int256.
    /// @param y The multiplier as an int256.
    /// @param denominator The divisor as an int256.
    /// @return result The result as an int256.
    function mulDivSigned(
        int256 x,
        int256 y,
        int256 denominator
    ) internal pure returns (int256 result) {
        if (x == type(int256).min || y == type(int256).min || denominator == type(int256).min) {
            revert PRBMath__MulDivSignedInputTooSmall();
        }

        // Get hold of the absolute values of x, y and the denominator.
        uint256 ax;
        uint256 ay;
        uint256 ad;
        unchecked {
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);
            ad = denominator < 0 ? uint256(-denominator) : uint256(denominator);
        }

        // Compute the absolute value of (x*y)÷denominator. The result must fit within int256.
        uint256 rAbs = mulDiv(ax, ay, ad);
        if (rAbs > uint256(type(int256).max)) {
            revert PRBMath__MulDivSignedOverflow(rAbs);
        }

        // Get the signs of x, y and the denominator.
        uint256 sx;
        uint256 sy;
        uint256 sd;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
            sd := sgt(denominator, sub(0, 1))
        }

        // XOR over sx, sy and sd. This is checking whether there are one or three negative signs in the inputs.
        // If yes, the result should be negative.
        result = sx ^ sy ^ sd == 0 ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The uint256 number for which to calculate the square root.
    /// @return result The result as an uint256.
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // Set the initial guess to the closest power of two that is higher than x.
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }
}