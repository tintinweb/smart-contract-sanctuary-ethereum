// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Defining the contract interface wih the required function signatures
// As of now only transfer function in required
interface ERC20Interface{
    function transfer(address to, uint256 amount) external returns (bool);
}


//@dev: add function to view historic transactions by transaction id
//@dev: add _ before all internal function variables
//@dev: add a setter function to add/remove multisig-owners
//      Eventually multisig will be superseeded with a generalised governance contract
//      with stake based voting
contract MultiSig{

    // Defining events
    // Fired when tokens are deposited to this multisig wallet
    event Deposit(address indexed sender, uint amount);
    // Fired when a transaction is submitted, waiting for other owners to approve
    event Submit(uint indexed txnId);
    // Fired when an owner approves
    event Approve(address indexed owner, uint indexed txnId);
    // Fired when an owner revokes his approval
    event Revoke(address indexed owner, uint indexed txnId);
    // Fired when there are sufficient approvals for the contract to get executed
    event Execute(uint indexed txnId);

    // Transaction Description
    struct Transaction {
        // Address where the transaction is executed
        address to;
        // Amount of tokens sent tot he 'to' address
        uint value;
        // Data to be sent to the 'to' address
        bytes data;
        // Set to true when transaction is executed
        bool executed;
    }

    // Owners of multisig
    address[] public owners;
    mapping(address => bool) public isOwner;
    // Minimum approvals for transaction get executed
    uint public required;

    // List of all transactions submitted
    Transaction[] public transactions;
    // Mapping of vote/approval of each owner for each transaction
    mapping(uint => mapping(address => bool)) public approved;

    // Defining token interface variable to be used to interact with Token Contract
    ERC20Interface walletToken;
    // Defining modifier to allow only owners to execute certain functions
    modifier onlyOwner(){
        require(isOwner[msg.sender], "not owner");
        _;
    }

    // Modifier to check if the transaction exists
    modifier txExists(uint _txId){
        require(_txId<transactions.length, "tx does not exist");
        _;
    }

    // Modifier to check if the transaction is not already approved by msg.sender
    modifier notApproved(uint _txId){
        require(!approved[_txId][msg.sender], "tx already approved");
        _;
    }

    // Modifier to check if the transaction is not executed
    modifier notExecuted(uint _txId){
        require(!transactions[_txId].executed, "tx already executed");
        _;
    }

    constructor(address[] memory _owners, uint _required, address token_address){
        require(_owners.length > 0, "Owners required");
        require(_required > 0 && _required < _owners.length, "invalid required numer of owners");
        for(uint i = 0; i < _owners.length; i++){
            
            address owner = _owners[i];
            
            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }
        required = _required;
        // Initialising token contract
        walletToken = ERC20Interface(token_address);
        
    }


    // Fallback function to received sent ether
    // Needed only for multisig wallets which work on native tokens
    // Since we're using this to control another contract, contract payments are unnecessary
    // If contract payments are also to be enabled, another function has to be defined
    // for the transaction execution (transfer) of the local token
    receive() external payable{
        // Emit Deposit event
        emit Deposit(msg.sender, msg.value);
    }

    // Function to submit transactions to be reviewed
    function submit(address _to, uint _value, bytes calldata _data) external onlyOwner {

        /*
        transactions.push(Transaction{
            to: _to,
            value: _value,
            data: _data,
            executed: false
        });
        */

        transactions.push(Transaction(_to, _value, _data, false));

        emit Submit(transactions.length - 1);
    }


    // Function to approve submitted transaction
    function approve(uint _txId) external 
    onlyOwner 
    txExists(_txId) 
    notApproved(_txId) 
    notExecuted(_txId) {

        approved[_txId][msg.sender] = true;
        emit Approve(msg.sender, _txId);
    }


    // Function to get total approvals for a submitted transaction
    function _getApprovalCount(uint _txId) private view returns (uint) {    
        uint count = 0;
        for(uint i = 0; i < owners.length; i++){
            if(approved[_txId][owners[i]]){
                count+=1;
            }
        }
        return count;
    }

    // Function to execute submitted transaction
    function execute(uint _txId) external
    onlyOwner
    txExists(_txId)
    notExecuted(_txId) {
        require(_getApprovalCount(_txId) >= required, "Approvals less than required");
        Transaction storage transaction = transactions[_txId];
        transaction.executed = true;
        //(bool success,) = transaction.to.call{value: transaction.value}(
        //                                                transaction.data
        //                                            );
        bool success = walletToken.transfer(transaction.to, transaction.value);
        require(success, "tx failed");

        emit Execute(_txId);
    }

    // Function to revoke approval for a submitted transaction
    function revoke(uint _txId) external 
    onlyOwner 
    txExists(_txId) 
    notExecuted(_txId) {

        require(approved[_txId][msg.sender], "tx not Approved");
        approved[_txId][msg.sender] = false;
        emit Revoke(msg.sender, _txId);
    }

//##################################################################################


    // // View function to view owners
    // function owners_address() external view
    // returns(address[] memory addresses) {
    //     // Based on the following link (https://stackoverflow.com/questions/71819186/what-is-the-best-practice-of-copying-from-array-to-array-in-solidity)
    //     // Looping is more deploymeent efficient and direct memory assignment is more function call efficient
    //     // Hence in functions we're using memory assignment and in the constructor, we're looping
    //     addresses = owners;  
    // }

    // // View function to return transaction based on transaction id
    // function view_transaction(uint _txId) external view
    // onlyOwner 
    // txExists(_txId) 
    // returns(address address_to, uint CAR_amount, bytes memory tx_data, bool execute_status) {
    //     address_to = transactions[_txId].to;
    //     CAR_amount = transactions[_txId].value;
    //     tx_data = transactions[_txId].data;
    //     execute_status = transactions[_txId].executed;  
    // }

    // View function to return number of transaction based on transaction id
    function num_transactions() external view
    returns(uint num_tx) {
        num_tx = transactions.length;
    }

    // // View function to view approvals for a perticular transaction id
    // function view_transaction_approvals(uint _txId) external view
    // onlyOwner 
    // txExists(_txId) 
    // returns(bool[] memory owner_approvals) {
    //     // Since mapping cannot be returned or directly be assigned to arrays
    //     // were looping through the addresses in the mappong to make our array
    //     owner_approvals = new bool[](owners.length);
    //     for(uint i = 0; i<owners.length; i++){
    //         owner_approvals[i] = approved[_txId][owners[i]];
    //     }

    // }
    // Define function for local token payment

}