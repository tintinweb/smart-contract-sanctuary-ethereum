// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

// SPDX-License-Identifier: MIT
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

pragma solidity ^0.8.0;
pragma abicoder v2;

// solhint-disable not-rely-on-time
// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IStakeManager.sol";
import "./interfaces/IRelayHub.sol";

/**
 * @title The StakeManager implementation
 * @notice An IStakeManager instance that accepts stakes in any ERC-20 token.
 *
 * @notice Single StakeInfo of a single RelayManager can only have one token address assigned to it.
 *
 * @notice It cannot be changed after the first time 'stakeForRelayManager' is called as it is equivalent to withdrawal.
 */
contract StakeManager is IStakeManager, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    string public override versionSM = "3.0.0-alpha.2+opengsn.stakemanager.istakemanager";
    uint256 internal immutable maxUnstakeDelay;

    address internal burnAddress;
    uint256 internal immutable creationBlock;

    /// maps relay managers to their stakes
    mapping(address => StakeInfo) public stakes;

    /// @inheritdoc IStakeManager
    function getStakeInfo(address relayManager) external override view returns (StakeInfo memory stakeInfo, bool isSenderAuthorizedHub) {
        bool isHubAuthorized = authorizedHubs[relayManager][msg.sender].removalTime == type(uint256).max;
        return (stakes[relayManager], isHubAuthorized);
    }

    /// @inheritdoc IStakeManager
    function setBurnAddress(address _burnAddress) public override onlyOwner {
        burnAddress = _burnAddress;
        emit BurnAddressSet(burnAddress);
    }

    /// @inheritdoc IStakeManager
    function getBurnAddress() external override view returns (address) {
        return burnAddress;
    }

    /// @inheritdoc IStakeManager
    function getMaxUnstakeDelay() external override view returns (uint256) {
        return maxUnstakeDelay;
    }

    /// maps relay managers to a map of addressed of their authorized hubs to the information on that hub
    mapping(address => mapping(address => RelayHubInfo)) public authorizedHubs;

    constructor(
        uint256 _maxUnstakeDelay,
        address _burnAddress
    ) {
        require(_burnAddress != address(0), "transfers to address(0) may fail");
        setBurnAddress(_burnAddress);
        creationBlock = block.number;
        maxUnstakeDelay = _maxUnstakeDelay;
    }

    /// @inheritdoc IStakeManager
    function getCreationBlock() external override view returns (uint256){
        return creationBlock;
    }

    /// @inheritdoc IStakeManager
    function setRelayManagerOwner(address owner) external override {
        require(owner != address(0), "invalid owner");
        require(stakes[msg.sender].owner == address(0), "already owned");
        stakes[msg.sender].owner = owner;
        emit OwnerSet(msg.sender, owner);
    }

    /// @inheritdoc IStakeManager
    function stakeForRelayManager(IERC20 token, address relayManager, uint256 unstakeDelay, uint256 amount) external override relayOwnerOnly(relayManager) {
        require(unstakeDelay >= stakes[relayManager].unstakeDelay, "unstakeDelay cannot be decreased");
        require(unstakeDelay <= maxUnstakeDelay, "unstakeDelay too big");
        require(token != IERC20(address(0)), "must specify stake token address");
        require(
            stakes[relayManager].token == IERC20(address(0)) ||
            stakes[relayManager].token == token,
            "stake token address is incorrect");
        token.safeTransferFrom(msg.sender, address(this), amount);
        stakes[relayManager].token = token;
        stakes[relayManager].stake += amount;
        stakes[relayManager].unstakeDelay = unstakeDelay;
        emit StakeAdded(relayManager, stakes[relayManager].owner, stakes[relayManager].token, stakes[relayManager].stake, stakes[relayManager].unstakeDelay);
    }

    /// @inheritdoc IStakeManager
    function unlockStake(address relayManager) external override relayOwnerOnly(relayManager) {
        StakeInfo storage info = stakes[relayManager];
        require(info.withdrawTime == 0, "already pending");
        info.withdrawTime = block.timestamp.add(info.unstakeDelay);
        emit StakeUnlocked(relayManager, msg.sender, info.withdrawTime);
    }

    /// @inheritdoc IStakeManager
    function withdrawStake(address relayManager) external override relayOwnerOnly(relayManager) {
        StakeInfo storage info = stakes[relayManager];
        require(info.withdrawTime > 0, "Withdrawal is not scheduled");
        require(info.withdrawTime <= block.timestamp, "Withdrawal is not due");
        uint256 amount = info.stake;
        info.stake = 0;
        info.withdrawTime = 0;
        info.token.safeTransfer(msg.sender, amount);
        emit StakeWithdrawn(relayManager, msg.sender, info.token, amount);
    }

    /// @notice Prevents any address other than a registered Relay Owner from calling this method.
    modifier relayOwnerOnly (address relayManager) {
        StakeInfo storage info = stakes[relayManager];
        require(info.owner == msg.sender, "not owner");
        _;
    }

    /// @notice Prevents any address other than a registered Relay Manager from calling this method.
    modifier managerOnly () {
        StakeInfo storage info = stakes[msg.sender];
        require(info.owner != address(0), "not manager");
        _;
    }

    /// @inheritdoc IStakeManager
    function authorizeHubByOwner(address relayManager, address relayHub) external relayOwnerOnly(relayManager) override {
        _authorizeHub(relayManager, relayHub);
    }

    /// @inheritdoc IStakeManager
    function authorizeHubByManager(address relayHub) external managerOnly override {
        _authorizeHub(msg.sender, relayHub);
    }

    function _authorizeHub(address relayManager, address relayHub) internal {
        authorizedHubs[relayManager][relayHub].removalTime = type(uint256).max;
        emit HubAuthorized(relayManager, relayHub);
    }

    /// @inheritdoc IStakeManager
    function unauthorizeHubByOwner(address relayManager, address relayHub) external override relayOwnerOnly(relayManager) {
        _unauthorizeHub(relayManager, relayHub);
    }

    /// @inheritdoc IStakeManager
    function unauthorizeHubByManager(address relayHub) external override managerOnly {
        _unauthorizeHub(msg.sender, relayHub);
    }

    function _unauthorizeHub(address relayManager, address relayHub) internal {
        RelayHubInfo storage hubInfo = authorizedHubs[relayManager][relayHub];
        require(hubInfo.removalTime == type(uint256).max, "hub not authorized");
        hubInfo.removalTime = block.timestamp.add(stakes[relayManager].unstakeDelay);
        emit HubUnauthorized(relayManager, relayHub, hubInfo.removalTime);
    }

    /// @inheritdoc IStakeManager
    function penalizeRelayManager(address relayManager, address beneficiary, uint256 amount) external override {
        uint256 removalTime = authorizedHubs[relayManager][msg.sender].removalTime;
        require(removalTime != 0, "hub not authorized");
        require(removalTime > block.timestamp, "hub authorization expired");

        // Half of the stake will be burned (sent to address 0)
        require(stakes[relayManager].stake >= amount, "penalty exceeds stake");
        stakes[relayManager].stake = SafeMath.sub(stakes[relayManager].stake, amount);

        uint256 toBurn = SafeMath.div(amount, 2);
        uint256 reward = SafeMath.sub(amount, toBurn);

        // Stake ERC-20 token is burned and transferred
        stakes[relayManager].token.safeTransfer(burnAddress, toBurn);
        stakes[relayManager].token.safeTransfer(beneficiary, reward);
        emit StakePenalized(relayManager, beneficiary, stakes[relayManager].token, reward);
    }
}

