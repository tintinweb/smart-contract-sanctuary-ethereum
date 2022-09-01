// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Chainlink } from "@chainlink/contracts/src/v0.8/Chainlink.sol";
import { ConfirmedOwner } from "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import { LinkTokenInterface } from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
// solhint-disable-next-line max-line-length
import { ChainlinkRequestInterface, OperatorInterface } from "@chainlink/contracts/src/v0.8/interfaces/OperatorInterface.sol";
import { TypeAndVersionInterface } from "@chainlink/contracts/src/v0.8/interfaces/TypeAndVersionInterface.sol";
import { KeeperBase } from "@chainlink/contracts/src/v0.8/KeeperBase.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IChainlinkExternalFulfillment } from "./interfaces/IChainlinkExternalFulfillment.sol";
import { IGenericConsumer } from "./interfaces/IGenericConsumer.sol";
import { Entry, EntryLibrary, RequestType } from "./libraries/internal/EntryLibrary.sol";
import { LotLibrary } from "./libraries/internal/LotLibrary.sol";

contract GenericConsumer is ConfirmedOwner, Pausable, KeeperBase, TypeAndVersionInterface, IGenericConsumer {
    using Address for address;
    using Chainlink for Chainlink.Request;
    using EntryLibrary for EntryLibrary.Map;
    using LotLibrary for LotLibrary.Map;

    // ChainlinkClient storage
    uint256 private constant ORACLE_ARGS_VERSION = 1; // 32 bytes
    uint256 private constant OPERATOR_ARGS_VERSION = 2; // 32 bytes
    uint256 private constant AMOUNT_OVERRIDE = 0; // 32 bytes
    address private constant SENDER_OVERRIDE = address(0); // 20 bytes
    // GenericConsumer storage
    uint8 private constant MIN_FALLBACK_MSG_DATA_LENGTH = 36; // 1 byte
    bytes4 private constant NO_CALLBACK_FUNCTION_SIGNATURE = bytes4(0); // 4 bytes
    uint96 private constant LINK_TOTAL_SUPPLY = 1e27; // 12 bytes
    address private constant NO_CALLBACK_ADDR = address(0); // 20 bytes
    bytes32 private constant NO_SPEC_ID = bytes32(0); // 32 bytes
    bytes32 private constant NO_ENTRY_KEY = bytes32(0); // 32 bytes
    LinkTokenInterface public immutable LINK; // 20 bytes
    uint96 private s_minGasLimitPerformUpkeep; // 12 bytes
    uint256 private s_requestCount = 1; // 32 bytes
    uint256 private s_latestRoundId; // 32 bytes
    string private s_description; // 64 bytes
    mapping(bytes32 => address) private s_pendingRequests; /* requestId */ /* oracle */
    mapping(address => uint96) private s_consumerToLinkBalance; /* mgs.sender */ /* LINK */
    mapping(uint256 => bool) private s_lotToIsUpkeepAllowed; /* lot */ /* bool */
    // solhint-disable-next-line max-line-length
    mapping(uint256 => mapping(bytes32 => uint256)) private s_lotToLastRequestTimestampMap; /* lot */ /* key */ /* lastRequestTimestamp */
    mapping(bytes32 => address) private s_requestIdToCallbackAddr; /* requestId */ /* callbackAddr */
    LotLibrary.Map private s_lotToEntryMap; /* lot */ /* key */ /* Entry */

    error GenericConsumer__ArrayIsEmpty(string arrayName);
    error GenericConsumer__ArrayLengthsAreNotEqual(
        string array1Name,
        uint256 array1Length,
        string array2Name,
        uint256 array2Length
    );
    error GenericConsumer__CallbackAddrIsGenericConsumer(address callbackAddr);
    error GenericConsumer__CallbackAddrIsNotContract(address callbackAddr);
    error GenericConsumer__CallbackFunctionSignatureIsZero();
    error GenericConsumer__ConsumerAddrIsOwner(address consumer);
    error GenericConsumer__EntryFieldCallbackFunctionSignatureIsZero(uint256 lot, bytes32 key);
    error GenericConsumer__EntryFieldCallbackAddrIsNotContract(uint256 lot, bytes32 key, address callbackAddr);
    error GenericConsumer__EntryFieldIntervalIsZero(uint256 lot, bytes32 key);
    error GenericConsumer__EntryFieldOracleIsGenericConsumer(uint256 lot, bytes32 key, address oracle);
    error GenericConsumer__EntryFieldOracleIsNotContract(uint256 lot, bytes32 key, address oracle);
    error GenericConsumer__EntryFieldPaymentIsGtLinkTotalSupply(uint256 lot, bytes32 key, uint96 payment);
    error GenericConsumer__EntryFieldSpecIdIsZero(uint256 lot, bytes32 key);
    error GenericConsumer__EntryIsInactive(uint256 lot, bytes32 key);
    error GenericConsumer__EntryIsNotInserted(uint256 lot, bytes32 key);
    error GenericConsumer__EntryIsNotScheduled(
        uint256 lot,
        bytes32 key,
        uint96 startAt,
        uint96 interval,
        uint256 lastRequestTimestamp,
        uint256 blockTimestamp
    );
    error GenericConsumer__FallbackMsgDataIsInvalid(bytes data);
    error GenericConsumer__LinkAllowanceIsInsufficient(address payer, uint96 allowance, uint96 amount);
    error GenericConsumer__LinkBalanceIsInsufficient(address payer, uint96 balance, uint96 amount);
    error GenericConsumer__LinkPaymentIsGtLinkTotalSupply(uint96 payment);
    error GenericConsumer__LinkTransferAndCallFailed(address to, uint96 amount, bytes encodedRequest);
    error GenericConsumer__LinkTransferFailed(address to, uint256 amount);
    error GenericConsumer__LinkTransferFromFailed(address from, address to, uint96 payment);
    error GenericConsumer__LotIsEmpty(uint256 lot);
    error GenericConsumer__LotIsNotInserted(uint256 lot);
    error GenericConsumer__LotIsNotUpkeepAllowed(uint256 lot);
    error GenericConsumer__OracleIsNotContract(address oracle);
    error GenericConsumer__CallerIsNotRequestOracle(address oracle);
    error GenericConsumer__RequestIsNotPending();
    error GenericConsumer__RequestTypeIsUnsupported(RequestType requestType);
    error GenericConsumer__SpecIdIsZero();

    event ChainlinkCancelled(bytes32 indexed requestId);
    event ChainlinkFulfilled(
        bytes32 indexed requestId,
        bool success,
        bool isForwarded,
        address indexed callbackAddr,
        bytes4 indexed callbackFunctionSignature,
        bytes data
    );
    event ChainlinkRequested(bytes32 indexed requestId);
    event DescriptionSet(string description);
    event EntryRequested(uint256 roundId, uint256 indexed lot, bytes32 indexed key, bytes32 indexed requestId);
    event EntryRemoved(uint256 indexed lot, bytes32 indexed key);
    event EntrySet(uint256 indexed lot, bytes32 indexed key, Entry entry);
    event FundsAdded(address indexed from, address indexed to, uint96 amount);
    event FundsWithdrawn(address indexed from, address indexed to, uint96 amount);
    event IsUpkeepAllowedSet(uint256 indexed lot, bool isUpkeepAllowed);
    event LastRequestTimestampSet(uint256 indexed lot, bytes32 indexed key, uint256 lastRequestTimestamp);
    event LatestRoundIdSet(uint256 latestRoundId);
    event LotRemoved(uint256 indexed lot);
    event MinGasLimitPerformUpkeepSet(uint96 minGasLimit);
    event SetExternalPendingRequestFailed(address indexed callbackAddr, bytes32 indexed requestId, bytes32 indexed key);

    /**
     * @param _link the LINK token address.
     * @param _description the contract description.
     */
    constructor(
        address _link,
        string memory _description,
        uint96 _minGasLimit
    ) ConfirmedOwner(msg.sender) {
        LINK = LinkTokenInterface(_link);
        s_description = _description;
        s_minGasLimitPerformUpkeep = _minGasLimit;
    }

    // solhint-disable-next-line no-complex-fallback, payable-fallback
    fallback() external whenNotPaused {
        bytes4 callbackFunctionSignature = msg.sig; // bytes4(msg.data);
        bytes calldata data = msg.data;
        _requireFallbackMsgData(data);
        bytes32 requestId = abi.decode(data[4:], (bytes32));
        _requireCallerIsRequestOracle(s_pendingRequests[requestId]);
        delete s_pendingRequests[requestId];
        address callbackAddr = s_requestIdToCallbackAddr[requestId];
        if (callbackAddr == NO_CALLBACK_ADDR) {
            emit ChainlinkFulfilled(requestId, true, false, address(this), callbackFunctionSignature, data);
        } else {
            delete s_requestIdToCallbackAddr[requestId];
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = callbackAddr.call(data);
            emit ChainlinkFulfilled(requestId, success, true, callbackAddr, callbackFunctionSignature, data);
        }
    }

    /* ========== EXTERNAL FUNCTIONS ========== */

    function addFunds(address _consumer, uint96 _amount) external {
        _requireConsumerIsNotOwner(_consumer);
        _requireLinkAllowanceIsSufficient(msg.sender, uint96(LINK.allowance(msg.sender, address(this))), _amount);
        _requireLinkBalanceIsSufficient(msg.sender, uint96(LINK.balanceOf(msg.sender)), _amount);
        s_consumerToLinkBalance[_consumer] += _amount;
        emit FundsAdded(msg.sender, _consumer, _amount);
        if (!LINK.transferFrom(msg.sender, address(this), _amount)) {
            revert GenericConsumer__LinkTransferFromFailed(msg.sender, address(this), _amount);
        }
    }

    function cancelRequest(
        bytes32 _requestId,
        uint96 _payment,
        bytes4 _callbackFunctionSignature,
        uint256 _expiration
    ) external {
        address oracleAddr = s_pendingRequests[_requestId];
        _requireRequestIsPending(oracleAddr);
        address consumer = _getConsumer();
        s_consumerToLinkBalance[consumer] += _payment;
        delete s_pendingRequests[_requestId];
        emit ChainlinkCancelled(_requestId);
        OperatorInterface operator = OperatorInterface(oracleAddr);
        operator.cancelOracleRequest(_requestId, _payment, _callbackFunctionSignature, _expiration);
    }

    /**
     * @notice Pauses the contract, which prevents executing requests
     */
    function pause() external onlyOwner {
        _pause();
    }

    function performUpkeep(bytes calldata _performData) external override whenNotPaused {
        (uint256 lot, bytes32[] memory keys) = abi.decode(_performData, (uint256, bytes32[]));
        _requireLotIsInserted(lot, s_lotToEntryMap.isInserted(lot));
        if (msg.sender != owner()) {
            _requireLotIsUpkeepAllowed(lot);
        }
        uint256 keysLength = keys.length;
        _requireArrayIsNotEmpty("keys", keysLength);
        EntryLibrary.Map storage s_keyToEntry = s_lotToEntryMap.getLot(lot);
        uint256 blockTimestamp = block.timestamp;
        uint256 roundId = s_latestRoundId + 1;
        mapping(bytes32 => uint256) storage s_keyToLastRequestTimestamp = s_lotToLastRequestTimestampMap[lot];
        uint256 minGasLimit = uint256(s_minGasLimitPerformUpkeep);
        uint96 consumerLinkBalance = s_consumerToLinkBalance[address(this)];
        uint256 nonce = s_requestCount;
        for (uint256 i = 0; i < keysLength; ) {
            bytes32 key = keys[i];
            unchecked {
                ++i;
            }
            _requireEntryIsInserted(lot, key, s_keyToEntry.isInserted(key));
            Entry memory entry = s_keyToEntry.getEntry(key);
            _requireEntryIsActive(lot, key, entry.inactive);
            _requireEntryIsScheduled(
                lot,
                key,
                entry.startAt,
                entry.interval,
                s_keyToLastRequestTimestamp[key],
                blockTimestamp
            );
            _requireLinkBalanceIsSufficient(address(this), consumerLinkBalance, entry.payment);
            consumerLinkBalance -= entry.payment;
            bytes32 requestId = _buildAndSendRequest(
                nonce,
                entry.specId,
                entry.oracle,
                entry.payment,
                entry.callbackAddr,
                entry.callbackFunctionSignature,
                entry.requestType,
                entry.buffer,
                key
            );
            unchecked {
                ++nonce;
            }
            s_keyToLastRequestTimestamp[key] = blockTimestamp;
            emit EntryRequested(roundId, lot, key, requestId);
            if (gasleft() <= minGasLimit) break;
        }
        s_requestCount = nonce;
        s_consumerToLinkBalance[address(this)] = consumerLinkBalance;
        s_latestRoundId = roundId;
    }

    function removeEntries(uint256 _lot, bytes32[] calldata _keys) external onlyOwner {
        _requireLotIsInserted(_lot, s_lotToEntryMap.isInserted(_lot));
        uint256 keysLength = _keys.length;
        _requireArrayIsNotEmpty("keys", keysLength);
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

    function removeEntry(uint256 _lot, bytes32 _key) external onlyOwner {
        _requireLotIsInserted(_lot, s_lotToEntryMap.isInserted(_lot));
        EntryLibrary.Map storage s_keyToEntry = s_lotToEntryMap.getLot(_lot);
        _removeEntry(s_keyToEntry, _lot, _key);
        delete s_lotToLastRequestTimestampMap[_lot][_key];
        _cleanLotData(s_keyToEntry.size(), _lot);
    }

    function removeLot(uint256 _lot) external onlyOwner {
        _requireLotIsInserted(_lot, s_lotToEntryMap.isInserted(_lot));
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

    function requestData(
        bytes32 _specId,
        address _oracleAddr,
        uint96 _payment,
        bytes4 _callbackFunctionSignature,
        RequestType _requestType,
        bytes calldata _buffer
    ) external whenNotPaused returns (bytes32) {
        return
            _requestData(
                _specId,
                _oracleAddr,
                _payment,
                address(this),
                _callbackFunctionSignature,
                _requestType,
                _buffer,
                false
            );
    }

    function requestDataAndForwardResponse(
        bytes32 _specId,
        address _oracleAddr,
        uint96 _payment,
        address _callbackAddr,
        bytes4 _callbackFunctionSignature,
        RequestType _requestType,
        bytes calldata _buffer
    ) external whenNotPaused returns (bytes32) {
        return
            _requestData(
                _specId,
                _oracleAddr,
                _payment,
                _callbackAddr,
                _callbackFunctionSignature,
                _requestType,
                _buffer,
                true
            );
    }

    function setDescription(string calldata _description) external onlyOwner {
        s_description = _description;
        emit DescriptionSet(_description);
    }

    function setEntries(
        uint256 _lot,
        bytes32[] calldata _keys,
        Entry[] calldata _entries
    ) external onlyOwner {
        uint256 keysLength = _keys.length;
        _requireArrayIsNotEmpty("keys", keysLength);
        _requireArrayLengthsAreEqual("keys", keysLength, "entries", _entries.length);
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
    ) external onlyOwner {
        _setEntry(s_lotToEntryMap.getLot(_lot), _lot, _key, _entry);
        s_lotToEntryMap.set(_lot);
    }

    function setIsUpkeepAllowed(uint256 _lot, bool _isUpkeepAllowed) external onlyOwner {
        _requireLotIsInserted(_lot, s_lotToEntryMap.isInserted(_lot));
        s_lotToIsUpkeepAllowed[_lot] = _isUpkeepAllowed;
        emit IsUpkeepAllowedSet(_lot, _isUpkeepAllowed);
    }

    function setLastRequestTimestamp(
        uint256 _lot,
        bytes32 _key,
        uint256 _lastRequestTimestamp
    ) external onlyOwner {
        _requireLotIsInserted(_lot, s_lotToEntryMap.isInserted(_lot));
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
    ) external onlyOwner {
        _requireLotIsInserted(_lot, s_lotToEntryMap.isInserted(_lot));
        uint256 keysLength = _keys.length;
        _requireArrayIsNotEmpty("keys", keysLength);
        _requireArrayLengthsAreEqual("keys", keysLength, "lastRequestTimestamps", _lastRequestTimestamps.length);
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

    function setLatestRoundId(uint256 _latestRoundId) external onlyOwner {
        s_latestRoundId = _latestRoundId;
        emit LatestRoundIdSet(_latestRoundId);
    }

    function setMinGasLimitPerformUpkeep(uint96 _minGasLimit) external onlyOwner {
        s_minGasLimitPerformUpkeep = _minGasLimit;
        emit MinGasLimitPerformUpkeepSet(_minGasLimit);
    }

    /**
     * @notice Unpauses the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    function withdrawFunds(address _payee, uint96 _amount) external {
        address consumer = _getConsumer();
        uint96 consumerLinkBalance = s_consumerToLinkBalance[consumer];
        _requireLinkBalanceIsSufficient(consumer, consumerLinkBalance, _amount);
        s_consumerToLinkBalance[consumer] = consumerLinkBalance - _amount;
        emit FundsWithdrawn(consumer, _payee, _amount);
        if (!LINK.transfer(_payee, _amount)) {
            revert GenericConsumer__LinkTransferFailed(_payee, _amount);
        }
    }

    /* ========== EXTERNAL VIEW FUNCTIONS ========== */

    function availableFunds(address _consumer) external view returns (uint96) {
        return s_consumerToLinkBalance[_consumer];
    }

    function checkUpkeep(bytes calldata _checkData) external view override cannotExecute returns (bool, bytes memory) {
        uint256 lot = abi.decode(_checkData, (uint256));
        _requireLotIsInserted(lot, s_lotToEntryMap.isInserted(lot));
        EntryLibrary.Map storage s_keyToEntry = s_lotToEntryMap.getLot(lot);
        uint256 keysLength = s_keyToEntry.size();
        _requireLotIsNotEmpty(lot, keysLength); // NB: assertion-like
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
        if (noEntriesToRequest > 0 && s_consumerToLinkBalance[address(this)] >= roundPayment) {
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
        _requireLotIsInserted(_lot, s_lotToEntryMap.isInserted(_lot));
        _requireEntryIsInserted(_lot, _key, s_lotToEntryMap.getLot(_lot).isInserted(_key));
        return s_lotToEntryMap.getLot(_lot).getEntry(_key);
    }

    function getEntryIsInserted(uint256 _lot, bytes32 _key) external view returns (bool) {
        _requireLotIsInserted(_lot, s_lotToEntryMap.isInserted(_lot));
        return s_lotToEntryMap.getLot(_lot).isInserted(_key);
    }

    function getEntryMapKeyAtIndex(uint256 _lot, uint256 _index) external view returns (bytes32) {
        _requireLotIsInserted(_lot, s_lotToEntryMap.isInserted(_lot));
        return s_lotToEntryMap.getLot(_lot).getKeyAtIndex(_index);
    }

    function getEntryMapKeys(uint256 _lot) external view returns (bytes32[] memory) {
        _requireLotIsInserted(_lot, s_lotToEntryMap.isInserted(_lot));
        return s_lotToEntryMap.getLot(_lot).keys;
    }

    function getIsUpkeepAllowed(uint256 _lot) external view returns (bool) {
        _requireLotIsInserted(_lot, s_lotToEntryMap.isInserted(_lot));
        return s_lotToIsUpkeepAllowed[_lot];
    }

    function getLastRequestTimestamp(uint256 _lot, bytes32 _key) external view returns (uint256) {
        _requireLotIsInserted(_lot, s_lotToEntryMap.isInserted(_lot));
        _requireEntryIsInserted(_lot, _key, s_lotToEntryMap.getLot(_lot).isInserted(_key));
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

    function getMinGasLimitPerformUpkeep() external view returns (uint96) {
        return s_minGasLimitPerformUpkeep;
    }

    function getNumberOfEntries(uint256 _lot) external view returns (uint256) {
        _requireLotIsInserted(_lot, s_lotToEntryMap.isInserted(_lot));
        return s_lotToEntryMap.getLot(_lot).size();
    }

    function getNumberOfLots() external view returns (uint256) {
        return s_lotToEntryMap.size();
    }

    /* ========== EXTERNAL PURE FUNCTIONS ========== */

    /**
     * @notice versions:
     *
     * - GenericConsumer 1.0.0: initial release
     * - GenericConsumer 2.0.0: added support for oracle requests, consumer LINK balance, upkeep access control & more
     *
     * @inheritdoc TypeAndVersionInterface
     */
    function typeAndVersion() external pure virtual override returns (string memory) {
        return "GenericConsumer 2.0.0";
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _buildAndSendRequest(
        uint256 _nonce,
        bytes32 _specId,
        address _oracleAddr,
        uint96 _payment,
        address _callbackAddr,
        bytes4 _callbackFunctionSignature,
        RequestType _requestType,
        bytes memory _buffer,
        bytes32 _key
    ) private returns (bytes32) {
        Chainlink.Request memory req;
        req = req.initialize(_specId, address(this), _callbackFunctionSignature);
        req.setBuffer(_buffer);
        bytes32 requestId = _sendRequestTo(_nonce, _oracleAddr, req, _payment, _requestType);
        // In case of "external request" (i.e. callbackAddr != address(this)) notify the fulfillment contract about the
        // pending request
        if (_callbackAddr != address(this)) {
            s_requestIdToCallbackAddr[requestId] = _callbackAddr;
            IChainlinkExternalFulfillment fulfillmentContract = IChainlinkExternalFulfillment(_callbackAddr);
            // solhint-disable-next-line no-empty-blocks
            try fulfillmentContract.setExternalPendingRequest(address(this), requestId) {} catch {
                emit SetExternalPendingRequestFailed(_callbackAddr, requestId, _key);
            }
        }
        return requestId;
    }

    function _cleanLotData(uint256 _noEntries, uint256 _lot) private {
        if (_noEntries == 0) {
            delete s_lotToIsUpkeepAllowed[_lot];
            s_lotToEntryMap.remove(_lot);
        }
    }

    function _removeEntry(
        EntryLibrary.Map storage _s_keyToEntry,
        uint256 _lot,
        bytes32 _key
    ) private {
        _requireEntryIsInserted(_lot, _key, _s_keyToEntry.isInserted(_key));
        _s_keyToEntry.remove(_key);
        emit EntryRemoved(_lot, _key);
    }

    function _requestData(
        bytes32 _specId,
        address _oracleAddr,
        uint96 _payment,
        address _callbackAddr,
        bytes4 _callbackFunctionSignature,
        RequestType _requestType,
        bytes memory _buffer,
        bool _isResponseForwarded
    ) private returns (bytes32) {
        _requireSpecId(_specId);
        _requireOracle(_oracleAddr);
        _requireLinkPaymentIsInRange(_payment);
        if (_isResponseForwarded) {
            _requireCallbackAddr(_callbackAddr);
        }
        _requireCallbackFunctionSignature(_callbackFunctionSignature);

        address consumer = _getConsumer();
        uint96 consumerLinkBalance = s_consumerToLinkBalance[consumer];
        _requireLinkBalanceIsSufficient(consumer, consumerLinkBalance, _payment);
        s_consumerToLinkBalance[consumer] = consumerLinkBalance - _payment;
        uint256 nonce = s_requestCount;
        s_requestCount = nonce + 1;
        return
            _buildAndSendRequest(
                nonce,
                _specId,
                _oracleAddr,
                _payment,
                _callbackAddr,
                _callbackFunctionSignature,
                _requestType,
                _buffer,
                NO_ENTRY_KEY
            );
    }

    function _sendRequestTo(
        uint256 _nonce,
        address _oracleAddress,
        Chainlink.Request memory _req,
        uint96 _payment,
        RequestType _requestType
    ) private returns (bytes32) {
        bytes memory encodedRequest;
        if (_requestType == RequestType.ORACLE) {
            // ChainlinkClient.sendChainlinkRequestTo()
            encodedRequest = abi.encodeWithSelector(
                ChainlinkRequestInterface.oracleRequest.selector,
                SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
                AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
                _req.id,
                address(this),
                _req.callbackFunctionId,
                _nonce,
                ORACLE_ARGS_VERSION,
                _req.buf.buf
            );
        } else if (_requestType == RequestType.OPERATOR) {
            // ChainlinkClient.sendOperatorRequestTo()
            encodedRequest = abi.encodeWithSelector(
                OperatorInterface.operatorRequest.selector,
                SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
                AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
                _req.id,
                _req.callbackFunctionId,
                _nonce,
                OPERATOR_ARGS_VERSION,
                _req.buf.buf
            );
        } else {
            revert GenericConsumer__RequestTypeIsUnsupported(_requestType);
        }
        // ChainlinkClient._rawRequest()
        bytes32 requestId = keccak256(abi.encodePacked(this, _nonce));
        s_pendingRequests[requestId] = _oracleAddress;
        emit ChainlinkRequested(requestId);
        if (!LINK.transferAndCall(_oracleAddress, _payment, encodedRequest)) {
            revert GenericConsumer__LinkTransferAndCallFailed(_oracleAddress, _payment, encodedRequest);
        }
        return requestId;
    }

    function _setEntry(
        EntryLibrary.Map storage _s_keyToEntry,
        uint256 _lot,
        bytes32 _key,
        Entry calldata _entry
    ) private {
        _validateEntryFieldSpecId(_lot, _key, _entry.specId);
        _validateEntryFieldOracle(_lot, _key, _entry.oracle);
        _validateEntryFieldPayment(_lot, _key, _entry.payment);
        _validateEntryFieldCallbackAddr(_lot, _key, _entry.callbackAddr);
        _validateEntryFieldCallbackFunctionSignature(_lot, _key, _entry.callbackFunctionSignature);
        _validateEntryFieldInterval(_lot, _key, _entry.interval);
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
        _requireEntryIsInserted(_lot, _key, _s_keyToEntry.isInserted(_key));
        _s_keyToLastRequestTimestamp[_key] = _lastRequestTimestamp;
        emit LastRequestTimestampSet(_lot, _key, _lastRequestTimestamp);
    }

    /* ========== PRIVATE VIEW FUNCTIONS ========== */

    function _getConsumer() private view returns (address) {
        return msg.sender == owner() ? address(this) : msg.sender;
    }

    function _requireCallbackAddr(address _callbackAddr) private view {
        if (!_callbackAddr.isContract()) {
            revert GenericConsumer__CallbackAddrIsNotContract(_callbackAddr);
        }
        if (_callbackAddr == address(this)) {
            revert GenericConsumer__CallbackAddrIsGenericConsumer(_callbackAddr);
        }
    }

    function _requireCallerIsRequestOracle(address _oracleAddr) private view {
        if (_oracleAddr != msg.sender) {
            _requireRequestIsPending(_oracleAddr);
            revert GenericConsumer__CallerIsNotRequestOracle(_oracleAddr);
        }
    }

    function _requireConsumerIsNotOwner(address _consumer) private view {
        if (_consumer == owner()) {
            revert GenericConsumer__ConsumerAddrIsOwner(_consumer);
        }
    }

    function _requireLotIsUpkeepAllowed(uint256 _lot) private view {
        if (!s_lotToIsUpkeepAllowed[_lot]) {
            revert GenericConsumer__LotIsNotUpkeepAllowed(_lot);
        }
    }

    function _requireOracle(address _oracle) private view {
        if (!_oracle.isContract()) {
            revert GenericConsumer__OracleIsNotContract(_oracle);
        }
    }

    function _validateEntryFieldOracle(
        uint256 _lot,
        bytes32 _key,
        address _oracle
    ) private view {
        if (!_oracle.isContract()) {
            revert GenericConsumer__EntryFieldOracleIsNotContract(_lot, _key, _oracle);
        }
        if (_oracle == address(this)) {
            revert GenericConsumer__EntryFieldOracleIsGenericConsumer(_lot, _key, _oracle);
        }
    }

    /* ========== PRIVATE PURE FUNCTIONS ========== */

    function _isScheduled(
        uint96 _startAt,
        uint96 _interval,
        uint256 _lastRequestTimestamp,
        uint256 _blockTimestamp
    ) private pure returns (bool) {
        return (_startAt <= _blockTimestamp && (_blockTimestamp - _lastRequestTimestamp) >= _interval);
    }

    function _requireArrayIsNotEmpty(string memory _arrayName, uint256 _arrayLength) private pure {
        if (_arrayLength == 0) {
            revert GenericConsumer__ArrayIsEmpty(_arrayName);
        }
    }

    function _requireArrayLengthsAreEqual(
        string memory _array1Name,
        uint256 _array1Length,
        string memory _array2Name,
        uint256 _array2Length
    ) private pure {
        if (_array1Length != _array2Length) {
            revert GenericConsumer__ArrayLengthsAreNotEqual(_array1Name, _array1Length, _array2Name, _array2Length);
        }
    }

    function _requireCallbackFunctionSignature(bytes4 _callbackFunctionSignature) private pure {
        if (_callbackFunctionSignature == NO_CALLBACK_FUNCTION_SIGNATURE) {
            revert GenericConsumer__CallbackFunctionSignatureIsZero();
        }
    }

    function _requireEntryIsActive(
        uint256 _lot,
        bytes32 _key,
        bool _inactive
    ) private pure {
        if (_inactive) {
            revert GenericConsumer__EntryIsInactive(_lot, _key);
        }
    }

    function _requireEntryIsInserted(
        uint256 _lot,
        bytes32 _key,
        bool _isInserted
    ) private pure {
        if (!_isInserted) {
            revert GenericConsumer__EntryIsNotInserted(_lot, _key);
        }
    }

    function _requireEntryIsScheduled(
        uint256 _lot,
        bytes32 _key,
        uint96 _startAt,
        uint96 _interval,
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

    function _requireFallbackMsgData(bytes calldata _data) private pure {
        if (_data.length < MIN_FALLBACK_MSG_DATA_LENGTH) {
            revert GenericConsumer__FallbackMsgDataIsInvalid(_data);
        }
    }

    function _requireLinkAllowanceIsSufficient(
        address _payer,
        uint96 _allowance,
        uint96 _amount
    ) private pure {
        if (_allowance < _amount) {
            revert GenericConsumer__LinkAllowanceIsInsufficient(_payer, _allowance, _amount);
        }
    }

    function _requireLinkBalanceIsSufficient(
        address _payer,
        uint96 _balance,
        uint96 _amount
    ) private pure {
        if (_balance < _amount) {
            revert GenericConsumer__LinkBalanceIsInsufficient(_payer, _balance, _amount);
        }
    }

    function _requireLinkPaymentIsInRange(uint96 _payment) private pure {
        if (_payment > LINK_TOTAL_SUPPLY) {
            revert GenericConsumer__LinkPaymentIsGtLinkTotalSupply(_payment);
        }
    }

    function _requireLotIsInserted(uint256 _lot, bool _isInserted) private pure {
        if (!_isInserted) {
            revert GenericConsumer__LotIsNotInserted(_lot);
        }
    }

    function _requireLotIsNotEmpty(uint256 _lot, uint256 _size) private pure {
        if (_size == 0) {
            revert GenericConsumer__LotIsEmpty(_lot);
        }
    }

    function _requireRequestIsPending(address _oracleAddr) private pure {
        if (_oracleAddr == address(0)) {
            revert GenericConsumer__RequestIsNotPending();
        }
    }

    function _requireSpecId(bytes32 _specId) private pure {
        if (_specId == NO_SPEC_ID) {
            revert GenericConsumer__SpecIdIsZero();
        }
    }

    function _validateEntryFieldCallbackAddr(
        uint256 _lot,
        bytes32 _key,
        address _callbackAddr
    ) private view {
        if (!_callbackAddr.isContract()) {
            revert GenericConsumer__EntryFieldCallbackAddrIsNotContract(_lot, _key, _callbackAddr);
        }
    }

    function _validateEntryFieldCallbackFunctionSignature(
        uint256 _lot,
        bytes32 _key,
        bytes4 _callbackFunctionSignature
    ) private pure {
        if (_callbackFunctionSignature == NO_CALLBACK_FUNCTION_SIGNATURE) {
            revert GenericConsumer__EntryFieldCallbackFunctionSignatureIsZero(_lot, _key);
        }
    }

    function _validateEntryFieldInterval(
        uint256 _lot,
        bytes32 _key,
        uint96 _interval
    ) private pure {
        if (_interval == 0) {
            revert GenericConsumer__EntryFieldIntervalIsZero(_lot, _key);
        }
    }

    function _validateEntryFieldPayment(
        uint256 _lot,
        bytes32 _key,
        uint96 _payment
    ) private pure {
        if (_payment > LINK_TOTAL_SUPPLY) {
            revert GenericConsumer__EntryFieldPaymentIsGtLinkTotalSupply(_lot, _key, _payment);
        }
    }

    function _validateEntryFieldSpecId(
        uint256 _lot,
        bytes32 _key,
        bytes32 _specId
    ) private pure {
        if (_specId == NO_SPEC_ID) {
            revert GenericConsumer__EntryFieldSpecIdIsZero(_lot, _key);
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

abstract contract TypeAndVersionInterface {
  function typeAndVersion() external pure virtual returns (string memory);
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
pragma solidity 0.8.15;

interface IChainlinkExternalFulfillment {
    function setExternalPendingRequest(address _msgSender, bytes32 _requestId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { KeeperCompatibleInterface } from "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import { Entry, EntryLibrary, RequestType } from "../libraries/internal/EntryLibrary.sol";
import { LotLibrary } from "../libraries/internal/LotLibrary.sol";

interface IGenericConsumer is KeeperCompatibleInterface {
    /* ========== EXTERNAL FUNCTIONS ========== */

    function addFunds(address _consumer, uint96 _amount) external;

    function cancelRequest(
        bytes32 _requestId,
        uint96 _payment,
        bytes4 _callbackFunctionSignature,
        uint256 _expiration
    ) external;

    function pause() external;

    function removeEntries(uint256 _lot, bytes32[] calldata _keys) external;

    function removeEntry(uint256 _lot, bytes32 _key) external;

    function removeLot(uint256 _lot) external;

    function requestData(
        bytes32 _specId,
        address _oracle,
        uint96 _payment,
        bytes4 _callbackFunctionSignature,
        RequestType _requestType,
        bytes calldata _buffer
    ) external returns (bytes32);

    function requestDataAndForwardResponse(
        bytes32 _specId,
        address _oracle,
        uint96 _payment,
        address _callbackAddr,
        bytes4 _callbackFunctionSignature,
        RequestType _requestType,
        bytes calldata _buffer
    ) external returns (bytes32);

    function setDescription(string calldata _description) external;

    function setEntries(
        uint256 _lot,
        bytes32[] calldata _keys,
        Entry[] calldata _entries
    ) external;

    function setEntry(
        uint256 _lot,
        bytes32 _key,
        Entry calldata _entry
    ) external;

    function setIsUpkeepAllowed(uint256 _lot, bool _isUpkeepAllowed) external;

    function setLastRequestTimestamp(
        uint256 _lot,
        bytes32 _key,
        uint256 _lastRequestTimestamp
    ) external;

    function setLastRequestTimestamps(
        uint256 _lot,
        bytes32[] calldata _keys,
        uint256[] calldata _lastRequestTimestamps
    ) external;

    function setLatestRoundId(uint256 _latestRoundId) external;

    function setMinGasLimitPerformUpkeep(uint96 _minGasLimit) external;

    function unpause() external;

    function withdrawFunds(address _payee, uint96 _amount) external;

    /* ========== EXTERNAL VIEW FUNCTIONS ========== */

    function availableFunds(address _consumer) external view returns (uint96);

    function getDescription() external view returns (string memory);

    function getEntry(uint256 _lot, bytes32 _key) external view returns (Entry memory);

    function getEntryIsInserted(uint256 _lot, bytes32 _key) external view returns (bool);

    function getEntryMapKeyAtIndex(uint256 _lot, uint256 _index) external view returns (bytes32);

    function getEntryMapKeys(uint256 _lot) external view returns (bytes32[] memory);

    function getIsUpkeepAllowed(uint256 _lot) external view returns (bool);

    function getLastRequestTimestamp(uint256 _lot, bytes32 _key) external view returns (uint256);

    function getLatestRoundId() external view returns (uint256);

    function getLotIsInserted(uint256 _lot) external view returns (bool);

    function getLots() external view returns (uint256[] memory);

    function getNumberOfEntries(uint256 _lot) external view returns (uint256);

    function getNumberOfLots() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

enum RequestType {
    ORACLE, // build and send a Chainlink request (dataVersion = ORACLE_ARGS_VERSION)
    OPERATOR // build and send an Operator request (dataVersion = OPERATOR_ARGS_VERSION)
}

struct Entry {
    bytes32 specId; // 32 bytes -> slot0
    address oracle; // 20 bytes -> slot1
    uint96 payment; // 12 bytes -> slot1
    address callbackAddr; // 20 bytes -> slot2
    uint96 startAt; // 12 bytes -> slot2
    uint96 interval; // 12 bytes -> slot3
    bytes4 callbackFunctionSignature; // 4 bytes -> slot3
    bool inactive; // 1 byte -> slot3
    RequestType requestType; // 1 byte -> slot3
    bytes buffer;
}

library EntryLibrary {
    error EntryLibrary__EntryIsNotInserted(bytes32 key);

    struct Map {
        bytes32[] keys;
        mapping(bytes32 => Entry) keyToEntry;
        mapping(bytes32 => uint256) indexOf;
        mapping(bytes32 => bool) inserted;
    }

    function getEntry(Map storage _self, bytes32 _key) internal view returns (Entry memory) {
        return _self.keyToEntry[_key];
    }

    function getKeyAtIndex(Map storage _self, uint256 _index) internal view returns (bytes32) {
        return _self.keys[_index];
    }

    function isInserted(Map storage _self, bytes32 _key) internal view returns (bool) {
        return _self.inserted[_key];
    }

    function size(Map storage _self) internal view returns (uint256) {
        return _self.keys.length;
    }

    function remove(Map storage _self, bytes32 _key) internal {
        if (!_self.inserted[_key]) {
            revert EntryLibrary__EntryIsNotInserted(_key);
        }

        delete _self.inserted[_key];
        delete _self.keyToEntry[_key];

        uint256 index = _self.indexOf[_key];
        uint256 lastIndex = _self.keys.length - 1;
        bytes32 lastKey = _self.keys[lastIndex];

        _self.indexOf[lastKey] = index;
        delete _self.indexOf[_key];

        _self.keys[index] = lastKey;
        _self.keys.pop();
    }

    function removeAll(Map storage _self) internal {
        uint256 mapSize = size(_self);
        for (uint256 i = 0; i < mapSize; ) {
            bytes32 key = getKeyAtIndex(_self, 0);
            remove(_self, key);
            unchecked {
                ++i;
            }
        }
    }

    function set(
        Map storage _self,
        bytes32 _key,
        Entry calldata _entry
    ) internal {
        if (!_self.inserted[_key]) {
            _self.inserted[_key] = true;
            _self.indexOf[_key] = _self.keys.length;
            _self.keys.push(_key);
        }
        _self.keyToEntry[_key] = _entry;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Entry, EntryLibrary } from "./EntryLibrary.sol";

library LotLibrary {
    using EntryLibrary for EntryLibrary.Map;

    error LotLibrary__LotIsNotInserted(uint256 lot);
    error LotLibrary__LotIsNotEmpty(uint256 lot);

    struct Map {
        uint256[] lots;
        mapping(uint256 => EntryLibrary.Map) lotToEntryMap;
        mapping(uint256 => uint256) indexOf;
        mapping(uint256 => bool) inserted;
    }

    function getLot(Map storage _self, uint256 _lot) internal view returns (EntryLibrary.Map storage) {
        return _self.lotToEntryMap[_lot];
    }

    function isInserted(Map storage _self, uint256 _lot) internal view returns (bool) {
        return _self.inserted[_lot];
    }

    function size(Map storage _self) internal view returns (uint256) {
        return _self.lots.length;
    }

    function remove(Map storage _self, uint256 _lot) internal {
        if (!_self.inserted[_lot]) {
            revert LotLibrary__LotIsNotInserted(_lot);
        }

        if (_self.lotToEntryMap[_lot].size() != 0) {
            revert LotLibrary__LotIsNotEmpty(_lot);
        }
        delete _self.inserted[_lot];

        uint256 index = _self.indexOf[_lot];
        uint256 lastIndex = _self.lots.length - 1;
        uint256 lastKey = _self.lots[lastIndex];

        _self.indexOf[lastKey] = index;
        delete _self.indexOf[_lot];

        _self.lots[index] = lastKey;
        _self.lots.pop();
    }

    function set(Map storage _self, uint256 _lot) internal {
        if (!_self.inserted[_lot]) {
            _self.inserted[_lot] = true;
            _self.indexOf[_lot] = _self.lots.length;
            _self.lots.push(_lot);
        }
    }
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