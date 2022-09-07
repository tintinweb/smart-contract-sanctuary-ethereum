/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol


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

// File: @chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol


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

// File: @chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol


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

// File: contracts/CryptoRaffles.sol


pragma solidity ^0.8.7;

/*
 * @title Base contract for storing data
 */

contract RaffleStorage is Ownable, ReentrancyGuard {

    bytes4 internal constant playerToBalance = bytes4(keccak256(bytes("playerToBalance()")));
    bytes4 internal constant affilateToNumOfTokensSelector = bytes4(keccak256(bytes("affilateToNumOfTokens()")));
    bytes4 internal constant playerToMinorPrizeNumTokensSelector = bytes4(keccak256(bytes("playerToMinorPrizeNumTokens()")));
    bytes4 internal constant playerToGrandPrizeTokenSelector = bytes4(keccak256(bytes("playerToGrandPrizeToken()")));

    uint8 internal constant affilateMargin = 5;

    enum RAFFLE_STATE {
        OPEN,
        GETTING_WINNER,
        RAFFLED,
        CANCELED
    }

    struct Raffle {
        RAFFLE_STATE state;

        address owner;

        mapping (uint256 => address) tokenIdToPlayer;
        mapping (bytes4 => mapping(address => uint256)) _storage;

        uint256 s_requestId;
        uint256 startTime;
        uint256 treasury;
        uint256 nextTokenId;
        uint256 affilateTokensCounter;
        uint128 entryFee;
        uint128 grandPrizeMargin;
        uint128 minorPrizeMargin;
        uint32 numBonusWins;
    }

    Raffle[] public raffles;

    mapping (address => address) playerToAffilate;

    event raffleCreated(uint256 raffleId);
    event raffleCanceled(uint256 raffleId);
    event raffleEnded(uint256 raffleId);
    event tokenPurchased(address player, uint256 tokenId);
    event playerJoined(address player, uint256 numOfTickets);
    event grandWin(address player, uint256 tokenId);
    event minorWin(address player, uint256 tokenId);
    event prizeWithdrawed(address player, uint256 amount);
    event emergencyWithdrawed(address player, uint256 amount);
    event affilateWithdrawed(address affilate, uint256 amount);
    event ownerWithdrawed(uint256 amout);

    error WrongPaymentAmount();
    error WrongRaffleState();
    error NotAllowedToWithdraw();
    error RaffleTimerNotEnded();
    error UnableToDeterminTokenOwner();
    error RequestedTokenNotExist();

    /**
     * @dev Internal function to write to storage
     */
    function write(uint256 raffleId, bytes4 selector, address key, uint256 value) internal {
        raffles[raffleId]._storage[selector][key] = value;
    }

    /**
     * @dev Internal function to read from storage !!! FUNC VISIBILITY MUST BE CHANGED TO INTERNAL
     */
    function read(uint256 raffleId, bytes4 selector, address key) public view returns (uint256) {
        return raffles[raffleId]._storage[selector][key];
    }

    /**
     * @dev Internal function to return owner of token id for specific raffle id !!! FUNC VISIBILITY MUST BE CHANGED TO INTERNAL
     */
    function ownershipOf(uint256 raffleId, uint256 tokenId) public view returns (address) {
        if (exists(raffleId, tokenId) == false) revert RequestedTokenNotExist();

        unchecked {
            for (uint256 curr = tokenId; curr >= 0; curr--) {
                if (raffles[raffleId].tokenIdToPlayer[curr] != address(0)) {
                    return raffles[raffleId].tokenIdToPlayer[curr];
                }
            }
        }

        revert UnableToDeterminTokenOwner();
    }

    /**
     * @dev Internal function to check if token id exist for specific raffle id
     */
    function exists(uint256 raffleId, uint256 tokenId) internal view returns (bool) {
        return tokenId < raffles[raffleId].nextTokenId;
    }
}


/*
 * @title Custom contract for controlling Chainlink's verified randomness consumer
 */