pragma solidity >=0.7.6;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/interfaces/IERC165.sol";

/**
 * @title The Forwarder Interface
 * @notice The contracts implementing this interface take a role of authorization, authentication and replay protection
 * for contracts that choose to trust a `Forwarder`, instead of relying on a mechanism built into the Ethereum protocol.
 *
 * @notice if the `Forwarder` contract decides that an incoming `ForwardRequest` is valid, it must append 20 bytes that
 * represent the caller to the `data` field of the request and send this new data to the target address (the `to` field)
 *
 * :warning: **Warning** :warning: The Forwarder can have a full control over a `Recipient` contract.
 * Any vulnerability in a `Forwarder` implementation can make all of its `Recipient` contracts susceptible!
 * Recipient contracts should only trust forwarders that passed through security audit,
 * otherwise they are susceptible to identity theft.
 */
interface IForwarder is IERC165 {

    /**
     * @notice A representation of a request for a `Forwarder` to send `data` on behalf of a `from` to a target (`to`).
     */
    struct ForwardRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        bytes data;
        uint256 validUntilTime;
    }

    event DomainRegistered(bytes32 indexed domainSeparator, bytes domainValue);

    event RequestTypeRegistered(bytes32 indexed typeHash, string typeStr);

    /**
     * @param from The address of a sender.
     * @return The nonce for this address.
     */
    function getNonce(address from)
    external view
    returns(uint256);

    /**
     * @notice Verify the transaction is valid and can be executed.
     * Implementations must validate the signature and the nonce of the request are correct.
     * Does not revert and returns successfully if the input is valid.
     * Reverts if any validation has failed. For instance, if either signature or nonce are incorrect.
     * Reverts if `domainSeparator` or `requestTypeHash` are not registered as well.
     */
    function verify(
        ForwardRequest calldata forwardRequest,
        bytes32 domainSeparator,
        bytes32 requestTypeHash,
        bytes calldata suffixData,
        bytes calldata signature
    ) external view;

    /**
     * @notice Executes a transaction specified by the `ForwardRequest`.
     * The transaction is first verified and then executed.
     * The success flag and returned bytes array of the `CALL` are returned as-is.
     *
     * This method would revert only in case of a verification error.
     *
     * All the target errors are reported using the returned success flag and returned bytes array.
     *
     * @param forwardRequest All requested transaction parameters.
     * @param domainSeparator The domain used when signing this request.
     * @param requestTypeHash The request type used when signing this request.
     * @param suffixData The ABI-encoded extension data for the current `RequestType` used when signing this request.
     * @param signature The client signature to be validated.
     *
     * @return success The success flag of the underlying `CALL` to the target address.
     * @return ret The byte array returned by the underlying `CALL` to the target address.
     */
    function execute(
        ForwardRequest calldata forwardRequest,
        bytes32 domainSeparator,
        bytes32 requestTypeHash,
        bytes calldata suffixData,
        bytes calldata signature
    )
    external payable
    returns (bool success, bytes memory ret);

    /**
     * @notice Register a new Request typehash.
     *
     * @notice This is necessary for the Forwarder to be able to verify the signatures conforming to the ERC-712.
     *
     * @param typeName The name of the request type.
     * @param typeSuffix Any extra data after the generic params. Must contain add at least one param.
     * The generic ForwardRequest type is always registered by the constructor.
     */
    function registerRequestType(string calldata typeName, string calldata typeSuffix) external;

    /**
     * @notice Register a new domain separator.
     *
     * @notice This is necessary for the Forwarder to be able to verify the signatures conforming to the ERC-712.
     *
     * @notice The domain separator must have the following fields: `name`, `version`, `chainId`, `verifyingContract`.
     * The `chainId` is the current network's `chainId`, and the `verifyingContract` is this Forwarder's address.
     * This method accepts the domain name and version to create and register the domain separator value.
     * @param name The domain's display name.
     * @param version The domain/protocol version.
     */
    function registerDomainSeparator(string calldata name, string calldata version) external;
}

