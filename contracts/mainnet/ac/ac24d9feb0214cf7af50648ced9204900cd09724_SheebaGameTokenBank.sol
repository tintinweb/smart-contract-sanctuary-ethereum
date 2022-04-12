/**
 *Submitted for verification at Etherscan.io on 2022-04-11
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/tokenIssueContract.sol


// Written by Metabridge - https://www.metabridgeagency.com
// We are a community of passionate <humans /> building a distributed world

pragma solidity ^0.8.0;


/// @author MetaBridge Agency LLC
/// @title The bank for the Sheeba play to earn rewards.
contract SheebaGameTokenBank {
    IERC20 public erc20Token;
    
    address public owner;
    string public name = "Sheeba Game Token Bank";

    mapping(address => bool) public admins;
    mapping(address => uint256) public earners;
    mapping(address => bool) public blockedAddresses;

    constructor(address _erc20Token) {
        erc20Token = IERC20(_erc20Token);
        owner = msg.sender;
        // Set the owner as a dev
        admins[msg.sender] = true;
    }

    /// Return the users token balance.
    /// @param userAddress the address to check.
    /// @return the users token balance.
    function getTokenBalance(address userAddress) public view returns(uint256) {
        return erc20Token.balanceOf(userAddress);
    }

    /// Return the contracts balance of tokens.
    /// @return the contracts balance of tokens.
    function getContractBalance() public view returns(uint256) {
        return getTokenBalance(address(this));
    }

    /// Return the users reward balance.
    /// @param userAddress the address to check.
    /// @return the users reward balance.
    function getRewardsBalance(address userAddress) public view returns(uint256) {
        return earners[userAddress];
    }

    /// Store 'totalSheeb'.
    /// @param userAddressToAdd the address to add.
    /// @param totalSheeb the amount of sheeb to add to the user. Not in full form decimal ex. 10 Tokens = 10
    function addTokens(address userAddressToAdd, uint256 totalSheeb) public {
        // Check if admin
        require(admins[msg.sender] == true, "YOU ARE NOT AN ADMIN");
        // Start
        earners[userAddressToAdd] = earners[userAddressToAdd] += totalSheeb * 10 ** 18;
    }

    /// Store 'totalSheeb' per user.
    /// @param userAddresses the addresses to add.
    /// @param points the points to add. Not in full form decimal ex. 10 Tokens = 10
    function addTokensMultiple(address[] memory userAddresses, uint256[] memory points) public {
        // Check if admin
        require(admins[msg.sender] == true, "YOU ARE NOT AN ADMIN");
        require(userAddresses.length == points.length, "Unequal arrays");

        // Start
        for (uint i=0; i<userAddresses.length; i++) {
            earners[userAddresses[i]] = earners[userAddresses[i]] += points[i] * 10 ** 18;
        }
    }

    /// Store 'userAddressToAdd' as either bot or not.
    /// @param userAddressToAdd the address to add or remove.
    /// @param isBot the indication of whether or not this address is a bot.
    function userIsBot(address userAddressToAdd, bool isBot) public {
        // Check if admin
        require(admins[msg.sender] == true, "YOU ARE NOT AN ADMIN");
        // Start
        blockedAddresses[userAddressToAdd] = isBot;
    }

    /// Store 'newAdmin' as admin.
    /// @param newAdmin the address to add.
    function addAdmin(address newAdmin) public {
        require(admins[msg.sender] == true, "YOU ARE NOT AN ADMIN");

        // Any admin can remove the another
        require(newAdmin != msg.sender, "Cannot add yourself as admin.");
        admins[newAdmin] = true;
    }

    /// Store 'adminToRemove' as admin.
    /// @param adminToRemove the address to remove.
    function removeAdmin(address adminToRemove) public {
        require(admins[msg.sender] == true, "YOU ARE NOT AN ADMIN");
        
        // Any admin can remove the another
        require(adminToRemove != msg.sender, "Cannot remove yourself as admin.");
        admins[adminToRemove] = false;
    }

    /// Remove the tokens from the contract in case of upgrade or contract issue.
    function retrieveRewardTokens() public {
        require(admins[msg.sender] == true, "YOU ARE NOT AN ADMIN");
        uint256 contractBalance = getTokenBalance(address(this));
        erc20Token.transfer(msg.sender, contractBalance);
    }

    /// Send the tokens to the users wallet.
    function recieveReward() public {
        uint256 amountToSend = earners[msg.sender];
        // Get balance of contract
        uint256 contractBalance = getTokenBalance(address(this));

        require(amountToSend > 0, "You have not earned any tokens.");
        require(contractBalance >= amountToSend, "Not enough tokens in the contract. Please contact the DEV team.");
        
        earners[msg.sender] = 0;
        erc20Token.transfer(msg.sender, amountToSend);
    }
}