// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/*
    @title Multisig wallet for the Openfort code challenge
    @author Taylor Ferran

    Usually we would have documentation on something like notion, but I've just left 
    some notes below so it's easier to read through before examining the actual code.

        Functionality includes:
        - Defining signatories, signatory roles and inital amount of signatures required. Done on contract creation.
        - Create transactions if a signatory. Inserting the deposit address and deposit amount.
        - Sign transactions if a signatory.
        - Unsign transactions if a signatory.
        - If transaction signatures reaches 0, transaction is sent out to the deposit address.
        - Cancel transactions if the address calling it is signatory level two or below.
        - Update number of signatures needed if the address calling it is signatory level one.
        - Add a signatory if the address calling it is signatory level one.
        - Remove a signatory if the address calling it is signatory level one.
        - Assign a password hash to an address.
        - Sign a transaction using the password for that address (for recovery purposes).
*/

contract MultiSig {

    // Mapping to check if signatory is part of this multisig and what access level is is
    mapping (address => uint256) public signatoryDetails;
    // To store transaction details by a transaction id
    mapping (uint256 => transactionStruct) public transactionMapping;
    // To store which transactions have been signed by which address
    mapping (address => mapping (uint256 => bool)) public isTransactionSigned;
    // To store the hash of the password 
    mapping (address => bytes32) public addressPasswordHash;

    // Updatable number of signatures required for a transaction to process
    uint128 public numberOfSignaturesRequired;
    // Total number of transactions, used to assign a transaction id
    uint128 public numberOfTransactions;

    // Signatory list, used to keep track of who is on the list for viewing purposes
    // This could be removed if we don't care for the front end. It doesn't affect funciontality.
    signatoryListStruct[] public signatoryList;

    // Data type to store signatory details for the array.
    struct signatoryListStruct {
        address signatoryAddress;
        uint96 signatoryRole;
    }

    // Data type to store transaction details
    struct transactionStruct {
        address depositAddress;
        uint88 signaturesRequired;
        bool active;
        uint256 amount;
    }


    /// @notice To check if an address is one of the signatories
    modifier isAddressMemberOfMultisig() {
        require(signatoryDetails[msg.sender] > 0, "Wallet not a member of this multi sig.");
        _;
    }

    /// @notice To check if the address is tier one (admin)
    modifier isAddressTierOne() {
        require(signatoryDetails[msg.sender] == 1, "Wallet is not the correct access level.");
        _;
    }

    /// @notice We include these in the constructor to make use of a contract factory
    constructor (signatoryListStruct[] memory _signatoryList, uint8 _numberOfSignatures) {

        for(uint256 i=0; i<_signatoryList.length; ++i) {
            signatoryDetails[_signatoryList[i].signatoryAddress] = _signatoryList[i].signatoryRole;
            signatoryList.push(_signatoryList[i]);
        }

        numberOfSignaturesRequired = _numberOfSignatures;
    }

    /// @dev Ignore, used for remix testing to send eth to contract on remix blockchain
    function deposit () public payable {

    }

    /// @notice Any member can propose a transaction
    function createTransaction(address _depositAddress, uint256 _amount) 
    public isAddressMemberOfMultisig() returns(uint128) {

        transactionStruct memory newTransaction = transactionStruct(
            {
                depositAddress : _depositAddress,
                signaturesRequired : uint88(numberOfSignaturesRequired),
                amount : _amount,
                active : true
            }
        );

        ++numberOfTransactions;
        transactionMapping[numberOfTransactions] = newTransaction;
        return(numberOfTransactions);
    }

    /// @notice Sign transaction with normal EOA transaction signing
    function signTransactionWithKey(uint128 _transactionID) 
    public isAddressMemberOfMultisig() {
        signTransaction(_transactionID, msg.sender);
    }

    /// @notice Single use recovery function, to be used by any address with the password for a one use transaction sign
    function signTransactionWithPassword(uint128 _transactionID, address _signer, string memory _password) 
    public {
        require(generatePasswordHash(_password) == addressPasswordHash[_signer]);
        signTransaction(_transactionID, _signer);
    }

    /// @dev We pass in the txn to sign and address to sign with, check our txn is active and unsigned 
    /// then set signature to signed and decrement txn signatures by one. If signatures required
    /// hits 0 then the txn is is carried out and the ETH is sent to the deposit address.
    function signTransaction(uint128 _transactionID, address _signer)
    internal {

        require(transactionMapping[_transactionID].active, "Txn inactive");
        require(!isTransactionSigned[_signer][_transactionID], "Txn already signed by this address");
        isTransactionSigned[_signer][_transactionID] = true;
        --transactionMapping[_transactionID].signaturesRequired;

        transactionStruct memory localTxn = transactionMapping[_transactionID];

        if(localTxn.signaturesRequired == 0) {
            (bool sent,) = localTxn.depositAddress.call{value: localTxn.amount}("");
            require(sent);
            transactionMapping[_transactionID].active = false;
        }
    }

    /// @notice Used to unsign a transaction, doing the opposite of signTransaction.
    function unsignTransaction(uint128 _transactionID) 
    public isAddressMemberOfMultisig(){

        require(isTransactionSigned[msg.sender][_transactionID], "Txn not signed by this address");
        isTransactionSigned[msg.sender][_transactionID] = false;
        ++transactionMapping[_transactionID].signaturesRequired;
    }

    /// @notice Sets a transaction to inactive, rendering it unusable.
    /// Address level needs to be 2 or above to call this function.
    function cancelTransaction(uint128 _transactionID) 
    public isAddressMemberOfMultisig() {
        require(signatoryDetails[msg.sender] <= 2, "Address does not have the correct access level to cancel transactions");
        transactionMapping[_transactionID].active = false;
    }

    /// @notice Used to assign the public backup password has to an address
    function assignPasswordHash(bytes32 _passwordHash) 
    public isAddressMemberOfMultisig() {
        addressPasswordHash[msg.sender] = _passwordHash;
    }

    /// @notice Only tier 1 signatories can update this value
    function updateNumberOfSignaturesRequired(uint128 _numberOfSignaturesRequired) 
    public isAddressTierOne() {
        require(_numberOfSignaturesRequired <= signatoryList.length, "Number provided higher than number of signatories ");
        numberOfSignaturesRequired = _numberOfSignaturesRequired;
    }


    /// @notice Only tier 1 signatories can add signatories 
    function addSignatory(address _signatory, uint96 _role) 
    public isAddressTierOne() {

        require(signatoryDetails[_signatory] < 1, "Signatory already added");

        signatoryListStruct memory newSignatory = signatoryListStruct(
            {
                signatoryAddress : _signatory,
                signatoryRole : _role
            }
        );

        signatoryDetails[_signatory] = _role;
        signatoryList.push(newSignatory);

    }

    /// @notice Only tier 1 signatories can remove signatories 
    function removeSignatory(address _signatory)
    public isAddressTierOne() {
        
        require(signatoryDetails[_signatory] > 0, "Signatory not apart of multisig");

        for(uint i=0; i < signatoryList.length; ++i) {
            if(_signatory == signatoryList[i].signatoryAddress) {
                signatoryList[i] = signatoryList[signatoryList.length - 1];
                signatoryList.pop();
                signatoryDetails[_signatory] = 0;
            }
        }
    }

    /// @notice Only tier 1 signatories can edit roles
    function changeSignatoryRole(address _signatory, uint96 _role)
    public isAddressTierOne() {
        require(signatoryDetails[_signatory] > 0, "Signatory not apart of multisig");
        signatoryDetails[_signatory] = _role;
    }

    /// @dev View functions

    function generatePasswordHash(string memory _passwordHash) public pure returns(bytes32) {
        return sha256(abi.encodePacked(_passwordHash));
    }

    function viewAddresses() public view returns(signatoryListStruct[] memory) {
        return signatoryList;
    }

    function viewTransactions() public view returns(transactionStruct[] memory) {

        // TODO FIX THIS SHIT AAAAAAaa

        //transactionStruct memory transactionList = new transactionStruct[](numberOfTransactions); 
        //transactionStruct[2] memory transactionList;
        transactionStruct[] memory transactionList;
        for(uint i=1; i < numberOfTransactions; i++) {
            transactionList[i-1] = transactionMapping[i];
        }

        return transactionList;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

}