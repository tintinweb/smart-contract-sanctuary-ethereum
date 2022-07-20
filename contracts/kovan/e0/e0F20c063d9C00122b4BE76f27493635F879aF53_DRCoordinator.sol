// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Chainlink } from "@chainlink/contracts/src/v0.8/Chainlink.sol";
import { ConfirmedOwner } from "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import { FlagsInterface } from "@chainlink/contracts/src/v0.8/interfaces/FlagsInterface.sol";
import { LinkTokenInterface } from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import { OperatorInterface } from "@chainlink/contracts/src/v0.8/interfaces/OperatorInterface.sol";
import { TypeAndVersionInterface } from "@chainlink/contracts/src/v0.8/interfaces/TypeAndVersionInterface.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IDRCoordinator } from "./interfaces/IDRCoordinator.sol";
import { IChainlinkExternalFulfillment } from "./interfaces/IChainlinkExternalFulfillment.sol";
import { FeeType, PaymentType, Spec, SpecLibrary } from "./libraries/internal/SpecLibrary.sol";
import { InsertedAddressLibrary as AuthorizedConsumerLibrary } from "./libraries/internal/InsertedAddressLibrary.sol";

// NB: enum placed outside due to Slither bug https://github.com/crytic/slither/issues/1166
enum PaymentPreFeeType {
    MAX,
    SPOT
}

