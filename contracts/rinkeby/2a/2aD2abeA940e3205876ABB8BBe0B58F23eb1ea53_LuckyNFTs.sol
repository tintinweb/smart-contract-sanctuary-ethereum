// SPDX-License-Identifier: WISE

pragma solidity =0.8.15;

import "./Helpers.sol";
import "./LuckyNFTsEvents.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract LuckyNFTs is Helpers, VRFConsumerBaseV2, LuckyNFTsEvents {

    ILinkToken immutable LINK;
    IVRFCoordinatorV2 immutable COORDINATOR;

    constructor()
        VRFConsumerBaseV2(
            COORDINATOR_ADDRESS
        )
    {
        master = msg.sender;
        usageFee = 5;

        COORDINATOR = IVRFCoordinatorV2(
            COORDINATOR_ADDRESS
        );

        LINK = ILinkToken(
            LINK_TOKEN_ADDRESS
        );

        subscriptionID = COORDINATOR.createSubscription();

        COORDINATOR.addConsumer(
            subscriptionID,
            address(this)
        );
    }

    function initializeRound( // consider rename (createLottery)
        address _nftAddress, // toketAddress
        address _sellToken,
        uint256 _nftID, // tokenID
        uint256 _totalPrice,
        uint256 _ticketNumber,
        uint256 _endTime // _endTime
    )
        external
    {
        _initializeRound(
            msg.sender,
            _nftAddress,
            _sellToken,
            _nftID,
            _totalPrice,
            _ticketNumber,
            _endTime
        );

        _transferNFT(
            msg.sender,
            address(this),
            _nftAddress,
            _nftID
        );

        emit InitializeRound(
            msg.sender,
            _nftAddress,
            _sellToken,
            _nftID,
            _totalPrice,
            _ticketNumber,
            _endTime
        );
    }

    function buyTicket(
        uint256 _index,
        uint256 _count
    )
        external
    {
        _checkState(
            _index,
            _count
        );

        uint256 startNumber = ticketData[_index].soldTickets;
        uint256 finalNumber = startNumber + _count;

        for (uint256 ticket = startNumber; ticket < finalNumber; ticket++) {
            tickets[_index][ticket] = msg.sender;
        }

        ticketData[_index].soldTickets =
        ticketData[_index].soldTickets + _count;

        _safeTransferFrom(
            baseData[_index].sellToken,
            msg.sender,
            address(this),
            ticketData[_index].ticketPrice * _count
        );

        emit BuyTicket(
            _index,
            startNumber,
            _count,
            msg.sender
        );
    }

    function getNFTforWinner( // consider rename
        uint256 _index
    )
        external
    {
        BaseData memory baseData = baseData[_index];

        if (msg.sender != baseData.winner)
            revert("LuckyNFTs: INVALID_CALLER");

        _transferNFT( // should we use safeTransfer
            address(this),
            baseData.winner,
            baseData.nftAddress,
            baseData.nftID
        );
    }

    function redeemNotClaimedNFT( // consider rename together with (getNFTforWinner)
        uint256 _index
    )
        external
    {
        BaseData memory baseData = baseData[_index];

        if (block.timestamp < baseData.closingTime + DEADLINE_REEDEM)
            revert("LuckyNFTs: REDEEM_TOO_EARLY");

        _transferNFT(
            address(this),
            master,
            baseData.nftAddress,
            baseData.nftID
        );
    }

    function concludeRound(
        uint256 _index
    )
        external
    {
        BaseData memory baseDataRound = baseData[_index];

        if (getStatus(_index) != Status.FINALIZED)
            revert("LuckyNFTs: NOT_FINALIZED");

        (
            address winner,
            uint256 luckyNumber,
            uint256 soldAmount
        )
        = _drawingOfLot(
            _index
        );

        address winnerAddress = winner == ZERO_ADDRESS
            ? baseDataRound.owner
            : winner;

        uint256 fee = applyUsageFee(
            usageFee,
            soldAmount
        );

        _closeRound(
            _index,
            luckyNumber,
            winnerAddress
        );

        _safeTransfer(
            baseDataRound.sellToken,
            baseDataRound.owner,
            soldAmount - fee
        );

        _safeTransfer(
            baseDataRound.sellToken,
            master,
            fee
        );

        emit ConcludeRound(
            baseDataRound.nftAddress,
            winnerAddress,
            baseDataRound.nftID,
            luckyNumber,
            _index
        );
    }

    // One call costs 0.25 LINK token for a random number
    function requestRandomNumberForRound(
        uint256 _index
    )
        external
    {
        if (getStatus(_index) == Status.FINALIZED)
            revert("LuckyNFTs: NUMBER_RECEIVED");

        if (readyForDrawing(_index) == false)
            revert("LuckyNFTs: NOT_READY_FOR_DRAWING");

        if (_getRetry(_index) == false) {

            if (getStatus(_index) != Status.PURCHASING)
                revert("LuckyNFTs: WAITING_FOR_NUMBER");
        }

        uint256 requestID = COORDINATOR.requestRandomWords(
            KEY_HASH,
            subscriptionID,
            CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            1
        );

        requestIDToIndex[requestID] = _index;

        baseData[_index].timeLastRequest = block.timestamp;

        _setRequested(
            _index
        );

        emit RequestRandomNumberForRound(
            _index,
            requestID,
            true
        );
    }

    function fulfillRandomWords(
        uint256 _requestID,
        uint256[] memory _randomWords
    )
        internal
        override
    {
        uint256 index = requestIDToIndex[_requestID];

        ticketData[index].luckyNumber = uniform(
            _randomWords[0],
            ticketData[index].totalTickets
        );

        _setFinalized(
            index
        );

        emit RandomwordFulfilled(
            index,
            ticketData[index].luckyNumber,
            true
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
            abi.encode(subscriptionID)
        );
    }

    function changeUsageFee(
        uint256 _amount
    )
        external
    {
        if (msg.sender != master)
            revert("LuckyNFTs: NOT_MASTER");

        if (_amount > MAX_FEE_PERCENTAGE)
            revert("LuckyNFTs: FEE_TOO_HIGH");

        usageFee = _amount;
    }
}

