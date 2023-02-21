// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import './library/Address.sol';
import './library/ValidatorStatus.sol';
import './interfaces/IVaultFactory.sol';
import './interfaces/IPoolSelector.sol';
import './interfaces/IPoolFactory.sol';
import './interfaces/INodeRegistry.sol';
import './interfaces/IPermissionlessPool.sol';
import './interfaces/SDCollateral/ISDCollateral.sol';
import './interfaces/IPermissionlessNodeRegistry.sol';

import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';

contract PermissionlessNodeRegistry is
    INodeRegistry,
    IPermissionlessNodeRegistry,
    AccessControlUpgradeable,
    PausableUpgradeable
{
    uint8 public constant override poolId = 1;
    uint64 private constant pubkey_LENGTH = 48;
    uint64 private constant SIGNATURE_LENGTH = 96;

    address public poolFactoryAddress;
    address public override vaultFactoryAddress;
    address public override sdCollateral;
    address public override elRewardSocializePool;
    address public override permissionlessPool;
    address public override staderInsuranceFund;

    uint256 public override nextOperatorId;
    uint256 public override nextValidatorId;
    uint256 public override validatorQueueSize;
    uint256 public override nextQueuedValidatorIndex;
    uint256 public override totalInitializedValidatorCount;
    uint256 public override totalQueuedValidatorCount;
    uint256 public override totalActiveValidatorCount;
    uint256 public override totalWithdrawnValidatorCount;
    uint256 public constant override PRE_DEPOSIT = 1 ether;
    uint256 public constant override FRONT_RUN_PENALTY = 3 ether;
    uint256 public constant override collateralETH = 4 ether;

    uint256 public constant override OPERATOR_MAX_NAME_LENGTH = 255;

    bytes32 public constant override PERMISSIONLESS_POOL = keccak256('PERMISSIONLESS_POOL');
    bytes32 public constant override STADER_ORACLE = keccak256('STADER_ORACLE');
    bytes32 public constant override VALIDATOR_STATUS_ROLE = keccak256('VALIDATOR_STATUS_ROLE');
    bytes32 public constant override STADER_MANAGER_BOT = keccak256('STADER_MANAGER_BOT');

    bytes32 public constant override PERMISSIONLESS_NODE_REGISTRY_OWNER =
        keccak256('PERMISSIONLESS_NODE_REGISTRY_OWNER');

    // mapping of validator Id and Validator struct
    mapping(uint256 => Validator) public override validatorRegistry;
    // mapping of validator public key and validator Id
    mapping(bytes => uint256) public override validatorIdByPubkey;
    // Queued Validator queue
    mapping(uint256 => uint256) public override queuedValidators;
    // mapping of operator Id and Operator struct
    mapping(uint256 => Operator) public override operatorStructById;
    // mapping of operator address and operator Id
    mapping(address => uint256) public override operatorIDByAddress;
    // timestamp when operator opted for socializing pool
    mapping(uint256 => uint256) public override socializingPoolStateChangeTimestamp; 

    /**
     * @dev Stader Staking Pool validator registry is initialized with following variables
     */
    function initialize(
        address _adminOwner,
        address _staderInsuranceFund,
        address _vaultFactoryAddress,
        address _elRewardSocializePool,
        address _poolFactoryAddress
    ) external initializer {
        Address.checkNonZeroAddress(_adminOwner);
        Address.checkNonZeroAddress(_staderInsuranceFund);
        Address.checkNonZeroAddress(_vaultFactoryAddress);
        Address.checkNonZeroAddress(_elRewardSocializePool);
        Address.checkNonZeroAddress(_poolFactoryAddress);
        __AccessControl_init_unchained();
        __Pausable_init();
        staderInsuranceFund = _staderInsuranceFund;
        vaultFactoryAddress = _vaultFactoryAddress;
        elRewardSocializePool = _elRewardSocializePool;
        poolFactoryAddress = _poolFactoryAddress;
        nextOperatorId = 1;
        nextValidatorId = 1;
        _grantRole(DEFAULT_ADMIN_ROLE, _adminOwner);
    }

    /**
     * @notice onboard a node operator
     * @dev any one call, permissionless
     * @param _optInForMevSocialize opted in or not to socialize mev and priority fee
     * @param _operatorName name of operator
     * @param _operatorRewardAddress eth1 address of operator to get rewards and withdrawals
     * @return mevFeeRecipientAddress fee recipient address for all validator clients
     */
    function onboardNodeOperator(
        bool _optInForMevSocialize,
        string calldata _operatorName,
        address payable _operatorRewardAddress
    ) external override whenNotPaused returns (address mevFeeRecipientAddress) {
        _onlyValidName(_operatorName);
        Address.checkNonZeroAddress(_operatorRewardAddress);

        uint256 operatorId = operatorIDByAddress[msg.sender];
        if (operatorId != 0) revert OperatorAlreadyOnBoarded();

        mevFeeRecipientAddress = elRewardSocializePool;
        if (!_optInForMevSocialize) {
            mevFeeRecipientAddress = IVaultFactory(vaultFactoryAddress).deployNodeELRewardVault(
                poolId,
                nextOperatorId,
                payable(_operatorRewardAddress)
            );
        }
        _onboardOperator(_optInForMevSocialize, _operatorName, _operatorRewardAddress);
        return mevFeeRecipientAddress;
    }

    /**
     * @notice add signing keys
     * @dev only accepts if bond of 4 ETH provided along with sufficient SD lockup
     * @param _validatorpubkey public key of validators
     * @param _validatorSignature signature of a validators
     */
    function addValidatorKeys(bytes[] calldata _validatorpubkey, bytes[] calldata _validatorSignature)
        external
        payable
        override
        whenNotPaused
    {
        uint256 operatorId = _onlyOnboardedOperator(msg.sender);
        if (_validatorpubkey.length != _validatorSignature.length) revert InvalidSizeOfInputKeys();

        uint256 keyCount = _validatorpubkey.length;
        if (keyCount == 0) revert NoKeysProvided();

        if (msg.value != keyCount * collateralETH) revert InvalidBondEthValue();

        Operator storage operator = operatorStructById[operatorId];

        uint256 totalNonWithdrawnKeys = this.getOperatorTotalKeys(msg.sender) - operator.withdrawnValidatorCount;

        //check if operator has enough SD collateral for adding `keyCount` keys
        ISDCollateral(sdCollateral).hasEnoughXSDCollateral(msg.sender, poolId, totalNonWithdrawnKeys + keyCount);

        for (uint256 i = 0; i < keyCount; i++) {
            _addValidatorKey(_validatorpubkey[i], _validatorSignature[i], operatorId);
        }
        totalInitializedValidatorCount += keyCount;
        _increaseInitializedValidatorCount(operator, keyCount);
    }

    /**
     * @notice move validator state from INITIALIZE to PRE_DEPOSIT after receiving pre-signed messages for withdrawal
     * @dev only admin can call
     * @param _pubkeys array of pubkeys ready to be moved to PRE_DEPOSIT state
     */
    function markValidatorReadyToDeposit(bytes[] calldata _pubkeys)
        external
        override
        whenNotPaused
        onlyRole(STADER_MANAGER_BOT)
    {
        uint256 inputSize = _pubkeys.length;
        for (uint256 i = 0; i < inputSize; i++) {
            uint256 validatorId = validatorIdByPubkey[_pubkeys[i]];
            if (validatorId == 0) revert pubkeyDoesNotExist();
            _markKeyReadyToDeposit(validatorId);
            emit ValidatorMarkedReadyToDeposit(_pubkeys[i], validatorId);
        }
        totalInitializedValidatorCount -= inputSize;
        totalQueuedValidatorCount += inputSize;
    }

    /**
     * @notice reports the front running validator
     * @dev only stader DAO can call
     * @param _validatorIds array of validator IDs which got front running deposit
     */
    function reportFrontRunValidators(uint256[] calldata _validatorIds) external onlyRole(STADER_ORACLE) {
        uint256 inputSize = _validatorIds.length;
        for (uint256 i = 0; i < inputSize; i++) {
            _handleFrontRun(_validatorIds[i]);
        }
        totalInitializedValidatorCount -= inputSize;
        totalWithdrawnValidatorCount += inputSize;
    }

    /**
     * @notice reduce the queued validator count and increase active validator count for a operator
     * @dev only accept call from permissionless pool contract
     * @param _operatorId operator ID
     */
    function updateQueuedAndActiveValidatorsCount(uint256 _operatorId) external override onlyRole(PERMISSIONLESS_POOL) {
        _updateQueuedAndActiveValidatorsCount(_operatorId);
    }

    /**
     * @notice reduce the active validator count and increase withdrawn validator count for a operator
     * @dev only accept call from accounts having `STADER_ORACLE` role
     * @param _operatorId operator ID
     */
    function updateActiveAndWithdrawnValidatorsCount(uint256 _operatorId) external override onlyRole(STADER_ORACLE) {
        _updateActiveAndWithdrawnValidatorsCount(_operatorId);
    }

    /**
     * @notice update the next queued validator index by a count
     * @dev accept call from permissionless pool
     * @param _count count of validators picked from queue, nextIndex after `_count`
     */
    function updateNextQueuedValidatorIndex(uint256 _count) external onlyRole(PERMISSIONLESS_POOL) {
        nextQueuedValidatorIndex += _count;
        emit UpdatedNextQueuedValidatorIndex(nextQueuedValidatorIndex);
    }

    function changeSocializingPoolState(bool _optedForSocializingPool) external {
        _onlyOnboardedOperator(msg.sender);
        uint256 operatorId = operatorIDByAddress[msg.sender];
        require(operatorStructById[operatorId].optedForSocializingPool != _optedForSocializingPool, "No change in state");

        operatorStructById[operatorId].optedForSocializingPool = _optedForSocializingPool;
        socializingPoolStateChangeTimestamp[operatorId] = block.timestamp;
        emit UpdatedSocializingPoolState(operatorId, _optedForSocializingPool, block.timestamp);
    }

    /**
     * @notice get the total deposited keys for an operator
     * @dev add initialized, queued, active and withdrawn validator key count to get total validators keys
     * @param _nodeOperator address of node operator
     */
    function getOperatorTotalNonWithdrawnKeys(address _nodeOperator)
        external
        view
        override
        returns (uint256 _totalKeys)
    {
        uint256 operatorId = operatorIDByAddress[_nodeOperator];
        Operator memory operator = operatorStructById[operatorId];
        _totalKeys = operator.initializedValidatorCount + operator.queuedValidatorCount + operator.activeValidatorCount;
    }

    /**
     * @notice get the total non withdrawn keys for an operator
     * @dev add initialized, queued and active validator key count to get total validators keys
     * @param _nodeOperator address of node operator
     */
    function getOperatorTotalKeys(address _nodeOperator) external view override returns (uint256 _totalKeys) {
        uint256 operatorId = operatorIDByAddress[_nodeOperator];
        _totalKeys =
            operatorStructById[operatorId].initializedValidatorCount +
            operatorStructById[operatorId].queuedValidatorCount +
            operatorStructById[operatorId].activeValidatorCount +
            operatorStructById[operatorId].withdrawnValidatorCount;
    }

    /**
     * @notice transfer the `_amount` to permissionless pool
     * @dev only permissionless pool can call
     * @param _amount amount of eth to send to permissionless pool
     */
    //TODO decide on the role name
    function transferCollateralToPool(uint256 _amount) external override whenNotPaused onlyRole(PERMISSIONLESS_POOL) {
        (, address poolAddress) = IPoolFactory(poolFactoryAddress).pools(poolId);
        _sendValue(poolAddress, _amount);
    }

    /**
     * @notice update the status of a validator
     * @dev only oracle can call
     * @param _pubkey public key of the validator
     * @param _status updated status of validator
     */
    function updateValidatorStatus(bytes calldata _pubkey, ValidatorStatus _status)
        external
        override
        onlyRole(VALIDATOR_STATUS_ROLE)
    {
        uint256 validatorId = validatorIdByPubkey[_pubkey];
        if (validatorId == 0) revert pubkeyDoesNotExist();
        validatorRegistry[validatorId].status = _status;
    }

    /**
     * @notice updates the address of pool factory
     * @dev only NOs registry can call
     * @param _poolFactoryAddress address of pool factory
     */
    function updatePoolFactoryAddress(address _poolFactoryAddress)
        external
        override
        onlyRole(PERMISSIONLESS_NODE_REGISTRY_OWNER)
    {
        Address.checkNonZeroAddress(_poolFactoryAddress);
        poolFactoryAddress = _poolFactoryAddress;
        emit UpdatedPoolFactoryAddress(poolFactoryAddress);
    }

    /**
     * @notice update the address of vault factory
     * @dev only admin can call
     * @param _vaultFactoryAddress address of vault factory
     */
    function updateVaultFactoryAddress(address _vaultFactoryAddress)
        external
        override
        onlyRole(PERMISSIONLESS_NODE_REGISTRY_OWNER)
    {
        Address.checkNonZeroAddress(_vaultFactoryAddress);
        vaultFactoryAddress = _vaultFactoryAddress;
        emit UpdatedVaultFactoryAddress(_vaultFactoryAddress);
    }

    function updatePermissionlessPoolAddress(address _permissionlessPool)
        external
        override
        onlyRole(PERMISSIONLESS_NODE_REGISTRY_OWNER)
    {
        Address.checkNonZeroAddress(_permissionlessPool);
        permissionlessPool = _permissionlessPool;
        emit UpdatedPermissionlessPoolAddress(permissionlessPool);
    }

    /**
     * @notice update the name and reward address of an operator
     * @dev only operator msg.sender can update
     * @param _operatorName new Name of the operator
     * @param _rewardAddress new reward address
     */
    function updateOperatorDetails(string calldata _operatorName, address payable _rewardAddress) external override {
        _onlyValidName(_operatorName);
        Address.checkNonZeroAddress(_rewardAddress);

        _onlyOnboardedOperator(msg.sender);
        uint256 operatorId = operatorIDByAddress[msg.sender];
        operatorStructById[operatorId].operatorName = _operatorName;
        operatorStructById[operatorId].operatorRewardAddress = _rewardAddress;
        emit UpdatedOperatorDetails(msg.sender, _operatorName, _rewardAddress);
    }

    /**
     * @notice return total queued keys for permissionless pool
     * @return _validatorCount total queued validator count
     */
    function getTotalQueuedValidatorCount() public view override returns (uint256) {
        return totalQueuedValidatorCount;
    }

    /**
     * @notice return total active keys for permissionless pool
     * @return _validatorCount total active validator count
     */
    function getTotalActiveValidatorCount() public view override returns (uint256) {
        return totalActiveValidatorCount;
    }

    /**
     * @dev Triggers stopped state.
     * should not be paused
     */
    function pause() external override onlyRole(PERMISSIONLESS_NODE_REGISTRY_OWNER) {
        _pause();
    }

    /**
     * @dev Returns to normal state.
     * should not be paused
     */
    function unpause() external override onlyRole(PERMISSIONLESS_NODE_REGISTRY_OWNER) {
        _unpause();
    }

    function getAllActiveValidators() public view override returns (Validator[] memory) {
        Validator[] memory validators = new Validator[](this.getTotalActiveValidatorCount());
        uint256 validatorCount = 0;
        for (uint256 i = 1; i < nextValidatorId; i++) {
            if (_isActiveValidator(i)) {
                validators[validatorCount] = validatorRegistry[i];
                validatorCount++;
            }
        }
        return validators;
    }

    function getValidator(bytes memory _pubkey) external view returns (Validator memory) {
        return validatorRegistry[validatorIdByPubkey[_pubkey]];
    }

    function getValidator(uint256 _validatorId) external view returns (Validator memory) {
        return validatorRegistry[_validatorId];
    }

    function _onboardOperator(
        bool _optInForMevSocialize,
        string calldata _operatorName,
        address payable _operatorRewardAddress
    ) internal {
        operatorStructById[nextOperatorId] = Operator(
            true,
            _optInForMevSocialize,
            _operatorName,
            _operatorRewardAddress,
            msg.sender,
            0,
            0,
            0,
            0
        );
        operatorIDByAddress[msg.sender] = nextOperatorId;
        nextOperatorId++;
        emit OnboardedOperator(msg.sender, nextOperatorId - 1);
    }

    function _addValidatorKey(
        bytes calldata _pubkey,
        bytes calldata _signature,
        uint256 _operatorId
    ) internal {
        uint256 totalKeys = this.getOperatorTotalKeys(msg.sender);
        _validateKeys(_pubkey, _signature);
        address withdrawVault = IVaultFactory(vaultFactoryAddress).deployWithdrawVault(poolId, _operatorId, totalKeys);
        validatorRegistry[nextValidatorId] = Validator(
            ValidatorStatus.INITIALIZED,
            false,
            _pubkey,
            _signature,
            withdrawVault,
            _operatorId,
            collateralETH
        );

        //slither-disable-next-line arbitrary-send-eth
        IPermissionlessPool(permissionlessPool).preDepositOnBeacon{value: PRE_DEPOSIT}(
            _pubkey,
            _signature,
            withdrawVault
        );
        validatorIdByPubkey[_pubkey] = nextValidatorId;
        nextValidatorId++;
        emit AddedKeys(msg.sender, _pubkey, nextValidatorId - 1);
    }

    function _markKeyReadyToDeposit(uint256 _validatorId) internal {
        validatorRegistry[_validatorId].status = ValidatorStatus.PRE_DEPOSIT;
        queuedValidators[validatorQueueSize] = _validatorId;
        uint256 operatorId = validatorRegistry[_validatorId].operatorId;
        _updateInitializedAndQueuedValidatorCount(operatorId);
        validatorQueueSize++;
    }

    function _handleFrontRun(uint256 _validatorId) internal {
        Validator storage validator = validatorRegistry[_validatorId];
        validator.isFrontRun = true;
        _updateInitializedAndWithdrawnValidatorCount(validator.operatorId);
        _sendValue(staderInsuranceFund, FRONT_RUN_PENALTY);
    }

    function _validateKeys(bytes calldata pubkey, bytes calldata signature) private view {
        if (pubkey.length != pubkey_LENGTH) revert InvalidLengthOfpubkey();
        if (signature.length != SIGNATURE_LENGTH) revert InvalidLengthOfSignature();
        if (validatorIdByPubkey[pubkey] != 0) revert pubkeyAlreadyExist();
    }

    function _sendValue(address receiver, uint256 _amount) internal {
        if (address(this).balance < _amount) revert InSufficientBalance();

        //slither-disable-next-line arbitrary-send-eth
        (bool success, ) = payable(receiver).call{value: _amount}('');
        if (!success) revert TransferFailed();
    }

    function _onlyOnboardedOperator(address operAddr) internal view returns (uint256 _operatorId) {
        _operatorId = operatorIDByAddress[operAddr];
        if (_operatorId == 0) revert OperatorNotOnBoarded();
    }

    function _onlyValidName(string calldata _name) internal pure {
        if (bytes(_name).length == 0) revert EmptyNameString();
        if (bytes(_name).length > OPERATOR_MAX_NAME_LENGTH) revert NameCrossedMaxLength();
    }

    function _increaseInitializedValidatorCount(Operator storage _operator, uint256 _count) internal {
        _operator.initializedValidatorCount += _count;
    }

    function _updateInitializedAndQueuedValidatorCount(uint256 _operatorId) internal {
        Operator storage operator = operatorStructById[_operatorId];
        operator.initializedValidatorCount--;
        operator.queuedValidatorCount++;
    }

    function _updateQueuedAndActiveValidatorsCount(uint256 _operatorId) internal {
        Operator storage operator = operatorStructById[_operatorId];
        operator.queuedValidatorCount--;
        operator.activeValidatorCount++;
        totalQueuedValidatorCount--;
        totalActiveValidatorCount++;
        emit UpdatedQueuedAndActiveValidatorsCount(
            _operatorId,
            operator.queuedValidatorCount,
            operator.activeValidatorCount
        );
    }

    function _updateActiveAndWithdrawnValidatorsCount(uint256 _operatorId) internal {
        Operator storage operator = operatorStructById[_operatorId];
        operator.activeValidatorCount--;
        operator.withdrawnValidatorCount++;
        totalActiveValidatorCount--;
        totalWithdrawnValidatorCount++;
        emit UpdatedActiveAndWithdrawnValidatorsCount(
            _operatorId,
            operator.activeValidatorCount,
            operator.withdrawnValidatorCount
        );
    }

    function _updateInitializedAndWithdrawnValidatorCount(uint256 _operatorId) internal {
        Operator storage operator = operatorStructById[_operatorId];
        operator.initializedValidatorCount--;
        operator.withdrawnValidatorCount++;
    }

    function _isActiveValidator(uint256 _validatorId) internal view returns (bool) {
        Validator memory validator = validatorRegistry[_validatorId];
        if (
            validator.status == ValidatorStatus.INITIALIZED ||
            validator.status == ValidatorStatus.PRE_DEPOSIT ||
            validator.status == ValidatorStatus.WITHDRAWN
        ) return false;
        return true;
    }
}

