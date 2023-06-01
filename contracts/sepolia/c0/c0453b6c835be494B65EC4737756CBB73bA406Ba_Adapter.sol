// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20, Address} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {IAdapter} from "./interfaces/IAdapter.sol";
import {IAdapterOwner} from "./interfaces/IAdapterOwner.sol";
import {IController} from "./interfaces/IController.sol";
import {IBasicRandcastConsumerBase} from "./interfaces/IBasicRandcastConsumerBase.sol";
import {RequestIdBase} from "./utils/RequestIdBase.sol";
import {RandomnessHandler} from "./utils/RandomnessHandler.sol";
import {BLS} from "./libraries/BLS.sol";
// solhint-disable-next-line no-global-import
import "./utils/Utils.sol" as Utils;

contract Adapter is UUPSUpgradeable, IAdapter, IAdapterOwner, RequestIdBase, RandomnessHandler, OwnableUpgradeable {
    using SafeERC20 for IERC20;
    using Address for address;

    // *Constants*
    uint16 public constant MAX_CONSUMERS = 100;
    uint16 public constant MAX_REQUEST_CONFIRMATIONS = 200;
    uint256 public constant RANDOMNESS_REWARD_GAS = 9000;
    uint256 public constant VERIFICATION_GAS_OVER_MINIMUM_THRESHOLD = 50000;
    uint256 public constant DEFAULT_MINIMUM_THRESHOLD = 3;

    // *State Variables*
    IController internal _controller;

    // Randomness Task State
    uint256 internal _lastAssignedGroupIndex;
    uint256 internal _lastRandomness;
    uint256 internal _randomnessCount;

    AdapterConfig internal _config;
    mapping(bytes32 => bytes32) internal _requestCommitments;
    /* consumerAddress - consumer */
    mapping(address => Consumer) internal _consumers;
    /* subId - subscription */
    mapping(uint64 => Subscription) internal _subscriptions;
    uint64 internal _currentSubId;

    // Referral Promotion
    ReferralConfig internal _referralConfig;

    // Flat Fee Promotion
    FlatFeeConfig internal _flatFeeConfig;

    // *Structs*
    // Note a nonce of 0 indicates an the consumer is not assigned to that subscription.
    struct Consumer {
        /* subId - nonce */
        mapping(uint64 => uint64) nonces;
        uint64 lastSubscription;
    }

    struct Subscription {
        address owner; // Owner can fund/withdraw/cancel the sub.
        address requestedOwner; // For safely transferring sub ownership.
        address[] consumers;
        uint256 balance; // Token balance used for all consumer requests.
        uint256 inflightCost; // Upper cost for pending requests(except drastic exchange rate changes).
        mapping(bytes32 => uint256) inflightPayments;
        uint64 reqCount; // For fee tiers
        uint64 freeRequestCount; // Number of free requests(flat fee) for this sub.
        uint64 referralSubId; //
        uint64 reqCountInCurrentPeriod;
        // Number of requests in the current period.
        uint256 lastRequestTimestamp; // Timestamp of the last request.
    }

    // *Events*
    event AdapterConfigSet(
        uint16 minimumRequestConfirmations,
        uint32 maxGasLimit,
        uint32 gasAfterPaymentCalculation,
        uint32 gasExceptCallback,
        uint256 signatureTaskExclusiveWindow,
        uint256 rewardPerSignature,
        uint256 committerRewardPerSignature
    );
    event FlatFeeConfigSet(
        FeeConfig flatFeeConfig,
        uint16 flatFeePromotionGlobalPercentage,
        bool isFlatFeePromotionEnabledPermanently,
        uint256 flatFeePromotionStartTimestamp,
        uint256 flatFeePromotionEndTimestamp
    );
    event ReferralConfigSet(
        bool isReferralEnabled, uint16 freeRequestCountForReferrer, uint16 freeRequestCountForReferee
    );
    event SubscriptionCreated(uint64 indexed subId, address indexed owner);
    event SubscriptionFunded(uint64 indexed subId, uint256 oldBalance, uint256 newBalance);
    event SubscriptionConsumerAdded(uint64 indexed subId, address consumer);
    event SubscriptionReferralSet(uint64 indexed subId, uint64 indexed referralSubId);
    event SubscriptionCanceled(uint64 indexed subId, address to, uint256 amount);
    event SubscriptionConsumerRemoved(uint64 indexed subId, address consumer);
    event RandomnessRequest(
        bytes32 indexed requestId,
        uint64 indexed subId,
        uint256 indexed groupIndex,
        RequestType requestType,
        bytes params,
        address sender,
        uint256 seed,
        uint16 requestConfirmations,
        uint256 callbackGasLimit,
        uint256 callbackMaxGasPrice,
        uint256 estimatedPayment
    );
    event RandomnessRequestResult(
        bytes32 indexed requestId,
        uint256 indexed groupIndex,
        address indexed committer,
        address[] participantMembers,
        uint256 randommness,
        uint256 payment,
        bool success
    );

    // *Errors*
    error Reentrant();
    error InvalidRequestConfirmations(uint16 have, uint16 min, uint16 max);
    error TooManyConsumers();
    error InsufficientBalanceWhenRequest();
    error InsufficientBalanceWhenFulfill();
    error InvalidConsumer(uint64 subId, address consumer);
    error InvalidSubscription();
    error ReferralPromotionDisabled();
    error SubscriptionAlreadyHasReferral();
    error AtLeastOneRequestIsRequired();
    error MustBeSubOwner(address owner);
    error PaymentTooLarge();
    error NoAvailableGroups();
    error NoCorrespondingRequest();
    error IncorrectCommitment();
    error InvalidRequestByEOA();
    error TaskStillExclusive();
    error TaskStillWithinRequestConfirmations();
    error NotFromCommitter();
    error GroupNotExist(uint256 groupIndex);
    error SenderNotController();
    error PendingRequestExists();

    // *Modifiers*
    modifier onlySubOwner(uint64 subId) {
        address owner = _subscriptions[subId].owner;
        if (owner == address(0)) {
            revert InvalidSubscription();
        }
        if (msg.sender != owner) {
            revert MustBeSubOwner(owner);
        }
        _;
    }

    modifier nonReentrant() {
        if (_config.reentrancyLock) {
            revert Reentrant();
        }
        _;
    }

    function initialize(address controller) public initializer {
        _controller = IController(controller);

        __Ownable_init();
    }

    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}

    // =============
    // IAdapterOwner
    // =============
    function setAdapterConfig(
        uint16 minimumRequestConfirmations,
        uint32 maxGasLimit,
        uint32 gasAfterPaymentCalculation,
        uint32 gasExceptCallback,
        uint256 signatureTaskExclusiveWindow,
        uint256 rewardPerSignature,
        uint256 committerRewardPerSignature
    ) external override(IAdapterOwner) onlyOwner {
        if (minimumRequestConfirmations > MAX_REQUEST_CONFIRMATIONS) {
            revert InvalidRequestConfirmations(
                minimumRequestConfirmations, minimumRequestConfirmations, MAX_REQUEST_CONFIRMATIONS
            );
        }
        _config = AdapterConfig({
            minimumRequestConfirmations: minimumRequestConfirmations,
            maxGasLimit: maxGasLimit,
            gasAfterPaymentCalculation: gasAfterPaymentCalculation,
            gasExceptCallback: gasExceptCallback,
            signatureTaskExclusiveWindow: signatureTaskExclusiveWindow,
            rewardPerSignature: rewardPerSignature,
            committerRewardPerSignature: committerRewardPerSignature,
            reentrancyLock: false
        });

        emit AdapterConfigSet(
            minimumRequestConfirmations,
            maxGasLimit,
            gasAfterPaymentCalculation,
            gasExceptCallback,
            signatureTaskExclusiveWindow,
            rewardPerSignature,
            committerRewardPerSignature
        );
    }

    function setFlatFeeConfig(
        FeeConfig memory flatFeeConfig,
        uint16 flatFeePromotionGlobalPercentage,
        bool isFlatFeePromotionEnabledPermanently,
        uint256 flatFeePromotionStartTimestamp,
        uint256 flatFeePromotionEndTimestamp
    ) external override(IAdapterOwner) onlyOwner {
        _flatFeeConfig = FlatFeeConfig({
            config: flatFeeConfig,
            flatFeePromotionGlobalPercentage: flatFeePromotionGlobalPercentage,
            isFlatFeePromotionEnabledPermanently: isFlatFeePromotionEnabledPermanently,
            flatFeePromotionStartTimestamp: flatFeePromotionStartTimestamp,
            flatFeePromotionEndTimestamp: flatFeePromotionEndTimestamp
        });

        emit FlatFeeConfigSet(
            flatFeeConfig,
            flatFeePromotionGlobalPercentage,
            isFlatFeePromotionEnabledPermanently,
            flatFeePromotionStartTimestamp,
            flatFeePromotionEndTimestamp
        );
    }

    function setReferralConfig(
        bool isReferralEnabled,
        uint16 freeRequestCountForReferrer,
        uint16 freeRequestCountForReferee
    ) external override(IAdapterOwner) onlyOwner {
        _referralConfig = ReferralConfig({
            isReferralEnabled: isReferralEnabled,
            freeRequestCountForReferrer: freeRequestCountForReferrer,
            freeRequestCountForReferee: freeRequestCountForReferee
        });

        emit ReferralConfigSet(isReferralEnabled, freeRequestCountForReferrer, freeRequestCountForReferee);
    }

    function setFreeRequestCount(uint64[] memory subIds, uint64[] memory freeRequestCounts)
        external
        override(IAdapterOwner)
        onlyOwner
    {
        for (uint256 i = 0; i < subIds.length; i++) {
            _subscriptions[subIds[i]].freeRequestCount = freeRequestCounts[i];
        }
    }

    function ownerCancelSubscription(uint64 subId) external override(IAdapterOwner) onlyOwner {
        if (_subscriptions[subId].owner == address(0)) {
            revert InvalidSubscription();
        }
        _cancelSubscriptionHelper(subId, _subscriptions[subId].owner);
    }

    // =============
    // IAdapter
    // =============
    function nodeWithdrawETH(address recipient, uint256 ethAmount) external {
        if (msg.sender != address(_controller)) {
            revert SenderNotController();
        }
        (bool sent,) = payable(recipient).call{value: ethAmount}("");
        require(sent, "Failed to send Ether");
    }

    function createSubscription() external override(IAdapter) nonReentrant returns (uint64) {
        _currentSubId++;

        _subscriptions[_currentSubId].owner = msg.sender;
        // flat fee free for the first request for each subscription
        _subscriptions[_currentSubId].freeRequestCount = 1;

        emit SubscriptionCreated(_currentSubId, msg.sender);
        return _currentSubId;
    }

    function addConsumer(uint64 subId, address consumer) external override(IAdapter) onlySubOwner(subId) nonReentrant {
        // Already maxed, cannot add any more consumers.
        if (_subscriptions[subId].consumers.length == MAX_CONSUMERS) {
            revert TooManyConsumers();
        }
        if (_consumers[consumer].nonces[subId] != 0) {
            // Idempotence - do nothing if already added.
            // Ensures uniqueness in subscriptions[subId].consumers.
            return;
        }
        // Initialize the nonce to 1, indicating the consumer is allocated.
        _consumers[consumer].nonces[subId] = 1;
        _consumers[consumer].lastSubscription = subId;
        _subscriptions[subId].consumers.push(consumer);

        emit SubscriptionConsumerAdded(subId, consumer);
    }

    function removeConsumer(uint64 subId, address consumer) external override onlySubOwner(subId) nonReentrant {
        if (_subscriptions[subId].inflightCost != 0) {
            revert PendingRequestExists();
        }
        address[] memory consumers = _subscriptions[subId].consumers;
        if (consumers.length == 0) {
            revert InvalidConsumer(subId, consumer);
        }
        // Note bounded by MAX_CONSUMERS
        for (uint256 i = 0; i < consumers.length; i++) {
            if (consumers[i] == consumer) {
                _subscriptions[subId].consumers[i] = consumers[consumers.length - 1];
                _subscriptions[subId].consumers.pop();

                emit SubscriptionConsumerRemoved(subId, consumer);
                return;
            }
        }
        revert InvalidConsumer(subId, consumer);
    }

    function fundSubscription(uint64 subId) external payable override(IAdapter) nonReentrant {
        if (_subscriptions[subId].owner == address(0)) {
            revert InvalidSubscription();
        }

        // We do not check that the msg.sender is the subscription owner,
        // anyone can fund a subscription.
        uint256 oldBalance = _subscriptions[subId].balance;
        _subscriptions[subId].balance += msg.value;
        emit SubscriptionFunded(subId, oldBalance, oldBalance + msg.value);
    }

    function setReferral(uint64 subId, uint64 referralSubId) external onlySubOwner(subId) nonReentrant {
        if (!_referralConfig.isReferralEnabled) {
            revert ReferralPromotionDisabled();
        }
        if (_subscriptions[subId].referralSubId != 0) {
            revert SubscriptionAlreadyHasReferral();
        }
        if (_subscriptions[subId].reqCount == 0 || _subscriptions[referralSubId].reqCount == 0) {
            revert AtLeastOneRequestIsRequired();
        }
        _subscriptions[referralSubId].freeRequestCount += _referralConfig.freeRequestCountForReferrer;
        _subscriptions[subId].freeRequestCount += _referralConfig.freeRequestCountForReferee;
        _subscriptions[subId].referralSubId = referralSubId;

        emit SubscriptionReferralSet(subId, referralSubId);
    }

    function cancelSubscription(uint64 subId, address to) external override onlySubOwner(subId) nonReentrant {
        if (_subscriptions[subId].inflightCost != 0) {
            revert PendingRequestExists();
        }
        _cancelSubscriptionHelper(subId, to);
    }

    function requestRandomness(RandomnessRequestParams calldata params)
        public
        virtual
        override(IAdapter)
        nonReentrant
        returns (bytes32)
    {
        RandomnessRequestParams memory p = params;

        // solhint-disable-next-line avoid-tx-origin
        if (msg.sender == tx.origin) {
            revert InvalidRequestByEOA();
        }

        Subscription storage sub = _subscriptions[p.subId];

        // Input validation using the subscription storage.
        if (sub.owner == address(0)) {
            revert InvalidSubscription();
        }
        // Its important to ensure that the consumer is in fact who they say they
        // are, otherwise they could use someone else's subscription balance.
        // A nonce of 0 indicates consumer is not allocated to the sub.
        if (_consumers[msg.sender].nonces[p.subId] == 0) {
            revert InvalidConsumer(p.subId, msg.sender);
        }

        // Choose current available group to handle randomness request(by round robin)
        _lastAssignedGroupIndex = _findGroupToAssignTask();

        // Calculate requestId for the task
        uint256 rawSeed = _makeRandcastInputSeed(p.seed, msg.sender, _consumers[msg.sender].nonces[p.subId]);
        _consumers[msg.sender].nonces[p.subId] += 1;
        bytes32 requestId = _makeRequestId(rawSeed);

        (, uint256 groupSize) = _controller.getGroupThreshold(_lastAssignedGroupIndex);

        uint256 payment =
            _freezePaymentBySubscription(sub, requestId, groupSize, p.callbackGasLimit, p.callbackMaxGasPrice);

        _requestCommitments[requestId] = keccak256(
            abi.encode(
                requestId,
                p.subId,
                _lastAssignedGroupIndex,
                p.requestType,
                p.params,
                msg.sender,
                rawSeed,
                p.requestConfirmations,
                p.callbackGasLimit,
                p.callbackMaxGasPrice,
                block.number
            )
        );

        emit RandomnessRequest(
            requestId,
            p.subId,
            _lastAssignedGroupIndex,
            p.requestType,
            p.params,
            msg.sender,
            rawSeed,
            p.requestConfirmations,
            p.callbackGasLimit,
            p.callbackMaxGasPrice,
            payment
        );

        return requestId;
    }

    function fulfillRandomness(
        uint256 groupIndex,
        bytes32 requestId,
        uint256 signature,
        RequestDetail calldata requestDetail,
        PartialSignature[] calldata partialSignatures
    ) public virtual override(IAdapter) nonReentrant {
        uint256 startGas = gasleft();

        bytes32 commitment = _requestCommitments[requestId];
        if (commitment == 0) {
            revert NoCorrespondingRequest();
        }
        if (
            commitment
                != keccak256(
                    abi.encode(
                        requestId,
                        requestDetail.subId,
                        requestDetail.groupIndex,
                        requestDetail.requestType,
                        requestDetail.params,
                        requestDetail.callbackContract,
                        requestDetail.seed,
                        requestDetail.requestConfirmations,
                        requestDetail.callbackGasLimit,
                        requestDetail.callbackMaxGasPrice,
                        requestDetail.blockNum
                    )
                )
        ) {
            revert IncorrectCommitment();
        }

        if (block.number < requestDetail.blockNum + requestDetail.requestConfirmations) {
            revert TaskStillWithinRequestConfirmations();
        }

        if (
            groupIndex != requestDetail.groupIndex
                && block.number <= requestDetail.blockNum + _config.signatureTaskExclusiveWindow
        ) {
            revert TaskStillExclusive();
        }
        if (groupIndex >= _controller.getGroupCount()) {
            revert GroupNotExist(groupIndex);
        }

        address[] memory participantMembers =
            _verifySignature(groupIndex, requestDetail.seed, requestDetail.blockNum, signature, partialSignatures);

        delete _requestCommitments[requestId];

        uint256 randomness = uint256(keccak256(abi.encode(signature)));

        _randomnessCount += 1;
        _lastRandomness = randomness;
        _controller.setLastOutput(randomness);
        // call user fulfill_randomness callback
        bool success = _fulfillCallback(requestId, randomness, requestDetail);

        uint256 payment =
            _payBySubscription(_subscriptions[requestDetail.subId], requestId, partialSignatures.length, startGas);

        // rewardRandomness for participants
        _rewardRandomness(participantMembers, payment);

        // Include payment in the event for tracking costs.
        emit RandomnessRequestResult(
            requestId, groupIndex, msg.sender, participantMembers, randomness, payment, success
        );
    }

    function getLastSubscription(address consumer) public view override(IAdapter) returns (uint64) {
        return _consumers[consumer].lastSubscription;
    }

    function getSubscription(uint64 subId)
        public
        view
        override(IAdapter)
        returns (uint256 balance, uint256 inflightCost, uint64 reqCount, address owner, address[] memory consumers)
    {
        if (_subscriptions[subId].owner == address(0)) {
            revert InvalidSubscription();
        }
        return (
            _subscriptions[subId].balance,
            _subscriptions[subId].inflightCost,
            _subscriptions[subId].reqCount,
            _subscriptions[subId].owner,
            _subscriptions[subId].consumers
        );
    }

    function getPendingRequestCommitment(bytes32 requestId) public view override(IAdapter) returns (bytes32) {
        return _requestCommitments[requestId];
    }

    function getLastRandomness() external view override(IAdapter) returns (uint256) {
        return _lastRandomness;
    }

    function getRandomnessCount() external view override(IAdapter) returns (uint256) {
        return _randomnessCount;
    }

    function getFeeTier(uint64 reqCount) public view override(IAdapter) returns (uint32) {
        FeeConfig memory fc = _flatFeeConfig.config;
        if (0 <= reqCount && reqCount <= fc.reqsForTier2) {
            return fc.fulfillmentFlatFeeEthPPMTier1;
        }
        if (fc.reqsForTier2 < reqCount && reqCount <= fc.reqsForTier3) {
            return fc.fulfillmentFlatFeeEthPPMTier2;
        }
        if (fc.reqsForTier3 < reqCount && reqCount <= fc.reqsForTier4) {
            return fc.fulfillmentFlatFeeEthPPMTier3;
        }
        if (fc.reqsForTier4 < reqCount && reqCount <= fc.reqsForTier5) {
            return fc.fulfillmentFlatFeeEthPPMTier4;
        }
        return fc.fulfillmentFlatFeeEthPPMTier5;
    }

    function estimatePaymentAmountInETH(
        uint256 callbackGasLimit,
        uint256 gasExceptCallback,
        uint32 fulfillmentFlatFeeEthPPM,
        uint256 weiPerUnitGas
    ) public pure override(IAdapter) returns (uint256) {
        uint256 paymentNoFee = weiPerUnitGas * (gasExceptCallback + callbackGasLimit);
        return (paymentNoFee + 1e12 * uint256(fulfillmentFlatFeeEthPPM));
    }

    // =============
    // Internal
    // =============

    function _rewardRandomness(address[] memory participantMembers, uint256 payment) internal {
        address[] memory committer = new address[](1);
        committer[0] = msg.sender;
        _controller.addReward(committer, payment, _config.committerRewardPerSignature);
        _controller.addReward(participantMembers, 0, _config.rewardPerSignature);
    }

    function _fulfillCallback(bytes32 requestId, uint256 randomness, RequestDetail memory requestDetail)
        internal
        returns (bool success)
    {
        IBasicRandcastConsumerBase b;
        bytes memory resp;
        if (requestDetail.requestType == RequestType.Randomness) {
            resp = abi.encodeWithSelector(b.rawFulfillRandomness.selector, requestId, randomness);
        } else if (requestDetail.requestType == RequestType.RandomWords) {
            uint32 numWords = abi.decode(requestDetail.params, (uint32));
            uint256[] memory randomWords = new uint256[](numWords);
            for (uint256 i = 0; i < numWords; i++) {
                randomWords[i] = uint256(keccak256(abi.encode(randomness, i)));
            }
            resp = abi.encodeWithSelector(b.rawFulfillRandomWords.selector, requestId, randomWords);
        } else if (requestDetail.requestType == RequestType.Shuffling) {
            uint32 upper = abi.decode(requestDetail.params, (uint32));
            uint256[] memory shuffledArray = _shuffle(upper, randomness);
            resp = abi.encodeWithSelector(b.rawFulfillShuffledArray.selector, requestId, shuffledArray);
        }

        // Call with explicitly the amount of callback gas requested
        // Important to not let them exhaust the gas budget and avoid oracle payment.
        // Do not allow any non-view/non-pure coordinator functions to be called
        // during the consumers callback code via reentrancyLock.
        // Note that callWithExactGas will revert if we do not have sufficient gas
        // to give the callee their requested amount.
        _config.reentrancyLock = true;
        success = Utils.callWithExactGas(requestDetail.callbackGasLimit, requestDetail.callbackContract, resp);
        _config.reentrancyLock = false;
    }

    function _freezePaymentBySubscription(
        Subscription storage sub,
        bytes32 requestId,
        uint256 groupSize,
        uint256 callbackGasLimit,
        uint256 callbackMaxGasPrice
    ) internal returns (uint256) {
        uint64 reqCount;
        if (_flatFeeConfig.isFlatFeePromotionEnabledPermanently) {
            reqCount = sub.reqCount;
        } else if (
            _flatFeeConfig
                //solhint-disable-next-line not-rely-on-time
                .flatFeePromotionStartTimestamp <= block.timestamp
            //solhint-disable-next-line not-rely-on-time
            && block.timestamp <= _flatFeeConfig.flatFeePromotionEndTimestamp
        ) {
            if (sub.lastRequestTimestamp < _flatFeeConfig.flatFeePromotionStartTimestamp) {
                reqCount = 1;
            } else {
                reqCount = sub.reqCountInCurrentPeriod + 1;
            }
        }

        // Estimate upper cost of this fulfillment.
        uint256 payment = estimatePaymentAmountInETH(
            callbackGasLimit,
            uint256(_config.gasExceptCallback) + RANDOMNESS_REWARD_GAS * groupSize
                + VERIFICATION_GAS_OVER_MINIMUM_THRESHOLD * (groupSize - DEFAULT_MINIMUM_THRESHOLD),
            sub.freeRequestCount > 0
                ? 0
                : (getFeeTier(reqCount) * _flatFeeConfig.flatFeePromotionGlobalPercentage / 100),
            callbackMaxGasPrice
        );

        if (sub.balance - sub.inflightCost < payment) {
            revert InsufficientBalanceWhenRequest();
        }

        sub.inflightCost += payment;
        sub.inflightPayments[requestId] = payment;

        return payment;
    }

    function _payBySubscription(
        Subscription storage sub,
        bytes32 requestId,
        uint256 partialSignersCount,
        uint256 startGas
    ) internal returns (uint256) {
        // Increment the req count for fee tier selection.
        sub.reqCount += 1;
        uint64 reqCount;
        if (_flatFeeConfig.isFlatFeePromotionEnabledPermanently) {
            reqCount = sub.reqCount;
        } else if (
            _flatFeeConfig
                //solhint-disable-next-line not-rely-on-time
                .flatFeePromotionStartTimestamp <= block.timestamp
            //solhint-disable-next-line not-rely-on-time
            && block.timestamp <= _flatFeeConfig.flatFeePromotionEndTimestamp
        ) {
            if (sub.lastRequestTimestamp < _flatFeeConfig.flatFeePromotionStartTimestamp) {
                sub.reqCountInCurrentPeriod == 1;
            } else {
                sub.reqCountInCurrentPeriod += 1;
            }
            reqCount = sub.reqCountInCurrentPeriod;
        }

        //solhint-disable-next-line not-rely-on-time
        sub.lastRequestTimestamp = block.timestamp;

        bool isFlatFeeFree = sub.freeRequestCount > 0;

        if (isFlatFeeFree) {
            sub.freeRequestCount -= 1;
        }

        // We want to charge users exactly for how much gas they use in their callback.
        // The gasAfterPaymentCalculation is meant to cover these additional operations where we
        // decrement the subscription balance and increment the groups withdrawable balance.
        // We also add the flat eth fee to the payment amount.
        // Its specified in millionths of eth, if _config.fulfillmentFlatFeeEthPPM = 1
        // 1 eth / 1e6 = 1e18 eth wei / 1e6 = 1e12 eth wei.
        uint256 payment = _calculatePaymentAmountInETH(
            startGas,
            uint256(_config.gasAfterPaymentCalculation) + RANDOMNESS_REWARD_GAS * partialSignersCount,
            isFlatFeeFree ? 0 : (getFeeTier(reqCount) * _flatFeeConfig.flatFeePromotionGlobalPercentage / 100),
            tx.gasprice
        );

        if (sub.balance < payment) {
            revert InsufficientBalanceWhenFulfill();
        }
        sub.inflightCost -= sub.inflightPayments[requestId];
        delete sub.inflightPayments[requestId];
        sub.balance -= payment;

        return payment;
    }

    function _cancelSubscriptionHelper(uint64 subId, address to) internal nonReentrant {
        uint256 balance = _subscriptions[subId].balance;
        delete _subscriptions[subId];
        (bool sent,) = payable(to).call{value: balance}("");
        require(sent, "Failed to send Ether");
        emit SubscriptionCanceled(subId, to, balance);
    }

    // Get the amount of gas used for fulfillment
    function _calculatePaymentAmountInETH(
        uint256 startGas,
        uint256 gasAfterPaymentCalculation,
        uint32 fulfillmentFlatFeeEthPPM,
        uint256 weiPerUnitGas
    ) internal view returns (uint256) {
        uint256 paymentNoFee = weiPerUnitGas * (gasAfterPaymentCalculation + startGas - gasleft());
        uint256 fee = 1e12 * uint256(fulfillmentFlatFeeEthPPM);
        if (paymentNoFee > (12e25 - fee)) {
            revert PaymentTooLarge(); // Payment + fee cannot be more than all of the ETH in existence.
        }
        return paymentNoFee + fee;
    }

    function _findGroupToAssignTask() internal view returns (uint256) {
        uint256[] memory validGroupIndices = _controller.getValidGroupIndices();

        if (validGroupIndices.length == 0) {
            revert NoAvailableGroups();
        }

        uint256 groupCount = _controller.getGroupCount();

        uint256 currentAssignedGroupIndex = (_lastAssignedGroupIndex + 1) % groupCount;

        while (!Utils.containElement(validGroupIndices, currentAssignedGroupIndex)) {
            currentAssignedGroupIndex = (currentAssignedGroupIndex + 1) % groupCount;
        }

        return currentAssignedGroupIndex;
    }

    function _verifySignature(
        uint256 groupIndex,
        uint256 seed,
        uint256 blockNum,
        uint256 signature,
        PartialSignature[] memory partialSignatures
    ) internal view returns (address[] memory participantMembers) {
        if (!BLS.isValid(signature)) {
            revert BLS.InvalidSignatureFormat();
        }

        if (partialSignatures.length == 0) {
            revert BLS.EmptyPartialSignatures();
        }

        IController.Group memory g = _controller.getGroup(groupIndex);

        if (!Utils.containElement(g.committers, msg.sender)) {
            revert NotFromCommitter();
        }

        bytes memory actualSeed = abi.encodePacked(seed, blockNum);

        uint256[2] memory message = BLS.hashToPoint(actualSeed);

        // verify tss-aggregation signature for randomness
        if (!BLS.verifySingle(BLS.decompress(signature), g.publicKey, message)) {
            revert BLS.InvalidSignature();
        }

        // verify bls-aggregation signature for incentivizing worker list
        uint256[2][] memory partials = new uint256[2][](partialSignatures.length);
        uint256[4][] memory pubkeys = new uint256[4][](partialSignatures.length);
        participantMembers = new address[](partialSignatures.length);
        for (uint256 i = 0; i < partialSignatures.length; i++) {
            if (!BLS.isValid(partialSignatures[i].partialSignature)) {
                revert BLS.InvalidPartialSignatureFormat();
            }
            partials[i] = BLS.decompress(partialSignatures[i].partialSignature);
            pubkeys[i] = g.members[partialSignatures[i].index].partialPublicKey;
            participantMembers[i] = g.members[partialSignatures[i].index].nodeIdAddress;
        }
        if (!BLS.verifyPartials(partials, pubkeys, message)) {
            revert BLS.InvalidPartialSignatures();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import {IRequestTypeBase} from "./IRequestTypeBase.sol";

interface IAdapter is IRequestTypeBase {
    struct PartialSignature {
        uint256 index;
        uint256 partialSignature;
    }

    struct RandomnessRequestParams {
        RequestType requestType;
        bytes params;
        uint64 subId;
        uint256 seed;
        uint16 requestConfirmations;
        uint256 callbackGasLimit;
        uint256 callbackMaxGasPrice;
    }

    struct RequestDetail {
        uint64 subId;
        uint256 groupIndex;
        RequestType requestType;
        bytes params;
        address callbackContract;
        uint256 seed;
        uint16 requestConfirmations;
        uint256 callbackGasLimit;
        uint256 callbackMaxGasPrice;
        uint256 blockNum;
    }

    // controller transaction
    function nodeWithdrawETH(address recipient, uint256 ethAmount) external;

    // consumer contract transaction
    function requestRandomness(RandomnessRequestParams calldata params) external returns (bytes32);

    function fulfillRandomness(
        uint256 groupIndex,
        bytes32 requestId,
        uint256 signature,
        RequestDetail calldata requestDetail,
        PartialSignature[] calldata partialSignatures
    ) external;

    // user transaction
    function createSubscription() external returns (uint64);

    function addConsumer(uint64 subId, address consumer) external;

    function fundSubscription(uint64 subId) external payable;

    function setReferral(uint64 subId, uint64 referralSubId) external;

    function cancelSubscription(uint64 subId, address to) external;

    function removeConsumer(uint64 subId, address consumer) external;

    // view
    function getLastSubscription(address consumer) external view returns (uint64);

    function getSubscription(uint64 subId)
        external
        view
        returns (uint256 balance, uint256 inflightCost, uint64 reqCount, address owner, address[] memory consumers);

    function getPendingRequestCommitment(bytes32 requestId) external view returns (bytes32);

    function getLastRandomness() external view returns (uint256);

    function getRandomnessCount() external view returns (uint256);

    /*
     * @notice Compute fee based on the request count
     * @param reqCount number of requests
     * @return feePPM fee in ARPA PPM
     */
    function getFeeTier(uint64 reqCount) external view returns (uint32);

    // Estimate the amount of gas used for fulfillment
    function estimatePaymentAmountInETH(
        uint256 callbackGasLimit,
        uint256 gasExceptCallback,
        uint32 fulfillmentFlatFeeEthPPM,
        uint256 weiPerUnitGas
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IAdapterOwner {
    struct AdapterConfig {
        // Minimum number of blocks a request must wait before being fulfilled.
        uint16 minimumRequestConfirmations;
        // Maximum gas limit for fulfillRandomness requests.
        uint32 maxGasLimit;
        // Reentrancy protection.
        bool reentrancyLock;
        // Gas to cover group payment after we calculate the payment.
        // We make it configurable in case those operations are repriced.
        uint32 gasAfterPaymentCalculation;
        // Gas except callback during fulfillment of randomness. Only used for estimating inflight cost.
        uint32 gasExceptCallback;
        // The assigned group is exclusive for fulfilling the task within this block window
        uint256 signatureTaskExclusiveWindow;
        // reward per signature for every participating node
        uint256 rewardPerSignature;
        // reward per signature for the committer
        uint256 committerRewardPerSignature;
    }

    struct FeeConfig {
        // Flat fee charged per fulfillment in millionths of arpa
        uint32 fulfillmentFlatFeeEthPPMTier1;
        uint32 fulfillmentFlatFeeEthPPMTier2;
        uint32 fulfillmentFlatFeeEthPPMTier3;
        uint32 fulfillmentFlatFeeEthPPMTier4;
        uint32 fulfillmentFlatFeeEthPPMTier5;
        uint24 reqsForTier2;
        uint24 reqsForTier3;
        uint24 reqsForTier4;
        uint24 reqsForTier5;
    }

    struct FlatFeeConfig {
        FeeConfig config;
        uint16 flatFeePromotionGlobalPercentage;
        bool isFlatFeePromotionEnabledPermanently;
        uint256 flatFeePromotionStartTimestamp;
        uint256 flatFeePromotionEndTimestamp;
    }

    struct ReferralConfig {
        bool isReferralEnabled;
        uint16 freeRequestCountForReferrer;
        uint16 freeRequestCountForReferee;
    }

    /**
     * @notice Sets the configuration of the adapter
     * @param minimumRequestConfirmations global min for request confirmations
     * @param maxGasLimit global max for request gas limit
     * @param gasAfterPaymentCalculation gas used in doing accounting after completing the gas measurement
     * @param signatureTaskExclusiveWindow window in which a signature task is exclusive to the assigned group
     * @param rewardPerSignature reward per signature for every participating node
     * @param committerRewardPerSignature reward per signature for the committer
     */
    function setAdapterConfig(
        uint16 minimumRequestConfirmations,
        uint32 maxGasLimit,
        uint32 gasAfterPaymentCalculation,
        uint32 gasExceptCallback,
        uint256 signatureTaskExclusiveWindow,
        uint256 rewardPerSignature,
        uint256 committerRewardPerSignature
    ) external;

    /**
     * @notice Sets the flat fee configuration of the adapter
     * @param flatFeeConfig flat fee tier configuration
     * @param flatFeePromotionGlobalPercentage global percentage of flat fee promotion
     * @param isFlatFeePromotionEnabledPermanently whether flat fee promotion is enabled permanently
     * @param flatFeePromotionStartTimestamp flat fee promotion start timestamp
     * @param flatFeePromotionEndTimestamp flat fee promotion end timestamp
     */
    function setFlatFeeConfig(
        FeeConfig memory flatFeeConfig,
        uint16 flatFeePromotionGlobalPercentage,
        bool isFlatFeePromotionEnabledPermanently,
        uint256 flatFeePromotionStartTimestamp,
        uint256 flatFeePromotionEndTimestamp
    ) external;

    /**
     * @notice Sets the referral configuration of the adapter
     * @param isReferralEnabled whether referral is enabled
     * @param freeRequestCountForReferrer free request count for referrer
     * @param freeRequestCountForReferee free request count for referee
     */
    function setReferralConfig(
        bool isReferralEnabled,
        uint16 freeRequestCountForReferrer,
        uint16 freeRequestCountForReferee
    ) external;

    /**
     * @notice Sets free request count for subscriptions
     * @param subIds subscription ids
     * @param freeRequestCounts free request count for each subscription
     */
    function setFreeRequestCount(uint64[] memory subIds, uint64[] memory freeRequestCounts) external;

    /**
     * @notice Owner cancel subscription, sends remaining eth directly to the subscription owner
     * @param subId subscription id
     * @dev notably can be called even if there are pending requests
     */
    function ownerCancelSubscription(uint64 subId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IController {
    struct Group {
        uint256 index;
        uint256 epoch;
        uint256 size;
        uint256 threshold;
        Member[] members;
        address[] committers;
        CommitCache[] commitCacheList;
        bool isStrictlyMajorityConsensusReached;
        uint256[4] publicKey;
    }

    struct Member {
        address nodeIdAddress;
        uint256[4] partialPublicKey;
    }

    struct CommitResult {
        uint256 groupEpoch;
        uint256[4] publicKey;
        address[] disqualifiedNodes;
    }

    struct CommitCache {
        address[] nodeIdAddress;
        CommitResult commitResult;
    }

    struct Node {
        address idAddress;
        bytes dkgPublicKey;
        bool state;
        uint256 pendingUntilBlock;
    }

    struct CommitDkgParams {
        uint256 groupIndex;
        uint256 groupEpoch;
        bytes publicKey;
        bytes partialPublicKey;
        address[] disqualifiedNodes;
    }

    // node transaction
    function nodeRegister(bytes calldata dkgPublicKey) external;

    function nodeActivate() external;

    function nodeQuit() external;

    function changeDkgPublicKey(bytes calldata dkgPublicKey) external;

    function commitDkg(CommitDkgParams memory params) external;

    function postProcessDkg(uint256 groupIndex, uint256 groupEpoch) external;

    function nodeWithdraw(address recipient) external;

    // adapter transaction
    function addReward(address[] memory nodes, uint256 ethAmount, uint256 arpaAmount) external;

    function setLastOutput(uint256 lastOutput) external;

    // view
    /// @notice Get list of all group indexes where group.isStrictlyMajorityConsensusReached == true
    /// @return uint256[] List of valid group indexes
    function getValidGroupIndices() external view returns (uint256[] memory);

    function getGroupCount() external view returns (uint256);

    function getGroup(uint256 index) external view returns (Group memory);

    function getGroupThreshold(uint256 groupIndex) external view returns (uint256, uint256);

    function getNode(address nodeAddress) external view returns (Node memory);

    function getMember(uint256 groupIndex, uint256 memberIndex) external view returns (Member memory);

    /// @notice Get the group index and member index of a given node.
    function getBelongingGroup(address nodeAddress) external view returns (int256, int256);

    function getCoordinator(uint256 groupIndex) external view returns (address);

    function getNodeWithdrawableTokens(address nodeAddress) external view returns (uint256, uint256);

    function getLastOutput() external view returns (uint256);

    /// @notice Check to see if a group has a partial public key registered for a given node.
    /// @return bool True if the node has a partial public key registered for the group.
    function isPartialKeyRegistered(uint256 groupIndex, address nodeIdAddress) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface IBasicRandcastConsumerBase {
    function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external;

    function rawFulfillRandomWords(bytes32 requestId, uint256[] memory randomWords) external;

    function rawFulfillShuffledArray(bytes32 requestId, uint256[] memory shuffledArray) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

contract RequestIdBase {
    function _makeRandcastInputSeed(uint256 _userSeed, address _requester, uint256 _nonce)
        internal
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encode(_userSeed, _requester, _nonce)));
    }

    function _makeRequestId(uint256 inputSeed) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(inputSeed));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

contract RandomnessHandler {
    function _shuffle(uint256 upper, uint256 randomness) internal pure returns (uint256[] memory) {
        uint256[] memory arr = new uint256[](upper);
        for (uint256 k = 0; k < upper; k++) {
            arr[k] = k;
        }
        uint256 i = arr.length;
        uint256 j;
        uint256 t;

        while (--i > 0) {
            j = randomness % i;
            randomness = uint256(keccak256(abi.encode(randomness)));
            t = arr[i];
            arr[i] = arr[j];
            arr[j] = t;
        }

        return arr;
    }
}

// SPDX-License-Identifier: LGPL 3.0
pragma solidity ^0.8.15;

import {BN256G2} from "./BN256G2.sol";

/**
 * @title BLS operations on bn254 curve
 * @author ARPA-Network adapted from https://github.com/ChihChengLiang/bls_solidity_python
 * @dev Homepage: https://github.com/ARPA-Network/BLS-TSS-Network
 *      Signature and Point hashed to G1 are represented by affine coordinate in big-endian order, deserialized from compressed format.
 *      Public key is represented and serialized by affine coordinate Q-x-re(x0), Q-x-im(x1), Q-y-re(y0), Q-y-im(y1) in big-endian order.
 */
library BLS {
    // Field order
    uint256 public constant N = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    // Negated genarator of G2
    uint256 public constant N_G2_X1 = 11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 public constant N_G2_X0 = 10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 public constant N_G2_Y1 = 17805874995975841540914202342111839520379459829704422454583296818431106115052;
    uint256 public constant N_G2_Y0 = 13392588948715843804641432497768002650278120570034223513918757245338268106653;

    uint256 public constant FIELD_MASK = 0x3fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    error MustNotBeInfinity();
    error InvalidPublicKeyEncoding();
    error InvalidSignatureFormat();
    error InvalidSignature();
    error InvalidPartialSignatureFormat();
    error InvalidPartialSignatures();
    error EmptyPartialSignatures();
    error InvalidPublicKey();
    error InvalidPartialPublicKey();

    function verifySingle(uint256[2] memory signature, uint256[4] memory pubkey, uint256[2] memory message)
        public
        view
        returns (bool)
    {
        uint256[12] memory input = [
            signature[0],
            signature[1],
            N_G2_X1,
            N_G2_X0,
            N_G2_Y1,
            N_G2_Y0,
            message[0],
            message[1],
            pubkey[1],
            pubkey[0],
            pubkey[3],
            pubkey[2]
        ];
        uint256[1] memory out;
        bool success;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, input, 384, out, 0x20)
            switch success
            case 0 { invalid() }
        }
        require(success, "");
        return out[0] != 0;
    }

    function verifyPartials(uint256[2][] memory partials, uint256[4][] memory pubkeys, uint256[2] memory message)
        public
        view
        returns (bool)
    {
        uint256[2] memory aggregatedSignature;
        uint256[4] memory aggregatedPublicKey;
        for (uint256 i = 0; i < partials.length; i++) {
            aggregatedSignature = addPoints(aggregatedSignature, partials[i]);
            aggregatedPublicKey = BN256G2.ecTwistAdd(aggregatedPublicKey, pubkeys[i]);
        }

        uint256[12] memory input = [
            aggregatedSignature[0],
            aggregatedSignature[1],
            N_G2_X1,
            N_G2_X0,
            N_G2_Y1,
            N_G2_Y0,
            message[0],
            message[1],
            aggregatedPublicKey[1],
            aggregatedPublicKey[0],
            aggregatedPublicKey[3],
            aggregatedPublicKey[2]
        ];
        uint256[1] memory out;
        bool success;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, input, 384, out, 0x20)
            switch success
            case 0 { invalid() }
        }
        require(success, "");
        return out[0] != 0;
    }

    // TODO a simple hash and increment implementation, can be improved later
    function hashToPoint(bytes memory data) public view returns (uint256[2] memory p) {
        bool found;
        bytes32 candidateHash = keccak256(data);
        while (true) {
            (p, found) = mapToPoint(candidateHash);
            if (found) {
                break;
            }
            candidateHash = keccak256(bytes.concat(candidateHash));
        }
    }

    //  we take the y-coordinate as the lexicographically largest of the two associated with the encoded x-coordinate
    function mapToPoint(bytes32 _x) internal view returns (uint256[2] memory p, bool found) {
        uint256 y;
        uint256 x = uint256(_x) % N;
        (y, found) = deriveYOnG1(x);
        if (found) {
            p[0] = x;
            p[1] = y > N / 2 ? N - y : y;
        }
    }

    function deriveYOnG1(uint256 x) internal view returns (uint256, bool) {
        uint256 y;
        y = mulmod(x, x, N);
        y = mulmod(y, x, N);
        y = addmod(y, 3, N);
        return sqrt(y);
    }

    function isValidPublicKey(uint256[4] memory publicKey) public pure returns (bool) {
        if ((publicKey[0] >= N) || (publicKey[1] >= N) || (publicKey[2] >= N || (publicKey[3] >= N))) {
            return false;
        } else {
            return isOnCurveG2(publicKey);
        }
    }

    function fromBytesPublicKey(bytes memory point) public pure returns (uint256[4] memory pubkey) {
        if (point.length != 128) {
            revert InvalidPublicKeyEncoding();
        }
        uint256 x0;
        uint256 x1;
        uint256 y0;
        uint256 y1;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // look the first 32 bytes of a bytes struct is its length
            x0 := mload(add(point, 32))
            x1 := mload(add(point, 64))
            y0 := mload(add(point, 96))
            y1 := mload(add(point, 128))
        }
        pubkey = [x0, x1, y0, y1];
    }

    function decompress(uint256 compressedSignature) public view returns (uint256[2] memory uncompressed) {
        uint256 x = compressedSignature & FIELD_MASK;
        // The most significant bit, when set, indicates that the y-coordinate of the point
        // is the lexicographically largest of the two associated values.
        // The second-most significant bit indicates that the point is at infinity. If this bit is set,
        // the remaining bits of the group element's encoding should be set to zero.
        // We don't accept infinity as valid signature.
        uint256 decision = compressedSignature >> 254;
        if (decision & 1 == 1) {
            revert MustNotBeInfinity();
        }
        uint256 y;
        (y,) = deriveYOnG1(x);

        // If the following two conditions or their negative forms are not met at the same time, get the negative y.
        // 1. The most significant bit of compressed signature is set
        // 2. The y we recovered first is the lexicographically largest
        if (((decision >> 1) ^ (y > N / 2 ? 1 : 0)) == 1) {
            y = N - y;
        }
        return [x, y];
    }

    function isValid(uint256 compressedSignature) public view returns (bool) {
        uint256 x = compressedSignature & FIELD_MASK;
        if (x >= N) {
            return false;
        } else if (x == 0) {
            return false;
        }
        return isOnCurveG1(x);
    }

    function isOnCurveG1(uint256[2] memory point) internal pure returns (bool _isOnCurve) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let t0 := mload(point)
            let t1 := mload(add(point, 32))
            let t2 := mulmod(t0, t0, N)
            t2 := mulmod(t2, t0, N)
            t2 := addmod(t2, 3, N)
            t1 := mulmod(t1, t1, N)
            _isOnCurve := eq(t1, t2)
        }
    }

    function isOnCurveG1(uint256 x) internal view returns (bool _isOnCurve) {
        bool callSuccess;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let t0 := x
            let t1 := mulmod(t0, t0, N)
            t1 := mulmod(t1, t0, N)
            // x ^ 3 + b
            t1 := addmod(t1, 3, N)

            let freemem := mload(0x40)
            mstore(freemem, 0x20)
            mstore(add(freemem, 0x20), 0x20)
            mstore(add(freemem, 0x40), 0x20)
            mstore(add(freemem, 0x60), t1)
            // (N - 1) / 2 = 0x183227397098d014dc2822db40c0ac2ecbc0b548b438e5469e10460b6c3e7ea3
            mstore(add(freemem, 0x80), 0x183227397098d014dc2822db40c0ac2ecbc0b548b438e5469e10460b6c3e7ea3)
            // N = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
            mstore(add(freemem, 0xA0), 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47)
            callSuccess := staticcall(sub(gas(), 2000), 5, freemem, 0xC0, freemem, 0x20)
            _isOnCurve := eq(1, mload(freemem))
        }
    }

    function isOnCurveG2(uint256[4] memory point) internal pure returns (bool _isOnCurve) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // x0, x1
            let t0 := mload(point)
            let t1 := mload(add(point, 32))
            // x0 ^ 2
            let t2 := mulmod(t0, t0, N)
            // x1 ^ 2
            let t3 := mulmod(t1, t1, N)
            // 3 * x0 ^ 2
            let t4 := add(add(t2, t2), t2)
            // 3 * x1 ^ 2
            let t5 := addmod(add(t3, t3), t3, N)
            // x0 * (x0 ^ 2 - 3 * x1 ^ 2)
            t2 := mulmod(add(t2, sub(N, t5)), t0, N)
            // x1 * (3 * x0 ^ 2 - x1 ^ 2)
            t3 := mulmod(add(t4, sub(N, t3)), t1, N)

            // x ^ 3 + b
            t0 := addmod(t2, 0x2b149d40ceb8aaae81be18991be06ac3b5b4c5e559dbefa33267e6dc24a138e5, N)
            t1 := addmod(t3, 0x009713b03af0fed4cd2cafadeed8fdf4a74fa084e52d1852e4a2bd0685c315d2, N)

            // y0, y1
            t2 := mload(add(point, 64))
            t3 := mload(add(point, 96))
            // y ^ 2
            t4 := mulmod(addmod(t2, t3, N), addmod(t2, sub(N, t3), N), N)
            t3 := mulmod(shl(1, t2), t3, N)

            // y ^ 2 == x ^ 3 + b
            _isOnCurve := and(eq(t0, t4), eq(t1, t3))
        }
    }

    function sqrt(uint256 xx) internal view returns (uint256 x, bool hasRoot) {
        bool callSuccess;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let freemem := mload(0x40)
            mstore(freemem, 0x20)
            mstore(add(freemem, 0x20), 0x20)
            mstore(add(freemem, 0x40), 0x20)
            mstore(add(freemem, 0x60), xx)
            // this is enabled by N % 4 = 3 and Fermat's little theorem
            // (N + 1) / 4 = 0xc19139cb84c680a6e14116da060561765e05aa45a1c72a34f082305b61f3f52
            mstore(add(freemem, 0x80), 0xc19139cb84c680a6e14116da060561765e05aa45a1c72a34f082305b61f3f52)
            // N = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
            mstore(add(freemem, 0xA0), 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47)
            callSuccess := staticcall(sub(gas(), 2000), 5, freemem, 0xC0, freemem, 0x20)
            x := mload(freemem)
            hasRoot := eq(xx, mulmod(x, x, N))
        }
        require(callSuccess, "BLS: sqrt modexp call failed");
    }

    /// @notice Add two points in G1
    function addPoints(uint256[2] memory p1, uint256[2] memory p2) internal view returns (uint256[2] memory ret) {
        uint256[4] memory input;
        input[0] = p1[0];
        input[1] = p1[1];
        input[2] = p2[0];
        input[3] = p2[1];
        bool success;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, ret, 0x60)
        }
        // solhint-disable-next-line reason-string
        require(success);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

