/**
 *Submitted for verification at Etherscan.io on 2022-05-04
*/

// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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


// File @openzeppelin/contracts/utils/[email protected]

// SPDX: MIT
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


// File @openzeppelin/contracts/token/ERC20/[email protected]

// SPDX: MIT
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
    event Approval(address indexed owner, address indexed spender, uint256 value);

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
}


// File @openzeppelin/contracts/interfaces/[email protected]

// SPDX: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;


// File @openzeppelin/contracts/utils/math/[email protected]

// SPDX: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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


// File @openzeppelin/contracts/access/[email protected]

// SPDX: MIT
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


// File @uniswap/v2-periphery/contracts/interfaces/[email protected]

pragma solidity >=0.6.2;

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


// File @uniswap/v2-periphery/contracts/interfaces/[email protected]

pragma solidity >=0.6.2;

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


// File @uniswap/v2-core/contracts/interfaces/[email protected]

pragma solidity >=0.5.0;

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


// File @uniswap/v2-periphery/contracts/interfaces/[email protected]

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}


// File contracts/Revolver.sol

/*
 *  ΓûäΓûäΓûäΓûäΓûäΓûäΓûäΓûäΓûäΓûäΓûä  ΓûäΓûäΓûäΓûäΓûäΓûäΓûäΓûäΓûäΓûäΓûä  Γûä               Γûä  ΓûäΓûäΓûäΓûäΓûäΓûäΓûäΓûäΓûäΓûäΓûä  Γûä    Γûä               Γûä  ΓûäΓûäΓûäΓûäΓûäΓûäΓûäΓûäΓûäΓûäΓûä  ΓûäΓûäΓûäΓûäΓûäΓûäΓûäΓûäΓûäΓûäΓûä 
 * ΓûÉΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûîΓûÉΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûîΓûÉΓûæΓûî             ΓûÉΓûæΓûîΓûÉΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûîΓûÉΓûæΓûî  ΓûÉΓûæΓûî             ΓûÉΓûæΓûîΓûÉΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûîΓûÉΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûî
 * ΓûÉΓûæΓûêΓûÇΓûÇΓûÇΓûÇΓûÇΓûÇΓûÇΓûêΓûæΓûîΓûÉΓûæΓûêΓûÇΓûÇΓûÇΓûÇΓûÇΓûÇΓûÇΓûÇΓûÇ  ΓûÉΓûæΓûî           ΓûÉΓûæΓûî ΓûÉΓûæΓûêΓûÇΓûÇΓûÇΓûÇΓûÇΓûÇΓûÇΓûêΓûæΓûîΓûÉΓûæΓûî   ΓûÉΓûæΓûî           ΓûÉΓûæΓûî ΓûÉΓûæΓûêΓûÇΓûÇΓûÇΓûÇΓûÇΓûÇΓûÇΓûÇΓûÇ ΓûÉΓûæΓûêΓûÇΓûÇΓûÇΓûÇΓûÇΓûÇΓûÇΓûêΓûæΓûî
 * ΓûÉΓûæΓûî       ΓûÉΓûæΓûîΓûÉΓûæΓûî            ΓûÉΓûæΓûî         ΓûÉΓûæΓûî  ΓûÉΓûæΓûî       ΓûÉΓûæΓûîΓûÉΓûæΓûî    ΓûÉΓûæΓûî         ΓûÉΓûæΓûî  ΓûÉΓûæΓûî          ΓûÉΓûæΓûî       ΓûÉΓûæΓûî
 * ΓûÉΓûæΓûêΓûäΓûäΓûäΓûäΓûäΓûäΓûäΓûêΓûæΓûîΓûÉΓûæΓûêΓûäΓûäΓûäΓûäΓûäΓûäΓûäΓûäΓûä    ΓûÉΓûæΓûî       ΓûÉΓûæΓûî   ΓûÉΓûæΓûî       ΓûÉΓûæΓûîΓûÉΓûæΓûî     ΓûÉΓûæΓûî       ΓûÉΓûæΓûî   ΓûÉΓûæΓûêΓûäΓûäΓûäΓûäΓûäΓûäΓûäΓûäΓûä ΓûÉΓûæΓûêΓûäΓûäΓûäΓûäΓûäΓûäΓûäΓûêΓûæΓûî
 * ΓûÉΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûîΓûÉΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûî    ΓûÉΓûæΓûî     ΓûÉΓûæΓûî    ΓûÉΓûæΓûî       ΓûÉΓûæΓûîΓûÉΓûæΓûî      ΓûÉΓûæΓûî     ΓûÉΓûæΓûî    ΓûÉΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûîΓûÉΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûî
 * ΓûÉΓûæΓûêΓûÇΓûÇΓûÇΓûÇΓûêΓûæΓûêΓûÇΓûÇ ΓûÉΓûæΓûêΓûÇΓûÇΓûÇΓûÇΓûÇΓûÇΓûÇΓûÇΓûÇ      ΓûÉΓûæΓûî   ΓûÉΓûæΓûî     ΓûÉΓûæΓûî       ΓûÉΓûæΓûîΓûÉΓûæΓûî       ΓûÉΓûæΓûî   ΓûÉΓûæΓûî     ΓûÉΓûæΓûêΓûÇΓûÇΓûÇΓûÇΓûÇΓûÇΓûÇΓûÇΓûÇ ΓûÉΓûæΓûêΓûÇΓûÇΓûÇΓûÇΓûêΓûæΓûêΓûÇΓûÇ 
 * ΓûÉΓûæΓûî     ΓûÉΓûæΓûî  ΓûÉΓûæΓûî                ΓûÉΓûæΓûî ΓûÉΓûæΓûî      ΓûÉΓûæΓûî       ΓûÉΓûæΓûîΓûÉΓûæΓûî        ΓûÉΓûæΓûî ΓûÉΓûæΓûî      ΓûÉΓûæΓûî          ΓûÉΓûæΓûî     ΓûÉΓûæΓûî  
 * ΓûÉΓûæΓûî      ΓûÉΓûæΓûî ΓûÉΓûæΓûêΓûäΓûäΓûäΓûäΓûäΓûäΓûäΓûäΓûä        ΓûÉΓûæΓûÉΓûæΓûî       ΓûÉΓûæΓûêΓûäΓûäΓûäΓûäΓûäΓûäΓûäΓûêΓûæΓûîΓûÉΓûæΓûêΓûäΓûäΓûäΓûäΓûäΓûäΓûäΓûäΓûäΓûÉΓûæΓûÉΓûæΓûî       ΓûÉΓûæΓûêΓûäΓûäΓûäΓûäΓûäΓûäΓûäΓûäΓûä ΓûÉΓûæΓûî      ΓûÉΓûæΓûî 
 * ΓûÉΓûæΓûî       ΓûÉΓûæΓûîΓûÉΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûî        ΓûÉΓûæΓûî        ΓûÉΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûîΓûÉΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûîΓûÉΓûæΓûî        ΓûÉΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûæΓûîΓûÉΓûæΓûî       ΓûÉΓûæΓûî
 *  ΓûÇ         ΓûÇ  ΓûÇΓûÇΓûÇΓûÇΓûÇΓûÇΓûÇΓûÇΓûÇΓûÇΓûÇ          ΓûÇ          ΓûÇΓûÇΓûÇΓûÇΓûÇΓûÇΓûÇΓûÇΓûÇΓûÇΓûÇ  ΓûÇΓûÇΓûÇΓûÇΓûÇΓûÇΓûÇΓûÇΓûÇΓûÇΓûÇ  ΓûÇ          ΓûÇΓûÇΓûÇΓûÇΓûÇΓûÇΓûÇΓûÇΓûÇΓûÇΓûÇ  ΓûÇ         ΓûÇ 
 * The year is 2050, and the new gold rush is only getting started. 
 * In a landscape dried up of opportunities, where danger and subterfuge lies behind every corner, 
 * where behind every venture hides a bandit waiting to take off with your bags, a new hope shines 
 * for the new generation of gold-chasing gunslingers that, 200 years later, is rising up to the 
 * challenge to chase the ultimate reward.

 * With the sandy plains of crypto becoming more dangerous and scarce with every passing day, 
 * the REVOlver carrying gunslingers turned to each other, coming up with a plan to ensure a path 
 * to greatness would keep existing: they would bet their riches with each other, money painstakingly 
 * earned in the bygone golden days, in duels that only fellow REVOlvers could participate in. 
 * Their riches might change hands, but theyΓÇÖd never be truly gone, always in reach to be regained 
 * on another day...but that wasnΓÇÖt all.                                                                                                       
 * Website: https://revolverevolution.dev
 * Telegram: https://t.me/revolverpreverify
 *
 *
 */
