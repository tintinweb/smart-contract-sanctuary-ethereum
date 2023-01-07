// SPDX-License-Identifier: WISE

pragma solidity =0.8.17;

import "./Events.sol";
import "./Helpers.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract LotteryETH is Helpers, Events, VRFConsumerBaseV2 {

    ILinkToken immutable LINK;
    IVRFCoordinatorV2 immutable COORDINATOR;

    modifier onlyMaster() {
        require(
            msg.sender == master,
            "LotteryETH: NOT_MASTER"
        );
        _;
    }

    modifier onlyPurchasePhase(
        uint256 _lotteryIndex
    ) {
        require(
            getStatus(_lotteryIndex) == Status.PURCHASING,
            "LotteryETH: NOT_PURCHASING_PHASE"
        );
        _;
    }

    modifier onlyOraclePhase(
        uint256 _lotteryIndex
    ) {
        if (readyForOracle(_lotteryIndex) == false) {
            revert("LotteryETH: NOT_READY_YET");
        }

        if (getStatus(_lotteryIndex) == Status.FINALIZED) {
            revert("LotteryETH: ALREADY_FINALIZED");
        }

        if (_getRetry(_lotteryIndex) == false) {
            revert("LotteryETH: INVALID_RETRY");
        }
        _;
    }

    modifier onlyFinalizedPhase(
        uint256 _lotteryIndex
    ) {
        require(
            getStatus(_lotteryIndex) == Status.FINALIZED,
            "LotteryETH: LOTTERY_NOT_FINALIZED"
        );
        _;
    }

    constructor(
        address _coordinatorAddress
    )
        VRFConsumerBaseV2(
            _coordinatorAddress
        )
    {
        master = msg.sender;
        usageFee = 5;

        COORDINATOR = IVRFCoordinatorV2(
            _coordinatorAddress
        );

        LINK = ILinkToken(
            LINK_TOKEN_ADDRESS
        );

        subscriptionId = COORDINATOR.createSubscription();

        COORDINATOR.addConsumer(
            subscriptionId,
            address(this)
        );
    }

    function createLottery(
        address _nftAddress,
        uint256 _nftId,
        address _sellToken,
        uint256 _totalPrice,
        uint256 _ticketCount,
        uint256 _lotteryTime
    )
        external
    {
        _createLottery(
            msg.sender,
            _nftAddress,
            _nftId,
            _sellToken,
            _totalPrice,
            _ticketCount,
            _lotteryTime
        );

        _transferNFT(
            msg.sender,
            address(this),
            _nftAddress,
            _nftId
        );

        emit LotteryCreated(
            msg.sender,
            lotteryCount,
            _nftAddress,
            _nftId,
            _sellToken,
            _totalPrice,
            _ticketCount,
            _lotteryTime
        );

        _increaseLotteryCount();
    }

    function buyTickets(
        uint256 _lotteryIndex,
        uint256 _ticketCount
    )
        external
        payable
        onlyPurchasePhase(
            _lotteryIndex
        )
    {
        _enoughTickets(
            _lotteryIndex,
            _ticketCount
        );

        (
            uint256 startNumber,
            uint256 finalNumber

        ) = _performTicketBuy(
            _lotteryIndex,
            _ticketCount,
            msg.sender,
            msg.value
        );

        emit BuyTickets(
            _lotteryIndex,
            startNumber,
            finalNumber,
            msg.sender
        );
    }

    function giftTickets(
        uint256 _lotteryIndex,
        uint256 _ticketCount,
        address _recipient
    )
        external
        payable
        onlyPurchasePhase(
            _lotteryIndex
        )
    {
        _enoughTickets(
            _lotteryIndex,
            _ticketCount
        );

        (
            uint256 startNumber,
            uint256 finalNumber

        ) = _performTicketBuy(
            _lotteryIndex,
            _ticketCount,
            _recipient,
            msg.value
        );

        emit GiftTickets(
            _lotteryIndex,
            startNumber,
            finalNumber,
            msg.sender,
            _recipient
        );
    }

    function _performTicketBuy(
        uint256 _lotteryIndex,
        uint256 _ticketCount,
        address _recipient,
        uint256 _payment
    )
        internal
        returns (
            uint256 startNumber,
            uint256 finalNumber
        )
    {
        TicketData storage data = ticketData[
            _lotteryIndex
        ];

        require(
            _payment == data.ticketPrice * _ticketCount,
            "LotteryETH: INVALID_PAYMENT_AMOUNT"
        );

        startNumber = data.soldTickets;
        finalNumber = startNumber + _ticketCount;

        for (uint256 i = startNumber; i < finalNumber; ++i) {
            tickets[_lotteryIndex][i] = _recipient;
        }

        data.soldTickets =
        data.soldTickets + _ticketCount;
    }

    function claimLottery(
        uint256 _lotteryIndex
    )
        external
    {
        BaseData memory baseData = baseData[
            _lotteryIndex
        ];

        require(
            msg.sender == baseData.winner,
            "LotteryETH: INVALID_CALLER"
        );

        _transferNFT(
            address(this),
            baseData.winner,
            baseData.nftAddress,
            baseData.nftId
        );
    }

    function rescueLottery(
        uint256 _lotteryIndex
    )
        external
    {
        BaseData memory baseData = baseData[
            _lotteryIndex
        ];

        if (block.timestamp < baseData.closingTime + DEADLINE_REDEEM) {
            revert("LotteryETH: STILL_CLAIMABLE");
        }

        _transferNFT(
            address(this),
            master,
            baseData.nftAddress,
            baseData.nftId
        );
    }

    function concludeLottery(
        uint256 _lotteryIndex
    )
        external
        onlyFinalizedPhase(
            _lotteryIndex
        )
    {
        BaseData memory baseDataRound = baseData[
            _lotteryIndex
        ];

        (
            address winner,
            uint256 luckyNumber,
            uint256 soldAmount

        ) = _getLuckyNumber(
            _lotteryIndex
        );

        address winnerAddress = winner == ZERO_ADDRESS
            ? baseDataRound.owner
            : winner;

        uint256 fee = applyUsageFee(
            usageFee,
            soldAmount
        );

        _closeRound(
            _lotteryIndex,
            luckyNumber,
            winnerAddress
        );

        payable(baseDataRound.owner).transfer(
            soldAmount - fee
        );

        payable(master).transfer(
            fee
        );

        emit ConcludeRound(
            baseDataRound.nftAddress,
            winnerAddress,
            baseDataRound.nftId,
            luckyNumber,
            _lotteryIndex
        );
    }

    function requestRandomNumber(
        uint256 _lotteryIndex
    )
        external
        onlyOraclePhase(
            _lotteryIndex
        )
    {
        uint256 requestId = COORDINATOR.requestRandomWords(
            KEY_HASH,
            subscriptionId,
            CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            1
        );

        _setRequested(
            _lotteryIndex
        );

        requestIdToIndex[requestId] = _lotteryIndex;

        emit RequestRandomNumberForRound(
            _lotteryIndex,
            requestId,
            true
        );
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    )
        internal
        override
    {
        uint256 lotteryIndex = requestIdToIndex[
            _requestId
        ];

        ticketData[lotteryIndex].luckyNumber = uniform(
            _randomWords[0],
            ticketData[lotteryIndex].totalTickets
        );

        _setFinalized(
            lotteryIndex
        );

        emit RandomWordsFulfilled(
            lotteryIndex,
            ticketData[lotteryIndex].luckyNumber
        );
    }

    function loadSubscription(
        uint256 _amount
    )
        external
    {
        _safeTransferFrom(
            LINK_TOKEN_ADDRESS,
            msg.sender,
            address(this),
            _amount
        );

        LINK.transferAndCall(
            address(COORDINATOR),
            _amount,
            abi.encode(subscriptionId)
        );
    }

    function changeUsageFee(
        uint256 _amount
    )
        external
        onlyMaster
    {
        if (_amount > MAX_FEE_PERCENTAGE) {
            revert("LotteryETH: FEE_TOO_HIGH");
        }

        usageFee = _amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: WISE

pragma solidity =0.8.17;

import "./Declerations.sol";
import "./TransferHelper.sol";

contract Helpers is Declerations, TransferHelper {

    function _setRequested(
        uint256 _lotteryIndex
    )
        internal
    {
        baseData[_lotteryIndex].status = Status.REQUEST_ORACLE;
        baseData[_lotteryIndex].timeLastRequest = block.timestamp;
    }

    function _setFinalized(
        uint256 _lotteryIndex
    )
        internal
    {
        baseData[_lotteryIndex].status = Status.FINALIZED;
    }

    function _increaseLotteryCount()
        internal
    {
        lotteryCount += 1;
    }

    function getStatus(
        uint256 _lotteryIndex
    )
        public
        view
        returns (Status)
    {
        return baseData[_lotteryIndex].status;
    }

    function _getTicketPrice(
        uint256 _totalPrice,
        uint256 _ticketCount
    )
        internal
        pure
        returns (uint256 res)
    {
        res = _totalPrice
            / _ticketCount;
    }

    function _getRetry(
        uint256 _lotteryIndex
    )
        internal
        view
        returns (bool)
    {
        return block.timestamp > _nextRetry(
            _lotteryIndex
        );
    }

    function _nextRetry(
        uint256 _lotteryIndex
    )
        internal
        view
        returns (uint256)
    {
        return baseData[_lotteryIndex].timeLastRequest + SECONDS_IN_DAY;
    }

    function applyUsageFee(
        uint256 _usageFee,
        uint256 _soldAmount
    )
        public
        pure
        returns (uint256)
    {
        return _soldAmount * _usageFee / PERCENT_BASE;
    }

    function calculateSoldAmount(
        uint256 _lotteryIndex
    )
        public
        view
        returns (uint256 res)
    {
        res = ticketData[_lotteryIndex].ticketPrice
            * ticketData[_lotteryIndex].soldTickets;
    }

    function _getDeadline(
        uint256 _secondsToPass
    )
        internal
        view
        returns (uint256)
    {
        return block.timestamp + _secondsToPass;
    }

    function _enoughTickets(
        uint256 _lotteryIndex,
        uint256 _numberTickets
    )
        internal
        view
    {
        if (hasEnoughTickets(_lotteryIndex, _numberTickets) == false) {
            revert("Helpers: NOT_ENOUGH_TICKETS_LEFT");
        }
    }

    function hasEnoughTickets(
        uint256 _lotteryIndex,
        uint256 _numberTickets
    )
        public
        view
        returns (bool)
    {
        return ticketData[_lotteryIndex].totalTickets
            >= ticketData[_lotteryIndex].soldTickets + _numberTickets;
    }

    function readyForOracle(
        uint256 _lotteryIndex
    )
        public
        view
        returns (bool)
    {
        if (block.timestamp > baseData[_lotteryIndex].closingTime) {
            return true;
        }

        TicketData memory tickets = ticketData[
            _lotteryIndex
        ];

        if (tickets.soldTickets == tickets.totalTickets) {
            return true;
        }

        return false;
    }

    function _getLuckyNumber(
        uint256 _lotteryIndex
    )
        internal
        view
        returns (
            address,
            uint256,
            uint256
        )
    {
        uint256 luckyNumber = ticketData[_lotteryIndex]
            .luckyNumber;

        uint256 soldAmount = calculateSoldAmount(
            _lotteryIndex
        );

        return (
            tickets[_lotteryIndex][luckyNumber],
            luckyNumber,
            soldAmount
        );
    }

    function _createLottery(
        address _owner,
        address _nftAddress,
        uint256 _nftId,
        address _sellToken,
        uint256 _totalPrice,
        uint256 _ticketCount,
        uint256 _time
    )
        internal
    {
        uint256 deadline = _getDeadline(
            _time
        );

        uint256 ticketPrice = _getTicketPrice(
            _totalPrice,
            _ticketCount
        );

        baseData[lotteryCount] = BaseData({
            status: Status.PURCHASING,
            owner: _owner,
            winner: ZERO_ADDRESS,
            nftAddress: _nftAddress,
            sellToken: _sellToken,
            nftId: _nftId,
            closingTime: deadline,
            timeLastRequest: 0
        });

        ticketData[lotteryCount] = TicketData({
            totalPrice: _totalPrice,
            ticketPrice: ticketPrice,
            totalTickets: _ticketCount,
            luckyNumber: 0,
            soldTickets: 0
        });
    }

    function _closeRound(
        uint256 _lotteryIndex,
        uint256 _luckyNumber,
        address _winnerAddress
    )
        internal
    {
        baseData[_lotteryIndex].winner = _winnerAddress;
        baseData[_lotteryIndex].closingTime = block.timestamp;
        ticketData[_lotteryIndex].luckyNumber = _luckyNumber;
    }

    function uniform(
        uint256 _entropy,
        uint256 _upperBound
    )
        public
        pure
        returns (uint256)
    {
        uint256 min = (type(uint256).max - _upperBound + 1)
            % _upperBound;

        uint256 random = _entropy;

        while (true) {
            if (random >= min) {
                break;
            }

            random = uint256(
                keccak256(
                    abi.encodePacked(
                        random
                    )
                )
            );
        }

        return random
            % _upperBound;
    }
}

// SPDX-License-Identifier: WISE

pragma solidity =0.8.17;

contract Events {

    event BuyTickets(
        uint256 indexed lotteryIndex,
        uint256 startNumber,
        uint256 finalNumber,
        address indexed buyer
    );

    event GiftTickets(
        uint256 indexed index,
        uint256 startNumber,
        uint256 finalNumber,
        address indexed buyer,
        address indexed recipient
    );

    event LotteryCreated(
        address owner,
        uint256 indexed lotteryIndex,
        address indexed nftAddress,
        uint256 indexed nftId,
        address sellToken,
        uint256 sellAmount,
        uint256 totalTickets,
        uint256 time
    );

    event ConcludeRound(
        address indexed nftAddress,
        address indexed nftWinner,
        uint256 indexed nftId,
        uint256 luckNumber,
        uint256 lotteryIndex
    );

    event RandomWordsFulfilled(
        uint256 indexed lotteryIndex,
        uint256 indexed luckyNumber
    );

    event RequestRandomNumberForRound(
        uint256 indexed lotteryIndex,
        uint256 indexed requestId,
        bool indexed requested
    );
}

// SPDX-License-Identifier: WISE

pragma solidity =0.8.17;

contract TransferHelper {

    function _transferNFT(
        address _from,
        address _to,
        address _tokenAddress,
        uint256 _tokenId
    )
        internal
    {
        bytes memory data = abi.encodeWithSignature(
            'safeTransferFrom(address,address,uint256)',
            _from,
            _to,
            _tokenId
        );

        (bool success,) = address(_tokenAddress).call(
            data
        );

        require(
            success,
            'TransferHelper: NFT_TRANSFER_FAILED'
        );
    }

    /* @dev
    * Checks if contract is nonstandard, does transferFrom according to contract implementation
    */
    function _transferFromNFT(
        address _from,
        address _to,
        address _tokenAddress,
        uint256 _tokenId
    )
        internal
    {
        bytes memory data;

        data = abi.encodeWithSignature(
            'safeTransferFrom(address,address,uint256)',
            _from,
            _to,
            _tokenId
        );

        (bool success, bytes memory resultData) = address(_tokenAddress).call(
            data
        );

        require(
            success,
            string(resultData)
        );
    }

    event ERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes data
    );

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    )
        external
        returns (bytes4)
    {
        emit ERC721Received(
            _operator,
            _from,
            _tokenId,
            _data
        );

        return this.onERC721Received.selector;
    }

    /**
     * @dev encoding for transfer
     */
    bytes4 constant TRANSFER = bytes4(
        keccak256(
            bytes(
                'transfer(address,uint256)'
            )
        )
    );

    /**
     * @dev encoding for transferFrom
     */
    bytes4 constant TRANSFER_FROM = bytes4(
        keccak256(
            bytes(
                'transferFrom(address,address,uint256)'
            )
        )
    );

    /**
     * @dev does an erc20 transfer then check for success
     */
    function _safeTransfer(
        address _token,
        address _to,
        uint256 _value
    )
        internal
    {
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(
                TRANSFER,
                _to,
                _value
            )
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper: TRANSFER_FAILED'
        );
    }

    /**
     * @dev does an erc20 transferFrom then check for success
     */
    function _safeTransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _value
    )
        internal
    {
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(
                TRANSFER_FROM,
                _from,
                _to,
                _value
            )
        );

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper: TRANSFER_FROM_FAILED'
        );
    }
}

