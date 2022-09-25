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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface IONtoken {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function burnONtoken(address account, uint256 amount) external;

    function collateralAssets(uint256) external view returns (address);

    function collateralsAmounts(uint256) external view returns (uint256);

    function collateralsValues(uint256) external view returns (uint256);

    function collaterizedTotalAmount() external view returns (uint256);

    function controller() external view returns (address);

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function expiryTimestamp() external view returns (uint256);

    function getCollateralAssets() external view returns (address[] memory);

    function getCollateralConstraints() external view returns (uint256[] memory);

    function getCollateralsAmounts() external view returns (uint256[] memory);

    function getCollateralsValues() external view returns (uint256[] memory);

    function getONtokenDetails()
        external
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            address,
            address,
            uint256,
            uint256,
            bool,
            uint256
        );

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function init(
        address _addressBook,
        address _underlyingAsset,
        address _strikeAsset,
        address[] memory _collateralAssets,
        uint256[] memory _collateralConstraints,
        uint256 _strikePrice,
        uint256 _expiryTimestamp,
        bool _isPut
    ) external;

    function isPut() external view returns (bool);

    function mintONtoken(
        address account,
        uint256 amount,
        uint256[] memory collateralsAmountsForMint,
        uint256[] memory collateralsValuesForMint
    ) external;

    function name() external view returns (string memory);

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

    function reduceCollaterization(
        uint256[] memory collateralsAmountsForReduce,
        uint256[] memory collateralsValuesForReduce,
        uint256 onTokenAmountBurnt
    ) external;

    function strikeAsset() external view returns (address);

    function strikePrice() external view returns (uint256);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function underlyingAsset() external view returns (address);
}

interface IONtokenFactory {
    event ONtokenCreated(
        address tokenAddress,
        address creator,
        address indexed underlying,
        address indexed strike,
        address[] indexed collateral,
        uint256 strikePrice,
        uint256 expiry,
        bool isPut
    );

    function addressBook() external view returns (address);

