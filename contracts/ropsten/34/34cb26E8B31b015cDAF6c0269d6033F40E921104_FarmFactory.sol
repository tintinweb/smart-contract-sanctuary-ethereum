/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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
   * @dev Moves `amount` tokens from the caller's account to `to`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address to, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

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
   * @dev Moves `amount` tokens from `from` to `to` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address from,
    address to,
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

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

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
    require(owner() == _msgSender(), 'Ownable: caller is not the owner');
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
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
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

// File: contracts/FarmsFeeManager.sol

pragma solidity =0.8.7;

contract FarmsFeeManager is Ownable {
  address public feeReceiver;
  uint256 public deploymentFee;
  uint256 public claimRewardsFee;
  uint256 public referralFee;

  mapping(address => bool) public isFarmExcludedFromFees;

  constructor(
    address payable _feeReceiver,
    uint256 _deploymentFee,
    uint256 _referralFee,
    uint256 _claimRewardsFee
  ) {
    feeReceiver = _feeReceiver;
    deploymentFee = _deploymentFee;
    require(_referralFee <= 10**4 / 2, 'referralFee must be <= 50%');
    referralFee = _referralFee;
    require(claimRewardsFee <= 10**4 / 10, 'claimRewardsFee must be <= 10%');
    claimRewardsFee = _claimRewardsFee;
  }

  function setFeeReceiver(address _feeReceiver) external onlyOwner {
    feeReceiver = _feeReceiver;
  }

  function setDeploymentFee(uint256 _deploymentFee) external onlyOwner {
    deploymentFee = _deploymentFee;
  }

  function setReferralFee(uint256 _referralFee) external onlyOwner {
    require(_referralFee <= 10**4 / 2, 'referralFee must be <= 50%');
    referralFee = _referralFee;
  }

  function setClaimRewardsFee(uint256 _claimRewardsFee) external onlyOwner {
    require(_claimRewardsFee <= 10**4 / 10, 'claimRewardsFee must be <= 10%');
    claimRewardsFee = _claimRewardsFee;
  }

  function setFarmExcludedFromFees(address _farm, bool _excluded)
    external
    onlyOwner
  {
    isFarmExcludedFromFees[_farm] = _excluded;
  }
}

// File: @openzeppelin/contracts/utils/Address.sol

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
    require(address(this).balance >= amount, 'Address: insufficient balance');

    (bool success, ) = recipient.call{value: amount}('');
    require(
      success,
      'Address: unable to send value, recipient may have reverted'
    );
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
  function functionCall(address target, bytes memory data)
    internal
    returns (bytes memory)
  {
    return functionCall(target, data, 'Address: low-level call failed');
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
    return
      functionCallWithValue(
        target,
        data,
        value,
        'Address: low-level call with value failed'
      );
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
    require(
      address(this).balance >= value,
      'Address: insufficient balance for call'
    );
    require(isContract(target), 'Address: call to non-contract');

    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(address target, bytes memory data)
    internal
    view
    returns (bytes memory)
  {
    return
      functionStaticCall(target, data, 'Address: low-level static call failed');
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
    require(isContract(target), 'Address: static call to non-contract');

    (bool success, bytes memory returndata) = target.staticcall(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a delegate call.
   *
   * _Available since v3.4._
   */
  function functionDelegateCall(address target, bytes memory data)
    internal
    returns (bytes memory)
  {
    return
      functionDelegateCall(
        target,
        data,
        'Address: low-level delegate call failed'
      );
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
    require(isContract(target), 'Address: delegate call to non-contract');

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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

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
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.transfer.selector, to, value)
    );
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
    );
  }

  /**
   * @dev Deprecated. This function has issues similar to the ones found in
   * {IERC20-approve}, and its usage is discouraged.
   *
   * Whenever possible, use {safeIncreaseAllowance} and
   * {safeDecreaseAllowance} instead.
   */
  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    // safeApprove should only be called when setting an initial allowance,
    // or when resetting it to zero. To increase and decrease it, use
    // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      'SafeERC20: approve from non-zero to non-zero allowance'
    );
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, value)
    );
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender) + value;
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
    );
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    unchecked {
      uint256 oldAllowance = token.allowance(address(this), spender);
      require(
        oldAllowance >= value,
        'SafeERC20: decreased allowance below zero'
      );
      uint256 newAllowance = oldAllowance - value;
      _callOptionalReturn(
        token,
        abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
      );
    }
  }

  /**
   * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
   * on the return value: the return value is optional (but if data is returned, it must not be false).
   * @param token The token targeted by the call.
   * @param data The call data (encoded using abi.encode or one of its variants).
   */
  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
    // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
    // the target address contains contract code and also asserts for success in the low-level call.

    bytes memory returndata = address(token).functionCall(
      data,
      'SafeERC20: low-level call failed'
    );
    if (returndata.length > 0) {
      // Return data is optional
      require(
        abi.decode(returndata, (bool)),
        'SafeERC20: ERC20 operation did not succeed'
      );
    }
  }
}

