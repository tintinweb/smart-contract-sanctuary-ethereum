// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

error NftLottery__TransferFailed();
error NftLottery__SendMoreToEnterNftLottery();
error NftLottery__NftLotteryNotOpen();
error NftLottery__NftLotteryNotClosed();
error NftLottery__NotNftOwner(
    address nftAddress,
    uint256 tokenId,
    address nftOwner,
    address sender
);
error NftLottery__InvalidLotteryParameters(string reason);
error NftLottery__NeedToClaimPrizeBeforeEnter();
error NftLottery__NothingToClaim();
error NftLottery__NotMinimumNumberOfPlayersEntered();
error NftLottery__ZeroLotteryBalance();

/**@title Nft Lottery Contract
 * @author https://github.com/lubos-harasta
 * @notice This contract is inspired by Patrick Collins' Raffle.sol, see at https://github.com/PatrickAlphaC/hardhat-smartcontract-lottery-fcc
 * the main difference is that only holders of eligible NFTs can enter the NFT Lottery
 * @dev Chainlink Keepers could be implemented
 */
contract NftLottery is VRFConsumerBaseV2, Ownable {
    /* Type declarations */
    enum NftLotteryState {
        OPEN,
        CALCULATING
    }

    struct NftLotteryParameters {
        bool parametersChangeRequired;
        uint256 entranceFee;
        uint32 numberOfWinners;
        uint256 minNumberOfPlayers;
    }

    /* Mappings */
    // nft collection address -> eligible
    mapping(address => bool) private s_nftCollectionsEligible;
    // player address => pending win
    mapping(address => uint256) private s_pendingWins;

    /* Modifiers */
    modifier isNftOwner(
        address nftAddress,
        uint256 tokenId,
        address sender
    ) {
        IERC721 nft = IERC721(nftAddress);
        address nftOwner = nft.ownerOf(tokenId);
        if (sender != nftOwner) {
            revert NftLottery__NotNftOwner(nftAddress, tokenId, nftOwner, sender);
        }
        _;
    }

    /* State variables */
    // Chainlink VRF Variables
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;

    // Lottery Variables
    using Counters for Counters.Counter;
    Counters.Counter private s_lotteryCounter;

    bool private s_lotteryParametersSettingRequired;

    uint256 private s_entranceFee;
    uint32 private s_numberOfWinners;
    uint256 private s_minNumberOfPlayers;
    uint256 private s_currentLotteryBalance;

    address[] private s_recentWinners;
    address[] private s_players;

    NftLotteryState private s_nftLotteryState;
    NftLotteryParameters private s_pendingRequiredNftLotteryChange;

    /* Events */
    event RequestedNftLotteryWinner(uint256 indexed requestId, uint256 indexed lotteryCounter);
    event NftLotteryEnter(
        uint256 indexed lotteryCounter,
        address indexed player,
        uint256 indexed entranceFee
    );
    event WinnerPicked(uint256 indexed requestId, address indexed player, uint256 indexed prize);
    event LotteryParametersChangeRequired(
        uint256 indexed entranceFee,
        uint32 indexed numberOfWinners,
        uint256 indexed minNumberOfPlayers
    );
    event LotteryParametersChanged(
        uint256 indexed entranceFee,
        uint32 indexed numberOfWinners,
        uint256 indexed minNumberOfPlayers
    );
    event NftAddressEligibilityChanged(
        address indexed nftCollectionAddress,
        bool indexed isEligible
    );
    event PrizeClaimed(address indexed winner, uint256 indexed prizeClaimed);

    /* Functions */
    constructor(
        address vrfCoordinatorV2,
        uint64 subscriptionId,
        bytes32 gasLane, // keyHash
        uint32 callbackGasLimit,
        uint256 entranceFee,
        uint32 numberOfWinners,
        uint256 minNumberOfPlayers
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_subscriptionId = subscriptionId;
        i_gasLane = gasLane;
        i_callbackGasLimit = callbackGasLimit;
        s_entranceFee = entranceFee;
        s_numberOfWinners = numberOfWinners;
        s_minNumberOfPlayers = minNumberOfPlayers;
        s_nftLotteryState = NftLotteryState.OPEN;
        s_lotteryParametersSettingRequired = false;
    }

    /**
     * @notice Method for entering the lottery
     * @param nftCollectionAddress Address of the NFT collection
     * @param tokenId Token ID of nftCollectionAddress
     * @dev check to one tokenId per entrance could be applied
     */
    function enterNftLottery(address nftCollectionAddress, uint256 tokenId)
        public
        payable
        isNftOwner(nftCollectionAddress, tokenId, msg.sender)
    {
        if (msg.value < s_entranceFee) {
            revert NftLottery__SendMoreToEnterNftLottery();
        }
        if (s_nftLotteryState != NftLotteryState.OPEN) {
            revert NftLottery__NftLotteryNotOpen();
        }
        if (s_pendingWins[msg.sender] > 0) {
            revert NftLottery__NeedToClaimPrizeBeforeEnter();
        }
        s_players.push(msg.sender);
        s_currentLotteryBalance += msg.value;

        emit NftLotteryEnter(s_lotteryCounter.current(), msg.sender, msg.value);
    }

    /**
     * @notice Method to end the lottery
     * @dev this function is called and it kicks off a Chainlink VRF call to get a random winner(s).
     */
    function endNftLotteryAndpickWinners() public {
        if (s_players.length < s_minNumberOfPlayers) {
            revert NftLottery__NotMinimumNumberOfPlayersEntered();
        }
        if (s_nftLotteryState != NftLotteryState.OPEN) {
            revert NftLottery__NftLotteryNotOpen();
        }
        s_nftLotteryState = NftLotteryState.CALCULATING;
        uint32 numOfWinners = s_numberOfWinners;

        // if there is a change of lottery parameters required, change it now
        if (s_pendingRequiredNftLotteryChange.parametersChangeRequired) {
            setLotteryParameters();
        }

        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            numOfWinners // number of words to get back from VRF
        );
        emit RequestedNftLotteryWinner(requestId, s_lotteryCounter.current());
    }

    /**
     * @notice Mthod to pick the winners
     * @param requestId Request ID from VRF Coordinator
     * @param randomWords Received random word(s) from VRF Coordinator
     * @dev This is the function that Chainlink VRF node
     * calls to update random winner(s) mapping.
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        s_recentWinners = new address[](0); // reset the array before

        uint256 totalPrizePerTicket = s_currentLotteryBalance / uint256(s_numberOfWinners);
        for (uint256 i = 0; i < s_numberOfWinners; i++) {
            uint256 indexOfWinner = randomWords[i] % s_players.length;
            address recentWinner = s_players[indexOfWinner];
            s_pendingWins[recentWinner] += totalPrizePerTicket;
            s_recentWinners.push(recentWinner);

            emit WinnerPicked(requestId, recentWinner, totalPrizePerTicket);
        }

        s_currentLotteryBalance = 0; // reset the currentLotteryBalance
        s_players = new address[](0);
        s_nftLotteryState = NftLotteryState.OPEN;
        s_lotteryCounter.increment();
    }

    /**
     * @notice Method to claim the prize
     */
    function claimPrize() public {
        uint256 claimableAmount = s_pendingWins[msg.sender];
        if (claimableAmount == 0) {
            revert NftLottery__NothingToClaim();
        }
        s_pendingWins[msg.sender] = 0;

        emit PrizeClaimed(msg.sender, claimableAmount);

        (bool success, ) = payable(msg.sender).call{value: claimableAmount}("");
        if (!success) {
            revert NftLottery__TransferFailed();
        }
    }

    /**
     * @notice Mthod to change parameters of the lottery
     */
    function requireLotteryParametersSetting(
        uint256 _entranceFee,
        uint32 _numberOfWinners,
        uint256 _minNumberOfPlayers
    ) public onlyOwner {
        if (_minNumberOfPlayers < _numberOfWinners) {
            revert NftLottery__InvalidLotteryParameters(
                "Number of players cannot be smaller than number of winners"
            );
        }
        if (_entranceFee <= 0) {
            revert NftLottery__InvalidLotteryParameters("Entrace fee must be higher than 0");
        }

        emit LotteryParametersChangeRequired(_entranceFee, _numberOfWinners, _minNumberOfPlayers);

        s_pendingRequiredNftLotteryChange.entranceFee = _entranceFee;
        s_pendingRequiredNftLotteryChange.numberOfWinners = _numberOfWinners;
        s_pendingRequiredNftLotteryChange.minNumberOfPlayers = _minNumberOfPlayers;
        s_pendingRequiredNftLotteryChange.parametersChangeRequired = true;

        // if the lottery has not started yet, change the parameters now
        if (getNumberOfPlayers() == 0) {
            setLotteryParameters();
        }
    }

    /** Setter Functions */
    /**
     * @notice Method to set eligibility of the NFT collection
     * @param _nftCollectionAddress Address to make eligible/ineligible
     * @param _isEligible Bool to set eligibility
     */
    function setEligibleNftCollection(address _nftCollectionAddress, bool _isEligible)
        public
        onlyOwner
    {
        s_nftCollectionsEligible[_nftCollectionAddress] = _isEligible;

        emit NftAddressEligibilityChanged(_nftCollectionAddress, _isEligible);
    }

    /**
     * @notice Method to set parameters of the lottery
     * @dev data is loaded from the 's_pendingRequiredNftLotteryChange'
     * @dev all checks are executed in 'requireLotteryParametersSetting'
     */
    function setLotteryParameters() internal {
        uint256 _entranceFee = s_pendingRequiredNftLotteryChange.entranceFee;
        uint32 _numberOfWinners = s_pendingRequiredNftLotteryChange.numberOfWinners;
        uint256 _minNumberOfPlayers = s_pendingRequiredNftLotteryChange.minNumberOfPlayers;

        s_pendingRequiredNftLotteryChange.parametersChangeRequired = false;

        s_entranceFee = _entranceFee;
        s_numberOfWinners = _numberOfWinners;
        s_minNumberOfPlayers = _minNumberOfPlayers;

        emit LotteryParametersChanged(_entranceFee, _numberOfWinners, _minNumberOfPlayers);
    }

    /** Getter Functions */

    function getLotteryCounter() public view returns (uint256 lotteryCounter) {
        return s_lotteryCounter.current();
    }

    function getEligibleNftCollection(address _nftContractAddress)
        public
        view
        returns (bool isEligible)
    {
        return s_nftCollectionsEligible[_nftContractAddress];
    }

    function getNftLotteryState() public view returns (NftLotteryState) {
        return s_nftLotteryState;
    }

    function getWinner(uint256 index) public view returns (address) {
        return s_recentWinners[index];
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getEntranceFee() public view returns (uint256) {
        return s_entranceFee;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }

    function getMinNumberOfPlayers() public view returns (uint256) {
        return s_minNumberOfPlayers;
    }

    function getNumberWinningTickets() public view returns (uint32) {
        return s_numberOfWinners;
    }

    function getCurrentWinningPrize() public view returns (uint256) {
        uint256 currentLotteryBalance = s_currentLotteryBalance;
        if (currentLotteryBalance == 0) {
            return 0;
        }
        return currentLotteryBalance / s_numberOfWinners;
    }

    function getPendingPrize(address _winner) public view returns (uint256) {
        return s_pendingWins[_winner];
    }

    function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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