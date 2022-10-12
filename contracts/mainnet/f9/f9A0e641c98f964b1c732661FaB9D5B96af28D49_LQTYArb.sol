/**
 *Submitted for verification at Etherscan.io on 2022-10-11
*/

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;


interface UniswapReserve {
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
}

interface ERC20Like {
    function approve(address spender, uint value) external returns(bool);
    function transfer(address to, uint value) external returns(bool);
    function balanceOf(address a) external view returns(uint);
}

interface WethLike is ERC20Like {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

interface ReserveLike {
    function trade(
        address srcToken,
        uint256 srcAmount,
        address destToken,
        address payable destAddress,
        uint256 conversionRate,
        bool validate
    ) external payable returns (bool);
}


contract LQTYArb {
    address constant LQTY = 0x6DEA81C8171D0bA574754EF6F8b412F2Ed88c54D;    
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    UniswapReserve constant LQTYETH = UniswapReserve(0xD1D5A4c0eA98971894772Dcd6D2f1dc71083C44E);
    uint160 constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;
    uint160 constant MIN_SQRT_RATIO = 4295128739;    

    constructor() public {
    }

    function swap(uint lqtyQty, address reserve, address lqtyDest, uint minLqtyProfit) external payable returns(uint) {
        bytes memory data = abi.encode(reserve);
        LQTYETH.swap(address(this), true, int256(lqtyQty), MIN_SQRT_RATIO + 1, data);

        uint retVal = ERC20Like(LQTY).balanceOf(address(this));
        require(retVal >= minLqtyProfit, "insufficient arb profit");
        ERC20Like(LQTY).transfer(lqtyDest, retVal);

        return retVal;
     }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external {
        require(msg.sender == address(LQTYETH), "uniswapV3SwapCallback: invalid sender");
        // swap ETH to LQTY
        uint ethAmount = uint(-1 * amount1Delta);
        WethLike(WETH).withdraw(ethAmount);
        uint totalEthBal = address(this).balance;

        ReserveLike reserve = abi.decode(data, (ReserveLike));
        reserve.trade{value: totalEthBal}(
            0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
            totalEthBal,
            LQTY,
            address(this),
            1,
            false
        );

        if(amount0Delta > 0) {
            ERC20Like(LQTY).transfer(msg.sender, uint(amount0Delta));
        }
    }

    receive() external payable {}
}