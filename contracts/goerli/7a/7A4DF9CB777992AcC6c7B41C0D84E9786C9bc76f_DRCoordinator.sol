// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Chainlink } from "@chainlink/contracts/src/v0.8/Chainlink.sol";
import { ConfirmedOwner } from "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import { LinkTokenInterface } from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import { OperatorInterface } from "@chainlink/contracts/src/v0.8/interfaces/OperatorInterface.sol";
import { TypeAndVersionInterface } from "@chainlink/contracts/src/v0.8/interfaces/TypeAndVersionInterface.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IDRCoordinator } from "./interfaces/IDRCoordinator.sol";
import { IDRCoordinatorCallable } from "./interfaces/IDRCoordinatorCallable.sol";
import { IChainlinkExternalFulfillment } from "./interfaces/IChainlinkExternalFulfillment.sol";
import { FeeType, PaymentType, Spec, SpecLibrary } from "./libraries/internal/SpecLibrary.sol";
import { InsertedAddressLibrary as AuthorizedConsumerLibrary } from "./libraries/internal/InsertedAddressLibrary.sol";

/**
 * @title The DRCoordinator (coOperator) contract.
 * @author Víctor Navascués.
 * @notice Node operators (NodeOp(s)) can deploy this contract to enable dynamic LINK payments on Direct Request
 * (Any API), syncing the job price (in LINK) with the network gas token (GASTKN) and its conditions.
 * @dev Uses @chainlink/contracts 0.5.1.
 * @dev This contract cooperates with the Chainlink Operator contract. DRCoordinator interfaces 1..N DRCoordinatorClient
 * contracts (Consumer(s)) with 1..N Operator contracts (Operator(s)) by forwarding Chainlink requests and responses.
 * This is a high level overview of a DRCoordinator Direct Request:
 *
 * 1. Adding the job on the Chainlink node
 * ---------------------------------------
 * NodeOps have to add a DRCoordinator-friendly TOML spec, which only requires to:
 * - Set the `minContractPaymentLinkJuels` field to 0 Juels. Make sure to set first the node env var
 * `MINIMUM_CONTRACT_PAYMENT_LINK_JUELS` to 0 as well.
 * - Add the DRCoordinator address in `requesters` to prevent the job being spammed (due to 0 Juels payment).
 * - Add an extra encoding as `(bytes32 requestId, bytes data)` before encoding the `fulfillOracleRequest2` tx.
 *
 * 2. Making the job requestable
 * -----------------------------
 * NodeOps have to:
 * 1. Create the `Spec` (see `SpecLibrary.sol`) of the TOML spec added above and upload it in the DRCoordinator storage
 * via `DRCoordinator.setSpec()`.
 * 2. Use `DRCoordinator.addSpecAuthorizedConsumers()` if on-chain whitelisting of consumers is desired.
 * 3. Share/communicate the `Spec` details (via its key) so the Consumer devs can monitor the `Spec` and act upon any
 * change on it, e.g. `fee`, `payment`, etc.
 *
 * 3. Implementing the Consumer
 * ----------------------------
 * Devs have to:
 * - Make Consumer inherit from `DRCoordinatorClient.sol` (an equivalent of `ChainlinkClient.sol` for DRCoordinator
 * requests). This library only builds the `Chainlink.Request` and then sends it to DRCoordinator (via
 * `DRCoordinator.requestData()`), which is responsible for extending it and ultimately send it to Operator.
 * - Request a `Spec` by passing the Operator address, the maximum amount of gas willing to spend, the maximum amount of
 * LINK willing to pay and the `Chainlink.Request` (which includes the `Spec.specId` as `id` and the request parameters
 * CBOR encoded).
 *
 * Devs can time the request with any of these strategies if gas prices are a concern:
 * - Call `DRCoordinator.calculateMaxPaymentAmount()`.
 * - Call `DRCoordinator.calculateSpotPaymentAmount()`.
 * - Call `DRCoordinator.getFeedData()`.
 *
 * 4. Requesting the job spec
 * --------------------------
 * When Consumer calls `DRCoordinator.requestData()` DRCoordinator does:
 * 1. Validates the arguments.
 * 2. Calculates MAX LINK payment amount, which is the amount of LINK Consumer would pay if all the
 * `callbackGasLimit` was used fulfilling the request (tx `gasLimit`).
 * 3. Checks that the Consumer balance can afford MAX LINK payment and that Consumer is willing to pay the amount.
 * 4. Calculates the LINK payment amount (REQUEST LINK payment) to be hold in escrow by Operator. The payment can be
 * either a flat amount or a percentage (permiryad) of MAX LINK payment. The `paymentType` and `payment` are set in the
 * `Spec` by NodeOp.
 * 5. Updates Consumer balancee.
 * 6. Stores essential data from Consumer, `Chainlink.Request` and `Spec` in a `FulfillConfig` (by request ID) struct to
 * be used upon fulfillment.
 * 7. Extends the Consumer `Chainlink.Request` and sends it to Operator (paying the REQUEST LINK amount).
 *
 * 5. Fulfilling the request
 * -------------------------
 * 1. Validates the request and its caller.
 * 2. Loads the request configuration (`FulfillConfig`) and attempts to fulfill the request by calling the Consumer
 * callback method passing the response data.
 * 3. Calculates SPOT LINK payment, which is the equivalent gas amount used fulfilling the request in LINK, minus
 * the REQUEST LINK payment, plus the fulfillment fee. The fee can be either a flat amount of a percentage (permiryad)
 * of SPOT LINK payment. The `feeType` and `fee` are set in the `Spec` by NodeOp.
 * 4. Checks that the Consumer balance can afford SPOT LINK payment and that Consumer is willing to pay the amount.
 * It is worth mentioning that DRCoordinator can refund Consumer if REQUEST LINK payment was greater than SPOT LINK
 * payment and DRCoordinator's balance is greater or equal than SPOT payment. Tuning the `Spec.payment` and `Spec.fee`
 * should make this particular case very rare.
 * 5.Updates Consumer and DRCoordinator balances.
 *
 * @dev The MAX and SPOT LINK payment amounts are calculated using Chainlink Price Feeds on the network (configured by
 * NodeOp on deployment), which provide the GASTKN wei amount per unit of LINK. The ideal scenario is to use the
 * LINK / GASTKN Price Feed on the network, however two Price Feed (GASTKN / TKN (priceFeed1) & LINK / TKN (priceFeed2))
 * can be set up on deployment.
 * @dev This contract implements the following Chainlink Price Feed risk mitigation strategies: stale answer.
 * The wei value per unit of LINK will default to `fallbackWeiPerUnitLink` (set by NodeOp).
 * @dev This contract implements the following L2 Sequencer Uptime Status Feed risk mitigation strategies: availability
 * and grace period. The wei value per unit of LINK will default to `fallbackWeiPerUnitLink` (set by NodeOp).
 * @dev BE AWARE: this contract currently does not take into account L1 fees when calculating MAX & SPOT LINK payment
 * amounts on L2s.
 * @dev This contract implements an emergency stop mechanism (triggered by NodeOp). Only request data, and fulfill
 * data are the functionalities disabled when the contract is paused.
 * @dev This contract allows CRUD `Spec`. A `Spec` is the representation of a `directrequest` job spec for DRCoordinator
 * requests. Composed of `directrequest` spec unique fields (e.g. `specId`, `operator`) DRCoordinator specific variables
 * to address the LINK payment, e.g. `fee`, `feeType`, etc.
 * @dev This contract allows CRD authorized consumers (whitelisted `requesters`) per `Spec` on-chain. Unfortunately,
 * off-chain whitelisting at TOML job spec level via the `requesters` field is not possible.
 * @dev This contract allows to fulfill requests in a contract different than Consumer who built the `Chainlink.Request`
 * (aka. Chainlink external requests).
 * @dev This contract has an internal LINK balances for itself and any Consumer. Any address (EOA/contract) can fund
 * them. Only the NodeOp (owner) is able to withdraw LINK from the DRCoordinator balance. Only the Consumer is able to
 * withdraw LINK from its balance. Be aware that the REQUEST LINK payment amount is located in the Operator contract
 * (either held in escrow or as earned LINK).
 */
