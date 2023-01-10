// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IMergeGators {
    event Received(address, uint);

    struct RequestStatusMerge {
        uint256[] randomWords;
        uint prize;
        address reciever;
    }

    enum Trait1 {
        X1,
        Y1,
        Z1
    }

    enum Trait2 {
        X2,
        Y2,
        Z2
    }

    enum Trait3 {
        X3,
        Y3,
        Z3
    }

    enum Trait4 {
        X4,
        Y4,
        Z4
    }

    enum Trait5 {
        X5,
        Y5,
        Z5
    }

    enum Trait6 {
        X6,
        Y6,
        Z6
    }

    enum Trait7 {
        X7,
        Y7,
        Z7
    }


   struct NFTAnatomy {
        Trait1 trait1;
        Trait2 trait2;
        Trait3 trait3;
        Trait4 trait4;
        Trait5 trait5;
        Trait6 trait6;
        Trait7 trait7;
    }

    struct NFTLevel {
        uint8 trait1Lvl;
        uint8 trait2Lvl;
        uint8 trait3Lvl;
        uint8 trait4Lvl;
        uint8 trait5Lvl;
        uint8 trait6Lvl;
        uint8 trait7Lvl;
    }

    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);
    event Setted(uint256 value);
    error InvalidSigner();
    error RangeOutOfBounds();
    error callErr();
    error Mergefailed();
    error invalidSigner();
    event MergeRequested(uint256 _1st, uint256 _2nd, uint256 _3rd, address _owner);
    event MergeFulfilled(uint256 mergeId);
    event MergePrizeStatus(bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// _______________________________________________________________________
//     _   _                              __                              
//     /  /|                            /    )                            
// ---/| /-|----__---)__----__----__---/---------__--_/_----__---)__---__-
//   / |/  |  /___) /   ) /   ) /___) /  --,   /   ) /    /   ) /   ) (_ `
// _/__/___|_(___ _/_____(___/_(___ _(____/___(___(_(_ __(___/_/_____(__)_
//                          /                                             
//                      (_ /                                              

import {MultiSigWallet} from './treasury.sol';
// import "./IAlligators.sol";
import './extension/Ownable.sol';
import './extension/Guard.sol';
import './chainlink/VRFConsumerBaseV2.sol';
import './chainlink/VRFCoordinatorV2Interface.sol';
import './IMergeGators.sol';

interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract MergeGators is Ownable, VRFConsumerBaseV2, IMergeGators, ReentrancyGuard {
    //Alligators alligators;
    /*//////////////////////////////////////////////////////////////
                               MERGE GATORS
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => RequestStatusMerge) private vrf_requests; 

    uint64 private immutable subscriptionId;
    uint32 private immutable callbackGasLimit = 100_000;
    uint32 private constant NUM_WORDS = 1;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    bytes32 private immutable gasLane;
    VRFCoordinatorV2Interface private immutable m_vrfCoordinator;

    uint256 internal constant MAX_CHANCE_VALUE = 1000;
    uint256 internal MIN_CHANCE_VALUE = 777;

    uint256 private _taxAmount;
    uint256 private _prizeBps;
    uint256 private _prizePortionBps;

    address payable public taxTreasury;
    address public alligators;
    
    constructor(
        address payable erc721_,
        address payable _taxTreasuryAddress,
        uint256 taxPay_,
        uint64 subscriptionId_,
        address vrfCoordinatorV2_,
        bytes32 gasLane_,
        uint256 prizeBps_,
        uint256 poolPortionBps_
    ) VRFConsumerBaseV2(vrfCoordinatorV2_) {
            require(erc721_ != address(0) && _taxTreasuryAddress != address(0), "construction failed");
            _setupOwner(msg.sender);
            //alligators = Alligators(ERC721_);
            alligators = erc721_;
            //alligators = Alligators(erc721_);
            taxTreasury = _taxTreasuryAddress;
            _taxAmount = taxPay_;
            _prizeBps = prizeBps_;
            _prizePortionBps = poolPortionBps_;
            subscriptionId = subscriptionId_;
            m_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2_);
            gasLane = gasLane_;
        }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function merge3NFTs(uint256 _1st, uint256 _2nd, uint256 _3rd) public payable nonReentrant() {
        require(msg.value >= _taxAmount, "ERR");
        payable(address(this)).transfer(_calculatePortionToRewardPool());
        taxTreasury.transfer(_calculatePortionToRewardPool());
        bytes memory data = abi.encodeWithSignature("merge3alligators(uint256,uint256,uint256,address)",_1st, _2nd, _3rd, msg.sender);
        (bool success, ) = address(alligators).call(data);
        require(success, "LowCallFailed");
        _mergePrize(msg.sender);
    }

    function merge3Wjoker(uint256 _1st, uint256 _2nd, uint256 _3rd) public payable nonReentrant() {
        require(msg.value >= _taxAmount, "ERR");
        payable(address(this)).transfer(_calculatePortionToRewardPool());
        taxTreasury.transfer(_calculatePortionToRewardPool());
        bytes memory data = abi.encodeWithSignature("mergeWjoker(uint256,uint256,uint256,address)",_1st, _2nd, _3rd, msg.sender);
        (bool success, ) = address(alligators).call(data);
        require(success, "LowCallFailed");
        _mergePrize(msg.sender);
    }
    
    function _mergePrize(address _receiver) internal returns (uint256 requestId) {
        requestId = m_vrfCoordinator.requestRandomWords(
            gasLane,
            subscriptionId,
            REQUEST_CONFIRMATIONS,
            callbackGasLimit,
            NUM_WORDS
        );
        vrf_requests[requestId] = RequestStatusMerge(
            {
                randomWords: new uint256[](0),
                prize : 0, reciever: _receiver
            });
        emit RequestSent(requestId, NUM_WORDS);
        return requestId;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        vrf_requests[_requestId].randomWords = _randomWords;

        uint moddedRng = _randomWords[0] % MAX_CHANCE_VALUE;

        uint256[2] memory chanceArracy = getChanceArray();

        if (moddedRng > chanceArracy[0]) {
            // withdraw from tax treasury to the reciever. !!!
            address payable to = payable(vrf_requests[_requestId].reciever);
            to.transfer(_calculatePortionToDistribute());
            emit MergePrizeStatus(true);
        }
        emit RequestFulfilled(_requestId, _randomWords);
    }

    function _getBalance() internal view returns (uint256) {
        address payable self = payable(address(this));
        uint256 balance = self.balance;
        return balance;
    }

    function _calculatePortionToDistribute() internal view returns (uint256) {
        return _getBalance() * _prizeBps / 10_000;
    }

    function _calculatePortionToRewardPool() internal view returns (uint256) {
        return _taxAmount * _prizePortionBps / 10_000;
    }

    function _canSetOwner() internal virtual view override returns (bool) {
        return msg.sender == owner();
    }

    function getChanceArray() public view returns (uint256[2] memory) {
        return [MIN_CHANCE_VALUE, MAX_CHANCE_VALUE];
    }

    function setChanceArray(uint256 _min) external onlyOwner {
        require(_min < MAX_CHANCE_VALUE, "invalid");
        MIN_CHANCE_VALUE = _min;
        emit Setted(_min);
    }

    function setTaxAmount(uint256 taxAmount) external onlyOwner {
        _taxAmount = taxAmount;
        emit Setted(taxAmount);
    }

    function setRewardPoolPortion(uint256 percentage) external onlyOwner {
        _prizePortionBps = percentage;
        emit Setted(percentage);
    }

    function setPrizePortion(uint256 percentage) external onlyOwner {
        _prizeBps = percentage;
        emit Setted(percentage);
    }

    function setTreasuryAddress(address payable _taxTreasuryAddress) external onlyOwner {
        if (_taxTreasuryAddress == address(0)) revert callErr();
        taxTreasury = _taxTreasuryAddress;
    }
    
    function rescueFunds(uint256 _amount, address payable _rescueTo) external onlyOwner {
        if (_rescueTo == address(0)) revert callErr();
        _rescueTo.transfer(_amount);
        }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

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
pragma solidity ^0.8.16;

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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.17;

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

import "../interfaces/IOwnable.sol";

abstract contract Ownable is IOwnable {
    /// @dev Owner of the contract (purpose: OpenSea compatibility)
    address private _owner;

    /// @dev Reverts if caller is not the owner.
    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert("Not authorized");
        }
        _;
    }

    /**
     *  @notice Returns the owner of the contract.
     */
    function owner() public view override returns (address) {
        return _owner;
    }

    /**
     *  @notice Lets an authorized wallet set a new owner for the contract.
     *  @param _newOwner The address to set as the new owner of the contract.
     */
    function setOwner(address _newOwner) external override {
        if (!_canSetOwner()) {
            revert("Not authorized");
        }
        _setupOwner(_newOwner);
    }

    /// @dev Lets a contract admin set a new owner for the contract. The new owner must be a contract admin.
    function _setupOwner(address _newOwner) internal {
        address _prevOwner = _owner;
        _owner = _newOwner;

        emit OwnerUpdated(_prevOwner, _newOwner);
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view virtual returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

interface IOwnable {
    /// @dev Returns the owner of the contract.
    function owner() external view returns (address);

    /// @dev Lets a module admin set a new owner for the contract. The new owner must be a module admin.
    function setOwner(address _newOwner) external;

    /// @dev Emitted when a new Owner is set.
    event OwnerUpdated(address indexed prevOwner, address indexed newOwner);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract MultiSigWallet {
    event Deposit(address indexed sender, uint amount, uint balance);
    event SubmitTransaction(
        address indexed owner,
        uint indexed txIndex,
        address indexed to,
        uint value,
        bytes data
    );
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public numConfirmationsRequired;

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numConfirmations;
    }

    // mapping from tx index => owner => bool
    mapping(uint => mapping(address => bool)) public isConfirmed;

    Transaction[] public transactions;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    constructor(address[] memory _owners, uint _numConfirmationsRequired) {
        require(_owners.length > 0, "owners required");
        require(
            _numConfirmationsRequired > 0 &&
                _numConfirmationsRequired <= _owners.length,
            "invalid number of required confirmations"
        );

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function submitTransaction(
        address _to,
        uint _value,
        bytes memory _data
    ) public onlyOwner {
        uint txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    function confirmTransaction(
        uint _txIndex
    ) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) notConfirmed(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function executeTransaction(
        uint _txIndex
    ) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "tx failed");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(
        uint _txIndex
    ) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    function getTransaction(
        uint _txIndex
    )
        public
        view
        returns (
            address to,
            uint value,
            bytes memory data,
            bool executed,
            uint numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../../src/MergeGators.sol";

contract MergeGatorsMock is MergeGators {

    address payable collection_ = payable(0x65A857da5Be3371FE8FD87C526f81B419145235D);
    uint256 constant bps = 3;
    uint256 constant portion = 30;

    address payable constant taxAddr = payable(0x7f310fd29922d80e1bD66f036F9C1025D92502bA);
    uint256 taxPay = 0.00001 ether;

    constructor(
        uint64 subscriptionId,
        address vrfCoordinatorV2,
        bytes32 gasLane
        )
        MergeGators(collection_,
                    taxAddr,
                    taxPay,
                    subscriptionId,
                    vrfCoordinatorV2,
                    gasLane,
                    bps,
                    portion)
    {}

}