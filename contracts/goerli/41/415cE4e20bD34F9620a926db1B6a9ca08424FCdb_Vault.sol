/**
 *Submitted for verification at Etherscan.io on 2023-01-27
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


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

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// File: am3Vault.sol


pragma solidity ^0.8.13;




    //Strategy:
    // 1. Users deposit ETH 
    // 2. ETH is swapped for DAI, USDC, and USDT on on Uniswap V2
    // 3. DAI, USDC, USDT is lent on AAVE
    //      AAVE gives aDAI, aUSDC, and aUSDT tokens
    // 4. aDAI, aUSDC, and aUSDT is deposited into Curve AAVE Stablecoin pool
    //      Curve gives am3CRV tokens

    //Instructions
    //**How to Execute
    //1. A_ETHToStablesUniswap() - swap from eth to USDC, USDT, and DAI from a DEX
    //2. B_DepositIntoAAVE() - deposit USDC, USDT, and DAI into AAVE
    //3. C_DepositIntoCurve() - deposit aUSDC, aUSDT, and aDAI into Curve's AAVE stablecoin pool

    // Contract owner can lock contract which prevents users from depositing or withdrawing
    // 

contract Vault {

// ========================================= Variables and Instances 🧾

    address owner;

    //Chainlink pricefeed dolllrs per wei
    //AggregatorV3Interface internal priceFeed = AggregatorV3Interface(0xAB594600376Ec9fD91F8e885dADF0CE036862dE0);

    //vault variables
    uint public totalLPTokensMinted;
    bool public isLocked;
    uint startingTime;
    uint startingAmt;
    uint endingAmt;

    uint accumulationPeriod = startingTime + 1 weeks;
    bool isSwapped;
    bool isLoaned;
    bool isProvided;

    //chainlink keeper registry address
    address keeper;

    //Stablecoin Addresses
    //address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    //address constant DAI = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    //address constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    //address constant USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;

    //AAVE Token Addresses
    //address constant maDAI = 0x27F8D03b3a2196956ED754baDc28D73be8830A6e;
    //address constant maUSDC = 0x1a13F4Ca1d028320A707D99520AbFefca3998b7F;
    //address constant maUSDT = 0x60D55F02A771d515e077c9C2403a1ef324885CeC;

    //Curve AAVE pool LP token instance
    //address constant am3CRV = 0xE7a24EF0C5e95Ffb0f6684b813A78F2a3AD7D171;

    //Uniswapv2 Router Instance
    //IUniswapV2Router02 public uniswapRouter = IUniswapV2Router02(0x93bcDc45f7e62f89a8e901DC4A0E2c6C427D9F25);


    /// @notice Interface for Aave lendingPoolAddressesProviderRegistry

    
    //address constant RegistryAddress = 0x3ac4e9aa29940770aeC38fe853a4bbabb2dA9C19;
    //address constant LendingPoolAddress = 0x3ac4e9aa29940770aeC38fe853a4bbabb2dA9C19;

    //address constant ProviderAddress = 0xd05e3E715d945B59290df0ae8eF85c1BdB684744;
    //ILendingPool LendingPool = (ILendingPool(ILendingPoolAddressesProvider(ProviderAddress).getLendingPool()));
    
    //Curve Polygon AAVE Stablecoin Pool instance
    //ICurve_AAVE_Stable_Pool curvePool = ICurve_AAVE_Stable_Pool(0x445FE580eF8d70FF569aB36e80c647af338db351);

    constructor() {
        owner = msg.sender;
        startingTime = block.timestamp;
        keeper = 0x02777053d6764996e594c3E88AF1D58D5363a2e6;
    }

// ========================================= Vault Management 🔐

    //total supply of shares
    uint public totalSupply;

    //returns number of shares per user
    mapping(address => uint) public balanceOf;

    //adds shares from user deposit
    function _mint(address _to, uint _shares) private {
        totalSupply += _shares;
        balanceOf[_to] += _shares;
    }

    //burns shares from user withdrawal
/*    function _burn(address _from, uint _shares) private {
        totalSupply -= _shares;
        balanceOf[_from] -= _shares;
    }
*/

    function lock(bool _lock) public {
        require(msg.sender == owner);
        isLocked =  _lock;
    }

    //add ETH to vault
    function deposit() payable public {
      //  require(block.timestamp < startingTime);
       // require(!isLocked);

        _mint(msg.sender, msg.value);
    }

    function returnContractBalance() public view returns(uint) {
        return address(this).balance;
     }

   function withdraw() public returns (uint receivedAmt) {
       //update user shares
       uint oldUserShares = balanceOf[msg.sender];
       delete balanceOf[msg.sender];

      //  require(!isLocked,"Contract Locked!");
    //    require(_shares <= balanceOf[msg.sender],"You dont have that many shares");
     //   uint amount = SafeMath.div(fakeShares, faketotal);
        receivedAmt = (endingAmt * oldUserShares) / totalSupply;
     //   _burn(msg.sender, _shares);

        //  ** send user something  **
        payable(msg.sender).transfer(receivedAmt);

    }
    

