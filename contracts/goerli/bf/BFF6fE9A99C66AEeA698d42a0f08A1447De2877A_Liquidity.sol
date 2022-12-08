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
pragma solidity ^0.8.7;

interface IUniswapV2Factory {
    function getPair(
        address token0,
        address token1
    ) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(
        address indexed sender,
        uint amount0,
        uint amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IUniswapV2Router {
    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Router.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Liquidity is IUniswapV2Pair {
    address private constant _UNISWAP_V2_ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant _FACTORY =
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    address private immutable _sil;
    address private immutable _gld;

    IUniswapV2Router private _router = IUniswapV2Router(_UNISWAP_V2_ROUTER);

    event AddLiquidity(uint amountA, uint amountB, uint liquidity);
    event RemoveLiquidity(uint amountA, uint amountB, uint liquidityBurned);

    constructor(address sil, address gld) {
        _sil = sil;
        _gld = gld;
    }

    function addLiquidity(
        uint _amountA,
        uint _amountB
    ) external returns (uint amountA, uint amountB, uint liquidity) {
        IERC20(_sil).transferFrom(msg.sender, address(this), _amountA);
        IERC20(_gld).transferFrom(msg.sender, address(this), _amountB);
        IERC20(_sil).approve(_UNISWAP_V2_ROUTER, _amountA);
        IERC20(_gld).approve(_UNISWAP_V2_ROUTER, _amountB);

        (amountA, amountB, liquidity) = _router.addLiquidity(
            _sil,
            _gld,
            _amountA,
            _amountB,
            1,
            1,
            msg.sender,
            block.timestamp
        );

        emit AddLiquidity(amountA, amountB, liquidity);
    }

    function removeLiquidity(
        address _tokenA,
        address _tokenB,
        uint liquidity
    ) external returns (uint amountA, uint amountB) {
        address pair = IUniswapV2Factory(_FACTORY).getPair(_tokenA, _tokenB);
        uint balance = IERC20(pair).balanceOf(msg.sender);
        require(balance > liquidity, "Insufficient Liquidity");
        IERC20(pair).transferFrom(msg.sender, address(this), liquidity);
        IERC20(pair).approve(_UNISWAP_V2_ROUTER, liquidity);
        (amountA, amountB) = _router.removeLiquidity(
            _tokenA,
            _tokenB,
            liquidity,
            1,
            1,
            msg.sender,
            block.timestamp
        );

        emit RemoveLiquidity(amountA, amountB, liquidity);
    }

    function getPair(
        address _tokenA,
        address _tokenB
    ) public view returns (address pair) {
        pair = IUniswapV2Factory(_FACTORY).getPair(_tokenA, _tokenB);
    }

    function getLiquidityBalance(
        address _tokenA,
        address _tokenB
    ) public view returns (uint liquidity) {
        address pair = getPair(_tokenA, _tokenB);
        liquidity = IERC20(pair).balanceOf(msg.sender);
    }
}