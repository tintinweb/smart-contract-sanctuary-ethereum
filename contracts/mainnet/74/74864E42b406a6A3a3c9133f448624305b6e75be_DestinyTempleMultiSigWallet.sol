/**
 *Submitted for verification at Etherscan.io on 2022-12-17
*/

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
    /*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Welcome to Destiny.<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

    88888888ba,                                    88                            
    88      `"8b                            ,d     ""                            
    88        `8b                           88                                   
    88         88   ,adPPYba,  ,adPPYba,  MM88MMM  88  8b,dPPYba,   8b       d8  
    88         88  a8P_____88  I8[    ""    88     88  88P'   `"8a  `8b     d8'  
    88         8P  8PP"""""""   `"Y8ba,     88     88  88       88   `8b   d8'   
    88      .a8P   "8b,   ,aa  aa    ]8I    88,    88  88       88    `8b,d8'    
    88888888Y"'     `"Ybbd8"'  `"YbbdP"'    "Y888  88  88       88      Y88'     
                                                                        d8'      
                                                                    d8'       
    >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Good luck.<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*//*

    ______  ___        ___________ _____ _____________                  ___       __        ____________      _____ 
    ___   |/  /____  _____  /__  /____(_)__  ___/___(_)_______ _        __ |     / /______ ____  /___  /_____ __  /_
    __  /|_/ / _  / / /__  / _  __/__  / _____ \ __  / __  __ `/__________ | /| / / _  __ `/__  / __  / _  _ \_  __/
    _  /  / /  / /_/ / _  /  / /_  _  /  ____/ / _  /  _  /_/ / _/_____/__ |/ |/ /  / /_/ / _  /  _  /  /  __// /_  
    /_/  /_/   \__,_/  /_/   \__/  /_/   /____/  /_/   _\__, /          ____/|__/   \__,_/  /_/   /_/   \___/ \__/  
                                                    /____/                                                       
    /*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
    /*
    * SPDX-License-Identifier: MIT
    */
    pragma solidity ^0.8.10;

    interface Token { function transfer(address to, uint256 value) external returns (bool); }

    contract DestinyTempleMultiSigWallet {
    /*
    *@dev Public events>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    */
        event OwnerAddition(address indexed owner);
        event OwnerRemoval(address indexed owner);
        event RequirementChange(uint required);
        event SetSignature(string signature);
        event Log(string LogString);
    /*
    *@dev Transaction events>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    */
        event Deposit(address indexed sender, uint amount, uint balance);

        event SubmitTransaction
        (
            address indexed msgSender,
            uint indexed transactionID,
            address indexed to,
            Transaction transaction,
            string signature
        );
        event ConfirmTransaction(address indexed msgSender, uint indexed transactionID);
        event RevokeConfirmation(address indexed msgSender, uint indexed transactionID);
        event ExecuteTransaction(address indexed msgSender, uint indexed transactionID);
        event TokenTransfer(address indexed msgSender, uint indexed transactionID,address contractAddress,uint transferTokenAmount);

    /*
    *@dev Transaction enums>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    */
        /*
        *Special transaction type:
        *--"0"--Ordinary transaction
        *--"1"--Add owner
        *--"2"--Remove owner
        *--"3"--Modify owner
        *--"4"--Modify the signature
        *--"5"--Modify the minimum number of confirmations
        *--"6"--Contract self-destruct
        */
        enum Transactiontype{
            Transaction,
            AddOwner,
            RemoveOwner,
            ReplaceOwner,
            setSignature,
            ChangeRequirement,
            SelfDestruct
        }
        /*
        *Transaction realization method
        *--"0"--call();
        *--"1"--send();
        *--"2"--transfer();
        */
        enum TransactionMethod{
            Call,
            Send,
            Transfer
        }
    /*
    *@dev Transaction struct>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    */
    /*
        *Transaction struct:
        *
        *   address to;----receiving address.
        *   uint value;----Amount of coins sent.
        *   bytes data;----The data provided for the .call(data) method.
        *   string message;----User defined message.
        *
        *   TransactionMethod txMethod;----TransactionMethod(.call(),.send(),.transfer()).
        *
        *   address contractAddress;----Token contractAddress.
        *   uint transferTokenAmount;----TransferTokenAmount.
        *   bool executed;----Transaction Execution Status.
        *   uint numConfirmations;----Transaction numConfirmations.
        *
        *   Transactiontype specialTransaction;----Transaction Type.
        *
        */
        struct Transaction {
            address to;
            uint value;
            bytes data;
            string message;

            TransactionMethod txMethod;

            address contractAddress;
            uint transferTokenAmount;
            bool executed;
            uint numConfirmations;

            Transactiontype specialTransaction;

        }
        /*
    *@dev Public variables>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    */
        string public signature="destinytemple.eth";
        /*
        *  Constants
        */
        uint constant public MAX_OWNER_COUNT = 49;

        address[]  public  owners;

        mapping(address => bool) public isOwner;

        uint public numConfirmationsRequired;
    /*
    *@dev Transaction variables>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    */
        mapping(uint => mapping(address => bool)) public isConfirmed;

        Transaction[] public transactions;
    /*
    *@dev Public modifiers>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    */
        modifier onlyOwner() {
            require(isOwner[msg.sender], "msg.sender not owne.r");
            _;
        }

        modifier ownerDoesNotExist(address owner) {
            require(!isOwner[owner],"owner already exist.");
            _;
        }

        modifier ownerExists(address owner) {
            require(isOwner[owner],"owner does not exist.");
            _;
        }

        modifier ownerValid(address owner) {
            require(owner != address(0),"owner cannot be zero address");
            require(owner != address(this),"owner cannot be this contract address.");
            _;
        }

        modifier validRequirement(uint ownerCount, uint _required) {
            require(ownerCount <= MAX_OWNER_COUNT
                && _required <= ownerCount
                && _required != 0
                && ownerCount != 0,
                "Requirement not valid."
                );
            _;
        }
    /*
    *@dev Transaction modifiers>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    */
        modifier txExists(uint _txIndex) {
            require(_txIndex < transactions.length, "transaction does not exist");
            _;
        }

        modifier notExecuted(uint _txIndex) {
            require(!transactions[_txIndex].executed, "transaction already executed");
            _;
        }

        modifier notConfirmed(uint _txIndex) {
            require(!isConfirmed[_txIndex][msg.sender], "msg.sender already confirmed this transaction");
            _;
        }

        modifier confirmed(uint _txIndex) {
            require(isConfirmed[_txIndex][msg.sender], "msg.sender not confirm this transaction");
            _;
        }

        modifier canExecuted(uint _txIndex) {
            require(transactions[_txIndex].numConfirmations>=numConfirmationsRequired, "The number of transaction confirmations is less than the minimum number of confirmations");
            _;
        }

        modifier _toNotisZeroAddress(address _to) {
            require(_to != address(0), "Cannot transaction to zero address.");
            _;
        }

    /*
    *@dev Contract constructor and receive functions>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    */
        constructor (address[] memory _owners, uint _numConfirmationsRequired) payable{
            require(_owners.length > 0, "owners required");
            require(
                _numConfirmationsRequired > 0 &&
                    _numConfirmationsRequired <= _owners.length,
                "invalid number of required confirmations"
            );

            for (uint i = 0; i < _owners.length; i++) {
                address owner = _owners[i];

                require(owner != address(0), "invalid owner");
                require(!isOwner[owner], "owner not unique");

                isOwner[owner] = true;
                owners.push(owner);
            }

            numConfirmationsRequired = _numConfirmationsRequired;
        }

        receive() external payable {
            emit Log("Using function receive");
            emit Deposit(msg.sender, msg.value, address(this).balance);
        }

    /*
    *@dev Public view function>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    */
        function getOwners() public view returns (address[] memory) {
            return owners;
        }
    /*
    *@dev Transaction view function>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    */
        function getTransactionCount() public view returns (uint) {
            return transactions.length;
        }

        function getTransaction(uint _txIndex)
        public
        view
        returns (
            address to,
            uint value,
            bytes memory data,
            string memory message,

            TransactionMethod txMethod,

            address contractAddress,
            uint transferTokenAmount,
            bool executed,
            uint numConfirmations,

            Transactiontype specialTransaction,

            string memory _signature
        )
        {
        Transaction storage transaction = transactions[_txIndex];

            return (
                transaction.to,
                transaction.value,
                transaction.data,
                transaction.message,
                transaction.txMethod,
                transaction.contractAddress,
                transaction.transferTokenAmount,
                transaction.executed,
                transaction.numConfirmations,
                transaction.specialTransaction,
                signature
            );
        }

    /*
    *@dev Public submit specialTransaction functions>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    */
        /*
        *Submit addOwner() specialTransaction
        *
        *   transactions.push(
        *        Transaction({
        *            specialTransaction: Transactiontype.addOwner
        *        })
        *   );
        */
        function addOwner(address _newOwner) 
            public 
            onlyOwner 
            ownerDoesNotExist(_newOwner)
            ownerValid(_newOwner)
            validRequirement(owners.length + 1, numConfirmationsRequired)
            returns(bool addOwnerSubmitted)
        {
            emit Log("Using function addOwner");

            uint _value = 0;
            bytes memory _data = "addOwner";

            submitTransaction(_newOwner, _value, _data, "addOwner", TransactionMethod.Call, address(this), 0, Transactiontype.AddOwner);

            return true;
        }
        /*
        *Submit RemoveOwner() specialTransaction
        *
        *   transactions.push(
        *        Transaction({
        *            specialTransaction: Transactiontype.RemoveOwner
        *        })
        *);
        */
        function removeOwner(address _owner)
            public
            onlyOwner
            ownerExists(_owner)
            returns(bool removeOwnerSubmitted)
        {
            emit Log("Using function removeOwner");

            uint _value = 0;
            bytes memory _data = "removeOwner";

            submitTransaction(_owner, _value, _data, "removeOwner", TransactionMethod.Call, address(this), 0, Transactiontype.RemoveOwner);

            return true;
        }
        /*
        *Submit replaceOwner() specialTransaction
        *
        *   transactions.push(
        *        Transaction({
        *            specialTransaction: Transactiontype.ReplaceOwner
        *        })
        *);
        */
        function replaceOwner(
            address _owner,
            address _newOwner
        ) 
            public 
            onlyOwner 
            ownerValid(_newOwner)
            ownerExists(_owner)
            ownerDoesNotExist(_newOwner)
            returns(bool replaceOwnerSubmitted)
        {
            emit Log("Using function replaceOwner");

            uint _value = 0;
            bytes memory _data = "replaceOwner";

            submitTransaction(_owner, _value, _data, "replaceOwner", TransactionMethod.Call, _newOwner, 0, Transactiontype.ReplaceOwner);

            return true;
        }
        /*
        *Submit setSignature() specialTransaction
        *
        *   transactions.push(
        *        Transaction({
        *            specialTransaction: Transactiontype.setSignature
        *        })
        *);
        */
        function setSignature( string memory _newsetSignature ) 
            public 
            onlyOwner 
            returns(bool setSignatureSubmitted)
        {
            emit Log("Using function setSignature");

            uint _value = 0;
            address _to=address(this);
            bytes memory _data = "setSignature";

            submitTransaction(_to, _value, _data, _newsetSignature, TransactionMethod.Call, address(this), 0, Transactiontype.setSignature);

            return true;
        }
        /*
        *Submit changeRequirement() specialTransaction
        *
        *   transactions.push(
        *        Transaction({
        *            specialTransaction: Transactiontype.changeRequirement
        *        })
        *);
        */
        function changeRequirement( uint _newRequirement )
            public
            onlyOwner 
            validRequirement(owners.length, _newRequirement)
            returns(bool changeRequirementSubmitted)
        {
            emit Log("Using function changeRequirement");
            address _to=address(this);
            bytes memory _data = "changeRequirement";

            submitTransaction(_to, _newRequirement, _data, "changeRequirement", TransactionMethod.Call, address(this), 0, Transactiontype.ChangeRequirement);

            return true;
        }
        /*
        *Submit selfDestruct() specialTransaction
        *
        *   transactions.push(
        *        Transaction({
        *            specialTransaction: Transactiontype.selfDestruct
        *        })
        *);
        */
        function selfDestruct(
            address _ultimateBeneficiaryAddress
        ) 
            public
            onlyOwner
            _toNotisZeroAddress(_ultimateBeneficiaryAddress) 
            returns (bool selfDestructSubmitted)
        {

            emit Log("Using function selfDestruct");
            uint _value = 0;
            bytes memory _data = "The sky is so blue, the blue seems to be unable to accommodate a trace of other colors.";

            submitTransaction(_ultimateBeneficiaryAddress, _value, _data, "End of story", TransactionMethod.Call, address(this), 0, Transactiontype.SelfDestruct);

            return true;
        }
    /*
    *@dev Internal execute functions>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    */

        /// @dev Allows to add a new owner. Transaction requires (numConfirmationsRequired) owner confirmations
        /// @param owner Address of new owner.
        function executeAddOwner(address owner)
            internal
            returns(bool)
        {
            emit Log("Using function executeAddOwner");

            isOwner[owner] = true;
            owners.push(owner);

            emit OwnerAddition(owner);

            return true;
        }

        /// @dev Allows to remove an owner. Transaction requires (numConfirmationsRequired) owner confirmations
        /// @param owner Address of owner.
        function executeRemoveOwner(address owner)
            internal
            returns(bool)
        {
            emit Log("Using function executeRemoveOwner");

            isOwner[owner] = false;

            if(owners[owners.length-1] == owner){
                owners.pop();
            }else{
                for (uint i=0; i<owners.length - 1; i++){
                    if (owners[i] == owner) {
                        owners[i] = owners[owners.length - 1];
                        owners.pop();
                        break;
                    }
                }
            }

            emit OwnerRemoval(owner);

            if (numConfirmationsRequired > owners.length){
                executeChangeRequirement(owners.length);
            }

            return true;
        }

        /// @dev Allows to replace an owner with a new owner. Transaction requires (numConfirmationsRequired) owner confirmations
        /// @param owner Address of owner to be replaced.
        /// @param newOwner Address of new owner.
        function executeReplaceOwner(address owner, address newOwner)
            internal
            returns(bool)
        {
            emit Log("Using function executeReplaceOwner");

            if(owners[owners.length-1] == owner){
                owners[owners.length-1] = newOwner;  
            }else {

                for (uint i=0; i<owners.length-1; i++){
                    if (owners[i] == owner) {
                        owners[i] = newOwner;
                        break;
                    }
                }
                
            }

            isOwner[owner] = false;
            isOwner[newOwner] = true;

            emit OwnerRemoval(owner);
            emit OwnerAddition(newOwner);

            return true;
        }
        /// @dev Allows to replace signature with new signature. Transaction requires (numConfirmationsRequired) owner confirmations
        /// @param newsignature of new signature.
        function executeSetSignature(string memory newsignature) 
            internal 
            returns(bool) 
        {
            emit Log("Using function executeSetSignature");

            signature = newsignature;

            emit SetSignature(newsignature);

            return true;
        }

        /// @dev Allows to change the number of required confirmations. Transaction requires (numConfirmationsRequired) owner confirmations
        /// @param _required Number of required confirmations.
        function executeChangeRequirement(uint _required)
            internal
            returns(bool)
        {
            emit Log("Using function executeChangeRequirement");

            numConfirmationsRequired = _required;

            emit RequirementChange(_required);

            return true;
        }
        /// @dev Allows to contract execute selfdestruct. Transaction requires (numConfirmationsRequired) owner confirmations
        /// @param _ultimateBeneficiaryAddress. The address of the ultimate beneficiary who receives the main currency of the contract self destruct.
        function executeSelfDestruct(address _ultimateBeneficiaryAddress)
            internal
        {
            emit Log("Using function executeSelfDestruct");

            selfdestruct(payable(_ultimateBeneficiaryAddress));
        }

    /*
    *@dev Transaction functions>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    */
        /*
        *Call the submitTransaction method to submit a general transaction.
        *And Set Transactiontype to Transaction.
        *
        *    submitTransaction(_to, _value, _data, _message, _txMethod, _contractAddress, _transferTokenAmount, Transactiontype.Transaction);
        *
        */
        function _submitTransaction(
            address _to,
            uint _value,
            bytes memory _data,
            string memory _message,
            TransactionMethod _txMethod,
            address _contractAddress,
            uint _transferTokenAmount
        ) 
        public
        onlyOwner 
        _toNotisZeroAddress(_to)
        returns(uint transactionId)
        {
            emit Log("Using function _submitTransaction");

            uint txIndex = transactions.length;

            submitTransaction(_to, _value, _data, _message, _txMethod, _contractAddress, _transferTokenAmount, Transactiontype.Transaction);

            return txIndex;
        }

        /*
        *Submit transactions, including general transactions and special transactions.
        *and automatically confirm this transaction for msg.sender.
        *
        *   transactions.push(
        *       Transaction({
        *           specialTransaction: _specialTransaction
        *       })
        *   );
        *
        *   confirmTransaction(txIndex);
        *
        */

        function submitTransaction(
            address _to,
            uint _value,
            bytes memory _data,
            string memory _message,
            TransactionMethod _txMethod,
            address _contractAddress,
            uint _transferTokenAmount,
            Transactiontype _specialTransaction
        ) 
        internal
        onlyOwner 
        _toNotisZeroAddress(_to)
        returns(uint transactionId)
        {
            emit Log("Using function submitTransaction");
            
            uint txIndex = transactions.length;

            transactions.push(
                Transaction({
                    to: _to,
                    value: _value,
                    data: _data,
                    message: _message,
                    txMethod: _txMethod,
                    contractAddress: _contractAddress,
                    transferTokenAmount: _transferTokenAmount,
                    executed: false,
                    numConfirmations: 0,
                    specialTransaction: _specialTransaction
                })
            );

            emit SubmitTransaction(msg.sender, txIndex, _to, transactions[txIndex],signature);

           _confirmTransaction(txIndex);

            return txIndex;
        }

        /*
        *Confirm (_txIndex) transaction for msg.sender,
        *
        *   transaction.numConfirmations += 1;
        *
        *   isConfirmed[_txIndex][msg.sender] = true;
        *
        *And if the number of confirmations of this transaction is greater than or equal to the minimum number of confirmations,
        *the transaction will be executed automatically.
        *
        *   if(transactions[_txIndex].numConfirmations >= numConfirmationsRequired){
        *        executeTransaction(_txIndex);
        *    }
        *
        */
        function _confirmTransaction(uint _txIndex)
            public
            onlyOwner
            txExists(_txIndex)
            notExecuted(_txIndex)
            notConfirmed(_txIndex)
            _toNotisZeroAddress(transactions[_txIndex].to)
            returns(bool transactionConfirmed)
        {
            emit Log("Using function confirmTransaction");

            Transaction storage transaction = transactions[_txIndex];

            transaction.numConfirmations += 1;

            isConfirmed[_txIndex][msg.sender] = true;

            emit ConfirmTransaction(msg.sender, _txIndex);

            if(transactions[_txIndex].numConfirmations >= numConfirmationsRequired){
                _executeTransaction(_txIndex);
            }

            return isConfirmed[_txIndex][msg.sender];
        }
        /*
        *Unconfirm transaction (_txIndex) for msg.sender
        *
        *   transaction.numConfirmations -= 1;
        *
        *   isConfirmed[_txIndex][msg.sender] = false;
        *
        */
        function _revokeConfirmation(uint _txIndex)
            public
            onlyOwner
            txExists(_txIndex)
            notExecuted(_txIndex)
            confirmed(_txIndex)
            returns(bool transctionRevokeConfirmed)
        {
            emit Log("Using function revokeConfirmation");

            Transaction storage transaction = transactions[_txIndex];

            transaction.numConfirmations -= 1;

            isConfirmed[_txIndex][msg.sender] = false;

            emit RevokeConfirmation(msg.sender, _txIndex);

            return !isConfirmed[_txIndex][msg.sender];
        }
        /*
        *   If transactions(_txIndex) satisfied (txExists,notExecuted,canExecuted){
        *       Execute this Transaction
        *   }
        */
        function _executeTransaction(uint _txIndex)
            public
            onlyOwner
            txExists(_txIndex)
            _toNotisZeroAddress(transactions[_txIndex].to)
            notExecuted(_txIndex)
            canExecuted(_txIndex)
            returns(bool transactionExecuted)
        {
            emit Log("Using function executeTransaction");

            Transaction storage transaction = transactions[_txIndex];
            /*
            *Determine the transaction type and use the corresponding method to execute the transaction
            *   if(transaction.specialTransaction == Transactiontype.enum)
            */
            bool success;
            if (transaction.specialTransaction == Transactiontype.Transaction){
                /*
                *If it is a general transaction
                *   Determine the transaction txMethod and use the corresponding method to execute the transaction
                *       if(transaction.txMethod == TransactionMethod.enum)
                */
                if (transaction.txMethod == TransactionMethod.Call){
                    success = usingCallExecuteTransaction(_txIndex);
                }
                else 
                if(transaction.txMethod == TransactionMethod.Send){
                    success = usingSendExecuteTransaction(_txIndex);
                }
                else 
                if(transaction.txMethod == TransactionMethod.Transfer){
                    success = usingTransferExecuteTransaction(_txIndex);
                }
                
            }else {
                if(transaction.specialTransaction == Transactiontype.AddOwner){
                    success = executeAddOwner(transaction.to);
                }
                else 
                if(transaction.specialTransaction == Transactiontype.RemoveOwner){
                    success = executeRemoveOwner(transaction.to);
                }
                else 
                if(transaction.specialTransaction == Transactiontype.ReplaceOwner){
                    success = executeReplaceOwner(transaction.to,transaction.contractAddress);
                }
                else 
                if(transaction.specialTransaction == Transactiontype.setSignature){
                    success = executeSetSignature(transaction.message);
                }
                else 
                if(transaction.specialTransaction == Transactiontype.ChangeRequirement){
                    success = executeChangeRequirement(transaction.value);
                }
                else 
                if(transaction.specialTransaction == Transactiontype.SelfDestruct){
                    executeSelfDestruct(transaction.to);
                }
                else{
                    require(false,"Function _executeTransaction----invalid transaction.specialTransaction or transaction.txMethod");
                } 
            }

            transaction.executed = true;
            
            emit ExecuteTransaction(msg.sender, _txIndex);

            return success;
        }
    /*
    *@dev Transaction execute functions>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    */
        /*
        *Send the value amount of main currency to an address through call(value).
        *If the target is a contract address, call the contract through call(data).
        *
        *If you want to transfer tokens,
        *please call(value) to (token contract address) (the general quantity is 0) 
        *And call the transfer method of the contract in call(data)
        */
        function usingCallExecuteTransaction(uint _txIndex)
            internal
            returns(bool callExecuted)
        {
            emit Log("Using function usingCallExecuteTransaction");

            Transaction storage transaction = transactions[_txIndex];

            (bool success, ) = transaction.to.call{value: transaction.value}(
                transaction.data
            );

            require(success, "Function usingCallExecuteTransaction:----Execute transaction.to.call{value: transaction.value}(transaction.data; error.");

            return success;
        }
        /*
        *Determine whether to perform token transfer
        *
        *   if (transaction_ContractAddress!=address(this) && transaction_TransferTokenAmount!=0){
        *
        */
        function needExecuteTokenTransfer(
            address transaction_ContractAddress,
            uint transaction_TransferTokenAmount
        )
            internal  
            returns(bool)        
        {
            emit Log("Using function needExecuteTokenTransfer");

            if(transaction_TransferTokenAmount != 0
                &&transaction_ContractAddress!=address(this)
                &&transaction_ContractAddress!=address(0)
            ){
                return true;
            }
            return false;
        }

        /*
        *Send (value) main currency to the _to address through the .send(value) method,
        *
        *If needExecuteTokenTransfer
        *Using the executeTokenTransfer method to transfer the token of (transaction.transferTokenAmount) to the _to address.
        *
        */
        function usingSendExecuteTransaction(uint _txIndex)
            internal
            returns(bool sendExecuted)
        {
            emit Log("Using function usingSendExecuteTransaction");

            Transaction storage transaction = transactions[_txIndex];

            if(needExecuteTokenTransfer(transaction.contractAddress,transaction.transferTokenAmount)){
                executeTokenTransfer(_txIndex);
            }

            address payable _to=payable(transaction.to);

            bool success= _to.send(transaction.value);

            require(success, "Function usingSendExecuteTransaction:----Execute transaction.to.send(transaction.value); error.");

            return success;
        }

        /*
        *Send (value) the main currency to the _to address through the .transfer(value) method,
        *
        *If needExecuteTokenTransfer
        *Using the executeTokenTransfer method to transfer the token of (transaction.transferTokenAmount) to the _to address.
        *
        */
        function usingTransferExecuteTransaction(uint _txIndex)
            internal
            returns(bool transferExecuted)
        {
            emit Log("Using function usingTransferExecuteTransaction");

            Transaction storage transaction = transactions[_txIndex];

            if(needExecuteTokenTransfer(transaction.contractAddress,transaction.transferTokenAmount)){
                executeTokenTransfer(_txIndex);
            }

            address payable _to=payable(transaction.to);

            _to.transfer(transaction.value);

            return true;
        }

        /*
        *Using the transfer method of (transaction.contractAddress) to transfer the token of (transaction.transferTokenAmount) to the _to address.
        */
        function executeTokenTransfer(uint _txIndex)
            internal
            returns(bool)
        {
            emit Log("Using function executeTokenTransfer");

            Transaction storage transaction = transactions[_txIndex];

            Token tokenContract = Token(transaction.contractAddress);
            
            bool success =tokenContract.transfer(transaction.to, transaction.transferTokenAmount);

            require(success, "Function executeTokenTransfer:----Execute tokenContract.transfer(transaction.to, transaction.transferTokenAmount); error.");

            emit TokenTransfer(msg.sender, _txIndex,transaction.contractAddress,transaction.transferTokenAmount);

            return success;
        }

    }
    /*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
    /*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Welcome to Destiny.<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

    88888888ba,                                    88                            
    88      `"8b                            ,d     ""                            
    88        `8b                           88                                   
    88         88   ,adPPYba,  ,adPPYba,  MM88MMM  88  8b,dPPYba,   8b       d8  
    88         88  a8P_____88  I8[    ""    88     88  88P'   `"8a  `8b     d8'  
    88         8P  8PP"""""""   `"Y8ba,     88     88  88       88   `8b   d8'   
    88      .a8P   "8b,   ,aa  aa    ]8I    88,    88  88       88    `8b,d8'    
    88888888Y"'     `"Ybbd8"'  `"YbbdP"'    "Y888  88  88       88      Y88'     
                                                                        d8'      
                                                                    d8'       
    >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Good luck.<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*//*

    ______  ___        ___________ _____ _____________                  ___       __        ____________      _____ 
    ___   |/  /____  _____  /__  /____(_)__  ___/___(_)_______ _        __ |     / /______ ____  /___  /_____ __  /_
    __  /|_/ / _  / / /__  / _  __/__  / _____ \ __  / __  __ `/__________ | /| / / _  __ `/__  / __  / _  _ \_  __/
    _  /  / /  / /_/ / _  /  / /_  _  /  ____/ / _  /  _  /_/ / _/_____/__ |/ |/ /  / /_/ / _  /  _  /  /  __// /_  
    /_/  /_/   \__,_/  /_/   \__/  /_/   /____/  /_/   _\__, /          ____/|__/   \__,_/  /_/   /_/   \___/ \__/  
                                                    /____/                                                       
    /*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/