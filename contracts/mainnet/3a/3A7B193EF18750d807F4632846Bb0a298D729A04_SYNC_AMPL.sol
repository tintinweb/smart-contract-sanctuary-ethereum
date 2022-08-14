//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IWAMPL.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV3Pool.sol";
import "./interfaces/ISwapRouter.sol";

contract SYNC_AMPL {
    IERC20 public ampl = IERC20(0xD46bA6D942050d489DBd938a2C909A5d5039A161);
    IWETH9 public weth = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IWAMPL public wampl = IWAMPL(0xEDB171C18cE90B633DB442f2A6F72874093b49Ef);
    IUniswapV2Pair public pair = IUniswapV2Pair(0xc5be99A02C6857f9Eac67BbCE58DF5572498F40c);
    // IUniswapV3Pool public pool = IUniswapV3Pool(0x1EeC74d40f6E53F888A5d89ff6Ae2cE0b683Be01);
    ISwapRouter public router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    // uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    // uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    address public owner;

    constructor() {
        owner = msg.sender;
        ampl.approve(address(wampl), type(uint256).max);
        IERC20(address(wampl)).approve(address(router), type(uint256).max);
        IERC20(address(weth)).approve(address(router), type(uint256).max);
    }

    /* =================== VIEW FUNCTIONS =================== */

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    /* ================ TRANSACTION FUNCTIONS ================ */

    function buyAmplSellWampl(uint256 ethAmountIn) public {
        IERC20(address(weth)).transfer(address(pair), ethAmountIn);

        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        pair.swap(0, getAmountOut(ethAmountIn, reserve0, reserve1), address(this), "");

        uint256 wamplAmountIn = wampl.deposit(ampl.balanceOf(address(this)));

        uint256 ethAmountOut = router.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: address(wampl),
                tokenOut: address(weth),
                fee: 3000,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: wamplAmountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            })
        );

        // bool zeroForOne = address(wampl) < address(weth);
        // pool.swap(
        //     address(this),
        //     zeroForOne,
        //     int256(wamplBalance),
        //     zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1,
        //     ""
        // );

        require(ethAmountOut > ethAmountIn, "not earn");
    }

    function buyWamplSellAmpl(uint256 ethAmountIn) public {
        router.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: address(weth),
                tokenOut: address(wampl),
                fee: 3000,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: ethAmountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            })
        );

        // bool zeroForOne = address(weth) < address(wampl);
        // pool.swap(
        //     address(this),
        //     zeroForOne,
        //     int256(msg.value),
        //     zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1,
        //     ""
        // );

        uint256 amplAmountIn = wampl.burnAllTo(address(pair));

        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        uint256 ethAmountOut = getAmountOut(amplAmountIn, reserve1, reserve0);
        pair.swap(ethAmountOut, 0, address(this), "");

        require(ethAmountOut > ethAmountIn, "not earn");
    }

    // function uniswapV3SwapCallback(
    //     int256 amount0Delta,
    //     int256 amount1Delta,
    //     bytes calldata _data
    // ) external {}

    receive() external payable {
        if (msg.sender != address(weth)) {
            uint256 value = msg.value;
            if (value > 0.004 ether && value < 0.0041 ether) {
                buyAmplSellWampl((value - 0.004 ether) * 10**5);
            } else if (value > 0.0041 ether && value < 0.0042 ether) {
                buyWamplSellAmpl((value - 0.0041 ether) * 10**5);
            }
            payable(owner).transfer(msg.value);
        }
    }

    function depositWEth() external payable {
        weth.deposit{value: msg.value}();
    }

    function withdrawWEth(uint256 amount) external {
        weth.withdraw(amount);
        payable(owner).transfer(amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

interface IWAMPL {
    function deposit(uint256 amples) external returns (uint256);

    function depositFor(address to, uint256 amples) external returns (uint256);

    function burnAll() external returns (uint256);

    function burnAllTo(address to) external returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

interface IWETH9 {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

interface IUniswapV2Pair {
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

interface IUniswapV3Pool {
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

interface ISwapRouter {
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

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

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

    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);
}