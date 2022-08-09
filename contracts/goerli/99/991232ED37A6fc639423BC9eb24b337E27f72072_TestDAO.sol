// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract TestDAO is Ownable {
  using Counters for Counters.Counter;
  Counters.Counter private proposalCount;

  address public nftContract;
  mapping(uint256 => Proposal) public proposals;
  mapping(uint256 => Votes) public totalVotes;
  mapping(uint256 => mapping(address => uint256)) public voteEntries;

  modifier onlyHolders(address _holder) {
    require(IERC721(nftContract).balanceOf(_holder) > 0, "signer does not have any entry.");
    _;
  }
  modifier validProposal(uint256 _proposal) {
    require(proposals[_proposal].proposalId.length > 0, "proposal not exist");
    require(proposals[_proposal].isActive, "proposal ended");
    _;
  }

  event NewProposal(
    uint256 proposalNo,
    bytes proposalId,
    uint256 minReputation
  );
  event Upvote(
    address voter,
    uint256 proposalNo,
    uint256 voteCount
  );
  event Downvote(
    address voter,
    uint256 proposalNo,
    uint256 voteCount
  );
  event ProposalResult(
    uint256 proposalNo,
    uint256 finalReputation,
    bool isMajority
  );
  
  struct Proposal {
    bytes proposalId;
    uint256 minReputations;
    bool isActive;
    bool isMajority;
  }
  struct Votes {
    uint256 upvotes;
    uint256 downvotes;
  }

  constructor(address _nftContract) {
    nftContract = _nftContract;
  }

  function propose(bytes memory _proposalId, uint256 _minReputation) external onlyOwner {
    require(_minReputation > 0, "min reputation cannot be 0");

    Proposal memory newPrososal = Proposal(_proposalId, _minReputation, true, false);
    proposalCount.increment();
    proposals[proposalCount.current()] = newPrososal;

    emit NewProposal(proposalCount.current(), _proposalId, _minReputation);
  }

  function upvote(uint256 _proposalNo, uint256 _count) 
    external 
    onlyHolders(msg.sender) 
    validProposal(_proposalNo) 
  {
    require(_count > 0, "voting count cannot be zero");
    require(_checkAvailability(msg.sender, _proposalNo, _count), "voting count exceed allowance");

    voteEntries[_proposalNo][msg.sender] += _count;
    totalVotes[_proposalNo].upvotes += _count;

    emit Upvote(msg.sender, _proposalNo, _count);
  }

  function downvote(uint256 _proposalNo, uint256 _count) 
    external 
    onlyHolders(msg.sender) 
    validProposal(_proposalNo) 
  {
    require(_count > 0, "voting count cannot be zero");
    require(_checkAvailability(msg.sender, _proposalNo, _count), "voting count exceed allowance");

    voteEntries[_proposalNo][msg.sender] += _count;
    totalVotes[_proposalNo].downvotes += _count;

    emit Downvote(msg.sender, _proposalNo, _count);
  }

  function endProposal(uint256 _proposalNo) external onlyOwner validProposal(_proposalNo) {
    uint256 total = totalVotes[_proposalNo].upvotes + totalVotes[_proposalNo].downvotes;

    proposals[_proposalNo].isActive = false;

    uint256 currentReputation = 0;
    if (total != 0) {
      currentReputation = totalVotes[_proposalNo].upvotes * 100 / total;

      if (currentReputation >= proposals[_proposalNo].minReputations) {
        proposals[_proposalNo].isMajority = true;
      }
    }

    emit ProposalResult(_proposalNo, currentReputation, proposals[_proposalNo].isMajority);
  }

  function getProposalNumber(bytes memory _proposalId) external view returns(uint256) {
    uint256 currentIndex = 1;
    uint256 proposalId = 0;

    while(currentIndex <= proposalCount.current()) {
      if (
        keccak256(abi.encodePacked(proposals[currentIndex].proposalId)) ==
        keccak256(abi.encodePacked(_proposalId))
      ) {
        proposalId = currentIndex;
        break;
      }

      currentIndex += 1;
    }

    return proposalId;
  }

  function getVoteAllowance(uint256 _proposalNo, address _voter) 
    external 
    view 
    returns(uint256) 
  {
    return IERC721(nftContract).balanceOf(_voter) - voteEntries[_proposalNo][_voter];
  }

  function _checkAvailability(address _voter, uint256 _proposalNo, uint256 _votingCount) 
    internal 
    view
    returns (bool) 
  {
    return (voteEntries[_proposalNo][_voter] + _votingCount) <= IERC721(nftContract).balanceOf(_voter);
  }

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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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