// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../Raffle.sol";
import "../extensions/RafflePurchaseable.sol";
import "../extensions/RaffleVRFRandomPick.sol";

/** 
 * @title VRFRaffle
 * @dev Provides a complete raffle system where entries are purchased at the entry
 *      price, the winner is selected using VRF, and the balance of all entries
 *      is sent to the winner.
 */
contract VRFRaffle is Ownable, Raffle, RafflePurchaseable, RaffleVRFRandomPick {

    constructor(
        uint256 entryCost,
        address vrfCoordinator
    ) RaffleVRFRandomPick(vrfCoordinator) {
        price = entryCost;
    }

    receive() external payable {
        _enter(1);
    }

    fallback() external payable {
        _enter(1);
    }
    
    /**
    * @notice Adds the sender to the list of raffle entries
    * @param qnty The number of entries to add for sender
    */
    function enter(uint16 qnty) external payable {
        _enter(qnty);
    }

    function pickWinner() external onlyOwner {
        _randomPickWinner();
    }

    function _enter(uint16 qnty) internal override {
        _purchase(qnty);
        super._enter(qnty);
    }

    function _resolveRandomPick(uint256 idx) internal override {
        address _winner = _pickWinner(idx);
        _sendWinnings(_winner);
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "../Raffle.sol";


/**
 * WORKSHOP STEPS FOR VRF EXTENSION:
 * 
 * 1. Go to https://vrf.chain.link/. Create and fund a subscription on Ethereum Goerli.
 * 
 * 2. Find the coordinator address and key hash for your consumer contract at https://docs.chain.link/docs/vrf-contracts/.
 * 
 * 3. Define the _subscriptionId and _keyHash variables with the info from steps 1 & 2.
 * 
 * 4. Implement the _randomPickWinner and fulfillRandomWords functions.
 * 
 * 5. Compile and deploy the VRFRaffle.sol contract with the Ethereum Goerli VRFv2 Coordinator address.
 * 
 * 6. Add the deployed contract address from step 5 as a consumer of the VRF subscription you created.
 * 
 * 7. Play the raffle!
 */


/** 
 * @title RaffleVRFRandomPick
 * @dev Extends the base raffle system with public functions plus VRF based winner selection
 */
abstract contract RaffleVRFRandomPick is Raffle, VRFConsumerBaseV2 {
    
    uint64 private constant _subscriptionId = 55; // Subscription ID of the VRF consumer

    bytes32 private constant _keyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15; // The key hash to be used for the VRF request

    uint32 private constant _numWords =  1; // Number of random words the consumer will request
    
    uint16 private constant _requestConfirmations = 3; // The delay in blocks before the VRF request is served

    uint32 private constant _callbackGasLimit = 100000; // The gas limit given to 

    uint256 public requestId; // The request ID of the VRF request once it is made

    VRFCoordinatorV2Interface COORDINATOR; // The VRF Coordinator


    /**
     * @param vrfCoordinatorAddress the address of the VRFv2 Coordinator.
     */
    constructor(
        address vrfCoordinatorAddress
    ) VRFConsumerBaseV2(vrfCoordinatorAddress) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinatorAddress);
    }

    /**
     * @notice Requests the random winner to be generated.
     * @dev hint: see the requestRandomWords function in VRFCoordinatorV2Interface.
     */
    function _randomPickWinner() internal virtual {
        // Implement me.
        requestId = COORDINATOR.requestRandomWords(
            _keyHash,
            _subscriptionId,
            _requestConfirmations,
            _callbackGasLimit,
            _numWords
        );
    }

    /**
     * @notice Fulfilled by VRF node.
     * @param randomWords a list of random words i.e [rand1, rand2, ...]
     *
     * @dev hint: use the modulo of this.entryCount() on the first item in the randomWords array, 
     * then use the _resolveRandomPick function 
     */
    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        uint256 idx = randomWords[0]%this.entryCount();
        _resolveRandomPick(idx);
    }

    function _resolveRandomPick(uint256 idx) internal virtual {
        _pickWinner(idx);
    }
}


interface VRFCoordinatorV2Interface {

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
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

/** 
 * @title RafflePurchaseable
 * @notice Provides utilities to process raffle entry purchases
 */
abstract contract RafflePurchaseable {

    uint256 public balance;

    uint256 public price;

    function _purchase(uint256 quantity_) internal virtual {
        require(msg.value >= quantity_ * price, "amount must be at least quantity times price");
        balance += msg.value;
    }

    /**
    * @notice Sends contract balance to the winner; override for custom logic
    * @param winner The winners address
    */
    function _sendWinnings(address winner) internal virtual {
        _beforeSendWinnings();

        uint256 _toSend = balance;
        balance = 0;
        payable(winner).transfer(_toSend);
        
        _afterSendWinnings();
    }

    function _setPrice(uint256 price_) internal virtual {
        price = price_;
    }

    function _beforeSendWinnings() internal virtual {}

    function _afterSendWinnings() internal virtual {}

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

/** 
 * @title Raffle
 * @notice Provides a basic raffle system
 */
abstract contract Raffle {

    // Emits a purchased raffle entry event
    event RaffleEntry(address indexed purchaser, uint256 quantity);

    // Emits a winner event with the winner address
    event RaffleWinner(address indexed winner);

    // an Entry represents a single entry purchase for a raffle
    struct Entry {
        address player;
    }

    // owner is the creator of the contract and is used for permissioned function calls
    address private _owner;

    // collection of entries for the current raffle
    Entry[] private _entries;

    /**
    * @notice Returns the total number of entries for the active raffle
    */
    function entryCount() public view returns (uint256) {
        return _entries.length;
    }

    /**
    * @notice Adds the entries to the private list of entries
    * @param qnty The number of entries to add for sender
    */
    function _enter(uint16 qnty) internal virtual {
        for (uint i = 0; i < qnty; i++) {
            _entries.push(Entry({
                player: msg.sender
            }));
        }

        emit RaffleEntry(msg.sender, qnty);
    }

    /**
    * @notice Provides logic to pick a winner from the list of entries
    * @param idx The index of the winner in the list of entries
    */
    function _pickWinner(uint256 idx) internal returns (address) {
        require(idx >= 0 && idx < _entries.length, "winner out of bounds");
        // collect winner info before modifying state
        Entry memory _winner = _entries[idx];
        
        // modify internal contract state before transfering funds
        delete _entries;

        // allow custom logic for extended cleanup
        _afterPickWinner(_winner.player);

        return _winner.player;
    }

    /**
    * @notice Cleanup function for after winner has been picked
    */
    function _afterPickWinner(address winner) internal virtual {
        emit RaffleWinner(winner);
    }

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