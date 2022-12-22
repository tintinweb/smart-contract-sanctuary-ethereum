// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*** CONTRACTS IMPORTED ***/
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./utils/FundUtils.sol";

/*** INTERFACES IMPORTED ***/
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/*** LIBRARIES IMPORTED ***/
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/*** CONTRACT ***/
contract FundU is ReentrancyGuard, FundUtils {
    /*** LIBRARIES USED ***/
    using SafeERC20 for IERC20;

    /*** STATE VARIABLES ***/
    uint256 private s_streamId;

    /*** MAPPINGS ***/
    mapping(uint256 => StreamData) private s_streamById; // Fund Id => Fund
    mapping(address => uint256[]) private s_beneficiaryStreamsIds; // address => [fund´s ids]
    mapping(address => uint256[]) private s_ownerStreamsIds; // address => [fund´s ids]

    /*** MODIFIERS ***/

    /**
     * @notice to check the stream owner
     * @param id Stream id
     */
    modifier onlyStreamOwner(uint256 id) {
        StreamData memory stream = s_streamById[id];
        if (msg.sender != stream.owner) {
            revert FundU__onlyStreamOwnerAllowed();
        }
        _;
    }

    /**
     * @notice to check the fund beneficiary
     * @param id Fund´s id
     */
    modifier onlyStreamBeneficiary(uint256 id) {
        StreamData memory stream = s_streamById[id];
        if (msg.sender != stream.beneficiary) {
            revert FundU__onlyStreamBeneficiaryAllowed();
        }
        _;
    }

    /*** CONSTRUCTOR ***/
    constructor() {
        s_streamId = 0;
    }

    /*** MAIN FUNCTIONS ***/
    /**
     * @notice create new streams
     * @param beneficiary The one to receive the stream
     * @param amountToDeposit How much to deposit
     * @param start When the stream starts
     * @param stop When the stream ends
     * @param tokenAddress Tokens address deposited
     * @return the newly created stream´s id
     * @dev if the startTime is 0 the stream will start right away
     * @dev It reverts if the beneficiary is the address zero
     * @dev It reverts if the beneficiary is this contract
     * @dev It reverts if the beneficiary is the owner
     * @dev It reverts if there is no deposit
     * @dev It reverts if the stopTime is less that the time when the function is called
     * @dev It reverts if the transfer fails
     */
    function newStream(
        address beneficiary,
        uint256 amountToDeposit,
        uint256 start,
        uint256 stop,
        address tokenAddress
    ) external returns (uint256) {
        // Check the beneficiary address
        if (
            beneficiary == address(0x00) ||
            beneficiary == address(this) ||
            beneficiary == msg.sender
        ) {
            revert FundU__InvalidBeneficiaryAddress();
        }
        // Check the deposit
        if (amountToDeposit == 0) {
            revert FundU__ZeroAmount();
        }
        uint256 startTime;

        // If start is zero the start time for the stream will be set to block.timestamp
        if (start == 0 || start < block.timestamp) {
            startTime = block.timestamp;
        } else {
            startTime = start;
        }
        if (stop <= startTime) {
            revert FundU__InvalidStopTime();
        }
        // Calculate the duration of the fund
        uint256 duration = stop - startTime;

        // This check is to ensure a rate per second, bigger than 0
        if (amountToDeposit < duration) {
            revert FundU__DepositSmallerThanTimeLeft();
        }

        // This check prevents decimals
        if (amountToDeposit % duration != 0) {
            revert FundU__DepositMustBeMultipleOfTime();
        }

        // Increment the id and creat the fund
        s_streamId++;

        StreamData storage stream = s_streamById[s_streamId];

        stream.deposit = amountToDeposit;
        stream.balanceLeft = amountToDeposit;
        stream.startTime = startTime;
        stream.stopTime = stop;
        stream.beneficiary = beneficiary;
        stream.owner = msg.sender;
        stream.tokenAddress = tokenAddress;
        stream.status = StreamStatus.Active;

        s_beneficiaryStreamsIds[beneficiary].push(s_streamId);
        s_ownerStreamsIds[msg.sender].push(s_streamId);
        // TODO Here I have to transfer to the vault´s contract
        // Transfer the tokens
        IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), amountToDeposit);

        emit NewStream(
            s_streamId,
            msg.sender,
            beneficiary,
            amountToDeposit,
            tokenAddress,
            startTime,
            stop
        );

        return s_streamId;
    }

    /**
     * @notice Pause an active stream
     * @param id Stream´s id
     * @dev It reverts if the caller is not the owner
     * @dev It reverts if the stream is not active
     */
    function paidPause(uint256 id) external onlyStreamOwner(id) {
        // Get the Stream
        StreamData storage stream = s_streamById[id];

        if (stream.status != StreamStatus.Active) {
            revert FundU__StreamIncorrectStatus();
        }

        stream.status = StreamStatus.PaidPaused;

        _withdrawPauseAndResume(id, stream.beneficiary);

        emit PauseStream(id, stream.beneficiary, true);
    }

    /**
     * @notice Pause an active stream
     * @param id Stream´s id
     * @dev It reverts if the caller is not the owner
     * @dev It reverts if the stream is not active
     */
    function unpaidPause(uint256 id) external onlyStreamOwner(id) {
        // Get the Stream
        StreamData storage stream = s_streamById[id];

        if (stream.status != StreamStatus.Active) {
            revert FundU__StreamIncorrectStatus();
        }

        stream.status = StreamStatus.UnpaidPaused;

        _withdrawPauseAndResume(id, stream.beneficiary);

        emit PauseStream(id, stream.beneficiary, false);
    }

    /**
     * @notice Resume a paused stream
     * @param id Stream´s id
     * @dev It reverts if the caller is not the owner
     * @dev It reverts if the stream is not active
     */
    function resumeStream(uint256 id) external onlyStreamOwner(id) {
        // Get the Stream
        StreamData storage stream = s_streamById[id];

        if (
            stream.status != StreamStatus.PaidPaused && stream.status != StreamStatus.UnpaidPaused
        ) {
            revert FundU__StreamIncorrectStatus();
        }

        if (stream.status == StreamStatus.UnpaidPaused) {
            _withdrawPauseAndResume(id, stream.owner);
        }

        if (stream.status != StreamStatus.Completed) {
            stream.status = StreamStatus.Active;

            emit ResumeStream(id, stream.beneficiary);
        }
    }

    /**
     * @notice Cancel an existing stream
     * @param id Stream´s id
     * @dev It reverts if the stream doesn´t exist
     * @dev It revert if the caller is not the owner
     * @dev It reverts if the transfer fails
     */
    function cancelStream(uint256 id) external nonReentrant onlyStreamOwner(id) {
        // Get the Stream
        StreamData storage stream = s_streamById[id];

        if (
            stream.status != StreamStatus.Active &&
            stream.status != StreamStatus.PaidPaused &&
            stream.status != StreamStatus.UnpaidPaused
        ) {
            revert FundU__StreamIncorrectStatus();
        }

        // Check the balances
        uint256 ownerRemainingBalance = balanceOfStreamOwner(id);
        uint256 beneficiaryRemainingBalance = balanceOfStreamBeneficiary(id);

        // Cancel the stream
        stream.status = StreamStatus.Canceled;

        // TODO This has to come from the vault´s contract
        // Transfer
        if (beneficiaryRemainingBalance > 0)
            IERC20(stream.tokenAddress).safeTransfer(
                stream.beneficiary,
                beneficiaryRemainingBalance
            );
        if (ownerRemainingBalance > 0)
            IERC20(stream.tokenAddress).safeTransfer(stream.owner, ownerRemainingBalance);

        emit CancelStream(
            id,
            stream.owner,
            stream.beneficiary,
            ownerRemainingBalance,
            beneficiaryRemainingBalance
        );
    }

    /**
     * @notice Allow the beneficiary to withdraw the proceeds
     * @dev It reverts if the stream doesn´t exist
     * @dev It revert if the caller is not the beneficiary
     * @dev It reverts if the amount is bigger than the balance left
     * @dev It reverts if the transfer fails
     */
    function withdrawAll() external nonReentrant {
        uint256[] memory beneficiaryIds = s_beneficiaryStreamsIds[msg.sender];
        for (uint i = 0; i < beneficiaryIds.length; i++) {
            uint256 id = beneficiaryIds[i];
            StreamData storage stream = s_streamById[id];

            if (stream.status != StreamStatus.Active) {
                revert FundU__StreamIncorrectStatus();
            }

            uint256 balance = balanceOfStreamBeneficiary(id);
            stream.balanceLeft = stream.balanceLeft - balance;
            if (stream.balanceLeft == 0) {
                stream.status = StreamStatus.Completed;
                emit Completed(id);
            }
            IERC20(stream.tokenAddress).safeTransfer(stream.beneficiary, balance);

            emit Withdraw(id, stream.beneficiary, balance);
        }
    }

    /**
     * @notice Allow the beneficiary to withdraw the proceeds
     * @param id Stream´s id
     * @param amount Amount to withdraw
     * @dev It reverts if the stream doesn´t exist
     * @dev It revert if the caller is not the beneficiary
     * @dev It reverts if the amount is bigger than the balance left
     * @dev It reverts if the transfer fails
     */
    function withdraw(uint256 id, uint256 amount) public nonReentrant onlyStreamBeneficiary(id) {
        if (amount <= 0) {
            revert FundU__ZeroAmount();
        }

        StreamData storage stream = s_streamById[id];

        if (stream.status != StreamStatus.Active) {
            revert FundU__StreamIncorrectStatus();
        }
        uint256 balance = balanceOfStreamBeneficiary(id);

        if (balance < amount) {
            revert FundU__InvalidWithdrawAmount();
        }

        stream.balanceLeft = stream.balanceLeft - amount;

        if (stream.balanceLeft == 0) {
            stream.status = StreamStatus.Completed;
            emit Completed(id);
        }

        IERC20(stream.tokenAddress).safeTransfer(stream.beneficiary, amount);

        emit Withdraw(id, stream.beneficiary, amount);
    }

    function _withdrawPauseAndResume(uint256 _id, address _who) private {
        StreamData storage stream = s_streamById[_id];
        uint256 _balance;

        if (_who == stream.beneficiary) {
            _balance = balanceOfStreamBeneficiary(_id);
        } else {
            _balance = balanceOfStreamOwner(_id);
        }

        stream.balanceLeft = stream.balanceLeft - _balance;

        if (stream.balanceLeft == 0) {
            stream.status = StreamStatus.Completed;
            emit Completed(_id);
        }

        IERC20(stream.tokenAddress).safeTransfer(_who, _balance);

        emit Withdraw(_id, stream.beneficiary, _balance);
    }

    /*** VIEW / PURE FUNCTIONS ***/
    /**
     * @notice Get the total number of streams
     */
    function getStreamsNumber() public view returns (uint256) {
        return s_streamId;
    }

    /**
     * @notice Get the Stream by giving the id
     * @param id the stream´s id
     * @return StreamData object
     */
    function getStreamById(uint256 id) public view returns (StreamData memory) {
        return s_streamById[id];
    }

    /**
     * @notice Get the Stream by giving the id
     * @param beneficiary the stream´s id
     * @return StreamData object
     */
    function getStreamByBeneficiary(address beneficiary) public view returns (uint256[] memory) {
        return s_beneficiaryStreamsIds[beneficiary];
    }

    /**
     * @notice Get the Stream by giving the id
     * @param beneficiary the stream´s id
     * @return StreamData object
     */
    function getBeneficiaryStreamCount(address beneficiary) public view returns (uint256) {
        return s_beneficiaryStreamsIds[beneficiary].length;
    }

    /**
     * @notice Get the Stream by giving the id
     * @param owner the stream´s id
     * @return StreamData object
     */
    function getStreamByOwner(address owner) public view returns (uint256[] memory) {
        return s_ownerStreamsIds[owner];
    }

    /**
     * @notice Get the Stream by giving the id
     * @param owner the stream´s id
     * @return StreamData object
     */
    function getOwnerStreamCount(address owner) public view returns (uint256) {
        return s_ownerStreamsIds[owner].length;
    }

    /**
     * @notice Calculate the balance
     * @param id Stream´s id
     * @return balance of beneficiary
     */
    function balanceOfStreamBeneficiary(uint256 id) public view returns (uint256 balance) {
        // Get the Stream
        StreamData memory stream = s_streamById[id];

        uint256 time = timePassed(id);
        uint256 duration = stream.stopTime - stream.startTime;
        uint256 rate = stream.deposit / duration;
        uint256 beneficiaryBalance = time * rate;

        // If the deposit is bigger than balanceLeft there has been some withdraws
        if (stream.deposit > stream.balanceLeft) {
            // So check how much the beneficiary has withdraw and calculate the actual balance
            uint256 withdraws = stream.deposit - stream.balanceLeft;
            beneficiaryBalance = beneficiaryBalance - withdraws;
        }

        return beneficiaryBalance;
    }

    /**
     * @notice Calculate the balance
     * @param id Stream´s id
     * @return balance of owner
     */
    function balanceOfStreamOwner(uint256 id) public view returns (uint256 balance) {
        // Get the Stream
        StreamData memory stream = s_streamById[id];
        uint256 beneficiaryBalance = balanceOfStreamBeneficiary(id);

        uint256 ownerBalance = stream.balanceLeft - beneficiaryBalance;
        return ownerBalance;
    }

    /**
     * @notice Calculates the time passed
     * @param id The stream´s id
     * @return time passed
     */
    function timePassed(uint256 id) public view returns (uint256 time) {
        StreamData memory stream = s_streamById[id];
        if (block.timestamp <= stream.startTime) return 0;
        if (block.timestamp < stream.stopTime) return block.timestamp - stream.startTime;
        return stream.stopTime - stream.startTime;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*** ERRORS ***/
error FundU__ZeroAmount();
error FundU__InvalidStopTime();
error FundU__StreamIncorrectStatus();
error FundU__InvalidWithdrawAmount();
error FundU__onlyStreamOwnerAllowed();
error FundU__InvalidBeneficiaryAddress();
error FundU__DepositSmallerThanTimeLeft();
error FundU__DepositMustBeMultipleOfTime();
error FundU__onlyStreamBeneficiaryAllowed();

/*** CONTRACT ***/
contract FundUtils {
    /*** STATE VARIABLES ***/

    enum StreamStatus {
        Active,
        PaidPaused,
        UnpaidPaused,
        Canceled,
        Completed
    }

    struct StreamData {
        uint256 deposit;
        uint256 balanceLeft; // If no withdraws must be equal to deposit
        uint256 startTime;
        uint256 stopTime;
        address beneficiary;
        address owner;
        address tokenAddress;
        StreamStatus status;
    }

    /*** EVENTS ***/
    event NewStream(
        uint256 indexed id,
        address indexed owner,
        address indexed beneficiary,
        uint256 depositedAmount,
        address token,
        uint256 startTime,
        uint256 stopTime
    );

    event PauseStream(uint256 indexed id, address indexed beneficiary, bool indexed paid);

    event ResumeStream(uint256 indexed id, address indexed beneficiary);

    event CancelStream(
        uint256 indexed id,
        address indexed owner,
        address indexed beneficiary,
        uint256 ownerRemainingBalance,
        uint256 beneficiaryRemainingBalance
    );

    event Withdraw(uint256 indexed id, address indexed beneficiary, uint256 amount);

    event Completed(uint256 indexed id);
}