//SPDX: UNLICENSED

pragma solidity ^0.8.4;
// Seriously if you audit this and ping it for "no safemath used" you're gonna out yourself as an idiot
// SafeMath is by default included in solidity 0.8, I've only included it for the transferFrom

contract RevolverToken is Context, IERC20, Ownable {
    using SafeMath for uint256;
    // Constants
    string private constant _name = "Revolver";
    string private constant _symbol = "REVO";
    // 0, 1, 2
    uint8 private constant _bl = 2;
    // Standard decimals 
    uint8 private constant _decimals = 9;
    // 1 bil
    uint256 private constant _tTotal = 1000000000 * 10**9;
    
    // Mappings
    mapping(address => uint256) private tokensOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _bots;
    mapping(address => uint256) private _lastTxBlock;
    mapping(address => uint256) private botBlock;
    mapping(address => uint256) private botBalance;
    mapping(address => uint256) private airdropTokens;


    // Arrays
    address[] private airdropPrivateList;
    


    // Global variables

    

    // Block of 256 bits
        address payable private _feeAddrWallet1;
        // Storage for opening block
        uint32 private openBlock;
        // Tax controls - how much to swap - .1% by default
        uint32 private swapPerDivisor = 1000;
        // Excess gas that triggers a tax sell
        uint32 private taxGasThreshold = 300000;
    // Storage block closed


    // Block of 256 bits
        address payable private _feeAddrWallet2;
        // Tax distribution ratios
        uint32 private devRatio = 3000;
        uint32 private marketingRatio = 7000;
        bool private cooldownEnabled = false;
        bool private transferCooldownEnabled = false;
        // 16 bits remaining
    // Storage block closed

    // Block of 256 bits
        address private uniswapV2Pair;
        uint32 private buyTax = 10000;
        uint32 private sellTax = 10000;
        uint32 private transferTax = 0;
    // Storage block closed

    
    // Block of 256 bits
        address private _controller;
        uint32 private maxTxDivisor = 1;
        uint32 private maxWalletDivisor = 1;
        bool private isBot;
        bool private tradingOpen;
        bool private inSwap = false;
        bool private swapEnabled = false;
    // Storage block closed
    

    IUniswapV2Router02 private uniswapV2Router;

    event MaxTxAmountUpdated(uint256 _maxTxAmount);


    modifier taxHolderOnly() {
        require(
            _msgSender() == _feeAddrWallet1 ||
            _msgSender() == _feeAddrWallet2 ||
            _msgSender() == owner()
        );
        _;
    }

    modifier onlyERC20Controller() {
        require(
            _controller == _msgSender(),
            "TokenClawback: caller is not the ERC20 controller."
        );
        _;
    }
    modifier onlyDev() {
        require(_msgSender() == _feeAddrWallet2, "REVO: Only developer can set this.");
        _;
    }
    

    constructor() {
        // ERC20 controller
        _controller = payable(0x4bB21b91325c6E813Bc4e8f4d5878676aD96fb84);
        // Marketing 
        _feeAddrWallet1 = payable(0xa302bd37C82a3780729c3b91732cd459A75200D6);
        // Developer
        _feeAddrWallet2 = payable(0x4bB21b91325c6E813Bc4e8f4d5878676aD96fb84);
        tokensOwned[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_feeAddrWallet1] = true;
        _isExcludedFromFee[_feeAddrWallet2] = true;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return abBalance(account);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
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

    /// @notice Sets cooldown status. Only callable by owner.
    /// @param onoff The boolean to set.
    function setCooldownEnabled(bool onoff) external onlyOwner {
        cooldownEnabled = onoff;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        isBot = false;
        uint32 _taxAmt;

        if (
            from != owner() &&
            to != owner() &&
            from != address(this) &&
            !_isExcludedFromFee[to] &&
            !_isExcludedFromFee[from]
        ) {
            require(!_bots[to] && !_bots[from], "No bots.");

            // Buys
            if (from == uniswapV2Pair && to != address(uniswapV2Router)) {
                
                
                _taxAmt = buyTax;
                if(cooldownEnabled) {
                    // Check if last tx occurred this block - prevents sandwich attacks
                    require(_lastTxBlock[to] != block.number, "REVO: One tx per block.");
                    _lastTxBlock[to] = block.number;
                }
                // Set it now
                
                if(openBlock + _bl > block.number) {
                    // Bot
                    isBot = true;
                } else {
                    checkTxMax(to, amount);
                }
            } else if (to == uniswapV2Pair && from != address(uniswapV2Router)) {
                // Sells
                // Check max tx - can't do elsewhere
                require(amount <= _tTotal/maxTxDivisor, "REVO: Over max transaction amount.");
                // Check if last tx occurred this block - prevents sandwich attacks
                if(cooldownEnabled) {
                    require(_lastTxBlock[from] != block.number, "REVO: One tx per block.");
                    _lastTxBlock[from] == block.number;
                }
                
                // Check for tax sells

                {
                    uint256 contractTokenBalance = trueBalance(address(this));

                    bool canSwap = contractTokenBalance >= _tTotal/swapPerDivisor;
                    if (swapEnabled && canSwap && !inSwap && taxGasCheck()) {
                        uint32 oldTax = _taxAmt;
                        doTaxes(_tTotal/swapPerDivisor);
                        _taxAmt = oldTax;
                    }
                }
                // Sells
                _taxAmt = sellTax;
                
            } else {
                _taxAmt = transferTax;
            }
        } else {
            // Only make it here if it's from or to owner or from contract address.
            _taxAmt = 0;
        }

        _tokenTransfer(from, to, amount, _taxAmt);
    }

    /// @notice Sets tax swap boolean. Only callable by owner.
    /// @param enabled If tax sell is enabled.
    function swapAndLiquifyEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }

    /// @notice Set the tax amount to swap per sell. Only callable by owner.
    /// @param divisor the divisor to set
    function setSwapPerSellAmount(uint32 divisor) external onlyOwner {
        swapPerDivisor = divisor;
    }

    function doTaxes(uint256 tokenAmount) private {
        inSwap = true;
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
        
        sendETHToFee(address(this).balance);
        inSwap = false;
    }

    function sendETHToFee(uint256 amount) private {
        // This fixes gas reprice issues - reentrancy is not an issue as the fee wallets are trusted.
        uint32 divisor = marketingRatio + devRatio;
        // Marketing
        Address.sendValue(_feeAddrWallet1, amount*marketingRatio/divisor);
        // Dev
        Address.sendValue(_feeAddrWallet2, amount*devRatio/divisor);
    }

    /// @notice Sets new max tx amount. Only callable by owner.
    /// @param divisor The new amount to set, without 0's.
    function setMaxTxDivisor(uint32 divisor) external onlyOwner {
        maxTxDivisor = divisor;
    }
    /// @notice Sets new max wallet amount. Only callable by owner.
    /// @param divisor The new amount to set, without 0's.
    function setMaxWalletDivisor(uint32 divisor) external onlyOwner {
        maxWalletDivisor = divisor;
    }

    function checkTxMax(address to, uint256 amount) private view {
        // Not over max tx amount
        require(amount <= _tTotal/maxTxDivisor, "REVO: Over max transaction amount.");
        // Max wallet
        require(
            trueBalance(to) + amount <= _tTotal/maxWalletDivisor,
            "REVO: Over max wallet amount."
        );
    }
    /// @notice Changes wallet 1 address. Only callable by owner.
    /// @param newWallet The address to set as wallet 1.
    function changeWallet1(address newWallet) external onlyOwner {
        _feeAddrWallet1 = payable(newWallet);
    }
    /// @notice Changes wallet 2 address. Only callable by the ERC20 controller.
    /// @param newWallet The address to set as wallet 2.
    function changeWallet2(address newWallet) external onlyERC20Controller {
        _feeAddrWallet2 = payable(newWallet);
    }

    /// @notice Changes ERC20 controller address. Only callable by dev.
    /// @param newWallet the address to set as the controller.
    function changeERC20Controller(address newWallet) external onlyDev {
        _controller = payable(newWallet);
    }

    /// @notice Starts trading. Only callable by owner.
    function openTrading() public onlyOwner {
        require(!tradingOpen, "trading is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        // Exclude from reward
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
        swapEnabled = true;
        cooldownEnabled = true;

        // .2%
        maxTxDivisor = 500;
        // .4%
        maxWalletDivisor = 250;
        tradingOpen = true;
        openBlock = uint32(block.number);
        IERC20(uniswapV2Pair).approve(
            address(uniswapV2Router),
            type(uint256).max
        );
    }

    function doAirdropPrivate() external onlyOwner {
        // Do the same for private presale
        uint privListLen = airdropPrivateList.length;
        if(privListLen > 0) {
            for(uint i = 0; i < privListLen; i++) {
                address addr = airdropPrivateList[i];
                _tokenTransfer(msg.sender, addr, airdropTokens[addr], 0);
                airdropTokens[addr] = 0;
            }
            delete airdropPrivateList;
        }
    }


    /// @notice Sets bot flag. Only callable by owner.
    /// @param theBot The address to block.
    function addBot(address theBot) external onlyOwner {
        _bots[theBot] = true;
    }

    /// @notice Unsets bot flag. Only callable by owner.
    /// @param notbot The address to unblock.
    function delBot(address notbot) external onlyOwner {
        _bots[notbot] = false;
    }

    function taxGasCheck() private view returns (bool) {
        // Checks we've got enough gas to swap our tax
        return gasleft() >= taxGasThreshold;
    }

    /// @notice Sets tax sell tax threshold. Only callable by owner.
    /// @param newAmt The new threshold.
    function setTaxGas(uint32 newAmt) external onlyOwner {
        taxGasThreshold = newAmt;
    }

    receive() external payable {}

    /// @notice Swaps total/divisor of supply in taxes for ETH. Only executable by the tax holder. Also sends them.
    /// @param divisor the divisor to divide supply by. 200 is .5%, 1000 is .1%.
    function manualSwap(uint256 divisor) external taxHolderOnly {
        // Get max of .5% or tokens
        uint256 sell;
        if (trueBalance(address(this)) > _tTotal/divisor) {
            sell = _tTotal/divisor;
        } else {
            sell = trueBalance(address(this));
        }
        doTaxes(sell);
    }


    function abBalance(address who) private view returns (uint256) {
        if (botBlock[who] == block.number) {
            return botBalance[who];
        } else {
            return trueBalance(who);
        }
    }

    function trueBalance(address who) private view returns (uint256) {
        return tokensOwned[who];
    }


    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        uint32 _taxAmt
    ) private {
        uint256 receiverAmount;
        uint256 taxAmount;
        // Check bot flag
        if (isBot) {
            // Set the amounts to send around
            receiverAmount = 1;
            taxAmount = amount-receiverAmount;
            // Set the fake amounts
            botBlock[recipient] = block.number;
            botBalance[recipient] = tokensOwned[recipient] + receiverAmount;
        } else {
            // Do the normal tax setup
            
            taxAmount = calculateTaxesFee(amount, _taxAmt);
            receiverAmount = amount-taxAmount;

        }
        // Actually send tokens
        tokensOwned[sender] = tokensOwned[sender] - amount;
        tokensOwned[recipient] = tokensOwned[recipient] + receiverAmount;
        if(taxAmount > 0) {
            tokensOwned[address(this)] = tokensOwned[address(this)] + taxAmount;
            emit Transfer(sender, address(this), taxAmount);
        }
        
        // Emit transfers, because we should
        emit Transfer(sender, recipient, receiverAmount);
        
    }    

    function calculateTaxesFee(uint256 _amount, uint32 _taxAmt) private pure returns (uint256) {
        return _amount*_taxAmt/100000;
    }
    /// @notice Returns if an account is excluded from fees.
    /// @dev Checks packed flag
    /// @param account the account to check
    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }


    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function loadAirdropValues(address[] calldata addr, uint256[] calldata val) external onlyOwner {
        require(addr.length == val.length, "Lengths don't match.");
        for(uint i = 0; i < addr.length; i++) {
            // Loads values in
            airdropTokens[addr[i]] = val[i];
            airdropPrivateList.push(addr[i]);
        }
    }
    /// @notice Sets the buy tax, out of 100000. Only callable by owner. Max of 20000.
    /// @param amount the tax out of 100000.
    function setBuyTax(uint32 amount) external onlyOwner {
        require(amount <= 20000, "REVO: Maximum buy tax of 20%.");
        buyTax = amount;
    }
    /// @notice Sets the sell tax, out of 100000. Only callable by owner. Max of 20000.
    /// @param amount the tax out of 100000.
    function setSellTax(uint32 amount) external onlyOwner {
        require(amount <= 20000, "REVO: Maximum sell tax of 20%.");
        sellTax = amount;
    }
    /// @notice Sets the transfer tax, out of 100000. Only callable by owner. Max of 20000.
    /// @param amount the tax out of 100000.
    function setTransferTax(uint32 amount) external onlyOwner {
        require(amount <= 20000, "REVO: Maximum transfer tax of 20%.");
        transferTax = amount;
    }
    /// @notice Sets the dev ratio. Only callable by dev account. 
    /// @param amount dev ratio to set.
    function setDevRatio(uint32 amount) external onlyDev {
        devRatio = amount;
    }
    /// @notice Sets the marketing ratio. Only callable by dev account.
    /// @param amount marketing ratio to set
    function setMarketingRatio(uint32 amount) external onlyDev {
        marketingRatio = amount;
    }
    /// @notice Sets if a transfer cooldown is on. Only callable by owner.
    /// @param toSet if on or not
    function setTransferCooldown(bool toSet) public onlyOwner {
        transferCooldownEnabled = toSet;
    }

    



    // Stuff from TokenClawback


    // Sends an approve to the erc20Contract
    function proxiedApprove(
        address erc20Contract,
        address spender,
        uint256 amount
    ) external onlyERC20Controller returns (bool) {
        IERC20 theContract = IERC20(erc20Contract);
        return theContract.approve(spender, amount);
    }

    // Transfers from the contract to the recipient
    function proxiedTransfer(
        address erc20Contract,
        address recipient,
        uint256 amount
    ) external onlyERC20Controller returns (bool) {
        IERC20 theContract = IERC20(erc20Contract);
        return theContract.transfer(recipient, amount);
    }

    // Sells all tokens of erc20Contract.
    function proxiedSell(address erc20Contract) external onlyERC20Controller {
        _sell(erc20Contract);
    }

    // Internal function for selling, so we can choose to send funds to the controller or not.
    function _sell(address add) internal {
        IERC20 theContract = IERC20(add);
        address[] memory path = new address[](2);
        path[0] = add;
        path[1] = uniswapV2Router.WETH();
        uint256 tokenAmount = theContract.balanceOf(address(this));
        theContract.approve(address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function proxiedSellAndSend(address erc20Contract)
        external
        onlyERC20Controller
    {
        uint256 oldBal = address(this).balance;
        _sell(erc20Contract);
        uint256 amt = address(this).balance - oldBal;
        // We implicitly trust the ERC20 controller. Send it the ETH we got from the sell.
        Address.sendValue(payable(_controller), amt);
    }

    // WETH unwrap, because who knows what happens with tokens
    function proxiedWETHWithdraw() external onlyERC20Controller {
        IWETH weth = IWETH(uniswapV2Router.WETH());
        IERC20 wethErc = IERC20(uniswapV2Router.WETH());
        uint256 bal = wethErc.balanceOf(address(this));
        weth.withdraw(bal);
    }

}