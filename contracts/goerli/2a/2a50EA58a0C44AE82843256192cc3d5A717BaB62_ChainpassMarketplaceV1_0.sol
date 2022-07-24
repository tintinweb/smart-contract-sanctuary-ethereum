//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./interfaces/ChainpassInterfaces.sol";
import "./types/ChainpassTypes.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ChainpassMarketplaceV1_0 is Ownable, ReentrancyGuard {

    struct GroupTicketAsk {
        uint256 startTokenId;
        uint256 amount;
        uint256 price;
    }

    event SecondaryAskSet(address ticketContractAddress, uint256 tokenId, uint256 price);
    event PrimaryAsksSet(address ticketContractAddress, uint256 startTokenId, uint256 amount, uint256 price);
    event TicketsBought(address ticketContractAddress, uint256[] tokenIds);

    address public chainpassRegistry;
    mapping(address => mapping(uint256 => Ask)) secondaryAsks;

    mapping(address => GroupTicketAsk[]) primaryAsks;
    mapping(address => mapping(uint256 => bool)) primaryAsksOmittedTokenIds;

    constructor(address  _chainpassRegistry) {
        chainpassRegistry = _chainpassRegistry;
    }

    function setPrimaryAsks(address ticketContractAddress, uint256 startTokenId, uint256 amount, uint256 price) external {
        IChainpassEventTickets ticketContract = IChainpassEventTickets(ticketContractAddress);
        require(
            address(ticketContract) == msg.sender,
            "Only ticket contract can set primary asks."
        );

        primaryAsks[ticketContractAddress].push(GroupTicketAsk(
            startTokenId,
            amount,
            price
        ));

        emit PrimaryAsksSet(ticketContractAddress, startTokenId, amount, price);
    }

    function setSecondaryAsk(address ticketContractAddress, uint256 tokenId, uint256 price) external {
        IChainpassEventTickets ticketContract = IChainpassEventTickets(ticketContractAddress);

        require(
            address(ticketContract) == msg.sender || ticketContract.ownerOf(tokenId) == msg.sender,
            "Only token owner or contract can set asks."
        );

        secondaryAsks[ticketContractAddress][tokenId] = Ask(true, price);

        if (!primaryAsksOmittedTokenIds[ticketContractAddress][tokenId]) {
            primaryAsksOmittedTokenIds[ticketContractAddress][tokenId] = true;
        }

        emit SecondaryAskSet(ticketContractAddress, tokenId, price);
    }

    function getAsk(address ticketContractAddress, uint256 tokenId) public view returns (Ask memory) {
        IChainpassEventTickets ticketContract = IChainpassEventTickets(ticketContractAddress);
        require(ticketContract.exists(tokenId), "Ticket doesn't exist.");

        if (secondaryAsks[ticketContractAddress][tokenId].exists) {
            return secondaryAsks[ticketContractAddress][tokenId];
        }

        if (!primaryAsksOmittedTokenIds[ticketContractAddress][tokenId]) {
            GroupTicketAsk[] memory groupAsks = primaryAsks[ticketContractAddress];
            for (uint256 i = 0; i < groupAsks.length; i++) {
                GroupTicketAsk memory groupAsk = groupAsks[i];

                if (tokenId >= groupAsk.startTokenId && tokenId < groupAsk.startTokenId + groupAsk.amount) {
                    return Ask(
                        true,
                        groupAsk.price
                    );
                }
            }
        }
        
        return Ask(false, 0);
    }

    function buyTickets(address ticketContractAddress, uint256[] memory tokenIds) external payable nonReentrant {
        require(tokenIds.length > 0, "There needs to be at least one tokenId");

        IChainpassEventTickets ticketContract = IChainpassEventTickets(ticketContractAddress);

        // sum up the total price and transfer each token
        uint256 totalPrice;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            Ask memory ask = getAsk(ticketContractAddress, tokenId);

            require(ask.exists, "Ticket is not for sale.");
            totalPrice += ask.price;

            ticketContract.transferFrom(ticketContract.ownerOf(tokenId), msg.sender, tokenId);

            if (!primaryAsksOmittedTokenIds[ticketContractAddress][tokenId]) {
                primaryAsksOmittedTokenIds[ticketContractAddress][tokenId] = true;
            }

            if (secondaryAsks[ticketContractAddress][tokenId].exists) {
                secondaryAsks[ticketContractAddress][tokenId] = Ask(false, 0);
            }
        }

        // check that the buyer has enough usdc
        IChainpassRegistry cpRegistry = registry();
        IERC20 usdcContract = IERC20(cpRegistry.getUSDCContractAddress());
        require(usdcContract.balanceOf(msg.sender) >= totalPrice, "Insufficient USDC.");

        IChainpassEventFactory cpEventFactory = eventFactory();

        uint256 royaltyAmount;
        (address royaltyReceiver, uint256 royaltyBPS) = ticketContract.getRoyaltyReceiverAndBPS();
        if (royaltyReceiver != address(0)) {
            // transfer royalties
            royaltyAmount = (totalPrice * royaltyBPS) / 10_000;
            usdcContract.transferFrom(msg.sender, royaltyReceiver, royaltyAmount);
        }

        // transfer CP cut
        uint256 chainpassCut = (totalPrice * cpEventFactory.getChainpassPrimaryBPS(ticketContractAddress)) / 10_000;
        usdcContract.transferFrom(msg.sender, cpRegistry.getChainpassWallet(), chainpassCut);
    
        // transfer the rest to the event host
        uint256 eventHostCut = totalPrice - royaltyAmount - chainpassCut;
        usdcContract.transferFrom(msg.sender, ticketContract.owner(), eventHostCut);

        emit TicketsBought(ticketContractAddress, tokenIds);
    }

    function registry() private view returns (IChainpassRegistry) {
        return IChainpassRegistry(chainpassRegistry);
    }

    function eventFactory() private view returns (IChainpassEventFactory) {
        return IChainpassEventFactory(registry().getChainpassEventFactoryContractAddress());
    }
}

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IERC2981Royalties.sol";

