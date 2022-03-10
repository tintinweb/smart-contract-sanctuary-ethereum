/**
 *Submitted for verification at Etherscan.io on 2022-03-10
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.6;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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

        (bool success,) = recipient.call{value : amount}("");
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

        (bool success, bytes memory returndata) = target.call{value : value}(data);
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

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function addressToString(address _addr) public pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(address(_addr))));

        bytes memory str = new bytes(51);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < 20; i++) {
            str[2 + i * 2] = _HEX_SYMBOLS[uint(uint8(value[i + 12] >> 4))];
            str[3 + i * 2] = _HEX_SYMBOLS[uint(uint8(value[i + 12] & 0x0f))];
        }
        return string(str);
    }

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

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

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

interface IToken is IERC20 {
    function TotalBurn() external view returns (uint256);

    function TwoHoursBurn() external view returns (uint256);

    function ResetTwoHoursBurn() external returns (bool);

    function getLastBurnTime() external view returns (uint256);

    function getInterval() external view returns (uint256);
}

// PI-DAO Pool 1
contract Pool1 is Ownable {
    using SafeMath for uint256;
    using Address for address;

    IToken public token;
    IUniswapV2Pair public uniswapV2Pair;

    constructor() {

    }

    // 初始化 
    function init(address _token, address _pair) public onlyOwner {
        token = IToken(_token);        
        uniswapV2Pair = IUniswapV2Pair(_pair);
    }

    // ---------------- node -----------------

    uint256 public n_1000 = 1000;
    uint256 public n_200 = 200;
    uint256 public requiredQuantity = 2; // required quantity

    mapping(address => uint256) private recommendCount; // 推荐数量
    mapping(address => address[]) private recommendAddress; // 推荐地址列表
    mapping(address => bool) private isRegister; // 是否已经被推荐
    mapping(address => address) private rootNode; // 上级地址
    mapping(address => bool) private nodeReal; // 真节点
    mapping(address => bool) private node; // 准节点

    event RegisterRootNode(address indexed account, address indexed root);
    event UpgradeToNode(address indexed account, bool result);
    event UpgradeToRealNode(address indexed account, bool result);
    event CalcValue(address indexed account, address indexed to, uint256 self_LP,uint256 _Total_LP,uint256 r0,uint256 r1,uint256 price,uint256 self_p,uint256 self_a0,uint256 self_a1,uint256 sum_lp);
    event CalcNomarlValue(address indexed account, address indexed to, uint256 self_LP,uint256 _Total_LP,uint256 r0,uint256 r1,uint256 price,uint256 self_p,uint256 self_a0,uint256 self_a1,uint256 sum_lp);

    function getUniswapV2Pair() public view returns (address){
        return address(uniswapV2Pair);
    }

    function getToken() public view returns (address){
        return address(token);
    }

    function setNode(address account, bool status) public onlyOwner {
        node[account] = status;
    }

    function setNodeReal(address account, bool status) public onlyOwner {
        nodeReal[account] = status;
    }

    function setRequiredQuantity(uint256 amount) public onlyOwner {
        require(amount > 0, "must be greater than zero");
        requiredQuantity = amount;        
    }

    function getRecommendCount(address account) external view returns(uint256){
        return recommendCount[account];
    }

    function getRootNode(address account) external view returns (address){
        return rootNode[account];
    }

    function isRealNode(address account) external view returns (bool){
        return nodeReal[account];
    }

    function isNode(address account) external view returns (bool){
        return node[account];
    }

    // 注册上级
    function registerRootNode(address rootAccount) external {
        require(isRegister[msg.sender] == false, "already recommended");
        require(node[rootAccount] == true, "not a node");
        require(rootAccount != msg.sender, "same address");

        recommendCount[rootAccount] = recommendCount[rootAccount].add(1);
        recommendAddress[rootAccount].push(msg.sender);
        isRegister[msg.sender] = true;
        rootNode[msg.sender] = rootAccount;

        emit RegisterRootNode(msg.sender, rootAccount);
    }

    function calculatedValue(address account) external returns (uint256, uint256, uint256) {
        return _calculatedValue(account);
    }

    // 计算用户锁仓总价值
    function _calculatedValue(address account) internal virtual returns (uint256 amount, uint256 token0Amount, uint256 token1Amount){
        // 锁仓总LP
        uint256 self_LP = lockLPSum[account]; 

        if (self_LP == 0) {
            return (0, 0, 0);
        }

        uint256 _Total_LP = 0;
        _Total_LP = _Total_LP.add(uniswapV2Pair.totalSupply());
        // Pair total LP

        (uint112 _reserve0, uint112 _reserve1,) = uniswapV2Pair.getReserves();

        uint256 r0 = 0;
        r0 = r0.add(_reserve1);

        uint256 r1 = 0;
        r1 = r1.add(_reserve0);

        // 计算锁仓质押价值是否足够 1000u
        // token0 单价      
        uint256 price = r1.div(r0);

        uint256 self_p = self_LP.mul(1000).div(_Total_LP);
        // LP 占比        

        uint256 self_a0 = r0.mul(self_p).div(1000).mul(price).div(10 ** 18);
        //  token0 总价值

        uint256 self_a1 = r1.mul(self_p).div(1000).div(10 ** 18);
        // USDT 总价值

        uint256 sum_lp = self_a0.add(self_a1);

        emit CalcValue(msg.sender, account, self_LP, _Total_LP, r0, r1, price, self_p, self_a0, self_a1, sum_lp);

        return (sum_lp, self_a0, self_a1);
    }

    // 计算普通锁仓用户总价值
    function _calculatedNormalValue(address account) internal virtual returns (uint256 amount, uint256 token0Amount, uint256 token1Amount){
        // 普通锁仓总LP
        uint256 self_LP = normalLockLPSum[account];

        if (self_LP == 0) {
            return (0, 0, 0);
        }

        uint256 _Total_LP = 0;
        _Total_LP = _Total_LP.add(uniswapV2Pair.totalSupply());

        (uint112 _reserve0, uint112 _reserve1,) = uniswapV2Pair.getReserves();

        uint256 r0 = 0;
        r0 = r0.add(_reserve1);

        uint256 r1 = 0;
        r1 = r1.add(_reserve0);

        uint256 price = r1.div(r0);
        uint256 self_p = self_LP.mul(1000).div(_Total_LP);
        uint256 self_a0 = r0.mul(self_p).div(1000).mul(price).div(10 ** 18);
        uint256 self_a1 = r1.mul(self_p).div(1000).div(10 ** 18);
        uint256 sum_lp = self_a0.add(self_a1);

        emit CalcNomarlValue(msg.sender, account, self_LP, _Total_LP, r0, r1, price, self_p, self_a0, self_a1, sum_lp);

        return (sum_lp, self_a0, self_a1);
    }

    function upgradeToNode() public {
        //require(rootNode[msg.sender] != address(0), "No recommended address");
        //require(node[msg.sender] == false, "already an official node");        
        (uint256 self_sum, ,) = _calculatedValue(msg.sender);
        require(self_sum >= n_1000, "Must pledge and lock 1000 USDT");
        node[msg.sender] = true;

        emit UpgradeToNode(msg.sender, true);
    }

    function _queryRequiredQuantity() internal virtual returns (uint256, bool) {
        uint256 sum = 0;

        for(uint256 i = 0; i < recommendAddress[msg.sender].length; i++) {
            address addr = recommendAddress[msg.sender][i];
            (uint256 s, ,) = _calculatedValue(addr);

            if (s == 0) {
                continue;
            }

            if (s >= n_200){
                sum = sum.add(1);
            }

            if(sum >= requiredQuantity) {
                return (sum, true);
            }             
        }

        return (sum, false);
    }

    function upgradeToRealNode() public returns (bool) {
        require(node[msg.sender] == true, "not a node");

        (uint256 sum, bool result) = _queryRequiredQuantity();

        require(result == true, "condition not met");

        if(sum >= requiredQuantity && result) {
            nodeReal[msg.sender] = true;
            emit UpgradeToRealNode(msg.sender, true);

            return true;
        }

        emit UpgradeToRealNode(msg.sender, false);

        return false;
    }

    // ---------------- Lock 365 days LP -----------------

    uint256 public lockDays = 0 days;
    mapping(address => uint256[]) private lockLPStartTime; // 开始锁仓时间记录
    mapping(address => uint256[]) private lockLPTotal;  // 锁仓记录量
    mapping(address => uint256) private lockLPSum;  // 锁仓总数量
    mapping(address => bool) private isLocked; // 锁仓的账号
    address[] private lockList; // 锁仓地址列表

    event LockLP(address indexed account, uint256 amount);
    event UnlockLP(address indexed account, uint256 startTime, uint256 amount);

    function lockLP(uint256 amount) external {
        uniswapV2Pair.transferFrom(msg.sender, address(this), amount);

        lockLPStartTime[msg.sender].push(block.timestamp);
        lockLPTotal[msg.sender].push(amount);
        lockLPSum[msg.sender] = lockLPSum[msg.sender].add(amount);
        if(isLocked[msg.sender] == false){
            lockList.push(msg.sender);
        }        
        isLocked[msg.sender] = true;        

        emit LockLP(msg.sender, amount);
    }    

    function unlockLP(uint256 startTime) external returns (bool) {
        if (startTime + block.timestamp < lockDays) {
            return false;
        }

        for (uint256 i = 0; i < lockLPStartTime[msg.sender].length; i++) {
            if (startTime == lockLPStartTime[msg.sender][i]) {
                uint256 amount = lockLPTotal[msg.sender][i];
                uniswapV2Pair.transfer(msg.sender, amount);

                lockLPSum[msg.sender] = lockLPSum[msg.sender].sub(amount);

                // remove startTime
                for (uint j = i; j < lockLPStartTime[msg.sender].length - 1; j++) {
                    lockLPStartTime[msg.sender][j] = lockLPStartTime[msg.sender][j + 1];
                }
                lockLPStartTime[msg.sender].pop();

                // remove lockLP amount
                for (uint j = i; j < lockLPTotal[msg.sender].length - 1; j++) {
                    lockLPTotal[msg.sender][j] = lockLPTotal[msg.sender][j + 1];
                }
                lockLPTotal[msg.sender].pop();

                // set isLocked is false
                if (lockLPStartTime[msg.sender].length == 0) {
                    isLocked[msg.sender] = false;                
                    // remove lockList amount
                    for (uint j = i; j < lockList.length - 1; j++) {
                        lockList[j] = lockList[j + 1];
                    }
                    lockList.pop();
                }

                emit UnlockLP(msg.sender, startTime, amount);

                return true;
            }
        }

        return false;
    }

    function setLockDays(uint256 ts) public onlyOwner{
        require(ts > 0, "must be greater than zero");
        lockDays = ts;
    }

    function getLockLP(address account) external view returns (uint256[] memory){
        return lockLPTotal[account];
    }

    function getLockLPStartTime(address account) external view returns (uint256[] memory){
        return lockLPStartTime[account];
    }

    function getLockLPSum(address account) external view returns (uint256){
        return lockLPSum[account];
    }

    function getLockList() public view returns (address[] memory) {
        return lockList;
    }

    // ---------------- 0 days normal Lock LP -----------------

    mapping(address => uint256[]) private normalLockLPStartTime; 
    mapping(address => uint256[]) private normalLockLPTotal;  
    mapping(address => uint256) private normalLockLPSum; 
    mapping(address => bool) private isNormalLocked;
    address[] private NormalLockList; // 锁仓地址列表

    event NormalLockLP(address indexed account, uint256 amount);
    event NormalUnlockLP(address indexed account,uint256 startTime, uint256 amount);

    function normalLockLP(uint256 amount) external {
        uniswapV2Pair.transferFrom(msg.sender, address(this), amount);

        normalLockLPStartTime[msg.sender].push(block.timestamp);
        normalLockLPTotal[msg.sender].push(amount);
        normalLockLPSum[msg.sender] = normalLockLPSum[msg.sender].add(amount);
        if(isNormalLocked[msg.sender] == false){
            NormalLockList.push(msg.sender);
        }        
        isNormalLocked[msg.sender] = true;

        emit NormalLockLP(msg.sender, amount);
    }

    function normalUnlockLP(uint256 startTime) external returns (bool) {
        for (uint256 i = 0; i < normalLockLPStartTime[msg.sender].length; i++) {
            if (startTime == normalLockLPStartTime[msg.sender][i]) {
                uint256 amount = normalLockLPTotal[msg.sender][i];
                uniswapV2Pair.transfer(msg.sender, amount);

                normalLockLPSum[msg.sender] = normalLockLPSum[msg.sender].sub(amount);

                // remove startTime
                for (uint j = i; j < normalLockLPStartTime[msg.sender].length - 1; j++) {
                    normalLockLPStartTime[msg.sender][j] = normalLockLPStartTime[msg.sender][j + 1];
                }
                normalLockLPStartTime[msg.sender].pop();

                // remove normalLockLPTotal amount
                for (uint j = i; j < normalLockLPTotal[msg.sender].length - 1; j++) {
                    normalLockLPTotal[msg.sender][j] = normalLockLPTotal[msg.sender][j + 1];
                }
                normalLockLPTotal[msg.sender].pop();

                // set isNormalLocked is false
                if (normalLockLPStartTime[msg.sender].length == 0) {
                    isNormalLocked[msg.sender] = false;
                    // remove NormalLockList amount
                    for (uint j = i; j < NormalLockList.length - 1; j++) {
                        NormalLockList[j] = NormalLockList[j + 1];
                    }
                    NormalLockList.pop();
                }

                emit NormalUnlockLP(msg.sender, startTime, amount);

                return true;
            }
        }

        return false;
    }

    function getNormalLockLP(address account) external view returns (uint256[] memory){
        return normalLockLPTotal[account];
    }

    function getNormalLockLPStartTime(address account) external view returns (uint256[] memory){
        return normalLockLPStartTime[account];
    }

    function getNormalLockLPSum(address account) external view returns (uint256){
        return normalLockLPSum[account];
    }

    function getNormalLockList() public view returns (address[] memory) {
        return NormalLockList;
    }

    // ---------------- Lottery ----------------
    event LotteryLocked365(address indexed account, uint256 freedVal, uint256 P, uint256 amount, uint256 sum);
    event LotteryLocked(address indexed account, uint256 freedVal, uint256 P, uint256 amount, uint256 sum);

    address[] LockUserAccount;
    uint256[] LockUserAmount;

    address[] NormalLockUserAccount;
    uint256[] NormalLockUserAmount;

    function getLockUserAccount() public view returns(address[] memory) {
        return LockUserAccount;
    }

    function getLockUserAmount() public view returns(uint256[] memory) {
        return LockUserAmount;
    }

    function getNormalLockUserAccount() public view returns(address[] memory) {
        return NormalLockUserAccount;
    }

    function getNormalLockUserAmount() public view returns(uint256[] memory) {
        return NormalLockUserAmount;
    }

    function lottery() public returns (bool) {
        // if (block.timestamp < token.getLastBurnTime() + token.getInterval()) {
        //     return false;
        // }

        uint256 total = token.balanceOf(address(this)); // 矿池拥有的token总数量
        require(total > 0, "token balance is zero");

        uint256 freed = total.mul(10).div(1000); // 本轮释放

        uint256 sum = 0; 

        delete LockUserAccount;
        delete LockUserAmount;
        delete NormalLockUserAccount;
        delete NormalLockUserAmount;

        // 锁仓地址列表

        for (uint256 i = 0; i < lockList.length; i++) {
            address account = lockList[i];
            if(isLocked[account] != true) {
                continue;
            }
            
            (uint256 LockValue,,) = _calculatedValue(account);
            LockUserAccount.push(account);
            LockUserAmount.push(LockValue.mul(2));
            sum = sum.add(LockValue.mul(2));
        }

        // 普通质押
        for (uint256 i = 0; i < NormalLockList.length; i++) {
            address account = NormalLockList[i];
            if(isNormalLocked[account] != true) {
                continue;
            }

            (uint256 nomarlLockValue,,) = _calculatedNormalValue(account);
            NormalLockUserAccount.push(account);
            NormalLockUserAmount.push(nomarlLockValue);
            sum = sum.add(nomarlLockValue);
        }

        // 结锁仓
        for (uint256 i = 0; i < LockUserAccount.length; i++) {
            address account = LockUserAccount[i];
            uint256 amount = LockUserAmount[i];
            uint256 P = amount.mul(1000).div(sum);
            uint256 val = freed.mul(P).div(1000);

            emit LotteryLocked365(account, val, P, amount, sum);
            token.transfer(account, val);
        }

        // 结普通锁仓
        for (uint256 i = 0; i < NormalLockUserAccount.length; i++) {
            address account = NormalLockUserAccount[i];
            uint256 amount = NormalLockUserAmount[i];
            uint256 P = amount.mul(1000).div(sum);
            uint256 val = freed.mul(P).div(1000);

            emit LotteryLocked(account, val, P, amount, sum);
            token.transfer(account, val);
        }

        token.ResetTwoHoursBurn();

        return true;
    }

}