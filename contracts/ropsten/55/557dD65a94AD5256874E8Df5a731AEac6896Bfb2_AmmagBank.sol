//SPDX-License-Identifier: MIT

import "./Counters.sol";
import "./IAccounts.sol";
pragma solidity ^0.8.4;

contract AmmagBank is IAccounts{
    using Counters for Counters.Counter;
    Counters.Counter trasactionID;
   struct Account {
        address accountAddress;
        uint256 dateTime;
        string accountTitle;
        uint256 amount;
        bool lockDeposit;
        bool deListed;
        bool blackListed;
    }
    struct Transaction{
        address sender;
        address reciever;
        uint amount;
        uint dateTime;
    }

    mapping (uint => Transaction) transactions;
    mapping (address => Transaction) transactionsByAddress;
    address payable winner;
    address payable deListClient;
    address public bankOwner;
    address public bankManager;
    mapping(address => Account) public accounts; //make it private
    mapping(address => bool) public blacklisedAddresses;
    mapping(address => bool) public DelisedAddresses;   
    address payable[] private clientsRewardList; 

    constructor(){
        bankOwner = msg.sender; 
    }

    function ChangeOwnerShip(address newOwner) public onlyBankOwner{
        bankOwner = newOwner;
    }
    function HandleManagerSeat(address manager) public onlyBankOwner{
        bankManager = manager;
    }
    ///////////////////////////Modifiers/////////////////////////////////////////
    
    modifier onlyBankOwner{
        require (msg.sender == bankOwner, "Only Bank Owner can perform this task.");
        _;        
    }

    modifier lockedDeposit{
        bool flag = accounts[msg.sender].lockDeposit;
        require(!flag,"You're not eligible to perfom this task");
        _;
    }
    modifier IsdeListed{
        bool flag = accounts[msg.sender].deListed;
        require(!flag,"You're not account holder.");
        _;
    }
    modifier onlyBankManager{
        require (msg.sender == bankManager, "Only Bank Manager can perform this task.");
        _;        
    }
    modifier blackListedAddress{
        require (!blacklisedAddresses[msg.sender] , "You're BlackListed.");
        _;
    }
    modifier deListedAddress{
        require (!DelisedAddresses[msg.sender] , "You're Delisted.");
        _;
    }
    ///////////////////////////Account Handling/////////////////////////////////////////
    function CreateAccount(string memory _name, address _clientAddress) public override onlyBankManager {
        Account memory a;
        a.accountAddress = _clientAddress;
        a.dateTime = block.timestamp;
        a.accountTitle = _name;
        a.lockDeposit = false;
        a.deListed = false;
        a.blackListed = false;
        accounts[_clientAddress] = a;

        // Delisted Account Renew
        if(DelisedAddresses[_clientAddress]){
            DelisedAddresses[_clientAddress] = false;
        }
    }

    function ClientProfile(address _accountAddress) public view override deListedAddress 
    returns(address AccountHolder, uint DateTime, string memory Title, uint Amount, bool DeListed, bool DepositLocked ){
        address accountAddress = accounts[_accountAddress].accountAddress; 
        uint256 dateTime = accounts[_accountAddress].dateTime;
        string memory accountTitle = accounts[_accountAddress].accountTitle;
        uint256 amount = accounts[_accountAddress].amount;
        bool isDeListted = accounts[_accountAddress].deListed;
        bool islockDeposit = accounts[_accountAddress].lockDeposit;
        return (accountAddress, dateTime, accountTitle, amount, isDeListted, islockDeposit );
    }
    function UpdateProfile(address _accountAddress, string memory _accountTitle) public override blackListedAddress deListedAddress {
        require (msg.sender ==_accountAddress || msg.sender == bankManager, "You're not authorised.");
        accounts[_accountAddress].accountTitle = _accountTitle;        
    }
    ///////////////////////////Transactions/////////////////////////////////////////
    function Deposit() public IsdeListed blackListedAddress payable override  {      
        require (msg.sender != bankManager && msg.value>0, "You cannot add amount to Bank Manager's account.");
        accounts[msg.sender].amount = msg.value;
        if(msg.value>= 1 ether){
            clientsRewardList.push(payable(msg.sender));
        }
    }
    function FundsWithdraw( uint256 _value) public blackListedAddress lockedDeposit IsdeListed override payable{
        require(accounts[msg.sender].amount >= _value && _value >0 , "no sufficent amount.");
        accounts[msg.sender].amount -= _value;
    }
    
    function TransferBWAccounts(address _recipient, uint _value) public blackListedAddress lockedDeposit IsdeListed override {
        require( msg.sender != bankManager, "You're Manager,");
        require(accounts[msg.sender].amount >= _value && _value >0 && msg.sender != bankManager, "no sufficent amount.");

        accounts[msg.sender].amount -= _value;
        accounts[_recipient].amount += _value;
        
        trasactionID.increment();
        uint _TrasactionID = trasactionID.current();
        Transaction memory t;
        t.sender = msg.sender;
        t.reciever = _recipient;
        t.amount = _value;
        t.dateTime = block.timestamp;
        transactions[_TrasactionID] = t;
        transactionsByAddress[msg.sender] = t;
    }
    function ViewAccountBalance(address owner) public view override returns(uint) {
        return accounts[owner].amount;
    }
    /////////////////////////////Transaction Report////////////////////////////////
    function ShowTransactions(uint tID) public view returns(Transaction memory){
    return transactions[tID];
    }
    function ShowTransactionBySender(address sender) public view returns(Transaction memory){
        return transactionsByAddress[sender];
    }
    function TotalTransactions() public view override returns(uint) {
        return trasactionID.current();
    }
    function ShowTransactionRecord()public view returns (Transaction[] memory) {
        uint256 numberOfExistingTokens = trasactionID.current();
        Transaction[] memory ownedTokenIds = new Transaction[](numberOfExistingTokens);
        for (uint256 x = 0; x < numberOfExistingTokens; x++) {
            ownedTokenIds[x] = transactions[x+1];
        }
        return ownedTokenIds;
    }
    /////////////////////////////Reward Section////////////////////////////////////////
    function random() private view  returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,clientsRewardList.length)));
    }
    function RewardWinner() public override {
        require (clientsRewardList.length >= 3);
        uint r = random();
        uint index = r % clientsRewardList.length;
        winner = clientsRewardList[index];
    }
    function RewardTransferToWinner() public override{
        winner.transfer(5 ether); // 5 ether is reward amount
        clientsRewardList = new address payable[](0);
    }  
    function ShowWinner() public override view returns(string memory){
       string memory a =accounts[winner].accountTitle;
        return a;
    }
    /////////////////////////////client listing////////////////////////////////////////
    function BlacklistHandler(address _blacklistAddress, bool _status)  public override onlyBankManager  {
        bool flag = accounts[_blacklistAddress].deListed;
        require(!flag,"This account is delisted!");
        require(_blacklistAddress !=bankManager, "Warning: you're adding manager's address." );
        blacklisedAddresses[_blacklistAddress] = _status;
        if(blacklisedAddresses[_blacklistAddress] == true && _status == false)
        {
            blacklisedAddresses[_blacklistAddress] = false;
        }

     /*   if(_status==true){
            return _msg= "Client added to blacklist";
        }
        else{
            return _msg= "Client removed to blacklist";
        }*/
    }
    //function MakeBlackToWhite(address _blacklistAddress) public
    function DelistClient(address _clientAddress) public override onlyBankManager payable{
        accounts[_clientAddress].deListed = true;   
        uint amount = accounts[_clientAddress].amount;
        deListClient.transfer(amount);
        accounts[_clientAddress].amount -= amount;
        DelisedAddresses[_clientAddress] = true;
        //accounts[_clientAddress].accountAddress = address(0);

    }
    function DelistedAccounts(address accountAddress) public override view returns(bool){
        return DelisedAddresses[accountAddress];
    }
    function BlacklistedAccounts(address accountAddress) public override view returns(bool){
        return blacklisedAddresses[accountAddress];
    }
    function LockDepositOfClient(address _clientAddress) override public onlyBankManager{
        accounts[_clientAddress].lockDeposit = true;   
    }
    function UnLockDepositOfClient(address _clientAddress) override public onlyBankManager{
        accounts[_clientAddress].lockDeposit = false;
    }
}