// ========================================= Strategy Execution Methods ⚔️

    // How to Execute
    //1. A_ETHToStablesUniswap() - swap from eth to USDC, USDT, and DAI from Uniswap v2
    //2. B_DepositIntoAAVE() - deposit USDC, USDT, and DAI into AAVE 
    //3. C_DepositIntoCurve() - deposit aUSDC, aUSDT, and aDAI into Curve's AAVE stablecoin pool 
    using SafeMath for uint256;

    function A_ETHToStablesUniswap() /*automated*/ public {
        //startingAmt = address(this).balance;
        //lock deposits
        //isLocked = true;
  
        IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(0x93bcDc45f7e62f89a8e901DC4A0E2c6C427D9F25);
        //require(msg.sender == owner,"must be owner");
        //require(step == 0, "STEP_COMPLETED");

        //get amount of ETH to spend per stablecoin (1/3)
       // uint thirdOfETH = address(this).balance / 3;

        // using 'now' for convenience, for mainnet pass deadline from frontend!
        uint deadline = block.timestamp + 15; 

       // tokenAmount is the minimum amount of output tokens that must be received for the transaction not to revert.
        //can use oracle
        // calculate: pricefeed returns dollars per wei * 10 ^ 6
        // pricefeed * msg.value
      //  (,int price,,,) = priceFeed.latestRoundData();

        //uint maticPrice = uint(price) / 10 ** 4;


    /*  uint amountToSwapInWei = thirdOfETH * maticPrice;
        amountToSwapInWei = amountToSwapInWei / 10 ** 4;
        amountToSwapInWei -= 2 ether;*/

        //get third of all eth using safemath
        uint256 third = getThird();

        //put zero expected amount because it keeps failing if I put an estimate
        // swap all ETH to USDC, USDT, and DAI from a DEX (Uniswap v2)
        uniswapRouter.swapExactETHForTokens{ value: third }(0, getPathForETHtoDAI(), address(this), deadline);
        uniswapRouter.swapExactETHForTokens{ value: third }(0, getPathForETHtoUSDC(), address(this), deadline);
        uniswapRouter.swapExactETHForTokens{ value: third }(0, getPathForETHtoUSDT(), address(this), deadline);

        // refund leftover ETH to user
      //  (bool success,) = msg.sender.call{ value: address(this).balance }("");
      //  require(success, "refund failed");

      isSwapped = true;
       
    }

     
    function B_DepositIntoAAVE() /*automated*/ public {
        //require swapped to uniswap, and is NOT loaned.
        require(isSwapped && !isLoaned);

        IERC20 USDC = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
        IERC20 DAI = IERC20(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);
        IERC20 USDT = IERC20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);

        ILendingPool LendingPool = (ILendingPool(ILendingPoolAddressesProvider(0xd05e3E715d945B59290df0ae8eF85c1BdB684744).getLendingPool()));
        uint16 REFERRAL_CODE = uint16(0);

        DAI.approve(address(LendingPool),  DAI.balanceOf(address(this)));
        USDC.approve(address(LendingPool), USDC.balanceOf(address(this)));
        USDT.approve(address(LendingPool), USDT.balanceOf(address(this)));
       // return address(_lendingPool());

        //  deposit USDC, USDT, and DAI into AAVE
       LendingPool.deposit(address(DAI), IERC20(DAI).balanceOf(address(this)) , address(this), REFERRAL_CODE);
       LendingPool.deposit(address(USDC), IERC20(USDC).balanceOf(address(this)) , address(this), REFERRAL_CODE);
       LendingPool.deposit(address(USDT), IERC20(USDT).balanceOf(address(this)) , address(this), REFERRAL_CODE);
        
        isLoaned = true;
    }
    
    
    function C_DepositIntoCurve() /*automated*/ public {
    //require loaned to AAVE and NOT provided liquidity to Curve.
    require(isLoaned && !isProvided, "tokens need to be Loaned first");

    IERC20 maDAI = IERC20(0x27F8D03b3a2196956ED754baDc28D73be8830A6e);
    IERC20 maUSDC = IERC20(0x1a13F4Ca1d028320A707D99520AbFefca3998b7F);
    IERC20 maUSDT = IERC20(0x60D55F02A771d515e077c9C2403a1ef324885CeC);

    ICurve_AAVE_Stable_Pool curvePool = ICurve_AAVE_Stable_Pool(0x445FE580eF8d70FF569aB36e80c647af338db351);
        //  calculate amount of AAVE stablecoins in contract and store in array
        uint[3] memory aaveTokenAmount = [maDAI.balanceOf(address(this)),maUSDC.balanceOf(address(this)),maUSDT.balanceOf(address(this))];


        //calculate minumum amount of LP tokens to mint (required by add liquidity function)
        //uint curve_expected_LP_token_amount = ICurve_AAVE_Stable_Pool(curvePool).calc_token_amount(aaveTokenAmount,true);

        //approve
        maDAI.approve(address(curvePool), type(uint256).max);
        maUSDC.approve(address(curvePool), type(uint256).max);
        maUSDT.approve(address(curvePool), type(uint256).max);

        // Deposit funds into Curve's Polygon AAVE Stablecoin Pool
        uint actual_LP_token_amount = ICurve_AAVE_Stable_Pool(curvePool).add_liquidity(aaveTokenAmount,0);
        //update public LP token amount minted
        totalLPTokensMinted = actual_LP_token_amount;

        isProvided = true;
    }

    function D_WithdrawFromCurve() /*automated*/ public {
        address curvePool = 0x445FE580eF8d70FF569aB36e80c647af338db351;
        address am3CRV = 0xE7a24EF0C5e95Ffb0f6684b813A78F2a3AD7D171;
        uint LPTokenAmt = IERC20(am3CRV).balanceOf(address(this));

        uint256[3] memory expected;
      
        ICurve_AAVE_Stable_Pool(curvePool).remove_liquidity(LPTokenAmt, expected );
    }

    function E_SwapStablesForEth() /*automated*/ public {
        
        IERC20 DAI = IERC20(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);
        IERC20 USDC = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
        IERC20 USDT = IERC20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
        address uniswapAddress = 0x93bcDc45f7e62f89a8e901DC4A0E2c6C427D9F25;
        IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(uniswapAddress);

        uint DAIamt = DAI.balanceOf(address(this));
        uint USDCamt = USDC.balanceOf(address(this));
        uint USDTamt = USDT.balanceOf(address(this));

        DAI.approve(uniswapAddress, DAIamt);
        USDC.approve(uniswapAddress, USDCamt);
        USDT.approve(uniswapAddress, USDTamt);


        uint deadline = block.timestamp + 15; 
        uniswapRouter.swapExactTokensForETH(DAIamt, 0, getPathForDAItoETH(), address(this), deadline);
        uniswapRouter.swapExactTokensForETH(USDCamt, 0, getPathForUSDCtoETH(), address(this), deadline);
        uniswapRouter.swapExactTokensForETH(USDTamt, 0, getPathForUSDTtoETH(), address(this), deadline);

        endingAmt = address(this).balance;

    }

