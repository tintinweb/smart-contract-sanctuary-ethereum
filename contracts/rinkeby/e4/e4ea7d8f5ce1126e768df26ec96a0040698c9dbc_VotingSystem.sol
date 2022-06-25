/**
 *Submitted for verification at Etherscan.io on 2022-06-25
*/

// SPDX-License-Identifier: MIT
// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/IERC165.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: contracts/votingContract.sol




pragma solidity >=0.7.0 <0.9.0;

contract VotingSystem {
    event proposalCreated(uint p_id,address owner);
    IERC721 nft;
    IERC721Enumerable nft1;
    
    struct Voter {
        uint weight; //Weight of the voter
        bool voted;  // if true, that person already voted
        uint vote;   // index of the voted proposal
    }

    // This is a type for a single proposal.
    struct Proposal {
        string name;   // short name (up to 32 bytes)
        uint pid;
        uint voteCount; // number of supporters
        uint opposeCount; // number of opposers
        uint neutralCount; // number of Neutrals
        address initiator; // Person who initiate the proposal
        uint startTime;  //Start time of proposal
    }


    // address public admin;

    // This declares a state variable that
    // stores a `Voter` struct for each possible address.
    // mapping(address => Voter) public voters;
mapping (address => mapping (uint => Voter) ) public voters;
    // A dynamically-sized array of `Proposal` structs.
    Proposal[] public proposals;

    /// Create a new ballot to choose one of `proposalNames`.
    constructor(address nftContract) {
        nft=IERC721(nftContract);
        nft1 = IERC721Enumerable(nftContract);
      
    }
function updateNFTAddress(address nftContract) public {
        nft=IERC721(nftContract);
        nft1 = IERC721Enumerable(nftContract);
      
    }
    function addProposal(string memory _name) public {
        require(nft.balanceOf(msg.sender)>0,"Not a Member of our system");
        require (nft1.totalSupply()>=2,"A minimum of 25% of the sale of all NFT for the community to be able start making voting proposals");  // 1250000 25% of 5 million

uint temp = proposals.length;
emit proposalCreated(temp,msg.sender);
        for(uint i=0;i<proposals.length;i++){
            if(proposals[i].initiator==msg.sender){
                if(proposals[i].startTime  + 1 minutes > block.timestamp){
                    revert("Only create one proposal in 12 days");
                }
            }
        }
            proposals.push(
                Proposal({
                    pid: temp,
                    name: _name,
                    voteCount: 0,
                    opposeCount:0,
                    neutralCount:0,
                    initiator:msg.sender,
                    startTime: block.timestamp

                })
            );
          
    }
    function returnLastProposal()external view returns(uint){
        // require(!proposals ,"No Proposal Yet");
        // require(proposals.length>=0,"No Proposal Yet");

return proposals.length;
        
    }

// function balinNft () public view returns (uint){
//     return nft.balanceOf(msg.sender);    
// }
    
 
    function vote(uint proposal,uint voteType) external {
        require( proposals[proposal].startTime + 5 minutes >= block.timestamp,"Voting Period for this proposal is over");
        require(voteType==0||voteType==1||voteType==3,"Type Not Available");
        Voter storage sender = voters[msg.sender][proposal];
        sender.weight = nft.balanceOf(msg.sender); 
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = proposal;                            

      
        if(voteType==0){
        proposals[proposal].voteCount += sender.weight;
        }
        else if(voteType==1){
        proposals[proposal].opposeCount += sender.weight;
        }
         else if(voteType==2){
        proposals[proposal].neutralCount += sender.weight;
        }
    }

    function getProposalVotes(uint proposal)external view returns(uint[3] memory){
        uint[3] memory temp;
            temp[0]=proposals[proposal].voteCount;
            temp[1]=proposals[proposal].opposeCount;
            temp[2]=proposals[proposal].neutralCount;
        
         return temp;   
        //  return [proposals[proposal].voteCount,proposals[proposal].opposeCount,proposals[proposal].neutralCount];

    } 
    function getProposalResult(uint proposal) external view returns(string memory){
require(proposals[proposal].startTime+ 5 minutes <block.timestamp,"Result can only be shown after 12 Days");
        uint votes=proposals[proposal].voteCount;
        uint oppose=proposals[proposal].opposeCount;
        uint neutral=proposals[proposal].neutralCount;

        require(votes!=0||oppose!=0||neutral!=0,"No vote casted for this proposal");
        if(votes+oppose+neutral <= nft1.totalSupply() *60 / 100)
        {
            return "Not Enough Voters"; 
        }
        // require(proposals[proposal].voteCount==0&&proposals[proposal].opposeCount==0&&proposals[proposal].neutralCount==0,"No vote casted for this proposal");
        // if(votes + oppose > neutral){
            // if(neutral>votes && neutral>oppose)
            // {
            //      return "Neutral, There were not enough voters";
            // }
            // else 
            if(
                votes>oppose
            ){
                return "Supported by the community";
            }
            else if(
                votes<oppose
            ){
                return "Rejected by the community";
            }else if(votes == oppose){
                return "Community is Neutral about this Proposal";
            }
            else{
                return "undefined";
            }

        } 
        // else{
        //     return "There were not enough voters";
        // }
    }