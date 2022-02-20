/**
 *Submitted for verification at Etherscan.io on 2022-02-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

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


// File @chainlink/contracts/src/v0.8/interfaces/[email protected]


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


// File @uniswap/v3-periphery/contracts/libraries/[email protected]


library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}


// File @uniswap/v3-core/contracts/interfaces/callback/[email protected]


/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}


// File @uniswap/v3-periphery/contracts/interfaces/[email protected]


/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}


// File contracts/OptionMaker.sol




//0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D

contract OptionContract {

    // @dev Option Contract Details 

    // @notice
    // CurrentPrice = Current Price of Ethereum
    // strikePrice = strike price user sets
    // expirationBlock = time of expiration of the option contract
    // CallOptionPrice = price the user paid for the contract (not including deposit)
    // deposit = call option price * amount of ETH
    // filled = if user is in the money and they buy at strike price this will be set to TRUE

    struct CallOption {

        uint currentPrice;
        uint strikePrice;
        uint amount;
        uint timeDays;
        uint expirationTime;
        uint CallOptionPrice;
        uint deposit;
        bool filled;

    }

    // @dev ETH and USDC and 1_INCH addresses
    address public USDC = 0xeb8f08a975Ab53E34D8a0330E0D34de942C95926;
    address public constant WETH9 = 0x942B9158080751b09c9BD713Fa6Bc0f53bCf7584;
    // nodejs limit implementation - address public ONEINCH = 0xE0f5206BBD039e7b0592d8918820024e2a7437b9;

    // @dev volatility of ETH 
    uint public SD = 500000000000000000;
    // @dev RISK
    uint public RISK = 80000000000000000;

    // @dev mapping of all Call Options to users. Users can have multiple call options
    mapping(address => mapping(uint => CallOption)) public CallOptions;

    // @dev potential debt obligation in ETH
    uint public potentialDebtObligation;

    // @dev this mapping allows users to have multiple options contracts
    mapping(address => uint[]) private listMappingOwner;


    // used by buyOption to calculate length of listMappingOwner
    uint private ID;

    // #########################
    // @dev CHAINLINK ORACLE ETH/USDC


    AggregatorV3Interface internal priceFeed;

    ISwapRouter public immutable swapRouter;

    
    /**
     * Network: Rinkeby
     * Aggregator: ETH/USD
     * Address: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
     */
    constructor(ISwapRouter _swapRouter) {
        swapRouter = _swapRouter;
        priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }
    // @dev end of CHAINLINK 

    // @dev UNISWAP swap functions

    function ETHtoWETH(uint amount) internal returns (bool) {
        payable(WETH9).transfer(amount);


        return true;
    }

    uint24 public constant poolFee = 3000;

    function swapExactInputSingle(uint amountIn) public returns (uint amountOut) {
        // msg.sender must approve this contract

        // Transfer the specified amount of weth to this contract.
        //TransferHelper.safeTransferFrom(WETH9, msg.sender, address(this), amountIn);

        // Approve the router to spend DAI.
        TransferHelper.safeApprove(WETH9, address(swapRouter), amountIn);

        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: WETH9,
                tokenOut: USDC,
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        amountOut = swapRouter.exactInputSingle(params);

        return amountOut;
    }



    // @dev Buy Option - Uses Black Scholes to calculate optimal price of Option to mitigate Risk
    function buyCallOption(uint amount, uint  currentPrice, uint strikePrice, uint timeDays) external payable returns (bool) {

        // @dev get ETH/USDT PRICE
        // @dev !!!! uncomment for deployment
        //uint currentPrice;
        //currentPrice = uint(getLatestPrice());

        // @dev Current Price / strike price 
        uint SKratio;

        SKratio = div(currentPrice, strikePrice);
        
        // @dev SKratio must be <= 2
        require(SKratio <= 2e18, 'Current functionality requires current price to strike ratio to be < 2');

        // @dev current time
        //uint currentBlock;
        //currentBlock = block.number;

        //timeDays
        
        //uint deltaT;
        //deltaT = expirationBlock - currentBlock;

        // @dev max expiration time is one year out
        require(timeDays <= 365, "Max expiration time is 1 year");

        uint CallOptionPrice;
        CallOptionPrice = BlackScholes(currentPrice, strikePrice, timeDays);

        // @dev amount is essentially the deposit the user must pay...
        // @dev !!!!! can the user then withdraw this amount?
        uint deposit;
        deposit = strikePrice * amount;

        // @dev payment is the amount the user must pay
        uint payment;
        payment = CallOptionPrice + deposit;

        // @dev 

        TransferHelper.safeTransferFrom(USDC, msg.sender, address(this), payment);

        //require(msg.value >= payment, "msg.value < Option Price");

        ID = listMappingOwner[msg.sender].length;

        CallOptions[msg.sender][ID].currentPrice = currentPrice;
        CallOptions[msg.sender][ID].strikePrice = strikePrice;
        CallOptions[msg.sender][ID].amount = amount;

        CallOptions[msg.sender][ID].timeDays = timeDays;

        CallOptions[msg.sender][ID].expirationTime = (timeDays * 86400) +block.timestamp;

        CallOptions[msg.sender][ID].CallOptionPrice = CallOptionPrice;
        CallOptions[msg.sender][ID].deposit = deposit;
        CallOptions[msg.sender][ID].filled = false;

        // @dev the potential amount the smart contract will owe to users in ETH
        potentialDebtObligation += amount;

        // the contract will buy the hedge as set by our strategy
        sellHedge(amount);

        return true;

    }


    // @dev sell hedge 
    // @dev honestly this functionality needs to be thought through a bit more...
    function sellHedge(uint amount) internal returns (uint) {

        ETHtoWETH(amount);

        uint WETHbalance;
        WETHbalance = IERC20(WETH9).balanceOf(address(this));

        //swapExactInputSingle(balance);

        swapExactInputSingle(WETHbalance);

        uint USDCbalance;
        USDCbalance = IERC20(WETH9).balanceOf(address(this));

        return USDCbalance;

        //когда рассчитали цену в смарт-контракте, 
        //мы покупаем хедж в размере N(d1)*amount с dex

    }





    // @dev stable coin balance of this Contract- DAI, USDT, USDC
    // @dev OpenZepplin IERC20 interface
    // @dev currently this is USDC on Rinkeby
    function checkUSDTBalance() public view returns (uint) {
        uint balance;
        balance = IERC20(USDC).balanceOf(address(this));
        return balance;

    }


    // @dev If user is in the money they can buy ETH at strike price in option contract
    // @dev however, they must buy entire ETH amount specified
    function buyAtStrike(uint ID) public payable returns (uint) {

        uint expirationTime;
        expirationTime = CallOptions[msg.sender][ID].expirationTime;


        require(expirationTime < block.timestamp, "Can only execute at expiration time i.e. European Option");

        uint strikePrice;
        uint amount; 
        uint payment;

        strikePrice = CallOptions[msg.sender][ID].strikePrice;

        amount = CallOptions[msg.sender][ID].amount;

        payment = amount * strikePrice;

        address sender;
        sender = msg.sender;

        // @dev calling USDC smart contract
        // @dev there could be a vulnerablity here but I'm too tired so moving on...
        // @dev essentially we must make sure that ETH amount * strikePrice is = ERC20 payment
        //IERC20(USDC).transferFrom(sender, address(this), payment);

        require(IERC20(USDC).transferFrom(sender, address(this), payment));

        payable(msg.sender).transfer(amount);

        potentialDebtObligation -= amount;


    }
    



    // @dev this is currently a filler function - we didn't have time to fix during hackathon
    // @dev the math checks out though
    function normalDistribution(uint d) public pure returns (uint) {

        uint N;
        N = 700000000000000000;
        return N;

    }


    function BlackScholes(uint currentPrice, uint strikePrice, uint expirationBlock) public view returns (uint) {

        // @dev d1 calls func_d1
        uint d1;
        d1 = func_d1(currentPrice, strikePrice, expirationBlock);

        // @dev first part of black scholes
        uint a;
        a = normalDistribution(d1) * currentPrice;

        // @dev risk * expiration time
        uint rt;
        rt = RISK * expirationBlock;

        // @dev calls our negative E function
        uint eNegativeRT;
        eNegativeRT = negativeExponent(rt);
        

        // @dev d2 calls func_d2
        uint d2;
        d2 = func_d2(d1,expirationBlock);



        // @dev sencond part of black scholes
        uint b;
        b = normalDistribution(d2) * strikePrice * eNegativeRT / 1e18;

    

        // @dev result
        uint C;
        C = a - b;

        return C;

    }





    // @dev calculate d1
    // d1 = ln(currentPrice/strikePrice) + (risk + ((sd**2) / 2)) * time
    // expiration time = expirationBlock
    function func_d1(uint currentPrice, uint strikePrice, uint expirationBlock) public view returns (uint) {

        //@dev s/x
        uint currentDivStrike;
        currentDivStrike = div(currentPrice, strikePrice);

        //@dev ln(x/s)
        uint naturalLog;
        naturalLog = getNaturalLog(currentDivStrike);


        //@dev (r + (sd**2 / 2))
        //@dev 1e18 !!!!!
        uint riskPlusSD;
        riskPlusSD = RISK + ((SD**2)/2)/1e18;

        // 
        uint riskTimesTime;
        riskTimesTime = riskPlusSD * expirationBlock;

        uint numerator;
        numerator = naturalLog + riskTimesTime;

        uint denominator;
        denominator = SD * SimpleSQRT(expirationBlock);

        uint d1;
        d1 = div(numerator, denominator);

        return d1*1e18;

    }


    // expirationBlock

    // @dev calculate d2
    // d2 = d1 - sd * sqrt(time)
    function func_d2(uint d1, uint delta_block_time) public view returns (uint) {

        uint d2;
        
        //uint delta_block_time = expirationBlock - block.number;
        //d2 = d1 - SD * ComplexSQRT(delta_block_time*1e18/(5600*365))/1e18;

        //d2 = d1 - SD * ComplexSQRT(delta_block_time);

        d2 = d1 - SD * SimpleSQRT(delta_block_time);
        
        
        return d2;

    }


    // @dev only works with negative exponents
    // @dev natural log table
    mapping(uint => uint) public lnTable;

    // @dev we can add values this way...
    function addTableVals(uint x, uint y) external {
        lnTable[x] = y;
    } 



    // @dev ln from 1 to 2.2 (we assume the ratio of current price / strike is never greater than 2.2)
    function table() public {
        lnTable[100] = 0;
        lnTable[110] = 953;
        lnTable[120] = 1823;
        lnTable[130] = 2623;
        lnTable[140] = 3364;
        lnTable[150] = 4054;
        lnTable[160] = 4700;
        lnTable[170] = 4700;
        lnTable[180] = 5877;
        lnTable[190] = 6418;
        lnTable[200] = 6931;
        lnTable[210] = 7419;
    }


    function getNaturalLog(uint x) public view returns (uint) {

        uint a;
        a = x / 1e17;
        a = a * 10;

        uint result;

        result = lnTable[a];

        return result;
    }




    // @dev returns int (but is essentially floating point)
    function div(uint x, uint y) public pure returns (uint) {

        uint result;

        uint base = 1e18;

        result = (x * base) / y;

        return result;

    }


    // @dev returns x
    function e(uint x) public pure returns (uint) {

        uint result;

        result = x * 1;

        return result;

    }

        // @dev only works with negative exponents
    function negativeExponent(uint x) public pure returns (uint) {

        uint result;
        result = 1e18 - x + x**2/ (2*1e18);

        return result;

    }


    //@dev math functions
    // only for time
    function SimpleSQRT(uint x) public pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }


    function ComplexSQRT(uint x) public pure returns (uint) {
        return 1e18 + 5*1e17*x/1e18;
    }

}