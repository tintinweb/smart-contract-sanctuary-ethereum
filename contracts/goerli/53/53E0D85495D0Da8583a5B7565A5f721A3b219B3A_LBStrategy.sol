// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

import "./IStrategy.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LBStrategy is IStrategy{
    uint256 public _totalShares;
    mapping (address => uint256) public _shares;
    address private _underlyingToken_address;
    IERC20 private _underlyingToken;

    constructor(address __underlyingToken){
        _underlyingToken_address = __underlyingToken;
        _underlyingToken= IERC20(__underlyingToken);
    }
    function deposit(IERC20 token, uint256 amount) external returns (uint256){
        token.transferFrom(msg.sender, address(this), amount);
        _shares[msg.sender] += amount;
        _totalShares += amount;
        return amount;

    }
    function withdraw(address depositor, IERC20 token, uint256 amountShares) external{
        token.transfer(depositor, amountShares);
        _shares[depositor] -= amountShares;
        _totalShares -= amountShares;
    }

    function sharesToUnderlying(uint256 amountShares) external returns (uint256){
        return amountShares;
    }
    function underlyingToShares(uint256 amountUnderlying) external returns (uint256){
        return amountUnderlying;
    }
    function userUnderlying(address user) external returns (uint256){
        return _shares[user];
    }
    function sharesToUnderlyingView(uint256 amountShares) external view returns (uint256){
        return amountShares;
    }
    function underlyingToSharesView(uint256 amountUnderlying) external view returns (uint256){
        return amountUnderlying;
    }
    function userUnderlyingView(address user) external view returns (uint256){
        return _shares[user];
    }
    function underlyingToken() external view returns (IERC20){
        return _underlyingToken;
    }
    function totalShares() external view returns (uint256){
        return _totalShares;
    }
    function explanation() external view returns (string memory){
        string memory ret = "This is a test strategy";
        return ret;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Minimal interface for an `Strategy` contract.
 * @author Layr Labs, Inc.
 * @notice Custom `Strategy` implementations may expand extensively on this interface.
 */
interface IStrategy {
    /**
     * @notice Used to deposit tokens into this Strategy
     * @param token is the ERC20 token being deposited
     * @param amount is the amount of token being deposited
     * @dev This function is only callable by the strategyManager contract. It is invoked inside of the strategyManager's
     * `depositIntoStrategy` function, and individual share balances are recorded in the strategyManager as well.
     * @return newShares is the number of new shares issued at the current exchange ratio.
     */
    function deposit(IERC20 token, uint256 amount) external returns (uint256);

    /**
     * @notice Used to withdraw tokens from this Strategy, to the `depositor`'s address
     * @param depositor is the address to receive the withdrawn funds
     * @param token is the ERC20 token being transferred out
     * @param amountShares is the amount of shares being withdrawn
     * @dev This function is only callable by the strategyManager contract. It is invoked inside of the strategyManager's
     * other functions, and individual share balances are recorded in the strategyManager as well.
     */
    function withdraw(address depositor, IERC20 token, uint256 amountShares) external;

    /**
     * @notice Used to convert a number of shares to the equivalent amount of underlying tokens for this strategy.
     * @notice In contrast to `sharesToUnderlyingView`, this function **may** make state modifications
     * @param amountShares is the amount of shares to calculate its conversion into the underlying token
     * @return The amount of underlying tokens corresponding to the input `amountShares`
     * @dev Implementation for these functions in particular may vary significantly for different strategies
     */
    function sharesToUnderlying(uint256 amountShares) external returns (uint256);

    /**
     * @notice Used to convert an amount of underlying tokens to the equivalent amount of shares in this strategy.
     * @notice In contrast to `underlyingToSharesView`, this function **may** make state modifications
     * @param amountUnderlying is the amount of `underlyingToken` to calculate its conversion into strategy shares
     * @return The amount of underlying tokens corresponding to the input `amountShares`
     * @dev Implementation for these functions in particular may vary significantly for different strategies
     */
    function underlyingToShares(uint256 amountUnderlying) external returns (uint256);

    /**
     * @notice convenience function for fetching the current underlying value of all of the `user`'s shares in
     * this strategy. In contrast to `userUnderlyingView`, this function **may** make state modifications
     */
    function userUnderlying(address user) external returns (uint256);

     /**
     * @notice Used to convert a number of shares to the equivalent amount of underlying tokens for this strategy.
     * @notice In contrast to `sharesToUnderlying`, this function guarantees no state modifications
     * @param amountShares is the amount of shares to calculate its conversion into the underlying token
     * @return The amount of shares corresponding to the input `amountUnderlying`
     * @dev Implementation for these functions in particular may vary significantly for different strategies
     */
    function sharesToUnderlyingView(uint256 amountShares) external view returns (uint256);

    /**
     * @notice Used to convert an amount of underlying tokens to the equivalent amount of shares in this strategy.
     * @notice In contrast to `underlyingToShares`, this function guarantees no state modifications
     * @param amountUnderlying is the amount of `underlyingToken` to calculate its conversion into strategy shares
     * @return The amount of shares corresponding to the input `amountUnderlying`
     * @dev Implementation for these functions in particular may vary significantly for different strategies
     */
    function underlyingToSharesView(uint256 amountUnderlying) external view returns (uint256);

    /**
     * @notice convenience function for fetching the current underlying value of all of the `user`'s shares in
     * this strategy. In contrast to `userUnderlying`, this function guarantees no state modifications
     */
    function userUnderlyingView(address user) external view returns (uint256);

    /// @notice The underlying token for shares in this Strategy
    function underlyingToken() external view returns (IERC20);

    /// @notice The total number of extant shares in this Strategy
    function totalShares() external view returns (uint256);

    /// @notice Returns either a brief string explaining the strategy's goal & purpose, or a link to metadata that explains in more detail.
    function explanation() external view returns (string memory);
}