// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {VRFBeaconBilling} from "./VRFBeaconBilling.sol";
import {IVRFCoordinatorConsumer} from "./IVRFCoordinatorConsumer.sol";
import {IVRFCoordinatorProducerAPI} from "./IVRFCoordinatorProducerAPI.sol";
import {ChainSpecificUtil} from "./ChainSpecificUtil.sol";
import {TypeAndVersionInterface} from "./vendor/ocr2-contracts/interfaces/TypeAndVersionInterface.sol";
import {IVRFMigratableCoordinator} from "./IVRFMigratableCoordinator.sol";
import {IVRFMigration} from "./IVRFMigration.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

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
    IVRFCoordinatorProducerAPI,
    VRFBeaconBilling,
    TypeAndVersionInterface,
    IVRFMigratableCoordinator,
    IVRFMigration
{
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet internal s_migrationTargets;

    /// @notice Max length of array returned from redeemRandomness
    uint256 public constant MAX_NUM_WORDS = 1000;

    /// @dev s_producer is responsible for writing VRF outputs to the coordinator
    /// @dev s_producer is the only allowed caller for IVRFCoordinatorExternalAPI
    address public s_producer;

    struct Config {
        // maxCallbackGasLimit is the maximum gas that can be provided to vrf callbacks.
        uint32 maxCallbackGasLimit;
        // maxCallbackArgumentsLength is the maximum length of the arguments that can
        // be provided to vrf callbacks.
        uint32 maxCallbackArgumentsLength;
    }
    Config public s_config;

    event CoordinatorConfigSet(Config newConfig);

    function setConfig(Config memory config) external onlyOwner {
        s_config = config;
        emit CoordinatorConfigSet(config);
    }

    error NativePaymentGiven(uint256 amount);

    modifier noNativePayment() {
        if (msg.value != 0) {
            revert NativePaymentGiven(msg.value);
        }
        _;
    }

    /// @inheritdoc IVRFMigratableCoordinator
    function requestRandomness(
        uint256 subID,
        uint16 numWords,
        uint24 confDelayArg,
        bytes memory /* extraArgs */
    )
        external
        payable
        override
        whenNotPaused
        nonReentrant
        noNativePayment
        returns (uint256)
    {
        ConfirmationDelay confDelay = ConfirmationDelay.wrap(confDelayArg);
        (
            RequestID requestID,
            BeaconRequest memory r,
            uint64 nextBeaconOutputHeight
        ) = beaconRequest(subID, msg.sender, numWords, confDelay);
        (uint256 costJuels, uint96 balance) = billSubscriberForRequest(
            msg.sender,
            subID
        ); // throws on failure

        s_pendingRequests[requestID] = r;
        emit RandomnessRequested(
            requestID,
            msg.sender,
            nextBeaconOutputHeight,
            confDelay,
            subID,
            numWords,
            costJuels,
            balance
        );
        return RequestID.unwrap(requestID);
    }

    error GasLimitTooBig(uint32 providedLimit, uint32 maxLimit);
    error CallbackArgumentsLengthTooBig(
        uint32 providedLength,
        uint32 maxLength
    );

    /// @inheritdoc IVRFMigratableCoordinator
    function requestRandomnessFulfillment(
        uint256 subID,
        uint16 numWords,
        uint24 confDelayArg,
        uint32 callbackGasLimit,
        bytes memory arguments,
        bytes memory /* extraArgs */
    )
        external
        payable
        override
        whenNotPaused
        nonReentrant
        noNativePayment
        returns (uint256)
    {
        {
            Config memory config = s_config;
            if (callbackGasLimit > config.maxCallbackGasLimit) {
                revert GasLimitTooBig(
                    callbackGasLimit,
                    config.maxCallbackGasLimit
                );
            }
            if (arguments.length > config.maxCallbackArgumentsLength) {
                revert CallbackArgumentsLengthTooBig(
                    uint32(arguments.length),
                    config.maxCallbackArgumentsLength
                );
            }
        }
        (
            RequestID requestID, // BeaconRequest. We do not store this, because we trust the committee
            ,
            // to only sign off on reports containing valid fulfillment requests
            uint64 nextBeaconOutputHeight
        ) = beaconRequest(
                subID,
                msg.sender,
                numWords,
                ConfirmationDelay.wrap(confDelayArg)
            );
        Callback memory callback = Callback({
            requestID: requestID,
            numWords: numWords,
            requester: msg.sender,
            arguments: arguments,
            subID: subID,
            gasAllowance: callbackGasLimit,
            gasPrice: 0,
            weiPerUnitLink: 0
        });

        // Get cost-related values from billing.
        uint256 costJuels;
        uint96 balance;
        (
            costJuels,
            callback.weiPerUnitLink,
            callback.gasPrice,
            balance
        ) = billSubscriberForCallback(callback); // throws on failure

        // Record the callback so that it can only be played once. This is checked
        // in VRFBeaconReport.processCallback, and the entry is then deleted
        s_callbackMemo[requestID] = keccak256(
            abi.encode(nextBeaconOutputHeight, confDelayArg, subID, callback)
        );

        // Struct used to avoid stack-too-deep error.
        RandomnessLogPayload memory log = RandomnessLogPayload({
            requestID: requestID,
            requester: msg.sender,
            nextBeaconOutputHeight: nextBeaconOutputHeight,
            confirmationDelayArg: ConfirmationDelay.wrap(confDelayArg),
            subID: subID,
            numWords: numWords,
            callbackGasLimit: callbackGasLimit,
            callback: callback,
            arguments: arguments,
            costJuels: costJuels,
            balance: balance
        });

        emit RandomnessFulfillmentRequested(
            log.requestID,
            log.requester,
            log.nextBeaconOutputHeight,
            log.confirmationDelayArg,
            log.subID,
            log.numWords,
            log.callbackGasLimit,
            log.callback.gasPrice,
            log.callback.weiPerUnitLink,
            log.arguments,
            log.costJuels,
            log.balance
        );

        return RequestID.unwrap(requestID);
    }

    struct RandomnessLogPayload {
        RequestID requestID;
        address requester;
        uint64 nextBeaconOutputHeight;
        ConfirmationDelay confirmationDelayArg;
        uint256 subID;
        uint16 numWords;
        uint32 callbackGasLimit;
        Callback callback;
        bytes arguments;
        uint256 costJuels;
        uint96 balance;
    }

    // Used to track pending callbacks by their keccak256 hash
    mapping(RequestID => bytes32) internal s_callbackMemo;

    function getCallbackMemo(RequestID requestId)
        public
        view
        returns (bytes32)
    {
        return s_callbackMemo[requestId];
    }

    /// @inheritdoc IVRFMigratableCoordinator
    function redeemRandomness(
        uint256 subID,
        uint256 requestIDArg,
        bytes memory /* extraArgs */
    ) public override nonReentrant returns (uint256[] memory randomness) {
        RequestID requestID = RequestID.wrap(requestIDArg);
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

        emit RandomnessRedeemed(requestID, msg.sender, subID);

        return
            finalOutput(
                requestID,
                r,
                s_seedByBlockHeight[
                    getSeedByBlockheightKey(blockHeight, r.confirmationDelay)
                ],
                uint64(blockHeight)
            );
    }

    /// @notice Emitted when the recentBlockHash is older than some of the VRF
    /// @notice outputs it's being used to sign.
    ///
    /// @param reportHeight height of the VRF output which is younger than the recentBlockHash
    /// @param separatorHeight recentBlockHeight in the report
    error HistoryDomainSeparatorTooOld(
        uint64 reportHeight,
        uint64 separatorHeight
    );

    function getSeedByBlockheightKey(
        uint256 blockHeight,
        ConfirmationDelay confDelay
    ) internal pure returns (uint256) {
        return
            uint256((blockHeight << 24) | ConfirmationDelay.unwrap(confDelay));
    }

    /// @dev Stores the VRF outputs received so far, indexed by the block heights
    /// @dev they're associated with
    mapping(uint256 => bytes32) s_seedByBlockHeight; /* block height + confirmation delay */ /* seed */

    error ProducerAlreadyInitialized(address producer);

    function setProducer(address producer) external onlyOwner {
        if (s_producer != address(0)) {
            revert ProducerAlreadyInitialized(s_producer);
        }
        s_producer = producer;
    }

    error MustBeProducer();

    modifier validateProducer() {
        if (msg.sender != s_producer) {
            revert MustBeProducer();
        }
        _;
    }

    /// @inheritdoc IVRFCoordinatorProducerAPI
    function processVRFOutputs(
        VRFOutput[] calldata vrfOutputs,
        uint192 juelsPerFeeCoin,
        uint64 reasonableGasPrice,
        uint64 blockHeight,
        bytes32 /* blockHash */
    )
        external
        override
        validateProducer
        whenNotPaused
        returns (OutputServed[] memory outputs)
    {
        // For a new valid jueslPerFeeCoin report by the OCR committee,
        // update local info.
        if (juelsPerFeeCoin != 0) {
            s_hotBillingConfig.lastReportTimestamp = uint32(block.timestamp);
            s_hotBillingConfig.weiPerUnitLink = uint96(juelsPerFeeCoin);
        }

        uint16 numOutputs;
        OutputServed[] memory outputsServedFull = new OutputServed[](
            vrfOutputs.length
        );
        for (uint256 i = 0; i < vrfOutputs.length; i++) {
            VRFOutput memory r = vrfOutputs[i];
            processVRFOutput(r, blockHeight, juelsPerFeeCoin);
            if (r.vrfOutput.p[0] != 0 || r.vrfOutput.p[1] != 0) {
                outputsServedFull[numOutputs] = OutputServed({
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
            juelsPerFeeCoin,
            reasonableGasPrice,
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
            seed = s_seedByBlockHeight[
                getSeedByBlockheightKey(
                    output.blockHeight,
                    output.confirmationDelay
                )
            ];
        } else {
            // We trust the committee to only sign off on reports with valid VRF
            // proofs
            seed = keccak256(abi.encode(output.vrfOutput));
            s_seedByBlockHeight[
                getSeedByBlockheightKey(
                    output.blockHeight,
                    output.confirmationDelay
                )
            ] = seed;
        }
        uint256 numCallbacks = output.callbacks.length;
        processCallbacks(numCallbacks, seed, output);
    }

    // Process callbacks for a report's ouput.
    function processCallbacks(
        uint256 numCallbacks,
        bytes32 seed,
        VRFOutput memory output
    ) internal {
        RequestID[] memory fulfilledRequests = new RequestID[](numCallbacks);
        bytes memory successfulFulfillment = new bytes(numCallbacks);
        bytes[] memory errorData = new bytes[](numCallbacks);
        uint16 errorCount = 0;
        uint96[] memory subBalances = new uint96[](numCallbacks);
        uint256[] memory subIDs = new uint256[](numCallbacks);

        for (uint256 j = 0; j < numCallbacks; j++) {
            // We trust the committee to only sign off on reports with valid,
            // requested callbacks.
            CostedCallback memory callback = output.callbacks[j];
            (
                bool isErr,
                bytes memory errmsg,
                uint96 subBalance
            ) = processCallback(
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
            subBalances[j] = subBalance;
            subIDs[j] = callback.callback.subID;
        }

        if (output.callbacks.length > 0) {
            bytes[] memory truncatedErrorData = new bytes[](errorCount);
            for (uint256 j = 0; j < errorCount; j++) {
                truncatedErrorData[j] = errorData[j];
            }
            emit RandomWordsFulfilled(
                fulfilledRequests,
                successfulFulfillment,
                truncatedErrorData,
                subBalances,
                subIDs
            );
        }
    }

    /// @dev Errors when gas left is less than gas allowance
    /// @dev This error indicates that sum of all callback gas allowances in the report
    /// @dev exceeded supplied gas for transmission
    error GasAllowanceExceedsGasLeft(uint256 gasAllowance, uint256 gasLeft);

    function processCallback(
        // extracted to deal with stack-depth issue
        uint64 blockHeight,
        ConfirmationDelay confDelay,
        bytes32 seed,
        CostedCallback memory c
    )
        internal
        returns (
            bool isErr,
            bytes memory errmsg,
            uint96 subBalance
        )
    {
        Subscription storage sub = s_subscriptions[c.callback.subID];

        // We trust the committee to only sign off on reports with valid beacon
        // heights which are small enough to fit in a SlotNumber.
        SlotNumber slotNum = SlotNumber.wrap(
            uint32(blockHeight / i_beaconPeriodBlocks)
        );
        Callback memory cb = c.callback;
        {
            // scoped to avoid stack too deep error
            bytes32 cbCommitment = keccak256(
                abi.encode(blockHeight, confDelay, cb.subID, cb)
            );
            if (cbCommitment != s_callbackMemo[cb.requestID]) {
                return (true, "unknown callback", sub.balance);
            }
        }
        BeaconRequest memory request = BeaconRequest({
            slotNumber: slotNum,
            confirmationDelay: confDelay,
            numWords: cb.numWords,
            requester: cb.requester
        });
        // don't revert in this case as reversion could introduce DoS attacks
        if (seed == bytes32(0)) {
            return (true, bytes("unavailable randomness"), sub.balance);
        }
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
            RequestID.unwrap(cb.requestID),
            fOutput,
            cb.arguments
        );
        s_reentrancyLock = true;
        bool success;
        uint256 gasBefore = gasleft();
        {
            // scoped to avoid stack too deep error
            bool sufficientGas;
            (success, sufficientGas) = callWithExactGasEvenIfTargetIsNoContract(
                c.callback.gasAllowance,
                cb.requester,
                resp
            );
            if (!sufficientGas) {
                revert GasAllowanceExceedsGasLeft(
                    uint256(c.callback.gasAllowance),
                    gasBefore
                );
            }
        }
        // Refund the user, excluding the gas used in the exact gas call check.
        // Ensure that more than CALL_WITH_EXACT_GAS_CUSHION was used to prevent an
        // underflow.
        uint256 gasAfter = gasleft() + CALL_WITH_EXACT_GAS_CUSHION;
        s_reentrancyLock = false;
        if (gasAfter < gasBefore) {
            refundCallback(gasBefore - gasAfter, c.callback);
        }
        sub.pendingFulfillments--;

        // Delete callback memo and return result of the callback.
        delete s_callbackMemo[cb.requestID];
        // if the required method code is missing in the target or if
        // the target is non-contract, we still return success (we don't care
        // about false success in this case).
        return
            success
                ? (false, bytes(""), sub.balance)
                : (true, bytes("execution failed"), sub.balance);
    }

    uint256 private constant CALL_WITH_EXACT_GAS_CUSHION = 3_000;

    /**
     * @dev calls target address with exactly gasAmount gas and data as calldata
     * or reverts if at least gasAmount gas is not available.
     */
    function callWithExactGasEvenIfTargetIsNoContract(
        uint256 gasAmount,
        address target,
        bytes memory data
    ) internal returns (bool success, bool sufficientGas) {
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
                if gt(sub(g, div(g, 64)), gasAmount) {
                    // Call and receive the result of call. Note that we did not check
                    // whether a contract actually exists at the _target address.
                    success := call(
                        gasAmount, // gas
                        target, // address of target contract
                        0, // value
                        add(data, 0x20), // inputs
                        mload(data), // inputs size
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

    /// @param beaconPeriodBlocksArg number of blocks between beacon outputs
    constructor(uint256 beaconPeriodBlocksArg, address linkToken)
        VRFBeaconBilling(linkToken)
    {
        if (beaconPeriodBlocksArg == 0) {
            revert BeaconPeriodMustBePositive();
        }
        i_beaconPeriodBlocks = beaconPeriodBlocksArg;

        // Warm up nonce so that the first request does not incur extra gas.
        s_requestParams.nonce++;
    }

    /// @notice Emitted when beaconPeriodBlocksArg is zero
    error BeaconPeriodMustBePositive();

    /// @notice Emitted when the blockHeight doesn't fit in uint64
    error UniverseHasEndedBangBangBang(uint256 blockHeight);

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

    /* XXX: Check that this really fits into a word. Does the compiler do the
     right thing with a custom type like ConfirmationDelay? */
    struct RequestParams {
        /// @dev Incremented on each new request; used to disambiguate requests.
        /// @dev nonce is mixed with subID, msg.sender and address(this) and hashed
        /// @dev to create a unique requestID.
        uint48 nonce;
        ConfirmationDelay[NUM_CONF_DELAYS] confirmationDelays;

        // Use extra 16 bits to specify a premium? /* XXX:  */
    }

    RequestParams s_requestParams;

    mapping(RequestID => BeaconRequest) public s_pendingRequests;

    function nextBeaconOutputHeightAndSlot()
        private
        view
        returns (uint256, SlotNumber)
    {
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
        return (nextBeaconOutputHeight, slotNumber);
    }

    function computeRequestID(
        uint256 subID,
        address requester,
        uint48 nonce
    ) internal view returns (RequestID) {
        return
            RequestID.wrap(
                uint256(
                    keccak256(
                        abi.encode(address(this), subID, requester, nonce)
                    )
                )
            );
    }

    /// returns the information common to both types of requests: The requestID,
    /// the BeaconRequest data, and the height of the VRF output
    function beaconRequest(
        uint256 subID,
        address requester,
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
        if (numWords > MAX_NUM_WORDS) {
            revert TooManyWords(numWords, MAX_NUM_WORDS);
        }
        if (numWords == 0) {
            revert NoWordsRequested();
        }
        (
            uint256 nextBeaconOutputHeight,
            SlotNumber slotNumber
        ) = nextBeaconOutputHeightAndSlot();
        uint48 nonce = s_requestParams.nonce;
        RequestID requestID = computeRequestID(subID, requester, nonce);
        RequestParams memory rp = s_requestParams;
        // Ensure next request has unique nonce
        s_requestParams.nonce = nonce + 1;

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
            requester: requester
        });
        return (requestID, r, uint64(nextBeaconOutputHeight));
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
            // this could happen only if called from redeemRandomness(), as in
            // processCallback() we check that the seed isn't zero before calling
            // this method.
            revert RandomnessNotAvailable(requestID, blockHeight);
        }
        bytes32 finalSeed = keccak256(abi.encode(requestID, r, seed));
        if (r.numWords > MAX_NUM_WORDS) {
            // Could happen if corrupted quorum submits
            revert TooManyWords(r.numWords, MAX_NUM_WORDS);
        }
        uint256[] memory randomness = new uint256[](r.numWords);
        for (uint16 i = 0; i < r.numWords; i++) {
            randomness[i] = uint256(keccak256(abi.encodePacked(finalSeed, i)));
        }
        return randomness;
    }

    /// @inheritdoc IVRFCoordinatorProducerAPI
    function transferLink(address recipient, uint256 juelsAmount)
        public
        override
        validateProducer
    {
        // Poses no re-entrancy issues, because i_link.transfer does not yield
        // control flow.
        if (!i_link.transfer(recipient, juelsAmount)) {
            revert InsufficientBalance(
                i_link.balanceOf(address(this)),
                juelsAmount
            );
        }
    }

    error InvalidNumberOfRecipients(uint256 numRecipients);
    error RecipientsPaymentsMismatch(
        uint256 numRecipients,
        uint256 numPayments
    );

    /// @inheritdoc IVRFCoordinatorProducerAPI
    function batchTransferLink(
        address[] calldata recipients,
        uint256[] calldata paymentsInJuels
    ) external override validateProducer {
        uint256 numRecipients = recipients.length;
        if (numRecipients == 0 || numRecipients > MAX_NUM_ORACLES) {
            revert InvalidNumberOfRecipients(numRecipients);
        }
        if (numRecipients != paymentsInJuels.length) {
            revert RecipientsPaymentsMismatch(
                numRecipients,
                paymentsInJuels.length
            );
        }
        for (
            uint256 recipientidx = 0;
            recipientidx < numRecipients;
            recipientidx++
        ) {
            // Poses no re-entrancy issues, because i_link.transfer does not yield
            // control flow.
            transferLink(
                recipients[recipientidx],
                paymentsInJuels[recipientidx]
            );
        }
    }

    /// @inheritdoc IVRFCoordinatorProducerAPI
    function getSubscriptionLinkBalance()
        external
        view
        override
        returns (uint256 balance)
    {
        return uint256(s_subscriptionBalance);
    }

    /// @inheritdoc IVRFCoordinatorProducerAPI
    /// @dev can only be called by producer (call setProducer)
    function setConfirmationDelays(
        ConfirmationDelay[NUM_CONF_DELAYS] calldata confDelays
    ) external override validateProducer {
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

    /// @inheritdoc IVRFCoordinatorProducerAPI
    function setReasonableGasPrice(uint64 gasPrice)
        external
        override
        validateProducer
    {
        if (s_billingConfig.useReasonableGasPrice) {
            s_hotBillingConfig.reasonableGasPrice = gasPrice;
            s_hotBillingConfig.reasonableGasPriceLastBlockNumber = uint64(
                block.number
            );
        }
    }

    /// @dev Calling pause() blocks following functions:
    /// @dev addConsumer/createSubscription/onTokenTransfer/
    /// @dev processVRFOutputs/requestRandomness/requestRandomnessFulfillment
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /***************************************************************************
     * Section: Billing
     **************************************************************************/

    /**
     * @inheritdoc IVRFMigratableCoordinator
     */
    function getFee(
        uint256, /*subID*/
        bytes memory /*extraArgs*/
    ) external view override returns (uint256) {
        return
            uint256(
                calculateRequestPriceJuelsInternal(
                    s_billingConfig,
                    s_hotBillingConfig
                )
            );
    }

    /**
     * @inheritdoc IVRFMigratableCoordinator
     */
    function getFulfillmentFee(
        uint256, /*subID*/
        uint32 callbackGasLimit,
        bytes memory arguments,
        bytes memory /*extraArgs*/
    ) external view override returns (uint256) {
        (uint96 cost, , ) = calculateRequestPriceCallbackJuelsInternal(
            callbackGasLimit,
            arguments,
            s_billingConfig,
            s_hotBillingConfig
        );
        return uint256(cost);
    }

    /***************************************************************************
     * Section: Migration
     ***************************************************************************/

    /// @dev encapsulates migration path
    struct V1MigrationRequest {
        uint8 toVersion;
        uint256 subID;
    }

    // @dev Length of abi-encoded V1MigrationRequest
    uint16 internal constant V1_MIGRATION_REQUEST_LENGTH = 64;

    /// @dev encapsulates data to be migrated from current coordinator
    struct V1MigrationData {
        uint8 fromVersion;
        uint256 subID;
        address subOwner;
        address[] consumers;
        uint96 balance;
    }

    /// @notice emitted when migration to new coordinator completes successfully
    /// @param newVersion migration version of new coordinator
    /// @param newCoordinator coordinator address after migration
    /// @param subID migrated subscription ID
    event MigrationCompleted(
        uint8 indexed newVersion,
        address newCoordinator,
        uint256 indexed subID
    );

    /// @dev Emitted when new coordinator is registered as migratable target
    event CoordinatorRegistered(address coordinatorAddress);

    /// @dev Emitted when new coordinator is deregistered
    event CoordinatorDeregistered(address coordinatorAddress);

    /// @notice emitted when onMigration() is called
    error OnMigrationNotSupported();

    /// @notice emitted when migrate() is called and given coordinator is not registered as migratable target
    error CoordinatorNotRegistered(address coordinatorAddress);

    /// @notice emitted when migrate() is called and given coordinator is registered as migratable target
    error CoordinatorAlreadyRegistered(address coordinatorAddress);

    /// @notice emitted when requested version doesn't match the version of coordinator
    /// @param requestedVersion version number is V1MigrationRequest
    /// @param coordinatorVersion version number of new coordinator
    error MigrationVersionMismatch(
        uint8 requestedVersion,
        uint8 coordinatorVersion
    );

    function registerMigratableCoordinator(address target) external onlyOwner {
        if (!s_migrationTargets.add(target)) {
            revert CoordinatorAlreadyRegistered(target);
        }
        emit CoordinatorRegistered(target);
    }

    function deregisterMigratableCoordinator(address target)
        external
        onlyOwner
    {
        if (!s_migrationTargets.contains(target)) {
            revert CoordinatorNotRegistered(target);
        }
        s_migrationTargets.remove(target);
        emit CoordinatorDeregistered(target);
    }

    /**
     * @inheritdoc IVRFMigration
     */
    function migrate(
        IVRFMigration newCoordinator,
        bytes calldata encodedRequest
    ) external nonReentrant {
        if (!s_migrationTargets.contains(address(newCoordinator))) {
            revert CoordinatorNotRegistered(address(newCoordinator));
        }

        if (encodedRequest.length != V1_MIGRATION_REQUEST_LENGTH) {
            revert InvalidCalldata(
                V1_MIGRATION_REQUEST_LENGTH,
                encodedRequest.length
            );
        }

        V1MigrationRequest memory request = abi.decode(
            encodedRequest,
            (V1MigrationRequest)
        );

        (
            uint96 balance,
            uint64 pendingFulfillments,
            address subOwner,
            address[] memory consumers
        ) = getSubscription(request.subID);

        if (msg.sender != subOwner) {
            revert MustBeSubOwner(subOwner);
        }

        if (request.toVersion != newCoordinator.migrationVersion()) {
            revert MigrationVersionMismatch(
                request.toVersion,
                newCoordinator.migrationVersion()
            );
        }

        if (pendingFulfillments > 0) {
            revert PendingRequestExists();
        }

        V1MigrationData memory migrationData = V1MigrationData({
            fromVersion: migrationVersion(),
            subID: request.subID,
            subOwner: subOwner,
            consumers: consumers,
            balance: balance
        });
        bytes memory encodedData = abi.encode(migrationData);
        deleteSubscription(request.subID);
        s_subscriptionBalance -= uint96(balance);

        require(
            i_link.transfer(address(newCoordinator), balance),
            "insufficient funds"
        );
        newCoordinator.onMigration(encodedData);

        for (uint256 i = 0; i < consumers.length; i++) {
            IVRFCoordinatorConsumer(consumers[i]).setCoordinator(
                address(newCoordinator)
            );
        }

        emit MigrationCompleted(
            request.toVersion,
            address(newCoordinator),
            request.subID
        );
    }

    /**
     * @inheritdoc IVRFMigration
     */
    function onMigration(
        bytes calldata /* encodedData */
    ) external pure {
        // this contract is the oldest version. Therefore, migrating to this
        // current contract is not supported.
        revert OnMigrationNotSupported();
    }

    /**
     * @inheritdoc IVRFMigration
     */
    function migrationVersion() public pure returns (uint8 version) {
        return 1;
    }

    function typeAndVersion() external pure override returns (string memory) {
        return "VRFCoordinator 1.0.0";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {LinkTokenInterface} from "./vendor/ocr2-contracts/interfaces/LinkTokenInterface.sol";
import {VRFBeaconTypes} from "./VRFBeaconTypes.sol";
import {OwnerIsCreator} from "./vendor/ocr2-contracts/OwnerIsCreator.sol";
import {ISubscription} from "./ISubscription.sol";
import {IERC677Receiver} from "./IERC677Receiver.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

abstract contract VRFBeaconBilling is
    OwnerIsCreator,
    ISubscription,
    IERC677Receiver,
    Pausable
{
    LinkTokenInterface public immutable i_link; // Address of LINK token contract

    // We need to maintain a list of consuming addresses.
    // This bound ensures we are able to loop over them as needed.
    // Should a user require more consumers, they can use multiple subscriptions.
    uint96 public constant MAX_JUELS_SUPPLY = 1e27;
    uint16 public constant MAX_CONSUMERS = 100;
    uint64 private s_currentSubNonce; // subscription nonce used to construct subID. Rises monotonically

    // s_subscriptionBalance tracks the total link sent to
    // this contract through onTokenTransfer
    // A discrepancy with this contract's link balance indicates someone
    // sent tokens using transfer and so we may need to use VRFBeaconOCR.withdrawFunds.
    uint96 internal s_subscriptionBalance;
    // Note bool value indicates whether a consumer is assigned to given subId
    mapping(uint256 => bool) /* consumer+subId */ /* subscribed? */
        private s_consumers;

    // Billing configuration struct.
    VRFBeaconTypes.BillingConfig public s_billingConfig;

    // Reentrancy protection.
    bool internal s_reentrancyLock;

    VRFBeaconTypes.HotBillingConfig internal s_hotBillingConfig;

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
    mapping(uint256 => SubscriptionConfig) /* subId */ /* subscriptionConfig */
        private s_subscriptionConfigs;

    struct Subscription {
        // There are only 1e9*1e18 = 1e27 juels in existence, so the balance can fit in uint96 (2^96 ~ 7e28)
        uint96 balance; // Common link balance used for all consumer requests.
        uint64 pendingFulfillments; // For checking pending requests
    }
    mapping(uint256 => Subscription) /* subId */ /* subscription */
        internal s_subscriptions;

    event SubscriptionCreated(uint256 indexed subId, address indexed owner);
    event SubscriptionOwnerTransferRequested(
        uint256 indexed subId,
        address from,
        address to
    );
    event SubscriptionOwnerTransferred(
        uint256 indexed subId,
        address from,
        address to
    );
    event SubscriptionConsumerAdded(uint256 indexed subId, address consumer);
    event SubscriptionConsumerRemoved(uint256 indexed subId, address consumer);
    event SubscriptionCanceled(
        uint256 indexed subId,
        address to,
        uint256 amount
    );
    event SubscriptionFunded(
        uint256 indexed subId,
        uint256 oldBalance,
        uint256 newBalance
    );
    event BillingConfigSet(VRFBeaconTypes.BillingConfig billingConfig);

    /// @dev Emitted when a subscription for a given ID cannot be found
    error InvalidSubscription(uint256 requestedSubID);
    /// @dev Emitted when sender is not authorized to make the requested change to
    /// @dev the subscription
    error MustBeSubOwner(address owner);
    /// @dev Emitted when consumer is not registered for the subscription
    error InvalidConsumer(uint256 subId, address consumer);
    /// @dev Emitted when number of consumer will exceed MAX_CONSUMERS
    error TooManyConsumers();
    /// @dev Emmited when balance is insufficient
    error InsufficientBalance(uint256 actualBalance, uint256 requiredBalance);
    /// @dev Emmited when msg.sender is not the requested owner
    error MustBeRequestedOwner(address proposedOwner);
    /// @dev Emmited when subscription can't be cancelled because of pending requests
    error PendingRequestExists();
    /// @dev Emitted when caller transfers tokens other than LINK
    error OnlyCallableFromLink();
    /// @dev Emitted when calldata is invalid
    error InvalidCalldata(uint16 expectedLength, uint256 actualLength);
    /// @dev Emitted when a client contract attempts to re-enter a state-changing
    /// @dev coordinator method.
    error Reentrant();
    /// @dev Emitted when the number of Juels from a conversion exceed the token supply.
    error InvalidJuelsConversion();
    /// @dev Emitted when an invalid billing config update was attempted.
    error InvalidBillingConfig();

    constructor(address link) OwnerIsCreator() {
        i_link = LinkTokenInterface(link);

        // Warm up s_hotBillingConfig and s_billingConfig.
        // Without a manual setBillingConfig, use .01 native gas token per unit link,
        // with no staleness, and default to tx.gasprice().
        s_hotBillingConfig = VRFBeaconTypes.HotBillingConfig({
            lastReportTimestamp: 0,
            weiPerUnitLink: 10000000000000000,
            reasonableGasPrice: 0,
            reasonableGasPriceLastBlockNumber: 0
        });
        s_billingConfig.stalenessSeconds = type(uint32).max;
    }

    /// @notice setBillingConfig updates the contract's billing config.
    function setBillingConfig(
        VRFBeaconTypes.BillingConfig calldata billingConfig
    ) external onlyOwner {
        if (billingConfig.unusedGasPenaltyPercent > 100) {
            revert InvalidBillingConfig();
        }
        s_billingConfig = billingConfig;
        emit BillingConfigSet(billingConfig);
    }

    // getFeedData returns the most recent LINK/ETH ratio,
    // "ETH" being the native gas token of a given network.
    function getFeedData(
        VRFBeaconTypes.BillingConfig memory billingConfig,
        VRFBeaconTypes.HotBillingConfig memory hotBillingConfig
    ) internal view returns (uint256) {
        uint32 stalenessSeconds = billingConfig.stalenessSeconds;
        bool staleFallback = billingConfig.stalenessSeconds > 1;
        uint96 weiPerUnitLink = hotBillingConfig.weiPerUnitLink;
        if (
            staleFallback &&
            (stalenessSeconds <
                block.timestamp - hotBillingConfig.lastReportTimestamp)
        ) {
            weiPerUnitLink = billingConfig.fallbackWeiPerUnitLink;
        }
        return uint256(weiPerUnitLink);
    }

    // billSubscriberForRequest calculates the cost of a beacon request in Juels,
    // and bills the user's subscription.
    function billSubscriberForRequest(address requester, uint256 subID)
        internal
        returns (uint256, uint96)
    {
        VRFBeaconTypes.HotBillingConfig
            memory hotBillingConfig = s_hotBillingConfig;
        VRFBeaconTypes.BillingConfig memory billingConfig = s_billingConfig;

        if (!s_consumers[getConsumerKey(requester, subID)]) {
            revert InvalidConsumer(subID, requester);
        }

        // Calculate the request price.
        uint256 costJuels = calculateRequestPriceJuelsInternal(
            billingConfig,
            hotBillingConfig
        );

        // Bill user if the subscription is funded, otherwise revert.
        Subscription storage sub = s_subscriptions[subID];
        uint96 balance = sub.balance; // Avoid double SLOAD
        if (balance < costJuels) {
            revert InsufficientBalance(sub.balance, costJuels);
        }
        unchecked {
            balance -= uint96(costJuels);
            sub.balance = balance;
            s_subscriptionBalance -= uint96(costJuels);
        }
        return (costJuels, balance);
    }

    // billSubscriberForCallback calculates the cost of a callback request in Juels,
    // and bills the user's subscription.
    function billSubscriberForCallback(VRFBeaconTypes.Callback memory callback)
        internal
        returns (
            uint256, // costJuels
            uint256, // weiPerUnitLink
            uint256, // gasPrice
            uint96 // balance
        )
    {
        if (!s_consumers[getConsumerKey(callback.requester, callback.subID)]) {
            revert InvalidConsumer(callback.subID, callback.requester);
        }

        VRFBeaconTypes.HotBillingConfig
            memory hotBillingConfig = s_hotBillingConfig;
        VRFBeaconTypes.BillingConfig memory billingConfig = s_billingConfig;

        // Calculate the request price.
        (
            uint256 costJuels,
            uint256 weiPerUnitLink,
            uint256 gasPrice
        ) = calculateRequestPriceCallbackJuelsInternal(
                callback.gasAllowance,
                callback.arguments,
                billingConfig,
                hotBillingConfig
            );

        // Bill user if the subscription is funded, otherwise revert.
        Subscription storage sub = s_subscriptions[callback.subID];
        if (sub.balance < costJuels) {
            revert InsufficientBalance(sub.balance, costJuels);
        }
        uint96 newSubBalance;
        unchecked {
            sub.pendingFulfillments++;
            newSubBalance = sub.balance - uint96(costJuels);
            sub.balance = newSubBalance;
            s_subscriptionBalance -= uint96(costJuels);
        }
        return (costJuels, weiPerUnitLink, gasPrice, newSubBalance);
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
        (uint96 refundJuels, ) = convertToJuels(
            refundWei,
            callback.weiPerUnitLink,
            s_billingConfig,
            s_hotBillingConfig
        );

        // Refund the given subscription.
        s_subscriptions[callback.subID].balance += refundJuels;
        s_subscriptionBalance += refundJuels;
    }

    /// @notice calculateRequestPriceJuels calculates the request price in Juels
    /// @notice for a beacon request.
    function calculateRequestPriceJuelsInternal(
        VRFBeaconTypes.BillingConfig memory billingConfig,
        VRFBeaconTypes.HotBillingConfig memory hotBillingConfig
    ) internal view returns (uint96) {
        uint256 baseCost = billingConfig.redeemableRequestGasOverhead *
            getReasonableGasPrice(billingConfig, hotBillingConfig);
        (uint96 cost, ) = getFinalCostJuels(
            baseCost,
            0,
            billingConfig,
            hotBillingConfig
        );
        return cost;
    }

    /// @notice calculateRequestPriceCallback calculates the request price in Juels
    /// @notice for a callback request.
    function calculateRequestPriceCallbackJuelsInternal(
        uint96 gasAllowance,
        bytes memory arguments,
        VRFBeaconTypes.BillingConfig memory billingConfig,
        VRFBeaconTypes.HotBillingConfig memory hotBillingConfig
    )
        internal
        view
        returns (
            uint96,
            uint256,
            uint256
        )
    {
        uint256 reasonableGasPrice = getReasonableGasPrice(
            billingConfig,
            hotBillingConfig
        );
        uint256 gasCostPerByte = reasonableGasPrice * 16;
        uint256 baseCost = (gasAllowance +
            billingConfig.callbackRequestGasOverhead) *
            reasonableGasPrice +
            arguments.length *
            ((gasCostPerByte * 21) / 20); // 105%
        (uint96 finalCost, uint256 weiPerUnitLink) = getFinalCostJuels(
            baseCost,
            0,
            billingConfig,
            hotBillingConfig
        );
        return (finalCost, weiPerUnitLink, reasonableGasPrice);
    }

    // getFinalCostJuels adds the premium percentage to the base cost of a request,
    // and converts that cost to Juels.
    function getFinalCostJuels(
        uint256 baseCost,
        uint256 localFeedData,
        VRFBeaconTypes.BillingConfig memory billingConfig,
        VRFBeaconTypes.HotBillingConfig memory hotBillingConfig
    ) internal view returns (uint96, uint256) {
        // Calculate raw wei cost with added premium.
        uint256 premiumCost = (baseCost *
            (billingConfig.premiumPercentage + 100)) / 100;

        // Convert wei cost to Juels.
        return
            convertToJuels(
                premiumCost,
                localFeedData,
                billingConfig,
                hotBillingConfig
            );
    }

    // convertToJuels converts a given weiAmount to Juels.
    // There are only 1e9*1e18 = 1e27 juels in existence,
    // so the return should always fit into a uint96 (2^96 ~ 7e28).
    function convertToJuels(
        uint256 weiAmount,
        uint256 localFeedData,
        VRFBeaconTypes.BillingConfig memory billingConfig,
        VRFBeaconTypes.HotBillingConfig memory hotBillingConfig
    ) private view returns (uint96, uint256) {
        uint256 weiPerUnitLink = localFeedData == 0
            ? getFeedData(billingConfig, hotBillingConfig)
            : localFeedData;
        uint256 juelsAmount = (1e18 * weiAmount) / weiPerUnitLink;
        if (juelsAmount > MAX_JUELS_SUPPLY) {
            revert InvalidJuelsConversion();
        }
        return (uint96(juelsAmount), weiPerUnitLink);
    }

    /**
     * @inheritdoc ISubscription
     */
    function createSubscription()
        external
        override
        nonReentrant
        whenNotPaused
        returns (uint256)
    {
        uint256 subId = uint256(
            keccak256(
                abi.encodePacked(
                    msg.sender,
                    blockhash(block.number - 1),
                    address(this),
                    s_currentSubNonce
                )
            )
        );
        s_currentSubNonce++;
        address[] memory consumers = new address[](0);
        s_subscriptions[subId] = Subscription({
            balance: 0,
            pendingFulfillments: 0
        });
        s_subscriptionConfigs[subId] = SubscriptionConfig({
            owner: msg.sender,
            requestedOwner: address(0),
            consumers: consumers
        });

        emit SubscriptionCreated(subId, msg.sender);
        return subId;
    }

    /**
     * @inheritdoc ISubscription
     */
    function getSubscription(uint256 subId)
        public
        view
        override
        returns (
            uint96 balance,
            uint64 pendingFulfillments,
            address owner,
            address[] memory consumers
        )
    {
        if (s_subscriptionConfigs[subId].owner == address(0)) {
            revert InvalidSubscription(subId);
        }
        return (
            s_subscriptions[subId].balance,
            s_subscriptions[subId].pendingFulfillments,
            s_subscriptionConfigs[subId].owner,
            s_subscriptionConfigs[subId].consumers
        );
    }

    /**
     * @inheritdoc ISubscription
     */
    function requestSubscriptionOwnerTransfer(uint256 subId, address newOwner)
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
     * @inheritdoc ISubscription
     */
    function acceptSubscriptionOwnerTransfer(uint256 subId)
        external
        override
        nonReentrant
    {
        if (s_subscriptionConfigs[subId].owner == address(0)) {
            revert InvalidSubscription(subId);
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

    function getConsumerKey(address consumer, uint256 subId)
        internal
        pure
        returns (uint256)
    {
        return uint256((subId << 160) | uint160(consumer));
    }

    /**
     * @inheritdoc ISubscription
     */
    function addConsumer(uint256 subId, address consumer)
        external
        override
        onlySubOwner(subId)
        nonReentrant
        whenNotPaused
    {
        // Already maxed, cannot add any more consumers.
        if (s_subscriptionConfigs[subId].consumers.length == MAX_CONSUMERS) {
            revert TooManyConsumers();
        }
        if (s_consumers[getConsumerKey(consumer, subId)]) {
            // Idempotence - do nothing if already added.
            // Ensures uniqueness in s_subscriptions[subId].consumers.
            return;
        }
        // Initialize the nonce to true, indicating the consumer is allocated.
        s_consumers[getConsumerKey(consumer, subId)] = true;
        s_subscriptionConfigs[subId].consumers.push(consumer);

        emit SubscriptionConsumerAdded(subId, consumer);
    }

    /**
     * @inheritdoc ISubscription
     */
    function removeConsumer(uint256 subId, address consumer)
        external
        override
        onlySubOwner(subId)
        validateNoPendingRequests(subId)
        nonReentrant
    {
        if (!s_consumers[getConsumerKey(consumer, subId)]) {
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
        delete s_consumers[getConsumerKey(consumer, subId)];
        emit SubscriptionConsumerRemoved(subId, consumer);
    }

    /**
     * @inheritdoc ISubscription
     */
    function cancelSubscription(uint256 subId, address to)
        external
        override
        onlySubOwner(subId)
        validateNoPendingRequests(subId)
        nonReentrant
    {
        Subscription memory sub = s_subscriptions[subId];
        uint96 balance = sub.balance;
        deleteSubscription(subId);
        uint96 totalBalance = s_subscriptionBalance;
        s_subscriptionBalance -= balance;
        if (!i_link.transfer(to, uint256(balance))) {
            revert InsufficientBalance(totalBalance, balance);
        }
        emit SubscriptionCanceled(subId, to, balance);
    }

    function deleteSubscription(uint256 subId) internal {
        SubscriptionConfig memory subConfig = s_subscriptionConfigs[subId];
        // Note bounded by MAX_CONSUMERS;
        // If no consumers, does nothing.
        for (uint256 i = 0; i < subConfig.consumers.length; i++) {
            delete s_consumers[getConsumerKey(subConfig.consumers[i], subId)];
        }
        delete s_subscriptionConfigs[subId];
        delete s_subscriptions[subId];
    }

    function onTokenTransfer(
        address, /* sender */
        uint256 amount,
        bytes calldata data
    ) external override nonReentrant whenNotPaused {
        if (msg.sender != address(i_link)) {
            revert OnlyCallableFromLink();
        }
        if (data.length != 32) {
            revert InvalidCalldata(32, data.length);
        }
        uint256 subId = abi.decode(data, (uint256));
        if (s_subscriptionConfigs[subId].owner == address(0)) {
            revert InvalidSubscription(subId);
        }
        // We do not check that the msg.sender is the subscription owner,
        // anyone can fund a subscription.
        uint256 oldBalance = s_subscriptions[subId].balance;
        s_subscriptions[subId].balance += uint96(amount);
        s_subscriptionBalance += uint96(amount);
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
    modifier onlySubOwner(uint256 subId) {
        address owner = s_subscriptionConfigs[subId].owner;
        if (owner == address(0)) {
            revert InvalidSubscription(subId);
        }
        if (msg.sender != owner) {
            revert MustBeSubOwner(owner);
        }
        _;
    }

    /// @dev reverts when subscription contains pending fulfillments
    /// @dev when a fulfillment is pending, removing a consumer or cancelling a subscription
    /// @dev should not be allowed
    modifier validateNoPendingRequests(uint256 subId) {
        if (s_subscriptions[subId].pendingFulfillments > 0) {
            revert PendingRequestExists();
        }
        _;
    }

    /// @dev Returns a reasonable gas price to use when billing the user for a
    /// @dev randomness request.
    function getReasonableGasPrice(
        VRFBeaconTypes.BillingConfig memory billingConfig,
        VRFBeaconTypes.HotBillingConfig memory hotBillingConfig
    ) internal view returns (uint64) {
        if (
            billingConfig.useReasonableGasPrice &&
            hotBillingConfig.reasonableGasPrice != 0
        ) {
            bool stalenessIsMoreThanTotalBlocks = block.number <
                billingConfig.reasonableGasPriceStalenessBlocks;
            if (
                stalenessIsMoreThanTotalBlocks || // prevents underflow
                (hotBillingConfig.reasonableGasPriceLastBlockNumber >=
                    block.number -
                        billingConfig.reasonableGasPriceStalenessBlocks)
            ) {
                return hotBillingConfig.reasonableGasPrice;
            }
        }
        return uint64(tx.gasprice);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ECCArithmetic} from "./ECCArithmetic.sol";
import {IVRFMigratableCoordinator} from "./IVRFMigratableCoordinator.sol";
import {OwnerIsCreator} from "./vendor/ocr2-contracts/OwnerIsCreator.sol";

abstract contract IVRFCoordinatorConsumer is OwnerIsCreator {
    IVRFMigratableCoordinator internal s_coordinator;

    constructor(address _coordinator) {
        s_coordinator = IVRFMigratableCoordinator(_coordinator);
    }

    event CoordinatorUpdated(address indexed coordinator);

    error MustBeOwnerOrCoordinator();

    // setCoordinator is called by the current coordinator during migration
    function setCoordinator(address coordinator) external {
        if (msg.sender != owner() && msg.sender != address(s_coordinator)) {
            revert MustBeOwnerOrCoordinator();
        }
        s_coordinator = IVRFMigratableCoordinator(coordinator);
        emit CoordinatorUpdated(coordinator);
    }

    function fulfillRandomWords(
        uint256 requestID,
        uint256[] memory response,
        bytes memory arguments
    ) internal virtual;

    error MustBeCoordinator();

    function rawFulfillRandomWords(
        uint256 requestID,
        uint256[] memory randomWords,
        bytes memory arguments
    ) external {
        if (address(s_coordinator) != msg.sender) {
            revert MustBeCoordinator();
        }
        fulfillRandomWords(requestID, randomWords, arguments);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

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
        uint64 reasonableGasPrice,
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

    /// @dev returns total subscription Link balance in the contract in juels
    function getSubscriptionLinkBalance()
        external
        view
        virtual
        returns (uint256 balance);

    /// @dev sets allowed confirmation delays
    function setConfirmationDelays(
        ConfirmationDelay[NUM_CONF_DELAYS] calldata confDelays
    ) external virtual;

    /// @dev sets the last reasonable gas price used for a report
    function setReasonableGasPrice(uint64 gasPrice) external virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

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
            if ((getBlockNumber() - blockNumber) > 256) {
                return "";
            }
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

interface TypeAndVersionInterface {
    function typeAndVersion() external pure returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

abstract contract IVRFMigratableCoordinator {
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
    /// @param subID subscription ID
    /// @param numWords number of uint256's of randomness to provide in response
    /// @param confirmationDelay minimum number of blocks before response
    /// @param extraArgs extra arguments
    /// @return ID of created request
    function requestRandomness(
        uint256 subID,
        uint16 numWords,
        uint24 confirmationDelay,
        bytes memory extraArgs
    ) external payable virtual returns (uint256);

    //////////////////////////////////////////////////////////////////////////////
    /// @notice Request a callback on the next available randomness output
    ///
    /// @notice The contract at the callback address must have a method
    /// @notice rawFulfillRandomness(bytes32,uint256,bytes). It will be called with
    /// @notice the ID returned by this function, the random value, and the
    /// @notice arguments value passed to this function.
    ///
    /// @dev No record of this commitment is stored onchain. The VRF committee is
    /// @dev trusted to only provide callbacks for valid requests.
    ///
    /// @param subID subscription ID
    /// @param numWords number of uint256's of randomness to provide in response
    /// @param confirmationDelay minimum number of blocks before response
    /// @param callbackGasLimit maximum gas allowed for callback function
    /// @param arguments data to return in response
    /// @param extraArgs extra arguments
    /// @return ID of created request
    function requestRandomnessFulfillment(
        uint256 subID,
        uint16 numWords,
        uint24 confirmationDelay,
        uint32 callbackGasLimit,
        bytes memory arguments,
        bytes memory extraArgs
    ) external payable virtual returns (uint256);

    //////////////////////////////////////////////////////////////////////////////
    /// @notice Get randomness for the given requestID
    /// @param requestID ID of request r for which to retrieve randomness
    /// @param extraArgs extra arguments
    /// @return randomness r.numWords random uint256's
    function redeemRandomness(
        uint256 subID,
        uint256 requestID,
        bytes memory extraArgs
    ) external virtual returns (uint256[] memory randomness);

    //////////////////////////////////////////////////////////////////////////////
    /// @notice gets request randomness price
    /// @param subID subscription ID
    /// @param extraArgs extra arguments
    /// @return fee amount in lowest denomination
    function getFee(uint256 subID, bytes memory extraArgs)
        external
        view
        virtual
        returns (uint256);

    //////////////////////////////////////////////////////////////////////////////
    /// @notice gets request randomness fulfillment price
    /// @param subID subscription ID
    /// @param callbackGasLimit maximum gas allowed for callback function
    /// @param arguments data to return in response
    /// @param extraArgs extra arguments
    /// @return fee amount in lowest denomination
    function getFulfillmentFee(
        uint256 subID,
        uint32 callbackGasLimit,
        bytes memory arguments,
        bytes memory extraArgs
    ) external view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IVRFMigratableCoordinator} from "./IVRFMigratableCoordinator.sol";

interface IVRFMigration {
    /**
     * @notice Migrates user data (e.g. balance, consumers) from one coordinator to another.
     * @notice only callable by the owner of user data
     * @param newCoordinator new coordinator instance
     * @param encodedRequest abi-encoded data that identifies that migrate() request (e.g. version to migrate to, user data ID)
     */
    function migrate(
        IVRFMigration newCoordinator,
        bytes calldata encodedRequest
    ) external;

    /**
     * @notice called by older versions of coordinator for migration.
     * @notice only callable by older versions of coordinator
     * @param encodedData - user data from older version of coordinator
     */
    function onMigration(bytes calldata encodedData) external;

    /**
     * @return version - current migration version
     */
    function migrationVersion() external pure returns (uint8 version);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
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
pragma solidity 0.8.19;

import {ECCArithmetic} from "./ECCArithmetic.sol";

// If these types are changed, the types in beaconObservation.proto and
// AbstractCostedCallbackRequest etc. probably need to change, too.
contract VRFBeaconTypes {
    type RequestID is uint256;
    uint48 internal constant MAX_NONCE = type(uint48).max;
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
        uint96 gasAllowance; // gas offered to callback method when called
        uint256 subID;
        uint256 gasPrice;
        uint256 weiPerUnitLink;
    }

    struct CostedCallback {
        Callback callback;
        uint96 price; // nominal price charged for the callback
    }

    /// @dev configuration parameters for billing that change per-report
    /// @dev total size: 256 bits
    struct HotBillingConfig {
        // lastReportTimestamp is the timestamp of the last report.
        uint32 lastReportTimestamp;
        // reasonableGasPriceLastBlockNumber is the block number of the
        // most recently-reported reasonableGasPrice.
        uint64 reasonableGasPriceLastBlockNumber;
        // The average gas price reported by the OCR committee.
        uint64 reasonableGasPrice;
        // Most recent LINK/ETH ratio.
        uint96 weiPerUnitLink;
    }

    /// @dev configuration parameters for billing
    /// @dev total size: 241 bits
    struct BillingConfig {
        // flag to enable/disable the use of reasonableGasPrice.
        bool useReasonableGasPrice;
        // Premium percentage charged.
        uint8 premiumPercentage;
        // Penalty in percent (max 100) for unused gas in an allowance.
        uint8 unusedGasPenaltyPercent;
        // stalenessSeconds is how long before we consider the feed price to be
        // stale and fallback to fallbackWeiPerUnitLink.
        uint32 stalenessSeconds;
        // Estimated gas cost for a beacon fulfillment.
        uint32 redeemableRequestGasOverhead;
        // Estimated gas cost for a callback fulfillment (excludes gas allowance).
        uint32 callbackRequestGasOverhead;
        // reasonableGasPriceStalenessBlocks is how long before we consider
        // the last reported average gas price to be valid before falling back to
        // tx.gasprice.
        uint32 reasonableGasPriceStalenessBlocks;
        // Fallback LINK/ETH ratio.
        uint96 fallbackWeiPerUnitLink;
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
    /// @param costJuels the cost in Juels of the randomness request
    event RandomnessRequested(
        RequestID indexed requestID,
        address requester,
        uint64 nextBeaconOutputHeight,
        ConfirmationDelay confDelay,
        uint256 subID,
        uint16 numWords,
        uint256 costJuels,
        uint256 newSubBalance
    );

    /// @dev Emitted when randomness is redeemed.
    ///
    /// @param requestID request identifier
    /// @param requester consumer contract
    event RandomnessRedeemed(
        RequestID indexed requestID,
        address indexed requester,
        uint256 subID
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
    /// @param costJuels the cost in Juels of the randomness request, pre-refund
    event RandomnessFulfillmentRequested(
        RequestID indexed requestID,
        address requester,
        uint64 nextBeaconOutputHeight,
        ConfirmationDelay confDelay,
        uint256 subID,
        uint16 numWords,
        uint32 gasAllowance,
        uint256 gasPrice,
        uint256 weiPerUnitLink,
        bytes arguments,
        uint256 costJuels,
        uint256 newSubBalance
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
        bytes[] truncatedErrorData,
        uint96[] subBalances,
        uint256[] subIDs
    );

    event NewTransmission(
        uint32 indexed aggregatorRoundId,
        uint40 indexed epochAndRound,
        address transmitter,
        uint192 juelsPerFeeCoin,
        uint64 reasonableGasPrice,
        bytes32 configDigest
    );

    event OutputsServed(
        uint64 recentBlockHeight,
        uint192 juelsPerFeeCoin,
        uint64 reasonableGasPrice,
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
pragma solidity 0.8.19;

interface ISubscription {
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
    function createSubscription() external returns (uint256 subId);

    /**
     * @notice Get a VRF subscription.
     * @param subId - ID of the subscription
     * @return balance - LINK balance of the subscription in juels.
     * @return pendingFulfillments - number of pending fulfillments.
     * @return owner - owner of the subscription.
     * @return consumers - list of consumer address which are able to use this subscription.
     */
    function getSubscription(uint256 subId)
        external
        view
        returns (
            uint96 balance,
            uint64 pendingFulfillments,
            address owner,
            address[] memory consumers
        );

    /**
     * @notice Request subscription owner transfer.
     * @param subId - ID of the subscription
     * @param newOwner - proposed new owner of the subscription
     */
    function requestSubscriptionOwnerTransfer(uint256 subId, address newOwner)
        external;

    /**
     * @notice Request subscription owner transfer.
     * @param subId - ID of the subscription
     * @dev will revert if original owner of subId has
     * not requested that msg.sender become the new owner.
     */
    function acceptSubscriptionOwnerTransfer(uint256 subId) external;

    /**
     * @notice Add a consumer to a VRF subscription.
     * @param subId - ID of the subscription
     * @param consumer - New consumer which can use the subscription
     */
    function addConsumer(uint256 subId, address consumer) external;

    /**
     * @notice Remove a consumer from a VRF subscription.
     * @param subId - ID of the subscription
     * @param consumer - Consumer to remove from the subscription
     */
    function removeConsumer(uint256 subId, address consumer) external;

    /**
     * @notice Cancel a subscription
     * @param subId - ID of the subscription
     * @param to - Where to send the remaining LINK to
     */
    function cancelSubscription(uint256 subId, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IERC677Receiver {
    function onTokenTransfer(
        address sender,
        uint256 amount,
        bytes calldata data
    ) external;
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
pragma solidity 0.8.19;

contract ECCArithmetic {
    // constant term in affine curve equation: y²=x³+b
    uint256 internal constant B = 3;

    // Base field for G1 is 𝔽ₚ
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-196.md#specification
    uint256 internal constant P =
        // solium-disable-next-line indentation
        0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47;

    // #E(𝔽ₚ), number of points on  G1/G2Add
    // https://github.com/ethereum/go-ethereum/blob/2388e42/crypto/bn256/cloudflare/constants.go#L23
    uint256 internal constant Q =
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
    uint256 internal constant G2_GEN_X_A =
        0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2;
    uint256 internal constant G2_GEN_X_B =
        0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed;
    uint256 internal constant G2_GEN_Y_A =
        0x090689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b;
    uint256 internal constant G2_GEN_Y_B =
        0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa;

    uint256 internal constant PAIRING_GAS_COST = 34_000 * 2 + 45_000; // Gas cost as of Istanbul; see EIP-1108
    uint256 internal constant PAIRING_PRECOMPILE_ADDRESS = 0x8;
    uint256 internal constant PAIRING_INPUT_LENGTH = 12 * 0x20;
    uint256 internal constant PAIRING_OUTPUT_LENGTH = 0x20;

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
        g2s[1] = G2Point([G2_GEN_X_A, G2_GEN_X_B, G2_GEN_Y_A, G2_GEN_Y_B]);
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
                PAIRING_GAS_COST,
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