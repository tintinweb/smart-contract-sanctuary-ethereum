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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/IPirateGames.sol";
import "./interfaces/IPytheas.sol";
import "./interfaces/IOrbitalBlockade.sol";
import "./interfaces/ITPirates.sol";
import "./interfaces/IRAW.sol";
import "./interfaces/IPirates.sol";
import "./interfaces/IColonist.sol";
import "./interfaces/IImperialGuild.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";


contract PirateGames is IPirateGames, VRFConsumerBaseV2, Pausable {
    struct MintCommit {
        bool stake;
        uint16 tokenId;
    }

    uint8[][6] public rarities;
    uint8[][6] public aliases;

    uint256 public OnosiaLiquorId;

    uint256 private maxRawEonCost;


    // address => can call
    mapping(address => bool) private admins;

    // address -> commit # -> commits
    mapping(address => mapping(uint16 => MintCommit)) private _mintCommits;
    // address -> commit num of commit need revealed for account
    mapping(address => uint16) private _pendingCommitId;

    // amout pending needed to toggle randomness
    uint16 toggleLimit;
    // counter for toggle randomness
    uint16 toggleCounter;

    uint16 private _commitId = 1;
    uint16 private pendingMintAmt;
    bool public allowCommits = false;

    address public auth;

    // reference to Pytheas for checking that a colonist has mined enough
    //rEON to make an attempt as well as pay from this amount, either the  current mint cost on
    //a successful pirate mint, or pirate tax on a failed attempt.
    IPytheas public pytheas;
    //reference to the OrbitalBlockade, where pirates are staked out, awaiting weak colonist miners.
    IOrbitalBlockade public orbital;
    // reference to raw Eon for attempts
    IRAW public raw;
    // reference to pirate collection
    IPirates public pirateNFT;
    // reference to the colonist NFT collection
    IColonist public colonistNFT;
    // reference to the galactic imperialGuild collection
    IImperialGuild public imperialGuild;
    // Chainlink references
    VRFCoordinatorV2Interface COORDINATOR;

    uint64 s_subscriptionId;
    uint256 linkFee;
    address vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
    bytes32 keyHash; 
    uint32 callbackGasLimit;
    uint16 requestConfirmations;
      //amount pending that toggles a randomness call
    uint32 public numWords = 1;
    uint256[] private randomness;
    uint256 public s_requestId;
    address s_owner;

    event MintCommitted(address indexed owner, uint256 indexed tokenId);
    event MintRevealed(address indexed owner, uint16[] indexed tokenId);

    constructor() VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_owner = msg.sender;
        auth = msg.sender;
        admins[msg.sender] = true;
        admins[address(this)] = true;

        //RatioChance 90
        rarities[0] = [27, 230];
        aliases[0] = [1, 0];
        //RatioChance 80
        rarities[1] = [51, 204];
        aliases[1] = [1, 0];
        //RatioChance 60
        rarities[2] = [90, 175];
        aliases[2] = [1, 0];
        //RatioChance 40
        rarities[3] = [155, 132];
        aliases[3] = [1, 0];
        //RatioChance 10
        rarities[4] = [200, 60];
        aliases[4] = [1, 0];
        //RatioChance 0
        rarities[5] = [255];
        aliases[5] = [0];
    }

    modifier noCheaters() {
        uint256 size = 0;
        address acc = msg.sender;
        assembly {
            size := extcodesize(acc)
        }

        require(
            admins[msg.sender] || (msg.sender == tx.origin && size == 0),
            "you're trying to cheat!"
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == auth);
        _;
    }

    /** CRITICAL TO SETUP */
    modifier requireContractsSet() {
        require(
            address(raw) != address(0) &&
                address(pirateNFT) != address(0) &&
                address(colonistNFT) != address(0) &&
                address(pytheas) != address(0) &&
                address(orbital) != address(0) &&
                address(imperialGuild) != address(0),
            "Contracts not set"
        );
        _;
    }

    function setContracts(
        address _rEON,
        address _pirateNFT,
        address _colonistNFT,
        address _pytheas,
        address _orbital,
        address _imperialGuild
    ) external onlyOwner {
        raw = IRAW(_rEON);
        pirateNFT = IPirates(_pirateNFT);
        colonistNFT = IColonist(_colonistNFT);
        pytheas = IPytheas(_pytheas);
        orbital = IOrbitalBlockade(_orbital);
        imperialGuild = IImperialGuild(_imperialGuild);
    }

    function getPendingMint(address addr)
        external
        view
        returns (MintCommit memory)
    {
        require(_pendingCommitId[addr] != 0, "no pending commits");
        return _mintCommits[addr][_pendingCommitId[addr]];
    }

    function hasMintPending(address addr) external view returns (bool) {
        return _pendingCommitId[addr] != 0;
    }

    function canMint(address addr) external view returns (bool) {
         uint16 commitIdCur = _pendingCommitId[addr];
         if (randomness.length == 1) {
            return 
            _pendingCommitId[addr] != 0;
         } else {
        return
            _pendingCommitId[addr] != 0 &&
            randomness.length >= commitIdCur;
         }
    }

     // Assumes the subscription is funded sufficiently.
    function requestRandomWords() internal {
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
         randomness.push(randomWords[0]);
    }


    function deleteCommit(address addr) external {
        require(
            auth == msg.sender || admins[msg.sender],
            "Only admins can call this"
        );

        uint16 commitIdCur = _pendingCommitId[addr];
        require(commitIdCur > 0, "No pending commit");
        delete _mintCommits[addr][commitIdCur];
        delete _pendingCommitId[addr];
    }

    function forceRevealCommit(address addr) external {
        require(
            auth == msg.sender || admins[msg.sender],
            "Only admins can call this"
        );
        pirateAttempt(addr);
    }

    function mintCommit(uint16 tokenId, bool stake)
        external
        whenNotPaused
        noCheaters
    {
        require(allowCommits, "adding commits disallowed");
        require(
            _pendingCommitId[msg.sender] == 0,
            "Already have pending mints"
        );
        uint16 piratesMinted = pirateNFT.piratesMinted();
        require(
            piratesMinted + pendingMintAmt + 1 <= 6000,
            "All tokens minted"
        );
        uint256 minted = colonistNFT.minted();
        uint256 maxTokens = colonistNFT.getMaxTokens();
        uint256 rawCost = rawMintCost(minted, maxTokens);

        raw.burn(1, rawCost, msg.sender);
        raw.updateOriginAccess(msg.sender);

        colonistNFT.transferFrom(msg.sender, address(this), tokenId);

        _mintCommits[msg.sender][_commitId] = MintCommit(stake, tokenId);
        _pendingCommitId[msg.sender] = _commitId;
        pendingMintAmt += 1;
        toggleCounter += 1;
        if (toggleCounter == toggleLimit) {
            requestRandomWords();
            toggleCounter = 0;
            _commitId += 1; 
        }
        emit MintCommitted(msg.sender, tokenId);
    }

    function mintReveal() external whenNotPaused noCheaters {
        pirateAttempt(msg.sender);
    }

    function pirateAttempt(address addr) internal {
        uint16 commitIdCur = _pendingCommitId[addr];
        require(commitIdCur >= 0, "No pending commit");
        require(randomness.length >= commitIdCur, "Random seed not set");
        MintCommit memory commit = _mintCommits[addr][commitIdCur];
        pendingMintAmt -= 1;
        uint16 colonistId = commit.tokenId;
        uint16 piratesMinted = pirateNFT.piratesMinted();
        uint256 seed = randomness[commitIdCur];
        uint256 circulation = colonistNFT.totalCir();
        uint8 chanceTable = getRatioChance(piratesMinted, circulation);
        seed = uint256(keccak256(abi.encode(seed, addr)));
        uint8 yayNay = getPirateResults(seed, chanceTable);
        // if the attempt fails, pay pirate tax and claim remaining
        if (yayNay == 0) {
            colonistNFT.safeTransferFrom(address(this), addr, colonistId);
        } else {
            colonistNFT.burn(colonistId);
            uint16[] memory pirateId = new uint16[](1);
            uint16[] memory pirateIdToStake = new uint16[](1);
            piratesMinted++;
            address recipient = selectRecipient(seed);
            if (
                recipient != addr &&
                imperialGuild.getBalance(addr, OnosiaLiquorId) > 0
            ) {
                // If the mint is going to be stolen, there's a 50% chance
                //  a pirate will prefer a fine crafted EON liquor over it
                if (seed & 1 == 1) {
                    imperialGuild.safeTransferFrom(
                        addr,
                        recipient,
                        OnosiaLiquorId,
                        1,
                        ""
                    );
                    recipient = addr;
                }
            }

            pirateId[0] = piratesMinted;
            if (!commit.stake || recipient != addr) {
                pirateNFT._mintPirate(recipient, seed);
            } else {
                pirateNFT._mintPirate(address(orbital), seed);
                pirateIdToStake[0] = piratesMinted;
            }
            pirateNFT.updateOriginAccess(pirateId);
            if (commit.stake) {
                orbital.addPiratesToCrew(addr, pirateIdToStake);
            }
            emit MintRevealed(addr, pirateId);
        }
        delete _mintCommits[addr][commitIdCur];
        delete _pendingCommitId[addr];
    }

    /**
     * @return the cost of the given token ID
     */
    function rawMintCost(uint256 tokenId, uint256 maxTokens)
        internal
        view
        returns (uint256)
    {
        if (tokenId <= (maxTokens * 8) / 24) return 4000; //10k-20k
        if (tokenId <= (maxTokens * 12) / 24) return 16000; //20k-30k
        if (tokenId <= (maxTokens * 16) / 24) return 48000; //30k-40k
        if (tokenId <= (maxTokens * 20) / 24) return 122500; //40k-50k
        if (tokenId <= (maxTokens * 22) / 24) return 250000; //50k-55k
        return maxRawEonCost;
    }

    function getRatioChance(uint256 pirates, uint256 circulation)
        public
        pure
        returns (uint8)
    {
        uint256 ratio = (pirates * 10000) / circulation;

        if (ratio <= 100) {
            return 0;
        } else if (ratio <= 300 && ratio >= 100) {
            return 1;
        } else if (ratio <= 500 && ratio >= 300) {
            return 2;
        } else if (ratio <= 800 && ratio >= 500) {
            return 3;
        } else if (ratio <= 999 && ratio >= 800) {
            return 4;
        } else {
            return 5;
        }
    }

    /**
     * Determines if an attempt to join the pirates is successful or not
     * granting a higher chance of success when the pirate to colonist ratio is
     * low, as the ratio gets closer to 10% the harder a chance at joining the pirates
     * becomes until ultimately they will not accept anyone else if the ratio is += 10%
    */
    function getPirateResults(uint256 seed, uint8 chanceTable)
        internal
        view
        returns (uint8)
    {
        seed >>= 16;
        uint8 yayNay = getResult(uint16(seed & 0xFFFF), chanceTable);
        return yayNay;
    }

    function getResult(uint256 seed, uint8 chanceTable)
        internal
        view
        returns (uint8)
    {
        uint8 result = uint8(seed) % uint8(rarities[chanceTable].length);
        // If the selected chance talbles rareity is selected (biased coin) return that
        if (seed >> 8 < rarities[chanceTable][result]) return result;
        // else return the aliases
        return aliases[chanceTable][result];
    }
    

    /** INTERNAL */

    /**
     * the first 10k colonist mints go to the minter
     * the remaining 80% have a 10% chance to be given to a random staked pirate
     * @param seed a random value to select a recipient from
     * @return the address of the recipient (either the minter or the pirate thief's owner)
     */
    function selectRecipient(uint256 seed) internal view returns (address) {
        if (((seed >> 245) % 10) != 0) return msg.sender; // top 10 bits
        address thief = orbital.randomPirateOwner(seed >> 144); // 144 bits reserved for trait selection
        if (thief == address(0x0)) return msg.sender;
        return thief;
    }

     // Assumes the subscription is funded sufficiently.
    function adminRequestRandomWords() external {
        require(admins[msg.sender], "only admins can request randomness");
        // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }



    /**
     * enables owner to pause / unpause contract
     */
    function setPaused(bool _paused) external requireContractsSet onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    function setOnosiaLiquorId(uint256 typeId) external onlyOwner {
        OnosiaLiquorId = typeId;
    }

    function setAllowCommits(bool allowed) external onlyOwner {
        allowCommits = allowed;
    }

    function setToggleLimit(uint16 _toggleLimit) external onlyOwner {
        toggleLimit = _toggleLimit;
    }

    function setPendingMintAmt(uint256 pendingAmt) external onlyOwner {
        pendingMintAmt = uint16(pendingAmt);
    }

    function setVRFsub(bytes32 _keyHash, uint64 _s_subscriptionId, uint32 _callbackGasLimit, uint16 _requestConfirmations) external onlyOwner {
        keyHash = _keyHash;
        s_subscriptionId = _s_subscriptionId;
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
    }

    function resetToggleCounter (uint16 _toggleCounter) external onlyOwner {
        toggleCounter = _toggleCounter;
    }
    
    function resetCommitId (uint16 commitId) external onlyOwner {
        _commitId = commitId;
    }

    function getCurrent() external view returns (uint16, uint256) {
        return (_commitId, randomness.length);
    }

    /* enables an address to mint / burn
     * @param addr the address to enable
     */
    function addAdmin(address addr) external onlyOwner {
        admins[addr] = true;
    }

    /**
     * disables an address from minting / burning
     * @param addr the address to disable
     */
    function removeAdmin(address addr) external onlyOwner {
        admins[addr] = false;
    }


    function emergencyExtraction(address recipient, uint256 tokenId) external onlyOwner {
        colonistNFT.transferFrom(address(this), recipient, tokenId);
    }
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

interface IColonist {
    // struct to store each Colonist's traits
    struct Colonist {
        bool isColonist;
        uint8 background;
        uint8 body;
        uint8 shirt;
        uint8 jacket;
        uint8 jaw;
        uint8 eyes;
        uint8 hair;
        uint8 held;
        uint8 gen;
    }

    struct HColonist {
        uint8 Legendary;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function isOwner(uint256 tokenId)
        external
        view
        returns (address);

    function minted() external returns (uint16);

    function totalCir() external returns (uint256);

    function _mintColonist(address recipient, uint256 seed) external;

    function _mintToHonors(address recipient, uint256 seed) external;

    function _mintHonors(address recipient, uint8 id) external;

    function burn(uint256 tokenId) external;

    function getMaxTokens() external view returns (uint256);

    function getPaidTokens() external view returns (uint256);

    function getTokenTraitsColonist(uint256 tokenId)
        external
        view
        returns (Colonist memory);

    function getTokenTraitsHonors(uint256 tokenId)
        external
        view
        returns (HColonist memory);

    function tokenNameByIndex(uint256 index)
        external
        view
        returns (string memory);

    function hasBeenNamed(uint256 tokenId) external view returns (bool);

    function nameColonist(uint256 tokenId, string memory newName) external;
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

interface IImperialGuild {

    function getBalance(
        address account,
        uint256 id
    ) external returns(uint256);

    function mint(
        uint256 typeId,
        uint256 paymentId,
        uint16 qty,
        address recipient
    ) external;

    function burn(
        uint256 typeId,
        uint16 qty,
        address burnFrom
    ) external;

    function handlePayment(uint256 amount) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IOrbitalBlockade {
    function addPiratesToCrew(address account, uint16[] calldata tokenIds)
        external;
    
    function claimPiratesFromCrew(address account, uint16[] calldata tokenIds, bool unstake)
        external;

    function payPirateTax(uint256 amount) external;

    function randomPirateOwner(uint256 seed) external view returns (address);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IPirateGames {}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IPirates {
    // struct to store each Colonist's traits
    struct Pirate {
        bool isPirate;
        uint8 sky;
        uint8 cockpit;
        uint8 base;
        uint8 engine;
        uint8 nose;
        uint8 wing;
        uint8 weapon1;
        uint8 weapon2;
        uint8 rank;
    }

    struct HPirates {
        uint8 Legendary;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) external;

    function minted() external returns (uint16);

    function piratesMinted() external returns (uint16);

    function isOwner(uint256 tokenId)
        external
        view
        returns (address);

    function _mintPirate(address recipient, uint256 seed) external;

    function burn(uint256 tokenId) external;

    function getTokenTraitsPirate(uint256 tokenId)
        external
        view
        returns (Pirate memory);

    function getTokenTraitsHonors(uint256 tokenId)
        external
        view
        returns (HPirates memory);

    function tokenNameByIndex(uint256 index)
        external
        view
        returns (string memory);
    
    function isHonors(uint256 tokenId)
        external
        view
        returns (bool);

    function updateOriginAccess(uint16[] memory tokenIds) external;

    function getTokenWriteBlock(uint256 tokenId) 
    external 
    view  
    returns(uint64);

    function hasBeenNamed(uint256 tokenId) external view returns (bool);

    function namePirate(uint256 tokenId, string memory newName) external;
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IPytheas {
    function addColonistToPytheas(address account, uint16[] calldata tokenIds)
        external;

    function claimColonistFromPytheas(address account, uint16[] calldata tokenIds, bool unstake)
        external;

    function getColonistMined(address account, uint16 tokenId)
        external
        returns (uint256);

    function handleJoinPirates(address addr, uint16 tokenId) external;

    function payUp(
        uint16 tokenId,
        uint256 amtMined,
        address addr
    ) external;
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

interface IRAW {

    function updateOriginAccess(address user) external;


    function balanceOf(
        address account,
        uint256 id
    ) external returns(uint256);

    function mint(
        uint256 typeId,
        uint256 qty,
        address recipient
    ) external;

    function burn(
        uint256 typeId,
        uint256 qty,
        address burnFrom
    ) external;

    function updateMintBurns(
        uint256 typeId,
        uint256 mintQty,
        uint256 burnQty
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

interface ITPirates {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}