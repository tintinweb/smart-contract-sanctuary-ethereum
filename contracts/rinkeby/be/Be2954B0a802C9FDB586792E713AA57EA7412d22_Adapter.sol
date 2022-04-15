// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./interfaces/IToken.sol";

/**
@title An adapter contract for Uniswap protocol
@author Said Avkhadeyev
@dev For implementation info refer to Uniswap docs
*/
contract Adapter is ReentrancyGuard {
    address public factory;
    address public router;

    /**
    Emitted when a new liquidity pair is created
    @param tokenA First token of the created pair
    @param tokenB Second token of the created pair
    @param pair The pair contract address
    */
    event PairCreated(address tokenA, address tokenB, address indexed pair);

    /**
    Emitted when liquidity is provided to the pool
    @param to LP tokens recipient address
    @param amountA First token amount
    @param amountB Second token amount
    @param amountLiquidity Provided liquidity amount
    */
    event LiquidityProvided(
        address indexed to,
        uint256 amountA,
        uint256 amountB,
        uint256 indexed amountLiquidity
    );

    /**
    Emitted when liquidity is removed from the pool
    @param to Asset tokens recipient address
    @param amountA First token amount
    @param amountB Second token amount
    @param amountLiquidity Removed liquidity amount
    */
    event LiquidityRemoved(
        address indexed to,
        uint256 amountA,
        uint256 amountB,
        uint256 indexed amountLiquidity
    );

    /**
    Emitted when tokens swapped
    @param to Swapped tokens recipient address
    @param addressArray Array of tokens used in swap
    @param amountsArray Amounts of tokens used in swap
    */
    event Swapped(
        address indexed to,
        address[] addressArray,
        uint256[] amountsArray
    );

    /**
    Constructor
    @param _factory Uniswap factory address
    @param _router Uniswap router address
    */
    constructor(address _factory, address _router) {
        factory = _factory;
        router = _router;
    }

    /**
    Creates a new pair of tokens if it doesn't exist
    @param tokenA First token address
    @param tokenB Second token address
    @return pair Created pair address
    */
    function createPair(address tokenA, address tokenB)
        public
        returns (address pair)
    {
        pair = IUniswapV2Factory(factory).createPair(tokenA, tokenB);
        emit PairCreated(tokenA, tokenB, pair);
    }

    /**
    Provides liquidity to the pool
    @param tokenA First token address
    @param tokenB Second token address
    @param amountADesired Desired amount of first token
    @param amountBDesired Desired amount of second token
    @param amountAMin The extent to which the B/A price can go up
    @param amountBMin The extent to which the A/B price can go up
    @param to Recipient of the liquidity tokens
    @param deadline Unix timestamp after which the transaction will revert
    @return amountA Amount of first token
    @return amountB Amount of second token
    @return liquidity Amount of liquidity tokens minted
    */
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        public
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        IToken(tokenA).transferFrom(msg.sender, address(this), amountADesired);
        IToken(tokenB).transferFrom(msg.sender, address(this), amountBDesired);

        IToken(tokenA).approve(router, amountADesired);
        IToken(tokenB).approve(router, amountBDesired);

        (amountA, amountB, liquidity) = IUniswapV2Router02(router).addLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin,
            to,
            deadline
        );

        emit LiquidityProvided(to, amountA, amountB, liquidity);
    }

    /**
    Removes liquidity from the pool
    @param tokenA First token address
    @param tokenB Second token address
    @param liquidity The amount of liquidity tokens to remove
    @param amountAMin The minimum amount of tokenA that must be received
    @param amountBMin The minimum amount of tokenB that must be received
    @param to Recipient of the tokens
    @param deadline Unix timestamp after which the transaction will revert
    @return amountA Amount of first token
    @return amountB Amount of second token
    */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) public returns (uint256 amountA, uint256 amountB) {
        address pair = IUniswapV2Factory(factory).getPair(tokenA, tokenB);
        IToken(pair).transferFrom(msg.sender, address(this), liquidity);
        IToken(pair).approve(address(router), liquidity);

        IUniswapV2Router02(router).removeLiquidity(
            tokenA,
            tokenB,
            liquidity,
            amountAMin,
            amountBMin,
            to,
            deadline
        );

        emit LiquidityRemoved(to, amountA, amountB, liquidity);
    }

    /**
    Swaps an exact amount of input tokens for as many output tokens as possible
    @param amountIn The amount of input tokens to send
    @param amountOutMin The minimum amount of output tokens that must be received
    @param path An array of token addresses
    @param to Recipient of the output tokens
    @param deadline Unix timestamp after which the transaction will revert
    @return amounts The amounts of swapped tokens
    */
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) public returns (uint256[] memory amounts) {
        IToken(path[0]).transferFrom(msg.sender, address(this), amountIn);
        IToken(path[0]).approve(router, amountIn);

        IUniswapV2Router02(router).swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            to,
            deadline
        );

        emit Swapped(to, path, amounts);
    }

    /**
    Receive an exact amount of output tokens for as few input tokens as possible
    @param amountOut The amount of output tokens to receive
    @param amountInMax The maximum amount of input tokens that can be required
    @param path An array of token addresses
    @param to Recipient of the output tokens
    @param deadline Unix timestamp after which the transaction will revert
    @return amounts The amounts of swapped tokens
    */
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) public returns (uint256[] memory amounts) {
        IToken(path[0]).transferFrom(msg.sender, address(this), amountInMax);
        IToken(path[0]).approve(router, amountInMax);

        amounts = IUniswapV2Router02(router).swapTokensForExactTokens(
            amountOut,
            amountInMax,
            path,
            to,
            deadline
        );
        IToken(path[0]).transfer(msg.sender, amountInMax - amounts[0]);

        emit Swapped(to, path, amounts);
    }

    /**
    Calculates all subsequent maximum output token amounts
    @param amountIn The amount of input tokens to send
    @param path An array of token addresses
    @return amounts The output amounts of the other assets
    */
    function getAmountsOut(uint256 amountIn, address[] memory path)
        public
        view
        returns (uint256[] memory amounts)
    {
        amounts = IUniswapV2Router02(router).getAmountsOut(amountIn, path);
    }

    /**
    Calculates all preceding minimum input token amounts
    @param amountOut The amount of output tokens to receive
    @param path An array of token addresses
    @return amounts The minimum input asset amounts required
    */
    function getAmountsIn(uint256 amountOut, address[] memory path)
        public
        view
        returns (uint256[] memory amounts)
    {
        amounts = IUniswapV2Router02(router).getAmountsIn(amountOut, path);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

pragma solidity >=0.5.0;

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

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;

interface IToken {
    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function approve(address to, uint256 amount) external;

    function mint(address to, uint256 amount) external;

    function burn(address owner, uint256 amount) external;

    function balanceOf(address owner) external returns (uint256);
}

pragma solidity >=0.6.2;

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