// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract MultiSig {

    // VARIABLES ///

    // Mapping to store each multi sig wallet with a specific name
    mapping(string => wallets) walletMapping;
    // Mapping to keep track of each each signature for each transaction
    mapping(address => mapping(string => mapping(uint => bool))) transactionPerWallet;

    struct wallets {
        address[] addresses;
        uint amountStored;
        transactions[] transactions;
        bool created;
    }

    struct transactions {
        address depositAddress;
        uint amountToSend;
        uint signatures;
    }

    /// MODIFIERS //



    // Check wallet has been created
    modifier walletNameCheck (string memory _walletName) {
        require(walletMapping[_walletName].created, "Wallet doesn't exist");
        _;
    }

    // Check address is a member of the multisig wallet it's trying to access
    modifier isAddressMemberOfMultisig(string memory _walletName) {
        uint addressCount = walletMapping[_walletName].addresses.length;
        address[] memory addresses = walletMapping[_walletName].addresses;
        bool auth;
        for(uint i=0; i<addressCount; ++i) {
            if(msg.sender == addresses[i]) {
                auth = true;
            }
        }
        require(auth, "Wallet not a member of this multi sig.");
        _;
    }

    /// UPGRADE FUNCTIONALITY ///

    /*
       Here I'm manually adding the openzepplin reentrancy guard 
       so that we can make this contract upgradeable

       TODO: Revisit, clean up or decide if we even need reentrancy guards
       in this contract, it's only used once, maybe we can implement a more
       simple one
    */

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

       modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    
    
    function initialize() external {
        _status = _NOT_ENTERED;
    }


    /// WRITES ///

    /* 
        Here we create a wallet with a unique string as the wallet key, and pass in an array list
        This array list are all of the members of the multisig wallet that have to sign off on 
        any transaction that is proposed by another member.

        ** TODO: Add check to disallow the same address or 0x0 address
    */

    function createMultiSigWallet(string memory _walletName, address[] memory _addressList) 
    external {
        require(bytes(_walletName).length < 20, "Wallet must be less than 20 chars");
        require(_addressList.length <= 10 && _addressList.length > 1, "2-10 address count allowed");
        require(!walletMapping[_walletName].created, "Wallet with this name exists");
        walletMapping[_walletName].created = true;
        walletMapping[_walletName].addresses = _addressList;
    }

    /*
        Any address can deposit to any wallet. Just check it exists.
        
        ** TODO: Calculate in eth instead of wei 
    */

    function depositToWallet(string memory _walletName, uint amount) 
    external payable walletNameCheck(_walletName) {
        require(msg.value == amount, "Amount sent incorrect");
        walletMapping[_walletName].amountStored += amount;
    }

    /*
        Any member of the multisig wallet can propose a transaction, they must submit the wallet name, 
        address to send eth to, and the amount of eth to send. 

        ** TODO: Calculate in eth instead of wei 
    */

    function createTransaction(string memory _walletName, address _depositAddress, uint _amount) 
    external walletNameCheck(_walletName) isAddressMemberOfMultisig(_walletName) {

        // Check how many signatures are needed to sign off on the transaction
        uint _num_of_wallets = walletMapping[_walletName].addresses.length;

        // Create transaction struct to place into map
        transactions memory createdTransaction = transactions(
            {
                depositAddress : _depositAddress,
                amountToSend : _amount,
                signatures : _num_of_wallets
            }
        );

        // Add transaction to it's correct wallet
        walletMapping[_walletName].transactions.push(createdTransaction);
        uint transactionID = walletMapping[_walletName].transactions.length-1;

        // Set signatures ready to be signed by each address 
        for(uint i=0; i<_num_of_wallets; ++i) {
            transactionPerWallet[walletMapping[_walletName].addresses[i]][_walletName][transactionID] = true;
        }
    }

    /*
        Validate transaction works by each member of the wallet having to call this function
        Once a member validates a transaction, their signature is set to false and the wallet
        signature count is decremented. Once the signature count is 0 this means all members
        have signed off and we can send the ether to the deposit address.
    */

    function validateTransaction(string memory _walletName, uint _transactionID) 
    external walletNameCheck(_walletName) isAddressMemberOfMultisig(_walletName) nonReentrant {

        // Check if there is a transaction to be signed at this address
        require(transactionPerWallet[msg.sender][_walletName][_transactionID], "Txn doesn't exist");
        require(walletMapping[_walletName].transactions[_transactionID].signatures > 0, "Transaction already finished");
        // Set it to false to set it as "signed off"
        transactionPerWallet[msg.sender][_walletName][_transactionID] = false;
        // Minus one signature, when it hits 0 we send the transaction as all parties have confirmed the transaction
        walletMapping[_walletName].transactions[_transactionID].signatures -=1;

        // Check if all wallets have signed off on the transaction
        if(walletMapping[_walletName].transactions[_transactionID].signatures == 0) {
            // Send eth to deposit address
            (bool sent, ) = walletMapping[_walletName].transactions[_transactionID].depositAddress.call{value: walletMapping[_walletName].transactions[_transactionID].amountToSend}("");
            require(sent, "Transaction failed.");
        }

    } 

    /// READS ///

    function viewTransaction(string memory _walletName, uint _transactionID) 
    external view walletNameCheck(_walletName) returns(bool) {
        // TODO handle false case correctly
        bool exists = walletMapping[_walletName].transactions[_transactionID].signatures > 0 ? true : false;
        return(exists);
    }

    function checkWalletExists(string memory _walletName) 
    external view walletNameCheck(_walletName) returns (bool) {
        return (walletMapping[_walletName].created);
    }

    function checkWalletAmount(string memory _walletName)
    external view returns(uint) {
        return walletMapping[_walletName].amountStored;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}


}