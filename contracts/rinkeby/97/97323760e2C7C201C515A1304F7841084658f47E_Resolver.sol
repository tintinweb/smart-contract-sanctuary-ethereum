//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {ITaskTreasury} from "./ITaskTreasury.sol";
import {MarginLong} from "../v1/MarginLong/MarginLong.sol";
import {IConverter} from "../Converter/IConverter.sol";

contract Resolver is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public taskTreasury;
    address public depositReceiver;
    address public ethAddress;

    address public converter;
    address public marginLong;

    constructor(
        address taskTreasury_,
        address depositReceiver_,
        address ethAddress_,
        address marginLong_,
        address converter_
    ) {
        taskTreasury = taskTreasury_;
        depositReceiver = depositReceiver_;
        ethAddress = ethAddress_;
        marginLong = marginLong_;
        converter = converter_;
    }

    // Set the task treasury to use
    function setTaskTreasury(address taskTreasury_) external onlyOwner {
        taskTreasury = taskTreasury_;
    }

    // Set the deposit receiver
    function setDepositReceiver(address depositReceiver_) external onlyOwner {
        depositReceiver = depositReceiver_;
    }

    // Set the eth address
    function setEthAddress(address ethAddress_) external onlyOwner {
        ethAddress = ethAddress_;
    }

    // Set the converter to use
    function setConverter(address converter_) external onlyOwner {
        converter = converter_;
    }

    // Set the margin long to use
    function setMarginLong(address marginLong_) external onlyOwner {
        marginLong = marginLong_;
    }

    // Convert liquidated amounts to ETH
    function _redepositEth(address[] memory repayToken_, uint256[] memory repayAmount_) internal returns (uint256) {
        uint256 total = 0;

        for (uint256 i = 0; i < repayToken_.length; i++) {
            if (repayAmount_[i] > 0) {
                IERC20(repayToken_[i]).safeApprove(converter, repayAmount_[i]);
                uint256 amountOut = IConverter(converter).swapMaxEthOut(repayToken_[i], repayAmount_[i]);

                total = total.add(amountOut);
            }
        }

        ITaskTreasury(taskTreasury).depositFunds{value: total}(depositReceiver, ethAddress, total);

        return total;
    }

    // Check if an account needs to be liquidated
    function checkLiquidate() external view returns (bool, bytes memory) {
        address[] memory accounts = MarginLong(marginLong).getBorrowingAccounts();

        for (uint256 i = 0; i < accounts.length; i++)
            if (MarginLong(marginLong).liquidatable(accounts[i])) return (true, abi.encodeWithSelector(this.executeLiquidate.selector, accounts[i]));

        return (false, bytes(""));
    }

    // Check if an account needs to be reset
    function checkReset() external view returns (bool, bytes memory) {
        address[] memory accounts = MarginLong(marginLong).getBorrowingAccounts();

        for (uint256 i = 0; i < accounts.length; i++)
            if (MarginLong(marginLong).resettable(accounts[i])) return (true, abi.encodeWithSelector(this.executeReset.selector, accounts[i]));

        return (false, bytes(""));
    }

    // Execute liquidate and repay
    function executeLiquidate(address account_) external {
        (address[] memory repayTokens, uint256[] memory repayAmounts) = MarginLong(marginLong).liquidateAccount(account_);
        _redepositEth(repayTokens, repayAmounts);
    }

    // Execute reset and repay
    function executeReset(address account_) external {
        (address[] memory repayTokens, uint256[] memory repayAmounts) = MarginLong(marginLong).resetAccount(account_);
        _redepositEth(repayTokens, repayAmounts);
    }

    receive() external payable {}
}

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ITaskTreasury {
    function depositFunds(
        address _receiver,
        address _token,
        uint256 _amount
    ) external payable;

    function userTokenBalance(address _receiver, address _token) external view returns (uint256);
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {MarginLongBorrow} from "./MarginLongBorrow.sol";
import {MarginLongRepay} from "./MarginLongRepay.sol";
import {MarginLongLiquidate} from "./MarginLongLiquidate.sol";

contract MarginLong is Initializable, MarginLongBorrow, MarginLongRepay, MarginLongLiquidate {
    function initialize(
        address pool_,
        address oracle_,
        uint256 minCollateralPrice_,
        uint256 maxLeverageNumerator_,
        uint256 maxLeverageDenominator_,
        uint256 liquidationFeePercentNumerator_,
        uint256 liquidationFeePercentDenominator_
    ) external initializer {
        initializeMarginCore(pool_, oracle_);
        initializeMarginLevel(maxLeverageNumerator_, maxLeverageDenominator_);
        initializeMarginLimits(minCollateralPrice_);
        initializeMarginLongLiquidateCore(liquidationFeePercentNumerator_, liquidationFeePercentDenominator_);
    }
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IConverter {
    function swapMaxTokenOut(
        address tokenIn_,
        uint256 amountIn_,
        address tokenOut_
    ) external returns (uint256);

    function maxAmountTokenOut(
        address tokenIn_,
        uint256 amountIn_,
        address tokenOut_
    ) external view returns (uint256);

    function minAmountTokenInTokenOut(
        address tokenIn_,
        address tokenOut_,
        uint256 amountOut_
    ) external view returns (uint256);

    function swapMaxEthIn(address tokenOut_) external payable returns (uint256);

    function swapMaxEthOut(address tokenIn_, uint256 amountIn_) external returns (uint256);

    function maxAmountEthOut(address tokenIn_, uint256 amountIn_) external view returns (uint256);

    function minAmountTokenInEthOut(address tokenIn_, uint256 amountOut_) external view returns (uint256);
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
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {LPool} from "../LPool/LPool.sol";
import {IOracle} from "../../Oracle/IOracle.sol";
import {MarginLongCore} from "./MarginLongCore.sol";

abstract contract MarginLongBorrow is MarginLongCore {
    using SafeMathUpgradeable for uint256;

    // Margin borrow against collateral
    function borrow(address token_, uint256 amount_) external onlyApprovedBorrowedToken(token_) {
        require(amount_ > 0, "MarginLongBorrow: Amount borrowed must be greater than 0");

        if (!isBorrowing(token_, _msgSender())) _addAccount(_msgSender());
        _setAccumulatedInterest(token_, interest(token_, _msgSender()), _msgSender());
        _setInitialBorrowTime(token_, block.timestamp, _msgSender());

        LPool(pool).claim(token_, amount_);
        _setBorrowed(token_, borrowed(token_, _msgSender()).add(amount_), _msgSender());

        uint256 _initialBorrowPrice = IOracle(oracle).priceMin(token_, amount_);
        _setInitialBorrowPrice(token_, initialBorrowPrice(token_, _msgSender()).add(_initialBorrowPrice), _msgSender());

        require(!resettable(_msgSender()) && !liquidatable(_msgSender()), "MarginLongBorrow: Borrowing desired amount puts account at risk");

        emit Borrow(_msgSender(), token_, amount_);
    }

    event Borrow(address indexed account, address token, uint256 amount);
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {MarginLongRepayCore} from "./MarginLongRepayCore.sol";

abstract contract MarginLongRepay is MarginLongRepayCore {
    using SafeMathUpgradeable for uint256;

    // Helper to repay a single leveraged position
    function _repayAccount(address token_, address account_) internal {
        if (_repayIsPayout(token_, account_)) _repayPayout(token_, account_);
        else _repayLoss(token_, account_);
    }

    // Helper to repay entire account
    function _repayAccount(address account_) internal {
        _repayPayoutAll(account_);
        _repayLossAll(account_);
    }

    // Repay a borrowed position in an account
    function repayAccount(address token_) external onlyBorrowedToken(token_) {
        require(isBorrowing(token_, _msgSender()), "MarginLongRepay: Cannot repay account with no leveraged position");

        _repayAccount(token_, _msgSender());
        require(!resettable(_msgSender()), "MarginLongRepay: Repaying position puts account at risk");

        emit Repay(_msgSender(), token_);
    }

    // Repay all borrowed positions in an account
    function repayAccount() external {
        require(isBorrowing(_msgSender()), "MarginLongRepay: Cannot repay account with no leveraged positions");

        _repayAccount(_msgSender());

        emit RepayAll(_msgSender());
    }

    // Reset an account
    function resetAccount(address account_) external returns (address[] memory, uint256[] memory) {
        require(resettable(account_), "MarginLongRepay: This account cannot be reset");

        _repayAccount(account_);

        (address[] memory collateralTokens, uint256[] memory collateralTax) = _taxAccount(account_, _msgSender());

        emit Reset(account_, _msgSender());

        return (collateralTokens, collateralTax);
    }
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {MarginLongLiquidateCore} from "./MarginLongLiquidateCore.sol";

abstract contract MarginLongLiquidate is MarginLongLiquidateCore {
    using SafeMathUpgradeable for uint256;

    // Helper for liquidating accounts
    function _liquidateAccount(address account_) internal {
        _resetCollateral(account_);
        _resetBorrowed(account_);
    }

    // Liquidate an account
    function liquidateAccount(address account_) external returns (address[] memory, uint256[] memory) {
        require(liquidatable(account_), "MarginLongLiquidate: This account cannot be liquidated");

        (address[] memory collateralTokens, uint256[] memory collateralTax) = _taxAccount(account_, _msgSender());

        _liquidateAccount(account_);

        emit Liquidated(account_, _msgSender());

        return (collateralTokens, collateralTax);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
library SafeMathUpgradeable {
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

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {LPoolProvide} from "./LPoolProvide.sol";
import {LPoolInterest} from "./LPoolInterest.sol";

contract LPool is Initializable, LPoolProvide, LPoolInterest {
    function initialize(
        address converter_,
        address oracle_,
        uint256 taxPercentNumerator_,
        uint256 taxPercentDenominator_,
        uint256 timePerInterestApplication_
    ) external initializer {
        initializeLPoolCore(converter_, oracle_);
        initializeLPoolTax(taxPercentNumerator_, taxPercentDenominator_);
        initializeLPoolInterest(timePerInterestApplication_);
    }
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IOracle {
    function priceDecimals() external view returns (uint256);

    function priceMin(address token_, uint256 amount_) external view returns (uint256);

    function priceMax(address token_, uint256 amount_) external view returns (uint256);

    function amountMin(address token_, uint256 price_) external view returns (uint256);

    function amountMax(address token_, uint256 price_) external view returns (uint256);
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {MarginCollateral} from "../Margin/MarginCollateral.sol";
import {MarginBorrowers} from "../Margin/MarginBorrowers.sol";

abstract contract MarginLongCore is MarginCollateral, MarginBorrowers {}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20Upgradeable, SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {LPoolLiquidity} from "./LPoolLiquidity.sol";
import {LPoolToken} from "./LPoolToken.sol";

abstract contract LPoolProvide is LPoolLiquidity {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Return the amount of LP tokens received for adding a given amount of tokens as liquidity
    function addLiquidityOutLPTokens(address token_, uint256 amount_) public view onlyApprovedPT(token_) returns (uint256) {
        LPoolToken LPToken = LPoolToken(LPFromPT(token_));

        uint256 totalSupply = LPToken.totalSupply();
        uint256 totalValue = tvl(token_);

        if (totalValue == 0) return amount_;

        return amount_.mul(totalSupply).div(totalValue);
    }

    // Add tokens to the liquidity pool and receive LP tokens that represent the users share in the pool
    function addLiquidity(address token_, uint256 amount_) external onlyApprovedPT(token_) returns (uint256) {
        require(amount_ > 0, "LPoolProvide: Amount of tokens must be greater than 0");

        LPoolToken LPToken = LPoolToken(LPFromPT(token_));

        uint256 value = addLiquidityOutLPTokens(token_, amount_);
        require(value > 0, "LPoolProvide: Not enough tokens provided");

        IERC20Upgradeable(token_).safeTransferFrom(_msgSender(), address(this), amount_);
        LPToken.mint(_msgSender(), value);

        emit AddLiquidity(_msgSender(), token_, amount_, value);

        return value;
    }

    // Get the value for redeeming LP tokens for the underlying asset
    function removeLiquidityOutPoolTokens(address token_, uint256 amount_) public view onlyLP(token_) returns (uint256) {
        LPoolToken LPToken = LPoolToken(token_);
        address approvedToken = PTFromLP(token_);

        uint256 totalSupply = LPToken.totalSupply();
        uint256 totalValue = tvl(approvedToken);

        return amount_.mul(totalValue).div(totalSupply);
    }

    // Redeem LP tokens for the underlying asset
    function removeLiquidity(address token_, uint256 amount_) external onlyLP(token_) returns (uint256) {
        require(amount_ > 0, "LPoolProvide: Amount of tokens must be greater than 0");

        LPoolToken LPToken = LPoolToken(token_);
        address approvedToken = PTFromLP(token_);

        uint256 value = removeLiquidityOutPoolTokens(token_, amount_);
        require(value <= liquidity(approvedToken), "LPoolProvide: Not enough liquidity to redeem at this time");

        LPToken.burn(_msgSender(), amount_);
        IERC20Upgradeable(approvedToken).safeTransfer(_msgSender(), value);

        emit RemoveLiquidity(_msgSender(), token_, amount_, value);

        return value;
    }

    event AddLiquidity(address indexed account, address token, uint256 amount, uint256 value);
    event RemoveLiquidity(address indexed account, address token, uint256 amount, uint256 value);
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {FractionMath} from "../../lib/FractionMath.sol";
import {LPoolLiquidity} from "./LPoolLiquidity.sol";

abstract contract LPoolInterest is Initializable, LPoolLiquidity {
    using SafeMathUpgradeable for uint256;
    using FractionMath for FractionMath.Fraction;

    uint256 public timePerInterestApplication;

    mapping(address => FractionMath.Fraction) private _maxInterestMin;
    mapping(address => FractionMath.Fraction) private _maxInterestMax;
    mapping(address => FractionMath.Fraction) private _maxUtilization;

    function initializeLPoolInterest(uint256 timePerInterestApplication_) public initializer {
        timePerInterestApplication = timePerInterestApplication_;
    }

    // Set the time the interest rate is applied after
    function setTimePerInterestApplication(uint256 timePerInterestApplication_) external onlyRole(POOL_ADMIN) {
        timePerInterestApplication = timePerInterestApplication_;
    }

    // Get the max interest for minimum utilization for the given token
    function maxInterestMin(address token_) public view onlyPT(token_) returns (uint256, uint256) {
        return _maxInterestMin[token_].export();
    }

    // Set the max interest for minimum utilization for the given token
    function setMaxInterestMin(
        address[] memory token_,
        uint256[] memory percentNumerator_,
        uint256[] memory percentDenominator_
    ) external onlyRole(POOL_ADMIN) {
        for (uint256 i = 0; i < token_.length; i++) {
            if (isPT(token_[i])) {
                _maxInterestMin[token_[i]].numerator = percentNumerator_[i];
                _maxInterestMin[token_[i]].denominator = percentDenominator_[i];
            }
        }
    }

    // Get the max interest for maximum utilization for the given token
    function maxInterestMax(address token_) public view onlyPT(token_) returns (uint256, uint256) {
        return _maxInterestMax[token_].export();
    }

    // Set the max interest for maximum utilization for the given token
    function setMaxInterestMax(
        address[] memory token_,
        uint256[] memory percentNumerator_,
        uint256[] memory percentDenominator_
    ) external onlyRole(POOL_ADMIN) {
        for (uint256 i = 0; i < token_.length; i++) {
            if (isPT(token_[i])) {
                _maxInterestMax[token_[i]].numerator = percentNumerator_[i];
                _maxInterestMax[token_[i]].denominator = percentDenominator_[i];
            }
        }
    }

    // Get the max utilization threshold for the given token
    function maxUtilization(address token_) public view onlyPT(token_) returns (uint256, uint256) {
        return _maxUtilization[token_].export();
    }

    // Set the max utilization threshold for the given token
    function setMaxUtilization(
        address[] memory token_,
        uint256[] memory percentNumerator_,
        uint256[] memory percentDenominator_
    ) external onlyRole(POOL_ADMIN) {
        for (uint256 i = 0; i < token_.length; i++) {
            if (isPT(token_[i])) {
                _maxUtilization[token_[i]].numerator = percentNumerator_[i];
                _maxUtilization[token_[i]].denominator = percentDenominator_[i];
            }
        }
    }

    // Helper to calculate the minimum interest rate
    function _interestRateMin(
        FractionMath.Fraction memory utilization_,
        FractionMath.Fraction memory utilizationMax_,
        FractionMath.Fraction memory interestMin_
    ) internal pure returns (FractionMath.Fraction memory) {
        return utilization_.mul(interestMin_).div(utilizationMax_);
    }

    // Helper to calculate the maximum interest rate
    function _interestRateMax(
        FractionMath.Fraction memory utilization_,
        FractionMath.Fraction memory interestMin_,
        FractionMath.Fraction memory utilizationMax_,
        FractionMath.Fraction memory interestMax_
    ) internal pure returns (FractionMath.Fraction memory) {
        FractionMath.Fraction memory slope = interestMax_.sub(interestMin_).div(FractionMath.create(1, 1).sub(utilizationMax_));

        return slope.mul(utilization_).add(interestMax_).sub(slope);
    }

    // Get the interest rate (in terms of numerator and denominator of ratio) for a given asset per compound
    function interestRate(address token_) public view override onlyPT(token_) returns (uint256, uint256) {
        (uint256 utilizationNumerator, uint256 utilizationDenominator) = utilizationRate(token_);

        FractionMath.Fraction memory utilization = FractionMath.create(utilizationNumerator, utilizationDenominator);
        FractionMath.Fraction memory utilizationMax = _maxUtilization[token_];
        FractionMath.Fraction memory interestMin = _maxInterestMin[token_];
        FractionMath.Fraction memory interestMax = _maxInterestMax[token_];

        if (utilization.gt(utilizationMax)) return _interestRateMax(utilization, interestMin, utilizationMax, interestMax).export();
        else return _interestRateMin(utilization, utilizationMax, interestMin).export();
    }

    // Get the accumulated interest on a given asset for a given amount of time
    function interest(
        address token_,
        uint256 borrowPrice_,
        uint256 borrowTime_
    ) public view onlyPT(token_) returns (uint256) {
        uint256 timeSinceBorrow = block.timestamp.sub(borrowTime_);
        (uint256 interestRateNumerator, uint256 interestRateDenominator) = interestRate(token_);

        return borrowPrice_.mul(interestRateNumerator).mul(timeSinceBorrow).div(interestRateDenominator).div(timePerInterestApplication);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {LPoolClaim} from "./LPoolClaim.sol";
import {LPoolDeposit} from "./LPoolDeposit.sol";

abstract contract LPoolLiquidity is LPoolClaim, LPoolDeposit {
    using SafeMathUpgradeable for uint256;

    // Return the total value locked of a given asset
    function tvl(address token_) public view onlyPT(token_) returns (uint256) {
        return IERC20Upgradeable(token_).balanceOf(address(this));
    }

    // Get the available liquidity of the pool
    function liquidity(address token_) public view override(LPoolClaim, LPoolDeposit) onlyPT(token_) returns (uint256) {
        uint256 claimed = totalClaimed(token_);

        return tvl(token_).sub(claimed);
    }

    // Get the total utilized in the pool
    function utilized(address token_) public view override(LPoolDeposit) onlyPT(token_) returns (uint256) {
        uint256 _liquidity = liquidity(token_);
        uint256 _tvl = tvl(token_);

        return _tvl.sub(_liquidity);
    }

    // Get the utilization rate for a given asset
    function utilizationRate(address token_) public view onlyPT(token_) returns (uint256, uint256) {
        uint256 _utilized = utilized(token_);
        uint256 _tvl = tvl(token_);

        return (_utilized, _tvl);
    }
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract LPoolToken is ERC20, Ownable {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    function mint(address account_, uint256 amount_) external onlyOwner {
        _mint(account_, amount_);
    }

    function burn(address account_, uint256 amount_) external onlyOwner {
        _burn(account_, amount_);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {LPoolApproved} from "./LPoolApproved.sol";

abstract contract LPoolClaim is LPoolApproved {
    using SafeMathUpgradeable for uint256;

    mapping(address => mapping(address => uint256)) private _claimed;
    mapping(address => uint256) private _totalClaimed;

    // Claim an amount of a given token
    function claim(address token_, uint256 amount_) external onlyRole(POOL_APPROVED) onlyApprovedPT(token_) {
        require(amount_ > 0, "LPoolClaim: claim amount must be greater than 0");
        require(amount_ <= liquidity(token_), "LPoolClaim: Cannot claim more than total liquidity");

        _claimed[_msgSender()][token_] = _claimed[_msgSender()][token_].add(amount_);
        _totalClaimed[token_] = _totalClaimed[token_].add(amount_);

        emit Claim(_msgSender(), token_, amount_);
    }

    // Unclaim an amount of a given token
    function unclaim(address token_, uint256 amount_) external onlyRole(POOL_APPROVED) onlyPT(token_) {
        require(amount_ > 0, "LPoolClaim: Unclaim amount must be greater than 0");
        require(amount_ <= _claimed[_msgSender()][token_], "LPoolClaim: Cannot unclaim more than current claim");

        _claimed[_msgSender()][token_] = _claimed[_msgSender()][token_].sub(amount_);
        _totalClaimed[token_] = _totalClaimed[token_].sub(amount_);

        emit Unclaim(_msgSender(), token_, amount_);
    }

    // Get the amount an account has claimed
    function claimed(address token_, address account_) public view onlyPT(token_) returns (uint256) {
        return _claimed[account_][token_];
    }

    // Get the total amount claimed
    function totalClaimed(address token_) public view onlyPT(token_) returns (uint256) {
        return _totalClaimed[token_];
    }

    function liquidity(address token_) public view virtual returns (uint256);

    event Claim(address indexed account, address token, uint256 amount);
    event Unclaim(address indexed account, address token, uint256 amount);
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20Upgradeable, SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {IOracle} from "../../Oracle/IOracle.sol";
import {IConverter} from "../../Converter/IConverter.sol";
import {LPoolApproved} from "./LPoolApproved.sol";
import {LPoolTax} from "./LPoolTax.sol";

abstract contract LPoolDeposit is LPoolApproved, LPoolTax {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Get a pseudo random token from a weighted distribution of pool tokens
    function _pseudoRandomWeightedPT() internal view returns (address) {
        address[] memory poolTokens = _poolTokens();
        uint256[] memory weights = new uint256[](poolTokens.length);

        uint256 totalWeightSize;
        for (uint256 i = 0; i < poolTokens.length; i++) {
            (uint256 interestRateNumerator, uint256 interestRateDenominator) = interestRate(poolTokens[i]);
            uint256 _utilized = IOracle(oracle).priceMax(poolTokens[i], utilized(poolTokens[i]));

            uint256 weightSize = _utilized.mul(interestRateNumerator).div(interestRateDenominator);

            weights[i] = weightSize;
            totalWeightSize = totalWeightSize.add(weightSize);
        }

        uint256 randomSample = uint256(keccak256(abi.encodePacked(block.difficulty, block.number, gasleft(), _msgSender()))).mod(totalWeightSize);

        uint256 cumulative = 0;
        address selected;
        for (uint256 i = 0; i < poolTokens.length; i++) {
            cumulative = cumulative.add(weights[i]);
            if (randomSample <= cumulative) {
                selected = poolTokens[i];
                break;
            }
        }
        return selected;
    }

    // Deposit a given amount of collateral into the pool and transfer a portion as a tax to the tax account
    function deposit(address token_, uint256 amount_) external onlyRole(POOL_APPROVED) {
        require(amount_ > 0, "LPoolDeposit: Deposit amount must be greater than 0");

        IERC20Upgradeable(token_).safeTransferFrom(_msgSender(), address(this), amount_);

        address convertedToken = _pseudoRandomWeightedPT();
        uint256 convertedAmount = amount_;
        if (convertedToken != token_) {
            IERC20Upgradeable(token_).safeApprove(converter, amount_);
            convertedAmount = IConverter(converter).swapMaxTokenOut(token_, amount_, convertedToken);
        }

        uint256 totalTax = _payTax(convertedToken, convertedAmount);

        emit Deposit(_msgSender(), token_, amount_, convertedToken, convertedAmount.sub(totalTax));
    }

    // Withdraw a given amount of collateral from the pool
    function withdraw(address token_, uint256 amount_) external onlyRole(POOL_APPROVED) onlyApprovedPT(token_) {
        require(amount_ > 0, "LPoolDeposit: Withdraw amount must be greater than 0");
        require(amount_ <= liquidity(token_), "LPoolDeposit: Withdraw amount exceeds available liquidity");

        IERC20Upgradeable(token_).safeTransfer(_msgSender(), amount_);

        emit Withdraw(_msgSender(), token_, amount_);
    }

    function liquidity(address token_) public view virtual returns (uint256);

    function utilized(address token_) public view virtual returns (uint256);

    function interestRate(address token_) public view virtual returns (uint256, uint256);

    event Deposit(address indexed account, address tokenIn, uint256 amountIn, address convertedToken, uint256 convertedAmount);
    event Withdraw(address indexed account, address token, uint256 amount);
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {LPoolCore} from "./LPoolCore.sol";
import {LPoolToken} from "./LPoolToken.sol";
import {Set} from "../../lib/Set.sol";

abstract contract LPoolApproved is LPoolCore {
    using Set for Set.AddressSet;

    mapping(address => address) private _PTToLP;
    mapping(address => address) private _LPToPT;

    Set.AddressSet private _PTList;

    mapping(address => bool) private _approved;

    modifier onlyPT(address token_) {
        require(isPT(token_), "LPoolApproved: Only pool tokens may be used");
        _;
    }

    modifier onlyApprovedPT(address token_) {
        require(isApprovedPT(token_), "LPoolApproved: Only approved pool tokens may be used");
        _;
    }

    modifier onlyLP(address token_) {
        require(isLP(token_), "LPoolApproved: Only liquidity pool tokens may be used");
        _;
    }

    modifier onlyApprovedLP(address token_) {
        require(isApprovedLP(token_), "LPoolApproved: Only approved liquidity pool tokens may be used");
        _;
    }

    // Check if a token is usable with the pool
    function isPT(address token_) public view returns (bool) {
        return _PTToLP[token_] != address(0);
    }

    // Check if a pool token is approved
    function isApprovedPT(address token_) public view returns (bool) {
        return isPT(token_) && _approved[token_];
    }

    // Check if a given token is an LP token
    function isLP(address token_) public view returns (bool) {
        return _LPToPT[token_] != address(0);
    }

    // Check if a LP token is approved
    function isApprovedLP(address token_) public view returns (bool) {
        return isLP(token_) && _approved[PTFromLP(token_)];
    }

    // Add a new token to be used with the pool
    function addLPToken(
        address[] memory token_,
        string[] memory name_,
        string[] memory symbol_
    ) external onlyRole(POOL_ADMIN) {
        for (uint256 i = 0; i < token_.length; i++) {
            if (!isPT(token_[i]) && !isLP(token_[i])) {
                address LPToken = address(new LPoolToken(name_[i], symbol_[i]));

                _PTToLP[token_[i]] = LPToken;
                _LPToPT[LPToken] = token_[i];

                emit AddLPToken(token_[i], LPToken);
            }
        }
    }

    // Get a list of pool tokens
    function _poolTokens() internal view returns (address[] memory) {
        return _PTList.iterable();
    }

    // Approve pool tokens for use with the pool if it is different to its current approved state - a LP token is approved if and only if its pool token is approved
    function setApproved(address[] memory token_, bool[] memory approved_) external onlyRole(POOL_ADMIN) {
        for (uint256 i = 0; i < token_.length; i++) {
            if (isPT(token_[i])) {
                _approved[token_[i]] = approved_[i];
                if (_approved[token_[i]] && !_PTList.exists(token_[i])) _PTList.insert(token_[i]);
                else if (!_approved[token_[i]] && _PTList.exists(token_[i])) _PTList.remove(token_[i]);
            }
        }
    }

    // Get the LP token that corresponds to the given token
    function LPFromPT(address token_) public view onlyPT(token_) returns (address) {
        return _PTToLP[token_];
    }

    // Get the token that corresponds to the given LP token
    function PTFromLP(address token_) public view onlyLP(token_) returns (address) {
        return _LPToPT[token_];
    }

    event AddLPToken(address token, address LPToken);
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

abstract contract LPoolCore is Initializable, AccessControlUpgradeable {
    bytes32 public constant POOL_ADMIN = keccak256("POOL_ADMIN_ROLE");
    bytes32 public constant POOL_APPROVED = keccak256("POOL_APPROVED_ROLE");

    address public converter;
    address public oracle;

    function initializeLPoolCore(address converter_, address oracle_) public initializer {
        __AccessControl_init();

        _setRoleAdmin(POOL_ADMIN, POOL_ADMIN);
        _setRoleAdmin(POOL_APPROVED, POOL_ADMIN);
        _grantRole(POOL_ADMIN, _msgSender());

        converter = converter_;
        oracle = oracle_;
    }

    // Set the converter to use
    function setConverter(address converter_) external onlyRole(POOL_ADMIN) {
        converter = converter_;
    }

    // Set the oracle to use
    function setOracle(address oracle_) external onlyRole(POOL_ADMIN) {
        oracle = oracle_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
Hitchens UnorderedAddressSet v0.93
Library for managing CRUD operations in dynamic address sets.
https://github.com/rob-Hitchens/UnorderedKeySet
Copyright (c), 2019, Rob Hitchens, the MIT License
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
THIS SOFTWARE IS NOT TESTED OR AUDITED. DO NOT USE FOR PRODUCTION.
*/

library Set {
    struct AddressSet {
        mapping(address => uint256) keyPointers;
        address[] keyList;
    }

    function insert(AddressSet storage self, address key) internal {
        require(!exists(self, key), "AddressSet: Address already exists in the set.");
        self.keyList.push(key);
        self.keyPointers[key] = self.keyList.length - 1;
    }

    function remove(AddressSet storage self, address key) internal {
        require(exists(self, key), "AddressSet: Address does not exist in the set.");
        address keyToMove = self.keyList[count(self) - 1];
        uint256 rowToReplace = self.keyPointers[key];

        self.keyPointers[keyToMove] = rowToReplace;
        self.keyList[rowToReplace] = keyToMove;

        delete self.keyPointers[key];
        self.keyList.pop();
    }

    function count(AddressSet storage self) internal view returns (uint256) {
        return (self.keyList.length);
    }

    function exists(AddressSet storage self, address key) internal view returns (bool) {
        if (self.keyList.length == 0) return false;
        return self.keyList[self.keyPointers[key]] == key;
    }

    function keyAtIndex(AddressSet storage self, uint256 index) internal view returns (address) {
        return self.keyList[index];
    }

    function iterable(AddressSet storage self) internal view returns (address[] memory) {
        return self.keyList;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC20Upgradeable, SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {FractionMath} from "../../lib/FractionMath.sol";
import {Set} from "../../lib/Set.sol";
import {LPoolCore} from "./LPoolCore.sol";

abstract contract LPoolTax is Initializable, LPoolCore {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using Set for Set.AddressSet;
    using FractionMath for FractionMath.Fraction;

    FractionMath.Fraction private _taxPercent;
    Set.AddressSet private _taxAccountSet;

    function initializeLPoolTax(uint256 taxPercentNumerator_, uint256 taxPercentDenominator_) public initializer {
        _taxPercent.numerator = taxPercentNumerator_;
        _taxPercent.denominator = taxPercentDenominator_;
    }

    // Set the tax percentage
    function setTaxPercentage(uint256 taxPercentNumerator_, uint256 taxPercentDenominator_) external onlyRole(POOL_ADMIN) {
        _taxPercent.numerator = taxPercentNumerator_;
        _taxPercent.denominator = taxPercentDenominator_;
    }

    // Get the tax percentage
    function taxPercentage() public view returns (uint256, uint256) {
        return _taxPercent.export();
    }

    // Add a text account
    function addTaxAccount(address account_) external onlyRole(POOL_ADMIN) {
        _taxAccountSet.insert(account_);
    }

    // Remove a tax account
    function removeTaxAccount(address account_) external onlyRole(POOL_ADMIN) {
        _taxAccountSet.remove(account_);
    }

    // Apply and distribute tax
    function _payTax(address token_, uint256 amountIn_) internal returns (uint256) {
        address[] memory taxAccounts = _taxAccountSet.iterable();

        uint256 tax = _taxPercent.numerator.mul(amountIn_).div(_taxPercent.denominator).div(taxAccounts.length);
        uint256 totalTax = tax.mul(taxAccounts.length);

        for (uint256 i = 0; i < taxAccounts.length; i++) IERC20Upgradeable(token_).safeTransfer(taxAccounts[i], tax);

        return totalTax;
    }
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

library FractionMath {
    using FractionMath for Fraction;
    using SafeMathUpgradeable for uint256;

    struct Fraction {
        uint256 numerator;
        uint256 denominator;
    }

    modifier onlyValid(Fraction memory fraction) {
        require(fraction.denominator != 0, "FractionMath: Denominator of fraction cannot equal 0");
        _;
    }

    function create(uint256 a, uint256 b) internal pure returns (Fraction memory fraction) {
        require(b != 0, "FractionMath: Denominator cannot equal o");
        return Fraction({numerator: a, denominator: b});
    }

    function export(Fraction memory a) internal pure onlyValid(a) returns (uint256, uint256) {
        return (a.numerator, a.denominator);
    }

    function add(Fraction memory a, Fraction memory b) internal pure onlyValid(a) onlyValid(b) returns (Fraction memory fraction) {
        fraction.numerator = a.numerator.mul(b.denominator).add(b.numerator.mul(a.denominator));
        fraction.denominator = a.denominator.mul(b.denominator);
    }

    function sub(Fraction memory a, Fraction memory b) internal pure onlyValid(a) onlyValid(b) returns (Fraction memory fraction) {
        fraction.numerator = a.numerator.mul(b.denominator).sub(b.numerator.mul(a.denominator));
        fraction.denominator = a.denominator.mul(b.denominator);
    }

    function mul(Fraction memory a, Fraction memory b) internal pure onlyValid(a) onlyValid(b) returns (Fraction memory fraction) {
        fraction.numerator = a.numerator.mul(b.numerator);
        fraction.denominator = a.denominator.mul(b.denominator);
    }

    function div(Fraction memory a, Fraction memory b) internal pure onlyValid(a) onlyValid(b) returns (Fraction memory fraction) {
        require(b.numerator != 0, "FractionMath: Divisior fraction cannot equal 0");
        fraction.numerator = a.numerator.mul(b.denominator);
        fraction.denominator = a.denominator.mul(b.numerator);
    }

    function eq(Fraction memory a, Fraction memory b) internal pure onlyValid(a) onlyValid(b) returns (bool) {
        return a.numerator.mul(b.denominator) == b.numerator.mul(a.denominator);
    }

    function gt(Fraction memory a, Fraction memory b) internal pure onlyValid(a) onlyValid(b) returns (bool) {
        return a.numerator.mul(b.denominator) > b.numerator.mul(a.denominator);
    }

    function gte(Fraction memory a, Fraction memory b) internal pure onlyValid(a) onlyValid(b) returns (bool) {
        return a.numerator.mul(b.denominator) >= b.numerator.mul(a.denominator);
    }

    function lt(Fraction memory a, Fraction memory b) internal pure onlyValid(a) onlyValid(b) returns (bool) {
        return a.numerator.mul(b.denominator) < b.numerator.mul(a.denominator);
    }

    function lte(Fraction memory a, Fraction memory b) internal pure onlyValid(a) onlyValid(b) returns (bool) {
        return a.numerator.mul(b.denominator) <= b.numerator.mul(a.denominator);
    }
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20Upgradeable, SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {MarginLevel} from "./MarginLevel.sol";
import {MarginApproved} from "./MarginApproved.sol";
import {MarginLimits} from "./MarginLimits.sol";

abstract contract MarginCollateral is MarginApproved, MarginLevel, MarginLimits {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Deposit collateral into the account
    function addCollateral(address token_, uint256 amount_) external onlyApprovedCollateralToken(token_) {
        require(amount_ > 0, "MarginCollateral: Amount added as collateral must be greater than 0");

        IERC20Upgradeable(token_).safeTransferFrom(_msgSender(), address(this), amount_);
        _setCollateral(token_, collateral(token_, _msgSender()).add(amount_), _msgSender());

        emit AddCollateral(_msgSender(), token_, amount_);
    }

    // Withdraw collateral from the account
    function removeCollateral(address token_, uint256 amount_) external onlyCollateralToken(token_) {
        require(amount_ > 0, "MarginCollateral: Collateral amount removed must be greater than 0");
        require(amount_ <= collateral(token_, _msgSender()), "MarginCollateral: Cannot remove more than available collateral");

        _setCollateral(token_, collateral(token_, _msgSender()).sub(amount_), _msgSender());
        require(!resettable(_msgSender()) && !liquidatable(_msgSender()), "MarginCollateral: Withdrawing desired collateral puts account at risk");

        IERC20Upgradeable(token_).safeTransfer(_msgSender(), amount_);

        emit RemoveCollateral(_msgSender(), token_, amount_);
    }

    event AddCollateral(address indexed account, address token, uint256 amount);
    event RemoveCollateral(address indexed account, address token, uint256 amount);
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Set} from "../../lib/Set.sol";

abstract contract MarginBorrowers {
    using Set for Set.AddressSet;

    Set.AddressSet private _accountSet;

    // Add an account to the borrowed list
    function _addAccount(address account_) internal {
        _accountSet.insert(account_);
    }

    // Remove an account from the borrowed list
    function _removeAccount(address account_) internal {
        _accountSet.remove(account_);
    }

    // Get a full list of all borrowing accounts
    function getBorrowingAccounts() public view returns (address[] memory) {
        return _accountSet.iterable();
    }
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {FractionMath} from "../../lib/FractionMath.sol";
import {MarginAccount} from "./MarginAccount.sol";

abstract contract MarginLevel is Initializable, MarginAccount {
    using FractionMath for FractionMath.Fraction;

    FractionMath.Fraction private _maxLeverage;

    function initializeMarginLevel(uint256 maxLeverageNumerator_, uint256 maxLeverageDenominator_) public initializer {
        _maxLeverage.numerator = maxLeverageNumerator_;
        _maxLeverage.denominator = maxLeverageDenominator_;
    }

    // Set the maximum leverage
    function setMaxLeverage(uint256 maxLeverageNumerator_, uint256 maxLeverageDenominator_) external onlyOwner {
        _maxLeverage.numerator = maxLeverageNumerator_;
        _maxLeverage.denominator = maxLeverageDenominator_;
    }

    // Get the max leverage
    function maxLeverage() public view returns (uint256, uint256) {
        return _maxLeverage.export();
    }

    // Get the amount of leverage for a given account
    function currentLeverage(address account_) public view returns (uint256, uint256) {
        uint256 _initialBorrowPrice = initialBorrowPrice(account_);
        uint256 _accountPrice = accountPrice(account_);

        return (_initialBorrowPrice, _accountPrice);
    }

    // Get the minimum margin level before liquidation
    function minMarginLevel() public view returns (uint256, uint256) {
        return FractionMath.create(1, 1).add(FractionMath.create(1, 1).div(_maxLeverage)).export();
    }

    // Get the margin level of an account
    function marginLevel(address account_) public view returns (uint256, uint256) {
        (uint256 currentLeverageNumerator, uint256 currentLeverageDenominator) = currentLeverage(account_);

        return FractionMath.create(1, 1).add(FractionMath.create(currentLeverageDenominator, currentLeverageNumerator)).export();
    }

    // Check whether an account is liquidatable
    function liquidatable(address account_) public view returns (bool) {
        if (!isBorrowing(account_)) return false;

        (uint256 marginLevelNumerator, uint256 marginLevelDenominator) = marginLevel(account_);
        FractionMath.Fraction memory _marginLevel = FractionMath.create(marginLevelNumerator, marginLevelDenominator);

        (uint256 minMarginLevelNumerator, uint256 minMarginLevelDenominator) = minMarginLevel();
        FractionMath.Fraction memory _minMarginLevel = FractionMath.create(minMarginLevelNumerator, minMarginLevelDenominator);

        return _marginLevel.lt(_minMarginLevel);
    }
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {MarginCore} from "./MarginCore.sol";

abstract contract MarginApproved is MarginCore {
    mapping(address => bool) private _collateralTokens;
    mapping(address => bool) private _borrowedTokens;

    mapping(address => bool) private _approvedCollateralTokens;
    mapping(address => bool) private _approvedBorrowedTokens;

    modifier onlyApprovedCollateralToken(address token_) {
        require(isApprovedCollateralToken(token_), "MarginApproved: Only approved collateral tokens may be used");
        _;
    }

    modifier onlyApprovedBorrowedToken(address token_) {
        require(isApprovedBorrowedToken(token_), "MarginApproved: Only approved borrowed tokens may be used");
        _;
    }

    modifier onlyCollateralToken(address token_) {
        require(isCollateralToken(token_), "MarginApproved: Only collateral tokens may be used");
        _;
    }

    modifier onlyBorrowedToken(address token_) {
        require(isBorrowedToken(token_), "MarginApproved: Only borrowed tokens may be used");
        _;
    }

    // Add a collateral token
    function addCollateralToken(address[] memory token_) external onlyOwner {
        for (uint256 i = 0; i < token_.length; i++) {
            if (!_collateralTokens[token_[i]]) {
                _collateralTokens[token_[i]] = true;
                emit AddCollateralToken(token_[i]);
            }
        }
    }

    // Add a borrowed token
    function addBorrowedToken(address[] memory token_) external onlyOwner {
        for (uint256 i = 0; i < token_.length; i++) {
            if (!_borrowedTokens[token_[i]]) {
                _borrowedTokens[token_[i]] = true;
                emit AddBorrowedToken(token_[i]);
            }
        }
    }

    // Approve a token for collateral
    function setApprovedCollateralToken(address[] memory token_, bool[] memory approved_) external onlyOwner {
        for (uint256 i = 0; i < token_.length; i++) {
            if (isCollateralToken(token_[i])) _approvedCollateralTokens[token_[i]] = approved_[i];
        }
    }

    // Approve a token to be used for borrowing
    function setApprovedBorrowedToken(address[] memory token_, bool[] memory approved_) external onlyOwner {
        for (uint256 i = 0; i < token_.length; i++) {
            if (isBorrowedToken(token_[i])) _approvedBorrowedTokens[token_[i]] = approved_[i];
        }
    }

    // Check if a token is a collateral token
    function isCollateralToken(address token_) public view returns (bool) {
        return _collateralTokens[token_];
    }

    // Check if a token is a borrowed token
    function isBorrowedToken(address token_) public view returns (bool) {
        return _borrowedTokens[token_];
    }

    // Check if a token is an approved collateral token
    function isApprovedCollateralToken(address token_) public view returns (bool) {
        return isCollateralToken(token_) && _approvedCollateralTokens[token_];
    }

    // Check if a token is an approved borrowed token
    function isApprovedBorrowedToken(address token_) public view returns (bool) {
        return isBorrowedToken(token_) && _approvedBorrowedTokens[token_];
    }

    event AddCollateralToken(address token);
    event AddBorrowedToken(address token);
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {MarginAccount} from "./MarginAccount.sol";

abstract contract MarginLimits is Initializable, MarginAccount {
    uint256 public minCollateralPrice;

    function initializeMarginLimits(uint256 minCollateralPrice_) public initializer {
        minCollateralPrice = minCollateralPrice_;
    }

    // Set the minimum collateral price
    function setMinCollateralPrice(uint256 minCollateralPrice_) external onlyOwner {
        minCollateralPrice = minCollateralPrice_;
    }

    // Check if an account has sufficient collateral to back a loan
    function sufficientCollateralPrice(address account_) public view returns (bool) {
        return collateralPrice(account_) >= minCollateralPrice;
    }

    // Check if an account is resettable
    function resettable(address account_) public view returns (bool) {
        return (isBorrowing(account_) && !sufficientCollateralPrice(account_));
    }
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {LPool} from "../LPool/LPool.sol";
import {IOracle} from "../../Oracle/IOracle.sol";
import {Set} from "../../lib/Set.sol";
import {MarginPool} from "./MarginPool.sol";

abstract contract MarginAccount is MarginPool {
    using SafeMathUpgradeable for uint256;
    using Set for Set.AddressSet;

    struct Account {
        Set.AddressSet collateral;
        mapping(address => uint256) collateralAmounts;
        Set.AddressSet borrowed;
        mapping(address => uint256) borrowedAmounts;
        mapping(address => uint256) initialBorrowPrice;
        mapping(address => uint256) initialBorrowTime;
        mapping(address => uint256) accumulatedInterest;
        uint256 hasBorrowed;
    }

    mapping(address => Account) private _accounts;

    // Set the collateral for a given asset
    function _setCollateral(
        address token_,
        uint256 amount_,
        address account_
    ) internal {
        Account storage account = _accounts[account_];

        if (!account.collateral.exists(token_) && amount_ != 0) account.collateral.insert(token_);
        else if (account.collateral.exists(token_) && amount_ == 0) account.collateral.remove(token_);

        _setTotalCollateral(token_, totalCollateral(token_).sub(account.collateralAmounts[token_]).add(amount_));
        account.collateralAmounts[token_] = amount_;
    }

    // Get the collateral for a given asset for a given account
    function collateral(address token_, address account_) public view onlyCollateralToken(token_) returns (uint256) {
        Account storage account = _accounts[account_];
        return account.collateralAmounts[token_];
    }

    // Get the total collateral price for a given account and asset borrowed
    function collateralPrice(address account_) public view returns (uint256) {
        Account storage account = _accounts[account_];
        uint256 totalPrice = 0;

        for (uint256 i = 0; i < account.collateral.count(); i++) {
            address token = account.collateral.keyAtIndex(i);
            uint256 price = IOracle(oracle).priceMin(token, collateral(token, account_));

            totalPrice = totalPrice.add(price);
        }

        return totalPrice;
    }

    // Get the collateral tokens list
    function _collateralTokens(address account_) internal view returns (address[] memory) {
        return _accounts[account_].collateral.iterable();
    }

    // Get the amount of each collateral token
    function _collateralAmounts(address account_) internal view returns (uint256[] memory) {
        address[] memory tokens = _collateralTokens(account_);
        uint256[] memory amounts = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) amounts[i] = collateral(tokens[i], account_);
        return amounts;
    }

    // Set the amount the user has borrowed
    function _setBorrowed(
        address token_,
        uint256 amount_,
        address account_
    ) internal {
        Account storage account = _accounts[account_];

        if (!account.borrowed.exists(token_) && amount_ != 0) account.borrowed.insert(token_);
        else if (account.borrowed.exists(token_) && amount_ == 0) account.borrowed.remove(token_);

        _setTotalBorrowed(token_, totalBorrowed(token_).sub(account.borrowedAmounts[token_]).add(amount_));
        account.hasBorrowed = account.hasBorrowed.sub(account.borrowedAmounts[token_]).add(amount_);
        account.borrowedAmounts[token_] = amount_;
    }

    // Get the borrowed for a given account
    function borrowed(address token_, address account_) public view onlyBorrowedToken(token_) returns (uint256) {
        Account storage account = _accounts[account_];
        return account.borrowedAmounts[token_];
    }

    // Get the total price of the assets borrowed
    function borrowedPrice(address account_) public view returns (uint256) {
        Account storage account = _accounts[account_];
        uint256 totalPrice = 0;

        for (uint256 i = 0; i < account.borrowed.count(); i++) {
            address token = account.borrowed.keyAtIndex(i);
            uint256 price = IOracle(oracle).priceMin(token, borrowed(token, account_));

            totalPrice = totalPrice.add(price);
        }

        return totalPrice;
    }

    // Get the borrowed tokens list
    function _borrowedTokens(address account_) internal view returns (address[] memory) {
        return _accounts[account_].borrowed.iterable();
    }

    // Check if an account is currently borrowing
    function isBorrowing(address account_) public view returns (bool) {
        Account storage account = _accounts[account_];
        return account.hasBorrowed > 0;
    }

    // Check if an account is currently borrowing a particular asset
    function isBorrowing(address token_, address account_) public view onlyBorrowedToken(token_) returns (bool) {
        return borrowed(token_, account_) > 0;
    }

    // Set the initial borrow price for an account
    function _setInitialBorrowPrice(
        address token_,
        uint256 price_,
        address account_
    ) internal {
        Account storage account = _accounts[account_];
        account.initialBorrowPrice[token_] = price_;
    }

    // Get the initial borrow price for an account
    function initialBorrowPrice(address token_, address account_) public view onlyBorrowedToken(token_) returns (uint256) {
        Account storage account = _accounts[account_];
        return account.initialBorrowPrice[token_];
    }

    // Get the total initial borrow price for an account
    function initialBorrowPrice(address account_) public view returns (uint256) {
        address[] memory borrowedTokens = _borrowedTokens(account_);
        uint256 total = 0;
        for (uint256 i = 0; i < borrowedTokens.length; i++) total = total.add(initialBorrowPrice(borrowedTokens[i], account_));
        return total;
    }

    // Set the initial borrow time for an asset for an account
    function _setInitialBorrowTime(
        address token_,
        uint256 time_,
        address account_
    ) internal {
        Account storage account = _accounts[account_];
        account.initialBorrowTime[token_] = time_;
    }

    // Get the initial borrow time for an asset for an account
    function initialBorrowTime(address token_, address account_) public view onlyBorrowedToken(token_) returns (uint256) {
        Account storage account = _accounts[account_];
        return account.initialBorrowTime[token_];
    }

    // Set the accumulated interest
    function _setAccumulatedInterest(
        address token_,
        uint256 amount_,
        address account_
    ) internal {
        Account storage account = _accounts[account_];
        account.accumulatedInterest[token_] = amount_;
    }

    // Get the accumulated interest
    function _accumulatedInterest(address token_, address account_) internal view returns (uint256) {
        Account storage account = _accounts[account_];
        return account.accumulatedInterest[token_];
    }

    // Get the interest accumulated for a given asset
    function interest(address token_, address account_) public view onlyBorrowedToken(token_) returns (uint256) {
        return _accumulatedInterest(token_, account_).add(LPool(pool).interest(token_, initialBorrowPrice(token_, account_), initialBorrowTime(token_, account_)));
    }

    // Get the interest accumulated for the total account
    function interest(address account_) public view returns (uint256) {
        address[] memory borrowedTokens = _borrowedTokens(account_);
        uint256 total = 0;
        for (uint256 i = 0; i < borrowedTokens.length; i++) total = total.add(interest(borrowedTokens[i], account_));
        return total;
    }

    // Get the total price of the account regading the value it holds
    function accountPrice(address account_) public view returns (uint256) {
        uint256 _collateralPrice = collateralPrice(account_);
        uint256 _initialBorrowPrice = initialBorrowPrice(account_);
        uint256 _borrowedPrice = borrowedPrice(account_);
        uint256 _interest = interest(account_);

        return _collateralPrice.add(_borrowedPrice).sub(_initialBorrowPrice).sub(_interest);
    }
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {MarginApproved} from "./MarginApproved.sol";

abstract contract MarginPool is MarginApproved {
    mapping(address => uint256) private _totalBorrowed;
    mapping(address => uint256) private _totalCollateral;

    // Get the total borrowed of a given asset
    function totalBorrowed(address token_) public view onlyBorrowedToken(token_) returns (uint256) {
        return _totalBorrowed[token_];
    }

    // Get the total collateral of a given asset
    function totalCollateral(address token_) public view onlyCollateralToken(token_) returns (uint256) {
        return _totalCollateral[token_];
    }

    // Set the total borrowed of a given asset
    function _setTotalBorrowed(address token_, uint256 amount_) internal {
        _totalBorrowed[token_] = amount_;
    }

    // Set the total collateral of a given asset
    function _setTotalCollateral(address token_, uint256 amount_) internal {
        _totalCollateral[token_] = amount_;
    }
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract MarginCore is Initializable, OwnableUpgradeable {
    address public pool;
    address public oracle;

    function initializeMarginCore(address pool_, address oracle_) public initializer {
        __Ownable_init();

        pool = pool_;
        oracle = oracle_;
    }

    // Set the pool to use
    function setPool(address pool_) external onlyOwner {
        pool = pool_;
    }

    // Set the oracle to use
    function setOracle(address oracle_) external onlyOwner {
        oracle = oracle_;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20Upgradeable, SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {IOracle} from "../../Oracle/IOracle.sol";
import {MarginLongCore} from "./MarginLongCore.sol";
import {LPool} from "../LPool/LPool.sol";

abstract contract MarginLongRepayCore is MarginLongCore {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Check whether or not a given borrowed asset is at a loss or profit
    function _repayIsPayout(address token_, address account_) internal view returns (bool) {
        uint256 currentPrice = IOracle(oracle).priceMin(token_, borrowed(token_, account_));
        uint256 _initialBorrowPrice = initialBorrowPrice(token_, account_);
        uint256 _interest = interest(token_, account_);

        return (currentPrice > _initialBorrowPrice.add(_interest));
    }

    // Get the repay amount when there is a payout
    function _repayPayoutAmount(address token_, address account_) internal view returns (uint256) {
        uint256 currentPrice = IOracle(oracle).priceMin(token_, borrowed(token_, account_));
        uint256 _initialBorrowPrice = initialBorrowPrice(token_, account_);
        uint256 _interest = interest(token_, account_);

        return IOracle(oracle).amountMin(token_, currentPrice.sub(_initialBorrowPrice).sub(_interest));
    }

    // Get the repay price when there is a loss
    function _repayLossesPrice(address token_, address account_) internal view returns (uint256) {
        uint256 currentPrice = IOracle(oracle).priceMin(token_, borrowed(token_, account_));
        uint256 _initialBorrowPrice = initialBorrowPrice(token_, account_);
        uint256 _interest = interest(token_, account_);

        return _initialBorrowPrice.add(_interest).sub(currentPrice);
    }

    // Repay a payout amount
    function _repayPayout(address token_, address account_) internal {
        uint256 payoutAmount = _repayPayoutAmount(token_, account_);

        _resetBorrowed(token_, account_);

        LPool(pool).withdraw(token_, payoutAmount);

        _setCollateral(token_, collateral(token_, account_).add(payoutAmount), account_);
    }

    // Repay the payout amounts
    function _repayPayoutAll(address account_) internal {
        address[] memory borrowedTokens = _borrowedTokens(account_);

        for (uint256 i = 0; i < borrowedTokens.length; i++) if (_repayIsPayout(borrowedTokens[i], account_)) _repayPayout(borrowedTokens[i], account_);
    }

    // Repay debt using an accounts collateral
    function _repayLossFromCollateral(
        uint256 debt_,
        address account_,
        address[] memory collateralToken_,
        uint256[] memory collateralRepayAmount_,
        uint256 collateralIndex_
    ) internal returns (uint256) {
        while (debt_ > 0 && collateralIndex_ < collateralToken_.length) {
            uint256 collateralAmount = collateral(collateralToken_[collateralIndex_], account_);
            uint256 collateralPrice = IOracle(oracle).priceMin(collateralToken_[collateralIndex_], collateral(collateralToken_[collateralIndex_], account_));

            if (collateralPrice < debt_) {
                collateralRepayAmount_[collateralIndex_] = collateralAmount;
                _setCollateral(collateralToken_[collateralIndex_], 0, account_);

                debt_ = debt_.sub(collateralPrice);
                collateralIndex_ = collateralIndex_.add(1);
            } else {
                uint256 newAmount = IOracle(oracle).amountMax(collateralToken_[collateralIndex_], debt_);
                if (newAmount > collateralAmount) newAmount = collateralAmount;

                collateralRepayAmount_[collateralIndex_] = newAmount;
                _setCollateral(collateralToken_[collateralIndex_], collateralAmount.sub(newAmount), account_);

                break;
            }
        }

        return collateralIndex_;
    }

    // Repay a loss for a given token
    function _repayLoss(address token_, address account_) internal {
        address[] memory collateralTokens = _collateralTokens(account_);
        uint256[] memory collateralRepayAmounts = new uint256[](collateralTokens.length);

        uint256 debt = _repayLossesPrice(token_, account_);
        _repayLossFromCollateral(debt, account_, collateralTokens, collateralRepayAmounts, 0);

        _deposit(collateralTokens, collateralRepayAmounts);

        _resetBorrowed(token_, account_);
    }

    // Pay of all of the losses using collateral
    function _repayLossAll(address account_) internal {
        address[] memory borrowedTokens = _borrowedTokens(account_);

        address[] memory collateralTokens = _collateralTokens(account_);
        uint256[] memory collateralRepayAmounts = new uint256[](collateralTokens.length);
        uint256 collateralIndex = 0;

        for (uint256 i = 0; i < borrowedTokens.length; i++) {
            uint256 debt = _repayLossesPrice(borrowedTokens[i], account_);
            collateralIndex = _repayLossFromCollateral(debt, account_, collateralTokens, collateralRepayAmounts, collateralIndex);
        }

        _deposit(collateralTokens, collateralRepayAmounts);

        _resetBorrowed(account_);
    }

    // Tax an accounts collateral and return the tax of each token
    function _taxAccount(address account_, address receiver_) internal returns (address[] memory, uint256[] memory) {
        address[] memory collateralTokens = _collateralTokens(account_);
        uint256[] memory collateralRepayAmounts = new uint256[](collateralTokens.length);

        for (uint256 i = 0; i < collateralTokens.length; i++) {
            uint256 collateralAmount = collateral(collateralTokens[i], account_);
            (uint256 liquidationFeePercentNumerator, uint256 liquidationFeePercentDenominator) = liquidationFeePercent();
            uint256 tax = collateralAmount.mul(liquidationFeePercentNumerator).div(liquidationFeePercentDenominator);

            _setCollateral(collateralTokens[i], collateralAmount.sub(tax), account_);
            collateralRepayAmounts[i] = tax;

            IERC20Upgradeable(collateralTokens[i]).safeTransfer(receiver_, tax);
        }

        return (collateralTokens, collateralRepayAmounts);
    }

    // Deposit collateral into the pool
    function _deposit(address[] memory token_, uint256[] memory amount_) internal {
        for (uint256 i = 0; i < token_.length; i++) {
            if (amount_[i] > 0) {
                IERC20Upgradeable(token_[i]).safeApprove(address(pool), amount_[i]);
                LPool(pool).deposit(token_[i], amount_[i]);
            }
        }
    }

    // Remove borrowed position for an account
    function _resetBorrowed(address token_, address account_) internal {
        LPool(pool).unclaim(token_, borrowed(token_, account_));
        _setInitialBorrowPrice(token_, 0, account_);
        _setBorrowed(token_, 0, account_);
        _setAccumulatedInterest(token_, 0, account_);

        if (!isBorrowing(account_)) _removeAccount(account_);
    }

    // Reset the users borrowed amounts
    function _resetBorrowed(address account_) internal {
        address[] memory borrowedTokens = _borrowedTokens(account_);

        for (uint256 i = 0; i < borrowedTokens.length; i++) _resetBorrowed(borrowedTokens[i], account_);
    }

    function liquidationFeePercent() public view virtual returns (uint256, uint256);

    event Repay(address indexed account, address token);
    event RepayAll(address indexed account);
    event Reset(address indexed account, address resetter);
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC20Upgradeable, SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {FractionMath} from "../../lib/FractionMath.sol";
import {MarginLongRepayCore} from "./MarginLongRepayCore.sol";

abstract contract MarginLongLiquidateCore is Initializable, MarginLongRepayCore {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using FractionMath for FractionMath.Fraction;

    FractionMath.Fraction private _liquidationFeePercent;

    function initializeMarginLongLiquidateCore(uint256 liquidationFeePercentNumerator_, uint256 liquidationFeePercentDenominator_) public initializer {
        _liquidationFeePercent.numerator = liquidationFeePercentNumerator_;
        _liquidationFeePercent.denominator = liquidationFeePercentDenominator_;
    }

    // Set the liquidation fee percent
    function setLiquidationFeePercent(uint256 liquidationFeePercentNumerator_, uint256 liquidationFeePercentDenominator_) external onlyOwner {
        _liquidationFeePercent.numerator = liquidationFeePercentNumerator_;
        _liquidationFeePercent.denominator = liquidationFeePercentDenominator_;
    }

    // Get the liquidation fee percent
    function liquidationFeePercent() public view override returns (uint256, uint256) {
        return _liquidationFeePercent.export();
    }

    // Reset the accounts collateral
    function _resetCollateral(address account_) internal {
        address[] memory collateralTokens = _collateralTokens(account_);
        uint256[] memory collateralAmounts = _collateralAmounts(account_);

        _deposit(collateralTokens, collateralAmounts);
        for (uint256 i = 0; i < collateralTokens.length; i++) _setCollateral(collateralTokens[i], 0, account_);
    }

    event Liquidated(address indexed account, address liquidator);
}