// SPDX-License-Identifier: WISE

pragma solidity =0.8.17;

import "./Interfaces.sol";

contract Declerations {

    address public master;
    uint256 public usageFee;
    uint256 public lotteryCount;

    uint64 public subscriptionId;

    uint256 constant public MAX_VALUE_HOUSE_PERCENTAGE = 50;
    uint256 constant public MAX_FEE_PERCENTAGE = 10;
    uint256 constant public PERCENT_BASE = 100;
    uint256 constant public DEADLINE_REDEEM = 30 days;
    uint256 constant public SECONDS_IN_DAY = 86400;
    uint32 constant public CALLBACK_GAS_LIMIT = 250000;
    uint16 constant public CONFIRMATIONS = 5;

    address constant public ZERO_ADDRESS = address(0x0);

    address constant public LINK_TOKEN_ADDRESS = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    bytes32 constant public KEY_HASH = 0xff8dedfbfa60af186cf3c830acbc32c05aae823045ae5ea7da1e45fbfaba4f92;

    enum Status {
        PURCHASING,
        REQUEST_ORACLE,
        FINALIZED
    }

    struct BaseData {
        Status status;
        address owner;
        address winner;
        address nftAddress;
        uint256 nftId;
        address sellToken;
        uint256 closingTime;
        uint256 timeLastRequest;
    }

    struct TicketData {
        uint256 totalPrice;
        uint256 ticketPrice;
        uint256 totalTickets;
        uint256 soldTickets;
        uint256 luckyNumber;
    }

    mapping(uint256 => BaseData) public baseData;
    mapping(uint256 => TicketData) public ticketData;

    // this is for oracle to store requestID
    mapping(uint256 => uint256) public requestIdToIndex;

    // to store ticket ownership per address per lottery
    mapping(uint256 => mapping(uint256 => address)) public tickets;
}

// SPDX-License-Identifier: WISE

pragma solidity =0.8.17;

interface IVRFCoordinatorV2 {

    function addConsumer(
        uint64 subId,
        address consumer
    )
        external;

    function createSubscription()
        external
        returns (uint64 subId);

    function requestRandomWords(
        bytes32 keyHash,
        uint64 subId,
        uint16 minimumRequestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords
    )
        external
        returns (uint256 requestId);
}

interface ILinkToken {

    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    )
        external
        returns (bool success);
}