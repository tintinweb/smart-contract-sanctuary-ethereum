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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IButtonswapERC20} from "./interfaces/IButtonswapERC20/IButtonswapERC20.sol";

contract ButtonswapERC20 is IButtonswapERC20 {
    /**
     * @inheritdoc IButtonswapERC20
     */
    string public constant name = "Buttonswap";

    /**
     * @inheritdoc IButtonswapERC20
     */
    string public constant symbol = "BTNSWP";

    /**
     * @inheritdoc IButtonswapERC20
     */
    uint8 public constant decimals = 18;

    /**
     * @inheritdoc IButtonswapERC20
     */
    uint256 public totalSupply;

    /**
     * @inheritdoc IButtonswapERC20
     */
    mapping(address => uint256) public balanceOf;

    /**
     * @inheritdoc IButtonswapERC20
     */
    mapping(address => mapping(address => uint256)) public allowance;

    /**
     * @inheritdoc IButtonswapERC20
     */
    bytes32 public immutable DOMAIN_SEPARATOR;

    /**
     * @inheritdoc IButtonswapERC20
     * @dev Pre-computed to equal `keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");`
     */
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /**
     * @inheritdoc IButtonswapERC20
     */
    mapping(address => uint256) public nonces;

    constructor() {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    /**
     * @dev Mints `value` tokens to `to`.
     *
     * Emits a {IButtonswapERC20Events-Transfer} event.
     * @param to The account that is receiving the tokens
     * @param value The amount of tokens being created
     */
    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply + value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(address(0), to, value);
    }

    /**
     * @dev Burns `value` tokens from `from`.
     *
     * Emits a {IButtonswapERC20Events-Transfer} event.
     * @param from The account that is sending the tokens
     * @param value The amount of tokens being destroyed
     */
    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from] - value;
        totalSupply = totalSupply - value;
        emit Transfer(from, address(0), value);
    }

    /**
     * @dev Sets `value` as the allowance of `spender` over the caller's tokens.
     *
     * Emits a {IButtonswapERC20Events-Approval} event.
     * @param owner The account whose tokens are being approved
     * @param spender The account that is granted permission to spend the tokens
     * @param value The amount of tokens that can be spent
     */
    function _approve(address owner, address spender, uint256 value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Moves `value` tokens from `from` to `to`.
     *
     * Emits a {IButtonswapERC20Events-Transfer} event.
     * @param from The account that is sending the tokens
     * @param to The account that is receiving the tokens
     * @param value The amount of tokens being sent
     */
    function _transfer(address from, address to, uint256 value) internal {
        balanceOf[from] = balanceOf[from] - value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(from, to, value);
    }

    /**
     * @inheritdoc IButtonswapERC20
     */
    function approve(address spender, uint256 value) external returns (bool success) {
        _approve(msg.sender, spender, value);
        success = true;
    }

    /**
     * @inheritdoc IButtonswapERC20
     */
    function transfer(address to, uint256 value) external returns (bool success) {
        _transfer(msg.sender, to, value);
        success = true;
    }

    /**
     * @inheritdoc IButtonswapERC20
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool success) {
        uint256 allowanceFromSender = allowance[from][msg.sender];
        if (allowanceFromSender != type(uint256).max) {
            allowance[from][msg.sender] = allowanceFromSender - value;
            emit Approval(from, msg.sender, allowanceFromSender - value);
        }
        _transfer(from, to, value);
        success = true;
    }

    /**
     * @inheritdoc IButtonswapERC20
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external
    {
        if (block.timestamp > deadline) {
            revert PermitExpired();
        }
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        if (recoveredAddress == address(0) || recoveredAddress != owner) {
            revert PermitInvalidSignature();
        }
        _approve(owner, spender, value);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IButtonswapPair} from "./interfaces/IButtonswapPair/IButtonswapPair.sol";
import {ButtonswapERC20} from "./ButtonswapERC20.sol";
import {Math} from "./libraries/Math.sol";
import {PairMath} from "./libraries/PairMath.sol";
import {UQ112x112} from "./libraries/UQ112x112.sol";
import {IERC20} from "[email protected]/token/ERC20/IERC20.sol";
import {SafeERC20} from "[email protected]/token/ERC20/utils/SafeERC20.sol";
import {IButtonswapFactory} from "./interfaces/IButtonswapFactory/IButtonswapFactory.sol";

contract ButtonswapPair is IButtonswapPair, ButtonswapERC20 {
    using UQ112x112 for uint224;

    /**
     * @dev A set of liquidity values.
     * @param pool0 The active `token0` liquidity
     * @param pool1 The active `token1` liquidity
     * @param reservoir0 The inactive `token0` liquidity
     * @param reservoir1 The inactive `token1` liquidity
     */
    struct LiquidityBalances {
        uint256 pool0;
        uint256 pool1;
        uint256 reservoir0;
        uint256 reservoir1;
    }

    /**
     * @inheritdoc IButtonswapPair
     */
    uint256 public constant MINIMUM_LIQUIDITY = 10 ** 3;

    /**
     * @dev Denominator for basis points.
     */
    uint256 private constant BPS = 10_000;

    /**
     * @dev Numerator for when price volatility triggers maximum single-sided timelock duration.
     */
    uint256 private constant maxVolatilityBps = 700;

    /**
     * @dev How long the minimum singled-sided timelock lasts for.
     */
    uint256 private constant minTimelockDuration = 24 seconds;

    /**
     * @dev How long the maximum singled-sided timelock lasts for.
     */
    uint256 private constant maxTimelockDuration = 24 hours;

    /**
     * @dev Numerator for the fraction of the pool balance that acts as the maximum limit on how much of the reservoir
     * can be swapped in a given timeframe.
     */
    uint256 private constant maxSwappableReservoirLimitBps = 1000;

    /**
     * @dev How much time it takes for the swappable reservoir value to grow from nothing to its maximum value.
     */
    uint256 private constant swappableReservoirGrowthWindow = 24 hours;

    /**
     * @inheritdoc IButtonswapPair
     */
    address public immutable factory;

    /**
     * @inheritdoc IButtonswapPair
     */
    address public immutable token0;

    /**
     * @inheritdoc IButtonswapPair
     */
    address public immutable token1;

    /**
     * @dev The active `token0` liquidity amount following the last swap.
     * This value is used to determine active liquidity balances after potential rebases until the next future swap.
     */
    uint112 internal pool0Last;

    /**
     * @dev The active `token1` liquidity amount following the last swap.
     * This value is used to determine active liquidity balances after potential rebases until the next future swap.
     */
    uint112 internal pool1Last;

    /**
     * @dev The timestamp of the block that the last swap occurred in.
     */
    uint32 internal blockTimestampLast;

    /**
     * @inheritdoc IButtonswapPair
     */
    uint256 public price0CumulativeLast;

    /**
     * @inheritdoc IButtonswapPair
     */
    uint256 public price1CumulativeLast;

    /**
     * @dev The value of `movingAveragePrice0` at the time of the last swap.
     */
    uint256 internal movingAveragePrice0Last;

    /**
     * @inheritdoc IButtonswapPair
     */
    uint128 public singleSidedTimelockDeadline;

    /**
     * @inheritdoc IButtonswapPair
     */
    uint128 public swappableReservoirLimitReachesMaxDeadline;

    /**
     * @notice Whether or not the pair is isPaused (paused = 1, unPaused = 0).
     * When paused, all operations other than dual-sided burning LP tokens are disabled.
     */
    uint128 public isPaused;

    /**
     * @dev Value to track the state of the re-entrancy guard.
     */
    uint128 private unlocked = 1;

    /**
     * @dev Guards against re-entrancy.
     */
    modifier lock() {
        if (unlocked == 0) {
            revert Locked();
        }
        unlocked = 0;
        _;
        unlocked = 1;
    }

    /**
     * @dev Prevents certain operations from being executed if the price volatility induced timelock has yet to conclude.
     */
    modifier singleSidedTimelock() {
        if (block.timestamp < singleSidedTimelockDeadline) {
            revert SingleSidedTimelock();
        }
        _;
    }

    /**
    * @dev Prevents operations from being executed if the Pair is currently paused.
    */
    modifier checkPaused() {
        if (isPaused == 1) {
            revert Paused();
        }
        _;
    }

    /**
     * @dev Called whenever an LP wants to burn their LP tokens to make sure they get their fair share of fees.
     * If `feeTo` is defined, `balanceOf(address(this))` gets transferred to `feeTo`.
     * If `feeTo` is not defined, `balanceOf(address(this))` gets burned and the LP tokens all grow in value.
     */
    modifier sendOrRefundFee() {
        address feeTo = IButtonswapFactory(factory).feeTo();
        if (feeTo != address(0)) {
            _transfer(address(this), feeTo, balanceOf[address(this)]);
        } else {
            _burn(address(this), balanceOf[address(this)]);
        }
        _;
    }

    constructor() {
        factory = msg.sender;
        (token0, token1) = IButtonswapFactory(factory).lastCreatedPairTokens();
        updateIsPaused();
    }

    /**
     * @dev Always mints liquidity equivalent to 1/6th of the growth in sqrt(k) and allocates to address(this)
     * If there isn't a `feeTo` address defined, these LP tokens will get burned this 1/6th gets reallocated to LPs
     * @param pool0 The `token0` active liquidity balance at the start of the ongoing swap
     * @param pool1 The `token1` active liquidity balance at the start of the ongoing swap
     * @param pool0New The `token0` active liquidity balance at the end of the ongoing swap
     * @param pool1New The `token1` active liquidity balance at the end of the ongoing swap
     */
    function _mintFee(uint256 pool0, uint256 pool1, uint256 pool0New, uint256 pool1New) internal {
        uint256 liquidityOut = PairMath.getProtocolFeeLiquidityMinted(totalSupply, pool0 * pool1, pool0New * pool1New);
        if (liquidityOut > 0) {
            _mint(address(this), liquidityOut);
        }
    }

    /**
     * @dev Updates `price0CumulativeLast` and `price1CumulativeLast` based on the current timestamp.
     * @param pool0 The `token0` active liquidity balance at the start of the ongoing swap
     * @param pool1 The `token1` active liquidity balance at the start of the ongoing swap
     */
    function _updatePriceCumulative(uint256 pool0, uint256 pool1) internal {
        uint112 _pool0 = uint112(pool0);
        uint112 _pool1 = uint112(pool1);
        uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);
        uint32 timeElapsed;
        unchecked {
            // underflow is desired
            timeElapsed = blockTimestamp - blockTimestampLast;
        }
        if (timeElapsed > 0 && pool0 != 0 && pool1 != 0) {
            // * never overflows, and + overflow is desired
            unchecked {
                price0CumulativeLast += ((pool1 << 112) * timeElapsed) / _pool0;
                price1CumulativeLast += ((pool0 << 112) * timeElapsed) / _pool1;
            }
            blockTimestampLast = blockTimestamp;
        }
    }

    /**
     * @dev Refer to [closest-bound-math.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/closest-bound-math.md) for more detail.
     * @param poolALower The lower bound for the active liquidity balance of the non-fixed token
     * @param poolB The active liquidity balance of the fixed token
     * @param _poolALast The active liquidity balance at the end of the last swap for the non-fixed token
     * @param _poolBLast The active liquidity balance at the end of the last swap for the fixed token
     * @return closestBound The bound for the active liquidity balance of the non-fixed token that produces a price ratio closest to last swap price
     */
    function _closestBound(uint256 poolALower, uint256 poolB, uint256 _poolALast, uint256 _poolBLast)
        internal
        pure
        returns (uint256 closestBound)
    {
        if ((poolALower * _poolBLast) + (_poolBLast / 2) < _poolALast * poolB) {
            closestBound = poolALower + 1;
        }
        closestBound = poolALower;
    }

    /**
     * @dev Refer to [liquidity-balances-math.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/liquidity-balances-math.md) for more detail.
     * @param total0 The total amount of `token0` held by the Pair
     * @param total1 The total amount of `token1` held by the Pair
     * @return lb The current active and inactive liquidity balances
     */
    function _getLiquidityBalances(uint256 total0, uint256 total1)
        internal
        view
        returns (LiquidityBalances memory lb)
    {
        uint256 _pool0Last = uint256(pool0Last);
        uint256 _pool1Last = uint256(pool1Last);
        if (_pool0Last == 0 || _pool1Last == 0) {
            // Before Pair is initialized by first dual mint just return zeroes
        } else if (total0 == 0 || total1 == 0) {
            // Return zeroes, _getLiquidityBalancesUnsafe will get stuck in an infinite loop if called
        } else {
            if (total0 * _pool1Last < total1 * _pool0Last) {
                lb.pool0 = total0;
                // pool0Last/pool1Last == pool0/pool1 => pool1 == (pool0*pool1Last)/pool0Last
                // pool1Last/pool0Last == pool1/pool0 => pool1 == (pool0*pool1Last)/pool0Last
                lb.pool1 = (lb.pool0 * _pool1Last) / _pool0Last;
                lb.pool1 = _closestBound(lb.pool1, lb.pool0, _pool1Last, _pool0Last);
                // reservoir0 is zero, so no need to set it
                lb.reservoir1 = total1 - lb.pool1;
            } else {
                lb.pool1 = total1;
                // pool0Last/pool1Last == pool0/pool1 => pool0 == (pool1*pool0Last)/pool1Last
                // pool1Last/pool0Last == pool1/pool0 => pool0 == (pool1*pool0Last)/pool1Last
                lb.pool0 = (lb.pool1 * _pool0Last) / _pool1Last;
                lb.pool0 = _closestBound(lb.pool0, lb.pool1, _pool0Last, _pool1Last);
                // reservoir1 is zero, so no need to set it
                lb.reservoir0 = total0 - lb.pool0;
            }
            if (lb.pool0 > type(uint112).max || lb.pool1 > type(uint112).max) {
                revert Overflow();
            }
        }
    }

    /**
     * @dev Calculates current price volatility and initiates a timelock scaled to the volatility size.
     * This timelock prohibits single-sided operations from being executed until enough time has passed for the timelock
     *   to conclude.
     * This protects against attempts to manipulate the price that the reservoir is valued at during single-sided operations.
     * @param _movingAveragePrice0 The current `movingAveragePrice0` value
     * @param pool0New The `token0` active liquidity balance at the end of the ongoing swap
     * @param pool1New The `token1` active liquidity balance at the end of the ongoing swap
     */
    function _updateSingleSidedTimelock(uint256 _movingAveragePrice0, uint112 pool0New, uint112 pool1New) internal {
        uint256 newPrice0 = uint256(UQ112x112.encode(pool1New).uqdiv(pool0New));
        uint256 priceDifference;
        if (newPrice0 > _movingAveragePrice0) {
            priceDifference = newPrice0 - _movingAveragePrice0;
        } else {
            priceDifference = _movingAveragePrice0 - newPrice0;
        }
        // priceDifference / ((_movingAveragePrice0 * maxVolatilityBps)/BPS)
        uint256 timelock = Math.min(
            minTimelockDuration
                + ((priceDifference * BPS * maxTimelockDuration) / (_movingAveragePrice0 * maxVolatilityBps)),
            maxTimelockDuration
        );
        uint128 timelockDeadline = uint128(block.timestamp + timelock);
        if (timelockDeadline > singleSidedTimelockDeadline) {
            singleSidedTimelockDeadline = timelockDeadline;
        }
    }

    /**
     * @dev Calculates the current limit on the number of reservoir tokens that can be exchanged during a single-sided
     *   operation.
     * This is based on corresponding active liquidity size and time since and size of the last single-sided operation.
     * @param reservoirA The inactive liquidity balance for the non-zero reservoir token
     * @param poolA The active liquidity balance for the non-zero reservoir token
     * @param poolB The active liquidity balance for the zero reservoir token
     * @return swappableReservoir The amount of non-zero reservoir token that can be exchanged as part of a single-sided operation
     */
    function _getSwappableReservoirLimit(uint256 reservoirA, uint256 poolA, uint256 poolB)
        internal
        view
        returns (uint256 swappableReservoir)
    {
        // Calculate the maximum the limit can be as a fraction of the corresponding active liquidity
        uint256 maxSwappableReservoirLimit;
        if (reservoirA == 0) {
            maxSwappableReservoirLimit = (poolB * maxSwappableReservoirLimitBps) / BPS;
        } else {
            maxSwappableReservoirLimit = (poolA * maxSwappableReservoirLimitBps) / BPS;
        }
        uint256 _swappableReservoirLimitReachesMaxDeadline = swappableReservoirLimitReachesMaxDeadline;
        uint256 blockTimestamp = block.timestamp;
        if (_swappableReservoirLimitReachesMaxDeadline > blockTimestamp) {
            // If the current deadline is still active then calculate the progress towards reaching it
            uint256 progress =
                swappableReservoirGrowthWindow - (_swappableReservoirLimitReachesMaxDeadline - blockTimestamp);
            // The greater the progress, the closer to the max limit we get
            swappableReservoir = (maxSwappableReservoirLimit * progress) / swappableReservoirGrowthWindow;
        } else {
            // If the current deadline has expired then the full limit is available
            swappableReservoir = maxSwappableReservoirLimit;
        }
    }

    /**
     * @dev Updates the value of `swappableReservoirLimitReachesMaxDeadline` which is the time at which the maximum
     *   amount of inactive liquidity tokens can be exchanged during a single-sided operation.
     * @param poolA The active liquidity balance for the non-zero reservoir token
     * @param swappedAmountA The amount of non-zero reservoir tokens that were exchanged during the ongoing single-sided
     *   operation
     */
    function _updateSwappableReservoirDeadline(uint256 poolA, uint256 swappedAmountA) internal {
        // Calculate the maximum the limit can be as a fraction of the corresponding active liquidity
        uint256 maxSwappableReservoirLimit = (poolA * maxSwappableReservoirLimitBps) / BPS;
        // Calculate how much time delay the swap instigates
        uint256 delay;
        // Check non-zero to avoid div by zero error
        if (maxSwappableReservoirLimit > 0) {
            delay = (swappableReservoirGrowthWindow * Math.min(swappedAmountA, maxSwappableReservoirLimit))
                / maxSwappableReservoirLimit;
        } else {
            // If it is zero then it's in an extreme condition and a delay is most appropriate way to handle it
            delay = swappableReservoirGrowthWindow;
        }
        // Apply the delay
        uint256 _swappableReservoirLimitReachesMaxDeadline = swappableReservoirLimitReachesMaxDeadline;
        uint256 blockTimestamp = block.timestamp;
        if (_swappableReservoirLimitReachesMaxDeadline > blockTimestamp) {
            // If the current deadline hasn't expired yet then add the delay to it
            swappableReservoirLimitReachesMaxDeadline = uint128(_swappableReservoirLimitReachesMaxDeadline + delay);
        } else {
            // If the current deadline has expired already then add the delay to the current time, so that the full
            //   delay is still applied
            swappableReservoirLimitReachesMaxDeadline = uint128(blockTimestamp + delay);
        }
    }

    /**
     * @inheritdoc IButtonswapPair
     */
    function getLiquidityBalances()
        external
        view
        returns (uint112 _pool0, uint112 _pool1, uint112 _reservoir0, uint112 _reservoir1, uint32 _blockTimestampLast)
    {
        uint256 total0 = IERC20(token0).balanceOf(address(this));
        uint256 total1 = IERC20(token1).balanceOf(address(this));
        LiquidityBalances memory lb = _getLiquidityBalances(total0, total1);
        _pool0 = uint112(lb.pool0);
        _pool1 = uint112(lb.pool1);
        _reservoir0 = uint112(lb.reservoir0);
        _reservoir1 = uint112(lb.reservoir1);
        _blockTimestampLast = blockTimestampLast;
    }

    /**
     * @inheritdoc IButtonswapPair
     */
    function movingAveragePrice0() public view returns (uint256 _movingAveragePrice0) {
        uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);
        uint32 timeElapsed;
        unchecked {
            // overflow is desired
            timeElapsed = blockTimestamp - blockTimestampLast;
        }
        uint256 currentPrice0 = uint256(UQ112x112.encode(pool1Last).uqdiv(pool0Last));
        if (timeElapsed == 0) {
            _movingAveragePrice0 = movingAveragePrice0Last;
        } else if (timeElapsed >= 24 hours) {
            _movingAveragePrice0 = currentPrice0;
        } else {
            _movingAveragePrice0 =
                ((movingAveragePrice0Last * (24 hours - timeElapsed)) + (currentPrice0 * timeElapsed)) / 24 hours;
        }
    }

    /**
     * @inheritdoc IButtonswapPair
     */
    function mint(uint256 amountIn0, uint256 amountIn1, address to)
        external
        lock
        checkPaused
        sendOrRefundFee
        returns (uint256 liquidityOut)
    {
        uint256 _totalSupply = totalSupply;
        address _token0 = token0;
        address _token1 = token1;
        uint256 total0 = IERC20(_token0).balanceOf(address(this));
        uint256 total1 = IERC20(_token1).balanceOf(address(this));
        SafeERC20.safeTransferFrom(IERC20(_token0), msg.sender, address(this), amountIn0);
        SafeERC20.safeTransferFrom(IERC20(_token1), msg.sender, address(this), amountIn1);
        // Use the balance delta as input amounts to ensure feeOnTransfer or similar tokens don't disrupt Pair math
        amountIn0 = IERC20(_token0).balanceOf(address(this)) - total0;
        amountIn1 = IERC20(_token1).balanceOf(address(this)) - total1;

        if (_totalSupply == 0) {
            liquidityOut = Math.sqrt(amountIn0 * amountIn1) - MINIMUM_LIQUIDITY;
            // permanently lock the first MINIMUM_LIQUIDITY tokens
            _mint(address(0), MINIMUM_LIQUIDITY);
            // Initialize Pair last swap price
            pool0Last = uint112(amountIn0);
            pool1Last = uint112(amountIn1);
            // Initialize timestamp so first price update is accurate
            blockTimestampLast = uint32(block.timestamp % 2 ** 32);
            // Initialize moving average
            movingAveragePrice0Last = uint256(UQ112x112.encode(pool1Last).uqdiv(pool0Last));
        } else {
            // Don't need to check that amountIn{0,1} are in the right ratio because the least generous ratio is used
            //   to determine the liquidityOut value, meaning any tokens that exceed that ratio are donated.
            // If total0 or total1 are zero (eg. due to negative rebases) then the function call reverts with div by zero
            liquidityOut =
                PairMath.getDualSidedMintLiquidityOutAmount(_totalSupply, amountIn0, amountIn1, total0, total1);
        }

        if (liquidityOut == 0) {
            revert InsufficientLiquidityMinted();
        }
        _mint(to, liquidityOut);
        emit Mint(msg.sender, amountIn0, amountIn1, liquidityOut, to);
    }

    /**
     * @inheritdoc IButtonswapPair
     */
    function mintWithReservoir(uint256 amountIn, address to)
        external
        lock
        checkPaused
        singleSidedTimelock
        sendOrRefundFee
        returns (uint256 liquidityOut)
    {
        if (amountIn == 0) {
            revert InsufficientLiquidityAdded();
        }
        uint256 _totalSupply = totalSupply;
        if (_totalSupply == 0) {
            revert Uninitialized();
        }
        address _token0 = token0;
        address _token1 = token1;
        uint256 total0 = IERC20(_token0).balanceOf(address(this));
        uint256 total1 = IERC20(_token1).balanceOf(address(this));
        // Determine current pool liquidity
        LiquidityBalances memory lb = _getLiquidityBalances(total0, total1);
        if (lb.pool0 == 0 || lb.pool1 == 0) {
            revert InsufficientLiquidity();
        }
        if (lb.reservoir0 == 0) {
            // If reservoir0 is empty then we're adding token0 to pair with token1 reservoir liquidity
            SafeERC20.safeTransferFrom(IERC20(_token0), msg.sender, address(this), amountIn);
            // Use the balance delta as input amounts to ensure feeOnTransfer or similar tokens don't disrupt Pair math
            amountIn = IERC20(_token0).balanceOf(address(this)) - total0;

            // Ensure there's enough reservoir1 liquidity to do this without growing reservoir0
            LiquidityBalances memory lbNew = _getLiquidityBalances(total0 + amountIn, total1);
            if (lbNew.reservoir0 > 0) {
                revert InsufficientReservoir();
            }

            uint256 swappedReservoirAmount1;
            (liquidityOut, swappedReservoirAmount1) = PairMath.getSingleSidedMintLiquidityOutAmountA(
                _totalSupply, amountIn, total0, total1, movingAveragePrice0()
            );

            uint256 swappableReservoirLimit = _getSwappableReservoirLimit(lb.reservoir0, lb.pool0, lb.pool1);
            if (swappedReservoirAmount1 > swappableReservoirLimit) {
                revert SwappableReservoirExceeded();
            }
            _updateSwappableReservoirDeadline(lb.pool1, swappedReservoirAmount1);
        } else {
            // If reservoir1 is empty then we're adding token1 to pair with token0 reservoir liquidity
            SafeERC20.safeTransferFrom(IERC20(_token1), msg.sender, address(this), amountIn);
            // Use the balance delta as input amounts to ensure feeOnTransfer or similar tokens don't disrupt Pair math
            amountIn = IERC20(_token1).balanceOf(address(this)) - total1;

            // Ensure there's enough reservoir0 liquidity to do this without growing reservoir1
            LiquidityBalances memory lbNew = _getLiquidityBalances(total0, total1 + amountIn);
            if (lbNew.reservoir1 > 0) {
                revert InsufficientReservoir();
            }

            uint256 swappedReservoirAmount0;
            (liquidityOut, swappedReservoirAmount0) = PairMath.getSingleSidedMintLiquidityOutAmountB(
                _totalSupply, amountIn, total0, total1, movingAveragePrice0()
            );

            uint256 swappableReservoirLimit = _getSwappableReservoirLimit(lb.reservoir0, lb.pool0, lb.pool1);
            if (swappedReservoirAmount0 > swappableReservoirLimit) {
                revert SwappableReservoirExceeded();
            }
            _updateSwappableReservoirDeadline(lb.pool0, swappedReservoirAmount0);
        }

        if (liquidityOut == 0) {
            revert InsufficientLiquidityMinted();
        }
        _mint(to, liquidityOut);
        if (lb.reservoir0 == 0) {
            emit Mint(msg.sender, amountIn, 0, liquidityOut, to);
        } else {
            emit Mint(msg.sender, 0, amountIn, liquidityOut, to);
        }
    }

    /**
     * @inheritdoc IButtonswapPair
     */
    function burn(uint256 liquidityIn, address to)
        external
        lock
        sendOrRefundFee
        returns (uint256 amountOut0, uint256 amountOut1)
    {
        uint256 _totalSupply = totalSupply;
        address _token0 = token0;
        address _token1 = token1;
        uint256 total0 = IERC20(_token0).balanceOf(address(this));
        uint256 total1 = IERC20(_token1).balanceOf(address(this));

        (amountOut0, amountOut1) = PairMath.getDualSidedBurnOutputAmounts(_totalSupply, liquidityIn, total0, total1);

        if (amountOut0 == 0 || amountOut1 == 0) {
            revert InsufficientLiquidityBurned();
        }
        _burn(msg.sender, liquidityIn);
        SafeERC20.safeTransfer(IERC20(_token0), to, amountOut0);
        SafeERC20.safeTransfer(IERC20(_token1), to, amountOut1);
        emit Burn(msg.sender, liquidityIn, amountOut0, amountOut1, to);
    }

    /**
     * @inheritdoc IButtonswapPair
     */
    function burnFromReservoir(uint256 liquidityIn, address to)
        external
        lock
        checkPaused
        singleSidedTimelock
        sendOrRefundFee
        returns (uint256 amountOut0, uint256 amountOut1)
    {
        uint256 _totalSupply = totalSupply;
        address _token0 = token0;
        address _token1 = token1;
        uint256 total0 = IERC20(_token0).balanceOf(address(this));
        uint256 total1 = IERC20(_token1).balanceOf(address(this));
        // Determine current pool liquidity
        LiquidityBalances memory lb = _getLiquidityBalances(total0, total1);
        if (lb.pool0 == 0 || lb.pool1 == 0) {
            revert InsufficientLiquidity();
        }
        if (lb.reservoir0 == 0) {
            // If reservoir0 is empty then we're swapping amountOut0 for token1 from reservoir1
            uint256 swappedReservoirAmount1;
            (amountOut1, swappedReservoirAmount1) = PairMath.getSingleSidedBurnOutputAmountB(
                _totalSupply, liquidityIn, total0, total1, movingAveragePrice0()
            );
            // Check there's enough reservoir liquidity to withdraw from
            // If `amountOut1` exceeds reservoir1 then it will result in reservoir0 growing from excess token0
            if (amountOut1 > lb.reservoir1) {
                revert InsufficientReservoir();
            }

            uint256 swappableReservoirLimit = _getSwappableReservoirLimit(lb.reservoir0, lb.pool0, lb.pool1);
            if (swappedReservoirAmount1 > swappableReservoirLimit) {
                revert SwappableReservoirExceeded();
            }
            _updateSwappableReservoirDeadline(lb.pool1, swappedReservoirAmount1);
        } else {
            // If reservoir0 isn't empty then we're swapping amountOut1 for token0 from reservoir0
            uint256 swappedReservoirAmount0;
            (amountOut0, swappedReservoirAmount0) = PairMath.getSingleSidedBurnOutputAmountA(
                _totalSupply, liquidityIn, total0, total1, movingAveragePrice0()
            );
            // Check there's enough reservoir liquidity to withdraw from
            // If `amountOut0` exceeds reservoir0 then it will result in reservoir1 growing from excess token1
            if (amountOut0 > lb.reservoir0) {
                revert InsufficientReservoir();
            }

            uint256 swappableReservoirLimit = _getSwappableReservoirLimit(lb.reservoir0, lb.pool0, lb.pool1);
            if (swappedReservoirAmount0 > swappableReservoirLimit) {
                revert SwappableReservoirExceeded();
            }
            _updateSwappableReservoirDeadline(lb.pool0, swappedReservoirAmount0);
        }
        _burn(msg.sender, liquidityIn);
        if (amountOut0 > 0) {
            SafeERC20.safeTransfer(IERC20(_token0), to, amountOut0);
        } else if (amountOut1 > 0) {
            SafeERC20.safeTransfer(IERC20(_token1), to, amountOut1);
        } else {
            revert InsufficientLiquidityBurned();
        }
        emit Burn(msg.sender, liquidityIn, amountOut0, amountOut1, to);
    }

    /**
     * @inheritdoc IButtonswapPair
     */
    function swap(uint256 amountIn0, uint256 amountIn1, uint256 amountOut0, uint256 amountOut1, address to)
        external
        lock
        checkPaused
    {
        {
            if (amountOut0 == 0 && amountOut1 == 0) {
                revert InsufficientOutputAmount();
            }
            address _token0 = token0;
            address _token1 = token1;
            if (to == _token0 || to == _token1) {
                revert InvalidRecipient();
            }
            uint256 total0 = IERC20(_token0).balanceOf(address(this));
            uint256 total1 = IERC20(_token1).balanceOf(address(this));
            // Determine current pool liquidity
            LiquidityBalances memory lb = _getLiquidityBalances(total0, total1);
            if (amountOut0 >= lb.pool0 || amountOut1 >= lb.pool1) {
                revert InsufficientLiquidity();
            }
            // Transfer in the specified input
            if (amountIn0 > 0) {
                SafeERC20.safeTransferFrom(IERC20(_token0), msg.sender, address(this), amountIn0);
            }
            if (amountIn1 > 0) {
                SafeERC20.safeTransferFrom(IERC20(_token1), msg.sender, address(this), amountIn1);
            }
            // Optimistically transfer output
            if (amountOut0 > 0) {
                SafeERC20.safeTransfer(IERC20(_token0), to, amountOut0);
            }
            if (amountOut1 > 0) {
                SafeERC20.safeTransfer(IERC20(_token1), to, amountOut1);
            }

            // Refresh balances
            total0 = IERC20(_token0).balanceOf(address(this));
            total1 = IERC20(_token1).balanceOf(address(this));
            // The reservoir balances must remain unchanged during a swap, so all balance changes impact the pool balances
            uint256 pool0New = total0 - lb.reservoir0;
            uint256 pool1New = total1 - lb.reservoir1;
            if (pool0New == 0 || pool1New == 0) {
                revert InvalidFinalPrice();
            }
            // Update to the actual amount of tokens the user sent in based on the delta between old and new pool balances
            if (pool0New > lb.pool0) {
                amountIn0 = pool0New - lb.pool0;
            } else {
                amountIn0 = 0;
            }
            if (pool1New > lb.pool1) {
                amountIn1 = pool1New - lb.pool1;
            } else {
                amountIn1 = 0;
            }
            // If after accounting for input and output cancelling one another out, fee on transfer, etc there is no
            //   input tokens in real terms then revert.
            if (amountIn0 == 0 && amountIn1 == 0) {
                revert InsufficientInputAmount();
            }
            uint256 pool0NewAdjusted = (pool0New * 1000) - (amountIn0 * 3);
            uint256 pool1NewAdjusted = (pool1New * 1000) - (amountIn1 * 3);
            // After account for 0.3% fees, the new K must not be less than the old K
            if (pool0NewAdjusted * pool1NewAdjusted < (lb.pool0 * lb.pool1 * 1000 ** 2)) {
                revert KInvariant();
            }
            // Update moving average before `_updatePriceCumulative` updates `blockTimestampLast` and the new `poolXLast` values are set
            uint256 _movingAveragePrice0 = movingAveragePrice0();
            movingAveragePrice0Last = _movingAveragePrice0;
            _mintFee(lb.pool0, lb.pool1, pool0New, pool1New);
            _updatePriceCumulative(lb.pool0, lb.pool1);
            _updateSingleSidedTimelock(_movingAveragePrice0, uint112(pool0New), uint112(pool1New));
            // Update Pair last swap price
            pool0Last = uint112(pool0New);
            pool1Last = uint112(pool1New);
        }
        emit Swap(msg.sender, amountIn0, amountIn1, amountOut0, amountOut1, to);
    }

    /**
     * @inheritdoc IButtonswapPair
     */
    function updateIsPaused() public {
        isPaused = IButtonswapFactory(factory).isPaused() ? 1 : 0;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IButtonswapERC20Errors} from "./IButtonswapERC20Errors.sol";