contract DRCoordinator is ConfirmedOwner, Pausable, ReentrancyGuard, TypeAndVersionInterface, IDRCoordinator {
    using Address for address;
    using AuthorizedConsumerLibrary for AuthorizedConsumerLibrary.Map;
    using Chainlink for Chainlink.Request;
    using SpecLibrary for SpecLibrary.Map;

    uint256 private constant AMOUNT_OVERRIDE = 0; // 32 bytes
    uint256 private constant OPERATOR_ARGS_VERSION = 2; // 32 bytes
    uint256 private constant OPERATOR_REQUEST_EXPIRATION_TIME = 5 minutes;
    bytes32 private constant NO_SPEC_ID = bytes32(0); // 32 bytes
    address private constant SENDER_OVERRIDE = address(0); // 20 bytes
    uint96 private constant LINK_TOTAL_SUPPLY = 1e27; // 12 bytes
    uint64 private constant LINK_TO_JUELS_FACTOR = 1e18; // 8 bytes
    bytes4 private constant OPERATOR_REQUEST_SELECTOR = OperatorInterface.operatorRequest.selector; // 4 bytes
    bytes4 private constant FULFILL_DATA_SELECTOR = this.fulfillData.selector; // 4 bytes
    uint16 public constant PERMIRYAD = 10_000; // 2 bytes
    uint8 public constant MAX_REQUEST_CONFIRMATIONS = 200; // 1 byte
    uint32 private constant MIN_REQUEST_GAS_LIMIT = 400_000; // 6 bytes, from Operator.sol MINIMUM_CONSUMER_GAS_LIMIT
    // NB: with the current balance model & actions after calculating the payment, it is safe setting the
    // GAS_AFTER_PAYMENT_CALCULATION to 50_000 as a constant. Exact amount used is 42422 gas
    uint32 public constant GAS_AFTER_PAYMENT_CALCULATION = 50_000; // 6 bytes
    bool public immutable IS_SEQUENCER_DEPENDANT; // 1 byte
    address public immutable FLAG_SEQUENCER_OFFLINE; // 20 bytes
    FlagsInterface public immutable CHAINLINK_FLAGS; // 20 bytes
    LinkTokenInterface public immutable LINK; // 20 bytes
    AggregatorV3Interface public immutable LINK_TKN_FEED; // 20 bytes
    uint8 private s_permiryadFeeFactor = 1; // 1 byte
    uint256 private s_requestCount = 1; // 32 bytes
    uint256 private s_stalenessSeconds; // 32 bytes
    uint256 private s_fallbackWeiPerUnitLink; // 32 bytes
    string private s_description;
    mapping(bytes32 => address) private s_pendingRequests; /* requestId */ /* operatorAddr */
    mapping(address => uint96) private s_consumerToLinkBalance; /* mgs.sender */ /* LINK */
    mapping(bytes32 => FulfillConfig) private s_requestIdToFulfillConfig; /* requestId */ /* FulfillConfig */
    /* keccak256(abi.encodePacked(operatorAddr, specId)) */
    /* address */
    /* bool */
    mapping(bytes32 => AuthorizedConsumerLibrary.Map) private s_keyToAuthorizedConsumerMap;
    SpecLibrary.Map private s_keyToSpec; /* keccak256(abi.encodePacked(operatorAddr, specId)) */ /* Spec */

    error DRCoordinator__ArrayIsEmpty(string arrayName);
    error DRCoordinator__ArrayLengthsAreNotEqual(
        string array1Name,
        uint256 array1Length,
        string array2Name,
        uint256 array2Length
    );
    error DRCoordinator__CallbackAddrIsDRCoordinator(address callbackAddr);
    error DRCoordinator__CallbackAddrIsNotContract(address callbackAddr);
    error DRCoordinator__CallbackGasLimitIsGtSpecGasLimit(uint32 callbackGasLimit, uint32 specGasLimit);
    error DRCoordinator__CallbackGasLimitIsLtMinRequestGasLimit(uint32 callbackGasLimit, uint32 minRequestGasLimit);
    error DRCoordinator__CallbackMinConfirmationsIsGtSpecMinConfirmations(
        uint8 callbackMinConfirmations,
        uint8 specMinConfirmations
    );
    error DRCoordinator__CallerIsNotAuthorizedConsumer(bytes32 key, address operatorAddr, bytes32 specId);
    error DRCoordinator__CallerIsNotRequester(address requester);
    error DRCoordinator__CallerIsNotRequestOperator(address operatorAddr);
    error DRCoordinator__FallbackWeiPerUnitLinkIsZero();
    error DRCoordinator__FeedAnswerIsNotGtZero(int256 answer);
    error DRCoordinator__FeeTypeIsUnsupported(FeeType feeType);
    error DRCoordinator__LinkAllowanceIsInsufficient(address payer, uint96 allowance, uint96 amount);
    error DRCoordinator__LinkBalanceIsInsufficient(address payer, uint96 balance, uint96 amount);
    error DRCoordinator__LinkPaymentIsGtLinkTotalSupply(uint96 payment, uint96 linkTotalSupply);
    error DRCoordinator__LinkTransferAndCallFailed(address to, uint96 amount, bytes encodedRequest);
    error DRCoordinator__LinkTransferFailed(address to, uint96 amount);
    error DRCoordinator__LinkTransferFromFailed(address from, address to, uint96 amount);
    error DRCoordinator__PaymentPreFeeTypeIsUnsupported(PaymentPreFeeType paymentPreFeeType);
    error DRCoordinator__PaymentTypeIsUnsupported(PaymentType paymentType);
    error DRCoordinator__Reentrant();
    error DRCoordinator__RequestIsNotPending();
    error DRCoordinator__SpecFieldFeeTypeIsUnsupported(bytes32 key, FeeType feeType);
    error DRCoordinator__SpecFieldFeeIsGtLinkTotalSupply(bytes32 key, uint96 fee, uint96 linkTotalSupply);
    error DRCoordinator__SpecFieldFeeIsGtMaxPermiryadFee(bytes32 key, uint96 fee, uint256 maxPermiryadFee);
    error DRCoordinator__SpecFieldGasLimitIsLtMinRequestGasLimit(
        bytes32 key,
        uint32 gasLimit,
        uint32 minRequestGasLimit
    );
    error DRCoordinator__SpecFieldMinConfirmationsIsGtMaxRequestConfirmations(
        bytes32 key,
        uint8 minConfirmations,
        uint8 maxRequestConfirmations
    );
    error DRCoordinator__SpecFieldOperatorIsDRCoordinator(bytes32 key, address operator);
    error DRCoordinator__SpecFieldOperatorIsNotContract(bytes32 key, address operator);
    error DRCoordinator__SpecFieldPaymentIsGtLinkTotalSupply(bytes32 key, uint96 payment, uint96 linkTotalSupply);
    error DRCoordinator__SpecFieldPaymentIsGtPermiryad(bytes32 key, uint96 payment, uint16 permiryad);
    error DRCoordinator__SpecFieldPaymentIsZero(bytes32 key);
    error DRCoordinator__SpecFieldPaymentTypeIsUnsupported(bytes32 key, PaymentType paymentType);
    error DRCoordinator__SpecFieldSpecIdIsZero(bytes32 key);
    error DRCoordinator__SpecIsNotInserted(bytes32 key);

    event AuthorizedConsumersAdded(bytes32 indexed key, address[] consumers);
    event AuthorizedConsumersRemoved(bytes32 indexed key, address[] consumers);
    event ChainlinkCancelled(bytes32 indexed id);
    event ChainlinkFulfilled(
        bytes32 indexed requestId,
        bool success,
        address indexed callbackAddr,
        bytes4 callbackFunctionId,
        int256 payment
    );
    event ChainlinkRequested(bytes32 indexed id);
    event DescriptionSet(string description);
    event FallbackWeiPerUnitLinkSet(uint256 fallbackWeiPerUnitLink);
    event FundsAdded(address indexed from, address indexed to, uint96 amount);
    event FundsWithdrawn(address indexed from, address indexed to, uint96 amount);
    event GasAfterPaymentCalculationSet(uint32 gasAfterPaymentCalculation);
    event PermiryadFeeFactorSet(uint8 permiryadFactor);
    event SetExternalPendingRequestFailed(address indexed callbackAddr, bytes32 indexed requestId, bytes32 key);
    event SpecRemoved(bytes32 indexed key);
    event SpecSet(bytes32 indexed key, Spec spec);
    event StalenessSecondsSet(uint256 stalenessSeconds);

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
        _requireFallbackWeiPerUnitLinkIsGtZero(_fallbackWeiPerUnitLink);
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

    /* ========== EXTERNAL FUNCTIONS ========== */

    function addFunds(address _consumer, uint96 _amount) external nonReentrant {
        _requireLinkAllowanceIsSufficient(msg.sender, uint96(LINK.allowance(msg.sender, address(this))), _amount);
        _requireLinkBalanceIsSufficient(msg.sender, uint96(LINK.balanceOf(msg.sender)), _amount);
        s_consumerToLinkBalance[_consumer] += _amount;
        emit FundsAdded(msg.sender, _consumer, _amount);
        if (!LINK.transferFrom(msg.sender, address(this), _amount)) {
            revert DRCoordinator__LinkTransferFromFailed(msg.sender, address(this), _amount);
        }
    }

    function addSpecAuthorizedConsumers(bytes32 _key, address[] calldata _authConsumers) external onlyOwner {
        _addSpecAuthorizedConsumers(_key, _authConsumers);
    }

    function addSpecsAuthorizedConsumers(bytes32[] calldata _keys, address[][] calldata _authConsumersArray)
        external
        onlyOwner
    {
        uint256 keysLength = _keys.length;
        _requireArrayIsNotEmpty("keys", keysLength);
        _requireArrayLengthsAreEqual("keys", keysLength, "authConsumersArray", _authConsumersArray.length);
        for (uint256 i = 0; i < keysLength; ) {
            _addSpecAuthorizedConsumers(_keys[i], _authConsumersArray[i]);
            unchecked {
                ++i;
            }
        }
    }

    function cancelRequest(bytes32 _requestId) external nonReentrant {
        address operatorAddr = s_pendingRequests[_requestId];
        _requireRequestIsPending(operatorAddr);
        IDRCoordinator.FulfillConfig memory fulfillConfig = s_requestIdToFulfillConfig[_requestId];
        _requireCallerIsRequester(fulfillConfig.msgSender);
        s_consumerToLinkBalance[msg.sender] += fulfillConfig.payment;
        OperatorInterface operator = OperatorInterface(operatorAddr);
        delete s_pendingRequests[_requestId];
        emit ChainlinkCancelled(_requestId);
        operator.cancelOracleRequest(
            _requestId,
            fulfillConfig.payment,
            FULFILL_DATA_SELECTOR,
            fulfillConfig.expiration
        );
    }

    function fulfillData(bytes32 _requestId, bytes calldata _data) external whenNotPaused nonReentrant {
        // Validate sender is the Operator of the request
        _requireCallerIsRequestOperator(s_pendingRequests[_requestId]);
        delete s_pendingRequests[_requestId];
        // Retrieve FulfillConfig by request ID
        IDRCoordinator.FulfillConfig memory fulfillConfig = s_requestIdToFulfillConfig[_requestId];
        // Format off-chain data
        bytes memory data = abi.encodePacked(fulfillConfig.callbackFunctionId, _data);
        // Fulfill just with the gas amount requested by the consumer
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = fulfillConfig.callbackAddr.call{
            gas: fulfillConfig.gasLimit - GAS_AFTER_PAYMENT_CALCULATION
        }(data);
        // Calculate the SPOT LINK payment amount
        int256 spotPaymentInt = _calculatePaymentAmount(
            PaymentPreFeeType.SPOT,
            fulfillConfig.gasLimit,
            tx.gasprice,
            fulfillConfig.payment,
            0,
            fulfillConfig.feeType,
            fulfillConfig.fee
        );
        // NB: statemens below cost 42422 gas -> GAS_AFTER_PAYMENT_CALCULATION = 50k gas
        // Calculate the LINK payment to either pay (consumer -> DRCoordinator) or refund (DRCoordinator -> consumer),
        // check whether the payer has enough balance, and adjust their balances (payer and payee)
        uint96 consumerLinkBalance = s_consumerToLinkBalance[fulfillConfig.msgSender];
        uint96 drCoordinatorLinkBalance = s_consumerToLinkBalance[address(this)];
        uint96 spotPayment;
        address payer;
        uint96 payerLinkBalance;
        if (spotPaymentInt >= 0) {
            spotPayment = uint96(uint256(spotPaymentInt));
            payer = fulfillConfig.msgSender;
            payerLinkBalance = consumerLinkBalance;
        } else {
            spotPayment = uint96(uint256(-spotPaymentInt));
            payer = address(this);
            payerLinkBalance = drCoordinatorLinkBalance;
        }
        _requireLinkPaymentIsInRange(spotPayment);
        _requireLinkBalanceIsSufficient(payer, payerLinkBalance, spotPayment);
        if (spotPaymentInt >= 0) {
            consumerLinkBalance -= spotPayment;
            drCoordinatorLinkBalance += spotPayment;
        } else {
            consumerLinkBalance += spotPayment;
            drCoordinatorLinkBalance -= spotPayment;
        }
        s_consumerToLinkBalance[fulfillConfig.msgSender] = consumerLinkBalance;
        s_consumerToLinkBalance[address(this)] = drCoordinatorLinkBalance;
        delete s_requestIdToFulfillConfig[_requestId];
        emit ChainlinkFulfilled(
            _requestId,
            success,
            fulfillConfig.callbackAddr,
            fulfillConfig.callbackFunctionId,
            spotPaymentInt
        );
    }

    function pause() external onlyOwner {
        _pause();
    }

    function removeSpecAuthorizedConsumers(bytes32 _key, address[] calldata _authConsumers) external onlyOwner {
        AuthorizedConsumerLibrary.Map storage s_authorizedConsumerMap = s_keyToAuthorizedConsumerMap[_key];
        _removeSpecAuthorizedConsumers(_key, _authConsumers, s_authorizedConsumerMap, true);
    }

    function removeSpecsAuthorizedConsumers(bytes32[] calldata _keys, address[][] calldata _authConsumersArray)
        external
        onlyOwner
    {
        uint256 keysLength = _keys.length;
        _requireArrayIsNotEmpty("keys", keysLength);
        _requireArrayLengthsAreEqual("keys", keysLength, "authConsumersArray", _authConsumersArray.length);
        for (uint256 i = 0; i < keysLength; ) {
            bytes32 key = _keys[i];
            AuthorizedConsumerLibrary.Map storage s_authorizedConsumerMap = s_keyToAuthorizedConsumerMap[key];
            _removeSpecAuthorizedConsumers(key, _authConsumersArray[i], s_authorizedConsumerMap, true);
            unchecked {
                ++i;
            }
        }
    }

    function requestData(
        address _operatorAddr,
        uint32 _callbackGasLimit,
        uint8 _callbackMinConfirmations,
        Chainlink.Request memory _req
    ) external whenNotPaused nonReentrant returns (bytes32) {
        // Validate parameters
        bytes32 key = _generateSpecKey(_operatorAddr, _req.id);
        _requireSpecIsInserted(key);
        address callbackAddr = _req.callbackAddress;
        _validateCallbackAddress(callbackAddr); // NB: prevents malicious loops
        // Validate consumer (requester) is authorized to request the Spec
        _requireCallerIsAuthorizedConsumer(key, _operatorAddr, _req.id);
        // Validate arguments against Spec parameters
        Spec memory spec = s_keyToSpec._getSpec(key);
        _validateCallbackGasLimit(_callbackGasLimit, spec.gasLimit);
        _validateCallbackMinConfirmations(_callbackMinConfirmations, spec.minConfirmations);
        // Calculate the MAX LINK payment amount
        uint96 maxPayment = uint96(
            uint256(
                _calculatePaymentAmount(
                    PaymentPreFeeType.MAX,
                    0,
                    tx.gasprice,
                    0,
                    _callbackGasLimit,
                    spec.feeType,
                    spec.fee
                )
            )
        );
        _requireLinkPaymentIsInRange(maxPayment);
        // Calculate the required consumer LINK balance, the LINK payment amount to be held escrow by the Operator,
        // check whether the consumer has enough balance, and adjust its balance
        uint96 consumerLinkBalance = s_consumerToLinkBalance[msg.sender];
        (
            uint96 requiredConsumerLinkBalance,
            uint96 paymentInEscrow
        ) = _calculateRequiredConsumerLinkBalanceAndPaymentInEscrow(maxPayment, spec.paymentType, spec.payment);
        _requireLinkBalanceIsSufficient(msg.sender, consumerLinkBalance, requiredConsumerLinkBalance);
        s_consumerToLinkBalance[msg.sender] = consumerLinkBalance - paymentInEscrow;
        // Initialise the fulfill configuration
        IDRCoordinator.FulfillConfig memory fulfillConfig;
        fulfillConfig.msgSender = msg.sender;
        fulfillConfig.payment = paymentInEscrow;
        fulfillConfig.callbackAddr = callbackAddr;
        fulfillConfig.fee = spec.fee;
        fulfillConfig.minConfirmations = _callbackMinConfirmations;
        fulfillConfig.gasLimit = _callbackGasLimit + GAS_AFTER_PAYMENT_CALCULATION;
        fulfillConfig.feeType = spec.feeType;
        fulfillConfig.callbackFunctionId = _req.callbackFunctionId;
        fulfillConfig.expiration = uint40(block.timestamp + OPERATOR_REQUEST_EXPIRATION_TIME);
        // Replace Chainlink.Request 'callbackAddress', 'callbackFunctionId'
        // and extend 'buffer' with the dynamic TOML jobspec params
        _req.callbackAddress = address(this);
        _req.callbackFunctionId = FULFILL_DATA_SELECTOR;
        _req.addUint("gasLimit", uint256(fulfillConfig.gasLimit));
        // NB: Chainlink nodes 1.2.0 to 1.4.1 can't parse uint/string for 'minConfirmations'
        // https://github.com/smartcontractkit/chainlink/issues/6680
        _req.addUint("minConfirmations", uint256(spec.minConfirmations));
        // Send an Operator request, and store the fulfill configuration by 'requestId'
        bytes32 requestId = _sendOperatorRequestTo(_operatorAddr, _req, paymentInEscrow);
        s_requestIdToFulfillConfig[requestId] = fulfillConfig;
        // In case of "external request" (i.e. requester !== callbackAddr) notify the fulfillment contract about the
        // pending request
        if (callbackAddr != msg.sender) {
            IChainlinkExternalFulfillment fulfillmentContract = IChainlinkExternalFulfillment(callbackAddr);
            // solhint-disable-next-line no-empty-blocks
            try fulfillmentContract.setExternalPendingRequest(address(this), requestId) {} catch {
                emit SetExternalPendingRequestFailed(callbackAddr, requestId, key);
            }
        }
        return requestId;
    }

    function removeSpec(bytes32 _key) external onlyOwner {
        // Remove first Spec authorized consumers
        AuthorizedConsumerLibrary.Map storage s_authorizedConsumerMap = s_keyToAuthorizedConsumerMap[_key];
        if (s_authorizedConsumerMap._size() > 0) {
            _removeSpecAuthorizedConsumers(_key, s_authorizedConsumerMap.keys, s_authorizedConsumerMap, false);
        }
        _removeSpec(_key);
    }

    function removeSpecs(bytes32[] calldata _keys) external onlyOwner {
        uint256 keysLength = _keys.length;
        _requireArrayIsNotEmpty("keys", keysLength);
        for (uint256 i = 0; i < keysLength; ) {
            bytes32 key = _keys[i];
            // Remove first Spec authorized consumers
            AuthorizedConsumerLibrary.Map storage s_authorizedConsumerMap = s_keyToAuthorizedConsumerMap[key];
            if (s_authorizedConsumerMap._size() > 0) {
                _removeSpecAuthorizedConsumers(key, s_authorizedConsumerMap.keys, s_authorizedConsumerMap, false);
            }
            _removeSpec(key);
            unchecked {
                ++i;
            }
        }
    }

    function setDescription(string calldata _description) external onlyOwner {
        s_description = _description;
        emit DescriptionSet(_description);
    }

    function setFallbackWeiPerUnitLink(uint256 _fallbackWeiPerUnitLink) external onlyOwner {
        _requireFallbackWeiPerUnitLinkIsGtZero(_fallbackWeiPerUnitLink);
        s_fallbackWeiPerUnitLink = _fallbackWeiPerUnitLink;
        emit FallbackWeiPerUnitLinkSet(_fallbackWeiPerUnitLink);
    }

    function setPermiryadFeeFactor(uint8 _permiryadFactor) external onlyOwner {
        s_permiryadFeeFactor = _permiryadFactor;
        emit PermiryadFeeFactorSet(_permiryadFactor);
    }

    function setSpec(bytes32 _key, Spec calldata _spec) external onlyOwner {
        _setSpec(_key, _spec);
    }

    function setSpecs(bytes32[] calldata _keys, Spec[] calldata _specs) external onlyOwner {
        uint256 keysLength = _keys.length;
        _requireArrayIsNotEmpty("keys", keysLength);
        _requireArrayLengthsAreEqual("keys", keysLength, "specConsumers", _specs.length);
        for (uint256 i = 0; i < keysLength; ) {
            _setSpec(_keys[i], _specs[i]);
            unchecked {
                ++i;
            }
        }
    }

    function setStalenessSeconds(uint256 _stalenessSeconds) external onlyOwner {
        s_stalenessSeconds = _stalenessSeconds;
        emit StalenessSecondsSet(_stalenessSeconds);
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdrawFunds(address _payee, uint96 _amount) external nonReentrant {
        address consumer = msg.sender == owner() ? address(this) : msg.sender;
        uint96 consumerLinkBalance = s_consumerToLinkBalance[consumer];
        _requireLinkBalanceIsSufficient(consumer, consumerLinkBalance, _amount);
        s_consumerToLinkBalance[consumer] = consumerLinkBalance - _amount;
        emit FundsWithdrawn(consumer, _payee, _amount);
        if (!LINK.transfer(_payee, _amount)) {
            revert DRCoordinator__LinkTransferFailed(_payee, _amount);
        }
    }

    /* ========== EXTERNAL VIEW FUNCTIONS ========== */

    function availableFunds(address _consumer) external view returns (uint96) {
        return s_consumerToLinkBalance[_consumer];
    }

    function calculateMaxPaymentAmount(
        uint256 _weiPerUnitGas,
        uint96 _paymentInEscrow,
        uint32 _gasLimit,
        FeeType _feeType,
        uint96 _fee
    ) external view returns (int256) {
        return
            _calculatePaymentAmount(
                PaymentPreFeeType.MAX,
                0,
                _weiPerUnitGas,
                _paymentInEscrow,
                _gasLimit,
                _feeType,
                _fee
            );
    }

    // NB: this method has limitations. It does not take into account the gas incurrend by
    // Operator.fulfillOracleRequest2() nor DRCoordinator.fulfillData(). All of them are affected, among other things,
    // by the data size and fulfillment function. Therefore it is needed to fine tune 'startGas'
    function calculateSpotPaymentAmount(
        uint32 _startGas,
        uint256 _weiPerUnitGas,
        uint96 _paymentInEscrow,
        FeeType _feeType,
        uint96 _fee
    ) external view returns (int256) {
        return
            _calculatePaymentAmount(
                PaymentPreFeeType.SPOT,
                _startGas,
                _weiPerUnitGas,
                _paymentInEscrow,
                0,
                _feeType,
                _fee
            );
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

    function getFulfillConfig(bytes32 _requestId) external view returns (IDRCoordinator.FulfillConfig memory) {
        return s_requestIdToFulfillConfig[_requestId];
    }

    function getNumberOfSpecs() external view returns (uint256) {
        return s_keyToSpec._size();
    }

    function getPermiryadFeeFactor() external view returns (uint8) {
        return s_permiryadFeeFactor;
    }

    function getRequestCount() external view returns (uint256) {
        return s_requestCount;
    }

    function getSpec(bytes32 _key) external view returns (Spec memory) {
        _requireSpecIsInserted(_key);
        return s_keyToSpec._getSpec(_key);
    }

    function getSpecAuthorizedConsumers(bytes32 _key) external view returns (address[] memory) {
        // NB: s_authorizedConsumerMap only stores keys that exist in s_keyToSpec
        _requireSpecIsInserted(_key);
        return s_keyToAuthorizedConsumerMap[_key].keys;
    }

    function getSpecKeyAtIndex(uint256 _index) external view returns (bytes32) {
        return s_keyToSpec._getKeyAtIndex(_index);
    }

    function getSpecMapKeys() external view returns (bytes32[] memory) {
        return s_keyToSpec.keys;
    }

    function getStalenessSeconds() external view returns (uint256) {
        return s_stalenessSeconds;
    }

    function isSpecAuthorizedConsumer(bytes32 _key, address _consumer) external view returns (bool) {
        // NB: s_authorizedConsumerMap only stores keys that exist in s_keyToSpec
        _requireSpecIsInserted(_key);
        return s_keyToAuthorizedConsumerMap[_key]._isInserted(_consumer);
    }

    /* ========== EXTERNAL PURE FUNCTIONS ========== */

    function typeAndVersion() external pure virtual override returns (string memory) {
        return "DRCoordinator 1.0.0";
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _addSpecAuthorizedConsumers(bytes32 _key, address[] calldata _authConsumers) private {
        _requireSpecIsInserted(_key);
        uint256 authConsumersLength = _authConsumers.length;
        _requireArrayIsNotEmpty("authConsumers", authConsumersLength);
        AuthorizedConsumerLibrary.Map storage s_authorizedConsumerMap = s_keyToAuthorizedConsumerMap[_key];
        for (uint256 i = 0; i < authConsumersLength; ) {
            s_authorizedConsumerMap._add(_authConsumers[i]);
            unchecked {
                ++i;
            }
        }
        emit AuthorizedConsumersAdded(_key, _authConsumers);
    }

    function _removeSpec(bytes32 _key) private {
        _requireSpecIsInserted(_key);
        s_keyToSpec._remove(_key);
        emit SpecRemoved(_key);
    }

    function _removeSpecAuthorizedConsumers(
        bytes32 _key,
        address[] memory _authConsumers,
        AuthorizedConsumerLibrary.Map storage _s_authorizedConsumerMap,
        bool _isUncheckedCase
    ) private {
        uint256 authConsumersLength = _authConsumers.length;
        if (_isUncheckedCase) {
            if (_s_authorizedConsumerMap._size() == 0) {
                revert DRCoordinator__SpecIsNotInserted(_key);
            }
            _requireArrayIsNotEmpty("authConsumers", authConsumersLength);
        }
        for (uint256 i = 0; i < authConsumersLength; ) {
            _s_authorizedConsumerMap._remove(_authConsumers[i]);
            unchecked {
                ++i;
            }
        }
        emit AuthorizedConsumersRemoved(_key, _authConsumers);
    }

    function _sendOperatorRequestTo(
        address _operatorAddr,
        Chainlink.Request memory _req,
        uint96 _payment
    ) private returns (bytes32) {
        uint256 nonce = s_requestCount;
        s_requestCount = nonce + 1;
        bytes memory encodedRequest = abi.encodeWithSelector(
            OPERATOR_REQUEST_SELECTOR,
            SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
            AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
            _req.id,
            _req.callbackFunctionId,
            nonce,
            OPERATOR_ARGS_VERSION,
            _req.buf.buf
        );
        bytes32 requestId = keccak256(abi.encodePacked(this, nonce));
        s_pendingRequests[requestId] = _operatorAddr;
        emit ChainlinkRequested(requestId);
        if (!LINK.transferAndCall(_operatorAddr, _payment, encodedRequest)) {
            revert DRCoordinator__LinkTransferAndCallFailed(_operatorAddr, _payment, encodedRequest);
        }
        return requestId;
    }

    function _setSpec(bytes32 _key, Spec calldata _spec) private {
        _validateSpecFieldSpecId(_key, _spec.specId);
        _validateSpecFieldOperator(_key, _spec.operator);
        _validateSpecFieldFee(_key, _spec.feeType, _spec.fee);
        _validateSpecFieldGasLimit(_key, _spec.gasLimit);
        _validateSpecFieldMinConfirmations(_key, _spec.minConfirmations);
        _validateSpecFieldPayment(_key, _spec.paymentType, _spec.payment);
        s_keyToSpec._set(_key, _spec);
        emit SpecSet(_key, _spec);
    }

    /* ========== PRIVATE VIEW FUNCTIONS ========== */

    function _calculatePaymentAmount(
        PaymentPreFeeType _paymentPreFeeType,
        uint32 _startGas,
        uint256 _weiPerUnitGas,
        uint96 _paymentInEscrow,
        uint32 _gasLimit,
        FeeType _feeType,
        uint96 _fee
    ) private view returns (int256) {
        // NB: parameters accept 0 to allow estimation calls
        uint256 weiPerUnitLink = _getFeedData();
        uint256 paymentPreFee;
        if (_paymentPreFeeType == PaymentPreFeeType.MAX) {
            paymentPreFee = (LINK_TO_JUELS_FACTOR * _weiPerUnitGas * _gasLimit) / weiPerUnitLink;
        } else if (_paymentPreFeeType == PaymentPreFeeType.SPOT) {
            paymentPreFee =
                (LINK_TO_JUELS_FACTOR * _weiPerUnitGas * (GAS_AFTER_PAYMENT_CALCULATION + _startGas - gasleft())) /
                weiPerUnitLink;
        } else {
            revert DRCoordinator__PaymentPreFeeTypeIsUnsupported(_paymentPreFeeType);
        }
        uint256 paymentAfterFee;
        if (_feeType == FeeType.FLAT) {
            paymentAfterFee = paymentPreFee + _fee;
        } else if (_feeType == FeeType.PERMIRYAD) {
            paymentAfterFee = paymentPreFee + (paymentPreFee * _fee) / PERMIRYAD;
        } else {
            revert DRCoordinator__FeeTypeIsUnsupported(_feeType);
        }
        return int256(paymentAfterFee) - int256(uint256(_paymentInEscrow));
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

    function _requireCallerIsAuthorizedConsumer(
        bytes32 _key,
        address _operatorAddr,
        bytes32 _specId
    ) private view {
        AuthorizedConsumerLibrary.Map storage s_authorizedConsumerMap = s_keyToAuthorizedConsumerMap[_key];
        if (s_authorizedConsumerMap._size() > 0 && !s_authorizedConsumerMap._isInserted(msg.sender)) {
            revert DRCoordinator__CallerIsNotAuthorizedConsumer(_key, _operatorAddr, _specId);
        }
    }

    function _requireCallerIsRequester(address _requester) private view {
        if (_requester != msg.sender) {
            revert DRCoordinator__CallerIsNotRequester(_requester);
        }
    }

    function _requireCallerIsRequestOperator(address _operatorAddr) private view {
        if (_operatorAddr != msg.sender) {
            _requireRequestIsPending(_operatorAddr);
            revert DRCoordinator__CallerIsNotRequestOperator(_operatorAddr);
        }
    }

    function _requireLinkPaymentIsInRange(uint96 _payment) private view {
        if (_payment > LINK_TOTAL_SUPPLY) {
            revert DRCoordinator__LinkPaymentIsGtLinkTotalSupply(_payment, LINK_TOTAL_SUPPLY);
        }
    }

    function _requireRequestIsPending(address _operatorAddr) private view {
        if (_operatorAddr == address(0)) {
            revert DRCoordinator__RequestIsNotPending();
        }
    }

    function _requireSpecIsInserted(bytes32 _key) private view {
        if (!s_keyToSpec._isInserted(_key)) {
            revert DRCoordinator__SpecIsNotInserted(_key);
        }
    }

    function _validateCallbackAddress(address _callbackAddr) private view {
        if (!_callbackAddr.isContract()) {
            revert DRCoordinator__CallbackAddrIsNotContract(_callbackAddr);
        }
        if (_callbackAddr == address(this)) {
            revert DRCoordinator__CallbackAddrIsDRCoordinator(_callbackAddr);
        }
    }

    function _validateCallbackGasLimit(uint32 _callbackGasLimit, uint32 _specGasLimit) private view {
        if (_callbackGasLimit > _specGasLimit) {
            revert DRCoordinator__CallbackGasLimitIsGtSpecGasLimit(_callbackGasLimit, _specGasLimit);
        }
        if (_callbackGasLimit < MIN_REQUEST_GAS_LIMIT) {
            revert DRCoordinator__CallbackGasLimitIsLtMinRequestGasLimit(_callbackGasLimit, MIN_REQUEST_GAS_LIMIT);
        }
    }

    function _validateSpecFieldFee(
        bytes32 _key,
        FeeType _feeType,
        uint96 _fee
    ) private view {
        if (_feeType == FeeType.FLAT) {
            if (_fee > LINK_TOTAL_SUPPLY) {
                revert DRCoordinator__SpecFieldFeeIsGtLinkTotalSupply(_key, _fee, LINK_TOTAL_SUPPLY);
            }
        } else if (_feeType == FeeType.PERMIRYAD) {
            uint256 maxPermiryadFee = PERMIRYAD * s_permiryadFeeFactor;
            if (_fee > maxPermiryadFee) {
                revert DRCoordinator__SpecFieldFeeIsGtMaxPermiryadFee(_key, _fee, maxPermiryadFee);
            }
        } else {
            revert DRCoordinator__SpecFieldFeeTypeIsUnsupported(_key, _feeType);
        }
    }

    function _validateSpecFieldOperator(bytes32 _key, address _operator) private view {
        if (!_operator.isContract()) {
            revert DRCoordinator__SpecFieldOperatorIsNotContract(_key, _operator);
        }
        if (_operator == address(this)) {
            revert DRCoordinator__SpecFieldOperatorIsDRCoordinator(_key, _operator);
        }
    }

    /* ========== PRIVATE PURE FUNCTIONS ========== */

    function _calculateRequiredConsumerLinkBalanceAndPaymentInEscrow(
        uint96 _maxPayment,
        PaymentType _paymentType,
        uint96 _payment
    ) private pure returns (uint96, uint96) {
        if (_paymentType == PaymentType.FLAT) {
            // NB: spec.payment could be greater than Max LINK payment
            uint96 requiredConsumerLinkBalance = _maxPayment >= _payment ? _maxPayment : _payment;
            return (requiredConsumerLinkBalance, _payment);
        } else if (_paymentType == PaymentType.PERMIRYAD) {
            return (_maxPayment, (_maxPayment * _payment) / PERMIRYAD);
        } else {
            revert DRCoordinator__PaymentTypeIsUnsupported(_paymentType);
        }
    }

    function _generateSpecKey(address _operatorAddr, bytes32 _specId) private pure returns (bytes32) {
        // (operatorAddr, specId) composite key allows storing N specs with the same externalJobID but different
        // operator address
        return keccak256(abi.encodePacked(_operatorAddr, _specId));
    }

    function _requireArrayIsNotEmpty(string memory _arrayName, uint256 _arrayLength) private pure {
        if (_arrayLength == 0) {
            revert DRCoordinator__ArrayIsEmpty(_arrayName);
        }
    }

    function _requireArrayLengthsAreEqual(
        string memory _array1Name,
        uint256 _array1Length,
        string memory _array2Name,
        uint256 _array2Length
    ) private pure {
        if (_array1Length != _array2Length) {
            revert DRCoordinator__ArrayLengthsAreNotEqual(_array1Name, _array1Length, _array2Name, _array2Length);
        }
    }

    function _requireFallbackWeiPerUnitLinkIsGtZero(uint256 _fallbackWeiPerUnitLink) private pure {
        if (_fallbackWeiPerUnitLink == 0) {
            revert DRCoordinator__FallbackWeiPerUnitLinkIsZero();
        }
    }

    function _requireLinkAllowanceIsSufficient(
        address _payer,
        uint96 _allowance,
        uint96 _amount
    ) private pure {
        if (_allowance < _amount) {
            revert DRCoordinator__LinkAllowanceIsInsufficient(_payer, _allowance, _amount);
        }
    }

    function _requireLinkBalanceIsSufficient(
        address _payer,
        uint96 _balance,
        uint96 _amount
    ) private pure {
        if (_balance < _amount) {
            revert DRCoordinator__LinkBalanceIsInsufficient(_payer, _balance, _amount);
        }
    }

    function _validateCallbackMinConfirmations(uint8 _callbackMinConfirmations, uint8 _specMinConfirmations)
        private
        pure
    {
        if (_callbackMinConfirmations > _specMinConfirmations) {
            revert DRCoordinator__CallbackMinConfirmationsIsGtSpecMinConfirmations(
                _callbackMinConfirmations,
                _specMinConfirmations
            );
        }
    }

    function _validateSpecFieldGasLimit(bytes32 _key, uint32 _gasLimit) private pure {
        if (_gasLimit < MIN_REQUEST_GAS_LIMIT) {
            revert DRCoordinator__SpecFieldGasLimitIsLtMinRequestGasLimit(_key, _gasLimit, MIN_REQUEST_GAS_LIMIT);
        }
    }

    function _validateSpecFieldMinConfirmations(bytes32 _key, uint8 _minConfirmations) private pure {
        if (_minConfirmations > MAX_REQUEST_CONFIRMATIONS) {
            revert DRCoordinator__SpecFieldMinConfirmationsIsGtMaxRequestConfirmations(
                _key,
                _minConfirmations,
                MAX_REQUEST_CONFIRMATIONS
            );
        }
    }

    function _validateSpecFieldPayment(
        bytes32 _key,
        PaymentType _paymentType,
        uint96 _payment
    ) private pure {
        if (_payment == 0) {
            revert DRCoordinator__SpecFieldPaymentIsZero(_key);
        }
        if (_paymentType == PaymentType.FLAT) {
            if (_payment > LINK_TOTAL_SUPPLY) {
                revert DRCoordinator__SpecFieldPaymentIsGtLinkTotalSupply(_key, _payment, LINK_TOTAL_SUPPLY);
            }
        } else if (_paymentType == PaymentType.PERMIRYAD) {
            if (_payment > PERMIRYAD) {
                revert DRCoordinator__SpecFieldPaymentIsGtPermiryad(_key, _payment, PERMIRYAD);
            }
        } else {
            revert DRCoordinator__SpecFieldPaymentTypeIsUnsupported(_key, _paymentType);
        }
    }

    function _validateSpecFieldSpecId(bytes32 _key, bytes32 _specId) private pure {
        if (_specId == NO_SPEC_ID) {
            revert DRCoordinator__SpecFieldSpecIdIsZero(_key);
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

import { Chainlink } from "@chainlink/contracts/src/v0.8/Chainlink.sol";
import { FeeType, Spec, SpecLibrary } from "../libraries/internal/SpecLibrary.sol";

interface IDRCoordinator {
    // FulfillConfig size = slot0 (32) + slot1 (32) + slot2 (15) = 79 bytes
    struct FulfillConfig {
        address msgSender; // 20 bytes -> slot0
        uint96 payment; // 12 bytes -> slot0
        address callbackAddr; // 20 bytes -> slot1
        uint96 fee; // 12 bytes -> slot 1
        uint8 minConfirmations; // 1 byte -> slot2
        uint32 gasLimit; // 4 bytes -> slot2
        FeeType feeType; // 1 byte -> slot2
        bytes4 callbackFunctionId; // 4 bytes -> slot2
        uint40 expiration; // 5 bytes -> slot2
    }

    /* ========== EXTERNAL FUNCTIONS ========== */

    function addFunds(address _consumer, uint96 _amount) external;

    function cancelRequest(bytes32 _requestId) external;

    function requestData(
        address _operatorAddr,
        uint32 _callbackGasLimit,
        uint8 _callbackMinConfirmations,
        Chainlink.Request memory _req
    ) external returns (bytes32);

    function withdrawFunds(address _payee, uint96 _amount) external;

    /* ========== EXTERNAL VIEW FUNCTIONS ========== */

    function availableFunds(address _consumer) external view returns (uint96);

    function calculateMaxPaymentAmount(
        uint256 _weiPerUnitGas,
        uint96 _payment,
        uint32 _gasLimit,
        FeeType _feeType,
        uint96 _fee
    ) external view returns (int256);

    function calculateSpotPaymentAmount(
        uint32 _startGas,
        uint256 _weiPerUnitGas,
        uint96 _payment,
        FeeType _feeType,
        uint96 _fee
    ) external view returns (int256);

    function getDescription() external view returns (string memory);

    function getFeedData() external view returns (uint256);

    function getFallbackWeiPerUnitLink() external view returns (uint256);

    function getFulfillConfig(bytes32 _requestId) external view returns (FulfillConfig memory);

    function getNumberOfSpecs() external view returns (uint256);

    function getRequestCount() external view returns (uint256);

    function getPermiryadFeeFactor() external view returns (uint8);

    function getSpec(bytes32 _key) external view returns (Spec memory);

    function getSpecAuthorizedConsumers(bytes32 _key) external view returns (address[] memory);

    function getSpecKeyAtIndex(uint256 _index) external view returns (bytes32);

    function getSpecMapKeys() external view returns (bytes32[] memory);

    function getStalenessSeconds() external view returns (uint256);

    function isSpecAuthorizedConsumer(bytes32 _key, address _consumer) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IChainlinkExternalFulfillment {
    function setExternalPendingRequest(address _msgSender, bytes32 _requestId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

// The kind of fee to apply on top of the LINK payment before fees (paymentPreFee)
enum FeeType {
    FLAT, // A fixed LINK amount
    PERMIRYAD // A dynamic LINK amount (a percentage of the paymentPreFee)
}
// The kind of LINK payment DRCoordinator makes to the Operator (holds it in escrow) on requesting data
enum PaymentType {
    FLAT, // A fixed LINK amount
    PERMIRYAD // A dynamic LINK amount (a percentage of the MAX LINK payment)
}

// A representation of the essential data of an Operator directrequest TOML job spec. It also includes specific
// variables for dynamic LINK payments, e.g. fee, feeType.
// Spec size = slot0 (32) + slot1 (32) + slot2 (19) = 83 bytes
struct Spec {
    bytes32 specId; // 32 bytes -> slot0
    address operator; // 20 bytes -> slot1
    uint96 payment; // 1e27 < 2^96 = 12 bytes -> slot1
    PaymentType paymentType; // 1 byte -> slot2
    uint96 fee; // 1e27 < 2^96 = 12 bytes -> slot2
    FeeType feeType; // 1 byte -> slot2
    uint32 gasLimit; // < 4.295 billion = 4 bytes -> slot2
    uint8 minConfirmations; // 200 < 2^8 = 1 byte -> slot2
}

/**
 * @title The SpecLibrary library.
 * @author LinkPool.
 * @notice An iterable mapping library for Spec. A Spec is the Solidity representation of the essential data of an
 * Operator directrequest TOML job spec. It also includes specific variables for dynamic LINK payments, e.g. payment,
 * fee, feeType.
 */
library SpecLibrary {
    error SpecLibrary__SpecIsNotInserted(bytes32 key);

    struct Map {
        bytes32[] keys; // key = keccak256(abi.encodePacked(operator, specId))
        mapping(bytes32 => Spec) keyToSpec;
        mapping(bytes32 => uint256) indexOf;
        mapping(bytes32 => bool) inserted;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @notice Deletes a Spec by key.
     * @dev Reverts if the Spec is not inserted.
     * @param _self The reference to this iterable mapping.
     * @param _key The Spec key.
     */
    function _remove(Map storage _self, bytes32 _key) internal {
        if (!_self.inserted[_key]) {
            revert SpecLibrary__SpecIsNotInserted(_key);
        }
        delete _self.inserted[_key];
        delete _self.keyToSpec[_key];

        uint256 index = _self.indexOf[_key];
        uint256 lastIndex = _self.keys.length - 1;
        bytes32 lastKey = _self.keys[lastIndex];

        _self.indexOf[lastKey] = index;
        delete _self.indexOf[_key];

        _self.keys[index] = lastKey;
        _self.keys.pop();
    }

    /**
     * @notice Sets (creates or updates) a Spec.
     * @param _self The reference to this iterable mapping.
     * @param _key The Spec key.
     * @param _spec The Spec data.
     */
    function _set(
        Map storage _self,
        bytes32 _key,
        Spec calldata _spec
    ) internal {
        if (!_self.inserted[_key]) {
            _self.inserted[_key] = true;
            _self.indexOf[_key] = _self.keys.length;
            _self.keys.push(_key);
        }
        _self.keyToSpec[_key] = _spec;
    }

    /* ========== INTERNAL VIEW FUNCTIONS ========== */

    /**
     * @notice Returns a Spec by key.
     * @param _self The reference to this iterable mapping.
     * @param _key The Spec key.
     * @return The Spec.
     */
    function _getSpec(Map storage _self, bytes32 _key) internal view returns (Spec memory) {
        return _self.keyToSpec[_key];
    }

    /**
     * @notice Returns the Spec key at the given index.
     * @param _self The reference to this iterable mapping.
     * @param _index The index of the keys array.
     * @return The Spec key.
     */
    function _getKeyAtIndex(Map storage _self, uint256 _index) internal view returns (bytes32) {
        return _self.keys[_index];
    }

    /**
     * @notice Returns whether there is a Spec inserted by the given key.
     * @param _self The reference to this iterable mapping.
     * @param _key The Spec key.
     * @return Whether the Spec is inserted.
     */
    function _isInserted(Map storage _self, bytes32 _key) internal view returns (bool) {
        return _self.inserted[_key];
    }

    /**
     * @notice Returns the amount of Spec inserted.
     * @param _self The reference to this iterable mapping.
     * @return The amount of Spec inserted.
     */
    function _size(Map storage _self) internal view returns (uint256) {
        return _self.keys.length;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/**
 * @title The InsertedAddressLibrary library.
 * @author LinkPool.
 * @notice An iterable mapping library for addresses. Useful to either grant or revoke by address.
 */
library InsertedAddressLibrary {
    error InsertedAddressLibrary__AddressAlreadyInserted(address key);
    error InsertedAddressLibrary__AddressIsNotInserted(address key);

    struct Map {
        address[] keys;
        mapping(address => uint256) indexOf;
        mapping(address => bool) inserted;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @notice Deletes an address by key.
     * @dev Reverts if the address is not inserted.
     * @param _self The reference to this iterable mapping.
     * @param _key The address to be removed.
     */
    function _remove(Map storage _self, address _key) internal {
        if (!_self.inserted[_key]) {
            revert InsertedAddressLibrary__AddressIsNotInserted(_key);
        }
        delete _self.inserted[_key];

        uint256 index = _self.indexOf[_key];
        uint256 lastIndex = _self.keys.length - 1;
        address lastKey = _self.keys[lastIndex];

        _self.indexOf[lastKey] = index;
        delete _self.indexOf[_key];

        _self.keys[index] = lastKey;
        _self.keys.pop();
    }

    /**
     * @notice Adds an address.
     * @param _self The reference to this iterable mapping.
     * @param _key The address to be added.
     */
    function _add(Map storage _self, address _key) internal {
        if (_self.inserted[_key]) {
            revert InsertedAddressLibrary__AddressAlreadyInserted(_key);
        }
        _self.inserted[_key] = true;
        _self.indexOf[_key] = _self.keys.length;
        _self.keys.push(_key);
    }

    /* ========== INTERNAL VIEW FUNCTIONS ========== */

    /**
     * @notice Returns whether the address (key) is inserted.
     * @param _self The reference to this iterable mapping.
     * @param _key The address (key).
     * @return Whether the address is inserted.
     */
    function _isInserted(Map storage _self, address _key) internal view returns (bool) {
        return _self.inserted[_key];
    }

    /**
     * @notice Returns the amount of addresses (keys) inserted.
     * @param _self The reference to this iterable mapping.
     * @return The amount of addresses inserted.
     */
    function _size(Map storage _self) internal view returns (uint256) {
        return _self.keys.length;
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