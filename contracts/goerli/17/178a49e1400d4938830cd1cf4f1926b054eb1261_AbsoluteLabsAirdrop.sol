/**
 *Submitted for verification at Etherscan.io on 2022-09-28
*/

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: contracts/absolute_labs_airdrop.sol

// AbsoluteLabsAirdrop v0.1
// Contract performing airdrops for customers of absolutelabs.io

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IERC721MintTo {
    function mintTo(address to, uint256 quantity) external payable;
}

contract AbsoluteLabsAirdrop is Ownable {
    // ERC20 balances per team.
    // teamId => (token contract address => balance in airdrop contract)
    mapping(string => mapping(IERC20 => uint256)) public erc20Balances;

    // ERC721 token IDs per team.
    // teamId => (NFT coll contract address => IDs in airdrop contract)
    mapping(string => mapping(IERC721 => uint256[])) public erc721Balances;

    // Cursors in ERC721 ID arrays.
    // We will be sending tokens in the order we received them, moving the cursor from which we start
    // reading in the ID array.
    mapping(string => mapping(IERC721 => uint256)) public erc721BalanceCursors;

    constructor() {}

    // Provide ERC20 tokens for a given team.
    // Requires sender to have approved this contract to spend its tokens.
    function fundERC20(
        string calldata teamId,
        IERC20 token,
        uint256 quantity
    ) external {
        require(
            token.allowance(msg.sender, address(this)) >= quantity,
            "Insufficient allowance to fund this quantity"
        );
        require(
            token.balanceOf(msg.sender) >= quantity,
            "Insufficient balance to fund this quantity"
        );
        token.transferFrom(msg.sender, address(this), quantity);
        erc20Balances[teamId][token] += quantity;
    }

    // Withdraw tokens from a team's balance.
    function withdrawERC20(
        string calldata teamId,
        IERC20 token,
        uint256 quantity,
        address to
    ) external onlyOwner {
        require(
            token.balanceOf(address(this)) >= quantity,
            "Insufficient balance to withdraw this quantity"
        );
        token.transferFrom(address(this), to, quantity);
        erc20Balances[teamId][token] -= quantity;
    }

    // Send tokens from a team's balance to a list of recipients.
    function airdropERC20(
        string calldata teamId,
        IERC20 token,
        address[] memory recipients,
        uint256 amountPerRecipient
    ) external onlyOwner {
        uint256 totalSize = amountPerRecipient * recipients.length;
        require(
            erc20Balances[teamId][token] >= totalSize,
            "Insufficient balance to airdrop this quantity"
        );
        erc20Balances[teamId][token] -= totalSize;
        for (uint256 i = 0; i < recipients.length; i++) {
            token.transfer(recipients[i], amountPerRecipient);
        }
    }

    // Directly mint NFTs into recipient wallets, if contract is compatible.
    function mintERC721(
        IERC721MintTo token,
        address[] memory recipients,
        uint256 amountPerRecipient,
        uint256 valuePerToken
    ) external onlyOwner {
        for (uint256 i = 0; i < recipients.length; i++) {
            token.mintTo{value: valuePerToken * amountPerRecipient}(
                recipients[i],
                amountPerRecipient
            );
        }
    }

    // Team can send / mint tokens to this contract, which Absolute Labs later reconciles by referencing ids.
    function registerERC721ToTeam(
        string calldata teamId,
        IERC721 token,
        uint256[] memory tokenIds
    ) external onlyOwner {
        for (uint256 i; i < tokenIds.length; i++) {
            erc721Balances[teamId][token].push(tokenIds[i]);
        }
    }

    // Send NFTs from a team's balance to a list of recipients.
    function airdropERC721(
        string calldata teamId,
        IERC721 token,
        address[] memory recipients,
        uint256 amountPerRecipient
    ) external onlyOwner {
        uint256 cursor = erc721BalanceCursors[teamId][token];
        require(
            cursor + amountPerRecipient * recipients.length <
                erc721Balances[teamId][token].length,
            "Insufficient balance to send this quantity"
        );
        erc721BalanceCursors[teamId][token] +=
            amountPerRecipient *
            recipients.length;
        for (
            uint256 recipientId = 0;
            recipientId < recipients.length;
            recipientId++
        ) {
            for (uint256 i = 0; i < amountPerRecipient; i++) {
                token.safeTransferFrom(
                    address(this),
                    recipients[recipientId],
                    erc721Balances[teamId][token][
                        cursor + recipientId * amountPerRecipient + i
                    ]
                );
            }
        }
    }

    function withdrawERC721(
        string calldata teamId,
        IERC721 token,
        uint256 quantity,
        address to
    ) external onlyOwner {
        uint256 cursor = erc721BalanceCursors[teamId][token];
        require(
            cursor + quantity < erc721Balances[teamId][token].length,
            "Insufficient balance to withdraw this quantity"
        );
        erc721BalanceCursors[teamId][token] += quantity;
        for (uint256 i = cursor; i < cursor + quantity; i++) {
            token.safeTransferFrom(
                address(this),
                to,
                erc721Balances[teamId][token][i]
            );
        }
    }

    // In case tokens were registered to a team even though they are not in the contract, allow to adjust cursor for a team
    function setCursorForTeam(
        string calldata teamId,
        IERC721 token,
        uint256 cursor
    ) external onlyOwner {
        erc721BalanceCursors[teamId][token] = cursor;
    }
}