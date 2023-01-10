// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract FUN721Staking is ReentrancyGuard {

    // Interfaces for ERC721
    IERC721 public immutable nftCollection;

    // Constructor function to set the NFT collection addresses
    constructor(IERC721 _nftCollection) {
        nftCollection = _nftCollection;
    }

    struct StakedToken {
        address staker;
        uint256 tokenId;
    }
    
    // Staker info
    struct Staker {
        // Amount of tokens staked by the staker
        uint256 amountStaked;

        // Staked token ids
        StakedToken[] stakedTokens;
    }

    // Mapping of User Address to Staker info
    mapping(address => Staker) public stakers;

    // Mapping of Token Id to staker. Made for the SC to remember
    // who to send back the ERC721 Token to.
    mapping(uint256 => address) public stakerAddress;

    // Increment the amountStaked and map msg.sender to the Token Id of the staked
    // Token to later send back on withdrawal.
    function stake(uint256 _tokenId) external nonReentrant {
        // Wallet must own the token they are trying to stake
        require(
            nftCollection.ownerOf(_tokenId) == msg.sender,
            "You don't own this token!"
        );

        // Transfer the token from the wallet to the Smart contract
        nftCollection.transferFrom(msg.sender, address(this), _tokenId);

        // Create StakedToken
        StakedToken memory stakedToken = StakedToken(msg.sender, _tokenId);

        // Add the token to the stakedTokens array
        stakers[msg.sender].stakedTokens.push(stakedToken);

        // Increment the amount staked for this wallet
        stakers[msg.sender].amountStaked++;

        // Update the mapping of the tokenId to the staker's address
        stakerAddress[_tokenId] = msg.sender;
    }
    
    // Check if user has any ERC721 Tokens Staked and if they tried to withdraw,
    // decrement the amountStaked of the user and transfer the ERC721 token back to them
    function withdraw(uint256 _tokenId) external nonReentrant {
        // Make sure the user has at least one token staked before withdrawing
        require(
            stakers[msg.sender].amountStaked > 0,
            "You have no tokens staked"
        );
        
        // Wallet must own the token they are trying to withdraw
        require(stakerAddress[_tokenId] == msg.sender, "You don't own this token!");

        // Find the index of this token id in the stakedTokens array
        uint256 index = 0;
        for (uint256 i = 0; i < stakers[msg.sender].stakedTokens.length; i++) {
            if (
                stakers[msg.sender].stakedTokens[i].tokenId == _tokenId 
                && 
                stakers[msg.sender].stakedTokens[i].staker != address(0)
            ) {
                index = i;
                break;
            }
        }

        // Set this token's .staker to be address 0 to mark it as no longer staked
        stakers[msg.sender].stakedTokens[index].staker = address(0);

        // Decrement the amount staked for this wallet
        stakers[msg.sender].amountStaked--;

        // Update the mapping of the tokenId to the be address(0) to indicate that the token is no longer staked
        stakerAddress[_tokenId] = address(0);

        // Transfer the token back to the withdrawer
        nftCollection.transferFrom(address(this), msg.sender, _tokenId);
    }

    function getStakedTokens(address _user) public view returns (StakedToken[] memory) {
        // Check if we know this user
        if (stakers[_user].amountStaked > 0) {
            // Return all the tokens in the stakedToken Array for this user that are not -1
            StakedToken[] memory _stakedTokens = new StakedToken[](stakers[_user].amountStaked);
            uint256 _index = 0;

            for (uint256 j = 0; j < stakers[_user].stakedTokens.length; j++) {
                if (stakers[_user].stakedTokens[j].staker != (address(0))) {
                    _stakedTokens[_index] = stakers[_user].stakedTokens[j];
                    _index++;
                }
            }

            return _stakedTokens;
        }
        
        // Otherwise, return empty array
        else {
            return new StakedToken[](0);
        }
    }
}