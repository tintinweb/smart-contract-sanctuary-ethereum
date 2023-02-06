// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity 0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity 0.8.0;

import "./IERC20.sol";

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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


interface IEverscale {
    struct EverscaleAddress {
        int8 wid;
        uint256 addr;
    }

    struct EverscaleEvent {
        uint64 eventTransactionLt;
        uint32 eventTimestamp;
        bytes eventData;
        int8 configurationWid;
        uint256 configurationAddress;
        int8 eventContractWid;
        uint256 eventContractAddress;
        address proxy;
        uint32 round;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "../IEverscale.sol";
import "./IMultiVaultFacetPendingWithdrawals.sol";


interface IMultiVaultFacetDeposit {
    struct DepositParams {
        IEverscale.EverscaleAddress recipient;
        address token;
        uint amount;
        uint expected_evers;
        bytes payload;
    }

    struct DepositNativeTokenParams {
        IEverscale.EverscaleAddress recipient;
        uint amount;
        uint expected_evers;
        bytes payload;
    }

    function depositByNativeToken(
        DepositNativeTokenParams memory d
    ) external payable;

    function depositByNativeToken(
        DepositNativeTokenParams memory d,
        uint256 expectedMinBounty,
        IMultiVaultFacetPendingWithdrawals.PendingWithdrawalId[] memory pendingWithdrawalIds
    ) external payable;

    function deposit(
        DepositParams memory d
    ) external payable;

    function deposit(
        DepositParams memory d,
        uint256 expectedMinBounty,
        IMultiVaultFacetPendingWithdrawals.PendingWithdrawalId[] memory pendingWithdrawalIds
    ) external payable;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "./IMultiVaultFacetTokens.sol";

interface IMultiVaultFacetDepositEvents {
    event NativeTransfer(
        int8 native_wid,
        uint256 native_addr,
        uint128 amount,
        int8 recipient_wid,
        uint256 recipient_addr,
        uint value,
        uint expected_evers,
        bytes payload
    );

    event AlienTransfer(
        uint256 base_chainId,
        uint160 base_token,
        string name,
        string symbol,
        uint8 decimals,
        uint128 amount,
        int8 recipient_wid,
        uint256 recipient_addr,
        uint value,
        uint expected_evers,
        bytes payload
    );

    event Deposit(
        IMultiVaultFacetTokens.TokenType _type,
        address sender,
        address token,
        int8 recipient_wid,
        uint256 recipient_addr,
        uint256 amount,
        uint256 fee
    );
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


interface IMultiVaultFacetLiquidity {
    struct Liquidity {
        uint activation;
        uint supply;
        uint cash;
        uint interest;
    }

    function mint(
        address token,
        uint amount,
        address receiver
    ) external;

    function redeem(
        address token,
        uint amount,
        address receiver
    ) external;

    function exchangeRateCurrent(
        address token
    ) external view returns(uint);

    function getCash(
        address token
    ) external view returns(uint);

    function getLPToken(
        address token
    ) external view returns (address);

    function setTokenInterest(
        address token,
        uint interest
    ) external;

    function setDefaultInterest(
        uint interest
    ) external;

    function liquidity(
        address token
    ) external view returns (Liquidity memory);

    function convertLPToUnderlying(
        address token,
        uint amount
    ) external view returns (uint);

    function convertUnderlyingToLP(
        address token,
        uint amount
    ) external view returns (uint);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "../IEverscale.sol";
import "./IMultiVaultFacetWithdraw.sol";


interface IMultiVaultFacetPendingWithdrawals {
    enum ApproveStatus { NotRequired, Required, Approved, Rejected }

    struct WithdrawalLimits {
        uint undeclared;
        uint daily;
        bool enabled;
    }

    struct PendingWithdrawalParams {
        address token;
        uint256 amount;
        uint256 bounty;
        uint256 timestamp;
        ApproveStatus approveStatus;

        uint256 chainId;
        IMultiVaultFacetWithdraw.Callback callback;
    }

    struct PendingWithdrawalId {
        address recipient;
        uint256 id;
    }

    struct WithdrawalPeriodParams {
        uint256 total;
        uint256 considered;
    }

    function pendingWithdrawalsPerUser(address user) external view returns (uint);
    function pendingWithdrawalsTotal(address token) external view returns (uint);

