/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

//
/// @title Interface for Sushi Masterchef
// https://soliditydeveloper.com/sushi-swap
interface ISushiMasterChef {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. SUSHIs to distribute per block.
        uint256 lastRewardBlock; // Last block number that SUSHIs distribution occurs.
        uint256 accSushiPerShare; // Accumulated SUSHIs per share, times 1e12.
    }

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function poolInfo(uint256 _pid) external view returns (PoolInfo memory);

    function poolLength() external view returns (uint256);

    function sushi() external view returns (address);

    function pendingSushi(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function updatePool(uint256 _pid) external;

    function sushiPerBlock() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function getMultiplier(uint256 _from, uint256 _to)
        external
        view
        returns (uint256);

    function userInfo(uint256 pid, address user)
        external
        returns (UserInfo memory);
}

//
interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

//
/// @title Interface for Sushi SLP strategy config
interface ISushiSlpStrategyConfig {
    event CurrentFeeChanged(uint256 newMinFee);
    event MinFeeChanged(uint256 newMinFee);
    event MaxFeeChanged(uint256 newMaxFee);
    event FeeAddressSet(
        address indexed owner,
        address indexed newAddr,
        address indexed oldAddr
    );
    event SushiTokenSet(
        address indexed owner,
        address indexed newAddr,
        address indexed oldAddr
    );
    event SlpTokenSet(
        address indexed owner,
        address indexed newAddr,
        address indexed oldAddr
    );
    event MasterChefSet(
        address indexed owner,
        address indexed newAddr,
        address indexed oldAddr
    );

    event PidSet(
        address indexed owner,
        uint256 indexed newVal,
        uint256 indexed oldVal
    );

    event WethTokenSet(
        address indexed owner,
        address indexed newAddr,
        address indexed oldAddr
    );

    event KeeperSet(
        address indexed owner,
        address indexed newAddr,
        address indexed oldAddr
    );

    event RouterSet(
        address indexed owner,
        address indexed newAddr,
        address indexed oldAddr
    );

    event RewardTokenSet(
        address indexed owner,
        address indexed newAddr,
        address indexed oldAddr
    );

    event RewardTokenStatusChange(
        address indexed owner,
        address indexed token,
        bool whitelisted
    );

    event StrategyAddressSet(
        address indexed owner,
        address indexed newAddr,
        address indexed oldAddr
    );

    event BridgeManagerAddressSet(
        address indexed owner,
        address indexed newAddr,
        address indexed oldAddr
    );

    /// @notice Event emitted withdrawal is paused
    event WithdrawalPaused(address indexed owner);
    /// @notice Event emitted withdrawal is resumed
    event WithdrawalResumed(address indexed owner);

    /// @notice Deposit method temporary data
    struct DepositTemporaryData {
        bool isAssetWeth;
        uint256 half;
        uint256[] swappedAmounts;
        address tokenA;
        address tokenB;
        uint256 amountADesired;
        uint256 amountBDesired;
        uint256 amountAMin;
        uint256 amountBMin;
        uint256 usedA;
        uint256 usedB;
        uint256 liquidity;
        uint256 toRefundA;
        uint256 toRefundB;
        uint256 pendingSushiTokens;
        address tokenOut;
    }
    /// @notice Transfer temporary data
    struct TransferLpTemporaryData {
        uint256 amountToTransfer;
        address transferredToken;
        uint256 totalWethAmount;
        uint256 amountIn;
        address tokenIn;
        uint256[] swapAmounts;
        uint256 amountA;
        uint256 amountB;
    }

    /// @notice Withdraw temporary data
    struct TemporaryWithdrawData {
        bool isEth;
        bool isSlp;
        ISushiMasterChef masterChef;
        uint256 pid;
        address sushiToken;
        uint256 totalSushi;
        uint256 slpAmount;
        uint256 wethAmount;
        uint256 amountA;
        uint256 amountB;
        uint256 prevEthBalance;
        uint256 afterEthBalance;
        uint256 totalEth;
    }

    /// @notice Remove liquidity temporary data
    struct RemoveLiquidityTempData {
        address tokenA;
        address tokenB;
        uint256 amountA;
        uint256 amountB;
    }

    function wethToken() external view returns (address);

    function sushiToken() external view returns (address);

    function slpToken() external view returns (address);

    function pid() external view returns (uint256);

    function masterChef() external view returns (ISushiMasterChef);

    function router() external view returns (IUniswapV2Router02);

    function keeper() external view returns (address);

    function whitelistedRewardTokens(address asset)
        external
        view
        returns (bool);

    function getRewardTokensArray() external view returns (address[] memory);

