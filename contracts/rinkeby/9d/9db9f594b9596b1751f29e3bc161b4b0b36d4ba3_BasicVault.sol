// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "yield-utils-v2/token/IERC20.sol";

/// @title Vault holding ERC20 tokens for users
/// @author davidbrai
/// @notice The vault allows users to deposit and withdraw token of a specific ERC20 contract. The contracts keeps track of balances.
contract BasicVault {

    /// @notice ERC20 token which this vault holds tokens for
    IERC20 immutable public token;

    /// @notice Mapping from address to balance representing the balance of each user
    mapping(address => uint) public balances;

    error BalanceTooLow();
    error TransferFailed();

    /// @notice This event is emitted when a user deposits tokens
    event Deposit(address from, uint amount);

    /// @notice This event is emitted when a user withdraws tokens
    event Withdraw(address to, uint amount);

    /// @notice Initalizes a new vault
    /// @param _token The address of an ERC20 token contract
    constructor(IERC20 _token) {
        token = _token;
    }

    /// @notice Deposits tokens from the user into the vault
    /// @dev Updates the balances mapping with the amount of tokens
    /// @param amount The amount of tokens to deposit
    function deposit(uint amount) public {
        balances[msg.sender] += amount;

        bool success = token.transferFrom(msg.sender, address(this), amount);
        if (!success) {
            revert TransferFailed();
        }

        emit Deposit(msg.sender, amount);
    }

    /// @notice Withdraws tokens back to the user
    /// @dev Updates the balances mapping with the amount of tokens
    /// @param amount The amount of tokens to be withdrawn
    function withdraw(uint amount) public {
        if (balances[msg.sender] < amount) {
            revert BalanceTooLow();
        }

        balances[msg.sender] -= amount;
        bool success = token.transfer(msg.sender, amount);
        if (!success) {
            revert TransferFailed();
        }
        
        emit Withdraw(msg.sender, amount);
    }
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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