pragma solidity ^0.8.16;

library Address {
    error ZeroAddress();

    /// @notice zero address check modifier
    function checkNonZeroAddress(address _address) internal pure {
        if (_address == address(0)) revert ZeroAddress();
    }
}

pragma solidity ^0.8.16;

enum ValidatorStatus {
    INITIALIZED,
    PRE_DEPOSIT,
    DEPOSITED,
    IN_ACTIVATION_QUEUE,
    ACTIVE,
    IN_EXIT_QUEUE,
    EXITED,
    WITHDRAWN
}

pragma solidity ^0.8.16;

interface IVaultFactory {
    event WithdrawVaultCreated(address withdrawVault);
    event NodeELRewardVaultCreated(address nodeDistributor);

    function vaultOwner() external view returns (address);

    function staderTreasury() external view returns (address payable);

    function STADER_NETWORK_CONTRACT() external view returns (bytes32);

    function PERMISSION_LESS_POOL() external view returns (bytes32);

    function deployWithdrawVault(
        uint8 poolType,
        uint256 operatorId,
        uint256 validatorCount
    ) external returns (address);

    function deployNodeELRewardVault(
        uint8 poolType,
        uint256 operatorId,
        address payable nodeRecipient
    ) external returns (address);

    function computeWithdrawVaultAddress(
        uint8 poolType,
        uint256 operatorId,
        uint256 validatorCount
    ) external view returns (address);

