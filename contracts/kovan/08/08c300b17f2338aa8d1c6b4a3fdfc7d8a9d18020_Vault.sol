/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

// SPDX-License-Identifier: MIT

// File: src/interfaces/IMasterChef.sol



pragma solidity 0.8.4;

interface IMasterChef {
    function poolInfo(uint256 poolId)
        external
        view
        returns (
            address lpToken,
            uint256 allocPoint,
            uint256 lastRewardTime,
            uint256 accRewardPerShare
        );

    function userInfo(uint256 poolId, address user) external view returns (uint256 amount, uint256 rewardDebt);

    function pendingReward(uint256 _pid, address _user) external view returns (uint256);

    function deposit(uint256 poolId, uint256 amount) external;

    function withdraw(uint256 poolId, uint256 amount) external;

    function reward() external view returns (address);

    function add(
        uint256 _allocPoint,
        address _lpToken,
        bool _withUpdate
    ) external;
}
// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

// File: src/interfaces/IUniswapV2Pair.sol



pragma solidity 0.8.4;
interface IUniswapV2Pair {
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
}
// File: src/interfaces/IUniswapV2Router.sol



pragma solidity 0.8.4;

interface IUniswapV2Router {
    function factory() external pure returns (address);
    function WBNB() external pure returns (address);

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
    function addLiquidityBNB(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountBNBMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountBNB, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityBNB(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountBNBMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountBNB);
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
    function removeLiquidityBNBWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountBNBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountBNB);
    function removeLiquidityBNBSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountBNBMin,
        address to,
        uint deadline
    ) external returns (uint amountBNB);
    function removeLiquidityBNBWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountBNBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountBNB);
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
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactBNBForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForBNBSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactBNBForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactBNB(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForBNB(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapBNBForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
// File: src/interfaces/IVault.sol



pragma solidity 0.8.4;

interface IVault {
  function owner() external view returns (address);

  function wantAddress() external view returns (address);

  function balanceInFarm() external view returns (uint256);

  function pending() external view returns (uint256);

  function compound() external;

  function claimRewards() external;

  function deposit(uint256 _wantAmt) external returns (uint256);

  function withdraw(uint256 _wantAmt) external returns (uint256);

  function withdrawAll() external returns (uint256);

  function updateSlippage(uint256 _slippage) external;

  function rescueFund(address _token, uint256 _amount) external;
}

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: src/interfaces/IWETH.sol


pragma solidity 0.8.4;


interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}
// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

// File: src/vaults/VaultBase.sol



pragma solidity 0.8.4;






abstract contract VaultBase is IVault, ReentrancyGuard {
  using SafeERC20 for IERC20;

  uint256 internal constant RATIO_PRECISION = 1000000; // 6 decimals
  address internal constant weth = 0xd0A1E359811322d97991E03f863a0C30C2cF029C; // kovan weth

  address public override owner; // the only address can deposit, withdraw
  address public harvestor; // this address can call earn method
  uint256 public lastEarnBlock;
  address public override wantAddress;
  uint256 public slippage = 50000; // 5%

  // =========== events ================================

  event Earned(address indexed _earnedToken, uint256 _amount);
  event Deposited(uint256 _amount);
  event Withdraw(uint256 _amount);
  event Exit(uint256 _lpAmount);

  constructor() {
    owner = msg.sender;
    harvestor = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "!owner");
    _;
  }

  modifier onlyHarvestor() {
    require(
      msg.sender == harvestor || msg.sender == owner,
      "!owner && !harvestor"
    );
    _;
  }

  modifier canHarvest() {
    require(msg.sender == owner, "!owner && !harvester");
    _;
  }

  // =========== restricted functions =================

  function updateSlippage(uint256 _slippage) public virtual override onlyOwner {
    slippage = _slippage;
  }

  function setHarvestor(address _harvestor) external onlyOwner {
    require(_harvestor != address(0x0), "cannot address set to zero");
    harvestor = _harvestor;
  }

  function claimRewards() external virtual override;

  // =========== internal functions ==================

  function _safeSwap(
    address _swapRouterAddress,
    uint256 _amountIn,
    uint256 _slippage,
    address[] memory _path,
    address _to,
    uint256 _deadline
  ) internal {
    IUniswapV2Router _swapRouter = IUniswapV2Router(_swapRouterAddress);
    require(_path.length > 0, "invalidSwapPath");
    uint256[] memory amounts = _swapRouter.getAmountsOut(_amountIn, _path);
    uint256 _minAmountOut = (amounts[amounts.length - 1] *
      (RATIO_PRECISION - _slippage)) / RATIO_PRECISION;

    _swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
      _amountIn,
      _minAmountOut,
      _path,
      _to,
      _deadline
    );
  }

  function _unwrapETH() internal {
    // WETH -> ETH
    uint256 wethBalance = IERC20(weth).balanceOf(address(this));
    if (wethBalance > 0) {
      IWETH(weth).withdraw(wethBalance);
    }
  }

  function _wrapETH() internal {
    // ETH -> WETH
    uint256 ethBalance = address(this).balance;
    if (ethBalance > 0) {
      IWETH(weth).deposit{ value: ethBalance }();
    }
  }

  function _isWETH(address _token) internal pure returns (bool) {
    return _token == weth;
  }

  // =========== emergency functions =================

  function rescueFund(address _token, uint256 _amount)
    public
    virtual
    override
    onlyOwner
  {
    IERC20(_token).safeTransfer(owner, _amount);
  }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


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

