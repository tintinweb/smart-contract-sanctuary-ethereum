// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

/// Adapted from https://solidity-by-example.org/app/multi-sig-wallet

/// Multisig controlled by 2 groups: admins and owners. 
/// Admins can add and remove admins and owners and set the confirmations required from each.
/// Some number of confirmations are required from both admins and owners for transactions
/// to be executed.
contract MultiSigWallet {
    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        bytes data
    );
    event ConfirmTransaction(address indexed admin, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);

    event AddAdmin(address indexed caller, address indexed admin);
    event AddOwner(address indexed caller, address indexed owner);
    
    event RemoveAdmin(address indexed caller, address indexed admin);
    event RemoveOwner(address indexed caller, address indexed owner);

    event SetAdminConfirmationsRequired(
        address indexed caller, 
        uint256 indexed adminConfirmationsRequired
    );
    event SetOwnerConfirmationsRequired(
        address indexed caller, 
        uint256 indexed ownerConfirmationsRequired
    );

    error AlreadyAnOwner(address owner);
    error AlreadyAnAdmin(address admin);

    error NotAnAdmin(address caller);
    error NotAnOwner(address caller);
    error NotAnOwnerOrAdmin(address caller);

    error OwnersAreRequired();
    error ConfirmationsRequiredCantBeZero();
    error ZeroAddress();

    error OwnerCantBeAdmin(address owner);
    error AdminCantBeOwner(address admin);

    error TxDoesNotExist(uint256 txIndex);
    error TxAlreadyExecuted(uint256 txIndex);
    error TxAlreadyConfirmed(uint256 txIndex);
    error TxFailed(uint256 txIndex);
    error TxNotConfirmed(uint256 txIndex);

    error InsufficientConfirmations(uint256 numConfirmations, uint256 numRequired);
    error ConfirmationsRequiredAboveMax(uint256 confirmationsRequired, uint256 max);
    error ArrayLengthBelowMinLength(uint256 length, uint256 minLength);

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 adminConfirmations;
        uint256 ownerConfirmations;
    }

    Transaction[] public transactions;

    address[] public admins;
    mapping(address => bool) public isAdmin;
    uint256 public adminConfirmationsRequired;

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public ownerConfirmationsRequired;

    // mapping from tx index => admin/owner => true if admin/owner has confirmed and false otherwise
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    modifier onlyOwner() {
        if (!isOwner[msg.sender]) revert NotAnOwner(msg.sender);
        _;
    }

    modifier onlyAdmin() {
        if (!isAdmin[msg.sender]) revert NotAnAdmin(msg.sender);
        _;
    }

    modifier onlyAdminOrOwner() {
        if (!isOwner[msg.sender] && !isAdmin[msg.sender]) revert NotAnOwnerOrAdmin(msg.sender);
        _;
    }

    modifier txExists(uint256 _txIndex) {
        if (_txIndex >= transactions.length) revert TxDoesNotExist(_txIndex);
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        if (transactions[_txIndex].executed) revert TxAlreadyExecuted(_txIndex);
        _;
    }

    modifier notConfirmed(uint256 _txIndex) {
        if (isConfirmed[_txIndex][msg.sender]) revert TxAlreadyConfirmed(_txIndex);
        _;
    }

    modifier onlyConfirmed(uint256 _txIndex) {
        if (!isConfirmed[_txIndex][msg.sender]) revert TxNotConfirmed(_txIndex);
        _;
    }

    /// If _admins is empty the setters in this contract will not be callable
    constructor(
        address[] memory _admins,
        address[] memory _owners,
        uint256 _adminConfirmationsRequired,
        uint256 _ownerConfirmationsRequired
    ) {
        if (_owners.length == 0) revert OwnersAreRequired();
        if (_adminConfirmationsRequired > _admins.length) {
            revert ConfirmationsRequiredAboveMax(_adminConfirmationsRequired, _admins.length);
        }
        if (_ownerConfirmationsRequired == 0) 
            revert ConfirmationsRequiredCantBeZero();
        if (_ownerConfirmationsRequired > _owners.length) {
            revert ConfirmationsRequiredAboveMax(_ownerConfirmationsRequired, _owners.length);
        }

        uint256 adminsLength = _admins.length;
        for (uint256 i = 0; i < adminsLength; i++) {
            address admin = _admins[i];

            if (admin == address(0)) revert ZeroAddress();
            if (isAdmin[admin]) revert AlreadyAnAdmin(admin);

            isAdmin[admin] = true;
            admins.push(admin);
        }

        uint256 ownersLength = _owners.length;
        for (uint256 i = 0; i < ownersLength; i++) {
            address owner = _owners[i];

            if (owner == address(0)) revert ZeroAddress();
            if (isAdmin[owner]) revert OwnerCantBeAdmin(owner);
            if (isOwner[owner]) revert AlreadyAnOwner(owner);

            isOwner[owner] = true;
            owners.push(owner);
        }

        adminConfirmationsRequired = _adminConfirmationsRequired;
        ownerConfirmationsRequired = _ownerConfirmationsRequired;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    /// Submit a new transaction for admin and owner confirmation
    function submitTransaction(
        address _to,
        uint256 _value,
        bytes memory _data
    ) 
        public 
        onlyAdminOrOwner 
    {
        uint256 txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                adminConfirmations: 0,
                ownerConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    /// Confirm that transaction with _txIndex can be executed
    function confirmTransaction(uint256 _txIndex)
        public
        onlyAdminOrOwner
        txExists(_txIndex)
        notConfirmed(_txIndex)
        notExecuted(_txIndex)
    {
        isConfirmed[_txIndex][msg.sender] = true;

        Transaction storage transaction = transactions[_txIndex];
        if (isAdmin[msg.sender]) {
            transaction.adminConfirmations += 1;
        } else {
            transaction.ownerConfirmations += 1;
        }

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    /// Revoke confirmation for transaction with _txIndex
    function revokeConfirmation(uint256 _txIndex)
        public
        onlyAdminOrOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        onlyConfirmed(_txIndex)
    {
        isConfirmed[_txIndex][msg.sender] = false;

        Transaction storage transaction = transactions[_txIndex];
        if (isAdmin[msg.sender]) {
            transaction.adminConfirmations -= 1;
        } else {
            transaction.ownerConfirmations -= 1;
        }

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    /// Execute the transaction with _txIndex
    function executeTransaction(uint256 _txIndex)
        public
        virtual
        onlyAdminOrOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        uint256 adminConfirmations = transaction.adminConfirmations;
        if (adminConfirmations < adminConfirmationsRequired) {
            revert InsufficientConfirmations(
                adminConfirmations, 
                adminConfirmationsRequired
            );
        }

        uint256 ownerConfirmations = transaction.ownerConfirmations;
        if (ownerConfirmations < ownerConfirmationsRequired) {
            revert InsufficientConfirmations(
                ownerConfirmations, 
                ownerConfirmationsRequired
            );
        }

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        if (!success) revert TxFailed(_txIndex);

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    /// Return the array of admins
    function getAdmins() public view returns (address[] memory) {
        return admins;
    }

    /// Return the array of owners
    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    /// Return the number of transactions that have been submitted
    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    /// Return the transaction with _txIndex
    function getTransaction(uint256 _txIndex)
        public
        view
        returns (
            address to,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 ownerConfirmations,
            uint256 adminConfirmations
        )
    {
        Transaction memory transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.ownerConfirmations,
            transaction.adminConfirmations
        );
    }

    /// Submit a transaction to add a new _admin
    function addAdmin(address _admin) public onlyAdmin {
        bytes memory data = abi.encodeWithSignature("_addAdmin(address)", _admin);
        submitTransaction(address(this), 0, data);
    }

    /// Submit a transaction to add a new _owner
    function addOwner(address _owner) public onlyAdmin {
        bytes memory data = abi.encodeWithSignature("_addOwner(address)", _owner);
        submitTransaction(address(this), 0, data);
    }

    /// Submit a transaction to remove _admin
    function removeAdmin(address _admin) public onlyAdmin {
        bytes memory data = abi.encodeWithSignature("_removeAdmin(address)", _admin);
        submitTransaction(address(this), 0, data);
    }

    /// Submit a transaction to remove _owner
    function removeOwner(address _owner) public onlyAdmin {
        bytes memory data = abi.encodeWithSignature("_removeOwner(address)", _owner);
        submitTransaction(address(this), 0, data);
    }

    /// Submit a transaction to set the number of admin confirmations required to execute 
    /// transactions
    function setAdminConfirmationsRequired(uint256 _adminConfirmationsRequired) 
        public 
        onlyAdmin 
    {
        bytes memory data = abi.encodeWithSignature(
            "_setAdminConfirmationsRequired(uint256)", 
            _adminConfirmationsRequired
        );
        submitTransaction(address(this), 0, data);
    }

    /// Submit a transaction to set the number of owner confirmations required to execute
    /// transactions
    function setOwnerConfirmationsRequired(uint256 _ownerConfirmationsRequired) 
        public 
        onlyAdmin 
    {
        bytes memory data = abi.encodeWithSignature(
            "_setOwnerConfirmationsRequired(uint256)", 
            _ownerConfirmationsRequired
        );
        submitTransaction(address(this), 0, data);
    }

    // Add _admin as an admin 
    function _addAdmin(address _admin) private {
        if (isAdmin[_admin]) revert AlreadyAnAdmin(_admin);
        if (isOwner[_admin]) revert AdminCantBeOwner(_admin);
        isAdmin[_admin] = true;
        admins.push(_admin);
        emit AddAdmin(msg.sender, _admin);
    }

    // Add _owner as an owner
    function _addOwner(address _owner) private {
        if (isOwner[_owner]) revert AlreadyAnOwner(_owner);
        if (isAdmin[_owner]) revert OwnerCantBeAdmin(_owner);
        isOwner[_owner] = true;
        owners.push(_owner);
        emit AddOwner(msg.sender, _owner);
    }

    // Remove _admin from being an admin 
    function _removeAdmin(address _admin) private {
        if (!isAdmin[_admin]) revert NotAnAdmin(_admin);
        uint256 adminsLength;
        if (adminsLength - 1 < adminConfirmationsRequired) {
            revert ArrayLengthBelowMinLength(
                adminsLength, 
                adminConfirmationsRequired
            );
        }
        for (uint256 i = 0; i < adminsLength; i++) {
            if (admins[i] == _admin) {
                isAdmin[_admin] = false;

                admins[i] = admins[adminsLength - 1];
                admins.pop();

                emit RemoveAdmin(msg.sender, _admin);

                return;
            }
        }
    }

    // Remove _owner from being an owner
    function _removeOwner(address _owner) private {
        if (!isOwner[_owner]) revert NotAnOwner(_owner);
        uint256 ownersLength;
        if (ownersLength - 1 < ownerConfirmationsRequired) {
            revert ArrayLengthBelowMinLength(
                ownersLength, 
                ownerConfirmationsRequired
            );
        }
        for (uint256 i = 0; i < ownersLength; i++) {
            if (owners[i] == _owner) {
                isOwner[_owner] = false;

                owners[i] = owners[ownersLength - 1];
                owners.pop();

                emit RemoveOwner(msg.sender, _owner);

                return;
            }
        }
    }

    // Set the _ownerConfirmationsRequired for transactions be be executed
    function _setAdminConfirmationsRequired(uint256 _adminConfirmationsRequired) private {
        if (_adminConfirmationsRequired > admins.length) {
            revert ConfirmationsRequiredAboveMax(_adminConfirmationsRequired, admins.length);
        }
 
        adminConfirmationsRequired = _adminConfirmationsRequired;
        emit SetAdminConfirmationsRequired(msg.sender, _adminConfirmationsRequired);
    }

    // Set the _ownerConfirmationsRequired for transactions be be executed
    function _setOwnerConfirmationsRequired(uint256 _ownerConfirmationsRequired) private {
        if (_ownerConfirmationsRequired == 0) revert ConfirmationsRequiredCantBeZero();
        if (_ownerConfirmationsRequired > owners.length) {
            revert ConfirmationsRequiredAboveMax(_ownerConfirmationsRequired, owners.length);
        }

        ownerConfirmationsRequired = _ownerConfirmationsRequired;
        emit SetOwnerConfirmationsRequired(msg.sender, _ownerConfirmationsRequired);
    }
}