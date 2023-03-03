/**
 *Submitted for verification at Etherscan.io on 2023-03-03
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
This contract simulates an ATM. Users are able to deposit, withdraw and transfer money.
Next to that, users have a credit card that allows a cash advance.
Lastly, admins are able to delete accounts.
**/
contract ATM {

    /**
    * Define a series of events that are triggered with specific functions.
    **/
    event Transfer (address receiver, address sender, uint256 amount);    
    event Deposit  (address sender, uint256 amount);
    event Withdraw (address receiver, uint256 amount);
    event CreditAdvance (address receiver, uint256 amount);
    event Received (address receiver);
    event Deleted (address deletedAddress);
    
    /**
    * Define a custom error in case the balance is not sufficient. 
    * This is used in the withdraw and transfer function.
    **/
    error InsufficientBalance(uint256 currentBalance, uint256 amountRequired);

    /**
    * Create mappings for balances and creditcards.
    * These are different, meaning that not every account has a creditcard.
    **/
    mapping (address => uint256) public _balances;
    mapping (address => uint256) public _creditCards;

    uint256 private _maxDebt = 100;
    address private _owner = msg.sender;
    
    constructor() {
        _maxDebt = 100;
        _owner = msg.sender;
    }

    /**
    * Fallback function for when ethereum is received
    **/
    receive () external payable {
        emit Received (msg.sender);
        revert();
    }


    /**
    * A modifier to check if you're the owner of the contract. Only used in specific Admin functions
    **/
    modifier onlyOwner() {
        require(msg.sender == _owner, "You are not the owner of this ATM");
        _;
    }
    
    /**
    * A function to deposit money into your account
    * @param amount: the amount you want to deposit in your account
    **/
    function deposit(uint256 amount) external payable returns(bool){
        if (_balances[msg.sender] >= amount) {
            revert InsufficientBalance(_balances[msg.sender], amount);
        }    
        _balances[msg.sender] += amount;

        emit Deposit(msg.sender, msg.value);
        return true;
    }
    
    /**
    * A function to withdraw money into your account
    * @param amount the amount to be withdrawn from the account
    **/
    function withdraw(uint256 amount) external payable returns(bool){
        if (_balances[msg.sender] >= amount) {
            revert InsufficientBalance(_balances[msg.sender], amount);
        }

        _balances[msg.sender] -= amount;

        emit Withdraw(msg.sender, msg.value);
        return true;
    }

    /**
    * A function to check the balance of your account
    **/
    function checkBalance() external view returns(uint256){
        return _balances[msg.sender];
    }

    /**
    * A function to transfer money between your account and another account
    * @param receiver -> the address of the receiver
    * @param amount   -> the amount to be transfered
    **/
    function transferMoney(address receiver, uint256 amount) external payable returns(bool){ 
        require(_balances[msg.sender] >= amount, "You have insufficient funds to transfer this amount");
        _balances[msg.sender] -= amount;
        _balances[receiver] += amount;

        emit Transfer(receiver, msg.sender, amount);
        return true;
    }

    /**
    * A function to check the balance of your creditcard account
    **/
    function checkCreditBalance() external view returns(uint256) {
        return _creditCards[msg.sender];
    }

    /**
    * A function to receive an upfront payment from your creditcard
    * @ param amount   -> The amount that the user wants to receive.
    * Requires      -> Is only possible if it does not exceeds the MaxDebt.
    **/
    function creditAdvance(uint256 amount) external payable returns(bool) {
        require(_creditCards[msg.sender] <= _maxDebt, "Too much debt to get a cash advance");
        require(_creditCards[msg.sender] + amount <= _maxDebt, "Withdrawing this will place you in too much debt");

        _creditCards[msg.sender] += amount;
        _balances[msg.sender] += amount;

        emit CreditAdvance(msg.sender, amount);
        return true;
    }

    /**q
    * A function to pay back your credit card
    * @param amount   -> The amount you want to pay back
    **/

    function payBackCredit(uint256 amount) external payable returns(bool) {
        require(_creditCards[msg.sender] > 0, "You have nothing to pay back");
        require(_creditCards[msg.sender] + amount > 0, "Paying this amount off is not possible. Creditcards cannot be positive.");

        _balances[msg.sender] -= amount;
        _creditCards[msg.sender] += amount;

        return true;
    }

    /**
    * An admin function to remove users from the ATM. 
    * This can only be done as the owner of the ATM and should only be used in specific cases
    * @param addr: The address that you want to remove
    **/
    function removeFromATM(address addr) external payable onlyOwner returns(bool) {
        delete _balances[addr];
        emit Deleted(addr);
        return true;
    }
}