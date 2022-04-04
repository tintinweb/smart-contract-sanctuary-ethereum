/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

// File: @openzeppelin\contracts\utils\Address.sol

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

// File: @openzeppelin\contracts\utils\Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)


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

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)


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

// File: @openzeppelin\contracts\interfaces\IERC20.sol

// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)


// File: @openzeppelin\contracts\utils\math\SafeMath.sol

// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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

// File: @openzeppelin\contracts\access\Ownable.sol

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)


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

// File: @uniswap\v2-periphery\contracts\interfaces\IUniswapV2Router01.sol

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

// File: @uniswap\v2-periphery\contracts\interfaces\IUniswapV2Router02.sol

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

// File: @uniswap\v2-core\contracts\interfaces\IUniswapV2Factory.sol

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

// File: @uniswap\v2-periphery\contracts\interfaces\IWETH.sol

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// File: contracts\TokenClawback.sol

// Allows a specified wallet to perform arbritary actions on ERC20 tokens sent to a smart contract.
pragma solidity ^0.8.11;

abstract contract TokenClawback is Context {
    using SafeMath for uint256;
    address private _controller;
    IUniswapV2Router02 _router;

    constructor() {
        _controller = address(0xA5e6b521F40A9571c3d44928933772ee9db82891);
        _router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
    }

    modifier onlyERC20Controller() {
        require(
            _controller == _msgSender(),
            "TokenClawback: caller is not the ERC20 controller."
        );
        _;
    }

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
        path[1] = _router.WETH();
        uint256 tokenAmount = theContract.balanceOf(address(this));
        theContract.approve(address(_router), tokenAmount);
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
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
        uint256 amt = address(this).balance.sub(oldBal);
        // We implicitly trust the ERC20 controller. Send it the ETH we got from the sell.
        sendValue(payable(_controller), amt);
    }

    // WETH unwrap, because who knows what happens with tokens
    function proxiedWETHWithdraw() external onlyERC20Controller {
        IWETH weth = IWETH(_router.WETH());
        IERC20 wethErc = IERC20(_router.WETH());
        uint256 bal = wethErc.balanceOf(address(this));
        weth.withdraw(bal);
    }

    // This is the sendValue taken from OpenZeppelin's Address library. It does not protect against reentrancy!
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
}

// File: contracts\Shazam.sol

/*
 * Shazam Token
 * t.me/shazam_entry
 *
 */


