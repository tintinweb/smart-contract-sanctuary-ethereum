// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

import "./storage/AbstractBatchStorage.sol";
import "./storage/AbstractViewableBatchStorage.sol";
import "../../utils/ContractRegistryAccess.sol";

contract ThreeXBatchVault is AbstractBatchStorage {
  bytes32 public contractId = keccak256("ThreeXBatchStorage");
  string public name = "3X Batch Vault v1";

  constructor(IContractRegistry _contractRegistry, address client) AbstractBatchStorage(_contractRegistry, client) {}
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./AbstractClientAccess.sol";
import "../../../interfaces/IBatchStorage.sol";

abstract contract AbstractBatchStorage is IAbstractBatchStorage, AbstractClientAccess {
  using SafeERC20 for IERC20;

  /* ========== STATE VARIABLES ========== */

  /**
   * @notice BatchId => account => balance in batch
   */
  mapping(bytes32 => mapping(address => uint256)) public accountBalances;
  mapping(address => bytes32[]) public accountBatches;
  mapping(bytes32 => Batch) public batches;
  bytes32[] public batchIds;

  /**
   * @dev allowances of client => recipient => batchId => token => amount
   */
  mapping(address => mapping(address => mapping(bytes32 => mapping(address => uint256)))) public allowances;

  /* ========== CONSTRUCTOR ========== */
  constructor(IContractRegistry __contractRegistry, address _client)
    AbstractClientAccess(__contractRegistry, _client)
  {}

  /* ========== EVENTS ========== */
  /* ========== VIEWS ========== */

  function getBatch(bytes32 batchId) public view virtual returns (Batch memory) {
    return batches[batchId];
  }

  function getBatchType(bytes32 batchId) public view virtual override returns (BatchType) {
    return batches[batchId].batchType;
  }

  /**
   * @notice Get ids for all batches that a user has interacted with
   * @param _account The address for whom we want to retrieve batches
   */
  function getAccountBatches(address _account) external view virtual returns (bytes32[] memory) {
    return accountBatches[_account];
  }

  /**
   * @notice Get ids for all batches that a user has interacted with
   * @param _account The address for whom we want to retrieve batches
   */
  function getAccountBalance(bytes32 batchId, address _account) external view virtual returns (uint256) {
    return accountBalances[batchId][_account];
  }

  /* ========== MODIFIERS ========== */

  modifier onlyOwnerOf(bytes32 batchId) {
    _onlyClients();
    Batch storage batch = batches[batchId];
    require(
      batch.owner == msg.sender || delegates[batch.owner][msg.sender],
      "client does not have access to this batch"
    );
    _;
  }

  /* ========== ADMIN FUNCTIONS (CLIENT ONLY) ========== */

  function createBatch(BatchType _batchType, BatchTokens memory _tokens)
    external
    override(IAbstractBatchStorage)
    onlyClients
    returns (bytes32)
  {
    bytes32 _id = _generateId();
    batchIds.push(_id);
    Batch storage batch = batches[_id];
    batch.batchType = _batchType;
    batch.batchId = _id;
    batch.sourceToken = _tokens.sourceToken;
    batch.targetToken = _tokens.targetToken;
    batch.owner = msg.sender;
    return _id;
  }

  function deposit(
    bytes32 batchId,
    address owner,
    uint256 amount
  ) public override onlyOwnerOf(batchId) returns (uint256) {
    Batch storage batch = batches[batchId];
    // todo allow anyone to deposit to this batch, not just the client address
    return _deposit(batch, owner, amount, msg.sender);
  }

  function _deposit(
    Batch storage batch,
    address owner,
    uint256 amount,
    address sender
  ) internal returns (uint256) {
    require(!batch.claimable, "can't deposit");
    batch.sourceTokenBalance += amount;
    batch.unclaimedShares += amount;
    accountBalances[batch.batchId][owner] += amount;
    _cacheAccount(batch.batchId, owner);
    _transferFrom(batch.sourceToken, sender, address(this), amount);
    return amount;
  }

  /**
   * @notice This function checks all requirements for claiming, updates batches and balances and transfers tokens
   */

  function claim(
    bytes32 batchId,
    address owner,
    uint256 shares,
    address recipient
  ) public override onlyOwnerOf(batchId) returns (uint256, uint256) {
    Batch storage batch = batches[batchId];
    require(batch.claimable, "not yet claimable");

    uint256 claimAmount = shares == 0 ? accountBalances[batchId][owner] : shares;

    (uint256 claimableTokenBalance, uint256 claimAccountBalanceBefore, ) = previewClaim(batchId, owner, claimAmount);

    accountBalances[batchId][owner] -= claimAmount;
    batch.targetTokenBalance -= claimableTokenBalance;
    batch.unclaimedShares -= claimAmount;

    _transfer(batch.targetToken, owner, recipient, batchId, claimableTokenBalance);

    return (claimableTokenBalance, claimAccountBalanceBefore);
  }

  function previewClaim(
    bytes32 batchId,
    address owner,
    uint256 shares
  )
    public
    view
    override
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    Batch memory batch = batches[batchId];
    uint256 claimAccountBalanceBefore = accountBalances[batchId][owner];

    require(shares <= batch.unclaimedShares && shares <= claimAccountBalanceBefore, "insufficient balance");

    uint256 targetTokenBalance = (batch.targetTokenBalance * shares) / batch.unclaimedShares;

    return (targetTokenBalance, claimAccountBalanceBefore, claimAccountBalanceBefore - shares);
  }

  /**
   * @notice Moves funds from unclaimed batches into the current mint/redeem batch
   * @param _sourceBatch the id of the claimable batch
   * @param _destinationBatch the id of the redeem batch
   * @param owner owner of the account balance
   * @param shares how many shares should be claimed
   */
  function moveUnclaimedIntoCurrentBatch(
    bytes32 _sourceBatch,
    bytes32 _destinationBatch,
    address owner,
    uint256 shares
  ) external override onlyOwnerOf(_sourceBatch) onlyOwnerOf(_destinationBatch) returns (uint256) {
    Batch storage sourceBatch = batches[_sourceBatch];
    Batch storage destinationBatch = batches[_destinationBatch];

    require(sourceBatch.claimable, "not yet claimable");
    require(sourceBatch.batchType != destinationBatch.batchType, "incorrect batchType");
    require(sourceBatch.targetToken == destinationBatch.sourceToken, "tokens don't match");

    (uint256 targetTokenBalance, ) = claim(_sourceBatch, owner, shares, address(0));
    return _deposit(destinationBatch, owner, targetTokenBalance, address(0));
  }

  /**
   * @notice This function allows a user to withdraw their funds from a batch before that batch has been processed
   * @param batchId From which batch should funds be withdrawn from
   * @param owner address that owns the account balance
   * @param amount amount of tokens to withdraw from batch
   * @param recipient address that will receive the token transfer. if address(0) then no transfer is made
   */
  function withdraw(
    bytes32 batchId,
    address owner,
    uint256 amount,
    address recipient
  ) public override onlyOwnerOf(batchId) returns (uint256) {
    // todo make this public so account owners can withdraw
    Batch storage batch = batches[batchId];
    require(accountBalances[batchId][owner] >= amount);
    require(batch.claimable == false, "already processed");

    //At this point the account balance is equal to the supplied token and can be used interchangeably
    accountBalances[batchId][owner] -= amount;
    batch.sourceTokenBalance -= amount;
    batch.unclaimedShares -= amount;

    _transfer(batch.sourceToken, owner, recipient, batchId, amount);
    return (amount);
  }

  /**
   * @notice approve allows the client contract to approve an address to be the recipient of a withdrawal or claim
   */
  function approve(
    IERC20 token,
    address delegatee,
    bytes32 batchId,
    uint256 amount
  ) external override(IAbstractBatchStorage) onlyOwnerOf(batchId) {
    allowances[msg.sender][delegatee][batchId][address(token)] = amount;
  }

  /**
   * @notice This function transfers the batch source tokens to the client usually for a minting or redeming operation
   * @param batchId From which batch should funds be withdrawn from
   */
  function withdrawSourceTokenFromBatch(bytes32 batchId)
    public
    override(IAbstractBatchStorage)
    onlyOwnerOf(batchId)
    returns (uint256)
  {
    Batch storage batch = batches[batchId];
    require(!batch.claimable, "already processed");
    batch.sourceToken.safeTransfer(msg.sender, batch.sourceTokenBalance);
    return (batch.sourceTokenBalance);
  }

  function depositTargetTokensIntoBatch(bytes32 batchId, uint256 amount)
    external
    override(IAbstractBatchStorage)
    onlyOwnerOf(batchId)
    returns (bool)
  {
    Batch storage batch = batches[batchId];
    require(!batch.claimable, "deposit already made"); // todo allow multiple deposits

    batch.targetToken.safeTransferFrom(msg.sender, address(this), amount);

    batch.claimable = true;
    batch.targetTokenBalance += amount;

    return true;
  }

  /* ========== INTERNAL ========== */

  /**
   * todo `clients` ultimately may withdraw tokens for a batch they create at anytime by calling withdrawSourceTokenFromBatch. tokens may be transfered out of this contract if the given recipient is a registered client or if the client has granted an allowance to a recipient to receive tokens. this means that in order to trust this contract, you must look at the clients because they can give themselves infinite allowance as a recipient of a target token from this contract. simply put, a rogue contract may infinite approve everything held by the contract and potentially send to itself.  any new client to this contract must be reviewed to ensure it does not make a claim or withdrawal for an address for which it should not. thought was given to designing this in a way to offer permissionless batch logic for any client, but greater attention would need to be given to scopes and boundaries. consider apodoting eip-1155 / eip-4626  standard interfaces for greater interoperability
   */
  function _transfer(
    IERC20 token,
    address owner,
    address recipient,
    bytes32 batchId,
    uint256 amount
  ) internal {
    if (recipient != address(0)) {
      Batch memory batch = batches[batchId];
      uint256 allowance = allowances[msg.sender][recipient][batchId][address(token)];
      bool hasAllowance = allowance >= amount;

      require(
        recipient == owner || hasAllowance || recipient == batch.owner || delegates[batch.owner][recipient],
        "won't send"
      );

      if (hasAllowance && allowance != 0) {
        allowances[msg.sender][recipient][batchId][address(token)] -= amount;
      }

      token.safeTransfer(recipient, amount);
    }
  }

  function _transferFrom(
    IERC20 token,
    address sender,
    address recipient,
    uint256 amount
  ) internal {
    if (sender != address(0) && recipient != address(0)) {
      token.safeTransferFrom(sender, recipient, amount);
    }
  }

  function _cacheAccount(bytes32 _id, address _owner) internal {
    //Save the batchId for the user so they can be retrieved to claim the batch
    if (accountBatches[_owner].length == 0 || accountBatches[_owner][accountBatches[_owner].length - 1] != _id) {
      accountBatches[_owner].push(_id);
    }
  }

  /**
   * @notice Generates the next batch id hashing the last batchId and timestamp
   */
  function _generateId() private view returns (bytes32) {
    bytes32 previousBatchId = batchIds.length > 0 ? batchIds[batchIds.length - 1] : bytes32("");
    return keccak256(abi.encodePacked(block.timestamp, previousBatchId));
  }
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../../utils/ContractRegistryAccess.sol";
import "../../../utils/ACLAuth.sol";
import "../../../interfaces/IACLRegistry.sol";
import "../../../interfaces/IContractRegistry.sol";
import "../../../interfaces/IBatchStorage.sol";
import "./Initializable.sol";

abstract contract AbstractClientAccess is ACLAuth, Initializable, ContractRegistryAccess, IClientBatchStorageAccess {
  // keccak("UPDATE_BATCH_STORAGE_CLIENT_ACTION")
  bytes32 constant UPDATE_BATCH_STORAGE_CLIENT_ACTION =
    0xb6f070e601e3563e164a63cf18567d22a74f31de2ff3f805afb7fa0c4d982e9c;

  constructor(IContractRegistry __contractRegistry, address _client) ContractRegistryAccess(__contractRegistry) {
    addClient(_client == address(0) ? msg.sender : _client);
    initialized = true;
  }

  /**
   * @dev  a mapping is made here when a client contract grants access to their batches to another client
   * owner => delegate => bool
   */
  mapping(address => mapping(address => bool)) public delegates;

  /**
   * @dev pendingClientAccessGrants contains mapping of current client to delegated clients that may accept a transfer after the given timestamp
   * client => newClient => validTransferAfter_timestamp
   */
  mapping(address => mapping(address => uint256)) public pendingClientAccessGrants;

  /**
   * @dev clients are allowed to use the batch storage contract. we allow many clients to use the batch contract. however, all batches are owned by the client which created the batch. clients have the ability to make claims / withdrawals and transfer tokens on behalf of depositors.
   */
  mapping(address => bool) public clients;

  function grantClientAccess(address newClient) external override onlyClients {
    pendingClientAccessGrants[msg.sender][newClient] = block.timestamp + 2 days;
  }

  function revokeClientAccess(address client) external override onlyClients {
    if (delegates[msg.sender][client]) {
      delegates[msg.sender][client] = false;
      clients[client] = false;
    }
  }

  function acceptClientAccess(address grantingAddress) external override {
    uint256 transferValidFrom = pendingClientAccessGrants[grantingAddress][msg.sender];
    require(transferValidFrom > 0 && transferValidFrom < block.timestamp, "access not valid");
    delegates[grantingAddress][msg.sender] = true;
    clients[msg.sender] = true;
  }

  /**
   * @notice DAO role can add any client. This is used to allow clients to use the batch storage contract.
   */
  function addClient(address _address) public override {
    bool hasPermission = acl().hasRole(DAO_ROLE, msg.sender) ||
      acl().hasPermission(UPDATE_BATCH_STORAGE_CLIENT_ACTION, msg.sender);
    if (!initialized || hasPermission) {
      clients[_address] = true;
    }
  }

  /**
   * @notice DAO role can remove any client. This is used to remove clients that are no longer using the batch storage contract. A client may remove itself by calling this function.
   */
  function removeClient(address _address) public override {
    bool hasPermission = acl().hasRole(DAO_ROLE, msg.sender) ||
      acl().hasPermission(UPDATE_BATCH_STORAGE_CLIENT_ACTION, msg.sender);
    if (hasPermission || (clients[msg.sender] && _address == msg.sender)) {
      clients[_address] = false;
    }
  }

  function acl() internal view returns (IACLRegistry) {
    return IACLRegistry(_getContract(keccak256("ACLRegistry")));
  }

  function _getContract(bytes32 _name)
    internal
    view
    virtual
    override(ACLAuth, ContractRegistryAccess)
    returns (address)
  {
    return IContractRegistry(_contractRegistry).getContract(_name);
  }

  modifier onlyClients() {
    _onlyClients();
    _;
  }

  function _onlyClients() internal view {
    require(clients[msg.sender], "!allowed");
  }
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

import "../../../interfaces/IBatchStorage.sol";
import "./AbstractBatchStorage.sol";

abstract contract AbstractViewableBatchStorage {
  AbstractBatchStorage public batchStorage;

  constructor() {}

  /**
   * @notice Get ids for all batches that a user has interacted with
   * @param _account The address for whom we want to retrieve batches
   */
  function getAccountBatches(address _account) external view returns (bytes32[] memory) {
    return batchStorage.getAccountBatches(_account);
  }

  function getAccountBalance(bytes32 _id, address _owner) public view virtual returns (uint256) {
    return batchStorage.accountBalances(_id, _owner);
  }

  function getAccountBatchIds(address account) public view returns (bytes32[] memory) {
    return batchStorage.getAccountBatches(account);
  }

  function getBatch(bytes32 batchId) public view virtual returns (Batch memory) {
    return batchStorage.getBatch(batchId);
  }

  /* ========== VIEWS ========== */

  function getBatchType(bytes32 batchId) external view virtual returns (BatchType) {
    Batch memory batch = batchStorage.getBatch(batchId);
    require(batch.batchId != "");
    return batch.batchType;
  }
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

abstract contract Initializable {
  bool public initialized;
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IACLRegistry {
  /**
   * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
   *
   * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
   * {RoleAdminChanged} not being emitted signaling this.
   *
   * _Available since v3.1._
   */
  event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

  /**
   * @dev Emitted when `account` is granted `role`.
   *
   * `sender` is the account that originated the contract call, an admin role
   * bearer except when using {AccessControl-_setupRole}.
   */
  event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

  /**
   * @dev Emitted when `account` is revoked `role`.
   *
   * `sender` is the account that originated the contract call:
   *   - if using `revokeRole`, it is the admin role bearer
   *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
   */
  event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

  /**
   * @dev Returns `true` if `account` has been granted `role`.
   */
  function hasRole(bytes32 role, address account) external view returns (bool);

  /**
   * @dev Returns `true` if `account` has been granted `permission`.
   */
  function hasPermission(bytes32 permission, address account) external view returns (bool);

  /**
   * @dev Returns the admin role that controls `role`. See {grantRole} and
   * {revokeRole}.
   *
   * To change a role's admin, use {AccessControl-_setRoleAdmin}.
   */
  function getRoleAdmin(bytes32 role) external view returns (bytes32);

  /**
   * @dev Grants `role` to `account`.
   *
   * If `account` had not been already granted `role`, emits a {RoleGranted}
   * event.
   *
   * Requirements:
   *
   * - the caller must have ``role``'s admin role.
   */
  function grantRole(bytes32 role, address account) external;

  /**
   * @dev Revokes `role` from `account`.
   *
   * If `account` had been granted `role`, emits a {RoleRevoked} event.
   *
   * Requirements:
   *
   * - the caller must have ``role``'s admin role.
   */
  function revokeRole(bytes32 role, address account) external;

  /**
   * @dev Revokes `role` from the calling account.
   *
   * Roles are often managed via {grantRole} and {revokeRole}: this function's
   * purpose is to provide a mechanism for accounts to lose their privileges
   * if they are compromised (such as when a trusted device is misplaced).
   *
   * If the calling account had been granted `role`, emits a {RoleRevoked}
   * event.
   *
   * Requirements:
   *
   * - the caller must be `account`.
   */
  function renounceRole(bytes32 role, address account) external;

  function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

  function grantPermission(bytes32 permission, address account) external;

  function revokePermission(bytes32 permission) external;

  function requireApprovedContractOrEOA(address account) external view;

  function requireRole(bytes32 role, address account) external view;

  function requirePermission(bytes32 permission, address account) external view;

  function isRoleAdmin(bytes32 role, address account) external view;
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IClientBatchStorageAccess } from "./IClientBatchStorageAccess.sol";
/**
 * @notice Defines if the Batch will mint or redeem 3X
 */
enum BatchType {
  Mint,
  Redeem
}

/**
 * @notice The Batch structure is used both for Batches of Minting and Redeeming
 * @param batchType Determines if this Batch is for Minting or Redeeming 3X
 * @param batchId bytes32 id of the batch
 * @param claimable Shows if a batch has been processed and is ready to be claimed, the suppliedToken cant be withdrawn if a batch is claimable
 * @param unclaimedShares The total amount of unclaimed shares in this batch
 * @param sourceTokenBalance The total amount of deposited token (either DAI or 3X)
 * @param claimableTokenBalance The total amount of claimable token (either sUSD or 3X)
 * @param sourceToken the token one supplies for minting/redeeming another token. the token collateral used to mint or redeem a mintable/redeemable token
 * @param targetToken the token that is claimable after providing the suppliedToken for mint/redeem. the token that a mintable/redeemable token turns into during mint/redeem
 * @param owner address of client (controller contract) that owns this batch and has access rights to it. this makes it so that all balances are isolated and not accessible by other clients that added to this contract over time
 * todo add deposit caps
 */
struct Batch {
  bytes32 id;
  BatchType batchType;
  bytes32 batchId;
  bool claimable;
  uint256 unclaimedShares;
  uint256 sourceTokenBalance;
  uint256 targetTokenBalance;
  IERC20 sourceToken;
  IERC20 targetToken;
  address owner;
}

/**
 * @notice Each type of batch (mint/redeem) have a source token and target token.
 * @param targetToken the token which is minted or redeemed for
 * @param sourceToken the token which is supplied to the batch to be minted/redeemed
 */
struct BatchTokens {
  IERC20 targetToken;
  IERC20 sourceToken;
}

interface IViewableBatchStorage {
  function getAccountBatches(address account) external view returns (bytes32[] memory);

  function getBatch(bytes32 batchId) external view returns (Batch memory);

  function getBatchIds(uint256 index) external view returns (Batch memory);

  function getAccountBalance(bytes32 batchId, address owner) external view returns (uint256);
}

interface IAbstractBatchStorage is IClientBatchStorageAccess {
  function getBatchType(bytes32 batchId) external view returns (BatchType);

  /* ========== VIEW ========== */

  function previewClaim(
    bytes32 batchId,
    address owner,
    uint256 shares
  )
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    );

  /* ========== SETTER ========== */

  function claim(
    bytes32 batchId,
    address owner,
    uint256 shares,
    address recipient
  ) external returns (uint256, uint256);

  /**
   * @notice This function allows a user to withdraw their funds from a batch before that batch has been processed
   * @param batchId From which batch should funds be withdrawn from
   * @param owner address that owns the account balance
   * @param amount amount of tokens to withdraw from batch
   * @param recipient address that will receive the token transfer. if address(0) then no transfer is made
   */
  function withdraw(
    bytes32 batchId,
    address owner,
    uint256 amount,
    address recipient
  ) external returns (uint256);

  function deposit(
    bytes32 batchId,
    address owner,
    uint256 amount
  ) external returns (uint256);

  /**
   * @notice approve allows the client contract to approve an address to be the recipient of a withdrawal or claim
   */
  function approve(
    IERC20 token,
    address delegatee,
    bytes32 batchId,
    uint256 amount
  ) external;

  /**
   * @notice This function transfers the batch source tokens to the client usually for a minting or redeming operation
   * @param batchId From which batch should funds be withdrawn from
   */
  function withdrawSourceTokenFromBatch(bytes32 batchId) external returns (uint256);

  /**
   * @notice Moves funds from unclaimed batches into the current mint/redeem batch
   * @param _sourceBatch the id of the claimable batch
   * @param _destinationBatch the id of the redeem batch
   * @param owner owner of the account balance
   * @param shares how many shares should be claimed
   */
  function moveUnclaimedIntoCurrentBatch(
    bytes32 _sourceBatch,
    bytes32 _destinationBatch,
    address owner,
    uint256 shares
  ) external returns (uint256);

  function depositTargetTokensIntoBatch(bytes32 id, uint256 amount) external returns (bool);

  function createBatch(BatchType _batchType, BatchTokens memory _tokens) external returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IClientBatchStorageAccess {
  function grantClientAccess(address newClient) external;

  function revokeClientAccess(address client) external;

  function acceptClientAccess(address grantingAddress) external;

  function addClient(address _address) external;

  function removeClient(address _address) external;
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity >=0.6.12;

/**
 * @dev External interface of ContractRegistry.
 */
interface IContractRegistry {
  function getContract(bytes32 _name) external view returns (address);

  function getContractIdFromAddress(address _contractAddress) external view returns (bytes32);

  function addContract(
    bytes32 _name,
    address _address,
    bytes32 _version
  ) external;
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

import "../interfaces/IACLRegistry.sol";

/**
 *  @notice Provides modifiers and internal functions for interacting with the `ACLRegistry`
 *  @dev Derived contracts using `ACLAuth` must also inherit `ContractRegistryAccess`
 *   and override `_getContract`.
 */
abstract contract ACLAuth {
  /**
   *  @dev Equal to keccak256("Keeper")
   */
  bytes32 internal constant KEEPER_ROLE = 0x4f78afe9dfc9a0cb0441c27b9405070cd2a48b490636a7bdd09f355e33a5d7de;

  /**
   *  @dev Equal to keccak256("DAO")
   */
  bytes32 internal constant DAO_ROLE = 0xd0a4ad96d49edb1c33461cebc6fb2609190f32c904e3c3f5877edb4488dee91e;

  /**
   *  @dev Equal to keccak256("GUARDIAN_ROLE")
   */
  bytes32 internal constant GUARDIAN_ROLE = 0x55435dd261a4b9b3364963f7738a7a662ad9c84396d64be3365284bb7f0a5041;

  /**
   *  @dev Equal to keccak256("ApprovedContract")
   */
  bytes32 internal constant APPROVED_CONTRACT_ROLE = 0xfb639edf4b4a4724b8b9fb42a839b712c82108c1edf1beb051bcebce8e689dc4;

  /**
   *  @dev Equal to keccak256("ACLRegistry")
   */
  bytes32 internal constant ACL_REGISTRY_ID = 0x15fa0125f52e5705da1148bfcf00974823c4381bee4314203ede255f9477b73e;

  /**
   *  @notice Require that `msg.sender` has given role
   *  @param role bytes32 role ID
   */
  modifier onlyRole(bytes32 role) {
    _requireRole(role);
    _;
  }

  /**
   *  @notice Require that `msg.sender` has at least one of the given roles
   *  @param roleA bytes32 role ID
   *  @param roleB bytes32 role ID
   */
  modifier onlyRoles(bytes32 roleA, bytes32 roleB) {
    require(_hasRole(roleA, msg.sender) == true || _hasRole(roleB, msg.sender) == true, "you dont have the right role");
    _;
  }

  /**
   *  @notice Require that `msg.sender` has given permission
   *  @param role bytes32 permission ID
   */
  modifier onlyPermission(bytes32 role) {
    _requirePermission(role);
    _;
  }

  /**
   *  @notice Require that `msg.sender` has the `ApprovedContract` role or is an EOA
   *  @dev This EOA check requires that `tx.origin == msg.sender` if caller does not have the `ApprovedContract` role.
   *  This limits compatibility with contract-based wallets for functions protected with this modifier.
   */
  modifier onlyApprovedContractOrEOA() {
    _requireApprovedContractOrEOA(msg.sender);
    _;
  }

  /**
   *  @notice Check whether a given account has been granted this bytes32 role
   *  @param role bytes32 role ID
   *  @param account address of account to check for role
   *  @return Whether account has been granted specified role.
   */
  function _hasRole(bytes32 role, address account) internal view returns (bool) {
    return _aclRegistry().hasRole(role, account);
  }

  /**
   *  @notice Require that `msg.sender` has given role
   *  @param role bytes32 role ID
   */
  function _requireRole(bytes32 role) internal view {
    _requireRole(role, msg.sender);
  }

  /**
   *  @notice Require that given account has specified role
   *  @param role bytes32 role ID
   *  @param account address of account to check for role
   */
  function _requireRole(bytes32 role, address account) internal view {
    _aclRegistry().requireRole(role, account);
  }

  /**
   *  @notice Check whether a given account has been granted this bytes32 permission
   *  @param permission bytes32 permission ID
   *  @param account address of account to check for permission
   *  @return Whether account has been granted specified permission.
   */
  function _hasPermission(bytes32 permission, address account) internal view returns (bool) {
    return _aclRegistry().hasPermission(permission, account);
  }

  /**
   *  @notice Require that `msg.sender` has specified permission
   *  @param permission bytes32 permission ID
   */
  function _requirePermission(bytes32 permission) internal view {
    _requirePermission(permission, msg.sender);
  }

  /**
   *  @notice Require that given account has specified permission
   *  @param permission bytes32 permission ID
   *  @param account address of account to check for permission
   */
  function _requirePermission(bytes32 permission, address account) internal view {
    _aclRegistry().requirePermission(permission, account);
  }

  /**
   *  @notice Require that `msg.sender` has the `ApprovedContract` role or is an EOA
   *  @dev This EOA check requires that `tx.origin == msg.sender` if caller does not have the `ApprovedContract` role.
   *  This limits compatibility with contract-based wallets for functions protected with this modifier.
   */
  function _requireApprovedContractOrEOA() internal view {
    _requireApprovedContractOrEOA(msg.sender);
  }

  /**
   *  @notice Require that `account` has the `ApprovedContract` role or is an EOA
   *  @param account address of account to check for role/EOA
   *  @dev This EOA check requires that `tx.origin == msg.sender` if caller does not have the `ApprovedContract` role.
   *  This limits compatibility with contract-based wallets for functions protected with this modifier.
   */
  function _requireApprovedContractOrEOA(address account) internal view {
    _aclRegistry().requireApprovedContractOrEOA(account);
  }

  /**
   *  @notice Return an IACLRegistry interface to the registered ACLRegistry contract
   *  @return IACLRegistry interface to ACLRegistry contract
   */
  function _aclRegistry() internal view returns (IACLRegistry) {
    return IACLRegistry(_getContract(ACL_REGISTRY_ID));
  }

  /**
   *  @notice Get a contract address by name from the contract registry
   *  @param _name bytes32 contract name
   *  @return contract address
   *  @dev Users of this abstract contract should also inherit from `ContractRegistryAccess`
   *   and override `_getContract` in their implementation.
   */
  function _getContract(bytes32 _name) internal view virtual returns (address);
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

import "../interfaces/IContractRegistry.sol";

/**
 *  @notice Provides an internal `_getContract` helper function to access the `ContractRegistry`
 */
abstract contract ContractRegistryAccess {
  IContractRegistry internal _contractRegistry;

  constructor(IContractRegistry contractRegistry_) {
    require(address(contractRegistry_) != address(0), "Zero address");
    _contractRegistry = contractRegistry_;
  }

  /**
   *  @notice Get a contract address by bytes32 name
   *  @param _name bytes32 contract name
   *  @dev contract name should be a keccak256 hash of the name string, e.g. `keccak256("ContractName")`
   *  @return contract address
   */
  function _getContract(bytes32 _name) internal view virtual returns (address) {
    return _contractRegistry.getContract(_name);
  }

  /**
   *  @notice Get contract id from contract address.
   *  @param _contractAddress contract address
   *  @return name - keccak256 hash of the name string  e.g. `keccak256("ContractName")`
   */
  function _getContractIdFromAddress(address _contractAddress) internal view virtual returns (bytes32) {
    return _contractRegistry.getContractIdFromAddress(_contractAddress);
  }
}