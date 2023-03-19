// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import './IAccessController.sol';

/// @title a contract to use multisig approach to send some transactions for DAO: withdraw,
/// set swap fee, upgrade, etc.
/// @author Dexpresso Team
/// @notice we have 64 DaoMember in the most extreme case. Each DaoMember is able to
/// create, approve,disapprove, revoke and execute
/// transactions. Each DaoMember can have 3 active pending transaction at a time.
/// @dev transaction ids start from 1, and zero value for txId means no transaction found
/// the only array we have, is pendingTransactions which has 64*3 items length at most
contract DAOMultiSig is IAccessController, Initializable, UUPSUpgradeable, ReentrancyGuardUpgradeable {
    // State Variables

    uint256 public transactionsCount;
    address internal newImplAddress;
    // minimum number of approvals needed to execute a transaction
    int8 public quorum;
    uint8 public daoMembersCount;
    mapping(address => bool) public isDaoMember;

    /// @notice to track each daoMember's pending transaction if exists
    /// @dev transaction ids start from 1 and zero value indicates that
    /// there is no pending transaction for this daoMember
    mapping(address => uint8) private pendingTransactionsByDaoMember;

    /// @notice to track if an daoMember has approved a transaction
    /// @dev address maps to transaction id and it maps to a number between(1, 0, -1)
    /// indicating if the address approved, disaprove a specific transaction or has not voted
    mapping(address => mapping(uint256 => int8)) public txApprovalByDaoMember;

    /// @notice storing pending transactions ids in pendingTransactions array
    /// @dev this array has at most 64*5 items, since we have 64 daoMembers maximum
    /// and each daoMember can have just 5 active pending transaction at a time
    uint256[] internal pendingTransactions;

    // a mapping from transaction Id to its transaction object
    mapping(uint256 => Transaction) internal transactions;

    // Structs && Enums

    // supported different types of transactions in a multisig manner
    enum TransactionType {
        WITHDRAW,
        WITHDRAW_ALL,
        ADD_DAO_MEMBER,
        DELETE_DAO_MEMBER,
        UPDATE_QUORUM,
        SET_SWAPPER_FEE,
        UNPAUSE_SWAPPER,
        PROPOSE_SWAPPER_ADMIN,
        ACCEPT_SWAPPER_ADMIN,
        UPGRADE_DAO_MULTISIG
    }

    enum TransactionStatus {
        PENDING,
        EXECUTED,
        REVOKED,
        REJECTED,
        EXPIRED
    }

    enum Filter {
        NONE,
        APPROVED,
        DISAPPROVED
    }

    // fields of a transaction, organized in a gas-efficient way
    struct Transaction {
        address from;
        TransactionType txType;
        TransactionStatus status;
        int8 approvals;
        uint64 validUntil;
        bytes data;
    }

    // fields of a pending transaction, gets fetched from web3
    struct PendingTx {
        uint256 id;
        address from;
        TransactionType txType;
        int8 vote;
        int8 approvals;
        uint64 validUntil;
        bytes data;
    }

    // Events && Errors

    event TransactionCreated(address indexed by, uint256 indexed txId);
    event TransactionApproved(address indexed by, uint256 indexed txId);
    event TransactionDisapproved(address indexed by, uint256 indexed txId);
    event TransactionExecuted(address indexed by, uint256 indexed txId);
    event TransactionRevoked(address indexed by, uint256 indexed txId);
    event ApprovalRevoked(address indexed by, uint256 indexed txId);
    event DisApprovalRevoked(address indexed by, uint256 indexed txId);
    event ERC20UnsuccessfulTransfer(address token);
    event EthTransferStatus(bool);

    // A custom error, thrown when an daoMember wants to issue a new transaction
    // while having three active pending transactions
    error ExceedsMaxNumberOfPendingTxs();
    error ERC20CallReverted(address token);

    // Modifiers

    modifier onlyDaoMember() {
        require(isDaoMember[msg.sender], 'ERROR: invalid caller');
        _;
    }

    modifier notZeroAddress(address account) {
        require(account != address(0), 'ERROR: invalid address');
        _;
    }
    modifier isValidPendingTx(uint256 txId) {
        // txId = 0 is not a valid transaction Id (valid txId starts from 1)
        require(txId > 0 && txId <= transactionsCount, 'ERROR: txId not found');
        require(transactions[txId].status == TransactionStatus.PENDING, 'ERROR: not a valid pending transaction');
        require(transactions[txId].validUntil >= block.timestamp, 'ERROR: expired transaction');
        _;
    }

    modifier canCreateTransaction() {
        uint8 pendingCount = pendingTransactionsByDaoMember[msg.sender];
        // max number of pending transactions per daoMember is 5
        if (pendingCount >= 5) {
            revert ExceedsMaxNumberOfPendingTxs();
        }
        _;
    }

    // Constructor and Functions

    /// @dev don't include msg.sender address in _daoMember and don't use repetitive
    /// addresses in this parameter
    /// @param _daoMember list of Dao Member including less than 128 addresses who
    /// can approve transactions
    /// we have maximum 64 daoMembers
    /// @param _quorum minimum number of daoMembers needed to execute a transaction
    function initialize(address[] memory _daoMember, uint8 _quorum) public initializer onlyProxy {
        require(_daoMember.length < 64, 'ERROR: number of DAO members is more than expected');
        require(_quorum <= _daoMember.length, 'ERROR: invalid quorum');
        for (uint8 i = 0; i < _daoMember.length; i++) {
            require(_daoMember[i] != address(0), 'ERROR: invalid daoMember');
            require(!isDaoMember[_daoMember[i]], 'ERROR: not unique daoMember');
            isDaoMember[_daoMember[i]] = true;
        }
        quorum = int8(_quorum);
        daoMembersCount = uint8(_daoMember.length);
    }

    /// @notice a valid caller can create a transaction to withdraw assets,
    /// waiting for getting enough approvals
    /// @dev max number of tokens to withdraw from, is 32 - msg.sender mustn't
    /// have more than 3 pending transactions
    /// @param receiver the address assets transfer to
    /// @param tokens list of ERC20 asset addresses (up to 32 addresses)
    /// @param amounts list of amounts to withdraw in the order of token addresses
    function createWithdrawTransaction(
        address receiver,
        address[] memory tokens,
        uint256[] memory amounts
    ) external virtual onlyDaoMember notZeroAddress(receiver) canCreateTransaction onlyProxy {
        require(tokens.length == amounts.length && tokens.length > 0 && tokens.length <= 32, 'ERROR: invalid input');
        bytes memory data = abi.encode(receiver, tokens, amounts);
        _createTransaction(TransactionType.WITHDRAW, data);
    }

    /// @notice a valid caller can create a transaction to empty out contract,
    /// waiting for getting enough approvals
    /// @dev max number of tokens to withdraw from, is 64 - msg.sender mustn't
    /// have more than 3 pending transactions
    /// @param receiver the address assets transfer to
    /// @param tokens list of ERC20 asset addresses (up to 64 addresses)
    function createWithdrawAllTransaction(
        address receiver,
        address[] memory tokens
    ) external virtual onlyDaoMember notZeroAddress(receiver) canCreateTransaction onlyProxy {
        require(tokens.length > 0 && tokens.length <= 64, 'ERROR: invalid input');
        bytes memory data = abi.encode(receiver, tokens);
        _createTransaction(TransactionType.WITHDRAW_ALL, data);
    }

    /// @notice a valid caller can create a transaction to add a new daoMember,
    ///  waiting for getting enough approvals
    /// @dev msg.sender must not have a pending transaction
    /// @param newDaoMember is new daoMember's address
    function createAddDaoMemberTransaction(
        address newDaoMember,
        uint8 newQuorum
    ) external virtual onlyDaoMember notZeroAddress(newDaoMember) canCreateTransaction onlyProxy {
        require(daoMembersCount < 64, 'ERROR: exceeded maximum number of daoMembers');
        require(!isDaoMember[newDaoMember], 'ERROR: provided address is already an daoMember');
        bytes memory data = abi.encode(newDaoMember, newQuorum);
        _createTransaction(TransactionType.ADD_DAO_MEMBER, data);
    }

    /// @notice a valid caller can create a transaction to delete an daoMember,
    /// waiting for getting enough approvals
    /// @dev msg.sender must not have a pending transaction
    /// @param daoMember is daoMember's address
    function createDeleteDaoMemberTransaction(
        address daoMember,
        uint8 newQuorum
    ) external virtual onlyDaoMember notZeroAddress(daoMember) canCreateTransaction onlyProxy {
        require(isDaoMember[daoMember], 'ERROR: provided address is not a DAO member');
        bytes memory data = abi.encode(daoMember, newQuorum);
        _createTransaction(TransactionType.DELETE_DAO_MEMBER, data);
    }

    /// @notice a valid caller can create a transaction to update the quorum,
    /// waiting for getting enough approvals
    /// @dev new value should be less than or equal to the number of
    /// daoMember count `daoMembersCount`
    /// @param newValue new quorum value
    function createUpdateQuorumTransaction(
        uint8 newValue
    ) external virtual onlyDaoMember canCreateTransaction onlyProxy {
        require(int8(newValue) != quorum && newValue <= daoMembersCount, 'ERROR: invalid input');
        bytes memory data = abi.encode(newValue);
        _createTransaction(TransactionType.UPDATE_QUORUM, data);
    }

    /// @notice a valid caller can create a transaction to upgrade this
    /// contract, waiting for getting enough approvals
    /// @dev be careful with the address to be accurate. Upgrading to
    /// this address is irreversible
    /// @param impl new implementation's deployed address
    function createUpgradeDaoMultiSigTransaction(
        address impl
    ) external virtual onlyDaoMember notZeroAddress(impl) canCreateTransaction onlyProxy {
        bytes memory data = abi.encode(impl);
        _createTransaction(TransactionType.UPGRADE_DAO_MULTISIG, data);
    }

    /// @notice a valid caller can create a transaction to re-set the
    /// maximum fee in swap engine contract, waiting for getting enough approvals
    /// @dev be careful don't include any spaces in the functionSignature
    /// @param target swap engine's contract address
    /// @param functionSignature external contract's function signature
    /// @param value new fee value to set
    function createSetSwapperFeeTransaction(
        address target,
        string memory functionSignature,
        uint16 value
    ) external virtual onlyDaoMember notZeroAddress(target) onlyProxy {
        bytes memory data = abi.encode(target, functionSignature, value);
        _createTransaction(TransactionType.SET_SWAPPER_FEE, data);
    }

    /// @notice a valid caller can create a transaction to re-set the
    /// maximum fee in swap engine contract, waiting for getting enough approvals
    /// @dev be careful don't include any spaces in the functionSignature
    /// @param target swap engine's contract address
    /// @param functionSignature external contract's function signature
    /// @param proposedAdmin new admins's address
    function createProposeSwapperAdminTransaction(
        address target,
        string memory functionSignature,
        address proposedAdmin
    ) external virtual onlyDaoMember notZeroAddress(target) notZeroAddress(proposedAdmin) onlyProxy {
        bytes memory data = abi.encode(target, functionSignature, proposedAdmin);
        _createTransaction(TransactionType.PROPOSE_SWAPPER_ADMIN, data);
    }

    /// @notice a valid caller can create a transaction to re-set the
    /// maximum fee in swap engine contract, waiting for getting enough approvals
    /// @dev be careful don't include any spaces in the functionSignature
    /// @param target swap engine's contract address
    /// @param functionSignature external contract's function signature
    function createAcceptSwapperAdminTransaction(
        address target,
        string memory functionSignature
    ) external virtual onlyDaoMember notZeroAddress(target) onlyProxy {
        bytes memory data = abi.encode(target, functionSignature);
        _createTransaction(TransactionType.ACCEPT_SWAPPER_ADMIN, data);
    }

    /// @notice a valid caller can create a transaction to pause swap engine
    /// contract, waiting for getting enough approvals
    /// @dev be careful don't include any spaces in the functionSignature
    /// @param target swap engine's contract address
    /// @param functionSignature external contract's function signature
    function createUnpauseSwapperTransaction(
        address target,
        string memory functionSignature
    ) external virtual onlyDaoMember notZeroAddress(target) onlyProxy {
        bytes memory data = abi.encode(target, functionSignature);
        _createTransaction(TransactionType.UNPAUSE_SWAPPER, data);
    }

    /// @notice a valid caller can approve a pending transaction
    /// @dev each address can approve a transaction once. The creator of the
    /// transaction can't approve it (already approved)
    /// @param txId Id of the transaction to approve
    function approveTransaction(
        uint256 txId
    ) external virtual onlyDaoMember onlyProxy isValidPendingTx(txId) returns (bool) {
        require(txApprovalByDaoMember[msg.sender][txId] != 1, 'ERROR: approved before');
        Transaction storage transaction = transactions[txId];
        transaction.approvals = ++transaction.approvals - txApprovalByDaoMember[msg.sender][txId];
        txApprovalByDaoMember[msg.sender][txId] = 1;
        if (transaction.approvals - quorum == 0) {
            return _executeTransaction(txId, transaction);
        }
        emit TransactionApproved(msg.sender, txId);
        return true;
    }

    /// @notice a valid caller can disapprove a pending transaction
    /// @dev each address can approve a transaction once. The creator of the
    /// transaction can't approve it (already approved)
    /// @param txId Id of the transaction to approve
    function disapproveTransaction(
        uint256 txId
    ) external virtual onlyDaoMember onlyProxy isValidPendingTx(txId) returns (bool) {
        require(txApprovalByDaoMember[msg.sender][txId] != -1, 'ERROR: disapproved before');
        Transaction storage transaction = transactions[txId];
        transaction.approvals = --transaction.approvals - txApprovalByDaoMember[msg.sender][txId];
        txApprovalByDaoMember[msg.sender][txId] = -1;
        if (transaction.approvals + quorum == 0) {
            transaction.status = TransactionStatus.REJECTED;
            _removeFromPendingTransactions(txId);
        }
        emit TransactionDisapproved(msg.sender, txId);
        return true;
    }

    /// @notice a valid caller can disapprove a pending transaction, waiting
    ///  for getting enough approvals
    /// @dev each address can approve a transaction once. The creator of the
    ///  transaction can't disapprove it
    /// @param txId Id of the transaction to disapprove
    function revokeApproval(
        uint256 txId
    ) external virtual onlyDaoMember onlyProxy isValidPendingTx(txId) returns (bool) {
        require(txApprovalByDaoMember[msg.sender][txId] == 1, 'ERROR: no approvals yet');
        Transaction storage transaction = transactions[txId];
        transaction.approvals -= txApprovalByDaoMember[msg.sender][txId];
        txApprovalByDaoMember[msg.sender][txId] = 0;
        emit ApprovalRevoked(msg.sender, txId);
        return true;
    }

    /// @notice a valid caller can disapprove a pending transaction, waiting
    ///  for getting enough approvals
    /// @dev each address can approve a transaction once. The creator of the
    ///  transaction can't disapprove it
    /// @param txId Id of the transaction to disapprove
    function revokeDisApproval(
        uint256 txId
    ) external virtual onlyDaoMember onlyProxy isValidPendingTx(txId) returns (bool) {
        require(txApprovalByDaoMember[msg.sender][txId] == -1, 'ERROR: no disApprovals yet');
        Transaction storage transaction = transactions[txId];
        transaction.approvals -= txApprovalByDaoMember[msg.sender][txId];
        txApprovalByDaoMember[msg.sender][txId] = 0;
        emit DisApprovalRevoked(msg.sender, txId);
        return true;
    }

    /// @notice creator of the transaction can revoke it (drops the transaction from pending)
    /// @dev just the creator of the transaction can revoke it
    /// @param txId Id of the transaction to revoke
    function revokeTransaction(uint256 txId) external virtual onlyProxy isValidPendingTx(txId) returns (bool) {
        Transaction storage _transaction = transactions[txId];
        require(msg.sender == _transaction.from, 'ERROR: invalid caller');
        _transaction.status = TransactionStatus.REVOKED;
        pendingTransactionsByDaoMember[_transaction.from]--;
        _removeFromPendingTransactions(txId);
        emit TransactionRevoked(msg.sender, txId);
        return true;
    }

    /// @notice some pending transactions might be invalid due to expiry
    /// this function runs periodically to remove invalid pending transactions
    function cleanUp() external virtual onlyDaoMember onlyProxy {
        uint8 pendingTxsCount = uint8(pendingTransactions.length);
        for (uint8 i = 1; i - 1 < pendingTxsCount; i++) {
            uint256 txId = pendingTransactions[i - 1];
            Transaction memory transaction = transactions[txId];
            if (transaction.validUntil < block.timestamp) {
                transaction.status = TransactionStatus.EXPIRED;
                pendingTransactions[i - 1] = pendingTransactions[pendingTxsCount - 1];
                pendingTransactionsByDaoMember[transaction.from]--;
                pendingTransactions.pop();
                pendingTxsCount--;
                i--;
            }
        }
    }

    // returns pending transactions filter by none, approved and disapproved
    function getPendingTransactions(
        Filter filter,
        address DAOmember
    ) external view virtual onlyProxy returns (PendingTx[] memory, uint8 total) {
        PendingTx[] memory txs = new PendingTx[](pendingTransactions.length);
        uint256[] memory _pendingTxs = pendingTransactions;
        for (uint8 i = 0; i < _pendingTxs.length; i++) {
            uint256 txId = _pendingTxs[i];
            Transaction memory transaction = transactions[txId];
            if (transaction.validUntil > block.timestamp) {
                if (
                    (filter == Filter.APPROVED && txApprovalByDaoMember[DAOmember][txId] != 1) ||
                    (filter == Filter.DISAPPROVED && txApprovalByDaoMember[DAOmember][txId] != -1)
                ) {
                    continue;
                }

                txs[total].id = _pendingTxs[i];
                txs[total].from = transaction.from;
                txs[total].txType = transaction.txType;
                txs[total].vote = txApprovalByDaoMember[DAOmember][txId];
                txs[total].approvals = transaction.approvals;
                txs[total].validUntil = transaction.validUntil;
                txs[total].data = transaction.data;
                total++;
            }
        }
        return (txs, total);
    }

    /// @notice returns the balance of each asset transferred to the address of this contract
    /// @dev provide a list of ERC20 token addresses as an input (up to 256 item each call)
    /// @param tokens list of token addresses
    /// @return amounts list of return value of each call in the order of provided addresses
    function getBalanceOfAssets(
        address[] memory tokens
    ) public view virtual onlyDaoMember onlyProxy returns (uint256[] memory) {
        address _address = address(this);
        uint256[] memory amounts = new uint256[](tokens.length);
        for (uint8 i = 0; i < tokens.length; i++) {
            (bool success, bytes memory data) = address(tokens[i]).staticcall(
                abi.encodeWithSignature('balanceOf(address)', _address)
            );
            if (!success) {
                revert ERC20CallReverted(tokens[i]);
            }
            amounts[i] = abi.decode(data, (uint256));
        }
        return amounts;
    }

    function _createTransaction(TransactionType txType, bytes memory data) internal {
        uint256 txId = ++transactionsCount;
        Transaction memory transaction;
        transaction.from = msg.sender;
        transaction.txType = txType;
        // 259200 = 3 * 24 * 60 * 60
        transaction.validUntil = uint64(block.timestamp) + 259200;
        transaction.data = data;
        unchecked {
            transaction.approvals++;
            // map txId to creator to track daoMember's pending transaction
            pendingTransactionsByDaoMember[msg.sender]++;
        }
        // add create transaction to mapping
        transactions[txId] = transaction;
        // creator of the transaction is one of the the daoMember too
        txApprovalByDaoMember[msg.sender][txId] = 1;
        // add transaction id to pending list
        pendingTransactions.push(txId);
        emit TransactionCreated(msg.sender, txId);
    }

    /// @notice creator of the transaction can execute the already
    /// created transaction, after getting enough approvals
    /// @dev just the creator of the transaction can execute it
    /// @param txId Id of the transaction to execute
    function _executeTransaction(
        uint256 txId,
        Transaction storage _transaction
    ) internal virtual isValidPendingTx(txId) returns (bool) {
        if (!isDaoMember[_transaction.from]) {
            revert('ERROR: transaction creator is not a DaoMember anymore');
        }

        _transaction.status = TransactionStatus.EXECUTED;
        TransactionType txType = _transaction.txType;

        // execute Withdraw transaction
        if (txType == TransactionType.WITHDRAW) {
            (address payable receiver, address[] memory tokens, uint256[] memory amounts) = abi.decode(
                _transaction.data,
                (address, address[], uint256[])
            );
            _withdraw(receiver, tokens, amounts);
            return _afterExecution(txId);
        }

        // execute WITHDRAW_ALL transaction
        if (txType == TransactionType.WITHDRAW_ALL) {
            (address payable receiver, address[] memory tokens) = abi.decode(_transaction.data, (address, address[]));
            _withdrawAll(receiver, tokens);
            return _afterExecution(txId);
        }

        // execute SET_SWAPPER_FEE transaction
        if (txType == TransactionType.SET_SWAPPER_FEE) {
            (address callee, string memory functionSignature, uint16 fee) = abi.decode(
                _transaction.data,
                (address, string, uint16)
            );
            _setSwapFee(callee, functionSignature, fee);
            return _afterExecution(txId);
        }

        // execute PROPOSE_SWAPPER_ADMIN transaction
        if (txType == TransactionType.PROPOSE_SWAPPER_ADMIN) {
            (address callee, string memory functionSignature, address proposedAdmin) = abi.decode(
                _transaction.data,
                (address, string, address)
            );
            _proposeSwapperAdmin(callee, functionSignature, proposedAdmin);
            return _afterExecution(txId);
        }

        // execute ACCEPT_SWAPPER_ADMIN transaction
        if (txType == TransactionType.ACCEPT_SWAPPER_ADMIN) {
            (address callee, string memory functionSignature) = abi.decode(_transaction.data, (address, string));
            _acceptSwapperAdmin(callee, functionSignature);
            return _afterExecution(txId);
        }

        // execute UNPAUSE_SWAPPER transaction
        if (txType == TransactionType.UNPAUSE_SWAPPER) {
            (address callee, string memory functionSignature) = abi.decode(_transaction.data, (address, string));
            _unpauseSwapper(callee, functionSignature);
            return _afterExecution(txId);
        }

        // execute ADD_DAO_MEMBER transaction
        if (txType == TransactionType.ADD_DAO_MEMBER) {
            (address newDaoMember, uint8 newQuorum) = abi.decode(_transaction.data, (address, uint8));
            _addDaoMember(newDaoMember, newQuorum);
            return _afterExecution(txId);
        }

        // execute DELETE_DAO_MEMBER transaction
        if (txType == TransactionType.DELETE_DAO_MEMBER) {
            (address daoMember, uint8 newQuorum) = abi.decode(_transaction.data, (address, uint8));
            _deleteDaoMember(daoMember, newQuorum);
            return _afterExecution(txId);
        }

        // execute UPDATE_QUORUM transaction
        if (txType == TransactionType.UPDATE_QUORUM) {
            uint8 newValue = abi.decode(_transaction.data, (uint8));
            _updateQuorum(newValue);
            return _afterExecution(txId);
        }

        // execute UPGRADE_DAO_MULTISIG transaction
        if (txType == TransactionType.UPGRADE_DAO_MULTISIG) {
            address newImpl = abi.decode(_transaction.data, (address));
            _upgrade(newImpl);
            return _afterExecution(txId);
        }

        revert('ERROR: tx type not found');
    }

    function _afterExecution(uint256 txId) internal virtual returns (bool) {
        pendingTransactionsByDaoMember[transactions[txId].from]--;
        _removeFromPendingTransactions(txId);
        emit TransactionExecuted(msg.sender, txId);
        return true;
    }

    // we don't use safeTransfer as we know which tokens we are interacting with
    // we are considering tokens like USDT which aren't fully compatible with ERC20 standard
    function _withdraw(address payable receiver, address[] memory tokens, uint256[] memory amounts) internal virtual {
        uint256 EthBalance = address(this).balance;
        for (uint8 i = 0; i < tokens.length; i++) {
            if ((tokens[i] == address(0)) && (EthBalance > 0)) {
                (bool EthTransferSuccess, ) = receiver.call{value: EthBalance}('');
                emit EthTransferStatus(EthTransferSuccess);
            }
            (bool success, ) = address(tokens[i]).call(
                abi.encodeWithSelector(IERC20(tokens[i]).transfer.selector, receiver, amounts[i])
            );
            if (!success) {
                emit ERC20UnsuccessfulTransfer(tokens[i]);
            }
        }
    }

    function _withdrawAll(address payable receiver, address[] memory tokens) internal virtual nonReentrant {
        uint256[] memory amounts = getBalanceOfAssets(tokens);
        _withdraw(receiver, tokens, amounts);
    }

    function _addDaoMember(address newDaoMember, uint8 newQuorum) internal virtual {
        require(daoMembersCount < 64, 'ERROR: exceeded maximum number of daoMembers');
        daoMembersCount++;
        isDaoMember[newDaoMember] = true;
        _updateQuorum(newQuorum);
    }

    function _deleteDaoMember(address daoMember, uint8 newQuorum) internal virtual {
        daoMembersCount--;
        delete isDaoMember[daoMember];

        for (uint8 i = 1; i - 1 < pendingTransactions.length; i++) {
            Transaction memory transaction = transactions[pendingTransactions[i - 1]];
            if (transaction.from == daoMember) {
                pendingTransactions[i - 1] = pendingTransactions[pendingTransactions.length - 1];
                pendingTransactions.pop();
                i--;
            } else {
                int8 daoMemberApproval = txApprovalByDaoMember[daoMember][pendingTransactions[i - 1]];
                if (daoMemberApproval != 0) {
                    transaction.approvals -= daoMemberApproval;
                    txApprovalByDaoMember[daoMember][pendingTransactions[i - 1]] = 0;
                }
            }
        }
        delete pendingTransactionsByDaoMember[daoMember];
        _updateQuorum(newQuorum);
    }

    function _updateQuorum(uint8 newValue) internal virtual {
        require(newValue <= daoMembersCount, 'ERROR: invalid input');
        quorum = int8(newValue);
    }

    function _upgrade(address newImpl) internal virtual {
        newImplAddress = newImpl;
    }

    function _setSwapFee(address callee, string memory functionSignature, uint256 fee) internal virtual {
        (bool success, ) = callee.call(abi.encodeWithSignature(functionSignature, fee));
        require(success, 'ERROR: external call failed');
    }

    function _proposeSwapperAdmin(
        address callee,
        string memory functionSignature,
        address proposedAdmin
    ) internal virtual {
        (bool success, ) = callee.call(abi.encodeWithSignature(functionSignature, proposedAdmin));
        require(success, 'ERROR: external call failed');
    }

    function _acceptSwapperAdmin(address callee, string memory functionSignature) internal virtual {
        (bool success, ) = callee.call(abi.encodeWithSignature(functionSignature));
        require(success, 'ERROR: external call failed');
    }

    function _unpauseSwapper(address callee, string memory functionSignature) internal virtual {
        (bool success, ) = callee.call(abi.encodeWithSignature(functionSignature));
        require(success, 'ERROR: external call failed');
    }

    /// @notice remove an item from list by swapping it with the last item
    /// @param txId the transaction id to be removed from pending transaction's list
    function _removeFromPendingTransactions(uint256 txId) internal virtual {
        uint256 pendingTxsCount = pendingTransactions.length;
        for (uint8 i = 0; i < pendingTxsCount; i++) {
            if (pendingTransactions[i] == txId) {
                pendingTransactions[i] = pendingTransactions[pendingTxsCount - 1];
                pendingTransactions.pop();
            }
        }
    }

    function _authorizeUpgrade(address newImplementation) internal view override onlyDaoMember {
        require(newImplAddress != address(0), 'ERROR: upgrade to zero address');
        require(newImplAddress == newImplementation, "ERROR: implementation address don't match with preset address");
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IAccessController {
    function isDaoMember(address _addr) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}