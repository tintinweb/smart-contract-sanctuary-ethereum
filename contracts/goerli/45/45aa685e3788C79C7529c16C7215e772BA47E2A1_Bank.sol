/**
 *Submitted for verification at Etherscan.io on 2022-11-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract Bank {
    struct User {
        string bankName;
        uint256 balance;
        uint256 createdAt;
        address userAddress;
        string accountType;
    }

    struct Transaction {
        uint256 amount;
        address destination;
        uint256 date;
    }

    struct InterestTime {
        uint256 date;
    }

    // bank name
    string nameBank;
    
    // mapping of address to password
    mapping(address => User) public userDetail;
    // mapping of address to transaction
    mapping(address => Transaction) public _lastTransactions;
    // mapping of address to interestTime
    mapping(address => InterestTime) private _dueInterest;
    // mapping of address to password
    mapping(address => bytes32) private passwords;
    // mapping of address to boolean
    mapping(address => bool) private time;

    User[] private users;
    Transaction[] private transaction;
    InterestTime[] private interestTime;

    modifier restricted() {
        require(msg.sender != address(0), "You cannot use a zero address");
        require(accountExist(msg.sender), "Account address does not exist");
        _;
    }
    
    /**
     * @dev constructor takes the string and set the nameBank
    */
    constructor() {
        nameBank = "Ethereum Bank";
    }

    /**
     * @dev The following two functions allow the contract to accept ETH deposits
     * directly from a wallet without calling a function
    */
    receive() external payable {}

    fallback() external payable {}


    /**
     * @dev createAccount creates a user account
     */
    function createAccount(bytes32 password) public payable {
        // zero address "0x000000000..."
        require(msg.sender != address(0), "You cannot use a zero address");
        require(msg.value != 0, "Can not deposit 0 amount");
        require(msg.value >= 0.1 ether, "Insufficient amount");
        require(!accountExist(msg.sender), "You already have an account");

        // sets a user details
        User storage createUser = users.push();
        createUser.bankName = nameBank;
        createUser.userAddress = msg.sender;
        createUser.createdAt = block.timestamp;

        passwords[msg.sender] = password;

        if (msg.value >= 0.1 ether) {
            createUser.accountType = "Savings Account";
        }
        if (msg.value >= 0.5 ether) {
            createUser.accountType = "Current Account";
        }
        if (msg.value >= 10 ether) {
            createUser.accountType = "Off-shore Account";
        }

        createUser.balance = msg.value;
        userDetail[msg.sender] = createUser;

        // updates transaction history
        updateTransaction();
        // update time to keep track of when a user is eligible to claim intereset
        eligibleInterest();
    }
    
    /**
     * @dev accountstatus return the status of an account address
    */
    function accountstatus() public view returns(string memory){
        return userDetail[msg.sender].accountType;
    }

    /**
     * deposit eth to the Ethereum Bank unbehalf of the user account
     */
    function deposit() public payable restricted {
        require(msg.value != 0, "Cannot deposit 0");
        userDetail[msg.sender].balance += msg.value;
        // updates transaction history
        updateTransaction();
    }

    /**
     * @dev withdraw the amount of eth from the contract to the users address
     */
    function withdraw(uint256 amount, bytes32 password) public payable restricted {
        require(getBalance() >= msg.value, "Insufficient balance");
        require(passwords[msg.sender] == password, "Password not correct");
        payable(msg.sender).transfer(amount);
        userDetail[msg.sender].balance -= amount;

        // updates transaction history
        Transaction storage userTransaction = transaction.push();
        userTransaction.amount = amount;
        userTransaction.destination = msg.sender;
        userTransaction.date = block.timestamp;
        _lastTransactions[msg.sender] = userTransaction;

        // update time to keep track of when a user is eligible to claim intereset
        eligibleInterest();
    }

    /**
     * @dev returns 2%, 3%, 5% on interest of your savings after 100days 
     * of no transaction. the percentage interest depends on the status
     * your account
     */
    function claimInterest(bytes32 password) public payable restricted {
        require(passwords[msg.sender] == password, "Password not correct");
        require(
            time[msg.sender] == false,
            "you have already withdrew your interest"
        );
        require(
            block.timestamp > _dueInterest[msg.sender].date + 100 days,
            "You are not eligible for interest"
        );
        if(keccak256(abi.encodePacked(accountstatus())) == keccak256(abi.encodePacked("Savings Account")))  {
            uint256 interestRate = (userDetail[msg.sender].balance * 2) / 100;
            payable(msg.sender).transfer(interestRate);
        }
        if(keccak256(abi.encodePacked(accountstatus())) == keccak256(abi.encodePacked("Current Account")))  {
            uint256 interestRate = (userDetail[msg.sender].balance * 3) / 100;
            payable(msg.sender).transfer(interestRate);
        }
        if(keccak256(abi.encodePacked(accountstatus())) == keccak256(abi.encodePacked("Off-shore Account")))  {
            uint256 interestRate = (userDetail[msg.sender].balance * 5) / 100;
            payable(msg.sender).transfer(interestRate);
        }

        time[msg.sender] = true;
    }

    /**
     * @dev bankTranfer: transfers eth within the Ethereum Bank, from one 
     * users account to another user account
     */
    function bankTransfer(address to, uint256 amount, bytes32 password)
        public
        restricted
    {
        require(passwords[msg.sender] == password, "Password not correct");
        require(getBalance() >= amount, "Insufficient balance");
        // 1% transfer charges per transaction within the Ethereum Bank
        uint256 tax = (amount * 1) / 100;
        uint256 totalAmount = amount + tax;
        // debit from the senders account
        userDetail[msg.sender].balance -= totalAmount;
        // transfer to address;
        userDetail[to].balance += amount;
        
        // updates transaction history
        Transaction storage userTransaction = transaction.push();
        userTransaction.amount = amount;
        userTransaction.destination = to;
        userTransaction.date = block.timestamp;
        _lastTransactions[msg.sender] = userTransaction;

         // update time to keep track of when a user is eligible to claim intereset
        eligibleInterest();
    }

    /**
     * @dev interTransfers transfer eth from the Ethereum Bank users account to
     * an etheruem address
     * Note: the address `to` can be a registered Ethereum Bank user or not.
     */
    function interTransfer(address to, uint256 amount, bytes32 password)
        public
        payable
        restricted
    {
        require(passwords[msg.sender] == password, "Password not correct");
        require(getBalance() >= amount, "Insufficient balance");
        // 2% transfer charges per transaction to an ethereum address
        uint256 tax = (amount * 2) / 100;
        uint256 totalAmount = amount + tax;
        // debit from the senders account
        userDetail[msg.sender].balance -= totalAmount;
        // transfer to the receiver
        payable(to).transfer(amount);
        
        // updates transaction history
        Transaction storage userTransaction = transaction.push();
        userTransaction.amount = amount;
        userTransaction.destination = to;
        userTransaction.date = block.timestamp;
        _lastTransactions[msg.sender] = userTransaction;

         // update time to keep track of when a user is eligible to claim intereset
        eligibleInterest();
    }
    
    /**
     * @dev accountExists verifies if an address has a password ie, the address is
     * registered with Ethereum bank
     */
    function accountExist(address _address) public view returns (bool) {
        // return true if password exist
        return passwords[_address] != bytes32(0);
    }

    /**
     * @dev changePassword delete the user password and set a new password for the user
    */
    function changePassword(bytes32 password, bytes32 newPassword)public restricted{
        require(passwords[msg.sender] == password, "Incorrect password");
        passwords[msg.sender] = newPassword;
    }

    /**
     * @dev allTransactions returns all transaction history
     */
    function alltransction() public view returns (Transaction[] memory) {
        return transaction;
    }

    /**
     * @dev getBalance returns the amount of eth a user (msg.sender) has in 
     * the Ethereum Bank account
     */
    function getBalance() public view returns (uint256) {
        require(
            accountExist(msg.sender),
            "Account address does not exist, Create and account"
        );
        return userDetail[msg.sender].balance;
    }

    /**
     * @dev updateTransaction: this function returns the transaction history of a user
     */
    function updateTransaction() private restricted {
        Transaction storage userTransaction = transaction.push();
        userTransaction.amount = msg.value;
        userTransaction.destination = msg.sender;
        userTransaction.date = block.timestamp;
        _lastTransactions[msg.sender] = userTransaction;
    }

    /**
    * @dev eligibleInterest: this function returns the timestamp of when a user account
    * was last debited
    */
    function eligibleInterest()private restricted{
        InterestTime storage user = interestTime.push();
        user.date = block.timestamp;
        _dueInterest[msg.sender] = user;
    }
}