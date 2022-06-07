// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./registry/RegistryEntities.sol";
import "./base/RegistryManager.sol";
import "../libs/LibDerivative.sol";
import "../libs/LibPosition.sol";
import "../libs/LibCalculator.sol";
import "../interfaces/IOpiumProxyFactory.sol";
import "../interfaces/ISyntheticAggregator.sol";
import "../interfaces/IOracleAggregator.sol";
import "../interfaces/ITokenSpender.sol";
import "../interfaces/IRegistry.sol";
import "../interfaces/IOpiumPositionToken.sol";
import "../interfaces/IDerivativeLogic.sol";

/**
    Error codes:
    - C1 = ERROR_CORE_POSITION_ADDRESSES_AND_AMOUNTS_DO_NOT_MATCH
    - C2 = ERROR_CORE_WRONG_HASH
    - C3 = ERROR_CORE_WRONG_POSITION_TYPE
    - C4 = ERROR_CORE_NOT_ENOUGH_POSITIONS
    - C5 = ERROR_CORE_WRONG_MOD
    - C6 = ERROR_CORE_CANT_CANCEL_DUMMY_ORACLE_ID
    - C7 = ERROR_CORE_TICKER_WAS_CANCELLED
    - C8 = ERROR_CORE_SYNTHETIC_VALIDATION_ERROR
    - C9 = ERROR_CORE_INSUFFICIENT_P2P_BALANCE
    - C10 = ERROR_CORE_EXECUTION_BEFORE_MATURITY_NOT_ALLOWED
    - C11 = ERROR_CORE_SYNTHETIC_EXECUTION_WAS_NOT_ALLOWED
    - C12 = ERROR_CORE_NOT_ENOUGH_TOKEN_ALLOWANCE
    - C13 = ERROR_CORE_CANCELLATION_IS_NOT_ALLOWED
    - C14 = ERROR_CORE_NOT_OPIUM_FACTORY_POSITIONS
    - C15 = ERROR_CORE_RESERVE_AMOUNT_GREATER_THAN_BALANCE
    - C16 = ERROR_CORE_NO_DERIVATIVE_CREATION_IN_THE_PAST
    - C17 = ERROR_CORE_PROTOCOL_POSITION_CREATION_PAUSED
    - C18 = ERROR_CORE_PROTOCOL_POSITION_MINT_PAUSED
    - C19 = ERROR_CORE_PROTOCOL_POSITION_REDEMPTION_PAUSED
    - C20 = ERROR_CORE_PROTOCOL_POSITION_EXECUTION_PAUSED
    - C21 = ERROR_CORE_PROTOCOL_POSITION_CANCELLATION_PAUSED
    - C22 = ERROR_CORE_PROTOCOL_RESERVE_CLAIM_PAUSED
    - C23 = ERROR_CORE_MISMATCHING_DERIVATIVES
 */

