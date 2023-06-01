/**
 *Submitted for verification at Etherscan.io on 2023-05-31
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}
 // import metadata

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface ITradingEngine {
    struct ExternalCollateralArgs {
        address collateralModule;
        bytes32 collateralPositionKey;
        uint256 collateralAmount;
    }

    function increasePosition(
        address _account,
        address _indexToken,
        address _collateralToken,
        uint256 _sizeDelta,
        bool _isLong
    ) external;

    function decreasePosition(
        address _account,
        address _indexToken,
        address _collateralToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong
    ) external;

    function increasePositionExternalCollateral(
        address _account,
        address _indexToken,
        address _collateralToken,
        uint256 _sizeDelta,
        bool _isLong,
        ExternalCollateralArgs calldata _args
    ) external;

    function liquidatePositionExternalCollateral(
        address _account,
        address _indexToken,
        address _collateralToken,
        bool _isLong,
        address _collateralModule,
        bytes32 _collateralPositionKey
    ) external;

    function whitelistedTokenCount() external view returns (uint256);

    function totalTokenWeights() external view returns (uint256);

    function tokenWeights(address _token) external view returns (uint256);

    function getTargetVlpAmount(address _token) external view returns (uint256);

    function getNormalizedIncome(address _token) external view returns (int256);

    function updateVaultBalance(address _token, uint256 _delta, bool _isIncrease) external;

    function getVault(address _token) external returns (address);

    function addVault(address _token, address _vault) external;
}

interface IvLPToken is IERC20 {
    function mint(address to, uint amount) external;

    function burnFrom(address account, uint256 amount) external;
}

interface IFastPriceFeed {
    function getPrice(address token, bool isMax) external view returns (uint256);

    function tokenDecimals(address token) external view returns (uint8);

    function getChainlinkPrice(address token) external view returns (uint256);
}

library Errors {
    error ZeroAmount();
    error ZeroAddress();

    error TokenNotWhitelisted();

    error InvalidPositionSize();
    error MarginRatioNotMet();

    error PositionNotExists(
        address owner,
        address indexToken,
        address collateralToken,
        bool isLong
    );
}

library Constants {
    address public constant ZERO_ADDRESS = address(0);
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    uint256 public constant DEFAULT_FUNDING_RATE_FACTOR = 100;
    uint256 public constant DEFAULT_MAX_OPEN_INTEREST = 10000000000 * PRICE_PRECISION;
    uint256 public constant DEFAULT_VLP_PRICE = 100000;
    uint256 public constant FUNDING_RATE_PRECISION = 1e6;
    uint256 public constant LIQUIDATE_NONE_EXCEED = 0;
    uint256 public constant LIQUIDATE_FEE_EXCEED = 1;
    uint256 public constant LIQUIDATE_THRESHOLD_EXCEED = 2;
    uint256 public constant LIQUIDATION_FEE_DIVISOR = 1e18;
    uint256 public constant MAX_DEPOSIT_FEE = 10000; // 10%
    uint256 public constant MAX_FUNDING_RATE_FACTOR = 10000; // 1%
    uint256 public constant MAX_LIQUIDATION_FEE_USD = 100 * PRICE_PRECISION; // 100 USD
    uint256 public constant MAX_TRIGGER_GAS_FEE = 1e8 gwei;

    uint256 public constant MAX_FUNDING_RATE_INTERVAL = 48 hours;
    uint256 public constant MIN_FUNDING_RATE_INTERVAL = 1 hours;

    uint256 public constant MIN_LEVERAGE = 10000; // 1x
    uint256 public constant MIN_FEE_REWARD_BASIS_POINTS = 50000; // 50%
    uint256 public constant PRICE_PRECISION = 1e12;
    uint256 public constant LP_DECIMALS = 18;
    uint256 public constant LP_INITIAL_PRICE = 1e12; // init set to 1$
    uint256 public constant USD_VALUE_PRECISION = 1e30;

    uint256 public constant FEE_PRECISION = 10000;

    uint8 public constant ORACLE_PRICE_DECIMALS = 12;
}

struct Fee {
    /// @notice charge when changing position size
    uint256 positionFee;
    /// @notice charge when liquidate position (in dollar)
    uint256 liquidationFeeUsd;
    /// @notice swap fee used when add/remove liquidity, swap token
    uint256 baseSwapFee;
    /// @notice tax used to adjust swapFee due to the effect of the action on token's weight
    /// It reduce swap fee when user add some amount of a under weight token to the pool
    uint256 taxBasisPoint;
    /// @notice swap fee used when add/remove liquidity, swap token
    uint256 stableCoinBaseSwapFee;
    /// @notice tax used to adjust swapFee due to the effect of the action on token's weight
    /// It reduce swap fee when user add some amount of a under weight token to the pool
    uint256 stableCoinTaxBasisPoint;
    /// @notice part of fee will be kept for DAO, the rest will be distributed to pool amount, thus
    /// increase the pool value and the price of LP token
    uint256 daoFee;
}

library FeeLib {
    function getPositionFeeValue(
        uint256 _positionFee,
        uint256 _sizeDelta
    ) internal pure returns (uint256) {
        return (_sizeDelta * _positionFee) / Constants.FEE_PRECISION;
    }

    function getFundingFeeValue(
        uint256 _entryFundingRate,
        uint256 _nextFundingRate,
        uint256 _positionSize
    ) internal pure returns (uint256) {
        return
            (_positionSize * (_nextFundingRate - _entryFundingRate)) /
            Constants.FUNDING_RATE_PRECISION;
    }

    // cases to consider
    // 1. initialAmount is far from targetAmount, action increases balance slightly => high rebate
    // 2. initialAmount is far from targetAmount, action increases balance largely => high rebate
    // 3. initialAmount is close to targetAmount, action increases balance slightly => low rebate
    // 4. initialAmount is far from targetAmount, action reduces balance slightly => high tax
    // 5. initialAmount is far from targetAmount, action reduces balance largely => high tax
    // 6. initialAmount is close to targetAmount, action reduces balance largely => low tax
    // 7. initialAmount is above targetAmount, nextAmount is below targetAmount and vice versa
    // 8. a large swap should have similar fees as the same trade split into multiple smaller swaps
    function getFeeBasisPoints(
        uint256 _targetVlpAmount,
        uint256 _vLpDelta,
        uint256 _vLpAmount,
        uint256 _feeBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) internal pure returns (uint256) {
        uint256 initialAmount = _vLpAmount;
        uint256 nextAmount = initialAmount + _vLpDelta;

        if (!_increment) {
            nextAmount = _vLpDelta > initialAmount ? 0 : initialAmount - _vLpDelta;
        }

        uint256 targetAmount = _targetVlpAmount;
        if (targetAmount == 0) {
            return _feeBasisPoints;
        }

        uint256 initialDiff = initialAmount > targetAmount
            ? initialAmount - targetAmount
            : targetAmount - initialAmount;

        uint256 nextDiff = nextAmount > targetAmount
            ? nextAmount - targetAmount
            : targetAmount - nextAmount;

        // action improves relative asset balance
        if (nextDiff < initialDiff) {
            uint256 rebateBps = (_taxBasisPoints * initialDiff) / targetAmount;
            return rebateBps > _feeBasisPoints ? 0 : _feeBasisPoints - rebateBps;
        }

        uint256 averageDiff = (initialDiff + nextDiff) / 2;
        if (averageDiff > targetAmount) {
            averageDiff = targetAmount;
        }

        uint256 taxBps = (_taxBasisPoints * averageDiff) / targetAmount;
        return _feeBasisPoints + taxBps;
    }
}

library InternalMath {
    function abs(int256 x) internal pure returns (int256) {
        return x >= 0 ? x : -x;
    }

    function subMinZero(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a - b : 0;
    }
}

struct Position {
    /// @dev side of the position, long or short
    bool isLong;
    /// @dev contract size is evaluated in dollar
    uint256 size;
    /// @dev collateral value in dollar
    uint256 collateralValue;
    /// @dev contract size in indexToken
    uint256 collateralAmount;
    uint256 reserveAmount;
    /// @dev average entry price
    uint256 entryPrice;
    /// @dev last cumulative interest rate
    uint256 entryFundingRate;
    address collateralModule;
    bytes32 collateralPositionKey;
}

struct DecreasePositionResult {
    int256 realizedPnl;
    uint256 feeValue;
    uint256 reserveDelta;
    uint256 payoutValue;
    uint256 collateralValueReduced;
}

library PositionLib {
    function increase(
        Position storage position,
        Fee memory feeStruct,
        bool _isLong,
        uint256 _sizeDelta,
        uint256 _collateralValue,
        uint256 _reserveDelta,
        uint256 _price,
        uint256 _fundingRate
    ) internal returns (uint256 feeValue) {
        uint256 size = position.size;
        // set entry price
        if (size == 0) {
            position.entryPrice = _price;
        } else {
            position.entryPrice = getNextAveragePrice(
                size,
                position.entryPrice,
                _isLong,
                _price,
                _sizeDelta
            );
        }

        feeValue = calcMarginFees(position, feeStruct.positionFee, _sizeDelta, _fundingRate);
        uint256 nextCollateralValue = position.collateralValue + _collateralValue;
        require(nextCollateralValue >= feeValue, "PositionLib::increase: insufficient collateral");
        position.collateralValue = nextCollateralValue - feeValue;
        position.size += _sizeDelta;
        position.reserveAmount += _reserveDelta;
        position.entryFundingRate = _fundingRate;
        position.isLong = _isLong;
    }

    function decrease(
        Position storage position,
        Fee memory feeStruct,
        bool _isLong,
        uint256 _sizeDelta,
        uint256 _collateralDelta,
        uint256 _indexPrice,
        uint256 _fundingRate,
        bool _isLiquidate
    ) internal returns (DecreasePositionResult memory result) {
        require(position.size >= _sizeDelta, "Position::decrease: insufficient position size");
        require(
            position.collateralValue >= _collateralDelta,
            "Position::decrease: insufficient collateral"
        );

        // decrease pool reserve amount
        result.feeValue = calcMarginFees(position, feeStruct.positionFee, _sizeDelta, _fundingRate);

        int256 pnl = calcPnl(_isLong, position.size, position.entryPrice, _indexPrice);
        // calculate realizedPnl which is proportional to pnl based on _sizeDelta size
        result.realizedPnl = (pnl * int256(_sizeDelta)) / int256(position.size);

        int256 payoutValueInt = result.realizedPnl +
            int256(_collateralDelta) -
            int256(result.feeValue);

        if (_isLiquidate) {
            payoutValueInt = payoutValueInt - int256(feeStruct.liquidationFeeUsd);
        }

        uint256 nextCollateralValue = position.collateralValue - _collateralDelta;

        if (payoutValueInt < 0) {
            // if payoutValue is negative, deduct uncovered lost from collateral
            // set a cap zero for the substraction to avoid underflow
            nextCollateralValue = InternalMath.subMinZero(
                nextCollateralValue,
                uint256(InternalMath.abs(payoutValueInt))
            );
        }

        result.reserveDelta = (position.reserveAmount * _sizeDelta) / position.size;
        result.payoutValue = payoutValueInt > 0 ? uint256(payoutValueInt) : 0;
        result.collateralValueReduced = position.collateralValue - nextCollateralValue;

        position.entryFundingRate = _fundingRate;
        position.size -= _sizeDelta;
        position.collateralValue = nextCollateralValue;
        position.reserveAmount = position.reserveAmount - result.reserveDelta;
    }

    function calcMarginFees(
        Position memory position,
        uint256 _positionFee,
        uint256 _sizeDelta,
        uint256 _nextFundingRate
    ) internal pure returns (uint256) {
        uint256 positionFeeUsd = FeeLib.getPositionFeeValue(_positionFee, _sizeDelta);
        uint256 fundingFeeUsd = FeeLib.getFundingFeeValue(
            position.entryFundingRate,
            _nextFundingRate,
            position.size
        );

        uint256 feeUsd = positionFeeUsd + fundingFeeUsd;
        return feeUsd;
    }

    function calcPnl(
        bool _isLong,
        uint256 _positionSize,
        uint256 _entryPrice,
        uint256 _nextPrice
    ) internal view returns (int256) {
        if (_positionSize == 0) {
            return 0;
        }

        if (_isLong) {
            int256 priceDelta = int256(_nextPrice) - int256(_entryPrice);

            return (priceDelta * int256(_positionSize)) / int256(_entryPrice);
        }

        int256 priceDeltaShort = int256(_entryPrice) - int256(_nextPrice);
        return (priceDeltaShort * int256(_positionSize)) / int256(_entryPrice);

        // TODO: handle front running bot
        // if the minProfitTime has passed then there will be no min profit threshold
        // the min profit threshold helps to prevent front-running issues
        // uint256 minBps = block.timestamp > _lastIncreasedTime.add(minProfitTime) ? 0 : minProfitBasisPoints[_indexToken];
        // if (hasProfit && delta.mul(BASIS_POINTS_DIVISOR) <= _size.mul(minBps)) {
        //     delta = 0;
        // }
    }

    function getNextAveragePrice(
        uint256 _size,
        uint256 _entryPrice,
        bool _isLong,
        uint256 _nextPrice,
        // uint256 _lastIncreasedTime
        uint256 _sizeDelta
    ) internal view returns (uint256) {
        if (_sizeDelta == 0) {
            return _entryPrice;
        }

        int256 pnl = calcPnl(_isLong, _size, _entryPrice, _nextPrice);

        uint256 nextSize = _size + _sizeDelta;
        int256 divisor = int256(nextSize) + pnl; // always > 0
        return (_nextPrice * nextSize) / uint256(divisor);
    }
}

struct Market {
    /// @notice amount of token deposited (via adding liquidity or increasing long position)
    uint256 poolAmount;
    // is the amount of tokens borrowed plus long position collateral
    /// @notice amount of token reserved for paying out when user takes profit
    uint256 reserveAmount;
    /// @notice amount reserved for fee
    uint256 feeReserve;
    /// @notice total borrowed (in USD) to leverage
    ///is the value of the amount of tokens borrowed in USD
    uint256 guaranteedValue;
    /// @notice total size of all short positions
    uint256 totalShortSize;
    /// @notice average entry price of all short position
    uint256 averageShortPrice;
    /// @notice recorded balance of token in pool
    uint256 poolBalance;
    /// @notice timestamp of the last time the funding rate was udpated
    uint256 lastFundingTimestamp;
    /// @notice accumulated funding rate
    uint256 fundingIndex;
    // v0.2 income of engine: comes from loss of long positions
    uint256 incomeAmount;
    uint256 lossAmount;
    uint256 liquidityIndex;
}

library MarketLib {
    function increasePoolAmount(Market storage market, uint256 amount) internal {
        market.poolAmount += amount;
    }

    function updateIncomeAndLoss(Market storage market, uint256 amount, bool hasProfit) internal {
        uint256 nextIncomeAmount = market.incomeAmount;
        uint256 nextLossAmount = market.lossAmount;

        if (hasProfit) {
            nextIncomeAmount += amount;
            market.incomeAmount = nextIncomeAmount;
        } else {
            nextLossAmount += amount;
            market.lossAmount = nextLossAmount;
        }

        if (nextLossAmount != 0) {
            market.liquidityIndex = nextIncomeAmount / nextLossAmount;
        }
    }

    function decreasePoolAmount(Market storage market, uint256 amount) internal {
        market.poolAmount -= amount;
        require(
            market.poolAmount >= market.reserveAmount,
            "MarketLib: reduce pool amount too much"
        );
    }

    function increaseReserve(Market storage market, uint256 reserveAdded) internal {
        market.reserveAmount += reserveAdded;
        require(market.reserveAmount <= market.poolAmount, "MarketLib::reserve exceed pool amount");
    }

    function decreaseReserve(Market storage market, uint256 reserveDeducted) internal {
        require(market.reserveAmount >= reserveDeducted, "MarketLib::reserve reduce too much");
        market.reserveAmount -= reserveDeducted;
    }

    /// @notice recalculate global LONG position for collateral asset
    function increaseLongPosition(
        Market storage market,
        uint256 sizeDelta,
        uint256 collateralAmount,
        uint256 collateralValue,
        uint256 feeAmount,
        uint256 feeValue
    ) internal {
        // remember pool amounts is amount of collateral token
        // the fee is deducted from collateral in, so we reduce it from poolAmount and guaranteed value
        market.poolAmount = market.poolAmount + collateralAmount - feeAmount;
        // guaranteed value = sizeDelta - (collateral - fee))
        // delta_guaranteed value = sizechange + fee - collateral
        market.guaranteedValue = market.guaranteedValue + sizeDelta + feeValue - collateralValue;
    }

    /// @notice recalculate global short position for index asset
    function increaseShortPosition(
        Market storage market,
        uint256 sizeDelta,
        uint256 indexPrice
    ) internal {
        // recalculate total short position
        uint256 lastSize = market.totalShortSize;
        uint256 entryPrice = market.averageShortPrice;
        market.averageShortPrice = PositionLib.getNextAveragePrice(
            lastSize,
            entryPrice,
            false,
            indexPrice,
            sizeDelta
        );
        market.totalShortSize = lastSize + sizeDelta;
    }

    function decreaseLongPosition(
        Market storage market,
        uint256 collateralValueReduced,
        uint256 sizeDelta,
        uint256 payoutAmount,
        uint256 fee
    ) internal {
        // update guaranteed
        // guaranteed = size - collateral
        // NOTE: collateralChanged is fee excluded
        market.guaranteedValue = InternalMath.subMinZero(
            market.guaranteedValue + collateralValueReduced,
            sizeDelta
        );
        market.poolAmount -= payoutAmount + fee;
    }

    function decreaseShortPosition(Market storage market, uint256 sizeDelta) internal {
        // update short position
        market.totalShortSize -= sizeDelta;
    }

    function getAUM(Market storage market, uint256 indexPrice) internal view returns (int256) {
        int256 shortPnl;

        if (market.totalShortSize > 0) {
            shortPnl = PositionLib.calcPnl(
                false,
                market.totalShortSize,
                market.averageShortPrice,
                indexPrice
            );
        }

        int256 poolVal = int256(market.poolAmount - market.reserveAmount) * int256(indexPrice);
        return poolVal + int256(market.guaranteedValue) + shortPnl;
    }
}

library SafeTransfer {
    using SafeERC20 for IERC20;
    /// @notice pseudo address to use inplace of native token
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function getBalance(IERC20 token, address holder) internal view returns (uint256) {
        if (isETH(token)) {
            return holder.balance;
        }
        return token.balanceOf(holder);
    }

    function transferTo(IERC20 token, address receiver, uint256 amount) internal {
        if (amount == 0) {
            return;
        }
        if (isETH(token)) {
            safeTransferETH(receiver, amount);
        } else {
            token.safeTransfer(receiver, amount);
        }
    }

    function isETH(IERC20 token) internal pure returns (bool) {
        return address(token) == ETH;
    }

    function safeTransferETH(address to, uint256 amount) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = to.call{value: amount}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

contract FundingManager {
    uint256 constant MAX_INTEREST_RATE = 1e3; // 0.1%
    uint256 constant UTILIZATION_PRECISION = 1e5;

    mapping(uint256 => int256) public fundingIndex;
    uint256 public interestRate = 100; // precision: 1e6
    uint256 public fundingInterval = 8 hours;

    event MaxFundingRateSet(uint256 maxFundingRate);
    event InterestRateSet(uint256 rate, uint256 interval);

    function setInterestRate(uint256 _interestRate, uint256 _fundingInterval) external {
        require(_fundingInterval >= 1, "FundingManager::invalid funding interval");
        require(_interestRate <= MAX_INTEREST_RATE, "FundingManager::invalid interest rate");

        interestRate = _interestRate;
        fundingInterval = _fundingInterval;
        emit InterestRateSet(_interestRate, _fundingInterval);
    }

    // GMX: GMX used a different funding rate for stable coin
    function _updateFundingRate(Market storage market) internal returns (uint256) {
        uint256 _now = block.timestamp;
        if (market.lastFundingTimestamp == 0 || market.poolAmount == 0) {
            market.lastFundingTimestamp = (_now / fundingInterval) * fundingInterval;
        } else {
            uint256 nInterval = (_now - market.lastFundingTimestamp) / fundingInterval;
            if (nInterval == 0) {
                return market.fundingIndex;
            }

            uint256 utilization = (market.reserveAmount * UTILIZATION_PRECISION) /
                market.poolAmount;
            market.fundingIndex += (nInterval * interestRate * utilization) / UTILIZATION_PRECISION;
            market.lastFundingTimestamp += nInterval * fundingInterval;
        }

        return market.fundingIndex;
    }
}

contract RiskManagement {
    function validatePositionSize(
        bool _isIncrease,
        uint256 _size,
        uint256 _collateralValue,
        uint256 _maxLeverage
    ) internal view {
        if (_isIncrease && _size == 0) {
            revert Errors.InvalidPositionSize();
        }

        require(_size >= _collateralValue, "RiskManagement:: invalid leverage");
        require(_size <= _collateralValue * _maxLeverage, "RiskManagement: max leverage exceeded");
    }

    function validateLiquidation(
        Position memory _position,
        Fee memory _feeStruct,
        uint256 _indexPrice,
        uint256 _minMarginRatio,
        uint256 _fundingRate
    ) internal view {
        if (
            _liquidationPositionAllowed(
                _position,
                _feeStruct,
                _indexPrice,
                _minMarginRatio,
                _fundingRate
            )
        ) {
            revert Errors.MarginRatioNotMet();
        }
    }

    function _liquidationPositionAllowed(
        Position memory _position,
        Fee memory _feeStruct,
        uint256 _indexPrice,
        uint256 _minMarginRatioBps,
        uint256 _fundingRate
    ) internal view returns (bool) {
        if (_position.size == 0) {
            return false;
        }

        uint256 feeValue = PositionLib.calcMarginFees(
            _position,
            _feeStruct.positionFee,
            _position.size,
            _fundingRate
        );

        int256 pnl = PositionLib.calcPnl(
            _position.isLong,
            _position.size,
            _position.entryPrice,
            _indexPrice
        );
        int256 remain = int256(_position.collateralValue) + pnl - int256(feeValue);
        uint256 maintenanceMargin = (_position.size * _minMarginRatioBps) /
            Constants.BASIS_POINTS_DIVISOR;

        return
            remain < int256(maintenanceMargin) ||
            remain < int256(feeValue + _feeStruct.liquidationFeeUsd);
    }
}

// import IERC20

interface IVToken is IERC20 {
    function mint(address receiver, uint256 amount) external;
}

interface IVault {
    function getAmountInAndUpdateVaultBalance() external returns (uint256);

    function payout(uint256 _amount, address _receiver, uint256 _collateralAmount) external;

    function updateRealizedPnl(bool hasProfit, uint256 pnl) external;
}

interface ICollateralModule {
    function depositERC721(
        address _asset,
        uint256 _tokenId,
        address _collateralOut
    ) external returns (bytes32 collateralPositionKey, uint256 collateralOutAmount);

    // Given a token, return the amount of collateral out that can be borrowed against it.
    function valuateERC721Asset(
        uint256 _collateralInTokenId,
        address _collateralOut
    ) external view returns (uint256);

    function liquidateCollateralPosition(bytes32 _collateralPositionKey) external returns (uint256);
}

contract TradingEngine is ReentrancyGuard, FundingManager, RiskManagement, ITradingEngine {
    struct TokenConfig {
        address token;
        uint256 decimals;
        uint256 tokenWeight;
        uint256 minProfitBps;
        uint256 maxLpAmount;
        bool isStable;
        bool isShortable;
    }

    address public gov;
    address public orderbook;
    address[] public allTokens;
    mapping(address => bool) public isWhitelistedToken;
    uint256 public override whitelistedTokenCount;
    uint256 public override totalTokenWeights;
    mapping(address => TokenConfig) public tokenConfigs;

    // tokenWeights allows customisation of index composition
    mapping(address => uint256) public override tokenWeights;

    // vlpAmounts tracks the amount of vLP debt for each whitelisted token
    mapping(address => uint256) public vLpAmountsPerToken;
    mapping(address => Market) public markets;
    mapping(address => IVault) public vaults;
    mapping(address => bool) public isStableCoin;
    mapping(bytes32 => Position) public positions;
    mapping(address => IVToken) public vTokens;

    mapping(address => uint256) public liquidityIndex;

    uint256 public taxBasisPoints; // 0.5%
    uint256 public mintBurnFeeBasisPoints; // 0.3%
    uint256 public maxLeverage = 50 * 10000; // 50x -TODO: check leverage
    uint256 public minMarginRatioBps = 100; // 1%
    bool public isFeeEnabled;

    IvLPToken public vLp;
    IFastPriceFeed public priceFeed;

    Fee public feeStruct;

    using SafeERC20 for IERC20;
    using MarketLib for Market;
    using PositionLib for Position;
    using SafeTransfer for IERC20;

    event CollectSwapFees(address token, uint256 feeInUsd, uint256 feeInTokens);
    event SetPriceFeed(address priceFeed);
    event CollectMarginFees(address token, uint256 feeUsd, uint256 feeTokens);

    constructor(address _vLpToken, address _priceFeed) {
        vLp = IvLPToken(_vLpToken);
        priceFeed = IFastPriceFeed(_priceFeed);

        gov = msg.sender;

        // uint256 public taxBasisPoints = 50; // 0.5%
        // uint256 public mintBurnFeeBasisPoints = 30; // 0.3%
        // uint256 public maxLeverage = 50 * 10000; // 50x -TODO: check leverage
        // uint256 public minMarginRatioBps = 100; // 1%
    }

    modifier onlyGov() {
        require(msg.sender == gov, "TradingEngine::onlyGov");
        _;
    }

    modifier onlyOrderBook() {
        require(msg.sender == orderbook, "TradingEngine::onlyOrderbook");
        _;
    }

    modifier onlyWhitelistedToken(address _token) {
        require(isWhitelistedToken[_token], "TradingEngine::onlyWhitelistedToken");
        _;
    }

    function setVToken(address _token, address _vToken) external onlyGov {
        vTokens[_token] = IVToken(_vToken);
    }

    // ============ Governing functions ============

    function addToken(
        address _token,
        uint256 _decimals,
        uint256 _tokenWeight,
        uint256 _minProfitBps,
        uint256 _maxLpAmount,
        bool _isStable,
        bool _isShortable
    ) external onlyGov {
        if (!isWhitelistedToken[_token]) {
            whitelistedTokenCount += 1;
            allTokens.push(_token);
            isWhitelistedToken[_token] = true;
            if (_isStable) {
                isStableCoin[_token] = true;
            }
        }

        uint256 _totalTokenWeights = totalTokenWeights - tokenWeights[_token];

        tokenConfigs[_token] = TokenConfig({
            token: _token,
            decimals: _decimals,
            tokenWeight: _tokenWeight,
            minProfitBps: _minProfitBps,
            maxLpAmount: _maxLpAmount,
            isStable: _isStable,
            isShortable: _isShortable
        });
        tokenWeights[_token] = _tokenWeight;

        totalTokenWeights = _totalTokenWeights + _tokenWeight;
    }

    function addVault(address _token, address _vault) external onlyGov {
        vaults[_token] = IVault(_vault);
    }

    function getVault(address _token) external view returns (address) {
        return address(vaults[_token]);
    }

    function removeToken(address _token) external onlyGov {
        require(isWhitelistedToken[_token], "TradingEngine::TOKEN_NOT_WHITELISTED");
        isWhitelistedToken[_token] = false;
        totalTokenWeights = totalTokenWeights - tokenWeights[_token];
        whitelistedTokenCount = whitelistedTokenCount - 1;
        delete tokenConfigs[_token];
    }

    function getNormalizedIncome(address _token) external view returns (int256) {
        Market memory market = markets[_token];

        int256 income = int256(market.incomeAmount) +
            int256(market.feeReserve) -
            int256(market.lossAmount);

        return income;
    }

    function setPriceFeed(address _priceFeed) external onlyGov {
        require(_priceFeed != address(0), "TradingEngine::INVALID_PRICE_FEED");
        priceFeed = IFastPriceFeed(_priceFeed);
        emit SetPriceFeed(_priceFeed);
    }

    // TODO
    function setFees(
        uint256 positionFee,
        uint256 liquidationFeeUsd,
        uint256 baseSwapFee,
        uint256 taxBasisPoint,
        uint256 stableCoinBaseSwapFee,
        uint256 stableCoinTaxBasisPoint,
        uint256 daoFee
    ) external onlyGov {
        feeStruct.positionFee = positionFee;
        feeStruct.liquidationFeeUsd = liquidationFeeUsd;
        feeStruct.baseSwapFee = baseSwapFee;
        feeStruct.taxBasisPoint = taxBasisPoint;
        feeStruct.stableCoinBaseSwapFee = stableCoinBaseSwapFee;
        feeStruct.stableCoinTaxBasisPoint = stableCoinTaxBasisPoint;
        feeStruct.daoFee = daoFee;
    }

    function setPositionFee(uint256 _positionFee) external onlyGov {
        feeStruct.positionFee = _positionFee;
    }

    function getFeeStruct() external view returns (Fee memory) {
        return feeStruct;
    }

    function setMinMarginRation() external onlyGov {}

    // ============

    // ============ Token Config functions ============

    function getTargetVlpAmount(address _token) public view override returns (uint256) {
        uint256 supply = vLp.totalSupply();
        if (supply == 0) {
            return 0;
        }

        uint256 weight = tokenWeights[_token];
        return (weight * supply) / totalTokenWeights;
    }

    // ============ Liquidity functions ============
    function addLiquidity(
        address _token,
        uint256 _amount,
        address _receiver
    ) external payable nonReentrant onlyWhitelistedToken(_token) {
        Market storage market = markets[_token];
        _updateFundingRate(market);
        // Level finance: accure interest for this token
        uint256 _amountIn = _requireAmount(_transferIn(_token, _amount));
        (uint256 amountAfterFees, uint256 liquidity) = _computeLiquidity(_token, _amountIn);
        vLp.mint(_receiver, liquidity);
        market.increasePoolAmount(amountAfterFees);
    }

    function addLiquidityIsolated(
        address _token,
        uint256 _amount,
        address _receiver
    ) external payable nonReentrant onlyWhitelistedToken(_token) {
        Market storage market = markets[_token];
        _updateFundingRate(market);

        uint256 _amountIn = _requireAmount(_transferIn(_token, _amount));
        // deduct fees
        IVToken vToken = vTokens[_token];
        vToken.mint(_receiver, _amountIn);
        market.increasePoolAmount(_amountIn);
    }

    // TODO: function removeLiquidity()

    function increasePosition(
        address _account,
        address _indexToken,
        address _collateralToken,
        uint256 _sizeDelta,
        bool _isLong
    ) external nonReentrant {
        // TODO: nonReentrant onlyOrderBook
        // GMX: validate isLeveragedEnabled
        // GMX: _validateGasPrice(); ?? not sure what is this
        // Checking if position size doesn't exceed reserve

        // validate sizeDelta
        require(
            _validateTokenPairs(_indexToken, _collateralToken, _isLong),
            "TradingEngine::INVALID_TOKEN_PAIR"
        );

        Market storage indexMarket = markets[_indexToken];
        Market storage collateralMarket = markets[_collateralToken];

        // GMX: preHook: engineUtils.validateIncreasePosition
        uint256 nextFundingRate = _updateFundingRate(indexMarket);
        bytes32 key = _getPositionKey(_account, _indexToken, _collateralToken, _isLong);

        uint256 collateralAmount = _requireAmount(
            vaults[_collateralToken].getAmountInAndUpdateVaultBalance()
        );

        // use maximized price for long and minimized price for short
        uint256 price = _getPrice(_indexToken, _isLong);
        uint256 collateralValue = _tokenAmountToMinUSD(_collateralToken, collateralAmount);

        uint256 reserveDelta = _usdToTokenMax(_collateralToken, _sizeDelta);

        Position storage position = positions[key];
        position.collateralAmount = collateralAmount;

        uint256 feeValue = position.increase(
            feeStruct,
            _isLong,
            _sizeDelta,
            collateralValue,
            reserveDelta,
            price,
            nextFundingRate
        );

        validatePositionSize(true, position.size, position.collateralValue, maxLeverage);
        validateLiquidation(position, feeStruct, price, minMarginRatioBps, nextFundingRate);

        uint256 feeAmount = _feeValueToTokenAmount(_collateralToken, feeValue);

        collateralMarket.feeReserve += feeAmount;

        emit CollectMarginFees(_collateralToken, feeValue, feeAmount);

        collateralMarket.increaseReserve(reserveDelta);
        if (_isLong) {
            collateralMarket.increaseLongPosition(
                _sizeDelta,
                collateralAmount,
                collateralValue,
                feeAmount,
                feeValue
            );
        } else {
            indexMarket.increaseShortPosition(_sizeDelta, price);
        }

        // Validate position size not exceeding max leverage
        //  TODO: validate liquidation

        // GMX: event IncreasePositionEvent
        // GMX: event UpdatePositionEvent
    }

    function increasePositionExternalCollateral(
        address _account,
        address _indexToken,
        address _collateralToken,
        uint256 _sizeDelta,
        bool _isLong,
        ITradingEngine.ExternalCollateralArgs calldata args
    ) external nonReentrant {
        // TODO: nonReentrant onlyOrderBook
        // GMX: validate isLeveragedEnabled
        // GMX: _validateGasPrice(); ?? not sure what is this
        // Checking if position size doesn't exceed reserve

        // validate sizeDelta
        require(
            _validateTokenPairs(_indexToken, _collateralToken, _isLong),
            "TradingEngine::INVALID_TOKEN_PAIR"
        );

        Market storage indexMarket = markets[_indexToken];
        Market storage collateralMarket = markets[_collateralToken];

        // GMX: preHook: engineUtils.validateIncreasePosition
        uint256 nextFundingRate = _updateFundingRate(indexMarket);
        bytes32 key = _getPositionKeyExternalCollateral(
            _account,
            _indexToken,
            _collateralToken,
            _isLong,
            args.collateralModule,
            args.collateralPositionKey
        );
        // uint256 _collateralAmount = _requireAmount(
        //     _getAmountInAndUpdatePoolBalance(_collateralToken)
        // );

        // use maximized price for long and minimized price for short
        uint256 price = _getPrice(_indexToken, _isLong);
        uint256 collateralValue = _tokenAmountToMinUSD(_collateralToken, args.collateralAmount);

        uint256 reserveDelta = _usdToTokenMax(_collateralToken, _sizeDelta);

        Position storage position = positions[key];
        position.collateralAmount = args.collateralAmount;

        uint256 feeValue = position.increase(
            feeStruct,
            _isLong,
            _sizeDelta,
            collateralValue,
            reserveDelta,
            price,
            nextFundingRate
        );

        position.collateralModule = args.collateralModule;
        position.collateralPositionKey = args.collateralPositionKey;

        validatePositionSize(true, position.size, position.collateralValue, maxLeverage);
        validateLiquidation(position, feeStruct, price, minMarginRatioBps, nextFundingRate);

        uint256 feeAmount = _feeValueToTokenAmount(_collateralToken, feeValue);

        collateralMarket.feeReserve += feeAmount;

        emit CollectMarginFees(_collateralToken, feeValue, feeAmount);

        collateralMarket.increaseReserve(reserveDelta);
        if (_isLong) {
            collateralMarket.increaseLongPosition(
                _sizeDelta,
                args.collateralAmount,
                collateralValue,
                feeAmount,
                feeValue
            );
        } else {
            indexMarket.increaseShortPosition(_sizeDelta, price);
        }

        // Validate position size not exceeding max leverage
        //  TODO: validate liquidation

        // GMX: event IncreasePositionEvent
        // GMX: event UpdatePositionEvent
    }

    function decreasePosition(
        address _account,
        address _indexToken,
        address _collateralToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong
    ) external {
        // TODO: nonReentrant onlyOrderBook

        // TODO: nonReentrant onlyOrderBook
        // GMX: validate isLeveragedEnabled
        // GMX: _validateGasPrice(); ?? not sure what is this

        // validate sizeDelta
        require(
            _validateTokenPairs(_indexToken, _collateralToken, _isLong),
            "TradingEngine::INVALID_TOKEN_PAIR"
        );

        // GMX: preHook: engineUtils.validateIncreasePosition
        uint256 nextFundingRate = _updateFundingRate(markets[_indexToken]);
        bytes32 key = _getPositionKey(_account, _indexToken, _collateralToken, _isLong);

        Position storage position = positions[key];
        if (position.size == 0) {
            revert Errors.PositionNotExists(_account, _indexToken, _collateralToken, false);
        }

        uint256 price = _isLong ? _getMinPrice(_indexToken) : _getMaxPrice(_indexToken);

        bool isFullyClosed = _sizeDelta == position.size;

        // realizedPnl to reserve reduced amount
        DecreasePositionResult memory result = position.decrease(
            feeStruct,
            _isLong,
            _sizeDelta,
            _collateralDelta,
            price,
            nextFundingRate,
            false
        );

        {
            if (!isFullyClosed) {
                validatePositionSize(false, position.size, position.collateralValue, maxLeverage);
                validateLiquidation(position, feeStruct, price, minMarginRatioBps, nextFundingRate);
            }
            uint256 feeAmount = _feeValueToTokenAmount(_collateralToken, result.feeValue);

            uint256 payoutAmount = _usdToTokenMin(_collateralToken, result.payoutValue);

            _updateTradingEngineStatePostDecreasePosition(
                result,
                _indexToken,
                _collateralToken,
                _sizeDelta,
                _isLong,
                payoutAmount,
                feeAmount
            );
            _doTransferOut(_collateralToken, _account, payoutAmount, position.collateralAmount);
        }
        // }

        // decrease open interest short or open intesrt long

        // use maximized price for long and minimized price for short

        // delete positions[key] if is a close order

        emit DecreasePosition(
            key,
            _account,
            _collateralToken,
            _indexToken,
            result.collateralValueReduced,
            _sizeDelta,
            _isLong,
            price
        );

        if (position.size == 0) {
            delete positions[key];
            emit ClosePosition(
                key,
                position.size,
                position.collateralValue,
                position.entryPrice,
                position.entryFundingRate,
                position.reserveAmount
            );
        } else {
            emit UpdatePosition(
                key,
                position.size,
                position.collateralValue,
                position.entryPrice,
                position.entryFundingRate,
                position.reserveAmount,
                price
            );
        }
    }

    function liquidatePosition(
        address _account,
        address _indexToken,
        address _collateralToken,
        bool _isLong,
        address _feeReceiver
    ) external {
        require(
            _validateTokenPairs(_indexToken, _collateralToken, _isLong),
            "TradingEngine::INVALID_TOKEN_PAIR"
        );

        uint256 nextFundingRate = _updateFundingRate(markets[_indexToken]);
        uint256 price = _isLong ? _getMinPrice(_indexToken) : _getMaxPrice(_indexToken);
        bytes32 key = _getPositionKey(_account, _indexToken, _collateralToken, _isLong);
        Position storage position = positions[key];

        require(
            _liquidationPositionAllowed(
                position,
                feeStruct,
                price,
                minMarginRatioBps,
                nextFundingRate
            ),
            "Position is not liquidatable"
        );

        uint256 sizeDelta = position.size;

        DecreasePositionResult memory result = position.decrease(
            feeStruct,
            _isLong,
            sizeDelta, // decrease 100% size
            0,
            price,
            nextFundingRate,
            true
        );

        uint256 feeAmount = _feeValueToTokenAmount(_collateralToken, result.feeValue);
        uint256 payoutAmount = _usdToTokenMin(_collateralToken, result.payoutValue);

        _updateTradingEngineStatePostDecreasePosition(
            result,
            _indexToken,
            _collateralToken,
            sizeDelta,
            _isLong,
            payoutAmount,
            feeAmount
        );

        _doTransferOut(_collateralToken, _account, payoutAmount, position.collateralAmount);
        _doTransferOut(
            _collateralToken,
            msg.sender,
            calcLiquidationFeeInTokens(_collateralToken, feeStruct.liquidationFeeUsd),
            0
        );

        delete positions[key];
    }

    function liquidatePositionExternalCollateral(
        address _account,
        address _indexToken,
        address _collateralToken,
        bool _isLong,
        address _collateralModule,
        bytes32 _collateralPositionKey
    ) external {
        require(
            _validateTokenPairs(_indexToken, _collateralToken, _isLong),
            "TradingEngine::INVALID_TOKEN_PAIR"
        );

        uint256 nextFundingRate = _updateFundingRate(markets[_indexToken]);
        uint256 price = _isLong ? _getMinPrice(_indexToken) : _getMaxPrice(_indexToken);
        bytes32 key = _getPositionKeyExternalCollateral(
            _account,
            _indexToken,
            _collateralToken,
            _isLong,
            _collateralModule,
            _collateralPositionKey
        );
        Position storage position = positions[key];

        require(
            _liquidationPositionAllowed(
                position,
                feeStruct,
                price,
                minMarginRatioBps,
                nextFundingRate
            ),
            "Position is not liquidatable"
        );

        uint256 sizeDelta = position.size;

        DecreasePositionResult memory result = position.decrease(
            feeStruct,
            _isLong,
            sizeDelta, // decrease 100% size
            0,
            price,
            nextFundingRate,
            true
        );

        _liquidate(_collateralToken, _account, result, position);
        delete positions[key];
    }

    function _liquidate(
        address _collateralToken,
        address _account,
        DecreasePositionResult memory result,
        Position memory position
    ) internal {
        uint256 feeAmount = _feeValueToTokenAmount(_collateralToken, result.feeValue);
        uint256 payoutAmount = _usdToTokenMin(_collateralToken, result.payoutValue);

        uint256 collateralAmount = ICollateralModule(position.collateralModule)
            .liquidateCollateralPosition(position.collateralPositionKey);

        // premium for liquidator , dirty code
        uint256 amountToPool = collateralAmount - feeAmount - payoutAmount; // handle cap 0

        _doTransferOut(_collateralToken, _account, payoutAmount, position.collateralAmount);
        _doTransferOut(
            _collateralToken,
            msg.sender,
            calcLiquidationFeeInTokens(_collateralToken, feeStruct.liquidationFeeUsd),
            0
        );

        Market storage collateralMarket = markets[_collateralToken];
        collateralMarket.increasePoolAmount(amountToPool);
        collateralMarket.decreaseReserve(result.reserveDelta);
        collateralMarket.feeReserve += feeAmount;

        // update poolBalance
        uint256 balance = IERC20(_collateralToken).balanceOf(address(this));
        collateralMarket.poolBalance = balance;
        //TODO: transfer premium to liquidator
    }

    function calcLiquidationFeeInTokens(
        address _token,
        uint256 _usdValue
    ) internal view returns (uint256) {
        uint256 adjustedValue = (_usdValue * 10 ** tokenConfigs[_token].decimals) /
            Constants.LIQUIDATION_FEE_DIVISOR;
        return _usdToTokenMin(_token, adjustedValue);
    }

    function _doTransferOut(
        address _token,
        address _to,
        uint256 _amount,
        uint256 _collateralAmount
    ) internal {
        if (_amount > 0) {
            IVault vault = vaults[_token];
            vault.payout(_amount, _to, _collateralAmount);
        }
    }

    function _updateTradingEngineStatePostDecreasePosition(
        DecreasePositionResult memory result,
        address _indexToken,
        address _collateralToken,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 payoutAmount,
        uint256 feeAmount
    ) internal {
        Market storage indexMarket = markets[_indexToken];
        Market storage collateralMarket = markets[_collateralToken];

        if (_isLong) {
            collateralMarket.decreaseLongPosition(
                result.collateralValueReduced,
                _sizeDelta,
                payoutAmount,
                feeAmount
            );

            (bool hasProfit, uint256 pnl) = _getRealizedPnl(result.realizedPnl);
            uint256 tokenAmount = _usdToTokenMin(_indexToken, pnl);

            // inverse the sign of realizedPnl as profit of trader is loss of pool
            // loss of trader is profit of pool
            // vaults[_collateralToken].updateRealizedPnl(!hasProfit, tokenAmount);
            if (!hasProfit) {
                vaults[_collateralToken].updateRealizedPnl(true, tokenAmount);
            }
        } else {
            (bool hasProfit, uint256 pnl) = _getRealizedPnl(result.realizedPnl);

            // is short
            uint256 tokenAmount = _usdToTokenMin(_collateralToken, pnl);
            if (result.realizedPnl > 0) {
                // pay out realised profits from the pool amount for short positions
                // collateralMarket.decreasePoolAmount(tokenAmount);
                vaults[_collateralToken].updateRealizedPnl(false, tokenAmount);
            } else if (result.realizedPnl < 0) {
                // transfer realised losses to the pool for short positions
                // realised losses for long positions are not transferred here as
                // _increasePoolAmount was already called in increasePosition for longs
                // collateralMarket.increasePoolAmount(tokenAmount);

                vaults[_collateralToken].updateRealizedPnl(true, tokenAmount);
            }

            indexMarket.decreaseShortPosition(_sizeDelta);
        }

        collateralMarket.decreaseReserve(result.reserveDelta);
        collateralMarket.feeReserve += feeAmount;
        emit CollectMarginFees(_collateralToken, result.feeValue, feeAmount);
    }

    function _getRealizedPnl(
        int256 _realizedPnl
    ) internal returns (bool hasProfit, uint256 amount) {
        if (_realizedPnl > 0) {
            hasProfit = true;
            amount = uint256(_realizedPnl);
        } else {
            hasProfit = false;
            amount = uint256(-_realizedPnl);
        }
    }

    function _feeValueToTokenAmount(
        address _token,
        uint256 _feeValue
    ) internal view returns (uint256) {
        return _usdToToken(_feeValue, _getMinPrice(_token));
    }

    function _getMinPrice(address _token) private view returns (uint256) {
        uint256 price = priceFeed.getPrice(_token, false);
        require(price > 0, "TradingEngine::INVALID_PRICE");
        return price;
    }

    function _getMaxPrice(address _token) private view returns (uint256) {
        uint256 price = priceFeed.getPrice(_token, true);
        require(price > 0, "TradingEngine::INVALID_PRICE");
        return price;
    }

    function _usdToTokenMax(address _token, uint256 _usdAmount) public view returns (uint256) {
        return _usdToToken(_usdAmount, _getPrice(_token, false));
    }

    function _usdToTokenMin(address _token, uint256 _usdAmount) public view returns (uint256) {
        return _usdToToken(_usdAmount, _getPrice(_token, true));
    }

    function _usdToToken(uint256 _usdAmount, uint256 _price) private view returns (uint256) {
        if (_usdAmount == 0) {
            return 0;
        }

        return _usdAmount / _price;
    }

    function _tokenAmountToMaxUSD(address _token, uint256 _amount) internal view returns (uint256) {
        uint256 price = _getPrice(_token, true);
        return _amount * price;
    }

    function _tokenAmountToMinUSD(address _token, uint256 _amount) internal view returns (uint256) {
        uint256 minPrice = _getPrice(_token, false);
        return _amount * minPrice;
    }

    function _validateTokenPairs(
        address _indexToken,
        address _collateralToken,
        bool _isLong
    ) internal view returns (bool) {
        if (!isWhitelistedToken[_indexToken] || !isWhitelistedToken[_collateralToken]) {
            revert Errors.TokenNotWhitelisted();
        }

        if (_isLong) {
            return !isStableCoin[_indexToken] && _indexToken == _collateralToken;
        } else {
            return tokenConfigs[_indexToken].isShortable && isStableCoin[_collateralToken];
        }
    }

    function _getPositionKey(
        address _account,
        address _indexToken,
        address _collateralToken,
        bool _isLong
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(_account, _indexToken, _collateralToken, _isLong));
    }

    function _getPositionKeyExternalCollateral(
        address _account,
        address _indexToken,
        address _collateralToken,
        bool _isLong,
        address _collateralModule,
        bytes32 _collateralPositionKey
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _account,
                    _indexToken,
                    _collateralToken,
                    _isLong,
                    _collateralModule,
                    _collateralPositionKey
                )
            );
    }

    function getPosition(
        address _account,
        address _indexToken,
        address _collateralToken,
        bool _isLong
    ) external view returns (Position memory) {
        bytes32 key = _getPositionKey(_account, _indexToken, _collateralToken, _isLong);
        return positions[key];
    }

    function getPositionExternalCollateral(
        address _account,
        address _indexToken,
        address _collateralToken,
        bool _isLong,
        address _collateralModule,
        bytes32 _collateralPositionKey
    ) external view returns (Position memory) {
        bytes32 key = _getPositionKeyExternalCollateral(
            _account,
            _indexToken,
            _collateralToken,
            _isLong,
            _collateralModule,
            _collateralPositionKey
        );
        return positions[key];
    }

    function getMarket(address _token) external view returns (Market memory) {
        return markets[_token];
    }

    function _transferIn(address _token, uint256 _amount) internal returns (uint256) {
        if (_token != Constants.ETH_ADDRESS) {
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        } else {
            require(msg.value >= _amount, "AssetManager: invalid value sent");
        }

        return _getAmountInAndUpdatePoolBalance(_token);
    }

    function _requireAmount(uint256 _amount) internal pure returns (uint256) {
        if (_amount == 0) {
            revert Errors.ZeroAmount();
        }

        return _amount;
    }

    function _getAmountInAndUpdatePoolBalance(address _token) internal returns (uint256) {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        uint256 amountIn = balance - markets[_token].poolBalance;
        markets[_token].poolBalance = balance;
        return amountIn;
    }

    function _calcTotalTradingEngineValue() internal view returns (uint256) {
        int256 total = 0;
        for (uint256 i = 0; i < allTokens.length; i++) {
            address token = allTokens[i];
            Market storage market = markets[token];
            uint256 decimals = tokenConfigs[token].decimals;
            uint256 price = _getPrice(token, true);
            if (tokenConfigs[token].isStable) {
                total += int256((market.poolAmount * price) / 10 ** decimals);
            } else {
                uint256 remain = market.poolAmount - market.reserveAmount;
                total += market.getAUM(price) / int256(10 ** decimals);
            }
        }

        // total MUST not be negative
        return uint256(total);
    }

    function adjustForDecimals(
        uint256 _amount,
        uint256 _decimalsMul,
        uint256 _decimalsDiv
    ) public pure returns (uint256) {
        return (_amount * 10 ** _decimalsMul) / 10 ** _decimalsDiv;
    }

    function _getFeeBps(address _token, uint256 _liquidityDelta) internal view returns (uint256) {
        return
            FeeLib.getFeeBasisPoints(
                getTargetVlpAmount(_token),
                _liquidityDelta,
                vLpAmountsPerToken[_token],
                mintBurnFeeBasisPoints,
                taxBasisPoints,
                true
            );
    }

    function _computeLiquidity(
        address _token,
        uint256 _amount
    ) internal returns (uint256 amountAfterFees, uint256 liquidity) {
        uint256 price = _getPrice(_token, false); // deicmals 12
        // WRONG  /Constants.USDG_DECIMALS:
        uint256 liquidityDelta = (_amount * price) / Constants.USD_VALUE_PRECISION;
        uint256 feeBps = _getFeeBps(_token, liquidityDelta);
        amountAfterFees = _collectSwapFees(_token, _amount, feeBps, price);

        uint256 totalTradingEngineValue = _calcTotalTradingEngineValue();
        uint256 supply = vLp.totalSupply();

        uint256 lpAmount;
        if (supply == 0) {
            lpAmount = (amountAfterFees * price) / Constants.LP_INITIAL_PRICE;
        } else {
            // LP Amount = (amountAfterFees * price) / (totalTradingEngineValue / supply)
            lpAmount =
                (amountAfterFees * price * supply) /
                (totalTradingEngineValue * 10 ** Constants.LP_DECIMALS);
        }

        liquidity = adjustForDecimals(
            lpAmount,
            Constants.LP_DECIMALS,
            tokenConfigs[_token].decimals
        );
    }

    function _collectSwapFees(
        address _token,
        uint256 _amount,
        uint256 _feeBasisPoints,
        uint256 _indexPrice
    ) internal returns (uint256) {
        uint256 afterFeeAmount = (_amount * (Constants.BASIS_POINTS_DIVISOR - _feeBasisPoints)) /
            Constants.BASIS_POINTS_DIVISOR;
        uint256 feeAmount = _amount - afterFeeAmount;
        markets[_token].feeReserve += feeAmount;
        emit CollectSwapFees(_token, feeAmount * _indexPrice, feeAmount);
        return afterFeeAmount;
    }

    function _getPrice(address _token, bool _isMax) internal view returns (uint256) {
        uint256 price = priceFeed.getPrice(_token, _isMax);
        require(price > 0, "TradingEngine::INVALID_PRICE");
        return price;
    }

    function updateVaultBalance(address _token, uint256 _delta, bool _isIncrease) external {
        // check if _token is whitelisted
        Market storage market = markets[_token];
        if (_isIncrease) {
            market.increasePoolAmount(_delta);
        } else {
            market.decreasePoolAmount(_delta);
        }
    }

    /* ========== EVENTS ========== */
    event SetOrderBook(address orderBook);

    event IncreasePosition(
        bytes32 key,
        address account,
        address collateralToken,
        address indexToken,
        uint256 collateralValue,
        uint256 sizeChanged,
        bool isLong,
        uint256 indexPrice
    );
    event UpdatePosition(
        bytes32 key,
        uint256 size,
        uint256 collateralValue,
        uint256 entryPrice,
        uint256 entryInterestRate,
        uint256 reserveAmount,
        uint256 indexPrice
    );
    event DecreasePosition(
        bytes32 key,
        address account,
        address collateralToken,
        address indexToken,
        uint256 collateralChanged,
        uint256 sizeChanged,
        bool isLong,
        uint256 indexPrice
    );
    event ClosePosition(
        bytes32 key,
        uint256 size,
        uint256 collateralValue,
        uint256 entryPrice,
        uint256 entryInterestRate,
        uint256 reserveAmount
    );
    event LiquidatePosition(
        bytes32 key,
        address account,
        address collateralToken,
        address indexToken,
        bool isLong,
        uint256 size,
        uint256 collateralValue,
        uint256 reserveAmount,
        uint256 indexPrice
    );
}