import {IButtonswapERC20Events} from "./IButtonswapERC20Events.sol";

interface IButtonswapERC20 is IButtonswapERC20Errors, IButtonswapERC20Events {
    /**
     * @notice Returns the name of the token.
     * @return name The token name
     */
    function name() external pure returns (string memory name);

    /**
     * @notice Returns the symbol of the token, usually a shorter version of the name.
     * @return symbol The token symbol
     */
    function symbol() external pure returns (string memory symbol);

    /**
     * @notice Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should be displayed to a user as `5.05` (`505 / 10 ** 2`).
     * @dev This information is only used for _display_ purposes: it in no way affects any of the arithmetic of the contract.
     * @return decimals The number of decimals
     */
    function decimals() external pure returns (uint8 decimals);

    /**
     * @notice Returns the amount of tokens in existence.
     * @return totalSupply The amount of tokens in existence
     */
    function totalSupply() external view returns (uint256 totalSupply);

    /**
     * @notice Returns the amount of tokens owned by `account`.
     * @param owner The account the balance is being checked for
     * @return balance The amount of tokens owned by `owner`
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @notice Returns the remaining number of tokens that `spender` will be allowed to spend on behalf of `owner` through {transferFrom}.
     * This is zero by default.
     * This value changes when {approve} or {transferFrom} are called.
     * @param owner The account that owns the tokens
     * @param spender The account that can spend the tokens
     * @return allowance The amount of tokens owned by `owner` that the `spender` can transfer
     */
    function allowance(address owner, address spender) external view returns (uint256 allowance);

