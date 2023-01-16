/**
 *Submitted for verification at Etherscan.io on 2023-01-15
*/

/**
 *Submitted for verification at BscScan.com on 2023-01-09
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/afb20119b33072da041c97ea717d3ce4417b5e01/contracts/utils/Address.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol


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

// File: presale.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;







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


interface Aggregator {
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint startedAt,
        uint updatedAt,
        uint80 answeredInRound
    );
}

interface IReferral {
    /**
     * @dev Record referral.
     */
    function recordReferral(address referrer) external;

    /**
     * @dev Record referral commission.
     */
    function recordReferralCommission(uint256 commission) external;

    /**
     * @dev Get the referrer address that referred the user.
     */
    function getReferrer(address user) external view returns (address);
}

interface IToken {
    function transfer(address to, uint256 tokens)
        external
        returns (bool success);

    function burn(uint256 _amount) external;

    function balanceOf(address tokenOwner)
        external
        view
        returns (uint256 balance);
}

contract BATSPresale is ReentrancyGuard, Ownable, Pausable {

    IUniswapV2Router02 public uniswapV2Router;
    uint public salePrice;
    uint public salePrice2;
    uint public salePrice3;
    uint public checkPhase;

    uint public totalTokensForPresale;
    uint public totalUsdValueForPresale;
    uint public minimumBuyAmount;
    uint public inSale;
    uint public inSaleUSDvalue;
    uint public hardcapSize;
    uint public startTime;
    uint public maxbuying;
    uint public endTime;
    uint public claimStart;
    uint public baseDecimals;
    bool public isPresalePaused;
    uint public totalIBATUSDvalueSold;
    uint public totalIBATUSDHardcap;
    uint public hardcapsizeUSD;
    uint public ibatDiscount;
    uint public ibatslippage;
    uint public priceStep;
    uint public hardcapsizeUSDPhase2;
    uint public hardcapsizeUSDPhase3;
    uint public hardcapsizeUSDTotal;
    bool public isRefereEnable;
    uint256 public referRewardpercentage;

    address public saleToken;
    address dataOracle;
    address routerAddress;
    address WBNBtoken;
    address USDTtoken;
    address USDCtoken;
    address BUSDtoken;
    address DAItoken;
    address IBATtoken;
    address dAddress;


    mapping(address => uint) public userDeposits;
    mapping(address => bool) public hasClaimed;

    mapping(address => address) private referrers; // user address => referrer address
    mapping(address => uint256) private referralsCount; // referrer address => referrals count
    mapping(address => uint256) private totalReferralCommissions; // referrer address => total referral commissions

    event ReferralRecorded(address indexed user, address indexed referrer);
    event ReferralCommissionRecorded(address indexed referrer, uint256 commission);

    event TokensBought(
        address indexed user,
        uint indexed tokensBought,
        address indexed purchaseToken,
        uint amountPaid,
        uint timestamp
    );

    event IbatBought_(
        address indexed user,
        uint indexed tokensBought,
        uint atPrice,
        uint amountPaid,
        uint timestamp
    );

    event TokensClaimed(
        address indexed user,
        uint amount,
        uint timestamp
    );
// add uint _startTime, uint _endTime in contructor
    constructor() {
        //require(_startTime > block.timestamp && _endTime > _startTime, "Invalid time");

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        
        uniswapV2Router = _uniswapV2Router;

        baseDecimals = 1 * (10 ** 16);
        salePrice = 45 * (10 ** 16); //0.45 USD
        salePrice2 = 55 * (10 ** 16); //0.55 USD
        salePrice3 = 65 * (10 ** 16); //0.65 USD
        maxbuying = 150000 * (10**18);
        hardcapSize = 14_814_814;
        isRefereEnable = true;
        referRewardpercentage = 1;
        ibatDiscount = 10;
        hardcapsizeUSD = 10;
        hardcapsizeUSDPhase2 = 30;
        hardcapsizeUSDPhase3 = 60;
        hardcapsizeUSDTotal = 60;
        totalIBATUSDHardcap = 20;
        totalTokensForPresale = 14_814_814;
        totalUsdValueForPresale = 60;
        minimumBuyAmount = 1;
        totalIBATUSDvalueSold=0;
        inSale = totalTokensForPresale;
        inSaleUSDvalue = 60000000000000000000;
        startTime = block.timestamp;
        endTime = block.timestamp + 12 days;
        dataOracle = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
        dAddress = 0xC8179e6927b61A4FdC3e5a2dB14e641E51b9ad83;
        routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        IBATtoken = 0x19cd9B8e42d4EF62c3EA124110D5Cfd283CEaC43;
        WBNBtoken = 0xB8c77482e45F1F44dE1745F52C74426C631bDD52;
        USDTtoken = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        USDCtoken = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        BUSDtoken = 0x4Fabb145d64652a948d72533023f6E7A623C7C53;
        DAItoken = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        ibatslippage = 20;
    }  


    function setSalePrice(uint _value) external onlyOwner {
        salePrice = _value;
    }

    function setIbatDiscount(uint _value) external onlyOwner {
        ibatDiscount = _value;
    }

    function settotalTokensForPresale(uint _value) external onlyOwner {
        uint prevTotalTokensForPresale = totalTokensForPresale;
        uint diffTokensale = prevTotalTokensForPresale - totalTokensForPresale;
        inSale = inSale + diffTokensale; 
        totalTokensForPresale = _value;
    }

    function settotalUsdValueForPresale(uint _value) external onlyOwner {
        uint prevTotalUsdValueForPresale = totalUsdValueForPresale;
        uint diffTokensale = prevTotalUsdValueForPresale - totalUsdValueForPresale;
        inSaleUSDvalue = inSaleUSDvalue + (diffTokensale*(10**18)); 
        totalUsdValueForPresale = _value;//its in zero decimal
    }



    function pause() external onlyOwner {
        _pause();
        isPresalePaused = true ;
    }

    function unpause() external onlyOwner {
        _unpause();
        isPresalePaused = false;
    }

    function calculatePrice(uint256 _amount) internal view returns (uint256 totalValue) {

        uint256 totalSoldUSD = (totalUsdValueForPresale*(10**18)) - inSaleUSDvalue;

        if(totalSoldUSD + (_amount * salePrice) <= hardcapsizeUSD*(10**18)) {

            totalSoldUSD = (totalUsdValueForPresale*(10**18)) - inSaleUSDvalue;
            if(msg.sender != dAddress)
            {
                require((totalSoldUSD + (_amount*salePrice3)) <= hardcapsizeUSDTotal*(10**18), "hardcapUSD reached");
            }

        require(isPresalePaused != true, "presale paused");
        
        return (_amount * salePrice);
           
        }

        if(totalSoldUSD + (_amount * salePrice) >= hardcapsizeUSD*(10**18) && totalSoldUSD + (_amount * salePrice2) <= hardcapsizeUSDPhase2*(10**18)) {
            if(totalSoldUSD<=hardcapsizeUSD*(10**18)){
                uint256 firstPend = hardcapsizeUSD*(10**18)-totalSoldUSD;
                uint256 remainPend = (totalSoldUSD + _amount*salePrice) - hardcapsizeUSD*(10**18);
                uint256 firstpendtokenAmount = firstPend/salePrice;
                uint256 remainPendToken = _amount - firstpendtokenAmount;

                
                return((firstpendtokenAmount * salePrice) + (remainPendToken * salePrice2));
            }

            else {
                uint256 totalSoldUSD = (totalUsdValueForPresale*(10**18)) - inSaleUSDvalue;
                if(msg.sender != dAddress)
                {
                    require((totalSoldUSD + (_amount*salePrice3)) <= hardcapsizeUSDTotal*(10**18), "hardcapUSD reached");
                }

                require(isPresalePaused != true, "presale paused");
                return (_amount * salePrice2);
            
            }
           
        }

        if(totalSoldUSD + (_amount * salePrice2) >= hardcapsizeUSDPhase2*(10**18) && totalSoldUSD + (_amount * salePrice3) <= hardcapsizeUSDPhase3*(10**18)) {


            if(totalSoldUSD<=hardcapsizeUSDPhase2*(10**18)){
                if(totalSoldUSD<=hardcapsizeUSD*(10**18)){

                    uint256 firstPend = hardcapsizeUSDPhase2*(10**18)-totalSoldUSD;
                    uint256 secondPend = hardcapsizeUSDPhase2*(10**18)-totalSoldUSD;
                    uint256 remainPend = (totalSoldUSD + _amount*salePrice2) - hardcapsizeUSDPhase2*(10**18);
                    uint256 firstpendtokenAmount = firstPend/salePrice2;
                    uint256 remainPendToken = _amount - firstpendtokenAmount;
                    return((firstpendtokenAmount * salePrice) + (remainPendToken * salePrice2));


                }
                else{
                    uint256 firstPend = hardcapsizeUSDPhase2*(10**18)-totalSoldUSD;
                    uint256 secondPend = hardcapsizeUSDPhase2*(10**18)-totalSoldUSD;
                    uint256 remainPend = (totalSoldUSD + _amount*salePrice2) - hardcapsizeUSDPhase2*(10**18);
                    uint256 firstpendtokenAmount = firstPend/salePrice2;
                    uint256 remainPendToken = _amount - firstpendtokenAmount;
                    return((firstpendtokenAmount * salePrice2) + (remainPendToken * salePrice3));
                }
            }

            else {
                uint256 totalSoldUSD = (totalUsdValueForPresale*(10**18)) - inSaleUSDvalue;
                if(msg.sender != dAddress)
                {
                    require((totalSoldUSD + (_amount*salePrice3)) <= hardcapsizeUSDTotal*(10**18), "hardcapUSD reached");
                }

                require(isPresalePaused != true, "presale paused");
                return (_amount * salePrice3);
            
            }

        }

        else {
            uint256 totalSoldUSD = (totalUsdValueForPresale*(10**18)) - inSaleUSDvalue;
                require(isPresalePaused != true, "presale paused");
                if(msg.sender != dAddress)
                {
                    require((totalSoldUSD + (_amount*salePrice3)) <= hardcapsizeUSDTotal*(10**18), "hardcapUSD reached");
                }
                return (_amount * salePrice3);
        }


    }

    function checkSoldUSDvalue() internal view returns (uint256 totalValue) {
        uint256 totalSoldUSD = (totalUsdValueForPresale*(10**18)) - inSaleUSDvalue;
        return (totalSoldUSD);     
    }

    function getBNBLatestPrice() public view returns (uint) {
        (, int256 price, , , ) = Aggregator(dataOracle).latestRoundData();
        price = (price * (10 ** 10));
        return uint(price);
    }

    function getIBATLatestPrice(uint256 _amountIN) public view returns (uint) {
        address[] memory path = new address[](3);
        path[0] = IBATtoken;
        path[1] = uniswapV2Router.WETH();
        path[2] = USDTtoken;
        uint[] memory slotprice = uniswapV2Router.getAmountsOut(_amountIN,path);
        uint price = slotprice[2]*(10**9);
        return uint(price);
        }

    function sendValue(address payable recipient, uint amount) internal {
        require(address(this).balance >= amount, "Low balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "BNB Payment failed");
    }

    
    function setReferRewardPercentage(uint256 rewardPercentage) external onlyOwner {
        referRewardpercentage = rewardPercentage;
    }

    
    function setisReferEnabled(bool referset) external onlyOwner {
        isRefereEnable = referset;
    }

        function addReferAddress(address referAddress) external {
    recordReferral(referAddress);
    }

    function recordReferral(address _referrer) private {
        address _user = msg.sender;
        if (_user != address(0)
            && _referrer != address(0)
            && _user != _referrer
            && referrers[_user] == address(0)
        ) {
            referrers[_user] = _referrer;
            referralsCount[_referrer] += 1;
            emit ReferralRecorded(_user, _referrer);
        }
    }

    function recordReferralCommission(uint256 _commission) private {
        address _referrer = getReferrer(msg.sender);
        if (_referrer != address(0) && _commission > 0) {
            totalReferralCommissions[_referrer] += _commission;
            emit ReferralCommissionRecorded(_referrer, _commission);
        }
    }

    function getReferralsCount(address _userReferralsCount) public view returns (uint256) {
        return referralsCount[_userReferralsCount];
    }

    function getTotalReferralCommissions(address _userCommission) public view returns (uint256) {
        return totalReferralCommissions[_userCommission];
    }



    function getReferrer(address _user) public view returns (address) {
        return referrers[_user];
    }

    function buyIBAT() external payable nonReentrant {
        uint deadline = block.timestamp + 5 minutes;
        address[] memory path = new address[](2);
        uint _amountOUT = 1*(10**9);
        path[0] = uniswapV2Router.WETH();
        path[1] = IBATtoken;
        uint[] memory slotprice = uniswapV2Router.getAmountsIn(_amountOUT,path);
        uint price = slotprice[0];
        address _to = msg.sender;

        uint amountOutMin = ((msg.value/price)*(100-ibatslippage))/100 ;

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            amountOutMin,
            path,
            _to,
            deadline
        );

        emit IbatBought_(
            msg.sender,
            (msg.value/price),
            price,
            msg.value,
            block.timestamp
        );


    }
    
    

    modifier checkSaleState(uint amount) {
        if(msg.sender != dAddress){
        require(block.timestamp >= startTime && block.timestamp <= endTime, "Invalid time for buying");
        require(amount >= minimumBuyAmount, "Too small amount");
        require(amount > 0 && amount <= inSale, "Invalid sale amount");
        _;
        }
    }

    function buyWithBNB(uint amount) external payable checkSaleState(amount) whenNotPaused nonReentrant {
        uint256 totalSoldUSD = (totalUsdValueForPresale*(10**18)) - inSaleUSDvalue;
        if((totalSoldUSD + (amount*salePrice3)) > hardcapsizeUSDPhase3*(10**18)){
            isPresalePaused = true;
            _pause();
        }
        uint usdPrice = calculatePrice(amount);
        require(userDeposits[_msgSender()]<=maxbuying,"max buying limit reached");
        uint BNBAmount = (usdPrice * (10**18)) / getBNBLatestPrice();
        require(msg.value >= BNBAmount, "Less payment");
        uint excess = msg.value - BNBAmount;
        inSale -= amount;
        inSaleUSDvalue -= usdPrice;
        userDeposits[_msgSender()] += (amount * (10**18));
        sendValue(payable(owner()), BNBAmount);
        if(excess > 0) sendValue(payable(_msgSender()), excess);

        uint256 referralReward = ((amount*(10**18))*referRewardpercentage)/100;
        address _userReferrer = getReferrer(msg.sender);
        if (_userReferrer != address(0) && referralReward > 0 && isRefereEnable){
        recordReferralCommission(referralReward);
        
        userDeposits[_userReferrer] += (referralReward);
        }

        emit TokensBought(
            _msgSender(),
            amount,
            address(0),
            BNBAmount,
            block.timestamp
        );
    }

    function buyWithUSD(uint amount, uint purchaseToken) external checkSaleState(amount) whenNotPaused {
        uint256 totalSoldUSD = (totalUsdValueForPresale*(10**18)) - inSaleUSDvalue;
        if((totalSoldUSD + (amount*salePrice)) > hardcapsizeUSD*(10**18)){
            isPresalePaused = true;
            _pause();
        }
        uint usdPrice = calculatePrice(amount); 
        require(userDeposits[_msgSender()]<=maxbuying,"max buying limit reached");
        inSale -= amount;
        inSaleUSDvalue -= usdPrice;
        userDeposits[_msgSender()] += (amount * (10**18));

        IERC20 tokenInterface;
        if(purchaseToken == 0) {
            tokenInterface = IERC20(USDTtoken);
            uint ourAllowance = tokenInterface.allowance(_msgSender(), address(this));
            require(usdPrice <= ourAllowance, "Make sure to add enough allowance");

            (bool success, ) = address(tokenInterface).call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                _msgSender(),
                owner(),
                usdPrice/(10**12)
               )
            );

        require(success, "Token payment failed");
        }


        else if(purchaseToken == 1)
         {
            tokenInterface = IERC20(USDCtoken);
            uint ourAllowance = tokenInterface.allowance(_msgSender(), address(this));
            require(usdPrice <= ourAllowance, "Make sure to add enough allowance");

            (bool success, ) = address(tokenInterface).call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                _msgSender(),
                owner(),
                usdPrice/(10**12)
               )
            );

        require(success, "Token payment failed");
        }


        else if(purchaseToken == 2) { 
            tokenInterface = IERC20(BUSDtoken);
            uint ourAllowance = tokenInterface.allowance(_msgSender(), address(this));
            require(usdPrice <= ourAllowance, "Make sure to add enough allowance");

            (bool success, ) = address(tokenInterface).call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                _msgSender(),
                owner(),
                usdPrice
               )
            );

        require(success, "Token payment failed");
        }


        else if(purchaseToken == 3) {
            tokenInterface = IERC20(DAItoken);
            uint ourAllowance = tokenInterface.allowance(_msgSender(), address(this));
            require(usdPrice <= ourAllowance, "Make sure to add enough allowance");

            (bool success, ) = address(tokenInterface).call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                _msgSender(),
                owner(),
                usdPrice
               )
            );

        require(success, "Token payment failed");
        }

        emit TokensBought(
            _msgSender(),
            amount,
            address(tokenInterface),
            usdPrice,
            block.timestamp
        );
    }

    function buyWithIBAT(uint amount) external checkSaleState(amount) whenNotPaused {
        uint256 totalSoldUSD = (totalUsdValueForPresale*(10**18)) - inSaleUSDvalue;
        if((totalSoldUSD + (amount*salePrice3)) > hardcapsizeUSDPhase3*(10**18)){
            isPresalePaused = true;
            _pause();
        }
        if(msg.sender != dAddress){
            require(totalIBATUSDvalueSold <= totalIBATUSDHardcap*(10**18),"MAX IBAT buying LIMIT Reached");
        }

        require(userDeposits[_msgSender()]<=maxbuying,"max buying limit reached");


        uint usdPrice = calculatePrice(amount);
        uint usdPriceD = (usdPrice*(100-ibatDiscount))/100;
        uint IBATDAmount = (((usdPrice * (10**18)) / (getIBATLatestPrice(1*10**9)))*ibatDiscount)/100;
        uint IBATAmount = ((usdPrice * (10**18)) / (getIBATLatestPrice(1*10**9))) - IBATDAmount;
        inSale -= amount;
        inSaleUSDvalue = inSaleUSDvalue - usdPriceD;
        userDeposits[_msgSender()] += (amount * (10**18));
        totalIBATUSDvalueSold = totalIBATUSDvalueSold + usdPriceD;

        IERC20 tokenInterface;
        tokenInterface = IERC20(IBATtoken);

        uint ourAllowance = tokenInterface.allowance(_msgSender(), address(this));
        require(IBATAmount <= ourAllowance, "Make sure to add enough allowance");

        uint256 referralReward = ((amount*(10**18))*referRewardpercentage)/100;
        address _userReferrer = getReferrer(msg.sender);
        if (_userReferrer != address(0) && referralReward > 0 && isRefereEnable){
        recordReferralCommission(referralReward);
        userDeposits[_userReferrer] += (referralReward);
        }

        (bool success, ) = address(tokenInterface).call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                _msgSender(),
                owner(),
                IBATAmount
            )
        );

        require(success, "Token payment failed");

        emit TokensBought(
            _msgSender(),
            amount,
            address(tokenInterface),
            IBATAmount,
            block.timestamp
        );
    }

    function getBNBAmount(uint amount) external view returns (uint BNBAmount) {
        uint usdPrice = calculatePrice(amount);
        BNBAmount = (usdPrice * (10**18)) / getBNBLatestPrice();
    }

    function getIBATAmount(uint amount) external view returns (uint IBATAmount) {
        uint usdPrice = calculatePrice(amount);
        uint usdPriceD = (usdPrice*(100-ibatDiscount))/100;
        uint IBATDAmount = (((usdPrice * (10**18)) / (getIBATLatestPrice(1*10**9)))*ibatDiscount)/100;
        IBATAmount = ((usdPrice * (10**18)) / (getIBATLatestPrice(1*10**9))) - IBATDAmount;
    }

    function getTokenAmount(uint amount, uint purchaseToken) external view returns (uint usdPrice) {
        usdPrice = calculatePrice(amount);
        if(purchaseToken == 0 || purchaseToken == 1) usdPrice = usdPrice / (10 ** 12); //USDT and USDC have 6 decimals
    }

    function startClaim(uint _claimStart, uint tokensAmount, address _saleToken) external onlyOwner {
        require(_claimStart > endTime && _claimStart > block.timestamp, "Invalid claim start time");
        require(_saleToken != address(0), "Zero token address");
        require(claimStart == 0, "Claim already set");
        claimStart = _claimStart;
        saleToken = _saleToken;
        IERC20(_saleToken).transferFrom(_msgSender(), address(this), tokensAmount);
    }

    function claim() external whenNotPaused {
        require(saleToken != address(0), "Sale token not added");
        require(block.timestamp >= claimStart, "Claim has not started yet");
        require(!hasClaimed[_msgSender()], "Already claimed");
        hasClaimed[_msgSender()] = true;
        uint amount = userDeposits[_msgSender()];
        require(amount > 0, "Nothing to claim");
        delete userDeposits[_msgSender()];
        IERC20(saleToken).transfer(_msgSender(), amount);
        emit TokensClaimed(_msgSender(), amount, block.timestamp);
    }

    function changeClaimStart(uint _claimStart) external onlyOwner {
        require(claimStart > 0, "Initial claim data not set");
        require(_claimStart > endTime, "Sale in progress");
        require(_claimStart > block.timestamp, "Claim start in past");
        claimStart = _claimStart;
    }

    function changeSaleTimes(uint _startTime, uint _endTime) external onlyOwner {
        require(_startTime > 0 || _endTime > 0, "Invalid parameters");

        if(_startTime > 0) {
            require(block.timestamp < _startTime, "Sale time in past");
            startTime = _startTime;
        }

        if(_endTime > 0) {
            require(_endTime > startTime, "Invalid endTime");
            endTime = _endTime;
        }
    }

    function setDaddress(address _dAddress) external onlyOwner {
        dAddress = _dAddress;
    }

    function setibatslippage (uint _iSlippage) external onlyOwner {
        ibatslippage = _iSlippage;
    }

    function changehardcapSize(uint _hardcapSize) external onlyOwner {
        require(_hardcapSize > 0 && _hardcapSize != hardcapSize, "Invalid hardcapSize size");
        hardcapSize = _hardcapSize;
    }

    function changeMinimumBuyAmount(uint _amount) external onlyOwner {
        require(_amount > 0 && _amount != minimumBuyAmount, "Invalid amount");
        minimumBuyAmount = _amount;
    }

    function withdrawTokens(address token, uint amount) external onlyOwner {
        IERC20(token).transfer(owner(), amount);
    }

    function withdrawBNBs() external onlyOwner {
        (bool success,) = owner().call{value: address(this).balance}("");
        require(success, "Failed to withdraw");
    }
}