interface IOwnable {
    function owner() external returns (address);
}

interface IChainpassRegistry {
    function eventTicketTokenURI(address eventTicketContractAddress, uint256 tokenID) external view returns (string memory);
    function getChainpassEventFactoryContractAddress() external view returns (address);
    function getUSDCContractAddress() external view returns (address);
    function getChainpassWallet() external view returns (address);
    function getChainpassDefaultPrimaryBPS() external pure returns (uint256);
    function getChainpassMarketplaceContractAddress() external view returns (address);
}

interface IChainpassEventFactory {
    function getChainpassPrimaryBPS(address eventTicketContractAddress) external view returns (uint256);
}

interface IChainpassEventTickets is IERC721, IERC2981Royalties, IOwnable {
    function exists(uint256 tokenId) external view returns (bool);
    function getRoyaltyReceiverAndBPS() external view returns (address, uint256);
}

interface IChainpassMarketplace {
    function setPrimaryAsks(address ticketContractAddress, uint256 startTokenId, uint256 amount, uint256 price) external;
    function buyTickets(address ticketContractAddress, uint256[] memory tokenIds) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

struct Ask {
    bool exists;
    uint256 price;
}

struct Royalty {
    address receiver;
    uint256 bps;
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

// SPDX-License-Identifier: MIT
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
    event Approval(address indexed owner, address indexed spender, uint256 value);

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
    function allowance(address owner, address spender) external view returns (uint256);

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface IERC2981Royalties {
    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _value - the sale price of the NFT asset specified by _tokenId
    /// @return _receiver - address of who should be sent the royalty payment
    /// @return _royaltyAmount - the royalty payment amount for value sale price
    function royaltyInfo(uint256 _tokenId, uint256 _value)
        external
        view
        returns (address _receiver, uint256 _royaltyAmount);
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