pragma solidity >=0.7.6;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/interfaces/IERC165.sol";

import "../utils/GsnTypes.sol";
import "./IStakeManager.sol";

/**
 * @title The RelayHub interface
 * @notice The implementation of this interface provides all the information the GSN client needs to
 * create a valid `RelayRequest` and also serves as an entry point for such requests.
 *
 * @notice The RelayHub also handles all the related financial records and hold the balances of participants.
 * The Paymasters keep their Ether deposited in the `RelayHub` in order to pay for the `RelayRequest`s that thay choose
 * to pay for, and Relay Servers keep their earned Ether in the `RelayHub` until they choose to `withdraw()`
 *
 * @notice The RelayHub on each supported network only needs a single instance and there is usually no need for dApp
 * developers or Relay Server operators to redeploy, reimplement, modify or override the `RelayHub`.
 */
interface IRelayHub is IERC165 {
    /**
     * @notice A struct that contains all the parameters of the `RelayHub` that can be modified after the deployment.
     */
    struct RelayHubConfig {
        // maximum number of worker accounts allowed per manager
        uint256 maxWorkerCount;
        // Gas set aside for all relayCall() instructions to prevent unexpected out-of-gas exceptions
        uint256 gasReserve;
        // Gas overhead to calculate gasUseWithoutPost
        uint256 postOverhead;
        // Gas cost of all relayCall() instructions after actual 'calculateCharge()'
        // Assume that relay has non-zero balance (costs 15'000 more otherwise).
        uint256 gasOverhead;
        // Minimum unstake delay seconds of a relay manager's stake on the StakeManager
        uint256 minimumUnstakeDelay;
        // Developers address
        address devAddress;
        // 0 < fee < 100, as percentage of total charge from paymaster to relayer
        uint8 devFee;

    }

