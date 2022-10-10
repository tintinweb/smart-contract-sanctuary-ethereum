/**
 *Submitted for verification at Etherscan.io on 2022-10-09
*/

pragma solidity ^0.8.7;

/* Interface for ERC20 Tokens */
abstract contract Token {
    function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool success);
    function approve(address _spender, uint256 _value) public virtual returns (bool success);
}

abstract contract pToken {
    function redeem(uint256 _value, string memory destinationAddress, bytes4 destinationChainId) public virtual returns (bool _success);
}

interface Curve {
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy, address receiver) external returns (uint256);
}

interface WETH {
    function deposit() external payable;
    function withdraw(uint256 amount) external;    
    function approve(address guy, uint256 wad) external;
}

interface UniswapRouter {
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

    function exactInputSingle(ExactInputSingleParams calldata params) external returns (uint256 amountOut);
}


contract BTCETHSwap {

    fallback() external {
        revert();
    }

    // ARB
    address public PBTC_ADDRESS = address(0x62199B909FB8B8cf870f97BEf2cE6783493c4908); 
    address public WBTC_ADDRESS = address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599); 
    address public WETH_ADDRESS = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public CURVE_PBTC_POOL  = address(0xC9467E453620f16b57a34a770C6bceBECe002587);
    address public UNISWAP_ROUTER   = address(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);

    int128 public CURVE_WBTC_INDEX = 2;
    int128 public CURVE_PBTC_INDEX = 0;
    
    bytes4 public PTOKENS_BTC_CHAINID = 0x01ec97de;


    // Constructor function, initializes the contract and sets the core variables
    constructor() {}

    // Swap PBTC for ETH
    function swapBTCforETH (uint256 amount, address payable recipient) public
    {
        Token(PBTC_ADDRESS).transferFrom(msg.sender, address(this), amount);

        // Curve pBTC for wBTC
        uint256 amount_wbtc = CurveSwap(
            false,
            amount
        );

        // Uniswap wBTC for ETH
        uint256 amountETH = Uniswap(
            WBTC_ADDRESS,
            WETH_ADDRESS,
            amount_wbtc,
            recipient,
            3000
        );

        WETH(WETH_ADDRESS).withdraw(amountETH);
    }

    // Swap ETH for PBTC
    function swapETHforBTC (string memory recipient) public payable {
        WETH(WETH_ADDRESS).deposit{value: msg.value};
        WETH(WETH_ADDRESS).approve(UNISWAP_ROUTER, msg.value);

        // Uniswap ETH for WBTC
        // uint256 amount_WBTC = Uniswap(
        //     WETH_ADDRESS,
        //     WBTC_ADDRESS,
        //     msg.value,
        //     address(this),
        //     500
        // );

        // Token(WBTC_ADDRESS).approve(CURVE_PBTC_POOL, amount_WBTC);

        // // Curve wBTC to pBTC
        // uint256 amount_pbtc = CurveSwap(
        //     true,
        //     amount_WBTC
        // );

        // // Redeem pBTC to recipient address
        // pToken(PBTC_ADDRESS).redeem(
        //     amount_pbtc, 
        //     recipient,
        //     PTOKENS_BTC_CHAINID
        // );
    }



    // Uniswap         
    function Uniswap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        address recipient,
        uint24 fee) internal returns (uint256)
    {

        UniswapRouter.ExactInputSingleParams memory params = UniswapRouter.ExactInputSingleParams(
            tokenIn,
            tokenOut,
            fee,
            recipient,
            block.timestamp,
            amountIn,
            0,
            0
        );

        uint256 amountOut = UniswapRouter(UNISWAP_ROUTER).exactInputSingle(params);
        return amountOut;
    }

    // Curve
    function CurveSwap(bool wtop, uint256 amountSell) internal returns (uint256)
    {
        int128 i;
        int128 j;

        if (wtop)
        {
            i = CURVE_WBTC_INDEX;
            j = CURVE_PBTC_INDEX;
        }
        else
        {
            i = CURVE_PBTC_INDEX;
            j = CURVE_WBTC_INDEX;
        }
        
        Curve(CURVE_PBTC_POOL).exchange_underlying(i, j, amountSell, 0, address(this));
    }    
}