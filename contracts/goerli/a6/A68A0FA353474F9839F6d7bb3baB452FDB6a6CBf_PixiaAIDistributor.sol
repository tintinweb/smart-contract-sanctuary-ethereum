//  SPDX-License-Identifier: MIT
// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol

/*
 * █▀█ █ ▀▄▀ █ ▄▀█   ▄▀█ █
 * █▀▀ █ █░█ █ █▀█   █▀█ █
 *
 * https://Pixia.Ai
 * https://t.me/PixiaAi
 * https://twitter.com/PixiaAi
*/


pragma solidity 0.8.17;

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

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol



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


// File: @openzeppelin/contracts/security/ReentrancyGuard.sol

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


// File: @openzeppelin/contracts/utils/math/SafeMath.sol
/* solhint-disable */



// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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

// File: @openzeppelin/contracts/utils/Context.sol


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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
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
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

interface IStaking {
    function addRewards (uint256 amount) external payable;
}


contract PixiaAIDistributor is Ownable, ReentrancyGuard {

    using SafeMath for uint256; 
    address public walletRunningCost;
    address public walletDev;
    mapping (address => bool) public isAdmin;

    uint256 public walletRunningCostShare;
    uint256 public contractStakingShare;
    uint256 public walletDevShare;
    uint256 public walletCallerShare;
    uint256 public AutoLPBurn;
    uint256 public buyAndBurn;

    uint256 public minAmount; // Min Reward Token to trigger Distribution Reward to Staking Contract 

    uint256 private totalRunningCost; // Total ETH sent to Running Cost
    uint256 private totalStaking; // Total ETH sent to Staking Wallet
    uint256 private totalDev; // Total ETH sent to Dev Wallet
    uint256 private totalCaller; // Total ETH sent to Callers combined
    uint256 private totalAutoLP; // Total ETH contributed to autoLP
    uint256 private totalBuybackBurn; // Total ETH contributed for buyback and burn



    IUniswapV2Router02 public router;
    IStaking public contractStaking;


    IERC20 public token;
    IERC20 public rewardToken;

    constructor () {
        walletRunningCost = address(0x123); // Running Cost Wallet Address
        walletDev = address(0x123); // Dev Wallet Address

        contractStaking = IStaking(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // Staking Contract Address

        token = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // Token Address that will be Buy Back And Burn, and, Provide AutoLP and Burn.
        rewardToken = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // Token Address that will be added to staking pool

        isAdmin[msg.sender] = true; // By default, the deployer wallet will be called Admin.
        isAdmin[address(0x123)]; // This address is set as Admin to support the Owner (Owner can remove admin anytime).


        // Values below are set in Thousand Percent ‰
        walletRunningCostShare = 650; // 65% to Running Cost Wallet
        contractStakingShare = 200; // 20% to Staking Contract
        walletDevShare = 30; // 3% to Dev Wallet
        walletCallerShare = 10; // 1% to User that triggers Distribution
        AutoLPBurn = 100; // 10% to Auto Buy LP and Burn
        buyAndBurn = 10; // 1% to Auto Buy Token and Burn

        minAmount = 10e6; //10 USDT
        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //uniswapV2Router
    }

    /// @dev owner can claim any ERC20 token
    function claimForeignToken (address _token) external {
        require(isAdmin[msg.sender], "only Admin can claim foreign token");
        uint256 balance = IERC20(_token).balanceOf(address(this));
        IERC20 (_token).transfer(msg.sender, balance);
    }

    /// @notice Any Address can call the trigger Distribution function,
    /// caller will be rewarded with x% from the contract balance
    function triggerDistribution() public nonReentrant {
        uint256 total = address(this).balance;
        uint256 walletRunningCostPart = total.mul(walletRunningCostShare).div(1000);
        uint256 contractStakingPart = total.mul(contractStakingShare).div(1000);
        uint256 walletDevPart = total.mul(walletDevShare).div(1000);
        uint256 walletCallerPart = total.mul(walletCallerShare).div(1000);
        uint256 autoLpPart = total.mul(AutoLPBurn).div(1000);
    
        // Sending ETH to Running Cost Wallet
        if (walletRunningCostPart > 0) {
            sendEther (walletRunningCost, walletRunningCostPart);
            totalRunningCost += walletRunningCostPart;
        }

        // Sending ETH to Staking Contract
        if (contractStakingPart > 0) {
            swapETHForTokens(contractStakingPart, address(this), rewardToken);
            
            if (rewardToken.balanceOf(address(this)) >= minAmount){
                uint256 balance = rewardToken.balanceOf(address(this));

                if (rewardToken.allowance(address(this), address(contractStaking)) < balance) {
                    rewardToken.approve(address(contractStaking), type(uint256).max);
                }

                contractStaking.addRewards{value: 0}(balance); // Adding rewards to pool

                totalStaking += contractStakingPart;
            }
        }

        // Sending ETH to Dev Wallet
        if (walletDevPart > 0){
            sendEther (walletDev, walletDevPart);
            totalDev += walletDevPart;
        }

        // Sending ETH to Caller Wallet
        if (walletCallerPart > 0 ) {
            sendEther (msg.sender, walletCallerPart);
            totalCaller += walletCallerPart;
        }

        // Sending ETH to Auto LP Burn
        if (autoLpPart > 0) {
            swapETHForTokens (autoLpPart/2, address(this), token);
            uint256 tokenBalance = token.balanceOf(address(this));
            addLiquidity (tokenBalance, autoLpPart/2);
            totalAutoLP += autoLpPart;
        }

        // Sending ETH to Buy Back and Burn
        if (address(this).balance > 0){
            swapETHForTokens (address(this).balance, address(0xdead), token);
            totalBuybackBurn += address(this).balance;
        }
    }

    /// @notice internal function to handle eth transfer
    function sendEther (address _user, uint256 amount) private {
        (bool sent,) = _user.call{value: amount}("");
        require(sent, "eth transfer failed");
    }

    /// @dev update the wallets for walletRunningCost and WalletDev
    function setWallets (address _walletRunningCost, address _walletDev) external onlyAdmin{
        require(_walletRunningCost != address(0) || _walletDev != address(0), "zero address is not allowed");
        walletRunningCost = _walletRunningCost;
        walletDev = _walletDev;
    }

    /// @dev update the staking contract
    function updateStakingContract (IStaking _contractStaking) external onlyAdmin {
        require (_contractStaking != contractStaking, "already set the same address");
        contractStaking = _contractStaking;
    }

    /// @dev Update Token address for autoLP and Burn part
    function updateToken (IERC20 _newToken) external onlyAdmin{
        token = _newToken;
    }

    /// @dev Update Reward Token Address for Staking Contract Distribution
    function updateRewardToken (IERC20 _reward) external onlyAdmin{
        rewardToken = _reward;
    }

    ///@dev Update Thousand Percentage Distribution for each Wallet and Contract
    function updateWalletPercentage (
        uint256 runningCostWallet,
        uint256 stakingContract,
        uint256 devWallet,
        uint256 callerWallet,
        uint256 autoLPBurn,
        uint256 buybackAndBurn) external onlyAdmin{
        walletRunningCostShare = runningCostWallet;
        contractStakingShare = stakingContract;
        walletDevShare = devWallet;
        walletCallerShare = callerWallet;
        AutoLPBurn = autoLPBurn;
        buyAndBurn = buybackAndBurn;

        require (walletRunningCostShare + contractStakingShare + walletDevShare + AutoLPBurn + buyAndBurn <= 1000, "max percentage is 100");
    }

    /// @dev Add or remove admins with true or false values
    function updateAdmins (address _newAdmin, bool value) external onlyOwner {
        isAdmin[_newAdmin] = value;
    }

    
    /// @notice Returns available ETH to distribute for each wallet
    function getAvailableEthtPerWallet () public view returns (
        uint256 runningCost,
        uint256 staking,
        uint256 dev,
        uint256 caller) {
        uint256 balance = address(this).balance;
        runningCost = balance.mul(walletRunningCostShare).div(1000);
        staking = balance.mul(contractStakingShare).div(1000);
        dev = balance.mul(walletDevShare).div(1000);
        caller = balance.mul(walletCallerShare).div(1000);
    }

    /// @notice Returns total ETH sent to wallets till date
    function  getTotalEthSentToWallets() public view returns (
        uint256 walletRunningCostTotal,
        uint256 walletStakingTotal,
        uint256 walletDevTotal, 
        uint256 walletCallerTotal) {
        walletRunningCostTotal = totalRunningCost;
        walletStakingTotal = totalStaking;
        walletDevTotal = totalDev;
        walletCallerTotal = totalCaller;
    }

   /// @notice Returns total ETH sent to Auto LP Burn and Buy Back Burn till date
    function getTotalEthForAutoLPandBuyback () public view returns (
        uint256 autoLPtotal,
        uint256 buybackAndBurntotal) {
        autoLPtotal = totalAutoLP;
        buybackAndBurntotal = totalBuybackBurn;   
    }

    /// @notice returns available ETH to distribute for Auto LP, BuybackBurn
    function getAvailableEthAutoLPandBuyBackBurn () public view returns (uint256 LP, uint256 BuybackBurn) {
        uint256 balance = address(this).balance;
        LP = balance.mul(AutoLPBurn).div(1000);
        BuybackBurn = balance.mul(buyAndBurn).div(1000);
    }

    /// @notice private internal functions handling autoLP and eth to token conversions
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

        if (token.allowance(address(this), address(router)) < tokenAmount) {
                token.approve(address(router), type(uint256).max);
            }

            // add the liquidity
            router.addLiquidityETH{value: ethAmount} (
            address(token),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0xdead),
            block.timestamp
        );
    }

    function swapETHForTokens(uint256 amount, address receiver, IERC20 _token) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(_token);

        // make the swap
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amount
        } (
            0, // accept any amount of Tokens
            path,
            receiver, 
            block.timestamp
        );
    }

     
    /// @dev Throws if called by any account other than the admin.
    modifier onlyAdmin() {
        require(isAdmin[_msgSender()], "Admin: caller is not the Admin");
        _;
    }

    receive () external payable {} // contract can receive external ether

}