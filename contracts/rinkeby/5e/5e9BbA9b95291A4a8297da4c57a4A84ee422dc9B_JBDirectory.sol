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
pragma solidity 0.8.6;

import '@openzeppelin/contracts/access/Ownable.sol';

import './abstract/JBOperatable.sol';
import './libraries/JBOperations.sol';
import './libraries/JBFundingCycleMetadataResolver.sol';
import './interfaces/IJBDirectory.sol';

//*********************************************************************//
// --------------------------- custom errors ------------------------- //
//*********************************************************************//
error INVALID_PROJECT_ID_IN_DIRECTORY();
error DUPLICATE_TERMINALS();
error SET_CONTROLLER_NOT_ALLOWED();
error SET_TERMINALS_NOT_ALLOWED();

/**
  @notice
  Keeps a reference of which terminal contracts each project is currently accepting funds through, and which controller contract is managing each project's tokens and funding cycles.

  @dev
  Adheres to:
  IJBDirectory: General interface for the methods in this contract that interact with the blockchain's state according to the protocol's rules.

  @dev
  Inherits from:
  JBOperatable: Includes convenience functionality for checking a message sender's permissions before executing certain transactions.
  Ownable: Includes convenience functionality for checking a message sender's permissions before executing certain transactions.
*/
contract JBDirectory is IJBDirectory, JBOperatable, Ownable {
  // A library that parses the packed funding cycle metadata into a friendlier format.
  using JBFundingCycleMetadataResolver for JBFundingCycle;

  //*********************************************************************//
  // --------------------- private stored properties ------------------- //
  //*********************************************************************//

  /**
    @notice
    For each project ID, the terminals that are currently managing its funds.

    _projectId The ID of the project to get terminals of.
  */
  mapping(uint256 => IJBPaymentTerminal[]) private _terminalsOf;

  /**
    @notice
    The project's primary terminal for a token.

    _projectId The ID of the project to get the primary terminal of.
    _token The token to get the project's primary terminal of.
  */
  mapping(uint256 => mapping(address => IJBPaymentTerminal)) private _primaryTerminalOf;

  //*********************************************************************//
  // ---------------- public immutable stored properties --------------- //
  //*********************************************************************//

  /**
    @notice
    The Projects contract which mints ERC-721's that represent project ownership and transfers.
  */
  IJBProjects public immutable override projects;

  /**
    @notice
    The contract storing all funding cycle configurations.
  */
  IJBFundingCycleStore public immutable override fundingCycleStore;

  //*********************************************************************//
  // --------------------- public stored properties -------------------- //
  //*********************************************************************//

  /** 
    @notice 
    For each project ID, the controller that manages how terminals interact with tokens and funding cycles.

    _projectId The ID of the project to get the controller of.
  */
  mapping(uint256 => IJBController) public override controllerOf;

  /**
    @notice
    Addresses that can set a project's first controller on their behalf. These addresses/contracts have been vetted and verified by this contract's owner.

    _address The address that is either allowed or not.
  */
  mapping(address => bool) public override isAllowedToSetFirstController;

  //*********************************************************************//
  // ------------------------- external views -------------------------- //
  //*********************************************************************//

  /**
    @notice
    For each project ID, the terminals that are currently managing its funds.

    @param _projectId The ID of the project to get terminals of.

    @return An array of terminal addresses.
  */
  function terminalsOf(uint256 _projectId)
    external
    view
    override
    returns (IJBPaymentTerminal[] memory)
  {
    return _terminalsOf[_projectId];
  }

  /**
    @notice
    Whether or not a specified terminal is a terminal of the specified project.

    @param _projectId The ID of the project to check within.
    @param _terminal The address of the terminal to check for.

    @return A flag indicating whether or not the specified terminal is a terminal of the specified project.
  */
  function isTerminalOf(uint256 _projectId, IJBPaymentTerminal _terminal)
    public
    view
    override
    returns (bool)
  {
    for (uint256 _i; _i < _terminalsOf[_projectId].length; _i++)
      if (_terminalsOf[_projectId][_i] == _terminal) return true;
    return false;
  }

  /**
    @notice
    The primary terminal that is managing funds for a project for a specified token.

    @dev
    The zero address is returned if a terminal isn't found for the specified token.

    @param _projectId The ID of the project to get a terminal for.
    @param _token The token the terminal accepts.

    @return The primary terminal for the project for the specified token.
  */
  function primaryTerminalOf(uint256 _projectId, address _token)
    public
    view
    override
    returns (IJBPaymentTerminal)
  {
    // If a primary terminal for the token was specifically set, return it.
    if (_primaryTerminalOf[_projectId][_token] != IJBPaymentTerminal(address(0)))
      return _primaryTerminalOf[_projectId][_token];

    // Return the first terminal which accepts the specified token.
    for (uint256 _i; _i < _terminalsOf[_projectId].length; _i++) {
      IJBPaymentTerminal _terminal = _terminalsOf[_projectId][_i];
      if (_terminal.token() == _token) return _terminal;
    }

    // Not found.
    return IJBPaymentTerminal(address(0));
  }

  //*********************************************************************//
  // -------------------------- constructor ---------------------------- //
  //*********************************************************************//

  /**
    @param _operatorStore A contract storing operator assignments.
    @param _projects A contract which mints ERC-721's that represent project ownership and transfers.
    @param _fundingCycleStore A contract storing all funding cycle configurations.
    @param _owner The address that will own the contract.
  */
  constructor(
    IJBOperatorStore _operatorStore,
    IJBProjects _projects,
    IJBFundingCycleStore _fundingCycleStore,
    address _owner
  ) JBOperatable(_operatorStore) {
    projects = _projects;
    fundingCycleStore = _fundingCycleStore;

    _transferOwnership(_owner);
  }

  /**
    @notice
    Update the controller that manages how terminals interact with the ecosystem.

    @dev
    A controller can be set if:
    - the message sender is the project owner or an operator having the correct authorization.
    - the message sender is the project's current controller.
    - or, an allowedlisted address is setting a controller for a project that doesn't already have a controller.

    @param _projectId The ID of the project to set a new controller for.
    @param _controller The new controller to set.
  */
  function setControllerOf(uint256 _projectId, IJBController _controller)
    external
    override
    requirePermissionAllowingOverride(
      projects.ownerOf(_projectId),
      _projectId,
      JBOperations.SET_CONTROLLER,
      (msg.sender == address(controllerOf[_projectId]) ||
        (isAllowedToSetFirstController[msg.sender] &&
          controllerOf[_projectId] == IJBController(address(0))))
    )
  {
    // The project must exist.
    if (projects.count() < _projectId) revert INVALID_PROJECT_ID_IN_DIRECTORY();

    // Get a reference to the project's current funding cycle.
    JBFundingCycle memory _fundingCycle = fundingCycleStore.currentOf(_projectId);

    // Setting controller must be allowed if not called from the current controller or if the project already has a controller.
    if (
      msg.sender != address(controllerOf[_projectId]) &&
      controllerOf[_projectId] != IJBController(address(0)) &&
      !_fundingCycle.setControllerAllowed()
    ) revert SET_CONTROLLER_NOT_ALLOWED();

    // Set the new controller.
    controllerOf[_projectId] = _controller;

    emit SetController(_projectId, _controller, msg.sender);
  }

  /** 
    @notice 
    Set a project's terminals.

    @dev
    Only a project owner, an operator, or its controller can set its terminals.

    @param _projectId The ID of the project having terminals set.
    @param _terminals The terminal to set.
  */
  function setTerminalsOf(uint256 _projectId, IJBPaymentTerminal[] calldata _terminals)
    external
    override
    requirePermissionAllowingOverride(
      projects.ownerOf(_projectId),
      _projectId,
      JBOperations.SET_TERMINALS,
      msg.sender == address(controllerOf[_projectId])
    )
  {
    // Get a reference to the project's current funding cycle.
    JBFundingCycle memory _fundingCycle = fundingCycleStore.currentOf(_projectId);

    // Setting terminals must be allowed if not called from the current controller.
    if (msg.sender != address(controllerOf[_projectId]) && !_fundingCycle.setTerminalsAllowed())
      revert SET_TERMINALS_NOT_ALLOWED();

    // Get a reference to the terminals of the project.
    IJBPaymentTerminal[] memory _oldTerminals = _terminalsOf[_projectId];

    // Delete the stored terminals for the project.
    _terminalsOf[_projectId] = _terminals;

    // Make sure duplicates were not added.
    if (_terminals.length > 1)
      for (uint256 _i; _i < _terminals.length; _i++)
        for (uint256 _j = _i + 1; _j < _terminals.length; _j++)
          if (_terminals[_i] == _terminals[_j]) revert DUPLICATE_TERMINALS();

    // If one of the old terminals was set as a primary terminal but is not included in the new terminals, remove it from being a primary terminal.
    for (uint256 _i; _i < _oldTerminals.length; _i++)
      if (
        _primaryTerminalOf[_projectId][_oldTerminals[_i].token()] == _oldTerminals[_i] &&
        !_contains(_terminals, _oldTerminals[_i])
      ) delete _primaryTerminalOf[_projectId][_oldTerminals[_i].token()];

    emit SetTerminals(_projectId, _terminals, msg.sender);
  }

  /**
    @notice
    Project's can set which terminal should be their primary for a particular token.
    This is useful in case a project has several terminals connected for a particular token.

    @dev
    The terminal will be set as the primary terminal where ecosystem contracts should route tokens.

    @dev
    If setting a newly added terminal and the funding cycle doesn't allow new terminals, the caller must be the current controller.

    @param _projectId The ID of the project for which a primary token is being set.
    @param _terminal The terminal to make primary.
  */
  function setPrimaryTerminalOf(uint256 _projectId, IJBPaymentTerminal _terminal)
    external
    override
    requirePermission(projects.ownerOf(_projectId), _projectId, JBOperations.SET_PRIMARY_TERMINAL)
  {
    // Get a reference to the token that the terminal accepts.
    address _token = _terminal.token();

    // Add the terminal to the project if it hasn't been already.
    _addTerminalIfNeeded(_projectId, _terminal);

    // Store the terminal as the primary for the particular token.
    _primaryTerminalOf[_projectId][_token] = _terminal;

    emit SetPrimaryTerminal(_projectId, _token, _terminal, msg.sender);
  }

  /** 
    @notice	
    Set a contract to the list of trusted addresses that can set a first controller for any project.	

    @dev
    The owner can add addresses which are allowed to change projects' first controllers. 
    These addresses are known and vetted controllers as well as contracts designed to launch new projects. 
    A project can set its own controller without it being on the allow list.

    @dev
    If you would like an address/contract allowlisted, please reach out to the contract owner.

    @param _address The address to allow or revoke allowance from.
    @param _flag Whether allowance is being added or revoked.
  */
  function setIsAllowedToSetFirstController(address _address, bool _flag)
    external
    override
    onlyOwner
  {
    // Set the flag in the allowlist.
    isAllowedToSetFirstController[_address] = _flag;

    emit SetIsAllowedToSetFirstController(_address, _flag, msg.sender);
  }

  //*********************************************************************//
  // --------------------- private helper functions -------------------- //
  //*********************************************************************//

  /**
    @notice
    Add a terminal to a project's list of terminals if it hasn't been already.

    @param _projectId The ID of the project having a terminal added.
    @param _terminal The terminal to add.
  */
  function _addTerminalIfNeeded(uint256 _projectId, IJBPaymentTerminal _terminal) private {
    // Check that the terminal has not already been added.
    if (isTerminalOf(_projectId, _terminal)) return;

    // Get a reference to the project's current funding cycle.
    JBFundingCycle memory _fundingCycle = fundingCycleStore.currentOf(_projectId);

    // Setting terminals must be allowed if not called from the current controller.
    if (msg.sender != address(controllerOf[_projectId]) && !_fundingCycle.setTerminalsAllowed())
      revert SET_TERMINALS_NOT_ALLOWED();

    // Add the new terminal.
    _terminalsOf[_projectId].push(_terminal);

    emit AddTerminal(_projectId, _terminal, msg.sender);
  }

  /** 
    @notice
    Check if the provided terminal array contains the provided terminal.

    @param _terminals The terminals to look through.
    @param _terminal The terminal to check for.

    @return Whether or not the `_terminals` includes the `_terminal`.
  */
  function _contains(IJBPaymentTerminal[] calldata _terminals, IJBPaymentTerminal _terminal)
    private
    pure
    returns (bool)
  {
    for (uint256 _i; _i < _terminals.length; _i++) if (_terminals[_i] == _terminal) return true;
    return false;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBOperatable.sol';

// --------------------------- custom errors -------------------------- //
//*********************************************************************//
error UNAUTHORIZED();

/** 
  @notice
  Modifiers to allow access to functions based on the message sender's operator status.
*/
abstract contract JBOperatable is IJBOperatable {
  modifier requirePermission(
    address _account,
    uint256 _domain,
    uint256 _permissionIndex
  ) {
    _requirePermission(_account, _domain, _permissionIndex);
    _;
  }

  modifier requirePermissionAllowingOverride(
    address _account,
    uint256 _domain,
    uint256 _permissionIndex,
    bool _override
  ) {
    _requirePermissionAllowingOverride(_account, _domain, _permissionIndex, _override);
    _;
  }

  /** 
    @notice 
    A contract storing operator assignments.
  */
  IJBOperatorStore public immutable override operatorStore;

  /** 
    @param _operatorStore A contract storing operator assignments.
  */
  constructor(IJBOperatorStore _operatorStore) {
    operatorStore = _operatorStore;
  }

  /** 
    @notice
    Require the message sender is either the account or has the specified permission.

    @param _account The account to allow.
    @param _domain The domain within which the permission index will be checked.
    @param _domain The permission index that an operator must have within the specified domain to be allowed.
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
    @param _domain The domain within which the permission index will be checked.
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
pragma solidity 0.8.6;

enum JBBallotState {
  Approved,
  Active,
  Failed
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../structs/JBFundingCycleData.sol';
import './../structs/JBFundingCycleMetadata.sol';
import './../structs/JBProjectMetadata.sol';
import './../structs/JBGroupedSplits.sol';
import './../structs/JBFundAccessConstraints.sol';
import './IJBDirectory.sol';
import './IJBToken.sol';
import './IJBPaymentTerminal.sol';
import './IJBFundingCycleStore.sol';
import './IJBTokenStore.sol';
import './IJBSplitsStore.sol';

interface IJBController {
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
    uint256 indexed fundingCycleConfiguration,
    uint256 indexed fundingCycleNumber,
    uint256 indexed projectId,
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

  event Migrate(uint256 indexed projectId, IJBController to, address caller);

  event PrepMigration(uint256 indexed projectId, IJBController from, address caller);

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
    IJBPaymentTerminal _terminal
  ) external view returns (uint256 distributionLimit, uint256 distributionLimitCurrency);

  function overflowAllowanceOf(
    uint256 _projectId,
    uint256 _configuration,
    IJBPaymentTerminal _terminal
  ) external view returns (uint256 overflowAllowance, uint256 overflowAllowanceCurrency);

  function totalOutstandingTokensOf(uint256 _projectId, uint256 _reservedRate)
    external
    view
    returns (uint256);

  function currentFundingCycleOf(uint256 _projectId)
    external
    returns (JBFundingCycle memory fundingCycle, JBFundingCycleMetadata memory metadata);

  function queuedFundingCycleOf(uint256 _projectId)
    external
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

  function issueTokenFor(
    uint256 _projectId,
    string calldata _name,
    string calldata _symbol
  ) external returns (IJBToken token);

  function changeTokenOf(
    uint256 _projectId,
    IJBToken _token,
    address _newOwner
  ) external;

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

  function prepForMigrationOf(uint256 _projectId, IJBController _from) external;

  function migrate(uint256 _projectId, IJBController _to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBPaymentTerminal.sol';
import './IJBProjects.sol';
import './IJBFundingCycleStore.sol';
import './IJBController.sol';

interface IJBDirectory {
  event SetController(uint256 indexed projectId, IJBController indexed controller, address caller);

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

  function controllerOf(uint256 _projectId) external view returns (IJBController);

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

  function setControllerOf(uint256 _projectId, IJBController _controller) external;

  function setTerminalsOf(uint256 _projectId, IJBPaymentTerminal[] calldata _terminals) external;

  function setPrimaryTerminalOf(uint256 _projectId, IJBPaymentTerminal _terminal) external;

  function setIsAllowedToSetFirstController(address _address, bool _flag) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../enums/JBBallotState.sol';

interface IJBFundingCycleBallot {
  function duration() external view returns (uint256);

  function stateOf(uint256 _projectId, uint256 _configuration)
    external
    view
    returns (JBBallotState);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBFundingCycleStore.sol';

import './IJBPayDelegate.sol';
import './IJBRedemptionDelegate.sol';

import './../structs/JBPayParamsData.sol';
import './../structs/JBRedeemParamsData.sol';

interface IJBFundingCycleDataSource {
  function payParams(JBPayParamsData calldata _data)
    external
    view
    returns (
      uint256 weight,
      string memory memo,
      IJBPayDelegate delegate
    );

  function redeemParams(JBRedeemParamsData calldata _data)
    external
    view
    returns (
      uint256 reclaimAmount,
      string memory memo,
      IJBRedemptionDelegate delegate
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBFundingCycleBallot.sol';
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

  function queuedOf(uint256 _projectId) external view returns (JBFundingCycle memory);

  function currentOf(uint256 _projectId) external view returns (JBFundingCycle memory);

  function currentBallotStateOf(uint256 _projectId) external view returns (JBBallotState);

  function configureFor(
    uint256 _projectId,
    JBFundingCycleData calldata _data,
    uint256 _metadata,
    uint256 _mustStartAtOrAfter
  ) external returns (JBFundingCycle memory fundingCycle);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBOperatorStore.sol';

interface IJBOperatable {
  function operatorStore() external view returns (IJBOperatorStore);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

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
pragma solidity 0.8.6;

import './../structs/JBDidPayData.sol';

interface IJBPayDelegate {
  function didPay(JBDidPayData calldata _data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBDirectory.sol';

interface IJBPaymentTerminal {
  function token() external view returns (address);

  function currency() external view returns (uint256);

  function decimals() external view returns (uint256);

  // Return value must be a fixed point number with 18 decimals.
  function currentEthOverflowOf(uint256 _projectId) external view returns (uint256);

  function pay(
    uint256 _amount,
    uint256 _projectId,
    address _beneficiary,
    uint256 _minReturnedTokens,
    bool _preferClaimedTokens,
    string calldata _memo,
    bytes calldata _metadata
  ) external payable returns (uint256 beneficiaryTokenCount);

  function addToBalanceOf(
    uint256 _projectId,
    uint256 _amount,
    string calldata _memo
  ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

import './IJBPaymentTerminal.sol';
import './IJBTokenUriResolver.sol';

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

  event SetTokenUriResolver(IJBTokenUriResolver resolver, address caller);

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
pragma solidity 0.8.6;

import './IJBFundingCycleStore.sol';

import './../structs/JBDidRedeemData.sol';

interface IJBRedemptionDelegate {
  function didRedeem(JBDidRedeemData calldata _data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '../structs/JBSplitAllocationData.sol';

interface IJBSplitAllocator {
  function allocate(JBSplitAllocationData calldata _data) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBOperatorStore.sol';
import './IJBProjects.sol';
import './IJBDirectory.sol';
import './IJBSplitAllocator.sol';

import './../structs/JBSplit.sol';

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
    uint256 _group,
    JBSplit[] memory _splits
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IJBToken {
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

  function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

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

  event ShouldRequireClaim(uint256 indexed projectId, bool indexed flag, address caller);

  event Change(
    uint256 indexed projectId,
    IJBToken indexed newToken,
    IJBToken indexed oldToken,
    address owner,
    address caller
  );

  event Transfer(
    address indexed holder,
    uint256 indexed projectId,
    address indexed recipient,
    uint256 amount,
    address caller
  );

  function tokenOf(uint256 _projectId) external view returns (IJBToken);

  function projectOf(IJBToken _token) external view returns (uint256);

  function projects() external view returns (IJBProjects);

  function unclaimedBalanceOf(address _holder, uint256 _projectId) external view returns (uint256);

  function unclaimedTotalSupplyOf(uint256 _projectId) external view returns (uint256);

  function totalSupplyOf(uint256 _projectId) external view returns (uint256);

  function balanceOf(address _holder, uint256 _projectId) external view returns (uint256 _result);

  function requireClaimFor(uint256 _projectId) external view returns (bool);

  function issueFor(
    uint256 _projectId,
    string calldata _name,
    string calldata _symbol
  ) external returns (IJBToken token);

  function changeFor(
    uint256 _projectId,
    IJBToken _token,
    address _newOwner
  ) external returns (IJBToken oldToken);

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

  function shouldRequireClaimingFor(uint256 _projectId, bool _flag) external;

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
pragma solidity 0.8.6;

interface IJBTokenUriResolver {
  function getUri(uint256 _projectId) external view returns (string memory tokenUri);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/**
  @notice
  Global constants used across multiple Juicebox contracts.
*/
library JBConstants {
  /** 
    @notice
    Maximum value for reserved, redemption, and ballot redemption rates. Does not include discount rate.
  */
  uint256 public constant MAX_RESERVED_RATE = 10000;

  /**
    @notice
    Maximum token redemption rate.  
    */
  uint256 public constant MAX_REDEMPTION_RATE = 10000;

  /** 
    @notice
    A funding cycle's discount rate is expressed as a percentage out of 1000000000.
  */
  uint256 public constant MAX_DISCOUNT_RATE = 1000000000;

  /** 
    @notice
    Maximum splits percentage.
  */
  uint256 public constant SPLITS_TOTAL_PERCENT = 1000000000;

  /** 
    @notice
    Maximum fee rate as a percentage out of 1000000000
  */
  uint256 public constant MAX_FEE = 1000000000;

  /** 
    @notice
    Maximum discount on fee granted by a gauge.
  */
  uint256 public constant MAX_FEE_DISCOUNT = 1000000000;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './JBConstants.sol';
import './../interfaces/IJBFundingCycleStore.sol';
import './../interfaces/IJBFundingCycleDataSource.sol';
import './../structs/JBFundingCycleMetadata.sol';

library JBFundingCycleMetadataResolver {
  function reservedRate(JBFundingCycle memory _fundingCycle) internal pure returns (uint256) {
    return uint256(uint16(_fundingCycle.metadata >> 8));
  }

  function redemptionRate(JBFundingCycle memory _fundingCycle) internal pure returns (uint256) {
    // Redemption rate is a number 0-10000. It's inverse was stored so the most common case of 100% results in no storage needs.
    return JBConstants.MAX_REDEMPTION_RATE - uint256(uint16(_fundingCycle.metadata >> 24));
  }

  function ballotRedemptionRate(JBFundingCycle memory _fundingCycle)
    internal
    pure
    returns (uint256)
  {
    // Redemption rate is a number 0-10000. It's inverse was stored so the most common case of 100% results in no storage needs.
    return JBConstants.MAX_REDEMPTION_RATE - uint256(uint16(_fundingCycle.metadata >> 40));
  }

  function payPaused(JBFundingCycle memory _fundingCycle) internal pure returns (bool) {
    return ((_fundingCycle.metadata >> 56) & 1) == 1;
  }

  function distributionsPaused(JBFundingCycle memory _fundingCycle) internal pure returns (bool) {
    return ((_fundingCycle.metadata >> 57) & 1) == 1;
  }

  function redeemPaused(JBFundingCycle memory _fundingCycle) internal pure returns (bool) {
    return ((_fundingCycle.metadata >> 58) & 1) == 1;
  }

  function burnPaused(JBFundingCycle memory _fundingCycle) internal pure returns (bool) {
    return ((_fundingCycle.metadata >> 59) & 1) == 1;
  }

  function mintingAllowed(JBFundingCycle memory _fundingCycle) internal pure returns (bool) {
    return ((_fundingCycle.metadata >> 60) & 1) == 1;
  }

  function changeTokenAllowed(JBFundingCycle memory _fundingCycle) internal pure returns (bool) {
    return ((_fundingCycle.metadata >> 61) & 1) == 1;
  }

  function terminalMigrationAllowed(JBFundingCycle memory _fundingCycle)
    internal
    pure
    returns (bool)
  {
    return ((_fundingCycle.metadata >> 62) & 1) == 1;
  }

  function controllerMigrationAllowed(JBFundingCycle memory _fundingCycle)
    internal
    pure
    returns (bool)
  {
    return ((_fundingCycle.metadata >> 63) & 1) == 1;
  }

  function setTerminalsAllowed(JBFundingCycle memory _fundingCycle) internal pure returns (bool) {
    return ((_fundingCycle.metadata >> 64) & 1) == 1;
  }

  function setControllerAllowed(JBFundingCycle memory _fundingCycle) internal pure returns (bool) {
    return ((_fundingCycle.metadata >> 65) & 1) == 1;
  }

  function shouldHoldFees(JBFundingCycle memory _fundingCycle) internal pure returns (bool) {
    return ((_fundingCycle.metadata >> 66) & 1) == 1;
  }

  function useTotalOverflowForRedemptions(JBFundingCycle memory _fundingCycle)
    internal
    pure
    returns (bool)
  {
    return ((_fundingCycle.metadata >> 67) & 1) == 1;
  }

  function useDataSourceForPay(JBFundingCycle memory _fundingCycle) internal pure returns (bool) {
    return (_fundingCycle.metadata >> 68) & 1 == 1;
  }

  function useDataSourceForRedeem(JBFundingCycle memory _fundingCycle)
    internal
    pure
    returns (bool)
  {
    return (_fundingCycle.metadata >> 69) & 1 == 1;
  }

  function dataSource(JBFundingCycle memory _fundingCycle)
    internal
    pure
    returns (IJBFundingCycleDataSource)
  {
    return IJBFundingCycleDataSource(address(uint160(_fundingCycle.metadata >> 70)));
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
    // reserved rate in bits 8-23 (16 bits).
    packed |= _metadata.reservedRate << 8;
    // redemption rate in bits 24-39 (16 bits).
    // redemption rate is a number 0-10000. Store the reverse so the most common case of 100% results in no storage needs.
    packed |= (JBConstants.MAX_REDEMPTION_RATE - _metadata.redemptionRate) << 24;
    // ballot redemption rate rate in bits 40-55 (16 bits).
    // ballot redemption rate is a number 0-10000. Store the reverse so the most common case of 100% results in no storage needs.
    packed |= (JBConstants.MAX_REDEMPTION_RATE - _metadata.ballotRedemptionRate) << 40;
    // pause pay in bit 56.
    if (_metadata.pausePay) packed |= 1 << 56;
    // pause tap in bit 57.
    if (_metadata.pauseDistributions) packed |= 1 << 57;
    // pause redeem in bit 58.
    if (_metadata.pauseRedeem) packed |= 1 << 58;
    // pause burn in bit 59.
    if (_metadata.pauseBurn) packed |= 1 << 59;
    // allow minting in bit 60.
    if (_metadata.allowMinting) packed |= 1 << 60;
    // pause change token in bit 61.
    if (_metadata.allowChangeToken) packed |= 1 << 61;
    // allow terminal migration in bit 62.
    if (_metadata.allowTerminalMigration) packed |= 1 << 62;
    // allow controller migration in bit 63.
    if (_metadata.allowControllerMigration) packed |= 1 << 63;
    // allow set terminals in bit 64.
    if (_metadata.allowSetTerminals) packed |= 1 << 64;
    // allow set controller in bit 65.
    if (_metadata.allowSetController) packed |= 1 << 65;
    // hold fees in bit 66.
    if (_metadata.holdFees) packed |= 1 << 66;
    // useTotalOverflowForRedemptions in bit 67.
    if (_metadata.useTotalOverflowForRedemptions) packed |= 1 << 67;
    // use pay data source in bit 68.
    if (_metadata.useDataSourceForPay) packed |= 1 << 68;
    // use redeem data source in bit 69.
    if (_metadata.useDataSourceForRedeem) packed |= 1 << 69;
    // data source address in bits 70-229.
    packed |= uint256(uint160(address(_metadata.dataSource))) << 70;
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
    returns (JBFundingCycleMetadata memory metadata)
  {
    return
      JBFundingCycleMetadata(
        reservedRate(_fundingCycle),
        redemptionRate(_fundingCycle),
        ballotRedemptionRate(_fundingCycle),
        payPaused(_fundingCycle),
        distributionsPaused(_fundingCycle),
        redeemPaused(_fundingCycle),
        burnPaused(_fundingCycle),
        mintingAllowed(_fundingCycle),
        changeTokenAllowed(_fundingCycle),
        terminalMigrationAllowed(_fundingCycle),
        controllerMigrationAllowed(_fundingCycle),
        setTerminalsAllowed(_fundingCycle),
        setControllerAllowed(_fundingCycle),
        shouldHoldFees(_fundingCycle),
        useTotalOverflowForRedemptions(_fundingCycle),
        useDataSourceForPay(_fundingCycle),
        useDataSourceForRedeem(_fundingCycle),
        dataSource(_fundingCycle)
      );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

library JBOperations {
  uint256 public constant RECONFIGURE = 1;
  uint256 public constant REDEEM = 2;
  uint256 public constant MIGRATE_CONTROLLER = 3;
  uint256 public constant MIGRATE_TERMINAL = 4;
  uint256 public constant PROCESS_FEES = 5;
  uint256 public constant SET_METADATA = 6;
  uint256 public constant ISSUE = 7;
  uint256 public constant CHANGE_TOKEN = 8;
  uint256 public constant MINT = 9;
  uint256 public constant BURN = 10;
  uint256 public constant CLAIM = 11;
  uint256 public constant TRANSFER = 12;
  uint256 public constant REQUIRE_CLAIM = 13;
  uint256 public constant SET_CONTROLLER = 14;
  uint256 public constant SET_TERMINALS = 15;
  uint256 public constant SET_PRIMARY_TERMINAL = 16;
  uint256 public constant USE_ALLOWANCE = 17;
  uint256 public constant SET_SPLITS = 18;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

library JBSplitsGroups {
  uint256 public constant ETH_PAYOUT = 1;
  uint256 public constant RESERVED_TOKENS = 2;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './JBTokenAmount.sol';

struct JBDidPayData {
  // The address from which the payment originated.
  address payer;
  // The ID of the project for which the payment was made.
  uint256 projectId;
  // The amount of the payment. Includes the token being paid, the value, the number of decimals included, and the currency of the amount.
  JBTokenAmount amount;
  // The number of project tokens minted for the beneficiary.
  uint256 projectTokenCount;
  // The address to which the tokens were minted.
  address beneficiary;
  // The memo that is being emitted alongside the payment.
  string memo;
  // Metadata to send to the delegate.
  bytes metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './JBTokenAmount.sol';

struct JBDidRedeemData {
  // The holder of the tokens being redeemed.
  address holder;
  // The project to which the redeemed tokens are associated.
  uint256 projectId;
  // The number of project tokens being redeemed.
  uint256 projectTokenCount;
  // The reclaimed amount. Includes the token being paid, the value, the number of decimals included, and the currency of the amount.
  JBTokenAmount reclaimedAmount;
  // The address to which the reclaimed amount will be sent.
  address payable beneficiary;
  // The memo that is being emitted alongside the redemption.
  string memo;
  // Metadata to send to the delegate.
  bytes metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBPaymentTerminal.sol';

struct JBFundAccessConstraints {
  // The terminal within which the distribution limit and the overflow allowance applies.
  IJBPaymentTerminal terminal;
  // The amount of the distribution limit, as a fixed point number with the same number of decimals as the terminal within which the limit applies.
  uint256 distributionLimit;
  // The currency of the distribution limit.
  uint256 distributionLimitCurrency;
  // The amount of the allowance, as a fixed point number with the same number of decimals as the terminal within which the allowance applies.
  uint256 overflowAllowance;
  // The currency of the overflow allowance.
  uint256 overflowAllowanceCurrency;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBFundingCycleBallot.sol';

struct JBFundingCycle {
  // The funding cycle number for each project.
  // Each funding cycle has a number that is an increment of the cycle that directly preceded it.
  // Each project's first funding cycle has a number of 1.
  uint256 number;
  // The timestamp when the parameters for this funding cycle were configured.
  // This value will stay the same for subsequent funding cycles that roll over from an originally configured cycle.
  uint256 configuration;
  // The `configuration` of the funding cycle that was active when this cycle was created.
  uint256 basedOn;
  // The timestamp marking the moment from which the funding cycle is considered active.
  // It is a unix timestamp measured in seconds.
  uint256 start;
  // The number of seconds the funding cycle lasts for, after which a new funding cycle will start.
  // A duration of 0 means that the funding cycle will stay active until the project owner explicitly issues a reconfiguration, at which point a new funding cycle will immediately start with the updated properties.
  // If the duration is greater than 0, a project owner cannot make changes to a funding cycle's parameters while it is active – any proposed changes will apply to the subsequent cycle.
  // If no changes are proposed, a funding cycle rolls over to another one with the same properties but new `start` timestamp and a discounted `weight`.
  uint256 duration;
  // A fixed point number with 18 decimals that contracts can use to base arbitrary calculations on.
  // For example, payment terminals can use this to determine how many tokens should be minted when a payment is received.
  uint256 weight;
  // A percent by how much the `weight` of the subsequent funding cycle should be reduced, if the project owner hasn't configured the subsequent funding cycle with an explicit `weight`.
  // If it's 0, each funding cycle will have equal weight.
  // If the number is 90%, the next funding cycle will have a 10% smaller weight.
  // This weight is out of `JBConstants.MAX_DISCOUNT_RATE`.
  uint256 discountRate;
  // An address of a contract that says whether a proposed reconfiguration should be accepted or rejected.
  // It can be used to create rules around how a project owner can change funding cycle parameters over time.
  IJBFundingCycleBallot ballot;
  // Extra data that can be associated with a funding cycle.
  uint256 metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBFundingCycleBallot.sol';

struct JBFundingCycleData {
  // The number of seconds the funding cycle lasts for, after which a new funding cycle will start.
  // A duration of 0 means that the funding cycle will stay active until the project owner explicitly issues a reconfiguration, at which point a new funding cycle will immediately start with the updated properties.
  // If the duration is greater than 0, a project owner cannot make changes to a funding cycle's parameters while it is active – any proposed changes will apply to the subsequent cycle.
  // If no changes are proposed, a funding cycle rolls over to another one with the same properties but new `start` timestamp and a discounted `weight`.
  uint256 duration;
  // A fixed point number with 18 decimals that contracts can use to base arbitrary calculations on.
  // For example, payment terminals can use this to determine how many tokens should be minted when a payment is received.
  uint256 weight;
  // A percent by how much the `weight` of the subsequent funding cycle should be reduced, if the project owner hasn't configured the subsequent funding cycle with an explicit `weight`.
  // If it's 0, each funding cycle will have equal weight.
  // If the number is 90%, the next funding cycle will have a 10% smaller weight.
  // This weight is out of `JBConstants.MAX_DISCOUNT_RATE`.
  uint256 discountRate;
  // An address of a contract that says whether a proposed reconfiguration should be accepted or rejected.
  // It can be used to create rules around how a project owner can change funding cycle parameters over time.
  IJBFundingCycleBallot ballot;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBFundingCycleDataSource.sol';

struct JBFundingCycleMetadata {
  // The reserved rate of the funding cycle. This number is a percentage calculated out of `JBConstants.MAX_RESERVED_RATE`.
  uint256 reservedRate;
  // The redemption rate of the funding cycle. This number is a percentage calculated out of `JBConstants.MAX_REDEMPTION_RATE`.
  uint256 redemptionRate;
  // The redemption rate to use during an active ballot of the funding cycle. This number is a percentage calculated out of `JBConstants.MAX_REDEMPTION_RATE`.
  uint256 ballotRedemptionRate;
  // If the pay functionality should be paused during the funding cycle.
  bool pausePay;
  // If the distribute functionality should be paused during the funding cycle.
  bool pauseDistributions;
  // If the redeem functionality should be paused during the funding cycle.
  bool pauseRedeem;
  // If the burn functionality should be paused during the funding cycle.
  bool pauseBurn;
  // If the mint functionality should be allowed during the funding cycle.
  bool allowMinting;
  // If changing tokens should be allowed during this funding cycle.
  bool allowChangeToken;
  // If migrating terminals should be allowed during this funding cycle.
  bool allowTerminalMigration;
  // If migrating controllers should be allowed during this funding cycle.
  bool allowControllerMigration;
  // If setting terminals should be allowed during this funding cycle.
  bool allowSetTerminals;
  // If setting a new controller should be allowed during this funding cycle.
  bool allowSetController;
  // If fees should be held during this funding cycle.
  bool holdFees;
  // If redemptions should use the project's balance held in all terminals instead of the project's local terminal balance from which the redemption is being fulfilled.
  bool useTotalOverflowForRedemptions;
  // If the data source should be used for pay transactions during this funding cycle.
  bool useDataSourceForPay;
  // If the data source should be used for redeem transactions during this funding cycle.
  bool useDataSourceForRedeem;
  // The data source to use during this funding cycle.
  IJBFundingCycleDataSource dataSource;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './JBSplit.sol';
import '../libraries/JBSplitsGroups.sol';

struct JBGroupedSplits {
  // The group indentifier.
  uint256 group;
  // The splits to associate with the group.
  JBSplit[] splits;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

struct JBOperatorData {
  // The address of the operator.
  address operator;
  // The domain within which the operator is being given permissions.
  // A domain of 0 is a wildcard domain, which gives an operator access to all domains.
  uint256 domain;
  // The indexes of the permissions the operator is being given.
  uint256[] permissionIndexes;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBPaymentTerminal.sol';

import './JBTokenAmount.sol';

struct JBPayParamsData {
  // The terminal that is facilitating the payment.
  IJBPaymentTerminal terminal;
  // The address from which the payment originated.
  address payer;
  // The amount of the payment. Includes the token being paid, the value, the number of decimals included, and the currency of the amount.
  JBTokenAmount amount;
  // The ID of the project being paid.
  uint256 projectId;
  // The weight of the funding cycle during which the payment is being made.
  uint256 weight;
  // The reserved rate of the funding cycle during which the payment is being made.
  uint256 reservedRate;
  // The memo that was sent alongside the payment.
  string memo;
  // Arbitrary metadata provided by the payer.
  bytes metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

struct JBProjectMetadata {
  // Metadata content.
  string content;
  // The domain within which the metadata applies.
  uint256 domain;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBPaymentTerminal.sol';

struct JBRedeemParamsData {
  // The terminal that is facilitating the redemption.
  IJBPaymentTerminal terminal;
  // The holder of the tokens being redeemed.
  address holder;
  // The ID of the project whos tokens are being redeemed.
  uint256 projectId;
  // The proposed number of tokens being redeemed, as a fixed point number with 18 decimals.
  uint256 tokenCount;
  // The total supply of tokens used in the calculation, as a fixed point number with 18 decimals.
  uint256 totalSupply;
  // The amount of overflow used in the reclaim amount calculation.
  uint256 overflow;
  // The number of decimals included in the reclaim amount fixed point number.
  uint256 decimals;
  // The currency that the reclaim amount is expected to be in terms of.
  uint256 currency;
  // The amount that should be reclaimed by the redeemer using the protocol's standard bonding curve redemption formula.
  uint256 reclaimAmount;
  // If overflow across all of a project's terminals is being used when making redemptions.
  bool useTotalOverflow;
  // The redemption rate of the funding cycle during which the redemption is being made.
  uint256 redemptionRate;
  // The ballot redemption rate of the funding cycle during which the redemption is being made.
  uint256 ballotRedemptionRate;
  // The proposed memo that is being emitted alongside the redemption.
  string memo;
  // Arbitrary metadata provided by the redeemer.
  bytes metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBSplitAllocator.sol';

struct JBSplit {
  // A flag that only has effect if a projectId is also specified, and the project has a token contract attached.
  // If so, this flag indicates if the tokens that result from making a payment to the project should be delivered claimed into the beneficiary's wallet, or unclaimed to save gas.
  bool preferClaimed;
  // The percent of the whole group that this split occupies. This number is out of `JBConstants.SPLITS_TOTAL_PERCENT`.
  uint256 percent;
  // If an allocator is not set but a projectId is set, funds will be sent to the protocol treasury belonging to the project who's ID is specified.
  // Resulting tokens will be routed to the beneficiary with the claimed token preference respected.
  uint256 projectId;
  // The role the of the beneficary depends on whether or not projectId is specified, and whether or not an allocator is specified.
  // If allocator is set, the beneficiary will be forwarded to the allocator for it to use.
  // If allocator is not set but projectId is set, the beneficiary is the address to which the project's tokens will be sent that result from a payment to it.
  // If neither allocator or projectId are set, the beneficiary is where the funds from the split will be sent.
  address payable beneficiary;
  // Specifies if the split should be unchangeable until the specified time, with the exception of extending the locked period.
  uint256 lockedUntil;
  // If an allocator is specified, funds will be sent to the allocator contract along with all properties of this split.
  IJBSplitAllocator allocator;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './JBSplit.sol';
import './JBTokenAmount.sol';

struct JBSplitAllocationData {
  // The amount being sent to the split allocator, as a fixed point number.
  uint256 amount;
  // The number of decimals in the amount.
  uint256 decimals;
  // The project to which the split belongs.
  uint256 projectId;
  // The group to which the split belongs.
  uint256 group;
  // The split that caused the allocation.
  JBSplit split;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

struct JBTokenAmount {
  // The token the payment was made in.
  address token;
  // The amount of tokens that was paid, as a fixed point number.
  uint256 value;
  // The number of decimals included in the value fixed point number.
  uint256 decimals;
  // The expected currency of the value.
  uint256 currency;
}