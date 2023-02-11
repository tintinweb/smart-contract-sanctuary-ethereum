// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
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

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
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
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) external returns (bool);
}

interface ITokenMarketplace {
    function buy(
        address tokenAddress,
        uint256 amount
    ) external payable returns (bool);

    function sell(address tokenAddress, uint256 amount) external returns (bool);

    function getPrice(address tokenAddress) external view returns (uint);
}

interface IETFToken {
    function balanceOf(address account) external view returns (uint256);
}

error ETFContract__HoldingNotEnoughETFToken();
error ETFContract__ProposalHasEnded();
error ETFContract__ProposalIsStillOngoing();
error ETFContract__NotEnoughEthInContract();
error ETFContract__NotEnoughTokenToBuy();
error ETFContract__NotEnoughTokenToSell();
error ETFContract__MarketplaceDoesntHaveEnoughETH();
error ETFContract__YouAlreadyVoted();

contract ETFContract is VRFConsumerBaseV2, AutomationCompatibleInterface {
    ///////////////////////
    // Type declarations //
    ///////////////////////

    enum Vote {
        YAY,
        NAY
    }

    /////////////////////
    // State Variables //
    /////////////////////

    // ETF Variables

    IETFToken etfToken;
    ITokenMarketplace tokenMarketplace;

    address public etfTokenAddress;
    uint public proposalCount;
    uint public interval = 1 days;
    address public s_recentWinner;
    uint public currentDeadline;
    address public tokenMarketplaceAddresse;

    struct Proposal {
        address tokenAddress;
        uint amount;
        bool buying;
        uint deadline;
        uint yayVotes;
        uint nayVotes;
        bool executed;
    }

    mapping(uint => mapping(address => bool)) public voted;
    mapping(uint => Proposal) public proposals;
    address payable[] private voters;

    // Chainlink VRF Variables
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit = 100000;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    event WinnerPicked(address indexed winner);
    event RequestedWinner(uint requestId);
    event ProposalSend(address indexed tokenAddress, uint amount, bool buying);
    event voteSend(uint proposalIndex, Vote vote);

    //////////////
    // Modifier //
    //////////////

    modifier onlyTokenHolder() {
        if (etfToken.balanceOf(msg.sender) < 0.01 ether) {
            revert ETFContract__HoldingNotEnoughETFToken();
        }
        _;
    }

    modifier proposalOngoing() {
        if (proposals[proposalCount].deadline <= block.timestamp) {
            revert ETFContract__ProposalHasEnded();
        }

        _;
    }

    modifier proposalEnded() {
        if (proposals[proposalCount].deadline > block.timestamp) {
            revert ETFContract__ProposalIsStillOngoing();
        }
        _;
    }

    ///////////////
    // Functions //
    ///////////////

    constructor(
        address vrfCoordinatorV2,
        address _etfToken,
        address _tokenMarketplace,
        uint64 subscriptionId,
        bytes32 gasLane
    ) payable VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        etfToken = IETFToken(_etfToken);
        tokenMarketplace = ITokenMarketplace(_tokenMarketplace);
        i_subscriptionId = subscriptionId;
        i_gasLane = gasLane;
        currentDeadline = block.timestamp + interval;
        tokenMarketplaceAddresse = _tokenMarketplace;
        etfTokenAddress = _etfToken;
    }

    /*
     * @notice Method for adding a proposal
     * @param tokenAddress Address of token contract
     * @param amount Amount of the token
     * @param buying Boolean if the contract should buy(true) or sell(false)
     */
    function addProposal(
        address tokenAddress,
        uint amount,
        bool buying
    ) external onlyTokenHolder {
        if (proposals[proposalCount].tokenAddress != address(0)) {
            revert ETFContract__ProposalIsStillOngoing();
        }
        IERC20 token = IERC20(tokenAddress);
        uint price = tokenMarketplace.getPrice(tokenAddress);
        uint cost = price * amount;
        if (buying == true) {
            uint tokenAmount = token.balanceOf(tokenMarketplaceAddresse);
            if (address(this).balance < cost) {
                revert ETFContract__NotEnoughEthInContract();
            }
            if (tokenAmount < amount) {
                revert ETFContract__NotEnoughTokenToBuy();
            }
        }
        if (buying == false) {
            uint balance = token.balanceOf(address(this));
            if (balance < amount) {
                revert ETFContract__NotEnoughTokenToSell();
            }
            uint marketplaceBalance = tokenMarketplaceAddresse.balance;
            if (marketplaceBalance < cost) {
                revert ETFContract__MarketplaceDoesntHaveEnoughETH();
            }
        }
        Proposal memory newProposal;
        newProposal.tokenAddress = tokenAddress;
        newProposal.amount = amount;
        newProposal.buying = buying;
        newProposal.deadline = currentDeadline;
        proposals[proposalCount] = newProposal;
        emit ProposalSend(tokenAddress, amount, buying);
    }

    /*
     * @notice Method for vote on the proposal
     * @param vote Vote for or against proposal
     */
    function voteOnProposal(
        Vote vote
    ) external onlyTokenHolder proposalOngoing {
        if (voted[proposalCount][msg.sender] == true) {
            revert ETFContract__YouAlreadyVoted();
        }
        if (vote == Vote.YAY) {
            proposals[proposalCount].yayVotes++;
            voted[proposalCount][msg.sender] = true;
        }
        if (vote == Vote.NAY) {
            proposals[proposalCount].nayVotes++;
            voted[proposalCount][msg.sender] = true;
        }

        voters.push(payable(msg.sender));
        emit voteSend(proposalCount, vote);
    }

    /*
     * @notice Method checking the requirements of the upkeep
     */
    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /*performData*/) {
        bool execute = proposals[proposalCount].executed == false;
        bool deadline = proposals[proposalCount].deadline <= block.timestamp;
        upkeepNeeded = (execute && deadline);
        return (upkeepNeeded, "0x0");
    }

    /*
     * @notice Method for executing the proposal
     */
    function performUpkeep(bytes calldata /*performData*/) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        require(upkeepNeeded, "Requirements are not fulfilled!");
        proposals[proposalCount].executed = true;
        Proposal memory proposal = proposals[proposalCount];
        proposalCount++;
        currentDeadline = block.timestamp + interval;
        if (proposal.yayVotes > proposal.nayVotes) {
            if (proposal.buying == true) {
                IERC20 token = IERC20(proposal.tokenAddress);
                uint marketplaceBalance = token.balanceOf(
                    tokenMarketplaceAddresse
                );
                if (marketplaceBalance >= proposal.amount) {
                    uint price = tokenMarketplace.getPrice(
                        proposal.tokenAddress
                    );
                    uint cost = proposal.amount * price;
                    if (address(this).balance >= cost) {
                        bool success = tokenMarketplace.buy{value: cost}(
                            proposal.tokenAddress,
                            proposal.amount
                        );

                        require(success, "The buy did not work");
                    }
                }
            } else {
                uint price = tokenMarketplace.getPrice(proposal.tokenAddress);
                uint cost = proposal.amount * price;
                uint marketplaceBalance = tokenMarketplaceAddresse.balance;
                if (marketplaceBalance >= cost) {
                    IERC20 token = IERC20(proposal.tokenAddress);
                    uint tokenAmount = proposal.amount;
                    token.increaseAllowance(
                        tokenMarketplaceAddresse,
                        tokenAmount
                    );
                    bool success = tokenMarketplace.sell(
                        proposal.tokenAddress,
                        proposal.amount
                    );
                    require(success, "The sell did not work!");
                }
            }

            proposal.executed = true;
        }
        uint requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        uint priceETF = tokenMarketplace.getPrice(etfTokenAddress);

        uint ethAmount = (address(this).balance * 1) / 100;
        uint etfAmount = ethAmount / priceETF;
        bool s = tokenMarketplace.buy{value: ethAmount}(
            etfTokenAddress,
            etfAmount
        );
        require(s, "You couldn't buy ETFToken back!");

        emit RequestedWinner(requestId);
    }

    /*
     * @notice Method for getting the winner and sending the prize
     * @param randomWords Random number to get the random winner
     */
    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % voters.length;
        address recentWinner = voters[indexOfWinner];
        s_recentWinner = recentWinner;
        voters = new address payable[](0);
        uint price = (address(this).balance * 1) / 100;
        (bool success, ) = recentWinner.call{value: price}("");
        require(success, "Transaction failed!");
        emit WinnerPicked(recentWinner);
    }

    //////////////////////
    // Getter Functions //
    //////////////////////

    function getCurrentProposal() public view returns (Proposal memory) {
        Proposal memory currentProposal = proposals[proposalCount];
        return currentProposal;
    }

    function getOldProposal(
        uint proposalIndex
    ) public view returns (Proposal memory) {
        Proposal memory oldProposal = proposals[proposalIndex];
        return oldProposal;
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getProposalNum() public view returns (uint) {
        return proposalCount;
    }

    function getRemainingTime() public view returns (uint) {
        if (currentDeadline <= block.timestamp) {
            return 0;
        }
        uint time = currentDeadline - block.timestamp;
        return time;
    }

    receive() external payable {}

    fallback() external payable {}
}