// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.11;

import "./IFlatOperator.sol";

/// @title The flat operator doesn't execute any logic to an input.
/// @notice The input is the output, and the input amount is the output amount.
/// Usefull to deposit/withdraw a token without swapping in your Orders.
contract FlatOperator is IFlatOperator {
    /// @inheritdoc IFlatOperator
    function transfer(address token, uint256 amount)
        external
        payable
        override
        returns (uint256[] memory amounts, address[] memory tokens)
    {
        require(amount != 0, "FO: INVALID_AMOUNT");

        amounts = new uint256[](2);
        tokens = new address[](2);

        // Output amounts
        amounts[0] = amount;
        amounts[1] = amount;
        // Output token
        tokens[0] = token;
        tokens[1] = token;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title FlatOperator Operator Interface
interface IFlatOperator {
    /// @notice Execute the flat operator... it does nothing !
    /// @param token The token address
    /// @param amount The amount
    /// @return amounts Array of output amounts
    /// @return tokens Array of output tokens
    function transfer(address token, uint256 amount)
        external
        payable
        returns (uint256[] memory amounts, address[] memory tokens);
}

// SPDX-License-Identifier: MIT

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