/// @title Opium.Core contract creates positions, holds and distributes margin at the maturity
contract Core is ReentrancyGuardUpgradeable, RegistryManager {
    using LibDerivative for LibDerivative.Derivative;
    using LibCalculator for uint256;
    using LibPosition for bytes32;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Emitted when Core creates a new LONG/SHORT position pair
    event LogCreated(address indexed _buyer, address indexed _seller, bytes32 indexed _derivativeHash, uint256 _amount);
    // Emitted when Core mints an amount of LONG/SHORT positions
    event LogMinted(address indexed _buyer, address indexed _seller, bytes32 indexed _derivativeHash, uint256 _amount);
    // Emitted when Core executes positions
    event LogExecuted(address indexed _positionsOwner, address indexed _positionAddress, uint256 _amount);
    // Emitted when Core cancels ticker for the first time
    event LogDerivativeHashCancelled(address indexed _positionOwner, bytes32 indexed _derivativeHash);
    // Emitted when Core cancels a position of a previously cancelled Derivative.derivativeHash
    event LogCancelled(address indexed _positionOwner, bytes32 indexed _derivativeHash, uint256 _amount);
    // Emitted when Core redeems an amount of market neutral positions
    event LogRedeemed(address indexed _positionOwner, bytes32 indexed _derivativeHash, uint256 _amount);

    RegistryEntities.ProtocolParametersArgs private protocolParametersArgs;
    RegistryEntities.ProtocolAddressesArgs private protocolAddressesArgs;

    // Key-value entity that maps a derivativeHash representing an existing derivative to its available balance (i.e: the amount of collateral that has not been claimed yet)
    mapping(bytes32 => uint256) private p2pVaults;

    // Key-value entity that maps a derivativeHash representing an existing derivative to a boolean representing whether a given derivative has been cancelled
    mapping(bytes32 => bool) private cancelledDerivatives;

    /// Key-value entity that maps a derivativeHash representing an existing derivative to its respective buyer's and seller's payouts.
    /// Both the buyer's and seller's are cached when a derivative's position is successfully executed for the first time
    /// derivativePayouts[derivativeHash][0] => buyer's payout
    /// derivativePayouts[derivativeHash][1] => seller's payout
    mapping(bytes32 => uint256[2]) private derivativePayouts;

    /// Reseves vault
    /// Key-value entity that maps an address representing a reserve recipient to a token address and the balance associated to the token address. It keeps tracks of the balances of reserve recipients (i.e: derivative authors)
    mapping(address => mapping(address => uint256)) private reservesVault;

    /// @notice It is called only once upon deployment of the contract. It sets the current Opium.Registry address and assigns the current protocol parameters stored in the Opium.Registry to the Core.protocolParametersArgs private variable {see RegistryEntities.sol for a description of the ProtocolParametersArgs struct}
    function initialize(address _registry) external initializer {
        __RegistryManager__init(_registry);
        __ReentrancyGuard_init();
        protocolParametersArgs = IRegistry(_registry).getProtocolParameters();
    }

    // ****************** EXTERNAL FUNCTIONS ******************

    // ***** GETTERS *****

    /// @notice It returns Opium.Core's internal state of the protocol parameters fetched from the Opium.Registry
    /// @dev {see RegistryEntities.sol for a description of the ProtocolParametersArgs struct}
    /// @return ProtocolParametersArgs struct including the protocol's main parameters
    function getProtocolParametersArgs() external view returns (RegistryEntities.ProtocolParametersArgs memory) {
        return protocolParametersArgs;
    }

    /// @notice It returns Opium.Core's internal state of the protocol contracts' and recipients' addresses fetched from the Opium.Registry
    /// @dev {see RegistryEntities.sol for a description of the protocolAddressesArgs struct}
    /// @return ProtocolAddressesArgs struct including the protocol's main addresses - contracts and reseves recipients
    function getProtocolAddresses() external view returns (RegistryEntities.ProtocolAddressesArgs memory) {
        return protocolAddressesArgs;
    }

    /// @notice It returns the accrued reseves of a given address denominated in a specified token
    /// @param _reseveRecipient address of the reseve recipient
    /// @param _token address of a token used as a reseve compensation
    /// @return uint256 amount of the accrued reseves denominated in the provided token
    function getReservesVaultBalance(address _reseveRecipient, address _token) external view returns (uint256) {
        return reservesVault[_reseveRecipient][_token];
    }

    /// @notice It queries the buyer's and seller's payouts for a given derivative
    /// @notice if it returns [0, 0] then the derivative has not been executed yet
    /// @param _derivativeHash bytes32 unique derivative identifier
    /// @return uint256[2] tuple containing LONG and SHORT payouts
    function getDerivativePayouts(bytes32 _derivativeHash) external view returns (uint256[2] memory) {
        return derivativePayouts[_derivativeHash];
    }

    /// @notice It queries the amount of funds allocated for a given derivative
    /// @param _derivativeHash bytes32 unique derivative identifier
    /// @return uint256 representing the remaining derivative's funds
    function getP2pDerivativeVaultFunds(bytes32 _derivativeHash) external view returns (uint256) {
        return p2pVaults[_derivativeHash];
    }

    /// @notice It checks whether a given derivative has been cancelled
    /// @param _derivativeHash bytes32 unique derivative identifier
    /// @return bool true if derivative has been cancelled, false if derivative has not been cancelled
    function isDerivativeCancelled(bytes32 _derivativeHash) external view returns (bool) {
        return cancelledDerivatives[_derivativeHash];
    }

    // ***** SETTERS *****

    /// @notice It allows to update the Opium Protocol parameters according to the current state of the Opium.Registry
    /// @dev {see RegistryEntities.sol for a description of the ProtocolParametersArgs struct}
    /// @dev should be called immediately after the deployment of the contract
    /// @dev only accounts who have been assigned the CORE_CONFIGURATION_UPDATER_ROLE { See LibRoles.sol } should be able to call the function
    function updateProtocolParametersArgs() external onlyCoreConfigurationUpdater {
        protocolParametersArgs = registry.getProtocolParameters();
    }

    /// @notice Allows to sync the Core protocol's addresses with the Registry protocol's addresses in case the registry updates at least one of them
    /// @dev {see RegistryEntities.sol for a description of the protocolAddressesArgs struct}
    /// @dev should be called immediately after the deployment of the contract
    /// @dev only accounts who have been assigned the CORE_CONFIGURATION_UPDATER_ROLE { See LibRoles.sol } should be able to call the function
    function updateProtocolAddresses() external onlyCoreConfigurationUpdater {
        protocolAddressesArgs = registry.getProtocolAddresses();
    }

    /// @notice It allows a reseve recipient to claim their entire accrued reserves
    /// @param _tokenAddress address of the ERC20 token to withdraw
    function claimReserves(address _tokenAddress) external nonReentrant {
        require(!registry.isProtocolReserveClaimPaused(), "C22");
        uint256 balance = reservesVault[msg.sender][_tokenAddress];
        reservesVault[msg.sender][_tokenAddress] = 0;
        IERC20Upgradeable(_tokenAddress).safeTransfer(msg.sender, balance);
    }

    /// @notice It allows a reserves recipient to to claim the desired amount of accrued reserves
    /// @param _tokenAddress address of the ERC20 token to withdraw
    /// @param _amount uint256 amount of reserves to withdraw
    function claimReserves(address _tokenAddress, uint256 _amount) external nonReentrant {
        require(!registry.isProtocolReserveClaimPaused(), "C22");
        uint256 balance = reservesVault[msg.sender][_tokenAddress];
        require(balance >= _amount, "C15");
        reservesVault[msg.sender][_tokenAddress] -= _amount;
        IERC20Upgradeable(_tokenAddress).safeTransfer(msg.sender, _amount);
    }

    /// @notice It deploys and mints the two erc20 contracts representing a derivative's LONG and SHORT positions { see Core._create for the business logic description }
    /// @param _derivative LibDerivative.Derivative Derivative definition
    /// @param _amount uint256 Amount of positions to create
    /// @param _positionsOwners address[2] Addresses of buyer and seller
    /// [0] - buyer address
    /// [1] - seller address
    function create(
        LibDerivative.Derivative calldata _derivative,
        uint256 _amount,
        address[2] calldata _positionsOwners
    ) external nonReentrant {
        _create(_derivative, _derivative.getDerivativeHash(), _amount, _positionsOwners);
    }

    /// @notice It can either 1) deploy AND mint 2) only mint.
    /// @notice It checks whether the ERC20 contracts representing the LONG and SHORT positions of the provided `LibDerivative.Derivative` have been deployed. If not, then it deploys the respective ERC20 contracts and mints the supplied _amount respectively to the provided buyer's and seller's accounts. If they have already been deployed, it only mints the provided _amount to the provided buyer's and seller's accounts.
    /// @dev if the position contracts have been deployed, it uses Core._create()
    /// @dev if the position contracts have deployed, it uses Core._mint()
    /// @param _derivative LibDerivative.Derivative Derivative definition
    /// @param _amount uint256 Amount of LONG and SHORT positions create and/or mint
    /// @param _positionsOwners address[2] Addresses of buyer and seller
    /// _positionsOwners[0] - buyer address -> receives LONG position
    /// _positionsOwners[1] - seller address -> receives SHORT position
    function createAndMint(
        LibDerivative.Derivative calldata _derivative,
        uint256 _amount,
        address[2] calldata _positionsOwners
    ) external nonReentrant {
        bytes32 derivativeHash = _derivative.getDerivativeHash();
        address implementationAddress = IOpiumProxyFactory(protocolAddressesArgs.opiumProxyFactory)
            .getImplementationAddress();
        (address longPositionTokenAddress, bool isLongDeployed) = derivativeHash.predictAndCheckDeterministicAddress(
            true,
            implementationAddress,
            address(protocolAddressesArgs.opiumProxyFactory)
        );
        (address shortPositionTokenAddress, bool isShortDeployed) = derivativeHash.predictAndCheckDeterministicAddress(
            false,
            implementationAddress,
            protocolAddressesArgs.opiumProxyFactory
        );
        // both erc20 positions have not been deployed
        require(isLongDeployed == isShortDeployed, "C23");
        if (!isLongDeployed) {
            _create(_derivative, derivativeHash, _amount, _positionsOwners);
        } else {
            _mint(_amount, [longPositionTokenAddress, shortPositionTokenAddress], _positionsOwners);
        }
    }

    /// @notice This function mints the provided amount of LONG/SHORT positions to msg.sender for a previously deployed pair of LONG/SHORT ERC20 contracts { see Core._mint for the business logic description }
    /// @param _amount uint256 Amount of positions to create
    /// @param _positionsAddresses address[2] Addresses of buyer and seller
    /// [0] - LONG erc20 position address
    /// [1] - SHORT erc20 position address
    /// @param _positionsOwners address[2] Addresses of buyer and seller
    /// _positionsOwners[0] - buyer address
    /// _positionsOwners[1] - seller address
    function mint(
        uint256 _amount,
        address[2] calldata _positionsAddresses,
        address[2] calldata _positionsOwners
    ) external nonReentrant {
        _mint(_amount, _positionsAddresses, _positionsOwners);
    }

    /// @notice Executes a single position of `msg.sender` with specified `positionAddress` { see Core._execute for the business logic description }
    /// @param _positionAddress address `positionAddress` of position that needs to be executed
    /// @param _amount uint256 Amount of positions to execute
    function execute(address _positionAddress, uint256 _amount) external nonReentrant {
        _execute(msg.sender, _positionAddress, _amount);
    }

    /// @notice Executes a single position of `_positionsOwner` with specified `positionAddress` { see Core._execute for the business logic description }
    /// @param _positionOwner address Address of the owner of positions
    /// @param _positionAddress address `positionAddress` of positions that needs to be executed
    /// @param _amount uint256 Amount of positions to execute
    function execute(
        address _positionOwner,
        address _positionAddress,
        uint256 _amount
    ) external nonReentrant {
        _execute(_positionOwner, _positionAddress, _amount);
    }

    /// @notice Executes several positions of `msg.sender` with different `positionAddresses` { see Core._execute for the business logic description }
    /// @param _positionsAddresses address[] `positionAddresses` of positions that need to be executed
    /// @param _amounts uint256[] Amount of positions to execute for each `positionAddress`
    function execute(address[] calldata _positionsAddresses, uint256[] calldata _amounts) external nonReentrant {
        require(_positionsAddresses.length == _amounts.length, "C1");
        for (uint256 i; i < _positionsAddresses.length; i++) {
            _execute(msg.sender, _positionsAddresses[i], _amounts[i]);
        }
    }

    /// @notice Executes several positions of `_positionsOwner` with different `positionAddresses` { see Core._execute for the business logic description }
    /// @param _positionsOwner address Address of the owner of positions
    /// @param _positionsAddresses address[] `positionAddresses` of positions that need to be executed
    /// @param _amounts uint256[] Amount of positions to execute for each `positionAddresses`
    function execute(
        address _positionsOwner,
        address[] calldata _positionsAddresses,
        uint256[] calldata _amounts
    ) external nonReentrant {
        require(_positionsAddresses.length == _amounts.length, "C1");
        for (uint256 i; i < _positionsAddresses.length; i++) {
            _execute(_positionsOwner, _positionsAddresses[i], _amounts[i]);
        }
    }

    /// @notice Redeems a single market neutral position pair { see Core._redeem for the business logic description }
    /// @param _positionsAddresses address[2] `_positionsAddresses` of the positions that need to be redeemed
    /// @param _amount uint256 Amount of tokens to redeem
    function redeem(address[2] calldata _positionsAddresses, uint256 _amount) external nonReentrant {
        _redeem(_positionsAddresses, _amount);
    }

    /// @notice Redeems several market neutral position pairs { see Core._redeem for the business logic description }
    /// @param _positionsAddresses address[2][] `_positionsAddresses` of the positions that need to be redeemed
    /// @param _amounts uint256[] Amount of tokens to redeem for each position pair
    function redeem(address[2][] calldata _positionsAddresses, uint256[] calldata _amounts) external nonReentrant {
        require(_positionsAddresses.length == _amounts.length, "C1");
        for (uint256 i = 0; i < _positionsAddresses.length; i++) {
            _redeem(_positionsAddresses[i], _amounts[i]);
        }
    }

    /// @notice It cancels the specified amount of a derivative's position { see Core._cancel for the business logic description }
    /// @param _positionAddress PositionType of positions to be canceled
    /// @param _amount uint256 Amount of positions to cancel
    function cancel(address _positionAddress, uint256 _amount) external nonReentrant {
        _cancel(_positionAddress, _amount);
    }

    /// @notice It cancels the specified amounts of a list of derivative's position { see Core._cancel for the business logic description }
    /// @param _positionsAddresses PositionTypes of positions to be cancelled
    /// @param _amounts uint256[] Amount of positions to cancel for each `positionAddress`
    function cancel(address[] calldata _positionsAddresses, uint256[] calldata _amounts) external nonReentrant {
        require(_positionsAddresses.length == _amounts.length, "C1");
        for (uint256 i; i < _positionsAddresses.length; i++) {
            _cancel(_positionsAddresses[i], _amounts[i]);
        }
    }

    // ****************** PRIVATE FUNCTIONS ******************

    // ***** SETTERS *****

    /// @notice It deploys two ERC20 contracts representing respectively the LONG and SHORT position of the provided `LibDerivative.Derivative` derivative and mints the provided amount of SHORT positions to a seller and LONG positions to a buyer
    /// @dev it can only be called if the ERC20 contracts for the derivative's positions have not yet been deployed
    /// @dev the uint256 _amount of positions to be minted can be 0 - which results in the deployment of the position contracts without any circulating supply
    /// @param _derivative LibDerivative.Derivative Derivative definition
    /// @param _derivativeHash unique identifier of a derivative which is used as a key in the p2pVaults mapping
    /// @param _amount uint256 Amount of positions to create
    /// @param _positionsOwners address[2] Addresses of buyer and seller
    /// [0] - buyer address -> receives LONG position
    /// [1] - seller address -> receives SHORT position
    function _create(
        LibDerivative.Derivative calldata _derivative,
        bytes32 _derivativeHash,
        uint256 _amount,
        address[2] calldata _positionsOwners
    ) private {
        require(block.timestamp < _derivative.endTime, "C16");
        require(!registry.isProtocolPositionCreationPaused(), "C17");

        // Validate input data against Derivative logic (`syntheticId`)
        require(IDerivativeLogic(_derivative.syntheticId).validateInput(_derivative), "C8");

        uint256[2] memory margins;
        // Get cached margin required according to logic from Opium.SyntheticAggregator
        // margins[0] - buyerMargin
        // margins[1] - sellerMargin
        (margins[0], margins[1]) = ISyntheticAggregator(protocolAddressesArgs.syntheticAggregator).getOrCacheMargin(
            _derivativeHash,
            _derivative
        );

        uint256 totalMargin = margins[0] + margins[1];
        require((totalMargin * _amount).modWithPrecisionFactor() == 0, "C5");
        uint256 totalMarginToE18 = totalMargin.mulWithPrecisionFactor(_amount);

        // Check ERC20 tokens allowance: (margins[0] + margins[1]) * amount
        // `msg.sender` must provide margin for position creation
        require(
            IERC20Upgradeable(_derivative.token).allowance(msg.sender, protocolAddressesArgs.tokenSpender) >=
                totalMarginToE18,
            "C12"
        );

        // Increment p2p positions balance by collected margin: vault += (margins[0] + margins[1]) * _amount
        _increaseP2PVault(_derivativeHash, totalMarginToE18);

        // Take ERC20 tokens from msg.sender, should never revert in correct ERC20 implementation
        ITokenSpender(protocolAddressesArgs.tokenSpender).claimTokens(
            IERC20Upgradeable(_derivative.token),
            msg.sender,
            address(this),
            totalMarginToE18
        );

        // Mint LONG and SHORT positions tokens
        IOpiumProxyFactory(protocolAddressesArgs.opiumProxyFactory).create(
            _positionsOwners[0],
            _positionsOwners[1],
            _amount,
            _derivativeHash,
            _derivative
        );

        emit LogCreated(_positionsOwners[0], _positionsOwners[1], _derivativeHash, _amount);
    }

    /// @notice It mints the provided amount of LONG and SHORT positions of a given derivative and it forwards them to the provided positions' owners
    /// @dev it can only be called if the ERC20 contracts for the derivative's positions have already been deployed
    /// @dev the uint256 _amount of positions to be minted can be 0
    /// @param _amount uint256 Amount of LONG and SHORT positions to mint
    /// @param _positionsAddresses address[2] tuple containing the addresses of the derivative's positions to be minted
    /// _positionsAddresses[0] -> erc20-based LONG position
    /// _positionsAddresses[1] - erc20-based SHORT position
    /// @param _positionsOwners address[2] Addresses of buyer and seller
    /// [0] - buyer address -> receives LONG position
    /// [1] - seller address -> receives SHORT position
    function _mint(
        uint256 _amount,
        address[2] memory _positionsAddresses,
        address[2] memory _positionsOwners
    ) private {
        require(!registry.isProtocolPositionMintingPaused(), "C18");
        IOpiumPositionToken.OpiumPositionTokenParams memory longOpiumPositionTokenParams = IOpiumPositionToken(
            _positionsAddresses[0]
        ).getPositionTokenData();
        IOpiumPositionToken.OpiumPositionTokenParams memory shortOpiumPositionTokenParams = IOpiumPositionToken(
            _positionsAddresses[1]
        ).getPositionTokenData();
        _onlyOpiumFactoryTokens(_positionsAddresses[0], longOpiumPositionTokenParams);
        _onlyOpiumFactoryTokens(_positionsAddresses[1], shortOpiumPositionTokenParams);
        require(shortOpiumPositionTokenParams.derivativeHash == longOpiumPositionTokenParams.derivativeHash, "C2");
        require(longOpiumPositionTokenParams.positionType == LibDerivative.PositionType.LONG, "C3");
        require(shortOpiumPositionTokenParams.positionType == LibDerivative.PositionType.SHORT, "C3");

        require(block.timestamp < longOpiumPositionTokenParams.derivative.endTime, "C16");

        uint256[2] memory margins;
        // Get cached margin required according to logic from Opium.SyntheticAggregator
        // margins[0] - buyerMargin
        // margins[1] - sellerMargin
        (margins[0], margins[1]) = ISyntheticAggregator(protocolAddressesArgs.syntheticAggregator).getOrCacheMargin(
            longOpiumPositionTokenParams.derivativeHash,
            longOpiumPositionTokenParams.derivative
        );

        uint256 totalMargin = margins[0] + margins[1];
        require((totalMargin * _amount).modWithPrecisionFactor() == 0, "C5");
        uint256 totalMarginToE18 = totalMargin.mulWithPrecisionFactor(_amount);

        // Check ERC20 tokens allowance: (margins[0] + margins[1]) * amount
        // `msg.sender` must provide margin for position creation
        require(
            IERC20Upgradeable(longOpiumPositionTokenParams.derivative.token).allowance(
                msg.sender,
                protocolAddressesArgs.tokenSpender
            ) >= totalMarginToE18,
            "C12"
        );

        // Increment p2p positions balance by collected margin: vault += (margins[0] + margins[1]) * _amount
        _increaseP2PVault(longOpiumPositionTokenParams.derivativeHash, totalMarginToE18);

        // Take ERC20 tokens from msg.sender, should never revert in correct ERC20 implementation
        ITokenSpender(protocolAddressesArgs.tokenSpender).claimTokens(
            IERC20Upgradeable(longOpiumPositionTokenParams.derivative.token),
            msg.sender,
            address(this),
            totalMarginToE18
        );

        // Mint LONG and SHORT positions tokens
        IOpiumProxyFactory(protocolAddressesArgs.opiumProxyFactory).mintPair(
            _positionsOwners[0],
            _positionsOwners[1],
            _positionsAddresses[0],
            _positionsAddresses[1],
            _amount
        );

        emit LogMinted(_positionsOwners[0], _positionsOwners[1], longOpiumPositionTokenParams.derivativeHash, _amount);
    }

    /// @notice It redeems the provided amount of a derivative's market neutral position pair (LONG/SHORT) owned by the msg.sender - redeeming a market neutral position pair results in an equal amount of LONG and SHORT positions being burned in exchange for their original collateral
    /// @param _positionsAddresses address[2] `positionAddresses` representing the tuple of market-neutral positions ordered in the following way:
    /// [0] LONG position
    /// [1] SHORT position
    /// @param _amount uint256 amount of the LONG and SHORT positions to be redeemed
    function _redeem(address[2] memory _positionsAddresses, uint256 _amount) private {
        require(!registry.isProtocolPositionRedemptionPaused(), "C19");
        IOpiumPositionToken.OpiumPositionTokenParams memory longOpiumPositionTokenParams = IOpiumPositionToken(
            _positionsAddresses[0]
        ).getPositionTokenData();
        IOpiumPositionToken.OpiumPositionTokenParams memory shortOpiumPositionTokenParams = IOpiumPositionToken(
            _positionsAddresses[1]
        ).getPositionTokenData();
        _onlyOpiumFactoryTokens(_positionsAddresses[0], longOpiumPositionTokenParams);
        _onlyOpiumFactoryTokens(_positionsAddresses[1], shortOpiumPositionTokenParams);
        require(shortOpiumPositionTokenParams.derivativeHash == longOpiumPositionTokenParams.derivativeHash, "C2");
        require(longOpiumPositionTokenParams.positionType == LibDerivative.PositionType.LONG, "C3");
        require(shortOpiumPositionTokenParams.positionType == LibDerivative.PositionType.SHORT, "C3");

        ISyntheticAggregator.SyntheticCache memory syntheticCache = ISyntheticAggregator(
            protocolAddressesArgs.syntheticAggregator
        ).getOrCacheSyntheticCache(
                shortOpiumPositionTokenParams.derivativeHash,
                shortOpiumPositionTokenParams.derivative
            );

        uint256 totalMargin = (syntheticCache.buyerMargin + syntheticCache.sellerMargin).mulWithPrecisionFactor(
            _amount
        );
        uint256 reserves = _computeReserves(
            syntheticCache.authorAddress,
            shortOpiumPositionTokenParams.derivative.token,
            protocolAddressesArgs.protocolRedemptionReserveClaimer,
            protocolParametersArgs.derivativeAuthorRedemptionReservePart,
            protocolParametersArgs.protocolRedemptionReservePart,
            totalMargin
        );

        _decreaseP2PVault(shortOpiumPositionTokenParams.derivativeHash, totalMargin);

        IOpiumProxyFactory(protocolAddressesArgs.opiumProxyFactory).burnPair(
            msg.sender,
            _positionsAddresses[0],
            _positionsAddresses[1],
            _amount
        );

        IERC20Upgradeable(shortOpiumPositionTokenParams.derivative.token).safeTransfer(
            msg.sender,
            totalMargin - reserves
        );

        emit LogRedeemed(msg.sender, shortOpiumPositionTokenParams.derivativeHash, _amount);
    }

    /// @notice It executes the provided amount of a derivative's position owned by a given position's owner - which results in the distribution of the position's payout and related reseves if the position is profitable and in the executed position's amount being burned regardless of its profitability
    /// @param _positionOwner address Address of the owner of positions
    /// @param _positionAddress address `_positionAddress` of the ERC20 OpiumPositionToken that needs to be executed
    /// @param _amount uint256 Amount of position to execute for the provided `positionAddress`
    function _execute(
        address _positionOwner,
        address _positionAddress,
        uint256 _amount
    ) private {
        require(!registry.isProtocolPositionExecutionPaused(), "C20");
        IOpiumPositionToken.OpiumPositionTokenParams memory opiumPositionTokenParams = IOpiumPositionToken(
            _positionAddress
        ).getPositionTokenData();
        _onlyOpiumFactoryTokens(_positionAddress, opiumPositionTokenParams);
        // Check if ticker was canceled
        require(!cancelledDerivatives[opiumPositionTokenParams.derivativeHash], "C7");
        // Check if execution is performed at a timestamp greater than or equal to the maturity date of the derivative
        require(block.timestamp >= opiumPositionTokenParams.derivative.endTime, "C10");

        // Checking whether execution is performed by `_positionsOwner` or `_positionsOwner` allowed third party executions on its behalf
        require(
            _positionOwner == msg.sender ||
                IDerivativeLogic(opiumPositionTokenParams.derivative.syntheticId).thirdpartyExecutionAllowed(
                    _positionOwner
                ),
            "C11"
        );

        // Burn executed position tokens
        IOpiumProxyFactory(protocolAddressesArgs.opiumProxyFactory).burn(_positionOwner, _positionAddress, _amount);

        // Returns payout for all positions
        uint256 payout = _computePayout(
            opiumPositionTokenParams,
            _amount,
            ISyntheticAggregator(protocolAddressesArgs.syntheticAggregator),
            IOracleAggregator(protocolAddressesArgs.oracleAggregator)
        );

        // Transfer payout
        if (payout > 0) {
            IERC20Upgradeable(opiumPositionTokenParams.derivative.token).safeTransfer(_positionOwner, payout);
        }

        emit LogExecuted(_positionOwner, _positionAddress, _amount);
    }

    /// @notice Cancels tickers, burns positions and returns margins to the position owner in case no data were provided within `protocolParametersArgs.noDataCancellationPeriod`
    /// @param _positionAddress PositionTypes of positions to be canceled
    /// @param _amount uint256[] Amount of positions to cancel for each `positionAddress`
    function _cancel(address _positionAddress, uint256 _amount) private {
        require(!registry.isProtocolPositionCancellationPaused(), "C21");
        IOpiumPositionToken.OpiumPositionTokenParams memory opiumPositionTokenParams = IOpiumPositionToken(
            _positionAddress
        ).getPositionTokenData();
        _onlyOpiumFactoryTokens(_positionAddress, opiumPositionTokenParams);

        // It's sufficient to perform all the sanity checks only if a derivative has not yet been canceled
        if (!cancelledDerivatives[opiumPositionTokenParams.derivativeHash]) {
            // Don't allow to cancel tickers with "dummy" oracleIds
            require(opiumPositionTokenParams.derivative.oracleId != address(0), "C6");

            // Check if cancellation is called after `protocolParametersArgs.noDataCancellationPeriod` and `oracleId` didn't provide the required data
            require(
                opiumPositionTokenParams.derivative.endTime + protocolParametersArgs.noDataCancellationPeriod <=
                    block.timestamp,
                "C13"
            );
            // Ensures that `Opium.OracleAggregator` has still not been provided with data after noDataCancellationperiod
            // The check needs to be performed only the first time a derivative is being canceled as to avoid preventing other parties from canceling their positions in case `Opium.OracleAggregator` receives data after the successful cancelation
            require(
                !IOracleAggregator(protocolAddressesArgs.oracleAggregator).hasData(
                    opiumPositionTokenParams.derivative.oracleId,
                    opiumPositionTokenParams.derivative.endTime
                ),
                "C13"
            );
            cancelledDerivatives[opiumPositionTokenParams.derivativeHash] = true;
            // Emit `LogDerivativeHashCancelled` event only once and mark ticker as canceled
            emit LogDerivativeHashCancelled(msg.sender, opiumPositionTokenParams.derivativeHash);
        }

        uint256 payout;
        // Check if `_positionsAddresses` is a LONG position
        if (opiumPositionTokenParams.positionType == LibDerivative.PositionType.LONG) {
            // Get cached margin required according to logic from Opium.SyntheticAggregator
            // (buyerMargin, sellerMargin) = syntheticAggregator.getMargin
            (uint256 buyerMargin, ) = ISyntheticAggregator(protocolAddressesArgs.syntheticAggregator).getOrCacheMargin(
                opiumPositionTokenParams.derivativeHash,
                opiumPositionTokenParams.derivative
            );
            // Set payout to buyerPayout
            payout = buyerMargin.mulWithPrecisionFactor(_amount);

            // Check if `positionAddress` is a SHORT position
        } else {
            // Get cached margin required according to logic from Opium.SyntheticAggregator
            // (buyerMargin, sellerMargin) = syntheticAggregator.getMargin
            (, uint256 sellerMargin) = ISyntheticAggregator(protocolAddressesArgs.syntheticAggregator).getOrCacheMargin(
                opiumPositionTokenParams.derivativeHash,
                opiumPositionTokenParams.derivative
            );
            // Set payout to sellerPayout
            payout = sellerMargin.mulWithPrecisionFactor(_amount);
        }

        _decreaseP2PVault(opiumPositionTokenParams.derivativeHash, payout);

        // Burn cancelled position tokens
        IOpiumProxyFactory(protocolAddressesArgs.opiumProxyFactory).burn(msg.sender, _positionAddress, _amount);

        // Transfer payout * _amounts[i]
        if (payout > 0) {
            IERC20Upgradeable(opiumPositionTokenParams.derivative.token).safeTransfer(msg.sender, payout);
        }

        emit LogCancelled(msg.sender, opiumPositionTokenParams.derivativeHash, _amount);
    }

    /// @notice Helper function consumed by `Core._execute` to calculate the execution's payout of a settled derivative's position
    /// @param _opiumPositionTokenParams it includes information about the derivative whose position is being executed { see OpiumPositionToken.sol for the implementation }
    /// @param _amount uint256 amount of positions of the same type (either LONG or SHORT) whose payout is being calculated
    /// @param _syntheticAggregator interface/address of `Opium SyntheticAggregator.sol`
    /// @param _oracleAggregator interface/address of `Opium OracleAggregator.sol`
    /// @return payout uint256 representing the net payout (gross payout - reserves) of the executed amount of positions
    function _computePayout(
        IOpiumPositionToken.OpiumPositionTokenParams memory _opiumPositionTokenParams,
        uint256 _amount,
        ISyntheticAggregator _syntheticAggregator,
        IOracleAggregator _oracleAggregator
    ) private returns (uint256 payout) {
        /// if the derivativePayout tuple's items (buyer payout and seller payout) are 0, it assumes it's the first time the _computePayout function is being executed, hence it fetches the payouts from the syntheticId and caches them.
        (uint256 buyerPayoutRatio, uint256 sellerPayoutRatio) = _getDerivativePayouts(
            _opiumPositionTokenParams.derivativeHash
        ); // gas saving
        if (buyerPayoutRatio == 0 && sellerPayoutRatio == 0) {
            /// fetches the derivative's data from the related oracleId
            /// opium allows the usage of "dummy" oracleIds - oracleIds whose address is null - in which case the data is set to 0
            uint256 data = _opiumPositionTokenParams.derivative.oracleId == address(0)
                ? 0
                : _oracleAggregator.getData(
                    _opiumPositionTokenParams.derivative.oracleId,
                    _opiumPositionTokenParams.derivative.endTime
                );
            // Get payout ratio from Derivative logic
            // payoutRatio[0] - buyerPayout
            // payoutRatio[1] - sellerPayout
            (buyerPayoutRatio, sellerPayoutRatio) = IDerivativeLogic(_opiumPositionTokenParams.derivative.syntheticId)
                .getExecutionPayout(_opiumPositionTokenParams.derivative, data);
            derivativePayouts[_opiumPositionTokenParams.derivativeHash] = [buyerPayoutRatio, sellerPayoutRatio]; // gas saving
        }

        ISyntheticAggregator.SyntheticCache memory syntheticCache = _syntheticAggregator.getOrCacheSyntheticCache(
            _opiumPositionTokenParams.derivativeHash,
            _opiumPositionTokenParams.derivative
        );

        uint256 positionMargin;

        // Check if `_positionType` is LONG
        if (_opiumPositionTokenParams.positionType == LibDerivative.PositionType.LONG) {
            // Calculates buyerPayout from ratio = (buyerMargin + sellerMargin) * buyerPayoutRatio / (buyerPayoutRatio + sellerPayoutRatio)
            // Set payout to buyerPayout multiplied by amount
            payout = (((syntheticCache.buyerMargin + syntheticCache.sellerMargin) * buyerPayoutRatio) /
                (buyerPayoutRatio + sellerPayoutRatio)).mulWithPrecisionFactor(_amount);
            // sets positionMargin to buyerMargin * amount
            positionMargin = syntheticCache.buyerMargin.mulWithPrecisionFactor(_amount);
            // Check if `_positionType` is a SHORT position
        } else {
            // Calculates sellerPayout from ratio = sellerPayout = (buyerMargin + sellerMargin) * sellerPayoutRatio / (buyerPayoutRatio + sellerPayoutRatio)
            // Set payout to sellerPayout multiplied by amount
            payout = (((syntheticCache.buyerMargin + syntheticCache.sellerMargin) * sellerPayoutRatio) /
                (buyerPayoutRatio + sellerPayoutRatio)).mulWithPrecisionFactor(_amount);
            // sets positionMargin to sellerMargin * amount
            positionMargin = syntheticCache.sellerMargin.mulWithPrecisionFactor(_amount);
        }

        _decreaseP2PVault(_opiumPositionTokenParams.derivativeHash, payout);

        // The reserves are deducted only from profitable positions: payout > positionMargin * amount
        if (payout > positionMargin) {
            payout =
                payout -
                _computeReserves(
                    syntheticCache.authorAddress,
                    _opiumPositionTokenParams.derivative.token,
                    protocolAddressesArgs.protocolExecutionReserveClaimer,
                    syntheticCache.authorCommission,
                    protocolParametersArgs.protocolExecutionReservePart,
                    payout - positionMargin
                );
        }
    }

    /// @notice It computes the total reserve to be distributed to the recipients provided as arguments
    /// @param _derivativeAuthorAddress address of the derivative author that receives a portion of the reserves being calculated
    /// @param _tokenAddress address of the token being used to distribute the reserves
    /// @param _protocolReserveReceiver  address of the designated recipient that receives a portion of the reserves being calculated
    /// @param _reservePercentage uint256 portion of the reserves that is being distributed from initial amount
    /// @param _protocolReservePercentage uint256 portion of the reserves that is being distributed to `_protocolReserveReceiver`
    /// @param _initialAmount uint256 the amount from which the reserves will be detracted
    /// @return totalReserve uint256 total reserves being calculated which corresponds to the sum of the reserves distributed to the derivative author and the designated recipient
    function _computeReserves(
        address _derivativeAuthorAddress,
        address _tokenAddress,
        address _protocolReserveReceiver,
        uint256 _reservePercentage,
        uint256 _protocolReservePercentage,
        uint256 _initialAmount
    ) private returns (uint256 totalReserve) {
        totalReserve = (_initialAmount * _reservePercentage) / LibCalculator.PERCENTAGE_BASE;

        // If totalReserve is zero, finish
        if (totalReserve == 0) {
            return 0;
        }

        uint256 protocolReserve = (totalReserve * _protocolReservePercentage) / LibCalculator.PERCENTAGE_BASE;

        // Update reservesVault for _protocolReserveReceiver
        reservesVault[_protocolReserveReceiver][_tokenAddress] += protocolReserve;

        // Update reservesVault for `syntheticId` author
        reservesVault[_derivativeAuthorAddress][_tokenAddress] += totalReserve - protocolReserve;
    }

    /// @notice It increases the balance associated to a given derivative stored in the p2pVaults mapping
    /// @param _derivativeHash unique identifier of a derivative which is used as a key in the p2pVaults mapping
    /// @param _amount uint256 representing how much the p2pVaults derivative's balance will increase
    function _increaseP2PVault(bytes32 _derivativeHash, uint256 _amount) private {
        p2pVaults[_derivativeHash] += _amount;
    }

    /// @notice It decreases the balance associated to a given derivative stored in the p2pVaults mapping
    /// @param _derivativeHash unique identifier of a derivative which is used as a key in the p2pVaults mapping
    /// @param _amount uint256 representing how much the p2pVaults derivative's balance will decrease
    function _decreaseP2PVault(bytes32 _derivativeHash, uint256 _amount) private {
        require(p2pVaults[_derivativeHash] >= _amount, "C9");
        p2pVaults[_derivativeHash] -= _amount;
    }

    // ***** GETTERS *****

    /// @notice ensures that a token was minted by the OpiumProxyFactory
    /// @dev usage of a private function rather than a modifier to avoid `stack too deep` error
    /// @param _tokenAddress address of the erc20 token to validate
    /// @param _opiumPositionTokenParams derivatives data of the token to validate
    function _onlyOpiumFactoryTokens(
        address _tokenAddress,
        IOpiumPositionToken.OpiumPositionTokenParams memory _opiumPositionTokenParams
    ) private view {
        address predicted = _opiumPositionTokenParams.derivativeHash.predictDeterministicAddress(
            _opiumPositionTokenParams.positionType == LibDerivative.PositionType.LONG,
            IOpiumProxyFactory(protocolAddressesArgs.opiumProxyFactory).getImplementationAddress(),
            address(protocolAddressesArgs.opiumProxyFactory)
        );
        require(_tokenAddress == predicted, "C14");
    }

    /// @notice private getter to destructure the derivativePayouts tuple. its only purpose is gas optimization
    /// @param _derivativeHash bytes32 identifier of the derivative whose payout is being fetched
    function _getDerivativePayouts(bytes32 _derivativeHash) private view returns (uint256, uint256) {
        return (derivativePayouts[_derivativeHash][0], derivativePayouts[_derivativeHash][1]);
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private __gap;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
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
    uint256[49] private __gap;
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../../interfaces/IRegistry.sol";

/**
    Error codes:
    - M1 = ERROR_REGISTRY_MANAGER_ONLY_REGISTRY_MANAGER_ROLE
    - M2 = ERROR_REGISTRY_MANAGER_ONLY_CORE_CONFIGURATION_UPDATER_ROLE
 */
contract RegistryManager is Initializable {
    event LogRegistryChanged(address indexed _changer, address indexed _newRegistryAddress);

    IRegistry internal registry;

    modifier onlyRegistryManager() {
        require(registry.isRegistryManager(msg.sender), "M1");
        _;
    }

    modifier onlyCoreConfigurationUpdater() {
        require(registry.isCoreConfigurationUpdater(msg.sender), "M2");
        _;
    }

    function __RegistryManager__init(address _registry) internal initializer {
        require(_registry != address(0));
        registry = IRegistry(_registry);
        emit LogRegistryChanged(msg.sender, _registry);
    }

    function setRegistry(address _registry) external onlyRegistryManager {
        registry = IRegistry(_registry);
        emit LogRegistryChanged(msg.sender, _registry);
    }

    function getRegistry() external view returns (address) {
        return address(registry);
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private __gap;
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.5;

import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";

library LibPosition {
    function predictDeterministicAddress(
        bytes32 _derivativeHash,
        bool _isLong,
        address _positionImplementationAddress,
        address _factoryAddress
    ) internal pure returns (address) {
        return _predictDeterministicAddress(_derivativeHash, _isLong, _positionImplementationAddress, _factoryAddress);
    }

    function predictAndCheckDeterministicAddress(
        bytes32 _derivativeHash,
        bool _isLong,
        address _positionImplementationAddress,
        address _factoryAddress
    ) internal view returns (address, bool) {
        address predicted = _predictDeterministicAddress(
            _derivativeHash,
            _isLong,
            _positionImplementationAddress,
            _factoryAddress
        );
        bool isDeployed = _isContract(predicted);
        return (predicted, isDeployed);
    }

    function deployOpiumPosition(
        bytes32 _derivativeHash,
        bool _isLong,
        address _positionImplementationAddress
    ) internal returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(_derivativeHash, _isLong ? "L" : "S"));
        return ClonesUpgradeable.cloneDeterministic(_positionImplementationAddress, salt);
    }

    function _predictDeterministicAddress(
        bytes32 _derivativeHash,
        bool _isLong,
        address _positionImplementationAddress,
        address _factoryAddress
    ) private pure returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(_derivativeHash, _isLong ? "L" : "S"));
        return ClonesUpgradeable.predictDeterministicAddress(_positionImplementationAddress, salt, _factoryAddress);
    }

    /// @notice checks whether a contract has already been deployed at a specific address
    /// @return bool true if a contract has been deployed at a specific address and false otherwise
    function _isContract(address _address) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_address)
        }
        return size > 0;
    }
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

