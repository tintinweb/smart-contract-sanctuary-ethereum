// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.13;

import "../Interfaces/ISwapRouter.sol";
import "../Interfaces/IERC20Mint.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// fake router use for testing only
/// we will simulate by just minting and returning the native token
/// reminder that we need to grant mint access (use token implementation)
contract FakeSWapRouter is ISwapRouter {
    IERC20Mint public nativeToken;
    uint256 public fakeAmountIn;
    uint256 public multiplier;

    constructor(IERC20Mint _nativeToken, uint256 _multiplier) {
        nativeToken = _nativeToken;

        //define the rates. tokenIn = multipler * tokenOut;
        multiplier = _multiplier;
    }

    function setAmountIn(uint256 _amountIn) external {
        fakeAmountIn = _amountIn;
    }

    function getAmountsIn(uint256 amountOut, address[] memory path)
        external
        view
        returns (uint256[] memory amounts)
    {
        path;

        amounts = new uint256[](2);
        if (fakeAmountIn != 0) {
            amounts[0] = fakeAmountIn;
            amounts[1] = amountOut / multiplier;
        } else {
            // return exact amount as amountOut, assuming amountIn:amountOut = 1:1
            amounts[0] = amountOut / multiplier;
            amounts[1] = amountOut / multiplier;
        }
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts) {
        amountOutMin;
        deadline;
        // siphon in all the tokens to this address
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        nativeToken.mint(to, amountIn * multiplier); // assuming rate is 1 to 1;

        amounts = new uint256[](2);

        // lazy way of applying multiplier to both
        // will not matter in our 'fake' case
        amounts[0] = amountIn * multiplier;
        amounts[1] = amountIn * multiplier;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

interface ISwapRouter {
    function getAmountsIn(uint256 amountOut, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.13;

interface IERC20Mint {
    function mint(address to, uint256 amount) external;
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