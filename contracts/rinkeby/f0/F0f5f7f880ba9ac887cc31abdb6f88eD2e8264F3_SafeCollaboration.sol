// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Yoinked from Rarible: https://github.com/rariblecom/protocol-contracts/blob/master/royalties/contracts/LibPart.sol
struct Part {
    address payable account;
    uint96 value;
}

bytes4 constant ERC20_ASSET_CLASS = bytes4(keccak256("ERC20"));
bytes4 constant ERC721_ASSET_CLASS = bytes4(keccak256("ERC721"));
bytes4 constant ERC1155_ASSET_CLASS = bytes4(keccak256("ERC1155"));

/**
 * @param assetClass        ERC721: bytes(keccak256("ERC721"))
 *                          ERC1155: bytes4(keccak256("ERC1155"))
 * @param collection        Address where the token is deployed
 * @param tokenNonceOrId    tokenNonce if issued
 *                          tokenId if minted
 * @param startDate         Start date of the listing for sale
 * @param endDate           End date of the listing for sale
 * @param quantity          usually one except for initial listings.
 *                          Also leaves options open for semi-fungible tokens in the future
 * @param initialPrice      Price of the listing
 * @param paymentToken      Payment token accepted for the listing
 */
struct Listing {
    bytes4 assetClass;
    address collection;
    uint256 tokenNonceOrId;
    uint256 startDate;
    uint256 endDate;
    uint256 quantity;
    uint256 initialPrice;
    address paymentToken;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Part} from "contracts/Schema.sol";
import {ISafeCollaboration} from "contracts/interfaces/ISafeCollaboration.sol";
import {SafeCollaborationStorage} from "contracts/storage/SafeCollaborationStorage.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title SafeCollaboration
 */
