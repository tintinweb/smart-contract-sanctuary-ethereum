/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + (temp % 10)));
            temp /= 10;
        }
        return string(buffer);
    }
}

/*
 *  TimeLockMultiSigWallet: Allows multiple parties to agree on transactions before execution with time lock.
 *  Reference 1: https://etherscan.io/address/0xf73b31c07e3f8ea8f7c59ac58ed1f878708c8a76#code
 *  Reference 2: https://github.com/compound-finance/compound-protocol/blob/master/contracts/Timelock.sol
 */
contract TimeLockMultiSigWallet {
    using Strings for uint256;

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
    event NewDelay(uint256 delay);

    uint256 public constant VERSION = 20210812;
    uint256 public constant MINIMUM_DELAY = 1;
    uint256 public constant MAXIMUM_DELAY = 15 days;
    uint256 public delay; // delay time

    uint256 public constant MAX_OWNER_COUNT = 50;

    mapping(uint256 => Transaction) public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmations;
    mapping(address => bool) public isOwner;
    address[] public owners;
    uint256 public required;
    uint256 public transactionCount;

    struct Transaction {
        address destination;
        uint256 value;
        bytes data;
        bool executed;
        uint256 submitTime;
    }

    /*
     *  Modifiers
     */
    modifier onlyWallet() {
        require(msg.sender == address(this), "msg.sender != address(this)");
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        require(!isOwner[owner], "is already owner");
        _;
    }

    modifier ownerExists(address owner) {
        require(isOwner[owner], "is not owner");
        _;
    }

    modifier transactionExists(uint256 transactionId) {
        require(
            transactions[transactionId].destination != address(0),
            "transactionId is not exists"
        );
        _;
    }

    modifier confirmed(uint256 transactionId, address owner) {
        require(confirmations[transactionId][owner], "is not confirmed");
        _;
    }

    modifier notConfirmed(uint256 transactionId, address owner) {
        require(!confirmations[transactionId][owner], "already confirmed");
        _;
    }

    modifier notExecuted(uint256 transactionId) {
        require(!transactions[transactionId].executed, "already executed");
        _;
    }

    modifier notNull(address _address) {
        require(_address != address(0), "_address == address(0)");
        _;
    }

    modifier validRequirement(uint256 ownerCount, uint256 _required) {
        require(
            ownerCount <= MAX_OWNER_COUNT &&
                _required <= ownerCount &&
                _required != 0 &&
                ownerCount != 0,
            "error: validRequirement()"
        );
        _;
    }

    /// @dev Fallback function allows to deposit ether.
    fallback() external {}

    receive() external payable {
        if (msg.value > 0) emit Deposit(msg.sender, msg.value);
    }

    /*
     * Public functions
     */
    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    constructor(
        address[] memory _owners,
        uint256 _required,
        uint256 _delay
    ) validRequirement(_owners.length, _required) {
        require(_delay >= MINIMUM_DELAY, "Delay must exceed minimum delay.");
        require(
            _delay <= MAXIMUM_DELAY,
            "Delay must not exceed maximum delay."
        );

        for (uint256 i = 0; i < _owners.length; i++) {
            require(!isOwner[_owners[i]] && _owners[i] != address(0));
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
        delay = _delay;
    }

    /// @dev Allows to add a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of new owner.
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

    /// @dev Allows to remove an owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner.
    function removeOwner(address owner) public onlyWallet ownerExists(owner) {
        isOwner[owner] = false;
        for (uint256 i = 0; i < owners.length - 1; i++)
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        if (required > (owners.length - 1))
            changeRequirement(owners.length - 1);
        emit OwnerRemoval(owner);
    }

    /// @dev Allows to replace an owner with a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner to be replaced.
    /// @param newOwner Address of new owner.
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

    /// @dev Allows to change the number of required confirmations. Transaction has to be sent by wallet.
    /// @param _required Number of required confirmations.
    function changeRequirement(uint256 _required)
        public
        onlyWallet
        validRequirement(owners.length, _required)
    {
        required = _required;
        emit RequirementChange(_required);
    }

    /*@dev Allows an owner to submit and confirm a transaction.
    @param destination Transaction target address.
    @param value Transaction ether value.
    @param data Transaction data payload.
    @return Returns transaction ID.*/
    function submitTransaction(
        address destination,
        uint256 value,
        bytes memory data
    ) public returns (uint256 transactionId) {
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }

    /// @dev Allows an owner to batch confirm  transactions.
    /// @param transactionIdArray Transaction ID array.
    function batchConfirmTransaction(uint256[] memory transactionIdArray)
        public
    {
        for (uint256 i = 0; i < transactionIdArray.length; i++) {
            confirmTransaction(transactionIdArray[i]);
        }
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint256 transactionId)
        public
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
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

    /// @dev Allows an owner to batch execute  transactions.
    /// @param transactionIdArray Transaction ID array.
    function batchExecuteTransaction(uint256[] memory transactionIdArray)
        public
    {
        for (uint256 i = 0; i < transactionIdArray.length; i++) {
            executeTransaction(transactionIdArray[i]);
        }
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint256 transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        require(
            getBlockTimestamp() >=
                transactions[transactionId].submitTime + delay,
            "The time is not up, the command cannot be executed temporarily!"
        );
        require(
            getBlockTimestamp() <=
                transactions[transactionId].submitTime + MAXIMUM_DELAY,
            "The maximum execution time has been exceeded, unable to execute!"
        );

        if (isConfirmed(transactionId)) {
            Transaction storage txn = transactions[transactionId];
            txn.executed = true;
            // address(txn.destination).call(abi.encodeWithSignature(txn.data))
            (bool success, ) = txn.destination.call{value: txn.value}(txn.data);
            if (success) emit Execution(transactionId);
            else {
                revert(
                    string(
                        abi.encodePacked(
                            "The transactionId ",
                            transactionId.toString(),
                            " failed."
                        )
                    )
                );
            }
        }
    }

    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(uint256 transactionId) public view returns (bool) {
        uint256 count = 0;
        for (uint256 i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) count += 1;
            if (count == required) return true;
        }
        return false;
    }

    /*
     * Internal functions
     */
    /*@dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    @param destination Transaction target address.
    @param value Transaction ether value.
    @param data Transaction data payload.
    @return Returns transaction ID.*/
    function addTransaction(
        address destination,
        uint256 value,
        bytes memory data
    ) internal notNull(destination) returns (uint256 transactionId) {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false,
            submitTime: block.timestamp
        });
        transactionCount += 1;
        emit Submission(transactionId);
    }

    /*
     * Web3 call functions
     */
    /*@dev Returns number of confirmations of a transaction.
    @param transactionId Transaction ID.
    @return Number of confirmations.*/
    function getConfirmationCount(uint256 transactionId)
        public
        view
        returns (uint256 count)
    {
        count = 0;
        for (uint256 i = 0; i < owners.length; i++)
            if (confirmations[transactionId][owners[i]]) count += 1;
    }

    /*@dev Returns total number of transactions after filers are applied.
    @param pending Include pending transactions.
    @param executed Include executed transactions.
    @return Total number of transactions after filters are applied.*/
    function getTransactionCount(bool pending, bool executed)
        public
        view
        returns (uint256 count)
    {
        count = 0;
        for (uint256 i = 0; i < transactionCount; i++)
            if (
                (pending && !transactions[i].executed) ||
                (executed && transactions[i].executed)
            ) count += 1;
    }

    /// @dev Returns list of owners.
    /// @return List of owner addresses.
    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    /*@dev Returns array with owner addresses, which confirmed transaction.
    @param transactionId Transaction ID.
    @return Returns array of owner addresses.*/
    function getConfirmations(uint256 transactionId)
        public
        view
        returns (address[] memory _confirmations)
    {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint256 count = 0;
        uint256 i;
        for (i = 0; i < owners.length; i++)
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        _confirmations = new address[](count);
        for (i = 0; i < count; i++) _confirmations[i] = confirmationsTemp[i];
    }

    /*@dev Returns list of transaction IDs in defined range.
    @param from Index start position of transaction array.
    @param to Index end position of transaction array.
    @param pending Include pending transactions.
    @param executed Include executed transactions.
    @return Returns array of transaction IDs.*/
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
            if (
                (pending && !transactions[i].executed) ||
                (executed && transactions[i].executed)
            ) {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        _transactionIds = new uint256[](to - from);
        for (i = from; i < to; i++)
            _transactionIds[i - from] = transactionIdsTemp[i];
    }

    function getBlockTimestamp() internal view returns (uint256) {
        return block.timestamp;
    }

    /*@dev setDelay
    @param delay time
    */
    function setDelay(uint256 _delay) public onlyWallet {
        require(_delay >= MINIMUM_DELAY, "Delay must exceed minimum delay.");
        require(
            _delay <= MAXIMUM_DELAY,
            "Delay must not exceed maximum delay."
        );

        delay = _delay;

        emit NewDelay(delay);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        bytes4 received = 0x150b7a02;
        return received;
    }
}