    function feeAddress() external view returns (address);

    function minFee() external view returns (uint256);

    function maxFee() external view returns (uint256);

    function currentFee() external view returns (uint256);

    function isToken0Weth() external view returns (bool);

    function isToken1Weth() external view returns (bool);

    function isWithdrawalPaused() external view returns (bool);

    function strategyAddress() external view returns (address);

    function bridgeManager() external view returns (address);

    function resumeWithdrawal() external;

    function pauseWithdrawal() external;
}

//
/// @title Interface for Sushi SLP strategy
interface ISushiSlpStrategy {
    /// @notice Event emitted when emergency save is triggered
    event EmergencySaveTriggered(address indexed owner);

    /// @notice Event emitted when a deposit is made
    event Deposit(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 slpAmount
    );

    event ReceiveBackLPs(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 slpAmount
    );

    /// @notice Event emitted for withdrawal
    event Withdraw(
        address indexed user,
        address indexed asset,
        uint256 slpAmount,
        uint256 assetAmount
    );

    struct WithdrawParamData {
        uint256 _assetMinAmount;
        bool _claimOtherRewards;
    }

    /// @notice struct containing user information
    struct UserInfo {
        uint256 sushiRewardDebt; // Reward debt for Sushi rewards. See explanation below.
        uint256 userAccumulatedSushi; //how many rewards this user has
        uint256 slpAmount; // How many SLP tokens the user has provided.
    }

    function userInfo(address _user)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function totalAmountOfLPs() external view returns (uint256);

    function sushiConfig() external view returns (ISushiSlpStrategyConfig);

    function getPendingRewards(address _user) external view returns (uint256);

    function transferLPs(
        uint256 bridgeId,
        uint256 destinationNetworkId,
        bool unwrap,
        uint256 amount,
        uint256 wethMinAmount,
        uint256 _deadline,
        uint256 _amountAMin,
        uint256 _amountBMin,
        bytes calldata _data
    ) external returns (uint256);

    function receiveBackLPs(
        uint256 _amount,
        address _asset,
        uint256 _deadline,
        uint256 _swapTokenOutMin
    ) external;

    function deposit(
        uint256 _amount,
        address _asset,
        uint256 _deadline,
        uint256 _swapTokenOutMin
    ) external payable;

    function withdraw(
        uint256 _amount,
        address _asset,
        uint256 _deadline,
        uint256 _amountAMin,
        uint256 _amountBMin,
        uint256 _wethMinAmount
    ) external;
}

//
/// @title Interface for SLP token
interface ISushiLpToken {
    function token0() external view returns (address);

    function token1() external view returns (address);
}

//
interface IWeth {
    function deposit() external payable;

    function withdraw(uint256 _wad) external;

    function balanceOf(address _account) external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
}

//
interface IBridgeManager {
    function transferERC20(
        uint256 _bridgeId,
        uint256 _destinationNetworkId,
        address _tokenIn,
        uint256 _amount,
        address _destinationAddress,
        bytes calldata _data
    ) external;

    function getBridgeAddress(uint256 _bridgeId) external returns (address);

    function isNetworkSupported(uint256 _bridgeId, uint256 _networkId)
        external
        returns (bool);
}

//
/**
 * Created on 2021-06-07 08:50
 */
library FeeOperations {
    uint256 internal constant FEE_FACTOR = 10000;

    function getFeeAbsolute(uint256 amount, uint256 fee)
        internal
        pure
        returns (uint256)
    {
        return (amount * fee) / FEE_FACTOR;
    }

    function getRatio(
        uint256 numerator,
        uint256 denominator,
        uint256 precision
    ) internal pure returns (uint256) {
        if (numerator == 0 || denominator == 0) {
            return 0;
        }
        uint256 _numerator = numerator * 10**(precision + 1);
        uint256 _quotient = ((_numerator / denominator) + 5) / 10;
        return (_quotient);
    }

    /// @notice Save approve token for spending on contract
    /// @param token Token's address
    /// @param to Contract's address
    /// @param value Amount
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "ERR::safeApprove: approve failed"
        );
    }

    /// @notice Safe transfer ETH to address
    /// @param to Contract's address
    /// @param value Contract's address
    /// @param value Amount
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "ERR::safeTransferETH: ETH transfer failed");
    }
}

//
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

//
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

//
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)
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

//
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
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
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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

//
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)
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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

//
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)
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

