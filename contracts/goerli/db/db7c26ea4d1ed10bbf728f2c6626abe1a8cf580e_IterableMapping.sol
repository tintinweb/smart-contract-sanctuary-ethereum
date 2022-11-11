/**
 *Submitted for verification at Etherscan.io on 2022-11-11
*/

/**
 *Submitted for verification at FtmScan.com on 2022-03-30
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;


/// @title Dividend-Paying Token Optional Interface
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev OPTIONAL functions for a dividend-paying token contract.
interface DividendPayingTokenOptionalInterface {
  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(address _owner) external view returns(uint256);

  /// @notice View the amount of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner) external view returns(uint256);

  /// @notice View the amount of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(address _owner) external view returns(uint256);
}
// File: contracts/interfaces/DividendPayingTokenInterface.sol



pragma solidity >=0.8.0;


/// @title Dividend-Paying Token Interface
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev An interface for a dividend-paying token contract.
interface DividendPayingTokenInterface {
  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function dividendOf(address _owner) external view returns(uint256);

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev SHOULD transfer `dividendOf(msg.sender)` wei to `msg.sender`, and `dividendOf(msg.sender)` SHOULD be 0 after the transfer.
  ///  MUST emit a `DividendWithdrawn` event if the amount of ether transferred is greater than 0.
  function withdrawDividend() external;

  /// @dev This event MUST emit when ether is distributed to token holders.
  /// @param from The address which sends ether to this contract.
  /// @param weiAmount The amount of distributed ether in wei.
  event DividendsDistributed(
    address indexed from,
    uint256 weiAmount
  );

  /// @dev This event MUST emit when an address withdraws their dividend.
  /// @param to The address which withdraws ether from this contract.
  /// @param weiAmount The amount of withdrawn ether in wei.
  event DividendWithdrawn(
    address indexed to,
    uint256 weiAmount
  );
}
// File: contracts/libraries/SafeMathUint.sol



pragma solidity >= 0.6.2;

/**
 * @title SafeMathUint
 * @dev Math operations with safety checks that revert on error
 */
library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}
// File: contracts/libraries/SafeMathInt.sol



/*
MIT License

Copyright (c) 2018 requestnetwork
Copyright (c) 2018 Fragments, Inc.

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
*/

pragma solidity >=0.6.2;

/**
 * @title SafeMathInt
 * @dev Math operations for int256 with overflow safety checks.
 */
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }


    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}
// File: contracts/libraries/IterableMapping.sol



pragma solidity ^0.8.0;


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
// File: contracts/libraries/SafeMath.sol



pragma solidity >=0.5.16;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}
// File: contracts/libraries/Address.sol



pragma solidity >=0.6.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an FTM balance of at least `value`.
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
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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
// File: contracts/interfaces/IBloqBallRouter01.sol



pragma solidity >= 0.6.0;

