/**
 *Submitted for verification at Etherscan.io on 2022-09-30
*/

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;


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

    function executor() external view returns (CallExecutor);

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


interface CallExecutor {
    function context() external view returns (address from, uint256 fromChainID, uint256 nonce);
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

    function safeTransfer(address _token, address _to, uint256 _value) internal {
        // 0xa9059cbb is the selector for "transfer(address,uint256)"
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(0xa9059cbb, _to, _value));

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "safe-transfer"
        );
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


contract AnyCallInteraction is Pausable, ReentrancyGuard, SafeTransfer, DataStructures {

    address public constant NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    CallProxy public callProxy;
    CallExecutor public callExecutor;

    InteractionClient public client;

    uint256[] public peerChainIds;
    mapping(uint256 => address) public peers;

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

    modifier onlyClient {
        require(
            msg.sender == address(client),
            "only-client"
        );

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
        require(
            _clientAddress != address(0),
            "client-zero-address"
        );

        client = InteractionClient(_clientAddress);

        emit SetClient(_clientAddress);
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
        address peerAddress = peers[_targetChainId];

        require(
            peerAddress != address(0),
            "peer-chain-id"
        );

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

        emit RemovePeer(_chainId);
    }

    function anyExecute(bytes calldata _data)
        external
        nonReentrant
        onlyCallExecutor
        whenNotPaused
        returns (bool success, bytes memory result)
    {
        bytes4 selector = bytes4(_data[:4]);

        if (selector == this.anyExecute.selector) {
            require(
                address(client) != address(0),
                "client-zero-address"
            );

            (address from, uint256 fromChainID, ) = callExecutor.context();

            require(
                fromChainID != 0 &&
                from != address(0) &&
                from == peers[fromChainID],
                "call-from-address"
            );

            return client.handleExecutionPayload(fromChainID, _data[4:]);
        } else if (selector == this.anyFallback.selector) {
            (address fallbackTo, bytes memory fallbackData) = abi.decode(_data[4:], (address, bytes));

            this.anyFallback(fallbackTo, fallbackData);

            return (true, "");
        } else {
            return (false, "call-selector");
        }
    }

    function anyFallback(address _to, bytes calldata _data) external onlySelf {
        require(
            address(client) != address(0),
            "client-zero-address"
        );

        (address from, uint256 fromChainID, ) = callExecutor.context();

        require(
            from == address(this),
            "fallback-context-from"
        );

        require(
            bytes4(_data[:4]) == this.anyExecute.selector,
            "fallback-data-selector"
        );

        require(
            fromChainID != 0 &&
            _to != address(0) &&
            _to == peers[fromChainID],
            "fallback-call-to-address"
        );

        client.handleFallbackPayload(fromChainID, _data[4:]);
    }

    function _setCallProxy(address _callProxyAddress) private {
        require(
            _callProxyAddress != address(0),
            "call-proxy-zero-address"
        );

        callProxy = CallProxy(_callProxyAddress);
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