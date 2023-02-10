/**
 *Submitted for verification at Etherscan.io on 2023-02-10
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4; 

contract DepositWithdraw1 {
    address public _owner;
    uint256 private constant fees = 0.00005 ether; 
   
    
    uint256 private   lock_time; 
    uint256 private amount;
    uint256 private balance;
    uint256 private lockPeriod;
    constructor() {
        _owner = msg.sender;
    }
    
    enum AccountType
    {
        SAVINGS, 
        FIXED
    }
    struct Account {
        address owner;
        uint256 balance;
        uint256 accountCreatedTime;
        
        uint256 atype;
    }
    mapping(address => Account) public MDAccount;
    mapping(address => bool) public BlockListed;
    event balanceAdded(address owner, uint256 balance, uint256 timestamp);
    event withdrawalDone(address owner, uint256 balance, uint256 timestamp);

    modifier minimum() {
        require(msg.value >= 0.00003 ether, "Doesn't follow minimum criteria");
        _;
    }

    function accountCreated(address account) public payable{

        MDAccount[account].owner = account;
         MDAccount[account].balance = msg.value;
        MDAccount[account].accountCreatedTime = block.timestamp;
        emit balanceAdded(account, msg.value, block.timestamp);
    }
      // FDfunds
     function FDFund(uint256 _amount, uint256 _lock_time) public {
        balance = _amount;
        lockPeriod = _lock_time;
       
        require(_amount >= 0.003 ether, "Invalid amount");
        
        require(MDAccount[msg.sender].balance >= _amount, "Not Enough balance");
         // require(_balance<=0.00005 ether,"max amount reached");
        uint fees=0.00005 ether;
 

   
    
       
    }
   
         function withdrawal() public payable {
            // address.transfer(amount to transfer)
            payable(msg.sender).transfer(MDAccount[msg.sender].balance);
            MDAccount[msg.sender].balance = 0; // clear the balance
            // payable(msg.sender)
            require(block.timestamp <= lock_time, "Funds are in locking period wait now");
            require(balance >= msg.value, "not enough funds");
            require(msg.value <= 0.5 ether, "Max locked > 0.5 ether");
            payable(msg.sender).transfer (msg.value);
            balance -= msg.value;
            emit withdrawalDone(
                msg.sender,
                MDAccount[msg.sender].balance,
                block.timestamp
            );
            
        } 
      

  

    
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    

    // depositing funds
    function deposit() public payable minimum {
        MDAccount[msg.sender].balance += msg.value;
        emit balanceAdded(msg.sender, msg.value, block.timestamp);
    }

    
    

    function getBalance(address _add) public view onlyOwner returns(uint256)
    {
        return MDAccount[_add].balance;
    }

  function close_account() public
    {
        delete MDAccount[msg.sender];
    }

    function blockUser(address _address) public onlyOwner {
        BlockListed[_address] = true;
        
  }    
    function removefromblocklist(address _address) public onlyOwner{
        BlockListed[_address] = false;
    }
         

    }