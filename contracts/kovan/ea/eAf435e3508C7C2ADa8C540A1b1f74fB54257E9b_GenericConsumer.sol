// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import { Chainlink, ChainlinkClient, LinkTokenInterface } from "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import { ConfirmedOwner } from "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import { TypeAndVersionInterface } from "@chainlink/contracts/src/v0.8/interfaces/TypeAndVersionInterface.sol";
import { KeeperCompatible } from "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IExternalFulfillment } from "./IExternalFulfillment.sol";
import { Entry, EntryLibrary } from "./EntryLibrary.sol";
import { LotLibrary } from "./LotLibrary.sol";

contract GenericConsumer is
    TypeAndVersionInterface,
    ConfirmedOwner,
    AccessControl,
    Pausable,
    ReentrancyGuard,
    ChainlinkClient,
    KeeperCompatible
{
    using Address for address;
    using Chainlink for Chainlink.Request;
    using EntryLibrary for EntryLibrary.Map;
    using LotLibrary for LotLibrary.Map;

    uint8 private constant MIN_FALLBACK_MSG_DATA_LENGTH = 36;
    bytes32 private constant NO_ENTRY_KEY = bytes32(0);
    address private constant NO_CALLBACK_ADDR = address(0);
    bytes32 public constant REQUESTER_ROLE = keccak256("REQUESTER_ROLE");
    LinkTokenInterface public immutable LINK;
    uint256 private s_latestRoundId;
    uint256 private s_minGasLimitPerformUpkeep;
    string private s_description;
    mapping(uint256 => bytes20) private s_lotToSha1; /* lot */ /* sha1 */
    // solhint-disable-next-line max-line-length
    mapping(uint256 => mapping(bytes32 => uint256)) private s_lotToLastRequestTimestampMap; /* lot */ /* key */ /* lastRequestTimestamp */
    mapping(bytes32 => address) private s_requestIdTocallbackAddr; /* requestId */ /* callbackAddr */
    LotLibrary.Map private s_lotToEntryMap; /* lot */ /* key */ /* Entry */

    error GenericConsumer__CallbackAddrIsGenericConsumer();
    error GenericConsumer__CallbackAddrIsNotAContract();
    error GenericConsumer__CallbackFunctionSignatureIsZero();
    error GenericConsumer__EntryIsInactive(uint256 lot, bytes32 key);
    error GenericConsumer__EntryIsNotInserted(uint256 lot, bytes32 key);
    error GenericConsumer__EntryIsNotScheduled(
        uint256 lot,
        bytes32 key,
        uint128 startAt,
        uint128 interval,
        uint256 lastRequestTimestamp,
        uint256 blockTimestamp
    );
    error GenericConsumer__EntryMapKeysAreEmpty();
    error GenericConsumer__FallbackMsgDataIsInvalid();
    error GenericConsumer__IntervalIsZero();
    error GenericConsumer__LengthIsNotEqual();
    error GenericConsumer__LinkAllowanceIsInsufficient(uint256 allowance, uint256 payment);
    error GenericConsumer__LinkBalanceIsInsufficient(uint256 balance, uint256 payment);
    error GenericConsumer__LinkTransferFailed(address to, uint256 amount);
    error GenericConsumer__LinkTransferFromFailed(address from, address to, uint256 payment);
    error GenericConsumer__LotIsEmpty(uint256 lot);
    error GenericConsumer__LotIsNotInserted(uint256 lot);
    error GenericConsumer__OracleIsNotAContract();
    error GenericConsumer__PaymentIsZero();
    error GenericConsumer__SetChainlinkExternalRequestFailed(address callbackAddr, bytes32 requestId, bytes32 key);
    error GenericConsumer__SpecIdIsZero();

    event EntryRemoved(uint256 indexed lot, bytes32 indexed key);
    event EntryRequested(
        uint256 roundId,
        uint256 indexed lot,
        bytes32 indexed key,
        bytes32 indexed requestId,
        uint256 blockTimestamp
    );
    event EntrySet(uint256 indexed lot, bytes32 indexed key, Entry entry);
    event FundsWithdrawn(address payee, uint256 amount);
    event RequestFulfilled(
        bytes32 indexed requestId,
        bool success,
        bool isForwarded,
        address indexed callbackAddr,
        bytes4 indexed callbackFunctionSignature,
        bytes data
    );
    event LastRequestTimestampSet(uint256 indexed lot, bytes32 indexed key, uint256 lastRequestTimestamp);
    event LotRemoved(uint256 indexed lot);

    /**
     * @param _link the LINK token address.
     * @param _description the contract description.
     */
    constructor(
        address _link,
        string memory _description,
        address[] memory _admins,
        address[] memory _requesters,
        uint256 _minGasLimit
    ) ConfirmedOwner(msg.sender) {
        setChainlinkToken(_link);
        LINK = LinkTokenInterface(_link);
        s_description = _description;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRoleTo(DEFAULT_ADMIN_ROLE, _admins);
        _grantRoleTo(REQUESTER_ROLE, _requesters);
        s_minGasLimitPerformUpkeep = _minGasLimit;
    }

    // solhint-disable-next-line no-complex-fallback, payable-fallback
    fallback() external whenNotPaused nonReentrant {
        bytes4 callbackFunctionSignature = msg.sig; // bytes4(msg.data);
        bytes calldata data = msg.data;
        _requireFallbackMsgData(data);
        bytes32 requestId = abi.decode(data[4:], (bytes32));
        validateChainlinkCallback(requestId);
        address callbackAddr = s_requestIdTocallbackAddr[requestId];
        if (callbackAddr == NO_CALLBACK_ADDR) {
            emit RequestFulfilled(requestId, true, false, address(this), callbackFunctionSignature, data);
        } else {
            delete s_requestIdTocallbackAddr[requestId];
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = callbackAddr.call(data);
            emit RequestFulfilled(requestId, success, true, callbackAddr, callbackFunctionSignature, data);
        }
    }

    /* ========== EXTERNAL FUNCTIONS ========== */

    function cancelRequest(
        bytes32 _requestId,
        uint256 _payment,
        bytes4 _callbackFunctionSignature,
        uint256 _expiration
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        cancelChainlinkRequest(_requestId, _payment, _callbackFunctionSignature, _expiration);
    }

    /**
     * @notice Pauses the contract, which prevents executing requests
     */
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function performUpkeep(bytes calldata _performData) external override whenNotPaused nonReentrant {
        (uint256 lot, bytes32[] memory keys) = abi.decode(_performData, (uint256, bytes32[]));
        _requireLotInserted(lot, s_lotToEntryMap.isInserted(lot));
        uint256 keysLength = keys.length;
        _requireEntryMapKeys(keysLength);
        EntryLibrary.Map storage s_keyToEntry = s_lotToEntryMap.getLot(lot);
        uint256 blockTimestamp = block.timestamp;
        uint256 roundId = s_latestRoundId + 1;
        mapping(bytes32 => uint256) storage s_keyToLastRequestTimestamp = s_lotToLastRequestTimestampMap[lot];
        uint256 minGasLimit = s_minGasLimitPerformUpkeep;
        for (uint256 i = 0; i < keysLength; ) {
            bytes32 key = keys[i];
            unchecked {
                ++i;
            }
            _requireEntryInserted(lot, key, s_keyToEntry.isInserted(key));
            Entry memory entry = s_keyToEntry.getEntry(key);
            _requireEntryActive(lot, key, entry.inactive);
            _requireEntryScheduled(
                lot,
                key,
                entry.startAt,
                entry.interval,
                s_keyToLastRequestTimestamp[key],
                blockTimestamp
            );
            bytes32 requestId = _buildAndSendOperatorRequest(
                entry.specId,
                entry.oracle,
                entry.payment,
                entry.callbackAddr,
                entry.callbackFunctionSignature,
                entry.buffer,
                key
            );
            s_keyToLastRequestTimestamp[key] = blockTimestamp;
            emit EntryRequested(roundId, lot, key, requestId, blockTimestamp);
            if (gasleft() <= minGasLimit) break;
        }
        s_latestRoundId = roundId;
    }

    function requestAndForwardData(
        bytes32 _specId,
        address _oracle,
        uint256 _payment,
        address _callbackAddr,
        bytes4 _callbackFunctionSignature,
        bytes calldata _buffer
    ) external onlyRole(REQUESTER_ROLE) whenNotPaused nonReentrant returns (bytes32) {
        return
            _requestData(_specId, _oracle, _payment, _callbackAddr, _callbackFunctionSignature, _buffer, true, false);
    }

    function requestAndForwardDataPaying(
        bytes32 _specId,
        address _oracle,
        uint256 _payment,
        address _callbackAddr,
        bytes4 _callbackFunctionSignature,
        bytes calldata _buffer
    ) external whenNotPaused nonReentrant returns (bytes32) {
        return _requestData(_specId, _oracle, _payment, _callbackAddr, _callbackFunctionSignature, _buffer, true, true);
    }

    function requestData(
        bytes32 _specId,
        address _oracle,
        uint256 _payment,
        bytes4 _callbackFunctionSignature,
        bytes calldata _buffer
    ) external onlyRole(REQUESTER_ROLE) whenNotPaused nonReentrant returns (bytes32) {
        return
            _requestData(_specId, _oracle, _payment, address(this), _callbackFunctionSignature, _buffer, false, false);
    }

    function requestDataPaying(
        bytes32 _specId,
        address _oracle,
        uint256 _payment,
        bytes4 _callbackFunctionSignature,
        bytes calldata _buffer
    ) external whenNotPaused nonReentrant returns (bytes32) {
        return
            _requestData(_specId, _oracle, _payment, address(this), _callbackFunctionSignature, _buffer, false, true);
    }

    function removeEntries(uint256 _lot, bytes32[] calldata _keys) external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        _requireLotInserted(_lot, s_lotToEntryMap.isInserted(_lot));
        _requireEntryMapKeys(_keys.length);
        uint256 keysLength = _keys.length;
        EntryLibrary.Map storage s_keyToEntry = s_lotToEntryMap.getLot(_lot);
        mapping(bytes32 => uint256) storage s_keyToLastRequestTimestamp = s_lotToLastRequestTimestampMap[_lot];
        for (uint256 i = 0; i < keysLength; ) {
            bytes32 key = _keys[i];
            _removeEntry(s_keyToEntry, _lot, key);
            delete s_keyToLastRequestTimestamp[key];
            unchecked {
                ++i;
            }
        }
        _cleanLotData(s_keyToEntry.size(), _lot);
    }

    function removeEntry(uint256 _lot, bytes32 _key) external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        _requireLotInserted(_lot, s_lotToEntryMap.isInserted(_lot));
        EntryLibrary.Map storage s_keyToEntry = s_lotToEntryMap.getLot(_lot);
        _removeEntry(s_keyToEntry, _lot, _key);
        delete s_lotToLastRequestTimestampMap[_lot][_key];
        _cleanLotData(s_keyToEntry.size(), _lot);
    }

    function removeLot(uint256 _lot) external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        _requireLotInserted(_lot, s_lotToEntryMap.isInserted(_lot));
        bytes32[] memory keys = s_lotToEntryMap.getLot(_lot).keys;
        uint256 keysLength = keys.length;
        mapping(bytes32 => uint256) storage s_keyToLastRequestTimestamp = s_lotToLastRequestTimestampMap[_lot];
        for (uint256 i = 0; i < keysLength; ) {
            delete s_keyToLastRequestTimestamp[keys[i]];
            unchecked {
                ++i;
            }
        }
        s_lotToEntryMap.getLot(_lot).removeAll();
        _cleanLotData(0, _lot);
        emit LotRemoved(_lot);
    }

    function setDescription(string calldata _description) external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        s_description = _description;
    }

    function setEntries(
        uint256 _lot,
        bytes32[] calldata _keys,
        Entry[] calldata _entries
    ) external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        uint256 keysLength = _keys.length;
        _requireEntryMapKeys(keysLength);
        _requireEqualLength(keysLength, _entries.length);
        EntryLibrary.Map storage s_keyToEntry = s_lotToEntryMap.getLot(_lot);
        for (uint256 i = 0; i < keysLength; ) {
            _setEntry(s_keyToEntry, _lot, _keys[i], _entries[i]);
            unchecked {
                ++i;
            }
        }
        s_lotToEntryMap.set(_lot);
    }

    function setEntry(
        uint256 _lot,
        bytes32 _key,
        Entry calldata _entry
    ) external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        _setEntry(s_lotToEntryMap.getLot(_lot), _lot, _key, _entry);
        s_lotToEntryMap.set(_lot);
    }

    function setLastRequestTimestamp(
        uint256 _lot,
        bytes32 _key,
        uint256 _lastRequestTimestamp
    ) external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        _requireLotInserted(_lot, s_lotToEntryMap.isInserted(_lot));
        _setLastRequestTimestamp(
            s_lotToEntryMap.getLot(_lot),
            s_lotToLastRequestTimestampMap[_lot],
            _lot,
            _key,
            _lastRequestTimestamp
        );
    }

    function setLastRequestTimestamps(
        uint256 _lot,
        bytes32[] calldata _keys,
        uint256[] calldata _lastRequestTimestamps
    ) external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        _requireLotInserted(_lot, s_lotToEntryMap.isInserted(_lot));
        uint256 keysLength = _keys.length;
        _requireEntryMapKeys(keysLength);
        _requireEqualLength(keysLength, _lastRequestTimestamps.length);
        EntryLibrary.Map storage s_keyToEntry = s_lotToEntryMap.getLot(_lot);
        mapping(bytes32 => uint256) storage s_keyToLastRequestTimestamp = s_lotToLastRequestTimestampMap[_lot];
        for (uint256 i = 0; i < keysLength; ) {
            _setLastRequestTimestamp(
                s_keyToEntry,
                s_keyToLastRequestTimestamp,
                _lot,
                _keys[i],
                _lastRequestTimestamps[i]
            );
            unchecked {
                ++i;
            }
        }
    }

    function setLatestRoundId(uint256 _latestRoundId) external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        s_latestRoundId = _latestRoundId;
    }

    function setMinGasLimitPerformUpkeep(uint256 _minGasLimit) external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        s_minGasLimitPerformUpkeep = _minGasLimit;
    }

    function setSha1(uint256 _lot, bytes20 _sha1) external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        _requireLotInserted(_lot, s_lotToEntryMap.isInserted(_lot));
        s_lotToSha1[_lot] = _sha1;
    }

    /**
     * @notice Unpauses the contract
     */
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function withdraw(address payable _payee, uint256 _amount) external onlyOwner {
        emit FundsWithdrawn(_payee, _amount);
        _requireLinkTransfer(LINK.transfer(_payee, _amount), _payee, _amount);
    }

    /* ========== EXTERNAL VIEW FUNCTIONS ========== */

    function availableFunds() external view returns (uint256) {
        return _availableFunds();
    }

    function checkUpkeep(bytes calldata _checkData) external view override cannotExecute returns (bool, bytes memory) {
        uint256 lot = abi.decode(_checkData, (uint256));
        _requireLotInserted(lot, s_lotToEntryMap.isInserted(lot));
        EntryLibrary.Map storage s_keyToEntry = s_lotToEntryMap.getLot(lot);
        uint256 keysLength = s_keyToEntry.size();
        _requireLotNotEmpty(lot, keysLength); // NB: assertion-like
        bytes32[] memory keys = new bytes32[](keysLength);
        mapping(bytes32 => uint256) storage s_keyToLastRequestTimestamp = s_lotToLastRequestTimestampMap[lot];
        uint256 blockTimestamp = block.timestamp;
        uint256 noEntriesToRequest = 0;
        uint256 roundPayment = 0;
        for (uint256 i = 0; i < keysLength; ) {
            bytes32 key = s_keyToEntry.getKeyAtIndex(i);
            unchecked {
                ++i;
            }

            Entry memory entry = s_keyToEntry.getEntry(key);
            if (entry.inactive) continue;
            if (!_isScheduled(entry.startAt, entry.interval, s_keyToLastRequestTimestamp[key], blockTimestamp))
                continue;
            keys[noEntriesToRequest] = key;
            roundPayment += entry.payment;
            unchecked {
                ++noEntriesToRequest;
            }
        }
        bool isUpkeepNeeded;
        bytes memory performData;
        if (noEntriesToRequest > 0 && _availableFunds() >= roundPayment) {
            isUpkeepNeeded = true;
            uint256 noEmptySlots = keysLength - noEntriesToRequest;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                mstore(keys, sub(mload(keys), noEmptySlots))
            }
            performData = abi.encode(lot, keys);
        }
        return (isUpkeepNeeded, performData);
    }

    function getDescription() external view returns (string memory) {
        return s_description;
    }

    function getEntry(uint256 _lot, bytes32 _key) external view returns (Entry memory) {
        _requireLotInserted(_lot, s_lotToEntryMap.isInserted(_lot));
        _requireEntryInserted(_lot, _key, s_lotToEntryMap.getLot(_lot).isInserted(_key));
        return s_lotToEntryMap.getLot(_lot).getEntry(_key);
    }

    function getEntryIsInserted(uint256 _lot, bytes32 _key) external view returns (bool) {
        _requireLotInserted(_lot, s_lotToEntryMap.isInserted(_lot));
        return s_lotToEntryMap.getLot(_lot).isInserted(_key);
    }

    function getEntryMapKeyAtIndex(uint256 _lot, uint256 _index) external view returns (bytes32) {
        _requireLotInserted(_lot, s_lotToEntryMap.isInserted(_lot));
        return s_lotToEntryMap.getLot(_lot).getKeyAtIndex(_index);
    }

    function getEntryMapKeys(uint256 _lot) external view returns (bytes32[] memory) {
        _requireLotInserted(_lot, s_lotToEntryMap.isInserted(_lot));
        return s_lotToEntryMap.getLot(_lot).keys;
    }

    function getLastRequestTimestamp(uint256 _lot, bytes32 _key) external view returns (uint256) {
        _requireLotInserted(_lot, s_lotToEntryMap.isInserted(_lot));
        _requireEntryInserted(_lot, _key, s_lotToEntryMap.getLot(_lot).isInserted(_key));
        return s_lotToLastRequestTimestampMap[_lot][_key];
    }

    function getLatestRoundId() external view returns (uint256) {
        return s_latestRoundId;
    }

    function getLotIsInserted(uint256 _lot) external view returns (bool) {
        return s_lotToEntryMap.isInserted(_lot);
    }

    function getLots() external view returns (uint256[] memory) {
        return s_lotToEntryMap.lots;
    }

    function getMinGasLimitPerformUpkeep() external view returns (uint256) {
        return s_minGasLimitPerformUpkeep;
    }

    function getNumberOfEntries(uint256 _lot) external view returns (uint256) {
        _requireLotInserted(_lot, s_lotToEntryMap.isInserted(_lot));
        return s_lotToEntryMap.getLot(_lot).size();
    }

    function getNumberOfLots() external view returns (uint256) {
        return s_lotToEntryMap.size();
    }

    function getSha1(uint256 _lot) external view returns (bytes20) {
        _requireLotInserted(_lot, s_lotToEntryMap.isInserted(_lot));
        return s_lotToSha1[_lot];
    }

    /* ========== EXTERNAL PURE FUNCTIONS ========== */

    /**
     * @notice versions:
     *
     * - GenericConsumer 1.0.0: initial release
     *
     * @inheritdoc TypeAndVersionInterface
     */
    function typeAndVersion() external pure virtual override returns (string memory) {
        return "GenericConsumer 1.0.0";
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _buildAndSendOperatorRequest(
        bytes32 _specId,
        address _oracle,
        uint256 _payment,
        address _callbackAddr,
        bytes4 _callbackFunctionSignature,
        bytes memory _buffer,
        bytes32 _key
    ) private returns (bytes32) {
        Chainlink.Request memory req = buildOperatorRequest(_specId, _callbackFunctionSignature);
        req.setBuffer(_buffer);
        bytes32 requestId = sendOperatorRequestTo(_oracle, req, _payment);
        if (_callbackAddr != address(this)) {
            s_requestIdTocallbackAddr[requestId] = _callbackAddr;
            IExternalFulfillment fulfillmentContract = IExternalFulfillment(_callbackAddr);
            // solhint-disable-next-line no-empty-blocks
            try fulfillmentContract.setChainlinkExternalRequest(address(this), requestId) {} catch {
                revert GenericConsumer__SetChainlinkExternalRequestFailed(_callbackAddr, requestId, _key);
            }
        }
        return requestId;
    }

    function _cleanLotData(uint256 _noEntries, uint256 _lot) private {
        if (_noEntries == 0) {
            s_lotToEntryMap.remove(_lot);
            delete s_lotToSha1[_lot];
        }
    }

    function _grantRoleTo(bytes32 _role, address[] memory _accounts) private {
        uint256 accountsLength = _accounts.length;
        for (uint256 i = 0; i < accountsLength; ) {
            _grantRole(_role, _accounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    function _removeEntry(
        EntryLibrary.Map storage _s_keyToEntry,
        uint256 _lot,
        bytes32 _key
    ) private {
        _requireEntryInserted(_lot, _key, _s_keyToEntry.isInserted(_key));
        _s_keyToEntry.remove(_key);
        emit EntryRemoved(_lot, _key);
    }

    function _requestData(
        bytes32 _specId,
        address _oracle,
        uint256 _payment,
        address _callbackAddr,
        bytes4 _callbackFunctionSignature,
        bytes memory _buffer,
        bool _isResponseForwarded,
        bool _isSenderPaying
    ) private returns (bytes32) {
        _requireSpecId(_specId);
        _requireOracle(_oracle);
        _requirePayment(_payment);
        if (_isResponseForwarded) {
            _requireCallbackAddr(_callbackAddr);
            _requireCallbackAddrIsNotGenericConsumer(_callbackAddr);
        }
        _requireCallbackFunctionSignature(_callbackFunctionSignature);
        if (_isSenderPaying) {
            _requireLinkAllowance(LINK.allowance(msg.sender, address(this)), _payment);
            _requireLinkBalance(LINK.balanceOf(msg.sender), _payment);
            _requireLinkTransferFrom(
                LINK.transferFrom(msg.sender, address(this), _payment),
                msg.sender,
                address(this),
                _payment
            );
        }
        return
            _buildAndSendOperatorRequest(
                _specId,
                _oracle,
                _payment,
                _callbackAddr,
                _callbackFunctionSignature,
                _buffer,
                NO_ENTRY_KEY
            );
    }

    function _setEntry(
        EntryLibrary.Map storage _s_keyToEntry,
        uint256 _lot,
        bytes32 _key,
        Entry calldata _entry
    ) private {
        _requireSpecId(_entry.specId);
        _requireOracle(_entry.oracle);
        _requirePayment(_entry.payment);
        _requireCallbackAddr(_entry.callbackAddr);
        _requireCallbackFunctionSignature(_entry.callbackFunctionSignature);
        _requireInterval(_entry.interval);
        _s_keyToEntry.set(_key, _entry);
        emit EntrySet(_lot, _key, _entry);
    }

    function _setLastRequestTimestamp(
        EntryLibrary.Map storage _s_keyToEntry,
        mapping(bytes32 => uint256) storage _s_keyToLastRequestTimestamp,
        uint256 _lot,
        bytes32 _key,
        uint256 _lastRequestTimestamp
    ) private {
        _requireEntryInserted(_lot, _key, _s_keyToEntry.isInserted(_key));
        _s_keyToLastRequestTimestamp[_key] = _lastRequestTimestamp;
        emit LastRequestTimestampSet(_lot, _key, _lastRequestTimestamp);
    }

    /* ========== PRIVATE VIEW FUNCTIONS ========== */

    function _availableFunds() private view returns (uint256) {
        return LINK.balanceOf(address(this));
    }

    function _requireCallbackAddr(address _callbackAddr) private view {
        if (!_callbackAddr.isContract()) {
            revert GenericConsumer__CallbackAddrIsNotAContract();
        }
    }

    function _requireCallbackAddrIsNotGenericConsumer(address _callbackAddr) private view {
        if (_callbackAddr == address(this)) {
            revert GenericConsumer__CallbackAddrIsGenericConsumer();
        }
    }

    function _requireOracle(address _oracle) private view {
        if (!_oracle.isContract()) {
            revert GenericConsumer__OracleIsNotAContract();
        }
    }

    /* ========== PRIVATE PURE FUNCTIONS ========== */

    function _isScheduled(
        uint128 _startAt,
        uint128 _interval,
        uint256 _lastRequestTimestamp,
        uint256 _blockTimestamp
    ) private pure returns (bool) {
        return (_startAt <= _blockTimestamp && (_blockTimestamp - _lastRequestTimestamp) >= _interval);
    }

    function _requireCallbackFunctionSignature(bytes4 _callbackFunctionSignature) private pure {
        if (_callbackFunctionSignature == bytes4(0)) {
            revert GenericConsumer__CallbackFunctionSignatureIsZero();
        }
    }

    function _requireEntryActive(
        uint256 _lot,
        bytes32 _key,
        bool _inactive
    ) private pure {
        if (_inactive) {
            revert GenericConsumer__EntryIsInactive(_lot, _key);
        }
    }

    function _requireEntryInserted(
        uint256 _lot,
        bytes32 _key,
        bool _isInserted
    ) private pure {
        if (!_isInserted) {
            revert GenericConsumer__EntryIsNotInserted(_lot, _key);
        }
    }

    function _requireEntryMapKeys(uint256 _length) private pure {
        if (_length == 0) {
            revert GenericConsumer__EntryMapKeysAreEmpty();
        }
    }

    function _requireEntryScheduled(
        uint256 _lot,
        bytes32 _key,
        uint128 _startAt,
        uint128 _interval,
        uint256 _lastRequestTimestamp,
        uint256 _blockTimestamp
    ) private pure {
        if (!_isScheduled(_startAt, _interval, _lastRequestTimestamp, _blockTimestamp)) {
            revert GenericConsumer__EntryIsNotScheduled(
                _lot,
                _key,
                _startAt,
                _interval,
                _lastRequestTimestamp,
                _blockTimestamp
            );
        }
    }

    function _requireEqualLength(uint256 _length1, uint256 _length2) private pure {
        if (_length1 != _length2) {
            revert GenericConsumer__LengthIsNotEqual();
        }
    }

    function _requireFallbackMsgData(bytes calldata _data) private pure {
        if (_data.length < MIN_FALLBACK_MSG_DATA_LENGTH) {
            revert GenericConsumer__FallbackMsgDataIsInvalid();
        }
    }

    function _requireInterval(uint256 _interval) private pure {
        if (_interval == 0) {
            revert GenericConsumer__IntervalIsZero();
        }
    }

    function _requireLinkAllowance(uint256 _allowance, uint256 _payment) private pure {
        if (_allowance < _payment) {
            revert GenericConsumer__LinkAllowanceIsInsufficient(_allowance, _payment);
        }
    }

    function _requireLinkBalance(uint256 _balance, uint256 _payment) private pure {
        if (_balance < _payment) {
            revert GenericConsumer__LinkBalanceIsInsufficient(_balance, _payment);
        }
    }

    function _requireLinkTransfer(
        bool _success,
        address _to,
        uint256 _amount
    ) private pure {
        if (!_success) {
            revert GenericConsumer__LinkTransferFailed(_to, _amount);
        }
    }

    function _requireLinkTransferFrom(
        bool _success,
        address _from,
        address _to,
        uint256 _payment
    ) private pure {
        if (!_success) {
            revert GenericConsumer__LinkTransferFromFailed(_from, _to, _payment);
        }
    }

    function _requireLotInserted(uint256 _lot, bool _isInserted) private pure {
        if (!_isInserted) {
            revert GenericConsumer__LotIsNotInserted(_lot);
        }
    }

    function _requireLotNotEmpty(uint256 _lot, uint256 _size) private pure {
        if (_size == 0) {
            revert GenericConsumer__LotIsEmpty(_lot);
        }
    }

    function _requirePayment(uint256 _payment) private pure {
        if (_payment == 0) {
            revert GenericConsumer__PaymentIsZero();
        }
    }

    function _requireSpecId(bytes32 _specId) private pure {
        if (_specId == bytes32(0)) {
            revert GenericConsumer__SpecIdIsZero();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Chainlink.sol";
import "./interfaces/ENSInterface.sol";
import "./interfaces/LinkTokenInterface.sol";
import "./interfaces/ChainlinkRequestInterface.sol";
import "./interfaces/OperatorInterface.sol";
import "./interfaces/PointerInterface.sol";
import {ENSResolver as ENSResolver_Chainlink} from "./vendor/ENSResolver.sol";

/**
 * @title The ChainlinkClient contract
 * @notice Contract writers can inherit this contract in order to create requests for the
 * Chainlink network
 */
abstract contract ChainlinkClient {
  using Chainlink for Chainlink.Request;

  uint256 internal constant LINK_DIVISIBILITY = 10**18;
  uint256 private constant AMOUNT_OVERRIDE = 0;
  address private constant SENDER_OVERRIDE = address(0);
  uint256 private constant ORACLE_ARGS_VERSION = 1;
  uint256 private constant OPERATOR_ARGS_VERSION = 2;
  bytes32 private constant ENS_TOKEN_SUBNAME = keccak256("link");
  bytes32 private constant ENS_ORACLE_SUBNAME = keccak256("oracle");
  address private constant LINK_TOKEN_POINTER = 0xC89bD4E1632D3A43CB03AAAd5262cbe4038Bc571;

  ENSInterface private s_ens;
  bytes32 private s_ensNode;
  LinkTokenInterface private s_link;
  OperatorInterface private s_oracle;
  uint256 private s_requestCount = 1;
  mapping(bytes32 => address) private s_pendingRequests;

  event ChainlinkRequested(bytes32 indexed id);
  event ChainlinkFulfilled(bytes32 indexed id);
  event ChainlinkCancelled(bytes32 indexed id);

  /**
   * @notice Creates a request that can hold additional parameters
   * @param specId The Job Specification ID that the request will be created for
   * @param callbackAddr address to operate the callback on
   * @param callbackFunctionSignature function signature to use for the callback
   * @return A Chainlink Request struct in memory
   */
  function buildChainlinkRequest(
    bytes32 specId,
    address callbackAddr,
    bytes4 callbackFunctionSignature
  ) internal pure returns (Chainlink.Request memory) {
    Chainlink.Request memory req;
    return req.initialize(specId, callbackAddr, callbackFunctionSignature);
  }

  /**
   * @notice Creates a request that can hold additional parameters
   * @param specId The Job Specification ID that the request will be created for
   * @param callbackFunctionSignature function signature to use for the callback
   * @return A Chainlink Request struct in memory
   */
  function buildOperatorRequest(bytes32 specId, bytes4 callbackFunctionSignature)
    internal
    view
    returns (Chainlink.Request memory)
  {
    Chainlink.Request memory req;
    return req.initialize(specId, address(this), callbackFunctionSignature);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev Calls `chainlinkRequestTo` with the stored oracle address
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequest(Chainlink.Request memory req, uint256 payment) internal returns (bytes32) {
    return sendChainlinkRequestTo(address(s_oracle), req, payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequestTo(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment
  ) internal returns (bytes32 requestId) {
    uint256 nonce = s_requestCount;
    s_requestCount = nonce + 1;
    bytes memory encodedRequest = abi.encodeWithSelector(
      ChainlinkRequestInterface.oracleRequest.selector,
      SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
      AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
      req.id,
      req.callbackAddress, // address(this),
      req.callbackFunctionId,
      nonce,
      ORACLE_ARGS_VERSION,
      req.buf.buf
    );
    return _rawRequest(oracleAddress, nonce, payment, encodedRequest);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev This function supports multi-word response
   * @dev Calls `sendOperatorRequestTo` with the stored oracle address
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendOperatorRequest(Chainlink.Request memory req, uint256 payment) internal returns (bytes32) {
    return sendOperatorRequestTo(address(s_oracle), req, payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev This function supports multi-word response
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendOperatorRequestTo(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment
  ) internal returns (bytes32 requestId) {
    uint256 nonce = s_requestCount;
    s_requestCount = nonce + 1;
    bytes memory encodedRequest = abi.encodeWithSelector(
      OperatorInterface.operatorRequest.selector,
      SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
      AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
      req.id,
      req.callbackFunctionId,
      nonce,
      OPERATOR_ARGS_VERSION,
      req.buf.buf
    );
    return _rawRequest(oracleAddress, nonce, payment, encodedRequest);
  }

  /**
   * @notice Make a request to an oracle
   * @param oracleAddress The address of the oracle for the request
   * @param nonce used to generate the request ID
   * @param payment The amount of LINK to send for the request
   * @param encodedRequest data encoded for request type specific format
   * @return requestId The request ID
   */
  function _rawRequest(
    address oracleAddress,
    uint256 nonce,
    uint256 payment,
    bytes memory encodedRequest
  ) private returns (bytes32 requestId) {
    requestId = keccak256(abi.encodePacked(this, nonce));
    s_pendingRequests[requestId] = oracleAddress;
    emit ChainlinkRequested(requestId);
    require(s_link.transferAndCall(oracleAddress, payment, encodedRequest), "unable to transferAndCall to oracle");
  }

  /**
   * @notice Allows a request to be cancelled if it has not been fulfilled
   * @dev Requires keeping track of the expiration value emitted from the oracle contract.
   * Deletes the request from the `pendingRequests` mapping.
   * Emits ChainlinkCancelled event.
   * @param requestId The request ID
   * @param payment The amount of LINK sent for the request
   * @param callbackFunc The callback function specified for the request
   * @param expiration The time of the expiration for the request
   */
  function cancelChainlinkRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunc,
    uint256 expiration
  ) internal {
    OperatorInterface requested = OperatorInterface(s_pendingRequests[requestId]);
    delete s_pendingRequests[requestId];
    emit ChainlinkCancelled(requestId);
    requested.cancelOracleRequest(requestId, payment, callbackFunc, expiration);
  }

  /**
   * @notice the next request count to be used in generating a nonce
   * @dev starts at 1 in order to ensure consistent gas cost
   * @return returns the next request count to be used in a nonce
   */
  function getNextRequestCount() internal view returns (uint256) {
    return s_requestCount;
  }

  /**
   * @notice Sets the stored oracle address
   * @param oracleAddress The address of the oracle contract
   */
  function setChainlinkOracle(address oracleAddress) internal {
    s_oracle = OperatorInterface(oracleAddress);
  }

  /**
   * @notice Sets the LINK token address
   * @param linkAddress The address of the LINK token contract
   */
  function setChainlinkToken(address linkAddress) internal {
    s_link = LinkTokenInterface(linkAddress);
  }

  /**
   * @notice Sets the Chainlink token address for the public
   * network as given by the Pointer contract
   */
  function setPublicChainlinkToken() internal {
    setChainlinkToken(PointerInterface(LINK_TOKEN_POINTER).getAddress());
  }

  /**
   * @notice Retrieves the stored address of the LINK token
   * @return The address of the LINK token
   */
  function chainlinkTokenAddress() internal view returns (address) {
    return address(s_link);
  }

  /**
   * @notice Retrieves the stored address of the oracle contract
   * @return The address of the oracle contract
   */
  function chainlinkOracleAddress() internal view returns (address) {
    return address(s_oracle);
  }

  /**
   * @notice Allows for a request which was created on another contract to be fulfilled
   * on this contract
   * @param oracleAddress The address of the oracle contract that will fulfill the request
   * @param requestId The request ID used for the response
   */
  function addChainlinkExternalRequest(address oracleAddress, bytes32 requestId) internal notPendingRequest(requestId) {
    s_pendingRequests[requestId] = oracleAddress;
  }

  /**
   * @notice Sets the stored oracle and LINK token contracts with the addresses resolved by ENS
   * @dev Accounts for subnodes having different resolvers
   * @param ensAddress The address of the ENS contract
   * @param node The ENS node hash
   */
  function useChainlinkWithENS(address ensAddress, bytes32 node) internal {
    s_ens = ENSInterface(ensAddress);
    s_ensNode = node;
    bytes32 linkSubnode = keccak256(abi.encodePacked(s_ensNode, ENS_TOKEN_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(s_ens.resolver(linkSubnode));
    setChainlinkToken(resolver.addr(linkSubnode));
    updateChainlinkOracleWithENS();
  }

  /**
   * @notice Sets the stored oracle contract with the address resolved by ENS
   * @dev This may be called on its own as long as `useChainlinkWithENS` has been called previously
   */
  function updateChainlinkOracleWithENS() internal {
    bytes32 oracleSubnode = keccak256(abi.encodePacked(s_ensNode, ENS_ORACLE_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(s_ens.resolver(oracleSubnode));
    setChainlinkOracle(resolver.addr(oracleSubnode));
  }

  /**
   * @notice Ensures that the fulfillment is valid for this contract
   * @dev Use if the contract developer prefers methods instead of modifiers for validation
   * @param requestId The request ID for fulfillment
   */
  function validateChainlinkCallback(bytes32 requestId)
    internal
    recordChainlinkFulfillment(requestId)
  // solhint-disable-next-line no-empty-blocks
  {

  }

  /**
   * @dev Reverts if the sender is not the oracle of the request.
   * Emits ChainlinkFulfilled event.
   * @param requestId The request ID for fulfillment
   */
  modifier recordChainlinkFulfillment(bytes32 requestId) {
    require(msg.sender == s_pendingRequests[requestId], "Source must be the oracle of the request");
    delete s_pendingRequests[requestId];
    emit ChainlinkFulfilled(requestId);
    _;
  }

  /**
   * @dev Reverts if the request is already pending
   * @param requestId The request ID for fulfillment
   */
  modifier notPendingRequest(bytes32 requestId) {
    require(s_pendingRequests[requestId] == address(0), "Request is already pending");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract TypeAndVersionInterface {
  function typeAndVersion() external pure virtual returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./KeeperBase.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
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
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
pragma solidity 0.8.13;

interface IExternalFulfillment {
    function cancelChainlinkExternalRequest(
        bytes32 _requestId,
        uint256 _payment,
        bytes4 _callbackFunc,
        uint256 _expiration
    ) external;

    function setChainlinkExternalRequest(address _from, bytes32 _requestId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

struct Entry {
    bytes32 specId;
    address oracle;
    uint256 payment;
    address callbackAddr;
    uint128 startAt;
    uint128 interval;
    bool inactive;
    bytes4 callbackFunctionSignature;
    bytes buffer;
}

error EntryLibrary__EntryIsNotInserted(bytes32 key);

library EntryLibrary {
    struct Map {
        bytes32[] keys;
        mapping(bytes32 => Entry) keyToEntry;
        mapping(bytes32 => uint256) indexOf;
        mapping(bytes32 => bool) inserted;
    }

    function getEntry(Map storage _map, bytes32 _key) internal view returns (Entry memory) {
        return _map.keyToEntry[_key];
    }

    function getKeyAtIndex(Map storage _map, uint256 _index) internal view returns (bytes32) {
        return _map.keys[_index];
    }

    function isInserted(Map storage _map, bytes32 _key) internal view returns (bool) {
        return _map.inserted[_key];
    }

    function size(Map storage _map) internal view returns (uint256) {
        return _map.keys.length;
    }

    function remove(Map storage _map, bytes32 _key) internal {
        if (!_map.inserted[_key]) {
            revert EntryLibrary__EntryIsNotInserted(_key);
        }

        delete _map.inserted[_key];
        delete _map.keyToEntry[_key];

        uint256 index = _map.indexOf[_key];
        uint256 lastIndex = _map.keys.length - 1;
        bytes32 lastKey = _map.keys[lastIndex];

        _map.indexOf[lastKey] = index;
        delete _map.indexOf[_key];

        _map.keys[index] = lastKey;
        _map.keys.pop();
    }

    function removeAll(Map storage _map) internal {
        uint256 mapSize = size(_map);
        for (uint256 i = 0; i < mapSize; ) {
            bytes32 key = getKeyAtIndex(_map, 0);
            remove(_map, key);
            unchecked {
                ++i;
            }
        }
    }

    function set(
        Map storage _map,
        bytes32 _key,
        Entry calldata _entry
    ) internal {
        if (!_map.inserted[_key]) {
            _map.inserted[_key] = true;
            _map.indexOf[_key] = _map.keys.length;
            _map.keys.push(_key);
        }
        _map.keyToEntry[_key] = _entry;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import { Entry, EntryLibrary } from "./EntryLibrary.sol";

error LotLibrary__LotIsNotInserted(uint256 lot);
error LotLibrary__LotIsNotEmpty(uint256 lot);

library LotLibrary {
    using EntryLibrary for EntryLibrary.Map;

    struct Map {
        uint256[] lots;
        mapping(uint256 => EntryLibrary.Map) lotToEntryMap;
        mapping(uint256 => uint256) indexOf;
        mapping(uint256 => bool) inserted;
    }

    function getLot(Map storage _map, uint256 _lot) internal view returns (EntryLibrary.Map storage) {
        return _map.lotToEntryMap[_lot];
    }

    function isInserted(Map storage _map, uint256 _lot) internal view returns (bool) {
        return _map.inserted[_lot];
    }

    function size(Map storage _map) internal view returns (uint256) {
        return _map.lots.length;
    }

    function remove(Map storage _map, uint256 _lot) internal {
        if (!_map.inserted[_lot]) {
            revert LotLibrary__LotIsNotInserted(_lot);
        }

        if (_map.lotToEntryMap[_lot].size() != 0) {
            revert LotLibrary__LotIsNotEmpty(_lot);
        }
        delete _map.inserted[_lot];

        uint256 index = _map.indexOf[_lot];
        uint256 lastIndex = _map.lots.length - 1;
        uint256 lastKey = _map.lots[lastIndex];

        _map.indexOf[lastKey] = index;
        delete _map.indexOf[_lot];

        _map.lots[index] = lastKey;
        _map.lots.pop();
    }

    function set(Map storage _map, uint256 _lot) internal {
        if (!_map.inserted[_lot]) {
            _map.inserted[_lot] = true;
            _map.indexOf[_lot] = _map.lots.length;
            _map.lots.push(_lot);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CBORChainlink} from "./vendor/CBORChainlink.sol";
import {BufferChainlink} from "./vendor/BufferChainlink.sol";

/**
 * @title Library for common Chainlink functions
 * @dev Uses imported CBOR library for encoding to buffer
 */
library Chainlink {
  uint256 internal constant defaultBufferSize = 256; // solhint-disable-line const-name-snakecase

  using CBORChainlink for BufferChainlink.buffer;

  struct Request {
    bytes32 id;
    address callbackAddress;
    bytes4 callbackFunctionId;
    uint256 nonce;
    BufferChainlink.buffer buf;
  }

  /**
   * @notice Initializes a Chainlink request
   * @dev Sets the ID, callback address, and callback function signature on the request
   * @param self The uninitialized request
   * @param jobId The Job Specification ID
   * @param callbackAddr The callback address
   * @param callbackFunc The callback function signature
   * @return The initialized request
   */
  function initialize(
    Request memory self,
    bytes32 jobId,
    address callbackAddr,
    bytes4 callbackFunc
  ) internal pure returns (Chainlink.Request memory) {
    BufferChainlink.init(self.buf, defaultBufferSize);
    self.id = jobId;
    self.callbackAddress = callbackAddr;
    self.callbackFunctionId = callbackFunc;
    return self;
  }

  /**
   * @notice Sets the data for the buffer without encoding CBOR on-chain
   * @dev CBOR can be closed with curly-brackets {} or they can be left off
   * @param self The initialized request
   * @param data The CBOR data
   */
  function setBuffer(Request memory self, bytes memory data) internal pure {
    BufferChainlink.init(self.buf, data.length);
    BufferChainlink.append(self.buf, data);
  }

  /**
   * @notice Adds a string value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The string value to add
   */
  function add(
    Request memory self,
    string memory key,
    string memory value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeString(value);
  }

  /**
   * @notice Adds a bytes value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The bytes value to add
   */
  function addBytes(
    Request memory self,
    string memory key,
    bytes memory value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeBytes(value);
  }

  /**
   * @notice Adds a int256 value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The int256 value to add
   */
  function addInt(
    Request memory self,
    string memory key,
    int256 value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeInt(value);
  }

  /**
   * @notice Adds a uint256 value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The uint256 value to add
   */
  function addUint(
    Request memory self,
    string memory key,
    uint256 value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeUInt(value);
  }

  /**
   * @notice Adds an array of strings to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param values The array of string values to add
   */
  function addStringArray(
    Request memory self,
    string memory key,
    string[] memory values
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.startArray();
    for (uint256 i = 0; i < values.length; i++) {
      self.buf.encodeString(values[i]);
    }
    self.buf.endSequence();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ENSInterface {
  // Logged when the owner of a node assigns a new owner to a subnode.
  event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

  // Logged when the owner of a node transfers ownership to a new account.
  event Transfer(bytes32 indexed node, address owner);

  // Logged when the resolver for a node changes.
  event NewResolver(bytes32 indexed node, address resolver);

  // Logged when the TTL of a node changes
  event NewTTL(bytes32 indexed node, uint64 ttl);

  function setSubnodeOwner(
    bytes32 node,
    bytes32 label,
    address owner
  ) external;

  function setResolver(bytes32 node, address resolver) external;

  function setOwner(bytes32 node, address owner) external;

  function setTTL(bytes32 node, uint64 ttl) external;

  function owner(bytes32 node) external view returns (address);

  function resolver(bytes32 node) external view returns (address);

  function ttl(bytes32 node) external view returns (uint64);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ChainlinkRequestInterface {
  function oracleRequest(
    address sender,
    uint256 requestPrice,
    bytes32 serviceAgreementID,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  ) external;

  function cancelOracleRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunctionId,
    uint256 expiration
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OracleInterface.sol";
import "./ChainlinkRequestInterface.sol";

interface OperatorInterface is OracleInterface, ChainlinkRequestInterface {
  function operatorRequest(
    address sender,
    uint256 payment,
    bytes32 specId,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  ) external;

  function fulfillOracleRequest2(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes calldata data
  ) external returns (bool);

  function ownerTransferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function distributeFunds(address payable[] calldata receivers, uint256[] calldata amounts) external payable;

  function getAuthorizedSenders() external returns (address[] memory);

  function setAuthorizedSenders(address[] calldata senders) external;

  function getForwarder() external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface PointerInterface {
  function getAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ENSResolver {
  function addr(bytes32 node) public view virtual returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.19;

import {BufferChainlink} from "./BufferChainlink.sol";

library CBORChainlink {
  using BufferChainlink for BufferChainlink.buffer;

  uint8 private constant MAJOR_TYPE_INT = 0;
  uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
  uint8 private constant MAJOR_TYPE_BYTES = 2;
  uint8 private constant MAJOR_TYPE_STRING = 3;
  uint8 private constant MAJOR_TYPE_ARRAY = 4;
  uint8 private constant MAJOR_TYPE_MAP = 5;
  uint8 private constant MAJOR_TYPE_TAG = 6;
  uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

  uint8 private constant TAG_TYPE_BIGNUM = 2;
  uint8 private constant TAG_TYPE_NEGATIVE_BIGNUM = 3;

  function encodeFixedNumeric(BufferChainlink.buffer memory buf, uint8 major, uint64 value) private pure {
    if(value <= 23) {
      buf.appendUint8(uint8((major << 5) | value));
    } else if (value <= 0xFF) {
      buf.appendUint8(uint8((major << 5) | 24));
      buf.appendInt(value, 1);
    } else if (value <= 0xFFFF) {
      buf.appendUint8(uint8((major << 5) | 25));
      buf.appendInt(value, 2);
    } else if (value <= 0xFFFFFFFF) {
      buf.appendUint8(uint8((major << 5) | 26));
      buf.appendInt(value, 4);
    } else {
      buf.appendUint8(uint8((major << 5) | 27));
      buf.appendInt(value, 8);
    }
  }

  function encodeIndefiniteLengthType(BufferChainlink.buffer memory buf, uint8 major) private pure {
    buf.appendUint8(uint8((major << 5) | 31));
  }

  function encodeUInt(BufferChainlink.buffer memory buf, uint value) internal pure {
    if(value > 0xFFFFFFFFFFFFFFFF) {
      encodeBigNum(buf, value);
    } else {
      encodeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(value));
    }
  }

  function encodeInt(BufferChainlink.buffer memory buf, int value) internal pure {
    if(value < -0x10000000000000000) {
      encodeSignedBigNum(buf, value);
    } else if(value > 0xFFFFFFFFFFFFFFFF) {
      encodeBigNum(buf, uint(value));
    } else if(value >= 0) {
      encodeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(uint256(value)));
    } else {
      encodeFixedNumeric(buf, MAJOR_TYPE_NEGATIVE_INT, uint64(uint256(-1 - value)));
    }
  }

  function encodeBytes(BufferChainlink.buffer memory buf, bytes memory value) internal pure {
    encodeFixedNumeric(buf, MAJOR_TYPE_BYTES, uint64(value.length));
    buf.append(value);
  }

  function encodeBigNum(BufferChainlink.buffer memory buf, uint value) internal pure {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_BIGNUM));
    encodeBytes(buf, abi.encode(value));
  }

  function encodeSignedBigNum(BufferChainlink.buffer memory buf, int input) internal pure {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_NEGATIVE_BIGNUM));
    encodeBytes(buf, abi.encode(uint256(-1 - input)));
  }

  function encodeString(BufferChainlink.buffer memory buf, string memory value) internal pure {
    encodeFixedNumeric(buf, MAJOR_TYPE_STRING, uint64(bytes(value).length));
    buf.append(bytes(value));
  }

  function startArray(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_ARRAY);
  }

  function startMap(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_MAP);
  }

  function endSequence(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_CONTENT_FREE);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev A library for working with mutable byte buffers in Solidity.
 *
 * Byte buffers are mutable and expandable, and provide a variety of primitives
 * for writing to them. At any time you can fetch a bytes object containing the
 * current contents of the buffer. The bytes object should not be stored between
 * operations, as it may change due to resizing of the buffer.
 */
library BufferChainlink {
  /**
   * @dev Represents a mutable buffer. Buffers have a current value (buf) and
   *      a capacity. The capacity may be longer than the current value, in
   *      which case it can be extended without the need to allocate more memory.
   */
  struct buffer {
    bytes buf;
    uint256 capacity;
  }

  /**
   * @dev Initializes a buffer with an initial capacity.
   * @param buf The buffer to initialize.
   * @param capacity The number of bytes of space to allocate the buffer.
   * @return The buffer, for chaining.
   */
  function init(buffer memory buf, uint256 capacity) internal pure returns (buffer memory) {
    if (capacity % 32 != 0) {
      capacity += 32 - (capacity % 32);
    }
    // Allocate space for the buffer data
    buf.capacity = capacity;
    assembly {
      let ptr := mload(0x40)
      mstore(buf, ptr)
      mstore(ptr, 0)
      mstore(0x40, add(32, add(ptr, capacity)))
    }
    return buf;
  }

  /**
   * @dev Initializes a new buffer from an existing bytes object.
   *      Changes to the buffer may mutate the original value.
   * @param b The bytes object to initialize the buffer with.
   * @return A new buffer.
   */
  function fromBytes(bytes memory b) internal pure returns (buffer memory) {
    buffer memory buf;
    buf.buf = b;
    buf.capacity = b.length;
    return buf;
  }

  function resize(buffer memory buf, uint256 capacity) private pure {
    bytes memory oldbuf = buf.buf;
    init(buf, capacity);
    append(buf, oldbuf);
  }

  function max(uint256 a, uint256 b) private pure returns (uint256) {
    if (a > b) {
      return a;
    }
    return b;
  }

  /**
   * @dev Sets buffer length to 0.
   * @param buf The buffer to truncate.
   * @return The original buffer, for chaining..
   */
  function truncate(buffer memory buf) internal pure returns (buffer memory) {
    assembly {
      let bufptr := mload(buf)
      mstore(bufptr, 0)
    }
    return buf;
  }

  /**
   * @dev Writes a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The start offset to write to.
   * @param data The data to append.
   * @param len The number of bytes to copy.
   * @return The original buffer, for chaining.
   */
  function write(
    buffer memory buf,
    uint256 off,
    bytes memory data,
    uint256 len
  ) internal pure returns (buffer memory) {
    require(len <= data.length);

    if (off + len > buf.capacity) {
      resize(buf, max(buf.capacity, len + off) * 2);
    }

    uint256 dest;
    uint256 src;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Start address = buffer address + offset + sizeof(buffer length)
      dest := add(add(bufptr, 32), off)
      // Update buffer length if we're extending it
      if gt(add(len, off), buflen) {
        mstore(bufptr, add(len, off))
      }
      src := add(data, 32)
    }

    // Copy word-length chunks while possible
    for (; len >= 32; len -= 32) {
      assembly {
        mstore(dest, mload(src))
      }
      dest += 32;
      src += 32;
    }

    // Copy remaining bytes
    unchecked {
      uint256 mask = (256**(32 - len)) - 1;
      assembly {
        let srcpart := and(mload(src), not(mask))
        let destpart := and(mload(dest), mask)
        mstore(dest, or(destpart, srcpart))
      }
    }

    return buf;
  }

  /**
   * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @param len The number of bytes to copy.
   * @return The original buffer, for chaining.
   */
  function append(
    buffer memory buf,
    bytes memory data,
    uint256 len
  ) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, len);
  }

  /**
   * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function append(buffer memory buf, bytes memory data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, data.length);
  }

  /**
   * @dev Writes a byte to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write the byte at.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function writeUint8(
    buffer memory buf,
    uint256 off,
    uint8 data
  ) internal pure returns (buffer memory) {
    if (off >= buf.capacity) {
      resize(buf, buf.capacity * 2);
    }

    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Address = buffer address + sizeof(buffer length) + off
      let dest := add(add(bufptr, off), 32)
      mstore8(dest, data)
      // Update buffer length if we extended it
      if eq(off, buflen) {
        mstore(bufptr, add(buflen, 1))
      }
    }
    return buf;
  }

  /**
   * @dev Appends a byte to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function appendUint8(buffer memory buf, uint8 data) internal pure returns (buffer memory) {
    return writeUint8(buf, buf.buf.length, data);
  }

  /**
   * @dev Writes up to 32 bytes to the buffer. Resizes if doing so would
   *      exceed the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @param len The number of bytes to write (left-aligned).
   * @return The original buffer, for chaining.
   */
  function write(
    buffer memory buf,
    uint256 off,
    bytes32 data,
    uint256 len
  ) private pure returns (buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    unchecked {
      uint256 mask = (256**len) - 1;
      // Right-align data
      data = data >> (8 * (32 - len));
      assembly {
        // Memory address of the buffer data
        let bufptr := mload(buf)
        // Address = buffer address + sizeof(buffer length) + off + len
        let dest := add(add(bufptr, off), len)
        mstore(dest, or(and(mload(dest), not(mask)), data))
        // Update buffer length if we extended it
        if gt(add(off, len), mload(bufptr)) {
          mstore(bufptr, add(off, len))
        }
      }
    }
    return buf;
  }

  /**
   * @dev Writes a bytes20 to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function writeBytes20(
    buffer memory buf,
    uint256 off,
    bytes20 data
  ) internal pure returns (buffer memory) {
    return write(buf, off, bytes32(data), 20);
  }

  /**
   * @dev Appends a bytes20 to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chhaining.
   */
  function appendBytes20(buffer memory buf, bytes20 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, bytes32(data), 20);
  }

  /**
   * @dev Appends a bytes32 to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function appendBytes32(buffer memory buf, bytes32 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, 32);
  }

  /**
   * @dev Writes an integer to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @param len The number of bytes to write (right-aligned).
   * @return The original buffer, for chaining.
   */
  function writeInt(
    buffer memory buf,
    uint256 off,
    uint256 data,
    uint256 len
  ) private pure returns (buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    uint256 mask = (256**len) - 1;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Address = buffer address + off + sizeof(buffer length) + len
      let dest := add(add(bufptr, off), len)
      mstore(dest, or(and(mload(dest), not(mask)), data))
      // Update buffer length if we extended it
      if gt(add(off, len), mload(bufptr)) {
        mstore(bufptr, add(off, len))
      }
    }
    return buf;
  }

  /**
   * @dev Appends a byte to the end of the buffer. Resizes if doing so would
   * exceed the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer.
   */
  function appendInt(
    buffer memory buf,
    uint256 data,
    uint256 len
  ) internal pure returns (buffer memory) {
    return writeInt(buf, buf.buf.length, data, len);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OracleInterface {
  function fulfillOracleRequest(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes32 data
  ) external returns (bool);

  function isAuthorizedSender(address node) external view returns (bool);

  function withdraw(address recipient, uint256 amount) external;

  function withdrawable() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
interface IERC165 {
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