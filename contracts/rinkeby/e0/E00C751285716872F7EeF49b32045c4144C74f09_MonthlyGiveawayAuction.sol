//SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./YearlyGiveawayAuction.sol";
import "./VRFv2Consumer.sol";

abstract contract IMonthlyGiveawayAuction {
    function pushingDailyPlayersToMonthlyPlayerList(
        address[] memory _dailyPlayersList
    ) public virtual;

    function resetMonthlyGiveaway() internal virtual;

    function getMonthlyPlayer(uint256 index)
        public
        view
        virtual
        returns (address);

    function pushingDailyPlayersToMonthlyPlayerList(address _dailyPlayer)
        public
        virtual;

    function pushingWinnerAuctionToMonthlyPlayerList(
        address _dailyWinnerAuction
    ) public virtual;

    function getBalance() public view virtual returns (uint256);
}

/**
 * @title MonthlyGiveawayAuction
 * @dev Ether Giveaway that transfer contract amount to winner
 */
contract MonthlyGiveawayAuction is VRFv2Consumer {
    bool public startedMonthly;
    bool public endedMonthly;
    uint256 public endAtMonthly;

    //list of players registered in lotery
    address payable[] public monthlyPlayers;
    address payable[] public monthlyDailyWinnerAuction;
    address public admin;
    address payable monthlyWinnerBidder;
    address payable monthlyWinnerAuctionWinner;

    // public, private, internal or what?
    uint256 public OUROWNTOKENID;

    uint256 public percentageMonthlyWinner = 30;
    uint256 public percentageMonthlyBidders = 20;

    //mapping(address => uint256) public bids;

    // info for interaction with MonthlyGiveawayAuction Contract
    address payable addressNFT;

    VRFv2Consumer vrf;

    constructor(address _addressNFT, uint64 _subscriptionId)
        VRFv2Consumer(_subscriptionId)
    {
        admin = msg.sender;
        addressNFT = payable(_addressNFT);
        startedMonthly = false;
        endedMonthly = true;
    }

    receive() external payable {}

    function startMonthlyAuction() external onlyOwner {
        require(startedMonthly == false, "Auction already started!");
        require(endedMonthly == true, "Auction is ended!");
        require(msg.sender == admin, "You cannot start the Auction!");

        startedMonthly = true;
        endedMonthly = false;

        // determining when the auction is ending automatically
        // endAtMonthly = block.timestamp + 30 days;
    }

    function pushingDailyPlayersToMonthlyPlayerList(address _dailyPlayer)
        public
    {
        monthlyPlayers.push(payable(_dailyPlayer));
    }

    function pushingWinnerAuctionToMonthlyPlayerList(
        address _dailyWinnerAuction
    ) public {
        monthlyDailyWinnerAuction.push(payable(_dailyWinnerAuction));
    }

    /**
     * @dev ending the auction and calling the dailyGiveaway
     */
    function endMonthlyAuction() external onlyOwner {
        require(startedMonthly == true, "You need to start the Auction!");
        require(block.timestamp >= endAtMonthly, "Auction is still ongoing!"); // don't want to allow the Auction if the endAt time is not yet reached
        require(endedMonthly == false, "Auction already ended!");

        // ending the auction
        startedMonthly = false;
        endedMonthly = true;
    }

    /**
     * @dev generates random int *WARNING* -> Not safe for public use, vulnerbility detected ==> needs to change into Chainlink VRF
     * NOTE: the daily minter cannot win the daily price: last require in function below
     */
    function randomMonthlyWinner() public onlyOwner {
        require(startedMonthly == false, "Started is true!");
        require(endedMonthly == true, "Ended is flase!");

        // VERIFIED RANDOMNESS WITH CHAINLINK_VRF
        monthlyWinnerBidder = monthlyPlayers[
            s_randomWords[0] % monthlyPlayers.length
        ];
        monthlyWinnerAuctionWinner = monthlyDailyWinnerAuction[
            s_randomWords[1] % monthlyDailyWinnerAuction.length
        ];

        /*uint256 randomNumber1 = uint256(
            keccak256(
                abi.encodePacked(
                    block.difficulty,
                    block.timestamp,
                    monthlyPlayers.length
                )
            )
        );
        uint256 randomNumber2 = uint256(
            keccak256(
                abi.encodePacked(
                    block.difficulty,
                    block.timestamp,
                    monthlyDailyWinnerAuction.length
                )
            )
        );
        monthlyWinnerBidder = monthlyPlayers[
            randomNumber1 % monthlyPlayers.length
        ];
        monthlyWinnerAuctionWinner = monthlyDailyWinnerAuction[
            randomNumber2 % monthlyDailyWinnerAuction.length
        ];*/
    }

    /**
     * @dev picks a winner from the giveaway, and grants winner the balance of contract
     */
    function sendRewardsMonthlyWinner() public payable onlyOwner {
        //makes sure that we have enough players in the giveaway
        require(startedMonthly == false, "Started is true!");
        require(endedMonthly == true, "Ended is flase!");

        // sending the funds to the monthly Winner
        (bool succes_dailyWinner, ) = payable(monthlyWinnerBidder).call{
            value: (getBalance() * percentageMonthlyBidders) / 100
        }("");
        require(
            succes_dailyWinner,
            "Could not transfer Giveaway to daily winner."
        );
        (bool succes_dailyWinnerAuctionWinner, ) = payable(
            monthlyWinnerAuctionWinner
        ).call{value: (getBalance() * percentageMonthlyWinner) / 100}("");
        require(
            succes_dailyWinnerAuctionWinner,
            "Could not transfer Giveaway to daily winner."
        );

        // resets the players array once someone is picked
        resetMonthlyGiveaways();

        // send all funds of MGA contract to the YGA contract
        (bool succes_fundstoYGA, ) = payable(addressNFT).call{
            value: getBalance()
        }("");
        require(succes_fundstoYGA, "Could not transfer balance to MGA.");
    }

    /**
     * @dev resets the giveaways
     */
    function resetMonthlyGiveaways() internal onlyOwner {
        monthlyPlayers = new address payable[](0);
        monthlyDailyWinnerAuction = new address payable[](0);
    }

    function getBalance() public view virtual returns (uint256) {
        // returns the contract balance
        return address(this).balance;
    }

    //@notice makes sure the owner is the ONLY one that can use the function
    modifier onlyOwner() {
        require(admin == msg.sender, "You are not the owner");
        _;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
/*
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract YearlyGiveawayAuction is ERC721Enumerable, Ownable, VRFConsumerBaseV2 {
    bool public startedYearly;
    bool public endedYearly;
    uint256 public endAtYearly;

    address public admin;
    address public yearlyWinner;

    // ************************************************************************************************************** //
    //FOR RANDOMNESS IN CHAINLINK VRF

    // for randomness
    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;

    // Your subscription ID.
    uint64 s_subscriptionId;

    // Rinkeby coordinator. For other networks,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;

    // Rinkeby LINK token contract. For other networks,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    address link = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 keyHash =
        0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 100000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // Retrieve 1 random value in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords = 1;

    uint256[] public s_randomWords;
    uint256 public s_requestId;

    constructor(
        uint64 subscriptionId,
        string memory _nameNFT,
        string memory _symbolNFT
    ) ERC721(_nameNFT, _symbolNFT) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(link);
        s_subscriptionId = subscriptionId;
        admin = msg.sender;
        startedYearly = false;
        endedYearly = true;
    }

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords() external onlyOwner {
        // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    function fulfillRandomWords(
        uint256, 
        uint256[] memory randomWords
    ) internal override {
        s_randomWords = randomWords;
    }

    receive() external payable {}

    function startYearlyAuction() external onlyOwner {
        require(startedYearly == false, "Auction already started!");
        require(endedYearly == true, "Auction is ended!");

        startedYearly = true;
        endedYearly = false;

        // determining when the auction is ending automatically
        // endAtYearly = block.timestamp + 365 days;
    }

    function endYearlyAuction() external onlyOwner {
        require(startedYearly == true, "Auction already not started!");
        require(endedYearly == false, "Auction is not ended!");

        startedYearly = false;
        endedYearly = true;
    }

    function randomYearlyWinner() public onlyOwner ended {
        //yearlyWinner = payable(ownerOf(randomNumber(366, block.difficulty, getBalance())));
        uint256 nftId = 0;
        yearlyWinner = payable(ownerOf(nftId));
        (bool sent_yearlyWinner, ) = payable(yearlyWinner).call{
            value: getBalance()
        }("");
        require(sent_yearlyWinner, "Yearly fund sent to Winner.");
    }

    function randomNumber(
        uint256 _mod,
        uint256 _seed,
        uint256 _salt
    ) public view returns (uint256) {
        uint256 num = uint256(
            keccak256(
                abi.encodePacked(block.timestamp, msg.sender, _seed, _salt)
            )
        ) % _mod;
        return num;
    }

    function resetYearlyGiveaway() internal onlyOwner {
        // monthlyPlayers = new address payable[](0);
    }

    function getBalance() public view virtual returns (uint256) {
        // returns the contract balance
        return address(this).balance;
    }

    //@notice makes sure the auction has already started
    modifier ended() {
        require(startedYearly == false, "Auction on, stared == true");
        require(endedYearly == true, "Auction on, endedYearly == false");
        _;
    }
}*/

// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

interface IVRFv2Consumer {
    function requestRandomWords() external;

    function fulfillRandomWords(uint256, uint256[] memory randomWords) external;

    function getS_randomWords() external returns (uint256[] memory);

    function getS_subscriptionId() external view returns (uint64);

    function getVrfCoordinator() external view returns (address);

    function getLink() external view returns (address);

    function getKeyHash() external view returns (bytes32);

    function getCallbackGasLimit() external view returns (uint32);

    function getRequestConfirmations() external view returns (uint16);
}

contract VRFv2Consumer is VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;

    // Your subscription ID.
    uint64 s_subscriptionId;

    // Rinkeby coordinator. For other networks,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;

    // Rinkeby LINK token contract. For other networks,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    address link = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 keyHash =
        0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 100000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords = 3;

    uint256[] public s_randomWords;
    uint256 public s_requestId;
    address s_owner;

    constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(link);
        s_owner = msg.sender;
        s_subscriptionId = subscriptionId;
    }

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords() external {
        // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        s_randomWords = randomWords;
    }

    function getS_randomWords() public view returns (uint256[] memory) {
        return s_randomWords;
    }

    function getS_subscriptionId() public view returns (uint64) {
        return s_subscriptionId;
    }

    function getVrfCoordinator() public view returns (address) {
        return vrfCoordinator;
    }

    function getLink() public view returns (address) {
        return link;
    }

    function getKeyHash() public view returns (bytes32) {
        return keyHash;
    }

    function getCallbackGasLimit() public view returns (uint32) {
        return callbackGasLimit;
    }

    function getRequestConfirmations() public view returns (uint16) {
        return requestConfirmations;
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
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

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
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

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
pragma solidity ^0.8.0;

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