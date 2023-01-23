/**
 *Submitted for verification at Etherscan.io on 2023-01-23
*/

// SPDX-License-Identifier: Unlicense

// File contracts/interfaces/IAaveProtocolDataProvider.sol

pragma solidity ^0.8.0;

interface IAaveProtocolDataProvider {
function getReserveTokensAddresses(address asset)
    external
    view
    returns (
      address aTokenAddress,
      address stableDebtTokenAddress,
      address variableDebtTokenAddress
    );
}


// File contracts/interfaces/IERC20.sol

pragma solidity ^0.8.0;
interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function decimals() external view returns (uint8);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
}


// File contracts/interfaces/ILendingPool.sol

pragma solidity ^0.8.0;

/**
 * @dev Interface of AAVE V2 Lending Pools
 */
interface ILendingPool {
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

}


// File contracts/interfaces/IUniswapV2Router.sol

pragma solidity ^0.8.0;

interface IUniswapV2Router {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    )
        external
        returns (
            uint amountA,
            uint amountB,
            uint liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

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
}


// File contracts/interfaces/IUniswapV2Pair.sol

interface IUniswapV2Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}


// File contracts/interfaces/IUniswapV2Factory.sol

pragma solidity ^0.8.0;

interface IUniswapV2Factory {
    function getPair(address token0, address token1) external view returns (address);
}


// File @chainlink/contracts/src/v0.8/interfaces/[email protected]

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


// File contracts/DollarHedgerV2.sol

pragma solidity ^0.8.13;







