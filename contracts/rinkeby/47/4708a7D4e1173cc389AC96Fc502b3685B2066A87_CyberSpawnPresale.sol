/**
 *Submitted for verification at Etherscan.io on 2022-06-03
*/

// Sources flattened with hardhat v2.8.3 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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


// File @openzeppelin/contracts/utils/introspection/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// File @openzeppelin/contracts/token/ERC721/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;


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


// File @openzeppelin/contracts/utils/math/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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


// File @openzeppelin/contracts/security/[email protected]


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// File contracts/interfaces/ICyberSpawnAccessControl.sol



pragma solidity ^0.8.0;

interface ICyberSpawnAccessControl {
  function hasAdminRole(address account) external view returns (bool);
  function hasSpawnerRole(address account) external view returns (bool);
}


// File contracts/cybercity/CyberSpawnPresale.sol


pragma solidity 0.8.0;






interface ICyberSpawnNFT is IERC721 {
  function mint(address recipient, uint8 _spawnType, string memory metadataURI) external returns (uint256);
}

/**
 * @notice Presale contract for Cyber Spawn NFTs
 */

contract CyberSpawnPresale is ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  
  uint256 constant public TH = 20;                  // 100% / 5%
  uint256 constant public MAX_OWNABLE = 6;

  uint8 constant public CLASS_AVES = 0;
  uint8 constant public CLASS_MAMMALS = 1;
  uint8 constant public CLASS_REPTILES = 2;
  uint8 constant public CLASS_MOLLUSC = 3;
  uint8 constant public CLASS_AQUA = 4;

  ICyberSpawnNFT public cyberspawn;

  /// @notice payment token
  address public token = 0x55d398326f99059fF775485246999027B3197955;      // BSC USDT token

  ICyberSpawnAccessControl accessControl;
  /// @notice amount of on-sale cyberspawn
  uint256 public maxAmount = 920;
  string private metadataURI;
  
  /// @notice initial price of cyberspawn
  uint256 public initialPrice = 200 * 1e18;       // BSC USDT decimal is 18
  
  /// @notice price increase rate
  uint256 public rate = 50 * 1e18;                // BSC USDT decimal is 18

  uint256 totalRaised = 0;
  mapping (address => uint256) public contributions;

  mapping (uint8 => uint256) public sold;
  mapping (address => mapping (uint8 => uint256)) public spawns;

  /// @notice address to withdraw funds
  address public immutable wallet;

  /// @notice whitelisted address
  mapping (address => bool) public whitelist;
  uint256 public whiteAmount;

  /// @notice for pausing presale functionality and presale progress
  bool public isPaused;
  bool public onPresale;

  event PresaleContractDeployed();
  event CyberSpawnNFTPurchased(address recipient, uint256 aves, uint256 mammals, uint256 reptiles, uint256 mollusc, uint256 aqua, uint256 payAmount);
  event PresaleStarted(uint256 initialPrice, uint256 rate);
  event InitialPriceUpdated(uint256 oldVal, uint256 newVal);
  event RateUpdated(uint256 oldVal, uint256 newVal);
  event MetadataURIUpdated(string oldVal, string newVal);
  event MaxAmountUpdated(uint256 oldVal, uint256 newVal);
  event PresaleFinished(uint256 totalRaised, uint256 aves, uint256 mammals, uint256 reptiles, uint256 mollusc, uint256 aqua);

  modifier whenNotPaused() {
    require(!isPaused, "Fuction is currently paused");
    _;
  }

  modifier onlyAdmin() {
    require(accessControl.hasAdminRole(msg.sender), "not admin");
    _;
  }

  constructor(
    address _wallet, 
    ICyberSpawnNFT _nft, 
    string memory _metadataURI, 
    uint256 _whiteAmount, 
    ICyberSpawnAccessControl _accessControl
  ) {
    require(_wallet != address(0), "Presale: wallet is the zero address");
    require(address(_nft) != address(0), "Presale: NFT is zero address");
    require(address(_accessControl) != address(0), "Invalid Access Controls");

    wallet = _wallet;
    cyberspawn = _nft;
    metadataURI = _metadataURI;
    whiteAmount = _whiteAmount;
    accessControl = _accessControl;

    emit PresaleContractDeployed();
  }

  /**
   * @notice buy cyberspawn
   * @param recipient the address to receive NFTs
   * @param aves the amount of aves to purchase
   * @param mammals the amount of mammals to purchase
   * @param reptiles the amount of reptiles to purchase
   * @param mollusc the amount of mollusc to purchase
   * @param aqua the amount of aqua to purchase
   */
  function buySpawns(address recipient, uint256 aves, uint256 mammals, uint256 reptiles, uint256 mollusc, uint256 aqua) public nonReentrant whenNotPaused {
    require(recipient != address(0), "recipient is zero address");
    require(whitelist[recipient] || onPresale, "whitelist or can buy in presale peroid");
    
    // check if exceed one buy limit
    uint256 _amount = cyberspawn.balanceOf(recipient);
    require(_amount.add(aves).add(mammals).add(reptiles).add(mollusc).add(aqua) < MAX_OWNABLE, "exceed limit of ownable for one address");
    //whitelisted address can buy 
    uint256 buyAmount = aves.add(mammals).add(reptiles).add(mollusc).add(aqua);
    if (whitelist[recipient]) {
      whiteAmount = whiteAmount > buyAmount ? whiteAmount - buyAmount : 0;
    } else {
      uint256 totalSold = sold[CLASS_AVES].add(sold[CLASS_MAMMALS]).add(sold[CLASS_REPTILES]).add(sold[CLASS_MOLLUSC]).add(sold[CLASS_AQUA]);
      require(totalSold.add(buyAmount).add(whiteAmount) <= maxAmount.mul(5), "sold out");
    }

    uint256 payAmount = 0;
    if (aves > 0) {
      require(sold[CLASS_AVES].add(aves) <= maxAmount, "exceed balance");
      payAmount = _buySpawns(recipient, CLASS_AVES, aves);
    }

    if (mammals > 0) {
      require(sold[CLASS_MAMMALS].add(mammals) <= maxAmount, "exceed balance");
      payAmount = payAmount.add(_buySpawns(recipient, CLASS_MAMMALS, mammals));
    }

    if (reptiles > 0) {
      require(sold[CLASS_REPTILES].add(reptiles) <= maxAmount, "exceed balance");
      payAmount = payAmount.add(_buySpawns(recipient, CLASS_REPTILES, reptiles));
    }

    if (mollusc > 0) {
      require(sold[CLASS_MOLLUSC].add(mollusc) <= maxAmount, "exceed balance");
      payAmount = payAmount.add(_buySpawns(recipient, CLASS_MOLLUSC, mollusc));
    }

    if (aqua > 0) {
      require(sold[CLASS_AQUA].add(aqua) <= maxAmount, "exceed balance");
      payAmount = payAmount.add(_buySpawns(recipient, CLASS_AQUA, aqua));
    }

    IERC20(token).safeTransferFrom(msg.sender, address(this), payAmount);
    
    contributions[recipient] = contributions[recipient].add(payAmount);

    emit CyberSpawnNFTPurchased(recipient, aves, mammals, reptiles, mollusc, aqua, payAmount);
  }

  //////////////////////////
  ///   View Functions   ///
  //////////////////////////

  /**
   * @notice 
   *  return the current price of spawn.
   *  spawn price increases and its mechanisum is based on a bonding curve.
   * @param _spawnType spawn type value
   */
  function spawnPrice(uint8 _spawnType) external view returns (uint256) {
    uint256 bundle = maxAmount.div(TH);
    uint256 currentPrice = sold[_spawnType].div(bundle).mul(rate).add(initialPrice);
    return currentPrice;
  }

  function remainings() external view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
    uint256 totalSold = sold[CLASS_AVES].add(sold[CLASS_MAMMALS]).add(sold[CLASS_REPTILES]).add(sold[CLASS_MOLLUSC]).add(sold[CLASS_AQUA]);
    uint256 totalRemainings = maxAmount.mul(5).sub(totalSold);

    return (totalRemainings, whiteAmount, maxAmount.sub(sold[CLASS_AVES]), maxAmount.sub(sold[CLASS_MAMMALS]), maxAmount.sub(sold[CLASS_REPTILES]), maxAmount.sub(sold[CLASS_MOLLUSC]), maxAmount.sub(sold[CLASS_AQUA]));
  }

  /////////////////////////
  ///   Admin Actions   ///
  /////////////////////////

  /**
   * @notice Toggling the pause flag
   * @dev Only owner
   */
  function toggleIsPaused() external onlyAdmin {
      isPaused = !isPaused;
  }

  /**
   * @notice set the initial price of a NFT
   * @dev only owner
   * @param _price price value
   */
  function setInitialPrice(uint256 _price) external onlyAdmin {
    require(_price != 0, "price can't be zero");
    uint256 old = initialPrice;
    initialPrice = _price;

    emit InitialPriceUpdated(old, _price);
  }

  /**
   * @notice set price increasement rate
   * @dev only owner
   * @param _rate new rate
   */
  function setRate(uint256 _rate) external onlyAdmin {
    require(_rate != 0, "rate can't be zero");
    uint256 old = rate;
    rate = _rate;

    emit RateUpdated(old, _rate);
  }

  /**
   * @notice set max amount of cyberspawn to sell during presale
   * @dev only owner
   * @param _max max amount
   */
  function setMaxAmount(uint256 _max) external onlyAdmin {
    require(_max != 0, "can't be a zero");
    uint256 old = maxAmount;
    maxAmount = _max;

    emit MaxAmountUpdated(old, _max);
  }

  /**
   * @notice set the whitelisted address for presale
   * @dev only owner
   * @param _whitelist whitelisted address array
   */
  function setWhitelist(address[] memory _whitelist) external onlyAdmin {
    require(_whitelist.length != 0, "empty list");
    for (uint i = 0; i < _whitelist.length; i++) {
      require(_whitelist[i] != address(0), "!zero address");
      whitelist[_whitelist[i]] = true;
    }
  }

  function setMetadataURI(string memory _metadataURI) external onlyAdmin {
    emit MetadataURIUpdated(metadataURI, _metadataURI);
    metadataURI = _metadataURI;
  }

  /// @notice start presale
  function startPresale() external onlyAdmin {
    require(onPresale == false && totalRaised == 0, "invalid");
    onPresale = true;
    
    emit PresaleStarted(initialPrice, rate);
  }

  /// @notice stop presale
  /// @dev move fund to the admin wallet
  function stopPresale() external onlyAdmin {
    require(onPresale == true, "invalid");
    onPresale = false;
    _forwardFunds();

    emit PresaleFinished(totalRaised, sold[CLASS_AVES], sold[CLASS_MAMMALS], sold[CLASS_REPTILES], sold[CLASS_MOLLUSC], sold[CLASS_AQUA]);
  }

  //////////////////////////
  // Internal and Private //
  //////////////////////////

  function _buySpawns(address recipient, uint8 _spawnType, uint256 amount) internal returns (uint256) {
    uint256 payAmount = _spawnPrice(_spawnType, amount);
    for (uint i = 0; i < amount; i++) {
      cyberspawn.mint(recipient, _spawnType, metadataURI);
    }
    
    // Update state variables
    totalRaised = totalRaised.add(payAmount);
    spawns[recipient][_spawnType] = spawns[recipient][_spawnType].add(amount);
    sold[_spawnType] = sold[_spawnType].add(amount);

    return payAmount;
  }

  function _spawnPrice(uint8 _spawnType, uint256 amount) internal view returns (uint256) {
    uint256 bundle = maxAmount.div(TH);
    uint256 currentPrice = sold[_spawnType].div(bundle).mul(rate).add(initialPrice);           // currentPrice = initialPrice + (soldAmount / 230) * rate
    uint256 payAmount = currentPrice.mul(amount);
    uint256 firstTh = sold[_spawnType].div(bundle);
    uint256 lastTh = sold[_spawnType].add(amount).div(bundle);
    for (uint256 curTh = firstTh + 1; curTh <= lastTh; curTh++) {
      if(curTh != lastTh){
        payAmount = payAmount.add(rate.mul(curTh.sub(firstTh)).mul(bundle));
      } else {
        uint256 restAmount = sold[_spawnType].add(amount).mod(bundle);
        payAmount = payAmount.add(rate.mul(curTh.sub(firstTh)).mul(restAmount));
      }
    }

    return payAmount;
  }

  function _forwardFunds() internal {
    IERC20(token).safeTransfer(wallet, IERC20(token).balanceOf(address(this)));
  }

}