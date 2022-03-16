// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./Whitelisted.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";



/// @title LockedAccount.
/// @author @Dadogg80.
/// @notice This contract will lock any funds transfered into it and destroy the contract at withdrawal like a piggybank.
contract LockedAccount is Whitelisted {
    
    /// @notice Deposit is emited when ETHER is transfered into this smart-contract.
    event Deposit(uint value);

    /// @notice Withdraw is emited when ETHER is transfered out from this smart-contract.
    event Withdraw(uint value);

    /// @notice The deployer of this contract.
    address private owner;

    constructor() {
        owner = payable(msg.sender);
        isWhitelisted[owner] = true;
    }

    /// @notice Receive allows anyone to send ETH or equalent to this contract address.
    receive() external payable {
        emit Deposit(msg.value);
    }

    /// @notice Withdraw all the funds, then destroys the contract.
    /// @dev Restricted to only whitelisted accounts.
    function withdraw() external onlyWhitelisted {
        emit Withdraw(address(this).balance);
        selfdestruct(payable(msg.sender));
    }

    /// @notice Withdraw a given ERC20 token.
    /// @param token The contract address of the ERC20 to withdraw.
    /// @dev Restricted to only whitelisted accounts.
    function withdrawERC20(IERC20 token) external onlyWhitelisted {
        uint balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

/// @title Whitelisted.
/// @author @Dadogg80.
/// @notice This contract is used to whitelist addresses.

contract Whitelisted {

    /// @notice Mapping takes an address and returns true if whitelisted.
    mapping(address => bool) internal isWhitelisted;
    
    address[] private list;

    /// @notice Error: Not authorized.
    /// @dev Error codes are described in the documentation.
    error Code_1();

    /// @notice Modifier used to check if caller is whitelisted. 
    modifier onlyWhitelisted() {
        if (!isWhitelisted[msg.sender]) revert Code_1();
        _;
    }

    /// @notice Whitelist an address.
    /// @param account The address to whitelist.
    /// @dev Call restricted to only whitelisted addresses.
    function addToWhitelist(address account) external onlyWhitelisted {
        isWhitelisted[payable(address(account))] = true;
        list.push(account);
    }

    /// @notice Return the whitelist
    /// @dev Call restricted to only whitelisted addresses.
    function getList() external view onlyWhitelisted returns (address[] memory){
        return list;
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