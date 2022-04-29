/**
 *Submitted for verification at Etherscan.io on 2022-04-29
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;




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

/**
@title An on-chain name registry
@author Calnix
@dev Vault for a specific ERC20 token; token address to be passed to constructor.
@notice Vault for a pre-defined ERC20 token that was set on deployment. 
*/

contract BasicVault {
    
    ///@notice ERC20 interface specifying token contract functions
    ///@dev For constant variables, the value has to be fixed at compile-time, while for immutable, it can still be assigned at construction time.
    IERC20 public immutable wmdToken;    

    ///@notice mapping addresses to their respective token balances
    mapping(address => uint) public balances;

    /// @notice Emit event when tokens are deposited into Vault
    event Deposited(address indexed from, uint amount);
    
    /// @notice Emit event when tokens are withdrawn from Vault
    event Withdrawal(address indexed from, uint amount);
    
    ///@param wmdToken_ ERC20 contract address
    constructor(IERC20 wmdToken_){
        wmdToken = wmdToken_;
    }

    /// @notice User can deposit tokens into Vault
    /// @dev Expect Deposit to revert if transferFrom fails
    /// @param amount The amount of tokens to deposit
    function deposit(uint amount) external {    
        balances[msg.sender] += amount;

        bool success = wmdToken.transferFrom(msg.sender, address(this), amount);
        require(success, "Deposit failed!"); 
        emit Deposited(msg.sender, amount);
    }

    /// @notice User can withdraw tokens from Vault
    /// @dev Expect Withdraw to revert if transfer fails
    /// @param amount The amount of tokens to withdraw
    function withdraw(uint amount) external {      
        balances[msg.sender] -= amount;
        
        bool success = wmdToken.transfer(msg.sender, amount);
        require(success, "Withdrawal failed!");
        emit Withdrawal(msg.sender, amount);
    }

}