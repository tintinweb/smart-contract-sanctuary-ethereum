// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later


library AMOCommon {
    error NotOperator();
    error NotOperatorOrOwner();
    error ZeroSwapLimit();
    error OnlyAMO();
    error AboveCappedAmount(uint256 amountIn);
    error InsufficientBPTAmount(uint256 amount);
    error InvalidBPSValue(uint256 value);
    error InsufficientAmountOutPostcall(uint256 expectedAmount, uint256 actualAmount);
    error InvalidMaxAmounts(uint256 bptMaxAmount, uint256 stableMaxAmount, uint256 templeMaxAmount);
    error InvalidBalancerVaultRequest();
    error NotEnoughCooldown();
    error NoRebalanceUp();
    error NoRebalanceDown();
    error HighSlippage();
    error Paused();
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later

interface AMO__IAuraBooster {

    struct PoolInfo {
        address lptoken;
        address token;
        address gauge;
        address crvRewards;
        address stash;
        bool shutdown;
    }
    function poolInfo(uint256 _pid) external view returns (PoolInfo memory);
    function isShutdown() external view returns (bool);

    function deposit(uint256 _pid, uint256 _amount, bool _stake) external returns (bool);
    function depositAll(uint256 _pid, bool _stake) external returns(bool);
    function earmarkRewards(uint256 _pid) external returns(bool);
    function claimRewards(uint256 _pid, address _gauge) external returns(bool);
    function earmarkFees(address _feeToken) external returns(bool);
    function minter() external view returns (address);

    event Deposited(address indexed user, uint256 indexed poolid, uint256 amount);
    event Withdrawn(address indexed user, uint256 indexed poolid, uint256 amount);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later


interface AMO__IAuraStaking {
    function setAuraPoolInfo(uint32 _pId, address _token, address _rewards) external;

    function setOperator(address _operator) external;

    function recoverToken(address token, address to, uint256 amount) external;

    function depositAndStake(uint256 amount) external;

    function depositAllAndStake() external;

    function withdrawAll(bool claim, bool sendToOperator) external;

    function withdraw(uint256 amount, bool claim, bool sendToOperator) external;

    function withdrawAndUnwrap(uint256 amount, bool claim, address to) external;

    function withdrawAllAndUnwrap(bool claim, bool sendToOperator) external;

    function getReward(bool claimExtras) external;

    function stakedBalance() external view returns (uint256);

    function earned() external view returns (uint256);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface AMO__IBalancerVault {

  struct JoinPoolRequest {
    IERC20[] assets;
    uint256[] maxAmountsIn;
    bytes userData;
    bool fromInternalBalance;
  }

  struct ExitPoolRequest {
    address[] assets;
    uint256[] minAmountsOut;
    bytes userData;
    bool toInternalBalance;
  }

  struct BatchSwapStep {
    bytes32 poolId;
    uint256 assetInIndex;
    uint256 assetOutIndex;
    uint256 amount;
    bytes userData;
  }

  struct FundManagement {
    address sender;
    bool fromInternalBalance;
    address payable recipient;
    bool toInternalBalance;
  }

  enum JoinKind { 
    INIT, 
    EXACT_TOKENS_IN_FOR_BPT_OUT, 
    TOKEN_IN_FOR_EXACT_BPT_OUT, 
    ALL_TOKENS_IN_FOR_EXACT_BPT_OUT 
  }

  enum SwapKind {
    GIVEN_IN,
    GIVEN_OUT
  }

  function batchSwap(
    SwapKind kind,
    BatchSwapStep[] memory swaps,
    address[] memory assets,
    FundManagement memory funds,
    int256[] memory limits,
    uint256 deadline
  ) external returns (int256[] memory assetDeltas);

  function joinPool(
    bytes32 poolId,
    address sender,
    address recipient,
    JoinPoolRequest memory request
  ) external payable;

  function exitPool( 
    bytes32 poolId, 
    address sender, 
    address recipient, 
    ExitPoolRequest memory request 
  ) external;

  function getPoolTokens(
    bytes32 poolId
  ) external view
    returns (
      address[] memory tokens,
      uint256[] memory balances,
      uint256 lastChangeBlock
  );
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later


import "./AMO__IBalancerVault.sol";

interface AMO__IPoolHelper {

    function getBalances() external view returns (uint256[] memory balances);

    function spotPriceUsingLPRatio() external view returns (uint256 templeBalance, uint256 stableBalance);

    function getSpotPriceScaled() external view returns (uint256 spotPriceScaled);

    function isSpotPriceBelowTPF() external view returns (bool);

    function isSpotPriceBelowTPF(uint256 slippage) external view returns (bool);

    function isSpotPriceAboveTPF(uint256 slippage) external view returns (bool);
    
    function isSpotPriceBelowTPFLowerBound() external view returns (bool);

    function isSpotPriceAboveTPFUpperBound() external view returns (bool);

    function isSpotPriceAboveTPF() external view returns (bool);

    function willExitTakePriceAboveTPFUpperBound(uint256 tokensOut) external view returns (bool);

    function willJoinTakePriceBelowTPFLowerBound(uint256 tokensIn) external view returns (bool);

    function getSlippage(uint256 spotPriceBeforeScaled) external view returns (uint256);

    function getMax(uint256 a, uint256 b) external pure returns (uint256 maxValue);
    
    function templeBalancerPoolIndex() external view returns (uint64);
    function balancerVault() external view returns (address);
    function balancerPoolId() external view returns (bytes32);

    function exitPool(
        uint256 bptAmountIn,
        uint256 minAmountOut,
        uint256 rebalancePercentageBoundLow,
        uint256 rebalancePercentageBoundUp,
        uint256 postRebalanceSlippage,
        uint256 exitTokenIndex,
        uint256 templePriceFloorNumerator,
        IERC20 exitPoolToken
    ) external returns (uint256 amountOut);

    function joinPool(
        uint256 amountIn,
        uint256 minBptOut,
        uint256 rebalancePercentageBoundUp,
        uint256 rebalancePercentageBoundLow,
        uint256 templePriceFloorNumerator,
        uint256 postRebalanceSlippage,
        uint256 joinTokenIndex,
        IERC20 joinPoolToken
    ) external returns (uint256 bptIn);

    function createPoolJoinRequest(
        IERC20 temple,
        IERC20 stable,
        uint256 amountIn,
        uint256 tokenIndex,
        uint256 minTokenOut
    ) external view returns (AMO__IBalancerVault.JoinPoolRequest memory request);

    function createPoolExitRequest(
        address temple,
        address stable,
        uint256 bptAmountIn,
        uint256 tokenIndex,
        uint256 minAmountOut,
        uint256 exitTokenIndex
    ) external view returns (AMO__IBalancerVault.ExitPoolRequest memory request);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later

interface AMO__ITempleERC20Token {
    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/AMO__IPoolHelper.sol";
import "./interfaces/AMO__IAuraBooster.sol";
import "./interfaces/AMO__ITempleERC20Token.sol";
import "./helpers/AMOCommon.sol";
import "./interfaces/AMO__IAuraStaking.sol";

/**
 * @title AMO built for 50TEMPLE-50BB-A-USD balancer pool
 *
 * @dev It has a  convergent price to which it trends called the TPF (Treasury Price Floor).
 * In order to accomplish this when the price is below the TPF it will single side withdraw 
 * BPTs into TEMPLE and burn them and if the price is above the TPF it will 
 * single side deposit TEMPLE into the pool to drop the spot price.
 */
contract RAMOS is Ownable, Pausable {
    using SafeERC20 for IERC20;

    AMO__IBalancerVault public immutable balancerVault;
    // @notice BPT token address
    IERC20 public immutable bptToken;
    // @notice Aura booster
    AMO__IAuraBooster public immutable booster;
    // @notice pool helper contract
    AMO__IPoolHelper public poolHelper;
    
    // @notice AMO contract for staking into aura 
    AMO__IAuraStaking public amoStaking;

    address public operator;
    IERC20 public immutable temple;
    IERC20 public immutable stable;

    // @notice lastRebalanceTimeSecs and cooldown used to control call rate 
    // for operator
    uint64 public lastRebalanceTimeSecs;
    uint64 public cooldownSecs;

    // @notice balancer 50/50 pool ID.
    bytes32 public immutable balancerPoolId;

    // @notice Precision for BPS calculations
    uint256 public constant BPS_PRECISION = 10_000;
    uint256 public templePriceFloorNumerator;

    // @notice percentage bounds (in bps) beyond which to rebalance up or down
    uint64 public rebalancePercentageBoundLow;
    uint64 public rebalancePercentageBoundUp;

    // @notice Maximum amount of tokens that can be rebalanced
    MaxRebalanceAmounts public maxRebalanceAmounts;

    // @notice by how much TPF slips up or down after rebalancing. In basis points
    uint64 public postRebalanceSlippage;

    // @notice temple index in balancer pool. to avoid recalculation or external calls
    uint64 public immutable templeBalancerPoolIndex;

    struct MaxRebalanceAmounts {
        uint256 bpt;
        uint256 stable;
        uint256 temple;
    }

    event RecoveredToken(address token, address to, uint256 amount);
    event SetOperator(address operator);
    event SetPostRebalanceSlippage(uint64 slippageBps);
    event SetCooldown(uint64 cooldownSecs);
    event SetPauseState(bool paused);
    event StableDeposited(uint256 amountIn, uint256 bptOut);
    event RebalanceUp(uint256 bptAmountIn, uint256 templeAmountOut);
    event RebalanceDown(uint256 templeAmountIn, uint256 bptIn);
    event SetPoolHelper(address poolHelper);
    event SetMaxRebalanceAmounts(uint256 bptMaxAmount, uint256 stableMaxAmount, uint256 templeMaxAmount);
    event WithdrawStable(uint256 bptAmountIn, uint256 amountOut);
    event SetRebalancePercentageBounds(uint64 belowTpf, uint64 aboveTpf);
    event SetTemplePriceFloorNumerator(uint128 numerator);
    event SetAmoStaking(address indexed amoStaking);

    constructor(
        address _balancerVault,
        address _temple,
        address _stable,
        address _bptToken,
        address _amoStaking,
        address _booster,
        uint64 _templeIndexInPool,
        bytes32 _balancerPoolId
    ) {
        balancerVault = AMO__IBalancerVault(_balancerVault);
        temple = IERC20(_temple);
        stable = IERC20(_stable);
        bptToken = IERC20(_bptToken);
        amoStaking = AMO__IAuraStaking(_amoStaking);
        booster = AMO__IAuraBooster(_booster);
        templeBalancerPoolIndex = _templeIndexInPool;
        balancerPoolId = _balancerPoolId;
    }

    function setPoolHelper(address _poolHelper) external onlyOwner {
        poolHelper = AMO__IPoolHelper(_poolHelper);

        emit SetPoolHelper(_poolHelper);
    }

    function setAmoStaking(address _amoStaking) external onlyOwner {
        amoStaking = AMO__IAuraStaking(_amoStaking);

        emit SetAmoStaking(_amoStaking);
    }

    function setPostRebalanceSlippage(uint64 slippage) external onlyOwner {
        if (slippage > BPS_PRECISION || slippage == 0) {
            revert AMOCommon.InvalidBPSValue(slippage);
        }
        postRebalanceSlippage = slippage;
        emit SetPostRebalanceSlippage(slippage);
    }

    /**
     * @notice Set maximum amount used by operator to rebalance
     * @param bptMaxAmount Maximum bpt amount per rebalance
     * @param stableMaxAmount Maximum stable amount per rebalance
     * @param templeMaxAmount Maximum temple amount per rebalance
     */
    function setMaxRebalanceAmounts(uint256 bptMaxAmount, uint256 stableMaxAmount, uint256 templeMaxAmount) external onlyOwner {
        if (bptMaxAmount == 0 || stableMaxAmount == 0 || templeMaxAmount == 0) {
            revert AMOCommon.InvalidMaxAmounts(bptMaxAmount, stableMaxAmount, templeMaxAmount);
        }
        maxRebalanceAmounts.bpt = bptMaxAmount;
        maxRebalanceAmounts.stable = stableMaxAmount;
        maxRebalanceAmounts.temple = templeMaxAmount;
        emit SetMaxRebalanceAmounts(bptMaxAmount, stableMaxAmount, templeMaxAmount);
    }

    // @notice percentage bounds (in bps) beyond which to rebalance up or down
    function setRebalancePercentageBounds(uint64 belowTPF, uint64 aboveTPF) external onlyOwner {
        if (belowTPF > BPS_PRECISION || aboveTPF > BPS_PRECISION) {
            revert AMOCommon.InvalidBPSValue(belowTPF);
        }
        rebalancePercentageBoundLow = belowTPF;
        rebalancePercentageBoundUp = aboveTPF;

        emit SetRebalancePercentageBounds(belowTPF, aboveTPF);
    }

    function setTemplePriceFloorNumerator(uint128 _numerator) external onlyOwner {
        templePriceFloorNumerator = _numerator;

        emit SetTemplePriceFloorNumerator(_numerator);
    }

    /**
     * @notice Set operator
     * @param _operator New operator
     */
    function setOperator(address _operator) external onlyOwner {
        operator = _operator;

        emit SetOperator(_operator);
    }

    /**
     * @notice Set cooldown time to throttle operator bot
     * @param _seconds Time in seconds between operator calls
     * */
    function setCoolDown(uint64 _seconds) external onlyOwner {
        cooldownSecs = _seconds;

        emit SetCooldown(_seconds);
    }
    
    /**
     * @notice Pause AMO
     * */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause AMO
     * */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Recover any token from AMO
     * @param token Token to recover
     * @param to Recipient address
     * @param amount Amount to recover
     */
    function recoverToken(address token, address to, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(to, amount);

        emit RecoveredToken(token, to, amount);
    }

    /**
     * @notice Rebalance when $TEMPLE spot price is below Treasury Price Floor.
     * Single-side withdraw $TEMPLE tokens from balancer liquidity pool to raise price.
     * BPT tokens are withdrawn from Aura rewards staking contract and used for balancer
     * pool exit. TEMPLE tokens returned from balancer pool are burned
     * @param bptAmountIn amount of BPT tokens going in balancer pool for exit
     * @param minAmountOut amount of TEMPLE tokens expected out of balancer pool
     */
    function rebalanceUp(
        uint256 bptAmountIn,
        uint256 minAmountOut
    ) external onlyOperatorOrOwner whenNotPaused enoughCooldown {
        _validateParams(minAmountOut, bptAmountIn, maxRebalanceAmounts.bpt);

        amoStaking.withdrawAndUnwrap(bptAmountIn, false, address(poolHelper));
    
        // exitTokenIndex = templeBalancerPoolIndex;
        uint256 burnAmount = poolHelper.exitPool(
            bptAmountIn, minAmountOut, rebalancePercentageBoundLow,
            rebalancePercentageBoundUp, postRebalanceSlippage,
            templeBalancerPoolIndex, templePriceFloorNumerator, temple
        );

        AMO__ITempleERC20Token(address(temple)).burn(burnAmount);

        lastRebalanceTimeSecs = uint64(block.timestamp);
        emit RebalanceUp(bptAmountIn, burnAmount);
    }

     /**
     * @notice Rebalance when $TEMPLE spot price is above Treasury Price Floor
     * Mints TEMPLE tokens and single-side deposits into balancer pool
     * Returned BPT tokens are deposited and staked into Aura for rewards using the staking contract.
     * @param templeAmountIn Amount of TEMPLE tokens to deposit into balancer pool
     * @param minBptOut Minimum amount of BPT tokens expected to receive
     * 
     */
    function rebalanceDown(
        uint256 templeAmountIn,
        uint256 minBptOut
    ) external onlyOperatorOrOwner whenNotPaused enoughCooldown {
        _validateParams(minBptOut, templeAmountIn, maxRebalanceAmounts.temple);

        AMO__ITempleERC20Token(address(temple)).mint(address(this), templeAmountIn);
        temple.safeTransfer(address(poolHelper), templeAmountIn);

        // joinTokenIndex = templeBalancerPoolIndex;
        uint256 bptIn = poolHelper.joinPool(
            templeAmountIn, minBptOut, rebalancePercentageBoundUp,
            rebalancePercentageBoundLow, templePriceFloorNumerator, 
            postRebalanceSlippage, templeBalancerPoolIndex, temple
        );

        lastRebalanceTimeSecs = uint64(block.timestamp);
        emit RebalanceDown(templeAmountIn, bptIn);

        // deposit and stake BPT
        bptToken.safeTransfer(address(amoStaking), bptIn);
        amoStaking.depositAndStake(bptIn);
    }

    /**
     * @notice Single-side deposit stable tokens into balancer pool when TEMPLE price 
     * is below Treasury Price Floor.
     * @param amountIn Amount of stable tokens to deposit into balancer pool
     * @param minBptOut Minimum amount of BPT tokens expected to receive
     */
    function depositStable(
        uint256 amountIn,
        uint256 minBptOut
    ) external onlyOwner whenNotPaused {
        _validateParams(minBptOut, amountIn, maxRebalanceAmounts.stable);

        stable.safeTransfer(address(poolHelper), amountIn);
        // stable join
        uint256 joinTokenIndex = templeBalancerPoolIndex == 0 ? 1 : 0;
        uint256 bptOut = poolHelper.joinPool(
            amountIn, minBptOut, rebalancePercentageBoundUp, rebalancePercentageBoundLow,
            templePriceFloorNumerator, postRebalanceSlippage, joinTokenIndex, stable
        );

        lastRebalanceTimeSecs = uint64(block.timestamp);

        emit StableDeposited(amountIn, bptOut);

        bptToken.safeTransfer(address(amoStaking), bptOut);
        amoStaking.depositAndStake(bptOut);
    }

     /**
     * @notice Single-side withdraw stable tokens from balancer pool when TEMPLE price 
     * is above Treasury Price Floor. Withdraw and unwrap BPT tokens from Aura staking.
     * BPT tokens are then sent into balancer pool for stable tokens in return.
     * @param bptAmountIn Amount of BPT tokens to deposit into balancer pool
     * @param minAmountOut Minimum amount of stable tokens expected to receive
     */
    function withdrawStable(
        uint256 bptAmountIn,
        uint256 minAmountOut
    ) external onlyOwner whenNotPaused {
        _validateParams(minAmountOut, bptAmountIn, maxRebalanceAmounts.bpt);

        amoStaking.withdrawAndUnwrap(bptAmountIn, false, address(poolHelper));

        uint256 stableTokenIndex = templeBalancerPoolIndex == 0 ? 1 : 0;
        uint256 amountOut = poolHelper.exitPool(
            bptAmountIn, minAmountOut, rebalancePercentageBoundLow, rebalancePercentageBoundUp,
            postRebalanceSlippage, stableTokenIndex, templePriceFloorNumerator, stable
        );

        lastRebalanceTimeSecs = uint64(block.timestamp);
        emit WithdrawStable(bptAmountIn, amountOut);
    }

    /**
     * @notice Add liquidity with both TEMPLE and stable tokens into balancer pool. 
     * Treasury Price Floor is expected to be within bounds of multisig set range.
     * BPT tokens are then deposited and staked in Aura.
     * @param request Request data for joining balancer pool. Assumes userdata of request is
     * encoded with EXACT_TOKENS_IN_FOR_BPT_OUT type
     * @param minBptOut Minimum amount of BPT tokens expected to receive
     */
    function addLiquidity(
        AMO__IBalancerVault.JoinPoolRequest memory request,
        uint256 minBptOut
    ) external onlyOwner {
        // validate request
        if (request.assets.length != request.maxAmountsIn.length || 
            request.assets.length != 2 || 
            request.fromInternalBalance == true) {
                revert AMOCommon.InvalidBalancerVaultRequest();
        }

        uint256 templeAmount = request.maxAmountsIn[templeBalancerPoolIndex];
        AMO__ITempleERC20Token(address(temple)).mint(address(this), templeAmount);
        // safe allowance stable and TEMPLE
        temple.safeIncreaseAllowance(address(balancerVault), templeAmount);

        // join pool
        uint256 bptAmountBefore = bptToken.balanceOf(address(this));
        balancerVault.joinPool(balancerPoolId, address(this), address(this), request);
        uint256 bptAmountAfter = bptToken.balanceOf(address(this));
        uint256 bptIn;
        unchecked {
            bptIn = bptAmountAfter - bptAmountBefore;
        }
        if (bptIn < minBptOut) {
            revert AMOCommon.InsufficientAmountOutPostcall(minBptOut, bptIn);
        }

        // stake BPT
        bptToken.safeTransfer(address(amoStaking), bptIn);
        amoStaking.depositAndStake(bptIn);
    }

    /**
     * @notice Remove liquidity from balancer pool receiving both TEMPLE and stable tokens from balancer pool. 
     * Treasury Price Floor is expected to be within bounds of multisig set range.
     * Withdraw and unwrap BPT tokens from Aura staking and send to balancer pool to receive both tokens.
     * @param request Request for use in balancer pool exit
     * @param bptIn Amount of BPT tokens to send into balancer pool
     */
    function removeLiquidity(
        AMO__IBalancerVault.ExitPoolRequest memory request,
        uint256 bptIn
    ) external onlyOwner {
        // validate request
        if (request.assets.length != request.minAmountsOut.length || 
            request.assets.length != 2 || 
            request.toInternalBalance == true) {
                revert AMOCommon.InvalidBalancerVaultRequest();
        }

        uint256 templeAmountBefore = temple.balanceOf(address(this));
        uint256 stableAmountBefore = stable.balanceOf(address(this));

        amoStaking.withdrawAndUnwrap(bptIn, false, address(this));

        balancerVault.exitPool(balancerPoolId, address(this), address(this), request);
        // validate amounts received
        uint256 receivedAmount;
        for (uint i=0; i<request.assets.length; ++i) {
            if (request.assets[i] == address(temple)) {
                unchecked {
                    receivedAmount = temple.balanceOf(address(this)) - templeAmountBefore;
                }
                if (receivedAmount > 0) {
                    AMO__ITempleERC20Token(address(temple)).burn(receivedAmount);
                }
            } else if (request.assets[i] == address(stable)) {
                unchecked {
                    receivedAmount = stable.balanceOf(address(this)) - stableAmountBefore;
                }
            }
        }
    }

    /**
     * @notice Allow owner to deposit and stake bpt tokens directly
     * @param amount Amount of Bpt tokens to depositt
     * @param useContractBalance If to use bpt tokens in contract
     */
    function depositAndStakeBptTokens(
        uint256 amount,
        bool useContractBalance
    ) external onlyOwner {
        if (!useContractBalance) {
            bptToken.safeTransferFrom(msg.sender, address(this), amount);
        }
        bptToken.safeTransfer(address(amoStaking), amount);
        amoStaking.depositAndStake(amount);
    }

    function _validateParams(
        uint256 minAmountOut,
        uint256 amountIn,
        uint256 maxRebalanceAmount
    ) internal pure {
        if (minAmountOut == 0) {
            revert AMOCommon.ZeroSwapLimit();
        }
        if (amountIn > maxRebalanceAmount) {
            revert AMOCommon.AboveCappedAmount(amountIn);
        }
    }

    modifier enoughCooldown() {
        if (lastRebalanceTimeSecs != 0 && lastRebalanceTimeSecs + cooldownSecs > block.timestamp) {
            revert AMOCommon.NotEnoughCooldown();
        }
        _;
    }

    modifier onlyOperatorOrOwner() {
        if (msg.sender != operator && msg.sender != owner()) {
            revert AMOCommon.NotOperatorOrOwner();
        }
        _;
    }
}