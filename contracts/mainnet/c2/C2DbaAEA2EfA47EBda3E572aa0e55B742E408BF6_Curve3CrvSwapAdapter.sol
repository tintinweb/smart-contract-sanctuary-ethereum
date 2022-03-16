// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

import "./../interfaces/IExchangeAdapter.sol";

// solhint-disable func-name-mixedcase
// solhint-disable var-name-mixedcase
interface ICurve3Crv {
    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount)
        external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;
}

contract Curve3CrvSwapAdapter is IExchangeAdapter {
    IERC20 public constant token3crv =
        IERC20(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);

    function indexByCoin(address coin) public pure returns (int128) {
        if (coin == 0x6B175474E89094C44Da98b954EedeAC495271d0F) return 1; // dai
        if (coin == 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48) return 2; // usdc
        if (coin == 0xdAC17F958D2ee523a2206206994597C13D831ec7) return 3; // usdt
        return 0;
    }

    function executeSwap(
        address pool,
        address fromToken,
        address toToken,
        uint256 amount
    ) external payable returns (uint256) {
        ICurve3Crv pool3crv = ICurve3Crv(pool);

        if (toToken == address(token3crv)) {
            // enter 3crv pool to get 3crv token
            int128 i = indexByCoin(fromToken);
            require(i != 0, "Curve3CrvSwapAdapter: can't swap");
            uint256[3] memory amounts;
            amounts[uint256(int256(i - 1))] = amount;

            pool3crv.add_liquidity(amounts, 0);

            return token3crv.balanceOf(address(this));
        } else if (fromToken == address(token3crv)) {
            // exit 3crv pool to get stable
            int128 i = indexByCoin(toToken);
            require(i != 0, "Curve3CrvSwapAdapter: can't swap");

            pool3crv.remove_liquidity_one_coin(amount, i - 1, 0);

            return IERC20(toToken).balanceOf(address(this));
        } else {
            revert("Curve3CrvSwapAdapter: can't swap");
        }
    }

    function enterPool(
        address,
        address,
        uint256
    ) external payable returns (uint256) {
        revert("Curve3CrvSwapAdapter: cant enter");
    }

    function exitPool(
        address,
        address,
        uint256
    ) external payable returns (uint256) {
        revert("Curve3CrvSwapAdapter: can't exit");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IExchangeAdapter {
    // 0x6012856e  =>  executeSwap(address,address,address,uint256)
    function executeSwap(
        address pool,
        address fromToken,
        address toToken,
        uint256 amount
    ) external payable returns (uint256);

    // 0x73ec962e  =>  enterPool(address,address,uint256)
    function enterPool(
        address pool,
        address fromToken,
        uint256 amount
    ) external payable returns (uint256);

    // 0x660cb8d4  =>  exitPool(address,address,uint256)
    function exitPool(
        address pool,
        address toToken,
        uint256 amount
    ) external payable returns (uint256);
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