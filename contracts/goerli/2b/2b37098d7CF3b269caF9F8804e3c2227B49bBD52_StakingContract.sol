// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract StakingContract {
    struct Staker {
        address stakerAddress;
        uint256 stakedNFTCount;
    }
    struct NFT{
        address contractAddress;
        uint256 tokenId;
    }

    // Define events
    event NFTStaked(address indexed user, address indexed nftAddress, uint256 indexed tokenId);
    event NFTUnstaked(address indexed user, address indexed nftAddress, uint256 indexed tokenId);

    mapping(address => mapping(uint256 => bool)) public stakedNFTs;
    mapping(address => Staker) public stakers;
    mapping(address => NFT[]) public staked;
    address[] public stakerAddresses;

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function stakeNFT(address nftAddress, uint256 tokenId) public {
        IERC721 nftContract = IERC721(nftAddress);

        require(nftContract.ownerOf(tokenId) == msg.sender, "You must own the NFT to stake it");
        require(stakedNFTs[nftAddress][tokenId] == false, "NFT already staked");
        nftContract.transferFrom(msg.sender, address(this), tokenId);

        stakedNFTs[nftAddress][tokenId] = true;
        if(stakers[msg.sender].stakedNFTCount == 0) {
            stakerAddresses.push(msg.sender);
        }
        stakers[msg.sender] = Staker(msg.sender, stakers[msg.sender].stakedNFTCount + 1);
        staked[msg.sender].push(NFT(nftAddress, tokenId));

        // Emit event
        emit NFTStaked(msg.sender, nftAddress, tokenId);
    }

    function getStakedNFTS(address user)public view returns (NFT[] memory){
        return staked[user];
    } 

    function unstakeNFT(address nftAddress, uint256 tokenId) public {
        require(stakedNFTs[nftAddress][tokenId] == true, "NFT is not staked");

        IERC721 nftContract = IERC721(nftAddress);

        bool owned = false;
        uint index = 0;
        NFT[] memory nfts = staked[msg.sender];
        for(uint i = 0; i < nfts.length; i++){
            if (nfts[i].contractAddress == nftAddress && nfts[i].tokenId == tokenId){
                owned = true;
                index = i;
                break;
            }
        }
        require(owned, "You don't own this NFT");
        nftContract.transferFrom(address(this), msg.sender, tokenId);

        stakedNFTs[nftAddress][tokenId] = false;
        stakers[msg.sender].stakedNFTCount -= 1;
        removeNFT(msg.sender, index);
        // Emit event
        emit NFTUnstaked(msg.sender, nftAddress, tokenId);
    }

    function removeNFT(address user, uint256 index) internal {
        require(index < staked[user].length, "Index out of bounds");

        if (index < staked[user].length - 1) {
            staked[user][index] = staked[user][staked[user].length - 1];
        }

        staked[user].pop();
    }

    function getStakerAddresses() public view returns (address[] memory) {
        return stakerAddresses;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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