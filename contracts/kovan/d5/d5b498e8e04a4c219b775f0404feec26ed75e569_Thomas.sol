/**
 *Submitted for verification at Etherscan.io on 2022-03-21
*/

// SPDX-License-Identifier: MIT
// File: tests/IterableMapping.sol
pragma solidity ^0.8.10;

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key) public view returns (int) {
        if(!map.inserted[key]) {
            return -1;
        }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint index) public view returns (address) {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint) {
        return map.keys.length;
    }

    function set(Map storage map, address key, uint val) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}
// File: tests/uniswap/IUniswapV2Factory.sol



pragma solidity ^0.8.10;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}
// File: tests/uniswap/IUniswapV2Router.sol


pragma solidity ^0.8.10;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
// File: tests/node_modules/openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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

// File: tests/node_modules/openzeppelin/contracts/utils/math/SafeMath.sol


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

// File: tests/node_modules/openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: tests/node_modules/openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


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

// File: tests/node_modules/openzeppelin/contracts/utils/Context.sol


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

// File: tests/node_modules/openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: tests/ThomasNodeManager.sol



pragma solidity ^0.8.10;








contract ThomasNodeManager is Ownable {
    using SafeMath for uint256;
    using IterableMapping for IterableMapping.Map;

    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    // Nodes
    struct NodeType {
      uint256 rewards; // Rewards of the Node
      uint256 timeToUpgrade; // Time to upgrade to the next Node
      uint256 typeUpgradeNode; // Type of the next Node
      uint256 price; // Price of the Node

      bool buyable;
      bool upgradable;
      bool disabled;
      bool bonus; // Bonus = not calculated in maxNode
    }

    struct Node {
      uint256 id;
      string name;
      uint256 nodeType;

      bool upgrading;

      uint256 createTimestamp;
      uint256 lastClaimTimestamp;
      uint256 ThomasUpgradeStartTimestamp;

      uint256 availableRewards;
    }

    // Booster
    struct BoosterData {
      address[] boosterChilds;
      address boosterGodFather;
      string boosterCode;

      bool boosterCodeSetup;
      bool boosterCodeUsed;
    }

    struct BoosterCode {
      bool isValid;
      address codeOwner;
      uint256 used;
    }

    // Settings
    uint256 public _maxNodes = 100;
    uint256 public _claimingTimestamp = 86400;
    uint256 public _gasForProcessing = 300000;
    uint256 public _minimumNodeUseRef = 1;
    uint256 public _minimumNodeSetRef = 3;
    uint256 public _maxAmountPerNode = 3;

    // Datas
    uint256 public _totalCreatedNodes = 0;
    uint256 public _totalEarn = 0;
    uint256 public _lastProcessedIndex = 0;
    bool private distributing = false;

    // Nodes
    IterableMapping.Map private nodeOwners;
    mapping(address => Node[]) private usersNodes;
    NodeType[] _nodeTypes;

    // Boosters
    mapping(address => BoosterData) private boosterDatas;
    mapping(string => BoosterCode) private boosterCodes;

    constructor() {
      // Thomas
      _nodeTypes.push(NodeType({
        rewards: 0.066 * (10**8),
        timeToUpgrade: 66 * 3600 * 24, // 66 Days
        typeUpgradeNode: 1, // Upgrade possible to 1
        price: 13 * (10**8),
        buyable: true,
        upgradable: true,
        disabled: false,
        bonus: false
      }));

      // Dark Thomas
      _nodeTypes.push(NodeType({
        rewards: 0.366 * (10**8),
        timeToUpgrade: 33 * 3600 * 24, // 33 Days
        typeUpgradeNode: 2, // Upgrade possible to 2
        price: 66 * (10**8),
        buyable: true,
        upgradable: true,
        disabled: false,
        bonus: false
      }));

      // Arch Thomas
      _nodeTypes.push(NodeType({
        rewards: 0.666 * (10**8),
        timeToUpgrade: 11 * 3600 * 24, // 11 Days
        typeUpgradeNode: 3, // Upgrade possible to 3
        price: 111 * (10**8),
        buyable: true,
        upgradable: true,
        disabled: false,
        bonus: false
      }));

      // Nemesis
      _nodeTypes.push(NodeType({
        rewards: 1 * (10**8),
        timeToUpgrade: 0,
        typeUpgradeNode: 0, // Upgrade impossible
        price: 100000000 * (10**8),
        buyable: false,
        upgradable: false,
        disabled: false,
        bonus: false
      }));

      // Booster
      _nodeTypes.push(NodeType({
        rewards: 0.111 * (10**8),
        timeToUpgrade: 0,
        typeUpgradeNode: 0, // Upgrade impossible
        price: 100000000 * (10**8),
        buyable: false,
        upgradable: false,
        disabled: false,
        bonus: true
      }));
    }

    function _setBoosterCode(address user, string memory code) external onlyOwner {
      require(!boosterCodes[code].isValid, "This code is already exist");
      require(!boosterDatas[user].boosterCodeSetup, "Cannot edit a booster code");
      require(getNumberOfSpecifiedMinNodes(user, _minimumNodeSetRef) > 0, "You need to have a specific node");

      boosterCodes[code].isValid = true;
      boosterCodes[code].codeOwner = user;
      boosterCodes[code].used = 0;

      boosterDatas[user].boosterCodeSetup = true;
      boosterDatas[user].boosterCode = code;
      boosterDatas[user].boosterGodFather = user;
    }

    function _useBoosterCode(address user, string memory code) external onlyOwner returns (address) {
      require(boosterCodes[code].isValid, "This code is not valid");
      require(!boosterDatas[user].boosterCodeUsed, "You already used a code");
      require(getNumberOfSpecifiedMinNodes(user, _minimumNodeUseRef) > 0, "You need to have a specific node");

      address codeOwner = boosterCodes[code].codeOwner;
      require(codeOwner != user, "You cannot use your code");
      require(
        boosterDatas[codeOwner].boosterChilds.length < getNumberOfSpecifiedMinNodes(codeOwner, _minimumNodeSetRef) * _maxAmountPerNode,
        "The code owner has no empty place");

      boosterDatas[codeOwner].boosterChilds.push(user);
      boosterDatas[user].boosterCodeUsed = true;
      boosterDatas[user].boosterGodFather = codeOwner;

      _createNode(codeOwner, "Booster Node", 4);

      return codeOwner;
    }

    function _createNode(address user, string memory name, uint256 nodeTypeId) public onlyOwner {
      require(_getNumberOfNodes(user) < _maxNodes, "Maximum of nodes reached");

      uint256 id = ++_totalCreatedNodes;

      usersNodes[user].push(Node({
        id: id,
        name: name,
        nodeType: nodeTypeId,
        upgrading: false,
        createTimestamp: block.timestamp,
        lastClaimTimestamp: block.timestamp,
        ThomasUpgradeStartTimestamp: 0,
        availableRewards: 0
      }));

      nodeOwners.set(user, usersNodes[user].length);

      if(!distributing) distributeRewards();
    }

    function _buyNode(address user, string memory name, uint256 nodeTypeId) external onlyOwner {
      NodeType storage nodeType = _nodeTypes[nodeTypeId];
      require(!nodeType.disabled, "Cannot buy a disabled node");
      require(nodeType.buyable, "Cannot buy a non-buyable node");

      _createNode(user, name, nodeTypeId);
    }

    function distributeRewards() private returns (uint256, uint256) {
      distributing = true;
      require(_totalCreatedNodes > 0, "No nodes to distribute");

      uint256 ownersCount = nodeOwners.keys.length;
      uint256 gasUsed = 0;
      uint256 gasLeft = gasleft();
      uint256 newGasLeft;
      uint256 iterations = 0;
      uint256 claims = 0;

      Node[] storage nodes;
      Node storage _node;
      NodeType storage _nodeType;

      while (gasUsed < _gasForProcessing && iterations < ownersCount) {
        if (_lastProcessedIndex >= nodeOwners.keys.length) _lastProcessedIndex = 0;

        nodes = usersNodes[nodeOwners.keys[_lastProcessedIndex]];
        for (uint256 i = 0; i < nodes.length; i++) {
          _node = nodes[i];
          _nodeType = _nodeTypes[_node.nodeType];

          // If we can process a claim, if is not a disabled node and not in upgrade
          if (canClaim(_node) && !_nodeType.disabled && !_node.upgrading) {
            _node.availableRewards += _nodeType.rewards;
            _node.lastClaimTimestamp = block.timestamp;
            _totalEarn += _nodeType.rewards;
            claims++;
          }
        }

        newGasLeft = gasleft();
        if (gasLeft > newGasLeft) gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
        gasLeft = newGasLeft;

        iterations++;

        _lastProcessedIndex++;
      }

      distributing = false;
      return (iterations, claims);
    }

    function _cashoutNode(address user, uint256 id) external onlyOwner returns (uint256) {
      Node[] storage nodes = usersNodes[user];

      uint256 nodesCount = nodes.length;
      require(nodesCount > 0, "No nodes to cashout");

      (uint256 nodeIndex, bool finded) = getNodeIndexWithId(nodes, id);

      require(finded, "Cannot find the node");

      Node storage node = nodes[nodeIndex];
      uint256 rewards = node.availableRewards;
      node.availableRewards = 0;

      return rewards;
    }

    function _cashoutAllNodes(address user) external onlyOwner returns (uint256) {
      Node[] storage nodes = usersNodes[user];

      uint256 nodesCount = nodes.length;
      require(nodesCount > 0, "No nodes to cashout");

      Node storage _node;
      uint256 rewards = 0;

      for (uint256 i = 0; i < nodesCount; i++) {
        _node = nodes[i];
        rewards += _node.availableRewards;
        _node.availableRewards = 0;
      }

      return rewards;
    }

    function _upgradeNode(address user, uint256 id) external onlyOwner returns (bool) {
      Node[] storage nodes = usersNodes[user];

      uint256 nodesCount = nodes.length;
      require(nodesCount > 0, "No nodes to upgrade");

      (uint256 nodeIndex, bool finded) = getNodeIndexWithId(nodes, id);
      require(finded, "Cannot find the node");

      Node storage node = nodes[nodeIndex];
      require(!node.upgrading, "Already upgrading");

      NodeType storage nodeType = _nodeTypes[node.nodeType];
      require(nodeType.upgradable, "Cannot upgrade this Node");

      node.upgrading = true;
      node.ThomasUpgradeStartTimestamp = block.timestamp;

      return true;
    }

    function _upgradeAllNodes(address user) external onlyOwner returns (uint256) {
      Node[] storage nodes = usersNodes[user];

      uint256 nodesCount = nodes.length;
      require(nodesCount > 0, "No nodes to cashout");

      Node storage node;
      NodeType storage nodeType;
      uint256 count = 0;

      for (uint256 i = 0; i < nodes.length; i++) {
        node = nodes[i];
        nodeType = _nodeTypes[node.nodeType];

        if(!node.upgrading && nodeType.upgradable) {
          node.upgrading = true;
          node.ThomasUpgradeStartTimestamp = block.timestamp;
          count++;
        }
      }

      return count;
    }

    function _claimUpgrade(address user, uint256 id) external onlyOwner returns (bool) {
      Node[] storage nodes = usersNodes[user];

      uint256 nodesCount = nodes.length;
      require(nodesCount > 0, "No nodes to cashout");

      (uint256 nodeIndex, bool finded) = getNodeIndexWithId(nodes, id);
      require(finded, "Cannot find the node");

      Node storage node = nodes[nodeIndex];
      require(canClaimUpgrade(node), "Cannot claim the upgrade node");

      node.upgrading = false;
      node.ThomasUpgradeStartTimestamp = 0;
      node.nodeType = _nodeTypes[node.nodeType].typeUpgradeNode;

      return true;
    }

    function _getClaimableUpgrades(address user) external onlyOwner view returns (uint256[] memory) {
      require(_getNumberOfNodes(user) > 0, "Cannot claim any nodes");

      Node[] storage nodes = usersNodes[user];
      Node storage node;
      NodeType storage nodeType;
      uint256[] memory idsClaimable = new uint256[](nodes.length);

      for (uint256 i = 0; i < nodes.length; i++) {
        node = nodes[i];
        nodeType = _nodeTypes[node.nodeType];

        if(node.upgrading) {
          if(block.timestamp >= node.ThomasUpgradeStartTimestamp + nodeType.timeToUpgrade) {
            idsClaimable[idsClaimable.length] = node.id;
          }
        }
      }

      return idsClaimable;
    }

    // Utils
    function canClaim(Node memory node) private view returns (bool) {
      return block.timestamp >= node.lastClaimTimestamp + _claimingTimestamp;
    }

    function getNodeIndexWithId(Node[] storage nodes, uint256 id) private view returns (uint256, bool) {
      for (uint256 i = 0; i < nodes.length; i++) {
        if(nodes[i].id == id) return (i, true);
      }
      return (0, false);
    }

    function canClaimUpgrade(Node memory node) private view returns (bool) {
      NodeType storage nodeType = _nodeTypes[node.nodeType];

      return node.upgrading && block.timestamp >= node.ThomasUpgradeStartTimestamp + nodeType.timeToUpgrade;
    }

    function getNumberOfSpecifiedMinNodes(address user, uint256 nodeTypeId) private view returns (uint256) {
      Node[] storage nodes = usersNodes[user];
      Node storage node;
      uint256 count = 0;

      for (uint256 i = 0; i < nodes.length; i++) {
        node = nodes[i];
        if(node.nodeType >= nodeTypeId && !_nodeTypes[node.nodeType].bonus) count++;
      }

      return count;
    }

    function _processDistribution() external onlyOwner {
      distributeRewards();
    }

    // Getters
    function _getClaimingTimestamp() external view returns (uint256) {
      return _claimingTimestamp;
    }

    function _getMaxNodes() external view returns (uint256) {
      return _maxNodes;
    }

    function _getTotalEarned() external view returns (uint256) {
      return _totalEarn;
    }

    function _getTotalCreatedNodes() external view returns (uint256) {
      return _totalCreatedNodes;
    }

    function _getNumberOfNodes(address user) private view returns (uint256) {
      Node[] storage nodes = usersNodes[user];
      uint256 count = 0;

      for (uint256 i = 0; i < nodes.length; i++) {
        if(!_nodeTypes[nodes[i].nodeType].bonus) count++;
      }

      return count;
    }

    function _isNodeOwner(address user) private view returns (bool) {
      return usersNodes[user].length > 0;
    }

    function _getPriceOfNode(uint256 nodeTypeId) public view returns (uint256) {
      require(nodeTypeId < _nodeTypes.length && nodeTypeId >= 0, "Not valid id of a type of Node");

      return _nodeTypes[nodeTypeId].price;
    }

    function _getNodes(address user) external onlyOwner view returns (Node[] memory) {
      return usersNodes[user];
    }

    function _getNodeTypes() external onlyOwner view returns (NodeType[] memory) {
      return _nodeTypes;
    }

    function _getBoosterDatas(address user) external onlyOwner view returns (BoosterData memory) {
      require(boosterDatas[user].boosterCodeSetup, "Booster code not setup yet");
      return boosterDatas[user];
    }

    function _setMinimumNodeUseRef(uint256 nodeId) external onlyOwner {
      _minimumNodeUseRef = nodeId;
    }

    function _setMinimumNodeSetRef(uint256 nodeId) external onlyOwner {
      _minimumNodeSetRef = nodeId;
    }

    function _setMaxAmountPerNode(uint256 amount) external onlyOwner {
      _maxAmountPerNode = amount;
    }

    // Setters
    function _updateGasForProcessing(uint256 amount) external onlyOwner {
      require(amount >= 200000 && amount <= 500000, "gasForProcessing must be between 200,000 and 500,000");
      require(amount != _gasForProcessing, "Cannot update gasForProcessing to same value");

      emit GasForProcessingUpdated(amount, _gasForProcessing);

      _gasForProcessing = amount;
    }

    function _setClaimingTimestamp(uint256 amount) external onlyOwner {
      _claimingTimestamp = amount;
    }

    function _setMaxNodes(uint256 amount) external onlyOwner {
      _maxNodes = amount;
    }

    function _editNodeType(uint256 nodeTypeId, uint256 rewards, uint256 timeToUpgrade, uint256 typeUpgradeNode,
                           uint256 price, bool buyable, bool upgradable, bool bonus) external onlyOwner {
      require(nodeTypeId < _nodeTypes.length && nodeTypeId >= 0, "Not valid id of a type of Node");

      NodeType storage nodeType = _nodeTypes[nodeTypeId];

      nodeType.rewards = rewards;
      nodeType.timeToUpgrade = timeToUpgrade;
      nodeType.typeUpgradeNode = typeUpgradeNode;
      nodeType.price = price;
      nodeType.buyable = buyable;
      nodeType.upgradable = upgradable;
      nodeType.bonus = bonus;
    }

    function _addNodeType(uint256 rewards, uint256 timeToUpgrade, uint256 typeUpgradeNode,
                           uint256 price, bool buyable, bool upgradable, bool bonus) external onlyOwner {
      _nodeTypes.push(NodeType({
        rewards: rewards,
        timeToUpgrade: timeToUpgrade,
        typeUpgradeNode: typeUpgradeNode,
        price: price,
        buyable: buyable,
        upgradable: upgradable,
        disabled: false,
        bonus: bonus
      }));
    }

    function _disableNodeType(uint256 id) external onlyOwner {
      require(id < _nodeTypes.length && id >= 0, "Not valid id of a type of Node");

      _nodeTypes[id].disabled = true;
    }

    function _enableNodeType(uint256 id) external onlyOwner {
      require(id < _nodeTypes.length && id >= 0, "Not valid id of a type of Node");

      _nodeTypes[id].disabled = false;
    }

}
// File: tests/node_modules/openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
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
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
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
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }

        _transfer(sender, recipient, amount);

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

