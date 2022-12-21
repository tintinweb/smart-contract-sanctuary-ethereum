// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

import { IGateway } from "./interfaces/IGateway.sol";
import { ILayerZeroProxy } from './interfaces/ILayerZeroProxy.sol';
import { IGatewayClient } from './interfaces/IGatewayClient.sol';
import { Pausable } from './Pausable.sol';
import { ReentrancyGuard } from './ReentrancyGuard.sol';
import { BalanceManagement } from './BalanceManagement.sol';
import { ZeroAddressError } from './Errors.sol';


contract LayerZeroGateway is Pausable, ReentrancyGuard, BalanceManagement, IGateway {

    error OnlyLayerZeroProxyError();
    error OnlyClientError();

    error PeerAddressMismatchError();
    error ZeroChainIdError();

    error PeerNotSetError();
    error LayerZeroChainIdNotSetError();
    error ClientNotSetError();

    error FallbackNotSupportedError();

    struct ChainIdPair {
        uint256 standardId;
        uint16 layerZeroId;
    }

    ILayerZeroProxy public layerZeroProxy;

    IGatewayClient public client;

    mapping(uint256 => address) public peerMap;
    uint256[] public peerChainIdList;
    mapping(uint256 => OptionalValue) public peerChainIdIndexMap;

    uint256 public targetGas;
    uint256 public gasReserve;

    mapping(uint256 => uint16) public standardToLayerZeroChainId;
    mapping(uint16 => uint256) public layerZeroToStandardChainId;

    uint16 private constant ADAPTER_PARAMETERS_VERSION = 1;

    event SetLayerZeroProxy(address indexed layerZeroProxyAddress);

    event SetClient(address indexed clientAddress);

    event SetPeer(uint256 indexed chainId, address indexed peerAddress);
    event RemovePeer(uint256 indexed chainId);

    event SetTargetGas(uint256 targetGas);
    event SetGasReserve(uint256 gasReserve);

    event SetChainIdPair(uint256 indexed standardId, uint16 indexed layerZeroId);
    event RemoveChainIdPair(uint256 indexed standardId, uint16 indexed layerZeroId);

    event TargetPausedFailure();
    event TargetClientNotSetFailure();
    event TargetFromAddressFailure(uint256 indexed sourceStandardChainId, address indexed fromAddress);
    event TargetGasReserveFailure(uint256 indexed sourceStandardChainId);
    event TargetExecutionFailure();

    constructor(
        address _layerZeroProxyAddress,
        uint256 _targetGas,
        ChainIdPair[] memory _chainIdPairs,
        address _ownerAddress,
        bool _grantManagerRoleToOwner
    )
    {
        _setLayerZeroProxy(_layerZeroProxyAddress);
        _setTargetGas(_targetGas);

        for (uint256 index; index < _chainIdPairs.length; index++) {
            ChainIdPair memory chainIdPair = _chainIdPairs[index];

            _setChainIdPair(chainIdPair.standardId, chainIdPair.layerZeroId);
        }

        _initRoles(_ownerAddress, _grantManagerRoleToOwner);
    }

    modifier onlyLayerZeroProxy {
        if (msg.sender != address(layerZeroProxy)) {
            revert OnlyLayerZeroProxyError();
        }

        _;
    }

    modifier onlyClient {
        if (msg.sender != address(client)) {
            revert OnlyClientError();
        }

        _;
    }

    receive() external payable {
    }

    fallback() external {
    }

    function setLayerZeroProxy(address _layerZeroProxyAddress) external onlyManager {
        _setLayerZeroProxy(_layerZeroProxyAddress);
    }

    function setClient(address _clientAddress) external onlyManager {
        if (_clientAddress == address(0)) {
            revert ZeroAddressError();
        }

        client = IGatewayClient(_clientAddress);

        emit SetClient(_clientAddress);
    }

    function setPeers(KeyToAddressValue[] calldata _peers) external onlyManager {
        for (uint256 index; index < _peers.length; index++) {
            KeyToAddressValue calldata item = _peers[index];

            uint256 chainId = item.key;
            address peerAddress = item.value;

            // Allow same configuration on multiple chains
            if (chainId == block.chainid) {
                if (peerAddress != address(this)) {
                    revert PeerAddressMismatchError();
                }
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

    function setTargetGas(uint256 _targetGas) external onlyManager {
        _setTargetGas(_targetGas);
    }

    function setGasReserve(uint256 _gasReserve) external onlyManager {
        gasReserve = _gasReserve;

        emit SetGasReserve(_gasReserve);
    }

    function setChainIdPairs(ChainIdPair[] calldata _chainIdPairs) external onlyManager {
        for (uint256 index; index < _chainIdPairs.length; index++) {
            ChainIdPair calldata chainIdPair = _chainIdPairs[index];

            _setChainIdPair(chainIdPair.standardId, chainIdPair.layerZeroId);
        }
    }

    function removeChainIdPairs(uint256[] calldata _standardChainIds) external onlyManager {
        for (uint256 index; index < _standardChainIds.length; index++) {
            uint256 standardId = _standardChainIds[index];

            _removeChainIdPair(standardId);
        }
    }

    function sendMessage(
        uint256 _targetChainId,
        bytes calldata _message,
        bool _useFallback
    )
        external
        payable
        onlyClient
        whenNotPaused
    {
        if (_useFallback) {
            revert FallbackNotSupportedError();
        }

        address peerAddress = peerMap[_targetChainId];

        if (peerAddress == address(0)) {
            revert PeerNotSetError();
        }

        uint16 targetLayerZeroChainId = standardToLayerZeroChainId[_targetChainId];

        if (targetLayerZeroChainId == 0) {
            revert LayerZeroChainIdNotSetError();
        }

        layerZeroProxy.send{value: msg.value}(
            targetLayerZeroChainId,
            abi.encodePacked(peerAddress, address(this)),
            _message,
            payable(msg.sender), // refund address
            address(0), // future parameter
            _getAdapterParameters()
        );
    }

    function lzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 /*_nonce*/,
        bytes calldata _payload
    )
        external
        nonReentrant
        onlyLayerZeroProxy
    {
        if (paused) {
            emit TargetPausedFailure();

            return;
        }

        if (address(client) == address(0)) {
            emit TargetClientNotSetFailure();

            return;
        }

        uint256 sourceStandardChainId = layerZeroToStandardChainId[_srcChainId];

        // use assembly to extract the address
        address fromAddress;
        assembly {
            fromAddress := mload(add(_srcAddress, 20))
        }

        bool condition =
            sourceStandardChainId != 0 &&
            fromAddress != address(0) &&
            fromAddress == peerMap[sourceStandardChainId];

        if (!condition) {
            emit TargetFromAddressFailure(sourceStandardChainId, fromAddress);

            return;
        }

        uint256 gasLeft = gasleft();

        if (gasLeft < gasReserve) {
            emit TargetGasReserveFailure(sourceStandardChainId);

            return;
        }

        try client.handleExecutionPayload{gas: gasLeft - gasReserve}(sourceStandardChainId, _payload) {
        } catch {
            emit TargetExecutionFailure();
        }
    }

    function peerCount() external view returns (uint256) {
        return peerChainIdList.length;
    }

    function messageFee(
        uint256 _targetChainId,
        uint256 _messageSizeInBytes
    )
        public
        view
        returns (uint256)
    {
        uint16 targetLayerZeroChainId = standardToLayerZeroChainId[_targetChainId];

        (uint256 nativeFee, ) = layerZeroProxy.estimateFees(
            targetLayerZeroChainId,
            address(this),
            new bytes(_messageSizeInBytes),
            false,
            _getAdapterParameters()
        );

        return nativeFee;
    }

    function _setPeer(uint256 _chainId, address _peerAddress) private {
        if (_chainId == 0) {
            revert ZeroChainIdError();
        }

        if (_peerAddress == address(0)) {
            revert ZeroAddressError();
        }

        combinedMapSet(peerMap, peerChainIdList, peerChainIdIndexMap, _chainId, _peerAddress);

        emit SetPeer(_chainId, _peerAddress);
    }

    function _removePeer(uint256 _chainId) private {
        if (_chainId == 0) {
            revert ZeroChainIdError();
        }

        combinedMapRemove(peerMap, peerChainIdList, peerChainIdIndexMap, _chainId);

        emit RemovePeer(_chainId);
    }

    function _setLayerZeroProxy(address _layerZeroProxyAddress) private {
        if (_layerZeroProxyAddress == address(0)) {
            revert ZeroAddressError();
        }

        layerZeroProxy = ILayerZeroProxy(_layerZeroProxyAddress);

        emit SetLayerZeroProxy(_layerZeroProxyAddress);
    }

    function _setTargetGas(uint256 _targetGas) private {
        targetGas = _targetGas;

        emit SetTargetGas(_targetGas);
    }

    function _setChainIdPair(uint256 _standardId, uint16 _layerZeroId) private {
        standardToLayerZeroChainId[_standardId] = _layerZeroId;
        layerZeroToStandardChainId[_layerZeroId] = _standardId;

        emit SetChainIdPair(_standardId, _layerZeroId);
    }

    function _removeChainIdPair(uint256 _standardId) private {
        uint16 layerZeroId = standardToLayerZeroChainId[_standardId];

        delete standardToLayerZeroChainId[_standardId];
        delete layerZeroToStandardChainId[layerZeroId];

        emit RemoveChainIdPair(_standardId, layerZeroId);
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

    function _getAdapterParameters() private view returns (bytes memory) {
        return abi.encodePacked(ADAPTER_PARAMETERS_VERSION, targetGas);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

import { ManagerRole } from './ManagerRole.sol';


abstract contract Pausable is ManagerRole {

    error WhenNotPausedError();
    error WhenPausedError();

    bool public paused = false;

    event Pause();
    event Unpause();

    modifier whenNotPaused() {
        if (paused) {
            revert WhenNotPausedError();
        }

        _;
    }

    modifier whenPaused() {
        if (!paused) {
            revert WhenPausedError();
        }

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

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;


interface IGatewayClient {
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

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;


interface ILayerZeroProxy {
    function send(
        uint16 _dstChainId,
        bytes calldata _destination,
        bytes calldata _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    )
        external
        payable
    ;

    function estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        bytes calldata _payload,
        bool _payInZRO,
        bytes calldata _adapterParam
    )
        external
        view
        returns (uint256 nativeFee, uint256 zroFee)
    ;
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;


interface IGateway {
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

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;


abstract contract ReentrancyGuard {

    error ReentrantCallError();

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
        if (_status == _ENTERED) {
            revert ReentrantCallError();
        }

        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;


error ZeroAddressError();

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


abstract contract NativeTokenAddress {

    address public constant NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;


interface ITokenBalance {
    function balanceOf(address _account) external view returns (uint256);
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