//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title DGX Swap Contract
/// @notice Contract to allows users to swap DGX tokens for CGT

contract SwapContract {

    address public constant CGT_ADDRESS = 0x1BDe87e1f83A20a39fcFDED73363DeBE3a88f602;
    address public constant DGX_ADDRESS = 0xB5BDc848Ed5662DC0C52b306EEDF8c33584a3243;

    uint public DGX_AmountBurnt;
    uint constant DGX_DECIMALS = 10 ** 9;
    uint constant DECIMAL_FACTOR = 10 ** (9-8); //DGX has 9 decimal places whereas CGT has 8

    event swappedTokens(uint DGX_Amount, address account);

    /// @notice Swaps DGX tokens for CGT tokens
    /// @dev DGX tokens are burnt
    /// @param _amount The amount of DGX tokens to be swapped, multiplied by DGX_DECIMALS 10 ** 9
    function swap(uint256 _amount) external {
        require(IERC20(DGX_ADDRESS).balanceOf(msg.sender) >= _amount, "Insufficient DGX balance");
        require(IERC20(CGT_ADDRESS).balanceOf(address(this)) >= _amount / DECIMAL_FACTOR, "Insufficient CGT in contract");
        require(IERC20(DGX_ADDRESS).allowance(msg.sender, address(this)) >= _amount, "Amount exceeds DGX allowance");
        DGX_AmountBurnt += _amount;
        IERC20(DGX_ADDRESS).transferFrom(msg.sender, address(0), _amount);
        // here we need to always give the user an equivalent amount of gold grams more is okay, less is not
        IERC20(CGT_ADDRESS).transfer(msg.sender, (_amount / DECIMAL_FACTOR) + round(_amount , DGX_DECIMALS));
        emit swappedTokens(_amount, msg.sender);
    }

    /// @dev Rounds the token a and returns 1 if it is to be rounded up
    /// @param a the token amount, m the number of decimals to round at
    function round(uint256 a, uint256 m) internal pure returns (uint ) {
        if(a % m >= 5)
            return 1;
        return 0;
    }
}

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