// File: tests/Thomas.sol



pragma solidity ^0.8.10;









contract Thomas is ERC20, Ownable {
    using SafeMath for uint256;

    ThomasNodeManager private nodeManager;

    // Global Informations
    uint8 private _decimals = 8;
    uint256 private _totalSupply = 10_000_000 * (10**8);

    // Fees
    uint256 public _futurUseSellFee = 15; // 15
    uint256 public _burnSellFee = 0; // 0
    uint256 public _futurUseNodeFee = 7; // 7
    uint256 public _liquidityPoolFee = 20; // 20
    uint256 public _distributionSwapFee = 3; // 3 | 3% of the 73% from rewardsNodeFee

    uint256 public _boosterChildAmount = 3;

    // Pools & Wallets
    address public _futurUsePool = 0x217F31064C4c8D51E59AA2EB4Fb7316ec7062cc6;
    address public _distributionPool = 0xF0Cb267F0450f0A9193fa398F6eD32fD9F179ad0;
    address public _deadWallet = 0x000000000000000000000000000000000000dEaD;

    // Pancakeswap V2
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    bool private swapping = false;
    uint256 public swapTokensAtAmount = 300 * (10**8);

    // Security
    mapping(address => bool) public _isBlacklisted;
    mapping (address => bool) private _isExcludedFromFees;

    // Events
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);

    constructor() ERC20("Thomas Nodes", "Thomas") {
        nodeManager = new ThomasNodeManager();

        uniswapV2Router = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());

        // Exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(_futurUsePool, true);
        excludeFromFees(_distributionPool, true);
        excludeFromFees(address(this), true);

        _mint(owner(), _totalSupply);
    }

    function decimals() public view virtual override returns (uint8) {
      return _decimals;
    }

    receive() external payable {}

    function buyNode(string memory name, uint256 nodeType) external  {
      address sender = safeSender();

      require(bytes(name).length >= 3 && bytes(name).length <= 32,
        "Name size must be between 3 and 32 length");

      uint256 price = nodeManager._getPriceOfNode(nodeType);
      require(balanceOf(sender) >= price,
        "You have not the balance to buy this node");

      uint256 contractThomasBalance = balanceOf(address(this));
      bool canProcess = contractThomasBalance >= swapTokensAtAmount;

      if (canProcess && !swapping) {
          swapping = true;

          // FuturUse
          if(_futurUseNodeFee > 0) {
            uint256 futurUseTokens = contractThomasBalance.mul(_futurUseNodeFee).div(100);
            swapAndSendToFee(_futurUsePool, futurUseTokens);
          }

          // Liquidity
          if(_liquidityPoolFee > 0) {
            uint256 swapTokens = contractThomasBalance.mul(_liquidityPoolFee).div(100);
            swapAndLiquify(swapTokens);
          }

          // Distribution
          if(_distributionSwapFee > 0) {
            uint256 distributionTokensToSwap = balanceOf(address(this)).mul(_distributionSwapFee).div(100);
            swapAndSendToFee(_distributionPool, distributionTokensToSwap);
          }

          super._transfer(address(this), _distributionPool, balanceOf(address(this)));

          swapping = false;
      }

      super._transfer(sender, address(this), price);

      nodeManager._buyNode(msg.sender, name, nodeType);
    }

    function _transfer(address from, address to, uint256 amount) internal override {
      require(from != address(0), "Transfer from the zero address");
      require(to != address(0), "Transfer to the zero address");
      require(from != _deadWallet, "Transfer from the dead wallet address");
      require(!_isBlacklisted[from] && !_isBlacklisted[to], 'Blacklisted address');

      if(amount == 0) {
        super._transfer(from, to, 0);
        return;
      }

      // If any account is inside _isExcludedFromFee then don't take the fee
      bool takeFee = !(_isExcludedFromFees[from] || _isExcludedFromFees[to]);

      // Fees on sell
      if(takeFee && to == uniswapV2Pair) {
        uint256 futurFees = amount.mul(_futurUseSellFee).div(100);
        super._transfer(from, _futurUsePool, futurFees);

        uint256 burnFees = amount.mul(_burnSellFee).div(100);
        super._transfer(from, _deadWallet, burnFees);

        amount = amount.sub(futurFees).sub(burnFees);
      }

      super._transfer(from, to, amount);
    }

    /*
     * Wrapper
     */
    function cashoutNode(uint256 id) external {
      address sender = safeSender();
      uint256 rewards = nodeManager._cashoutNode(sender, id);
      super._transfer(_distributionPool, sender, rewards);
    }

    function cashoutAllNodes() external {
      address sender = safeSender();
      uint256 rewards = nodeManager._cashoutAllNodes(sender);
      super._transfer(_distributionPool, sender, rewards);
    }

    function upgradeNode(uint256 id) external returns (bool) {
      address sender = safeSender();
      return nodeManager._upgradeNode(sender, id);
    }

    function upgradeAllNodes() external returns (uint256) {
      address sender = safeSender();
      return nodeManager._upgradeAllNodes(sender);
    }

    function claimUpgrade(uint256 id) external returns (bool) {
      address sender = safeSender();
      return nodeManager._claimUpgrade(sender, id);
    }

    function setSwapTokensAtAmount(uint256 amount) external onlyOwner {
      swapTokensAtAmount = amount;
    }

    function giveNode(address[] memory users, string memory name, uint256 nodeType) external onlyOwner {
      for (uint256 i = 0; i < users.length; i++)
        nodeManager._createNode(users[i], name, nodeType);
    }

    function getPriceOfNode(uint256 nodeTypeId) external view returns (uint256) {
      return nodeManager._getPriceOfNode(nodeTypeId);
    }

    function setBoosterCode(string memory code) external {
      address sender = safeSender();
      nodeManager._setBoosterCode(sender, code);
    }

    function useBoosterCode(string memory code) external {
      address sender = safeSender();
      nodeManager._useBoosterCode(sender, code);
      super._transfer(_distributionPool, sender, _boosterChildAmount);
    }

    function getClaimableUpgrades(address user) external view returns (uint256[] memory) {
      return nodeManager._getClaimableUpgrades(user);
    }

    function updateGasForProcessing(uint256 newValue) external onlyOwner {
        nodeManager._updateGasForProcessing(newValue);
    }

    function updateClaimingTimestamp(uint256 newValue) external onlyOwner {
        nodeManager._setClaimingTimestamp(newValue);
    }

    function updateMaxNodes(uint256 newValue) external onlyOwner {
        nodeManager._setMaxNodes(newValue);
    }

    function getClaimingTimestamp() external view returns (uint256) {
        return nodeManager._getClaimingTimestamp();
    }

    function getMaxNodes() external view returns (uint256) {
        return nodeManager._getMaxNodes();
    }

    function getTotalEarned() external view returns (uint256) {
        return nodeManager._getTotalEarned();
    }

    function setMinimumNodeUseRef(uint256 nodeId) external onlyOwner {
      return nodeManager._setMinimumNodeUseRef(nodeId);
    }

    function setMinimumNodeSetRef(uint256 nodeId) external onlyOwner {
      return nodeManager._setMinimumNodeSetRef(nodeId);
    }

    function setMaxAmountPerNode(uint256 amount) external onlyOwner {
      return nodeManager._setMaxAmountPerNode(amount);
    }

    function getTotalCreatedNodes() external view returns (uint256) {
        return nodeManager._getTotalCreatedNodes();
    }

    function getNodes(address user) external view returns (ThomasNodeManager.Node[] memory) {
      return nodeManager._getNodes(user);
    }

    function getNodeTypes() external onlyOwner view returns (ThomasNodeManager.NodeType[] memory) {
      return nodeManager._getNodeTypes();
    }

    function getBoosterDatas(address user) external view returns (ThomasNodeManager.BoosterData memory) {
      return nodeManager._getBoosterDatas(user);
    }

    function editNodeType(uint256 nodeTypeId, uint256 rewards, uint256 timeToUpgrade, uint256 typeUpgradeNode,
                           uint256 price, bool buyable, bool upgradable, bool bonus) external onlyOwner {
      nodeManager._editNodeType(nodeTypeId, rewards, timeToUpgrade, typeUpgradeNode, price, buyable, upgradable, bonus);
    }

    function addNodeType(uint256 rewards, uint256 timeToUpgrade, uint256 typeUpgradeNode,
                           uint256 price, bool buyable, bool upgradable, bool bonus) external onlyOwner {
      nodeManager._addNodeType(rewards, timeToUpgrade, typeUpgradeNode, price, buyable, upgradable, bonus);
    }

    function disableNodeType(uint256 id) external onlyOwner {
      nodeManager._disableNodeType(id);
    }

    function enableNodeType(uint256 id) external onlyOwner {
      nodeManager._enableNodeType(id);
    }

    function processDistribution() external onlyOwner {
      nodeManager._processDistribution();
    }

    /*
     * Utils
     */
    function safeSender() private view returns (address) {
      address sender = _msgSender();

      require(sender != address(0), "Cannot cashout from the zero address");
      require(!_isBlacklisted[sender], "Blacklisted address");

      return sender;
    }

    function swapTokensForEth(uint256 tokenAmount) private {
      address[] memory path = new address[](2);
      path[0] = address(this);
      path[1] = uniswapV2Router.WETH();

      _approve(address(this), address(uniswapV2Router), tokenAmount);

      uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
        tokenAmount,
        0,
        path,
        address(this),
        block.timestamp
      );
    }

    function swapAndSendToFee(address destination, uint256 tokens) private {
      uint256 initialETHBalance = address(this).balance;

      swapTokensForEth(tokens);
      uint256 newBalance = (address(this).balance).sub(initialETHBalance);

      payable(destination).transfer(newBalance);
    }

    function swapAndLiquify(uint256 tokens) private {
      uint256 half = tokens.div(2);
      uint256 otherHalf = tokens.sub(half);

      uint256 initialBalance = address(this).balance;

      // Swaping the half
      swapTokensForEth(half);
      uint256 newBalance = address(this).balance.sub(initialBalance);

      // Approving and adding liquidity
      _approve(address(this), address(uniswapV2Router), tokens);
      uniswapV2Router.addLiquidityETH{value: newBalance}(
        address(this),
        tokens,
        0,
        0,
        address(0),
        block.timestamp
      );

      emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function setFuturUsePool(address payable wallet) external onlyOwner {
       _futurUsePool = wallet;
    }

    function setDistributionPool(address payable wallet) external onlyOwner {
       _distributionPool = wallet;
    }

    function blacklistAddress(address account, bool value) external onlyOwner {
      _isBlacklisted[account] = value;
    }

    function setFuturUseSellFee(uint256 value) external onlyOwner {
      _futurUseSellFee = value;
    }

    function setBurnSellFee(uint256 value) external onlyOwner {
      _burnSellFee = value;
    }

    function setFuturUseNodeFee(uint256 value) external onlyOwner {
      _futurUseNodeFee = value;
    }

    function setLiquidityPoolFee(uint256 value) external onlyOwner {
      _liquidityPoolFee = value;
    }

    function setDistributionSwapFee(uint256 value) external onlyOwner {
      _distributionSwapFee = value;
    }

    function setPairAddress(address pair) external onlyOwner {
        uniswapV2Pair = pair;
    }

    function setBoosterChildAmount(uint256 value) external onlyOwner {
      _boosterChildAmount = value;
    }

    function updateUniswapV2Router(address newAddress) external onlyOwner {
        require(newAddress != address(uniswapV2Router), "The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));

        uniswapV2Router = IUniswapV2Router02(newAddress);

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function isExcludedFromFees(address account) public view returns(bool) {
      return _isExcludedFromFees[account];
    }

}