//
//TODO:
// - tests
// -toRefundA/toRefundB
/// @notice User should be able to enter with either Tricrypto LP or any of the assets underlying (one must be WETH)
contract SushiSlpStrategy is ISushiSlpStrategy, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice the config's contract address
    ISushiSlpStrategyConfig public override sushiConfig;

    /// @notice info for each user.
    mapping(address => UserInfo) public override userInfo;

    /// @notice total amount of LPs the strategy has
    uint256 public override totalAmountOfLPs;

    /// @notice Constructor
    /// @param _config the config's contract address
    constructor(address _config) {
        require(_config != address(0), "ERR: INVALID CONFIG");
        sushiConfig = ISushiSlpStrategyConfig(_config);
    }

    //-----------------
    //----------------- Owner methods -----------------
    //-----------------

    /// @notice Save funds from the contract
    /// @param _token Tokens's address
    /// @param _amount Tokens's amount
    function emergencySave(address _token, uint256 _amount) external onlyOwner {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        require(_amount <= balance, "ERR: BALANCE");
        IERC20(_token).safeTransfer(msg.sender, _amount);
        emit EmergencySaveTriggered(msg.sender);
    }

    //-----------------
    //----------------- View methods -----------------
    //-----------------
    /// @notice Return current reward amount for user
    /// @param _user User's address
    /// @return Reward amount
    function getPendingRewards(address _user)
        public
        view
        override
        returns (uint256)
    {
        ISushiMasterChef masterChef = sushiConfig.masterChef();
        UserInfo storage user = userInfo[_user];
        ISushiMasterChef.PoolInfo memory sushiPool = masterChef.poolInfo(
            sushiConfig.pid()
        );
        uint256 lpSupply = sushiPool.lpToken.balanceOf(address(masterChef));

        if (block.number > sushiPool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = masterChef.getMultiplier(
                sushiPool.lastRewardBlock,
                block.number
            );
            uint256 sushiReward = (multiplier *
                masterChef.sushiPerBlock() *
                sushiPool.allocPoint) / masterChef.totalAllocPoint();
            sushiPool.accSushiPerShare =
                sushiPool.accSushiPerShare +
                ((sushiReward * (1e12)) / lpSupply);
        }

        uint256 accumulatedSushi = (user.slpAmount *
            sushiPool.accSushiPerShare) / (1e12);

        if (accumulatedSushi < user.sushiRewardDebt) {
            return 0;
        }

        return accumulatedSushi - user.sushiRewardDebt;
    }

    //-----------------
    //----------------- Non-view methods -----------------
    //-----------------
    /// @notice Deposit token0, token1, ETH, or the SLP
    /// @param _amount Deposited amount
    /// @param _asset Deposited asset
    /// @param _deadline No of blocks until swap/add_liquidity transactions expire
    /// @param _swapTokenOutMin The minimum for the other token being exchanged; can be 0 when _asset is the SLP
    function deposit(
        uint256 _amount,
        address _asset,
        uint256 _deadline,
        uint256 _swapTokenOutMin
    ) external payable override nonReentrant validAddress(_asset) {
        _deposit(_amount, _asset, _deadline, _swapTokenOutMin, false);
    }

    /// @notice Withdraw SLP, ETH or WETH
    /// @param _amount Withdrawal amount
    /// @param _asset Withdrawal asset
    /// @param _deadline No of blocks until swap/remove_liquidity transactions expire
    /// @param _amountAMin Minimum amount for the SLP's token0
    /// @param _amountBMin Minimum amount for the SLP's token1
    /// @param _wethMinAmount Minimum Weth amount for token to Weth swap
    function withdraw(
        uint256 _amount,
        address _asset,
        uint256 _deadline,
        uint256 _amountAMin,
        uint256 _amountBMin,
        uint256 _wethMinAmount
    ) external override nonReentrant {
        if (!_isSenderKeeperOrOwner(msg.sender)) {
            require(userInfo[msg.sender].slpAmount >= _amount, "ERR: AMOUNT");
            require(!sushiConfig.isWithdrawalPaused(), "ERR: PAUSED");
        }

        require(
            sushiConfig.slpToken() == _asset ||
                sushiConfig.wethToken() == _asset ||
                _asset == address(0),
            "ERR: ASSET"
        );
        if (_asset != sushiConfig.slpToken()) {
            require(_wethMinAmount > 0, "ERR: WETH MIN TOO LOW");
            require(_amountAMin > 0, "ERR: AMOUNTA TOO LOW");
            require(_amountBMin > 0, "ERR: AMOUNTB TOO LOW");
        }
        ISushiSlpStrategyConfig.TemporaryWithdrawData memory tempData;
        tempData.isEth = _asset == address(0);
        tempData.isSlp = _asset == sushiConfig.slpToken();
        tempData.masterChef = sushiConfig.masterChef();
        tempData.pid = sushiConfig.pid();
        tempData.sushiToken = sushiConfig.sushiToken();
        // -----
        // withdraw from sushi master chef
        // -----
        tempData.masterChef.updatePool(tempData.pid);

        (tempData.totalSushi, tempData.slpAmount) = _getTotalSushiForWithdrawal(
            _amount,
            tempData.pid,
            tempData.masterChef
        );

        if (
            !_isSenderKeeperOrOwner(msg.sender) &&
            msg.sender != sushiConfig.feeAddress()
        ) {
            uint256 fee = _takeFee(tempData.totalSushi, tempData.sushiToken);
            tempData.totalSushi = tempData.totalSushi - fee;
        }

        //transfer sushi to the user
        IERC20(tempData.sushiToken).safeTransfer(
            msg.sender,
            tempData.totalSushi
        );

        totalAmountOfLPs = totalAmountOfLPs - tempData.slpAmount;

        if (tempData.isSlp) {
            IERC20(sushiConfig.slpToken()).safeTransfer(
                msg.sender,
                tempData.slpAmount
            );
            emit Withdraw(
                msg.sender,
                _asset,
                tempData.slpAmount,
                tempData.slpAmount
            );
        } else {
            //unwrap and send the right asset
            tempData.wethAmount = _unwrap(
                tempData.slpAmount,
                _deadline,
                _amountAMin,
                _amountBMin,
                _wethMinAmount
            );

            if (tempData.isEth) {
                tempData.prevEthBalance = address(this).balance;
                IWeth(sushiConfig.wethToken()).withdraw(tempData.wethAmount);
                tempData.afterEthBalance = address(this).balance;

                tempData.totalEth =
                    tempData.afterEthBalance -
                    tempData.prevEthBalance;
                FeeOperations.safeTransferETH(msg.sender, tempData.totalEth);
                emit Withdraw(
                    msg.sender,
                    _asset,
                    tempData.slpAmount,
                    tempData.totalEth
                );
            } else {
                IERC20(sushiConfig.wethToken()).safeTransfer(
                    msg.sender,
                    tempData.wethAmount
                );
                emit Withdraw(
                    msg.sender,
                    _asset,
                    tempData.slpAmount,
                    tempData.wethAmount
                );
            }
        }
    }

    /// @notice Transfer LPs or WETH to another layer
    /// @param bridgeId The bridge id to be used for this operation
    /// @param unwrap If 'true', the LP is unwrapped into WETH
    /// @param amount Amount of LPs to transfer/unwrap & transfer
    /// @param wethMinAmount When 'unwrap' is true, this should be represent the minimum amount of WETH to be received
    /// @param _data additional data needed for the bridge
    /// @return An unique id
    function transferLPs(
        uint256 bridgeId,
        uint256 _destinationNetworkId,
        bool unwrap,
        uint256 amount,
        uint256 wethMinAmount,
        uint256 _deadline,
        uint256 _amountAMin,
        uint256 _amountBMin,
        bytes calldata _data
    ) external override onlyOwnerOrKeeper nonReentrant returns (uint256) {
        //unstake from masterchef
        ISushiMasterChef.UserInfo memory masterChefUserInfo = sushiConfig
            .masterChef()
            .userInfo(sushiConfig.pid(), address(this));
        require(masterChefUserInfo.amount >= amount, "ERR: EXCEEDS BALANCE");

        if (masterChefUserInfo.amount == amount) {
            sushiConfig.pauseWithdrawal();
        }

        ISushiSlpStrategyConfig.TransferLpTemporaryData memory tempData;
        tempData.amountToTransfer = 0;
        tempData.transferredToken = sushiConfig.slpToken();

        sushiConfig.masterChef().withdraw(sushiConfig.pid(), amount);

        tempData.amountToTransfer = amount;

        if (unwrap) {
            require(wethMinAmount > 0, "ERR: WETH MIN TOO LOW");
            require(_amountAMin > 0, "ERR: AMOUNTA TOO LOW");
            require(_amountBMin > 0, "ERR: AMOUNTB TOO LOW");
            tempData.amountToTransfer = _unwrap(
                amount,
                _deadline,
                _amountAMin,
                _amountBMin,
                wethMinAmount
            );
            tempData.transferredToken = sushiConfig.wethToken();
        }

        require(tempData.amountToTransfer > 0, "ERR: AMOUNT");
        require(bridgeId > 0, "ERR: BRIDGE");
        require(
            tempData.transferredToken == sushiConfig.wethToken() ||
                tempData.transferredToken == sushiConfig.slpToken(),
            "ERR: TOKEN"
        );
        // transfer the tokens to another layer
        address bridgeManager = sushiConfig.bridgeManager();
        FeeOperations.safeApprove(
            tempData.transferredToken,
            bridgeManager,
            tempData.amountToTransfer
        );
        IBridgeManager(bridgeManager).transferERC20(
            bridgeId,
            _destinationNetworkId,
            tempData.transferredToken,
            tempData.amountToTransfer,
            sushiConfig.keeper(), // the keeper will deposit the funds on the destination layer
            _data
        );
        return tempData.amountToTransfer;
    }

    /// @notice Receive WETH or the SLP that come back from another Layer, basically deposit but with the transferral of all accumulated CRV tokens in the owner/keeper account (NEED Owner/Keeper to approve the CRV spending by this contract)
    /// @param _amount Deposited amount
    /// @param _asset Deposited asset
    /// @param _deadline No of blocks until swap/add_liquidity transactions expire
    /// @param _swapTokenOutMin The minimum for the other token being exchanged; can be 0 when _asset is the SLP
    function receiveBackLPs(
        uint256 _amount,
        address _asset,
        uint256 _deadline,
        uint256 _swapTokenOutMin
    ) external override onlyOwnerOrKeeper nonReentrant validAddress(_asset) {
        _deposit(_amount, _asset, _deadline, _swapTokenOutMin, true);

        // Transfer accumulated sushi rewards from other Layers:
        uint256 ownerSushiBalance = IERC20(sushiConfig.sushiToken()).balanceOf(
            msg.sender
        );
        IERC20(sushiConfig.sushiToken()).safeTransferFrom(
            msg.sender,
            address(this),
            ownerSushiBalance
        );
    }

    //-----------------
    //----------------- Private methods -----------------
    //-----------------

    /// @notice INTERNAL Function for deposit token0, token1, ETH, or the SLP called by deposit and receiveBackLPs
    /// @param _amount Deposited amount
    /// @param _asset Deposited asset
    /// @param _deadline No of blocks until swap/add_liquidity transactions expire
    /// @param _swapTokenOutMin The minimum for the other token being exchanged; can be 0 when _asset is the SLP
    function _deposit(
        uint256 _amount,
        address _asset,
        uint256 _deadline,
        uint256 _swapTokenOutMin,
        bool _isReceiveBackLP
    ) internal validAddress(_asset) {
        require(
            ISushiLpToken(sushiConfig.slpToken()).token0() == _asset ||
                ISushiLpToken(sushiConfig.slpToken()).token1() == _asset ||
                sushiConfig.slpToken() == _asset ||
                sushiConfig.wethToken() == _asset ||
                msg.value > 0,
            "ERR: ASSET"
        );
        if (_asset != sushiConfig.slpToken()) {
            require(_swapTokenOutMin > 0, "ERR: SLIPPAGE");
        }

        ISushiSlpStrategyConfig.DepositTemporaryData memory tempData;
        tempData.isAssetWeth = _asset == sushiConfig.wethToken();
        if (msg.value == 0) {
            require(_amount > 0, "ERR: AMOUNT IS ZERO");
            IERC20(_asset).safeTransferFrom(msg.sender, address(this), _amount);
        } else {
            _amount = msg.value;
            _asset = sushiConfig.wethToken();
            IWeth(sushiConfig.wethToken()).deposit{value: _amount}();
            tempData.isAssetWeth = true;
        }
        //we now have WETH, token0, token1 or the SLP

        //trade & add liquidity
        // -----
        if (sushiConfig.slpToken() != _asset) {
            //swap existing asset with token0 or with token1
            tempData.half = _amount / 2;
            _amount = _amount - tempData.half;

            if (_asset == sushiConfig.wethToken()) {
                if (sushiConfig.isToken0Weth()) {
                    tempData.tokenOut = ISushiLpToken(sushiConfig.slpToken())
                        .token1();
                } else if (sushiConfig.isToken1Weth()) {
                    tempData.tokenOut = ISushiLpToken(sushiConfig.slpToken())
                        .token0();
                }
            } else {
                tempData.tokenOut = sushiConfig.wethToken();
            }

            //swap half of asset
            tempData.swappedAmounts = _getTheOtherToken(
                _asset,
                tempData.tokenOut,
                tempData.half,
                _swapTokenOutMin,
                _deadline
            );

            tempData.tokenA = _asset;
            tempData.tokenB = tempData.tokenOut;
            (
                tempData.usedA,
                tempData.usedB,
                tempData.liquidity,
                tempData.toRefundA,
                tempData.toRefundB
            ) = _addLiquidity(tempData, _amount, _deadline);
        } else {
            tempData.liquidity = _amount;
        }

        //Refund excedent of tokens after swapping
        if (tempData.toRefundA > 0) {
            IERC20(tempData.tokenA).transfer(msg.sender, tempData.toRefundA);
        }

        if (tempData.toRefundB > 0) {
            IERC20(tempData.tokenB).transfer(msg.sender, tempData.toRefundB);
        }

        UserInfo storage user = userInfo[msg.sender];

        // update rewards
        // -----
        if (_isSenderKeeperOrOwner(msg.sender) && _isReceiveBackLP) {} else {
            (
                user.slpAmount,
                tempData.pendingSushiTokens,
                user.sushiRewardDebt
            ) = _updatePool(
                user.slpAmount,
                user.sushiRewardDebt,
                tempData.liquidity
            );
        }

        uint256 prevSushiBalance = IERC20(sushiConfig.sushiToken()).balanceOf(
            address(this)
        );

        // deposit into the master chef
        // -----
        FeeOperations.safeApprove(
            sushiConfig.slpToken(),
            address(sushiConfig.masterChef()),
            tempData.liquidity
        );
        sushiConfig.masterChef().deposit(sushiConfig.pid(), tempData.liquidity);

        // accrue rewards
        // -----
        if (tempData.pendingSushiTokens > 0) {
            uint256 sushiBalance = IERC20(sushiConfig.sushiToken()).balanceOf(
                address(this)
            );
            if (sushiBalance > prevSushiBalance) {
                uint256 actualSushiTokens = sushiBalance - prevSushiBalance;

                if (tempData.pendingSushiTokens > actualSushiTokens) {
                    user.userAccumulatedSushi =
                        user.userAccumulatedSushi +
                        actualSushiTokens;
                } else {
                    user.userAccumulatedSushi =
                        user.userAccumulatedSushi +
                        tempData.pendingSushiTokens;
                }
            }
        }
        if (_isSenderKeeperOrOwner(msg.sender) && _isReceiveBackLP) {
            //nothing should happen
        } else {
            totalAmountOfLPs = totalAmountOfLPs + tempData.liquidity;
        }
        if (_isReceiveBackLP) {
            emit ReceiveBackLPs(
                msg.sender,
                _asset,
                _amount + tempData.half,
                tempData.liquidity
            );
        } else {
            emit Deposit(
                msg.sender,
                _asset,
                _amount + tempData.half,
                tempData.liquidity
            );
        }
    }

    /// @notice Extracts fee from amount & transfers it to the feeAddress
    /// @param _amount Amount from which the fee is subtracted from
    /// @param _asset Asset that's going to be transferred
    function _takeFee(uint256 _amount, address _asset)
        private
        returns (uint256)
    {
        uint256 feePart = FeeOperations.getFeeAbsolute(
            _amount,
            sushiConfig.currentFee()
        );
        IERC20(_asset).safeTransfer(sushiConfig.feeAddress(), feePart);
        return feePart;
    }

    /// @notice Unwrap liquidity
    /// @param _deadline No of blocks until transaction expires
    /// @param _amountAMin Min amount for the first token
    /// @param _amountBMin Min amount for the second token
    /// @param _wethMinAmount Second token is swapped with eth and the min amount is defined by this
    /// @return Total Weth amount
    function _unwrap(
        uint256 _amount,
        uint256 _deadline,
        uint256 _amountAMin,
        uint256 _amountBMin,
        uint256 _wethMinAmount
    ) private returns (uint256) {
        ISushiSlpStrategyConfig.TransferLpTemporaryData memory tempData;
        tempData.amountToTransfer = _amount;

        //unwrap LP into weth
        (tempData.amountA, tempData.amountB) = _removeLiquidity(
            tempData.amountToTransfer,
            _deadline,
            _amountAMin,
            _amountBMin
        );
        tempData.totalWethAmount = 0;
        tempData.amountIn = 0;
        tempData.tokenIn = address(0);
        if (sushiConfig.isToken0Weth()) {
            tempData.totalWethAmount =
                tempData.totalWethAmount +
                tempData.amountA;
            tempData.amountIn = tempData.amountB;
            tempData.tokenIn = ISushiLpToken(sushiConfig.slpToken()).token1();
        } else if (sushiConfig.isToken1Weth()) {
            tempData.totalWethAmount =
                tempData.totalWethAmount +
                tempData.amountB;
            tempData.amountIn = tempData.amountA;
            tempData.tokenIn = ISushiLpToken(sushiConfig.slpToken()).token0();
        }

        uint256[] memory swapAmounts = _getTheOtherToken(
            tempData.tokenIn,
            sushiConfig.wethToken(),
            tempData.amountIn,
            _wethMinAmount,
            _deadline
        );
        tempData.totalWethAmount =
            tempData.totalWethAmount +
            swapAmounts[swapAmounts.length - 1];

        return tempData.totalWethAmount;
    }

    /// @notice Removes liquidity
    /// @param _liquidity Liquidity amount
    /// @param _deadline No of blocks until transaction expires
    /// @param _amountAMin Min amount for the first token
    /// @param _amountBMin Min amount for the second token
    /// @return tokenA amount, tokenB amount
    function _removeLiquidity(
        uint256 _liquidity,
        uint256 _deadline,
        uint256 _amountAMin,
        uint256 _amountBMin
    ) private returns (uint256, uint256) {
        ISushiSlpStrategyConfig.RemoveLiquidityTempData memory tempData;
        tempData.tokenA = ISushiLpToken(sushiConfig.slpToken()).token0();
        tempData.tokenB = ISushiLpToken(sushiConfig.slpToken()).token1();

        FeeOperations.safeApprove(
            sushiConfig.slpToken(),
            address(sushiConfig.router()),
            _liquidity
        );

        (tempData.amountA, tempData.amountB) = IUniswapV2Router02(
            sushiConfig.router()
        ).removeLiquidity(
                tempData.tokenA,
                tempData.tokenB,
                _liquidity,
                _amountAMin,
                _amountBMin,
                address(this),
                _deadline
            );

        return (tempData.amountA, tempData.amountB);
    }

    /// @notice Withdraw and return sushi amount
    /// @param _amount Withdrawal amount
    /// @param pid Pool id
    /// @param masterChef Master chef contract
    /// @return sushi amount, slp amount
    function _getTotalSushiForWithdrawal(
        uint256 _amount,
        uint256 pid,
        ISushiMasterChef masterChef
    ) private returns (uint256, uint256) {
        // if (_isSenderKeeperOrOwner(msg.sender)) {
        //     return (0, 0);
        // }
        UserInfo storage user = userInfo[msg.sender];
        uint256 sushiShareRate = (_amount *
            (masterChef.poolInfo(pid).accSushiPerShare)) / (1e12);
        uint256 pendingSushiTokens = 0;
        if (sushiShareRate >= user.sushiRewardDebt) {
            pendingSushiTokens = (sushiShareRate) - user.sushiRewardDebt;
        }
        uint256 slpAmount = _withdraw(_amount, masterChef, pid);
        require(slpAmount > 0, "ERR: INVALID UNSTAKE");
        user.slpAmount = user.slpAmount - slpAmount;

        user.sushiRewardDebt =
            (user.slpAmount * (masterChef.poolInfo(pid).accSushiPerShare)) /
            (1e12);

        uint256 sushiBalance = IERC20(sushiConfig.sushiToken()).balanceOf(
            address(this)
        );
        if (pendingSushiTokens > 0) {
            if (pendingSushiTokens > sushiBalance) {
                user.userAccumulatedSushi =
                    user.userAccumulatedSushi +
                    sushiBalance;
            } else {
                user.userAccumulatedSushi =
                    user.userAccumulatedSushi +
                    pendingSushiTokens;
            }
        }

        if (user.userAccumulatedSushi > sushiBalance) {
            return (sushiBalance, slpAmount);
        }
        return (user.userAccumulatedSushi, slpAmount);
    }

    /// @notice Withdraw from masterchef
    /// @param amount Withdrawal amount
    /// @param masterChef Master chef contract
    /// @param masterChefPoolId Pool id
    /// @return slp amount
    function _withdraw(
        uint256 amount,
        ISushiMasterChef masterChef,
        uint256 masterChefPoolId
    ) private returns (uint256) {
        uint256 prevSlpAmount = IERC20(sushiConfig.slpToken()).balanceOf(
            address(this)
        );

        masterChef.withdraw(masterChefPoolId, amount);

        uint256 currentSlpAmount = IERC20(sushiConfig.slpToken()).balanceOf(
            address(this)
        );
        if (currentSlpAmount <= prevSlpAmount) {
            return 0;
        }

        return currentSlpAmount - prevSlpAmount;
    }

    /// @notice Add liquidity
    /// @param tempData Temporary data used internally
    /// @param _amount Deposited amount
    /// @param _deadline No of blocks until add_liquidity transactions expire
    /// @return  tokenA used amount,tokenB used amount, liquidity obtained, tokenA amount to be refunded, tokenB amount to be refunded
    function _addLiquidity(
        ISushiSlpStrategyConfig.DepositTemporaryData memory tempData,
        uint256 _amount,
        uint256 _deadline
    )
        private
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        tempData.amountADesired = 0;
        tempData.amountBDesired = 0;
        if (
            (tempData.tokenA == sushiConfig.wethToken() &&
                tempData.isAssetWeth) ||
            (tempData.tokenB == sushiConfig.wethToken() &&
                !tempData.isAssetWeth)
        ) {
            tempData.amountADesired = _amount;
            tempData.amountBDesired = tempData.swappedAmounts[1];
        } else if (
            (tempData.tokenA == sushiConfig.wethToken() &&
                !tempData.isAssetWeth) ||
            (tempData.tokenB == sushiConfig.wethToken() && tempData.isAssetWeth)
        ) {
            tempData.amountADesired = tempData.swappedAmounts[1];
            tempData.amountBDesired = _amount;
        }

        tempData.amountAMin =
            tempData.amountADesired -
            FeeOperations.getFeeAbsolute(tempData.amountADesired, 1000);
        tempData.amountBMin =
            tempData.amountBDesired -
            FeeOperations.getFeeAbsolute(tempData.amountBDesired, 1000);

        FeeOperations.safeApprove(
            tempData.tokenA,
            address(sushiConfig.router()),
            tempData.amountADesired
        );
        FeeOperations.safeApprove(
            tempData.tokenB,
            address(sushiConfig.router()),
            tempData.amountBDesired
        );
        (tempData.usedA, tempData.usedB, tempData.liquidity) = sushiConfig
            .router()
            .addLiquidity(
                tempData.tokenA,
                tempData.tokenB,
                tempData.amountADesired,
                tempData.amountBDesired,
                tempData.amountAMin,
                tempData.amountBMin,
                address(this),
                _deadline
            );

        if (tempData.amountADesired - tempData.usedA > 0) {
            tempData.toRefundA = tempData.amountADesired - tempData.usedA;
        }
        if (tempData.amountBDesired - tempData.usedB > 0) {
            tempData.toRefundB = tempData.amountBDesired - tempData.usedB;
        }
        return (
            tempData.usedA,
            tempData.usedB,
            tempData.liquidity,
            tempData.toRefundA,
            tempData.toRefundB
        );
    }

    /// @notice Trade one token with the other one
    /// @param _tokenIn Deposited amount
    /// @param _amountIn Deposited asset
    /// @param _tokenOutAmountMin Deposited asset
    /// @param _deadline No of blocks until swap/add_liquidity transactions expire
    /// @return amounts  Array of 2 items: token0 amount, token1 amount
    function _getTheOtherToken(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _tokenOutAmountMin,
        uint256 _deadline
    ) private returns (uint256[] memory amounts) {
        address[] memory path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;
        FeeOperations.safeApprove(
            _tokenIn,
            address(sushiConfig.router()),
            _amountIn
        );
        amounts = IUniswapV2Router02(sushiConfig.router())
            .swapExactTokensForTokens(
                _amountIn,
                _tokenOutAmountMin,
                path,
                address(this),
                _deadline
            );
    }

    /// @notice Get Sushi token ratio for a user
    /// @param amount User address
    /// @param sushiRewardDebt User address
    /// @param liquidity User address
    /// @return amount, pendingSushiTokens, sushiRewardDebt
    function _updatePool(
        uint256 amount,
        uint256 sushiRewardDebt,
        uint256 liquidity
    )
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        ISushiMasterChef masterChef = sushiConfig.masterChef();
        uint256 masterChefPoolId = sushiConfig.pid();
        masterChef.updatePool(masterChefPoolId);
        uint256 pendingSushiTokens = ((amount *
            masterChef.poolInfo(masterChefPoolId).accSushiPerShare) / (1e12)) -
            sushiRewardDebt;

        amount = amount + liquidity;

        sushiRewardDebt =
            (amount * masterChef.poolInfo(masterChefPoolId).accSushiPerShare) /
            (1e12);

        return (amount, pendingSushiTokens, sushiRewardDebt);
    }

    function _isSenderKeeperOrOwner(address _user) private view returns (bool) {
        return _user == owner() || _user == sushiConfig.keeper();
    }

    //-----------------
    //----------------- Modifiers -----------------
    //-----------------
    modifier onlyOwnerOrKeeper() {
        require(
            msg.sender == owner() || msg.sender == sushiConfig.keeper(),
            "ERR: NOT AUTHORIZED"
        );
        _;
    }
    modifier validAddress(address _address) {
        require(_address != address(0), "ERR: INVALID ADDRESS");
        _;
    }
}