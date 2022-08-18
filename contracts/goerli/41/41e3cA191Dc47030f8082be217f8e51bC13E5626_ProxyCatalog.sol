// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/Address.sol';
import '../tools/Errors.sol';

contract AccessCallHelper {
  address private immutable _owner;

  constructor(address owner) {
    require(owner != address(0));
    _owner = owner;
  }

  function doCall(address callAddr, bytes calldata callData) external returns (bytes memory result) {
    Access.require(msg.sender == _owner);
    return Address.functionCall(callAddr, callData);
  }
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

import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '../tools/SafeOwnable.sol';
import '../tools/Errors.sol';
import '../tools/math/BitUtils.sol';
import '../tools/upgradeability/TransparentProxy.sol';
import '../tools/upgradeability/IProxy.sol';
import './interfaces/IAccessController.sol';
import './interfaces/IManagedAccessController.sol';
import './AccessCallHelper.sol';

import 'hardhat/console.sol';

abstract contract AccessControllerBase is SafeOwnable, IManagedAccessController {
  using BitUtils for uint256;
  using EnumerableSet for EnumerableSet.AddressSet;

  enum AddrMode {
    None,
    Singlet,
    ProtectedSinglet,
    Multilet
  }

  struct AddrInfo {
    address addr;
    AddrMode mode;
  }

  mapping(address => uint256) private _masks;
  mapping(uint256 => AddrInfo) private _singlets;
  mapping(uint256 => EnumerableSet.AddressSet) private _multilets;

  AccessCallHelper private immutable _callHelper;

  uint256 private _singletons;

  address private _tempAdmin;
  uint32 private _expiresAt;

  uint8 private constant ANY_ROLE_BLOCKED = 1;
  uint8 private constant ANY_ROLE_ENABLED = 2;
  uint8 private _anyRoleMode;

  constructor(
    uint256 singletons,
    uint256 nonSingletons,
    uint256 protecteds
  ) {
    require(singletons & nonSingletons == 0, 'mixed types');
    require(singletons & protecteds == protecteds, 'all protected must be singletons');

    for ((uint256 flags, uint256 mask) = (singletons | nonSingletons, 1); flags > 0; (flags, mask) = (flags >> 1, mask << 1)) {
      if (flags & 1 != 0) {
        AddrInfo storage info = _singlets[mask];
        info.mode = nonSingletons & mask != 0 ? AddrMode.Multilet : (protecteds & mask != 0 ? AddrMode.ProtectedSinglet : AddrMode.Singlet);
      }
    }

    _singletons = singletons;

    _callHelper = new AccessCallHelper(address(this));
  }

  function _onlyOwnerOrAdmin() private view {
    Access.require(isAdmin(msg.sender));
  }

  modifier onlyOwnerOrAdmin() {
    _onlyOwnerOrAdmin();
    _;
  }

  function owner() public view override(IAccessController, SafeOwnable) returns (address) {
    return super.owner();
  }

  function isAdmin(address addr) public view returns (bool) {
    return addr == owner() || (addr == _tempAdmin && _expiresAt > block.timestamp);
  }

  function queryAccessControlMask(address addr, uint256 filter) external view override returns (uint256 flags) {
    flags = _masks[addr];
    return filter == 0 ? flags : flags & filter;
  }

  function setTemporaryAdmin(address admin, uint256 expiryTime) external override onlyOwner {
    if (_tempAdmin != address(0)) {
      _revokeAllRoles(_tempAdmin);
    }
    if ((_tempAdmin = admin) != address(0)) {
      require((_expiresAt = uint32(expiryTime += block.timestamp)) >= block.timestamp);
    } else {
      _expiresAt = 0;
      expiryTime = 0;
    }
    emit TemporaryAdminAssigned(admin, expiryTime);
  }

  function getTemporaryAdmin() external view override returns (address admin, uint256 expiresAt) {
    admin = _tempAdmin;
    if (admin != address(0)) {
      return (admin, _expiresAt);
    }
    return (address(0), 0);
  }

  /// @dev Renouncement has no time limit and can be done either by the temporary admin at any time, or by anyone after the expiry.
  function renounceTemporaryAdmin() external override {
    address tempAdmin = _tempAdmin;
    if (tempAdmin == address(0)) {
      return;
    }
    if (msg.sender != tempAdmin && _expiresAt > block.timestamp) {
      return;
    }
    _revokeAllRoles(tempAdmin);
    _tempAdmin = address(0);
    emit TemporaryAdminAssigned(address(0), 0);
  }

  function setAnyRoleMode(bool blockOrEnable) external onlyOwnerOrAdmin {
    if (blockOrEnable) {
      require(_anyRoleMode != ANY_ROLE_BLOCKED);
      _anyRoleMode = ANY_ROLE_ENABLED;
      emit AnyRoleModeEnabled();
    } else if (_anyRoleMode != ANY_ROLE_BLOCKED) {
      _anyRoleMode = ANY_ROLE_BLOCKED;
      emit AnyRoleModeBlocked();
    }
  }

  function grantRoles(address addr, uint256 flags) external onlyOwnerOrAdmin returns (uint256) {
    return _grantMultiRoles(addr, flags, true);
  }

  function grantAnyRoles(address addr, uint256 flags) external onlyOwnerOrAdmin returns (uint256) {
    State.require(_anyRoleMode == ANY_ROLE_ENABLED);
    return _grantMultiRoles(addr, flags, false);
  }

  function _grantMultiRoles(
    address addr,
    uint256 flags,
    bool strict
  ) private returns (uint256) {
    uint256 m = _masks[addr];
    flags &= ~m;
    if (flags == 0) {
      return m;
    }
    m |= flags;
    _masks[addr] = m;

    for (uint256 mask = 1; flags > 0; (flags, mask) = (flags >> 1, mask << 1)) {
      if (flags & 1 != 0) {
        AddrInfo storage info = _singlets[mask];
        if (info.addr != addr) {
          AddrMode mode = info.mode;
          if (mode == AddrMode.None) {
            info.mode = AddrMode.Multilet;
          } else {
            require(mode == AddrMode.Multilet || !strict, 'singleton should use setAddress');
          }

          _multilets[mask].add(addr);
        }
      }
    }

    emit RolesUpdated(addr, m);
    return m;
  }

  function revokeRoles(address addr, uint256 flags) external onlyOwnerOrAdmin returns (uint256) {
    return _revokeRoles(addr, flags);
  }

  function revokeAllRoles(address addr) external onlyOwnerOrAdmin returns (uint256) {
    return _revokeAllRoles(addr);
  }

  function _revokeAllRoles(address addr) private returns (uint256) {
    uint256 m = _masks[addr];
    if (m == 0) {
      return 0;
    }
    delete _masks[addr];
    _revokeRolesByMask(addr, m);
    emit RolesUpdated(addr, 0);
    return m;
  }

  function _revokeRolesByMask(address addr, uint256 flags) private {
    for (uint256 mask = 1; flags > 0; (flags, mask) = (flags >> 1, mask << 1)) {
      if (flags & 1 != 0) {
        AddrInfo storage info = _singlets[mask];
        if (info.addr == addr) {
          _ensureNotProtected(info.mode);
          info.addr = address(0);
          emit AddressSet(mask, address(0));
        } else {
          _multilets[mask].remove(addr);
        }
      }
    }
  }

  function _ensureNotProtected(AddrMode mode) private pure {
    require(mode != AddrMode.ProtectedSinglet, 'protected singleton can not be revoked');
  }

  function _revokeRoles(address addr, uint256 flags) private returns (uint256) {
    uint256 m = _masks[addr];
    if ((flags &= m) != 0) {
      _masks[addr] = (m &= ~flags);
      _revokeRolesByMask(addr, flags);
      emit RolesUpdated(addr, m);
    }
    return m;
  }

  function revokeRolesFromAll(uint256 flags, uint256 limitMultitons) external onlyOwnerOrAdmin returns (bool all) {
    all = true;
    uint256 fullMask = flags;

    for (uint256 mask = 1; flags > 0; (flags, mask) = (flags >> 1, mask << 1)) {
      if (flags & 1 != 0) {
        AddrInfo storage info = _singlets[mask];
        address addr = info.addr;
        if (addr != address(0)) {
          _ensureNotProtected(info.mode);
          _masks[addr] &= ~mask;
          info.addr = address(0);
          emit AddressSet(mask, address(0));
        }

        if (all) {
          EnumerableSet.AddressSet storage multilets = _multilets[mask];
          for (uint256 j = multilets.length(); j > 0; ) {
            j--;
            if (limitMultitons == 0) {
              all = false;
              break;
            }
            limitMultitons--;
            _revokeRoles(multilets.at(j), fullMask);
          }
        }
      }
    }
  }

  function _onlyOneRole(uint256 id) private pure {
    require(id.isPowerOf2nz(), 'only one role is allowed');
  }

  function roleHolders(uint256 id) external view override returns (address[] memory addrList) {
    _onlyOneRole(id);

    address singleton = _singlets[id].addr;
    EnumerableSet.AddressSet storage multilets = _multilets[id];

    if (singleton == address(0) || multilets.contains(singleton)) {
      return multilets.values();
    }

    addrList = new address[](1 + multilets.length());
    addrList[0] = singleton;

    for (uint256 i = addrList.length; i > 1; ) {
      i--;
      addrList[i] = multilets.at(i - 1);
    }
  }

  /**
   * @dev Sets a sigleton address, replaces previous value
   * @param id The id
   * @param newAddress The address to set
   */
  function setAddress(uint256 id, address newAddress) public override onlyOwnerOrAdmin {
    _internalSetAddress(id, newAddress);
    emit AddressSet(id, newAddress);
  }

  function _internalSetAddress(uint256 id, address newAddress) private {
    _onlyOneRole(id);

    AddrInfo storage info = _singlets[id];
    AddrMode mode = info.mode;

    if (mode == AddrMode.None) {
      _singletons |= id;
      info.mode = AddrMode.Singlet;
    } else {
      require(mode < AddrMode.Multilet, 'id is not a singleton');

      address prev = info.addr;
      if (prev != address(0)) {
        require(mode == AddrMode.Singlet, 'id is protected');
        _masks[prev] = _masks[prev] & ~id;
      }
    }
    if (newAddress != address(0)) {
      require(Address.isContract(newAddress), 'must be contract');
      _masks[newAddress] = _masks[newAddress] | id;
    }
    info.addr = newAddress;
  }

  /**
   * @dev Returns a singleton address by id
   * @return addr The address
   */
  function getAddress(uint256 id) public view override returns (address addr) {
    AddrInfo storage info = _singlets[id];

    if ((addr = info.addr) == address(0)) {
      _onlyOneRole(id);
      require(info.mode < AddrMode.Multilet, 'id is not a singleton');
    }
    return addr;
  }

  function isAddress(uint256 id, address addr) public view returns (bool) {
    return _masks[addr] & id != 0;
  }

  function setProtection(uint256 id, bool protection) external onlyOwnerOrAdmin {
    _onlyOneRole(id);
    AddrInfo storage info = _singlets[id];
    require(info.mode < AddrMode.Multilet, 'id is not a singleton');
    info.mode = protection ? AddrMode.ProtectedSinglet : AddrMode.Singlet;
  }

  function _callWithRoles(
    uint256 flags,
    address grantAddr,
    function(address, bytes calldata) internal returns (bytes memory) callFn,
    address callAddr,
    bytes calldata data
  ) private returns (bytes memory result) {
    require(callAddr != address(this) && Address.isContract(callAddr), 'must be another contract');

    (bool restoreMask, uint256 oldMask) = _beforeCallWithRoles(flags, grantAddr);

    result = callFn(callAddr, data);

    if (restoreMask) {
      _masks[grantAddr] = oldMask;
      emit RolesUpdated(grantAddr, oldMask);
    }
    return result;
  }

  function _directCall(address callAddr, bytes calldata callData) private returns (bytes memory) {
    return Address.functionCall(callAddr, callData);
  }

  function _indirectCall(address callAddr, bytes calldata callData) private returns (bytes memory) {
    return _callHelper.doCall(callAddr, callData);
  }

  function _beforeCallWithRoles(uint256 flags, address addr) private returns (bool restoreMask, uint256 oldMask) {
    if (_singletons & flags != 0) {
      require(_anyRoleMode == ANY_ROLE_ENABLED, 'singleton should use setAddress');
    }

    oldMask = _masks[addr];
    if (flags & ~oldMask != 0) {
      flags |= oldMask;
      emit RolesUpdated(addr, flags);
      _masks[addr] = flags;

      restoreMask = true;
    }
  }

  function directCallWithRoles(
    uint256 flags,
    address addr,
    bytes calldata data
  ) external override onlyOwnerOrAdmin returns (bytes memory result) {
    return _callWithRoles(flags, addr, _directCall, addr, data);
  }

  function directCallWithRolesBatch(CallParams[] calldata params) external override onlyOwnerOrAdmin returns (bytes[] memory results) {
    results = new bytes[](params.length);

    for (uint256 i = 0; i < params.length; i++) {
      address callAddr = params[i].callAddr == address(0) ? getAddress(params[i].callFlag) : params[i].callAddr;
      results[i] = _callWithRoles(params[i].accessFlags, callAddr, _directCall, callAddr, params[i].callData);
    }
    return results;
  }

  function callWithRolesBatch(CallParams[] calldata params) external override onlyOwnerOrAdmin returns (bytes[] memory results) {
    results = new bytes[](params.length);

    for (uint256 i = 0; i < params.length; i++) {
      address callAddr = params[i].callAddr == address(0) ? getAddress(params[i].callFlag) : params[i].callAddr;
      results[i] = _callWithRoles(params[i].accessFlags, address(_callHelper), _indirectCall, callAddr, params[i].callData);
    }
    return results;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * Ownership is transferred in 2 phases: current owner calls {transferOwnership}
 * then the new owner calls {acceptOwnership}.
 * The last owner can recover ownership with {recoverOwnership} before {acceptOwnership} is called by the new owner.
 *
 * When ownership transfer was initiated, this module behaves like there is no owner, until
 * either acceptOwnership() or recoverOwnership() is called.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract SafeOwnable {
  address private _lastOwner;
  address private _activeOwner;
  address private _pendingOwner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event OwnershipTransferring(address indexed previousOwner, address indexed pendingOwner);

  /// @dev Initializes the contract setting the deployer as the initial owner.
  constructor() {
    _activeOwner = msg.sender;
    _pendingOwner = msg.sender;
    emit OwnershipTransferred(address(0), msg.sender);
  }

  /// @dev Returns active owner
  function owner() public view virtual returns (address) {
    return _activeOwner;
  }

  function owners()
    public
    view
    returns (
      address lastOwner,
      address activeOwner,
      address pendingOwner
    )
  {
    return (_lastOwner, _activeOwner, _pendingOwner);
  }

  function _onlyOwner() private view {
    require(
      _activeOwner == msg.sender,
      _pendingOwner == msg.sender ? 'Ownable: caller is not the owner (pending)' : 'Ownable: caller is not the owner'
    );
  }

  /// @dev Reverts if called by any account other than the owner.
  /// Will also revert after transferOwnership() when neither acceptOwnership() nor recoverOwnership() was called.
  modifier onlyOwner() {
    _onlyOwner();
    _;
  }

  /**
   * @dev Initiate ownership renouncment. After cempletion of renouncment, the contract will be without an owner.
   * It will not be possible to call `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NB! To complete renouncment, current owner must call acceptOwnershipTransfer()
   */
  function renounceOwnership() external onlyOwner {
    _initiateOwnershipTransfer(address(0));
  }

  /// @dev Initiates ownership transfer of the contract to a new account `newOwner`.
  /// Can only be called by the current owner. The new owner must call acceptOwnershipTransfer() to get the ownership.
  function transferOwnership(address newOwner) external onlyOwner {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    _initiateOwnershipTransfer(newOwner);
  }

  function _initiateOwnershipTransfer(address newOwner) private {
    emit OwnershipTransferring(msg.sender, newOwner);
    _pendingOwner = newOwner;
    _lastOwner = _activeOwner;
    _activeOwner = address(0);
  }

  /// @dev Accepts ownership of this contract. Can be called:
  // - by the new owner set with transferOwnership(); or
  // - by the last owner to confirm renouncement after renounceOwnership().
  function acceptOwnershipTransfer() external {
    address pendingOwner = _pendingOwner;
    address lastOwner = _lastOwner;
    require(
      _activeOwner == address(0) && (pendingOwner == msg.sender || (pendingOwner == address(0) && lastOwner == msg.sender)),
      'SafeOwnable: caller is not the pending owner'
    );

    emit OwnershipTransferred(lastOwner, pendingOwner);
    _lastOwner = address(0);
    _activeOwner = pendingOwner;
  }

  /// @dev Recovers ownership of this contract to the last owner after transferOwnership(),
  /// unless acceptOwnership() was already called by the new owner.
  function recoverOwnership() external {
    require(_activeOwner == address(0) && _lastOwner == msg.sender, 'SafeOwnable: caller can not recover ownership');
    emit OwnershipTransferred(msg.sender, msg.sender);
    _pendingOwner = msg.sender;
    _activeOwner = msg.sender;
    _lastOwner = address(0);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

library BitUtils {
  function isBit(uint256 v, uint8 index) internal pure returns (bool) {
    return (v >> index) & 1 != 0;
  }

  function nextPowerOf2(uint256 v) internal pure returns (uint256) {
    if (v == 0) {
      return 1;
    }
    v--;
    v |= v >> 1;
    v |= v >> 2;
    v |= v >> 4;
    v |= v >> 8;
    v |= v >> 16;
    v |= v >> 32;
    v |= v >> 64;
    v |= v >> 128;
    return v + 1;
  }

  function isPowerOf2(uint256 v) internal pure returns (bool) {
    return (v & (v - 1)) == 0;
  }

  function isPowerOf2nz(uint256 v) internal pure returns (bool) {
    return (v != 0) && (v & (v - 1) == 0);
  }

  function bitLength(uint256 v) internal pure returns (uint256 len) {
    if (v == 0) {
      return 0;
    }
    if (v > type(uint128).max) {
      v >>= 128;
      len += 128;
    }
    if (v > type(uint64).max) {
      v >>= 64;
      len += 64;
    }
    if (v > type(uint32).max) {
      v >>= 32;
      len += 32;
    }
    if (v > type(uint16).max) {
      v >>= 16;
      len += 16;
    }
    if (v > type(uint8).max) {
      v >>= 8;
      len += 8;
    }
    if (v > 15) {
      v >>= 4;
      len += 4;
    }
    if (v > 3) {
      v >>= 2;
      len += 2;
    }
    if (v > 1) {
      len += 1;
    }
    return len + 1;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/Address.sol';
import './TransparentProxyBase.sol';

/// @dev This contract is a transparent upgradeability proxy with admin. The admin role is immutable.
contract TransparentProxy is TransparentProxyBase {
  constructor(
    address admin,
    address logic,
    bytes memory data
  ) TransparentProxyBase(admin) {
    _setImplementation(logic);
    if (data.length > 0) {
      Address.functionDelegateCall(logic, data);
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IProxy {
  function upgradeToAndCall(address newImplementation, bytes calldata data) external payable;
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

import './IRemoteAccessBitmask.sol';
import './IAccessController.sol';

interface IManagedAccessController is IAccessController {
  function setTemporaryAdmin(address admin, uint256 expirySeconds) external;

  function getTemporaryAdmin() external view returns (address admin, uint256 expiresAt);

  function renounceTemporaryAdmin() external;

  function setAddress(uint256 id, address newAddress) external;

  struct CallParams {
    uint256 accessFlags;
    uint256 callFlag;
    address callAddr;
    bytes callData;
  }

  function callWithRolesBatch(CallParams[] calldata params) external returns (bytes[] memory result);

  function directCallWithRoles(
    uint256 flags,
    address addr,
    bytes calldata data
  ) external returns (bytes memory result);

  function directCallWithRolesBatch(CallParams[] calldata params) external returns (bytes[] memory result);

  event AddressSet(uint256 indexed id, address indexed newAddress);
  event RolesUpdated(address indexed addr, uint256 flags);
  event TemporaryAdminAssigned(address indexed admin, uint256 expiresAt);
  event AnyRoleModeEnabled();
  event AnyRoleModeBlocked();
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './BaseUpgradeabilityProxy.sol';
import './IProxy.sol';

/// @dev This contract is a transparent upgradeability proxy with admin. The admin role is immutable.
abstract contract TransparentProxyBase is BaseUpgradeabilityProxy, IProxy {
  bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

  constructor(address admin) {
    require(admin != address(0));
    assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1));
    assert(ADMIN_SLOT == bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1));

    bytes32 slot = ADMIN_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, admin)
    }
  }

  // slither-disable-next-line incorrect-modifier
  modifier ifAdmin() {
    if (msg.sender == _admin()) {
      _;
    } else {
      _fallback();
    }
  }

  function _admin() internal view returns (address impl) {
    bytes32 slot = ADMIN_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      impl := sload(slot)
    }
  }

  /// @return impl The address of the implementation.
  function implementation() external ifAdmin returns (address impl) {
    return _implementation();
  }

  /// @dev Upgrade the backing implementation of the proxy and call a function on it.
  function upgradeToAndCall(address logic, bytes calldata data) external payable override ifAdmin {
    _upgradeTo(logic);
    Address.functionDelegateCall(logic, data);
  }

  error AdminCantCallFallback();

  /// @dev Only fall back when the sender is not the admin.
  function _willFallback() internal virtual override {
    if (msg.sender == _admin()) {
      revert AdminCantCallFallback();
    }
    super._willFallback();
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../Errors.sol';
import './Proxy.sol';
import '@openzeppelin/contracts/utils/Address.sol';

/**
 * @title BaseUpgradeabilityProxy
 * @dev This contract implements a proxy that allows to change the
 * implementation address to which it will delegate.
 * Such a change is called an implementation upgrade.
 */
contract BaseUpgradeabilityProxy is Proxy {
  /**
   * @dev Emitted when the implementation is upgraded.
   * @param implementation Address of the new implementation.
   */
  event Upgraded(address indexed implementation);

  /**
   * @dev Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  /**
   * @dev Returns the current implementation.
   * @return impl Address of the current implementation
   */
  function _implementation() internal view override returns (address impl) {
    bytes32 slot = IMPLEMENTATION_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      impl := sload(slot)
    }
  }

  /**
   * @dev Upgrades the proxy to a new implementation.
   * @param newImplementation Address of the new implementation.
   */
  function _upgradeTo(address newImplementation) internal {
    _setImplementation(newImplementation);
    emit Upgraded(newImplementation);
  }

  /**
   * @dev Sets the implementation address of the proxy.
   * @param newImplementation Address of the new implementation.
   */
  function _setImplementation(address newImplementation) internal {
    Value.requireContract(newImplementation);

    bytes32 slot = IMPLEMENTATION_SLOT;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, newImplementation)
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

/**
 * @title Proxy
 * @dev Implements delegation of calls to other contracts, with proper
 * forwarding of return values and bubbling of failures.
 * It defines a fallback function that delegates all calls to the address
 * returned by the abstract _implementation() internal function.
 */
abstract contract Proxy {
  /**
   * @dev Fallback function.
   * Implemented entirely in `_fallback`.
   */
  fallback() external payable {
    _fallback();
  }

  receive() external payable {
    _fallback();
  }

  /**
   * @return The Address of the implementation.
   */
  function _implementation() internal view virtual returns (address);

  /**
   * @dev Delegates execution to an implementation contract.
   * This is a low level function that doesn't return to its internal call site.
   * It will return to the external caller whatever the implementation returns.
   * @param implementation Address to delegate.
   */
  function _delegate(address implementation) internal {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      calldatacopy(0, 0, calldatasize())

      // Call the implementation.
      // out and outsize are 0 because we don't know the size yet.
      let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

      // Copy the returned data.
      returndatacopy(0, 0, returndatasize())

      switch result
      // delegatecall returns 0 on error.
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }

  /**
   * @dev Function that is run as the first thing in the fallback function.
   * Can be redefined in derived contracts to add functionality.
   * Redefinitions must call super._willFallback().
   */
  function _willFallback() internal virtual {}

  /**
   * @dev fallback implementation.
   * Extracted to enable manual triggering.
   */
  function _fallback() internal {
    _willFallback();
    _delegate(_implementation());
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

import './InterestMath.sol';
import './BitUtils.sol';

import 'hardhat/console.sol';

contract LibTestUtils {
  function testLinearInterest(uint256 rate, uint256 ts) external view returns (uint256) {
    return InterestMath.calculateLinearInterest(rate, uint40(ts));
  }

  function testBitLengthShift(uint16 n) external pure returns (uint256) {
    return BitUtils.bitLength(uint256(1) << n);
  }

  function testBitLength(uint256 n) external pure returns (uint256) {
    return BitUtils.bitLength(n);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './WadRayMath.sol';

library InterestMath {
  using WadRayMath for uint256;

  /// @dev Ignoring leap years
  uint256 internal constant SECONDS_PER_YEAR = 365 days;
  uint256 internal constant MILLIS_PER_YEAR = SECONDS_PER_YEAR * 1000;

  /**
   * @dev Function to calculate the interest accumulated using a linear interest rate formula
   * @param rate The annual interest rate, in ray
   * @param lastUpdateTimestamp The timestamp of the last update of the interest
   * @return The interest rate linearly accumulated during the timeDelta, in ray
   **/
  function calculateLinearInterest(uint256 rate, uint40 lastUpdateTimestamp) internal view returns (uint256) {
    return WadRayMath.RAY + (rate * (block.timestamp - lastUpdateTimestamp)) / SECONDS_PER_YEAR;
  }

  /**
   * @dev Function to calculate the interest using a compounded interest rate formula
   * To avoid expensive exponentiation, the calculation is performed using a binomial approximation:
   *
   *  (1+x)^n = 1+n*x+[n/2*(n-1)]*x^2+[n/6*(n-1)*(n-2)*x^3...
   *
   * The approximation slightly underpays liquidity providers and undercharges borrowers, with the advantage of great gas cost reductions
   *
   * @param rate The interest rate, in ray
   * @param lastUpdateTimestamp The timestamp of the last update of the interest
   * @return The interest rate compounded during the timeDelta, in ray
   **/
  function calculateCompoundedInterest(
    uint256 rate,
    uint40 lastUpdateTimestamp,
    uint256 currentTimestamp
  ) internal pure returns (uint256) {
    uint256 exp = currentTimestamp - lastUpdateTimestamp;

    if (exp == 0) {
      return WadRayMath.ray();
    }

    uint256 expMinusOne = exp - 1;
    uint256 expMinusTwo = exp > 2 ? exp - 2 : 0;

    uint256 ratePerSecond = rate / SECONDS_PER_YEAR;

    uint256 basePowerTwo = ratePerSecond.rayMul(ratePerSecond);
    uint256 basePowerThree = basePowerTwo.rayMul(ratePerSecond);

    uint256 secondTerm = (exp * expMinusOne * basePowerTwo) / 2;
    uint256 thirdTerm = (exp * expMinusOne * expMinusTwo * basePowerThree) / 6;

    return WadRayMath.RAY + exp * ratePerSecond + secondTerm + thirdTerm;
  }

  /**
   * @dev Calculates the compounded interest between the timestamp of the last update and the current block timestamp
   * @param rate The interest rate (in ray)
   * @param lastUpdateTimestamp The timestamp from which the interest accumulation needs to be calculated
   **/
  function calculateCompoundedInterest(uint256 rate, uint40 lastUpdateTimestamp) internal view returns (uint256) {
    return calculateCompoundedInterest(rate, lastUpdateTimestamp, block.timestamp);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../Errors.sol';

/// @dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
library WadRayMath {
  uint256 internal constant WAD = 1e18;
  uint256 internal constant halfWAD = WAD / 2;

  uint256 internal constant RAY = 1e27;
  uint256 internal constant halfRAY = RAY / 2;

  uint256 internal constant WAD_RAY_RATIO = 1e9;
  uint256 private constant halfRatio = WAD_RAY_RATIO / 2;

  /// @return One ray, 1e27
  function ray() internal pure returns (uint256) {
    return RAY;
  }

  /// @return One wad, 1e18
  function wad() internal pure returns (uint256) {
    return WAD;
  }

  /// @return Half ray, 1e27/2
  function halfRay() internal pure returns (uint256) {
    return halfRAY;
  }

  /// @return Half ray, 1e18/2
  function halfWad() internal pure returns (uint256) {
    return halfWAD;
  }

  /// @dev Multiplies two wad, rounding half up to the nearest wad
  function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }
    return (a * b + halfWAD) / WAD;
  }

  /// @dev Multiplies two wad, rounding half up to the nearest wad
  function wadMulUp(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }
    return (a * b + WAD - 1) / WAD;
  }

  /// @dev Divides two wad, rounding half up to the nearest wad
  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    return (a * WAD + b / 2) / b;
  }

  function divUp(uint256 a, uint256 b) internal pure returns (uint256) {
    return (a + b / 2) / b;
  }

  /// @dev Multiplies two ray, rounding half up to the nearest ray
  function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }
    return (a * b + halfRAY) / RAY;
  }

  /// @dev Divides two ray, rounding half up to the nearest ray
  function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    return (a * RAY + b / 2) / b;
  }

  /// @dev Casts ray down to wad
  function rayToWad(uint256 a) internal pure returns (uint256) {
    return (a + halfRatio) / WAD_RAY_RATIO;
  }

  /// @dev Converts wad up to ray
  function wadToRay(uint256 a) internal pure returns (uint256) {
    return a * WAD_RAY_RATIO;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/Errors.sol';
import '../tools/math/PercentageMath.sol';
import '../tools/math/WadRayMath.sol';
import '../access/AccessHelper.sol';
import './interfaces/IManagedPriceRouter.sol';
import './interfaces/IPriceFeedChainlinkV3.sol';
import './interfaces/IPriceFeedUniswapV2.sol';
import './OracleRouterBase.sol';
import './FuseBox.sol';

contract PriceGuardOracleBase is OracleRouterBase, FuseBox {
  using WadRayMath for uint256;
  using PercentageMath for uint256;

  uint8 private constant EF_LIMIT_BREACHED_STICKY = 1 << 0;

  constructor(IAccessController acl, address quote) AccessHelper(acl) OracleRouterBase(quote) {}

  event SourceTripped(address indexed asset, uint256 price);

  function pullAssetPrice(address asset, uint256 fuseMask) external override returns (uint256) {
    if (asset == getQuoteAsset()) {
      return WadRayMath.WAD;
    }

    (uint256 v, uint8 flags) = internalReadSource(asset);

    if (v == 0) {
      revert Errors.UnknownPriceAsset(asset);
    }

    if (internalHasAnyBlownFuse(fuseMask)) {
      revert Errors.ExcessiveVolatilityLock(fuseMask);
    }

    if (flags & EF_LIMIT_BREACHED != 0) {
      if (flags & EF_LIMIT_BREACHED_STICKY == 0) {
        emit SourceTripped(asset, v);
        internalSetCustomFlags(asset, 0, EF_LIMIT_BREACHED_STICKY);
      }
      internalBlowFuses(asset);
      v = 0;
    } else if (flags & EF_LIMIT_BREACHED_STICKY != 0) {
      if (internalHasAnyBlownFuse(asset)) {
        v = 0;
      } else {
        internalSetCustomFlags(asset, EF_LIMIT_BREACHED_STICKY, 0);
      }
    }

    return v;
  }

  event SourceToGroupsAdded(address indexed asset, uint256 mask);
  event SourceFromGroupsRemoved(address indexed asset, uint256 mask);

  function attachSource(address asset, bool attach) external override {
    Value.require(asset != address(0));

    uint256 maskSet = internalGetOwnedFuses(msg.sender);
    uint256 maskUnset;
    if (maskSet != 0) {
      if (attach) {
        emit SourceToGroupsAdded(asset, maskSet);
      } else {
        (maskSet, maskUnset) = (0, maskSet);
        emit SourceFromGroupsRemoved(asset, maskUnset);
      }
      internalSetFuses(asset, maskUnset, maskSet);
    }
  }

  function resetSourceGroup() external override {
    uint256 mask = internalGetOwnedFuses(msg.sender);
    if (mask != 0) {
      internalResetFuses(mask);
      emit SourceGroupResetted(msg.sender, mask);
    }
  }

  function internalResetGroup(uint256 mask) internal override {
    internalResetFuses(mask);
  }

  function internalRegisterGroup(address account, uint256 mask) internal override {
    internalSetOwnedFuses(account, mask);
  }

  function groupsOf(address account) external view override returns (uint256 memberOf, uint256 ownerOf) {
    return (internalGetFuses(account), internalGetOwnedFuses(account));
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../Errors.sol';

/// @dev Percentages are defined in basis points. The precision is indicated by ONE. Operations are rounded half up.
library PercentageMath {
  uint16 public constant BP = 1; // basis point
  uint16 public constant PCT = 100 * BP; // basis points per percentage point
  uint16 public constant ONE = 100 * PCT; // basis points per 1 (100%)
  uint16 public constant HALF_ONE = ONE / 2;

  /**
   * @dev Executes a percentage multiplication
   * @param value The value of which the percentage needs to be calculated
   * @param factor Basis points of the value to be calculated
   * @return The percentage of value
   **/
  function percentMul(uint256 value, uint256 factor) internal pure returns (uint256) {
    if (value == 0 || factor == 0) {
      return 0;
    }
    return (value * factor + HALF_ONE) / ONE;
  }

  /**
   * @dev Executes a percentage division
   * @param value The value of which the percentage needs to be calculated
   * @param factor Basis points of the value to be calculated
   * @return The value divided the percentage
   **/
  function percentDiv(uint256 value, uint256 factor) internal pure returns (uint256) {
    return (value * ONE + factor / 2) / factor;
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

import './IPriceRouter.sol';

interface IManagedPriceRouter is IPriceRouter {
  function getPriceSource(address asset) external view returns (PriceSource memory result);

  function getPriceSources(address[] calldata assets) external view returns (PriceSource[] memory result);

  function setPriceSources(address[] calldata assets, PriceSource[] calldata prices) external;

  function setStaticPrices(address[] calldata assets, uint256[] calldata prices) external;

  function setSafePriceRanges(
    address[] calldata assets,
    uint256[] calldata targetPrices,
    uint16[] calldata tolerancePcts
  ) external;

  function getPriceSourceRange(address asset) external view returns (uint256 targetPrice, uint16 tolerancePct);

  function attachSource(address asset, bool attach) external;

  function configureSourceGroup(address account, uint256 mask) external;

  function resetSourceGroup() external;

  function resetSourceGroupByAdmin(uint256 mask) external;
}

enum PriceFeedType {
  StaticValue,
  ChainLinkV3,
  UniSwapV2Pair
}

struct PriceSource {
  PriceFeedType feedType;
  address feedContract;
  uint256 feedConstValue;
  uint8 decimals;
  address crossPrice;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IPriceFeedChainlinkV3 {
  // aka AggregatorV3Interface
  // function decimals() external view returns (uint8);

  // function description() external view returns (string memory);

  // function version() external view returns (uint256);

  // // getRoundData and latestRoundData should both raise "No data present"
  // // if they do not have data to report, instead of returning unset values
  // // which could be misinterpreted as actual reported values.
  // function getRoundData(uint80 _roundId)
  //   external
  //   view
  //   returns (
  //     uint80 roundId,
  //     int256 answer,
  //     uint256 startedAt,
  //     uint256 updatedAt,
  //     uint80 answeredInRound
  //   );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IPriceFeedUniswapV2 {
  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );
  // function price0CumulativeLast() external view returns (uint);
  // function price1CumulativeLast() external view returns (uint);
  // function kLast() external view returns (uint);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/Errors.sol';
import '../tools/math/PercentageMath.sol';
import '../tools/math/WadRayMath.sol';
import '../access/AccessHelper.sol';
import './interfaces/IManagedPriceRouter.sol';
import './interfaces/IPriceFeedChainlinkV3.sol';
import './interfaces/IPriceFeedUniswapV2.sol';
import './PriceSourceBase.sol';

// @dev All prices given out have 18 decimals
abstract contract OracleRouterBase is IManagedPriceRouter, AccessHelper, PriceSourceBase {
  using WadRayMath for uint256;
  using PercentageMath for uint256;

  address private immutable _quote;

  constructor(address quote) {
    _quote = quote;
  }

  function _onlyOracleAdmin() private view {
    if (!hasAnyAcl(msg.sender, AccessFlags.PRICE_ROUTER_ADMIN)) {
      revert Errors.CallerNotOracleAdmin();
    }
  }

  modifier onlyOracleAdmin() {
    _onlyOracleAdmin();
    _;
  }

  uint8 private constant CF_UNISWAP_V2_RESERVE = 1 << 0;

  function getQuoteAsset() public view returns (address) {
    return _quote;
  }

  function getAssetPrice(address asset) public view override returns (uint256) {
    if (asset == _quote) {
      return WadRayMath.WAD;
    }

    (uint256 v, ) = internalReadSource(asset);

    if (v == 0) {
      revert Errors.UnknownPriceAsset(asset);
    }

    return v;
  }

  function getAssetPrices(address[] calldata assets) external view override returns (uint256[] memory result) {
    result = new uint256[](assets.length);
    for (uint256 i = assets.length; i > 0; ) {
      i--;
      result[i] = getAssetPrice(assets[i]);
    }
    return result;
  }

  error UnknownPriceFeedType(uint8);

  function internalGetHandler(uint8 callType)
    internal
    pure
    override
    returns (function(uint8, address, address) internal view returns (uint256, uint32))
  {
    if (callType == uint8(PriceFeedType.ChainLinkV3)) {
      return _readChainlink;
    } else if (callType == uint8(PriceFeedType.UniSwapV2Pair)) {
      return _readUniswapV2;
    }
    revert UnknownPriceFeedType(callType);
  }

  function _readChainlink(
    uint8,
    address feed,
    address
  ) private view returns (uint256, uint32) {
    (, int256 v, , uint256 at, ) = IPriceFeedChainlinkV3(feed).latestRoundData();
    return (uint256(v), uint32(at));
  }

  function _readUniswapV2(
    uint8 callFlags,
    address feed,
    address
  ) private view returns (uint256 v0, uint32 at) {
    uint256 v1;
    (v0, v1, at) = IPriceFeedUniswapV2(feed).getReserves();
    if (v0 != 0) {
      if (callFlags & CF_UNISWAP_V2_RESERVE != 0) {
        (v0, v1) = (v1, v0);
      }
      v0 = v1.wadDiv(v0);
    }
  }

  // slither-disable-next-line calls-loop
  function _setupUniswapV2(address feed, address token) private view returns (uint8 callFlags) {
    if (token == IPriceFeedUniswapV2(feed).token1()) {
      return CF_UNISWAP_V2_RESERVE;
    }
    Value.require(token == IPriceFeedUniswapV2(feed).token0());
  }

  function _getPriceSource(address asset, PriceSource memory result)
    private
    view
    returns (
      bool ok,
      uint8 decimals,
      address crossPrice,
      uint32 maxValidity,
      uint8 flags
    )
  {
    bool staticPrice;
    (ok, decimals, crossPrice, maxValidity, flags, staticPrice) = internalGetConfig(asset);

    if (ok) {
      result.decimals = decimals;
      result.crossPrice = crossPrice;
      // result.maxValidity = maxValidity;

      if (staticPrice) {
        result.feedType = PriceFeedType.StaticValue;
        (result.feedConstValue, ) = internalGetStatic(asset);
      } else {
        uint8 callType;
        (callType, result.feedContract, , , ) = internalGetSource(asset);
        result.feedType = PriceFeedType(callType);
      }
    }
  }

  function getPriceSource(address asset) external view returns (PriceSource memory result) {
    _getPriceSource(asset, result);
  }

  function getPriceSources(address[] calldata assets) external view returns (PriceSource[] memory result) {
    result = new PriceSource[](assets.length);
    for (uint256 i = assets.length; i > 0; ) {
      i--;
      _getPriceSource(assets[i], result[i]);
    }
  }

  /// @param sources  If using a Uniswap price, the decimals field must compensate for tokens that
  ///                 do not have the same as the quote asset decimals.
  ///                 If the quote asset has 18 decimals:
  ///                   If a token has 9 decimals, it must set the decimals value to (9 + 18) = 27
  ///                   If a token has 27 decimals, it must set the decimals value to (27 - 18) = 9
  function setPriceSources(address[] calldata assets, PriceSource[] calldata sources) external onlyOracleAdmin {
    for (uint256 i = assets.length; i > 0; ) {
      i--;
      _setPriceSource(assets[i], sources[i]);
    }
  }

  /// @dev When an asset was configured before, then this call assumes the price to have same decimals, otherwise 18
  function setStaticPrices(address[] calldata assets, uint256[] calldata prices) external onlyOracleAdmin {
    for (uint256 i = assets.length; i > 0; ) {
      i--;
      _setStaticValue(assets[i], prices[i]);
    }
  }

  event SourceStaticUpdated(address indexed asset, uint256 value);
  event SourceStaticConfigured(address indexed asset, uint256 value, uint8 decimals, address xPrice);
  event SourceFeedConfigured(address indexed asset, address source, uint8 decimals, address xPrice, uint8 feedType, uint8 callFlags);

  function _setStaticValue(address asset, uint256 value) private {
    Value.require(asset != _quote);

    internalSetStatic(asset, value, 0);
    emit SourceStaticUpdated(asset, value);
  }

  function _setPriceSource(address asset, PriceSource calldata source) private {
    Value.require(asset != _quote);

    if (source.feedType == PriceFeedType.StaticValue) {
      internalSetStatic(asset, source.feedConstValue, 0);

      emit SourceStaticConfigured(asset, source.feedConstValue, source.decimals, source.crossPrice);
    } else {
      uint8 callFlags;
      if (source.feedType == PriceFeedType.UniSwapV2Pair) {
        callFlags = _setupUniswapV2(source.feedContract, asset);
      }
      internalSetSource(asset, uint8(source.feedType), source.feedContract, callFlags);

      emit SourceFeedConfigured(asset, source.feedContract, source.decimals, source.crossPrice, uint8(source.feedType), callFlags);
    }
    internalSetConfig(asset, source.decimals, source.crossPrice, 0);
  }

  event PriceRangeUpdated(address indexed asset, uint256 targetPrice, uint16 tolerancePct);

  function setSafePriceRanges(
    address[] calldata assets,
    uint256[] calldata targetPrices,
    uint16[] calldata tolerancePcts
  ) external override onlyOracleAdmin {
    Value.require(assets.length == targetPrices.length);
    Value.require(assets.length == tolerancePcts.length);
    for (uint256 i = assets.length; i > 0; ) {
      i--;
      address asset = assets[i];
      Value.require(asset != address(0) && asset != _quote);

      uint256 targetPrice = targetPrices[i];
      uint16 tolerancePct = tolerancePcts[i];

      internalSetPriceTolerance(asset, targetPrice, tolerancePct);
      emit PriceRangeUpdated(asset, targetPrice, tolerancePct);
    }
  }

  function getPriceSourceRange(address asset) external view override returns (uint256 targetPrice, uint16 tolerancePct) {
    (, , , targetPrice, tolerancePct) = internalGetSource(asset);
  }

  event SourceGroupResetted(address indexed account, uint256 mask);

  function resetSourceGroupByAdmin(uint256 mask) external override onlyOracleAdmin {
    internalResetGroup(mask);
    emit SourceGroupResetted(address(0), mask);
  }

  function internalResetGroup(uint256 mask) internal virtual;

  function internalRegisterGroup(address account, uint256 mask) internal virtual;

  event SourceGroupConfigured(address indexed account, uint256 mask);

  function configureSourceGroup(address account, uint256 mask) external override onlyOracleAdmin {
    Value.require(account != address(0));
    internalRegisterGroup(account, mask);
    emit SourceGroupConfigured(account, mask);
  }

  function groupsOf(address) external view virtual returns (uint256 memberOf, uint256 ownerOf);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/Errors.sol';
import '../tools/math/PercentageMath.sol';
import '../tools/math/WadRayMath.sol';
import './interfaces/IManagedPriceRouter.sol';

abstract contract FuseBox {
  using WadRayMath for uint256;
  using PercentageMath for uint256;

  mapping(address => uint256) private _fuseOwners;
  mapping(address => uint256) private _fuseMasks;
  uint256 private _fuseBox;

  function internalBlowFuses(address addr) internal returns (bool blown) {
    uint256 mask = _fuseMasks[addr];
    if (mask != 0) {
      uint256 fuseBox = _fuseBox;
      if ((mask &= ~fuseBox) != 0) {
        _fuseBox = fuseBox | mask;
        internalFuseBlown(addr, fuseBox, mask);
        blown = true;
      }
    }
  }

  function internalFuseBlown(
    address addr,
    uint256 fuseBoxBefore,
    uint256 blownFuses
  ) internal virtual {}

  function internalSetFuses(
    address addr,
    uint256 unsetMask,
    uint256 setMask
  ) internal {
    if ((unsetMask = ~unsetMask) != 0) {
      setMask |= _fuseMasks[addr] & unsetMask;
    }
    _fuseMasks[addr] = setMask;
  }

  function internalGetFuses(address addr) internal view returns (uint256) {
    return _fuseMasks[addr];
  }

  function internalHasAnyBlownFuse(uint256 mask) internal view returns (bool) {
    return mask != 0 && (mask & _fuseBox != 0);
  }

  function internalHasAnyBlownFuse(address addr) internal view returns (bool) {
    return internalHasAnyBlownFuse(_fuseMasks[addr]);
  }

  function internalHasAnyBlownFuse(address addr, uint256 mask) internal view returns (bool) {
    return mask != 0 && internalHasAnyBlownFuse(mask & _fuseMasks[addr]);
  }

  function internalGetOwnedFuses(address owner) internal view returns (uint256) {
    return _fuseOwners[owner];
  }

  function internalResetFuses(uint256 mask) internal {
    _fuseBox &= ~mask;
  }

  function internalIsOwnerOfAllFuses(address owner, uint256 mask) internal view returns (bool) {
    return mask & ~_fuseOwners[owner] == 0;
  }

  function internalSetOwnedFuses(address owner, uint256 mask) internal {
    _fuseOwners[owner] = mask;
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './IFallbackPriceOracle.sol';

interface IPriceRouter is IFallbackPriceOracle {
  function getAssetPrices(address[] calldata asset) external view returns (uint256[] memory);

  function pullAssetPrice(address asset, uint256 fuseMask) external returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IFallbackPriceOracle {
  function getQuoteAsset() external view returns (address);

  function getAssetPrice(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/Errors.sol';
import '../tools/math/PercentageMath.sol';
import '../tools/math/WadRayMath.sol';

abstract contract PriceSourceBase {
  using WadRayMath for uint256;
  using PercentageMath for uint256;

  // struct Source {
  //   uint4 sourceType;
  //   uint6 decimals;
  //   uint6 internalFlags;
  //   uint8 maxValidity; // minutes

  //   address source;
  //   uint8 callFlags;

  //   uint8 tolerance;
  //   uint56 target;
  // }

  uint8 private constant SOURCE_TYPE_OFS = 0;
  uint8 private constant SOURCE_TYPE_BIT = 4;
  uint256 private constant SOURCE_TYPE_MASK = (2**SOURCE_TYPE_BIT) - 1;

  uint8 private constant DECIMALS_OFS = SOURCE_TYPE_OFS + SOURCE_TYPE_BIT;
  uint8 private constant DECIMALS_BIT = 6;
  uint256 private constant DECIMALS_MASK = (2**DECIMALS_BIT) - 1;

  uint8 private constant FLAGS_OFS = DECIMALS_OFS + DECIMALS_BIT;
  uint8 private constant FLAGS_BIT = 6;
  uint256 private constant FLAGS_MASK = (2**FLAGS_BIT) - 1;

  uint256 private constant FLAG_CROSS_PRICED = 1 << (FLAGS_OFS + FLAGS_BIT - 1);
  uint8 internal constant EF_LIMIT_BREACHED = uint8(FLAG_CROSS_PRICED >> FLAGS_OFS);
  uint8 private constant CUSTOM_FLAG_MASK = EF_LIMIT_BREACHED - 1;

  uint8 private constant VALIDITY_OFS = FLAGS_OFS + FLAGS_BIT;
  uint8 private constant VALIDITY_BIT = 8;
  uint256 private constant VALIDITY_MASK = (2**VALIDITY_BIT) - 1;

  uint8 private constant PAYLOAD_OFS = VALIDITY_OFS + VALIDITY_BIT;

  uint8 private constant FEED_POST_PAYLOAD_OFS = PAYLOAD_OFS + 160 + 8;
  uint256 private constant FEED_PAYLOAD_CONFIG_AND_SOURCE_TYPE_MASK = (uint256(1) << FEED_POST_PAYLOAD_OFS) - 1;

  uint256 private constant MAX_STATIC_VALUE = (type(uint256).max << (PAYLOAD_OFS + 32)) >> (PAYLOAD_OFS + 32);

  uint256 private constant CONFIG_AND_SOURCE_TYPE_MASK = (uint256(1) << PAYLOAD_OFS) - 1;
  uint256 private constant CONFIG_MASK = CONFIG_AND_SOURCE_TYPE_MASK & ~SOURCE_TYPE_MASK;
  uint256 private constant INVERSE_CONFIG_MASK = ~CONFIG_MASK;

  // struct StaticSource {
  //   uint8 sourceType == 0;
  //   uint6 decimals;
  //   uint6 internalFlags;
  //   uint8 maxValidity; // minutes

  //   uint32 updatedAt;
  //   uint200 staticValue;
  // }

  struct CallHandler {
    function(uint8, address, address) internal view returns (uint256, uint32) handler;
  }

  mapping(address => uint256) private _encodedSources;
  mapping(address => address) private _crossTokens;
  mapping(address => uint256) private _fuseMasks;

  function internalReadSource(address token) internal view returns (uint256, uint8) {
    return _readSource(token, true);
  }

  function _readSource(address token, bool notNested) private view returns (uint256, uint8 resultFlags) {
    uint256 encoded = _encodedSources[token];
    if (encoded == 0) {
      return (0, 0);
    }

    uint8 callType = uint8(encoded & SOURCE_TYPE_MASK);

    (uint256 v, uint32 t) = callType != 0 ? _callSource(callType, encoded, token) : _callStatic(encoded);

    uint8 maxValidity = uint8(encoded >> VALIDITY_OFS);
    require(maxValidity == 0 || t == 0 || t + maxValidity * 1 minutes >= block.timestamp);

    resultFlags = uint8((encoded >> FLAGS_OFS) & FLAGS_MASK);
    uint8 decimals = uint8(((encoded >> DECIMALS_OFS) + 18) & DECIMALS_MASK);

    if (encoded & FLAG_CROSS_PRICED != 0) {
      State.require(notNested);
      uint256 vc;
      (vc, ) = _readSource(_crossTokens[token], false);
      v *= vc;
      decimals += 18;
    }

    if (decimals > 18) {
      v = v.divUp(10**uint8(decimals - 18));
    } else {
      v *= 10**uint8(18 - decimals);
    }

    if (callType != 0 && _checkLimits(v, encoded)) {
      resultFlags |= EF_LIMIT_BREACHED;
    }

    return (v, resultFlags);
  }

  uint256 private constant TARGET_UNIT = 10**9;
  uint256 private constant TOLERANCE_ONE = 800;

  function _callSource(
    uint8 callType,
    uint256 encoded,
    address token
  ) private view returns (uint256 v, uint32 t) {
    return internalGetHandler(callType)(uint8(encoded >> (PAYLOAD_OFS + 160)), address(uint160(encoded >> PAYLOAD_OFS)), token);
  }

  function _checkLimits(uint256 v, uint256 encoded) private pure returns (bool) {
    encoded >>= FEED_POST_PAYLOAD_OFS;
    uint8 tolerance = uint8(encoded);
    uint256 target = encoded >> 8;
    target *= TARGET_UNIT;

    v = v > target ? v - target : target - v;
    return (v * TOLERANCE_ONE > target * tolerance);
  }

  function _callStatic(uint256 encoded) private pure returns (uint256 v, uint32 t) {
    encoded >>= PAYLOAD_OFS;
    return (encoded >> 32, uint32(encoded));
  }

  function internalGetHandler(uint8 callType)
    internal
    view
    virtual
    returns (function(uint8, address, address) internal view returns (uint256, uint32));

  function internalSetStatic(
    address token,
    uint256 value,
    uint32 since
  ) internal {
    uint256 encoded = _encodedSources[token];
    require(value <= MAX_STATIC_VALUE);

    if (value == 0) {
      since = 0;
    } else if (since == 0) {
      since = uint32(block.timestamp);
    }

    value = (value << 32) | since;
    _encodedSources[token] = (value << PAYLOAD_OFS) | (encoded & CONFIG_MASK);
  }

  function internalUnsetSource(address token) internal {
    delete _encodedSources[token];
  }

  function internalSetCustomFlags(
    address token,
    uint8 unsetFlags,
    uint8 setFlags
  ) internal {
    Value.require((unsetFlags | setFlags) <= CUSTOM_FLAG_MASK);

    uint256 encoded = _encodedSources[token];

    if (unsetFlags != 0) {
      encoded &= ~(uint256(unsetFlags) << FLAGS_OFS);
    }
    encoded |= uint256(setFlags) << FLAGS_OFS;

    _encodedSources[token] = encoded;
  }

  function internalSetSource(
    address token,
    uint8 callType,
    address feed,
    uint8 callFlags
  ) internal {
    Value.require(feed != address(0));
    Value.require(callType > 0 && callType <= SOURCE_TYPE_MASK);

    internalGetHandler(callType);

    uint256 encoded = _encodedSources[token] & CONFIG_MASK;
    encoded |= callType | (((uint256(callFlags) << 160) | uint160(feed)) << PAYLOAD_OFS);

    _encodedSources[token] = encoded;
  }

  function internalSetPriceTolerance(
    address token,
    uint256 targetPrice,
    uint16 tolerancePct
  ) internal {
    uint256 encoded = _encodedSources[token];
    State.require(encoded & SOURCE_TYPE_MASK != 0);

    uint256 v;
    if (targetPrice != 0) {
      v = uint256(tolerancePct).percentMul(TOLERANCE_ONE);
      Value.require(v <= type(uint8).max);

      targetPrice = targetPrice.divUp(TARGET_UNIT);
      Value.require(targetPrice > 0);
      v |= targetPrice << 8;

      v <<= FEED_POST_PAYLOAD_OFS;
    }

    _encodedSources[token] = v | (encoded & FEED_PAYLOAD_CONFIG_AND_SOURCE_TYPE_MASK);
  }

  function _ensureCrossPriceToken(address crossPrice) private view {
    uint256 encoded = _encodedSources[crossPrice];

    Value.require(encoded != 0);
    State.require(encoded & FLAG_CROSS_PRICED == 0);
    State.require(_crossTokens[crossPrice] == crossPrice);
  }

  function internalSetConfig(
    address token,
    uint8 decimals,
    address crossPrice,
    uint32 maxValidity
  ) internal {
    uint256 encoded = _encodedSources[token];
    State.require(encoded != 0);

    Value.require(decimals <= DECIMALS_MASK);
    decimals = uint8(((DECIMALS_MASK - 17) + decimals) & DECIMALS_MASK);

    maxValidity = maxValidity == type(uint32).max ? 0 : (maxValidity + 1 minutes - 1) / 1 minutes;
    Value.require(maxValidity <= type(uint8).max);

    if (crossPrice != address(0) && crossPrice != token) {
      _ensureCrossPriceToken(crossPrice);
      encoded |= FLAG_CROSS_PRICED;
    } else {
      encoded &= ~FLAG_CROSS_PRICED;
    }

    encoded &= ~(VALIDITY_MASK << VALIDITY_OFS) | (DECIMALS_MASK << DECIMALS_OFS);
    _encodedSources[token] = encoded | (uint256(maxValidity) << VALIDITY_OFS) | (uint256(decimals) << DECIMALS_OFS);
    _crossTokens[token] = crossPrice;
  }

  function internalGetConfig(address token)
    internal
    view
    returns (
      bool ok,
      uint8 decimals,
      address crossPrice,
      uint32 maxValidity,
      uint8 flags,
      bool staticPrice
    )
  {
    uint256 encoded = _encodedSources[token];
    if (encoded != 0) {
      ok = true;
      staticPrice = encoded & SOURCE_TYPE_MASK == 0;

      decimals = uint8(((encoded >> DECIMALS_OFS) + 18) & DECIMALS_MASK);
      maxValidity = uint8(encoded >> VALIDITY_OFS);

      if (encoded & FLAG_CROSS_PRICED != 0) {
        crossPrice = _crossTokens[token];
      }

      flags = uint8((encoded >> FLAGS_OFS) & CUSTOM_FLAG_MASK);
    }
  }

  function internalGetSource(address token)
    internal
    view
    returns (
      uint8 callType,
      address feed,
      uint8 callFlags,
      uint256 target,
      uint16 tolerance
    )
  {
    uint256 encoded = _encodedSources[token];
    if (encoded != 0) {
      State.require((callType = uint8(encoded & SOURCE_TYPE_MASK)) != 0);
      encoded >>= PAYLOAD_OFS;

      feed = address(uint160(encoded));
      encoded >>= 160;
      callFlags = uint8(encoded);
      encoded >>= 8;

      tolerance = uint16(uint256(uint8(encoded)).percentDiv(TOLERANCE_ONE));
      target = (encoded >> 8) * TARGET_UNIT;
    }
  }

  function internalGetStatic(address token) internal view returns (uint256, uint32) {
    uint256 encoded = _encodedSources[token];
    State.require(encoded & SOURCE_TYPE_MASK == 0);
    encoded >>= PAYLOAD_OFS;

    return (encoded >> 32, uint32(encoded));
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/Errors.sol';
import '../tools/math/PercentageMath.sol';
import '../tools/math/WadRayMath.sol';
import '../access/AccessHelper.sol';
import './interfaces/IManagedPriceRouter.sol';
import './interfaces/IPriceFeedChainlinkV3.sol';
import './interfaces/IPriceFeedUniswapV2.sol';
import './OracleRouterBase.sol';

contract OracleRouter is OracleRouterBase {
  using WadRayMath for uint256;
  using PercentageMath for uint256;

  constructor(IAccessController acl, address quote) AccessHelper(acl) OracleRouterBase(quote) {}

  function pullAssetPrice(address asset, uint256) external view override returns (uint256) {
    return getAssetPrice(asset);
  }

  function attachSource(address asset, bool) external virtual override {
    Value.require(asset != address(0));
  }

  function resetSourceGroup() external virtual override {}

  function internalResetGroup(uint256 mask) internal override {}

  function internalRegisterGroup(address account, uint256 mask) internal override {}

  function groupsOf(address) external pure override returns (uint256 memberOf, uint256 ownerOf) {
    return (0, 0);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../interfaces/IPriceFeedUniswapV2.sol';

contract MockUniswapV2 is IPriceFeedUniswapV2 {
  address public token0;
  address public token1;

  uint112 private reserve0_;
  uint112 private reserve1_;

  constructor(address _token0, address _token1) {
    token0 = _token0;
    token1 = _token1;
  }

  function setReserves(uint112 _reserve0, uint112 _reserve1) external {
    reserve0_ = _reserve0;
    reserve1_ = _reserve1;
  }

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    )
  {
    return (reserve0_, reserve1_, 0);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../interfaces/IPriceFeedChainlinkV3.sol';

contract MockChainlinkV3 is IPriceFeedChainlinkV3 {
  int256 private answer_;
  uint256 private updatedAt_;

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return (0, answer_, 0, updatedAt_, 0);
  }

  function setAnswer(int256 _answer) external {
    answer_ = _answer;
  }

  function setUpdatedAt(uint256 at) external {
    updatedAt_ = at;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '../tools/SafeERC20.sol';
import '../tools/Errors.sol';
import '../tools/tokens/ERC20BalancelessBase.sol';
import '../libraries/Balances.sol';
import '../libraries/AddressExt.sol';
import '../tools/tokens/IERC20.sol';
import '../access/AccessHelper.sol';
import '../pricing/PricingHelper.sol';
import '../funds/Collateralized.sol';
import '../interfaces/IPremiumDistributor.sol';
import '../interfaces/IPremiumActuary.sol';
import '../interfaces/IPremiumSource.sol';
import '../interfaces/IInsuredPool.sol';
import '../tools/math/WadRayMath.sol';
import './BalancerLib2.sol';

import 'hardhat/console.sol';

contract PremiumFundBase is IPremiumDistributor, AccessHelper, PricingHelper, Collateralized {
  using WadRayMath for uint256;
  using SafeERC20 for IERC20;
  using BalancerLib2 for BalancerLib2.AssetBalancer;
  using Balances for Balances.RateAcc;
  using EnumerableSet for EnumerableSet.AddressSet;

  mapping(address => BalancerLib2.AssetBalancer) internal _balancers; // [actuary]

  enum ActuaryState {
    Unknown,
    Inactive,
    Active,
    Paused
  }

  struct TokenInfo {
    EnumerableSet.AddressSet activeSources;
    uint32 nextReplenish;
  }

  struct SourceBalance {
    uint128 debt;
    uint96 rate;
    uint32 updatedAt;
  }

  uint8 private constant TS_PRESENT = 1 << 0;
  uint8 private constant TS_SUSPENDED = 1 << 1;

  struct TokenState {
    uint128 collectedFees;
    uint8 flags;
  }

  struct ActuaryConfig {
    mapping(address => TokenInfo) tokens; // [token]
    mapping(address => address) sourceToken; // [source] => token
    mapping(address => SourceBalance) sourceBalances; // [source] - to support shared tokens among different sources
    BalancerLib2.AssetConfig defaultConfig;
    ActuaryState state;
  }

  mapping(address => ActuaryConfig) internal _configs; // [actuary]
  mapping(address => TokenState) private _tokens; // [token]
  mapping(address => EnumerableSet.AddressSet) private _tokenActuaries; // [token]

  address[] private _knownTokens;

  constructor(IAccessController acl, address collateral_) AccessHelper(acl) Collateralized(collateral_) PricingHelper(_getPricerByAcl(acl)) {}

  function remoteAcl() internal view override(AccessHelper, PricingHelper) returns (IAccessController pricer) {
    return AccessHelper.remoteAcl();
  }

  event ActuaryAdded(address indexed actuary);
  event ActuaryRemoved(address indexed actuary);

  function registerPremiumActuary(address actuary, bool register) external virtual aclHas(AccessFlags.INSURER_ADMIN) {
    ActuaryConfig storage config = _configs[actuary];
    address cc = collateral();

    if (register) {
      State.require(config.state < ActuaryState.Active);
      Value.require(IPremiumActuary(actuary).collateral() == cc);
      if (_markTokenAsPresent(cc)) {
        _balancers[actuary].configs[cc].price = uint152(WadRayMath.WAD);
      }

      config.state = ActuaryState.Active;
      _tokenActuaries[cc].add(actuary);
      emit ActuaryAdded(actuary);
    } else if (config.state >= ActuaryState.Active) {
      config.state = ActuaryState.Inactive;
      _tokenActuaries[cc].remove(actuary);
      emit ActuaryRemoved(actuary);
    }
  }

  event ActuaryPaused(address indexed actuary, bool paused);
  event ActuaryTokenPaused(address indexed actuary, address indexed token, bool paused);
  event TokenPaused(address indexed token, bool paused);

  function setPaused(address actuary, bool paused) external onlyEmergencyAdmin {
    ActuaryConfig storage config = _configs[actuary];
    State.require(config.state >= ActuaryState.Active);

    config.state = paused ? ActuaryState.Paused : ActuaryState.Active;
    emit ActuaryPaused(actuary, paused);
  }

  function isPaused(address actuary) public view returns (bool) {
    return _configs[actuary].state == ActuaryState.Paused;
  }

  function setPaused(
    address actuary,
    address token,
    bool paused
  ) external onlyEmergencyAdmin {
    ActuaryConfig storage config = _configs[actuary];
    State.require(config.state > ActuaryState.Unknown);
    Value.require(token != address(0));

    BalancerLib2.AssetConfig storage assetConfig = _balancers[actuary].configs[token];
    uint16 flags = assetConfig.flags;
    assetConfig.flags = paused ? flags | BalancerLib2.BF_SUSPENDED : flags & ~BalancerLib2.BF_SUSPENDED;
    emit ActuaryTokenPaused(actuary, token, paused);
  }

  function isPaused(address actuary, address token) public view returns (bool) {
    ActuaryState state = _configs[actuary].state;
    if (state == ActuaryState.Active) {
      return _balancers[actuary].configs[token].flags & BalancerLib2.BF_SUSPENDED != 0;
    }
    return state == ActuaryState.Paused;
  }

  function setPausedToken(address token, bool paused) external onlyEmergencyAdmin {
    Value.require(token != address(0));

    TokenState storage state = _tokens[token];
    uint8 flags = state.flags;
    state.flags = paused ? flags | TS_SUSPENDED : flags & ~TS_SUSPENDED;
    emit TokenPaused(token, paused);
  }

  function isPausedToken(address token) public view returns (bool) {
    return _tokens[token].flags & TS_SUSPENDED != 0;
  }

  uint8 private constant SOURCE_MULTI_MODE_MASK = 3;
  uint8 private constant SMM_SOLO = 0;
  uint8 private constant SMM_MANY_NO_LIST = 1;
  uint8 private constant SMM_LIST = 2;

  event ActuarySourceAdded(address indexed actuary, address indexed source, address indexed token);
  event ActuarySourceRemoved(address indexed actuary, address indexed source, address indexed token);

  function registerPremiumSource(address source, bool register) external override {
    address actuary = msg.sender;

    ActuaryConfig storage config = _configs[actuary];
    State.require(config.state >= ActuaryState.Active);

    if (register) {
      Value.require(source != address(0) && source != collateral());
      // NB! a source will actually be added on non-zero rate only
      require(config.sourceToken[source] == address(0));

      address targetToken = IPremiumSource(source).premiumToken();
      _ensureNonCollateral(actuary, targetToken);
      _markTokenAsPresent(targetToken);
      config.sourceToken[source] = targetToken;
      _tokenActuaries[targetToken].add(actuary);
      emit ActuarySourceAdded(actuary, source, targetToken);
    } else {
      address targetToken = config.sourceToken[source];
      if (targetToken != address(0)) {
        if (_removePremiumSource(config, _balancers[actuary], source, targetToken)) {
          _tokenActuaries[targetToken].remove(actuary);
        }
        emit ActuarySourceRemoved(actuary, source, targetToken);
      }
    }
  }

  function _ensureNonCollateral(address actuary, address token) private view {
    Value.require(token != IPremiumActuary(actuary).collateral());
  }

  function _markTokenAsPresent(address token) private returns (bool) {
    require(token != address(0));
    TokenState storage state = _tokens[token];
    uint8 flags = state.flags;
    if (flags & TS_PRESENT == 0) {
      state.flags = flags | TS_PRESENT;
      _knownTokens.push(token);
      return true;
    }
    return false;
  }

  function _addPremiumSource(
    ActuaryConfig storage config,
    BalancerLib2.AssetBalancer storage balancer,
    address targetToken,
    address source
  ) private {
    EnumerableSet.AddressSet storage activeSources = config.tokens[targetToken].activeSources;

    State.require(activeSources.add(source));

    if (activeSources.length() == 1) {
      BalancerLib2.AssetBalance storage balance = balancer.balances[source];

      require(balance.rateValue == 0);
      // re-activation should keep price
      uint152 price = balance.accumAmount == 0 ? 0 : balancer.configs[targetToken].price;
      balancer.configs[targetToken] = config.defaultConfig;
      balancer.configs[targetToken].price = price;
    }
  }

  function _removePremiumSource(
    ActuaryConfig storage config,
    BalancerLib2.AssetBalancer storage balancer,
    address source,
    address targetToken
  ) private returns (bool allRemoved) {
    delete config.sourceToken[source];
    EnumerableSet.AddressSet storage activeSources = config.tokens[targetToken].activeSources;

    if (activeSources.remove(source)) {
      BalancerLib2.AssetConfig storage balancerConfig = balancer.configs[targetToken];

      SourceBalance storage sBalance = config.sourceBalances[source];
      uint96 rate = balancer.decRate(targetToken, sBalance.rate);

      delete config.sourceBalances[source];

      if (activeSources.length() == 0) {
        require(rate == 0);
        balancerConfig.flags |= BalancerLib2.BF_FINISHED;

        allRemoved = true;
      }
    } else {
      allRemoved = activeSources.length() == 0;
    }
  }

  function _ensureActuary(address actuary) private view returns (ActuaryConfig storage config) {
    config = _configs[actuary];
    State.require(config.state >= ActuaryState.Active);
  }

  function _ensureActiveActuary(address actuary) private view returns (ActuaryConfig storage config) {
    config = _configs[actuary];
    State.require(config.state == ActuaryState.Active);
  }

  event PremiumAllocationUpdated(
    address indexed actuary,
    address indexed source,
    address indexed token,
    uint256 increment,
    uint256 rate,
    bool underprovisioned
  );

  function _premiumAllocationUpdated(
    ActuaryConfig storage config,
    address actuary,
    address source,
    address token,
    uint256 increment,
    uint256 rate,
    bool checkSuspended
  )
    private
    returns (
      address targetToken,
      BalancerLib2.AssetBalancer storage balancer,
      SourceBalance storage sBalance
    )
  {
    Value.require(source != address(0));
    balancer = _balancers[actuary];

    sBalance = config.sourceBalances[source];
    (uint96 lastRate, uint32 updatedAt) = (sBalance.rate, sBalance.updatedAt);

    if (token == address(0)) {
      // this is a call from the actuary - it doesnt know about tokens, only about sources
      targetToken = config.sourceToken[source];
      Value.require(targetToken != address(0));

      if (updatedAt == 0 && rate > 0) {
        _addPremiumSource(config, balancer, targetToken, source);
      }
    } else {
      // this is a sync call from a user - who knows about tokens, but not about sources
      targetToken = token;
      rate = lastRate;
      increment = rate * (uint32(block.timestamp - updatedAt));
    }

    bool underprovisioned = !balancer.replenishAsset(
      BalancerLib2.ReplenishParams({actuary: actuary, source: source, token: targetToken, replenishFn: _replenishFn}),
      increment,
      uint96(rate),
      lastRate,
      checkSuspended
    );
    emit PremiumAllocationUpdated(actuary, source, token, increment, rate, underprovisioned);

    if (underprovisioned) {
      // the source failed to keep the promised premium rate, stop the rate to avoid false inflow
      sBalance.rate = 0;
    } else if (lastRate != rate) {
      Value.require((sBalance.rate = uint96(rate)) == rate);
    }
    sBalance.updatedAt = uint32(block.timestamp);
  }

  function premiumAllocationUpdated(
    address source,
    uint256,
    uint256 increment,
    uint256 rate
  ) external override {
    ActuaryConfig storage config = _ensureActuary(msg.sender);
    Value.require(source != address(0));
    Value.require(rate > 0);

    _premiumAllocationUpdated(config, msg.sender, source, address(0), increment, rate, false);
  }

  function premiumAllocationFinished(
    address source,
    uint256,
    uint256 increment
  ) external override returns (uint256 premiumDebt) {
    ActuaryConfig storage config = _ensureActuary(msg.sender);
    Value.require(source != address(0));

    (address targetToken, BalancerLib2.AssetBalancer storage balancer, SourceBalance storage sBalance) = _premiumAllocationUpdated(
      config,
      msg.sender,
      source,
      address(0),
      increment,
      0,
      false
    );

    premiumDebt = sBalance.debt;
    if (premiumDebt > 0) {
      sBalance.debt = 0;
    }

    _removePremiumSource(config, balancer, source, targetToken);
    emit ActuarySourceRemoved(msg.sender, source, targetToken);
  }

  function _replenishFn(BalancerLib2.ReplenishParams memory params, uint256 requiredValue)
    private
    returns (
      uint256 replenishedAmount,
      uint256 replenishedValue,
      uint256 expectedValue
    )
  {
    /* ============================================================ */
    /* ============================================================ */
    /* ============================================================ */
    /* WARNING! Balancer logic and state MUST NOT be accessed here! */
    /* ============================================================ */
    /* ============================================================ */
    /* ============================================================ */

    ActuaryConfig storage config = _configs[params.actuary];

    if (params.source == address(0)) {
      // this is called by auto-replenishment during swap - it is not related to any specific source
      // will auto-replenish from one source only to keep gas cost stable
      params.source = _sourceForReplenish(config, params.token);
    }

    SourceBalance storage balance = config.sourceBalances[params.source];
    {
      uint32 cur = uint32(block.timestamp);
      if (cur > balance.updatedAt) {
        expectedValue = uint256(cur - balance.updatedAt) * balance.rate;
        balance.updatedAt = cur;
      } else {
        require(cur == balance.updatedAt);
        return (0, 0, 0);
      }
    }
    if (requiredValue < expectedValue) {
      requiredValue = expectedValue;
    }

    uint256 debtValue = balance.debt;
    requiredValue += debtValue;

    if (requiredValue > 0) {
      uint256 missingValue;
      uint256 price = internalPriceOf(params.token);

      (replenishedAmount, missingValue) = _collectPremium(params, requiredValue, price);

      if (debtValue != missingValue) {
        require((balance.debt = uint128(missingValue)) == missingValue);
      }

      replenishedValue = replenishedAmount.wadMul(price);
    }
  }

  function _sourceForReplenish(ActuaryConfig storage config, address token) private returns (address) {
    TokenInfo storage tokenInfo = config.tokens[token];

    uint32 index = tokenInfo.nextReplenish;
    EnumerableSet.AddressSet storage activeSources = tokenInfo.activeSources;
    uint256 length = activeSources.length();
    if (index >= length) {
      index = 0;
    }
    tokenInfo.nextReplenish = index + 1;

    return activeSources.at(index);
  }

  function _collectPremium(
    BalancerLib2.ReplenishParams memory params,
    uint256 requiredValue,
    uint256 price
  ) private returns (uint256 collectedAmount, uint256 missingValue) {
    uint256 requiredAmount = requiredValue.wadDiv(price);
    collectedAmount = _collectPremiumCall(params.actuary, params.source, IERC20(params.token), requiredAmount, requiredValue);
    if (collectedAmount < requiredAmount) {
      missingValue = (requiredAmount - collectedAmount).wadMul(price);

      /*

      // This section of code enables use of CC as an additional way of premium payment

      if (missingValue > 0) {
        // assert(params.token != collateral());
        uint256 collectedValue = _collectPremiumCall(params.actuary, params.source, IERC20(collateral()), missingValue, missingValue);

        if (collectedValue > 0) {
          missingValue -= collectedValue;
          collectedAmount += collectedValue.wadDiv(price);
        }
      }

      */
    }
  }

  event PremiumCollectionFailed(address indexed source, address indexed token, uint256 amount, bool isPanic, bytes reason);

  function _collectPremiumCall(
    address actuary,
    address source,
    IERC20 token,
    uint256 amount,
    uint256 value
  ) private returns (uint256) {
    uint256 balance = token.balanceOf(address(this));

    bool isPanic;
    bytes memory errReason;

    try IPremiumSource(source).collectPremium(actuary, address(token), amount, value) {
      return token.balanceOf(address(this)) - balance;
    } catch Error(string memory reason) {
      errReason = bytes(reason);
    } catch (bytes memory reason) {
      isPanic = true;
      errReason = reason;
    }
    emit PremiumCollectionFailed(source, address(token), amount, isPanic, errReason);

    return 0;
  }

  function priceOf(address token) public view returns (uint256) {
    return internalPriceOf(token);
  }

  function internalPriceOf(address token) internal view virtual returns (uint256) {
    return getPricer().getAssetPrice(token);
  }

  function _ensureToken(address token) private view {
    uint8 flags = _tokens[token].flags;
    State.require(flags & TS_PRESENT != 0);
    if (flags & TS_SUSPENDED != 0) {
      revert Errors.OperationPaused();
    }
  }

  // slither-disable-next-line calls-loop
  function _syncAsset(
    ActuaryConfig storage config,
    address actuary,
    address token,
    uint256 sourceLimit
  ) private returns (uint256) {
    _ensureToken(token);
    Value.require(token != address(0));
    if (collateral() == token) {
      IPremiumActuary(actuary).collectDrawdownPremium();
      return sourceLimit == 0 ? 0 : sourceLimit - 1;
    }

    TokenInfo storage tokenInfo = config.tokens[token];
    EnumerableSet.AddressSet storage activeSources = tokenInfo.activeSources;
    uint256 length = activeSources.length();

    if (length > 0) {
      uint32 index = tokenInfo.nextReplenish;
      if (index >= length) {
        index = 0;
      }
      uint256 stop = index;

      for (; sourceLimit > 0; sourceLimit--) {
        _premiumAllocationUpdated(config, actuary, activeSources.at(index), token, 0, 0, true);
        index++;
        if (index >= length) {
          index = 0;
        }
        if (index == stop) {
          break;
        }
      }

      tokenInfo.nextReplenish = index;
    }

    return sourceLimit;
  }

  function syncAsset(
    address actuary,
    uint256 sourceLimit,
    address targetToken
  ) public {
    if (sourceLimit == 0) {
      sourceLimit = ~sourceLimit;
    }

    ActuaryConfig storage config = _ensureActiveActuary(actuary);
    _syncAsset(config, actuary, targetToken, sourceLimit);
  }

  function syncAssets(
    address actuary,
    uint256 sourceLimit,
    address[] calldata targetTokens
  ) external returns (uint256 i) {
    if (sourceLimit == 0) {
      sourceLimit = ~sourceLimit;
    }

    ActuaryConfig storage config = _ensureActiveActuary(actuary);

    for (; i < targetTokens.length; i++) {
      sourceLimit = _syncAsset(config, actuary, targetTokens[i], sourceLimit);
      if (sourceLimit == 0) {
        break;
      }
    }
  }

  function assetBalance(address actuary, address asset)
    external
    view
    returns (
      uint256 amount,
      uint256 stravation,
      uint256 price,
      uint256 feeFactor
    )
  {
    ActuaryConfig storage config = _configs[actuary];
    if (config.state > ActuaryState.Unknown) {
      (, amount, stravation, price, feeFactor) = _balancers[actuary].assetState(asset);
    }
  }

  function swapAsset(
    address actuary,
    address account,
    address recipient,
    uint256 valueToSwap,
    address targetToken,
    uint256 minAmount
  ) public returns (uint256 tokenAmount) {
    _ensureActiveActuary(actuary);
    _ensureToken(targetToken);
    Value.require(recipient != address(0));

    uint256 fee;
    address burnReceiver;
    uint256 drawdownValue = IPremiumActuary(actuary).collectDrawdownPremium();
    BalancerLib2.AssetBalancer storage balancer = _balancers[actuary];

    if (collateral() == targetToken) {
      (tokenAmount, fee) = balancer.swapExternalAsset(targetToken, valueToSwap, minAmount, drawdownValue);
      if (tokenAmount > 0) {
        if (fee == 0) {
          // use a direct transfer when no fees
          require(tokenAmount == valueToSwap);
          burnReceiver = recipient;
        } else {
          burnReceiver = address(this);
        }
      }
    } else {
      (tokenAmount, fee) = balancer.swapAsset(_replenishParams(actuary, targetToken), valueToSwap, minAmount, drawdownValue);
    }

    if (tokenAmount > 0) {
      IPremiumActuary(actuary).burnPremium(account, valueToSwap, burnReceiver);
      if (burnReceiver != recipient) {
        SafeERC20.safeTransfer(IERC20(targetToken), recipient, tokenAmount);
      }
    }

    if (fee > 0) {
      _addFee(_configs[actuary], targetToken, fee);
    }
  }

  function _addFee(
    ActuaryConfig storage,
    address targetToken,
    uint256 fee
  ) private {
    require((_tokens[targetToken].collectedFees += uint128(fee)) >= fee);
  }

  function availableFee(address targetToken) external view returns (uint256) {
    return _tokens[targetToken].collectedFees;
  }

  function collectFees(
    address[] calldata tokens,
    uint256 minAmount,
    address recipient
  ) external aclHas(AccessFlags.TREASURY) returns (uint256[] memory fees) {
    Value.require(recipient != address(0));
    if (minAmount == 0) {
      minAmount = 1;
    }

    fees = new uint256[](tokens.length);
    for (uint256 i = tokens.length; i > 0; ) {
      i--;
      TokenState storage state = _tokens[tokens[i]];

      uint256 fee = state.collectedFees;
      if (fee >= minAmount) {
        state.collectedFees = 0;
        IERC20(tokens[i]).safeTransfer(recipient, fees[i] = fee);
      }
    }
  }

  struct SwapInstruction {
    uint256 valueToSwap;
    address targetToken;
    uint256 minAmount;
    address recipient;
  }

  function swapAssets(
    address actuary,
    address account,
    address defaultRecepient,
    SwapInstruction[] calldata instructions
  ) external returns (uint256[] memory tokenAmounts) {
    if (instructions.length <= 1) {
      // _ensureActiveActuary is applied inside swapToken invoked via _swapTokensOne
      return instructions.length == 0 ? tokenAmounts : _swapTokensOne(actuary, account, defaultRecepient, instructions[0]);
    }

    _ensureActiveActuary(actuary);

    uint256[] memory fees;
    (tokenAmounts, fees) = _swapTokens(actuary, account, instructions, IPremiumActuary(actuary).collectDrawdownPremium());
    ActuaryConfig storage config = _configs[actuary];

    for (uint256 i = 0; i < instructions.length; i++) {
      address recipient = instructions[i].recipient;
      address targetToken = instructions[i].targetToken;

      SafeERC20.safeTransfer(IERC20(targetToken), recipient == address(0) ? defaultRecepient : recipient, tokenAmounts[i]);

      if (fees[i] > 0) {
        _addFee(config, targetToken, fees[i]);
      }
    }
  }

  function _swapTokens(
    address actuary,
    address account,
    SwapInstruction[] calldata instructions,
    uint256 drawdownValue
  ) private returns (uint256[] memory tokenAmounts, uint256[] memory fees) {
    BalancerLib2.AssetBalancer storage balancer = _balancers[actuary];

    uint256 drawdownBalance = drawdownValue;

    tokenAmounts = new uint256[](instructions.length);
    fees = new uint256[](instructions.length);

    Balances.RateAcc memory totalOrig = balancer.totalBalance;
    Balances.RateAcc memory totalSum;
    (totalSum.accum, totalSum.rate, totalSum.updatedAt) = (totalOrig.accum, totalOrig.rate, totalOrig.updatedAt);
    BalancerLib2.ReplenishParams memory params = _replenishParams(actuary, address(0));

    uint256 totalValue;
    uint256 totalExtValue;
    for (uint256 i = 0; i < instructions.length; i++) {
      _ensureToken(instructions[i].targetToken);

      Balances.RateAcc memory total;
      (total.accum, total.rate, total.updatedAt) = (totalOrig.accum, totalOrig.rate, totalOrig.updatedAt);

      if (collateral() == instructions[i].targetToken) {
        (tokenAmounts[i], fees[i]) = _swapExtTokenInBatch(balancer, instructions[i], drawdownBalance, total);

        if (tokenAmounts[i] > 0) {
          totalExtValue += instructions[i].valueToSwap;
          drawdownBalance -= tokenAmounts[i];
        }
      } else {
        (tokenAmounts[i], fees[i]) = _swapTokenInBatch(balancer, instructions[i], drawdownValue, params, total);

        if (tokenAmounts[i] > 0) {
          _mergeTotals(totalSum, totalOrig, total);
          totalValue += instructions[i].valueToSwap;
        }
      }
    }

    if (totalValue > 0) {
      IPremiumActuary(actuary).burnPremium(account, totalValue, address(0));
    }

    if (totalExtValue > 0) {
      IPremiumActuary(actuary).burnPremium(account, totalExtValue, address(this));
    }

    balancer.totalBalance = totalSum;
  }

  function _replenishParams(address actuary, address targetToken) private pure returns (BalancerLib2.ReplenishParams memory) {
    return BalancerLib2.ReplenishParams({actuary: actuary, source: address(0), token: targetToken, replenishFn: _replenishFn});
  }

  function _swapTokenInBatch(
    BalancerLib2.AssetBalancer storage balancer,
    SwapInstruction calldata instruction,
    uint256 drawdownValue,
    BalancerLib2.ReplenishParams memory params,
    Balances.RateAcc memory total
  ) private returns (uint256 tokenAmount, uint256 fee) {
    params.token = instruction.targetToken;
    (tokenAmount, fee, ) = balancer.swapAssetInBatch(params, instruction.valueToSwap, instruction.minAmount, drawdownValue, total);
  }

  function _swapExtTokenInBatch(
    BalancerLib2.AssetBalancer storage balancer,
    SwapInstruction calldata instruction,
    uint256 drawdownBalance,
    Balances.RateAcc memory total
  ) private view returns (uint256 tokenAmount, uint256 fee) {
    return balancer.swapExternalAssetInBatch(instruction.targetToken, instruction.valueToSwap, instruction.minAmount, drawdownBalance, total);
  }

  function _mergeValue(
    uint256 vSum,
    uint256 vOrig,
    uint256 v,
    uint256 max
  ) private pure returns (uint256) {
    if (vOrig >= v) {
      unchecked {
        v = vOrig - v;
      }
      v = vSum - v;
    } else {
      unchecked {
        v = v - vOrig;
      }
      require((v = vSum + v) <= max);
    }
    return v;
  }

  function _mergeTotals(
    Balances.RateAcc memory totalSum,
    Balances.RateAcc memory totalOrig,
    Balances.RateAcc memory total
  ) private pure {
    if (totalSum.updatedAt != total.updatedAt) {
      totalSum.sync(total.updatedAt);
    }
    totalSum.accum = uint128(_mergeValue(totalSum.accum, totalOrig.accum, total.accum, type(uint128).max));
    totalSum.rate = uint96(_mergeValue(totalSum.rate, totalOrig.rate, total.rate, type(uint96).max));
  }

  function _swapTokensOne(
    address actuary,
    address account,
    address defaultRecepient,
    SwapInstruction calldata instruction
  ) private returns (uint256[] memory tokenAmounts) {
    tokenAmounts = new uint256[](1);

    tokenAmounts[0] = swapAsset(
      actuary,
      account,
      instruction.recipient != address(0) ? instruction.recipient : defaultRecepient,
      instruction.valueToSwap,
      instruction.targetToken,
      instruction.minAmount
    );
  }

  function knownTokens() external view returns (address[] memory) {
    return _knownTokens;
  }

  function actuariesOfToken(address token) public view returns (address[] memory) {
    return _tokenActuaries[token].values();
  }

  function actuaries() external view returns (address[] memory) {
    return actuariesOfToken(collateral());
  }

  function activeSourcesOf(address actuary, address token) external view returns (address[] memory) {
    return _configs[actuary].tokens[token].activeSources.values();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import './tokens/IERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';

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

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    require((value == 0) || (token.allowance(address(this), spender) == 0), 'SafeERC20: approve from non-zero to non-zero allowance');
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
    // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
    // the target address contains contract code and also asserts for success in the low-level call.

    bytes memory returndata = address(token).functionCall(data, 'SafeERC20: low-level call failed');
    if (returndata.length > 0) {
      // Return data is optional
      require(abi.decode(returndata, (bool)), 'SafeERC20: ERC20 operation did not succeed');
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './ERC20DetailsBase.sol';
import './ERC20AllowanceBase.sol';
import './ERC20MintableBase.sol';
import './ERC20PermitBase.sol';

abstract contract ERC20BalancelessBase is ERC20DetailsBase, ERC20AllowanceBase, ERC20PermitBase, ERC20TransferBase {
  function _getPermitDomainName() internal view override returns (bytes memory) {
    return bytes(super.name());
  }

  function _approveByPermit(
    address owner,
    address spender,
    uint256 value
  ) internal override {
    _approve(owner, spender, value);
  }

  function _approveTransferFrom(address owner, uint256 amount) internal override(ERC20AllowanceBase, ERC20TransferBase) {
    ERC20AllowanceBase._approveTransferFrom(owner, amount);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

library Balances {
  struct RateAcc {
    uint128 accum;
    uint96 rate;
    uint32 updatedAt;
  }

  function sync(RateAcc memory b, uint32 at) internal pure returns (RateAcc memory) {
    uint256 adjustment = at - b.updatedAt;
    if (adjustment > 0 && (adjustment = adjustment * b.rate) > 0) {
      adjustment += b.accum;
      require(adjustment == (b.accum = uint128(adjustment)));
    }
    b.updatedAt = at;
    return b;
  }

  // function syncStorage(RateAcc storage b, uint32 at) internal {
  //   uint256 adjustment = at - b.updatedAt;
  //   if (adjustment > 0 && (adjustment = adjustment * b.rate) > 0) {
  //     adjustment += b.accum;
  //     require(adjustment == (b.accum = uint128(adjustment)));
  //   }
  //   b.updatedAt = at;
  // }

  // function setRateStorage(
  //   RateAcc storage b,
  //   uint32 at,
  //   uint256 rate
  // ) internal {
  //   syncStorage(b, at);
  //   require(rate == (b.rate = uint96(rate)));
  // }

  // function setRate(
  //   RateAcc memory b,
  //   uint32 at,
  //   uint256 rate
  // ) internal pure returns (RateAcc memory) {
  //   b = sync(b, at);
  //   require(rate == (b.rate = uint96(rate)));
  //   return b;
  // }

  function setRateAfterSync(RateAcc memory b, uint256 rate) internal view returns (RateAcc memory) {
    require(b.updatedAt == block.timestamp);
    require(rate == (b.rate = uint96(rate)));
    return b;
  }

  // function incRate(
  //   RateAcc memory b,
  //   uint32 at,
  //   uint256 rateIncrement
  // ) internal pure returns (RateAcc memory) {
  //   return setRate(b, at, b.rate + rateIncrement);
  // }

  // function decRate(
  //   RateAcc memory b,
  //   uint32 at,
  //   uint256 rateDecrement
  // ) internal pure returns (RateAcc memory) {
  //   return setRate(b, at, b.rate - rateDecrement);
  // }

  // struct RateAccWithUint8 {
  //   uint120 accum;
  //   uint96 rate;
  //   uint32 updatedAt;
  //   uint8 extra;
  // }

  // function sync(RateAccWithUint8 memory b, uint32 at) internal pure returns (RateAccWithUint8 memory) {
  //   uint256 adjustment = at - b.updatedAt;
  //   if (adjustment > 0 && (adjustment = adjustment * b.rate) > 0) {
  //     adjustment += b.accum;
  //     require(adjustment == (b.accum = uint120(adjustment)));
  //   }
  //   b.updatedAt = at;
  //   return b;
  // }

  // function syncStorage(RateAccWithUint8 storage b, uint32 at) internal {
  //   uint256 adjustment = at - b.updatedAt;
  //   if (adjustment > 0 && (adjustment = adjustment * b.rate) > 0) {
  //     adjustment += b.accum;
  //     require(adjustment == (b.accum = uint120(adjustment)));
  //   }
  //   b.updatedAt = at;
  // }

  // function setRateStorage(
  //   RateAccWithUint8 storage b,
  //   uint32 at,
  //   uint256 rate
  // ) internal {
  //   syncStorage(b, at);
  //   require(rate == (b.rate = uint96(rate)));
  // }

  // function setRate(
  //   RateAccWithUint8 memory b,
  //   uint32 at,
  //   uint256 rate
  // ) internal pure returns (RateAccWithUint8 memory) {
  //   b = sync(b, at);
  //   require(rate == (b.rate = uint96(rate)));
  //   return b;
  // }

  // function incRate(
  //   RateAccWithUint8 memory b,
  //   uint32 at,
  //   uint256 rateIncrement
  // ) internal pure returns (RateAccWithUint8 memory) {
  //   return setRate(b, at, b.rate + rateIncrement);
  // }

  // function decRate(
  //   RateAccWithUint8 memory b,
  //   uint32 at,
  //   uint256 rateDecrement
  // ) internal pure returns (RateAccWithUint8 memory) {
  //   return setRate(b, at, b.rate - rateDecrement);
  // }

  struct RateAccWithUint16 {
    uint120 accum;
    uint88 rate;
    uint32 updatedAt;
    uint16 extra;
  }

  function sync(RateAccWithUint16 memory b, uint32 at) internal pure returns (RateAccWithUint16 memory) {
    uint256 adjustment = at - b.updatedAt;
    if (adjustment > 0 && (adjustment = adjustment * b.rate) > 0) {
      adjustment += b.accum;
      require(adjustment == (b.accum = uint120(adjustment)));
    }
    b.updatedAt = at;
    return b;
  }

  // function syncStorage(RateAccWithUint16 storage b, uint32 at) internal {
  //   uint256 adjustment = at - b.updatedAt;
  //   if (adjustment > 0 && (adjustment = adjustment * b.rate) > 0) {
  //     adjustment += b.accum;
  //     require(adjustment == (b.accum = uint120(adjustment)));
  //   }
  //   b.updatedAt = at;
  // }

  // function setRateStorage(
  //   RateAccWithUint16 storage b,
  //   uint32 at,
  //   uint256 rate
  // ) internal {
  //   syncStorage(b, at);
  //   require(rate == (b.rate = uint88(rate)));
  // }

  // function setRate(
  //   RateAccWithUint16 memory b,
  //   uint32 at,
  //   uint256 rate
  // ) internal pure returns (RateAccWithUint16 memory) {
  //   b = sync(b, at);
  //   require(rate == (b.rate = uint88(rate)));
  //   return b;
  // }

  // function incRate(
  //   RateAccWithUint16 memory b,
  //   uint32 at,
  //   uint256 rateIncrement
  // ) internal pure returns (RateAccWithUint16 memory) {
  //   return setRate(b, at, b.rate + rateIncrement);
  // }

  // function decRate(
  //   RateAccWithUint16 memory b,
  //   uint32 at,
  //   uint256 rateDecrement
  // ) internal pure returns (RateAccWithUint16 memory) {
  //   return setRate(b, at, b.rate - rateDecrement);
  // }

  // struct RateAccWithUint32 {
  //   uint112 accum;
  //   uint80 rate;
  //   uint32 updatedAt;
  //   uint32 extra;
  // }

  // function sync(RateAccWithUint32 memory b, uint32 at) internal pure returns (RateAccWithUint32 memory) {
  //   uint256 adjustment = at - b.updatedAt;
  //   if (adjustment > 0 && (adjustment = adjustment * b.rate) > 0) {
  //     adjustment += b.accum;
  //     require(adjustment == (b.accum = uint112(adjustment)));
  //   }
  //   b.updatedAt = at;
  //   return b;
  // }

  // function syncStorage(RateAccWithUint32 storage b, uint32 at) internal {
  //   uint256 adjustment = at - b.updatedAt;
  //   if (adjustment > 0 && (adjustment = adjustment * b.rate) > 0) {
  //     adjustment += b.accum;
  //     require(adjustment == (b.accum = uint112(adjustment)));
  //   }
  //   b.updatedAt = at;
  // }

  // function setRateStorage(
  //   RateAccWithUint32 storage b,
  //   uint32 at,
  //   uint256 rate
  // ) internal {
  //   syncStorage(b, at);
  //   require(rate == (b.rate = uint80(rate)));
  // }

  // function setRate(
  //   RateAccWithUint32 memory b,
  //   uint32 at,
  //   uint256 rate
  // ) internal pure returns (RateAccWithUint32 memory) {
  //   b = sync(b, at);
  //   require(rate == (b.rate = uint80(rate)));
  //   return b;
  // }

  // function incRate(
  //   RateAccWithUint32 memory b,
  //   uint32 at,
  //   uint256 rateIncrement
  // ) internal pure returns (RateAccWithUint32 memory) {
  //   return setRate(b, at, b.rate + rateIncrement);
  // }

  // function decRate(
  //   RateAccWithUint32 memory b,
  //   uint32 at,
  //   uint256 rateDecrement
  // ) internal pure returns (RateAccWithUint32 memory) {
  //   return setRate(b, at, b.rate - rateDecrement);
  // }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

library AddressExt {
  function addr(uint256 v) internal pure returns (address) {
    return address(uint160(v));
  }

  function ext(uint256 v) internal pure returns (uint96) {
    return uint96(v >> 160);
  }

  function setAddr(uint256 v, address a) internal pure returns (uint256) {
    return (v & ~uint256(type(uint160).max)) | uint160(a);
  }

  function setExt(uint256 v, uint96 e) internal pure returns (uint256) {
    return (v & type(uint160).max) | (uint256(e) << 160);
  }

  function newAddressExt(address a, uint96 e) internal pure returns (uint256) {
    return (uint256(e) << 160) | uint160(a);
  }

  function newAddressExt(address a) internal pure returns (uint256) {
    return uint160(a);
  }

  function unwrap(uint256 v) internal pure returns (address, uint96) {
    return (addr(v), ext(v));
  }
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

import '../tools/Errors.sol';
import '../access/AccessHelper.sol';
import './interfaces/IManagedPriceRouter.sol';

abstract contract PricingHelper {
  IManagedPriceRouter private immutable _pricer;

  constructor(address pricer_) {
    _pricer = IManagedPriceRouter(pricer_);
  }

  function priceOracle() external view returns (address) {
    return address(getPricer());
  }

  function remoteAcl() internal view virtual returns (IAccessController pricer);

  function getPricer() internal view virtual returns (IManagedPriceRouter pricer) {
    pricer = _pricer;
    if (address(pricer) == address(0)) {
      pricer = IManagedPriceRouter(_getPricerByAcl(remoteAcl()));
      State.require(address(pricer) != address(0));
    }
  }

  function _getPricerByAcl(IAccessController acl) internal view returns (address) {
    return address(acl) == address(0) ? address(0) : acl.getAddress(AccessFlags.PRICE_ROUTER);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/Errors.sol';
import '../tools/tokens/IERC20.sol';
import '../interfaces/IManagedCollateralCurrency.sol';
import '../interfaces/ICollateralized.sol';

abstract contract Collateralized is ICollateralized {
  address private immutable _collateral;

  constructor(address collateral_) {
    _collateral = collateral_;
  }

  function collateral() public view virtual override returns (address) {
    return _collateral;
  }

  function _onlyCollateralCurrency() private view {
    Access.require(msg.sender == _collateral);
  }

  modifier onlyCollateralCurrency() {
    _onlyCollateralCurrency();
    _;
  }

  function _onlyLiquidityProvider() private view {
    Access.require(IManagedCollateralCurrency(_collateral).isLiquidityProvider(msg.sender));
  }

  modifier onlyLiquidityProvider() {
    _onlyLiquidityProvider();
    _;
  }

  function transferCollateral(address recipient, uint256 amount) internal {
    // collateral is a trusted token, hence we do not use safeTransfer here
    ensureTransfer(IERC20(collateral()).transfer(recipient, amount));
  }

  function balanceOfCollateral(address account) internal view returns (uint256) {
    return IERC20(collateral()).balanceOf(account);
  }

  function transferCollateralFrom(
    address from,
    address recipient,
    uint256 amount
  ) internal {
    // collateral is a trusted token, hence we do not use safeTransfer here
    ensureTransfer(IERC20(collateral()).transferFrom(from, recipient, amount));
  }

  function transferAvailableCollateralFrom(
    address from,
    address recipient,
    uint256 maxAmount
  ) internal returns (uint256 amount) {
    IERC20 token = IERC20(collateral());
    amount = maxAmount;
    if (amount > (maxAmount = token.allowance(from, address(this)))) {
      if (maxAmount == 0) {
        return 0;
      }
      amount = maxAmount;
    }
    if (amount > (maxAmount = token.balanceOf(from))) {
      if (maxAmount == 0) {
        return 0;
      }
      amount = maxAmount;
    }
    // ensureTransfer(token.transferFrom(from, recipient, amount));
    transferCollateralFrom(from, recipient, amount);
  }

  function ensureTransfer(bool ok) private pure {
    if (!ok) {
      revert Errors.CollateralTransferFailed();
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './ICollateralized.sol';

interface IPremiumDistributor is ICollateralized {
  function premiumAllocationUpdated(
    address insured,
    uint256 accumulated,
    uint256 increment,
    uint256 rate
  ) external;

  function premiumAllocationFinished(
    address insured,
    uint256 accumulated,
    uint256 increment
  ) external returns (uint256 premiumDebt);

  function registerPremiumSource(address insured, bool register) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './ICollateralized.sol';

interface IPremiumActuary is ICollateralized {
  function premiumDistributor() external view returns (address);

  function collectDrawdownPremium() external returns (uint256 availablePremiumValue);

  function burnPremium(
    address account,
    uint256 value,
    address drawdownRecepient
  ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './ICollateralized.sol';

interface IPremiumSource {
  function premiumToken() external view returns (address);

  function collectPremium(
    address actuary,
    address token,
    uint256 amount,
    uint256 value
  ) external;
}

interface IPremiumSourceDelegate {
  function collectPremium(
    address actuary,
    address token,
    uint256 amount,
    uint256 value,
    address recipient
  ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './ICollateralized.sol';

interface IInsuredPool is ICollateralized {
  /// @notice Called by insurer during or after requestJoin() to inform this insured if it was accepted or not
  /// @param accepted true if accepted by the insurer
  function joinProcessed(bool accepted) external;

  /// @notice Invoked by chartered pools to request more coverage demand
  /// @param amount a hint on demand amount, 0 means default
  /// @param loopLimit a max number of iterations
  function pullCoverageDemand(uint256 amount, uint256 loopLimit) external returns (bool);

  /// @notice Get this insured params
  /// @return The insured params
  function insuredParams() external view returns (InsuredParams memory);

  /// @notice Directly offer coverage to the insured
  /// @param offeredAmount The amount of coverage being offered
  /// @return acceptedAmount The amount of coverage accepted by the insured
  /// @return rate The rate that the insured is paying for the coverage
  function offerCoverage(uint256 offeredAmount) external returns (uint256 acceptedAmount, uint256 rate);

  function rateBands() external view returns (InsuredRateBand[] memory bands, uint256 maxBands);
}

struct InsuredParams {
  uint128 minPerInsurer;
}

struct InsuredRateBand {
  uint64 premiumRate;
  uint96 coverageDemand;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/math/Math.sol';
import '../tools/math/WadRayMath.sol';
import '../tools/math/PercentageMath.sol';
import '../libraries/Balances.sol';

import 'hardhat/console.sol';

library BalancerLib2 {
  using WadRayMath for uint256;
  using Balances for Balances.RateAcc;

  struct AssetBalance {
    uint128 accumAmount; // amount of asset
    uint96 rateValue; // value per second
    uint32 applyFrom;
  }

  struct AssetBalancer {
    mapping(address => AssetBalance) balances; // [token] total balance and rate of all sources using this token
    Balances.RateAcc totalBalance; // total VALUE balance and VALUE rate of all sources
    mapping(address => AssetConfig) configs; // [token] token balancing configuration
    uint160 spConst; // value, for (BF_SPM_GLOBAL | BF_SPM_CONSTANT) starvation point mode
    uint32 spFactor; // rate multiplier, for (BF_SPM_GLOBAL | !BF_SPM_CONSTANT) starvation point mode
  }

  struct AssetConfig {
    uint152 price; // target price, wad-multiplier, uint192
    uint64 w; // [0..1] fee control, uint64
    uint32 n; // rate multiplier, for (!BF_SPM_GLOBAL | !BF_SPM_CONSTANT) starvation point mode
    uint16 flags; // starvation point modes and asset states
    uint160 spConst; // value, for (!BF_SPM_GLOBAL | BF_SPM_CONSTANT) starvation point mode
  }

  uint8 private constant FINISHED_OFFSET = 8;

  uint16 internal constant BF_SPM_GLOBAL = 1 << 0;
  uint16 internal constant BF_SPM_CONSTANT = 1 << 1;
  uint16 internal constant BF_SPM_MAX_WITH_CONST = 1 << 2; // only applicable with BF_SPM_CONSTANT

  uint16 internal constant BF_AUTO_REPLENISH = 1 << 6; // pull a source at every swap
  uint16 internal constant BF_FINISHED = 1 << 7; // no more sources for this token

  uint16 internal constant BF_SPM_MASK = BF_SPM_GLOBAL | BF_SPM_CONSTANT | BF_SPM_MAX_WITH_CONST;
  uint16 internal constant BF_SPM_F_MASK = BF_SPM_MASK << FINISHED_OFFSET;

  // uint16 internal constant BF_SPM_F_GLOBAL = BF_SPM_GLOBAL << FINISHED_OFFSET;
  // uint16 internal constant BF_SPM_F_CONSTANT = BF_SPM_CONSTANT << FINISHED_OFFSET;

  uint16 internal constant BF_SUSPENDED = 1 << 15; // token is suspended

  struct CalcParams {
    uint256 sA; // amount of an asset at starvation
    uint256 vA; // target price, wad-multiplier, uint192
    uint256 w; // [0..1] wad, controls fees, uint64
    uint256 extraTotal;
  }

  struct ReplenishParams {
    address actuary;
    address source;
    address token;
    function(
      ReplenishParams memory,
      uint256 /* requestedValue */
    )
      returns (
        uint256, /* replenishedAmount */
        uint256, /* replenishedValue */
        uint256 /*  expectedValue */
      ) replenishFn;
  }

  function swapExternalAsset(
    AssetBalancer storage p,
    address token,
    uint256 value,
    uint256 minAmount,
    uint256 assetAmount
  ) internal view returns (uint256 amount, uint256 fee) {
    return swapExternalAssetInBatch(p, token, value, minAmount, assetAmount, p.totalBalance);
  }

  function swapExternalAssetInBatch(
    AssetBalancer storage p,
    address token,
    uint256 value,
    uint256 minAmount,
    uint256 assetAmount,
    Balances.RateAcc memory total
  ) internal view returns (uint256 amount, uint256 fee) {
    AssetBalance memory balance;
    total.sync(uint32(block.timestamp));
    (CalcParams memory c, ) = _calcParams(p, token, balance.rateValue, true);

    // NB!!!!! value and amount are the same for this case
    c.vA = WadRayMath.WAD;

    require((total.accum += uint128(assetAmount)) >= assetAmount);
    balance.accumAmount = uint128(assetAmount);

    (amount, fee) = _swapAsset(value, minAmount, c, balance, total);
  }

  function swapAsset(
    AssetBalancer storage p,
    ReplenishParams memory params,
    uint256 value,
    uint256 minAmount,
    uint256 extraTotalValue
  ) internal returns (uint256 amount, uint256 fee) {
    Balances.RateAcc memory total = p.totalBalance;
    bool updateTotal;
    (amount, fee, updateTotal) = swapAssetInBatch(p, params, value, minAmount, extraTotalValue, total);

    if (updateTotal) {
      p.totalBalance = total;
    }
  }

  function assetState(AssetBalancer storage p, address token)
    internal
    view
    returns (
      uint256,
      uint256 accum,
      uint256 stravation,
      uint256 price,
      uint256 w
    )
  {
    AssetBalance memory balance = p.balances[token];
    (CalcParams memory c, uint256 flags) = _calcParams(p, token, balance.rateValue, false);
    return (flags, balance.accumAmount, c.sA, c.vA, c.w);
  }

  function swapAssetInBatch(
    AssetBalancer storage p,
    ReplenishParams memory params,
    uint256 value,
    uint256 minAmount,
    uint256 extraTotal,
    Balances.RateAcc memory total
  )
    internal
    returns (
      uint256 amount,
      uint256 fee,
      bool updateTotal
    )
  {
    AssetBalance memory balance = p.balances[params.token];
    total.sync(uint32(block.timestamp));

    (CalcParams memory c, uint256 flags) = _calcParams(p, params.token, balance.rateValue, true);

    if (flags & BF_AUTO_REPLENISH != 0 || (balance.rateValue > 0 && balance.accumAmount <= c.sA)) {
      // c.extraTotal = 0; - it is and it should be zero here
      _replenishAsset(p, params, c, balance, total);
      updateTotal = true;
    }

    c.extraTotal = extraTotal;
    (amount, fee) = _swapAsset(value, minAmount, c, balance, total);
    if (amount > 0) {
      p.balances[params.token] = balance;
      updateTotal = true;
    }
  }

  function _calcParams(
    AssetBalancer storage p,
    address token,
    uint256 rateValue,
    bool checkSuspended
  ) private view returns (CalcParams memory c, uint256 flags) {
    AssetConfig storage config = p.configs[token];

    c.w = config.w;
    c.vA = config.price;

    {
      flags = config.flags;
      if (flags & BF_SUSPENDED != 0 && checkSuspended) {
        revert Errors.OperationPaused();
      }
      if (flags & BF_FINISHED != 0) {
        flags <<= FINISHED_OFFSET;
      }

      // if (flags & BF_SPM_CONSTANT == 0) {
      //   c.sA = rateValue == 0 ? 0 : (rateValue * (flags & BF_SPM_GLOBAL == 0 ? config.n : p.spFactor)).wadDiv(c.vA);
      // } else {
      //   c.sA = flags & BF_SPM_GLOBAL == 0 ? config.spConst : p.spConst;
      // }

      if (flags & BF_SPM_CONSTANT != 0) {
        c.sA = flags & BF_SPM_GLOBAL == 0 ? config.spConst : p.spConst;
      }

      uint256 mode = flags & (BF_SPM_CONSTANT | BF_SPM_MAX_WITH_CONST);
      if (mode != BF_SPM_CONSTANT) {
        uint256 v;
        if (rateValue != 0) {
          v = (flags & BF_SPM_GLOBAL == 0) == (mode != BF_SPM_MAX_WITH_CONST) ? config.n : p.spFactor;
          v = (rateValue * v).wadDiv(c.vA);
        }
        if (flags & BF_SPM_MAX_WITH_CONST == 0 || v > c.sA) {
          c.sA = v;
        }
      }
    }
  }

  function _swapAsset(
    uint256 value,
    uint256 minAmount,
    CalcParams memory c,
    AssetBalance memory balance,
    Balances.RateAcc memory total
  ) private pure returns (uint256 amount, uint256 fee) {
    if (balance.accumAmount == 0) {
      return (0, 0);
    }

    uint256 k = _calcScale(c, balance, total);
    amount = _calcAmount(c, balance.accumAmount, value.rayMul(k));

    if (amount == 0 && c.sA != 0 && balance.accumAmount > 0) {
      amount = 1;
    }
    amount = balance.accumAmount - amount;

    if (amount >= minAmount && amount > 0) {
      balance.accumAmount = uint128(balance.accumAmount - amount);
      uint256 v = amount.wadMul(c.vA);
      total.accum = uint128(total.accum - v);

      if (v < value) {
        // This is a total amount of fees - it has 2 parts: balancing levy and volume penalty.
        fee = value - v;
        // The balancing levy can be positive (for popular assets) or negative (for non-popular assets) and is distributed within the balancer.
        // The volume penalty is charged on large transactions and can be taken out.

        // This formula is an aproximation that overestimates the levy and underpays the penalty. It is an acceptable behavior.
        // More accurate formula needs log() which may be an overkill for this case.
        k = (k + _calcScale(c, balance, total)) >> 1;
        // The negative levy is ignored here as it was applied with rayMul(k) above.
        k = k < WadRayMath.RAY ? value - value.rayMul(WadRayMath.RAY - k) : 0;

        // The constant-product formula (1/x) should produce enough fees than required by balancing levy ... but there can be gaps.
        fee = fee > k ? fee - k : 0;
      }
    } else {
      amount = 0;
    }
  }

  function _calcScale(
    CalcParams memory c,
    AssetBalance memory balance,
    Balances.RateAcc memory total
  ) private pure returns (uint256) {
    return
      balance.rateValue == 0 || (total.accum == 0 && c.extraTotal == 0)
        ? WadRayMath.RAY
        : ((uint256(balance.accumAmount) *
          c.vA +
          (balance.applyFrom > 0 ? WadRayMath.WAD * uint256(total.updatedAt - balance.applyFrom) * balance.rateValue : 0)).wadToRay().divUp(
            total.accum + c.extraTotal
          ) * total.rate).divUp(balance.rateValue);
  }

  function _calcAmount(
    CalcParams memory c,
    uint256 a,
    uint256 dV
  ) private pure returns (uint256 a1) {
    if (a > c.sA) {
      if (c.w == 0) {
        // no fee based on amount
        a1 = _calcFlat(c, a, dV);
      } else if (c.w == WadRayMath.WAD) {
        a1 = _calcCurve(c, a, dV);
      } else {
        a1 = _calcCurveW(c, a, dV);
      }
    } else {
      a1 = _calcStarvation(c, a, dV);
    }
  }

  function _calcCurve(
    CalcParams memory c,
    uint256 a,
    uint256 dV
  ) private pure returns (uint256) {
    return _calc(a, dV, a, a.wadMul(c.vA));
  }

  function _calcCurveW(
    CalcParams memory c,
    uint256 a,
    uint256 dV
  ) private pure returns (uint256 a1) {
    uint256 wA = a.wadDiv(c.w);
    uint256 wV = wA.wadMul(c.vA);

    a1 = _calc(wA, dV, wA, wV);

    uint256 wsA = wA - (a - c.sA);
    if (a1 < wsA) {
      uint256 wsV = (wA * wV) / wsA;
      return _calc(c.sA, dV - (wsV - wV), c.sA, wsV);
    }

    return a - (wA - a1);
  }

  function _calcFlat(
    CalcParams memory c,
    uint256 a,
    uint256 dV
  ) private pure returns (uint256 a1) {
    uint256 dA = dV.wadDiv(c.vA);
    if (c.sA + dA <= a) {
      a1 = a - dA;
    } else {
      dV -= (a - c.sA).wadMul(c.vA);
      a1 = _calcStarvation(c, c.sA, dV);
    }
  }

  function _calcStarvation(
    CalcParams memory c,
    uint256 a,
    uint256 dV
  ) private pure returns (uint256 a1) {
    a1 = _calc(a, dV, c.sA, c.sA.wadMul(c.vA));
  }

  function _calc(
    uint256 a,
    uint256 dV,
    uint256 cA,
    uint256 cV
  ) private pure returns (uint256) {
    if (cV > cA) {
      (cA, cV) = (cV, cA);
    }
    cV = cV * WadRayMath.RAY;

    return Math.mulDiv(cV, cA, dV * WadRayMath.RAY + Math.mulDiv(cV, cA, a));
  }

  function replenishAsset(
    AssetBalancer storage p,
    ReplenishParams memory params,
    uint256 incrementValue,
    uint96 newRate,
    uint96 lastRate,
    bool checkSuspended
  ) internal returns (bool fully) {
    Balances.RateAcc memory total = _syncTotalBalance(p);
    AssetBalance memory balance = p.balances[params.token];
    (CalcParams memory c, ) = _calcParams(p, params.token, balance.rateValue, checkSuspended);
    c.extraTotal = incrementValue;

    if (_replenishAsset(p, params, c, balance, total) < incrementValue) {
      newRate = 0;
    } else {
      fully = true;
    }

    if (lastRate != newRate) {
      _changeRate(lastRate, newRate, balance, total);
    }

    _save(p, params, balance, total);
  }

  function _syncTotalBalance(AssetBalancer storage p) private view returns (Balances.RateAcc memory) {
    return p.totalBalance.sync(uint32(block.timestamp));
  }

  function _save(
    AssetBalancer storage p,
    address token,
    AssetBalance memory balance,
    Balances.RateAcc memory total
  ) private {
    p.balances[token] = balance;
    p.totalBalance = total;
  }

  function _save(
    AssetBalancer storage p,
    ReplenishParams memory params,
    AssetBalance memory balance,
    Balances.RateAcc memory total
  ) private {
    _save(p, params.token, balance, total);
  }

  function _changeRate(
    uint96 lastRate,
    uint96 newRate,
    AssetBalance memory balance,
    Balances.RateAcc memory total
  ) private pure {
    if (newRate > lastRate) {
      unchecked {
        newRate = newRate - lastRate;
      }
      require((balance.rateValue += newRate) >= newRate);
      total.rate += newRate;
    } else {
      unchecked {
        newRate = lastRate - newRate;
      }
      balance.rateValue -= newRate;
      total.rate -= newRate;
    }

    balance.applyFrom = _applyRateFrom(lastRate, newRate, balance.applyFrom, total.updatedAt);
  }

  function _replenishAsset(
    AssetBalancer storage p,
    ReplenishParams memory params,
    CalcParams memory c,
    AssetBalance memory assetBalance,
    Balances.RateAcc memory total
  ) private returns (uint256) {
    require(total.updatedAt == block.timestamp);

    (uint256 receivedAmount, uint256 receivedValue, uint256 expectedValue) = params.replenishFn(params, c.extraTotal);
    if (receivedAmount == 0) {
      if (expectedValue == 0) {
        return 0;
      }
      receivedValue = 0;
    }

    uint256 v = receivedValue * WadRayMath.WAD + uint256(assetBalance.accumAmount) * c.vA;
    {
      total.accum = uint128(total.accum - expectedValue);
      require((total.accum += uint128(receivedValue)) >= receivedValue);
      require((assetBalance.accumAmount += uint128(receivedAmount)) >= receivedAmount);
    }

    if (assetBalance.accumAmount == 0) {
      v = expectedValue = 0;
    } else {
      v = v.divUp(assetBalance.accumAmount);
    }
    if (v != c.vA) {
      require((c.vA = p.configs[params.token].price = uint152(v)) == v);
    }

    _applyRateFromBalanceUpdate(expectedValue, assetBalance, total);

    return receivedValue;
  }

  function _applyRateFromBalanceUpdate(
    uint256 expectedValue,
    AssetBalance memory assetBalance,
    Balances.RateAcc memory total
  ) private pure {
    if (assetBalance.applyFrom == 0 || assetBalance.rateValue == 0) {
      assetBalance.applyFrom = total.updatedAt;
    } else if (expectedValue > 0) {
      uint256 d = assetBalance.applyFrom + (uint256(expectedValue) + assetBalance.rateValue - 1) / assetBalance.rateValue;
      assetBalance.applyFrom = d < total.updatedAt ? uint32(d) : total.updatedAt;
    }
  }

  function _applyRateFrom(
    uint256 oldRate,
    uint256 newRate,
    uint32 applyFrom,
    uint32 current
  ) private pure returns (uint32) {
    if (oldRate == 0 || newRate == 0 || applyFrom == 0) {
      return current;
    }
    uint256 d = (oldRate * uint256(current - applyFrom) + newRate - 1) / newRate;
    return d >= current ? 1 : uint32(current - d);
  }

  function decRate(
    AssetBalancer storage p,
    address targetToken,
    uint96 lastRate
  ) internal returns (uint96 rate) {
    AssetBalance storage balance = p.balances[targetToken];
    rate = balance.rateValue;

    if (lastRate > 0) {
      Balances.RateAcc memory total = _syncTotalBalance(p);

      total.rate -= lastRate;
      p.totalBalance = total;

      (lastRate, rate) = (rate, rate - lastRate);
      (balance.rateValue, balance.applyFrom) = (rate, _applyRateFrom(lastRate, rate, balance.applyFrom, total.updatedAt));
    }
  }
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

import './IERC20WithPermit.sol';
import './EIP712Base.sol';

abstract contract ERC20PermitBase is IERC20WithPermit, EIP712Base {
  bytes32 public constant PERMIT_TYPEHASH = keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)');

  constructor() {
    _initializeDomainSeparator();
  }

  function _initializeDomainSeparator() internal {
    super._initializeDomainSeparator(_getPermitDomainName());
  }

  /**
   * @dev implements the permit function as for https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
   * @param owner the owner of the funds
   * @param spender the spender
   * @param value the amount
   * @param deadline the deadline timestamp, type(uint256).max for no deadline
   * @param v signature param
   * @param s signature param
   * @param r signature param
   */

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external override {
    Value.require(owner != address(0));
    internalPermit(owner, spender, value, deadline, v, r, s, PERMIT_TYPEHASH);
    _approveByPermit(owner, spender, value);
  }

  function _approveByPermit(
    address owner,
    address spender,
    uint256 value
  ) internal virtual;

  function _getPermitDomainName() internal view virtual returns (bytes memory);
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../tools/tokens/IERC20.sol';

interface IERC20WithPermit is IERC20 {
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../EIP712Lib.sol';

abstract contract EIP712Base {
  // solhint-disable-next-line var-name-mixedcase
  bytes32 public DOMAIN_SEPARATOR;

  mapping(address => uint256) private _nonces;

  /// @dev returns nonce, to comply with eip-2612
  function nonces(address addr) external view returns (uint256) {
    return _nonces[addr];
  }

  // solhint-disable-next-line func-name-mixedcase
  function EIP712_REVISION() external pure returns (bytes memory) {
    return EIP712Lib.EIP712_REVISION;
  }

  function _initializeDomainSeparator(bytes memory permitDomainName) internal {
    DOMAIN_SEPARATOR = EIP712Lib.domainSeparator(permitDomainName);
  }

  /**
   * @param owner the owner of the funds
   * @param spender the spender
   * @param value the amount
   * @param deadline the deadline timestamp, type(uint256).max for no deadline
   * @param v signature param
   * @param s signature param
   * @param r signature param
   */

  function internalPermit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s,
    bytes32 typeHash
  ) internal {
    uint256 currentValidNonce = _nonces[owner]++;
    EIP712Lib.verifyPermit(owner, spender, bytes32(value), deadline, v, r, s, typeHash, DOMAIN_SEPARATOR, currentValidNonce);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './Errors.sol';

library EIP712Lib {
  bytes internal constant EIP712_REVISION = '1';
  bytes32 internal constant EIP712_DOMAIN = keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)');

  function chainId() internal view returns (uint256 id) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      id := chainid()
    }
  }

  function domainSeparator(bytes memory permitDomainName) internal view returns (bytes32) {
    return keccak256(abi.encode(EIP712_DOMAIN, keccak256(permitDomainName), keccak256(EIP712_REVISION), chainId(), address(this)));
  }

  /**
   * @param owner the owner of the funds
   * @param spender the spender
   * @param value the amount
   * @param deadline the deadline timestamp, type(uint256).max for no deadline
   * @param v signature param
   * @param s signature param
   * @param r signature param
   */
  function verifyPermit(
    address owner,
    address spender,
    bytes32 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s,
    bytes32 typeHash,
    bytes32 domainSep,
    uint256 nonce
  ) internal view {
    verifyCustomPermit(owner, abi.encode(typeHash, owner, spender, value, nonce, deadline), deadline, v, r, s, domainSep);
  }

  function verifyCustomPermit(
    address owner,
    bytes memory params,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s,
    bytes32 domainSep
  ) internal view {
    Value.require(owner != address(0));
    if (block.timestamp > deadline) {
      revert Errors.ExpiredPermit();
    }

    bytes32 digest = keccak256(abi.encodePacked('\x19\x01', domainSep, keccak256(params)));

    if (owner != ecrecover(digest, v, r, s)) {
      revert Errors.WrongPermitSignature();
    }
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

interface ICollateralized {
  /// @dev address of the collateral fund and coverage token ($CC)
  function collateral() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

library Math {
  function boundedSub(uint256 x, uint256 y) internal pure returns (uint256) {
    unchecked {
      return x < y ? 0 : x - y;
    }
  }

  function boundedSub2(uint256 x, uint256 y) internal pure returns (uint256, uint256) {
    unchecked {
      return x < y ? (uint256(0), y - x) : (x - y, 0);
    }
  }

  function addAbsDelta(
    uint256 x,
    uint256 y,
    uint256 z
  ) internal pure returns (uint256) {
    return y > z ? x + y - z : x + z - y;
  }

  function asUint224(uint256 x) internal pure returns (uint224) {
    require(x <= type(uint224).max);
    return uint224(x);
  }

  function asUint216(uint256 x) internal pure returns (uint216) {
    require(x <= type(uint216).max);
    return uint216(x);
  }

  function asUint128(uint256 x) internal pure returns (uint128) {
    require(x <= type(uint128).max);
    return uint128(x);
  }

  function asUint112(uint256 x) internal pure returns (uint112) {
    require(x <= type(uint112).max);
    return uint112(x);
  }

  function asUint96(uint256 x) internal pure returns (uint96) {
    require(x <= type(uint96).max);
    return uint96(x);
  }

  function asInt128(uint256 v) internal pure returns (int128) {
    require(v <= type(uint128).max);
    return int128(uint128(v));
  }

  function sqrt(uint256 y) internal pure returns (uint256 z) {
    if (y > 3) {
      z = y;
      uint256 x = (y >> 1) + 1;
      while (x < z) {
        z = x;
        x = (y / x + x) >> 1;
      }
    } else if (y != 0) {
      z = 1;
    }
  }

  // @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
  /// @param a The multiplicand
  /// @param b The multiplier
  /// @param denominator The divisor
  /// @return result The 256-bit result
  /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
  function mulDiv(
    uint256 a,
    uint256 b,
    uint256 denominator
  ) internal pure returns (uint256 result) {
    // 512-bit multiply [prod1 prod0] = a * b
    // Compute the product mod 2**256 and mod 2**256 - 1
    // then use the Chinese Remainder Theorem to reconstruct
    // the 512 bit result. The result is stored in two 256
    // variables such that product = prod1 * 2**256 + prod0
    uint256 prod0; // Least significant 256 bits of the product
    uint256 prod1; // Most significant 256 bits of the product

    // solhint-disable no-inline-assembly
    assembly {
      let mm := mulmod(a, b, not(0))
      prod0 := mul(a, b)
      prod1 := sub(sub(mm, prod0), lt(mm, prod0))
    }

    // Handle non-overflow cases, 256 by 256 division
    if (prod1 == 0) {
      require(denominator > 0);
      assembly {
        result := div(prod0, denominator)
      }
      return result;
    }

    // Make sure the result is less than 2**256.
    // Also prevents denominator == 0
    require(denominator > prod1);

    ///////////////////////////////////////////////
    // 512 by 256 division.
    ///////////////////////////////////////////////

    // Make division exact by subtracting the remainder from [prod1 prod0]
    // Compute remainder using mulmod
    uint256 remainder;
    assembly {
      remainder := mulmod(a, b, denominator)
    }
    // Subtract 256 bit number from 512 bit number
    assembly {
      prod1 := sub(prod1, gt(remainder, prod0))
      prod0 := sub(prod0, remainder)
    }

    // Factor powers of two out of denominator
    // Compute largest power of two divisor of denominator.
    // Always >= 1.
    unchecked {
      uint256 twos = (type(uint256).max - denominator + 1) & denominator;
      // Divide denominator by power of two
      assembly {
        denominator := div(denominator, twos)
      }

      // Divide [prod1 prod0] by the factors of two
      assembly {
        prod0 := div(prod0, twos)
      }
      // Shift in bits from prod1 into prod0. For this we need
      // to flip `twos` such that it is 2**256 / twos.
      // If twos is zero, then it becomes one
      assembly {
        twos := add(div(sub(0, twos), twos), 1)
      }
      prod0 |= prod1 * twos;

      // Invert denominator mod 2**256
      // Now that denominator is an odd number, it has an inverse
      // modulo 2**256 such that denominator * inv = 1 mod 2**256.
      // Compute the inverse by starting with a seed that is correct
      // correct for four bits. That is, denominator * inv = 1 mod 2**4
      uint256 inv = (3 * denominator) ^ 2;
      // Now use Newton-Raphson iteration to improve the precision.
      // Thanks to Hensel's lifting lemma, this also works in modular
      // arithmetic, doubling the correct bits in each step.
      inv *= 2 - denominator * inv; // inverse mod 2**8
      inv *= 2 - denominator * inv; // inverse mod 2**16
      inv *= 2 - denominator * inv; // inverse mod 2**32
      inv *= 2 - denominator * inv; // inverse mod 2**64
      inv *= 2 - denominator * inv; // inverse mod 2**128
      inv *= 2 - denominator * inv; // inverse mod 2**256

      // Because the division is now exact we can divide by multiplying
      // with the modular inverse of denominator. This will give us the
      // correct result modulo 2**256. Since the precoditions guarantee
      // that the outcome is less than 2**256, this is the final result.
      // We don't need to compute the high bits of the result and prod1
      // is no longer required.
      result = prod0 * inv;
      return result;
    }
    // solhint-enable no-inline-assembly
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/upgradeability/VersionedInitializable.sol';
import '../interfaces/IPremiumFundInit.sol';
import './PremiumFundBase.sol';

contract PremiumFundV1 is VersionedInitializable, IPremiumFundInit, PremiumFundBase {
  uint256 private constant CONTRACT_REVISION = 1;

  constructor(IAccessController acl, address collateral_) PremiumFundBase(acl, collateral_) {}

  function initializePremiumFund() public override initializer(CONTRACT_REVISION) {}

  function getRevision() internal pure override returns (uint256) {
    return CONTRACT_REVISION;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './IVersioned.sol';

/**
 * @title VersionedInitializable
 *
 * @dev Helper contract to implement versioned initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` or `initializerRunAlways` modifier.
 * The revision number should be defined as a private constant, returned by getRevision() and used by initializer() modifier.
 *
 * ATTN: There is a built-in protection from implementation self-destruct exploits. This protection
 * prevents initializers from being called on an implementation inself, but only on proxied contracts.
 * To override this protection, call _unsafeResetVersionedInitializers() from a constructor.
 *
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an initializable contract, as well
 * as extending an initializable contract via inheritance.
 *
 * ATTN: When used with inheritance, parent initializers with `initializer` modifier are prevented by calling twice,
 * but can only be called in child-to-parent sequence.
 *
 * WARNING: When used with inheritance, parent initializers with `initializerRunAlways` modifier
 * are NOT protected from multiple calls by another initializer.
 */
abstract contract VersionedInitializable is IVersioned {
  uint256 private constant BLOCK_REVISION = type(uint256).max;
  // This revision number is applied to implementations
  uint256 private constant IMPL_REVISION = BLOCK_REVISION - 1;

  /// @dev Indicates that the contract has been initialized. The default value blocks initializers from being called on an implementation.
  uint256 private lastInitializedRevision = IMPL_REVISION;

  /// @dev Indicates that the contract is in the process of being initialized.
  uint256 private lastInitializingRevision = 0;

  error OnlyInsideConstructor();
  error OnlyBeforeInitializer();

  /**
   * @dev There is a built-in protection from self-destruct of implementation exploits. This protection
   * prevents initializers from being called on an implementation inself, but only on proxied contracts.
   * Function _unsafeResetVersionedInitializers() can be called from a constructor to disable this protection.
   * It must be called before any initializers, otherwise it will fail.
   */
  function _unsafeResetVersionedInitializers() internal {
    if (!isConstructor()) {
      revert OnlyInsideConstructor();
    }

    if (lastInitializedRevision == IMPL_REVISION) {
      lastInitializedRevision = 0;
    } else if (lastInitializedRevision != 0) {
      revert OnlyBeforeInitializer();
    }
  }

  /// @dev Modifier to use in the initializer function of a contract.
  // slither-disable-next-line incorrect-modifier
  modifier initializer(uint256 localRevision) {
    (uint256 topRevision, bool initializing, bool skip) = _preInitializer(localRevision);

    if (!skip) {
      lastInitializingRevision = localRevision;
      _;
      lastInitializedRevision = localRevision;
    }

    if (!initializing) {
      lastInitializedRevision = topRevision;
      lastInitializingRevision = 0;
    }
  }

  modifier initializerRunAlways(uint256 localRevision) {
    (uint256 topRevision, bool initializing, bool skip) = _preInitializer(localRevision);

    if (!skip) {
      lastInitializingRevision = localRevision;
    }
    _;
    if (!skip) {
      lastInitializedRevision = localRevision;
    }

    if (!initializing) {
      lastInitializedRevision = topRevision;
      lastInitializingRevision = 0;
    }
  }

  error WrongContractRevision();
  error WrongInitializerRevision();
  error InconsistentContractRevision();
  error AlreadyInitialized();
  error InitializerBlockedOff();
  error WrongOrderOfInitializers();

  function _preInitializer(uint256 localRevision)
    private
    returns (
      uint256 topRevision,
      bool initializing,
      bool skip
    )
  {
    topRevision = getRevision();
    if (topRevision >= IMPL_REVISION) {
      revert WrongContractRevision();
    }

    if (localRevision > topRevision) {
      revert InconsistentContractRevision();
    } else if (localRevision == 0) {
      revert WrongInitializerRevision();
    }

    if (lastInitializedRevision < IMPL_REVISION) {
      // normal initialization
      initializing = lastInitializingRevision > 0 && lastInitializedRevision < topRevision;
      if (!(initializing || isConstructor() || topRevision > lastInitializedRevision)) {
        revert AlreadyInitialized();
      }
    } else {
      // by default, initialization of implementation is only allowed inside a constructor
      if (!(lastInitializedRevision == IMPL_REVISION && isConstructor())) {
        revert InitializerBlockedOff();
      }

      // enable normal use of initializers inside a constructor
      lastInitializedRevision = 0;
      // but make sure to block initializers afterwards
      topRevision = BLOCK_REVISION;

      initializing = lastInitializingRevision > 0;
    }

    if (initializing && lastInitializingRevision <= localRevision) {
      revert WrongOrderOfInitializers();
    }

    if (localRevision <= lastInitializedRevision) {
      // prevent calling of parent's initializer when it was called before
      if (initializing) {
        // Can't set zero yet, as it is not a top-level call, otherwise `initializing` will become false.
        // Further calls will fail with the `incorrect order` assertion above.
        lastInitializingRevision = 1;
      }
      skip = true;
    }
  }

  function isRevisionInitialized(uint256 localRevision) internal view returns (bool) {
    return lastInitializedRevision >= localRevision;
  }

  // solhint-disable-next-line func-name-mixedcase
  function REVISION() public pure override returns (uint256) {
    return getRevision();
  }

  /**
   * @dev returns the revision number (< type(uint256).max - 1) of the contract.
   * The number should be defined as a private constant.
   **/
  function getRevision() internal pure virtual returns (uint256);

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    uint256 cs;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      cs := extcodesize(address())
    }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  // slither-disable-next-line unused-state
  uint256[16] private ______gap;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IPremiumFundInit {
  function initializePremiumFund() external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IVersioned {
  // solhint-disable-next-line func-name-mixedcase
  function REVISION() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../access/interfaces/IAccessController.sol';
import '../interfaces/IInsuredPoolInit.sol';
import '../interfaces/IWeightedPool.sol';
import '../interfaces/IPremiumFundInit.sol';
import '../interfaces/ICollateralFundInit.sol';
import '../interfaces/IYieldDistributorInit.sol';
import '../insurer/WeightedPoolConfig.sol';

library ProxyTypes {
  bytes32 internal constant APPROVAL_CATALOG = 'APPROVAL_CATALOG';
  bytes32 internal constant ORACLE_ROUTER = 'ORACLE_ROUTER';

  bytes32 internal constant INSURED_POOL = 'INSURED_POOL';

  function insuredInit(address governor) internal pure returns (bytes memory) {
    return abi.encodeWithSelector(IInsuredPoolInit.initializeInsured.selector, governor);
  }

  bytes32 internal constant PERPETUAL_INDEX_POOL = 'PERPETUAL_INDEX_POOL';
  bytes32 internal constant IMPERPETUAL_INDEX_POOL = 'IMPERPETUAL_INDEX_POOL';

  function weightedPoolInit(
    address governor,
    string calldata tokenName,
    string calldata tokenSymbol,
    WeightedPoolParams calldata params
  ) internal pure returns (bytes memory) {
    return abi.encodeWithSelector(IWeightedPoolInit.initializeWeighted.selector, governor, tokenName, tokenSymbol, params);
  }

  bytes32 internal constant PREMIUM_FUND = 'PREMIUM_FUND';

  function premiumFundInit() internal pure returns (bytes memory) {
    return abi.encodeWithSelector(IPremiumFundInit.initializePremiumFund.selector);
  }

  bytes32 internal constant COLLATERAL_FUND = 'COLLATERAL_FUND';

  function collateralFundInit() internal pure returns (bytes memory) {
    return abi.encodeWithSelector(ICollateralFundInit.initializeCollateralFund.selector);
  }

  bytes32 internal constant YIELD_DISTRIBUTOR = 'YIELD_DISTRIBUTOR';

  function yieldDistributorInit() internal pure returns (bytes memory) {
    return abi.encodeWithSelector(IYieldDistributorInit.initializeYieldDistributor.selector);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IInsuredPoolInit {
  function initializeInsured(address governor) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IWeightedPoolInit {
  function initializeWeighted(
    address governor,
    string calldata tokenName,
    string calldata tokenSymbol,
    WeightedPoolParams calldata params
  ) external;
}

struct WeightedPoolParams {
  /// @dev a recommended maximum of uncovered units per pool
  uint32 maxAdvanceUnits;
  /// @dev a recommended minimum of units per batch
  uint32 minAdvanceUnits;
  /// @dev a target risk level, an insured with higher risk will get a lower share per batch (and vice versa)
  uint16 riskWeightTarget;
  /// @dev a minimum share per batch per insured, lower values will be replaced by this one
  uint16 minInsuredSharePct;
  /// @dev a maximum share per batch per insured, higher values will be replaced by this one
  uint16 maxInsuredSharePct;
  /// @dev an amount of units per round in a batch to consider the batch as ready to be covered
  uint16 minUnitsPerRound;
  /// @dev an amount of units per round in a batch to consider a batch as full (no more units can be added)
  uint16 maxUnitsPerRound;
  /// @dev an "overcharge" / a maximum allowed amount of units per round in a batch that can be applied to reduce batch fragmentation
  uint16 overUnitsPerRound;
  /// @dev an amount of coverage to be given out on reconciliation, where 100% disables drawdown permanently. A new value must be >= the prev one.
  uint16 coveragePrepayPct;
  /// @dev an amount of coverage usable as collateral drawdown, where 0% stops drawdown. MUST: maxUserDrawdownPct + coveragePrepayPct <= 100%
  uint16 maxUserDrawdownPct;
  /// @dev limits a number of auto-pull loops by amount of added coverage divided by this number, zero disables auto-pull
  uint16 unitsPerAutoPull;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface ICollateralFundInit {
  function initializeCollateralFund() external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IYieldDistributorInit {
  function initializeYieldDistributor() external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/introspection/ERC165Checker.sol';
import '../interfaces/IWeightedPool.sol';
import '../interfaces/IPremiumSource.sol';
import '../tools/math/PercentageMath.sol';
import './WeightedRoundsBase.sol';
import './WeightedPoolAccessControl.sol';

abstract contract WeightedPoolConfig is WeightedRoundsBase, WeightedPoolAccessControl {
  using PercentageMath for uint256;
  using WadRayMath for uint256;
  using Rounds for Rounds.PackedInsuredParams;

  WeightedPoolParams internal _params;

  // uint256 private _loopLimits;

  constructor(
    IAccessController acl,
    uint256 unitSize,
    address collateral_
  ) WeightedRoundsBase(unitSize) GovernedHelper(acl, collateral_) {}

  // function internalSetLoopLimits(uint16[] memory limits) internal virtual {
  //   uint256 v;
  //   for (uint256 i = limits.length; i > 0; ) {
  //     i--;
  //     v = (v << 16) | uint16(limits[i]);
  //   }
  //   _loopLimits = v;
  // }

  event WeightedPoolParamsUpdated(WeightedPoolParams params);

  function internalSetPoolParams(WeightedPoolParams memory params) internal virtual {
    Value.require(
      params.minUnitsPerRound > 0 && params.maxUnitsPerRound >= params.minUnitsPerRound && params.overUnitsPerRound >= params.maxUnitsPerRound
    );

    Value.require(params.maxAdvanceUnits >= params.minAdvanceUnits && params.minAdvanceUnits >= params.maxUnitsPerRound);

    Value.require(
      params.minInsuredSharePct > 0 && params.maxInsuredSharePct > params.minInsuredSharePct && params.maxInsuredSharePct <= PercentageMath.ONE
    );

    Value.require(params.riskWeightTarget > 0 && params.riskWeightTarget < PercentageMath.ONE);

    Value.require(
      params.coveragePrepayPct >= _params.coveragePrepayPct &&
        params.coveragePrepayPct >= PercentageMath.HALF_ONE &&
        params.maxUserDrawdownPct <= PercentageMath.ONE - params.coveragePrepayPct
    );

    _params = params;
    emit WeightedPoolParamsUpdated(params);
  }

  ///@return The number of rounds to initialize a new batch
  function internalBatchAppend(
    uint80,
    uint32 openRounds,
    uint64 unitCount
  ) internal view override returns (uint24) {
    uint256 max = _params.maxUnitsPerRound;
    uint256 min = _params.minAdvanceUnits / max;
    max = _params.maxAdvanceUnits / max;

    if (min > type(uint24).max) {
      if (openRounds + min > max) {
        return 0;
      }
      min = type(uint24).max;
    }

    if (openRounds + min > max) {
      if (min < (max >> 1) || openRounds > (max >> 1)) {
        return 0;
      }
    }

    if (unitCount > type(uint24).max) {
      unitCount = type(uint24).max;
    }

    if ((unitCount /= uint64(min)) <= 1) {
      return uint24(min);
    }

    if ((max = (max - openRounds) / min) < unitCount) {
      min *= max;
    } else {
      min *= unitCount;
    }
    Sanity.require(min > 0);

    return uint24(min);
  }

  function internalGetPassiveCoverageUnits() internal view returns (uint256) {}

  /// @dev Calculate the limits of the number of units that can be added to a round
  function internalRoundLimits(
    uint80 totalUnitsBeforeBatch,
    uint24 batchRounds,
    uint16 unitPerRound,
    uint64 demandedUnits,
    uint16 maxShare
  )
    internal
    view
    override
    returns (
      uint16, // maxShareUnitsPerRound,
      uint16, // minUnitsPerRound,
      uint16, // readyUnitsPerRound
      uint16 // maxUnitsPerRound
    )
  {
    (uint16 minUnitsPerRound, uint16 maxUnitsPerRound) = (_params.minUnitsPerRound, _params.maxUnitsPerRound);

    // total # of units could be allocated when this round if full
    uint256 x = uint256(unitPerRound < minUnitsPerRound ? minUnitsPerRound : unitPerRound + 1) *
      batchRounds +
      totalUnitsBeforeBatch +
      internalGetPassiveCoverageUnits();

    // max of units that can be added in total for the share not to be exceeded
    x = x.percentMul(maxShare);

    if (x < demandedUnits + batchRounds) {
      x = 0;
    } else {
      unchecked {
        x = (x - demandedUnits) / batchRounds;
      }
      if (unitPerRound + x >= maxUnitsPerRound) {
        if (unitPerRound < minUnitsPerRound) {
          // this prevents lockup of a batch when demand is added by small portions
          minUnitsPerRound = unitPerRound + 1;
        }
      }

      if (x > type(uint16).max) {
        x = type(uint16).max;
      }
    }

    return (uint16(x), minUnitsPerRound, maxUnitsPerRound, _params.overUnitsPerRound);
  }

  function _requiredForMinimumCoverage(
    uint64 demandedUnits,
    uint64 minUnits,
    uint256 remainingUnits
  ) private pure returns (bool) {
    return demandedUnits < minUnits && demandedUnits + remainingUnits >= minUnits;
  }

  function internalBatchSplit(
    uint64 demandedUnits,
    uint64 minUnits,
    uint24 batchRounds,
    uint24 remainingUnits
  ) internal pure override returns (uint24 splitRounds) {
    // console.log('internalBatchSplit-0', demandedUnits, minUnits);
    // console.log('internalBatchSplit-1', batchRounds, remainingUnits);
    return _requiredForMinimumCoverage(demandedUnits, minUnits, remainingUnits) || (remainingUnits > batchRounds >> 2) ? remainingUnits : 0;
  }

  function internalIsEnoughForMore(Rounds.InsuredEntry memory entry, uint256 unitCount) internal view override returns (bool) {
    return _requiredForMinimumCoverage(entry.demandedUnits, entry.params.minUnits(), unitCount) || unitCount >= _params.minAdvanceUnits;
  }

  function defaultLoopLimit(LoopLimitType t, uint256 limit) internal view returns (uint256) {
    if (limit == 0) {
      // limit = uint16(_loopLimits >> (uint8(t) << 1));
      // if (limit == 0) {
      limit = t > LoopLimitType.ReceivableDemandedCoverage ? 31 : 255;
      // }
    }
    this;
    return limit;
  }

  function internalGetUnderwrittenParams(address insured) internal virtual returns (bool ok, IApprovalCatalog.ApprovedPolicyForInsurer memory data) {
    IApprovalCatalog ac = approvalCatalog();
    if (address(ac) != address(0)) {
      (ok, data) = ac.getAppliedApplicationForInsurer(insured);
    } else {
      IInsurerGovernor g = governorContract();
      if (address(g) != address(0)) {
        (ok, data) = g.getApprovedPolicyForInsurer(insured);
      }
    }
  }

  /// @dev Prepare for an insured pool to join by setting the parameters
  function internalPrepareJoin(address insured) internal override returns (bool) {
    (bool ok, IApprovalCatalog.ApprovedPolicyForInsurer memory approvedParams) = internalGetUnderwrittenParams(insured);
    if (!ok) {
      return false;
    }

    uint256 maxShare = approvedParams.riskLevel == 0 ? PercentageMath.ONE : uint256(_params.riskWeightTarget).percentDiv(approvedParams.riskLevel);
    uint256 v;
    if (maxShare >= (v = _params.maxInsuredSharePct)) {
      maxShare = v;
    } else if (maxShare < (v = _params.minInsuredSharePct)) {
      maxShare = v;
    }

    if (maxShare == 0) {
      return false;
    }

    State.require(IPremiumSource(insured).premiumToken() == approvedParams.premiumToken);

    InsuredParams memory insuredSelfParams = IInsuredPool(insured).insuredParams();

    uint256 unitSize = internalUnitSize();
    uint256 minUnits = (insuredSelfParams.minPerInsurer + unitSize - 1) / unitSize;
    State.require(minUnits <= type(uint24).max);

    uint256 baseRate = (approvedParams.basePremiumRate + unitSize - 1) / unitSize;
    State.require(baseRate <= type(uint40).max);

    super.internalSetInsuredParams(
      insured,
      Rounds.InsuredParams({minUnits: uint24(minUnits), maxShare: uint16(maxShare), minPremiumRate: uint40(baseRate)})
    );

    return true;
  }

  function internalGetStatus(address account) internal view override returns (MemberStatus) {
    return internalGetInsuredStatus(account);
  }

  function internalSetStatus(address account, MemberStatus status) internal override {
    return super.internalSetInsuredStatus(account, status);
  }

  /// @return status The status of the account, NotApplicable if unknown about this address or account is an investor
  function internalStatusOf(address account) internal view returns (MemberStatus status) {
    if ((status = internalGetStatus(account)) == MemberStatus.Unknown && internalIsInvestor(account)) {
      status = MemberStatus.NotApplicable;
    }
    return status;
  }
}

enum LoopLimitType {
  // View ops (255 iterations by default)
  ReceivableDemandedCoverage,
  // Modify ops (31 iterations by default)
  AddCoverageDemand,
  AddCoverage,
  AddCoverageDemandByPull,
  CancelCoverageDemand,
  ReceiveDemandedCoverage
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '../tools/math/WadRayMath.sol';
import '../tools/math/Math.sol';
import '../interfaces/IInsurerPool.sol';
import './Rounds.sol';

import 'hardhat/console.sol';

/// @title A calculator for allocating coverage
/// @notice Coverage is demanded and provided through rounds and batches.
// solhint-disable-next-line max-states-count
abstract contract WeightedRoundsBase {
  using Rounds for Rounds.Batch;
  using Rounds for Rounds.State;
  using Rounds for Rounds.PackedInsuredParams;
  using EnumerableSet for EnumerableSet.AddressSet;
  using WadRayMath for uint256;
  using Math for uint256;

  uint256 private immutable _unitSize;

  constructor(uint256 unitSize) {
    Value.require(unitSize > 0);
    _unitSize = unitSize;
  }

  /// @dev tracking info about insured pools
  mapping(address => Rounds.InsuredEntry) private _insureds;
  /// @dev demand log of each insured pool, updated by addition of coverage demand
  mapping(address => Rounds.Demand[]) private _demands;
  /// @dev coverage summary of each insured pool, updated by retrieving collected coverage
  mapping(address => Rounds.Coverage) private _covered;
  /// @dev premium summary of each insured pool, updated by retrieving collected coverage
  mapping(address => Rounds.CoveragePremium) private _premiums;

  /// @dev one way linked list of batches, appended by adding coverage demand, trimmed by adding coverage
  mapping(uint64 => Rounds.Batch) private _batches;

  /// @dev total number of batches
  uint64 private _batchCount;
  /// @dev the most recently added batch (head of the linked list)
  uint64 private _latestBatchNo;
  /// @dev points to an earliest round that is open, can not be zero
  uint64 private _firstOpenBatchNo;
  /// @dev number of open rounds starting from the partial one to _latestBatchNo
  /// @dev it is provided to the logic distribution control logic
  uint32 private _openRounds;
  /// @dev summary of total pool premium (covers all batches before the partial)
  Rounds.CoveragePremium private _poolPremium;

  struct PartialState {
    /// @dev amount of coverage in the partial round, must be zero when roundNo == batch size
    uint128 roundCoverage;
    /// @dev points either to a partial round or to the last full round when there is no other rounds
    /// @dev can ONLY be zero when there is no rounds (zero state)
    uint64 batchNo;
    /// @dev number of a partial round / also is the number of full rounds in the batch
    /// @dev when equals to batch size - then there is no partial round
    uint24 roundNo;
  }
  /// @dev the batch being filled (partially filled)
  PartialState private _partial;

  /// @dev segment of a coverage integral (time-weighted) for a partial or full batch
  struct TimeMark {
    /// @dev value of integral of coverage for a batch
    uint192 coverageTW;
    /// @dev last updated at
    uint32 timestamp;
    /// @dev time duration of this batch (length of the integral segment)
    uint32 duration;
  }
  /// @dev segments of coverage integral NB! Each segment is independent, it does NOT include / cosider previous segments
  mapping(uint64 => TimeMark) private _marks;

  uint80 private _pendingCancelledCoverageUnits;
  uint80 private _pendingCancelledDemandUnits;

  /// @dev a batch number to look for insureds with "hasMore" in _pullableDemands
  uint64 private _pullableBatchNo;
  /// @dev sets of insureds with "hasMore"
  mapping(uint64 => EnumerableSet.AddressSet) private _pullableDemands;

  function internalSetInsuredStatus(address account, MemberStatus status) internal {
    _insureds[account].status = status;
  }

  function internalGetInsuredStatus(address account) internal view returns (MemberStatus) {
    return _insureds[account].status;
  }

  ///@dev Sets the minimum amount of units this insured pool will assign and the max share % of the pool it can take up
  function internalSetInsuredParams(address account, Rounds.InsuredParams memory params) internal {
    _insureds[account].params = Rounds.packInsuredParams(params.minUnits, params.maxShare, params.minPremiumRate);
  }

  function internalGetInsuredParams(address account) internal view returns (MemberStatus, Rounds.InsuredParams memory) {
    Rounds.InsuredEntry storage entry = _insureds[account];
    return (entry.status, entry.params.unpackInsuredParams());
  }

  function internalUnitSize() internal view returns (uint256) {
    return _unitSize;
  }

  struct AddCoverageDemandParams {
    uint256 loopLimit;
    address insured;
    uint40 premiumRate;
    bool hasMore;
    // temporary variables
    uint64 prevPullBatch;
    bool takeNext;
  }

  /// @dev Adds coverage demand by performing the following:
  /// @dev Find which batch to first append to
  /// @dev Fill the batch, and create new batches if needed, looping under either all units added to batch or loopLimit
  /// @return The remaining demanded units
  function internalAddCoverageDemand(uint64 unitCount, AddCoverageDemandParams memory params)
    internal
    returns (
      uint64 // remainingCount
    )
  {
    // console.log('\ninternalAddCoverageDemand', unitCount);
    Rounds.InsuredEntry memory entry = _insureds[params.insured];
    Access.require(entry.status == MemberStatus.Accepted);
    Value.require(entry.params.minPremiumRate() <= params.premiumRate);

    if (unitCount == 0 || params.loopLimit == 0) {
      return unitCount;
    }

    Rounds.Demand[] storage demands = _demands[params.insured];
    params.prevPullBatch = entry.nextBatchNo;

    (Rounds.Batch memory b, uint64 thisBatch, bool isFirstOfOpen) = _findBatchToAppend(entry.nextBatchNo);

    Rounds.Demand memory demand;
    uint32 openRounds = _openRounds - _partial.roundNo;
    bool updateBatch;
    for (;;) {
      // console.log('addDemandLoop', thisBatch, isFirstOfOpen, b.totalUnitsBeforeBatch);
      params.loopLimit--;

      // Sanity.require(thisBatch != 0);
      if (b.rounds == 0) {
        // NB! empty batches can also be produced by cancellation

        b.rounds = internalBatchAppend(_adjustedTotalUnits(b.totalUnitsBeforeBatch), openRounds, unitCount);
        // console.log('addDemandToEmpty', b.rounds, openRounds - _partial.roundNo);

        if (b.rounds == 0) {
          break;
        }

        openRounds += b.rounds;
        _initTimeMark(_latestBatchNo = b.nextBatchNo = ++_batchCount);
        updateBatch = true;
      }

      uint16 addPerRound;
      if (b.isOpen()) {
        (addPerRound, params.takeNext) = _addToBatch(unitCount, b, entry, params, isFirstOfOpen);
        // console.log('addToBatchResult', addPerRound, takeNext);
        if (addPerRound > 0) {
          updateBatch = true;
        } else if (b.unitPerRound == 0) {
          updateBatch = false;
          break;
        }

        if (isFirstOfOpen && b.isOpen()) {
          _firstOpenBatchNo = thisBatch;
          isFirstOfOpen = false;
        }
      }

      if (b.rounds > 0 && _addToSlot(demand, demands, addPerRound, b.rounds, params.premiumRate)) {
        demand = Rounds.Demand({startBatchNo: thisBatch, premiumRate: params.premiumRate, rounds: b.rounds, unitPerRound: addPerRound});
      }

      if (addPerRound > 0) {
        // Sanity.require(takeNext);
        uint64 addedUnits = uint64(addPerRound) * b.rounds;
        unitCount -= addedUnits;
        entry.demandedUnits += addedUnits;
      }

      if (!params.takeNext) {
        break;
      }

      _batches[thisBatch] = b;
      updateBatch = false;

      entry.nextBatchNo = thisBatch = b.nextBatchNo;
      // Sanity.require(thisBatch != 0);

      uint80 totalUnitsBeforeBatch = b.totalUnitsBeforeBatch + uint80(b.unitPerRound) * b.rounds;
      b = _batches[thisBatch];

      if (b.totalUnitsBeforeBatch != totalUnitsBeforeBatch) {
        b.totalUnitsBeforeBatch = totalUnitsBeforeBatch;
        updateBatch = true;
      }

      if (unitCount == 0 || params.loopLimit == 0) {
        break;
      }
    }

    if (updateBatch) {
      _batches[thisBatch] = b;
    }
    _openRounds = openRounds + _partial.roundNo;

    _setPullBatch(params, params.hasMore || internalIsEnoughForMore(entry, unitCount) ? thisBatch : 0);
    _insureds[params.insured] = entry;

    if (demand.unitPerRound != 0) {
      demands.push(demand);
    }

    if (isFirstOfOpen) {
      _firstOpenBatchNo = thisBatch;
    }

    return unitCount;
  }

  function internalIsEnoughForMore(Rounds.InsuredEntry memory entry, uint256 unitCount) internal view virtual returns (bool);

  function _setPullBatch(AddCoverageDemandParams memory params, uint64 newPullBatch) private {
    if (params.prevPullBatch != newPullBatch) {
      if (params.prevPullBatch != 0) {
        _removeFromPullable(params.insured, params.prevPullBatch);
      }
      if (newPullBatch != 0) {
        _addToPullable(params.insured, newPullBatch);
      }
    }
  }

  /// @dev Finds which batch to add coverage demand to.
  /// @param nextBatchNo Attempts to use if it is accepting coverage demand
  /// @return b Returns the current batch, its number and whether batches were filled
  /// @return thisBatchNo
  /// @return isFirstOfOpen
  function _findBatchToAppend(uint64 nextBatchNo)
    private
    returns (
      Rounds.Batch memory b,
      uint64 thisBatchNo,
      bool isFirstOfOpen
    )
  {
    uint64 firstOpen = _firstOpenBatchNo;
    if (firstOpen == 0) {
      // there are no batches
      Sanity.require(_batchCount == 0);
      Sanity.require(nextBatchNo == 0);
      _initTimeMark(_latestBatchNo = _batchCount = _partial.batchNo = _firstOpenBatchNo = 1);
      return (b, 1, true);
    }

    if (nextBatchNo != 0 && (b = _batches[nextBatchNo]).isOpen()) {
      thisBatchNo = nextBatchNo;
    } else {
      b = _batches[thisBatchNo = firstOpen];
    }

    if (b.nextBatchNo == 0) {
      Sanity.require(b.rounds == 0);
    } else {
      PartialState memory part = _partial;
      if (part.batchNo == thisBatchNo) {
        uint24 remainingRounds = part.roundCoverage == 0 ? part.roundNo : part.roundNo + 1;
        if (remainingRounds > 0) {
          _splitBatch(remainingRounds, b);

          if (part.roundCoverage == 0) {
            b.state = Rounds.State.Full;

            Rounds.CoveragePremium memory premium = _poolPremium;
            _addPartialToTotalPremium(thisBatchNo, premium, b);
            _poolPremium = premium;

            _partial = PartialState({roundCoverage: 0, batchNo: b.nextBatchNo, roundNo: 0});
          }
          _batches[thisBatchNo] = b;
          if (firstOpen == thisBatchNo) {
            _firstOpenBatchNo = firstOpen = b.nextBatchNo;
          }
          b = _batches[thisBatchNo = b.nextBatchNo];
        }
      }
    }

    return (b, thisBatchNo, thisBatchNo == firstOpen);
  }

  function _adjustedTotalUnits(uint80 units) private view returns (uint80 n) {
    n = _pendingCancelledCoverageUnits;
    if (n >= units) {
      return 0;
    }
    unchecked {
      return units - n;
    }
  }

  /// @dev adds the demand to the list of demands
  function _addToSlot(
    Rounds.Demand memory demand,
    Rounds.Demand[] storage demands,
    uint16 addPerRound,
    uint24 batchRounds,
    uint40 premiumRate
  ) private returns (bool) {
    if (demand.unitPerRound == addPerRound && demand.premiumRate == premiumRate) {
      uint24 t;
      unchecked {
        t = batchRounds + demand.rounds;
      }
      if (t >= batchRounds) {
        demand.rounds = t;
        return false;
      }
      // overflow on amount of rounds per slot
    }

    if (demand.unitPerRound != 0) {
      demands.push(demand);
    }
    return true;
  }

  /// @dev Adds units to the batch. Can split the batch when the number of units is less than the number of rounds inside the batch.
  /// The unitCount units are evenly distributed across rounds by increase the # of units per round
  function _addToBatch(
    uint64 unitCount,
    Rounds.Batch memory b,
    Rounds.InsuredEntry memory entry,
    AddCoverageDemandParams memory params,
    bool canClose
  ) private returns (uint16 addPerRound, bool takeNext) {
    Sanity.require(b.isOpen() && b.rounds > 0);

    if (unitCount < b.rounds) {
      // split the batch or return the non-allocated units
      uint24 splitRounds = internalBatchSplit(entry.demandedUnits, entry.params.minUnits(), b.rounds, uint24(unitCount));
      // console.log('addToBatch-internalBatchSplit', splitRounds);
      if (splitRounds == 0) {
        return (0, false);
      }
      Sanity.require(unitCount >= splitRounds);
      // console.log('batchSplit-before', splitRounds, b.rounds, b.nextBatchNo);
      _splitBatch(splitRounds, b);
      // console.log('batchSplit-after', b.rounds, b.nextBatchNo);
    }

    (uint16 maxShareUnitsPerRound, uint16 minUnitsPerRound, uint16 readyUnitsPerRound, uint16 maxUnitsPerRound) = internalRoundLimits(
      _adjustedTotalUnits(b.totalUnitsBeforeBatch),
      b.rounds,
      b.unitPerRound,
      entry.demandedUnits,
      entry.params.maxShare()
    );

    // console.log('addToBatch-checkLimits', b.unitPerRound, b.rounds);
    // console.log('addToBatch-limits', maxShareUnitsPerRound, minUnitsPerRound, maxUnitsPerRound);

    if (maxShareUnitsPerRound > 0) {
      takeNext = true;
      if (b.unitPerRound < maxUnitsPerRound) {
        addPerRound = maxUnitsPerRound - b.unitPerRound;
        if (addPerRound > maxShareUnitsPerRound) {
          addPerRound = maxShareUnitsPerRound;
        }
        uint64 n = unitCount / b.rounds;
        if (addPerRound > n) {
          addPerRound = uint16(n);
        }
        Sanity.require(addPerRound > 0);

        b.unitPerRound += addPerRound;
        b.roundPremiumRateSum += uint56(params.premiumRate) * addPerRound;
      }
    }

    if (b.unitPerRound >= minUnitsPerRound) {
      b.state = canClose && b.unitPerRound >= readyUnitsPerRound ? Rounds.State.Ready : Rounds.State.ReadyMin;
    }
  }

  function internalRoundLimits(
    uint80 totalUnitsBeforeBatch,
    uint24 batchRounds,
    uint16 unitPerRound,
    uint64 demandedUnits,
    uint16 maxShare
  )
    internal
    virtual
    returns (
      uint16 maxAddUnitsPerRound,
      uint16 minUnitsPerRound,
      uint16 readyUnitsPerRound,
      uint16 maxUnitsPerRound
    );

  function internalBatchSplit(
    uint64 demandedUnits,
    uint64 minUnits,
    uint24 batchRounds,
    uint24 remainingUnits
  ) internal virtual returns (uint24 splitRounds);

  function internalBatchAppend(
    uint80 totalUnitsBeforeBatch,
    uint32 openRounds,
    uint64 unitCount
  ) internal virtual returns (uint24 rounds);

  /// @dev Reduces the current batch's rounds and adds the leftover rounds to a new batch.
  /// @dev Checks if this is the new latest batch
  /// @param remainingRounds Number of rounds to reduce the current batch to
  /// @param b The batch to add leftover rounds to
  function _splitBatch(uint24 remainingRounds, Rounds.Batch memory b) private {
    if (b.rounds == remainingRounds) return;
    Sanity.require(b.rounds > remainingRounds);

    uint64 newBatchNo = ++_batchCount;

    _batches[newBatchNo] = Rounds.Batch({
      nextBatchNo: b.nextBatchNo,
      totalUnitsBeforeBatch: b.totalUnitsBeforeBatch + uint80(remainingRounds) * b.unitPerRound,
      rounds: b.rounds - remainingRounds,
      unitPerRound: b.unitPerRound,
      state: b.state,
      roundPremiumRateSum: b.roundPremiumRateSum
    });
    _initTimeMark(newBatchNo);

    b.rounds = remainingRounds;
    if (b.nextBatchNo == 0) {
      _latestBatchNo = newBatchNo;
    }
    b.nextBatchNo = newBatchNo;
  }

  function _splitBatch(uint24 remainingRounds, uint64 batchNo) private returns (uint64) {
    Rounds.Batch memory b = _batches[batchNo];
    _splitBatch(remainingRounds, b);
    _batches[batchNo] = b;
    return b.nextBatchNo;
  }

  struct GetCoveredDemandParams {
    uint256 loopLimit;
    uint256 receivedCoverage;
    uint256 receivedPremium;
    address insured;
    bool done;
  }

  /// @dev Get the amount of demand that has been covered and the premium earned from it
  /// @param params Updates the received coverage
  /// @return coverage The values in this struct ONLY reflect the insured. IS FINALIZED
  /// @return covered Updated information based on newly collected coverage
  /// @return premium The premium paid and new premium rate
  function internalGetCoveredDemand(GetCoveredDemandParams memory params)
    internal
    view
    returns (
      DemandedCoverage memory coverage,
      Rounds.Coverage memory covered,
      Rounds.CoveragePremium memory premium
    )
  {
    Rounds.Demand[] storage demands = _demands[params.insured];
    premium = _premiums[params.insured];

    (coverage.totalPremium, coverage.premiumRate, coverage.premiumUpdatedAt) = (
      premium.coveragePremium,
      premium.coveragePremiumRate,
      premium.lastUpdatedAt
    );
    params.receivedPremium = uint256(_unitSize).wadMul(coverage.totalPremium);

    uint256 demandLength = demands.length;
    if (demandLength == 0) {
      params.done = true;
    } else {
      covered = _covered[params.insured];
      params.receivedCoverage = covered.coveredUnits;

      for (; params.loopLimit > 0; params.loopLimit--) {
        if (covered.lastUpdateIndex >= demandLength || !_collectCoveredDemandSlot(demands[covered.lastUpdateIndex], coverage, covered, premium)) {
          params.done = true;
          break;
        }
      }
    }

    _finalizePremium(coverage, true);
    coverage.totalDemand = uint256(_unitSize) * _insureds[params.insured].demandedUnits;
    coverage.totalCovered += uint256(_unitSize) * covered.coveredUnits;
    params.receivedCoverage = uint256(_unitSize) * (covered.coveredUnits - params.receivedCoverage);
    params.receivedPremium = coverage.totalPremium - params.receivedPremium;
  }

  function internalUpdateCoveredDemand(GetCoveredDemandParams memory params) internal returns (DemandedCoverage memory coverage) {
    (coverage, _covered[params.insured], _premiums[params.insured]) = internalGetCoveredDemand(params);
  }

  /// @dev Sets the function parameters to their correct values by calculating on new full batches
  /// @param d Update startBatchNo is set to the first open batch and rounds from last updated
  /// @param covered Update covered units and last known info based on the newly counted full batches
  /// @param premium Update total premium collected and the new premium rate for full batches
  /// @param coverage Update total premium collected and the new premium rate including the partial batch
  /// @return true if the demand has been completely filled
  function _collectCoveredDemandSlot(
    Rounds.Demand memory d,
    DemandedCoverage memory coverage,
    Rounds.Coverage memory covered,
    Rounds.CoveragePremium memory premium
  ) private view returns (bool) {
    // console.log('collect', d.rounds, covered.lastUpdateBatchNo, covered.lastUpdateRounds);

    uint24 fullRounds;
    if (covered.lastUpdateRounds > 0) {
      d.rounds -= covered.lastUpdateRounds; //Reduce by # of full rounds that was kept track of until lastUpdateBatchNo
      d.startBatchNo = covered.lastUpdateBatchNo;
    }
    if (covered.lastPartialRoundNo > 0) {
      covered.coveredUnits -= uint64(covered.lastPartialRoundNo) * d.unitPerRound;
      covered.lastPartialRoundNo = 0;
    }

    Rounds.Batch memory b;
    while (d.rounds > fullRounds) {
      Sanity.require(d.startBatchNo != 0);
      b = _batches[d.startBatchNo];
      // console.log('collectBatch', d.startBatchNo, b.nextBatchNo, b.rounds);

      if (!b.isFull()) break;
      // console.log('collectBatch1');

      // zero rounds may be present due to cancellations
      if (b.rounds > 0) {
        fullRounds += b.rounds;

        (premium.coveragePremium, premium.coveragePremiumRate, premium.lastUpdatedAt) = _calcPremium(
          d,
          premium,
          b.rounds,
          0,
          d.premiumRate,
          b.unitPerRound
        );
      }
      d.startBatchNo = b.nextBatchNo;
    }

    covered.coveredUnits += uint64(fullRounds) * d.unitPerRound;
    (coverage.totalPremium, coverage.premiumRate, coverage.premiumUpdatedAt) = (
      premium.coveragePremium,
      premium.coveragePremiumRate,
      premium.lastUpdatedAt
    );

    // if the covered.lastUpdateIndex demand has been fully covered
    if (d.rounds == fullRounds) {
      covered.lastUpdateRounds = 0;
      covered.lastUpdateBatchNo = 0;
      covered.lastUpdateIndex++;
      return true;
    }

    Sanity.require(d.rounds > fullRounds);
    Sanity.require(d.startBatchNo != 0);
    covered.lastUpdateRounds += fullRounds;
    covered.lastUpdateBatchNo = d.startBatchNo;

    PartialState memory part = _partial;
    // console.log('collectCheck', part.batchNo, covered.lastUpdateBatchNo);
    if (part.batchNo == d.startBatchNo) {
      // console.log('collectPartial', part.roundNo, part.roundCoverage);
      if (part.roundNo > 0 || part.roundCoverage > 0) {
        covered.coveredUnits += uint64(covered.lastPartialRoundNo = part.roundNo) * d.unitPerRound;
        coverage.pendingCovered = (uint256(part.roundCoverage) * d.unitPerRound) / _batches[d.startBatchNo].unitPerRound;

        (coverage.totalPremium, coverage.premiumRate, coverage.premiumUpdatedAt) = _calcPremium(
          d,
          premium,
          part.roundNo,
          coverage.pendingCovered,
          d.premiumRate,
          b.unitPerRound
        );
      }
    }

    return false;
  }

  /// @dev Calculate the actual premium values since variables keep track of number of coverage units instead of
  /// amount of coverage currency (coverage units * unit size).
  /// @dev NOTE: The effects from this should not be used in any calculations for modifying state
  function _finalizePremium(DemandedCoverage memory coverage, bool roundUp) private view {
    coverage.premiumRate = roundUp ? uint256(_unitSize).wadMulUp(coverage.premiumRate) : uint256(_unitSize).wadMul(coverage.premiumRate);
    coverage.totalPremium = uint256(_unitSize).wadMul(coverage.totalPremium);
    if (coverage.premiumUpdatedAt != 0) {
      coverage.totalPremium += coverage.premiumRate * (block.timestamp - coverage.premiumUpdatedAt);
      coverage.premiumRateUpdatedAt = coverage.premiumUpdatedAt;
      coverage.premiumUpdatedAt = uint32(block.timestamp);
    }
  }

  /// @dev Calculate the new premium values by including the rounds that have been filled for demand d and
  /// the partial rounds
  function _calcPremium(
    Rounds.Demand memory d,
    Rounds.CoveragePremium memory premium,
    uint24 rounds,
    uint256 pendingCovered,
    uint256 premiumRate,
    uint256 batchUnitPerRound
  )
    private
    view
    returns (
      uint96 coveragePremium,
      uint64 coveragePremiumRate,
      uint32 lastUpdatedAt
    )
  {
    TimeMark memory mark = _marks[d.startBatchNo];
    // console.log('premiumBefore', d.startBatchNo, d.unitPerRound, rounds);
    // console.log('premiumBefore', mark.timestamp, premium.lastUpdatedAt, mark.duration);
    // console.log('premiumBefore', premium.coveragePremium, premium.coveragePremiumRate, pendingCovered);
    // console.log('premiumBefore', mark.coverageTW, premiumRate, batchUnitPerRound);
    uint256 v = premium.coveragePremium;
    if (premium.lastUpdatedAt != 0) {
      v += uint256(premium.coveragePremiumRate) * (mark.timestamp - premium.lastUpdatedAt);
    }
    lastUpdatedAt = mark.timestamp;

    if (mark.coverageTW > 0) {
      // normalization by unitSize to reduce storage requirements
      v += _calcTimeMarkPortion(premiumRate * mark.coverageTW, d.unitPerRound, uint256(_unitSize) * batchUnitPerRound);
    }
    coveragePremium = v.asUint96();

    v = premium.coveragePremiumRate + premiumRate * uint256(rounds) * d.unitPerRound;
    if (pendingCovered > 0) {
      // normalization by unitSize to reduce storage requirements
      // roundup is aggresive here to ensure that this pools is guaranteed to pay not less that it pays out
      v += (pendingCovered * premiumRate + (_unitSize - 1)) / _unitSize;
    }
    Value.require((coveragePremiumRate = uint64(v)) == v);
    // console.log('premiumAfter', coveragePremium, coveragePremiumRate);
  }

  function _calcTimeMarkPortion(
    uint256 tw,
    uint16 unitPerRound,
    uint256 batchRoundUnits
  ) private pure returns (uint256) {
    return (tw * unitPerRound + (batchRoundUnits - 1)) / batchRoundUnits;
  }

  /// @dev Update the premium totals of coverage by including batch b
  function _collectPremiumTotalsFromPartial(
    PartialState memory part,
    Rounds.Batch memory b,
    Rounds.CoveragePremium memory premium,
    DemandedCoverage memory coverage
  ) private view {
    if (b.isFull() || (part.roundNo == 0 && part.roundCoverage == 0)) {
      (coverage.totalPremium, coverage.premiumRate, coverage.premiumUpdatedAt) = (
        premium.coveragePremium,
        premium.coveragePremiumRate,
        premium.lastUpdatedAt
      );
      return;
    }

    Rounds.Demand memory d;
    d.startBatchNo = part.batchNo;
    d.unitPerRound = 1;

    (coverage.totalPremium, coverage.premiumRate, coverage.premiumUpdatedAt) = _calcPremium(
      d,
      premium,
      part.roundNo,
      (part.roundCoverage + (b.unitPerRound - 1)) / b.unitPerRound,
      b.roundPremiumRateSum,
      b.unitPerRound
    );
  }

  function internalGetCoveredTotals() internal view returns (uint256 totalCovered, uint256 pendingCovered) {
    uint64 batchNo = _partial.batchNo;
    if (batchNo > 0) {
      Rounds.Batch storage b = _batches[batchNo];
      totalCovered = _unitSize * (_adjustedTotalUnits(b.totalUnitsBeforeBatch) + uint256(_partial.roundNo) * b.unitPerRound);
      pendingCovered = _partial.roundCoverage;
    }
  }

  function internalGetPremiumTotals() internal view returns (DemandedCoverage memory coverage) {
    return internalGetPremiumTotals(_partial, _poolPremium);
  }

  /// @return coverage All the coverage and premium values
  /// @dev IS FINALIZED
  function internalGetPremiumTotals(PartialState memory part, Rounds.CoveragePremium memory premium)
    internal
    view
    returns (DemandedCoverage memory coverage)
  {
    if (part.batchNo == 0) {
      return coverage;
    }

    Rounds.Batch memory b = _batches[part.batchNo];
    _collectPremiumTotalsFromPartial(part, b, premium, coverage);

    coverage.totalCovered = _adjustedTotalUnits(b.totalUnitsBeforeBatch) + uint256(part.roundNo) * b.unitPerRound;
    coverage.pendingCovered = part.roundCoverage;

    _finalizePremium(coverage, false);
    coverage.totalCovered *= _unitSize;
  }

  /// @dev Get the Pool's total amount of coverage that has been demanded, covered and allocated (partial round) and
  /// the corresponding premium based on these values
  /// @dev IS FINALIZED
  function internalGetTotals(uint256 loopLimit) internal view returns (DemandedCoverage memory coverage, TotalCoverage memory total) {
    PartialState memory part = _partial;
    if (part.batchNo == 0) return (coverage, total);

    uint64 thisBatch = part.batchNo;

    Rounds.Batch memory b = _batches[thisBatch];
    // console.log('batch0', thisBatch, b.nextBatchNo, b.rounds);
    // console.log('batch1', part.roundNo);
    _collectPremiumTotalsFromPartial(part, b, _poolPremium, coverage);

    uint80 adjustedTotal = _adjustedTotalUnits(b.totalUnitsBeforeBatch);
    coverage.totalCovered = adjustedTotal + uint256(part.roundNo) * b.unitPerRound;
    coverage.totalDemand = adjustedTotal + uint256(b.rounds) * b.unitPerRound;
    coverage.pendingCovered = part.roundCoverage;
    total.batchCount = 1;

    if (b.isReady()) {
      total.usableRounds = b.rounds - part.roundNo;
      total.totalCoverable = uint256(total.usableRounds) * b.unitPerRound;
    }
    if (b.isOpen()) {
      total.openRounds += b.rounds - part.roundNo;
    }

    for (; loopLimit > 0 && b.nextBatchNo != 0; loopLimit--) {
      thisBatch = b.nextBatchNo;
      b = _batches[b.nextBatchNo];
      // console.log('batch', thisBatch, b.nextBatchNo);

      total.batchCount++;
      coverage.totalDemand += uint256(b.rounds) * b.unitPerRound;

      if (b.isReady()) {
        total.usableRounds += b.rounds;
        total.totalCoverable += uint256(b.rounds) * b.unitPerRound;
      }

      if (b.isOpen()) {
        total.openRounds += b.rounds;
      }
    }

    _finalizePremium(coverage, false);
    coverage.totalCovered *= _unitSize;
    coverage.totalDemand *= _unitSize;
    total.totalCoverable = total.totalCoverable * _unitSize - coverage.pendingCovered;
  }

  struct AddCoverageParams {
    Rounds.CoveragePremium premium;
    /// @dev != 0 also indicates that at least one round was added
    uint64 openBatchNo;
    bool openBatchUpdated;
    bool batchUpdated;
    bool premiumUpdated;
    // uint256 unitsCovered;
  }

  /// @dev Satisfy coverage demand by adding coverage
  function internalAddCoverage(uint256 amount, uint256 loopLimit)
    internal
    returns (
      uint256 remainingAmount,
      uint256, /* remainingLoopLimit */
      AddCoverageParams memory params,
      PartialState memory part
    )
  {
    part = _partial;

    if (amount == 0 || loopLimit == 0 || part.batchNo == 0) {
      return (amount, loopLimit, params, part);
    }

    Rounds.Batch memory b;
    params.premium = _poolPremium;

    (remainingAmount, loopLimit, b) = _addCoverage(amount, loopLimit, part, params);
    if (params.batchUpdated) {
      _batches[part.batchNo] = b;
    }
    if (params.premiumUpdated) {
      _poolPremium = params.premium;
    }
    if (params.openBatchUpdated) {
      Sanity.require(params.openBatchNo != 0);
      _firstOpenBatchNo = params.openBatchNo;
    }
    _partial = part;
    // console.log('partial3', part.batchNo, part.roundNo, part.roundCoverage);

    return (remainingAmount, loopLimit, params, part);
  }

  /// @dev Adds coverage to the pool and stops if there are no batches left to add coverage to or
  /// if the current batch is not ready to accept coverage
  function _addCoverage(
    uint256 amount,
    uint256 loopLimit,
    PartialState memory part,
    AddCoverageParams memory params
  )
    internal
    returns (
      uint256, /* remainingAmount */
      uint256 remainingLoopLimit,
      Rounds.Batch memory b
    )
  {
    b = _batches[part.batchNo];

    if (part.roundCoverage > 0) {
      Sanity.require(b.isReady());

      _updateTimeMark(part, b.unitPerRound);

      uint256 maxRoundCoverage = uint256(_unitSize) * b.unitPerRound;
      uint256 vacant = maxRoundCoverage - part.roundCoverage;
      if (amount < vacant) {
        part.roundCoverage += uint128(amount);
        return (0, loopLimit - 1, b);
      }
      // params.unitsCovered = b.unitPerRound;
      part.roundCoverage = 0;
      part.roundNo++;
      amount -= vacant;
    } else if (!b.isReady()) {
      return (amount, loopLimit - 1, b);
    }

    /// @dev != 0 also indicates that at least one round was added
    params.openBatchNo = _firstOpenBatchNo;
    while (true) {
      loopLimit--;

      // if filled in the final round of a batch
      if (part.roundNo >= b.rounds) {
        Sanity.require(part.roundNo == b.rounds);
        Sanity.require(part.roundCoverage == 0);

        if (b.state != Rounds.State.Full) {
          b.state = Rounds.State.Full;
          params.batchUpdated = true;

          if (b.unitPerRound == 0) {
            // this is a special case when all units were removed by cancellations
            Sanity.require(b.rounds == 0);
            // total premium doesn't need to be updated as the rate remains the same
          } else {
            _addPartialToTotalPremium(part.batchNo, params.premium, b);
            params.premiumUpdated = true;
          }
        }

        if (params.batchUpdated) {
          _batches[part.batchNo] = b;
          params.batchUpdated = false;
        }

        if (part.batchNo == params.openBatchNo) {
          params.openBatchNo = b.nextBatchNo;
          params.openBatchUpdated = true;
        }

        if (b.nextBatchNo == 0) break;

        // do NOT do like this here:  part = PartialState({batchNo: b.nextBatchNo, roundNo: 0, roundCoverage: 0});
        (part.batchNo, part.roundNo, part.roundCoverage) = (b.nextBatchNo, 0, 0);
        // console.log('partial0', part.batchNo, part.roundNo, part.roundCoverage);

        uint80 totalUnitsBeforeBatch = b.totalUnitsBeforeBatch;
        if (b.rounds > 0) {
          _openRounds -= b.rounds;
          totalUnitsBeforeBatch += uint80(b.rounds) * b.unitPerRound;
        }

        b = _batches[part.batchNo];

        if (totalUnitsBeforeBatch != b.totalUnitsBeforeBatch) {
          b.totalUnitsBeforeBatch = totalUnitsBeforeBatch;
          params.batchUpdated = true;
        }

        if (amount == 0) break;
        if (!b.isReady()) {
          return (amount, loopLimit, b);
        }
      } else {
        _updateTimeMark(part, b.unitPerRound);

        uint256 maxRoundCoverage = uint256(_unitSize) * b.unitPerRound;
        uint256 n = amount / maxRoundCoverage;

        uint24 vacantRounds = b.rounds - part.roundNo;
        Sanity.require(vacantRounds > 0);

        if (n < vacantRounds) {
          // params.unitsCovered += n * b.unitPerRound;
          part.roundNo += uint24(n);
          part.roundCoverage = uint128(amount - maxRoundCoverage * n);
          amount = 0;
          break;
        }

        // params.unitsCovered += vacantRounds * b.unitPerRound;
        part.roundNo = b.rounds;
        amount -= maxRoundCoverage * vacantRounds;
        if (loopLimit > 0) continue; // make sure to move to the next batch
      }
      if (amount == 0 || loopLimit == 0) {
        break;
      }
    }

    return (amount, loopLimit, b);
  }

  /// @dev Sets the values of premium to include the partial batch b
  function _addPartialToTotalPremium(
    uint64 batchNo,
    Rounds.CoveragePremium memory premium,
    Rounds.Batch memory b
  ) internal view {
    (premium.coveragePremium, premium.coveragePremiumRate, premium.lastUpdatedAt) = _calcPremium(
      Rounds.Demand(batchNo, 0, 0, 1),
      premium,
      b.rounds,
      0,
      b.roundPremiumRateSum,
      b.unitPerRound
    );
  }

  function _initTimeMark(uint64 batchNo) private {
    // NB! this moves some of gas costs from addCoverage to addCoverageDemand
    _marks[batchNo].timestamp = 1;
  }

  /// @dev Updates the timeMark for the partial batch which calculates the "area under the curve"
  /// of the coverage curve over time
  function _updateTimeMark(PartialState memory part, uint256 batchUnitPerRound) private {
    // console.log('==updateTimeMark', part.batchNo);
    Sanity.require(part.batchNo != 0);
    TimeMark memory mark = _marks[part.batchNo];

    if (mark.timestamp <= 1) {
      mark.coverageTW = 0;
      mark.duration = 0;
    } else {
      uint32 duration = uint32(block.timestamp - mark.timestamp);
      if (duration == 0) return;

      uint256 coverageTW = mark.coverageTW + (uint256(_unitSize) * part.roundNo * batchUnitPerRound + part.roundCoverage) * duration;
      Value.require(coverageTW == (mark.coverageTW = uint192(coverageTW)));

      mark.duration += duration;
    }
    mark.timestamp = uint32(block.timestamp);

    _marks[part.batchNo] = mark;
  }

  struct Dump {
    uint64 batchCount;
    uint64 latestBatch;
    /// @dev points to an earliest round that is open, can be zero when all rounds are full
    uint64 firstOpenBatch;
    PartialState part;
    Rounds.Batch[] batches;
  }

  /// @dev Return coverage and premium information for an insured
  function _dumpInsured(address insured)
    internal
    view
    returns (
      Rounds.InsuredEntry memory,
      Rounds.Demand[] memory,
      Rounds.Coverage memory,
      Rounds.CoveragePremium memory
    )
  {
    return (_insureds[insured], _demands[insured], _covered[insured], _premiums[insured]);
  }

  /// @return dump The current state of the batches of the system
  function _dump() internal view returns (Dump memory dump) {
    dump.batchCount = _batchCount;
    dump.latestBatch = _latestBatchNo;
    dump.firstOpenBatch = _firstOpenBatchNo;
    dump.part = _partial;
    uint64 j = 0;
    for (uint64 i = dump.part.batchNo; i > 0; i = _batches[i].nextBatchNo) {
      j++;
    }
    dump.batches = new Rounds.Batch[](j);
    j = 0;
    for (uint64 i = dump.part.batchNo; i > 0; ) {
      Rounds.Batch memory b = _batches[i];
      i = b.nextBatchNo;
      dump.batches[j++] = b;
    }
  }

  /// @return If coverage can be added to the partial state
  function internalCanAddCoverage() internal view returns (bool) {
    uint64 batchNo = _partial.batchNo;
    return batchNo != 0 && (_partial.roundCoverage > 0 || _batches[batchNo].state.isReady());
  }

  struct CancelCoverageDemandParams {
    uint256 loopLimit;
    address insured;
    bool done;
    // temp var
    uint80 totalUnitsBeforeBatch;
  }

  /// @dev Try to cancel `unitCount` units of coverage demand
  /// @return The amount of units that were cancelled
  function internalCancelCoverageDemand(uint64 unitCount, CancelCoverageDemandParams memory params) internal returns (uint64) {
    Rounds.InsuredEntry storage entry = _insureds[params.insured];
    Access.require(entry.status == MemberStatus.Accepted);

    _removeFromPullable(params.insured, entry.nextBatchNo);

    if (unitCount == 0 || params.loopLimit == 0 || entry.demandedUnits == _covered[params.insured].coveredUnits) {
      return 0;
    }

    Rounds.Demand[] storage demands = _demands[params.insured];

    (uint256 index, uint64 batchNo, uint256 skippedRounds, Rounds.Demand memory demand, uint64 cancelledUnits) = _findAndAdjustUncovered(
      unitCount,
      demands,
      params
    );

    if (cancelledUnits == 0) {
      return 0;
    }

    entry.nextBatchNo = batchNo;
    entry.demandedUnits -= cancelledUnits;

    uint24 cancelFirstSlotRounds = uint24(demand.rounds - skippedRounds);
    Sanity.require(cancelFirstSlotRounds > 0);

    demand.rounds = uint24(skippedRounds);

    (batchNo, params.totalUnitsBeforeBatch) = _adjustUncoveredBatches(
      batchNo,
      cancelFirstSlotRounds,
      _batches[batchNo].totalUnitsBeforeBatch,
      demand
    );

    _adjustUncoveredSlots(batchNo, uint80(cancelFirstSlotRounds) * demand.unitPerRound, demands, index + 1, params);

    for (uint256 i = demands.length - index; i > 1; i--) {
      demands.pop();
    }

    if (demand.rounds == 0) {
      demands.pop();
    } else {
      demands[index] = demand;
    }

    return cancelledUnits;
  }

  /// @dev Remove coverage demand from batches
  function _findAndAdjustUncovered(
    uint64 unitCount,
    Rounds.Demand[] storage demands,
    CancelCoverageDemandParams memory params
  )
    private
    returns (
      uint256 index,
      uint64 batchNo,
      uint256 skippedRounds,
      Rounds.Demand memory demand,
      uint64 cancelledUnits
    )
  {
    PartialState memory part = _partial;

    for (index = demands.length; index > 0 && params.loopLimit > 0; params.loopLimit--) {
      index--;

      Rounds.Demand memory prev = demand;
      demand = demands[index];

      uint64 cancelUnits;
      (params.done, batchNo, cancelUnits, skippedRounds) = _findUncoveredBatch(part, demand, unitCount - cancelledUnits);

      cancelledUnits += cancelUnits;
      if (params.done) {
        if (skippedRounds == demand.rounds) {
          // the whole demand slot was skipped, so use the previous one
          Sanity.require(cancelUnits == 0);
          index++;
          demand = prev;
          batchNo = prev.startBatchNo;
          skippedRounds = 0;
        }
        break;
      }

      Sanity.require(skippedRounds == 0);
    }
  }

  /// @dev Find the batch to remove coverage demand from
  function _findUncoveredBatch(
    PartialState memory part,
    Rounds.Demand memory demand,
    uint256 unitCount
  )
    private
    returns (
      bool done,
      uint64 batchNo,
      uint64 cancelUnits,
      uint256 skippedRounds
    )
  {
    batchNo = demand.startBatchNo;

    uint256 partialRounds;
    if (batchNo == part.batchNo) {
      done = true;
    } else if (_batches[batchNo].state.isFull()) {
      for (;;) {
        Rounds.Batch storage batch = _batches[batchNo];
        skippedRounds += batch.rounds;
        if (skippedRounds >= demand.rounds) {
          Sanity.require(skippedRounds == demand.rounds);
          return (true, batchNo, 0, skippedRounds);
        }
        batchNo = batch.nextBatchNo;
        if (batchNo == part.batchNo) {
          break;
        }
      }
      done = true;
    }
    if (done) {
      partialRounds = part.roundCoverage == 0 ? part.roundNo : part.roundNo + 1;
    }

    uint256 neededRounds = (uint256(unitCount) + demand.unitPerRound - 1) / demand.unitPerRound;

    if (demand.rounds <= skippedRounds + partialRounds + neededRounds) {
      // we should cancel all demands of this slot
      if (partialRounds > 0) {
        // the partial batch can alway be split
        batchNo = _splitBatch(uint24(partialRounds), batchNo);
        skippedRounds += partialRounds;
      }
      neededRounds = demand.rounds - skippedRounds;
    } else {
      // there is more demand in this slot than needs to be cancelled
      // so some batches may be skipped
      done = true;
      uint256 excessRounds = uint256(demand.rounds) - skippedRounds - neededRounds;

      for (; excessRounds > 0; ) {
        Rounds.Batch storage batch = _batches[batchNo];

        uint24 rounds = batch.rounds;
        if (rounds > excessRounds) {
          uint24 remainingRounds;
          unchecked {
            remainingRounds = rounds - uint24(excessRounds);
          }
          if (batchNo == part.batchNo || internalCanSplitBatchOnCancel(batchNo, remainingRounds)) {
            // partial batch can always be split, otherwise the policy decides
            batchNo = _splitBatch(remainingRounds, batchNo);
          } else {
            // cancel more than actually requested to avoid fragmentation of batches
            neededRounds += remainingRounds;
          }
          break;
        } else {
          skippedRounds += rounds;
          excessRounds -= rounds;
          batchNo = batch.nextBatchNo;
        }
      }
    }
    cancelUnits = uint64(neededRounds * demand.unitPerRound);
  }

  function internalCanSplitBatchOnCancel(uint64 batchNo, uint24 remainingRounds) internal view virtual returns (bool) {}

  function _adjustUncoveredSlots(
    uint64 batchNo,
    uint80 totalUnitsAdjustment,
    Rounds.Demand[] storage demands,
    uint256 startFrom,
    CancelCoverageDemandParams memory params
  ) private {
    uint256 maxIndex = demands.length;

    for (uint256 i = startFrom; i < maxIndex; i++) {
      Rounds.Demand memory d = demands[i];
      if (d.startBatchNo != batchNo) {
        params.totalUnitsBeforeBatch = _batches[d.startBatchNo].totalUnitsBeforeBatch;
        if (params.totalUnitsBeforeBatch > totalUnitsAdjustment) {
          params.totalUnitsBeforeBatch -= totalUnitsAdjustment;
        } else {
          params.totalUnitsBeforeBatch = 0;
        }
      }
      (batchNo, params.totalUnitsBeforeBatch) = _adjustUncoveredBatches(d.startBatchNo, d.rounds, params.totalUnitsBeforeBatch, d);
      totalUnitsAdjustment += uint80(d.rounds) * d.unitPerRound;
    }

    if (totalUnitsAdjustment > 0) {
      _pendingCancelledDemandUnits += totalUnitsAdjustment;
    }
  }

  function _adjustUncoveredBatches(
    uint64 batchNo,
    uint256 rounds,
    uint80 totalUnitsBeforeBatch,
    Rounds.Demand memory demand
  ) private returns (uint64, uint80) {
    for (; rounds > 0; ) {
      Rounds.Batch storage batch = _batches[batchNo];
      (uint24 br, uint16 bupr) = (batch.rounds, batch.unitPerRound);
      rounds -= br;
      if (bupr == demand.unitPerRound) {
        (batch.rounds, batch.roundPremiumRateSum, bupr) = (0, 0, 0);
        _openRounds -= br;
      } else {
        bupr -= demand.unitPerRound;
        batch.roundPremiumRateSum -= uint56(demand.unitPerRound) * demand.premiumRate;
      }

      batch.unitPerRound = bupr;
      batch.totalUnitsBeforeBatch = totalUnitsBeforeBatch;

      totalUnitsBeforeBatch += uint80(br) * bupr;

      if (batch.state == Rounds.State.Ready) {
        batch.state = Rounds.State.ReadyMin;
      }

      batchNo = batch.nextBatchNo;
    }
    return (batchNo, totalUnitsBeforeBatch);
  }

  function internalGetUnadjustedUnits()
    internal
    view
    returns (
      uint256 total,
      uint256 pendingCovered,
      uint256 pendingDemand
    )
  {
    Rounds.Batch storage b = _batches[_partial.batchNo];
    return (uint256(b.totalUnitsBeforeBatch) + _partial.roundNo * b.unitPerRound, _pendingCancelledCoverageUnits, _pendingCancelledDemandUnits);
  }

  function internalApplyAdjustmentsToTotals() internal {
    uint80 totals = _pendingCancelledCoverageUnits;
    if (totals == 0 && _pendingCancelledDemandUnits == 0) {
      return;
    }
    (_pendingCancelledCoverageUnits, _pendingCancelledDemandUnits) = (0, 0);

    uint64 batchNo = _partial.batchNo;
    totals = _batches[batchNo].totalUnitsBeforeBatch - totals;

    for (; batchNo > 0; ) {
      Rounds.Batch storage b = _batches[batchNo];
      b.totalUnitsBeforeBatch = totals;
      totals += uint80(b.rounds) * b.unitPerRound;
      batchNo = b.nextBatchNo;
    }
  }

  error DemandMustBeCancelled();

  /// @dev Cancel ALL coverage for the insured, including in the partial state
  /// @dev Deletes the coverage information and demands of the insured
  /// @return coverage The coverage info of the insured. IS FINALIZED
  /// @return excessCoverage The new amount of excess coverage
  /// @return providedCoverage Amount of coverage provided before cancellation
  /// @return receivedCoverage Amount of coverage received from the sync before cancelling
  function internalCancelCoverage(address insured)
    internal
    returns (
      DemandedCoverage memory coverage,
      uint256 excessCoverage,
      uint256 providedCoverage,
      uint256 receivedCoverage,
      uint256 receivedPremium
    )
  {
    Rounds.InsuredEntry storage entry = _insureds[insured];

    if (entry.demandedUnits == 0) {
      return (coverage, 0, 0, 0, 0);
    }
    _removeFromPullable(insured, entry.nextBatchNo);

    Rounds.Coverage memory covered;
    Rounds.CoveragePremium memory premium;
    (coverage, covered, premium, receivedCoverage, receivedPremium) = _syncBeforeCancelCoverage(insured);

    Rounds.Demand[] storage demands = _demands[insured];
    Rounds.Demand memory d;
    PartialState memory part = _partial;

    if (covered.lastUpdateIndex < demands.length) {
      if (covered.lastUpdateIndex == demands.length - 1 && covered.lastUpdateBatchNo == part.batchNo && covered.lastPartialRoundNo == part.roundNo) {
        d = demands[covered.lastUpdateIndex];
      } else {
        revert DemandMustBeCancelled();
      }
    } else {
      Sanity.require(entry.demandedUnits == covered.coveredUnits);
    }

    providedCoverage = covered.coveredUnits * _unitSize;
    _pendingCancelledCoverageUnits += covered.coveredUnits - uint64(covered.lastPartialRoundNo) * d.unitPerRound;

    if (part.batchNo > 0) {
      _premiums[insured] = _cancelPremium(premium, coverage.totalPremium);
      // ATTN! There MUST be a call to _updateTimeMark AFTER _cancelPremium - this call is inside _cancelPartialCoverage
      excessCoverage = _cancelPartialCoverage(part, d);
    }

    entry.demandedUnits = 0;
    entry.nextBatchNo = 0;
    delete (_covered[insured]);
    delete (_demands[insured]);
  }

  /// @dev Sync the insured's amount of coverage and premium paid
  /// @return coverage FINAZLIED coverage amounts ONLY for the insured
  /// @return covered Updated coverage info from sync
  /// @return premium Total premium collected and rate after sync
  /// @return receivedCoverage FINALIZED amount of covered units during this sync
  function _syncBeforeCancelCoverage(address insured)
    private
    view
    returns (
      DemandedCoverage memory coverage,
      Rounds.Coverage memory covered,
      Rounds.CoveragePremium memory premium,
      uint256 receivedCoverage,
      uint256 receivedPremium
    )
  {
    GetCoveredDemandParams memory params;
    params.insured = insured;
    params.loopLimit = ~uint256(0);

    (coverage, covered, premium) = internalGetCoveredDemand(params);
    Sanity.require(params.done);

    receivedCoverage = params.receivedCoverage;
    receivedPremium = params.receivedPremium;
  }

  /// @dev Cancel coverage in the partial state
  /// @return excessCoverage The new amount of excess coverage
  function _cancelPartialCoverage(PartialState memory part, Rounds.Demand memory d) private returns (uint128 excessCoverage) {
    Rounds.Batch storage partBatch = _batches[part.batchNo];
    Rounds.Batch memory b = partBatch;

    // Call to _updateTimeMark is MUST, because of _cancelPremium updating _poolPremium's timestamp
    _updateTimeMark(part, b.unitPerRound);

    if (d.unitPerRound == 0) {
      return 0;
    }
    Sanity.require(d.unitPerRound <= b.unitPerRound);

    {
      TimeMark storage mark = _marks[part.batchNo];
      uint192 coverageTW = mark.coverageTW;
      if (coverageTW > 0) {
        // reduce the integral summ proportionally - the relevant part was added to finalPremium already
        uint256 delta = _calcTimeMarkPortion(coverageTW, d.unitPerRound, b.unitPerRound);
        mark.coverageTW = uint192(coverageTW - delta);
      }
    }

    (partBatch.unitPerRound, partBatch.roundPremiumRateSum) = (
      b.unitPerRound -= d.unitPerRound,
      b.roundPremiumRateSum - uint56(d.premiumRate) * d.unitPerRound
    );

    if (b.unitPerRound == 0) {
      excessCoverage = part.roundCoverage;
      _partial.roundCoverage = part.roundCoverage = 0;
      _partial.roundNo = part.roundNo = 0;
    } else if (part.roundCoverage > 0) {
      excessCoverage = uint128(_unitSize) * b.unitPerRound;

      if (part.roundCoverage > excessCoverage) {
        (part.roundCoverage, excessCoverage) = (excessCoverage, part.roundCoverage - excessCoverage);
        _partial.roundCoverage = part.roundCoverage;
      }
    }
  }

  /// @dev Update the premium based on time elapsed and premium rate
  function _syncPremium(Rounds.CoveragePremium memory premium) private view returns (Rounds.CoveragePremium memory) {
    if (premium.lastUpdatedAt != 0) {
      premium.coveragePremium += uint96(premium.coveragePremiumRate) * (uint32(block.timestamp) - premium.lastUpdatedAt);
    }
    premium.lastUpdatedAt = uint32(block.timestamp);
    return premium;
  }

  /// @dev Cancel premium according to the parameters, and adjust the global pool's premium rate
  /// @param premium The premium info of the insured
  /// @param finalPremium The REAL amount of premium collected from the insured (multiplied by unitSize)
  /// @return A new CoveragePremium struct with the rate set to 0
  function _cancelPremium(Rounds.CoveragePremium memory premium, uint256 finalPremium) private returns (Rounds.CoveragePremium memory) {
    Rounds.CoveragePremium memory poolPremium = _syncPremium(_poolPremium);

    finalPremium = finalPremium.wadDiv(_unitSize).asUint96();

    poolPremium.coveragePremiumRate -= premium.coveragePremiumRate;
    poolPremium.coveragePremium += uint96(finalPremium - premium.coveragePremium);

    if (premium.lastUpdatedAt != poolPremium.lastUpdatedAt) {
      // avoid double-counting when premiuns are not synced
      poolPremium.coveragePremium -= uint96(premium.coveragePremiumRate) * (poolPremium.lastUpdatedAt - premium.lastUpdatedAt);
    }

    _poolPremium = poolPremium;

    return Rounds.CoveragePremium({coveragePremiumRate: 0, coveragePremium: uint96(finalPremium), lastUpdatedAt: poolPremium.lastUpdatedAt});
  }

  function _addToPullable(address insured, uint64 batchNo) private {
    _pullableDemands[batchNo].add(insured);
  }

  function _removeFromPullable(address insured, uint64 batchNo) private {
    _pullableDemands[batchNo].remove(insured);
  }

  function internalPullDemandCandidate(uint256 loopLimit, bool trimOnly) internal returns (address insured, uint256) {
    uint64 batchNo;
    uint64 pullableBatchNo = batchNo = _pullableBatchNo;
    if (batchNo == 0) {
      batchNo = 1;
    }

    for (; loopLimit > 0; ) {
      loopLimit--;

      Rounds.Batch storage batch = _batches[batchNo];
      if (!batch.state.isFull()) {
        break;
      }

      EnumerableSet.AddressSet storage demands = _pullableDemands[batchNo];
      for (uint256 n = demands.length(); n > 0; ) {
        n--;
        insured = demands.at(n);
        if (_insureds[insured].status == MemberStatus.Accepted) {
          if (!trimOnly) {
            demands.remove(insured);
          }
          break;
        }
        demands.remove(insured);
        insured = address(0);
        if (loopLimit == 0) {
          break;
        }
        loopLimit--;
      }
      if (insured != address(0)) {
        break;
      }

      uint64 nextBatchNo = batch.nextBatchNo;
      if (nextBatchNo == 0) {
        break;
      }
      batchNo = nextBatchNo;
    }

    if (pullableBatchNo != batchNo) {
      _pullableBatchNo = batchNo;
    }

    return (insured, loopLimit);
  }

  function internalOpenBatchRounds() internal view returns (uint256) {
    return _batches[_firstOpenBatchNo].rounds;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/introspection/ERC165Checker.sol';
import '../tools/math/PercentageMath.sol';
import '../tools/math/WadRayMath.sol';
import '../tools/math/Math.sol';
import '../governance/interfaces/IInsurerGovernor.sol';
import '../governance/GovernedHelper.sol';
import './InsurerJoinBase.sol';

abstract contract WeightedPoolAccessControl is GovernedHelper, InsurerJoinBase {
  using PercentageMath for uint256;

  address private _governor;
  bool private _governorIsContract;

  function _onlyActiveInsured(address insurer) internal view {
    Access.require(internalGetStatus(insurer) == MemberStatus.Accepted);
  }

  function _onlyInsured(address insurer) private view {
    Access.require(internalGetStatus(insurer) > MemberStatus.Unknown);
  }

  modifier onlyActiveInsured() {
    _onlyActiveInsured(msg.sender);
    _;
  }

  modifier onlyInsured() {
    _onlyInsured(msg.sender);
    _;
  }

  function internalSetTypedGovernor(IInsurerGovernor addr) internal {
    _governorIsContract = true;
    _setGovernor(address(addr));
  }

  function internalSetGovernor(address addr) internal virtual {
    // will also return false for EOA
    _governorIsContract = ERC165Checker.supportsInterface(addr, type(IInsurerGovernor).interfaceId);
    _setGovernor(addr);
  }

  function governorContract() internal view virtual returns (IInsurerGovernor) {
    return IInsurerGovernor(_governorIsContract ? governorAccount() : address(0));
  }

  function isAllowedByGovernor(address account, uint256 flags) internal view override returns (bool) {
    return _governorIsContract && IInsurerGovernor(governorAccount()).governerQueryAccessControlMask(account, flags) & flags != 0;
  }

  function internalInitiateJoin(address insured) internal override returns (MemberStatus) {
    IJoinHandler jh = governorContract();
    if (address(jh) == address(0)) {
      IApprovalCatalog c = approvalCatalog();
      Access.require(address(c) == address(0) || c.hasApprovedApplication(insured));
      return MemberStatus.Joining;
    } else {
      return jh.handleJoinRequest(insured);
    }
  }

  event GovernorUpdated(address);

  function _setGovernor(address addr) internal {
    emit GovernorUpdated(_governor = addr);
  }

  function governorAccount() internal view override returns (address) {
    return _governor;
  }

  function internalVerifyPayoutRatio(
    address insured,
    uint256 payoutRatio,
    bool enforcedCancel
  ) internal virtual returns (uint256 approvedPayoutRatio) {
    IInsurerGovernor jh = governorContract();
    if (address(jh) == address(0)) {
      IApprovalCatalog c = approvalCatalog();
      if (address(c) == address(0)) {
        return payoutRatio;
      }

      if (!enforcedCancel || c.hasApprovedClaim(insured)) {
        IApprovalCatalog.ApprovedClaim memory info = c.applyApprovedClaim(insured);

        Access.require(enforcedCancel || info.since <= block.timestamp);
        approvedPayoutRatio = WadRayMath.RAY.percentMul(info.payoutRatio);
      }
      // else approvedPayoutRatio = 0 (for enfoced calls without an approved claim)
    } else if (!enforcedCancel || payoutRatio > 0) {
      approvedPayoutRatio = jh.verifyPayoutRatio(insured, payoutRatio);
    }

    if (payoutRatio < approvedPayoutRatio) {
      approvedPayoutRatio = payoutRatio;
    }
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/tokens/IERC20.sol';
import './ICoverageDistributor.sol';

interface IInsurerPoolBase is ICollateralized, ICharterable {
  /// @dev returns ratio of $IC to $CC, this starts as 1 (RAY)
  function exchangeRate() external view returns (uint256);
}

interface IPerpetualInsurerPool is IInsurerPoolBase {
  /// @notice The interest of the account is their earned premium amount
  /// @param account The account to query
  /// @return rate The current interest rate of the account
  /// @return accumulated The current earned premium of the account
  function interestOf(address account) external view returns (uint256 rate, uint256 accumulated);

  /// @notice Withdrawable amount of this account
  /// @param account The account to query
  /// @return amount The amount withdrawable
  function withdrawable(address account) external view returns (uint256 amount);

  /// @notice Attempt to withdraw all of a user's coverage
  /// @return The amount withdrawn
  function withdrawAll() external returns (uint256);
}

interface IInsurerPool is IERC20, IInsurerPoolBase, ICoverageDistributor {}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.10;

/*

UnitPremiumRate per sec * 365 days <= 1 WAD (i.e. 1 WAD = 100% of coverage p.a.)
=>> UnitPremiumRate is uint40
=>> timestamp ~80y

=>> RoundPremiumRate = UnitPremiumRate (40) * unitPerRound (16) = 56

=>> InsuredPremiumRate = UnitPremiumRate (40) * avgUnits (24) = 64
=>> AccumulatedInsuredPremiumRate = InsuredPremiumRate (64) * timestamp (32) = 96

=>> PoolPremiumRate = UnitPremiumRate (40) * maxUnits (64) = 104
=>> PoolAccumulatedPremiumRate = PoolPremiumRate (104) * timestamp (32) = 140

*/

library Rounds {
  /// @dev demand log entry, related to a single insurd pool
  struct Demand {
    /// @dev first batch that includes this demand
    uint64 startBatchNo;
    /// @dev premiumRate for this demand
    uint40 premiumRate;
    /// @dev number of rounds accross all batches where this demand was added
    uint24 rounds;
    /// @dev number of units added to each round by this demand
    uint16 unitPerRound;
  }

  struct InsuredParams {
    /// @dev a minimum number of units to be allocated for an insured in a single batch. Best effort, but may be ignored.
    uint24 minUnits;
    /// @dev a maximum % of units this insured can have per round. This is a hard limit.
    uint16 maxShare;
    /// @dev a minimum premium rate to accept new coverage demand
    uint40 minPremiumRate;
  }

  struct InsuredEntry {
    /// @dev batch number to add next demand (if it will be open) otherwise it will start with the earliest open batch
    uint64 nextBatchNo;
    /// @dev total number of units demanded by this insured pool
    uint64 demandedUnits;
    /// @dev see InsuredParams
    PackedInsuredParams params;
    /// @dev status of the insured pool
    MemberStatus status;
  }

  struct Coverage {
    /// @dev total number of units covered for this insured pool
    uint64 coveredUnits;
    /// @dev index of Demand entry that is covered partially or will be covered next
    uint64 lastUpdateIndex;
    /// @dev Batch that is a part of the partially covered Demand
    uint64 lastUpdateBatchNo;
    /// @dev number of rounds within the Demand (lastUpdateIndex) starting from Demand's startBatchNo till lastUpdateBatchNo
    uint24 lastUpdateRounds;
    /// @dev number of rounds of a partial batch included into coveredUnits
    uint24 lastPartialRoundNo;
  }

  struct CoveragePremium {
    /// @dev total premium collected till lastUpdatedAt
    uint96 coveragePremium;
    /// @dev premium collection rate at lastUpdatedAt
    uint64 coveragePremiumRate;
    // uint64
    /// @dev time of the last updated applied
    uint32 lastUpdatedAt;
  }

  /// @dev Draft round can NOT receive coverage, more units can be added, always unbalanced
  /// @dev ReadyMin is a Ready round where more units can be added, may be unbalanced
  /// @dev Ready round can receive coverage, more units can NOT be added, balanced
  /// @dev Full round can NOT receive coverage, more units can NOT be added - full rounds are summed up and ignored further
  enum State {
    Draft,
    ReadyMin,
    Ready,
    Full
  }

  struct Batch {
    /// @dev sum of premium rates provided by all units (from different insured pools), per round
    uint56 roundPremiumRateSum;
    /// @dev next batch number (one-way linked list)
    uint64 nextBatchNo;
    /// @dev total number of units befor this batch, this value may not be exact for non-ready batches
    uint80 totalUnitsBeforeBatch;
    /// @dev number of rounds within the batch, can only be zero for an empty (not initialized batch)
    uint24 rounds;
    /// @dev number of units for each round of this batch
    uint16 unitPerRound;
    /// @dev state of this batch
    State state;
  }

  function isFull(Batch memory b) internal pure returns (bool) {
    return isFull(b.state);
  }

  function isOpen(Batch memory b) internal pure returns (bool) {
    return isOpen(b.state);
  }

  function isReady(Batch memory b) internal pure returns (bool) {
    return isReady(b.state);
  }

  function isDraft(State state) internal pure returns (bool) {
    return state == State.Draft;
  }

  function isFull(State state) internal pure returns (bool) {
    return state == State.Full;
  }

  function isOpen(State state) internal pure returns (bool) {
    return state <= State.ReadyMin;
  }

  function isReady(State state) internal pure returns (bool) {
    return state >= State.ReadyMin && state <= State.Ready;
  }

  type PackedInsuredParams is uint80;

  function packInsuredParams(
    uint24 minUnits_,
    uint16 maxShare_,
    uint40 minPremiumRate_
  ) internal pure returns (PackedInsuredParams) {
    return PackedInsuredParams.wrap(uint80((uint256(minPremiumRate_) << 40) | (uint256(maxShare_) << 24) | minUnits_));
  }

  function unpackInsuredParams(PackedInsuredParams v) internal pure returns (InsuredParams memory p) {
    p.minUnits = minUnits(v);
    p.maxShare = maxShare(v);
    p.minPremiumRate = minPremiumRate(v);
  }

  function minUnits(PackedInsuredParams v) internal pure returns (uint24) {
    return uint24(PackedInsuredParams.unwrap(v));
  }

  function maxShare(PackedInsuredParams v) internal pure returns (uint16) {
    return uint16(PackedInsuredParams.unwrap(v) >> 24);
  }

  function minPremiumRate(PackedInsuredParams v) internal pure returns (uint40) {
    return uint40(PackedInsuredParams.unwrap(v) >> 40);
  }
}

enum MemberStatus {
  Unknown,
  JoinCancelled,
  JoinRejected,
  JoinFailed,
  Declined,
  Joining,
  Accepted,
  Banned,
  NotApplicable
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './ICollateralized.sol';
import './ICharterable.sol';

interface ICancellableCoverage {
  /// @notice Cancel coverage for the sender
  /// @dev Called by insureds
  /// @param payoutRatio The RAY ratio of how much of provided coverage should be paid out
  /// @dev e.g payoutRatio = 5e26 means 50% of coverage is paid
  /// @return payoutValue The amount of coverage paid out to the insured
  function cancelCoverage(address insured, uint256 payoutRatio) external returns (uint256 payoutValue);
}

interface ICancellableCoverageDemand is ICancellableCoverage {
  /// @dev size of collateral allocation chunk made by this pool
  function coverageUnitSize() external view returns (uint256);

  /// @notice Cancel coverage that has been demanded, but not filled yet
  /// @dev can only be called by an accepted insured pool
  /// @param unitCount The number of units that wishes to be cancelled
  /// @return cancelledUnits The amount of units that were cancelled
  function cancelCoverageDemand(
    address insured,
    uint256 unitCount,
    uint256 loopLimit
  ) external returns (uint256 cancelledUnits);
}

interface ICoverageDistributor is ICancellableCoverageDemand {
  /// @notice Add demand for coverage
  /// @dev can only be called by an accepted insured pool
  /// @param unitCount Number of *units* of coverage demand to add
  /// @param premiumRate The rate paid on the coverage
  /// @param hasMore Whether the insured has more demand it would like to request after this
  /// @return addedCount Number of units of demand that were actually added
  function addCoverageDemand(
    uint256 unitCount,
    uint256 premiumRate,
    bool hasMore,
    uint256 loopLimit
  ) external returns (uint256 addedCount);

  ///@notice Get the amount of coverage demanded and filled, and the total premium rate and premium charged
  ///@param insured The insured pool
  ///@return availableCoverage The amount coverage in terms of $CC
  ///@return coverage All the details relating to the coverage, demand and premium
  function receivableDemandedCoverage(address insured, uint256 loopLimit)
    external
    view
    returns (uint256 availableCoverage, DemandedCoverage memory coverage);

  /// @notice Transfer the amount of coverage that been filled to the insured since last called
  /// @dev Only should be called when charteredDemand is true
  /// @dev No use in calling this after coverage demand is fully fulfilled
  /// @param insured The insured to be updated
  /// @return receivedCoverage amount of coverage the Insured received
  /// @return receivedCollateral amount of collateral sent to the Insured
  /// @return coverage Up to date information for this insured
  function receiveDemandedCoverage(address insured, uint256 loopLimit)
    external
    returns (
      uint256 receivedCoverage,
      uint256 receivedCollateral,
      DemandedCoverage memory
    );
}

struct DemandedCoverage {
  uint256 totalDemand; // total demand added to insurer
  uint256 totalCovered; // total coverage allocated by insurer (can not exceed total demand)
  uint256 pendingCovered; // coverage that is allocated, but can not be given yet (should reach unit size)
  uint256 premiumRate; // total premium rate accumulated accross all units filled-in with coverage
  uint256 totalPremium; // time-cumulated of premiumRate
  uint32 premiumUpdatedAt;
  uint32 premiumRateUpdatedAt;
}

struct TotalCoverage {
  uint256 totalCoverable; // total demand that can be covered now (already balanced) - this value is not provided per-insured
  uint88 usableRounds;
  uint88 openRounds;
  uint64 batchCount;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface ICharterable {
  /// @dev indicates how the demand from insured pools is handled:
  /// * Chartered demand will be allocated without calling IInsuredPool, coverage units can be partially filled in.
  /// * Non-chartered (potential) demand can only be allocated after calling IInsuredPool.tryAddCoverage first, units can only be allocated in full.
  function charteredDemand() external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../interfaces/IJoinHandler.sol';
import './IApprovalCatalog.sol';

interface IInsurerGovernor is IJoinHandler {
  function governerQueryAccessControlMask(address subject, uint256 filterMask) external view returns (uint256);

  function verifyPayoutRatio(address insured, uint256 payoutRatio) external returns (uint256);

  function getApprovedPolicyForInsurer(address insured) external returns (bool ok, IApprovalCatalog.ApprovedPolicyForInsurer memory data);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/Errors.sol';
import '../interfaces/IProxyFactory.sol';
import '../funds/Collateralized.sol';
import '../access/AccessHelper.sol';
import './interfaces/IApprovalCatalog.sol';

abstract contract GovernedHelper is AccessHelper, Collateralized {
  constructor(IAccessController acl, address collateral_) AccessHelper(acl) Collateralized(collateral_) {}

  function _onlyGovernorOr(uint256 flags) internal view {
    Access.require(_isAllowed(flags) || hasAnyAcl(msg.sender, flags));
  }

  function _onlyGovernor() private view {
    Access.require(governorAccount() == msg.sender);
  }

  function _isAllowed(uint256 flags) private view returns (bool) {
    return governorAccount() == msg.sender || isAllowedByGovernor(msg.sender, flags);
  }

  function isAllowedByGovernor(address account, uint256 flags) internal view virtual returns (bool) {}

  modifier onlyGovernorOr(uint256 flags) {
    _onlyGovernorOr(flags);
    _;
  }

  modifier onlyGovernor() {
    _onlyGovernor();
    _;
  }

  function _onlySelf() private view {
    Access.require(msg.sender == address(this));
  }

  modifier onlySelf() {
    _onlySelf();
    _;
  }

  function governorAccount() internal view virtual returns (address);

  function approvalCatalog() internal view returns (IApprovalCatalog) {
    return IApprovalCatalog(getAclAddress(AccessFlags.APPROVAL_CATALOG));
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/Address.sol';
import '../tools/Errors.sol';
import '../interfaces/IJoinable.sol';
import '../interfaces/IInsuredPool.sol';
import '../insurer/Rounds.sol';

import 'hardhat/console.sol';

/// @title InsurerJoinBase
/// @notice Handles Insured's requests on joining this Insurer
abstract contract InsurerJoinBase is IJoinEvents {
  function internalGetStatus(address) internal view virtual returns (MemberStatus);

  function internalSetStatus(address, MemberStatus) internal virtual;

  function internalIsInvestor(address) internal view virtual returns (bool);

  function internalRequestJoin(address insured) internal virtual returns (MemberStatus status) {
    require(Address.isContract(insured));
    if ((status = internalGetStatus(insured)) >= MemberStatus.Joining) {
      return status;
    }
    if (status == MemberStatus.Unknown) {
      require(!internalIsInvestor(insured));
    }
    internalSetStatus(insured, MemberStatus.Joining);
    emit JoinRequested(insured);

    if ((status = internalInitiateJoin(insured)) != MemberStatus.Joining) {
      status = _updateInsuredStatus(insured, status);
    }
  }

  function internalCancelJoin(address insured) internal returns (MemberStatus status) {
    if ((status = internalGetStatus(insured)) == MemberStatus.Joining) {
      status = MemberStatus.JoinCancelled;
      internalSetStatus(insured, status);
      emit JoinCancelled(insured);
    }
  }

  function _updateInsuredStatus(address insured, MemberStatus status) private returns (MemberStatus) {
    require(status > MemberStatus.Unknown);

    MemberStatus currentStatus = internalGetStatus(insured);
    if (currentStatus == MemberStatus.Joining) {
      bool accepted;
      if (status == MemberStatus.Accepted) {
        if (internalPrepareJoin(insured)) {
          accepted = true;
        } else {
          status = MemberStatus.JoinRejected;
        }
      } else if (status != MemberStatus.Banned) {
        status = MemberStatus.JoinRejected;
      }
      internalSetStatus(insured, status);

      bool isPanic;
      bytes memory errReason;

      try IInsuredPool(insured).joinProcessed(accepted) {
        emit JoinProcessed(insured, accepted);

        status = internalGetStatus(insured);
        if (accepted && status == MemberStatus.Accepted) {
          internalAfterJoinOrLeave(insured, status);
        }
        return status;
      } catch Error(string memory reason) {
        errReason = bytes(reason);
      } catch (bytes memory reason) {
        isPanic = true;
        errReason = reason;
      }
      emit JoinFailed(insured, isPanic, errReason);
      status = MemberStatus.JoinFailed;
    } else {
      if (status == MemberStatus.Declined) {
        require(currentStatus != MemberStatus.Banned);
      }
      if (currentStatus == MemberStatus.Accepted && status != MemberStatus.Accepted) {
        internalAfterJoinOrLeave(insured, status);
      }
    }

    internalSetStatus(insured, status);
    return status;
  }

  function internalAfterJoinOrLeave(address insured, MemberStatus status) internal virtual {}

  function internalProcessJoin(address insured, bool accepted) internal virtual {
    _updateInsuredStatus(insured, accepted ? MemberStatus.Accepted : MemberStatus.JoinRejected);
  }

  function internalPrepareJoin(address) internal virtual returns (bool);

  function internalInitiateJoin(address) internal virtual returns (MemberStatus);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../insurer/Rounds.sol';

interface IJoinHandler {
  function handleJoinRequest(address) external returns (MemberStatus);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IApprovalCatalog {
  struct ApprovedPolicy {
    bytes32 requestCid;
    bytes32 approvalCid;
    address insured;
    uint16 riskLevel;
    uint80 basePremiumRate;
    string policyName;
    string policySymbol;
    address premiumToken;
    uint96 minPrepayValue;
    uint32 rollingAdvanceWindow;
    uint32 expiresAt;
    bool applied;
  }

  struct ApprovedPolicyForInsurer {
    uint16 riskLevel;
    uint80 basePremiumRate;
    address premiumToken;
  }

  function hasApprovedApplication(address insured) external view returns (bool);

  function getApprovedApplication(address insured) external view returns (ApprovedPolicy memory);

  function applyApprovedApplication() external returns (ApprovedPolicy memory);

  function getAppliedApplicationForInsurer(address insured) external view returns (bool valid, ApprovedPolicyForInsurer memory data);

  struct ApprovedClaim {
    bytes32 requestCid;
    bytes32 approvalCid;
    uint16 payoutRatio;
    uint32 since;
  }

  function hasApprovedClaim(address insured) external view returns (bool);

  function getApprovedClaim(address insured) external view returns (ApprovedClaim memory);

  function applyApprovedClaim(address insured) external returns (ApprovedClaim memory);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './ICharterable.sol';

interface IJoinableBase {
  /// @dev initiates evaluation of the insured pool by this insurer. May involve governance activities etc.
  /// IInsuredPool.joinProcessed will be called after the decision is made.
  function requestJoin(address insured) external;

  // function statusOf(address insured)
}

interface IJoinable is ICharterable, IJoinableBase {}

interface IJoinEvents {
  event JoinRequested(address indexed insured);
  event JoinCancelled(address indexed insured);
  event JoinProcessed(address indexed insured, bool accepted);
  event JoinFailed(address indexed insured, bool isPanic, bytes reason);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/upgradeability/VersionedInitializable.sol';
import './ApprovalCatalog.sol';
import './ProxyTypes.sol';

contract ApprovalCatalogV1 is VersionedInitializable, ApprovalCatalog {
  uint256 private constant CONTRACT_REVISION = 1;

  constructor(IAccessController acl) ApprovalCatalog(acl, ProxyTypes.INSURED_POOL) {}

  function initializeApprovalCatalog() public initializer(CONTRACT_REVISION) {
    _initializeDomainSeparator();
  }

  function getRevision() internal pure override returns (uint256) {
    return CONTRACT_REVISION;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/Address.sol';
import '../tools/Errors.sol';
import '../tools/upgradeability/TransparentProxy.sol';
import '../tools/upgradeability/ProxyAdminBase.sol';
import '../tools/upgradeability/IProxy.sol';
import '../tools/upgradeability/IVersioned.sol';
import '../tools/EIP712Lib.sol';
import '../access/interfaces/IAccessController.sol';
import '../access/AccessHelper.sol';
import '../access/AccessFlags.sol';
import './interfaces/IApprovalCatalog.sol';
import './interfaces/IClaimAccessValidator.sol';
import './ProxyTypes.sol';

contract ApprovalCatalog is IApprovalCatalog, AccessHelper {
  // solhint-disable-next-line var-name-mixedcase
  bytes32 public DOMAIN_SEPARATOR;
  bytes32 private immutable _insuredProxyType;

  constructor(IAccessController acl, bytes32 insuredProxyType) AccessHelper(acl) {
    _insuredProxyType = insuredProxyType;
    _initializeDomainSeparator();
  }

  mapping(address => uint256) private _nonces;

  /// @dev returns nonce, to comply with eip-2612
  function nonces(address addr) external view returns (uint256) {
    return _nonces[addr];
  }

  function _initializeDomainSeparator() internal {
    DOMAIN_SEPARATOR = EIP712Lib.domainSeparator('ApprovalCatalog');
  }

  // solhint-disable-next-line func-name-mixedcase
  function EIP712_REVISION() external pure returns (bytes memory) {
    return EIP712Lib.EIP712_REVISION;
  }

  struct RequestedPolicy {
    bytes32 cid;
    address requestedBy;
  }

  mapping(address => RequestedPolicy) private _requestedPolicies;
  mapping(address => ApprovedPolicy) private _approvedPolicies;

  event ApplicationSubmitted(address indexed insured, bytes32 indexed requestCid);

  function submitApplication(bytes32 cid, address collateral) external returns (address insured) {
    Value.require(collateral != address(0));
    insured = _createInsured(msg.sender, address(0), collateral);
    _submitApplication(insured, cid);
  }

  function submitApplicationWithImpl(bytes32 cid, address impl) external returns (address insured) {
    Value.require(impl != address(0));
    insured = _createInsured(msg.sender, impl, address(0));
    _submitApplication(insured, cid);
  }

  function _submitApplication(address insured, bytes32 cid) private {
    Value.require(cid != 0);
    _requestedPolicies[insured] = RequestedPolicy({cid: cid, requestedBy: msg.sender});
    emit ApplicationSubmitted(insured, cid);
  }

  function _createInsured(
    address requestedBy,
    address impl,
    address collateral
  ) private returns (address) {
    IProxyFactory pf = getProxyFactory();
    bytes memory callData = ProxyTypes.insuredInit(requestedBy);
    if (impl == address(0)) {
      return pf.createProxy(requestedBy, _insuredProxyType, collateral, callData);
    }
    return pf.createProxyWithImpl(requestedBy, _insuredProxyType, impl, callData);
  }

  function resubmitApplication(address insured, bytes32 cid) external {
    State.require(!hasApprovedApplication(insured));

    _submitApplication(insured, cid);
  }

  function hasApprovedApplication(address insured) public view returns (bool) {
    return insured != address(0) && _approvedPolicies[insured].insured == insured;
  }

  function getApprovedApplication(address insured) external view returns (ApprovedPolicy memory) {
    State.require(hasApprovedApplication(insured));
    return _approvedPolicies[insured];
  }

  event ApplicationApplied(address indexed insured, bytes32 indexed requestCid);

  function applyApprovedApplication() external returns (ApprovedPolicy memory data) {
    address insured = msg.sender;
    State.require(hasApprovedApplication(insured));
    data = _approvedPolicies[insured];
    _approvedPolicies[insured].applied = true;

    emit ApplicationApplied(insured, data.requestCid);
  }

  function getAppliedApplicationForInsurer(address insured) external view returns (bool valid, ApprovedPolicyForInsurer memory data) {
    ApprovedPolicy storage policy = _approvedPolicies[insured];
    if (policy.insured == insured && policy.applied) {
      data = ApprovedPolicyForInsurer({riskLevel: policy.riskLevel, basePremiumRate: policy.basePremiumRate, premiumToken: policy.premiumToken});
      valid = true;
    }
  }

  event ApplicationApproved(address indexed approver, address indexed insured, bytes32 indexed requestCid, ApprovedPolicy data);

  function approveApplication(ApprovedPolicy calldata data) external {
    _onlyUnderwriterOfPolicy(msg.sender);

    _approveApplication(msg.sender, data);
  }

  bytes32 public constant APPROVE_APPL_TYPEHASH =
    keccak256(
      // solhint-disable-next-line max-line-length
      'approveApplicationByPermit(address approver,T1 data,uint256 nonce,uint256 expiry)T1(bytes32 requestCid,bytes32 approvalCid,address insured,uint16 riskLevel,uint80 basePremiumRate,string policyName,string policySymbol,address premiumToken,uint96 minPrepayValue,uint32 rollingAdvanceWindow,uint32 expiresAt,bool applied)'
    );
  bytes32 private constant APPROVE_APPL_DATA_TYPEHASH =
    keccak256(
      // solhint-disable-next-line max-line-length
      'T1(bytes32 requestCid,bytes32 approvalCid,address insured,uint16 riskLevel,uint80 basePremiumRate,string policyName,string policySymbol,address premiumToken,uint96 minPrepayValue,uint32 rollingAdvanceWindow,uint32 expiresAt,bool applied)'
    );

  function approveApplicationByPermit(
    address approver,
    ApprovedPolicy calldata data,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    _onlyUnderwriterOfPolicy(approver);

    uint256 nonce = _nonces[data.insured]++;
    EIP712Lib.verifyCustomPermit(
      approver,
      abi.encode(APPROVE_APPL_TYPEHASH, approver, _encodeApplicationPermit(data), nonce, deadline),
      deadline,
      v,
      r,
      s,
      DOMAIN_SEPARATOR
    );

    _approveApplication(approver, data);
  }

  function _encodeApplicationPermit(ApprovedPolicy calldata data) private pure returns (bytes32) {
    // NB! There is no problem for usual compilation, BUT during coverage
    // And this chunked encoding is a workaround for "stack too deep" during coverage.

    bytes memory prefix = abi.encode(
      APPROVE_APPL_DATA_TYPEHASH,
      data.requestCid,
      data.approvalCid,
      data.insured,
      data.riskLevel,
      data.basePremiumRate
    );

    return
      keccak256(
        abi.encodePacked(
          prefix,
          _encodeString(data.policyName),
          _encodeString(data.policySymbol),
          abi.encode(data.premiumToken, data.minPrepayValue, data.rollingAdvanceWindow, data.expiresAt, data.applied)
        )
      );
  }

  function _encodeString(string calldata data) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(data));
  }

  function _onlyUnderwriterOfPolicy(address approver) private view {
    Access.require(hasAnyAcl(approver, AccessFlags.UNDERWRITER_POLICY));
  }

  function _approveApplication(address approver, ApprovedPolicy calldata data) private {
    Value.require(data.insured != address(0));
    Value.require(data.requestCid != 0);
    Value.require(!data.applied);
    State.require(!hasApprovedApplication(data.insured));
    _approvedPolicies[data.insured] = data;
    emit ApplicationApproved(approver, data.insured, data.requestCid, data);
  }

  event ApplicationDeclined(address indexed insured, bytes32 indexed cid, string reason);

  function declineApplication(
    address insured,
    bytes32 cid,
    string calldata reason
  ) external {
    _onlyUnderwriterOfPolicy(msg.sender);

    Value.require(insured != address(0));
    ApprovedPolicy storage data = _approvedPolicies[insured];
    if (data.insured != address(0)) {
      assert(data.insured == insured);
      if (data.requestCid == cid) {
        // decline of the previously approved one is only possible when is was not applied
        State.require(!data.applied);
        delete _approvedPolicies[insured];
      }
    }
    emit ApplicationDeclined(insured, cid, reason);
  }

  struct RequestedClaim {
    bytes32 cid; // supporting documents
    address requestedBy;
    uint256 payoutValue;
  }

  mapping(address => RequestedClaim[]) private _requestedClaims;
  mapping(address => ApprovedClaim) private _approvedClaims;

  event ClaimSubmitted(address indexed insured, bytes32 indexed cid, uint256 payoutValue);

  function submitClaim(
    address insured,
    bytes32 cid,
    uint256 payoutValue
  ) external returns (uint256) {
    Access.require(insured != address(0) && IClaimAccessValidator(insured).canClaimInsurance(msg.sender));
    Value.require(cid != 0);
    State.require(!hasApprovedClaim(insured));

    RequestedClaim[] storage claims = _requestedClaims[insured];
    claims.push(RequestedClaim({cid: cid, requestedBy: msg.sender, payoutValue: payoutValue}));

    emit ClaimSubmitted(insured, cid, payoutValue);

    return claims.length;
  }

  function hasApprovedClaim(address insured) public view returns (bool) {
    return _approvedClaims[insured].requestCid != 0;
  }

  function getApprovedClaim(address insured) public view returns (ApprovedClaim memory) {
    State.require(hasApprovedClaim(insured));
    return _approvedClaims[insured];
  }

  event ClaimApproved(address indexed approver, address indexed insured, bytes32 indexed requestCid, ApprovedClaim data);

  function approveClaim(address insured, ApprovedClaim calldata data) external {
    _onlyUnderwriterClaim(msg.sender);
    _approveClaim(msg.sender, insured, data);
  }

  bytes32 public constant APPROVE_CLAIM_TYPEHASH =
    keccak256(
      // solhint-disable-next-line max-line-length
      'approveClaimByPermit(address approver,address insured,T1 data,uint256 nonce,uint256 expiry)T1(bytes32 requestCid,bytes32 approvalCid,uint16 payoutRatio,uint32 since)'
    );
  bytes32 private constant APPROVE_CLAIM_DATA_TYPEHASH = keccak256('T1(bytes32 requestCid,bytes32 approvalCid,uint16 payoutRatio,uint32 since)');

  function _encodeClaimPermit(ApprovedClaim calldata data) private pure returns (bytes32) {
    return keccak256(abi.encode(APPROVE_CLAIM_DATA_TYPEHASH, data));
  }

  function approveClaimByPermit(
    address approver,
    address insured,
    ApprovedClaim calldata data,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    _onlyUnderwriterClaim(approver);
    uint256 nonce = _nonces[insured]++;
    EIP712Lib.verifyCustomPermit(
      approver,
      abi.encode(APPROVE_CLAIM_TYPEHASH, approver, insured, _encodeClaimPermit(data), nonce, deadline),
      deadline,
      v,
      r,
      s,
      DOMAIN_SEPARATOR
    );
    _approveClaim(approver, insured, data);
  }

  function _onlyUnderwriterClaim(address approver) private view {
    Access.require(hasAnyAcl(approver, AccessFlags.UNDERWRITER_CLAIM));
  }

  function _approveClaim(
    address approver,
    address insured,
    ApprovedClaim calldata data
  ) private {
    Value.require(insured != address(0));
    Value.require(data.requestCid != 0);
    State.require(!hasApprovedClaim(insured));
    _approvedClaims[insured] = data;
    emit ClaimApproved(approver, insured, data.requestCid, data);
  }

  event ClaimApplied(address indexed insured, bytes32 indexed requestCid, ApprovedClaim data);

  function applyApprovedClaim(address insured) external returns (ApprovedClaim memory data) {
    data = getApprovedClaim(insured);
    emit ClaimApplied(insured, data.requestCid, data);
  }

  function cancelLastPermit(address insured)
    external
    aclHasAny(AccessFlags.UNDERWRITER_CLAIM | AccessFlags.UNDERWRITER_POLICY | AccessFlags.INSURED_ADMIN)
  {
    Value.require(insured != address(0));
    _nonces[insured]++;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './IProxy.sol';

abstract contract ProxyAdminBase {
  /// @dev Returns the current implementation of an owned `proxy`.
  function _getProxyImplementation(IProxy proxy) internal view returns (address) {
    // We need to manually run the static call since the getter cannot be flagged as view
    // bytes4(keccak256('implementation()')) == 0x5c60da1b
    (bool success, bytes memory returndata) = address(proxy).staticcall(hex'5c60da1b');
    require(success);
    return abi.decode(returndata, (address));
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IClaimAccessValidator {
  function canClaimInsurance(address) external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/math/WadRayMath.sol';
import '../tools/math/Math.sol';
import '../governance/interfaces/IClaimAccessValidator.sol';
import '../interfaces/IPremiumActuary.sol';
import './InsuredBalancesBase.sol';
import './InsuredJoinBase.sol';
import './PremiumCollectorBase.sol';
import './InsuredAccessControl.sol';

import 'hardhat/console.sol';

/// @title Insured Pool Base
/// @notice The base pool that tracks how much coverage is requested, provided and paid
/// @dev Reconcilation must be called for the most accurate information
abstract contract InsuredPoolBase is
  IInsuredPool,
  InsuredBalancesBase,
  InsuredJoinBase,
  PremiumCollectorBase,
  IClaimAccessValidator,
  InsuredAccessControl
{
  using WadRayMath for uint256;
  using Math for uint256;

  InsuredParams private _params;
  mapping(address => uint256) private _receivedCollaterals; // [insurer]

  uint8 internal constant DECIMALS = 18;

  constructor(IAccessController acl, address collateral_) ERC20DetailsBase('', '', DECIMALS) InsuredAccessControl(acl, collateral_) {}

  function applyApprovedApplication() external onlyGovernor {
    State.require(!internalHasAppliedApplication());
    _applyApprovedApplication();
  }

  function internalHasAppliedApplication() internal view returns (bool) {
    return premiumToken() != address(0);
  }

  function internalGetApprovedPolicy() internal returns (IApprovalCatalog.ApprovedPolicy memory) {
    return approvalCatalog().applyApprovedApplication();
  }

  function _applyApprovedApplication() private {
    IApprovalCatalog.ApprovedPolicy memory ap = internalGetApprovedPolicy();

    State.require(ap.insured == address(this));
    State.require(ap.expiresAt > block.timestamp);

    _initializeERC20(ap.policyName, ap.policySymbol, DECIMALS);
    _initializePremiumCollector(ap.premiumToken, ap.minPrepayValue, ap.rollingAdvanceWindow);
  }

  function collateral() public view override(ICollateralized, Collateralized, PremiumCollectorBase) returns (address) {
    return Collateralized.collateral();
  }

  event ParamsUpdated(InsuredParams params);

  function internalSetInsuredParams(InsuredParams memory params) internal {
    _params = params;
    emit ParamsUpdated(params);
  }

  /// @inheritdoc IInsuredPool
  function insuredParams() public view override returns (InsuredParams memory) {
    return _params;
  }

  function internalSetServiceAccountStatus(address account, uint16 status) internal override(InsuredBalancesBase, InsuredJoinBase) {
    return InsuredBalancesBase.internalSetServiceAccountStatus(account, status);
  }

  function getAccountStatus(address account) internal view override(InsuredBalancesBase, InsuredJoinBase) returns (uint16) {
    return InsuredBalancesBase.getAccountStatus(account);
  }

  function internalIsAllowedAsHolder(uint16 status) internal view override(InsuredBalancesBase, InsuredJoinBase) returns (bool) {
    return InsuredJoinBase.internalIsAllowedAsHolder(status);
  }

  /// @notice Attempt to join an insurer
  function joinPool(IJoinable pool) external onlyGovernor {
    Value.require(address(pool) != address(0));
    if (!internalHasAppliedApplication()) {
      _applyApprovedApplication();
    }

    State.require(IERC20(premiumToken()).balanceOf(address(this)) >= expectedPrepay(uint32(block.timestamp)));

    internalJoinPool(pool);
  }

  /// @notice Add coverage demand to the desired insurers
  /// @param targets The insurers to add demand to
  /// @param amounts The amount of coverage demand to request
  function pushCoverageDemandTo(ICoverageDistributor[] calldata targets, uint256[] calldata amounts)
    external
    onlyGovernorOr(AccessFlags.INSURED_OPS)
  {
    Value.require(targets.length == amounts.length);
    for (uint256 i = 0; i < targets.length; i++) {
      internalPushCoverageDemandTo(targets[i], amounts[i]);
    }
  }

  function setInsuredParams(InsuredParams calldata params) external onlyGovernorOr(AccessFlags.INSURED_OPS) {
    internalSetInsuredParams(params);
  }

  /// @notice Called when the insurer has process this insured
  /// @param accepted True if this insured was accepted to the pool
  function joinProcessed(bool accepted) external override {
    internalJoinProcessed(msg.sender, accepted);
  }

  /// @notice Reconcile the coverage and premium with chartered insurers
  /// @param startIndex Index to start at
  /// @param count Max amount of insurers to reconcile with, 0 == max
  /// @return receivedCoverage Returns the amount of coverage received
  /// @return receivedCollateral Returns the amount of collateral received (<= receivedCoverage)
  /// @return demandedCoverage Total amount of coverage demanded
  /// @return providedCoverage Total coverage provided (demand satisfied)
  function reconcileWithInsurers(uint256 startIndex, uint256 count)
    external
    onlyGovernorOr(AccessFlags.INSURED_OPS)
    returns (
      uint256 receivedCoverage,
      uint256 receivedCollateral,
      uint256 demandedCoverage,
      uint256 providedCoverage
    )
  {
    return _reconcileWithInsurers(startIndex, count > 0 ? count : type(uint256).max);
  }

  event CoverageReconciled(address indexed insurer, uint256 receivedCoverage, uint256 receivedCollateral);

  /// @dev Go through each insurer and reconcile with them
  /// @dev Does NOT sync the rate
  function _reconcileWithInsurers(uint256 startIndex, uint256 count)
    private
    returns (
      uint256 receivedCoverage,
      uint256 receivedCollateral,
      uint256 demandedCoverage,
      uint256 providedCoverage
    )
  {
    address[] storage insurers = getCharteredInsurers();
    uint256 max = insurers.length;
    unchecked {
      count += startIndex;
    }
    if (count > startIndex && count < max) {
      max = count;
    }

    for (; startIndex < max; startIndex++) {
      address insurer = insurers[startIndex];
      (uint256 cov, uint256 col, DemandedCoverage memory cv) = internalReconcileWithInsurer(ICoverageDistributor(insurer), false);
      emit CoverageReconciled(insurer, cov, col);

      receivedCoverage += cov;
      receivedCollateral += col;
      demandedCoverage += cv.totalDemand;
      providedCoverage += cv.totalCovered;
    }
  }

  /// @dev Get the values if reconciliation were to occur with the desired Insurers
  /// @dev DOES sync the rate (for the view)
  function _reconcileWithInsurersView(uint256 startIndex, uint256 count)
    private
    view
    returns (
      uint256 receivableCoverage,
      uint256 demandedCoverage,
      uint256 providedCoverage,
      uint256 rate,
      uint256 accumulated
    )
  {
    address[] storage insurers = getCharteredInsurers();
    uint256 max = insurers.length;
    unchecked {
      if ((count += startIndex) > startIndex && count < max) {
        max = count;
      }
    }
    Balances.RateAcc memory totals = internalSyncTotals();
    for (; startIndex < max; startIndex++) {
      (uint256 c, DemandedCoverage memory cov, ) = internalReconcileWithInsurerView(ICoverageDistributor(insurers[startIndex]), totals);
      demandedCoverage += cov.totalDemand;
      providedCoverage += cov.totalCovered;
      receivableCoverage += c;
    }
    (rate, accumulated) = (totals.rate, totals.accum);
  }

  /// @notice Get the values if reconciliation were to occur with all insurers
  function receivableByReconcileWithInsurers(uint256 startIndex, uint256 count)
    external
    view
    returns (
      uint256 receivableCoverage,
      uint256 demandedCoverage,
      uint256 providedCoverage,
      uint256 rate,
      uint256 accumulated
    )
  {
    return _reconcileWithInsurersView(startIndex, count > 0 ? count : type(uint256).max);
  }

  event CoverageFullyCancelled(uint256 expectedPayout, uint256 actualPayout, address indexed payoutReceiver);

  /// @notice Cancel coverage and get paid out the coverage amount
  /// @param payoutReceiver The receiver of the collateral currency
  /// @param expectedPayout Amount to get paid out for
  function cancelCoverage(address payoutReceiver, uint256 expectedPayout) external onlyGovernorOr(AccessFlags.INSURED_OPS) {
    internalCancelRates();

    uint256 payoutRatio = super.totalReceivedCollateral();
    if (payoutRatio <= expectedPayout) {
      payoutRatio = WadRayMath.RAY;
    } else if (payoutRatio > 0) {
      payoutRatio = expectedPayout.rayDiv(payoutRatio);
    } else {
      require(expectedPayout == 0);
    }

    uint256 totalPayout = internalCancelInsurers(getCharteredInsurers(), payoutRatio);
    totalPayout += internalCancelInsurers(getGenericInsurers(), payoutRatio);

    // NB! it is possible for totalPayout < expectedPayout when drawdown takes place
    if (totalPayout > 0) {
      require(payoutReceiver != address(0));
      transferCollateral(payoutReceiver, totalPayout);
    }

    emit CoverageFullyCancelled(expectedPayout, totalPayout, payoutReceiver);
  }

  function internalCollateralReceived(address insurer, uint256 amount) internal override {
    super.internalCollateralReceived(insurer, amount);
    _receivedCollaterals[insurer] += amount;
  }

  event CoverageCancelled(address indexed insurer, uint256 payoutRatio, uint256 actualPayout);

  /// @dev Goes through the insurers and cancels with the payout ratio
  /// @param insurers The insurers to cancel with
  /// @param payoutRatio The ratio of coverage to get paid out
  /// @dev e.g payoutRatio = 7e26 means 30% of coverage is sent back to the insurer
  /// @return totalPayout total amount of coverage paid out to this insured
  function internalCancelInsurers(address[] storage insurers, uint256 payoutRatio) private returns (uint256 totalPayout) {
    IERC20 t = IERC20(collateral());

    for (uint256 i = insurers.length; i > 0; ) {
      address insurer = insurers[--i];

      uint256 receivedCollateral = _receivedCollaterals[insurer];
      _receivedCollaterals[insurer] = 0;

      require(t.approve(insurer, receivedCollateral));

      totalPayout += ICancellableCoverage(insurer).cancelCoverage(address(this), payoutRatio);
      emit CoverageCancelled(insurer, payoutRatio, totalPayout);

      internalDecReceivedCollateral(receivedCollateral - t.allowance(address(this), insurer));
      require(t.approve(insurer, 0));
    }
  }

  function internalPriceOf(address asset) internal view virtual override returns (uint256) {
    return getPricer().getAssetPrice(asset);
  }

  function internalPullPriceOf(address asset) internal virtual override returns (uint256) {
    return getPricer().pullAssetPrice(asset, 0);
  }

  function internalExpectedPrepay(uint256 atTimestamp) internal view override returns (uint256) {
    return internalExpectedTotals(uint32(atTimestamp)).accum;
  }

  function collectPremium(
    address actuary,
    address token,
    uint256 amount,
    uint256 value
  ) external override {
    _ensureHolder(actuary);
    Access.require(IPremiumActuary(actuary).premiumDistributor() == msg.sender);
    internalCollectPremium(token, amount, value);
  }

  function internalReservedCollateral() internal view override returns (uint256) {
    return super.totalReceivedCollateral();
  }

  event PrepayWithdrawn(uint256 amount, address indexed recipient);

  function withdrawPrepay(address recipient, uint256 amount) external override onlyGovernor {
    amount = internalWithdrawPrepay(recipient, amount);
    emit PrepayWithdrawn(amount, recipient);
  }

  function governor() public view returns (address) {
    return governorAccount();
  }

  function setGovernor(address addr) external onlyGovernorOr(AccessFlags.INSURED_ADMIN) {
    internalSetGovernor(addr);
  }

  function canClaimInsurance(address claimedBy) public view virtual override returns (bool) {
    return claimedBy == governorAccount();
  }

  event CoverageDemandOffered(address indexed offeredBy, uint256 offeredAmount, uint256 acceptedAmount, uint256 rate);

  /// @inheritdoc IInsuredPool
  function offerCoverage(uint256 offeredAmount) external override returns (uint256 acceptedAmount, uint256 rate) {
    (acceptedAmount, rate) = internalOfferCoverage(msg.sender, offeredAmount);
    emit CoverageDemandOffered(msg.sender, offeredAmount, acceptedAmount, rate);
  }

  function internalOfferCoverage(address account, uint256 offeredAmount) internal virtual returns (uint256 acceptedAmount, uint256 rate);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/Address.sol';
import '../tools/tokens/ERC20BalancelessBase.sol';
import '../libraries/Balances.sol';
import '../interfaces/ICoverageDistributor.sol';
import '../interfaces/IInsuredPool.sol';
import '../tools/math/WadRayMath.sol';
import '../funds/Collateralized.sol';

import 'hardhat/console.sol';

/// @title Insured Balances Base
/// @notice Holds balances of how much Insured owes to each Insurer in terms of rate
/// @dev Calculates retroactive premium paid by Insured to Insurer over-time.
/// @dev Insured pool tokens = investment * premium rate (e.g $1000 @ 5% premium = 50 tokens)
abstract contract InsuredBalancesBase is Collateralized, ERC20BalancelessBase {
  using WadRayMath for uint256;
  using Balances for Balances.RateAcc;
  using Balances for Balances.RateAccWithUint16;

  mapping(address => Balances.RateAccWithUint16) private _balances;
  Balances.RateAcc private _totalAllocatedDemand;

  uint224 private _receivedCollateral;
  uint32 private _cancelledAt;

  function _ensureHolder(uint16 flags) private view {
    Access.require(internalIsAllowedAsHolder(flags));
  }

  function _ensureHolder(address account) internal view {
    _ensureHolder(_balances[account].extra);
  }

  function _beforeMintOrBurn(address account) internal view returns (Balances.RateAccWithUint16 memory b, Balances.RateAcc memory totals) {
    b = _syncBalance(account);
    _ensureHolder(b.extra);
    totals = internalSyncTotals();
  }

  // slither-disable-next-line costly-loop
  function _afterMintOrBurn(
    address account,
    Balances.RateAccWithUint16 memory b,
    Balances.RateAcc memory totals
  ) internal {
    _balances[account] = b;
    _totalAllocatedDemand = totals;
  }

  /// @dev Mint the correct amount of tokens for the account (investor)
  /// @param account Account to mint to
  /// @param rateAmount Amount of rate
  // slither-disable-next-line costly-loop
  function internalMintForDemandedCoverage(address account, uint256 rateAmount) internal {
    Value.require(rateAmount <= type(uint88).max);
    (Balances.RateAccWithUint16 memory b, Balances.RateAcc memory totals) = _beforeMintOrBurn(account);

    b.rate += uint88(rateAmount);
    rateAmount += totals.rate;
    Value.require((totals.rate = uint96(rateAmount)) == rateAmount);

    _afterMintOrBurn(account, b, totals);
    emit Transfer(address(0), address(account), rateAmount);
  }

  function internalBurnForDemandedCoverage(address account, uint256 rateAmount) internal {
    (Balances.RateAccWithUint16 memory b, Balances.RateAcc memory totals) = _beforeMintOrBurn(account);

    b.rate = uint88(b.rate - rateAmount);
    totals.rate = uint96(totals.rate - rateAmount);

    _afterMintOrBurn(account, b, totals);
    emit Transfer(address(account), address(0), rateAmount);
  }

  function transferBalance(
    address sender,
    address recipient,
    uint256 amount
  ) internal override {
    Balances.RateAccWithUint16 memory b = _syncBalance(sender);
    b.rate = uint88(b.rate - amount);
    _balances[sender] = b;

    b = _syncBalance(recipient);
    b.rate += uint88(amount);
    _balances[recipient] = b;
  }

  function internalIsAllowedAsHolder(uint16 status) internal view virtual returns (bool);

  /// @dev Cancel this policy
  function internalCancelRates() internal {
    State.require(_cancelledAt == 0);
    _cancelledAt = uint32(block.timestamp);
  }

  /// @dev Return timestamp or time that the cancelled state occurred
  function _syncTimestamp() private view returns (uint32) {
    uint32 ts = _cancelledAt;
    return ts > 0 ? ts : uint32(block.timestamp);
  }

  /// @dev Update premium paid of entire pool
  function internalExpectedTotals(uint32 at) internal view returns (Balances.RateAcc memory) {
    Value.require(at >= block.timestamp);
    uint32 ts = _cancelledAt;
    return _totalAllocatedDemand.sync(ts > 0 && ts <= at ? ts : at);
  }

  /// @dev Update premium paid of entire pool
  function internalSyncTotals() internal view returns (Balances.RateAcc memory) {
    return _totalAllocatedDemand.sync(_syncTimestamp());
  }

  /// @dev Update premium paid to an account
  function _syncBalance(address account) private view returns (Balances.RateAccWithUint16 memory b) {
    return _balances[account].sync(_syncTimestamp());
  }

  /// @notice Balance of the account, which is the rate paid to it
  /// @param account The account to query
  /// @return Rate paid to this account
  function balanceOf(address account) public view override returns (uint256) {
    return _balances[account].rate;
  }

  /// @notice Balance and total accumulated of the account
  /// @param account The account to query
  /// @return rate The rate paid to this account
  /// @return premium The total premium paid to this account
  function balancesOf(address account) public view returns (uint256 rate, uint256 premium) {
    Balances.RateAccWithUint16 memory b = _syncBalance(account);
    return (b.rate, b.accum);
  }

  /// @notice Total Supply - also the current premium rate
  /// @return The total premium rate
  function totalSupply() public view override returns (uint256) {
    return _totalAllocatedDemand.rate;
  }

  /// @notice Total Premium rate and accumulated
  /// @return rate The current rate paid by the insured
  /// @return accumulated The total amount of premium to be paid for the policy
  function totalPremium() public view returns (uint256 rate, uint256 accumulated) {
    Balances.RateAcc memory totals = internalSyncTotals();
    return (totals.rate, totals.accum);
  }

  function internalSetServiceAccountStatus(address account, uint16 status) internal virtual {
    Value.require(status > 0);
    if (_balances[account].extra == 0) {
      Value.require(Address.isContract(account));
    }
    _balances[account].extra = status;
  }

  function getAccountStatus(address account) internal view virtual returns (uint16) {
    return _balances[account].extra;
  }

  /// @dev Reconcile the amount of collected premium and current premium rate with the Insurer
  /// @param insurer The insurer to reconcile with
  /// @param updateRate Whether the total rate of this Insured pool should be updated
  /// @return receivedCoverage Amount of new coverage provided since the last reconcilation
  /// @return receivedCollateral Amount of collateral currency received during this reconcilation (<= receivedCoverage)
  /// @return coverage The new information on coverage demanded, provided and premium paid
  function internalReconcileWithInsurer(ICoverageDistributor insurer, bool updateRate)
    internal
    returns (
      uint256 receivedCoverage,
      uint256 receivedCollateral,
      DemandedCoverage memory coverage
    )
  {
    Balances.RateAccWithUint16 memory b = _syncBalance(address(insurer));
    _ensureHolder(b.extra);

    (receivedCoverage, receivedCollateral, coverage) = insurer.receiveDemandedCoverage(address(this), 0);
    // console.log('internalReconcileWithInsurer', address(this), coverage.totalPremium, coverage.premiumRate);
    if (receivedCollateral > 0) {
      internalCollateralReceived(address(insurer), receivedCollateral);
    }

    (Balances.RateAcc memory totals, bool updated) = _syncInsurerBalance(b, coverage);

    if (coverage.premiumRate != b.rate && (coverage.premiumRate > b.rate || updateRate)) {
      if (!updated) {
        totals = internalSyncTotals();
        updated = true;
      }
      uint88 prevRate = b.rate;
      Value.require((b.rate = uint88(coverage.premiumRate)) == coverage.premiumRate);
      if (prevRate > b.rate) {
        totals.rate -= prevRate - b.rate;
      } else {
        totals.rate += b.rate - prevRate;
      }
    }

    if (updated) {
      _totalAllocatedDemand = totals;
      _balances[address(insurer)] = b;
    }
  }

  function internalCollateralReceived(address insurer, uint256 amount) internal virtual {
    insurer;
    Value.require((_receivedCollateral += uint224(amount)) >= amount);
  }

  function internalDecReceivedCollateral(uint256 amount) internal virtual {
    _receivedCollateral = uint224(_receivedCollateral - amount);
  }

  function totalReceivedCollateral() public view returns (uint256) {
    return _receivedCollateral;
  }

  function _syncInsurerBalance(Balances.RateAccWithUint16 memory b, DemandedCoverage memory coverage)
    private
    view
    returns (Balances.RateAcc memory totals, bool)
  {
    uint256 diff;
    if (b.accum != coverage.totalPremium) {
      totals = internalSyncTotals();
      if (b.accum < coverage.totalPremium) {
        // technical underpayment
        diff = coverage.totalPremium - b.accum;
        diff += totals.accum;
        Value.require((totals.accum = uint128(diff)) == diff);
      } else {
        totals.accum -= uint128(diff = b.accum - coverage.totalPremium);
      }

      b.accum = uint120(coverage.totalPremium);
    }

    return (totals, diff != 0);
  }

  /// @dev Do the same as `internalReconcileWithInsurer` but only as a view, don't make changes
  function internalReconcileWithInsurerView(ICoverageDistributor insurer, Balances.RateAcc memory totals)
    internal
    view
    returns (
      uint256 receivedCoverage,
      DemandedCoverage memory coverage,
      Balances.RateAccWithUint16 memory b
    )
  {
    b = _syncBalance(address(insurer));
    _ensureHolder(b.extra);

    (receivedCoverage, coverage) = insurer.receivableDemandedCoverage(address(this), 0);
    State.require(b.updatedAt >= coverage.premiumUpdatedAt);

    (totals, ) = _syncInsurerBalance(b, coverage);

    if (coverage.premiumRate != b.rate && (coverage.premiumRate > b.rate)) {
      Value.require((b.rate = uint88(coverage.premiumRate)) == coverage.premiumRate);
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../interfaces/IJoinable.sol';
import './InsuredBalancesBase.sol';

/// @title Insured Join Base
/// @notice Handles tracking and joining insurers
abstract contract InsuredJoinBase is IInsuredPool {
  address[] private _genericInsurers; // ICoverageDistributor[]
  address[] private _charteredInsurers;

  uint16 private constant STATUS_MAX = type(uint16).max;
  uint16 private constant STATUS_NOT_JOINED = STATUS_MAX;
  uint16 private constant STATUS_PENDING = STATUS_MAX - 1;
  uint16 private constant INDEX_MAX = STATUS_MAX - 2;

  function internalJoinPool(IJoinable pool) internal {
    Value.require(address(pool) != address(0));
    uint32 status = getAccountStatus(address(pool));

    State.require(status == 0 || status == STATUS_NOT_JOINED);
    internalSetServiceAccountStatus(address(pool), STATUS_PENDING);

    pool.requestJoin(address(this));
  }

  function getInsurers() public view returns (address[] memory, address[] memory) {
    return (_genericInsurers, _charteredInsurers);
  }

  function getGenericInsurers() internal view returns (address[] storage) {
    return _genericInsurers;
  }

  function getCharteredInsurers() internal view returns (address[] storage) {
    return _charteredInsurers;
  }

  function getDemandOnJoin() internal view virtual returns (uint256) {
    return ~uint256(0);
  }

  ///@dev Add the Insurer pool if accepted, and set the status of it
  function internalJoinProcessed(address insurer, bool accepted) internal {
    Access.require(getAccountStatus(insurer) == STATUS_PENDING);

    if (accepted) {
      bool chartered = IJoinable(insurer).charteredDemand();
      uint256 index = chartered ? (_charteredInsurers.length << 1) + 1 : (_genericInsurers.length + 1) << 1;
      State.require(index < INDEX_MAX);
      (chartered ? _charteredInsurers : _genericInsurers).push(insurer);
      internalSetServiceAccountStatus(insurer, uint16(index));
      _addCoverageDemandTo(ICoverageDistributor(insurer), 0, getDemandOnJoin(), 0);
    } else {
      internalSetServiceAccountStatus(insurer, STATUS_NOT_JOINED);
    }
  }

  /// @inheritdoc IInsuredPool
  function pullCoverageDemand(uint256 amount, uint256 loopLimit) external override returns (bool) {
    uint16 status = getAccountStatus(msg.sender);
    if (status <= INDEX_MAX) {
      Access.require(status > 0);
      return _addCoverageDemandTo(ICoverageDistributor(msg.sender), amount, type(uint256).max, loopLimit);
    }
    return false;
  }

  function internalPushCoverageDemandTo(ICoverageDistributor target, uint256 maxAmount) internal {
    uint16 status = getAccountStatus(address(target));
    Access.require(status > 0 && status <= INDEX_MAX);
    _addCoverageDemandTo(target, 0, maxAmount, 0);
  }

  /// @dev Add coverage demand to the Insurer and
  /// @param target The insurer to add demand to
  /// @param minAmount The desired min amount of demand to add (soft limit)
  /// @param maxAmount The max amount of demand to add (hard limit)
  /// @return True if there is more demand that can be added
  // slither-disable-next-line calls-loop
  function _addCoverageDemandTo(
    ICoverageDistributor target,
    uint256 minAmount,
    uint256 maxAmount,
    uint256 loopLimit
  ) private returns (bool) {
    uint256 unitSize = target.coverageUnitSize();

    (uint256 amount, uint256 premiumRate) = internalAllocateCoverageDemand(address(target), minAmount, maxAmount, unitSize);
    State.require(amount <= maxAmount);

    amount = amount < unitSize ? 0 : target.addCoverageDemand(amount / unitSize, premiumRate, amount % unitSize != 0, loopLimit);
    if (amount == 0) {
      return false;
    }

    internalCoverageDemandAdded(address(target), amount * unitSize, premiumRate);
    return true;
  }

  /// @dev Calculate how much coverage demand to add
  /// @param target The insurer demand is being added to
  /// @param minAmount The desired min amount of demand to add (soft limit)
  /// @param maxAmount The max amount of demand to add (hard limit)
  /// @param unitSize The unit size of the insurer
  /// @return amount Amount of coverage demand to add
  /// @return premiumRate The rate to pay for the coverage to add
  function internalAllocateCoverageDemand(
    address target,
    uint256 minAmount,
    uint256 maxAmount,
    uint256 unitSize
  ) internal virtual returns (uint256 amount, uint256 premiumRate);

  function internalCoverageDemandAdded(
    address target,
    uint256 amount,
    uint256 premiumRate
  ) internal virtual;

  function internalSetServiceAccountStatus(address account, uint16 status) internal virtual;

  function getAccountStatus(address account) internal view virtual returns (uint16);

  function internalIsAllowedAsHolder(uint16 status) internal view virtual returns (bool) {
    return status > 0 && status <= INDEX_MAX;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/Address.sol';
import '../tools/SafeERC20.sol';
import '../tools/Errors.sol';
import '../tools/tokens/IERC20.sol';
import '../interfaces/IPremiumActuary.sol';
import '../interfaces/IPremiumCollector.sol';
import '../interfaces/IPremiumSource.sol';
import '../tools/math/WadRayMath.sol';

import 'hardhat/console.sol';

abstract contract PremiumCollectorBase is IPremiumCollector, IPremiumSource {
  using WadRayMath for uint256;
  using SafeERC20 for IERC20;

  IERC20 private _premiumToken;
  uint256 private _collectedValue;

  uint32 private _rollingAdvanceWindow;
  uint160 private _minPrepayValue;

  function premiumToken() public view override(IPremiumCollector, IPremiumSource) returns (address) {
    return address(_premiumToken);
  }

  function _initializePremiumCollector(
    address token,
    uint160 minPrepayValue,
    uint32 rollingAdvanceWindow
  ) internal {
    Value.require(token != address(0));
    State.require(address(_premiumToken) == address(0));
    _premiumToken = IERC20(token);
    internalSetPrepay(minPrepayValue, rollingAdvanceWindow);
  }

  function internalSetPrepay(uint160 minPrepayValue, uint32 rollingAdvanceWindow) internal {
    _minPrepayValue = minPrepayValue;
    _rollingAdvanceWindow = rollingAdvanceWindow;
  }

  function internalExpectedPrepay(uint256 atTimestamp) internal view virtual returns (uint256);

  function internalPriceOf(address) internal view virtual returns (uint256);

  function internalPullPriceOf(address) internal virtual returns (uint256);

  function _expectedPrepay(uint256 atTimestamp) internal view returns (uint256) {
    uint256 required = internalExpectedPrepay(atTimestamp + _rollingAdvanceWindow);
    uint256 minPrepayValue = _minPrepayValue;
    if (minPrepayValue > required) {
      required = minPrepayValue;
    }

    uint256 collected = _collectedValue;
    return collected >= required ? 0 : required - collected;
  }

  function expectedPrepay(uint256 atTimestamp) public view override returns (uint256) {
    uint256 value = _expectedPrepay(atTimestamp);
    return value == 0 ? 0 : value.wadDiv(internalPriceOf(address(_premiumToken)));
  }

  function expectedPrepayAfter(uint32 timeDelta) external view override returns (uint256 amount) {
    return expectedPrepay(uint32(block.timestamp) + timeDelta);
  }

  function internalWithdrawPrepay(address recipient, uint256 amount) internal returns (uint256) {
    IERC20 token = _premiumToken;

    uint256 balance = token.balanceOf(address(this));
    if (balance > 0) {
      uint256 expected = _expectedPrepay(uint32(block.timestamp));
      if (expected > 0) {
        uint256 price = internalPullPriceOf(address(_premiumToken));
        if (price != 0) {
          expected = expected.wadDiv(price);
          balance = expected >= balance ? 0 : balance - expected;
        } else {
          balance = 0;
        }
      }
    }
    if (amount == type(uint256).max) {
      amount = balance;
    } else {
      Value.require(amount <= balance);
    }

    if (amount > 0) {
      token.safeTransfer(recipient, amount);
    }

    return amount;
  }

  function collateral() public view virtual returns (address);

  function internalReservedCollateral() internal view virtual returns (uint256);

  function internalCollectPremium(
    address token,
    uint256 amount,
    uint256 value
  ) internal {
    uint256 balance = IERC20(token).balanceOf(address(this));

    if (balance > 0) {
      if (token == collateral()) {
        balance -= internalReservedCollateral();
        if (amount > balance) {
          amount = balance;
        }
        value = amount;
      } else {
        Value.require(token == address(_premiumToken));
        if (amount > balance) {
          value = (value * balance) / amount;
          amount = balance;
        }
      }

      if (value > 0) {
        IERC20(token).safeTransfer(msg.sender, amount);
        _collectedValue += value;
      }
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/introspection/ERC165Checker.sol';
import '../tools/math/PercentageMath.sol';
import '../tools/math/WadRayMath.sol';
import '../governance/interfaces/IInsuredGovernor.sol';
import '../governance/GovernedHelper.sol';
import '../pricing/PricingHelper.sol';

abstract contract InsuredAccessControl is GovernedHelper, PricingHelper {
  using PercentageMath for uint256;

  address private _governor;
  bool private _governorIsContract;

  constructor(IAccessController acl, address collateral_) GovernedHelper(acl, collateral_) PricingHelper(_getPricerByAcl(acl)) {}

  function remoteAcl() internal view override(AccessHelper, PricingHelper) returns (IAccessController pricer) {
    return AccessHelper.remoteAcl();
  }

  function internalSetTypedGovernor(IInsuredGovernor addr) internal {
    _governorIsContract = true;
    _setGovernor(address(addr));
  }

  function internalSetGovernor(address addr) internal virtual {
    // will also return false for EOA
    _governorIsContract = ERC165Checker.supportsInterface(addr, type(IInsuredGovernor).interfaceId);
    _setGovernor(addr);
  }

  function governorContract() internal view virtual returns (IInsuredGovernor) {
    return IInsuredGovernor(_governorIsContract ? governorAccount() : address(0));
  }

  function isAllowedByGovernor(address account, uint256 flags) internal view override returns (bool) {
    return _governorIsContract && IInsuredGovernor(governorAccount()).governerQueryAccessControlMask(account, flags) & flags != 0;
  }

  event GovernorUpdated(address);

  function _setGovernor(address addr) internal {
    emit GovernorUpdated(_governor = addr);
  }

  function governorAccount() internal view override returns (address) {
    return _governor;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './ICollateralized.sol';

interface IPremiumCollector {
  /// @return The token of premium
  function premiumToken() external view returns (address);

  function expectedPrepay(uint256 atTimestamp) external view returns (uint256); // amount or value?

  function expectedPrepayAfter(uint32 timeDelta) external view returns (uint256);

  function withdrawPrepay(address recipient, uint256 amount) external; // amount or value?
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './IApprovalCatalog.sol';

interface IInsuredGovernor {
  function governerQueryAccessControlMask(address subject, uint256 filterMask) external view returns (uint256);

  // function getApprovedPolicyForInsurer(address insured) external returns (bool ok, IApprovalCatalog.ApprovedPolicyForInsurer memory data);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './IProxy.sol';
import './ProxyAdminBase.sol';
import '../Errors.sol';

/// @dev This contract meant to be assigned as the admin of a {IProxy}. Adopted from the OpenZeppelin
contract ProxyAdmin is ProxyAdminBase {
  address private immutable _owner;

  constructor() {
    _owner = msg.sender;
  }

  /// @dev Returns the address of the current owner.
  function owner() public view returns (address) {
    return _owner;
  }

  function _onlyOwner() private view {
    if (_owner != msg.sender) {
      revert Errors.CallerNotProxyOwner();
    }
  }

  /// @dev Throws if called by any account other than the owner.
  modifier onlyOwner() {
    _onlyOwner();
    _;
  }

  /// @dev Returns the current implementation of `proxy`.
  function getProxyImplementation(IProxy proxy) public view virtual returns (address) {
    return _getProxyImplementation(proxy);
  }

  /// @dev Upgrades `proxy` to `implementation` and calls a function on the new implementation.
  function upgradeAndCall(
    IProxy proxy,
    address implementation,
    bytes memory data
  ) public payable virtual onlyOwner {
    proxy.upgradeToAndCall{value: msg.value}(implementation, data);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/Address.sol';
import '../tools/Errors.sol';
import '../tools/upgradeability/TransparentProxy.sol';
import '../tools/upgradeability/ProxyAdminBase.sol';
import '../tools/upgradeability/IProxy.sol';
import '../tools/upgradeability/IVersioned.sol';
import '../access/interfaces/IAccessController.sol';
import '../access/AccessHelper.sol';
import '../libraries/Strings.sol';
import './interfaces/IProxyCatalog.sol';

contract ProxyCatalog is IManagedProxyCatalog, ProxyAdminBase, AccessHelper {
  mapping(address => address) private _proxyOwners; // [proxy]

  mapping(address => mapping(bytes32 => address)) private _defaultImpls; // [ctx][name]
  mapping(address => bytes32) private _authImpls; // [impl]
  mapping(address => bytes32) private _revokedImpls; // [impl]
  mapping(address => address) private _contexts; // [impl]
  mapping(bytes32 => uint256) private _accessRoles;

  constructor(IAccessController acl) AccessHelper(acl) {}

  function getImplementationType(address impl) public view override returns (bytes32 name, address ctx) {
    name = _authImpls[impl];
    if (name == 0) {
      name = _revokedImpls[impl];
    }
    ctx = _contexts[impl];
  }

  function isAuthenticImplementation(address impl) public view override returns (bool) {
    return impl != address(0) && _authImpls[impl] != 0;
  }

  function isAuthenticProxy(address proxy) public view override returns (bool) {
    return getProxyOwner(proxy) != address(0) && isAuthenticImplementation(getProxyImplementation(proxy));
  }

  function getDefaultImplementation(bytes32 name, address ctx) public view override returns (address addr) {
    State.require((addr = _defaultImpls[ctx][name]) != address(0));
  }

  function addAuthenticImplementation(
    address impl,
    bytes32 name,
    address ctx
  ) public onlyAdmin {
    Value.require(name != 0);
    Value.require(impl != address(0));
    bytes32 implName = _authImpls[impl];
    if (implName != name) {
      State.require(implName == 0);
      _authImpls[impl] = name;
      _contexts[impl] = ctx;
      emit ImplementationAdded(name, ctx, impl);
    } else {
      State.require(ctx == _contexts[impl]);
    }
  }

  function removeAuthenticImplementation(address impl, address defReplacement) public onlyAdmin {
    bytes32 name = _authImpls[impl];
    if (name != 0) {
      delete _authImpls[impl];
      _revokedImpls[impl] = name;
      address ctx = _contexts[impl];
      emit ImplementationRemoved(name, ctx, impl);

      if (_defaultImpls[ctx][name] == impl) {
        if (defReplacement == address(0)) {
          delete _defaultImpls[ctx][name];
          emit DefaultImplementationUpdated(name, ctx, address(0));
        } else {
          Value.require(_authImpls[defReplacement] == name && _contexts[defReplacement] == ctx);
          _setDefaultImplementation(defReplacement, name, ctx, false);
        }
      }
    }
  }

  function unsetDefaultImplementation(address impl) public onlyAdmin {
    bytes32 name = _authImpls[impl];
    address ctx = _contexts[impl];
    if (_defaultImpls[ctx][name] == impl) {
      delete _defaultImpls[ctx][name];
      emit DefaultImplementationUpdated(name, ctx, address(0));
    }
  }

  function setDefaultImplementation(address impl) public onlyAdmin {
    bytes32 name = _authImpls[impl];
    State.require(name != 0);
    _setDefaultImplementation(impl, name, _contexts[impl], true);
  }

  function _ensureNewRevision(address prevImpl, address newImpl) internal view {
    require(IVersioned(newImpl).REVISION() > (prevImpl == address(0) ? 0 : IVersioned(prevImpl).REVISION()));
  }

  function _setDefaultImplementation(
    address impl,
    bytes32 name,
    address ctx,
    bool checkRevision
  ) private {
    if (checkRevision) {
      _ensureNewRevision(_defaultImpls[ctx][name], impl);
    }
    _defaultImpls[ctx][name] = impl;
    emit DefaultImplementationUpdated(name, ctx, impl);
  }

  function getProxyOwner(address proxy) public view returns (address) {
    return _proxyOwners[proxy];
  }

  /// @dev Returns the current implementation of `proxy`.
  function getProxyImplementation(address proxy) public view returns (address) {
    return _getProxyImplementation(IProxy(proxy));
  }

  function _updateImpl(
    address proxyAddress,
    address newImpl,
    bytes memory params,
    bytes32 name
  ) private {
    TransparentProxy(payable(proxyAddress)).upgradeToAndCall(newImpl, params);
    emit ProxyUpdated(proxyAddress, newImpl, Strings.asString(name), params);
  }

  function _createCustomProxy(
    address adminAddress,
    address implAddress,
    bytes memory params,
    bytes32 name
  ) private returns (TransparentProxy proxy) {
    proxy = new TransparentProxy(adminAddress, implAddress, params);
    emit ProxyCreated(address(proxy), implAddress, Strings.asString(name), params, adminAddress);
  }

  function createCustomProxy(
    address adminAddress,
    address implAddress,
    bytes calldata params
  ) external returns (IProxy) {
    Value.require(adminAddress != address(this));
    return _createCustomProxy(adminAddress, implAddress, params, '');
  }

  function _createProxy(
    address adminAddress,
    address implAddress,
    bytes memory params,
    bytes32 name
  ) private returns (TransparentProxy) {
    TransparentProxy proxy = _createCustomProxy(address(this), implAddress, params, name);
    _proxyOwners[address(proxy)] = adminAddress == address(0) ? address(this) : adminAddress;
    return proxy;
  }

  function getAccess(bytes32[] calldata implNames) external view returns (uint256[] memory results) {
    results = new uint256[](implNames.length);
    for (uint256 i = implNames.length; i > 0; ) {
      i--;
      results[i] = _accessRoles[implNames[i]];
    }
  }

  function setAccess(bytes32[] calldata implNames, uint256[] calldata accessFlags) external onlyAdmin {
    Value.require(implNames.length == accessFlags.length || accessFlags.length == 1);
    for (uint256 i = implNames.length; i > 0; ) {
      i--;
      _accessRoles[implNames[i]] = i < accessFlags.length ? accessFlags[i] : accessFlags[0];
    }
  }

  function _onlyAccessibleImpl(bytes32 implName) private view {
    uint256 flags = _accessRoles[implName];
    if (flags != type(uint256).max) {
      // restricted access
      Access.require(flags == 0 ? isAdmin(msg.sender) : hasAnyAcl(msg.sender, flags));
    }
  }

  modifier onlyAccessibleImpl(bytes32 implName) {
    _onlyAccessibleImpl(implName);
    _;
  }

  function createProxy(
    address adminAddress,
    bytes32 implName,
    address ctx,
    bytes memory params
  ) external override onlyAccessibleImpl(implName) returns (address) {
    return address(_createProxy(adminAddress, getDefaultImplementation(implName, ctx), params, implName));
  }

  function createProxyWithImpl(
    address adminAddress,
    bytes32 implName,
    address impl,
    bytes calldata params
  ) external override onlyAccessibleImpl(implName) returns (address) {
    State.require(implName != 0 && implName == _authImpls[impl]);
    return address(_createProxy(adminAddress, impl, params, implName));
  }

  function _onlyAdminOrProxyOwner(address proxyAddress) private view {
    Access.require(getProxyOwner(proxyAddress) == msg.sender || isAdmin(msg.sender));
  }

  modifier onlyAdminOrProxyOwner(address proxyAddress) {
    _onlyAdminOrProxyOwner(proxyAddress);
    _;
  }

  function upgradeProxy(address proxyAddress, bytes calldata params) external override onlyAdminOrProxyOwner(proxyAddress) returns (bool) {
    address prevImpl = getProxyImplementation(proxyAddress);
    (bytes32 name, address ctx) = getImplementationType(prevImpl);
    address newImpl = getDefaultImplementation(name, ctx);
    if (prevImpl != newImpl) {
      _ensureNewRevision(prevImpl, newImpl);
      _updateImpl(proxyAddress, newImpl, params, name);
      return true;
    }
    return false;
  }

  function upgradeProxyWithImpl(
    address proxyAddress,
    address newImpl,
    bool checkRevision,
    bytes calldata params
  ) external override onlyAdmin returns (bool) {
    address prevImpl = getProxyImplementation(proxyAddress);
    if (prevImpl != newImpl) {
      (bytes32 name, address ctx) = getImplementationType(prevImpl);
      (bytes32 name2, address ctx2) = getImplementationType(newImpl);
      Value.require(ctx == ctx2);
      if (name != 0 || checkRevision) {
        Value.require(name == name2 || name == 0 || (!checkRevision && name2 == 0));
      }

      if (checkRevision) {
        _ensureNewRevision(prevImpl, newImpl);
      }

      _updateImpl(proxyAddress, newImpl, params, name2);
      return true;
    }
    return false;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

library Strings {
  function trimRight(bytes memory s) internal pure returns (bytes memory) {
    uint256 i = s.length;
    for (; i > 0; i--) {
      if (s[i - 1] > 0x20) {
        break;
      }
    }
    // solhint-disable-next-line no-inline-assembly
    assembly {
      mstore(s, i)
    }
    return s;
  }

  function trimRight(string memory s) internal pure returns (string memory) {
    return string(trimRight(bytes(s)));
  }

  function asString(bytes32 data) internal pure returns (string memory) {
    return string(trimRight(abi.encodePacked(data)));
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../interfaces/IProxyFactory.sol';

interface IProxyCatalog is IProxyFactory {
  function getImplementationType(address impl) external view returns (bytes32, address);

  function isAuthenticImplementation(address impl) external view returns (bool);

  function isAuthenticProxy(address proxy) external view returns (bool);

  function getDefaultImplementation(bytes32 name, address context) external view returns (address);

  function getProxyOwner(address proxy) external view returns (address);

  function getProxyImplementation(address proxy) external view returns (address);
}

interface IManagedProxyCatalog is IProxyCatalog {
  function addAuthenticImplementation(
    address impl,
    bytes32 name,
    address context
  ) external;

  function removeAuthenticImplementation(address impl, address defReplacement) external;

  function unsetDefaultImplementation(address impl) external;

  function setDefaultImplementation(address impl) external;

  event ImplementationAdded(bytes32 indexed name, address indexed context, address indexed impl);
  event ImplementationRemoved(bytes32 indexed name, address indexed context, address indexed impl);
  event DefaultImplementationUpdated(bytes32 indexed name, address indexed context, address indexed impl);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../libraries/Balances.sol';
import './WeightedPoolStorage.sol';
import './WeightedPoolBase.sol';
import './InsurerJoinBase.sol';

// Handles Insured pool functions, adding/cancelling demand
abstract contract WeightedPoolExtension is ICoverageDistributor, WeightedPoolStorage {
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using Balances for Balances.RateAcc;

  /// @notice Coverage Unit Size is the minimum amount of coverage that can be demanded/provided
  /// @return The coverage unit size
  function coverageUnitSize() external view override returns (uint256) {
    return internalUnitSize();
  }

  /// @inheritdoc ICoverageDistributor
  function addCoverageDemand(
    uint256 unitCount,
    uint256 premiumRate,
    bool hasMore,
    uint256 loopLimit
  ) external override onlyActiveInsured returns (uint256 addedCount) {
    AddCoverageDemandParams memory params;
    params.insured = msg.sender;
    require(premiumRate == (params.premiumRate = uint40(premiumRate)));
    params.loopLimit = defaultLoopLimit(LoopLimitType.AddCoverageDemand, loopLimit);
    hasMore;
    require(unitCount <= type(uint64).max);

    addedCount = unitCount - super.internalAddCoverageDemand(uint64(unitCount), params);
    //If there was excess coverage before adding this demand, immediately assign it
    if (_excessCoverage > 0 && internalCanAddCoverage()) {
      // avoid addCoverage code to be duplicated within WeightedPoolExtension to reduce contract size
      WeightedPoolBase(address(this)).pushCoverageExcess();
    }
    return addedCount;
  }

  function _onlyActiveInsuredOrOps(address insured) private view {
    if (insured != msg.sender) {
      _onlyGovernorOr(AccessFlags.INSURER_OPS);
    }
    _onlyActiveInsured(insured);
  }

  modifier onlyActiveInsuredOrOps(address insured) {
    _onlyActiveInsuredOrOps(insured);
    _;
  }

  function cancelCoverageDemand(
    address insured,
    uint256 unitCount,
    uint256 loopLimit
  ) external override onlyActiveInsuredOrOps(insured) returns (uint256 cancelledUnits) {
    CancelCoverageDemandParams memory params;
    params.insured = insured;
    params.loopLimit = defaultLoopLimit(LoopLimitType.CancelCoverageDemand, loopLimit);

    if (unitCount > type(uint64).max) {
      unitCount = type(uint64).max;
    }
    return internalCancelCoverageDemand(uint64(unitCount), params);
  }

  function cancelCoverage(address insured, uint256 payoutRatio)
    external
    override
    onlyActiveInsuredOrOps(insured)
    onlyUnpaused
    returns (uint256 payoutValue)
  {
    bool enforcedCancel = msg.sender != insured;
    if (payoutRatio > 0) {
      payoutRatio = internalVerifyPayoutRatio(insured, payoutRatio, enforcedCancel);
    }
    (payoutValue, ) = internalCancelCoverage(insured, payoutRatio, enforcedCancel);
  }

  /// @dev Cancel all coverage for the insured and payout
  /// @param insured The address of the insured to cancel
  /// @param payoutRatio The RAY ratio of how much of provided coverage should be paid out
  /// @return payoutValue The effective amount of coverage paid out to the insured (includes all )
  function internalCancelCoverage(
    address insured,
    uint256 payoutRatio,
    bool enforcedCancel
  ) private returns (uint256 payoutValue, uint256 deductedValue) {
    (DemandedCoverage memory coverage, uint256 excessCoverage, uint256 providedCoverage, uint256 receivableCoverage, uint256 receivedPremium) = super
      .internalCancelCoverage(insured);
    // NB! receivableCoverage was not yet received by the insured, it was found during the cancallation
    // and caller relies on a coverage provided earlier

    // NB! when protocol is not fully covered, then there will be a discrepancy between the coverage provided ad-hoc
    // and the actual amount of protocol tokens made available during last sync
    // so this is a sanity check - insurance must be sync'ed before cancellation
    // otherwise there will be premium without actual supply of protocol tokens

    payoutValue = providedCoverage.rayMul(payoutRatio);

    require(
      enforcedCancel || ((receivableCoverage <= providedCoverage >> 16) && (receivableCoverage + payoutValue <= providedCoverage)),
      'must be reconciled'
    );

    uint256 premiumDebt = address(_premiumDistributor) == address(0)
      ? 0
      : _premiumDistributor.premiumAllocationFinished(insured, coverage.totalPremium, receivedPremium);

    internalSetStatus(insured, MemberStatus.Declined);

    if (premiumDebt > 0) {
      unchecked {
        if (premiumDebt >= payoutValue) {
          deductedValue = payoutValue;
          premiumDebt -= payoutValue;
          payoutValue = 0;
        } else {
          deductedValue = premiumDebt;
          payoutValue -= premiumDebt;
          premiumDebt = 0;
        }
      }
    }

    payoutValue = internalTransferCancelledCoverage(
      insured,
      payoutValue,
      providedCoverage - receivableCoverage,
      excessCoverage + receivableCoverage,
      premiumDebt
    );
  }

  function internalTransferCancelledCoverage(
    address insured,
    uint256 payoutValue,
    uint256 advanceValue,
    uint256 recoveredValue,
    uint256 premiumDebt
  ) internal virtual returns (uint256);

  /// @inheritdoc ICoverageDistributor
  function receivableDemandedCoverage(address insured, uint256 loopLimit)
    external
    view
    override
    returns (uint256 receivableCoverage, DemandedCoverage memory coverage)
  {
    GetCoveredDemandParams memory params;
    params.insured = insured;
    params.loopLimit = defaultLoopLimit(LoopLimitType.ReceivableDemandedCoverage, loopLimit);

    (coverage, , ) = internalGetCoveredDemand(params);
    return (params.receivedCoverage, coverage);
  }

  /// @inheritdoc ICoverageDistributor
  function receiveDemandedCoverage(address insured, uint256 loopLimit)
    external
    override
    onlyActiveInsured
    onlyUnpaused
    returns (
      uint256 receivedCoverage,
      uint256 receivedCollateral,
      DemandedCoverage memory coverage
    )
  {
    GetCoveredDemandParams memory params;
    params.insured = insured;
    params.loopLimit = defaultLoopLimit(LoopLimitType.ReceiveDemandedCoverage, loopLimit);

    coverage = internalUpdateCoveredDemand(params);
    receivedCollateral = internalTransferDemandedCoverage(insured, params.receivedCoverage, coverage);

    if (address(_premiumDistributor) != address(0)) {
      _premiumDistributor.premiumAllocationUpdated(insured, coverage.totalPremium, params.receivedPremium, coverage.premiumRate);
    }

    return (params.receivedCoverage, receivedCollateral, coverage);
  }

  function internalTransferDemandedCoverage(
    address insured,
    uint256 receivedCoverage,
    DemandedCoverage memory coverage
  ) internal virtual returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/math/PercentageMath.sol';
import '../interfaces/IPremiumDistributor.sol';
import './WeightedPoolConfig.sol';

// Contains all variables for both base and extension contract. Allows for upgrades without corruption

/// @dev
/// @dev WARNING! This contract MUST NOT be extended with new fields after deployment
/// @dev
abstract contract WeightedPoolStorage is WeightedPoolConfig {
  using PercentageMath for uint256;
  using WadRayMath for uint256;

  struct UserBalance {
    uint128 balance; // scaled
    uint128 extra; // NB! this field is used differenly for perpetual and imperpetual pools
  }
  mapping(address => UserBalance) internal _balances; // [investor]

  IPremiumDistributor internal _premiumDistributor;

  /// @dev Amount of coverage provided to the pool that is not satisfying demand
  uint192 internal _excessCoverage;
  bool internal _paused;

  event ExcessCoverageUpdated(uint256 coverageExcess);

  function internalSetExcess(uint256 excess) internal {
    Value.require((_excessCoverage = uint192(excess)) == excess);
    emit ExcessCoverageUpdated(excess);
  }

  modifier onlyUnpaused() {
    Access.require(!_paused);
    _;
  }

  ///@dev Return if an account has a balance or premium earned
  function internalIsInvestor(address account) internal view override returns (bool) {
    UserBalance memory b = _balances[account];
    return b.extra != 0 || b.balance != 0;
  }

  event PremiumDistributorUpdated(address);

  function internalSetPremiumDistributor(address premiumDistributor_) internal virtual {
    _premiumDistributor = IPremiumDistributor(premiumDistributor_);
    emit PremiumDistributorUpdated(premiumDistributor_);
  }

  function internalAfterJoinOrLeave(address insured, MemberStatus status) internal override {
    if (address(_premiumDistributor) != address(0)) {
      _premiumDistributor.registerPremiumSource(insured, status == MemberStatus.Accepted);
    }
    super.internalAfterJoinOrLeave(insured, status);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/upgradeability/VersionedInitializable.sol';
import '../tools/upgradeability/Delegator.sol';
import '../tools/tokens/ERC1363ReceiverBase.sol';
import '../interfaces/ICollateralStakeManager.sol';
import '../interfaces/IYieldStakeAsset.sol';
import '../interfaces/IPremiumActuary.sol';
import '../interfaces/IInsurerPool.sol';
import '../interfaces/IJoinable.sol';
import './WeightedPoolExtension.sol';
import './JoinablePoolExtension.sol';
import './WeightedPoolStorage.sol';

abstract contract WeightedPoolBase is
  IJoinableBase,
  IInsurerPoolBase,
  IPremiumActuary,
  IYieldStakeAsset,
  Delegator,
  ERC1363ReceiverBase,
  WeightedPoolStorage,
  VersionedInitializable
{
  address internal immutable _extension;
  address internal immutable _joinExtension;

  constructor(WeightedPoolExtension extension, JoinablePoolExtension joinExtension)
    WeightedPoolConfig(joinExtension.accessController(), extension.coverageUnitSize(), extension.collateral())
  {
    // TODO check for the same access controller
    // require(extension.accessController() == joinExtension.accessController());
    // require(extension.coverageUnitSize() == joinExtension.coverageUnitSize());
    Value.require(extension.collateral() == joinExtension.collateral());
    _extension = address(extension);
    _joinExtension = address(joinExtension);
  }

  // solhint-disable-next-line payable-fallback
  fallback() external {
    // all ICoverageDistributor etc functions should be delegated to the extension
    _delegate(_extension);
  }

  function charteredDemand() external pure override returns (bool) {
    return true;
  }

  function pushCoverageExcess() public virtual;

  function internalOnCoverageRecovered() internal virtual {
    pushCoverageExcess();
  }

  /// @dev initiates evaluation of the insured pool by this insurer. May involve governance activities etc.
  /// IInsuredPool.joinProcessed will be called after the decision is made.
  function requestJoin(address) external override {
    _delegate(_joinExtension);
  }

  function approveJoiner(address, bool) external {
    _delegate(_joinExtension);
  }

  function cancelJoin() external returns (MemberStatus) {
    _delegate(_joinExtension);
  }

  function governor() public view returns (address) {
    return governorAccount();
  }

  function _onlyPremiumDistributor() private view {
    Access.require(msg.sender == premiumDistributor());
  }

  modifier onlyPremiumDistributor() virtual {
    _onlyPremiumDistributor();
    _;
  }

  function burnPremium(
    address account,
    uint256 value,
    address drawdownRecepient
  ) external override onlyPremiumDistributor {
    internalBurnPremium(account, value, drawdownRecepient);
  }

  function internalBurnPremium(
    address account,
    uint256 value,
    address drawdownRecepient
  ) internal virtual;

  function collectDrawdownPremium() external override onlyPremiumDistributor returns (uint256) {
    return internalCollectDrawdownPremium();
  }

  function internalCollectDrawdownPremium() internal virtual returns (uint256);

  event SubrogationAdded(uint256 value);

  function addSubrogation(address donor, uint256 value) external aclHas(AccessFlags.INSURER_OPS) {
    if (value > 0) {
      transferCollateralFrom(donor, address(this), value);
      internalSubrogated(value);
      internalOnCoverageRecovered();
      internalOnCoveredUpdated();
      emit SubrogationAdded(value);
    }
  }

  function internalSubrogated(uint256 value) internal virtual;

  function setGovernor(address addr) external aclHas(AccessFlags.INSURER_ADMIN) {
    internalSetGovernor(addr);
  }

  function setPremiumDistributor(address addr) external aclHas(AccessFlags.INSURER_ADMIN) {
    internalSetPremiumDistributor(addr);
  }

  function setPoolParams(WeightedPoolParams calldata params) external onlyGovernorOr(AccessFlags.INSURER_ADMIN) {
    internalSetPoolParams(params);
  }

  // TODO setLoopLimits
  // function setLoopLimits(uint16[] calldata limits) external onlyGovernorOr(AccessFlags.INSURER_OPS) {
  //   internalSetLoopLimits(limits);
  // }

  /// @return status The status of the account, NotApplicable if unknown about this address or account is an investor
  function statusOf(address account) external view returns (MemberStatus status) {
    return internalStatusOf(account);
  }

  function premiumDistributor() public view override returns (address) {
    return address(_premiumDistributor);
  }

  function internalReceiveTransfer(
    address operator,
    address account,
    uint256 amount,
    bytes calldata data
  ) internal override onlyCollateralCurrency onlyUnpaused {
    Access.require(operator != address(this) && account != address(this) && internalGetStatus(account) == MemberStatus.Unknown);
    Value.require(data.length == 0);

    internalMintForCoverage(account, amount);
    internalOnCoveredUpdated();
  }

  function internalMintForCoverage(address account, uint256 value) internal virtual;

  event Paused(bool);

  function setPaused(bool paused) external onlyEmergencyAdmin {
    _paused = paused;
    emit Paused(paused);
  }

  function isPaused() public view returns (bool) {
    return _paused;
  }

  function internalOnCoveredUpdated() internal {}

  function internalSyncStake() internal {
    ICollateralStakeManager m = ICollateralStakeManager(IManagedCollateralCurrency(collateral()).borrowManager());
    if (address(m) != address(0)) {
      m.syncByStakeAsset(totalSupply(), collateralSupply());
    }
  }

  function _coveredTotal() internal view returns (uint256) {
    (uint256 totalCovered, uint256 pendingCovered) = super.internalGetCoveredTotals();
    return totalCovered + pendingCovered;
  }

  function totalSupply() public view virtual override returns (uint256);

  function collateralSupply() public view override returns (uint256) {
    return _coveredTotal() + _excessCoverage;
  }

  function totalPremiumRate() external view returns (uint256) {
    return super.internalGetPremiumTotals().premiumRate;
  }

  function internalPullDemand(uint256 loopLimit) internal {
    uint256 insuredLimit = defaultLoopLimit(LoopLimitType.AddCoverageDemandByPull, 0);

    for (; loopLimit > 0; ) {
      address insured;
      (insured, loopLimit) = super.internalPullDemandCandidate(loopLimit, false);
      if (insured == address(0)) {
        break;
      }
      if (IInsuredPool(insured).pullCoverageDemand(internalOpenBatchRounds() * internalUnitSize(), insuredLimit)) {
        if (loopLimit <= insuredLimit) {
          break;
        }
        loopLimit -= insuredLimit;
      }
    }
  }

  function internalAutoPullDemand(
    AddCoverageParams memory params,
    uint256 loopLimit,
    bool hasExcess,
    uint256 value
  ) internal {
    if (loopLimit > 0 && (hasExcess || params.openBatchNo == 0)) {
      uint256 n = _params.unitsPerAutoPull;
      if (n == 0) {
        return;
      }

      if (value != 0) {
        n = value / (n * internalUnitSize());
        if (n < loopLimit) {
          loopLimit = n;
        }
      }

      if (!hasExcess) {
        super.internalPullDemandCandidate(loopLimit == 0 ? 1 : loopLimit, true);
      } else if (loopLimit > 0) {
        internalPullDemand(loopLimit);
      }
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

/// @dev Provides delegation of calls with proper forwarding of return values and bubbling of failures. Based on OpenZeppelin Proxy.
abstract contract Delegator {
  /**
   * @dev Delegates execution to an implementation contract.
   * This is a low level function that doesn't return to its internal call site.
   * It will return to the external caller whatever the implementation returns.
   * @param implementation Address to delegate.
   */
  function _delegate(address implementation) internal {
    require(implementation != address(0));
    // solhint-disable-next-line no-inline-assembly
    assembly {
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      calldatacopy(0, 0, calldatasize())

      // Call the implementation.
      // out and outsize are 0 because we don't know the size yet.
      let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

      // Copy the returned data.
      returndatacopy(0, 0, returndatasize())

      switch result
      // delegatecall returns 0 on error.
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './IERC1363.sol';

abstract contract ERC1363ReceiverBase is IERC1363Receiver {
  function onTransferReceived(
    address operator,
    address from,
    uint256 value,
    bytes calldata data
  ) external override returns (bytes4) {
    internalReceiveTransfer(operator, from, value, data);
    return this.onTransferReceived.selector;
  }

  function internalReceiveTransfer(
    address operator,
    address from,
    uint256 value,
    bytes calldata data
  ) internal virtual;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface ICollateralStakeManager {
  function verifyBorrowUnderlying(address account, uint256 value) external returns (bool);

  function verifyRepayUnderlying(address account, uint256 value) external returns (bool);

  function syncStakeAsset(address asset) external;

  function syncByStakeAsset(uint256 assetSupply, uint256 collateralSupply) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './ICollateralized.sol';
import '../tools/tokens/IERC20.sol';

interface IYieldStakeAsset is ICollateralized {
  function collateralSupply() external view returns (uint256);

  function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/upgradeability/Delegator.sol';
import '../tools/tokens/ERC1363ReceiverBase.sol';
import '../interfaces/IPremiumActuary.sol';
import '../interfaces/IInsurerPool.sol';
import '../interfaces/IJoinable.sol';
import './WeightedPoolExtension.sol';
import './WeightedPoolStorage.sol';

contract JoinablePoolExtension is IJoinableBase, WeightedPoolStorage {
  constructor(
    IAccessController acl,
    uint256 unitSize,
    address collateral_
  ) WeightedPoolConfig(acl, unitSize, collateral_) {}

  function accessController() external view returns (IAccessController) {
    return remoteAcl();
  }

  function requestJoin(address insured) external override {
    Access.require(msg.sender == insured);
    internalRequestJoin(insured);
  }

  function approveJoiner(address insured, bool accepted) external onlyGovernorOr(AccessFlags.INSURER_OPS) {
    internalProcessJoin(insured, accepted);
  }

  function cancelJoin() external returns (MemberStatus) {
    return internalCancelJoin(msg.sender);
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

import './WeightedPoolExtension.sol';
import './PerpetualPoolBase.sol';

/// @dev NB! MUST HAVE NO STORAGE
contract PerpetualPoolExtension is WeightedPoolExtension {
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using Balances for Balances.RateAcc;

  constructor(
    IAccessController acl,
    uint256 unitSize,
    address collateral_
  ) WeightedPoolConfig(acl, unitSize, collateral_) {}

  function internalTransferCancelledCoverage(
    address insured,
    uint256 payoutValue,
    uint256 advanceValue,
    uint256 recoveredValue,
    uint256 premiumDebt
  ) internal override returns (uint256) {
    uint256 deficitValue;
    uint256 toPay = payoutValue;
    unchecked {
      if (toPay >= advanceValue) {
        toPay -= advanceValue;
        advanceValue = 0;
      } else {
        deficitValue = (advanceValue -= toPay);
        toPay = 0;
      }

      if (toPay >= premiumDebt) {
        toPay -= premiumDebt;
      } else {
        deficitValue += (premiumDebt - toPay);
      }
    }

    uint256 collateralAsPremium;

    if (deficitValue > 0) {
      // toPay is zero
      toPay = transferAvailableCollateralFrom(insured, address(this), deficitValue);
      if (toPay > advanceValue) {
        unchecked {
          collateralAsPremium = toPay - advanceValue;
        }
        toPay = advanceValue;
      }
      recoveredValue += toPay;
    } else if (toPay > 0) {
      transferCollateral(insured, toPay);
    }

    // this call is to consider / reinvest the released funds
    PerpetualPoolBase(address(this)).updateCoverageOnCancel(payoutValue + premiumDebt, recoveredValue, collateralAsPremium);
    // ^^ avoids code to be duplicated within WeightedPoolExtension to reduce contract size

    return payoutValue;
  }

  function internalTransferDemandedCoverage(
    address insured,
    uint256 receivedCoverage,
    DemandedCoverage memory
  ) internal override returns (uint256) {
    if (receivedCoverage > 0) {
      transferCollateral(insured, receivedCoverage);
    }
    return receivedCoverage;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './PerpetualPoolStorage.sol';
import './PerpetualPoolExtension.sol';
import './WeightedPoolBase.sol';

/// @title Index Pool Base with Perpetual Index Pool Tokens
/// @notice Handles adding coverage by users.
abstract contract PerpetualPoolBase is IPerpetualInsurerPool, PerpetualPoolStorage {
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using Balances for Balances.RateAcc;

  constructor(PerpetualPoolExtension extension, JoinablePoolExtension joinExtension) WeightedPoolBase(extension, joinExtension) {}

  /// @dev Updates the user's balance based upon the current exchange rate of $CC to $Pool_Coverage
  /// @dev Update the new amount of excess coverage
  function internalMintForCoverage(address account, uint256 coverageValue) internal override {
    (UserBalance memory b, Balances.RateAcc memory totals) = _beforeBalanceUpdate(account);

    uint256 excessCoverage = _excessCoverage;
    if (coverageValue > 0 || excessCoverage > 0) {
      (uint256 newExcess, uint256 loopLimit, AddCoverageParams memory params, PartialState memory part) = super.internalAddCoverage(
        coverageValue + excessCoverage,
        defaultLoopLimit(LoopLimitType.AddCoverage, 0)
      );

      if (newExcess != excessCoverage) {
        internalSetExcess(newExcess);
      }

      _afterBalanceUpdate(newExcess, totals, super.internalGetPremiumTotals(part, params.premium));

      internalAutoPullDemand(params, loopLimit, newExcess > 0, coverageValue);
    }

    emit Transfer(address(0), account, coverageValue);

    uint256 amount = coverageValue.rayDiv(exchangeRate()) + b.balance;
    require(amount == (b.balance = uint128(amount)));
    _balances[account] = b;
  }

  function internalAdjustCoverage(uint256 loss, uint256 excess) private {
    DemandedCoverage memory coverage = super.internalGetPremiumTotals();
    Balances.RateAcc memory totals = _beforeAnyBalanceUpdate();

    uint256 excessCoverage = _excessCoverage + excess;
    if (loss > 0) {
      uint256 total = coverage.totalCovered + coverage.pendingCovered + excessCoverage;
      _inverseExchangeRate = WadRayMath.RAY - total.rayDiv(total + loss).rayMul(exchangeRate());
    }

    if (excess > 0) {
      internalSetExcess(excessCoverage);
    }
    _afterBalanceUpdate(excessCoverage, totals, coverage);
  }

  function internalSubrogated(uint256 value) internal override {
    internalAdjustCoverage(0, value);
  }

  /// @dev Update the exchange rate and excess coverage when a policy cancellation occurs
  /// @dev Call _afterBalanceUpdate to update the rate of the pool
  function updateCoverageOnCancel(
    uint256 valueLoss,
    uint256 excess,
    uint256 collateralAsPremium
  ) external onlySelf {
    internalAdjustCoverage(valueLoss, excess);
    if (collateralAsPremium > 0) {
      internalAddCollateralAsPremium(collateralAsPremium);
    }
    if (excess > 0) {
      internalOnCoverageRecovered();
    }
  }

  function internalAddCollateralAsPremium(uint256 amount) internal virtual {
    amount;
    // TODO internalAddCollateralAsPremium
    Errors.notImplemented();
  }

  /// @dev Attempt to take the excess coverage and fill batches
  /// @dev Occurs when there is excess and a new batch is ready (more demand added)
  function pushCoverageExcess() public override {
    uint256 excessCoverage = _excessCoverage;
    if (excessCoverage == 0) {
      return;
    }

    (uint256 newExcess, , AddCoverageParams memory p, PartialState memory part) = super.internalAddCoverage(excessCoverage, type(uint256).max);

    if (newExcess != excessCoverage) {
      Balances.RateAcc memory totals = _beforeAnyBalanceUpdate();
      internalSetExcess(newExcess);
      _afterBalanceUpdate(newExcess, totals, super.internalGetPremiumTotals(part, p.premium));
    }
  }

  /// @dev Burn a user's pool tokens and send them the underlying $CC in return
  function internalBurn(address account, uint256 coverageValue) internal returns (uint256) {
    (UserBalance memory b, Balances.RateAcc memory totals) = _beforeBalanceUpdate(account);

    {
      uint256 balance = uint256(b.balance).rayMul(exchangeRate());
      if (coverageValue >= balance) {
        coverageValue = balance;
        b.balance = 0;
      } else {
        b.balance = uint128(b.balance - coverageValue.rayDiv(exchangeRate()));
      }
    }

    if (coverageValue > 0) {
      uint256 excess = _excessCoverage - coverageValue;
      internalSetExcess(excess);
      totals = _afterBalanceUpdate(excess, totals, super.internalGetPremiumTotals());
    }
    emit Transfer(account, address(0), coverageValue);
    _balances[account] = b;

    transferCollateral(account, coverageValue);

    return coverageValue;
  }

  function balanceOf(address account) public view override returns (uint256) {
    return _balances[account].balance;
  }

  /// @dev returns the ($CC coverage, $PC coverage, premium accumulated) of a user
  /// @return coverage The amount of coverage user is providing
  /// @return scaled The number of tokens `coverage` is equal to
  /// @return premium The amount of premium earned by the user
  function balancesOf(address account)
    public
    view
    returns (
      uint256 coverage,
      uint256 scaled,
      uint256 premium
    )
  {
    scaled = balanceOf(account);
    coverage = scaled.rayMul(exchangeRate());
    (, premium) = interestOf(account);
  }

  /// @return The $CC-equivalent value of this pool
  function totalSupplyValue() public view returns (uint256) {
    DemandedCoverage memory coverage = super.internalGetPremiumTotals();
    return coverage.totalCovered + coverage.pendingCovered + _excessCoverage;
  }

  /// @return The amount of tokens of this pool
  function totalSupply() public view override returns (uint256) {
    return totalSupplyValue().rayDiv(exchangeRate());
  }

  function interestOf(address account) public view override returns (uint256 rate, uint256 accumulated) {
    Balances.RateAcc memory totals = _beforeAnyBalanceUpdate();
    UserBalance memory b = _balances[account];

    accumulated = _userPremiums[account];

    if (b.balance > 0) {
      uint256 premiumDiff = totals.accum - b.extra;
      if (premiumDiff > 0) {
        accumulated += uint256(b.balance).rayMul(premiumDiff);
      }
      return (uint256(b.balance).rayMul(totals.rate), accumulated);
    }

    return (0, accumulated);
  }

  function exchangeRate() public view override(IInsurerPoolBase, PerpetualPoolStorage) returns (uint256) {
    return PerpetualPoolStorage.exchangeRate();
  }

  ///@notice Transfer a balance to a recipient, syncs the balances before performing the transfer
  ///@param sender  The sender
  ///@param recipient The receiver
  ///@param amount  Amount to transfer
  function transferBalance(
    address sender,
    address recipient,
    uint256 amount
  ) internal override {
    (UserBalance memory b, Balances.RateAcc memory totals) = _beforeBalanceUpdate(sender);

    b.balance = uint128(b.balance - amount);
    _balances[sender] = b;

    b = _syncBalance(recipient, totals);
    require((b.balance += uint128(amount)) >= amount);
    _balances[recipient] = b;
  }

  /// @dev Max amount withdrawable is the amount of excess coverage
  function withdrawable(address account) public view override returns (uint256 amount) {
    amount = _excessCoverage;
    if (amount > 0) {
      uint256 bal = balanceOf(account).rayMul(exchangeRate());
      if (amount > bal) {
        amount = bal;
      }
    }
  }

  function withdrawAll() external override onlyUnpaused returns (uint256) {
    return internalBurn(msg.sender, _excessCoverage);
  }

  function internalBurnPremium(
    address account,
    uint256 value,
    address drawdownRecepient
  ) internal override {
    if (drawdownRecepient == address(0)) {
      (UserBalance memory b, ) = _beforeBalanceUpdate(account);
      b.extra = uint128(b.extra - value);
      _balances[account] = b;
    } else {
      _burnDrawdown(account, value);
    }
  }

  function _burnDrawdown(address account, uint256 value) private {
    account;
    value;
    Errors.notImplemented();
  }

  function internalCollectDrawdownPremium() internal override returns (uint256) {}

  function internalSetPoolParams(WeightedPoolParams memory params) internal override {
    require(params.coveragePrepayPct == PercentageMath.ONE);

    super.internalSetPoolParams(params);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/tokens/ERC20BalancelessBase.sol';
import '../libraries/Balances.sol';
import './WeightedPoolBase.sol';

abstract contract PerpetualPoolStorage is WeightedPoolBase, ERC20BalancelessBase {
  using WadRayMath for uint256;
  using Balances for Balances.RateAcc;

  mapping(address => uint256) internal _userPremiums;
  Balances.RateAcc private _totalRate;

  uint256 internal _inverseExchangeRate;

  /// @notice The exchange rate from shares to $CC
  /// @return The exchange rate
  function exchangeRate() public view virtual override returns (uint256) {
    return WadRayMath.RAY - _inverseExchangeRate;
  }

  /// @dev Performed before all balance updates. The total rate accum by the pool is updated
  /// @return totals The new totals of the pool
  function _beforeAnyBalanceUpdate() internal view returns (Balances.RateAcc memory totals) {
    totals = _totalRate.sync(uint32(block.timestamp));
  }

  /// @dev Performed before balance updates.
  /// @dev Update the total, and then the account's premium
  function _beforeBalanceUpdate(address account) internal returns (UserBalance memory b, Balances.RateAcc memory totals) {
    totals = _beforeAnyBalanceUpdate();
    b = _syncBalance(account, totals);
  }

  /// @dev Update the premium earned by a user, and then sets their premiumBase to the current pool accumulated per unit
  /// @return b The user's balance struct
  function _syncBalance(address account, Balances.RateAcc memory totals) internal returns (UserBalance memory b) {
    b = _balances[account];
    if (b.balance > 0) {
      uint256 premiumDiff = totals.accum - b.extra;
      if (premiumDiff > 0) {
        _userPremiums[account] += premiumDiff.rayMul(b.balance);
      }
    }
    b.extra = totals.accum;
  }

  /// @dev After the balance of the pool is updated, update the _totalRate
  function _afterBalanceUpdate(
    uint256 newExcess,
    Balances.RateAcc memory totals,
    DemandedCoverage memory coverage
  ) internal returns (Balances.RateAcc memory) {
    // console.log('_afterBalanceUpdate', coverage.premiumRate, newExcess, coverage.totalCovered + coverage.pendingCovered);

    uint256 rate = coverage.premiumRate == 0 ? 0 : uint256(coverage.premiumRate).rayDiv(newExcess + coverage.totalCovered + coverage.pendingCovered);
    // earns per second * 10^27
    _totalRate = totals.setRateAfterSync(rate.rayMul(exchangeRate()));
    return totals;
  }

  function totalSupply() public view virtual override(IERC20, WeightedPoolBase) returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../BalancerLib2.sol';

contract MockBalancerLib2 {
  using BalancerLib2 for BalancerLib2.AssetBalancer;

  BalancerLib2.AssetBalancer private _poolBalance;

  function getTotalBalance() external view returns (Balances.RateAcc memory) {
    return _poolBalance.totalBalance;
  }

  function setGlobals(uint32 spFactor, uint160 spConst) external {
    _poolBalance.spFactor = spFactor;
    _poolBalance.spConst = spConst;
  }

  function setTotalBalance(uint128 accum, uint96 rate) external {
    _poolBalance.totalBalance = Balances.RateAcc(accum, rate, uint32(block.timestamp));
  }

  function setConfig(
    address asset,
    uint152 price,
    uint64 w,
    uint32 n,
    uint16 flags,
    uint160 spConst
  ) external {
    _poolBalance.configs[asset] = BalancerLib2.AssetConfig(price, w, n, flags, spConst);
  }

  function setBalance(
    address asset,
    uint128 accum,
    uint96 rate
  ) external {
    _poolBalance.balances[asset] = BalancerLib2.AssetBalance(accum, rate, uint32(block.timestamp));
  }

  function getBalance(address asset) external view returns (BalancerLib2.AssetBalance memory) {
    return _poolBalance.balances[asset];
  }

  event TokenSwapped(uint256 amount, uint256 fee);

  uint256 private _replenishDelta;
  uint256 private _exchangeRate = WadRayMath.WAD;

  function setReplenishDelta(uint256 delta) external {
    _replenishDelta = delta;
  }

  function setExchangeRate(uint16 pctRate) external {
    _exchangeRate = PercentageMath.percentMul(WadRayMath.WAD, pctRate);
  }

  function _replenishFn(BalancerLib2.ReplenishParams memory, uint256 v)
    private
    view
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    v += _replenishDelta;
    return (WadRayMath.wadDiv(v, _exchangeRate), v, v);
  }

  function swapToken(
    address token,
    uint256 value,
    uint256 minAmount
  ) external returns (uint256 amount, uint256 fee) {
    (amount, fee) = _poolBalance.swapAsset(
      BalancerLib2.ReplenishParams({actuary: address(0), source: address(0), token: token, replenishFn: _replenishFn}),
      value,
      minAmount,
      0
    );
    emit TokenSwapped(amount, fee);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/math/WadRayMath.sol';
import '../tools/math/Math.sol';
import './InsuredPoolBase.sol';

contract InsuredPoolMonoRateBase is InsuredPoolBase {
  using WadRayMath for uint256;
  using Math for uint256;

  uint96 private _requiredCoverage;
  uint96 private _demandedCoverage;
  uint64 private _premiumRate;

  constructor(IAccessController acl, address collateral_) InsuredPoolBase(acl, collateral_) {}

  event CoverageDemandUpdated(uint256 requiredCoverage, uint256 premiumRate);

  function _initializeCoverageDemand(uint256 requiredCoverage, uint256 premiumRate) internal {
    State.require(_premiumRate == 0);
    Value.require(premiumRate != 0);
    Value.require((_requiredCoverage = uint96(requiredCoverage)) == requiredCoverage);
    Value.require((_premiumRate = uint64(premiumRate)) == premiumRate);
    emit CoverageDemandUpdated(requiredCoverage, premiumRate);
  }

  function internalAddRequiredCoverage(uint256 amount) internal {
    _requiredCoverage += amount.asUint96();
    emit CoverageDemandUpdated(_requiredCoverage + _demandedCoverage, _premiumRate);
  }

  /// @dev When coverage demand is added, the required coverage is reduced and total demanded coverage increased
  /// @dev Mints to the appropriate insurer
  // slither-disable-next-line costly-loop
  function internalCoverageDemandAdded(
    address target,
    uint256 amount,
    uint256 premiumRate
  ) internal override {
    _requiredCoverage = uint96(_requiredCoverage - amount);
    _demandedCoverage += uint96(amount);
    InsuredBalancesBase.internalMintForDemandedCoverage(target, amount.wadMul(premiumRate));
  }

  function internalAllocateCoverageDemand(
    address,
    uint256,
    uint256 maxAmount,
    uint256
  ) internal view override returns (uint256 amountToAdd, uint256 premiumRate) {
    amountToAdd = _requiredCoverage;
    if (amountToAdd > maxAmount) {
      amountToAdd = maxAmount;
    }
    premiumRate = _premiumRate;
  }

  function setCoverageDemand(uint256 requiredCoverage, uint256 premiumRate) external onlyGovernor {
    if (internalHasAppliedApplication()) {
      IApprovalCatalog.ApprovedPolicy memory ap = internalGetApprovedPolicy();
      Value.require(premiumRate >= ap.basePremiumRate);
    }
    _initializeCoverageDemand(requiredCoverage, premiumRate);
  }

  function internalOfferCoverage(address account, uint256 offeredAmount) internal override returns (uint256 acceptedAmount, uint256 rate) {
    _ensureHolder(account);
    acceptedAmount = _requiredCoverage;
    if (acceptedAmount <= offeredAmount) {
      _requiredCoverage = 0;
    } else {
      _requiredCoverage = uint96(acceptedAmount - offeredAmount);
      acceptedAmount = offeredAmount;
    }
    rate = _premiumRate;
    InsuredBalancesBase.internalMintForDemandedCoverage(account, acceptedAmount.wadMul(rate));
  }

  function rateBands() external view override returns (InsuredRateBand[] memory bands, uint256) {
    if (_premiumRate > 0) {
      bands = new InsuredRateBand[](1);
      bands[0].premiumRate = _premiumRate;
      bands[0].coverageDemand = _requiredCoverage + _demandedCoverage;
    }
    return (bands, 1);
  }

  function cancelCoverageDemand(address[] calldata targets, uint256[] calldata amounts)
    external
    onlyGovernorOr(AccessFlags.INSURED_OPS)
    returns (uint256 cancelledDemand)
  {
    Value.require(targets.length == amounts.length);
    for (uint256 i = 0; i < targets.length; i++) {
      cancelledDemand += _cancelDemand(targets[i], amounts[i]);
    }
  }

  function cancelAllCoverageDemand() external onlyGovernorOr(AccessFlags.INSURED_OPS) returns (uint256 cancelledDemand) {
    address[] storage targets = getCharteredInsurers();
    for (uint256 i = targets.length; i > 0; ) {
      i--;
      cancelledDemand += _cancelDemand(targets[i], type(uint256).max);
    }
  }

  event CoverageDemandCancelled(address indexed insurer, uint256 requested, uint256 cancelled);

  // slither-disable-next-line calls-loop,costly-loop
  function _cancelDemand(address insurer, uint256 requestedAmount) private returns (uint256 totalPayout) {
    uint256 unitSize = ICancellableCoverageDemand(insurer).coverageUnitSize();
    uint256 unitCount = requestedAmount.divUp(unitSize);
    if (unitCount > 0) {
      unitCount = ICancellableCoverageDemand(insurer).cancelCoverageDemand(address(this), unitCount, 0);
    }

    if (unitCount > 0) {
      totalPayout = unitCount * unitSize;

      _demandedCoverage = uint96(_demandedCoverage - totalPayout);
      Value.require((_requiredCoverage += uint96(totalPayout)) >= totalPayout);
      internalBurnForDemandedCoverage(insurer, totalPayout.wadMul(_premiumRate));
    }

    emit CoverageDemandCancelled(insurer, requestedAmount, totalPayout);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../InsuredPoolMonoRateBase.sol';

contract MockInsuredPool is InsuredPoolMonoRateBase {
  constructor(
    address collateral_,
    uint256 totalDemand,
    uint64 premiumRate,
    uint128 minPerInsurer,
    address premiumToken_
  ) InsuredPoolMonoRateBase(IAccessController(address(0)), collateral_) {
    _initializeERC20('InsuredPoolToken', '$DC', DECIMALS);
    _initializeCoverageDemand(totalDemand, premiumRate);
    _initializePremiumCollector(premiumToken_, 0, 0);
    internalSetInsuredParams(InsuredParams({minPerInsurer: minPerInsurer}));
    internalSetGovernor(msg.sender);
  }

  function externalGetAccountStatus(address account) external view returns (uint16) {
    return getAccountStatus(account);
  }

  function testCancelCoverageDemand(address insurer, uint64 unitCount) external {
    ICoverageDistributor(insurer).cancelCoverageDemand(address(this), unitCount, 0);
  }

  function internalPriceOf(address) internal pure override returns (uint256) {
    return WadRayMath.WAD;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/upgradeability/VersionedInitializable.sol';
import '../interfaces/IInsuredPoolInit.sol';
import './InsuredPoolMonoRateBase.sol';

contract InsuredPoolV1 is VersionedInitializable, IInsuredPoolInit, InsuredPoolMonoRateBase {
  uint256 private constant CONTRACT_REVISION = 1;

  constructor(IAccessController acl, address collateral_) InsuredPoolMonoRateBase(acl, collateral_) {}

  function initializeInsured(address governor_) public override initializer(CONTRACT_REVISION) {
    internalSetGovernor(governor_);
  }

  function getRevision() internal pure virtual override returns (uint256) {
    return CONTRACT_REVISION;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/upgradeability/VersionedInitializable.sol';
import './PriceGuardOracleBase.sol';

contract OracleRouterV1 is VersionedInitializable, PriceGuardOracleBase {
  uint256 private constant CONTRACT_REVISION = 1;

  constructor(IAccessController acl, address quote) PriceGuardOracleBase(acl, quote) {}

  function initializePriceOracle() public initializer(CONTRACT_REVISION) {}

  function getRevision() internal pure override returns (uint256) {
    return CONTRACT_REVISION;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../tools/upgradeability/VersionedInitializable.sol';

contract MockVersionedInitializable1 is VersionedInitializable {
  uint256 private constant revision = 1;

  string public name;

  function initialize(string memory name_) external initializer(revision) {
    name = name_;
  }

  function getRevision() internal pure override returns (uint256) {
    return revision;
  }
}

contract MockVersionedInitializable2 is VersionedInitializable {
  uint256 private constant revision = 2;

  string public name;

  function initialize(string memory name_) external initializer(revision) {
    name = name_;
  }

  function getRevision() internal pure override returns (uint256) {
    return revision;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/upgradeability/VersionedInitializable.sol';
import '../interfaces/IYieldDistributorInit.sol';
import './YieldDistributorBase.sol';

contract YieldDistributorV1 is IYieldDistributorInit, VersionedInitializable, YieldDistributorBase {
  uint256 private constant CONTRACT_REVISION = 1;

  constructor(IAccessController acl, address collateral_) YieldDistributorBase(acl, collateral_) {}

  function initializeYieldDistributor() public override initializer(CONTRACT_REVISION) {}

  function getRevision() internal pure override returns (uint256) {
    return CONTRACT_REVISION;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '../tools/SafeERC20.sol';
import '../tools/math/Math.sol';
import '../tools/math/WadRayMath.sol';
import '../tools/math/PercentageMath.sol';
import '../interfaces/IManagedCollateralCurrency.sol';
import '../access/AccessHelper.sol';

import '../access/AccessHelper.sol';
import './interfaces/IManagedYieldDistributor.sol';
import './YieldStakerBase.sol';
import './YieldStreamerBase.sol';

contract YieldDistributorBase is IManagedYieldDistributor, YieldStakerBase, YieldStreamerBase {
  using SafeERC20 for IERC20;
  using Math for uint256;
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using EnumerableSet for EnumerableSet.AddressSet;

  uint128 private _totalIntegral;
  uint32 private _lastUpdatedAt;

  constructor(IAccessController acl, address collateral_) AccessHelper(acl) Collateralized(collateral_) {}

  event AssetAdded(address indexed asset);
  event AssetRemoved(address indexed asset);

  function registerStakeAsset(address asset, bool register) external override onlyCollateralCurrency {
    if (register) {
      internalAddAsset(asset);
      emit AssetAdded(asset);
    } else {
      internalRemoveAsset(asset);
      emit AssetRemoved(asset);
    }
  }

  function internalAddYieldExcess(uint256 value) internal override(YieldStakerBase, YieldStreamerBase) {
    YieldStakerBase.internalAddYieldExcess(value);
  }

  function internalGetTimeIntegral() internal view override returns (uint256 totalIntegral, uint32 lastUpdatedAt) {
    return (_totalIntegral, _lastUpdatedAt);
  }

  function internalSetTimeIntegral(uint256 totalIntegral, uint32 lastUpdatedAt) internal override {
    (_totalIntegral, _lastUpdatedAt) = (totalIntegral.asUint128(), lastUpdatedAt);
  }

  function internalGetRateIntegral(uint32 from, uint32 till) internal override(YieldStakerBase, YieldStreamerBase) returns (uint256) {
    return YieldStreamerBase.internalGetRateIntegral(from, till);
  }

  function internalCalcRateIntegral(uint32 from, uint32 till) internal view override(YieldStakerBase, YieldStreamerBase) returns (uint256) {
    return YieldStreamerBase.internalCalcRateIntegral(from, till);
  }

  function internalPullYield(uint256 availableYield, uint256 requestedYield) internal override(YieldStakerBase, YieldStreamerBase) returns (bool) {
    return YieldStreamerBase.internalPullYield(availableYield, requestedYield);
  }

  function _onlyTrustedBorrower(address addr) private view {
    Access.require(hasAnyAcl(addr, AccessFlags.LIQUIDITY_BORROWER) && internalIsYieldSource(addr));
  }

  modifier onlyTrustedBorrower(address addr) {
    _onlyTrustedBorrower(addr);
    _;
  }

  function verifyBorrowUnderlying(address account, uint256 value)
    external
    override
    onlyLiquidityProvider
    onlyTrustedBorrower(account)
    returns (bool)
  {
    internalApplyBorrow(value);
    return true;
  }

  function verifyRepayUnderlying(address account, uint256 value) external override onlyLiquidityProvider onlyTrustedBorrower(account) returns (bool) {
    internalApplyRepay(value);
    return true;
  }

  event YieldPayout(address indexed source, uint256 amount, uint256 expectedRate);

  function addYieldPayout(uint256 amount, uint256 expectedRate) external {
    if (amount > 0) {
      transferCollateralFrom(msg.sender, address(this), amount);
    }
    internalSyncTotal();
    internalAddYieldPayout(msg.sender, amount, expectedRate);
    emit YieldPayout(msg.sender, amount, expectedRate);
  }

  function addYieldSource(address source, uint8 sourceType) external aclHas(AccessFlags.BORROWER_ADMIN) {
    internalAddYieldSource(source, sourceType);
  }

  function removeYieldSource(address source) external aclHas(AccessFlags.BORROWER_ADMIN) {
    internalSyncTotal();
    internalRemoveYieldSource(source);
  }

  // TODO pause, pause_asset, pause_source_borrow

  function getYieldSource(address source)
    external
    view
    returns (
      uint8 sourceType,
      uint96 expectedRate,
      uint32 since
    )
  {
    return internalGetYieldSource(source);
  }

  function getYieldInfo()
    external
    view
    returns (
      uint256 rate,
      uint256 debt,
      uint32 cutOff
    )
  {
    return internalGetYieldInfo();
  }

  function internalPullYieldFrom(uint8, address) internal virtual override returns (uint256) {
    Errors.notImplemented();
    return 0;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../interfaces/ICollateralized.sol';

interface IManagedYieldDistributor is ICollateralized {
  function registerStakeAsset(address asset, bool register) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '../tools/SafeERC20.sol';
import '../tools/math/Math.sol';
import '../tools/math/WadRayMath.sol';
import '../tools/math/PercentageMath.sol';
import '../interfaces/IManagedCollateralCurrency.sol';
import '../interfaces/ICollateralStakeManager.sol';
import '../interfaces/IYieldStakeAsset.sol';
import '../access/AccessHelper.sol';

import '../access/AccessHelper.sol';
import './interfaces/ICollateralFund.sol';
import './Collateralized.sol';

abstract contract YieldStakerBase is ICollateralStakeManager, AccessHelper, Collateralized {
  using SafeERC20 for IERC20;
  using Math for uint256;
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using EnumerableSet for EnumerableSet.AddressSet;

  uint128 private _totalStakedCollateral;
  uint128 private _totalBorrowedCollateral;

  uint16 private constant FLAG_ASSET_PRESENT = 1 << 0;
  uint16 private constant FLAG_ASSET_REMOVED = 1 << 1;
  uint16 private constant FLAG_ASSET_PAUSED = 1 << 2;

  struct AssetBalance {
    uint16 flags;
    uint112 collateralFactor;
    uint128 stakedTokenTotal;
    uint128 totalIntegral;
    uint128 assetIntegral;
  }

  mapping(IYieldStakeAsset => AssetBalance) private _assetBalances;

  struct UserBalance {
    uint128 yieldBalance;
    uint16 assetCount;
  }

  struct UserAssetBalance {
    uint128 assetIntegral;
    uint112 stakedTokenAmount;
    uint16 assetIndex;
  }

  mapping(address => UserBalance) private _userBalances;
  mapping(IYieldStakeAsset => mapping(address => UserAssetBalance)) private _userAssetBalances;
  mapping(address => mapping(uint256 => IYieldStakeAsset)) private _userAssets;

  function internalAddAsset(address asset) internal {
    Value.require(IYieldStakeAsset(asset).collateral() == collateral());

    AssetBalance storage assetBalance = _assetBalances[IYieldStakeAsset(asset)];
    State.require(assetBalance.flags == 0);

    assetBalance.flags = FLAG_ASSET_PRESENT;
  }

  function internalRemoveAsset(address asset) internal {
    AssetBalance storage assetBalance = _assetBalances[IYieldStakeAsset(asset)];
    uint16 flags = assetBalance.flags;
    if (flags & (FLAG_ASSET_PRESENT | FLAG_ASSET_REMOVED) == FLAG_ASSET_PRESENT) {
      _updateAsset(IYieldStakeAsset(asset), 1, 0, true);
      assetBalance.flags = flags | FLAG_ASSET_REMOVED | FLAG_ASSET_PAUSED;
    }
  }

  function internalPauseAsset(address asset, bool paused) internal {
    AssetBalance storage assetBalance = _assetBalances[IYieldStakeAsset(asset)];
    uint16 flags = assetBalance.flags;
    State.require(flags & FLAG_ASSET_PRESENT != 0);
    assetBalance.flags = paused ? flags | FLAG_ASSET_PAUSED : flags & ~uint16(FLAG_ASSET_PAUSED);
  }

  function internalIsAssetPaused(address asset) internal view returns (bool) {
    AssetBalance storage assetBalance = _assetBalances[IYieldStakeAsset(asset)];
    return assetBalance.flags & FLAG_ASSET_PAUSED != 0;
  }

  function _ensureActiveAsset(uint16 assetFlags, bool ignorePause) private pure {
    State.require(
      (assetFlags & (ignorePause ? FLAG_ASSET_PRESENT | FLAG_ASSET_REMOVED : FLAG_ASSET_PRESENT | FLAG_ASSET_REMOVED | FLAG_ASSET_PAUSED) ==
        FLAG_ASSET_PRESENT)
    );
  }

  function _ensureUnpausedAsset(address asset, bool mustBeActive) private view {
    _ensureUnpausedAsset(_assetBalances[IYieldStakeAsset(asset)].flags, mustBeActive);
  }

  function _ensureUnpausedAsset(uint16 assetFlags, bool mustBeActive) private pure {
    State.require(
      (assetFlags & (mustBeActive ? FLAG_ASSET_PRESENT | FLAG_ASSET_REMOVED : FLAG_ASSET_PRESENT | FLAG_ASSET_PAUSED) == FLAG_ASSET_PRESENT)
    );
  }

  modifier onlyUnpausedAsset(address asset, bool active) {
    _ensureUnpausedAsset(asset, active);
    _;
  }

  function stake(
    address asset,
    uint256 amount,
    address to
  ) external onlyUnpausedAsset(asset, true) {
    Value.require(to != address(0));

    if (amount == type(uint256).max) {
      if ((amount = IERC20(asset).balanceOf(msg.sender)) > 0) {
        uint256 max = IERC20(asset).allowance(msg.sender, address(this));
        if (amount > max) {
          amount = max;
        }
      }
    }
    if (amount == 0) {
      return;
    }

    SafeERC20.safeTransferFrom(IERC20(asset), msg.sender, address(this), amount);

    _updateAssetAndUser(IYieldStakeAsset(asset), amount.asUint112(), 0, to);
  }

  function unstake(
    address asset,
    uint256 amount,
    address to
  ) external onlyUnpausedAsset(asset, false) {
    Value.require(to != address(0));

    if (amount == type(uint256).max) {
      amount = _userAssetBalances[IYieldStakeAsset(asset)][msg.sender].stakedTokenAmount;
    }
    if (amount == 0) {
      return;
    }

    _updateAssetAndUser(IYieldStakeAsset(asset), 0, amount.asUint112(), msg.sender);
    SafeERC20.safeTransfer(IERC20(asset), to, amount);
  }

  function syncStakeAsset(address asset) external override onlyUnpausedAsset(asset, true) {
    IYieldStakeAsset a = IYieldStakeAsset(asset);
    _updateAsset(a, a.totalSupply(), a.collateralSupply(), false);
  }

  function syncByStakeAsset(uint256 assetSupply, uint256 collateralSupply) external override {
    IYieldStakeAsset asset = IYieldStakeAsset(msg.sender);
    _ensureActiveAsset(_assetBalances[asset].flags, true);
    _updateAsset(asset, assetSupply, collateralSupply, true);
  }

  function _updateAsset(
    IYieldStakeAsset asset,
    uint256 assetSupply,
    uint256 collateralSupply,
    bool ignorePause
  ) private {
    uint256 collateralFactor = collateralSupply.rayDiv(assetSupply);
    if (_assetBalances[asset].collateralFactor == collateralFactor) {
      return;
    }

    _updateAsset(asset, collateralFactor, 0, 0, ignorePause);
  }

  function internalGetTimeIntegral() internal view virtual returns (uint256 totalIntegral, uint32 lastUpdatedAt);

  function internalSetTimeIntegral(uint256 totalIntegral, uint32 lastUpdatedAt) internal virtual;

  function internalGetRateIntegral(uint32 from, uint32 till) internal virtual returns (uint256);

  function internalCalcRateIntegral(uint32 from, uint32 till) internal view virtual returns (uint256);

  function internalAddYieldExcess(uint256 value) internal virtual {
    _updateTotal(value);
  }

  function _syncTotal() private view returns (uint256 totalIntegral) {
    uint32 lastUpdatedAt;
    (totalIntegral, lastUpdatedAt) = internalGetTimeIntegral();

    uint32 at = uint32(block.timestamp);
    if (at != lastUpdatedAt) {
      uint256 totalStaked = _totalStakedCollateral;
      if (totalStaked != 0) {
        totalIntegral += internalCalcRateIntegral(lastUpdatedAt, at).rayDiv(totalStaked);
      }
    }
  }

  function internalSyncTotal() internal {
    _updateTotal(0);
  }

  function _updateTotal(uint256 extra) private returns (uint256 totalIntegral, uint256 totalStaked) {
    uint32 lastUpdatedAt;
    (totalIntegral, lastUpdatedAt) = internalGetTimeIntegral();

    uint32 at = uint32(block.timestamp);
    if (at != lastUpdatedAt) {
      extra += internalGetRateIntegral(lastUpdatedAt, at);
    } else if (extra == 0) {
      return (totalIntegral, totalStaked);
    }
    if ((totalStaked = _totalStakedCollateral) != 0) {
      totalIntegral += extra.rayDiv(totalStaked);
      internalSetTimeIntegral(totalIntegral, at);
    }
  }

  function _syncAnyAsset(AssetBalance memory assetBalance, uint256 totalIntegral) private pure {
    uint256 d = totalIntegral - assetBalance.totalIntegral;
    if (d != 0) {
      assetBalance.totalIntegral = totalIntegral.asUint128();
      assetBalance.assetIntegral += d.rayMul(assetBalance.collateralFactor).asUint128();
    }
  }

  event AssetUpdated(address indexed asset, uint256 stakedTotal, uint256 collateralFactor);

  function _updateAsset(
    IYieldStakeAsset asset,
    uint256 collateralFactor,
    uint128 incAmount,
    uint128 decAmount,
    bool ignorePause
  ) private returns (uint128) {
    AssetBalance memory assetBalance = _assetBalances[asset];
    _ensureActiveAsset(assetBalance.flags, ignorePause);

    (uint256 totalIntegral, uint256 totalStaked) = _updateTotal(0);

    uint256 prevCollateral = uint256(assetBalance.stakedTokenTotal).rayMul(assetBalance.collateralFactor);

    _syncAnyAsset(assetBalance, totalIntegral);
    assetBalance.collateralFactor = collateralFactor.asUint112();
    assetBalance.stakedTokenTotal = (assetBalance.stakedTokenTotal - decAmount) + incAmount;

    uint256 newCollateral = uint256(assetBalance.stakedTokenTotal).rayMul(collateralFactor);

    emit AssetUpdated(address(asset), assetBalance.stakedTokenTotal, collateralFactor);

    _assetBalances[asset] = assetBalance;

    if (newCollateral != prevCollateral) {
      if (totalStaked == 0) {
        totalStaked = _totalStakedCollateral;
      }
      internalOnStakedCollateralChanged(totalStaked, _totalStakedCollateral = (totalStaked + newCollateral - prevCollateral).asUint128());
    }

    return assetBalance.assetIntegral;
  }

  function internalOnStakedCollateralChanged(uint256 prevStaked, uint256 newStaked) internal virtual {}

  event StakeUpdated(address indexed asset, address indexed account, uint256 staked);

  function _updateAssetAndUser(
    IYieldStakeAsset asset,
    uint112 incAmount,
    uint112 decAmount,
    address account
  ) private {
    uint256 collateralFactor = asset.collateralSupply().rayDiv(asset.totalSupply());
    uint128 assetIntegral = _updateAsset(asset, collateralFactor, incAmount, decAmount, false);

    Value.require(account != address(0));

    UserAssetBalance storage balance = _userAssetBalances[asset][account];

    uint256 d = assetIntegral - balance.assetIntegral;
    uint112 stakedTokenAmount = balance.stakedTokenAmount;

    if (d != 0 && stakedTokenAmount != 0) {
      balance.assetIntegral = assetIntegral;
      _userBalances[account].yieldBalance += d.rayMul(stakedTokenAmount).asUint128();
    }

    mapping(uint256 => IYieldStakeAsset) storage listing = _userAssets[account];

    //    console.log('stakedTokenAmount', stakedTokenAmount, decAmount, incAmount);
    uint256 balanceAfter = (stakedTokenAmount - decAmount) + incAmount;
    if (balanceAfter == 0) {
      if (stakedTokenAmount != 0) {
        // remove asset
        uint16 index = _userBalances[account].assetCount--;
        uint16 assetIndex = balance.assetIndex;
        if (assetIndex != index) {
          State.require(assetIndex < index);
          IYieldStakeAsset a = listing[assetIndex] = listing[index];
          _userAssetBalances[a][account].assetIndex = assetIndex;
        } else {
          delete _userAssetBalances[asset][account];
          delete listing[assetIndex];
        }
      }
    } else if (stakedTokenAmount == 0) {
      // add asset
      uint16 index = ++_userBalances[account].assetCount;
      balance.assetIndex = index;
      _userAssets[account][index] = asset;
    }
    balance.stakedTokenAmount = balanceAfter.asUint112();

    emit StakeUpdated(address(asset), account, balanceAfter);
  }

  function _syncPresentAsset(IYieldStakeAsset asset, uint256 totalIntegral) private view returns (AssetBalance memory assetBalance) {
    assetBalance = _assetBalances[asset];
    State.require(assetBalance.flags & FLAG_ASSET_PRESENT != 0);
    _syncAnyAsset(assetBalance, totalIntegral);
  }

  function balanceOf(address account) external view returns (uint256 yieldBalance) {
    if (account == address(0)) {
      return 0;
    }

    UserBalance storage ub = _userBalances[account];
    mapping(uint256 => IYieldStakeAsset) storage listing = _userAssets[account];

    yieldBalance = ub.yieldBalance;
    uint256 totalIntegral = _syncTotal();

    for (uint256 i = ub.assetCount; i > 0; i--) {
      IYieldStakeAsset asset = listing[i];
      State.require(address(asset) != address(0));

      AssetBalance memory assetBalance = _syncPresentAsset(asset, totalIntegral);

      UserAssetBalance storage balance = _userAssetBalances[asset][account];

      uint256 d = assetBalance.assetIntegral - balance.assetIntegral;
      if (d != 0) {
        uint112 stakedTokenAmount = balance.stakedTokenAmount;
        if (stakedTokenAmount != 0) {
          yieldBalance += d.rayMul(stakedTokenAmount);
        }
      }
    }
  }

  function stakedBalanceOf(address asset, address account) external view returns (uint256) {
    return _userAssetBalances[IYieldStakeAsset(asset)][account].stakedTokenAmount;
  }

  function claimYield(address to) external returns (uint256) {
    address account = msg.sender;
    (uint256 yieldBalance, uint256 i) = _claimCollectedYield(account);

    (uint256 totalIntegral, ) = _updateTotal(0);
    mapping(uint256 => IYieldStakeAsset) storage listing = _userAssets[account];

    for (; i > 0; i--) {
      IYieldStakeAsset asset = listing[i];
      State.require(address(asset) != address(0));
      yieldBalance += _claimYield(asset, account, totalIntegral);
    }

    return _transferYield(account, yieldBalance, to);
  }

  function claimYieldFrom(address to, address[] calldata assets) external returns (uint256) {
    address account = msg.sender;
    (uint256 yieldBalance, ) = _claimCollectedYield(account);

    (uint256 totalIntegral, ) = _updateTotal(0);

    for (uint256 i = assets.length; i > 0; ) {
      i--;
      address asset = assets[i];
      Value.require(asset != address(0));
      yieldBalance += _claimYield(IYieldStakeAsset(asset), account, totalIntegral);
    }

    return _transferYield(account, yieldBalance, to);
  }

  function _claimCollectedYield(address account) private returns (uint256 yieldBalance, uint16) {
    Value.require(account != address(0));

    UserBalance storage ub = _userBalances[account];
    yieldBalance = ub.yieldBalance;
    if (yieldBalance > 0) {
      _userBalances[account].yieldBalance = 0;
    }
    return (yieldBalance, ub.assetCount);
  }

  function _claimYield(
    IYieldStakeAsset asset,
    address account,
    uint256 totalIntegral
  ) private returns (uint256 yieldBalance) {
    AssetBalance memory assetBalance = _syncPresentAsset(asset, totalIntegral);
    if (assetBalance.flags & FLAG_ASSET_PAUSED != 0) {
      return 0;
    }

    UserAssetBalance storage balance = _userAssetBalances[asset][account];

    uint256 d = assetBalance.assetIntegral - balance.assetIntegral;

    if (d != 0) {
      uint112 stakedTokenAmount = balance.stakedTokenAmount;
      if (stakedTokenAmount != 0) {
        _assetBalances[asset] = assetBalance;
        balance.assetIntegral = assetBalance.assetIntegral;

        yieldBalance = d.rayMul(stakedTokenAmount);
      }
    }
  }

  event YieldClaimed(address indexed account, uint256 amount);

  function _transferYield(
    address account,
    uint256 amount,
    address to
  ) private returns (uint256) {
    if (amount > 0) {
      IManagedCollateralCurrency cc = IManagedCollateralCurrency(collateral());
      uint256 availableYield = cc.balanceOf(address(this));
      if (availableYield < amount) {
        if (internalPullYield(availableYield, amount)) {
          availableYield = cc.balanceOf(address(this));
        }
        if (availableYield < amount) {
          _userBalances[account].yieldBalance += (amount - availableYield).asUint128();
          amount = availableYield;
        }
      }
      if (amount != 0) {
        cc.transferOnBehalf(account, to, amount);
      }
    }

    emit YieldClaimed(account, amount);
    return amount;
  }

  function internalPullYield(uint256 availableYield, uint256 requestedYield) internal virtual returns (bool);

  function totalStakedCollateral() public view returns (uint256) {
    return _totalStakedCollateral;
  }

  function totalBorrowedCollateral() external view returns (uint256) {
    return _totalBorrowedCollateral;
  }

  event CollateralBorrowUpdate(uint256 totalStakedCollateral, uint256 totalBorrowedCollateral);

  function internalApplyBorrow(uint256 value) internal {
    uint256 totalBorrowed = _totalBorrowedCollateral + value;
    uint256 totalStaked = _totalStakedCollateral;

    State.require(totalBorrowed <= totalStaked);

    _totalBorrowedCollateral = totalBorrowed.asUint128();

    emit CollateralBorrowUpdate(totalStaked, totalBorrowed);
  }

  function internalApplyRepay(uint256 value) internal {
    emit CollateralBorrowUpdate(_totalStakedCollateral, _totalBorrowedCollateral = uint128(_totalBorrowedCollateral - value));
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '../tools/SafeERC20.sol';
import '../tools/math/Math.sol';
import '../tools/math/WadRayMath.sol';
import '../tools/math/PercentageMath.sol';
import '../interfaces/IManagedCollateralCurrency.sol';
import '../interfaces/ICollateralStakeManager.sol';
import '../access/AccessHelper.sol';

import '../access/AccessHelper.sol';
import './interfaces/ICollateralFund.sol';
import './Collateralized.sol';

abstract contract YieldStreamerBase is Collateralized {
  using SafeERC20 for IERC20;
  using Math for uint256;
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using EnumerableSet for EnumerableSet.AddressSet;

  uint32 private _rateCutOffAt;
  uint96 private _yieldRate;
  uint128 private _yieldDebt;

  uint16 private _pullableCount;
  uint16 private _lastPullable;
  mapping(uint256 => PullableSource) private _pullableSources;
  mapping(address => YieldSource) private _sources;

  struct YieldSource {
    uint16 pullableIndex;
    uint32 appliedSince;
    uint96 expectedRate;
  }

  struct PullableSource {
    uint8 sourceType;
    address source;
  }

  function internalGetYieldInfo()
    internal
    view
    returns (
      uint256 rate,
      uint256 debt,
      uint32 cutOff
    )
  {
    return (_yieldRate, _yieldDebt, _rateCutOffAt);
  }

  function internalCalcRateIntegral(uint32 from, uint32 till) internal view virtual returns (uint256 v) {
    v = _calcDiff(from, till);
    if (v > 0) {
      v = v.boundedSub(_yieldDebt);
    }
  }

  function internalGetRateIntegral(uint32 from, uint32 till) internal virtual returns (uint256 v) {
    v = _calcDiff(from, till);
    if (v > 0) {
      uint256 yieldDebt = _yieldDebt;
      if (yieldDebt > 0) {
        (v, yieldDebt) = v.boundedSub2(yieldDebt);
        _yieldDebt = uint128(yieldDebt);
      }
    }
  }

  function internalSetRateCutOff(uint32 at) internal {
    _rateCutOffAt = at;
  }

  function _calcDiff(uint32 from, uint32 till) private view returns (uint256) {
    uint32 cutOff = _rateCutOffAt;
    if (cutOff > 0) {
      if (from >= cutOff) {
        return 0;
      }
      if (till > cutOff) {
        till = cutOff;
      }
    }
    return till == from ? 0 : uint256(_yieldRate) * (till - from);
  }

  function internalAddYieldExcess(uint256) internal virtual;

  // NB! Total integral must be synced before calling this method
  function internalAddYieldPayout(
    address source,
    uint256 amount,
    uint256 expectedRate
  ) internal {
    YieldSource storage s = _sources[source];
    State.require(s.appliedSince != 0);

    uint32 at = uint32(block.timestamp);
    uint256 lastRate = s.expectedRate;

    uint256 expectedAmount = uint256(at - s.appliedSince) * lastRate + _yieldDebt;
    s.appliedSince = at;

    if (expectedAmount > amount) {
      _yieldDebt = (expectedAmount - amount).asUint128();
    } else {
      _yieldDebt = 0;
      if (expectedAmount < amount) {
        internalAddYieldExcess(amount - expectedAmount);
      }
    }

    if (lastRate != expectedRate) {
      s.expectedRate = expectedRate.asUint96();
      _yieldRate = (uint256(_yieldRate) + expectedRate - lastRate).asUint96();
    }
  }

  event YieldSourceAdded(address indexed source, uint8 sourceType);
  event YieldSourceRemoved(address indexed source);

  function internalAddYieldSource(address source, uint8 sourceType) internal {
    Value.require(source != address(0));
    Value.require(sourceType != uint8(YieldSourceType.None));

    YieldSource storage s = _sources[source];
    State.require(s.appliedSince == 0);
    s.appliedSince = uint32(block.timestamp);

    if (sourceType > uint8(YieldSourceType.Passive)) {
      PullableSource storage ps = _pullableSources[s.pullableIndex = ++_pullableCount];
      ps.source = source;
      ps.sourceType = sourceType;
    }
    emit YieldSourceAdded(source, sourceType);
  }

  // NB! Total integral must be synced before calling this method
  function internalRemoveYieldSource(address source) internal returns (bool ok) {
    YieldSource storage s = _sources[source];
    if (ok = (s.appliedSince != 0)) {
      internalAddYieldPayout(source, 0, 0);
      uint16 pullableIndex = s.pullableIndex;
      if (pullableIndex > 0) {
        uint16 index = _pullableCount--;
        if (pullableIndex != index) {
          State.require(pullableIndex < index);
          _sources[(_pullableSources[pullableIndex] = _pullableSources[index]).source].pullableIndex = pullableIndex;
        }
      }
      emit YieldSourceRemoved(source);
    }
    delete _sources[source];
  }

  function internalIsYieldSource(address source) internal view returns (bool) {
    return _sources[source].appliedSince != 0;
  }

  function internalGetYieldSource(address source)
    internal
    view
    returns (
      uint8 sourceType,
      uint96 expectedRate,
      uint32 since
    )
  {
    YieldSource storage s = _sources[source];
    if ((since = s.appliedSince) != 0) {
      expectedRate = s.expectedRate;
      uint16 index = s.pullableIndex;
      sourceType = index == 0 ? uint8(YieldSourceType.Passive) : _pullableSources[index].sourceType;
    }
  }

  event YieldSourcePulled(address indexed source, uint256 amount);

  function internalPullYield(uint256 availableYield, uint256 requestedYield) internal virtual returns (bool foundMore) {
    uint256 count = _pullableCount;
    if (count == 0) {
      return false;
    }

    uint256 i = _lastPullable;
    if (i > count) {
      i = 0;
    }

    for (uint256 n = count; n > 0; n--) {
      i = 1 + (i % count);

      PullableSource storage ps = _pullableSources[i];
      uint256 collectedYield = internalPullYieldFrom(ps.sourceType, ps.source);

      if (collectedYield > 0) {
        emit YieldSourcePulled(ps.source, collectedYield);
        foundMore = true;
      }

      if ((availableYield += collectedYield) >= requestedYield) {
        break;
      }
    }
    _lastPullable = uint16(i);
  }

  function internalPullYieldFrom(uint8 sourceType, address source) internal virtual returns (uint256);
}

enum YieldSourceType {
  None,
  Passive
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../interfaces/ICollateralized.sol';

interface ICollateralFund is ICollateralized {
  function setApprovalsFor(
    address operator,
    uint256 access,
    bool approved
  ) external;

  function setAllApprovalsFor(address operator, uint256 access) external;

  function getAllApprovalsFor(address account, address operator) external view returns (uint256);

  function isApprovedFor(
    address account,
    address operator,
    uint256 access
  ) external view returns (bool);

  function deposit(
    address account,
    address token,
    uint256 tokenAmount
  ) external returns (uint256);

  function invest(
    address account,
    address token,
    uint256 tokenAmount,
    address investTo
  ) external returns (uint256);

  function investIncludingDeposit(
    address account,
    uint256 depositValue,
    address token,
    uint256 tokenAmount,
    address investTo
  ) external returns (uint256);

  function withdraw(
    address account,
    address to,
    address token,
    uint256 amount
  ) external returns (uint256);

  function assets() external view returns (address[] memory);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/tokens/ERC20BalancelessBase.sol';
import '../tools/tokens/ERC1363ReceiverBase.sol';
import '../tools/math/PercentageMath.sol';
import '../tools/math/WadRayMath.sol';
import '../tools/upgradeability/Delegator.sol';
import '../libraries/Balances.sol';
import '../interfaces/IInsurerPool.sol';
import '../interfaces/IInsuredPool.sol';
import '../funds/Collateralized.sol';
import './InsurerJoinBase.sol';

/// @title Direct Pool Base
/// @notice Handles capital providing actions involving adding coverage DIRECTLY to an insured
abstract contract DirectPoolBase is
  ICancellableCoverage,
  IPerpetualInsurerPool,
  Collateralized,
  InsurerJoinBase,
  ERC20BalancelessBase,
  ERC1363ReceiverBase
{
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using Balances for Balances.RateAcc;

  address private _insured;

  mapping(address => Balances.RateAcc) private _premiums;
  mapping(address => uint256) private _balances;

  uint256 private _totalBalance;
  uint224 private _inverseExchangeRate;
  uint32 private _cancelledAt;

  function exchangeRate() public view override returns (uint256) {
    return WadRayMath.RAY - _inverseExchangeRate;
  }

  function _onlyActiveInsured() private view {
    require(msg.sender == _insured && _cancelledAt == 0);
  }

  modifier onlyActiveInsured() {
    _onlyActiveInsured();
    _;
  }

  function _onlyInsured() private view {
    require(msg.sender == _insured);
  }

  modifier onlyInsured() {
    _onlyInsured();
    _;
  }

  function charteredDemand() external pure override returns (bool) {
    return false;
  }

  function _beforeBalanceUpdate(address account) private view returns (Balances.RateAcc memory) {
    return _beforeBalanceUpdate(account, uint32(block.timestamp));
  }

  function _beforeBalanceUpdate(address account, uint32 at) private view returns (Balances.RateAcc memory) {
    return _premiums[account].sync(at);
  }

  function cancelCoverage(address insured, uint256 payoutRatio) external override onlyActiveInsured returns (uint256 payoutValue) {
    require(insured == msg.sender);

    uint256 total = _totalBalance.rayMul(exchangeRate());

    if (payoutRatio > 0) {
      payoutValue = total.rayMul(payoutRatio);
      // slither-disable-next-line events-maths
      _inverseExchangeRate = uint96(WadRayMath.RAY - (total - payoutValue).rayDiv(total).rayMul(exchangeRate()));
      total -= payoutValue;
    }

    if (total > 0) {
      transferCollateralFrom(msg.sender, address(this), total);
    }

    _cancelledAt = uint32(block.timestamp);
  }

  function internalMintForCoverage(address account, uint256 providedAmount) internal returns (uint256 excess) {
    require(account != address(0));
    require(_cancelledAt == 0);

    (uint256 coverageAmount, uint256 ratePoints) = IInsuredPool(_insured).offerCoverage(providedAmount);
    if (providedAmount > coverageAmount) {
      excess = providedAmount - coverageAmount;
    }

    Balances.RateAcc memory b = _beforeBalanceUpdate(account);
    require((b.rate = uint96(ratePoints + b.rate)) >= ratePoints);
    _premiums[account] = b;

    emit Transfer(address(0), account, coverageAmount);

    coverageAmount = coverageAmount.rayDiv(exchangeRate());
    _balances[account] += coverageAmount;
    _totalBalance += coverageAmount;
  }

  function internalBurnAll(address account) internal returns (uint256 coverageAmount) {
    uint32 cancelledAt = _cancelledAt;
    require(cancelledAt != 0);

    coverageAmount = _balances[account];
    delete _balances[account];
    _totalBalance -= coverageAmount;

    Balances.RateAcc memory b = _beforeBalanceUpdate(account, cancelledAt);
    b.rate = 0;
    _premiums[account] = b;

    coverageAmount = coverageAmount.rayMul(exchangeRate());
    emit Transfer(account, address(0), coverageAmount);

    return coverageAmount;
  }

  function balanceOf(address account) public view override returns (uint256) {
    return uint256(_balances[account]).rayMul(exchangeRate());
  }

  function balancesOf(address account)
    public
    view
    returns (
      uint256 coverageAmount,
      uint256 rate,
      uint256 premium
    )
  {
    coverageAmount = balanceOf(account);
    (rate, premium) = interestOf(account);
  }

  function totalSupply() public view override returns (uint256) {
    return _totalBalance.rayMul(exchangeRate());
  }

  function interestOf(address account) public view override returns (uint256 rate, uint256 accumulated) {
    Balances.RateAcc memory b = _premiums[account];
    uint32 at = _cancelledAt;
    if (at == 0) {
      rate = b.rate;
      at = uint32(block.timestamp);
    }
    accumulated = b.sync(at).accum;
  }

  /// @notice Get the status of the insured account
  /// @param account The account to query
  /// @return status The status of the insured. NotApplicable if the caller is an investor
  function statusOf(address account) external view returns (MemberStatus status) {
    if ((status = internalGetStatus(account)) == MemberStatus.Unknown && internalIsInvestor(account)) {
      status = MemberStatus.NotApplicable;
    }
    return status;
  }

  /// @notice Transfer a balance to a recipient, syncs the balances before performing the transfer
  /// @param sender  The sender
  /// @param recipient The receiver
  /// @param amount  Amount to transfer
  function transferBalance(
    address sender,
    address recipient,
    uint256 amount
  ) internal override {
    amount = amount.rayDiv(exchangeRate());
    uint96 ratePoints;

    Balances.RateAcc memory b;
    {
      b = _beforeBalanceUpdate(sender);

      uint256 bal = _balances[sender];
      ratePoints = uint96((b.rate * (amount + (bal >> 1))) / bal);
      b.rate -= ratePoints;

      _balances[sender] = bal - amount;
      _premiums[sender] = b;
    }

    {
      b = _beforeBalanceUpdate(recipient);
      b.rate += ratePoints;

      _balances[recipient] += amount;
      _premiums[sender] = b;
    }
  }

  function internalPrepareJoin(address) internal pure override returns (bool) {
    return true;
  }

  function internalInitiateJoin(address account) internal override returns (MemberStatus) {
    address insured = _insured;
    if (insured == address(0)) {
      _insured = account;
    } else if (insured != account) {
      return MemberStatus.JoinRejected;
    }

    return MemberStatus.Accepted;
  }

  function internalGetStatus(address account) internal view override returns (MemberStatus) {
    return _insured == account ? (_cancelledAt == 0 ? MemberStatus.Accepted : MemberStatus.Declined) : MemberStatus.Unknown;
  }

  function internalSetStatus(address account, MemberStatus s) internal override {
    // TODO check?
  }

  function internalIsInvestor(address account) internal view override returns (bool) {
    address insured = _insured;
    if (insured != address(0)) {
      return insured != account;
    }

    return _balances[account] > 0 || _premiums[account].accum > 0;
  }

  function internalReceiveTransfer(
    address operator,
    address account,
    uint256 amount,
    bytes calldata data
  ) internal override onlyCollateralCurrency {
    require(data.length == 0);
    if (internalGetStatus(operator) == MemberStatus.Unknown) {
      uint256 excess = internalMintForCoverage(account, amount);
      if (excess > 0) {
        transferCollateral(account, amount);
      }
    } else {
      // return of funds from insured
    }
  }

  function withdrawable(address account) public view override returns (uint256 amount) {
    return _cancelledAt == 0 ? 0 : balanceOf(account);
  }

  function withdrawAll() external override returns (uint256) {
    return _cancelledAt == 0 ? 0 : internalBurnAll(msg.sender);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../WeightedRoundsBase.sol';

contract MockWeightedRounds is WeightedRoundsBase {
  uint256 public excessCoverage;

  constructor(uint256 unitSize) WeightedRoundsBase(unitSize) {}

  function addInsured(address insured) external {
    internalSetInsuredStatus(insured, MemberStatus.Accepted);
  }

  function addCoverageDemand(
    address insured,
    uint64 unitCount,
    uint40 premiumRate,
    bool hasMore
  ) external returns (uint64) {
    AddCoverageDemandParams memory params;
    params.insured = insured;
    params.premiumRate = premiumRate;
    params.loopLimit = ~params.loopLimit;
    hasMore;

    return super.internalAddCoverageDemand(unitCount, params);
  }

  uint16 private _maxAddUnitsPerRound = 1;
  uint16 private _minUnitsPerRound = 2;
  uint16 private _maxUnitsPerRound = 3;

  function setRoundLimits(
    uint16 maxAddUnitsPerRound,
    uint16 minUnitsPerRound,
    uint16 maxUnitsPerRound
  ) external {
    _maxAddUnitsPerRound = maxAddUnitsPerRound;
    _minUnitsPerRound = minUnitsPerRound;
    _maxUnitsPerRound = maxUnitsPerRound;
  }

  function internalRoundLimits(
    uint80,
    uint24,
    uint16,
    uint64,
    uint16
  )
    internal
    view
    override
    returns (
      uint16,
      uint16,
      uint16,
      uint16
    )
  {
    return (_maxAddUnitsPerRound, _minUnitsPerRound, _maxUnitsPerRound, _maxUnitsPerRound);
  }

  uint32 private _splitRounds = type(uint32).max;

  function setBatchSplit(uint32 splitRounds) external {
    _splitRounds = splitRounds;
  }

  function internalBatchSplit(
    uint64,
    uint64,
    uint24,
    uint24 remainingUnits
  ) internal view override returns (uint24) {
    return _splitRounds <= type(uint24).max ? uint24(_splitRounds) : remainingUnits;
  }

  function internalBatchAppend(
    uint80,
    uint32,
    uint64 unitCount
  ) internal pure override returns (uint24) {
    return unitCount > type(uint24).max ? type(uint24).max : uint24(unitCount);
  }

  function addCoverage(uint256 amount) external {
    (amount, , , ) = super.internalAddCoverage(amount, type(uint256).max);
    excessCoverage += amount;
  }

  function dump() external view returns (Dump memory) {
    return _dump();
  }

  function getTotals() external view returns (DemandedCoverage memory coverage, TotalCoverage memory total) {
    return internalGetTotals(type(uint256).max);
  }

  function receivableDemandedCoverage(address insured) external view returns (uint256 availableCoverage, DemandedCoverage memory coverage) {
    GetCoveredDemandParams memory params;
    params.insured = insured;
    params.loopLimit = ~params.loopLimit;

    (coverage, , ) = internalGetCoveredDemand(params);
    return (params.receivedCoverage, coverage);
  }

  uint256 public receivedCoverage;

  function receiveDemandedCoverage(address insured, uint16 loopLimit) external returns (DemandedCoverage memory coverage) {
    GetCoveredDemandParams memory params;
    params.insured = insured;
    params.loopLimit = loopLimit;

    coverage = internalUpdateCoveredDemand(params);
    receivedCoverage += params.receivedCoverage;
  }

  function internalIsEnoughForMore(Rounds.InsuredEntry memory entry, uint256 unitCount) internal view override returns (bool) {}
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../PerpetualPoolBase.sol';
import './MockWeightedRounds.sol';

contract MockPerpetualPool is IInsurerGovernor, PerpetualPoolBase {
  constructor(PerpetualPoolExtension extension, JoinablePoolExtension joinExtension)
    ERC20DetailsBase('PerpetualPoolToken', '$IC', 18)
    PerpetualPoolBase(extension, joinExtension)
  {
    internalSetTypedGovernor(this);
    internalSetPoolParams(
      WeightedPoolParams({
        maxAdvanceUnits: 10000,
        minAdvanceUnits: 1000,
        riskWeightTarget: 1000, // 10%
        minInsuredSharePct: 100, // 1%
        maxInsuredSharePct: 4000, // 40%
        minUnitsPerRound: 20,
        maxUnitsPerRound: 20,
        overUnitsPerRound: 30,
        coveragePrepayPct: 10000, // 100%
        maxUserDrawdownPct: 0, // 0%
        unitsPerAutoPull: 0
      })
    );
  }

  function getRevision() internal pure override returns (uint256) {}

  function handleJoinRequest(address) external pure override returns (MemberStatus) {
    return MemberStatus.Accepted;
  }

  function governerQueryAccessControlMask(address, uint256 filterMask) external pure override returns (uint256) {
    return filterMask;
  }

  function getTotals() external view returns (DemandedCoverage memory coverage, TotalCoverage memory total) {
    return internalGetTotals(type(uint256).max);
  }

  function getExcessCoverage() external view returns (uint256) {
    return _excessCoverage;
  }

  function setExcessCoverage(uint256 v) external {
    internalSetExcess(v);
  }

  function internalOnCoverageRecovered() internal override {}

  function dump() external view returns (Dump memory) {
    return _dump();
  }

  function getPendingAdjustments()
    external
    view
    returns (
      uint256 total,
      uint256 pendingCovered,
      uint256 pendingDemand
    )
  {
    return internalGetUnadjustedUnits();
  }

  function applyPendingAdjustments() external {
    internalApplyAdjustmentsToTotals();
  }

  function hasAnyAcl(address, uint256) internal pure override returns (bool) {
    return true;
  }

  function hasAllAcl(address, uint256) internal pure override returns (bool) {
    return true;
  }

  function isAdmin(address) internal pure override returns (bool) {
    return true;
  }

  uint16 private _riskWeightValue;
  address private _expectedPremiumToken;

  function approveNextJoin(uint16 riskWeightValue, address expectedPremiumToken) external {
    _riskWeightValue = riskWeightValue + 1;
    _expectedPremiumToken = expectedPremiumToken;
  }

  function verifyPayoutRatio(address, uint256 payoutRatio) external pure override returns (uint256) {
    return payoutRatio;
  }

  function getApprovedPolicyForInsurer(address) external override returns (bool ok, IApprovalCatalog.ApprovedPolicyForInsurer memory data) {
    data.riskLevel = _riskWeightValue;
    if (data.riskLevel > 0) {
      _riskWeightValue = 0;
      data.riskLevel--;
      data.premiumToken = _expectedPremiumToken;
      ok = true;
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../ImperpetualPoolBase.sol';
import './MockWeightedRounds.sol';

contract MockImperpetualPool is IInsurerGovernor, ImperpetualPoolBase {
  constructor(ImperpetualPoolExtension extension, JoinablePoolExtension joinExtension)
    ERC20DetailsBase('ImperpetualPoolToken', '$IC', 18)
    ImperpetualPoolBase(extension, joinExtension)
  {
    internalSetTypedGovernor(this);
    internalSetPoolParams(
      WeightedPoolParams({
        maxAdvanceUnits: 10000,
        minAdvanceUnits: 1000,
        riskWeightTarget: 1000, // 10%
        minInsuredSharePct: 100, // 1%
        maxInsuredSharePct: 4000, // 40%
        minUnitsPerRound: 20,
        maxUnitsPerRound: 20,
        overUnitsPerRound: 30,
        coveragePrepayPct: 9000, // 90%
        maxUserDrawdownPct: 1000, // 10%
        unitsPerAutoPull: 0
      })
    );
  }

  function getRevision() internal pure override returns (uint256) {}

  function handleJoinRequest(address) external pure override returns (MemberStatus) {
    return MemberStatus.Accepted;
  }

  function governerQueryAccessControlMask(address, uint256 filterMask) external pure override returns (uint256) {
    return filterMask;
  }

  function getTotals() external view returns (DemandedCoverage memory coverage, TotalCoverage memory total) {
    return internalGetTotals(type(uint256).max);
  }

  function getExcessCoverage() external view returns (uint256) {
    return _excessCoverage;
  }

  function setExcessCoverage(uint256 v) external {
    internalSetExcess(v);
  }

  function internalOnCoverageRecovered() internal override {}

  // function dump() external view returns (Dump memory) {
  //   return _dump();
  // }

  // function dumpInsured(address insured)
  //   external
  //   view
  //   returns (
  //     Rounds.InsuredEntry memory,
  //     Rounds.Demand[] memory,
  //     Rounds.Coverage memory,
  //     Rounds.CoveragePremium memory
  //   )
  // {
  //   return _dumpInsured(insured);
  // }

  function getPendingAdjustments()
    external
    view
    returns (
      uint256 total,
      uint256 pendingCovered,
      uint256 pendingDemand
    )
  {
    return internalGetUnadjustedUnits();
  }

  function applyPendingAdjustments() external {
    internalApplyAdjustmentsToTotals();
  }

  modifier onlyPremiumDistributor() override {
    _;
  }

  function hasAnyAcl(address, uint256) internal pure override returns (bool) {
    return true;
  }

  function hasAllAcl(address, uint256) internal pure override returns (bool) {
    return true;
  }

  function isAdmin(address) internal pure override returns (bool) {
    return true;
  }

  uint16 private _riskWeightValue;
  address private _expectedPremiumToken;

  function approveNextJoin(uint16 riskWeightValue, address expectedPremiumToken) external {
    _riskWeightValue = riskWeightValue + 1;
    _expectedPremiumToken = expectedPremiumToken;
  }

  function verifyPayoutRatio(address, uint256 payoutRatio) external pure override returns (uint256) {
    return payoutRatio;
  }

  function getApprovedPolicyForInsurer(address) external override returns (bool ok, IApprovalCatalog.ApprovedPolicyForInsurer memory data) {
    data.riskLevel = _riskWeightValue;
    if (data.riskLevel > 0) {
      _riskWeightValue = 0;
      data.riskLevel--;
      data.premiumToken = _expectedPremiumToken;
      ok = true;
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './ImperpetualPoolStorage.sol';
import './ImperpetualPoolExtension.sol';
import './WeightedPoolBase.sol';

/// @title Index Pool Base with Perpetual Index Pool Tokens
/// @notice Handles adding coverage by users.
abstract contract ImperpetualPoolBase is ImperpetualPoolStorage {
  using Math for uint256;
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using Balances for Balances.RateAcc;

  constructor(ImperpetualPoolExtension extension, JoinablePoolExtension joinExtension) WeightedPoolBase(extension, joinExtension) {}

  function _addCoverage(uint256 value)
    private
    returns (
      bool done,
      AddCoverageParams memory params,
      PartialState memory part
    )
  {
    uint256 excessCoverage = _excessCoverage;
    if (excessCoverage > 0 || value > 0) {
      uint256 newExcess;
      uint256 loopLimit;
      (newExcess, loopLimit, params, part) = super.internalAddCoverage(value + excessCoverage, defaultLoopLimit(LoopLimitType.AddCoverage, 0));

      if (newExcess != excessCoverage) {
        internalSetExcess(newExcess);
      }

      internalAutoPullDemand(params, loopLimit, newExcess > 0, value);

      done = true;
    }
  }

  /// @dev Updates the user's balance based upon the current exchange rate of $CC to $Pool_Coverage
  /// @dev Update the new amount of excess coverage
  function internalMintForCoverage(address account, uint256 value) internal override {
    (bool done, AddCoverageParams memory params, PartialState memory part) = _addCoverage(value);

    // TODO:TEST test adding coverage to an empty pool
    _mint(account, done ? value.rayDiv(exchangeRate(super.internalGetPremiumTotals(part, params.premium), value)) : 0, value);
  }

  function internalSubrogated(uint256 value) internal override {
    internalSetExcess(_excessCoverage + value);
    internalSyncStake();
  }

  function updateCoverageOnCancel(
    address insured,
    uint256 payoutValue,
    uint256 advanceValue,
    uint256 recoveredValue,
    uint256 premiumDebt
  ) external onlySelf returns (uint256) {
    uint256 givenOutValue = _insuredBalances[insured];
    require(givenOutValue <= advanceValue);

    delete _insuredBalances[insured];
    uint256 givenValue = givenOutValue + premiumDebt;
    bool syncStake;

    if (givenValue != payoutValue) {
      if (givenValue > payoutValue) {
        recoveredValue += advanceValue - givenValue;

        // try to take back the given coverage
        uint256 recovered = transferAvailableCollateralFrom(insured, address(this), givenValue - payoutValue);

        // only the outstanding premium debt should be deducted, an outstanding coverage debt is managed as reduction of coverage itself
        if (premiumDebt > recovered) {
          _decrementTotalValue(premiumDebt - recovered);
          syncStake = true;
        }

        recoveredValue += recovered;
      } else {
        uint256 underpay = payoutValue - givenValue;

        if (recoveredValue < underpay) {
          recoveredValue += _calcAvailableDrawdownReserve(recoveredValue + advanceValue);
          if (recoveredValue < underpay) {
            underpay = recoveredValue;
          }
          recoveredValue = 0;
        } else {
          recoveredValue -= underpay;
        }

        if (underpay > 0) {
          transferCollateral(insured, underpay);
        }
        payoutValue = givenValue + underpay;
      }
    }

    if (recoveredValue > 0) {
      internalSetExcess(_excessCoverage + recoveredValue);
      internalOnCoverageRecovered();
      syncStake = true;
    }
    if (syncStake) {
      internalSyncStake();
    }

    return payoutValue;
  }

  function updateCoverageOnReconcile(
    address insured,
    uint256 receivedCoverage,
    uint256 totalCovered
  ) external onlySelf returns (uint256) {
    uint256 expectedAmount = totalCovered.percentMul(_params.coveragePrepayPct);
    uint256 actualAmount = _insuredBalances[insured];

    if (actualAmount < expectedAmount) {
      uint256 d = expectedAmount - actualAmount;
      if (d < receivedCoverage) {
        receivedCoverage = d;
      }
      if ((d = balanceOfCollateral(address(this))) < receivedCoverage) {
        receivedCoverage = d;
      }

      if (receivedCoverage > 0) {
        _insuredBalances[insured] = actualAmount + receivedCoverage;
        transferCollateral(insured, receivedCoverage);
      }
    } else {
      receivedCoverage = 0;
    }

    return receivedCoverage;
  }

  function _decrementTotalValue(uint256 valueLoss) private {
    _valueAdjustment -= valueLoss.asInt128();
  }

  function _incrementTotalValue(uint256 valueGain) private {
    _valueAdjustment += valueGain.asInt128();
  }

  /// @dev Attempt to take the excess coverage and fill batches
  /// @dev Occurs when there is excess and a new batch is ready (more demand added)
  function pushCoverageExcess() public override {
    _addCoverage(0);
  }

  function totalSupplyValue(DemandedCoverage memory coverage, uint256 added) private view returns (uint256 v) {
    v = coverage.totalCovered - _burntDrawdown;
    v = (v + coverage.pendingCovered) - added;

    {
      int256 va = _valueAdjustment;
      if (va >= 0) {
        v += uint256(va);
      } else {
        v -= uint256(-va);
      }
    }
    v += coverage.totalPremium - _burntPremium;
    v += _excessCoverage;
  }

  function totalSupplyValue() public view returns (uint256) {
    return totalSupplyValue(super.internalGetPremiumTotals(), 0);
  }

  function exchangeRate(DemandedCoverage memory coverage, uint256 added) private view returns (uint256 v) {
    if ((v = totalSupply()) > 0) {
      v = totalSupplyValue(coverage, added).rayDiv(v);
    } else {
      v = WadRayMath.RAY;
    }
  }

  function exchangeRate() public view override returns (uint256 v) {
    return exchangeRate(super.internalGetPremiumTotals(), 0);
  }

  function balanceOf(address account) public view override returns (uint256) {
    return _balances[account].balance;
  }

  function balancesOf(address account)
    public
    view
    returns (
      uint256 coverage,
      uint256 scaled,
      uint256 premium
    )
  {
    scaled = balanceOf(account);
    coverage = scaled.rayMul(exchangeRate());
    premium;
  }

  ///@notice Transfer a balance to a recipient, syncs the balances before performing the transfer
  ///@param sender  The sender
  ///@param recipient The receiver
  ///@param amount  Amount to transfer
  function transferBalance(
    address sender,
    address recipient,
    uint256 amount
  ) internal override {
    _balances[sender].balance = uint128(_balances[sender].balance - amount);
    _balances[recipient].balance += uint128(amount);
  }

  function _burnValue(
    address account,
    uint256 value,
    DemandedCoverage memory coverage
  ) private returns (uint256 burntAmount) {
    _burn(account, burntAmount = value.rayDiv(exchangeRate(coverage, 0)), value);
  }

  function _burnPremium(
    address account,
    uint256 value,
    DemandedCoverage memory coverage
  ) internal returns (uint256 burntAmount) {
    require(coverage.totalPremium >= _burntPremium + value);
    burntAmount = _burnValue(account, value, coverage);
    _burntPremium += value.asUint128();
  }

  function _burnCoverage(
    address account,
    uint256 value,
    address recepient,
    DemandedCoverage memory coverage
  ) internal returns (uint256 burntAmount) {
    // NB! removed for performance reasons - use carefully
    // Value.require(value <= _calcAvailableUserDrawdown(totalCovered + pendingCovered));

    burntAmount = _burnValue(account, value, coverage);

    _burntDrawdown += value.asUint128();
    transferCollateral(recepient, value);
  }

  function internalBurnPremium(
    address account,
    uint256 value,
    address drawdownRecepient
  ) internal override {
    DemandedCoverage memory coverage = super.internalGetPremiumTotals();
    drawdownRecepient != address(0) ? _burnCoverage(account, value, drawdownRecepient, coverage) : _burnPremium(account, value, coverage);
  }

  function __calcAvailableDrawdown(uint256 totalCovered, uint16 maxDrawdown) internal view returns (uint256) {
    uint256 burntDrawdown = _burntDrawdown;
    totalCovered += _excessCoverage;
    totalCovered = totalCovered.percentMul(maxDrawdown);
    return totalCovered.boundedSub(burntDrawdown);
  }

  function _calcAvailableDrawdownReserve(uint256 extra) internal view returns (uint256) {
    return __calcAvailableDrawdown(_coveredTotal() + extra, PercentageMath.ONE - _params.coveragePrepayPct);
  }

  function _calcAvailableUserDrawdown() internal view returns (uint256) {
    return _calcAvailableUserDrawdown(_coveredTotal());
  }

  function _calcAvailableUserDrawdown(uint256 totalCovered) internal view returns (uint256) {
    return __calcAvailableDrawdown(totalCovered, _params.maxUserDrawdownPct);
  }

  function internalCollectDrawdownPremium() internal view override returns (uint256) {
    return _calcAvailableUserDrawdown();
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/tokens/ERC20BalancelessBase.sol';
import '../tools/Errors.sol';
import '../libraries/Balances.sol';
import './WeightedPoolBase.sol';

abstract contract ImperpetualPoolStorage is WeightedPoolBase, ERC20BalancelessBase {
  using Math for uint256;
  using WadRayMath for uint256;

  mapping(address => uint256) internal _insuredBalances; // [insured]

  uint128 private _totalSupply;

  uint128 internal _burntDrawdown;
  uint128 internal _burntPremium;

  /// @dev decreased on losses (e.g. premium underpaid or collateral loss), increased on external value streams, e.g. collateral yield
  int128 internal _valueAdjustment;

  function totalSupply() public view override(IERC20, WeightedPoolBase) returns (uint256) {
    return _totalSupply;
  }

  function _mint(
    address account,
    uint256 amount256,
    uint256 value
  ) internal {
    value;
    uint128 amount = amount256.asUint128();

    emit Transfer(address(0), account, amount);
    _totalSupply += amount;
    _balances[account].balance += amount;
  }

  function _burn(
    address account,
    uint256 amount256,
    uint256 value
  ) internal {
    uint128 amount = amount256.asUint128();

    emit Transfer(account, address(0), amount);
    _balances[account].balance -= amount;
    unchecked {
      // overflow doesnt matter much here
      _balances[account].extra += uint128(value);
    }
    _totalSupply -= amount;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './WeightedPoolExtension.sol';
import './ImperpetualPoolBase.sol';

/// @dev NB! MUST HAVE NO STORAGE
contract ImperpetualPoolExtension is WeightedPoolExtension {
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using Balances for Balances.RateAcc;

  constructor(
    IAccessController acl,
    uint256 unitSize,
    address collateral_
  ) WeightedPoolConfig(acl, unitSize, collateral_) {}

  function internalTransferCancelledCoverage(
    address insured,
    uint256 payoutValue,
    uint256 advanceValue,
    uint256 recoveredValue,
    uint256 premiumDebt
  ) internal override returns (uint256) {
    return ImperpetualPoolBase(address(this)).updateCoverageOnCancel(insured, payoutValue, advanceValue, recoveredValue, premiumDebt);
    // ^^ this call avoids code to be duplicated within PoolExtension to reduce contract size
  }

  function internalTransferDemandedCoverage(
    address insured,
    uint256 receivedCoverage,
    DemandedCoverage memory coverage
  ) internal override returns (uint256) {
    if (receivedCoverage > 0) {
      return ImperpetualPoolBase(address(this)).updateCoverageOnReconcile(insured, receivedCoverage, coverage.totalCovered);
      // ^^ this call avoids code to be duplicated within PoolExtension to reduce contract size
    }
    return receivedCoverage;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './ImperpetualPoolBase.sol';

contract ImperpetualPoolV1 is ImperpetualPoolBase, IWeightedPoolInit {
  uint256 private constant CONTRACT_REVISION = 1;
  uint8 internal constant DECIMALS = 18;

  constructor(ImperpetualPoolExtension extension, JoinablePoolExtension joinExtension)
    ERC20DetailsBase('', '', DECIMALS)
    ImperpetualPoolBase(extension, joinExtension)
  {}

  function initializeWeighted(
    address governor_,
    string calldata tokenName,
    string calldata tokenSymbol,
    WeightedPoolParams calldata params
  ) public override initializer(CONTRACT_REVISION) {
    _initializeERC20(tokenName, tokenSymbol, DECIMALS);
    internalSetGovernor(governor_);
    internalSetPoolParams(params);
  }

  function getRevision() internal pure override returns (uint256) {
    return CONTRACT_REVISION;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './ERC20Base.sol';
import './ERC20PermitBase.sol';

abstract contract ERC20BaseWithPermit is ERC20Base, ERC20PermitBase {
  constructor(
    string memory name_,
    string memory symbol_,
    uint8 decimals_
  ) ERC20Base(name_, symbol_, decimals_) ERC20PermitBase() {}

  function _approveByPermit(
    address owner,
    address spender,
    uint256 amount
  ) internal override {
    _approve(owner, spender, amount);
  }

  function _getPermitDomainName() internal view override returns (bytes memory) {
    return bytes(super.name());
  }
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

import '../../tools/tokens/ERC20Base.sol';

contract MockERC20 is ERC20Base {
  constructor(
    string memory name_,
    string memory symbol_,
    uint8 decimals_
  ) ERC20Base(name_, symbol_, decimals_) {}

  function mint(address to, uint256 amount) external {
    _mint(to, amount);
  }

  function burn(address from, uint256 amount) external {
    _burn(from, amount);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../tools/tokens/ERC20Base.sol';
import '../../tools/math/WadRayMath.sol';
import '../../interfaces/IYieldStakeAsset.sol';
import '../../interfaces/ICollateralStakeManager.sol';
import '../Collateralized.sol';

contract MockInsurerForYield is IYieldStakeAsset, Collateralized, ERC20Base {
  using WadRayMath for uint256;

  uint256 private _collateralSupplyFactor;

  constructor(address cc) Collateralized(cc) ERC20Base('Insured', '$IT0', 18) {
    _collateralSupplyFactor = WadRayMath.WAD;
  }

  function setCollateralSupplyFactor(uint256 collateralSupplyFactor) external {
    _collateralSupplyFactor = collateralSupplyFactor;
  }

  function totalSupply() public view override(IERC20, IYieldStakeAsset) returns (uint256) {
    return super.totalSupply();
  }

  function collateralSupply() public view override returns (uint256) {
    return super.totalSupply().wadMul(_collateralSupplyFactor);
  }

  function mint(address account, uint256 amount) external {
    _mint(account, amount);
  }

  function callSyncByAsset() external {
    ICollateralStakeManager m = ICollateralStakeManager(IManagedCollateralCurrency(collateral()).borrowManager());
    if (address(m) != address(0)) {
      m.syncByStakeAsset(totalSupply(), collateralSupply());
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '../tools/SafeERC20.sol';
import '../tools/math/WadRayMath.sol';
import '../tools/math/PercentageMath.sol';
import '../interfaces/IManagedCollateralCurrency.sol';
import '../interfaces/ICollateralStakeManager.sol';
import '../pricing/PricingHelper.sol';
import '../access/AccessHelper.sol';
import './interfaces/ICollateralFund.sol';
import './Collateralized.sol';

// TODO:TEST tests for zero return on price lockup

abstract contract CollateralFundBase is ICollateralFund, AccessHelper, PricingHelper {
  using SafeERC20 for IERC20;
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using EnumerableSet for EnumerableSet.AddressSet;

  IManagedCollateralCurrency private immutable _collateral;
  uint256 private immutable _sourceFuses;

  constructor(
    IAccessController acl,
    address collateral_,
    uint256 sourceFuses
  ) AccessHelper(acl) PricingHelper(_getPricerByAcl(acl)) {
    _collateral = IManagedCollateralCurrency(collateral_);
    _sourceFuses = sourceFuses;
  }

  struct CollateralAsset {
    uint8 assetFlags;
    address trustee;
  }

  struct BorrowBalance {
    uint128 amount;
    uint128 value;
  }

  uint8 private constant AF_ADDED = 1 << 7;

  EnumerableSet.AddressSet private _tokens;
  mapping(address => CollateralAsset) private _assets; // [token]
  mapping(address => mapping(address => BorrowBalance)) private _borrowedBalances; // [token][borrower]
  mapping(address => mapping(address => uint256)) private _approvals; // [owner][delegate]

  function _onlyApproved(
    address operator,
    address account,
    uint256 access
  ) private view {
    Access.require(operator == account || isApprovedFor(account, operator, access));
  }

  function _onlySpecial(address account, uint256 access) private view {
    Access.require(isApprovedFor(address(0), account, access));
  }

  modifier onlySpecial(address account, uint256 access) {
    _onlySpecial(account, access);
    _;
  }

  function remoteAcl() internal view override(AccessHelper, PricingHelper) returns (IAccessController pricer) {
    return AccessHelper.remoteAcl();
  }

  event ApprovalFor(address indexed owner, address indexed operator, uint256 approved);

  function setApprovalsFor(
    address operator,
    uint256 access,
    bool approved
  ) external override {
    uint256 flags;
    if (approved) {
      flags = (_approvals[msg.sender][operator] |= access);
    } else {
      flags = (_approvals[msg.sender][operator] &= ~access);
    }
    emit ApprovalFor(msg.sender, operator, flags);
  }

  function collateral() public view override returns (address) {
    return address(_collateral);
  }

  function setAllApprovalsFor(address operator, uint256 access) external override {
    _approvals[msg.sender][operator] = access;
    emit ApprovalFor(msg.sender, operator, access);
  }

  function getAllApprovalsFor(address account, address operator) public view override returns (uint256) {
    return _approvals[account][operator];
  }

  function isApprovedFor(
    address account,
    address operator,
    uint256 access
  ) public view override returns (bool) {
    return _approvals[account][operator] & access == access;
  }

  event SpecialApprovalFor(address indexed operator, uint256 approved);

  function internalSetSpecialApprovals(address operator, uint256 access) internal {
    _approvals[address(0)][operator] = access;
    emit SpecialApprovalFor(operator, access);
  }

  event TrusteeUpdated(address indexed token, address indexed trustedOperator);

  function internalSetTrustee(address token, address trustee) internal {
    CollateralAsset storage asset = _assets[token];
    State.require(asset.assetFlags & AF_ADDED != 0);
    asset.trustee = trustee;
    emit TrusteeUpdated(token, trustee);
  }

  function internalSetFlags(address token, uint8 flags) internal {
    CollateralAsset storage asset = _assets[token];
    State.require(asset.assetFlags & AF_ADDED != 0 && _tokens.contains(token));
    asset.assetFlags = AF_ADDED | flags;
  }

  event AssetAdded(address indexed token);
  event AssetRemoved(address indexed token);

  function internalAddAsset(address token, address trustee) internal virtual {
    Value.require(token != address(0));
    State.require(_tokens.add(token));

    _assets[token] = CollateralAsset({assetFlags: type(uint8).max, trustee: trustee});
    _attachSource(token, true);

    emit AssetAdded(token);
    if (trustee != address(0)) {
      emit TrusteeUpdated(token, trustee);
    }
  }

  function internalRemoveAsset(address token) internal {
    if (token != address(0) && _tokens.remove(token)) {
      CollateralAsset storage asset = _assets[token];
      asset.assetFlags = AF_ADDED;
      _attachSource(token, false);

      emit AssetRemoved(token);
    }
  }

  function _attachSource(address token, bool set) private {
    IManagedPriceRouter pricer = getPricer();
    if (address(pricer) != address(0)) {
      pricer.attachSource(token, set);
    }
  }

  function deposit(
    address account,
    address token,
    uint256 tokenAmount
  ) external override returns (uint256) {
    _ensureApproved(account, token, CollateralFundLib.APPROVED_DEPOSIT);
    return _depositAndMint(msg.sender, account, token, tokenAmount);
  }

  function invest(
    address account,
    address token,
    uint256 tokenAmount,
    address investTo
  ) external override returns (uint256) {
    _ensureApproved(account, token, CollateralFundLib.APPROVED_DEPOSIT | CollateralFundLib.APPROVED_INVEST);
    return _depositAndInvest(msg.sender, account, 0, token, tokenAmount, investTo);
  }

  function investIncludingDeposit(
    address account,
    uint256 depositValue,
    address token,
    uint256 tokenAmount,
    address investTo
  ) external override returns (uint256) {
    _ensureApproved(
      account,
      token,
      tokenAmount > 0 ? CollateralFundLib.APPROVED_DEPOSIT | CollateralFundLib.APPROVED_INVEST : CollateralFundLib.APPROVED_INVEST
    );
    return _depositAndInvest(msg.sender, account, depositValue, token, tokenAmount, investTo);
  }

  function internalPriceOf(address token) internal virtual returns (uint256) {
    return getPricer().pullAssetPrice(token, _sourceFuses);
  }

  function withdraw(
    address account,
    address to,
    address token,
    uint256 amount
  ) external override returns (uint256) {
    _ensureApproved(account, token, CollateralFundLib.APPROVED_WITHDRAW);
    return _withdraw(account, to, token, amount);
  }

  event AssetWithdrawn(address indexed token, address indexed account, uint256 amount, uint256 value);

  function _withdraw(
    address from,
    address to,
    address token,
    uint256 amount
  ) private returns (uint256) {
    if (amount > 0) {
      uint256 value;
      if (amount == type(uint256).max) {
        value = _collateral.balanceOf(from);
        if (value > 0) {
          uint256 price = internalPriceOf(token);
          if (price != 0) {
            amount = value.wadDiv(price);
          } else {
            value = 0;
          }
        }
      } else {
        value = amount.wadMul(internalPriceOf(token));
      }

      if (value > 0) {
        _collateral.burn(from, value);
        IERC20(token).safeTransfer(to, amount);

        emit AssetWithdrawn(token, from, amount, value);
        return amount;
      }
    }

    return 0;
  }

  function _ensureApproved(
    address account,
    address token,
    uint8 accessFlags
  ) private view returns (CollateralAsset storage asset) {
    return __ensureApproved(msg.sender, account, token, accessFlags);
  }

  function __ensureApproved(
    address operator,
    address account,
    address token,
    uint8 accessFlags
  ) private view returns (CollateralAsset storage asset) {
    _onlyApproved(operator, account, accessFlags);
    asset = _onlyActiveAsset(token, accessFlags);
  }

  function _onlyActiveAsset(address token, uint8 accessFlags) private view returns (CollateralAsset storage asset) {
    asset = _assets[token];
    uint8 flags = asset.assetFlags;
    State.require(flags & AF_ADDED != 0);
    if (flags & accessFlags != accessFlags) {
      if (_tokens.contains(token)) {
        revert Errors.OperationPaused();
      } else {
        revert Errors.IllegalState();
      }
    }
  }

  function internalIsTrusted(
    CollateralAsset storage asset,
    address operator,
    address token
  ) internal view virtual returns (bool) {
    token;
    return operator == asset.trustee;
  }

  function _ensureTrusted(
    address operator,
    address account,
    address token,
    uint8 accessFlags
  ) private view returns (CollateralAsset storage asset) {
    asset = __ensureApproved(operator, account, token, accessFlags);
    Access.require(internalIsTrusted(asset, msg.sender, token));
  }

  event AssetDeposited(address indexed token, address indexed account, uint256 amount, uint256 value);

  function __deposit(
    address from,
    address token,
    uint256 amount
  ) private returns (uint256 value, bool ok) {
    uint256 price = internalPriceOf(token);
    if (price != 0) {
      IERC20(token).safeTransferFrom(from, address(this), amount);
      value = amount.wadMul(price);
      ok = true;
    }
  }

  function _depositAndMint(
    address operator,
    address account,
    address token,
    uint256 tokenAmount
  ) private onlySpecial(account, CollateralFundLib.APPROVED_DEPOSIT) returns (uint256) {
    (uint256 value, bool ok) = __deposit(operator, token, tokenAmount);
    if (ok) {
      emit AssetDeposited(token, account, tokenAmount, value);
      _collateral.mint(account, value);
      return value;
    }
    return 0;
  }

  function _depositAndInvest(
    address operator,
    address account,
    uint256 depositValue,
    address token,
    uint256 tokenAmount,
    address investTo
  ) private returns (uint256) {
    (uint256 value, bool ok) = __deposit(operator, token, tokenAmount);
    if (ok) {
      emit AssetDeposited(token, account, tokenAmount, value);
      _collateral.mintAndTransfer(account, investTo, value, depositValue);
      return value + depositValue;
    }
    return 0;
  }

  function trustedDeposit(
    address operator,
    address account,
    address token,
    uint256 amount
  ) external returns (uint256) {
    _ensureTrusted(operator, account, token, CollateralFundLib.APPROVED_DEPOSIT);
    return _depositAndMint(operator, account, token, amount);
  }

  function trustedInvest(
    address operator,
    address account,
    uint256 depositValue,
    address token,
    uint256 tokenAmount,
    address investTo
  ) external returns (uint256) {
    _ensureTrusted(
      operator,
      account,
      token,
      tokenAmount > 0 ? CollateralFundLib.APPROVED_DEPOSIT | CollateralFundLib.APPROVED_INVEST : CollateralFundLib.APPROVED_INVEST
    );

    return _depositAndInvest(operator, account, depositValue, token, tokenAmount, investTo);
  }

  function trustedWithdraw(
    address operator,
    address account,
    address to,
    address token,
    uint256 amount
  ) external returns (uint256) {
    _ensureTrusted(operator, account, token, CollateralFundLib.APPROVED_WITHDRAW);
    return _withdraw(account, to, token, amount);
  }

  event AssetPaused(address indexed token, bool paused);

  function setPaused(address token, bool paused) external onlyEmergencyAdmin {
    internalSetFlags(token, paused ? 0 : type(uint8).max);
    emit AssetPaused(token, paused);
  }

  function isPaused(address token) public view returns (bool) {
    return _assets[token].assetFlags == type(uint8).max;
  }

  function setTrustedOperator(address token, address trustee) external aclHas(AccessFlags.LP_DEPLOY) {
    internalSetTrustee(token, trustee);
  }

  function setSpecialRoles(address operator, uint256 accessFlags) external aclHas(AccessFlags.LP_ADMIN) {
    internalSetSpecialApprovals(operator, accessFlags);
  }

  function _attachToken(address token, bool attach) private {
    IManagedPriceRouter pricer = getPricer();
    if (address(pricer) != address(0)) {
      pricer.attachSource(token, attach);
    }
  }

  function addAsset(address token, address trusted) external aclHas(AccessFlags.LP_DEPLOY) {
    internalAddAsset(token, trusted);
    _attachToken(token, true);
  }

  function removeAsset(address token) external aclHas(AccessFlags.LP_DEPLOY) {
    internalRemoveAsset(token);
    _attachToken(token, false);
  }

  function assets() external view override returns (address[] memory) {
    return _tokens.values();
  }

  event AssetBorrowed(address indexed token, uint256 amount, address to);
  event AssetReplenished(address indexed token, uint256 amount);

  function borrow(
    address token,
    uint256 amount,
    address to
  ) external {
    _onlyActiveAsset(token, CollateralFundLib.APPROVED_BORROW);
    Value.require(amount > 0);

    ICollateralStakeManager bm = ICollateralStakeManager(IManagedCollateralCurrency(collateral()).borrowManager());
    uint256 value = amount.wadMul(internalPriceOf(token));
    State.require(value > 0);
    State.require(bm.verifyBorrowUnderlying(msg.sender, value));

    BorrowBalance storage balance = _borrowedBalances[token][msg.sender];
    require((balance.amount += uint128(amount)) >= amount);
    require((balance.value += uint128(value)) >= value);

    SafeERC20.safeTransfer(IERC20(token), to, amount);

    emit AssetBorrowed(token, amount, to);
  }

  function repay(address token, uint256 amount) external {
    _onlyActiveAsset(token, CollateralFundLib.APPROVED_BORROW);
    Value.require(amount > 0);

    SafeERC20.safeTransferFrom(IERC20(token), msg.sender, address(this), amount);

    BorrowBalance storage balance = _borrowedBalances[token][msg.sender];
    uint256 prevAmount = balance.amount;
    balance.amount = uint128(prevAmount - amount);

    uint256 prevValue = balance.value;
    uint256 value = (prevValue * amount) / prevAmount;
    balance.value = uint128(prevValue - value);

    ICollateralStakeManager bm = ICollateralStakeManager(IManagedCollateralCurrency(collateral()).borrowManager());
    State.require(bm.verifyRepayUnderlying(msg.sender, value));

    emit AssetReplenished(token, amount);
  }

  function resetPriceGuard() external aclHasAny(AccessFlags.LP_ADMIN) {
    getPricer().resetSourceGroup();
  }
}

library CollateralFundLib {
  uint8 internal constant APPROVED_DEPOSIT = 1 << 0;
  uint8 internal constant APPROVED_INVEST = 1 << 1;
  uint8 internal constant APPROVED_WITHDRAW = 1 << 2;
  uint8 internal constant APPROVED_BORROW = 1 << 3;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../CollateralFundBase.sol';

contract MockCollateralFund is CollateralFundBase {
  mapping(address => uint256) private _prices;

  constructor(address collateral_) CollateralFundBase(IAccessController(address(0)), collateral_, 0) {}

  function internalAddAsset(address token, address trusted) internal override {
    super.internalAddAsset(token, trusted);
  }

  function internalPriceOf(address token) internal view override returns (uint256) {
    return _prices[token];
  }

  function getPricer() internal view override returns (IManagedPriceRouter pricer) {}

  function setPriceOf(address token, uint256 price) external {
    _prices[token] = price;
  }

  function hasAnyAcl(address, uint256) internal pure override returns (bool) {
    return true;
  }

  function hasAllAcl(address, uint256) internal pure override returns (bool) {
    return true;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/upgradeability/VersionedInitializable.sol';
import '../interfaces/ICollateralFundInit.sol';
import './CollateralFundBase.sol';

contract CollateralFundV1 is VersionedInitializable, ICollateralFundInit, CollateralFundBase {
  uint256 private constant CONTRACT_REVISION = 1;

  constructor(
    IAccessController acl,
    address collateral_,
    uint256 sourceFuses
  ) CollateralFundBase(acl, collateral_, sourceFuses) {}

  function initializeCollateralFund() public override initializer(CONTRACT_REVISION) {}

  function getRevision() internal pure override returns (uint256) {
    return CONTRACT_REVISION;
  }
}

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

import '../CollateralCurrency.sol';

contract MockCollateralCurrency is CollateralCurrency {
  address private _owner;

  constructor(string memory name_, string memory symbol_) CollateralCurrency(IAccessController(address(0)), name_, symbol_) {
    _owner = msg.sender;
  }

  function hasAnyAcl(address subject, uint256) internal view override returns (bool) {
    return subject == _owner;
  }

  function hasAllAcl(address subject, uint256) internal view override returns (bool) {
    return subject == _owner;
  }

  function isAdmin(address addr) internal view override returns (bool) {
    return addr == _owner;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../tools/tokens/IERC20.sol';
import '../../tools/tokens/IERC1363.sol';

contract MockCollateralCurrencyStub {
  function invest(address insurer, uint256 amount) external {
    _transferAndCall(insurer, amount, '');
  }

  function approve(address, uint256) external pure returns (bool) {
    return true;
  }

  function allowance(address, address) external view returns (uint256) {}

  function balanceOf(address) external view returns (uint256) {}

  function totalSupply() external view returns (uint256) {}

  function transfer(address, uint256) external pure returns (bool) {
    return true;
  }

  function transferAndCall(address to, uint256 value) external returns (bool) {
    return _transferAndCall(to, value, '');
  }

  function transferAndCall(
    address to,
    uint256 value,
    bytes memory data
  ) external returns (bool) {
    return _transferAndCall(to, value, data);
  }

  function _transferAndCall(
    address to,
    uint256 value,
    bytes memory data
  ) private returns (bool) {
    ERC1363.callReceiver(to, msg.sender, msg.sender, value, data);
    return true;
  }

  function borrowManager() public view returns (address) {}
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../tools/tokens/IERC20.sol';

interface IERC20Extended is IERC20 {
  function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

  function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

  function useAllowance(address spender, uint256 subtractedValue) external returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../tools/tokens/IERC20.sol';
import './IERC20Details.sol';

interface IERC20Detailed is IERC20, IERC20Details {}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/Errors.sol';
import '../tools/tokens/IERC20Details.sol';
import '../interfaces/IProxyFactory.sol';
import '../interfaces/IInsurerPool.sol';
import '../interfaces/IPremiumActuary.sol';
import '../interfaces/IManagedCollateralCurrency.sol';
import '../funds/interfaces/ICollateralFund.sol';
import '../premium/interfaces/IPremiumFund.sol';
import '../access/AccessHelper.sol';
import '../governance/interfaces/IApprovalCatalog.sol';

contract FrontHelper is AccessHelper {
  constructor(IAccessController acl) AccessHelper(acl) {}

  struct CollateralFundInfo {
    address fund;
    address collateral;
    address yieldDistributor;
    address[] assets;
  }

  struct InsurerInfo {
    address pool;
    address collateral;
    address premiumFund;
    bool chartered;
  }

  // slither-disable-next-line calls-loop
  function getAddresses()
    external
    view
    returns (
      address accessController,
      address proxyCatalog,
      address approvalCatalog,
      address priceRouter,
      CollateralFundInfo[] memory collateralFunds,
      InsurerInfo[] memory insurers
    )
  {
    IAccessController ac = remoteAcl();
    accessController = address(ac);

    proxyCatalog = ac.getAddress(AccessFlags.PROXY_FACTORY);
    approvalCatalog = ac.getAddress(AccessFlags.APPROVAL_CATALOG);
    priceRouter = ac.getAddress(AccessFlags.PRICE_ROUTER);

    address[] memory list = ac.roleHolders(AccessFlags.COLLATERAL_FUND_LISTING);

    collateralFunds = new CollateralFundInfo[](list.length);
    for (uint256 i = list.length; i > 0; ) {
      i--;
      ICollateralFund fund = ICollateralFund(collateralFunds[i].fund = list[i]);
      address cc = fund.collateral();
      collateralFunds[i].collateral = cc;
      collateralFunds[i].assets = fund.assets();
      collateralFunds[i].yieldDistributor = IManagedCollateralCurrency(cc).borrowManager();
    }

    list = ac.roleHolders(AccessFlags.INSURER_POOL_LISTING);

    insurers = new InsurerInfo[](list.length);
    for (uint256 i = list.length; i > 0; ) {
      i--;
      IInsurerPool insurer = IInsurerPool(insurers[i].pool = list[i]);
      insurers[i].collateral = insurer.collateral();
      insurers[i].chartered = insurer.charteredDemand();
      insurers[i].premiumFund = IPremiumActuary(address(insurer)).premiumDistributor();
    }
  }

  struct PremiumFundInfo {
    address fund;
    PremiumTokenInfo[] knownTokens;
  }

  struct PremiumTokenInfo {
    address token;
    PremiumActuaryInfo[] actuaries;
  }

  struct PremiumActuaryInfo {
    address actuary;
    address[] activeSources;
  }

  function getPremiumFundInfo(address[] calldata premiumFunds) external view returns (PremiumFundInfo[] memory funds) {
    funds = new PremiumFundInfo[](premiumFunds.length);
    for (uint256 i = premiumFunds.length; i > 0; ) {
      i--;
      funds[i] = _getPremiumFundInfo(IPremiumFund(premiumFunds[i]));
    }
  }

  // slither-disable-next-line calls-loop
  function _getPremiumFundInfo(IPremiumFund fund) private view returns (PremiumFundInfo memory info) {
    info.fund = address(fund);

    address[] memory knownTokens = fund.knownTokens();

    if (knownTokens.length > 0) {
      info.knownTokens = new PremiumTokenInfo[](knownTokens.length);

      for (uint256 i = knownTokens.length; i > 0; ) {
        i--;
        info.knownTokens[i] = _getDistributorTokenInfo(fund, knownTokens[i]);
      }
    }
  }

  // slither-disable-next-line calls-loop
  function _getDistributorTokenInfo(IPremiumFund fund, address token) private view returns (PremiumTokenInfo memory info) {
    info.token = token;

    address[] memory actuaries = fund.actuariesOfToken(token);

    if (actuaries.length > 0) {
      info.actuaries = new PremiumActuaryInfo[](actuaries.length);

      for (uint256 i = actuaries.length; i > 0; ) {
        i--;
        address[] memory sources = fund.activeSourcesOf(actuaries[i], token);
        info.actuaries[i] = PremiumActuaryInfo({actuary: actuaries[i], activeSources: sources});
      }
    }
  }

  // slither-disable-next-line calls-loop
  function batchBalanceOf(address[] calldata users, address[] calldata tokens) external view returns (uint256[] memory balances) {
    balances = new uint256[](users.length * tokens.length);

    for (uint256 i = 0; i < users.length; i++) {
      for (uint256 j = 0; j < tokens.length; j++) {
        balances[i * tokens.length + j] = IERC20(tokens[j]).balanceOf(users[i]);
      }
    }
  }

  struct TokenDetails {
    string symbol;
    string name;
    uint8 decimals;
  }

  // slither-disable-next-line calls-loop
  function batchTokenDetails(address[] calldata tokens) external view returns (TokenDetails[] memory details) {
    details = new TokenDetails[](tokens.length);

    for (uint256 j = 0; j < tokens.length; j++) {
      IERC20Details token = IERC20Details(tokens[j]);
      details[j] = TokenDetails({symbol: token.symbol(), name: token.name(), decimals: token.decimals()});
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../interfaces/ICollateralized.sol';

interface IPremiumFund is ICollateralized {
  // function priceOf(address token) external view returns (uint256);

  function syncAsset(
    address actuary,
    uint256 sourceLimit,
    address targetToken
  ) external;

  function syncAssets(
    address actuary,
    uint256 sourceLimit,
    address[] calldata targetTokens
  ) external returns (uint256);

  function swapAsset(
    address actuary,
    address account,
    address recipient,
    uint256 valueToSwap,
    address targetToken,
    uint256 minAmount
  ) external returns (uint256 tokenAmount);

  struct SwapInstruction {
    uint256 valueToSwap;
    address targetToken;
    uint256 minAmount;
    address recipient;
  }

  function swapAssets(
    address actuary,
    address account,
    address defaultRecepient,
    SwapInstruction[] calldata instructions
  ) external returns (uint256[] memory tokenAmounts);

  function knownTokens() external view returns (address[] memory);

  function actuariesOfToken(address token) external view returns (address[] memory);

  function actuaries() external view returns (address[] memory);

  function activeSourcesOf(address actuary, address token) external view returns (address[] memory);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../interfaces/IPremiumActuary.sol';
import '../../interfaces/IPremiumDistributor.sol';

import '../../tools/tokens/IERC20.sol';

contract MockPremiumActuary is IPremiumActuary {
  address public override premiumDistributor;
  address public override collateral;
  uint256 public drawdown;

  mapping(address => uint256) public premiumBurnt;

  constructor(address _distributor, address _collateral) {
    premiumDistributor = _distributor;
    collateral = _collateral;
  }

  function addSource(address source) external {
    IPremiumDistributor(premiumDistributor).registerPremiumSource(source, true);
  }

  function removeSource(address source) external {
    IPremiumDistributor(premiumDistributor).registerPremiumSource(source, false);
  }

  function setDrawdown(uint256 amount) external {
    drawdown = amount;
  }

  function collectDrawdownPremium() external view override returns (uint256 availablePremiumValue) {
    return drawdown;
  }

  function burnPremium(
    address account,
    uint256 value,
    address drawdownRecepient
  ) external override {
    premiumBurnt[account] += value;
    if (drawdownRecepient != address(0)) {
      drawdown -= value;
      IERC20(collateral).transfer(drawdownRecepient, value);
    }
  }

  function callPremiumAllocationUpdated(
    address insured,
    uint256 accumulated,
    uint256 increment,
    uint256 rate
  ) external {
    IPremiumDistributor(premiumDistributor).premiumAllocationUpdated(insured, accumulated, increment, rate);
  }

  function callPremiumAllocationFinished(address source, uint256 increment) external {
    IPremiumDistributor(premiumDistributor).premiumAllocationFinished(source, 0, increment);
  }

  function setRate(address insured, uint256 rate) external {
    IPremiumDistributor(premiumDistributor).premiumAllocationUpdated(insured, 0, 0, rate);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../interfaces/IPremiumSource.sol';
import '../../tools/tokens/IERC20.sol';
import '../../tools/Errors.sol';
import '../../tools/math/WadRayMath.sol';

//import '../../interfaces/IPremiumDistributor.sol';
//import '../../insured/PremiumCollectorBase.sol';

contract MockPremiumSource is IPremiumSource {
  using WadRayMath for uint256;
  address public premiumToken;
  address public collateral;

  constructor(address _premiumToken, address _collateral) {
    premiumToken = _premiumToken;
    collateral = _collateral;
  }

  function collectPremium(
    address actuary,
    address token,
    uint256 amount,
    uint256 value
  ) external {
    actuary;
    uint256 balance = IERC20(token).balanceOf(address(this));

    if (balance > 0) {
      if (token == collateral) {
        if (amount > balance) {
          amount = balance;
        }
        value = amount;
      } else {
        Value.require(token == address(premiumToken));
        if (amount > balance) {
          value = (value * balance) / amount;
          amount = balance;
        }
      }

      if (value > 0) {
        IERC20(token).transfer(msg.sender, amount);
        //_collectedValue += value;
      }
    }
  }

  /*
  function collectPremium(
    address actuary,
    address token,
    uint256 amount,
    uint256 price
  ) external {
    uint256 balance = IERC20(token).balanceOf(address(this));
    uint256 value;

    if (balance > 0) {
      if (amount > balance) {
        amount = balance;
      }
      if (token == collateral) {
        value = amount;
      } else {
        Value.require(token == address(premiumToken));
        value = amount.wadMul(price);
      }

      if (value > 0) {
        IERC20(token).transfer(msg.sender, amount);
        //_collectedValue += value;
      }
    }
  }
  */
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/Address.sol';
import '../interfaces/ISweeper.sol';
import './tokens/IERC20.sol';
import './SafeERC20.sol';
import './Errors.sol';

abstract contract SweepBase is ISweeper {
  address private constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  function sweepToken(
    address token,
    address to,
    uint256 amount
  ) external override {
    _onlySweepAdmin();
    if (token == ETH) {
      Address.sendValue(payable(to), amount);
    } else {
      SafeERC20.safeTransfer(IERC20(token), to, amount);
    }
  }

  function _onlySweepAdmin() internal view virtual;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface ISweeper {
  /// @dev transfer ERC20 or ETH from the utility contract, for recovery of direct transfers to the contract address.
  function sweepToken(
    address token,
    address to,
    uint256 amount
  ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './TransparentProxyBase.sol';

/// @dev This contract is a transparent upgradeability proxy with admin. The admin role is immutable.
contract TransparentProxyLazyInit is TransparentProxyBase {
  constructor(address admin) TransparentProxyBase(admin) {}

  /// @dev Sets initial implementation of the proxy and call a function on it. Can be called only once, but by anyone.
  /// @dev Caller MUST check return to be equal to proxy's address to ensure that this function was actually called.
  function initializeProxy(address logic, bytes calldata data) external returns (address self) {
    if (_implementation() == address(0)) {
      _upgradeTo(logic);
      Address.functionDelegateCall(logic, data);
      return address(this); // call sanity check
    } else {
      _fallback();
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../interfaces/IManagedAccessController.sol';

contract MockCaller {
  //uint256 public lastTempRole;

  /*
  function setLastTempRole() external {
    lastTempRole = IManagedAccessController(msg.sender).queryAccessControlMask(address(this), 0);
  }
  */

  function checkRoleDirect(uint256 flags) external view {
    require(IManagedAccessController(msg.sender).queryAccessControlMask(address(this), flags) == flags, 'Incorrect roles');
  }

  function checkRoleIndirect(IManagedAccessController controller, uint256 flags) external view {
    require(controller.queryAccessControlMask(msg.sender, flags) == flags, 'Incorrect roles');
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../tools/tokens/IERC20.sol';
import '../../tools/Errors.sol';

abstract contract ERC20NoTransferBase is IERC20 {
  function transfer(address, uint256) public pure override returns (bool) {
    revert Errors.NotSupported();
  }

  function allowance(address, address) public pure override returns (uint256) {}

  function approve(address, uint256) public pure override returns (bool) {
    revert Errors.NotSupported();
  }

  function transferFrom(
    address,
    address,
    uint256
  ) public pure override returns (bool) {
    revert Errors.NotSupported();
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../YieldDistributorBase.sol';

contract MockYieldDistributor is YieldDistributorBase {
  mapping(address => uint256) private _prices;

  constructor(address collateral_) YieldDistributorBase(IAccessController(address(0)), collateral_) {}

  function hasAnyAcl(address, uint256) internal pure override returns (bool) {
    return true;
  }

  function hasAllAcl(address, uint256) internal pure override returns (bool) {
    return true;
  }

  uint256 public pullCount;

  function internalPullYieldFrom(uint8 sourceType, address addr) internal override returns (uint256) {
    Value.require(addr != address(0));
    if (sourceType != 2) {
      revert Errors.NotImplemented();
    }
    pullCount++;
    return 0;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../insured/InsuredPoolV1.sol';

contract MockInsuredPoolV2 is InsuredPoolV1 {
  uint256 private constant CONTRACT_REVISION = 2;
  mapping(address => bool) private _canClaimInsurance;

  constructor(IAccessController acl, address collateral_) InsuredPoolV1(acl, collateral_) {}

  function getRevision() internal pure override returns (uint256) {
    return CONTRACT_REVISION;
  }

  function canClaimInsurance(address claimedBy) public view virtual override returns (bool) {
    return super.canClaimInsurance(claimedBy) || _canClaimInsurance[claimedBy];
  }

  function setClaimInsurance(address user) external {
    _canClaimInsurance[user] = true;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../Strings.sol';

contract MockLibs {
  function testBytes32ToString(bytes32 v) public pure returns (string memory) {
    return Strings.asString(v);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './AccessFlags.sol';
import './AccessControllerBase.sol';

contract AccessController is AccessControllerBase {
  constructor(uint256 moreMultilets)
    AccessControllerBase(AccessFlags.SINGLETS, AccessFlags.ROLES | AccessFlags.ROLES_EXT | moreMultilets, AccessFlags.PROTECTED_SINGLETS)
  {}
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../PremiumFundBase.sol';

contract MockPremiumFund is PremiumFundBase {
  using EnumerableSet for EnumerableSet.AddressSet;

  mapping(address => uint256) private _prices;

  constructor(address collateral_) PremiumFundBase(IAccessController(address(0)), collateral_) {}

  function isAdmin(address) internal pure override returns (bool) {
    return true;
  }

  function hasAnyAcl(address, uint256) internal pure override returns (bool) {
    return true;
  }

  function hasAllAcl(address, uint256) internal pure override returns (bool) {
    return true;
  }

  function setConfig(
    address actuary,
    address asset,
    uint152 price,
    uint64 w,
    uint32 n,
    uint16 flags,
    uint160 spConst
  ) external {
    _balancers[actuary].configs[asset] = BalancerLib2.AssetConfig(price, w, n, flags, spConst);
  }

  function setDefaultConfig(
    address actuary,
    uint152 price,
    uint64 w,
    uint32 n,
    uint16 flags,
    uint160 spConst
  ) external {
    _configs[actuary].defaultConfig = BalancerLib2.AssetConfig(price, w, n, flags, spConst);
  }

  function getDefaultConfig(address actuary) external view returns (BalancerLib2.AssetConfig memory) {
    return _configs[actuary].defaultConfig;
  }

  function getConifg(address actuary, address asset) external view returns (BalancerLib2.AssetConfig memory) {
    return _balancers[actuary].configs[asset];
  }

  function setAutoReplenish(address actuary, address asset) external {
    _balancers[actuary].configs[asset].flags |= BalancerLib2.BF_AUTO_REPLENISH;
  }

  function balancesOf(address actuary, address source) external view returns (SourceBalance memory) {
    return _configs[actuary].sourceBalances[source];
  }

  function balancerBalanceOf(address actuary, address token) external view returns (BalancerLib2.AssetBalance memory) {
    return _balancers[actuary].balances[token];
  }

  function balancerTotals(address actuary) external view returns (Balances.RateAcc memory) {
    return _balancers[actuary].totalBalance;
  }

  function setPrice(address token, uint256 price) external {
    _prices[token] = price;
  }

  function internalPriceOf(address token) internal view override returns (uint256) {
    if (token == collateral()) {
      return WadRayMath.WAD;
    }
    return _prices[token];
  }

  /*
  function registerPremiumActuary(address actuary, bool register) external override onlyAdmin {
    PremiumFundBase.registerPremiumActuary(actuary,register);
  }
  */
}