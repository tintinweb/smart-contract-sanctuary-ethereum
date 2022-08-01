// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "./interfaces/IVaultTransfers.sol";

contract LiquidityRouter {
    IWETH public WETH;
    IERC20 public token;
    IUniswapV2Pair  public pair;
    IVaultTransfers  public vault;
    address private smallestTokenAddress;
    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "EXPIRED");
        _;
    }
    constructor(
        address _vaultAddress,
        address _pair,
        address _WETH,
        address _token
    ) {
        pair = IUniswapV2Pair(_pair);
        WETH = IWETH(_WETH);
        token = IERC20(_token);
        vault = IVaultTransfers(_vaultAddress);
        smallestTokenAddress = _WETH < _token ? _WETH : _token;
        pair.approve(address(vault), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
    }

    function addLiquidity(uint256 _deadline, uint256 _tokenOutMin)
        public
        payable
        ensure(_deadline)
    {
        require(msg.value > 0, "ZERO_ETH");
        uint256 half = msg.value / 2;
        require(_getAmountToken(half) >= _tokenOutMin, "PRICE_CHANGED");
        uint256 tokenFromSwap = _swapETHforToken(half);
        (
            uint256 liquidityToken,
            uint256 liquidityWETH,
            uint256 lpTokens
        ) = _addLiquidity(tokenFromSwap, half);
        if (tokenFromSwap - liquidityToken > 0)
            token.transfer(msg.sender, tokenFromSwap - liquidityToken);
        if (half - liquidityWETH > 0)
            payable(msg.sender).transfer(half - liquidityWETH);
        vault.depositFor(lpTokens, msg.sender);
    }
    function getMinSwapAmountToken(uint256 _amountETH)
        public
        view
        returns (uint256)
    {
        return _getAmountToken(_amountETH);
    }

    function _swapETHforToken(uint256 _amountETH)
        internal
        returns (uint256 amountToken)
    {
        amountToken = _getAmountToken(_amountETH);
        WETH.deposit{value: _amountETH}();
        WETH.transfer(address(pair), _amountETH);
        (uint256 amount0Out, uint256 amount1Out) = address(WETH) == smallestTokenAddress
            ? (uint256(0), amountToken)
            : (amountToken, uint256(0));
        pair.swap(amount0Out, amount1Out, address(this), new bytes(0));
    }

    function _getAmountToken(uint256 _amountETH) internal view returns (uint256) {
        uint256 reserveETH;
        uint256 reserveToken;
        address(WETH) == smallestTokenAddress ? 
            (reserveETH, reserveToken, ) = pair.getReserves() : 
            (reserveToken, reserveETH, ) = pair.getReserves();
        uint256 amountInWithFee = _amountETH * 998;
        uint256 numerator = amountInWithFee * reserveToken;
        uint256 denominator = reserveETH * 1000 + amountInWithFee;
        return numerator / denominator;
    }

    function _addLiquidity(uint256 _amountTokendesired, uint256 _amountETHdesired)
        internal
        returns (
            uint256 liquidityToken,
            uint256 liquidityETH,
            uint256 lpTokens
        )
    {
        uint256 reserveETH = IERC20(address(WETH)).balanceOf(address(pair));
        uint256 reserveToken = token.balanceOf(address(pair));
        uint256 amountETHOptimal = (_amountTokendesired * reserveETH) /
            reserveToken;
        if (amountETHOptimal <= _amountETHdesired) {
            (liquidityToken, liquidityETH) = (
                _amountTokendesired,
                amountETHOptimal
            );
        } else {
            uint256 amountTokenOptimal = (_amountETHdesired * reserveToken) /
                reserveETH;
            require(amountTokenOptimal <= _amountTokendesired);
            (liquidityToken, liquidityETH) = (
                amountTokenOptimal,
                _amountETHdesired
            );
        }
        token.transfer(address(pair), liquidityToken);
        WETH.deposit{value: liquidityETH}();
        WETH.transfer(address(pair), liquidityETH);
        lpTokens = pair.mint(address(this));
    }
}

pragma solidity ^0.8.2;

interface IVaultTransfers {

    function depositFor(uint256, address) external;
    function withdraw(uint256, address) external;
    function getReward(address) external;
    function withdrawAndHarvest(uint256, address) external;
    function stakeFor(uint256, address) external;
    function unwrap(uint256, address) external;
    function earned(address token, address account) external view returns (uint256);

}