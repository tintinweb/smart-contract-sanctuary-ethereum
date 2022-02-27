//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {ResolverResolve} from "./ResolverResolve.sol";

contract Resolver is Initializable, ResolverResolve {
    function initialize(
        address taskTreasury_,
        address depositReceiver_,
        address ethAddress_,
        address marginLong_,
        address converter_
    ) external initializer {
        initializeResolverCore(taskTreasury_, depositReceiver_, ethAddress_, marginLong_, converter_);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
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

import {IERC20Upgradeable, SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {ITaskTreasury} from "./ITaskTreasury.sol";
import {MarginLong} from "../Margin/MarginLong/MarginLong.sol";
import {IConverter} from "../Converter/IConverter.sol";

import {ResolverCore} from "./ResolverCore.sol";

abstract contract ResolverResolve is ResolverCore {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Convert liquidated amounts to ETH
    function _redepositEth(address[] memory repayToken_, uint256[] memory repayAmount_) internal returns (uint256) {
        uint256 total = 0;

        for (uint256 i = 0; i < repayToken_.length; i++) {
            if (repayAmount_[i] > 0) {
                IERC20Upgradeable(repayToken_[i]).safeApprove(converter, repayAmount_[i]);
                uint256 amountOut = IConverter(converter).swapMaxTokenInEthOut(repayToken_[i], repayAmount_[i]);

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
    function executeLiquidate(address account_) external whenNotPaused {
        (address[] memory repayTokens, uint256[] memory repayAmounts) = MarginLong(marginLong).liquidateAccount(account_);
        _redepositEth(repayTokens, repayAmounts);
    }

    // Execute reset and repay
    function executeReset(address account_) external whenNotPaused {
        (address[] memory repayTokens, uint256[] memory repayAmounts) = MarginLong(marginLong).resetAccount(account_);
        _redepositEth(repayTokens, repayAmounts);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
        initializeMarginLimits(minCollateralPrice_);
        initializeMarginLevel(maxLeverageNumerator_, maxLeverageDenominator_);
        initializeMarginLongLiquidateCore(liquidationFeePercentNumerator_, liquidationFeePercentDenominator_);
    }
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IConverter {
    function maxAmountTokenInTokenOut(
        address tokenIn_,
        uint256 amountIn_,
        address tokenOut_
    ) external view returns (uint256);

    function minAmountTokenInTokenOut(
        address tokenIn_,
        address tokenOut_,
        uint256 amountOut_
    ) external view returns (uint256);

    function swapMaxTokenInTokenOut(
        address tokenIn_,
        uint256 amountIn_,
        address tokenOut_
    ) external returns (uint256);

    function swapMaxEthInTokenOut(address tokenOut_) external payable returns (uint256);

    function swapMaxTokenInEthOut(address tokenIn_, uint256 amountIn_) external returns (uint256);
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

abstract contract ResolverCore is Initializable, AccessControlUpgradeable, PausableUpgradeable {
    bytes32 public RESOLVER_ADMIN;

    address public taskTreasury;
    address public depositReceiver;
    address public ethAddress;

    address public converter;
    address public marginLong;

    function initializeResolverCore(
        address taskTreasury_,
        address depositReceiver_,
        address ethAddress_,
        address marginLong_,
        address converter_
    ) public initializer {
        __AccessControl_init();
        __Pausable_init();

        RESOLVER_ADMIN = keccak256("RESOLVER_ADMIN_ROLE");
        _setRoleAdmin(RESOLVER_ADMIN, RESOLVER_ADMIN);
        _grantRole(RESOLVER_ADMIN, _msgSender());

        taskTreasury = taskTreasury_;
        depositReceiver = depositReceiver_;
        ethAddress = ethAddress_;
        marginLong = marginLong_;
        converter = converter_;
    }

    // Pause the contract
    function pause() external onlyRole(RESOLVER_ADMIN) {
        _pause();
    }

    // Unpause the contract
    function unpause() external onlyRole(RESOLVER_ADMIN) {
        _unpause();
    }

    // Set the task treasury to use
    function setTaskTreasury(address taskTreasury_) external onlyRole(RESOLVER_ADMIN) {
        taskTreasury = taskTreasury_;
    }

    // Set the deposit receiver
    function setDepositReceiver(address depositReceiver_) external onlyRole(RESOLVER_ADMIN) {
        depositReceiver = depositReceiver_;
    }

    // Set the eth address
    function setEthAddress(address ethAddress_) external onlyRole(RESOLVER_ADMIN) {
        ethAddress = ethAddress_;
    }

    // Set the converter to use
    function setConverter(address converter_) external onlyRole(RESOLVER_ADMIN) {
        converter = converter_;
    }

    // Set the margin long to use
    function setMarginLong(address marginLong_) external onlyRole(RESOLVER_ADMIN) {
        marginLong = marginLong_;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
import {LPool} from "../../LPool/LPool.sol";
import {IOracle} from "../../Oracle/IOracle.sol";

import {MarginLongCore} from "./MarginLongCore.sol";

abstract contract MarginLongBorrow is MarginLongCore {
    using SafeMathUpgradeable for uint256;

    // Margin borrow against collateral
    function borrow(address token_, uint256 amount_) external whenNotPaused onlyApprovedBorrowToken(token_) {
        require(amount_ > 0, "MarginLongBorrow: Amount borrowed must be greater than 0");

        if (!_isBorrowing(_msgSender())) _addAccount(_msgSender());
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

import {MarginLongRepayCore} from "./MarginLongRepayCore.sol";

abstract contract MarginLongRepay is MarginLongRepayCore {
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
    function repayAccount(address token_) external whenNotPaused onlyBorrowToken(token_) {
        require(_isBorrowing(token_, _msgSender()), "MarginLongRepay: Cannot repay account with no leveraged position");

        _repayAccount(token_, _msgSender());
        require(!resettable(_msgSender()), "MarginLongRepay: Repaying position puts account at risk");

        emit Repay(_msgSender(), token_);
    }

    // Repay all borrowed positions in an account
    function repayAccount() external whenNotPaused {
        require(_isBorrowing(_msgSender()), "MarginLongRepay: Cannot repay account with no leveraged positions");

        _repayAccount(_msgSender());

        emit RepayAll(_msgSender());
    }

    // Reset an account
    function resetAccount(address account_) external whenNotPaused returns (address[] memory, uint256[] memory) {
        require(resettable(account_), "MarginLongRepay: This account cannot be reset");

        _repayAccount(account_);

        (address[] memory collateralTokens, uint256[] memory collateralTax) = _taxAccount(account_, _msgSender());

        emit Reset(account_, _msgSender());

        return (collateralTokens, collateralTax);
    }
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {MarginLongLiquidateCore} from "./MarginLongLiquidateCore.sol";

abstract contract MarginLongLiquidate is MarginLongLiquidateCore {
    // Helper for liquidating accounts
    function _liquidateAccount(address account_) internal {
        _resetCollateral(account_);
        _resetBorrowed(account_);
    }

    // Liquidate an account
    function liquidateAccount(address account_) external whenNotPaused returns (address[] memory, uint256[] memory) {
        require(liquidatable(account_), "MarginLongLiquidate: This account cannot be liquidated");

        (address[] memory collateralTokens, uint256[] memory collateralTax) = _taxAccount(account_, _msgSender());

        _liquidateAccount(account_);

        emit Liquidated(account_, _msgSender());

        return (collateralTokens, collateralTax);
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
    function isSupported(address token_) external view returns (bool);

    function priceDecimals() external view returns (uint256);

    function priceMin(address token_, uint256 amount_) external view returns (uint256);

    function priceMax(address token_, uint256 amount_) external view returns (uint256);

    function amountMin(address token_, uint256 price_) external view returns (uint256);

    function amountMax(address token_, uint256 price_) external view returns (uint256);
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {MarginCollateral} from "../MarginCollateral.sol";
import {MarginBorrowers} from "../MarginBorrowers.sol";

abstract contract MarginLongCore is MarginCollateral, MarginBorrowers {}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20Upgradeable, SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import {LPoolLiquidity} from "./LPoolLiquidity.sol";
import {LPoolToken} from "./Token/LPoolToken.sol";

abstract contract LPoolProvide is LPoolLiquidity {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Return the amount of LP tokens received for adding a given amount of tokens as liquidity
    function provideLiquidityOutLPTokens(address token_, uint256 amount_) public view onlyApprovedPT(token_) returns (uint256) {
        LPoolToken LPToken = LPoolToken(LPFromPT(token_));

        uint256 _totalSupply = LPToken.totalSupply();
        uint256 _totalAmountLocked = totalAmountLocked(token_);

        if (_totalAmountLocked == 0) return amount_;

        return amount_.mul(_totalSupply).div(_totalAmountLocked);
    }

    // Provide tokens to the liquidity pool and receive LP tokens that represent the users share in the pool
    function provideLiquidity(address token_, uint256 amount_) external whenNotPaused onlyApprovedPT(token_) returns (uint256) {
        require(amount_ > 0, "LPoolProvide: Amount of tokens must be greater than 0");

        LPoolToken LPToken = LPoolToken(LPFromPT(token_));

        uint256 outTokens = provideLiquidityOutLPTokens(token_, amount_);
        require(outTokens > 0, "LPoolProvide: Not enough tokens provided");

        IERC20Upgradeable(token_).safeTransferFrom(_msgSender(), address(this), amount_);
        LPToken.mint(_msgSender(), outTokens);

        emit AddLiquidity(_msgSender(), token_, amount_, outTokens);

        return outTokens;
    }

    // Get the amount of pool tokens for redeeming LP tokens
    function redeemLiquidityOutPoolTokens(address token_, uint256 amount_) public view onlyLP(token_) returns (uint256) {
        LPoolToken LPToken = LPoolToken(token_);

        uint256 _totalSupply = LPToken.totalSupply();
        uint256 _totalAmountLocked = totalAmountLocked(PTFromLP(token_));

        return amount_.mul(_totalAmountLocked).div(_totalSupply);
    }

    // Redeem LP tokens for the underlying asset
    function redeemLiquidity(address token_, uint256 amount_) external whenNotPaused onlyLP(token_) returns (uint256) {
        require(amount_ > 0, "LPoolProvide: Amount of tokens must be greater than 0");

        LPoolToken LPToken = LPoolToken(token_);
        address poolToken = PTFromLP(token_);

        uint256 outTokens = redeemLiquidityOutPoolTokens(token_, amount_);
        require(outTokens <= liquidity(poolToken), "LPoolProvide: Not enough liquidity to redeem at this time");

        LPToken.burn(_msgSender(), amount_);
        IERC20Upgradeable(poolToken).safeTransfer(_msgSender(), outTokens);

        emit RedeemLiquidity(_msgSender(), token_, amount_, outTokens);

        return outTokens;
    }

    event AddLiquidity(address indexed account, address token, uint256 amount, uint256 lpTokenAmount);
    event RedeemLiquidity(address indexed account, address token, uint256 amount, uint256 poolTokenAmount);
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {FractionMath} from "../lib/FractionMath.sol";

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

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import {LPoolClaim} from "./LPoolClaim.sol";
import {LPoolDeposit} from "./LPoolDeposit.sol";

abstract contract LPoolLiquidity is LPoolClaim, LPoolDeposit {
    using SafeMathUpgradeable for uint256;

    // Return the total amount locked of a given asset
    function totalAmountLocked(address token_) public view onlyPT(token_) returns (uint256) {
        return IERC20Upgradeable(token_).balanceOf(address(this));
    }

    // Get the available liquidity of the pool
    function liquidity(address token_) public view override(LPoolClaim, LPoolDeposit) onlyPT(token_) returns (uint256) {
        return totalAmountLocked(token_).sub(_totalAmountClaimed(token_));
    }

    // Get the total utilized in the pool
    function utilized(address token_) public view override onlyPT(token_) returns (uint256) {
        return totalAmountLocked(token_).sub(liquidity(token_));
    }

    // Get the utilization rate for a given asset
    function utilizationRate(address token_) public view onlyPT(token_) returns (uint256, uint256) {
        return (utilized(token_), totalAmountLocked(token_));
    }
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {ERC20PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract LPoolToken is Initializable, AccessControlUpgradeable, ERC20Upgradeable, ERC20PausableUpgradeable {
    bytes32 public TOKEN_ADMIN;

    function initialize(string memory name_, string memory symbol_) external initializer {
        __AccessControl_init();
        __ERC20_init(name_, symbol_);
        __ERC20Pausable_init();

        TOKEN_ADMIN = keccak256("TOKEN_ADMIN_ROLE");
        _setRoleAdmin(TOKEN_ADMIN, TOKEN_ADMIN);
        _grantRole(TOKEN_ADMIN, _msgSender());
    }

    function mint(address account_, uint256 amount_) external onlyRole(TOKEN_ADMIN) {
        _mint(account_, amount_);
    }

    function burn(address account_, uint256 amount_) external onlyRole(TOKEN_ADMIN) {
        _burn(account_, amount_);
    }

    // Pause the contract
    function pause() external onlyRole(TOKEN_ADMIN) {
        _pause();
    }

    // Unpause the contract
    function unpause() external onlyRole(TOKEN_ADMIN) {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 amount_
    ) internal override(ERC20Upgradeable, ERC20PausableUpgradeable) {
        super._beforeTokenTransfer(from_, to_, amount_);
    }
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
    function claim(address token_, uint256 amount_) external whenNotPaused onlyRole(POOL_ADMIN) onlyApprovedPT(token_) {
        require(amount_ > 0, "LPoolClaim: claim amount must be greater than 0");
        require(amount_ <= liquidity(token_), "LPoolClaim: Cannot claim more than total liquidity");

        _claimed[_msgSender()][token_] = _claimed[_msgSender()][token_].add(amount_);
        _totalClaimed[token_] = _totalClaimed[token_].add(amount_);
    }

    // Unclaim an amount of a given token
    function unclaim(address token_, uint256 amount_) external whenNotPaused onlyRole(POOL_ADMIN) onlyPT(token_) {
        require(amount_ > 0, "LPoolClaim: Unclaim amount must be greater than 0");
        require(amount_ <= _claimed[_msgSender()][token_], "LPoolClaim: Cannot unclaim more than current claim");

        _claimed[_msgSender()][token_] = _claimed[_msgSender()][token_].sub(amount_);
        _totalClaimed[token_] = _totalClaimed[token_].sub(amount_);
    }

    // Get the total amount claimed
    function _totalAmountClaimed(address token_) internal view returns (uint256) {
        return _totalClaimed[token_];
    }

    function liquidity(address token_) public view virtual returns (uint256);
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20Upgradeable, SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {IOracle} from "../Oracle/IOracle.sol";
import {IConverter} from "../Converter/IConverter.sol";

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
            uint256 _utilized = utilized(poolTokens[i]);

            if (_utilized > 0) {
                (uint256 interestRateNumerator, uint256 interestRateDenominator) = interestRate(poolTokens[i]);
                uint256 utilizedValue = IOracle(oracle).priceMax(poolTokens[i], _utilized);

                uint256 weightSize = utilizedValue.mul(interestRateNumerator).div(interestRateDenominator);

                weights[i] = weightSize;
                totalWeightSize = totalWeightSize.add(weightSize);
            }
        }

        uint256 randomSample = uint256(keccak256(abi.encodePacked(block.difficulty, block.number, gasleft(), _msgSender()))).mod(totalWeightSize).add(1);

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
    function deposit(address token_, uint256 amount_) external whenNotPaused onlyRole(POOL_ADMIN) {
        require(amount_ > 0, "LPoolDeposit: Deposit amount must be greater than 0");

        IERC20Upgradeable(token_).safeTransferFrom(_msgSender(), address(this), amount_);

        address convertedToken = _pseudoRandomWeightedPT();
        uint256 convertedAmount = amount_;
        if (convertedToken != token_) {
            IERC20Upgradeable(token_).safeApprove(converter, amount_);
            convertedAmount = IConverter(converter).swapMaxTokenInTokenOut(token_, amount_, convertedToken);
        }

        uint256 totalTax = _payTax(convertedToken, convertedAmount);

        emit Deposit(_msgSender(), token_, amount_, convertedToken, convertedAmount.sub(totalTax));
    }

    // Withdraw a given amount of collateral from the pool
    function withdraw(address token_, uint256 amount_) external whenNotPaused onlyRole(POOL_ADMIN) onlyApprovedPT(token_) {
        require(amount_ > 0, "LPoolDeposit: Withdraw amount must be greater than 0");
        require(amount_ <= liquidity(token_), "LPoolDeposit: Withdraw amount exceeds available liquidity");

        IERC20Upgradeable(token_).safeTransfer(_msgSender(), amount_);

        emit Withdraw(_msgSender(), token_, amount_);
    }

    function liquidity(address token_) public view virtual returns (uint256);

    function utilized(address token_) public view virtual returns (uint256);

    function interestRate(address token_) public view virtual returns (uint256, uint256);

    event Deposit(address indexed account, address tokenIn, uint256 amount, address convertedToken, uint256 convertedAmount);
    event Withdraw(address indexed account, address token, uint256 amount);
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {EnumerableSetUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import {LPoolCore} from "./LPoolCore.sol";

abstract contract LPoolApproved is LPoolCore {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(address => address) private _PTToLP;
    mapping(address => address) private _LPToPT;

    EnumerableSetUpgradeable.AddressSet private _PTSet;

    mapping(address => bool) private _approved;

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
    function addLPToken(address[] memory token_, address[] memory lpToken_) external onlyRole(POOL_ADMIN) {
        for (uint256 i = 0; i < token_.length; i++) {
            if (!isPT(token_[i]) && !isLP(lpToken_[i])) {
                _PTToLP[token_[i]] = lpToken_[i];
                _LPToPT[lpToken_[i]] = token_[i];
            }
        }
    }

    // Get a list of pool tokens
    function _poolTokens() internal view returns (address[] memory) {
        return _PTSet.values();
    }

    // Approve pool tokens for use with the pool if it is different to its current approved state - a LP token is approved if and only if its pool token is approved
    function setApproved(address[] memory token_, bool[] memory approved_) external onlyRole(POOL_ADMIN) {
        for (uint256 i = 0; i < token_.length; i++) {
            if (isPT(token_[i])) {
                _approved[token_[i]] = approved_[i];

                if (_approved[token_[i]] && !_PTSet.contains(token_[i])) _PTSet.add(token_[i]);
                else if (!_approved[token_[i]] && _PTSet.contains(token_[i])) _PTSet.remove(token_[i]);
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

abstract contract LPoolCore is Initializable, AccessControlUpgradeable, PausableUpgradeable {
    bytes32 public POOL_ADMIN;

    address public converter;
    address public oracle;

    function initializeLPoolCore(address converter_, address oracle_) public initializer {
        __AccessControl_init();
        __Pausable_init();

        POOL_ADMIN = keccak256("POOL_ADMIN_ROLE");
        _setRoleAdmin(POOL_ADMIN, POOL_ADMIN);
        _grantRole(POOL_ADMIN, _msgSender());

        converter = converter_;
        oracle = oracle_;
    }

    // Pause the contract
    function pause() external onlyRole(POOL_ADMIN) {
        _pause();
    }

    // Unpause the contract
    function unpause() external onlyRole(POOL_ADMIN) {
        _unpause();
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
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

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
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
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
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
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
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
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
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
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

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {IERC20Upgradeable, SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {FractionMath} from "../lib/FractionMath.sol";
import {EnumerableSetUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import {LPoolCore} from "./LPoolCore.sol";

abstract contract LPoolTax is Initializable, LPoolCore {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using FractionMath for FractionMath.Fraction;

    FractionMath.Fraction private _taxPercent;
    EnumerableSetUpgradeable.AddressSet private _taxAccountSet;

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
        _taxAccountSet.add(account_);
    }

    // Remove a tax account
    function removeTaxAccount(address account_) external onlyRole(POOL_ADMIN) {
        _taxAccountSet.remove(account_);
    }

    // Apply and distribute tax
    function _payTax(address token_, uint256 amountIn_) internal returns (uint256) {
        address[] memory taxAccounts = _taxAccountSet.values();

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
        require(isValid(fraction), "FractionMath: Denominator of fraction cannot equal 0");
        _;
    }

    function isValid(Fraction memory fraction) internal pure returns (bool) {
        return fraction.denominator != 0;
    }

    function create(uint256 a, uint256 b) internal pure returns (Fraction memory fraction) {
        fraction = Fraction({numerator: a, denominator: b});
        require(isValid(fraction), "FractionMath: Denominator of fraction cannot equal 0");
    }

    function export(Fraction memory fraction) internal pure onlyValid(fraction) returns (uint256, uint256) {
        return (fraction.numerator, fraction.denominator);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../security/PausableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20PausableUpgradeable is Initializable, ERC20Upgradeable, PausableUpgradeable {
    function __ERC20Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __ERC20Pausable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

import {IERC20Upgradeable, SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import {MarginLevel} from "./MarginLevel.sol";
import {MarginApproved} from "./MarginApproved.sol";
import {MarginLimits} from "./MarginLimits.sol";

abstract contract MarginCollateral is MarginApproved, MarginLevel, MarginLimits {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Deposit collateral into the account
    function addCollateral(address token_, uint256 amount_) external whenNotPaused onlyApprovedCollateralToken(token_) {
        require(amount_ > 0, "MarginCollateral: Amount added as collateral must be greater than 0");

        IERC20Upgradeable(token_).safeTransferFrom(_msgSender(), address(this), amount_);
        _setCollateral(token_, collateral(token_, _msgSender()).add(amount_), _msgSender());

        emit AddCollateral(_msgSender(), token_, amount_);
    }

    // Withdraw collateral from the account
    function removeCollateral(address token_, uint256 amount_) external whenNotPaused onlyCollateralToken(token_) {
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

import {EnumerableSetUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

abstract contract MarginBorrowers {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    EnumerableSetUpgradeable.AddressSet private _accountSet;

    // Add an account to the borrowed list
    function _addAccount(address account_) internal {
        _accountSet.add(account_);
    }

    // Remove an account from the borrowed list
    function _removeAccount(address account_) internal {
        _accountSet.remove(account_);
    }

    // Get a full list of all borrowing accounts
    function getBorrowingAccounts() public view returns (address[] memory) {
        return _accountSet.values();
    }
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {FractionMath} from "../lib/FractionMath.sol";

import {MarginAccount} from "./MarginAccount.sol";

abstract contract MarginLevel is Initializable, MarginAccount {
    using FractionMath for FractionMath.Fraction;

    FractionMath.Fraction private _maxLeverage;

    function initializeMarginLevel(uint256 maxLeverageNumerator_, uint256 maxLeverageDenominator_) public initializer {
        _maxLeverage.numerator = maxLeverageNumerator_;
        _maxLeverage.denominator = maxLeverageDenominator_;
    }

    // Set the maximum leverage
    function setMaxLeverage(uint256 maxLeverageNumerator_, uint256 maxLeverageDenominator_) external onlyRole(MARGIN_ADMIN) {
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
        if (!_isBorrowing(account_)) return false;

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
    mapping(address => bool) private _borrowTokens;

    mapping(address => bool) private _approvedCollateralTokens;
    mapping(address => bool) private _approvedBorrowTokens;

    // Add a collateral token
    function addCollateralToken(address[] memory token_) public onlyRole(MARGIN_ADMIN) {
        for (uint256 i = 0; i < token_.length; i++) if (!isCollateralToken(token_[i])) _collateralTokens[token_[i]] = true;
    }

    // Add a borrow token
    function addBorrowToken(address[] memory token_) external onlyRole(MARGIN_ADMIN) {
        for (uint256 i = 0; i < token_.length; i++) if (!isBorrowToken(token_[i])) _borrowTokens[token_[i]] = true;
        addCollateralToken(token_);
    }

    // Approve a token for collateral
    function setApprovedCollateralToken(address[] memory token_, bool[] memory approved_) external onlyRole(MARGIN_ADMIN) {
        for (uint256 i = 0; i < token_.length; i++) {
            if (isCollateralToken(token_[i])) _approvedCollateralTokens[token_[i]] = approved_[i];
        }
    }

    // Approve a borrow token
    function setApprovedBorrowToken(address[] memory token_, bool[] memory approved_) external onlyRole(MARGIN_ADMIN) {
        for (uint256 i = 0; i < token_.length; i++) {
            if (isBorrowToken(token_[i])) _approvedBorrowTokens[token_[i]] = approved_[i];
        }
    }

    // Check if a token is a collateral token
    function isCollateralToken(address token_) public view returns (bool) {
        return _collateralTokens[token_];
    }

    // Check if a token is a borrow token
    function isBorrowToken(address token_) public view returns (bool) {
        return _borrowTokens[token_];
    }

    // Check if a token is an approved collateral token
    function isApprovedCollateralToken(address token_) public view returns (bool) {
        return isCollateralToken(token_) && _approvedCollateralTokens[token_];
    }

    // Check if a token is an approved borrow token
    function isApprovedBorrowToken(address token_) public view returns (bool) {
        return isBorrowToken(token_) && _approvedBorrowTokens[token_];
    }

    modifier onlyCollateralToken(address token_) {
        require(isCollateralToken(token_), "MarginApproved: Only collateral tokens may be used");
        _;
    }

    modifier onlyBorrowToken(address token_) {
        require(isBorrowToken(token_), "MarginApproved: Only borrow tokens may be used");
        _;
    }

    modifier onlyApprovedCollateralToken(address token_) {
        require(isApprovedCollateralToken(token_), "MarginApproved: Only approved collateral tokens may be used");
        _;
    }

    modifier onlyApprovedBorrowToken(address token_) {
        require(isApprovedBorrowToken(token_), "MarginApproved: Only approved borrow tokens may be used");
        _;
    }
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
    function setMinCollateralPrice(uint256 minCollateralPrice_) external onlyRole(MARGIN_ADMIN) {
        minCollateralPrice = minCollateralPrice_;
    }

    // Check if an account has sufficient collateral to leverage
    function _sufficientCollateralPrice(address account_) internal view returns (bool) {
        return collateralPrice(account_) >= minCollateralPrice;
    }

    // Check if an account is resettable
    function resettable(address account_) public view returns (bool) {
        return (_isBorrowing(account_) && !_sufficientCollateralPrice(account_));
    }
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {LPool} from "../LPool/LPool.sol";
import {IOracle} from "../Oracle/IOracle.sol";
import {EnumerableSetUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import {MarginPool} from "./MarginPool.sol";

abstract contract MarginAccount is MarginPool {
    using SafeMathUpgradeable for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    struct Account {
        EnumerableSetUpgradeable.AddressSet collateral;
        mapping(address => uint256) collateralAmounts;
        EnumerableSetUpgradeable.AddressSet borrowed;
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

        if (!account.collateral.contains(token_) && amount_ != 0) account.collateral.add(token_);
        else if (account.collateral.contains(token_) && amount_ == 0) account.collateral.remove(token_);

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

        for (uint256 i = 0; i < account.collateral.length(); i++) {
            address token = account.collateral.at(i);
            uint256 price = IOracle(oracle).priceMin(token, collateral(token, account_));

            totalPrice = totalPrice.add(price);
        }

        return totalPrice;
    }

    // Get the collateral tokens list
    function _collateralTokens(address account_) internal view returns (address[] memory) {
        return _accounts[account_].collateral.values();
    }

    // Set the amount the user has borrowed
    function _setBorrowed(
        address token_,
        uint256 amount_,
        address account_
    ) internal {
        Account storage account = _accounts[account_];

        if (!account.borrowed.contains(token_) && amount_ != 0) account.borrowed.add(token_);
        else if (account.borrowed.contains(token_) && amount_ == 0) account.borrowed.remove(token_);

        _setTotalBorrowed(token_, totalBorrowed(token_).sub(account.borrowedAmounts[token_]).add(amount_));
        account.hasBorrowed = account.hasBorrowed.sub(account.borrowedAmounts[token_]).add(amount_);
        account.borrowedAmounts[token_] = amount_;
    }

    // Get the borrowed for a given account
    function borrowed(address token_, address account_) public view onlyBorrowToken(token_) returns (uint256) {
        Account storage account = _accounts[account_];
        return account.borrowedAmounts[token_];
    }

    // Get the total price of the assets borrowed
    function borrowedPrice(address account_) public view returns (uint256) {
        Account storage account = _accounts[account_];
        uint256 totalPrice = 0;

        for (uint256 i = 0; i < account.borrowed.length(); i++) {
            address token = account.borrowed.at(i);
            uint256 price = IOracle(oracle).priceMin(token, borrowed(token, account_));

            totalPrice = totalPrice.add(price);
        }

        return totalPrice;
    }

    // Get the borrowed tokens list
    function _borrowedTokens(address account_) internal view returns (address[] memory) {
        return _accounts[account_].borrowed.values();
    }

    // Check if an account is currently borrowing
    function _isBorrowing(address account_) internal view returns (bool) {
        Account storage account = _accounts[account_];
        return account.hasBorrowed > 0;
    }

    // Check if an account is currently borrowing a particular asset
    function _isBorrowing(address token_, address account_) internal view returns (bool) {
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
    function initialBorrowPrice(address token_, address account_) public view onlyBorrowToken(token_) returns (uint256) {
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
    function _initialBorrowTime(address token_, address account_) internal view returns (uint256) {
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
    function interest(address token_, address account_) public view onlyBorrowToken(token_) returns (uint256) {
        return _accumulatedInterest(token_, account_).add(LPool(pool).interest(token_, initialBorrowPrice(token_, account_), _initialBorrowTime(token_, account_)));
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

        uint256 temp1 = _collateralPrice.add(_borrowedPrice);
        uint256 temp2 = _initialBorrowPrice.add(_interest);

        if (temp2 > temp1) return 0;
        return temp1.sub(temp2);
    }
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {MarginApproved} from "./MarginApproved.sol";

abstract contract MarginPool is MarginApproved {
    mapping(address => uint256) private _totalBorrowed;
    mapping(address => uint256) private _totalCollateral;

    // Get the total borrowed of a given asset
    function totalBorrowed(address token_) public view onlyBorrowToken(token_) returns (uint256) {
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
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

abstract contract MarginCore is Initializable, AccessControlUpgradeable, PausableUpgradeable {
    bytes32 public MARGIN_ADMIN;

    address public pool;
    address public oracle;

    function initializeMarginCore(address pool_, address oracle_) public initializer {
        __AccessControl_init();
        __Pausable_init();

        MARGIN_ADMIN = keccak256("MARGIN_ADMIN_ROLE");
        _setRoleAdmin(MARGIN_ADMIN, MARGIN_ADMIN);
        _grantRole(MARGIN_ADMIN, _msgSender());

        pool = pool_;
        oracle = oracle_;
    }

    // Pause the contract
    function pause() external onlyRole(MARGIN_ADMIN) {
        _pause();
    }

    // Unpause the contract
    function unpause() external onlyRole(MARGIN_ADMIN) {
        _unpause();
    }

    // Set the pool to use
    function setPool(address pool_) external onlyRole(MARGIN_ADMIN) {
        pool = pool_;
    }

    // Set the oracle to use
    function setOracle(address oracle_) external onlyRole(MARGIN_ADMIN) {
        oracle = oracle_;
    }
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20Upgradeable, SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {IOracle} from "../../Oracle/IOracle.sol";
import {LPool} from "../../LPool/LPool.sol";

import {MarginLongCore} from "./MarginLongCore.sol";

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
            uint256 collateralPrice = IOracle(oracle).priceMin(collateralToken_[collateralIndex_], collateralAmount);

            if (collateralPrice < debt_) {
                collateralRepayAmount_[collateralIndex_] = collateralRepayAmount_[collateralIndex_].add(collateralAmount);
                _setCollateral(collateralToken_[collateralIndex_], 0, account_);

                debt_ = debt_.sub(collateralPrice);
                collateralIndex_ = collateralIndex_.add(1);
            } else {
                uint256 newAmount = IOracle(oracle).amountMax(collateralToken_[collateralIndex_], debt_);
                if (newAmount > collateralAmount) newAmount = collateralAmount;

                collateralRepayAmount_[collateralIndex_] = collateralRepayAmount_[collateralIndex_].add(newAmount);
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

        if (!_isBorrowing(account_)) _removeAccount(account_);
    }

    // Reset the users borrowed amounts
    function _resetBorrowed(address account_) internal {
        address[] memory borrowedTokens = _borrowedTokens(account_);

        for (uint256 i = 0; i < borrowedTokens.length; i++) _resetBorrowed(borrowedTokens[i], account_);
    }

    function liquidationFeePercent() public view virtual returns (uint256, uint256);

    event Repay(address indexed account, address token);
    event RepayAll(address indexed account);
    event Reset(address indexed account, address executor);
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {FractionMath} from "../../lib/FractionMath.sol";

import {MarginLongRepayCore} from "./MarginLongRepayCore.sol";

abstract contract MarginLongLiquidateCore is Initializable, MarginLongRepayCore {
    using FractionMath for FractionMath.Fraction;

    FractionMath.Fraction private _liquidationFeePercent;

    function initializeMarginLongLiquidateCore(uint256 liquidationFeePercentNumerator_, uint256 liquidationFeePercentDenominator_) public initializer {
        _liquidationFeePercent.numerator = liquidationFeePercentNumerator_;
        _liquidationFeePercent.denominator = liquidationFeePercentDenominator_;
    }

    // Set the liquidation fee percent
    function setLiquidationFeePercent(uint256 liquidationFeePercentNumerator_, uint256 liquidationFeePercentDenominator_) external onlyRole(MARGIN_ADMIN) {
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

        uint256[] memory collateralAmounts = new uint256[](collateralTokens.length);
        for (uint256 i = 0; i < collateralTokens.length; i++) collateralAmounts[i] = collateral(collateralTokens[i], account_);

        _deposit(collateralTokens, collateralAmounts);
        for (uint256 i = 0; i < collateralTokens.length; i++) _setCollateral(collateralTokens[i], 0, account_);
    }

    event Liquidated(address indexed account, address executor);
}