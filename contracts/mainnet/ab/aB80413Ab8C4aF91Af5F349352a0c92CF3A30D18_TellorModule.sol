// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0;

import "@gnosis.pm/zodiac/contracts/core/Module.sol";
import "usingtellor/contracts/UsingTellor.sol";

contract TellorModule is Module, UsingTellor {
    // Events
    event ProposalAdded(bytes32 indexed queryId, string indexed proposalId);
    event TellorModuleSetup(
        address indexed initiator,
        address indexed avatar,
        address target
    );
    // Storage
    bool private initialized;
    uint32 public resultExpiration;
    bytes32 public constant DOMAIN_SEPARATOR_TYPEHASH =
        0x47e79534a245952e8b16893a336b85a3d9ea9fa8c573f3d803afb92a79469218;
    // keccak256(
    //     "EIP712Domain(uint256 chainId,address verifyingContract)"
    // );
    // Mapping of proposalHash to transactionHash to execution state
    mapping(bytes32 => mapping(bytes32 => bool))
        public executedProposalTransactions;
    bytes32 public constant INVALIDATED =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    uint32 public cooldown;
    // Mapping of proposal hash to proposal id. Special case: INVALIDATED for proposal hashes that have been invalidated
    mapping(bytes32 => bytes32) public queryIds;
    bytes32 public constant TRANSACTION_TYPEHASH =
        0x72e9670a7ee00f5fbf1049b8c38e3f22fab7e9b85029e85cf9412f17fdd5c2ad;

    // keccak256(
    //     "Transaction(address to,uint256 value,bytes data,uint8 operation,uint256 nonce)"
    // );
    /*Functions*/
    /**
     * @param _owner Address of the owner of the module
     * @param _avatar Address of the avatar (e.g. a Safe)
     * @param _target Address of the contract that will call exec function
     * @param _tellorAddress Address of the Tellor oracle contract
     * @param _cooldown Cooldown in seconds that should be required after a oracle provided result
     * @param _expiration Duration that a positive result of the oracle is valid in seconds (or 0 if valid forever)
     * @notice There need to be at least 60 seconds between end of cooldown and expiration
     */
    constructor(
        address _owner,
        address _avatar,
        address _target,
        address payable _tellorAddress,
        uint32 _cooldown,
        uint32 _expiration
    ) UsingTellor(_tellorAddress) {
        bytes memory initParams = abi.encode(
            _owner,
            _avatar,
            _target,
            _tellorAddress,
            _cooldown,
            _expiration
        );
        setUp(initParams);
    }

    /**
     * @dev Function to add a proposal that should be considered for execution
     * @param _proposalId Id that should identify the proposal uniquely
     * @param _txHashes EIP-712 hashes of the transactions that should be executed
     */
    function addProposal(string memory _proposalId, bytes32[] memory _txHashes)
        public
    {
        // We generate the proposal string used for the oracle
        string memory _proposal = buildProposal(_proposalId, _txHashes);
        bytes32 _proposalHash = keccak256(bytes(_proposal));
        require(
            queryIds[_proposalHash] == bytes32(0),
            "Proposal has already been submitted"
        );
        bytes32 _queryId = getQueryId(_proposalId, _txHashes);
        // Set the proposal hash for this query id
        queryIds[_proposalHash] = _queryId;
        emit ProposalAdded(_queryId, _proposalId);
    }

    /**
     * @dev Build the proposal by combining the proposalId and the hex string of the hash of the txHashes
     * @param _proposalId Id of the proposal that proposes to execute the transactions represented by the txHashes
     * @param _txHashes EIP-712 Hashes of the transactions that should be executed
     */
    function buildProposal(
        string memory _proposalId,
        bytes32[] memory _txHashes
    ) public pure returns (string memory) {
        string memory _txsHash = _bytes32ToAsciiString(
            keccak256(abi.encodePacked(_txHashes))
        );
        return
            string(abi.encodePacked(_proposalId, bytes3(0xe2909f), _txsHash));
    }

    /**
     * @dev Executes the transactions of a proposal via the target if accepted
     * @param _proposalId Id that should identify the proposal uniquely
     * @param _txHashes EIP-712 hashes of the transactions that should be executed
     * @param _to Target of the transaction that should be executed
     * @param _value Wei value of the transaction that should be executed
     * @param _data Data of the transaction that should be executed
     * @param _operation Operation (Call or Delegatecall) of the transaction that should be executed
     * @notice The txIndex used by this function is always 0
     */
    function executeProposal(
        string memory _proposalId,
        bytes32[] memory _txHashes,
        address _to,
        uint256 _value,
        bytes memory _data,
        Enum.Operation _operation
    ) public {
        executeProposalWithIndex(
            _proposalId,
            _txHashes,
            _to,
            _value,
            _data,
            _operation,
            0
        );
    }

    /**
     * @dev Executes the transactions of a proposal via the target if accepted
     * @param _proposalId Id that should identify the proposal uniquely
     * @param _txHashes EIP-712 hashes of the transactions that should be executed
     * @param _to Target of the transaction that should be executed
     * @param _value Wei value of the transaction that should be executed
     * @param _data Data of the transaction that should be executed
     * @param _operation Operation (Call or Delegatecall) of the transaction that should be executed
     * @param _txIndex Index of the transaction hash in txHashes. This is used as the nonce for the transaction, to make the tx hash unique
     */
    function executeProposalWithIndex(
        string memory _proposalId,
        bytes32[] memory _txHashes,
        address _to,
        uint256 _value,
        bytes memory _data,
        Enum.Operation _operation,
        uint256 _txIndex
    ) public {
        // We use the hash of the proposal to check the execution state, as the other parameters might change, but the proposal not
        bytes32 _proposalHash = keccak256(
            bytes(buildProposal(_proposalId, _txHashes))
        );
        // Lookup query id for this proposal
        bytes32 _queryId = queryIds[_proposalHash];
        // Proposal hash needs to set to be eligible for execution
        require(
            _queryId != bytes32(0),
            "No query id set for provided proposal"
        );
        require(_queryId != INVALIDATED, "Proposal has been invalidated");
        bytes32 _txHash = getTransactionHash(
            _to,
            _value,
            _data,
            _operation,
            _txIndex
        );
        require(_txHashes[_txIndex] == _txHash, "Unexpected transaction hash");
        (
            bytes memory _valueRetrieved,
            uint256 _timestampReceived
        ) = getDataBefore(_queryId, block.timestamp); // change to getDataAfter(ts=0)
        require(_timestampReceived > 0, "Data not retrieved");
        // The result is valid in the time after the cooldown and before the expiration time (if set).
        require(
            _timestampReceived + uint256(cooldown) < block.timestamp, 
            "Wait for additional cooldown"
        );
        bool _didPass = abi.decode(_valueRetrieved, (bool));
        require(_didPass, "Transaction was not approved");
        uint32 _expiration = resultExpiration;
        require(
            _expiration == 0 ||
                _timestampReceived + uint256(_expiration) >= block.timestamp,
            "Result has expired"
        );
        // Check this is either the first transaction in the list or that the previous proposal was already approved
        require(
            _txIndex == 0 ||
                executedProposalTransactions[_proposalHash][
                    _txHashes[_txIndex - 1]
                ],
            "Previous transaction not executed yet"
        );
        // Check that this proposal was not executed yet
        require(
            !executedProposalTransactions[_proposalHash][_txHash],
            "Cannot execute transaction again"
        );
        // Mark transaction as executed
        executedProposalTransactions[_proposalHash][_txHash] = true;
        // Execute the transaction via the target.
        require(
            exec(_to, _value, _data, _operation),
            "Module transaction failed"
        );
    }

    /// @dev Marks a proposal as invalid, preventing execution of the connected transactions
    /// @param _proposalId Id that should identify the proposal uniquely
    /// @param _txHashes EIP-712 hashes of the transactions that should be executed
    /// @notice This can only be called by the owner
    function markProposalAsInvalid(
        string memory _proposalId,
        bytes32[] memory _txHashes // owner only is checked in markProposalAsInvalidByHash(bytes32)
    ) public {
        // We generate the proposal string used for the oracle
        string memory _proposal = buildProposal(_proposalId, _txHashes);
        bytes32 _proposalHash = keccak256(bytes(_proposal));
        markProposalAsInvalidByHash(_proposalHash);
    }

    /// @dev Marks a question hash as invalid, preventing execution of the connected transactions
    /// @param _proposalHash Proposal hash calculated based on the proposal id and txHashes
    /// @notice This can only be called by the owner
    function markProposalAsInvalidByHash(bytes32 _proposalHash)
        public
        onlyOwner
    {
        queryIds[_proposalHash] = INVALIDATED;
    }

    /**
     * @dev Generate the query id.
     * @param _proposalId Id that should identify the proposal uniquely
     * @notice It is required that this is the same as for the oracle implementation used.
     */
    function getQueryId(string memory _proposalId, bytes32[] memory _txHashes)
        public
        view
        returns (bytes32)
    {
        bytes32 _superHash = keccak256(abi.encode(_txHashes));
        bytes32 _queryId = keccak256(
            abi.encode("Snapshot", abi.encode(_proposalId, _superHash, address(this)))
        );
        return _queryId;
    }

    /**
     * @dev Returns the chain id used by this contract.
     */
    function getChainId() public view returns (uint256) {
        uint256 _id;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            _id := chainid()
        }
        return _id;
    }

    /**
     * @dev Generates the data for the module transaction hash (required for signing)
     * @param _to Target of the transaction that should be executed
     * @param _value Wei value of the transaction that should be executed
     * @param _data Data of the transaction that should be executed
     * @param _operation Operation (Call or Delegatecall) of the transaction that should be executed
     * @param _nonce Nonce of the transaction that should be executed
     */
    function generateTransactionHashData(
        address _to,
        uint256 _value,
        bytes memory _data,
        Enum.Operation _operation,
        uint256 _nonce
    ) internal view returns (bytes memory) {
        uint256 _chainId = getChainId();
        bytes32 _domainSeparator = keccak256(
            abi.encode(DOMAIN_SEPARATOR_TYPEHASH, _chainId, this)
        );
        bytes32 _transactionHash = keccak256(
            abi.encode(
                TRANSACTION_TYPEHASH,
                _to,
                _value,
                keccak256(_data),
                _operation,
                _nonce
            )
        );
        return
            abi.encodePacked(
                bytes1(0x19),
                bytes1(0x01),
                _domainSeparator,
                _transactionHash
            );
    }

    /**
     * @dev Generates the hash for the module transaction
     * @param _to Target of the transaction
     * @param _value Wei value of the transaction
     * @param _data Data of the transaction
     * @param _operation Operation (Call or Delegatecall) of the transaction
     * @param _nonce Nonce of the transaction
     */
    function getTransactionHash(
        address _to,
        uint256 _value,
        bytes memory _data,
        Enum.Operation _operation,
        uint256 _nonce
    ) public view returns (bytes32) {
        return
            keccak256(
                generateTransactionHashData(
                    _to,
                    _value,
                    _data,
                    _operation,
                    _nonce
                )
            );
    }

    /**
     * @dev Marks a proposal with an expired result as invalid, preventing execution of the connected transactions
     * @param _proposalHash Proposal hash calculated based on the proposal id and txHashes
     */
    function markProposalWithExpiredResultAsInvalid(bytes32 _proposalHash)
        public
    {
        uint32 _expirationDuration = resultExpiration;
        require(_expirationDuration > 0, "Results are valid forever");
        bytes32 _queryId = queryIds[_proposalHash];
        require(_queryId != INVALIDATED, "Proposal is already invalidated");
        require(
            _queryId != bytes32(0),
            "No query id set for provided proposal"
        );
        (
            bytes memory _valueRetrieved,
            uint256 _timestampRetrieved
        ) = getDataBefore(_queryId, block.timestamp);  // change to getDataAfter(ts=0)
        require(_timestampRetrieved > 0, "Data not retrieved");
        bool _didPass = abi.decode(_valueRetrieved, (bool));
        require(_didPass, "Transaction was not approved");
        require(
            _timestampRetrieved + uint256(_expirationDuration) <
                block.timestamp,
            "Result has not expired yet"
        );
        queryIds[_proposalHash] = INVALIDATED;
    }

    /**
    //  * @dev Initializes the contract with the given parameters.
    //  * @param _initParams Initialization parameters for the contract
    //  */
    function setUp(bytes memory _initParams) public override {
        (
            address _owner,
            address _avatar,
            address _target,
            address _tellorAddress,
            uint32 _cooldown,
            uint32 _expiration
        ) = abi.decode(
                _initParams,
                (address, address, address, address, uint32, uint32)
            );
        require(
            !initialized,
            "Initializable: contract is already initialized"
        );
        initialized = true;
        __Ownable_init();
        require(_avatar != address(0), "Avatar can not be zero address");
        require(_target != address(0), "Target can not be zero address");
        require(
            _expiration == 0 || _expiration - _cooldown >= 60,
            "There need to be at least 60s between end of cooldown and expiration"
        );
        avatar = _avatar;
        target = _target;
        tellor = ITellor(payable(_tellorAddress));
        resultExpiration = _expiration;
        cooldown = _cooldown;

        transferOwnership(_owner);

        emit TellorModuleSetup(msg.sender, _avatar, _target);
    }

    /**
     * @dev converts bytes32 to string
     * @param _bytes bytes32 to be converted
     */
    function _bytes32ToAsciiString(bytes32 _bytes)
        internal
        pure
        returns (string memory)
    {
        bytes memory s = new bytes(64);
        for (uint256 i = 0; i < 32; i++) {
            uint8 b = uint8(bytes1(_bytes << (i * 8)));
            uint8 hi = uint8(b) / 16;
            uint8 lo = uint8(b) % 16;
            s[2 * i] = _char(hi);
            s[2 * i + 1] = _char(lo);
        }
        return string(s);
    }

    /**
     * @dev converts uint8 to char
     * @param _b uint8 to be converted
     */
    function _char(uint8 _b) internal pure returns (bytes1 c) {
        if (_b < 10) return bytes1(_b + 0x30);
        else return bytes1(_b + 0x57);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only

/// @title Module Interface - A contract that can pass messages to a Module Manager contract if enabled by that contract.
pragma solidity >=0.7.0 <0.9.0;

import "../interfaces/IAvatar.sol";
import "../factory/FactoryFriendly.sol";
import "../guard/Guardable.sol";

abstract contract Module is FactoryFriendly, Guardable {
    /// @dev Emitted each time the avatar is set.
    event AvatarSet(address indexed previousAvatar, address indexed newAvatar);
    /// @dev Emitted each time the Target is set.
    event TargetSet(address indexed previousTarget, address indexed newTarget);

    /// @dev Address that will ultimately execute function calls.
    address public avatar;
    /// @dev Address that this module will pass transactions to.
    address public target;

    /// @dev Sets the avatar to a new avatar (`newAvatar`).
    /// @notice Can only be called by the current owner.
    function setAvatar(address _avatar) public onlyOwner {
        address previousAvatar = avatar;
        avatar = _avatar;
        emit AvatarSet(previousAvatar, _avatar);
    }

    /// @dev Sets the target to a new target (`newTarget`).
    /// @notice Can only be called by the current owner.
    function setTarget(address _target) public onlyOwner {
        address previousTarget = target;
        target = _target;
        emit TargetSet(previousTarget, _target);
    }

    /// @dev Passes a transaction to be executed by the avatar.
    /// @notice Can only be called by this contract.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
    function exec(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) internal returns (bool success) {
        /// check if a transactioon guard is enabled.
        if (guard != address(0)) {
            IGuard(guard).checkTransaction(
                /// Transaction info used by module transactions
                to,
                value,
                data,
                operation,
                /// Zero out the redundant transaction information only used for Safe multisig transctions
                0,
                0,
                0,
                address(0),
                payable(0),
                bytes("0x"),
                address(0)
            );
        }
        success = IAvatar(target).execTransactionFromModule(
            to,
            value,
            data,
            operation
        );
        if (guard != address(0)) {
            IGuard(guard).checkAfterExecution(bytes32("0x"), success);
        }
        return success;
    }

    /// @dev Passes a transaction to be executed by the target and returns data.
    /// @notice Can only be called by this contract.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
    function execAndReturnData(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) internal returns (bool success, bytes memory returnData) {
        /// check if a transactioon guard is enabled.
        if (guard != address(0)) {
            IGuard(guard).checkTransaction(
                /// Transaction info used by module transactions
                to,
                value,
                data,
                operation,
                /// Zero out the redundant transaction information only used for Safe multisig transctions
                0,
                0,
                0,
                address(0),
                payable(0),
                bytes("0x"),
                address(0)
            );
        }
        (success, returnData) = IAvatar(target)
            .execTransactionFromModuleReturnData(to, value, data, operation);
        if (guard != address(0)) {
            IGuard(guard).checkAfterExecution(bytes32("0x"), success);
        }
        return (success, returnData);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./interface/ITellor.sol";
import "./interface/IERC2362.sol";
import "./interface/IMappingContract.sol";

/**
 @author Tellor Inc
 @title UsingTellor
 @dev This contract helps smart contracts read data from Tellor
 */
contract UsingTellor is IERC2362 {
    ITellor public tellor;
    IMappingContract public idMappingContract;

    /*Constructor*/
    /**
     * @dev the constructor sets the oracle address in storage
     * @param _tellor is the Tellor Oracle address
     */
    constructor(address payable _tellor) {
        tellor = ITellor(_tellor);
    }

    /*Getters*/
    /**
     * @dev Retrieves the next value for the queryId after the specified timestamp
     * @param _queryId is the queryId to look up the value for
     * @param _timestamp after which to search for next value
     * @return _value the value retrieved
     * @return _timestampRetrieved the value's timestamp
     */
    function getDataAfter(bytes32 _queryId, uint256 _timestamp)
        public
        view
        returns (bytes memory _value, uint256 _timestampRetrieved)
    {
        (bool _found, uint256 _index) = getIndexForDataAfter(
            _queryId,
            _timestamp
        );
        if (!_found) {
            return ("", 0);
        }
        _timestampRetrieved = getTimestampbyQueryIdandIndex(_queryId, _index);
        _value = retrieveData(_queryId, _timestampRetrieved);
        return (_value, _timestampRetrieved);
    }

    /**
     * @dev Retrieves the latest value for the queryId before the specified timestamp
     * @param _queryId is the queryId to look up the value for
     * @param _timestamp before which to search for latest value
     * @return _value the value retrieved
     * @return _timestampRetrieved the value's timestamp
     */
    function getDataBefore(bytes32 _queryId, uint256 _timestamp)
        public
        view
        returns (bytes memory _value, uint256 _timestampRetrieved)
    {
        (, _value, _timestampRetrieved) = tellor.getDataBefore(
            _queryId,
            _timestamp
        );
    }

    /**
     * @dev Retrieves latest array index of data before the specified timestamp for the queryId
     * @param _queryId is the queryId to look up the index for
     * @param _timestamp is the timestamp before which to search for the latest index
     * @return _found whether the index was found
     * @return _index the latest index found before the specified timestamp
     */
    // slither-disable-next-line calls-loop
    function getIndexForDataAfter(bytes32 _queryId, uint256 _timestamp)
        public
        view
        returns (bool _found, uint256 _index)
    {
        uint256 _count = getNewValueCountbyQueryId(_queryId);
        if (_count == 0) return (false, 0);
        _count--;
        bool _search = true; // perform binary search
        uint256 _middle = 0;
        uint256 _start = 0;
        uint256 _end = _count;
        uint256 _timestampRetrieved;
        // checking boundaries to short-circuit the algorithm
        _timestampRetrieved = getTimestampbyQueryIdandIndex(_queryId, _end);
        if (_timestampRetrieved <= _timestamp) return (false, 0);
        _timestampRetrieved = getTimestampbyQueryIdandIndex(_queryId, _start);
        if (_timestampRetrieved > _timestamp) {
            // candidate found, check for disputes
            _search = false;
        }
        // since the value is within our boundaries, do a binary search
        while (_search) {
            _middle = (_end + _start) / 2;
            _timestampRetrieved = getTimestampbyQueryIdandIndex(
                _queryId,
                _middle
            );
            if (_timestampRetrieved > _timestamp) {
                // get immediate previous value
                uint256 _prevTime = getTimestampbyQueryIdandIndex(
                    _queryId,
                    _middle - 1
                );
                if (_prevTime <= _timestamp) {
                    // candidate found, check for disputes
                    _search = false;
                } else {
                    // look from start to middle -1(prev value)
                    _end = _middle - 1;
                }
            } else {
                // get immediate next value
                uint256 _nextTime = getTimestampbyQueryIdandIndex(
                    _queryId,
                    _middle + 1
                );
                if (_nextTime > _timestamp) {
                    // candidate found, check for disputes
                    _search = false;
                    _middle++;
                    _timestampRetrieved = _nextTime;
                } else {
                    // look from middle + 1(next value) to end
                    _start = _middle + 1;
                }
            }
        }
        // candidate found, check for disputed values
        if (!isInDispute(_queryId, _timestampRetrieved)) {
            // _timestampRetrieved is correct
            return (true, _middle);
        } else {
            // iterate forward until we find a non-disputed value
            while (
                isInDispute(_queryId, _timestampRetrieved) && _middle < _count
            ) {
                _middle++;
                _timestampRetrieved = getTimestampbyQueryIdandIndex(
                    _queryId,
                    _middle
                );
            }
            if (
                _middle == _count && isInDispute(_queryId, _timestampRetrieved)
            ) {
                return (false, 0);
            }
            // _timestampRetrieved is correct
            return (true, _middle);
        }
    }

    /**
     * @dev Retrieves latest array index of data before the specified timestamp for the queryId
     * @param _queryId is the queryId to look up the index for
     * @param _timestamp is the timestamp before which to search for the latest index
     * @return _found whether the index was found
     * @return _index the latest index found before the specified timestamp
     */
    // slither-disable-next-line calls-loop
    function getIndexForDataBefore(bytes32 _queryId, uint256 _timestamp)
        public
        view
        returns (bool _found, uint256 _index)
    {
        return tellor.getIndexForDataBefore(_queryId, _timestamp);
    }

    /**
     * @dev Retrieves multiple uint256 values before the specified timestamp
     * @param _queryId the unique id of the data query
     * @param _timestamp the timestamp before which to search for values
     * @param _maxAge the maximum number of seconds before the _timestamp to search for values
     * @param _maxCount the maximum number of values to return
     * @return _values the values retrieved, ordered from oldest to newest
     * @return _timestamps the timestamps of the values retrieved
     */
    function getMultipleValuesBefore(
        bytes32 _queryId,
        uint256 _timestamp,
        uint256 _maxAge,
        uint256 _maxCount
    )
        public
        view
        returns (bytes[] memory _values, uint256[] memory _timestamps)
    {
        // get index of first possible value
        (bool _ifRetrieve, uint256 _startIndex) = getIndexForDataAfter(
            _queryId,
            _timestamp - _maxAge
        );
        // no value within range
        if (!_ifRetrieve) {
            return (new bytes[](0), new uint256[](0));
        }
        uint256 _endIndex;
        // get index of last possible value
        (_ifRetrieve, _endIndex) = getIndexForDataBefore(_queryId, _timestamp);
        // no value before _timestamp
        if (!_ifRetrieve) {
            return (new bytes[](0), new uint256[](0));
        }
        uint256 _valCount = 0;
        uint256 _index = 0;
        uint256[] memory _timestampsArrayTemp = new uint256[](_maxCount);
        // generate array of non-disputed timestamps within range
        while (_valCount < _maxCount && _endIndex + 1 - _index > _startIndex) {
            uint256 _timestampRetrieved = getTimestampbyQueryIdandIndex(
                _queryId,
                _endIndex - _index
            );
            if (!isInDispute(_queryId, _timestampRetrieved)) {
                _timestampsArrayTemp[_valCount] = _timestampRetrieved;
                _valCount++;
            }
            _index++;
        }

        bytes[] memory _valuesArray = new bytes[](_valCount);
        uint256[] memory _timestampsArray = new uint256[](_valCount);
        // retrieve values and reverse timestamps order
        for (uint256 _i = 0; _i < _valCount; _i++) {
            _timestampsArray[_i] = _timestampsArrayTemp[_valCount - 1 - _i];
            _valuesArray[_i] = retrieveData(_queryId, _timestampsArray[_i]);
        }
        return (_valuesArray, _timestampsArray);
    }

    /**
     * @dev Counts the number of values that have been submitted for the queryId
     * @param _queryId the id to look up
     * @return uint256 count of the number of values received for the queryId
     */
    function getNewValueCountbyQueryId(bytes32 _queryId)
        public
        view
        returns (uint256)
    {
        return tellor.getNewValueCountbyQueryId(_queryId);
    }

    /**
     * @dev Returns the address of the reporter who submitted a value for a data ID at a specific time
     * @param _queryId is ID of the specific data feed
     * @param _timestamp is the timestamp to find a corresponding reporter for
     * @return address of the reporter who reported the value for the data ID at the given timestamp
     */
    function getReporterByTimestamp(bytes32 _queryId, uint256 _timestamp)
        public
        view
        returns (address)
    {
        return tellor.getReporterByTimestamp(_queryId, _timestamp);
    }

    /**
     * @dev Gets the timestamp for the value based on their index
     * @param _queryId is the id to look up
     * @param _index is the value index to look up
     * @return uint256 timestamp
     */
    function getTimestampbyQueryIdandIndex(bytes32 _queryId, uint256 _index)
        public
        view
        returns (uint256)
    {
        return tellor.getTimestampbyQueryIdandIndex(_queryId, _index);
    }

    /**
     * @dev Determines whether a value with a given queryId and timestamp has been disputed
     * @param _queryId is the value id to look up
     * @param _timestamp is the timestamp of the value to look up
     * @return bool true if queryId/timestamp is under dispute
     */
    function isInDispute(bytes32 _queryId, uint256 _timestamp)
        public
        view
        returns (bool)
    {
        return tellor.isInDispute(_queryId, _timestamp);
    }

    /**
     * @dev Retrieve value from oracle based on queryId/timestamp
     * @param _queryId being requested
     * @param _timestamp to retrieve data/value from
     * @return bytes value for query/timestamp submitted
     */
    function retrieveData(bytes32 _queryId, uint256 _timestamp)
        public
        view
        returns (bytes memory)
    {
        return tellor.retrieveData(_queryId, _timestamp);
    }

    /**
     * @dev allows dev to set mapping contract for valueFor (EIP2362)
     * @param _addy address of mapping contract
     */
    function setIdMappingContract(address _addy) external {
        require(address(idMappingContract) == address(0));
        idMappingContract = IMappingContract(_addy);
    }

    /**
     * @dev Retrieve most recent int256 value from oracle based on queryId
     * @param _id being requested
     * @return _value most recent value submitted
     * @return _timestamp timestamp of most recent value
     * @return _statusCode 200 if value found, 404 if not found
     */
    function valueFor(bytes32 _id)
        external
        view
        override
        returns (
            int256 _value,
            uint256 _timestamp,
            uint256 _statusCode
        )
    {
        bytes32 _queryId = idMappingContract.getTellorID(_id);
        bytes memory _valueBytes;
        (_valueBytes, _timestamp) = getDataBefore(
            _queryId,
            block.timestamp + 1
        );
        if (_timestamp == 0) {
            return (0, 0, 404);
        }
        uint256 _valueUint = _sliceUint(_valueBytes);
        _value = int256(_valueUint);
        return (_value, _timestamp, 200);
    }

    // Internal functions
    /**
     * @dev Convert bytes to uint256
     * @param _b bytes value to convert to uint256
     * @return _number uint256 converted from bytes
     */
    function _sliceUint(bytes memory _b)
        internal
        pure
        returns (uint256 _number)
    {
        for (uint256 _i = 0; _i < _b.length; _i++) {
            _number = _number * 256 + uint8(_b[_i]);
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only

/// @title Zodiac Avatar - A contract that manages modules that can execute transactions via this contract.
pragma solidity >=0.7.0 <0.9.0;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

interface IAvatar {
    /// @dev Enables a module on the avatar.
    /// @notice Can only be called by the avatar.
    /// @notice Modules should be stored as a linked list.
    /// @notice Must emit EnabledModule(address module) if successful.
    /// @param module Module to be enabled.
    function enableModule(address module) external;

    /// @dev Disables a module on the avatar.
    /// @notice Can only be called by the avatar.
    /// @notice Must emit DisabledModule(address module) if successful.
    /// @param prevModule Address that pointed to the module to be removed in the linked list
    /// @param module Module to be removed.
    function disableModule(address prevModule, address module) external;

    /// @dev Allows a Module to execute a transaction.
    /// @notice Can only be called by an enabled module.
    /// @notice Must emit ExecutionFromModuleSuccess(address module) if successful.
    /// @notice Must emit ExecutionFromModuleFailure(address module) if unsuccessful.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) external returns (bool success);

    /// @dev Allows a Module to execute a transaction and return data
    /// @notice Can only be called by an enabled module.
    /// @notice Must emit ExecutionFromModuleSuccess(address module) if successful.
    /// @notice Must emit ExecutionFromModuleFailure(address module) if unsuccessful.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
    function execTransactionFromModuleReturnData(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) external returns (bool success, bytes memory returnData);

    /// @dev Returns if an module is enabled
    /// @return True if the module is enabled
    function isModuleEnabled(address module) external view returns (bool);

    /// @dev Returns array of modules.
    /// @param start Start of the page.
    /// @param pageSize Maximum number of modules that should be returned.
    /// @return array Array of modules.
    /// @return next Start of the next page.
    function getModulesPaginated(address start, uint256 pageSize)
        external
        view
        returns (address[] memory array, address next);
}

// SPDX-License-Identifier: LGPL-3.0-only

/// @title Zodiac FactoryFriendly - A contract that allows other contracts to be initializable and pass bytes as arguments to define contract state
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract FactoryFriendly is OwnableUpgradeable {
    function setUp(bytes memory initializeParams) public virtual;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@gnosis.pm/safe-contracts/contracts/interfaces/IERC165.sol";
import "./BaseGuard.sol";

/// @title Guardable - A contract that manages fallback calls made to this contract
contract Guardable is OwnableUpgradeable {
    event ChangedGuard(address guard);

    address public guard;

    /// @dev Set a guard that checks transactions before execution
    /// @param _guard The address of the guard to be used or the 0 address to disable the guard
    function setGuard(address _guard) external onlyOwner {
        if (_guard != address(0)) {
            require(
                BaseGuard(_guard).supportsInterface(type(IGuard).interfaceId),
                "Guard does not implement IERC165"
            );
        }
        guard = _guard;
        emit ChangedGuard(guard);
    }

    function getGuard() external view returns (address _guard) {
        return guard;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title Enum - Collection of enums
/// @author Richard Meissner - <[email protected]>
contract Enum {
    enum Operation {Call, DelegateCall}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @notice More details at https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/IERC165.sol
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";
import "@gnosis.pm/safe-contracts/contracts/interfaces/IERC165.sol";
import "../interfaces/IGuard.sol";

abstract contract BaseGuard is IERC165 {
    function supportsInterface(bytes4 interfaceId)
        external
        pure
        override
        returns (bool)
    {
        return
            interfaceId == type(IGuard).interfaceId || // 0xe6d7a83a
            interfaceId == type(IERC165).interfaceId; // 0x01ffc9a7
    }

    /// Module transactions only use the first four parameters: to, value, data, and operation.
    /// Module.sol hardcodes the remaining parameters as 0 since they are not used for module transactions.
    /// This interface is used to maintain compatibilty with Gnosis Safe transaction guards.
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address msgSender
    ) external virtual;

    function checkAfterExecution(bytes32 txHash, bool success) external virtual;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

interface IGuard {
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address msgSender
    ) external;

    function checkAfterExecution(bytes32 txHash, bool success) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ITellor {
    //Controller
    function addresses(bytes32) external view returns (address);

    function uints(bytes32) external view returns (uint256);

    function burn(uint256 _amount) external;

    function changeDeity(address _newDeity) external;

    function changeOwner(address _newOwner) external;
    function changeUint(bytes32 _target, uint256 _amount) external;

    function migrate() external;

    function mint(address _reciever, uint256 _amount) external;

    function init() external;

    function getAllDisputeVars(uint256 _disputeId)
        external
        view
        returns (
            bytes32,
            bool,
            bool,
            bool,
            address,
            address,
            address,
            uint256[9] memory,
            int256
        );

    function getDisputeIdByDisputeHash(bytes32 _hash)
        external
        view
        returns (uint256);

    function getDisputeUintVars(uint256 _disputeId, bytes32 _data)
        external
        view
        returns (uint256);

    function getLastNewValueById(uint256 _requestId)
        external
        view
        returns (uint256, bool);

    function retrieveData(uint256 _requestId, uint256 _timestamp)
        external
        view
        returns (uint256);

    function getNewValueCountbyRequestId(uint256 _requestId)
        external
        view
        returns (uint256);

    function getAddressVars(bytes32 _data) external view returns (address);

    function getUintVar(bytes32 _data) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function isMigrated(address _addy) external view returns (bool);

    function allowance(address _user, address _spender)
        external
        view
        returns (uint256);

    function allowedToTrade(address _user, uint256 _amount)
        external
        view
        returns (bool);

    function approve(address _spender, uint256 _amount) external returns (bool);

    function approveAndTransferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external returns (bool);

    function balanceOf(address _user) external view returns (uint256);

    function balanceOfAt(address _user, uint256 _blockNumber)
        external
        view
        returns (uint256);

    function transfer(address _to, uint256 _amount)
        external
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external returns (bool success);

    function depositStake() external;

    function requestStakingWithdraw() external;

    function withdrawStake() external;

    function changeStakingStatus(address _reporter, uint256 _status) external;

    function slashReporter(address _reporter, address _disputer) external;

    function getStakerInfo(address _staker)
        external
        view
        returns (uint256, uint256);

    function getTimestampbyRequestIDandIndex(uint256 _requestId, uint256 _index)
        external
        view
        returns (uint256);

    function getNewCurrentVariables()
        external
        view
        returns (
            bytes32 _c,
            uint256[5] memory _r,
            uint256 _d,
            uint256 _t
        );

    function getNewValueCountbyQueryId(bytes32 _queryId)
        external
        view
        returns (uint256);

    function getTimestampbyQueryIdandIndex(bytes32 _queryId, uint256 _index)
        external
        view
        returns (uint256);

    function retrieveData(bytes32 _queryId, uint256 _timestamp)
        external
        view
        returns (bytes memory);

    //Governance
    enum VoteResult {
        FAILED,
        PASSED,
        INVALID
    }

    function setApprovedFunction(bytes4 _func, bool _val) external;

    function beginDispute(bytes32 _queryId, uint256 _timestamp) external;

    function delegate(address _delegate) external;

    function delegateOfAt(address _user, uint256 _blockNumber)
        external
        view
        returns (address);

    function executeVote(uint256 _disputeId) external;

    function proposeVote(
        address _contract,
        bytes4 _function,
        bytes calldata _data,
        uint256 _timestamp
    ) external;

    function tallyVotes(uint256 _disputeId) external;

    function governance() external view returns (address);

    function updateMinDisputeFee() external;

    function verify() external pure returns (uint256);

    function vote(
        uint256 _disputeId,
        bool _supports,
        bool _invalidQuery
    ) external;

    function voteFor(
        address[] calldata _addys,
        uint256 _disputeId,
        bool _supports,
        bool _invalidQuery
    ) external;

    function getDelegateInfo(address _holder)
        external
        view
        returns (address, uint256);

    function isFunctionApproved(bytes4 _func) external view returns (bool);

    function isApprovedGovernanceContract(address _contract)
        external
        returns (bool);

    function getVoteRounds(bytes32 _hash)
        external
        view
        returns (uint256[] memory);

    function getVoteCount() external view returns (uint256);

    function getVoteInfo(uint256 _disputeId)
        external
        view
        returns (
            bytes32,
            uint256[9] memory,
            bool[2] memory,
            VoteResult,
            bytes memory,
            bytes4,
            address[2] memory
        );

    function getDisputeInfo(uint256 _disputeId)
        external
        view
        returns (
            uint256,
            uint256,
            bytes memory,
            address
        );

    function getOpenDisputesOnId(bytes32 _queryId)
        external
        view
        returns (uint256);

    function didVote(uint256 _disputeId, address _voter)
        external
        view
        returns (bool);

    //Oracle
    function getReportTimestampByIndex(bytes32 _queryId, uint256 _index)
        external
        view
        returns (uint256);

    function getValueByTimestamp(bytes32 _queryId, uint256 _timestamp)
        external
        view
        returns (bytes memory);

    function getBlockNumberByTimestamp(bytes32 _queryId, uint256 _timestamp)
        external
        view
        returns (uint256);

    function getReportingLock() external view returns (uint256);

    function getReporterByTimestamp(bytes32 _queryId, uint256 _timestamp)
        external
        view
        returns (address);

    function reportingLock() external view returns (uint256);

    function removeValue(bytes32 _queryId, uint256 _timestamp) external;
    function getTipsByUser(address _user) external view returns(uint256);
    function tipQuery(bytes32 _queryId, uint256 _tip, bytes memory _queryData) external;
    function submitValue(bytes32 _queryId, bytes calldata _value, uint256 _nonce, bytes memory _queryData) external;
    function burnTips() external;

    function changeReportingLock(uint256 _newReportingLock) external;
    function getReportsSubmittedByAddress(address _reporter) external view returns(uint256);
    function changeTimeBasedReward(uint256 _newTimeBasedReward) external;
    function getReporterLastTimestamp(address _reporter) external view returns(uint256);
    function getTipsById(bytes32 _queryId) external view returns(uint256);
    function getTimeBasedReward() external view returns(uint256);
    function getTimestampCountById(bytes32 _queryId) external view returns(uint256);
    function getTimestampIndexByTimestamp(bytes32 _queryId, uint256 _timestamp) external view returns(uint256);
    function getCurrentReward(bytes32 _queryId) external view returns(uint256, uint256);
    function getCurrentValue(bytes32 _queryId) external view returns(bytes memory);
    function getDataBefore(bytes32 _queryId, uint256 _timestamp) external view returns(bool _ifRetrieve, bytes memory _value, uint256 _timestampRetrieved);
    function getTimeOfLastNewValue() external view returns(uint256);
    function depositStake(uint256 _amount) external;
    function requestStakingWithdraw(uint256 _amount) external;

    //Test functions
    function changeAddressVar(bytes32 _id, address _addy) external;

    //parachute functions
    function killContract() external;

    function migrateFor(address _destination, uint256 _amount) external;

    function rescue51PercentAttack(address _tokenHolder) external;

    function rescueBrokenDataReporting() external;

    function rescueFailedUpdate() external;

    //Tellor 360
    function addStakingRewards(uint256 _amount) external;

    function _sliceUint(bytes memory _b)
        external
        pure
        returns (uint256 _number);

    function claimOneTimeTip(bytes32 _queryId, uint256[] memory _timestamps)
        external;

    function claimTip(
        bytes32 _feedId,
        bytes32 _queryId,
        uint256[] memory _timestamps
    ) external;

    function fee() external view returns (uint256);

    function feedsWithFunding(uint256) external view returns (bytes32);

    function fundFeed(
        bytes32 _feedId,
        bytes32 _queryId,
        uint256 _amount
    ) external;

    function getCurrentFeeds(bytes32 _queryId)
        external
        view
        returns (bytes32[] memory);

    function getCurrentTip(bytes32 _queryId) external view returns (uint256);

    function getDataAfter(bytes32 _queryId, uint256 _timestamp)
        external
        view
        returns (bytes memory _value, uint256 _timestampRetrieved);

    function getDataFeed(bytes32 _feedId)
        external
        view
        returns (Autopay.FeedDetails memory);

    function getFundedFeeds() external view returns (bytes32[] memory);

    function getFundedQueryIds() external view returns (bytes32[] memory);

    function getIndexForDataAfter(bytes32 _queryId, uint256 _timestamp)
        external
        view
        returns (bool _found, uint256 _index);

    function getIndexForDataBefore(bytes32 _queryId, uint256 _timestamp)
        external
        view
        returns (bool _found, uint256 _index);

    function getMultipleValuesBefore(
        bytes32 _queryId,
        uint256 _timestamp,
        uint256 _maxAge,
        uint256 _maxCount
    )
        external
        view
        returns (uint256[] memory _values, uint256[] memory _timestamps);

    function getPastTipByIndex(bytes32 _queryId, uint256 _index)
        external
        view
        returns (Autopay.Tip memory);

    function getPastTipCount(bytes32 _queryId) external view returns (uint256);

    function getPastTips(bytes32 _queryId)
        external
        view
        returns (Autopay.Tip[] memory);

    function getQueryIdFromFeedId(bytes32 _feedId)
        external
        view
        returns (bytes32);

    function getRewardAmount(
        bytes32 _feedId,
        bytes32 _queryId,
        uint256[] memory _timestamps
    ) external view returns (uint256 _cumulativeReward);

    function getRewardClaimedStatus(
        bytes32 _feedId,
        bytes32 _queryId,
        uint256 _timestamp
    ) external view returns (bool);

    function getTipsByAddress(address _user) external view returns (uint256);

    function isInDispute(bytes32 _queryId, uint256 _timestamp)
        external
        view
        returns (bool);

    function queryIdFromDataFeedId(bytes32) external view returns (bytes32);

    function queryIdsWithFunding(uint256) external view returns (bytes32);

    function queryIdsWithFundingIndex(bytes32) external view returns (uint256);

    function setupDataFeed(
        bytes32 _queryId,
        uint256 _reward,
        uint256 _startTime,
        uint256 _interval,
        uint256 _window,
        uint256 _priceThreshold,
        uint256 _rewardIncreasePerSecond,
        bytes memory _queryData,
        uint256 _amount
    ) external;

    function tellor() external view returns (address);

    function tip(
        bytes32 _queryId,
        uint256 _amount,
        bytes memory _queryData
    ) external;

    function tips(bytes32, uint256)
        external
        view
        returns (uint256 amount, uint256 timestamp);

    function token() external view returns (address);

    function userTipsTotal(address) external view returns (uint256);

    function valueFor(bytes32 _id)
        external
        view
        returns (
            int256 _value,
            uint256 _timestamp,
            uint256 _statusCode
        );
}

interface Autopay {
    struct FeedDetails {
        uint256 reward;
        uint256 balance;
        uint256 startTime;
        uint256 interval;
        uint256 window;
        uint256 priceThreshold;
        uint256 rewardIncreasePerSecond;
        uint256 feedsWithFundingIndex;
    }

    struct Tip {
        uint256 amount;
        uint256 timestamp;
    }
    function getStakeAmount() external view returns(uint256);
    function stakeAmount() external view returns(uint256);
    function token() external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
    * @dev EIP2362 Interface for pull oracles
    * https://github.com/tellor-io/EIP-2362
*/
interface IERC2362
{
	/**
	 * @dev Exposed function pertaining to EIP standards
	 * @param _id bytes32 ID of the query
	 * @return int,uint,uint returns the value, timestamp, and status code of query
	 */
	function valueFor(bytes32 _id) external view returns(int256,uint256,uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMappingContract{
    function getTellorID(bytes32 _id) external view returns(bytes32);
}