interface IBloqBallRouter01 {
    function factory() external pure returns (address);
    function WFTM() external pure returns (address);

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
    function addLiquidityFTM(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountFTMMin,
        address to,
        uint deadline
    ) external  payable returns (uint amountToken, uint amountFTM, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityFTM(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountFTMMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountFTM);
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
    function removeLiquidityFTMWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountFTMMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountFTM);
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
    function swapExactFTMForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactFTM(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForFTM(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapFTMForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
// File: contracts/interfaces/IBloqBallRouter02.sol



pragma solidity >= 0.6.0;


interface IBloqBallRouter02 is IBloqBallRouter01 {
    function removeLiquidityFTMSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountFTMMin,
        address to,
        uint deadline
    ) external returns (uint amountFTM);
    function removeLiquidityFTMWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountFTMMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountFTM);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactFTMForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForFTMSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
// File: contracts/interfaces/IBloqBallFactory.sol



pragma solidity >= 0.5.16;

interface IBloqBallFactory {
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
// File: contracts/interfaces/IERC20.sol



pragma solidity >= 0.5.16;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/interfaces/IERC20Metadata.sol



pragma solidity >=0.6.12;


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

// File: contracts/utils/SafeERC20.sol



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

// File: contracts/interfaces/IBloqBallReferral.sol



pragma solidity ^0.8.0;

interface IBloqBallReferral {
    /**
     * @dev Record referral.
     */
    function recordReferral(address user, address referrer) external;

    /**
     * @dev Record referral commission.
     */
    function recordReferralCommission(address referrer, uint256 commission) external;

    /**
     * @dev Get the referrer address that referred the user.
     */
    function getReferrer(address user) external view returns (address);
}
// File: contracts/security/ReentrancyGuard.sol



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
     * by making the `nonReentrant` function external, and make it call a
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

// File: contracts/utils/Context.sol



pragma solidity >=0.6.0;

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

    function _msgData() internal pure virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: contracts/interfaces/ERC20.sol



pragma solidity >=0.6.0;





/**
 * @dev Implementation of the `IERC20` interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using `_mint`.
 * For a generic mechanism see `ERC20Mintable`.
 *
 * *For a detailed writeup see our guide [How to implement supply
 * mechanisms](https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226).*
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an `Approval` event is emitted on calls to `transferFrom`.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard `decreaseAllowance` and `increaseAllowance`
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See `IERC20.approve`.
 */
 
contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
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

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
     * will be to transferred to `to`.
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
}
// File: contracts/access/Ownable.sol



pragma solidity >=0.6.0;


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

// File: contracts/interfaces/DividendPayingToken.sol



pragma solidity >=0.8.0;









/// @title Dividend-Paying Token
/// @dev A mintable ERC20 token that allows anyone to pay and distribute ether
///  to token holders as dividends and allows token holders to withdraw their dividends.
contract DividendPayingToken is ERC20, Ownable, DividendPayingTokenInterface, DividendPayingTokenOptionalInterface {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;

  // With `magnitude`, we can properly distribute dividends even if the amount of received ether is small.
  // For more discussion about choosing the value of `magnitude`,
  //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
  uint256 constant internal magnitude = 2**128;

  uint256 internal magnifiedDividendPerShare;

  mapping(address => int256) internal magnifiedDividendCorrections;
  mapping(address => uint256) internal withdrawnDividends;

  uint256 public totalDividendsDistributed;
  uint256 public lockedUp;

  constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
  }

  function decimals() public view virtual override returns (uint8) {
    return 18;
  }

  function distributeDividends(uint256 amount) public onlyOwner{
    // require(totalSupply() > 0);
    if (totalSupply() == 0) {
        lockedUp = lockedUp.add(amount);
        return;
    }

    if (amount > 0) {
        if (lockedUp > 0) {
            amount = amount.add(lockedUp);
            lockedUp = 0;
        }
        magnifiedDividendPerShare = magnifiedDividendPerShare.add(
        (amount).mul(magnitude) / totalSupply()
        );
        emit DividendsDistributed(msg.sender, amount);

        totalDividendsDistributed = totalDividendsDistributed.add(amount);
    }
  }

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
  function withdrawDividend() public virtual override {
    _withdrawDividendOfUser(payable(msg.sender), true);
  }

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
 function _withdrawDividendOfUser(address payable user, bool transferCake) internal returns (uint256) {
    uint256 _withdrawableDividend = withdrawableDividendOf(user);
    if (_withdrawableDividend > 0) {
      withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
      emit DividendWithdrawn(user, _withdrawableDividend);

      if (transferCake) {
          (bool success,) = address(user).call{value: _withdrawableDividend}("");

          if(!success) {
            withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
            return 0;
          }
      }

      return _withdrawableDividend;
    }

    return 0;
  }

  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function dividendOf(address _owner) public view override returns(uint256) {
    return withdrawableDividendOf(_owner);
  }

  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(address _owner) public view override returns(uint256) {
    return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
  }

  /// @notice View the amount of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner) public view override returns(uint256) {
    return withdrawnDividends[_owner];
  }