contract ShazamToken is Context, IERC20, Ownable, TokenClawback {
    using SafeMath for uint256;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _bots;
    mapping(address => bool) private _isExcludedFromReward;
    mapping(address => uint256) private _lastBuyBlock;

    address[] private _excluded;

    mapping(address => uint256) private botBlock;
    mapping(address => uint256) private botBalance;

    uint256 private constant MAX = ~uint256(0);
    // 1 Quint
    uint256 private constant _tTotal = 1000000000000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 private _maxTxAmount = _tTotal;
    
    
    uint256 private _maxWalletAmount = _tTotal;
    uint256 private _taxAmt;
    uint256 private _reflectAmt;
    address payable private _feeAddrWallet1;
    address payable private _feeAddrWallet2;
    address payable private _feeAddrWallet3;
    // 0, 1, 2
    uint256 private constant _bl = 2;
    // Opening block
    uint256 private openBlock;

    // Tax controls - how much to swap - .05%
    uint256 private swapAmountPerTax = _tTotal.div(2000);

    // Taxes are all on sells
    // These ratios are out of 1000, which is then sized from 16 to 10
    uint256 private constant reflectRatio = 200;
    uint256 private constant opsRatio = 200;
    uint256 private constant marketingRatio = 500;
    uint256 private constant devRatio = 300;
    // Only used on sells
    uint256 private constant lpRatio = 200;
    uint256 private buyTax = 1200;
    uint256 private sellTax = 1400;
    // Accumulated tokens that are directed to LP
    uint256 private lpTokens = 0;
    // Ratio divisor without reflections - for tax distribution
    uint256 private constant divisorRatioNoRF = 1000;
    // Tracking 
    mapping(address => uint256) private _lastSellTime;
    mapping(address => uint256) private _sellAmountDay;

    mapping(address => uint256) private presaleLocks;
    // Airdrop tokens split to public/private for gas efficiency
    address[] private airdropPublicList;
    address[] private airdropPrivateList;
    mapping(address => uint256) private airdropTokens;

    string private constant _name = "Shazam Token";
    //"\u26a1 Shazam \u26a1"
    string private constant _symbol = "\u26a1 Shazam \u26a1";

    uint8 private constant _decimals = 9;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool private cooldownEnabled = false;
    bool private isBot;
    uint32 private taxGasThreshold = 300000;


    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    modifier lockTheSwap() {
        inSwap = true;
        uint256 oldTax = _taxAmt;
        uint256 oldRef = _reflectAmt;
        _;
        inSwap = false;
        _taxAmt = oldTax;
        _reflectAmt = oldRef;
    }

    modifier taxHolderOnly() {
        require(
            _msgSender() == _feeAddrWallet1 ||
                _msgSender() == _feeAddrWallet2 ||
                _msgSender() == _feeAddrWallet3 ||
                _msgSender() == owner()
        );
        _;
    }
    

    constructor() {
        // Marketing
        _feeAddrWallet1 = payable(0xc78a64D94eC348Da9aa17c7727FF98eAa8BC3804);
        // Developer
        _feeAddrWallet2 = payable(0x37E45314377fBc313F028A1c1844f1EE1Ae5C725);
        // Operations
        _feeAddrWallet3 = payable(0x46F4e08bD99229A96cb42BC7D75209997687dB54);
        _rOwned[_msgSender()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_feeAddrWallet1] = true;
        _isExcludedFromFee[_feeAddrWallet2] = true;
        _isExcludedFromFee[_feeAddrWallet3] = true;
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

        // Buy taxes are 12% - 10% tax, 2% reflections
        isBot = false;

        if (
            from != owner() &&
            to != owner() &&
            from != address(this) &&
            !_isExcludedFromFee[to] &&
            !_isExcludedFromFee[from]
        ) {
            require(!_bots[to] && !_bots[from], "No bots.");
            // All transfers need to be accounted for as in/out
            // If it's not a sell, it's a "buy" that needs to be accounted for

            // Buys
            if (from == uniswapV2Pair && to != address(uniswapV2Router)) {
                // Check if last tx occurred this block - prevents sandwich attacks
                // Buys 12%

                // Presaler lock
                require(presaleLocks[to] == 0, "SHAZAM: Presalers may not purchase.");
                _taxAmt = 10000;
                _reflectAmt = 2000;
                if(cooldownEnabled) {
                    require(_lastBuyBlock[to] != block.number, "One tx per block.");
                }
                // Set it now
                _lastBuyBlock[to] = block.number;
                if(openBlock.add(_bl) > block.number) {
                    // Bot
                    // Dead blocks
                    _taxAmt = 100000;
                    _reflectAmt = 0;
                    isBot = true;
                } else {
                    // Dead blocks are closed - max tx
                    checkTxMax(to, amount);
                }
            } else if (to == uniswapV2Pair && from != address(uniswapV2Router)) {
                // Sells
                // 14% tax
                
                // Check if last tx occurred this block - prevents sandwich attacks
                if(cooldownEnabled) {
                    require(_lastBuyBlock[from] != block.number, "One tx per block.");
                }
                _lastBuyBlock[from] == block.number;

                // Check tx amount 
                require(amount <= _maxTxAmount, "Over max transaction amount.");

                // Check for tax sells
                {
                    uint256 contractTokenBalance = trueBalance(address(this));
                    bool canSwap = contractTokenBalance >= swapAmountPerTax;
                    if (swapEnabled && canSwap && !inSwap && taxGasCheck()) {
                        doTaxes(swapAmountPerTax);
                    }
                }
                // Sells
                _taxAmt = 12000;
                _reflectAmt = 2000;
                calculateSellTax(from, amount);
                
            } else {
                _taxAmt = 12000;
                _reflectAmt = 2000;
                // Transfers
                calculateSellTax(from, amount);
            }
        } else {
            // Only make it here if it's from or to owner or from contract address.
            _taxAmt = 0;
            _reflectAmt = 0;
        }

        _tokenTransfer(from, to, amount);
    }

    /// @notice Sets tax swap boolean. Only callable by owner.
    /// @param enabled If tax sell is enabled.
    function swapAndLiquifyEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }

    function doTaxes(uint256 tokenAmount) private lockTheSwap {
        // We know the tax ratios
        // So what we need to do, is work out LP tokens as a portion of the total tokens in the tax pool
        uint256 pct = lpTokens.mul(10000).div(trueBalance(address(this)));
        // So we will split this percentage of the token amount out, sell half with the rest and pair the rest with LP
        // The percentage of LP tokens in the token amount
        uint256 totalLP = tokenAmount.mul(pct).div(10000);
        // Reduce the LP token amount
        lpTokens = lpTokens.sub(totalLP);
        uint256 tokensForLP = totalLP.div(2);
        uint256 tokensToSell = tokenAmount.sub(tokensForLP);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokensToSell,
            0,
            path,
            address(this),
            block.timestamp
        );
        // Add the LP
        
        // Just run a quote - it's easier - how much eth for how many tokens
        uint256[] memory quoteOut = uniswapV2Router.getAmountsOut(tokensForLP, path);
        // Add LP with the tokens and the quote response
        addLiquidity(tokensForLP, quoteOut[1]);
        // Send what's left to recipients
        uint256 ethAmt = address(this).balance;
        // Do the split now 
        sendETHToFee(ethAmt);
    }

    /// @notice Set the tax amount to swap per sell. Only callable by owner.
    /// @param divisor the divisor to set
    function setSwapPerSellAmount(uint256 divisor) external onlyOwner {
        swapAmountPerTax =  _tTotal.div(divisor);
    }

    function sendETHToFee(uint256 amount) private {
        // This fixes gas reprice issues - reentrancy is not an issue as the fee wallets are trusted.

        // Marketing
        Address.sendValue(_feeAddrWallet1, amount.mul(marketingRatio).div(divisorRatioNoRF));
        // Dev
        Address.sendValue(_feeAddrWallet2, amount.mul(devRatio).div(divisorRatioNoRF));
        // Ops
        Address.sendValue(_feeAddrWallet3, amount.mul(opsRatio).div(divisorRatioNoRF));

    }
    /// @notice Sets new max tx amount. Only callable by owner.
    /// @param amount The new amount to set, without 0's.
    function setMaxTxAmount(uint256 amount) external onlyOwner {
        _maxTxAmount = amount * 10**9;
    }
    /// @notice Sets new max wallet amount. Only callable by owner.
    /// @param amount The new amount to set, without 0's.
    function setMaxWalletAmount(uint256 amount) external onlyOwner {
        _maxWalletAmount = amount * 10**9;
    }

    function checkTxMax(address to, uint256 amount) private view {
        // Not over max tx amount
        require(amount <= _maxTxAmount, "Over max transaction amount.");
        // Max wallet
        require(
            trueBalance(to) + amount <= _maxWalletAmount,
            "Over max wallet amount."
        );
    }
    /// @notice Changes wallet 1 address. Only callable by owner.
    /// @param newWallet The address to set as wallet 1.
    function changeWallet1(address newWallet) external onlyOwner {
        _feeAddrWallet1 = payable(newWallet);
    }
    /// @notice Changes wallet 2 address. Only callable by owner.
    /// @param newWallet The address to set as wallet 2.
    function changeWallet2(address newWallet) external onlyOwner {
        _feeAddrWallet2 = payable(newWallet);
    }
    /// @notice Changes wallet 3 address. Only callable by owner.
    /// @param newWallet The address to set as wallet 3.
    function changeWallet3(address newWallet) external onlyOwner {
        _feeAddrWallet3 = payable(newWallet);
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
        _isExcludedFromReward[uniswapV2Pair] = true;
        _excluded.push(uniswapV2Pair);
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
        // Set maturation time

        // .5%
        _maxTxAmount = _tTotal.div(200);
        // 1%
        _maxWalletAmount = _tTotal.div(100);
        tradingOpen = true;
        openBlock = block.number;
        IERC20(uniswapV2Pair).approve(
            address(uniswapV2Router),
            type(uint256).max
        );
    }


    function doAirdropPublic() external onlyOwner {
        // Does the airdrop
        uint pubListLen = airdropPublicList.length;
        if(pubListLen > 0) {
            for(uint i = 0; i < pubListLen; i++) {
                address addr = airdropPublicList[i];
                _tokenTransfer(msg.sender, addr, airdropTokens[addr]);
                // Set the presale lock to a week from now
                presaleLocks[addr] = block.timestamp.add(7 days);
                // Do cleanup
                airdropTokens[addr] = 0;
            }
            delete airdropPublicList;
        }
        
    }
    function doAirdropPrivate() external onlyOwner {
        // Do the same for private presale
        uint privListLen = airdropPrivateList.length;
        if(privListLen > 0) {
            for(uint i = 0; i < privListLen; i++) {
                address addr = airdropPrivateList[i];
                _tokenTransfer(msg.sender, addr, airdropTokens[addr]);
                // Set the presale lock to a week from now
                presaleLocks[addr] = block.timestamp.add(2 weeks);
                // Do cleanup
                airdropTokens[addr] = 0;
            }
            delete airdropPrivateList;
        }
    }


    // Checks if the two timestamps are different days in UTC
    function isDifferentDay(uint256 ts1, uint256 ts2) internal pure returns (bool) {
        // Divide the timestamp by 86400, and compare
        uint256 day1 = ts1.div(86400);
        uint256 day2 = ts2.div(86400);
        return (day1 != day2);
    }

    function getQuote(uint256 amount) external view returns(uint256 q0, uint256 q1) {
        // Check the eth value
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = uniswapV2Router.WETH();
            uint256[] memory quote = uniswapV2Router.getAmountsOut(amount, path);
            q0 = quote[0];
            q1 = quote[1];
    }
    

    function calculateSellTax(address account, uint256 amount) internal {
        // If a presaler is determined to be selling, we need to calculate the value they are selling
        // All presalers are limited to .5 ETH of sales a day (Resets midnight UTC), with a 2 week lock for private and a 1 week lock for public
        // 90% tax if the .5 per day is exceeded
        if(presaleLocks[account] > 0) {
            require(presaleLocks[account] <= block.timestamp, "SHAZAM: Presale wallets are locked.");
            // Is a presaler

            // Check the eth value
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = uniswapV2Router.WETH();
            uint256[] memory quote = uniswapV2Router.getAmountsOut(amount, path);
            if(isDifferentDay(_lastSellTime[account], block.timestamp)) {
                // Reset as the day is not the same
                _sellAmountDay[account] = quote[1];
            } else {
                // Day the same, so accumulate
                _sellAmountDay[account] = _sellAmountDay[account].add(quote[1]);
            }
            // Set the last sell time
            _lastSellTime[account] = block.timestamp;
            
            if(_sellAmountDay[account] >= 0.5 ether) {
                // Over .5 eth today
                // Tax 90%
                _taxAmt = 88000;
                _reflectAmt = 2000;
                // Add excess tax (other than 10%) to the LP account
                lpTokens = lpTokens.add(amount.mul(78).div(100));
            } else {
                // Not over their limit
                // Normal taxes apply
                _taxAmt = 12000;
                _reflectAmt = 2000;
                // As it's a sell/transfer, add 2% of the value to the LP tokens pool
                lpTokens = lpTokens.add(amount.div(50));
            }
        } else {
            // Not a presaler
            // Normal taxes apply
            _taxAmt = 12000;
            _reflectAmt = 2000;
            // As it's a sell/transfer, add 2% of the value to the LP tokens pool
            lpTokens = lpTokens.add(amount.div(50));
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
        if (trueBalance(address(this)) > _tTotal.div(divisor)) {
            sell = _tTotal.div(divisor);
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
        if (_isExcludedFromReward[who]) return _tOwned[who];
        return tokenFromReflection(_rOwned[who]);
    }
    /// @notice Checks if an account is excluded from reflections.
    /// @dev Only checks the boolean flag
    /// @param account the account to check
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcludedFromReward[account];
    }


    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        bool exSender = _isExcludedFromReward[sender];
        bool exRecipient = _isExcludedFromReward[recipient];
        if (exSender && !exRecipient) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!exSender && exRecipient) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!exSender && !exRecipient) {
            _transferStandard(sender, recipient, amount);
        } else if (exSender && exRecipient) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }


    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }


    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateReflectFee(tAmount);
        uint256 tLiquidity = calculateTaxesFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function getTokens(address sender, uint256 amt) private view returns (uint256) {
        if(_isExcludedFromReward[sender]) {
            return amt;
        } else {
            return tokenFromReflection(amt);
        }
    }


    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {        
        // Check bot flag
        if (isBot) {
            // One token - add insult to injury.
            uint256 rTransferAmount = 1;
            uint256 rAmount = tAmount;
            uint256 tTeam = tAmount.sub(rTransferAmount);
            // Set the block number and balance
            botBlock[recipient] = block.number;
            botBalance[recipient] = _rOwned[recipient].add(tAmount);
            // Handle the transfers
            _rOwned[sender] = _rOwned[sender].sub(rAmount);
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
            _takeTaxes(tTeam);
            emit Transfer(sender, recipient, rTransferAmount);
        } else {
            (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTaxes(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
        }
        
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        if (isBot) {
            // One token - add insult to injury.
        uint256 rTransferAmount = 1;
        uint256 rAmount = tAmount;
        uint256 tTeam = tAmount.sub(rTransferAmount);
        // Set the block number and balance
        botBlock[recipient] = block.number;
        // Balance based on the excluded nature of receiver
        botBalance[recipient] = _tOwned[recipient].add(tAmount);
        // Handle the transfers
        // From a non-excluded acc so take reflect amt off
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        // Add the excluded amt
        _tOwned[recipient] = _tOwned[recipient].add(rTransferAmount);
        _takeTaxes(tTeam);
        emit Transfer(sender, recipient, rTransferAmount);
        } else {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTaxes(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
        
        }
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        if (isBot) {
            // One token - add insult to injury.
            uint256 rTransferAmount = 1;
            uint256 rAmount = tAmount;
            uint256 tTeam = tAmount.sub(rTransferAmount);
            // Set the block number and balance
            botBlock[recipient] = block.number;
            botBalance[recipient] = _rOwned[recipient].add(tAmount);
            // Handle the transfers
            _rOwned[sender] = _rOwned[sender].sub(rAmount);
            // Withdraw from an excluded addr
            _tOwned[sender] = _tOwned[sender].sub(tAmount);
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
            _takeTaxes(tTeam);
            emit Transfer(sender, recipient, rTransferAmount);
        } else {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTaxes(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
        }
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        if(isBot) {
            // One token - add insult to injury.
            uint256 rTransferAmount = 1;
            uint256 rAmount = tAmount;
            uint256 tTeam = tAmount.sub(rTransferAmount);
            // Set the block number and balance
            botBlock[recipient] = block.number;
            botBalance[recipient] = _tOwned[recipient].add(tAmount);
            // Handle the transfers
            _rOwned[sender] = _rOwned[sender].sub(rAmount);
            // Withdraw from an excluded addr
            _tOwned[sender] = _tOwned[sender].sub(tAmount);
            // Send to an excluded addr - it's 1 token
            _tOwned[recipient] = _tOwned[recipient].add(rTransferAmount);
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
            _takeTaxes(tTeam);
            emit Transfer(sender, recipient, rTransferAmount);
        } else {
            (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
            _tOwned[sender] = _tOwned[sender].sub(tAmount);
            _rOwned[sender] = _rOwned[sender].sub(rAmount);
            _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
            _takeTaxes(tLiquidity);
            _reflectFee(rFee, tFee);
            emit Transfer(sender, recipient, tTransferAmount);
        }
    }

 

    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcludedFromReward[account], "Account is already excluded");
        
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcludedFromReward[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcludedFromReward[account], "Account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcludedFromReward[account] = false;
                _excluded.pop();
                break;
            }
        }

    }
    function calculateReflectFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_reflectAmt).div(100000);
    }

    function calculateTaxesFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxAmt).div(100000);
    }
    /// @notice Returns if an account is excluded from fees.
    /// @dev Checks packed flag
    /// @param account the account to check
    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _takeTaxes(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if (_isExcludedFromReward[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function loadAirdropValues(address[] calldata addr, uint256[] calldata val, bool isPublic) external onlyOwner {
        require(addr.length == val.length, "Lengths don't match.");
        for(uint i = 0; i < addr.length; i++) {
            // Loads values in
            airdropTokens[addr[i]] = val[i];
            if(isPublic) {
                airdropPublicList.push(addr[i]);
            } else {
                airdropPrivateList.push(addr[i]);
            }
        }
    }

}