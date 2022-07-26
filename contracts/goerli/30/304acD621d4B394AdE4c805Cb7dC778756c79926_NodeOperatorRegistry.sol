// SPDX-FileCopyrightText: 2021 ShardLabs
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./interfaces/IValidatorShare.sol";
import "./interfaces/INodeOperatorRegistry.sol";
import "./interfaces/IStMATIC.sol";

/// @title NodeOperatorRegistry
/// @author 2021 ShardLabs.
/// @notice NodeOperatorRegistry is the main contract that manage operators.
contract NodeOperatorRegistry is
    INodeOperatorRegistry,
    PausableUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable
{
    /// @notice stakeManager interface.
    IStakeManager public stakeManager;

    /// @notice stMatic interface.
    IStMATIC public stMATIC;

    /// @notice contract version.
    string public version;

    /// @notice all the roles.
    bytes32 public constant DAO_ROLE = keccak256("LIDO_DAO");
    bytes32 public constant PAUSE_ROLE = keccak256("LIDO_PAUSE_OPERATOR");
    bytes32 public constant UNPAUSE_ROLE = keccak256("LIDO_UNPAUSE_OPERATOR");
    bytes32 public constant ADD_NODE_OPERATOR_ROLE =
        keccak256("ADD_NODE_OPERATOR_ROLE");
    bytes32 public constant REMOVE_NODE_OPERATOR_ROLE =
        keccak256("REMOVE_NODE_OPERATOR_ROLE");

    /// @notice The min percent to recognize the system as balanced.
    uint256 public DISTANCE_THRESHOLD_PERCENTS;

    /// @notice The maximum percentage withdraw per system rebalance.
    uint256 public MAX_WITHDRAW_PERCENTAGE_PER_REBALANCE;

    /// @notice Allows to increse the number of validators to request withdraw from
    /// when the system is balanced.
    uint8 public MIN_REQUEST_WITHDRAW_RANGE_PERCENTS;

    /// @notice all the validators ids.
    uint256[] public validatorIds;

    /// @notice Mapping of all owners with node operator id. Mapping is used to be able to
    /// extend the struct.
    mapping(uint256 => address) public validatorIdToRewardAddress;

    /// @notice Mapping of validator reward address to validator Id. Mapping is used to be able to
    /// extend the struct.
    mapping(address => uint256) public validatorRewardAddressToId;

    /// @notice Initialize the NodeOperatorRegistry contract.
    function initialize(
        IStakeManager _stakeManager,
        IStMATIC _stMATIC,
        address _dao
    ) external initializer {
        __Pausable_init_unchained();
        __AccessControl_init_unchained();
        __ReentrancyGuard_init_unchained();

        stakeManager = _stakeManager;
        stMATIC = _stMATIC;

        DISTANCE_THRESHOLD_PERCENTS = 120;
        MAX_WITHDRAW_PERCENTAGE_PER_REBALANCE = 20;
        MIN_REQUEST_WITHDRAW_RANGE_PERCENTS = 15;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSE_ROLE, msg.sender);
        _grantRole(UNPAUSE_ROLE, _dao);
        _grantRole(DAO_ROLE, _dao);
        _grantRole(ADD_NODE_OPERATOR_ROLE, _dao);
        _grantRole(REMOVE_NODE_OPERATOR_ROLE, _dao);
        version = "2.0.0";
    }

    /// @notice Add a new node operator to the system.
    /// ONLY ADD_NODE_OPERATOR_ROLE can execute this function.
    /// @param _validatorId the validator id on stakeManager.
    /// @param _rewardAddress the reward address.
    function addNodeOperator(uint256 _validatorId, address _rewardAddress)
        external
        override
        onlyRole(ADD_NODE_OPERATOR_ROLE)
        nonReentrant
    {
        require(_validatorId != 0, "ValidatorId=0");
        require(
            validatorIdToRewardAddress[_validatorId] == address(0),
            "Validator exists"
        );
        require(
            validatorRewardAddressToId[_rewardAddress] == 0,
            "Reward Address already used"
        );
        require(_rewardAddress != address(0), "Invalid reward address");

        IStakeManager.Validator memory validator = stakeManager.validators(
            _validatorId
        );

        require(
            validator.status == IStakeManager.Status.Active &&
                validator.deactivationEpoch == 0,
            "Validator isn't ACTIVE"
        );

        require(
            validator.contractAddress != address(0),
            "Validator has no ValidatorShare"
        );

        require(
            IValidatorShare(validator.contractAddress).delegation(),
            "Delegation is disabled"
        );

        validatorIdToRewardAddress[_validatorId] = _rewardAddress;
        validatorRewardAddressToId[_rewardAddress] = _validatorId;
        validatorIds.push(_validatorId);

        emit AddNodeOperator(_validatorId, _rewardAddress);
    }

    /// @notice Exit the node operator registry
    /// ONLY the owner of the node operator can call this function
    function exitNodeOperatorRegistry() external override nonReentrant {
        uint256 validatorId = validatorRewardAddressToId[msg.sender];
        address rewardAddress = validatorIdToRewardAddress[validatorId];
        require(rewardAddress == msg.sender, "Unauthorized");

        IStakeManager.Validator memory validator = stakeManager.validators(
            validatorId
        );
        _removeOperator(validatorId, validator.contractAddress, rewardAddress);
        emit ExitNodeOperator(validatorId, rewardAddress);
    }

    /// @notice Remove a node operator from the system and withdraw total delegated tokens to it.
    /// ONLY DAO can execute this function.
    /// withdraw delegated tokens from it.
    /// @param _validatorId the validator id on stakeManager.
    function removeNodeOperator(uint256 _validatorId)
        external
        override
        onlyRole(REMOVE_NODE_OPERATOR_ROLE)
        nonReentrant
    {
        address rewardAddress = validatorIdToRewardAddress[_validatorId];
        require(rewardAddress != address(0), "Validator doesn't exist");

        IStakeManager.Validator memory validator = stakeManager.validators(
            _validatorId
        );

        _removeOperator(_validatorId, validator.contractAddress, rewardAddress);

        emit RemoveNodeOperator(_validatorId, rewardAddress);
    }

    /// @notice Remove a node operator from the system if it fails to meet certain conditions.
    /// If the Node Operator is either Unstaked or Ejected.
    /// @param _validatorId the validator id on stakeManager.
    function removeInvalidNodeOperator(uint256 _validatorId)
        external
        override
        whenNotPaused
        nonReentrant
    {
        (
            NodeOperatorRegistryStatus operatorStatus,
            IStakeManager.Validator memory validator
        ) = _getOperatorStatusAndValidator(_validatorId);

        require(
            operatorStatus == NodeOperatorRegistryStatus.UNSTAKED ||
                operatorStatus == NodeOperatorRegistryStatus.EJECTED,
            "Cannot remove valid operator."
        );
        address rewardAddress = validatorIdToRewardAddress[_validatorId];

        _removeOperator(_validatorId, validator.contractAddress, rewardAddress);

        emit RemoveInvalidNodeOperator(_validatorId, rewardAddress);
    }

    function _removeOperator(
        uint256 _validatorId,
        address _contractAddress,
        address _rewardAddress
    ) private {
        uint256 length = validatorIds.length;
        for (uint256 idx = 0; idx < length - 1; idx++) {
            if (_validatorId == validatorIds[idx]) {
                validatorIds[idx] = validatorIds[validatorIds.length - 1];
                break;
            }
        }
        validatorIds.pop();
        stMATIC.withdrawTotalDelegated(_contractAddress);
        delete validatorIdToRewardAddress[_validatorId];
        delete validatorRewardAddressToId[_rewardAddress];
    }

    ////////////////////////////////////////////////////////////
    /////                                                    ///
    /////                 ***Setters***                      ///
    /////                                                    ///
    ////////////////////////////////////////////////////////////

    /// @notice Set StMatic address.
    /// ONLY DAO can call this function
    /// @param _newStMatic new stMatic address.
    function setStMaticAddress(address _newStMatic)
        external
        override
        onlyRole(DAO_ROLE)
    {
        require(_newStMatic != address(0), "Invalid stMatic address");

        address oldStMATIC = address(stMATIC);
        stMATIC = IStMATIC(_newStMatic);

        emit SetStMaticAddress(oldStMATIC, _newStMatic);
    }

    /// @notice Update the reward address of a Node Operator.
    /// ONLY Operator owner can call this function
    /// @param _newRewardAddress the new reward address.
    function setRewardAddress(address _newRewardAddress)
        external
        override
        whenNotPaused
    {
        uint256 validatorId = validatorRewardAddressToId[msg.sender];
        address oldRewardAddress = validatorIdToRewardAddress[validatorId];
        require(oldRewardAddress == msg.sender, "Unauthorized");
        require(_newRewardAddress != address(0), "Invalid reward address");

        validatorIdToRewardAddress[validatorId] = _newRewardAddress;
        validatorRewardAddressToId[_newRewardAddress] = validatorId;
        delete validatorRewardAddressToId[msg.sender];

        emit SetRewardAddress(validatorId, oldRewardAddress, _newRewardAddress);
    }

    /// @notice set DISTANCE_THRESHOLD_PERCENTS
    /// ONLY DAO can call this function
    /// @param _newDistanceThreshold the min rebalance threshold to include
    /// a validator in the delegation process.
    function setDistanceThreshold(uint256 _newDistanceThreshold)
        external
        override
        onlyRole(DAO_ROLE)
    {
        require(_newDistanceThreshold >= 100, "Invalid distance threshold");
        uint256 _oldDistanceThreshold = DISTANCE_THRESHOLD_PERCENTS;
        DISTANCE_THRESHOLD_PERCENTS = _newDistanceThreshold;

        emit SetDistanceThreshold(_oldDistanceThreshold, _newDistanceThreshold);
    }

    /// @notice set MIN_REQUEST_WITHDRAW_RANGE_PERCENTS
    /// ONLY DAO can call this function
    /// @param _newMinRequestWithdrawRangePercents the min request withdraw range percents.
    function setMinRequestWithdrawRange(
        uint8 _newMinRequestWithdrawRangePercents
    ) external override onlyRole(DAO_ROLE) {
        require(
            _newMinRequestWithdrawRangePercents <= 100,
            "Invalid minRequestWithdrawRange"
        );
        uint8 _oldMinRequestWithdrawRange = MIN_REQUEST_WITHDRAW_RANGE_PERCENTS;
        MIN_REQUEST_WITHDRAW_RANGE_PERCENTS = _newMinRequestWithdrawRangePercents;

        emit SetMinRequestWithdrawRange(
            _oldMinRequestWithdrawRange,
            _newMinRequestWithdrawRangePercents
        );
    }

    /// @notice set MAX_WITHDRAW_PERCENTAGE_PER_REBALANCE
    /// ONLY DAO can call this function
    /// @param _newMaxWithdrawPercentagePerRebalance the max withdraw percentage to
    /// withdraw from a validator per rebalance.
    function setMaxWithdrawPercentagePerRebalance(
        uint256 _newMaxWithdrawPercentagePerRebalance
    ) external override onlyRole(DAO_ROLE) {
        require(
            _newMaxWithdrawPercentagePerRebalance <= 100,
            "Invalid maxWithdrawPercentagePerRebalance"
        );
        uint256 _oldMaxWithdrawPercentagePerRebalance = MAX_WITHDRAW_PERCENTAGE_PER_REBALANCE;
        MAX_WITHDRAW_PERCENTAGE_PER_REBALANCE = _newMaxWithdrawPercentagePerRebalance;

        emit SetMaxWithdrawPercentagePerRebalance(
            _oldMaxWithdrawPercentagePerRebalance,
            _newMaxWithdrawPercentagePerRebalance
        );
    }

    /// @notice Allows to pause the contract.
    /// @param _newVersion contract version.
    function setVersion(string memory _newVersion)
        external
        override
        onlyRole(DAO_ROLE)
    {
        string memory oldVersion = version;
        version = _newVersion;
        emit SetVersion(oldVersion, _newVersion);
    }

    /// @notice Pauses the contract
    function pause() external onlyRole(PAUSE_ROLE) {
        _pause();
    }

    /// @notice Unpauses the contract
    function unpause() external onlyRole(UNPAUSE_ROLE) {
        _unpause();
    }

    ////////////////////////////////////////////////////////////
    /////                                                    ///
    /////                 ***Getters***                      ///
    /////                                                    ///
    ////////////////////////////////////////////////////////////

    /// @notice List all the ACTIVE operators on the stakeManager.
    /// @return activeNodeOperators a list of ACTIVE node operator.
    /// @return totalActiveNodeOperators total active node operators.
    function listDelegatedNodeOperators()
        external
        view
        override
        returns (ValidatorData[] memory, uint256)
    {
        uint256 totalActiveNodeOperators = 0;
        IStakeManager.Validator memory validator;
        NodeOperatorRegistryStatus operatorStatus;
        ValidatorData[] memory activeValidators = new ValidatorData[](validatorIds.length);

        for (uint256 i = 0; i < validatorIds.length; i++) {
            (operatorStatus, validator) = _getOperatorStatusAndValidator(
                validatorIds[i]
            );
            if (operatorStatus == NodeOperatorRegistryStatus.ACTIVE) {
                if (!IValidatorShare(validator.contractAddress).delegation())
                    continue;

                activeValidators[totalActiveNodeOperators] = ValidatorData(
                    validator.contractAddress,
                    validatorIdToRewardAddress[validatorIds[i]]
                );
                totalActiveNodeOperators++;
            }
        }
        return (activeValidators, totalActiveNodeOperators);
    }

    /// @notice List all the operators on the stakeManager that can be withdrawn from this
    /// includes ACTIVE, JAILED, ejected, and UNSTAKED operators.
    /// @return nodeOperators a list of ACTIVE, JAILED, EJECTED or UNSTAKED node operator.
    /// @return totalNodeOperators total number of node operators.
    function listWithdrawNodeOperators()
        external
        view
        override
        returns (ValidatorData[] memory, uint256)
    {
        uint256 totalNodeOperators = 0;
        uint256[] memory memValidatorIds = validatorIds;
        uint256 length = memValidatorIds.length;
        IStakeManager.Validator memory validator;
        NodeOperatorRegistryStatus operatorStatus;
        ValidatorData[] memory withdrawValidators = new ValidatorData[](length);

        for (uint256 i = 0; i < length; i++) {
            (operatorStatus, validator) = _getOperatorStatusAndValidator(
                memValidatorIds[i]
            );
            if (operatorStatus == NodeOperatorRegistryStatus.INACTIVE) continue;

            validator = stakeManager.validators(memValidatorIds[i]);
            withdrawValidators[totalNodeOperators] = ValidatorData(
                validator.contractAddress,
                validatorIdToRewardAddress[memValidatorIds[i]]
            );
            totalNodeOperators++;
        }

        return (withdrawValidators, totalNodeOperators);
    }

    /// @notice Returns operators delegation infos.
    /// @return validators all active node operators.
    /// @return activeOperatorCount count only active validators.
    /// @return stakePerOperator amount staked in each validator.
    /// @return totalStaked the total amount staked in all validators.
    /// @return distanceThreshold the distance between the min and max amount staked in a validator.
    function _getValidatorsDelegationInfos()
        private
        view
        returns (
            ValidatorData[] memory validators,
            uint256 activeOperatorCount,
            uint256[] memory stakePerOperator,
            uint256 totalStaked,
            uint256 distanceThreshold
        )
    {
        uint256 length = validatorIds.length;
        validators = new ValidatorData[](length);
        stakePerOperator = new uint256[](length);

        uint256 validatorId;
        IStakeManager.Validator memory validator;
        NodeOperatorRegistryStatus status;

        uint256 maxAmount;
        uint256 minAmount;

        for (uint256 i = 0; i < length; i++) {
            validatorId = validatorIds[i];
            (status, validator) = _getOperatorStatusAndValidator(validatorId);
            if (status == NodeOperatorRegistryStatus.INACTIVE) continue;

            require(
                !(status == NodeOperatorRegistryStatus.EJECTED),
                "Could not calculate the stake data, an operator was EJECTED"
            );

            require(
                !(status == NodeOperatorRegistryStatus.UNSTAKED),
                "Could not calculate the stake data, an operator was UNSTAKED"
            );

            // Get the total staked tokens by the StMatic contract in a validatorShare.
            (uint256 amount, ) = IValidatorShare(validator.contractAddress)
                .getTotalStake(address(stMATIC));

            totalStaked += amount;

            if (maxAmount < amount) {
                maxAmount = amount;
            }

            if (minAmount > amount || minAmount == 0) {
                minAmount = amount;
            }

            bool isDelegationEnabled = IValidatorShare(
                validator.contractAddress
            ).delegation();

            if (
                status == NodeOperatorRegistryStatus.ACTIVE &&
                isDelegationEnabled
            ) {
                stakePerOperator[activeOperatorCount] = amount;

                validators[activeOperatorCount] = ValidatorData(
                    validator.contractAddress,
                    validatorIdToRewardAddress[validatorIds[i]]
                );

                activeOperatorCount++;
            }
        }

        require(activeOperatorCount > 0, "There are no active validator");

        // The max amount is multiplied by 100 to have a precise value.
        minAmount = minAmount == 0 ? 1 : minAmount;
        distanceThreshold = ((maxAmount * 100) / minAmount);
    }

    /// @notice  Calculate how total buffered should be delegated between the active validators,
    /// depending on if the system is balanced or not. If validators are in EJECTED or UNSTAKED
    /// status the function will revert.
    /// @param _amountToDelegate The total that can be delegated.
    /// @return validators all active node operators.
    /// @return totalActiveNodeOperator total active node operators.
    /// @return operatorRatios a list of operator's ratio. It will be calculated if the system is not balanced.
    /// @return totalRatio the total ratio. If ZERO that means the system is balanced.
    ///  It will be calculated if the system is not balanced.
    function getValidatorsDelegationAmount(uint256 _amountToDelegate)
        external
        view
        override
        returns (
            ValidatorData[] memory validators,
            uint256 totalActiveNodeOperator,
            uint256[] memory operatorRatios,
            uint256 totalRatio
        )
    {
        require(validatorIds.length > 0, "Not enough operators to delegate");
        uint256[] memory stakePerOperator;
        uint256 totalStaked;
        uint256 distanceThreshold;
        (
            validators,
            totalActiveNodeOperator,
            stakePerOperator,
            totalStaked,
            distanceThreshold
        ) = _getValidatorsDelegationInfos();

        uint256 distanceThresholdPercents = DISTANCE_THRESHOLD_PERCENTS;
        bool isTheSystemBalanced = distanceThreshold <=
            distanceThresholdPercents;
        if (isTheSystemBalanced) {
            return (
                validators,
                totalActiveNodeOperator,
                operatorRatios,
                totalRatio
            );
        }

        // If the system is not balanced calculate ratios
        operatorRatios = new uint256[](totalActiveNodeOperator);
        uint256 rebalanceTarget = (totalStaked + _amountToDelegate) /
            totalActiveNodeOperator;

        uint256 operatorRatioToDelegate;

        for (uint256 idx = 0; idx < totalActiveNodeOperator; idx++) {
            operatorRatioToDelegate = stakePerOperator[idx] >= rebalanceTarget
                ? 0
                : rebalanceTarget - stakePerOperator[idx];

            if (operatorRatioToDelegate != 0 && stakePerOperator[idx] != 0) {
                operatorRatioToDelegate = (rebalanceTarget * 100) /
                    stakePerOperator[idx] >=
                    distanceThresholdPercents
                    ? operatorRatioToDelegate
                    : 0;
            }

            operatorRatios[idx] = operatorRatioToDelegate;
            totalRatio += operatorRatioToDelegate;
        }
    }

    /// @notice  Calculate how the system could be rebalanced depending on the current
    /// buffered tokens. If validators are in EJECTED or UNSTAKED status the function will revert.
    /// If the system is balanced the function will revert.
    /// @notice Calculate the operator ratios to rebalance the system.
    /// @param _amountToReDelegate The total amount to redelegate in Matic.
    /// @return validators all active node operators.
    /// @return totalActiveNodeOperator total active node operators.
    /// @return operatorRatios is a list of operator's ratio.
    /// @return totalRatio the total ratio. If ZERO that means the system is balanced.
    /// @return totalToWithdraw the total amount to withdraw.
    function getValidatorsRebalanceAmount(uint256 _amountToReDelegate)
        external
        view
        override
        returns (
            ValidatorData[] memory validators,
            uint256 totalActiveNodeOperator,
            uint256[] memory operatorRatios,
            uint256 totalRatio,
            uint256 totalToWithdraw
        )
    {
        require(validatorIds.length > 1, "Not enough operator to rebalance");
        uint256[] memory stakePerOperator;
        uint256 totalStaked;
        uint256 distanceThreshold;
        (
            validators,
            totalActiveNodeOperator,
            stakePerOperator,
            totalStaked,
            distanceThreshold
        ) = _getValidatorsDelegationInfos();

        require(
            totalActiveNodeOperator > 1,
            "Not enough active operators to rebalance"
        );

        uint256 distanceThresholdPercents = DISTANCE_THRESHOLD_PERCENTS;
        require(
            distanceThreshold >= distanceThresholdPercents && totalStaked > 0,
            "The system is balanced"
        );

        operatorRatios = new uint256[](totalActiveNodeOperator);
        uint256 rebalanceTarget = totalStaked / totalActiveNodeOperator;
        uint256 operatorRatioToRebalance;

        for (uint256 idx = 0; idx < totalActiveNodeOperator; idx++) {
            operatorRatioToRebalance = stakePerOperator[idx] > rebalanceTarget
                ? stakePerOperator[idx] - rebalanceTarget
                : 0;

            operatorRatioToRebalance = (stakePerOperator[idx] * 100) /
                rebalanceTarget >=
                distanceThresholdPercents
                ? operatorRatioToRebalance
                : 0;

            operatorRatios[idx] = operatorRatioToRebalance;
            totalRatio += operatorRatioToRebalance;
        }
        totalToWithdraw = totalRatio > _amountToReDelegate
            ? totalRatio - _amountToReDelegate
            : 0;

        totalToWithdraw =
            (totalToWithdraw * MAX_WITHDRAW_PERCENTAGE_PER_REBALANCE) /
            100;
        require(totalToWithdraw > 0, "Zero total to withdraw");
    }

    /// @notice Returns operators info.
    /// @return nonInactiveValidators all no inactive node operators.
    /// @return stakePerOperator amount staked in each validator.
    /// @return totalDelegated the total amount delegated to all validators.
    /// @return minAmount the distance between the min and max amount staked in a validator.
    /// @return maxAmount the distance between the min and max amount staked in a validator.
    function _getValidatorsRequestWithdraw()
        private
        view
        returns (
            ValidatorData[] memory nonInactiveValidators,
            uint256[] memory stakePerOperator,
            uint256 totalDelegated,
            uint256 minAmount,
            uint256 maxAmount
        )
    {
        uint256 length = validatorIds.length;
        nonInactiveValidators = new ValidatorData[](length);
        stakePerOperator = new uint256[](length);

        uint256 validatorId;
        IStakeManager.Validator memory validator;

        for (uint256 i = 0; i < length; i++) {
            validatorId = validatorIds[i];
            (, validator) = _getOperatorStatusAndValidator(validatorId);

            // Get the total staked tokens by the StMatic contract in a validatorShare.
            (uint256 amount, ) = IValidatorShare(validator.contractAddress)
                .getTotalStake(address(stMATIC));

            stakePerOperator[i] = amount;
            totalDelegated += amount;

            if (maxAmount < amount) {
                maxAmount = amount;
            }

            if ((minAmount > amount && amount != 0) || minAmount == 0) {
                minAmount = amount;
            }

            nonInactiveValidators[i] = ValidatorData(
                validator.contractAddress,
                validatorIdToRewardAddress[validatorIds[i]]
            );
        }
        minAmount = minAmount == 0 ? 1 : minAmount;
    }

    /// @notice Calculate the validators to request withdrawal from depending if the system is balalnced or not.
    /// @param _withdrawAmount The amount to withdraw.
    /// @return validators all node operators.
    /// @return totalDelegated total amount delegated.
    /// @return bigNodeOperatorLength number of ids bigNodeOperatorIds.
    /// @return bigNodeOperatorIds stores the ids of node operators that amount delegated to it is greater than the average delegation.
    /// @return smallNodeOperatorLength number of ids smallNodeOperatorIds.
    /// @return smallNodeOperatorIds stores the ids of node operators that amount delegated to it is less than the average delegation.
    /// @return operatorAmountCanBeRequested amount that can be requested from a spécific validator when the system is not balanced.
    /// @return totalValidatorToWithdrawFrom the number of validator to withdraw from when the system is balanced.
    function getValidatorsRequestWithdraw(uint256 _withdrawAmount)
        external
        view
        override
        returns (
            ValidatorData[] memory validators,
            uint256 totalDelegated,
            uint256 bigNodeOperatorLength,
            uint256[] memory bigNodeOperatorIds,
            uint256 smallNodeOperatorLength,
            uint256[] memory smallNodeOperatorIds,
            uint256[] memory operatorAmountCanBeRequested,
            uint256 totalValidatorToWithdrawFrom
        )
    {
        if (validatorIds.length == 0) {
            return (
                validators,
                totalDelegated,
                bigNodeOperatorLength,
                bigNodeOperatorIds,
                smallNodeOperatorLength,
                smallNodeOperatorIds,
                operatorAmountCanBeRequested,
                totalValidatorToWithdrawFrom
            );
        }
        uint256[] memory stakePerOperator;
        uint256 minAmount;
        uint256 maxAmount;

        (
            validators,
            stakePerOperator,
            totalDelegated,
            minAmount,
            maxAmount
        ) = _getValidatorsRequestWithdraw();

        if (totalDelegated == 0) {
            return (
                validators,
                totalDelegated,
                bigNodeOperatorLength,
                bigNodeOperatorIds,
                smallNodeOperatorLength,
                smallNodeOperatorIds,
                operatorAmountCanBeRequested,
                totalValidatorToWithdrawFrom
            );
        }

        uint256 length = validators.length;
        uint256 withdrawAmountPercentage = (_withdrawAmount * 100) /
            totalDelegated;

        totalValidatorToWithdrawFrom =
            (((withdrawAmountPercentage + MIN_REQUEST_WITHDRAW_RANGE_PERCENTS) *
                length) / 100) +
            1;

        totalValidatorToWithdrawFrom = totalValidatorToWithdrawFrom > length
            ? length
            : totalValidatorToWithdrawFrom;

        if (
            (maxAmount * 100) / minAmount <= DISTANCE_THRESHOLD_PERCENTS &&
            minAmount * totalValidatorToWithdrawFrom >= _withdrawAmount
        ) {
            return (
                validators,
                totalDelegated,
                bigNodeOperatorLength,
                bigNodeOperatorIds,
                smallNodeOperatorLength,
                smallNodeOperatorIds,
                operatorAmountCanBeRequested,
                totalValidatorToWithdrawFrom
            );
        }
        totalValidatorToWithdrawFrom = 0;
        operatorAmountCanBeRequested = new uint256[](length);
        withdrawAmountPercentage = withdrawAmountPercentage == 0
            ? 1
            : withdrawAmountPercentage;
        uint256 rebalanceTarget = totalDelegated > _withdrawAmount
            ? (totalDelegated - _withdrawAmount) / length
            : 0;

        rebalanceTarget = rebalanceTarget > minAmount
            ? minAmount
            : rebalanceTarget;

        uint256 averageTarget = totalDelegated / length;
        bigNodeOperatorIds = new uint256[](length);
        smallNodeOperatorIds = new uint256[](length);

        for (uint256 idx = 0; idx < length; idx++) {
            if (stakePerOperator[idx] > averageTarget) {
                bigNodeOperatorIds[bigNodeOperatorLength] = idx;
                bigNodeOperatorLength++;
            } else {
                smallNodeOperatorIds[smallNodeOperatorLength] = idx;
                smallNodeOperatorLength++;
            }

            uint256 operatorRatioToRebalance = stakePerOperator[idx] != 0 &&
                stakePerOperator[idx] > rebalanceTarget
                ? stakePerOperator[idx] - rebalanceTarget
                : 0;
            operatorAmountCanBeRequested[idx] = operatorRatioToRebalance;
        }
    }

    /// @notice Returns a node operator.
    /// @param _validatorId the validator id on stakeManager.
    /// @return nodeOperator Returns a node operator.
    function getNodeOperator(uint256 _validatorId)
        external
        view
        override
        returns (FullNodeOperatorRegistry memory nodeOperator)
    {
        (
            NodeOperatorRegistryStatus operatorStatus,
            IStakeManager.Validator memory validator
        ) = _getOperatorStatusAndValidator(_validatorId);
        nodeOperator.validatorShare = validator.contractAddress;
        nodeOperator.validatorId = _validatorId;
        nodeOperator.rewardAddress = validatorIdToRewardAddress[_validatorId];
        nodeOperator.status = operatorStatus;
        nodeOperator.commissionRate = validator.commissionRate;
    }

    /// @notice Returns a node operator.
    /// @param _rewardAddress the reward address.
    /// @return nodeOperator Returns a node operator.
    function getNodeOperator(address _rewardAddress)
        external
        view
        override
        returns (FullNodeOperatorRegistry memory nodeOperator)
    {
        uint256 validatorId = validatorRewardAddressToId[_rewardAddress];
        (
            NodeOperatorRegistryStatus operatorStatus,
            IStakeManager.Validator memory validator
        ) = _getOperatorStatusAndValidator(validatorId);

        nodeOperator.status = operatorStatus;
        nodeOperator.rewardAddress = _rewardAddress;
        nodeOperator.validatorId = validatorId;
        nodeOperator.validatorShare = validator.contractAddress;
        nodeOperator.commissionRate = validator.commissionRate;
    }

    /// @notice Returns a node operator status.
    /// @param  _validatorId is the id of the node operator.
    /// @return operatorStatus Returns a node operator status.
    function getNodeOperatorStatus(uint256 _validatorId)
        external
        view
        override
        returns (NodeOperatorRegistryStatus operatorStatus)
    {
        (operatorStatus, ) = _getOperatorStatusAndValidator(_validatorId);
    }

    /// @notice Returns a node operator status.
    /// @param  _validatorId is the id of the node operator.
    /// @return operatorStatus is the operator status.
    /// @return validator is the validator info.
    function _getOperatorStatusAndValidator(uint256 _validatorId)
        private
        view
        returns (
            NodeOperatorRegistryStatus operatorStatus,
            IStakeManager.Validator memory validator
        )
    {
        address rewardAddress = validatorIdToRewardAddress[_validatorId];
        require(rewardAddress != address(0), "Operator not found");
        validator = stakeManager.validators(_validatorId);

        if (
            validator.status == IStakeManager.Status.Active &&
            validator.deactivationEpoch == 0
        ) {
            operatorStatus = NodeOperatorRegistryStatus.ACTIVE;
        } else if (
            validator.status == IStakeManager.Status.Locked &&
            validator.deactivationEpoch == 0
        ) {
            operatorStatus = NodeOperatorRegistryStatus.JAILED;
        } else if (
            (validator.status == IStakeManager.Status.Active ||
                validator.status == IStakeManager.Status.Locked) &&
            validator.deactivationEpoch != 0
        ) {
            operatorStatus = NodeOperatorRegistryStatus.EJECTED;
        } else if ((validator.status == IStakeManager.Status.Unstaked)) {
            operatorStatus = NodeOperatorRegistryStatus.UNSTAKED;
        } else {
            operatorStatus = NodeOperatorRegistryStatus.INACTIVE;
        }

        return (operatorStatus, validator);
    }

    /// @notice Return a list of all validator ids in the system.
    function getValidatorIds()
        external
        view
        override
        returns (uint256[] memory)
    {
        return validatorIds;
    }

    /// @notice Return the statistics about the protocol as a list
    /// @return isBalanced if the system is balanced or not.
    /// @return distanceThreshold the distance threshold
    /// @return minAmount min amount delegated to a validator.
    /// @return maxAmount max amount delegated to a validator.
    function getProtocolStats()
        external
        view
        override
        returns (
            bool isBalanced,
            uint256 distanceThreshold,
            uint256 minAmount,
            uint256 maxAmount
        )
    {
        uint256 length = validatorIds.length;
        uint256 validatorId;
        for (uint256 i = 0; i < length; i++) {
            validatorId = validatorIds[i];
            (
                ,
                IStakeManager.Validator memory validator
            ) = _getOperatorStatusAndValidator(validatorId);

            (uint256 amount, ) = IValidatorShare(validator.contractAddress)
                .getTotalStake(address(stMATIC));
            if (maxAmount < amount) {
                maxAmount = amount;
            }

            if (minAmount > amount || minAmount == 0) {
                minAmount = amount;
            }
        }

        uint256 min = minAmount == 0 ? 1 : minAmount;
        distanceThreshold = ((maxAmount * 100) / min);
        isBalanced = distanceThreshold <= DISTANCE_THRESHOLD_PERCENTS;
    }

    /// @notice List all the node operator statuses in the system.
    /// @return inactiveNodeOperator the number of inactive operators.
    /// @return activeNodeOperator the number of active operators.
    /// @return jailedNodeOperator the number of jailed operators.
    /// @return ejectedNodeOperator the number of ejected operators.
    /// @return unstakedNodeOperator the number of unstaked operators.
    function getStats()
        external
        view
        override
        returns (
            uint256 inactiveNodeOperator,
            uint256 activeNodeOperator,
            uint256 jailedNodeOperator,
            uint256 ejectedNodeOperator,
            uint256 unstakedNodeOperator
        )
    {
        uint256 length = validatorIds.length;
        for (uint256 idx = 0; idx < length; idx++) {
            (
                NodeOperatorRegistryStatus operatorStatus,

            ) = _getOperatorStatusAndValidator(validatorIds[idx]);
            if (operatorStatus == NodeOperatorRegistryStatus.ACTIVE) {
                activeNodeOperator++;
            } else if (operatorStatus == NodeOperatorRegistryStatus.JAILED) {
                jailedNodeOperator++;
            } else if (operatorStatus == NodeOperatorRegistryStatus.EJECTED) {
                ejectedNodeOperator++;
            } else if (operatorStatus == NodeOperatorRegistryStatus.UNSTAKED) {
                unstakedNodeOperator++;
            } else {
                inactiveNodeOperator++;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

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
        _checkRole(role, _msgSender());
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
                        StringsUpgradeable.toHexString(uint160(account), 20),
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

// SPDX-FileCopyrightText: 2021 ShardLabs
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

/// @title Polygon validator share interface.
/// @dev https://github.com/maticnetwork/contracts/blob/v0.3.0-backport/contracts/staking/validatorShare/ValidatorShare.sol
/// @author 2021 ShardLabs
interface IValidatorShare {
    struct DelegatorUnbond {
        uint256 shares;
        uint256 withdrawEpoch;
    }

    function unbondNonces(address _address) external view returns (uint256);

    function activeAmount() external view returns (uint256);

    function validatorId() external view returns (uint256);

    function withdrawExchangeRate() external view returns (uint256);

    function withdrawRewards() external;

    function unstakeClaimTokens() external;

    function minAmount() external view returns (uint256);

    function getLiquidRewards(address user) external view returns (uint256);

    function delegation() external view returns (bool);

    function updateDelegation(bool _delegation) external;

    function buyVoucher(uint256 _amount, uint256 _minSharesToMint)
        external
        returns (uint256);

    function sellVoucher_new(uint256 claimAmount, uint256 maximumSharesToBurn)
        external;

    function unstakeClaimTokens_new(uint256 unbondNonce) external;

    function unbonds_new(address _address, uint256 _unbondNonce)
        external
        view
        returns (DelegatorUnbond memory);

    function getTotalStake(address user)
        external
        view
        returns (uint256, uint256);

    function owner() external view returns (address);

    function restake() external returns (uint256, uint256);

    function unlock() external;

    function lock() external;

    function drain(
        address token,
        address payable destination,
        uint256 amount
    ) external;

    function slash(uint256 _amount) external;

    function migrateOut(address user, uint256 amount) external;

    function migrateIn(address user, uint256 amount) external;

    function exchangeRate() external view returns (uint256);
}

// SPDX-FileCopyrightText: 2021 ShardLabs
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

/// @title INodeOperatorRegistry
/// @author 2021 ShardLabs
/// @notice Node operator registry interface
interface INodeOperatorRegistry {
    /// @notice Node Operator Registry Statuses
    /// StakeManager statuses: https://github.com/maticnetwork/contracts/blob/v0.3.0-backport/contracts/staking/stakeManager/StakeManagerStorage.sol#L13
    /// ACTIVE: (validator.status == status.Active && validator.deactivationEpoch == 0)
    /// JAILED: (validator.status == status.Locked && validator.deactivationEpoch == 0)
    /// EJECTED: ((validator.status == status.Active || validator.status == status.Locked) && validator.deactivationEpoch != 0)
    /// UNSTAKED: (validator.status == status.Unstaked)
    enum NodeOperatorRegistryStatus {
        INACTIVE,
        ACTIVE,
        JAILED,
        EJECTED,
        UNSTAKED
    }

    /// @notice The full node operator struct.
    /// @param validatorId the validator id on stakeManager.
    /// @param commissionRate rate of each operator
    /// @param validatorShare the validator share address of the validator.
    /// @param rewardAddress the reward address.
    /// @param delegation delegation.
    /// @param status the status of the node operator in the stake manager.
    struct FullNodeOperatorRegistry {
        uint256 validatorId;
        uint256 commissionRate;
        address validatorShare;
        address rewardAddress;
        bool delegation;
        NodeOperatorRegistryStatus status;
    }

    /// @notice The node operator struct
    /// @param validatorShare the validator share address of the validator.
    /// @param rewardAddress the reward address.
    struct ValidatorData {
        address validatorShare;
        address rewardAddress;
    }

    /// @notice Add a new node operator to the system.
    /// ONLY DAO can execute this function.
    /// @param validatorId the validator id on stakeManager.
    /// @param rewardAddress the reward address.
    function addNodeOperator(uint256 validatorId, address rewardAddress)
        external;

    /// @notice Exit the node operator registry
    /// ONLY the owner of the node operator can call this function
    function exitNodeOperatorRegistry() external;

    /// @notice Remove a node operator from the system and withdraw total delegated tokens to it.
    /// ONLY DAO can execute this function.
    /// withdraw delegated tokens from it.
    /// @param validatorId the validator id on stakeManager.
    function removeNodeOperator(uint256 validatorId) external;

    /// @notice Remove a node operator from the system if it fails to meet certain conditions.
    /// 1. If the commission of the Node Operator is less than the standard commission.
    /// 2. If the Node Operator is either Unstaked or Ejected.
    /// @param validatorId the validator id on stakeManager.
    function removeInvalidNodeOperator(uint256 validatorId) external;

    /// @notice Set StMatic address.
    /// ONLY DAO can call this function
    /// @param newStMatic new stMatic address.
    function setStMaticAddress(address newStMatic) external;

    /// @notice Update reward address of a Node Operator.
    /// ONLY Operator owner can call this function
    /// @param newRewardAddress the new reward address.
    function setRewardAddress(address newRewardAddress) external;

    /// @notice set DISTANCETHRESHOLD
    /// ONLY DAO can call this function
    /// @param distanceThreshold the min rebalance threshold to include
    /// a validator in the delegation process.
    function setDistanceThreshold(uint256 distanceThreshold) external;

    /// @notice set MINREQUESTWITHDRAWRANGE
    /// ONLY DAO can call this function
    /// @param minRequestWithdrawRange the min request withdraw range.
    function setMinRequestWithdrawRange(uint8 minRequestWithdrawRange) external;

    /// @notice set MAXWITHDRAWPERCENTAGEPERREBALANCE
    /// ONLY DAO can call this function
    /// @param maxWithdrawPercentagePerRebalance the max withdraw percentage to
    /// withdraw from a validator per rebalance.
    function setMaxWithdrawPercentagePerRebalance(
        uint256 maxWithdrawPercentagePerRebalance
    ) external;

    /// @notice Allows to set new version.
    /// @param _newVersion new contract version.
    function setVersion(string memory _newVersion) external;

    /// @notice List all the ACTIVE operators on the stakeManager.
    /// @return activeNodeOperators a list of ACTIVE node operator.
    /// @return totalActiveNodeOperators total active node operators.
    function listDelegatedNodeOperators()
        external
        view
        returns (ValidatorData[] memory, uint256);

    /// @notice List all the operators on the stakeManager that can be withdrawn from this includes ACTIVE, JAILED, and
    /// @notice UNSTAKED operators.
    /// @return nodeOperators a list of ACTIVE, JAILED or UNSTAKED node operator.
    /// @return totalNodeOperators total number of node operators.
    function listWithdrawNodeOperators()
        external
        view
        returns (ValidatorData[] memory, uint256);

    /// @notice  Calculate how total buffered should be delegated between the active validators,
    /// depending on if the system is balanced or not. If validators are in EJECTED or UNSTAKED
    /// status the function will revert.
    /// @param amountToDelegate The total that can be delegated.
    /// @return validators all active node operators.
    /// @return totalActiveNodeOperator total active node operators.
    /// @return operatorRatios a list of operator's ratio. It will be calculated if the system is not balanced.
    /// @return totalRatio the total ratio. If ZERO that means the system is balanced.
    ///  It will be calculated if the system is not balanced.
    function getValidatorsDelegationAmount(uint256 amountToDelegate)
        external
        view
        returns (
            ValidatorData[] memory validators,
            uint256 totalActiveNodeOperator,
            uint256[] memory operatorRatios,
            uint256 totalRatio
        );

    /// @notice  Calculate how the system could be rebalanced depending on the current
    /// buffered tokens. If validators are in EJECTED or UNSTAKED status the function will revert.
    /// If the system is balanced the function will revert.
    /// @notice Calculate the operator ratios to rebalance the system.
    /// @param totalBuffered The total amount buffered in stMatic.
    /// @return validators all active node operators.
    /// @return totalActiveNodeOperator total active node operators.
    /// @return operatorRatios is a list of operator's ratio.
    /// @return totalRatio the total ratio. If ZERO that means the system is balanced.
    /// @return totalToWithdraw the total amount to withdraw.
    function getValidatorsRebalanceAmount(uint256 totalBuffered)
        external
        view
        returns (
            ValidatorData[] memory validators,
            uint256 totalActiveNodeOperator,
            uint256[] memory operatorRatios,
            uint256 totalRatio,
            uint256 totalToWithdraw
        );

    /// @notice Calculate the validators to request withdrawal from depending if the system is balalnced or not.
    /// @param _withdrawAmount The amount to withdraw.
    /// @return validators all node operators.
    /// @return totalDelegated total amount delegated.
    /// @return bigNodeOperatorLength number of ids bigNodeOperatorIds.
    /// @return bigNodeOperatorIds stores the ids of node operators that amount delegated to it is greater than the average delegation.
    /// @return smallNodeOperatorLength number of ids smallNodeOperatorIds.
    /// @return smallNodeOperatorIds stores the ids of node operators that amount delegated to it is less than the average delegation.
    /// @return operatorAmountCanBeRequested amount that can be requested from a spécific validator when the system is not balanced.
    /// @return totalValidatorToWithdrawFrom the number of validator to withdraw from when the system is balanced.
    function getValidatorsRequestWithdraw(uint256 _withdrawAmount)
        external
        view
        returns (
            ValidatorData[] memory validators,
            uint256 totalDelegated,
            uint256 bigNodeOperatorLength,
            uint256[] memory bigNodeOperatorIds,
            uint256 smallNodeOperatorLength,
            uint256[] memory smallNodeOperatorIds,
            uint256[] memory operatorAmountCanBeRequested,
            uint256 totalValidatorToWithdrawFrom
        );

    /// @notice Returns a node operator.
    /// @param validatorId the validator id on stakeManager.
    /// @return operatorStatus a node operator.
    function getNodeOperator(uint256 validatorId)
        external
        view
        returns (FullNodeOperatorRegistry memory operatorStatus);

    /// @notice Returns a node operator.
    /// @param rewardAddress the reward address.
    /// @return operatorStatus a node operator.
    function getNodeOperator(address rewardAddress)
        external
        view
        returns (FullNodeOperatorRegistry memory operatorStatus);

    /// @notice Returns a node operator status.
    /// @param  validatorId is the id of the node operator.
    /// @return operatorStatus Returns a node operator status.
    function getNodeOperatorStatus(uint256 validatorId)
        external
        view
        returns (NodeOperatorRegistryStatus operatorStatus);

    /// @notice Return a list of all validator ids in the system.
    function getValidatorIds() external view returns (uint256[] memory);

    /// @notice Explain to an end user what this does
    /// @return isBalanced if the system is balanced or not.
    /// @return distanceThreshold the distance threshold
    /// @return minAmount min amount delegated to a validator.
    /// @return maxAmount max amount delegated to a validator.
    function getProtocolStats()
        external
        view
        returns (
            bool isBalanced,
            uint256 distanceThreshold,
            uint256 minAmount,
            uint256 maxAmount
        );

    /// @notice List all the node operator statuses in the system.
    /// @return inactiveNodeOperator the number of inactive operators.
    /// @return activeNodeOperator the number of active operators.
    /// @return jailedNodeOperator the number of jailed operators.
    /// @return ejectedNodeOperator the number of ejected operators.
    /// @return unstakedNodeOperator the number of unstaked operators.
    function getStats()
        external
        view
        returns (
            uint256 inactiveNodeOperator,
            uint256 activeNodeOperator,
            uint256 jailedNodeOperator,
            uint256 ejectedNodeOperator,
            uint256 unstakedNodeOperator
        );

    ////////////////////////////////////////////////////////////
    /////                                                    ///
    /////                 ***EVENTS***                       ///
    /////                                                    ///
    ////////////////////////////////////////////////////////////

    /// @notice Add Node Operator event
    /// @param validatorId validator id.
    /// @param rewardAddress reward address.
    event AddNodeOperator(uint256 validatorId, address rewardAddress);

    /// @notice Remove Node Operator event.
    /// @param validatorId validator id.
    /// @param rewardAddress reward address.
    event RemoveNodeOperator(uint256 validatorId, address rewardAddress);

    /// @notice Remove Invalid Node Operator event.
    /// @param validatorId validator id.
    /// @param rewardAddress reward address.
    event RemoveInvalidNodeOperator(uint256 validatorId, address rewardAddress);

    /// @notice Set StMatic address event.
    /// @param oldStMatic old stMatic address.
    /// @param newStMatic new stMatic address.
    event SetStMaticAddress(address oldStMatic, address newStMatic);

    /// @notice Set reward address event.
    /// @param validatorId the validator id.
    /// @param oldRewardAddress old reward address.
    /// @param newRewardAddress new reward address.
    event SetRewardAddress(
        uint256 validatorId,
        address oldRewardAddress,
        address newRewardAddress
    );

    /// @notice Emit when the distance threshold is changed.
    /// @param oldDistanceThreshold the old distance threshold.
    /// @param newDistanceThreshold the new distance threshold.
    event SetDistanceThreshold(
        uint256 oldDistanceThreshold,
        uint256 newDistanceThreshold
    );

    /// @notice Emit when the min request withdraw range is changed.
    /// @param oldMinRequestWithdrawRange the old min request withdraw range.
    /// @param newMinRequestWithdrawRange the new min request withdraw range.
    event SetMinRequestWithdrawRange(
        uint8 oldMinRequestWithdrawRange,
        uint8 newMinRequestWithdrawRange
    );

    /// @notice Emit when the max withdraw percentage per rebalance is changed.
    /// @param oldMaxWithdrawPercentagePerRebalance the old max withdraw percentage per rebalance.
    /// @param newMaxWithdrawPercentagePerRebalance the new max withdraw percentage per rebalance.
    event SetMaxWithdrawPercentagePerRebalance(
        uint256 oldMaxWithdrawPercentagePerRebalance,
        uint256 newMaxWithdrawPercentagePerRebalance
    );

    /// @notice Emit when set new version.
    /// @param oldVersion the old version.
    /// @param newVersion the new version.
    event SetVersion(string oldVersion, string newVersion);

    /// @notice Emit when the node operator exits the registry
    /// @param validatorId node operator id
    /// @param rewardAddress node operator reward address
    event ExitNodeOperator(uint256 validatorId, address rewardAddress);
}

// SPDX-FileCopyrightText: 2021 ShardLabs
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "./IValidatorShare.sol";
import "./INodeOperatorRegistry.sol";
import "./IStakeManager.sol";
import "./IPoLidoNFT.sol";
import "./IFxStateRootTunnel.sol";

/// @title StMATIC interface.
/// @author 2021 ShardLabs
interface IStMATIC is IERC20Upgradeable {
    /// @notice The request withdraw struct.
    /// @param amount2WithdrawFromStMATIC amount in Matic.
    /// @param validatorNonce validator nonce.
    /// @param requestTime request epoch.
    /// @param validatorAddress validator share address.
    struct RequestWithdraw {
        uint256 amount2WithdrawFromStMATIC;
        uint256 validatorNonce;
        uint256 requestTime;
        address validatorAddress;
    }

    /// @notice The fee distribution struct.
    /// @param dao dao fee.
    /// @param operators operators fee.
    /// @param insurance insurance fee.
    struct FeeDistribution {
        uint8 dao;
        uint8 operators;
        uint8 insurance;
    }

    /// @notice node operator registry interface.
    function nodeOperator()
        external
        view
        returns (INodeOperatorRegistry);

    /// @notice The fee distribution.
    /// @return dao dao fee.
    /// @return operators operators fee.
    /// @return insurance insurance fee.
    function entityFees()
        external
        view
        returns (
            uint8,
            uint8,
            uint8
        );

    /// @notice StakeManager interface.
    function stakeManager() external view returns (IStakeManager);

    /// @notice LidoNFT interface.
    function poLidoNFT() external view returns (IPoLidoNFT);

    /// @notice fxStateRootTunnel interface.
    function fxStateRootTunnel() external view returns (IFxStateRootTunnel);

    /// @notice contract version.
    function version() external view returns (string memory);

    /// @notice dao address.
    function dao() external view returns (address);

    /// @notice insurance address.
    function insurance() external view returns (address);

    /// @notice Matic ERC20 token.
    function token() external view returns (address);

    /// @notice Matic ERC20 token address NOT USED IN V2.
    function lastWithdrawnValidatorId() external view returns (uint256);

    /// @notice total buffered Matic in the contract.
    function totalBuffered() external view returns (uint256);

    /// @notice delegation lower bound.
    function delegationLowerBound() external view returns (uint256);

    /// @notice reward distribution lower bound.
    function rewardDistributionLowerBound() external view returns (uint256);

    /// @notice reserved funds in Matic.
    function reservedFunds() external view returns (uint256);

    /// @notice submit threshold NOT USED in V2.
    function submitThreshold() external view returns (uint256);

    /// @notice submit handler NOT USED in V2.
    function submitHandler() external view returns (bool);

    /// @notice token to WithdrawRequest mapping.
    function token2WithdrawRequest(uint256 _requestId)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            address
        );

    /// @notice DAO Role.
    function DAO() external view returns (bytes32);

    /// @notice PAUSE_ROLE Role.
    function PAUSE_ROLE() external view returns (bytes32);

    /// @notice UNPAUSE_ROLE Role.
    function UNPAUSE_ROLE() external view returns (bytes32);

    /// @notice Protocol Fee.
    function protocolFee() external view returns (uint8);

    /// @param _nodeOperatorRegistry - Address of the node operator registry
    /// @param _token - Address of MATIC token on Ethereum Mainnet
    /// @param _dao - Address of the DAO
    /// @param _insurance - Address of the insurance
    /// @param _stakeManager - Address of the stake manager
    /// @param _poLidoNFT - Address of the stMATIC NFT
    /// @param _fxStateRootTunnel - Address of the FxStateRootTunnel
    function initialize(
        address _nodeOperatorRegistry,
        address _token,
        address _dao,
        address _insurance,
        address _stakeManager,
        address _poLidoNFT,
        address _fxStateRootTunnel
    ) external;

    /// @notice Send funds to StMATIC contract and mints StMATIC to msg.sender
    /// @notice Requires that msg.sender has approved _amount of MATIC to this contract
    /// @param _amount - Amount of MATIC sent from msg.sender to this contract
    /// @return Amount of StMATIC shares generated
    function submit(uint256 _amount) external returns (uint256);

    /// @notice Stores users request to withdraw into a RequestWithdraw struct
    /// @param _amount - Amount of StMATIC that is requested to withdraw
    function requestWithdraw(uint256 _amount) external;

    /// @notice This will be included in the cron job
    /// @notice Delegates tokens to validator share contract
    function delegate() external;

    /// @notice Claims tokens from validator share and sends them to the
    /// StMATIC contract
    /// @param _tokenId - Id of the token that is supposed to be claimed
    function claimTokens(uint256 _tokenId) external;

    /// @notice Distributes rewards claimed from validator shares based on fees defined
    /// in entityFee.
    function distributeRewards() external;

    /// @notice withdraw total delegated
    /// @param _validatorShare validator share address.
    function withdrawTotalDelegated(address _validatorShare) external;

    /// @notice Claims tokens from validator share and sends them to the
    /// StMATIC contract
    /// @param _tokenId - Id of the token that is supposed to be claimed
    function claimTokensFromValidatorToContract(uint256 _tokenId) external;

    /// @notice Rebalane the system by request withdraw from the validators that contains
    /// more token delegated to them.
    function rebalanceDelegatedTokens() external;

    /// @notice Helper function for that returns total pooled MATIC
    /// @return Total pooled MATIC
    function getTotalStake(IValidatorShare _validatorShare)
        external
        view
        returns (uint256, uint256);

    /// @notice API for liquid rewards of this contract from validatorShare
    /// @param _validatorShare - Address of validatorShare contract
    /// @return Liquid rewards of this contract
    function getLiquidRewards(IValidatorShare _validatorShare)
        external
        view
        returns (uint256);

    /// @notice Helper function for that returns total pooled MATIC
    /// @return Total pooled MATIC
    function getTotalStakeAcrossAllValidators() external view returns (uint256);

    /// @notice Function that calculates total pooled Matic
    /// @return Total pooled Matic
    function getTotalPooledMatic() external view returns (uint256);

    /// @notice get Matic from token id.
    /// @param _tokenId NFT token id.
    /// @return total the amount in Matic.
    function getMaticFromTokenId(uint256 _tokenId)
        external
        view
        returns (uint256);

    /// @notice calculate the total amount stored in all the NFTs owned by
    /// stMatic contract.
    /// @return pendingBufferedTokens the total pending amount for stMatic.
    function calculatePendingBufferedTokens() external view returns(uint256);

    /// @notice Function that converts arbitrary stMATIC to Matic
    /// @param _amountInStMatic - Amount of stMATIC to convert to Matic
    /// @return amountInMatic - Amount of Matic after conversion,
    /// @return totalStMaticAmount - Total StMatic in the contract,
    /// @return totalPooledMatic - Total Matic in the staking pool
    function convertStMaticToMatic(uint256 _amountInStMatic)
        external
        view
        returns (
            uint256 amountInMatic,
            uint256 totalStMaticAmount,
            uint256 totalPooledMatic
        );

    /// @notice Function that converts arbitrary Matic to stMATIC
    /// @param _amountInMatic - Amount of Matic to convert to stMatic
    /// @return amountInStMatic - Amount of Matic to converted to stMatic
    /// @return totalStMaticSupply - Total amount of StMatic in the contract
    /// @return totalPooledMatic - Total amount of Matic in the staking pool
    function convertMaticToStMatic(uint256 _amountInMatic)
        external
        view
        returns (
            uint256 amountInStMatic,
            uint256 totalStMaticSupply,
            uint256 totalPooledMatic
        );

    /// @notice Allows to set fees.
    /// @param _daoFee the new daoFee
    /// @param _operatorsFee the new operatorsFee
    /// @param _insuranceFee the new insuranceFee
    function setFees(
        uint8 _daoFee,
        uint8 _operatorsFee,
        uint8 _insuranceFee
    ) external;

    /// @notice Function that sets protocol fee
    /// @param _newProtocolFee - Insurance fee in %
    function setProtocolFee(uint8 _newProtocolFee) external;

    /// @notice Allows to set DaoAddress.
    /// @param _newDaoAddress new DaoAddress.
    function setDaoAddress(address _newDaoAddress) external;

    /// @notice Allows to set InsuranceAddress.
    /// @param _newInsuranceAddress new InsuranceAddress.
    function setInsuranceAddress(address _newInsuranceAddress) external;

    /// @notice Allows to set NodeOperatorRegistryAddress.
    /// @param _newNodeOperatorRegistry new NodeOperatorRegistryAddress.
    function setNodeOperatorRegistryAddress(address _newNodeOperatorRegistry)
        external;

    /// @notice Allows to set delegationLowerBound.
    /// @param _delegationLowerBound new delegationLowerBound.
    function setDelegationLowerBound(uint256 _delegationLowerBound) external;

    /// @notice Allows to set setRewardDistributionLowerBound.
    /// @param _rewardDistributionLowerBound new setRewardDistributionLowerBound.
    function setRewardDistributionLowerBound(
        uint256 _rewardDistributionLowerBound
    ) external;

    /// @notice Allows to set LidoNFT.
    /// @param _poLidoNFT new LidoNFT.
    function setPoLidoNFT(address _poLidoNFT) external;

    /// @notice Allows to set fxStateRootTunnel.
    /// @param _fxStateRootTunnel new fxStateRootTunnel.
    function setFxStateRootTunnel(address _fxStateRootTunnel) external;

    /// @notice Allows to set new version.
    /// @param _newVersion new contract version.
    function setVersion(string calldata _newVersion) external;

    ////////////////////////////////////////////////////////////
    /////                                                    ///
    /////                 ***EVENTS***                       ///
    /////                                                    ///
    ////////////////////////////////////////////////////////////

    /// @notice Emit when submit.
    /// @param _from msg.sender.
    /// @param _amount amount.
    event SubmitEvent(address indexed _from, uint256 indexed _amount);

    /// @notice Emit when request withdraw.
    /// @param _from msg.sender.
    /// @param _amount amount.
    event RequestWithdrawEvent(address indexed _from, uint256 indexed _amount);

    /// @notice Emit when distribute rewards.
    /// @param _amount amount.
    event DistributeRewardsEvent(uint256 indexed _amount);

    /// @notice Emit when withdraw total delegated.
    /// @param _from msg.sender.
    /// @param _amount amount.
    event WithdrawTotalDelegatedEvent(
        address indexed _from,
        uint256 indexed _amount
    );

    /// @notice Emit when delegate.
    /// @param _amountDelegated amount to delegate.
    /// @param _remainder remainder.
    event DelegateEvent(
        uint256 indexed _amountDelegated,
        uint256 indexed _remainder
    );

    /// @notice Emit when ClaimTokens.
    /// @param _from msg.sender.
    /// @param _id token id.
    /// @param _amountClaimed amount Claimed.
    /// @param _amountBurned amount Burned.
    event ClaimTokensEvent(
        address indexed _from,
        uint256 indexed _id,
        uint256 indexed _amountClaimed,
        uint256 _amountBurned
    );

    /// @notice Emit when set new InsuranceAddress.
    /// @param _newInsuranceAddress the new InsuranceAddress.
    event SetInsuranceAddress(address indexed _newInsuranceAddress);

    /// @notice Emit when set new NodeOperatorRegistryAddress.
    /// @param _newNodeOperatorRegistryAddress the new NodeOperatorRegistryAddress.
    event SetNodeOperatorRegistryAddress(
        address indexed _newNodeOperatorRegistryAddress
    );

    /// @notice Emit when set new SetDelegationLowerBound.
    /// @param _delegationLowerBound the old DelegationLowerBound.
    event SetDelegationLowerBound(uint256 indexed _delegationLowerBound);

    /// @notice Emit when set new RewardDistributionLowerBound.
    /// @param oldRewardDistributionLowerBound the old RewardDistributionLowerBound.
    /// @param newRewardDistributionLowerBound the new RewardDistributionLowerBound.
    event SetRewardDistributionLowerBound(
        uint256 oldRewardDistributionLowerBound,
        uint256 newRewardDistributionLowerBound
    );

    /// @notice Emit when set new LidoNFT.
    /// @param oldLidoNFT the old oldLidoNFT.
    /// @param newLidoNFT the new newLidoNFT.
    event SetLidoNFT(address oldLidoNFT, address newLidoNFT);

    /// @notice Emit when set new FxStateRootTunnel.
    /// @param oldFxStateRootTunnel the old FxStateRootTunnel.
    /// @param newFxStateRootTunnel the new FxStateRootTunnel.
    event SetFxStateRootTunnel(
        address oldFxStateRootTunnel,
        address newFxStateRootTunnel
    );

    /// @notice Emit when set new DAO.
    /// @param oldDaoAddress the old DAO.
    /// @param newDaoAddress the new DAO.
    event SetDaoAddress(address oldDaoAddress, address newDaoAddress);

    /// @notice Emit when set fees.
    /// @param daoFee the new daoFee
    /// @param operatorsFee the new operatorsFee
    /// @param insuranceFee the new insuranceFee
    event SetFees(uint256 daoFee, uint256 operatorsFee, uint256 insuranceFee);

    /// @notice Emit when set ProtocolFee.
    /// @param oldProtocolFee the new ProtocolFee
    /// @param newProtocolFee the new ProtocolFee
    event SetProtocolFee(uint8 oldProtocolFee, uint8 newProtocolFee);

    /// @notice Emit when set ProtocolFee.
    /// @param validatorShare vaidatorshare address.
    /// @param amountClaimed amount claimed.
    event ClaimTotalDelegatedEvent(
        address indexed validatorShare,
        uint256 indexed amountClaimed
    );

    /// @notice Emit when set version.
    /// @param oldVersion old.
    /// @param newVersion new.
    event Version(
        string oldVersion,
        string indexed newVersion
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
}

// SPDX-FileCopyrightText: 2021 ShardLabs
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

/// @title polygon stake manager interface.
/// @author 2021 ShardLabs
interface IStakeManager {
    /// @dev Plygon stakeManager status and Validator struct
    /// https://github.com/maticnetwork/contracts/blob/v0.3.0-backport/contracts/staking/stakeManager/StakeManagerStorage.sol
    enum Status {
        Inactive,
        Active,
        Locked,
        Unstaked
    }

    struct Validator {
        uint256 amount;
        uint256 reward;
        uint256 activationEpoch;
        uint256 deactivationEpoch;
        uint256 jailTime;
        address signer;
        address contractAddress;
        Status status;
        uint256 commissionRate;
        uint256 lastCommissionUpdate;
        uint256 delegatorsReward;
        uint256 delegatedAmount;
        uint256 initialRewardPerStake;
    }

    /// @notice get the validator contract used for delegation.
    /// @param validatorId validator id.
    /// @return return the address of the validator contract.
    function getValidatorContract(uint256 validatorId)
        external
        view
        returns (address);

    /// @notice Transfers amount from delegator
    function delegationDeposit(
        uint256 validatorId,
        uint256 amount,
        address delegator
    ) external returns (bool);

    function epoch() external view returns (uint256);

    function validators(uint256 _index)
        external
        view
        returns (Validator memory);

    /// @notice Returns a withdrawal delay.
    function withdrawalDelay() external  view returns (uint256);
}

// SPDX-FileCopyrightText: 2021 ShardLabs
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

/// @title PoLidoNFT interface.
/// @author 2021 ShardLabs
interface IPoLidoNFT is IERC721Upgradeable {
    
    /// @notice Mint a new Lido NFT for a _to address.
    /// @param _to owner of the NFT.
    /// @return tokenId returns the token id.
    function mint(address _to) external returns (uint256);

    /// @notice Burn a Lido NFT for a _to address.
    /// @param _tokenId the token id.
    function burn(uint256 _tokenId) external;

    /// @notice Check if the spender is the owner of the NFT or it was approved to it.
    /// @param _spender the spender address.
    /// @param _tokenId the token id.
    /// @return result return if the token is owned or approved to/by the spender.
    function isApprovedOrOwner(address _spender, uint256 _tokenId)
        external
        view
        returns (bool);

    /// @notice Set stMatic address.
    /// @param _stMATIC new stMatic address.
    function setStMATIC(address _stMATIC) external;

    /// @notice List all the tokens owned by an address.
    /// @param _owner the owner address.
    /// @return result return a list of token ids.
    function getOwnedTokens(address _owner) external view returns (uint256[] memory);

    /// @notice toggle pause/unpause the contract
    function togglePause() external;

    /// @notice Allows to set new version.
    /// @param _newVersion new contract version.
    function setVersion(string calldata _newVersion) external;
}

// SPDX-FileCopyrightText: 2021 ShardLabs
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

interface IFxStateRootTunnel {

    /// @notice send message to child
    /// @param _message message
    function sendMessageToChild(bytes memory _message) external;

    /// @notice Set stMatic address.
    /// @param _newStMATIC the new stMatic address.
    function setStMATIC(address _newStMATIC) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}