// 5k is plenty for an EXTCODESIZE call (2600) + warm CALL (100)
// and some arithmetic operations.
uint256 constant GAS_FOR_CALL_EXACT_CHECK = 5_000;

function containElement(uint256[] memory arr, uint256 element) pure returns (bool) {
    for (uint256 i = 0; i < arr.length; i++) {
        if (arr[i] == element) {
            return true;
        }
    }
    return false;
}

function containElement(address[] memory arr, address element) pure returns (bool) {
    for (uint256 i = 0; i < arr.length; i++) {
        if (arr[i] == element) {
            return true;
        }
    }
    return false;
}

/**
 * @dev returns the minimum threshold for a group of size groupSize
 */
function minimumThreshold(uint256 groupSize) pure returns (uint256) {
    return groupSize / 2 + 1;
}

/**
 * @dev choose one random index from an array.
 */
function pickRandomIndex(uint256 seed, uint256 length) pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(seed))) % length;
}

/**
 * @dev choose "count" random indices from "indices" array.
 */
function pickRandomIndex(uint256 seed, uint256[] memory indices, uint256 count) pure returns (uint256[] memory) {
    uint256[] memory chosenIndices = new uint256[](count);

    // Create copy of indices to avoid modifying original array.
    uint256[] memory remainingIndices = new uint256[](indices.length);
    for (uint256 i = 0; i < indices.length; i++) {
        remainingIndices[i] = indices[i];
    }

    uint256 remainingCount = remainingIndices.length;
    for (uint256 i = 0; i < count; i++) {
        uint256 index = uint256(keccak256(abi.encodePacked(seed, i))) % remainingCount;
        chosenIndices[i] = remainingIndices[index];
        remainingIndices[index] = remainingIndices[remainingCount - 1];
        remainingCount--;
    }
    return chosenIndices;
}

