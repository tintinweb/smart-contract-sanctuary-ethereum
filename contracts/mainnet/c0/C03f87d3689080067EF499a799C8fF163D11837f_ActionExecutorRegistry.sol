// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

import { IVault } from './interfaces/IVault.sol';
import { IRegistry } from './interfaces/IRegistry.sol';
import { DataStructures } from './DataStructures.sol';
import { BalanceManagement } from './BalanceManagement.sol';
import { ZeroAddressError } from './Errors.sol';


contract ActionExecutorRegistry is BalanceManagement, IRegistry {

    error GatewayNotSetError();
    error VaultNotSetError();
    error SwapAmountMinGreaterThanMaxError();
    error SwapAmountMaxLessThanMinError();
    error DuplicateGatewayAddressError();
    error SystemFeeValueError();

    uint256 public constant VAULT_DECIMALS_CHAIN_ID_WILDCARD = 0;

    mapping(uint256 => address) public gatewayMap;
    uint256[] public gatewayTypeList;
    mapping(uint256 => OptionalValue) public gatewayTypeIndexMap;
    mapping(uint256 => bool) public gatewayFallbackFlags;
    mapping(address => bool) public isGatewayAddress;

    mapping(uint256 => address) public routerMap;
    uint256[] public routerTypeList;
    mapping(uint256 => OptionalValue) public routerTypeIndexMap;

    mapping(uint256 => address) public vaultMap;
    uint256[] public vaultTypeList;
    mapping(uint256 => OptionalValue) public vaultTypeIndexMap;

    mapping(uint256 => mapping(uint256 => OptionalValue)) public vaultDecimalsTable; // Keys: vault type, chain id
    uint256[] public vaultDecimalsChainIdList;
    mapping(uint256 => OptionalValue) public vaultDecimalsChainIdIndexMap;

    uint256 public systemFee; // System fee in millipercent
    uint256 public fallbackFee; // Fallback fee in network's native currency
    address public feeCollector;
    address public feeCollectorLocal;
    address public feeCollectorForVariableToken;

    address[] public whitelist;
    mapping(address => OptionalValue) public whitelistIndexMap;

    // Swap amount limits with decimals = 18
    uint256 public swapAmountMin = 0;
    uint256 public swapAmountMax = INFINITY;

    uint256 private constant DECIMALS_DEFAULT = 18;
    uint256 private constant INFINITY = type(uint256).max;
    uint256 private constant MILLIPERCENT_FACTOR = 1e5;

    event SetGateway(uint256 indexed gatewayType, address indexed gatewayAddress, bool indexed useFallback);
    event SetUseGatewayFallback(uint256 indexed gatewayType, bool indexed useFallback);
    event RemoveGateway(uint256 indexed gatewayType);

    event SetVault(uint256 indexed vaultType, address indexed vault);
    event RemoveVault(uint256 indexed vaultType);

    event SetVaultDecimals(uint256 indexed vaultType, KeyToValue[] decimalsData);
    event UnsetVaultDecimals(uint256 indexed vaultType, uint256[] chainIds);

    event SetRouter(uint256 indexed routerType, address indexed routerAddress);
    event RemoveRouter(uint256 indexed routerType);

    event SetSystemFee(uint256 systemFee);
    event SetFallbackFee(uint256 fallbackFee);

    event SetFeeCollector(address indexed feeCollector);
    event SetFeeCollectorLocal(address indexed feeCollector);
    event SetFeeCollectorForVariableToken(address indexed feeCollector);

    event SetWhitelist(address indexed whitelistAddress, bool indexed value);

    event SetSwapAmountMin(uint256 value);
    event SetSwapAmountMax(uint256 value);

    constructor(
        KeyToAddressAndFlag[] memory _gateways,
        uint256 _systemFee, // System fee in millipercent
        address _feeCollector,
        address _feeCollectorLocal,
        address _feeCollectorForVariableToken,
        address _ownerAddress,
        bool _grantManagerRoleToOwner
    )
    {
        for (uint256 index; index < _gateways.length; index++) {
            KeyToAddressAndFlag memory item = _gateways[index];

            _setGateway(item.key, item.value, item.flag);
        }

        _setSystemFee(_systemFee);

        _setFeeCollector(_feeCollector);
        _setFeeCollectorLocal(_feeCollectorLocal);
        _setFeeCollectorForVariableToken(_feeCollectorForVariableToken);

        _initRoles(_ownerAddress, _grantManagerRoleToOwner);
    }

    function setGateway(uint256 _gatewayType, address _gatewayAddress, bool _useFallback) external onlyManager {
        _setGateway(_gatewayType, _gatewayAddress, _useFallback);
    }

    function setUseGatewayFallback(uint256 _gatewayType, bool _useFallback) external onlyManager {
        if (gatewayMap[_gatewayType] == address(0)) {
            revert GatewayNotSetError();
        }

        gatewayFallbackFlags[_gatewayType] = _useFallback;

        emit SetUseGatewayFallback(_gatewayType, _useFallback);
    }

    function removeGateway(uint256 _gatewayType) external onlyManager {
        address gatewayAddress = gatewayMap[_gatewayType];

        if (gatewayAddress == address(0)) {
            revert GatewayNotSetError();
        }

        combinedMapRemove(gatewayMap, gatewayTypeList, gatewayTypeIndexMap, _gatewayType);

        delete gatewayFallbackFlags[_gatewayType];
        delete isGatewayAddress[gatewayAddress];

        emit RemoveGateway(_gatewayType);
    }

    function setRouters(KeyToAddressValue[] calldata _routers) external onlyManager {
        for (uint256 index; index < _routers.length; index++) {
            KeyToAddressValue calldata item = _routers[index];

            _setRouter(item.key, item.value);
        }
    }

    function removeRouters(uint256[] calldata _routerTypes) external onlyManager {
        for (uint256 index; index < _routerTypes.length; index++) {
            uint256 routerType = _routerTypes[index];

            _removeRouter(routerType);
        }
    }

    function setVault(uint256 _vaultType, address _vault) external onlyManager {
        if (_vault == address(0)) {
            revert ZeroAddressError();
        }

        combinedMapSet(vaultMap, vaultTypeList, vaultTypeIndexMap, _vaultType, _vault);

        emit SetVault(_vaultType, _vault);
    }

    function removeVault(uint256 _vaultType) external onlyManager {
        combinedMapRemove(vaultMap, vaultTypeList, vaultTypeIndexMap, _vaultType);

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

    function setVaultDecimals(uint256 _vaultType, KeyToValue[] calldata _decimalsData) external onlyManager {
        if (vaultMap[_vaultType] == address(0)) {
            revert VaultNotSetError();
        }

        for (uint256 index; index < _decimalsData.length; index++) {
            KeyToValue calldata decimalsDataItem = _decimalsData[index];

            uint256 chainId = decimalsDataItem.key;

            vaultDecimalsTable[_vaultType][chainId] = OptionalValue(true, decimalsDataItem.value);

            if (chainId != VAULT_DECIMALS_CHAIN_ID_WILDCARD) {
                uniqueListAdd(vaultDecimalsChainIdList, vaultDecimalsChainIdIndexMap, chainId);
            }
        }

        emit SetVaultDecimals(_vaultType, _decimalsData);
    }

    function unsetVaultDecimals(uint256 _vaultType, uint256[] calldata _chainIds) external onlyManager {
        if (vaultMap[_vaultType] == address(0)) {
            revert VaultNotSetError();
        }

        for (uint256 index; index < _chainIds.length; index++) {
            uint256 chainId = _chainIds[index];
            delete vaultDecimalsTable[_vaultType][chainId];
        }

        emit UnsetVaultDecimals(_vaultType, _chainIds);
    }

    // System fee in millipercent
    function setSystemFee(uint256 _systemFee) external onlyManager {
        _setSystemFee(_systemFee);
    }

    // Fallback fee in network's native currency
    function setFallbackFee(uint256 _fallbackFee) external onlyManager {
        fallbackFee = _fallbackFee;

        emit SetFallbackFee(_fallbackFee);
    }

    function setFeeCollector(address _feeCollector) external onlyManager {
        _setFeeCollector(_feeCollector);
    }

    function setFeeCollectorLocal(address _feeCollector) external onlyManager {
        _setFeeCollectorLocal(_feeCollector);
    }

    function setFeeCollectorForVariableToken(address _feeCollector) external onlyManager {
        _setFeeCollectorForVariableToken(_feeCollector);
    }

    function setWhitelist(address _whitelistAddress, bool _value) external onlyManager {
        if (_value) {
            uniqueAddressListAdd(whitelist, whitelistIndexMap, _whitelistAddress);
        } else {
            uniqueAddressListRemove(whitelist, whitelistIndexMap, _whitelistAddress);
        }

        emit SetWhitelist(_whitelistAddress, _value);
    }

    // Decimals = 18
    function setSwapAmountMin(uint256 _value) external onlyManager {
        if (_value > swapAmountMax) {
            revert SwapAmountMinGreaterThanMaxError();
        }

        swapAmountMin = _value;

        emit SetSwapAmountMin(_value);
    }

    // Decimals = 18
    function setSwapAmountMax(uint256 _value) external onlyManager {
        if (_value < swapAmountMin) {
            revert SwapAmountMaxLessThanMinError();
        }

        swapAmountMax = _value;

        emit SetSwapAmountMax(_value);
    }

    function localSettings(
        address _caller,
        uint256 _routerType
    )
        external
        view
        returns (LocalSettings memory)
    {
        return LocalSettings({
            router: routerMap[_routerType],
            systemFee: systemFee,
            feeCollectorLocal: feeCollectorLocal,
            isWhitelist: isWhitelist(_caller)
        });
    }

    function sourceSettings(
        address _caller,
        uint256 _targetChainId,
        uint256 _gatewayType,
        uint256 _routerType,
        uint256 _vaultType
    )
        external
        view
        returns (SourceSettings memory)
    {
        return SourceSettings({
            gateway: gatewayMap[_gatewayType],
            useGatewayFallback : gatewayFallbackFlags[_gatewayType],
            router: routerMap[_routerType],
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

    function targetSettings(
        uint256 _vaultType,
        uint256 _routerType
    )
        external
        view
        returns (TargetSettings memory)
    {
        return TargetSettings({
            router: routerMap[_routerType],
            vault: vaultMap[_vaultType]
        });
    }

    function fallbackSettings(
        uint256 _targetChainId,
        uint256 _vaultType
    )
        external
        view
        returns (FallbackSettings memory)
    {
        return FallbackSettings({
            sourceVaultDecimals: vaultDecimals(_vaultType, block.chainid),
            targetVaultDecimals: vaultDecimals(_vaultType, _targetChainId)
        });
    }

    function variableTokenClaimSettings(
        uint256 _vaultType
    )
        external
        view
        returns (VariableTokenClaimSettings memory)
    {

        return  VariableTokenClaimSettings({
            vault: vaultMap[_vaultType],
            fallbackFee: fallbackFee,
            feeCollectorForVariableToken: feeCollectorForVariableToken
        });
    }

    function messageFeeEstimateSettings(
        uint256 _gatewayType
    )
        external
        view
        returns (MessageFeeEstimateSettings memory)
    {
        return MessageFeeEstimateSettings({
            gateway: gatewayMap[_gatewayType]
        });
    }

    function localAmountCalculationSettings(
        address _caller
    )
        external
        view
        returns (LocalAmountCalculationSettings memory)
    {
        return LocalAmountCalculationSettings({
            systemFee: systemFee,
            isWhitelist: isWhitelist(_caller)
        });
    }

    function vaultAmountCalculationSettings(
        address _caller,
        uint256 _vaultType,
        uint256 _fromChainId,
        uint256 _toChainId
    )
        external
        view
        returns (VaultAmountCalculationSettings memory)
    {
        return VaultAmountCalculationSettings({
            fromDecimals: vaultDecimals(_vaultType, _fromChainId),
            toDecimals: vaultDecimals(_vaultType, _toChainId),
            systemFee: systemFee,
            isWhitelist: isWhitelist(_caller)
        });
    }

    function swapAmountLimits(uint256 _vaultType) external view returns (uint256 min, uint256 max) {
        if (swapAmountMin == 0 && swapAmountMax == INFINITY) {
            min = 0;
            max = INFINITY;
        } else {
            uint256 toDecimals = vaultDecimals(_vaultType, block.chainid);

            min =
                (swapAmountMin == 0) ?
                    0 :
                    convertDecimals(DECIMALS_DEFAULT, toDecimals, swapAmountMin);

            max =
                (swapAmountMax == INFINITY) ?
                    INFINITY :
                    convertDecimals(DECIMALS_DEFAULT, toDecimals, swapAmountMax);
        }
    }

    function vaultDecimals(uint256 _vaultType, uint256 _chainId) public view returns (uint256) {
        OptionalValue storage optionalValue = vaultDecimalsTable[_vaultType][_chainId];

        if (optionalValue.isSet) {
            return optionalValue.value;
        }

        OptionalValue storage wildcardOptionalValue =
            vaultDecimalsTable[_vaultType][VAULT_DECIMALS_CHAIN_ID_WILDCARD];

        if (wildcardOptionalValue.isSet) {
            return wildcardOptionalValue.value;
        }

        return DECIMALS_DEFAULT;
    }

    function gatewayTypeCount() public view returns (uint256) {
        return gatewayTypeList.length;
    }

    function routerTypeCount() public view returns (uint256) {
        return routerTypeList.length;
    }

    function vaultTypeCount() public view returns (uint256) {
        return vaultTypeList.length;
    }

    function vaultDecimalsChainIdCount() public view returns (uint256) {
        return vaultDecimalsChainIdList.length;
    }

    function whitelistCount() public view returns (uint256) {
        return whitelist.length;
    }

    function isWhitelist(address _account) public view returns (bool) {
        return whitelistIndexMap[_account].isSet;
    }

    function convertDecimals(
        uint256 _fromDecimals,
        uint256 _toDecimals,
        uint256 _fromAmount
    )
        public
        pure
        returns (uint256)
    {
        if (_toDecimals == _fromDecimals) {
            return _fromAmount;
        } else if (_toDecimals > _fromDecimals) {
            return _fromAmount * 10 ** (_toDecimals - _fromDecimals);
        } else {
            return _fromAmount / 10 ** (_fromDecimals - _toDecimals);
        }
    }

    function _initRoles(address _ownerAddress, bool _grantManagerRoleToOwner) private {
        address ownerAddress =
            _ownerAddress == address(0) ?
                msg.sender :
                _ownerAddress;

        if (_grantManagerRoleToOwner) {
            setManager(ownerAddress, true);
        }

        if (ownerAddress != msg.sender) {
            transferOwnership(ownerAddress);
        }
    }

    function _setGateway(uint256 _gatewayType, address _gatewayAddress, bool _useFallback) private {
        if (_gatewayAddress == address(0)) {
            revert ZeroAddressError();
        }

        if (
            isGatewayAddress[_gatewayAddress] &&
            gatewayMap[_gatewayType] != _gatewayAddress
        ) {
           revert DuplicateGatewayAddressError();
        }

        combinedMapSet(gatewayMap, gatewayTypeList, gatewayTypeIndexMap, _gatewayType, _gatewayAddress);

        gatewayFallbackFlags[_gatewayType] = _useFallback;
        isGatewayAddress[_gatewayAddress] = true;

        emit SetGateway(_gatewayType, _gatewayAddress, _useFallback);
    }

    function _setRouter(uint256 _routerType, address _routerAddress) private {
        if (_routerAddress == address(0)) {
            revert ZeroAddressError();
        }

        combinedMapSet(routerMap, routerTypeList, routerTypeIndexMap, _routerType, _routerAddress);

        emit SetRouter(_routerType, _routerAddress);
    }

    function _removeRouter(uint256 _routerType) private {
        combinedMapRemove(routerMap, routerTypeList, routerTypeIndexMap, _routerType);

        emit RemoveRouter(_routerType);
    }

    function _setSystemFee(uint256 _systemFee) private {
        if (_systemFee > MILLIPERCENT_FACTOR) {
            revert SystemFeeValueError();
        }

        systemFee = _systemFee;

        emit SetSystemFee(_systemFee);
    }

    function _setFeeCollector(address _feeCollector) private {
        feeCollector = _feeCollector;

        emit SetFeeCollector(_feeCollector);
    }

    function _setFeeCollectorLocal(address _feeCollector) private {
        feeCollectorLocal = _feeCollector;

        emit SetFeeCollectorLocal(_feeCollector);
    }

    function _setFeeCollectorForVariableToken(address _feeCollector) private {
        feeCollectorForVariableToken = _feeCollector;

        emit SetFeeCollectorForVariableToken(_feeCollector);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;


interface IVault {
    function asset() external view returns (address);

    function variableToken() external view returns (address);

    function requestAsset(uint256 _amount, address _to, bool _forVariableToken) external returns (address assetAddress);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;


abstract contract DataStructures {

    struct OptionalValue {
        bool isSet;
        uint256 value;
    }

    struct KeyToValue {
        uint256 key;
        uint256 value;
    }

    struct KeyToAddressValue {
        uint256 key;
        address value;
    }

    struct KeyToAddressAndFlag {
        uint256 key;
        address value;
        bool flag;
    }

    function combinedMapSet(
        mapping(uint256 => address) storage _map,
        uint256[] storage _keyList,
        mapping(uint256 => OptionalValue) storage _keyIndexMap,
        uint256 _key,
        address _value
    )
        internal
        returns (bool isNewKey)
    {
        isNewKey = !_keyIndexMap[_key].isSet;

        if (isNewKey) {
            uniqueListAdd(_keyList, _keyIndexMap, _key);
        }

        _map[_key] = _value;
    }

    function combinedMapRemove(
        mapping(uint256 => address) storage _map,
        uint256[] storage _keyList,
        mapping(uint256 => OptionalValue) storage _keyIndexMap,
        uint256 _key
    )
        internal
        returns (bool isChanged)
    {
        isChanged = _keyIndexMap[_key].isSet;

        if (isChanged) {
            delete _map[_key];
            uniqueListRemove(_keyList, _keyIndexMap, _key);
        }
    }

    function uniqueListAdd(
        uint256[] storage _list,
        mapping(uint256 => OptionalValue) storage _indexMap,
        uint256 _value
    )
        internal
        returns (bool isChanged)
    {
        isChanged = !_indexMap[_value].isSet;

        if (isChanged) {
            _indexMap[_value] = OptionalValue(true, _list.length);
            _list.push(_value);
        }
    }

    function uniqueListRemove(
        uint256[] storage _list,
        mapping(uint256 => OptionalValue) storage _indexMap,
        uint256 _value
    )
        internal
        returns (bool isChanged)
    {
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

    function uniqueAddressListAdd(
        address[] storage _list,
        mapping(address => OptionalValue) storage _indexMap,
        address _value
    )
        internal
        returns (bool isChanged)
    {
        isChanged = !_indexMap[_value].isSet;

        if (isChanged) {
            _indexMap[_value] = OptionalValue(true, _list.length);
            _list.push(_value);
        }
    }

    function uniqueAddressListRemove(
        address[] storage _list,
        mapping(address => OptionalValue) storage _indexMap,
        address _value
    )
        internal
        returns (bool isChanged)
    {
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

    function uniqueAddressListUpdate(
        address[] storage _list,
        mapping(address => OptionalValue) storage _indexMap,
        address _value,
        bool _flag
    )
        internal
        returns (bool isChanged)
    {
        return _flag ?
            uniqueAddressListAdd(_list, _indexMap, _value) :
            uniqueAddressListRemove(_list, _indexMap, _value);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

import { ITokenBalance } from './interfaces/ITokenBalance.sol';
import { ManagerRole } from './ManagerRole.sol';
import { NativeTokenAddress } from './NativeTokenAddress.sol';
import { SafeTransfer } from './SafeTransfer.sol';


abstract contract BalanceManagement is ManagerRole, NativeTokenAddress, SafeTransfer {

    error ReservedTokenError();

    function cleanup(address _tokenAddress, uint256 _tokenAmount) external onlyManager {
        if (isReservedToken(_tokenAddress)) {
            revert ReservedTokenError();
        }

        if (_tokenAddress == NATIVE_TOKEN_ADDRESS) {
            safeTransferNative(msg.sender, _tokenAmount);
        } else {
            safeTransfer(_tokenAddress, msg.sender, _tokenAmount);
        }
    }

    function tokenBalance(address _tokenAddress) public view returns (uint256) {
        if (_tokenAddress == NATIVE_TOKEN_ADDRESS) {
            return address(this).balance;
        } else {
            return ITokenBalance(_tokenAddress).balanceOf(address(this));
        }
    }

    function isReservedToken(address /*_tokenAddress*/) public view virtual returns (bool) {
        return false;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

import { ISettings } from './ISettings.sol';


interface IRegistry is ISettings {
    function isGatewayAddress(address _account) external view returns (bool);

    function fallbackFee() external view returns (uint256);

    function localSettings(
        address _caller,
        uint256 _routerType
    )
        external
        view
        returns (LocalSettings memory)
    ;

    function sourceSettings(
        address _caller,
        uint256 _targetChainId,
        uint256 _gatewayType,
        uint256 _routerType,
        uint256 _vaultType
    )
        external
        view
        returns (SourceSettings memory)
    ;

    function targetSettings(
        uint256 _vaultType,
        uint256 _routerType
    )
        external
        view
        returns (TargetSettings memory)
    ;

    function fallbackSettings(
        uint256 _targetChainId,
        uint256 _vaultType
    )
        external
        view
        returns (FallbackSettings memory)
    ;

    function variableTokenClaimSettings(
        uint256 _vaultType
    )
        external
        view
        returns (VariableTokenClaimSettings memory)
    ;

    function messageFeeEstimateSettings(
        uint256 _gatewayType
    )
        external
        view
        returns (MessageFeeEstimateSettings memory)
    ;

    function localAmountCalculationSettings(
        address _caller
    )
        external
        view
        returns (LocalAmountCalculationSettings memory)
    ;

    function vaultAmountCalculationSettings(
        address _caller,
        uint256 _vaultType,
        uint256 _fromChainId,
        uint256 _toChainId
    )
        external
        view
        returns (VaultAmountCalculationSettings memory)
    ;

    function swapAmountLimits(
        uint256 _vaultType
    )
        external
        view
        returns (uint256 swapAmountMin, uint256 swapAmountMax)
    ;
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;


error ZeroAddressError();

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

import { Ownable } from './Ownable.sol';
import { DataStructures } from './DataStructures.sol';


abstract contract ManagerRole is Ownable, DataStructures {

    error OnlyManagerError();

    address[] public managerList;
    mapping(address => OptionalValue) public managerIndexMap;

    event SetManager(address indexed account, bool indexed value);

    modifier onlyManager {
        if (!isManager(msg.sender)) {
            revert OnlyManagerError();
        }

        _;
    }

    function setManager(address _account, bool _value) public virtual onlyOwner {
        _setManager(_account, _value);
    }

    function renounceManagerRole() public virtual onlyManager {
        _setManager(msg.sender, false);
    }

    function isManager(address _account) public view virtual returns (bool) {
        return managerIndexMap[_account].isSet;
    }

    function managerCount() public view virtual returns (uint256) {
        return managerList.length;
    }

    function _setManager(address _account, bool _value) private {
        uniqueAddressListUpdate(managerList, managerIndexMap, _account, _value);

        emit SetManager(_account, _value);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;


interface ITokenBalance {
    function balanceOf(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;


abstract contract NativeTokenAddress {

    address public constant NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;


abstract contract SafeTransfer {

    error SafeApproveError();
    error SafeTransferError();
    error SafeTransferFromError();
    error SafeTransferNativeError();

    function safeApprove(address _token, address _to, uint256 _value) internal {
        // 0x095ea7b3 is the selector for "approve(address,uint256)"
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(0x095ea7b3, _to, _value));

        bool condition = success && (data.length == 0 || abi.decode(data, (bool)));

        if (!condition) {
            revert SafeApproveError();
        }
    }

    function safeTransfer(address _token, address _to, uint256 _value) internal {
        // 0xa9059cbb is the selector for "transfer(address,uint256)"
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(0xa9059cbb, _to, _value));

        bool condition = success && (data.length == 0 || abi.decode(data, (bool)));

        if (!condition) {
            revert SafeTransferError();
        }
    }

    function safeTransferFrom(address _token, address _from, address _to, uint256 _value) internal {
        // 0x23b872dd is the selector for "transferFrom(address,address,uint256)"
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(0x23b872dd, _from, _to, _value));

        bool condition = success && (data.length == 0 || abi.decode(data, (bool)));

        if (!condition) {
            revert SafeTransferFromError();
        }
    }

    function safeTransferNative(address _to, uint256 _value) internal {
        (bool success, ) = _to.call{value: _value}(new bytes(0));

        if (!success) {
            revert SafeTransferNativeError();
        }
    }

    function safeTransferNativeUnchecked(address _to, uint256 _value) internal {
        (bool ignore, ) = _to.call{value: _value}(new bytes(0));

        ignore;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

import { ZeroAddressError } from './Errors.sol';


abstract contract Ownable {

    error OnlyOwnerError();

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) {
            revert OnlyOwnerError();
        }

        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert ZeroAddressError();
        }

        address previousOwner = owner;
        owner = newOwner;

        emit OwnershipTransferred(previousOwner, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;


interface ISettings {
    struct LocalSettings {
        address router;
        uint256 systemFee;
        address feeCollectorLocal;
        bool isWhitelist;
    }

    struct SourceSettings {
        address gateway;
        bool useGatewayFallback;
        address router;
        address vault;
        uint256 sourceVaultDecimals;
        uint256 targetVaultDecimals;
        uint256 systemFee;
        address feeCollector;
        bool isWhitelist;
        uint256 swapAmountMin;
        uint256 swapAmountMax;
    }

    struct TargetSettings {
        address router;
        address vault;
    }

    struct FallbackSettings {
        uint256 sourceVaultDecimals;
        uint256 targetVaultDecimals;
    }

    struct VariableTokenClaimSettings {
        address vault;
        uint256 fallbackFee;
        address feeCollectorForVariableToken;
    }

    struct MessageFeeEstimateSettings {
        address gateway;
    }

    struct LocalAmountCalculationSettings {
        uint256 systemFee;
        bool isWhitelist;
    }

    struct VaultAmountCalculationSettings {
        uint256 fromDecimals;
        uint256 toDecimals;
        uint256 systemFee;
        bool isWhitelist;
    }
}