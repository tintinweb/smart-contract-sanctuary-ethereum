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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract MetawinRaffle is IERC721Receiver, VRFConsumerBase {
    using SafeMath for uint256;

    enum RaffleStatus {
        ONGOING,
        PENDING_COMPLETION,
        COMPLETE
    }

    //NFT raffle struct
    struct NftRaffle {
        address creator;
        address nftContractAddress;
        uint256 nftId;
        uint256 ticketPrice;
        uint256 totalPrice;
        uint256 maxEntries;
        uint256 period;
        address[] tickets;
        int256 winnerIndex;
        uint256 createdAt;
        RaffleStatus status;
    }

    //Eth Raffle struct
    struct EthRaffle {
        address creator;
        uint256 rewardEth;
        uint256 ticketPrice;
        uint256 totalPrice;
        uint256 maxEntries;
        uint256 period;
        address[] tickets;
        int256 winnerIndex;
        uint256 createdAt;
        RaffleStatus status;
    }

    //Contract owner address
    address public owner;
    //NFT Raffles
    NftRaffle[] public nftRaffles;
    //Eth Raffles
    EthRaffle[] public ethRaffles;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    //params for chainlink VRF
    //keyhash can be 0xced103054e349b8dfb51352f0f8fa9b5d20dde3d06f9f43cb2b85bc64b238205
    //fee can be 0.1 * 10 ** 18
    bytes32 internal keyHash;
    uint256 internal fee;

    //map VRF request to raffle
    mapping(bytes32 => uint256) internal randomnessRequestToNftRaffle;
    mapping(bytes32 => uint256) internal randomnessRequestToEthRaffle;

    constructor(
        address _vrfCoordinator,
        address _linkToken,
        uint256 _fee,
        bytes32 _keyHash
    ) VRFConsumerBase(_vrfCoordinator, _linkToken) {
        owner = msg.sender;
        keyHash = _keyHash;
        fee = _fee;
    }

    //Create a new NFT raffle
    //nftContract.approve should be called before this function
    function createNftRaffle(
        IERC721 _nftContract,
        uint256 _nftId,
        uint256 _ticketPrice,
        uint256 _numTickets,
        uint256 _rafflePeriod
    ) onlyOwner public {
        _nftContract.approve(address(this), _nftId);

        //transfer the NFT from the raffle creator to this contract
        _nftContract.safeTransferFrom(
            msg.sender,
            address(this),
            _nftId,
            abi.encode(_ticketPrice, _numTickets, _rafflePeriod)
        );
    }

    //Complete raffle creation when receiving ERC721
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes memory data
    ) public override returns (bytes4) {
        (uint256 _ticketPrice, uint256 _numTickets, uint256 _rafflePeriod) = abi.decode(
            data,
            (uint256, uint256, uint256)
        );

        //init tickets
        address[] memory _tickets;
        //create raffle
        NftRaffle memory _raffle = NftRaffle(
            tx.origin,
            msg.sender,
            _tokenId,
            _ticketPrice,
            0,
            _numTickets,
            _rafflePeriod,
            _tickets,
            -1,
            block.timestamp,
            RaffleStatus.ONGOING
        );

        //store raffel in state
        nftRaffles.push(_raffle);

        //emit event
        emit NftRaffleCreated(nftRaffles.length - 1, tx.origin);

        //return function signature to confirm safe transfer
        return bytes4(keccak256("onERC721Received(address, address, uint256, bytes)"));
    }

    //Cancel NFT Raffle
    function cancelNftRaffle(
        IERC721 _nftContract,
        uint256 _nftId
    ) onlyOwner public {
        //transfer the NFT from the contract to the raffle creator
        _nftContract.safeTransferFrom(
            address(this),
            msg.sender,
            _nftId
        );
    }

    //Create a new Eth Raffle
    function createEthRaffle(
        uint256 _rewardEth,
        uint256 _ticketPrice,
        uint256 _numTickets,
        uint256 _rafflePeriod
    ) onlyOwner public payable{
        require(msg.value == _rewardEth, "Reward Eth is not enough!");

        address[] memory _tickets;

        EthRaffle memory _raffle = EthRaffle(
            msg.sender,
            _rewardEth,
            _ticketPrice,
            0,
            _numTickets,
            _rafflePeriod,
            _tickets,
            -1,
            block.timestamp,
            RaffleStatus.ONGOING
        );

        ethRaffles.push(_raffle);

        emit EthRaffleCreated(ethRaffles.length - 1, msg.sender);
    }

    //Cancel Eth raffle
    function cancelEthRaffle(uint256 _raffleId) onlyOwner public {
        (bool sent, bytes memory data) = ethRaffles[_raffleId].creator.call{value: ethRaffles[_raffleId].rewardEth}("");
            require(sent, "Failed to send Ether");
    }

    //enter a user in the draw for a given NFT raffle
    function enterNftRaffle(uint256 _raffleId, uint256 _tickets) public payable {
        require(
            uint256(nftRaffles[_raffleId].status) == uint256(RaffleStatus.ONGOING),
            "NFT Raffle no longer active"
        );

        require(block.timestamp < (nftRaffles[_raffleId].createdAt + nftRaffles[_raffleId].period), "Raffle period is over");

        require(
            _tickets.add(nftRaffles[_raffleId].tickets.length) <= nftRaffles[_raffleId].maxEntries,
            "Not enough tickets available"
        );

        require(_tickets > 0, "Not enough _tickets purchased");

        if(_tickets == 1) {
            require(msg.value == nftRaffles[_raffleId].ticketPrice, "Ticket price not paid");
        } else if(_tickets == 15) {
            require(msg.value == 0.12 ether, "Ticket price not paid");
        } else if(_tickets == 35) {
            require(msg.value == 0.24 ether, "Ticket price not paid");
        } else if(_tickets == 75) {
            require(msg.value == 0.48 ether, "Ticket price not paid");
        } else if(_tickets == 155) {
            require(msg.value == 0.96 ether, "Ticket price not paid");
        } else {
            require(msg.value == _tickets.mul(nftRaffles[_raffleId].ticketPrice), "Ticket price not paid");
        }

        //add _tickets
        for (uint256 i = 0; i < _tickets; i++) {
            nftRaffles[_raffleId].tickets.push(payable(msg.sender));
        }

        nftRaffles[_raffleId].totalPrice += msg.value;
        
        emit NftTicketPurchased(_raffleId, msg.sender, _tickets);

        //award prizes if this was the last ticket purchased
        if(
            nftRaffles[_raffleId].tickets.length == nftRaffles[_raffleId].maxEntries
        ) {
            nftRaffles[_raffleId].status = RaffleStatus.PENDING_COMPLETION;
            chooseNftWinner(_raffleId);
        }
    }

    //enter a user in the draw for a given ETH raffle
    function enterEthRaffle(uint256 _raffleId, uint256 _tickets) public payable {
        require(
            uint256(ethRaffles[_raffleId].status) == uint256(RaffleStatus.ONGOING),
            "NFT Raffle no longer active"
        );

        require(
            _tickets.add(ethRaffles[_raffleId].tickets.length) <= ethRaffles[_raffleId].maxEntries,
            "Not enough tickets available"
        );
        
        require(_tickets > 0, "Not enough _tickets purchased");

        if(ethRaffles[_raffleId].period != 0) {
            require(block.timestamp < (ethRaffles[_raffleId].createdAt + ethRaffles[_raffleId].period), "Raffle period is over");

            if(_tickets == 1) {
                require(msg.value == ethRaffles[_raffleId].ticketPrice, "Ticket price not paid");
            } else if(_tickets == 15) {
                require(msg.value == 0.095 ether, "Ticket price not paid");
            } else if(_tickets == 35) {
                require(msg.value == 0.19 ether, "Ticket price not paid");
            } else if(_tickets == 75) {
                require(msg.value == 0.38 ether, "Ticket price not paid");
            } else if(_tickets == 155) {
                require(msg.value == 0.76 ether, "Ticket price not paid");
            } else {
                require(msg.value == _tickets.mul(nftRaffles[_raffleId].ticketPrice), "Ticket price not paid");
            }
        }
        
        for (uint256 i = 0; i < _tickets; i++) {
            ethRaffles[_raffleId].tickets.push(payable(msg.sender));
        }

        ethRaffles[_raffleId].totalPrice += msg.value;

        emit EthTicketPurchased(_raffleId, msg.sender, _tickets);
        
        if(
            ethRaffles[_raffleId].tickets.length == ethRaffles[_raffleId].maxEntries
        ) {
            ethRaffles[_raffleId].status = RaffleStatus.PENDING_COMPLETION;
            chooseEthWinner(_raffleId);
        }
    }

    function chooseNftWinner(uint256 _raffleId) public {
        require(block.timestamp >= (nftRaffles[_raffleId].createdAt + nftRaffles[_raffleId].period), "Raffle is not ended yet");
        require(nftRaffles[_raffleId].winnerIndex == -1, "Winner is already chosen");

        //Request a random number from Chainlink
        require(
            LINK.balanceOf(address(this)) > fee,
            "Not enough LINK - top up to contract complete raffle"
        );

        // uint256 seed = uint256(keccak256(abi.encode(_raffleId, blockhash(block.number))));
        bytes32 requestId = requestRandomness(keyHash, fee);
        randomnessRequestToNftRaffle[requestId] = _raffleId;
    }

    function chooseEthWinner(uint256 _raffleId) public {
        require(block.timestamp >= (ethRaffles[_raffleId].createdAt + ethRaffles[_raffleId].period), "Raffle is not ended yet");
        require(ethRaffles[_raffleId].winnerIndex == -1, "Winner is already chosen");

        //Request a random number from Chainlink
        require(
            LINK.balanceOf(address(this)) > fee,
            "Not enough LINK - top up to contract complete raffle"
        );

        bytes32 requestId = requestRandomness(keyHash, fee);
        randomnessRequestToEthRaffle[requestId] = _raffleId;
    }

    //This function needs to use <200k otherwise it will revert!
    //(award winner)
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override {
        if ( randomnessRequestToNftRaffle[_requestId] != 0) {
            NftRaffle memory raffle = nftRaffles[randomnessRequestToNftRaffle[_requestId]];
          
            // map randomness to value between 0 and raffle.tickets.length
            // (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
            uint256 winnerIndex = ((_randomness - 0) * (raffle.tickets.length - 0)) / (2**256 - 1 - 0) + 0;

            //Input winnerIndex to raffle struct
            raffle.winnerIndex = int256(winnerIndex);

            //award winner
            IERC721(raffle.nftContractAddress).transferFrom(
                address(this),
                raffle.tickets[winnerIndex],
                raffle.nftId
            );

            //pay raffle creator
            (bool sent, bytes memory data) = raffle.creator.call{value: (raffle.totalPrice)}("");
            require(sent, "Failed to send Ether");

            nftRaffles[randomnessRequestToNftRaffle[_requestId]].status = RaffleStatus.COMPLETE;

            emit NftRaffleCompleted(
                randomnessRequestToNftRaffle[_requestId],
                raffle.tickets[winnerIndex]
            );
        } else {
            EthRaffle memory raffle = ethRaffles[randomnessRequestToEthRaffle[_requestId]];

            uint256 winnerIndex = ((_randomness - 0) * (raffle.tickets.length - 0)) / (2**256 - 1 - 0) + 0;
            raffle.winnerIndex = int256(winnerIndex);

            (bool sent, bytes memory data) = raffle.tickets[winnerIndex].call{value: raffle.rewardEth}("");
            require(sent, "Failed to send Ether");

            if(raffle.totalPrice > raffle.rewardEth) {
                (bool rewardSent, bytes memory rewardData) = raffle.creator.call{value: (raffle.totalPrice - raffle.rewardEth)}("");
                require(rewardSent, "Failed to send Ether");
            }
        }
    }

    //allows us to claim back our link if we need to
    function withdrawLink() public {
        require(msg.sender == owner);
        require(
            LINK.transfer(msg.sender, LINK.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    event NftRaffleCreated(uint256 id, address creator);
    event NftTicketPurchased(uint256 raffleId, address buyer, uint256 numTickets);
    event NftRaffleCompleted(uint256 id, address winner);

    event EthRaffleCreated(uint256 id, address creator);
    event EthTicketPurchased(uint256 raffleId, address buyer, uint256 numTickets);
    event EthRaffleCompleted(uint256 id, address winner);
}