/**
 * @dev iterates through list of members and remove disqualified nodes.
 */
function getNonDisqualifiedMajorityMembers(address[] memory nodeAddresses, address[] memory disqualifiedNodes)
    pure
    returns (address[] memory)
{
    address[] memory majorityMembers = new address[](nodeAddresses.length);
    uint256 majorityMembersLength = 0;
    for (uint256 i = 0; i < nodeAddresses.length; i++) {
        if (!containElement(disqualifiedNodes, nodeAddresses[i])) {
            majorityMembers[majorityMembersLength] = nodeAddresses[i];
            majorityMembersLength++;
        }
    }

    // remove trailing zero addresses
    return trimTrailingElements(majorityMembers, majorityMembersLength);
}

function trimTrailingElements(uint256[] memory arr, uint256 newLength) pure returns (uint256[] memory) {
    uint256[] memory output = new uint256[](newLength);
    for (uint256 i = 0; i < newLength; i++) {
        output[i] = arr[i];
    }
    return output;
}

function trimTrailingElements(address[] memory arr, uint256 newLength) pure returns (address[] memory) {
    address[] memory output = new address[](newLength);
    for (uint256 i = 0; i < newLength; i++) {
        output[i] = arr[i];
    }
    return output;
}

/**
 * @dev calls target address with exactly gasAmount gas and data as calldata
 * or reverts if at least gasAmount gas is not available.
 */