interface IRegistry {
    function initialize(address _governor) external;

    function setProtocolAddresses(
        address _opiumProxyFactory,
        address _core,
        address _oracleAggregator,
        address _syntheticAggregator,
        address _tokenSpender
    ) external;

    function setNoDataCancellationPeriod(uint32 _noDataCancellationPeriod) external;

    function addToWhitelist(address _whitelisted) external;

    function removeFromWhitelist(address _whitelisted) external;

    function setProtocolExecutionReserveClaimer(address _protocolExecutionReserveClaimer) external;

    function setProtocolRedemptionReserveClaimer(address _protocolRedemptionReserveClaimer) external;

    function setProtocolExecutionReservePart(uint32 _protocolExecutionReservePart) external;

    function setDerivativeAuthorExecutionFeeCap(uint32 _derivativeAuthorExecutionFeeCap) external;

    function setProtocolRedemptionReservePart(uint32 _protocolRedemptionReservePart) external;

    function setDerivativeAuthorRedemptionReservePart(uint32 _derivativeAuthorRedemptionReservePart) external;

    function pause() external;

    function pauseProtocolPositionCreation() external;

    function pauseProtocolPositionMinting() external;

    function pauseProtocolPositionRedemption() external;

    function pauseProtocolPositionExecution() external;

