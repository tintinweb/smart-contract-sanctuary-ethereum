// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./MerkleProofLib.sol";

interface IWorm {
  function isDisciple(address _address) external view returns (bool);
}

contract MechFlashPact {
  uint256 constant public DEPOSIT = 0.01 ether;
  uint256 immutable public MAX_JOIN_DEADLINE; 

  address constant private EDWONE = 0xf65D6475869F61c6dce6aC194B6a7dbE45a91c63;
  address constant private MECH = 0xB1763F78e6116228326256292BeBF37aB762cE52;
  address immutable private DEPLOYER;
  address immutable private PACT_LEADER;

  uint256 public joinDeadline;

  mapping(address => uint256) private active;
  bytes32 private merkleRoot;
  address[] private pactMembers;

  constructor(
    address pactLeader,
    bytes32 root,
    uint256 initJoinDeadline
  ) {
    DEPLOYER = msg.sender;
    MAX_JOIN_DEADLINE = block.timestamp + 5 days;
    PACT_LEADER = pactLeader;
    merkleRoot = root;
    joinDeadline = initJoinDeadline;
    pactMembers.push(pactLeader);
  }

  function executePact(address endOfPact) external {
    _onlyPactLeaderOrDeployer();
    require(joinDeadline < block.timestamp && block.timestamp <= _fulfillmentDeadline());

    pactMembers.push(endOfPact);
    uint256 length = pactMembers.length;

    uint256 last;
    uint256 next = 1;
    while (next <= length - 1) {
      if (next == length - 1 || _pactReady(pactMembers[next])) {
        IERC721(MECH).transferFrom(pactMembers[last], pactMembers[next], 0);
        last = next;
        ++next;
      } else {
        ++next;
      }
    }

    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success);
  }

  function joinPact(bytes32[] calldata merkleProof) external payable {
    require(_pactReady(msg.sender));
    require(block.timestamp <= joinDeadline);
    require(msg.value >= DEPOSIT);
    require(active[msg.sender] == 0);
    require(!IWorm(EDWONE).isDisciple(msg.sender));
    require(MerkleProofLib.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))));

    active[msg.sender] = 1;
    pactMembers.push(msg.sender);
  }

  function extendJoinDeadline(uint256 newDeadline) external {
    _onlyPactLeaderOrDeployer();
    require(
      block.timestamp < joinDeadline &&
      joinDeadline < newDeadline &&
      newDeadline < MAX_JOIN_DEADLINE
    );
    joinDeadline = newDeadline;
  }

  function updateMerkleRoot(bytes32 newRoot) external {
    _onlyPactLeaderOrDeployer();
    merkleRoot = newRoot;
  }

  function withdraw() external {
    require(block.timestamp > _fulfillmentDeadline());
    require(active[msg.sender] > 0);

    active[msg.sender] = 0;
    (bool success, ) = msg.sender.call{value: DEPOSIT}("");
    require(success);
  }

  function _fulfillmentDeadline() private view returns (uint256) {
    return joinDeadline + 24 hours;
  }

  function _onlyPactLeaderOrDeployer() private view {
    require(msg.sender == PACT_LEADER || msg.sender == DEPLOYER);
  }

  function _pactReady(address target) private view returns (bool) {
    return IERC721(MECH).isApprovedForAll(target, address(this));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Gas optimized merkle proof verification library.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/MerkleProofLib.sol)
/// @author Modified from Solady (https://github.com/Vectorized/solady/blob/main/src/utils/MerkleProofLib.sol)
library MerkleProofLib {
    function verify(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool isValid) {
        /// @solidity memory-safe-assembly
        assembly {
            if proof.length {
                // Left shifting by 5 is like multiplying by 32.
                let end := add(proof.offset, shl(5, proof.length))

                // Initialize offset to the offset of the proof in calldata.
                let offset := proof.offset

                // Iterate over proof elements to compute root hash.
                // prettier-ignore
                for {} 1 {} {
                    // Slot where the leaf should be put in scratch space. If
                    // leaf > calldataload(offset): slot 32, otherwise: slot 0.
                    let leafSlot := shl(5, gt(leaf, calldataload(offset)))

                    // Store elements to hash contiguously in scratch space.
                    // The xor puts calldataload(offset) in whichever slot leaf
                    // is not occupying, so 0 if leafSlot is 32, and 32 otherwise.
                    mstore(leafSlot, leaf)
                    mstore(xor(leafSlot, 32), calldataload(offset))

                    // Reuse leaf to store the hash to reduce stack operations.
                    leaf := keccak256(0, 64) // Hash both slots of scratch space.

                    offset := add(offset, 32) // Shift 1 word per cycle.

                    // prettier-ignore
                    if iszero(lt(offset, end)) { break }
                }
            }

            isValid := eq(leaf, root) // The proof is valid if the roots match.
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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