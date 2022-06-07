// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../../libs/LibRoles.sol";
import "../../libs/LibCalculator.sol";
import "../../interfaces/IOpiumProxyFactory.sol";
import "../../interfaces/ISyntheticAggregator.sol";
import "../../interfaces/IOracleAggregator.sol";
import "../../interfaces/ITokenSpender.sol";
import "../../interfaces/ICore.sol";

/**
    Error codes:
    - R1 = ERROR_REGISTRY_ONLY_PROTOCOL_ADDRESSES_SETTER_ROLE
    - R2 = ERROR_REGISTRY_ONLY_EXECUTION_RESERVE_CLAIMER_ADDRESS_SETTER_ROLE
    - R3 = ERROR_REGISTRY_ONLY_REDEMPTION_RESERVE_CLAIMER_ADDRESS_SETTER_ROLE
    - R4 = ERROR_REGISTRY_ONLY_EXECUTION_RESERVE_PART_SETTER_ROLE
    - R5 = ERROR_REGISTRY_ONLY_NO_DATA_CANCELLATION_PERIOD_SETTER_ROLE
    - R6 = ERROR_REGISTRY_ONLY_GUARDIAN_ROLE
    - R7 = ERROR_REGISTRY_ONLY_WHITELISTER_ROLE
    - R8 = ERROR_REGISTRY_ONLY_DERIVATIVE_AUTHOR_EXECUTION_FEE_CAP_SETTER_ROLE
    - R9 = ERROR_REGISTRY_ONLY_REDEMPTION_RESERVE_PART_SETTER_ROLE
    - R10 = ERROR_REGISTRY_ALREADY_PAUSED
    - R11 = ERROR_REGISTRY_NOT_PAUSED
    - R12 = ERROR_REGISTRY_NULL_ADDRESS
    - R13 = ERROR_REGISTRY_ONLY_PARTIAL_CREATE_PAUSE_ROLE
    - R14 = ERROR_REGISTRY_ONLY_PARTIAL_MINT_PAUSE_ROLE
    - R15 = ERROR_REGISTRY_ONLY_PARTIAL_REDEEM_PAUSE_ROLE
    - R16 = ERROR_REGISTRY_ONLY_PARTIAL_EXECUTE_PAUSE_ROLE
    - R17 = ERROR_REGISTRY_ONLY_PARTIAL_CANCEL_PAUSE_ROLE
    - R18 = ERROR_REGISTRY_ONLY_PARTIAL_CLAIM_RESERVE_PAUSE_ROLE
    - R19 = ERROR_REGISTRY_ONLY_PROTOCOL_UNPAUSER_ROLE
    - R20 = ERROR_REGISTRY_INVALID_VALUE
 */