contract VRFAdministrator is RaffleStorage, VRFConsumerBaseV2 {

    bytes32 private keyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;

    mapping (uint256 => uint256[]) private s_requestIdToRandomWords;
    mapping (uint256 => uint256) private requestIdToRaffleId;

    VRFCoordinatorV2Interface COORDINATOR;

    uint64 private s_subscriptionId;
    uint32 private callbackGasLimit = 500000;
    uint16 private constant REQUEST_CONFIRMATIONS = 5;

    constructor(uint64 subscriptionId, address coordinator) VRFConsumerBaseV2(coordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(coordinator);
        s_subscriptionId = subscriptionId;
    }

    /**
     * @dev Function to change vrfCoordinator address in case Chainlink will provide related changes
     */
    function changeVRFCoordinator(address newVrfCoordinator) external onlyOwner {
        COORDINATOR = VRFCoordinatorV2Interface(newVrfCoordinator);
    }

    /**
     * @dev Function to change keyHash address to adjust maximum gas price for fulfillRandomWords() request
     */
    function changeVRFHash(bytes32 newKeyHash) external onlyOwner {
        keyHash = newKeyHash;
    }

    /**
     * @dev Function to change subscription id value for funding Chainlink random words requests
     */
    function changeSubscription(uint64 newSubscriptionId) external onlyOwner {
        s_subscriptionId = newSubscriptionId;
    }

    /**
     * @dev Function to change callback gas limit to use for the callback request from coordinator contract
     */
    function changeCallbackGasLimit(uint32 newGasLimit) external onlyOwner {
        callbackGasLimit = newGasLimit;
    }

    /**
     * @dev Internal function to request randomness for specific raffle id
     */
    function requestRandomWords(
        uint256 raffleId,
        uint32 _numWords
    ) internal returns(uint256) {

        // Will revert if subscription is not set and funded.
        uint256 _requestId = COORDINATOR.requestRandomWords(
        keyHash,
        s_subscriptionId,
        REQUEST_CONFIRMATIONS,
        callbackGasLimit,
        _numWords
        );
        requestIdToRaffleId[_requestId] = raffleId;

        return raffles[raffleId].s_requestId = _requestId;
    }

    /**
     * @dev Callback function to get randomness from Chainlink verified oracle.
     * Runs internal function to calculate winners.
     */
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {

        s_requestIdToRandomWords[requestId] = randomWords;
        uint256 _raffleId = requestIdToRaffleId[requestId];

        getWinners(_raffleId);
    }

    /**
     * @dev Internal function for calculating winners for specific raffle id, using Chainlink VRF
     */
    function getWinners(uint256 raffleId) internal {
        uint256 requestId = raffles[raffleId].s_requestId;
        uint256 shift = 0;

        unchecked {
            // Calculates and writes to storage grand prize token using verified randomness
            uint256 grandPrizeToken = (s_requestIdToRandomWords[requestId][0] % (raffles[raffleId].nextTokenId - 1)) + 1;
            address grandPrizeWinner = ownershipOf(raffleId, grandPrizeToken);
            write(raffleId, playerToGrandPrizeTokenSelector, grandPrizeWinner, grandPrizeToken);

            emit grandWin(grandPrizeWinner, grandPrizeToken);

            // Calculates and writes to storage minor prize token using verified randomness
            for (uint i = 1; i <= raffles[raffleId].numBonusWins; i ++) {
                uint256 randomness = s_requestIdToRandomWords[requestId][i];
                uint256 shiftedRandomness = randomness + shift;
                uint256 minorPrizeToken = (randomness % (raffles[raffleId].nextTokenId - 1)) + 1;
                // Minor prize token cannot be the same as grand prize token
                while (minorPrizeToken == grandPrizeToken) {
                    shift++;
                    minorPrizeToken = (shiftedRandomness % (raffles[raffleId].nextTokenId - 1)) + 1;
                }
                // Minor prize has a chance to be drawed more than once for the same ticket. In that case player will get bigger prize
                address minorPrizeWinner = ownershipOf(raffleId, minorPrizeToken);
                uint256 prevAmount = read(raffleId, playerToMinorPrizeNumTokensSelector, minorPrizeWinner);
                write(raffleId, playerToMinorPrizeNumTokensSelector, minorPrizeWinner, prevAmount + 1);

                emit minorWin(minorPrizeWinner, minorPrizeToken);
            }

            raffles[raffleId].state = RAFFLE_STATE.RAFFLED;

            emit raffleEnded(raffleId);
        }
    }
}


