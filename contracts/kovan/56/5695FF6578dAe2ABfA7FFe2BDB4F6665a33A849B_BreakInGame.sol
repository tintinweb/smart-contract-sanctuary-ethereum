// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

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
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
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
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {
  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 private constant USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {
  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

// SPDX-License-Identifier: MIT

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT

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
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

interface INFTMinter {
    function getNFTAttributes(uint256 NFTID)
        external
        returns (
            uint256 agility,
            uint256 strength,
            uint256 charm,
            uint256 sneak,
            uint256 health
        );

    function changeNFTAttributes(
        uint256 NFTID,
        uint256 health,
        uint256 agility,
        uint256 strength,
        uint256 sneak,
        uint256 charm
    ) external returns (bool);
}

contract BreakInGame is VRFConsumerBase, Ownable, KeeperCompatibleInterface {
    bytes32 internal keyHash;
    uint256 internal fee;

    uint256 public randomResult;

    address keeperRegistryAddress;

    modifier onlyKeeper() {
        require(msg.sender == keeperRegistryAddress);
        _;
    }
    uint256 hospitalBill = 1000 * 10**18;
    uint256 public lastCheckIn = block.timestamp;
    uint256 public checkInTimeInterval = 864000; //default to six months
    address public nextOwner;

    INFTMinter IBreakInNFTMinter;
    IERC721 breakInNFT; //address of breakInNFTs
    IERC20 socialLegoToken; //address of SocialLego token

    constructor(
        address _vrfCoordinator,
        address _link,
        address _keeperRegistryAddress,
        address _breakInNFT,
        address _socialLegoToken
    ) VRFConsumerBase(_vrfCoordinator, _link) {
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
        fee = 0.1 * 10**18; // 0.1 LINK (Varies by network)

        keeperRegistryAddress = _keeperRegistryAddress;
        IBreakInNFTMinter = INFTMinter(_breakInNFT);
        breakInNFT = IERC721(_breakInNFT);
        socialLegoToken = IERC20(_socialLegoToken);
    }

    struct scenarios {
        string name;
        uint256 riskBaseDifficulty;
        uint256 payoutAmountBase;
    }
    struct NFTCharacter {
        uint256 born;
        uint256 health;
        uint256 agility;
        uint256 strength;
        uint256 sneak;
        uint256 charm;
        uint256 characterID;
    }
    struct depostedCharacter {
        uint256 NFTID;
        bool isDeposited;
        bool arrested;
        uint256 freetoPlayAgain;
        bool playingPVP;
        uint256 canStopPlayingPVP;
        uint256 lootingTimeout;
        uint256 health;
        uint256 agility;
        uint256 strength;
        uint256 sneak;
        uint256 charm;
    }
    struct gamePlay {
        address player;
        uint256 scenario;
        uint256 breakInStyle;
        uint256 difficultyLevel;
        uint256 health;
        uint256 agility;
        uint256 strength;
        uint256 sneak;
        uint256 charm;
    }
    struct jailBreak {
        address player;
        uint256 breakInStyle;
        uint256 health;
        uint256 agility;
        uint256 strength;
        uint256 sneak;
        uint256 charm;
        address targetPlayer; // who you want to break out
    }
    struct PvP {
        address player;
        uint256 breakInStyle;
        uint256 difficultyLevel;
        uint256 health;
        uint256 agility;
        uint256 strength;
        uint256 sneak;
        uint256 charm;
        address targetPlayer; // who you want to steal from
        uint256 targetPlayerHealth;
        uint256 targetPlayerAgility;
        uint256 targetPlayerStrength;
        uint256 targetPlayerSneak;
        uint256 targetPlayerCharm;
    }

    struct gameModes {
        uint256 gameMode; // 0 if robbing, 1 if jailBreak, 2 if PvP
    }

    event gameCode(bytes32 requestID, address player, uint256 code);
    uint256 differentGameScenarios;
    mapping(uint256 => scenarios) public gameScenarios; // current gameScenarios for robbing
    mapping(bytes32 => PvP) currentPVPGamePlays; // for if you are trying to steal from a player
    mapping(bytes32 => gamePlay) currentGamePlays; // this is for a standard robbing gameplay
    mapping(bytes32 => gameModes) currentGameMode; // this allows for a quick compare statement to determine which game to play to safe gas
    mapping(bytes32 => jailBreak) currentJailBreaks; // this is for players trying to break out a buddy
    mapping(address => depostedCharacter) public NFTCharacterDepositLedger; // Players deposit their NFT into this contract to Play
    mapping(address => uint256) public jewelDepositLedger; // Players must deposit their loot to play PvP

    function changeHospitalBill(uint256 newHospitalBill) public onlyOwner {
        hospitalBill = newHospitalBill;
        lastCheckIn = block.timestamp;
    }

    function addScenario(
        string memory name,
        uint16 riskBaseDifficulty,
        uint256 payoutAmountBase
    ) public onlyOwner {
        uint256 gameScenarioID = differentGameScenarios;
        gameScenarios[gameScenarioID].name = name;
        gameScenarios[gameScenarioID].riskBaseDifficulty = riskBaseDifficulty;
        gameScenarios[gameScenarioID].payoutAmountBase = payoutAmountBase;
        differentGameScenarios += 1;
    }

    function modifyScenario(
        uint256 scenarioNumber,
        string memory name,
        uint16 riskBaseDifficulty,
        uint16 payoutAmountBase
    ) public onlyOwner {
        gameScenarios[scenarioNumber].riskBaseDifficulty = riskBaseDifficulty; // scenarios can be removed by effectily raising the riskbase difficult level so high no one would bother playing it and making payoutAmountBase 0
        gameScenarios[scenarioNumber].payoutAmountBase = payoutAmountBase;
        gameScenarios[scenarioNumber].name = name;
    }

    function depositNFT(uint256 NFTID) public {
        // users Must Deposit a character to play
        require(
            NFTCharacterDepositLedger[msg.sender].isDeposited != true,
            "Character Already Deposited"
        );
        breakInNFT.transferFrom(msg.sender, address(this), NFTID);
        NFTCharacterDepositLedger[msg.sender].NFTID = NFTID;
        NFTCharacterDepositLedger[msg.sender].isDeposited = true; //
        (
            NFTCharacterDepositLedger[msg.sender].agility,
            NFTCharacterDepositLedger[msg.sender].strength,
            NFTCharacterDepositLedger[msg.sender].charm,
            NFTCharacterDepositLedger[msg.sender].sneak,
            NFTCharacterDepositLedger[msg.sender].health
        ) = IBreakInNFTMinter.getNFTAttributes(
            NFTCharacterDepositLedger[msg.sender].NFTID
        );
    }

    function withdrawNFT() public {
        require(
            NFTCharacterDepositLedger[msg.sender].isDeposited == true,
            "No Character Deposited"
        );
        require(
            NFTCharacterDepositLedger[msg.sender].arrested == false,
            "Character in Prison"
        );
        IBreakInNFTMinter.changeNFTAttributes(
            NFTCharacterDepositLedger[msg.sender].NFTID, // modify attributes of player if experience was gained or health lost
            NFTCharacterDepositLedger[msg.sender].health,
            NFTCharacterDepositLedger[msg.sender].agility,
            NFTCharacterDepositLedger[msg.sender].strength,
            NFTCharacterDepositLedger[msg.sender].sneak,
            NFTCharacterDepositLedger[msg.sender].charm
        );
        breakInNFT.transferFrom(
            address(this),
            msg.sender,
            NFTCharacterDepositLedger[msg.sender].NFTID
        );
        NFTCharacterDepositLedger[msg.sender].isDeposited = false;
    }

    function depositJewels(uint256 amountToDeposit) public {
        require(
            NFTCharacterDepositLedger[msg.sender].arrested == false,
            "Character in Prison"
        );
        socialLegoToken.transferFrom(
            msg.sender,
            address(this),
            amountToDeposit
        );
        jewelDepositLedger[msg.sender] += amountToDeposit;
    }

    function withdrawJewels(uint256 amountToWithdraw) public {
        require(
            jewelDepositLedger[msg.sender] >= amountToWithdraw,
            "Trying to withdraw too much money"
        );
        socialLegoToken.transfer(msg.sender, amountToWithdraw);
        jewelDepositLedger[msg.sender] -= amountToWithdraw;
    }

    function startPlayPVP() public {
        require(
            NFTCharacterDepositLedger[msg.sender].isDeposited == true,
            "Character Not deposited"
        );
        NFTCharacterDepositLedger[msg.sender].playingPVP = true;
        NFTCharacterDepositLedger[msg.sender].canStopPlayingPVP =
            block.timestamp +
            604800; // players must play a minimum 7 days to prevent players entering and exiting quickly;
    }

    function stopPlayPVP() public {
        require(
            block.timestamp >=
                NFTCharacterDepositLedger[msg.sender].canStopPlayingPVP,
            "You must wait 7 days since you started playing"
        );
        NFTCharacterDepositLedger[msg.sender].playingPVP = false;
    }

    function hospitalVisit() public {
        require(
            NFTCharacterDepositLedger[msg.sender].isDeposited == true,
            "Character Not Deposited"
        );
        require(NFTCharacterDepositLedger[msg.sender].health < 100);
        require(jewelDepositLedger[msg.sender] >= (hospitalBill));
        jewelDepositLedger[msg.sender] -= hospitalBill;
        NFTCharacterDepositLedger[msg.sender].health = 100;
    }

    // Please Hire Me ;)
    function playGame(
        uint256 difficultyLevel,
        uint256 breakInStyle,
        uint256 scenario
    ) public returns (bytes32) {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        require(
            NFTCharacterDepositLedger[msg.sender].isDeposited == true,
            "No Character Deposited"
        );
        require(
            NFTCharacterDepositLedger[msg.sender].arrested == false,
            "Character in Prison"
        );
        require(scenario < differentGameScenarios, "No Game Scenario");
        bytes32 requestID = requestRandomness(keyHash, fee);
        currentGameMode[requestID].gameMode = 0;
        currentGamePlays[requestID].player = msg.sender;
        currentGamePlays[requestID].breakInStyle = breakInStyle;
        currentGamePlays[requestID].difficultyLevel = difficultyLevel;
        currentGamePlays[requestID].scenario = scenario;
        currentGamePlays[requestID].agility = NFTCharacterDepositLedger[
            msg.sender
        ].agility;
        currentGamePlays[requestID].strength = NFTCharacterDepositLedger[
            msg.sender
        ].strength;
        currentGamePlays[requestID].charm = NFTCharacterDepositLedger[
            msg.sender
        ].charm;
        currentGamePlays[requestID].sneak = NFTCharacterDepositLedger[
            msg.sender
        ].sneak;
        currentGamePlays[requestID].health = NFTCharacterDepositLedger[
            msg.sender
        ].health;
        return requestID;
    }

    function playBreakOut(uint256 breakInStyle, address targetPlayer)
        public
        returns (bytes32)
    {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        require(
            NFTCharacterDepositLedger[targetPlayer].isDeposited == true,
            "No Target Character Deposited"
        );
        require(
            NFTCharacterDepositLedger[msg.sender].isDeposited == true,
            "You have no Character Deposited"
        );
        require(
            NFTCharacterDepositLedger[targetPlayer].arrested == true,
            "Character is not in Prison"
        );
        require(targetPlayer != msg.sender, "You cannot free yourself");
        bytes32 requestID = requestRandomness(keyHash, fee);
        currentGameMode[requestID].gameMode = 1;
        currentJailBreaks[requestID].player = msg.sender;
        currentJailBreaks[requestID].breakInStyle = breakInStyle;
        currentJailBreaks[requestID].targetPlayer = targetPlayer;
        currentJailBreaks[requestID].agility = NFTCharacterDepositLedger[
            msg.sender
        ].agility;
        currentJailBreaks[requestID].strength = NFTCharacterDepositLedger[
            msg.sender
        ].strength;
        currentJailBreaks[requestID].charm = NFTCharacterDepositLedger[
            msg.sender
        ].charm;
        currentJailBreaks[requestID].sneak = NFTCharacterDepositLedger[
            msg.sender
        ].sneak;
        currentJailBreaks[requestID].health = NFTCharacterDepositLedger[
            msg.sender
        ].health;
        return requestID;
    }

    function playPVP(uint256 breakInStyle, address targetPlayer)
        public
        returns (bytes32)
    {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        require(
            NFTCharacterDepositLedger[targetPlayer].isDeposited == true,
            "No Target Character Deposited"
        );
        require(
            NFTCharacterDepositLedger[msg.sender].isDeposited == true,
            "You have no Character Deposited"
        );
        require(targetPlayer != msg.sender, "You cannot rob from yourself");
        require(
            NFTCharacterDepositLedger[msg.sender].lootingTimeout <
                block.timestamp
        ); // only successfully rob someone once a day
        require(
            NFTCharacterDepositLedger[targetPlayer].lootingTimeout <
                block.timestamp
        ); // only get robbed  once a day
        require(jewelDepositLedger[targetPlayer] > (1 * 10**18)); // require targetPlayer has at least 1 jewel to prevent division issues.
        require(
            jewelDepositLedger[msg.sender] >
                (jewelDepositLedger[targetPlayer] / 2)
        ); // you need to have at least 50% jewels of your target character to prvent small characters constantly attacking
        bytes32 requestID = requestRandomness(keyHash, fee);
        currentGameMode[requestID].gameMode = 2;
        currentPVPGamePlays[requestID].player = msg.sender;
        currentPVPGamePlays[requestID].breakInStyle = breakInStyle;
        currentPVPGamePlays[requestID].targetPlayer = targetPlayer;
        currentPVPGamePlays[requestID].agility = NFTCharacterDepositLedger[
            msg.sender
        ].agility;
        currentPVPGamePlays[requestID].strength = NFTCharacterDepositLedger[
            msg.sender
        ].strength;
        currentPVPGamePlays[requestID].charm = NFTCharacterDepositLedger[
            msg.sender
        ].charm;
        currentPVPGamePlays[requestID].sneak = NFTCharacterDepositLedger[
            msg.sender
        ].sneak;
        currentPVPGamePlays[requestID].health = NFTCharacterDepositLedger[
            msg.sender
        ].health;

        currentPVPGamePlays[requestID]
            .targetPlayerAgility = NFTCharacterDepositLedger[targetPlayer]
            .agility;
        currentPVPGamePlays[requestID]
            .targetPlayerStrength = NFTCharacterDepositLedger[targetPlayer]
            .strength;
        currentPVPGamePlays[requestID]
            .targetPlayerCharm = NFTCharacterDepositLedger[targetPlayer].charm;
        currentPVPGamePlays[requestID]
            .targetPlayerSneak = NFTCharacterDepositLedger[targetPlayer].sneak;
        currentPVPGamePlays[requestID]
            .targetPlayerHealth = NFTCharacterDepositLedger[targetPlayer]
            .health;

        return requestID;
    }

    function vrfPlayGame(uint256 randomness, bytes32 requestId) internal {
        // only when randomness is returned can this function be called.
        if ((randomness % 2000) == 1) {
            // 1 in 2000 chance character dies
            NFTCharacterDepositLedger[currentGamePlays[requestId].player]
                .isDeposited = false;
            emit gameCode(requestId, currentGamePlays[requestId].player, 0);
            return;
        }

        if (((randomness % 143456) % 20) == 1) {
            // 1 in 20 chance character is injured
            uint256 healthDecrease = ((randomness % 123456) % 99); // player can lose up to 99 health every 1 in 20
            if (
                (100 - currentGamePlays[requestId].health + healthDecrease) >
                100
            ) {
                // players don't have to heal if they get injured before but if they get injured again and its greater than 100, they die
                NFTCharacterDepositLedger[currentGamePlays[requestId].player]
                    .isDeposited = false;
                emit gameCode(requestId, currentGamePlays[requestId].player, 0);
                return;
            }
            NFTCharacterDepositLedger[currentGamePlays[requestId].player]
                .health -= healthDecrease;
            emit gameCode(requestId, currentGamePlays[requestId].player, 1);
            return;
        }
        if (((randomness % 23015) % 20) == 1) {
            // 1 in 20 chance character is almost getting arrested
            uint256 agilityRequiredtoEscape = ((randomness % 54321) % 1000); // player still has chance to escape
            if (currentGamePlays[requestId].agility > agilityRequiredtoEscape) {
                if (((randomness % 2214) % 2) == 1) {
                    // gain XP!
                    NFTCharacterDepositLedger[
                        currentGamePlays[requestId].player
                    ].agility += 1;
                }
                emit gameCode(requestId, currentGamePlays[requestId].player, 3);
                return; // escaped but no money given
            } else {
                NFTCharacterDepositLedger[currentGamePlays[requestId].player]
                    .arrested = true;
                NFTCharacterDepositLedger[currentGamePlays[requestId].player]
                    .freetoPlayAgain = block.timestamp + 172800; //player arrested for 2 days.
                emit gameCode(requestId, currentGamePlays[requestId].player, 2);
                return; //  playerArrested
            }
        }
        if (currentGamePlays[requestId].breakInStyle == 0) {
            //player is sneaking in
            uint256 sneakInExperienceRequired = ((randomness % 235674) % 750) +
                currentGamePlays[requestId].difficultyLevel +
                gameScenarios[currentGamePlays[requestId].scenario]
                    .riskBaseDifficulty; // difficulty will be somewhere between 0 to 10000 pluse the difficulty level which will be about 100 to 950
            if (currentGamePlays[requestId].sneak > sneakInExperienceRequired) {
                uint256 totalWon = currentGamePlays[requestId].difficultyLevel *
                    gameScenarios[currentGamePlays[requestId].scenario]
                        .payoutAmountBase;
                jewelDepositLedger[
                    currentGamePlays[requestId].player
                ] += totalWon;
                if (((randomness % 2214) % 2) == 1) {
                    // gain XP!
                    NFTCharacterDepositLedger[
                        currentGamePlays[requestId].player
                    ].sneak += 1;
                }
                emit gameCode(
                    requestId,
                    currentGamePlays[requestId].player,
                    totalWon
                );
                return;
            }
            emit gameCode(requestId, currentGamePlays[requestId].player, 4);
            return;
        }
        if (currentGamePlays[requestId].breakInStyle == 1) {
            // player is breaking in with charm
            uint256 charmInExperienceRequired = ((randomness % 453678) % 750) +
                currentGamePlays[requestId].difficultyLevel +
                gameScenarios[currentGamePlays[requestId].scenario]
                    .riskBaseDifficulty;
            if (currentGamePlays[requestId].charm > charmInExperienceRequired) {
                uint256 totalWon = currentGamePlays[requestId].difficultyLevel *
                    gameScenarios[currentGamePlays[requestId].scenario]
                        .payoutAmountBase;
                jewelDepositLedger[
                    currentGamePlays[requestId].player
                ] += totalWon;
                if (((randomness % 2214) % 2) == 1) {
                    // gain XP!
                    NFTCharacterDepositLedger[
                        currentGamePlays[requestId].player
                    ].charm += 1;
                }
                emit gameCode(
                    requestId,
                    currentGamePlays[requestId].player,
                    totalWon
                );
                return;
            }
            emit gameCode(requestId, currentGamePlays[requestId].player, 4);
            return;
        }
        if (currentGamePlays[requestId].breakInStyle == 2) {
            // player is breaking in with strength
            uint256 strengthInExperienceRequired = ((randomness % 786435) %
                750) +
                currentGamePlays[requestId].difficultyLevel +
                gameScenarios[currentGamePlays[requestId].scenario]
                    .riskBaseDifficulty; // strength is used for daylight robbery
            if (
                currentGamePlays[requestId].strength >
                strengthInExperienceRequired
            ) {
                uint256 totalWon = currentGamePlays[requestId].difficultyLevel *
                    gameScenarios[currentGamePlays[requestId].scenario]
                        .payoutAmountBase;
                jewelDepositLedger[
                    currentGamePlays[requestId].player
                ] += totalWon;
                if (((randomness % 2214) % 2) == 1) {
                    // gain XP!
                    NFTCharacterDepositLedger[
                        currentGamePlays[requestId].player
                    ].strength += 1;
                }
                emit gameCode(
                    requestId,
                    currentGamePlays[requestId].player,
                    totalWon
                );
                return;
            }
            emit gameCode(requestId, currentGamePlays[requestId].player, 4);
            return;
        }
    }

    function vrfJailBreak(uint256 randomness, bytes32 requestId) internal {
        // only when randomness is returned can this function be called.
        if ((randomness % 1000) == 1) {
            // 5x higher chance of dying because its a jail
            // 1 in 1000 chance character dies
            NFTCharacterDepositLedger[currentJailBreaks[requestId].player]
                .isDeposited = false; //
            emit gameCode(requestId, currentJailBreaks[requestId].player, 0);
            return;
        }

        if (((randomness % 143456) % 10) == 1) {
            //2x higher chance of getting injured
            // 1 in 100 chance character is injured
            uint256 healthDecrease = ((randomness % 123456) % 99); // player can lose up to 99 health every 1 in 100
            if (
                (100 - currentJailBreaks[requestId].health + healthDecrease) >
                100
            ) {
                // players don't have to heal if they get injured before but if they get injured again and its greater than 100, they die
                NFTCharacterDepositLedger[msg.sender].isDeposited = false; //
                emit gameCode(
                    requestId,
                    currentJailBreaks[requestId].player,
                    0
                );
                return;
            }
            NFTCharacterDepositLedger[currentJailBreaks[requestId].player]
                .health -= healthDecrease;
            emit gameCode(requestId, currentJailBreaks[requestId].player, 1);
            return;
        }
        if (((randomness % 23015) % 5) == 1) {
            // really high chance of getting spotted
            // 1 in 5 chance character is almost getting arrested
            uint256 agilityRequiredtoEscape = ((randomness % 54321) % 1000); // player still has chance to escape
            if (
                currentJailBreaks[requestId].agility > agilityRequiredtoEscape
            ) {
                if (((randomness % 2214) % 2) == 1) {
                    // gain XP!
                    NFTCharacterDepositLedger[
                        currentJailBreaks[requestId].player
                    ].agility += 1;
                }
                emit gameCode(
                    requestId,
                    currentJailBreaks[requestId].player,
                    3
                );
                return; // escaped but no money given
            } else {
                NFTCharacterDepositLedger[msg.sender].arrested = true;
                NFTCharacterDepositLedger[msg.sender].freetoPlayAgain =
                    block.timestamp +
                    259200; //player arrested for 3 days.
                emit gameCode(
                    requestId,
                    currentJailBreaks[requestId].player,
                    2
                );
                return; //  playerArrested
            }
        }
        if (currentJailBreaks[requestId].breakInStyle == 0) {
            //player is sneaking in
            uint256 sneakInExperienceRequired = ((randomness % 235674) % 1000); // difficulty will be somewhere between 0 to 10000
            if (
                currentJailBreaks[requestId].sneak > sneakInExperienceRequired
            ) {
                NFTCharacterDepositLedger[
                    currentJailBreaks[requestId].targetPlayer
                ].arrested = false;
                if (((randomness % 2214) % 2) == 1) {
                    // gain XP!
                    NFTCharacterDepositLedger[
                        currentJailBreaks[requestId].player
                    ].sneak += 1;
                }
                emit gameCode(
                    requestId,
                    currentJailBreaks[requestId].targetPlayer,
                    5
                );
                return;
            }
            emit gameCode(requestId, currentJailBreaks[requestId].player, 4);
            return;
        }
        if (currentJailBreaks[requestId].breakInStyle == 1) {
            // player is breaking in with charm
            uint256 charmInExperienceRequired = ((randomness % 453678) % 1000);
            if (
                currentJailBreaks[requestId].charm > charmInExperienceRequired
            ) {
                NFTCharacterDepositLedger[
                    currentJailBreaks[requestId].targetPlayer
                ].arrested = false;
                if (((randomness % 2214) % 2) == 1) {
                    // gain XP!
                    NFTCharacterDepositLedger[
                        currentJailBreaks[requestId].player
                    ].charm += 1;
                }
                emit gameCode(
                    requestId,
                    currentJailBreaks[requestId].targetPlayer,
                    5
                );
                return;
            }
            emit gameCode(requestId, currentJailBreaks[requestId].player, 4);
            return;
        }
        if (currentJailBreaks[requestId].breakInStyle == 2) {
            // player is breaking in with strength
            uint256 strengthInExperienceRequired = ((randomness % 786435) %
                1000);
            if (
                currentJailBreaks[requestId].strength >
                strengthInExperienceRequired
            ) {
                NFTCharacterDepositLedger[
                    currentJailBreaks[requestId].targetPlayer
                ].arrested = false;
                if (((randomness % 2214) % 4) == 1) {
                    // gain XP!
                    NFTCharacterDepositLedger[
                        currentJailBreaks[requestId].player
                    ].strength += 1;
                }
                emit gameCode(
                    requestId,
                    currentJailBreaks[requestId].targetPlayer,
                    5
                );
                return;
            }
            emit gameCode(requestId, currentJailBreaks[requestId].player, 4);
            return;
        }
    }

    function vrfPlayPVP(uint256 randomness, bytes32 requestId) internal {
        // only when randomness is returned can this function be called.
        if ((randomness % 100) == 1) {
            //  really high chance of getting killed
            // 1 in 100 chance character dies
            NFTCharacterDepositLedger[currentPVPGamePlays[requestId].player]
                .isDeposited = false; //
            emit gameCode(requestId, currentPVPGamePlays[requestId].player, 0);
            return;
        }

        if (((randomness % 143456) % 11) == 3) {
            //really high chance of getting injured
            // 1 in 11 chance character is injured
            uint256 healthDecrease = ((randomness % 123456) % 99); // player can lose up to 99 health every 1 in 100
            if (
                (100 - currentPVPGamePlays[requestId].health + healthDecrease) >
                100
            ) {
                // players don't have to heal if they get injured before but if they get injured again and its greater than 100, they die
                NFTCharacterDepositLedger[msg.sender].isDeposited = false; //
                emit gameCode(
                    requestId,
                    currentPVPGamePlays[requestId].player,
                    0
                );
                return;
            }
            NFTCharacterDepositLedger[currentPVPGamePlays[requestId].player]
                .health -= healthDecrease;
            emit gameCode(requestId, currentPVPGamePlays[requestId].player, 1);
            return;
        }
        // no chance of getting arrested since you are a robbing another player
        // There is nothing stopping players with 800 sneak targeting players with 300 sneak.
        // It is assumed that the 800 sneak character will be more vulnerbale to strength attacks.
        // Players have to decide if they want to play more defensivly by equally levelling up each trait
        // or focus on one specfic trait which allows them to attack better but have worse defense.
        // Oh and please hire me.
        if (currentPVPGamePlays[requestId].breakInStyle == 0) {
            //player is sneaking in
            uint256 sneakInExperienceRequired = ((randomness % 235674) % 1000) +
                currentPVPGamePlays[requestId].targetPlayerSneak; // difficulty will be somewhere between 0 to 10000 plus the difficulty level which will be about 100 to 950
            if (
                currentPVPGamePlays[requestId].sneak > sneakInExperienceRequired
            ) {
                uint256 totalWon = jewelDepositLedger[
                    currentPVPGamePlays[requestId].targetPlayer
                ] / 20; // player can only lose 5% max each day
                if (((randomness % 2214) % 2) == 1) {
                    // gain XP!
                    NFTCharacterDepositLedger[
                        currentPVPGamePlays[requestId].player
                    ].sneak += 1;
                }
                jewelDepositLedger[
                    currentPVPGamePlays[requestId].targetPlayer
                ] -= totalWon;
                jewelDepositLedger[
                    currentPVPGamePlays[requestId].player
                ] += totalWon;
                NFTCharacterDepositLedger[currentPVPGamePlays[requestId].player]
                    .lootingTimeout = block.timestamp + 86400; // players can only loot once a day
                NFTCharacterDepositLedger[
                    currentPVPGamePlays[requestId].targetPlayer
                ].lootingTimeout = block.timestamp + 86400; // players can only get looted once a day
                emit gameCode(
                    requestId,
                    currentPVPGamePlays[requestId].player,
                    totalWon
                );
                return;
            }
            emit gameCode(requestId, currentPVPGamePlays[requestId].player, 4);
            return;
        }
        if (currentPVPGamePlays[requestId].breakInStyle == 1) {
            // player is breaking in with charm
            uint256 charmInExperienceRequired = ((randomness % 453678) % 1000) +
                currentPVPGamePlays[requestId].targetPlayerCharm;
            if (
                currentPVPGamePlays[requestId].charm > charmInExperienceRequired
            ) {
                uint256 totalWon = jewelDepositLedger[
                    currentPVPGamePlays[requestId].targetPlayer
                ] / 20;
                if (((randomness % 2214) % 2) == 1) {
                    // gain XP!
                    NFTCharacterDepositLedger[
                        currentPVPGamePlays[requestId].player
                    ].charm += 1;
                }
                jewelDepositLedger[
                    currentPVPGamePlays[requestId].player
                ] += totalWon;
                NFTCharacterDepositLedger[currentPVPGamePlays[requestId].player]
                    .lootingTimeout = block.timestamp + 86400; // players can only loot once a day
                NFTCharacterDepositLedger[
                    currentPVPGamePlays[requestId].targetPlayer
                ].lootingTimeout = block.timestamp + 86400; // players can only get looted once a day
                emit gameCode(
                    requestId,
                    currentPVPGamePlays[requestId].player,
                    totalWon
                );
                return;
            }
            emit gameCode(requestId, currentPVPGamePlays[requestId].player, 4);
            return;
        }
        if (currentPVPGamePlays[requestId].breakInStyle == 2) {
            // player is breaking in with strength
            uint256 strengthInExperienceRequired = ((randomness % 786435) %
                1000) + currentPVPGamePlays[requestId].targetPlayerStrength; // strength is used for daylight robbery
            if (
                currentPVPGamePlays[requestId].strength >
                strengthInExperienceRequired
            ) {
                uint256 totalWon = jewelDepositLedger[
                    currentPVPGamePlays[requestId].targetPlayer
                ] / 20; // player can only lose 5% max each day
                if (((randomness % 2214) % 2) == 1) {
                    // gain XP!
                    NFTCharacterDepositLedger[
                        currentPVPGamePlays[requestId].player
                    ].strength += 1;
                }
                jewelDepositLedger[
                    currentPVPGamePlays[requestId].targetPlayer
                ] -= totalWon;
                jewelDepositLedger[
                    currentPVPGamePlays[requestId].player
                ] += totalWon;
                NFTCharacterDepositLedger[currentPVPGamePlays[requestId].player]
                    .lootingTimeout = block.timestamp + 86400; // players can only loot once a day
                NFTCharacterDepositLedger[
                    currentPVPGamePlays[requestId].targetPlayer
                ].lootingTimeout = block.timestamp + 86400; // players can only get looted once a day
                emit gameCode(
                    requestId,
                    currentPVPGamePlays[requestId].player,
                    totalWon
                );
                return;
            }
            emit gameCode(requestId, currentPVPGamePlays[requestId].player, 4);
            return;
        }
    }

    function getRandomNumber() internal returns (bytes32 requestId) {
        // internal
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        return requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        if (currentGameMode[requestId].gameMode == 0) {
            vrfPlayGame(randomness, requestId);
        }
        if (currentGameMode[requestId].gameMode == 1) {
            vrfJailBreak(randomness, requestId);
        }
        if (currentGameMode[requestId].gameMode == 2) {
            vrfPlayPVP(randomness, requestId);
        }
    }

    function changeInheritance(address newInheritor) public onlyOwner {
        nextOwner = newInheritor;
    }

    function ownerCheckIn() public onlyOwner {
        lastCheckIn = block.timestamp;
    }

    function changeCheckInTime(uint256 newCheckInTimeInterval)
        public
        onlyOwner
    {
        checkInTimeInterval = newCheckInTimeInterval; // let owner change check in case he know he will be away for a while.
    }

    function passDownInheritance() internal {
        transferOwnership(nextOwner);
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        return (
            block.timestamp > (lastCheckIn + checkInTimeInterval),
            bytes("")
        ); // make sure to check in at least once every 6 months
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override onlyKeeper {
        passDownInheritance();
    }

    function withdraw(uint256 amount) public onlyOwner returns (bool) {
        require(amount <= address(this).balance);
        payable(msg.sender).transfer(amount); //if the owner send to sender
        return true;
    }

    function withdrawErc20(IERC20 token) public onlyOwner {
        require(
            token.transfer(msg.sender, token.balanceOf(address(this))),
            "Transfer failed"
        );
    }

    receive() external payable {
        // nothing to do but accept money
    }
}