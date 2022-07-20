// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./Wallet.sol";
import "./IUniswapV2Router.sol";
import "./PriceConsumerV3.sol";
import "./PoolLPToken.sol";
import "./strategies/IStrategy.sol";
import "./IPool.sol";
import "./IPriceFeed.sol";

import { PoolLib } from  "./PoolLib.sol";


contract Pool is IPool, Wallet, KeeperCompatibleInterface  {

    event Swapped(string swapType, uint spent, uint bought, uint slippage);
    event SlippageInfo(uint slippage, uint thereshold, uint amountIn, uint amountMin);

    uint public slippageThereshold = 500; // allow for 5% slippage on swaps (aka should receive at least 95% of the expected token amount)
    uint public immutable upkeepUpdateInterval;
    uint public lastUpkeepTimeStamp;

    PoolLib.SwapInfo[] public swaps;

    address public immutable uniswapV2RouterAddress;
    address public immutable priceFeedAddress;
    address public immutable lpTokenAddress;
    address public immutable depositTokenAddress;
    address public immutable investTokenAddress;
    address public strategyAddress;
 
    constructor(
        address _uniswapV2RouterAddress, 
        address _priceFeedAddress, 
        address _depositTokenAddress, 
        address _investTokenAddress, 
        address _lpTokenAddress,
        address _strategyAddress,
        uint _updateInterval) Wallet(_depositTokenAddress) {

        uniswapV2RouterAddress = _uniswapV2RouterAddress;
        priceFeedAddress = _priceFeedAddress;
        strategyAddress = _strategyAddress;
        lpTokenAddress = _lpTokenAddress;
        depositTokenAddress = _depositTokenAddress;
        investTokenAddress = _investTokenAddress;

        upkeepUpdateInterval = _updateInterval;
        lastUpkeepTimeStamp = block.timestamp;
    }


    // returns the value of the deposit tokens in USD using the latest pricefeed price
    function depositTokenValue() public override view returns(uint) {
        return depositToken.balanceOf(address(this));
    }


    // returns the value of the invest tokens in USD using the latest pricefeed price
    function investedTokenValue() public override view returns(uint) {

        IERC20Metadata investToken = IERC20Metadata(investTokenAddress);
        IPriceFeed priceFeed = IPriceFeed(priceFeedAddress);

        uint investTokens = investToken.balanceOf(address(this));
        int investTokenPrice = priceFeed.getLatestPrice();
        require (investTokenPrice >= 0, "Invest token price can't be negative");

        uint depositTokenDecimals = uint(depositToken.decimals());
        uint investTokensDecimals = uint(investToken.decimals());
        uint priceFeedPrecision = 10 ** uint(priceFeed.decimals());
       
        uint value;        
         // portoflio value is the sum of deposit token value and invest token value in the unit of the deposit token
        if (investTokensDecimals >= depositTokenDecimals) {
            // invest token has more decimals than deposit token, have to divide the invest token value by the difference
            uint decimalsConversionFactor = 10 ** (investTokensDecimals - depositTokenDecimals);
            value = investTokens * uint(investTokenPrice) / decimalsConversionFactor / priceFeedPrecision;
        } else {
            // invest token has less decimals tham deposit token, have to multiply invest token value by the difference
            uint decimalsConversionFactor = 10 ** (depositTokenDecimals - investTokensDecimals);
            value = investTokens * uint(investTokenPrice) * decimalsConversionFactor / priceFeedPrecision;
        }

        return value;
    }


    // returns the portfolio value in depositTokens
    function totalPortfolioValue() public override view returns(uint) {
        uint depositTokens = depositToken.balanceOf(address(this));
        return depositTokens + investedTokenValue();
    }



    //////  PUBLIC FUNCTIONS  ////// 

    // Returns the % of the fund owned by the input _addr using 18 digits precision
    function portfolioPercentage(address _addr) public view returns (uint) {
        PoolLPToken lpToken = PoolLPToken(lpTokenAddress);

        // the % of the portfolio of the user
        if (lpToken.totalSupply() == 0) return 0;

        uint precision = 10 ** uint(portfolioPercentageDecimals());
        return precision * lpToken.balanceOf(_addr) / lpToken.totalSupply();
    }


    function portfolioPercentageDecimals() public view returns (uint8) {
        return IPriceFeed(priceFeedAddress).decimals();
    }


    function portfolioAllocartion() public view returns (uint)  {
        uint precision = 10 ** uint(portfolioPercentageDecimals());
        return (PoolLPToken(lpTokenAddress).totalSupply() == 0) ? 0 : precision * investedTokenValue() / totalPortfolioValue(); 
    }


    function portfolioValue(address _addr) public view returns (uint) {
        // the value of the portfolio allocated to the user, espressed in deposit tokens
        uint precision = 10 ** uint(portfolioPercentageDecimals());
        return totalPortfolioValue() * portfolioPercentage(_addr) / precision;
    }


    // User deposits 'amount' of depositTokens into the pool
    function deposit(uint amount) public override {

        PoolLPToken lpToken = PoolLPToken(lpTokenAddress);
        PoolLPToken investToken = PoolLPToken(investTokenAddress);

        // portfolio allocation before the deposit
        uint investTokenPerc = portfolioAllocartion();

        // transfer deposit amount into the pool
        super.deposit(amount);

        uint depositLPTokens;

        if (lpToken.totalSupply() == 0) {
             ///// If first deposit => allocate the inital LP tokens amount to the user
            depositLPTokens = amount;
            invest(); // run the strategy after the first deposit
        } else {
            ///// if already have allocated LP tokens => calculate the additional LP tokens for this deposit

            // calculate portfolio % of the deposit (using lpPrecision digits precision)
            uint portFolioValue = totalPortfolioValue();
            require(portFolioValue > 0, "Portfolio value is 0");

            uint lpPrecision = 10 ** uint(lpToken.decimals());
            uint portFolioPercentage = lpPrecision * amount / portFolioValue;

            // calculate the amount of LP tokens for the deposit so that they represent 
            // a % of the existing LP tokens equivalent to the % value of this deposit to the whole portfolio value.
            // 
            // X := P * T / (1 - P)  
            //      X: additinal LP toleks to allocate to the user to account for this deposit
            //      P: Percentage of portfolio accounted by this deposit
            //      T: total LP tokens allocated before this deposit
    
            depositLPTokens = (portFolioPercentage * lpToken.totalSupply()) / ((1 * lpPrecision) - portFolioPercentage);
            uint precision = 10 ** uint(portfolioPercentageDecimals());
            uint rebalanceAmount = investTokenPerc * amount / precision;

            // swap some of the deposit amount into investTokens to keep the pool balanced at current levels
            swapIfNotExcessiveSlippage(StrategyAction.BUY, address(depositToken), address(investToken), rebalanceAmount, false);
        }

        // mint lp tokens to the user
        lpToken.mint(msg.sender, depositLPTokens);
    }


    // Withdraw an 'amount' of depositTokens from the pool
    function withdraw(uint amount) public override {
        uint value = totalPortfolioValue();
        require (value > 0, "Portfolio value is 0");

        // the % of the whole pool to be withdrawn
        uint precision = 10 ** uint(portfolioPercentageDecimals());
        uint withdrawPerc = precision * amount / value;

        // the LP amount to withdraw
        uint lpAmount = PoolLPToken(lpTokenAddress).totalSupply() * withdrawPerc / precision;

        withdrawLP(lpAmount);
    }


    // Withdraw all LP tokens
    function withdrawAll() public  {
        withdrawLP(PoolLPToken(lpTokenAddress).balanceOf(msg.sender));
    }

    // Withdraw the amount of lp tokens provided
    function withdrawLP(uint amount) public {

        PoolLPToken lpToken = PoolLPToken(lpTokenAddress);
        PoolLPToken investToken = PoolLPToken(investTokenAddress);

        require(amount > 0, "Invalid LP amount");
        require(lpToken.totalSupply() > 0, "No LP tokens minted");
        require(amount <= lpToken.balanceOf(msg.sender), "LP balance exceeded");

        uint precision = 10 ** uint(portfolioPercentageDecimals());
        uint withdrawPerc = precision * amount / lpToken.totalSupply();

        // burn the user LP
        lpToken.burn(msg.sender, amount);

        // calculate amount of depositTokens & investTokens to withdraw
        uint depositTokensBeforeSwap = depositToken.balanceOf(address(this));
        uint investTokensBeforeSwap = investToken.balanceOf(address(this));

        // the amount of deposit and invest tokens to withdraw
        uint withdrawDepositTokensAmount = depositTokensBeforeSwap * withdrawPerc / precision;
        uint withdrawInvestTokensTokensAmount = investTokensBeforeSwap * withdrawPerc / precision;

        uint depositTokensSwapped = 0;
        // check if have to swap some invest tokens back into deposit tokens
        if (withdrawInvestTokensTokensAmount > 0) {
            // swap some investTokens into depositTokens to be withdrawn
            uint256 amountMin = getAmountOutMin(address(investToken), address(depositToken), withdrawInvestTokensTokensAmount);
            swap(address(investToken), address(depositToken), withdrawInvestTokensTokensAmount, amountMin, address(this));
        
            // determine how much depositTokens where swapped
            uint depositTokensAfterSwap = depositToken.balanceOf(address(this));
            require(depositTokensAfterSwap >= depositTokensBeforeSwap, "Deposit tokens after swap are less than amount before swap");
            depositTokensSwapped = depositTokensAfterSwap - depositTokensBeforeSwap;
        }


        // transfer depositTokens to the user
        uint amountToWithdraw = withdrawDepositTokensAmount + depositTokensSwapped;        
        super.withdraw(amountToWithdraw);
    }


    function getSwapsInfo() public view returns (PoolLib.SwapInfo[] memory) {
        return swaps;
    }

  
    // Returns the min amount of tokens expected from the swap and the slippage calculated as a percentage from the feed price. 
    // The returned percentage is returned with 4 digits decimals
    // E.g: For a 5% slippage below the expected amount 500 is returned
    function slippagePercentage(address tokenIn, address tokenOut, uint amountIn) public view returns (uint amountMin, uint slippage) {
        IPriceFeed priceFeed = IPriceFeed(priceFeedAddress);
        IERC20Metadata investToken = IERC20Metadata(investTokenAddress);

        require(priceFeed.getLatestPrice() > 0, "Invalid price");

        uint price = uint(priceFeed.getLatestPrice());
        uint pricePrecision = 10 ** uint(priceFeed.decimals());

        uint amountExpected;

        // swap USD => ETH
        if (tokenIn == address(depositToken) && tokenOut == address(investToken)) {
            uint tokenInDecimals = uint(depositToken.decimals());
            uint tokenOutDecimals = uint(investToken.decimals());
            uint amountInAdjusted = PoolLib.adjustAmountDecimals (tokenInDecimals, tokenOutDecimals, amountIn);
            amountExpected = amountInAdjusted * pricePrecision / price;
        } 

        // swap ETH => USD
        if (tokenIn == address(investToken) && tokenOut == address(depositToken)) {
            uint tokenInDecimals = uint(investToken.decimals());
            uint tokenOutDecimals = uint(depositToken.decimals());
            uint amountInAdjusted = PoolLib.adjustAmountDecimals (tokenInDecimals, tokenOutDecimals, amountIn);
            amountExpected = amountInAdjusted * price / pricePrecision;
        }

        require(amountExpected > 0, "Invalid expected amount received after swap. It should be greater than 0 but it was not.");
       
        amountMin = getAmountOutMin(tokenIn, tokenOut, amountIn);
        if (amountMin >= amountExpected) return (amountMin, 0);

        slippage = 10000 - (10000 * amountMin / amountExpected); // e.g 10000 - 9500 = 500  (5% slippage)
    }



    function invest() public {
        // evaluate strategy to see if we should BUY or SELL
        (StrategyAction action, uint amountIn) = IStrategy(strategyAddress).evaluate();

        if (action == StrategyAction.NONE || amountIn == 0) {
            // No rebalancing needed
            emit Swapped("None", 0, 0, 0);
            return;
        }

        address tokenIn;
        address tokenOut;

        if (action == StrategyAction.BUY) {
            tokenIn = depositTokenAddress;
            tokenOut = investTokenAddress;
        } else if (action == StrategyAction.SELL) {
            tokenIn = investTokenAddress;
            tokenOut = depositTokenAddress;
        }

        swapIfNotExcessiveSlippage(action, tokenIn, tokenOut, amountIn, true);
    }


    //////  OWNER FUNCTIONS  ////// 

    function setSlippageThereshold(uint _slippage) public onlyOwner {
        slippageThereshold = _slippage;
    }

    function setStrategy(address _strategyAddress) public onlyOwner {
        strategyAddress = _strategyAddress;
    }


    //////  UPKEEP FUNCTIONALITY  ////// 

    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        upkeepNeeded = (block.timestamp - lastUpkeepTimeStamp) > upkeepUpdateInterval;
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        if ((block.timestamp - lastUpkeepTimeStamp) > upkeepUpdateInterval ) {
            lastUpkeepTimeStamp = block.timestamp;
            invest();
        }
    }


    ////// TOKEN SWAP FUNCTIONALITY ////// 

    function swapIfNotExcessiveSlippage(StrategyAction action, address _tokenIn, address _tokenOut, uint256 _amountIn, bool log) internal {

        IERC20Metadata investToken = IERC20Metadata(investTokenAddress);

        // ensure slippage is not too much (e.g. <= 500 for a 5% slippage)
        (uint amountMin, uint slippage) = slippagePercentage(_tokenIn, _tokenOut, _amountIn);
        emit SlippageInfo(slippage, slippageThereshold, _amountIn, amountMin);

        if (slippage > slippageThereshold) {
            revert("Slippage thereshold exceeded");
        }

        uint256 depositTokenBalanceBefore = depositToken.balanceOf(address(this));
        uint256 investTokenBalanceBefore = investToken.balanceOf(address(this));

        // perform swap required to rebalance the portfolio
       swap(_tokenIn, _tokenOut, _amountIn, amountMin, address(this));

        // balances after swap
        uint256 depositTokenBalanceAfter = depositToken.balanceOf(address(this));
        uint256 investTokenBalanceAfter = investToken.balanceOf(address(this));

        uint256 spent;
        uint256 bought;
        string memory swapType;
        
        if (action == StrategyAction.BUY) {
            swapType = "BUY";
            spent = depositTokenBalanceBefore - depositTokenBalanceAfter;
            bought = investTokenBalanceAfter - investTokenBalanceBefore;
        } else if (action == StrategyAction.SELL) {
            swapType = "SELL";
            spent = investTokenBalanceBefore - investTokenBalanceAfter;
            bought = depositTokenBalanceAfter - depositTokenBalanceBefore;
        }
        if (log) { 
            logSwap(swapType, _tokenIn, _tokenOut, spent, bought);
        }

        emit Swapped(swapType, spent, bought, slippage);
    }

  

    function logSwap(string memory swapType, address tokenIn, address tokenOut, uint amountIn, uint amountOut) internal {
        PoolLib.SwapInfo memory info = PoolLib.swapInfo(
                swapType, tokenIn, tokenOut, amountIn, amountOut, 
                depositTokenAddress, investTokenAddress, priceFeedAddress);

        swaps.push(info);
    }


    function swap(address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _amountOutMin, address _to) internal {

        // allow the uniswapv2 router to spend the token we just sent to this contract
        IERC20(_tokenIn).approve(uniswapV2RouterAddress, _amountIn);

        // path is an array of addresses and we assume there is a direct pair btween the in and out tokens
        address[] memory path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;

        // the deadline is the latest time the trade is valid for
        // for the deadline we will pass in block.timestamp
        IUniswapV2Router(uniswapV2RouterAddress).swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            path,
            _to,
            block.timestamp
        );
    }

    // return the minimum amount from a swap
    function getAmountOutMin(address _tokenIn, address _tokenOut, uint256 _amountIn) internal view returns (uint) {
        address[] memory path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;

        uint256[] memory amountOutMins = IUniswapV2Router(uniswapV2RouterAddress).getAmountsOut(_amountIn, path);
        require(amountOutMins.length >= path.length , "Invalid amountOutMins size");

        return amountOutMins[path.length - 1];
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "../IPriceFeed.sol";

enum StrategyAction { NONE, BUY, SELL }

interface IStrategy {
    function name() external view returns(string memory);
    function description() external view returns(string memory);
    function evaluate() external returns(StrategyAction action, uint amount);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Wallet is Ownable {

    event Deposited(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount);

    uint public totalDeposited = 0;
    uint public totalWithdrawn = 0;

    // depositToken token balances
    mapping (address => uint) public deposits;
    mapping (address => uint) public withdrawals;

    // users that deposited depositToken tokens into their balances
    address[] internal usersArray;
    mapping (address => bool) internal users;
    IERC20Metadata internal depositToken;

    constructor(address _depositTokenAddress) {
        depositToken = IERC20Metadata(_depositTokenAddress);
    }

    function deposit(uint amount) public virtual {
        require(amount > 0, "Deposit amount is 0");
        require(depositToken.allowance(msg.sender, address(this)) >= amount, "Insufficient allowance to deposit");

        deposits[msg.sender] = deposits[msg.sender] + amount;
        totalDeposited = totalDeposited + amount;
        // remember addresses that deposited tokens
        if (!users[msg.sender]) {
            users[msg.sender] = true;
            usersArray.push(msg.sender);
        }
        depositToken.transferFrom(msg.sender, address(this), amount);

        emit Deposited(msg.sender, amount);
    }

    function withdraw(uint amount) public virtual {
        require(amount > 0, "Withdraw amount is 0");
        require(depositToken.balanceOf(address(this)) >= amount, "Withdrawal amount exceeds balance");

        withdrawals[msg.sender] = withdrawals[msg.sender] + amount;
        totalWithdrawn = totalWithdrawn + amount;

        depositToken.transfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./IPriceFeed.sol";


contract PriceConsumerV3 is IPriceFeed {

    AggregatorV3Interface internal priceFeed;

    /**
      * Chainlink pricefeed addresses.
      *
      * Aggregator: ETH/USD
      * Kovan: '0x9326BFA02ADD2366b30bacB125260Af641031331'
      * Polygon: '0xF9680D99D6C9589e2a93a78A04A279e509205945'
     */
    constructor(address _priceFeed) {
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public override view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();

        return price;
    }

    /**
     * Returns the latest price
     */
    function getLatestTimestamp() public override view returns (uint) {
        (
            /*uint80 roundID*/,
            /*int price*/,
            /*uint startedAt*/,
            uint timeStamp,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();

        return timeStamp;
    }

    function decimals() public override view returns (uint8) {
        return priceFeed.decimals();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./IPriceFeed.sol";

library PoolLib {

    struct SwapInfo {
        uint timestamp;
        string side;
        uint feedPrice;
        uint bought;
        uint sold;
        uint depositTokenBalance;
        uint investTokenBalance;
    }

    function adjustAmountDecimals(uint tokenInDecimals, uint tokenOutDecimals, uint amountIn) internal pure returns (uint) {

        uint amountInAdjusted = (tokenOutDecimals >= tokenInDecimals) ?
                amountIn * (10 ** (tokenOutDecimals - tokenInDecimals)) :
                amountIn / (10 ** (tokenInDecimals - tokenOutDecimals));

        return amountInAdjusted;
    }

    function swapInfo(string memory swapType,
        address tokenIn, address tokenOut,
        uint amountIn, uint amountOut,
        address depositTokenAddress, address investTokenAddress, address priceFeedAddress) internal view returns (SwapInfo memory) {

        require(IPriceFeed(priceFeedAddress).getLatestPrice() > 0, "Invalid price");

        IERC20Metadata depositToken = IERC20Metadata(depositTokenAddress);
        IERC20Metadata investToken = IERC20Metadata(investTokenAddress);
        
        // Record swap info
        PoolLib.SwapInfo memory info = PoolLib.SwapInfo({
            timestamp: block.timestamp,
            side: swapType,
            feedPrice: uint(IPriceFeed(priceFeedAddress).getLatestPrice()),
            bought: amountOut,
            sold: amountIn,
            depositTokenBalance: depositToken.balanceOf(address(this)),
            investTokenBalance: investToken.balanceOf(address(this))
        });

        return info;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./MinterRole.sol";

/**
 * The LP Token of the pool.
 * New tokens get minted by the Pool when users deposit into the pool
 * and get burt when users withdraw from the pool.
 * Only the Pool contract should be able to mint/burn these tokens.
 */

contract PoolLPToken is ERC20, MinterRole {

    uint8 immutable decs;

    constructor (string memory _name, string memory _symbol, uint8 _decimals) ERC20(_name, _symbol) {
        decs = _decimals;
    }

    function mint(address to, uint256 value) public onlyMinter returns (bool) {
        _mint(to, value);
        return true;
    }

    function burn(address to, uint256 value) public onlyMinter returns (bool) {
        _burn(to, value);
        return true;
    }

    function decimals() public view override returns (uint8) {
        return decs;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;


/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0), "0x0 account");
        require(!has(role, account), "Account already has role");

        role.bearer[account] = true;
    }

    /**
     * @dev remove an account's access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0), "0x0 account");
        require(has(role, account), "Account does not have role");

        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "0x0 account");
        return role.bearer[account];
    }
}


contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "Non minter call");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IUniswapV2Router {

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function swapExactTokensForTokens(
        uint amountIn, //amount of tokens we are sending in
        uint amountOutMin, //the minimum amount of tokens we want out of the trade
        address[] calldata path,  //list of token addresses we are going to trade in.  this is necessary to calculate amounts
        address to,  //this is the address we are going to send the output tokens to
        uint deadline //the last time that the trade is valid for
    ) external returns (uint[] memory amounts);

    function WETH() external returns (address addr);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IPriceFeed {
    function getLatestPrice() external view returns (int);
    function getLatestTimestamp() external view returns (uint);
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IPool {
    function totalPortfolioValue() external view returns(uint);
    function investedTokenValue() external view returns(uint);
    function depositTokenValue() external view returns(uint);
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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