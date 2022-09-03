// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract MultiSig {

    // Mapping to store each multi sig wallet with a specific name
    mapping(string => wallets) walletMapping;
    // Mapping to keep track of each each signature for each transaction
    mapping(address => mapping(string => mapping( uint => bool))) transactionPerWallet;

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

    modifier walletExists(string memory _walletName) {
        require(walletMapping[_walletName].created, "Wallet not created for this ID.");
        _;
    }

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

    function createMultiSigWallet(string memory _walletName, address[] memory _addressList) 
    public {
        require(!walletMapping[_walletName].created, "Wallet already created with this name.");
        walletMapping[_walletName].created = true;
        walletMapping[_walletName].addresses = _addressList;
    }

    function depositToWallet(string memory _walletName, uint amount) 
    public payable walletExists(_walletName) {
        require(msg.value == amount, "Amount sent not the same as amount specified.");
        walletMapping[_walletName].amountStored += amount;
    }

    function createTransaction(string memory _walletName, address _depositAddress, uint _amount) 
    public walletExists(_walletName) isAddressMemberOfMultisig(_walletName) {

        address[] memory walletList = walletMapping[_walletName].addresses;
        uint _num_of_wallets = walletMapping[_walletName].addresses.length;

        transactions memory createdTransaction = transactions(
            {
                depositAddress : _depositAddress,
                amountToSend : _amount,
                signatures : _num_of_wallets
            }
        );
        walletMapping[_walletName].transactions.push(createdTransaction);
        uint transactionID = walletMapping[_walletName].transactions.length-1;

        // Set signatures ready to be signed by each address 
        for(uint i=0; i<_num_of_wallets; ++i) {
            transactionPerWallet[walletList[i]][_walletName][transactionID] = true;
        }
    }


    function validateTransaction(string memory _walletName, uint _transactionID) 
    public walletExists(_walletName) isAddressMemberOfMultisig(_walletName) {

        // Check if their is a transaction to be signed at this address
        require(transactionPerWallet[msg.sender][_walletName][_transactionID], "No valid transaction at this address/wallet/id.");
        require(walletMapping[_walletName].transactions[_transactionID].signatures > 0, "Transaction already complete.");
        // Set it to false to set it as "signed off"
        transactionPerWallet[msg.sender][_walletName][_transactionID] = false;
        walletMapping[_walletName].transactions[_transactionID].signatures -=1;

        // Check if all wallets have signed off on the transaction
        if(walletMapping[_walletName].transactions[_transactionID].signatures == 0) {
            // Send eth to deposit address
            (bool sent, ) = walletMapping[_walletName].transactions[_transactionID].depositAddress.call{value: walletMapping[_walletName].transactions[_transactionID].amountToSend}("");
            require(sent, "Transaction failed.");
        }

    } 

    function viewTransaction(string memory _walletName, uint _transactionID) 
    public view walletExists(_walletName) returns(bool) {
        // TODO handle false case correctly
        bool exists = walletMapping[_walletName].transactions[_transactionID].signatures > 0 ? true : false;
        return(exists);
    }

    function checkWalletExists(string memory _walletName) 
    public view returns (bool) {
        return (walletMapping[_walletName].created);
    }

    function checkWalletAmount(string memory _walletName)
    public view returns(uint) {
        return walletMapping[_walletName].amountStored;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}


}