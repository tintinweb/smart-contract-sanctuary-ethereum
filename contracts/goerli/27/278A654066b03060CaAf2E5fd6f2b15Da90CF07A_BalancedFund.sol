/**
 *Submitted for verification at Etherscan.io on 2023-02-25
*/

/** 
 *  SourceUnit: /Users/kuldeep/ETHEREUM/interviews/Xalts/truffle/contracts/BalancedFund.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the decimal value.
     */
    function decimals() external view returns (uint256);

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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




/** 
 *  SourceUnit: /Users/kuldeep/ETHEREUM/interviews/Xalts/truffle/contracts/BalancedFund.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: UNLICENSED
pragma solidity 0.8.19;
////import "./IERC20.sol";

interface IBalancedFund {
    // address public constant UNISWAP_V2_FACTORY =
    //     address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    // address public constant UNISWAP_V2_ROUTER =
    //     address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    // address public constant USDC_TOKEN = address(0x1);
    // // address public constant WETH = address();
    // IERC20 public USDCToken = IERC20(USDC_TOKEN);
    // uint256 public constant INITIAL_USDC_DEPOSIT = 1000;
    // address[] public tokens;
    // uint256 public numberOfTokens;
    // // for any address, at index 0 - uniV2 pair
    // mapping(address => address[]) public tokenPairs;
    // uint256 public totalUSDCbalanced;
}




/** 
 *  SourceUnit: /Users/kuldeep/ETHEREUM/interviews/Xalts/truffle/contracts/BalancedFund.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: UNLICENSED
pragma solidity >=0.6.2;

interface IUniswapV2Router {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}




/** 
 *  SourceUnit: /Users/kuldeep/ETHEREUM/interviews/Xalts/truffle/contracts/BalancedFund.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: UNLICENSED
pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

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

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}




/** 
 *  SourceUnit: /Users/kuldeep/ETHEREUM/interviews/Xalts/truffle/contracts/BalancedFund.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: UNLICENSED
pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}


/** 
 *  SourceUnit: /Users/kuldeep/ETHEREUM/interviews/Xalts/truffle/contracts/BalancedFund.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: UNLICENSED
pragma solidity 0.8.19;

////import "./interfaces/IUniswapV2Factory.sol";
////import "./interfaces/IUniswapV2Pair.sol";
////import "./interfaces/IUniswapV2Router.sol";
////import "./interfaces/IBalancedFund.sol";

contract BalancedFund is IBalancedFund {
    address public constant UNISWAP_V2_FACTORY =
        address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    address public constant UNISWAP_V2_ROUTER =
        address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IERC20 public USDCToken;
    uint256 public constant INITIAL_USDC_DEPOSIT = 1000;

    address[] public tokens;
    uint256 public numberOfTokens;
    // for any address, at index 0 - uniV2 pair
    mapping(address => address[]) public tokenPairs;

    uint256 public totalUSDCbalanced;

    constructor(address usdcToken, address[] memory _tokens) {
        require(
            _tokens.length >= 3 && _tokens.length <= 10,
            "Invalid number of tokens"
        );
        USDCToken = IERC20(usdcToken);
        tokens = _tokens;
        numberOfTokens = _tokens.length;
    }

    function init() public {
        require(totalUSDCbalanced == 0, "Initialised!");
        require(
            USDCToken.transferFrom(
                msg.sender,
                address(this),
                INITIAL_USDC_DEPOSIT * (10**USDCToken.decimals())
            ),
            "Init: tokens transfer failed"
        );

        // adding uniswap v2 pair pool address for all tokens
        for (uint256 i = 0; i < numberOfTokens; i++) {
            // no token same as USDC
            IUniswapV2Factory factory = IUniswapV2Factory(UNISWAP_V2_FACTORY);
            address pair = factory.getPair(tokens[i], (address(USDCToken)));
            tokenPairs[tokens[i]].push(pair);
        }

        _rebalance();
    }

    // reentrancy check
    function rebalance() public {
        _rebalance();
    }

    // reentrancy check
    function _rebalance() internal {
        if (totalUSDCbalanced == 0) {
            totalUSDCbalanced = (INITIAL_USDC_DEPOSIT *
                (10**USDCToken.decimals()));
            uint256 tokenSharesInUSDC = (INITIAL_USDC_DEPOSIT *
                (10**USDCToken.decimals())) / numberOfTokens;
            // swap tokenShareInUSDC to respective tokens
            for (uint256 i = 0; i < numberOfTokens; i++) {
                _swapUSDCToTokens(tokenSharesInUSDC, tokens[i]);
            }
        } else {
            uint256 depositedUSDC = USDCToken.balanceOf(address(this));
            if (depositedUSDC == 0) {
                return;
            }
            totalUSDCbalanced += depositedUSDC;

            uint256[] memory currentUSDCValueOfTokens = new uint256[](
                numberOfTokens
            );
            uint256 currentTotalUSDCValueOfTokens;

            // total USDC value of all tokens
            for (uint256 i = 0; i < numberOfTokens; i++) {
                uint256 amountOutMin = _getAmountOut(
                    tokens[i] == IUniswapV2Router(UNISWAP_V2_ROUTER).WETH()
                        ? address(this).balance
                        : IERC20(tokens[i]).balanceOf(address(this)),
                    tokens[i]
                );
                currentUSDCValueOfTokens[i] = amountOutMin;
                currentTotalUSDCValueOfTokens += amountOutMin;
            }

            uint256 newTokensShareInUSDC = (currentTotalUSDCValueOfTokens +
                depositedUSDC) / numberOfTokens;

            // swap partial tokens to USDC if tokens' current USDC value > newTokensShareInUSDC
            for (uint256 i = 0; i < numberOfTokens; i++) {
                int256 diffInAmount = int256(currentUSDCValueOfTokens[i]) -
                    int256(newTokensShareInUSDC);
                if (diffInAmount > 0) {
                    // swap tokens for USDC
                    // check for WETH & Other tokens
                    _swapTokensToUSDC(uint256(diffInAmount), tokens[i]);
                }
            }

            // swap USDC to tokens to rebalance
            for (uint256 i = 0; i < numberOfTokens; i++) {
                int256 diffInAmount = int256(newTokensShareInUSDC) -
                    int256(currentUSDCValueOfTokens[i]);
                if (diffInAmount > 0) {
                    // swap USDC for tokens
                    // check for WETH & Other tokens
                    _swapUSDCToTokens(uint256(diffInAmount), tokens[i]);
                }
            }
        }
    }

    function _getAmountOut(uint256 amountIn, address token)
        internal
        view
        returns (uint256)
    {
        (address token0, ) = token > address(USDCToken)
            ? (token, address(USDCToken))
            : (address(USDCToken), token);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(
            tokenPairs[token][0]
        ).getReserves();
        (uint256 reserveIn, uint256 reserveOut) = token == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
        uint256 amountOutMin = IUniswapV2Router(UNISWAP_V2_ROUTER).getAmountOut(
            amountIn,
            reserveIn,
            reserveOut
        );
        return amountOutMin;
    }

    function _swapUSDCToTokens(uint256 amountIn, address token) internal {
        uint256 amountOutMin = _getAmountOut(amountIn, token);
        address[] memory path = new address[](2);
        path[0] = address(USDCToken);
        path[1] = token;
        USDCToken.approve(address(UNISWAP_V2_ROUTER), amountIn);
        if (token == IUniswapV2Router(UNISWAP_V2_ROUTER).WETH()) {
            IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForETH(
                amountIn,
                amountOutMin,
                path,
                address(this),
                block.timestamp
            );
        } else {
            IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForTokens(
                amountIn,
                amountOutMin,
                path,
                address(this),
                block.timestamp
            );
        }
    }

    function _getAmountIn(uint256 amountOut, address token)
        internal
        view
        returns (uint256)
    {
        (address token0, ) = token > address(USDCToken)
            ? (token, address(USDCToken))
            : (address(USDCToken), token);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(
            tokenPairs[token][0]
        ).getReserves();
        (uint256 reserveIn, uint256 reserveOut) = token == token0
            ? (reserve1, reserve0)
            : (reserve0, reserve1);

        uint256 amountInMin = IUniswapV2Router(UNISWAP_V2_ROUTER).getAmountIn(
            (amountOut),
            reserveIn,
            reserveOut
        );
        return amountInMin;
    }

    function _swapTokensToUSDC(uint256 amountOut, address token) internal {
        uint256 amountInMin = _getAmountIn(amountOut, token);
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = address(USDCToken);
        if (token == IUniswapV2Router(UNISWAP_V2_ROUTER).WETH()) {
            // unwrap WETH to ETH
            IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactETHForTokens{
                value: amountInMin
            }(amountOut, path, address(this), block.timestamp);
        } else {
            IERC20(token).approve(address(UNISWAP_V2_ROUTER), amountInMin);
            IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForTokens(
                amountInMin,
                amountOut,
                path,
                address(this),
                block.timestamp
            );
        }
    }

    receive() external payable {}
}