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

import "./interfaces/IAllowlist.1.sol";
import "./interfaces/IOperatorRegistry.1.sol";
import "./interfaces/IRiver.1.sol";
import "./interfaces/IELFeeRecipient.1.sol";

import "./components/ConsensusLayerDepositManager.1.sol";
import "./components/UserDepositManager.1.sol";
import "./components/SharesManager.1.sol";
import "./components/OracleManager.1.sol";
import "./Initializable.sol";
import "./Administrable.sol";

import "./state/river/AllowlistAddress.sol";
import "./state/river/OperatorsRegistryAddress.sol";
import "./state/river/CollectorAddress.sol";
import "./state/river/GlobalFee.sol";
import "./state/river/ELFeeRecipientAddress.sol";

/// @title River (v1)
/// @author Kiln
/// @notice This contract merges all the manager contracts and implements all the virtual methods stitching all components together
/// @notice
/// @notice    +---------------------------------------------------------------------+
/// @notice    |                                                                     |
/// @notice    |                           Consensus Layer                           |
/// @notice    |                                                                     |
/// @notice    | +-------------------+  +-------------------+  +-------------------+ |
/// @notice    | |                   |  |                   |  |                   | |
/// @notice    | |  EL Fee Recipient |  |      Oracle       |  |  Deposit Contract | |
/// @notice    | |                   |  |                   |  |                   | |
/// @notice    | +---------|---------+  +---------|---------+  +---------|---------+ |
/// @notice    +---------------------------------------------------------------------+
/// @notice                |         7            |            5         |
/// @notice                +-----------------|    |    |-----------------+
/// @notice                                  |    |6   |
/// @notice                                  |    |    |
/// @notice        +---------+          +----|----|----|----+            +---------+
/// @notice        |         |          |                   |     2      |         |
/// @notice        |Operator |          |       River       --------------  User   |
/// @notice        |         |          |                   |            |         |
/// @notice        +----|----+          +----|---------|----+            +---------+
/// @notice             |                    |         |
/// @notice             |             4      |         |       3
/// @notice             |1     +-------------|         |--------------+
/// @notice             |      |                                      |
/// @notice             |      |                                      |
/// @notice      +------|------|------------+           +-------------|------------+
/// @notice      |                          |           |                          |
/// @notice      |    Operators Registry    |           |         Allowlist        |
/// @notice      |                          |           |                          |
/// @notice      +--------------------------+           +--------------------------+
/// @notice
/// @notice      1. Operators are adding BLS Public Keys of validators running in their
/// @notice         infrastructure.
/// @notice      2. User deposit ETH to the system and get shares minted in exchange
/// @notice      3. Upon deposit, the system verifies if the User is allowed to deposit
/// @notice         by querying the Allowlist
/// @notice      4. When the system has enough funds to deposit validators, keys are pulled
/// @notice         from the Operators Registry
/// @notice      5. The deposit data is computed and the validators are funded via the official
/// @notice         deposit contract
/// @notice      6. Oracles report the total balance of the running validators and the total count
/// @notice         of running validators
/// @notice      7. The running validators propose blocks that reward the EL Fee Recipient. The funds
/// @notice         are pulled back in the system.
/// @notice
contract RiverV1 is
    ConsensusLayerDepositManagerV1,
    UserDepositManagerV1,
    SharesManagerV1,
    OracleManagerV1,
    Initializable,
    Administrable,
    IRiverV1
{
    /// @notice The mask for the deposit right
    uint256 internal constant DEPOSIT_MASK = 0x1;

    /// @inheritdoc IRiverV1
    function initRiverV1(
        address _depositContractAddress,
        address _elFeeRecipientAddress,
        bytes32 _withdrawalCredentials,
        address _oracleAddress,
        address _systemAdministratorAddress,
        address _allowlistAddress,
        address _operatorRegistryAddress,
        address _collectorAddress,
        uint256 _globalFee
    ) external init(0) {
        _setAdmin(_systemAdministratorAddress);

        CollectorAddress.set(_collectorAddress);
        emit SetCollector(_collectorAddress);

        GlobalFee.set(_globalFee);
        emit SetGlobalFee(_globalFee);

        ELFeeRecipientAddress.set(_elFeeRecipientAddress);
        emit SetELFeeRecipient(_elFeeRecipientAddress);

        AllowlistAddress.set(_allowlistAddress);
        emit SetAllowlist(_allowlistAddress);

        OperatorsRegistryAddress.set(_operatorRegistryAddress);
        emit SetOperatorsRegistry(_operatorRegistryAddress);

        ConsensusLayerDepositManagerV1.initConsensusLayerDepositManagerV1(
            _depositContractAddress, _withdrawalCredentials
        );

        OracleManagerV1.initOracleManagerV1(_oracleAddress);
    }

    /// @inheritdoc IRiverV1
    function getGlobalFee() external view returns (uint256) {
        return GlobalFee.get();
    }

    /// @inheritdoc IRiverV1
    function getAllowlist() external view returns (address) {
        return AllowlistAddress.get();
    }

    /// @inheritdoc IRiverV1
    function getCollector() external view returns (address) {
        return CollectorAddress.get();
    }

    /// @inheritdoc IRiverV1
    function getELFeeRecipient() external view returns (address) {
        return ELFeeRecipientAddress.get();
    }

    /// @inheritdoc IRiverV1
    function setGlobalFee(uint256 newFee) external onlyAdmin {
        GlobalFee.set(newFee);
        emit SetGlobalFee(newFee);
    }

    /// @inheritdoc IRiverV1
    function setAllowlist(address _newAllowlist) external onlyAdmin {
        AllowlistAddress.set(_newAllowlist);
        emit SetAllowlist(_newAllowlist);
    }

    /// @inheritdoc IRiverV1
    function setCollector(address _newCollector) external onlyAdmin {
        CollectorAddress.set(_newCollector);
        emit SetCollector(_newCollector);
    }

    /// @inheritdoc IRiverV1
    function setELFeeRecipient(address _newELFeeRecipient) external onlyAdmin {
        ELFeeRecipientAddress.set(_newELFeeRecipient);
        emit SetELFeeRecipient(_newELFeeRecipient);
    }

    /// @inheritdoc IRiverV1
    function getOperatorsRegistry() external view returns (address) {
        return OperatorsRegistryAddress.get();
    }

    /// @inheritdoc IRiverV1
    function sendELFees() external payable {
        if (msg.sender != ELFeeRecipientAddress.get()) {
            revert LibErrors.Unauthorized(msg.sender);
        }
    }

    /// @notice Overriden handler to pass the system admin inside components
    /// @return The address of the admin
    function _getRiverAdmin()
        internal
        view
        override (OracleManagerV1, ConsensusLayerDepositManagerV1)
        returns (address)
    {
        return Administrable._getAdmin();
    }

    /// @notice Overriden handler called whenever a token transfer is triggered
    /// @param _from Token sender
    /// @param _to Token receiver
    function _onTransfer(address _from, address _to) internal view override {
        IAllowlistV1 allowlist = IAllowlistV1(AllowlistAddress.get());
        if (allowlist.isDenied(_from)) {
            revert Denied(_from);
        }
        if (allowlist.isDenied(_to)) {
            revert Denied(_to);
        }
    }

    /// @notice Overriden handler called whenever a user deposits ETH to the system. Mints the adequate amount of shares.
    /// @param _depositor User address that made the deposit
    /// @param _amount Amount of ETH deposited
    function _onDeposit(address _depositor, address _recipient, uint256 _amount) internal override {
        uint256 mintedShares = SharesManagerV1._mintShares(_depositor, _amount);
        IAllowlistV1 allowlist = IAllowlistV1(AllowlistAddress.get());
        if (_depositor == _recipient) {
            allowlist.onlyAllowed(_depositor, DEPOSIT_MASK); // this call reverts if unauthorized or denied
        } else {
            allowlist.onlyAllowed(_depositor, DEPOSIT_MASK); // this call reverts if unauthorized or denied
            if (allowlist.isDenied(_recipient)) {
                revert Denied(_recipient);
            }
            _transfer(_depositor, _recipient, mintedShares);
        }
    }

    /// @notice Overriden handler called whenever a deposit to the consensus layer is made. Should retrieve _requestedAmount or lower keys
    /// @param _requestedAmount Amount of keys required. Contract is expected to send _requestedAmount or lower.
    /// @return publicKeys Array of fundable public keys
    /// @return signatures Array of signatures linked to the public keys
    function _getNextValidators(uint256 _requestedAmount)
        internal
        override
        returns (bytes[] memory publicKeys, bytes[] memory signatures)
    {
        return IOperatorsRegistryV1(OperatorsRegistryAddress.get()).pickNextValidators(_requestedAmount);
    }

    /// @notice Overriden handler to pull funds from the execution layer fee recipient to River and return the delta in the balance
    /// @param _max The maximum amount to pull from the execution layer fee recipient
    /// @return The amount pulled from the execution layer fee recipient
    function _pullELFees(uint256 _max) internal override returns (uint256) {
        address elFeeRecipient = ELFeeRecipientAddress.get();
        if (elFeeRecipient == address(0)) {
            return 0;
        }
        uint256 initialBalance = address(this).balance;
        IELFeeRecipientV1(payable(elFeeRecipient)).pullELFees(_max);
        uint256 collectedELFees = address(this).balance - initialBalance;
        BalanceToDeposit.set(BalanceToDeposit.get() + collectedELFees);
        emit PulledELFees(collectedELFees);
        return collectedELFees;
    }

    /// @notice Overriden handler called whenever the balance of ETH handled by the system increases. Computes the fees paid to the collector
    /// @param _amount Additional ETH received
    function _onEarnings(uint256 _amount) internal override {
        uint256 oldTotalSupply = _totalSupply();
        if (oldTotalSupply == 0) {
            revert ZeroMintedShares();
        }
        uint256 newTotalBalance = _assetBalance();
        uint256 globalFee = GlobalFee.get();
        uint256 numerator = _amount * oldTotalSupply * globalFee;
        uint256 denominator = (newTotalBalance * LibBasisPoints.BASIS_POINTS_MAX) - (_amount * globalFee);
        uint256 sharesToMint = denominator == 0 ? 0 : (numerator / denominator);

        if (sharesToMint > 0) {
            address collector = CollectorAddress.get();
            _mintRawShares(collector, sharesToMint);
            uint256 newTotalSupply = _totalSupply();
            uint256 oldTotalBalance = newTotalBalance - _amount;
            emit RewardsEarned(collector, oldTotalBalance, oldTotalSupply, newTotalBalance, newTotalSupply);
        }
    }

    /// @notice Overriden handler called whenever the total balance of ETH is requested
    /// @return The current total asset balance managed by River
    function _assetBalance() internal view override returns (uint256) {
        uint256 clValidatorCount = CLValidatorCount.get();
        uint256 depositedValidatorCount = DepositedValidatorCount.get();
        if (clValidatorCount < depositedValidatorCount) {
            return CLValidatorTotalBalance.get() + BalanceToDeposit.get()
                + (depositedValidatorCount - clValidatorCount) * ConsensusLayerDepositManagerV1.DEPOSIT_SIZE;
        } else {
            return CLValidatorTotalBalance.get() + BalanceToDeposit.get();
        }
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../interfaces/components/IConsensusLayerDepositManager.1.sol";
import "../interfaces/IDepositContract.sol";

import "../libraries/LibBytes.sol";
import "../libraries/LibUint256.sol";

import "../state/river/DepositContractAddress.sol";
import "../state/river/WithdrawalCredentials.sol";
import "../state/river/DepositedValidatorCount.sol";
import "../state/river/BalanceToDeposit.sol";

/// @title Consensus Layer Deposit Manager (v1)
/// @author Kiln
/// @notice This contract handles the interactions with the official deposit contract, funding all validators
/// @notice Whenever a deposit to the consensus layer is requested, this contract computed the amount of keys
/// @notice that could be deposited depending on the amount available in the contract. It then tries to retrieve
/// @notice validator keys by calling its internal virtual method _getNextValidators. This method should be
/// @notice overridden by the implementing contract to provide [0; _keyCount] keys when invoked.
abstract contract ConsensusLayerDepositManagerV1 is IConsensusLayerDepositManagerV1 {
    /// @notice Size of a BLS Public key in bytes
    uint256 public constant PUBLIC_KEY_LENGTH = 48;
    /// @notice Size of a BLS Signature in bytes
    uint256 public constant SIGNATURE_LENGTH = 96;
    /// @notice Size of a deposit in ETH
    uint256 public constant DEPOSIT_SIZE = 32 ether;

    /// @notice Handler called to retrieve the internal River admin address
    /// @dev Must be overriden
    function _getRiverAdmin() internal view virtual returns (address);

    /// @notice Prevents unauthorized calls
    modifier onlyAdmin_CDMV1() {
        if (msg.sender != _getRiverAdmin()) {
            revert LibErrors.Unauthorized(msg.sender);
        }
        _;
    }

    /// @notice Internal helper to retrieve validator keys ready to be funded
    /// @dev Must be overridden
    /// @param _keyCount The amount of keys (or less) to return.
    function _getNextValidators(uint256 _keyCount)
        internal
        virtual
        returns (bytes[] memory publicKeys, bytes[] memory signatures);

    /// @notice Initializer to set the deposit contract address and the withdrawal credentials to use
    /// @param _depositContractAddress The address of the deposit contract
    /// @param _withdrawalCredentials The withdrawal credentials to apply to all deposits
    function initConsensusLayerDepositManagerV1(address _depositContractAddress, bytes32 _withdrawalCredentials)
        internal
    {
        DepositContractAddress.set(_depositContractAddress);
        emit SetDepositContractAddress(_depositContractAddress);

        WithdrawalCredentials.set(_withdrawalCredentials);
        emit SetWithdrawalCredentials(_withdrawalCredentials);
    }

    /// @inheritdoc IConsensusLayerDepositManagerV1
    function getBalanceToDeposit() external view returns (uint256) {
        return BalanceToDeposit.get();
    }

    /// @inheritdoc IConsensusLayerDepositManagerV1
    function getWithdrawalCredentials() external view returns (bytes32) {
        return WithdrawalCredentials.get();
    }

    /// @inheritdoc IConsensusLayerDepositManagerV1
    function getDepositedValidatorCount() external view returns (uint256) {
        return DepositedValidatorCount.get();
    }

    /// @inheritdoc IConsensusLayerDepositManagerV1
    function depositToConsensusLayer(uint256 _maxCount) external onlyAdmin_CDMV1 {
        uint256 balanceToDeposit = BalanceToDeposit.get();
        uint256 keyToDepositCount = LibUint256.min(balanceToDeposit / DEPOSIT_SIZE, _maxCount);

        if (keyToDepositCount == 0) {
            revert NotEnoughFunds();
        }

        (bytes[] memory publicKeys, bytes[] memory signatures) = _getNextValidators(keyToDepositCount);

        uint256 receivedPublicKeyCount = publicKeys.length;

        if (receivedPublicKeyCount == 0) {
            revert NoAvailableValidatorKeys();
        }

        if (receivedPublicKeyCount > keyToDepositCount) {
            revert InvalidPublicKeyCount();
        }

        uint256 receivedSignatureCount = signatures.length;

        if (receivedSignatureCount != receivedPublicKeyCount) {
            revert InvalidSignatureCount();
        }

        bytes32 withdrawalCredentials = WithdrawalCredentials.get();

        if (withdrawalCredentials == 0) {
            revert InvalidWithdrawalCredentials();
        }

        for (uint256 idx = 0; idx < receivedPublicKeyCount;) {
            _depositValidator(publicKeys[idx], signatures[idx], withdrawalCredentials);
            unchecked {
                ++idx;
            }
        }
        BalanceToDeposit.set(balanceToDeposit - DEPOSIT_SIZE * receivedPublicKeyCount);
        DepositedValidatorCount.set(DepositedValidatorCount.get() + receivedPublicKeyCount);
    }

    /// @notice Deposits 32 ETH to the official Deposit contract
    /// @param _publicKey The public key of the validator
    /// @param _signature The signature provided by the operator
    /// @param _withdrawalCredentials The withdrawal credentials provided by River
    function _depositValidator(bytes memory _publicKey, bytes memory _signature, bytes32 _withdrawalCredentials)
        internal
    {
        if (_publicKey.length != PUBLIC_KEY_LENGTH) {
            revert InconsistentPublicKeys();
        }

        if (_signature.length != SIGNATURE_LENGTH) {
            revert InconsistentSignatures();
        }
        uint256 value = DEPOSIT_SIZE;

        uint256 depositAmount = value / 1 gwei;

        bytes32 pubkeyRoot = sha256(bytes.concat(_publicKey, bytes16(0)));
        bytes32 signatureRoot = sha256(
            bytes.concat(
                sha256(LibBytes.slice(_signature, 0, 64)),
                sha256(bytes.concat(LibBytes.slice(_signature, 64, SIGNATURE_LENGTH - 64), bytes32(0)))
            )
        );

        bytes32 depositDataRoot = sha256(
            bytes.concat(
                sha256(bytes.concat(pubkeyRoot, _withdrawalCredentials)),
                sha256(bytes.concat(bytes32(LibUint256.toLittleEndian64(depositAmount)), signatureRoot))
            )
        );

        uint256 targetBalance = address(this).balance - value;

        IDepositContract(DepositContractAddress.get()).deposit{value: value}(
            _publicKey, abi.encodePacked(_withdrawalCredentials), _signature, depositDataRoot
        );
        if (address(this).balance != targetBalance) {
            revert ErrorOnDeposit();
        }
        emit FundedValidatorKey(_publicKey);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../interfaces/components/IOracleManager.1.sol";

import "../state/river/OracleAddress.sol";
import "../state/river/LastOracleRoundId.sol";
import "../state/river/CLValidatorTotalBalance.sol";
import "../state/river/CLValidatorCount.sol";
import "../state/river/DepositedValidatorCount.sol";

/// @title Oracle Manager (v1)
/// @author Kiln
/// @notice This contract handles the inputs provided by the oracle
/// @notice The Oracle contract is plugged to this contract and is in charge of pushing
/// @notice data whenever a new report has been deemed valid. The report consists in two
/// @notice values: the sum of all balances of all deposited validators and the count of
/// @notice validators that have been activated on the consensus layer.
abstract contract OracleManagerV1 is IOracleManagerV1 {
    /// @notice Handler called if the delta between the last and new validator balance sum is positive
    /// @dev Must be overridden
    /// @param _profits The positive increase in the validator balance sum (staking rewards)
    function _onEarnings(uint256 _profits) internal virtual;

    /// @notice Handler called to pull the Execution layer fees from the recipient
    /// @dev Must be overridden
    /// @param _max The maximum amount to pull inside the system
    /// @return The amount pulled inside the system
    function _pullELFees(uint256 _max) internal virtual returns (uint256);

    /// @notice Handler called to retrieve the system administrator address
    /// @dev Must be overridden
    /// @return The system administrator address
    function _getRiverAdmin() internal view virtual returns (address);

    /// @notice Prevents unauthorized calls
    modifier onlyAdmin_OMV1() {
        if (msg.sender != _getRiverAdmin()) {
            revert LibErrors.Unauthorized(msg.sender);
        }
        _;
    }

    /// @notice Set the initial oracle address
    /// @param _oracle Address of the oracle
    function initOracleManagerV1(address _oracle) internal {
        OracleAddress.set(_oracle);
        emit SetOracle(_oracle);
    }

    /// @inheritdoc IOracleManagerV1
    function getOracle() external view returns (address) {
        return OracleAddress.get();
    }

    /// @inheritdoc IOracleManagerV1
    function getCLValidatorTotalBalance() external view returns (uint256) {
        return CLValidatorTotalBalance.get();
    }

    /// @inheritdoc IOracleManagerV1
    function getCLValidatorCount() external view returns (uint256) {
        return CLValidatorCount.get();
    }

    /// @inheritdoc IOracleManagerV1
    function setOracle(address _oracleAddress) external onlyAdmin_OMV1 {
        OracleAddress.set(_oracleAddress);
        emit SetOracle(_oracleAddress);
    }

    /// @inheritdoc IOracleManagerV1
    function setConsensusLayerData(
        uint256 _validatorCount,
        uint256 _validatorTotalBalance,
        bytes32 _roundId,
        uint256 _maxIncrease
    ) external {
        if (msg.sender != OracleAddress.get()) {
            revert LibErrors.Unauthorized(msg.sender);
        }

        if (_validatorCount > DepositedValidatorCount.get()) {
            revert InvalidValidatorCountReport(_validatorCount, DepositedValidatorCount.get());
        }

        uint256 newValidators = _validatorCount - CLValidatorCount.get();
        uint256 previousValidatorTotalBalance = CLValidatorTotalBalance.get() + (newValidators * 32 ether);

        CLValidatorTotalBalance.set(_validatorTotalBalance);
        CLValidatorCount.set(_validatorCount);
        LastOracleRoundId.set(_roundId);

        uint256 executionLayerFees;

        // if there's a margin left for pulling the execution layer fees that would leave our delta under the allowed maxIncrease value, do it
        if ((_maxIncrease + previousValidatorTotalBalance) > _validatorTotalBalance) {
            executionLayerFees = _pullELFees((_maxIncrease + previousValidatorTotalBalance) - _validatorTotalBalance);
        }

        if (previousValidatorTotalBalance < _validatorTotalBalance + executionLayerFees) {
            _onEarnings((_validatorTotalBalance + executionLayerFees) - previousValidatorTotalBalance);
        }

        emit ConsensusLayerDataUpdate(_validatorCount, _validatorTotalBalance, _roundId);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../interfaces/components/ISharesManager.1.sol";

import "../libraries/LibSanitize.sol";

import "../state/river/Shares.sol";
import "../state/river/SharesPerOwner.sol";
import "../state/shared/ApprovalsPerOwner.sol";

/// @title Shares Manager (v1)
/// @author Kiln
/// @notice This contract handles the shares of the depositor and the ERC20 interface
abstract contract SharesManagerV1 is ISharesManagerV1 {
    /// @notice Internal hook triggered on the external transfer call
    /// @dev Must be overridden
    /// @param _from Address of the sender
    /// @param _to Address of the recipient
    function _onTransfer(address _from, address _to) internal view virtual;

    /// @notice Internal method to override to provide the total underlying asset balance
    /// @dev Must be overridden
    /// @return The total asset balance of the system
    function _assetBalance() internal view virtual returns (uint256);

    /// @notice Modifier used to ensure that the transfer is allowed by using the internal hook to perform internal checks
    /// @param _from Address of the sender
    /// @param _to Address of the recipient
    modifier transferAllowed(address _from, address _to) {
        _onTransfer(_from, _to);
        _;
    }

    /// @notice Modifier used to ensure the amount transferred is not 0
    /// @param _value Amount to check
    modifier isNotZero(uint256 _value) {
        if (_value == 0) {
            revert NullTransfer();
        }
        _;
    }

    /// @notice Modifier used to ensure that the sender has enough funds for the transfer
    /// @param _owner Address of the sender
    /// @param _value Value that is required to be sent
    modifier hasFunds(address _owner, uint256 _value) {
        if (_balanceOf(_owner) < _value) {
            revert BalanceTooLow();
        }
        _;
    }

    /// @inheritdoc ISharesManagerV1
    function name() external pure returns (string memory) {
        return "Liquid Staked ETH";
    }

    /// @inheritdoc ISharesManagerV1
    function symbol() external pure returns (string memory) {
        return "LsETH";
    }

    /// @inheritdoc ISharesManagerV1
    function decimals() external pure returns (uint8) {
        return 18;
    }

    /// @inheritdoc ISharesManagerV1
    function totalSupply() external view returns (uint256) {
        return _totalSupply();
    }

    /// @inheritdoc ISharesManagerV1
    function totalUnderlyingSupply() external view returns (uint256) {
        return _assetBalance();
    }

    /// @inheritdoc ISharesManagerV1
    function balanceOf(address _owner) external view returns (uint256) {
        return _balanceOf(_owner);
    }

    /// @inheritdoc ISharesManagerV1
    function balanceOfUnderlying(address _owner) public view returns (uint256) {
        return _balanceFromShares(SharesPerOwner.get(_owner));
    }

    /// @inheritdoc ISharesManagerV1
    function underlyingBalanceFromShares(uint256 _shares) external view returns (uint256) {
        return _balanceFromShares(_shares);
    }

    /// @inheritdoc ISharesManagerV1
    function sharesFromUnderlyingBalance(uint256 _underlyingAssetAmount) external view returns (uint256) {
        return _sharesFromBalance(_underlyingAssetAmount);
    }

    /// @inheritdoc ISharesManagerV1
    function allowance(address _owner, address _spender) external view returns (uint256) {
        return ApprovalsPerOwner.get(_owner, _spender);
    }

    /// @inheritdoc ISharesManagerV1
    function transfer(address _to, uint256 _value)
        external
        transferAllowed(msg.sender, _to)
        isNotZero(_value)
        hasFunds(msg.sender, _value)
        returns (bool)
    {
        if (_to == address(0)) {
            revert UnauthorizedTransfer(msg.sender, address(0));
        }
        return _transfer(msg.sender, _to, _value);
    }

    /// @inheritdoc ISharesManagerV1
    function transferFrom(address _from, address _to, uint256 _value)
        external
        transferAllowed(_from, _to)
        isNotZero(_value)
        hasFunds(_from, _value)
        returns (bool)
    {
        if (_to == address(0)) {
            revert UnauthorizedTransfer(_from, address(0));
        }
        _spendAllowance(_from, _value);
        return _transfer(_from, _to, _value);
    }

    /// @inheritdoc ISharesManagerV1
    function approve(address _spender, uint256 _value) external returns (bool) {
        _approve(msg.sender, _spender, _value);
        return true;
    }

    /// @inheritdoc ISharesManagerV1
    function increaseAllowance(address _spender, uint256 _additionalValue) external returns (bool) {
        _approve(msg.sender, _spender, ApprovalsPerOwner.get(msg.sender, _spender) + _additionalValue);
        return true;
    }

    /// @inheritdoc ISharesManagerV1
    function decreaseAllowance(address _spender, uint256 _subtractableValue) external returns (bool) {
        _approve(msg.sender, _spender, ApprovalsPerOwner.get(msg.sender, _spender) - _subtractableValue);
        return true;
    }

    /// @notice Internal utility to spend the allowance of an account from the message sender
    /// @param _from Address owning the allowance
    /// @param _value Amount of allowance in shares to spend
    function _spendAllowance(address _from, uint256 _value) internal {
        uint256 currentAllowance = ApprovalsPerOwner.get(_from, msg.sender);
        if (currentAllowance < _value) {
            revert AllowanceTooLow(_from, msg.sender, currentAllowance, _value);
        }
        if (currentAllowance != type(uint256).max) {
            _approve(_from, msg.sender, currentAllowance - _value);
        }
    }

    /// @notice Internal utility to change the allowance of an owner to a spender
    /// @param _owner The owner of the shares
    /// @param _spender The allowed spender of the shares
    /// @param _value The new allowance value
    function _approve(address _owner, address _spender, uint256 _value) internal {
        LibSanitize._notZeroAddress(_owner);
        LibSanitize._notZeroAddress(_spender);
        ApprovalsPerOwner.set(_owner, _spender, _value);
        emit Approval(_owner, _spender, _value);
    }

    /// @notice Internal utility to retrieve the total supply of tokens
    /// @return The total supply
    function _totalSupply() internal view returns (uint256) {
        return Shares.get();
    }

    /// @notice Internal utility to perform an unchecked transfer
    /// @param _from Address sending the tokens
    /// @param _to Address receiving the tokens
    /// @param _value Amount of shares to be sent
    /// @return True if success
    function _transfer(address _from, address _to, uint256 _value) internal returns (bool) {
        SharesPerOwner.set(_from, SharesPerOwner.get(_from) - _value);
        SharesPerOwner.set(_to, SharesPerOwner.get(_to) + _value);

        emit Transfer(_from, _to, _value);

        return true;
    }

    /// @notice Internal utility to retrieve the underlying asset balance for the given shares
    /// @param _shares Amount of shares to convert
    /// @return The balance from the given shares
    function _balanceFromShares(uint256 _shares) internal view returns (uint256) {
        uint256 _totalSharesValue = Shares.get();

        if (_totalSharesValue == 0) {
            return 0;
        }

        return ((_shares * _assetBalance())) / _totalSharesValue;
    }

    /// @notice Internal utility to retrieve the shares count for a given underlying asset amount
    /// @param _balance Amount of underlying asset balance to convert
    /// @return The shares from the given balance
    function _sharesFromBalance(uint256 _balance) internal view returns (uint256) {
        uint256 _totalSharesValue = Shares.get();

        if (_totalSharesValue == 0) {
            return 0;
        }

        return (_balance * _totalSharesValue) / _assetBalance();
    }

    /// @notice Internal utility to mint shares for the specified user
    /// @dev This method assumes that funds received are now part of the _assetBalance()
    /// @param _owner Account that should receive the new shares
    /// @param _underlyingAssetValue Value of underlying asset received, to convert into shares
    /// @return sharesToMint The amnount of minted shares
    function _mintShares(address _owner, uint256 _underlyingAssetValue) internal returns (uint256 sharesToMint) {
        uint256 oldTotalAssetBalance = _assetBalance() - _underlyingAssetValue;

        if (oldTotalAssetBalance == 0) {
            sharesToMint = _underlyingAssetValue;
            _mintRawShares(_owner, _underlyingAssetValue);
        } else {
            sharesToMint = (_underlyingAssetValue * _totalSupply()) / oldTotalAssetBalance;
            _mintRawShares(_owner, sharesToMint);
        }
    }

    /// @notice Internal utility to mint shares without any conversion, and emits a mint Transfer event
    /// @param _owner Account that should receive the new shares
    /// @param _value Amount of shares to mint
    function _mintRawShares(address _owner, uint256 _value) internal {
        Shares.set(Shares.get() + _value);
        SharesPerOwner.set(_owner, SharesPerOwner.get(_owner) + _value);
        emit Transfer(address(0), _owner, _value);
    }

    /// @notice Internal utility to retrieve the amount of shares per owner
    /// @param _owner Account to be checked
    /// @return The balance of the account in shares
    function _balanceOf(address _owner) internal view returns (uint256) {
        return SharesPerOwner.get(_owner);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../interfaces/components/IUserDepositManager.1.sol";

import "../libraries/LibSanitize.sol";

import "../state/river/BalanceToDeposit.sol";

/// @title User Deposit Manager (v1)
/// @author Kiln
/// @notice This contract handles the inbound transfers cases or the explicit submissions
abstract contract UserDepositManagerV1 is IUserDepositManagerV1 {
    /// @notice Handler called whenever a user has sent funds to the contract
    /// @dev Must be overridden
    /// @param _depositor Address that made the deposit
    /// @param _recipient Address that receives the minted shares
    /// @param _amount Amount deposited
    function _onDeposit(address _depositor, address _recipient, uint256 _amount) internal virtual;

    /// @inheritdoc IUserDepositManagerV1
    function deposit() external payable {
        _deposit(msg.sender);
    }

    /// @inheritdoc IUserDepositManagerV1
    function depositAndTransfer(address _recipient) external payable {
        LibSanitize._notZeroAddress(_recipient);
        _deposit(_recipient);
    }

    /// @inheritdoc IUserDepositManagerV1
    receive() external payable {
        _deposit(msg.sender);
    }

    /// @inheritdoc IUserDepositManagerV1
    fallback() external payable {
        revert LibErrors.InvalidCall();
    }

    /// @notice Internal utility calling the deposit handler and emitting the deposit details
    /// @param _recipient The account receiving the minted shares
    function _deposit(address _recipient) internal {
        if (msg.value == 0) {
            revert EmptyDeposit();
        }

        BalanceToDeposit.set(BalanceToDeposit.get() + msg.value);

        _onDeposit(msg.sender, _recipient, msg.value);

        emit UserDeposit(msg.sender, _recipient, msg.value);
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

/// @title Allowlist Interface (v1)
/// @author Kiln
/// @notice This interface exposes methods to handle the list of allowed recipients.
interface IAllowlistV1 {
    /// @notice The permissions of several accounts have changed
    /// @param accounts List of accounts
    /// @param permissions New permissions for each account at the same index
    event SetAllowlistPermissions(address[] indexed accounts, uint256[] permissions);

    /// @notice The stored allower address has been changed
    /// @param allower The new allower address
    event SetAllower(address indexed allower);

    /// @notice The provided accounts list is empty
    error InvalidAlloweeCount();

    /// @notice The account is denied access
    /// @param _account The denied account
    error Denied(address _account);

    /// @notice The provided accounts and permissions list have different lengths
    error MismatchedAlloweeAndStatusCount();

    /// @notice Initializes the allowlist
    /// @param _admin Address of the Allowlist administrator
    /// @param _allower Address of the allower
    function initAllowlistV1(address _admin, address _allower) external;

    /// @notice Retrieves the allower address
    /// @return The address of the allower
    function getAllower() external view returns (address);

    /// @notice This method returns true if the user has the expected permission and
    ///         is not in the deny list
    /// @param _account Recipient to verify
    /// @param _mask Combination of permissions to verify
    /// @return True if mask is respected and user is allowed
    function isAllowed(address _account, uint256 _mask) external view returns (bool);

    /// @notice This method returns true if the user is in the deny list
    /// @param _account Recipient to verify
    /// @return True if user is denied access
    function isDenied(address _account) external view returns (bool);

    /// @notice This method returns true if the user has the expected permission
    ///         ignoring any deny list membership
    /// @param _account Recipient to verify
    /// @param _mask Combination of permissions to verify
    /// @return True if mask is respected
    function hasPermission(address _account, uint256 _mask) external view returns (bool);

    /// @notice This method retrieves the raw permission value
    /// @param _account Recipient to verify
    /// @return The raw permissions value of the account
    function getPermissions(address _account) external view returns (uint256);

    /// @notice This method should be used as a modifier and is expected to revert
    ///         if the user hasn't got the required permission or if the user is
    ///         in the deny list.
    /// @param _account Recipient to verify
    /// @param _mask Combination of permissions to verify
    function onlyAllowed(address _account, uint256 _mask) external view;

    /// @notice Changes the allower address
    /// @param _newAllowerAddress New address allowed to edit the allowlist
    function setAllower(address _newAllowerAddress) external;

    /// @notice Sets the allowlisting status for one or more accounts
    /// @dev The permission value is overridden and not updated
    /// @param _accounts Accounts with statuses to edit
    /// @param _permissions Allowlist permissions for each account, in the same order as _accounts
    function allow(address[] calldata _accounts, uint256[] calldata _permissions) external;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/// @title Deposit Contract Interface
/// @notice This interface exposes methods to perform validator deposits
interface IDepositContract {
    /// @notice Official deposit method to activate a validator on the consensus layer
    /// @param pubkey The 48 bytes long BLS Public key representing the validator
    /// @param withdrawalCredentials The 32 bytes long withdrawal credentials, configures the withdrawal recipient
    /// @param signature The 96 bytes long BLS Signature performed by the pubkey's private key
    /// @param depositDataRoot The root hash of the whole deposit data structure
    function deposit(
        bytes calldata pubkey,
        bytes calldata withdrawalCredentials,
        bytes calldata signature,
        bytes32 depositDataRoot
    ) external payable;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/// @title Execution Layer Fee Recipient Interface (v1)
/// @author Kiln
/// @notice This interface exposes methods to receive all the execution layer fees from the proposed blocks + bribes
interface IELFeeRecipientV1 {
    /// @notice The storage river address has changed
    /// @param river The new river address
    event SetRiver(address indexed river);

    /// @notice The fallback has been triggered
    error InvalidCall();

    /// @notice Initialize the fee recipient with the required arguments
    /// @param _riverAddress Address of River
    function initELFeeRecipientV1(address _riverAddress) external;

    /// @notice Pulls all the ETH to the River contract
    /// @dev Only callable by the River contract
    /// @param _maxAmount The maximum amount to pull into the system
    function pullELFees(uint256 _maxAmount) external;

    /// @notice Ether receiver
    receive() external payable;

    /// @notice Invalid fallback detector
    fallback() external payable;
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

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./components/IConsensusLayerDepositManager.1.sol";
import "./components/IOracleManager.1.sol";
import "./components/ISharesManager.1.sol";
import "./components/IUserDepositManager.1.sol";

/// @title River Interface (v1)
/// @author Kiln
/// @notice The main system interface
interface IRiverV1 is IConsensusLayerDepositManagerV1, IUserDepositManagerV1, ISharesManagerV1, IOracleManagerV1 {
    /// @notice Funds have been pulled from the Execution Layer Fee Recipient
    /// @param amount The amount pulled
    event PulledELFees(uint256 amount);

    /// @notice The stored Execution Layer Fee Recipient has been changed
    /// @param elFeeRecipient The new Execution Layer Fee Recipient
    event SetELFeeRecipient(address indexed elFeeRecipient);

    /// @notice The stored Collector has been changed
    /// @param collector The new Collector
    event SetCollector(address indexed collector);

    /// @notice The stored Allowlist has been changed
    /// @param allowlist The new Allowlist
    event SetAllowlist(address indexed allowlist);

    /// @notice The stored Global Fee has been changed
    /// @param fee The new Global Fee
    event SetGlobalFee(uint256 fee);

    /// @notice The stored Operators Registry has been changed
    /// @param operatorRegistry The new Operators Registry
    event SetOperatorsRegistry(address indexed operatorRegistry);

    /// @notice The system underlying supply increased. This is a snapshot of the balances for accounting purposes
    /// @param _collector The address of the collector during this event
    /// @param _oldTotalUnderlyingBalance Old total ETH balance under management by River
    /// @param _oldTotalSupply Old total supply in shares
    /// @param _newTotalUnderlyingBalance New total ETH balance under management by River
    /// @param _newTotalSupply New total supply in shares
    event RewardsEarned(
        address indexed _collector,
        uint256 _oldTotalUnderlyingBalance,
        uint256 _oldTotalSupply,
        uint256 _newTotalUnderlyingBalance,
        uint256 _newTotalSupply
    );

    /// @notice The computed amount of shares to mint is 0
    error ZeroMintedShares();

    /// @notice The access was denied
    /// @param account The account that was denied
    error Denied(address account);

    /// @notice Initializes the River system
    /// @param _depositContractAddress Address to make Consensus Layer deposits
    /// @param _elFeeRecipientAddress Address that receives the execution layer fees
    /// @param _withdrawalCredentials Credentials to use for every validator deposit
    /// @param _oracleAddress The address of the Oracle contract
    /// @param _systemAdministratorAddress Administrator address
    /// @param _allowlistAddress Address of the allowlist contract
    /// @param _operatorRegistryAddress Address of the operator registry
    /// @param _collectorAddress Address receiving the the global fee on revenue
    /// @param _globalFee Amount retained when the ETH balance increases and sent to the collector
    function initRiverV1(
        address _depositContractAddress,
        address _elFeeRecipientAddress,
        bytes32 _withdrawalCredentials,
        address _oracleAddress,
        address _systemAdministratorAddress,
        address _allowlistAddress,
        address _operatorRegistryAddress,
        address _collectorAddress,
        uint256 _globalFee
    ) external;

    /// @notice Get the current global fee
    /// @return The global fee
    function getGlobalFee() external view returns (uint256);

    /// @notice Retrieve the allowlist address
    /// @return The allowlist address
    function getAllowlist() external view returns (address);

    /// @notice Retrieve the collector address
    /// @return The collector address
    function getCollector() external view returns (address);

    /// @notice Retrieve the execution layer fee recipient
    /// @return The execution layer fee recipient address
    function getELFeeRecipient() external view returns (address);

    /// @notice Retrieve the operators registry
    /// @return The operators registry address
    function getOperatorsRegistry() external view returns (address);

    /// @notice Changes the global fee parameter
    /// @param newFee New fee value
    function setGlobalFee(uint256 newFee) external;

    /// @notice Changes the allowlist address
    /// @param _newAllowlist New address for the allowlist
    function setAllowlist(address _newAllowlist) external;

    /// @notice Changes the collector address
    /// @param _newCollector New address for the collector
    function setCollector(address _newCollector) external;

    /// @notice Changes the execution layer fee recipient
    /// @param _newELFeeRecipient New address for the recipient
    function setELFeeRecipient(address _newELFeeRecipient) external;

    /// @notice Input for execution layer fee earnings
    function sendELFees() external payable;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/// @title Consensys Layer Deposit Manager Interface (v1)
/// @author Kiln
/// @notice This interface exposes methods to handle the interactions with the official deposit contract
interface IConsensusLayerDepositManagerV1 {
    /// @notice A validator key got funded on the deposit contract
    /// @param publicKey BLS Public key that got funded
    event FundedValidatorKey(bytes publicKey);

    /// @notice The stored deposit contract address changed
    /// @param depositContract Address of the deposit contract
    event SetDepositContractAddress(address indexed depositContract);

    /// @notice The stored withdrawal credentials changed
    /// @param withdrawalCredentials The withdrawal credentials to use for deposits
    event SetWithdrawalCredentials(bytes32 withdrawalCredentials);

    /// @notice Not enough funds to deposit one validator
    error NotEnoughFunds();

    /// @notice The length of the BLS Public key is invalid during deposit
    error InconsistentPublicKeys();

    /// @notice The length of the BLS Signature is invalid during deposit
    error InconsistentSignatures();

    /// @notice The internal key retrieval returned no keys
    error NoAvailableValidatorKeys();

    /// @notice The received count of public keys to deposit is invalid
    error InvalidPublicKeyCount();

    /// @notice The received count of signatures to deposit is invalid
    error InvalidSignatureCount();

    /// @notice The withdrawal credentials value is null
    error InvalidWithdrawalCredentials();

    /// @notice An error occured during the deposit
    error ErrorOnDeposit();

    /// @notice Returns the amount of pending ETH
    /// @return The amount of pending ETH
    function getBalanceToDeposit() external view returns (uint256);

    /// @notice Retrieve the withdrawal credentials
    /// @return The withdrawal credentials
    function getWithdrawalCredentials() external view returns (bytes32);

    /// @notice Get the deposited validator count (the count of deposits made by the contract)
    /// @return The deposited validator count
    function getDepositedValidatorCount() external view returns (uint256);

    /// @notice Deposits current balance to the Consensus Layer by batches of 32 ETH
    /// @param _maxCount The maximum amount of validator keys to fund
    function depositToConsensusLayer(uint256 _maxCount) external;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/// @title Oracle Manager (v1)
/// @author Kiln
/// @notice This interface exposes methods to handle the inputs provided by the oracle
interface IOracleManagerV1 {
    /// @notice The stored oracle address changed
    /// @param oracleAddress The new oracle address
    event SetOracle(address indexed oracleAddress);

    /// @notice The consensus layer data provided by the oracle has been updated
    /// @param validatorCount The new count of validators running on the consensus layer
    /// @param validatorTotalBalance The new total balance sum of all validators
    /// @param roundId Round identifier
    event ConsensusLayerDataUpdate(uint256 validatorCount, uint256 validatorTotalBalance, bytes32 roundId);

    /// @notice The reported validator count is invalid
    /// @param providedValidatorCount The received validator count value
    /// @param depositedValidatorCount The number of deposits performed by the system
    error InvalidValidatorCountReport(uint256 providedValidatorCount, uint256 depositedValidatorCount);

    /// @notice Get oracle address
    /// @return The oracle address
    function getOracle() external view returns (address);

    /// @notice Get CL validator total balance
    /// @return The CL Validator total balance
    function getCLValidatorTotalBalance() external view returns (uint256);

    /// @notice Get CL validator count (the amount of validator reported by the oracles)
    /// @return The CL validator count
    function getCLValidatorCount() external view returns (uint256);

    /// @notice Set the oracle address
    /// @param _oracleAddress Address of the oracle
    function setOracle(address _oracleAddress) external;

    /// @notice Sets the validator count and validator total balance sum reported by the oracle
    /// @dev Can only be called by the oracle address
    /// @dev The round id is a blackbox value that should only be used to identify unique reports
    /// @dev When a report is performed, River computes the amount of fees that can be pulled
    /// @dev from the execution layer fee recipient. This amount is capped by the max allowed
    /// @dev increase provided during the report.
    /// @dev If the total asset balance increases (from the reported total balance and the pulled funds)
    /// @dev we then compute the share that must be taken for the collector on the positive delta.
    /// @dev The execution layer fees are taken into account here because they are the product of
    /// @dev node operator's work, just like consensus layer fees, and both should be handled in the
    /// @dev same manner, as a single revenue stream for the users and the collector.
    /// @param _validatorCount The number of active validators on the consensus layer
    /// @param _validatorTotalBalance The balance sum of the active validators on the consensus layer
    /// @param _roundId An identifier for this update
    /// @param _maxIncrease The maximum allowed increase in the total balance
    function setConsensusLayerData(
        uint256 _validatorCount,
        uint256 _validatorTotalBalance,
        bytes32 _roundId,
        uint256 _maxIncrease
    ) external;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/// @title Shares Manager Interface (v1)
/// @author Kiln
/// @notice This interface exposes methods to handle the shares of the depositor and the ERC20 interface
interface ISharesManagerV1 is IERC20 {
    /// @notice Balance too low to perform operation
    error BalanceTooLow();

    /// @notice Allowance too low to perform operation
    /// @param _from Account where funds are sent from
    /// @param _operator Account attempting the transfer
    /// @param _allowance Current allowance
    /// @param _value Requested transfer value in shares
    error AllowanceTooLow(address _from, address _operator, uint256 _allowance, uint256 _value);

    /// @notice Invalid empty transfer
    error NullTransfer();

    /// @notice Invalid transfer recipients
    /// @param _from Account sending the funds in the invalid transfer
    /// @param _to Account receiving the funds in the invalid transfer
    error UnauthorizedTransfer(address _from, address _to);

    /// @notice Retrieve the token name
    /// @return The token name
    function name() external pure returns (string memory);

    /// @notice Retrieve the token symbol
    /// @return The token symbol
    function symbol() external pure returns (string memory);

    /// @notice Retrieve the decimal count
    /// @return The decimal count
    function decimals() external pure returns (uint8);

    /// @notice Retrieve the total token supply
    /// @return The total supply in shares
    function totalSupply() external view returns (uint256);

    /// @notice Retrieve the total underlying asset supply
    /// @return The total underlying asset supply
    function totalUnderlyingSupply() external view returns (uint256);

    /// @notice Retrieve the balance of an account
    /// @param _owner Address to be checked
    /// @return The balance of the account in shares
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Retrieve the underlying asset balance of an account
    /// @param _owner Address to be checked
    /// @return The underlying balance of the account
    function balanceOfUnderlying(address _owner) external view returns (uint256);

    /// @notice Retrieve the underlying asset balance from an amount of shares
    /// @param _shares Amount of shares to convert
    /// @return The underlying asset balance represented by the shares
    function underlyingBalanceFromShares(uint256 _shares) external view returns (uint256);

    /// @notice Retrieve the shares count from an underlying asset amount
    /// @param _underlyingAssetAmount Amount of underlying asset to convert
    /// @return The amount of shares worth the underlying asset amopunt
    function sharesFromUnderlyingBalance(uint256 _underlyingAssetAmount) external view returns (uint256);

    /// @notice Retrieve the allowance value for a spender
    /// @param _owner Address that issued the allowance
    /// @param _spender Address that received the allowance
    /// @return The allowance in shares for a given spender
    function allowance(address _owner, address _spender) external view returns (uint256);

    /// @notice Performs a transfer from the message sender to the provided account
    /// @param _to Address receiving the tokens
    /// @param _value Amount of shares to be sent
    /// @return True if success
    function transfer(address _to, uint256 _value) external returns (bool);

    /// @notice Performs a transfer between two recipients
    /// @param _from Address sending the tokens
    /// @param _to Address receiving the tokens
    /// @param _value Amount of shares to be sent
    /// @return True if success
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);

    /// @notice Approves an account for future spendings
    /// @dev An approved account can use transferFrom to transfer funds on behalf of the token owner
    /// @param _spender Address that is allowed to spend the tokens
    /// @param _value The allowed amount in shares, will override previous value
    /// @return True if success
    function approve(address _spender, uint256 _value) external returns (bool);

    /// @notice Increase allowance to another account
    /// @param _spender Spender that receives the allowance
    /// @param _additionalValue Amount of shares to add
    /// @return True if success
    function increaseAllowance(address _spender, uint256 _additionalValue) external returns (bool);

    /// @notice Decrease allowance to another account
    /// @param _spender Spender that receives the allowance
    /// @param _subtractableValue Amount of shares to subtract
    /// @return True if success
    function decreaseAllowance(address _spender, uint256 _subtractableValue) external returns (bool);
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/// @title User Deposit Manager (v1)
/// @author Kiln
/// @notice This interface exposes methods to handle the inbound transfers cases or the explicit submissions
interface IUserDepositManagerV1 {
    /// @notice User deposited ETH in the system
    /// @param depositor Address performing the deposit
    /// @param recipient Address receiving the minted shares
    /// @param amount Amount in ETH deposited
    event UserDeposit(address indexed depositor, address indexed recipient, uint256 amount);

    /// @notice And empty deposit attempt was made
    error EmptyDeposit();

    /// @notice Explicit deposit method to mint on msg.sender
    function deposit() external payable;

    /// @notice Explicit deposit method to mint on msg.sender and transfer to _recipient
    /// @param _recipient Address receiving the minted LsETH
    function depositAndTransfer(address _recipient) external payable;

    /// @notice Implicit deposit method, when the user performs a regular transfer to the contract
    receive() external payable;

    /// @notice Invalid call, when the user sends a transaction with a data payload but no method matched
    fallback() external payable;
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

import "../../libraries/LibUnstructuredStorage.sol";
import "../../libraries/LibSanitize.sol";

/// @title Allowlist Address Storage
/// @notice Utility to manage the Allowlist Address in storage
library AllowlistAddress {
    /// @notice Storage slot of the Allowlist Address
    bytes32 internal constant ALLOWLIST_ADDRESS_SLOT = bytes32(uint256(keccak256("river.state.allowlistAddress")) - 1);

    /// @notice Retrieve the Allowlist Address
    /// @return The Allowlist Address
    function get() internal view returns (address) {
        return LibUnstructuredStorage.getStorageAddress(ALLOWLIST_ADDRESS_SLOT);
    }

    /// @notice Sets the Allowlist Address
    /// @param _newValue New Allowlist Address
    function set(address _newValue) internal {
        LibSanitize._notZeroAddress(_newValue);
        LibUnstructuredStorage.setStorageAddress(ALLOWLIST_ADDRESS_SLOT, _newValue);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibUnstructuredStorage.sol";

library BalanceToDeposit {
    bytes32 internal constant BALANCE_TO_DEPOSIT_SLOT = bytes32(uint256(keccak256("river.state.balanceToDeposit")) - 1);

    function get() internal view returns (uint256) {
        return LibUnstructuredStorage.getStorageUint256(BALANCE_TO_DEPOSIT_SLOT);
    }

    function set(uint256 newValue) internal {
        LibUnstructuredStorage.setStorageUint256(BALANCE_TO_DEPOSIT_SLOT, newValue);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibUnstructuredStorage.sol";

/// @title Consensus Layer Validator Count Storage
/// @notice Utility to manage the Consensus Layer Validator Count in storage
library CLValidatorCount {
    /// @notice Storage slot of the Consensus Layer Validator Count
    bytes32 internal constant CL_VALIDATOR_COUNT_SLOT = bytes32(uint256(keccak256("river.state.clValidatorCount")) - 1);

    /// @notice Retrieve the Consensus Layer Validator Count
    /// @return The Consensus Layer Validator Count
    function get() internal view returns (uint256) {
        return LibUnstructuredStorage.getStorageUint256(CL_VALIDATOR_COUNT_SLOT);
    }

    /// @notice Sets the Consensus Layer Validator Count
    /// @param _newValue New Consensus Layer Validator Count
    function set(uint256 _newValue) internal {
        LibUnstructuredStorage.setStorageUint256(CL_VALIDATOR_COUNT_SLOT, _newValue);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibUnstructuredStorage.sol";

/// @title Consensus Layer Validator Total Balance Storage
/// @notice Utility to manage the Consensus Layer Validator Total Balance in storage
library CLValidatorTotalBalance {
    /// @notice Storage slot of the Consensus Layer Validator Total Balance
    bytes32 internal constant CL_VALIDATOR_TOTAL_BALANCE_SLOT =
        bytes32(uint256(keccak256("river.state.clValidatorTotalBalance")) - 1);

    /// @notice Retrieve the Consensus Layer Validator Total Balance
    /// @return The Consensus Layer Validator Total Balance
    function get() internal view returns (uint256) {
        return LibUnstructuredStorage.getStorageUint256(CL_VALIDATOR_TOTAL_BALANCE_SLOT);
    }

    /// @notice Sets the Consensus Layer Validator Total Balance
    /// @param _newValue New Consensus Layer Validator Total Balance
    function set(uint256 _newValue) internal {
        LibUnstructuredStorage.setStorageUint256(CL_VALIDATOR_TOTAL_BALANCE_SLOT, _newValue);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibUnstructuredStorage.sol";
import "../../libraries/LibSanitize.sol";

/// @title Collector Address Storage
/// @notice Utility to manage the Collector Address in storage
library CollectorAddress {
    /// @notice Storage slot of the Collector Address
    bytes32 internal constant COLLECTOR_ADDRESS_SLOT = bytes32(uint256(keccak256("river.state.collectorAddress")) - 1);

    /// @notice Retrieve the Collector Address
    /// @return The Collector Address
    function get() internal view returns (address) {
        return LibUnstructuredStorage.getStorageAddress(COLLECTOR_ADDRESS_SLOT);
    }

    /// @notice Sets the Collector Address
    /// @param _newValue New Collector Address
    function set(address _newValue) internal {
        LibSanitize._notZeroAddress(_newValue);
        LibUnstructuredStorage.setStorageAddress(COLLECTOR_ADDRESS_SLOT, _newValue);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibSanitize.sol";
import "../../libraries/LibUnstructuredStorage.sol";

/// @title Deposit Contract Address Storage
/// @notice Utility to manage the Deposit Contract Address in storage
library DepositContractAddress {
    /// @notice Storage slot of the Deposit Contract Address
    bytes32 internal constant DEPOSIT_CONTRACT_ADDRESS_SLOT =
        bytes32(uint256(keccak256("river.state.depositContractAddress")) - 1);

    /// @notice Retrieve the Deposit Contract Address
    /// @return The Deposit Contract Address
    function get() internal view returns (address) {
        return LibUnstructuredStorage.getStorageAddress(DEPOSIT_CONTRACT_ADDRESS_SLOT);
    }

    /// @notice Sets the Deposit Contract Address
    /// @param _newValue New Deposit Contract Address
    function set(address _newValue) internal {
        LibSanitize._notZeroAddress(_newValue);
        LibUnstructuredStorage.setStorageAddress(DEPOSIT_CONTRACT_ADDRESS_SLOT, _newValue);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibUnstructuredStorage.sol";

/// @title Deposited Validator Count Storage
/// @notice Utility to manage the Deposited Validator Count in storage
library DepositedValidatorCount {
    /// @notice Storage slot of the Deposited Validator Count
    bytes32 internal constant DEPOSITED_VALIDATOR_COUNT_SLOT =
        bytes32(uint256(keccak256("river.state.depositedValidatorCount")) - 1);

    /// @notice Retrieve the Deposited Validator Count
    /// @return The Deposited Validator Count
    function get() internal view returns (uint256) {
        return LibUnstructuredStorage.getStorageUint256(DEPOSITED_VALIDATOR_COUNT_SLOT);
    }

    /// @notice Sets the Deposited Validator Count
    /// @param _newValue New Deposited Validator Count
    function set(uint256 _newValue) internal {
        LibUnstructuredStorage.setStorageUint256(DEPOSITED_VALIDATOR_COUNT_SLOT, _newValue);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibUnstructuredStorage.sol";

/// @title Execution Layer Fee Recipient Address Storage
/// @notice Utility to manage the Execution Layer Fee Recipient Address in storage
library ELFeeRecipientAddress {
    /// @notice Storage slot of the Execution Layer Fee Recipient Address
    bytes32 internal constant EL_FEE_RECIPIENT_ADDRESS =
        bytes32(uint256(keccak256("river.state.elFeeRecipientAddress")) - 1);

    /// @notice Retrieve the Execution Layer Fee Recipient Address
    /// @return The Execution Layer Fee Recipient Address
    function get() internal view returns (address) {
        return LibUnstructuredStorage.getStorageAddress(EL_FEE_RECIPIENT_ADDRESS);
    }

    /// @notice Sets the Execution Layer Fee Recipient Address
    /// @param _newValue New Execution Layer Fee Recipient Address
    function set(address _newValue) internal {
        LibUnstructuredStorage.setStorageAddress(EL_FEE_RECIPIENT_ADDRESS, _newValue);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibSanitize.sol";
import "../../libraries/LibUnstructuredStorage.sol";

/// @title Global Fee Storage
/// @notice Utility to manage the Global Fee in storage
library GlobalFee {
    /// @notice Storage slot of the Global Fee
    bytes32 internal constant GLOBAL_FEE_SLOT = bytes32(uint256(keccak256("river.state.globalFee")) - 1);

    /// @notice Retrieve the Global Fee
    /// @return The Global Fee
    function get() internal view returns (uint256) {
        return LibUnstructuredStorage.getStorageUint256(GLOBAL_FEE_SLOT);
    }

    /// @notice Sets the Global Fee
    /// @param _newValue New Global Fee
    function set(uint256 _newValue) internal {
        LibSanitize._validFee(_newValue);
        LibUnstructuredStorage.setStorageUint256(GLOBAL_FEE_SLOT, _newValue);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibUnstructuredStorage.sol";

/// @title Last Oracle Round Id Storage
/// @notice Utility to manage the Last Oracle Round Id in storage
library LastOracleRoundId {
    /// @notice Storage slot of the Last Oracle Round Id
    bytes32 internal constant LAST_ORACLE_ROUND_ID_SLOT =
        bytes32(uint256(keccak256("river.state.lastOracleRoundId")) - 1);

    /// @notice Retrieve the Last Oracle Round Id
    /// @return The Last Oracle Round Id
    function get() internal view returns (bytes32) {
        return LibUnstructuredStorage.getStorageBytes32(LAST_ORACLE_ROUND_ID_SLOT);
    }

    /// @notice Sets the Last Oracle Round Id
    /// @param _newValue New Last Oracle Round Id
    function set(bytes32 _newValue) internal {
        LibUnstructuredStorage.setStorageBytes32(LAST_ORACLE_ROUND_ID_SLOT, _newValue);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibUnstructuredStorage.sol";
import "../../libraries/LibSanitize.sol";

/// @title Operators Registry Address Storage
/// @notice Utility to manage the Operators Registry Address in storage
library OperatorsRegistryAddress {
    /// @notice Storage slot of the Operators Registry Address
    bytes32 internal constant OPERATORS_REGISTRY_ADDRESS_SLOT =
        bytes32(uint256(keccak256("river.state.operatorsRegistryAddress")) - 1);

    /// @notice Retrieve the Operators Registry Address
    /// @return The Operators Registry Address
    function get() internal view returns (address) {
        return LibUnstructuredStorage.getStorageAddress(OPERATORS_REGISTRY_ADDRESS_SLOT);
    }

    /// @notice Sets the Operators Registry Address
    /// @param _newValue New Operators Registry Address
    function set(address _newValue) internal {
        LibSanitize._notZeroAddress(_newValue);
        LibUnstructuredStorage.setStorageAddress(OPERATORS_REGISTRY_ADDRESS_SLOT, _newValue);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibUnstructuredStorage.sol";
import "../../libraries/LibSanitize.sol";

/// @title Oracle Address Storage
/// @notice Utility to manage the Oracle Address in storage
library OracleAddress {
    /// @notice Storage slot of the Oracle Address
    bytes32 internal constant ORACLE_ADDRESS_SLOT = bytes32(uint256(keccak256("river.state.oracleAddress")) - 1);

    /// @notice Retrieve the Oracle Address
    /// @return The Oracle Address
    function get() internal view returns (address) {
        return LibUnstructuredStorage.getStorageAddress(ORACLE_ADDRESS_SLOT);
    }

    /// @notice Sets the Oracle Address
    /// @param _newValue New Oracle Address
    function set(address _newValue) internal {
        LibSanitize._notZeroAddress(_newValue);
        LibUnstructuredStorage.setStorageAddress(ORACLE_ADDRESS_SLOT, _newValue);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibUnstructuredStorage.sol";

/// @title Shares Count Storage
/// @notice Utility to manage the Shares Count in storage
library Shares {
    /// @notice Storage slot of the Shares Count
    bytes32 internal constant SHARES_SLOT = bytes32(uint256(keccak256("river.state.shares")) - 1);

    /// @notice Retrieve the Shares Count
    /// @return The Shares Count
    function get() internal view returns (uint256) {
        return LibUnstructuredStorage.getStorageUint256(SHARES_SLOT);
    }

    /// @notice Sets the Shares Count
    /// @param _newValue New Shares Count
    function set(uint256 _newValue) internal {
        LibUnstructuredStorage.setStorageUint256(SHARES_SLOT, _newValue);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/// @title Shares Per Owner Storage
/// @notice Utility to manage the Shares Per Owner in storage
library SharesPerOwner {
    /// @notice Storage slot of the Shares Per Owner
    bytes32 internal constant SHARES_PER_OWNER_SLOT = bytes32(uint256(keccak256("river.state.sharesPerOwner")) - 1);

    /// @notice Structure in storage
    struct Slot {
        /// @custom:attribute The mapping from an owner to its share count
        mapping(address => uint256) value;
    }

    /// @notice Retrieve the share count for given owner
    /// @param _owner The address to get the balance of
    /// @return The amount of shares
    function get(address _owner) internal view returns (uint256) {
        bytes32 slot = SHARES_PER_OWNER_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        return r.value[_owner];
    }

    /// @notice Set the amount of shares for an owner
    /// @param _owner The owner of the shares to edit
    /// @param _newValue The new shares value for the owner
    function set(address _owner, uint256 _newValue) internal {
        bytes32 slot = SHARES_PER_OWNER_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        r.value[_owner] = _newValue;
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibErrors.sol";
import "../../libraries/LibUnstructuredStorage.sol";

/// @title Withdrawal Credentials Storage
/// @notice Utility to manage the Withdrawal Credentials in storage
library WithdrawalCredentials {
    /// @notice Storage slot of the Withdrawal Credentials
    bytes32 internal constant WITHDRAWAL_CREDENTIALS_SLOT =
        bytes32(uint256(keccak256("river.state.withdrawalCredentials")) - 1);

    /// @notice Retrieve the Withdrawal Credentials
    /// @return The Withdrawal Credentials
    function get() internal view returns (bytes32) {
        return LibUnstructuredStorage.getStorageBytes32(WITHDRAWAL_CREDENTIALS_SLOT);
    }

    /// @notice Sets the Withdrawal Credentials
    /// @param _newValue New Withdrawal Credentials
    function set(bytes32 _newValue) internal {
        if (_newValue == bytes32(0)) {
            revert LibErrors.InvalidArgument();
        }
        LibUnstructuredStorage.setStorageBytes32(WITHDRAWAL_CREDENTIALS_SLOT, _newValue);
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

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/// @title Approvals Per Owner Storage
/// @notice Utility to manage the Approvals Per Owner in storage
library ApprovalsPerOwner {
    /// @notice Storage slot of the Approvals Per Owner
    bytes32 internal constant APPROVALS_PER_OWNER_SLOT =
        bytes32(uint256(keccak256("river.state.approvalsPerOwner")) - 1);

    /// @notice The structure in storage
    struct Slot {
        /// @custom:attribute The mapping from an owner to an operator to the approval amount
        mapping(address => mapping(address => uint256)) value;
    }

    /// @notice Retrieve the approval for an owner to an operator
    /// @param _owner The account that gave the approval
    /// @param _operator The account receiving the approval
    /// @return The value of the approval
    function get(address _owner, address _operator) internal view returns (uint256) {
        bytes32 slot = APPROVALS_PER_OWNER_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        return r.value[_owner][_operator];
    }

    /// @notice Set the approval value for an owner to an operator
    /// @param _owner The account that gives the approval
    /// @param _operator The account receiving the approval
    /// @param _newValue The value of the approval
    function set(address _owner, address _operator, uint256 _newValue) internal {
        bytes32 slot = APPROVALS_PER_OWNER_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        r.value[_owner][_operator] = _newValue;
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