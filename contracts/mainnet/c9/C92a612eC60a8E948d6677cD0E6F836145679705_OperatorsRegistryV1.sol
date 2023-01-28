//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./interfaces/IAdministrable.sol";

import "./libraries/LibAdministrable.sol";
import "./libraries/LibSanitize.sol";

/// @title Administrable
/// @author Kiln
/// @notice This contract handles the administration of the contracts
abstract contract Administrable is IAdministrable {
    /// @notice Prevents unauthorized calls
    modifier onlyAdmin() {
        if (msg.sender != LibAdministrable._getAdmin()) {
            revert LibErrors.Unauthorized(msg.sender);
        }
        _;
    }

    /// @notice Prevents unauthorized calls
    modifier onlyPendingAdmin() {
        if (msg.sender != LibAdministrable._getPendingAdmin()) {
            revert LibErrors.Unauthorized(msg.sender);
        }
        _;
    }

    /// @inheritdoc IAdministrable
    function getAdmin() external view returns (address) {
        return LibAdministrable._getAdmin();
    }

    /// @inheritdoc IAdministrable
    function getPendingAdmin() external view returns (address) {
        return LibAdministrable._getPendingAdmin();
    }

    /// @inheritdoc IAdministrable
    function proposeAdmin(address _newAdmin) external onlyAdmin {
        _setPendingAdmin(_newAdmin);
    }

    /// @inheritdoc IAdministrable
    function acceptAdmin() external onlyPendingAdmin {
        _setAdmin(LibAdministrable._getPendingAdmin());
        _setPendingAdmin(address(0));
    }

    /// @notice Internal utility to set the admin address
    /// @param _admin Address to set as admin
    function _setAdmin(address _admin) internal {
        LibSanitize._notZeroAddress(_admin);
        LibAdministrable._setAdmin(_admin);
        emit SetAdmin(_admin);
    }

    /// @notice Internal utility to set the pending admin address
    /// @param _pendingAdmin Address to set as pending admin
    function _setPendingAdmin(address _pendingAdmin) internal {
        LibAdministrable._setPendingAdmin(_pendingAdmin);
        emit SetPendingAdmin(_pendingAdmin);
    }

    /// @notice Internal utility to retrieve the address of the current admin
    /// @return The address of admin
    function _getAdmin() internal view returns (address) {
        return LibAdministrable._getAdmin();
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./state/shared/Version.sol";

/// @title Initializable
/// @author Kiln
/// @notice This contract ensures that initializers are called only once per version
contract Initializable {
    /// @notice An error occured during the initialization
    /// @param version The version that was attempting to be initialized
    /// @param expectedVersion The version that was expected
    error InvalidInitialization(uint256 version, uint256 expectedVersion);

    /// @notice Emitted when the contract is properly initialized
    /// @param version New version of the contracts
    /// @param cdata Complete calldata that was used during the initialization
    event Initialize(uint256 version, bytes cdata);

    /// @notice Use this modifier on initializers along with a hard-coded version number
    /// @param _version Version to initialize
    modifier init(uint256 _version) {
        if (_version != Version.get()) {
            revert InvalidInitialization(_version, Version.get());
        }
        Version.set(_version + 1); // prevents reentrency on the called method
        _;
        emit Initialize(_version, msg.data);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./interfaces/IOperatorRegistry.1.sol";

import "./libraries/LibUint256.sol";

import "./Initializable.sol";
import "./Administrable.sol";

import "./state/operatorsRegistry/Operators.sol";
import "./state/operatorsRegistry/ValidatorKeys.sol";
import "./state/shared/RiverAddress.sol";

/// @title Operators Registry (v1)
/// @author Kiln
/// @notice This contract handles the list of operators and their keys
contract OperatorsRegistryV1 is IOperatorsRegistryV1, Initializable, Administrable {
    /// @notice Maximum validators given to an operator per selection loop round
    uint256 internal constant MAX_VALIDATOR_ATTRIBUTION_PER_ROUND = 5;

    /// @inheritdoc IOperatorsRegistryV1
    function initOperatorsRegistryV1(address _admin, address _river) external init(0) {
        _setAdmin(_admin);
        RiverAddress.set(_river);
        emit SetRiver(_river);
    }

    /// @notice Prevent unauthorized calls
    modifier onlyRiver() virtual {
        if (msg.sender != RiverAddress.get()) {
            revert LibErrors.Unauthorized(msg.sender);
        }
        _;
    }

    /// @notice Prevents anyone except the admin or the given operator to make the call. Also checks if operator is active
    /// @notice The admin is able to call this method on behalf of any operator, even if inactive
    /// @param _index The index identifying the operator
    modifier onlyOperatorOrAdmin(uint256 _index) {
        if (msg.sender == _getAdmin()) {
            _;
            return;
        }
        Operators.Operator storage operator = Operators.get(_index);
        if (!operator.active) {
            revert InactiveOperator(_index);
        }
        if (msg.sender != operator.operator) {
            revert LibErrors.Unauthorized(msg.sender);
        }
        _;
    }

    /// @inheritdoc IOperatorsRegistryV1
    function getRiver() external view returns (address) {
        return RiverAddress.get();
    }

    /// @inheritdoc IOperatorsRegistryV1
    function getOperator(uint256 _index) external view returns (Operators.Operator memory) {
        return Operators.get(_index);
    }

    /// @inheritdoc IOperatorsRegistryV1
    function getOperatorCount() external view returns (uint256) {
        return Operators.getCount();
    }

    /// @inheritdoc IOperatorsRegistryV1
    function getValidator(uint256 _operatorIndex, uint256 _validatorIndex)
        external
        view
        returns (bytes memory publicKey, bytes memory signature, bool funded)
    {
        (publicKey, signature) = ValidatorKeys.get(_operatorIndex, _validatorIndex);
        funded = _validatorIndex < Operators.get(_operatorIndex).funded;
    }

    /// @inheritdoc IOperatorsRegistryV1
    function listActiveOperators() external view returns (Operators.Operator[] memory) {
        return Operators.getAllActive();
    }

    /// @inheritdoc IOperatorsRegistryV1
    function addOperator(string calldata _name, address _operator) external onlyAdmin returns (uint256) {
        Operators.Operator memory newOperator = Operators.Operator({
            active: true,
            operator: _operator,
            name: _name,
            limit: 0,
            funded: 0,
            keys: 0,
            stopped: 0,
            latestKeysEditBlockNumber: block.number
        });

        uint256 operatorIndex = Operators.push(newOperator) - 1;

        emit AddedOperator(operatorIndex, _name, _operator);
        return operatorIndex;
    }

    /// @inheritdoc IOperatorsRegistryV1
    function setOperatorAddress(uint256 _index, address _newOperatorAddress) external onlyOperatorOrAdmin(_index) {
        LibSanitize._notZeroAddress(_newOperatorAddress);
        Operators.Operator storage operator = Operators.get(_index);

        operator.operator = _newOperatorAddress;

        emit SetOperatorAddress(_index, _newOperatorAddress);
    }

    /// @inheritdoc IOperatorsRegistryV1
    function setOperatorName(uint256 _index, string calldata _newName) external onlyOperatorOrAdmin(_index) {
        LibSanitize._notEmptyString(_newName);
        Operators.Operator storage operator = Operators.get(_index);
        operator.name = _newName;

        emit SetOperatorName(_index, _newName);
    }

    /// @inheritdoc IOperatorsRegistryV1
    function setOperatorStatus(uint256 _index, bool _newStatus) external onlyAdmin {
        Operators.Operator storage operator = Operators.get(_index);
        operator.active = _newStatus;

        emit SetOperatorStatus(_index, _newStatus);
    }

    /// @inheritdoc IOperatorsRegistryV1
    function setOperatorStoppedValidatorCount(uint256 _index, uint256 _newStoppedValidatorCount) external onlyAdmin {
        Operators.Operator storage operator = Operators.get(_index);

        if (_newStoppedValidatorCount > operator.funded) {
            revert LibErrors.InvalidArgument();
        }

        operator.stopped = _newStoppedValidatorCount;

        emit SetOperatorStoppedValidatorCount(_index, _newStoppedValidatorCount);
    }

    /// @inheritdoc IOperatorsRegistryV1
    function setOperatorLimits(
        uint256[] calldata _operatorIndexes,
        uint256[] calldata _newLimits,
        uint256 _snapshotBlock
    ) external onlyAdmin {
        if (_operatorIndexes.length != _newLimits.length) {
            revert InvalidArrayLengths();
        }
        if (_operatorIndexes.length == 0) {
            revert InvalidEmptyArray();
        }
        for (uint256 idx = 0; idx < _operatorIndexes.length;) {
            uint256 operatorIndex = _operatorIndexes[idx];
            uint256 newLimit = _newLimits[idx];

            // prevents duplicates
            if (idx > 0 && !(operatorIndex > _operatorIndexes[idx - 1])) {
                revert UnorderedOperatorList();
            }

            Operators.Operator storage operator = Operators.get(operatorIndex);

            uint256 currentLimit = operator.limit;
            if (newLimit == currentLimit) {
                emit OperatorLimitUnchanged(operatorIndex, newLimit);
                unchecked {
                    ++idx;
                }
                continue;
            }

            // we enter this condition if the operator edited its keys after the off-chain key audit was made
            // we will skip any limit update on that operator unless it was a decrease in the initial limit
            if (_snapshotBlock < operator.latestKeysEditBlockNumber && newLimit > currentLimit) {
                emit OperatorEditsAfterSnapshot(
                    operatorIndex, currentLimit, newLimit, operator.latestKeysEditBlockNumber, _snapshotBlock
                    );
                unchecked {
                    ++idx;
                }
                continue;
            }

            // otherwise, we check for limit invariants that shouldn't happen if the off-chain key audit
            // was made properly, and if everything is respected, we update the limit

            if (newLimit > operator.keys) {
                revert OperatorLimitTooHigh(operatorIndex, newLimit, operator.keys);
            }

            if (newLimit < operator.funded) {
                revert OperatorLimitTooLow(operatorIndex, newLimit, operator.funded);
            }

            operator.limit = newLimit;
            emit SetOperatorLimit(operatorIndex, newLimit);

            unchecked {
                ++idx;
            }
        }
    }

    /// @inheritdoc IOperatorsRegistryV1
    function addValidators(uint256 _index, uint256 _keyCount, bytes calldata _publicKeysAndSignatures)
        external
        onlyOperatorOrAdmin(_index)
    {
        if (_keyCount == 0) {
            revert InvalidKeyCount();
        }

        if (
            _publicKeysAndSignatures.length
                != _keyCount * (ValidatorKeys.PUBLIC_KEY_LENGTH + ValidatorKeys.SIGNATURE_LENGTH)
        ) {
            revert InvalidKeysLength();
        }

        Operators.Operator storage operator = Operators.get(_index);

        for (uint256 idx = 0; idx < _keyCount;) {
            bytes memory publicKeyAndSignature = LibBytes.slice(
                _publicKeysAndSignatures,
                idx * (ValidatorKeys.PUBLIC_KEY_LENGTH + ValidatorKeys.SIGNATURE_LENGTH),
                ValidatorKeys.PUBLIC_KEY_LENGTH + ValidatorKeys.SIGNATURE_LENGTH
            );
            ValidatorKeys.set(_index, operator.keys + idx, publicKeyAndSignature);
            unchecked {
                ++idx;
            }
        }
        Operators.setKeys(_index, operator.keys + _keyCount);

        emit AddedValidatorKeys(_index, _publicKeysAndSignatures);
    }

    /// @inheritdoc IOperatorsRegistryV1
    function removeValidators(uint256 _index, uint256[] calldata _indexes) external onlyOperatorOrAdmin(_index) {
        uint256 indexesLength = _indexes.length;
        if (indexesLength == 0) {
            revert InvalidKeyCount();
        }

        Operators.Operator storage operator = Operators.get(_index);

        uint256 totalKeys = operator.keys;

        if (!(_indexes[0] < totalKeys)) {
            revert InvalidIndexOutOfBounds();
        }

        uint256 lastIndex = _indexes[indexesLength - 1];

        if (lastIndex < operator.funded) {
            revert InvalidFundedKeyDeletionAttempt();
        }

        bool limitEqualsKeyCount = operator.keys == operator.limit;
        Operators.setKeys(_index, totalKeys - indexesLength);

        uint256 idx;
        for (; idx < indexesLength;) {
            uint256 keyIndex = _indexes[idx];

            if (idx > 0 && !(keyIndex < _indexes[idx - 1])) {
                revert InvalidUnsortedIndexes();
            }

            unchecked {
                ++idx;
            }

            uint256 lastKeyIndex = totalKeys - idx;

            (bytes memory removedPublicKey,) = ValidatorKeys.get(_index, keyIndex);
            (bytes memory lastPublicKeyAndSignature) = ValidatorKeys.getRaw(_index, lastKeyIndex);
            ValidatorKeys.set(_index, keyIndex, lastPublicKeyAndSignature);
            ValidatorKeys.set(_index, lastKeyIndex, new bytes(0));

            emit RemovedValidatorKey(_index, removedPublicKey);
        }

        if (limitEqualsKeyCount) {
            operator.limit = operator.keys;
        } else if (lastIndex < operator.limit) {
            operator.limit = lastIndex;
        }
    }

    /// @inheritdoc IOperatorsRegistryV1
    function pickNextValidators(uint256 _count)
        external
        onlyRiver
        returns (bytes[] memory publicKeys, bytes[] memory signatures)
    {
        return _pickNextValidatorsFromActiveOperators(_count);
    }

    /// @notice Internal utility to concatenate bytes arrays together
    /// @param _arr1 First array
    /// @param _arr2 Second array
    /// @return The result of the concatenation of _arr1 + _arr2
    function _concatenateByteArrays(bytes[] memory _arr1, bytes[] memory _arr2)
        internal
        pure
        returns (bytes[] memory)
    {
        bytes[] memory res = new bytes[](_arr1.length + _arr2.length);
        for (uint256 idx = 0; idx < _arr1.length;) {
            res[idx] = _arr1[idx];
            unchecked {
                ++idx;
            }
        }
        for (uint256 idx = 0; idx < _arr2.length;) {
            res[idx + _arr1.length] = _arr2[idx];
            unchecked {
                ++idx;
            }
        }
        return res;
    }

    /// @notice Internal utility to verify if an operator has fundable keys during the selection process
    /// @param _operator The Operator structure in memory
    /// @return True if at least one fundable key is available
    function _hasFundableKeys(Operators.CachedOperator memory _operator) internal pure returns (bool) {
        return (_operator.funded + _operator.picked) < _operator.limit;
    }

    /// @notice Internal utility to get the count of active validators during the selection process
    /// @param _operator The Operator structure in memory
    /// @return The count of active validators for the operator
    function _getActiveKeyCount(Operators.CachedOperator memory _operator) internal pure returns (uint256) {
        return (_operator.funded + _operator.picked) - _operator.stopped;
    }

    /// @notice Internal utility to retrieve _count or lower fundable keys
    /// @dev The selection process starts by retrieving the full list of active operators with at least one fundable key.
    /// @dev
    /// @dev An operator is considered to have at least one fundable key when their staking limit is higher than their funded key count.
    /// @dev
    /// @dev    isFundable = operator.active && operator.limit > operator.funded
    /// @dev
    /// @dev The internal utility will loop on all operators and select the operator with the lowest active validator count.
    /// @dev The active validator count is computed by subtracting the stopped validator count to the funded validator count.
    /// @dev
    /// @dev    activeValidatorCount = operator.funded - operator.stopped
    /// @dev
    /// @dev During the selection process, we keep in memory all previously selected operators and the number of given validators inside a field
    /// @dev called picked that only exists on the CachedOperator structure in memory.
    /// @dev
    /// @dev    isFundable = operator.active && operator.limit > (operator.funded + operator.picked)
    /// @dev    activeValidatorCount = (operator.funded + operator.picked) - operator.stopped
    /// @dev
    /// @dev When we reach the requested key count or when all available keys are used, we perform a final loop on all the operators and extract keys
    /// @dev if any operator has a positive picked count. We then update the storage counters and return the arrays with the public keys and signatures.
    /// @param _count Amount of keys required. Contract is expected to send _count or lower.
    /// @return publicKeys An array of fundable public keys
    /// @return signatures An array of signatures linked to the public keys
    function _pickNextValidatorsFromActiveOperators(uint256 _count)
        internal
        returns (bytes[] memory publicKeys, bytes[] memory signatures)
    {
        Operators.CachedOperator[] memory operators = Operators.getAllFundable();

        if (operators.length == 0) {
            return (new bytes[](0), new bytes[](0));
        }

        while (_count > 0) {
            // loop on operators to find the first that has fundable keys, taking into account previous loop round attributions
            uint256 selectedOperatorIndex = 0;
            for (; selectedOperatorIndex < operators.length;) {
                if (_hasFundableKeys(operators[selectedOperatorIndex])) {
                    break;
                }
                unchecked {
                    ++selectedOperatorIndex;
                }
            }

            // if we reach the end, we have allocated all keys
            if (selectedOperatorIndex == operators.length) {
                break;
            }

            // we start from the next operator and we try to find one that has fundable keys but a lower (funded + picked) - stopped value
            for (uint256 idx = selectedOperatorIndex + 1; idx < operators.length;) {
                if (
                    _getActiveKeyCount(operators[idx]) < _getActiveKeyCount(operators[selectedOperatorIndex])
                        && _hasFundableKeys(operators[idx])
                ) {
                    selectedOperatorIndex = idx;
                }
                unchecked {
                    ++idx;
                }
            }

            // we take the smallest value between limit - (funded + picked), _requestedAmount and MAX_VALIDATOR_ATTRIBUTION_PER_ROUND
            uint256 pickedKeyCount = LibUint256.min(
                LibUint256.min(
                    operators[selectedOperatorIndex].limit
                        - (operators[selectedOperatorIndex].funded + operators[selectedOperatorIndex].picked),
                    MAX_VALIDATOR_ATTRIBUTION_PER_ROUND
                ),
                _count
            );

            // we update the cached picked amount
            operators[selectedOperatorIndex].picked += pickedKeyCount;

            // we update the requested amount count
            _count -= pickedKeyCount;
        }

        // we loop on all operators
        for (uint256 idx = 0; idx < operators.length; ++idx) {
            // if we picked keys on any operator, we extract the keys from storage and concatenate them in the result
            // we then update the funded value
            if (operators[idx].picked > 0) {
                (bytes[] memory _publicKeys, bytes[] memory _signatures) =
                    ValidatorKeys.getKeys(operators[idx].index, operators[idx].funded, operators[idx].picked);
                publicKeys = _concatenateByteArrays(publicKeys, _publicKeys);
                signatures = _concatenateByteArrays(signatures, _signatures);
                (Operators.get(operators[idx].index)).funded += operators[idx].picked;
            }
        }
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/// @title Administrable Interface
/// @author Kiln
/// @notice This interface exposes methods to handle the ownership of the contracts
interface IAdministrable {
    /// @notice The pending admin address changed
    /// @param pendingAdmin New pending admin address
    event SetPendingAdmin(address indexed pendingAdmin);

    /// @notice The admin address changed
    /// @param admin New admin address
    event SetAdmin(address indexed admin);

    /// @notice Retrieves the current admin address
    /// @return The admin address
    function getAdmin() external view returns (address);

    /// @notice Retrieve the current pending admin address
    /// @return The pending admin address
    function getPendingAdmin() external view returns (address);

    /// @notice Proposes a new address as admin
    /// @dev This security prevents setting an invalid address as an admin. The pending
    /// @dev admin has to claim its ownership of the contract, and prove that the new
    /// @dev address is able to perform regular transactions.
    /// @param _newAdmin New admin address
    function proposeAdmin(address _newAdmin) external;

    /// @notice Accept the transfer of ownership
    /// @dev Only callable by the pending admin. Resets the pending admin if succesful.
    function acceptAdmin() external;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../state/operatorsRegistry/Operators.sol";

/// @title Operators Registry Interface (v1)
/// @author Kiln
/// @notice This interface exposes methods to handle the list of operators and their keys
interface IOperatorsRegistryV1 {
    /// @notice A new operator has been added to the registry
    /// @param index The operator index
    /// @param name The operator display name
    /// @param operatorAddress The operator address
    event AddedOperator(uint256 indexed index, string name, address indexed operatorAddress);

    /// @notice The operator status has been changed
    /// @param index The operator index
    /// @param active True if the operator is active
    event SetOperatorStatus(uint256 indexed index, bool active);

    /// @notice The operator limit has been changed
    /// @param index The operator index
    /// @param newLimit The new operator staking limit
    event SetOperatorLimit(uint256 indexed index, uint256 newLimit);

    /// @notice The operator stopped validator count has been changed
    /// @param index The operator index
    /// @param newStoppedValidatorCount The new stopped validator count
    event SetOperatorStoppedValidatorCount(uint256 indexed index, uint256 newStoppedValidatorCount);

    /// @notice The operator address has been changed
    /// @param index The operator index
    /// @param newOperatorAddress The new operator address
    event SetOperatorAddress(uint256 indexed index, address indexed newOperatorAddress);

    /// @notice The operator display name has been changed
    /// @param index The operator index
    /// @param newName The new display name
    event SetOperatorName(uint256 indexed index, string newName);

    /// @notice The operator or the admin added new validator keys and signatures
    /// @dev The public keys and signatures are concatenated
    /// @dev A public key is 48 bytes long
    /// @dev A signature is 96 bytes long
    /// @dev [P1, S1, P2, S2, ..., PN, SN] where N is the bytes length divided by (96 + 48)
    /// @param index The operator index
    /// @param publicKeysAndSignatures The concatenated public keys and signatures
    event AddedValidatorKeys(uint256 indexed index, bytes publicKeysAndSignatures);

    /// @notice The operator or the admin removed a public key and its signature from the registry
    /// @param index The operator index
    /// @param publicKey The BLS public key that has been removed
    event RemovedValidatorKey(uint256 indexed index, bytes publicKey);

    /// @notice The stored river address has been changed
    /// @param river The new river address
    event SetRiver(address indexed river);

    /// @notice The operator edited its keys after the snapshot block
    /// @dev This means that we cannot assume that its key set is checked by the snapshot
    /// @dev This happens only if the limit was meant to be increased
    /// @param index The operator index
    /// @param currentLimit The current operator limit
    /// @param newLimit The new operator limit that was attempted to be set
    /// @param latestKeysEditBlockNumber The last block number at which the operator changed its keys
    /// @param snapshotBlock The block number of the snapshot
    event OperatorEditsAfterSnapshot(
        uint256 indexed index,
        uint256 currentLimit,
        uint256 newLimit,
        uint256 indexed latestKeysEditBlockNumber,
        uint256 indexed snapshotBlock
    );

    /// @notice The call didn't alter the limit of the operator
    /// @param index The operator index
    /// @param limit The limit of the operator
    event OperatorLimitUnchanged(uint256 indexed index, uint256 limit);

    /// @notice The calling operator is inactive
    /// @param index The operator index
    error InactiveOperator(uint256 index);

    /// @notice A funded key deletion has been attempted
    error InvalidFundedKeyDeletionAttempt();

    /// @notice The index provided are not sorted properly (descending order)
    error InvalidUnsortedIndexes();

    /// @notice The provided operator and limits array have different lengths
    error InvalidArrayLengths();

    /// @notice The provided operator and limits array are empty
    error InvalidEmptyArray();

    /// @notice The provided key count is 0
    error InvalidKeyCount();

    /// @notice The provided concatenated keys do not have the expected length
    error InvalidKeysLength();

    /// @notice The index that is removed is out of bounds
    error InvalidIndexOutOfBounds();

    /// @notice The value for the operator limit is too high
    /// @param index The operator index
    /// @param limit The new limit provided
    /// @param keyCount The operator key count
    error OperatorLimitTooHigh(uint256 index, uint256 limit, uint256 keyCount);

    /// @notice The value for the limit is too low
    /// @param index The operator index
    /// @param limit The new limit provided
    /// @param fundedKeyCount The operator funded key count
    error OperatorLimitTooLow(uint256 index, uint256 limit, uint256 fundedKeyCount);

    /// @notice The provided list of operators is not in increasing order
    error UnorderedOperatorList();

    /// @notice Initializes the operators registry
    /// @param _admin Admin in charge of managing operators
    /// @param _river Address of River system
    function initOperatorsRegistryV1(address _admin, address _river) external;

    /// @notice Retrieve the River address
    /// @return The address of River
    function getRiver() external view returns (address);

    /// @notice Get operator details
    /// @param _index The index of the operator
    /// @return The details of the operator
    function getOperator(uint256 _index) external view returns (Operators.Operator memory);

    /// @notice Get operator count
    /// @return The operator count
    function getOperatorCount() external view returns (uint256);

    /// @notice Get the details of a validator
    /// @param _operatorIndex The index of the operator
    /// @param _validatorIndex The index of the validator
    /// @return publicKey The public key of the validator
    /// @return signature The signature used during deposit
    /// @return funded True if validator has been funded
    function getValidator(uint256 _operatorIndex, uint256 _validatorIndex)
        external
        view
        returns (bytes memory publicKey, bytes memory signature, bool funded);

    /// @notice Retrieve the active operator set
    /// @return The list of active operators and their details
    function listActiveOperators() external view returns (Operators.Operator[] memory);

    /// @notice Adds an operator to the registry
    /// @dev Only callable by the administrator
    /// @param _name The name identifying the operator
    /// @param _operator The address representing the operator, receiving the rewards
    /// @return The index of the new operator
    function addOperator(string calldata _name, address _operator) external returns (uint256);

    /// @notice Changes the operator address of an operator
    /// @dev Only callable by the administrator or the previous operator address
    /// @param _index The operator index
    /// @param _newOperatorAddress The new address of the operator
    function setOperatorAddress(uint256 _index, address _newOperatorAddress) external;

    /// @notice Changes the operator name
    /// @dev Only callable by the administrator or the operator
    /// @param _index The operator index
    /// @param _newName The new operator name
    function setOperatorName(uint256 _index, string calldata _newName) external;

    /// @notice Changes the operator status
    /// @dev Only callable by the administrator
    /// @param _index The operator index
    /// @param _newStatus The new status of the operator
    function setOperatorStatus(uint256 _index, bool _newStatus) external;

    /// @notice Changes the operator stopped validator count
    /// @dev Only callable by the administrator
    /// @param _index The operator index
    /// @param _newStoppedValidatorCount The new stopped validator count of the operator
    function setOperatorStoppedValidatorCount(uint256 _index, uint256 _newStoppedValidatorCount) external;

    /// @notice Changes the operator staking limit
    /// @dev Only callable by the administrator
    /// @dev The operator indexes must be in increasing order and contain no duplicate
    /// @dev The limit cannot exceed the total key count of the operator
    /// @dev The _indexes and _newLimits must have the same length.
    /// @dev Each limit value is applied to the operator index at the same index in the _indexes array.
    /// @param _operatorIndexes The operator indexes, in increasing order and duplicate free
    /// @param _newLimits The new staking limit of the operators
    /// @param _snapshotBlock The block number at which the snapshot was computed
    function setOperatorLimits(
        uint256[] calldata _operatorIndexes,
        uint256[] calldata _newLimits,
        uint256 _snapshotBlock
    ) external;

    /// @notice Adds new keys for an operator
    /// @dev Only callable by the administrator or the operator address
    /// @param _index The operator index
    /// @param _keyCount The amount of keys provided
    /// @param _publicKeysAndSignatures Public keys of the validator, concatenated
    function addValidators(uint256 _index, uint256 _keyCount, bytes calldata _publicKeysAndSignatures) external;

    /// @notice Remove validator keys
    /// @dev Only callable by the administrator or the operator address
    /// @dev The indexes must be provided sorted in decreasing order and duplicate-free, otherwise the method will revert
    /// @dev The operator limit will be set to the lowest deleted key index if the operator's limit wasn't equal to its total key count
    /// @dev The operator or the admin cannot remove funded keys
    /// @dev When removing validators, the indexes of specific unfunded keys can be changed in order to properly
    /// @dev remove the keys from the storage array. Beware of this specific behavior when chaining calls as the
    /// @dev targeted public key indexes can point to a different key after a first call was made and performed
    /// @dev some swaps
    /// @param _index The operator index
    /// @param _indexes The indexes of the keys to remove
    function removeValidators(uint256 _index, uint256[] calldata _indexes) external;

    /// @notice Retrieve validator keys based on operator statuses
    /// @param _count Max amount of keys requested
    /// @return publicKeys An array of public keys
    /// @return signatures An array of signatures linked to the public keys
    function pickNextValidators(uint256 _count)
        external
        returns (bytes[] memory publicKeys, bytes[] memory signatures);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../state/shared/AdministratorAddress.sol";
import "../state/shared/PendingAdministratorAddress.sol";

/// @title Lib Administrable
/// @author Kiln
/// @notice This library handles the admin and pending admin storage vars
library LibAdministrable {
    /// @notice Retrieve the system admin
    /// @return The address of the system admin
    function _getAdmin() internal view returns (address) {
        return AdministratorAddress.get();
    }

    /// @notice Retrieve the pending system admin
    /// @return The adress of the pending system admin
    function _getPendingAdmin() internal view returns (address) {
        return PendingAdministratorAddress.get();
    }

    /// @notice Sets the system admin
    /// @param _admin New system admin
    function _setAdmin(address _admin) internal {
        AdministratorAddress.set(_admin);
    }

    /// @notice Sets the pending system admin
    /// @param _pendingAdmin New pending system admin
    function _setPendingAdmin(address _pendingAdmin) internal {
        PendingAdministratorAddress.set(_pendingAdmin);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/// @title Lib Basis Points
/// @notice Holds the basis points max value
library LibBasisPoints {
    /// @notice The max value for basis points (represents 100%)
    uint256 internal constant BASIS_POINTS_MAX = 10_000;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/// @title Lib Bytes
/// @notice This library helps manipulating bytes
library LibBytes {
    /// @notice The length overflows an uint
    error SliceOverflow();

    /// @notice The slice is outside of the initial bytes bounds
    error SliceOutOfBounds();

    /// @notice Slices the provided bytes
    /// @param _bytes Bytes to slice
    /// @param _start The starting index of the slice
    /// @param _length The length of the slice
    /// @return The slice of _bytes starting at _start of length _length
    function slice(bytes memory _bytes, uint256 _start, uint256 _length) internal pure returns (bytes memory) {
        unchecked {
            if (_length + 31 < _length) {
                revert SliceOverflow();
            }
        }
        if (_bytes.length < _start + _length) {
            revert SliceOutOfBounds();
        }

        bytes memory tempBytes;

        // solhint-disable-next-line no-inline-assembly
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
                } { mstore(mc, mload(cc)) }

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
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/// @title Lib Errors
/// @notice Library of common errors
library LibErrors {
    /// @notice The operator is unauthorized for the caller
    /// @param caller Address performing the call
    error Unauthorized(address caller);

    /// @notice The call was invalid
    error InvalidCall();

    /// @notice The argument was invalid
    error InvalidArgument();

    /// @notice The address is zero
    error InvalidZeroAddress();

    /// @notice The string is empty
    error InvalidEmptyString();

    /// @notice The fee is invalid
    error InvalidFee();
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./LibErrors.sol";
import "./LibBasisPoints.sol";

/// @title Lib Sanitize
/// @notice Utilities to sanitize input values
library LibSanitize {
    /// @notice Reverts if address is 0
    /// @param _address Address to check
    function _notZeroAddress(address _address) internal pure {
        if (_address == address(0)) {
            revert LibErrors.InvalidZeroAddress();
        }
    }

    /// @notice Reverts if string is empty
    /// @param _string String to check
    function _notEmptyString(string memory _string) internal pure {
        if (bytes(_string).length == 0) {
            revert LibErrors.InvalidEmptyString();
        }
    }

    /// @notice Reverts if fee is invalid
    /// @param _fee Fee to check
    function _validFee(uint256 _fee) internal pure {
        if (_fee > LibBasisPoints.BASIS_POINTS_MAX) {
            revert LibErrors.InvalidFee();
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/// @title Lib Uint256
/// @notice Utilities to perform uint operations
library LibUint256 {
    /// @notice Converts a value to little endian (64 bits)
    /// @param _value The value to convert
    /// @return result The converted value
    function toLittleEndian64(uint256 _value) internal pure returns (uint256 result) {
        result = 0;
        uint256 tempValue = _value;
        result = tempValue & 0xFF;
        tempValue >>= 8;

        result = (result << 8) | (tempValue & 0xFF);
        tempValue >>= 8;

        result = (result << 8) | (tempValue & 0xFF);
        tempValue >>= 8;

        result = (result << 8) | (tempValue & 0xFF);
        tempValue >>= 8;

        result = (result << 8) | (tempValue & 0xFF);
        tempValue >>= 8;

        result = (result << 8) | (tempValue & 0xFF);
        tempValue >>= 8;

        result = (result << 8) | (tempValue & 0xFF);
        tempValue >>= 8;

        result = (result << 8) | (tempValue & 0xFF);
        tempValue >>= 8;

        assert(0 == tempValue); // fully converted
        result <<= (24 * 8);
    }

    /// @notice Returns the minimum value
    /// @param _a First value
    /// @param _b Second value
    /// @return Smallest value between _a and _b
    function min(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return (_a > _b ? _b : _a);
    }
}

// SPDX-License-Identifier:    MIT

pragma solidity 0.8.10;

/// @title Lib Unstructured Storage
/// @notice Utilities to work with unstructured storage
library LibUnstructuredStorage {
    /// @notice Retrieve a bool value at a storage slot
    /// @param _position The storage slot to retrieve
    /// @return data The bool value
    function getStorageBool(bytes32 _position) internal view returns (bool data) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            data := sload(_position)
        }
    }

    /// @notice Retrieve an address value at a storage slot
    /// @param _position The storage slot to retrieve
    /// @return data The address value
    function getStorageAddress(bytes32 _position) internal view returns (address data) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            data := sload(_position)
        }
    }

    /// @notice Retrieve a bytes32 value at a storage slot
    /// @param _position The storage slot to retrieve
    /// @return data The bytes32 value
    function getStorageBytes32(bytes32 _position) internal view returns (bytes32 data) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            data := sload(_position)
        }
    }

    /// @notice Retrieve an uint256 value at a storage slot
    /// @param _position The storage slot to retrieve
    /// @return data The uint256 value
    function getStorageUint256(bytes32 _position) internal view returns (uint256 data) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            data := sload(_position)
        }
    }

    /// @notice Sets a bool value at a storage slot
    /// @param _position The storage slot to set
    /// @param _data The bool value to set
    function setStorageBool(bytes32 _position, bool _data) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(_position, _data)
        }
    }

    /// @notice Sets an address value at a storage slot
    /// @param _position The storage slot to set
    /// @param _data The address value to set
    function setStorageAddress(bytes32 _position, address _data) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(_position, _data)
        }
    }

    /// @notice Sets a bytes32 value at a storage slot
    /// @param _position The storage slot to set
    /// @param _data The bytes32 value to set
    function setStorageBytes32(bytes32 _position, bytes32 _data) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(_position, _data)
        }
    }

    /// @notice Sets an uint256 value at a storage slot
    /// @param _position The storage slot to set
    /// @param _data The uint256 value to set
    function setStorageUint256(bytes32 _position, uint256 _data) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(_position, _data)
        }
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibSanitize.sol";

/// @title Operators Storage
/// @notice Utility to manage the Operators in storage
library Operators {
    /// @notice Storage slot of the Operators
    bytes32 internal constant OPERATORS_SLOT = bytes32(uint256(keccak256("river.state.operators")) - 1);

    /// @notice The Operator structure in storage
    struct Operator {
        /// @custom:attribute True if the operator is active and allowed to operate on River
        bool active;
        /// @custom:attribute Display name of the operator
        string name;
        /// @custom:attribute Address of the operator
        address operator;
        /// @dev The following values respect this invariant:
        /// @dev     keys >= limit >= funded >= stopped

        /// @custom:attribute Staking limit of the operator
        uint256 limit;
        /// @custom:attribute The count of funded validators
        uint256 funded;
        /// @custom:attribute The total count of keys of the operator
        uint256 keys;
        /// @custom:attribute The count of stopped validators. Stopped validators are validators
        ///                   that exited the consensus layer (voluntary or slashed)
        uint256 stopped;
        uint256 latestKeysEditBlockNumber;
    }

    /// @notice The Operator structure when loaded in memory
    struct CachedOperator {
        /// @custom:attribute True if the operator is active and allowed to operate on River
        bool active;
        /// @custom:attribute Display name of the operator
        string name;
        /// @custom:attribute Address of the operator
        address operator;
        /// @custom:attribute Staking limit of the operator
        uint256 limit;
        /// @custom:attribute The count of funded validators
        uint256 funded;
        /// @custom:attribute The total count of keys of the operator
        uint256 keys;
        /// @custom:attribute The count of stopped validators
        uint256 stopped;
        /// @custom:attribute The count of stopped validators. Stopped validators are validators
        ///                   that exited the consensus layer (voluntary or slashed)
        uint256 index;
        /// @custom:attribute The amount of picked keys, buffer used before changing funded in storage
        uint256 picked;
    }

    /// @notice The structure at the storage slot
    struct SlotOperator {
        /// @custom:attribute Array containing all the operators
        Operator[] value;
    }

    /// @notice The operator was not found
    /// @param index The provided index
    error OperatorNotFound(uint256 index);

    /// @notice Retrieve the operator in storage
    /// @param _index The index of the operator
    /// @return The Operator structure
    function get(uint256 _index) internal view returns (Operator storage) {
        bytes32 slot = OPERATORS_SLOT;

        SlotOperator storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        if (r.value.length <= _index) {
            revert OperatorNotFound(_index);
        }

        return r.value[_index];
    }

    /// @notice Retrieve the operator count in storage
    /// @return The count of operators in storage
    function getCount() internal view returns (uint256) {
        bytes32 slot = OPERATORS_SLOT;

        SlotOperator storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        return r.value.length;
    }

    /// @notice Retrieve all the active operators
    /// @return The list of active operator structures
    function getAllActive() internal view returns (Operator[] memory) {
        bytes32 slot = OPERATORS_SLOT;

        SlotOperator storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        uint256 activeCount = 0;
        uint256 operatorCount = r.value.length;

        for (uint256 idx = 0; idx < operatorCount;) {
            if (r.value[idx].active) {
                unchecked {
                    ++activeCount;
                }
            }
            unchecked {
                ++idx;
            }
        }

        Operator[] memory activeOperators = new Operator[](activeCount);

        uint256 activeIdx = 0;
        for (uint256 idx = 0; idx < operatorCount;) {
            if (r.value[idx].active) {
                activeOperators[activeIdx] = r.value[idx];
                unchecked {
                    ++activeIdx;
                }
            }
            unchecked {
                ++idx;
            }
        }

        return activeOperators;
    }

    /// @notice Retrieve all the active and fundable operators
    /// @return The list of active and fundable operators
    function getAllFundable() internal view returns (CachedOperator[] memory) {
        bytes32 slot = OPERATORS_SLOT;

        SlotOperator storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        uint256 activeCount = 0;
        uint256 operatorCount = r.value.length;

        for (uint256 idx = 0; idx < operatorCount;) {
            if (_hasFundableKeys(r.value[idx])) {
                unchecked {
                    ++activeCount;
                }
            }
            unchecked {
                ++idx;
            }
        }

        CachedOperator[] memory activeOperators = new CachedOperator[](activeCount);

        uint256 activeIdx = 0;
        for (uint256 idx = 0; idx < operatorCount;) {
            Operator memory op = r.value[idx];
            if (_hasFundableKeys(op)) {
                activeOperators[activeIdx] = CachedOperator({
                    active: op.active,
                    name: op.name,
                    operator: op.operator,
                    limit: op.limit,
                    funded: op.funded,
                    keys: op.keys,
                    stopped: op.stopped,
                    index: idx,
                    picked: 0
                });
                unchecked {
                    ++activeIdx;
                }
            }
            unchecked {
                ++idx;
            }
        }

        return activeOperators;
    }

    /// @notice Add a new operator in storage
    /// @param _newOperator Value of the new operator
    /// @return The size of the operator array after the operation
    function push(Operator memory _newOperator) internal returns (uint256) {
        LibSanitize._notZeroAddress(_newOperator.operator);
        LibSanitize._notEmptyString(_newOperator.name);
        bytes32 slot = OPERATORS_SLOT;

        SlotOperator storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        r.value.push(_newOperator);

        return r.value.length;
    }

    /// @notice Atomic operation to set the key count and update the latestKeysEditBlockNumber field at the same time
    /// @param _index The operator index
    /// @param _newKeys The new value for the key count
    function setKeys(uint256 _index, uint256 _newKeys) internal {
        Operator storage op = get(_index);

        op.keys = _newKeys;
        op.latestKeysEditBlockNumber = block.number;
    }

    /// @notice Checks if an operator is active and has fundable keys
    /// @param _operator The operator details
    /// @return True if active and fundable
    function _hasFundableKeys(Operators.Operator memory _operator) internal pure returns (bool) {
        return (_operator.active && _operator.limit > _operator.funded);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibBytes.sol";

/// @title Validator Keys Storage
/// @notice Utility to manage the validator keys in storage
library ValidatorKeys {
    /// @notice Storage slot of the Validator Keys
    bytes32 internal constant VALIDATOR_KEYS_SLOT = bytes32(uint256(keccak256("river.state.validatorKeys")) - 1);

    /// @notice Length in bytes of a BLS Public Key used for validator deposits
    uint256 internal constant PUBLIC_KEY_LENGTH = 48;

    /// @notice Length in bytes of a BLS Signature used for validator deposits
    uint256 internal constant SIGNATURE_LENGTH = 96;

    /// @notice The provided public key is not matching the expected length
    error InvalidPublicKey();

    /// @notice The provided signature is not matching the expected length
    error InvalidSignature();

    /// @notice Structure of the Validator Keys in storage
    struct Slot {
        /// @custom:attribute The mapping from operator index to key index to key value
        mapping(uint256 => mapping(uint256 => bytes)) value;
    }

    /// @notice Retrieve the Validator Key of an operator at a specific index
    /// @param _operatorIndex The operator index
    /// @param _idx the Validator Key index
    /// @return publicKey The Validator Key public key
    /// @return signature The Validator Key signature
    function get(uint256 _operatorIndex, uint256 _idx)
        internal
        view
        returns (bytes memory publicKey, bytes memory signature)
    {
        bytes32 slot = VALIDATOR_KEYS_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        bytes storage entry = r.value[_operatorIndex][_idx];

        publicKey = LibBytes.slice(entry, 0, PUBLIC_KEY_LENGTH);
        signature = LibBytes.slice(entry, PUBLIC_KEY_LENGTH, SIGNATURE_LENGTH);
    }

    /// @notice Retrieve the raw concatenated Validator Keys
    /// @param _operatorIndex The operator index
    /// @param _idx The Validator Key index
    /// @return The concatenated public key and signature
    function getRaw(uint256 _operatorIndex, uint256 _idx) internal view returns (bytes memory) {
        bytes32 slot = VALIDATOR_KEYS_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        return r.value[_operatorIndex][_idx];
    }

    /// @notice Retrieve multiple keys of an operator starting at an index
    /// @param _operatorIndex The operator index
    /// @param _startIdx The starting index to retrieve the keys from
    /// @param _amount The amount of keys to retrieve
    /// @return publicKeys The public keys retrieved
    /// @return signatures The signatures associated with the public keys
    function getKeys(uint256 _operatorIndex, uint256 _startIdx, uint256 _amount)
        internal
        view
        returns (bytes[] memory publicKeys, bytes[] memory signatures)
    {
        publicKeys = new bytes[](_amount);
        signatures = new bytes[](_amount);

        bytes32 slot = VALIDATOR_KEYS_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }
        uint256 idx;
        for (; idx < _amount;) {
            bytes memory rawCredentials = r.value[_operatorIndex][idx + _startIdx];
            publicKeys[idx] = LibBytes.slice(rawCredentials, 0, PUBLIC_KEY_LENGTH);
            signatures[idx] = LibBytes.slice(rawCredentials, PUBLIC_KEY_LENGTH, SIGNATURE_LENGTH);
            unchecked {
                ++idx;
            }
        }
    }

    /// @notice Set the concatenated Validator Keys at an index for an operator
    /// @param _operatorIndex The operator index
    /// @param _idx The key index to write on
    /// @param _publicKeyAndSignature The concatenated Validator Keys
    function set(uint256 _operatorIndex, uint256 _idx, bytes memory _publicKeyAndSignature) internal {
        bytes32 slot = VALIDATOR_KEYS_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        r.value[_operatorIndex][_idx] = _publicKeyAndSignature;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../../libraries/LibUnstructuredStorage.sol";
import "../../libraries/LibSanitize.sol";

/// @title Administrator Address Storage
/// @notice Utility to manage the Administrator Address in storage
library AdministratorAddress {
    /// @notice Storage slot of the Administrator Address
    bytes32 public constant ADMINISTRATOR_ADDRESS_SLOT =
        bytes32(uint256(keccak256("river.state.administratorAddress")) - 1);

    /// @notice Retrieve the Administrator Address
    /// @return The Administrator Address
    function get() internal view returns (address) {
        return LibUnstructuredStorage.getStorageAddress(ADMINISTRATOR_ADDRESS_SLOT);
    }

    /// @notice Sets the Administrator Address
    /// @param _newValue New Administrator Address
    function set(address _newValue) internal {
        LibSanitize._notZeroAddress(_newValue);
        LibUnstructuredStorage.setStorageAddress(ADMINISTRATOR_ADDRESS_SLOT, _newValue);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../../libraries/LibUnstructuredStorage.sol";

/// @title Pending Administrator Address Storage
/// @notice Utility to manage the Pending Administrator Address in storage
library PendingAdministratorAddress {
    /// @notice Storage slot of the Pending Administrator Address
    bytes32 public constant PENDING_ADMINISTRATOR_ADDRESS_SLOT =
        bytes32(uint256(keccak256("river.state.pendingAdministratorAddress")) - 1);

    /// @notice Retrieve the Pending Administrator Address
    /// @return The Pending Administrator Address
    function get() internal view returns (address) {
        return LibUnstructuredStorage.getStorageAddress(PENDING_ADMINISTRATOR_ADDRESS_SLOT);
    }

    /// @notice Sets the Pending Administrator Address
    /// @param _newValue New Pending Administrator Address
    function set(address _newValue) internal {
        LibUnstructuredStorage.setStorageAddress(PENDING_ADMINISTRATOR_ADDRESS_SLOT, _newValue);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibSanitize.sol";
import "../../libraries/LibUnstructuredStorage.sol";

/// @title River Address Storage
/// @notice Utility to manage the River Address in storage
library RiverAddress {
    /// @notice Storage slot of the River Address
    bytes32 internal constant RIVER_ADDRESS_SLOT = bytes32(uint256(keccak256("river.state.riverAddress")) - 1);

    /// @notice Retrieve the River Address
    /// @return The River Address
    function get() internal view returns (address) {
        return LibUnstructuredStorage.getStorageAddress(RIVER_ADDRESS_SLOT);
    }

    /// @notice Sets the River Address
    /// @param _newValue New River Address
    function set(address _newValue) internal {
        LibSanitize._notZeroAddress(_newValue);
        LibUnstructuredStorage.setStorageAddress(RIVER_ADDRESS_SLOT, _newValue);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibUnstructuredStorage.sol";

/// @title Version Storage
/// @notice Utility to manage the Version in storage
library Version {
    /// @notice Storage slot of the Version
    bytes32 public constant VERSION_SLOT = bytes32(uint256(keccak256("river.state.version")) - 1);

    /// @notice Retrieve the Version
    /// @return The Version
    function get() internal view returns (uint256) {
        return LibUnstructuredStorage.getStorageUint256(VERSION_SLOT);
    }

    /// @notice Sets the Version
    /// @param _newValue New Version
    function set(uint256 _newValue) internal {
        LibUnstructuredStorage.setStorageUint256(VERSION_SLOT, _newValue);
    }
}