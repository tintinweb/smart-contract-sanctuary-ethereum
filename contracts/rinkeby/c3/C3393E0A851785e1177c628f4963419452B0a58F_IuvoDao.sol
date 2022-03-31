// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol';
import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import '@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './interfaces/IIuvoDaoToken.sol';

contract IuvoDao is Ownable, VRFConsumerBaseV2 {
  uint256 private constant PERCENT_DENOMENATOR = 1000;

  VRFCoordinatorV2Interface VRF_COORDINATOR;
  LinkTokenInterface LINK;
  uint64 private _vrfSubscriptionId;
  bytes32 private _vrfKeyHash;
  uint32 private _vrfCallbackGasLimit = 100000;
  mapping(uint256 => uint256) private _vrfInitiators;
  mapping(uint256 => address) private _vrfWinners;

  address public currentCharity;
  uint256 public percentDonatedOnChange = 100; // 10%
  uint256 public percentDonatedOnDeposit = 500; // 50% of deposit amount donated immediately
  uint256 public percentTreasuryBuyerPool = 10; // 1%
  uint256 public timeToChangeCharities = 60 * 60 * 24 * 7; // 7 days
  uint256 public lastCharityChange;
  uint256 public maxCharitiesPerPeriod = 5;

  uint256 public totalDonated;
  address[] public allSelectedCharities;
  mapping(address => uint256) public donatedPerCharity;

  address[] public charityChangers;

  mapping(address => bool) public authorized;

  IIuvoDaoToken voterToken;

  // lastCharityChange => charity[]
  mapping(uint256 => address[]) public charities;
  // lastCharityChange => charity => true
  mapping(uint256 => mapping(address => bool)) public charitiesIndexed;
  // lastCharityChange => charity => votes
  mapping(uint256 => mapping(address => uint256)) public charityVotes;
  // lastCharityChange => user => voted
  mapping(uint256 => mapping(address => uint256)) public userVotedAmount;
  // lastCharityChange => user => charity
  mapping(uint256 => mapping(address => address)) public userVotedFor;

  event AddCharity(address indexed charity, uint256 lastCharityChange);
  event RemoveCharity(address indexed charity, uint256 lastCharityChange);
  event ChangeCharity(address newCharity);
  event VoteForCharity(address indexed user, address charity);
  event UnvoteForCharity(address indexed user, address charity);
  event InitiatedEpochWinner(uint256 indexed requestId, uint256 indexed epoch);
  event SelectedEpochWinner(
    uint256 indexed requestId,
    uint256 indexed epoch,
    address winner
  );

  modifier onlyAuthorized() {
    require(msg.sender == owner() || authorized[msg.sender], 'not authorized');
    _;
  }

  constructor(
    address _charity,
    address _voterToken,
    address _vrfCoordinator,
    uint64 _subscriptionId,
    address _linkToken,
    bytes32 _keyHash
  ) VRFConsumerBaseV2(_vrfCoordinator) {
    currentCharity = _charity;
    allSelectedCharities.push(_charity);
    lastCharityChange = block.timestamp;

    voterToken = IIuvoDaoToken(_voterToken);

    VRF_COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
    LINK = LinkTokenInterface(_linkToken);
    _vrfSubscriptionId = _subscriptionId;
    _vrfKeyHash = _keyHash;
  }

  function getVoterToken() external view returns (address) {
    return address(voterToken);
  }

  function getAllCharities() external view returns (address[] memory) {
    return allSelectedCharities;
  }

  function getCharityChangers() external view returns (address[] memory) {
    return charityChangers;
  }

  function selectWinningBuyerAtPreviousEpoch() external {
    uint256 _epoch = voterToken.getEpoch() - 1;
    _selectWinningBuyerAtEpoch(_epoch);
  }

  // only let owner select at some epoch that's not the previous one
  function selectWinningBuyerAt(uint256 _epoch) external onlyOwner {
    _selectWinningBuyerAtEpoch(_epoch);
  }

  function _selectWinningBuyerAtEpoch(uint256 _epoch) internal {
    require(voterToken.getEpoch() > _epoch, 'epoch is not complete');
    require(
      voterToken.getAllEpochBuyerAmount(_epoch) > 0,
      'no buyers during period'
    );

    uint256 requestId = VRF_COORDINATOR.requestRandomWords(
      _vrfKeyHash,
      _vrfSubscriptionId,
      uint16(3),
      _vrfCallbackGasLimit,
      uint16(1)
    );
    // epoch is always 1 or greater
    require(_vrfInitiators[requestId] == 0, 'already initiated');

    _vrfInitiators[requestId] = _epoch;
    emit InitiatedEpochWinner(requestId, _epoch);
  }

  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
    internal
    override
  {
    uint256 _epoch = _vrfInitiators[requestId];
    uint256 _allBuyerLength = voterToken.getAllEpochBuyerAmount(_epoch);
    uint256 _winnerIdx = randomWords[0] % _allBuyerLength;
    _vrfWinners[_epoch] = voterToken.epochBuyers(_epoch, _winnerIdx);

    uint256 _before = address(this).balance;
    uint256 _amountETH = (_before * percentTreasuryBuyerPool) /
      PERCENT_DENOMENATOR;
    payable(_vrfWinners[_epoch]).call{ value: _amountETH }('');
    require(address(this).balance >= _before - _amountETH);
    emit SelectedEpochWinner(requestId, _epoch, _vrfWinners[_epoch]);
  }

  function addCharity(address _charity) external onlyAuthorized {
    require(
      !charitiesIndexed[lastCharityChange][_charity],
      'charity already present'
    );
    require(
      charities[lastCharityChange].length <= maxCharitiesPerPeriod,
      'exceeded max charities to select from per period'
    );

    charities[lastCharityChange].push(_charity);
    charitiesIndexed[lastCharityChange][_charity] = true;
    emit AddCharity(_charity, lastCharityChange);
  }

  function removeCharity(address _charity) external onlyAuthorized {
    require(
      charitiesIndexed[lastCharityChange][_charity],
      'charity not present currently'
    );

    for (uint256 i = 0; i < charities[lastCharityChange].length; i++) {
      if (charities[lastCharityChange][i] == _charity) {
        charities[lastCharityChange][i] = charities[lastCharityChange][
          charities[lastCharityChange].length - 1
        ];
        delete charitiesIndexed[lastCharityChange][_charity];
        charities[lastCharityChange].pop();
        charityVotes[lastCharityChange][_charity] = 0;
        break;
      }
    }
    emit RemoveCharity(_charity, lastCharityChange);
  }

  function donateAndChangeCharity() external {
    require(
      block.timestamp > lastCharityChange + timeToChangeCharities,
      'not enough time has passed to change charities'
    );
    uint256 donatedAmount = (address(this).balance * percentDonatedOnChange) /
      PERCENT_DENOMENATOR;
    _sendToCharity(donatedAmount);
    totalDonated += donatedAmount;
    donatedPerCharity[currentCharity] += donatedAmount;

    // get and set next charity with most votes this period
    currentCharity = _getNextCharity();
    require(currentCharity != address(0), 'not a valid charity');
    allSelectedCharities.push(currentCharity);

    charityChangers.push(msg.sender);
    lastCharityChange = block.timestamp;
    emit ChangeCharity(currentCharity);
  }

  function vote(address _charity) external {
    _voteForCharity(msg.sender, _charity);
  }

  function changeCurrentVote(address _newCharity) external {
    _unvote(msg.sender);
    _voteForCharity(msg.sender, _newCharity);
  }

  function removeCurrentVote() external {
    _unvote(msg.sender);
  }

  function _voteForCharity(address _user, address _charity) internal {
    require(userVotedAmount[lastCharityChange][_user] == 0, 'already voted');
    // cooldown handles preventing duplicate votes so users don't transfer
    // tokens to another wallet to try and vote more than once per period
    require(
      block.timestamp >
        voterToken.voteCooldownStart(_user) + voterToken.voteCooldownPeriod(),
      'in cooldown period from recent token transfer'
    );
    uint256 userVoteShares = voterToken.balanceOf(_user);
    require(userVoteShares > 0, 'must have voter token balance to vote');

    address _validCharity = _checkAndGetValidCharity(_charity);
    require(_validCharity != address(0), 'not a valid charity to vote for');

    charityVotes[lastCharityChange][_validCharity] += userVoteShares;
    userVotedAmount[lastCharityChange][_user] = userVoteShares;
    userVotedFor[lastCharityChange][_user] = _validCharity;
    emit VoteForCharity(_user, _charity);
  }

  function _unvote(address _user) internal {
    require(
      userVotedAmount[lastCharityChange][_user] > 0,
      'user has not voted yet'
    );

    address _charityUserVotedFor = userVotedFor[lastCharityChange][_user];
    uint256 _previousVoteShares = userVotedAmount[lastCharityChange][_user];

    uint256 _votes = charityVotes[lastCharityChange][_charityUserVotedFor];
    // votes will be 0 if an admin removed the charity from the list for any reason
    if (_votes > 0) {
      charityVotes[lastCharityChange][
        _charityUserVotedFor
      ] -= _previousVoteShares;
    }
    delete userVotedFor[lastCharityChange][_user];
    delete userVotedAmount[lastCharityChange][_user];
    emit UnvoteForCharity(_user, _charityUserVotedFor);
  }

  function _checkAndGetValidCharity(address _charity)
    internal
    view
    returns (address)
  {
    for (uint256 i = 0; i < charities[lastCharityChange].length; i++) {
      if (charities[lastCharityChange][i] == _charity) {
        return _charity;
      }
    }
    return address(0);
  }

  function _getNextCharity() internal view returns (address) {
    address charityMostVotes = address(0);
    uint256 mostVotes = 0;
    for (uint256 i = 0; i < charities[lastCharityChange].length; i++) {
      address _charity = charities[lastCharityChange][i];
      if (
        charityMostVotes == address(0) ||
        charityVotes[lastCharityChange][_charity] > mostVotes
      ) {
        charityMostVotes = _charity;
        mostVotes = charityVotes[lastCharityChange][_charity];
      }
    }
    return charityMostVotes;
  }

  function setMaxCharitiesPerPeriod(uint256 _max) external onlyOwner {
    require(_max <= 20, '20 is the max charities to select from');
    maxCharitiesPerPeriod = _max;
  }

  function setPercentDonatedOnChange(uint256 _percent) external onlyOwner {
    require(_percent <= PERCENT_DENOMENATOR, 'cannot be more than 100%');
    percentDonatedOnChange = _percent;
  }

  function setPercentDonatedOnDeposit(uint256 _percent) external onlyOwner {
    require(_percent <= PERCENT_DENOMENATOR, 'cannot be more than 100%');
    percentDonatedOnDeposit = _percent;
  }

  function setTimeBetweenCharities(uint256 _timeSeconds) external onlyOwner {
    require(_timeSeconds <= 60 * 60 * 24 * 30 * 6, 'not more than 6 months');
    timeToChangeCharities = _timeSeconds;
  }

  function setPercentTreasuryBuyerPool(uint256 _percent) external onlyOwner {
    require(
      _percent <= (PERCENT_DENOMENATOR * 10) / 100,
      'cannot be more than 10%'
    );
    percentTreasuryBuyerPool = _percent;
  }

  function setAuthorized(address _user, bool _isAuthorized)
    external
    onlyAuthorized
  {
    authorized[_user] = _isAuthorized;
  }

  // https://docs.chain.link/docs/get-a-random-number/
  function setVrfCallbackGasLimit(uint32 _gas) external onlyOwner {
    _vrfCallbackGasLimit = _gas;
  }

  function _sendToCharity(uint256 _amountETH) private {
    uint256 before = address(this).balance;
    payable(currentCharity).call{ value: _amountETH }('');
    require(address(this).balance >= before - _amountETH);
  }

  receive() external payable {
    if (percentDonatedOnDeposit > 0) {
      uint256 donateAmount = (msg.value * percentDonatedOnDeposit) /
        PERCENT_DENOMENATOR;
      _sendToCharity(donateAmount);
      totalDonated += donateAmount;
      donatedPerCharity[currentCharity] += donateAmount;
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IIuvoDaoToken is IERC20 {
  function epochBuyers(uint256 epoch, uint256 index)
    external
    view
    returns (address);

  function epochBuyersIndexed(uint256 epoch, address buyer)
    external
    view
    returns (bool);

  function getAllEpochBuyerAmount(uint256 epoch)
    external
    view
    returns (uint256);

  function getEpoch() external view returns (uint256);

  function voteCooldownPeriod() external view returns (uint256);

  function voteCooldownStart(address _user) external view returns (uint256);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}