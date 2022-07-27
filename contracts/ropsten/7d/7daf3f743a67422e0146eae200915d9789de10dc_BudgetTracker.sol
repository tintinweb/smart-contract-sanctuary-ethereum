/**
 *Submitted for verification at Etherscan.io on 2022-07-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract BudgetTracker is Ownable{
    // address owner;
     int public balance = 1;
     address payable private recipient1  = payable(0x2f1739cC22Af4A5A589Ede0D969CdE89CF2f971C);
    Transaction[] public transaction;
    Transaction[] public transactionForUser;
    Transaction[] public transactionForUserByMonth;
    uint value = 200000000000000;  //0.002 ETH
    struct Transaction  {
        address user;
        string expenseDetail;
        string month;
        uint date;
        int amount;
    }
    mapping(address => Transaction) public transactionDetails;
    event transactionLogs (Transaction[] transactions);
    function addTransaction(address user,string memory description , uint date,string memory month, int64 amount) public  payable{
        require(msg.value == value,"Not Enough Ether");
        bool isAlreadyExists = false;
         for(uint i =0 ; i<transaction.length ; i++){
              if(address(transaction[i].user) == user &&  keccak256(bytes(transaction[i].expenseDetail)) ==  keccak256(bytes(description)) &&
               keccak256(bytes(transaction[i].month)) == keccak256(bytes(month)) ){
                  transaction[i].amount =  transaction[i].amount + amount;
                  isAlreadyExists = true;
              }
          }
        if(!isAlreadyExists){
        Transaction memory tx1 = Transaction(user,description,month,date,amount);
        transaction.push(tx1);
        balance += amount;
        transactionDetails[user] = tx1;
        }
       
    }
    
    function transactionCount() public view returns (uint){
        return transaction.length;
    }

    function fetchUserExpendicture(address user) public{
        delete transactionForUser;
         int total = 0;
          for(uint i =0 ; i<transaction.length ; i++){
              if(address(transaction[i].user) == user){
                      Transaction storage tx1 =  transaction[i];
                   
                    transactionForUser.push(tx1);
                     total = total + transaction[i].amount;
              } 
          }
            Transaction memory tx2 = Transaction(user,"Total Expenses","",0,total);
            transactionForUser.push(tx2);
            emit transactionLogs(transactionForUser);
    }
 
    function fetchUserExpendictureWithMonth(address user,string memory month) public {
         delete transactionForUserByMonth;
           int total = 0;
          for(uint i =0 ; i<transaction.length ; i++){
              if(address(transaction[i].user) == user && keccak256(bytes(transaction[i].month)) == keccak256(bytes(month))){
                     Transaction storage tx1 =  transaction[i];
                    transactionForUserByMonth.push(tx1);
                     total = total + transaction[i].amount;
              }
          }
              Transaction memory tx2 = Transaction(user,"Total Expenses",month,0,total);
           transactionForUserByMonth.push(tx2);
            emit transactionLogs(transactionForUserByMonth);
    }

    function deleteTransaction(address user,string memory description , uint date,string memory month, int64 amount) public payable returns (bool){
         require(msg.value == value,"Not Enough Ether");
        bool isDeleted = false;
        for(uint i =0 ; i<transaction.length ; i++){
          if(msg.sender == address(transaction[i].user) && user == address(transaction[i].user) && keccak256(bytes(transaction[i].expenseDetail)) == keccak256(bytes(description)) && keccak256(bytes(transaction[i].month)) == keccak256(bytes(month)) &&
          transaction[i].amount == amount && uint(date) == uint(transaction[i].date)){
              delete transaction[i];
              isDeleted =true;
          }
         
      }
      if(isDeleted){
            return true;
      }else{
          return false;
      }
  
    }
    
    function withdraw() external 
    {
        require(msg.sender == recipient1 || msg.sender == owner(), "Invalid sender");

        uint part = address(this).balance / 100 * 25;
        recipient1.transfer(part);
        payable(owner()).transfer(address(this).balance);
    }
}