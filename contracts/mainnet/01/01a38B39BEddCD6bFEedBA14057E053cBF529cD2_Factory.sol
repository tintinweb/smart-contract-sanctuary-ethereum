// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is disstributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.6.12;
import "../base/WhiteToken.sol";
import "../interfaces/IBFactory.sol";
import "../libraries/SafeERC20.sol";

contract Factory is WhiteToken {
    using SafeERC20 for IERC20;

    event LOG_NEW_POOL(address indexed caller, address indexed pool);
    event LOG_BLABS(address indexed caller, address indexed blabs);
    event LOG_ROUTER(address indexed caller, address indexed router);
    event LOG_VAULT(address indexed vault, address indexed caller);
    event LOG_USER_VAULT(address indexed vault, address indexed caller);
    event LOG_MANAGER(address indexed manager, address indexed caller);
    event LOG_ORACLE(address indexed caller, address indexed oracle);
    event SYSTEM_MODULE_CHANGED(address module, bool state);
    event MODULE_STATUS_CHANGE(address etf, address module, bool status);
    event PAUSED_STATUS(bool state);

    mapping(address => bool) private _isLiquidityPool;
    mapping(address => bool) private _isSystemModule;
    mapping(address => mapping(address => bool)) private _isModuleRegistered;
    uint private counters;
    bytes private bytecodes;
    bool public isPaused;

    address private _blabs;
    address private _oracle;
    address private _vaultAddress;
    address private _userVaultAddress;

    constructor(
      address oracle,
      address vault,
      address userVault
    ) public {
        _blabs = msg.sender;
        _oracle = oracle;
        _vaultAddress = vault;
        _userVaultAddress = userVault;
    }

    function addTokenToWhitelist(uint[] memory sort, address[] memory token) external onlyBlabs {
        require(sort.length == token.length, "ERR_SORT_TOKEN_MISMATCH");
        for (uint i = 0; i < sort.length; i++) {
            _addTokenToWhitelist(sort[i], token[i]);
        }
    }

    function removeTokenFromWhitelist(uint[] memory sort, address[] memory token) external onlyBlabs {
        require(sort.length == token.length, "ERR_SORT_TOKEN_MISMATCH");
        for (uint i = 0; i < sort.length; i++) {
            _removeTokenFromWhitelist(sort[i], token[i]);
        }
    }

    function isTokenWhitelistedForVerify(uint sort, address token) external view returns (bool) {
        return _isTokenWhitelistedForVerify(sort, token);
    }

    function isTokenWhitelistedForVerify(address token) external view returns (bool) {
        return _queryIsTokenWhitelisted(token);
    }

    function isLiquidityPool(address b) external view returns (bool) {
        return _isLiquidityPool[b];
    }

    function createPool() internal returns (address base) {
        bytes memory bytecode = bytecodes;
        bytes32 salt = keccak256(abi.encodePacked(counters++));

        assembly {
            base := create2(0, add(bytecode, 32), mload(bytecode), salt)
            if iszero(extcodesize(base)) {
                revert(0, 0)
            }
        }
        counters++;
    }

    function newLiquidityPool() external returns (IBPool) {
        address lpool = createPool();
        _isLiquidityPool[lpool] = true;
        emit LOG_NEW_POOL(msg.sender, lpool);
        IBPool(lpool).setController(msg.sender);
        return IBPool(lpool);
    }

    function getBLabs() external view returns (address) {
        return _blabs;
    }

    function setBLabs(address b) external onlyBlabs {
        require(b != address(0), "ERR_ZERO_ADDRESS");
        emit LOG_BLABS(msg.sender, b);
        _blabs = b;
    }

    function getModuleStatus(address etf, address module) external view returns (bool) {
        return _isSystemModule[module] || _isModuleRegistered[etf][module];
    }

    function getOracleAddress() external view returns (address) {
        return _oracle;
    }

    function setSystemModule(address module, bool state) external onlyBlabs {
        require(module != address(0), "ZERO ADDRESS");

        _isSystemModule[module] = state;

        emit SYSTEM_MODULE_CHANGED(module, state);
    }

    function registerModule(address etf, address module) external onlyBlabs {
        require(etf != address(0), "ZERO ETF ADDRESS");
        require(module != address(0), "ZERO ADDRESS");

        _isModuleRegistered[etf][module] = true;

        emit MODULE_STATUS_CHANGE(etf, module, true);
    }

    function removeModule(address etf, address module) external onlyBlabs {
        require(etf != address(0), "ZERO ETF ADDRESS");
        require(module != address(0), "ZERO ADDRESS");

        _isModuleRegistered[etf][module] = false;

        emit MODULE_STATUS_CHANGE(etf, module, false);
    }

    function setOracle(address oracle) external onlyBlabs {
        require(oracle != address(0), "ERR_ZERO_ADDRESS");
        emit LOG_ORACLE(msg.sender, oracle);
        _oracle = oracle;
    }

    function collect(IERC20 token) external onlyBlabs {
        uint collected = token.balanceOf(address(this));
        token.safeTransfer(_blabs, collected);
    }

    function getVault() external view returns (address) {
        return _vaultAddress;
    }

    function setVault(address newVault) external onlyBlabs {
        require(newVault != address(0), "ERR_ZERO_ADDRESS");
        _vaultAddress = newVault;
        emit LOG_VAULT(newVault, msg.sender);
    }

    function getUserVault() external view returns (address) {
        return _userVaultAddress;
    }

    function setUserVault(address newVault) external onlyBlabs {
        require(newVault != address(0), "ERR_ZERO_ADDRESS");
        _userVaultAddress = newVault;
        emit LOG_USER_VAULT(newVault, msg.sender);
    }

    function setProtocolPaused(bool state) external onlyBlabs {
        isPaused = state;
        emit PAUSED_STATUS(state);
    }

    function setByteCodes(bytes memory _bytecode) external onlyBlabs {
        bytecodes = _bytecode;
    }

    modifier onlyBlabs() {
        require(msg.sender == _blabs, "ERR_NOT_BLABS");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import {IERC20} from "../interfaces/IERC20.sol";
import {SafeMath} from "./SafeMath.sol";
import {Address} from "./Address.sol";

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
    using SafeMath for uint;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint value
    ) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint value
    ) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint value
    ) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0), "SafeERC20: approve from non-zero to non-zero allowance");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IBPool {
    function rebind(
        address token,
        uint balance,
        uint denorm
    ) external;

    function execute(
        address _target,
        uint _value,
        bytes calldata _data
    ) external returns (bytes memory _returnValue);

    function bind(
        address token,
        uint balance,
        uint denorm
    ) external;

    function unbind(address token) external;

    function unbindPure(address token) external;

    function isBound(address token) external view returns (bool);

    function getBalance(address token) external view returns (uint);

    function totalSupply() external view returns (uint);

    function isPublicSwap() external view returns (bool);

    function getDenormalizedWeight(address token) external view returns (uint);

    function getTotalDenormalizedWeight() external view returns (uint);

    function EXIT_FEE() external view returns (uint);

    function getCurrentTokens() external view returns (address[] memory tokens);

    function setController(address owner) external;
}

