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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

// Common Errors
error ZERO_ADDRESS();
error ZERO_AMOUNT();
error INPUT_ARRAY_MISMATCH();

// Config Errors
error TOO_HIGH_FEE();

// Oracle
error INVALID_ROUND(uint256 roundId);
error INVALID_ROUND_TIME(uint256 roundId, uint256 timestamp);
error NOT_ORACLE_ADMIN(address sender);
error NOT_ORACLE_WRITER(address sender);
error ORACLE_ALREADY_ADDED(address market);

// Vault
error NOT_FROM_MARKET(address caller);
error NO_DEPOSIT(address user);
error EXCEED_BALANCE(address user, uint256 amount);
error EXCEED_BETS(address player, uint256 amount);
error EXPIRED_CLAIM(address player);

// Market
error INVALID_TIMEFRAMES();
error INVALID_TIMEFRAME_ID(uint timeframeId);
error POS_ALREADY_CREATED(uint roundId, address account);
error CANNOT_CLAIM(uint roundId, address account);

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "../interfaces/binary/IBinaryMarket.sol";
import "../interfaces/binary/IBinaryVault.sol";
import "../interfaces/binary/IOracle.sol";
import "./BinaryErrors.sol";

// fixme I would personally get rid of roundid in oracle. Its redundant information. No need to have it in oracle and I would like if possible to switch oracle to chain link (to allow to write it like we can not that we will do it). That means we can use same oracle for perps. We want to configure perps from existing contracts we have. Less code we need to test and maintain.
// fixme decide if use error constants or error string, not both. Better to use "ERROR_LIKE_THIS" then "like this"
contract BinaryMarket is
    Pausable,
    IBinaryMarket
{
    using SafeERC20 for IERC20;

    // fixme do we real need all fields to be uint256?
    // legendary, TBH, not sure.. but I think most of them should be.
    struct Round {
        uint256 epoch;
        uint256 startBlock;
        uint256 lockBlock;
        uint256 closeBlock;
        uint256 lockPrice;
        uint256 closePrice;
        uint256 lockOracleId;
        uint256 closeOracleId;
        uint256 totalAmount;
        uint256 bullAmount;
        uint256 bearAmount;
        bool oracleCalled;
    }

    struct BetInfo {
        Position position;
        uint256 amount;
        bool claimed; // default false
    }

    /// @dev Market Data
    string public marketName;
    IOracle public oracle;
    IBinaryVault public vault;

    IERC20 public underlyingToken;

    /// @dev Timeframes supported in this market.
    TimeFrame[] public timeframes;

    /// @dev Rounds per timeframe
    mapping(uint8 => mapping(uint256 => Round)) public rounds; // timeframe id => round id => round

    /// @dev bet info per user and round
    mapping(uint8 => mapping(uint256 => mapping(address => BetInfo)))
        public ledger; // timeframe id => round id => address => bet info

    // @dev user rounds per timeframe
    mapping(uint8 => mapping(address => uint256[])) public userRounds; // timeframe id => user address => round ids

    /// @dev current round id per timeframe.
    mapping(uint8 => uint256) public currentEpochs; // timeframe id => current round id

    /// @dev This should be modified
    uint256 public minBetAmount;
    uint256 public oracleLatestRoundId;
    uint256 public genesisStartBlockTimestamp;
    uint256 public genesisStartBlockNumber;

    // fixme why admin is not from ownable, why operator is not from accesscontrol?
    // legendary - We aimed to create all markets from market mananger. 
    // In this case owner will be market manager, so we cannot control market directly. 
    // I don't think we need to do all admin operations through market manager. What do you think?
    address public adminAddress;
    address public operatorAddress;

    /// @dev default false
    bool public genesisStartOnce;
    /// @dev timeframe id => genesis locked? default false
    mapping(uint8 => bool) public genesisLockOnces;

    event PositionOpened(
        string indexed marketName,
        address user,
        uint256 amount,
        uint8 timeframeId,
        uint256 roundId,
        Position position
    );

    event Claimed(
        string indexed marketName,
        address indexed user,
        uint8 timeframeId,
        uint256 indexed roundId,
        uint256 amount
    );

    event StartRound(uint8 indexed timeframeId, uint256 indexed epoch);
    event LockRound(
        uint8 indexed timeframeId,
        uint256 indexed epoch,
        uint256 indexed oracleRoundId,
        uint256 price
    );
    event EndRound(
        uint8 indexed timeframeId,
        uint256 indexed epoch,
        uint256 indexed oracleRoundId,
        uint256 price
    );

    event OracleChanged(
        address indexed oldOracle,
        address indexed newOracle
    );
    event MarketNameChanged(
        string oldName,
        string newName
    );
    event AdminChanged(
        address indexed oldAdmin,
        address indexed newAdmin
    );
    event OperatorChanged(
        address indexed oldOperator,
        address indexed newOperator
    );

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "admin: wut?");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operatorAddress, "operator: wut?");
        _;
    }

    modifier onlyAdminOrOperator() {
        require(
            msg.sender == adminAddress || msg.sender == operatorAddress,
            "admin | operator: wut?"
        );
        _;
    }

    constructor(
        IOracle oracle_,
        IBinaryVault vault_,
        string memory marketName_,
        TimeFrame[] memory timeframes_,
        address adminAddress_,
        address operatorAddress_,
        uint256 minBetAmount_
    ) {
        if (address(oracle_) == address(0)) revert ZERO_ADDRESS();
        if (address(vault_) == address(0)) revert ZERO_ADDRESS();
        if (timeframes_.length == 0) revert INVALID_TIMEFRAMES();

        oracle = oracle_;
        vault = vault_;

        marketName = marketName_;
        adminAddress = adminAddress_;
        operatorAddress = operatorAddress_;
        minBetAmount = minBetAmount_;

        for (uint256 i = 0; i < timeframes_.length; i = i + 1) {
            timeframes.push(timeframes_[i]);
        }

        underlyingToken = vault.underlyingToken();
    }

    /**
     * @notice Set oracle of underlying token of this market
     * @dev Only owner can set the oracle
     * @param oracle_ New oracle address to set
     */
    function setOracle(IOracle oracle_) external onlyAdmin {
        if (address(oracle_) == address(0)) revert ZERO_ADDRESS();
        emit OracleChanged(address(oracle), address(oracle_));
        oracle = oracle_;
    }

    /**
     * @notice Set name of this market
     * @dev Only owner can set name
     * @param name_ New name to set
     */
    function setName(string memory name_) external onlyAdmin {
        emit MarketNameChanged(marketName, name_);
        marketName = name_;
    }

    /**
     * @notice Set new admin of this market
     * @dev Only owner can set new admin
     * @param admin_ New admin to set
     */
    function setAdmin(address admin_) external onlyAdmin {
        require(admin_ != address(0), "Zero address");
        emit AdminChanged(adminAddress, admin_);
        adminAddress = admin_;
    }

    /**
     * @notice Set new operator of this market
     * @dev Only admin can set new operator
     * @param operator_ New operator to set
     */
    function setOperator(address operator_) external onlyAdmin {
        require(operator_ != address(0), "Zero address");
        emit OperatorChanged(operatorAddress, operator_);
        operatorAddress = operator_;
    }

    /**
     * @notice Set timeframes of this market
     * @dev Only admin can set new timeframe, format genesis
     * @param timeframes_ New timeframe to set
     */
    function setTimeframes(TimeFrame[] memory timeframes_) external onlyAdmin {
        require(timeframes_.length > 0, "Invalid length");
        genesisStartOnce = false;
        delete timeframes;
        for (uint256 i = 0; i < timeframes_.length; i = i + 1) {
            timeframes.push(timeframes_[i]);
            genesisLockOnces[timeframes_[i].id] = false;
        }
    }

    /**
     * @dev Get latest recorded price from oracle
     */
    function _getPriceFromOracle() internal returns (uint256, uint256, uint256) {
        (uint256 roundId, uint256 timestamp, uint256 price, ) = oracle.latestRoundData();
        require(
            roundId > oracleLatestRoundId,
            "Oracle update roundId must be larger than oracleLatestRoundId"
        );
        oracleLatestRoundId = roundId;
        return (roundId, price, timestamp);
    }

    function _writeOraclePrice(uint256 timestamp, uint256 price) internal {
        (uint256 roundId, , , ) = oracle.latestRoundData();
        oracle.writePrice(roundId + 1, timestamp, price);
    }

    /**
     * @dev Start genesis round
     */
    function genesisStartRound() external onlyOperator whenNotPaused {
        require(!genesisStartOnce, "Can only run genesisStartRound once");
        genesisStartBlockTimestamp = block.timestamp;
        genesisStartBlockNumber = block.number;
        for (uint256 i = 0; i < timeframes.length; i = i + 1) {
            currentEpochs[timeframes[i].id] = currentEpochs[timeframes[i].id] + 1;
            _startRound(timeframes[i].id, currentEpochs[timeframes[i].id]);

        }
        genesisStartOnce = true;
    }

    /**
     * @dev Lock genesis round
     */
    function genesisLockRound(uint8 timeframeId) external onlyOperator whenNotPaused {
        require(genesisStartOnce, "Can only run after genesisStartRound is triggered");
        require(!genesisLockOnces[timeframeId], "Can only run genesisLockRound once");
        
        _writeOraclePrice(block.timestamp, 1 wei);
        (uint256 currentRoundId, uint256 currentPrice, ) = _getPriceFromOracle();

        _safeLockRound(timeframeId, currentEpochs[timeframeId], currentRoundId, currentPrice);
        currentEpochs[timeframeId] = currentEpochs[timeframeId] + 1;
        _startRound(timeframeId, currentEpochs[timeframeId]);
        genesisLockOnces[timeframeId] = true;
    }


    // fixme what if I have 2m and 3m timeframes? I would like to not depend on having 1m tf.
    // legendary - Our bet round doesn't depend on timeframe specifician, I think we can use any timeframe 2m or 3m. Just need to determine how to call this function from backend.
    /**
     * @dev Start the next round n, lock price for round n-1, end round n-2
     */
    function executeRound(
        uint8[] memory timeframeIds,
        uint256 price
    ) external onlyOperator whenNotPaused {
        require(
            genesisStartOnce,
            "Can only run after genesisStartRound is triggered"
        );
        uint256 timestamp = block.timestamp;
        // Update oracle price
        _writeOraclePrice(timestamp, price);

        (uint256 currentRoundId, uint256 currentPrice, ) = _getPriceFromOracle();

        for (uint8 i = 0; i < timeframeIds.length; i = i + 1) {
            uint8 timeframeId = timeframeIds[i];
            if(genesisLockOnces[timeframeId]) {

                uint256 currentEpoch = currentEpochs[timeframeId];
                // CurrentEpoch refers to previous round (n-1)
                _safeLockRound(
                    timeframeId,
                    currentEpoch,
                    currentRoundId,
                    currentPrice
                );
                _safeEndRound(
                    timeframeId,
                    currentEpoch - 1,
                    currentRoundId,
                    currentPrice
                );

                // Increment currentEpoch to current round (n)
                currentEpoch = currentEpoch + 1;
                currentEpochs[timeframeId] = currentEpoch;
                _safeStartRound(timeframeId, currentEpoch);
            }

        }
    }

    /**
     * @dev Start round
     * Previous round n-2 must end
     */
    function _safeStartRound(uint8 timeframeId, uint256 epoch) internal {
        require(
            block.number >= rounds[timeframeId][epoch - 2].closeBlock,
            "Can only start new round after round n-2 closeBlock"
        );
        _startRound(timeframeId, epoch);
    }

    function _startRound(uint8 timeframeId, uint256 epoch) internal {
        Round storage round = rounds[timeframeId][epoch];
        round.startBlock = block.number;
        round.lockBlock = block.number + timeframes[timeframeId].intervalBlocks;
        round.closeBlock = block.number + timeframes[timeframeId].intervalBlocks * 2;
        round.epoch = epoch;
        round.totalAmount = 0;

        emit StartRound(timeframeId, epoch);
    }

    /**
     * @dev Lock round
     */
    function _safeLockRound(
        uint8 timeframeId,
        uint256 epoch,
        uint256 roundId,
        uint256 price
    ) internal {
        require(
            rounds[timeframeId][epoch].startBlock != 0,
            "Can only lock round after round has started"
        );
        require(
            block.number >= rounds[timeframeId][epoch].lockBlock,
            "Can only lock round after lockBlock"
        );
        _lockRound(timeframeId, epoch, roundId, price);
    }

    function _lockRound(
        uint8 timeframeId,
        uint256 epoch,
        uint256 roundId,
        uint256 price
    ) internal {
        Round storage round = rounds[timeframeId][epoch];
        round.lockPrice = price;
        round.lockOracleId = roundId;

        emit LockRound(timeframeId, epoch, roundId, round.lockPrice);
    }

    /**
     * @dev End round
     */
    function _safeEndRound(
        uint8 timeframeId,
        uint256 epoch,
        uint256 roundId,
        uint256 price
    ) internal {
        require(
            rounds[timeframeId][epoch].lockBlock != 0,
            "Can only end round after round has locked"
        );
        require(
            block.number >= rounds[timeframeId][epoch].closeBlock,
            "Can only end round after closeBlock"
        );
        _endRound(timeframeId, epoch, roundId, price);
    }

    function _endRound(
        uint8 timeframeId,
        uint256 epoch,
        uint256 roundId,
        uint256 price
    ) internal {
        Round storage round = rounds[timeframeId][epoch];
        round.closePrice = price;
        round.closeOracleId = roundId;
        round.oracleCalled = true;

        emit EndRound(timeframeId, epoch, roundId, round.closePrice);
    }

    /**
     * @dev Bet bear position
     * @param amount Bet amount
     * @param timeframeId id of 1m/5m/10m
     * @param position bull/bear
     */
    function openPosition(
        uint256 amount,
        uint8 timeframeId,
        Position position
    ) external whenNotPaused {
        uint256 currentEpoch = currentEpochs[timeframeId];
        underlyingToken.safeTransferFrom(msg.sender, address(vault), amount);

        require(_bettable(timeframeId, currentEpoch), "Round not bettable");
        require(
            amount >= minBetAmount,
            "Bet amount must be greater than minBetAmount"
        );
        require(
            ledger[timeframeId][currentEpoch][msg.sender].amount == 0,
            "Can only bet once per round"
        );

        // Update round data
        Round storage round = rounds[timeframeId][currentEpoch];
        round.totalAmount = round.totalAmount + amount;
        
        if (position == Position.Bear) {
            round.bearAmount = round.bearAmount + amount;
        } else {
            round.bullAmount = round.bullAmount + amount;
        }

        // Update user data
        BetInfo storage betInfo = ledger[timeframeId][currentEpoch][msg.sender];
        betInfo.position = position;
        betInfo.amount = amount;
        userRounds[timeframeId][msg.sender].push(currentEpoch);

        emit PositionOpened(
            marketName,
            msg.sender,
            amount,
            timeframeId,
            currentEpoch,
            position
        );
    }

    function _claim(uint8 timeframeId, uint256 epoch) internal {
        require(
            rounds[timeframeId][epoch].startBlock != 0,
            "Round has not started"
        );
        require(
            block.number > rounds[timeframeId][epoch].closeBlock,
            "Round has not ended"
        );
        require(
            !ledger[timeframeId][epoch][msg.sender].claimed,
            "Rewards claimed"
        );

        uint256 rewardAmount = 0;
        BetInfo storage betInfo = ledger[timeframeId][epoch][msg.sender];

        // Round valid, claim rewards
        if (rounds[timeframeId][epoch].oracleCalled) {
            require(
                isClaimable(timeframeId, epoch, msg.sender),
                "Not eligible for claim"
            );
            rewardAmount = betInfo.amount * 2;
        }
        // Round invalid, refund bet amount
        else {
            require(
                refundable(timeframeId, epoch, msg.sender),
                "Not eligible for refund"
            );

            rewardAmount = betInfo.amount;
        }

        betInfo.claimed = true;
        vault.claimBettingRewards(msg.sender, rewardAmount);

        emit Claimed(marketName, msg.sender, timeframeId, epoch, rewardAmount);
    }

    /**
     * @notice claim winning rewards
     * @param timeframeId Timeframe ID to claim winning rewards
     * @param epoch round id
     */
    function claim(uint8 timeframeId, uint256 epoch) external {
        _claim(timeframeId, epoch);
    }

    /**
     * @notice Batch claim winning rewards
     * @param timeframeIds Timeframe IDs to claim winning rewards
     * @param epochs round ids
     */
    function claimBatch(uint8[] memory timeframeIds, uint256[][] memory epochs) external {
        require(timeframeIds.length == epochs.length, "Invalid array length");

        for (uint256 i = 0; i < timeframeIds.length; i = i + 1) {
            uint8 timeframeId = timeframeIds[i];
            for (uint256 j = 0; j < epochs[i].length; j = j + 1) {
                _claim(timeframeId, epochs[i][j]);
            }
        }
    }

    /**
     * @dev Get the claimable stats of specific epoch and user account
     */
    function isClaimable(
        uint8 timeframeId,
        uint256 epoch,
        address user
    ) public view returns (bool) {
        BetInfo memory betInfo = ledger[timeframeId][epoch][user];
        Round memory round = rounds[timeframeId][epoch];
        if (round.lockPrice == round.closePrice) {
            return false;
        }
        return
            round.oracleCalled &&
            betInfo.amount > 0 &&
            !betInfo.claimed && 
            ((round.closePrice > round.lockPrice &&
                betInfo.position == Position.Bull) ||
                (round.closePrice < round.lockPrice &&
                    betInfo.position == Position.Bear));
    }

    /**
     * @dev Determine if a round is valid for receiving bets
     * Round must have started and locked
     * Current block must be within startBlock and closeBlock
     */
    function _bettable(uint8 timeframeId, uint256 epoch)
        internal
        view
        returns (bool)
    {
        // fixme I cannot bet if it's locked
        // fixme here I want a safeguard that I cannot bet on such round which should have close price at time which already gone on block.timestamp 
        // legendary - lockblock !=0 means this round should already be started. (Not live yet, just ready to accept bets), and lockPrice == 0 means this block should not be locked yet (still acceptable bet)
        // So once round starts, it can accept bets till it will be locked. (till executeRound called from backend)
        return
            rounds[timeframeId][epoch].startBlock != 0 &&
            rounds[timeframeId][epoch].lockBlock != 0 &&
            rounds[timeframeId][epoch].lockPrice == 0 &&
            block.number > rounds[timeframeId][epoch].startBlock;
    }

    /**
     * @dev Get the refundable stats of specific epoch and user account
     */
    function refundable(
        uint8 timeframeId,
        uint256 epoch,
        address user
    ) public view returns (bool) {
        // fixme now imagine that people will refund their lost bets. We need to do some interval between close timestamp and us writing close price. Let's say you can refund if we don't write price within 30minutes after close timestamp.
        // legendary - Yes, I agree. We can set buffer block for each timeframe.
        BetInfo memory betInfo = ledger[timeframeId][epoch][user];
        Round memory round = rounds[timeframeId][epoch];
        return
            !round.oracleCalled &&
            block.number > round.closeBlock + timeframes[timeframeId].bufferBlocks &&
            betInfo.amount != 0;
    }

    /**
    * @dev Pause/unpause
    */

    function setPause(bool value) external onlyOperator {
        if (value) {
            _pause();
        } else {
            genesisStartOnce = false;
            for (uint i; i < timeframes.length; i = i + 1) {
                genesisLockOnces[timeframes[i].id] = false;
            }
            _unpause();
        }
    }

    
    /**
     * @dev set minBetAmount
     * callable by admin
     */
    function setMinBetAmount(uint256 _minBetAmount) external onlyAdmin {
        minBetAmount = _minBetAmount;
    }

    function isNecessaryToExecute(uint8 timeframeId) public view returns(bool) {
        if (!genesisLockOnces[timeframeId] || !genesisStartOnce) {
            return false;
        }

        uint256 currentEpoch = currentEpochs[timeframeId];
        Round memory round = rounds[timeframeId][currentEpoch];
        Round memory prevRound = rounds[timeframeId][currentEpoch - 1];

        bool lockable = round.startBlock != 0 && round.lockPrice == 0 && block.number >= round.lockBlock;
        bool closable = prevRound.lockBlock !=0 && prevRound.closePrice == 0 && !prevRound.oracleCalled && block.number >= prevRound.closeBlock;

        return lockable && closable && (prevRound.totalAmount > 0 || round.totalAmount > 0);
    }


    // fixme why this not returning array of uint8?
    // legendary: OK Agree.
    /**
        @dev check if bet is active
     */

    function getExecutableTimeframes() external view returns(uint8[] memory result, uint256 count) {
        result = new uint8[](timeframes.length);

        for (uint256 i = 0; i < timeframes.length; i = i + 1) {
            uint8 timeframeId = timeframes[i].id;

            if (isNecessaryToExecute(timeframeId)) {
                result[count] = timeframeId;
                count = count + 1;
            }
        }
    }

    /**
     * @dev Return round epochs that a user has participated in specific timeframe
     */
    function getUserRounds(
        uint8 timeframeId,
        address user,
        uint256 cursor,
        uint256 size
    ) external view returns (uint256[] memory, uint256) {
        uint256 length = size;
        if (length > userRounds[timeframeId][user].length - cursor) {
            length = userRounds[timeframeId][user].length - cursor;
        }

        uint256[] memory values = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            values[i] = userRounds[timeframeId][user][cursor + i];
        }

        return (values, cursor + length);
    }

    /**
     * @dev Caluclate current round based on genesis timestamp and block number
     * @param timeframeId timeframe id what we want to get round number
    */
    function getCurrentUserRoundNumber(uint8 timeframeId) 
        external 
        view 
        returns(uint256 roundFromBlockNumber, uint256 roundFromBlockTime )
    {
        roundFromBlockNumber = (block.number - genesisStartBlockNumber) / timeframes[timeframeId].intervalBlocks;
        roundFromBlockTime = (block.timestamp - genesisStartBlockTimestamp) / timeframes[timeframeId].interval;
    }

    /**
    * @dev Check if round is bettable
    */
    function isBettable(uint8 timeframeId, uint256 epoch)
        external
        view
        returns(bool)
    {
        return _bettable(timeframeId, epoch);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface IBinaryMarket {
    enum Position {
        Bull,
        Bear
    }
    
    struct TimeFrame {
        uint8 id;
        uint256 interval;
        uint256 intervalBlocks;
        uint256 bufferBlocks;
    }

    function openPosition(
        uint256 amount,
        uint8 timeframe,
        Position position
    ) external;

    function claim(uint8 timeframeId, uint256 epoch) external;

    function claimBatch(uint8[] memory timeframeIds, uint256[][] memory epochs)
        external;

    function executeRound(
        uint8[] memory timeframeIds,
        uint256 price
    ) external;

    function getExecutableTimeframes() external view returns(uint8[] memory, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBinaryVault {
    function underlyingToken() external view returns (IERC20);

    function whitelistedMarkets(address) external view returns (bool);

    function claimBettingRewards(address to, uint256 amount) external;

    /**
    * @dev Supply underlying token to this vault (new position)
    * @param user Receipt for share
    * @param amount Underlying token amount
    */
    function addNewLiquidityPosition(address user, uint256 amount) external;

    /**
    * @dev Add liquidity. Burn existing token, mint new one.
    * @param user Receipt for share
    * @param amount Underlying token amount
    * @param tokenId nft id to be added liquidity. This should be existing id.
    */
    function addLiquidityPosition(address user, uint256 amount, uint256 tokenId) external;

    /**
    * @dev Merge tokens into one, Burn existing ones and mint new one
    * @param user receipent
    * @param tokenIds Token ids which will be merged
    */
    function mergePositions(address user, uint256[] memory tokenIds) external;

     /**
    * @dev Merge all owned nfts into new one
    */
    function mergeAllPositions(address user) external;

    /**
    * @dev Remove liquidity from position
    * @param user Receipent
    * @param tokenId position that where remove liquidity from
    * @param shareAmount amount of share
    */
    function removeLiquidityPosition(address user, uint256 tokenId, uint256 shareAmount) external;

    /**
    *@dev Remove share, and merge to one
    *@param user receipent
    *@param shareAmount Share amount
    */
    function removeLiquidity(address user, uint256 shareAmount) external;

    /**
    * @dev Get shares of user.
    */
    function getSharesOfUser(address user) external returns(uint256 shares, uint256 underlyingTokenAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface IOracle {
    function writePrice(
        uint256 roundId,
        uint256 timestamp,
        uint256 price
    ) external;

    function writeBatchPrices(
        uint256[] memory roundIds,
        uint256[] memory timestamps,
        uint256[] memory prices
    ) external;

    function getRoundData(uint256 roundId)
        external
        view
        returns (uint256 timestamp, uint256 price);
    
    function latestRoundData()
        external
        view
        returns (uint256 roundId, uint256 timestamp, uint256 price, address writer);
}