    function computeNodeELRewardVaultAddress(uint8 poolType, uint256 operatorId) external view returns (address);

    function getValidatorWithdrawCredential(address _withdrawVault) external pure returns (bytes memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

interface IPoolSelector {
    // Error events
    error InvalidTargetWeight();
    error InvalidNewTargetInput();
    error InvalidSumOfPoolTargets();
    error NotEnoughInitializedValidators();
    error InputBatchLimitIsIdenticalToCurrent();

    // Getters
    function poolIdForExcessDeposit() external view returns (uint8); // returns the ID of the pool with excess supply

    function TOTAL_TARGET() external pure returns (uint8); // returns the total target for pools

    function POOL_SELECTOR_ADMIN() external view returns (bytes32);

    function STADER_STAKE_POOL_MANAGER() external view returns (bytes32);

    function computePoolAllocationForDeposit(uint256 _pooledEth)
        external
        returns (uint256[] memory poolWiseValidatorsToDeposit);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import './INodeRegistry.sol';

// Interface for the PoolFactory contract
interface IPoolFactory {
    // Events
    event PoolAdded(string poolName, address poolAddress);
    event PoolAddressUpdated(uint8 indexed poolId, address poolAddress);

    // Struct representing a pool
    struct Pool {
        string poolName;
        address poolAddress;
    }

    // returns the details of a specific pool
    function pools(uint8) external view returns (string calldata poolName, address poolAddress);

    // Pool functions
    function addNewPool(string calldata _poolName, address _poolAddress) external;

    function updatePoolAddress(uint8 _poolId, address _poolAddress) external;

    function getAllActiveValidators() external view returns (Validator[] memory);

    function retrieveValidator(bytes calldata _pubkey) external view returns (Validator memory);

    function getValidatorByPool(uint8 _poolId, bytes calldata _pubkey) external view returns (Validator memory);

    function getOperatorTotalNonWithdrawnKeys(uint8 _poolId, address _nodeOperator) external view returns (uint256);

    // Pool getters
    function poolCount() external view returns (uint8); // returns the number of pools in the factory

    function getTotalActiveValidatorCount() external view returns (uint256); //returns total active validators across all pools

    function getActiveValidatorCountByPool(uint8 _poolId) external view returns (uint256); // returns the total number of active validators in a specific pool

    function getQueuedValidatorCountByPool(uint8 _poolId) external view returns (uint256); // returns the total number of queued validators in a specific pool
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import '../library/ValidatorStatus.sol';

struct Validator {
    ValidatorStatus status; // state of validator
    bool isFrontRun; // set to true by DAO if validator get front deposit
    bytes pubkey; //public Key of the validator
    bytes signature; //signature for deposit to Ethereum Deposit contract
    address withdrawVaultAddress; //eth1 withdrawal address for validator
    uint256 operatorId; // stader network assigned Id
    uint256 initialBondEth; // amount of bond eth in gwei
}

struct Operator {
    bool active; // operator status
    bool optedForSocializingPool; // operator opted for socializing pool
    string operatorName; // name of the operator
    address payable operatorRewardAddress; //Eth1 address of node for reward
    address operatorAddress; //address of operator to interact with stader
    uint256 initializedValidatorCount; //validator whose keys added but not given pre signed msg for withdrawal
    uint256 queuedValidatorCount; // validator queued for deposit
    uint256 activeValidatorCount; // registered validator on beacon chain
    uint256 withdrawnValidatorCount; //withdrawn validator count
}

// Interface for the NodeRegistry contract
interface INodeRegistry {
    function getAllActiveValidators() external view returns (Validator[] memory);

    function getValidator(bytes memory _pubkey) external view returns (Validator memory);

    function getValidator(uint256 _validatorId) external view returns (Validator memory);

    function getOperatorTotalNonWithdrawnKeys(address _nodeOperator) external view returns (uint256 _totalKeys);

    function getTotalQueuedValidatorCount() external view returns (uint256); // returns the total number of active validators across all operators

    function getTotalActiveValidatorCount() external view returns (uint256); // returns the total number of queued validators across all operators
}

pragma solidity ^0.8.16;

interface IPermissionlessPool {
    function preDepositOnBeacon(
        bytes calldata _pubkey,
        bytes calldata _signature,
        address withdrawVault
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface ISDCollateral {
    function depositXSDAsCollateral(uint256 _xsdAmount) external;

    function depositSDAsCollateral(uint256 _sdAmount) external;

    function updatePoolThreshold(
        uint8 _poolId,
        uint256 _lower,
        uint256 _upper,
        string memory _units
    ) external;

    function hasEnoughXSDCollateral(
        address _operator,
        uint8 _poolId,
        uint256 _numValidators
    ) external view returns (bool);
}

pragma solidity ^0.8.16;

import '../library/ValidatorStatus.sol';
import './INodeRegistry.sol';

interface IPermissionlessNodeRegistry {
    // Error events
    error InvalidIndex();
    error TransferFailed();
    error EmptyNameString();
    error NameCrossedMaxLength();
    error pubkeyDoesNotExist();
    error OperatorNotOnBoarded();
    error InvalidBondEthValue();
    error InSufficientBalance();
    error OperatorAlreadyOnBoarded();
    error NoQueuedValidatorLeft();
    error NoActiveValidatorLeft();
    error NoKeysProvided();
    error pubkeyAlreadyExist();
    error InvalidLengthOfpubkey();
    error InvalidLengthOfSignature();
    error InvalidSizeOfInputKeys();
    error ValidatorInPreDepositState();

    //Events
    event OnboardedOperator(address indexed _nodeOperator, uint256 _operatorId);
    event AddedKeys(address indexed _nodeOperator, bytes _pubkey, uint256 _validatorId);
    event ValidatorMarkedReadyToDeposit(bytes _pubkey, uint256 _validatorId);
    event UpdatedQueuedAndActiveValidatorsCount(
        uint256 _operatorId,
        uint256 _queuedValidatorCount,
        uint256 _activeValidatorCount
    );
    event UpdatedActiveAndWithdrawnValidatorsCount(
        uint256 _operatorId,
        uint256 _activeValidatorCount,
        uint256 _withdrawnValidators
    );
    event UpdatedPoolFactoryAddress(address _poolFactoryAddress);
    event UpdatedVaultFactoryAddress(address _vaultFactoryAddress);
    event UpdatedPermissionlessPoolAddress(address _permissionlessPool);
    event UpdatedNextQueuedValidatorIndex(uint256 _nextQueuedValidatorIndex);
    event UpdatedOperatorDetails(address indexed _nodeOperator, string _operatorName, address _rewardAddress);
    event UpdatedSocializingPoolState(uint256 _operatorId, bool _optedForSocializingPool, uint256 timestamp);

    //Getters

    function PERMISSIONLESS_NODE_REGISTRY_OWNER() external returns (bytes32);

    function STADER_ORACLE() external view returns (bytes32);

    function VALIDATOR_STATUS_ROLE() external returns (bytes32);

    function PERMISSIONLESS_POOL() external returns (bytes32);

    function STADER_MANAGER_BOT() external returns (bytes32);

    function poolId() external view returns (uint8);

    function poolFactoryAddress() external view returns (address);

    function vaultFactoryAddress() external view returns (address);

    function sdCollateral() external view returns (address);

    function elRewardSocializePool() external view returns (address);

    function permissionlessPool() external view returns (address);

    function staderInsuranceFund() external view returns (address);

    function nextOperatorId() external view returns (uint256);

    function nextValidatorId() external view returns (uint256);

    function validatorQueueSize() external view returns (uint256);

    function nextQueuedValidatorIndex() external view returns (uint256);

    function totalInitializedValidatorCount() external view returns (uint256);

    function totalQueuedValidatorCount() external view returns (uint256);

    function totalActiveValidatorCount() external view returns (uint256);

    function totalWithdrawnValidatorCount() external view returns (uint256);

    function PRE_DEPOSIT() external view returns (uint256);

    function FRONT_RUN_PENALTY() external view returns (uint256);

    function collateralETH() external view returns (uint256);

    function OPERATOR_MAX_NAME_LENGTH() external view returns (uint256);

    function validatorRegistry(uint256)
        external
        view
        returns (
            ValidatorStatus status,
            bool isFrontRun,
            bytes calldata pubkey,
            bytes calldata signature,
            address withdrawVaultAddress,
            uint256 operatorId,
            uint256 initialBondEth
        );

    function validatorIdByPubkey(bytes calldata _pubkey) external view returns (uint256);

    function queuedValidators(uint256) external view returns (uint256);

    function operatorStructById(uint256)
        external
        view
        returns (
            bool active,
            bool optedForSocializingPool,
            string calldata operatorName,
            address payable operatorRewardAddress,
            address operatorAddress,
            uint256 initializedValidatorCount,
            uint256 queuedValidatorCount,
            uint256 activeValidatorCount,
            uint256 withdrawnValidatorCount
        );

    function operatorIDByAddress(address) external view returns (uint256);

    function socializingPoolStateChangeTimestamp(uint256) external view returns (uint256);

    function getOperatorTotalKeys(address _nodeOperator) external view returns (uint256 _totalKeys);

    //Setters

    function onboardNodeOperator(
        bool _optInForMevSocialize,
        string calldata _operatorName,
        address payable _operatorRewardAddress
    ) external returns (address mevFeeRecipientAddress);

    function addValidatorKeys(bytes[] calldata _validatorpubkey, bytes[] calldata _validatorSignature) external payable;

    function markValidatorReadyToDeposit(bytes[] calldata _pubkeys) external;

    function updateQueuedAndActiveValidatorsCount(uint256 _operatorID) external;

    function updateActiveAndWithdrawnValidatorsCount(uint256 _operatorID) external;

    function updateNextQueuedValidatorIndex(uint256 _count) external;

    function transferCollateralToPool(uint256 _amount) external;

    function updateValidatorStatus(bytes calldata _pubkey, ValidatorStatus _status) external;

    function updatePoolFactoryAddress(address _staderPoolSelector) external;

    function updateVaultFactoryAddress(address _vaultFactoryAddress) external;

    function updatePermissionlessPoolAddress(address _permissionlessPool) external;

    function updateOperatorDetails(string calldata _operatorName, address payable _rewardAddress) external;

    function changeSocializingPoolState(bool _optedForSocializingPool) external;

    function pause() external;

    function unpause() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
                        StringsUpgradeable.toHexString(account),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (proxy/utils/Initializable.sol)

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
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
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
interface IERC165Upgradeable {
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