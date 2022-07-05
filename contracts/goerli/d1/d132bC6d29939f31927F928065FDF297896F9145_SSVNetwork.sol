// File: contracts/SSVNetwork.sol
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./utils/VersionedContract.sol";
import "./ISSVNetwork.sol";

contract SSVNetwork is Initializable, OwnableUpgradeable, ISSVNetwork, VersionedContract {
    struct OperatorData {
        uint256 blockNumber;
        uint256 earnings;
        uint256 index;
        uint256 indexBlockNumber;
        uint32 activeValidatorCount;
    }

    struct OwnerData {
        uint256 deposited;
        uint256 withdrawn;
        uint256 used;
        uint256 networkFee;
        uint256 networkFeeIndex;
        uint32 activeValidatorCount;
        bool validatorsDisabled;
    }

    struct OperatorInUse {
        uint256 index;
        uint256 used;
        uint32 validatorCount;
        uint32 indexInArray;
        bool exists;
    }

    struct FeeChangeRequest {
        uint256 fee;
        uint256 approvalBeginTime;
        uint256 approvalEndTime;
    }

    ISSVRegistry private _ssvRegistryContract;
    IERC20 private _token;
    uint256 private _minimumBlocksBeforeLiquidation;
    uint256 private _operatorMaxFeeIncrease;

    uint256 private _networkFee;
    uint256 private _networkFeeIndex;
    uint256 private _networkFeeIndexBlockNumber;
    uint256 private _networkEarnings;
    uint256 private _networkEarningsBlockNumber;
    uint256 private _withdrawnFromTreasury;

    mapping(uint32 => OperatorData) private _operatorDatas;
    mapping(address => OwnerData) private _owners;
    mapping(address => mapping(uint32 => OperatorInUse)) private _operatorsInUseByAddress;
    mapping(address => uint32[]) private _operatorsInUseList;

    uint256 private _declareOperatorFeePeriod;
    uint256 private _executeOperatorFeePeriod;
    mapping(uint32 => FeeChangeRequest) private _feeChangeRequests;

    uint256 constant MINIMAL_OPERATOR_FEE = 10000;

    uint256 constant MANAGING_OPERATORS_PER_ACCOUNT_LIMIT = 50;

    function initialize(
        ISSVRegistry registryAddress_,
        IERC20 token_,
        uint256 minimumBlocksBeforeLiquidation_,
        uint256 operatorMaxFeeIncrease_,
        uint256 declareOperatorFeePeriod_,
        uint256 executeOperatorFeePeriod_,
        uint16 validatorsPerOperatorLimit_,
        uint16 registeredOperatorsPerAccountLimit_
    ) external initializer override {
        __SSVNetwork_init(registryAddress_, token_, minimumBlocksBeforeLiquidation_, operatorMaxFeeIncrease_, declareOperatorFeePeriod_, executeOperatorFeePeriod_, validatorsPerOperatorLimit_, registeredOperatorsPerAccountLimit_);
    }

    function __SSVNetwork_init(
        ISSVRegistry registryAddress_,
        IERC20 token_,
        uint256 minimumBlocksBeforeLiquidation_,
        uint256 operatorMaxFeeIncrease_,
        uint256 declareOperatorFeePeriod_,
        uint256 executeOperatorFeePeriod_,
        uint16 validatorsPerOperatorLimit_,
        uint16 registeredOperatorsPerAccountLimit_
    ) internal initializer {
        __Ownable_init_unchained();
        __SSVNetwork_init_unchained(registryAddress_, token_, minimumBlocksBeforeLiquidation_, operatorMaxFeeIncrease_, declareOperatorFeePeriod_, executeOperatorFeePeriod_, validatorsPerOperatorLimit_, registeredOperatorsPerAccountLimit_);
    }

    function __SSVNetwork_init_unchained(
        ISSVRegistry registryAddress_,
        IERC20 token_,
        uint256 minimumBlocksBeforeLiquidation_,
        uint256 operatorMaxFeeIncrease_,
        uint256 declareOperatorFeePeriod_,
        uint256 executeOperatorFeePeriod_,
        uint16 validatorsPerOperatorLimit_,
        uint16 registeredOperatorsPerAccountLimit_
    ) internal onlyInitializing {
        _ssvRegistryContract = registryAddress_;
        _token = token_;
        _updateLiquidationThresholdPeriod(minimumBlocksBeforeLiquidation_);
        _updateOperatorFeeIncreaseLimit(operatorMaxFeeIncrease_);
        _updateDeclareOperatorFeePeriod(declareOperatorFeePeriod_);
        _updateExecuteOperatorFeePeriod(executeOperatorFeePeriod_);
        _ssvRegistryContract.initialize(validatorsPerOperatorLimit_, registeredOperatorsPerAccountLimit_);
    }

    modifier onlyValidatorOwnerOrContractOwner(bytes calldata publicKey) {
        address validatorOwner = _ssvRegistryContract.getValidatorOwner(publicKey);
        require(
            validatorOwner != address(0),
            "validator with public key does not exist"
        );
        require(msg.sender == validatorOwner || msg.sender == owner(), "caller is not validator owner");
        _;
    }

    modifier onlyOperatorOwnerOrContractOwner(uint32 operatorId) {
        address operatorOwner = _ssvRegistryContract.getOperatorOwner(operatorId);
        require(
            operatorOwner != address(0),
            "operator with public key does not exist"
        );
        require(msg.sender == operatorOwner || msg.sender == owner(), "caller is not operator owner");
        _;
    }

    modifier ensureMinimalOperatorFee(uint256 fee) {
        require(fee >= MINIMAL_OPERATOR_FEE, "fee is too low");
        _;
    }

    /**
     * @dev See {ISSVNetwork-registerOperator}.
     */
    function registerOperator(
        string calldata name,
        bytes calldata publicKey,
        uint256 fee
    ) ensureMinimalOperatorFee(fee) external override returns (uint32 operatorId) {
        operatorId = _ssvRegistryContract.registerOperator(
            name,
            msg.sender,
            publicKey,
            fee
        );

        _operatorDatas[operatorId] = OperatorData({ blockNumber: block.number, earnings: 0, index: 0, indexBlockNumber: block.number, activeValidatorCount: 0 });
        emit OperatorAdded(operatorId, name, msg.sender, publicKey, fee);
    }

    /**
     * @dev See {ISSVNetwork-removeOperator}.
     */
    function removeOperator(uint32 operatorId) onlyOperatorOwnerOrContractOwner(operatorId) external override {
        address owner = _ssvRegistryContract.getOperatorOwner(operatorId);

        _updateOperatorFeeUnsafe(operatorId, 0);
        _ssvRegistryContract.removeOperator(operatorId);

        emit OperatorRemoved(operatorId, owner);
    }

    function declareOperatorFee(uint32 operatorId, uint256 fee) onlyOperatorOwnerOrContractOwner(operatorId) ensureMinimalOperatorFee(fee) external override {
        require(fee <= _ssvRegistryContract.getOperatorFee(operatorId) * (100000 + _operatorMaxFeeIncrease) / 100000, "fee exceeds increase limit");
        _feeChangeRequests[operatorId] = FeeChangeRequest(fee, block.timestamp + _declareOperatorFeePeriod, block.timestamp + _declareOperatorFeePeriod + _executeOperatorFeePeriod);

        emit OperatorFeeSet(msg.sender, operatorId, block.number, fee);
    }

    function cancelDeclaredOperatorFee(uint32 operatorId) onlyOperatorOwnerOrContractOwner(operatorId) external override {
        delete _feeChangeRequests[operatorId];

        emit OperatorFeeSetCanceled(msg.sender, operatorId);
    }

    function executeOperatorFee(uint32 operatorId) onlyOperatorOwnerOrContractOwner(operatorId) external override {
        FeeChangeRequest storage feeChangeRequest = _feeChangeRequests[operatorId];

        require(feeChangeRequest.fee > 0, "no pending fee change request");
        require(block.timestamp >= feeChangeRequest.approvalBeginTime && block.timestamp <= feeChangeRequest.approvalEndTime, "approval not within timeframe");

        _updateOperatorFeeUnsafe(operatorId, feeChangeRequest.fee);

        emit OperatorFeeApproved(msg.sender, operatorId, block.number, feeChangeRequest.fee);

        delete _feeChangeRequests[operatorId];
    }

    function updateOperatorScore(uint32 operatorId, uint16 score) onlyOwner external override {
        _ssvRegistryContract.updateOperatorScore(operatorId, score);

        emit OperatorScoreUpdated(operatorId, msg.sender, block.number, score);
    }

    /**
     * @dev See {ISSVNetwork-registerValidator}.
     */
    function registerValidator(
        bytes calldata publicKey,
        uint32[] calldata operatorIds,
        bytes[] calldata sharesPublicKeys,
        bytes[] calldata encryptedKeys,
        uint256 tokenAmount
    ) external override {
        _updateNetworkEarnings();
        _updateAddressNetworkFee(msg.sender);
        _registerValidatorUnsafe(msg.sender, publicKey, operatorIds, sharesPublicKeys, encryptedKeys, tokenAmount);
    }

    /**
     * @dev See {ISSVNetwork-updateValidator}.
     */
    function updateValidator(
        bytes calldata publicKey,
        uint32[] calldata operatorIds,
        bytes[] calldata sharesPublicKeys,
        bytes[] calldata encryptedKeys,
        uint256 tokenAmount
    ) onlyValidatorOwnerOrContractOwner(publicKey) external override {
        _removeValidatorUnsafe(msg.sender, publicKey);
        _registerValidatorUnsafe(msg.sender, publicKey, operatorIds, sharesPublicKeys, encryptedKeys, tokenAmount);
    }

    /**
     * @dev See {ISSVNetwork-removeValidator}.
     */
    function removeValidator(bytes calldata publicKey) onlyValidatorOwnerOrContractOwner(publicKey) external override {
        _updateNetworkEarnings();
        _updateAddressNetworkFee(msg.sender);
        _removeValidatorUnsafe(msg.sender, publicKey);
        _totalBalanceOf(msg.sender); // For assertion
    }

    function deposit(address ownerAddress, uint256 tokenAmount) external override {
        _deposit(ownerAddress, tokenAmount);
    }

    function withdraw(uint256 tokenAmount) external override {
        require(_totalBalanceOf(msg.sender) >= tokenAmount, "not enough balance");

        _withdrawUnsafe(tokenAmount);

        require(!_liquidatable(msg.sender), "not enough balance");
    }

    function withdrawAll() external override {
        require(_burnRate(msg.sender) == 0, "burn rate positive");

        _withdrawUnsafe(_totalBalanceOf(msg.sender));
    }

    function liquidate(address[] calldata ownerAddresses) external override {
        uint balanceToTransfer = 0;

        for (uint256 index = 0; index < ownerAddresses.length; ++index) {
            if (_canLiquidate(ownerAddresses[index])) {
                balanceToTransfer += _liquidateUnsafe(ownerAddresses[index]);
            }
        }

        _token.transfer(msg.sender, balanceToTransfer);
    }

    function reactivateAccount(uint256 tokenAmount) external override {
        require(_owners[msg.sender].validatorsDisabled, "account already enabled");

        _deposit(msg.sender, tokenAmount);

        _enableOwnerValidatorsUnsafe(msg.sender);

        require(!_liquidatable(msg.sender), "not enough balance");

        emit AccountEnabled(msg.sender);
    }

    function updateLiquidationThresholdPeriod(uint256 newMinimumBlocksBeforeLiquidation) external onlyOwner override {
        _updateLiquidationThresholdPeriod(newMinimumBlocksBeforeLiquidation);
    }

    function updateOperatorFeeIncreaseLimit(uint256 newOperatorMaxFeeIncrease) external onlyOwner override {
        _updateOperatorFeeIncreaseLimit(newOperatorMaxFeeIncrease);
    }

    function updateDeclareOperatorFeePeriod(uint256 newDeclareOperatorFeePeriod) external onlyOwner override {
        _updateDeclareOperatorFeePeriod(newDeclareOperatorFeePeriod);
    }

    function updateExecuteOperatorFeePeriod(uint256 newExecuteOperatorFeePeriod) external onlyOwner override {
        _updateExecuteOperatorFeePeriod(newExecuteOperatorFeePeriod);
    }

    /**
     * @dev See {ISSVNetwork-updateNetworkFee}.
     */
    function updateNetworkFee(uint256 fee) external onlyOwner override {
        emit NetworkFeeUpdated(_networkFee, fee);
        _updateNetworkEarnings();
        _updateNetworkFeeIndex();
        _networkFee = fee;
    }

    function withdrawNetworkEarnings(uint256 amount) external onlyOwner override {
        require(amount <= _getNetworkTreasury(), "not enough balance");
        _withdrawnFromTreasury += amount;
        _token.transfer(msg.sender, amount);

        emit NetworkFeesWithdrawn(amount, msg.sender);
    }

    function getAddressBalance(address ownerAddress) external override view returns (uint256) {
        return _totalBalanceOf(ownerAddress);
    }

    function isLiquidated(address ownerAddress) external view override returns (bool) {
        return _owners[ownerAddress].validatorsDisabled;
    }

    /**
     * @dev See {ISSVNetwork-getOperatorById}.
     */
    function getOperatorById(uint32 operatorId) external view override returns (string memory, address, bytes memory, uint256, uint256, uint256, bool) {
        return _ssvRegistryContract.getOperatorById(operatorId);
    }

    /**
     * @dev See {ISSVNetwork-getOperatorByPublicKey}.
     */
    function getOperatorByPublicKey(bytes memory publicKey) external view override returns (string memory, address, bytes memory, uint256, uint256, uint256, bool) {
        return _ssvRegistryContract.getOperatorByPublicKey(publicKey);
    }

    function getOperatorDeclaredFee(uint32 operatorId) external view override returns (uint256, uint256, uint256) {
        FeeChangeRequest storage feeChangeRequest = _feeChangeRequests[operatorId];

        return (feeChangeRequest.fee, feeChangeRequest.approvalBeginTime, feeChangeRequest.approvalEndTime);
    }

    /**
     * @dev See {ISSVNetwork-getOperatorFee}.
     */
    function getOperatorFee(uint32 operatorId) external view override returns (uint256) {
        return _ssvRegistryContract.getOperatorFee(operatorId);
    }

    /**
     * @dev See {ISSVNetwork-getOperatorsByValidator}.
     */
    function getOperatorsByValidator(bytes memory publicKey) external view override returns (uint32[] memory) {
        return _ssvRegistryContract.getOperatorsByValidator(publicKey);
    }

    /**
     * @dev See {ISSVNetwork-getValidatorsByAddress}.
     */
    function getValidatorsByOwnerAddress(address ownerAddress) external view override returns (bytes[] memory) {
        return _ssvRegistryContract.getValidatorsByAddress(ownerAddress);
    }

    /**
     * @dev See {ISSVNetwork-addressNetworkFee}.
     */
    function addressNetworkFee(address ownerAddress) external view override returns (uint256) {
        return _addressNetworkFee(ownerAddress);
    }

    function getAddressBurnRate(address ownerAddress) external view override returns (uint256) {
        return _burnRate(ownerAddress);
    }

    function isLiquidatable(address ownerAddress) external view override returns (bool) {
        return _liquidatable(ownerAddress);
    }

    function getNetworkFee() external view override returns (uint256) {
        return _networkFee;
    }

    function getNetworkEarnings() external view override returns (uint256) {
        return _getNetworkTreasury();
    }

    function getLiquidationThresholdPeriod() external view override returns (uint256) {
        return _minimumBlocksBeforeLiquidation;
    }

    function getOperatorFeeIncreaseLimit() external view override returns (uint256) {
        return _operatorMaxFeeIncrease;
    }

    function getExecuteOperatorFeePeriod() external view override returns (uint256) {
        return _executeOperatorFeePeriod;
    }

    function getDeclaredOperatorFeePeriod() external view override returns (uint256) {
        return _declareOperatorFeePeriod;
    }

    function updateValidatorsPerOperatorLimit(uint16 validatorsPerOperatorLimit_) external onlyOwner {
        _ssvRegistryContract.updateValidatorsPerOperatorLimit(validatorsPerOperatorLimit_);

        emit ValidatorsPerOperatorLimitUpdated(validatorsPerOperatorLimit_);
    }

    function updateRegisteredOperatorsPerAccountLimit(uint16 registeredOperatorsPerAccountLimit_) external onlyOwner {
        _ssvRegistryContract.updateRegisteredOperatorsPerAccountLimit(registeredOperatorsPerAccountLimit_);

        emit RegisteredOperatorsPerAccountLimitUpdated(registeredOperatorsPerAccountLimit_);
    }

    function validatorsPerOperatorCount(uint32 operatorId_) external view returns (uint16) {
        return _ssvRegistryContract.validatorsPerOperatorCount(operatorId_);
    }

    function getValidatorsPerOperatorLimit() external view returns (uint16) {
        return _ssvRegistryContract.getValidatorsPerOperatorLimit();
    }

    function getRegisteredOperatorsPerAccountLimit() external view returns (uint256) {
        return _ssvRegistryContract.getRegisteredOperatorsPerAccountLimit();
    }

    function _deposit(address ownerAddress, uint256 tokenAmount) private {
        _token.transferFrom(msg.sender, address(this), tokenAmount);
        _owners[ownerAddress].deposited += tokenAmount;

        emit FundsDeposited(tokenAmount, ownerAddress, msg.sender);
    }

    function _withdrawUnsafe(uint256 tokenAmount) private {
        _owners[msg.sender].withdrawn += tokenAmount;
        _token.transfer(msg.sender, tokenAmount);

        emit FundsWithdrawn(tokenAmount, msg.sender);
    }

    /**
     * @dev Update network fee for the address.
     * @param ownerAddress Owner address.
     */
    function _updateAddressNetworkFee(address ownerAddress) private {
        _owners[ownerAddress].networkFee = _addressNetworkFee(ownerAddress);
        _owners[ownerAddress].networkFeeIndex = _currentNetworkFeeIndex();
    }

    function _updateOperatorIndex(uint32 operatorId) private {
        _operatorDatas[operatorId].index = _operatorIndexOf(operatorId);
    }

    /**
     * @dev Updates operators's balance.
     */
    function _updateOperatorBalance(uint32 operatorId) private {
        OperatorData storage operatorData = _operatorDatas[operatorId];
        operatorData.earnings = _operatorEarningsOf(operatorId);
        operatorData.blockNumber = block.number;
    }

    function _liquidateUnsafe(address ownerAddress) private returns (uint256) {
        _disableOwnerValidatorsUnsafe(ownerAddress);

        uint256 balanceToTransfer = _totalBalanceOf(ownerAddress);

        _owners[ownerAddress].used += balanceToTransfer;

        emit AccountLiquidated(ownerAddress);

        return balanceToTransfer;
    }

    function _updateNetworkEarnings() private {
        _networkEarnings = _getTotalNetworkEarnings();
        _networkEarningsBlockNumber = block.number;
    }

    function _updateNetworkFeeIndex() private {
        _networkFeeIndex = _currentNetworkFeeIndex();
        _networkFeeIndexBlockNumber = block.number;
    }

    function _registerValidatorUnsafe(
        address ownerAddress,
        bytes calldata publicKey,
        uint32[] calldata operatorIds,
        bytes[] calldata sharesPublicKeys,
        bytes[] calldata encryptedKeys,
        uint256 tokenAmount) private {

        _ssvRegistryContract.registerValidator(
            ownerAddress,
            publicKey,
            operatorIds,
            sharesPublicKeys,
            encryptedKeys
        );

        OwnerData storage owner = _owners[ownerAddress];

        if (!owner.validatorsDisabled) {
            ++owner.activeValidatorCount;
        }

        for (uint256 index = 0; index < operatorIds.length; ++index) {
            uint32 operatorId = operatorIds[index];
            _updateOperatorBalance(operatorId);

            if (!owner.validatorsDisabled) {
                ++_operatorDatas[operatorId].activeValidatorCount;
            }

            _useOperatorByOwner(ownerAddress, operatorId);
        }

        if (tokenAmount > 0) {
            _deposit(msg.sender, tokenAmount);
        }

        require(!_liquidatable(ownerAddress), "not enough balance");

        emit ValidatorAdded(ownerAddress, publicKey, operatorIds, sharesPublicKeys, encryptedKeys);
    }

    function _removeValidatorUnsafe(address ownerAddress, bytes memory publicKey) private {
        _unregisterValidator(ownerAddress, publicKey);
        _ssvRegistryContract.removeValidator(publicKey);

        if (!_owners[ownerAddress].validatorsDisabled) {
            --_owners[ownerAddress].activeValidatorCount;
        }

        emit ValidatorRemoved(ownerAddress, publicKey);
    }

    function _unregisterValidator(address ownerAddress, bytes memory publicKey) private {
        // calculate balances for current operators in use and update their balances
        uint32[] memory currentOperatorIds = _ssvRegistryContract.getOperatorsByValidator(publicKey);
        for (uint256 index = 0; index < currentOperatorIds.length; ++index) {
            uint32 operatorId = currentOperatorIds[index];
            _updateOperatorBalance(operatorId);

            if (!_owners[ownerAddress].validatorsDisabled) {
                --_operatorDatas[operatorId].activeValidatorCount;
            }

            _stopUsingOperatorByOwner(ownerAddress, operatorId);
        }
    }

    function _useOperatorByOwner(address ownerAddress, uint32 operatorId) private {
        _updateUsingOperatorByOwner(ownerAddress, operatorId, true);
    }

    function _stopUsingOperatorByOwner(address ownerAddress, uint32 operatorId) private {
        _updateUsingOperatorByOwner(ownerAddress, operatorId, false);
    }

    function _updateOperatorFeeUnsafe(uint32 operatorId, uint256 fee) private {
        OperatorData storage operatorData = _operatorDatas[operatorId];
        _updateOperatorIndex(operatorId);
        operatorData.indexBlockNumber = block.number;
        _updateOperatorBalance(operatorId);
        _ssvRegistryContract.updateOperatorFee(operatorId, fee);
    }

    /**
     * @dev Updates the relation between operator and owner
     * @param ownerAddress Owner address.
     * @param increase Change value for validators amount.
     */
    function _updateUsingOperatorByOwner(address ownerAddress, uint32 operatorId, bool increase) private {
        OperatorInUse storage operatorInUseData = _operatorsInUseByAddress[ownerAddress][operatorId];

        if (operatorInUseData.exists) {
            _updateOperatorUsageByOwner(operatorInUseData, ownerAddress, operatorId);

            if (increase) {
                ++operatorInUseData.validatorCount;
            } else {
                if (--operatorInUseData.validatorCount == 0) {
                    _owners[ownerAddress].used += operatorInUseData.used;

                    // remove from mapping and list;

                    _operatorsInUseList[ownerAddress][operatorInUseData.indexInArray] = _operatorsInUseList[ownerAddress][_operatorsInUseList[ownerAddress].length - 1];
                    _operatorsInUseByAddress[ownerAddress][_operatorsInUseList[ownerAddress][operatorInUseData.indexInArray]].indexInArray = operatorInUseData.indexInArray;
                    _operatorsInUseList[ownerAddress].pop();

                    delete _operatorsInUseByAddress[ownerAddress][operatorId];
                }
            }
        } else {
            require(_operatorsInUseList[ownerAddress].length < MANAGING_OPERATORS_PER_ACCOUNT_LIMIT, "exceed managing operators per account limit");

            _operatorsInUseByAddress[ownerAddress][operatorId] = OperatorInUse({ index: _operatorIndexOf(operatorId), validatorCount: 1, used: 0, exists: true, indexInArray: uint32(_operatorsInUseList[ownerAddress].length) });
            _operatorsInUseList[ownerAddress].push(operatorId);
        }
    }

    function _disableOwnerValidatorsUnsafe(address ownerAddress) private {
        _updateNetworkEarnings();
        _updateAddressNetworkFee(ownerAddress);

        for (uint256 index = 0; index < _operatorsInUseList[ownerAddress].length; ++index) {
            uint32 operatorId = _operatorsInUseList[ownerAddress][index];
            _updateOperatorBalance(operatorId);
            OperatorInUse storage operatorInUseData = _operatorsInUseByAddress[ownerAddress][operatorId];
            _updateOperatorUsageByOwner(operatorInUseData, ownerAddress, operatorId);
            _operatorDatas[operatorId].activeValidatorCount -= operatorInUseData.validatorCount;
        }

        _ssvRegistryContract.disableOwnerValidators(ownerAddress);

        _owners[ownerAddress].validatorsDisabled = true;
    }

    function _enableOwnerValidatorsUnsafe(address ownerAddress) private {
        _updateNetworkEarnings();
        _updateAddressNetworkFee(ownerAddress);

        for (uint256 index = 0; index < _operatorsInUseList[ownerAddress].length; ++index) {
            uint32 operatorId = _operatorsInUseList[ownerAddress][index];
            _updateOperatorBalance(operatorId);
            OperatorInUse storage operatorInUseData = _operatorsInUseByAddress[ownerAddress][operatorId];
            _updateOperatorUsageByOwner(operatorInUseData, ownerAddress, operatorId);
            _operatorDatas[operatorId].activeValidatorCount += operatorInUseData.validatorCount;
        }

        _ssvRegistryContract.enableOwnerValidators(ownerAddress);

        _owners[ownerAddress].validatorsDisabled = false;
    }

    function _updateOperatorUsageByOwner(OperatorInUse storage operatorInUseData, address ownerAddress, uint32 operatorId) private {
        operatorInUseData.used = _operatorInUseUsageOf(operatorInUseData, ownerAddress, operatorId);
        operatorInUseData.index = _operatorIndexOf(operatorId);
    }

    function _updateLiquidationThresholdPeriod(uint256 newMinimumBlocksBeforeLiquidation) private {
        _minimumBlocksBeforeLiquidation = newMinimumBlocksBeforeLiquidation;

        emit LiquidationThresholdPeriodUpdated(_minimumBlocksBeforeLiquidation);
    }

    function _updateOperatorFeeIncreaseLimit(uint256 newOperatorMaxFeeIncrease) private {
        _operatorMaxFeeIncrease = newOperatorMaxFeeIncrease;

        emit OperatorFeeIncreaseLimitUpdated(_operatorMaxFeeIncrease);

    }

    function _updateDeclareOperatorFeePeriod(uint256 newDeclareOperatorFeePeriod) private {
        _declareOperatorFeePeriod = newDeclareOperatorFeePeriod;

        emit DeclareOperatorFeePeriodUpdated(newDeclareOperatorFeePeriod);
    }

    function _updateExecuteOperatorFeePeriod(uint256 newExecuteOperatorFeePeriod) private {
        _executeOperatorFeePeriod = newExecuteOperatorFeePeriod;

        emit ExecuteOperatorFeePeriodUpdated(newExecuteOperatorFeePeriod);
    }

    function _expensesOf(address ownerAddress) private view returns(uint256) {
        uint256 usage =  _owners[ownerAddress].used + _addressNetworkFee(ownerAddress);
        for (uint256 index = 0; index < _operatorsInUseList[ownerAddress].length; ++index) {
            OperatorInUse storage operatorInUseData = _operatorsInUseByAddress[ownerAddress][_operatorsInUseList[ownerAddress][index]];
            usage += _operatorInUseUsageOf(operatorInUseData, ownerAddress, _operatorsInUseList[ownerAddress][index]);
        }

        return usage;
    }

    function _totalEarningsOf(address ownerAddress) private view returns (uint256 earnings) {
        uint32[] memory operatorsByOwner = _ssvRegistryContract.getOperatorsByOwnerAddress(ownerAddress);
        for (uint256 index = 0; index < operatorsByOwner.length; ++index) {
            earnings += _operatorEarningsOf(operatorsByOwner[index]);
        }
    }

    function _totalBalanceOf(address ownerAddress) private view returns (uint256) {
        uint256 balance = _owners[ownerAddress].deposited + _totalEarningsOf(ownerAddress);

        uint256 usage = _owners[ownerAddress].withdrawn + _expensesOf(ownerAddress);

        require(balance >= usage, "negative balance");

        return balance - usage;
    }

    function _operatorEarnRate(uint32 operatorId) private view returns (uint256) {
        return _ssvRegistryContract.getOperatorFee(operatorId) * _operatorDatas[operatorId].activeValidatorCount;
    }

    /**
     * @dev See {ISSVNetwork-operatorEarningsOf}.
     */
    function _operatorEarningsOf(uint32 operatorId) private view returns (uint256) {
        return _operatorDatas[operatorId].earnings +
               (block.number - _operatorDatas[operatorId].blockNumber) *
               _operatorEarnRate(operatorId);
    }

    function _addressNetworkFee(address ownerAddress) private view returns (uint256) {
        return _owners[ownerAddress].networkFee +
              (_currentNetworkFeeIndex() - _owners[ownerAddress].networkFeeIndex) *
              _owners[ownerAddress].activeValidatorCount;
    }

    function _burnRate(address ownerAddress) private view returns (uint256 ownerBurnRate) {
        if (_owners[ownerAddress].validatorsDisabled) {
            return 0;
        }

        for (uint256 index = 0; index < _operatorsInUseList[ownerAddress].length; ++index) {
            ownerBurnRate += _operatorInUseBurnRateWithNetworkFeeUnsafe(ownerAddress, _operatorsInUseList[ownerAddress][index]);
        }

        uint32[] memory operatorsByOwner = _ssvRegistryContract.getOperatorsByOwnerAddress(ownerAddress);

        for (uint256 index = 0; index < operatorsByOwner.length; ++index) {
            if (ownerBurnRate <= _operatorEarnRate(operatorsByOwner[index])) {
                return 0;
            } else {
                ownerBurnRate -= _operatorEarnRate(operatorsByOwner[index]);
            }
        }
    }

    function _overdue(address ownerAddress) private view returns (bool) {
        return _totalBalanceOf(ownerAddress) < _minimumBlocksBeforeLiquidation * _burnRate(ownerAddress);
    }

    function _liquidatable(address ownerAddress) private view returns (bool) {
        return !_owners[ownerAddress].validatorsDisabled && _overdue(ownerAddress);
    }

    function _canLiquidate(address ownerAddress) private view returns (bool) {
        return !_owners[ownerAddress].validatorsDisabled && (msg.sender == ownerAddress || _overdue(ownerAddress));
    }

    function _getTotalNetworkEarnings() private view returns (uint256) {
        return _networkEarnings + (block.number - _networkEarningsBlockNumber) * _networkFee * _ssvRegistryContract.activeValidatorCount();
    }

    function _getNetworkTreasury() private view returns (uint256) {
        return _getTotalNetworkEarnings() - _withdrawnFromTreasury;
    }

    /**
     * @dev Get operator index by address.
     */
    function _operatorIndexOf(uint32 operatorId) private view returns (uint256) {
        return _operatorDatas[operatorId].index +
               _ssvRegistryContract.getOperatorFee(operatorId) *
               (block.number - _operatorDatas[operatorId].indexBlockNumber);
    }

    function _operatorInUseUsageOf(OperatorInUse storage operatorInUseData, address ownerAddress, uint32 operatorId) private view returns (uint256) {
        return operatorInUseData.used + (
                _owners[ownerAddress].validatorsDisabled ? 0 :
                (_operatorIndexOf(operatorId) - operatorInUseData.index) * operatorInUseData.validatorCount
               );
    }

    function _operatorInUseBurnRateWithNetworkFeeUnsafe(address ownerAddress, uint32 operatorId) private view returns (uint256) {
        OperatorInUse storage operatorInUseData = _operatorsInUseByAddress[ownerAddress][operatorId];
        return (_ssvRegistryContract.getOperatorFee(operatorId) + _networkFee) * operatorInUseData.validatorCount;
    }

    /**
     * @dev Returns the current network fee index
     */
    function _currentNetworkFeeIndex() private view returns(uint256) {
        return _networkFeeIndex + (block.number - _networkFeeIndexBlockNumber) * _networkFee;
    }

    function version() external pure override returns (uint32) {
        return 1;
    }

    uint256[50] ______gap;
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// File: contracts/utils/VersionedContract.sol
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.13;

interface VersionedContract {
  function version() external pure returns (uint32);
}

// File: contracts/ISSVNetwork.sol
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import "./ISSVRegistry.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISSVNetwork {
    /**
     * @dev Emitted when the account has been enabled.
     * @param ownerAddress Operator's owner.
     */
    event AccountEnabled(address indexed ownerAddress);

    /**
     * @dev Emitted when the account has been liquidated.
     * @param ownerAddress Operator's owner.
     */
    event AccountLiquidated(address indexed ownerAddress);

    /**
     * @dev Emitted when the operator has been added.
     * @param id operator's ID.
     * @param name Operator's display name.
     * @param ownerAddress Operator's ethereum address that can collect fees.
     * @param publicKey Operator's public key. Will be used to encrypt secret shares of validators keys.
     * @param fee Operator's initial fee.
     */
    event OperatorAdded(
        uint32 indexed id,
        string name,
        address indexed ownerAddress,
        bytes publicKey,
        uint256 fee
    );

    /**
     * @dev Emitted when the operator has been removed.
     * @param operatorId operator's ID.
     * @param ownerAddress Operator's owner.
     */
    event OperatorRemoved(uint32 operatorId, address indexed ownerAddress);

    event OperatorFeeSet(
        address indexed ownerAddress,
        uint32 operatorId,
        uint256 blockNumber,
        uint256 fee
    );

    event OperatorFeeSetCanceled(address indexed ownerAddress, uint32 operatorId);

    /**
     * @dev Emitted when an operator's fee is updated.
     * @param ownerAddress Operator's owner.
     * @param blockNumber from which block number.
     * @param fee updated fee value.
     */
    event OperatorFeeApproved(
        address indexed ownerAddress,
        uint32 operatorId,
        uint256 blockNumber,
        uint256 fee
    );

    /**
     * @dev Emitted when an operator's score is updated.
     * @param operatorId operator's ID.
     * @param ownerAddress Operator's owner.
     * @param blockNumber from which block number.
     * @param score updated score value.
     */
    event OperatorScoreUpdated(
        uint32 operatorId,
        address indexed ownerAddress,
        uint256 blockNumber,
        uint256 score
    );

    /**
     * @dev Emitted when the validator has been added.
     * @param ownerAddress The user's ethereum address that is the owner of the validator.
     * @param publicKey The public key of a validator.
     * @param operatorIds The operators public keys list for this validator.
     * @param sharesPublicKeys The shared publick keys list for this validator.
     * @param encryptedKeys The encrypted keys list for this validator.
     */
    event ValidatorAdded(
        address indexed ownerAddress,
        bytes publicKey,
        uint32[] operatorIds,
        bytes[] sharesPublicKeys,
        bytes[] encryptedKeys
    );

    /**
     * @dev Emitted when the validator is removed.
     * @param ownerAddress Validator's owner.
     * @param publicKey The public key of a validator.
     */
    event ValidatorRemoved(address indexed ownerAddress, bytes publicKey);

    /**
     * @dev Emitted when an owner deposits funds.
     * @param value Amount of tokens.
     * @param ownerAddress Owner's address.
     * @param senderAddress Sender's address.
     */
    event FundsDeposited(uint256 value, address indexed ownerAddress, address indexed senderAddress);

    /**
     * @dev Emitted when an owner withdraws funds.
     * @param value Amount of tokens.
     * @param ownerAddress Owner's address.
     */
    event FundsWithdrawn(uint256 value, address indexed ownerAddress);

    /**
     * @dev Emitted when the network fee is updated.
     * @param oldFee The old fee
     * @param newFee The new fee
     */
    event NetworkFeeUpdated(uint256 oldFee, uint256 newFee);

    /**
     * @dev Emitted when transfer fees are withdrawn.
     * @param value The amount of tokens withdrawn.
     * @param recipient The recipient address.
     */
    event NetworkFeesWithdrawn(uint256 value, address recipient);

    event DeclareOperatorFeePeriodUpdated(uint256 value);

    event ExecuteOperatorFeePeriodUpdated(uint256 value);

    event LiquidationThresholdPeriodUpdated(uint256 value);

    event OperatorFeeIncreaseLimitUpdated(uint256 value);

    event ValidatorsPerOperatorLimitUpdated(uint256 value);

    event RegisteredOperatorsPerAccountLimitUpdated(uint256 value);

    event MinimumBlocksBeforeLiquidationUpdated(uint256 value);

    event OperatorMaxFeeIncreaseUpdated(uint256 value);

    /**
     * @dev Initializes the contract.
     * @param registryAddress_ The registry address.
     * @param token_ The network token.
     * @param minimumBlocksBeforeLiquidation_ The minimum blocks before liquidation.
     * @param declareOperatorFeePeriod_ The period an operator needs to wait before they can approve their fee.
     * @param executeOperatorFeePeriod_ The length of the period in which an operator can approve their fee.
     * @param validatorsPerOperatorLimit_ the limit for validators per operator.
     * @param registeredOperatorsPerAccountLimit_ the limit for registered operators per account address.
     */
    function initialize(
        ISSVRegistry registryAddress_,
        IERC20 token_,
        uint256 minimumBlocksBeforeLiquidation_,
        uint256 operatorMaxFeeIncrease_,
        uint256 declareOperatorFeePeriod_,
        uint256 executeOperatorFeePeriod_,
        uint16 validatorsPerOperatorLimit_,
        uint16 registeredOperatorsPerAccountLimit_
    ) external;

    /**
     * @dev Registers a new operator.
     * @param name Operator's display name.
     * @param publicKey Operator's public key. Used to encrypt secret shares of validators keys.
     */
    function registerOperator(
        string calldata name,
        bytes calldata publicKey,
        uint256 fee
    ) external returns (uint32);

    /**
     * @dev Removes an operator.
     * @param operatorId Operator's id.
     */
    function removeOperator(uint32 operatorId) external;

    /**
     * @dev Set operator's fee change request by public key.
     * @param operatorId Operator's id.
     * @param fee The operator's updated fee.
     */
    function declareOperatorFee(uint32 operatorId, uint256 fee) external;

    function cancelDeclaredOperatorFee(uint32 operatorId) external;

    function executeOperatorFee(uint32 operatorId) external;

    /**
     * @dev Updates operator's score by public key.
     * @param operatorId Operator's id.
     * @param score The operators's updated score.
     */
    function updateOperatorScore(uint32 operatorId, uint16 score) external;

    /**
     * @dev Registers a new validator.
     * @param publicKey Validator public key.
     * @param operatorIds Operator public keys.
     * @param sharesPublicKeys Shares public keys.
     * @param encryptedKeys Encrypted private keys.
     */
    function registerValidator(
        bytes calldata publicKey,
        uint32[] calldata operatorIds,
        bytes[] calldata sharesPublicKeys,
        bytes[] calldata encryptedKeys,
        uint256 tokenAmount
    ) external;

    /**
     * @dev Updates a validator.
     * @param publicKey Validator public key.
     * @param operatorIds Operator public keys.
     * @param sharesPublicKeys Shares public keys.
     * @param encryptedKeys Encrypted private keys.
     */
    function updateValidator(
        bytes calldata publicKey,
        uint32[] calldata operatorIds,
        bytes[] calldata sharesPublicKeys,
        bytes[] calldata encryptedKeys,
        uint256 tokenAmount
    ) external;

    /**
     * @dev Removes a validator.
     * @param publicKey Validator's public key.
     */
    function removeValidator(bytes calldata publicKey) external;

    /**
     * @dev Deposits tokens for the sender.
     * @param ownerAddress Owners' addresses.
     * @param tokenAmount Tokens amount.
     */
    function deposit(address ownerAddress, uint256 tokenAmount) external;

    /**
     * @dev Withdraw tokens for the sender.
     * @param tokenAmount Tokens amount.
     */
    function withdraw(uint256 tokenAmount) external;

    /**
     * @dev Withdraw total balance to the sender, deactivating their validators if necessary.
     */
    function withdrawAll() external;

    /**
     * @dev Liquidates multiple owners.
     * @param ownerAddresses Owners' addresses.
     */
    function liquidate(address[] calldata ownerAddresses) external;

    /**
     * @dev Enables msg.sender account.
     * @param tokenAmount Tokens amount.
     */
    function reactivateAccount(uint256 tokenAmount) external;

    /**
     * @dev Updates the number of blocks left for an owner before they can be liquidated.
     * @param newMinimumBlocksBeforeLiquidation The new value.
     */
    function updateLiquidationThresholdPeriod(uint256 newMinimumBlocksBeforeLiquidation) external;

    /**
     * @dev Updates the maximum fee increase in pecentage.
     * @param newOperatorMaxFeeIncrease The new value.
     */
    function updateOperatorFeeIncreaseLimit(uint256 newOperatorMaxFeeIncrease) external;

    function updateDeclareOperatorFeePeriod(uint256 newDeclareOperatorFeePeriod) external;

    function updateExecuteOperatorFeePeriod(uint256 newExecuteOperatorFeePeriod) external;

    /**
     * @dev Updates the network fee.
     * @param fee the new fee
     */
    function updateNetworkFee(uint256 fee) external;

    /**
     * @dev Withdraws network fees.
     * @param amount Amount to withdraw
     */
    function withdrawNetworkEarnings(uint256 amount) external;

    /**
     * @dev Gets total balance for an owner.
     * @param ownerAddress Owner's address.
     */
    function getAddressBalance(address ownerAddress) external view returns (uint256);

    function isLiquidated(address ownerAddress) external view returns (bool);

    /**
     * @dev Gets an operator by operator id.
     * @param operatorId Operator's id.
     */
    function getOperatorById(uint32 operatorId)
        external view
        returns (
            string memory,
            address,
            bytes memory,
            uint256,
            uint256,
            uint256,
            bool
        );


    /**
     * @dev Gets an operator by public key.
     * @param publicKey Operator public key.
     */
    function getOperatorByPublicKey(bytes memory publicKey)
        external view
        returns (
            string memory,
            address,
            bytes memory,
            uint256,
            uint256,
            uint256,
            bool
        );

    /**
     * @dev Gets a validator public keys by owner's address.
     * @param ownerAddress Owner's Address.
     */
    function getValidatorsByOwnerAddress(address ownerAddress)
        external view
        returns (bytes[] memory);

    /**
     * @dev Gets operators list which are in use by validator.
     * @param validatorPublicKey Validator's public key.
     */
    function getOperatorsByValidator(bytes calldata validatorPublicKey)
        external view
        returns (uint32[] memory);

    function getOperatorDeclaredFee(uint32 operatorId) external view returns (uint256, uint256, uint256);

    /**
     * @dev Gets operator current fee.
     * @param operatorId Operator's id.
     */
    function getOperatorFee(uint32 operatorId) external view returns (uint256);

    /**
     * @dev Gets the network fee for an address.
     * @param ownerAddress Owner's address.
     */
    function addressNetworkFee(address ownerAddress) external view returns (uint256);

    /**
     * @dev Returns the burn rate of an owner, returns 0 if negative.
     * @param ownerAddress Owner's address.
     */
    function getAddressBurnRate(address ownerAddress) external view returns (uint256);

    /**
     * @dev Check if an owner is liquidatable.
     * @param ownerAddress Owner's address.
     */
    function isLiquidatable(address ownerAddress) external view returns (bool);

    /**
     * @dev Returns the network fee.
     */
    function getNetworkFee() external view returns (uint256);

    /**
     * @dev Gets the available network earnings
     */
    function getNetworkEarnings() external view returns (uint256);

    /**
     * @dev Returns the number of blocks left for an owner before they can be liquidated.
     */
    function getLiquidationThresholdPeriod() external view returns (uint256);

    /**
     * @dev Returns the maximum fee increase in pecentage
     */
     function getOperatorFeeIncreaseLimit() external view returns (uint256);

     function getExecuteOperatorFeePeriod() external view returns (uint256);

     function getDeclaredOperatorFeePeriod() external view returns (uint256);
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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
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

// File: contracts/ISSVRegistry.sol
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

interface ISSVRegistry {
    struct Oess {
        uint32 operatorId;
        bytes sharedPublicKey;
        bytes encryptedKey;
    }

    /**
     * @dev Emitted when an operator's fee is updated.
     * @param ownerAddress Operator's owner.
     * @param publicKey Operator's public key.
     * @param blockNumber from which block number.
     * @param fee updated fee value.
     */
    event OperatorFeeUpdated(
        uint32 indexed operatorId,
        address indexed ownerAddress,
        bytes publicKey,
        uint256 blockNumber,
        uint256 fee
    );

    event OwnerValidatorsDisabled(address ownerAddress);

    event OwnerValidatorsEnabled(address indexed ownerAddress);

    event ValidatorsPerOperatorLimitUpdated(uint16 validatorsPerOperatorLimit);

    event RegisteredOperatorsPerAccountLimitUpdated(uint16 registeredOperatorsPerAccountLimit);

    /**
     * @dev Initializes the contract
     * @param validatorsPerOperatorLimit_ the limit for validators per operator.
     * @param registeredOperatorsPerAccountLimit_ the limit for registered operators per account address.
     */
    function initialize(uint16 validatorsPerOperatorLimit_, uint16 registeredOperatorsPerAccountLimit_) external;

    /**
     * @dev Registers a new operator.
     * @param name Operator's display name.
     * @param ownerAddress Operator's ethereum address that can collect fees.
     * @param publicKey Operator's public key. Will be used to encrypt secret shares of validators keys.
     * @param fee The fee which the operator charges for each block.
     */
    function registerOperator(string calldata name, address ownerAddress, bytes calldata publicKey, uint256 fee) external returns (uint32);

    /**
     * @dev removes an operator.
     * @param operatorId Operator id.
     */
    function removeOperator(uint32 operatorId) external;

    /**
     * @dev Updates an operator fee.
     * @param operatorId Operator id.
     * @param fee New operator fee.
     */
    function updateOperatorFee(
        uint32 operatorId,
        uint256 fee
    ) external;

    /**
     * @dev Updates an operator fee.
     * @param operatorId Operator id.
     * @param score New score.
     */
    function updateOperatorScore(
        uint32 operatorId,
        uint16 score
    ) external;

    /**
     * @dev Registers a new validator.
     * @param ownerAddress The user's ethereum address that is the owner of the validator.
     * @param publicKey Validator public key.
     * @param operatorIds Operator ids.
     * @param sharesPublicKeys Shares public keys.
     * @param encryptedKeys Encrypted private keys.
     */
    function registerValidator(
        address ownerAddress,
        bytes calldata publicKey,
        uint32[] calldata operatorIds,
        bytes[] calldata sharesPublicKeys,
        bytes[] calldata encryptedKeys
    ) external;

    /**
     * @dev removes a validator.
     * @param publicKey Validator's public key.
     */
    function removeValidator(bytes calldata publicKey) external;

    function enableOwnerValidators(address ownerAddress) external;

    function disableOwnerValidators(address ownerAddress) external;

    function isLiquidated(address ownerAddress) external view returns (bool);

    /**
     * @dev Gets an operator by operator id.
     * @param operatorId Operator id.
     */
    function getOperatorById(uint32 operatorId)
        external view
        returns (
            string memory,
            address,
            bytes memory,
            uint256,
            uint256,
            uint256,
            bool
        );

    /**
     * @dev Gets an operator by public key.
     * @param publicKey Operator public key.
     */
    function getOperatorByPublicKey(bytes memory publicKey)
        external view
        returns (
            string memory,
            address,
            bytes memory,
            uint256,
            uint256,
            uint256,
            bool
        );

    /**
     * @dev Returns operators for owner.
     * @param ownerAddress Owner's address.
     */
    function getOperatorsByOwnerAddress(address ownerAddress)
        external view
        returns (uint32[] memory);

    /**
     * @dev Gets operators list which are in use by validator.
     * @param validatorPublicKey Validator's public key.
     */
    function getOperatorsByValidator(bytes calldata validatorPublicKey)
        external view
        returns (uint32[] memory);

    /**
     * @dev Gets operator's owner.
     * @param operatorId Operator id.
     */
    function getOperatorOwner(uint32 operatorId) external view returns (address);

    /**
     * @dev Gets operator current fee.
     * @param operatorId Operator id.
     */
    function getOperatorFee(uint32 operatorId)
        external view
        returns (uint256);

    /**
     * @dev Gets active validator count.
     */
    function activeValidatorCount() external view returns (uint32);

    /**
     * @dev Gets an validator by public key.
     * @param publicKey Validator's public key.
     */
    function validators(bytes calldata publicKey)
        external view
        returns (
            address,
            bytes memory,
            bool
        );

    /**
     * @dev Gets a validator public keys by owner's address.
     * @param ownerAddress Owner's Address.
     */
    function getValidatorsByAddress(address ownerAddress)
        external view
        returns (bytes[] memory);

    /**
     * @dev Get validator's owner.
     * @param publicKey Validator's public key.
     */
    function getValidatorOwner(bytes calldata publicKey) external view returns (address);

    /**
     * @dev Update Max validators amount limit per Operator.
     * @param _validatorsPerOperatorLimit Amount
     */
    function updateValidatorsPerOperatorLimit(uint16 _validatorsPerOperatorLimit) external;

    /**
     * @dev Update Max registered operators per account per Operator.
     * @param _registeredOperatorsPerAccountLimit Amount
     */
    function updateRegisteredOperatorsPerAccountLimit(uint16 _registeredOperatorsPerAccountLimit) external;

    /**
     * @dev Get validators per operator limit.
     */
    function getValidatorsPerOperatorLimit() external view returns (uint16);

    /**
     * @dev Get validators amount per operator.
     * @param operatorId Operator public key
     */
    function validatorsPerOperatorCount(uint32 operatorId) external view returns (uint16);

    /**
     * @dev Get registered operators per account limit.
     */
    function getRegisteredOperatorsPerAccountLimit() external view returns (uint16);
}