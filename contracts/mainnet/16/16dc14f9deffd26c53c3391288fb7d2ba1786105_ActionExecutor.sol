/**
 *Submitted for verification at Etherscan.io on 2022-09-25
*/

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;


interface TokenBalance {
    function balanceOf(address _account) external view returns (uint256);
}


interface TokenMint {
    function mint(address _to, uint256 _amount) external returns (bool);
}


interface CallProxy {
    function anyCall(
        address _to,
        bytes calldata _data,
        address _fallback,
        uint256 _toChainID,
        uint256 _flags
    )
        external
        payable
    ;

    function deposit(address _account) external payable;

    function withdraw(uint256 _amount) external;

    function executor() external view returns (CallExecutor executor);

    function srcDefaultFees(uint256 _targetChainId) external view returns (uint256 baseFees, uint256 feesPerByte);

    function executionBudget(address _account) external view returns (uint256 amount);
}


interface CallExecutor {
    function context() external view returns (address from, uint256 fromChainID, uint256 nonce);
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

    function renounceOwnership() public virtual onlyOwner {
        address previousOwner = owner;
        owner = address(0);

        emit OwnershipTransferred(previousOwner, address(0));
    }
}


abstract contract ManagerRole is Ownable {

    mapping(address => bool) public managers;

    event SetManager(address indexed manager, bool indexed value);

    constructor(bool _grantToOwner) {
        if (_grantToOwner) {
            setManager(owner, true);
        }
    }

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


abstract contract AnyCallInteraction is ReentrancyGuard {

    CallProxy public callProxy;
    CallExecutor public callExecutor;

    uint256 internal constant PAY_FEE_ON_SOURCE_CHAIN = 0x1 << 1;
    address internal callFallbackAddress;

    event SetCallProxy(address indexed callProxyAddress, address indexed callExecutorAddress);
    event SetUseCallFallback(bool indexed value);

    constructor(address _callProxyAddress, bool _useCallFallback) {
        _setCallProxy(_callProxyAddress);
        _setUseCallFallback(_useCallFallback);
    }

    modifier onlyCallExecutor {
        require(
            msg.sender == address(callExecutor),
            "only-call-executor"
        );

        _;
    }

    modifier onlySelf {
        require(
            msg.sender == address(this),
            "only-self"
        );

        _;
    }

    function anyExecute(bytes calldata _data)
        external
        nonReentrant
        onlyCallExecutor
        returns (bool success, bytes memory result)
    {
        bytes4 selector = bytes4(_data[:4]);

        if (selector == this.anyExecute.selector) {
            (address from, uint256 fromChainID, ) = callExecutor.context();

            return handleAnyExecutePayload(fromChainID, from, _data[4:]);
        } else if (selector == this.anyFallback.selector) {
            (address fallbackTo, bytes memory fallbackData) = abi.decode(_data[4:], (address, bytes));

            this.anyFallback(fallbackTo, fallbackData);

            return (true, "");
        } else {
            return (false, "call-selector");
        }
    }

    function anyFallback(address _to, bytes calldata _data) external onlySelf {
        (address from, uint256 fromChainID, ) = callExecutor.context();

        require(
            from == address(this),
            "fallback-context-from"
        );

        require(
            bytes4(_data[:4]) == this.anyExecute.selector,
            "fallback-data-selector"
        );

        handleAnyFallbackPayload(fromChainID, _to, _data[4:]);
    }

    function _setCallProxy(address _callProxyAddress) internal {
        require(
            _callProxyAddress != address(0),
            "call-proxy-zero-address"
        );

        callProxy = CallProxy(_callProxyAddress);
        callExecutor = callProxy.executor();

        emit SetCallProxy(_callProxyAddress, address(callExecutor));
    }

    function _setUseCallFallback(bool _value) internal {
        callFallbackAddress = _value ?
            address(this) :
            address(0);

        emit SetUseCallFallback(_value);
    }

    function handleAnyExecutePayload(
        uint256 _callFromChainId,
        address _callFromAddress,
        bytes calldata _payloadData
    )
        internal
        virtual
        returns (bool success, bytes memory result)
    ;

    function handleAnyFallbackPayload(
        uint256 _callToChainId,
        address _callToAddress,
        bytes calldata _payloadData
    )
        internal
        virtual
    ;
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


contract ActionExecutor is ManagerRole, AnyCallInteraction, SafeTransfer, DataStructures {

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

    uint256[] public vaultTypes;
    mapping(uint256 => address) public vaults;
    mapping(uint256 => address) public vaultAssets;
    mapping(uint256 => address) public vaultVTokens;
    mapping(uint256 => mapping(uint256 => OptionalValue)) vaultDecimalsTable; // Keys: vault type, chain id

    uint256[] public peerChainIds;
    mapping(uint256 => address) public peers;

    uint256[] public routerTypes;
    mapping(uint256 => address) public routers;

    uint256 public systemFee; // System fee in millipercent
    address public systemFeeCollector;
    mapping(address => bool) public whitelist;

    uint256 private constant MILLIPERCENT_FACTOR = 1e5;

    uint256 private lastActionId = block.chainid * 1e7 + 555 ** 2;

    event SetVault(
        uint256 indexed vaultType,
        address indexed vaultAddress,
        address indexed vaultAssetAddress,
        address vaultVTokenAddress
    );

    event RemoveVault(uint256 indexed vaultType);

    event SetVaultCustomDecimals(uint256 indexed vaultType, KeyToValue[] customDecimals);
    event UnsetVaultCustomDecimals(uint256 indexed vaultType, uint256[] chainIds);

    event SetPeer(uint256 indexed chainId, address indexed peerAddress);
    event RemovePeer(uint256 indexed chainId);

    event SetRouter(uint256 indexed routerType, address indexed routerAddress);
    event RemoveRouter(uint256 indexed routerType);

    event SetSystemFee(uint256 systemFee);
    event SetSystemFeeCollector(address indexed systemFeeCollector);
    event SetWhitelist(address indexed whitelistAddress, bool indexed value);

    event CallProxyDeposit(uint256 amount);
    event CallProxyWithdraw(uint256 amount);

    event ActionId(uint256 indexed actionId);

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
        address tokenAddress,
        uint256 tokenAmount
    );

    constructor(
        address _callProxy,
        uint256 _systemFee, // System fee in millipercent
        address _systemFeeCollector,
        bool _grantManagerRoleToOwner
    )
        ManagerRole(_grantManagerRoleToOwner)
        AnyCallInteraction(_callProxy, true)
    {
        _setSystemFee(_systemFee);
        _setSystemFeeCollector(_systemFeeCollector);
    }

    receive() external payable {
    }

    fallback() external {
    }

    function setVault(
        uint256 _vaultType,
        address _vaultAddress,
        address _vaultAssetAddress,
        address _vaultVTokenAddress
    )
        external
        onlyManager
    {
        require(
            _vaultAddress != address(0),
            "vault-zero-address"
        );

        require(
            _vaultAssetAddress != address(0),
            "vault-asset-zero-address"
        );

        mapWithKeyListSet(vaults, vaultTypes, _vaultType, _vaultAddress);

        vaultAssets[_vaultType] = _vaultAssetAddress;
        vaultVTokens[_vaultType] = _vaultVTokenAddress;

        emit SetVault(_vaultType, _vaultAddress, _vaultAssetAddress, _vaultVTokenAddress);
    }

    function removeVault(uint256 _vaultType) external onlyManager {
        mapWithKeyListRemove(vaults, vaultTypes, _vaultType);

        delete vaultAssets[_vaultType];
        delete vaultVTokens[_vaultType];

        // - - - Vault decimals table cleanup - - -

        delete vaultDecimalsTable[_vaultType][VAULT_DECIMALS_CHAIN_ID_WILDCARD];

        uint256 peerChainIdsLength = peerChainIds.length;

        for (uint256 index; index < peerChainIdsLength; index++) {
            uint256 peerChainId = peerChainIds[index];

            delete vaultDecimalsTable[_vaultType][peerChainId];
        }

        // - - -

        emit RemoveVault(_vaultType);
    }

    function setVaultCustomDecimals(uint256 _vaultType, KeyToValue[] calldata _customDecimals) external onlyManager {
        require(
            vaults[_vaultType] != address(0),
            "vault-type"
        );

        for (uint256 index; index < _customDecimals.length; index++) {
            KeyToValue calldata customDecimalsItem = _customDecimals[index];
            vaultDecimalsTable[_vaultType][customDecimalsItem.key] = OptionalValue(true, customDecimalsItem.value);
        }

        emit SetVaultCustomDecimals(_vaultType, _customDecimals);
    }

    function unsetVaultCustomDecimals(uint256 _vaultType, uint256[] calldata _chainIds) external onlyManager {
        require(
            vaults[_vaultType] != address(0),
            "vault-type"
        );

        for (uint256 index; index < _chainIds.length; index++) {
            uint256 chainId = _chainIds[index];
            delete vaultDecimalsTable[_vaultType][chainId];
        }

        emit UnsetVaultCustomDecimals(_vaultType, _chainIds);
    }

    function setPeers(KeyToAddressValue[] calldata _peers) external onlyManager {
        for (uint256 index; index < _peers.length; index++) {
            KeyToAddressValue calldata item = _peers[index];

            uint256 chainId = item.key;
            address peerAddress = item.value;

            // Allow same configuration on multiple chains
            if (chainId == block.chainid) {
                require(
                    peerAddress == address(this),
                    "peer-address-mismatch"
                );
            } else {
                _setPeer(chainId, peerAddress);
            }
        }
    }

    function removePeers(uint256[] calldata _chainIds) external onlyManager {
        for (uint256 index; index < _chainIds.length; index++) {
            uint256 chainId = _chainIds[index];

            // Allow same configuration on multiple chains
            if (chainId != block.chainid) {
                _removePeer(chainId);
            }
        }
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

    function setSystemFeeCollector(address _systemFeeCollector) external onlyManager {
        _setSystemFeeCollector(_systemFeeCollector);
    }

    function setWhitelist(address _whitelistAddress, bool _value) external onlyManager {
        whitelist[_whitelistAddress] = _value;

        emit SetWhitelist(_whitelistAddress, _value);
    }

    function setCallProxy(address _callProxyAddress) external onlyManager {
        _setCallProxy(_callProxyAddress);
    }

    function setUseCallFallback(bool _value) external onlyManager {
        _setUseCallFallback(_value);
    }

    function callProxyDeposit() external payable onlyManager {
        uint256 amount = msg.value;

        callProxy.deposit{value: amount}(address(this));

        emit CallProxyDeposit(amount);
    }

    function callProxyWithdraw(uint256 _amount) external onlyManager {
        callProxy.withdraw(_amount);

        safeTransferNative(msg.sender, _amount);

        emit CallProxyWithdraw(_amount);
    }

    function cleanup(address _tokenAddress, uint256 _tokenAmount) external onlyManager {
        if (_tokenAddress == NATIVE_TOKEN_ADDRESS) {
            safeTransferNative(msg.sender, _tokenAmount);
        } else {
            safeTransfer(_tokenAddress, msg.sender, _tokenAmount);
        }
    }

    function execute(Action calldata _action) external payable nonReentrant returns (uint256 actionId) {
        address vaultAddress = vaults[_action.vaultType];
        address vaultAssetAddress = vaultAssets[_action.vaultType];

        require(
            vaultAddress != address(0) && vaultAssetAddress != address(0),
            "vault-type"
        );

        lastActionId++;
        actionId = lastActionId;

        emit ActionId(actionId);

        uint256 initialBalance = address(this).balance - msg.value;
        uint256 initialVaultAssetBalance = TokenBalance(vaultAssetAddress).balanceOf(address(this));

        uint256 processedAmount = _processSource(
            actionId,
            _action.sourceTokenAddress,
            vaultAssetAddress,
            _action.sourceSwapInfo,
            initialVaultAssetBalance
        );

        uint256 targetVaultAmountMax = targetVaultAmount(
            _action.vaultType,
            _action.targetChainId,
            processedAmount
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

        if (_action.targetChainId == block.chainid) {
            (bool success, ) = _processTarget(
                actionId,
                vaultAssetAddress,
                _action.targetTokenAddress,
                targetSwapInfo,
                _action.targetRecipient
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

            TargetMessage memory targetMessage = TargetMessage({
                actionId: actionId,
                sourceSender: msg.sender,
                vaultType: _action.vaultType,
                targetTokenAddress: _action.targetTokenAddress,
                targetSwapInfo: targetSwapInfo,
                targetRecipient: _action.targetRecipient
            });

            _notifyTarget(
                _action.targetChainId,
                abi.encodeWithSelector(
                    this.anyExecute.selector,
                    targetMessage
                )
            );
        }

        // - - - System fee transfer - - -

        uint256 systemFeeAmount = TokenBalance(vaultAssetAddress).balanceOf(address(this)) - initialVaultAssetBalance;

        if (systemFeeAmount != 0 && systemFeeCollector != address(0)) {
            safeTransfer(vaultAssetAddress, systemFeeCollector, systemFeeAmount);
        }

        // - - -

        // - - - Extra balance transfer - - -

        uint256 extraBalance = address(this).balance - initialBalance;

        if (extraBalance > 0) {
            safeTransferNative(msg.sender, extraBalance);
        }

        // - - -
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

            bytes memory messageData = abi.encodeWithSelector(
                this.anyExecute.selector,
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

            uint256 value = _messageFeeBySize(_targetChainId, messageData.length);

            if (value > result) {
                result = value;
            }
        }

        return result;
    }

    function callProxyExecutionBudget() external view returns (uint256 amount) {
        return callProxy.executionBudget(address(this));
    }

    function targetVaultAmount(
        uint256 _vaultType,
        uint256 _targetChainId,
        uint256 _sourceVaultAmount
    )
        public
        view
        returns (uint256)
    {
        uint256 amount = whitelist[msg.sender] ?
            _sourceVaultAmount :
            _sourceVaultAmount * (MILLIPERCENT_FACTOR - systemFee) / MILLIPERCENT_FACTOR;

        return _convertVaultDecimals(
            _vaultType,
            amount,
            block.chainid,
            _targetChainId
        );
    }

    function vaultDecimals(uint256 _vaultType, uint256 _chainId) public view returns (uint256) {
        OptionalValue storage optionalValue = vaultDecimalsTable[_vaultType][_chainId];

        if (optionalValue.isSet) {
            return optionalValue.value;
        }

        OptionalValue storage wildcardOptionalValue = vaultDecimalsTable[_vaultType][VAULT_DECIMALS_CHAIN_ID_WILDCARD];

        if (wildcardOptionalValue.isSet) {
            return wildcardOptionalValue.value;
        }

        return 18;
    }

    function tokenBalance(address _tokenAddress) public view returns (uint256) {
        if (_tokenAddress == NATIVE_TOKEN_ADDRESS) {
            return address(this).balance;
        } else {
            return TokenBalance(_tokenAddress).balanceOf(address(this));
        }
    }

    function handleAnyExecutePayload(
        uint256 _callFromChainId,
        address _callFromAddress,
        bytes calldata _payloadData
    )
        internal
        override
        returns (bool success, bytes memory result)
    {
        require(
            _callFromChainId != 0 && _callFromAddress == peers[_callFromChainId],
            "call-from-address"
        );

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

    function handleAnyFallbackPayload(
        uint256 _callToChainId,
        address _callToAddress,
        bytes calldata _payloadData
    )
        internal
        override
    {
        require(
            _callToChainId != 0 && _callToAddress == peers[_callToChainId],
            "fallback-call-to-address"
        );

        TargetMessage memory targetMessage = abi.decode(_payloadData, (TargetMessage));

        address tokenRecipient = targetMessage.sourceSender;
        uint256 vaultType = targetMessage.vaultType;
        address tokenAddress = vaultVTokens[vaultType];

        uint256 tokenAmount = _convertVaultDecimals(
            vaultType,
            targetMessage.targetSwapInfo.fromAmount,
            _callToChainId,
            block.chainid
        );

        if (tokenAddress != address(0)) {
            TokenMint(tokenAddress).mint(tokenRecipient, tokenAmount);
        }

        emit FallbackProcessed(
            targetMessage.actionId,
            tokenRecipient,
            vaultType,
            tokenAddress,
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

        resultAmount = TokenBalance(_vaultAssetAddress).balanceOf(address(this)) - initialVaultAssetBalance;

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

    function _notifyTarget(uint256 _targetChainId, bytes memory _message) private {
        address peer = peers[_targetChainId];

        require(
            peer != address(0),
            "peer-chain-id"
        );

        uint256 callFee = _messageFeeBySize(_targetChainId, _message.length);

        callProxy.anyCall{value: callFee}(
            peer,
            _message,
            callFallbackAddress,
            _targetChainId,
            PAY_FEE_ON_SOURCE_CHAIN
        );
    }

    function _setPeer(uint256 _chainId, address _peerAddress) private {
        require(
            _chainId != 0,
            "chain-id-zero"
        );

        require(
            _peerAddress != address(0),
            "peer-zero-address"
        );

        mapWithKeyListSet(peers, peerChainIds, _chainId, _peerAddress);

        emit SetPeer(_chainId, _peerAddress);
    }

    function _removePeer(uint256 _chainId) private {
        require(
            _chainId != 0,
            "chain-id-zero"
        );

        mapWithKeyListRemove(peers, peerChainIds, _chainId);

        // - - - Vault decimals table cleanup - - -

        uint256 vaultTypesLength = vaultTypes.length;

        for (uint256 index; index < vaultTypesLength; index++) {
            uint256 vaultType = vaultTypes[index];

            delete vaultDecimalsTable[vaultType][_chainId];
        }

        // - - -

        emit RemovePeer(_chainId);
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

    function _setSystemFeeCollector(address _systemFeeCollector) private {
        systemFeeCollector =_systemFeeCollector;

        emit SetSystemFeeCollector(_systemFeeCollector);
    }

    function _messageFeeBySize(uint256 _targetChainId, uint256 _messageSizeInBytes) private view returns (uint256) {
        (uint256 baseFees, uint256 feesPerByte) = callProxy.srcDefaultFees(_targetChainId);

        return baseFees + feesPerByte * _messageSizeInBytes;
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

        if (toDecimals == fromDecimals) {
            return _amount;
        }

        return _amount * 10 ** toDecimals / 10 ** fromDecimals;
    }
}