function callWithExactGas(uint256 gasAmount, address target, bytes memory data) returns (bool success) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
        let g := gas()
        // Compute g -= GAS_FOR_CALL_EXACT_CHECK and check for underflow
        // The gas actually passed to the callee is min(gasAmount, 63//64*gas available).
        // We want to ensure that we revert if gasAmount >  63//64*gas available
        // as we do not want to provide them with less, however that check itself costs
        // gas.  GAS_FOR_CALL_EXACT_CHECK ensures we have at least enough gas to be able
        // to revert if gasAmount >  63//64*gas available.
        if lt(g, GAS_FOR_CALL_EXACT_CHECK) { revert(0, 0) }
        g := sub(g, GAS_FOR_CALL_EXACT_CHECK)
        // if g - g//64 <= gasAmount, revert
        // (we subtract g//64 because of EIP-150)
        if iszero(gt(sub(g, div(g, 64)), gasAmount)) { revert(0, 0) }
        // solidity calls check that a contract actually exists at the destination, so we do the same
        if iszero(extcodesize(target)) { revert(0, 0) }
        // call and return whether we succeeded. ignore return data
        // call(gas,addr,value,argsOffset,argsLength,retOffset,retLength)
        success := call(gasAmount, target, 0, add(data, 0x20), mload(data), 0, 0)
    }
    return success;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.3) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/IERC1967Upgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable, IERC1967Upgradeable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface IRequestTypeBase {
    enum RequestType {
        Randomness,
        RandomWords,
        Shuffling
    }
}

