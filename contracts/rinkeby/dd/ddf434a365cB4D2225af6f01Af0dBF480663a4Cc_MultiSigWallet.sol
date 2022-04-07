// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Multisignature wallet - Allows multiple parties to agree on transactions before execution.
/// @author Stefan George - <[email protected]>
contract MultiSigWallet {
    /*
     *  Events
     */
    event Confirmation(address indexed sender, uint256 indexed transactionId);
    event Revocation(address indexed sender, uint256 indexed transactionId);
    event Submission(uint256 indexed transactionId);
    event Execution(uint256 indexed transactionId);
    event ExecutionFailure(uint256 indexed transactionId);
    event Deposit(address indexed sender, uint256 value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint256 required);

    /*
     *  Constants
     */
    uint256 public constant MAX_OWNER_COUNT = 50;

    /*
     *  Storage
     */
    // 记录交易ID及交易信息体
    mapping(uint256 => Transaction) public transactions;
    // 记录交易ID及确认交易人和态度
    mapping(uint256 => mapping(address => bool)) public confirmations;
    // 账户是否是Owner
    mapping(address => bool) public isOwner;
    // 所有的Owner
    address[] public owners;
    // 确认交易人数量
    uint256 public required;
    // 交易数量
    uint256 public transactionCount;

    // 交易信息体
    struct Transaction {
        address destination;
        uint256 value;
        bytes data;
        bool executed;
    }

    /*
     *  Modifiers
     */
    modifier onlyWallet() {
        // 合约发起？
        require(msg.sender == address(this), "msw: msg.sender is not owner");
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        // owner不存在
        require(!isOwner[owner], "msw: owner Exists");
        _;
    }

    modifier ownerExists(address owner) {
        // owner存在
        require(isOwner[owner], "msw: owner not Exists");
        _;
    }

    modifier transactionExists(uint256 transactionId) {
        // 交易id下的目标不能是0x0，防止出现无效交易账户
        require(transactions[transactionId].destination != address(0), "msw: transaction not Exists");
        _;
    }

    modifier confirmed(uint256 transactionId, address owner) {
        // 交易Id下的账户确认交易
        require(confirmations[transactionId][owner], "msw: unconfirmed");
        _;
    }

    modifier notConfirmed(uint256 transactionId, address owner) {
        // 交易Id下的账户没有确认交易
        require(!confirmations[transactionId][owner], "msw: transactionId confirmed");
        _;
    }

    modifier notExecuted(uint256 transactionId) {
        // 交易Id还未执行成功
        require(!transactions[transactionId].executed, "msw: transactionId executed");
        _;
    }

    modifier notNull(address _address) {
        // 账户不能是零地址
        require(_address != address(0), "msw: _address==address(0)");
        _;
    }

    modifier validRequirement(uint256 ownerCount, uint256 _required) {
        // ownerCount 满足1、不能超最大Owner数量；2、大于等于最低确认账户数量；3、不能是0个账户
        // _required  满足1、不能超过ownerCount；2、不能是0个账户
        require(
            ownerCount <= MAX_OWNER_COUNT && _required <= ownerCount && _required != 0 && ownerCount != 0,
            "msw: ownerCount unvalid number"
        );
        _;
    }

    /// @dev Fallback function allows to deposit ether.
    receive() external payable {
        if (msg.value > 0) emit Deposit(msg.sender, msg.value);
    }

    /*
     * Public functions
     */
    /// @dev 设置最初的Owner和需要确认的账户数量
    /// @param _owners Owner账户列表
    /// @param _required 需要确认的账户数量
    constructor(address[] memory _owners, uint256 _required) validRequirement(_owners.length, _required) {
        for (uint256 i = 0; i < _owners.length; i++) {
            // 逐个查询Owner列表的账户，排查已经是Owner （如：一次性放入多个一样的账户）和零地址的账户
            require(!isOwner[_owners[i]] && _owners[i] != address(0), "MultiSigWallet: is owner or 0x0");
            // 新账户
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
    }

    /// @dev 添加新Owner. Transaction has to be sent by wallet.
    /// @param owner owner账户
    function addOwner(address owner)
        public
        onlyWallet
        ownerDoesNotExist(owner)
        notNull(owner)
        validRequirement(owners.length + 1, required)
    {
        isOwner[owner] = true;
        owners.push(owner);

        emit OwnerAddition(owner);
    }

    /// @dev 移除Owner. Transaction has to be sent by wallet.
    /// @param owner owner账户
    function removeOwner(address owner) public onlyWallet ownerExists(owner) {
        // 先标记FALSE
        isOwner[owner] = false;
        for (uint256 i = 0; i < owners.length - 1; i++)
            if (owners[i] == owner) {
                // 删除
                delete owners[i];
                break;
            }
        // 如果删除后，引起了确认数大于总Owner数量，需要设置最大确认数量就是总Owner数量
        if (required > owners.length) changeRequirement(owners.length);

        emit OwnerRemoval(owner);
    }

    /// @dev 用新账户替换旧账户. Transaction has to be sent by wallet.
    /// @param owner 旧账户
    /// @param newOwner 新账户
    function replaceOwner(address owner, address newOwner)
        public
        onlyWallet
        ownerExists(owner)
        ownerDoesNotExist(newOwner)
    {
        for (uint256 i = 0; i < owners.length; i++)
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
        isOwner[owner] = false;
        isOwner[newOwner] = true;

        emit OwnerRemoval(owner);
        emit OwnerAddition(newOwner);
    }

    /// @dev 改变确认账户数量. Transaction has to be sent by wallet.
    /// @param _required 确认账户数量.
    function changeRequirement(uint256 _required) public onlyWallet validRequirement(owners.length, _required) {
        required = _required;

        emit RequirementChange(_required);
    }

    /// @dev owner提交和确认交易
    /// @param destination 交易对象账户
    /// @param value eth数量
    /// @param data 交易数据
    /// @return transactionId  交易Id.
    function submitTransaction(
        address destination,
        uint256 value,
        bytes memory data
    ) public returns (uint256 transactionId) {
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }

    /// @dev owner确认交易
    /// @param transactionId 交易 ID.
    function confirmTransaction(uint256 transactionId)
        public
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        // 设置交易确认
        confirmations[transactionId][msg.sender] = true;

        emit Confirmation(msg.sender, transactionId);

        executeTransaction(transactionId);
    }

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(uint256 transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
    }

    /// @dev 允许任何人执行确认的交易体
    /// @param transactionId 交易ID.
    function executeTransaction(uint256 transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            // 获得交易体
            Transaction storage txn = transactions[transactionId];
            txn.executed = true;
            // 执行交易
            if (external_call(txn.destination, txn.value, txn.data.length, txn.data)) emit Execution(transactionId);
            else {
                emit ExecutionFailure(transactionId);
                txn.executed = false;
            }
        }
    }

    // call has been separated into its own function in order to take advantage
    // of the Solidity's code generator to produce a loop that copies tx.data into memory.
    function external_call(
        address destination,
        uint256 value,
        uint256 dataLength,
        bytes memory data
    ) internal returns (bool) {
        bool result;
        assembly {
            let x := mload(0x40) // "Allocate" memory for output (0x40 is where "free memory" pointer is stored by convention)
            let d := add(data, 32) // First 32 bytes are the padded length of data, so exclude that
            result := call(
                sub(gas(), 34710), // 34710 is the value that solidity is currently emitting
                // It includes callGas (700) + callVeryLow (3, to pay for SUB) + callValueTransferGas (9000) +
                // callNewAccountGas (25000, in case the destination address does not exist and needs creating)
                destination,
                value,
                d,
                dataLength, // Size of the input (in bytes) - this is what fixes the padding problem
                x,
                0 // Output is ignored, therefore the output size is zero
            )
        }
        return result;
    }

    /// @dev 返回交易确认量是不是都满足了最小多签量
    /// @param transactionId 交易 ID.
    /// @return status 是否满足多签数量
    function isConfirmed(uint256 transactionId) public view returns (bool status) {
        uint256 count = 0;
        for (uint256 i = 0; i < owners.length; i++) {
            //逐一从owner中查询，确认后累计
            if (confirmations[transactionId][owners[i]]) count += 1;
            if (count == required) status = true;
        }
    }

    /*
     * Internal functions
     */
    /// @dev 交易不存在时，提交交易体给transactions
    /// @param destination 交易对象地址
    /// @param value eth数量
    /// @param data 交易数据
    /// @return transactionId 交易Id
    function addTransaction(
        address destination,
        uint256 value,
        bytes memory data
    ) internal notNull(destination) returns (uint256 transactionId) {
        // 交易Id从0开始计数
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });
        // 计数+1
        transactionCount += 1;

        emit Submission(transactionId);
    }

    /*
     * Web3 call functions
     */
    /// @dev 获得交易确认数.
    /// @param transactionId 交易 ID.
    /// @return count 已确认数量.
    function getConfirmationCount(uint256 transactionId) public view returns (uint256 count) {
        for (uint256 i = 0; i < owners.length; i++) if (confirmations[transactionId][owners[i]]) count += 1;
    }

    /// @dev 获得Pending和完成两种状态下的交易量
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return count number of transactions after filters are applied.
    function getTransactionCount(bool pending, bool executed) public view returns (uint256 count) {
        for (uint256 i = 0; i < transactionCount; i++)
            if ((pending && !transactions[i].executed) || (executed && transactions[i].executed)) count += 1;
    }

    /// @dev 返回所有owner
    /// @return List of owner addresses.
    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    /// @dev 获得已经确认的owner账户.
    /// @param transactionId Transaction ID.
    /// @return _confirmations array of owner addresses.
    function getConfirmations(uint256 transactionId) public view returns (address[] memory _confirmations) {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint256 count = 0;
        uint256 i;
        for (i = 0; i < owners.length; i++)
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        // 重新赋值？
        _confirmations = new address[](count);
        for (i = 0; i < count; i++) _confirmations[i] = confirmationsTemp[i];
    }

    /// @dev 获取间隔内的交易Id列表.
    /// @param from Index start position of transaction array.
    /// @param to Index end position of transaction array.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return _transactionIds  array of transaction IDs.
    function getTransactionIds(
        uint256 from,
        uint256 to,
        bool pending,
        bool executed
    ) public view returns (uint256[] memory _transactionIds) {
        uint256[] memory transactionIdsTemp = new uint256[](transactionCount);
        uint256 count = 0;
        uint256 i;
        for (i = 0; i < transactionCount; i++)
            if ((pending && !transactions[i].executed) || (executed && transactions[i].executed)) {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        _transactionIds = new uint256[](to - from);
        for (i = from; i < to; i++) _transactionIds[i - from] = transactionIdsTemp[i];
    }
}