contract DollarHedgerV2 {
    address private constant FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f; //goerli, mainnnet
    address private constant ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; //goerli, mainnet
    address private constant LENDINGPOOL = 0x4bd5643ac6f66a5237E18bfA7d47cF22f1c9F210; //goerli
    address private constant AAVEPROTOCOLDATAPROVIDER = 0x927F584d4321C1dCcBf5e2902368124b02419a1E; //goerli

    address private constant BTC_USD = 0xA39434A63A52E749F02807ae27335515BA4b07F7; // goerli, 1% deviation
    address private constant SNX_USD = 0xdC5f59e61e51b90264b38F0202156F07956E2577; // goerli, 1% deviation
    address private constant ETH_USD = 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e; // goerli, 1% deviation

    mapping(address => bool) public allowedTokenA;
    mapping(address => bool) public allowedTokenB;

    mapping(address => address) public OracleForTokenA;

    /// @notice Using Interface as Oracle to interact with oracle
    AggregatorV3Interface internal Oracle;
    
    constructor() {
        OracleForTokenA[0xf4423F4152966eBb106261740da907662A3569C5] = BTC_USD; // WBTC
        OracleForTokenA[0xFc1Ab0379db4B6ad8Bf5Bc1382e108a341E2EaBb] = SNX_USD; // SNX
        //Token A:
        allowedTokenA[0xf4423F4152966eBb106261740da907662A3569C5] = true; // WBTC
        allowedTokenA[0xFc1Ab0379db4B6ad8Bf5Bc1382e108a341E2EaBb] = true; // SNX
        //Token B:
        allowedTokenB[0xa7c3Bf25FFeA8605B516Cf878B7435fe1768c89b] = true; // BUSD
        allowedTokenB[0x75Ab5AB1Eef154C0352Fc31D2428Cef80C7F8B33] = true; // DAI
        allowedTokenB[0x4e62eB262948671590b8D967BDE048557bdd03eD] = true; // SUSD
        allowedTokenB[0x9FD21bE27A2B059a288229361E2fA632D8D2d074] = true; // USDC
        allowedTokenB[0x65E2fe35C30eC218b46266F89847c63c2eDa7Dc7] = true; // USDT
    }

    modifier onlyApprovedTokens(address tokenA, address tokenB) {
        require(allowedTokenA[tokenA], "Token A not approved for hedging");
        require(allowedTokenB[tokenB], "Token B not approved for hedging");
        _;
    }
    // WBTC: 0xf4423F4152966eBb106261740da907662A3569C5
    // USDC: 0x9FD21bE27A2B059a288229361E2fA632D8D2d074 - 1443042852
    // requires msg sender to call approve delegation on Debt WBTC to this contract address - high number
    // requires msg sender to approve tokenB to this contract address
    // 10000000000 is 10k USDC - 75% is 75000000
    function hedgePosition(uint256 _amountProvidedOnTokenB, uint256 _loanPercentage, address _tokenA, address _tokenB, uint256 aaveInterestRateMode) onlyApprovedTokens(_tokenA, _tokenB) public {
        // TODO: check that tokens exist in both aave and uniswap
        IERC20(_tokenB).transferFrom(msg.sender, address(this), _amountProvidedOnTokenB);
       _hedgePosition(_amountProvidedOnTokenB, _loanPercentage, _tokenA, _tokenB, aaveInterestRateMode);
    }

    function _hedgePosition(uint256 _amountProvidedOnTokenB, uint256 _loanPercentage, address _tokenA, address _tokenB, uint256 aaveInterestRateMode) internal {
        //Calculate collateral and amount to borrow in USD
        uint256 collateral = (_amountProvidedOnTokenB *100000000)/ (_loanPercentage+100000000); // 10000000000 / 1.75 = 5714285714
        uint256 amountToBorrowUSD = (collateral * (_loanPercentage))/1000000; //4285 + 6 zeros - add 2 zeros to match decimals, as wbtc has 8 decimals
        // Approve transfer of collateral in tokenB to Aave's Lending pool contract
        IERC20(_tokenB).approve(LENDINGPOOL, collateral);
        //Deposit to AAVE
        ILendingPool(LENDINGPOOL).deposit(_tokenB, collateral, msg.sender, 0);
        // interest-bearing aTokens transferred to contract at this point. Amount is 1:1 with collateral

        // Calculate amountToBorrow from Aave in TokenA decimals using price from oracle
        uint256 amountToBorrow =  ((amountToBorrowUSD * 10**8) / getPriceFromOracle(_tokenA));
        // user must have delegatedApproval by this point. Get a loan from Aave
        ILendingPool(LENDINGPOOL).borrow(_tokenA, amountToBorrow, aaveInterestRateMode, 0, msg.sender);
        // Debt token transferred to user. Borrowed amount transferred to contract at this point.
        // Add liquidity to Uniswap
        (uint amountAprovided, ) = _addUniswapLiquidity(_tokenA, _tokenB, IERC20(_tokenA).balanceOf(address(this)), IERC20(_tokenB).balanceOf(address(this)));
        // Implement zap to add liquidity to the aToken leftovers
        if (amountToBorrow > amountAprovided) {
            zap(_tokenA, _tokenB, amountToBorrow - amountAprovided);
        }
    }

    // WBTC: 0xf4423F4152966eBb106261740da907662A3569C5
    // USDC: 0x9FD21bE27A2B059a288229361E2fA632D8D2d074
    // requires msg sender to approve UNI LP tokens to contract 
    // requires msg sender to approve aToken to contract
    // All aTokens of the USDC the user holds will be liquidated
    function liquidatePosition(address _tokenA, address _tokenB, uint256 aaveInterestRateMode, uint256 liquidationPercentage) public {
        // transfer all LP tokens to contract & call remove liquidity
        (uint256 _amountA, uint256 _amountB) = removeUniswapLiquidity(_tokenA, _tokenB, 0);
        (address aTokenB, ,) = IAaveProtocolDataProvider(AAVEPROTOCOLDATAPROVIDER).getReserveTokensAddresses(_tokenB);        
        // If aToken amount is not enough to repay loan, swap for more
        address debtToken;
        if (aaveInterestRateMode == 1) {
            (, debtToken,) = IAaveProtocolDataProvider(AAVEPROTOCOLDATAPROVIDER).getReserveTokensAddresses(_tokenA);
        } else {
            (, ,debtToken) = IAaveProtocolDataProvider(AAVEPROTOCOLDATAPROVIDER).getReserveTokensAddresses(_tokenA);
        }
        if (IERC20(debtToken).balanceOf(msg.sender) > _amountA) {
            _amountA += _swapForExact(_tokenB, _tokenA, IERC20(debtToken).balanceOf(msg.sender) - _amountA, _amountB);
        }
        // approve tokenA to Aave & call repay
        IERC20(_tokenA).approve(LENDINGPOOL, _amountA);
        // pay back loan
        ILendingPool(LENDINGPOOL).repay(_tokenA, _amountA + 10**2, aaveInterestRateMode, msg.sender);

        // pay back interest bearing token, transfer them to the contract from the user
        uint256 aTokenBbalance = IERC20(aTokenB).balanceOf(msg.sender);
        IERC20(aTokenB).transferFrom(msg.sender, address(this), aTokenBbalance); // instead of aTokenBbalance, use amount withdrawn from UNI (_amountB)
        IERC20(aTokenB).approve(LENDINGPOOL, aTokenBbalance);
        ILendingPool(LENDINGPOOL).withdraw(_tokenB, type(uint).max, address(this));

        if (liquidationPercentage > 0) { 
            uint256 tokenBBalance = IERC20(_tokenB).balanceOf(address(this));
            uint256 tokenBBalanceToRefund = (tokenBBalance *100000000)/ (liquidationPercentage+100000000);
            IERC20(_tokenB).approve(msg.sender, tokenBBalanceToRefund); //approve & process withdrawal
            IERC20(_tokenB).transfer(msg.sender, tokenBBalanceToRefund);
            if (tokenBBalanceToRefund > tokenBBalance) {
                _hedgePosition(tokenBBalanceToRefund - tokenBBalance, 70000000, _tokenA, _tokenB, 2);
            } else {
                _hedgePosition(tokenBBalance - tokenBBalanceToRefund, 70000000, _tokenA, _tokenB, 2);
            }
        } else {
            IERC20(_tokenB).approve(msg.sender, IERC20(_tokenB).balanceOf(address(this)));
            IERC20(_tokenB).transfer(msg.sender, IERC20(_tokenB).balanceOf(address(this)));
        }
    }

    function getUnderlyingBalance(address pair) public view returns (uint256,uint256) {
        (uint112 reserve0,uint112 reserve1,) = IUniswapV2Pair(pair).getReserves(); // USDC-WBTC
        uint256 LPtokensA = (reserve0 * IERC20(pair).balanceOf(msg.sender)) / IERC20(pair).totalSupply(); // usdc
        uint256 LPtokensB = (reserve1 * IERC20(pair).balanceOf(msg.sender)) / IERC20(pair).totalSupply(); // wbtc
        return (LPtokensA,LPtokensB);
    }
    
    // Rebalance functions

    // Sell portion of your LP tokens to increase your collateral
    // Ideal if the price of tokenA goes up.
    // requires msg sender to call approve on UNI LP token
    function decreasePosition(address _tokenA, address _tokenB, uint256 _liquidityToRemove) public {
        (uint256 _amountA, uint256 _amountB) = removeUniswapLiquidity(_tokenA, _tokenB, _liquidityToRemove);
        // Swap TokenA to TokenB to increase collateral. Eg Sell WBTC to buy USDC
        //uint256 amountReceived = _swap(_tokenA, _tokenB, _amountA);
        // Pay back loan instead of swapping the tokens
        IERC20(_tokenA).approve(LENDINGPOOL, _amountA);
        ILendingPool(LENDINGPOOL).repay(_tokenA, _amountA, 2, msg.sender);
        // Approve transfer to AAVE
        //IERC20(_tokenB).approve(LENDINGPOOL, _amountB + amountReceived);
        IERC20(_tokenB).approve(LENDINGPOOL, _amountB);
        // Deposit to AAVE on behalf of the user
        ILendingPool(LENDINGPOOL).deposit(_tokenB, _amountB, msg.sender, 0);
    }

    // Increase leverage by reducing collateral, zapping it and adding liquidity
    // Ideal if the price of tokenA goes down.
    // requires msg sender to call approve delegation on Debt WBTC
    function increasePosition(address _tokenA, address _tokenB, uint256 _amountToBorrow, uint256 aaveInterestRateMode) public {
        // user must have given delegatedApproval at this point. Get a loan from Aave with the user's aTokens
        ILendingPool(LENDINGPOOL).borrow(_tokenA, _amountToBorrow, aaveInterestRateMode, 0, msg.sender);
        // Debt token transferred to user. Borrowed amount transferred to contract.
        // Zap for optimal one-sided supply liquidity provision
        zap(_tokenA, _tokenB, _amountToBorrow);
    }

    function getPriceFromOracle(address tokenA) internal view returns (uint256) {
        (, int256 currentTokenAprice, , , ) = AggregatorV3Interface(OracleForTokenA[tokenA]).latestRoundData();
        return uint256(currentTokenAprice);
    }

    function calculatePureCollateral(uint256 _amountProvidedOnTokenB, uint256 _loanPercentage) external pure returns (uint256) {
        return (_amountProvidedOnTokenB *100000000)/ (_loanPercentage+100000000); // 10000000000 / 1.75 = 5714285714
    } // uint256: 428571428550

    // 75% represented as 75000000
    function calculateAmountToBorrowUSD(uint256 _amountProvidedOnTokenB, uint256 _loanPercentage) external pure returns (uint256) {
        uint256 collateral = (_amountProvidedOnTokenB *100000000)/ (_loanPercentage+100000000); // 10000000000 / 1.75 = 5714285714
        uint256 amountToBorrowUSD = (collateral * (_loanPercentage))/1000000; //4285 + 6 zeros - add 2 zeros to match decimals, as wbtc has 8 decimals
        return amountToBorrowUSD;
    }

    // UNISWAP related functions

    function sqrt(uint y) private pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    /*
    s = optimal swap amount
    r = amount of reserve for token a
    a = amount of token a the user currently has (not added to reserve yet)
    f = swap fee percent
    s = (sqrt(((2 - f)r)^2 + 4(1 - f)ar) - (2 - f)r) / (2(1 - f))
    */
    function getSwapAmount(uint r, uint a) public pure returns (uint) {
        return (sqrt(r * (r * 3988009 + a * 3988000)) - r * 1997) / 1994;
    }

    function zap(
        address _tokenA,
        address _tokenB,
        uint _amountA
    ) public returns (uint256, uint256) {
        address pair = IUniswapV2Factory(FACTORY).getPair(_tokenA, _tokenB);
        (uint reserve0, uint reserve1, ) = IUniswapV2Pair(pair).getReserves();

        uint swapAmount;
        if (IUniswapV2Pair(pair).token0() == _tokenA) {
            // swap from token0 to token1
            swapAmount = getSwapAmount(reserve0, _amountA);
        } else {
            // swap from token1 to token0
            swapAmount = getSwapAmount(reserve1, _amountA);
        }

        _swap(_tokenA, _tokenB, swapAmount);
        (uint256 amountA, uint256 amountB) = _addUniswapLiquidity(_tokenA, _tokenB, IERC20(_tokenA).balanceOf(address(this)), IERC20(_tokenB).balanceOf(address(this)));
        return (amountA, amountB);
    }

    function _swapForExact(
        address _from,
        address _to,
        uint _amountToReceive,
        uint _amounToSendOut
    ) internal returns (uint) {
        IERC20(_from).approve(ROUTER, _amounToSendOut);

        address[] memory path = new address[](2);
        path = new address[](2);
        path[0] = _from;
        path[1] = _to;

        uint[] memory outputs = IUniswapV2Router(ROUTER).swapTokensForExactTokens(
            _amountToReceive,
            _amounToSendOut,
            path,
            address(this),
            block.timestamp
        );
        uint256 outputsLenght = outputs.length-1;
        return outputs[outputsLenght];
    }

    function _swap(
        address _from,
        address _to,
        uint _amount
    ) internal returns (uint) {
        IERC20(_from).approve(ROUTER, _amount);

        address[] memory path = new address[](2);
        path = new address[](2);
        path[0] = _from;
        path[1] = _to;

        uint[] memory outputs = IUniswapV2Router(ROUTER).swapExactTokensForTokens(
            _amount,
            1,
            path,
            address(this),
            block.timestamp
        );
        uint256 outputsLenght = outputs.length-1;
        return outputs[outputsLenght];
    }
    
    function _addUniswapLiquidity(address _tokenA,
        address _tokenB,
        uint256 _amountA,
        uint256 _amountB) internal returns (uint256, uint256) {
        IERC20(_tokenA).approve(ROUTER, _amountA);
        IERC20(_tokenB).approve(ROUTER, _amountB);
        (uint amountA, uint amountB, uint liquidity) = IUniswapV2Router(ROUTER)
            .addLiquidity(
                _tokenA,
                _tokenB,
                _amountA,
                _amountB,
                1,
                1,
                msg.sender,
                block.timestamp
            );
        return (amountA, amountB);
    }

    function _addUniswapLiquidityFull(address _tokenA, address _tokenB) internal {
        uint balA = IERC20(_tokenA).balanceOf(address(this));
        uint balB = IERC20(_tokenB).balanceOf(address(this));
        IERC20(_tokenA).approve(ROUTER, balA);
        IERC20(_tokenB).approve(ROUTER, balB);

        IUniswapV2Router(ROUTER).addLiquidity(
            _tokenA,
            _tokenB,
            balA,
            balB,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    function removeUniswapLiquidity(address _tokenA, address _tokenB, uint256 _liquidity) internal returns (uint256, uint256) {
        address pair = IUniswapV2Factory(FACTORY).getPair(_tokenA, _tokenB);
        
        uint256 liquidity;
        if (_liquidity == 0) {
            liquidity = IERC20(pair).balanceOf(msg.sender);
        } else {
            liquidity = _liquidity;
        }
        IERC20(pair).transferFrom(msg.sender, address(this), liquidity);
        IERC20(pair).approve(ROUTER, liquidity);

        (uint amountA, uint amountB) = IUniswapV2Router(ROUTER).removeLiquidity(
            _tokenA,
            _tokenB,
            liquidity,
            1,
            1,
            address(this),
            block.timestamp
        );
        return (amountA, amountB);
    }

    // Get borrowing power of user in ETH (18 decimals), USD (6 decimals) and token A (in tokenA decimals)
    function getBorrowingPower(address _account, address _tokenA) public view returns (uint256, uint256, uint256) {
        (,,uint256 availableBorrowsETH,,,) = ILendingPool(LENDINGPOOL).getUserAccountData(_account);
        (, int256 currentEthprice, , , ) = AggregatorV3Interface(ETH_USD).latestRoundData();
        currentEthprice = currentEthprice / 10**2;
        uint256 availableBorrowsUSD = (((availableBorrowsETH / 10**12) * uint256(currentEthprice))/10**6);
        uint8 decimals = IERC20(_tokenA).decimals();
        uint256 amountToBorrow =  ((availableBorrowsUSD * 10**decimals) / getPriceFromOracle(_tokenA));
        return (availableBorrowsETH, availableBorrowsUSD, amountToBorrow);
    }
}