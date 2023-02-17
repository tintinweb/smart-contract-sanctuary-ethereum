/**
 *Submitted for verification at Etherscan.io on 2023-02-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

//
uint256 constant DENOMINATOR = 100;

uint256 constant MAX_REFERRAL_PERCENTAGE = 100;

// 100%
// Presale
// CHANGE THESE TO MEET YOUR REQUIREMENTS
uint128 constant USDT_PRICE = 0.01 * 10**18;

// price of 1 SOLANTER in USDT in 18 decimals (1 solanter = 0.01 USDT)
uint128 constant MAX_BUY_IN_SOLANTER = 1000000 * 10**18;

// max buy per user in SOLANTER
uint128 constant MIN_BUY_IN_SOLANTER = 100 * 10**18;

// minimum buy in solanter token
uint64 constant START_TIME_UNIX_EPOCH = 0;

// set the starting time (you can change it later as long as the ICO did not start)
uint64 constant END_TIME_UNIX_EPOCH = 0;

// set the starting time (you can change it later as long as the ICO did not end)
uint64 constant LISTING_TIME_UNIX_EPOCH = 0;

// set the starting time (you can change it later as long as the ICO did not end)
uint64 constant VESTING_PERIOD = 30 days;

// 30 days this means that the user will get 1/30 of the tokens every day
uint64 constant VESTING_INTERVAL = 1 days;

// 1 day this means that the user will get 1/30 of the tokens every day
uint64 constant VESTING_RATIO = 100;

// 100% of tokens will be vested
// these are here for reference only , the contract takes these addresses as deployment args
// THESE HAVE NO EFFECT ON THE CONTRACT
address constant PANCAKE_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

address constant PANCAKE_FACTORY = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;

address constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

address constant USDT = 0x55d398326f99059fF775485246999027B3197955;

//
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
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

//
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

//
contract ReferralManagement is Ownable {
    uint256 public referralCommissionRate = 1; // 1%

    mapping(address => address) private referrers;

    function setReferralCommissionRate(uint256 _referralCommissionRate)
        external
        onlyOwner
    {
        require(
            _referralCommissionRate <= MAX_REFERRAL_PERCENTAGE,
            "ReferralManagement: > 100%"
        );
        referralCommissionRate = _referralCommissionRate;
    }

    function _getReferrer(address _user) internal view returns (address) {
        address referrer = referrers[_user];
        return referrer;
    }

    function setReferrer(address _referrer) external {
        _setReffererFor(msg.sender, _referrer);
    }

    function _safelySetReferrer(address _user, address _referrer) internal {
        // does not revert if referrer is already set or if referrer is the user or if referrer is 0x0
        if (
            referrers[_user] == address(0) &&
            _referrer != _user &&
            _referrer != address(0)
        ) {
            _setReffererFor(_user, _referrer);
        }
    }

    function _setReffererFor(address _user, address _referrer) internal {
        require(
            _referrer != address(0),
            "ReferralManagement: invalid referrer address"
        );
        require(
            _referrer != _user,
            "ReferralManagement: referrer cannot be the user"
        );
        require(
            referrers[_user] == address(0),
            "ReferralManagement: referrer already set"
        );
        referrers[_user] = _referrer;
    }

    function setReferrerFor(address _user, address _referrer)
        external
        onlyOwner
    {
        _setReffererFor(_user, _referrer);
    }

    function referrerOf(address account) external view returns (address) {
        return referrers[account];
    }
}

//
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
}

//
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)
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

//
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
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
        return
            functionCallWithValue(
                target,
                data,
                0,
                "Address: low-level call failed"
            );
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
                "Address: low-level call with value failed"
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
            "Address: insufficient balance for call"
        );
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
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
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
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
                "Address: low-level delegate call failed"
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage)
        private
        pure
    {
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

//
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)
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
            "SafeERC20: approve from non-zero to non-zero allowance"
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
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
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
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
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
        require(
            nonceAfter == nonceBefore + 1,
            "SafeERC20: permit did not succeed"
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

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

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

//
//import "hardhat/console.sol";
struct UserData {
    uint256 boughtAmount;
    uint256 nonVestedAmount;
    uint256 unlockedAmount;
    uint256 claimableAmount;
    uint256 claimedAmount;
    uint256 usdtInvested;
    uint256 bnbInvested;
    uint256 bnbReferralRewards;
    uint256 usdtReferralRewards;
}

struct PresaleData {
    uint256 totalPresale;
    uint256 totalSold;
    uint256 usdtPrice;
    uint256 maxBuy;
    uint256 minBuy;
    uint256 startTime;
    uint256 endTime;
    uint256 listingTime;
    uint256 totalUsdtInvested;
    uint256 totalBnbInvested;
    uint256 totalUsdtReferralRewards;
    uint256 totalBnbReferralRewards;
    uint256 totalUSDValueRaised;
    uint256 vestingPeriod;
    uint256 vestingInterval;
    uint256 vestingRatio;
    bool isVestingEnabled;
    uint256 referralCommissionRate;
}

contract SolanterPreLaunch is Ownable, ReferralManagement {
    using SafeERC20 for IERC20;

    IERC20 public immutable solanterToken;
    IERC20 public immutable usdt;
    IERC20 public immutable wbnb;
    IUniswapV2Router02 public immutable uniswapRouter;
    IUniswapV2Pair public immutable usdtWbnbPair;

    uint256 refUSDT = 0;
    uint256 refBNB = 0;

    uint128 public usdtPrice = USDT_PRICE;
    uint128 public maxBuy = MAX_BUY_IN_SOLANTER;
    uint128 public minBuy = MIN_BUY_IN_SOLANTER;
    uint64 public startTime = START_TIME_UNIX_EPOCH;
    uint64 public endTime = END_TIME_UNIX_EPOCH;

    bool public isVestingEnabled = true;

    uint64 public listingTime = LISTING_TIME_UNIX_EPOCH;

    // create function to change listingTime
    function setListingTime(uint64 _listingTime) external onlyOwner {
        require(
            _listingTime > block.timestamp && _listingTime > endTime,
            "SolanterPreLaunch: listing time must be in the future"
        );
        listingTime = _listingTime;
    }

    uint64 public vestingPeriod = VESTING_PERIOD;

    // function to change vestingPeriod
    function setVestingPeriod(uint64 _vestingPeriodInDays) external onlyOwner {
        require(
            block.timestamp < listingTime,
            "SolanterPreLaunch: vesting interval can only be changed before listing time"
        );
        vestingPeriod = _vestingPeriodInDays * 1 days;
    }

    uint64 public vestingInterval = VESTING_INTERVAL;

    // function to change vestingInterval
    function setVestingInterval(uint64 _vestingInterval) external onlyOwner {
        require(
            _vestingInterval > 0,
            "SolanterPreLaunch: vesting interval must be greater than 0"
        );
        // only before listingTime
        require(
            block.timestamp < listingTime,
            "SolanterPreLaunch: vesting interval can only be changed before listing time"
        );
        vestingInterval = _vestingInterval;
    }

    uint64 public vestingRatio = VESTING_RATIO; // 100% of tokens will be vested

    // function to change vestingRatio
    function setVestingRatio(uint64 _vestingRatio) external onlyOwner {
        // only before listingTime
        require(
            block.timestamp < listingTime,
            "SolanterPreLaunch: vesting ratio can only be changed before listing time"
        );
        require(
            _vestingRatio <= 100,
            "SolanterPreLaunch: vesting ratio must be < 100"
        );
        vestingRatio = _vestingRatio;
    }

    uint256 public totalPresale;
    uint256 public totalSold;
    uint256 public totalSoldClaimed;
    uint256 public totalUsdtInvested;
    uint256 public totalBnbInvested;

    uint256 public totalUsdtReferralRewards;
    uint256 public totalBnbReferralRewards;
    uint256 public totalUSDValueRaised;

    mapping(address => uint256) public boughtAmount;
    mapping(address => uint256) public claimedAmount;
    mapping(address => uint256) public usdtInvested;
    mapping(address => uint256) public bnbInvested;
    mapping(address => uint256) public bnbReferralRewards;
    mapping(address => uint256) public usdtReferralRewards;

    event Buy(
        address indexed user,
        uint8 indexed token,
        uint256 amount,
        uint256 investment
    ); //token: 0 for BNB, 1 for BUSD
    event SetPrice(uint256 price); //token: 0 for BNB, 1 for BUSD
    event SetMaxBuy(uint256 amount);
    event SetMinBuy(uint256 amount);
    event StartTimeChanged(uint256 oldTime, uint256 newTime);
    event EndTimeChanged(uint256 oldTime, uint256 newTime);

    constructor(
        IERC20 solanterToken_,
        IERC20 usdt_,
        IUniswapV2Router02 uniswapRouter_,
        IUniswapV2Pair usdtWbnbPair_,
        IERC20 wbnb_
    ) {
        solanterToken = solanterToken_;
        usdt = usdt_;
        uniswapRouter = uniswapRouter_;
        usdtWbnbPair = usdtWbnbPair_;
        wbnb = wbnb_;
    }

    receive() external payable {
        _buyWithBNB(address(0));
    }

    modifier onlyWhenSaleIsOn() {
        require(
            block.timestamp >= startTime && block.timestamp <= endTime,
            "SolanterPreLaunch: Sale is not on"
        );
        _;
    }

    function getUserData(address _user)
        external
        view
        returns (UserData memory)
    {
        ClaimData memory claimData = getClaimabledBoughtTokens(_user);
        return
            UserData({
                boughtAmount: boughtAmount[_user],
                nonVestedAmount: claimData.nonVested,
                unlockedAmount: claimData.unlocked,
                claimableAmount: claimData.claimable,
                claimedAmount: claimedAmount[_user],
                usdtInvested: usdtInvested[_user],
                bnbInvested: bnbInvested[_user],
                bnbReferralRewards: bnbReferralRewards[_user],
                usdtReferralRewards: usdtReferralRewards[_user]
            });
    }

    function getPresaleData() external view returns (PresaleData memory) {
        return
            PresaleData({
                totalPresale: totalPresale,
                totalSold: totalSold,
                totalUsdtInvested: totalUsdtInvested,
                totalBnbInvested: totalBnbInvested,
                totalUsdtReferralRewards: totalUsdtReferralRewards,
                totalBnbReferralRewards: totalBnbReferralRewards,
                totalUSDValueRaised: totalUSDValueRaised,
                usdtPrice: usdtPrice,
                maxBuy: maxBuy,
                minBuy: minBuy,
                startTime: startTime,
                endTime: endTime,
                listingTime: listingTime,
                vestingPeriod: vestingPeriod,
                vestingInterval: vestingInterval,
                vestingRatio: vestingRatio,
                isVestingEnabled: isVestingEnabled,
                referralCommissionRate: referralCommissionRate
            });
    }

    function buy(uint256 amount, address _referrer) external onlyWhenSaleIsOn {
        // set referrer
        address currRef = _getReferrer(msg.sender);
        if (currRef == address(0)) {
            _safelySetReferrer(msg.sender, _referrer);
            currRef = _referrer;
        }
        uint256 refAmount = currRef != address(0)
            ? (amount * referralCommissionRate) / 100
            : 0;

        // transfer this usdt here
        usdt.safeTransferFrom(msg.sender, address(this), amount);
        // calculate the amount of solanter token to send
        uint256 solanterAmount = ((amount) * 10**18) / usdtPrice;
        // update the bought amount
        _buy(_msgSender(), 1, solanterAmount, amount);

        usdtInvested[msg.sender] += amount;

        usdtReferralRewards[currRef] += refAmount;
        totalUsdtReferralRewards += refAmount;
        refUSDT += refAmount;
        totalUsdtInvested += amount;
        totalUSDValueRaised += amount;
    }

    function buyWithBNB(address _referrer) external payable onlyWhenSaleIsOn {
        _buyWithBNB(_referrer);
    }

    function _buyWithBNB(address _referrer) internal {
        // set referrer
        address currRef = _getReferrer(msg.sender);
        if (currRef == address(0)) {
            _safelySetReferrer(msg.sender, _referrer);
            currRef = _referrer;
        }
        uint256 refAmount = currRef != address(0)
            ? (msg.value * referralCommissionRate) / 100
            : 0;

        uint256 usdtValue = _getBNBValueInUSDT(msg.value);
        // calculate the amount of solanter token to send
        uint256 solanterAmount = (usdtValue * 10**18) / usdtPrice;
        // update the bought amount
        _buy(_msgSender(), 0, solanterAmount, usdtValue);

        bnbInvested[msg.sender] += msg.value;
        bnbReferralRewards[currRef] += refAmount;
        totalBnbInvested += msg.value;
        totalUSDValueRaised += usdtValue;
        refBNB += refAmount;
        totalBnbReferralRewards += refAmount;
    }

    /**
     * @dev returns the price of wbnb in usdt (18 decimals)
     */
    function _getBNBValueInUSDT(uint256 amount) public view returns (uint256) {
        address _wbnb = address(wbnb);
        address usdtAddress = address(usdt);

        (uint256 reserve0, uint256 reserve1, ) = usdtWbnbPair.getReserves();

        // this will be way mroe gas efficient that calling pair.token0() and pair.token1()
        // check the PancakeFactory.createPair() for more details on this logic
        if (_wbnb < usdtAddress) {
            // wbnb is token0
            return uniswapRouter.getAmountOut(amount, reserve0, reserve1);
        } else {
            // wbnb is token1
            return uniswapRouter.getAmountOut(amount, reserve1, reserve0);
        }
    }

    function _buy(
        address user,
        uint8 token,
        uint256 amount,
        uint256 investment
    ) internal {
        require(
            amount >= minBuy,
            "SolanterPreLaunch: Amount is less than min buy"
        );
        boughtAmount[user] += amount;
        require(
            maxBuy == 0 || boughtAmount[user] <= maxBuy,
            "SolanterPreLaunch: Exceed max buy"
        );
        totalSold += amount;
        require(
            totalSold <= totalPresale,
            "SolanterPreLaunch: Exceed total presale"
        );
        emit Buy(user, token, amount, investment);
    }

    function withdrawBNB() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance - refBNB);
    }

    function withdrawUSDT() external onlyOwner {
        usdt.safeTransfer(msg.sender, usdt.balanceOf(address(this)) - refUSDT);
    }

    function setUsdtPrice(uint128 _price) external onlyOwner {
        require(_price > 0, "SolanterPreLaunch: Price must be greater than 0");
        usdtPrice = _price;
        emit SetPrice(_price);
    }

    function setMaxBuy(uint128 _maxBuy) external onlyOwner {
        maxBuy = _maxBuy;
        emit SetMaxBuy(_maxBuy);
    }

    function setEndTime(uint64 _endTime) external onlyOwner {
        require(
            _endTime > block.timestamp && _endTime > startTime,
            "SolanterPreLaunch: End time must be in the future"
        );
        emit EndTimeChanged(endTime, _endTime);
        endTime = _endTime;
        listingTime = endTime + 10 days;
    }

    function setStartTime(uint64 _startTime) external onlyOwner {
        require(
            (startTime == 0 || startTime > block.timestamp) &&
                _startTime > block.timestamp,
            "SolanterPreLaunch: Start time can't be changes after sale started"
        );
        emit StartTimeChanged(startTime, _startTime);
        uint64 diff = endTime - startTime;
        startTime = _startTime;

        endTime = _startTime + (diff > 0 ? diff : 10 days);

        listingTime = endTime + 10 days;
    }

    function setMinBuy(uint128 _minBuy) external onlyOwner {
        minBuy = _minBuy;
        emit SetMinBuy(_minBuy);
    }

    function withdrawPresaleToken(uint256 amount) external onlyOwner {
        require(
            amount <= totalPresale - (totalSold),
            "SolanterPreLaunch: Total presale must be greater than total sold"
        );
        totalPresale -= amount;
        solanterToken.safeTransfer(msg.sender, amount);
    }

    function depositPresaleToken(uint256 amount) external onlyOwner {
        solanterToken.safeTransferFrom(msg.sender, address(this), amount);
        totalPresale += amount;
    }

    function claimAllReferralRewards() external {
        uint256 bnbReward = bnbReferralRewards[msg.sender];
        uint256 usdtReward = usdtReferralRewards[msg.sender];

        if (bnbReward > 0) {
            bnbReferralRewards[msg.sender] = 0;
            payable(msg.sender).transfer(bnbReward);
            refBNB -= bnbReward;
        }

        if (usdtReward > 0) {
            usdtReferralRewards[msg.sender] = 0;
            usdt.safeTransfer(msg.sender, usdtReward);
            refUSDT -= usdtReward;
        }
    }

    function claimUnlockedBoughtTokens() external {
        require(
            block.timestamp > listingTime,
            "SolanterPreLaunch: Sale is still on"
        );

        uint256 totalAmount = boughtAmount[msg.sender];
        uint256 alreadyClaimed = claimedAmount[msg.sender];

        bool enabled = isVestingEnabled &&
            vestingRatio > 0 &&
            vestingPeriod > 0;

        uint256 nonVested = enabled
            ? (totalAmount * (100 - vestingRatio)) / 100
            : totalAmount;

        uint256 passedTime = (block.timestamp - listingTime);
        passedTime = passedTime > vestingPeriod ? vestingPeriod : passedTime;
        uint256 intervalsUnlocked = passedTime / vestingInterval;
        uint256 totalIntervals = vestingPeriod / vestingInterval;

        uint256 unlocked = enabled
            ? ((totalAmount - nonVested) * intervalsUnlocked) / totalIntervals
            : 0;

        uint256 claimable = nonVested + unlocked - alreadyClaimed;

        require(claimable > 0, "SolanterPreLaunch: Nothing to claim");

        claimedAmount[msg.sender] += claimable;

        solanterToken.safeTransfer(msg.sender, claimable);
        totalSoldClaimed += claimable;
    }

    struct ClaimData {
        uint256 nonVested;
        uint256 unlocked;
        uint256 claimable;
    }

    function getClaimabledBoughtTokens(address user)
        public
        view
        returns (ClaimData memory)
    {
        uint256 totalAmount = boughtAmount[user];
        uint256 alreadyClaimed = claimedAmount[user];

        bool enabled = isVestingEnabled &&
            vestingRatio > 0 &&
            vestingPeriod > 0;

        uint256 nonVested = enabled
            ? (totalAmount * (100 - vestingRatio)) / 100
            : totalAmount;

        uint256 passedTime = block.timestamp > listingTime
            ? block.timestamp - listingTime
            : 0;

        passedTime = passedTime > vestingPeriod ? vestingPeriod : passedTime;

        uint256 intervalsUnlocked = passedTime / vestingInterval;
        uint256 totalIntervals = vestingPeriod / vestingInterval;

        uint256 unlocked = enabled
            ? ((totalAmount - nonVested) * intervalsUnlocked) / totalIntervals
            : 0;

        uint256 claimable = nonVested + unlocked - alreadyClaimed;

        if (block.timestamp <= listingTime) {
            return ClaimData(nonVested, 0, nonVested);
        }

        return ClaimData(nonVested, unlocked, claimable);
    }
}