    /**
     * @notice Sets `value` as the allowance of `spender` over the caller's tokens.
     * @dev IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {IButtonswapERC20Events-Approval} event.
     * @param spender The account that is granted permission to spend the tokens
     * @param value The amount of tokens that can be spent
     * @return success Whether the operation succeeded
     */
    function approve(address spender, uint256 value) external returns (bool success);

    /**
     * @notice Moves `value` tokens from the caller's account to `to`.
     * @dev Emits a {IButtonswapERC20Events-Transfer} event.
     * @param to The account that is receiving the tokens
     * @param value The amount of tokens being sent
     * @return success Whether the operation succeeded
     */
    function transfer(address to, uint256 value) external returns (bool success);

    /**
     * @notice Moves `value` tokens from `from` to `to` using the allowance mechanism.
     * `value` is then deducted from the caller's allowance.
     * @dev Emits a {IButtonswapERC20Events-Transfer} event.
     * @param from The account that is sending the tokens
     * @param to The account that is receiving the tokens
     * @param value The amount of tokens being sent
     * @return success Whether the operation succeeded
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    /**
     * @notice Returns the domain separator used in the encoding of the signature for {permit}, as defined by [EIP712](https://eips.ethereum.org/EIPS/eip-712).
     * @return DOMAIN_SEPARATOR The `DOMAIN_SEPARATOR` value
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32 DOMAIN_SEPARATOR);

    /**
     * @notice Returns the typehash used in the encoding of the signature for {permit}, as defined by [EIP712](https://eips.ethereum.org/EIPS/eip-712).
     * @return PERMIT_TYPEHASH The `PERMIT_TYPEHASH` value
     */
    function PERMIT_TYPEHASH() external pure returns (bytes32 PERMIT_TYPEHASH);

