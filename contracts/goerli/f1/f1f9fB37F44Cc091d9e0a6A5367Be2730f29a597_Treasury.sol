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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface ITreasury {
    function receiveFromUserWithETH(address user, address _tokenAddress) external payable;
    function receiveFromUser(address payTokenAddress, address tokenAddress, address user, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IUniswapV2Router02.sol";
import "./ITreasury.sol";

contract Treasury is ITreasury {
    event feeUpdated(uint256 newfee);

    address internal constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address payable public owner;
    IUniswapV2Router02 public uniswapRouter;

    uint256 public fee;

    constructor() {
        owner = payable(msg.sender);
        uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
        fee = 5;
    }

    function receiveFromUserWithETH(address user, address _tokenAddress) external payable {
        convertEthToCoin(user, _tokenAddress);
    }

    function receiveFromUser(address payTokenAddress, address tokenAddress, address user, uint256 amount) external {
        IERC20(payTokenAddress).transferFrom(msg.sender, address(this), amount);
        convertTokenToToken(payTokenAddress, tokenAddress, user, amount * (100 - fee) / 100);
    }

    fallback() external payable { }

    function convertTokenToToken(address payTokenAddress, address tokenAddress, address user, uint256 payAmount) internal {
        uint256 deadline = block.timestamp + 15000; // using 'now' for convenience, for mainnet pass deadline from frontend!
        uint256[] memory amounts = uniswapRouter.getAmountsOut(payAmount, getPathForTokentoToken(payTokenAddress, tokenAddress));
        IERC20(payTokenAddress).approve(address(uniswapRouter), amounts[0]);
        uniswapRouter.swapExactTokensForTokens(
            payAmount,
            amounts[amounts.length - 1],
            getPathForTokentoToken(payTokenAddress, tokenAddress),
            user,
            deadline
        );
    }

    function convertEthToCoin(address user, address _tokenAddress) internal {
        uint256 deadline = block.timestamp + 15000; // using 'now' for convenience, for mainnet pass deadline from frontend!
        uint256[] memory amounts = getEstimatedETHforCoin(msg.value * (100 - fee) / 100, _tokenAddress);
        uniswapRouter.swapETHForExactTokens{value: msg.value * (100 - fee) / 100}(
            amounts[1],
            getPathForETHtoCoin( _tokenAddress ),
            user,
            deadline
        );
    }

    function getEstimatedETHforCoin(uint256 ethAmount, address _tokenAddress)
        public
        view
        returns (uint256[] memory)
    {
        return uniswapRouter.getAmountsOut(ethAmount, getPathForETHtoCoin(_tokenAddress));
    }

    function getPathForETHtoCoin(address _tokenAddress) private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = _tokenAddress;

        return path;
    }
    function getPathForTokentoToken(address payTokenAddress, address tokenAddress) private pure returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = payTokenAddress;
        path[1] = tokenAddress;

        return path;
    }
    
    function feeUpdate(uint256 newfee) external{
        require(owner == msg.sender);
        fee = newfee;
        emit feeUpdated(newfee);
    }
    function getFee() view external returns (uint256){
        return fee;
    }

}