// SPDX-License-Identifier: WISE

pragma solidity =0.8.15;

contract TransferLuckyNFTs {

    //cryptoPunks contract address
    address constant PUNKS = 0x2f1dC6E3f732E2333A7073bc65335B90f07fE8b0;
    // ropsten : 0xEb59fE75AC86dF3997A990EDe100b90DDCf9a826;
    // mainnet : 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;

    //cryptoKitties contract address
    address constant KITTIES = 0x06012c8cf97BEaD5deAe237070F9587f8E7A266d;

    /* @dev
    * Checks if contract is nonstandard, does transfer according to contract implementation
    */
    function _transferNFT(
        address _from,
        address _to,
        address _tokenAddress,
        uint256 _tokenId
    )
        internal
    {
        bytes memory data;

        if (_tokenAddress == KITTIES) {
            data = abi.encodeWithSignature(
                'transfer(address,uint256)',
                _to,
                _tokenId
            );
        } else if (_tokenAddress == PUNKS) {
            data = abi.encodeWithSignature(
                'transferPunk(address,uint256)',
                _to,
                _tokenId
            );
        } else {
            data = abi.encodeWithSignature(
                'safeTransferFrom(address,address,uint256)',
                _from,
                _to,
                _tokenId
            );
        }

        (bool success,) = address(_tokenAddress).call(
            data
        );

        require(
            success,
            'NFT_TRANSFER_FAILED'
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

        if (_tokenAddress == KITTIES) {

            data = abi.encodeWithSignature(
                'transferFrom(address,address,uint256)',
                _from,
                _to,
                _tokenId
            );

        } else if (_tokenAddress == PUNKS) {

            bytes memory punkIndexToAddress = abi.encodeWithSignature(
                'punkIndexToAddress(uint256)',
                _tokenId
            );

            (bool checkSuccess, bytes memory result) = address(_tokenAddress).staticcall(
                punkIndexToAddress
            );

            (address owner) = abi.decode(
                result,
                (address)
            );

            require(
                checkSuccess &&
                owner == msg.sender,
                'INVALID_OWNER'
            );

            bytes memory buyData = abi.encodeWithSignature(
                'buyPunk(uint256)',
                _tokenId
            );

            (bool buySuccess, bytes memory buyResultData) = address(_tokenAddress).call(
                buyData
            );

            require(
                buySuccess,
                string(buyResultData)
            );

            data = abi.encodeWithSignature(
                'transferPunk(address,uint256)',
                _to,
                _tokenId
            );

        } else {

            data = abi.encodeWithSignature(
                'safeTransferFrom(address,address,uint256)',
                _from,
                _to,
                _tokenId
            );
        }

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
            'PoolHelper: TRANSFER_FAILED'
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
            'PoolHelper: TRANSFER_FROM_FAILED'
        );
    }
}