interface IBFactory {
    function newLiquidityPool() external returns (IBPool);

    function setBLabs(address b) external;

    function collect(IBPool pool) external;

    function isBPool(address b) external view returns (bool);

    function getBLabs() external view returns (address);

    function getVault() external view returns (address);

    function getUserVault() external view returns (address);

    function getVaultAddress() external view returns (address);

    function getOracleAddress() external view returns (address);

    function isTokenWhitelistedForVerify(uint sort, address token) external view returns (bool);

    function isTokenWhitelistedForVerify(address token) external view returns (bool);

    function getModuleStatus(address etf, address module) external view returns (bool);

    function isPaused() external view returns (bool);
}

interface IVault {
    function depositManagerToken(address[] calldata poolTokens, uint[] calldata tokensAmount) external;

    function depositIssueRedeemPToken(
        address[] calldata poolTokens,
        uint[] calldata tokensAmount,
        uint[] calldata tokensAmountP,
        bool isPerfermance
    ) external;

    function managerClaim(address pool) external;

    function getManagerClaimBool(address pool) external view returns (bool);
}

interface IUserVault {
    function recordTokenInfo(
        address kol,
        address user,
        address[] calldata poolTokens,
        uint[] calldata tokensAmount
    ) external;
}

interface Oracles {
    function getPrice(address tokenAddress) external returns (uint price);

