// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import { Chainlink, ChainlinkClient, LinkTokenInterface } from "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import { ConfirmedOwner } from "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import { FlagsInterface } from "@chainlink/contracts/src/v0.8/interfaces/FlagsInterface.sol";
import { TypeAndVersionInterface } from "@chainlink/contracts/src/v0.8/interfaces/TypeAndVersionInterface.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IExternalFulfillment } from "./IExternalFulfillment.sol";
import { FeeType, Spec, SpecLibrary } from "./SpecLibrary.sol";

// NB: enum placed outside due to Slither bug https://github.com/crytic/slither/issues/1166
enum PaymentPreFeeType {
    MAX,
    SPOT
}

// NB: enum placed outside due to Slither bug https://github.com/crytic/slither/issues/1166
enum FulfillMode {
    FALLBACK,
    FULFILL_DATA
}

// TODO: notes, all the FulfillMode logic is gonna be removed once either fallback or fulfillData is chosen
contract DRCoordinator is TypeAndVersionInterface, ConfirmedOwner, Pausable, ReentrancyGuard, ChainlinkClient {
    using Address for address;
    using Chainlink for Chainlink.Request;
    using SpecLibrary for SpecLibrary.Map;

    struct FulfillConfig {
        address msgSender; // 20 bytes
        uint96 payment; // 12 bytes
        address callbackAddr; // 20 bytes
        uint96 fulfillmentFee; // 12 bytes
        uint8 minConfirmations; // 1 byte
        uint48 gasLimit; // 6 bytes
        FeeType feeType; // 1 byte
        bytes4 callbackFunctionId; // 4 bytes
    }
    bytes32 private constant NO_SPEC_KEY = bytes32(0); // 32 bytes
    uint96 private constant LINK_TOTAL_SUPPLY = 1e27; // 12 bytes
    uint48 private constant MIN_CONSUMER_GAS_LIMIT = 400_000; // 6 bytes, from Operator.sol MINIMUM_CONSUMER_GAS_LIMIT
    // NB: with the current balance model & actions after calculating the payment, it is safe setting the
    // GAS_AFTER_PAYMENT_CALCULATION to 50_000 as a constant. Exact amount used is 42489 gas
    uint8 private constant MIN_FALLBACK_MSG_DATA_LENGTH = 36; // 1 byte
    uint48 public constant GAS_AFTER_PAYMENT_CALCULATION = 50_000; // 6 bytes
    uint8 public constant MAX_REQUEST_CONFIRMATIONS = 200; // 1 byte
    bool public immutable IS_SEQUENCER_DEPENDANT; // 1 byte
    address public immutable FLAG_SEQUENCER_OFFLINE; // 20 bytes
    FlagsInterface public immutable CHAINLINK_FLAGS; // 20 bytes
    LinkTokenInterface public immutable LINK; // 20 bytes
    AggregatorV3Interface public immutable LINK_TKN_FEED; // 20 bytes
    bytes20 private s_sha1; // 20 bytes
    uint256 private s_stalenessSeconds; // 32 bytes (or uint32 - 4 bytes)
    uint256 private s_fallbackWeiPerUnitLink; // 32 bytes
    string private s_description;
    mapping(address => uint96) private s_consumerToLinkBalance; /* address */ /* LINK */
    mapping(bytes32 => FulfillConfig) private s_requestIdToFulfillConfig; /* requestId */ /* FulfillConfig */
    SpecLibrary.Map private s_keyToSpec; /* keccak256(abi.encodePacked(operator, specId)) */ /* Spec */

    error DRCoordinator__ArraysLengthIsNotEqual();
    error DRCoordinator__CallbackAddrIsDRCoordinator();
    error DRCoordinator__CallbackAddrIsNotAContract();
    error DRCoordinator__CallerIsNotRequester();
    error DRCoordinator__FallbackMsgDataIsInvalid();
    error DRCoordinator__FeedAnswerIsNotGtZero(int256 answer);
    error DRCoordinator__FeeTypeIsUnsupported(FeeType feeType);
    error DRCoordinator__GasLimitIsGtSpecGasLimit(uint48 gasLimit, uint48 specGasLimit);
    error DRCoordinator__GasLimitIsLtMinConsumerGasLimit(uint48 gasLimit, uint48 minConsumerGasLimit);
    error DRCoordinator__FulfillmentFeeIsGtLinkTotalSupply();
    error DRCoordinator__FulfillmentFeeIsZero();
    error DRCoordinator__FulfillModeUnsupported(FulfillMode fulfillmode);
    error DRCoordinator__LinkAllowanceIsInsufficient(uint96 amount, uint96 allowance);
    error DRCoordinator__LinkBalanceIsZero();
    error DRCoordinator__LinkBalanceIsInsufficient(uint96 amount, uint96 balance);
    error DRCoordinator__LinkTransferFailed(address to, uint96 amount);
    error DRCoordinator__LinkTransferFromFailed(address from, address to, uint96 payment);
    error DRCoordinator__LinkWeiPriceIsZero();
    error DRCoordinator__MinConfirmationsIsGtMaxRequestConfirmations(
        uint8 minConfirmations,
        uint8 maxRequestConfirmations
    );
    error DRCoordinator__MinConfirmationsIsGtSpecMinConfirmations(uint8 minConfirmations, uint8 specMinConfirmations);
    error DRCoordinator__OperatorIsNotAContract();
    error DRCoordinator__PaymentAfterFeeIsGtLinkTotalSupply(uint256 paymentAfterFee);
    error DRCoordinator__PaymentIsGtLinkTotalSupply();
    error DRCoordinator__PaymentIsZero();
    error DRCoordinator__PaymentPreFeeIsLtePayment(uint256 paymentPreFee, uint96 payment);
    error DRCoordinator__PaymentPreFeeTypeUnsupported(PaymentPreFeeType paymentPreFeeType);
    error DRCoordinator__RequestIsNotPending();
    error DRCoordinator__SpecIsNotInserted(bytes32 key);
    error DRCoordinator__SpecIdIsZero();
    error DRCoordinator__SpecKeysArraysIsEmpty();

    event DRCoordinator__FallbackWeiPerUnitLinkSet(uint256 fallbackWeiPerUnitLink);
    event DRCoordinator__FundsAdded(address from, uint96 amount);
    event DRCoordinator__FundsWithdrawn(address payee, uint96 amount);
    event DRCoordinator__GasAfterPaymentCalculationSet(uint48 gasAfterPaymentCalculation);
    event DRCoordinator__RequestFulfilled(
        bytes32 indexed requestId,
        bool success,
        address indexed callbackAddr,
        bytes4 callbackFunctionId,
        uint256 payment
    );
    event DRCoordinator__SetChainlinkExternalRequestFailed(
        address indexed callbackAddr,
        bytes32 indexed requestId,
        bytes32 key
    );
    event DRCoordinator__SpecRemoved(bytes32 indexed key);
    event DRCoordinator__SpecSet(bytes32 indexed key, Spec spec);
    event DRCoordinator__StalenessSecondsSet(uint256 stalenessSeconds);

    constructor(
        address _link,
        address _linkTknFeed,
        string memory _description,
        uint256 _fallbackWeiPerUnitLink,
        uint256 _stalenessSeconds,
        bool _isSequencerDependant,
        string memory _sequencerOfflineFlag,
        address _chainlinkFlags
    ) ConfirmedOwner(msg.sender) {
        _requireLinkWeiPrice(_fallbackWeiPerUnitLink);
        setChainlinkToken(_link);
        LINK = LinkTokenInterface(_link);
        LINK_TKN_FEED = AggregatorV3Interface(_linkTknFeed);
        IS_SEQUENCER_DEPENDANT = _isSequencerDependant;
        FLAG_SEQUENCER_OFFLINE = _isSequencerDependant
            ? address(bytes20(bytes32(uint256(keccak256(abi.encodePacked(_sequencerOfflineFlag))) - 1)))
            : address(0);
        CHAINLINK_FLAGS = FlagsInterface(_chainlinkFlags);
        s_description = _description;
        s_fallbackWeiPerUnitLink = _fallbackWeiPerUnitLink;
        s_stalenessSeconds = _stalenessSeconds;
    }

    // solhint-disable-next-line no-complex-fallback, payable-fallback
    fallback() external whenNotPaused nonReentrant {
        // Validate requestId
        bytes calldata data = msg.data;
        _requireFallbackMsgData(data);
        bytes32 requestId = abi.decode(data[4:], (bytes32));
        validateChainlinkCallback(requestId);
        _fulfillData(requestId, data, FulfillMode.FALLBACK);
    }

    /* ========== EXTERNAL FUNCTIONS ========== */

    function addFunds(address _consumer, uint96 _amount) external {
        _requireLinkAllowance(_amount, uint96(LINK.allowance(msg.sender, address(this))));
        _requireLinkBalance(_amount, uint96(LINK.balanceOf(msg.sender)));
        s_consumerToLinkBalance[_consumer] += _amount;
        emit DRCoordinator__FundsAdded(msg.sender, _amount);
        _requireLinkTransferFrom(
            LINK.transferFrom(msg.sender, address(this), _amount),
            msg.sender,
            address(this),
            _amount
        );
    }

    function fulfillData(bytes32 _requestId, bytes calldata _data)
        external
        whenNotPaused
        nonReentrant
        recordChainlinkFulfillment(_requestId)
    {
        _fulfillData(_requestId, _data, FulfillMode.FULFILL_DATA);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function requestDataViaFallback(
        address _operator,
        uint48 _callbackGasLimit,
        uint8 _callbackMinConfirmations,
        Chainlink.Request memory _req
    ) external whenNotPaused nonReentrant returns (bytes32) {
        return _requestData(_operator, _callbackGasLimit, _callbackMinConfirmations, _req, FulfillMode.FALLBACK);
    }

    function requestDataViaFulfillData(
        address _operator,
        uint48 _callbackGasLimit,
        uint8 _callbackMinConfirmations,
        Chainlink.Request memory _req
    ) external whenNotPaused nonReentrant returns (bytes32) {
        return _requestData(_operator, _callbackGasLimit, _callbackMinConfirmations, _req, FulfillMode.FULFILL_DATA);
    }

    function removeSpec(bytes32 _key) external onlyOwner whenNotPaused {
        _removeSpec(_key);
        s_sha1 = bytes20(0);
    }

    function removeSpecs(bytes32[] calldata _keys) external onlyOwner whenNotPaused {
        uint256 keysLength = _keys.length;
        _requireSpecKeys(keysLength);
        for (uint256 i = 0; i < keysLength; ) {
            _removeSpec(_keys[i]);
            unchecked {
                ++i;
            }
        }
        s_sha1 = bytes20(0);
    }

    function setDescription(string calldata _description) external onlyOwner whenNotPaused {
        s_description = _description;
    }

    function setFallbackWeiPerUnitLink(uint256 _fallbackWeiPerUnitLink) external onlyOwner {
        _requireLinkWeiPrice(_fallbackWeiPerUnitLink);
        s_fallbackWeiPerUnitLink = _fallbackWeiPerUnitLink;
        emit DRCoordinator__FallbackWeiPerUnitLinkSet(_fallbackWeiPerUnitLink);
    }

    function setSha1(bytes20 _sha1) external onlyOwner whenNotPaused {
        s_sha1 = _sha1;
    }

    function setSpec(bytes32 _key, Spec calldata _spec) external onlyOwner whenNotPaused {
        _setSpec(_key, _spec);
    }

    function setSpecs(bytes32[] calldata _keys, Spec[] calldata _specs) external onlyOwner whenNotPaused {
        uint256 keysLength = _keys.length;
        _requireSpecKeys(keysLength);
        _requireEqualLength(keysLength, _specs.length);
        for (uint256 i = 0; i < keysLength; ) {
            _setSpec(_keys[i], _specs[i]);
            unchecked {
                ++i;
            }
        }
    }

    function setStalenessSeconds(uint256 _stalenessSeconds) external onlyOwner {
        s_stalenessSeconds = _stalenessSeconds;
        emit DRCoordinator__StalenessSecondsSet(_stalenessSeconds);
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdrawFunds(address _payee, uint96 _amount) external {
        address consumer = msg.sender == owner() ? address(this) : msg.sender;
        _requireLinkBalance(_amount, s_consumerToLinkBalance[consumer]);
        s_consumerToLinkBalance[consumer] -= _amount;
        emit DRCoordinator__FundsWithdrawn(_payee, _amount);
        _requireLinkTransfer(LINK.transfer(_payee, _amount), _payee, _amount);
    }

    /* ========== EXTERNAL VIEW FUNCTIONS ========== */

    function availableFunds(address _consumer) external view returns (uint96) {
        return s_consumerToLinkBalance[_consumer];
    }

    function calculateMaxPaymentAmount(
        uint256 _weiPerUnitGas,
        uint96 _payment,
        uint48 _gasLimit,
        uint96 _fulfillmentFee,
        FeeType _feeType
    ) external view returns (uint96) {
        return
            _calculatePaymentAmount(
                PaymentPreFeeType.MAX,
                0,
                _weiPerUnitGas,
                _payment,
                _gasLimit,
                _fulfillmentFee,
                _feeType
            );
    }

    // NB: this method has limitations. It does not take into account the gas incurrend by Operator::fulfillRequest2
    // nor DRCoordinator::fallback or DRCoordiantor::fulfillData. All of them are affected, among other things,
    // by the data size and fulfillment function. Therefore it is needed to fine tune 'startGas'
    function calculateSpotPaymentAmount(
        uint48 _startGas,
        uint256 _weiPerUnitGas,
        uint96 _payment,
        uint96 _fulfillmentFee,
        FeeType _feeType
    ) external view returns (uint96) {
        return
            _calculatePaymentAmount(
                PaymentPreFeeType.SPOT,
                _startGas,
                _weiPerUnitGas,
                _payment,
                0,
                _fulfillmentFee,
                _feeType
            );
    }

    function cancelRequest(
        bytes32 _requestId,
        uint256 _expiration,
        FulfillMode _fulfillMode
    ) external {
        FulfillConfig memory fulfillConfig = s_requestIdToFulfillConfig[_requestId];
        _requireRequestNotPending(fulfillConfig.msgSender);
        _requireRequester(fulfillConfig.msgSender);

        bytes4 callbackFunctionId;
        if (_fulfillMode == FulfillMode.FULFILL_DATA) {
            callbackFunctionId = this.fulfillData.selector;
        } else {
            callbackFunctionId = fulfillConfig.callbackFunctionId;
        }
        s_consumerToLinkBalance[msg.sender] += fulfillConfig.payment;
        cancelChainlinkRequest(_requestId, fulfillConfig.payment, callbackFunctionId, _expiration);
    }

    function getDescription() external view returns (string memory) {
        return s_description;
    }

    function getFeedData() external view returns (uint256) {
        return _getFeedData();
    }

    function getFallbackWeiPerUnitLink() external view returns (uint256) {
        return s_fallbackWeiPerUnitLink;
    }

    function getNumberOfSpecs() external view returns (uint256) {
        return s_keyToSpec.size();
    }

    function getSha1() external view returns (bytes20) {
        return s_sha1;
    }

    function getSpec(bytes32 _key) external view returns (Spec memory) {
        _requireSpecIsInserted(_key, s_keyToSpec.isInserted(_key));
        return s_keyToSpec.getSpec(_key);
    }

    function getSpecKeyAtIndex(uint256 _index) external view returns (bytes32) {
        return s_keyToSpec.getKeyAtIndex(_index);
    }

    function getSpecMapKeys() external view returns (bytes32[] memory) {
        return s_keyToSpec.keys;
    }

    function getStalenessSeconds() external view returns (uint256) {
        return s_stalenessSeconds;
    }

    /* ========== EXTERNAL PURE FUNCTIONS ========== */

    function typeAndVersion() external pure virtual override returns (string memory) {
        return "DRCoordinator 1.0.0";
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _fulfillData(
        bytes32 _requestId,
        bytes calldata _data,
        FulfillMode _fulfillMode
    ) private {
        // Retrieve FulfillConfig by request ID
        FulfillConfig memory fulfillConfig = s_requestIdToFulfillConfig[_requestId];

        // Format data
        bytes memory data;
        if (_fulfillMode == FulfillMode.FALLBACK) {
            data = _data;
        } else if (_fulfillMode == FulfillMode.FULFILL_DATA) {
            data = abi.encodePacked(fulfillConfig.callbackFunctionId, _data);
        } else {
            revert DRCoordinator__FulfillModeUnsupported(_fulfillMode);
        }

        // Fulfill just with the gas amount requested by the consumer
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = fulfillConfig.callbackAddr.call{
            gas: fulfillConfig.gasLimit - GAS_AFTER_PAYMENT_CALCULATION
        }(data);

        // Charge LINK payment
        uint96 payment = _calculatePaymentAmount(
            PaymentPreFeeType.SPOT,
            fulfillConfig.gasLimit,
            tx.gasprice,
            fulfillConfig.payment,
            0,
            fulfillConfig.fulfillmentFee,
            fulfillConfig.feeType
        );
        // NB: statemens below cost 42489 gas -> GAS_AFTER_PAYMENT_CALCULATION = 50k gas
        _requireLinkBalance(payment, s_consumerToLinkBalance[fulfillConfig.msgSender]);
        s_consumerToLinkBalance[fulfillConfig.msgSender] -= payment;
        s_consumerToLinkBalance[address(this)] += payment;
        delete s_requestIdToFulfillConfig[_requestId];
        emit DRCoordinator__RequestFulfilled(
            _requestId,
            success,
            fulfillConfig.callbackAddr,
            fulfillConfig.callbackFunctionId,
            payment
        );
    }

    function _removeSpec(bytes32 _key) private {
        _requireSpecIsInserted(_key, s_keyToSpec.isInserted(_key));
        s_keyToSpec.remove(_key);
        emit DRCoordinator__SpecRemoved(_key);
    }

    function _requestData(
        address _operator,
        uint48 _callbackGasLimit,
        uint8 _callbackMinConfirmations,
        Chainlink.Request memory _req,
        FulfillMode _fulfillMode
    ) private returns (bytes32) {
        // Validate params
        bytes32 specId = _req.id;
        address callbackAddr = _req.callbackAddress;
        _requireOperator(_operator);
        _requireSpecId(specId);
        _requireCallbackAddr(callbackAddr);
        bytes32 key = _generateSpecKey(_operator, specId);
        _requireSpecIsInserted(key, s_keyToSpec.isInserted(key));
        Spec memory spec = s_keyToSpec.getSpec(key);
        _requireMinConfirmations(_callbackMinConfirmations, spec.minConfirmations);
        _requireGasLimit(_callbackGasLimit, spec.gasLimit);

        // Check whether caller has enough LINK funds (payment amount calculated using all the _callbackGasLimit)
        uint96 maxPayment = _calculatePaymentAmount(
            PaymentPreFeeType.MAX,
            0,
            tx.gasprice,
            spec.payment,
            _callbackGasLimit,
            spec.fulfillmentFee,
            spec.feeType
        );
        _requireLinkBalance(maxPayment, s_consumerToLinkBalance[msg.sender]);
        s_consumerToLinkBalance[msg.sender] -= spec.payment;

        // Initialise the fulfill configuration
        FulfillConfig memory fulfillConfig;
        fulfillConfig.msgSender = msg.sender;
        fulfillConfig.payment = spec.payment;
        fulfillConfig.callbackAddr = callbackAddr;
        fulfillConfig.fulfillmentFee = spec.fulfillmentFee;
        fulfillConfig.minConfirmations = _callbackMinConfirmations;
        uint48 gasLimit = _callbackGasLimit + GAS_AFTER_PAYMENT_CALCULATION;
        fulfillConfig.gasLimit = gasLimit;
        fulfillConfig.feeType = spec.feeType;
        fulfillConfig.callbackFunctionId = _req.callbackFunctionId;

        // Replace Chainlink.Request 'callbackAddress', 'callbackFunctionId'
        // and extend 'buffer' with the dynamic TOML jobspec params
        if (_fulfillMode == FulfillMode.FULFILL_DATA) {
            _req.callbackFunctionId = this.fulfillData.selector;
        }
        _req.callbackAddress = address(this);
        _req.addUint("gasLimit", uint256(gasLimit));
        // NB: Chainlink nodes 1.2.0 to 1.4.1 can't parse uint/string for 'minConfirmations'
        // https://github.com/smartcontractkit/chainlink/issues/6680
        // _req.addUint("minConfirmations", uint256(spec.minConfirmations));
        // _req.add("minConfirmations", Strings.toString(spec.minConfirmations));

        // Send an Operator request, and store the fulfill configuration by 'requestId'
        bytes32 requestId = sendOperatorRequestTo(_operator, _req, uint256(spec.payment));
        s_requestIdToFulfillConfig[requestId] = fulfillConfig;

        // In case of "external request" (i.e. requester !== callbackAddr) notify the fulfillment contract about the
        // pending request
        if (callbackAddr != msg.sender) {
            IExternalFulfillment fulfillmentContract = IExternalFulfillment(callbackAddr);
            // solhint-disable-next-line no-empty-blocks
            try fulfillmentContract.setChainlinkExternalRequest(address(this), requestId) {} catch {
                emit DRCoordinator__SetChainlinkExternalRequestFailed(callbackAddr, requestId, key);
            }
        }
        return requestId;
    }

    function _setSpec(bytes32 _key, Spec calldata _spec) private {
        _requireSpecId(_spec.specId);
        _requireOperator(_spec.operator);
        _requireSpecPayment(_spec.payment);
        _requireSpecMinConfirmations(_spec.minConfirmations);
        _requireSpecGasLimit(_spec.gasLimit);
        _requireSpecFulfillmentFee(_spec.fulfillmentFee);
        s_keyToSpec.set(_key, _spec);
        emit DRCoordinator__SpecSet(_key, _spec);
    }

    /* ========== PRIVATE VIEW FUNCTIONS ========== */

    function _calculatePaymentAmount(
        PaymentPreFeeType _paymentPreFeeType,
        uint48 _startGas,
        uint256 _weiPerUnitGas,
        uint96 _payment,
        uint48 _gasLimit,
        uint96 _fulfillmentFee,
        FeeType _feeType
    ) private view returns (uint96) {
        // NB: parameters accept 0 to allow estimation calls
        uint256 weiPerUnitLink = _getFeedData();
        uint256 paymentPreFee = 0;
        if (_paymentPreFeeType == PaymentPreFeeType.MAX) {
            paymentPreFee = (1e18 * _weiPerUnitGas * _gasLimit) / weiPerUnitLink;
        } else if (_paymentPreFeeType == PaymentPreFeeType.SPOT) {
            paymentPreFee =
                (1e18 * _weiPerUnitGas * (GAS_AFTER_PAYMENT_CALCULATION + _startGas - gasleft())) /
                weiPerUnitLink;
        } else {
            revert DRCoordinator__PaymentPreFeeTypeUnsupported(_paymentPreFeeType);
        }
        if (paymentPreFee <= _payment) {
            // NB: adjust the spec.payment if paymentPreFee - spec.payment <= 0 LINK
            revert DRCoordinator__PaymentPreFeeIsLtePayment(paymentPreFee, _payment);
        }
        paymentPreFee = paymentPreFee - _payment;
        uint256 paymentAfterFee = 0;
        if (_feeType == FeeType.FLAT) {
            paymentAfterFee = paymentPreFee + _fulfillmentFee;
        } else if (_feeType == FeeType.PERMIRYAD) {
            paymentAfterFee = paymentPreFee + (paymentPreFee * _fulfillmentFee) / 1e4;
        } else {
            revert DRCoordinator__FeeTypeIsUnsupported(_feeType);
        }
        if (paymentAfterFee > LINK_TOTAL_SUPPLY) {
            // Amount can't be > LINK total supply
            revert DRCoordinator__PaymentAfterFeeIsGtLinkTotalSupply(paymentAfterFee);
        }
        return uint96(paymentAfterFee);
    }

    // TODO: it currently calculates the 'weiPerUnitLink' via a single feed (LINK / TKN). Add a 2-hops feed support
    // (LINK / USD + TKN / USD, 2 hops) on networks that don't have yet a LINK / TKN feed, e.g. Moonbeam, Harmony
    function _getFeedData() private view returns (uint256) {
        if (IS_SEQUENCER_DEPENDANT && CHAINLINK_FLAGS.getFlag(FLAG_SEQUENCER_OFFLINE)) {
            return s_fallbackWeiPerUnitLink;
        }
        uint256 stalenessSeconds = s_stalenessSeconds;
        uint256 timestamp;
        int256 answer;
        uint256 weiPerUnitLink;
        (, answer, , timestamp, ) = LINK_TKN_FEED.latestRoundData();
        if (answer < 1) {
            revert DRCoordinator__FeedAnswerIsNotGtZero(answer);
        }
        // solhint-disable-next-line not-rely-on-time
        if (stalenessSeconds > 0 && stalenessSeconds < block.timestamp - timestamp) {
            weiPerUnitLink = s_fallbackWeiPerUnitLink;
        } else {
            weiPerUnitLink = uint256(answer);
        }
        return weiPerUnitLink;
    }

    function _requireCallbackAddr(address _callbackAddr) private view {
        if (!_callbackAddr.isContract()) {
            revert DRCoordinator__CallbackAddrIsNotAContract();
        }
        if (_callbackAddr == address(this)) {
            revert DRCoordinator__CallbackAddrIsDRCoordinator();
        }
    }

    function _requireOperator(address _operator) private view {
        if (!_operator.isContract()) {
            revert DRCoordinator__OperatorIsNotAContract();
        }
    }

    function _requireRequester(address _msgSender) private view {
        if (_msgSender != msg.sender) {
            revert DRCoordinator__CallerIsNotRequester();
        }
    }

    /* ========== PRIVATE PURE FUNCTIONS ========== */

    function _generateSpecKey(address _operator, bytes32 _specId) private pure returns (bytes32) {
        // (operator, specId) composite key allows storing N specs with the same externalJobID but different operator
        return keccak256(abi.encodePacked(_operator, _specId));
    }

    function _requireEqualLength(uint256 _length1, uint256 _length2) private pure {
        if (_length1 != _length2) {
            revert DRCoordinator__ArraysLengthIsNotEqual();
        }
    }

    function _requireFallbackMsgData(bytes calldata _data) private pure {
        if (_data.length < MIN_FALLBACK_MSG_DATA_LENGTH) {
            revert DRCoordinator__FallbackMsgDataIsInvalid();
        }
    }

    function _requireGasLimit(uint48 _gasLimit, uint48 _specGasLimit) private pure {
        if (_gasLimit > _specGasLimit) {
            revert DRCoordinator__GasLimitIsGtSpecGasLimit(_gasLimit, _specGasLimit);
        }
        _requireSpecGasLimit(_gasLimit);
    }

    function _requireLinkAllowance(uint96 _amount, uint96 _allowance) private pure {
        if (_allowance < _amount) {
            revert DRCoordinator__LinkAllowanceIsInsufficient(_amount, _allowance);
        }
    }

    function _requireLinkBalance(uint96 _amount, uint96 _balance) private pure {
        if (_balance == 0) {
            revert DRCoordinator__LinkBalanceIsZero();
        }
        if (_balance < _amount) {
            revert DRCoordinator__LinkBalanceIsInsufficient(_amount, _balance);
        }
    }

    function _requireLinkWeiPrice(uint256 _linkWeiPrice) private pure {
        if (_linkWeiPrice == 0) {
            revert DRCoordinator__LinkWeiPriceIsZero();
        }
    }

    function _requireLinkTransfer(
        bool _success,
        address _to,
        uint96 _amount
    ) private pure {
        if (!_success) {
            revert DRCoordinator__LinkTransferFailed(_to, _amount);
        }
    }

    function _requireLinkTransferFrom(
        bool _success,
        address _from,
        address _to,
        uint96 _payment
    ) private pure {
        if (!_success) {
            revert DRCoordinator__LinkTransferFromFailed(_from, _to, _payment);
        }
    }

    function _requireMinConfirmations(uint8 _minConfirmations, uint8 _specMinConfirmations) private pure {
        if (_minConfirmations > _specMinConfirmations) {
            revert DRCoordinator__MinConfirmationsIsGtSpecMinConfirmations(_minConfirmations, _specMinConfirmations);
        }
    }

    function _requireRequestNotPending(address _msgSender) private pure {
        if (_msgSender == address(0)) {
            revert DRCoordinator__RequestIsNotPending();
        }
    }

    function _requireSpecMinConfirmations(uint8 _minConfirmations) private pure {
        if (_minConfirmations > MAX_REQUEST_CONFIRMATIONS) {
            revert DRCoordinator__MinConfirmationsIsGtMaxRequestConfirmations(
                _minConfirmations,
                MAX_REQUEST_CONFIRMATIONS
            );
        }
    }

    function _requireSpecFulfillmentFee(uint96 _fulfillmentFee) private pure {
        if (_fulfillmentFee == 0) {
            revert DRCoordinator__FulfillmentFeeIsZero();
        }
        if (_fulfillmentFee > LINK_TOTAL_SUPPLY) {
            revert DRCoordinator__FulfillmentFeeIsGtLinkTotalSupply();
        }
    }

    function _requireSpecGasLimit(uint48 _gasLimit) private pure {
        if (_gasLimit < MIN_CONSUMER_GAS_LIMIT) {
            revert DRCoordinator__GasLimitIsLtMinConsumerGasLimit(_gasLimit, MIN_CONSUMER_GAS_LIMIT);
        }
    }

    function _requireSpecId(bytes32 _specId) private pure {
        if (_specId == NO_SPEC_KEY) {
            revert DRCoordinator__SpecIdIsZero();
        }
    }

    function _requireSpecIsInserted(bytes32 _key, bool _isInserted) private pure {
        if (!_isInserted) {
            revert DRCoordinator__SpecIsNotInserted(_key);
        }
    }

    function _requireSpecKeys(uint256 keysLength) private pure {
        if (keysLength == 0) {
            revert DRCoordinator__SpecKeysArraysIsEmpty();
        }
    }

    function _requireSpecPayment(uint256 _payment) private pure {
        if (_payment == 0) {
            revert DRCoordinator__PaymentIsZero();
        }
        if (_payment > LINK_TOTAL_SUPPLY) {
            revert DRCoordinator__PaymentIsGtLinkTotalSupply();
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
      address(this),
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

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface FlagsInterface {
  function getFlag(address) external view returns (bool);

  function getFlags(address[] calldata) external view returns (bool[] memory);

  function raiseFlag(address) external;

  function raiseFlags(address[] calldata) external;

  function lowerFlags(address[] calldata) external;

  function setRaisingAccessController(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract TypeAndVersionInterface {
  function typeAndVersion() external pure virtual returns (string memory);
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
    function setChainlinkExternalRequest(address _from, bytes32 _requestId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

enum FeeType {
    FLAT,
    PERMIRYAD
}

struct Spec {
    bytes32 specId; // 32 bytes
    address operator; // 20 bytes
    uint96 payment; // 1e27 < 2^96 = 12 bytes
    uint8 minConfirmations; // 200 < 2^8 = 1 byte
    uint48 gasLimit; // < 2.81 * 10^14 = 6 bytes
    uint96 fulfillmentFee; // 1e27 < 2^96 = 12 bytes
    FeeType feeType; // uint8 = 1 byte
}

error SpecLibrary__SpecIsNotInserted(bytes32 key);

library SpecLibrary {
    struct Map {
        bytes32[] keys; // key = keccak256(abi.encodePacked(oracle, specId))
        mapping(bytes32 => Spec) keyToSpec;
        mapping(bytes32 => uint256) indexOf;
        mapping(bytes32 => bool) inserted;
    }

    function getSpec(Map storage _map, bytes32 _key) internal view returns (Spec memory) {
        return _map.keyToSpec[_key];
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
            revert SpecLibrary__SpecIsNotInserted(_key);
        }

        delete _map.inserted[_key];
        delete _map.keyToSpec[_key];

        uint256 index = _map.indexOf[_key];
        uint256 lastIndex = _map.keys.length - 1;
        bytes32 lastKey = _map.keys[lastIndex];

        _map.indexOf[lastKey] = index;
        delete _map.indexOf[_key];

        _map.keys[index] = lastKey;
        _map.keys.pop();
    }

    function set(
        Map storage _map,
        bytes32 _key,
        Spec calldata _spec
    ) internal {
        if (!_map.inserted[_key]) {
            _map.inserted[_key] = true;
            _map.indexOf[_key] = _map.keys.length;
            _map.keys.push(_key);
        }
        _map.keyToSpec[_key] = _spec;
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