    /// @notice Emitted when a configuration of the `RelayHub` is changed
    event RelayHubConfigured(RelayHubConfig config);

    /// @notice Emitted when relays are added by a relayManager
    event RelayWorkersAdded(
        address indexed relayManager,
        address[] newRelayWorkers,
        uint256 workersCount
    );

    /// @notice Emitted when an account withdraws funds from the `RelayHub`.
    event Withdrawn(
        address indexed account,
        address indexed dest,
        uint256 amount
    );

    /// @notice Emitted when `depositFor` is called, including the amount and account that was funded.
    event Deposited(
        address indexed paymaster,
        address indexed from,
        uint256 amount
    );

    /// @notice Emitted for each token configured for staking in setMinimumStakes
    event StakingToken(
        address token,
        uint minimumStake
    );

    /**
     * @notice Emitted when an attempt to relay a call fails and the `Paymaster` does not accept the transaction.
     * The actual relayed call was not executed, and the recipient not charged.
     * @param reason contains a revert reason returned from preRelayedCall or forwarder.
     */
    event TransactionRejectedByPaymaster(
        address indexed relayManager,
        address indexed paymaster,
        bytes32 indexed relayRequestID,
        address from,
        address to,
        address relayWorker,
        bytes4 selector,
        uint256 innerGasUsed,
        bytes reason
    );

    /**
     * @notice Emitted when a transaction is relayed. Note that the actual internal function call might be reverted.
     * The reason for a revert will be indicated in the `status` field of a corresponding `RelayCallStatus` value.
     * @notice `charge` is the Ether value deducted from the `Paymaster` balance.
     * The amount added to the `relayManager` balance will be lower if there is an activated `devFee` in the `config`.
     */
    event TransactionRelayed(
        address indexed relayManager,
        address indexed relayWorker,
        bytes32 indexed relayRequestID,
        address from,
        address to,
        address paymaster,
        bytes4 selector,
        RelayCallStatus status,
        uint256 charge
    );

    /// @notice This event is emitted in case the internal function returns a value or reverts with a revert string.
    event TransactionResult(
        RelayCallStatus status,
        bytes returnValue
    );

    /// @notice This event is emitted in case this `RelayHub` is deprecated and will stop serving transactions soon.
    event HubDeprecated(uint256 deprecationTime);