// File: @openzeppelin/contracts/utils/structs/EnumerableSet.sol

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
  function _contains(Set storage set, bytes32 value)
    private
    view
    returns (bool)
  {
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
  function remove(Bytes32Set storage set, bytes32 value)
    internal
    returns (bool)
  {
    return _remove(set._inner, value);
  }

  /**
   * @dev Returns true if the value is in the set. O(1).
   */
  function contains(Bytes32Set storage set, bytes32 value)
    internal
    view
    returns (bool)
  {
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
  function at(Bytes32Set storage set, uint256 index)
    internal
    view
    returns (bytes32)
  {
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
  function values(Bytes32Set storage set)
    internal
    view
    returns (bytes32[] memory)
  {
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
  function remove(AddressSet storage set, address value)
    internal
    returns (bool)
  {
    return _remove(set._inner, bytes32(uint256(uint160(value))));
  }

  /**
   * @dev Returns true if the value is in the set. O(1).
   */
  function contains(AddressSet storage set, address value)
    internal
    view
    returns (bool)
  {
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
  function at(AddressSet storage set, uint256 index)
    internal
    view
    returns (address)
  {
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
  function values(AddressSet storage set)
    internal
    view
    returns (address[] memory)
  {
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
  function contains(UintSet storage set, uint256 value)
    internal
    view
    returns (bool)
  {
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
  function at(UintSet storage set, uint256 index)
    internal
    view
    returns (uint256)
  {
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
  function values(UintSet storage set)
    internal
    view
    returns (uint256[] memory)
  {
    bytes32[] memory store = _values(set._inner);
    uint256[] memory result;

    assembly {
      result := store
    }

    return result;
  }
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol

// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, with an overflow flag.
   *
   * _Available since v3.4._
   */
  function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
      uint256 c = a + b;
      if (c < a) return (false, 0);
      return (true, c);
    }
  }

  /**
   * @dev Returns the substraction of two unsigned integers, with an overflow flag.
   *
   * _Available since v3.4._
   */
  function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
      if (b > a) return (false, 0);
      return (true, a - b);
    }
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
   *
   * _Available since v3.4._
   */
  function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
      // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
      // benefit is lost if 'b' is also tested.
      // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
      if (a == 0) return (true, 0);
      uint256 c = a * b;
      if (c / a != b) return (false, 0);
      return (true, c);
    }
  }

  /**
   * @dev Returns the division of two unsigned integers, with a division by zero flag.
   *
   * _Available since v3.4._
   */
  function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
      if (b == 0) return (false, 0);
      return (true, a / b);
    }
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
   *
   * _Available since v3.4._
   */
  function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
      if (b == 0) return (false, 0);
      return (true, a % b);
    }
  }

  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   *
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    return a + b;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   *
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return a - b;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   *
   * - Multiplication cannot overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    return a * b;
  }

  /**
   * @dev Returns the integer division of two unsigned integers, reverting on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator.
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * reverting when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return a % b;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * CAUTION: This function is deprecated because it requires allocating memory for the error
   * message unnecessarily. For custom revert reasons use {trySub}.
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   *
   * - Subtraction cannot overflow.
   */
  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    unchecked {
      require(b <= a, errorMessage);
      return a - b;
    }
  }

  /**
   * @dev Returns the integer division of two unsigned integers, reverting with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    unchecked {
      require(b > 0, errorMessage);
      return a / b;
    }
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * reverting with custom message when dividing by zero.
   *
   * CAUTION: This function is deprecated because it requires allocating memory for the error
   * message unnecessarily. For custom revert reasons use {tryMod}.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    unchecked {
      require(b > 0, errorMessage);
      return a % b;
    }
  }
}

// File: contracts/Farm.sol

pragma solidity ^0.8.0;

contract Farm is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  uint256 public constant VERSION = 1;
  FarmsFeeManager public feeManager;
  address public creator;

  // Info of each user.
  struct UserInfo {
    uint256 depositedAt; // The block number when the user deposited LP.
    uint256 amount; // How many LP tokens the user has provided.
    uint256 rewardDebt; // Reward debt. See explanation below.
    //
    // We do some fancy math here. Basically, any point in time, the amount of ERC20s
    // entitled to a user but is pending to be distributed is:
    //
    //   pending reward = (user.amount * pool.accERC20PerShare) - user.rewardDebt
    //
    // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
    //   1. The pool's `accERC20PerShare` (and `lastRewardBlock`) gets updated.
    //   2. User receives the pending reward sent to his/her address.
    //   3. User's `amount` gets updated.
    //   4. User's `rewardDebt` gets updated.
  }

  // Info of each pool.
  struct PoolInfo {
    IERC20 lpToken; // Address of LP token contract.
    uint256 lockPeriod; // How many blocks the LP token is locked.
    uint256 earlyWithdrawFee; // Early withdraw fee in percentage.
    uint256 allocPoint; // How many allocation points assigned to this pool. ERC20s to distribute per block.
    uint256 lastRewardBlock; // Last block number that ERC20s distribution occurs.
    uint256 accERC20PerShare; // Accumulated ERC20s per share, times 1e36.
  }

  // Address of the ERC20 Token contract.
  IERC20 public erc20;
  // The total amount of ERC20 that's paid out as reward.
  uint256 public paidOut = 0;
  // ERC20 tokens rewarded per block.
  uint256 public rewardPerBlock;

  // Info of each pool.
  PoolInfo[] public poolInfo;
  // Info of each user that stakes LP tokens.
  mapping(uint256 => mapping(address => UserInfo)) public userInfo;
  // Total allocation points. Must be the sum of all allocation points in all pools.
  uint256 public totalAllocPoint = 0;
  // Total amount of users that are staking LP tokens.
  mapping(uint256 => uint256) public usersCount;

  // The block number when farming starts.
  uint256 public startBlock;
  // The block number when farming ends.
  uint256 public endBlock;

  event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
  event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
  event RewardUser(
    address indexed user,
    uint256 indexed pid,
    uint256 amount,
    uint256 fee
  );
  event CollectFee(
    address indexed user,
    address indexed recipient,
    uint256 indexed pid,
    uint256 amount
  );
  event EmergencyWithdraw(
    address indexed user,
    uint256 indexed pid,
    uint256 amount
  );

  constructor(
    IERC20 _erc20,
    uint256 _rewardPerBlock,
    uint256 _startBlock,
    address _creator,
    address _feeManager
  ) {
    erc20 = _erc20;
    rewardPerBlock = _rewardPerBlock;
    startBlock = _startBlock;
    endBlock = _startBlock;
    creator = _creator;

    feeManager = FarmsFeeManager(_feeManager);
  }

  function deploymentFee() public view returns (uint256) {
    return feeManager.deploymentFee();
  }

  function claimRewardsFee() public view returns (uint256) {
    return feeManager.claimRewardsFee();
  }

  function hasClaimRewardsFee() public view returns (bool) {
    return !feeManager.isFarmExcludedFromFees(address(this));
  }

  function feeReceiver() public view returns (address) {
    return feeManager.feeReceiver();
  }

  // Number of LP pools
  function poolLength() external view returns (uint256) {
    return poolInfo.length;
  }

  // Fund the farm, increase the end block
  function fund(uint256 _amount) public {
    require(block.number < endBlock, 'Farm.fund: too late, the farm is closed');

    erc20.safeTransferFrom(address(msg.sender), address(this), _amount);
    endBlock += _amount.div(rewardPerBlock);
  }

  // Add a new lp to the pool. Can only be called by the owner.
  // DO NOT add the same LP token more than once. Rewards will be messed up if you do.
  // If _lockPeriod = 0 it will be ignored.
  function add(
    uint256 _allocPoint,
    IERC20 _lpToken,
    uint256 _lockPeriod,
    uint256 _earlyWithdrawFee,
    bool _withUpdate
  ) public onlyOwner {
    require(
      _earlyWithdrawFee <= 10**4 / 4,
      'Farm.add: earlyWithdrawFee must be <= 25%'
    );
    require(_allocPoint > 0, 'Farm.add: allocPoint must be > 0');
    require(_lockPeriod >= 0, 'Farm.add: lockPeriod must be >= 0');
    for (uint256 index = 0; index < poolInfo.length; index++) {
      require(
        poolInfo[index].lpToken != _lpToken,
        'Farm.add: you can not add the same LP token twice'
      );
    }
    if (_withUpdate) {
      massUpdatePools();
    }
    uint256 lastRewardBlock = block.number > startBlock
      ? block.number
      : startBlock;
    totalAllocPoint = totalAllocPoint.add(_allocPoint);
    poolInfo.push(
      PoolInfo({
        lpToken: _lpToken,
        allocPoint: _allocPoint,
        lockPeriod: _lockPeriod,
        earlyWithdrawFee: _earlyWithdrawFee,
        lastRewardBlock: lastRewardBlock,
        accERC20PerShare: 0
      })
    );
  }

  // Update the given pool's ERC20 allocation point. Can only be called by the owner.
  function set(
    uint256 _pid,
    uint256 _allocPoint,
    uint256 _lockPeriod,
    uint256 _earlyWithdrawFee,
    bool _withUpdate
  ) public onlyOwner {
    if (_withUpdate) {
      massUpdatePools();
    }
    totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
      _allocPoint
    );
    poolInfo[_pid].allocPoint = _allocPoint;
    poolInfo[_pid].lockPeriod = _lockPeriod;
    poolInfo[_pid].earlyWithdrawFee = _earlyWithdrawFee;
  }

  // View function to see deposited LP for a user.
  function deposited(uint256 _pid, address _user)
    external
    view
    returns (uint256)
  {
    UserInfo storage user = userInfo[_pid][_user];
    return user.amount;
  }

  // View function to see pending ERC20s for a user.
  function pending(uint256 _pid, address _user)
    external
    view
    returns (uint256)
  {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][_user];
    uint256 accERC20PerShare = pool.accERC20PerShare;
    uint256 lpSupply = pool.lpToken.balanceOf(address(this));
    uint256 lastBlock = block.number < endBlock ? block.number : endBlock;

    if (
      lastBlock > pool.lastRewardBlock &&
      block.number > pool.lastRewardBlock &&
      lpSupply != 0
    ) {
      uint256 nrOfBlocks = lastBlock.sub(pool.lastRewardBlock);
      uint256 erc20Reward = nrOfBlocks
        .mul(rewardPerBlock)
        .mul(pool.allocPoint)
        .div(totalAllocPoint);
      accERC20PerShare = accERC20PerShare.add(
        erc20Reward.mul(1e36).div(lpSupply)
      );
    }

    return user.amount.mul(accERC20PerShare).div(1e36).sub(user.rewardDebt);
  }

  // View function for total reward the farm has yet to pay out.
  function totalPending() external view returns (uint256) {
    if (block.number <= startBlock) {
      return 0;
    }

    uint256 lastBlock = block.number < endBlock ? block.number : endBlock;
    return rewardPerBlock.mul(lastBlock - startBlock).sub(paidOut);
  }

  // Update reward variables for all pools. Be careful of gas spending!
  function massUpdatePools() public {
    uint256 length = poolInfo.length;
    for (uint256 pid = 0; pid < length; ++pid) {
      updatePool(pid);
    }
  }

  // Update reward variables of the given pool to be up-to-date.
  function updatePool(uint256 _pid) public {
    PoolInfo storage pool = poolInfo[_pid];
    uint256 lastBlock = block.number < endBlock ? block.number : endBlock;

    if (lastBlock <= pool.lastRewardBlock) {
      return;
    }
    uint256 lpSupply = pool.lpToken.balanceOf(address(this));
    if (lpSupply == 0) {
      pool.lastRewardBlock = lastBlock;
      return;
    }

    uint256 nrOfBlocks = lastBlock.sub(pool.lastRewardBlock);
    uint256 erc20Reward = nrOfBlocks
      .mul(rewardPerBlock)
      .mul(pool.allocPoint)
      .div(totalAllocPoint);

    pool.accERC20PerShare = pool.accERC20PerShare.add(
      erc20Reward.mul(1e36).div(lpSupply)
    );
    pool.lastRewardBlock = block.number;
  }

  // Deposit LP tokens to Farm for ERC20 allocation.
  function deposit(
    uint256 _pid,
    uint256 _amount,
    address _to
  ) external onlyOwner {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][_to];

    if (user.amount == 0) {
      usersCount[_pid]++;
    }

    updatePool(_pid);

    _rewardUser(_pid, _to);

    pool.lpToken.safeTransferFrom(address(_to), address(this), _amount);
    user.depositedAt = block.number;
    user.amount = user.amount.add(_amount);
    user.rewardDebt = user.amount.mul(pool.accERC20PerShare).div(1e36);

    emit Deposit(_to, _pid, _amount);
  }

  // Withdraw LP tokens from Farm.
  function withdraw(
    uint256 _pid,
    uint256 _amount,
    address _to
  ) external onlyOwner {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][_to];
    require(
      user.amount > 0,
      "Farm.withdraw: can't withdraw from user with no LP tokens deposited"
    );
    require(
      user.amount >= _amount,
      "Farm.withdraw: can't withdraw more than deposited amount"
    );
    updatePool(_pid);

    _rewardUser(_pid, _to);

    user.amount = user.amount.sub(_amount);
    user.rewardDebt = user.amount.mul(pool.accERC20PerShare).div(1e36);
    pool.lpToken.safeTransfer(address(_to), _amount);

    if (user.amount == 0) {
      usersCount[_pid]--;
    }

    emit Withdraw(_to, _pid, _amount);
  }

  // Transfer, if necessary, rewards to a specific address and charge fees if applied.
  function _rewardUser(uint256 _pid, address _address) internal {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][_address];
    if (user.amount > 0) {
      uint256 pendingAmount = user
        .amount
        .mul(pool.accERC20PerShare)
        .div(1e36)
        .sub(user.rewardDebt);
      uint256 rewards = pendingAmount;
      uint256 totalFee = 0;

      // Check and charge claim rewards fee
      if (hasClaimRewardsFee() && claimRewardsFee() > 0) {
        uint256 fee = (rewards * claimRewardsFee()) / 10**4;
        totalFee += fee;
        erc20Transfer(feeReceiver(), fee);
        rewards -= fee;
        emit CollectFee(_address, feeReceiver(), _pid, fee);
      }

      // Check and charge early withdraw fee
      if (
        pool.lockPeriod > 0 && // lock period is set
        pool.earlyWithdrawFee > 0 && // early withdraw fee is set
        pendingAmount > 0 && // there is pending rewards
        (user.depositedAt + pool.lockPeriod) > block.number // user is in lock period
      ) {
        uint256 fee = (rewards * pool.earlyWithdrawFee) / 10**4;
        totalFee += fee;
        erc20Transfer(creator, fee);
        rewards -= fee;
        emit CollectFee(_address, creator, _pid, fee);
      }

      // Transfer rewards to user
      erc20Transfer(_address, rewards);
      emit RewardUser(_address, _pid, rewards, totalFee);
    }
  }

  // Withdraw without caring about rewards. EMERGENCY ONLY.
  function emergencyWithdraw(uint256 _pid, address _address) public onlyOwner {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][_address];
    pool.lpToken.safeTransfer(_address, user.amount);
    emit EmergencyWithdraw(_address, _pid, user.amount);
    user.amount = 0;
    user.rewardDebt = 0;
  }

  function emergencyRecovery() external onlyOwner {
    uint256 erc20Balance = erc20.balanceOf(address(this));
    if (erc20Balance > 0) {
      erc20Transfer(creator, erc20Balance);
    }
  }

  // Transfer ERC20 and update the required ERC20 to payout all rewards
  function erc20Transfer(address _to, uint256 _amount) internal {
    erc20.transfer(_to, _amount);
    paidOut += _amount;
  }
}

// File: contracts/FarmFactory.sol

pragma solidity =0.8.7;

contract FarmFactory is Ownable {
  using SafeMath for uint256;

  uint256 public constant VERSION = 1;

  FarmsFeeManager public feeManager;

  bool public isEnabled = true;

  event FarmCreated(address indexed owner, address indexed token, address farm);
  event CollectDeploymentFee(
    address indexed receiver,
    address indexed sender,
    uint256 amount
  );
  event CollectReferralFee(
    address indexed receiver,
    address indexed sender,
    uint256 amount
  );

  Farm[] public farms;

  struct UserFarm {
    Farm farm;
    uint256 deposited;
  }

  mapping(address => UserFarm[]) public userFarms;

  struct CreateFarmParams {
    // constructor
    IERC20 erc20;
    uint256 rewardPerBlock;
    uint256 startBlock;
    // add
    IERC20 lpToken;
    uint256 lockPeriod;
    uint256 earlyWithdrawFee;
    // fund
    uint256 amount;
    // referral
    address referral;
  }

  constructor(
    address payable _feeReceiver,
    uint256 _deploymentFee,
    uint256 _referralFee,
    uint256 _claimRewardsFee
  ) {
    feeManager = new FarmsFeeManager(
      _feeReceiver,
      _deploymentFee,
      _referralFee,
      _claimRewardsFee
    );
    feeManager.transferOwnership(msg.sender);
  }

  function deploymentFee() public view returns (uint256) {
    return feeManager.deploymentFee();
  }

  function referralFee() public view returns (uint256) {
    return feeManager.referralFee();
  }

  function claimRewardsFee() public view returns (uint256) {
    return feeManager.claimRewardsFee();
  }

  function feeReceiver() public view returns (address) {
    return feeManager.feeReceiver();
  }

  function _deploy(CreateFarmParams memory info) internal {
    require(isEnabled, 'FarmFactory.deploy: deployments are disabled');

    Farm farm = new Farm(
      info.erc20,
      info.rewardPerBlock,
      info.startBlock,
      msg.sender,
      address(feeManager)
    );

    farm.add(1, info.lpToken, info.lockPeriod, info.earlyWithdrawFee, false);

    info.erc20.transferFrom(msg.sender, address(this), info.amount);
    info.erc20.approve(address(farm), info.amount);
    farm.fund(info.amount);

    farms.push(farm);

    emit FarmCreated(msg.sender, address(info.erc20), address(farm));
  }

  function _payDeploymentFee(uint256 _deploymentFee) internal {
    (bool sent, ) = feeReceiver().call{value: _deploymentFee}('');
    require(sent, 'FarmFactory.deploy: failed to pay deployment fee');

    emit CollectDeploymentFee(feeReceiver(), msg.sender, _deploymentFee);
  }

  function _payReferralFee(uint256 _referralFee, address referrer) internal {
    (bool sentReferralFee, ) = referrer.call{value: _referralFee}('');
    require(sentReferralFee, 'FarmFactory.deploy: failed to pay referral fee');

    emit CollectReferralFee(referrer, msg.sender, _referralFee);
  }

  function deploy(CreateFarmParams memory info) public payable {
    _deploy(info);

    uint256 _referralFee = 0;

    if (info.referral != address(0)) {
      _referralFee = deploymentFee().mul(referralFee()).div(10**4);
      _payReferralFee(_referralFee, info.referral);
    }

    _payDeploymentFee(deploymentFee().sub(_referralFee));
  }

  function farmsLength() external view returns (uint256) {
    return farms.length;
  }

  function setIsEnabled(bool _isEnabled) external onlyOwner {
    isEnabled = _isEnabled;
  }

  function deposit(address farmAddress, uint256 amount) external {
    require(amount > 0, 'FarmFactory.deposit: amount must be greater than 0');

    UserFarm[] storage _userFarms = userFarms[msg.sender];
    UserFarm memory farm;
    bool found = false;

    uint256 index = 0;

    for (index = 0; index < _userFarms.length; index++) {
      if (address(_userFarms[index].farm) == farmAddress) {
        farm = _userFarms[index];
        found = true;
        break;
      }
    }

    Farm farmInstance = Farm(farmAddress);
    farmInstance.deposit(0, amount, msg.sender);

    farm.farm = farmInstance;
    farm.deposited = farm.deposited + amount;

    if (found) {
      _userFarms[index] = farm;
      return;
    }

    _userFarms.push(farm);
    userFarms[msg.sender] = _userFarms;
  }

  function withdraw(address farmAddress, uint256 amount) external {
    UserFarm[] storage _userFarms = userFarms[msg.sender];
    UserFarm memory farm;
    bool found = false;

    uint256 index = 0;

    for (index = 0; index < _userFarms.length; index++) {
      if (address(_userFarms[index].farm) == farmAddress) {
        farm = _userFarms[index];
        found = true;
        break;
      }
    }

    Farm farmInstance = Farm(farmAddress);
    farmInstance.withdraw(0, amount, msg.sender);

    farm.farm = farmInstance;
    farm.deposited = farm.deposited - amount;

    if (found) {
      _userFarms[index] = farm;
      return;
    }

    _userFarms.push(farm);
    userFarms[msg.sender] = _userFarms;
  }

  function emergencyWithdraw(address farmAddress, uint256 amount) external {
    UserFarm[] storage _userFarms = userFarms[msg.sender];
    UserFarm memory farm;
    bool found = false;

    uint256 index = 0;

    for (index = 0; index < _userFarms.length; index++) {
      if (address(_userFarms[index].farm) == farmAddress) {
        farm = _userFarms[index];
        found = true;
        break;
      }
    }

    Farm farmInstance = Farm(farmAddress);
    farmInstance.emergencyWithdraw(0, msg.sender);

    farm.farm = farmInstance;
    farm.deposited = farm.deposited - amount;

    if (found) {
      _userFarms[index] = farm;
      return;
    }

    _userFarms.push(farm);
    userFarms[msg.sender] = _userFarms;
  }

  function emergencyRecovery(address farm) external onlyOwner {
    Farm farmInstance = Farm(farm);
    farmInstance.emergencyRecovery();
  }

  function pending(address farm) external view returns (uint256) {
    Farm farmInstance = Farm(farm);
    uint256 pendingRewards = farmInstance.pending(0, msg.sender);
    return pendingRewards;
  }

  function userFarmsLength(address user) external view returns (uint256) {
    UserFarm[] storage _userFarms = userFarms[user];
    return _userFarms.length;
  }
}