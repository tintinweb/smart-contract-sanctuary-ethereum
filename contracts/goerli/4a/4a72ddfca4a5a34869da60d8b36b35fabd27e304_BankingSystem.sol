/**
 *Submitted for verification at Etherscan.io on 2022-12-09
*/

// SPDX-License-Identifier: MIT
// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// File: contracts/BankingSystem.sol


pragma solidity >=0.8.0 <0.9.0;


//sample owners: ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4","0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2","0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db"],2
error notOwnerError(string notOwnerMsg);
error ethExceed(string ethExceedMsg);
error accessError(string bankAccessMsg);
error loggedOutError(string loggedOutMessage);
error receiverError(string receiverAccessMsg);


contract BankingSystem {
    uint256 public ethAmountInUsd;
    uint256 public sendUsd;
    uint256 amountInUsd = 1_000_000;
    // uint256 public constant minimumUsd = 2 * 1e18;
    string notOwnerMsg = "You are not one of the owner of this contract";
    string ethExceedMsg = "Withdrawal limit exceeded. Please proceed to submit transaction.";
    uint public numConfirmationsRequired;
    uint time;
    string bankAccessMsg = "You don't have access to the bank. Please enroll first.";
    string loggedOutMessage = "You don't have access to the bank. Please log in first.";
    string receiverAccessMsg = "Receiver address is not yet enrolled. Please enroll first.";
    uint timeStamp;

    address[] public owners;
    mapping(address => bool) public isOwner;
    mapping(address => uint256) public userEthBalance;
    mapping(address => uint256) public userUsdBalance;
    mapping(uint => mapping(address => bool)) public isConfirmed;
    mapping(address => bool) enrolledAddresses; 
    mapping(address => bool) accessValid;

    struct Transaction {
        address to;
        uint value;
        bool executed;
        uint numConfirmations;
    }

    Transaction[] public transactions;
  
    constructor(address[] memory _owners, uint _numConfirmationsRequired) {
        require(_owners.length > 0, "owners required");
        require(
            _numConfirmationsRequired > 0 &&
                _numConfirmationsRequired <= _owners.length,
            "invalid number of required confirmations"
        );

    for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            enrolledAddresses[owner] = true;
            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
            
        }
        numConfirmationsRequired = _numConfirmationsRequired;
    }

    receive() external payable {
        emit eventDeposit(msg.sender, block.timestamp, msg.value, address(this).balance);
    }

    fallback() external payable {
    }

    modifier onlyOwner {
        if(!isOwner[msg.sender]) {
            revert notOwnerError(notOwnerMsg);
        }
        _;
    }

    modifier grantAccess {
        if(!enrolledAddresses[msg.sender] ) {   
            revert accessError(bankAccessMsg);
        }
        _;
    }

    modifier loginFirst {
        if(!accessValid[msg.sender] ) {   
            revert loggedOutError(loggedOutMessage);
        }
        _;
    }

    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }


    // Events
    event eventDeposit (
        address indexed sender,
        uint256 indexed dateDeposit,
        uint256 indexed amount,
        uint balance
    );

    event eventWithdraw (
        uint256 indexed dateWithdraw,
        uint256 indexed amount
    );

    event eventTransfer (
        uint256 indexed dateTransfer,
        uint256 indexed amount
    );

    event eventSubmitTransaction(
        address indexed owner,
        uint indexed txIndex,
        address indexed to,
        uint value
    );

    event eventConfirmTransaction(
        address indexed owner, uint indexed txIndex
    );

    event eventRevokeConfirmation(
        address indexed owner, uint indexed txIndex
    );

    event eventExecuteTransaction(
        address indexed owner, uint indexed txIndex
    );


    // Owners
    function getOwners() public view returns(address[] memory) {
        return owners;
    }

    // Deposit
    function deposit() public payable grantAccess loginFirst {
        // require(getConversionRate(msg.value) >= minimumUsd, "Didn't send enough!");
        require(msg.value >= 1 ether , "Please deposit at least 1 ether."); 
        //0.014 eth = 14_000_000 gwei = Php1000
        userEthBalance[msg.sender] += msg.value;
        
        emit eventDeposit(msg.sender, block.timestamp, msg.value, address(this).balance);
    }

    // Withdraw
    function withdraw(uint256 _amount) public payable grantAccess loginFirst {
        require (userEthBalance[msg.sender] >= _amount * 1e18, "Insufficient Funds!");
        // 0.36 eth = 360_000_000 gwei = Php25,000
        if ( _amount * 1e18 >= 2 * 1e18 ) {
           revert ethExceed(ethExceedMsg);
        }
        else {
        userEthBalance[msg.sender] -= _amount * 1e18;
        
        (bool sent,) = msg.sender.call{value: _amount * 1e18}("sent!");
        require(sent, "Failed to complete!");
        }

        emit eventWithdraw(block.timestamp, _amount);
    }

    function withdrawFunds(uint256 _amount) public payable onlyOwner loginFirst {
        (bool sent,) = msg.sender.call{value: _amount * 1e18}("sent!");
        require(sent, "Failed to complete!");

        emit eventWithdraw(block.timestamp, _amount);
    }

    // Balance
    function getUserBalance() public view returns (uint256) {
        return userEthBalance[msg.sender];
    }

    function getAdminBalance() public view onlyOwner returns(uint256) {
        return address(this).balance;
    }

    // Transfer
    function transferEth(address _receiver, uint256 _amount) public grantAccess loginFirst {
        userEthBalance[msg.sender] -= _amount * 1e18;
        if(!enrolledAddresses[_receiver] ) {   
            revert receiverError(receiverAccessMsg);
        }
        else{
            userEthBalance[_receiver] += _amount * 1e18;
        }
        
        emit eventTransfer(block.timestamp, _amount);
    }
    
    // For exchange currency function
    function getPrice() public view returns(uint256) {
        // Goerli ETH/USD Address
        // 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        (,int256 price,,,) = priceFeed.latestRoundData();
        // ETH in terms of USD
        return uint256(price * 1e10);
    }

    function getConversionRate(uint256 ethAmount) public returns (uint256) {
        uint256 ethPrice = getPrice();
        // 3000_000000000000000000 = ETH / USD price
        // 1_000000000000000000 ETH
        ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        // 3000
        return ethAmountInUsd;
    }

    function usdAmount() public view returns(uint256) {
        return amountInUsd;
    }

    function exchangeCurrency(uint256 _amount) public payable grantAccess loginFirst returns(bool){
        require(_amount  >=  1 ether , "Minimum of 1 ether");
        userEthBalance[msg.sender] -= _amount;
        sendUsd = (_amount * ethAmountInUsd) / 1e18;
        amountInUsd -= sendUsd;
        userUsdBalance[msg.sender] += sendUsd;
        return true;
    }

    // Whitelist
    function enrollUser (address _addressToEnroll) public {   
        enrolledAddresses[_addressToEnroll] = true;
    }

    function removeUser (address _addressToRemove) public onlyOwner {
        enrolledAddresses[_addressToRemove] = false;
    }

    function verifyUserIfEnrolled(address _address) public view returns (bool) {  
        bool IsUserEnrolled = enrolledAddresses[_address];
        return IsUserEnrolled;
    }
    
    function accessBankInAndOut() public grantAccess { 
        if( accessValid[msg.sender] == true ) {
            accessValid[msg.sender] = false;
            timeStamp = block.timestamp;
        } else accessValid[msg.sender] = true;
            timeStamp = block.timestamp;
    }

    function isLoggedIn(address _address) public view returns (bool, uint256) {   
        return  (accessValid[_address], timeStamp); 
    }


    // **FOR MULTI-SIGNATURE**
    // SUBMIT
    function submitTransaction(
        address _to,
        uint _value
    ) public {
        uint txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value * 1e18,
                executed: false,
                numConfirmations: 0
            })
        );

        if(!enrolledAddresses[_to] ) {   
            revert receiverError(receiverAccessMsg);
        }

        emit eventSubmitTransaction(msg.sender, txIndex, _to, _value);
    }

    // CONFIRM
    function confirmTransaction(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit eventConfirmTransaction(msg.sender, _txIndex);
    }

    // EXECUTE
    function executeTransaction(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );

        transaction.executed = true;
        userEthBalance[transaction.to] -= transaction.value;

        (bool success, ) = transaction.to.call{value: transaction.value}("");
        require(success, "tx failed");

        emit eventExecuteTransaction(msg.sender, _txIndex);
    }

    // REVOKE
    function revokeConfirmation(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit eventRevokeConfirmation(msg.sender, _txIndex);
    }

    // TRANSACTION
    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    function getTransaction(uint _txIndex)
        public
        view
        returns (
            address to,
            uint value,
            bool executed,
            uint numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.executed,
            transaction.numConfirmations
        );
    }
}