    /**
     * Error codes that describe all possible failure reasons reported in the `TransactionRelayed` event `status` field.
     *  @param OK The transaction was successfully relayed and execution successful - never included in the event.
     *  @param RelayedCallFailed The transaction was relayed, but the relayed call failed.
     *  @param RejectedByPreRelayed The transaction was not relayed due to preRelatedCall reverting.
     *  @param RejectedByForwarder The transaction was not relayed due to forwarder check (signature,nonce).
     *  @param PostRelayedFailed The transaction was relayed and reverted due to postRelatedCall reverting.
     *  @param PaymasterBalanceChanged The transaction was relayed and reverted due to the paymaster balance change.
     */
    enum RelayCallStatus {
        OK,
        RelayedCallFailed,
        RejectedByPreRelayed,
        RejectedByForwarder,
        RejectedByRecipientRevert,
        PostRelayedFailed,
        PaymasterBalanceChanged
    }

    /**
     * @notice Add new worker addresses controlled by the sender who must be a staked Relay Manager address.
     * Emits a `RelayWorkersAdded` event.
     * This function can be called multiple times, emitting new events.
     */
    function addRelayWorkers(address[] calldata newRelayWorkers) external;

    function verifyCanRegister(address relayManager) external;

    // Balance management

    /**
     * @notice Deposits ether for a `Paymaster`, so that it can and pay for relayed transactions.
     * :warning: **Warning** :warning: Unused balance can only be withdrawn by the holder itself, by calling `withdraw`.
     * Emits a `Deposited` event.
     */
    function depositFor(address target) external payable;

    /**
     * @notice Withdraws from an account's balance, sending it back to the caller.
     * Relay Managers call this to retrieve their revenue, and `Paymasters` can also use it to reduce their funding.
     * Emits a `Withdrawn` event.
     */
    function withdraw(uint256 amount, address payable dest) external;

    // Relaying

    /**
     * @notice Relays a transaction. For this to succeed, multiple conditions must be met:
     *  - `Paymaster`'s `preRelayCall` method must succeed and not revert.
     *  - the `msg.sender` must be a registered Relay Worker that the user signed to use.
     *  - the transaction's gas fees must be equal or larger than the ones that were signed by the sender.
     *  - the transaction must have enough gas to run all internal transactions if they use all gas available to them.
     *  - the `Paymaster` must have enough balance to pay the Relay Worker if all gas is spent.
     *
     * @notice If all conditions are met, the call will be relayed and the `Paymaster` charged.
     *
     * @param maxAcceptanceBudget The maximum valid value for `paymaster.getGasLimits().acceptanceBudget` to return.
     * @param relayRequest All details of the requested relayed call.
     * @param signature The client's EIP-712 signature over the `relayRequest` struct.
     * @param approvalData The dapp-specific data forwarded to the `Paymaster`'s `preRelayedCall` method.
     * This value is **not** verified by the `RelayHub` in any way.
     * As an example, it can be used to pass some kind of a third-party signature to the `Paymaster` for verification.
     *
     * Emits a `TransactionRelayed` event regardless of whether the transaction succeeded or failed.
     */
    function relayCall(
        uint256 maxAcceptanceBudget,
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData
    )
    external
    returns (bool paymasterAccepted, bytes memory returnValue);

    /**
     * @notice In case the Relay Worker has been found to be in violation of some rules by the `Penalizer` contract,
     * the `Penalizer` will call this method to execute a penalization.
     * The `RelayHub` will look up the Relay Manager of the given Relay Worker and will forward the call to
     * the `StakeManager` contract. The `RelayHub` does not perform the actual penalization either.
     * @param relayWorker The address of the Relay Worker that committed a penalizable offense.
     * @param beneficiary The address that called the `Penalizer` and will receive a reward for it.
     */
    function penalize(address relayWorker, address payable beneficiary) external;

    /**
     * @notice Sets or changes the configuration of this `RelayHub`.
     * @param _config The new configuration.
     */
    function setConfiguration(RelayHubConfig memory _config) external;

