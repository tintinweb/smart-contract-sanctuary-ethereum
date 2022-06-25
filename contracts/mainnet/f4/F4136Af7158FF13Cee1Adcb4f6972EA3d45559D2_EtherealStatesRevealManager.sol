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
pragma solidity ^0.8.12;

/// @title EtherealStatesDNA
/// @author Artist: GenuineHumanArt (https://twitter.com/GenuineHumanArt)
/// @author Developer: dievardump (https://twitter.com/dievardump, [email protected])
/// @notice Generates DNA for EtherealStates NFTs
///         A big thank you to cxkoda (https://twitter.com/cxkoda) who helped me with the bit manipulation
///         & assembly and saved quite some gas.
contract EtherealStatesDNA {
    error WrongDistributionForLayer(uint256 layer, uint256 acc);

    function checkLayersValidity() public pure {
        unchecked {
            bytes memory layer;
            uint256 acc;
            uint256 i;
            for (uint256 j; j < 20; j++) {
                layer = getLayer(j);
                acc = 0;
                assembly {
                    for {
                        let current := add(layer, 0x20)
                        let length := mload(layer)
                    } lt(i, length) {
                        current := add(current, 2)
                        i := add(i, 2)
                    } {
                        acc := add(acc, sar(240, mload(current)))
                    }
                    i := 0
                }

                if (acc != 10000) {
                    revert WrongDistributionForLayer(j, acc);
                }
            }
        }
    }

    function generate(uint256 seed, bool includeHolderTraits)
        public
        pure
        returns (bytes32)
    {
        uint256 dna;
        uint256 random;

        unchecked {
            for (uint256 i; i < 20; i++) {
                // keccak the seed, very simple prng
                // we do it on each call, because even if Holders layer is not shown we want to be sure
                // the layers after stay the same with or without it
                seed = uint256(keccak256(abi.encode(seed)));

                // next random number
                random = seed % 10000;

                // push 8 null bits on the right side
                dna <<= 8;

                // done here and not in consumer, because getLayer(i) and pickOne are costly operations.
                // this way we save the gas when the trait is not included
                if (i != 12 || includeHolderTraits) {
                    // set the last 8 bits to the index of the asset in the layer
                    dna |= _pickOne(getLayer(i), random);
                }
            }

            // add 96 null bits right
            dna <<= 96;
        }
        return bytes32(dna);
    }

    function _pickOne(bytes memory layer, uint256 chance)
        public
        pure
        returns (uint256)
    {
        unchecked {
            uint256 i;
            assembly {
                for {
                    let current := add(layer, 0x20)
                    let acc
                } 1 {
                    // add 2 bytes to current position
                    current := add(current, 2)
                    i := add(i, 2)
                } {
                    // add the value of the 2 first bytes of current in acc
                    acc := add(acc, sar(240, mload(current)))
                    // if chance < acc
                    if lt(chance, acc) {
                        break
                    }
                }
                i := sar(1, i)
            }
            return i;
        }
    }

    // this is pretty dirty but this saves quite some gas
    // 1) putting the layers in storage would be very expensive when deploying & when reading storage
    // 2) using arrays of uint for that many assets (512), is too big for a contract
    // After tests, this seems to be a good working compromise
    function getLayer(uint256 which) public pure returns (bytes memory layer) {
        if (which == 0)
            layer = hex'01900190017c017c019001900006015e01900040017c00be0190000a0190015e017c017c0190015e001000680190017c0190017c00140020017c0087017c017c00df015e';
        else if (which == 1)
            layer = hex'012e0132007c00a0005e000a012c01e701e7000c000800b4006401e700a201e701e701e701e701bb01e701e7000e01e701b7000c01b701bb007c0130000e01e701e700a6';
        else if (which == 2)
            layer = hex'01b8019001b801b801a4011801cc01cc01cc0168001401cc01cc01b801cc01b801cc01b801b801b801b801cc01a401cc';
        else if (which == 3)
            layer = hex'004b003602080208020802080208004b00780208009102080110020802080208020801ae020801ae0208004f020802080208';
        else if (which == 4)
            layer = hex'007d004002080208020802080208004b020800a502080129020802080208020801c2020801c202080036020802080208';
        else if (which == 5)
            layer = hex'02260226021202120226021200d2012c022600aa02260096004002120212010400780212005602260212021202260226';
        else if (which == 6)
            layer = hex'01c201c200320064017201c201c20172001901c2017201720096017200960172003201c201c2017201c20064001901c2017201720064017201c201c2009601c2';
        else if (which == 7)
            layer = hex'00a01d4c005500780055009f00c700c7000700a000c700c7009f000500780055005500780005001e00c70078';
        else if (which == 8)
            layer = hex'01a901f401b301b301f401b301b301f401f4010e01f401f401b301f401b301f401a901f4005a01f40096001e01f401f4';
        else if (which == 9)
            layer = hex'020801b301b30208020801b300640208003c020800a001b301e501e501b30208015e020801b300c802080208015e0208';
        else if (which == 10)
            layer = hex'01e001fe019a019a01fe01e001fe01e0019a003201e001fe00960069004b01fe01fe01fe01fe01e001e001fe01fe019a';
        else if (which == 11)
            layer = hex'01f401f401f401f4012c01f40194019401e0001401e001f401f401e0000a019401e001e0019401f401f4019400fa01f4';
        else if (which == 12)
            layer = hex'0000032f032f032f032f032f032f01e00154032f01e00226032f032f032f';
        else if (which == 13)
            layer = hex'00780205020502050205008c01e002050205020501e0020500a000c001e001e00036020501e001e0020500fa02050205';
        else if (which == 14)
            layer = hex'020800be01e0020801e001fe01fe01e000fa003c01e0020800640208008c020801e00208020801e002080208020800a0';
        else if (which == 15)
            layer = hex'0194007801e0019401ea01ea01e00194000a019401ea01ea01ea01ea012c01e000fa01ea01ea01e001e001ea01ea0194';
        else if (which == 16)
            layer = hex'003201c2014301c201c2000a0143000f01c20143014301c200a000a00007005001c2003c00a001c2014301c201c201c201c201c201c201c2014301c201c200a0';
        else if (which == 17)
            layer = hex'00a00143005001a401a400f001a4006401a401a401a401a40143014301a4000a01a400f001a401a401a401a401a401a4014a01a400f000a0003c01430143002d';
        else if (which == 18)
            layer = hex'0143005001a401a401a4014301a40082002d01a4000a01a401a400f001a401a401a400a001a4004601a400a001a401430143014301a4017c00f001a4014a00f0';
        else if (which == 19)
            layer = hex'000a000a000a000a000a000a000a000a268e000a000a000a000a000a';
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {OwnableOperators} from '../../utils/OwnableOperators.sol';

import {EtherealStatesVRFUpdated} from './EtherealStatesVRFUpdated.sol';
import {EtherealStatesDNA} from '../EtherealStatesDNA.sol';

/// @title EtherealStatesRevealManager
/// @author Artist: GenuineHumanArt (https://twitter.com/GenuineHumanArt)
/// @author Developer: dievardump (https://twitter.com/dievardump, [email protected])
/// @notice EtherealStates Reveal logic
contract EtherealStatesRevealManager is
    OwnableOperators,
    EtherealStatesVRFUpdated
{
    error NotRevealed();
    error WrongContext();

    /// @notice emitted whenever the DNA changes.
    event TokenDNAChanged(
        address operator,
        uint256 indexed tokenId,
        bytes32 oldDNA,
        bytes32 newDNA
    );

    /// @notice emitted whenever the random seed is set for a request
    event RequestFulfilled(uint256 requestId, uint256 seed);

    struct RevealGroup {
        uint256 requestId;
        uint256 endTokenId;
    }

    /// @notice NFT holder
    address public etherealstates;

    /// @notice DNA Generator contract
    address public dnaGenerator;

    /// @notice the next group id to reveal
    uint256 public nextGroupId;

    /// @notice seeds for each request sent
    mapping(uint256 => uint256) public seeds;

    /// @notice this allows to save the DNA in the contract instead of having to generate
    ///         it every time we call tokenDNA()
    mapping(uint256 => bytes32) public revealedDNA;

    mapping(uint256 => RevealGroup) public revealedGroups;

    constructor(
        address etherealstates_,
        address dnaGenerator_,
        VRFConfig memory vrfConfig_
    ) EtherealStatesVRFUpdated(vrfConfig_) {
        etherealstates = etherealstates_;
        dnaGenerator = dnaGenerator_;
    }

    /////////////////////////////////////////////////////////
    // Getters                                             //
    /////////////////////////////////////////////////////////

    function hasHoldersTrait(uint256 tokenId) public view returns (bool) {
        return IEtherealStates(etherealstates).hasHoldersTrait(tokenId);
    }

    /// @notice Get the DNA for a given tokenId
    /// @param tokenId the token id to get the DNA for
    /// @return dna the DNA
    function tokenDNA(uint256 tokenId) public view returns (bytes32 dna) {
        dna = revealedDNA[tokenId];

        if (dna == 0x0) {
            (, uint256 seed, ) = groupForTokenId(tokenId, 0);
            if (seed == 0) {
                revert NotRevealed();
            }
            dna = _tokenDNA(tokenId, seed);
        }
    }

    /// @notice Get the DNA for a range of ids
    /// @param startId the token id to start at
    /// @param howMany how many to fatch
    /// @return dnas the DNAs
    function tokensDNA(uint256 startId, uint256 howMany)
        public
        view
        returns (bytes32[] memory dnas)
    {
        uint256 tokenId;

        (
            RevealGroup memory group,
            uint256 seed,
            uint256 currentGroupId
        ) = groupForTokenId(startId, 0);

        bytes32 dna;
        dnas = new bytes32[](howMany);

        for (uint256 i; i < howMany; i++) {
            tokenId = startId + i;
            // if not in this group, select next group
            if (tokenId > group.endTokenId) {
                (group, seed, currentGroupId) = groupForTokenId(
                    tokenId,
                    currentGroupId + 1 // start at next group
                );
            }

            // break the loop if no seed for this group
            if (seed == 0) break;

            dna = revealedDNA[tokenId];
            if (dna == 0x0) {
                dna = _tokenDNA(tokenId, seed);
            }
            dnas[i] = dna;
        }
    }

    /// @notice Returns the group info for a tokenId
    /// @param tokenId the token id
    /// @param startAtGroupId where to start in the groups
    /// @return the group info
    /// @return the seed
    /// @return the group id
    function groupForTokenId(uint256 tokenId, uint256 startAtGroupId)
        public
        view
        returns (
            RevealGroup memory,
            uint256,
            uint256
        )
    {
        uint256 nextGroupId_ = nextGroupId + 1;
        RevealGroup memory group;
        for (; startAtGroupId <= nextGroupId_; startAtGroupId++) {
            group = revealedGroups[startAtGroupId];
            // if we found the right group
            if (group.endTokenId >= tokenId) {
                break;
            }
        }

        return (group, seeds[group.requestId], startAtGroupId);
    }

    /////////////////////////////////////////////////////////
    // Setters                                             //
    /////////////////////////////////////////////////////////

    /// @notice Allows to save the DNA of a tokenId so it doesn't need to be recomputed
    ///         after that
    /// @param tokenId the token id to reveal
    /// @return dna the DNA
    function revealDNA(uint256 tokenId) external returns (bytes32 dna) {
        (, uint256 seed, ) = groupForTokenId(tokenId, 0);

        // make sure the group has a seed
        if (seed == 0) {
            revert NotRevealed();
        }

        dna = revealedDNA[tokenId];

        // only reveal if not already revealed
        if (dna == 0x0) {
            dna = _tokenDNA(tokenId, seed);
            revealedDNA[tokenId] = dna;
            emit TokenDNAChanged(msg.sender, tokenId, 0x0, dna);
        }
    }

    /////////////////////////////////////////////////////////
    // Gated Operator                                      //
    /////////////////////////////////////////////////////////

    /// @notice Allows an Operator to update a token DNA, for reasons
    /// @dev the DNA must have been revealed before
    /// @param tokenId the token id to update the DNA of
    /// @param newDNA the new DNA
    function updateTokenDNA(uint256 tokenId, bytes32 newDNA)
        external
        onlyOperator
    {
        bytes32 dna = revealedDNA[tokenId];
        if (dna == 0x0) {
            revert NotRevealed();
        }

        revealedDNA[tokenId] = newDNA;
        emit TokenDNAChanged(msg.sender, tokenId, dna, newDNA);
    }

    /////////////////////////////////////////////////////////
    // Gated Owner                                         //
    /////////////////////////////////////////////////////////

    /// @notice Allows owner to update dna generator
    /// @param newGenerator the new address of the dna generator
    function setDNAGenerator(address newGenerator) external onlyOwner {
        dnaGenerator = newGenerator;
    }

    /// @notice Allows owner to start the reveal process for the last batch of items minted
    function nextReveal() external onlyOwner {
        // only call if requestId is 0
        if (requestId != 0) {
            revert WrongContext();
        }

        uint256 requestId_ = _requestRandomWords();

        // create next group
        uint256 groupId = nextGroupId++;
        revealedGroups[groupId] = RevealGroup(
            requestId_,
            IEtherealStates(etherealstates).totalMinted()
        );
    }

    /// @notice Allows owner to update the VRFConfig if something is not right
    function setVRFConfig(VRFConfig memory vrfConfig_) external onlyOwner {
        vrfConfig = vrfConfig_;
    }

    /////////////////////////////////////////////////////////
    // Internals                                           //
    /////////////////////////////////////////////////////////

    // called when ChainLink answers with the random number
    function fulfillRandomWords(uint256 requestId_, uint256[] memory words)
        internal
        override
    {
        seeds[requestId_] = words[0];
        emit RequestFulfilled(requestId_, words[0]);

        // allow next reveal
        requestId = 0;
    }

    function _tokenDNA(uint256 tokenId, uint256 seed)
        internal
        view
        returns (bytes32)
    {
        return
            EtherealStatesDNA(dnaGenerator).generate(
                uint256(keccak256(abi.encode(seed, tokenId))),
                hasHoldersTrait(tokenId)
            );
    }
}

interface IEtherealStates {
    function totalMinted() external view returns (uint256);

    function hasHoldersTrait(uint256 tokenId) external view returns (bool);

    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {VRFCoordinatorV2Interface} from '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import {VRFConsumerBaseV2} from '@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';

/// @title EtherealStatesVRFUpdated
/// @author Artist: GenuineHumanArt (https://twitter.com/GenuineHumanArt)
/// @author Developer: dievardump (https://twitter.com/dievardump, [email protected])
/// @notice EtherealStates VRF logic
contract EtherealStatesVRFUpdated is VRFConsumerBaseV2 {
    struct VRFConfig {
        bytes32 keyHash;
        address coordinator;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
        uint16 requestConfirmations;
        uint32 numWords;
    }

    /// @notice ChainLink request id
    uint256 public requestId;

    /// @notice ChainLink config
    VRFConfig public vrfConfig;

    constructor(VRFConfig memory vrfConfig_)
        VRFConsumerBaseV2(vrfConfig_.coordinator)
    {
        vrfConfig = vrfConfig_;
    }

    /// @dev basic call using the vrfConfig
    function _requestRandomWords()
        internal
        virtual
        returns (uint256 requestId_)
    {
        VRFConfig memory vrfConfig_ = vrfConfig;
        // Will revert if subscription is not set and funded.
        requestId_ = VRFCoordinatorV2Interface(vrfConfig_.coordinator)
            .requestRandomWords(
                vrfConfig_.keyHash,
                vrfConfig_.subscriptionId,
                vrfConfig_.requestConfirmations,
                vrfConfig_.callbackGasLimit,
                vrfConfig_.numWords
            );

        requestId = requestId_;
    }

    /// @dev needs to be overrode in the consumer contract
    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory
    ) internal virtual override {}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title Operators
/// @author Simon Fremaux (@dievardump)
contract Operators {
    error NotAuthorized();
    error InvalidAddress(address invalid);

    mapping(address => bool) public operators;

    modifier onlyOperator() virtual {
        if (!isOperator(msg.sender)) revert NotAuthorized();
        _;
    }

    /// @notice tells if an account is an operator or not
    /// @param account the address to check
    function isOperator(address account) public view virtual returns (bool) {
        return operators[account];
    }

    /// @dev set operator state to `isOperator` for ops[]
    function _editOperators(address[] memory ops, bool isOperatorRole)
        internal
    {
        for (uint256 i; i < ops.length; i++) {
            if (ops[i] == address(0)) revert InvalidAddress(ops[i]);
            operators[ops[i]] = isOperatorRole;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';

import './Operators.sol';

/// @title OwnableOperators
/// @author Simon Fremaux (@dievardump)
contract OwnableOperators is Ownable, Operators {
    ////////////////////////////////////////////
    // Only Owner                             //
    ////////////////////////////////////////////

    /// @notice add new operators
    /// @param ops the list of operators to add
    function addOperators(address[] memory ops) external onlyOwner {
        _editOperators(ops, true);
    }

    /// @notice add a new operator
    /// @param operator the operator to add
    function addOperator(address operator) external onlyOwner {
        address[] memory ops = new address[](1);
        ops[0] = operator;
        _editOperators(ops, true);
    }

    /// @notice remove operators
    /// @param ops the list of operators to remove
    function removeOperators(address[] memory ops) external onlyOwner {
        _editOperators(ops, false);
    }

    /// @notice remove an operator
    /// @param operator the operator to remove
    function removeOperator(address operator) external onlyOwner {
        address[] memory ops = new address[](1);
        ops[0] = operator;
        _editOperators(ops, false);
    }
}