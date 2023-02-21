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
pragma solidity ^0.8.16;

import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import './abstract/JBControllerUtility.sol';
import './interfaces/IJBFundAccessConstraintsStore.sol';

/**
  @notice
  Information pertaining to how much funds can be accessed by a project from each payment terminal.
  
  @dev
  Adheres to -
  IJBFundAccessConstraintsStore: General interface for the generic controller methods in this contract that interacts with funding cycles and tokens according to the protocol's rules.

  @dev
  Inherits from -
  JBControllerUtility: Several functions in this contract can only be accessed by a project owner, or an address that has been preconfifigured to be an operator of the project.
  ERC165: Introspection on interface adherance. 
*/
contract JBFundAccessConstraintsStore is
  JBControllerUtility,
  ERC165,
  IJBFundAccessConstraintsStore
{
  //*********************************************************************//
  // --------------------------- custom errors ------------------------- //
  //*********************************************************************//

  error INVALID_DISTRIBUTION_LIMIT();
  error INVALID_DISTRIBUTION_LIMIT_CURRENCY();
  error INVALID_OVERFLOW_ALLOWANCE();
  error INVALID_OVERFLOW_ALLOWANCE_CURRENCY();

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
  // ------------------------- external views -------------------------- //
  //*********************************************************************//

  /**
    @notice
    The amount of token that a project can distribute per funding cycle, and the currency it's in terms of.

    @dev
    The number of decimals in the returned fixed point amount is the same as that of the specified terminal. 

    @param _projectId The ID of the project to get the distribution limit of.
    @param _configuration The configuration during which the distribution limit applies.
    @param _terminal The terminal from which distributions are being limited.
    @param _token The token for which the distribution limit applies.

    @return The distribution limit, as a fixed point number with the same number of decimals as the provided terminal.
    @return The currency of the distribution limit.
  */
  function distributionLimitOf(
    uint256 _projectId,
    uint256 _configuration,
    IJBPaymentTerminal _terminal,
    address _token
  ) external view override returns (uint256, uint256) {
    // Get a reference to the packed data.
    uint256 _data = _packedDistributionLimitDataOf[_projectId][_configuration][_terminal][_token];

    // The limit is in bits 0-231. The currency is in bits 232-255.
    return (uint256(uint232(_data)), _data >> 232);
  }

  /**
    @notice
    The amount of overflow that a project is allowed to tap into on-demand throughout a configuration, and the currency it's in terms of.

    @dev
    The number of decimals in the returned fixed point amount is the same as that of the specified terminal. 

    @param _projectId The ID of the project to get the overflow allowance of.
    @param _configuration The configuration of the during which the allowance applies.
    @param _terminal The terminal managing the overflow.
    @param _token The token for which the overflow allowance applies.

    @return The overflow allowance, as a fixed point number with the same number of decimals as the provided terminal.
    @return The currency of the overflow allowance.
  */
  function overflowAllowanceOf(
    uint256 _projectId,
    uint256 _configuration,
    IJBPaymentTerminal _terminal,
    address _token
  ) external view override returns (uint256, uint256) {
    // Get a reference to the packed data.
    uint256 _data = _packedOverflowAllowanceDataOf[_projectId][_configuration][_terminal][_token];

    // The allowance is in bits 0-231. The currency is in bits 232-255.
    return (uint256(uint232(_data)), _data >> 232);
  }

  //*********************************************************************//
  // -------------------------- constructor ---------------------------- //
  //*********************************************************************//

  /** 
    @param _directory A contract storing directories of terminals and controllers for each project.
  */
  // solhint-disable-next-line no-empty-blocks
  constructor(IJBDirectory _directory) JBControllerUtility(_directory) {}

  //*********************************************************************//
  // --------------------- external transactions ----------------------- //
  //*********************************************************************//

  /**
    @notice
    Sets a project's constraints for accessing treasury funds.

    @dev
    Only a project's current controller can set its fund access constraints.

    @param _projectId The ID of the project whose fund access constraints are being set.
    @param _configuration The funding cycle configuration the constraints apply within.
    @param _fundAccessConstraints An array containing amounts that a project can use from its treasury for each payment terminal. Amounts are fixed point numbers using the same number of decimals as the accompanying terminal. The `_distributionLimit` and `_overflowAllowance` parameters must fit in a `uint232`.
  */
  function setFor(
    uint256 _projectId,
    uint256 _configuration,
    JBFundAccessConstraints[] calldata _fundAccessConstraints
  ) external override onlyController(_projectId) {
    // Save the number of constraints.
    uint256 _numberOfFundAccessConstraints = _fundAccessConstraints.length;

    // Set distribution limits if there are any.
    for (uint256 _i; _i < _numberOfFundAccessConstraints; ) {
      // If distribution limit value is larger than 232 bits, revert.
      if (_fundAccessConstraints[_i].distributionLimit > type(uint232).max) revert INVALID_DISTRIBUTION_LIMIT();

      // If distribution limit currency value is larger than 24 bits, revert.
      if (_fundAccessConstraints[_i].distributionLimitCurrency > type(uint24).max)
        revert INVALID_DISTRIBUTION_LIMIT_CURRENCY();

      // If overflow allowance value is larger than 232 bits, revert.
      if (_fundAccessConstraints[_i].overflowAllowance > type(uint232).max) revert INVALID_OVERFLOW_ALLOWANCE();

      // If overflow allowance currency value is larger than 24 bits, revert.
      if (_fundAccessConstraints[_i].overflowAllowanceCurrency > type(uint24).max)
        revert INVALID_OVERFLOW_ALLOWANCE_CURRENCY();

      // Set the distribution limit if there is one.
      if (_fundAccessConstraints[_i].distributionLimit > 0)
        _packedDistributionLimitDataOf[_projectId][_configuration][_fundAccessConstraints[_i].terminal][
          _fundAccessConstraints[_i].token
        ] = _fundAccessConstraints[_i].distributionLimit | (_fundAccessConstraints[_i].distributionLimitCurrency << 232);

      // Set the overflow allowance if there is one.
      if (_fundAccessConstraints[_i].overflowAllowance > 0)
        _packedOverflowAllowanceDataOf[_projectId][_configuration][_fundAccessConstraints[_i].terminal][
          _fundAccessConstraints[_i].token
        ] = _fundAccessConstraints[_i].overflowAllowance | (_fundAccessConstraints[_i].overflowAllowanceCurrency << 232);

      emit SetFundAccessConstraints(_configuration, _projectId, _fundAccessConstraints[_i], msg.sender);

      unchecked {
        ++_i;
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import './../interfaces/IJBControllerUtility.sol';

/** 
  @notice
  Provides tools for contracts with functionality that can only be accessed by a project's controller.

  @dev
  Adheres to -
  IJBControllerUtility: General interface for the methods in this contract that interact with the blockchain's state according to the protocol's rules.
*/
abstract contract JBControllerUtility is IJBControllerUtility {
  //*********************************************************************//
  // --------------------------- custom errors -------------------------- //
  //*********************************************************************//
  error CONTROLLER_UNAUTHORIZED();

  //*********************************************************************//
  // ---------------------------- modifiers ---------------------------- //
  //*********************************************************************//

  /** 
    @notice
    Only allows the controller of the specified project to proceed. 

    @param _projectId The ID of the project. 
  */
  modifier onlyController(uint256 _projectId) {
    if (address(directory.controllerOf(_projectId)) != msg.sender) revert CONTROLLER_UNAUTHORIZED();
    _;
  }

  //*********************************************************************//
  // ---------------- public immutable stored properties --------------- //
  //*********************************************************************//

  /** 
    @notice 
    The directory of terminals and controllers for projects.
  */
  IJBDirectory public immutable override directory;

  //*********************************************************************//
  // -------------------------- constructor ---------------------------- //
  //*********************************************************************//

  /** 
    @param _directory A contract storing directories of terminals and controllers for each project.
  */
  constructor(IJBDirectory _directory) {
    directory = _directory;
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

import './IJBDirectory.sol';

interface IJBControllerUtility {
  function directory() external view returns (IJBDirectory);
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

interface IJBTokenUriResolver {
  function getUri(uint256 _projectId) external view returns (string memory tokenUri);
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

/** 
  @member content The metadata content.
  @member domain The domain within which the metadata applies.
*/
struct JBProjectMetadata {
  string content;
  uint256 domain;
}