    /**
     * @notice Sets or changes the minimum amount of a given `token` that needs to be staked so that the Relay Manager
     * is considered to be 'staked' by this `RelayHub`. Zero value means this token is not allowed for staking.
     * @param token An array of addresses of ERC-20 compatible tokens.
     * @param minimumStake An array of minimal amounts necessary for a corresponding token, in wei.
     */
    function setMinimumStakes(IERC20[] memory token, uint256[] memory minimumStake) external;

    /**
     * @notice Deprecate hub by reverting all incoming `relayCall()` calls starting from a given timestamp
     * @param _deprecationTime The timestamp in seconds after which the `RelayHub` stops serving transactions.
     */
    function deprecateHub(uint256 _deprecationTime) external;

    /**
     * @notice The fee is expressed as a base fee in wei plus percentage of the actual charge.
     * For example, a value '40' stands for a 40% fee, so the recipient will be charged for 1.4 times the spent amount.
     * @param gasUsed An amount of gas used by the transaction.
     * @param relayData The details of a transaction signed by the sender.
     * @return The calculated charge, in wei.
     */
    function calculateCharge(uint256 gasUsed, GsnTypes.RelayData calldata relayData) external view returns (uint256);

    /**
     * @notice The fee is expressed as a  percentage of the actual charge.
     * For example, a value '40' stands for a 40% fee, so the Relay Manager will only get 60% of the `charge`.
     * @param charge The amount of Ether in wei the Paymaster will be charged for this transaction.
     * @return The calculated devFee, in wei.
     */
    function calculateDevCharge(uint256 charge) external view returns (uint256);
    /* getters */

    /// @return config The configuration of the `RelayHub`.
    function getConfiguration() external view returns (RelayHubConfig memory config);

    /**
     * @param token An address of an ERC-20 compatible tokens.
     * @return The minimum amount of a given `token` that needs to be staked so that the Relay Manager
     * is considered to be 'staked' by this `RelayHub`. Zero value means this token is not allowed for staking.
     */
    function getMinimumStakePerToken(IERC20 token) external view returns (uint256);

    /**
     * @param worker An address of the Relay Worker.
     * @return The address of its Relay Manager.
     */
    function getWorkerManager(address worker) external view returns (address);

    /**
     * @param manager An address of the Relay Manager.
     * @return The count of Relay Workers associated with this Relay Manager.
     */
    function getWorkerCount(address manager) external view returns (uint256);

    /// @return An account's balance. It can be either a deposit of a `Paymaster`, or a revenue of a Relay Manager.
    function balanceOf(address target) external view returns (uint256);

    /// @return The `StakeManager` address for this `RelayHub`.
    function getStakeManager() external view returns (IStakeManager);

    /// @return The `Penalizer` address for this `RelayHub`.
    function getPenalizer() external view returns (address);

    /// @return The `RelayRegistrar` address for this `RelayHub`.
    function getRelayRegistrar() external view returns (address);

    /// @return The `BatchGateway` address for this `RelayHub`.
    function getBatchGateway() external view returns (address);

    /**
     * @notice Uses `StakeManager` to decide if the Relay Manager can be considered staked or not.
     * Returns if the stake's token, amount and delay satisfy all requirements, reverts otherwise.
     */
    function verifyRelayManagerStaked(address relayManager) external view;

    /// @return `true` if the `RelayHub` is deprecated, `false` it it is not deprecated and can serve transactions.
    function isDeprecated() external view returns (bool);

    /// @return The timestamp from which the hub no longer allows relaying calls.
    function getDeprecationTime() external view returns (uint256);

    /// @return The block number in which the contract has been deployed.
    function getCreationBlock() external view returns (uint256);

    /// @return a SemVer-compliant version of the `RelayHub` contract.
    function versionHub() external view returns (string memory);

    /// @return A total measurable amount of gas left to current execution. Same as 'gasleft()' for pure EVMs.
    function aggregateGasleft() external view returns (uint256);
}