    function pauseProtocolPositionCancellation() external;

    function pauseProtocolReserveClaim() external;

    function unpause() external;

    function getProtocolParameters() external view returns (RegistryEntities.ProtocolParametersArgs memory);

    function getProtocolAddresses() external view returns (RegistryEntities.ProtocolAddressesArgs memory);

    function isRegistryManager(address _address) external view returns (bool);

    function isCoreConfigurationUpdater(address _address) external view returns (bool);

    function getCore() external view returns (address);

    function isCoreSpenderWhitelisted(address _address) external view returns (bool);

    function isProtocolPaused() external view returns (bool);

    function isProtocolPositionCreationPaused() external view returns (bool);

    function isProtocolPositionMintingPaused() external view returns (bool);

    function isProtocolPositionRedemptionPaused() external view returns (bool);

    function isProtocolPositionExecutionPaused() external view returns (bool);

    function isProtocolPositionCancellationPaused() external view returns (bool);

    function isProtocolReserveClaimPaused() external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../libs/LibDerivative.sol";

interface IOpiumPositionToken is IERC20PermitUpgradeable, IERC20Upgradeable {
    struct OpiumPositionTokenParams {
        LibDerivative.Derivative derivative;
        LibDerivative.PositionType positionType;
        bytes32 derivativeHash;
    }

