// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "../../dependencies/governance/Multisig.sol";

import "../../interfaces/IPhiatMultisigGov.sol";
import "../../interfaces/IPhiatTimelockController.sol";

import "../libraries/types/DataTypes.sol";

contract PhiatMultisigGov is Multisig, IPhiatMultisigGov {
    constructor(address[] memory _owners, uint256 _required)
        Multisig(_owners, _required)
    {}

    function updateReserveLimits(
        IPhiatTimelockController timelock,
        address reserve
    )
        external
        override
        ownerExists(msg.sender)
        returns (DataTypes.ReserveLimits memory newLimits)
    {
        return timelock.updateReserveLimits(reserve);
    }

    function updateReservesLimits(IPhiatTimelockController timelock)
        external
        override
        ownerExists(msg.sender)
        returns (DataTypes.ReserveLimits[] memory newLimits)
    {
        return timelock.updateReservesLimits();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

contract Multisig {
    // ============ Events ============

    event Confirmation(address indexed sender, uint256 indexed transactionId);
    event Revocation(address indexed sender, uint256 indexed transactionId);
    event Submission(uint256 indexed transactionId);
    event Execution(uint256 indexed transactionId);
    event ExecutionFailure(uint256 indexed transactionId);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint256 required);

    // ============ Constants ============

    uint256 public constant MAX_OWNER_COUNT = 50;
    address constant ADDRESS_ZERO = address(0);

    // ============ Storage ============

    mapping(uint256 => Transaction) public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmations;
    mapping(address => bool) public isOwner;
    address[] public owners;
    uint256 public required;
    uint256 public transactionCount;

    // ============ Structs ============

    struct Transaction {
        address destination;
        uint256 value;
        bytes data;
        bool executed;
    }

    // ============ Modifiers ============

    modifier onlyWallet() {
        require(
            msg.sender == address(this),
            "Multisig: sender is not this contract"
        );
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        require(!isOwner[owner], "Multisig: should not be one of the owners");
        _;
    }

    modifier ownerExists(address owner) {
        require(isOwner[owner], "Multisig: should be one of the owners");
        _;
    }

    modifier transactionExists(uint256 transactionId) {
        require(
            transactions[transactionId].destination != ADDRESS_ZERO,
            "Multisig: transaction does not exist"
        );
        _;
    }

    modifier confirmed(uint256 transactionId, address owner) {
        require(
            confirmations[transactionId][owner],
            "Multisig: transaction is not confirmed"
        );
        _;
    }

    modifier notConfirmed(uint256 transactionId, address owner) {
        require(
            !confirmations[transactionId][owner],
            "Multisig: transaction is confirmed"
        );
        _;
    }

    modifier notExecuted(uint256 transactionId) {
        require(
            !transactions[transactionId].executed,
            "Multisig: transaction is executed"
        );
        _;
    }

    modifier notNull(address _address) {
        require(
            _address != ADDRESS_ZERO,
            "Multisig: should not be zero address"
        );
        _;
    }

    modifier validRequirement(uint256 ownerCount, uint256 _required) {
        require(
            ownerCount <= MAX_OWNER_COUNT &&
                _required <= ownerCount &&
                _required != 0 &&
                ownerCount != 0,
            "Multisig: invalid owner setting"
        );
        _;
    }

    // ============ Constructor ============

    /**
     * Contract constructor sets initial owners and required number of confirmations.
     *
     * @param  _owners    List of initial owners.
     * @param  _required  Number of required confirmations.
     */
    constructor(address[] memory _owners, uint256 _required)
        validRequirement(_owners.length, _required)
    {
        for (uint256 i = 0; i < _owners.length; i++) {
            require(
                _owners[i] != ADDRESS_ZERO,
                "Multisig: owner should not be zero address"
            );
            require(
                !isOwner[_owners[i]],
                "Multisig: should not have duplicate owners"
            );
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
    }

    // ============ Wallet-Only Functions ============

    /**
     * Allows to add a new owner. Transaction has to be sent by wallet.
     *
     * @param  owner  Address of new owner.
     */
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

    /**
     * Allows to remove an owner. Transaction has to be sent by wallet.
     *
     * @param  owner  Address of owner.
     */
    function removeOwner(address owner) public onlyWallet ownerExists(owner) {
        isOwner[owner] = false;
        for (uint256 i = 0; i < owners.length - 1; i++) {
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        }
        owners.pop();
        if (required > owners.length) {
            changeRequirement(owners.length);
        }
        emit OwnerRemoval(owner);
    }

    /**
     * Allows to replace an owner with a new owner. Transaction has to be sent by wallet.
     *
     * @param  owner     Address of owner to be replaced.
     * @param  newOwner  Address of new owner.
     */
    function replaceOwner(address owner, address newOwner)
        public
        onlyWallet
        ownerExists(owner)
        ownerDoesNotExist(newOwner)
        notNull(newOwner)
    {
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
        }
        isOwner[owner] = false;
        isOwner[newOwner] = true;
        emit OwnerRemoval(owner);
        emit OwnerAddition(newOwner);
    }

    /**
     * Allows to change the number of required confirmations. Transaction has to be sent by wallet.
     *
     * @param  _required  Number of required confirmations.
     */
    function changeRequirement(uint256 _required)
        public
        onlyWallet
        validRequirement(owners.length, _required)
    {
        required = _required;
        emit RequirementChange(_required);
    }

    // ============ Owner Functions ============

    /**
     * Allows an owner to submit and confirm a transaction.
     *
     * @param  destination  Transaction target address.
     * @param  value        Transaction ether value.
     * @param  data         Transaction data payload.
     * @return              Transaction ID.
     */
    function submitTransaction(
        address destination,
        uint256 value,
        bytes memory data
    ) public returns (uint256) {
        uint256 transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
        return transactionId;
    }

    /**
     * Allows an owner to confirm a transaction.
     *
     * @param  transactionId  Transaction ID.
     */
    function confirmTransaction(uint256 transactionId)
        public
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

    /**
     * Allows an owner to revoke a confirmation for a transaction.
     *
     * @param  transactionId  Transaction ID.
     */
    function revokeConfirmation(uint256 transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
    }

    /**
     * Allows an owner to execute a confirmed transaction.
     *
     * @param  transactionId  Transaction ID.
     */
    function executeTransaction(uint256 transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            Transaction storage txn = transactions[transactionId];
            txn.executed = true;
            if (externalCall(txn.destination, txn.value, txn.data)) {
                emit Execution(transactionId);
            } else {
                emit ExecutionFailure(transactionId);
                txn.executed = false;
            }
        }
    }

    // ============ Getter Functions ============

    /**
     * Returns the confirmation status of a transaction.
     *
     * @param  transactionId  Transaction ID.
     * @return                Confirmation status.
     */
    function isConfirmed(uint256 transactionId) public view returns (bool) {
        uint256 count = 0;
        for (uint256 i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                count += 1;
            }
            if (count == required) {
                return true;
            }
        }
        return false;
    }

    /**
     * Returns number of confirmations of a transaction.
     *
     * @param  transactionId  Transaction ID.
     * @return                Number of confirmations.
     */
    function getConfirmationCount(uint256 transactionId)
        public
        view
        returns (uint256)
    {
        uint256 count = 0;
        for (uint256 i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                count += 1;
            }
        }
        return count;
    }

    /**
     * Returns total number of transactions after filers are applied.
     *
     * @param  pending   Include pending transactions.
     * @param  executed  Include executed transactions.
     * @return           Total number of transactions after filters are applied.
     */
    function getTransactionCount(bool pending, bool executed)
        public
        view
        returns (uint256)
    {
        uint256 count = 0;
        for (uint256 i = 0; i < transactionCount; i++) {
            if (
                (pending && !transactions[i].executed) ||
                (executed && transactions[i].executed)
            ) {
                count += 1;
            }
        }
        return count;
    }

    /**
     * Returns array of owners.
     *
     * @return  Array of owner addresses.
     */
    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    /**
     * Returns array with owner addresses, which confirmed transaction.
     *
     * @param  transactionId  Transaction ID.
     * @return                Array of owner addresses.
     */
    function getConfirmations(uint256 transactionId)
        public
        view
        returns (address[] memory)
    {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint256 count = 0;
        uint256 i;
        for (i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        }
        address[] memory _confirmations = new address[](count);
        for (i = 0; i < count; i++) {
            _confirmations[i] = confirmationsTemp[i];
        }
        return _confirmations;
    }

    /**
     * Returns list of transaction IDs in defined range.
     *
     * @param  from      Index start position of transaction array.
     * @param  to        Index end position of transaction array.
     * @param  pending   Include pending transactions.
     * @param  executed  Include executed transactions.
     * @return           Array of transaction IDs.
     */
    function getTransactionIds(
        uint256 from,
        uint256 to,
        bool pending,
        bool executed
    ) public view returns (uint256[] memory) {
        uint256[] memory transactionIdsTemp = new uint256[](transactionCount);
        uint256 count = 0;
        uint256 i;
        for (i = 0; i < transactionCount; i++) {
            if (
                (pending && !transactions[i].executed) ||
                (executed && transactions[i].executed)
            ) {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        }
        uint256[] memory _transactionIds = new uint256[](to - from);
        for (i = from; i < to; i++) {
            _transactionIds[i - from] = transactionIdsTemp[i];
        }
        return _transactionIds;
    }

    // ============ Helper Functions ============

    // call has been separated into its own function in order to take advantage
    // of the Solidity's code generator to produce a loop that copies tx.data into memory.
    function externalCall(
        address destination,
        uint256 value,
        bytes memory data
    ) internal returns (bool) {
        (bool success, ) = destination.call{value: value}(data);
        return success;
    }

    /**
     * Adds a new transaction to the transaction mapping, if transaction does not exist yet.
     *
     * @param  destination  Transaction target address.
     * @param  value        Transaction ether value.
     * @param  data         Transaction data payload.
     * @return              Transaction ID.
     */
    function addTransaction(
        address destination,
        uint256 value,
        bytes memory data
    ) internal notNull(destination) returns (uint256) {
        uint256 transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });
        transactionCount += 1;
        emit Submission(transactionId);
        return transactionId;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "../protocol/libraries/types/DataTypes.sol";