// SPDX-License-Identifier: LGPL 3.0
pragma solidity ^0.8.15;

/**
 * @title Elliptic curve operations on twist points for alt_bn128
 * @author ARPA-Network adapted from https://github.com/musalbas/solidity-BN256G2
 * @dev Homepage: https://github.com/ARPA-Network/BLS-TSS-Network
 */

library BN256G2 {
    uint256 public constant FIELD_MODULUS = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47;
    uint256 public constant TWISTBX = 0x2b149d40ceb8aaae81be18991be06ac3b5b4c5e559dbefa33267e6dc24a138e5;
    uint256 public constant TWISTBY = 0x9713b03af0fed4cd2cafadeed8fdf4a74fa084e52d1852e4a2bd0685c315d2;
    uint256 public constant PTXX = 0;
    uint256 public constant PTXY = 1;
    uint256 public constant PTYX = 2;
    uint256 public constant PTYY = 3;
    uint256 public constant PTZX = 4;
    uint256 public constant PTZY = 5;

    function ecTwistAdd(uint256[4] memory pt1, uint256[4] memory pt2) internal view returns (uint256[4] memory pt) {
        (uint256 xx, uint256 xy, uint256 yx, uint256 yy) =
            ecTwistAdd(pt1[0], pt1[1], pt1[2], pt1[3], pt2[0], pt2[1], pt2[2], pt2[3]);
        pt = [xx, xy, yx, yy];
    }

    /**
     * @notice Add two twist points
     * @param pt1xx Coefficient 1 of x on point 1
     * @param pt1xy Coefficient 2 of x on point 1
     * @param pt1yx Coefficient 1 of y on point 1
     * @param pt1yy Coefficient 2 of y on point 1
     * @param pt2xx Coefficient 1 of x on point 2
     * @param pt2xy Coefficient 2 of x on point 2
     * @param pt2yx Coefficient 1 of y on point 2
     * @param pt2yy Coefficient 2 of y on point 2
     * @return (pt3xx, pt3xy, pt3yx, pt3yy)
     */
    function ecTwistAdd(
        uint256 pt1xx,
        uint256 pt1xy,
        uint256 pt1yx,
        uint256 pt1yy,
        uint256 pt2xx,
        uint256 pt2xy,
        uint256 pt2yx,
        uint256 pt2yy
    ) internal view returns (uint256, uint256, uint256, uint256) {
        if (pt1xx == 0 && pt1xy == 0 && pt1yx == 0 && pt1yy == 0) {
            if (!(pt2xx == 0 && pt2xy == 0 && pt2yx == 0 && pt2yy == 0)) {
                assert(isOnCurve(pt2xx, pt2xy, pt2yx, pt2yy));
            }
            return (pt2xx, pt2xy, pt2yx, pt2yy);
        } else if (pt2xx == 0 && pt2xy == 0 && pt2yx == 0 && pt2yy == 0) {
            assert(isOnCurve(pt1xx, pt1xy, pt1yx, pt1yy));
            return (pt1xx, pt1xy, pt1yx, pt1yy);
        }

        assert(isOnCurve(pt1xx, pt1xy, pt1yx, pt1yy));
        assert(isOnCurve(pt2xx, pt2xy, pt2yx, pt2yy));

        uint256[6] memory pt1 = [pt1xx, pt1xy, pt1yx, pt1yy, 1, 0];
        uint256[6] memory pt2 = [pt2xx, pt2xy, pt2yx, pt2yy, 1, 0];
        uint256[6] memory pt3 = ecTwistAddJacobian(pt1, pt2);

        return fromJacobian(pt3[PTXX], pt3[PTXY], pt3[PTYX], pt3[PTYY], pt3[PTZX], pt3[PTZY]);
    }

    function submod(uint256 a, uint256 b, uint256 n) internal pure returns (uint256) {
        return addmod(a, n - b, n);
    }

    function fq2Mul(uint256 xx, uint256 xy, uint256 yx, uint256 yy) internal pure returns (uint256, uint256) {
        return (
            submod(mulmod(xx, yx, FIELD_MODULUS), mulmod(xy, yy, FIELD_MODULUS), FIELD_MODULUS),
            addmod(mulmod(xx, yy, FIELD_MODULUS), mulmod(xy, yx, FIELD_MODULUS), FIELD_MODULUS)
        );
    }

    function fq2Muc(uint256 xx, uint256 xy, uint256 c) internal pure returns (uint256, uint256) {
        return (mulmod(xx, c, FIELD_MODULUS), mulmod(xy, c, FIELD_MODULUS));
    }

    function fq2Add(uint256 xx, uint256 xy, uint256 yx, uint256 yy) internal pure returns (uint256, uint256) {
        return (addmod(xx, yx, FIELD_MODULUS), addmod(xy, yy, FIELD_MODULUS));
    }

    function fq2Sub(uint256 xx, uint256 xy, uint256 yx, uint256 yy) internal pure returns (uint256 rx, uint256 ry) {
        return (submod(xx, yx, FIELD_MODULUS), submod(xy, yy, FIELD_MODULUS));
    }

    function fq2Div(uint256 xx, uint256 xy, uint256 yx, uint256 yy) internal view returns (uint256, uint256) {
        (yx, yy) = fq2Inv(yx, yy);
        return fq2Mul(xx, xy, yx, yy);
    }

    function fq2Inv(uint256 x, uint256 y) internal view returns (uint256, uint256) {
        uint256 inv =
            modInv(addmod(mulmod(y, y, FIELD_MODULUS), mulmod(x, x, FIELD_MODULUS), FIELD_MODULUS), FIELD_MODULUS);
        return (mulmod(x, inv, FIELD_MODULUS), FIELD_MODULUS - mulmod(y, inv, FIELD_MODULUS));
    }

    function isOnCurve(uint256 xx, uint256 xy, uint256 yx, uint256 yy) internal pure returns (bool) {
        uint256 yyx;
        uint256 yyy;
        uint256 xxxx;
        uint256 xxxy;
        (yyx, yyy) = fq2Mul(yx, yy, yx, yy);
        (xxxx, xxxy) = fq2Mul(xx, xy, xx, xy);
        (xxxx, xxxy) = fq2Mul(xxxx, xxxy, xx, xy);
        (yyx, yyy) = fq2Sub(yyx, yyy, xxxx, xxxy);
        (yyx, yyy) = fq2Sub(yyx, yyy, TWISTBX, TWISTBY);
        return yyx == 0 && yyy == 0;
    }

    function modInv(uint256 a, uint256 n) internal view returns (uint256 result) {
        bool success;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let freemem := mload(0x40)
            mstore(freemem, 0x20)
            mstore(add(freemem, 0x20), 0x20)
            mstore(add(freemem, 0x40), 0x20)
            mstore(add(freemem, 0x60), a)
            mstore(add(freemem, 0x80), sub(n, 2))
            mstore(add(freemem, 0xA0), n)
            success := staticcall(sub(gas(), 2000), 5, freemem, 0xC0, freemem, 0x20)
            result := mload(freemem)
        }
        // solhint-disable-next-line reason-string
        require(success);
    }

    function fromJacobian(uint256 pt1xx, uint256 pt1xy, uint256 pt1yx, uint256 pt1yy, uint256 pt1zx, uint256 pt1zy)
        internal
        view
        returns (uint256 pt2xx, uint256 pt2xy, uint256 pt2yx, uint256 pt2yy)
    {
        uint256 invzx;
        uint256 invzy;
        (invzx, invzy) = fq2Inv(pt1zx, pt1zy);
        (pt2xx, pt2xy) = fq2Mul(pt1xx, pt1xy, invzx, invzy);
        (pt2yx, pt2yy) = fq2Mul(pt1yx, pt1yy, invzx, invzy);
    }

    function ecTwistAddJacobian(uint256[6] memory pt1, uint256[6] memory pt2)
        public
        pure
        returns (uint256[6] memory pt3)
    {
        if (pt1[4] == 0 && pt1[5] == 0) {
            (pt3[PTXX], pt3[PTXY], pt3[PTYX], pt3[PTYY], pt3[PTZX], pt3[PTZY]) =
                (pt2[0], pt2[1], pt2[2], pt2[3], pt2[4], pt2[5]);
            return pt3;
        } else if (pt2[4] == 0 && pt2[5] == 0) {
            (pt3[PTXX], pt3[PTXY], pt3[PTYX], pt3[PTYY], pt3[PTZX], pt3[PTZY]) =
                (pt1[0], pt1[1], pt1[2], pt1[3], pt1[4], pt1[5]);
            return pt3;
        }

        (pt2[2], pt2[3]) = fq2Mul(pt2[2], pt2[3], pt1[4], pt1[5]); // U1 = y2 * z1
        (pt3[PTYX], pt3[PTYY]) = fq2Mul(pt1[2], pt1[3], pt2[4], pt2[5]); // U2 = y1 * z2
        (pt2[0], pt2[1]) = fq2Mul(pt2[0], pt2[1], pt1[4], pt1[5]); // V1 = x2 * z1
        (pt3[PTZX], pt3[PTZY]) = fq2Mul(pt1[0], pt1[1], pt2[4], pt2[5]); // V2 = x1 * z2

        if (pt2[0] == pt3[PTZX] && pt2[1] == pt3[PTZY]) {
            if (pt2[2] == pt3[PTYX] && pt2[3] == pt3[PTYY]) {
                (pt3[PTXX], pt3[PTXY], pt3[PTYX], pt3[PTYY], pt3[PTZX], pt3[PTZY]) =
                    ecTwistDoubleJacobian(pt1[0], pt1[1], pt1[2], pt1[3], pt1[4], pt1[5]);
                return pt3;
            }
            (pt3[PTXX], pt3[PTXY], pt3[PTYX], pt3[PTYY], pt3[PTZX], pt3[PTZY]) = (1, 0, 1, 0, 0, 0);
            return pt3;
        }

        (pt2[4], pt2[5]) = fq2Mul(pt1[4], pt1[5], pt2[4], pt2[5]); // W = z1 * z2
        (pt1[0], pt1[1]) = fq2Sub(pt2[2], pt2[3], pt3[PTYX], pt3[PTYY]); // U = U1 - U2
        (pt1[2], pt1[3]) = fq2Sub(pt2[0], pt2[1], pt3[PTZX], pt3[PTZY]); // V = V1 - V2
        (pt1[4], pt1[5]) = fq2Mul(pt1[2], pt1[3], pt1[2], pt1[3]); // V_squared = V * V
        (pt2[2], pt2[3]) = fq2Mul(pt1[4], pt1[5], pt3[PTZX], pt3[PTZY]); // V_squared_times_V2 = V_squared * V2
        (pt1[4], pt1[5]) = fq2Mul(pt1[4], pt1[5], pt1[2], pt1[3]); // V_cubed = V * V_squared
        (pt3[PTZX], pt3[PTZY]) = fq2Mul(pt1[4], pt1[5], pt2[4], pt2[5]); // newz = V_cubed * W
        (pt2[0], pt2[1]) = fq2Mul(pt1[0], pt1[1], pt1[0], pt1[1]); // U * U
        (pt2[0], pt2[1]) = fq2Mul(pt2[0], pt2[1], pt2[4], pt2[5]); // U * U * W
        (pt2[0], pt2[1]) = fq2Sub(pt2[0], pt2[1], pt1[4], pt1[5]); // U * U * W - V_cubed
        (pt2[4], pt2[5]) = fq2Muc(pt2[2], pt2[3], 2); // 2 * V_squared_times_V2
        (pt2[0], pt2[1]) = fq2Sub(pt2[0], pt2[1], pt2[4], pt2[5]); // A = U * U * W - V_cubed - 2 * V_squared_times_V2
        (pt3[PTXX], pt3[PTXY]) = fq2Mul(pt1[2], pt1[3], pt2[0], pt2[1]); // newx = V * A
        (pt1[2], pt1[3]) = fq2Sub(pt2[2], pt2[3], pt2[0], pt2[1]); // V_squared_times_V2 - A
        (pt1[2], pt1[3]) = fq2Mul(pt1[0], pt1[1], pt1[2], pt1[3]); // U * (V_squared_times_V2 - A)
        (pt1[0], pt1[1]) = fq2Mul(pt1[4], pt1[5], pt3[PTYX], pt3[PTYY]); // V_cubed * U2
        (pt3[PTYX], pt3[PTYY]) = fq2Sub(pt1[2], pt1[3], pt1[0], pt1[1]); // newy = U * (V_squared_times_V2 - A) - V_cubed * U2
    }

    function ecTwistDoubleJacobian(
        uint256 pt1xx,
        uint256 pt1xy,
        uint256 pt1yx,
        uint256 pt1yy,
        uint256 pt1zx,
        uint256 pt1zy
    ) public pure returns (uint256 pt2xx, uint256 pt2xy, uint256 pt2yx, uint256 pt2yy, uint256 pt2zx, uint256 pt2zy) {
        (pt2xx, pt2xy) = fq2Muc(pt1xx, pt1xy, 3); // 3 * x
        (pt2xx, pt2xy) = fq2Mul(pt2xx, pt2xy, pt1xx, pt1xy); // W = 3 * x * x
        (pt1zx, pt1zy) = fq2Mul(pt1yx, pt1yy, pt1zx, pt1zy); // S = y * z
        (pt2yx, pt2yy) = fq2Mul(pt1xx, pt1xy, pt1yx, pt1yy); // x * y
        (pt2yx, pt2yy) = fq2Mul(pt2yx, pt2yy, pt1zx, pt1zy); // B = x * y * S
        (pt1xx, pt1xy) = fq2Mul(pt2xx, pt2xy, pt2xx, pt2xy); // W * W
        (pt2zx, pt2zy) = fq2Muc(pt2yx, pt2yy, 8); // 8 * B
        (pt1xx, pt1xy) = fq2Sub(pt1xx, pt1xy, pt2zx, pt2zy); // H = W * W - 8 * B
        (pt2zx, pt2zy) = fq2Mul(pt1zx, pt1zy, pt1zx, pt1zy); // S_squared = S * S
        (pt2yx, pt2yy) = fq2Muc(pt2yx, pt2yy, 4); // 4 * B
        (pt2yx, pt2yy) = fq2Sub(pt2yx, pt2yy, pt1xx, pt1xy); // 4 * B - H
        (pt2yx, pt2yy) = fq2Mul(pt2yx, pt2yy, pt2xx, pt2xy); // W * (4 * B - H)
        (pt2xx, pt2xy) = fq2Muc(pt1yx, pt1yy, 8); // 8 * y
        (pt2xx, pt2xy) = fq2Mul(pt2xx, pt2xy, pt1yx, pt1yy); // 8 * y * y
        (pt2xx, pt2xy) = fq2Mul(pt2xx, pt2xy, pt2zx, pt2zy); // 8 * y * y * S_squared
        (pt2yx, pt2yy) = fq2Sub(pt2yx, pt2yy, pt2xx, pt2xy); // newy = W * (4 * B - H) - 8 * y * y * S_squared
        (pt2xx, pt2xy) = fq2Muc(pt1xx, pt1xy, 2); // 2 * H
        (pt2xx, pt2xy) = fq2Mul(pt2xx, pt2xy, pt1zx, pt1zy); // newx = 2 * H * S
        (pt2zx, pt2zy) = fq2Mul(pt1zx, pt1zy, pt2zx, pt2zy); // S * S_squared
        (pt2zx, pt2zy) = fq2Muc(pt2zx, pt2zy, 8); // newz = 8 * S * S_squared
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.3) (interfaces/IERC1967.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 *
 * _Available since v4.9._
 */
interface IERC1967Upgradeable {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}