// ========================================= internal utility methods ✨


    function getPathForETHtoDAI() internal pure returns (address[] memory) {
        IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(0x93bcDc45f7e62f89a8e901DC4A0E2c6C427D9F25);
        address DAI = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = DAI;
    
        return path;
    }

    function getPathForETHtoUSDC() internal pure returns (address[] memory) {
        address USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
        IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(0x93bcDc45f7e62f89a8e901DC4A0E2c6C427D9F25);

        address[] memory path = new address[](2);
    
        path[0] = uniswapRouter.WETH();
        path[1] = USDC;
    
        return path;
    }
    
    function getPathForETHtoUSDT() internal pure returns (address[] memory) {
        address USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
        IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(0x93bcDc45f7e62f89a8e901DC4A0E2c6C427D9F25);
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = USDT;
    
        return path;
    }

    function getThird() public view returns (uint256) {
        return address(this).balance / 3;
    }

    function getPathForDAItoETH() internal pure returns (address[] memory) {
        IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(0x93bcDc45f7e62f89a8e901DC4A0E2c6C427D9F25);
        address DAI = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
        address[] memory path = new address[](2);    
        path[0] = DAI;
        path[1] = uniswapRouter.WETH();  

        return path;  
    }

    function getPathForUSDCtoETH() internal pure returns (address[] memory) {
        IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(0x93bcDc45f7e62f89a8e901DC4A0E2c6C427D9F25);
        address USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
        address[] memory path = new address[](2);    
        path[0] = USDC;
        path[1] = uniswapRouter.WETH();  

        return path;  
    }

    function getPathForUSDTtoETH() internal pure returns (address[] memory) {
        IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(0x93bcDc45f7e62f89a8e901DC4A0E2c6C427D9F25);
        address USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
        address[] memory path = new address[](2);    
        path[0] = USDT;
        path[1] = uniswapRouter.WETH();  

        return path;  
    }


    /* Testing functions, TO BE DELETED */
    function getDaiBalance() public view returns (uint) {
        address DAI = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
        uint daibalance = IERC20(DAI).balanceOf(address(this));
        return daibalance;
    }

    function getUsdcBalance() public view returns (uint) {
        address USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
        uint daibalance = IERC20(USDC).balanceOf(address(this));
        return daibalance;
    }

    function getUsdtBalance() public view returns (uint) {
        address USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
        uint daibalance = IERC20(USDT).balanceOf(address(this));
        return daibalance;
    }
    

    function maDaiBalance() public view returns (uint) {
        address maDAI = 0x27F8D03b3a2196956ED754baDc28D73be8830A6e;
        uint daibalance = IERC20(maDAI).balanceOf(address(this));
        return daibalance;
    }

    function maUSDCBalance() public view returns (uint) {
        address maUSDC = 0x1a13F4Ca1d028320A707D99520AbFefca3998b7F;
        uint daibalance = IERC20(maUSDC).balanceOf(address(this));
        return daibalance;
    }

    function maUSDTBalance() public view returns (uint) {
        address maUSDT = 0x60D55F02A771d515e077c9C2403a1ef324885CeC;
        uint daibalance = IERC20(maUSDT).balanceOf(address(this));
        return daibalance;
    }

    function am3CRVTBalance() public view returns (uint) {
        address am3CRV = 0xE7a24EF0C5e95Ffb0f6684b813A78F2a3AD7D171;
        uint am3CRVamt = IERC20(am3CRV).balanceOf(address(this));
        return am3CRVamt;
    }


    //MODIFIERS
    //can only be called by chainlink keeper
    modifier automated() {
        require(msg.sender == keeper);
        _;
    }
    
    // receive function 
  receive() payable external {}

}


interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);
}


interface ILendingPool {
    function deposit(address _asset, uint256 _amount, address _onBehalfOf, uint16 referralCode) external;
}

interface ILendingPoolAddressesProvider {

  function getLendingPool() external view returns (address);

}


interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    

}

interface IUniswapV2Router02 is IUniswapV2Router01 {

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


interface ICurve_AAVE_Stable_Pool {
    function calc_token_amount(uint256[3] memory _amounts, bool _is_deposit) external returns (uint256);
    function remove_liquidity(uint256 _amount, uint[3] memory _min_amounts) external returns (uint256);
    function add_liquidity(uint256[3] memory _amounts, uint256 _min_mint_amount) external returns (uint256);
}