import "./IPhiatTimelockController.sol";

interface IPhiatMultisigGov {
    function updateReserveLimits(
        IPhiatTimelockController timelock,
        address reserve
    ) external returns (DataTypes.ReserveLimits memory newLimits);

    function updateReservesLimits(IPhiatTimelockController timelock)
        external
        returns (DataTypes.ReserveLimits[] memory newLimits);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "../protocol/libraries/types/DataTypes.sol";

interface IPhiatTimelockController {
    function updateReserveLimits(address reserve)
        external
        returns (DataTypes.ReserveLimits memory newLimits);

    function updateReservesLimits()
        external
        returns (DataTypes.ReserveLimits[] memory newLimits);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;

library DataTypes {
    // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        //tokens addresses
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint8 id;
    }

    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: Reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60-63: reserved
        //bit 64-79: reserve factor
        uint256 data;
    }

    struct ReserveLimits {
        uint256 maxGlobalDepositSize;
        uint256 maxIndividualDepositSize;
        uint256 minIndividualDepositSize;
        uint256 maxGlobalBorrowSize;
        uint256 maxIndividualBorrowSize;
        uint256 maxBorrowBps;
    }

    struct UserConfigurationMap {
        uint256 data;
    }

    enum InterestRateMode {
        NONE,
        STABLE,
        VARIABLE
    }
}