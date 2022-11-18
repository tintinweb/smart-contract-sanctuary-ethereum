// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721Upgradeable.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
interface IERC165Upgradeable {
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

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/IAccessControl.sol";

/// @title Cake access control
/// @author landakram
/// @notice This contact centralizes contract-to-contract access control using a simple
/// access-control list. There are two types of actors: operators and admins. Operators
/// are callers involved in a regular end-user tx. This would likely be another Goldfinch
/// contract for which the current contract is a dependency. Admins are callers allowed
/// for specific admin actions (like changing parameters, topping up funds, etc.).
contract AccessControl is Initializable, IAccessControl {
  /// @dev Mapping from contract address to contract admin;
  mapping(address => address) public admins;

  function initialize(address admin) public initializer {
    admins[address(this)] = admin;
    emit AdminSet(address(this), admin);
  }

  /// @inheritdoc IAccessControl
  function setAdmin(address resource, address admin) external {
    requireSuperAdmin(msg.sender);
    admins[resource] = admin;
    emit AdminSet(resource, admin);
  }

  /// @inheritdoc IAccessControl
  function requireAdmin(address resource, address accessor) public view {
    if (accessor == address(0)) revert ZeroAddress();
    bool isAdmin = admins[resource] == accessor;
    if (!isAdmin) revert RequiresAdmin(resource, accessor);
  }

  /// @inheritdoc IAccessControl
  function requireSuperAdmin(address accessor) public view {
    // The super admin is the admin of this AccessControl contract
    requireAdmin({resource: address(this), accessor: accessor});
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {AccessControl} from "./AccessControl.sol";
import {Router} from "./Router.sol";
import "./Routing.sol" as Routing;

using Routing.Context for Context;

/// @title Entry-point for all application-layer contracts.
/// @author landakram
/// @notice This contract provides an interface for retrieving other contract addresses and doing access
///  control.
contract Context {
  /// @notice Used for retrieving other contract addresses.
  /// @dev This variable is immutable. This is done to save gas, as it is expected to be referenced
  /// in every end-user call with a call-chain length > 0. Note that it is written into the contract
  /// bytecode at contract creation time, so if the contract is deployed as the implementation for proxies,
  /// every proxy will share the same Router address.
  Router public immutable router;

  constructor(Router _router) {
    router = _router;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControl} from "./AccessControl.sol";
import {IRouter} from "../interfaces/IRouter.sol";

import "./Routing.sol" as Routing;

/// @title Router
/// @author landakram
/// @notice This contract provides service discovery for contracts using the cake framework.
///   It can be used in conjunction with the convenience methods defined in the `Routing.Context`
///   and `Routing.Keys` libraries.
contract Router is Initializable, IRouter {
  /// @notice Mapping of keys to contract addresses. Keys are the first 4 bytes of the keccak of
  ///   the contract's name. See Routing.sol for all options.
  mapping(bytes4 => address) public contracts;

  function initialize(AccessControl accessControl) public initializer {
    contracts[Routing.Keys.AccessControl] = address(accessControl);
  }

  /// @notice Associate a routing key to a contract address
  /// @dev This function is only callable by the Router admin
  /// @param key A routing key (defined in the `Routing.Keys` libary)
  /// @param addr A contract address
  function setContract(bytes4 key, address addr) public {
    AccessControl accessControl = AccessControl(contracts[Routing.Keys.AccessControl]);
    accessControl.requireAdmin(address(this), msg.sender);
    contracts[key] = addr;
    emit SetContract(key, addr);
  }
}

// SPDX-License-Identifier: MIT
// solhint-disable const-name-snakecase

pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";

import {IMembershipVault} from "../interfaces/IMembershipVault.sol";
import {IGFILedger} from "../interfaces/IGFILedger.sol";
import {ICapitalLedger} from "../interfaces/ICapitalLedger.sol";
import {IMembershipDirector} from "../interfaces/IMembershipDirector.sol";
import {IMembershipOrchestrator} from "../interfaces/IMembershipOrchestrator.sol";
import {IMembershipLedger} from "../interfaces/IMembershipLedger.sol";
import {IMembershipCollector} from "../interfaces/IMembershipCollector.sol";

import {ISeniorPool} from "../interfaces/ISeniorPool.sol";
import {IPoolTokens} from "../interfaces/IPoolTokens.sol";
import {IStakingRewards} from "../interfaces/IStakingRewards.sol";

import {IERC20Splitter} from "../interfaces/IERC20Splitter.sol";
import {Context as ContextContract} from "./Context.sol";
import {IAccessControl} from "../interfaces/IAccessControl.sol";

import {Router} from "./Router.sol";

/// @title Routing.Keys
/// @notice This library is used to define routing keys used by `Router`.
/// @dev We use uints instead of enums for several reasons. First, keys can be re-ordered
///   or removed. This is useful when routing keys are deprecated; they can be moved to a
///   different section of the file. Second, other libraries or contracts can define their
///   own routing keys independent of this global mapping. This is useful for test contracts.
library Keys {
  // Membership
  bytes4 internal constant MembershipOrchestrator = bytes4(keccak256("MembershipOrchestrator"));
  bytes4 internal constant MembershipDirector = bytes4(keccak256("MembershipDirector"));
  bytes4 internal constant GFILedger = bytes4(keccak256("GFILedger"));
  bytes4 internal constant CapitalLedger = bytes4(keccak256("CapitalLedger"));
  bytes4 internal constant MembershipCollector = bytes4(keccak256("MembershipCollector"));
  bytes4 internal constant MembershipLedger = bytes4(keccak256("MembershipLedger"));
  bytes4 internal constant MembershipVault = bytes4(keccak256("MembershipVault"));

  // Tokens
  bytes4 internal constant GFI = bytes4(keccak256("GFI"));
  bytes4 internal constant FIDU = bytes4(keccak256("FIDU"));
  bytes4 internal constant USDC = bytes4(keccak256("USDC"));

  // Cake
  bytes4 internal constant AccessControl = bytes4(keccak256("AccessControl"));
  bytes4 internal constant Router = bytes4(keccak256("Router"));

  // Core
  bytes4 internal constant ReserveSplitter = bytes4(keccak256("ReserveSplitter"));
  bytes4 internal constant PoolTokens = bytes4(keccak256("PoolTokens"));
  bytes4 internal constant SeniorPool = bytes4(keccak256("SeniorPool"));
  bytes4 internal constant StakingRewards = bytes4(keccak256("StakingRewards"));
  bytes4 internal constant ProtocolAdmin = bytes4(keccak256("ProtocolAdmin"));
  bytes4 internal constant PauserAdmin = bytes4(keccak256("PauserAdmin"));
}

/// @title Routing.Context
/// @notice This library provides convenience functions for getting contracts from `Router`.
library Context {
  function accessControl(ContextContract context) internal view returns (IAccessControl) {
    return IAccessControl(context.router().contracts(Keys.AccessControl));
  }

  function membershipVault(ContextContract context) internal view returns (IMembershipVault) {
    return IMembershipVault(context.router().contracts(Keys.MembershipVault));
  }

  function capitalLedger(ContextContract context) internal view returns (ICapitalLedger) {
    return ICapitalLedger(context.router().contracts(Keys.CapitalLedger));
  }

  function gfiLedger(ContextContract context) internal view returns (IGFILedger) {
    return IGFILedger(context.router().contracts(Keys.GFILedger));
  }

  function gfi(ContextContract context) internal view returns (IERC20Upgradeable) {
    return IERC20Upgradeable(context.router().contracts(Keys.GFI));
  }

  function membershipDirector(ContextContract context) internal view returns (IMembershipDirector) {
    return IMembershipDirector(context.router().contracts(Keys.MembershipDirector));
  }

  function membershipOrchestrator(ContextContract context) internal view returns (IMembershipOrchestrator) {
    return IMembershipOrchestrator(context.router().contracts(Keys.MembershipOrchestrator));
  }

  function stakingRewards(ContextContract context) internal view returns (IStakingRewards) {
    return IStakingRewards(context.router().contracts(Keys.StakingRewards));
  }

  function poolTokens(ContextContract context) internal view returns (IPoolTokens) {
    return IPoolTokens(context.router().contracts(Keys.PoolTokens));
  }

  function seniorPool(ContextContract context) internal view returns (ISeniorPool) {
    return ISeniorPool(context.router().contracts(Keys.SeniorPool));
  }

  function fidu(ContextContract context) internal view returns (IERC20Upgradeable) {
    return IERC20Upgradeable(context.router().contracts(Keys.FIDU));
  }

  function usdc(ContextContract context) internal view returns (IERC20Upgradeable) {
    return IERC20Upgradeable(context.router().contracts(Keys.USDC));
  }

  function reserveSplitter(ContextContract context) internal view returns (IERC20Splitter) {
    return IERC20Splitter(context.router().contracts(Keys.ReserveSplitter));
  }

  function membershipLedger(ContextContract context) internal view returns (IMembershipLedger) {
    return IMembershipLedger(context.router().contracts(Keys.MembershipLedger));
  }

  function membershipCollector(ContextContract context) internal view returns (IMembershipCollector) {
    return IMembershipCollector(context.router().contracts(Keys.MembershipCollector));
  }

  function protocolAdmin(ContextContract context) internal view returns (address) {
    return context.router().contracts(Keys.ProtocolAdmin);
  }

  function pauserAdmin(ContextContract context) internal view returns (address) {
    return context.router().contracts(Keys.PauserAdmin);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/// @title Cake access control
/// @author landakram
/// @notice This contact centralizes contract-to-contract access control using a simple
/// access-control list. There are two types of actors: operators and admins. Operators
/// are callers involved in a regular end-user tx. This would likely be another Goldfinch
/// contract for which the current contract is a dependency. Admins are callers allowed
/// for specific admin actions (like changing parameters, topping up funds, etc.).
interface IAccessControl {
  error RequiresAdmin(address resource, address accessor);
  error ZeroAddress();

  event AdminSet(address indexed resource, address indexed admin);

  /// @notice Set an admin for a given resource
  /// @param resource An address which with `admin` should be allowed to administer
  /// @param admin An address which should be allowed to administer `resource`
  /// @dev This method is only callable by the super-admin (the admin of this AccessControl
  ///   contract)
  function setAdmin(address resource, address admin) external;

  /// @notice Require a valid admin for a given resource
  /// @param resource An address that `accessor` is attempting to access
  /// @param accessor An address on which to assert access control checks
  /// @dev This method reverts when `accessor` is not a valid admin
  function requireAdmin(address resource, address accessor) external view;

  /// @notice Require a super-admin. A super-admin is an admin of this AccessControl contract.
  /// @param accessor An address on which to assert access control checks
  /// @dev This method reverts when `accessor` is not a valid super-admin
  function requireSuperAdmin(address accessor) external view;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

enum CapitalAssetType {
  INVALID,
  ERC721
}

interface ICapitalLedger {
  /**
   * @notice Emitted when a new capital erc721 deposit has been made
   * @param owner address owning the deposit
   * @param assetAddress address of the deposited ERC721
   * @param positionId id for the deposit
   * @param assetTokenId id of the token from the ERC721 `assetAddress`
   * @param usdcEquivalent usdc equivalent value at the time of deposit
   */
  event CapitalERC721Deposit(
    address indexed owner,
    address indexed assetAddress,
    uint256 positionId,
    uint256 assetTokenId,
    uint256 usdcEquivalent
  );

  /**
   * @notice Emitted when a new ERC721 capital withdrawal has been made
   * @param owner address owning the deposit
   * @param positionId id for the capital position
   * @param assetAddress address of the underlying ERC721
   * @param depositTimestamp block.timestamp of the original deposit
   */
  event CapitalERC721Withdrawal(
    address indexed owner,
    uint256 positionId,
    address assetAddress,
    uint256 depositTimestamp
  );

  /// Thrown when called with an invalid asset type for the function. Valid
  /// types are defined under CapitalAssetType
  error InvalidAssetType(CapitalAssetType);

  /**
   * @notice Account for a deposit of `id` for the ERC721 asset at `assetAddress`.
   * @dev reverts with InvalidAssetType if `assetAddress` is not an ERC721
   * @param owner address that owns the position
   * @param assetAddress address of the ERC20 address
   * @param assetTokenId id of the ERC721 asset to add
   * @return id of the newly created position
   */
  function depositERC721(
    address owner,
    address assetAddress,
    uint256 assetTokenId
  ) external returns (uint256);

  /**
   * @notice Get the id of the ERC721 asset held by position `id`. Pair this with
   *  `assetAddressOf` to get the address & id of the nft.
   * @dev reverts with InvalidAssetType if `assetAddress` is not an ERC721
   * @param positionId id of the position
   * @return id of the underlying ERC721 asset
   */
  function erc721IdOf(uint256 positionId) external view returns (uint256);

  /**
   * @notice Completely withdraw a position
   * @param positionId id of the position
   */
  function withdraw(uint256 positionId) external;

  /**
   * @notice Get the asset address of the position. Example: For an ERC721 position, this
   *  returns the address of that ERC721 contract.
   * @param positionId id of the position
   * @return asset address of the position
   */
  function assetAddressOf(uint256 positionId) external view returns (address);

  /**
   * @notice Get the owner of a given position.
   * @param positionId id of the position
   * @return owner of the position
   */
  function ownerOf(uint256 positionId) external view returns (address);

  /**
   * @notice Total number of positions in the ledger
   * @return number of positions in the ledger
   */
  function totalSupply() external view returns (uint256);

  /**
   * @notice Get the number of capital positions held by an address
   * @param addr address
   * @return positions held by address
   */
  function balanceOf(address addr) external view returns (uint256);

  /**
   * @notice Returns a position ID owned by `owner` at a given `index` of its position list
   * @param owner owner of the positions
   * @param index index of the owner's balance to get the position ID of
   * @return position id
   *
   * @dev use with {balanceOf} to enumerate all of `owner`'s positions
   */
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

  /**
   * @dev Returns a position ID at a given `index` of all the positions stored by the contract.
   * @param index index to get the position ID at
   * @return position id
   *
   * @dev use with {totalSupply} to enumerate all positions
   */
  function tokenByIndex(uint256 index) external view returns (uint256);

  /**
   * @notice Get the USDC value of `owner`s positions, reporting what is currently
   *  eligible and the total amount.
   * @param owner address owning the positions
   * @return eligibleAmount USDC value of positions eligible for rewards
   * @return totalAmount total USDC value of positions
   *
   * @dev this is used by Membership to determine how much is eligible in
   *  the current epoch vs the next epoch.
   */
  function totalsOf(address owner) external view returns (uint256 eligibleAmount, uint256 totalAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

interface ICreditLine {
  function borrower() external view returns (address);

  function limit() external view returns (uint256);

  function maxLimit() external view returns (uint256);

  function interestApr() external view returns (uint256);

  function paymentPeriodInDays() external view returns (uint256);

  function principalGracePeriodInDays() external view returns (uint256);

  function termInDays() external view returns (uint256);

  function lateFeeApr() external view returns (uint256);

  function isLate() external view returns (bool);

  function withinPrincipalGracePeriod() external view returns (bool);

  // Accounting variables
  function balance() external view returns (uint256);

  function interestOwed() external view returns (uint256);

  function principalOwed() external view returns (uint256);

  function termEndTime() external view returns (uint256);

  function nextDueTime() external view returns (uint256);

  function interestAccruedAsOf() external view returns (uint256);

  function lastFullPaymentTime() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

interface IERC20Splitter {
  function lastDistributionAt() external view returns (uint256);

  function distribute() external;

  function replacePayees(address[] calldata _payees, uint256[] calldata _shares) external;

  function pendingDistributionFor(address payee) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

interface IGFILedger {
  struct Position {
    // Owner of the position
    address owner;
    // Index of the position in the ownership array
    uint256 ownedIndex;
    // Amount of GFI held in the position
    uint256 amount;
    // When the position was deposited
    uint256 depositTimestamp;
  }

  /**
   * @notice Emitted when a new GFI deposit has been made
   * @param owner address owning the deposit
   * @param positionId id for the deposit
   * @param amount how much GFI was deposited
   */
  event GFIDeposit(address indexed owner, uint256 indexed positionId, uint256 amount);

  /**
   * @notice Emitted when a new GFI withdrawal has been made. If the remaining amount is 0, the position has bee removed
   * @param owner address owning the withdrawn position
   * @param positionId id for the position
   * @param remainingAmount how much GFI is remaining in the position
   * @param depositTimestamp block.timestamp of the original deposit
   */
  event GFIWithdrawal(
    address indexed owner,
    uint256 indexed positionId,
    uint256 withdrawnAmount,
    uint256 remainingAmount,
    uint256 depositTimestamp
  );

  /**
   * @notice Account for a new deposit by the owner.
   * @param owner address to account for the deposit
   * @param amount how much was deposited
   * @return how much was deposited
   */
  function deposit(address owner, uint256 amount) external returns (uint256);

  /**
   * @notice Account for a new withdraw by the owner.
   * @param positionId id of the position
   * @return how much was withdrawn
   */
  function withdraw(uint256 positionId) external returns (uint256);

  /**
   * @notice Account for a new withdraw by the owner.
   * @param positionId id of the position
   * @param amount how much to withdraw
   * @return how much was withdrawn
   */
  function withdraw(uint256 positionId, uint256 amount) external returns (uint256);

  /**
   * @notice Get the number of GFI positions held by an address
   * @param addr address
   * @return positions held by address
   */
  function balanceOf(address addr) external view returns (uint256);

  /**
   * @notice Get the owner of a given position.
   * @param positionId id of the position
   * @return owner of the position
   */
  function ownerOf(uint256 positionId) external view returns (address);

  /**
   * @notice Total number of positions in the ledger
   * @return number of positions in the ledger
   */
  function totalSupply() external view returns (uint256);

  /**
   * @notice Returns a position ID owned by `owner` at a given `index` of its position list
   * @param owner owner of the positions
   * @param index index of the owner's balance to get the position ID of
   * @return position id
   *
   * @dev use with {balanceOf} to enumerate all of `owner`'s positions
   */
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

  /**
   * @dev Returns a position ID at a given `index` of all the positions stored by the contract.
   * @param index index to get the position ID at
   * @return token id
   *
   * @dev use with {totalSupply} to enumerate all positions
   */
  function tokenByIndex(uint256 index) external view returns (uint256);

  /**
   * @notice Get amount of GFI of `owner`s positions, reporting what is currently
   *  eligible and the total amount.
   * @return eligibleAmount GFI amount of positions eligible for rewards
   * @return totalAmount total GFI amount of positions
   *
   * @dev this is used by Membership to determine how much is eligible in
   *  the current epoch vs the next epoch.
   */
  function totalsOf(address owner) external view returns (uint256 eligibleAmount, uint256 totalAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

interface IMembershipCollector {
  /// @notice Have the collector distribute `amount` of Fidu to `addr`
  /// @param addr address to distribute to
  /// @param amount amount to distribute
  function distributeFiduTo(address addr, uint256 amount) external;

  /// @notice Get the last epoch finalized by the collector. This means the
  ///  collector will no longer add rewards to the epoch.
  /// @return the last finalized epoch
  function lastFinalizedEpoch() external view returns (uint256);

  /// @notice Get the rewards associated with `epoch`. This amount may change
  ///  until `epoch` has been finalized (is less than or equal to getLastFinalizedEpoch)
  /// @return rewards associated with `epoch`
  function rewardsForEpoch(uint256 epoch) external view returns (uint256);

  /// @notice Estimate rewards for a given epoch. For epochs at or before lastFinalizedEpoch
  ///  this will be the fixed, accurate reward for the epoch. For the current and other
  ///  non-finalized epochs, this will be the value as if the epoch were finalized in that
  ///  moment.
  /// @param epoch epoch to estimate the rewards of
  /// @return rewards associated with `epoch`
  function estimateRewardsFor(uint256 epoch) external view returns (uint256);

  /// @notice Finalize all unfinalized epochs. Causes the reserve splitter to distribute
  ///  if there are unfinalized epochs so all possible rewards are distributed.
  function finalizeEpochs() external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

interface IMembershipDirector {
  /**
   * @notice Adjust an `owner`s membership score and position due to the change
   *  in their GFI and Capital holdings
   * @param owner address who's holdings changed
   * @return id of membership position
   */
  function consumeHoldingsAdjustment(address owner) external returns (uint256);

  /**
   * @notice Collect all membership yield enhancements for the owner.
   * @param owner address to claim rewards for
   * @return amount of yield enhancements collected
   */
  function collectRewards(address owner) external returns (uint256);

  /**
   * @notice Check how many rewards are claimable for the owner. The return
   *  value here is how much would be retrieved by calling `collectRewards`.
   * @param owner address to calculate claimable rewards for
   * @return the amount of rewards that could be claimed by the owner
   */
  function claimableRewards(address owner) external view returns (uint256);

  /**
   * @notice Calculate the membership score
   * @param gfi Amount of gfi
   * @param capital Amount of capital in USDC
   * @return membership score
   */
  function calculateMembershipScore(uint256 gfi, uint256 capital) external view returns (uint256);

  /**
   * @notice Get the current score of `owner`
   * @param owner address to check the score of
   * @return eligibleScore score that is currently eligible for rewards
   * @return totalScore score that will be elgible for rewards next epoch
   */
  function currentScore(address owner) external view returns (uint256 eligibleScore, uint256 totalScore);

  /**
   * @notice Get the sum of all member scores that are currently eligible and that will be eligible next epoch
   * @return eligibleTotal sum of all member scores that are currently eligible
   * @return nextEpochTotal sum of all member scores that will be eligible next epoch
   */
  function totalMemberScores() external view returns (uint256 eligibleTotal, uint256 nextEpochTotal);

  /**
   * @notice Estimate the score for an existing member, given some changes in GFI and capital
   * @param memberAddress the member's address
   * @param gfi the change in gfi holdings, denominated in GFI
   * @param capital the change in gfi holdings, denominated in USDC
   * @return score resulting score for the member given the GFI and capital changes
   */
  function estimateMemberScore(
    address memberAddress,
    int256 gfi,
    int256 capital
  ) external view returns (uint256 score);

  /// @notice Finalize all unfinalized epochs. Causes the reserve splitter to distribute
  ///  if there are unfinalized epochs so all possible rewards are distributed.
  function finalizeEpochs() external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

interface IMembershipLedger {
  /**
   * @notice Set `addr`s allocated rewards back to 0
   * @param addr address to reset rewards on
   */
  function resetRewards(address addr) external;

  /**
   * @notice Allocate `amount` rewards for `addr` but do not send them
   * @param addr address to distribute rewards to
   * @param amount amount of rewards to allocate for `addr`
   * @return rewards total allocated to `addr`
   */
  function allocateRewardsTo(address addr, uint256 amount) external returns (uint256 rewards);

  /**
   * @notice Get the rewards allocated to a certain `addr`
   * @param addr the address to check pending rewards for
   * @return rewards pending rewards for `addr`
   */
  function getPendingRewardsFor(address addr) external view returns (uint256 rewards);

  /**
   * @notice Get the alpha parameter for the cobb douglas function. Will always be in (0,1).
   * @return numerator numerator for the alpha param
   * @return denominator denominator for the alpha param
   */
  function alpha() external view returns (uint128 numerator, uint128 denominator);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

import {Context} from "../cake/Context.sol";

struct CapitalDeposit {
  /// Address of the asset being deposited
  /// @dev must be supported in CapitalAssets.sol
  address assetAddress;
  /// Id of the nft
  uint256 id;
}

struct Deposit {
  /// Amount of gfi to deposit
  uint256 gfi;
  /// List of capital deposits
  CapitalDeposit[] capitalDeposits;
}

struct DepositResult {
  uint256 membershipId;
  uint256 gfiPositionId;
  uint256[] capitalPositionIds;
}

struct ERC20Withdrawal {
  uint256 id;
  uint256 amount;
}

struct Withdrawal {
  /// List of gfi token ids to withdraw
  ERC20Withdrawal[] gfiPositions;
  /// List of capital token ids to withdraw
  uint256[] capitalPositions;
}

/**
 * @title MembershipOrchestrator
 * @notice Externally facing gateway to all Goldfinch membership functionality.
 * @author Goldfinch
 */
interface IMembershipOrchestrator {
  /**
   * @notice Deposit multiple assets defined in `multiDeposit`. Assets can include GFI, Staked Fidu,
   *  and others.
   * @param deposit struct describing all the assets to deposit
   * @return ids all of the ids of the created depoits, in the same order as deposit. If GFI is
   *  present, it will be the first id.
   */
  function deposit(Deposit calldata deposit) external returns (DepositResult memory);

  /**
   * @notice Withdraw multiple assets defined in `multiWithdraw`. Assets can be GFI or capital
   *  positions ids. Caller must have been permitted to act upon all of the positions.
   * @param withdrawal all of the GFI and Capital ids to withdraw
   */
  function withdraw(Withdrawal calldata withdrawal) external;

  /**
   * @notice Collect all membership rewards for the caller.
   * @return how many rewards were collected and sent to caller
   */
  function collectRewards() external returns (uint256);

  /**
   * @notice Check how many rewards are claimable at this moment in time for caller.
   * @param addr the address to check claimable rewards for
   * @return how many rewards could be claimed by a call to `collectRewards`
   */
  function claimableRewards(address addr) external view returns (uint256);

  /**
   * @notice Check the voting power of a given address
   * @param addr the address to check the voting power of
   * @return the voting power
   */
  function votingPower(address addr) external view returns (uint256);

  /**
   * @notice Get all GFI in Membership held by `addr`. This returns the current eligible amount and the
   *  total amount of GFI.
   * @param addr the owner
   * @return eligibleAmount how much GFI is currently eligible for rewards
   * @return totalAmount how much GFI is currently eligible for rewards
   */
  function totalGFIHeldBy(address addr) external view returns (uint256 eligibleAmount, uint256 totalAmount);

  /**
   * @notice Get all capital, denominated in USDC, in Membership held by `addr`. This returns the current
   *  eligible amount and the total USDC value of capital.
   * @param addr the owner
   * @return eligibleAmount how much USDC of capital is currently eligible for rewards
   * @return totalAmount how much  USDC of capital is currently eligible for rewards
   */
  function totalCapitalHeldBy(address addr) external view returns (uint256 eligibleAmount, uint256 totalAmount);

  /**
   * @notice Get the member score of `addr`
   * @param addr the owner
   * @return eligibleScore the currently eligible score
   * @return totalScore the total score that will be eligible next epoch
   *
   * @dev if eligibleScore == totalScore then there are no changes between now and the next epoch
   */
  function memberScoreOf(address addr) external view returns (uint256 eligibleScore, uint256 totalScore);

  /**
   * @notice Estimate rewards for a given epoch. For epochs at or before lastFinalizedEpoch
   *  this will be the fixed, accurate reward for the epoch. For the current and other
   *  non-finalized epochs, this will be the value as if the epoch were finalized in that
   *  moment.
   * @param epoch epoch to estimate the rewards of
   * @return rewards associated with `epoch`
   */
  function estimateRewardsFor(uint256 epoch) external view returns (uint256);

  /**
   * @notice Calculate what the Membership Score would be if a `gfi` amount of GFI and `capital` amount
   *  of Capital denominated in USDC were deposited.
   * @param gfi amount of GFI to estimate with
   * @param capital amount of capital to estimate with, denominated in USDC
   * @return score the resulting score
   */
  function calculateMemberScore(uint256 gfi, uint256 capital) external view returns (uint256 score);

  /**
   * @notice Get the sum of all member scores that are currently eligible and that will be eligible next epoch
   * @return eligibleTotal sum of all member scores that are currently eligible
   * @return nextEpochTotal sum of all member scores that will be eligible next epoch
   */
  function totalMemberScores() external view returns (uint256 eligibleTotal, uint256 nextEpochTotal);

  /**
   * @notice Estimate the score for an existing member, given some changes in GFI and capital
   * @param memberAddress the member's address
   * @param gfi the change in gfi holdings, denominated in GFI
   * @param capital the change in gfi holdings, denominated in USDC
   * @return score resulting score for the member given the GFI and capital changes
   */
  function estimateMemberScore(
    address memberAddress,
    int256 gfi,
    int256 capital
  ) external view returns (uint256 score);

  /// @notice Finalize all unfinalized epochs. Causes the reserve splitter to distribute
  ///  if there are unfinalized epochs so all possible rewards are distributed.
  function finalizeEpochs() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC721Upgradeable.sol";

struct Position {
  // address owning the position
  address owner;
  // how much of the position is eligible as of checkpointEpoch
  uint256 eligibleAmount;
  // how much of the postion is eligible the epoch after checkpointEpoch
  uint256 nextEpochAmount;
  // when the position was first created
  uint256 createdTimestamp;
  // epoch of the last checkpoint
  uint256 checkpointEpoch;
}

/**
 * @title IMembershipVault
 * @notice Track assets held by owners in a vault, as well as the total held in the vault. Assets
 *  are not accounted for until the next epoch for MEV protection.
 * @author Goldfinch
 */
interface IMembershipVault is IERC721Upgradeable {
  /**
   * @notice Emitted when an owner has adjusted their holdings in a vault
   * @param owner the owner increasing their holdings
   * @param eligibleAmount the new eligible amount
   * @param nextEpochAmount the new next epoch amount
   */
  event AdjustedHoldings(address indexed owner, uint256 eligibleAmount, uint256 nextEpochAmount);

  /**
   * @notice Emitted when the total within the vault has changed
   * @param eligibleAmount new current amount
   * @param nextEpochAmount new next epoch amount
   */
  event VaultTotalUpdate(uint256 eligibleAmount, uint256 nextEpochAmount);

  /**
   * @notice Get the current value of `owner`. This changes depending on the current
   *  block.timestamp as increased holdings are not accounted for until the subsequent epoch.
   * @param owner address owning the positions
   * @return sum of all positions held by an address
   */
  function currentValueOwnedBy(address owner) external view returns (uint256);

  /**
   * @notice Get the total value in the vault as of block.timestamp
   * @return total value in the vault as of block.timestamp
   */
  function currentTotal() external view returns (uint256);

  /**
   * @notice Get the total value in the vault as of epoch
   * @return total value in the vault as of epoch
   */
  function totalAtEpoch(uint256 epoch) external view returns (uint256);

  /**
   * @notice Get the position owned by `owner`
   * @return position owned by `owner`
   */
  function positionOwnedBy(address owner) external view returns (Position memory);

  /**
   * @notice Record an adjustment in holdings. Eligible assets will update this epoch and
   *  total assets will become eligible the subsequent epoch.
   * @param owner the owner to checkpoint
   * @param eligibleAmount amount of points to apply to the current epoch
   * @param nextEpochAmount amount of points to apply to the next epoch
   * @return id of the position
   */
  function adjustHoldings(
    address owner,
    uint256 eligibleAmount,
    uint256 nextEpochAmount
  ) external returns (uint256);

  /**
   * @notice Checkpoint a specific owner & the vault total
   * @param owner the owner to checkpoint
   *
   * @dev to collect rewards, this must be called before `increaseHoldings` or
   *  `decreaseHoldings`. Those functions must call checkpoint internally
   *  so the historical data will be lost otherwise.
   */
  function checkpoint(address owner) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "./openzeppelin/IERC721.sol";

interface IPoolTokens is IERC721 {
  event TokenMinted(
    address indexed owner,
    address indexed pool,
    uint256 indexed tokenId,
    uint256 amount,
    uint256 tranche
  );

  event TokenRedeemed(
    address indexed owner,
    address indexed pool,
    uint256 indexed tokenId,
    uint256 principalRedeemed,
    uint256 interestRedeemed,
    uint256 tranche
  );
  event TokenBurned(address indexed owner, address indexed pool, uint256 indexed tokenId);

  struct TokenInfo {
    address pool;
    uint256 tranche;
    uint256 principalAmount;
    uint256 principalRedeemed;
    uint256 interestRedeemed;
  }

  struct MintParams {
    uint256 principalAmount;
    uint256 tranche;
  }

  function mint(MintParams calldata params, address to) external returns (uint256);

  function redeem(
    uint256 tokenId,
    uint256 principalRedeemed,
    uint256 interestRedeemed
  ) external;

  function withdrawPrincipal(uint256 tokenId, uint256 principalAmount) external;

  function burn(uint256 tokenId) external;

  function onPoolCreated(address newPool) external;

  function getTokenInfo(uint256 tokenId) external view returns (TokenInfo memory);

  function validPool(address sender) external view returns (bool);

  function isApprovedOrOwner(address spender, uint256 tokenId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/// @title IRouter
/// @author landakram
/// @notice This contract provides service discovery for contracts using the cake framework.
///   It can be used in conjunction with the convenience methods defined in the `Routing.Context`
///   and `Routing.Keys` libraries.
interface IRouter {
  event SetContract(bytes4 indexed key, address indexed addr);

  /// @notice Associate a routing key to a contract address
  /// @dev This function is only callable by the Router admin
  /// @param key A routing key (defined in the `Routing.Keys` libary)
  /// @param addr A contract address
  function setContract(bytes4 key, address addr) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "./ITranchedPool.sol";

abstract contract ISeniorPool {
  uint256 public sharePrice;
  uint256 public totalLoansOutstanding;
  uint256 public totalWritedowns;

  function deposit(uint256 amount) external virtual returns (uint256 depositShares);

  function depositWithPermit(
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external virtual returns (uint256 depositShares);

  function withdraw(uint256 usdcAmount) external virtual returns (uint256 amount);

  function withdrawInFidu(uint256 fiduAmount) external virtual returns (uint256 amount);

  function sweepToCompound() public virtual;

  function sweepFromCompound() public virtual;

  function invest(ITranchedPool pool) public virtual;

  function estimateInvestment(ITranchedPool pool) public view virtual returns (uint256);

  function redeem(uint256 tokenId) public virtual;

  function writedown(uint256 tokenId) public virtual;

  function calculateWritedown(uint256 tokenId) public view virtual returns (uint256 writedownAmount);

  function assets() public view virtual returns (uint256);

  function getNumShares(uint256 amount) public view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

pragma experimental ABIEncoderV2;

import {IERC721} from "./openzeppelin/IERC721.sol";
import {IERC721Metadata} from "./openzeppelin/IERC721Metadata.sol";
import {IERC721Enumerable} from "./openzeppelin/IERC721Enumerable.sol";

interface IStakingRewards is IERC721, IERC721Metadata, IERC721Enumerable {
  function getPosition(uint256 tokenId) external view returns (StakedPosition memory position);

  function unstake(uint256 tokenId, uint256 amount) external;

  function addToStake(uint256 tokenId, uint256 amount) external;

  function stakedBalanceOf(uint256 tokenId) external view returns (uint256);

  function depositToCurveAndStakeFrom(
    address nftRecipient,
    uint256 fiduAmount,
    uint256 usdcAmount
  ) external;

  function kick(uint256 tokenId) external;

  function accumulatedRewardsPerToken() external view returns (uint256);

  function lastUpdateTime() external view returns (uint256);

  /* ========== EVENTS ========== */

  event RewardAdded(uint256 reward);
  event Staked(
    address indexed user,
    uint256 indexed tokenId,
    uint256 amount,
    StakedPositionType positionType,
    uint256 baseTokenExchangeRate
  );
  event DepositedAndStaked(address indexed user, uint256 depositedAmount, uint256 indexed tokenId, uint256 amount);
  event DepositedToCurve(address indexed user, uint256 fiduAmount, uint256 usdcAmount, uint256 tokensReceived);
  event DepositedToCurveAndStaked(
    address indexed user,
    uint256 fiduAmount,
    uint256 usdcAmount,
    uint256 indexed tokenId,
    uint256 amount
  );
  event Unstaked(address indexed user, uint256 indexed tokenId, uint256 amount, StakedPositionType positionType);
  event UnstakedMultiple(address indexed user, uint256[] tokenIds, uint256[] amounts);
  event UnstakedAndWithdrew(address indexed user, uint256 usdcReceivedAmount, uint256 indexed tokenId, uint256 amount);
  event UnstakedAndWithdrewMultiple(
    address indexed user,
    uint256 usdcReceivedAmount,
    uint256[] tokenIds,
    uint256[] amounts
  );
  event RewardPaid(address indexed user, uint256 indexed tokenId, uint256 reward);
  event RewardsParametersUpdated(
    address indexed who,
    uint256 targetCapacity,
    uint256 minRate,
    uint256 maxRate,
    uint256 minRateAtPercent,
    uint256 maxRateAtPercent
  );
  event EffectiveMultiplierUpdated(address indexed who, StakedPositionType positionType, uint256 multiplier);
}

/// @notice Indicates which ERC20 is staked
enum StakedPositionType {
  Fidu,
  CurveLP
}

struct Rewards {
  uint256 totalUnvested;
  uint256 totalVested;
  // @dev DEPRECATED (definition kept for storage slot)
  //   For legacy vesting positions, this was used in the case of slashing.
  //   For non-vesting positions, this is unused.
  uint256 totalPreviouslyVested;
  uint256 totalClaimed;
  uint256 startTime;
  // @dev DEPRECATED (definition kept for storage slot)
  //   For legacy vesting positions, this is the endTime of the vesting.
  //   For non-vesting positions, this is 0.
  uint256 endTime;
}

struct StakedPosition {
  // @notice Staked amount denominated in `stakingToken().decimals()`
  uint256 amount;
  // @notice Struct describing rewards owed with vesting
  Rewards rewards;
  // @notice Multiplier applied to staked amount when locking up position
  uint256 leverageMultiplier;
  // @notice Time in seconds after which position can be unstaked
  uint256 lockedUntil;
  // @notice Type of the staked position
  StakedPositionType positionType;
  // @notice Multiplier applied to staked amount to denominate in `baseStakingToken().decimals()`
  // @dev This field should not be used directly; it may be 0 for staked positions created prior to GIP-1.
  //  If you need this field, use `safeEffectiveMultiplier()`, which correctly handles old staked positions.
  uint256 unsafeEffectiveMultiplier;
  // @notice Exchange rate applied to staked amount to denominate in `baseStakingToken().decimals()`
  // @dev This field should not be used directly; it may be 0 for staked positions created prior to GIP-1.
  //  If you need this field, use `safeBaseTokenExchangeRate()`, which correctly handles old staked positions.
  uint256 unsafeBaseTokenExchangeRate;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import {IV2CreditLine} from "./IV2CreditLine.sol";

abstract contract ITranchedPool {
  IV2CreditLine public creditLine;
  uint256 public createdAt;
  enum Tranches {
    Reserved,
    Senior,
    Junior
  }

  struct TrancheInfo {
    uint256 id;
    uint256 principalDeposited;
    uint256 principalSharePrice;
    uint256 interestSharePrice;
    uint256 lockedUntil;
  }

  struct PoolSlice {
    TrancheInfo seniorTranche;
    TrancheInfo juniorTranche;
    uint256 totalInterestAccrued;
    uint256 principalDeployed;
  }

  function initialize(
    address _config,
    address _borrower,
    uint256 _juniorFeePercent,
    uint256 _limit,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr,
    uint256 _principalGracePeriodInDays,
    uint256 _fundableAt,
    uint256[] calldata _allowedUIDTypes
  ) public virtual;

  function getTranche(uint256 tranche) external view virtual returns (TrancheInfo memory);

  function pay(uint256 amount) external virtual;

  function poolSlices(uint256 index) external view virtual returns (PoolSlice memory);

  function lockJuniorCapital() external virtual;

  function lockPool() external virtual;

  function initializeNextSlice(uint256 _fundableAt) external virtual;

  function totalJuniorDeposits() external view virtual returns (uint256);

  function drawdown(uint256 amount) external virtual;

  function setFundableAt(uint256 timestamp) external virtual;

  function deposit(uint256 tranche, uint256 amount) external virtual returns (uint256 tokenId);

  function assess() external virtual;

  function depositWithPermit(
    uint256 tranche,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external virtual returns (uint256 tokenId);

  function availableToWithdraw(uint256 tokenId)
    external
    view
    virtual
    returns (uint256 interestRedeemable, uint256 principalRedeemable);

  function withdraw(uint256 tokenId, uint256 amount)
    external
    virtual
    returns (uint256 interestWithdrawn, uint256 principalWithdrawn);

  function withdrawMax(uint256 tokenId)
    external
    virtual
    returns (uint256 interestWithdrawn, uint256 principalWithdrawn);

  function withdrawMultiple(uint256[] calldata tokenIds, uint256[] calldata amounts) external virtual;

  function numSlices() external view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "./ICreditLine.sol";

abstract contract IV2CreditLine is ICreditLine {
  function principal() external view virtual returns (uint256);

  function totalInterestAccrued() external view virtual returns (uint256);

  function termStartTime() external view virtual returns (uint256);

  function setLimit(uint256 newAmount) external virtual;

  function setMaxLimit(uint256 newAmount) external virtual;

  function setBalance(uint256 newBalance) external virtual;

  function setPrincipal(uint256 _principal) external virtual;

  function setTotalInterestAccrued(uint256 _interestAccrued) external virtual;

  function drawdown(uint256 amount) external virtual;

  function assess()
    external
    virtual
    returns (
      uint256,
      uint256,
      uint256
    );

  function initialize(
    address _config,
    address owner,
    address _borrower,
    uint256 _limit,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr,
    uint256 _principalGracePeriodInDays
  ) public virtual;

  function setTermEndTime(uint256 newTermEndTime) external virtual;

  function setNextDueTime(uint256 newNextDueTime) external virtual;

  function setInterestOwed(uint256 newInterestOwed) external virtual;

  function setPrincipalOwed(uint256 newPrincipalOwed) external virtual;

  function setInterestAccruedAsOf(uint256 newInterestAccruedAsOf) external virtual;

  function setWritedownAmount(uint256 newWritedownAmount) external virtual;

  function setLastFullPaymentTime(uint256 newLastFullPaymentTime) external virtual;

  function setLateFeeApr(uint256 newLateFeeApr) external virtual;
}

pragma solidity >=0.6.0;

// This file copied from OZ, but with the version pragma updated to use >=.

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

pragma solidity >=0.6.2;

// This file copied from OZ, but with the version pragma updated to use >= & reference other >= pragma interfaces.
// NOTE: Modified to reference our updated pragma version of IERC165
import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  /**
   * @dev Returns the number of NFTs in ``owner``'s account.
   */
  function balanceOf(address owner) external view returns (uint256 balance);

  /**
   * @dev Returns the owner of the NFT specified by `tokenId`.
   */
  function ownerOf(uint256 tokenId) external view returns (address owner);

  /**
   * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
   * another (`to`).
   *
   *
   *
   * Requirements:
   * - `from`, `to` cannot be zero.
   * - `tokenId` must be owned by `from`.
   * - If the caller is not `from`, it must be have been allowed to move this
   * NFT by either {approve} or {setApprovalForAll}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  /**
   * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
   * another (`to`).
   *
   * Requirements:
   * - If the caller is not `from`, it must be approved to move this NFT by
   * either {approve} or {setApprovalForAll}.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function approve(address to, uint256 tokenId) external;

  function getApproved(uint256 tokenId) external view returns (address operator);

  function setApprovalForAll(address operator, bool _approved) external;

  function isApprovedForAll(address owner, address operator) external view returns (bool);

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
  ) external;
}

pragma solidity >=0.6.2;

// This file copied from OZ, but with the version pragma updated to use >=.

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
  function totalSupply() external view returns (uint256);

  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

  function tokenByIndex(uint256 index) external view returns (uint256);
}

pragma solidity >=0.6.2;

// This file copied from OZ, but with the version pragma updated to use >=.

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function tokenURI(uint256 tokenId) external view returns (string memory);
}