contract DRCoordinator is ConfirmedOwner, Pausable, TypeAndVersionInterface, IDRCoordinator {
    using Address for address;
    using AuthorizedConsumerLibrary for AuthorizedConsumerLibrary.Map;
    using Chainlink for Chainlink.Request;
    using SpecLibrary for SpecLibrary.Map;

    uint256 private constant AMOUNT_OVERRIDE = 0;
    uint256 private constant OPERATOR_ARGS_VERSION = 2;
    uint256 private constant OPERATOR_REQUEST_EXPIRATION_TIME = 5 minutes;
    int256 private constant L2_SEQUENCER_IS_DOWN = 1;
    bytes32 private constant NO_SPEC_ID = bytes32(0);
    uint256 private constant TKN_TO_WEI_FACTOR = 1e18;
    address private constant SENDER_OVERRIDE = address(0);
    uint96 private constant LINK_TOTAL_SUPPLY = 1e27;
    uint64 private constant LINK_TO_JUELS_FACTOR = 1e18;
    bytes4 private constant OPERATOR_REQUEST_SELECTOR = OperatorInterface.operatorRequest.selector;
    bytes4 private constant FULFILL_DATA_SELECTOR = this.fulfillData.selector;
    uint16 private constant PERMIRYAD = 10_000;
    uint32 private constant MIN_REQUEST_GAS_LIMIT = 400_000; // From Operator.sol MINIMUM_CONSUMER_GAS_LIMIT
    // NB: with the current balance model & actions after calculating the payment, it is safe setting the
    // GAS_AFTER_PAYMENT_CALCULATION to 50_000 as a constant. Exact amount used is 42945 gas
    uint32 private constant GAS_AFTER_PAYMENT_CALCULATION = 50_000;
    LinkTokenInterface private immutable i_link;
    AggregatorV3Interface private immutable i_l2SequencerFeed;
    AggregatorV3Interface private immutable i_priceFeed1; // LINK/TKN (single feed) or TKN/USD (multi feed)
    AggregatorV3Interface private immutable i_priceFeed2; // address(0) (single feed) or LINK/USD (multi feed)
    bool private immutable i_isMultiPriceFeedDependant;
    bool private immutable i_isL2SequencerDependant;
    bool private s_isReentrancyLocked;
    uint8 private s_permiryadFeeFactor = 1;
    uint256 private s_requestCount = 1;
    uint256 private s_stalenessSeconds;
    uint256 private s_l2SequencerGracePeriodSeconds;
    uint256 private s_fallbackWeiPerUnitLink;
    string private s_description;
    mapping(bytes32 => address) private s_pendingRequests; /* requestId */ /* operatorAddr */
    mapping(address => uint96) private s_consumerToLinkBalance; /* mgs.sender */ /* LINK */
    mapping(bytes32 => FulfillConfig) private s_requestIdToFulfillConfig; /* requestId */ /* FulfillConfig */
    /* keccak256(abi.encodePacked(operatorAddr, specId)) */
    /* address */
    /* bool */
    mapping(bytes32 => AuthorizedConsumerLibrary.Map) private s_keyToAuthorizedConsumerMap;
    SpecLibrary.Map private s_keyToSpec; /* keccak256(abi.encodePacked(operatorAddr, specId)) */ /* Spec */

    /**
     * @notice versions:
     * - DRCoordinator 1.0.0: release Chainlink Hackaton Fall 2022
     *                      : adopt fulfillData as fulfillment method and remove fallback
     *                      : standardise and improve custom errors and remove unused ones
     *                      : standardise and improve events
     *                      : add paymentType (permiryad support on the requestData LINK payment)
     *                      : allow whitelist consumers per Spec (authorized consumers)
     *                      : add refund mode (DRC refunds LINK if the requestData payment exceeds the fulfillData one)
     *                      : add consumerMaxPayment (requestData & fulfillData revert if LINK payment is greater than)
     *                      : add multi Price Feed (2-hop mode via GASTKN / TKN and LINK / TKN feeds)
     *                      : replace L2 Sequencer Flag with L2 Sequencer Uptime Status Feed
     *                      : improve contract inheritance, e.g. add IDRCoordinator, remove ChainlinkClient, etc.
     *                      : make simple cancelRequest by storing payment and expiration
     *                      : add permiryadFactor (allow setting fees greater than 100%)
     *                      : remove minConfirmations requirement
     *                      : add a public lock
     *                      : improve Consumer tools, e.g. DRCoordinatorClient, ChainlinkExternalFulfillmentCompatible
     *                      : apply Chainlink Solidity Style Guide (skipped args without '_', and contract layout)
     *                      : add NatSpec
     *                      : upgrade to solidity v0.8.17
     * - DRCoordinator 0.1.0: initial release Chainlink Hackaton Spring 2022
     */
    string public constant override typeAndVersion = "DRCoordinator 1.0.0";

    event AuthorizedConsumersAdded(bytes32 indexed key, address[] consumers);
    event AuthorizedConsumersRemoved(bytes32 indexed key, address[] consumers);
    event ChainlinkCancelled(bytes32 indexed id);
    event ChainlinkFulfilled(
        bytes32 indexed requestId,
        bool success,
        address indexed callbackAddr,
        bytes4 callbackFunctionId,
        uint96 requestPayment,
        int256 spotPayment
    );
    event ChainlinkRequested(bytes32 indexed id);
    event DescriptionSet(string description);
    event FallbackWeiPerUnitLinkSet(uint256 fallbackWeiPerUnitLink);
    event FundsAdded(address indexed from, address indexed to, uint96 amount);
    event FundsWithdrawn(address indexed from, address indexed to, uint96 amount);
    event GasAfterPaymentCalculationSet(uint32 gasAfterPaymentCalculation);
    event L2SequencerGracePeriodSecondsSet(uint256 l2SequencerGracePeriodSeconds);
    event PermiryadFeeFactorSet(uint8 permiryadFactor);
    event SetExternalPendingRequestFailed(address indexed callbackAddr, bytes32 indexed requestId, bytes32 key);
    event SpecRemoved(bytes32 indexed key);
    event SpecSet(bytes32 indexed key, Spec spec);
    event StalenessSecondsSet(uint256 stalenessSeconds);

    modifier nonReentrant() {
        if (s_isReentrancyLocked) {
            revert DRCoordinator__CallIsReentrant();
        }
        s_isReentrancyLocked = true;
        _;
        s_isReentrancyLocked = false;
    }

    constructor(
        address _link,
        bool _isMultiPriceFeedDependant,
        address _priceFeed1,
        address _priceFeed2,
        string memory _description,
        uint256 _fallbackWeiPerUnitLink,
        uint256 _stalenessSeconds,
        bool _isL2SequencerDependant,
        address _l2SequencerFeed,
        uint256 _l2SequencerGracePeriodSeconds
    ) ConfirmedOwner(msg.sender) {
        _requirePriceFeed(_isMultiPriceFeedDependant, _priceFeed1, _priceFeed2);
        _requireFallbackWeiPerUnitLinkIsGtZero(_fallbackWeiPerUnitLink);
        _requireL2SequencerFeed(_isL2SequencerDependant, _l2SequencerFeed);
        i_link = LinkTokenInterface(_link);
        i_isMultiPriceFeedDependant = _isMultiPriceFeedDependant;
        i_priceFeed1 = AggregatorV3Interface(_priceFeed1);
        i_priceFeed2 = _isMultiPriceFeedDependant
            ? AggregatorV3Interface(_priceFeed2)
            : AggregatorV3Interface(address(0));
        i_isL2SequencerDependant = _isL2SequencerDependant;
        i_l2SequencerFeed = _isL2SequencerDependant
            ? AggregatorV3Interface(_l2SequencerFeed)
            : AggregatorV3Interface(address(0));
        s_description = _description;
        s_fallbackWeiPerUnitLink = _fallbackWeiPerUnitLink;
        s_stalenessSeconds = _stalenessSeconds;
        s_l2SequencerGracePeriodSeconds = _isL2SequencerDependant ? _l2SequencerGracePeriodSeconds : 0;
    }

    /* ========== EXTERNAL FUNCTIONS ========== */

    /// @inheritdoc IDRCoordinatorCallable
    function addFunds(address _consumer, uint96 _amount) external nonReentrant {
        _requireLinkAllowanceIsSufficient(msg.sender, uint96(i_link.allowance(msg.sender, address(this))), _amount);
        _requireLinkBalanceIsSufficient(msg.sender, uint96(i_link.balanceOf(msg.sender)), _amount);
        s_consumerToLinkBalance[_consumer] += _amount;
        emit FundsAdded(msg.sender, _consumer, _amount);
        if (!i_link.transferFrom(msg.sender, address(this), _amount)) {
            revert DRCoordinator__LinkTransferFromFailed(msg.sender, address(this), _amount);
        }
    }

    /// @inheritdoc IDRCoordinator
    function addSpecAuthorizedConsumers(bytes32 _key, address[] calldata _authConsumers) external onlyOwner {
        _addSpecAuthorizedConsumers(_key, _authConsumers);
    }

    /// @inheritdoc IDRCoordinator
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

    /// @inheritdoc IDRCoordinatorCallable
    function cancelRequest(bytes32 _requestId) external nonReentrant {
        address operatorAddr = s_pendingRequests[_requestId];
        _requireRequestIsPending(operatorAddr);
        FulfillConfig memory fulfillConfig = s_requestIdToFulfillConfig[_requestId];
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

    /// @inheritdoc IDRCoordinatorCallable
    function fulfillData(bytes32 _requestId, bytes calldata _data) external whenNotPaused nonReentrant {
        // Validate sender is the request Operator
        _requireCallerIsRequestOperator(s_pendingRequests[_requestId]);
        delete s_pendingRequests[_requestId];
        // Retrieve the request `FulfillConfig` by request ID
        FulfillConfig memory fulfillConfig = s_requestIdToFulfillConfig[_requestId];
        // Format off-chain data
        bytes memory data = abi.encodePacked(fulfillConfig.callbackFunctionId, _data);
        // Fulfill just with the gas amount requested by Consumer
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = fulfillConfig.callbackAddr.call{
            gas: fulfillConfig.gasLimit - GAS_AFTER_PAYMENT_CALCULATION
        }(data);
        // Calculate SPOT LINK payment
        int256 spotPaymentInt = _calculatePaymentAmount(
            PaymentPreFeeType.SPOT,
            fulfillConfig.gasLimit,
            tx.gasprice,
            fulfillConfig.payment,
            0,
            fulfillConfig.feeType,
            fulfillConfig.fee
        );
        // NB: statemens below cost 42945 gas -> GAS_AFTER_PAYMENT_CALCULATION = 50k gas
        // Calculate SPOT LINK payment to either pay (Consumer -> DRCoordinator) or refund (DRCoordinator -> Consumer)
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
        // Check whether Consumer is willing to pay REQUEST LINK payment + SPOT LINK payment
        if (fulfillConfig.consumerMaxPayment > 0) {
            _requireLinkPaymentIsWithinConsumerMaxPaymentRange(
                spotPaymentInt >= 0 ? fulfillConfig.payment + spotPayment : fulfillConfig.payment - spotPayment,
                fulfillConfig.consumerMaxPayment
            );
        }
        // Check whether payer has enough LINK balance
        _requireLinkBalanceIsSufficient(payer, payerLinkBalance, spotPayment);
        // Update Consumer and DRCoordinator LINK balances
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
            fulfillConfig.payment,
            spotPaymentInt
        );
    }

    /// @inheritdoc IDRCoordinator
    function pause() external onlyOwner {
        _pause();
    }

    /// @inheritdoc IDRCoordinator
    function removeSpecAuthorizedConsumers(bytes32 _key, address[] calldata _authConsumers) external onlyOwner {
        AuthorizedConsumerLibrary.Map storage s_authorizedConsumerMap = s_keyToAuthorizedConsumerMap[_key];
        _removeSpecAuthorizedConsumers(_key, _authConsumers, s_authorizedConsumerMap, true);
    }

    /// @inheritdoc IDRCoordinator
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

    /// @inheritdoc IDRCoordinatorCallable
    function requestData(
        address _operatorAddr,
        uint32 _callbackGasLimit,
        uint96 _consumerMaxPayment,
        Chainlink.Request memory _req
    ) external whenNotPaused nonReentrant returns (bytes32) {
        // Validate parameters
        bytes32 key = _generateSpecKey(_operatorAddr, _req.id);
        _requireSpecIsInserted(key);
        address callbackAddr = _req.callbackAddress;
        _validateCallbackAddress(callbackAddr); // NB: prevents malicious loops
        // Validate Consumer is authorized to request the `Spec`
        _requireCallerIsAuthorizedConsumer(key, _operatorAddr, _req.id);
        // Validate arguments against `Spec` parameters
        Spec memory spec = s_keyToSpec._getSpec(key);
        _validateCallbackGasLimit(_callbackGasLimit, spec.gasLimit);
        // Calculate MAX LINK payment amount
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
        // Check whether Consumer is willing to pay MAX LINK payment
        if (_consumerMaxPayment > 0) {
            _requireLinkPaymentIsWithinConsumerMaxPaymentRange(maxPayment, _consumerMaxPayment);
        }
        // Re-calculate MAX LINK payment (from `Spec.payment`) and calculate REQUEST LINK payment (to be hold in escrow
        // by Operator)
        uint96 consumerLinkBalance = s_consumerToLinkBalance[msg.sender];
        (
            uint96 requiredConsumerLinkBalance,
            uint96 requestPayment
        ) = _calculateRequiredConsumerLinkBalanceAndRequestPayment(maxPayment, spec.paymentType, spec.payment);
        // Check whether Consumer has enough LINK balance and update it
        _requireLinkBalanceIsSufficient(msg.sender, consumerLinkBalance, requiredConsumerLinkBalance);
        s_consumerToLinkBalance[msg.sender] = consumerLinkBalance - requestPayment;
        // Initialise the fulfill configuration
        FulfillConfig memory fulfillConfig;
        fulfillConfig.msgSender = msg.sender;
        fulfillConfig.payment = requestPayment;
        fulfillConfig.callbackAddr = callbackAddr;
        fulfillConfig.fee = spec.fee;
        fulfillConfig.consumerMaxPayment = _consumerMaxPayment;
        fulfillConfig.gasLimit = _callbackGasLimit + GAS_AFTER_PAYMENT_CALCULATION;
        fulfillConfig.feeType = spec.feeType;
        fulfillConfig.callbackFunctionId = _req.callbackFunctionId;
        fulfillConfig.expiration = uint40(block.timestamp + OPERATOR_REQUEST_EXPIRATION_TIME);
        // Replace `callbackAddress` & `callbackFunctionId` in `Chainlink.Request`. Extend its `buffer` with `gasLimit`.
        _req.callbackAddress = address(this);
        _req.callbackFunctionId = FULFILL_DATA_SELECTOR;
        _req.addUint("gasLimit", uint256(fulfillConfig.gasLimit));
        // Send an Operator request, and store the fulfill configuration by request ID
        bytes32 requestId = _sendOperatorRequestTo(_operatorAddr, _req, requestPayment);
        s_requestIdToFulfillConfig[requestId] = fulfillConfig;
        // In case of "external request" (i.e. r`equester !== callbackAddr`) notify the fulfillment contract about the
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

    /// @inheritdoc IDRCoordinator
    function removeSpec(bytes32 _key) external onlyOwner {
        // Remove first `Spec` authorized consumers
        AuthorizedConsumerLibrary.Map storage s_authorizedConsumerMap = s_keyToAuthorizedConsumerMap[_key];
        if (s_authorizedConsumerMap._size() > 0) {
            _removeSpecAuthorizedConsumers(_key, s_authorizedConsumerMap.keys, s_authorizedConsumerMap, false);
        }
        _removeSpec(_key);
    }

    /// @inheritdoc IDRCoordinator
    function removeSpecs(bytes32[] calldata _keys) external onlyOwner {
        uint256 keysLength = _keys.length;
        _requireArrayIsNotEmpty("keys", keysLength);
        for (uint256 i = 0; i < keysLength; ) {
            bytes32 key = _keys[i];
            // Remove first `Spec` authorized consumers
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

    /// @inheritdoc IDRCoordinator
    function setDescription(string calldata _description) external onlyOwner {
        s_description = _description;
        emit DescriptionSet(_description);
    }

    /// @inheritdoc IDRCoordinator
    function setFallbackWeiPerUnitLink(uint256 _fallbackWeiPerUnitLink) external onlyOwner {
        _requireFallbackWeiPerUnitLinkIsGtZero(_fallbackWeiPerUnitLink);
        s_fallbackWeiPerUnitLink = _fallbackWeiPerUnitLink;
        emit FallbackWeiPerUnitLinkSet(_fallbackWeiPerUnitLink);
    }

    /// @inheritdoc IDRCoordinator
    function setL2SequencerGracePeriodSeconds(uint256 _l2SequencerGracePeriodSeconds) external onlyOwner {
        s_l2SequencerGracePeriodSeconds = _l2SequencerGracePeriodSeconds;
        emit L2SequencerGracePeriodSecondsSet(_l2SequencerGracePeriodSeconds);
    }

    /// @inheritdoc IDRCoordinator
    function setPermiryadFeeFactor(uint8 _permiryadFactor) external onlyOwner {
        s_permiryadFeeFactor = _permiryadFactor;
        emit PermiryadFeeFactorSet(_permiryadFactor);
    }

    /// @inheritdoc IDRCoordinator
    function setSpec(bytes32 _key, Spec calldata _spec) external onlyOwner {
        _setSpec(_key, _spec);
    }

    /// @inheritdoc IDRCoordinator
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

    /// @inheritdoc IDRCoordinator
    function setStalenessSeconds(uint256 _stalenessSeconds) external onlyOwner {
        s_stalenessSeconds = _stalenessSeconds;
        emit StalenessSecondsSet(_stalenessSeconds);
    }

    /// @inheritdoc IDRCoordinator
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @inheritdoc IDRCoordinatorCallable
    function withdrawFunds(address _payee, uint96 _amount) external nonReentrant {
        address consumer = msg.sender == owner() ? address(this) : msg.sender;
        uint96 consumerLinkBalance = s_consumerToLinkBalance[consumer];
        _requireLinkBalanceIsSufficient(consumer, consumerLinkBalance, _amount);
        s_consumerToLinkBalance[consumer] = consumerLinkBalance - _amount;
        emit FundsWithdrawn(consumer, _payee, _amount);
        if (!i_link.transfer(_payee, _amount)) {
            revert DRCoordinator__LinkTransferFailed(_payee, _amount);
        }
    }

    /* ========== EXTERNAL VIEW FUNCTIONS ========== */

    /// @inheritdoc IDRCoordinatorCallable
    function availableFunds(address _consumer) external view returns (uint96) {
        return s_consumerToLinkBalance[_consumer];
    }

    /// @inheritdoc IDRCoordinatorCallable
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

    /// @inheritdoc IDRCoordinatorCallable
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

    /// @inheritdoc IDRCoordinatorCallable
    function getDescription() external view returns (string memory) {
        return s_description;
    }

    /// @inheritdoc IDRCoordinatorCallable
    function getFeedData() external view returns (uint256) {
        return _getFeedData();
    }

    /// @inheritdoc IDRCoordinatorCallable
    function getFallbackWeiPerUnitLink() external view returns (uint256) {
        return s_fallbackWeiPerUnitLink;
    }

    /// @inheritdoc IDRCoordinatorCallable
    function getFulfillConfig(bytes32 _requestId) external view returns (FulfillConfig memory) {
        return s_requestIdToFulfillConfig[_requestId];
    }

    /// @inheritdoc IDRCoordinatorCallable
    function getIsL2SequencerDependant() external view returns (bool) {
        return i_isL2SequencerDependant;
    }

    /// @inheritdoc IDRCoordinatorCallable
    function getIsMultiPriceFeedDependant() external view returns (bool) {
        return i_isMultiPriceFeedDependant;
    }

    /// @inheritdoc IDRCoordinatorCallable
    function getIsReentrancyLocked() external view returns (bool) {
        return s_isReentrancyLocked;
    }

    /// @inheritdoc IDRCoordinatorCallable
    function getLinkToken() external view returns (LinkTokenInterface) {
        return i_link;
    }

    /// @inheritdoc IDRCoordinatorCallable
    function getL2SequencerFeed() external view returns (AggregatorV3Interface) {
        return i_l2SequencerFeed;
    }

    /// @inheritdoc IDRCoordinatorCallable
    function getL2SequencerGracePeriodSeconds() external view returns (uint256) {
        return s_l2SequencerGracePeriodSeconds;
    }

    /// @inheritdoc IDRCoordinatorCallable
    function getNumberOfSpecs() external view returns (uint256) {
        return s_keyToSpec._size();
    }

    /// @inheritdoc IDRCoordinatorCallable
    function getPermiryadFeeFactor() external view returns (uint8) {
        return s_permiryadFeeFactor;
    }

    /// @inheritdoc IDRCoordinatorCallable
    function getPriceFeed1() external view returns (AggregatorV3Interface) {
        return i_priceFeed1;
    }

    /// @inheritdoc IDRCoordinatorCallable
    function getPriceFeed2() external view returns (AggregatorV3Interface) {
        return i_priceFeed2;
    }

    /// @inheritdoc IDRCoordinatorCallable
    function getRequestCount() external view returns (uint256) {
        return s_requestCount;
    }

    /// @inheritdoc IDRCoordinatorCallable
    function getSpec(bytes32 _key) external view returns (Spec memory) {
        _requireSpecIsInserted(_key);
        return s_keyToSpec._getSpec(_key);
    }

    /// @inheritdoc IDRCoordinatorCallable
    function getSpecAuthorizedConsumers(bytes32 _key) external view returns (address[] memory) {
        // NB: `s_authorizedConsumerMap` only stores keys that exist in `s_keyToSpec`
        _requireSpecIsInserted(_key);
        return s_keyToAuthorizedConsumerMap[_key].keys;
    }

    /// @inheritdoc IDRCoordinatorCallable
    function getSpecKeyAtIndex(uint256 _index) external view returns (bytes32) {
        return s_keyToSpec._getKeyAtIndex(_index);
    }

    /// @inheritdoc IDRCoordinatorCallable
    function getSpecMapKeys() external view returns (bytes32[] memory) {
        return s_keyToSpec.keys;
    }

    /// @inheritdoc IDRCoordinatorCallable
    function getStalenessSeconds() external view returns (uint256) {
        return s_stalenessSeconds;
    }

    /// @inheritdoc IDRCoordinatorCallable
    function isSpecAuthorizedConsumer(bytes32 _key, address _consumer) external view returns (bool) {
        // NB: `s_authorizedConsumerMap` only stores keys that exist in `s_keyToSpec`
        _requireSpecIsInserted(_key);
        return s_keyToAuthorizedConsumerMap[_key]._isInserted(_consumer);
    }

    /* ========== EXTERNAL PURE FUNCTIONS ========== */

    /// @inheritdoc IDRCoordinatorCallable
    function getGasAfterPaymentCalculation() external pure returns (uint32) {
        return GAS_AFTER_PAYMENT_CALCULATION;
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
            SENDER_OVERRIDE, // Sender value - overridden by `onTokenTransfer()` by the requesting contract's address
            AMOUNT_OVERRIDE, // Amount value - overridden by `onTokenTransfer()` by the actual amount of LINK sent
            _req.id,
            _req.callbackFunctionId,
            nonce,
            OPERATOR_ARGS_VERSION,
            _req.buf.buf
        );
        bytes32 requestId = keccak256(abi.encodePacked(this, nonce));
        s_pendingRequests[requestId] = _operatorAddr;
        emit ChainlinkRequested(requestId);
        if (!i_link.transferAndCall(_operatorAddr, _payment, encodedRequest)) {
            revert DRCoordinator__LinkTransferAndCallFailed(_operatorAddr, _payment, encodedRequest);
        }
        return requestId;
    }

    function _setSpec(bytes32 _key, Spec calldata _spec) private {
        _validateSpecFieldSpecId(_key, _spec.specId);
        _validateSpecFieldOperator(_key, _spec.operator);
        _validateSpecFieldFee(_key, _spec.feeType, _spec.fee);
        _validateSpecFieldGasLimit(_key, _spec.gasLimit);
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

    function _calculateWeiPerUnitLink(
        bool _isPriceFeed1Case,
        AggregatorV3Interface _priceFeed,
        uint256 _stalenessSeconds,
        uint256 _weiPerUnitLink
    ) private view returns (uint256) {
        int256 answer;
        uint256 timestamp;
        (, answer, , timestamp, ) = _priceFeed.latestRoundData();
        if (answer < 1) {
            revert DRCoordinator__FeedAnswerIsNotGtZero(address(_priceFeed), answer);
        }
        // solhint-disable-next-line not-rely-on-time
        if (_stalenessSeconds > 0 && _stalenessSeconds < block.timestamp - timestamp) {
            return s_fallbackWeiPerUnitLink;
        }
        return _isPriceFeed1Case ? uint256(answer) : (uint256(answer) * TKN_TO_WEI_FACTOR) / _weiPerUnitLink;
    }

    function _getFeedData() private view returns (uint256) {
        if (i_isL2SequencerDependant) {
            (, int256 answer, , uint256 startedAt, ) = i_l2SequencerFeed.latestRoundData();
            if (answer == L2_SEQUENCER_IS_DOWN || block.timestamp - startedAt <= s_l2SequencerGracePeriodSeconds) {
                return s_fallbackWeiPerUnitLink;
            }
        }
        uint256 stalenessSeconds = s_stalenessSeconds;
        uint256 weiPerUnitLink = _calculateWeiPerUnitLink(true, i_priceFeed1, stalenessSeconds, 0);
        if (!i_isMultiPriceFeedDependant) return weiPerUnitLink;
        return _calculateWeiPerUnitLink(false, i_priceFeed2, stalenessSeconds, weiPerUnitLink);
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

    function _calculateRequiredConsumerLinkBalanceAndRequestPayment(
        uint96 _maxPayment,
        PaymentType _paymentType,
        uint96 _payment
    ) private pure returns (uint96, uint96) {
        if (_paymentType == PaymentType.FLAT) {
            // NB: `Spec.payment` could be greater than MAX LINK payment
            uint96 requiredConsumerLinkBalance = _maxPayment >= _payment ? _maxPayment : _payment;
            return (requiredConsumerLinkBalance, _payment);
        } else if (_paymentType == PaymentType.PERMIRYAD) {
            return (_maxPayment, (_maxPayment * _payment) / PERMIRYAD);
        } else {
            revert DRCoordinator__PaymentTypeIsUnsupported(_paymentType);
        }
    }

    function _generateSpecKey(address _operatorAddr, bytes32 _specId) private pure returns (bytes32) {
        // `(operatorAddr, specId)` composite key allows storing N specs with the same `externalJobID` but different
        // Operator address
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

    function _requireLinkPaymentIsInRange(uint96 _payment) private pure {
        if (_payment > LINK_TOTAL_SUPPLY) {
            revert DRCoordinator__LinkPaymentIsGtLinkTotalSupply(_payment, LINK_TOTAL_SUPPLY);
        }
    }

    function _requireLinkPaymentIsWithinConsumerMaxPaymentRange(uint96 _payment, uint96 _consumerMaxPayment)
        private
        pure
    {
        if (_payment > _consumerMaxPayment) {
            revert DRCoordinator__LinkPaymentIsGtConsumerMaxPayment(_payment, _consumerMaxPayment);
        }
    }

    function _requireL2SequencerFeed(bool _isL2SequencerDependant, address _l2SequencerFeed) private view {
        if (_isL2SequencerDependant && !_l2SequencerFeed.isContract()) {
            revert DRCoordinator__L2SequencerFeedIsNotContract(_l2SequencerFeed);
        }
    }

    function _requirePriceFeed(
        bool _isMultiPriceFeedDependant,
        address _priceFeed1,
        address _priceFeed2
    ) private view {
        if (!_priceFeed1.isContract()) {
            revert DRCoordinator__PriceFeedIsNotContract(_priceFeed1);
        }
        if (_isMultiPriceFeedDependant && !_priceFeed2.isContract()) {
            revert DRCoordinator__PriceFeedIsNotContract(_priceFeed2);
        }
    }

    function _requireRequestIsPending(address _operatorAddr) private pure {
        if (_operatorAddr == address(0)) {
            revert DRCoordinator__RequestIsNotPending();
        }
    }

    function _validateCallbackGasLimit(uint32 _callbackGasLimit, uint32 _specGasLimit) private pure {
        if (_callbackGasLimit > _specGasLimit) {
            revert DRCoordinator__CallbackGasLimitIsGtSpecGasLimit(_callbackGasLimit, _specGasLimit);
        }
        if (_callbackGasLimit < MIN_REQUEST_GAS_LIMIT) {
            revert DRCoordinator__CallbackGasLimitIsLtMinRequestGasLimit(_callbackGasLimit, MIN_REQUEST_GAS_LIMIT);
        }
    }

    function _validateSpecFieldGasLimit(bytes32 _key, uint32 _gasLimit) private pure {
        if (_gasLimit < MIN_REQUEST_GAS_LIMIT) {
            revert DRCoordinator__SpecFieldGasLimitIsLtMinRequestGasLimit(_key, _gasLimit, MIN_REQUEST_GAS_LIMIT);
        }
    }

    function _validateSpecFieldPayment(
        bytes32 _key,
        PaymentType _paymentType,
        uint96 _payment
    ) private pure {
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
pragma solidity 0.8.17;

import { Chainlink } from "@chainlink/contracts/src/v0.8/Chainlink.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import { LinkTokenInterface } from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import { FeeType, PaymentType, Spec } from "../libraries/internal/SpecLibrary.sol";

/**
 * @notice Contract writers can inherit this contract in order to interact with a DRCoordinator.
 */
interface IDRCoordinatorCallable {
    // Used in the function that calculates the LINK payment amount to execute a specific logic.
    enum PaymentPreFeeType {
        MAX,
        SPOT
    }

    error DRCoordinator__CallbackAddrIsDRCoordinator(address callbackAddr);
    error DRCoordinator__CallbackAddrIsNotContract(address callbackAddr);
    error DRCoordinator__CallbackGasLimitIsGtSpecGasLimit(uint32 callbackGasLimit, uint32 specGasLimit);
    error DRCoordinator__CallbackGasLimitIsLtMinRequestGasLimit(uint32 callbackGasLimit, uint32 minRequestGasLimit);
    error DRCoordinator__CallerIsNotAuthorizedConsumer(bytes32 key, address operatorAddr, bytes32 specId);
    error DRCoordinator__CallerIsNotRequester(address requester);
    error DRCoordinator__CallerIsNotRequestOperator(address operatorAddr);
    error DRCoordinator__CallIsReentrant();
    error DRCoordinator__FeedAnswerIsNotGtZero(address priceFeed, int256 answer);
    error DRCoordinator__FeeTypeIsUnsupported(FeeType feeType);
    error DRCoordinator__LinkAllowanceIsInsufficient(address payer, uint96 allowance, uint96 amount);
    error DRCoordinator__LinkBalanceIsInsufficient(address payer, uint96 balance, uint96 amount);
    error DRCoordinator__LinkPaymentIsGtConsumerMaxPayment(uint96 payment, uint96 consumerMaxPayment);
    error DRCoordinator__LinkPaymentIsGtLinkTotalSupply(uint96 payment, uint96 linkTotalSupply);
    error DRCoordinator__LinkTransferAndCallFailed(address to, uint96 amount, bytes encodedRequest);
    error DRCoordinator__LinkTransferFailed(address to, uint96 amount);
    error DRCoordinator__LinkTransferFromFailed(address from, address to, uint96 amount);
    error DRCoordinator__PaymentPreFeeTypeIsUnsupported(PaymentPreFeeType paymentPreFeeType);
    error DRCoordinator__PaymentTypeIsUnsupported(PaymentType paymentType);
    error DRCoordinator__RequestIsNotPending();

    /**
     * @notice Stores the essential `Spec` request data to be used by DRCoordinator when fulfilling the request.
     * @dev Size = slot0 (32) + slot1 (32) + slot2 (26) = 90 bytes
     * @member msgSender The Consumer address.
     * @member payment The LINK amount Operator holds in escrow (aka. REQUEST LINK payment).
     * @member callbackAddr The Consumer address where to fulfill the request.
     * @member fee From `Spec.fee`. The LINK amount that DRCoordinator charges Consumer when fulfilling the request.
     * It depends on the `feeType`.
     * @member consumerMaxPayment The maximum LINK amount Consumer is willing to pay for the request.
     * @member gasLimit The maximum gas amount Consumer is willing to set on the fulfillment transaction, plus the fixed
     * amount of gas DRCoordinator requires when executing the fulfillment logic.
     * @member feeType From `Spec.feeType`. The kind of `fee`; a fixed amount or a percentage of the LINK required to
     * cover the gas costs incurred.
     * @member callbackFunctionId The Consumer function signature to call when fulfilling the request.
     * @member expiration The UNIX timestamp before Consumer can cancel the unfulfilled request.
     */
    struct FulfillConfig {
        address msgSender; // 20 bytes -> slot0
        uint96 payment; // 12 bytes -> slot0
        address callbackAddr; // 20 bytes -> slot1
        uint96 fee; // 12 bytes -> slot 1
        uint96 consumerMaxPayment; // 12 bytes -> slot 2
        uint32 gasLimit; // 4 bytes -> slot2
        FeeType feeType; // 1 byte -> slot2
        bytes4 callbackFunctionId; // 4 bytes -> slot2
        uint40 expiration; // 5 bytes -> slot2
    }

    /* ========== EXTERNAL FUNCTIONS ========== */

    /**
     * @notice Allows to top-up any Consumer LINK balances.
     * @param _consumer The Consumer address.
     * @param _amount The LINK amount.
     */
    function addFunds(address _consumer, uint96 _amount) external;

    /**
     * @notice Allows Consumer to cancel an unfulfilled request.
     * @param _requestId The request ID.
     */
    function cancelRequest(bytes32 _requestId) external;

    /**
     * @notice Called by `Operator.fulfillOracleRequest2()` to fulfill requests with multi-word support.
     * @param _requestId The request ID.
     * @param _data The data to return to Consumer.
     */
    function fulfillData(bytes32 _requestId, bytes calldata _data) external;

    /**
     * @notice Called by Consumer to send a Chainlink request to Operator.
     * @dev The Chainlink request has been built by Consumer and is extended by DRCoordinator.
     * @param _operatorAddr The Operator contract address.
     * @param _callbackGasLimit The amount of gas to attach to the fulfillment transaction. It is the `gasLimit`
     * parameter of the `ethtx` task of the `direcrequest` job.
     * @param _consumerMaxPayment The maximum amount of LINK willing to pay for the request (REQUEST LINK payment +
     * SPOT LINK payment). Set it to 0 if there is no hard cap.
     * @param _req The initialized `Chainlink.Request`.
     */
    function requestData(
        address _operatorAddr,
        uint32 _callbackGasLimit,
        uint96 _consumerMaxPayment,
        Chainlink.Request memory _req
    ) external returns (bytes32);

    /**
     * @notice Allows to withdraw Consumer LINK balances.
     * @param _payee The receiver address.
     * @param _amount The LINK amount.
     */
    function withdrawFunds(address _payee, uint96 _amount) external;

    /* ========== EXTERNAL VIEW FUNCTIONS ========== */

    /**
     * @notice Returns the LINK balance for the given address.
     * @dev The LINK earned by DRCoordinator are held in its own address.
     * @param _consumer The Consumer address.
     * @return The LINK balance.
     */
    function availableFunds(address _consumer) external view returns (uint96);

    /**
     * @notice Calculates the maximum LINK amount to pay for the request (aka. MAX LINK payment amount). The amount is
     * the result of simulating the usage of all the request `callbackGasLimit` (set by Consumer) with the current
     * LINK and GASTKN prices (via Chainlink Price Feeds on the network).
     * @dev Consumer can call this method to know in advance the request MAX LINK payment and act upon it.
     * @param _weiPerUnitGas The amount of LINK per unit of GASTKN.
     * @param _paymentInEscrow The REQUEST LINK payment amount (if exists) hold in escrow by Operator.
     * @param _gasLimit The `callbackGasLimit` set by the Consumer request.
     * @param _feeType The requested `Spec.feeType`.
     * @param _fee The requested `Spec.fee`.
     * @return The LINK payment amount.
     */
    function calculateMaxPaymentAmount(
        uint256 _weiPerUnitGas,
        uint96 _paymentInEscrow,
        uint32 _gasLimit,
        FeeType _feeType,
        uint96 _fee
    ) external view returns (int256);

    /**
     * @notice Estimates the LINK amount to pay for fulfilling the request (aka. SPOT LINK payment amount). The amount
     * is the result of calculating the LINK amount used to cover the gas costs with the current
     * LINK and GASTKN prices (via Chainlink Price Feeds on the network).
     * @dev This method has limitations. It does not take into account the gas incurrend by
     * `Operator.fulfillOracleRequest2()` nor `DRCoordinator.fulfillData()`. All of them are affected, among other
     * things, by the data size and the fulfillment method logic. Therefore it is needed to fine tune `startGas`.
     * @param _weiPerUnitGas The amount of LINK per unit of GASTKN.
     * @param _paymentInEscrow The REQUEST LINK payment amount (if exists) hold in escrow by Operator.
     * @param _feeType The requested `Spec.feeType`.
     * @param _fee The requested `Spec.fee`.
     * @return The LINK payment amount.
     */
    function calculateSpotPaymentAmount(
        uint32 _startGas,
        uint256 _weiPerUnitGas,
        uint96 _paymentInEscrow,
        FeeType _feeType,
        uint96 _fee
    ) external view returns (int256);

    /**
     * @notice Returns the contract description.
     * @return The description.
     */
    function getDescription() external view returns (string memory);

    /**
     * @notice Returns wei of GASTKN per unit of LINK.
     * @dev On a single Price Feed setup the value comes from LINK / GASTKN feed.
     * @dev On a multi Price Feed setup the value comes from GASTKN / TKN and LINK / TKN feeds.
     * @dev The returned value comes from `fallbackWeiPerUnitLink` if any Price Feed is unresponsive (stale answer).
     * @dev On a L2 Sequencer dependant setup the returned value comes from `fallbackWeiPerUnitLink` if the L2
     * Sequencer Uptime Status Feed answer is not valid or has not been reported after the grace period.
     * @return The wei amount.
     */
    function getFeedData() external view returns (uint256);

    /**
     * @notice Returns the default wei of GASTKN per unit of LINK.
     * @return The wei amount.
     */
    function getFallbackWeiPerUnitLink() external view returns (uint256);

    /**
     * @notice Returns the `FulfillConfig` struct of the request.
     * @param _requestId The request ID.
     * @return The `FulfillConfig`.
     */
    function getFulfillConfig(bytes32 _requestId) external view returns (FulfillConfig memory);

    /**
     * @notice Returns whether DRCoordinator is set up to depend on a L2 Sequencer.
     * @return A boolean.
     */
    function getIsL2SequencerDependant() external view returns (bool);

    /**
     * @notice Returns whether DRCoordinator is set up to use two Price Feed to calculate the wei of GASTKN per unit of
     * LINK.
     * @return A boolean.
     */
    function getIsMultiPriceFeedDependant() external view returns (bool);

    /**
     * @notice Returns whether the DRCoordinator mutex is locked.
     * @dev The lock visibility is public to facilitate the understandment of the DRCoordinator state.
     * @return A boolean.
     */
    function getIsReentrancyLocked() external view returns (bool);

    /**
     * @notice Returns the LinkToken on the network.
     * @return The `LinkTokenInterface`.
     */
    function getLinkToken() external view returns (LinkTokenInterface);

    /**
     * @notice Returns the L2 Sequencer Uptime Status Feed address (as interface) on the network.
     * @return The `AggregatorV3Interface`.
     */
    function getL2SequencerFeed() external view returns (AggregatorV3Interface);

    /**
     * @notice Returns the number of seconds to wait before trusting the L2 Sequencer Uptime Status Feed answers.
     * @return The number of secods.
     */
    function getL2SequencerGracePeriodSeconds() external view returns (uint256);

    /**
     * @notice Returns the amount of `Spec` in DRCoordinator storage.
     * @return The amount of `Spec`.
     */
    function getNumberOfSpecs() external view returns (uint256);

    /**
     * @notice Returns the current permiryad factor that determines the maximum fee on permiryiad fee types.
     * @dev The number is multiplied by `PERMIRYAD` to calculate the `maxPeriryadFee`.
     * @return The factor.
     */
    function getPermiryadFeeFactor() external view returns (uint8);

    /**
     * @notice Returns the Price Feed 1 on the network.
     * @dev LINK / GASTKN on a single Price Feed setup.
     * @dev GASTKN / TKN on a multi Price Feed setup.
     * @return The `AggregatorV3Interface`.
     */
    function getPriceFeed1() external view returns (AggregatorV3Interface);

    /**
     * @notice Returns the Price Feed 2 on the network.
     * @dev Ignored (i.e. Zero address) on a single Price Feed setup.
     * @dev LINK / TKN on a multi Price Feed setup.
     * @return The `AggregatorV3Interface`.
     */
    function getPriceFeed2() external view returns (AggregatorV3Interface);

    /**
     * @notice Returns the number of Chainlink requests done by DRCoordinator.
     * @dev It is used to generate the Chainlink Request request ID and nonce.
     * @return The amount.
     */
    function getRequestCount() external view returns (uint256);

    /**
     * @notice Returns a `Spec` by key.
     * @param _key The `Spec` key.
     * @return The `Spec`.
     */
    function getSpec(bytes32 _key) external view returns (Spec memory);

    /**
     * @notice Returns the authorized consumer addresses (aka. requesters) by the given `Spec` (by key).
     * @param _key The `Spec` key.
     * @return The array of addresses.
     */
    function getSpecAuthorizedConsumers(bytes32 _key) external view returns (address[] memory);

    /**
     * @notice Returns the `Spec` key at the given position.
     * @dev Spec `key = keccak256(abi.encodePacked(operator, specId))`.
     * @param _index The `Spec` index.
     * @return The `Spec` key.
     */
    function getSpecKeyAtIndex(uint256 _index) external view returns (bytes32);

    /**
     * @notice Returns all the `Spec` keys.
     * @dev Spec `key = keccak256(abi.encodePacked(operator, specId))`.
     * @return The `Spec` keys array.
     */
    function getSpecMapKeys() external view returns (bytes32[] memory);

    /**
     * @notice Returns the number of seconds after which any Price Feed answer is considered stale and invalid.
     * @return The amount of seconds.
     */
    function getStalenessSeconds() external view returns (uint256);

    /**
     * @notice Returns whether Consumer (aka. requester) is authorized to request the given `Spec` (by key).
     * @param _key The `Spec` key.
     * @param _consumer The Consumer address.
     * @return A boolean.
     */
    function isSpecAuthorizedConsumer(bytes32 _key, address _consumer) external view returns (bool);

    /* ========== EXTERNAL PURE FUNCTIONS ========== */

    /**
     * @notice Returns the amount of gas needed by DRCoordinator to execute any fulfillment logic left on the
     * `fulfillData()` method after calling Consumer with the response data.
     * @return The gas units.
     */
    function getGasAfterPaymentCalculation() external pure returns (uint32);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { IDRCoordinatorCallable } from "./IDRCoordinatorCallable.sol";
import { FeeType, PaymentType, Spec } from "../libraries/internal/SpecLibrary.sol";

interface IDRCoordinator is IDRCoordinatorCallable {
    error DRCoordinator__ArrayIsEmpty(string arrayName);
    error DRCoordinator__ArrayLengthsAreNotEqual(
        string array1Name,
        uint256 array1Length,
        string array2Name,
        uint256 array2Length
    );
    error DRCoordinator__FallbackWeiPerUnitLinkIsZero();
    error DRCoordinator__L2SequencerFeedIsNotContract(address l2SequencerFeed);
    error DRCoordinator__PriceFeedIsNotContract(address priceFeedAddr);
    error DRCoordinator__SpecFieldFeeTypeIsUnsupported(bytes32 key, FeeType feeType);
    error DRCoordinator__SpecFieldFeeIsGtLinkTotalSupply(bytes32 key, uint96 fee, uint96 linkTotalSupply);
    error DRCoordinator__SpecFieldFeeIsGtMaxPermiryadFee(bytes32 key, uint96 fee, uint256 maxPermiryadFee);
    error DRCoordinator__SpecFieldGasLimitIsLtMinRequestGasLimit(
        bytes32 key,
        uint32 gasLimit,
        uint32 minRequestGasLimit
    );
    error DRCoordinator__SpecFieldOperatorIsDRCoordinator(bytes32 key, address operator);
    error DRCoordinator__SpecFieldOperatorIsNotContract(bytes32 key, address operator);
    error DRCoordinator__SpecFieldPaymentIsGtLinkTotalSupply(bytes32 key, uint96 payment, uint96 linkTotalSupply);
    error DRCoordinator__SpecFieldPaymentIsGtPermiryad(bytes32 key, uint96 payment, uint16 permiryad);
    error DRCoordinator__SpecFieldPaymentTypeIsUnsupported(bytes32 key, PaymentType paymentType);
    error DRCoordinator__SpecFieldSpecIdIsZero(bytes32 key);
    error DRCoordinator__SpecIsNotInserted(bytes32 key);

    /* ========== EXTERNAL FUNCTIONS ========== */

    /**
     * @notice Authorizes consumer addresses on the given `Spec` (by key).
     * @param _key The `Spec` key.
     * @param _authConsumers The array of consumer addresses.
     */
    function addSpecAuthorizedConsumers(bytes32 _key, address[] calldata _authConsumers) external;

    /**
     * @notice Authorizes consumer addresses on the given specs (by keys).
     * @param _keys The array of `Spec` keys.
     * @param _authConsumersArray The array of consumer addresses (per `Spec`).
     */
    function addSpecsAuthorizedConsumers(bytes32[] calldata _keys, address[][] calldata _authConsumersArray) external;

    /**
     * @notice Pauses DRCoordinator.
     */
    function pause() external;

    /**
     * @notice Withdrawns authorization for consumer addresses on the given `Spec` (by key).
     * @param _key The `Spec` key.
     * @param _authConsumers The array of consumer addresses.
     */
    function removeSpecAuthorizedConsumers(bytes32 _key, address[] calldata _authConsumers) external;

    /**
     * @notice Withdrawns authorization for consumer addresses on the given specs (by keys).
     * @param _keys The array of `Spec` keys.
     * @param _authConsumersArray The array of consumer addresses (per `Spec`).
     */
    function removeSpecsAuthorizedConsumers(bytes32[] calldata _keys, address[][] calldata _authConsumersArray)
        external;

    /**
     * @notice Removes a `Spec` by key.
     * @param _key The `Spec` key.
     */
    function removeSpec(bytes32 _key) external;

    /**
     * @notice Removes specs by keys.
     * @param _keys The array of `Spec` keys.
     */
    function removeSpecs(bytes32[] calldata _keys) external;

    /**
     * @notice Sets the DRCoordinator description.
     * @param _description The explanation.
     */
    function setDescription(string calldata _description) external;

    /**
     * @notice Sets the fallback amount of GASTKN wei per unit of LINK.
     * @dev This amount is used when any Price Feed answer is stale, or the L2 Sequencer Uptime Status Feed is down, or
     * its answer has been reported before the grace period.
     * @param _fallbackWeiPerUnitLink The wei amount.
     */
    function setFallbackWeiPerUnitLink(uint256 _fallbackWeiPerUnitLink) external;

    /**
     * @notice Sets the number of seconds to wait before trusting the L2 Sequencer Uptime Status Feed answer.
     * @param _l2SequencerGracePeriodSeconds The number of seconds.
     */
    function setL2SequencerGracePeriodSeconds(uint256 _l2SequencerGracePeriodSeconds) external;

    /**
     * @notice Sets the permiryad factor (1 by default).
     * @dev Allows to bump the fee percentage above 100%.
     * @param _permiryadFactor The factor.
     */
    function setPermiryadFeeFactor(uint8 _permiryadFactor) external;

    /**
     * @notice Sets a `Spec` by key.
     * @param _key The `Spec` key.
     * @param _spec The Spec` tuple.
     */
    function setSpec(bytes32 _key, Spec calldata _spec) external;

    /**
     * @notice Sets specs by keys.
     * @param _keys The array of `Spec` keys.
     * @param _specs The array of `Spec` tuples.
     */
    function setSpecs(bytes32[] calldata _keys, Spec[] calldata _specs) external;

    /**
     * @notice Sets the number of seconds after which any Price Feed answer is considered stale and invalid.
     * @param _stalenessSeconds The number of seconds.
     */
    function setStalenessSeconds(uint256 _stalenessSeconds) external;

    /**
     * @notice Unpauses DRCoordinator.
     */
    function unpause() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @notice Contract writers can inherit this contract in order to fulfill requests built in a different contract
 * (aka Chainlink external request).
 * @dev See docs: https://docs.chain.link/docs/any-api/api-reference/#addchainlinkexternalrequest
 */
interface IChainlinkExternalFulfillment {
    /**
     * @notice Track unfulfilled requests that the contract hasn't created itself.
     * @param _msgSender The Operator address expected to make the fulfillment tx.
     * @param _requestId The request ID.
     */
    function setExternalPendingRequest(address _msgSender, bytes32 _requestId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title The InsertedAddressLibrary library.
 * @author Víctor Navascués.
 * @notice An iterable mapping library for addresses. Useful to either grant or revoke by address whilst keeping track
 * of them.
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
pragma solidity 0.8.17;

enum FeeType {
    FLAT, // A fixed LINK amount
    PERMIRYAD // A dynamic LINK amount (a percentage of the `paymentPreFee`)
}

enum PaymentType {
    FLAT, // A fixed LINK amount
    PERMIRYAD // A dynamic LINK amount (a percentage of the MAX LINK payment)
}

/**
 * @notice The representation of a `directrequest` job spec for DRCoordinator requests. Composed of `directrequest`
 * spec unique fields (e.g. `specId`, `operator`) DRCoordinator specific variables to address the LINK payment, e.g.
 * `fee`, `feeType`, etc.
 * @dev Size = slot0 (32) + slot1 (32) + slot2 (18) = 82 bytes
 * @member specId The `externalJobID` (UUIDv4) as bytes32.
 * @member operator The Operator address.
 * @member payment The LINK amount that Consumer pays to Operator when requesting the job (and to be hold in escrow).
 * It depends on the `paymentType`.
 * @member paymentType The kind of `payment`; a fixed amount or a percentage of the LINK required to cover the gas costs
 * if all the `gasLimit` was used (aka. MAX LINK payment).
 * @member fee The LINK amount that DRCoordinator charges Consumer when fulfilling the request. It depends on the
 * `feeType`.
 * @member feeType The kind of `fee`; a fixed amount or a percentage of the LINK required to cover the gas costs
 * incurred.
 * @member gasLimit The amount of gas to attach to the transaction (via `gasLimit` parameter on the `ethtx` task of the
 * `directrequest` job).
 */
struct Spec {
    bytes32 specId; // 32 bytes -> slot0
    address operator; // 20 bytes -> slot1
    uint96 payment; // 1e27 < 2^96 = 12 bytes -> slot1
    PaymentType paymentType; // 1 byte -> slot2
    uint96 fee; // 1e27 < 2^96 = 12 bytes -> slot2
    FeeType feeType; // 1 byte -> slot2
    uint32 gasLimit; // < 4.295 billion = 4 bytes -> slot2
}

/**
 * @title The SpecLibrary library.
 * @author Víctor Navascués.
 * @notice An iterable mapping library for Spec.
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

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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