contract SafeCollaboration is SafeCollaborationStorage, ERC165, ISafeCollaboration {
    using Address for address;
    using Address for address payable;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**
     * @dev Requires that the msg.sender is one of the accounts in this split.
     */
    modifier onlyaccount() {
        for (uint256 i = 0; i < _shares.length; i++) {
            if (_shares[i].account == msg.sender) {
                _;
                return;
            }
        }
        revert("Split: Can only be called by one of the accounts");
    }

    /**
     * @notice Returns a tuple with the terms of this split.
     * @return shares   Shares of this collaboration. See `Schema.sol` for Part struct.
     */
    function getShares() public view override returns (Part[] memory shares) {
        return _shares;
    }

    /**
     * @notice Returns how many accounts are part of this split.
     * @return shareLength  Number of shares for this collaboration
     */
    function getShareLength()
        public
        view
        override
        returns (uint256 shareLength)
    {
        return _shares.length;
    }

    /**
     * @notice Returns a account in this split.
     * @param index Account index
     * @return Shares account
     */
    function getShareAccountByIndex(uint256 index)
        public
        view
        override
        returns (address payable)
    {
        return _shares[index].account;
    }

    /**
     * @notice Returns a account's percent share in basis points.
     * @param index         Account index
     * @return percentShare  Percent by basis points
     */
    function getPercentInBasisPointsByIndex(uint256 index)
        public
        view
        override
        returns (uint256 percentShare)
    {
        return _shares[index].value;
    }

    /**
     * @notice Returns metadata uri describing this collaboration agreement.
     * @return metadata  Uri link to additional metadata describing this collaboration
     */
    function getMetadata()
        public
        view
        override
        returns (string memory metadata)
    {
        return _metadata;
    }

    /**
     * @notice Forwards any ETH received to the accounts in this split.
     * @dev Each account increases the gas required to split
     * and contract accounts may significantly increase the gas required.
     */
    receive() external payable {
        _splitETH(msg.value);
    }

    /**
     * @notice Allows any ETH stored by the contract to be split among accounts.
     */
    function splitETH() public override {
        _splitETH(address(this).balance);
    }

    /**
     * @notice Splits ETH stored by the contract to be split among accounts
     */
    function _splitETH(uint256 value) internal {
        if (value > 0) {
            uint256 totalSent;
            uint256 amountToSend;
            for (uint256 i = _shares.length - 1; i > 0; i--) {
                Part memory share = _shares[i];
                amountToSend = (value * share.value) / BASIS_POINTS;
                totalSent += amountToSend;
                // share.account.sendValue(amountToSend);
                (bool success, ) = share.account.call{value: amountToSend}("");
                if(!success) {
                  continue;
                }
                emit ETHTransferred(share.account, amountToSend, i);
            }
            // Favor the 1st account if there are any rounding issues
            amountToSend = value - totalSent;
            (bool success, ) = _shares[0].account.call{value: amountToSend}("");
            if(success) {
                emit ETHTransferred(_shares[0].account, amountToSend, 0);
            }
        }
    }

    /**
     * @notice Anyone can call this function to split all available tokens at the provided address between the accounts.
     * @param erc20Contract Contract address of ERC20 to split
     */
    function splitERC20Tokens(IERC20 erc20Contract) public override {
        require(_splitERC20Tokens(erc20Contract), "Split: ERC20 split failed");
    }

    /**
     * @dev Anyone can call this function to split all available tokens at the provided address between the accounts.
     * Returns false on fail instead of reverting.
     */
    function _splitERC20Tokens(IERC20 erc20Contract) internal returns (bool) {
        try erc20Contract.balanceOf(address(this)) returns (uint256 balance) {
            if (balance == 0) {
                return false;
            }
            uint256 amountToSend;
            uint256 totalSent;
            for (uint256 i = _shares.length - 1; i > 0; i--) {
                Part memory share = _shares[i];
                bool success;
                (success, amountToSend) = balance.tryMul(share.value);
                if (!success) {
                    return false;
                }
                amountToSend /= BASIS_POINTS;
                totalSent += amountToSend;
                erc20Contract.safeTransfer(share.account, amountToSend);
                emit ERC20Transferred(
                    address(erc20Contract),
                    share.account,
                    amountToSend,
                    i
                );
            }
            // Favor the 1st account if there are any rounding issues
            amountToSend = balance - totalSent;
            erc20Contract.safeTransfer(_shares[0].account, amountToSend);
            emit ERC20Transferred(
                address(erc20Contract),
                _shares[0].account,
                amountToSend,
                0
            );
            return true;
        } catch {
            return false;
        }
    }

    /**
     * @notice Allows account to update address that is paid
     * @param index         Shares account index to update
     * @param newAccount    Address to replace the account with
     */
    function updateAccount(uint256 index, address payable newAccount)
        public
        override
    {
        require(_shares[index].account == msg.sender, "Invalid account index");

        _shares[index].account = newAccount;
		
		emit PercentSplitUpdate(newAccount, index);
    }

    /**
     * @notice Allows the split accounts to make an arbitrary contract call.
     * @dev This is provided to allow recovering from unexpected scenarios,
     * such as receiving an NFT at this address.
     * It will first attempt a fair split of ERC20 tokens before proceeding.
     * @param target    Target address of the proxy function call
     * @param callData  Encoded function call data
     */
    function proxyCall(address payable target, bytes memory callData)
        public
        override
        onlyaccount
    {
        _splitERC20Tokens(IERC20(target));
        target.functionCall(callData);
    }

    /**
     * @notice Returns if the interface if supported
     * @dev See {IERC165-supportsInterface}.
     * @param interfaceId Interface id to check for support
     * @return _supportsInterface True if supported, otherwise false
     */
    function supportsInterface(bytes4 interfaceId)
      public
      view
      virtual
      override
      returns (bool _supportsInterface)
    {
      return
        interfaceId == type(ISafeCollaboration).interfaceId ||
        super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Part} from "contracts/Schema.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface ISafeCollaboration {

    event PercentSplitShare(
        address indexed account,
        uint256 percentInBasisPoints,
        uint256 indexed accountIndex
    );
	event PercentSplitUpdate(
		address indexed newAccount,
		uint256 indexed accountIndex
	);
    event ETHTransferred(
        address indexed account,
        uint256 amount,
        uint256 indexed accountIndex
    );
    event ERC20Transferred(
        address indexed erc20Contract,
        address indexed account,
        uint256 amount,
        uint256 indexed accountIndex
    );

    /**
    //  * @notice Initialize a collaboration
    //  * @param shares Shares participation for the collaboration. See `Schema.sol`
    //  * @param metadata Metadata url string
    //  */
    // function initialize(Part[] memory shares, string memory metadata) external;

    /**
     * @notice Returns a tuple with the terms of this split.
     */
    function getShares() external view returns (Part[] memory shares);

    /**
     * @notice Returns how many accounts are part of this split.
     */
    function getShareLength() external view returns (uint256 shareLength) ;

    /**
     * @notice Returns a account in this split.
     */
    function getShareAccountByIndex(uint256 index)
        external
        view
        returns (address payable);

    /**
     * @notice Returns a account's percent share in basis points.
     */
    function getPercentInBasisPointsByIndex(uint256 index)
        external
        view
        returns (uint256 percentShare);

    /**
     * @notice Returns metadata uri describing this collaboration agreement.
     */
    function getMetadata() external view returns (string memory metadata);


    /**
     * @notice Allows any ETH stored by the contract to be split among accounts.
     */
    function splitETH() external; 


    /**
     * @notice Anyone can call this function to split all available tokens at the provided address between the accounts.
     */
    function splitERC20Tokens(IERC20 erc20Contract) external;

    /**
     * @notice Allows account to update address that is paid
     */
    function updateAccount(uint256 index, address payable newAccount) external;

    /**
     * @notice Allows the split accounts to make an arbitrary contract call.
     * @dev This is provided to allow recovering from unexpected scenarios,
     * such as receiving an NFT at this address.
     * It will first attempt a fair split of ERC20 tokens before proceeding.
     */
    function proxyCall(address payable target, bytes memory callData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Part} from "contracts/Schema.sol";

/**
 * @title SafeCollaborationStorage
 */
contract SafeCollaborationStorage {
    address internal _implementation;
    bool internal _initialized;
    Part[] internal _shares;
    string internal _metadata;
    uint256 internal BASIS_POINTS = 10000;
}