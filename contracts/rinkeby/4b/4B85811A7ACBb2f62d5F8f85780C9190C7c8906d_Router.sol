//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces/IPair.sol";

contract Router {
    address public spaceCoin;
    address payable public pair;

    constructor(address payable _pair, address payable _spaceCoin) {
        pair = _pair;
        spaceCoin = _spaceCoin;
    }

    function addLiquidity(uint256 amountToken, address to)
        external
        payable
        returns (uint256 liquidity)
    {
        IERC20(spaceCoin).transferFrom(msg.sender, pair, amountToken);
        (bool success, ) = pair.call{value: msg.value}("");

        require(success, "FAILED_ON_TRANSFER_ETH");
        liquidity = IPair(pair).mint(to);
    }

    function removeLiquidity(uint256 liquidity, address payable to)
        external
        returns (uint256 tokenOut, uint256 ethOut)
    {
        IPair(pair).transferFrom(to, address(pair), liquidity);
        (tokenOut, ethOut) = IPair(pair).burn(to);
    }

    function swapExactETHForToken(uint256 amountOutMin)
        external
        payable
        returns (uint256 amountOut)
    {
        (uint256 tokenReserves, uint256 ethReserves) = IPair(pair)
            .getReserves();
        amountOut = getAmountOut(msg.value, ethReserves, tokenReserves);

        require(amountOut >= amountOutMin, "INSUFFICIENT_OUTPUT_AMOUNT");

        (bool success, ) = pair.call{value: msg.value}("");
        require(success, "FAILED_ON_TRANSFER_ETH");

        IPair(pair).swap(amountOut, 0, msg.sender);
    }

    function swapExactTokenForETH(uint256 amountOutMin, uint256 amountIn)
        external
        returns (uint256 amountOut)
    {
        (uint256 tokenReserves, uint256 ethReserves) = IPair(pair)
            .getReserves();

        amountOut = getAmountOut(amountIn, tokenReserves, ethReserves);
        require(amountOut >= amountOutMin, "INSUFFICIENT_OUTPUT_AMOUNT");

        IERC20(spaceCoin).transferFrom(msg.sender, address(pair), amountIn);
        IPair(pair).swap(0, amountOut, msg.sender);
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure returns (uint256 amountOut) {
        require(amountIn > 0, "INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "INSUFFICIENT_LIQUIDITY");

        uint256 amountInWithFee = amountIn * 99;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 100) + amountInWithFee;

        amountOut = numerator / denominator;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPair is IERC20 {
    function mint(address to) external returns (uint256 liquidity);

    function burn(address payable to)
        external
        returns (uint256 tokenOut, uint256 ethOut);

    function swap(
        uint256 tokenOutAmount,
        uint256 etherOutAmount,
        address to
    ) external;

    function getReserves()
        external
        view
        returns (uint256 _tokenReserves, uint256 _ethReserves);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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