// SPDX-License-Identifier: WISE

pragma solidity =0.8.15;


contract LuckyNFTsEvents {

    event BuyTicket(
        uint256 indexed index,
        uint256 indexed totalTickets,
        uint256 numberOfTickets,
        address indexed customer
    );

    event InitializeRound(
        address indexed owner,
        address indexed nftAddress,
        address sellToken,
        uint256 indexed nftID,
        uint256 sellAmount,
        uint256 totalTickets,
        uint256 time
    );

    event ConcludeRound(
        address indexed nftAddress,
        address indexed winner,
        uint256 indexed nftID,
        uint256 luckNumber,
        uint256 index
    );

    event RandomwordFulfilled(
        uint256 indexed index,
        uint256 indexed luckyNumber,
        bool indexed fulfilled
    );

    event RequestRandomNumberForRound(
        uint256 indexed index,
        uint256 indexed requestID,
        bool indexed requested
    );
}

// SPDX-License-Identifier: WISE

pragma solidity = 0.8.15;

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

// SPDX-License-Identifier: WISE

pragma solidity = 0.8.15;

import "./Declerations.sol";
import "./TransferLuckyNFTs.sol";

contract Helpers is Declerations, TransferLuckyNFTs {

    function _setRequested(
        uint256 _index
    )
        internal
    {
        baseData[_index].status = Status.REQUEST_ORACLE;
    }

    function _setFinalized(
        uint256 _index
    )
        internal
    {
        baseData[_index].status = Status.FINALIZED;
    }

    function _increasLatestIndex(
    )
        internal
    {
        latesIndex += 1;
    }

    function getStatus(
        uint256 _index
    )
        public
        view
        returns (Status)
    {
        return baseData[_index].status;
    }

    function _getTicketPrice(
        uint256 _totalPrice,
        uint256 _ticketNumber
    )
        internal
        pure
        returns (uint256)
    {
        return _totalPrice / _ticketNumber;
    }

    function _getRetry(
        uint256 _index
    )
        internal
        view
        returns (bool)
    {
        return block.timestamp >
            SECONDS_IN_DAY + baseData[_index].timeLastRequest;
    }

    function applyUsageFee( // consider rename
        uint256 _usageFee,
        uint256 _soldAmount
    )
        public
        pure
        returns (uint256)
    {
        return _soldAmount
            * _usageFee
            / ONE_HUNDRED;
    }

    function calculateSoldAmount(
        uint256 _index
    )
        public
        view
        returns (uint256)
    {
        return ticketData[_index].ticketPrice
            * ticketData[_index].soldTickets;
    }

    function _getDeadline(
        uint256 _time
    )
        internal
        view
        returns (uint256)
    {
        return block.timestamp + _time;
    }

    function _checkState(
        uint256 _index,
        uint256 _numberTickets
    )
        internal
        view
    {
        if (getStatus(_index) != Status.PURCHASING)
            revert("Helpers: NO_PURCHASING_PHASE");

        if (checkSoldTickets(_index, _numberTickets))
            revert("Helpers: NOT_ENOUGH_TICKETS_LEFT");
    }

    function checkSoldTickets(
        uint256 _index,
        uint256 _numberTickets
    )
        public
        view
        returns (bool)
    {
        return ticketData[_index].totalTickets
            < (ticketData[_index].soldTickets + _numberTickets);
    }

    function readyForDrawing(
        uint256 _index
    )
        public
        view
        returns (bool)
    {
        if (block.timestamp > baseData[_index].closingTime) {
            return true;
        }

        if (checkSoldTickets(_index, 1)) {
            return true;
        }

        return false;
    }

    function _drawingOfLot( // consider rename
        uint256 _index
    )
        internal
        view
        returns (
            address,
            uint256,
            uint256
        )
    {
        uint256 luckyNumber = ticketData[_index].luckyNumber;
        uint256 soldAmount = calculateSoldAmount(
            _index
        );

        return (
            tickets[_index][luckyNumber],
            luckyNumber,
            soldAmount
        );
    }

    function _initializeRound(
        address _owner,
        address _nftAddress,
        address _sellToken,
        uint256 _nftID,
        uint256 _totalPrice,
        uint256 _numberTickets,
        uint256 _time
    )
        internal
    {
        _increasLatestIndex(); // consider rename: increaseLotteryCount

        uint256 deadline = _getDeadline(
            _time
        );

        uint256 ticketPrice = _getTicketPrice(
            _totalPrice,
            _numberTickets
        );

        baseData[latesIndex] = BaseData({
            status: Status.PURCHASING,
            owner: _owner,
            winner: ZERO_ADDRESS,
            nftAddress: _nftAddress,
            sellToken: _sellToken,
            nftID: _nftID,
            closingTime: deadline,
            timeLastRequest: 0
        });

        ticketData[latesIndex] = TicketData({
            totalPrice: _totalPrice,
            ticketPrice: ticketPrice,
            totalTickets: _numberTickets,
            luckyNumber: 0,
            soldTickets: 0
        });
    }

    function _closeRound(
        uint256 _index,
        uint256 _luckyNumber,
        address _winner
    )
        internal
    {
        baseData[_index].winner = _winner;
        baseData[_index].closingTime = block.timestamp;
        ticketData[_index].luckyNumber = _luckyNumber;
    }

    function uniform(
        uint256 _entropy,
        uint256 _upperBound
    )
        public
        pure
        returns (uint256)
    {
        uint256 min = (type(uint256).max - _upperBound + 1) % _upperBound;
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

        return random % _upperBound;
    }
}

