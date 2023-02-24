// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol

// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

//pragma solidity ^0.8.0;

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
    function tryAdd(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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
    function tryMul(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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
    function tryDiv(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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
    function tryMod(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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

// File: @openzeppelin/contracts/utils/Address.sol

// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

//pragma solidity ^0.8.1;

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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                0,
                "Address: low-level call failed"
            );
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data
    ) internal view returns (bytes memory) {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(
        bytes memory returndata,
        string memory errorMessage
    ) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// File: @openzeppelin/contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

//pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

//pragma solidity ^0.8.0;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol

//pragma solidity >=0.6.2;

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
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

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
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
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

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountOut);

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol

//pragma solidity >=0.6.2;

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
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
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

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol

//pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol

//pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(
        address indexed sender,
        uint amount0,
        uint amount1,
        address indexed to
    );
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

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// File: contracts/GameCoin.sol

//pragma solidity ^0.8.0;

/// @title coignx
/// @author Pawan T (cis2213)

/* solium-disable-next-line */
contract Coignx is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;

    mapping(address => bool) private _isExcluded;
    address[] private _excluded;

    // Max number of uint256
    uint256 private constant MAX = ~uint256(0);

    // Total supply of the token
    uint256 private _tTotal = 1000000000000000 * 10 ** 18;

    // Total tokens for reflextion
    uint256 private _rTotal = MAX.sub(MAX.mod(_tTotal));
    uint256 private _tTaxFeeTotal;
    uint256 private _totalBurnedToken = 0;
    uint256 private _totalDonationFeeAccumulated = 0;
    uint256 private _burnLimit = (_tTotal.div(100)).div(2); // Initially the burn is capped to 50% of inital supply.

    string private _name = "XNATION TOKEN";
    string private _symbol = "XNT";
    uint8 private _decimals = 18;

    //Burn Fee.. x% of the fee will be burned
    uint8 private _burnFee = 2;
    uint8 private _previousBurnFee = _burnFee;

    //Burn Fee.. x% of the fee will be reflected back to all token holders
    uint8 private _taxFee = 2;
    uint8 private _previousTaxFee = _taxFee;

    // Donation Fee.. x% of the fee will be Donated to charities
    uint8 private _donationFee = 5;
    uint8 private _previousDonationFee = _donationFee;

    mapping(address => bool) private _isCompanyAccount;
    bool private _isGiveitAwayEnabled;
    uint256 private _totalCompanyTx = 0;
    uint8 private _companyTxTax = 2;

    //Uniswap contract and it's address
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;

    // Used to enable and disable swap and liquify the tokens.
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    // TODO: Understand and reform the following 2 variables.
    uint256 public _maxTxAmount = 1000000000000000 * 10 ** 18;

    uint256 private numTokensSellToAddToLiquidity = 1000000000000000 * 10 ** 18;

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    address public airdropAddress;
    address public advisorsAddress;
    address public privateSaleAddress;
    address public ecosystemAddress;
    address public publicSaleAddress;
    address public playToEarnAddress;
    address public stakingReawardsAddress;
    address public xnationAddress;

    constructor(
        address airdropAddress_,
        address advisorsAddress_,
        address privateSaleAddress_,
        address ecosystemAddress_,
        address publicSaleAddress_,
        address playToEarnAddress_,
        address stakingReawardsAddress_,
        address xnationAddress_
    ) {
        airdropAddress = airdropAddress_;
        advisorsAddress = advisorsAddress_;
        privateSaleAddress = privateSaleAddress_;
        ecosystemAddress = ecosystemAddress_;
        publicSaleAddress = publicSaleAddress_;
        playToEarnAddress = playToEarnAddress_;
        stakingReawardsAddress = stakingReawardsAddress_;
        xnationAddress = xnationAddress_;

        _tOwned[privateSaleAddress] = _tTotal.mul(5).div(100);
        _rOwned[privateSaleAddress] = _rTotal.div(100);
        _rOwned[privateSaleAddress] = _rOwned[privateSaleAddress].mul(5);

        _tOwned[ecosystemAddress] = _tTotal.mul(8).div(100);
        _rOwned[ecosystemAddress] = _rTotal.div(100);
        _rOwned[ecosystemAddress] = _rOwned[ecosystemAddress].mul(8);

        _tOwned[publicSaleAddress] = _tTotal.mul(11).div(100);
        _rOwned[publicSaleAddress] = _rTotal.div(100);
        _rOwned[publicSaleAddress] = _rOwned[publicSaleAddress].mul(11);

        _tOwned[playToEarnAddress] = _tTotal.mul(20).div(100);
        _rOwned[playToEarnAddress] = _rTotal.div(100);
        _rOwned[playToEarnAddress] = _rOwned[playToEarnAddress].mul(20);

        _tOwned[stakingReawardsAddress] = _tTotal.mul(29).div(100);
        _rOwned[stakingReawardsAddress] = _rTotal.div(100);
        _rOwned[stakingReawardsAddress] = _rOwned[stakingReawardsAddress].mul(
            29
        );

        _tOwned[xnationAddress] = _tTotal.mul(16).div(100);
        _rOwned[xnationAddress] = _rTotal.div(100);
        _rOwned[xnationAddress] = _rOwned[xnationAddress].mul(16);

        _rOwned[_msgSender()] = _rTotal.div(100);
        _rOwned[_msgSender()] = _rOwned[_msgSender()].mul(10);
        _tOwned[_msgSender()] = _tTotal.mul(10).div(100);

        //exclude owner and contract addresses from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        /// Exclude burn address from the reflection rewardscv
        /// Exclude burn address from the reflection rewardscv
        _isExcluded[address(0)] = true;
        _excluded.push(address(0));

        /// Exclude owner address from the reflection rewards
        _isExcluded[owner()] = true;
        _excluded.push(owner());

        /// Exclude contract address from the reflection rewards
        _isExcluded[address(this)] = true;
        _excluded.push(address(this));

        // Flag owner account as comapny account
        _isCompanyAccount[owner()] = true;

        emit Transfer(
            address(0),
            privateSaleAddress,
            _tOwned[privateSaleAddress]
        );
        emit Transfer(address(0), ecosystemAddress, _tOwned[ecosystemAddress]);
        emit Transfer(
            address(0),
            publicSaleAddress,
            _tOwned[publicSaleAddress]
        );
        emit Transfer(
            address(0),
            playToEarnAddress,
            _tOwned[playToEarnAddress]
        );
        emit Transfer(
            address(0),
            stakingReawardsAddress,
            _tOwned[stakingReawardsAddress]
        );
        emit Transfer(address(0), xnationAddress, _tOwned[xnationAddress]);
        emit Transfer(address(0), _msgSender(), _tOwned[_msgSender()]);
    }

    function setRouterAddress(
        address routerAddress
    ) public onlyOwner returns (bool) {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(routerAddress);
        //Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        _isExcluded[routerAddress] = true;
        _excluded.push(routerAddress);

        _isExcludedFromFee[routerAddress] = true;

        return true;
    }

    /// @return  the name of the token
    function name() public view returns (string memory) {
        return _name;
    }

    /// @return  the symbol of the token
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /// @return  the decimals of the token
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /// @return the total supply of the token
    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    /// @return the total tokens burnedtilldate
    function totalBurned() public view returns (uint256) {
        return _totalBurnedToken;
    }

    function changeBurnLimitPercent(uint256 burnLimit) public onlyOwner {
        _burnLimit = _tTotal.mul(burnLimit).div(100);
    }

    /// @return total fee collected so far
    function totalFees() public view returns (uint256) {
        return _tTaxFeeTotal;
    }

    /// @return total donation collected so far
    function totalDonationAccumulated() public view returns (uint256) {
        return _totalDonationFeeAccumulated;
    }

    /// @return  the tax percentage
    function getTaxFee() public view returns (uint256) {
        return _taxFee;
    }

    /// @return  the burn percentage
    function getBurnFee() public view returns (uint256) {
        return _burnFee;
    }

    /// @return  the donation percentage
    function getDonationFee() public view returns (uint256) {
        return _donationFee;
    }

    /// @return  company tx
    function getCompanyTx() public view returns (uint256) {
        return _totalCompanyTx;
    }

    // Set a account as company account
    /// @param account that needs to be set as company account
    function setCompanyAccount(address account) external onlyOwner {
        _isCompanyAccount[account] = true;
    }

    // unset a account as company account
    /// @param account that needs to be unset as company account
    function removeCompanyAccount(address account) external onlyOwner {
        _isCompanyAccount[account] = false;
    }

    function setCompanyTxFee(uint8 companyFee) external onlyOwner {
        _companyTxTax = companyFee;
    }

    function setGiveItAway(bool enable) external onlyOwner {
        _isGiveitAwayEnabled = enable;
    }

    function getGiveItAway() public view returns (bool) {
        return _isGiveitAwayEnabled;
    }

    /// Burns the given amount from the given account
    /// @param tBurnFee number of token to be burned from t-space
    /// @param rBurnFee number of token to be burned from t-space
    /// @param sender account
    function _takeBurnFee(
        address sender,
        uint256 tBurnFee,
        uint256 rBurnFee
    ) private {
        if (_totalBurnedToken <= _burnLimit) {
            _totalBurnedToken = _totalBurnedToken.add(tBurnFee);
            _rOwned[address(0)] = _rOwned[address(0)].add(rBurnFee);
            _tOwned[address(0)] = _tOwned[address(0)].add(tBurnFee);
            emit Transfer(sender, address(0), tBurnFee);
        }
    }

    /// @param account of which the token balance is retrived
    /// @return If the user is excluded from the rewards, then tOwned.If the user is
    /// included then the funtion will return the reflected and balance of the user
    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    /// Tranfer the given amount of token to recipient
    /// @param recipient receiver address
    /// @param amount of tokens to transfer
    /// @return true on succefull transfer
    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function excludeFromRewards(address account) external onlyOwner {
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    // When balanceOf() function is called, this function
    // will help in calculating the total tokens
    // earned by user based on thier current balance
    /// TODO: Learn more about this method
    function tokenFromReflection(
        uint256 rAmount
    ) public view returns (uint256) {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    // Owner can set the what percentage of each
    // trasaction should be compensated to burn
    function setBurnFeePercent(uint8 burnFee) external onlyOwner {
        require(burnFee <= 10, "Max burn fee rate can be 10%");
        _burnFee = burnFee;
    }

    // Owner can set the what percentage of each
    // trasaction should be compensated to reflection
    function setTaxFeePercent(uint8 taxFee) external onlyOwner {
        require(taxFee <= 10, "Max Tax fee rate can be 10%");
        _taxFee = taxFee;
    }

    // Owner can set the what percentage of each
    // trasaction should be compensated to donate
    function setDonationFeePercent(uint8 donationFee) external onlyOwner {
        require(donationFee <= 10, "Max Tax fee rate can be 10%");
        _donationFee = donationFee;
    }

    /// TODO: Learn more about this method
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(100);
    }

    /// TODO: Learn more about this method
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _takeTaxFee(uint256 rTaxFee, uint256 tTaxFee) private {
        _rTotal = _rTotal.sub(rTaxFee);
        _tTaxFeeTotal = _tTaxFeeTotal.add(tTaxFee);
    }

    // Calculates tax fee, donation fee, and final amount to be tranferred.
    // It also calculates the reflections.
    function _getValues(
        uint256 tAmount
    ) private view returns (uint256[] memory) {
        (
            uint256 tTaxFee,
            uint256 tDonationFee,
            uint256 tBurnFee,
            uint256 tCompanyTxFee
        ) = _getTValues(tAmount);
        (
            uint256 rAmount,
            uint256 rTaxFee,
            uint256 rDonationFee,
            uint256 rBurnFee,
            uint256 rCompanyTxFee
        ) = _getRValues(
                tAmount,
                tTaxFee,
                tDonationFee,
                tBurnFee,
                tCompanyTxFee,
                _getRate()
            );

        uint256[] memory fees = new uint256[](9);

        fees[0] = rAmount;
        fees[1] = rTaxFee;
        fees[2] = tTaxFee;
        fees[3] = rDonationFee;
        fees[4] = tDonationFee;
        fees[5] = rBurnFee;
        fees[6] = tBurnFee;
        fees[7] = rCompanyTxFee;
        fees[8] = tCompanyTxFee;

        return fees;

        // fees array structure = [ [0]rAmount, [1]rTaxFee, [2]tTaxFee, [3]rDonationFee, [4]tDonationFee, [5]rBurnFee, [6]tBurnFee, [7]rCompanyTxFee, [8]tCompanyTxFee]
    }

    // Calcualtes fees and tranfer amount.
    function _getTValues(
        uint256 tAmount
    ) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tBurnFee = _calculateBurnFee(tAmount);
        uint256 tTaxFee = _calculateTaxFee(tAmount);
        uint256 tDonation = _calculateDonationFee(tAmount);
        uint256 tCompanyTxFee = _calculateCompanyTxFee(tAmount);
        return (tTaxFee, tDonation, tBurnFee, tCompanyTxFee);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tTaxFee,
        uint256 tDonation,
        uint256 tBurnFee,
        uint256 tCompanyTxFee,
        uint256 currentRate
    ) private pure returns (uint256, uint256, uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rBurnFee = tBurnFee.mul(currentRate);
        uint256 rTaxFee = tTaxFee.mul(currentRate);
        uint256 rDonation = tDonation.mul(currentRate);
        uint256 rCompanyTxFee = tCompanyTxFee.mul(currentRate);
        return (rAmount, rTaxFee, rDonation, rBurnFee, rCompanyTxFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    // This function can be  removed as we are not
    // Taking any liquidity from tranasctions.
    function _takeDonation(uint256 tDonation, uint256 rDonation) private {
        _totalDonationFeeAccumulated = _totalDonationFeeAccumulated.add(
            tDonation
        );
        _rOwned[address(this)] = _rOwned[address(this)].add(rDonation);
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tDonation);
    }

    // TODO; change the function name to _calculateBurnFee()
    function _calculateBurnFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_burnFee).div(100);
    }

    // TODO; change the function name to _calculateTaxFee()
    function _calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(100);
    }

    function _calculateDonationFee(
        uint256 _amount
    ) private view returns (uint256) {
        return _amount.mul(_donationFee).div(100);
    }

    function _calculateCompanyTxFee(
        uint256 _amount
    ) private view returns (uint256) {
        return _amount.mul(_companyTxTax).div(100);
    }

    // Takes companyFee of x% from all company Tx when give it back protocol
    function _takeCompanyTxFee(
        uint256 tCompanyFee,
        uint256 rCompanyFee
    ) private {
        _totalCompanyTx = _totalCompanyTx.add(tCompanyFee);
        _rOwned[address(this)] = _rOwned[address(this)].add(rCompanyFee);
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tCompanyFee);
    }

    function removeAllFee() private {
        if (_burnFee == 0 && _donationFee == 0 && _taxFee == 0) return;

        _previousBurnFee = _burnFee;
        _previousTaxFee = _taxFee;
        _previousDonationFee = _donationFee;

        _burnFee = 0;
        _taxFee = 0;
        _donationFee = 0;
    }

    function restoreAllFee() private {
        _burnFee = _previousBurnFee;
        _taxFee = _previousTaxFee;
        _donationFee = _previousDonationFee;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        // This if statement can be removed depending on the removal of the _maxTxAmount
        if ((from != owner() && to != owner()))
            require(
                amount <= _maxTxAmount,
                "Transfer amount exceeds the maxTxAmount."
            );

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    function swapAndLiquify(
        uint256 contractTokenBalance
    ) public lockTheSwap onlyOwner {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    /// This function will release the accumulated donation amount to
    /// given charity address
    /// @param donationAccount address if the community voted charity
    function releaseDonationAndCompanyTxFee(
        address donationAccount,
        address winnerAccount
    ) public onlyOwner {
        if (
            _totalDonationFeeAccumulated != 0 && donationAccount != address(0)
        ) {
            require(
                balanceOf(address(this)) >= _totalDonationFeeAccumulated,
                "Not enough balance"
            );
            _tokenTransfer(
                address(this),
                donationAccount,
                _totalDonationFeeAccumulated,
                false
            );

            _totalDonationFeeAccumulated = 0;
        }

        if (_totalCompanyTx != 0 && winnerAccount != address(0)) {
            require(
                balanceOf(address(this)) >= _totalCompanyTx,
                "Not enough balance"
            );
            _tokenTransfer(
                address(this),
                winnerAccount,
                _totalCompanyTx,
                false
            );

            _totalCompanyTx = 0;
        }
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) public {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee
    ) private {
        uint256[] memory fees = new uint256[](9);
        fees = _getValues(tAmount);

        uint256 rDeductionAmount;
        uint256 tDeductionAmount;

        if (!takeFee) {
            rDeductionAmount = fees[0];
            tDeductionAmount = tAmount;
        } else {
            rDeductionAmount = fees[0].add(fees[1]).add(fees[3]).add(fees[5]);
            tDeductionAmount = tAmount.add(fees[2]).add(fees[4]).add(fees[6]);
            _takeBurnFee(sender, fees[6], fees[5]);
            _takeDonation(fees[4], fees[3]);
            _takeTaxFee(fees[1], fees[2]);
        }

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            // _transferFromExcluded

            if (_isCompanyAccount[sender] && _isGiveitAwayEnabled) {
                _tOwned[sender] = _tOwned[sender].sub(
                    tDeductionAmount.add(fees[8])
                );
                _rOwned[sender] = _rOwned[sender].sub(
                    rDeductionAmount.add(fees[7])
                );
                _takeCompanyTxFee(fees[8], fees[7]);
            } else {
                _tOwned[sender] = _tOwned[sender].sub(tDeductionAmount);
                _rOwned[sender] = _rOwned[sender].sub(rDeductionAmount);
            }
            _rOwned[recipient] = _rOwned[recipient].add(fees[0]);

            //
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            // _transferToExcluded

            if (_isCompanyAccount[sender] && _isGiveitAwayEnabled) {
                _rOwned[sender] = _rOwned[sender].sub(
                    rDeductionAmount.add(fees[7])
                );
                _takeCompanyTxFee(fees[8], fees[7]);
            } else {
                _rOwned[sender] = _rOwned[sender].sub(rDeductionAmount);
            }
            _tOwned[recipient] = _tOwned[recipient].add(tAmount);
            _rOwned[recipient] = _rOwned[recipient].add(fees[0]);

            //
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            // _transferBothExcluded

            if (_isCompanyAccount[sender] && _isGiveitAwayEnabled) {
                _tOwned[sender] = _tOwned[sender].sub(
                    tDeductionAmount.add(fees[8])
                );
                _rOwned[sender] = _rOwned[sender].sub(
                    rDeductionAmount.add(fees[7])
                );
                _takeCompanyTxFee(fees[8], fees[7]);
            } else {
                _tOwned[sender] = _tOwned[sender].sub(tDeductionAmount);
                _rOwned[sender] = _rOwned[sender].sub(rDeductionAmount);
            }
            _tOwned[recipient] = _tOwned[recipient].add(tAmount);
            _rOwned[recipient] = _rOwned[recipient].add(fees[0]);

            //
        } else {
            // _transferStandard

            if (_isCompanyAccount[sender] && _isGiveitAwayEnabled) {
                _rOwned[sender] = _rOwned[sender].sub(
                    rDeductionAmount.add(fees[7])
                );
                _takeCompanyTxFee(fees[8], fees[7]);
            } else {
                _rOwned[sender] = _rOwned[sender].sub(rDeductionAmount);
            }
            _rOwned[recipient] = _rOwned[recipient].add(fees[0]);

            //
        }
        emit Transfer(sender, recipient, tAmount);
    }
}