    /**
     * @notice Returns the current nonce for `owner`.
     * This value must be included whenever a signature is generated for {permit}.
     * @dev Every successful call to {permit} increases `owner`'s nonce by one.
     * This prevents a signature from being used multiple times.
     * @param owner The account to get the nonce for
     * @return nonce The current nonce for the given `owner`
     */
    function nonces(address owner) external view returns (uint256 nonce);

    /**
     * @notice Sets `value` as the allowance of `spender` over `owner`'s tokens, given `owner`'s signed approval.
     * @dev IMPORTANT: The same issues {approve} has related to transaction ordering also apply here.
     *
     * Emits an {IButtonswapERC20Events-Approval} event.
     *
     * Requirements:
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner` over the EIP712-formatted function arguments.
     * - the signature must use `owner`'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the [relevant EIP section](https://eips.ethereum.org/EIPS/eip-2612#specification).
     * @param owner The account that owns the tokens
     * @param spender The account that can spend the tokens
     * @param value The amount of `owner`'s tokens that `spender` can transfer
     * @param deadline The future time after which the permit is no longer valid
     * @param v Part of the signature
     * @param r Part of the signature
     * @param s Part of the signature
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IButtonswapERC20Errors {
    /**
     * @notice Permit deadline was exceeded
     */
    error PermitExpired();

