// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

// OpenZeppelin Contracts (last updated v4.7.0) (interfaces/IERC3156FlashBorrower.sol)

/**
 * @dev Interface of the ERC3156 FlashBorrower, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * _Available since v4.1._
 */
interface IERC3156FlashBorrower {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "IERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
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

interface IPositionManagerDependent {
    // --- Errors ---

    /// @dev Position Manager cannot be zero.
    error PositionManagerCannotBeZero();

    /// @dev Caller is not Position Manager.
    error CallerIsNotPositionManager(address caller);

    // --- Functions ---

    /// @dev Returns address of the PositionManager contract.
    function positionManager() external view returns (address);
}

/// @dev Interface that particular AMM integrations need to implement in order to be used in OneStepLeverage.
/// Implementation will be used to swap between R and collateralToken.
interface IAMM {
    /// @dev Thrown when the amount received after a swap is below the provided minimum return parameter.
    /// @param amountReceived The amount of tokens received after the swap.
    /// @param minReturn The provided minimum return.
    error InsufficientAmountReceived(uint256 amountReceived, uint256 minReturn);

    /// @dev Thrown when a swap is only partially filled.
    error SwapPartiallyFilled();

    /// @dev Emitted when a swap between two tokens occurs.
    /// @param tokenIn The address of the input token being swapped.
    /// @param tokenOut The address of the output token being swapped.
    /// @param amountIn The amount of input tokens being swapped.
    /// @param amountOut The amount of output tokens being swapped.
    /// @param minReturn The minimum acceptable return for the swap (expressed in `tokenOut`).
    event Swap(
        address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut, uint256 minReturn
    );

