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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IBasePool_v_1_1} from "./interfaces/IBasePool_v_1_1.sol";

abstract contract BasePool_v_1_1 is IBasePool_v_1_1 {
    using SafeERC20 for IERC20Metadata;

    error IdenticalLoanAndCollCcy();
    error InvalidZeroAddress();
    error InvalidLoanTenor();
    error InvalidMaxLoanPerColl();
    error InvalidRateParams();
    error InvalidLiquidityBnds();
    error InvalidMinLiquidity();
    error InvalidBaseAggrSize();
    error InvalidFee();
    error PastDeadline();
    error InvalidAddAmount();
    error BeforeEarliestRemove();
    error InsufficientLiquidity();
    error InvalidRemove();
    error LoanTooSmall();
    error LoanBelowLimit();
    error ErroneousLoanTerms();
    error RepaymentAboveLimit();
    error InvalidLoanIdx();
    error UnapprovedSender();
    error InvalidRecipient();
    error InvalidSubAggregation();
    error CannotRepayAfterExpiry();
    error AlreadyRepaid();
    error CannotRepayInSameBlock();
    error InvalidRollOver();
    error InvalidSendAmount();
    error NothingToClaim();
    error MustBeLp();
    error InvalidNewSharePointer();
    error UnentitledFromLoanIdx();
    error LoanIdxsWithChangingShares();
    error NonAscendingLoanIdxs();
    error CannotClaimWithUnsettledLoan();
    error InvalidApprovalAddress();
    error ZeroShareClaim();
    error Invalid();

    uint256 constant MIN_LPING_PERIOD = 120; // in seconds
    uint256 constant BASE = 10 ** 18;
    uint256 constant MAX_FEE = 500 * 10 ** 14; // 5%, denominated in BASE
    uint256 minLiquidity; // denominated in loanCcy decimals

    address public poolCreator;
    address poolCreatorProposal;
    address collCcyToken;
    address loanCcyToken;

    uint128 totalLpShares; // LP shares are denominated and discretized in 1/1000th of minLiquidity
    uint256 loanTenor; // in seconds
    uint256 collTokenDecimals;
    uint256 maxLoanPerColl; // denominated in loanCcy decimals
    uint256 public creatorFee; // denominated in BASE
    uint256 totalLiquidity; // denominated in loanCcy decimals
    uint256 loanIdx;
    uint256 r1; // denominated in BASE and w.r.t. tenor (i.e., not annualized)
    uint256 r2; // denominated in BASE and w.r.t. tenor (i.e., not annualized)
    uint256 liquidityBnd1; // denominated in loanCcy decimals
    uint256 liquidityBnd2; // denominated in loanCcy decimals
    uint256 minLoan; // denominated in loanCcy decimals
    uint256 baseAggrBucketSize; // must be a multiple of 100
    mapping(address => LpInfo) addrToLpInfo;
    mapping(address => uint256) lastAddOfTxOrigin;
    mapping(uint256 => LoanInfo) public loanIdxToLoanInfo;
    mapping(uint256 => address) public loanIdxToBorrower;
    mapping(address => bool) public lpWhitelist;

    mapping(address => mapping(address => mapping(IBasePool_v_1_1.ApprovalTypes => bool)))
        public isApproved;

    mapping(uint256 => AggClaimsInfo) collAndRepayTotalBaseAgg1;
    mapping(uint256 => AggClaimsInfo) collAndRepayTotalBaseAgg2;
    mapping(uint256 => AggClaimsInfo) collAndRepayTotalBaseAgg3;

    constructor(
        address _loanCcyToken,
        address _collCcyToken,
        uint256 _loanTenor,
        uint256 _maxLoanPerColl,
        uint256 _r1,
        uint256 _r2,
        uint256 _liquidityBnd1,
        uint256 _liquidityBnd2,
        uint256 _minLoan,
        uint256 _baseAggrBucketSize,
        uint256 _creatorFee,
        uint256 _minLiquidity
    ) {
        if (_collCcyToken == _loanCcyToken) revert IdenticalLoanAndCollCcy();
        if (_loanCcyToken == address(0) || _collCcyToken == address(0))
            revert InvalidZeroAddress();
        if (_loanTenor < 60 * 60) revert InvalidLoanTenor();
        if (_maxLoanPerColl == 0) revert InvalidMaxLoanPerColl();
        if (_r1 <= _r2 || _r2 == 0) revert InvalidRateParams();
        if (_liquidityBnd2 <= _liquidityBnd1 || _liquidityBnd1 == 0)
            revert InvalidLiquidityBnds();
        // ensure LP shares can be minted based on 1/1000th of minLp discretization
        if (_minLiquidity < 1000) revert InvalidMinLiquidity();
        if (_baseAggrBucketSize < 100 || _baseAggrBucketSize % 100 != 0)
            revert InvalidBaseAggrSize();
        if (_creatorFee > MAX_FEE) revert InvalidFee();
        poolCreator = msg.sender;
        loanCcyToken = _loanCcyToken;
        collCcyToken = _collCcyToken;
        loanTenor = _loanTenor;
        maxLoanPerColl = _maxLoanPerColl;
        r1 = _r1;
        r2 = _r2;
        liquidityBnd1 = _liquidityBnd1;
        liquidityBnd2 = _liquidityBnd2;
        minLoan = _minLoan;
        loanIdx = 1;
        collTokenDecimals = IERC20Metadata(_collCcyToken).decimals();
        baseAggrBucketSize = _baseAggrBucketSize;
        creatorFee = _creatorFee;
        minLiquidity = _minLiquidity;
        emit NewSubPool(
            _loanCcyToken,
            _collCcyToken,
            _loanTenor,
            _maxLoanPerColl,
            _r1,
            _r2,
            _liquidityBnd1,
            _liquidityBnd2,
            _minLoan,
            _creatorFee
        );
    }

    function addLiquidity(
        address _onBehalfOf,
        uint128 _sendAmount,
        uint256 _deadline,
        uint256 _referralCode
    ) external override {
        // verify LP info and eligibility
        if (!(msg.sender == _onBehalfOf && lpWhitelist[msg.sender])) {
            revert UnapprovedSender();
        }
        checkTimestamp(_deadline);

        uint128 _inAmountAfterFees = _sendAmount -
            getLoanCcyTransferFee(_sendAmount);

        (
            uint256 dust,
            uint256 newLpShares,
            uint32 earliestRemove
        ) = _addLiquidity(_onBehalfOf, _inAmountAfterFees);

        // transfer liquidity
        IERC20Metadata(loanCcyToken).safeTransferFrom(
            msg.sender,
            address(this),
            _sendAmount
        );

        // transfer dust to creator if any
        if (dust > 0) {
            IERC20Metadata(loanCcyToken).safeTransfer(poolCreator, dust);
        }
        // spawn event
        emit AddLiquidity(
            _onBehalfOf,
            _sendAmount,
            newLpShares,
            totalLiquidity,
            totalLpShares,
            earliestRemove,
            loanIdx,
            _referralCode
        );
    }

    // put in number of shares to remove, up to all of them
    function removeLiquidity(
        address _onBehalfOf,
        uint128 numShares
    ) external override {
        delete lastAddOfTxOrigin[_onBehalfOf];
        // verify LP info and eligibility
        checkSenderApproval(
            _onBehalfOf,
            IBasePool_v_1_1.ApprovalTypes.REMOVE_LIQUIDITY
        );

        LpInfo storage lpInfo = addrToLpInfo[_onBehalfOf];
        uint256 shareLength = lpInfo.sharesOverTime.length;
        if (
            shareLength * numShares == 0 ||
            lpInfo.sharesOverTime[shareLength - 1] < numShares
        ) revert InvalidRemove();
        if (block.timestamp < lpInfo.earliestRemove)
            revert BeforeEarliestRemove();
        uint256 _totalLiquidity = totalLiquidity;
        uint128 _totalLpShares = totalLpShares;
        // update state of pool
        uint256 liquidityRemoved = (numShares *
            (_totalLiquidity - minLiquidity)) / _totalLpShares;
        totalLpShares -= numShares;
        totalLiquidity = _totalLiquidity - liquidityRemoved;

        // update LP arrays and check for auto increment
        updateLpArrays(lpInfo, numShares, false);

        // transfer liquidity
        IERC20Metadata(loanCcyToken).safeTransfer(msg.sender, liquidityRemoved);
        // spawn event
        emit RemoveLiquidity(
            _onBehalfOf,
            liquidityRemoved,
            numShares,
            totalLiquidity,
            _totalLpShares - numShares,
            loanIdx
        );
    }

    function borrow(
        address _onBehalf,
        uint128 _sendAmount,
        uint128 _minLoanLimit,
        uint128 _maxRepayLimit,
        uint256 _deadline,
        uint256 _referralCode
    ) external override {
        uint256 _timestamp = checkTimestamp(_deadline);
        // check if atomic add and borrow as well as sanity check of onBehalf address
        if (
            lastAddOfTxOrigin[tx.origin] == _timestamp ||
            _onBehalf == address(0)
        ) revert Invalid();
        uint128 _inAmountAfterFees = _sendAmount -
            getCollCcyTransferFee(_sendAmount);
        // get borrow terms and do checks
        (
            uint128 loanAmount,
            uint128 repaymentAmount,
            uint128 pledgeAmount,
            uint32 expiry,
            uint256 _creatorFee,
            uint256 _totalLiquidity
        ) = _borrow(
                _inAmountAfterFees,
                _minLoanLimit,
                _maxRepayLimit,
                _timestamp
            );
        {
            // update pool state
            totalLiquidity = _totalLiquidity - loanAmount;

            uint256 _loanIdx = loanIdx;
            uint128 _totalLpShares = totalLpShares;

            // update loan info
            loanIdxToBorrower[_loanIdx] = _onBehalf;
            LoanInfo memory loanInfo;
            loanInfo.repayment = repaymentAmount;
            loanInfo.totalLpShares = _totalLpShares;
            loanInfo.expiry = expiry;
            loanInfo.collateral = pledgeAmount;
            loanIdxToLoanInfo[_loanIdx] = loanInfo;

            // update aggregations
            updateAggregations(
                _loanIdx,
                pledgeAmount,
                0,
                _totalLpShares,
                false
            );

            // update loan idx counter
            loanIdx = _loanIdx + 1;
        }
        {
            // transfer _sendAmount (not pledgeAmount) in collateral ccy
            IERC20Metadata(collCcyToken).safeTransferFrom(
                msg.sender,
                address(this),
                _sendAmount
            );

            // transfer creator fee to creator in collateral ccy
            IERC20Metadata(collCcyToken).safeTransfer(poolCreator, _creatorFee);

            // transfer loanAmount in loan ccy
            IERC20Metadata(loanCcyToken).safeTransfer(msg.sender, loanAmount);
        }
        // spawn event
        emit Borrow(
            _onBehalf,
            loanIdx - 1,
            pledgeAmount,
            loanAmount,
            repaymentAmount,
            totalLpShares,
            expiry,
            _referralCode
        );
    }

    function repay(
        uint256 _loanIdx,
        address _recipient,
        uint128 _sendAmount
    ) external override {
        // verify loan info and eligibility
        if (_loanIdx == 0 || _loanIdx >= loanIdx) revert InvalidLoanIdx();
        address _loanOwner = loanIdxToBorrower[_loanIdx];

        if (!(_loanOwner == _recipient || msg.sender == _recipient))
            revert InvalidRecipient();
        checkSenderApproval(_loanOwner, IBasePool_v_1_1.ApprovalTypes.REPAY);
        LoanInfo storage loanInfo = loanIdxToLoanInfo[_loanIdx];
        uint256 timestamp = block.timestamp;
        if (timestamp > loanInfo.expiry) revert CannotRepayAfterExpiry();
        if (loanInfo.repaid) revert AlreadyRepaid();
        if (timestamp == loanInfo.expiry - loanTenor)
            revert CannotRepayInSameBlock();
        // update loan info
        loanInfo.repaid = true;
        uint128 _repayment = loanInfo.repayment;

        // transfer repayment amount
        uint128 repaymentAmountAfterFees = checkAndGetSendAmountAfterFees(
            _sendAmount,
            _repayment
        );
        // if repaymentAmountAfterFees was larger then update loan info
        // this ensures the extra repayment goes to the LPs
        if (repaymentAmountAfterFees != _repayment) {
            loanInfo.repayment = repaymentAmountAfterFees;
        }
        uint128 _collateral = loanInfo.collateral;
        uint128 _totalLpShares = loanInfo.totalLpShares;
        // update the aggregation mappings
        updateAggregations(
            _loanIdx,
            _collateral,
            repaymentAmountAfterFees,
            _totalLpShares,
            true
        );

        IERC20Metadata(loanCcyToken).safeTransferFrom(
            msg.sender,
            address(this),
            _sendAmount
        );
        // transfer collateral to _recipient (allows for possible
        // transfer directly to someone other than payer/sender)
        IERC20Metadata(collCcyToken).safeTransfer(_recipient, _collateral);
        // spawn event
        emit Repay(_loanOwner, _loanIdx, repaymentAmountAfterFees);
    }

    function claim(
        address _onBehalfOf,
        uint256[] calldata _loanIdxs,
        bool _isReinvested,
        uint256 _deadline
    ) external override {
        // check if reinvested is chosen that deadline is valid and sender can add liquidity on behalf of
        if (_isReinvested) {
            claimReinvestmentCheck(_deadline, _onBehalfOf);
        }
        checkSenderApproval(_onBehalfOf, IBasePool_v_1_1.ApprovalTypes.CLAIM);
        LpInfo storage lpInfo = addrToLpInfo[_onBehalfOf];

        // verify LP info and eligibility
        uint256 loanIdxsLen = _loanIdxs.length;
        // length of sharesOverTime array for LP
        uint256 sharesOverTimeLen = lpInfo.sharesOverTime.length;
        if (loanIdxsLen * sharesOverTimeLen == 0) revert NothingToClaim();
        if (_loanIdxs[0] == 0) revert InvalidLoanIdx();

        (
            uint256 sharesUnchangedUntilLoanIdx,
            uint256 applicableShares
        ) = claimsChecksAndSetters(
                _loanIdxs[0],
                _loanIdxs[loanIdxsLen - 1],
                lpInfo
            );

        // iterate over loans to get claimable amounts
        (uint256 repayments, uint256 collateral) = getClaimsFromList(
            _loanIdxs,
            loanIdxsLen,
            applicableShares
        );

        // update LP's from loan index to prevent double claiming and check share pointer
        checkSharePtrIncrement(
            lpInfo,
            _loanIdxs[loanIdxsLen - 1],
            lpInfo.currSharePtr,
            sharesUnchangedUntilLoanIdx
        );

        claimTransferAndReinvestment(
            _onBehalfOf,
            repayments,
            collateral,
            _isReinvested
        );

        // spawn event
        emit Claim(_onBehalfOf, _loanIdxs, repayments, collateral);
    }

    function overrideSharePointer(uint256 _newSharePointer) external {
        LpInfo storage lpInfo = addrToLpInfo[msg.sender];
        if (lpInfo.fromLoanIdx == 0) revert MustBeLp();
        // check that passed in pointer is greater than current share pointer
        // and less than length of LP's shares over time array
        if (
            _newSharePointer <= lpInfo.currSharePtr ||
            _newSharePointer + 1 > lpInfo.sharesOverTime.length
        ) revert InvalidNewSharePointer();
        lpInfo.currSharePtr = uint32(_newSharePointer);
        lpInfo.fromLoanIdx = uint32(
            lpInfo.loanIdxsWhereSharesChanged[_newSharePointer - 1]
        );
    }

    function claimFromAggregated(
        address _onBehalfOf,
        uint256[] calldata _aggIdxs,
        bool _isReinvested,
        uint256 _deadline
    ) external override {
        // check if reinvested is chosen that deadline is valid and sender can add liquidity on behalf of
        if (_isReinvested) {
            claimReinvestmentCheck(_deadline, _onBehalfOf);
        }
        checkSenderApproval(_onBehalfOf, IBasePool_v_1_1.ApprovalTypes.CLAIM);
        LpInfo storage lpInfo = addrToLpInfo[_onBehalfOf];

        // verify LP info and eligibility
        // length of loanIdxs array LP wants to claim
        uint256 lengthArr = _aggIdxs.length;
        // checks if length loanIds passed in is less than 2 (hence does not make even one valid claim interval)
        // OR if sharesOverTime array is empty.
        if (lpInfo.sharesOverTime.length == 0 || lengthArr < 2)
            revert NothingToClaim();

        (
            uint256 sharesUnchangedUntilLoanIdx,
            uint256 applicableShares
        ) = claimsChecksAndSetters(
                _aggIdxs[0],
                _aggIdxs[lengthArr - 1] - 1,
                lpInfo
            );

        // local variables to track repayments and collateral claimed
        uint256 totalRepayments;
        uint256 totalCollateral;

        // local variables for each iteration's repayments and collateral
        uint256 repayments;
        uint256 collateral;

        // iterate over the length of the passed in array
        for (uint256 counter = 0; counter < lengthArr - 1; ) {
            // make sure input loan indices are strictly increasing
            if (_aggIdxs[counter] >= _aggIdxs[counter + 1])
                revert NonAscendingLoanIdxs();

            // get aggregated claims
            (repayments, collateral) = getClaimsFromAggregated(
                _aggIdxs[counter],
                _aggIdxs[counter + 1],
                applicableShares
            );
            // update total repayment amount and total collateral amount
            totalRepayments += repayments;
            totalCollateral += collateral;

            unchecked {
                //increment local counter
                counter++;
            }
        }

        // update LP's from loan index to prevent double claiming and check share pointer
        checkSharePtrIncrement(
            lpInfo,
            _aggIdxs[lengthArr - 1] - 1,
            lpInfo.currSharePtr,
            sharesUnchangedUntilLoanIdx
        );

        claimTransferAndReinvestment(
            _onBehalfOf,
            totalRepayments,
            totalCollateral,
            _isReinvested
        );
        // spawn event
        emit ClaimFromAggregated(
            _onBehalfOf,
            _aggIdxs[0],
            _aggIdxs[lengthArr - 1],
            totalRepayments,
            totalCollateral
        );
    }

    function setApprovals(
        address _approvee,
        uint256 _packedApprovals
    ) external {
        if (msg.sender == _approvee || _approvee == address(0))
            revert InvalidApprovalAddress();
        _packedApprovals &= 0x1f;
        for (uint256 index = 0; index < 5; ) {
            bool approvalFlag = ((_packedApprovals >> index) & uint256(1)) == 1;
            if (
                isApproved[msg.sender][_approvee][
                    IBasePool_v_1_1.ApprovalTypes(index)
                ] != approvalFlag
            ) {
                isApproved[msg.sender][_approvee][
                    IBasePool_v_1_1.ApprovalTypes(index)
                ] = approvalFlag;
                _packedApprovals |= uint256(1) << 5;
            }
            unchecked {
                index++;
            }
        }
        if (((_packedApprovals >> 5) & uint256(1)) == 1) {
            emit ApprovalUpdate(msg.sender, _approvee, _packedApprovals & 0x1f);
        }
    }

    function proposeNewCreator(address newAddr) external {
        if (msg.sender != poolCreator) {
            revert UnapprovedSender();
        }
        poolCreatorProposal = newAddr;
    }

    function claimCreator() external {
        if (msg.sender != poolCreatorProposal) {
            revert UnapprovedSender();
        }
        address prevPoolCreator = poolCreator;
        lpWhitelist[prevPoolCreator] = false;
        lpWhitelist[msg.sender] = true;
        poolCreator = msg.sender;
        emit LpWhitelistUpdate(prevPoolCreator, false);
        emit LpWhitelistUpdate(msg.sender, true);
    }

    function toggleLpWhitelist(address newAddr) external {
        if (msg.sender != poolCreator) {
            revert UnapprovedSender();
        }
        bool newIsApproved = !lpWhitelist[newAddr];
        lpWhitelist[newAddr] = newIsApproved;
        emit LpWhitelistUpdate(newAddr, newIsApproved);
    }

    function getLpInfo(
        address _lpAddr
    )
        external
        view
        returns (
            uint32 fromLoanIdx,
            uint32 earliestRemove,
            uint32 currSharePtr,
            uint256[] memory sharesOverTime,
            uint256[] memory loanIdxsWhereSharesChanged
        )
    {
        LpInfo memory lpInfo = addrToLpInfo[_lpAddr];
        fromLoanIdx = lpInfo.fromLoanIdx;
        earliestRemove = lpInfo.earliestRemove;
        currSharePtr = lpInfo.currSharePtr;
        sharesOverTime = lpInfo.sharesOverTime;
        loanIdxsWhereSharesChanged = lpInfo.loanIdxsWhereSharesChanged;
    }

    function getRateParams()
        external
        view
        returns (
            uint256 _liquidityBnd1,
            uint256 _liquidityBnd2,
            uint256 _r1,
            uint256 _r2
        )
    {
        _liquidityBnd1 = liquidityBnd1;
        _liquidityBnd2 = liquidityBnd2;
        _r1 = r1;
        _r2 = r2;
    }

    function getPoolInfo()
        external
        view
        returns (
            address _loanCcyToken,
            address _collCcyToken,
            uint256 _maxLoanPerColl,
            uint256 _minLoan,
            uint256 _loanTenor,
            uint256 _totalLiquidity,
            uint256 _totalLpShares,
            uint256 _baseAggrBucketSize,
            uint256 _loanIdx
        )
    {
        _loanCcyToken = loanCcyToken;
        _collCcyToken = collCcyToken;
        _maxLoanPerColl = maxLoanPerColl;
        _minLoan = minLoan;
        _loanTenor = loanTenor;
        _totalLiquidity = totalLiquidity;
        _totalLpShares = totalLpShares;
        _baseAggrBucketSize = baseAggrBucketSize;
        _loanIdx = loanIdx;
    }

    function loanTerms(
        uint128 _inAmountAfterFees
    )
        public
        view
        returns (
            uint128 loanAmount,
            uint128 repaymentAmount,
            uint128 pledgeAmount,
            uint256 _creatorFee,
            uint256 _totalLiquidity
        )
    {
        // compute terms (as uint256)
        _creatorFee = (_inAmountAfterFees * creatorFee) / BASE;
        uint256 pledge = _inAmountAfterFees - _creatorFee;
        _totalLiquidity = totalLiquidity;
        if (_totalLiquidity <= minLiquidity) revert InsufficientLiquidity();
        uint256 loan = (pledge * maxLoanPerColl) / 10 ** collTokenDecimals;
        uint256 L_k = ((_totalLiquidity - minLiquidity) * BASE * 9) /
            (BASE * 10);
        if (loan > L_k) {
            uint256 x_k = (L_k * 10 ** collTokenDecimals) / maxLoanPerColl;
            loan =
                ((pledge - x_k) *
                    maxLoanPerColl *
                    (_totalLiquidity - minLiquidity - L_k)) /
                ((pledge - x_k) *
                    maxLoanPerColl +
                    (_totalLiquidity - minLiquidity - L_k) *
                    10 ** collTokenDecimals) +
                L_k;
        }

        if (loan < minLoan) revert LoanTooSmall();
        uint256 postLiquidity = _totalLiquidity - loan;
        assert(postLiquidity >= minLiquidity);
        // we use the average rate to calculate the repayment amount
        uint256 avgRate = (getRate(_totalLiquidity) + getRate(postLiquidity)) /
            2;
        // if pre- and post-borrow liquidity are within target liquidity range
        // then the repayment amount exactly matches the amount of integrating the
        // loan size over the infinitesimal rate; else the repayment amount is
        // larger than the amount of integrating loan size over rate;
        uint256 repayment = (loan * (BASE + avgRate)) / BASE;
        // return terms (as uint128)
        assert(uint128(loan) == loan);
        loanAmount = uint128(loan);
        assert(uint128(repayment) == repayment);
        repaymentAmount = uint128(repayment);
        assert(uint128(pledge) == pledge);
        pledgeAmount = uint128(pledge);
        if (repaymentAmount <= loanAmount) revert ErroneousLoanTerms();
    }

    function getClaimsFromAggregated(
        uint256 _fromLoanIdx,
        uint256 _toLoanIdx,
        uint256 _shares
    ) public view returns (uint256 repayments, uint256 collateral) {
        uint256 fromToDiff = _toLoanIdx - _fromLoanIdx;
        uint256 _baseAggrBucketSize = baseAggrBucketSize;
        // expiry check to make sure last loan in aggregation (one prior to _toLoanIdx for bucket) was taken out and expired
        uint32 expiryCheck = loanIdxToLoanInfo[_toLoanIdx - 1].expiry;
        if (expiryCheck == 0 || expiryCheck + 1 > block.timestamp) {
            revert InvalidSubAggregation();
        }
        AggClaimsInfo memory aggClaimsInfo;
        // find which bucket to which the current aggregation belongs and get aggClaimsInfo
        if (
            _toLoanIdx % _baseAggrBucketSize == 0 &&
            fromToDiff == _baseAggrBucketSize
        ) {
            aggClaimsInfo = collAndRepayTotalBaseAgg1[
                _fromLoanIdx / _baseAggrBucketSize + 1
            ];
        } else if (
            _toLoanIdx % (10 * _baseAggrBucketSize) == 0 &&
            fromToDiff == _baseAggrBucketSize * 10
        ) {
            aggClaimsInfo = collAndRepayTotalBaseAgg2[
                (_fromLoanIdx / (_baseAggrBucketSize * 10)) + 1
            ];
        } else if (
            _toLoanIdx % (100 * _baseAggrBucketSize) == 0 &&
            fromToDiff == _baseAggrBucketSize * 100
        ) {
            aggClaimsInfo = collAndRepayTotalBaseAgg3[
                (_fromLoanIdx / (_baseAggrBucketSize * 100)) + 1
            ];
        } else {
            revert InvalidSubAggregation();
        }

        // return repayment and collateral amounts
        repayments = (aggClaimsInfo.repayments * _shares) / BASE;
        collateral = (aggClaimsInfo.collateral * _shares) / BASE;
    }

    /**
     * @notice Function which updates the 3 aggegration levels when claiming
     * @dev This function will subtract collateral and add to repay if _isRepay is true.
     * Otherwise, repayment will be unchanged and collateral will be added
     * @param _loanIdx Loan index used to determine aggregation "bucket" index
     * @param _collateral Amount of collateral to add/subtract from aggregations
     * @param _repayment Amount of loan currency to add to repayments, only if _isRepay is true
     * @param _totalLpShares Amount of LP Shares for given loan, used to divide amounts into units per LP share
     * @param _isRepay Flag which if false only allows adding collateral else subtracts collateral and adds repayments
     */
    function updateAggregations(
        uint256 _loanIdx,
        uint128 _collateral,
        uint128 _repayment,
        uint128 _totalLpShares,
        bool _isRepay
    ) internal {
        uint256 _baseAggFirstIndex = _loanIdx / baseAggrBucketSize + 1;
        uint256 _baseAggSecondIndex = ((_baseAggFirstIndex - 1) / 10) + 1;
        uint256 _baseAggThirdIndex = ((_baseAggFirstIndex - 1) / 100) + 1;

        uint128 collateralUpdate = uint128(
            (_collateral * BASE) / _totalLpShares
        );
        uint128 repaymentUpdate = uint128((_repayment * BASE) / _totalLpShares);

        if (_isRepay) {
            collAndRepayTotalBaseAgg1[_baseAggFirstIndex]
                .collateral -= collateralUpdate;
            collAndRepayTotalBaseAgg2[_baseAggSecondIndex]
                .collateral -= collateralUpdate;
            collAndRepayTotalBaseAgg3[_baseAggThirdIndex]
                .collateral -= collateralUpdate;
            collAndRepayTotalBaseAgg1[_baseAggFirstIndex]
                .repayments += repaymentUpdate;
            collAndRepayTotalBaseAgg2[_baseAggSecondIndex]
                .repayments += repaymentUpdate;
            collAndRepayTotalBaseAgg3[_baseAggThirdIndex]
                .repayments += repaymentUpdate;
        } else {
            collAndRepayTotalBaseAgg1[_baseAggFirstIndex]
                .collateral += collateralUpdate;
            collAndRepayTotalBaseAgg2[_baseAggSecondIndex]
                .collateral += collateralUpdate;
            collAndRepayTotalBaseAgg3[_baseAggThirdIndex]
                .collateral += collateralUpdate;
        }
    }

    /**
     * @notice Function which updates from index and checks if share pointer should be incremented
     * @dev This function will update new from index for LP to last claimed id + 1. If the current
     * share pointer is not at the end of the LP's shares over time array, and if the new from index
     * is equivalent to the index where shares were then added/removed by LP, then increment share pointer.
     * @param _lpInfo Storage struct of LpInfo passed into function
     * @param _lastIdxFromUserInput Last claimable index passed by user into claims
     * @param _currSharePtr Current pointer for shares over time array for LP
     * @param _sharesUnchangedUntilLoanIdx Loan index where the number of shares owned by LP changed.
     */
    function checkSharePtrIncrement(
        LpInfo storage _lpInfo,
        uint256 _lastIdxFromUserInput,
        uint256 _currSharePtr,
        uint256 _sharesUnchangedUntilLoanIdx
    ) internal {
        // update LPs from loan index
        _lpInfo.fromLoanIdx = uint32(_lastIdxFromUserInput) + 1;
        // if current share pointer is not already at end and
        // the last loan claimed was exactly one below the currentToLoanIdx
        // then increment the current share pointer
        if (
            _currSharePtr < _lpInfo.sharesOverTime.length - 1 &&
            _lastIdxFromUserInput + 1 == _sharesUnchangedUntilLoanIdx
        ) {
            unchecked {
                _lpInfo.currSharePtr++;
            }
        }
    }

    /**
     * @notice Function which performs check and possibly updates lpInfo when claiming
     * @dev This function will update first check if the current share pointer for the LP
     * is pointing to a zero value. In that case, pointer will be incremented (since pointless to claim for
     * zero shares) and fromLoanIdx is then updated accordingly from LP's loanIdxWhereSharesChanged array.
     * Other checks are then performed to make sure that LP is entitled to claim from indices sent in.
     * @param _startIndex Start index sent in by user when claiming
     * @param _endIndex Last claimable index passed by user into claims
     * @param _lpInfo Current LpInfo struct passed in as storage
     * @return _sharesUnchangedUntilLoanIdx The index up to which the LP did not change shares
     * @return _applicableShares The number of shares to use in the claiming calculation
     */
    function claimsChecksAndSetters(
        uint256 _startIndex,
        uint256 _endIndex,
        LpInfo storage _lpInfo
    )
        internal
        returns (
            uint256 _sharesUnchangedUntilLoanIdx,
            uint256 _applicableShares
        )
    {
        /*
         * check if reasonable to automatically increment share pointer for intermediate period with zero shares
         * and push fromLoanIdx forward
         * Note: Since there is an offset of length 1 for the sharesOverTime and loanIdxWhereSharesChanged
         * this is why the fromLoanIdx needs to be updated before the current share pointer increments
         **/
        uint256 currSharePtr = _lpInfo.currSharePtr;
        if (_lpInfo.sharesOverTime[currSharePtr] == 0) {
            // if share ptr at end of shares over time array, then LP still has 0 shares and should revert right away
            if (currSharePtr == _lpInfo.sharesOverTime.length - 1)
                revert ZeroShareClaim();
            _lpInfo.fromLoanIdx = uint32(
                _lpInfo.loanIdxsWhereSharesChanged[currSharePtr]
            );
            unchecked {
                currSharePtr = ++_lpInfo.currSharePtr;
            }
        }

        /*
         * first loan index (which is what _fromLoanIdx will become)
         * cannot be less than lpInfo.fromLoanIdx (double-claiming or not entitled since
         * wasn't invested during that time), unless special case of first loan globally
         * and LpInfo.fromLoanIdx is 1
         * Note: This still works for claim, since in that function startIndex !=0 is already
         * checked, so second part is always true in claim function
         **/
        if (
            _startIndex < _lpInfo.fromLoanIdx &&
            !(_startIndex == 0 && _lpInfo.fromLoanIdx == 1)
        ) revert UnentitledFromLoanIdx();

        // infer applicable upper loan idx for which number of shares didn't change
        _sharesUnchangedUntilLoanIdx = currSharePtr ==
            _lpInfo.sharesOverTime.length - 1
            ? loanIdx
            : _lpInfo.loanIdxsWhereSharesChanged[currSharePtr];

        // check passed last loan idx is consistent with constant share interval
        if (_endIndex >= _sharesUnchangedUntilLoanIdx)
            revert LoanIdxsWithChangingShares();

        // get applicable number of shares for pro-rata calculations (given current share pointer position)
        _applicableShares = _lpInfo.sharesOverTime[currSharePtr];
    }

    /**
     * @notice Function which transfers collateral and repayments of claims and reinvests
     * @dev This function will reinvest the loan currency only (and only of course if _isReinvested is true)
     * @param _onBehalfOf LP address which is owner or has approved sender to claim on their behalf (and possibly reinvest)
     * @param _repayments Total repayments (loan currency) after all claims processed
     * @param _collateral Total collateral (collateral currency) after all claims processed
     * @param _isReinvested Flag for if LP wants claimed loanCcy to be re-invested
     */
    function claimTransferAndReinvestment(
        address _onBehalfOf,
        uint256 _repayments,
        uint256 _collateral,
        bool _isReinvested
    ) internal {
        if (_repayments > 0) {
            if (_isReinvested) {
                // allows reinvestment and transfer of any dust from claim functions
                (
                    uint256 dust,
                    uint256 newLpShares,
                    uint32 earliestRemove
                ) = _addLiquidity(_onBehalfOf, _repayments);
                if (dust > 0) {
                    IERC20Metadata(loanCcyToken).safeTransfer(
                        poolCreator,
                        dust
                    );
                }
                // spawn event
                emit Reinvest(
                    _onBehalfOf,
                    _repayments,
                    newLpShares,
                    earliestRemove,
                    loanIdx
                );
            } else {
                IERC20Metadata(loanCcyToken).safeTransfer(
                    msg.sender,
                    _repayments
                );
            }
        }
        // transfer collateral
        if (_collateral > 0) {
            IERC20Metadata(collCcyToken).safeTransfer(msg.sender, _collateral);
        }
    }

    /**
     * @notice Helper function when adding liquidity
     * @dev This function is called by addLiquidity, but also
     * by claimants who would like to reinvest their loanCcy
     * portion of the claim
     * @param _onBehalfOf Recipient of the LP shares
     * @param _inAmountAfterFees Net amount of what was sent by LP minus fees
     * @return dust If no LP shares, dust is any remaining excess liquidity (i.e. minLiquidity and rounding)
     * @return newLpShares Amount of new LP shares to be credited to LP.
     * @return earliestRemove Earliest timestamp from which LP is allowed to remove liquidity
     */
    function _addLiquidity(
        address _onBehalfOf,
        uint256 _inAmountAfterFees
    )
        internal
        returns (uint256 dust, uint256 newLpShares, uint32 earliestRemove)
    {
        uint256 _totalLiquidity = totalLiquidity;
        if (_inAmountAfterFees < minLiquidity / 1000) revert InvalidAddAmount();
        // retrieve lpInfo of sender
        LpInfo storage lpInfo = addrToLpInfo[_onBehalfOf];

        // calculate new lp shares
        if (totalLpShares == 0) {
            dust = _totalLiquidity;
            _totalLiquidity = 0;
            newLpShares = (_inAmountAfterFees * 1000) / minLiquidity;
        } else {
            assert(_totalLiquidity > 0);
            newLpShares =
                (_inAmountAfterFees * totalLpShares) /
                _totalLiquidity;
        }
        if (newLpShares == 0 || uint128(newLpShares) != newLpShares)
            revert InvalidAddAmount();
        totalLpShares += uint128(newLpShares);
        totalLiquidity = _totalLiquidity + _inAmountAfterFees;
        // update LP info
        bool isFirstAddLiquidity = lpInfo.fromLoanIdx == 0;
        if (isFirstAddLiquidity) {
            lpInfo.fromLoanIdx = uint32(loanIdx);
            lpInfo.sharesOverTime.push(newLpShares);
        } else {
            // update both LP arrays and check for auto increment
            updateLpArrays(lpInfo, newLpShares, true);
        }
        earliestRemove = uint32(block.timestamp + MIN_LPING_PERIOD);
        lpInfo.earliestRemove = earliestRemove;
        // keep track of add timestamp per tx origin to check for atomic add and borrows/rollOvers
        lastAddOfTxOrigin[tx.origin] = block.timestamp;
    }

    /**
     * @notice Function which updates array (and possibly array pointer) info
     * @dev There are many different cases depending on if shares over time is length 1,
     * if the LP fromLoanId = loanIdx, if last value of loanIdxsWhereSharesChanged = loanIdx,
     * and possibly on the value of the penultimate shares over time array = newShares...
     * further discussion of all cases is provided in gitbook documentation
     * @param _lpInfo Struct of the info for the current LP
     * @param _newLpShares Amount of new LP shares to add/remove from current LP position
     * @param _add Flag that allows for addition of shares for addLiquidity and subtraction for remove.
     */
    function updateLpArrays(
        LpInfo storage _lpInfo,
        uint256 _newLpShares,
        bool _add
    ) internal {
        uint256 _loanIdx = loanIdx;
        uint256 _originalSharesLen = _lpInfo.sharesOverTime.length;
        uint256 _originalLoanIdxsLen = _originalSharesLen - 1;
        uint256 currShares = _lpInfo.sharesOverTime[_originalSharesLen - 1];
        uint256 newShares = _add
            ? currShares + _newLpShares
            : currShares - _newLpShares;
        bool loanCheck = (_originalLoanIdxsLen > 0 &&
            _lpInfo.loanIdxsWhereSharesChanged[_originalLoanIdxsLen - 1] ==
            _loanIdx);
        // if LP has claimed all possible loans that were taken out (fromLoanIdx = loanIdx)
        if (_lpInfo.fromLoanIdx == _loanIdx) {
            /**
                if shares length has one value, OR
                if loanIdxsWhereSharesChanged array is non empty
                and the last value of the array is equal to current loanId
                then we go ahead and overwrite the lastShares array.
                We do not have to worry about popping array in second case
                because since fromLoanIdx == loanIdx, we know currSharePtr is
                already at end of the array, and therefore can never get stuck
            */
            if (_originalSharesLen == 1 || loanCheck) {
                _lpInfo.sharesOverTime[_originalSharesLen - 1] = newShares;
            }
            /**
            if loanIdxsWhereSharesChanged array is non empty
            and the last value of the array is NOT equal to current loanId
            then we go ahead and push a new value onto both arrays and increment currSharePtr
            we can safely increment share pointer because we know if fromLoanIdx is == loanIdx
            then currSharePtr has to already be length of original shares over time array - 1 and
            we want to keep it at end of the array 
            */
            else {
                pushLpArrays(_lpInfo, newShares, _loanIdx);
                unchecked {
                    _lpInfo.currSharePtr++;
                }
            }
        }
        /**
            fromLoanIdx is NOT equal to loanIdx in this case, but
            loanIdxsWhereSharesChanged array is non empty
            and the last value of the array is equal to current loanId.        
        */
        else if (loanCheck) {
            /**
                The value in the shares array before the last array
                In this case we are going to pop off the last values.
                Since we know that if currSharePtr was at end of array and loan id is still equal to last value
                on the loanIdxsWhereSharesUnchanged array, this would have meant that fromLoanIdx == loanIdx
                and hence, no need to check if currSharePtr needs to decrement
            */
            if (_lpInfo.sharesOverTime[_originalSharesLen - 2] == newShares) {
                _lpInfo.sharesOverTime.pop();
                _lpInfo.loanIdxsWhereSharesChanged.pop();
            }
            // if next to last shares over time value is not same as newShares,
            // then just overwrite last share value
            else {
                _lpInfo.sharesOverTime[_originalSharesLen - 1] = newShares;
            }
        } else {
            // if the previous conditions are not met then push newShares onto shares over time array
            // and push global loan index onto loanIdxsWhereSharesChanged
            pushLpArrays(_lpInfo, newShares, _loanIdx);
        }
    }

    /**
     * @notice Helper function that pushes onto both LP Info arrays
     * @dev This function is called by updateLpArrays function in two cases when both
     * LP Info arrays, sharesOverTime and loanIdxsWhereSharesChanged, are pushed onto
     * @param _lpInfo Struct of the info for the current LP
     * @param _newShares New amount of LP shares pushed onto sharesOverTime array
     * @param _loanIdx Current global loanIdx pushed onto loanIdxsWhereSharesChanged array
     */
    function pushLpArrays(
        LpInfo storage _lpInfo,
        uint256 _newShares,
        uint256 _loanIdx
    ) internal {
        _lpInfo.sharesOverTime.push(_newShares);
        _lpInfo.loanIdxsWhereSharesChanged.push(_loanIdx);
    }

    /**
     * @notice Helper function when user is borrowing
     * @dev This function is called by borrow and rollover
     * @param _inAmountAfterFees Net amount of what was sent by borrower minus fees
     * @param _minLoanLimit Minimum loan currency amount acceptable to borrower
     * @param _maxRepayLimit Maximum allowable loan currency amount borrower is willing to repay
     * @param _timestamp Time that is used to set loan expiry
     * @return loanAmount Amount of loan Ccy given to the borrower
     * @return repaymentAmount Amount of loan Ccy borrower needs to repay to claim collateral
     * @return pledgeAmount Amount of collCcy reclaimable upon repayment
     * @return expiry Timestamp after which loan expires
     * @return _creatorFee Per transaction fee which levied for using the protocol
     * @return _totalLiquidity Updated total liquidity (pre-borrow)
     */
    function _borrow(
        uint128 _inAmountAfterFees,
        uint128 _minLoanLimit,
        uint128 _maxRepayLimit,
        uint256 _timestamp
    )
        internal
        view
        returns (
            uint128 loanAmount,
            uint128 repaymentAmount,
            uint128 pledgeAmount,
            uint32 expiry,
            uint256 _creatorFee,
            uint256 _totalLiquidity
        )
    {
        // get and verify loan terms
        (
            loanAmount,
            repaymentAmount,
            pledgeAmount,
            _creatorFee,
            _totalLiquidity
        ) = loanTerms(_inAmountAfterFees);
        assert(_inAmountAfterFees != 0); // if 0 must have failed in loanTerms(...)
        if (loanAmount < _minLoanLimit) revert LoanBelowLimit();
        if (repaymentAmount > _maxRepayLimit) revert RepaymentAboveLimit();
        expiry = uint32(_timestamp + loanTenor);
    }

    /**
     * @notice Helper function called whenever a function needs to check a deadline
     * @dev This function is called by addLiquidity, borrow, rollover, and if reinvestment on claiming,
     * it will be called by claimReinvestmentCheck
     * @param _deadline Last timestamp after which function will revert
     * @return timestamp Current timestamp passed back to function
     */
    function checkTimestamp(
        uint256 _deadline
    ) internal view returns (uint256 timestamp) {
        timestamp = block.timestamp;
        if (timestamp > _deadline) revert PastDeadline();
    }

    /**
     * @notice Helper function called whenever reinvestment is possible
     * @dev This function is called by claim and claimFromAggregated if reinvestment is desired
     * @param _deadline Last timestamp after which function will revert
     */
    function claimReinvestmentCheck(
        uint256 _deadline,
        address /*_onBehalfOf*/
    ) internal view {
        checkTimestamp(_deadline);
    }

    /**
     * @notice Helper function checks if function caller is a valid sender
     * @dev This function is called by addLiquidity, removeLiquidity, repay,
     * rollOver, claim, claimFromAggregated, claimReinvestmentCheck
     * @param _ownerOrBeneficiary Address which will be owner or beneficiary of transaction if approved
     * @param _approvalType Type of approval requested { REPAY, ROLLOVER, REMOVE_LIQUIDITY, CLAIM }
     */
    function checkSenderApproval(
        address _ownerOrBeneficiary,
        IBasePool_v_1_1.ApprovalTypes _approvalType
    ) internal view {
        if (
            !(_ownerOrBeneficiary == msg.sender ||
                isApproved[_ownerOrBeneficiary][msg.sender][_approvalType])
        ) revert UnapprovedSender();
    }

    /**
     * @notice Helper function used by claim function
     * @dev This function is called by claim to check the passed array
     * is valid and return the repayment and collateral amounts
     * @param _loanIdxs Array of loan Idxs over which the LP would like to claim
     * @param arrayLen Length of the loanIdxs array
     * @param _shares The LP shares owned by the LP during the period of the claims
     * @return repayments The amount of loanCcy over claims to which LP is entitled
     * @return collateral The amount of collCcy over claims to which LP is entitled
     */
    function getClaimsFromList(
        uint256[] calldata _loanIdxs,
        uint256 arrayLen,
        uint256 _shares
    ) internal view returns (uint256 repayments, uint256 collateral) {
        // aggregate claims from list
        for (uint256 i = 0; i < arrayLen; ) {
            LoanInfo memory loanInfo = loanIdxToLoanInfo[_loanIdxs[i]];
            if (i > 0) {
                if (_loanIdxs[i] <= _loanIdxs[i - 1])
                    revert NonAscendingLoanIdxs();
            }
            if (loanInfo.repaid) {
                repayments +=
                    (loanInfo.repayment * BASE) /
                    loanInfo.totalLpShares;
            } else if (loanInfo.expiry < block.timestamp) {
                collateral +=
                    (loanInfo.collateral * BASE) /
                    loanInfo.totalLpShares;
            } else {
                revert CannotClaimWithUnsettledLoan();
            }
            unchecked {
                i++;
            }
        }
        // return claims
        repayments = (repayments * _shares) / BASE;
        collateral = (collateral * _shares) / BASE;
    }

    /**
     * @notice Function that returns the pool's rate given _liquidity to calculate
     * a loan's repayment amount.
     * @dev The rate is defined as a piecewise function with 3 ranges:
     * (1) low liquidity range: here the rate is defined as a reciprocal function
     * (2) target liquidity range: here the rate is linear
     * (3) high liquidity range: here the rate is constant
     * @param _liquidity The liquidity level for which the rate shall be calculated
     * @return rate The applicable rate
     */
    function getRate(uint256 _liquidity) internal view returns (uint256 rate) {
        if (_liquidity < liquidityBnd1) {
            rate = (r1 * liquidityBnd1) / _liquidity;
        } else if (_liquidity <= liquidityBnd2) {
            rate =
                r2 +
                ((r1 - r2) * (liquidityBnd2 - _liquidity)) /
                (liquidityBnd2 - liquidityBnd1);
        } else {
            rate = r2;
        }
    }

    /**
     * @notice Function which checks and returns loan ccy send amount after fees
     * @param _sendAmount Amount of loanCcy to be transferred
     * @param lowerBnd Minimum amount which is expected to be received at least
     */
    function checkAndGetSendAmountAfterFees(
        uint128 _sendAmount,
        uint128 lowerBnd
    ) internal view returns (uint128 sendAmountAfterFees) {
        sendAmountAfterFees = _sendAmount - getLoanCcyTransferFee(_sendAmount);
        // check range in case of rounding exact lowerBnd amount
        // cannot be hit; set upper bound to prevent fat finger
        if (
            sendAmountAfterFees < lowerBnd ||
            sendAmountAfterFees > (101 * lowerBnd) / 100
        ) revert InvalidSendAmount();
        return sendAmountAfterFees;
    }

    /**
     * @notice Function which gets fees (if any) on the collCcy
     * @param _transferAmount Amount of collCcy to be transferred
     */
    function getCollCcyTransferFee(
        uint128 _transferAmount
    ) internal view virtual returns (uint128);

    /**
     * @notice Function which gets fees (if any) on the loanCcy
     * @param _transferAmount Amount of loanCcy to be transferred
     */
    function getLoanCcyTransferFee(
        uint128 _transferAmount
    ) internal view virtual returns (uint128);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

interface IBasePool_v_1_1 {
    event NewSubPool(
        address loanCcyToken,
        address collCcyToken,
        uint256 loanTenor,
        uint256 maxLoanPerColl,
        uint256 r1,
        uint256 r2,
        uint256 liquidityBnd1,
        uint256 liquidityBnd2,
        uint256 minLoan,
        uint256 creatorFee
    );
    event AddLiquidity(
        address indexed lp,
        uint256 amount,
        uint256 newLpShares,
        uint256 totalLiquidity,
        uint256 totalLpShares,
        uint256 earliestRemove,
        uint256 indexed loanIdx,
        uint256 indexed referralCode
    );
    event RemoveLiquidity(
        address indexed lp,
        uint256 amount,
        uint256 removedLpShares,
        uint256 totalLiquidity,
        uint256 totalLpShares,
        uint256 indexed loanIdx
    );
    event Borrow(
        address indexed borrower,
        uint256 loanIdx,
        uint256 collateral,
        uint256 loanAmount,
        uint256 repaymentAmount,
        uint256 totalLpShares,
        uint256 indexed expiry,
        uint256 indexed referralCode
    );
    event ClaimFromAggregated(
        address indexed lp,
        uint256 fromLoanIdx,
        uint256 toLoanIdx,
        uint256 repayments,
        uint256 collateral
    );
    event Claim(
        address indexed lp,
        uint256[] loanIdxs,
        uint256 repayments,
        uint256 collateral
    );
    event Repay(
        address indexed borrower,
        uint256 loanIdx,
        uint256 repaymentAmountAfterFees
    );
    event Reinvest(
        address indexed lp,
        uint256 repayments,
        uint256 newLpShares,
        uint256 earliestRemove,
        uint256 indexed loanIdx
    );
    event ApprovalUpdate(
        address ownerOrBeneficiary,
        address sender,
        uint256 _packedApprovals
    );
    event UpdatedTerms(
        uint256 maxLoanPerColl,
        uint256 creatorFee,
        uint256 r1,
        uint256 r2,
        uint256 liquidityBnd1,
        uint256 liquidityBnd2
    );
    event LpWhitelistUpdate(address indexed lpAddr, bool isApproved);
    enum ApprovalTypes {
        REPAY,
        REMOVE_LIQUIDITY,
        CLAIM
    }

    struct LpInfo {
        // lower bound loan idx (incl.) from which LP is entitled to claim; gets updated with every claim
        uint32 fromLoanIdx;
        // timestamp from which on LP is allowed to remove liquidity
        uint32 earliestRemove;
        // current share pointer to indicate which sharesOverTime element to be used fromLoanIdx until loanIdxsWhereSharesChanged[currSharePtr] or, if
        // out-of-bounds, until global loan idx
        uint32 currSharePtr;
        // array of len n, with elements representing number of sharesOverTime and new elements being added for consecutive adding/removing of liquidity
        uint256[] sharesOverTime;
        // array of len n-1, with elements representing upper bound loan idx bounds (excl.); LP can claim until loanIdxsWhereSharesChanged[i] with
        // sharesOverTime[i]; and if index i is out-of-bounds of loanIdxsWhereSharesChanged[] then LP can claim up until latest loan idx with sharesOverTime[i]
        uint256[] loanIdxsWhereSharesChanged;
    }

    struct LoanInfo {
        // repayment amount due (post potential fees) to reclaim collateral
        uint128 repayment;
        // reclaimable collateral amount
        uint128 collateral;
        // number of shares for which repayment, respectively collateral, needs to be split
        uint128 totalLpShares;
        // timestamp until repayment is possible and after which borrower forfeits collateral
        uint32 expiry;
        // flag whether loan was repaid or not
        bool repaid;
    }

    struct AggClaimsInfo {
        // aggregated repayment amount
        uint128 repayments;
        // aggregated collateral amount
        uint128 collateral;
    }

    /**
     * @notice Function which adds to an LPs current position
     * @dev This function will update loanIdxsWhereSharesChanged only if not
     * the first add. If address on behalf of is not sender, then sender must have permission.
     * @param _onBehalfOf Recipient of the LP shares
     * @param _sendAmount Amount of loan currency LP wishes to deposit
     * @param _deadline Last timestamp after which function will revert
     * @param _referralCode Will possibly be used later to reward referrals
     */
    function addLiquidity(
        address _onBehalfOf,
        uint128 _sendAmount,
        uint256 _deadline,
        uint256 _referralCode
    ) external;

    /**
     * @notice Function which removes shares from an LPs
     * @dev This function will update loanIdxsWhereSharesChanged and
     * shareOverTime arrays in lpInfo. If address on behalf of is not
     * sender, then sender must have permission to remove on behalf of owner.
     * @param _onBehalfOf Owner of the LP shares
     * @param numSharesRemove Amount of LP shares to remove
     */
    function removeLiquidity(
        address _onBehalfOf,
        uint128 numSharesRemove
    ) external;

    /**
     * @notice Function which allows borrowing from the pool
     * @param _onBehalf Will become owner of the loan
     * @param _sendAmount Amount of collateral currency sent by borrower
     * @param _minLoan Minimum loan currency amount acceptable to borrower
     * @param _maxRepay Maximum allowable loan currency amount borrower is willing to repay
     * @param _deadline Timestamp after which transaction will be void
     * @param _referralCode Code for later possible rewards in referral program
     */
    function borrow(
        address _onBehalf,
        uint128 _sendAmount,
        uint128 _minLoan,
        uint128 _maxRepay,
        uint256 _deadline,
        uint256 _referralCode
    ) external;

    /**
     * @notice Function which allows repayment of a loan
     * @dev The sent amount of loan currency must be sufficient to account
     * for any fees on transfer (if any)
     * @param _loanIdx Index of the loan to be repaid
     * @param _recipient Address that will receive the collateral transfer
     * @param _sendAmount Amount of loan currency sent for repayment.
     */
    function repay(
        uint256 _loanIdx,
        address _recipient,
        uint128 _sendAmount
    ) external;

    /**
     * @notice Function which handles individual claiming by LPs
     * @dev This function is more expensive, but needs to be used when LP
     * changes position size in the middle of smallest aggregation block
     * or if LP wants to claim some of the loans before the expiry time
     * of the last loan in the aggregation block. _loanIdxs must be increasing array.
     * If address on behalf of is not sender, then sender must have permission to claim.
     * As well if reinvestment ootion is chosen, sender must have permission to add liquidity
     * @param _onBehalfOf LP address which is owner or has approved sender to claim on their behalf (and possibly reinvest)
     * @param _loanIdxs Loan indices on which LP wants to claim
     * @param _isReinvested Flag for if LP wants claimed loanCcy to be re-invested
     * @param _deadline Deadline if reinvestment occurs. (If no reinvestment, this is ignored)
     */
    function claim(
        address _onBehalfOf,
        uint256[] calldata _loanIdxs,
        bool _isReinvested,
        uint256 _deadline
    ) external;

    /**
     * @notice Function will update the share pointer for the LP
     * @dev This function will allow an LP to skip his pointer ahead but
     * caution should be used since once an LP has updated their from index
     * they lose all rights to any outstanding claims before that from index
     * @param _newSharePointer New location of the LP's current share pointer
     */
    function overrideSharePointer(uint256 _newSharePointer) external;

    /**
     * @notice Function which handles aggregate claiming by LPs
     * @dev This function is much more efficient, but can only be used when LPs position size did not change
     * over the entire interval LP would like to claim over. _aggIdxs must be increasing array.
     * the first index of _aggIdxs is the from loan index to start aggregation, the rest of the
     * indices are the end loan indexes of the intervals he wants to claim.
     * If address on behalf of is not sender, then sender must have permission to claim.
     * As well if reinvestment option is chosen, sender must have permission to add liquidity
     * @param _onBehalfOf LP address which is owner or has approved sender to claim on their behalf (and possibly reinvest)
     * @param _aggIdxs From index and end indices of the aggregation that LP wants to claim
     * @param _isReinvested Flag for if LP wants claimed loanCcy to be re-invested
     * @param _deadline Deadline if reinvestment occurs. (If no reinvestment, this is ignored)
     */
    function claimFromAggregated(
        address _onBehalfOf,
        uint256[] calldata _aggIdxs,
        bool _isReinvested,
        uint256 _deadline
    ) external;

    /**
     * @notice Function which sets approval for another to perform a certain function on sender's behalf
     * @param _approvee This address is being given approval for the action(s) by the current sender
     * @param _packedApprovals Packed boolean flags to set which actions are approved or not approved,
     * where e.g. "00001" refers to ApprovalTypes.Repay (=0) and "10000" to ApprovalTypes.Claim (=4)
     */
    function setApprovals(address _approvee, uint256 _packedApprovals) external;

    /**
     * @notice Function which proposes a new pool creator address
     * @param _newAddr Address that is being proposed as new pool creator
     */
    function proposeNewCreator(address _newAddr) external;

    /**
     * @notice Function to claim proposed creator role
     */
    function claimCreator() external;

    /**
     * @notice Function which gets all LP info
     * @dev fromLoanIdx = 0 can be utilized for checking if someone had been an LP in the pool
     * @param _lpAddr Address for which LP info is being retrieved
     * @return fromLoanIdx Lower bound loan idx (incl.) from which LP is entitled to claim
     * @return earliestRemove Earliest timestamp from which LP is allowed to remove liquidity
     * @return currSharePtr Current pointer for the shares over time array
     * @return sharesOverTime Array with elements representing number of LP shares for their past and current positions
     * @return loanIdxsWhereSharesChanged Array with elements representing upper loan idx bounds (excl.), where LP can claim
     */
    function getLpInfo(
        address _lpAddr
    )
        external
        view
        returns (
            uint32 fromLoanIdx,
            uint32 earliestRemove,
            uint32 currSharePtr,
            uint256[] memory sharesOverTime,
            uint256[] memory loanIdxsWhereSharesChanged
        );

    /**
     * @notice Function which returns rate parameters need for interest rate calculation
     * @dev This function can be used to get parameters needed for interest rate calculations
     * @return _liquidityBnd1 Amount of liquidity the pool needs to end the reciprocal (hyperbola)
     * range and start "target" range
     * @return _liquidityBnd2 Amount of liquidity the pool needs to end the "target" range and start flat rate
     * @return _r1 Rate that is used at start of target range
     * @return _r2 Minimum rate at end of target range. This is minimum allowable rate
     */
    function getRateParams()
        external
        view
        returns (
            uint256 _liquidityBnd1,
            uint256 _liquidityBnd2,
            uint256 _r1,
            uint256 _r2
        );

    /**
     * @notice Function which returns pool information
     * @dev This function can be used to get pool information
     * @return _loanCcyToken Loan currency
     * @return _collCcyToken Collateral currency
     * @return _maxLoanPerColl Maximum loan amount per pledged collateral unit
     * @return _minLoan Minimum loan size
     * @return _loanTenor Loan tenor
     * @return _totalLiquidity Total liquidity available for loans
     * @return _totalLpShares Total LP shares
     * @return _baseAggrBucketSize Base aggregation level
     * @return _loanIdx Loan index for the next incoming loan
     */
    function getPoolInfo()
        external
        view
        returns (
            address _loanCcyToken,
            address _collCcyToken,
            uint256 _maxLoanPerColl,
            uint256 _minLoan,
            uint256 _loanTenor,
            uint256 _totalLiquidity,
            uint256 _totalLpShares,
            uint256 _baseAggrBucketSize,
            uint256 _loanIdx
        );

    /**
     * @notice Function which calculates loan terms
     * @param _inAmountAfterFees Amount of collateral currency after fees are deducted
     * @return loanAmount Amount of loan currency to be trasnferred to the borrower
     * @return repaymentAmount Amount of loan currency borrower must repay to reclaim collateral
     * @return pledgeAmount Amount of collateral currency borrower retrieves upon repayment
     * @return _creatorFee Amount of collateral currency to be transferred to treasury
     * @return _totalLiquidity The total liquidity of the pool (pre-borrow) that is available for new loans
     */
    function loanTerms(
        uint128 _inAmountAfterFees
    )
        external
        view
        returns (
            uint128 loanAmount,
            uint128 repaymentAmount,
            uint128 pledgeAmount,
            uint256 _creatorFee,
            uint256 _totalLiquidity
        );

    /**
     * @notice Function which returns claims for a given aggregated from and to index and amount of sharesOverTime
     * @dev This function is called internally, but also can be used by other protocols so has some checks
     * which are unnecessary if it was solely an internal function
     * @param _fromLoanIdx Loan index on which he wants to start aggregate claim (must be mod 0 wrt 100)
     * @param _toLoanIdx End loan index of the aggregation
     * @param _shares Amount of sharesOverTime which the LP owned over this given aggregation period
     */
    function getClaimsFromAggregated(
        uint256 _fromLoanIdx,
        uint256 _toLoanIdx,
        uint256 _shares
    ) external view returns (uint256 repayments, uint256 collateral);

    /**
     * @notice Getter which returns the borrower for a given loan idx
     * @param loanIdx The loan idx
     * @return The borrower address
     */
    function loanIdxToBorrower(uint256 loanIdx) external view returns (address);

    /**
     * @notice Function returns if owner or beneficiary has approved a sender address for a given type
     * @param _ownerOrBeneficiary Address which will be owner or beneficiary of transaction if approved
     * @param _sender Address which will be sending request on behalf of _ownerOrBeneficiary
     * @param _approvalType Type of approval requested { REPAY, ADD_LIQUIDITY, REMOVE_LIQUIDITY, CLAIM }
     * @return _approved True if approved, false otherwise
     */
    function isApproved(
        address _ownerOrBeneficiary,
        address _sender,
        ApprovalTypes _approvalType
    ) external view returns (bool _approved);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {BasePool_v_1_1} from "../../BasePool_v_1_1.sol";

contract PoolRplUsdc_v_1_1 is BasePool_v_1_1 {
    constructor(
        uint24 _loanTenor,
        uint128 _maxLoanPerColl,
        uint256 _r1,
        uint256 _r2,
        uint256 _liquidityBnd1,
        uint256 _liquidityBnd2,
        uint256 _minLoan,
        uint256 _baseAggrBucketSize,
        uint128 _creatorFee
    )
        BasePool_v_1_1(
            0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
            0xD33526068D116cE69F19A9ee46F0bd304F21A51f,
            _loanTenor,
            _maxLoanPerColl,
            _r1,
            _r2,
            _liquidityBnd1,
            _liquidityBnd2,
            _minLoan,
            _baseAggrBucketSize,
            _creatorFee,
            10 * 10 ** 6
        )
    {}

    function updateTerms(
        uint256 _maxLoanPerColl,
        uint256 _creatorFee,
        uint256 _r1,
        uint256 _r2,
        uint256 _liquidityBnd1,
        uint256 _liquidityBnd2
    ) external {
        if (msg.sender != poolCreator) {
            revert UnapprovedSender();
        }
        if (_maxLoanPerColl == 0) revert InvalidMaxLoanPerColl();
        if (_r1 <= _r2 || _r2 == 0) revert InvalidRateParams();
        if (_liquidityBnd2 <= _liquidityBnd1 || _liquidityBnd1 == 0)
            revert InvalidLiquidityBnds();
        if (_creatorFee > MAX_FEE) revert InvalidFee();
        maxLoanPerColl = _maxLoanPerColl;
        creatorFee = _creatorFee;
        r1 = _r1;
        r2 = _r2;
        liquidityBnd1 = _liquidityBnd1;
        liquidityBnd2 = _liquidityBnd2;
        emit UpdatedTerms(
            maxLoanPerColl,
            creatorFee,
            r1,
            r2,
            liquidityBnd1,
            liquidityBnd2
        );
    }

    function getCollCcyTransferFee(
        uint128 /*_transferAmount*/
    ) internal pure override returns (uint128 transferFee) {
        transferFee = 0;
    }

    function getLoanCcyTransferFee(
        uint128 /*_transferAmount*/
    ) internal pure override returns (uint128 transferFee) {
        transferFee = 0;
    }
}