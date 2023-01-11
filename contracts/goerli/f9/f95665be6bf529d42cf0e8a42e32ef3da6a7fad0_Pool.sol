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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// Percentage using BPS
// https://stackoverflow.com/questions/3730019/why-not-use-double-or-float-to-represent-currency/3730040#3730040

library FinMath {
    int256 public constant BPS = 10 ** 4; // basis points [TODO: move to 10**4]
    uint256 constant WAD = 10 ** 18;
    uint256 constant RAY = 10 ** 27;
    uint256 constant LIMIT = 2 ** 255;

    int256 internal constant MAX_SD59x18 =
        57896044618658097711785492504343953926634992332820282019728792003956564819967;
    int256 internal constant MIN_SD59x18 =
        -57896044618658097711785492504343953926634992332820282019728792003956564819968;

    // @notice Calculate percentage using BPS precision
    // @param bps input in base points
    // @param x the number we want to calculate percentage
    // @return the % of the x including fixed-point arithimetic
    function bps(int256 bp, uint256 x) internal pure returns (int256) {
        require(x < 2 ** 255);
        int256 y = int256(x);
        require((y * bp) >= BPS);
        return (y * bp) / BPS;
    }

    function bps(uint256 bp, uint256 x) internal pure returns (uint256) {
        uint256 UBPS = uint256(BPS);
        uint256 res = (x * bp) / UBPS;
        require(res < LIMIT); // cast overflow check
        return res;
    }

    function bps(uint256 bp, int256 x) internal pure returns (int256) {
        require(bp < LIMIT); // cast overflow check
        return bps(int256(bp), x);
    }

    function bps(int256 bp, int256 x) internal pure returns (int256) {
        return (x * bp) / BPS;
    }

    function ibps(uint256 bp, uint256 x) internal pure returns (int256) {
        uint256 UBPS = uint256(BPS);
        uint256 res = (x * bp) / UBPS;
        require(res < LIMIT); // cast overflow check
        return int(res);
    }


    // @notice somethimes we need to print int but cast them to uint befor
    function inv(int x) internal pure returns(uint) {
        if(x < 0) return uint(-x);
        if(x >=0) return uint(x);
    }


    // function bps(uint64 bp, uint256 x) internal pure returns (uint256) {
    //     return (x * bp) / uint256(BPS);
    // }

    // @notice Bring the number up to the BPS decimal format for further calculations
    // @param x number to convert
    // @return value in BPS case
    function bps(uint256 x) internal pure returns (uint256) {
        return mul(x, uint256(BPS));
    }

    // @notice Return the positive number of an int256 or zero if it was negative
    // @parame x the number we want to normalize
    // @return zero or a positive number
    function pos(int256 a) internal pure returns (uint256) {
        return (a >= 0) ? uint256(a) : 0;
    }

    // @param x The multiplicand as a signed 59.18-decimal fixed-point number.
    // @param y The multiplier as a signed 59.18-decimal fixed-point number.
    // @return result The result as a signed 59.18-decimal fixed-point number.
    // https://github.com/paulrberg/prb-math/blob/v1.0.3/contracts/PRBMathCommon.sol - license WTFPL
    function mul(int256 x, int256 y) internal pure returns (int256 result) {
        require(x > MIN_SD59x18);
        require(y > MIN_SD59x18);

        unchecked {
            uint256 ax;
            uint256 ay;
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);

            uint256 resultUnsigned = mul(ax, ay);
            require(resultUnsigned <= uint256(MAX_SD59x18));

            uint256 sx;
            uint256 sy;
            assembly {
                sx := sgt(x, sub(0, 1))
                sy := sgt(y, sub(0, 1))
            }
            result = sx ^ sy == 1
                ? -int256(resultUnsigned)
                : int256(resultUnsigned);
        }
    }

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, 'fin-math-add-overflow');
    }

    function add(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x + y) >= x, 'fin-math-add-overflow');
    }

    function isub(uint256 x, uint256 y) internal pure returns (int256 z) {
        require(x < LIMIT && y < LIMIT, 'fin-math-cast-overflow');
        return int256(x) - int256(y);
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, 'fin-math-sub-underflow');
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, 'fin-math-mul-overflow');
    }

    function add(uint256 x, int256 y) internal pure returns (uint256 z) {
        z = x + uint256(y);
        require(y >= 0 || z <= x, 'fin-math-iadd-overflow');
        require(y <= 0 || z >= x, 'fin-math-iadd-overflow');
    }

    function add(int256 x, uint256 y) internal pure returns (int256 z) {
        require(y < LIMIT, 'fin-math-cast-overflow');
        z = x + int256(y);
        // require(y >= 0 || z <= x, "fin-math-iadd-overflow");
        // require(y <= 0 || z >= x, "fin-math-iadd-overflow");
    }

    function sub(uint256 x, int256 y) internal pure returns (uint256 z) {
        z = x - uint256(y);
        require(y <= 0 || z <= x);
        require(y >= 0 || z >= x);
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x >= y ? x : y;
    }

    function imin(int256 x, int256 y) internal pure returns (int256 z) {
        return x <= y ? x : y;
    }

    function imax(int256 x, int256 y) internal pure returns (int256 z) {
        return x >= y ? x : y;
    }

    //@dev rounds to zero if x*y < WAD / 2
    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    //@notice Multiply two Wads and return a new Wad with the correct level
    // of precision. A Wad is a decimal number with 18 digits of precision
    // that is being represented as an integer.
    function wmul(int256 x, int256 y) internal pure returns (int256 z) {
        z = add(mul(x, y), int256(WAD) / 2) / int256(WAD);
    }

    //rounds to zero if x*y < WAD / 2
    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    //@notice Divide two Wads and return a new Wad with the correct level of precision.
    //@dev rounds to zero if x*y < WAD / 2
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    //rounds to zero if x*y < RAY / 2
    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@dex/perp/interfaces/IPool.sol';
