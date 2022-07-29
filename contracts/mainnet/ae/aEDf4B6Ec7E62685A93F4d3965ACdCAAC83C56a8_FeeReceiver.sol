/**
 *Submitted for verification at Etherscan.io on 2022-07-29
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

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

interface IERC20 {

    function totalSupply() external view returns (uint256);
    
    function symbol() external view returns(string memory);
    
    function name() external view returns(string memory);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    
    /**
     * @dev Returns the number of decimal places
     */
    function decimals() external view returns (uint8);

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
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IOwnedContract {
    function getOwner() external view returns (address);
}

interface IYieldFarm {
    function depositRewards(uint256 amount) external;
}

contract FeeReceiver {

    // Token
    address public immutable token;

    // Recipients Of Fees
    address public treasury;
    address public yieldFarm;
    address public stakingPool;

    // Fee Percentages
    uint256 public treasuryPercent  = 60;
    uint256 public yieldFarmPercent = 30;
    uint256 public stakingPercent   = 10;
    uint256 public bountyPercent    = 2;

    // Token -> BNB
    address[] private path;

    // router
    IUniswapV2Router02 public constant router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    // Events
    event UpdatedFees(uint256 treasury_, uint256 yield_, uint256 stake_);

    modifier onlyOwner(){
        require(
            msg.sender == IOwnedContract(token).getOwner(),
            'Only Token Owner'
        );
        _;
    }

    constructor(address token_, address treasury_) {
        token = token_;
        treasury = treasury_;
        path = new address[](2);
        path[0] = token_;
        path[1] = router.WETH();
        IERC20(token_).approve(address(router), 10**65);
    }

    function trigger() external {

        // Bounty Reward For Triggerer
        uint bounty = currentBounty();
        if (bounty > 0) {
            IERC20(token).transfer(msg.sender, bounty);
        }

        // Split up remaining balance
        uint bal = IERC20(token).balanceOf(address(this));
        uint tBal = bal * treasuryPercent / 100;
        uint yBal = bal * yieldFarmPercent / 100;
        uint sBal = bal - ( tBal + yBal );

        // Sell Percentage Of Tokens For Treasury
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(tBal, 0, path, treasury, block.timestamp + 300);

        // Deposit Tokens Into Yield Farm
        IYieldFarm(yieldFarm).depositRewards(yBal);

        // Give Tokens To Staking
        IERC20(token).transfer(stakingPool, sBal);
    }

    function updateFeePercentages(uint treasury_, uint yield_, uint stake_) external onlyOwner {
        require(
            treasury_ + yield_ + stake_ == 100, 'Invalid Fees'
        );
        treasuryPercent = treasury_;
        yieldFarmPercent = yield_;
        stakingPercent = stake_;

        emit UpdatedFees(treasury_, yield_, stake_);
    }

    function setBountyPercent(uint256 bountyPercent_) external onlyOwner {
        require(bountyPercent_ <= 50);
        bountyPercent = bountyPercent_;
    }

    function setTreasury(address treasury_) external onlyOwner {
        require(treasury_ != address(0));
        treasury = treasury_;
    }

    function setYieldFarm(address yieldFarm_) external onlyOwner {
        require(yieldFarm_ != address(0));
        yieldFarm = yieldFarm_;
        IERC20(token).approve(yieldFarm_, ~uint(0));
    }
    
    function setStakingPool(address stakingPool_) external onlyOwner {
        require(stakingPool_ != address(0));
        stakingPool = stakingPool_;
    }

    function redoApprovals() external onlyOwner {
        IERC20(token).approve(address(router), ~uint(0));
        IERC20(token).approve(yieldFarm, ~uint(0));
    }
    
    function withdraw() external onlyOwner {
        (bool s,) = payable(msg.sender).call{value: address(this).balance}("");
        require(s);
    }
    
    function withdraw(address _token) external onlyOwner {
        IERC20(_token).transfer(msg.sender, IERC20(_token).balanceOf(address(this)));
    }

    receive() external payable {}

    function currentBounty() public view returns (uint256) {
        return (IERC20(token).balanceOf(address(this)) * bountyPercent ) / 100;
    }
}