  /// @notice View the amount of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(address _owner) public view override returns(uint256) {
    return magnifiedDividendPerShare.mul(balanceOf(_owner)).toInt256Safe()
      .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
  }

  /// @dev Internal function that transfer tokens from one address to another.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param from The address to transfer from.
  /// @param to The address to transfer to.
  /// @param value The amount to be transferred.
  function _transfer(address from, address to, uint256 value) internal virtual override {
    require(false);

    int256 _magCorrection = magnifiedDividendPerShare.mul(value).toInt256Safe();
    magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from].add(_magCorrection);
    magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(_magCorrection);
  }

  /// @dev Internal function that mints tokens to an account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param account The account that will receive the created tokens.
  /// @param value The amount that will be created.
  function _mint(address account, uint256 value) internal override {
    super._mint(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .sub( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  /// @dev Internal function that burns an amount of the token of a given account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param account The account whose tokens will be burnt.
  /// @param value The amount that will be burnt.
  function _burn(address account, uint256 value) internal override {
    super._burn(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .add( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  function _setBalance(address account, uint256 newBalance) internal {
    uint256 currentBalance = balanceOf(account);

    if(newBalance > currentBalance) {
      uint256 mintAmount = newBalance.sub(currentBalance);
      _mint(account, mintAmount);
    } else if(newBalance < currentBalance) {
      uint256 burnAmount = currentBalance.sub(newBalance);
      _burn(account, burnAmount);
    }
  }
}
// File: contracts/BloqBallStakingDividendTracker.sol



pragma solidity ^0.8.0;





contract BloqBallStakingDividendTracker is Ownable, DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;

    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() DividendPayingToken("BloqBall_Staking_Dividend_Tracker", "BQBDT") {
        claimWait = 1 hours;
        minimumTokenBalanceForDividends = 1000 * (10**18);
    }

    function setMinimumTokenBalanceForDividends(uint256 _minimumTokenBalanceForDividends) 
        public onlyOwner {
        minimumTokenBalanceForDividends = _minimumTokenBalanceForDividends;
    }

    receive() external payable {
    }

    function _transfer(address, address, uint256) internal pure override {
        require(false, "Diamond_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public pure override {
        require(false, "Diamond_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main MMR contract.");
    }

    function excludeFromDividends(address account) external onlyOwner {
        require(!excludedFromDividends[account]);
        excludedFromDividends[account] = true;

        _setBalance(account, 0);
        tokenHoldersMap.remove(account);

        emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "Diamond_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "Diamond_Dividend_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function getLastProcessedIndex() external view returns(uint256) {
        return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }

    function getAccount(address _account)
        public view returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable) {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if(index >= 0) {
            if(uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                                                        tokenHoldersMap.keys.length.sub(lastProcessedIndex) :
                                                        0;

                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }

        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];

        nextClaimTime = lastClaimTime > 0 ?
                                    lastClaimTime.add(claimWait) :
                                    0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                                                    nextClaimTime.sub(block.timestamp) :
                                                    0;
    }

    function getAccountAtIndex(uint256 index)
        public view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        if(index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccount(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
        if(lastClaimTime > block.timestamp)  {
            return false;
        }

        return block.timestamp.sub(lastClaimTime) >= claimWait;
    }

    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
        if(_isContract(account)) {
            return;
        }

        if(excludedFromDividends[account]) {
            return;
        }

        if(newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
            tokenHoldersMap.set(account, newBalance);
        }
        else {
            _setBalance(account, 0);
            tokenHoldersMap.remove(account);
        }
    }

    function process() public pure returns (uint256, uint256, uint256) {

        return (0, 0, 0);
/*
        uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

        if(numberOfTokenHolders == 0) {
            return (0, 0, lastProcessedIndex);
        }

        uint256 _lastProcessedIndex = lastProcessedIndex;

        uint256 gasUsed = 0;

        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        uint256 claims = 0;

        while(gasUsed < gas && iterations < numberOfTokenHolders) {
            _lastProcessedIndex++;

            if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
                _lastProcessedIndex = 0;
            }

            address account = tokenHoldersMap.keys[_lastProcessedIndex];

            if(canAutoClaim(lastClaimTimes[account])) {
                if(processAccount(payable(account), true)) {
                    claims++;
                }
            }

            iterations++;

            uint256 newGasLeft = gasleft();

            if(gasLeft > newGasLeft) {
                gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
            }

            gasLeft = newGasLeft;
        }

        lastProcessedIndex = _lastProcessedIndex;

        return (iterations, claims, lastProcessedIndex);*/
    }

    function processAccount(address payable account, bool automatic, bool transferRewards) 
        public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account, transferRewards);

        if(amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
            return true;
        }

        return false;
    }
}
// File: contracts/Masterchef.sol



pragma solidity ^0.8.0;












interface BloqBall {
    function mint(address _to, uint256 _amount) external;
    function transferTaxRate() external returns (uint256);
    function transferOwnership(address newOwner) external;
}

// MasterChef is the master of BQB. He can make BQB and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once BQB is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // The operator
    address private _operator;

    BloqBallStakingDividendTracker public dividendTracker;

   // Info of each Deposit.
    struct DepositInfo {
        uint256 pid;
        uint256 amount;
        uint256 lockupPeriod;
        uint256 nextWithdraw;
        uint256 accBloqBallPerShare;
        uint256 taxAmount;
    }

    mapping (address=> mapping(uint256=>DepositInfo[])) public depositInfo;

    // Info of each user.
    struct UserInfo {
        uint256 amount;             // How many LP tokens the user has provided.
        uint256 nextHarvestUntil;   // When can the user harvest again.
        uint256 totalEarnedBQB;
        uint256 taxAmount;
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. BQBs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that BQBs distribution occurs.
        uint256 accBloqBallPerShare;   // Accumulated BQBs per share, times 1e12. See below.
        uint16 depositFeeBP;      // Deposit fee in basis points
        uint256 harvestInterval;  // Harvest interval in seconds
        uint256 totalStakedTokens;  // total count of staked tokens
    }
    
    // The BQB TOKEN!
    address public bloqball;

    // The count of BQB transfered from reward fees.
    uint256 private totalAmountFromFeeByRewards = 0;

    // Deposit Fee address
    address public feeAddress;

    // BQB tokens created per block.
    uint256 public BQBPerBlock = 1 * 10**18;
    uint256 public initialBQBPerBlock = 10 * 10 ** 18;          // 10 BQB until first 10 days

    // Bonus muliplier for early BQB makers.
    uint256 public constant BONUS_MULTIPLIER = 1;

    // First day and default harvest interval
    uint256 public constant DEFAULT_HARVEST_INTERVAL = 1 minutes;
    uint256 public constant MAX_HARVEST_INTERVAL = 15 minutes;  //1 days;
    uint256 public lockUpTaxRate = 5000;                        // 50%

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    // BQB referral contract address.
    IBloqBallReferral public BloqBallReferral;
    
    // Referral commission rate in basis points.
    uint16 public referralCommissionRate = 100;
    
    // Max referral commission rate: 10%.
    uint16 public constant MAXIMUM_REFERRAL_COMMISSION_RATE = 1000;
    
    // The block number and timestamp when BQB mining starts.
    bool public enableStartBQBReward = false;
    uint256 public startBlock;

    mapping(uint8 => bool) public enableStaking;

    // Informations to get daily FTM reward for calculating APR of FTM rewards in staking BQB
    struct FTMRewardInfo {
        uint256 timestamp;
        uint256 totalAmountFromFee;
    }
    mapping(uint256 => FTMRewardInfo) public ftmRewardInfoAtId;
    uint public currentFTMRewardID;
    
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmissionRateUpdated(address indexed caller, uint256 previousAmount, uint256 newAmount);
    event ReferralCommissionPaid(address indexed user, address indexed referrer, uint256 commissionAmount);
    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);
    event SendDividends(uint256 tokensamount);
    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );

    modifier onlyOperator() {
        require(_operator == msg.sender, "operator: caller is not the operator");
        _;
    }

    constructor (address _bloqball) {
        dividendTracker = new BloqBallStakingDividendTracker();
        
        bloqball = _bloqball;

        feeAddress = msg.sender;
        _operator = _bloqball;
    }

    receive() external payable {
    }

    function setEnableStaking(uint8 _pid, bool _bEnable) external onlyOwner {
        enableStaking[_pid] = _bEnable;
    }

    // set to start the BQB rewards per block
    function setStartBQBReward() public onlyOwner {
        enableStartBQBReward = true;
        
        startBlock = block.number;
        uint256 length = poolInfo.length;
        
        for (uint256 pid = 0; pid < length; ++pid) {
            poolInfo[pid].lastRewardBlock = 
                block.number > poolInfo[pid].lastRewardBlock ? block.number : poolInfo[pid].lastRewardBlock;
        }
    }

    /**
     * @dev Set operator of the contract to a new account (`newOperator`).
     * Can only be called by the current operator.
     */
    function setOperator(address newOperator) public onlyOwner {
        require(newOperator != address(0), "BloqBall::transferOperator: new operator is the zero address");
        emit OperatorTransferred(_operator, newOperator);

        _operator = newOperator;
    }
    
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IERC20 _lpToken, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= 10000, "add: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accBloqBallPerShare: 0,
            depositFeeBP: _depositFeeBP,
            harvestInterval: DEFAULT_HARVEST_INTERVAL,
            totalStakedTokens:0
        }));
    }

    // Update the given pool's BQB allocation point and deposit fee. Can only be called by the owner.
    function set(uint8 _pid, uint256 _allocPoint, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= 10000, "set: invalid deposit fee basis points");
        
        if (_withUpdate) {
            massUpdatePools();
        }

        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
        poolInfo[_pid].harvestInterval = DEFAULT_HARVEST_INTERVAL;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }
    
    // Return total reward multiplier over the given _from to _to block.
    function getTotalBQBRewardFromBlock() public view returns (uint256) {
        if (!enableStartBQBReward) {
            return 0;
        }
            
        uint256 multiplier;
        uint256 bloqBallReward;

        uint256 midBlock = startBlock + 10 days;           // 10 days from start day

        if (midBlock < block.number) {
            multiplier = getMultiplier(startBlock, midBlock);
            bloqBallReward = multiplier.mul(initialBQBPerBlock);
            
            multiplier = getMultiplier(midBlock, block.number);
            bloqBallReward.add(multiplier.mul(BQBPerBlock));
        }
        else {
            multiplier = getMultiplier(startBlock, block.number);
            bloqBallReward = multiplier.mul(initialBQBPerBlock);
        }
        
        return bloqBallReward;
    }
    
    // Return reward multiplier over the given _from to _to block.
    function getBQBRewardFromBlock(uint8 _pid) public view returns (uint256) {
        if (!enableStartBQBReward) {
            return 0;
        }
            
        PoolInfo storage pool = poolInfo[_pid];    
            
        uint256 multiplier;
        uint256 bloqBallReward = 0;
        
        uint256 midBlock = startBlock + 10 days;                // 10 days from start day
        if (pool.lastRewardBlock > midBlock) {
            multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            bloqBallReward = multiplier.mul(BQBPerBlock);
        }
        else {
            if (midBlock < block.number) {
                multiplier = getMultiplier(pool.lastRewardBlock, midBlock);
                bloqBallReward = multiplier.mul(initialBQBPerBlock);
                
                multiplier = getMultiplier(midBlock, block.number);
                bloqBallReward.add(multiplier.mul(BQBPerBlock));
            }
            else {
                multiplier = getMultiplier(pool.lastRewardBlock, block.number);
                bloqBallReward = multiplier.mul(initialBQBPerBlock);
            }
        }
        
        return bloqBallReward;
    }

    // View function to see pending BQBs on frontend.
    function pendingBloqBall(uint8 _pid, address _user) 
        external view returns (uint256 totalPending, uint256 claimablePending) {
        PoolInfo storage pool = poolInfo[_pid];

        uint256 accBloqBallPerShare = pool.accBloqBallPerShare;
        uint256 lpSupply = pool.totalStakedTokens; //pool.lpToken.balanceOf(address(this));

        if (lpSupply == 0) {
            return (0, 0);
        }

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 bloqBallReward = getBQBRewardFromBlock(_pid).mul(pool.allocPoint).div(totalAllocPoint);

            if (address(pool.lpToken) == bloqball) {
                bloqBallReward = bloqBallReward.add(totalAmountFromFeeByRewards);
            }

            accBloqBallPerShare = accBloqBallPerShare.add(bloqBallReward.mul(1e12).div(lpSupply));
        }

        (uint256 _totalPending, uint256 _claimablePending, ) = 
            availableRewardsForHarvest(_pid, _user, accBloqBallPerShare);

        totalPending = _totalPending;
        claimablePending = _claimablePending;
    }

    function pendingBloqBallForDeposit(uint8 _pid, address _user, uint256 _depositIndex) 
        public view returns (uint256 totalPending, uint256 claimablePending) {
        PoolInfo storage pool = poolInfo[_pid];

        uint256 accBloqBallPerShare = pool.accBloqBallPerShare;
        uint256 lpSupply = pool.totalStakedTokens; //pool.lpToken.balanceOf(address(this));

        if (lpSupply == 0) {
            return (0, 0);
        }

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 bloqBallReward = getBQBRewardFromBlock(_pid).mul(pool.allocPoint).div(totalAllocPoint);

            if (address(pool.lpToken) == bloqball) {
                bloqBallReward = bloqBallReward.add(totalAmountFromFeeByRewards);
            }

            accBloqBallPerShare = accBloqBallPerShare.add(bloqBallReward.mul(1e12).div(lpSupply));
        }

        (uint256 _totalPending, uint256 _claimablePending, ) = 
            availableIndividualRewardsForHarvest(_pid, _user, accBloqBallPerShare, _depositIndex);

        totalPending = _totalPending;
        claimablePending = _claimablePending;
    }

    function getEarnedTokenInfo(uint8 _pid, address _user) external view returns (uint256[] memory, uint256[] memory) {
        DepositInfo[] memory myDeposits =  depositInfo[_user][_pid];

        uint256[] memory totalPendingTokenInfo = new uint256[](myDeposits.length);
        uint256[] memory claimablePendingTokenInfo = new uint256[](myDeposits.length);

        for(uint256 i=0; i< myDeposits.length; i++) {
            (uint256 totalAmount, uint256 pendingAmount) = pendingBloqBallForDeposit(_pid, _user, i);
            totalPendingTokenInfo[i] = totalAmount;
            claimablePendingTokenInfo[i] = pendingAmount;
        }

        return (totalPendingTokenInfo, claimablePendingTokenInfo);
    }

    // View function to see if user can harvest BloqBalls.
    function canHarvest(uint8 _pid, address _user) public view returns (bool) {
        UserInfo storage user = userInfo[_pid][_user];
        return block.timestamp >= user.nextHarvestUntil;
    }
    
    // View function to see user's deposit info.
    function getDepositInfo(uint8 _pid, address _user) public view returns (DepositInfo[] memory) {
        return depositInfo[_user][_pid];
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint8 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint8 _pid) public {
        require(enableStaking[_pid] == true, 'Deposite: DISABLE DEPOSITING');

        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.totalStakedTokens; //pool.lpToken.balanceOf(address(this));

        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 bloqBallReward = getBQBRewardFromBlock(_pid).mul(pool.allocPoint).div(totalAllocPoint);
               
        BloqBall(bloqball).mint(address(this), bloqBallReward);
        
        if (address(pool.lpToken) == bloqball) {
            bloqBallReward = bloqBallReward.add(totalAmountFromFeeByRewards);
            totalAmountFromFeeByRewards = 0;
        }

        pool.accBloqBallPerShare = pool.accBloqBallPerShare.add(bloqBallReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for BQB allocation.
    function deposit(uint8 _pid, uint256 _amount, address _referrer) public nonReentrant {
        require(enableStaking[_pid] == true, 'Deposite: DISABLE DEPOSITING');
        require(_amount > 0, 'Deposite: DISABLE DEPOSITING');
        
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        updatePool(_pid);

        if (address(BloqBallReferral) != address(0) 
                && _referrer != address(0) 
                && _referrer != msg.sender) {
            BloqBallReferral.recordReferral(msg.sender, _referrer);
        }

        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);

        if (address(pool.lpToken) == bloqball) {
            uint256 transferTax = _amount.mul(BloqBall(bloqball).transferTaxRate()).div(10000);
            _amount = _amount.sub(transferTax);
        }

        pool.totalStakedTokens = pool.totalStakedTokens.add(_amount);

        if (pool.depositFeeBP > 0) {
            uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
            pool.lpToken.safeTransfer(feeAddress, depositFee);
            pool.totalStakedTokens -= depositFee;
            user.amount = user.amount.add(_amount).sub(depositFee);
        }
        else {
            user.amount = user.amount.add(_amount);
        }

        depositInfo[msg.sender][_pid].push(DepositInfo({
            pid: _pid,
            amount: _amount,
            lockupPeriod:MAX_HARVEST_INTERVAL,
            nextWithdraw: block.timestamp.add(MAX_HARVEST_INTERVAL),
            accBloqBallPerShare: pool.accBloqBallPerShare,
            taxAmount: 0
        }));

        if (user.nextHarvestUntil == 0) {
            user.nextHarvestUntil = block.timestamp.add(MAX_HARVEST_INTERVAL);
        }

        emit Deposit(msg.sender, _pid, _amount);
        
        if (address(pool.lpToken) == bloqball) {
            try dividendTracker.setBalance(payable(msg.sender), user.amount) {} catch {}
        }
    }

    // Harvest rewards.
    function harvest(uint8 _pid) public nonReentrant {
        require(enableStaking[_pid] == true, 'Deposite: DISABLE DEPOSITING');

        updatePool(_pid);
        payOrLockupPendingBQB(_pid);
    }

    function harvestForDeposit(uint8 _pid, uint256 _depositIndex) public nonReentrant {
        require(enableStaking[_pid] == true, 'Deposite: DISABLE DEPOSITING');

        updatePool(_pid);
        payOrLockupPendingBQB(_pid, _depositIndex);
    }

    function availableIndividualRewardsForHarvest (uint8 _pid, address _user, uint256 accPerShare, uint256 depositIndex) 
            public view returns (uint256 totalRewardAmount, uint256 rewardAmount, uint256 taxAmount) {
        uint256 rewardRate;
        uint256 rewardDebt;

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        DepositInfo memory myDeposit =  depositInfo[_user][_pid][depositIndex];

        if (address(pool.lpToken) == bloqball) {
            accPerShare = accPerShare.sub(user.taxAmount.mul(1e12).div(pool.totalStakedTokens));
        }

        rewardDebt =  myDeposit.amount.mul(myDeposit.accBloqBallPerShare).div(1e12);
        totalRewardAmount = myDeposit.amount.mul(accPerShare).div(1e12);

        if (rewardDebt > totalRewardAmount) {       // no rewards yet
            return (0, 0, 0);
        }

        totalRewardAmount = totalRewardAmount.sub(rewardDebt);

        if (myDeposit.nextWithdraw > block.timestamp) {
            return (totalRewardAmount, 0, 0);
        }

        rewardRate = calculateRewardRate(_pid, _user, depositIndex);     
        taxAmount = totalRewardAmount.mul(rewardRate).div(10000);
        rewardAmount = totalRewardAmount.sub(taxAmount);
    }

    function availableRewardsForHarvest(uint8 _pid, address _user, uint256 accPerShare) 
            public view returns (uint256 totalRewardAmount, uint256 rewardAmount, uint256 taxAmount) {
        uint256 totalRewards;
        uint256 rewardRate;
        uint256 rewardDebt;
        uint256 totalRewardDebt;

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        DepositInfo[] memory myDeposits =  depositInfo[_user][_pid];

        if (address(pool.lpToken) == bloqball) {
            accPerShare = accPerShare.sub(user.taxAmount.mul(1e12).div(pool.totalStakedTokens));
        }

        for(uint256 i=0; i< myDeposits.length; i++) {
            rewardDebt = (myDeposits[i].amount).mul(myDeposits[i].accBloqBallPerShare).div(1e12);
            totalRewardDebt = totalRewardDebt.add(rewardDebt);

            if (myDeposits[i].nextWithdraw > block.timestamp) {
                continue;
            }

            totalRewards = (myDeposits[i].amount).mul(accPerShare).div(1e12);
            totalRewards = totalRewards.sub(rewardDebt);          

            rewardRate = calculateRewardRate(_pid, _user, i);     
            taxAmount = taxAmount.add(totalRewards.mul(rewardRate).div(10000));
            rewardAmount = rewardAmount.add(totalRewards.sub(totalRewards.mul(rewardRate).div(10000)));
        }

        totalRewardAmount = user.amount.mul(accPerShare).div(1e12).sub(totalRewardDebt);
    }

    function updateDepositInfo(uint8 _pid, address _user) public {
        PoolInfo storage pool = poolInfo[_pid];
        DepositInfo[] memory myDeposits =  depositInfo[_user][_pid];

        for(uint256 i=0; i< myDeposits.length; i++) {
            if(myDeposits[i].nextWithdraw < block.timestamp) {
                depositInfo[_user][_pid][i].accBloqBallPerShare = pool.accBloqBallPerShare;
            }
        }
    }

    function updateDepositInfo(uint8 _pid, address _user, uint256 _depositIndex) public {
        PoolInfo storage pool = poolInfo[_pid];
        DepositInfo memory myDeposit =  depositInfo[_user][_pid][_depositIndex];

        if(myDeposit.nextWithdraw < block.timestamp) {
            depositInfo[_user][_pid][_depositIndex].accBloqBallPerShare = pool.accBloqBallPerShare;
        }
    }

    function getTaxInfo(uint8 _pid, address _user) external view returns (uint256[] memory) {
        DepositInfo[] memory myDeposits =  depositInfo[_user][_pid];

        uint256[] memory taxInfo = new uint256[](myDeposits.length);

        for(uint256 i=0; i< myDeposits.length; i++) {
            taxInfo[i] = calculateRewardRate(_pid, _user, i);
        }

        return taxInfo;
    }

    function calculateRewardRate(uint8 _pid, address _user, uint256 _depositIndex) 
            public view returns (uint256 rewardRate) {
        DepositInfo storage myDeposit =  depositInfo[_user][_pid][_depositIndex];

        if (block.timestamp < myDeposit.nextWithdraw)
            return lockUpTaxRate;

        uint256 elapsedTime = block.timestamp.sub(myDeposit.nextWithdraw);

        uint256 interval = elapsedTime.div(MAX_HARVEST_INTERVAL);

        if (lockUpTaxRate > (interval.add(1)).mul(100))
            rewardRate = lockUpTaxRate.sub((interval.add(1)).mul(100));
        else 
            rewardRate = 0;
    }

    function availableForWithdraw(address _user, uint8 _pid) public view returns (uint256 totalAmount) {
        totalAmount = 0;
        DepositInfo[] memory myDeposits =  depositInfo[_user][_pid];
        for(uint256 i=0; i< myDeposits.length; i++) {
            if(myDeposits[i].nextWithdraw < block.timestamp) {
                totalAmount = totalAmount.add(myDeposits[i].amount);
            }
        }
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint8 _pid, uint256 _amount) public nonReentrant {
        require(enableStaking[_pid] == true, 'Withdraw: DISABLE WITHDRAWING');
        
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.amount >= _amount, "withdraw: not good");

        uint256 availableAmount = availableForWithdraw(msg.sender, _pid);
        require(availableAmount > 0, "withdraw: no available amount");

        if (availableAmount < _amount) {
            _amount = availableAmount;
        }

        updatePool(_pid);
        payOrLockupPendingBQB(_pid);

        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
            pool.totalStakedTokens -= _amount;
        }

        // Remove desosit info in the array
        removeAmountFromDeposits(msg.sender, _pid, _amount, block.timestamp);
        removeEmptyDeposits(msg.sender, _pid);
        
        emit Withdraw(msg.sender, _pid, _amount);

        if (address(pool.lpToken) == bloqball) {
            try dividendTracker.setBalance(payable(msg.sender), user.amount) {} catch {}
        }
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint8 _pid) public nonReentrant {
        require(enableStaking[_pid] == true, 'Withdraw: DISABLE WITHDRAWING');
        
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.nextHarvestUntil = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        pool.totalStakedTokens -= amount;
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Pay or lockup pending BloqBalls.
    function payOrLockupPendingBQB(uint8 _pid) public {
        require(enableStaking[_pid] == true, 'Withdraw: DISABLE WITHDRAWING');
        
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        (, uint256 claimablePending, uint256 taxPending) = 
            availableRewardsForHarvest(_pid, msg.sender, pool.accBloqBallPerShare);

        if (canHarvest(_pid, msg.sender)) {
            if (claimablePending > 0) {
                totalAmountFromFeeByRewards = totalAmountFromFeeByRewards.add(taxPending);
                user.nextHarvestUntil = block.timestamp.add(pool.harvestInterval);

                // send BQB rewards
                safeBQBTransfer(msg.sender, claimablePending);
                payReferralCommission(msg.sender, claimablePending);

                user.totalEarnedBQB = user.totalEarnedBQB.add(claimablePending);
                user.taxAmount = taxPending;
                updateDepositInfo(_pid, msg.sender);
            }
        }
    }

    // Pay or lockup pending BloqBalls.
    function payOrLockupPendingBQB(uint8 _pid, uint256 _depositIndex) public {
        require(enableStaking[_pid] == true, 'Withdraw: DISABLE WITHDRAWING');
        
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        (, uint256 claimablePending, uint256 taxPending) = 
            availableIndividualRewardsForHarvest(_pid, msg.sender, pool.accBloqBallPerShare, _depositIndex);

        if (canHarvest(_pid, msg.sender)) {
            if (claimablePending > 0) {
                totalAmountFromFeeByRewards = totalAmountFromFeeByRewards.add(taxPending);
                user.nextHarvestUntil = block.timestamp.add(pool.harvestInterval);

                // send BQB rewards
                safeBQBTransfer(msg.sender, claimablePending);
                payReferralCommission(msg.sender, claimablePending);

                user.totalEarnedBQB = user.totalEarnedBQB.add(claimablePending);
                user.taxAmount = taxPending;

                updateDepositInfo(_pid, msg.sender, _depositIndex);
            }
        }
    }
    
    // Safe BQB transfer function, just in case if rounding error causes pool to not have enough BloqBalls.
    function safeBQBTransfer(address _to, uint256 _amount) internal {   
        uint256 BloqBallBal = IERC20(bloqball).balanceOf(address(this));
        if (_amount > BloqBallBal) {
            IERC20(bloqball).transfer(_to, BloqBallBal);
        } else {
            IERC20(bloqball).transfer(_to, _amount);
        }
    }

    function sendDividends(uint256 amount) public onlyOperator {
        require(amount <= address(this).balance, 'sendDividends: Insufficient balance');

        (bool success,) = address(payable(dividendTracker)).call{value: amount}("");

        if (success) {
            dividendTracker.distributeDividends(amount);
            emit SendDividends(amount);

            ftmRewardInfoAtId[currentFTMRewardID].timestamp = block.timestamp;
            ftmRewardInfoAtId[currentFTMRewardID].totalAmountFromFee = dividendTracker.totalDividendsDistributed();
            
            currentFTMRewardID ++;
        }
    }

    function getRewardsFTMofPeriod(uint256 period) external view returns (uint256) {
        uint oldDay = block.timestamp - period * 1 days;
        uint256 newFTMReward;
        uint256 ftmRewardOfOldDay;
        
        if (currentFTMRewardID < 1) {
            return 0;
        }
        
        for (uint i=currentFTMRewardID-1; i>= 0; i--) {
            if (ftmRewardInfoAtId[currentFTMRewardID].timestamp < oldDay) {
                ftmRewardOfOldDay = ftmRewardInfoAtId[currentFTMRewardID].totalAmountFromFee;
                break;
            }
        }

        uint256 totalFTMReward = dividendTracker.totalDividendsDistributed();
        newFTMReward = totalFTMReward - ftmRewardOfOldDay;
        
        return newFTMReward;
    }

    function setFeeAddress(address _feeAddress) public {
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        require(_feeAddress != address(0), "setFeeAddress: ZERO");
        feeAddress = _feeAddress;
    }
    
    function setLockUpTaxRate(uint256 _limit) public onlyOwner {
        require(_limit <= 10000, 'Limit Period: can not over 100%');
        lockUpTaxRate = _limit;
    }

    function removeAmountFromDeposits(address _user, uint8 _pid, uint256 _amount, uint256 _time) public {
        uint256 length =  depositInfo[_user][_pid].length;

        for(uint256 i=0; i< length; i++) {
            if(depositInfo[_user][_pid][i].nextWithdraw < _time) {
                if (depositInfo[_user][_pid][i].amount <= _amount) {
                    _amount = _amount.sub(depositInfo[_user][_pid][i].amount);
                    depositInfo[_user][_pid][i].amount = 0;
                }
                else {
                    depositInfo[_user][_pid][i].amount = depositInfo[_user][_pid][i].amount.sub(_amount);
                    _amount = 0;
                }
            }

            if (_amount == 0) {
                break;
            }
        }
    }

    function removeEmptyDeposits(address user, uint8 _pid) public {
        for (uint256 i=0; i<depositInfo[user][_pid].length; i++) {
            while(depositInfo[user][_pid].length > 0 && depositInfo[user][_pid][i].amount  == 0) {
                for (uint256 j = i; j<depositInfo[user][_pid].length-1; j++) {
                    depositInfo[user][_pid][j] = depositInfo[user][_pid][j+1];
                }
                depositInfo[user][_pid].pop();
            }
        }
    }

    // BQB has to add hidden dummy pools in order to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _BloqBallPerBlock) public onlyOwner {
        massUpdatePools();
        emit EmissionRateUpdated(msg.sender, BQBPerBlock, _BloqBallPerBlock);
        BQBPerBlock = _BloqBallPerBlock;
    }

    // Update the BQB referral contract address by the owner
    function setBQBReferral(IBloqBallReferral _BloqBallReferral) public onlyOwner {
        BloqBallReferral = _BloqBallReferral;
    }

    // Update referral commission rate by the owner
    function setReferralCommissionRate(uint16 _referralCommissionRate) public onlyOwner {
        require(_referralCommissionRate <= MAXIMUM_REFERRAL_COMMISSION_RATE, "setReferralCommissionRate: invalid referral commission rate basis points");
        referralCommissionRate = _referralCommissionRate;
    }

    // Pay referral commission to the referrer who referred this user.
    function payReferralCommission(address _user, uint256 _pending) internal {
        if (address(BloqBallReferral) != address(0) && referralCommissionRate > 0) {
            address referrer = BloqBallReferral.getReferrer(_user);
            uint256 commissionAmount = _pending.mul(referralCommissionRate).div(10000);

            if (referrer != address(0) && commissionAmount > 0) {
                BloqBall(bloqball).mint(referrer, commissionAmount);
                BloqBallReferral.recordReferralCommission(referrer, commissionAmount);
                emit ReferralCommissionPaid(_user, referrer, commissionAmount);
            }
        }
    }

    function transferOwnershipOfBloqBall() public onlyOwner {
        BloqBall(bloqball).transferOwnership(msg.sender);
    }


    //====================================== Dividend Distribute ========================================//

    /**
     * @notice Get the total amount of dividend distributed
     */ 
    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    /**
     * @notice View the amount of dividend in wei that an address can withdraw.
     */ 
    function withdrawableDividendOf(address account) public view returns(uint256) {
        return dividendTracker.withdrawableDividendOf(account);
    }

    /**
     * @notice View the amount of dividend in wei that an address has earned in total.
     */ 
    function withdrawnDividendOf(address account) public view returns(uint256) {
        return dividendTracker.withdrawnDividendOf(account);
    }

    /**
     * @notice Get the dividend token balancer in account
     */ 
    function dividendTokenBalanceOf(address account) public view returns (uint256) {
        return dividendTracker.balanceOf(account);
    }

    /**
     * @notice Exclude from receiving dividends
     */ 
    function excludeFromDividends(address account) external onlyOwner{
        dividendTracker.excludeFromDividends(account);
    }

    /**
     * @notice Get the dividend infor for account
     */ 
    function getAccountDividendsInfo(address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return dividendTracker.getAccount(account);
    }

    /**
     * @notice Get the indexed dividend infor
     */ 
    function getAccountDividendsInfoAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return dividendTracker.getAccountAtIndex(index);
    }

    /**
     * @notice Withdraws the token distributed to all token holders
     */
    function processDividendTracker() external {
        (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process();
        emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, 0, tx.origin);

    }

    /**
     * @notice Withdraws the token distributed to the sender.
     */
    function claim() external {
        dividendTracker.processAccount(payable(msg.sender), false, true);
    }

    /**
     * @notice Get the last processed info in dividend tracker
     */
    function getLastProcessedIndex() external view returns(uint256) {
        return dividendTracker.getLastProcessedIndex();
    }

    /**
     * @notice Get the number of dividend token holders
     */
    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }
}