    function pendingWithdrawals(
        address user,
        uint256 id
    ) external view returns (PendingWithdrawalParams memory);

    function setPendingWithdrawalBounty(
        uint256 id,
        uint256 bounty
    ) external;

    function cancelPendingWithdrawal(
        uint256 id,
        uint256 amount,
        IEverscale.EverscaleAddress memory recipient,
        uint expected_evers,
        bytes memory payload,
        uint bounty
    ) external payable;

    function setPendingWithdrawalApprove(
        PendingWithdrawalId memory pendingWithdrawalId,
        ApproveStatus approveStatus
    ) external;

    function setPendingWithdrawalApprove(
        PendingWithdrawalId[] memory pendingWithdrawalId,
        ApproveStatus[] memory approveStatus
    ) external;

    function forceWithdraw(
        PendingWithdrawalId[] memory pendingWithdrawalIds
    ) external;

    function withdrawalLimits(
        address token
    ) external view returns(WithdrawalLimits memory);

    function withdrawalPeriods(
        address token,
        uint256 withdrawalPeriodId
    ) external view returns (WithdrawalPeriodParams memory);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "./IMultiVaultFacetPendingWithdrawals.sol";


interface IMultiVaultFacetPendingWithdrawalsEvents {
    event PendingWithdrawalCancel(
        address recipient,
        uint256 id,
        uint256 amount
    );

    event PendingWithdrawalUpdateBounty(
        address recipient,
        uint256 id,
        uint256 bounty
    );

    event PendingWithdrawalCreated(
        address recipient,
        uint256 id,
        address token,
        uint256 amount,
        bytes32 payloadId
    );

    event PendingWithdrawalWithdraw(
        address recipient,
        uint256 id,
        uint256 amount
    );

    event PendingWithdrawalFill(
        address recipient,
        uint256 id
    );

    event PendingWithdrawalForce(
        address recipient,
        uint256 id
    );

    event PendingWithdrawalUpdateApproveStatus(
        address recipient,
        uint256 id,
        IMultiVaultFacetPendingWithdrawals.ApproveStatus approveStatus
    );
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "./../IEverscale.sol";


interface IMultiVaultFacetTokens {
    enum TokenType { Native, Alien }

    struct TokenPrefix {
        uint activation;
        string name;
        string symbol;
    }

    struct TokenMeta {
        string name;
        string symbol;
        uint8 decimals;
    }

    struct Token {
        uint activation;
        bool blacklisted;
        uint depositFee;
        uint withdrawFee;
        bool isNative;
        address custom;
    }

    function prefixes(address _token) external view returns (TokenPrefix memory);
    function tokens(address _token) external view returns (Token memory);
    function natives(address _token) external view returns (IEverscale.EverscaleAddress memory);

    function setPrefix(
        address token,
        string memory name_prefix,
        string memory symbol_prefix
    ) external;

    function setTokenBlacklist(
        address token,
        bool blacklisted
    ) external;

    function getNativeToken(
        IEverscale.EverscaleAddress memory native
    ) external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "./IMultiVaultFacetTokens.sol";
import "../IEverscale.sol";


interface IMultiVaultFacetWithdraw {
    struct Callback {
        address recipient;
        bytes payload;
        bool strict;
    }

    struct NativeWithdrawalParams {
        IEverscale.EverscaleAddress native;
        IMultiVaultFacetTokens.TokenMeta meta;
        uint256 amount;
        address recipient;
        uint256 chainId;
        Callback callback;
    }

    struct AlienWithdrawalParams {
        address token;
        uint256 amount;
        address recipient;
        uint256 chainId;
        Callback callback;
    }

    function withdrawalIds(bytes32) external view returns (bool);

    function saveWithdrawNative(
        bytes memory payload,
        bytes[] memory signatures
    ) external;

    function saveWithdrawAlien(
        bytes memory payload,
        bytes[] memory signatures
    ) external;

