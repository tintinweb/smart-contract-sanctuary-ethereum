// SPDX-License-Identifier: MIT
/*
 ______     __                            __           __                      __
|_   _ \   [  |                          |  ]         [  |                    |  ]
  | |_) |   | |    .--.     .--.     .--.| |   .--.    | |--.    .---.    .--.| |
  |  __'.   | |  / .'`\ \ / .'`\ \ / /'`\' |  ( (`\]   | .-. |  / /__\\ / /'`\' |
 _| |__) |  | |  | \__. | | \__. | | \__/  |   `'.'.   | | | |  | \__., | \__/  |
|_______/  [___]  '.__.'   '.__.'   '.__.;__] [\__) ) [___]|__]  '.__.'  '.__.;__]
                      ________
                      ___  __ )_____ ______ _________________
                      __  __  |_  _ \_  __ `/__  ___/__  ___/
                      _  /_/ / /  __// /_/ / _  /    _(__  )
                      /_____/  \___/ \__,_/  /_/     /____/
*/
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

interface IBloodToken {
  function spend(address wallet_, uint256 amount_) external;
  function walletsBalances(address wallet_) external view returns (uint256);
}

contract Lottery is VRFConsumerBaseV2, Ownable {

    uint256 private constant MAX_CHANCE = 1_000_000;
    uint256 private constant MAX_UINT256 = type(uint256).max;

    IBloodToken public bloodToken;

    struct ListItem {
        uint256 roundStart; // timestamp
        uint8 status; // 0 = not listed, 1 = don't allow tickets, 2 = allow tickets
        uint256 price; // price of ticket in BLD
        uint32 chance; // number between 1 - MAX_CHANCE, if tickets are limited than 0, should be 1 of N (N = chance)
        /* 
        100% chance = 1
        50% chance = 2
        33.3% chance = 3
        10% chance = 10
        5% chance = 20
        1% chance = 100
        0.1% chance = 1000
        */
        uint256 tickets; // max tickets available, 0 = unlimited
        uint256 maxPerAddress; // max tickets per address, 0 = unlimited
        address winner; // only gets set if user wins it with chance ticket
        address winnerBLD; // only gets set if user wins it with chance ticket
    }

    struct InputItem {
        /* InputItem only used as input parameter */
        uint256 projectId;
        uint8 status;
        uint256 price;
        uint32 chance;
        uint256 tickets;
        uint256 maxPerAddress;
    }

    mapping(uint256 => ListItem) public listDetails; // projectId => ListItem 
    mapping(uint256 => mapping(uint256 => address[])) public projectTickets;
    mapping(bytes32 => uint256) public projectTicketsUser; // bytes32 = projectId + roundStart + address

    mapping(uint256 => uint256[]) private vrfRequest; // requestId => projectIds

    // VRF Settings
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;
    address vrfCoordinator;
    bytes32 s_keyHash;

    uint32 callbackGasLimit = 200000;
    uint16 requestConfirmations = 3;

    event ChanceBought(address wallet, uint256 project, uint256 price, uint256 tickets);
    event DrawComplete(uint256 project, address winner, address winnerBLD);
    event ItemAdded(
        uint256 project, 
        uint256 roundStart, 
        uint8 status, 
        uint256 price, 
        uint32 chance, 
        uint256 tickets, 
        uint256 maxPerAddress
    );
    event ItemUpdated(
        uint256 project, 
        uint8 status, 
        uint256 price, 
        uint32 chance, 
        uint256 tickets, 
        uint256 maxPerAddress
    );
    event ItemRemoved(uint256 project);
    event ItemRestarted(uint256 project, uint256 roundStart);

    constructor(
        address _bloodToken,
        uint64 _subscriptionId,
        address _vrfCoordinator,
        bytes32 _sKeyHash
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        bloodToken = IBloodToken(_bloodToken);
        vrfCoordinator = _vrfCoordinator;
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = _subscriptionId;
        s_keyHash = _sKeyHash;
    }

    /**
    * @dev Add items.
    * @param _items: [InputItem, InputItem, ...]
    */
    function addItems(InputItem[] calldata _items) external onlyOwner {
        for (uint8 i = 0; i < _items.length; i++) {
            require(
                listDetails[_items[i].projectId].status == 0, 
                "Item already listed."
            );
            require(
                _items[i].chance >= 0 && _items[i].chance < MAX_CHANCE, 
                "Chance needs to be in range 0 - MAX_CHANCE."
            );
            require(
                _items[i].status == 1 || _items[i].status == 2, 
                "Status needs to be 1 or 2."
            );

            listDetails[_items[i].projectId] = ListItem({
                roundStart: block.timestamp,
                status: _items[i].status,
                price: _items[i].price,
                chance: _items[i].chance,
                tickets: _items[i].tickets,
                maxPerAddress: _items[i].maxPerAddress,
                winner: address(0),
                winnerBLD: address(0)
            });

            emit ItemAdded(
                _items[i].projectId, 
                listDetails[_items[i].projectId].roundStart, 
                listDetails[_items[i].projectId].status, 
                listDetails[_items[i].projectId].price, 
                listDetails[_items[i].projectId].chance, 
                listDetails[_items[i].projectId].tickets,
                listDetails[_items[i].projectId].maxPerAddress
            );
        }
    }

    /**
    * @dev Remove items.
    * @param _items: [projectId, projectId, projectId, ...]
    */
    function removeItems(uint256[] calldata _items) external onlyOwner {
        for (uint8 i = 0; i < _items.length; i++) {
            require(
                listDetails[_items[i]].status != 0, 
                "Item NOT listed."
            );
            require(
                listDetails[_items[i]].winner == address(0), 
                "Item already won."
            );
            delete listDetails[_items[i]];
            emit ItemRemoved(_items[i]);
        }
    }

    /**
    * @dev Update items.
    * @param _items: [InputItem, InputItem, ...]
    */
    function updateItems(InputItem[] calldata _items) external onlyOwner {
        for (uint8 i = 0; i < _items.length; i++) {
            require(
                listDetails[_items[i].projectId].status != 0, 
                "Item NOT listed."
            );
            require(
                listDetails[_items[i].projectId].winner == address(0), 
                "Item already won."
            );
            require(
                _items[i].chance >= 0 && _items[i].chance < MAX_CHANCE, 
                "Chance needs to be in range 0 - MAX_CHANCE."
            );
            require(
                _items[i].status == 1 || _items[i].status == 2, 
                "Status needs to be 1 or 2."
            );

            listDetails[_items[i].projectId].status = _items[i].status;
            listDetails[_items[i].projectId].price = _items[i].price;
            listDetails[_items[i].projectId].chance = _items[i].chance;
            listDetails[_items[i].projectId].tickets = _items[i].tickets;
            listDetails[_items[i].projectId].maxPerAddress = _items[i].maxPerAddress;

            emit ItemUpdated(
                _items[i].projectId, 
                listDetails[_items[i].projectId].status, 
                listDetails[_items[i].projectId].price, 
                listDetails[_items[i].projectId].chance, 
                listDetails[_items[i].projectId].tickets,
                listDetails[_items[i].projectId].maxPerAddress
            );
        }
    }

    /**
    * @dev Restart items.
    * @param _projectIds: [projectId, projectId, ...]
    */
    function restartItems(uint256[] calldata _projectIds) external onlyOwner {
        for (uint8 i = 0; i < _projectIds.length; i++) {
            require(
                listDetails[_projectIds[i]].status == 1, 
                "Item with incorrect status."
            );
            require(
                listDetails[_projectIds[i]].winner == address(0), 
                "Item already won."
            );

            listDetails[_projectIds[i]].status = 2;
            listDetails[_projectIds[i]].roundStart = block.timestamp;
            listDetails[_projectIds[i]].winnerBLD = address(0);

            emit ItemRestarted(_projectIds[i], listDetails[_projectIds[i]].roundStart);
        }
    }

    /**
    * @dev Buy chance to participate.
    * @param _items: [[projectId, tickets], [projectId, tickets], ...]
    */
    function buyChance(uint256[][] calldata _items, address _user) external {
        uint256 projectId;
        uint256 tickets;
        uint256 amtTotal;
        for (uint8 i = 0; i < _items.length; i++) {
            projectId = _items[i][0];
            tickets = _items[i][1];

            if (tickets > 0) {
                require(listDetails[projectId].status == 2, "Cannot buy item tickets.");
                require(
                    listDetails[projectId].tickets == 0 || 
                    listDetails[projectId].tickets >= noProjTickets(projectId) + tickets, 
                    "Not enough tickets available."
                );

                require(
                    getAvailableTickets(projectId, _user) >= tickets,
                    "Too many tickets requested."
                );

                amtTotal += listDetails[projectId].price * tickets;

                // add tickets for user
                for (uint256 j = 0; j < tickets; j ++) {
                    projectTickets[projectId][listDetails[projectId].roundStart].push(_user);
                }
                projectTicketsUser[getUserHash(projectId, _user)] += tickets;

                emit ChanceBought(_user, projectId, listDetails[projectId].price, tickets);
            }
        }

        if (msg.sender != owner()) {
            require(
                bloodToken.walletsBalances(msg.sender) >= amtTotal, 
                "Insufficient BLD on internal wallet."
            );
            bloodToken.spend(msg.sender, amtTotal);
        }
    }

    /**
    * @dev Draw results to get winners.
    * @param _items: [projectId, projectId, projectId, ...]
    */
    function draw(uint256[] calldata _items) external onlyOwner {
        // Will revert if subscription is not set and funded.
        uint256 _requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            uint32(_items.length)
        );

        uint256 projectId;
        for (uint8 i = 0; i < _items.length; i++) {
            projectId = _items[i];

            require(
                listDetails[projectId].status != 0, 
                "Item NOT listed."
            );
            require(
                listDetails[projectId].winner == address(0), 
                "Item already won."
            );

            vrfRequest[_requestId].push(projectId);
        }
    }

    function noProjTickets(uint256 _projectId) public view returns (uint256) {
        return projectTickets[_projectId][listDetails[_projectId].roundStart].length;
    }

    function getProjTicket(uint256 _projectId, uint256 _idx) public view returns (address) {
        return projectTickets[_projectId][listDetails[_projectId].roundStart][_idx];
    }

    function getUserHash(uint256 _projectId, address _user) public view returns (bytes32) {
        return keccak256(
            abi.encodePacked(_projectId, listDetails[_projectId].roundStart, _user)
        );
    }

    function getAvailableTickets(uint256 _projectId, address _user) public view returns (uint256) {
        return listDetails[_projectId].maxPerAddress - projectTicketsUser[getUserHash(_projectId, _user)];
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 projectId;
        uint256 winnerIdx;
        uint256 cntProjTickets;
        for (uint256 i = 0; i < randomWords.length; i++) {
            projectId = vrfRequest[requestId][i];

            if (listDetails[projectId].status == 2) {
                // fail safe in case of multiple draw events

                cntProjTickets = noProjTickets(projectId);
                listDetails[projectId].status = 1; // disable submitting tickets

                if (listDetails[projectId].tickets > 0) {
                    // guaranteed winner
                    winnerIdx = randomWords[i] % cntProjTickets;

                } else {
                    // non-guaranteed winner
                    winnerIdx = randomWords[i] % (listDetails[projectId].chance * cntProjTickets);
                    if (winnerIdx > cntProjTickets - 1) {
                        winnerIdx = MAX_UINT256;
                    }
                }

                if (winnerIdx != MAX_UINT256) {
                    listDetails[projectId].winner = getProjTicket(projectId, winnerIdx);
                }

                // get BLD winner
                listDetails[projectId].winnerBLD = getProjTicket(
                    projectId, (randomWords[i] + block.timestamp) % cntProjTickets
                );
                
                emit DrawComplete(projectId, listDetails[projectId].winner, listDetails[projectId].winnerBLD);
            }
        }
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