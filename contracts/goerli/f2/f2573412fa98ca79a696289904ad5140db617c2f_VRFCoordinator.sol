// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VRFBeaconBilling} from "./VRFBeaconBilling.sol";
import {IVRFCoordinatorExternalAPI} from "./IVRFCoordinatorExternalAPI.sol";
import {IVRFCoordinatorConsumer} from "./IVRFCoordinatorConsumer.sol";
import {IVRFCoordinatorProducerAPI} from "./IVRFCoordinatorProducerAPI.sol";
import {ChainSpecificUtil} from "./ChainSpecificUtil.sol";

////////////////////////////////////////////////////////////////////////////////
/// @title Tracks VRF Beacon randomness requests
///
/// @notice Call `requestRandomness` to register retrieval of randomness from
/// @notice the next beacon output, then call `redeemRandomness` with the RequestID
/// @notice returned by `requestRandomness`
///
/// @dev This is intended as a superclass for the VRF Beacon contract,
/// @dev containing the logic for processing and responding to randomness
/// @dev requests
contract VRFCoordinator is
    IVRFCoordinatorExternalAPI,
    IVRFCoordinatorProducerAPI,
    VRFBeaconBilling
{
    /// @notice Max length of array returned from redeemRandomness
    uint256 public constant maxNumWords = 1000;

    /// @dev producer is responsible for writing VRF outputs to the coordinator
    /// @dev producer is the only allowed caller for IVRFCoordinatorExternalAPI
    address public producer;

    /// @inheritdoc IVRFCoordinatorExternalAPI
    function requestRandomness(
        uint16 numWords,
        uint64 subID,
        ConfirmationDelay confirmationDelayArg
    ) external override returns (RequestID) {
        (
            RequestID nonce,
            BeaconRequest memory r,
            uint64 nextBeaconOutputHeight
        ) = beaconRequest(numWords, confirmationDelayArg);
        address requester = msg.sender;
        billSubscriberForRequest(requester, subID); // throws on failure
        s_pendingRequests[nonce] = r;
        s_subscriptions[subID].reqCount++;
        emit RandomnessRequested(
            nonce,
            requester,
            nextBeaconOutputHeight,
            confirmationDelayArg,
            subID,
            numWords
        );
        return nonce;
    }

    /// @inheritdoc IVRFCoordinatorExternalAPI
    function requestRandomnessFulfillment(
        uint64 subID,
        uint16 numWords,
        ConfirmationDelay confirmationDelayArg,
        uint32 callbackGasLimit,
        bytes memory arguments
    ) external override returns (RequestID) {
        (
            RequestID requestID, // BeaconRequest. We do not store this, because we trust the committee
            ,
            // to only sign off on reports containing valid fulfillment requests
            uint64 nextBeaconOutputHeight
        ) = beaconRequest(numWords, confirmationDelayArg);
        uint256 weiPerUnitLink = getFeedData();
        Callback memory callback = Callback({
            requestID: requestID,
            numWords: numWords,
            requester: msg.sender,
            arguments: arguments,
            subID: subID,
            gasAllowance: callbackGasLimit,
            gasPrice: tx.gasprice,
            weiPerUnitLink: weiPerUnitLink
        });
        billSubscriberForCallback(callback); // throws on failure
        // Record the callback so that it can only be played once. This is checked
        // in VRFBeaconReport.processCallback, and the entry is then deleted
        s_callbackMemo[requestID] = keccak256(
            abi.encode(
                nextBeaconOutputHeight,
                confirmationDelayArg,
                subID,
                callback
            )
        );
        s_subscriptions[subID].reqCount++;
        emit RandomnessFulfillmentRequested(
            requestID,
            msg.sender,
            nextBeaconOutputHeight,
            confirmationDelayArg,
            subID,
            numWords,
            callbackGasLimit,
            tx.gasprice,
            weiPerUnitLink,
            arguments
        );
        return requestID;
    }

    // Used to track pending callbacks by their keccak256 hash
    mapping(RequestID => bytes32) internal s_callbackMemo;

    /// @inheritdoc IVRFCoordinatorExternalAPI
    function redeemRandomness(RequestID requestID)
        public
        override
        returns (uint256[] memory randomness)
    {
        // No billing logic required here. Callback-free requests are paid up-front
        // and only registered if fully paid.
        BeaconRequest memory r = s_pendingRequests[requestID];
        delete s_pendingRequests[requestID]; // save gas, prevent re-entrancy
        if (r.requester != msg.sender) {
            revert ResponseMustBeRetrievedByRequester(r.requester, msg.sender);
        }
        uint256 blockHeight = SlotNumber.unwrap(r.slotNumber) *
            i_beaconPeriodBlocks;
        uint256 blockNumber = ChainSpecificUtil.getBlockNumber();
        uint256 confThreshold = blockNumber -
            ConfirmationDelay.unwrap(r.confirmationDelay);
        if (blockHeight >= confThreshold) {
            revert BlockTooRecent(
                blockHeight,
                blockHeight + ConfirmationDelay.unwrap(r.confirmationDelay) + 1
            );
        }
        if (blockHeight > type(uint64).max) {
            revert UniverseHasEndedBangBangBang(blockHeight);
        }
        return
            finalOutput(
                requestID,
                r,
                s_seedByBlockHeight[blockHeight][r.confirmationDelay],
                uint64(blockHeight)
            );
    }

    struct Config {
        uint16 minimumRequestConfirmations;
        uint32 maxGasLimit;
        // stalenessSeconds is how long before we consider the feed price to be stale
        // and fallback to fallbackWeiPerUnitLink.
        uint32 stalenessSeconds;
        // Gas to cover oracle payment after we calculate the payment.
        // We make it configurable in case those operations are repriced.
        uint32 gasAfterPaymentCalculation;
    }
    Config private s_config;

    /// @notice Emitted when the recentBlockHash is older than some of the VRF
    /// @notice outputs it's being used to sign.
    ///
    /// @param reportHeight height of the VRF output which is younger than the recentBlockHash
    /// @param separatorHeight recentBlockHeight in the report
    error HistoryDomainSeparatorTooOld(
        uint64 reportHeight,
        uint64 separatorHeight
    );

    /// @dev Stores the VRF outputs received so far, indexed by the block heights
    /// @dev they're associated with
    mapping(uint256 => mapping(ConfirmationDelay => bytes32)) s_seedByBlockHeight; /* block height */ /* seed */

    function setProducer(address addr) external onlyOwner {
        producer = addr;
    }

    modifier onlyProducer() {
        require(msg.sender == producer, "call setProducer");
        _;
    }

    /// @inheritdoc IVRFCoordinatorProducerAPI
    function processVRFOutputs(
        VRFOutput[] calldata vrfOutputs,
        uint192 juelsPerFeeCoin,
        uint64 blockHeight,
        bytes32 /* blockHash */
    ) external override onlyProducer returns (OutputServed[] memory outputs) {
        uint16 numOutputs;
        OutputServed[] memory outputsServedFull = new OutputServed[](
            vrfOutputs.length
        );
        for (uint256 i = 0; i < vrfOutputs.length; i++) {
            VRFOutput memory r = vrfOutputs[i];
            processVRFOutput(r, blockHeight, juelsPerFeeCoin);
            if (r.vrfOutput.p[0] != 0 || r.vrfOutput.p[1] != 0) {
                outputsServedFull[i] = OutputServed({
                    height: r.blockHeight,
                    confirmationDelay: r.confirmationDelay,
                    proofG1X: r.vrfOutput.p[0],
                    proofG1Y: r.vrfOutput.p[1]
                });
                numOutputs++;
            }
        }
        OutputServed[] memory outputsServed = new OutputServed[](numOutputs);
        for (uint256 i = 0; i < numOutputs; i++) {
            // truncate heights
            outputsServed[i] = outputsServedFull[i];
        }
        emit OutputsServed(
            blockHeight,
            msg.sender,
            juelsPerFeeCoin,
            outputsServed
        );
        return outputsServed;
    }

    function processVRFOutput(
        // extracted to deal with stack-depth issue
        VRFOutput memory output,
        uint64 blockHeight,
        uint192 /* juelsPerFeeCoin */
    ) internal {
        if (output.blockHeight > blockHeight) {
            revert HistoryDomainSeparatorTooOld(
                blockHeight,
                output.blockHeight
            );
        }
        bytes32 seed;
        if (output.vrfOutput.p[0] == 0 && output.vrfOutput.p[1] == 0) {
            // We trust the committee to only sign off on reports with blank VRF
            // outputs for heights where the output already exists onchain.
            seed = s_seedByBlockHeight[output.blockHeight][
                output.confirmationDelay
            ];
        } else {
            // We trust the committee to only sign off on reports with valid VRF
            // proofs
            seed = keccak256(abi.encode(output.vrfOutput));
            s_seedByBlockHeight[output.blockHeight][
                output.confirmationDelay
            ] = seed;
        }
        uint256 numCallbacks = output.callbacks.length;
        RequestID[] memory fulfilledRequests = new RequestID[](numCallbacks);
        bytes memory successfulFulfillment = new bytes(numCallbacks);
        bytes[] memory errorData = new bytes[](numCallbacks);
        uint16 errorCount = 0;
        for (uint256 j = 0; j < numCallbacks; j++) {
            // We trust the committee to only sign off on reports with valid,
            // requested callbacks.
            CostedCallback memory callback = output.callbacks[j];
            (bool isErr, bytes memory errmsg) = processCallback(
                output.blockHeight,
                output.confirmationDelay,
                seed,
                callback
            );
            if (isErr) {
                errorData[errorCount] = errmsg;
                errorCount++;
            } else {
                successfulFulfillment[j] = bytes1(uint8(1)); // succeeded
            }
            fulfilledRequests[j] = callback.callback.requestID;
        }

        if (output.callbacks.length > 0) {
            bytes[] memory truncatedErrorData = new bytes[](errorCount);
            for (uint256 j = 0; j < errorCount; j++) {
                truncatedErrorData[j] = errorData[j];
            }
            emit RandomWordsFulfilled(
                fulfilledRequests,
                successfulFulfillment,
                truncatedErrorData
            );
        }
    }

    function processCallback(
        // extracted to deal with stack-depth issue
        uint64 blockHeight,
        ConfirmationDelay confDelay,
        bytes32 seed,
        CostedCallback memory c
    ) internal returns (bool isErr, bytes memory errmsg) {
        // We trust the committee to only sign off on reports with valid beacon
        // heights which are small enough to fit in a SlotNumber.
        SlotNumber slotNum = SlotNumber.wrap(
            uint32(blockHeight / i_beaconPeriodBlocks)
        );
        Callback memory cb = c.callback;
        bytes32 cbCommitment = keccak256(
            abi.encode(blockHeight, confDelay, cb.subID, cb)
        );
        if (cbCommitment != s_callbackMemo[cb.requestID]) {
            return (true, "unknown callback");
        }
        if (!subscriptionExists(cb.subID)) {
            delete s_callbackMemo[cb.requestID];
            return (true, "subscription cancelled");
        }
        BeaconRequest memory request = BeaconRequest({
            slotNumber: slotNum,
            confirmationDelay: confDelay,
            numWords: cb.numWords,
            requester: cb.requester
        });
        uint256[] memory fOutput = finalOutput(
            cb.requestID,
            request,
            seed,
            blockHeight
        );
        IVRFCoordinatorConsumer consumer = IVRFCoordinatorConsumer(
            request.requester
        );
        bytes memory resp = abi.encodeWithSelector(
            consumer.rawFulfillRandomWords.selector,
            cb.requestID,
            fOutput,
            cb.arguments
        );
        s_reentrancyLock = true;
        bool success;
        bool sufficientGas;
        uint256 gasBefore = gasleft();
        (success, sufficientGas) = callWithExactGasEvenIfTargetIsNoContract(
            c.callback.gasAllowance,
            cb.requester,
            resp
        );
        require(sufficientGas, "insufficient gas");
        // Refund the user, excluding the gas used in the exact gas call check.
        // Ensure that more than CALL_WITH_EXACT_GAS_CUSHION was used to prevent an
        // underflow.
        uint256 gasAfter = gasleft() + CALL_WITH_EXACT_GAS_CUSHION;
        s_reentrancyLock = false;
        if (gasAfter < gasBefore) {
            refundCallback(gasBefore - gasAfter, c.callback);
        }

        // Delete callback memo and return result of the callback.
        delete s_callbackMemo[cb.requestID];
        // if the required method code is missing in the target or if
        // the target is non-contract, we still return success (we don't care
        // about false success in this case).
        return success ? (false, bytes("")) : (true, bytes("execution failed"));
    }

    uint256 private constant CALL_WITH_EXACT_GAS_CUSHION = 5_000;

    /**
     * @dev calls target address with exactly gasAmount gas and data as calldata
     * or reverts if at least gasAmount gas is not available.
     */
    function callWithExactGasEvenIfTargetIsNoContract(
        uint256 _gasAmount,
        address _target,
        bytes memory _data
    ) private returns (bool success, bool sufficientGas) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let g := gas()
            // Compute g -= CALL_WITH_EXACT_GAS_CUSHION and check for underflow. We
            // need the cushion since the logic following the above call to gas also
            // costs gas which we cannot account for exactly. So cushion is a
            // conservative upper bound for the cost of this logic.
            if iszero(lt(g, CALL_WITH_EXACT_GAS_CUSHION)) {
                // i.e., g >= CALL_WITH_EXACT_GAS_CUSHION
                g := sub(g, CALL_WITH_EXACT_GAS_CUSHION)
                // If g - g//64 <= _gasAmount, we don't have enough gas. (We subtract g//64
                // because of EIP-150.)
                if gt(sub(g, div(g, 64)), _gasAmount) {
                    // Call and receive the result of call. Note that we did not check
                    // whether a contract actually exists at the _target address.
                    success := call(
                        _gasAmount, // gas
                        _target, // address of target contract
                        0, // value
                        add(_data, 0x20), // inputs
                        mload(_data), // inputs size
                        0, // outputs
                        0 // outputs size
                    )
                    sufficientGas := true
                }
            }
        }
    }

    //////////////////////////////////////////////////////////////////////////////
    // Errors emitted by the above functions

    /// @notice Emitted when too many random words requested in requestRandomness
    /// @param requested number of words requested, which was too large
    /// @param max, largest number of words which can be requested
    error TooManyWords(uint256 requested, uint256 max);

    /// @notice Emitted when zero random words requested in requestRandomness
    error NoWordsRequested();

    /// @notice Emitted when slot number cannot be represented in given int size,
    /// @notice indicating that the contract must be replaced with new
    /// @notice slot-processing logic. (Should not be an issue before the year
    /// @notice 4,000 A.D.)
    error TooManySlotsReplaceContract();

    /// @notice Emitted when number of requests cannot be represented in given int
    /// @notice size, indicating that the contract must be replaced with new
    /// @notice request-nonce logic.
    error TooManyRequestsReplaceContract();

    /// @notice Emitted when redeemRandomness is called by an address which does not
    /// @notice match the original requester's
    /// @param expected the  address which is allowed to retrieve the randomness
    /// @param actual the addres which tried to retrieve the randomness
    error ResponseMustBeRetrievedByRequester(address expected, address actual);

    /// @notice Emitted when redeemRandomness is called for a block which is too
    /// @notice recent to regard as committed.
    /// @param requestHeight the height of the block with the attempted retrieval
    /// @param earliestAllowed the lowest height at which retrieval is allowed
    error BlockTooRecent(uint256 requestHeight, uint256 earliestAllowed);

    /// @notice Emitted when redeemRandomness is called for a block where the seed
    /// @notice has not yet been provided.
    /// @param requestID the request for which retrieval was attempted
    /// @param requestHeight the block height at which retrieval was attempted
    error RandomnessNotAvailable(RequestID requestID, uint256 requestHeight);

    /// @notice Shortest possible confirmation delay.
    /// @dev Note that this is NOT an adequate value for most chains!!!
    uint16 public constant minDelay = 3;

    /// @param beaconPeriodBlocksArg number of blocks between beacon outputs
    ///
    /// @dev Confirmation delays must be at least minDelay, increasing, until the
    /// @dev first zero
    constructor(
        uint256 beaconPeriodBlocksArg,
        address linkToken,
        address linkEthFeed
    ) VRFBeaconBilling(linkToken, linkEthFeed) {
        if (beaconPeriodBlocksArg == 0) {
            revert BeaconPeriodMustBePositive();
        }
        i_beaconPeriodBlocks = beaconPeriodBlocksArg;

        // i_StartSlot = next block with height divisible by period ("slot")
        uint256 blockNumber = ChainSpecificUtil.getBlockNumber();
        uint256 blocksSinceLastSlot = blockNumber % i_beaconPeriodBlocks;
        uint256 blocksToNextSlot = i_beaconPeriodBlocks - blocksSinceLastSlot;
        i_StartSlot = blockNumber + blocksToNextSlot;
    }

    /// @notice Emitted when beaconPeriodBlocksArg is zero
    error BeaconPeriodMustBePositive();

    /// @notice Emitted when the blockHeight doesn't fit in uint64
    error UniverseHasEndedBangBangBang(uint256 blockHeight);

    /// @notice Emitted when the first confirmation delay is below the minimum
    error ConfirmationDelayBlocksTooShort(uint16 firstDelay, uint16 minDelay);

    /// @notice Emitted when nonzero confirmation delays are not increasing
    error ConfirmationDelaysNotIncreasing(
        uint16[10] confirmationDelays,
        uint8 violatingIndex
    );

    /// @notice Emitted when nonzero conf delay follows zero conf delay
    error NonZeroDelayAfterZeroDelay(uint16[10] confDelays);

    /// @dev A VRF output is provided whenever
    /// @dev blockHeight % i_beaconPeriodBlocks == 0
    uint256 public immutable i_beaconPeriodBlocks;

    /// @dev First slot for which randomness should be provided. Offchain system
    /// @dev uses this, plus NewHead and SeedProvided, events to determine which
    /// @dev blocks currently require an answer. (NewHead is used to invalidate
    /// @dev slots which follow the current head, in the case of a re-org.)
    uint256 public immutable i_StartSlot;

    /* XXX: Check that this really fits into a word. Does the compiler do the
     right thing with a custom type like ConfirmationDelay? */
    struct RequestParams {
        /// @dev Incremented on each new request; used to disambiguate requests. We
        /// @dev can use a single nonce for all requests with no compromise to
        /// @dev security, because an adversary gains no predictable control over a
        /// @dev target by incrementing this value with interleaving requests.
        RequestID requestID;
        ConfirmationDelay[NUM_CONF_DELAYS] confirmationDelays;

        // Use extra 16 bits to specify a premium? /* XXX:  */
    }

    RequestParams s_requestParams;

    mapping(RequestID => BeaconRequest) s_pendingRequests;

    /// returns the information common to both types of requests: The requestID,
    /// the BeaconRequest data, and the height of the VRF output
    function beaconRequest(
        uint16 numWords,
        ConfirmationDelay confirmationDelayArg
    )
        internal
        returns (
            RequestID,
            BeaconRequest memory,
            uint64
        )
    {
        if (numWords > maxNumWords) {
            revert TooManyWords(numWords, maxNumWords);
        }
        if (numWords == 0) {
            revert NoWordsRequested();
        }
        uint256 blockNumber = ChainSpecificUtil.getBlockNumber();
        uint256 periodOffset = blockNumber % i_beaconPeriodBlocks;
        uint256 nextBeaconOutputHeight = blockNumber +
            i_beaconPeriodBlocks -
            periodOffset;

        uint256 slotNumberBig = nextBeaconOutputHeight / i_beaconPeriodBlocks;
        if (slotNumberBig >= SlotNumber.unwrap(MAX_SLOT_NUMBER)) {
            revert TooManySlotsReplaceContract();
        }
        SlotNumber slotNumber = SlotNumber.wrap(uint32(slotNumberBig));
        RequestParams memory rp = s_requestParams;
        RequestID nonce = rp.requestID;
        if (RequestID.unwrap(nonce) >= RequestID.unwrap(MAX_REQUEST_ID)) {
            revert TooManyRequestsReplaceContract();
        }
        // Ensure next request has unique nonce
        s_requestParams.requestID = RequestID.wrap(RequestID.unwrap(nonce) + 1);

        uint256 i;
        for (i = 0; i < rp.confirmationDelays.length; i++) {
            if (
                ConfirmationDelay.unwrap(rp.confirmationDelays[i]) ==
                ConfirmationDelay.unwrap(confirmationDelayArg)
            ) {
                break;
            }
        }
        if (i >= rp.confirmationDelays.length) {
            revert UnknownConfirmationDelay(
                confirmationDelayArg,
                rp.confirmationDelays
            );
        }

        BeaconRequest memory r = BeaconRequest({
            slotNumber: slotNumber,
            confirmationDelay: confirmationDelayArg,
            numWords: numWords,
            requester: msg.sender
        });
        return (nonce, r, uint64(nextBeaconOutputHeight));
    }

    error UnknownConfirmationDelay(
        ConfirmationDelay givenDelay,
        ConfirmationDelay[NUM_CONF_DELAYS] knownDelays
    );

    // Returns the requested words for the given BeaconRequest and VRF output seed
    function finalOutput(
        RequestID requestID,
        BeaconRequest memory r,
        bytes32 seed,
        uint64 blockHeight
    ) internal pure returns (uint256[] memory) {
        if (seed == bytes32(0)) {
            revert RandomnessNotAvailable(requestID, blockHeight);
        }
        bytes32 finalSeed = keccak256(abi.encode(requestID, r, seed));
        if (r.numWords > maxNumWords) {
            // Could happen if corrupted quorum submits
            revert TooManyWords(r.numWords, maxNumWords); // fake callback
        }
        uint256[] memory randomness = new uint256[](r.numWords);
        for (uint16 i = 0; i < r.numWords; i++) {
            randomness[i] = uint256(keccak256(abi.encodePacked(finalSeed, i)));
        }
        return randomness;
    }

    /// @inheritdoc IVRFCoordinatorProducerAPI
    function transferLink(address recipient, uint256 juelsAmount)
        external
        override
        onlyProducer
    {
        // Poses no re-entrancy issues, because LINK.transfer does not yield
        // control flow.
        require(LINK.transfer(recipient, juelsAmount), "insufficient funds");
    }

    /// @inheritdoc IVRFCoordinatorProducerAPI
    function batchTransferLink(
        address[] calldata recipients,
        uint256[] calldata paymentsInJuels
    ) external override onlyProducer {
        uint256 numRecipients = recipients.length;
        require(
            numRecipients > 0,
            "number of recipients must be greater than 0"
        );
        require(numRecipients <= MAX_NUM_ORACLES, "too many recipients");
        require(
            numRecipients == paymentsInJuels.length,
            "length of recipients and paymentsInJuels did not match"
        );
        for (
            uint256 recipientidx = 0;
            recipientidx < numRecipients;
            recipientidx++
        ) {
            // Poses no re-entrancy issues, because LINK.transfer does not yield
            // control flow.
            require(
                LINK.transfer(
                    recipients[recipientidx],
                    paymentsInJuels[recipientidx]
                ),
                "insufficient funds"
            );
        }
    }

    /// @inheritdoc IVRFCoordinatorProducerAPI
    function getTotalLinkBalance()
        external
        view
        override
        onlyProducer
        returns (uint256 balance)
    {
        return LINK.balanceOf(address(this));
    }

    /// @inheritdoc IVRFCoordinatorProducerAPI
    /// @dev can only be called by producer (call setProducer)
    function setConfirmationDelays(
        ConfirmationDelay[NUM_CONF_DELAYS] calldata confDelays
    ) external override onlyProducer {
        s_requestParams.confirmationDelays = confDelays;
    }

    /// @notice returns allowed confirmationDelays
    function getConfirmationDelays()
        external
        view
        returns (ConfirmationDelay[NUM_CONF_DELAYS] memory)
    {
        return s_requestParams.confirmationDelays;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {AggregatorV3Interface} from "./vendor/ocr2-contracts/interfaces/AggregatorV3Interface.sol";
import {LinkTokenInterface} from "./vendor/ocr2-contracts/interfaces/LinkTokenInterface.sol";
import {VRFBeaconTypes} from "./VRFBeaconTypes.sol";
import {OwnerIsCreator} from "./vendor/ocr2-contracts/OwnerIsCreator.sol";
import {SubscriptionInterface} from "./SubscriptionInterface.sol";
import {ERC677ReceiverInterface} from "./ERC677ReceiverInterface.sol";

abstract contract VRFBeaconBilling is
    OwnerIsCreator,
    SubscriptionInterface,
    ERC677ReceiverInterface
{
    LinkTokenInterface public immutable LINK; // Address of LINK token contract
    AggregatorV3Interface public immutable LINK_ETH_FEED; // Address of LINK/ETH feed
    // We need to maintain a list of consuming addresses.
    // This bound ensures we are able to loop over them as needed.
    // Should a user require more consumers, they can use multiple subscriptions.
    uint96 private constant MAX_JUELS_SUPPLY = 1e27;
    uint16 public constant MAX_CONSUMERS = 100;
    uint64 private s_currentSubId; // Highest subscription ID. Rises monotonically
    // s_totalBalance tracks the total link sent to
    // this contract through onTokenTransfer
    // A discrepancy with this contract's link balance indicates someone
    // sent tokens using transfer and so we may need to use recoverFunds.
    uint96 private s_totalBalance;
    // Note a nonce of 0 indicates an the consumer is not assigned to that subscription.
    mapping(address => mapping(uint64 => uint64)) /* consumer */ /* subId */ /* nonce */
        private s_consumers;

    // Billing configuration struct.
    VRFBeaconTypes.BillingConfig private s_billingConfig;

    // Reentrancy protection.
    bool internal s_reentrancyLock;

    struct SubscriptionConfig {
        address owner; // Owner can fund/withdraw/cancel the sub.
        address requestedOwner; // For safely transferring sub ownership.
        // Maintains the list of keys in s_consumers.
        // We do this for 2 reasons:
        // 1. To be able to clean up all keys from s_consumers when canceling a
        //    subscription.
        // 2. To be able to return the list of all consumers in getSubscription.
        // Note that we need the s_consumers map to be able to directly check if a
        // consumer is valid without reading all the consumers from storage.
        address[] consumers;
    }
    mapping(uint64 => SubscriptionConfig) /* subId */ /* subscriptionConfig */
        private s_subscriptionConfigs;

    struct Subscription {
        // There are only 1e9*1e18 = 1e27 juels in existence, so the balance can fit in uint96 (2^96 ~ 7e28)
        uint96 balance; // Common link balance used for all consumer requests.
        uint64 reqCount; // For fee tiers
    }
    mapping(uint64 => Subscription) /* subId */ /* subscription */
        internal s_subscriptions;

    event SubscriptionCreated(uint64 indexed subId, address owner);
    event SubscriptionOwnerTransferRequested(
        uint64 indexed subId,
        address from,
        address to
    );
    event SubscriptionOwnerTransferred(
        uint64 indexed subId,
        address from,
        address to
    );
    event SubscriptionConsumerAdded(uint64 indexed subId, address consumer);
    event SubscriptionConsumerRemoved(uint64 indexed subId, address consumer);
    event SubscriptionCanceled(
        uint64 indexed subId,
        address to,
        uint256 amount
    );
    event SubscriptionFunded(
        uint64 indexed subId,
        uint256 oldBalance,
        uint256 newBalance
    );

    /// @dev Emitted when a subscription for a given ID cannot be found
    error InvalidSubscription();
    /// @dev Emitted when sender is not authorized to make the requested change to
    /// @dev the subscription
    error MustBeSubOwner(address owner);
    /// @dev Emitted when consumer is not registered for the subscription
    error InvalidConsumer(uint64 subId, address consumer);
    /// @dev Emitted when number of consumer will exceed MAX_CONSUMERS
    error TooManyConsumers();
    /// @dev Emmited when balance is insufficient
    error InsufficientBalance();
    /// @dev Emmited when msg.sender is not the requested owner
    error MustBeRequestedOwner(address proposedOwner);
    /// @dev Emmited when subscription can't be cancelled because of pending requests
    error PendingRequestExists();
    /// @dev Emitted when caller transfers tokens other than LINK
    error OnlyCallableFromLink();
    /// @dev Emitted when calldata is invalid
    error InvalidCalldata();
    /// @dev Emitted when a client contract attempts to re-enter a state-changing
    /// @dev coordinator method.
    error Reentrant();
    /// @dev Emitted when the number of Juels from a conversion exceed the token supply.
    error InvalidJuelsConversion();
    /// @dev Emitted when an invalid billing config update was attempted.
    error InvalidBillingConfig();

    constructor(address link, address linkEthFeed) OwnerIsCreator() {
        LINK = LinkTokenInterface(link);
        LINK_ETH_FEED = AggregatorV3Interface(linkEthFeed);
    }

    /// @notice setBillingConfig updates the contract's billing config.
    function setBillingConfig(
        VRFBeaconTypes.BillingConfig calldata billingConfig
    ) external onlyOwner {
        if (billingConfig.unusedGasPenaltyPercent > 100) {
            revert InvalidBillingConfig();
        }
        s_billingConfig = billingConfig;
    }

    function getTotalBalance() external view returns (uint96) {
        return s_totalBalance;
    }

    // getFeedData returns the most recent LINK/ETH ratio,
    // "ETH" being the native gas token of a given network.
    function getFeedData() internal view returns (uint256) {
        uint32 stalenessSeconds = s_billingConfig.stalenessSeconds;
        bool staleFallback = stalenessSeconds > 0;
        uint256 timestamp;
        int256 weiPerUnitLink;
        (, weiPerUnitLink, , timestamp, ) = LINK_ETH_FEED.latestRoundData();
        if (staleFallback && stalenessSeconds < block.timestamp - timestamp) {
            weiPerUnitLink = s_billingConfig.fallbackWeiPerUnitLink;
        }
        return uint256(weiPerUnitLink);
    }

    // billSubscriberForRequest calculates the cost of a beacon request in Juels,
    // and bills the user's subscription.
    function billSubscriberForRequest(address requester, uint64 subID)
        internal
    {
        if (s_consumers[requester][subID] == 0) {
            revert InvalidConsumer(subID, requester);
        }

        // Calculate the request price.
        uint256 costJuels = calculateRequestPriceJuels();

        // Bill user if the subscription is funded, otherwise revert.
        Subscription storage sub = s_subscriptions[subID];
        if (sub.balance < costJuels) {
            revert InsufficientBalance();
        }
        sub.balance -= uint96(costJuels);
    }

    // billSubscriberForCallback calculates the cost of a callback request in Juels,
    // and bills the user's subscription.
    function billSubscriberForCallback(VRFBeaconTypes.Callback memory callback)
        internal
    {
        if (s_consumers[callback.requester][callback.subID] == 0) {
            revert InvalidConsumer(callback.subID, callback.requester);
        }

        // Calculate the request price.
        uint256 costJuels = calculateRequestPriceCallbackJuels(callback);

        // Bill user if the subscription is funded, otherwise revert.
        Subscription storage sub = s_subscriptions[callback.subID];
        if (sub.balance < costJuels) {
            revert InsufficientBalance();
        }
        sub.balance -= uint96(costJuels);
    }

    // refundCallback refunds a callback after it has been processed.
    function refundCallback(
        uint256 gasUsed,
        VRFBeaconTypes.Callback memory callback
    ) internal {
        if (gasUsed > callback.gasAllowance) {
            // This shouldn't happen, but return to prevent an underflow.
            return;
        }
        // Calculate the refund amount based on the unused gas penalty,
        // and convert to Juels.
        uint256 refundWei = (((callback.gasAllowance - gasUsed) *
            callback.gasPrice) *
            (100 - s_billingConfig.unusedGasPenaltyPercent)) / 100;
        uint96 refundJuels = convertToJuels(refundWei, callback.weiPerUnitLink);

        // Refund the given subscription.
        s_subscriptions[callback.subID].balance += refundJuels;
    }

    /// @notice calculateRequestPriceJuels calculates the request price in Juels
    /// @notice for a beacon request.
    function calculateRequestPriceJuels() public view returns (uint96) {
        uint256 baseCost = s_billingConfig.redeemableRequestGasOverhead *
            tx.gasprice;
        return getFinalCostJuels(baseCost, 0);
    }

    /// @notice calculateRequestPriceCallback calculates the request price in Juels
    /// @notice for a callback request.
    function calculateRequestPriceCallbackJuels(
        VRFBeaconTypes.Callback memory callback
    ) public view returns (uint96) {
        uint256 baseCost = (callback.gasAllowance +
            s_billingConfig.callbackRequestGasOverhead) * tx.gasprice;
        return getFinalCostJuels(baseCost, callback.weiPerUnitLink);
    }

    // getFinalCostJuels adds the permium percentage to the base cost of a request,
    // and converts that cost to Juels.
    function getFinalCostJuels(uint256 baseCost, uint256 localFeedData)
        internal
        view
        returns (uint96)
    {
        // Calculate raw wei cost with added premium.
        uint256 premiumCost = (baseCost *
            (s_billingConfig.premiumPercentage + 100)) / 100;

        // Convert wei cost to Juels.
        return convertToJuels(premiumCost, localFeedData);
    }

    // convertToJuels converts a given weiAmount to Juels.
    // There are only 1e9*1e18 = 1e27 juels in existence,
    // so the return should always fit into a uint96 (2^96 ~ 7e28).
    function convertToJuels(uint256 weiAmount, uint256 localFeedData)
        private
        view
        returns (uint96)
    {
        uint256 weiPerUnitLink = localFeedData == 0
            ? getFeedData()
            : localFeedData;
        uint256 juelsAmount = (1e18 * weiAmount) / weiPerUnitLink;
        if (juelsAmount > MAX_JUELS_SUPPLY) {
            revert InvalidJuelsConversion();
        }
        return uint96(juelsAmount);
    }

    /**
     * @inheritdoc SubscriptionInterface
     */
    function getCurrentSubId() external view returns (uint64) {
        return s_currentSubId;
    }

    /**
     * @inheritdoc SubscriptionInterface
     */
    function createSubscription()
        external
        override
        nonReentrant
        returns (uint64)
    {
        s_currentSubId++;
        uint64 currentSubId = s_currentSubId;
        address[] memory consumers = new address[](0);
        s_subscriptions[currentSubId] = Subscription({balance: 0, reqCount: 0});
        s_subscriptionConfigs[currentSubId] = SubscriptionConfig({
            owner: msg.sender,
            requestedOwner: address(0),
            consumers: consumers
        });

        emit SubscriptionCreated(currentSubId, msg.sender);
        return currentSubId;
    }

    /**
     * @inheritdoc SubscriptionInterface
     */
    function getSubscription(uint64 subId)
        external
        view
        override
        returns (
            uint96 balance,
            uint64 reqCount,
            address owner,
            address[] memory consumers
        )
    {
        if (s_subscriptionConfigs[subId].owner == address(0)) {
            revert InvalidSubscription();
        }
        return (
            s_subscriptions[subId].balance,
            s_subscriptions[subId].reqCount,
            s_subscriptionConfigs[subId].owner,
            s_subscriptionConfigs[subId].consumers
        );
    }

    /**
     * @inheritdoc SubscriptionInterface
     */
    function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner)
        external
        override
        onlySubOwner(subId)
        nonReentrant
    {
        // Proposing to address(0) would never be claimable so don't need to check.
        if (s_subscriptionConfigs[subId].requestedOwner != newOwner) {
            s_subscriptionConfigs[subId].requestedOwner = newOwner;
            emit SubscriptionOwnerTransferRequested(
                subId,
                msg.sender,
                newOwner
            );
        }
    }

    /**
     * @inheritdoc SubscriptionInterface
     */
    function acceptSubscriptionOwnerTransfer(uint64 subId)
        external
        override
        nonReentrant
    {
        if (s_subscriptionConfigs[subId].owner == address(0)) {
            revert InvalidSubscription();
        }
        if (s_subscriptionConfigs[subId].requestedOwner != msg.sender) {
            revert MustBeRequestedOwner(
                s_subscriptionConfigs[subId].requestedOwner
            );
        }
        address oldOwner = s_subscriptionConfigs[subId].owner;
        s_subscriptionConfigs[subId].owner = msg.sender;
        s_subscriptionConfigs[subId].requestedOwner = address(0);
        emit SubscriptionOwnerTransferred(subId, oldOwner, msg.sender);
    }

    /**
     * @inheritdoc SubscriptionInterface
     */
    function addConsumer(uint64 subId, address consumer)
        external
        override
        onlySubOwner(subId)
        nonReentrant
    {
        // Already maxed, cannot add any more consumers.
        if (s_subscriptionConfigs[subId].consumers.length == MAX_CONSUMERS) {
            revert TooManyConsumers();
        }
        if (s_consumers[consumer][subId] != 0) {
            // Idempotence - do nothing if already added.
            // Ensures uniqueness in s_subscriptions[subId].consumers.
            return;
        }
        // Initialize the nonce to 1, indicating the consumer is allocated.
        s_consumers[consumer][subId] = 1;
        s_subscriptionConfigs[subId].consumers.push(consumer);

        emit SubscriptionConsumerAdded(subId, consumer);
    }

    /**
     * @inheritdoc SubscriptionInterface
     */
    function removeConsumer(uint64 subId, address consumer)
        external
        override
        onlySubOwner(subId)
        nonReentrant
    {
        if (s_consumers[consumer][subId] == 0) {
            revert InvalidConsumer(subId, consumer);
        }
        // Note bounded by MAX_CONSUMERS
        address[] memory consumers = s_subscriptionConfigs[subId].consumers;
        uint256 lastConsumerIndex = consumers.length - 1;
        for (uint256 i = 0; i < consumers.length; i++) {
            if (consumers[i] == consumer) {
                address last = consumers[lastConsumerIndex];
                // Storage write to preserve last element
                s_subscriptionConfigs[subId].consumers[i] = last;
                // Storage remove last element
                s_subscriptionConfigs[subId].consumers.pop();
                break;
            }
        }
        delete s_consumers[consumer][subId];
        emit SubscriptionConsumerRemoved(subId, consumer);
    }

    /**
     * @inheritdoc SubscriptionInterface
     */
    function cancelSubscription(uint64 subId, address to)
        external
        override
        onlySubOwner(subId)
        nonReentrant
    {
        SubscriptionConfig memory subConfig = s_subscriptionConfigs[subId];
        Subscription memory sub = s_subscriptions[subId];
        uint96 balance = sub.balance;
        // Note bounded by MAX_CONSUMERS;
        // If no consumers, does nothing.
        for (uint256 i = 0; i < subConfig.consumers.length; i++) {
            delete s_consumers[subConfig.consumers[i]][subId];
        }
        delete s_subscriptionConfigs[subId];
        delete s_subscriptions[subId];
        s_totalBalance -= balance;
        if (!LINK.transfer(to, uint256(balance))) {
            revert InsufficientBalance();
        }
        emit SubscriptionCanceled(subId, to, balance);
    }

    /// @dev TODO: Discuss if this functionality is needed. It seems to be only needed
    /// @dev if we support a free/cheap tier for low-volume users. If we do need it,
    /// @dev then s_consumerSubscription will require updates to functions in
    /// @dev SubscriptionInterface.sol
    /// @dev Each consumer is associated with a single subscription, for the life
    /// @dev of this coordinator, unless the coordinator owner moves it. This
    /// @dev prevents users from moving a consuming contract to different
    /// @dev subscription in order to obtain a cheaper fee tier. The zero value
    /// @dev means that a consumer has not yet been assigned to a subscription.
    mapping(address => uint64) /* consumer */ /* subscription */
        internal s_consumerSubscription;

    /// @notice Forget the subscription ID a consumer address is associated with.
    ///
    /// @dev Useful if a user needs to move to a new subscription for some reason.
    /// @dev Can only be called by coordinator owner.
    function forgetConsumerSubscriptionID(address[] calldata consumers)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < consumers.length; i++) {
            s_consumerSubscription[consumers[i]] = 0;
        }
    }

    function onTokenTransfer(
        address, /* sender */
        uint256 amount,
        bytes calldata data
    ) external override nonReentrant {
        if (msg.sender != address(LINK)) {
            revert OnlyCallableFromLink();
        }
        if (data.length != 32) {
            revert InvalidCalldata();
        }
        uint64 subId = abi.decode(data, (uint64));
        if (s_subscriptionConfigs[subId].owner == address(0)) {
            revert InvalidSubscription();
        }
        // We do not check that the msg.sender is the subscription owner,
        // anyone can fund a subscription.
        uint256 oldBalance = s_subscriptions[subId].balance;
        s_subscriptions[subId].balance += uint96(amount);
        s_totalBalance += uint96(amount);
        emit SubscriptionFunded(subId, oldBalance, oldBalance + amount);
    }

    /// @dev reverts when a client contract attempts to re-enter a state-changing
    /// @dev method
    modifier nonReentrant() {
        if (s_reentrancyLock) {
            revert Reentrant();
        }
        _;
    }

    /// @dev reverts when the sender is not the owner of the subscription
    modifier onlySubOwner(uint64 subId) {
        address owner = s_subscriptionConfigs[subId].owner;
        if (owner == address(0)) {
            revert InvalidSubscription();
        }
        if (msg.sender != owner) {
            revert MustBeSubOwner(owner);
        }
        _;
    }

    function subscriptionExists(uint64 subID) internal view returns (bool) {
        return s_subscriptionConfigs[subID].owner != address(0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VRFBeaconTypes} from "./VRFBeaconTypes.sol";

abstract contract IVRFCoordinatorExternalAPI is VRFBeaconTypes {
    //////////////////////////////////////////////////////////////////////////////
    /// @notice Register a future request for randomness,and return the requestID.
    ///
    /// @notice The requestID resulting from given requestRandomness call MAY
    /// @notice CHANGE if a set of transactions calling requestRandomness are
    /// @notice re-ordered during a block re-organization. Thus, it is necessary
    /// @notice for the calling context to store the requestID onchain, unless
    /// @notice there is a an offchain system which keeps track of changes to the
    /// @notice requestID.
    ///
    /// @param numWords number of uint256's of randomness to provide in response
    /// @return ID of created request
    function requestRandomness(
        uint16 numWords,
        uint64 subID,
        ConfirmationDelay confirmationDelayArg
    ) external virtual returns (RequestID);

    //////////////////////////////////////////////////////////////////////////////
    /// @notice Request a callback on the next available randomness output
    ///
    /// @notice The contract at the callback address must have a method
    /// @notice fulfillRandomness(RequestID,uint256,bytes). It will be called with
    /// @notice the ID returned by this function, the random value, and the
    /// @notice arguments value passed to this function.
    ///
    /// @param numWords number of uint256's of randomness to provide in response
    /// @param arguments data which should be passed to the callback method
    ///
    /// @return ID of created request
    ///
    /// @dev No record of this commitment is stored onchain. The VRF committee is
    /// @dev trusted to only provide callbacks for valid requests.
    function requestRandomnessFulfillment(
        uint64 subID,
        uint16 numWords,
        ConfirmationDelay confirmationDelayArg,
        uint32 callbackGasLimit,
        bytes memory arguments
    ) external virtual returns (RequestID);

    //////////////////////////////////////////////////////////////////////////////
    /// @notice Get randomness for the given requestID
    /// @param requestID ID of request r for which to retrieve randomness
    /// @return randomness r.numWords random uint256's
    function redeemRandomness(RequestID requestID)
        public
        virtual
        returns (uint256[] memory randomness);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {ECCArithmetic} from "./ECCArithmetic.sol";
import {VRFBeaconTypes} from "./VRFBeaconTypes.sol";
import {IVRFCoordinatorExternalAPI} from "./IVRFCoordinatorExternalAPI.sol";

abstract contract IVRFCoordinatorConsumer is VRFBeaconTypes {
    IVRFCoordinatorExternalAPI immutable coordinator;

    constructor(address _coordinator) {
        coordinator = IVRFCoordinatorExternalAPI(_coordinator);
    }

    function fulfillRandomWords(
        VRFBeaconTypes.RequestID requestID,
        uint256[] memory response,
        bytes memory arguments
    ) internal virtual;

    function rawFulfillRandomWords(
        VRFBeaconTypes.RequestID requestID,
        uint256[] memory randomWords,
        bytes memory arguments
    ) external {
        require(
            address(coordinator) == msg.sender,
            "only coordinator can fulfill"
        );
        fulfillRandomWords(requestID, randomWords, arguments);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VRFBeaconTypes} from "./VRFBeaconTypes.sol";

// Interface used by VRF output producers such as VRFBeacon
// Exposes methods for processing VRF outputs and paying appropriate EOA
// The methods are only callable by producers
abstract contract IVRFCoordinatorProducerAPI is VRFBeaconTypes {
    /// @dev processes VRF outputs for given blockHeight and blockHash
    /// @dev also fulfills callbacks
    function processVRFOutputs(
        VRFOutput[] calldata vrfOutputs,
        uint192 juelsPerFeeCoin,
        uint64 blockHeight,
        bytes32 blockHash
    ) external virtual returns (OutputServed[] memory);

    /// @dev transfers LINK to recipient
    /// @dev reverts when there are not enough funds
    function transferLink(address recipient, uint256 juelsAmount)
        external
        virtual;

    /// @dev transfer LINK to multiple recipients
    /// @dev reverts when there are not enough funds or number of recipients and
    /// @dev paymentsInJuels are not as expected
    function batchTransferLink(
        address[] calldata recipients,
        uint256[] calldata paymentsInJuels
    ) external virtual;

    /// @dev returns total Link balance in the contract in juels
    function getTotalLinkBalance()
        external
        view
        virtual
        returns (uint256 balance);

    /// @dev sets allowed confirmation delays
    function setConfirmationDelays(
        ConfirmationDelay[NUM_CONF_DELAYS] calldata confDelays
    ) external virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {ArbSys} from "./vendor/nitro/207827de97/contracts/src/precompiles/ArbSys.sol";

//@dev A library that abstracts out opcodes that behave differently across chains.
//@dev The methods below return values that are pertinent to the given chain.
//@dev For instance, ChainSpecificUtil.getBlockNumber() returns L2 block number in L2 chains
library ChainSpecificUtil {
    address private constant ARBSYS_ADDR =
        address(0x0000000000000000000000000000000000000064);
    ArbSys private constant ARBSYS = ArbSys(ARBSYS_ADDR);
    uint256 private constant ARB_MAINNET_CHAIN_ID = 42161;
    uint256 private constant ARB_GOERLI_TESTNET_CHAIN_ID = 421613;

    function getBlockhash(uint64 blockNumber) internal view returns (bytes32) {
        uint256 chainid = block.chainid;
        if (
            chainid == ARB_MAINNET_CHAIN_ID ||
            chainid == ARB_GOERLI_TESTNET_CHAIN_ID
        ) {
            return ARBSYS.arbBlockHash(blockNumber);
        }
        return blockhash(blockNumber);
    }

    function getBlockNumber() internal view returns (uint256) {
        uint256 chainid = block.chainid;
        if (
            chainid == ARB_MAINNET_CHAIN_ID ||
            chainid == ARB_GOERLI_TESTNET_CHAIN_ID
        ) {
            return ARBSYS.arbBlockNumber();
        }
        return block.number;
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
pragma solidity ^0.8.0;

interface LinkTokenInterface {
    function allowance(address owner, address spender)
        external
        view
        returns (uint256 remaining);

    function approve(address spender, uint256 value)
        external
        returns (bool success);

    function balanceOf(address owner) external view returns (uint256 balance);

    function decimals() external view returns (uint8 decimalPlaces);

    function decreaseApproval(address spender, uint256 addedValue)
        external
        returns (bool success);

    function increaseApproval(address spender, uint256 subtractedValue)
        external;

    function name() external view returns (string memory tokenName);

    function symbol() external view returns (string memory tokenSymbol);

    function totalSupply() external view returns (uint256 totalTokensIssued);

    function transfer(address to, uint256 value)
        external
        returns (bool success);

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
pragma solidity 0.8.15;

import {ECCArithmetic} from "./ECCArithmetic.sol";

// If these types are changed, the types in beaconObservation.proto and
// AbstractCostedCallbackRequest etc. probably need to change, too.
contract VRFBeaconTypes {
    type RequestID is uint48;
    RequestID constant MAX_REQUEST_ID = RequestID.wrap(type(uint48).max);
    uint8 public constant NUM_CONF_DELAYS = 8;
    uint256 internal constant MAX_NUM_ORACLES = 31;

    /// @dev With a beacon period of 15, using a uint32 here allows for roughly
    /// @dev 60B blocks, which would take roughly 2000 years on a chain with a 1s
    /// @dev block time.
    type SlotNumber is uint32;
    SlotNumber internal constant MAX_SLOT_NUMBER =
        SlotNumber.wrap(type(uint32).max);

    type ConfirmationDelay is uint24;
    ConfirmationDelay internal constant MAX_CONFIRMATION_DELAY =
        ConfirmationDelay.wrap(type(uint24).max);
    uint8 internal constant CONFIRMATION_DELAY_BYTE_WIDTH = 3;

    /// @dev Request metadata. Designed to fit in a single 32-byte word, to save
    /// @dev on storage/retrieval gas costs.
    struct BeaconRequest {
        SlotNumber slotNumber;
        ConfirmationDelay confirmationDelay;
        uint16 numWords;
        address requester; // Address which will eventually retrieve randomness
    }

    struct Callback {
        RequestID requestID;
        uint16 numWords;
        address requester;
        bytes arguments;
        uint64 subID;
        uint96 gasAllowance; // gas offered to callback method when called
        uint256 gasPrice;
        uint256 weiPerUnitLink;
    }

    struct CostedCallback {
        Callback callback;
        uint96 price; // nominal price charged for the callback
    }

    /// @dev configuration parameters for billing
    struct BillingConfig {
        // Penalty in percent (max 100) for unused gas in an allowance.
        uint8 unusedGasPenaltyPercent;
        // stalenessSeconds is how long before we consider the feed price to be
        // stale and fallback to fallbackWeiPerUnitLink.
        uint32 stalenessSeconds;
        // Estimated gas cost for a beacon fulfillment.
        uint32 redeemableRequestGasOverhead;
        // Estimated gas cost for a callback fulfillment (excludes gas allowance).
        uint32 callbackRequestGasOverhead;
        // Premium percentage charged.
        uint32 premiumPercentage;
        // Fallback LINK/ETH ratio.
        int256 fallbackWeiPerUnitLink;
    }

    // TODO(coventry): There is scope for optimization of the calldata gas cost,
    // here. The solidity lists can be replaced by something lower-level, where
    // the lengths are represented by something shorter, and there could be a
    // specialized part of the report which deals with fulfillments for blocks
    // which have already had their seeds reported.
    struct VRFOutput {
        uint64 blockHeight; // Beacon height this output corresponds to
        ConfirmationDelay confirmationDelay; // #blocks til offchain system response
        // VRF output for blockhash at blockHeight. If this is (0,0), indicates that
        // this is a request for callbacks for a pre-existing height, and the seed
        // should be sought from contract storage
        ECCArithmetic.G1Point vrfOutput;
        CostedCallback[] callbacks; // Contracts to callback with random outputs
    }

    struct OutputServed {
        uint64 height;
        ConfirmationDelay confirmationDelay;
        uint256 proofG1X;
        uint256 proofG1Y;
    }

    /// @dev Emitted when randomness is requested without a callback, for the
    /// @dev given beacon height. This signals to the offchain system that it
    /// @dev should provide the VRF output for that height
    ///
    /// @param requestID request identifier
    /// @param requester consumer contract
    /// @param nextBeaconOutputHeight height where VRF output should be provided
    /// @param confDelay num blocks offchain system should wait before responding
    /// @param subID subscription ID that consumer contract belongs to
    /// @param numWords number of randomness words requested
    event RandomnessRequested(
        RequestID indexed requestID,
        address indexed requester,
        uint64 nextBeaconOutputHeight,
        ConfirmationDelay confDelay,
        uint64 subID,
        uint16 numWords
    );

    /// @dev Emitted when randomness is requested with a callback, for the given
    /// @dev height, to the given address, which should contain a contract with a
    /// @dev fulfillRandomness(RequestID,uint256,bytes) method. This will be
    /// @dev called with the given RequestID, the uint256 output, and the given
    /// @dev bytes arguments.
    ///
    /// @param requestID request identifier
    /// @param requester consumer contract
    /// @param nextBeaconOutputHeight height where VRF output should be provided
    /// @param confDelay num blocks offchain system should wait before responding
    /// @param subID subscription ID that consumer contract belongs to
    /// @param numWords number of randomness words requested
    /// @param gasAllowance max gas offered to callback method during fulfillment
    /// @param gasPrice tx.gasprice during request
    /// @param weiPerUnitLink ETH/LINK ratio during request
    /// @param arguments callback arguments passed in from consumer contract
    event RandomnessFulfillmentRequested(
        RequestID indexed requestID,
        address indexed requester,
        uint64 nextBeaconOutputHeight,
        ConfirmationDelay confDelay,
        uint64 subID,
        uint16 numWords,
        uint32 gasAllowance,
        uint256 gasPrice,
        uint256 weiPerUnitLink,
        bytes arguments
    );

    /// @notice emitted when the requestIDs have been fulfilled
    ///
    /// @dev There is one entry in truncatedErrorData for each false entry in
    /// @dev successfulFulfillment
    ///
    /// @param requestIDs the IDs of the requests which have been fulfilled
    /// @param successfulFulfillment ith entry true if ith fulfillment succeeded
    /// @param truncatedErrorData ith entry is error message for ith failure
    event RandomWordsFulfilled(
        RequestID[] requestIDs,
        bytes successfulFulfillment,
        bytes[] truncatedErrorData
    );

    event NewTransmission(
        uint32 indexed aggregatorRoundId,
        uint40 indexed epochAndRound,
        address transmitter,
        uint192 juelsPerFeeCoin,
        bytes32 configDigest
    );

    event OutputsServed(
        uint64 recentBlockHeight,
        address transmitter,
        uint192 juelsPerFeeCoin,
        OutputServed[] outputsServed
    );
    /**
     * @notice triggers a new run of the offchain reporting protocol
     * @param previousConfigBlockNumber block in which the previous config was set, to simplify historic analysis
     * @param configDigest configDigest of this configuration
     * @param configCount ordinal number of this config setting among all config settings over the life of this contract
     * @param signers ith element is address ith oracle uses to sign a report
     * @param transmitters ith element is address ith oracle uses to transmit a report via the transmit method
     * @param f maximum number of faulty/dishonest oracles the protocol can tolerate while still working correctly
     * @param onchainConfig serialized configuration used by the contract (and possibly oracles)
     * @param offchainConfigVersion version of the serialization format used for "offchainConfig" parameter
     * @param offchainConfig serialized configuration used by the oracles exclusively and only passed through the contract
     */
    event ConfigSet(
        uint32 previousConfigBlockNumber,
        bytes32 configDigest,
        uint64 configCount,
        address[] signers,
        address[] transmitters,
        uint8 f,
        bytes onchainConfig,
        uint64 offchainConfigVersion,
        bytes offchainConfig
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwner.sol";

/**
 * @title The OwnerIsCreator contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract OwnerIsCreator is ConfirmedOwner {
    constructor() ConfirmedOwner(msg.sender) {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface SubscriptionInterface {
    /**
     * @notice Create a VRF subscription.
     * @return subId - A unique subscription id.
     * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
     * @dev Note to fund the subscription, use transferAndCall. For example
     * @dev  LINKTOKEN.transferAndCall(
     * @dev    address(COORDINATOR),
     * @dev    amount,
     * @dev    abi.encode(subId));
     */
    function createSubscription() external returns (uint64 subId);

    /**
     * @notice Get current subscription ID.
     * @return subId - ID of the current subscription
     */
    function getCurrentSubId() external returns (uint64 subId);

    /**
     * @notice Get a VRF subscription.
     * @param subId - ID of the subscription
     * @return balance - LINK balance of the subscription in juels.
     * @return reqCount - number of requests for this subscription, determines fee tier.
     * @return owner - owner of the subscription.
     * @return consumers - list of consumer address which are able to use this subscription.
     */
    function getSubscription(uint64 subId)
        external
        view
        returns (
            uint96 balance,
            uint64 reqCount,
            address owner,
            address[] memory consumers
        );

    /**
     * @notice Request subscription owner transfer.
     * @param subId - ID of the subscription
     * @param newOwner - proposed new owner of the subscription
     */
    function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner)
        external;

    /**
     * @notice Request subscription owner transfer.
     * @param subId - ID of the subscription
     * @dev will revert if original owner of subId has
     * not requested that msg.sender become the new owner.
     */
    function acceptSubscriptionOwnerTransfer(uint64 subId) external;

    /**
     * @notice Add a consumer to a VRF subscription.
     * @param subId - ID of the subscription
     * @param consumer - New consumer which can use the subscription
     */
    function addConsumer(uint64 subId, address consumer) external;

    /**
     * @notice Remove a consumer from a VRF subscription.
     * @param subId - ID of the subscription
     * @param consumer - Consumer to remove from the subscription
     */
    function removeConsumer(uint64 subId, address consumer) external;

    /**
     * @notice Cancel a subscription
     * @param subId - ID of the subscription
     * @param to - Where to send the remaining LINK to
     */
    function cancelSubscription(uint64 subId, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface ERC677ReceiverInterface {
    function onTokenTransfer(
        address sender,
        uint256 amount,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract ECCArithmetic {
    // constant term in affine curve equation: y²=x³+b
    uint256 constant B = 3;

    // Base field for G1 is 𝔽ₚ
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-196.md#specification
    uint256 constant P =
        // solium-disable-next-line indentation
        0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47;

    // #E(𝔽ₚ), number of points on  G1/G2Add
    // https://github.com/ethereum/go-ethereum/blob/2388e42/crypto/bn256/cloudflare/constants.go#L23
    uint256 constant Q =
        0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001;

    struct G1Point {
        uint256[2] p;
    }

    struct G2Point {
        uint256[4] p;
    }

    function checkPointOnCurve(G1Point memory p) internal pure {
        require(p.p[0] < P, "x not in F_P");
        require(p.p[1] < P, "y not in F_P");
        uint256 rhs = addmod(
            mulmod(mulmod(p.p[0], p.p[0], P), p.p[0], P),
            B,
            P
        );
        require(mulmod(p.p[1], p.p[1], P) == rhs, "point not on curve");
    }

    function _addG1(G1Point memory p1, G1Point memory p2)
        internal
        view
        returns (G1Point memory sum)
    {
        checkPointOnCurve(p1);
        checkPointOnCurve(p2);

        uint256[4] memory summands;
        summands[0] = p1.p[0];
        summands[1] = p1.p[1];
        summands[2] = p2.p[0];
        summands[3] = p2.p[1];
        uint256[2] memory result;
        uint256 callresult;
        assembly {
            // solhint-disable-line no-inline-assembly
            callresult := staticcall(
                // gas cost. https://eips.ethereum.org/EIPS/eip-1108 ,
                // https://github.com/ethereum/go-ethereum/blob/9d10856/params/protocol_params.go#L124
                150,
                // g1add https://github.com/ethereum/go-ethereum/blob/9d10856/core/vm/contracts.go#L89
                0x6,
                summands, // input
                0x80, // input length: 4 words
                result, // output
                0x40 // output length: 2 words
            )
        }
        require(callresult != 0, "addg1 call failed");
        sum.p[0] = result[0];
        sum.p[1] = result[1];
        return sum;
    }

    function addG1(G1Point memory p1, G1Point memory p2)
        internal
        view
        returns (G1Point memory)
    {
        G1Point memory sum = _addG1(p1, p2);
        // This failure is mathematically possible from a legitimate return
        // value, but vanishingly unlikely, and almost certainly instead
        // reflects a failure in the precompile.
        require(sum.p[0] != 0 && sum.p[1] != 0, "addg1 failed: zero ordinate");
        return sum;
    }

    // Coordinates for generator of G2.
    uint256 constant g2GenXA =
        0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2;
    uint256 constant g2GenXB =
        0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed;
    uint256 constant g2GenYA =
        0x090689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b;
    uint256 constant g2GenYB =
        0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa;

    uint256 constant pairingGasCost = 34_000 * 2 + 45_000; // Gas cost as of Istanbul; see EIP-1108
    uint256 constant pairingPrecompileAddress = 0x8;
    uint256 constant pairingInputLength = 12 * 0x20;
    uint256 constant pairingOutputLength = 0x20;

    // discreteLogsMatch returns true iff signature = sk*base, where sk is the
    // secret key associated with pubkey, i.e. pubkey = sk*<G2 generator>
    //
    // This is used for signature/VRF verification. In actual use, g1Base is the
    // hash-to-curve to be signed/exponentiated, and pubkey is the public key
    // the signature pertains to.
    function discreteLogsMatch(
        G1Point memory g1Base,
        G1Point memory signature,
        G2Point memory pubkey
    ) internal view returns (bool) {
        // It is not necessary to check that the points are in their respective
        // groups; the pairing check fails if that's not the case.

        // Let g1, g2 be the canonical generators of G1, G2, respectively..
        // Let l be the (unknown) discrete log of g1Base w.r.t. the G1 generator.
        //
        // In the happy path, the result of the first pairing in the following
        // will be -l*log_{g2}(pubkey) * e(g1,g2) = -l * sk * e(g1,g2), of the
        // second will be sk * l * e(g1,g2) = l * sk * e(g1,g2). Thus the two
        // terms will cancel, and the pairing function will return one. See
        // EIP-197.
        G1Point[] memory g1s = new G1Point[](2);
        G2Point[] memory g2s = new G2Point[](2);
        g1s[0] = G1Point([g1Base.p[0], P - g1Base.p[1]]);
        g1s[1] = signature;
        g2s[0] = pubkey;
        g2s[1] = G2Point([g2GenXA, g2GenXB, g2GenYA, g2GenYB]);
        return pairing(g1s, g2s);
    }

    function negateG1(G1Point memory p)
        internal
        pure
        returns (G1Point memory neg)
    {
        neg.p[0] = p.p[0];
        neg.p[1] = P - p.p[1];
    }

    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    //
    // Cribbed from https://gist.github.com/BjornvdLaan/ca6dd4e3993e1ef392f363ec27fe74c4
    function pairing(G1Point[] memory p1, G2Point[] memory p2)
        internal
        view
        returns (bool)
    {
        require(p1.length == p2.length);
        uint256 elements = p1.length;
        uint256 inputSize = elements * 6;
        uint256[] memory input = new uint256[](inputSize);

        for (uint256 i = 0; i < elements; i++) {
            input[i * 6 + 0] = p1[i].p[0];
            input[i * 6 + 1] = p1[i].p[1];
            input[i * 6 + 2] = p2[i].p[0];
            input[i * 6 + 3] = p2[i].p[1];
            input[i * 6 + 4] = p2[i].p[2];
            input[i * 6 + 5] = p2[i].p[3];
        }

        uint256[1] memory out;
        bool success;

        assembly {
            success := staticcall(
                pairingGasCost,
                8,
                add(input, 0x20),
                mul(inputSize, 0x20),
                out,
                0x20
            )
        }
        require(success);
        return out[0] != 0;
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.4.21 <0.9.0;

/**
 * @title System level functionality
 * @notice For use by contracts to interact with core L2-specific functionality.
 * Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064.
 */
interface ArbSys {
    /**
     * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
     * @return block number as int
     */
    function arbBlockNumber() external view returns (uint256);

    /**
     * @notice Get Arbitrum block hash (reverts unless currentBlockNum-256 <= arbBlockNum < currentBlockNum)
     * @return block hash
     */
    function arbBlockHash(uint256 arbBlockNum) external view returns (bytes32);

    /**
     * @notice Gets the rollup's unique chain identifier
     * @return Chain identifier as int
     */
    function arbChainID() external view returns (uint256);

    /**
     * @notice Get internal version number identifying an ArbOS build
     * @return version number as int
     */
    function arbOSVersion() external view returns (uint256);

    /**
     * @notice Returns 0 since Nitro has no concept of storage gas
     * @return uint 0
     */
    function getStorageGasAvailable() external view returns (uint256);

    /**
     * @notice (deprecated) check if current call is top level (meaning it was triggered by an EoA or a L1 contract)
     * @dev this call has been deprecated and may be removed in a future release
     * @return true if current execution frame is not a call by another L2 contract
     */
    function isTopLevelCall() external view returns (bool);

    /**
     * @notice map L1 sender contract address to its L2 alias
     * @param sender sender address
     * @param unused argument no longer used
     * @return aliased sender address
     */
    function mapL1SenderContractAddressToL2Alias(address sender, address unused)
        external
        pure
        returns (address);

    /**
     * @notice check if the caller (of this caller of this) is an aliased L1 contract address
     * @return true iff the caller's address is an alias for an L1 contract address
     */
    function wasMyCallersAddressAliased() external view returns (bool);

    /**
     * @notice return the address of the caller (of this caller of this), without applying L1 contract address aliasing
     * @return address of the caller's caller, without applying L1 contract address aliasing
     */
    function myCallersAddressWithoutAliasing() external view returns (address);

    /**
     * @notice Send given amount of Eth to dest from sender.
     * This is a convenience function, which is equivalent to calling sendTxToL1 with empty data.
     * @param destination recipient address on L1
     * @return unique identifier for this L2-to-L1 transaction.
     */
    function withdrawEth(address destination)
        external
        payable
        returns (uint256);

    /**
     * @notice Send a transaction to L1
     * @dev it is not possible to execute on the L1 any L2-to-L1 transaction which contains data
     * to a contract address without any code (as enforced by the Bridge contract).
     * @param destination recipient address on L1
     * @param data (optional) calldata for L1 contract call
     * @return a unique identifier for this L2-to-L1 transaction.
     */
    function sendTxToL1(address destination, bytes calldata data)
        external
        payable
        returns (uint256);

    /**
     * @notice Get send Merkle tree state
     * @return size number of sends in the history
     * @return root root hash of the send history
     * @return partials hashes of partial subtrees in the send history tree
     */
    function sendMerkleTreeState()
        external
        view
        returns (
            uint256 size,
            bytes32 root,
            bytes32[] memory partials
        );

    /**
     * @notice creates a send txn from L2 to L1
     * @param position = (level << 192) + leaf = (0 << 192) + leaf = leaf
     */
    event L2ToL1Tx(
        address caller,
        address indexed destination,
        uint256 indexed hash,
        uint256 indexed position,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );

    /// @dev DEPRECATED in favour of the new L2ToL1Tx event above after the nitro upgrade
    event L2ToL1Transaction(
        address caller,
        address indexed destination,
        uint256 indexed uniqueId,
        uint256 indexed batchNumber,
        uint256 indexInBatch,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );

    /**
     * @notice logs a merkle branch for proof synthesis
     * @param reserved an index meant only to align the 4th index with L2ToL1Transaction's 4th event
     * @param hash the merkle hash
     * @param position = (level << 192) + leaf
     */
    event SendMerkleUpdate(
        uint256 indexed reserved,
        bytes32 indexed hash,
        uint256 indexed position
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
    constructor(address newOwner)
        ConfirmedOwnerWithProposal(newOwner, address(0))
    {}
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