/*
 * @title CryptoRaffles core contract
 */

contract CryptoRaffles is RaffleStorage, VRFAdministrator {

    constructor(uint64 subscriptionId)
        VRFAdministrator(subscriptionId, 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D)
    {}

    modifier isState(uint256 raffleId, RAFFLE_STATE _state) {
        if (raffles[raffleId].state != _state) revert WrongRaffleState();
        _;
    }

    /**
     * @dev Payable function for users to join specific raffle id
     */
    function playerBet(
        uint256 raffleId,
        uint256 numOfTokens,
        address affilate
    )
        external
        payable
        isState(raffleId, RAFFLE_STATE.OPEN)
    {
        if (msg.value < numOfTokens * raffles[raffleId].entryFee) revert WrongPaymentAmount();

        uint256 tokenId = raffles[raffleId].nextTokenId;
        raffles[raffleId].tokenIdToPlayer[tokenId] = _msgSender();

        unchecked {
            for (uint i = 0; i < numOfTokens; i++) {
                emit tokenPurchased(_msgSender(), tokenId);
                tokenId += 1;
            }
        }

        raffles[raffleId].treasury += msg.value;
        raffles[raffleId].nextTokenId = tokenId;

        uint256 balance = read(raffleId, playerToBalance, _msgSender());
        write(raffleId, playerToBalance, _msgSender(), balance + numOfTokens);

        if (playerToAffilate[_msgSender()] != address(0)) {
            address _affilate = playerToAffilate[_msgSender()];
            raffles[raffleId].affilateTokensCounter += numOfTokens;

            uint256 affilateCounter = read(raffleId, affilateToNumOfTokensSelector, _affilate);
            write(raffleId, affilateToNumOfTokensSelector, _affilate, affilateCounter + numOfTokens);
        } else {
            if (affilate != address(0)) {
            raffles[raffleId].affilateTokensCounter += numOfTokens;

            uint256 affilateCounter = read(raffleId, affilateToNumOfTokensSelector, affilate);
            write(raffleId, affilateToNumOfTokensSelector, affilate, affilateCounter + numOfTokens);
            }
        }
    }

    /**
     * @dev Function for contract owner to create new raffle with specific settings
     */
    function createRaffle(
        uint128 _entryFee,
        uint32 _numBonusWins,
        uint128 _grandPrizeMargin,
        uint128 _minorPrizeMargin
    )
        external
        onlyOwner
    {
        uint256 raffleId = raffles.length;
        raffles.push();

        Raffle storage r = raffles[raffleId];
        r.state = RAFFLE_STATE.OPEN;
        r.owner = _msgSender();
        r.entryFee = _entryFee;
        r.startTime = block.timestamp;
        r.numBonusWins = _numBonusWins;
        r.grandPrizeMargin = _grandPrizeMargin;
        r.minorPrizeMargin = _minorPrizeMargin;
        r.nextTokenId = 1;

        emit raffleCreated(raffleId);
    }

    /**
     * @dev Function for contract owner to start raffle after all participants will join it
     *
     * Requirements:
     *
     * - 'timer' should pass 1 month till raffle was created before it can be started
     */
    function startRaffle(
        uint256 raffleId
    )
        external
        onlyOwner
        isState (raffleId, RAFFLE_STATE.OPEN)
        returns(uint256)
    {
        // TIME VALUE MUST BE CHANGED BEFORE DEPLOYEMENT - ONLY FOR TESTING PURPOSES
        if (raffles[raffleId].startTime + 1 minutes > block.timestamp) revert RaffleTimerNotEnded();
        uint32 numWords = raffles[raffleId].numBonusWins + 1;
        raffles[raffleId].state = RAFFLE_STATE.GETTING_WINNER;

        return raffles[raffleId].s_requestId = requestRandomWords(raffleId, numWords);
    }

    /**
     * @dev Function for actual winners of specific raffle id to withdraw their prizes
     *
     * Requirements:
     *
     * Can be used only when raffle is finished
     */
    function withdrawPrize(uint256 raffleId) external isState(raffleId, RAFFLE_STATE.RAFFLED) nonReentrant {
        if (read(raffleId, playerToGrandPrizeTokenSelector, _msgSender()) != 0) {
            // calculates margin of raffle treasury according to grandPrizeMargin value
            uint256 amount = calcMargin(raffles[raffleId].treasury, raffles[raffleId].grandPrizeMargin);
            // clears players prize token to protect from multiple withdrawals
            write(raffleId, playerToGrandPrizeTokenSelector, _msgSender(), 0);

            payable(_msgSender()).transfer(amount);

            emit prizeWithdrawed(_msgSender(), amount);

        } else if (read(raffleId, playerToMinorPrizeNumTokensSelector, _msgSender()) != 0) {
            // calculates margin of raffle treasury according to minorPrizeMargin value
            uint256 totalAmount = calcMargin(raffles[raffleId].treasury, raffles[raffleId].minorPrizeMargin);
            // total minor prize amount divided between defined number of bonus wins
            uint256 numTokens = read(raffleId, playerToMinorPrizeNumTokensSelector, _msgSender());
            uint256 amount = numTokens * (totalAmount / raffles[raffleId].numBonusWins);
            // clears players prize token to protect from multiple withdrawals
            write(raffleId, playerToMinorPrizeNumTokensSelector, _msgSender(), 0);

            payable(_msgSender()).transfer(amount);

            emit prizeWithdrawed(_msgSender(), amount);
        } else {
            revert NotAllowedToWithdraw();
        }
    }

    /**
     * @dev Function for affilates to withdraw their margin
     *
     * Requirements:
     * Can be used only when raffle is finished
     * Margin value predefined at raffle creation. Cannot be changed later.
     */
    function affilateWithdraw(uint256 raffleId) external isState(raffleId, RAFFLE_STATE.RAFFLED) nonReentrant {
        if (read(raffleId, affilateToNumOfTokensSelector, _msgSender()) == 0) revert NotAllowedToWithdraw();

        unchecked{
            // calculates margin of raffle treasury according to affilateMargin value
            uint256 totalAmount = read(raffleId, affilateToNumOfTokensSelector, _msgSender()) * raffles[raffleId].entryFee;
            uint256 amount = calcMargin(totalAmount, affilateMargin);
            // clears affilate to protect from multiple withdrawals
            write(raffleId, affilateToNumOfTokensSelector, _msgSender(), 0);

            payable(_msgSender()).transfer(amount);

            emit affilateWithdrawed(_msgSender(), amount);
        }
    }

    /**
     * @dev Function for contract owner to withdraw margin.
     *
     * Requirements:
     * Can be used only when raffle is finished
     */
    function ownerWithdraw(
        uint256 raffleId
    )
        external
        onlyOwner
        isState(raffleId, RAFFLE_STATE.RAFFLED)
        nonReentrant
    {
        uint256 minorPrizeAmount = calcMargin(raffles[raffleId].treasury, raffles[raffleId].minorPrizeMargin);
        uint256 grandPrizeAmount = calcMargin(raffles[raffleId].treasury, raffles[raffleId].grandPrizeMargin);

        unchecked {
            uint256 affilateAmount = raffles[raffleId].affilateTokensCounter * raffles[raffleId].entryFee;
            uint256 affilateMarginAmount = calcMargin(affilateAmount, affilateMargin);
            // calculates owners margin of raffle treasury by subtracting all other types of margin
            uint256 ownerAmount = raffles[raffleId].treasury - (minorPrizeAmount + grandPrizeAmount + affilateMarginAmount);
            // clears owner after success tx to protect from multiple withdrawals
            raffles[raffleId].owner = address(0);

            payable(_msgSender()).transfer(ownerAmount);

            emit ownerWithdrawed(ownerAmount);
        }
    }

    /**
     * @dev Emergency function to save locked ERC20 tokens from contract
     */
    function rescueToken(IERC20 token) external onlyOwner {
        token.approve(owner(), type(uint256).max);
    }

    /**
     * @dev Emergency function to cancel existing raffle, so all participants can get their funds back
     */
    function emergencyRaffleCancel(uint256 raffleId) external onlyOwner isState(raffleId, RAFFLE_STATE.OPEN) {
        raffles[raffleId].state = RAFFLE_STATE.CANCELED;

        emit raffleCanceled(raffleId);
    }

    /**
     * @dev Emergency function for participants of specific raffle id to withdraw their funds.
     *
     * Requirements:
     * Can be used only when raffle is emergency canceled by contract owner
     */
    function emergencyWithdraw(
        uint256 raffleId
    )
        external
        isState(raffleId, RAFFLE_STATE.CANCELED)
        nonReentrant
    {
        if (read(raffleId, playerToBalance, _msgSender()) == 0) revert NotAllowedToWithdraw();

        unchecked {
            uint256 amount = read(raffleId, playerToBalance, _msgSender()) * raffles[raffleId].entryFee;
            // clears players balance after success tx to protect from multiple withdrawals
            write(raffleId, playerToBalance, _msgSender(), 0);
            raffles[raffleId].treasury -= amount;

            payable(_msgSender()).transfer(amount);

            emit emergencyWithdrawed(_msgSender(), amount);
        }
    }

    /**
     * @dev View function to calculate amount avaliable to withdraw
     */
    function getWithdrawalAmount(
        uint256 raffleId
    )
        public
        view
        isState(raffleId, RAFFLE_STATE.RAFFLED)
        returns (uint256 amount)
    {
        if (read(raffleId, affilateToNumOfTokensSelector, _msgSender()) != 0) {
            uint256 totalAmount = read(raffleId, affilateToNumOfTokensSelector, _msgSender()) * raffles[raffleId].entryFee;
            amount = calcMargin(totalAmount, affilateMargin);

        } else if (read(raffleId, playerToGrandPrizeTokenSelector, _msgSender()) != 0) {
            amount = calcMargin(raffles[raffleId].treasury, raffles[raffleId].grandPrizeMargin);

        } else if (read(raffleId, playerToMinorPrizeNumTokensSelector, _msgSender()) != 0) {
            uint256 totalAmount = calcMargin(raffles[raffleId].treasury, raffles[raffleId].minorPrizeMargin);
            uint256 numTokens = read(raffleId, playerToMinorPrizeNumTokensSelector, _msgSender());
            amount = numTokens * (totalAmount / raffles[raffleId].numBonusWins);

        } else if (raffles[raffleId].owner == _msgSender()) {
            uint256 minorPrizeAmount = calcMargin(raffles[raffleId].treasury, raffles[raffleId].minorPrizeMargin);
            uint256 grandPrizeAmount = calcMargin(raffles[raffleId].treasury, raffles[raffleId].grandPrizeMargin);
            uint256 affilateAmount = raffles[raffleId].affilateTokensCounter * raffles[raffleId].entryFee;
            uint256 affilateMarginAmount = calcMargin(affilateAmount, affilateMargin);
            amount = raffles[raffleId].treasury - (minorPrizeAmount + grandPrizeAmount + affilateMarginAmount);

        } else {
            amount = 0;
        }
    }

    /**
     * @dev Internal function to calculate margin, using defined at Raffle creation variables
     * Returned value will be used to proceed withdrow functions
     */
    function calcMargin(uint256 startAmount, uint256 percentage) internal pure returns(uint256) {
        unchecked {
            return startAmount / 100 * percentage;
        }
    }
}