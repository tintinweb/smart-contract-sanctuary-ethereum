/**
 *Submitted for verification at Etherscan.io on 2022-09-30
*/

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;


interface TokenBalance {
    function balanceOf(address _account) external view returns (uint256);
}


interface TokenMint {
    function mint(address _to, uint256 _amount) external returns (bool);
}


interface Interaction {
    function sendMessage(
        uint256 _targetChainId,
        bytes calldata _message,
        bool _useFallback
    )
        external
        payable
    ;

    function messageFee(
        uint256 _targetChainId,
        uint256 _messageSizeInBytes
    )
        external
        view
        returns (uint256)
    ;
}


interface InteractionClient {
    function handleExecutionPayload(
        uint256 _messageSourceChainId,
        bytes calldata _payloadData
    )
        external
        returns (bool success, bytes memory result)
    ;

    function handleFallbackPayload(
        uint256 _messageTargetChainId,
        bytes calldata _payloadData
    )
        external
    ;
}


abstract contract Ownable {

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(
            msg.sender == owner,
            "only-owner"
        );

        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "owner-zero-address"
        );

        address previousOwner = owner;
        owner = newOwner;

        emit OwnershipTransferred(previousOwner, newOwner);
    }
}


abstract contract ManagerRole is Ownable {

    mapping(address => bool) public managers;

    event SetManager(address indexed manager, bool indexed value);

    modifier onlyManager {
        require(
            managers[msg.sender],
            "only-manager"
        );

        _;
    }

    function setManager(address _manager, bool _value) public virtual onlyOwner {
        managers[_manager] = _value;

        emit SetManager(_manager, _value);
    }
}


abstract contract Pausable is ManagerRole {

    bool public paused = false;

    event Pause();
    event Unpause();

    modifier whenNotPaused() {
        require(
            !paused,
            "when-not-paused"
        );

        _;
    }

    modifier whenPaused() {
        require(
            paused,
            "when-paused"
        );

        _;
    }

    function pause() onlyManager whenNotPaused public {
        paused = true;

        emit Pause();
    }

    function unpause() onlyManager whenPaused public {
        paused = false;

        emit Unpause();
    }
}


abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant {
        _nonReentrantBefore();

        _;

        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        require(
            _status != _ENTERED,
            "reentrant-call"
        );

        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }
}


abstract contract SafeTransfer {

    function safeApprove(address _token, address _to, uint256 _value) internal {
        // 0x095ea7b3 is the selector for "approve(address,uint256)"
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(0x095ea7b3, _to, _value));

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "safe-approve"
        );
    }

    function safeTransfer(address _token, address _to, uint256 _value) internal {
        // 0xa9059cbb is the selector for "transfer(address,uint256)"
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(0xa9059cbb, _to, _value));

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "safe-transfer"
        );
    }

    function safeTransferFrom(address _token, address _from, address _to, uint256 _value) internal {
        // 0x23b872dd is the selector for "transferFrom(address,address,uint256)"
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(0x23b872dd, _from, _to, _value));

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "safe-transfer-from"
        );
    }

    function safeTransferFromWithResult(address _token, address _from, address _to, uint256 _value)
        internal
        returns (bool success, bytes memory data)
    {
        bool callSuccess;

        // 0x23b872dd is the selector for "transferFrom(address,address,uint256)"
        (callSuccess, data) = _token.call(abi.encodeWithSelector(0x23b872dd, _from, _to, _value));

        success = callSuccess && (data.length == 0 || abi.decode(data, (bool)));
    }

    function safeTransferNative(address _to, uint256 _value) internal {
        (bool success, ) = _to.call{value: _value}(new bytes(0));

        require(
            success,
            "safe-transfer-native"
        );
    }
}


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

    function mapWithKeyListSet(
        mapping(uint256 => address) storage _map,
        uint256[] storage _keyList,
        uint256 _key,
        address _value
    )
        internal
        returns (bool isNewKey)
    {
        require(
            _value != address(0),
            "value-zero-address"
        );

        isNewKey = (_map[_key] == address(0));

        if (isNewKey) {
            _keyList.push(_key);
        }

        _map[_key] = _value;
    }

    function mapWithKeyListRemove(
        mapping(uint256 => address) storage _map,
        uint256[] storage _keyList,
        uint256 _key
    )
        internal
        returns (bool isChanged)
    {
        isChanged = (_map[_key] != address(0));

        if (isChanged) {
            delete _map[_key];
            arrayRemoveValue(_keyList, _key);
        }
    }

    function listWithValueMapAdd(
        uint256[] storage _list,
        mapping(uint256 => bool) storage _valueMap,
        uint256 _value
    )
        internal
        returns (bool isNewValue)
    {
        isNewValue = !_valueMap[_value];

        if (isNewValue) {
            _list.push(_value);
            _valueMap[_value] = true;
        }
    }

    function arrayRemoveValue(uint256[] storage _array, uint256 _value) internal returns (bool isChanged) {
        uint256 arrayLength = _array.length;

        for (uint256 index; index < arrayLength; index++) {
            if (_array[index] == _value) {
                _array[index] = _array[arrayLength - 1];
                _array.pop();

                return true;
            }
        }

        return false;
    }
}