// SPDX-License-Identifier: WISE

pragma solidity = 0.8.15;

import './Interfaces.sol';

contract Declerations {

    address public master;
    uint256 public usageFee;
    uint256 public latesIndex;

    uint64 public subscriptionID;

    uint256 constant public MAX_VALUE_HOUSE_PERCENTAGE = 50;
    uint256 constant public MAX_FEE_PERCENTAGE = 10;
    uint256 constant public ONE_HUNDRED = 100;
    uint256 constant public DEADLINE_REEDEM = 5184000; // 60 days in seconds
    uint256 constant public SECONDS_IN_DAY = 60 * 60 * 24;

    uint32 constant public CALLBACK_GAS_LIMIT = 100000;
    uint16 constant public CONFIRMATIONS = 3;

    address constant public ZERO_ADDRESS = address(0x0);

    //address constant public COORDINATOR_ADDRESS = 0xD6a6B880c546c255bBdeAa9acA874129f7367Ac3;   // local
    address constant public COORDINATOR_ADDRESS = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;  // Rinkeby testnet
    //address constant public COORDINATOR_ADDRESS = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;  // ETH main

    //address constant public LINK_TOKEN_ADDRESS = 0x514910771AF9Ca656af840dff83E8264EcF986CA;   // ETH main
    address constant public LINK_TOKEN_ADDRESS = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709; // Rinkeby testnet
    bytes32 constant public KEY_HASH = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;

    enum Status {
        PURCHASING,
        REQUEST_ORACLE,
        FINALIZED
    }

    struct BaseData {
        Status status;
        address owner;
        address winner;
        address nftAddress; // tokenAddress
        address sellToken;
        uint256 nftID; // tokenID
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
    mapping(uint256 => uint256) public requestIDToIndex;

    // to store ticket ownership per address per lottery
    mapping(uint256 => mapping(uint256 => address)) public tickets;
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