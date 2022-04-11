/**
 *Submitted for verification at Etherscan.io on 2022-04-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;



// source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol

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



// source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol

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



// source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol

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



// source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/Proxy.sol

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
        require(owner() == _msgSender(), "[ptkn111401][ownable] caller is not the owner");
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
        require(newOwner != address(0), "[ptkn111401][ownable] new owner is the zero address");
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



// source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol

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



// source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol
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



// source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol
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
abstract contract ERC20 is Context, IERC20, IERC20Metadata {
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



library Array256{
    using Array256 for uint256[];
    function del(uint256[] storage self, uint256 i) internal{
        self[i] = self[self.length - 1];
        self.pop();
    }

    function delval(uint256[] storage self, uint256 v) internal{
        for(uint256 i=0; i<self.length; i++){
            if(self[i] == v){
                self.del(i);
            }
        }
    }

    function max(uint256[] storage self) internal view returns(uint256){
        uint256 _max = (
            (self.length > 0) ? self[0] : 0
        );
        for(uint256 i=0; i<self.length; i++){
            if(self[i] > _max){
                _max = self[i];
            }
        }
        return(_max);
    }

    function min(uint256[] storage self) internal view returns(uint256){
        uint256 _min = (
            (self.length > 0) ? self[0] : 0
        );
        for(uint256 i=0; i<self.length; i++){
            if(self[i] < _min){
                _min = self[i];
            }
        }
        return(_min);
    }

    function includes(uint256[] storage self, uint256 x) internal view returns(bool){
        for(uint256 i=0; i<self.length; i++){
            if(self[i] == x){
                return(true);
            }
        }
        return(false);
    }

    function fisherYatesShuffle(uint256[] storage self, uint256 r) internal{
        uint256 n; uint256 c; uint256 e;
        for(uint256 i=self.length-1; i>0; i--){
            n = r % (self.length - 1);
            c = self[i]; e = self[n];
            self[i] = e; self[n] = c;
        }
    }

    function _sort(uint256[] memory _self, uint256 left, uint256 right) private{
        uint256 i = left;
        uint256 j = right;  
        if(i == j){
            return;
        }
        uint256 n = _self[uint256(left + (right - left) / 2)];
        while(i <= j){
            while(_self[uint256(i)] < n) i++;
            while (n < _self[uint256(j)]) j--;
            if(i <= j){
                (_self[uint256(i)], _self[uint256(j)]) = (_self[uint256(j)], _self[uint256(i)]);
                i++;
                j--;
            }
        }
        if(left < j){
            _sort(_self, left, j);
        }
        if(i < right){
            _sort(_self, i, right);
        }
    }

    function sort(uint256[] storage self) internal{
        uint256[] memory _self = self;
        _sort(_self, 0, _self.length);
        for(uint l=0; l<_self.length; l++){
            self[l] = _self[l];
        }
    }
}

library ArrayAddress{
    using ArrayAddress for address[];
    function del(address[] storage self, uint256 i) internal{
        self[i] = self[self.length - 1];
        self.pop();
    }

    function delval(address[] storage self, address v) internal{
        for(uint256 i=0; i<self.length; i++){
            if(self[i] == v){
                self.del(i);
            }
        }
    }

    function includes(address[] storage self, address x) internal view returns(bool){
        for(uint256 i=0; i<self.length; i++){
            if(self[i] == x){
                return(true);
            }
        }
        return(false);
    }
}


abstract contract RoleBasedAccessControl is Context, Ownable{
    mapping(string => mapping(address => bool)) private _roleToAddress;
    mapping(string => bool) private _role;
    string[] _roles;

    // modifiers
        modifier onlyRole(string memory pRole){
            require(_roleToAddress[pRole][_msgSender()], "[ptkn111401][role based access control] only addresses assigned this role can access this function!");
            _;
        }

        modifier onlyRoles(string[] memory pRoles){
            for(uint256 i=0; i<pRoles.length; i++){
                require(_roleToAddress[pRoles[i]][_msgSender()], "[ptkn111401][role based access control] only addresses assigned this role can access this function!");
            }
            _;
        }

        modifier onlyRolesOr(string[] memory pRoles){
            bool rolePresent = false;
            for(uint256 i=0; i<pRoles.length; i++){
                rolePresent = rolePresent || _roleToAddress[pRoles[i]][_msgSender()];
            }
            require(rolePresent, "[ptkn111401][role based access control] only addresses assigned this role can access this function!");
            _;
        }

        modifier onlyRoleOrOwner(string memory pRole){
            require(_roleToAddress[pRole][_msgSender()] || owner() == _msgSender(), "[ptkn111401][role based access control] only addresses assigned this role or the owner can access this function!");
            _;
        }

    // register new roles

        function registerRole(string memory pRole, address[] memory pMembers) public virtual onlyRoleOrOwner("root"){
            _addRole(pRole);
            for(uint256 i=0; i<pMembers.length; i++){
                _roleToAddress[pRole][pMembers[i]] = true;
            }
        }

        function registerRoleAddress(string memory pRole, address pMember) public virtual onlyRoleOrOwner("root"){
            _addRole(pRole);
            _roleToAddress[pRole][pMember] = true;
        }

        function removeRoleAddress(string memory pRole, address pMember) public virtual onlyRoleOrOwner("root"){
            _addRole(pRole);
            _roleToAddress[pRole][pMember] = false;
        }

    // add

        function addRoleAddress(string memory pRole, address pMember) public virtual onlyRoleOrOwner("root"){
            _addRole(pRole);
            _roleToAddress[pRole][pMember] = true;
        }

    // get
    
        function hasRoleAddress(string memory pRole, address pAddress) public virtual returns(bool){
            return(_roleToAddress[pRole][pAddress]);
        }

    // privates

    function _addRole(string memory pRole) private{
        if(!_role[pRole]){
            _role[pRole] = true;
            _roles.push(pRole);
        }
    }
}


contract IPTKN111401{
    address public ADDRESS_MARKETING;
    address public ADDRESS_DEVELOPER;
    address public ADDRESS_BUYBACK;
    function enableIndividualTaxes(address, uint16, uint16, uint16, bool) public {}
    function disableIndividualTaxes(address) public {}
}

contract IPTKN111401Vote{
    function addVote(address) public {}
    function removeVote(address) public {}
}

contract PTKN111401Pools is Context, Ownable, ReentrancyGuard, RoleBasedAccessControl{
    // lib
        using SafeMath for uint256;
        using Address for address;
        using Array256 for uint256[];
        using ArrayAddress for address[];

    // addresses
        address public ADDRESS_TOKEN;
        address public ADDRESS_VOTE;

    // interfaces
        IPTKN111401 private _main;
        IPTKN111401Vote private _vote;

    // storage
        struct Taxes{
            uint16 marketing;
            uint16 developer;
            uint16 buyback;
        }
        struct Stake{
            uint256 tokens;
            uint256 start;
            uint256 end;
        }
        struct Pool{
            bool enabled;
            uint256 tokens;
            uint256 duration;
            string name;
            uint256[] brackets;
        }
        struct Info{
            uint256[] pools;
        }
        mapping(address => ERC20) public TOKENS;
        address[] private _tokens;
        mapping(address => mapping(uint256 => Pool)) public POOLS;
        mapping(address => mapping(uint256 => mapping(uint256 => Taxes))) public TAXES;
        mapping(address => mapping(uint256 => mapping(address => Stake))) public STAKES;
        mapping(address => Info) private _info;

    // errors
        mapping(string => string) public ERROR;

    // events
        event PoolNewToken(address indexed token);
        event PoolNew(address indexed token, uint256 pool, string name);
        event PoolRemove(address indexed token, uint256 pool);
        event PoolNewBracket(address indexed token, uint256 pool, uint256 bracket, uint16 marketing, uint16 developer, uint16 buyback);
        event PoolRemoveBracket(address indexed token, uint256 pool, uint256 bracket);
        event PoolStake(address indexed wallet, address indexed token, uint256 tokens, uint256 pool, uint256 total);
        event PoolUnstake(address indexed wallet, address indexed token, uint256 tokens, uint256 pool);
        event PoolForceUnstake(address indexed wallet, address indexed token, uint256 tokens, uint256 pool);
        event PoolVoteError(string error, string action, address indexed wallet);
        event PoolVoteErrorBytes(bytes error, string action, address indexed wallet);
        event PoolSetTaxes(address indexed wallet, address indexed token, uint256 pool, uint16 marketing, uint16 developer, uint16 buyback);
        event PoolSetTaxesError(string error, address indexed wallet, address indexed token, uint256 pool, string action, uint16 marketing, uint16 developer, uint16 buyback, bool buy);
        event PoolSetTaxesErrorBytes(bytes error, address indexed wallet, address indexed token, uint256 pool, string action, uint16 marketing, uint16 developer, uint16 buyback, bool buy);

    receive() external payable {}

    constructor(address pToken, address pVote){
        // all things wrong
            ERROR['unknownToken'] = '[ptkn111401][pools] this token is not allowed !';
            ERROR['poolExist'] = '[ptkn111401][pools] this pool exists already!';
            ERROR['poolDaysToLow'] = '[ptkn111401][pools] cant create a zero days pool!';
            ERROR['poolNotExist'] = '[ptkn111401][pools] this pool does not exist!';
            ERROR['stakingZero'] = '[ptkn111401][pools] cant stake zero tokens!';
            ERROR['stakingNotEnded'] = '[ptkn111401][pools] your staking pool has not ended yet!';
            ERROR['stakingNoTokens'] = '[ptkn111401][pools] you did not stake any tokens!';
            ERROR['stakingNoBracket'] = '[ptkn111401][pools] bracket does not exist!';
            ERROR['stakingNoBrackets'] = '[ptkn111401][pools] pool has no tack brackets!';
            ERROR['balanceLessThan'] = '[ptkn111401][pools] you do not have enough tokens!';
            ERROR['allowanceLessThan'] = '[ptkn111401][pools] your set allowance on this token is not enough!';
            ERROR['tokenTransferFailed'] = '[ptkn111401][pools] transfer of tokens failed!';
            ERROR['callVoteError'] = '[ptkn111401][pools] could not interact with voting contract!';

        // all things tokens
        
            ADDRESS_TOKEN = pToken;
            ADDRESS_VOTE = pVote;

            _main = IPTKN111401(ADDRESS_TOKEN);
            _vote = IPTKN111401Vote(ADDRESS_VOTE);

            _addToken(ADDRESS_TOKEN);

        // all things security
            registerRoleAddress("root", _msgSender());
            registerRoleAddress("root", _main.ADDRESS_DEVELOPER());
            renounceOwnership();
    }



    // owner
    // ███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗
    // ╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝

    function init(uint256 pPool) public onlyRole("root"){
        uint256 _decimals = 10**TOKENS[ADDRESS_TOKEN].decimals();
        if(pPool == 30){
            _addPool(ADDRESS_TOKEN, pPool, 'Great White Shark (Silver)');
                _addStakingBracket(ADDRESS_TOKEN, pPool, 50 * (10**9) * _decimals, 40, 30, 30);
                _addStakingBracket(ADDRESS_TOKEN, pPool, 55 * (10**9) * _decimals, 30, 30, 30);
                _addStakingBracket(ADDRESS_TOKEN, pPool, 65 * (10**9) * _decimals, 30, 30, 20);
        }
        
        if(pPool == 180){
            _addPool(ADDRESS_TOKEN, pPool, 'Whale Shark (Gold)');
                _addStakingBracket(ADDRESS_TOKEN, pPool, 75 * (10**9) * _decimals, 30, 20, 20);
                _addStakingBracket(ADDRESS_TOKEN, pPool, 85 * (10**9) * _decimals, 20, 20, 20);
                _addStakingBracket(ADDRESS_TOKEN, pPool, 95 * (10**9) * _decimals, 20, 20, 10);
        }

        if(pPool == 365){
            _addPool(ADDRESS_TOKEN, pPool, 'Megalodon (Diamond)');
                _addStakingBracket(ADDRESS_TOKEN, pPool, 100 * (10**9) * _decimals, 10, 10, 10);
                _addStakingBracket(ADDRESS_TOKEN, pPool, 250 * (10**9) * _decimals, 10, 10, 0);
                _addStakingBracket(ADDRESS_TOKEN, pPool, 500 * (10**9) * _decimals, 10, 0, 0);
        }
    }

    function addToken(address pToken) public onlyRole("root"){
        _addToken(pToken);
    }

    function addPool(address pToken, uint256 pPool, string memory pName) public onlyRole("root"){
        _addPool(pToken, pPool, pName);
    }

    function removePool(address pToken, uint256 pPool) public onlyRole("root"){
        _removePool(pToken, pPool);
    }

    function addStakingBracket(address pToken, uint256 pPool, uint256 pTokens, uint16 pMarketing, uint16 pDeveloper, uint16 pBuyback) public onlyRole("root"){
        _addStakingBracket(pToken, pPool, pTokens, pMarketing, pDeveloper, pBuyback);
    }

    function removeStakingBracket(address pToken, uint256 pPool, uint256 pTokens) public onlyRole("root"){
        _removeStakingBracket(pToken, pPool, pTokens);
    }

    function forceUnstake(address pWallet, address pToken, uint256 pPool) public onlyRole("root"){
        require(POOLS[pToken][pPool].enabled, ERROR['poolNotExist']);
        require(STAKES[pToken][pPool][pWallet].tokens > 0, ERROR['stakingNoTokens']);
        require(TOKENS[pToken].transfer(pWallet, STAKES[pToken][pPool][pWallet].tokens), ERROR['tokenTransferFailed']);

        uint256 _unstakedTokens = STAKES[pToken][pPool][pWallet].tokens;
        POOLS[pToken][pPool].tokens = POOLS[pToken][pPool].tokens.sub(_unstakedTokens);
        STAKES[pToken][pPool][pWallet].tokens = 0;

        // event
            emit PoolForceUnstake(pWallet, pToken, _unstakedTokens, pPool);
    }



    // public
    // ███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗
    // ╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝

    function balanceOf(address pWallet, address pToken) public view returns(uint256){
        uint256 _totalTokens;
        uint256[] memory _pools = getPools(pToken);
        for(uint256 j=0; j<_pools.length; j++){
            if(STAKES[pToken][_pools[j]][pWallet].tokens > 0){
                _totalTokens = _totalTokens.add(STAKES[pToken][_pools[j]][pWallet].tokens);
            }
        }

        return(_totalTokens);
    }

    function getTokens() public view returns(address[] memory){
        return(_tokens);
    }

    function getPools(address pToken) public view returns(uint256[] memory){
        require(_info[pToken].pools.length > 0, ERROR['poolNotExist']);
        return(_info[pToken].pools);
    }

    function getBrackets(address pToken, uint256 pPool) public view returns(uint256[] memory){
        require(POOLS[pToken][pPool].enabled, ERROR['poolNotExist']);
        return(POOLS[pToken][pPool].brackets);
    }

    function getTaxes(address pToken, uint256 pPool, uint256 pBracket) public view returns(
        uint16 rMarketing,
        uint16 rDeveloper,
        uint16 rBuyback
    ){
        require(POOLS[pToken][pPool].enabled, ERROR['poolNotExist']);
        require(POOLS[pToken][pPool].brackets.length > 0, ERROR['stakingNoBrackets']);
        require(POOLS[pToken][pPool].brackets.includes(pBracket), ERROR['stakingNoBracket']);
        return(
            TAXES[pToken][pPool][pBracket].marketing,
            TAXES[pToken][pPool][pBracket].developer,
            TAXES[pToken][pPool][pBracket].buyback
        );
    }

    function stake(address pToken, uint256 pTokens, uint256 pPool) public nonReentrant{
        require(_tokens.includes(pToken), ERROR['unknownToken']);
        require(pTokens > 0, ERROR['stakingZero']);
        require(POOLS[pToken][pPool].brackets.length > 0, ERROR['stakingNoBrackets']);
        require(TOKENS[pToken].balanceOf(_msgSender()) >= pTokens, ERROR['balanceLessThan']);
        require(TOKENS[pToken].allowance(_msgSender(), address(this)) >= pTokens, ERROR['allowanceLessThan']);
        require(POOLS[pToken][pPool].enabled, ERROR['poolNotExist']);
        require(TOKENS[pToken].transferFrom(_msgSender(), address(this), pTokens), ERROR['tokenTransferFailed']);

        if(STAKES[pToken][pPool][_msgSender()].tokens <= 0){
            Stake storage _stake = STAKES[pToken][pPool][_msgSender()];
            _stake.start = block.timestamp;
            _stake.end = block.timestamp.add(POOLS[pToken][pPool].duration);
            try _vote.addVote(_msgSender()){

            }catch Error(string memory _error){
                // event
                    emit PoolVoteError(_error, 'stake', _msgSender());
            }catch (bytes memory _error){
                // event
                    emit PoolVoteErrorBytes(_error, 'stake', _msgSender());
            }
        }

        STAKES[pToken][pPool][_msgSender()].tokens = STAKES[pToken][pPool][_msgSender()].tokens.add(pTokens);
        POOLS[pToken][pPool].tokens = POOLS[pToken][pPool].tokens.add(pTokens);
        _setTaxes(pToken, pPool, STAKES[pToken][pPool][_msgSender()].tokens);

        // event
            emit PoolStake(_msgSender(), pToken, pTokens, pPool, POOLS[pToken][pPool].tokens); 
    }

    function unstake(address pToken, uint256 pPool) public nonReentrant{
        require(POOLS[pToken][pPool].enabled, ERROR['poolNotExist']);
        require(STAKES[pToken][pPool][_msgSender()].tokens > 0, ERROR['stakingNoTokens']);
        require(block.timestamp >= STAKES[pToken][pPool][_msgSender()].end, ERROR['stakingNotEnded']);
        require(TOKENS[pToken].transfer(_msgSender(), STAKES[pToken][pPool][_msgSender()].tokens), ERROR['tokenTransferFailed']);

        uint256 _unstakedTokens = STAKES[pToken][pPool][_msgSender()].tokens;
        POOLS[pToken][pPool].tokens = POOLS[pToken][pPool].tokens.sub(_unstakedTokens);
        STAKES[pToken][pPool][_msgSender()].tokens = 0;

        try _main.disableIndividualTaxes(_msgSender()){
            // nothing
        }catch Error(string memory _error){
            // event
                emit PoolSetTaxesError(_error, _msgSender(), pToken, pPool, 'unstake', 0, 0, 0, false);
        }catch (bytes memory _error){
            // event
                emit PoolSetTaxesErrorBytes(_error, _msgSender(), pToken, pPool, 'unstake', 0, 0, 0, false);
        }

        try _vote.removeVote(_msgSender()){
            // nothing
        }catch Error(string memory _error){
            // event
                emit PoolVoteError(_error, 'unstake', _msgSender());
        }catch (bytes memory _error){
            // event
                emit PoolVoteErrorBytes(_error, 'unstake', _msgSender());
        }

        // event
            emit PoolUnstake(_msgSender(), pToken, _unstakedTokens, pPool);
    }


    // private
    // ███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗
    // ╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝

    function _addToken(address pToken) private{
        if(!_tokens.includes(pToken)){
            TOKENS[pToken] = ERC20(pToken);
            _tokens.push(pToken);

            // event
                emit PoolNewToken(pToken);
        }
    }

    function _setTaxes(address pToken, uint256 pPool, uint256 pTokens) private{
        uint256 _bracket;
        for(uint256 i=0; i<POOLS[pToken][pPool].brackets.length; i++){
            if(pTokens >= POOLS[pToken][pPool].brackets[i]){
                _bracket = POOLS[pToken][pPool].brackets[i];
            }
        }

        if(_bracket > 0){
            try _main.enableIndividualTaxes(
                _msgSender(), 
                TAXES[pToken][pPool][_bracket].marketing,
                TAXES[pToken][pPool][_bracket].developer,
                TAXES[pToken][pPool][_bracket].buyback,
                false
            ){

            }catch Error(string memory _error){
                // event
                    emit PoolSetTaxesError(_error, _msgSender(), pToken, pPool, 'stake', TAXES[pToken][pPool][_bracket].marketing, TAXES[pToken][pPool][_bracket].developer, TAXES[pToken][pPool][_bracket].buyback, false);
            }catch (bytes memory _error){
                // event
                    emit PoolSetTaxesErrorBytes(_error, _msgSender(), pToken, pPool, 'stake', TAXES[pToken][pPool][_bracket].marketing, TAXES[pToken][pPool][_bracket].developer, TAXES[pToken][pPool][_bracket].buyback, false);
            }

            try _main.enableIndividualTaxes(
                _msgSender(), 
                TAXES[pToken][pPool][_bracket].marketing,
                TAXES[pToken][pPool][_bracket].developer,
                TAXES[pToken][pPool][_bracket].buyback,
                true
            ){

            }catch Error(string memory _error){
                // event
                    emit PoolSetTaxesError(_error, _msgSender(), pToken, pPool, 'stake', TAXES[pToken][pPool][_bracket].marketing, TAXES[pToken][pPool][_bracket].developer, TAXES[pToken][pPool][_bracket].buyback, false);
            }catch (bytes memory _error){
                // event
                    emit PoolSetTaxesErrorBytes(_error, _msgSender(), pToken, pPool, 'stake', TAXES[pToken][pPool][_bracket].marketing, TAXES[pToken][pPool][_bracket].developer, TAXES[pToken][pPool][_bracket].buyback, false);
            }

            // event
                emit PoolSetTaxes(_msgSender(), pToken, pPool, TAXES[pToken][pPool][_bracket].marketing, TAXES[pToken][pPool][_bracket].developer, TAXES[pToken][pPool][_bracket].buyback);
        }
    }

    function _addPool(address pToken, uint256 pPool, string memory pName) private{
        require(pPool > 0, ERROR['poolDaysToLow']);
        require(!POOLS[pToken][pPool].enabled, ERROR['poolExist']);
        require(POOLS[pToken][pPool].duration <= 0, ERROR['poolExist']);
        Pool storage _pool = POOLS[pToken][pPool];
        _pool.duration = pPool * 86400;
        _pool.name = pName;
        _pool.enabled = true;

        Info storage _infos = _info[pToken];
        _infos.pools.push(pPool);

        // event
            emit PoolNew(pToken, pPool, pName);
    }

    function _removePool(address pToken, uint256 pPool) private{
        require(POOLS[pToken][pPool].enabled, ERROR['poolNotExist']);
        POOLS[pToken][pPool].enabled = false;
        _info[pToken].pools.delval(pPool);

        // event
            emit PoolRemove(pToken, pPool);
    }

    function _addStakingBracket(address pToken, uint256 pPool, uint256 pTokens, uint16 pMarketing, uint16 pDeveloper, uint16 pBuyback) private{
        require(POOLS[pToken][pPool].enabled, ERROR['poolNotExist']);
        POOLS[pToken][pPool].brackets.push(pTokens);
        Taxes storage _taxes = TAXES[pToken][pPool][pTokens];
        _taxes.marketing = pMarketing;
        _taxes.developer = pDeveloper;
        _taxes.buyback = pBuyback;

        // event
            emit PoolNewBracket(pToken, pPool, pTokens, pMarketing, pDeveloper, pBuyback);
    }

    function _removeStakingBracket(address pToken, uint256 pPool, uint256 pTokens) private{
        require(POOLS[pToken][pPool].enabled, ERROR['poolNotExist']);
        POOLS[pToken][pPool].brackets.delval(pTokens);
        TAXES[pToken][pPool][pTokens].marketing = 0;
        TAXES[pToken][pPool][pTokens].developer = 0;
        TAXES[pToken][pPool][pTokens].buyback = 0;

        // event
            emit PoolRemoveBracket(pToken, pPool, pTokens);
    }
}