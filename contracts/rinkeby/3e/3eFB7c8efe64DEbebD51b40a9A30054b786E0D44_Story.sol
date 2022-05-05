//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";

contract Story {
    struct storyDetails {
        uint256 contributionTime;
        bytes32 storyCommit;
        bytes story;
        bool revealed;
    }

    struct Stats {
        uint256 numberOfContributions;
        address lastContributor;
    }

    struct Stories {
        uint256 contributionIndex;
        address contributor;
    }

    /*
    First mapping is a mapping of contract addressess to contributors' addressess
    Second mapping is a mapping of contributors' addresses to a list of their contributions.
     */
    mapping (address => mapping (address => storyDetails[])) tokenStories;

    mapping (address => Stories[]) contributions;

    // a mapping of contract addresses and their contribution stats
    mapping (address => Stats) contributionStats;

    uint256 public totalStories;

    /** --------------------------------- Write functions --------------------------- */  

    modifier commitHelper (address tokenAddress) {
        require(tokenAddress != address(0), "Can't create a story commit with an empty address");
        require(canContribute(msg.sender, tokenAddress), "Only token holders can contribute to a story");
        require(contributionStats[tokenAddress].lastContributor != msg.sender, "You can't contribute to the same story twice in a row");
        require(getLastContribution(msg.sender, tokenAddress).revealed, "You can't contribute a new story before last reveal");

        if (contributionStats[tokenAddress].numberOfContributions == 0) {
            totalStories++;
        }

        contributionStats[tokenAddress].numberOfContributions++;
        contributionStats[tokenAddress].lastContributor = msg.sender;
        _;
    }

    /** 
    * @dev commits story to a given address.
    * @param tokenAddress address of the token contract
    * @param storyHash bytes32 of the story commit
    */
    function createStoryCommit (
        bytes32 storyHash, 
        address tokenAddress
        ) public commitHelper(
            tokenAddress
            ) {
        tokenStories[tokenAddress][msg.sender].push(
            storyDetails(block.timestamp, storyHash, bytes(""), false)
        );
    }

    /**
    * @dev Reveals the story committed by a contributor.
    * @param story the story to be revealed
    * @param tokenAddress address of the token contract
     */
    function createStoryReveal (bytes memory story, address tokenAddress) public {
        require(getLastContribution(msg.sender, tokenAddress).revealed == false, "You can't reveal a story twice");
        require(canContribute(msg.sender, tokenAddress), "Only token holders can contribute to a story");

        bytes32 storyReveal = sha256(abi.encodePacked(msg.sender, story));
        uint256 stories = tokenStories[tokenAddress][msg.sender].length;
        storyDetails memory Dstory = tokenStories[tokenAddress][msg.sender][stories - 1];
        require(storyReveal == Dstory.storyCommit, "Story commit doesn't match");

        contributions[tokenAddress].push(
            Stories(stories - 1, msg.sender)
        );

        tokenStories[tokenAddress][msg.sender][stories - 1] = storyDetails (
            Dstory.contributionTime,
            Dstory.storyCommit,
            story,
            true
        );

    }

    /**
    * @dev Contributes to a story directly. Transactions are liable to frontrunning attacks if not sent privately.
    * @param story the story to be contributed
    * @param tokenAddress address of the token contract
     */
    function addStory (
        address tokenAddress, 
        bytes memory story
        ) commitHelper(tokenAddress) public {
            bytes32 storyReveal = sha256(abi.encodePacked(msg.sender, story));
            tokenStories[tokenAddress][msg.sender].push(
            storyDetails(block.timestamp, storyReveal, story, true)
        );
    }

    /** --------------------------------- Read functions --------------------------- */  

    /**
    * @dev Checks if the given address can contributr to a story.
    * @param contributorAddress The address of the contributor.
    * @param tokenAddress The address of the token contract.
     */
    function canContribute (address contributorAddress, address tokenAddress) public view returns (bool) {
        require(contributorAddress != address(0));
        require(tokenAddress != address(0));
        IERC721 token = IERC721(tokenAddress);
        return token.balanceOf(contributorAddress) > 0;
    }

    /**
     * @dev Returns whether an address is a contributor to the contract.
     * @param tokenAddress The address of the contract
     * @param contributorAddress The address of the contributor
     */
    function isContributor (address contributorAddress, address tokenAddress) public view returns (bool) {
        uint256 stories = tokenStories[tokenAddress][contributorAddress].length;
        return stories > 0;
    }

    /**
     * @dev Returns the number of contributions made by a contributor.
     * @param contributorAddress The address of the contributor
     * @param tokenAddress The address of the contract
     */
    function getNumberOfContributions (address contributorAddress, address tokenAddress) public view returns (uint256) {
        uint256 stories = tokenStories[tokenAddress][contributorAddress].length;
        return stories;
    }

    /**
     * @dev Returns the last contribution made by a contributor.
     * @param contributorAddress The address of the contributor
     * @param tokenAddress The address of the contract
     */
    function getLastContribution (address contributorAddress, address tokenAddress) public view returns (storyDetails memory) {
        uint256 stories = tokenStories[tokenAddress][contributorAddress].length;
        if (stories > 0) {
            return tokenStories[tokenAddress][contributorAddress][stories - 1];
        } else {
            return storyDetails(
                0,
                bytes32(""),
                bytes(""),
                true
            );
        }
    }

    /**
     * @dev Returns all the contributions made by a contributor.
     * @param contributorAddress The address of the contributor
     * @param tokenAddress The address of the contract
     */
    function getContributions(address contributorAddress, address tokenAddress) public view returns (storyDetails[] memory) {
        return tokenStories[tokenAddress][contributorAddress];
    }

    /**
    * @dev Returns the last contribution made to a story  
    * @param tokenAddress The address of the contract
     */
    function getLastStory (address tokenAddress) public view returns (bytes memory) {
        address lastContributor = contributionStats[tokenAddress].lastContributor;
        return getLastContribution(lastContributor, tokenAddress).story;
    }

    /**
    * @dev Returns the number of contributions and last contribution made to a story
    * @param tokenAddress The address of the contract
     */
    function getStoryStats (address tokenAddress) public view returns (Stats memory) {
        return contributionStats[tokenAddress];
    }

    /**
    * @dev Returns all Stories - contributor address and the index of their contribution in order
    * @param tokenAddress The address of the contract
    */
    function getAllContributions (address tokenAddress) public view returns (Stories[] memory) {
        return contributions[tokenAddress];
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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