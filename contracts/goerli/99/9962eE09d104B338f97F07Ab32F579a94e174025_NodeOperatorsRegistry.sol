// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";

import "./interfaces/INodeOperatorsRegistry.sol";
import "./lib/UnstructuredStorage.sol";
import "./lib/MemoryUtils.sol";
import "./helper/ArrConversion.sol";

contract NodeOperatorsRegistry is INodeOperatorsRegistry, AccessControl, ArrConversion {
    using SafeMath for uint256;
    using UnstructuredStorage for bytes32;

    // Access Control List
    bytes32 constant public MANAGE_SIGNING_KEYS = keccak256("MANAGE_SIGNING_KEYS");
    bytes32 constant public ADD_NODE_OPERATOR_ROLE = keccak256("ADD_NODE_OPERATOR_ROLE");
    bytes32 constant public SET_NODE_OPERATOR_ACTIVE_ROLE = keccak256("SET_NODE_OPERATOR_ACTIVE_ROLE");
    bytes32 constant public SET_NODE_OPERATOR_NAME_ROLE = keccak256("SET_NODE_OPERATOR_NAME_ROLE");
    bytes32 constant public SET_NODE_OPERATOR_ADDRESS_ROLE = keccak256("SET_NODE_OPERATOR_ADDRESS_ROLE");
    bytes32 constant public SET_NODE_OPERATOR_LIMIT_ROLE = keccak256("SET_NODE_OPERATOR_LIMIT_ROLE");
    bytes32 constant public REPORT_STOPPED_VALIDATORS_ROLE = keccak256("REPORT_STOPPED_VALIDATORS_ROLE");

    uint256 constant public PUBKEY_LENGTH = 48;
    uint256 constant public SIGNATURE_LENGTH = 96;

    uint256 internal constant UINT64_MAX = uint256(type(uint64).max);
    bytes32 internal constant SIGNING_KEYS_MAPPING_NAME = keccak256("lightNode.NodeOperatorsRegistry.signingKeysMappingName");

    /// @dev Node Operator parameters and internal state
    struct NodeOperator {
        bool active;    // a flag indicating if the operator can participate in further staking and reward distribution
        address rewardAddress;  // Ethereum 1 address which receives steth rewards for this operator
        string name;    // human-readable name
        uint64 stakingLimit;    // the maximum number of validators to stake for this operator
        uint64 stoppedValidators;   // number of signing keys which stopped validation (e.g. were slashed)

        uint64 totalSigningKeys;    // total amount of signing keys of this operator
        uint64 usedSigningKeys;     // number of signing keys of this operator which were used in deposits to the Ethereum 2
    }

    /// @dev Memory cache entry used in the assignNextKeys function
    struct DepositLookupCacheEntry {
        // Makes no sense to pack types since reading memory is as fast as any op
        uint256 id;
        uint256 stakingLimit;
        uint256 stoppedValidators;
        uint256 totalSigningKeys;
        uint256 usedSigningKeys;
        uint256 initialUsedSigningKeys;
    }

    /// @dev Mapping of all node operators. Mapping is used to be able to extend the struct.
    mapping(uint256 => NodeOperator) internal operators;

    /// @dev Total number of operators
    bytes32 internal constant TOTAL_OPERATORS_COUNT_POSITION = keccak256("lightNode.NodeOperatorsRegistry.totalOperatorsCount");

    /// @dev Cached number of active operators
    bytes32 internal constant ACTIVE_OPERATORS_COUNT_POSITION = keccak256("lightNode.NodeOperatorsRegistry.activeOperatorsCount");

    /// @dev link to the Staking contract
    bytes32 internal constant LIGHT_NODE_POSITION = keccak256("lightNode.NodeOperatorsRegistry.lightNode");

    /// @dev link to the index of operations with keys
    bytes32 internal constant KEYS_OP_INDEX_POSITION = keccak256("lightNode.NodeOperatorsRegistry.keysOpIndex");

    modifier onlyLightNode() {
        require(msg.sender == LIGHT_NODE_POSITION.getStorageAddress(), "APP_AUTH_FAILED");
        _;
    }

    modifier validAddress(address _a) {
        require(_a != address(0), "INVALID_ADDRESS");
        _;
    }

    modifier operatorExists( uint256 _id){
        require(_id < getNodeOperatorsCount(), "NODE_OPERATOT_DOESN'T EXTIST");
        _;
    }

    constructor(address _slEth) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        TOTAL_OPERATORS_COUNT_POSITION.setStorageUint256(0);
        ACTIVE_OPERATORS_COUNT_POSITION.setStorageUint256(0);
        KEYS_OP_INDEX_POSITION.setStorageUint256(0);
        LIGHT_NODE_POSITION.setStorageAddress(_slEth);
    }

    function addNodeOperator(
        string memory _name, 
        address _rewardAdd
    ) external onlyRole(ADD_NODE_OPERATOR_ROLE) validAddress(_rewardAdd) override returns(uint256 id) {
        id = getNodeOperatorsCount();
        TOTAL_OPERATORS_COUNT_POSITION.setStorageUint256(id + 1);

        NodeOperator storage operator = operators[id];
        // update active operator count
        uint256 activeOperator = getActiveNodeOperatorsCount();
        ACTIVE_OPERATORS_COUNT_POSITION.setStorageUint256(activeOperator+1);

        operator.active = true;
        operator.name = _name;
        operator.rewardAddress = _rewardAdd;
        operator.stakingLimit = 0;

        emit NodeOperatorAdded(id, _name, _rewardAdd, 0);

        return id;
    }

    function setNodeOperatorActive(uint _id, bool _active) external onlyRole(SET_NODE_OPERATOR_ACTIVE_ROLE) override operatorExists(_id){
        _increaseKeysOpIndex();

        if(operators[_id].active != _active){
            uint256 activeOperator = getActiveNodeOperatorsCount();
            if(_active){
                ACTIVE_OPERATORS_COUNT_POSITION.setStorageUint256(activeOperator + 1);
            } else{
                ACTIVE_OPERATORS_COUNT_POSITION.setStorageUint256(activeOperator - 1);
            }
        }

        operators[_id].active = _active;
        emit NodeOperatorActiveSet(_id, _active);
    }

    /**
    * @notice Change human-readable name of the node operator #`_id` to `_name`
    */
    function setNodeOperatorName(uint256 _id, string memory _name) external
        onlyRole(SET_NODE_OPERATOR_NAME_ROLE)
        operatorExists(_id) override
    {
        operators[_id].name = _name;
        emit NodeOperatorNameSet(_id, _name);
    }

    /**
    * @notice Change reward address of the node operator #`_id` to `_rewardAddress`
    */
    function setNodeOperatorRewardAddress(uint256 _id, address _rewardAddress) external
        onlyRole(SET_NODE_OPERATOR_ADDRESS_ROLE)
        operatorExists(_id)
        validAddress(_rewardAddress) override
    {
        operators[_id].rewardAddress = _rewardAddress;
        emit NodeOperatorRewardAddressSet(_id, _rewardAddress);
    }

    /**
    * @notice Report `_stoppedIncrement` more stopped validators of the node operator #`_id`
    */
    function reportStoppedValidators(uint256 _id, uint64 _stoppedIncrement) external
        onlyRole(REPORT_STOPPED_VALIDATORS_ROLE)
        operatorExists(_id) override
    {
        require(0 != _stoppedIncrement, "EMPTY_VALUE");
        operators[_id].stoppedValidators = operators[_id].stoppedValidators + (_stoppedIncrement);
        require(operators[_id].stoppedValidators <= operators[_id].usedSigningKeys, "STOPPED_MORE_THAN_LAUNCHED");

        emit NodeOperatorTotalStoppedValidatorsReported(_id, operators[_id].stoppedValidators);
    }


    /**
    * @notice Remove unused signing keys
    * @dev Function is used by the Staking contract
    */
    function trimUnusedKeys() external onlyLightNode override {
        uint256 length = getNodeOperatorsCount();
        for (uint256 operatorId = 0; operatorId < length; ++operatorId) {
            uint64 totalSigningKeys = operators[operatorId].totalSigningKeys;
            uint64 usedSigningKeys = operators[operatorId].usedSigningKeys;
            if (totalSigningKeys != usedSigningKeys) { // write only if update is needed
                operators[operatorId].totalSigningKeys = usedSigningKeys;  // discard unused keys
                emit NodeOperatorTotalKeysTrimmed(operatorId, totalSigningKeys - usedSigningKeys);
            }
        }
    }

    /**
    * @notice Add `_quantity` validator signing keys of operator #`_id` to the set of usable keys. Concatenated keys are: `_pubkeys`. Can be done by the DAO in question by using the designated rewards address.
    * @dev Along with each key the DAO has to provide a signatures for the
    *      (pubkey, withdrawal_credentials, 32000000000) message.
    *      Given that information, the contract'll be able to call
    *      deposit_contract.deposit on-chain.
    * @param _operator_id Node Operator id
    * @param _quantity Number of signing keys provided
    * @param _pubkeys Several concatenated validator signing keys
    * @param _signatures Several concatenated signatures for (pubkey, withdrawal_credentials, 32000000000) messages
    */
    function addSigningKeys(uint256 _operator_id, uint256 _quantity, bytes memory _pubkeys, bytes memory _signatures) external
        onlyRole(MANAGE_SIGNING_KEYS) override
    {
        _addSigningKeys(_operator_id, _quantity, _pubkeys, _signatures);
    }

    /**
    * @notice Add `_quantity` validator signing keys of operator #`_id` to the set of usable keys. Concatenated keys are: `_pubkeys`. Can be done by node operator in question by using the designated rewards address.
    * @dev Along with each key the DAO has to provide a signatures for the
    *      (pubkey, withdrawal_credentials, 32000000000) message.
    *      Given that information, the contract'll be able to call
    *      deposit_contract.deposit on-chain.
    * @param _operator_id Node Operator id
    * @param _quantity Number of signing keys provided
    * @param _pubkeys Several concatenated validator signing keys
    * @param _signatures Several concatenated signatures for (pubkey, withdrawal_credentials, 32000000000) messages
    */
    function addSigningKeysOperatorBH(
        uint256 _operator_id,
        uint256 _quantity,
        bytes memory _pubkeys,
        bytes memory _signatures
    )
        external override
    {
        require(msg.sender == operators[_operator_id].rewardAddress, "APP_AUTH_FAILED");
        _addSigningKeys(_operator_id, _quantity, _pubkeys, _signatures);
    }

    /**
    * @notice Removes a validator signing key #`_index` of operator #`_id` from the set of usable keys. Executed on behalf of DAO.
    * @param _operator_id Node Operator id
    * @param _index Index of the key, starting with 0
    */
    function removeSigningKey(uint256 _operator_id, uint256 _index)
        external
        onlyRole(MANAGE_SIGNING_KEYS) override
    {
        _removeSigningKey(_operator_id, _index);
    }

    /**
    * @notice Removes an #`_amount` of validator signing keys starting from #`_index` of operator #`_id` usable keys. Executed on behalf of DAO.
    * @param _operator_id Node Operator id
    * @param _index Index of the key, starting with 0
    * @param _amount Number of keys to remove
    */
    function removeSigningKeys(uint256 _operator_id, uint256 _index, uint256 _amount)
        external
        onlyRole(MANAGE_SIGNING_KEYS)
    {
        // removing from the last index to the highest one, so we won't get outside the array
        for (uint256 i = _index + _amount; i > _index ; --i) {
            _removeSigningKey(_operator_id, i - 1);
        }
    }

    /**
    * @notice Removes a validator signing key #`_index` of operator #`_id` from the set of usable keys. Executed on behalf of Node Operator.
    * @param _operator_id Node Operator id
    * @param _index Index of the key, starting with 0
    */
    function removeSigningKeyOperatorBH(uint256 _operator_id, uint256 _index) external override {
        require(msg.sender == operators[_operator_id].rewardAddress, "APP_AUTH_FAILED");
        _removeSigningKey(_operator_id, _index);
    }

    /**
    * @notice Removes an #`_amount` of validator signing keys starting from #`_index` of operator #`_id` usable keys. Executed on behalf of Node Operator.
    * @param _operator_id Node Operator id
    * @param _index Index of the key, starting with 0
    * @param _amount Number of keys to remove
    */
    function removeSigningKeysOperatorBH(uint256 _operator_id, uint256 _index, uint256 _amount) external {
        require(msg.sender == operators[_operator_id].rewardAddress, "APP_AUTH_FAILED");
        // removing from the last index to the highest one, so we won't get outside the array
        for (uint256 i = _index + _amount; i > _index ; --i) {
            _removeSigningKey(_operator_id, i - 1);
        }
    }

    /**
     * @notice Selects and returns at most `_numKeys` signing keys (as well as the corresponding
     *         signatures) from the set of active keys and marks the selected keys as used.
     *         May only be called by the Staking contract.
     *
     * @param _numKeys The number of keys to select. The actual number of selected keys may be less
     *        due to the lack of active keys.
     */
    function assignNextSigningKeys(uint256 _numKeys) external onlyLightNode returns (bytes memory pubkeys, bytes memory signatures) {
        // Memory is very cheap, although you don't want to grow it too much
        DepositLookupCacheEntry[] memory cache = _loadOperatorCache();
        if (0 == cache.length)
            return (new bytes(0), new bytes(0));

        uint256 numAssignedKeys = 0;
        DepositLookupCacheEntry memory entry;

        while (numAssignedKeys < _numKeys) {
            // Finding the best suitable operator
            uint256 bestOperatorIdx = cache.length;   // 'not found' flag
            uint256 smallestStake;
            // The loop is ligthweight comparing to an ether transfer and .deposit invocation
            for (uint256 idx = 0; idx < cache.length; ++idx) {
                entry = cache[idx];

                assert(entry.usedSigningKeys <= entry.totalSigningKeys);
                if (entry.usedSigningKeys == entry.totalSigningKeys)
                    continue;

                uint256 stake = entry.usedSigningKeys.sub(entry.stoppedValidators);
                if (stake + 1 > entry.stakingLimit)
                    continue;

                if (bestOperatorIdx == cache.length || stake < smallestStake) {
                    bestOperatorIdx = idx;
                    smallestStake = stake;
                }
            }

            if (bestOperatorIdx == cache.length)  // not found
                break;

            entry = cache[bestOperatorIdx];
            assert(entry.usedSigningKeys < UINT64_MAX);

            ++entry.usedSigningKeys;
            ++numAssignedKeys;
        }

        if (numAssignedKeys == 0) {
            return (new bytes(0), new bytes(0));
        }

        if (numAssignedKeys > 1) {
            // we can allocate without zeroing out since we're going to rewrite the whole array
            pubkeys = MemoryUtils.unSafeBytesAllocation(numAssignedKeys * PUBKEY_LENGTH);
            signatures = MemoryUtils.unSafeBytesAllocation(numAssignedKeys * SIGNATURE_LENGTH);
        }

        uint256 numLoadedKeys = 0;

        for (uint256 i = 0; i < cache.length; ++i) {
            entry = cache[i];

            if (entry.usedSigningKeys == entry.initialUsedSigningKeys) {
                continue;
            }

            operators[entry.id].usedSigningKeys = uint64(entry.usedSigningKeys);

            for (uint256 keyIndex = entry.initialUsedSigningKeys; keyIndex < entry.usedSigningKeys; ++keyIndex) {
                (bytes memory pubkey, bytes memory signature) = _loadSigningKey(entry.id, keyIndex);
                if (numAssignedKeys == 1) {
                    return (pubkey, signature);
                } else {
                    MemoryUtils.copyBytes(pubkey, pubkeys, numLoadedKeys * PUBKEY_LENGTH);
                    MemoryUtils.copyBytes(signature, signatures, numLoadedKeys * SIGNATURE_LENGTH);
                    ++numLoadedKeys;
                }
            }

            if (numLoadedKeys == numAssignedKeys) {
                break;
            }
        }

        assert(numLoadedKeys == numAssignedKeys);
        return (pubkeys, signatures);
    }

    /**
    * @notice Returns the rewards distribution proportional to the effective stake for each node operator.
    * @param _totalRewardShares Total amount of reward shares to distribute.
    */
    function getRewardsDistribution(uint256 _totalRewardShares) external override view
        returns (
            address[] memory recipients,
            uint256[] memory shares
        )
    {
        uint256 nodeOperatorCount = getNodeOperatorsCount();

        uint256 activeCount = getActiveNodeOperatorsCount();
        recipients = new address[](activeCount);
        shares = new uint256[](activeCount);
        uint256 idx = 0;

        uint256 effectiveStakeTotal = 0;
        for (uint256 operatorId = 0; operatorId < nodeOperatorCount; ++operatorId) {
            NodeOperator storage operator = operators[operatorId];
            if (!operator.active)
                continue;

            uint256 effectiveStake = operator.usedSigningKeys - (operator.stoppedValidators);
            effectiveStakeTotal = effectiveStakeTotal + (effectiveStake);

            recipients[idx] = operator.rewardAddress;
            shares[idx] = effectiveStake;

            ++idx;
        }

        if (effectiveStakeTotal == 0)
            return (recipients, shares);

        uint256 perValidatorReward = _totalRewardShares.div(effectiveStakeTotal);

        for (idx = 0; idx < activeCount; ++idx) {
            shares[idx] = shares[idx].mul(perValidatorReward);
        }

        return (recipients, shares);
    }

    /**
    * @notice Set the maximum number of validators to stake for the node operator #`_id` to `_stakingLimit`
    */
    function setNodeOperatorStakingLimit(uint256 _id, uint64 _stakingLimit) external 
        onlyRole(SET_NODE_OPERATOR_LIMIT_ROLE)
        operatorExists(_id) override
    {
        _increaseKeysOpIndex();
        operators[_id].stakingLimit = _stakingLimit;
        emit NodeOperatorStakingLimitSet(_id, _stakingLimit);
    }


    function _increaseKeysOpIndex() internal {
        uint256 keysOpIndex = getKeysOpIndex();
        KEYS_OP_INDEX_POSITION.setStorageUint256(keysOpIndex + 1);
        emit KeysOpIndexSet(keysOpIndex + 1);
    }

    //view functions
    
    /**
    * @notice Returns a monotonically increasing counter that gets incremented when any of the following happens:
    *   1. a node operator's key(s) is added;
    *   2. a node operator's key(s) is removed;
    *   3. a node operator's approved keys limit is changed.
    *   4. a node operator was activated/deactivated. Activation or deactivation of node operator
    *      might lead to usage of unvalidated keys in the assignNextSigningKeys method.
    */
    function getKeysOpIndex() public view override returns (uint256) {
        return KEYS_OP_INDEX_POSITION.getStorageUint256();
    }

    /**
    * @notice Returns total number of node operators
    */
    function getNodeOperatorsCount() public view override returns (uint256) {
        return TOTAL_OPERATORS_COUNT_POSITION.getStorageUint256();
    }

    function getActiveNodeOperatorsCount() public view returns(uint256){
        return ACTIVE_OPERATORS_COUNT_POSITION.getStorageUint256();

    }

    /**
    * @notice Returns the n-th node operator
    * @param _id Node Operator id
    * @param _fullInfo If true, name will be returned as well
    */
    function getNodeOperator(uint256 _id, bool _fullInfo) external view
        operatorExists(_id) override
        returns
        (
            bool active,
            string memory name,
            address rewardAddress,
            uint64 stakingLimit,
            uint64 stoppedValidators,
            uint64 totalSigningKeys,
            uint64 usedSigningKeys
        )
    { 
        NodeOperator storage operator = operators[_id];

        active = operator.active;
        name = _fullInfo ? operator.name : "";    // reading name is 2+ SLOADs
        rewardAddress = operator.rewardAddress;
        stakingLimit = operator.stakingLimit;
        stoppedValidators = operator.stoppedValidators;
        totalSigningKeys = operator.totalSigningKeys;
        usedSigningKeys = operator.usedSigningKeys;
    }

    /**
    * @notice Returns total number of signing keys of the node operator #`_operator_id`
    */
    function getTotalSigningKeyCount(uint256 _operator_id) external override view operatorExists(_operator_id) returns (uint256) {
        return operators[_operator_id].totalSigningKeys;
    }

    /**
      * @notice Returns number of usable signing keys of the node operator #`_operator_id`
      */
    function getUnusedSigningKeyCount(uint256 _operator_id) external override view operatorExists(_operator_id) returns (uint256) {
        return operators[_operator_id].totalSigningKeys - (operators[_operator_id].usedSigningKeys);
    }

    /**
    * @notice Returns n-th signing key of the node operator #`_operator_id`
    * @param _operator_id Node Operator id
    * @param _index Index of the key, starting with 0
    * @return key Key
    * @return depositSignature Signature needed for a deposit_contract.deposit call
    * @return used Flag indication if the key was used in the staking
    */
    function getSigningKey(uint256 _operator_id, uint256 _index) external override view
        operatorExists(_operator_id)
        returns (bytes memory key, bytes memory depositSignature, bool used)
    {
        require(_index < operators[_operator_id].totalSigningKeys, "KEY_NOT_FOUND");

        (bytes memory key_, bytes memory signature) = _loadSigningKey(_operator_id, _index);

        return (key_, signature, _index < operators[_operator_id].usedSigningKeys);
    }

    function _isEmptySigningKey(bytes memory _key) internal pure returns (bool) {
        assert(_key.length == PUBKEY_LENGTH);
        // algorithm applicability constraint
        assert(PUBKEY_LENGTH >= 32 && PUBKEY_LENGTH <= 64);

        uint256 k1;
        uint256 k2;
        assembly {
            k1 := mload(add(_key, 0x20))
            k2 := mload(add(_key, 0x40))
        }

        return 0 == k1 && 0 == (k2 >> ((2 * 32 - PUBKEY_LENGTH) * 8));
    }

    function to64(uint256 v) internal pure returns (uint64) {
        assert(v <= uint256(type(uint64).max));
        return uint64(v);
    }

    function _signingKeyOffset(uint256 _operator_id, uint256 _keyIndex) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(SIGNING_KEYS_MAPPING_NAME, _operator_id, _keyIndex)));
    }

    function _storeSigningKey(uint256 _operator_id, uint256 _keyIndex, bytes memory _key, bytes memory _signature) internal {
        assert(_key.length == PUBKEY_LENGTH);
        assert(_signature.length == SIGNATURE_LENGTH);
        // algorithm applicability constraints
        assert(PUBKEY_LENGTH >= 32 && PUBKEY_LENGTH <= 64);
        assert(0 == SIGNATURE_LENGTH % 32);

        // key
        uint256 offset = _signingKeyOffset(_operator_id, _keyIndex);
        uint256 keyExcessBits = (2 * 32 - PUBKEY_LENGTH) * 8;
        assembly {
            sstore(offset, mload(add(_key, 0x20)))
            sstore(add(offset, 1), shl(keyExcessBits, shr(keyExcessBits, mload(add(_key, 0x40)))))
        }
        offset += 2;

        // signature
        for (uint256 i = 0; i < SIGNATURE_LENGTH; i += 32) {
            assembly {
                sstore(offset, mload(add(_signature, add(0x20, i))))
            }
            offset++;
        }
    }

    function _addSigningKeys(uint256 _operator_id, uint256 _quantity, bytes memory _pubkeys, bytes memory _signatures) internal
        operatorExists(_operator_id)
    {
        require(_quantity != 0, "NO_KEYS");
        require(_pubkeys.length == _quantity.mul(PUBKEY_LENGTH), "INVALID_LENGTH");
        require(_signatures.length == _quantity.mul(SIGNATURE_LENGTH), "INVALID_LENGTH");

        _increaseKeysOpIndex();

        for (uint256 i = 0; i < _quantity; ++i) {
            bytes memory key = BytesLib.slice(_pubkeys, i * PUBKEY_LENGTH, PUBKEY_LENGTH);
            require(!_isEmptySigningKey(key), "EMPTY_KEY");
            bytes memory sig = BytesLib.slice(_signatures, i * SIGNATURE_LENGTH, SIGNATURE_LENGTH);

            _storeSigningKey(_operator_id, operators[_operator_id].totalSigningKeys + i, key, sig);
            emit SigningKeyAdded(_operator_id, key);
        }

        operators[_operator_id].totalSigningKeys = operators[_operator_id].totalSigningKeys + (to64(_quantity));
    }

    function _removeSigningKey(uint256 _operator_id, uint256 _index) internal
        operatorExists(_operator_id)
    {
        require(_index < operators[_operator_id].totalSigningKeys, "KEY_NOT_FOUND");
        require(_index >= operators[_operator_id].usedSigningKeys, "KEY_WAS_USED");

        _increaseKeysOpIndex();

        (bytes memory removedKey, ) = _loadSigningKey(_operator_id, _index);

        uint256 lastIndex = operators[_operator_id].totalSigningKeys - (1);
        if (_index < lastIndex) {
            (bytes memory key, bytes memory signature) = _loadSigningKey(_operator_id, lastIndex);
            _storeSigningKey(_operator_id, _index, key, signature);
        }

        _deleteSigningKey(_operator_id, lastIndex);
        operators[_operator_id].totalSigningKeys = operators[_operator_id].totalSigningKeys - (1);

        if (_index < operators[_operator_id].stakingLimit) {
            // decreasing the staking limit so the key at _index can't be used anymore
            operators[_operator_id].stakingLimit = uint64(_index);
        }

        emit SigningKeyRemoved(_operator_id, removedKey);
    }

    
    function _deleteSigningKey(uint256 _operator_id, uint256 _keyIndex) internal {
        uint256 offset = _signingKeyOffset(_operator_id, _keyIndex);
        for (uint256 i = 0; i < (PUBKEY_LENGTH + SIGNATURE_LENGTH) / 32 + 1; ++i) {
            assembly {
                sstore(add(offset, i), 0)
            }
        }
    }

    function _loadSigningKey(uint256 _operator_id, uint256 _keyIndex) internal view returns (bytes memory key, bytes memory signature) {
        // algorithm applicability constraints
        assert(PUBKEY_LENGTH >= 32 && PUBKEY_LENGTH <= 64);
        assert(0 == SIGNATURE_LENGTH % 32);

        uint256 offset = _signingKeyOffset(_operator_id, _keyIndex);

        // key
        bytes memory tmpKey = new bytes(64);
        assembly {
            mstore(add(tmpKey, 0x20), sload(offset))
            mstore(add(tmpKey, 0x40), sload(add(offset, 1)))
        }
        offset += 2;
        key = BytesLib.slice(tmpKey, 0, PUBKEY_LENGTH);

        // signature
        signature = new bytes(SIGNATURE_LENGTH);
        for (uint256 i = 0; i < SIGNATURE_LENGTH; i += 32) {
            assembly {
                mstore(add(signature, add(0x20, i)), sload(offset))
            }
            offset++;
        }

        return (key, signature);
    }

    function _loadOperatorCache() internal view returns (DepositLookupCacheEntry[] memory cache) {
        cache = new DepositLookupCacheEntry[](getActiveNodeOperatorsCount());
        if (0 == cache.length)
            return cache;

        uint256 totalOperators = getNodeOperatorsCount();
        uint256 idx = 0;
        for (uint256 operatorId = 0; operatorId < totalOperators; ++operatorId) {
            NodeOperator storage operator = operators[operatorId];

            if (!operator.active)
                continue;

            DepositLookupCacheEntry memory entry = cache[idx++];
            entry.id = operatorId;
            entry.stakingLimit = operator.stakingLimit;
            entry.stoppedValidators = operator.stoppedValidators;
            entry.totalSigningKeys = operator.totalSigningKeys;
            entry.usedSigningKeys = operator.usedSigningKeys;
            entry.initialUsedSigningKeys = entry.usedSigningKeys;
        }
        require(idx == cache.length, "INCOSISTENT_ACTIVE_COUNT");

        return cache;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Node Operator registry
 *
 * Node Operator registry manages signing keys and other node operator data.
 * It's also responsible for distributing rewards to node operators.
 */
interface INodeOperatorsRegistry {

    /**
     * @notice Add node operator named `name` with reward address `rewardAddress` and staking limit = 0 validators
     * @param _name Human-readable name
     * @param _rewardAddress Ethereum 1 address which receives slETH rewards for this operator
     * @return id A unique key of the added operator
     */
    function addNodeOperator(string memory _name, address _rewardAddress) external returns (uint256 id);

    /**
     * @notice `_active ? 'Enable' : 'Disable'` the node operator #`_id`
     */
    function setNodeOperatorActive(uint256 _id, bool _active) external;

    /**
     * @notice Change human-readable name of the node operator #`_id` to `_name`
     */
    function setNodeOperatorName(uint256 _id, string memory _name) external;

    /**
     * @notice Change reward address of the node operator #`_id` to `_rewardAddress`
     */
    function setNodeOperatorRewardAddress(uint256 _id, address _rewardAddress) external;

    /**
     * @notice Set the maximum number of validators to stake for the node operator #`_id` to `_stakingLimit`
     */
    function setNodeOperatorStakingLimit(uint256 _id, uint64 _stakingLimit) external;

    /**
     * @notice Report `_stoppedIncrement` more stopped validators of the node operator #`_id`
     */
    function reportStoppedValidators(uint256 _id, uint64 _stoppedIncrement) external;

    /**
     * @notice Remove unused signing keys
     * @dev Function is used by the pool
     */
    function trimUnusedKeys() external;

    /**
     * @notice Returns total number of node operators
     */
    function getNodeOperatorsCount() external view returns (uint256);

    /**
     * @notice Returns the n-th node operator
     * @param _id Node Operator id
     * @param _fullInfo If true, name will be returned as well
     */
    function getNodeOperator(uint256 _id, bool _fullInfo) external view returns (
        bool active,
        string memory name,
        address rewardAddress,
        uint64 stakingLimit,
        uint64 stoppedValidators,
        uint64 totalSigningKeys,
        uint64 usedSigningKeys);

    /**
     * @notice Returns the rewards distribution proportional to the effective stake for each node operator.
     * @param _totalRewardShares Total amount of reward shares to distribute.
     */
    function getRewardsDistribution(uint256 _totalRewardShares) external view returns (
        address[] memory recipients,
        uint256[] memory shares
    );

    event NodeOperatorAdded(uint256 id, string name, address rewardAddress, uint64 stakingLimit);
    event NodeOperatorActiveSet(uint256 indexed id, bool active);
    event NodeOperatorNameSet(uint256 indexed id, string name);
    event NodeOperatorRewardAddressSet(uint256 indexed id, address rewardAddress);
    event NodeOperatorStakingLimitSet(uint256 indexed id, uint64 stakingLimit);
    event NodeOperatorTotalStoppedValidatorsReported(uint256 indexed id, uint64 totalStopped);
    event NodeOperatorTotalKeysTrimmed(uint256 indexed id, uint64 totalKeysTrimmed);

    /**
     * @notice Selects and returns at most `_numKeys` signing keys (as well as the corresponding
     *         signatures) from the set of active keys and marks the selected keys as used.
     *         May only be called by the pool contract.
     *
     * @param _numKeys The number of keys to select. The actual number of selected keys may be less
     *        due to the lack of active keys.
     */
    function assignNextSigningKeys(uint256 _numKeys) external returns (bytes memory pubkeys, bytes memory signatures);

    /**
     * @notice Add `_quantity` validator signing keys to the keys of the node operator #`_operator_id`. Concatenated keys are: `_pubkeys`
     * @dev Along with each key the DAO has to provide a signatures for the
     *      (pubkey, withdrawal_credentials, 32000000000) message.
     *      Given that information, the contract'll be able to call
     *      deposit_contract.deposit on-chain.
     * @param _operator_id Node Operator id
     * @param _quantity Number of signing keys provided
     * @param _pubkeys Several concatenated validator signing keys
     * @param _signatures Several concatenated signatures for (pubkey, withdrawal_credentials, 32000000000) messages
     */
    function addSigningKeys(uint256 _operator_id, uint256 _quantity, bytes memory _pubkeys, bytes memory _signatures) external;

    /**
     * @notice Add `_quantity` validator signing keys of operator #`_id` to the set of usable keys. Concatenated keys are: `_pubkeys`. Can be done by node operator in question by using the designated rewards address.
     * @dev Along with each key the DAO has to provide a signatures for the
     *      (pubkey, withdrawal_credentials, 32000000000) message.
     *      Given that information, the contract'll be able to call
     *      deposit_contract.deposit on-chain.
     * @param _operator_id Node Operator id
     * @param _quantity Number of signing keys provided
     * @param _pubkeys Several concatenated validator signing keys
     * @param _signatures Several concatenated signatures for (pubkey, withdrawal_credentials, 32000000000) messages
     */
    function addSigningKeysOperatorBH(uint256 _operator_id, uint256 _quantity, bytes memory _pubkeys, bytes memory _signatures) external;

    /**
     * @notice Removes a validator signing key #`_index` from the keys of the node operator #`_operator_id`
     * @param _operator_id Node Operator id
     * @param _index Index of the key, starting with 0
     */
    function removeSigningKey(uint256 _operator_id, uint256 _index) external;

    /**
     * @notice Removes a validator signing key #`_index` of operator #`_id` from the set of usable keys. Executed on behalf of Node Operator.
     * @param _operator_id Node Operator id
     * @param _index Index of the key, starting with 0
     */
    function removeSigningKeyOperatorBH(uint256 _operator_id, uint256 _index) external;

    /**
     * @notice Returns total number of signing keys of the node operator #`_operator_id`
     */
    function getTotalSigningKeyCount(uint256 _operator_id) external view returns (uint256);

    /**
     * @notice Returns number of usable signing keys of the node operator #`_operator_id`
     */
    function getUnusedSigningKeyCount(uint256 _operator_id) external view returns (uint256);

    /**
     * @notice Returns n-th signing key of the node operator #`_operator_id`
     * @param _operator_id Node Operator id
     * @param _index Index of the key, starting with 0
     * @return key Key
     * @return depositSignature Signature needed for a deposit_contract.deposit call
     * @return used Flag indication if the key was used in the staking
     */
    function getSigningKey(uint256 _operator_id, uint256 _index) external view returns
            (bytes memory key, bytes memory depositSignature, bool used);

    /**
     * @notice Returns a monotonically increasing counter that gets incremented when any of the following happens:
     *   1. a node operator's key(s) is added;
     *   2. a node operator's key(s) is removed;
     *   3. a node operator's approved keys limit is changed.
     *   4. a node operator was activated/deactivated. Activation or deactivation of node operator
     *      might lead to usage of unvalidated keys in the assignNextSigningKeys method.
     */
    function getKeysOpIndex() external view returns (uint256);

    event SigningKeyAdded(uint256 indexed operatorId, bytes pubkey);
    event SigningKeyRemoved(uint256 indexed operatorId, bytes pubkey);
    event KeysOpIndexSet(uint256 keysOpIndex);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library UnstructuredStorage {
    function getStorageBool(bytes32 position)
        internal
        view
        returns (bool data)
    {
        assembly {
            data := sload(position)
        }
    }

    function getStorageAddress(bytes32 position)
        internal
        view
        returns (address data)
    {
        assembly {
            data := sload(position)
        }
    }

    function getStorageBytes32(bytes32 position)
        internal
        view
        returns (bytes32 data)
    {
        assembly {
            data := sload(position)
        }
    }

    function getStorageUint256(bytes32 position)
        internal
        view
        returns (uint256 data)
    {
        assembly {
            data := sload(position)
        }
    }

    function setStorageBool(bytes32 position, bool data) internal {
        assembly {
            sstore(position, data)
        }
    }

    function setStorageAddress(bytes32 position, address data) internal {
        assembly {
            sstore(position, data)
        }
    }

    function setStorageBytes32(bytes32 position, bytes32 data) internal {
        assembly {
            sstore(position, data)
        }
    }

    function setStorageUint256(bytes32 position, uint256 data) internal {
        assembly {
            sstore(position, data)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library MemoryUtils {
    /**
     * @dev Allocates a memory byte array of `_len` bytes without zeroing it out.
     */
    function unSafeBytesAllocation(uint256 _length) internal pure returns(bytes memory memoryBytes) {
        assembly{
            memoryBytes := mload(0x40)
            mstore(memoryBytes, _length)
            mstore(0x40, add(add(memoryBytes, _length),32))
        }
    }

    /**
     * @dev Performs a memory copy of `_len` bytes from position `_src` to position `_dst`.
     */
    function memorycopy(uint256 _start, uint256 _end, uint256 _length) internal pure{
        assembly{
            //while loop _length > _length
            for {} gt(_length, 31) {}{
                mstore(_end, mload(_start))
                _start := add(_start, 32)
                _end := add(_end, 32)
                _length := add(_length, 32)
            }

            if gt(_length, 0){
                let mask := sub(shl(1, mul(8, sub(32, _length))), 1)
                let startMasked := and(mload(_start), not(mask))
                let endMasked :=  and(mload(_end), mask)
                mstore(_end, or(endMasked, startMasked))
            }
        }
    }

    /**
     * @dev Copies bytes from `_src` to `_dst`, starting at position `_dstStart` into `_dst`.
     */
    function copyBytes(bytes memory _start, bytes memory _end, uint256 _endStart) internal pure {
        require(_endStart + _start.length <= _end.length, "ARRAY_OUT_OF_BOUNDS");
        uint256 intStartPos;
        uint256 endStartPos;
        assembly {
            intStartPos := add(_start, 32)
            endStartPos := add(add(_end, 32), _endStart)
        }
        memorycopy(intStartPos, endStartPos, _start.length);
    }  
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ArrConversion {
    function arr() internal pure returns (uint256[] memory) {
        return new uint256[](0);
    }

    function arr(bytes32 _a) internal pure returns (uint256[] memory r) {
        return arr(uint256(_a));
    }

    function arr(bytes32 _a, bytes32 _b)
        internal
        pure
        returns (uint256[] memory r)
    {
        return arr(uint256(_a), uint256(_b));
    }

    function arr(address _a) internal pure returns (uint256[] memory r) {
        return arr(uint160(_a));
    }

    function arr(address _a, address _b)
        internal
        pure
        returns (uint256[] memory r)
    {
        return arr(uint160(_a), uint160(_b));
    }

    function arr(
        address _a,
        uint256 _b,
        uint256 _c
    ) internal pure returns (uint256[] memory r) {
        return arr(uint160(_a), _b, _c);
    }

    function arr(
        address _a,
        uint256 _b,
        uint256 _c,
        uint256 _d
    ) internal pure returns (uint256[] memory r) {
        return arr(uint160(_a), _b, _c, _d);
    }

    function arr(address _a, uint256 _b)
        internal
        pure
        returns (uint256[] memory r)
    {
        return arr(uint160(_a), uint160(_b));
    }

    function arr(
        address _a,
        address _b,
        uint256 _c,
        uint256 _d,
        uint256 _e
    ) internal pure returns (uint256[] memory r) {
        return arr(uint160(_a), uint160(_b), _c, _d, _e);
    }

    function arr(
        address _a,
        address _b,
        address _c
    ) internal pure returns (uint256[] memory r) {
        return arr(uint160(_a), uint160(_b), uint160(_c));
    }

    function arr(
        address _a,
        address _b,
        uint256 _c
    ) internal pure returns (uint256[] memory r) {
        return arr(uint160(_a), uint160(_b), uint160(_c));
    }

    function arr(uint256 _a) internal pure returns (uint256[] memory r) {
        r = new uint256[](1);
        r[0] = _a;
    }

    function arr(uint256 _a, uint256 _b)
        internal
        pure
        returns (uint256[] memory r)
    {
        r = new uint256[](2);
        r[0] = _a;
        r[1] = _b;
    }

    function arr(
        uint256 _a,
        uint256 _b,
        uint256 _c
    ) internal pure returns (uint256[] memory r) {
        r = new uint256[](3);
        r[0] = _a;
        r[1] = _b;
        r[2] = _c;
    }

    function arr(
        uint256 _a,
        uint256 _b,
        uint256 _c,
        uint256 _d
    ) internal pure returns (uint256[] memory r) {
        r = new uint256[](4);
        r[0] = _a;
        r[1] = _b;
        r[2] = _c;
        r[3] = _d;
    }

    function arr(
        uint256 _a,
        uint256 _b,
        uint256 _c,
        uint256 _d,
        uint256 _e
    ) internal pure returns (uint256[] memory r) {
        r = new uint256[](5);
        r[0] = _a;
        r[1] = _b;
        r[2] = _c;
        r[3] = _d;
        r[4] = _e;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
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
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
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