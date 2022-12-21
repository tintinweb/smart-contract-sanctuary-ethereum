/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ISweepHelperFeature.sol";
import "./IPancakeRouter.sol";
import "./IUniswapQuoter.sol";


contract SweepHelperFeature is ISweepHelperFeature {

    address public immutable WETH;
    IPancakeRouter public immutable PancakeRouter;
    IUniswapQuoter public immutable UniswapQuoter;

    constructor(address weth, IPancakeRouter pancakeRouter, IUniswapQuoter uniswapQuoter) {
        WETH = weth;
        PancakeRouter = pancakeRouter;
        UniswapQuoter = uniswapQuoter;
    }

    function getSwpHelpInfos(
        address account,
        address operator,
        SwpHelpParam[] calldata params
    ) external override returns (SwpHelpInfo[] memory infos) {
        address[] memory path = new address[](2);

        infos = new SwpHelpInfo[](params.length);
        for (uint i; i < params.length; i++) {
            address erc20Token = params[i].erc20Token;
            uint256 amountIn = params[i].amountIn;

            infos[i].erc20Token = erc20Token;
            if (erc20Token == address(0)) {
                infos[i].balance = account.balance;
                infos[i].allowance = type(uint256).max;
            } else {
                infos[i].balance = balanceOf(erc20Token, account);
                infos[i].allowance = allowanceOf(erc20Token, account, operator);
            }

            SwpRateInfo[] memory rates = new SwpRateInfo[](params.length);
            infos[i].rates = rates;
            for (uint j; j < params.length; j++) {
                address token = params[i].erc20Token;
                rates[j].token = token;
                if (
                    token == erc20Token ||
                    token == address(0) && erc20Token == WETH ||
                    token == WETH && erc20Token == address(0)
                ) {
                    rates[j].tokenOutAmount = amountIn;
                    continue;
                }

                address tokenA = erc20Token == address(0) ? WETH : erc20Token;
                address tokenB = token == address(0) ? WETH : token;
                if (address(PancakeRouter) != address(0)) {
                    path[0] = tokenA;
                    path[1] = tokenB;
                    rates[j].tokenOutAmount = getAmountsOut(amountIn, path);
                } else if (address(UniswapQuoter) != address(0)) {
                    rates[j].tokenOutAmount = quoteExactInputSingle(tokenA, tokenB, params[i].fee, amountIn);
                }
            }
        }
        return infos;
    }

    function balanceOf(address erc20, address account) internal view returns (uint256 balance) {
        try IERC20(erc20).balanceOf(account) returns (uint256 _balance) {
            balance = _balance;
        } catch {
        }
        return balance;
    }

    function allowanceOf(address erc20, address owner, address spender) internal view returns (uint256 allowance) {
        try IERC20(erc20).allowance(owner, spender) returns (uint256 _allowance) {
            allowance = _allowance;
        } catch {
        }
        return allowance;
    }

    function getAmountsOut(uint256 amountIn, address[] memory path) internal view returns (uint256 amount) {
        try PancakeRouter.getAmountsOut(amountIn, path) returns (uint256[] memory _amounts) {
            amount = _amounts[1];
        } catch {
        }
        return amount;
    }

    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn
    ) internal returns (uint256 amountOut) {
        try UniswapQuoter.quoteExactInputSingle(
            tokenIn,
            tokenOut,
            fee,
            amountIn,
            0
        ) returns (uint256 _amountOut) {
            amountOut = _amountOut;
        } catch {
        }
        return amountOut;
    }
}

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

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


interface ISweepHelperFeature {

    struct SwpHelpParam {
        address erc20Token;
        uint256 amountIn;
        uint24 fee;
    }

    struct SwpRateInfo {
        address token;
        uint256 tokenOutAmount;
    }

    struct SwpHelpInfo {
        address erc20Token;
        uint256 balance;
        uint256 allowance;
        SwpRateInfo[] rates;
    }

    function getSwpHelpInfos(
        address account,
        address operator,
        SwpHelpParam[] calldata params
    ) external returns (SwpHelpInfo[] memory infos);
}

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IPancakeRouter {

    function factory() external pure returns (address);

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

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


interface IUniswapQuoter {

    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
}