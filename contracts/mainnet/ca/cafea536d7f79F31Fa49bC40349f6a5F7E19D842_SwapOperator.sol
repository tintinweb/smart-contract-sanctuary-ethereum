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

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-v4/token/ERC20/IERC20.sol";

/// @title Gnosis Protocol v2 Order Library
/// @author Gnosis Developers
library GPv2Order {
    /// @dev The complete data for a Gnosis Protocol order. This struct contains
    /// all order parameters that are signed for submitting to GP.
    struct Data {
        IERC20 sellToken;
        IERC20 buyToken;
        address receiver;
        uint256 sellAmount;
        uint256 buyAmount;
        uint32 validTo;
        bytes32 appData;
        uint256 feeAmount;
        bytes32 kind;
        bool partiallyFillable;
        bytes32 sellTokenBalance;
        bytes32 buyTokenBalance;
    }

    /// @dev The order EIP-712 type hash for the [`GPv2Order.Data`] struct.
    ///
    /// This value is pre-computed from the following expression:
    /// ```
    /// keccak256(
    ///     "Order(" +
    ///         "address sellToken," +
    ///         "address buyToken," +
    ///         "address receiver," +
    ///         "uint256 sellAmount," +
    ///         "uint256 buyAmount," +
    ///         "uint32 validTo," +
    ///         "bytes32 appData," +
    ///         "uint256 feeAmount," +
    ///         "string kind," +
    ///         "bool partiallyFillable" +
    ///         "string sellTokenBalance" +
    ///         "string buyTokenBalance" +
    ///     ")"
    /// )
    /// ```
    bytes32 internal constant TYPE_HASH =
        hex"d5a25ba2e97094ad7d83dc28a6572da797d6b3e7fc6663bd93efb789fc17e489";

    /// @dev The marker value for a sell order for computing the order struct
    /// hash. This allows the EIP-712 compatible wallets to display a
    /// descriptive string for the order kind (instead of 0 or 1).
    ///
    /// This value is pre-computed from the following expression:
    /// ```
    /// keccak256("sell")
    /// ```
    bytes32 internal constant KIND_SELL =
        hex"f3b277728b3fee749481eb3e0b3b48980dbbab78658fc419025cb16eee346775";

    /// @dev The OrderKind marker value for a buy order for computing the order
    /// struct hash.
    ///
    /// This value is pre-computed from the following expression:
    /// ```
    /// keccak256("buy")
    /// ```
    bytes32 internal constant KIND_BUY =
        hex"6ed88e868af0a1983e3886d5f3e95a2fafbd6c3450bc229e27342283dc429ccc";

    /// @dev The TokenBalance marker value for using direct ERC20 balances for
    /// computing the order struct hash.
    ///
    /// This value is pre-computed from the following expression:
    /// ```
    /// keccak256("erc20")
    /// ```
    bytes32 internal constant BALANCE_ERC20 =
        hex"5a28e9363bb942b639270062aa6bb295f434bcdfc42c97267bf003f272060dc9";

    /// @dev The TokenBalance marker value for using Balancer Vault external
    /// balances (in order to re-use Vault ERC20 approvals) for computing the
    /// order struct hash.
    ///
    /// This value is pre-computed from the following expression:
    /// ```
    /// keccak256("external")
    /// ```
    bytes32 internal constant BALANCE_EXTERNAL =
        hex"abee3b73373acd583a130924aad6dc38cfdc44ba0555ba94ce2ff63980ea0632";

    /// @dev The TokenBalance marker value for using Balancer Vault internal
    /// balances for computing the order struct hash.
    ///
    /// This value is pre-computed from the following expression:
    /// ```
    /// keccak256("internal")
    /// ```
    bytes32 internal constant BALANCE_INTERNAL =
        hex"4ac99ace14ee0a5ef932dc609df0943ab7ac16b7583634612f8dc35a4289a6ce";

    /// @dev Marker address used to indicate that the receiver of the trade
    /// proceeds should the owner of the order.
    ///
    /// This is chosen to be `address(0)` for gas efficiency as it is expected
    /// to be the most common case.
    address internal constant RECEIVER_SAME_AS_OWNER = address(0);

    /// @dev The byte length of an order unique identifier.
    uint256 internal constant UID_LENGTH = 56;

    /// @dev Returns the actual receiver for an order. This function checks
    /// whether or not the [`receiver`] field uses the marker value to indicate
    /// it is the same as the order owner.
    ///
    /// @return receiver The actual receiver of trade proceeds.
    function actualReceiver(Data memory order, address owner)
        internal
        pure
        returns (address receiver)
    {
        if (order.receiver == RECEIVER_SAME_AS_OWNER) {
            receiver = owner;
        } else {
            receiver = order.receiver;
        }
    }

    /// @dev Return the EIP-712 signing hash for the specified order.
    ///
    /// @param order The order to compute the EIP-712 signing hash for.
    /// @param domainSeparator The EIP-712 domain separator to use.
    /// @return orderDigest The 32 byte EIP-712 struct hash.
    function hash(Data memory order, bytes32 domainSeparator)
        internal
        pure
        returns (bytes32 orderDigest)
    {
        bytes32 structHash;

        // NOTE: Compute the EIP-712 order struct hash in place. As suggested
        // in the EIP proposal, noting that the order struct has 10 fields, and
        // including the type hash `(12 + 1) * 32 = 416` bytes to hash.
        // <https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#rationale-for-encodedata>
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let dataStart := sub(order, 32)
            let temp := mload(dataStart)
            mstore(dataStart, TYPE_HASH)
            structHash := keccak256(dataStart, 416)
            mstore(dataStart, temp)
        }

        // NOTE: Now that we have the struct hash, compute the EIP-712 signing
        // hash using scratch memory past the free memory pointer. The signing
        // hash is computed from `"\x19\x01" || domainSeparator || structHash`.
        // <https://docs.soliditylang.org/en/v0.7.6/internals/layout_in_memory.html#layout-in-memory>
        // <https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#specification>
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let freeMemoryPointer := mload(0x40)
            mstore(freeMemoryPointer, "\x19\x01")
            mstore(add(freeMemoryPointer, 2), domainSeparator)
            mstore(add(freeMemoryPointer, 34), structHash)
            orderDigest := keccak256(freeMemoryPointer, 66)
        }
    }

    /// @dev Packs order UID parameters into the specified memory location. The
    /// result is equivalent to `abi.encodePacked(...)` with the difference that
    /// it allows re-using the memory for packing the order UID.
    ///
    /// This function reverts if the order UID buffer is not the correct size.
    ///
    /// @param orderUid The buffer pack the order UID parameters into.
    /// @param orderDigest The EIP-712 struct digest derived from the order
    /// parameters.
    /// @param owner The address of the user who owns this order.
    /// @param validTo The epoch time at which the order will stop being valid.
    function packOrderUidParams(
        bytes memory orderUid,
        bytes32 orderDigest,
        address owner,
        uint32 validTo
    ) internal pure {
        require(orderUid.length == UID_LENGTH, "GPv2: uid buffer overflow");

        // NOTE: Write the order UID to the allocated memory buffer. The order
        // parameters are written to memory in **reverse order** as memory
        // operations write 32-bytes at a time and we want to use a packed
        // encoding. This means, for example, that after writing the value of
        // `owner` to bytes `20:52`, writing the `orderDigest` to bytes `0:32`
        // will **overwrite** bytes `20:32`. This is desirable as addresses are
        // only 20 bytes and `20:32` should be `0`s:
        //
        //        |           1111111111222222222233333333334444444444555555
        //   byte | 01234567890123456789012345678901234567890123456789012345
        // -------+---------------------------------------------------------
        //  field | [.........orderDigest..........][......owner.......][vT]
        // -------+---------------------------------------------------------
        // mstore |                         [000000000000000000000000000.vT]
        //        |                     [00000000000.......owner.......]
        //        | [.........orderDigest..........]
        //
        // Additionally, since Solidity `bytes memory` are length prefixed,
        // 32 needs to be added to all the offsets.
        //
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(add(orderUid, 56), validTo)
            mstore(add(orderUid, 52), owner)
            mstore(add(orderUid, 32), orderDigest)
        }
    }

    /// @dev Extracts specific order information from the standardized unique
    /// order id of the protocol.
    ///
    /// @param orderUid The unique identifier used to represent an order in
    /// the protocol. This uid is the packed concatenation of the order digest,
    /// the validTo order parameter and the address of the user who created the
    /// order. It is used by the user to interface with the contract directly,
    /// and not by calls that are triggered by the solvers.
    /// @return orderDigest The EIP-712 signing digest derived from the order
    /// parameters.
    /// @return owner The address of the user who owns this order.
    /// @return validTo The epoch time at which the order will stop being valid.
    function extractOrderUidParams(bytes calldata orderUid)
        internal
        pure
        returns (
            bytes32 orderDigest,
            address owner,
            uint32 validTo
        )
    {
        require(orderUid.length == UID_LENGTH, "GPv2: invalid uid");

        // Use assembly to efficiently decode packed calldata.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            orderDigest := calldataload(orderUid.offset)
            owner := shr(96, calldataload(add(orderUid.offset, 32)))
            validTo := shr(224, calldataload(add(orderUid.offset, 52)))
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface IEnzymeFundValueCalculatorRouter {
  function calcGrossShareValue(address _vaultProxy)
  external
  returns (address denominationAsset_, uint256 grossShareValue_);

  function calcNetShareValue(address _vaultProxy)
  external
  returns (address denominationAsset_, uint256 netShareValue_);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface IPolicyManager {
  function updatePolicySettingsForFund(
    address _comptrollerProxy,
    address _policy,
    bytes calldata _settingsData
  ) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface IEnzymeV4Comptroller {
    function getDenominationAsset() external view returns (address denominationAsset_);
    function redeemSharesForSpecificAssets(
        address _recipient,
        uint256 _sharesQuantity,
        address[] calldata _payoutAssets,
        uint256[] calldata _payoutAssetPercentages
    ) external returns (uint256[] memory payoutAmounts_);

  function vaultCallOnContract(
    address _contract,
    bytes4 _selector,
    bytes calldata _encodedArgs
  ) external;

  function buyShares(uint _investmentAmount, uint _minSharesQuantity) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface IEnzymeV4Vault {
  function getAccessor() external view returns (address);

  function getOwner() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface ICowSettlement {
  function setPreSignature(bytes calldata orderUid, bool signed) external;

  function filledAmount(bytes calldata orderUid) external view returns (uint256);

  function vaultRelayer() external view returns (address);

  function domainSeparator() external view returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface IERC20Detailed {

  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);

  function decimals() external view returns (uint8);

  function symbol() external view returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface INXMMaster {

  function tokenAddress() external view returns (address);

  function owner() external view returns (address);

  function emergencyAdmin() external view returns (address);

  function masterInitialized() external view returns (bool);

  function isInternal(address _add) external view returns (bool);

  function isPause() external view returns (bool check);

  function isMember(address _add) external view returns (bool);

  function checkIsAuthToGoverned(address _add) external view returns (bool);

  function getLatestAddress(bytes2 _contractName) external view returns (address payable contractAddress);

  function contractAddresses(bytes2 code) external view returns (address payable);

  function upgradeMultipleContracts(
    bytes2[] calldata _contractCodes,
    address payable[] calldata newAddresses
  ) external;

  function removeContracts(bytes2[] calldata contractCodesToRemove) external;

  function addNewInternalContracts(
    bytes2[] calldata _contractCodes,
    address payable[] calldata newAddresses,
    uint[] calldata _types
  ) external;

  function updateOwnerParameters(bytes8 code, address payable val) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

import "./IPriceFeedOracle.sol";

struct SwapDetails {
  uint104 minAmount;
  uint104 maxAmount;
  uint32 lastSwapTime;
  // 2 decimals of precision. 0.01% -> 0.0001 -> 1e14
  uint16 maxSlippageRatio;
}

struct Asset {
  address assetAddress;
  bool isCoverAsset;
  bool isAbandoned;
}

interface IPool {

  function getAsset(uint assetId) external view returns (Asset memory);

  function getAssets() external view returns (Asset[] memory);

  function buyNXM(uint minTokensOut) external payable;

  function sellNXM(uint tokenAmount, uint minEthOut) external;

  function sellNXMTokens(uint tokenAmount) external returns (bool);

  function transferAssetToSwapOperator(address asset, uint amount) external;

  function setSwapDetailsLastSwapTime(address asset, uint32 lastSwapTime) external;

  function getAssetSwapDetails(address assetAddress) external view returns (SwapDetails memory);

  function getNXMForEth(uint ethAmount) external view returns (uint);

  function sendPayout(uint assetIndex, address payable payoutAddress, uint amount) external;

  function upgradeCapitalPool(address payable newPoolAddress) external;

  function priceFeedOracle() external view returns (IPriceFeedOracle);

  function getPoolValueInEth() external view returns (uint);

  function getEthForNXM(uint nxmAmount) external view returns (uint ethAmount);

  function calculateEthForNXM(uint nxmAmount, uint currentTotalAssetValue, uint mcrEth) external pure returns (uint);

  function calculateMCRRatio(uint totalAssetValue, uint mcrEth) external pure returns (uint);

  function calculateTokenSpotPrice(uint totalAssetValue, uint mcrEth) external pure returns (uint tokenPrice);

  function getTokenPriceInAsset(uint assetId) external view returns (uint tokenPrice);

  function getTokenPrice() external view returns (uint tokenPrice);

  function getMCRRatio() external view returns (uint);

  function setSwapValue(uint value) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface Aggregator {
  function latestAnswer() external view returns (int);
}

struct OracleAsset {
  Aggregator aggregator;
  uint8 decimals;
}

interface IPriceFeedOracle {

  function ETH() external view returns (address);
  function assets(address) external view returns (Aggregator, uint8);

  function getAssetToEthRate(address asset) external view returns (uint);
  function getAssetForEth(address asset, uint ethIn) external view returns (uint);
  function getEthForAsset(address asset, uint amount) external view returns (uint);

}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface IWeth {
  function deposit() external payable;

  function withdraw(uint256 wad) external;

  function approve(address spender, uint256 value) external;

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.18;

import "@openzeppelin/contracts-v4/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-v4/token/ERC20/utils/SafeERC20.sol";

import "../../external/cow/GPv2Order.sol";
import "../../interfaces/ICowSettlement.sol";
import "../../interfaces/INXMMaster.sol";
import "../../interfaces/IPool.sol";
import "../../interfaces/IPriceFeedOracle.sol";
import "../../interfaces/IWeth.sol";
import "../../interfaces/IERC20Detailed.sol";

import "../../external/enzyme/IEnzymeFundValueCalculatorRouter.sol";
import "../../external/enzyme/IEnzymeV4Vault.sol";
import "../../external/enzyme/IEnzymeV4Comptroller.sol";
import "../../external/enzyme/IEnzymePolicyManager.sol";

/**
  @title A contract for swapping Pool's assets using CoW protocol
  @dev This contract's address is set on the Pool's swapOperator variable via governance
 */
contract SwapOperator {
  using SafeERC20 for IERC20;

  // Storage
  bytes public currentOrderUID;

  // Immutables
  ICowSettlement public immutable cowSettlement;
  address public immutable cowVaultRelayer;
  INXMMaster public immutable master;
  address public immutable swapController;
  IWeth public immutable weth;
  bytes32 public immutable domainSeparator;

  address public immutable enzymeV4VaultProxyAddress;
  IEnzymeFundValueCalculatorRouter public immutable enzymeFundValueCalculatorRouter;
  uint public immutable minPoolEth;

  // Constants
  address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  uint public constant MAX_SLIPPAGE_DENOMINATOR = 10000;
  uint public constant MIN_VALID_TO_PERIOD = 600; // 10 minutes
  uint public constant MAX_VALID_TO_PERIOD = 3600; // 60 minutes
  uint public constant MIN_TIME_BETWEEN_ORDERS = 900; // 15 minutes
  uint public constant maxFee = 0.3 ether;

  // Events
  event OrderPlaced(GPv2Order.Data order);
  event OrderClosed(GPv2Order.Data order, uint filledAmount);
  event Swapped(address indexed fromAsset, address indexed toAsset, uint amountIn, uint amountOut);

  modifier onlyController() {
    require(msg.sender == swapController, "SwapOp: only controller can execute");
    _;
  }

  /**
   * @param _cowSettlement Address of CoW protocol's settlement contract
   * @param _swapController Account allowed to place and close orders
   * @param _master Address of Nexus' master contract
   * @param _weth Address of wrapped eth token
   */
  constructor(
    address _cowSettlement,
    address _swapController,
    address _master,
    address _weth,
    address _enzymeV4VaultProxyAddress,
    IEnzymeFundValueCalculatorRouter _enzymeFundValueCalculatorRouter,
    uint _minPoolEth
  ) {
    cowSettlement = ICowSettlement(_cowSettlement);
    cowVaultRelayer = cowSettlement.vaultRelayer();
    master = INXMMaster(_master);
    swapController = _swapController;
    weth = IWeth(_weth);
    domainSeparator = cowSettlement.domainSeparator();
    enzymeV4VaultProxyAddress = _enzymeV4VaultProxyAddress;
    enzymeFundValueCalculatorRouter = _enzymeFundValueCalculatorRouter;
    minPoolEth = _minPoolEth;
  }

  receive() external payable {}

  /**
   * @dev Compute the digest of an order using CoW protocol's logic
   * @param order The order
   * @return The digest
   */
  function getDigest(GPv2Order.Data calldata order) public view returns (bytes32) {
    bytes32 hash = GPv2Order.hash(order, domainSeparator);
    return hash;
  }

  /**
   * @dev Compute the UID of an order using CoW protocol's logic
   * @param order The order
   * @return The UID (56 bytes)
   */
  function getUID(GPv2Order.Data calldata order) public view returns (bytes memory) {
    bytes memory uid = new bytes(56);
    bytes32 digest = getDigest(order);
    GPv2Order.packOrderUidParams(uid, digest, order.receiver, order.validTo);
    return uid;
  }

  /**
   * @dev Approve a given order to be executed, by presigning it on CoW protocol's settlement contract
   * Only one order can be open at the same time, and one of the swapped assets must be ether
   * @param order The order
   * @param orderUID The order UID, for verification purposes
   */
  function placeOrder(GPv2Order.Data calldata order, bytes calldata orderUID) public onlyController {
    // Validate there's no current order going on
    require(!orderInProgress(), "SwapOp: an order is already in place");

    // Order UID verification
    validateUID(order, orderUID);

    // Validate basic CoW params
    validateBasicCowParams(order);

    IPool pool = _pool();
    IPriceFeedOracle priceFeedOracle = pool.priceFeedOracle();
    uint totalOutAmount = order.sellAmount + order.feeAmount;

    if (isSellingEth(order)) {
      // Validate min/max setup for buyToken
      SwapDetails memory swapDetails = pool.getAssetSwapDetails(address(order.buyToken));
      require(swapDetails.minAmount != 0 || swapDetails.maxAmount != 0, "SwapOp: buyToken is not enabled");
      uint buyTokenBalance = order.buyToken.balanceOf(address(pool));
      require(buyTokenBalance < swapDetails.minAmount, "SwapOp: can only buy asset when < minAmount");
      require(buyTokenBalance + order.buyAmount <= swapDetails.maxAmount, "SwapOp: swap brings buyToken above max");

      validateSwapFrequency(swapDetails);

      validateMaxFee(priceFeedOracle, ETH, order.feeAmount);

      // Validate minimum pool eth reserve
      require(address(pool).balance - totalOutAmount >= minPoolEth, "SwapOp: Pool eth balance below min");

      // Ask oracle how much of the other asset we should get
      uint oracleBuyAmount = priceFeedOracle.getAssetForEth(address(order.buyToken), order.sellAmount);

      // Calculate slippage and minimum amount we should accept
      uint maxSlippageAmount = (oracleBuyAmount * swapDetails.maxSlippageRatio) / MAX_SLIPPAGE_DENOMINATOR;
      uint minBuyAmountOnMaxSlippage = oracleBuyAmount - maxSlippageAmount;

      require(order.buyAmount >= minBuyAmountOnMaxSlippage, "SwapOp: order.buyAmount too low (oracle)");

      refreshAssetLastSwapDate(pool, address(order.buyToken));

      // Transfer ETH from pool and wrap it
      pool.transferAssetToSwapOperator(ETH, totalOutAmount);
      weth.deposit{value: totalOutAmount}();

      // Set pool's swapValue
      pool.setSwapValue(totalOutAmount);
    } else if (isBuyingEth(order)) {
      // Validate min/max setup for sellToken
      SwapDetails memory swapDetails = pool.getAssetSwapDetails(address(order.sellToken));
      require(swapDetails.minAmount != 0 || swapDetails.maxAmount != 0, "SwapOp: sellToken is not enabled");
      uint sellTokenBalance = order.sellToken.balanceOf(address(pool));
      require(sellTokenBalance > swapDetails.maxAmount, "SwapOp: can only sell asset when > maxAmount");
      require(sellTokenBalance - totalOutAmount >= swapDetails.minAmount, "SwapOp: swap brings sellToken below min");

      validateSwapFrequency(swapDetails);

      validateMaxFee(priceFeedOracle, address(order.sellToken), order.feeAmount);

      // Ask oracle how much ether we should get
      uint oracleBuyAmount = priceFeedOracle.getEthForAsset(address(order.sellToken), order.sellAmount);

      // Calculate slippage and minimum amount we should accept
      uint maxSlippageAmount = (oracleBuyAmount * swapDetails.maxSlippageRatio) / MAX_SLIPPAGE_DENOMINATOR;
      uint minBuyAmountOnMaxSlippage = oracleBuyAmount - maxSlippageAmount;
      require(order.buyAmount >= minBuyAmountOnMaxSlippage, "SwapOp: order.buyAmount too low (oracle)");

      refreshAssetLastSwapDate(pool, address(order.sellToken));

      // Transfer ERC20 asset from Pool
      pool.transferAssetToSwapOperator(address(order.sellToken), totalOutAmount);

      // Calculate swapValue using oracle and set it on the pool
      uint swapValue = priceFeedOracle.getEthForAsset(address(order.sellToken), totalOutAmount);
      pool.setSwapValue(swapValue);
    } else {
      revert("SwapOp: Must either sell or buy eth");
    }

    // Approve Cow's contract to spend sellToken
    approveVaultRelayer(order.sellToken, totalOutAmount);

    // Store the order UID
    currentOrderUID = orderUID;

    // Sign the Cow order
    cowSettlement.setPreSignature(orderUID, true);

    // Emit an event
    emit OrderPlaced(order);
  }

  /**
   * @dev Close a previously placed order, returning assets to the pool (either fulfilled or not)
   * @param order The order to close
   */
  function closeOrder(GPv2Order.Data calldata order) external {
    // Validate there is an order in place
    require(orderInProgress(), "SwapOp: No order in place");

    // Before validTo, only controller can call this. After it, everyone can call
    if (block.timestamp <= order.validTo) {
      require(msg.sender == swapController, "SwapOp: only controller can execute");
    }

    validateUID(order, currentOrderUID);

    // Check how much of the order was filled, and if it was fully filled
    uint filledAmount = cowSettlement.filledAmount(currentOrderUID);

    // Cancel signature and unapprove tokens
    cowSettlement.setPreSignature(currentOrderUID, false);
    approveVaultRelayer(order.sellToken, 0);

    // Clear the current order
    delete currentOrderUID;

    // Withdraw both buyToken and sellToken
    returnAssetToPool(order.buyToken);
    returnAssetToPool(order.sellToken);

    // Set swapValue on pool to 0
    _pool().setSwapValue(0);

    // Emit event
    emit OrderClosed(order, filledAmount);
  }

  /**
   * @dev Return a given asset to the pool, either ETH or ERC20
   * @param asset The asset
   */
  function returnAssetToPool(IERC20 asset) internal {
    uint balance = asset.balanceOf(address(this));

    if (balance == 0) {
      return;
    }

    if (address(asset) == address(weth)) {
      // Unwrap WETH
      weth.withdraw(balance);

      // Transfer ETH to pool
      (bool sent, ) = payable(address(_pool())).call{value: balance}("");
      require(sent, "SwapOp: Failed to send Ether to pool");
    } else {
      // Transfer ERC20 to pool
      asset.safeTransfer(address(_pool()), balance);
    }
  }

  /**
   * @dev Function to determine if an order is for selling eth
   * @param order The order
   * @return true or false
   */
  function isSellingEth(GPv2Order.Data calldata order) internal view returns (bool) {
    return address(order.sellToken) == address(weth);
  }

  /**
   * @dev Function to determine if an order is for buying eth
   * @param order The order
   * @return true or false
   */
  function isBuyingEth(GPv2Order.Data calldata order) internal view returns (bool) {
    return address(order.buyToken) == address(weth);
  }

  /**
   * @dev General validations on individual order fields
   * @param order The order
   */
  function validateBasicCowParams(GPv2Order.Data calldata order) internal view {
    require(order.sellTokenBalance == GPv2Order.BALANCE_ERC20, "SwapOp: Only erc20 supported for sellTokenBalance");
    require(order.buyTokenBalance == GPv2Order.BALANCE_ERC20, "SwapOp: Only erc20 supported for buyTokenBalance");
    require(order.receiver == address(this), "SwapOp: Receiver must be this contract");
    require(
      order.validTo >= block.timestamp + MIN_VALID_TO_PERIOD,
      "SwapOp: validTo must be at least 10 minutes in the future"
    );
    require(
      order.validTo <= block.timestamp + MAX_VALID_TO_PERIOD,
      "SwapOp: validTo must be at most 60 minutes in the future"
    );
  }

  /**
   * @dev Approve CoW's vault relayer to spend some given ERC20 token
   * @param token The token
   * @param amount Amount to approve
   */
  function approveVaultRelayer(IERC20 token, uint amount) internal {
    token.safeApprove(cowVaultRelayer, amount);
  }

  /**
   * @dev Validate that a given UID is the correct one for a given order
   * @param order The order
   * @param providedOrderUID The UID
   */
  function validateUID(GPv2Order.Data calldata order, bytes memory providedOrderUID) internal view {
    bytes memory calculatedUID = getUID(order);
    require(
      keccak256(calculatedUID) == keccak256(providedOrderUID),
      "SwapOp: Provided UID doesnt match calculated UID"
    );
  }

  /**
   * @dev Get the Pool's instance through master contract
   * @return The pool instance
   */
  function _pool() internal view returns (IPool) {
    return IPool(master.getLatestAddress("P1"));
  }

  /**
   * @dev Validates that a given asset is not swapped too fast
   * @param swapDetails Swap details for the given asset
   */
  function validateSwapFrequency(SwapDetails memory swapDetails) internal view {
    require(
      block.timestamp >= swapDetails.lastSwapTime + MIN_TIME_BETWEEN_ORDERS,
      "SwapOp: already swapped this asset recently"
    );
  }

  /**
   * @dev Set the last swap's time of a given asset to current time
   * @param pool The pool instance
   * @param asset The asset
   */
  function refreshAssetLastSwapDate(IPool pool, address asset) internal {
    pool.setSwapDetailsLastSwapTime(asset, uint32(block.timestamp));
  }

  /**
   * @dev Validate that the fee for the order is not higher than the maximum allowed fee, in ether
   * @param oracle The oracle instance
   * @param asset The asset
   * @param feeAmount The fee, in asset's units
   */
  function validateMaxFee(
    IPriceFeedOracle oracle,
    address asset,
    uint feeAmount
  ) internal view {
    uint feeInEther = oracle.getEthForAsset(asset, feeAmount);
    require(feeInEther <= maxFee, "SwapOp: Fee amount is higher than configured max fee");
  }


  function swapETHForEnzymeVaultShare(uint amountIn, uint amountOutMin) external onlyController {

    // Validate there's no current cow swap order going on
    require(!orderInProgress(), "SwapOp: an order is already in place");

    IPool pool = _pool();
    IEnzymeV4Comptroller comptrollerProxy = IEnzymeV4Comptroller(IEnzymeV4Vault(enzymeV4VaultProxyAddress).getAccessor());
    IERC20Detailed toToken = IERC20Detailed(enzymeV4VaultProxyAddress);


    SwapDetails memory swapDetails = pool.getAssetSwapDetails(address(toToken));

    require(!(swapDetails.minAmount == 0 && swapDetails.maxAmount == 0), "SwapOp: asset is not enabled");

    {
      // scope for swap frequency check
      uint timeSinceLastTrade = block.timestamp - uint(swapDetails.lastSwapTime);
      require(timeSinceLastTrade > MIN_TIME_BETWEEN_ORDERS, "SwapOp: too fast");
    }

    {
      // check slippage
      (, uint netShareValue) = enzymeFundValueCalculatorRouter.calcNetShareValue(enzymeV4VaultProxyAddress);

      uint avgAmountOut = amountIn * 1e18 / netShareValue;
      uint maxSlippageAmount = avgAmountOut * swapDetails.maxSlippageRatio / 1e18;
      uint minOutOnMaxSlippage = avgAmountOut - maxSlippageAmount;

      require(amountOutMin >= minOutOnMaxSlippage, "SwapOp: amountOutMin < minOutOnMaxSlippage");
    }

    uint balanceBefore = toToken.balanceOf(address(pool));
    pool.transferAssetToSwapOperator(ETH, amountIn);

    require(comptrollerProxy.getDenominationAsset() == address(weth), "SwapOp: invalid denomination asset");

    weth.deposit{ value: amountIn }();
    weth.approve(address(comptrollerProxy), amountIn);
    comptrollerProxy.buyShares(amountIn, amountOutMin);

    pool.setSwapDetailsLastSwapTime(address(toToken), uint32(block.timestamp));

    uint amountOut = toToken.balanceOf(address(this));

    require(amountOut >= amountOutMin, "SwapOp: amountOut < amountOutMin");
    require(balanceBefore < swapDetails.minAmount, "SwapOp: balanceBefore >= min");
    require(balanceBefore + amountOutMin <= swapDetails.maxAmount, "SwapOp: balanceAfter > max");

    {
      uint ethBalanceAfter = address(pool).balance;
      require(ethBalanceAfter >= minPoolEth, "SwapOp: insufficient ether left");
    }

    transferAssetTo(enzymeV4VaultProxyAddress, address(pool), amountOut);

    emit Swapped(ETH, enzymeV4VaultProxyAddress, amountIn, amountOut);
  }

  function swapEnzymeVaultShareForETH(
    uint amountIn,
    uint amountOutMin
  ) external onlyController {

    // Validate there's no current cow swap order going on
    require(!orderInProgress(), "SwapOp: an order is already in place");

    IPool pool = _pool();
    IERC20Detailed fromToken = IERC20Detailed(enzymeV4VaultProxyAddress);

    uint balanceBefore = fromToken.balanceOf(address(pool));
    {

      SwapDetails memory swapDetails = pool.getAssetSwapDetails(address(fromToken));

      require(!(swapDetails.minAmount == 0 && swapDetails.maxAmount == 0), "SwapOp: asset is not enabled");

      // swap frequency check
      uint timeSinceLastTrade = block.timestamp - uint(swapDetails.lastSwapTime);
      require(timeSinceLastTrade > MIN_TIME_BETWEEN_ORDERS, "SwapOp: too fast");

      uint netShareValue;
      {
        address denominationAsset;
        (denominationAsset, netShareValue) =
        enzymeFundValueCalculatorRouter.calcNetShareValue(enzymeV4VaultProxyAddress);

        require(denominationAsset ==  address(weth), "SwapOp: invalid denomination asset");
      }

      // avgAmountOut in ETH
      uint avgAmountOut = amountIn * netShareValue / (10 ** fromToken.decimals());
      uint maxSlippageAmount = avgAmountOut * swapDetails.maxSlippageRatio / 1e18;
      uint minOutOnMaxSlippage = avgAmountOut - maxSlippageAmount;

      // slippage check
      require(amountOutMin >= minOutOnMaxSlippage, "SwapOp: amountOutMin < minOutOnMaxSlippage");
      require(balanceBefore > swapDetails.maxAmount, "SwapOp: balanceBefore <= max");
      require(balanceBefore - amountIn >= swapDetails.minAmount, "SwapOp: tokenBalanceAfter < min");
    }

    pool.transferAssetToSwapOperator(address(fromToken), amountIn);

    IEnzymeV4Comptroller comptrollerProxy = IEnzymeV4Comptroller(IEnzymeV4Vault(enzymeV4VaultProxyAddress).getAccessor());
    fromToken.approve(address(comptrollerProxy), amountIn);

    address[] memory payoutAssets = new address[](1);
    uint[] memory payoutAssetsPercentages = new uint[](1);

    payoutAssets[0] = address(weth);
    payoutAssetsPercentages[0] = 10000;

    comptrollerProxy.redeemSharesForSpecificAssets(address(this), amountIn, payoutAssets, payoutAssetsPercentages);

    uint amountOut = weth.balanceOf(address(this));
    weth.withdraw(amountOut);

    pool.setSwapDetailsLastSwapTime(address(fromToken), uint32(block.timestamp));

    require(amountOut >= amountOutMin, "SwapOp: amountOut < amountOutMin");

    transferAssetTo(ETH, address(pool), amountOut);

    emit Swapped(enzymeV4VaultProxyAddress, ETH, amountIn, amountOut);
  }

  function transferAssetTo (address asset, address to, uint amount) internal {

    if (asset == ETH) {
      (bool ok, /* data */) = to.call{ value: amount }("");
      require(ok, "SwapOp: Eth transfer failed");
      return;
    }

    IERC20 token = IERC20(asset);
    token.safeTransfer(to, amount);
  }

  function recoverAsset(address assetAddress, address receiver) public onlyController {

    // Validate there's no current cow swap order going on
    require(!orderInProgress(), "SwapOp: an order is already in place");

    IERC20 asset = IERC20(assetAddress);

    uint balance = asset.balanceOf(address(this));
    require(balance > 0, "SwapOp: Balance = 0");

    IPool pool = _pool();

    SwapDetails memory swapDetails = pool.getAssetSwapDetails(assetAddress);

    if (swapDetails.minAmount == 0 && swapDetails.maxAmount == 0) {
      // asset is not supported
      asset.transfer(receiver, balance);
      return;
    }

    asset.transfer(address(pool), balance);
  }

  function orderInProgress() public view returns (bool) {
    return currentOrderUID.length > 0;
  }
}