import '@dex/lib/FinMath.sol';

// TODO: rename bond to shares or similar name
contract Pool is Ownable, IPool {
    using FinMath for uint256;
    using SafeERC20 for IERC20;
    uint256 constant PRECISION = 1e18;
    uint256 constant PERCENT = 1e6; // TODO: move this to global config
    uint256 public door; // Cooldown permited withdraw period
    uint256 public wfee; // Withdraw fee [wad]
    uint256 public cap; // Max deposit cap [wad]
    uint256 public immutable hold; // Cooldown waiting period
    address public immutable treasury; // gov to receive withdraw fees
    IERC20 public immutable usdc; // USDC address
    mapping(address => UserInfo) public users;
    uint256 public totalShares;
    int256 public accRewardsPerShares; // rewards are not guaranteed and can potentially turns negative
    uint256 public totalFees;
    uint256 totalNotionalValue;
    uint256 withdrawRatio; // scaling factor to gauge withdraw lock

    mapping(address => Notional) public notionals; // to calculate total open interest for all markets
    address[] public markets; // keep a list of unique markets

    enum Status {
        NONE,
        PREMATURE,
        ACTIVE,
        EXPIRED
    }

    // --- Events ---
    event Deposited(address indexed user, address indexed usdc, uint256 pay);

    event Withdrew(
        address indexed user,
        address indexed usdc,
        uint256 pay,
        uint256 per,
        uint256 fee
    );

    event Profit(address indexed user, address indexed usdc, uint256 pay);

    event Loss(address indexed user, address indexed usdc, uint256 pay);

    struct UserInfo {
        uint256 withdrawRequest; // timestamp the last time a user attempted a withdraw
        uint256 shares;
        uint256 withdrawAmount; // Promised withdraw amount on hold during the door period
        int256 accRewardsSnapshotAtLock; // used to avoid rewards aggregating while a withdraw is pending
        int256 accRewardsSnapshot;
    }

    // to track all markets risk
    struct Notional {
        uint256 amount; // open position amount
        uint256 price; // last updated price
        uint256 value; // notional value = amount * price
        bool added;
    }

    // --- Init ---
    constructor(
        address treasury_,
        IERC20 usdc_,
        uint256 wfee_,
        uint256 door_,
        uint256 hold_,
        uint256 cap_
    ) {
        require(treasury_ != address(0), 'address0');
        require(address(usdc_) != address(0), 'address0');

        treasury = treasury_;
        usdc = usdc_;
        wfee = wfee_;
        door = door_;
        hold = hold_;
        cap = cap_;
        totalNotionalValue = 0;
        withdrawRatio = 200e4; // = 200% [200e4/1e6 = 2]
    }

    // TODO: secure this function with msg.sender call + sanity checks
    function updateNotional(
        address oracle,
        uint256 price,
        uint256 amount,
        bool decrease
    ) external {
        uint256 current = notionals[oracle].amount;
        uint256 updated = (decrease) ? current - amount : current + amount;
        notionals[oracle].amount = updated;
        notionals[oracle].price = price;
        notionals[oracle].value = (updated * price) / PRECISION;
        addMarket(oracle);
    }

    // Keep a list of unique oracles updated so we can loop and get the total open interest from the mapping
    function addMarket(address oracle) internal {
        if (!notionals[oracle].added) {
            markets.push(oracle);
            notionals[oracle].added = true;
        }
    }

    function totalNotional() public view returns (uint256 total) {
        for (uint16 i = 0; i < markets.length; i++) {
            total += notionals[markets[i]].value;
        }
    }

    // return true if is valid
    function validateOICap(
        uint256 openInterestCap,
        uint256 poolBalance
    ) external view returns (bool) {
        uint256 oi = totalNotional() / poolBalance; // we do want the percentage use
        return (poolBalance == 0 || oi.bps() <= openInterestCap);
    }

    // --- Fungibility ---
    function deposit(uint256 amount) external {
        require(amount != 0, 'pool/zero-amount');
        uint256 balance = IERC20(usdc).balanceOf(address(this));
        require(amount + balance <= cap, 'pool/total-cap-exceeded');

        IERC20(usdc).safeTransferFrom(msg.sender, address(this), amount);

        UserInfo storage u = users[msg.sender];

        totalShares += amount;
        u.shares += amount;
        u.accRewardsSnapshot = accRewardsPerShares;

        // users[msg.sender] = u;

        emit Deposited(msg.sender, address(usdc), amount);
    }

    function cancelWithdraw() external {
        UserInfo storage u = users[msg.sender];
        require(u.withdrawRequest != 0, 'pool/no-withdraw-ongoing');
        u.withdrawRequest = 0;
        // modify the old snapshot, take the pnl of the withdrawal process into account
        u.accRewardsSnapshot =
            ((int256(u.shares - u.withdrawAmount) *
                (accRewardsPerShares - u.accRewardsSnapshotAtLock)) +
                (int256(u.shares) *
                    (u.accRewardsSnapshotAtLock - u.accRewardsSnapshot))) /
            int256(u.shares);
    }

    // only escrow is authorized to call
    function withdraw(uint256 amount, address recipient) external {
        UserInfo storage u = users[recipient];
        require(amount != 0, 'pool/zero-amount');
        require(amount <= u.shares, 'pool/amount-too-high');
        if (u.withdrawRequest == 0) {
            // check if this request apply for open interest conditions
            uint256 balance = IERC20(usdc).balanceOf(address(this));
            uint256 scaled = (balance * withdrawRatio) / PERCENT;
            require(totalNotional() < scaled, 'pool/LP-deposit-threshold');
            // clean state
            u.withdrawRequest = block.timestamp;
            u.withdrawAmount = amount;
            // take a snapshot of the current accRewardsPerShare
            u.accRewardsSnapshotAtLock = accRewardsPerShares;
        } else if ((block.timestamp - u.withdrawRequest) > (door + hold)) {
            totalShares = totalShares + u.withdrawAmount - amount;
            // there was a previous request but is now expired
            // modify the old snapshot, take the pnl of the withdrawal process into account
            u.accRewardsSnapshot =
                ((int256(u.shares - u.withdrawAmount) *
                    (accRewardsPerShares - u.accRewardsSnapshotAtLock)) +
                    (int256(u.shares) *
                        (u.accRewardsSnapshotAtLock - u.accRewardsSnapshot))) /
                int256(u.shares);
            u.withdrawRequest = block.timestamp;
            u.withdrawAmount = amount;
            // take a snapshot of the current accRewardsPerShare
            u.accRewardsSnapshotAtLock = accRewardsPerShares;
        } else if ((block.timestamp - u.withdrawRequest) > door) {
            require(u.withdrawAmount >= amount, 'locked-amount-too-low');
            int256 pnlSinceLock = (int256(u.shares - u.withdrawAmount) *
                (accRewardsPerShares - u.accRewardsSnapshotAtLock)) /
                int256(PRECISION);
            int256 pnlAtLock = (int256(u.shares) *
                (u.accRewardsSnapshotAtLock - u.accRewardsSnapshot)) /
                int256(PRECISION);
            int256 pnl = pnlSinceLock + pnlAtLock;
            // do we take fees if pnl is negative?
            uint256 fees = (amount * wfee) / PRECISION;
            totalFees += fees;

            // Effects
            totalShares = totalShares + u.withdrawAmount - amount; // if a difference exist, add to the totalShares
            u.shares -= amount;
            u.accRewardsSnapshot = accRewardsPerShares;
            u.withdrawRequest = 0;

            // @todo this is a naïve way to do it, should be done differently
            require(int256(amount) > (-pnl + int256(fees)), 'pnl>amount');

            usdc.safeTransfer(
                recipient,
                uint256(int256(amount) + pnl - int256(fees))
            );
        } else {
            // if we are below door period, we do a refresh
            // update the totalshare if a delta exist between previous withdraw amount and the current
            // modify the old snapshot, take the pnl of the uncanceled withdrawal process into account
            u.accRewardsSnapshot =
                ((int256(u.shares - u.withdrawAmount) *
                    (accRewardsPerShares - u.accRewardsSnapshotAtLock)) +
                    (int256(u.shares) *
                        (u.accRewardsSnapshotAtLock - u.accRewardsSnapshot))) /
                int256(u.shares);
            totalShares = totalShares + u.withdrawAmount - amount;
            u.withdrawRequest = block.timestamp;
            u.withdrawAmount = amount;
            // refresh rewards accumulation to an older date
            u.accRewardsSnapshotAtLock = accRewardsPerShares;
        }
        // // store
        // users[recipient] = u;
    }

    function setWithdrawRatio(uint256 ratio) external onlyOwner {
        withdrawRatio = ratio;
    }

    function setCoolDown(uint256 period) external onlyOwner {
        door = period;
    }

    function setWithdrawFee(uint256 fee) external onlyOwner {
        wfee = fee;
    }

    function setCap(uint256 cap_) external onlyOwner {
        cap = cap_;
    }

    function profit(uint256 amount) external onlyOwner {
        require(totalShares != 0, 'no-shares');
        IERC20(usdc).safeTransferFrom(msg.sender, address(this), amount);
        accRewardsPerShares += int256(amount * PRECISION) / int256(totalShares);
        emit Profit(msg.sender, address(usdc), amount);
    }

    function loss(uint256 amount) external onlyOwner {
        require(totalShares != 0, 'no-shares');
        IERC20(usdc).safeTransferFrom(address(this), msg.sender, amount);
        accRewardsPerShares -= int256(amount * PRECISION) / int256(totalShares);
        emit Loss(msg.sender, address(usdc), amount);
    }

    function status() public view returns (Status) {
        UserInfo memory u = users[msg.sender];
        if (u.withdrawRequest == 0) {
            // no withdrawal request pending
            return Status.NONE;
        } else if ((block.timestamp - u.withdrawRequest) > (door + hold)) {
            // there was a previous request but is now expired
            return Status.EXPIRED;
        } else if ((block.timestamp - u.withdrawRequest) > door) {
            return Status.ACTIVE;
        } else {
            return Status.PREMATURE;
        }
    }

    function withdrawFees() public onlyOwner {
        // reset totalFees accumulated
        totalFees = 0;

        usdc.safeTransfer(treasury, totalFees);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IPool {
    function totalShares() external view returns (uint256);

    function deposit(uint256 amount) external;

    function cancelWithdraw() external;

    function withdraw(uint256 amount, address recipient) external;

    function updateNotional(
        address oracle,
        uint256 price,
        uint256 amount,
        bool decrease
    ) external;

    function totalNotional() external view returns (uint256 total);

    function validateOICap(
        uint256 openInterestCap,
        uint256 poolBalance
    ) external view returns (bool);
}