    function createONtoken(
        address _underlyingAsset,
        address _strikeAsset,
        address[] memory _collateralAssets,
        uint256[] memory _collateralConstraints,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external returns (address);

    function getONtoken(
        address _underlyingAsset,
        address _strikeAsset,
        address[] memory _collateralAssets,
        uint256[] memory _collateralConstraints,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external view returns (address);

    function getONtokensLength() external view returns (uint256);

    function getTargetONtokenAddress(
        address _underlyingAsset,
        address _strikeAsset,
        address[] memory _collateralAssets,
        uint256[] memory _collateralConstraints,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external view returns (address);

    function onTokens(uint256) external view returns (address);
}

interface IController {
    event AccountOperatorUpdated(address indexed accountOwner, address indexed operator, bool isSet);
    event CallExecuted(address indexed from, address indexed to, bytes data);
    event CallRestricted(bool isRestricted);
    event CollateralAssetDeposited(
        address indexed asset,
        address indexed accountOwner,
        address indexed from,
        uint256 vaultId,
        uint256 amount
    );
    event CollateralAssetWithdrawed(
        address indexed asset,
        address indexed accountOwner,
        address indexed to,
        uint256 vaultId,
        uint256 amount
    );
    event Donated(address indexed donator, address indexed asset, uint256 amount);
    event FullPauserUpdated(address indexed oldFullPauser, address indexed newFullPauser);
    event LongONtokenDeposited(
        address indexed onToken,
        address indexed accountOwner,
        address indexed from,
        uint256 vaultId,
        uint256 amount
    );
    event LongONtokenWithdrawed(
        address indexed onToken,
        address indexed accountOwner,
        address indexed to,
        uint256 vaultId,
        uint256 amount
    );
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PartialPauserUpdated(address indexed oldPartialPauser, address indexed newPartialPauser);
    event Redeem(
        address indexed onToken,
        address indexed redeemer,
        address indexed receiver,
        address[] collateralAssets,
        uint256 onTokenBurned,
        uint256[] payouts
    );
    event ShortONtokenBurned(
        address indexed onToken,
        address indexed accountOwner,
        address indexed sender,
        uint256 vaultId,
        uint256 amount
    );
    event ShortONtokenMinted(
        address indexed onToken,
        address indexed accountOwner,
        address indexed to,
        uint256 vaultId,
        uint256 amount
    );
    event SystemFullyPaused(bool isPaused);
    event SystemPartiallyPaused(bool isPaused);
    event VaultOpened(address indexed accountOwner, uint256 vaultId);
    event VaultSettled(
        address indexed accountOwner,
        address indexed shortONtoken,
        address to,
        uint256[] payouts,
        uint256 vaultId
    );

    function accountVaultCounter(address) external view returns (uint256);

    function addressbook() external view returns (address);

    function calculator() external view returns (address);

    function callRestricted() external view returns (bool);

    function canSettleAssets(
        address _underlying,
        address _strike,
        address[] memory _collaterals,
        uint256 _expiry
    ) external view returns (bool);

    function donate(address _asset, uint256 _amount) external;

    function fullPauser() external view returns (address);

    function getMaxCollateratedShortAmount(address user, uint256 vault_id) external view returns (uint256);

    function getProceed(address _owner, uint256 _vaultId) external view returns (uint256[] memory);

    function getVaultWithDetails(address _owner, uint256 _vaultId)
        external
        view
        returns (IMarginVault.Vault memory, uint256);

    function hasExpired(address _onToken) external view returns (bool);

    function initialize(address _addressBook, address _owner) external;

    function isOperator(address _owner, address _operator) external view returns (bool);

    function isSettlementAllowed(address _onToken) external view returns (bool);

    function operate(Actions.ActionArgs[] memory _actions) external;

    function oracle() external view returns (address);

    function owner() external view returns (address);

    function partialPauser() external view returns (address);

    function pool() external view returns (address);

    function refreshConfiguration() external;

    function renounceOwnership() external;

    function setFullPauser(address _fullPauser) external;

    function setOperator(address _operator, bool _isOperator) external;

    function setPartialPauser(address _partialPauser) external;

    function setSystemFullyPaused(bool _fullyPaused) external;

    function setSystemPartiallyPaused(bool _partiallyPaused) external;

    function sync(address _owner, uint256 _vaultId) external;

    function systemFullyPaused() external view returns (bool);

    function systemPartiallyPaused() external view returns (bool);

    function transferOwnership(address newOwner) external;

    function vaults(address, uint256)
        external
        view
        returns (
            address shortONtoken,
            address longONtoken,
            uint256 shortAmount,
            uint256 longAmount,
            uint256 usedLongAmount
        );

    function whitelist() external view returns (address);
}

interface IMarginVault {
    struct Vault {
        address shortONtoken;
        address longONtoken;
        address[] collateralAssets;
        uint256 shortAmount;
        uint256 longAmount;
        uint256 usedLongAmount;
        uint256[] collateralAmounts;
        uint256[] reservedCollateralAmounts;
        uint256[] usedCollateralValues;
        uint256[] availableCollateralAmounts;
    }
}

interface Actions {
    enum ActionType {
        OpenVault,
        MintShortOption,
        BurnShortOption,
        DepositLongOption,
        WithdrawLongOption,
        DepositCollateral,
        WithdrawCollateral,
        SettleVault,
        Redeem,
        Call
    }

    struct ActionArgs {
        ActionType actionType;
        address owner;
        address secondAddress;
        address[] assets;
        uint256 vaultId;
        uint256[] amounts;
    }
}

interface IOracle {
    event DisputerUpdated(address indexed newDisputer);
    event ExpiryPriceDisputed(
        address indexed asset,
        uint256 indexed expiryTimestamp,
        uint256 disputedPrice,
        uint256 newPrice,
        uint256 disputeTimestamp
    );
    event ExpiryPriceUpdated(
        address indexed asset,
        uint256 indexed expiryTimestamp,
        uint256 price,
        uint256 onchainTimestamp
    );
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PricerDisputePeriodUpdated(address indexed pricer, uint256 disputePeriod);
    event PricerLockingPeriodUpdated(address indexed pricer, uint256 lockingPeriod);
    event PricerUpdated(address indexed asset, address indexed pricer);
    event StablePriceUpdated(address indexed asset, uint256 price);

    function disputeExpiryPrice(
        address _asset,
        uint256 _expiryTimestamp,
        uint256 _price
    ) external;

    function endMigration() external;

    function getDisputer() external view returns (address);

    function getExpiryPrice(address _asset, uint256 _expiryTimestamp) external view returns (uint256, bool);

    function getPrice(address _asset) external view returns (uint256);

    function getPricer(address _asset) external view returns (address);

    function getPricerDisputePeriod(address _pricer) external view returns (uint256);

    function getPricerLockingPeriod(address _pricer) external view returns (uint256);

    function isDisputePeriodOver(address _asset, uint256 _expiryTimestamp) external view returns (bool);

    function isLockingPeriodOver(address _asset, uint256 _expiryTimestamp) external view returns (bool);

    function migrateOracle(
        address _asset,
        uint256[] memory _expiries,
        uint256[] memory _prices
    ) external;

    function owner() external view returns (address);

    function renounceOwnership() external;

    function setAssetPricer(address _asset, address _pricer) external;

    function setDisputePeriod(address _pricer, uint256 _disputePeriod) external;

    function setDisputer(address _disputer) external;

    function setExpiryPrice(
        address _asset,
        uint256 _expiryTimestamp,
        uint256 _price
    ) external;

    function setLockingPeriod(address _pricer, uint256 _lockingPeriod) external;

    function setStablePrice(address _asset, uint256 _price) external;

    function transferOwnership(address newOwner) external;
}

interface IWhitelist {
    event CollateralBlacklisted(address[] indexed collateral);
    event CollateralWhitelisted(address[] indexed collateral);
    event ONtokenBlacklisted(address indexed onToken);
    event ONtokenWhitelisted(address indexed onToken);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ProductBlacklisted(
        bytes32 productHash,
        address indexed underlying,
        address indexed strike,
        address[] indexed collateral,
        bool isPut
    );
    event ProductWhitelisted(
        bytes32 productHash,
        address indexed underlying,
        address indexed strike,
        address[] indexed collaterals,
        bool isPut
    );

    function addressBook() external view returns (address);

    function blacklistCollateral(address[] memory _collaterals) external;

    function blacklistONtoken(address _onTokenAddress) external;

    function blacklistProduct(
        address _underlying,
        address _strike,
        address[] memory _collaterals,
        bool _isPut
    ) external;

    function isWhitelistedCollaterals(address[] memory _collaterals) external view returns (bool);

    function isWhitelistedONtoken(address _onToken) external view returns (bool);

    function isWhitelistedProduct(
        address _underlying,
        address _strike,
        address[] memory _collateral,
        bool _isPut
    ) external view returns (bool);

    function owner() external view returns (address);

    function renounceOwnership() external;

    function transferOwnership(address newOwner) external;

    function whitelistCollaterals(address[] memory _collaterals) external;

    function whitelistONtoken(address _onTokenAddress) external;

    function whitelistProduct(
        address _underlying,
        address _strike,
        address[] memory _collaterals,
        bool _isPut
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Detailed is IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string calldata);

    function name() external view returns (string calldata);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library AuctionType {
    struct AuctionData {
        IERC20 auctioningToken;
        IERC20 biddingToken;
        uint256 orderCancellationEndDate;
        uint256 auctionEndDate;
        bytes32 initialAuctionOrder;
        uint256 minimumBiddingAmountPerOrder;
        uint256 interimSumBidAmount;
        bytes32 interimOrder;
        bytes32 clearingPriceOrder;
        uint96 volumeClearingPriceOrder;
        bool minFundingThresholdNotReached;
        bool isAtomicClosureAllowed;
        uint256 feeNumerator;
        uint256 minFundingThreshold;
    }
}

interface IGnosisAuction {
    function initiateAuction(
        address _auctioningToken,
        address _biddingToken,
        uint256 orderCancellationEndDate,
        uint256 auctionEndDate,
        uint96 _auctionedSellAmount,
        uint96 _minBuyAmount,
        uint256 minimumBiddingAmountPerOrder,
        uint256 minFundingThreshold,
        bool isAtomicClosureAllowed,
        address accessManagerContract,
        bytes memory accessManagerContractData
    ) external returns (uint256);

    function auctionCounter() external view returns (uint256);

    function auctionData(uint256 auctionId) external view returns (AuctionType.AuctionData memory);

    function auctionAccessManager(uint256 auctionId) external view returns (address);

    function auctionAccessData(uint256 auctionId) external view returns (bytes memory);

    function FEE_DENOMINATOR() external view returns (uint256);

    function feeNumerator() external view returns (uint256);

    function settleAuction(uint256 auctionId) external returns (bytes32);

    function placeSellOrders(
        uint256 auctionId,
        uint96[] memory _minBuyAmounts,
        uint96[] memory _sellAmounts,
        bytes32[] memory _prevSellOrders,
        bytes calldata allowListCallData
    ) external returns (uint64);

    function claimFromParticipantOrder(uint256 auctionId, bytes32[] memory orders) external returns (uint256, uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface IStrikeSelection {
    function getStrikePrice(uint256 expiryTimestamp, bool isPut) external view returns (uint256, uint256);

    function delta() external view returns (uint256);
}

interface IOptionsPremiumPricer {
    function getPremium(
        uint256 strikePrice,
        uint256 timeToExpiry,
        bool isPut
    ) external view returns (uint256);

    function getPremiumInStables(
        uint256 strikePrice,
        uint256 timeToExpiry,
        bool isPut
    ) external view returns (uint256);

    function getOptionDelta(
        uint256 spotPrice,
        uint256 strikePrice,
        uint256 volatility,
        uint256 expiryTimestamp
    ) external view returns (uint256 delta);

    function getUnderlyingPrice() external view returns (uint256);

    function priceOracle() external view returns (address);

    function volatilityOracle() external view returns (address);

    function optionId() external view returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { Vault } from "../libraries/Vault.sol";

interface INeuronThetaVault {
    function currentOption() external view returns (address);

    function nextOption() external view returns (address);

    function vaultParams() external view returns (Vault.VaultParams memory);

    function vaultState() external view returns (Vault.VaultState memory);

    function optionState() external view returns (Vault.OptionState memory);

    function optionAuctionID() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { IERC20Detailed } from "../interfaces/IERC20Detailed.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { DSMath } from "../vendor/DSMath.sol";
import { IGnosisAuction } from "../interfaces/IGnosisAuction.sol";
import { IONtoken, IOracle } from "../interfaces/GammaInterface.sol";
import { IOptionsPremiumPricer } from "../interfaces/INeuron.sol";
import { Vault } from "./Vault.sol";
import { INeuronThetaVault } from "../interfaces/INeuronThetaVault.sol";

library GnosisAuction {
    using SafeMath for uint256;
    using SafeERC20 for IERC20Detailed;

    event InitiateGnosisAuction(
        address indexed auctioningToken,
        address indexed biddingToken,
        uint256 auctionCounter,
        address indexed manager
    );

    event PlaceAuctionBid(
        uint256 auctionId,
        address indexed auctioningToken,
        uint256 sellAmount,
        uint256 buyAmount,
        address indexed bidder
    );

    struct AuctionDetails {
        address onTokenAddress;
        address gnosisEasyAuction;
        address asset;
        uint256 assetDecimals;
        uint256 onTokenPremium;
        uint256 duration;
    }

    struct BidDetails {
        address onTokenAddress;
        address gnosisEasyAuction;
        address asset;
        uint256 assetDecimals;
        uint256 auctionId;
        uint256 lockedBalance;
        uint256 optionAllocation;
        uint256 optionPremium;
        address bidder;
    }

    function startAuction(AuctionDetails calldata auctionDetails) internal returns (uint256 auctionID) {
        uint256 onTokenSellAmount = getONTokenSellAmount(auctionDetails.onTokenAddress);

        IERC20Detailed onToken = IERC20Detailed(auctionDetails.onTokenAddress);
        onToken.safeApprove(auctionDetails.gnosisEasyAuction, 0);
        onToken.safeApprove(auctionDetails.gnosisEasyAuction, onToken.balanceOf(address(this)));

        // minBidAmount is total onTokens to sell * premium per onToken
        // shift decimals to correspond to decimals of USDC for puts
        // and underlying for calls
        uint256 minBidAmount = DSMath.wmul(onTokenSellAmount.mul(10**10), auctionDetails.onTokenPremium);

        minBidAmount = auctionDetails.assetDecimals > 18
            ? minBidAmount.mul(10**(auctionDetails.assetDecimals.sub(18)))
            : minBidAmount.div(10**(uint256(18).sub(auctionDetails.assetDecimals)));

        require(minBidAmount <= type(uint96).max, "optionPremium * onTokenSellAmount > type(uint96) max value!");

        uint256 auctionEnd = block.timestamp.add(auctionDetails.duration);

        auctionID = IGnosisAuction(auctionDetails.gnosisEasyAuction).initiateAuction(
            // address of onToken we minted and are selling
            auctionDetails.onTokenAddress,
            // address of asset we want in exchange for onTokens. Should match vault `asset`
            auctionDetails.asset,
            // orders can be cancelled at any time during the auction
            auctionEnd,
            // order will last for `duration`
            auctionEnd,
            // we are selling all of the onTokens minus a fee taken by gnosis
            uint96(onTokenSellAmount),
            // the minimum we are willing to sell all the onTokens for. A discount is applied on black-scholes price
            uint96(minBidAmount),
            // the minimum bidding amount must be 1 * 10 ** -assetDecimals
            1,
            // the min funding threshold
            0,
            // no atomic closure
            false,
            // access manager contract
            address(0),
            // bytes for storing info like a whitelist for who can bid
            bytes("")
        );

        emit InitiateGnosisAuction(auctionDetails.onTokenAddress, auctionDetails.asset, auctionID, msg.sender);
    }

    function claimAuctionONtokens(
        Vault.AuctionSellOrder calldata auctionSellOrder,
        address gnosisEasyAuction,
        address counterpartyThetaVault
    ) internal {
        bytes32 order = encodeOrder(auctionSellOrder.userId, auctionSellOrder.buyAmount, auctionSellOrder.sellAmount);
        bytes32[] memory orders = new bytes32[](1);
        orders[0] = order;
        IGnosisAuction(gnosisEasyAuction).claimFromParticipantOrder(
            INeuronThetaVault(counterpartyThetaVault).optionAuctionID(),
            orders
        );
    }

    function getONTokenSellAmount(address onTokenAddress) internal view returns (uint256) {
        // We take our current onToken balance. That will be our sell amount
        // but onTokens will be transferred to gnosis.
        uint256 onTokenSellAmount = IERC20Detailed(onTokenAddress).balanceOf(address(this));

        require(onTokenSellAmount <= type(uint96).max, "onTokenSellAmount > type(uint96) max value!");

        return onTokenSellAmount;
    }

    function convertAmountOnLivePrice(
        uint256 _amount,
        address _assetA,
        address _assetB,
        address oracleAddress
    ) internal view returns (uint256) {
        if (_assetA == _assetB) {
            return _amount;
        }
        IOracle oracle = IOracle(oracleAddress);

        uint256 priceA = oracle.getPrice(_assetA);
        uint256 priceB = oracle.getPrice(_assetB);
        uint256 assetADecimals = IERC20Detailed(_assetA).decimals();
        uint256 assetBDecimals = IERC20Detailed(_assetB).decimals();

        uint256 decimalShift = assetADecimals > assetBDecimals
            ? 10**(assetADecimals.sub(assetBDecimals))
            : 10**(assetBDecimals.sub(assetADecimals));

        uint256 assetAValue = _amount.mul(priceA);

        return
            assetADecimals > assetBDecimals
                ? assetAValue.div(priceB).div(decimalShift)
                : assetAValue.mul(decimalShift).div(priceB);
    }

    function getONTokenPremium(
        address onTokenAddress,
        address optionsPremiumPricer,
        uint256 premiumDiscount
    ) internal view returns (uint256) {
        IONtoken newONToken = IONtoken(onTokenAddress);
        IOptionsPremiumPricer premiumPricer = IOptionsPremiumPricer(optionsPremiumPricer);

        // Apply black-scholes formula to option given its features
        // and get price for 100 contracts denominated in the underlying asset for call option
        // and USDC for put option
        uint256 optionPremium = premiumPricer.getPremium(
            newONToken.strikePrice(),
            newONToken.expiryTimestamp(),
            newONToken.isPut()
        );

        // Apply a discount to incentivize arbitraguers
        optionPremium = optionPremium.mul(premiumDiscount).div(100 * Vault.PREMIUM_DISCOUNT_MULTIPLIER);

        require(optionPremium <= type(uint96).max, "optionPremium > type(uint96) max value!");

        return optionPremium;
    }

    function getONTokenPremiumInToken(
        address oracleAddress,
        address onTokenAddress,
        address optionsPremiumPricer,
        uint256 premiumDiscount,
        address convertFromToken,
        address convertTonToken
    ) internal view returns (uint256) {
        IONtoken newONToken = IONtoken(onTokenAddress);
        IOptionsPremiumPricer premiumPricer = IOptionsPremiumPricer(optionsPremiumPricer);

        // Apply black-scholes formula to option given its features
        // and get price for 100 contracts denominated in the underlying asset for call option
        // and USDC for put option
        uint256 optionPremium = premiumPricer.getPremium(
            newONToken.strikePrice(),
            newONToken.expiryTimestamp(),
            newONToken.isPut()
        );

        // Apply a discount to incentivize arbitraguers
        optionPremium = optionPremium.mul(premiumDiscount).div(100 * Vault.PREMIUM_DISCOUNT_MULTIPLIER);

        optionPremium = convertAmountOnLivePrice(optionPremium, convertFromToken, convertTonToken, oracleAddress);

        require(optionPremium <= type(uint96).max, "optionPremium > type(uint96) max value!");

        return optionPremium;
    }

    function encodeOrder(
        uint64 userId,
        uint96 buyAmount,
        uint96 sellAmount
    ) internal pure returns (bytes32) {
        return bytes32((uint256(userId) << 192) + (uint256(buyAmount) << 96) + uint256(sellAmount));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { Vault } from "./Vault.sol";

library ShareMath {
    using SafeMath for uint256;

    uint256 internal constant PLACEHOLDER_UINT = 1;

    function assetToShares(
        uint256 assetAmount,
        uint256 assetPerShare,
        uint256 decimals
    ) internal pure returns (uint256) {
        // If this throws, it means that vault's roundPricePerShare[currentRound] has not been set yet
        // which should never happen.
        // Has to be larger than 1 because `1` is used in `initRoundPricePerShares` to prevent cold writes.
        require(assetPerShare > PLACEHOLDER_UINT, "Invalid assetPerShare");

        return assetAmount.mul(10**decimals).div(assetPerShare);
    }

    function sharesToAsset(
        uint256 shares,
        uint256 assetPerShare,
        uint256 decimals
    ) internal pure returns (uint256) {
        // If this throws, it means that vault's roundPricePerShare[currentRound] has not been set yet
        // which should never happen.
        // Has to be larger than 1 because `1` is used in `initRoundPricePerShares` to prevent cold writes.
        require(assetPerShare > PLACEHOLDER_UINT, "Invalid assetPerShare");

        return shares.mul(assetPerShare).div(10**decimals);
    }

    /**
     * @notice Returns the shares unredeemed by the user given their DepositReceipt
     * @param depositReceipt is the user's deposit receipt
     * @param currentRound is the `round` stored on the vault
     * @param assetPerShare is the price in asset per share
     * @param decimals is the number of decimals the asset/shares use
     * @return unredeemedShares is the user's virtual balance of shares that are owed
     */
    function getSharesFromReceipt(
        Vault.DepositReceipt memory depositReceipt,
        uint256 currentRound,
        uint256 assetPerShare,
        uint256 decimals
    ) internal pure returns (uint256 unredeemedShares) {
        if (depositReceipt.round > 0 && depositReceipt.round < currentRound) {
            uint256 sharesFromRound = assetToShares(depositReceipt.amount, assetPerShare, decimals);

            return uint256(depositReceipt.unredeemedShares).add(sharesFromRound);
        }
        return depositReceipt.unredeemedShares;
    }

    function pricePerShare(
        uint256 totalSupply,
        uint256 totalBalance,
        uint256 pendingAmount,
        uint256 decimals
    ) internal pure returns (uint256) {
        uint256 singleShare = 10**decimals;
        return totalSupply > 0 ? singleShare.mul(totalBalance.sub(pendingAmount)).div(totalSupply) : singleShare;
    }

    /************************************************
     *  HELPERS
     ***********************************************/

    function assertUint104(uint256 num) internal pure {
        require(num <= type(uint104).max, "Overflow uint104");
    }

    function assertUint128(uint256 num) internal pure {
        require(num <= type(uint128).max, "Overflow uint128");
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

library Vault {
    /************************************************
     *  IMMUTABLES & CONSTANTS
     ***********************************************/

    // Fees are 6-decimal places. For example: 20 * 10**6 = 20%
    uint256 internal constant FEE_MULTIPLIER = 10**6;

    // Premium discount has 1-decimal place. For example: 80 * 10**1 = 80%. Which represents a 20% discount.
    uint256 internal constant PREMIUM_DISCOUNT_MULTIPLIER = 10;

    struct CollateralVaultParams {
        // Option type the vault is selling
        bool isPut;
        // Token decimals for vault shares
        uint8 decimals;
        // Neuron pool address
        address collateralAsset;
        // Underlying asset of the options sold by vault
        address underlying;
        // Minimum supply of the vault shares issued, for ETH it's 10**10
        uint56 minimumSupply;
        // Vault cap
        uint104 cap;
    }

    struct CollateralUpdate {
        address[] newCollateralVaults;
        address[] newCollateralAssets;
    }

    struct VaultParams {
        // Option type the vault is selling
        bool isPut;
        // Asset used in Theta / Delta Vault
        address[] collateralAssets;
        // Underlying asset of the options sold by vault
        address underlying;
        // Addresses of collateral vaults for collateral assets
        address[] collateralVaults;
    }

    struct AuctionParams {
        // Auction duration
        uint256 auctionDuration;
        // Auction bid token address
        address auctionBiddingToken;
    }

    struct OptionState {
        // Option that the vault is shorting / longing in the next cycle
        address nextOption;
        // Option that the vault is currently shorting / longing
        address currentOption;
        // The timestamp when the `nextOption` can be used by the vault
        uint32 nextOptionReadyAt;
    }

    struct CollateralVaultState {
        // 32 byte slot 1
        //  Current round number. `round` represents the number of `period`s elapsed.
        uint16 round;
        // Amount that is currently locked for selling options
        uint104 lockedAmount;
        // Amount that was locked for selling options in the previous round
        // used for calculating performance fee deduction
        uint104 lastLockedAmount;
        // 32 byte slot 2
        // Stores the total tally of how much of `asset` there is
        // to be used to mint nTHETA tokens
        uint128 totalPending;
        // Amount locked for scheduled withdrawals;
        uint128 queuedWithdrawShares;
        bool isDisabled;
    }

    struct VaultState {
        // 32 byte slot 1
        //  Current round number. `round` represents the number of `period`s elapsed.
        uint16 round;
        // Amount that is currently locked for selling options
        uint104 lockedValue;
        // Amount that was locked for selling options in the previous round
        // used for calculating performance fee deduction
        uint104 lastLockedValue;
    }

    struct DepositReceipt {
        // Maximum of 65535 rounds. Assuming 1 round is 7 days, maximum is 1256 years.
        uint16 round;
        // Deposit amount, max 20,282,409,603,651 or 20 trillion ETH deposit
        uint104 amount;
        // Unredeemed shares balance
        uint128 unredeemedShares;
    }

    struct Withdrawal {
        // Maximum of 65535 rounds. Assuming 1 round is 7 days, maximum is 1256 years.
        uint16 round;
        // Number of shares withdrawn
        uint128 shares;
    }

    struct AuctionSellOrder {
        // Amount of `asset` token offered in auction
        uint96 sellAmount;
        // Amount of onToken requested in auction
        uint96 buyAmount;
        // User Id of delta vault in latest gnosis auction
        uint64 userId;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Vault } from "./Vault.sol";
import { ShareMath } from "./ShareMath.sol";
import { IStrikeSelection } from "../interfaces/INeuron.sol";
import { GnosisAuction } from "./GnosisAuction.sol";
import { IONtokenFactory, IONtoken, IController, Actions, IMarginVault } from "../interfaces/GammaInterface.sol";
import { IERC20Detailed } from "../interfaces/IERC20Detailed.sol";
import { IGnosisAuction } from "../interfaces/IGnosisAuction.sol";

library VaultLifecycle {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event BurnedOnTokens(address indexed ontokenAddress, uint256 amountBurned);

    struct CloseParams {
        address ON_TOKEN_FACTORY;
        address USDC;
        address currentOption;
        uint256 delay;
        uint16 lastStrikeOverrideRound;
        uint256 overriddenStrikePrice;
        uint256[] collateralConstraints;
    }

    struct ClosePremiumParams {
        address oracle;
        address strikeSelection;
        address optionsPremiumPricer;
        uint256 premiumDiscount;
        address auctionBiddingToken;
    }

    //  * @notice Sets the next option the vault will be shorting, and calculates its premium for the auction
    //  * @param strikeSelection is the address of the contract with strike selection logic
    //  * @param optionsPremiumPricer is the address of the contract with the
    //    black-scholes premium calculation logic
    //  * @param premiumDiscount is the vault's discount applied to the premium
    //  * @param closeParams is the struct with details on previous option and strike selection details
    //  * @param vaultParams is the struct with vault general data
    //  * @param vaultState is the struct with vault accounting state
    //  * @return onTokenAddress is the address of the new option
    //  * @return premium is the premium of the new option
    //  * @return strikePrice is the strike price of the new option
    //  * @return delta is the delta of the new option
    //  */
    function commitAndClose(
        address _usdc,
        uint16 round,
        Vault.VaultParams storage vaultParams,
        CloseParams calldata closeParams,
        ClosePremiumParams calldata closePremiumParams
    )
        external
        returns (
            address onTokenAddress,
            uint256 premium,
            uint256 strikePrice,
            uint256 delta
        )
    {
        bool isPut = vaultParams.isPut;
        address underlying = vaultParams.underlying;
        {
            uint256 expiry = getNextExpiry(closeParams.currentOption);

            IStrikeSelection selection = IStrikeSelection(closePremiumParams.strikeSelection);

            (strikePrice, delta) = closeParams.lastStrikeOverrideRound == round
                ? (closeParams.overriddenStrikePrice, selection.delta())
                : selection.getStrikePrice(expiry, isPut);

            require(strikePrice != 0, "!strikePrice");

            // retrieve address if option already exists, or deploy it
            onTokenAddress = getOrDeployONtoken(
                closeParams,
                vaultParams,
                underlying,
                vaultParams.collateralAssets,
                strikePrice,
                expiry,
                isPut
            );
        }

        address premiumCalcToken = _usdc;
        if (premiumCalcToken != closePremiumParams.auctionBiddingToken) {
            // get the black scholes premium of the option
            premium = GnosisAuction.getONTokenPremiumInToken(
                closePremiumParams.oracle,
                onTokenAddress,
                closePremiumParams.optionsPremiumPricer,
                closePremiumParams.premiumDiscount,
                premiumCalcToken,
                closePremiumParams.auctionBiddingToken
            );
        } else {
            // get the black scholes premium of the option
            premium = GnosisAuction.getONTokenPremium(
                onTokenAddress,
                closePremiumParams.optionsPremiumPricer,
                closePremiumParams.premiumDiscount
            );
        }
        require(premium > 0, "!premium");

        return (onTokenAddress, premium, strikePrice, delta);
    }

    /**
     * @notice Verify the onToken has the correct parameters to prevent vulnerability to option protocolcontract changes
     * @param onTokenAddress is the address of the onToken
     * @param vaultParams is the struct with vault general data
     * @param collateralAssets is the address of the collateral asset
     * @param USDC is the address of usdc
     * @param delay is the delay between commitAndClose and rollToNextOption
     */
    function verifyONtoken(
        address onTokenAddress,
        Vault.VaultParams storage vaultParams,
        address[] memory collateralAssets,
        address USDC,
        uint256 delay
    ) private view {
        require(onTokenAddress != address(0), "!onTokenAddress");

        IONtoken onToken = IONtoken(onTokenAddress);
        require(onToken.isPut() == vaultParams.isPut, "Type mismatch");
        require(onToken.underlyingAsset() == vaultParams.underlying, "Wrong underlyingAsset");
        require(
            keccak256(abi.encode(onToken.getCollateralAssets())) == keccak256(abi.encode(collateralAssets)),
            "Wrong collateralAsset"
        );

        // we just assume all options use USDC as the strike
        require(onToken.strikeAsset() == USDC, "strikeAsset != USDC");

        uint256 readyAt = block.timestamp.add(delay);
        require(onToken.expiryTimestamp() >= readyAt, "Expiry before delay");
    }

    /**
     * @notice Creates the actual Option Protocol short position by depositing collateral and minting onTokens
     * @param gammaController is the address of the option protocolcontroller contract
     * @param marginPool is the address of the option protocolmargin contract which holds the collateral
     * @param onTokenAddress is the address of the onToken to mint
     * @param depositAmounts is the amounts of collaterals to deposit
     * @return the onToken mint amount
     */
    function createShort(
        address gammaController,
        address marginPool,
        address onTokenAddress,
        uint256[] memory depositAmounts
    ) external returns (uint256, uint256) {
        IController controller = IController(gammaController);
        uint256 newVaultID = (controller.accountVaultCounter(address(this))).add(1);

        // An onToken's collateralAsset is the vault's `asset`
        // So in the context of performing Option Protocol short operations we call them collateralAsset
        IONtoken onToken = IONtoken(onTokenAddress);
        address[] memory collateralAssets = onToken.getCollateralAssets();

        for (uint256 i = 0; i < collateralAssets.length; i++) {
            // double approve to fix non-compliant ERC20s
            IERC20 collateralToken = IERC20(collateralAssets[i]);
            collateralToken.safeApprove(marginPool, 0);
            collateralToken.safeApprove(marginPool, depositAmounts[i]);
        }

        Actions.ActionArgs[] memory actions = new Actions.ActionArgs[](3);

        // Pass zero to mint using all deposited collaterals
        uint256[] memory mintAmount = new uint256[](1);

        actions[0] = Actions.ActionArgs({
            actionType: Actions.ActionType.OpenVault,
            owner: address(this), // owner
            secondAddress: onTokenAddress, // optionToken
            assets: new address[](0), // not used
            vaultId: newVaultID, // vaultId
            amounts: new uint256[](0) // not used
        });

        actions[1] = Actions.ActionArgs({
            actionType: Actions.ActionType.DepositCollateral,
            owner: address(this), // owner
            secondAddress: address(this), // address to transfer from
            assets: new address[](0), // not used
            vaultId: newVaultID, // vaultId
            amounts: depositAmounts // amounts
        });

        actions[2] = Actions.ActionArgs({
            actionType: Actions.ActionType.MintShortOption,
            owner: address(this), // owner
            secondAddress: address(this), // address to transfer to
            assets: new address[](0), // not used
            vaultId: newVaultID, // vaultId
            amounts: mintAmount // amount
        });
        controller.operate(actions);

        uint256 mintedAmount = onToken.balanceOf(address(this));

        return (mintedAmount, newVaultID);
    }

    /**
     * @notice Close the existing short onToken position. Currently this implementation is simple.
     * It closes the most recent vault opened by the contract. This assumes that the contract will
     * only have a single vault open at any given time. Since calling `_closeShort` deletes vaults by
     calling SettleVault action, this assumption should hold.
     * @param gammaController is the address of the option protocolcontroller contract
     * @return amount of collateral redeemed from the vault
     */
    function settleShort(Vault.VaultParams storage vaultParams, address gammaController)
        external
        returns (uint256[] memory)
    {
        IController controller = IController(gammaController);

        // gets the currently active vault ID
        uint256 vaultID = controller.accountVaultCounter(address(this));

        (IMarginVault.Vault memory vault, ) = controller.getVaultWithDetails(address(this), vaultID);

        require(vault.shortONtoken != address(0), "No short");

        // This is equivalent to doing IERC20(vault.asset).balanceOf(address(this))
        uint256[] memory startCollateralBalances = getCollateralBalances(vaultParams);

        // If it is after expiry, we need to settle the short position using the normal way
        // Delete the vault and withdraw all remaining collateral from the vault
        Actions.ActionArgs[] memory actions = new Actions.ActionArgs[](1);

        actions[0] = Actions.ActionArgs(
            Actions.ActionType.SettleVault,
            address(this), // owner
            address(this), // address to transfer to
            new address[](0), // not used
            vaultID, // vaultId
            new uint256[](0) // not used
        );

        controller.operate(actions);

        uint256[] memory endCollateralBalances = getCollateralBalances(vaultParams);

        return getArrayOfDiffs(endCollateralBalances, startCollateralBalances);
    }

    /**
     * @notice Burn the remaining onTokens left over from auction. Currently this implementation is simple.
     * It burns onTokens from the most recent vault opened by the contract. This assumes that the contract will
     * only have a single vault open at any given time.
     * @param gammaController is the address of the option protocolcontroller contract
     * @param currentOption is the address of the current option
     */
    function burnONtokens(address gammaController, address currentOption) external {
        uint256 numONTokensToBurn = IERC20(currentOption).balanceOf(address(this));
        require(numONTokensToBurn > 0, "No onTokens to burn");

        IController controller = IController(gammaController);

        // gets the currently active vault ID
        uint256 vaultID = controller.accountVaultCounter(address(this));

        (IMarginVault.Vault memory gammaVault, ) = controller.getVaultWithDetails(address(this), vaultID);

        require(gammaVault.shortONtoken != address(0), "No short");

        // Burning `amount` of onTokens from the neuron vault,
        // then withdrawing the corresponding collateral amount from the vault
        Actions.ActionArgs[] memory actions = new Actions.ActionArgs[](2);

        address[] memory shortONtokenAddressActionArg = new address[](1);
        shortONtokenAddressActionArg[0] = gammaVault.shortONtoken;

        uint256[] memory burnAmountActionArg = new uint256[](1);
        burnAmountActionArg[0] = numONTokensToBurn;

        actions[0] = Actions.ActionArgs({
            actionType: Actions.ActionType.BurnShortOption,
            owner: address(this), // vault owner
            secondAddress: address(0), // not used
            assets: shortONtokenAddressActionArg, // short to burn
            vaultId: vaultID,
            amounts: burnAmountActionArg // burn amount
        });

        actions[1] = Actions.ActionArgs({
            actionType: Actions.ActionType.WithdrawCollateral,
            owner: address(this), // vault owner
            secondAddress: address(this), // withdraw to
            assets: new address[](0), // not used
            vaultId: vaultID,
            amounts: new uint256[](1) // array with one zero element to withdraw all available
        });

        controller.operate(actions);

        emit BurnedOnTokens(currentOption, numONTokensToBurn);
    }

    function getCollateralBalances(Vault.VaultParams storage vaultParams) internal view returns (uint256[] memory) {
        address[] memory collateralAssets = vaultParams.collateralAssets;
        uint256 collateralsLength = collateralAssets.length;
        uint256[] memory collateralBalances = new uint256[](collateralsLength);
        for (uint256 i = 0; i < collateralsLength; i++) {
            collateralBalances[i] = IERC20(collateralAssets[i]).balanceOf(address(this));
        }
        return collateralBalances;
    }

    function getArrayOfDiffs(uint256[] memory a, uint256[] memory b) internal pure returns (uint256[] memory) {
        require(a.length == b.length, "Arrays must be of equal length");
        uint256[] memory diffs = new uint256[](a.length);
        for (uint256 i = 0; i < a.length; i++) {
            diffs[i] = a[i].sub(b[i]);
        }
        return diffs;
    }

    /**
     * @notice Either retrieves the option token if it already exists, or deploy it
     * @param closeParams is the struct with details on previous option and strike selection details
     * @param vaultParams is the struct with vault general data
     * @param underlying is the address of the underlying asset of the option
     * @param collateralAssets is the address of the collateral asset of the option
     * @param strikePrice is the strike price of the option
     * @param expiry is the expiry timestamp of the option
     * @param isPut is whether the option is a put
     * @return the address of the option
     */
    function getOrDeployONtoken(
        CloseParams calldata closeParams,
        Vault.VaultParams storage vaultParams,
        address underlying,
        address[] memory collateralAssets,
        uint256 strikePrice,
        uint256 expiry,
        bool isPut
    ) internal returns (address) {
        IONtokenFactory factory = IONtokenFactory(closeParams.ON_TOKEN_FACTORY);

        {
            address onTokenFromFactory = factory.getONtoken(
                underlying,
                closeParams.USDC,
                collateralAssets,
                closeParams.collateralConstraints,
                strikePrice,
                expiry,
                isPut
            );

            if (onTokenFromFactory != address(0)) {
                return onTokenFromFactory;
            }
        }
        address onToken = factory.createONtoken(
            underlying,
            closeParams.USDC,
            collateralAssets,
            closeParams.collateralConstraints,
            strikePrice,
            expiry,
            isPut
        );

        verifyONtoken(onToken, vaultParams, collateralAssets, closeParams.USDC, closeParams.delay);

        return onToken;
    }

    /**
     * @notice Starts the gnosis auction
     * @param auctionDetails is the struct with all the custom parameters of the auction
     * @return the auction id of the newly created auction
     */
    function startAuction(GnosisAuction.AuctionDetails calldata auctionDetails) external returns (uint256) {
        return GnosisAuction.startAuction(auctionDetails);
    }

    /**
     * @notice Settles the gnosis auction
     * @param gnosisEasyAuction is the contract address of Gnosis easy auction protocol
     * @param auctionID is the auction ID of the gnosis easy auction
     */
    function settleAuction(address gnosisEasyAuction, uint256 auctionID) internal {
        IGnosisAuction(gnosisEasyAuction).settleAuction(auctionID);
    }

    /**
     * @notice Verify the constructor params satisfy requirements
     * @param owner is the owner of the vault with critical permissions
     * @param keeper is the address of the vault keeper with vault management permissions
     * @param _vaultParams is the struct with vault general data
     */
    function verifyInitializerParams(
        address owner,
        address keeper,
        Vault.VaultParams calldata _vaultParams
    ) external pure {
        require(owner != address(0), "!owner");
        require(keeper != address(0), "!keeper");

        require(_vaultParams.collateralAssets.length != 0, "!collateralAssets");

        for (uint256 i = 0; i < _vaultParams.collateralAssets.length; i++) {
            require(_vaultParams.collateralAssets[i] != address(0), "zero address collateral asset");
        }

        require(_vaultParams.underlying != address(0), "!underlying");
    }

    /**
     * @notice Gets the next option expiry timestamp
     * @param currentOption is the onToken address that the vault is currently writing
     */
    function getNextExpiry(address currentOption) internal view returns (uint256) {
        // uninitialized state
        if (currentOption == address(0)) {
            return getNextFriday(block.timestamp);
        }
        uint256 currentExpiry = IONtoken(currentOption).expiryTimestamp();

        // After options expiry if no options are written for >1 week
        // We need to give the ability continue writing options
        if (block.timestamp > currentExpiry + 7 days) {
            return getNextFriday(block.timestamp);
        }
        return getNextFriday(currentExpiry);
    }

    /**
     * @notice Gets the next options expiry timestamp
     * @param timestamp is the expiry timestamp of the current option
     * Reference: https://codereview.stackexchange.com/a/33532
     * Examples:
     * getNextFriday(week 1 thursday) -> week 1 friday
     * getNextFriday(week 1 friday) -> week 2 friday
     * getNextFriday(week 1 saturday) -> week 2 friday
     */
    function getNextFriday(uint256 timestamp) internal pure returns (uint256) {
        // dayOfWeek = 0 (sunday) - 6 (saturday)
        uint256 dayOfWeek = ((timestamp / 1 days) + 4) % 7;
        uint256 nextFriday = timestamp + ((7 + 5 - dayOfWeek) % 7) * 1 days;
        uint256 friday8am = nextFriday - (nextFriday % (24 hours)) + (8 hours);

        // If the passed timestamp is day=Friday hour>8am, we simply increment it by a week to next Friday
        if (timestamp >= friday8am) {
            friday8am += 7 days;
        }
        return friday8am;
    }
}

// SPDX-License-Identifier: GPL-3.0

/// math.sol -- mixin for inline numerical wizardry

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >0.4.13;

library DSMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
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

    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;

    //rounds to zero if x*y < WAD / 2
    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    //rounds to zero if x*y < WAD / 2
    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    //rounds to zero if x*y < WAD / 2
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