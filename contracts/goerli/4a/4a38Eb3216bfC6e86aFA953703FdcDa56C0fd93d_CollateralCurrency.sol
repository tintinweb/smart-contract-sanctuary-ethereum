// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../access/AccessHelper.sol';
import '../interfaces/IManagedCollateralCurrency.sol';
import './interfaces/IManagedYieldDistributor.sol';
import './TokenDelegateBase.sol';

contract CollateralCurrency is IManagedCollateralCurrency, AccessHelper, TokenDelegateBase {
  address private _borrowManager;

  uint8 internal constant DECIMALS = 18;

  constructor(
    IAccessController acl,
    string memory name_,
    string memory symbol_
  ) AccessHelper(acl) ERC20Base(name_, symbol_, DECIMALS) {}

  event LiquidityProviderRegistered(address indexed account);

  function registerLiquidityProvider(address account) external aclHas(AccessFlags.LP_DEPLOY) {
    internalSetFlags(account, FLAG_MINT | FLAG_BURN);
    emit LiquidityProviderRegistered(account);
  }

  function isLiquidityProvider(address account) external view override returns (bool) {
    return internalGetFlags(account) & FLAG_MINT != 0;
  }

  event InsurerRegistered(address indexed account);

  function registerInsurer(address account) external aclHas(AccessFlags.INSURER_ADMIN) {
    internalSetFlags(account, FLAG_TRANSFER_CALLBACK);
    emit InsurerRegistered(account);
    _registerStakeAsset(account, true);
  }

  function _registerStakeAsset(address account, bool register) private {
    address bm = borrowManager();
    if (bm != address(0)) {
      IManagedYieldDistributor(bm).registerStakeAsset(account, register);
    }
  }

  event Unegistered(address indexed account);

  function unregister(address account) external {
    if (msg.sender != account) {
      Access.require(hasAnyAcl(msg.sender, internalGetFlags(account) == FLAG_TRANSFER_CALLBACK ? AccessFlags.INSURER_ADMIN : AccessFlags.LP_DEPLOY));
    }
    internalUnsetFlags(account);
    emit Unegistered(account);

    _registerStakeAsset(account, false);
  }

  function mint(address account, uint256 amount) external override onlyWithFlags(FLAG_MINT) {
    _mint(account, amount);
  }

  function transferOnBehalf(
    address onBehalf,
    address recipient,
    uint256 amount
  ) external override onlyBorrowManager {
    _transferOnBehalf(msg.sender, recipient, amount, onBehalf);
  }

  function mintAndTransfer(
    address onBehalf,
    address recipient,
    uint256 mintAmount,
    uint256 balanceAmount
  ) external override onlyWithFlags(FLAG_MINT) {
    if (balanceAmount == 0) {
      _mintAndTransfer(onBehalf, recipient, mintAmount);
    } else {
      _mint(onBehalf, mintAmount);
      if (balanceAmount == type(uint256).max) {
        balanceAmount = balanceOf(onBehalf);
      } else {
        balanceAmount += mintAmount;
      }
      _transfer(onBehalf, recipient, balanceAmount);
    }
  }

  function burn(address account, uint256 amount) external override onlyWithFlags(FLAG_BURN) {
    _burn(account, amount);
  }

  function _onlyBorrowManager() private view {
    Access.require(msg.sender == borrowManager());
  }

  modifier onlyBorrowManager() {
    _onlyBorrowManager();
    _;
  }

  function borrowManager() public view override returns (address) {
    return _borrowManager;
  }

  event BorrowManagerUpdated(address indexed addr);

  function setBorrowManager(address borrowManager_) external onlyAdmin {
    Value.require(borrowManager_ != address(0));
    // Slither is not very smart
    // slither-disable-next-line missing-zero-check
    _borrowManager = borrowManager_;

    emit BorrowManagerUpdated(borrowManager_);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/Errors.sol';
import '../interfaces/IProxyFactory.sol';
import './interfaces/IAccessController.sol';
import './AccessLib.sol';
import './AccessFlags.sol';

abstract contract AccessHelper {
  using AccessLib for IAccessController;

  IAccessController private immutable _remoteAcl;

  constructor(IAccessController acl) {
    _remoteAcl = acl;
  }

  function remoteAcl() internal view virtual returns (IAccessController) {
    return _remoteAcl;
  }

  function hasRemoteAcl() internal view returns (bool) {
    return address(remoteAcl()) != address(0);
  }

  function isAdmin(address addr) internal view virtual returns (bool) {
    IAccessController acl = remoteAcl();
    return (address(acl) != address(0)) && acl.isAdmin(addr);
  }

  function owner() public view returns (address) {
    IAccessController acl = remoteAcl();
    return address(acl) != address(0) ? acl.owner() : address(0);
  }

  function _onlyAdmin() private view {
    Access.require(isAdmin(msg.sender));
  }

  modifier onlyAdmin() {
    _onlyAdmin();
    _;
  }

  function hasAnyAcl(address subject, uint256 flags) internal view virtual returns (bool) {
    return remoteAcl().hasAnyOf(subject, flags);
  }

  function hasAllAcl(address subject, uint256 flags) internal view virtual returns (bool) {
    return remoteAcl().hasAllOf(subject, flags);
  }

  function _requireAnyFor(address subject, uint256 flags) private view {
    Access.require(hasAnyAcl(subject, flags));
  }

  function _requireAllFor(address subject, uint256 flags) private view {
    Access.require(hasAllAcl(subject, flags));
  }

  modifier aclHas(uint256 flags) {
    _requireAnyFor(msg.sender, flags);
    _;
  }

  modifier aclHasAny(uint256 flags) {
    _requireAnyFor(msg.sender, flags);
    _;
  }

  modifier aclHasAll(uint256 flags) {
    _requireAllFor(msg.sender, flags);
    _;
  }

  modifier aclHasAnyFor(address subject, uint256 flags) {
    _requireAnyFor(subject, flags);
    _;
  }

  modifier aclHasAllFor(address subject, uint256 flags) {
    _requireAllFor(subject, flags);
    _;
  }

  function _onlyEmergencyAdmin() private view {
    if (!hasAnyAcl(msg.sender, AccessFlags.EMERGENCY_ADMIN)) {
      revert Errors.CallerNotEmergencyAdmin();
    }
  }

  modifier onlyEmergencyAdmin() {
    _onlyEmergencyAdmin();
    _;
  }

  function _onlySweepAdmin() private view {
    if (!hasAnyAcl(msg.sender, AccessFlags.SWEEP_ADMIN)) {
      revert Errors.CallerNotSweepAdmin();
    }
  }

  modifier onlySweepAdmin() {
    _onlySweepAdmin();
    _;
  }

  function getProxyFactory() internal view returns (IProxyFactory) {
    return IProxyFactory(getAclAddress(AccessFlags.PROXY_FACTORY));
  }

  function getAclAddress(uint256 t) internal view returns (address) {
    IAccessController acl = remoteAcl();
    return address(acl) == address(0) ? address(0) : acl.getAddress(t);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/tokens/IERC20.sol';

interface IManagedCollateralCurrency is IERC20 {
  /// @dev regular mint
  function mint(address account, uint256 amount) external;

  /// @dev an optimized combo, equivalent of mint(onBehalf, mintAmount) and then transfers (mintAmount + balanceAmount) from onBehalf to recipient
  /// @dev balanceAmount can be uint256.max to take whole balance
  function mintAndTransfer(
    address onBehalf,
    address recepient,
    uint256 mintAmount,
    uint256 balanceAmount
  ) external;

  function transferOnBehalf(
    address onBehalf,
    address recipient,
    uint256 amount
  ) external;

  function burn(address account, uint256 amount) external;

  function isLiquidityProvider(address account) external view returns (bool);

  function borrowManager() external view returns (address); // ICollateralStakeManager
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../interfaces/ICollateralized.sol';

interface IManagedYieldDistributor is ICollateralized {
  function registerStakeAsset(address asset, bool register) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/tokens/ERC20Base.sol';
import '../tools/tokens/IERC1363.sol';
import '../tools/Errors.sol';

abstract contract TokenDelegateBase is ERC20Base {
  uint256 internal constant FLAG_MINT = 1 << 1;
  uint256 internal constant FLAG_BURN = 1 << 2;
  uint256 internal constant FLAG_TRANSFER_CALLBACK = 1 << 3;

  mapping(address => uint256) private _flags;

  function _onlyWithAnyFlags(uint256 flags) private view {
    Access.require(_flags[msg.sender] & flags == flags && flags != 0);
  }

  modifier onlyWithFlags(uint256 flags) {
    _onlyWithAnyFlags(flags);
    _;
  }

  function _transferAndEmit(
    address sender,
    address recipient,
    uint256 amount,
    address onBehalf
  ) internal override {
    super._transferAndEmit(sender, recipient, amount, onBehalf);
    _notifyRecipient(onBehalf, recipient, amount);
  }

  function _notifyRecipient(
    address sender,
    address recipient,
    uint256 amount
  ) private {
    if (msg.sender != recipient && _flags[recipient] & FLAG_TRANSFER_CALLBACK != 0) {
      IERC1363Receiver(recipient).onTransferReceived(msg.sender, sender, amount, '');
    }
  }

  function _mintAndTransfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal override {
    super._mintAndTransfer(sender, recipient, amount);
    _notifyRecipient(sender, recipient, amount);
  }

  function internalGetFlags(address account) internal view returns (uint256) {
    return _flags[account];
  }

  function internalSetFlags(address account, uint256 flags) internal {
    require(account != address(0));
    _flags[account] |= flags;
  }

  function internalUnsetFlags(address account, uint256 flags) internal {
    require(account != address(0));
    _flags[account] &= ~flags;
  }

  function internalUnsetFlags(address account) internal {
    delete _flags[account];
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/Address.sol';

library Errors {
  function illegalState(bool ok) internal pure {
    if (!ok) {
      revert IllegalState();
    }
  }

  function illegalValue(bool ok) internal pure {
    if (!ok) {
      revert IllegalValue();
    }
  }

  function accessDenied(bool ok) internal pure {
    if (!ok) {
      revert AccessDenied();
    }
  }

  function _mutable() private returns (bool) {}

  function notImplemented() internal {
    if (!_mutable()) {
      revert NotImplemented();
    }
  }

  error OperationPaused();
  error IllegalState();
  error Impossible();
  error IllegalValue();
  error NotSupported();
  error NotImplemented();
  error AccessDenied();

  error ExpiredPermit();
  error WrongPermitSignature();

  error ExcessiveVolatility();
  error ExcessiveVolatilityLock(uint256 mask);

  error CallerNotProxyOwner();
  error CallerNotEmergencyAdmin();
  error CallerNotSweepAdmin();
  error CallerNotOracleAdmin();

  error CollateralTransferFailed();

  error ContractRequired();
  error ImplementationRequired();

  error UnknownPriceAsset(address asset);
}

library Sanity {
  // slither-disable-next-line shadowing-builtin
  function require(bool ok) internal pure {
    // This code should be commented out on release
    if (!ok) {
      revert Errors.Impossible();
    }
  }
}

library State {
  // slither-disable-next-line shadowing-builtin
  function require(bool ok) internal pure {
    if (!ok) {
      revert Errors.IllegalState();
    }
  }
}

library Value {
  // slither-disable-next-line shadowing-builtin
  function require(bool ok) internal pure {
    if (!ok) {
      revert Errors.IllegalValue();
    }
  }

  function requireContract(address a) internal view {
    if (!Address.isContract(a)) {
      revert Errors.ContractRequired();
    }
  }
}

library Access {
  // slither-disable-next-line shadowing-builtin
  function require(bool ok) internal pure {
    if (!ok) {
      revert Errors.AccessDenied();
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IProxyFactory {
  function isAuthenticProxy(address proxy) external view returns (bool);

  function createProxy(
    address adminAddress,
    bytes32 implName,
    address context,
    bytes calldata params
  ) external returns (address);

  function createProxyWithImpl(
    address adminAddress,
    bytes32 implName,
    address impl,
    bytes calldata params
  ) external returns (address);

  function upgradeProxy(address proxyAddress, bytes calldata params) external returns (bool);

  function upgradeProxyWithImpl(
    address proxyAddress,
    address newImpl,
    bool checkRevision,
    bytes calldata params
  ) external returns (bool);

  event ProxyCreated(address indexed proxy, address indexed impl, string typ, bytes params, address indexed admin);
  event ProxyUpdated(address indexed proxy, address indexed impl, string typ, bytes params);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './IRemoteAccessBitmask.sol';
import '../../tools/upgradeability/IProxy.sol';

/// @dev Main registry of permissions and addresses
interface IAccessController is IRemoteAccessBitmask {
  function getAddress(uint256 id) external view returns (address);

  function isAdmin(address) external view returns (bool);

  function owner() external view returns (address);

  function roleHolders(uint256 id) external view returns (address[] memory addrList);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './interfaces/IRemoteAccessBitmask.sol';

library AccessLib {
  function getAcl(IRemoteAccessBitmask remote, address subject) internal view returns (uint256) {
    return remote.queryAccessControlMask(subject, type(uint256).max);
  }

  function queryAcl(
    IRemoteAccessBitmask remote,
    address subject,
    uint256 filterMask
  ) internal view returns (uint256) {
    return address(remote) != address(0) ? remote.queryAccessControlMask(subject, filterMask) : 0;
  }

  function hasAnyOf(
    IRemoteAccessBitmask remote,
    address subject,
    uint256 flags
  ) internal view returns (bool) {
    return queryAcl(remote, subject, flags) & flags != 0;
  }

  function hasAllOf(
    IRemoteAccessBitmask remote,
    address subject,
    uint256 flags
  ) internal view returns (bool) {
    return flags != 0 && queryAcl(remote, subject, flags) & flags == flags;
  }

  function hasAny(IRemoteAccessBitmask remote, address subject) internal view returns (bool) {
    return address(remote) != address(0) && remote.queryAccessControlMask(subject, 0) != 0;
  }

  function hasNone(IRemoteAccessBitmask remote, address subject) internal view returns (bool) {
    return address(remote) != address(0) && remote.queryAccessControlMask(subject, 0) == 0;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

library AccessFlags {
  // roles that can be assigned to multiple addresses - use range [0..15]
  uint256 public constant EMERGENCY_ADMIN = 1 << 0;
  uint256 public constant TREASURY_ADMIN = 1 << 1;
  uint256 public constant COLLATERAL_FUND_ADMIN = 1 << 2;
  uint256 public constant INSURER_ADMIN = 1 << 3;
  uint256 public constant INSURER_OPS = 1 << 4;

  uint256 public constant PREMIUM_FUND_ADMIN = 1 << 5;

  uint256 public constant SWEEP_ADMIN = 1 << 6;
  uint256 public constant PRICE_ROUTER_ADMIN = 1 << 7;

  uint256 public constant UNDERWRITER_POLICY = 1 << 8;
  uint256 public constant UNDERWRITER_CLAIM = 1 << 9;

  uint256 public constant LP_DEPLOY = 1 << 10;
  uint256 public constant LP_ADMIN = 1 << 11;

  uint256 public constant INSURED_ADMIN = 1 << 12;
  uint256 public constant INSURED_OPS = 1 << 13;
  uint256 public constant BORROWER_ADMIN = 1 << 14;
  uint256 public constant LIQUIDITY_BORROWER = 1 << 15;

  uint256 public constant ROLES = (uint256(1) << 16) - 1;

  // singletons - use range [16..64] - can ONLY be assigned to a single address
  uint256 public constant SINGLETS = ((uint256(1) << 64) - 1) & ~ROLES;

  // protected singletons - use for proxies
  uint256 public constant APPROVAL_CATALOG = 1 << 16;
  uint256 public constant TREASURY = 1 << 17;
  // uint256 public constant COLLATERAL_CURRENCY = 1 << 18;
  uint256 public constant PRICE_ROUTER = 1 << 19;

  uint256 public constant PROTECTED_SINGLETS = ((uint256(1) << 26) - 1) & ~ROLES;

  // non-proxied singletons, numbered down from 31 (as JS has problems with bitmasks over 31 bits)
  uint256 public constant PROXY_FACTORY = 1 << 26;

  uint256 public constant DATA_HELPER = 1 << 28;

  // any other roles - use range [64..]
  // these roles can be assigned to multiple addresses
  uint256 public constant COLLATERAL_FUND_LISTING = 1 << 64; // an ephemeral role - just to keep a list of collateral funds
  uint256 public constant INSURER_POOL_LISTING = 1 << 65; // an ephemeral role - just to keep a list of insurer funds

  uint256 public constant ROLES_EXT = uint256(0x3) << 64;
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IRemoteAccessBitmask {
  /**
   * @dev Returns access flags granted to the given address and limited by the filterMask. filterMask == 0 has a special meaning.
   * @param addr an to get access perfmissions for
   * @param filterMask limits a subset of flags to be checked.
   * NB! When filterMask == 0 then zero is returned no flags granted, or an unspecified non-zero value otherwise.
   * @return Access flags currently granted
   */
  function queryAccessControlMask(address addr, uint256 filterMask) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IProxy {
  function upgradeToAndCall(address newImplementation, bytes calldata data) external payable;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP excluding events to avoid linearization issues.
 */
interface IERC20 {
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
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface ICollateralized {
  /// @dev address of the collateral fund and coverage token ($CC)
  function collateral() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './ERC20DetailsBase.sol';
import './ERC20AllowanceBase.sol';
import './ERC20BalanceBase.sol';
import './ERC20MintableBase.sol';

abstract contract ERC20Base is ERC20DetailsBase, ERC20AllowanceBase, ERC20BalanceBase, ERC20MintableBase {
  constructor(
    string memory name_,
    string memory symbol_,
    uint8 decimals_
  ) ERC20DetailsBase(name_, symbol_, decimals_) {}

  function _approveTransferFrom(address owner, uint256 amount) internal override(ERC20AllowanceBase, ERC20TransferBase) {
    ERC20AllowanceBase._approveTransferFrom(owner, amount);
  }

  function incrementBalance(address account, uint256 amount) internal override(ERC20BalanceBase, ERC20MintableBase) {
    ERC20BalanceBase.incrementBalance(account, amount);
  }

  function decrementBalance(address account, uint256 amount) internal override(ERC20BalanceBase, ERC20MintableBase) {
    ERC20BalanceBase.decrementBalance(account, amount);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './IERC20Details.sol';

library ERC1363 {
  // 0x88a7ca5c === bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))
  bytes4 internal constant RECEIVER = type(IERC1363Receiver).interfaceId;

  /* 0xb0202a11 ===
   *   bytes4(keccak256('transferAndCall(address,uint256)')) ^
   *   bytes4(keccak256('transferAndCall(address,uint256,bytes)')) ^
   *   bytes4(keccak256('transferFromAndCall(address,address,uint256)')) ^
   *   bytes4(keccak256('transferFromAndCall(address,address,uint256,bytes)')) ^
   *   bytes4(keccak256('approveAndCall(address,uint256)')) ^
   *   bytes4(keccak256('approveAndCall(address,uint256,bytes)'))
   */
  bytes4 internal constant TOKEN = type(IERC1363).interfaceId;

  function callReceiver(
    address receiver,
    address operator,
    address from,
    uint256 value,
    bytes memory data
  ) internal {
    require(IERC1363Receiver(receiver).onTransferReceived(operator, from, value, data) == IERC1363Receiver.onTransferReceived.selector);
  }
}

interface IERC1363 {
  /**
   * @notice Transfer tokens from `msg.sender` to another address and then call `onTransferReceived` on receiver
   * @param recipient address The address which you want to transfer to
   * @param amount uint256 The amount of tokens to be transferred
   * @return true unless throwing
   */
  function transferAndCall(address recipient, uint256 amount) external returns (bool);

  /**
   * @notice Transfer tokens from `msg.sender` to another address and then call `onTransferReceived` on receiver
   * @param recipient address The address which you want to transfer to
   * @param amount uint256 The amount of tokens to be transferred
   * @param data bytes Additional data with no specified format, sent in call to `recipient`
   * @return true unless throwing
   */
  function transferAndCall(
    address recipient,
    uint256 amount,
    bytes calldata data
  ) external returns (bool);

  /**
   * @notice Transfer tokens from one address to another and then call `onTransferReceived` on receiver
   * @param sender address The address which you want to send tokens from
   * @param recipient address The address which you want to transfer to
   * @param amount uint256 The amount of tokens to be transferred
   * @return true unless throwing
   */
  function transferFromAndCall(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  /**
   * @notice Transfer tokens from one address to another and then call `onTransferReceived` on receiver
   * @param sender address The address which you want to send tokens from
   * @param recipient address The address which you want to transfer to
   * @param amount uint256 The amount of tokens to be transferred
   * @param data bytes Additional data with no specified format, sent in call to `recipient`
   * @return true unless throwing
   */
  function transferFromAndCall(
    address sender,
    address recipient,
    uint256 amount,
    bytes calldata data
  ) external returns (bool);

  /**
   * @notice Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
   * and then call `onApprovalReceived` on spender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param spender address The address which will spend the funds
   * @param amount uint256 The amount of tokens to be spent
   */
  function approveAndCall(address spender, uint256 amount) external returns (bool);

  /**
   * @notice Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
   * and then call `onApprovalReceived` on spender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param spender address The address which will spend the funds
   * @param amount uint256 The amount of tokens to be spent
   * @param data bytes Additional data with no specified format, sent in call to `spender`
   */
  function approveAndCall(
    address spender,
    uint256 amount,
    bytes calldata data
  ) external returns (bool);
}

interface IERC1363Receiver {
  /**
   * @notice Handle the receipt of ERC1363 tokens
   * @dev Any ERC1363 smart contract calls this function on the recipient
   * after a `transfer` or a `transferFrom`. This function MAY throw to revert and reject the
   * transfer. Return of other than the magic value MUST result in the
   * transaction being reverted.
   * Note: the token contract address is always the message sender.
   * @param operator address The address which called `transferAndCall` or `transferFromAndCall` function
   * @param from address The address which are token transferred from
   * @param value uint256 The amount of tokens transferred
   * @param data bytes Additional data with no specified format
   * @return `bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))`
   *  unless throwing
   */
  function onTransferReceived(
    address operator,
    address from,
    uint256 value,
    bytes memory data
  ) external returns (bytes4);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './IERC20Details.sol';

abstract contract ERC20DetailsBase is IERC20Details {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(
    string memory name_,
    string memory symbol_,
    uint8 decimals_
  ) {
    _name = name_;
    _symbol = symbol_;
    _decimals = decimals_;
  }

  function _initializeERC20(
    string memory name_,
    string memory symbol_,
    uint8 decimals_
  ) internal {
    _name = name_;
    _symbol = symbol_;
    _decimals = decimals_;
  }

  function name() public view override returns (string memory) {
    return _name;
  }

  function symbol() public view override returns (string memory) {
    return _symbol;
  }

  function decimals() public view override returns (uint8) {
    return _decimals;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../tools/tokens/IERC20.sol';

abstract contract ERC20AllowanceBase is IERC20 {
  mapping(address => mapping(address => uint256)) private _allowances;

  function allowance(address owner, address spender) public view virtual override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    _approve(msg.sender, spender, amount);
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    _decAllowance(msg.sender, spender, subtractedValue, false);
    return true;
  }

  function useAllowance(address owner, uint256 subtractedValue) public virtual returns (bool) {
    _decAllowance(owner, msg.sender, subtractedValue, false);
    return true;
  }

  function _decAllowance(
    address owner,
    address spender,
    uint256 subtractedValue,
    bool transfer_
  ) private {
    uint256 limit = _allowances[owner][spender];
    if (limit == 0 && subtractedValue > 0 && transfer_ && delegatedAllownance(owner, spender, subtractedValue)) {
      return;
    }

    require(limit >= subtractedValue, 'ERC20: decreased allowance below zero');
    unchecked {
      _approve(owner, spender, limit - subtractedValue);
    }
  }

  function delegatedAllownance(
    address owner,
    address spender,
    uint256 subtractedValue
  ) internal virtual returns (bool) {}

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
   *
   * This is internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal {
    require(owner != address(0), 'ERC20: approve from the zero address');
    require(spender != address(0), 'ERC20: approve to the zero address');

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  event Approval(address indexed owner, address indexed spender, uint256 value);

  function _approveTransferFrom(address owner, uint256 amount) internal virtual {
    _decAllowance(owner, msg.sender, amount, true);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../tools/tokens/IERC20.sol';

abstract contract ERC20BalanceBase is IERC20 {
  mapping(address => uint256) private _balances;

  function balanceOf(address account) public view override returns (uint256) {
    return _balances[account];
  }

  function incrementBalance(address account, uint256 amount) internal virtual {
    _balances[account] += amount;
  }

  function decrementBalance(address account, uint256 amount) internal virtual {
    uint256 balance = _balances[account];
    require(balance >= amount, 'ERC20: transfer amount exceeds balance');
    unchecked {
      _balances[account] = balance - amount;
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './ERC20TransferBase.sol';

abstract contract ERC20MintableBase is ERC20TransferBase {
  uint256 private _totalSupply;

  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements
   *
   * - `to` cannot be the zero address.
   */
  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), 'ERC20: mint to the zero address');

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply = _totalSupply + amount;
    incrementBalance(account, amount);

    emit Transfer(address(0), account, amount);
  }

  function _mintAndTransfer(
    address account,
    address recipient,
    uint256 amount
  ) internal virtual {
    require(account != address(0), 'ERC20: mint to the zero address');
    require(recipient != address(0), 'ERC20: transfer to the zero address');

    _beforeTokenTransfer(address(0), account, amount);
    _beforeTokenTransfer(account, recipient, amount);

    _totalSupply = _totalSupply + amount;
    incrementBalance(recipient, amount);

    emit Transfer(address(0), account, amount);
    emit Transfer(account, recipient, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   *
   * Requirements
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), 'ERC20: burn from the zero address');

    _beforeTokenTransfer(account, address(0), amount);

    _totalSupply = _totalSupply - amount;
    decrementBalance(account, amount);

    emit Transfer(account, address(0), amount);
  }

  function transferBalance(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual override {
    decrementBalance(sender, amount);
    incrementBalance(recipient, amount);
  }

  function incrementBalance(address account, uint256 amount) internal virtual;

  function decrementBalance(address account, uint256 amount) internal virtual;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IERC20Details {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../tools/tokens/IERC20.sol';

abstract contract ERC20TransferBase is IERC20 {
  event Transfer(address indexed from, address indexed to, uint256 value);

  function transfer(address recipient, uint256 amount) public override returns (bool) {
    _transfer(msg.sender, recipient, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public override returns (bool) {
    _transfer(sender, recipient, amount);
    _approveTransferFrom(sender, amount);
    return true;
  }

  function _approveTransferFrom(address owner, uint256 amount) internal virtual;

  /**
   * @dev Moves tokens `amount` from `sender` to `recipient`.
   *
   * This is internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */
  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {
    _ensure(sender, recipient);

    _beforeTokenTransfer(sender, recipient, amount);
    _transferAndEmit(sender, recipient, amount, sender);
  }

  function _transferOnBehalf(
    address sender,
    address recipient,
    uint256 amount,
    address onBehalf
  ) internal virtual {
    _ensure(sender, recipient);
    require(onBehalf != address(0), 'ERC20: transfer on behalf of the zero address');

    _beforeTokenTransfer(sender, recipient, amount);
    _transferAndEmit(sender, recipient, amount, onBehalf);
  }

  function _ensure(address sender, address recipient) private pure {
    require(sender != address(0), 'ERC20: transfer from the zero address');
    require(recipient != address(0), 'ERC20: transfer to the zero address');
  }

  function _transferAndEmit(
    address sender,
    address recipient,
    uint256 amount,
    address onBehalf
  ) internal virtual {
    if (sender != recipient) {
      transferBalance(sender, recipient, amount);
    }
    if (onBehalf != sender) {
      emit Transfer(sender, onBehalf, amount);
    }
    emit Transfer(onBehalf, recipient, amount);
  }

  function transferBalance(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual;

  /**
   * @dev Hook that is called before any transfer of tokens. This includes
   * minting and burning.
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
   * will be to transferred to `to`.
   * - when `from` is zero, `amount` tokens will be minted for `to`.
   * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
   * - `from` and `to` are never both zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}
}