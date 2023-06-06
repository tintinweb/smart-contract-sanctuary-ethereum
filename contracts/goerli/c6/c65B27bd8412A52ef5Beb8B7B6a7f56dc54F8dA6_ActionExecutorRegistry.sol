// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { IRegistry } from './interfaces/IRegistry.sol';
import { IVault } from './interfaces/IVault.sol';
import { BalanceManagement } from './BalanceManagement.sol';
import { SystemVersionId } from './SystemVersionId.sol';
import { TargetGasReserve } from './crosschain/TargetGasReserve.sol';
import { ZeroAddressError } from './Errors.sol';
import './helpers/AddressHelper.sol' as AddressHelper;
import './helpers/DecimalsHelper.sol' as DecimalsHelper;
import './Constants.sol' as Constants;
import './DataStructures.sol' as DataStructures;

/**
 * @title ActionExecutorRegistry
 * @notice The contract for action settings
 */
contract ActionExecutorRegistry is SystemVersionId, TargetGasReserve, BalanceManagement, IRegistry {
    /**
     * @dev Registered cross-chain gateway addresses by type
     */
    mapping(uint256 /*gatewayType*/ => address /*gatewayAddress*/) public gatewayMap;

    /**
     * @dev Registered cross-chain gateway types
     */
    uint256[] public gatewayTypeList;

    /**
     * @dev Registered cross-chain gateway type indices
     */
    mapping(uint256 /*gatewayType*/ => DataStructures.OptionalValue /*gatewayTypeIndex*/)
        public gatewayTypeIndexMap;

    /**
     * @dev Registered cross-chain gateway flags by address
     */
    mapping(address /*account*/ => bool /*isGateway*/) public isGatewayAddress;

    /**
     * @dev Registered swap router addresses by type
     */
    mapping(uint256 /*routerType*/ => address /*routerAddress*/) public routerMap;

    /**
     * @dev Registered swap router types
     */
    uint256[] public routerTypeList;

    /**
     * @dev Registered swap router type indices
     */
    mapping(uint256 /*routerType*/ => DataStructures.OptionalValue /*routerTypeIndex*/)
        public routerTypeIndexMap;

    /**
     * @dev Registered swap router transfer addresses by router type
     */
    mapping(uint256 /*routerType*/ => address /*routerTransferAddress*/) public routerTransferMap;

    /**
     * @dev Registered vault addresses by type
     */
    mapping(uint256 /*vaultType*/ => address /*vaultAddress*/) public vaultMap;

    /**
     * @dev Registered vault types
     */
    uint256[] public vaultTypeList;

    /**
     * @dev Registered vault-type indices
     */
    mapping(uint256 /*vaultType*/ => DataStructures.OptionalValue /*vaultTypeIndex*/)
        public vaultTypeIndexMap;

    /**
     * @dev Registered non-default decimal values by vault type
     */
    mapping(uint256 /*vaultType*/ => mapping(uint256 /*chainId*/ => DataStructures.OptionalValue /*vaultDecimals*/))
        public vaultDecimalsTable;

    /**
     * @dev Chain IDs of registered vault decimal values
     */
    uint256[] public vaultDecimalsChainIdList;

    /**
     * @dev Chain ID indices of registered vault decimal values
     */
    mapping(uint256 /*chainId*/ => DataStructures.OptionalValue /*chainIdIndex*/)
        public vaultDecimalsChainIdIndexMap;

    /**
     * @dev The system fee value (cross-chain swaps) in milli-percent, e.g., 100 is 0.1%
     */
    uint256 public systemFee;

    /**
     * @dev The system fee value (single-chain swaps) in milli-percent, e.g., 100 is 0.1%
     */
    uint256 public systemFeeLocal;

    /**
     * @dev The address of the cross-chain action fee collector
     */
    address public feeCollector;

    /**
     * @dev The address of the single-chain action fee collector
     */
    address public feeCollectorLocal;

    /**
     * @dev The list of accounts that can perform actions without fees and amount restrictions
     */
    address[] public whitelist;

    /**
     * @dev The whitelist account indices
     */
    mapping(address /*account*/ => DataStructures.OptionalValue /*whitelistIndex*/)
        public whitelistIndexMap;

    /**
     * @dev The minimum cross-chain swap amount in USD, with decimals = 18
     */
    uint256 public swapAmountMin = 0;

    /**
     * @dev The maximum cross-chain swap amount in USD, with decimals = 18. Is type(uint256).max for unlimited amount
     */
    uint256 public swapAmountMax = Constants.INFINITY;

    uint256 private constant VAULT_DECIMALS_CHAIN_ID_WILDCARD = 0;
    uint256 private constant SYSTEM_FEE_LIMIT = 10_000; // Maximum system fee in milli-percent = 10%
    uint256 private constant SYSTEM_FEE_INITIAL = 100; // Initial system fee in milli-percent = 0.1%

    /**
     * @notice Emitted when a registered cross-chain gateway contract address is added or updated
     * @param gatewayType The type of the registered cross-chain gateway
     * @param gatewayAddress The address of the registered cross-chain gateway contract
     */
    event SetGateway(uint256 indexed gatewayType, address indexed gatewayAddress);

    /**
     * @notice Emitted when a registered cross-chain gateway contract address is removed
     * @param gatewayType The type of the removed cross-chain gateway
     */
    event RemoveGateway(uint256 indexed gatewayType);

    /**
     * @notice Emitted when a registered vault contract address is added or updated
     * @param vaultType The type of the registered vault
     * @param vaultAddress The address of the registered vault contract
     */
    event SetVault(uint256 indexed vaultType, address indexed vaultAddress);

    /**
     * @notice Emitted when a registered vault contract address is removed
     * @param vaultType The type of the removed vault
     */
    event RemoveVault(uint256 indexed vaultType);

    /**
     * @notice Emitted when vault decimal values are set
     * @param vaultType The type of the vault
     * @param decimalsData The vault decimal values
     */
    event SetVaultDecimals(uint256 indexed vaultType, DataStructures.KeyToValue[] decimalsData);

    /**
     * @notice Emitted when vault decimal values are unset
     * @param vaultType The type of the vault
     */
    event UnsetVaultDecimals(uint256 indexed vaultType, uint256[] chainIds);

    /**
     * @notice Emitted when a registered swap router contract address is added or updated
     * @param routerType The type of the registered swap router
     * @param routerAddress The address of the registered swap router contract
     */
    event SetRouter(uint256 indexed routerType, address indexed routerAddress);

    /**
     * @notice Emitted when a registered swap router contract address is removed
     * @param routerType The type of the removed swap router
     */
    event RemoveRouter(uint256 indexed routerType);

    /**
     * @notice Emitted when a registered swap router transfer contract address is set
     * @param routerType The type of the swap router
     * @param routerTransfer The address of the swap router transfer contract
     */
    event SetRouterTransfer(uint256 indexed routerType, address indexed routerTransfer);

    /**
     * @notice Emitted when the system fee value (cross-chain swaps) is set
     * @param systemFee The system fee value in milli-percent, e.g., 100 is 0.1%
     */
    event SetSystemFee(uint256 systemFee);

    /**
     * @notice Emitted when the system fee value (single-chain swaps) is set
     * @param systemFeeLocal The system fee value in milli-percent, e.g., 100 is 0.1%
     */
    event SetSystemFeeLocal(uint256 systemFeeLocal);

    /**
     * @notice Emitted when the address of the cross-chain action fee collector is set
     * @param feeCollector The address of the cross-chain action fee collector
     */
    event SetFeeCollector(address indexed feeCollector);

    /**
     * @notice Emitted when the address of the single-chain action fee collector is set
     * @param feeCollector The address of the single-chain action fee collector
     */
    event SetFeeCollectorLocal(address indexed feeCollector);

    /**
     * @notice Emitted when the whitelist is updated
     * @param whitelistAddress The added or removed account address
     * @param value The flag of account inclusion
     */
    event SetWhitelist(address indexed whitelistAddress, bool indexed value);

    /**
     * @notice Emitted when the minimum cross-chain swap amount is set
     * @param value The minimum swap amount in USD, with decimals = 18
     */
    event SetSwapAmountMin(uint256 value);

    /**
     * @notice Emitted when the maximum cross-chain swap amount is set
     * @dev Is type(uint256).max for unlimited amount
     * @param value The maximum swap amount in USD, with decimals = 18
     */
    event SetSwapAmountMax(uint256 value);

    /**
     * @notice Emitted when the specified cross-chain gateway address is duplicate
     */
    error DuplicateGatewayAddressError();

    /**
     * @notice Emitted when the requested cross-chain gateway type is not set
     */
    error GatewayNotSetError();

    /**
     * @notice Emitted when the requested swap router type is not set
     */
    error RouterNotSetError();

    /**
     * @notice Emitted when the specified swap amount maximum is less than the current minimum
     */
    error SwapAmountMaxLessThanMinError();

    /**
     * @notice Emitted when the specified swap amount minimum is greater than the current maximum
     */
    error SwapAmountMinGreaterThanMaxError();

    /**
     * @notice Emitted when the specified system fee percentage value is greater than the allowed maximum
     */
    error SystemFeeValueError();

    /**
     * @notice Emitted when the requested vault type is not set
     */
    error VaultNotSetError();

    /**
     * @notice Deploys the ActionExecutorRegistry contract
     * @param _gateways Initial values of cross-chain gateway types and addresses
     * @param _feeCollector The initial address of the cross-chain action fee collector
     * @param _feeCollectorLocal The initial address of the single-chain action fee collector
     * @param _targetGasReserve The initial gas reserve value for target chain action processing
     * @param _owner The address of the initial owner of the contract
     * @param _managers The addresses of initial managers of the contract
     * @param _addOwnerToManagers The flag to optionally add the owner to the list of managers
     */
    constructor(
        DataStructures.KeyToAddressValue[] memory _gateways,
        address _feeCollector,
        address _feeCollectorLocal,
        uint256 _targetGasReserve,
        address _owner,
        address[] memory _managers,
        bool _addOwnerToManagers
    ) {
        for (uint256 index; index < _gateways.length; index++) {
            DataStructures.KeyToAddressValue memory item = _gateways[index];

            _setGateway(item.key, item.value);
        }

        _setSystemFee(SYSTEM_FEE_INITIAL);
        _setSystemFeeLocal(SYSTEM_FEE_INITIAL);

        _setFeeCollector(_feeCollector);
        _setFeeCollectorLocal(_feeCollectorLocal);

        _setTargetGasReserve(_targetGasReserve);

        _initRoles(_owner, _managers, _addOwnerToManagers);
    }

    /**
     * @notice Adds or updates a registered cross-chain gateway contract address
     * @param _gatewayType The type of the registered cross-chain gateway
     * @param _gatewayAddress The address of the registered cross-chain gateway contract
     */
    function setGateway(uint256 _gatewayType, address _gatewayAddress) external onlyManager {
        _setGateway(_gatewayType, _gatewayAddress);
    }

    /**
     * @notice Removes a registered cross-chain gateway contract address
     * @param _gatewayType The type of the removed cross-chain gateway
     */
    function removeGateway(uint256 _gatewayType) external onlyManager {
        address gatewayAddress = gatewayMap[_gatewayType];

        if (gatewayAddress == address(0)) {
            revert GatewayNotSetError();
        }

        DataStructures.combinedMapRemove(
            gatewayMap,
            gatewayTypeList,
            gatewayTypeIndexMap,
            _gatewayType
        );

        delete isGatewayAddress[gatewayAddress];

        emit RemoveGateway(_gatewayType);
    }

    /**
     * @notice Adds or updates registered swap router contract addresses
     * @param _routers Types and addresses of swap routers
     */
    function setRouters(DataStructures.KeyToAddressValue[] calldata _routers) external onlyManager {
        for (uint256 index; index < _routers.length; index++) {
            DataStructures.KeyToAddressValue calldata item = _routers[index];

            _setRouter(item.key, item.value);
        }
    }

    /**
     * @notice Removes registered swap router contract addresses
     * @param _routerTypes Types of swap routers
     */
    function removeRouters(uint256[] calldata _routerTypes) external onlyManager {
        for (uint256 index; index < _routerTypes.length; index++) {
            uint256 routerType = _routerTypes[index];

            _removeRouter(routerType);
        }
    }

    /**
     * @notice Adds or updates a registered swap router transfer contract address
     * @dev Zero address can be used to remove a router transfer contract
     * @param _routerType The type of the swap router
     * @param _routerTransfer The address of the swap router transfer contract
     */
    function setRouterTransfer(uint256 _routerType, address _routerTransfer) external onlyManager {
        if (routerMap[_routerType] == address(0)) {
            revert RouterNotSetError();
        }

        AddressHelper.requireContractOrZeroAddress(_routerTransfer);

        routerTransferMap[_routerType] = _routerTransfer;

        emit SetRouterTransfer(_routerType, _routerTransfer);
    }

    /**
     * @notice Adds or updates a registered vault contract address
     * @param _vaultType The type of the registered vault
     * @param _vaultAddress The address of the registered vault contract
     */
    function setVault(uint256 _vaultType, address _vaultAddress) external onlyManager {
        AddressHelper.requireContract(_vaultAddress);

        DataStructures.combinedMapSet(
            vaultMap,
            vaultTypeList,
            vaultTypeIndexMap,
            _vaultType,
            _vaultAddress,
            Constants.LIST_SIZE_LIMIT_DEFAULT
        );

        emit SetVault(_vaultType, _vaultAddress);
    }

    /**
     * @notice Removes a registered vault contract address
     * @param _vaultType The type of the registered vault
     */
    function removeVault(uint256 _vaultType) external onlyManager {
        DataStructures.combinedMapRemove(vaultMap, vaultTypeList, vaultTypeIndexMap, _vaultType);

        // - - - Vault decimals table cleanup - - -

        delete vaultDecimalsTable[_vaultType][VAULT_DECIMALS_CHAIN_ID_WILDCARD];

        uint256 chainIdListLength = vaultDecimalsChainIdList.length;

        for (uint256 index; index < chainIdListLength; index++) {
            uint256 chainId = vaultDecimalsChainIdList[index];

            delete vaultDecimalsTable[_vaultType][chainId];
        }

        // - - -

        emit RemoveVault(_vaultType);
    }

    /**
     * @notice Sets vault decimal values
     * @param _vaultType The type of the vault
     * @param _decimalsData The vault decimal values
     */
    function setVaultDecimals(
        uint256 _vaultType,
        DataStructures.KeyToValue[] calldata _decimalsData
    ) external onlyManager {
        if (vaultMap[_vaultType] == address(0)) {
            revert VaultNotSetError();
        }

        for (uint256 index; index < _decimalsData.length; index++) {
            DataStructures.KeyToValue calldata decimalsDataItem = _decimalsData[index];

            uint256 chainId = decimalsDataItem.key;

            if (chainId != VAULT_DECIMALS_CHAIN_ID_WILDCARD) {
                DataStructures.uniqueListAdd(
                    vaultDecimalsChainIdList,
                    vaultDecimalsChainIdIndexMap,
                    chainId,
                    Constants.LIST_SIZE_LIMIT_DEFAULT
                );
            }

            vaultDecimalsTable[_vaultType][chainId] = DataStructures.OptionalValue(
                true,
                decimalsDataItem.value
            );
        }

        emit SetVaultDecimals(_vaultType, _decimalsData);
    }

    /**
     * @notice Unsets vault decimal values
     * @param _vaultType The type of the vault
     * @param _chainIds Chain IDs of registered vault decimal values
     */
    function unsetVaultDecimals(
        uint256 _vaultType,
        uint256[] calldata _chainIds
    ) external onlyManager {
        if (vaultMap[_vaultType] == address(0)) {
            revert VaultNotSetError();
        }

        for (uint256 index; index < _chainIds.length; index++) {
            uint256 chainId = _chainIds[index];
            delete vaultDecimalsTable[_vaultType][chainId];
        }

        emit UnsetVaultDecimals(_vaultType, _chainIds);
    }

    /**
     * @notice Sets the system fee value (cross-chain swaps)
     * @param _systemFee The system fee value in milli-percent, e.g., 100 is 0.1%
     */
    function setSystemFee(uint256 _systemFee) external onlyManager {
        _setSystemFee(_systemFee);
    }

    /**
     * @notice Sets the system fee value (single-chain swaps)
     * @param _systemFeeLocal The system fee value in milli-percent, e.g., 100 is 0.1%
     */
    function setSystemFeeLocal(uint256 _systemFeeLocal) external onlyManager {
        _setSystemFeeLocal(_systemFeeLocal);
    }

    /**
     * @notice Sets the address of the cross-chain action fee collector
     * @param _feeCollector The address of the cross-chain action fee collector
     */
    function setFeeCollector(address _feeCollector) external onlyManager {
        _setFeeCollector(_feeCollector);
    }

    /**
     * @notice Sets the address of the single-chain action fee collector
     * @param _feeCollector The address of the single-chain action fee collector
     */
    function setFeeCollectorLocal(address _feeCollector) external onlyManager {
        _setFeeCollectorLocal(_feeCollector);
    }

    /**
     * @notice Updates the whitelist
     * @param _whitelistAddress The added or removed account address
     * @param _value The flag of account inclusion
     */
    function setWhitelist(address _whitelistAddress, bool _value) external onlyManager {
        DataStructures.uniqueAddressListUpdate(
            whitelist,
            whitelistIndexMap,
            _whitelistAddress,
            _value,
            Constants.LIST_SIZE_LIMIT_DEFAULT
        );

        emit SetWhitelist(_whitelistAddress, _value);
    }

    /**
     * @notice Sets the minimum cross-chain swap amount
     * @param _value The minimum swap amount in USD, with decimals = 18
     */
    function setSwapAmountMin(uint256 _value) external onlyManager {
        if (_value > swapAmountMax) {
            revert SwapAmountMinGreaterThanMaxError();
        }

        swapAmountMin = _value;

        emit SetSwapAmountMin(_value);
    }

    /**
     * @notice Sets the maximum cross-chain swap amount
     * @dev Use type(uint256).max value for unlimited amount
     * @param _value The maximum swap amount in USD, with decimals = 18
     */
    function setSwapAmountMax(uint256 _value) external onlyManager {
        if (_value < swapAmountMin) {
            revert SwapAmountMaxLessThanMinError();
        }

        swapAmountMax = _value;

        emit SetSwapAmountMax(_value);
    }

    /**
     * @notice Settings for a single-chain swap
     * @param _caller The user's account address
     * @param _routerType The type of the swap router
     * @return Settings for a single-chain swap
     */
    function localSettings(
        address _caller,
        uint256 _routerType
    ) external view returns (LocalSettings memory) {
        (address router, address routerTransfer) = _routerAddresses(_routerType);

        return
            LocalSettings({
                router: router,
                routerTransfer: routerTransfer,
                systemFeeLocal: systemFeeLocal,
                feeCollectorLocal: feeCollectorLocal,
                isWhitelist: isWhitelist(_caller)
            });
    }

    /**
     * @notice Getter of source chain settings for a cross-chain swap
     * @param _caller The user's account address
     * @param _targetChainId The target chain ID
     * @param _gatewayType The type of the cross-chain gateway
     * @param _routerType The type of the swap router
     * @param _vaultType The type of the vault
     * @return Source chain settings for a cross-chain swap
     */
    function sourceSettings(
        address _caller,
        uint256 _targetChainId,
        uint256 _gatewayType,
        uint256 _routerType,
        uint256 _vaultType
    ) external view returns (SourceSettings memory) {
        (address router, address routerTransfer) = _routerAddresses(_routerType);

        return
            SourceSettings({
                gateway: gatewayMap[_gatewayType],
                router: router,
                routerTransfer: routerTransfer,
                vault: vaultMap[_vaultType],
                sourceVaultDecimals: vaultDecimals(_vaultType, block.chainid),
                targetVaultDecimals: vaultDecimals(_vaultType, _targetChainId),
                systemFee: systemFee,
                feeCollector: feeCollector,
                isWhitelist: isWhitelist(_caller),
                swapAmountMin: swapAmountMin,
                swapAmountMax: swapAmountMax
            });
    }

    /**
     * @notice Getter of target chain settings for a cross-chain swap
     * @param _vaultType The type of the vault
     * @param _routerType The type of the swap router
     * @return Target chain settings for a cross-chain swap
     */
    function targetSettings(
        uint256 _vaultType,
        uint256 _routerType
    ) external view returns (TargetSettings memory) {
        (address router, address routerTransfer) = _routerAddresses(_routerType);

        return
            TargetSettings({
                router: router,
                routerTransfer: routerTransfer,
                vault: vaultMap[_vaultType],
                gasReserve: targetGasReserve
            });
    }

    /**
     * @notice Getter of variable balance repayment settings
     * @param _vaultType The type of the vault
     * @return Variable balance repayment settings
     */
    function variableBalanceRepaymentSettings(
        uint256 _vaultType
    ) external view returns (VariableBalanceRepaymentSettings memory) {
        return VariableBalanceRepaymentSettings({ vault: vaultMap[_vaultType] });
    }

    /**
     * @notice Getter of cross-chain message fee estimation settings
     * @param _gatewayType The type of the cross-chain gateway
     * @return Cross-chain message fee estimation settings
     */
    function messageFeeEstimateSettings(
        uint256 _gatewayType
    ) external view returns (MessageFeeEstimateSettings memory) {
        return MessageFeeEstimateSettings({ gateway: gatewayMap[_gatewayType] });
    }

    /**
     * @notice Getter of swap result calculation settings for a single-chain swap
     * @param _caller The user's account address
     * @return Swap result calculation settings for a single-chain swap
     */
    function localAmountCalculationSettings(
        address _caller
    ) external view returns (LocalAmountCalculationSettings memory) {
        return
            LocalAmountCalculationSettings({
                systemFeeLocal: systemFeeLocal,
                isWhitelist: isWhitelist(_caller)
            });
    }

    /**
     * @notice Getter of swap result calculation settings for a cross-chain swap
     * @param _caller The user's account address
     * @param _vaultType The type of the vault
     * @param _fromChainId The ID of the swap source chain
     * @param _toChainId The ID of the swap target chain
     * @return Swap result calculation settings for a cross-chain swap
     */
    function vaultAmountCalculationSettings(
        address _caller,
        uint256 _vaultType,
        uint256 _fromChainId,
        uint256 _toChainId
    ) external view returns (VaultAmountCalculationSettings memory) {
        return
            VaultAmountCalculationSettings({
                fromDecimals: vaultDecimals(_vaultType, _fromChainId),
                toDecimals: vaultDecimals(_vaultType, _toChainId),
                systemFee: systemFee,
                isWhitelist: isWhitelist(_caller)
            });
    }

    /**
     * @notice Getter of amount limits in USD for cross-chain swaps
     * @param _vaultType The type of the vault
     * @return min Minimum cross-chain swap amount in USD, with decimals = 18
     * @return max Maximum cross-chain swap amount in USD, with decimals = 18
     */
    function swapAmountLimits(uint256 _vaultType) external view returns (uint256 min, uint256 max) {
        if (swapAmountMin == 0 && swapAmountMax == Constants.INFINITY) {
            min = 0;
            max = Constants.INFINITY;
        } else {
            uint256 toDecimals = vaultDecimals(_vaultType, block.chainid);

            min = (swapAmountMin == 0)
                ? 0
                : DecimalsHelper.convertDecimals(
                    Constants.DECIMALS_DEFAULT,
                    toDecimals,
                    swapAmountMin
                );

            max = (swapAmountMax == Constants.INFINITY)
                ? Constants.INFINITY
                : DecimalsHelper.convertDecimals(
                    Constants.DECIMALS_DEFAULT,
                    toDecimals,
                    swapAmountMax
                );
        }
    }

    /**
     * @notice Getter of registered cross-chain gateway type count
     * @return Registered cross-chain gateway type count
     */
    function gatewayTypeCount() external view returns (uint256) {
        return gatewayTypeList.length;
    }

    /**
     * @notice Getter of the complete list of registered cross-chain gateway types
     * @return The complete list of registered cross-chain gateway types
     */
    function fullGatewayTypeList() external view returns (uint256[] memory) {
        return gatewayTypeList;
    }

    /**
     * @notice Getter of registered swap router type count
     * @return Registered swap router type count
     */
    function routerTypeCount() external view returns (uint256) {
        return routerTypeList.length;
    }

    /**
     * @notice Getter of the complete list of registered swap router types
     * @return The complete list of registered swap router types
     */
    function fullRouterTypeList() external view returns (uint256[] memory) {
        return routerTypeList;
    }

    /**
     * @notice Getter of registered vault type count
     * @return Registered vault type count
     */
    function vaultTypeCount() external view returns (uint256) {
        return vaultTypeList.length;
    }

    /**
     * @notice Getter of the complete list of registered vault types
     * @return The complete list of registered vault types
     */
    function fullVaultTypeList() external view returns (uint256[] memory) {
        return vaultTypeList;
    }

    /**
     * @notice Getter of registered vault decimals chain ID count
     * @return Registered vault decimals chain ID count
     */
    function vaultDecimalsChainIdCount() external view returns (uint256) {
        return vaultDecimalsChainIdList.length;
    }

    /**
     * @notice Getter of the complete list of registered vault decimals chain IDs
     * @return The complete list of registered vault decimals chain IDs
     */
    function fullVaultDecimalsChainIdList() external view returns (uint256[] memory) {
        return vaultDecimalsChainIdList;
    }

    /**
     * @notice Getter of registered whitelist entry count
     * @return Registered whitelist entry count
     */
    function whitelistCount() external view returns (uint256) {
        return whitelist.length;
    }

    /**
     * @notice Getter of the full whitelist content
     * @return Full whitelist content
     */
    function fullWhitelist() external view returns (address[] memory) {
        return whitelist;
    }

    /**
     * @notice Getter of a whitelist flag
     * @param _account The account address
     * @return The whitelist flag
     */
    function isWhitelist(address _account) public view returns (bool) {
        return whitelistIndexMap[_account].isSet;
    }

    /**
     * @notice Getter of vault decimals value
     * @param _vaultType The type of the vault
     * @param _chainId The vault chain ID
     * @return Vault decimals value
     */
    function vaultDecimals(uint256 _vaultType, uint256 _chainId) public view returns (uint256) {
        DataStructures.OptionalValue storage optionalValue = vaultDecimalsTable[_vaultType][
            _chainId
        ];

        if (optionalValue.isSet) {
            return optionalValue.value;
        }

        DataStructures.OptionalValue storage wildcardOptionalValue = vaultDecimalsTable[_vaultType][
            VAULT_DECIMALS_CHAIN_ID_WILDCARD
        ];

        if (wildcardOptionalValue.isSet) {
            return wildcardOptionalValue.value;
        }

        return Constants.DECIMALS_DEFAULT;
    }

    function _setGateway(uint256 _gatewayType, address _gatewayAddress) private {
        AddressHelper.requireContract(_gatewayAddress);

        if (isGatewayAddress[_gatewayAddress] && gatewayMap[_gatewayType] != _gatewayAddress) {
            revert DuplicateGatewayAddressError();
        }

        DataStructures.combinedMapSet(
            gatewayMap,
            gatewayTypeList,
            gatewayTypeIndexMap,
            _gatewayType,
            _gatewayAddress,
            Constants.LIST_SIZE_LIMIT_DEFAULT
        );

        isGatewayAddress[_gatewayAddress] = true;

        emit SetGateway(_gatewayType, _gatewayAddress);
    }

    function _setRouter(uint256 _routerType, address _routerAddress) private {
        AddressHelper.requireContract(_routerAddress);

        DataStructures.combinedMapSet(
            routerMap,
            routerTypeList,
            routerTypeIndexMap,
            _routerType,
            _routerAddress,
            Constants.LIST_SIZE_LIMIT_ROUTERS
        );

        emit SetRouter(_routerType, _routerAddress);
    }

    function _removeRouter(uint256 _routerType) private {
        DataStructures.combinedMapRemove(
            routerMap,
            routerTypeList,
            routerTypeIndexMap,
            _routerType
        );

        delete routerTransferMap[_routerType];

        emit RemoveRouter(_routerType);
    }

    function _setSystemFee(uint256 _systemFee) private {
        if (_systemFee > SYSTEM_FEE_LIMIT) {
            revert SystemFeeValueError();
        }

        systemFee = _systemFee;

        emit SetSystemFee(_systemFee);
    }

    function _setSystemFeeLocal(uint256 _systemFeeLocal) private {
        if (_systemFeeLocal > SYSTEM_FEE_LIMIT) {
            revert SystemFeeValueError();
        }

        systemFeeLocal = _systemFeeLocal;

        emit SetSystemFeeLocal(_systemFeeLocal);
    }

    function _setFeeCollector(address _feeCollector) private {
        feeCollector = _feeCollector;

        emit SetFeeCollector(_feeCollector);
    }

    function _setFeeCollectorLocal(address _feeCollector) private {
        feeCollectorLocal = _feeCollector;

        emit SetFeeCollectorLocal(_feeCollector);
    }

    function _routerAddresses(
        uint256 _routerType
    ) private view returns (address router, address routerTransfer) {
        router = routerMap[_routerType];
        routerTransfer = routerTransferMap[_routerType];

        if (routerTransfer == address(0)) {
            routerTransfer = router;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { ITokenBalance } from './interfaces/ITokenBalance.sol';
import { ManagerRole } from './roles/ManagerRole.sol';
import './helpers/TransferHelper.sol' as TransferHelper;
import './Constants.sol' as Constants;

/**
 * @title BalanceManagement
 * @notice Base contract for the withdrawal of tokens, except for reserved ones
 */
abstract contract BalanceManagement is ManagerRole {
    /**
     * @notice Emitted when the specified token is reserved
     */
    error ReservedTokenError();

    /**
     * @notice Performs the withdrawal of tokens, except for reserved ones
     * @dev Use the "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE" address for the native token
     * @param _tokenAddress The address of the token
     * @param _tokenAmount The amount of the token
     */
    function cleanup(address _tokenAddress, uint256 _tokenAmount) external onlyManager {
        if (isReservedToken(_tokenAddress)) {
            revert ReservedTokenError();
        }

        if (_tokenAddress == Constants.NATIVE_TOKEN_ADDRESS) {
            TransferHelper.safeTransferNative(msg.sender, _tokenAmount);
        } else {
            TransferHelper.safeTransfer(_tokenAddress, msg.sender, _tokenAmount);
        }
    }

    /**
     * @notice Getter of the token balance of the current contract
     * @dev Use the "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE" address for the native token
     * @param _tokenAddress The address of the token
     * @return The token balance of the current contract
     */
    function tokenBalance(address _tokenAddress) public view returns (uint256) {
        if (_tokenAddress == Constants.NATIVE_TOKEN_ADDRESS) {
            return address(this).balance;
        } else {
            return ITokenBalance(_tokenAddress).balanceOf(address(this));
        }
    }

    /**
     * @notice Getter of the reserved token flag
     * @dev Override to add reserved token addresses
     * @param _tokenAddress The address of the token
     * @return The reserved token flag
     */
    function isReservedToken(address _tokenAddress) public view virtual returns (bool) {
        // The function returns false by default.
        // The explicit return statement is omitted to avoid the unused parameter warning.
        // See https://github.com/ethereum/solidity/issues/5295
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @dev The default token decimals value
 */
uint256 constant DECIMALS_DEFAULT = 18;

/**
 * @dev The maximum uint256 value for swap amount limit settings
 */
uint256 constant INFINITY = type(uint256).max;

/**
 * @dev The default limit of account list size
 */
uint256 constant LIST_SIZE_LIMIT_DEFAULT = 100;

/**
 * @dev The limit of swap router list size
 */
uint256 constant LIST_SIZE_LIMIT_ROUTERS = 200;

/**
 * @dev The factor for percentage settings. Example: 100 is 0.1%
 */
uint256 constant MILLIPERCENT_FACTOR = 100_000;

/**
 * @dev The de facto standard address to denote the native token
 */
address constant NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { ManagerRole } from '../roles/ManagerRole.sol';

/**
 * @title TargetGasReserve
 * @notice Base contract that implements the gas reserve logic for the target chain actions
 */
abstract contract TargetGasReserve is ManagerRole {
    /**
     * @dev The target chain gas reserve value
     */
    uint256 public targetGasReserve;

    /**
     * @notice Emitted when the target chain gas reserve value is set
     * @param gasReserve The target chain gas reserve value
     */
    event SetTargetGasReserve(uint256 gasReserve);

    /**
     * @notice Sets the target chain gas reserve value
     * @param _gasReserve The target chain gas reserve value
     */
    function setTargetGasReserve(uint256 _gasReserve) external onlyManager {
        _setTargetGasReserve(_gasReserve);
    }

    function _setTargetGasReserve(uint256 _gasReserve) internal virtual {
        targetGasReserve = _gasReserve;

        emit SetTargetGasReserve(_gasReserve);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @notice Optional value structure
 * @dev Is used in mappings to allow zero values
 * @param isSet Value presence flag
 * @param value Numeric value
 */
struct OptionalValue {
    bool isSet;
    uint256 value;
}

/**
 * @notice Key-to-value structure
 * @dev Is used as an array parameter item to perform multiple key-value settings
 * @param key Numeric key
 * @param value Numeric value
 */
struct KeyToValue {
    uint256 key;
    uint256 value;
}

/**
 * @notice Key-to-value structure for address values
 * @dev Is used as an array parameter item to perform multiple key-value settings with address values
 * @param key Numeric key
 * @param value Address value
 */
struct KeyToAddressValue {
    uint256 key;
    address value;
}

/**
 * @notice Address-to-flag structure
 * @dev Is used as an array parameter item to perform multiple settings
 * @param account Account address
 * @param flag Flag value
 */
struct AccountToFlag {
    address account;
    bool flag;
}

/**
 * @notice Emitted when a list exceeds the size limit
 */
error ListSizeLimitError();

/**
 * @notice Sets or updates a value in a combined map (a mapping with a key list and key index mapping)
 * @param _map The mapping reference
 * @param _keyList The key list reference
 * @param _keyIndexMap The key list index mapping reference
 * @param _key The numeric key
 * @param _value The address value
 * @param _sizeLimit The map and list size limit
 * @return isNewKey True if the key was just added, otherwise false
 */
function combinedMapSet(
    mapping(uint256 => address) storage _map,
    uint256[] storage _keyList,
    mapping(uint256 => OptionalValue) storage _keyIndexMap,
    uint256 _key,
    address _value,
    uint256 _sizeLimit
) returns (bool isNewKey) {
    isNewKey = !_keyIndexMap[_key].isSet;

    if (isNewKey) {
        uniqueListAdd(_keyList, _keyIndexMap, _key, _sizeLimit);
    }

    _map[_key] = _value;
}

/**
 * @notice Removes a value from a combined map (a mapping with a key list and key index mapping)
 * @param _map The mapping reference
 * @param _keyList The key list reference
 * @param _keyIndexMap The key list index mapping reference
 * @param _key The numeric key
 * @return isChanged True if the combined map was changed, otherwise false
 */
function combinedMapRemove(
    mapping(uint256 => address) storage _map,
    uint256[] storage _keyList,
    mapping(uint256 => OptionalValue) storage _keyIndexMap,
    uint256 _key
) returns (bool isChanged) {
    isChanged = _keyIndexMap[_key].isSet;

    if (isChanged) {
        delete _map[_key];
        uniqueListRemove(_keyList, _keyIndexMap, _key);
    }
}

/**
 * @notice Adds a value to a unique value list (a list with value index mapping)
 * @param _list The list reference
 * @param _indexMap The value index mapping reference
 * @param _value The numeric value
 * @param _sizeLimit The list size limit
 * @return isChanged True if the list was changed, otherwise false
 */
function uniqueListAdd(
    uint256[] storage _list,
    mapping(uint256 => OptionalValue) storage _indexMap,
    uint256 _value,
    uint256 _sizeLimit
) returns (bool isChanged) {
    isChanged = !_indexMap[_value].isSet;

    if (isChanged) {
        if (_list.length >= _sizeLimit) {
            revert ListSizeLimitError();
        }

        _indexMap[_value] = OptionalValue(true, _list.length);
        _list.push(_value);
    }
}

/**
 * @notice Removes a value from a unique value list (a list with value index mapping)
 * @param _list The list reference
 * @param _indexMap The value index mapping reference
 * @param _value The numeric value
 * @return isChanged True if the list was changed, otherwise false
 */
function uniqueListRemove(
    uint256[] storage _list,
    mapping(uint256 => OptionalValue) storage _indexMap,
    uint256 _value
) returns (bool isChanged) {
    OptionalValue storage indexItem = _indexMap[_value];

    isChanged = indexItem.isSet;

    if (isChanged) {
        uint256 itemIndex = indexItem.value;
        uint256 lastIndex = _list.length - 1;

        if (itemIndex != lastIndex) {
            uint256 lastValue = _list[lastIndex];
            _list[itemIndex] = lastValue;
            _indexMap[lastValue].value = itemIndex;
        }

        _list.pop();
        delete _indexMap[_value];
    }
}

/**
 * @notice Adds a value to a unique address value list (a list with value index mapping)
 * @param _list The list reference
 * @param _indexMap The value index mapping reference
 * @param _value The address value
 * @param _sizeLimit The list size limit
 * @return isChanged True if the list was changed, otherwise false
 */
function uniqueAddressListAdd(
    address[] storage _list,
    mapping(address => OptionalValue) storage _indexMap,
    address _value,
    uint256 _sizeLimit
) returns (bool isChanged) {
    isChanged = !_indexMap[_value].isSet;

    if (isChanged) {
        if (_list.length >= _sizeLimit) {
            revert ListSizeLimitError();
        }

        _indexMap[_value] = OptionalValue(true, _list.length);
        _list.push(_value);
    }
}

/**
 * @notice Removes a value from a unique address value list (a list with value index mapping)
 * @param _list The list reference
 * @param _indexMap The value index mapping reference
 * @param _value The address value
 * @return isChanged True if the list was changed, otherwise false
 */
function uniqueAddressListRemove(
    address[] storage _list,
    mapping(address => OptionalValue) storage _indexMap,
    address _value
) returns (bool isChanged) {
    OptionalValue storage indexItem = _indexMap[_value];

    isChanged = indexItem.isSet;

    if (isChanged) {
        uint256 itemIndex = indexItem.value;
        uint256 lastIndex = _list.length - 1;

        if (itemIndex != lastIndex) {
            address lastValue = _list[lastIndex];
            _list[itemIndex] = lastValue;
            _indexMap[lastValue].value = itemIndex;
        }

        _list.pop();
        delete _indexMap[_value];
    }
}

/**
 * @notice Adds or removes a value to/from a unique address value list (a list with value index mapping)
 * @dev The list size limit is checked on items adding only
 * @param _list The list reference
 * @param _indexMap The value index mapping reference
 * @param _value The address value
 * @param _flag The value inclusion flag
 * @param _sizeLimit The list size limit
 * @return isChanged True if the list was changed, otherwise false
 */
function uniqueAddressListUpdate(
    address[] storage _list,
    mapping(address => OptionalValue) storage _indexMap,
    address _value,
    bool _flag,
    uint256 _sizeLimit
) returns (bool isChanged) {
    return
        _flag
            ? uniqueAddressListAdd(_list, _indexMap, _value, _sizeLimit)
            : uniqueAddressListRemove(_list, _indexMap, _value);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @notice Emitted when an attempt to burn a token fails
 */
error TokenBurnError();

/**
 * @notice Emitted when an attempt to mint a token fails
 */
error TokenMintError();

/**
 * @notice Emitted when a zero address is specified where it is not allowed
 */
error ZeroAddressError();

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @notice Emitted when the account is not a contract
 * @param account The account address
 */
error NonContractAddressError(address account);

/**
 * @notice Function to check if the account is a contract
 * @return The account contract status flag
 */
function isContract(address _account) view returns (bool) {
    return _account.code.length > 0;
}

/**
 * @notice Function to require an account to be a contract
 */
function requireContract(address _account) view {
    if (!isContract(_account)) {
        revert NonContractAddressError(_account);
    }
}

/**
 * @notice Function to require an account to be a contract or a zero address
 */
function requireContractOrZeroAddress(address _account) view {
    if (_account != address(0)) {
        requireContract(_account);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @notice Function to perform decimals conversion
 * @param _fromDecimals Source value decimals
 * @param _toDecimals Target value decimals
 * @param _fromAmount Source value
 * @return Target value
 */
function convertDecimals(
    uint256 _fromDecimals,
    uint256 _toDecimals,
    uint256 _fromAmount
) pure returns (uint256) {
    if (_toDecimals == _fromDecimals) {
        return _fromAmount;
    } else if (_toDecimals > _fromDecimals) {
        return _fromAmount * 10 ** (_toDecimals - _fromDecimals);
    } else {
        return _fromAmount / 10 ** (_fromDecimals - _toDecimals);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @notice Emitted when an approval action fails
 */
error SafeApproveError();

/**
 * @notice Emitted when a transfer action fails
 */
error SafeTransferError();

/**
 * @notice Emitted when a transferFrom action fails
 */
error SafeTransferFromError();

/**
 * @notice Emitted when a transfer of the native token fails
 */
error SafeTransferNativeError();

/**
 * @notice Safely approve the token to the account
 * @param _token The token address
 * @param _to The token approval recipient address
 * @param _value The token approval amount
 */
function safeApprove(address _token, address _to, uint256 _value) {
    // 0x095ea7b3 is the selector for "approve(address,uint256)"
    (bool success, bytes memory data) = _token.call(
        abi.encodeWithSelector(0x095ea7b3, _to, _value)
    );

    bool condition = success && (data.length == 0 || abi.decode(data, (bool)));

    if (!condition) {
        revert SafeApproveError();
    }
}

/**
 * @notice Safely transfer the token to the account
 * @param _token The token address
 * @param _to The token transfer recipient address
 * @param _value The token transfer amount
 */
function safeTransfer(address _token, address _to, uint256 _value) {
    // 0xa9059cbb is the selector for "transfer(address,uint256)"
    (bool success, bytes memory data) = _token.call(
        abi.encodeWithSelector(0xa9059cbb, _to, _value)
    );

    bool condition = success && (data.length == 0 || abi.decode(data, (bool)));

    if (!condition) {
        revert SafeTransferError();
    }
}

/**
 * @notice Safely transfer the token between the accounts
 * @param _token The token address
 * @param _from The token transfer source address
 * @param _to The token transfer recipient address
 * @param _value The token transfer amount
 */
function safeTransferFrom(address _token, address _from, address _to, uint256 _value) {
    // 0x23b872dd is the selector for "transferFrom(address,address,uint256)"
    (bool success, bytes memory data) = _token.call(
        abi.encodeWithSelector(0x23b872dd, _from, _to, _value)
    );

    bool condition = success && (data.length == 0 || abi.decode(data, (bool)));

    if (!condition) {
        revert SafeTransferFromError();
    }
}

/**
 * @notice Safely transfer the native token to the account
 * @param _to The native token transfer recipient address
 * @param _value The native token transfer amount
 */
function safeTransferNative(address _to, uint256 _value) {
    (bool success, ) = _to.call{ value: _value }(new bytes(0));

    if (!success) {
        revert SafeTransferNativeError();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { ISettings } from './ISettings.sol';

interface IRegistry is ISettings {
    /**
     * @notice Getter of the registered gateway flag by the account address
     * @param _account The account address
     * @return The registered gateway flag
     */
    function isGatewayAddress(address _account) external view returns (bool);

    /**
     * @notice Settings for a single-chain swap
     * @param _caller The user's account address
     * @param _routerType The type of the swap router
     * @return Settings for a single-chain swap
     */
    function localSettings(
        address _caller,
        uint256 _routerType
    ) external view returns (LocalSettings memory);

    /**
     * @notice Getter of source chain settings for a cross-chain swap
     * @param _caller The user's account address
     * @param _targetChainId The target chain ID
     * @param _gatewayType The type of the cross-chain gateway
     * @param _routerType The type of the swap router
     * @param _vaultType The type of the vault
     * @return Source chain settings for a cross-chain swap
     */
    function sourceSettings(
        address _caller,
        uint256 _targetChainId,
        uint256 _gatewayType,
        uint256 _routerType,
        uint256 _vaultType
    ) external view returns (SourceSettings memory);

    /**
     * @notice Getter of target chain settings for a cross-chain swap
     * @param _vaultType The type of the vault
     * @param _routerType The type of the swap router
     * @return Target chain settings for a cross-chain swap
     */
    function targetSettings(
        uint256 _vaultType,
        uint256 _routerType
    ) external view returns (TargetSettings memory);

    /**
     * @notice Getter of variable balance repayment settings
     * @param _vaultType The type of the vault
     * @return Variable balance repayment settings
     */
    function variableBalanceRepaymentSettings(
        uint256 _vaultType
    ) external view returns (VariableBalanceRepaymentSettings memory);

    /**
     * @notice Getter of cross-chain message fee estimation settings
     * @param _gatewayType The type of the cross-chain gateway
     * @return Cross-chain message fee estimation settings
     */
    function messageFeeEstimateSettings(
        uint256 _gatewayType
    ) external view returns (MessageFeeEstimateSettings memory);

    /**
     * @notice Getter of swap result calculation settings for a single-chain swap
     * @param _caller The user's account address
     * @return Swap result calculation settings for a single-chain swap
     */
    function localAmountCalculationSettings(
        address _caller
    ) external view returns (LocalAmountCalculationSettings memory);

    /**
     * @notice Getter of swap result calculation settings for a cross-chain swap
     * @param _caller The user's account address
     * @param _vaultType The type of the vault
     * @param _fromChainId The ID of the swap source chain
     * @param _toChainId The ID of the swap target chain
     * @return Swap result calculation settings for a cross-chain swap
     */
    function vaultAmountCalculationSettings(
        address _caller,
        uint256 _vaultType,
        uint256 _fromChainId,
        uint256 _toChainId
    ) external view returns (VaultAmountCalculationSettings memory);

    /**
     * @notice Getter of amount limits in USD for cross-chain swaps
     * @param _vaultType The type of the vault
     * @return min Minimum cross-chain swap amount in USD, with decimals = 18
     * @return max Maximum cross-chain swap amount in USD, with decimals = 18
     */
    function swapAmountLimits(uint256 _vaultType) external view returns (uint256 min, uint256 max);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @title ISettings
 * @notice Settings data structure declarations
 */
interface ISettings {
    /**
     * @notice Settings for a single-chain swap
     * @param router The swap router contract address
     * @param routerTransfer The swap router transfer contract address
     * @param systemFeeLocal The system fee value in milli-percent, e.g., 100 is 0.1%
     * @param feeCollectorLocal The address of the single-chain action fee collector
     * @param isWhitelist The whitelist flag
     */
    struct LocalSettings {
        address router;
        address routerTransfer;
        uint256 systemFeeLocal;
        address feeCollectorLocal;
        bool isWhitelist;
    }

    /**
     * @notice Source chain settings for a cross-chain swap
     * @param gateway The cross-chain gateway contract address
     * @param router The swap router contract address
     * @param routerTransfer The swap router transfer contract address
     * @param vault The vault contract address
     * @param sourceVaultDecimals The value of the vault decimals on the source chain
     * @param targetVaultDecimals The value of the vault decimals on the target chain
     * @param systemFee The system fee value in milli-percent, e.g., 100 is 0.1%
     * @param feeCollector The address of the cross-chain action fee collector
     * @param isWhitelist The whitelist flag
     * @param swapAmountMin The minimum cross-chain swap amount in USD, with decimals = 18
     * @param swapAmountMax The maximum cross-chain swap amount in USD, with decimals = 18
     */
    struct SourceSettings {
        address gateway;
        address router;
        address routerTransfer;
        address vault;
        uint256 sourceVaultDecimals;
        uint256 targetVaultDecimals;
        uint256 systemFee;
        address feeCollector;
        bool isWhitelist;
        uint256 swapAmountMin;
        uint256 swapAmountMax;
    }

    /**
     * @notice Target chain settings for a cross-chain swap
     * @param router The swap router contract address
     * @param routerTransfer The swap router transfer contract address
     * @param vault The vault contract address
     * @param gasReserve The target chain gas reserve value
     */
    struct TargetSettings {
        address router;
        address routerTransfer;
        address vault;
        uint256 gasReserve;
    }

    /**
     * @notice Variable balance repayment settings
     * @param vault The vault contract address
     */
    struct VariableBalanceRepaymentSettings {
        address vault;
    }

    /**
     * @notice Cross-chain message fee estimation settings
     * @param gateway The cross-chain gateway contract address
     */
    struct MessageFeeEstimateSettings {
        address gateway;
    }

    /**
     * @notice Swap result calculation settings for a single-chain swap
     * @param systemFee The system fee value in milli-percent, e.g., 100 is 0.1%
     * @param isWhitelist The whitelist flag
     */
    struct LocalAmountCalculationSettings {
        uint256 systemFeeLocal;
        bool isWhitelist;
    }

    /**
     * @notice Swap result calculation settings for a cross-chain swap
     * @param fromDecimals The value of the vault decimals on the source chain
     * @param toDecimals The value of the vault decimals on the target chain
     * @param systemFee The system fee value in milli-percent, e.g., 100 is 0.1%
     * @param isWhitelist The whitelist flag
     */
    struct VaultAmountCalculationSettings {
        uint256 fromDecimals;
        uint256 toDecimals;
        uint256 systemFee;
        bool isWhitelist;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @title ITokenBalance
 * @notice Token balance interface
 */
interface ITokenBalance {
    /**
     * @notice Getter of the token balance by the account
     * @param _account The account address
     * @return Token balance
     */
    function balanceOf(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @title IVault
 * @notice Vault interface
 */
interface IVault {
    /**
     * @notice The getter of the vault asset address
     */
    function asset() external view returns (address);

    /**
     * @notice Checks the status of the variable token and balance actions and the variable token address
     * @return The address of the variable token
     */
    function checkVariableTokenState() external view returns (address);

    /**
     * @notice Requests the vault asset tokens
     * @param _amount The amount of the vault asset tokens
     * @param _to The address of the vault asset tokens receiver
     * @param _forVariableBalance True if the request is made for a variable balance repayment, otherwise false
     * @return assetAddress The address of the vault asset token
     */
    function requestAsset(
        uint256 _amount,
        address _to,
        bool _forVariableBalance
    ) external returns (address assetAddress);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { RoleBearers } from './RoleBearers.sol';

/**
 * @title ManagerRole
 * @notice Base contract that implements the Manager role.
 * The manager role is a high-permission role for core team members only.
 * Managers can set vaults and routers addresses, fees, cross-chain protocols,
 * and other parameters for Interchain (cross-chain) swaps and single-network swaps.
 * Please note, the manager role is unique for every contract,
 * hence different addresses may be assigned as managers for different contracts.
 */
abstract contract ManagerRole is Ownable, RoleBearers {
    bytes32 private constant ROLE_KEY = keccak256('Manager');

    /**
     * @notice Emitted when the Manager role status for the account is updated
     * @param account The account address
     * @param value The Manager role status flag
     */
    event SetManager(address indexed account, bool indexed value);

    /**
     * @notice Emitted when the Manager role status for the account is renounced
     * @param account The account address
     */
    event RenounceManagerRole(address indexed account);

    /**
     * @notice Emitted when the caller is not a Manager role bearer
     */
    error OnlyManagerError();

    /**
     * @dev Modifier to check if the caller is a Manager role bearer
     */
    modifier onlyManager() {
        if (!isManager(msg.sender)) {
            revert OnlyManagerError();
        }

        _;
    }

    /**
     * @notice Updates the Manager role status for the account
     * @param _account The account address
     * @param _value The Manager role status flag
     */
    function setManager(address _account, bool _value) public onlyOwner {
        _setRoleBearer(ROLE_KEY, _account, _value);

        emit SetManager(_account, _value);
    }

    /**
     * @notice Renounces the Manager role
     */
    function renounceManagerRole() external onlyManager {
        _setRoleBearer(ROLE_KEY, msg.sender, false);

        emit RenounceManagerRole(msg.sender);
    }

    /**
     * @notice Getter of the Manager role bearer count
     * @return The Manager role bearer count
     */
    function managerCount() external view returns (uint256) {
        return _roleBearerCount(ROLE_KEY);
    }

    /**
     * @notice Getter of the complete list of the Manager role bearers
     * @return The complete list of the Manager role bearers
     */
    function fullManagerList() external view returns (address[] memory) {
        return _fullRoleBearerList(ROLE_KEY);
    }

    /**
     * @notice Getter of the Manager role bearer status
     * @param _account The account address
     */
    function isManager(address _account) public view returns (bool) {
        return _isRoleBearer(ROLE_KEY, _account);
    }

    function _initRoles(
        address _owner,
        address[] memory _managers,
        bool _addOwnerToManagers
    ) internal {
        address ownerAddress = _owner == address(0) ? msg.sender : _owner;

        for (uint256 index; index < _managers.length; index++) {
            setManager(_managers[index], true);
        }

        if (_addOwnerToManagers && !isManager(ownerAddress)) {
            setManager(ownerAddress, true);
        }

        if (ownerAddress != msg.sender) {
            transferOwnership(ownerAddress);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import '../Constants.sol' as Constants;
import '../DataStructures.sol' as DataStructures;

/**
 * @title RoleBearers
 * @notice Base contract that implements role-based access control
 * @dev A custom implementation providing full role bearer lists
 */
abstract contract RoleBearers {
    mapping(bytes32 /*roleKey*/ => address[] /*roleBearers*/) private roleBearerTable;
    mapping(bytes32 /*roleKey*/ => mapping(address /*account*/ => DataStructures.OptionalValue /*status*/))
        private roleBearerIndexTable;

    function _setRoleBearer(bytes32 _roleKey, address _account, bool _value) internal {
        DataStructures.uniqueAddressListUpdate(
            roleBearerTable[_roleKey],
            roleBearerIndexTable[_roleKey],
            _account,
            _value,
            Constants.LIST_SIZE_LIMIT_DEFAULT
        );
    }

    function _isRoleBearer(bytes32 _roleKey, address _account) internal view returns (bool) {
        return roleBearerIndexTable[_roleKey][_account].isSet;
    }

    function _roleBearerCount(bytes32 _roleKey) internal view returns (uint256) {
        return roleBearerTable[_roleKey].length;
    }

    function _fullRoleBearerList(bytes32 _roleKey) internal view returns (address[] memory) {
        return roleBearerTable[_roleKey];
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @title SystemVersionId
 * @notice Base contract providing the system version identifier
 */
abstract contract SystemVersionId {
    /**
     * @dev The system version identifier
     */
    uint256 public constant SYSTEM_VERSION_ID = uint256(keccak256('Testnet - Initial B'));
}