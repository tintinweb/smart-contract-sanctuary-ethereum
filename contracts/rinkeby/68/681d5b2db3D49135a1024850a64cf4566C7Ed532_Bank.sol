/**
 *Submitted for verification at Etherscan.io on 2022-06-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.12;



// File: Bank.sol

/**
* @title Bank Contract.
* @author Anthony (fps) https://github.com/fps8k.
* @dev  The bank itself.
*       Like a typical bank, users deposit and their balances are
*       recorded against their addresses, but the ether is deposited
*       directly into the contract bank.
*       Withdrawals and Transfers cost some tax.
*       Deposits don't.
*/


contract Bank {
    /**
    * @dev  Plans that controls the users deposits and withdrawals.
    *       There are 4 of them, and as the user upgrades these plans,
    *       there is an increase in the amounts he can deposit and
    *       withdraw.
    *       It is also worthy to note that these plans will be upgraded
    *       one at a time, a Free user cannot move to Ultimate, but
    *       first move to Basic, Pro, then Ultimate.
    *       Ultimate has no limits.
    */
    enum Plan {
        Free,
        Basic,
        Pro,
        Ultimate
    }

    /// @dev Mapping user addresses to their passwords.
    mapping(address => bytes32) private passwords;
    /// @dev Mapping the plans to their prices for upgrades.
    mapping(Plan => uint256) private planPrices;
    mapping(address => Plan) private userPlan;
    /// @dev Mapping plans to their limits.
    mapping(Plan => uint256) private planLimits;
    /// @dev Mapping address to the amount of ether in their balance.
    mapping(address => uint256) private balances;
    /// @dev Maximum ether.
    uint private stretch = type(uint256).max;
    // 0x48656c6c6f204272756e6f204d61727300000000000000000000000000000000
    
    /**
    * @dev  Constructor sets the plan limits and the plan prices for the
    *       deployment of the contract.
    */
    constructor() {
        /// @dev Initialize the `planPrices`.
        planPrices[Plan.Free] = 0;
        planPrices[Plan.Basic] = 0.1 ether;
        planPrices[Plan.Pro] = 0.5 ether;
        planPrices[Plan.Ultimate] = 1 ether;

        /// @dev Initialize the `planLimits`.
        planLimits[Plan.Free] = 1 ether;
        planLimits[Plan.Basic] = 5 ether;
        planLimits[Plan.Pro] = 10 ether;
        planLimits[Plan.Ultimate] = stretch;
    }

    /**
    * @dev  Creates an account for the caller with password as `password`.
    *       The password needs to be hashed off-chain for security.
    *       This will also validate that the msg.sender has no accounts already.
    *
    * @param password User's preferred password.
    */
    function createAccount(bytes32 password) public {
        /// @dev Ensure message sender is not a 0 address.
        require(msg.sender != address(0), "Call from 0 address.");
        /// @dev Ensure caller has no account yet.
        require(!hasAccount(msg.sender), "Address has an account.");
        /// @dev Ensure the password is indeed 32 in length.
        require(password.length == 32, "Invalid password hash.");
        /// @dev Create account.
        passwords[msg.sender] = password;
        userPlan[msg.sender] = Plan.Free;
    }

    /**
    * @dev  Creates an account for `_address` with password as `password`.
    *       The password needs to be hashed off-chain for security.
    *       This will also validate that the `_address` has no accounts already.
    *
    * @param _address   Address to open account for.
    * @param password   User's preferred password.
    */
    function createAccountFor(address _address, bytes32 password) public {
        /// @dev Ensure message sender is not a 0 address.
        require(msg.sender != address(0), "Call from 0 address.");
        /// @dev Ensure address is not a 0 address.
        require(_address != address(0), "Call to 0 address.");
        /// @dev Ensure address has no account yet.
        require(!hasAccount(_address), "Address has an account.");
        /// @dev Ensure the password is indeed 32 in length.
        require(password.length == 32, "Invalid password hash.");
        /// @dev Create account.
        passwords[_address] = password;
        userPlan[_address] = Plan.Free;
    }

    /**
    * @dev  Returns true if the address already owns an account.
    *
    * @param _address Address to check for.
    *
    * @return bool.
    */
    function hasAccount(address _address) private view returns(bool) {
        /// @dev Returns true if the address has set a password already.
        return passwords[_address] != bytes32(0);
    }

    /**
    * @dev  Returns the balance of the caller.
    *       Caller must have an account.
    *
    * @return uint256 caller's balance.
    */
    function getBalance() public view returns(uint256) {
        require(hasAccount(msg.sender), "Non-Account address.");
        return balances[msg.sender];
    }

    /**
    * @dev  Changes password from `oldPassword` to new `passWord`.
    *       Old passwords must match.
    */
    function changePassword(bytes32 oldPassword, bytes32 newPassword) public {
        require(hasAccount(msg.sender), "Non-Account address.");
        require(passwords[msg.sender] == oldPassword, "Wrong password.");
        require(newPassword.length == 32, "Invalid password length.");
        passwords[msg.sender] = newPassword;
    }

    /**
    * @dev Deposits money into the bank.
    */
    function deposit(bytes32 password) public payable {
        require(hasAccount(msg.sender), "Non-Account address.");
        require(passwords[msg.sender] == password, "Wrong password.");
        require(msg.value != 0, "Cannot deposit 0");

        Plan usersPlan = userPlan[msg.sender];
        uint userLimit = planLimits[usersPlan];

        require(msg.value <= userLimit, "Cannot deposit more than your limit.");
        require(balances[msg.sender] + msg.value <= userLimit, "You cannot have more than your limit.");

        balances[msg.sender] += msg.value;
    }

    /**
    * @dev Withdraw money from the bank.
    */
    function withdraw(uint256 amount, bytes32 password) public payable {
        require(hasAccount(msg.sender), "Non-Account address.");
        require(passwords[msg.sender] == password, "Wrong password.");
        require(msg.value != 0, "Cannot withdraw 0");

        Plan usersPlan = userPlan[msg.sender];
        uint userLimit = planLimits[usersPlan];

        require(msg.value <= userLimit, "Cannot withdraw more than your limit.");
        require(balances[msg.sender] >= msg.value, "You cannot withdraw more than you have.");

        payable(msg.sender).transfer(amount);
        balances[msg.sender] -= amount;
    }

    /**
    * @dev Upgrade plan to `level`.
    */
    function upgrade(uint256 level, bytes32 password) public payable {
        require(hasAccount(msg.sender), "Non-Account address.");
        require(passwords[msg.sender] == password, "Wrong password.");
        require(level < 4, "Not valid level");
        
        Plan usersPlan = userPlan[msg.sender];
        uint256 price = planPrices[Plan(level)];

        require(usersPlan != Plan.Ultimate, "You cannot upgrade this. This is max.");
        require(uint256(userPlan[msg.sender]) < level, "You cannot downgrade");

        require(msg.value >= price, "Plan price higher than payment.");

        uint256 balance = msg.value - price;

        userPlan[msg.sender] = Plan(level);
        payable(msg.sender).transfer(balance);
    }

    function show() public view returns(Plan) {
        require(hasAccount(msg.sender), "Non-Account address.");
        return userPlan[msg.sender];
    }
}