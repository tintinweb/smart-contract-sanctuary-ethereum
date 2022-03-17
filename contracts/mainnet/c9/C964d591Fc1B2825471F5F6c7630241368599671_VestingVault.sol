// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IVestingVault.sol";

/**
 * @title VestingVault
 * @dev A token vesting contract that will release tokens gradually like a
 * standard equity vesting schedule, with a cliff and vesting period but no
 * arbitrary restrictions on the frequency of claims. Optionally has an initial
 * tranche claimable immediately after the cliff expires (in addition to any
 * amounts that would have vested up to that point but didn't due to a cliff).
 */
contract VestingVault is IVestingVault, Ownable {
  using SafeERC20 for IERC20;

  // The amount unclaimed for an address, whether or not vested.
  mapping(address => mapping (IERC20 => uint256)) public pendingAmount;

  // The allocations assigned to an address.
  mapping(address => Allocation[]) public userAllocations;

  /**
   * @dev Creates a new allocation for a beneficiary. Tokens are released
   * linearly over time until a given number of seconds have passed since the
   * start of the vesting schedule. Callable only by issuers.
   * @param _beneficiary The address to which tokens will be released
   * @param _amount The amount of the allocation (in wei)
   * @param _startAt The unix timestamp at which the vesting may begin
   * @param _cliff The number of seconds after _startAt before which no vesting occurs
   * @param _duration The number of seconds after which the entire allocation is vested
   */
  function issue(
    address _beneficiary,
    IERC20 _token,
    uint256 _amount,
    uint256 _startAt,
    uint256 _cliff,
    uint256 _duration
  ) external override {
    require(_amount > 0, "issue: zero-value allocations disallowed");
    require(_beneficiary != address(0), "issue: zero address disallowed");
    require(_cliff <= _duration, "issue: cliff exceeds duration");

    _token.safeTransferFrom(msg.sender, address(this), _amount);

    Allocation storage allocation = userAllocations[_beneficiary].push();
    allocation.token = _token;
    allocation.total = _amount;
    allocation.start = _startAt;
    allocation.duration = _duration;
    allocation.cliff = _cliff;

    pendingAmount[_beneficiary][_token] += _amount;

    emit Issued(
      _beneficiary,
      _token,
      _amount,
      _startAt,
      _cliff,
      _duration
    );
  }

  /**
   * @dev Revokes an existing allocation. Any unclaimed tokens are recalled
   * and sent to the caller. Callable only by the owner.
   * @param _beneficiary The address whose allocation is to be revoked
   * @param _id The allocation ID to revoke
   */
  function revoke(
    address _beneficiary,
    uint256 _id
  ) external override {
    Allocation storage allocation = userAllocations[_beneficiary][_id];

    // Calculate the remaining amount.
    uint256 total = allocation.total;
    uint256 remainder = total - allocation.claimed;

    // Update the total pending for the address.
    pendingAmount[_beneficiary][allocation.token] -= remainder;

    // Update the allocation to be claimed in full.
    allocation.claimed = total;

    // Transfer the tokens vested
    allocation.token.safeTransfer(owner(), remainder);
    emit Revoked(_beneficiary, _id, allocation.token, total, remainder);
  }

  /**
   * @dev Transfers vested tokens from any number of allocations to their beneficiary. Callable by anyone. May be gas-intensive.
   * @param _beneficiary The address that has vested tokens
   * @param _ids The vested allocation indexes
   */
  function release(
    address _beneficiary,
    uint256[] calldata _ids
  ) external override {
    for (uint256 i = 0; i < _ids.length; i++) {
      _release(_beneficiary, _ids[i]);
    }
  }

  /**
   * @dev Gets the number of allocations issued for a given address.
   * @param _beneficiary The address to check for allocations
   */
  function allocationCount(
    address _beneficiary
  ) external view override returns (uint256 count) {
    return userAllocations[_beneficiary].length;
  }

  /**
   * @dev Gets details about a given allocation.
   * @param _beneficiary Address to check
   * @param _id The allocation index
   * @return allocation The allocation
   * @return vested The total amount vested to date
   * @return releasable The amount currently releasable
   */
  function allocationSummary(
    address _beneficiary,
    uint256 _id
  ) external view override returns (
    Allocation memory allocation,
    uint256 vested,
    uint256 releasable
  ) {
    allocation = userAllocations[_beneficiary][_id];
    vested = _vestedAmount(allocation);
    releasable = _releasableAmount(allocation);
  }

  /**
   * @dev Transfers vested tokens from an allocation to its beneficiary.
   * @param _beneficiary The address that has vested tokens
   * @param _id The vested allocation index
   */
  function _release(
    address _beneficiary,
    uint256 _id
  ) internal {
    Allocation storage allocation = userAllocations[_beneficiary][_id];

    // Calculate the releasable amount.
    uint256 amount = _releasableAmount(allocation);
    require(amount > 0, "release: nothing here");

    // Add the amount to the allocation's total claimed.
    allocation.claimed += amount;

    // Subtract the amount from the beneficiary's total pending.
    pendingAmount[_beneficiary][allocation.token] -= amount;

    // Transfer the tokens to the beneficiary.
    allocation.token.safeTransfer(_beneficiary, amount);

    emit Released(
      _beneficiary,
      _id,
      allocation.token,
      amount,
      allocation.total - allocation.claimed
    );
  }

  /**
   * @dev Calculates the amount that has already vested but hasn't been released yet.
   * @param allocation Allocation to calculate against
   */
  function _releasableAmount(
    Allocation memory allocation
  ) internal view returns (uint256) {
    return _vestedAmount(allocation) - allocation.claimed;
  }

  /**
   * @dev Calculates the amount that has already vested.
   * @param allocation Allocation to calculate against
   */
  function _vestedAmount(
    Allocation memory allocation
  ) internal view returns (uint256 amount) {
    if (block.timestamp < allocation.start + allocation.cliff) {
      // Nothing is vested until after the start time + cliff length.
      amount = 0;
    } else if (
      block.timestamp >= allocation.start + allocation.duration
    ) {
      // The entire amount has vested if the entire duration has elapsed.
      amount = allocation.total;
    } else {
      // The initial tranche is available once the cliff expires, plus any portion of
      // tokens which have otherwise become vested as of the current block's timestamp.
      amount = allocation.total * (block.timestamp - allocation.start) / allocation.duration;
    }

    return amount;
  }
}

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title VestingVault
 * @dev A token vesting contract that will release tokens gradually like a
 * standard equity vesting schedule, with a cliff and vesting period but no
 * arbitrary restrictions on the frequency of claims. Optionally has an initial
 * tranche claimable immediately after the cliff expires (in addition to any
 * amounts that would have vested up to that point but didn't due to a cliff).
 */
interface IVestingVault {
  event Issued(
    address indexed beneficiary,
    IERC20 token,
    uint256 amount,
    uint256 start,
    uint256 cliff,
    uint256 duration
  );

  event Released(
    address indexed beneficiary,
    uint256 indexed allocationId,
    IERC20 token,
    uint256 amount,
    uint256 remaining
  );

  event Revoked(
    address indexed beneficiary,
    uint256 indexed allocationId,
    IERC20 token,
    uint256 allocationAmount,
    uint256 revokedAmount
  );

  struct Allocation {
    IERC20 token;
    uint256 start;
    uint256 cliff;
    uint256 duration;
    uint256 total;
    uint256 claimed;
  }

  /**
   * @dev Creates a new allocation for a beneficiary. Tokens are released
   * linearly over time until a given number of seconds have passed since the
   * start of the vesting schedule. Callable only by issuers.
   * @param _beneficiary The address to which tokens will be released
   * @param _amount The amount of the allocation (in wei)
   * @param _startAt The unix timestamp at which the vesting may begin
   * @param _cliff The number of seconds after _startAt before which no vesting occurs
   * @param _duration The number of seconds after which the entire allocation is vested
   */
  function issue(
    address _beneficiary,
    IERC20 _token,
    uint256 _amount,
    uint256 _startAt,
    uint256 _cliff,
    uint256 _duration
  ) external;

  /**
   * @dev Revokes an existing allocation. Any unclaimed tokens are recalled
   * and sent to the caller. Callable only be issuers.
   * @param _beneficiary The address whose allocation is to be revoked
   * @param _id The allocation ID to revoke
   */
  function revoke(
    address _beneficiary,
    uint256 _id
  ) external;

  /**
   * @dev Transfers vested tokens from any number of allocations to their beneficiary. Callable by anyone. May be gas-intensive.
   * @param _beneficiary The address that has vested tokens
   * @param _ids The vested allocation indexes
   */
  function release(
    address _beneficiary, 
    uint256[] calldata _ids
  ) external;

  /**
   * @dev Gets the number of allocations issued for a given address.
   * @param _beneficiary The address to check for allocations
   */
  function allocationCount(
    address _beneficiary
  ) external view returns (
    uint256 count
  );

  /**
   * @dev Gets details about a given allocation.
   * @param _beneficiary Address to check
   * @param _id The allocation index
   * @return allocation The allocation
   * @return vested The total amount vested to date
   * @return releasable The amount currently releasable
   */
  function allocationSummary(
    address _beneficiary,
    uint256 _id
  ) external view returns (
    Allocation memory allocation,
    uint256 vested,
    uint256 releasable
  );
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