contract Registry is AccessControlUpgradeable {
    // Setup
    event LogNoDataCancellationPeriodChanged(address indexed _setter, uint256 indexed _noDataCancellationPeriod);
    event LogWhitelistAccountAdded(address indexed _setter, address indexed _whitelisted);
    event LogWhitelistAccountRemoved(address indexed _setter, address indexed _unlisted);
    // Reserve
    event LogProtocolExecutionReserveClaimerChanged(
        address indexed _setter,
        address indexed _protocolExecutionReserveClaimer
    );
    event LogProtocolRedemptionReserveClaimerChanged(
        address indexed _setter,
        address indexed _protocolRedemptionReserveClaimer
    );
    event LogProtocolExecutionReservePartChanged(address indexed _setter, uint32 indexed _protocolExecutionReservePart);
    event LogDerivativeAuthorExecutionFeeCapChanged(
        address indexed _setter,
        uint32 indexed _derivativeAuthorExecutionFeeCap
    );
    event LogProtocolRedemptionReservePartChanged(
        address indexed _setter,
        uint32 indexed _protocolRedemptionReservePart
    );
    event LogDerivativeAuthorRedemptionReservePartChanged(
        address indexed _setter,
        uint32 indexed _derivativeAuthorRedemptionReservePart
    );
    // Emergency
    // emits the role to signal what type of pause has been committed, if any
    event LogProtocolPausableStateChanged(address indexed _setter, bool indexed _state, bytes32 indexed _role);

    RegistryEntities.ProtocolParametersArgs private protocolParametersArgs;
    RegistryEntities.ProtocolAddressesArgs private protocolAddressesArgs;
    RegistryEntities.ProtocolPausabilityArgs private protocolPausabilityArgs;
    mapping(address => bool) private coreSpenderWhitelist;

    // ***** SETUP *****

    /// @notice it ensures that the calling account has been granted the PROTOCOL_ADDRESSES_SETTER_ROLE
    /// @dev by default, it is granted to the `governor` account
    modifier onlyProtocolAdressesSetter() {
        require(hasRole(LibRoles.PROTOCOL_ADDRESSES_SETTER_ROLE, msg.sender), "R1");
        _;
    }

    /// @notice it ensures that the calling account has been granted the NO_DATA_CANCELLATION_PERIOD_SETTER_ROLE
    /// @dev by default, it is granted to the `governor` account
    modifier onlyNoDataCancellationPeriodSetter() {
        require(hasRole(LibRoles.NO_DATA_CANCELLATION_PERIOD_SETTER_ROLE, msg.sender), "R5");
        _;
    }

    /// @notice it ensures that the calling account has been granted the WHITELISTER_ROLE
    /// @dev by default, it is granted to the `governor` account
    modifier onlyWhitelister() {
        require(hasRole(LibRoles.WHITELISTER_ROLE, msg.sender), "R7");
        _;
    }

    // ***** RESERVE *****

    /// @notice it ensures that the calling account has been granted the EXECUTION_RESERVE_CLAIMER_ADDRESS_SETTER_ROLE
    /// @dev by default, it is granted to the `governor` account
    modifier onlyProtocolExecutionReserveClaimerAddressSetter() {
        require(hasRole(LibRoles.EXECUTION_RESERVE_CLAIMER_ADDRESS_SETTER_ROLE, msg.sender), "R2");
        _;
    }

    /// @notice it ensures that the calling account has been granted the REDEMPTION_RESERVE_CLAIMER_ADDRESS_SETTER_ROLE
    /// @dev by default, it is granted to the `governor` account
    modifier onlyProtocolRedemptionReserveClaimerAddressSetter() {
        require(hasRole(LibRoles.REDEMPTION_RESERVE_CLAIMER_ADDRESS_SETTER_ROLE, msg.sender), "R3");
        _;
    }

    /// @notice it ensures that the calling account has been granted the EXECUTION_RESERVE_PART_SETTER_ROLE
    /// @dev by default, it is granted to the `governor` account
    modifier onlyProtocolExecutionReservePartSetter() {
        require(hasRole(LibRoles.EXECUTION_RESERVE_PART_SETTER_ROLE, msg.sender), "R4");
        _;
    }

    /// @notice it ensures that the calling account has been granted the DERIVATIVE_AUTHOR_EXECUTION_FEE_CAP_SETTER_ROLE
    /// @dev by default, it is granted to the `governor` account
    modifier onlyDerivativeAuthorExecutionFeeCapSetter() {
        require(hasRole(LibRoles.DERIVATIVE_AUTHOR_EXECUTION_FEE_CAP_SETTER_ROLE, msg.sender), "R8");
        _;
    }

    /// @notice it ensures that the calling account has been granted the REDEMPTION_RESERVE_PART_SETTER_ROLE
    /// @dev by default, it is granted to the `governor` account
    modifier onlyProtocolRedemptionReservePartSetter() {
        require(hasRole(LibRoles.REDEMPTION_RESERVE_PART_SETTER_ROLE, msg.sender), "R9");
        _;
    }

    // ***** EMERGENCY *****

    /// @notice it ensures that the calling account has been granted the GUARDIAN_ROLE
    /// @dev by default, it is granted to the `governor` account
    modifier onlyGuardian() {
        require(hasRole(LibRoles.GUARDIAN_ROLE, msg.sender), "R6");
        _;
    }

    /// @notice it ensures that the calling account has been granted the PARTIAL_CREATE_PAUSE_ROLE
    /// @dev by default, it is granted to the `governor` account
    modifier onlyPartialCreatePauseSetter() {
        require(hasRole(LibRoles.PARTIAL_CREATE_PAUSE_ROLE, msg.sender), "R13");
        _;
    }

    /// @notice it ensures that the calling account has been granted the PARTIAL_MINT_PAUSE_ROLE
    /// @dev by default, it is granted to the `governor` account
    modifier onlyPartialMintPauseSetter() {
        require(hasRole(LibRoles.PARTIAL_MINT_PAUSE_ROLE, msg.sender), "R14");
        _;
    }

    /// @notice it ensures that the calling account has been granted the PARTIAL_REDEEM_PAUSE_ROLE
    /// @dev by default, it is granted to the `governor` account
    modifier onlyPartialRedeemPauseSetter() {
        require(hasRole(LibRoles.PARTIAL_REDEEM_PAUSE_ROLE, msg.sender), "R15");
        _;
    }

    /// @notice it ensures that the calling account has been granted the PARTIAL_EXECUTE_PAUSE_ROLE
    /// @dev by default, it is granted to the `governor` account
    modifier onlyPartialExecutePauseSetter() {
        require(hasRole(LibRoles.PARTIAL_EXECUTE_PAUSE_ROLE, msg.sender), "R16");
        _;
    }

    /// @notice it ensures that the calling account has been granted the PARTIAL_CANCEL_PAUSE_ROLE
    /// @dev by default, it is granted to the `governor` account
    modifier onlyPartialCancelPauseSetter() {
        require(hasRole(LibRoles.PARTIAL_CANCEL_PAUSE_ROLE, msg.sender), "R17");
        _;
    }

    /// @notice it ensures that the calling account has been granted the PARTIAL_CLAIM_RESERVE_PAUSE_ROLE
    /// @dev by default, it is granted to the `governor` account
    modifier onlyPartialClaimReservePauseSetter() {
        require(hasRole(LibRoles.PARTIAL_CLAIM_RESERVE_PAUSE_ROLE, msg.sender), "R18");
        _;
    }

    /// @notice it ensures that the calling account has been granted the PROTOCOL_UNPAUSER_ROLE
    /// @dev by default, it is granted to the `governor` account
    modifier onlyProtocolUnpauserSetter() {
        require(hasRole(LibRoles.PROTOCOL_UNPAUSER_ROLE, msg.sender), "R19");
        _;
    }

    // ****************** EXTERNAL FUNCTIONS ******************

    // ***** SETTERS *****

    /// @notice it is called only once upon deployment of the contract. It initializes the DEFAULT_ADMIN_ROLE with the given governor address.
    /// @notice it sets the default ProtocolParametersArgs protocol parameters
    /// @dev internally, it assigns all the setters roles to the DEFAULT_ADMIN_ROLE and it sets the initial protocol parameters
    /// @param _governor address of the governance account which will be assigned all the roles included in the LibRoles library and the OpenZeppelin AccessControl.DEFAULT_ADMIN_ROLE
    function initialize(address _governor) external initializer {
        __AccessControl_init();

        // Setup
        _setupRole(DEFAULT_ADMIN_ROLE, _governor);
        _setupRole(LibRoles.PROTOCOL_ADDRESSES_SETTER_ROLE, _governor);
        _setupRole(LibRoles.NO_DATA_CANCELLATION_PERIOD_SETTER_ROLE, _governor);
        _setupRole(LibRoles.WHITELISTER_ROLE, _governor);
        _setupRole(LibRoles.REGISTRY_MANAGER_ROLE, _governor);
        _setupRole(LibRoles.CORE_CONFIGURATION_UPDATER_ROLE, _governor);

        // Reserve
        _setupRole(LibRoles.EXECUTION_RESERVE_CLAIMER_ADDRESS_SETTER_ROLE, _governor);
        _setupRole(LibRoles.REDEMPTION_RESERVE_CLAIMER_ADDRESS_SETTER_ROLE, _governor);
        _setupRole(LibRoles.EXECUTION_RESERVE_PART_SETTER_ROLE, _governor);
        _setupRole(LibRoles.DERIVATIVE_AUTHOR_EXECUTION_FEE_CAP_SETTER_ROLE, _governor);
        _setupRole(LibRoles.REDEMPTION_RESERVE_PART_SETTER_ROLE, _governor);

        // Emergency
        _setupRole(LibRoles.GUARDIAN_ROLE, _governor);
        _setupRole(LibRoles.PARTIAL_CREATE_PAUSE_ROLE, _governor);
        _setupRole(LibRoles.PARTIAL_MINT_PAUSE_ROLE, _governor);
        _setupRole(LibRoles.PARTIAL_REDEEM_PAUSE_ROLE, _governor);
        _setupRole(LibRoles.PARTIAL_EXECUTE_PAUSE_ROLE, _governor);
        _setupRole(LibRoles.PARTIAL_CANCEL_PAUSE_ROLE, _governor);
        _setupRole(LibRoles.PARTIAL_CLAIM_RESERVE_PAUSE_ROLE, _governor);
        _setupRole(LibRoles.PROTOCOL_UNPAUSER_ROLE, _governor);

        // Default protocol parameters
        protocolParametersArgs.noDataCancellationPeriod = 2 weeks;
        protocolParametersArgs.derivativeAuthorExecutionFeeCap = 1000; // 10%
        protocolParametersArgs.derivativeAuthorRedemptionReservePart = 10; // 0.1%
        protocolParametersArgs.protocolExecutionReservePart = 1000; // 10%
        protocolParametersArgs.protocolRedemptionReservePart = 1000; // 10%
    }

    // ** ROLE-RESTRICTED FUNCTIONS **

    // * Setup *

    /// @notice It allows the PROTOCOL_ADDRESSES_SETTER_ROLE role to set the addresses of Opium Protocol's contracts
    /// @dev It must be called as part of the protocol's deployment setup after the core addresses have been deployed
    /// @dev the contracts' addresses are set using their respective interfaces
    /// @param _opiumProxyFactory address of Opium.OpiumProxyFactory
    /// @param _core address of Opium.Core
    /// @param _oracleAggregator address of Opium.OracleAggregator
    /// @param _syntheticAggregator address of Opium.SyntheticAggregator
    /// @param _tokenSpender address of Opium.TokenSpender
    function setProtocolAddresses(
        address _opiumProxyFactory,
        address _core,
        address _oracleAggregator,
        address _syntheticAggregator,
        address _tokenSpender
    ) external onlyProtocolAdressesSetter {
        require(
            _opiumProxyFactory != address(0) &&
                _core != address(0) &&
                _oracleAggregator != address(0) &&
                _syntheticAggregator != address(0) &&
                _tokenSpender != address(0),
            "R12"
        );
        protocolAddressesArgs.opiumProxyFactory = _opiumProxyFactory;
        protocolAddressesArgs.core = _core;
        protocolAddressesArgs.oracleAggregator = _oracleAggregator;
        protocolAddressesArgs.syntheticAggregator = _syntheticAggregator;
        protocolAddressesArgs.tokenSpender = _tokenSpender;
    }

    /// @notice It allows the NO_DATA_CANCELLATION_PERIOD_SETTER_ROLE role to change the noDataCancellationPeriod (the timeframe after which a derivative can be cancelled if the oracle has not provided any data)
    function setNoDataCancellationPeriod(uint32 _noDataCancellationPeriod) external onlyNoDataCancellationPeriodSetter {
        protocolParametersArgs.noDataCancellationPeriod = _noDataCancellationPeriod;
        emit LogNoDataCancellationPeriodChanged(msg.sender, _noDataCancellationPeriod);
    }

    /// @notice It allows the WHITELISTER_ROLE to add an address to the whitelist
    function addToWhitelist(address _whitelisted) external onlyWhitelister {
        coreSpenderWhitelist[_whitelisted] = true;
        emit LogWhitelistAccountAdded(msg.sender, _whitelisted);
    }

    /// @notice It allows the WHITELISTER_ROLE to remove an address from the whitelist
    function removeFromWhitelist(address _whitelisted) external onlyWhitelister {
        coreSpenderWhitelist[_whitelisted] = false;
        emit LogWhitelistAccountRemoved(msg.sender, _whitelisted);
    }

    // * Reserve *

    /// @notice It allows the EXECUTION_RESERVE_CLAIMER_ADDRESS_SETTER_ROLE role to change the address of the recipient of execution protocol reserves
    /// @dev It must be called as part of the protocol's deployment setup after the core addresses have been deployed
    /// @dev it must be a non-null address
    /// @param _protocolExecutionReserveClaimer address that will replace the current `protocolExecutionReserveClaimer`
    function setProtocolExecutionReserveClaimer(address _protocolExecutionReserveClaimer)
        external
        onlyProtocolExecutionReserveClaimerAddressSetter
    {
        require(_protocolExecutionReserveClaimer != address(0), "R12");
        protocolAddressesArgs.protocolExecutionReserveClaimer = _protocolExecutionReserveClaimer;
        emit LogProtocolExecutionReserveClaimerChanged(msg.sender, _protocolExecutionReserveClaimer);
    }

    /// @notice It allows the REDEMPTION_RESERVE_CLAIMER_ADDRESS_SETTER_ROLE role to change the address of the recipient of redemption protocol reserves
    /// @dev It must be called as part of the protocol's deployment setup after the core addresses have been deployed
    /// @dev it must be a non-null address
    /// @param _protocolRedemptionReserveClaimer address that will replace the current `protocolAddressesArgs.protocolRedemptionReserveClaimer`
    function setProtocolRedemptionReserveClaimer(address _protocolRedemptionReserveClaimer)
        external
        onlyProtocolRedemptionReserveClaimerAddressSetter
    {
        require(_protocolRedemptionReserveClaimer != address(0), "R12");
        protocolAddressesArgs.protocolRedemptionReserveClaimer = _protocolRedemptionReserveClaimer;
        emit LogProtocolRedemptionReserveClaimerChanged(msg.sender, _protocolRedemptionReserveClaimer);
    }

    /// @notice It allows the EXECUTION_RESERVE_PART_SETTER_ROLE role to change part of derivative author reserves originated from derivative executions go to the protocol reserves
    /// @param _protocolExecutionReservePart must be less than 100%
    function setProtocolExecutionReservePart(uint32 _protocolExecutionReservePart)
        external
        onlyProtocolExecutionReservePartSetter
    {
        require(_protocolExecutionReservePart < LibCalculator.PERCENTAGE_BASE, "R20");
        protocolParametersArgs.protocolExecutionReservePart = _protocolExecutionReservePart;
        emit LogProtocolExecutionReservePartChanged(msg.sender, _protocolExecutionReservePart);
    }

    /// @notice It allows the DERIVATIVE_AUTHOR_EXECUTION_FEE_CAP_SETTER_ROLE role to change max fee that derivative author can set
    /// @param _derivativeAuthorExecutionFeeCap must be less than 100%
    function setDerivativeAuthorExecutionFeeCap(uint32 _derivativeAuthorExecutionFeeCap)
        external
        onlyDerivativeAuthorExecutionFeeCapSetter
    {
        require(_derivativeAuthorExecutionFeeCap < LibCalculator.PERCENTAGE_BASE, "R20");
        protocolParametersArgs.derivativeAuthorExecutionFeeCap = _derivativeAuthorExecutionFeeCap;
        emit LogDerivativeAuthorExecutionFeeCapChanged(msg.sender, _derivativeAuthorExecutionFeeCap);
    }

    /// @notice It allows the REDEMPTION_RESERVE_PART_SETTER_ROLE role to change part of derivative author reserves originated from redemption of market neutral positions go to the protocol reserves
    /// @param _protocolRedemptionReservePart must be less than 100%
    function setProtocolRedemptionReservePart(uint32 _protocolRedemptionReservePart)
        external
        onlyProtocolRedemptionReservePartSetter
    {
        require(_protocolRedemptionReservePart < LibCalculator.PERCENTAGE_BASE, "R20");
        protocolParametersArgs.protocolRedemptionReservePart = _protocolRedemptionReservePart;
        emit LogProtocolRedemptionReservePartChanged(msg.sender, _protocolRedemptionReservePart);
    }

    /// @notice It allows the REDEMPTION_RESERVE_PART_SETTER_ROLE role to change the fixed part (percentage) that the derivative author receives for each redemption of market neutral positions
    /// @param _derivativeAuthorRedemptionReservePart must be less than 1%
    function setDerivativeAuthorRedemptionReservePart(uint32 _derivativeAuthorRedemptionReservePart)
        external
        onlyProtocolRedemptionReservePartSetter
    {
        require(_derivativeAuthorRedemptionReservePart <= LibCalculator.MAX_REDEMPTION_PART, "R20");
        protocolParametersArgs.derivativeAuthorRedemptionReservePart = _derivativeAuthorRedemptionReservePart;
        emit LogDerivativeAuthorRedemptionReservePartChanged(msg.sender, _derivativeAuthorRedemptionReservePart);
    }

    // * Emergency *

    /// @notice It allows the GUARDIAN role to pause the entire Opium Protocol
    /// @dev it fails if the entire protocol is already paused
    function pause() external onlyGuardian {
        require(!protocolPausabilityArgs.protocolGlobal, "R10");
        protocolPausabilityArgs.protocolGlobal = true;
        emit LogProtocolPausableStateChanged(msg.sender, true, LibRoles.GUARDIAN_ROLE);
    }

    /// @notice It allows the PARTIAL_CREATE_PAUSE_ROLE role to pause the creation of positions
    /// @dev it fails if the creation of positions is paused
    function pauseProtocolPositionCreation() external onlyPartialCreatePauseSetter {
        require(!protocolPausabilityArgs.protocolPositionCreation, "R10");
        protocolPausabilityArgs.protocolPositionCreation = true;
        emit LogProtocolPausableStateChanged(msg.sender, true, LibRoles.PARTIAL_CREATE_PAUSE_ROLE);
    }

    /// @notice It allows the PARTIAL_MINT_PAUSE_ROLE role to pause the minting of positions
    /// @dev it fails if the minting of positions is paused
    function pauseProtocolPositionMinting() external onlyPartialMintPauseSetter {
        require(!protocolPausabilityArgs.protocolPositionMinting, "R10");
        protocolPausabilityArgs.protocolPositionMinting = true;
        emit LogProtocolPausableStateChanged(msg.sender, true, LibRoles.PARTIAL_MINT_PAUSE_ROLE);
    }

    /// @notice It allows the PARTIAL_REDEEM_PAUSE_ROLE role to pause the redemption of positions
    /// @dev it fails if the redemption of positions is paused
    function pauseProtocolPositionRedemption() external onlyPartialRedeemPauseSetter {
        require(!protocolPausabilityArgs.protocolPositionRedemption, "R10");
        protocolPausabilityArgs.protocolPositionRedemption = true;
        emit LogProtocolPausableStateChanged(msg.sender, true, LibRoles.PARTIAL_REDEEM_PAUSE_ROLE);
    }

    /// @notice It allows the PARTIAL_EXECUTE_PAUSE_ROLE role to pause the execution of positions
    /// @dev it fails if the execution of positions is paused
    function pauseProtocolPositionExecution() external onlyPartialExecutePauseSetter {
        require(!protocolPausabilityArgs.protocolPositionExecution, "R10");
        protocolPausabilityArgs.protocolPositionExecution = true;
        emit LogProtocolPausableStateChanged(msg.sender, true, LibRoles.PARTIAL_EXECUTE_PAUSE_ROLE);
    }

    /// @notice It allows the PARTIAL_CANCEL_PAUSE_ROLE role to pause the cancellation of positions
    /// @dev it fails if the cancellation of positions is paused
    function pauseProtocolPositionCancellation() external onlyPartialCancelPauseSetter {
        require(!protocolPausabilityArgs.protocolPositionCancellation, "R10");
        protocolPausabilityArgs.protocolPositionCancellation = true;
        emit LogProtocolPausableStateChanged(msg.sender, true, LibRoles.PARTIAL_CANCEL_PAUSE_ROLE);
    }

    /// @notice It allows the PARTIAL_CLAIM_RESERVE_PAUSE_ROLE role to pause the reserves claims
    /// @dev it fails if the reserves claims are paused
    function pauseProtocolReserveClaim() external onlyPartialClaimReservePauseSetter {
        require(!protocolPausabilityArgs.protocolReserveClaim, "R10");
        protocolPausabilityArgs.protocolReserveClaim = true;
        emit LogProtocolPausableStateChanged(msg.sender, true, LibRoles.PARTIAL_CLAIM_RESERVE_PAUSE_ROLE);
    }

    /// @notice It allows the PROTOCOL_UNPAUSER_ROLE to unpause the Opium Protocol
    function unpause() external onlyProtocolUnpauserSetter {
        delete protocolPausabilityArgs;
        emit LogProtocolPausableStateChanged(msg.sender, false, LibRoles.PROTOCOL_UNPAUSER_ROLE);
    }

    // ***** GETTERS *****

    ///@return RegistryEntities.getProtocolParameters struct that packs the protocol lifecycle parameters {see RegistryEntities comments}
    function getProtocolParameters() external view returns (RegistryEntities.ProtocolParametersArgs memory) {
        return protocolParametersArgs;
    }

    ///@return RegistryEntities.ProtocolAddressesArgs struct that packs all the interfaces of the Opium Protocol
    function getProtocolAddresses() external view returns (RegistryEntities.ProtocolAddressesArgs memory) {
        return protocolAddressesArgs;
    }

    /// @notice Returns true if msg.sender has been assigned the REGISTRY_MANAGER_ROLE role
    /// @dev it is meant to be consumed by the RegistryManager module
    /// @param _address address to be checked
    function isRegistryManager(address _address) external view returns (bool) {
        return hasRole(LibRoles.REGISTRY_MANAGER_ROLE, _address);
    }

    /// @notice Returns true if msg.sender has been assigned the CORE_CONFIGURATION_UPDATER_ROLE role
    /// @dev it is meant to be consumed by the RegistryManager module
    /// @param _address address to be checked
    function isCoreConfigurationUpdater(address _address) external view returns (bool) {
        return hasRole(LibRoles.CORE_CONFIGURATION_UPDATER_ROLE, _address);
    }

    /// @return `Opium.Core`
    function getCore() external view returns (address) {
        return address(protocolAddressesArgs.core);
    }

    /// @notice It returns whether a given address is allowed to manage Opium.Core ERC20 balances
    function isCoreSpenderWhitelisted(address _address) external view returns (bool) {
        return coreSpenderWhitelist[_address];
    }

    /// @notice It returns true if the protocol is globally paused
    function isProtocolPaused() external view returns (bool) {
        return protocolPausabilityArgs.protocolGlobal;
    }

    /// @notice It returns whether Core.create() is currently paused
    /// @return true if protocol is globally paused or if protocolPositionCreation is paused
    function isProtocolPositionCreationPaused() external view returns (bool) {
        return protocolPausabilityArgs.protocolGlobal || protocolPausabilityArgs.protocolPositionCreation;
    }

    /// @notice It returns whether Core.mint() is currently paused
    /// @return true if protocol is globally paused or if protocolPositionMinting is paused
    function isProtocolPositionMintingPaused() external view returns (bool) {
        return protocolPausabilityArgs.protocolGlobal || protocolPausabilityArgs.protocolPositionMinting;
    }

    /// @notice It returns whether Core.redeem() is currently paused
    /// @return true if protocol is globally paused or if protocolPositionRedemption is paused
    function isProtocolPositionRedemptionPaused() external view returns (bool) {
        return protocolPausabilityArgs.protocolGlobal || protocolPausabilityArgs.protocolPositionRedemption;
    }

    /// @notice It returns whether Core.execute() is currently paused
    /// @return true if protocol is globally paused or if protocolPositionExecution is paused
    function isProtocolPositionExecutionPaused() external view returns (bool) {
        return protocolPausabilityArgs.protocolGlobal || protocolPausabilityArgs.protocolPositionExecution;
    }

    /// @notice It returns whether Core.cancel() is currently paused
    /// @return true if protocol is globally paused or if protocolPositionCancellation is paused
    function isProtocolPositionCancellationPaused() external view returns (bool) {
        return protocolPausabilityArgs.protocolGlobal || protocolPausabilityArgs.protocolPositionCancellation;
    }

    /// @notice It returns whether Core.execute() is currently paused
    /// @return true if protocol is globally paused or if protocolReserveClaim is paused
    function isProtocolReserveClaimPaused() external view returns (bool) {
        return protocolPausabilityArgs.protocolGlobal || protocolPausabilityArgs.protocolReserveClaim;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

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
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
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
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;

library LibRoles {
    // ***** SETUP *****

    /// @notice Role responsible for updating the Opium Protocol core contracts' addresses encoded in the RegistryEntities.ProtocolAddressesArgs struct
    /// @dev { See RegistryEntities.sol for a detailed description of the struct }
    bytes32 internal constant PROTOCOL_ADDRESSES_SETTER_ROLE = keccak256("RL1");

    /// @notice Role responsible for updating the RegistryEntities.ProtocolParametersArgs.noDataCancellationPeriod
    /// @dev { See RegistryEntities.sol for a detailed description of the ProtocolParametersArgs parameters }
    bytes32 internal constant NO_DATA_CANCELLATION_PERIOD_SETTER_ROLE = keccak256("RL5");

    /// @notice Role responsible for managing (adding and removing accounts) the whitelist
    bytes32 internal constant WHITELISTER_ROLE = keccak256("RL7");

    /// @notice Role responsible for updating the Registry address itself stored in the Opium Protocol core contracts that consume the Registry
    /// @dev It is the only role whose associated setter does not reside in the Registry itself but in a module inherited by its consumer contracts.
    /// @dev The registry's sole responsibility is to keep track of the accounts that have been assigned to the REGISTRY_MANAGER_ROLE role
    /// @dev { See RegistryManager.sol for further details }
    bytes32 internal constant REGISTRY_MANAGER_ROLE = keccak256("RL10");

    /// @notice Role responsible for updating (applying) new core configuration if it was changed in the registry
    bytes32 internal constant CORE_CONFIGURATION_UPDATER_ROLE = keccak256("RL18");

    // ***** RESERVE *****

    /// @notice Role responsible for updating the reserve recipient's address of the profitable execution of derivatives positions
    bytes32 internal constant EXECUTION_RESERVE_CLAIMER_ADDRESS_SETTER_ROLE = keccak256("RL2");

    /// @notice Role responsible for updating the reserve recipient's address of the redemption of market neutral positions
    bytes32 internal constant REDEMPTION_RESERVE_CLAIMER_ADDRESS_SETTER_ROLE = keccak256("RL3");

    /// @notice Role responsible for updating the fixed part (percentage) of the derivative author fees that goes to the protocol execution reserve
    bytes32 internal constant EXECUTION_RESERVE_PART_SETTER_ROLE = keccak256("RL4");

    /// @notice Role responsible for updating the maximum fee that a derivative author can set as a commission originated from the profitable execution of derivatives positions
    bytes32 internal constant DERIVATIVE_AUTHOR_EXECUTION_FEE_CAP_SETTER_ROLE = keccak256("RL8");

    /// @notice Role responsible for updating the fixed part (percentage) of the initial margin that will be deducted to the reserves during redemption of market neutral positions
    /// @notice Also sets fixed part (percentage) of this redemption reserves that goes to the protocol redemption reserve
    bytes32 internal constant REDEMPTION_RESERVE_PART_SETTER_ROLE = keccak256("RL9");

    // ***** EMERGENCY *****

    /// @notice Role responsible for globally pausing the protocol
    bytes32 internal constant GUARDIAN_ROLE = keccak256("RL6");

    /// @notice Role responsible for pausing Core.create
    bytes32 internal constant PARTIAL_CREATE_PAUSE_ROLE = keccak256("RL11");

    /// @notice Role responsible for pausing Core.mint
    bytes32 internal constant PARTIAL_MINT_PAUSE_ROLE = keccak256("RL12");

    /// @notice Role responsible for pausing Core.redeem
    bytes32 internal constant PARTIAL_REDEEM_PAUSE_ROLE = keccak256("RL13");

    /// @notice Role responsible for pausing Core.execute
    bytes32 internal constant PARTIAL_EXECUTE_PAUSE_ROLE = keccak256("RL14");

    /// @notice Role responsible for pausing Core.cancel
    bytes32 internal constant PARTIAL_CANCEL_PAUSE_ROLE = keccak256("RL15");

    /// @notice Role responsible for pausing Core.claimReserve
    bytes32 internal constant PARTIAL_CLAIM_RESERVE_PAUSE_ROLE = keccak256("RL16");

    /// @notice Role responsible for globally unpausing the protocol
    bytes32 internal constant PROTOCOL_UNPAUSER_ROLE = keccak256("RL17");
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;

library LibCalculator {
    uint256 internal constant PERCENTAGE_BASE = 10000; // Represents 100%
    uint256 internal constant MAX_REDEMPTION_PART = 100; // Represents 1%

    function mulWithPrecisionFactor(uint256 _x, uint256 _y) internal pure returns (uint256) {
        return (_x * _y) / 1e18;
    }

    function modWithPrecisionFactor(uint256 _x) internal pure returns (uint256) {
        return _x % 1e18;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;
import "../libs/LibDerivative.sol";

interface IOpiumProxyFactory {
    function getImplementationAddress() external view returns (address);

    function initialize(address _registry) external;

    function create(
        address _buyer,
        address _seller,
        uint256 _amount,
        bytes32 _derivativeHash,
        LibDerivative.Derivative calldata _derivative
    ) external;

    function mintPair(
        address _buyer,
        address _seller,
        address _longPositionAddress,
        address _shortPositionAddress,
        uint256 _amount
    ) external;

    function burn(
        address _positionOwner,
        address _positionAddress,
        uint256 _amount
    ) external;

    function burnPair(
        address _positionOwner,
        address _longPositionAddress,
        address _shortPositionAddress,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;
import "../libs/LibDerivative.sol";

interface ISyntheticAggregator {
    struct SyntheticCache {
        uint256 buyerMargin;
        uint256 sellerMargin;
        uint256 authorCommission;
        address authorAddress;
        bool init;
    }

    function initialize(address _registry) external;

    function getOrCacheSyntheticCache(bytes32 _derivativeHash, LibDerivative.Derivative calldata _derivative)
        external
        returns (SyntheticCache memory);

    function getOrCacheMargin(bytes32 _derivativeHash, LibDerivative.Derivative calldata _derivative)
        external
        returns (uint256 buyerMargin, uint256 sellerMargin);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;

interface IOracleAggregator {
    function __callback(uint256 timestamp, uint256 data) external;

    function getData(address oracleId, uint256 timestamp) external view returns (uint256 dataResult);

    function hasData(address oracleId, uint256 timestamp) external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ITokenSpender {
    function claimTokens(
        IERC20Upgradeable _token,
        address _from,
        address _to,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;

import "../core/registry/RegistryEntities.sol";
import "../libs/LibDerivative.sol";

interface ICore {
    function initialize(address _governor) external;

    function getProtocolParametersArgs() external view returns (RegistryEntities.ProtocolParametersArgs memory);

    function getProtocolAddresses() external view returns (RegistryEntities.ProtocolAddressesArgs memory);

    function getReservesVaultBalance(address _reseveRecipient, address _token) external view returns (uint256);

    function getDerivativePayouts(bytes32 _derivativeHash) external view returns (uint256[2] memory);

    function getP2pDerivativeVaultFunds(bytes32 _derivativeHash) external view returns (uint256);

    function isDerivativeCancelled(bytes32 _derivativeHash) external view returns (bool);

    function updateProtocolParametersArgs() external;

    function updateProtocolAddresses() external;

    function claimReserves(address _tokenAddress) external;

    function claimReserves(address _tokenAddress, uint256 _amount) external;

    function create(
        LibDerivative.Derivative calldata _derivative,
        uint256 _amount,
        address[2] calldata _positionsOwners
    ) external;

    function createAndMint(
        LibDerivative.Derivative calldata _derivative,
        uint256 _amount,
        address[2] calldata _positionsOwners,
        string calldata _derivativeAuthorCustomName
    ) external;

    function mint(
        uint256 _amount,
        address[2] calldata _positionsAddresses,
        address[2] calldata _positionsOwners
    ) external;

    function execute(address _positionAddress, uint256 _amount) external;

    function execute(
        address _positionOwner,
        address _positionAddress,
        uint256 _amount
    ) external;

    function execute(address[] calldata _positionsAddresses, uint256[] calldata _amounts) external;

    function execute(
        address _positionsOwner,
        address[] calldata _positionsAddresses,
        uint256[] calldata _amounts
    ) external;

    function redeem(address[2] calldata _positionsAddresses, uint256 _amount) external;

    function redeem(address[2][] calldata _positionsAddresses, uint256[] calldata _amounts) external;

    function cancel(address _positionAddress, uint256 _amount) external;

    function cancel(address[] calldata _positionsAddresses, uint256[] calldata _amounts) external;
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
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
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
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;

/// @title Opium.Lib.LibDerivative contract should be inherited by contracts that use Derivative structure and calculate derivativeHash
library LibDerivative {
    enum PositionType {
        SHORT,
        LONG
    }

    // Opium derivative structure (ticker) definition
    struct Derivative {
        // Margin parameter for syntheticId
        uint256 margin;
        // Maturity of derivative
        uint256 endTime;
        // Additional parameters for syntheticId
        uint256[] params;
        // oracleId of derivative
        address oracleId;
        // Margin token address of derivative
        address token;
        // syntheticId of derivative
        address syntheticId;
    }

    /// @notice Calculates hash of provided Derivative
    /// @param _derivative Derivative Instance of derivative to hash
    /// @return derivativeHash bytes32 Derivative hash
    function getDerivativeHash(Derivative memory _derivative) internal pure returns (bytes32 derivativeHash) {
        derivativeHash = keccak256(
            abi.encodePacked(
                _derivative.margin,
                _derivative.endTime,
                _derivative.params,
                _derivative.oracleId,
                _derivative.token,
                _derivative.syntheticId
            )
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;

library RegistryEntities {
    struct ProtocolParametersArgs {
        // Period of time after which ticker could be canceled if no data was provided to the `oracleId`
        uint32 noDataCancellationPeriod;
        // Max fee that derivative author can set
        // it works as an upper bound for when the derivative authors set their synthetic's fee
        uint32 derivativeAuthorExecutionFeeCap;
        // Fixed part (percentage) that the derivative author receives for each redemption of market neutral positions
        // It is not set by the derivative authors themselves
        uint32 derivativeAuthorRedemptionReservePart;
        // Represents which part of derivative author reserves originated from derivative executions go to the protocol reserves
        uint32 protocolExecutionReservePart;
        // Represents which part of derivative author reserves originated from redemption of market neutral positions go to the protocol reserves
        uint32 protocolRedemptionReservePart;
        /// Initially uninitialized variables to allow some flexibility in case of future changes and upgradeability
        uint32 __gapOne;
        uint32 __gapTwo;
        uint32 __gapThree;
    }

    struct ProtocolAddressesArgs {
        // Address of Opium.Core contract
        address core;
        // Address of Opium.OpiumProxyFactory contract
        address opiumProxyFactory;
        // Address of Opium.OracleAggregator contract
        address oracleAggregator;
        // Address of Opium.SyntheticAggregator contract
        address syntheticAggregator;
        // Address of Opium.TokenSpender contract
        address tokenSpender;
        // Address of the recipient of execution protocol reserves
        address protocolExecutionReserveClaimer;
        // Address of the recipient of redemption protocol reserves
        address protocolRedemptionReserveClaimer;
        /// Initially uninitialized variables to allow some flexibility in case of future changes and upgradeability
        uint32 __gapOne;
        uint32 __gapTwo;
    }

    struct ProtocolPausabilityArgs {
        // if true, all the protocol's entry-points are paused
        bool protocolGlobal;
        // if true, no new positions can be created
        bool protocolPositionCreation;
        // if true, no new positions can be minted
        bool protocolPositionMinting;
        // if true, no new positions can be redeemed
        bool protocolPositionRedemption;
        // if true, no new positions can be executed
        bool protocolPositionExecution;
        // if true, no new positions can be cancelled
        bool protocolPositionCancellation;
        // if true, no reserves can be claimed
        bool protocolReserveClaim;
        /// Initially uninitialized variables to allow some flexibility in case of future changes and upgradeability
        bool __gapOne;
        bool __gapTwo;
        bool __gapThree;
        bool __gapFour;
    }
}