pragma solidity >=0.7.6;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title The StakeManager Interface
 * @notice In order to prevent an attacker from registering a large number of unresponsive relays, the GSN requires
 * the Relay Server to maintain a permanently locked stake in the system before being able to register.
 *
 * @notice Also, in some cases the behavior of a Relay Server may be found to be illegal by a `Penalizer` contract.
 * In such case, the stake will never be returned to the Relay Server operator and will be slashed.
 *
 * @notice An implementation of this interface is tasked with keeping Relay Servers' stakes, made in any ERC-20 token.
 * Note that the `RelayHub` chooses which ERC-20 tokens to support and how much stake is needed.
 */
interface IStakeManager {

    /// @notice Emitted when a `stake` or `unstakeDelay` are initialized or increased.
    event StakeAdded(
        address indexed relayManager,
        address indexed owner,
        IERC20 token,
        uint256 stake,
        uint256 unstakeDelay
    );

    /// @notice Emitted once a stake is scheduled for withdrawal.
    event StakeUnlocked(
        address indexed relayManager,
        address indexed owner,
        uint256 withdrawTime
    );

    /// @notice Emitted when owner withdraws `relayManager` funds.
    event StakeWithdrawn(
        address indexed relayManager,
        address indexed owner,
        IERC20 token,
        uint256 amount
    );

    /// @notice Emitted when an authorized `RelayHub` penalizes a `relayManager`.
    event StakePenalized(
        address indexed relayManager,
        address indexed beneficiary,
        IERC20 token,
        uint256 reward
    );

    /// @notice Emitted when a `relayManager` adds a new `RelayHub` to a list of authorized.
    event HubAuthorized(
        address indexed relayManager,
        address indexed relayHub
    );

    /// @notice Emitted when a `relayManager` removes a `RelayHub` from a list of authorized.
    event HubUnauthorized(
        address indexed relayManager,
        address indexed relayHub,
        uint256 removalTime
    );

    /// @notice Emitted when a `relayManager` sets its `owner`. This is necessary to prevent stake hijacking.
    event OwnerSet(
        address indexed relayManager,
        address indexed owner
    );

    /// @notice Emitted when a `burnAddress` is changed.
    event BurnAddressSet(
        address indexed burnAddress
    );

    /**
     * @param stake - amount of ether staked for this relay
     * @param unstakeDelay - number of seconds to elapse before the owner can retrieve the stake after calling 'unlock'
     * @param withdrawTime - timestamp in seconds when 'withdraw' will be callable, or zero if the unlock has not been called
     * @param owner - address that receives revenue and manages relayManager's stake
     */
    struct StakeInfo {
        uint256 stake;
        uint256 unstakeDelay;
        uint256 withdrawTime;
        IERC20 token;
        address owner;
    }

    struct RelayHubInfo {
        uint256 removalTime;
    }

    /**
     * @notice Set the owner of a Relay Manager. Called only by the RelayManager itself.
     * Note that owners cannot transfer ownership - if the entry already exists, reverts.
     * @param owner - owner of the relay (as configured off-chain)
     */
    function setRelayManagerOwner(address owner) external;

    /**
     * @notice Put a stake for a relayManager and set its unstake delay.
     * Only the owner can call this function. If the entry does not exist, reverts.
     * The owner must give allowance of the ERC-20 token to the StakeManager before calling this method.
     * It is the RelayHub who has a configurable list of minimum stakes per token. StakeManager accepts all tokens.
     * @param token The address of an ERC-20 token that is used by the relayManager as a stake
     * @param relayManager The address that represents a stake entry and controls relay registrations on relay hubs
     * @param unstakeDelay The number of seconds to elapse before an owner can retrieve the stake after calling `unlock`
     * @param amount The amount of tokens to be taken from the relayOwner and locked in the StakeManager as a stake
     */
    function stakeForRelayManager(IERC20 token, address relayManager, uint256 unstakeDelay, uint256 amount) external;