    function saveWithdrawAlien(
        bytes memory payload,
        bytes[] memory signatures,
        uint bounty
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;

import "./IMultiVaultFacetWithdraw.sol";


interface IOctusCallback {
    function onNativeWithdrawal(
        IMultiVaultFacetWithdraw.NativeWithdrawalParams memory payload
    ) external;
    function onAlienWithdrawal(
        IMultiVaultFacetWithdraw.AlienWithdrawalParams memory payload,
        uint256 withdrawAmount
    ) external;
    function onAlienWithdrawalPendingCreated(
        IMultiVaultFacetWithdraw.AlienWithdrawalParams memory _payload,
        uint pendingWithdrawalId
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity 0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity 0.8.0;

import "./../interfaces/IERC20.sol";
import "./../libraries/Address.sol";

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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "../../interfaces/multivault/IMultiVaultFacetPendingWithdrawals.sol";
import "../../interfaces/multivault/IMultiVaultFacetPendingWithdrawalsEvents.sol";
import "../../interfaces/multivault/IMultiVaultFacetWithdraw.sol";
import "../../interfaces/IEverscale.sol";
import "../../interfaces/IERC20.sol";

import "../helpers/MultiVaultHelperEmergency.sol";
import "../helpers/MultiVaultHelperActors.sol";
import "../helpers/MultiVaultHelperPendingWithdrawal.sol";
import "../helpers/MultiVaultHelperTokenBalance.sol";
import "../helpers/MultiVaultHelperEverscale.sol";
import "../helpers/MultiVaultHelperCallback.sol";

import "../storage/MultiVaultStorage.sol";
import "../../libraries/SafeERC20.sol";



contract MultiVaultFacetPendingWithdrawals is
    MultiVaultHelperEmergency,
    MultiVaultHelperActors,
    MultiVaultHelperEverscale,
    MultiVaultHelperTokenBalance,
    MultiVaultHelperPendingWithdrawal,
    IMultiVaultFacetPendingWithdrawals,
    MultiVaultHelperCallback
{
    using SafeERC20 for IERC20;

    function pendingWithdrawals(
        address user,
        uint256 id
    ) external view override returns (PendingWithdrawalParams memory) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        return s.pendingWithdrawals_[user][id];
    }

    function withdrawalLimits(
        address token
    ) external view override returns(WithdrawalLimits memory) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        return s.withdrawalLimits_[token];
    }

    function withdrawalPeriods(
        address token,
        uint256 withdrawalPeriodId
    ) external view override returns (WithdrawalPeriodParams memory) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        return s.withdrawalPeriods_[token][withdrawalPeriodId];
    }

    /// @notice Changes pending withdrawal bounty for specific pending withdrawal
    /// @param id Pending withdrawal ID.
    /// @param bounty The new value for pending withdrawal bounty.
    function setPendingWithdrawalBounty(
        uint256 id,
        uint256 bounty
    )
        public
        override
    {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        PendingWithdrawalParams memory pendingWithdrawal = _pendingWithdrawal(msg.sender, id);

        require(bounty <= pendingWithdrawal.amount);

        s.pendingWithdrawals_[msg.sender][id].bounty = bounty;

        emit PendingWithdrawalUpdateBounty(
            msg.sender,
            id,
            bounty
        );
    }

    function forceWithdraw(
        PendingWithdrawalId[] memory pendingWithdrawalIds
    ) external override {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        for (uint i = 0; i < pendingWithdrawalIds.length; i++) {
            PendingWithdrawalId memory pendingWithdrawalId = pendingWithdrawalIds[i];
            PendingWithdrawalParams memory pendingWithdrawal = _pendingWithdrawal(pendingWithdrawalId);

            s.pendingWithdrawals_[pendingWithdrawalId.recipient][pendingWithdrawalId.id].amount = 0;

            IERC20(pendingWithdrawal.token).safeTransfer(
                pendingWithdrawalId.recipient,
                pendingWithdrawal.amount
            );

            emit PendingWithdrawalForce(
                pendingWithdrawalId.recipient,
                pendingWithdrawalId.id
            );

            _callbackAlienWithdrawal(
                IMultiVaultFacetWithdraw.AlienWithdrawalParams({
                    token: pendingWithdrawal.token,
                    amount: pendingWithdrawal.amount,
                    recipient: pendingWithdrawalId.recipient,
                    chainId: pendingWithdrawal.chainId,
                    callback: pendingWithdrawal.callback
                }),
                pendingWithdrawal.amount
            );
        }
    }

    /// @notice Cancel pending withdrawal partially or completely.
    /// This may only be called by pending withdrawal recipient.
    /// @param id Pending withdrawal ID
    /// @param amount Amount to cancel, should be less or equal than pending withdrawal amount
    /// @param recipient Tokens recipient, in Everscale network
    /// @param bounty New value for bounty
    function cancelPendingWithdrawal(
        uint256 id,
        uint256 amount,
        IEverscale.EverscaleAddress memory recipient,
        uint expected_evers,
        bytes memory payload,
        uint bounty
    )
        external
        payable
        override
        onlyEmergencyDisabled
    {
        PendingWithdrawalParams memory pendingWithdrawal = _pendingWithdrawal(msg.sender, id);
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        require(amount > 0 && amount <= pendingWithdrawal.amount);

        s.pendingWithdrawals_[msg.sender][id].amount -= amount;

        IMultiVaultFacetDeposit.DepositParams memory deposit = IMultiVaultFacetDeposit.DepositParams({
            recipient: recipient,
            token: pendingWithdrawal.token,
            amount: amount,
            expected_evers: expected_evers,
            payload: payload
        });

        _transferToEverscaleAlien(deposit, 0, msg.value);

        emit PendingWithdrawalCancel(msg.sender, id, amount);

        setPendingWithdrawalBounty(id, bounty);
    }

    /**
        @notice Set approve status for pending withdrawal.
            Pending withdrawal must be in `Required` (1) approve status, so approve status can be set only once.
            If Vault has enough tokens on its balance - withdrawal will be filled immediately.
            This may only be called by `governance` or `withdrawGuardian`.
        @param pendingWithdrawalId Pending withdrawal ID.
        @param approveStatus Approve status. Must be `Approved` (2) or `Rejected` (3).
    */
    function setPendingWithdrawalApprove(
        PendingWithdrawalId memory pendingWithdrawalId,
        ApproveStatus approveStatus
    )
        public
        override
        onlyGovernanceOrWithdrawGuardian
        pendingWithdrawalOpened(pendingWithdrawalId)
    {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();
        PendingWithdrawalParams memory pendingWithdrawal = _pendingWithdrawal(pendingWithdrawalId);

        require(pendingWithdrawal.approveStatus == ApproveStatus.Required);

        require(
            approveStatus == ApproveStatus.Approved ||
            approveStatus == ApproveStatus.Rejected
        );

        _pendingWithdrawalApproveStatusUpdate(pendingWithdrawalId, approveStatus);

        // Fill approved withdrawal
        if (approveStatus == ApproveStatus.Approved && pendingWithdrawal.amount <= _vaultTokenBalance(pendingWithdrawal.token)) {
            _pendingWithdrawalAmountReduce(
                pendingWithdrawal.token,
                pendingWithdrawalId,
                pendingWithdrawal.amount
            );

            IERC20(pendingWithdrawal.token).safeTransfer(
                pendingWithdrawalId.recipient,
                pendingWithdrawal.amount
            );

            emit PendingWithdrawalWithdraw(
                pendingWithdrawalId.recipient,
                pendingWithdrawalId.id,
                pendingWithdrawal.amount
            );
        }

        // Update withdrawal period considered amount
        uint withdrawalPeriodId = _withdrawalPeriodDeriveId(pendingWithdrawal.timestamp);

        s.withdrawalPeriods_[pendingWithdrawal.token][withdrawalPeriodId].considered += pendingWithdrawal.amount;
    }

    /**
        @notice Multicall for `setPendingWithdrawalApprove`.
        @param pendingWithdrawalId List of pending withdrawals IDs.
        @param approveStatus List of approve statuses.
    */
    function setPendingWithdrawalApprove(
        PendingWithdrawalId[] memory pendingWithdrawalId,
        ApproveStatus[] memory approveStatus
    ) external override {
        require(pendingWithdrawalId.length == approveStatus.length);

        for (uint i = 0; i < pendingWithdrawalId.length; i++) {
            setPendingWithdrawalApprove(pendingWithdrawalId[i], approveStatus[i]);
        }
    }

    function pendingWithdrawalsTotal(address _token) external view override returns (uint) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        return s.pendingWithdrawalsTotal[_token];
    }

