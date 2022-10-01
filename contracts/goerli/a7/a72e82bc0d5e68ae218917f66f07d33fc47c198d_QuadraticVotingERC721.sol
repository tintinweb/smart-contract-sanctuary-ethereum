// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract QuadraticVotingERC721 {

    uint public proposalCount;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    enum ProposalStatus {
        IN_PROGRESS,
        ENDED
    }

    struct Proposal {
        address proposalForNFT;
        address creator;
        bytes description;
        uint yesVotes;
        uint noVotes;
        uint expirationTime;
        ProposalStatus status;
        address[] voters;
        mapping(address => Voter) voterInfo;
    }

    struct Voter {
        bool hasVoted;
        bool vote;
        uint weight;
    }

    mapping(uint => Proposal) public ProposalIdToProposal;


    modifier hasBalance(address _nftAddress){
        require(_nftAddress != address(0));
        IERC721 erc721 = IERC721(_nftAddress);
        uint voterBalance = erc721.balanceOf(msg.sender);
        require(voterBalance >= 0, "You dont have enough tokens");
        _;
    }

    modifier validProposal(uint _proposalId){
        require(_proposalId <= proposalCount && _proposalId > 0);
        require(getProposalStatus(_proposalId) == ProposalStatus.IN_PROGRESS);
        require(getProposalExpirationTime(_proposalId) > block.timestamp, "Proposal has expired");
        _;
    }

    modifier authUser(address _user, uint _proposalId) {
        require(msg.sender == owner || msg.sender == ProposalIdToProposal[_proposalId].creator);
        _;
    }

    function createProposal(address _nftAddress, string calldata _description, uint _expirationTime) 
    external
    returns (uint) 
    {
        require(checkProposalLimit(_nftAddress), "There are 3 pending proposals");
        require(_expirationTime > block.timestamp, "Expiration time must be in future" );
        Proposal storage currentProposal = ProposalIdToProposal[proposalCount++];
        currentProposal.proposalForNFT = _nftAddress;
        currentProposal.creator = msg.sender;
        currentProposal.description = abi.encode(_description);
        currentProposal.expirationTime = _expirationTime;
        currentProposal.status = ProposalStatus.IN_PROGRESS;
        return proposalCount;
    }

    function castVote(uint _proposalId, bool _vote) 
    public 
    hasBalance(ProposalIdToProposal[_proposalId].proposalForNFT)
    validProposal(_proposalId)
    {
        require(userHasVoted(_proposalId, msg.sender) != true, "User has already voted");
        Proposal storage currentProposal = ProposalIdToProposal[_proposalId];
        IERC721 erc721 = IERC721(ProposalIdToProposal[_proposalId].proposalForNFT);
        uint voterBalance = erc721.balanceOf(msg.sender);
        uint weight = sqrt(voterBalance);
        currentProposal.voterInfo[msg.sender] = Voter(true, _vote, weight);
        currentProposal.voters.push(msg.sender);
    }

    function countVotes(uint _proposalId) external
    validProposal(_proposalId)
    returns (uint, uint)
    {
        uint yesVotes;
        uint noVotes;
        address[] memory voters = ProposalIdToProposal[_proposalId].voters;
        for (uint i = 0; i < voters.length; i++) {
            address voter = voters[i];
            bool vote = ProposalIdToProposal[_proposalId].voterInfo[voter].vote;
            uint weight = ProposalIdToProposal[_proposalId].voterInfo[voter].weight;
            if (vote == true) {
                yesVotes += weight;
            } 
            else {noVotes += weight;}
        } 
        
        ProposalIdToProposal[_proposalId].yesVotes = yesVotes;
        ProposalIdToProposal[_proposalId].noVotes = noVotes;

        return (yesVotes, noVotes);
    }

    function setProposalStatus(uint _proposalId) external 
    validProposal(_proposalId) 
    authUser(msg.sender, _proposalId)  
    {
        ProposalIdToProposal[_proposalId].status = ProposalStatus.ENDED;
    }

    function userHasVoted(uint _proposalId, address _user)internal view returns (bool) {
        return (ProposalIdToProposal[_proposalId].voterInfo[_user].hasVoted);
    }

    function getProposalStatus(uint _proposalId) internal view returns(ProposalStatus) {
       return ProposalIdToProposal[_proposalId].status;
    }

    function getProposalExpirationTime(uint _proposalId) internal view returns(uint) {
        return ProposalIdToProposal[_proposalId].expirationTime;
    }


    function checkProposalLimit(address _nftAddress) internal view returns(bool) {
        uint _proposalForNftAddress;
        if (proposalCount > 2) {
            for (uint i = 0; i < proposalCount; i++) {
            if (ProposalIdToProposal[i].proposalForNFT == _nftAddress && ProposalIdToProposal[i].status == ProposalStatus.IN_PROGRESS) {
                 _proposalForNftAddress++;
            } if (_proposalForNftAddress > 3) {
                return false;
            }
        }
    } else return true;
    }

    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }


    // function checkProposalLimit(address _nftAddress) internal view returns(bool) {
    //     uint _proposalForNftAddress;
    //     if (proposalCount < 3) {
    //         return true;
    //     } else for (uint i = 0; i < proposalCount; i++) {
    //         if (ProposalIdToProposal[i].proposalForNFT == _nftAddress && ProposalIdToProposal[i].status == ProposalStatus.IN_PROGRESS) {
    //              _proposalForNftAddress++;
    //         } if (_proposalForNftAddress > 3) {
    //             return false;
    //         }
    //     } return true;



}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (token/ERC721/IERC721.sol)

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