    /**
     * @notice Schedule the unlocking of the stake. The `unstakeDelay` must pass before owner can call `withdrawStake`.
     * @param relayManager The address of a Relay Manager whose stake is to be unlocked.
     */
    function unlockStake(address relayManager) external;
    /**
     * @notice Withdraw the unlocked stake.
     * @param relayManager The address of a Relay Manager whose stake is to be withdrawn.
     */
    function withdrawStake(address relayManager) external;

    /**
     * @notice Add the `RelayHub` to a list of authorized by this Relay Manager.
     * This allows the RelayHub to penalize this Relay Manager. The `RelayHub` cannot trust a Relay it cannot penalize.
     * @param relayManager The address of a Relay Manager whose stake is to be authorized for the new `RelayHub`.
     * @param relayHub The address of a `RelayHub` to be authorized.
     */
    function authorizeHubByOwner(address relayManager, address relayHub) external;

    /**
     * @notice Same as `authorizeHubByOwner` but can be called by the RelayManager itself.
     */
    function authorizeHubByManager(address relayHub) external;

    /**
     * @notice Remove the `RelayHub` from a list of authorized by this Relay Manager.
     * @param relayManager The address of a Relay Manager.
     * @param relayHub The address of a `RelayHub` to be unauthorized.
     */
    function unauthorizeHubByOwner(address relayManager, address relayHub) external;

    /**
     * @notice Same as `unauthorizeHubByOwner` but can be called by the RelayManager itself.
     */
    function unauthorizeHubByManager(address relayHub) external;

    /**
     * Slash the stake of the relay relayManager. In order to prevent stake kidnapping, burns part of stake on the way.
     * @param relayManager The address of a Relay Manager to be penalized.
     * @param beneficiary The address that receives part of the penalty amount.
     * @param amount A total amount of penalty to be withdrawn from stake.
     */
    function penalizeRelayManager(address relayManager, address beneficiary, uint256 amount) external;

    /**
     * @notice Get the stake details information for the given Relay Manager.
     * @param relayManager The address of a Relay Manager.
     * @return stakeInfo The `StakeInfo` structure.
     * @return isSenderAuthorizedHub `true` if the `msg.sender` for this call was a `RelayHub` that is authorized now.
     * `false` if the `msg.sender` for this call is not authorized.
     */
    function getStakeInfo(address relayManager) external view returns (StakeInfo memory stakeInfo, bool isSenderAuthorizedHub);

    /**
     * @return The maximum unstake delay this `StakeManger` allows. This is to prevent locking money forever by mistake.
     */
    function getMaxUnstakeDelay() external view returns (uint256);

    /**
     * @notice Change the address that will receive the 'burned' part of the penalized stake.
     * This is done to prevent malicious Relay Server from penalizing itself and breaking even.
     */
    function setBurnAddress(address _burnAddress) external;

    /**
     * @return The address that will receive the 'burned' part of the penalized stake.
     */
    function getBurnAddress() external view returns (address);

    /**
     * @return the block number in which the contract has been deployed.
     */
    function getCreationBlock() external view returns (uint256);

    /**
     * @return a SemVer-compliant version of the `StakeManager` contract.
     */
    function versionSM() external view returns (string memory);
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: GPL-3.0-only

import "../forwarder/IForwarder.sol";

interface GsnTypes {
    /// @notice maxFeePerGas, maxPriorityFeePerGas, pctRelayFee and baseRelayFee must be validated inside of the paymaster's preRelayedCall in order not to overpay
    struct RelayData {
        uint256 maxFeePerGas;
        uint256 maxPriorityFeePerGas;
        uint256 pctRelayFee;
        uint256 baseRelayFee;
        uint256 transactionCalldataGasUsed;
        address relayWorker;
        address paymaster;
        address forwarder;
        bytes paymasterData;
        uint256 clientId;
    }

    //note: must start with the ForwardRequest to be an extension of the generic forwarder
    struct RelayRequest {
        IForwarder.ForwardRequest request;
        RelayData relayData;
    }
}