contract ActionExecutor is Pausable, ReentrancyGuard, SafeTransfer, DataStructures, InteractionClient {

    struct Action {
        uint256 vaultType;
        address sourceTokenAddress;
        SwapInfo sourceSwapInfo;
        uint256 targetChainId;
        address targetTokenAddress;
        SwapInfo[] targetSwapInfoOptions;
        address targetRecipient;
    }

    struct SwapInfo {
        uint256 fromAmount;
        uint256 routerType;
        bytes routerData;
    }

    struct TargetMessage {
        uint256 actionId;
        address sourceSender;
        uint256 vaultType;
        address targetTokenAddress;
        SwapInfo targetSwapInfo;
        address targetRecipient;
    }

    address public constant NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 public constant VAULT_DECIMALS_CHAIN_ID_WILDCARD = 0;

    Interaction public interaction;
    bool useInteractionFallback;

    uint256[] public vaultTypes;
    mapping(uint256 => address) public vaults;
    mapping(uint256 => address) public vaultAssets;
    mapping(uint256 => address) public vaultVariableTokens;

    mapping(uint256 => mapping(uint256 => OptionalValue)) public vaultDecimalsTable; // Keys: vault type, chain id
    uint256[] public vaultDecimalsChainIdList;
    mapping(uint256 => bool) public vaultDecimalsChainIdMap;

    uint256[] public routerTypes;
    mapping(uint256 => address) public routers;

    uint256 public systemFee; // System fee in millipercent
    uint256 public fallbackFee; // Fallback fee in network's native currency
    address public feeCollector;
    mapping(address => bool) public whitelist;

    // Swap amount limits with decimals = 18
    uint256 public swapAmountMin = 0;
    uint256 public swapAmountMax = INFINITY;

    // Keys: account address, vault type
    mapping(address => mapping(uint256 => uint256)) public variableTokenBalanceTable;
    mapping(address => mapping(uint256 => uint256)) public fallbackCountTable;

    uint256 private constant DECIMALS_DEFAULT = 18;
    uint256 private constant INFINITY = type(uint256).max;
    uint256 private constant MILLIPERCENT_FACTOR = 1e5;

    uint256 private lastActionId = block.chainid * 1e7 + 555 ** 2;

    event SetInteraction(address indexed interactionAddress);
    event SetUseInteractionFallback(bool indexed value);

    event SetVault(
        uint256 indexed vaultType,
        address indexed vault,
        address indexed asset,
        address variableToken
    );

    event RemoveVault(uint256 indexed vaultType);

    event SetVaultDecimals(uint256 indexed vaultType, KeyToValue[] decimalsData);
    event UnsetVaultDecimals(uint256 indexed vaultType, uint256[] chainIds);

    event SetRouter(uint256 indexed routerType, address indexed routerAddress);
    event RemoveRouter(uint256 indexed routerType);

    event SetSystemFee(uint256 systemFee);
    event SetFallbackFee(uint256 fallbackFee);
    event SetFeeCollector(address indexed feeCollector);

    event SetWhitelist(address indexed whitelistAddress, bool indexed value);

    event SetSwapAmountMin(uint256 value);
    event SetSwapAmountMax(uint256 value);

    event ActionId(uint256 indexed actionId, uint256 indexed targetChainId);

    event SourceProcessed(
        uint256 indexed actionId,
        address indexed sender,
        uint256 indexed routerType,
        address fromTokenAddress,
        address toVaultAssetAddress,
        uint256 fromAmount,
        uint256 resultAmount
    );

    event TargetProcessed(
        uint256 indexed actionId,
        address indexed recipient,
        uint256 indexed routerType,
        address fromVaultAssetAddress,
        address toTokenAddress,
        uint256 fromAmount,
        uint256 resultAmount
    );

    event TargetStopped(
        uint256 indexed actionId,
        uint256 indexed step,
        bytes data
    );

    event FallbackProcessed(
        uint256 indexed actionId,
        address indexed tokenRecipient,
        uint256 indexed vaultType,
        uint256 tokenAmount
    );

    constructor(
        address _interactionAddress,
        uint256 _systemFee, // System fee in millipercent
        address _feeCollector,
        address _ownerAddress,
        bool _grantManagerRoleToOwner
    )
    {
        _setInteraction(_interactionAddress);
        _setUseInteractionFallback(true);

        _setSystemFee(_systemFee);
        _setFeeCollector(_feeCollector);

        _initRoles(_ownerAddress, _grantManagerRoleToOwner);
    }

    modifier onlyInteraction {
        require(
            msg.sender == address(interaction),
            "only-interaction"
        );

        _;
    }

    receive() external payable {
    }

    fallback() external {
    }

    function setInteraction(address _interactionAddress) external onlyManager {
        _setInteraction(_interactionAddress);
    }

    function setUseInteractionFallback(bool _value) external onlyManager {
        _setUseInteractionFallback(_value);
    }

    function setVault(
        uint256 _vaultType,
        address _vault,
        address _asset,
        address _variableToken
    )
        external
        onlyManager
    {
        require(
            _vault != address(0) &&
            _asset != address(0) &&
            _variableToken != address(0),
            "vault-zero-address"
        );

        mapWithKeyListSet(vaults, vaultTypes, _vaultType, _vault);

        vaultAssets[_vaultType] = _asset;
        vaultVariableTokens[_vaultType] = _variableToken;

        emit SetVault(_vaultType, _vault, _asset, _variableToken);
    }

    function removeVault(uint256 _vaultType) external onlyManager {
        mapWithKeyListRemove(vaults, vaultTypes, _vaultType);

        delete vaultAssets[_vaultType];
        delete vaultVariableTokens[_vaultType];

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
        require(
            vaults[_vaultType] != address(0),
            "vault-type"
        );

        for (uint256 index; index < _decimalsData.length; index++) {
            KeyToValue calldata decimalsDataItem = _decimalsData[index];

            uint256 chainId = decimalsDataItem.key;

            vaultDecimalsTable[_vaultType][chainId] = OptionalValue(true, decimalsDataItem.value);

            if (chainId != VAULT_DECIMALS_CHAIN_ID_WILDCARD) {
                listWithValueMapAdd(vaultDecimalsChainIdList, vaultDecimalsChainIdMap, chainId);
            }
        }

        emit SetVaultDecimals(_vaultType, _decimalsData);
    }

    function unsetVaultDecimals(uint256 _vaultType, uint256[] calldata _chainIds) external onlyManager {
        require(
            vaults[_vaultType] != address(0),
            "vault-type"
        );

        for (uint256 index; index < _chainIds.length; index++) {
            uint256 chainId = _chainIds[index];
            delete vaultDecimalsTable[_vaultType][chainId];
        }

        emit UnsetVaultDecimals(_vaultType, _chainIds);
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

    function setWhitelist(address _whitelistAddress, bool _value) external onlyManager {
        whitelist[_whitelistAddress] = _value;

        emit SetWhitelist(_whitelistAddress, _value);
    }

    // Value decimals = 18
    function setSwapAmountMin(uint256 _value) external onlyManager {
        require(
            _value <= swapAmountMax,
            "min-greater-than-max"
        );

        swapAmountMin = _value;

        emit SetSwapAmountMin(_value);
    }

    // Value decimals = 18
    function setSwapAmountMax(uint256 _value) external onlyManager {
        require(
            _value >= swapAmountMin,
            "max-less-than-min"
        );

        swapAmountMax = _value;

        emit SetSwapAmountMax(_value);
    }

    function cleanup(address _tokenAddress, uint256 _tokenAmount) external onlyManager {
        if (_tokenAddress == NATIVE_TOKEN_ADDRESS) {
            safeTransferNative(msg.sender, _tokenAmount);
        } else {
            safeTransfer(_tokenAddress, msg.sender, _tokenAmount);
        }
    }

    function execute(Action calldata _action)
        external
        payable
        nonReentrant
        whenNotPaused
        returns (uint256 actionId)
    {
        address vaultAddress = vaults[_action.vaultType];
        address vaultAssetAddress = vaultAssets[_action.vaultType];

        require(
            vaultAddress != address(0) && vaultAssetAddress != address(0),
            "vault-type"
        );

        lastActionId++;
        actionId = lastActionId;

        emit ActionId(actionId, _action.targetChainId);

        uint256 initialBalance = address(this).balance - msg.value;
        uint256 initialVaultAssetBalance = TokenBalance(vaultAssetAddress).balanceOf(address(this));

        uint256 processedAmount = _processSource(
            actionId,
            _action.sourceTokenAddress,
            vaultAssetAddress,
            _action.sourceSwapInfo,
            initialVaultAssetBalance
        );

        _checkSwapAmountLimits(_action.vaultType, processedAmount);

        uint256 targetVaultAmountMax = calculateVaultAmount(
            _action.vaultType,
            block.chainid,
            _action.targetChainId,
            processedAmount,
            true
        );

        SwapInfo memory targetSwapInfo;

        uint256 targetOptionsLength = _action.targetSwapInfoOptions.length;

        if (targetOptionsLength != 0) {
            for (uint256 index; index < targetOptionsLength; index++) {
                SwapInfo memory targetSwapInfoOption = _action.targetSwapInfoOptions[index];

                if (targetSwapInfoOption.fromAmount <= targetVaultAmountMax) {
                    targetSwapInfo = targetSwapInfoOption;
                    break;
                }
            }

            require(
                targetSwapInfo.fromAmount != 0,
                "target-swap-info"
            );
        } else {
            targetSwapInfo = SwapInfo({
                fromAmount: targetVaultAmountMax,
                routerType: uint256(0),
                routerData: new bytes(0)
            });
        }

        address targetRecipient =
            _action.targetRecipient == address(0) ?
                msg.sender :
                _action.targetRecipient;

        if (_action.targetChainId == block.chainid) {
            (bool success, ) = _processTarget(
                actionId,
                vaultAssetAddress,
                _action.targetTokenAddress,
                targetSwapInfo,
                targetRecipient
            );

            require(
                success,
                "process-target-local"
            );
        } else {
            uint256 sourceVaultAmount = _convertVaultDecimals(
                _action.vaultType,
                targetSwapInfo.fromAmount,
                _action.targetChainId,
                block.chainid
            );

            // - - - Transfer to vault - - -

            safeTransfer(vaultAssetAddress, vaultAddress, sourceVaultAmount);

            // - - -

            bytes memory targetMessageData = abi.encode(
                TargetMessage({
                    actionId: actionId,
                    sourceSender: msg.sender,
                    vaultType: _action.vaultType,
                    targetTokenAddress: _action.targetTokenAddress,
                    targetSwapInfo: targetSwapInfo,
                    targetRecipient: targetRecipient
                })                
            );

            _sendMessage(_action.targetChainId, targetMessageData);
        }

        // - - - System fee transfer - - -

        uint256 systemFeeAmount =
            TokenBalance(vaultAssetAddress).balanceOf(address(this)) -
            initialVaultAssetBalance;

        if (systemFeeAmount > 0 && feeCollector != address(0)) {
            safeTransfer(vaultAssetAddress, feeCollector, systemFeeAmount);
        }

        // - - -

        // - - - Extra balance transfer - - -

        uint256 extraBalance = address(this).balance - initialBalance;

        if (extraBalance > 0) {
            safeTransferNative(msg.sender, extraBalance);
        }

        // - - -
    }

    function claimVariableToken(uint256 _vaultType) external payable {
        _processVariableTokenClaim(_vaultType, false);
    }

    function convertVariableTokenToVaultAsset(uint256 _vaultType) external payable {
        _processVariableTokenClaim(_vaultType, true);
    }

    function messageFeeEstimate(uint256 _targetChainId, bytes[] calldata _targetRouterDataOptions)
        external
        view
        returns (uint256)
    {
        if (_targetChainId == block.chainid) {
            return 0;
        }

        uint256 result = 0;

        for (uint256 index; index < _targetRouterDataOptions.length; index++) {
            bytes calldata targetRouterData = _targetRouterDataOptions[index];

            bytes memory messageData = abi.encode(
                TargetMessage({
                    actionId: uint256(0),
                    sourceSender: address(0),
                    vaultType: uint256(0),
                    targetTokenAddress: address(0),
                    targetSwapInfo: SwapInfo({
                        fromAmount: uint256(0),
                        routerType: uint256(0),
                        routerData: targetRouterData
                    }),
                    targetRecipient: address(0)
                })
            );

            uint256 value = interaction.messageFee(_targetChainId, messageData.length);

            if (value > result) {
                result = value;
            }
        }

        return result;
    }

    function calculateVaultAmount(
        uint256 _vaultType,
        uint256 _fromChainId,
        uint256 _toChainId,
        uint256 _fromAmount,
        bool _isForward
    )
        public
        view
        returns (uint256 result)
    {
        bool isZeroFee = whitelist[msg.sender] || systemFee == 0;

        uint256 amountToConvert =
            (!_isForward || isZeroFee) ?
                _fromAmount :
                _fromAmount * (MILLIPERCENT_FACTOR - systemFee) / MILLIPERCENT_FACTOR;

        uint256 convertedAmount = _convertVaultDecimals(
            _vaultType,
            amountToConvert,
            _fromChainId,
            _toChainId
        );

        result =
            (_isForward || isZeroFee) ?
                convertedAmount :
                convertedAmount * MILLIPERCENT_FACTOR / (MILLIPERCENT_FACTOR - systemFee);
    }

    function swapAmountLimits(uint256 _vaultType) public view returns (uint256 min, uint256 max) {
        if (swapAmountMin == 0 && swapAmountMax == INFINITY) {
            min = 0;
            max = INFINITY;
        } else {
            uint256 toDecimals = vaultDecimals(_vaultType, block.chainid);

            min =
                (swapAmountMin == 0) ?
                    0 :
                    _convertDecimals(DECIMALS_DEFAULT, toDecimals, swapAmountMin);

            max =
                (swapAmountMax == INFINITY) ?
                    INFINITY :
                    _convertDecimals(DECIMALS_DEFAULT, toDecimals, swapAmountMax);
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

    function variableTokenBalance(address _account, uint256 _vaultType) public view returns (uint256) {
        return variableTokenBalanceTable[_account][_vaultType];
    }

    function variableTokenFeeAmount(address _account, uint256 _vaultType) public view returns (uint256) {
        return fallbackCountTable[_account][_vaultType] * fallbackFee;
    }

    function tokenBalance(address _tokenAddress) public view returns (uint256) {
        if (_tokenAddress == NATIVE_TOKEN_ADDRESS) {
            return address(this).balance;
        } else {
            return TokenBalance(_tokenAddress).balanceOf(address(this));
        }
    }

    function handleExecutionPayload(
        uint256 /*_messageSourceChainId*/,
        bytes calldata _payloadData
    )
        external
        onlyInteraction
        whenNotPaused
        returns (bool success, bytes memory result)
    {
        TargetMessage memory targetMessage = abi.decode(_payloadData, (TargetMessage));

        address vaultAddress = vaults[targetMessage.vaultType];
        address vaultAssetAddress = vaultAssets[targetMessage.vaultType];

        require(
            vaultAddress != address(0) && vaultAssetAddress != address(0),
            "vault-type"
        );

        // - - - Transfer from vault - - -

        (bool vaultTransferSuccess, bytes memory vaultTransferData) =
            safeTransferFromWithResult(
                vaultAssetAddress,
                vaultAddress,
                address(this),
                targetMessage.targetSwapInfo.fromAmount
            );

        if (!vaultTransferSuccess) {
            emit TargetStopped(targetMessage.actionId, 1, vaultTransferData);

            return (false, vaultTransferData);
        }

        // - - -

        return _processTarget(
            targetMessage.actionId,
            vaultAssetAddress,
            targetMessage.targetTokenAddress,
            targetMessage.targetSwapInfo,
            targetMessage.targetRecipient
        );
    }

    function handleFallbackPayload(
        uint256 _messageTargetChainId,
        bytes calldata _payloadData
    )
        external
        onlyInteraction
        whenNotPaused
    {
        TargetMessage memory targetMessage = abi.decode(_payloadData, (TargetMessage));

        address tokenRecipient = targetMessage.sourceSender;
        uint256 vaultType = targetMessage.vaultType;

        fallbackCountTable[tokenRecipient][vaultType]++;

        uint256 tokenAmount = _convertVaultDecimals(
            vaultType,
            targetMessage.targetSwapInfo.fromAmount,
            _messageTargetChainId,
            block.chainid
        );

        variableTokenBalanceTable[tokenRecipient][vaultType] += tokenAmount;

        emit FallbackProcessed(
            targetMessage.actionId,
            tokenRecipient,
            vaultType,
            tokenAmount
        );
    }

    function _processSource(
        uint256 _actionId,
        address _sourceTokenAddress,
        address _vaultAssetAddress,
        SwapInfo memory _sourceSwapInfo,
        uint256 initialVaultAssetBalance
    )
        private
        returns (uint256 resultAmount)
    {
        if (_sourceTokenAddress == NATIVE_TOKEN_ADDRESS) {
            address router = routers[_sourceSwapInfo.routerType];

            require(
                router != address(0),
                "source-router-type"
            );

            // - - - Source swap (native token) - - -

            (bool routerCallSuccess, ) =
                payable(router).call{value: _sourceSwapInfo.fromAmount}(_sourceSwapInfo.routerData);

            require(
                routerCallSuccess,
                "source-swap"
            );

            // - - -
        } else {
            safeTransferFrom(_sourceTokenAddress, msg.sender, address(this), _sourceSwapInfo.fromAmount);

            if (_sourceTokenAddress != _vaultAssetAddress) {
                address router = routers[_sourceSwapInfo.routerType];

                require(
                    router != address(0),
                    "source-router-type"
                );

                // - - - Source swap (non-native token) - - -

                safeApprove(_sourceTokenAddress, router, _sourceSwapInfo.fromAmount);

                (bool routerCallSuccess, ) = router.call(_sourceSwapInfo.routerData);

                require(
                    routerCallSuccess,
                    "source-swap"
                );

                safeApprove(_sourceTokenAddress, router, 0);

                // - - -
            }
        }

        resultAmount =
            TokenBalance(_vaultAssetAddress).balanceOf(address(this)) -
            initialVaultAssetBalance;

        emit SourceProcessed(
            _actionId,
            msg.sender,
            _sourceSwapInfo.routerType,
            _sourceTokenAddress,
            _vaultAssetAddress,
            _sourceSwapInfo.fromAmount,
            resultAmount
        );
    }

    function _processTarget(
        uint256 _actionId,
        address _vaultAssetAddress,
        address _targetTokenAddress,
        SwapInfo memory _targetSwapInfo,
        address _targetRecipient
    )
        private
        returns (bool success, bytes memory result)
    {
        uint256 resultAmount;

        if (_targetTokenAddress == _vaultAssetAddress) {
            resultAmount = _targetSwapInfo.fromAmount;

            safeTransfer(_targetTokenAddress, _targetRecipient, resultAmount);
        } else {
            address router = routers[_targetSwapInfo.routerType];

            require(
                router != address(0),
                "target-router-type"
            );

            uint256 targetTokenBalanceBefore = tokenBalance(_targetTokenAddress);

            // - - - Target swap - - -

            safeApprove(_vaultAssetAddress, router, _targetSwapInfo.fromAmount);

            (bool routerCallSuccess, bytes memory routerCallData) = router.call(_targetSwapInfo.routerData);

            safeApprove(_vaultAssetAddress, router, 0);

            if (!routerCallSuccess) {
                emit TargetStopped(_actionId, 2, routerCallData);

                return (false, routerCallData);
            }

            // - - -

            uint256 targetTokenBalanceAfter = tokenBalance(_targetTokenAddress);
            resultAmount = targetTokenBalanceAfter - targetTokenBalanceBefore;

            if (_targetTokenAddress == NATIVE_TOKEN_ADDRESS) {
                safeTransferNative(_targetRecipient, resultAmount);
            } else {
                safeTransfer(_targetTokenAddress, _targetRecipient, resultAmount);
            }
        }

        emit TargetProcessed(
            _actionId,
            _targetRecipient,
            _targetSwapInfo.routerType,
            _vaultAssetAddress,
            _targetTokenAddress,
            _targetSwapInfo.fromAmount,
            resultAmount
        );

        return (true, "");
    }

    function _processVariableTokenClaim(uint256 _vaultType, bool _convertToVaultAsset) private {
        address vaultAddress = vaults[_vaultType];

        require(
            vaultAddress != address(0),
            "vault-type"
        );

        uint256 feeAmount = variableTokenFeeAmount(msg.sender, _vaultType);

        require(
            msg.value >= feeAmount,
            "fee-amount"
        );

        uint256 initialBalance = address(this).balance - msg.value;

        // - - - Fallback fee transfer

        if (feeAmount > 0) {
            if (feeCollector != address(0)) {
                safeTransferNative(feeCollector, feeAmount);
            } else {
                initialBalance += feeAmount; // Keep at the contract address
            }
        }

        // - - -

        uint256 tokenAmount = variableTokenBalance(msg.sender, _vaultType);

        if (tokenAmount > 0) {
            variableTokenBalanceTable[msg.sender][_vaultType] = 0;

            if (_convertToVaultAsset) {
                address assetAddress = vaultAssets[_vaultType];

                require(
                    assetAddress != address(0),
                    "asset-zero-address"
                );

                safeTransferFrom(
                    assetAddress,
                    vaultAddress,
                    msg.sender,
                    tokenAmount
                );
            } else {
                address tokenAddress = vaultVariableTokens[_vaultType];

                require(
                    tokenAddress != address(0),
                    "token-zero-address"
                );

                TokenMint(tokenAddress).mint(msg.sender, tokenAmount);
            }
        }

        // - - - Extra balance transfer - - -

        uint256 extraBalance = address(this).balance - initialBalance;

        if (extraBalance > 0) {
            safeTransferNative(msg.sender, extraBalance);
        }

        // - - -

        fallbackCountTable[msg.sender][_vaultType] = 0;
    }

    function _setInteraction(address _interactionAddress) private {
        require(
            _interactionAddress != address(0),
            "call-proxy-zero-address"
        );

        interaction = Interaction(_interactionAddress);

        emit SetInteraction(_interactionAddress);
    }

    function _setUseInteractionFallback(bool _value) internal {
        useInteractionFallback = _value;

        emit SetUseInteractionFallback(_value);
    }

    function _setRouter(uint256 _routerType, address _routerAddress) private {
        require(
            _routerAddress != address(0),
            "router-zero-address"
        );

        mapWithKeyListSet(routers, routerTypes, _routerType, _routerAddress);

        emit SetRouter(_routerType, _routerAddress);
    }

    function _removeRouter(uint256 _routerType) private {
        mapWithKeyListRemove(routers, routerTypes, _routerType);

        emit RemoveRouter(_routerType);
    }

    function _setSystemFee(uint256 _systemFee) private {
        require(
            _systemFee <= MILLIPERCENT_FACTOR,
            "system-fee-value"
        );

        systemFee = _systemFee;

        emit SetSystemFee(_systemFee);
    }

    function _setFeeCollector(address _feeCollector) private {
        feeCollector = _feeCollector;

        emit SetFeeCollector(_feeCollector);
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

    function _sendMessage(uint256 _targetChainId, bytes memory _messageData) private {
        uint256 messageFee = interaction.messageFee(_targetChainId, _messageData.length);

        interaction.sendMessage{value: messageFee}(
            _targetChainId,
            _messageData,
            useInteractionFallback
        );
    }

    function _checkSwapAmountLimits(uint256 _vaultType, uint256 _amount) private view {
        uint256 normalizedAmount = _convertDecimals(
             vaultDecimals(_vaultType, block.chainid),
             DECIMALS_DEFAULT,
             _amount
        );

        require(
            normalizedAmount >= swapAmountMin,
            "swap-amount-min"
        );

        require(
            normalizedAmount <= swapAmountMax,
            "swap-amount-max"
        );
    }

    function _convertVaultDecimals(
        uint256 _vaultType,
        uint256 _amount,
        uint256 _fromChainId,
        uint256 _toChainId
    )
        private
        view
        returns (uint256)
    {
        if (_toChainId == _fromChainId) {
            return _amount;
        }

        uint256 fromDecimals = vaultDecimals(_vaultType, _fromChainId);
        uint256 toDecimals = vaultDecimals(_vaultType, _toChainId);

        return _convertDecimals(fromDecimals, toDecimals, _amount);
    }

    function _convertDecimals(
        uint256 _fromDecimals,
        uint256 _toDecimals,
        uint256 _fromAmount
    )
        private
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
}