    function initialize(
        bytes32 _derivativeHash,
        LibDerivative.PositionType _positionType,
        LibDerivative.Derivative calldata _derivative
    ) external;

    function mint(address _positionOwner, uint256 _amount) external;

    function burn(address _positionOwner, uint256 _amount) external;

    function getFactoryAddress() external view returns (address);

    function getPositionTokenData() external view returns (OpiumPositionTokenParams memory opiumPositionTokenParams);

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) external;

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;

import "../libs/LibDerivative.sol";

/// @title Opium.Interface.IDerivativeLogic is an interface that every syntheticId should implement
interface IDerivativeLogic {
    // Event with syntheticId metadata JSON string (for DIB.ONE derivative explorer)
    event LogMetadataSet(string metadata);

    /// @notice Validates ticker
    /// @param _derivative Derivative Instance of derivative to validate
    /// @return Returns boolean whether ticker is valid
    function validateInput(LibDerivative.Derivative memory _derivative) external view returns (bool);

    /// @return Returns the custom name of a derivative ticker which will be used as part of the name of its positions
    function getSyntheticIdName() external view returns (string memory);

    /// @notice Calculates margin required for derivative creation
    /// @param _derivative Derivative Instance of derivative
    /// @return buyerMargin uint256 Margin needed from buyer (LONG position)
    /// @return sellerMargin uint256 Margin needed from seller (SHORT position)
    function getMargin(LibDerivative.Derivative memory _derivative)
        external
        view
        returns (uint256 buyerMargin, uint256 sellerMargin);

