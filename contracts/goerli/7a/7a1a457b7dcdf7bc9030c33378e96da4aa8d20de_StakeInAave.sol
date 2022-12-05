/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


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

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}



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

interface ILendingPoolAddressesProvider {
  event MarketIdSet(string newMarketId);
  event LendingPoolUpdated(address indexed newAddress);
  function getLendingPool() external view returns (address);

}



interface ILendingPool {

  event Deposit(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referral
  );

  
  event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

  event Borrow(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint256 borrowRateMode,
    uint256 borrowRate,
    uint16 indexed referral
  );

  
  event Repay(
    address indexed reserve,
    address indexed user,
    address indexed repayer,
    uint256 amount
  );


 
  event FlashLoan(
    address indexed target,
    address indexed initiator,
    address indexed asset,
    uint256 amount,
    uint256 premium,
    uint16 referralCode
  );

  /**
   * @dev Emitted when the pause is triggered.
   */
  event Paused();

  /**
   * @dev Emitted when the pause is lifted.
   */
  event Unpaused();

  /**
   * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
   * LendingPoolCollateral manager using a DELEGATECALL
   * This allows to have the events in the generated ABI for LendingPool.
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
   * @param liquidator The address of the liquidator
   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  event LiquidationCall(
    address indexed collateralAsset,
    address indexed debtAsset,
    address indexed user,
    uint256 debtToCover,
    uint256 liquidatedCollateralAmount,
    address liquidator,
    bool receiveAToken
  );

 
  event ReserveDataUpdated(
    address indexed reserve,
    uint256 liquidityRate,
    uint256 stableBorrowRate,
    uint256 variableBorrowRate,
    uint256 liquidityIndex,
    uint256 variableBorrowIndex
  );

  
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;


  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external;

  
  function repay(
    address asset,
    uint256 amount,
    uint256 rateMode,
    address onBehalfOf
  ) external returns (uint256);


  function swapBorrowRateMode(address asset, uint256 rateMode) external;

 
  function rebalanceStableBorrowRate(address asset, address user) external;


  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;


  function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256 debtToCover,
    bool receiveAToken
  ) external;

 
  function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata modes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  ) external;

  /**
   * @dev Returns the user account data across all the reserves
   * @param user The address of the user
   * @return totalCollateralETH the total collateral in ETH of the user
   * @return totalDebtETH the total debt in ETH of the user
   * @return availableBorrowsETH the borrowing power left of the user
   * @return currentLiquidationThreshold the liquidation threshold of the user
   * @return ltv the loan to value of the user
   * @return healthFactor the current health factor of the user
   **/
  function getUserAccountData(address user)
    external
    view
    returns (
      uint256 totalCollateralETH,
      uint256 totalDebtETH,
      uint256 availableBorrowsETH,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    );

  function initReserve(
    address reserve,
    address aTokenAddress,
    address stableDebtAddress,
    address variableDebtAddress,
    address interestRateStrategyAddress
  ) external;

  function setReserveInterestRateStrategyAddress(address reserve, address rateStrategyAddress)
    external;

  function setConfiguration(address reserve, uint256 configuration) external;

 

  function getReserveNormalizedIncome(address asset) external view returns (uint256);

