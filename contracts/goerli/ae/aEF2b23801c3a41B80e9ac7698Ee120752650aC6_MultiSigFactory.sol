// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "MultiSigWallet.sol";

contract MultiSigFactory {
    event Deposit(address indexed sender, uint amount, uint balance);
    event SubmitTransaction(
        address indexed owner,
        uint indexed txIndex,
        address indexed to,
        uint value,
        bytes data
    );
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);

    mapping(address => MultiSigWallet[]) public userToWallets;
    mapping(address => bool) public userExists;
    mapping(address => mapping(MultiSigWallet => bool)) public isOwner;
    mapping(MultiSigWallet => mapping(uint => mapping(address => bool))) public isConfirmed;

    function createMultiSig(address[] memory _owners, uint _numConfirmationsRequired) public {
        MultiSigWallet multiSigWallet = new MultiSigWallet(_owners, _numConfirmationsRequired);

        for (uint i = 0; i < _owners.length; i++) {
            if (!userExists[_owners[i]]) {
                userToWallets[_owners[i]] = [multiSigWallet];
                userExists[_owners[i]] = true;
                isOwner[_owners[i]][multiSigWallet] = true;
            }

            else if (userExists[_owners[i]]) {
                userToWallets[_owners[i]].push(multiSigWallet);
                isOwner[_owners[i]][multiSigWallet] = true;
            }
        }
        
    }

    function getOwners(address _user, uint _contract) public view returns (address[] memory) {
        MultiSigWallet wallet_contract = userToWallets[_user][_contract];
        return wallet_contract.getOwners();
    }

    function getTransaction(address _user, uint _contract, uint _txIndex) public view returns (address to, uint value, bytes memory data, bool executed, uint numConfirmations) {
        MultiSigWallet wallet_contract = userToWallets[_user][_contract];
        return wallet_contract.getTransaction(_txIndex);
    }

    function getTransactionCount(address _user, uint _contract) public view returns (uint) {
        MultiSigWallet wallet_contract = userToWallets[_user][_contract];
        return wallet_contract.getTransactionCount();
    }

    function submitTransaction(address _user, uint _contract, address _to, uint _value, bytes memory _data) public {
        MultiSigWallet wallet_contract = userToWallets[_user][_contract];
        require(isOwner[msg.sender][wallet_contract], "not owner");
        uint txIndex = getTransactionCount(_user, _contract);
        wallet_contract.submitTransaction(_to, _value, _data);
        isConfirmed[wallet_contract][txIndex][msg.sender] = true;

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
        emit ConfirmTransaction(msg.sender, txIndex);
        
    }

    function confirmTransaction(address _user, uint _contract, uint _txIndex) public {
        MultiSigWallet wallet_contract = userToWallets[_user][_contract];
        require(isOwner[msg.sender][wallet_contract], "not owner");
        require(!isConfirmed[wallet_contract][_txIndex][msg.sender], "tx already confirmed");
        wallet_contract.confirmTransaction(_txIndex);
        isConfirmed[wallet_contract][_txIndex][msg.sender] = true;
        
        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function executeTransaction(address _user, uint _contract, uint _txIndex) public {
        MultiSigWallet wallet_contract = userToWallets[_user][_contract];
        require(isOwner[msg.sender][wallet_contract], "not owner");
        wallet_contract.executeTransaction(_txIndex);
        
        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(address _user, uint _contract, uint _txIndex) public {
        MultiSigWallet wallet_contract = userToWallets[_user][_contract];
        require(isOwner[msg.sender][wallet_contract], "not owner");
        require(isConfirmed[wallet_contract][_txIndex][msg.sender], "tx not confirmed");
        wallet_contract.revokeConfirmation(_txIndex);
        isConfirmed[wallet_contract][_txIndex][msg.sender] = false;
        
        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    function deposit(address _user, uint _contract) payable external {
        MultiSigWallet wallet_contract = userToWallets[_user][_contract];
        require(isOwner[msg.sender][wallet_contract], "not owner");
        (bool sent, ) = address(wallet_contract).call{value: msg.value}("");
        require(sent, "Failed to send Ether");

        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function returnWallet(address _user, uint _contract) view public returns(address) {
        MultiSigWallet wallet_contract = userToWallets[_user][_contract];
        return address(wallet_contract);
    }

    function returnWalletCount(address _user) view public returns(uint256) {
        uint256 walletCount = userToWallets[_user].length;
        return walletCount;
    }

    function returnNumConfirmationsRequired(address _user, uint _contract) view public returns(uint256) {
        MultiSigWallet wallet_contract = userToWallets[_user][_contract];
        return wallet_contract.numConfirmationsRequired();
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract MultiSigWallet {
    address mainOwner;
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public numConfirmationsRequired;

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numConfirmations;
    }

    mapping(uint => mapping(address => bool)) public isConfirmed;

    Transaction[] public transactions;

    modifier onlyOwner() {
        require(msg.sender == mainOwner, "not owner");
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

    constructor(address[] memory _owners, uint _numConfirmationsRequired) {
        mainOwner = msg.sender;
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

    receive() external payable {}

    function deposit() payable external {}

    function submitTransaction(
        address _to,
        uint _value,
        bytes memory _data
    ) public onlyOwner {
        uint txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );

        confirmTransaction(txIndex);
    }

    function confirmTransaction(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;
    }

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

        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "tx failed");
    }

    function revokeConfirmation(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

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
            bool executed,
            uint numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }
}

// [0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db], 2
// [0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, 0xdD870fA1b7C4700F2BD7f44238821C26f7392148, 0x583031D1113aD414F02576BD6afaBfb302140225], 2