    function pendingWithdrawalsPerUser(address user) external view override returns(uint) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        return s.pendingWithdrawalsPerUser[user];
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "../storage/MultiVaultStorage.sol";


abstract contract MultiVaultHelperActors {
    modifier onlyPendingGovernance() {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        require(msg.sender == s.pendingGovernance);

        _;
    }

    modifier onlyGovernance() {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        require(msg.sender == s.governance);

        _;
    }

    modifier onlyGovernanceOrManagement() {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        require(msg.sender == s.governance || msg.sender == s.management);

        _;
    }

    modifier onlyGovernanceOrWithdrawGuardian() {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        require(msg.sender == s.governance || msg.sender == s.withdrawGuardian);

        _;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "../../interfaces/multivault/IMultiVaultFacetWithdraw.sol";
import "../../interfaces/multivault/IOctusCallback.sol";

abstract contract MultiVaultHelperCallback {
    modifier checkCallbackRecipient(address recipient) {
        require(recipient != address(this));

        if (recipient != address(0)) {
            _;
        }
    }

    function _callbackNativeWithdrawal(
        IMultiVaultFacetWithdraw.NativeWithdrawalParams memory withdrawal
    ) internal checkCallbackRecipient(withdrawal.callback.recipient) {
        bytes memory data = abi.encodeWithSelector(
            IOctusCallback.onNativeWithdrawal.selector,
            withdrawal
        );

        _execute(
            withdrawal.callback.recipient,
            data,
            withdrawal.callback.strict
        );
    }

    function _callbackAlienWithdrawal(
        IMultiVaultFacetWithdraw.AlienWithdrawalParams memory _withdrawal,
        uint256 _withdrawAmount
    ) internal checkCallbackRecipient(_withdrawal.callback.recipient) {
        bytes memory data = abi.encodeWithSelector(
            IOctusCallback.onAlienWithdrawal.selector,
            _withdrawal,
            _withdrawAmount
        );

        _execute(
            _withdrawal.callback.recipient,
            data,
            _withdrawal.callback.strict
        );
    }

    function _callbackAlienWithdrawalPendingCreated(
        IMultiVaultFacetWithdraw.AlienWithdrawalParams memory _withdrawal,
        uint _pendingWithdrawalId
    ) checkCallbackRecipient(_withdrawal.callback.recipient) internal {
        bytes memory data = abi.encodeWithSelector(
            IOctusCallback.onAlienWithdrawalPendingCreated.selector,
            _withdrawal,
            _pendingWithdrawalId
        );

        _execute(
            _withdrawal.callback.recipient,
            data,
            _withdrawal.callback.strict
        );
    }

    function _execute(
        address recipient,
        bytes memory data,
        bool strict
    ) internal {
        (bool success, ) = recipient.call(data);

        if (strict) require(success);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;

import "../storage/MultiVaultStorage.sol";


abstract contract MultiVaultHelperEmergency {
    modifier onlyEmergencyDisabled() {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        require(!s.emergencyShutdown);

        _;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "../../interfaces/IEverscale.sol";
import "../../interfaces/IERC20Metadata.sol";
import "../../interfaces/multivault/IMultiVaultFacetDepositEvents.sol";
import "../../interfaces/multivault/IMultiVaultFacetDeposit.sol";

import "../storage/MultiVaultStorage.sol";


abstract contract MultiVaultHelperEverscale is IMultiVaultFacetDepositEvents {
    function _transferToEverscaleNative(
        IMultiVaultFacetDeposit.DepositParams memory deposit,
        uint fee,
        uint value
    ) internal {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        IEverscale.EverscaleAddress memory native = s.natives_[deposit.token];

        emit NativeTransfer(
            native.wid,
            native.addr,

            uint128(deposit.amount),
            deposit.recipient.wid,
            deposit.recipient.addr,
            value,
            deposit.expected_evers,
            deposit.payload
        );

        _emitDeposit(deposit, fee, true);
    }

    function _transferToEverscaleAlien(
        IMultiVaultFacetDeposit.DepositParams memory deposit,
        uint fee,
        uint value
    ) internal {
        emit AlienTransfer(
            block.chainid,
            uint160(deposit.token),
            IERC20Metadata(deposit.token).name(),
            IERC20Metadata(deposit.token).symbol(),
            IERC20Metadata(deposit.token).decimals(),

            uint128(deposit.amount),
            deposit.recipient.wid,
            deposit.recipient.addr,
            value,
            deposit.expected_evers,
            deposit.payload
        );

        _emitDeposit(deposit, fee, false);
    }

    function _emitDeposit(
        IMultiVaultFacetDeposit.DepositParams memory deposit,
        uint fee,
        bool isNative
    ) internal {
        emit Deposit(
            isNative ? IMultiVaultFacetTokens.TokenType.Native : IMultiVaultFacetTokens.TokenType.Alien,
            msg.sender,
            deposit.token,
            deposit.recipient.wid,
            deposit.recipient.addr,
            deposit.amount + fee,
            fee
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "../../interfaces/multivault/IMultiVaultFacetPendingWithdrawals.sol";
import "../../interfaces/multivault/IMultiVaultFacetPendingWithdrawalsEvents.sol";

import "../storage/MultiVaultStorage.sol";


abstract contract MultiVaultHelperPendingWithdrawal is IMultiVaultFacetPendingWithdrawalsEvents {
    modifier pendingWithdrawalOpened(
        IMultiVaultFacetPendingWithdrawals.PendingWithdrawalId memory pendingWithdrawalId
    ) {
        IMultiVaultFacetPendingWithdrawals.PendingWithdrawalParams memory pendingWithdrawal = _pendingWithdrawal(pendingWithdrawalId);

        require(pendingWithdrawal.amount > 0);

        _;
    }

    function _pendingWithdrawal(
        IMultiVaultFacetPendingWithdrawals.PendingWithdrawalId memory pendingWithdrawalId
    ) internal view returns (IMultiVaultFacetPendingWithdrawals.PendingWithdrawalParams memory) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        return s.pendingWithdrawals_[pendingWithdrawalId.recipient][pendingWithdrawalId.id];
    }

    function _pendingWithdrawal(
        address recipient,
        uint256 id
    ) internal view returns (IMultiVaultFacetPendingWithdrawals.PendingWithdrawalParams memory) {
        return _pendingWithdrawal(IMultiVaultFacetPendingWithdrawals.PendingWithdrawalId(recipient, id));
    }

    function _pendingWithdrawalApproveStatusUpdate(
        IMultiVaultFacetPendingWithdrawals.PendingWithdrawalId memory pendingWithdrawalId,
        IMultiVaultFacetPendingWithdrawals.ApproveStatus approveStatus
    ) internal {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        s.pendingWithdrawals_[pendingWithdrawalId.recipient][pendingWithdrawalId.id].approveStatus = approveStatus;

        emit PendingWithdrawalUpdateApproveStatus(
            pendingWithdrawalId.recipient,
            pendingWithdrawalId.id,
            approveStatus
        );
    }

    function _pendingWithdrawalAmountReduce(
        address token,
        IMultiVaultFacetPendingWithdrawals.PendingWithdrawalId memory pendingWithdrawalId,
        uint amount
    ) internal {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        s.pendingWithdrawals_[pendingWithdrawalId.recipient][pendingWithdrawalId.id].amount -= amount;
        s.pendingWithdrawalsTotal[token] -= amount;
    }

    function _withdrawalPeriod(
        address token,
        uint256 timestamp
    ) internal view returns (IMultiVaultFacetPendingWithdrawals.WithdrawalPeriodParams memory) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        return s.withdrawalPeriods_[token][_withdrawalPeriodDeriveId(timestamp)];
    }

    function _withdrawalPeriodDeriveId(
        uint256 timestamp
    ) internal pure returns (uint256) {
        return timestamp / MultiVaultStorage.WITHDRAW_PERIOD_DURATION_IN_SECONDS;
    }

    function _withdrawalPeriodIncreaseTotalByTimestamp(
        address token,
        uint256 timestamp,
        uint256 amount
    ) internal {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        uint withdrawalPeriodId = _withdrawalPeriodDeriveId(timestamp);

        s.withdrawalPeriods_[token][withdrawalPeriodId].total += amount;
    }

    function _withdrawalPeriodCheckLimitsPassed(
        address token,
        uint amount,
        IMultiVaultFacetPendingWithdrawals.WithdrawalPeriodParams memory withdrawalPeriod
    ) internal view returns (bool) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        IMultiVaultFacetPendingWithdrawals.WithdrawalLimits memory withdrawalLimit = s.withdrawalLimits_[token];

        if (!withdrawalLimit.enabled) return true;

        return (amount < withdrawalLimit.undeclared) &&
        (amount + withdrawalPeriod.total - withdrawalPeriod.considered < withdrawalLimit.daily);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "../../interfaces/IERC20.sol";


abstract contract MultiVaultHelperTokenBalance {
    function _vaultTokenBalance(
        address token
    ) internal view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "../../interfaces/IEverscale.sol";
import "../../interfaces/multivault/IMultiVaultFacetTokens.sol";
import "../../interfaces/multivault/IMultiVaultFacetPendingWithdrawals.sol";
import "../../interfaces/multivault/IMultiVaultFacetLiquidity.sol";


library MultiVaultStorage {
    uint constant MAX_BPS = 10_000;
    uint constant FEE_LIMIT = MAX_BPS / 2;

    uint8 constant DECIMALS_LIMIT = 18;
    uint256 constant SYMBOL_LENGTH_LIMIT = 32;
    uint256 constant NAME_LENGTH_LIMIT = 32;

    string constant DEFAULT_NAME_PREFIX = '';
    string constant DEFAULT_SYMBOL_PREFIX = '';

    string constant DEFAULT_NAME_LP_PREFIX = 'Octus LP ';
    string constant DEFAULT_SYMBOL_LP_PREFIX = 'octLP';

    uint256 constant WITHDRAW_PERIOD_DURATION_IN_SECONDS = 60 * 60 * 24; // 24 hours

    // Previous version of the Vault contract was built with Upgradable Proxy Pattern, without using Diamond storage
    bytes32 constant MULTIVAULT_LEGACY_STORAGE_POSITION = 0x0000000000000000000000000000000000000000000000000000000000000002;

    uint constant LP_EXCHANGE_RATE_BPS = 10_000_000_000;

    struct Storage {
        mapping (address => IMultiVaultFacetTokens.Token) tokens_;
        mapping (address => IEverscale.EverscaleAddress) natives_;

        uint defaultNativeDepositFee;
        uint defaultNativeWithdrawFee;
        uint defaultAlienDepositFee;
        uint defaultAlienWithdrawFee;

        bool emergencyShutdown;

        address bridge;
        mapping(bytes32 => bool) withdrawalIds;
        IEverscale.EverscaleAddress rewards_;
        IEverscale.EverscaleAddress configurationNative_;
        IEverscale.EverscaleAddress configurationAlien_;

        address governance;
        address pendingGovernance;
        address guardian;
        address management;

        mapping (address => IMultiVaultFacetTokens.TokenPrefix) prefixes_;
        mapping (address => uint) fees;

        // STORAGE UPDATE 1
        // Pending withdrawals
        // - Counter pending withdrawals per user
        mapping(address => uint) pendingWithdrawalsPerUser;
        // - Pending withdrawal details
        mapping(address => mapping(uint256 => IMultiVaultFacetPendingWithdrawals.PendingWithdrawalParams)) pendingWithdrawals_;

        // - Total amount of pending withdrawals per token
        mapping(address => uint) pendingWithdrawalsTotal;

        // STORAGE UPDATE 2
        // Withdrawal limits per token
        mapping(address => IMultiVaultFacetPendingWithdrawals.WithdrawalLimits) withdrawalLimits_;

        // - Withdrawal periods. Each period is `WITHDRAW_PERIOD_DURATION_IN_SECONDS` seconds long.
        // If some period has reached the `withdrawalLimitPerPeriod` - all the future
        // withdrawals in this period require manual approve, see note on `setPendingWithdrawalsApprove`
        mapping(address => mapping(uint256 => IMultiVaultFacetPendingWithdrawals.WithdrawalPeriodParams)) withdrawalPeriods_;

        address withdrawGuardian;

        // STORAGE UPDATE 3
        mapping (address => IMultiVaultFacetLiquidity.Liquidity) liquidity;
        uint defaultInterest;

        // STORAGE UPDATE 4
        // - Receives native value, attached to the deposit
        address gasDonor;
        address weth;
    }

    function _storage() internal pure returns (Storage storage s) {
        assembly {
            s.slot := MULTIVAULT_LEGACY_STORAGE_POSITION
        }
    }
}