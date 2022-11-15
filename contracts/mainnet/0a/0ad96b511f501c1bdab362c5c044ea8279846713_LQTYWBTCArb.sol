/**
 *Submitted for verification at Etherscan.io on 2022-11-15
*/

// based on https://etherscan.io/address/0xf9a0e641c98f964b1c732661fab9d5b96af28d49#code
pragma solidity ^0.8.14;

interface IUniswapReserve {
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
}

//import "forge-std/console.sol"; // TODO

interface ICurvePool {
    function get_dy(uint i, uint j, uint dx) external view returns(uint);
    function get_dy_underlying(int128 i, int128 j, uint dx) external view returns(uint);
    function exchange(uint i, uint j, uint dx, uint minDy, bool useEth) external payable;
    function exchange_underlying(int128 i, int128 j, uint dx, uint minDy) external returns(uint);
}

interface IGemSeller {
    function getSwapGemAmount(uint lusdQty) external view returns(uint gemAmount, uint feeLusdAmount);
    function swap(uint lusdAmount, uint minGemReturn, address payable dest) external returns(uint);
    function fetchGem2EthPrice() external view returns(uint);
    function fetchEthPrice() external view returns(uint);
    function gemToUSD(uint gemQty, uint gem2EthPrice, uint eth2UsdPrice) external pure returns(uint);
    function USDToGem(uint lusdQty, uint gem2EthPrice, uint eth2UsdPrice) external pure returns(uint);
    function getReturn(uint xQty, uint xBalance, uint yBalance, uint A) external pure returns(uint);
    function compensateForLusdDeviation(uint gemAmount) external view returns(uint newGemAmount);
}

interface ERC20Like {
    function approve(address spender, uint value) external returns(bool);
    function transfer(address to, uint value) external returns(bool);
    function balanceOf(address a) external view returns(uint);
}

interface IUSDT {
    function approve(address spender, uint amount) external;
}

contract LQTYWBTCArb {
    address constant LQTY = 0x6DEA81C8171D0bA574754EF6F8b412F2Ed88c54D;
    address constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant LUSD = 0x5f98805A4E8be255a32880FDeC7F6728C6568bA0;

    IGemSeller immutable gemSeller;

    IUniswapReserve constant WBTCLQTY = IUniswapReserve(0xeFd784093dDD12e24231Fa6B792c09d03A4F7B7E);
    uint160 constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;
    uint160 constant MIN_SQRT_RATIO = 4295128739;

    ICurvePool constant threeCrypto = ICurvePool(0xD51a44d3FaE010294C616388b506AcdA1bfAAE46);
    ICurvePool constant lusdCrv = ICurvePool(0xEd279fDD11cA84bEef15AF5D39BB4d4bEE23F0cA);

    constructor(address _gemSellerAddress) {
        gemSeller = IGemSeller(_gemSellerAddress);
        ERC20Like(WBTC).approve(address(threeCrypto), type(uint256).max);
        IUSDT(USDT).approve(address(lusdCrv), type(uint256).max);
        ERC20Like(LUSD).approve(address(gemSeller), type(uint256).max);
    }

    function getSwapAmount(uint wbtcAmount) public view returns(uint lqtyAmount) {
        // wbtc => usdt => lusd => lqty
        uint usdtAmount = threeCrypto.get_dy(1, 0, wbtcAmount);
        uint lusdAmount = lusdCrv.get_dy_underlying(3, 0, usdtAmount);
        (lqtyAmount,) = gemSeller.getSwapGemAmount(lusdAmount);
    }

    function swap(uint lqtyQty, address lqtyDest, uint minLqtyProfit) external payable returns(uint) {
        WBTCLQTY.swap(address(this), false, int256(lqtyQty), MAX_SQRT_RATIO - 1, new bytes(0));

        uint retVal = ERC20Like(LQTY).balanceOf(address(this));
        require(retVal >= minLqtyProfit, "insufficient arb profit");
        ERC20Like(LQTY).transfer(lqtyDest, retVal);

        return retVal;
     }

    function _uniswapWBTCLQTYCallback(
        int256 /* amount0Delta */,
        int256 amount1Delta,
        bytes calldata /* data */
    ) internal {
        // swap WBTC to LQTY
        //uint wbtcAmount = uint(-1 * amount1Delta);
        uint totalWbtcBal = ERC20Like(WBTC).balanceOf(address(this));

        // wbtc => usdt => lusd => lqty
        threeCrypto.exchange(1, 0, totalWbtcBal, 1, false);
        uint usdtBalance = ERC20Like(USDT).balanceOf(address(this));
        uint lusdBalance = lusdCrv.exchange_underlying(3, 0, usdtBalance, 1);

        require(gemSeller.swap(lusdBalance, 1, payable(this)) > 0, "Nothing swapped in GemSeller");

        if(amount1Delta > 0) {
            ERC20Like(LQTY).transfer(msg.sender, uint(amount1Delta));
        }
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external {
        if (msg.sender == address(WBTCLQTY)) {
            _uniswapWBTCLQTYCallback(amount0Delta, amount1Delta, data);
        } else {
            revert("uniswapV3SwapCallback: invalid sender");
        }
    }

    receive() external payable {}
}