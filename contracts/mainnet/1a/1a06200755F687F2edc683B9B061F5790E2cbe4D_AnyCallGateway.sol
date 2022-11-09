// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

import { ICallProxy } from './interfaces/ICallProxy.sol';
import { ICallExecutor } from './interfaces/ICallExecutor.sol';
import { IGatewayClient } from './interfaces/IGatewayClient.sol';
import { Pausable } from './Pausable.sol';
import { ReentrancyGuard } from './ReentrancyGuard.sol';
import { BalanceManagement } from './BalanceManagement.sol';
import { ZeroAddressError } from './Errors.sol';


contract AnyCallGateway is Pausable, ReentrancyGuard, BalanceManagement {

    error OnlyCallExecutorError();
    error OnlySelfError();
    error OnlyClientError();

    error PeerAddressMismatchError();
    error ZeroChainIdError();

    error PeerNotSetError();
    error ClientNotSetError();

    error CallFromAddressError();
    error FallbackContextFromError();
    error FallbackDataSelectorError();
    error FallbackCallToAddressError();

    ICallProxy public callProxy;
    ICallExecutor public callExecutor;

    IGatewayClient public client;

    mapping(uint256 => address) public peerMap;
    uint256[] public peerChainIdList;
    mapping(uint256 => OptionalValue) public peerChainIdIndexMap;

    uint256 private constant PAY_FEE_ON_SOURCE_CHAIN = 0x1 << 1;
    uint256 private constant SELECTOR_DATA_SIZE = 4;

    event SetCallProxy(address indexed callProxyAddress, address indexed callExecutorAddress);

    event SetClient(address indexed clientAddress);

    event SetPeer(uint256 indexed chainId, address indexed peerAddress);
    event RemovePeer(uint256 indexed chainId);

    event CallProxyDeposit(uint256 amount);
    event CallProxyWithdraw(uint256 amount);

    constructor(
        address _callProxyAddress,
        address _ownerAddress,
        bool _grantManagerRoleToOwner
    )
    {
        _setCallProxy(_callProxyAddress);

        _initRoles(_ownerAddress, _grantManagerRoleToOwner);
    }

    modifier onlyCallExecutor {
        if (msg.sender != address(callExecutor)) {
            revert OnlyCallExecutorError();
        }

        _;
    }

    modifier onlySelf {
        if (msg.sender != address(this)) {
            revert OnlySelfError();
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

    function setCallProxy(address _callProxyAddress) external onlyManager {
        _setCallProxy(_callProxyAddress);
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
        address peerAddress = peerMap[_targetChainId];

        if (peerAddress == address(0)) {
            revert PeerNotSetError();
        }

        callProxy.anyCall{value: msg.value}(
            peerAddress,
            abi.encodePacked(this.anyExecute.selector, _message),
            _useFallback ?
                address(this) :
                address(0),
            _targetChainId,
            PAY_FEE_ON_SOURCE_CHAIN
        );
    }

    function peerCount() external view returns (uint256) {
        return peerChainIdList.length;
    }

    function callProxyExecutionBudget() external view returns (uint256 amount) {
        return callProxy.executionBudget(address(this));
    }

    function messageFee(
        uint256 _targetChainId,
        uint256 _messageSizeInBytes
    )
        public
        view
        returns (uint256)
    {
        return callProxy.calcSrcFees(
            address(this),
            _targetChainId,
            _messageSizeInBytes + SELECTOR_DATA_SIZE
        );
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

    function anyExecute(bytes calldata _data)
        external
        nonReentrant
        onlyCallExecutor
        whenNotPaused
        returns (bool success, bytes memory result)
    {
        bytes4 selector = bytes4(_data[:SELECTOR_DATA_SIZE]);

        if (selector == this.anyExecute.selector) {
            if (address(client) == address(0)) {
                revert ClientNotSetError();
            }

            (address from, uint256 fromChainID, ) = callExecutor.context();

            bool condition =
                fromChainID != 0 &&
                from != address(0) &&
                from == peerMap[fromChainID];

            if (!condition) {
                revert CallFromAddressError();
            }

            return client.handleExecutionPayload(fromChainID, _data[SELECTOR_DATA_SIZE:]);
        } else if (selector == this.anyFallback.selector) {
            (address fallbackTo, bytes memory fallbackData) = abi.decode(_data[SELECTOR_DATA_SIZE:], (address, bytes));

            this.anyFallback(fallbackTo, fallbackData);

            return (true, "");
        } else {
            return (false, "call-selector");
        }
    }

    function anyFallback(address _to, bytes calldata _data) external onlySelf {
        if (address(client) == address(0)) {
            revert ClientNotSetError();
        }

        (address from, uint256 fromChainID, ) = callExecutor.context();

        if (from != address(this)) {
            revert FallbackContextFromError();
        }

        if (bytes4(_data[:SELECTOR_DATA_SIZE]) != this.anyExecute.selector) {
            revert FallbackDataSelectorError();
        }

        bool condition =
            fromChainID != 0 &&
            _to != address(0) &&
            _to == peerMap[fromChainID];

        if (!condition) {
            revert FallbackCallToAddressError();
        }

        client.handleFallbackPayload(fromChainID, _data[SELECTOR_DATA_SIZE:]);
    }

    function _setCallProxy(address _callProxyAddress) private {
        if (_callProxyAddress == address(0)) {
            revert ZeroAddressError();
        }

        callProxy = ICallProxy(_callProxyAddress);
        callExecutor = callProxy.executor();

        emit SetCallProxy(_callProxyAddress, address(callExecutor));
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


interface ICallExecutor {
    function context() external view returns (address from, uint256 fromChainID, uint256 nonce);
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

import { ICallExecutor } from './ICallExecutor.sol';


interface ICallProxy {
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

    function executor() external view returns (ICallExecutor);

    function calcSrcFees(
        address _app,
        uint256 _toChainID,
        uint256 _dataLength
    )
        external
        view
        returns (uint256)
    ;

    function executionBudget(address _account) external view returns (uint256);
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


interface ITokenBalance {
    function balanceOf(address _account) external view returns (uint256);
}