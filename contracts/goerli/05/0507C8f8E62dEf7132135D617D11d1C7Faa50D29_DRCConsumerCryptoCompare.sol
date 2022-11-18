// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Chainlink, DRCoordinatorClient, IDRCoordinator } from "../DRCoordinatorClient.sol";

contract DRCConsumerCryptoCompare is DRCoordinatorClient {
    using Chainlink for Chainlink.Request;

    struct PriceData3 {
        uint256 btc;
        uint256 eth;
        uint256 link;
    }

    struct PriceData6 {
        uint256 btc;
        uint256 eth;
        uint256 link;
        uint256 matic;
        uint256 aave;
        uint256 snx;
    }

    mapping(bytes32 => uint256) public requestIdToPriceData1;
    mapping(bytes32 => PriceData3) public requestIdToPriceData3;
    mapping(bytes32 => PriceData6) public requestIdToPriceData6;

    error LinkTransferFailed(address to, uint256 amount);

    event FundsWithdrawn(address payee, uint256 amount);

    constructor(address _linkAddr, address _drCoordinatorAddr) {
        _setLink(_linkAddr);
        _setDRCoordinator(_drCoordinatorAddr);
    }

    /* ========== EXTERNAL FUNCTIONS ========== */

    function cancelRequest(bytes32 _requestId) external {
        s_drCoordinator.cancelRequest(_requestId);
    }

    // Function signature: d276286e
    function fulfillPriceData1(bytes32 _requestId, uint256 _link) external recordFulfillment(_requestId) {
        requestIdToPriceData1[_requestId] = _link;
    }

    // Function signature: 3551fb7a
    function fulfillPriceData3(
        bytes32 _requestId,
        uint256 _btc,
        uint256 _eth,
        uint256 _link
    ) external recordFulfillment(_requestId) {
        PriceData3 memory priceData3 = PriceData3(_btc, _eth, _link);
        requestIdToPriceData3[_requestId] = priceData3;
    }

    // Function signature: ea4ed058
    function fulfillPriceData6(
        bytes32 _requestId,
        uint256 _btc,
        uint256 _eth,
        uint256 _link,
        uint256 _matic,
        uint256 _aave,
        uint256 _snx
    ) external recordFulfillment(_requestId) {
        PriceData6 memory priceData6 = PriceData6(_btc, _eth, _link, _matic, _aave, _snx);
        requestIdToPriceData6[_requestId] = priceData6;
    }

    function requestPrices(
        address _operatorAddr,
        bytes32 _specId,
        uint32 _callbackGasLimit,
        uint96 _consumerMaxPayment,
        bytes4 _callbackFunctionId
    ) external {
        Chainlink.Request memory req = _buildRequest(_specId, address(this), _callbackFunctionId);
        _sendRequest(_operatorAddr, _callbackGasLimit, _consumerMaxPayment, req);
    }

    function setDRCoordinator(address _drCoordinator) external {
        _setDRCoordinator(_drCoordinator);
    }

    function withdraw(address _payee, uint256 _amount) external {
        emit FundsWithdrawn(_payee, _amount);
        _requireLinkTransfer(s_link.transfer(_payee, _amount), _payee, _amount);
    }

    function withdrawFunds(address _payee, uint96 _amount) external {
        s_drCoordinator.withdrawFunds(_payee, _amount);
    }

    /* ========== EXTERNAL VIEW FUNCTIONS ========== */

    function getPriceData1(bytes32 _requestId) external view returns (uint256) {
        return requestIdToPriceData1[_requestId];
    }

    function getPriceData3(bytes32 _requestId) external view returns (PriceData3 memory) {
        return requestIdToPriceData3[_requestId];
    }

    function getPriceData6(bytes32 _requestId) external view returns (PriceData6 memory) {
        return requestIdToPriceData6[_requestId];
    }

    /* ========== PRIVATE PURE FUNCTIONS ========== */

    function _requireLinkTransfer(
        bool _success,
        address _to,
        uint256 _amount
    ) private pure {
        if (!_success) {
            revert LinkTransferFailed(_to, _amount);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Chainlink } from "@chainlink/contracts/src/v0.8/Chainlink.sol";
import { LinkTokenInterface } from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import { IDRCoordinatorCallable as IDRCoordinator } from "./interfaces/IDRCoordinatorCallable.sol";
import { ChainlinkFulfillment } from "./ChainlinkFulfillment.sol";

/**
 * @title The DRCoordinatorClient contract.
 * @author Víctor Navascués.
 * @notice Contract writers can inherit this contract in order to create requests for the Chainlink network via a
 * DRCoordinator contract.
 * @dev Uses @chainlink/contracts 0.5.1.
 * @dev Like a standard ChainlinkClient it builds and sends a Chainlink request. The difference between a
 * ChainlinkClient and a DRCoordinatorClient is that the former sends the Chainlink.Request to the Operator contract
 * attached in the LINK token via LINK.transferAndCall(), whilst the latter does not transfer LINK to the DRCoordinator
 * contract.
 */
contract DRCoordinatorClient is ChainlinkFulfillment {
    using Chainlink for Chainlink.Request;

    LinkTokenInterface internal s_link;
    IDRCoordinator internal s_drCoordinator;

    event ChainlinkCancelled(bytes32 indexed id);
    event ChainlinkRequested(bytes32 indexed id);

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @notice Allows a request to be cancelled if it has not been fulfilled.
     * @dev Cancelling a DRCoordinator request does not require to keep track of the expiration value (which equals
     * 5 minutes + block.timestamp) set & emitted by the operator contract due to it is stored.
     * @dev Calls IDRcoordinatior.cancelRequest().
     * @dev Deletes the request from the s_pendingRequests mapping.
     * @dev Emits the ChainlinkCancelled event.
     * @param _requestId The request ID.
     */
    function _cancelRequest(bytes32 _requestId) internal {
        IDRCoordinator drCoordinator = IDRCoordinator(s_pendingRequests[_requestId]);
        delete s_pendingRequests[_requestId];
        emit ChainlinkCancelled(_requestId);
        drCoordinator.cancelRequest(_requestId);
    }

    /**
     * @notice Sends a Chainlink request along with the other directrequest data to the stored DRCoordinator.
     * @dev This function supports multi-word response (Operator.operatorRequest() compatible).
     * @dev Calls sendDRCoordinatorRequestTo() with the stored DRCoordinator contract interface.
     * @dev It does not involve LINK.transferAndCall().
     * @param _operatorAddr The Operator contract address.
     * @param _callbackGasLimit The amount of gas to attach to the fulfillment transaction. It is the `gasLimit`
     * parameter of the `ethtx` task of the `direcrequest` job.
     * @param _consumerMaxPayment The maximum amount of LINK willing to pay for the request (initial payment +
     * fulfill payment). Set it to 0 if there is no hard cap.
     * @param _req The initialized Chainlink.Request.
     * @return requestId The request ID.
     */
    function _sendRequest(
        address _operatorAddr,
        uint32 _callbackGasLimit,
        uint96 _consumerMaxPayment,
        Chainlink.Request memory _req
    ) internal returns (bytes32) {
        return _sendRequestTo(s_drCoordinator, _operatorAddr, _callbackGasLimit, _consumerMaxPayment, _req);
    }

    /**
     * @notice Sends a Chainlink request along with the other directrequest data to the DRCoordinator.
     * @dev This function supports multi-word response (Operator.operatorRequest() compatible).
     * @dev Calls IDRCoordinator.requestData(), which emits the ChainlinkRequested event.
     * @dev It does not involve LINK.transferAndCall().
     * @dev Emits the ChainlinkRequested event.
     * @param _drCoordinator The DRCoordinator contract interface.
     * @param _operatorAddr The Operator contract address.
     * @param _callbackGasLimit The amount of gas to attach to directrequest fulfillment transaction. It is the gasLimit
     * parameter of the directrequest ethtx task.
     * @param _consumerMaxPayment The maximum amount of LINK willing to pay for the request (initial payment +
     * fulfill payment). Set it to 0 if there is no hard cap.
     * @param _req The initialized Chainlink.Request.
     * @return requestId The request ID.
     */
    function _sendRequestTo(
        IDRCoordinator _drCoordinator,
        address _operatorAddr,
        uint32 _callbackGasLimit,
        uint96 _consumerMaxPayment,
        Chainlink.Request memory _req
    ) internal returns (bytes32) {
        bytes32 requestId = _drCoordinator.requestData(_operatorAddr, _callbackGasLimit, _consumerMaxPayment, _req);
        _addPendingRequest(address(_drCoordinator), requestId);
        emit ChainlinkRequested(requestId);
        return requestId;
    }

    /**
     * @notice Sets the stored DRCoordinator contract address.
     * @param _drCoordinatorAddr The DRCoordinator contract address.
     */
    function _setDRCoordinator(address _drCoordinatorAddr) internal {
        s_drCoordinator = IDRCoordinator(_drCoordinatorAddr);
    }

    /**
     * @notice Sets the stored LinkToken contract address.
     * @param _linkAddr The LINK token contract address.
     */
    function _setLink(address _linkAddr) internal {
        s_link = LinkTokenInterface(_linkAddr);
    }

    /* ========== INTERNAL PURE FUNCTIONS ========== */

    /**
     * @notice Creates a Chainlink request which contains this function arguments and that can hold additional
     * parameters.
     * @dev DRCoordinator supports requests where the requester contract is not the fulfillment contract;
     * address(this) != _callbackAddr, known as well as external requests.
     * @param _specId The directrequest Job Spec ID (externalJobID parameter) that the request will be created for.
     * @param _callbackAddr The contract address where to fulfill the request.
     * @param _callbackFunctionId The _callbackAddr function selector to call when fulfilling the request.
     * @return A Chainlink Request struct in memory.
     */
    function _buildRequest(
        bytes32 _specId,
        address _callbackAddr,
        bytes4 _callbackFunctionId
    ) internal pure returns (Chainlink.Request memory) {
        Chainlink.Request memory req;
        return req.initialize(_specId, _callbackAddr, _callbackFunctionId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title The ChainlinkFulfillment contract.
 * @author Víctor Navascués.
 * @notice Contract writers can inherit this contract to fulfill Chainlink requests.
 * @dev Uses @chainlink/contracts 0.5.1.
 */
contract ChainlinkFulfillment {
    mapping(bytes32 => address) internal s_pendingRequests;

    error ChainlinkFulfillment__CallerIsNotRequester(address msgSender);
    error ChainlinkFulfillment__RequestIsPending(bytes32 requestId);

    event ChainlinkFulfilled(bytes32 indexed id);

    /* ========== MODIFIERS ========== */

    /**
     * @dev Reverts if the request is already pending (value is a contract address).
     * @param _requestId The request ID for fulfillment.
     */
    modifier notPendingRequest(bytes32 _requestId) {
        _requireRequestIsNotPending(_requestId);
        _;
    }

    /**
     * @dev Reverts if the sender is not the DRCoordinator.
     * @dev Emits the ChainlinkFulfilled event.
     * @param _requestId The request ID for fulfillment.
     */
    modifier recordFulfillment(bytes32 _requestId) {
        _recordFulfillment(_requestId);
        _;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @notice Allows for a Chainlink request to be fulfilled on this contract.
     * @dev Maps the request ID with the contract address in charge of fulfilling the request.
     * @param _msgSender The address of the contract that will fulfill the request.
     * @param _requestId The request ID used for the response.
     */
    function _addPendingRequest(address _msgSender, bytes32 _requestId) internal notPendingRequest(_requestId) {
        s_pendingRequests[_requestId] = _msgSender;
    }

    /**
     * @notice Validates the request fulfillment data (requestId and sender), protecting Chainlink client callbacks from
     * being called by malicious callers.
     * @dev Reverts if the caller is not the original request sender.
     * @dev Emits the ChainlinkFulfilled event.
     * @param _requestId The request ID for fulfillment.
     */
    function _recordFulfillment(bytes32 _requestId) internal {
        address msgSender = s_pendingRequests[_requestId];
        if (msg.sender != msgSender) {
            revert ChainlinkFulfillment__CallerIsNotRequester(msgSender);
        }
        delete s_pendingRequests[_requestId];
        emit ChainlinkFulfilled(_requestId);
    }

    /* ========== INTERNAL VIEW FUNCTIONS ========== */

    /**
     * @notice Validates the request is not pending (it hasn't been fulfilled yet, or it just does not exist).
     * @dev Reverts if the request is pending (value is a non-zero contract address).
     * @param _requestId The request ID for fulfillment.
     */
    function _requireRequestIsNotPending(bytes32 _requestId) internal view {
        if (s_pendingRequests[_requestId] != address(0)) {
            revert ChainlinkFulfillment__RequestIsPending(_requestId);
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