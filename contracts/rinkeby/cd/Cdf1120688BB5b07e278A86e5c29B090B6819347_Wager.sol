// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

/// @author - unterrorize (DP)
contract Wager {


    constructor() payable {
    }

     //User values that is stored on the blockchain
    struct User {
        uint id;
        uint balance; // balance of eth credit to be withdrawed for User
        uint rank; //  rank of associated user
        bool withdrawPending;
        uint withdrawlBalance;
    }

    
    address owner =  msg.sender;
    uint totalusers = 1;
    
    mapping(address => User) public users;

    //Errors
    /// You are not an active user, configure yourself as a user from the discord.
    error notActive();
    /// There is not enough funding to satisfy transaction.
    error insufficientFunds();
    /// Values are controlled at server level. Start this command at the discord level.
    error accessError();
    /// You already have a pending withdraw, use the withdraw() command
    error claimPending();
    /// Please send the transaction receipt to admin.
    error adminError();
    /// You need to initialize a claim at the discord level
    error claimNotInitialized();

    // Events - read by event_listener.py to display transactions
    event userAdded(address indexed userAddy);
    event withdrawInitialized(address indexed userAddy, uint256 indexed withdrawl, uint256 indexed updatedUserBalance);
    event fundsAdded(address indexed userAddy, uint256 indexed depositAmount, uint256 indexed updatedBalance);
    event rankUpdated(address indexed userAddy, uint256 indexed rank);
    event balanceUpdated(address indexed userAddy, uint256 indexed balance);


    function getRank(address addy) public view returns (uint256){
        return users[addy].rank;
    }

    function getBalance(address addy) public view returns (uint256){
        return users[addy].balance;
    }

    function setRank(address userAddy, uint256 elo) public returns(bool){
        if(msg.sender != owner) 
            revert accessError();
        users[userAddy].rank = elo;
        emit rankUpdated(userAddy, elo);
        return true;
    }

    //House take %3 commission for every transaction, handled at server level. pass in calculated balance
    //Handle as many computations at we3_logic level as possible.  
    //If necessary, here is a resource for computation methods https://chowdera.com/2022/01/202201201455474678.html
    function setBalance(address userAddy, uint256 value) public returns (bool){
        if(msg.sender != owner) 
            revert accessError();
        emit balanceUpdated(userAddy,value);
        users[userAddy].balance = value;
        return true;
    }

    //Default value for user not in?
    //https://stackoverflow.com/questions/37852682/are-there-null-like-thing-in-solidity
    //assuming unassigned struct = 0 
    function isUser(address userAddy) public view returns (bool){
            if(users[userAddy].id > 0){
                return true;
            } else return false; }
    
    function addUser(address userAddy) public returns (bool){
        if(msg.sender != owner) 
            revert accessError();
        if(isUser(userAddy))
            revert adminError();
        emit userAdded(userAddy);
        users[userAddy].id = totalusers;
        totalusers += 1;
        users[userAddy].balance = 0;
        users[userAddy].rank = 1000;
        users[userAddy].withdrawPending = false;
        users[userAddy].withdrawlBalance = 0;
        
        return true;
    }


    function isPendingWithdraw(address userAddy) public view returns (bool) {
        if(!isUser(msg.sender))
            revert notActive();
        return users[userAddy].withdrawPending;
    }


    //
    function initializeWithdraw(address userAddy, uint256 withdrawl) public returns(bool){
        if(msg.sender != owner) 
            revert accessError();
        if (isPendingWithdraw(userAddy)) 
            revert claimPending();
        if(!isUser(userAddy))
            revert notActive();
        if (users[userAddy].balance <= withdrawl) 
            revert adminError(); 
        

        
        users[userAddy].withdrawPending = true;
        uint256 updatedBalance = users[userAddy].balance - withdrawl;
        users[userAddy].withdrawlBalance = withdrawl;
        setBalance(userAddy,updatedBalance);
        emit withdrawInitialized(userAddy,withdrawl,updatedBalance);
        
        return true;
    }
    
    
    function withdraw() public {
        if(!isUser(msg.sender))
            revert notActive();
        if(!isPendingWithdraw(msg.sender))
            revert claimNotInitialized();
        uint amount = users[msg.sender].withdrawlBalance;
        users[msg.sender].withdrawPending = false;
        users[msg.sender].withdrawlBalance = 0;
        payable(msg.sender).transfer(amount);
    }

    
    function userDeposit() external payable {
        if(!isUser(msg.sender))
            revert notActive();
  
        users[msg.sender].balance += msg.value;
        emit fundsAdded(msg.sender, msg.value, users[msg.sender].balance); // **
    }


    // Triggers week period to have %80 of active users to terminate contract. If so, 
    // disburse %70 back to owners, will be a pricey command to run - price of doing business.
    // will implement with official launch at +500 members
    function m0bRuLz() internal {
        require(msg.sender == owner);
        selfdestruct(payable(msg.sender));
    }

}