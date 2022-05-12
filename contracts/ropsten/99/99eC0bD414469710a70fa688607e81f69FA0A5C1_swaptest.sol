// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

/**
 * @dev by Pridevel
 */
contract swaptest {
    IUniswapV2Factory public immutable uniswapV2Factory;
    IUniswapV2Router02 public immutable uniswapV2Router;
    address WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;

    constructor() {
        // uniswap router address
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Factory = IUniswapV2Factory(_uniswapV2Router.factory());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
    }

    event liquidityadded(
        address user,
        address token1,
        address address2,
        uint256 tokenAamount,
        uint256 tokenBamount
    );
    event liquidityremove(address user, address pairAddress, uint256 lptoken);
    event liquidityaddedETH(
        address user,
        address token,
        uint256 amountToken,
        uint256 amountETH
    );
    event liquidityremoveETH(
        address user,
        address pairAddress,
        uint256 lptoken
    );

    function addLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _amountA,
        uint256 _amountB
    ) public {
        require(_amountA > 0, "Less TokenA Supply");
        require(_amountB > 0, "Less TokenB Supply");
        require(_tokenA != address(0), "DeAd address not allowed");
        require(_tokenB != address(0), "DeAd address not allowed");
        require(_tokenA != _tokenB, "Same Token not allowed");
        IERC20 token = IERC20(_tokenA);
        IERC20 token2 = IERC20(_tokenB);
        require(CheckAllowance(token) >= _amountA, "Less Supply");
        require(CheckAllowance(token2) >= _amountB, "Less Supply");
        token.transferFrom(msg.sender, address(this), _amountA);
        token2.transferFrom(msg.sender, address(this), _amountB);
        // tokens are approving router
        token.approve(address(uniswapV2Router), _amountA);
        token2.approve(address(uniswapV2Router), _amountB);
        uniswapV2Router.addLiquidity(
            _tokenA,
            _tokenB,
            _amountA,
            _amountB,
            0,
            0,
            msg.sender,
            block.timestamp
        );
        emit liquidityadded(msg.sender, _tokenA, _tokenB, _amountA, _amountB);
    }

    function addLiquidityETH(address _token, uint256 _amountToken)
        public
        payable
    {
        require(_amountToken > 0, "Less TokenA Supply");
        IERC20 token = IERC20(_token);
        require(CheckAllowance(token) >= _amountToken, "Less Supply");
        token.transferFrom(msg.sender, address(this), _amountToken);
        token.approve(address(uniswapV2Router), _amountToken);

        uniswapV2Router.addLiquidityETH{value: msg.value}(
            _token,
            _amountToken,
            0,
            0,
            msg.sender,
            block.timestamp
        );
        emit liquidityaddedETH(msg.sender, _token, _amountToken, msg.value);
    }

    function CheckAllowance(IERC20 _Token) internal view returns (uint256) {
        return IERC20(_Token).allowance(msg.sender, address(this));
    }

    function pairAddress(address _tokenA, address _tokenB)
        public
        view
        returns (IERC20)
    {
        return IERC20(uniswapV2Factory.getPair(_tokenA, _tokenB));
    }

    function removingLiquidity(address _tokenA, address _tokenB) public {
        require(_tokenA != address(0), "DeAd address not allowed");
        require(_tokenB != address(0), "DeAd address not allowed");
        IERC20 pair = pairAddress(_tokenA, _tokenB);
        uint256 lptoken = IERC20(pair).balanceOf(msg.sender);
        pair.transferFrom(msg.sender, address(this), lptoken);
        pair.approve(address(uniswapV2Router), lptoken);
        uniswapV2Router.removeLiquidity(
            _tokenA,
            _tokenB,
            lptoken,
            1,
            1,
            msg.sender,
            block.timestamp
        );
        emit liquidityremove(msg.sender, address(pair), lptoken);
    }

    function removingLiquidityETH(address _token) public payable {
        require(_token != address(0), "DeAd address not allowed");
        //IERC20 pair = pairAddress(_token);
        IERC20 token = IERC20(_token);
        uint256 lptoken = IERC20(token).balanceOf(msg.sender);
        token.transferFrom(msg.sender, address(this), lptoken);
        token.approve(address(uniswapV2Router), lptoken);
        uniswapV2Router.removeLiquidity(
            _token,
            WETH,
            lptoken,
            1,
            1,
            msg.sender,
            block.timestamp
        );
        emit liquidityremoveETH(msg.sender, address(token), lptoken);
    }
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