    /// @dev Swaps `amountIn` of `tokenIn` for `tokenOut`. Fails if returned amount is smaller than `minReturn`.
    /// @param tokenIn Address of the token that is being swapped.
    /// @param tokenOut Address of the token to swap for.
    /// @param amountIn Amount of `tokenIn` being swapped.
    /// @param minReturn Minimum amount of `tokenOut` to get as a result of swap.
    /// @param extraData Extra data for particular integration with DEX/Aggregator.
    /// @return amountOut Actual amount that was returned from swap. Needs to be >= `minReturn`.
    function swap(
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint256 amountIn,
        uint256 minReturn,
        bytes calldata extraData
    )
        external
        returns (uint256 amountOut);
}

// OpenZeppelin Contracts v4.4.1 (interfaces/IERC3156FlashLender.sol)

/**
 * @dev Interface of the ERC3156 FlashLender, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * _Available since v4.1._
 */
interface IERC3156FlashLender {
    /**
     * @dev The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

/// @dev Interface to be used by contracts that collect fees. Contains fee recipient that can be changed by owner.
interface IFeeCollector {
    // --- Events ---

    /// @dev Fee Recipient is changed to @param feeRecipient address.
    /// @param feeRecipient New fee recipient address.
    event FeeRecipientChanged(address feeRecipient);

    // --- Errors ---

    /// @dev Invalid fee recipient.
    error InvalidFeeRecipient();

    // --- Functions ---

    /// @return Address of the current fee recipient.
    function feeRecipient() external view returns (address);

    /// @dev Sets new fee recipient address
    /// @param newFeeRecipient Address of the new fee recipient.
    function setFeeRecipient(address newFeeRecipient) external;
}

/// @dev Interface of R stablecoin token. Implements some standards like IERC20, IERC20Permit, and IERC3156FlashLender.
/// Raft's specific implementation contains IFeeCollector and IPositionManagerDependent.
/// PositionManager can mint and burn R when particular actions happen with user's position.
interface IRToken is IERC20, IERC20Permit, IERC3156FlashLender, IFeeCollector, IPositionManagerDependent {
    // --- Events ---

    /// @dev New R token is deployed
    /// @param positionManager Address of the PositionManager contract that is authorized to mint and burn new tokens.
    /// @param flashMintFeeRecipient Address of flash mint fee recipient.
    event RDeployed(address positionManager, address flashMintFeeRecipient);

    /// @dev The Flash Mint Fee Percentage has been changed.
    /// @param flashMintFeePercentage The new Flash Mint Fee Percentage value.
    event FlashMintFeePercentageChanged(uint256 flashMintFeePercentage);

    /// --- Errors ---

    /// @dev Proposed flash mint fee percentage is too big.
    /// @param feePercentage Proposed flash mint fee percentage.
    error FlashFeePercentageTooBig(uint256 feePercentage);

    // --- Functions ---

    /// @return Number representing 100 percentage.
    function PERCENTAGE_BASE() external view returns (uint256);

    /// @dev Mints new tokens. Callable only by PositionManager contract.
    /// @param to Address that will receive newly minted tokens.
    /// @param amount Amount of tokens to mint.
    function mint(address to, uint256 amount) external;

    /// @dev Mints new tokens. Callable only by PositionManager contract.
    /// @param from Address of user whose tokens are burnt.
    /// @param amount Amount of tokens to burn.
    function burn(address from, uint256 amount) external;

    /// @return Maximum flash mint fee percentage that can be set by owner.
    function MAX_FLASH_MINT_FEE_PERCENTAGE() external view returns (uint256);

    /// @return Current flash mint fee percentage.
    function flashMintFeePercentage() external view returns (uint256);

    /// @dev Sets new flash mint fee percentage. Callable only by owner.
    /// @notice The proposed flash mint fee percentage cannot exceed `MAX_FLASH_MINT_FEE_PERCENTAGE`.
    /// @param feePercentage New flash fee percentage.
    function setFlashMintFeePercentage(uint256 feePercentage) external;
}

/// @dev Interface that OneStepLeverage needs to implement
interface IFlashMintLiquidator is IERC3156FlashBorrower, IPositionManagerDependent {
    // --- Errors ---

    /// @dev AMM cannot be zero address.
    error AmmCannotBeZero();

    /// @dev Collateral token cannot be zero address.
    error CollateralTokenCannotBeZero();

    /// @dev One step leverage supports only R token flash mints.
    error UnsupportedToken();

    /// @dev Flash mint initiator is not One Step Leverage contract.
    error InvalidInitiator();

    // --- Functions ---

    /// @dev Address of the contract that handles swaps from collateral token to R.
    function amm() external view returns (IAMM);

    /// @dev Collateral token used for leverage.
    function collateralToken() external view returns (IERC20);

    /// @dev Address of Raft debt token. Used to get amount of debt to liquidate.
    function raftDebtToken() external view returns (IERC20);

    /// @dev Address of R token.
    function rToken() external view returns (IRToken);

    /// @dev Liquidates position by:
    /// 1. Flash mint R
    /// 2. Liquidate position
    /// 3. Swap collateralToken to R
    /// 4. Repay flash mint and take profit.
    /// @param position Position to liquidate.
    /// @param ammData Additional data to pass to amm for swap.
    function liquidate(address position, bytes calldata ammData) external;
}

/// Parameters for ERC20Permit.permit call
struct ERC20PermitSignature {
    IERC20Permit token;
    uint256 value;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
}

library PermitHelper {
    function applyPermit(
        ERC20PermitSignature calldata p,
        address owner,
        address spender
    ) internal {
        p.token.permit(owner, spender, p.value, p.deadline, p.v, p.r, p.s);
    }

    function applyPermits(
        ERC20PermitSignature[] calldata permits,
        address owner,
        address spender
    ) internal {
        for (uint256 i = 0; i < permits.length; i++) {
            applyPermit(permits[i], owner, spender);
        }
    }
}

interface IERC20Indexable is IERC20, IPositionManagerDependent {
    // --- Events ---

    /// @dev New token is deployed.
    /// @param positionManager Address of the PositionManager contract that is authorized to mint and burn new tokens.
    event ERC20IndexableDeployed(address positionManager);

    /// @dev New index has been set.
    /// @param newIndex Value of the new index.
    event IndexUpdated(uint256 newIndex);

    // --- Errors ---

    /// @dev Unsupported action for ERC20Indexable contract.
    error NotSupported();

    // --- Functions ---

    /// @return Precision for token index. Represents index that is equal to 1.
    function INDEX_PRECISION() external view returns (uint256);

    /// @return Current index value.
    function currentIndex() external view returns (uint256);

    /// @dev Sets new token index. Callable only by PositionManager contract.
    /// @param backingAmount Amount of backing token that is covered by total supply.
    function setIndex(uint256 backingAmount) external;

    /// @dev Mints new tokens. Callable only by PositionManager contract.
    /// @param to Address that will receive newly minted tokens.
    /// @param amount Amount of tokens to mint.
    function mint(address to, uint256 amount) external;

    /// @dev Mints new tokens. Callable only by PositionManager contract.
    /// @param from Address of user whose tokens are burnt.
    /// @param amount Amount of tokens to burn.
    function burn(address from, uint256 amount) external;
}

interface IWstETH is IERC20 {
    // --- Functions ---

    function stETH() external returns (IERC20);

    /// @notice Exchanges stETH to wstETH
    /// @param stETHAmount amount of stETH to wrap in exchange for wstETH
    /// @dev Requirements:
    ///  - `stETHAmount` must be non-zero
    ///  - msg.sender must approve at least `stETHAmount` stETH to this
    ///    contract.
    ///  - msg.sender must have at least `stETHAmount` of stETH.
    /// User should first approve `stETHAmount` to the WstETH contract
    /// @return Amount of wstETH user receives after wrap
    function wrap(uint256 stETHAmount) external returns (uint256);

    /// @notice Exchanges wstETH to stETH.
    /// @param wstETHAmount Amount of wstETH to unwrap in exchange for stETH.
    /// @dev Requirements:
    ///  - `wstETHAmount` must be non-zero
    ///  - msg.sender must have at least `wstETHAmount` wstETH.
    /// @return Amount of stETH user receives after unwrap.
    function unwrap(uint256 wstETHAmount) external returns (uint256);

    /// @notice Get amount of wstETH for a given amount of stETH.
    /// @param stETHAmount Amount of stETH.
    /// @return Amount of wstETH for a given stETH amount.
    function getWstETHByStETH(uint256 stETHAmount) external view returns (uint256);

    /// @notice Get amount of stETH for a given amount of wstETH.
    /// @param wstETHAmount amount of wstETH.
    /// @return Amount of stETH for a given wstETH amount.
    function getStETHByWstETH(uint256 wstETHAmount) external view returns (uint256);

    /// @notice Get amount of stETH for a one wstETH.
    /// @return Amount of stETH for 1 wstETH.
    function stEthPerToken() external view returns (uint256);

    /// @notice Get amount of wstETH for a one stETH.
    /// @return Amount of wstETH for a 1 stETH.
    function tokensPerStEth() external view returns (uint256);
}

interface IPriceOracle {
    // --- Types ---

    struct PriceOracleResponse {
        bool isBrokenOrFrozen;
        bool priceChangeAboveMax;
        uint256 price;
    }

    // --- Errors ---

    /// @dev Invalid wstETH address.
    error InvalidWstETHAddress();

    // --- Functions ---

    /// @dev Return price oracle response which consists the following information: oracle is broken or frozen, the
    /// price change between two rounds is more than max, and the price.
    function getPriceOracleResponse() external returns (PriceOracleResponse memory);

    /// @dev Return wstETH address.
    function wstETH() external view returns (IWstETH);

    /// @dev Maximum time period allowed since oracle latest round data timestamp, beyond which oracle is considered
    /// frozen.
    function TIMEOUT() external view returns (uint256);

    /// @dev Used to convert a price answer to an 18-digit precision uint.
    function TARGET_DIGITS() external view returns (uint256);

    /// @dev price deviation for the oracle in percentage.
    function DEVIATION() external view returns (uint256);
}

interface IPriceFeed {
    // --- Events ---

    /// @dev Last good price has been updated.
    event LastGoodPriceUpdated(uint256 lastGoodPrice);

    /// @dev Price difference between oracles has been updated.
    /// @param priceDifferenceBetweenOracles New price difference between oracles.
    event PriceDifferenceBetweenOraclesUpdated(uint256 priceDifferenceBetweenOracles);

    /// @dev Primary oracle has been updated.
    /// @param primaryOracle New primary oracle.
    event PrimaryOracleUpdated(IPriceOracle primaryOracle);

    /// @dev Secondary oracle has been updated.
    /// @param secondaryOracle New secondary oracle.
    event SecondaryOracleUpdated(IPriceOracle secondaryOracle);

    // --- Errors ---

    /// @dev Invalid primary oracle.
    error InvalidPrimaryOracle();

    /// @dev Invalid secondary oracle.
    error InvalidSecondaryOracle();

    /// @dev Primary oracle is broken or frozen or has bad result.
    error PrimaryOracleBrokenOrFrozenOrBadResult();

    /// @dev Invalid price difference between oracles.
    error InvalidPriceDifferenceBetweenOracles();

    // --- Functions ---

    /// @dev Return primary oracle address.
    function primaryOracle() external returns (IPriceOracle);

    /// @dev Return secondary oracle address
    function secondaryOracle() external returns (IPriceOracle);

    /// @dev The last good price seen from an oracle by Raft.
    function lastGoodPrice() external returns (uint256);

    /// @dev The maximum relative price difference between two oracle responses.
    function priceDifferenceBetweenOracles() external returns (uint256);

    /// @dev Set primary oracle address.
    /// @param newPrimaryOracle Primary oracle address.
    function setPrimaryOracle(IPriceOracle newPrimaryOracle) external;

    /// @dev Set secondary oracle address.
    /// @param newSecondaryOracle Secondary oracle address.
    function setSecondaryOracle(IPriceOracle newSecondaryOracle) external;

    /// @dev Set the maximum relative price difference between two oracle responses.
    /// @param newPriceDifferenceBetweenOracles The maximum relative price difference between two oracle responses.
    function setPriceDifferenceBetweenOracles(uint256 newPriceDifferenceBetweenOracles) external;

    /// @dev Returns the latest price obtained from the Oracle. Called by Raft functions that require a current price.
    ///
    /// Also callable by anyone externally.
    /// Non-view function - it stores the last good price seen by Raft.
    ///
    /// Uses a primary oracle and a fallback oracle in case primary fails. If both fail,
    /// it uses the last good price seen by Raft.
    ///
    /// @return currentPrice Returned price.
    /// @return deviation Deviation of the reported price in percentage.
    /// @notice Actual returned price is in range `currentPrice` +/- `currentPrice * deviation / ONE`
    function fetchPrice() external returns (uint256 currentPrice, uint256 deviation);
}

interface ISplitLiquidationCollateral {
    // --- Functions ---

    /// @dev Returns lowest total debt that will be split.
    function LOW_TOTAL_DEBT() external view returns (uint256);

    /// @dev Minimum collateralisation ratio for position
    function MCR() external view returns (uint256);

    /// @dev Splits collateral between protocol and liquidator.
    /// @param totalCollateral Amount of collateral to split.
    /// @param totalDebt Amount of debt to split.
    /// @param price Price of collateral.
    /// @param isRedistribution True if this is a redistribution.
    /// @return collateralToSendToProtocol Amount of collateral to send to protocol.
    /// @return collateralToSentToLiquidator Amount of collateral to send to liquidator.
    function split(
        uint256 totalCollateral,
        uint256 totalDebt,
        uint256 price,
        bool isRedistribution
    )
        external
        view
        returns (uint256 collateralToSendToProtocol, uint256 collateralToSentToLiquidator);
}

/// @dev Common interface for the Position Manager.
interface IPositionManager is IFeeCollector {
    // --- Types ---

    /// @dev Information for a Raft indexable collateral token.
    /// @param collateralToken The Raft indexable collateral token.
    /// @param debtToken Coresponding Rafft indexable debt token.
    /// @param priceFeed The contract that provides a price for the collateral token.
    /// @param splitLiquidation The contract that calculates collateral split in case of liquidation.
    /// @param isEnabled Whether the token can be used as collateral or not.
    /// @param lastFeeOperationTime Timestamp of the last operation for the collateral token.
    /// @param borrowingSpread The current borrowing spread.
    /// @param baseRate The current base rate.
    /// @param redemptionSpread The current redemption spread.
    /// @param redemptionRebate Percentage of the redemption fee returned to redeemed positions.
    struct CollateralTokenInfo {
        IERC20Indexable collateralToken;
        IERC20Indexable debtToken;
        IPriceFeed priceFeed;
        ISplitLiquidationCollateral splitLiquidation;
        bool isEnabled;
        uint256 lastFeeOperationTime;
        uint256 borrowingSpread;
        uint256 baseRate;
        uint256 redemptionSpread;
        uint256 redemptionRebate;
    }

    // --- Events ---

    /// @dev New position manager has been token deployed.
    /// @param rToken The R token used by the position manager.
    /// @param feeRecipient The address of fee recipient.
    event PositionManagerDeployed(IRToken rToken, address feeRecipient);

    /// @dev New collateral token has been added added to the system.
    /// @param collateralToken The token used as collateral.
    /// @param raftCollateralToken The Raft indexable collateral token for the given collateral token.
    /// @param raftDebtToken The Raft indexable debt token for given collateral token.
    /// @param priceFeed The contract that provides price for the collateral token.
    event CollateralTokenAdded(
        IERC20 collateralToken,
        IERC20Indexable raftCollateralToken,
        IERC20Indexable raftDebtToken,
        IPriceFeed priceFeed
    );

    /// @dev Collateral token has been enabled or disabled.
    /// @param collateralToken The token used as collateral.
    /// @param isEnabled True if the token is enabled, false otherwise.
    event CollateralTokenModified(IERC20 collateralToken, bool isEnabled);

    /// @dev A delegate has been whitelisted for a certain position.
    /// @param position The position for which the delegate was whitelisted.
    /// @param delegate The delegate which was whitelisted.
    /// @param whitelisted Specifies whether the delegate whitelisting has been enabled (true) or disabled (false).
    event DelegateWhitelisted(address indexed position, address indexed delegate, bool whitelisted);

    /// @dev New position has been created.
    /// @param position The address of the user opening new position.
    /// @param collateralToken The token used as collateral for the created position.
    event PositionCreated(address indexed position, IERC20 indexed collateralToken);

    /// @dev The position has been closed by either repayment, liquidation, or redemption.
    /// @param position The address of the user whose position is closed.
    event PositionClosed(address indexed position);

    /// @dev Collateral amount for the position has been changed.
    /// @param position The address of the user that has opened the position.
    /// @param collateralToken The address of the collateral token being added to position.
    /// @param collateralAmount The amount of collateral added or removed.
    /// @param isCollateralIncrease Whether the collateral is added to the position or removed from it.
    event CollateralChanged(
        address indexed position, IERC20 indexed collateralToken, uint256 collateralAmount, bool isCollateralIncrease
    );

    /// @dev Debt amount for position has been changed.
    /// @param position The address of the user that has opened the position.
    /// @param collateralToken The address of the collateral token backing the debt.
    /// @param debtAmount The amount of debt added or removed.
    /// @param isDebtIncrease Whether the debt is added to the position or removed from it.
    event DebtChanged(
        address indexed position, IERC20 indexed collateralToken, uint256 debtAmount, bool isDebtIncrease
    );

    /// @dev Borrowing fee has been paid. Emitted only if the actual fee was paid - doesn't happen with no fees are
    /// paid.
    /// @param collateralToken Collateral token used to mint R.
    /// @param position The address of position's owner that triggered the fee payment.
    /// @param feeAmount The amount of tokens paid as the borrowing fee.
    event RBorrowingFeePaid(IERC20 collateralToken, address indexed position, uint256 feeAmount);

    /// @dev Liquidation has been executed.
    /// @param liquidator The liquidator that executed the liquidation.
    /// @param position The address of position's owner whose position was liquidated.
    /// @param collateralToken The collateral token used for the liquidation.
    /// @param debtLiquidated The total debt that was liquidated or redistributed.
    /// @param collateralLiquidated The total collateral liquidated.
    /// @param collateralSentToLiquidator The collateral amount sent to the liquidator.
    /// @param collateralLiquidationFeePaid The total collateral paid as the liquidation fee to the fee recipient.
    /// @param isRedistribution Whether the executed liquidation was redistribution or not.
    event Liquidation(
        address indexed liquidator,
        address indexed position,
        IERC20 indexed collateralToken,
        uint256 debtLiquidated,
        uint256 collateralLiquidated,
        uint256 collateralSentToLiquidator,
        uint256 collateralLiquidationFeePaid,
        bool isRedistribution
    );

    /// @dev Redemption has been executed.
    /// @param redeemer User that redeemed R.
    /// @param amount Amount of R that was redeemed.
    /// @param collateralSent The amount of collateral sent to the redeemer.
    /// @param fee The amount of fee paid to the fee recipient.
    /// @param rebate Redemption rebate amount.
    event Redemption(address indexed redeemer, uint256 amount, uint256 collateralSent, uint256 fee, uint256 rebate);

    /// @dev Borrowing spread has been updated.
    /// @param borrowingSpread The new borrowing spread.
    event BorrowingSpreadUpdated(uint256 borrowingSpread);

    /// @dev Redemption rebate has been updated.
    /// @param redemptionRebate The new redemption rebate.
    event RedemptionRebateUpdated(uint256 redemptionRebate);

    /// @dev Redemption spread has been updated.
    /// @param collateralToken Collateral token that the spread was set for.
    /// @param redemptionSpread The new redemption spread.
    event RedemptionSpreadUpdated(IERC20 collateralToken, uint256 redemptionSpread);

    /// @dev Base rate has been updated.
    /// @param collateralToken Collateral token that the baser rate was updated for.
    /// @param baseRate The new base rate.
    event BaseRateUpdated(IERC20 collateralToken, uint256 baseRate);

    /// @dev Last fee operation time has been updated.
    /// @param collateralToken Collateral token that the baser rate was updated for.
    /// @param lastFeeOpTime The new operation time.
    event LastFeeOpTimeUpdated(IERC20 collateralToken, uint256 lastFeeOpTime);

    /// @dev Split liquidation collateral has been changed.
    /// @param collateralToken Collateral token whose split liquidation collateral contract is set.
    /// @param newSplitLiquidationCollateral New value that was set to be split liquidation collateral.
    event SplitLiquidationCollateralChanged(
        IERC20 collateralToken, ISplitLiquidationCollateral indexed newSplitLiquidationCollateral
    );

    // --- Errors ---

    /// @dev Max fee percentage must be between borrowing spread and 100%.
    error InvalidMaxFeePercentage();

    /// @dev Max fee percentage must be between 0.5% and 100%.
    error MaxFeePercentageOutOfRange();

    /// @dev Amount is zero.
    error AmountIsZero();

    /// @dev Nothing to liquidate.
    error NothingToLiquidate();

    /// @dev Cannot liquidate last position.
    error CannotLiquidateLastPosition();

    /// @dev Cannot redeem collateral below minimum debt threshold.
    /// @param collateralToken Collateral token used to redeem.
    /// @param newTotalDebt New total debt backed by collateral, which is lower than minimum debt.
    error TotalDebtCannotBeLowerThanMinDebt(IERC20 collateralToken, uint256 newTotalDebt);

    /// @dev Fee would eat up all returned collateral.
    error FeeEatsUpAllReturnedCollateral();

    /// @dev Borrowing spread exceeds maximum.
    error BorrowingSpreadExceedsMaximum();

    /// @dev Redemption rebate exceeds maximum.
    error RedemptionRebateExceedsMaximum();

    /// @dev Redemption spread is out of allowed range.
    error RedemptionSpreadOutOfRange();

    /// @dev There must be either a collateral change or a debt change.
    error NoCollateralOrDebtChange();

    /// @dev There is some collateral for position that doesn't have debt.
    error InvalidPosition();

    /// @dev An operation that would result in ICR < MCR is not permitted.
    /// @param newICR Resulting ICR that is bellow MCR.
    error NewICRLowerThanMCR(uint256 newICR);

    /// @dev Position's net debt must be greater than minimum.
    /// @param netDebt Net debt amount that is below minimum.
    error NetDebtBelowMinimum(uint256 netDebt);

    /// @dev The provided delegate address is invalid.
    error InvalidDelegateAddress();

    /// @dev A non-whitelisted delegate cannot adjust positions.
    error DelegateNotWhitelisted();

    /// @dev Fee exceeded provided maximum fee percentage.
    /// @param fee The fee amount.
    /// @param amount The amount of debt or collateral.
    /// @param maxFeePercentage The maximum fee percentage.
    error FeeExceedsMaxFee(uint256 fee, uint256 amount, uint256 maxFeePercentage);

    /// @dev Borrower uses a different collateral token already.
    error PositionCollateralTokenMismatch();

    /// @dev Collateral token address cannot be zero.
    error CollateralTokenAddressCannotBeZero();

    /// @dev Price feed address cannot be zero.
    error PriceFeedAddressCannotBeZero();

    /// @dev Collateral token already added.
    error CollateralTokenAlreadyAdded();

    /// @dev Collateral token is not added.
    error CollateralTokenNotAdded();

    /// @dev Collateral token is not enabled.
    error CollateralTokenDisabled();

    /// @dev Split liquidation collateral cannot be zero.
    error SplitLiquidationCollateralCannotBeZero();

    /// @dev Cannot change collateral in case of repaying the whole debt.
    error WrongCollateralParamsForFullRepayment();

    // --- Functions ---

    /// @return The R token used by position manager.
    function rToken() external view returns (IRToken);

    /// @dev Retrieves information about certain collateral type.
    /// @param collateralToken The token used as collateral.
    /// @return raftCollateralToken The Raft indexable collateral token.
    /// @return raftDebtToken The Raft indexable debt token.
    /// @return priceFeed The contract that provides a price for the collateral token.
    /// @return splitLiquidation The contract that calculates collateral split in case of liquidation.
    /// @return isEnabled Whether the collateral token can be used as collateral or not.
    /// @return lastFeeOperationTime Timestamp of the last operation for the collateral token.
    /// @return borrowingSpread The current borrowing spread.
    /// @return baseRate The current base rate.
    /// @return redemptionSpread The current redemption spread.
    /// @return redemptionRebate Percentage of the redemption fee returned to redeemed positions.
    function collateralInfo(IERC20 collateralToken)
        external
        view
        returns (
            IERC20Indexable raftCollateralToken,
            IERC20Indexable raftDebtToken,
            IPriceFeed priceFeed,
            ISplitLiquidationCollateral splitLiquidation,
            bool isEnabled,
            uint256 lastFeeOperationTime,
            uint256 borrowingSpread,
            uint256 baseRate,
            uint256 redemptionSpread,
            uint256 redemptionRebate
        );

    /// @param collateralToken Collateral token whose raft collateral indexable token is being queried.
    /// @return Raft collateral token address for given collateral token.
    function raftCollateralToken(IERC20 collateralToken) external view returns (IERC20Indexable);

    /// @param collateralToken Collateral token whose raft collateral indexable token is being queried.
    /// @return Raft debt token address for given collateral token.
    function raftDebtToken(IERC20 collateralToken) external view returns (IERC20Indexable);

    /// @param collateralToken Collateral token whose price feed contract is being queried.
    /// @return Price feed contract address for given collateral token.
    function priceFeed(IERC20 collateralToken) external view returns (IPriceFeed);

    /// @param collateralToken Collateral token whose split liquidation collateral is being queried.
    /// @return Returns address of the split liquidation collateral contract.
    function splitLiquidationCollateral(IERC20 collateralToken) external view returns (ISplitLiquidationCollateral);

    /// @param collateralToken Collateral token whose split liquidation collateral is being queried.
    /// @return Returns whether collateral is enabled or nor.
    function collateralEnabled(IERC20 collateralToken) external view returns (bool);

    /// @param collateralToken Collateral token we query last operation time fee for.
    /// @return The timestamp of the latest fee operation (redemption or new R issuance).
    function lastFeeOperationTime(IERC20 collateralToken) external view returns (uint256);

    /// @param collateralToken Collateral token we query borrowing spread for.
    /// @return The current borrowing spread.
    function borrowingSpread(IERC20 collateralToken) external view returns (uint256);

    /// @param collateralToken Collateral token we query base rate for.
    /// @return rate The base rate.
    function baseRate(IERC20 collateralToken) external view returns (uint256 rate);

    /// @param collateralToken Collateral token we query redemption spread for.
    /// @return The current redemption spread for collateral token.
    function redemptionSpread(IERC20 collateralToken) external view returns (uint256);

    /// @param collateralToken Collateral token we query redemption rebate for.
    /// @return rebate Percentage of the redemption fee returned to redeemed positions.
    function redemptionRebate(IERC20 collateralToken) external view returns (uint256);

    /// @param collateralToken Collateral token we query redemption rate for.
    /// @return rate The current redemption rate for collateral token.
    function getRedemptionRate(IERC20 collateralToken) external view returns (uint256 rate);

    /// @dev Returns the collateral token that a given position used for their position.
    /// @param position The address of the borrower.
    /// @return collateralToken The collateral token of the borrower's position.
    function collateralTokenForPosition(address position) external view returns (IERC20 collateralToken);

    /// @dev Adds a new collateral token to the protocol.
    /// @param collateralToken The new collateral token.
    /// @param priceFeed The price feed for the collateral token.
    /// @param newSplitLiquidationCollateral split liquidation collateral contract address.
    function addCollateralToken(
        IERC20 collateralToken,
        IPriceFeed priceFeed,
        ISplitLiquidationCollateral newSplitLiquidationCollateral
    )
        external;

    /// @dev Enables or disables a collateral token. Reverts if the collateral token has not been added.
    /// @param collateralToken The collateral token.
    /// @param isEnabled Whether the collateral token can be used as collateral or not.
    function setCollateralEnabled(IERC20 collateralToken, bool isEnabled) external;

    /// @dev Sets the new split liquidation collateral contract.
    /// @param collateralToken Collateral token whose split liquidation collateral is being set.
    /// @param newSplitLiquidationCollateral New split liquidation collateral contract address.
    function setSplitLiquidationCollateral(
        IERC20 collateralToken,
        ISplitLiquidationCollateral newSplitLiquidationCollateral
    )
        external;

    /// @dev Liquidates the borrower if its position's ICR is lower than the minimum collateral ratio.
    /// @param position The address of the borrower.
    function liquidate(address position) external;

    /// @dev Redeems the collateral token for a given debt amount. It sends @param debtAmount R to the system and
    /// redeems the corresponding amount of collateral from as many positions as are needed to fill the redemption
    /// request.
    /// @param collateralToken The token used as collateral.
    /// @param debtAmount The amount of debt to be redeemed. Must be greater than zero.
    /// @param maxFeePercentage The maximum fee percentage to pay for the redemption.
    function redeemCollateral(IERC20 collateralToken, uint256 debtAmount, uint256 maxFeePercentage) external;

    /// @dev Manages the position on behalf of a given borrower.
    /// @param collateralToken The token the borrower used as collateral.
    /// @param position The address of the borrower.
    /// @param collateralChange The amount of collateral to add or remove.
    /// @param isCollateralIncrease True if the collateral is being increased, false otherwise.
    /// @param debtChange The amount of R to add or remove. In case of repayment (isDebtIncrease = false)
    /// `type(uint256).max` value can be used to repay the whole outstanding loan.
    /// @param isDebtIncrease True if the debt is being increased, false otherwise.
    /// @param maxFeePercentage The maximum fee percentage to pay for the position management.
    /// @param permitSignature Optional permit signature for tokens that support IERC20Permit interface.
    /// @notice `permitSignature` it is ignored if permit signature is not for `collateralToken`.
    /// @notice In case of full debt repayment, `isCollateralIncrease` is ignored and `collateralChange` must be 0.
    /// These values are set to `false`(collateral decrease), and the whole collateral balance of the user.
    /// @return actualCollateralChange Actual amount of collateral added/removed.
    /// Can be different to `collateralChange` in case of full repayment.
    /// @return actualDebtChange Actual amount of debt added/removed.
    /// Can be different to `debtChange` in case of passing type(uint256).max as `debtChange`.
    function managePosition(
        IERC20 collateralToken,
        address position,
        uint256 collateralChange,
        bool isCollateralIncrease,
        uint256 debtChange,
        bool isDebtIncrease,
        uint256 maxFeePercentage,
        ERC20PermitSignature calldata permitSignature
    )
        external
        returns (uint256 actualCollateralChange, uint256 actualDebtChange);

    /// @return The max borrowing spread.
    function MAX_BORROWING_SPREAD() external view returns (uint256);

    /// @return The max borrowing rate.
    function MAX_BORROWING_RATE() external view returns (uint256);

    /// @dev Sets the new borrowing spread.
    /// @param collateralToken Collateral token we set borrowing spread for.
    /// @param newBorrowingSpread New borrowing spread to be used.
    function setBorrowingSpread(IERC20 collateralToken, uint256 newBorrowingSpread) external;

    /// @param collateralToken Collateral token we query borrowing rate for.
    /// @return The current borrowing rate.
    function getBorrowingRate(IERC20 collateralToken) external view returns (uint256);

    /// @param collateralToken Collateral token we query borrowing rate with decay for.
    /// @return The current borrowing rate with decay.
    function getBorrowingRateWithDecay(IERC20 collateralToken) external view returns (uint256);

    /// @dev Returns the borrowing fee for a given debt amount.
    /// @param collateralToken Collateral token we query borrowing fee for.
    /// @param debtAmount The amount of debt.
    /// @return The borrowing fee.
    function getBorrowingFee(IERC20 collateralToken, uint256 debtAmount) external view returns (uint256);

    /// @dev Sets the new redemption spread.
    /// @param newRedemptionSpread New redemption spread to be used.
    function setRedemptionSpread(IERC20 collateralToken, uint256 newRedemptionSpread) external;

    /// @dev Sets new redemption rebate percentage.
    /// @param newRedemptionRebate Value that is being set as a redemption rebate percentage.
    function setRedemptionRebate(IERC20 collateralToken, uint256 newRedemptionRebate) external;

    /// @param collateralToken Collateral token we query redemption rate with decay for.
    /// @return The current redemption rate with decay.
    function getRedemptionRateWithDecay(IERC20 collateralToken) external view returns (uint256);

    /// @dev Returns the redemption fee for a given collateral amount.
    /// @param collateralToken Collateral token we query redemption fee for.
    /// @param collateralAmount The amount of collateral.
    /// @param priceDeviation Deviation for the reported price by oracle in percentage.
    /// @return The redemption fee.
    function getRedemptionFee(
        IERC20 collateralToken,
        uint256 collateralAmount,
        uint256 priceDeviation
    )
        external
        view
        returns (uint256);

    /// @dev Returns the redemption fee with decay for a given collateral amount.
    /// @param collateralToken Collateral token we query redemption fee with decay for.
    /// @param collateralAmount The amount of collateral.
    /// @return The redemption fee with decay.
    function getRedemptionFeeWithDecay(
        IERC20 collateralToken,
        uint256 collateralAmount
    )
        external
        view
        returns (uint256);

    /// @return Half-life of 12h (720 min).
    /// @dev (1/2) = d^720 => d = (1/2)^(1/720)
    function MINUTE_DECAY_FACTOR() external view returns (uint256);

    /// @dev Returns if a given delegate is whitelisted for a given borrower.
    /// @param position The address of the borrower.
    /// @param delegate The address of the delegate.
    /// @return isWhitelisted True if the delegate is whitelisted for a given borrower, false otherwise.
    function isDelegateWhitelisted(address position, address delegate) external view returns (bool isWhitelisted);

    /// @dev Whitelists a delegate.
    /// @param delegate The address of the delegate.
    /// @param whitelisted True if delegate is being whitelisted, false otherwise.
    function whitelistDelegate(address delegate, bool whitelisted) external;

    /// @return Parameter by which to divide the redeemed fraction, in order to calc the new base rate from a
    /// redemption. Corresponds to (1 / ALPHA) in the white paper.
    function BETA() external view returns (uint256);
}

abstract contract PositionManagerDependent is IPositionManagerDependent {
    // --- Immutable variables ---

    address public immutable override positionManager;

    // --- Modifiers ---

    modifier onlyPositionManager() {
        if (msg.sender != positionManager) {
            revert CallerIsNotPositionManager(msg.sender);
        }
        _;
    }

    // --- Constructor ---

    constructor(address positionManager_) {
        if (positionManager_ == address(0)) {
            revert PositionManagerCannotBeZero();
        }
        positionManager = positionManager_;
    }
}

contract FlashMintLiquidator is IFlashMintLiquidator, PositionManagerDependent {
    using SafeERC20 for IERC20;

    IAMM public immutable override amm;
    IERC20 public immutable override collateralToken;
    IERC20 public immutable override raftDebtToken;
    IRToken public immutable override rToken;

    constructor(
        IPositionManager positionManager_,
        IAMM amm_,
        IERC20 collateralToken_
    )
        PositionManagerDependent(address(positionManager_))
    {
        if (address(amm_) == address(0)) {
            revert AmmCannotBeZero();
        }
        if (address(collateralToken_) == address(0)) {
            revert CollateralTokenCannotBeZero();
        }
        amm = amm_;
        collateralToken = collateralToken_;

        rToken = positionManager_.rToken();
        raftDebtToken = positionManager_.raftDebtToken(collateralToken);

        // We approve tokens here so we do not need to do approvals in particular actions.
        // Approved contracts are known, so this should be considered as safe.

        // No need to use safeApprove, IRToken is known token and is safe.
        rToken.approve(address(positionManager_.rToken()), type(uint256).max);
        collateralToken_.safeApprove(address(amm), type(uint256).max);
    }

    function liquidate(address position, bytes calldata ammData) external override {
        bytes memory data = abi.encode(msg.sender, position, ammData);
        rToken.flashLoan(this, address(rToken), raftDebtToken.balanceOf(position), data);
    }

    function onFlashLoan(
        address initiator,
        address,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    )
        external
        override
        returns (bytes32)
    {
        if (msg.sender != address(rToken)) {
            revert UnsupportedToken();
        }
        if (initiator != address(this)) {
            revert InvalidInitiator();
        }

        (address liquidator, address position, bytes memory ammData) = abi.decode(data, (address, address, bytes));

        IPositionManager(positionManager).liquidate(position);
        uint256 repayAmount = amount + fee;
        amm.swap(collateralToken, rToken, collateralToken.balanceOf(address(this)), repayAmount, ammData);
        rToken.transfer(liquidator, rToken.balanceOf(address(this)) - repayAmount);

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
}