    /**
     * @notice Permit signature invalid
     */
    error PermitInvalidSignature();
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IButtonswapERC20Events {
    /**
     * @notice Emitted when the allowance of a `spender` for an `owner` is set by a call to {IButtonswapERC20-approve}.
     * `value` is the new allowance.
     * @param owner The account that has granted approval
     * @param spender The account that has been given approval
     * @param value The amount the spender can transfer
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @notice Emitted when `value` tokens are moved from one account (`from`) to another (`to`).
     * @param from The account that sent the tokens
     * @param to The account that received the tokens
     * @param value The amount of tokens transferred
     */
    event Transfer(address indexed from, address indexed to, uint256 value);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IButtonswapFactoryErrors} from "./IButtonswapFactoryErrors.sol";
import {IButtonswapFactoryEvents} from "./IButtonswapFactoryEvents.sol";

interface IButtonswapFactory is IButtonswapFactoryErrors, IButtonswapFactoryEvents {
    /**
     * @notice Returns the current address for `feeTo`.
     * The owner of this address receives the protocol fee as it is collected over time.
     * @return _feeTo The `feeTo` address
     */
    function feeTo() external view returns (address _feeTo);

    /**
     * @notice Returns the current address for `feeToSetter`.
     * The owner of this address has the power to update both `feeToSetter` and `feeTo`.
     * @return _feeToSetter The `feeToSetter` address
     */
    function feeToSetter() external view returns (address _feeToSetter);