    function getAllPrice(address[] calldata poolTokens, uint[] calldata tokensAmount) external returns (uint);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

contract WhiteToken {
    // add token log
    event LOG_WHITELIST(address indexed spender, uint indexed sort, address indexed caller, address token);
    // del token log
    event LOG_DEL_WHITELIST(address indexed spender, uint indexed sort, address indexed caller, address token);

    // record the number of whitelists.
    uint private _whiteTokenCount;
    // token address => is white token.
    mapping(address => bool) private _isTokenWhitelisted;
    // Multi level white token.
    // type => token address => is white token.
    mapping(uint => mapping(address => bool)) private _tokenWhitelistedInfo;

    function _queryIsTokenWhitelisted(address token) internal view returns (bool) {
        return _isTokenWhitelisted[token];
    }

    // for factory to verify
    function _isTokenWhitelistedForVerify(uint sort, address token) internal view returns (bool) {
        return _tokenWhitelistedInfo[sort][token];
    }

    // add sort token
    function _addTokenToWhitelist(uint sort, address token) internal {
        require(token != address(0), "ERR_INVALID_TOKEN_ADDRESS");
        require(_queryIsTokenWhitelisted(token) == false, "ERR_HAS_BEEN_ADDED_WHITE");

        _tokenWhitelistedInfo[sort][token] = true;
        _isTokenWhitelisted[token] = true;
        _whiteTokenCount++;

        emit LOG_WHITELIST(address(this), sort, msg.sender, token);
    }

    // remove sort token
    function _removeTokenFromWhitelist(uint sort, address token) internal {
        require(_queryIsTokenWhitelisted(token) == true, "ERR_NOT_WHITE_TOKEN");

        require(_tokenWhitelistedInfo[sort][token], "ERR_SORT_NOT_MATCHED");

        _tokenWhitelistedInfo[sort][token] = false;
        _isTokenWhitelisted[token] = false;
        _whiteTokenCount--;
        emit LOG_DEL_WHITELIST(address(this), sort, msg.sender, token);
    }

    // already has init
    function _initWhiteTokenState() internal view returns (bool) {
        return _whiteTokenCount == 0 ?  false : true;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

// Interface declarations

/* solhint-disable func-order */

interface IERC20 {
    // Emitted when the allowance of a spender for an owner is set by a call to approve.
    // Value is the new allowance
    event Approval(address indexed owner, address indexed spender, uint value);

    // Emitted when value tokens are moved from one account (from) to another (to).
    // Note that value may be zero
    event Transfer(address indexed from, address indexed to, uint value);

    // Returns the amount of tokens in existence
    function totalSupply() external view returns (uint);

    // Returns the amount of tokens owned by account
    function balanceOf(address account) external view returns (uint);

    // Returns the decimals of tokens
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    // Returns the remaining number of tokens that spender will be allowed to spend on behalf of owner
    // through transferFrom. This is zero by default
    // This value changes when approve or transferFrom are called
    function allowance(address owner, address spender) external view returns (uint);

    // Sets amount as the allowance of spender over the caller’s tokens
    // Returns a boolean value indicating whether the operation succeeded
    // Emits an Approval event.
    function approve(address spender, uint amount) external returns (bool);

    // Moves amount tokens from the caller’s account to recipient
    // Returns a boolean value indicating whether the operation succeeded
    // Emits a Transfer event.
    function transfer(address recipient, uint amount) external returns (bool);

    // Moves amount tokens from sender to recipient using the allowance mechanism
    // Amount is then deducted from the caller’s allowance
    // Returns a boolean value indicating whether the operation succeeded
    // Emits a Transfer event
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
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
    function sendValue(address payable recipient, uint amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        uint value
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
        uint value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint a, uint b) internal pure returns (uint) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint a, uint b) internal pure returns (uint) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
        require(b != 0, errorMessage);
        return a % b;
    }
}