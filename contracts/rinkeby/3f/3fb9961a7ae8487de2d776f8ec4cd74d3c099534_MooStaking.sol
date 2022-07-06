// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/IMilk.sol";

contract MooStaking is IERC721Receiver {
    struct Stake {
        uint256 tokenId;
        uint256 started;
        address owner;
    }

    uint256 public totalStaked;

    // Fixed staking reward (per NFT staked)
    uint256 public stakeReward = 100 ether;

    uint256 public rewardInterval = 1 days;

    uint256 public maxStakingPerWallet = 5;

    uint256 public maxStakingDuration = 9 days;

    // tokenID => Stake
    mapping(uint256 => Stake) public receipt;

    // owner => tokenIDs[]
    mapping(address => uint256[]) public staked;

    // tokenID => staked token of owner by index
    mapping(uint256 => uint256) private stakedIndex;

    // NFT to be staked
    IERC721 private collection;

    // ERC20 to be given as stake reward
    IMilk private milk;

    constructor(address collectionAddress, address milkAddress) {
        collection = IERC721(collectionAddress);
        milk = IMilk(milkAddress);
    }

    function stake(uint256 tokenId) public {
        require(staked[msg.sender].length < maxStakingPerWallet, "Reached max NFTs staked");
        // Check if NFT isn't already staked
        require(collection.ownerOf(tokenId) != address(this), "NFT already staked");
        // Check if the staker owns the NFT
        require(collection.ownerOf(tokenId) == msg.sender, "You're not the NFT owner");
        // Transfer the NFT to the staking contract vault (need approval first)
        collection.safeTransferFrom(msg.sender, address(this), tokenId, "");
        // Update in the mappings
        _stakeNFT(tokenId, msg.sender);
    }

    function stake(uint256[] calldata tokenIDs) public {
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            stake(tokenIDs[i]);
        }
    }

    function _stakeNFT(uint256 tokenId, address to) internal {
        // Array index starts at 0, so the length is the index for new array items
        uint256 index = staked[to].length;
        // Push the NFT to the array
        staked[to].push(tokenId);
        // Make the contract know which index this NFT are in
        stakedIndex[tokenId] = index;
        // Store the Stake informations (tokenId, time stake started, NFT owner)
        receipt[tokenId] = Stake(tokenId, block.timestamp, to);
        totalStaked++;
    }

    function unstake(uint256 tokenId) public {
        // Stake informations
        Stake memory _staked = receipt[tokenId];
        // Check if the caller is the NFT owner
        require(_staked.owner == msg.sender, "You're not the NFT owner");
        // If the above statement is OK, unstake the NFT
        _unstakeNFT(tokenId, msg.sender);
        // And after unstaking, give the NFT back to the owner
        collection.safeTransferFrom(address(this), msg.sender, tokenId, "");
    }

    function unstake(uint256[] calldata tokenIDs) public {
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            unstake(tokenIDs[i]);
        }
    }

    function _unstakeNFT(uint256 tokenId, address to) internal {
        // Staked NFT index in the array
        uint256 index = stakedIndex[tokenId];
        // Get the last index in the array
        uint256 last = staked[to].length - 1;
        // If the NFT we wish to unstake isn't the last one, make it the last one
        if (index != last) {
            // ID of the last index NFT
            uint256 lastTokenId = staked[to][last];
            // Move the last NFT to the index of the NFT that will be unstaked
            staked[to][index] = lastTokenId;
            // Move the NFT that will be unstaked to the last NFT index
            staked[to][last] = tokenId;
            // Make the same thing with the index array
            stakedIndex[lastTokenId] = index;
            stakedIndex[tokenId] = last;
        }
        // Then delete the index of the unstaked token
        delete stakedIndex[tokenId];
        // Remove from the owner staked NFT's array
        staked[to].pop();
        // Delete the Stake informations from the vault
        delete receipt[tokenId];
        totalStaked--;
    }

    function claim() external {
        // Check if the claimer has any NFT staked
        require(staked[msg.sender].length > 0, "Nothing to claim");
        uint256 tokenId;
        uint256 reward;
        // Loop into claimer staked NFT's
        for (uint256 i = 0; i < staked[msg.sender].length; i++) {
            tokenId = staked[msg.sender][i];
            // Stake informations
            Stake memory _staked = receipt[tokenId];
            // Check if the claimer is the NFT owner
            require(_staked.owner == msg.sender, "You're not the NFT owner");
            // NFT stake start date (unix timestamp)
            uint256 stakedAt = _staked.started;
            // reward = stakeReward * rewardInterval staked
            reward += stakeReward * ((((block.timestamp - stakedAt) / rewardInterval) / (maxStakingDuration / rewardInterval)) > 0 ? (maxStakingDuration / rewardInterval) : ((block.timestamp - stakedAt) / rewardInterval));
        }
        // If reward isn't zero, mint the reward ERC20 to the claimer
        if (reward > 0) {
            milk.mint(msg.sender, reward);
        }
    }

    function stakedNFTs() external view returns (uint256[] memory) {
        return staked[msg.sender];
    }

    function getReceipt(uint256 tokenId) external view returns (uint256, uint256, address) {
        require(collection.ownerOf(tokenId) == address(this), "NFT not staked");
        Stake memory _staked = receipt[tokenId];
        return (_staked.tokenId, _staked.started, _staked.owner);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
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
pragma solidity ^0.8.15;

interface IMilk {
    function mint(address to, uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
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