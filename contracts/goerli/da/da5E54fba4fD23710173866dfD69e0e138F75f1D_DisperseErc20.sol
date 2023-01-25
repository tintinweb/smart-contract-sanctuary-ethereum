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

// SPDX-License-Identifier: Apache-2.0
// Copyright 2023 Enjinstarter
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IDisperseErc20.sol";

/**
 * @title DisperseErc20
 * @author Tim Loh
 */
contract DisperseErc20 is IDisperseErc20 {
    function disperseErc20(address token, address[] calldata recipients, uint256[] calldata values) external override {
        require(token != address(0), "Disperse: token");
        require(recipients.length > 0, "Disperse: length");
        require(recipients.length == values.length, "Disperse: diff len");

        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; ++i) {
            require(recipients[i] != address(0), "Disperse: recipient");
            require(values[i] != 0, "Disperse: value");

            total += values[i];
        }

        emit Erc20Dispersed(token, total, recipients.length);

        require(IERC20(token).transferFrom(msg.sender, address(this), total), "Disperse: transfer from");

        for (uint256 i = 0; i < recipients.length; ++i) {
            // https://github.com/crytic/slither/wiki/Detector-Documentation/#calls-inside-a-loop
            // slither-disable-next-line calls-loop
            require(IERC20(token).transfer(recipients[i], values[i]), "Disperse: transfer");
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2023 Enjinstarter
pragma solidity ^0.8.0;

/**
 * @title DisperseErc20 Interface
 * @author Tim Loh
 * @notice Interface for DisperseErc20 where ERC-20 tokens will be dispersed to multiple recipients
 */
interface IDisperseErc20 {
    /**
     * @notice Emitted when ERC-20 tokens have been successfully dispersed
     * @param token ERC-20 token address
     * @param total Total amount transferred
     * @param numRecipients Total number of recipients
     */
    event Erc20Dispersed(
        address indexed token,
        uint256 total,
        uint256 numRecipients
    );

    function disperseErc20(address token, address[] calldata recipients, uint256[] calldata values) external;
}