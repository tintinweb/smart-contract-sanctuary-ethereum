/**
 *Submitted for verification at Etherscan.io on 2023-03-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract MultiSigWallet {

    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        bytes data
    );
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);

    address[] public owners;
    mapping(address => bool) public isOwner;

    uint256 public numConfirmationsRequired;

    uint256 public confirmationsForAddOwner;   
    uint256 public confirmationsForRemoveOwner;

   

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numConfirmations;
       
    }

   
    mapping(uint256 => mapping(address => bool)) public isConfirmed;
    mapping(address=>bool) public isConfirmedForAddOwner;
    mapping(address=>bool) public isConfirmedForRemoveOwner;
    mapping(address=>bool)  isExistOwner;

    

    mapping(uint256 => Transaction) public transactions;

    uint256 private totalTransaction;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint256 _txIndex) {
        require(transactions[_txIndex].value != 0, "tx does not exist");
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint256 _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    constructor(address[] memory _owners, uint256 _numConfirmationsRequired) {
        require(_owners.length > 0, "owners required");
        require(
            _numConfirmationsRequired > 0 &&
                _numConfirmationsRequired <= _owners.length,
            "invalid number of required confirmations"
        );

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
        
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function confirmForAddOwner() public onlyOwner{

        require(!isConfirmedForAddOwner[msg.sender],"Already confirmed for add owner");

        confirmationsForAddOwner = confirmationsForAddOwner +1;
        isConfirmedForAddOwner[msg.sender] = true;
    }

    function confirmForRemoveOwner() public onlyOwner{
        require(!isConfirmedForRemoveOwner[msg.sender],"Already confirmed for remove owner");

                confirmationsForRemoveOwner = confirmationsForRemoveOwner +1;
                isConfirmedForRemoveOwner[msg.sender] = true;



    }


    function addNewOwner(
        address _owner
        ) public
          onlyOwner 
          {
              require(confirmationsForAddOwner == numConfirmationsRequired,"Confirm from all owner:Confirmation required for add new owner");
              require(!isExistOwner[msg.sender],"Already exist owner ");
              require(!isOwner[_owner],"Already owner ");

              owners.push(_owner);
              numConfirmationsRequired = numConfirmationsRequired +1;
              isExistOwner[msg.sender] = true;
              isOwner[_owner] = true;
          }

    function removeOwner(
        uint256 _ownerIndex
        )  public
           onlyOwner 
           {
            require(confirmationsForRemoveOwner == numConfirmationsRequired,"Confirm from all owner:Confirmation required for remove old owner");

               //Transaction storage transaction = transactions[_ownerIndex];

               //require(transaction.numConfirmations==confirmationsRequiredOwner,"");

               owners[_ownerIndex] = owners[owners.length -1];
               owners.pop();

                //isOwner[ owners[_ownerIndex]] = false;

               numConfirmationsRequired = numConfirmationsRequired -1;
               confirmationsForRemoveOwner = confirmationsForRemoveOwner -1;
                
               if(confirmationsForAddOwner != 0){
                    confirmationsForAddOwner = confirmationsForAddOwner -1;
                }
               
           }

    function submitTransaction(
        address _to,
        uint256 _value,
        bytes memory _data
    ) public  {

        require(_to != address(0),"address should not be zero address");
        require(_value > 0,"Value should not be zero");
        require(_data.length != 0,"data of bytes should not be zero");
        
        uint256 txIndex = totalTransaction+1 ;


        transactions[txIndex].to = _to;
        transactions[txIndex].value = _value;
        transactions[txIndex].data= _data;
        transactions[txIndex].executed = false;
        transactions[txIndex].numConfirmations = 0;

        

        // transactions.push(
        //     Transaction({
        //         to: _to,
        //         value: _value,
        //         data: _data,
        //         executed: false,
        //         numConfirmations: 0
        //     })
        // );

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    function confirmTransaction(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }


    function executeTransaction(uint256 _txIndex)
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

        // (bool success , ) = transaction.to.call{value: transaction.value}(
        //     transaction.data
        // );
        // require(success, "tx failed");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    // function getOwners() public view returns (address[] memory) {
    //     return owners;
    // }

    // function getTransactionCount() public view returns (uint256) {
    //     return totalTransaction;
    // }

    // function getTransaction(uint256 _txIndex)
    //     public
    //     view
    //     returns (
    //         address to,
    //         uint256 value,
    //         bytes memory data,
    //         bool executed,
    //         uint256 numConfirmations
    //     )
    // {
    //     Transaction storage transaction = transactions[_txIndex];

    //     return (
    //         transaction.to,
    //         transaction.value,
    //         transaction.data,
    //         transaction.executed,
    //         transaction.numConfirmations
    //     );
    // }
}