  /**
   * @dev Returns the normalized variable debt per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
  function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

  

  function getReservesList() external view returns (address[] memory);

  function getAddressesProvider() external view returns (ILendingPoolAddressesProvider);

  function setPause(bool val) external;

  function paused() external view returns (bool);
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}
interface IWETHGateway {
  function depositETH(
    address lendingPool,
    address onBehalfOf,
    uint16 referralCode
  ) external payable;

  function withdrawETH(
    address lendingPool,
    uint256 amount,
    address onBehalfOf
  ) external;

  function repayETH(
    address lendingPool,
    uint256 amount,
    uint256 rateMode,
    address onBehalfOf
  ) external payable;

  function borrowETH(
    address lendingPool,
    uint256 amount,
    uint256 interesRateMode,
    uint16 referralCode
  ) external;
}


contract StakeInAave{
    using SafeMath for uint256;

    ILendingPoolAddressesProvider private lendingPoolProvider;
    

    uint public amountSwapped;
    uint256 private amountToDistribute;
    address internal admin;
    address private owner;
    address private lendingPool;
    IERC20 internal daiToken;
    address internal constant weth = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
    address internal constant aWeth = 0x22404B0e2a7067068AcdaDd8f9D586F834cCe2c5;
    //address constant daiToken = 0x75Ab5AB1Eef154C0352Fc31D2428Cef80C7F8B33;
    address constant aDai = 0x31f30d9A5627eAfeC4433Ae2886Cf6cc3D25E772;
    address constant IgethWay = 0x3bd3a20Ac9Ff1dda1D99C0dFCE6D65C4960B3627;
    
    address internal constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    struct stakeInfo{
        address user;
        uint256 ethAmount;
        uint256 totalEth;
        uint256 Tokenamount;
        uint256 totalToken;
        uint256 totalETHStakedInAave;
        uint256 totalTokenStakedInAave;
        uint256 time;
    }

    mapping(address => stakeInfo) public stakedDetail;

    event Stake(address user, uint256 amount);
    event DepositedInAave(address user, uint256 amount); 
    event OwnerShipChanged(address oldOwner, address newOwner);
    event LiquidityPool(uint amountA,uint amountB,uint liquidity);
    //event lendingPoolAddress(ILendingPool lendingPoolAddr);

    constructor()  {
        //lendingPoolProvider = ILendingPoolAddressesProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5); //0x88757f2f99175387aB4C6a4b3067c77A695b0349
        lendingPool = 0x4bd5643ac6f66a5237E18bfA7d47cF22f1c9F210;
        daiToken = IERC20(0x75Ab5AB1Eef154C0352Fc31D2428Cef80C7F8B33);
        //emit lendingPoolAddress(lendeingPool);
        owner = msg.sender;

    }

    modifier onlyOwner(){
      require(msg.sender == owner,"Only owner are allowed to call this function.");
      _;
    }

    function changeOwnerShip(address newOwner)external onlyOwner{
      address oldOwner = owner;
      owner = newOwner;
      emit OwnerShipChanged(oldOwner, newOwner);
    }

    function setAdminAddress(address adminAddress) external onlyOwner{
      admin = adminAddress;
    }

    function stakeToken(address _token,uint256 _amount)public payable {
        require(_amount > 0, "invalid amount");
        require(msg.sender != address(0),"invalid address");

        if(_token == address(0)){
          stakedDetail[msg.sender].user = msg.sender;
          stakedDetail[msg.sender].ethAmount =  msg.value;
          stakedDetail[msg.sender].totalEth +=  msg.value;
          stakedDetail[msg.sender].time = block.timestamp;
        }else{
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
         
        stakedDetail[msg.sender].user = msg.sender;
        stakedDetail[msg.sender].Tokenamount = _amount;
        stakedDetail[msg.sender].totalToken += _amount;
        stakedDetail[msg.sender].time = block.timestamp;

        emit Stake(msg.sender, _amount);
        }
    }

    function withdrawToken(address _token, uint256 _amount) public{

      if(_token == address(0)){
        uint ethamount = stakedDetail[msg.sender].totalEth;
        require(_amount < ethamount,"insufficient balance." );
        address payable recipient;
        bool sent = recipient.send(_amount);
        require(sent,"transcation is fail");
        stakedDetail[msg.sender].ethAmount = 0;
        stakedDetail[msg.sender].totalEth -= _amount;
      }
      else{
        uint amount = stakedDetail[msg.sender].totalToken;

        require(_amount <= amount, "insufficient balance.");
        require(msg.sender != address(0),"invalid address");

        IERC20(_token).transfer(msg.sender, _amount);
        stakedDetail[msg.sender].totalToken -= _amount;
      }
    }

    function depositInAave(address _token) public {
      if(_token == address(0)){
        uint256 value = stakedDetail[msg.sender].ethAmount;
        IWETHGateway(IgethWay).depositETH{value:value}(lendingPool,address(this),0);
        stakedDetail[msg.sender].totalETHStakedInAave += value;
      }else{
      uint256 amount = stakedDetail[msg.sender].Tokenamount;
      IERC20(_token).approve(lendingPool, amount);
      ILendingPool(lendingPool).deposit(_token, amount, address(this),0);
      stakedDetail[msg.sender].totalTokenStakedInAave += amount;
      emit DepositedInAave((address(this)), amount);
      }
    }

    function aDaiBalance()public view returns(uint256 bal){
      return IERC20(aDai).balanceOf(address(this));
    }

    function aDaiBalanceUser()public view returns(uint256 bal){
      return IERC20(aDai).balanceOf(msg.sender);
    }

    function wETHBalanceUser(address user)public view returns(uint256 bal){
      return IERC20(aWeth).balanceOf(user);
    }

    function withdrawFromAave(address _token, uint256 _amount) public{
      if(_token == address(0)){
        
        //uint256 amount = stakedDetail[msg.sender].ethAmount;
        //require(_amount <= amount ,"invalid amount.");
        IERC20(aWeth).approve(IgethWay, _amount);
        IWETHGateway(IgethWay).withdrawETH(lendingPool, type(uint).max, address(this));
        //ethAmountToDistribute = stakedDetail[msg.sender].totalETHStakedInAave
      }else{
      uint amount_ = aDaiBalance();
      require(_amount <= amount_ ,"invalid amount.");

      daiToken.approve(lendingPool, _amount);
      ILendingPool(lendingPool).withdraw(_token, _amount, address(this));
      amountToDistribute = _amount;
      }
    }

    function addLiquidity(address tokenA, address tokenB,  uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin) public  {
      IERC20(tokenA).transferFrom(msg.sender, address(this), amountADesired);
      IERC20(tokenB).transferFrom(msg.sender, address(this), amountBDesired);

      IERC20(tokenA).approve( UNISWAP_V2_ROUTER, amountADesired);
      IERC20(tokenB).approve(UNISWAP_V2_ROUTER, amountBDesired);

      (uint amountA, uint amountB, uint liquidity) = IUniswapV2Router02(UNISWAP_V2_ROUTER).addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin, msg.sender, block.timestamp+1000);
      emit LiquidityPool(amountA,amountB,liquidity);


    }
    function swap(address tokenIn, address tokenOut, uint amountIn, address _to) public {
      IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
      IERC20(tokenIn).approve(UNISWAP_V2_ROUTER, amountIn);

      address[] memory path;
 
      path = new address[](2);
      path[0] = tokenIn;
      path[1] = tokenOut;
        
      uint[] memory amountOutMins = IUniswapV2Router02(UNISWAP_V2_ROUTER).getAmountsOut(amountIn, path);
      amountSwapped = amountOutMins[path.length - 1];
    
      IUniswapV2Router02(UNISWAP_V2_ROUTER).swapExactTokensForTokens(amountIn, amountSwapped, path, _to, block.timestamp + 1000);
    }

    function amountDistribution(address token)public {
      uint256 stakedAmount = stakedDetail[msg.sender].Tokenamount;
      uint256 profit = stakedAmount - amountToDistribute ;
      uint256 OwnerProfit = stakedDetail[msg.sender].Tokenamount += (profit*20)/100;
      stakedDetail[msg.sender].Tokenamount += (profit*80)/100;
      uint256 userFinalWithdrawalAmount = stakedDetail[msg.sender].Tokenamount;

      uint adminBal = (OwnerProfit*80)/100;
      uint swapAmnt = OwnerProfit - adminBal;
      
      IERC20(token).transfer(msg.sender, userFinalWithdrawalAmount);
      IERC20(token).transfer(admin, adminBal);
      swap(address(daiToken),0x32D5ee0131FAfb0aB5b33cF1093Ddb393A892c07,swapAmnt , msg.sender );


    }
    receive() external payable {
        // React to receiving ether
    }

    


}