    /**
     * @notice Returns the current state of restricted creation.
     * If true, then no new pairs, only feeToSetter can create new pairs
     * @return _isCreationRestricted The `isCreationRestricted` state
     */
    function isCreationRestricted() external view returns (bool _isCreationRestricted);

    /**
     * @notice Returns the current default pause state of Pairs
     * New pairs are created with this value as their initial pause state
     * @return _isPaused The `isPaused` state
     */
    function isPaused() external view returns (bool _isPaused);

    /**
     * @notice Get the (unique) Pair address created for the given combination of `tokenA` and `tokenB`.
     * If the Pair does not exist then zero address is returned.
     * @param tokenA The first unsorted token
     * @param tokenB The second unsorted token
     * @return pair The address of the Pair instance
     */
    function getPair(address tokenA, address tokenB) external view returns (address pair);

    /**
     * @notice Get the Pair address at the given `index`, ordered chronologically.
     * @param index The index to query
     * @return pair The address of the Pair created at the given `index`
     */
    function allPairs(uint256 index) external view returns (address pair);

    /**
     * @notice Get the current total number of Pairs created
     * @return count The total number of Pairs created
     */
    function allPairsLength() external view returns (uint256 count);

    /**
     * @notice Creates a new {ButtonswapPair} instance for the given unsorted tokens `tokenA` and `tokenB`.
     * @dev The tokens are sorted later, but can be provided to this method in either order.
     * @param tokenA The first unsorted token address
     * @param tokenB The second unsorted token address
     * @return pair The address of the new {ButtonswapPair} instance
     */
    function createPair(address tokenA, address tokenB) external returns (address pair);

    /**
     * @notice Updates the address that receives the protocol fee.
     * This can only be called by the `feeToSetter` address.
     * @param _feeTo The new address
     */
    function setFeeTo(address _feeTo) external;

    /**
     * @notice Updates the address that has the power to set the `feeToSetter` and `feeTo` addresses.
     * This can only be called by the `feeToSetter` address.
     * @param _feeToSetter The new address
     */
    function setFeeToSetter(address _feeToSetter) external;

    /**
     * @notice Updates the state of restricted creation.
     * This can only be called by the `feeToSetter` address.
     * @param _isCreationRestricted The new state
     */
    function setIsCreationRestricted(bool _isCreationRestricted) external;

    /**
     * @notice Updates the default pause state of Pairs.
     * This can only be called by the `feeToSetter` address.
     * @param _isPaused The new state
     */
    function setIsPaused(bool _isPaused) external;

    /**
     * @notice Returns the last token pair created.
     * @return token0 The first token address
     * @return token1 The second token address
     */
    function lastCreatedPairTokens() external returns (address token0, address token1);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IButtonswapFactoryErrors {
    /**
     * @notice The given token addresses are the same
     */
    error TokenIdenticalAddress();

    /**
     * @notice The given token address is the zero address
     */
    error TokenZeroAddress();

    /**
     * @notice The given tokens already have a {ButtonswapPair} instance
     */
    error PairExists();

    /**
     * @notice User does not have permission for the attempted operation
     */
    error Forbidden();
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IButtonswapFactoryEvents {
    /**
     * @notice Emitted when a new Pair is created.
     * @param token0 The first sorted token
     * @param token1 The second sorted token
     * @param pair The address of the new {ButtonswapPair} contract
     * @param count The new total number of Pairs created
     */
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256 count);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IButtonswapPairErrors} from "./IButtonswapPairErrors.sol";
import {IButtonswapPairEvents} from "./IButtonswapPairEvents.sol";
import {IButtonswapERC20} from "../IButtonswapERC20/IButtonswapERC20.sol";

interface IButtonswapPair is IButtonswapPairErrors, IButtonswapPairEvents, IButtonswapERC20 {
    /**
     * @notice The smallest value that {IButtonswapERC20-totalSupply} can be.
     * @dev After the first mint the total liquidity (represented by the liquidity token total supply) can never drop below this value.
     *
     * This is to protect against an attack where the attacker mints a very small amount of liquidity, and then donates pool tokens to skew the ratio.
     * This results in future minters receiving no liquidity tokens when they deposit.
     * By enforcing a minimum liquidity value this attack becomes prohibitively expensive to execute.
     * @return MINIMUM_LIQUIDITY The MINIMUM_LIQUIDITY value
     */
    function MINIMUM_LIQUIDITY() external pure returns (uint256 MINIMUM_LIQUIDITY);

    /**
     * @notice The address of the {ButtonswapFactory} instance used to create this Pair.
     * @dev Set to `msg.sender` in the Pair constructor.
     * @return factory The factory address
     */
    function factory() external view returns (address factory);

    /**
     * @notice The address of the first sorted token.
     * @return token0 The token address
     */
    function token0() external view returns (address token0);

    /**
     * @notice The address of the second sorted token.
     * @return token1 The token address
     */
    function token1() external view returns (address token1);

    /**
     * @notice Whether the Pair is currently paused
     * @return isPaused The paused state
     */
    function isPaused() external view returns (uint128 isPaused);

    /**
     * @notice The time-weighted average price of the Pair.
     * The price is of `token0` in terms of `token1`.
     * @dev The price is represented as a [UQ112x112](https://en.wikipedia.org/wiki/Q_(number_format)) to maintain precision.
     * Consequently this value must be divided by `2^112` to get the actual price.
     *
     * Because of the time weighting, `price0CumulativeLast` must also be divided by the total Pair lifetime to get the average price over that time period.
     * @return price0CumulativeLast The current cumulative `token0` price
     */
    function price0CumulativeLast() external view returns (uint256 price0CumulativeLast);

    /**
     * @notice The time-weighted average price of the Pair.
     * The price is of `token1` in terms of `token0`.
     * @dev The price is represented as a [UQ112x112](https://en.wikipedia.org/wiki/Q_(number_format)) to maintain precision.
     * Consequently this value must be divided by `2^112` to get the actual price.
     *
     * Because of the time weighting, `price1CumulativeLast` must also be divided by the total Pair lifetime to get the average price over that time period.
     * @return price1CumulativeLast The current cumulative `token1` price
     */
    function price1CumulativeLast() external view returns (uint256 price1CumulativeLast);

    /**
     * @notice The timestamp for when the single-sided timelock concludes.
     * The timelock is initiated based on price volatility of swaps over the last 24 hours, and can be extended by new
     *   swaps if they are sufficiently volatile.
     * The timelock protects against attempts to manipulate the price that is used to valuate the reservoir tokens during
     *   single-sided operations.
     * It also guards against general legitimate volatility, as it is preferable to defer single-sided operations until
     *   it is clearer what the market considers the price to be.
     * @return singleSidedTimelockDeadline The current deadline timestamp
     */
    function singleSidedTimelockDeadline() external view returns (uint128 singleSidedTimelockDeadline);

    /**
     * @notice The timestamp by which the amount of reservoir tokens that can be exchanged during a single-sided operation
     *   reaches its maximum value.
     * This maximum value is not necessarily the entirety of the reservoir, instead being calculated as a fraction of the
     *   corresponding token's active liquidity.
     * @return swappableReservoirLimitReachesMaxDeadline The current deadline timestamp
     */
    function swappableReservoirLimitReachesMaxDeadline()
        external
        view
        returns (uint128 swappableReservoirLimitReachesMaxDeadline);

    /**
     * @notice Get the current liquidity values.
     * @return _pool0 The active `token0` liquidity
     * @return _pool1 The active `token1` liquidity
     * @return _reservoir0 The inactive `token0` liquidity
     * @return _reservoir1 The inactive `token1` liquidity
     * @return _blockTimestampLast The timestamp of when the price was last updated
     */
    function getLiquidityBalances()
        external
        view
        returns (uint112 _pool0, uint112 _pool1, uint112 _reservoir0, uint112 _reservoir1, uint32 _blockTimestampLast);