    /// @notice Calculates payout for derivative execution
    /// @param _derivative Derivative Instance of derivative
    /// @param _result uint256 Data retrieved from oracleId on the maturity
    /// @return buyerPayout uint256 Payout in ratio for buyer (LONG position holder)
    /// @return sellerPayout uint256 Payout in ratio for seller (SHORT position holder)
    function getExecutionPayout(LibDerivative.Derivative memory _derivative, uint256 _result)
        external
        view
        returns (uint256 buyerPayout, uint256 sellerPayout);

    /// @notice Returns syntheticId author address for Opium commissions
    /// @return authorAddress address The address of syntheticId address
    function getAuthorAddress() external view returns (address authorAddress);

    /// @notice Returns syntheticId author commission in base of COMMISSION_BASE
    /// @return commission uint256 Author commission
    function getAuthorCommission() external view returns (uint256 commission);

    /// @notice Returns whether thirdparty could execute on derivative's owner's behalf
    /// @param _derivativeOwner address Derivative owner address
    /// @return Returns boolean whether _derivativeOwner allowed third party execution
    function thirdpartyExecutionAllowed(address _derivativeOwner) external view returns (bool);

    /// @notice Sets whether thirds parties are allowed or not to execute derivative's on msg.sender's behalf
    /// @param _allow bool Flag for execution allowance
    function allowThirdpartyExecution(bool _allow) external;
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
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library ClonesUpgradeable {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}