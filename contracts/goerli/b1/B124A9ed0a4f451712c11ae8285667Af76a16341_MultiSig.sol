// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
    @title Multisig wallet for the Openfort code assessment
    @author Taylor Ferran
    @notice Made for a technical challenge, not released in production
**/ 

/// @notice Custom error for when non admins try to call admin functions
/// @dev In production we would include far more of these for gas purposes
error NotAdminAddress();

contract MultiSig {

    /// @notice Mapping to check if signatory is part of this multisig and what access level is is
    mapping (address => uint256) public signatoryDetails;
    /// @notice To store transaction details by a transaction id
    mapping (uint256 => TransactionStruct) public transactionMapping;
    /// @notice To store which transactions have been signed by which address
    mapping (address => mapping (uint256 => bool)) public isTransactionSigned;
    /// @notice To store the hash of the password 
    mapping (address => bytes32) public addressPasswordHash;

    /// @notice Updatable number of signatures required for a transaction to process
    uint128 public numberOfSignaturesRequired;
    /// @notice Total number of transactions, used to assign a transaction id
    uint128 public numberOfTransactions;

    /// @notice Signatory list, used to keep track of who is on the list for viewing purposes
    /// @notice This could be removed if we don't care for the front end. It doesn't affect funciontality.
    SignatoryListStruct[] public signatoryList;

    /// @notice Data type to store signatory details for the array.
    /// @dev uint96 used to pack the struct correctly
    struct SignatoryListStruct {
        address signatoryAddress;
        uint96 signatoryRole;
    }

    /// @notice Data type to store transaction details
    /// @dev uint88 used to pack the struct correctly
    struct TransactionStruct {
        address depositAddress;
        uint88 signaturesRequired;
        bool active;
        uint256 amount;
    }

    /// @notice To check if an address is one of the signatories
    /// @dev Anything above 0 is a valid multisig address
    modifier isAddressMemberOfMultisig() {
        require(signatoryDetails[msg.sender] > 0, "Wallet not a member of this multi sig");
        _;
    }

    /// @notice To check if the address is tier one (admin)
    modifier isAddressTierOne() {

        // An example of a more gas friendly error we would use in production.
        // The others I've left as require statements for readability for this test
        if(signatoryDetails[msg.sender] != 1)
            revert NotAdminAddress();
        _;
    }

    /// @notice We include these in the constructor to make use of a contract factory
    constructor (SignatoryListStruct[] memory _signatoryList, uint8 _numberOfSignatures) {
        uint256 listLength = _signatoryList.length;
        for(uint256 i = 0; i < listLength;) {
            signatoryDetails[_signatoryList[i].signatoryAddress] = _signatoryList[i].signatoryRole;
            signatoryList.push(_signatoryList[i]);
            unchecked {
                ++i;
            }
        }

        assembly {
            sstore(numberOfSignaturesRequired.slot, _numberOfSignatures)
        }
    }

    /// @dev Ignore, used for testing
    function deposit () external payable {}

    /// @notice Any member can propose a transaction
    /// @return Returns the id of the newly formed transaction
    function createTransaction(address _depositAddress, uint256 _depositAmount) 
    external isAddressMemberOfMultisig() returns(uint128) {
        TransactionStruct memory newTransaction = TransactionStruct(
            {
                depositAddress : _depositAddress,
                signaturesRequired : uint88(numberOfSignaturesRequired),
                active : true,
                amount : _depositAmount
            }
        );

        ++numberOfTransactions;
        transactionMapping[numberOfTransactions] = newTransaction;
        return(numberOfTransactions);
    }

    /// @notice Sign transaction with normal EOA transaction signing
    function signTransactionWithKey(uint128 _transactionID) 
    external isAddressMemberOfMultisig() {
        signTransaction(_transactionID, msg.sender);
    }

    /// @notice **SINGLE USE** recovery function, to be used by any address with the password for a one use transaction sign
    /// @dev Potentially could be used for WebAuth(FIDO2) purposes as well, may need some tweaks. WebAuth also uses sha256
    /// @param _signer The address we want to sign the transaction with 
    /// @param _password The password that was set when we had control of the account
    function signTransactionWithPassword(uint128 _transactionID, address _signer, string calldata _password) 
    external {
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

        TransactionStruct memory localTxn = transactionMapping[_transactionID];

        if(localTxn.signaturesRequired == 0) {
            require(address(this).balance > localTxn.amount, "Not enough ETH in multisig");
            transactionMapping[_transactionID].active = false;
            (bool sent,) = localTxn.depositAddress.call{value: localTxn.amount}("");
            require(sent);
        }
    }

    /// @notice Used to unsign a transaction, doing the opposite of signTransaction.
    function unsignTransaction(uint128 _transactionID) 
    external isAddressMemberOfMultisig() {
        require(isTransactionSigned[msg.sender][_transactionID], "Txn not signed by this address");
        isTransactionSigned[msg.sender][_transactionID] = false;
        ++transactionMapping[_transactionID].signaturesRequired;
    }

    /// @notice Sets a transaction to inactive, rendering it unusable.
    /// Address level needs to be 2 or above to call this function.
    function cancelTransaction(uint128 _transactionID) 
    external isAddressMemberOfMultisig() {
        require(signatoryDetails[msg.sender] < 3, "Address does not have the correct access level to cancel transactions");
        transactionMapping[_transactionID].active = false;
    }

    /// @notice Used to assign the public backup password hash to an address
    /// @param _passwordHash the 32 bit hash of the password generated from the sha256 hash function
    function assignPasswordHash(bytes32 _passwordHash) 
    external isAddressMemberOfMultisig() {
        addressPasswordHash[msg.sender] = _passwordHash;
    }

    /// @notice Only tier 1 signatories can update this value
    /// @dev Might make sense to deprecate this and move to the createTransaction function
    function updateNumberOfSignaturesRequired(uint128 _numberOfSignaturesRequired) 
    external isAddressTierOne() {
        require(_numberOfSignaturesRequired < signatoryList.length + 1, "Number provided higher than number of signatories");
        assembly {
            sstore(numberOfSignaturesRequired.slot, _numberOfSignaturesRequired)
        }
    }


    /// @notice Only tier 1 signatories can add signatories
    function addSignatory(address _signatory, uint96 _role) 
    external isAddressTierOne() {
        require(signatoryDetails[_signatory] < 1, "Signatory already added");
        SignatoryListStruct memory newSignatory = SignatoryListStruct(
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
    external isAddressTierOne() {
        for(uint i = 0; i < signatoryList.length;) {
            if(_signatory == signatoryList[i].signatoryAddress) {
                signatoryList[i] = signatoryList[signatoryList.length - 1];
                signatoryList.pop();
                signatoryDetails[_signatory] = 0;
            }
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Only tier 1 signatories can edit roles
    function changeSignatoryRole(address _signatory, uint96 _role)
    external isAddressTierOne() {
        signatoryDetails[_signatory] = _role;
    }

    /// @dev View functions

    function generatePasswordHash(string calldata _passwordHash) public pure returns(bytes32) {
        return sha256(abi.encodePacked(_passwordHash));
    }

    function viewAddresses() external view returns(SignatoryListStruct[] memory) {
        return signatoryList;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}
}