    /**
     * @notice The current `movingAveragePrice0` value, based on the current block timestamp.
     * @dev This is the `token0` price, time weighted to prevent manipulation.
     * Refer to [reservoir-valuation.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/reservoir-valuation.md#price-stability) for more detail.
     *
     * The price is represented as a [UQ112x112](https://en.wikipedia.org/wiki/Q_(number_format)) to maintain precision.
     * It is used to valuate the reservoir tokens that are exchanged during single-sided operations.
     * @return _movingAveragePrice0 The current `movingAveragePrice0` value
     */
    function movingAveragePrice0() external view returns (uint256 _movingAveragePrice0);

    /**
     * @notice Mints new liquidity tokens to `to` based on `amountIn0` of `token0` and `amountIn1  of`token1` deposited.
     * Expects both tokens to be deposited in a ratio that matches the current Pair price.
     * @dev The token deposits are deduced to be the delta between token balance before and after the transfers in order to account for unusual tokens.
     * Refer to [mint-math.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/mint-math.md#dual-sided-mint) for more detail.
     * @param amountIn0 The amount of `token0` that should be transferred in from the user
     * @param amountIn1 The amount of `token1` that should be transferred in from the user
     * @param to The account that receives the newly minted liquidity tokens
     * @return liquidityOut THe amount of liquidity tokens minted
     */
    function mint(uint256 amountIn0, uint256 amountIn1, address to) external returns (uint256 liquidityOut);

    /**
     * @notice Mints new liquidity tokens to `to` based on how much `token0` or `token1` has been deposited.
     * The token transferred is the one that the Pair does not have a non-zero inactive liquidity balance for.
     * Expects only one token to be deposited, so that it can be paired with the other token's inactive liquidity.
     * @dev The token deposits are deduced to be the delta between token balance before and after the transfers in order to account for unusual tokens.
     * Refer to [mint-math.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/mint-math.md#single-sided-mint) for more detail.
     * @param amountIn The amount of tokens that should be transferred in from the user
     * @param to The account that receives the newly minted liquidity tokens
     * @return liquidityOut THe amount of liquidity tokens minted
     */
    function mintWithReservoir(uint256 amountIn, address to) external returns (uint256 liquidityOut);

    /**
     * @notice Burns `liquidityIn` liquidity tokens to redeem to `to` the corresponding `amountOut0` of `token0` and `amountOut1` of `token1`.
     * @dev Refer to [burn-math.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/burn-math.md#dual-sided-burn) for more detail.
     * @param liquidityIn The amount of liquidity tokens to burn
     * @param to The account that receives the redeemed tokens
     * @return amountOut0 The amount of `token0` that the liquidity tokens are redeemed for
     * @return amountOut1 The amount of `token1` that the liquidity tokens are redeemed for
     */
    function burn(uint256 liquidityIn, address to) external returns (uint256 amountOut0, uint256 amountOut1);

    /**
     * @notice Burns `liquidityIn` liquidity tokens to redeem to `to` the corresponding `amountOut0` of `token0` and `amountOut1` of `token1`.
     * Only returns tokens from the non-zero inactive liquidity balance, meaning one of `amountOut0` and `amountOut1` will be zero.
     * @dev Refer to [burn-math.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/burn-math.md#single-sided-burn) for more detail.
     * @param liquidityIn The amount of liquidity tokens to burn
     * @param to The account that receives the redeemed tokens
     * @return amountOut0 The amount of `token0` that the liquidity tokens are redeemed for
     * @return amountOut1 The amount of `token1` that the liquidity tokens are redeemed for
     */
    function burnFromReservoir(uint256 liquidityIn, address to)
        external
        returns (uint256 amountOut0, uint256 amountOut1);

    /**
     * @notice Swaps one token for the other, taking `amountIn0` of `token0` and `amountIn1` of `token1` from the sender and sending `amountOut0` of `token0` and `amountOut1` of `token1` to `to`.
     * The price of the swap is determined by maintaining the "K Invariant".
     * A 0.3% fee is collected to distribute between liquidity providers and the protocol.
     * @dev The token deposits are deduced to be the delta between the current Pair contract token balances and the last stored balances.
     * Optional calldata can be passed to `data`, which will be used to confirm the output token transfer with `to` if `to` is a contract that implements the {IButtonswapCallee} interface.
     * Refer to [swap-math.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/swap-math.md) for more detail.
     * @param amountIn0 The amount of `token0` that the sender sends
     * @param amountIn1 The amount of `token1` that the sender sends
     * @param amountOut0 The amount of `token0` that the recipient receives
     * @param amountOut1 The amount of `token1` that the recipient receives
     * @param to The account that receives the swap output
     */
    function swap(uint256 amountIn0, uint256 amountIn1, uint256 amountOut0, uint256 amountOut1, address to) external;

    /**
     * @notice Updates the pause state of the pair to the default value of the factory.
     */
    function updateIsPaused() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IButtonswapERC20Errors} from "../IButtonswapERC20/IButtonswapERC20Errors.sol";

interface IButtonswapPairErrors is IButtonswapERC20Errors {
    /**
     * @notice Re-entrancy guard prevented method call
     */
    error Locked();

    /**
     * @notice User does not have permission for the attempted operation
     */
    error Forbidden();

    /**
     * @notice Integer maximums exceeded
     */
    error Overflow();

    /**
     * @notice Initial deposit not yet made
     */
    error Uninitialized();

    /**
     * @notice There was not enough liquidity in the reservoir
     */
    error InsufficientReservoir();

    /**
     * @notice Not enough liquidity was created during mint
     */
    error InsufficientLiquidityMinted();

    /**
     * @notice Not enough funds added to mint new liquidity
     */
    error InsufficientLiquidityAdded();

    /**
     * @notice More liquidity must be burned to be redeemed for non-zero amounts
     */
    error InsufficientLiquidityBurned();

    /**
     * @notice Swap was attempted with zero input
     */
    error InsufficientInputAmount();

    /**
     * @notice Swap was attempted with zero output
     */
    error InsufficientOutputAmount();

    /**
     * @notice Pool doesn't have the liquidity to service the swap
     */
    error InsufficientLiquidity();

    /**
     * @notice The specified "to" address is invalid
     */
    error InvalidRecipient();

    /**
     * @notice The product of pool balances must not change during a swap (save for accounting for fees)
     */
    error KInvariant();

    /**
     * @notice The new price ratio after a swap is invalid (one or more of the price terms are zero)
     */
    error InvalidFinalPrice();

    /**
     * @notice Single sided operations are not executable at this point in time
     */
    error SingleSidedTimelock();

    /**
     * @notice The attempted operation would have swapped reservoir tokens above the current limit
     */
    error SwappableReservoirExceeded();

    /**
     * @notice All operations on the pair other than dual-sided burning are currently paused
     */
    error Paused();
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IButtonswapERC20Events} from "../IButtonswapERC20/IButtonswapERC20Events.sol";

interface IButtonswapPairEvents is IButtonswapERC20Events {
    /**
     * @notice Emitted when a {IButtonswapPair-mint} is performed.
     * Some `token0` and `token1` are deposited in exchange for liquidity tokens representing a claim on them.
     * @param from The account that supplied the tokens for the mint
     * @param amount0 The amount of `token0` that was deposited
     * @param amount1 The amount of `token1` that was deposited
     * @param amountOut The amount of liquidity tokens that were minted
     * @param to The account that received the tokens from the mint
     */
    event Mint(address indexed from, uint256 amount0, uint256 amount1, uint256 amountOut, address indexed to);

    /**
     * @notice Emitted when a {IButtonswapPair-burn} is performed.
     * Liquidity tokens are redeemed for underlying `token0` and `token1`.
     * @param from The account that supplied the tokens for the burn
     * @param amountIn The amount of liquidity tokens that were burned
     * @param amount0 The amount of `token0` that was received
     * @param amount1 The amount of `token1` that was received
     * @param to The account that received the tokens from the burn
     */
    event Burn(address indexed from, uint256 amountIn, uint256 amount0, uint256 amount1, address indexed to);