// File: src/vaults/Vault.sol



pragma solidity 0.8.4;









contract Vault is VaultBase {
  using SafeERC20 for IERC20;

  IMasterChef public masterChef;

  uint256 public poolId;
  address public token0;
  address public token1;
  address public rewardToken;
  address public swapRouter;

  address[] public earnedToToken0Path;
  address[] public earnedToToken1Path;
  address[] public token0ToEarnedPath;
  address[] public token1ToEarnedPath;

  uint256 public swapTimeout;

  constructor(
    address _swapRouter,
    IMasterChef _masterChef,
    uint256 _poolId
  ) VaultBase() {
    swapRouter = _swapRouter;
    masterChef = _masterChef;
    poolId = _poolId;
    (wantAddress, , , ) = _masterChef.poolInfo(poolId);
    rewardToken = _masterChef.reward();
    token0 = IUniswapV2Pair(address(wantAddress)).token0();
    token1 = IUniswapV2Pair(address(wantAddress)).token1();
    token0ToEarnedPath = [token0, rewardToken];
    token1ToEarnedPath = [token1, rewardToken];
    earnedToToken0Path = [rewardToken, token0];
    earnedToToken1Path = [rewardToken, token1];
  }

  // ========== views =================

  function balanceInFarm() public view override returns (uint256) {
    (uint256 _amount, ) = masterChef.userInfo(poolId, address(this));
    return _amount;
  }

  function pending() public view override returns (uint256) {
    return masterChef.pendingReward(poolId, address(this));
  }

  // ========== vault core functions ===========

  function compound() external override onlyHarvestor {
    // Harvest farm tokens
    uint256 _initBalance = balanceInFarm();
    _widthdrawFromFarm(0);

    if (_isWETH(rewardToken)) {
      _wrapETH();
    }

    // Converts farm tokens into want tokens
    uint256 earnedAmt = IERC20(rewardToken).balanceOf(address(this));

    if (rewardToken != token0) {
      _swap(rewardToken, token0, earnedAmt / 2, earnedToToken0Path);
    }

    if (rewardToken != token1) {
      _swap(rewardToken, token1, earnedAmt / 2, earnedToToken1Path);
    }

    IERC20 _token0 = IERC20(token0);
    IERC20 _token1 = IERC20(token1);
    // Get want tokens, ie. add liquidity
    uint256 token0Amt = _token0.balanceOf(address(this));
    uint256 token1Amt = _token1.balanceOf(address(this));
    if (token0Amt > 0 && token1Amt > 0) {
      _token0.safeIncreaseAllowance(swapRouter, token0Amt);
      _token1.safeIncreaseAllowance(swapRouter, token1Amt);
      IUniswapV2Router(swapRouter).addLiquidity(
        token0,
        token1,
        token0Amt,
        token1Amt,
        0,
        0,
        address(this),
        block.timestamp + swapTimeout
      );
    }

    lastEarnBlock = block.number;

    _depositToFarm();
    _cleanUp();

    uint256 _afterBalance = balanceInFarm();
    if (_afterBalance > _initBalance) {
      emit Earned(wantAddress, _afterBalance - _initBalance);
    } else {
      emit Earned(wantAddress, 0);
    }
  }

  function deposit(uint256 _wantAmt)
    public
    override
    onlyOwner
    nonReentrant
    returns (uint256)
  {
    IERC20(wantAddress).safeTransferFrom(
      address(msg.sender),
      address(this),
      _wantAmt
    );
    _depositToFarm();
    return _wantAmt;
  }

  function withdrawAll()
    external
    override
    onlyOwner
    returns (uint256 _withdrawBalance)
  {
    uint256 _balance = balanceInFarm();
    _withdrawBalance = withdraw(_balance);
    _cleanUp();
    _withdrawFromVault();
    emit Exit(_withdrawBalance);
  }

  function withdraw(uint256 _wantAmt)
    public
    override
    onlyOwner
    nonReentrant
    returns (uint256)
  {
    require(_wantAmt > 0, "_wantAmt <= 0");
    _widthdrawFromFarm(_wantAmt);
    uint256 _balance = IERC20(rewardToken).balanceOf(address(this));
    _withdrawFromVault();
    return _balance;
  }

  function claimRewards() external override onlyOwner {
    _widthdrawFromFarm(0);
    uint256 _balance = IERC20(rewardToken).balanceOf(address(this));
    if (_balance > 0) {
      IERC20(rewardToken).safeTransfer(msg.sender, _balance);
    }
  }

  function _withdrawFromVault() internal {
    uint256 _dustRewardBal = IERC20(rewardToken).balanceOf(address(this));
    if (_dustRewardBal > 0) {
      IERC20(rewardToken).safeTransfer(msg.sender, _dustRewardBal);
    }
    uint256 _wantBalance = IERC20(wantAddress).balanceOf(address(this));
    if (_wantBalance > 0) {
      IERC20(wantAddress).safeTransfer(msg.sender, _wantBalance);
    }
  }

  function _cleanUp() internal {
    // Converts dust tokens into reward tokens, which will be reinvested on the next compound().
    // Converts token0 dust (if any) to reward tokens
    uint256 token0Amt = IERC20(token0).balanceOf(address(this));
    if (token0 != rewardToken && token0Amt > 0) {
      _swap(token0, rewardToken, token0Amt, token0ToEarnedPath);
    }

    // Converts token1 dust (if any) to reward tokens
    uint256 token1Amt = IERC20(token1).balanceOf(address(this));
    if (token1 != rewardToken && token1Amt > 0) {
      _swap(token1, rewardToken, token1Amt, token1ToEarnedPath);
    }
  }

  function _depositToFarm() internal onlyOwner {
    IERC20 wantToken = IERC20(wantAddress);
    uint256 wantAmt = wantToken.balanceOf(address(this));
    wantToken.safeIncreaseAllowance(address(masterChef), wantAmt);
    masterChef.deposit(poolId, wantAmt);
    emit Deposited(wantAmt);
  }

  function _widthdrawFromFarm(uint256 _wantAmt) internal {
    masterChef.withdraw(poolId, _wantAmt);
    emit Withdraw(_wantAmt);
  }

  function _swap(
    address _inputToken,
    address _outputToken,
    uint256 _inputAmount,
    address[] memory _path
  ) internal {
    if (_inputAmount == 0) {
      return;
    }
    require(_path[0] == _inputToken, "Route must start with src token");
    require(
      _path[_path.length - 1] == _outputToken,
      "Route must end with dst token"
    );
    IERC20(_inputToken).safeApprove(swapRouter, 0);
    IERC20(_inputToken).safeApprove(swapRouter, _inputAmount);
    _safeSwap(
      swapRouter,
      _inputAmount,
      slippage,
      _path,
      address(this),
      block.timestamp + swapTimeout
    );
  }
}