    /**
     * @notice Emitted when a {IButtonswapPair-swap} is performed.
     * @param from The account that supplied the tokens for the swap
     * @param amount0In The amount of `token0` that went into the swap
     * @param amount1In The amount of `token1` that went into the swap
     * @param amount0Out The amount of `token0` that came out of the swap
     * @param amount1Out The amount of `token1` that came out of the swap
     * @param to The account that received the tokens from the swap
     */
    event Swap(
        address indexed from,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// a library for performing various math operations

library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // Borrowed implementation from solmate
    // https://github.com/transmissions11/solmate/blob/2001af43aedb46fdc2335d2a7714fb2dae7cfcd1/src/utils/FixedPointMathLib.sol#L164
    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Math} from "./Math.sol";

library PairMath {
    /// @dev Refer to [mint-math.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/mint-math.md#dual-sided-mint) for more detail.
    function getDualSidedMintLiquidityOutAmount(
        uint256 totalLiquidity,
        uint256 amountInA,
        uint256 amountInB,
        uint256 totalA,
        uint256 totalB
    ) internal pure returns (uint256 liquidityOut) {
        liquidityOut = Math.min((totalLiquidity * amountInA) / totalA, (totalLiquidity * amountInB) / totalB);
    }

    /// @dev Refer to [mint-math.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/mint-math.md#single-sided-mint) for more detail.
    function getSingleSidedMintLiquidityOutAmountA(
        uint256 totalLiquidity,
        uint256 mintAmountA,
        uint256 totalA,
        uint256 totalB,
        uint256 movingAveragePriceA
    ) internal pure returns (uint256 liquidityOut, uint256 swappedReservoirAmountB) {
        // movingAveragePriceA is a UQ112x112 and so is a uint224 that needs to be divided by 2^112 after being multiplied.
        // Here we risk `movingAveragePriceA * (totalA + mintAmountA)` overflowing since we multiple a uint224 by the sum
        //   of two uint112s, however:
        //   - `totalA + mintAmountA` don't exceed 2^112 without violating max pool size.
        //   - 2^256/2^112 = 144 bits spare for movingAveragePriceA
        //   - 2^144/2^112 = 2^32 is the maximum price ratio that can be expressed without overflowing
        // Is 2^32 sufficient? Consider a pair with 1 WBTC (8 decimals) and 30,000 USDX (18 decimals)
        // log2((30000*1e18)/1e8) = 48 and as such a greater price ratio that can be handled.
        // Consequently we require a mulDiv that can handle phantom overflow.
        uint256 tokenAToSwap =
            (mintAmountA * totalB) / (Math.mulDiv(movingAveragePriceA, (totalA + mintAmountA), 2 ** 112) + totalB);
        // Here we don't risk undesired overflow because if `tokenAToSwap * movingAveragePriceA` exceeded 2^256 then it
        //   would necessarily mean `swappedReservoirAmountB` exceeded 2^112, which would result in breaking the poolX unit112 limits.
        swappedReservoirAmountB = (tokenAToSwap * movingAveragePriceA) / 2 ** 112;
        // Update totals to account for the fixed price swap
        totalA += tokenAToSwap;
        totalB -= swappedReservoirAmountB;
        uint256 tokenARemaining = mintAmountA - tokenAToSwap;
        liquidityOut =
            getDualSidedMintLiquidityOutAmount(totalLiquidity, tokenARemaining, swappedReservoirAmountB, totalA, totalB);
    }

    /// @dev Refer to [mint-math.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/mint-math.md#single-sided-mint) for more detail.
    function getSingleSidedMintLiquidityOutAmountB(
        uint256 totalLiquidity,
        uint256 mintAmountB,
        uint256 totalA,
        uint256 totalB,
        uint256 movingAveragePriceA
    ) internal pure returns (uint256 liquidityOut, uint256 swappedReservoirAmountA) {
        // `movingAveragePriceA` is a UQ112x112 and so is a uint224 that needs to be divided by 2^112 after being multiplied.
        // Here we need to use the inverse price however, which means we multiply the numerator by 2^112 and then divide that
        //   by movingAveragePriceA to get the result, all without risk of overflow.
        uint256 tokenBToSwap =
            (mintAmountB * totalA) / (((2 ** 112 * (totalB + mintAmountB)) / movingAveragePriceA) + totalA);
        // Inverse price so again we can use it without overflow risk
        swappedReservoirAmountA = (tokenBToSwap * (2 ** 112)) / movingAveragePriceA;
        // Update totals to account for the fixed price swap
        totalA -= swappedReservoirAmountA;
        totalB += tokenBToSwap;
        uint256 tokenBRemaining = mintAmountB - tokenBToSwap;
        liquidityOut =
            getDualSidedMintLiquidityOutAmount(totalLiquidity, swappedReservoirAmountA, tokenBRemaining, totalA, totalB);
    }

    /// @dev Refer to [burn-math.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/burn-math.md#dual-sided-burn) for more detail.
    function getDualSidedBurnOutputAmounts(uint256 totalLiquidity, uint256 liquidityIn, uint256 totalA, uint256 totalB)
        internal
        pure
        returns (uint256 amountOutA, uint256 amountOutB)
    {
        amountOutA = (totalA * liquidityIn) / totalLiquidity;
        amountOutB = (totalB * liquidityIn) / totalLiquidity;
    }

    /// @dev Refer to [burn-math.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/burn-math.md#single-sided-burn) for more detail.
    function getSingleSidedBurnOutputAmountA(
        uint256 totalLiquidity,
        uint256 liquidityIn,
        uint256 totalA,
        uint256 totalB,
        uint256 movingAveragePriceA
    ) internal pure returns (uint256 amountOutA, uint256 swappedReservoirAmountA) {
        // Calculate what the liquidity is worth in terms of both tokens
        uint256 amountOutB;
        (amountOutA, amountOutB) = getDualSidedBurnOutputAmounts(totalLiquidity, liquidityIn, totalA, totalB);

        // Here we need to use the inverse price however, which means we multiply the numerator by 2^112 and then divide that
        //   by movingAveragePriceA to get the result, all without risk of overflow (because amountOutB must be less than 2*2^112)
        swappedReservoirAmountA = (amountOutB * (2 ** 112)) / movingAveragePriceA;
        amountOutA = amountOutA + swappedReservoirAmountA;
    }

    /// @dev Refer to [burn-math.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/burn-math.md#single-sided-burn) for more detail.
    function getSingleSidedBurnOutputAmountB(
        uint256 totalLiquidity,
        uint256 liquidityIn,
        uint256 totalA,
        uint256 totalB,
        uint256 movingAveragePriceA
    ) internal pure returns (uint256 amountOutB, uint256 swappedReservoirAmountB) {
        // Calculate what the liquidity is worth in terms of both tokens
        uint256 amountOutA;
        (amountOutA, amountOutB) = getDualSidedBurnOutputAmounts(totalLiquidity, liquidityIn, totalA, totalB);

        // Whilst we appear to risk overflow here, the final `swappedReservoirAmountB` needs to be smaller than the reservoir
        //   which soft-caps it at 2^112.
        // As such, any combination of amountOutA and movingAveragePriceA that would overflow would violate the next
        //   check anyway, and we can therefore safely ignore the overflow potential.
        swappedReservoirAmountB = (amountOutA * movingAveragePriceA) / 2 ** 112;
        amountOutB = amountOutB + swappedReservoirAmountB;
    }

    /// @dev Refer to [swap-math.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/swap-math.md) for more detail.
    function getSwapOutputAmount(uint256 inputAmount, uint256 poolInput, uint256 poolOutput)
        internal
        pure
        returns (uint256 outputAmount)
    {
        outputAmount = (poolOutput * inputAmount * 997) / ((poolInput * 1000) + (inputAmount * 997));
    }

    /// @dev @dev Refer to [fee-math.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/fee-math.md) for more detail.
    function getProtocolFeeLiquidityMinted(uint256 totalLiquidity, uint256 kLast, uint256 k)
        internal
        pure
        returns (uint256 liquidityOut)
    {
        uint256 rootKLast = Math.sqrt(kLast);
        uint256 rootK = Math.sqrt(k);
        liquidityOut = (totalLiquidity * (rootK - rootKLast)) / ((5 * rootK) + rootKLast);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 constant Q112 = 2 ** 112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}