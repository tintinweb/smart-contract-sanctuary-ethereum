//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./meta_tx/MetaTxMixin.sol";
import "./interfaces/IChainpassRegistry.sol";
import "./interfaces/IChainpassTickets.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/*
 *  ChainpassMarketplace V1.0
 */
contract ChainpassMarketplace_1_0 is MetaTxMixin, Ownable, ReentrancyGuard {
    struct Ask {
        bool exists;
        uint256 price;
    }

    struct GroupTicketAsk {
        uint256 startTokenId;
        uint256 amount;
        uint256 price;
    }

    event SecondaryAskSet(address ticketContractAddress, uint256 tokenId, uint256 price);
    event PrimaryAsksSet(address ticketContractAddress, uint256 startTokenId, uint256 amount, uint256 price);
    event TicketsBought(address ticketContractAddress, uint256[] tokenIds);

    constructor(address  _chainpassRegistry) {
        chainpassRegistry = _chainpassRegistry;
    }

    /*
     *  Handling asks.
     */
    mapping(address => GroupTicketAsk[]) primaryAsks;
    mapping(address => mapping(uint256 => bool)) primaryAsksOmittedTokenIds;
    mapping(address => mapping(uint256 => Ask)) secondaryAsks;

    function setPrimaryAsks(
        address ticketContractAddress,
        uint256 startTokenId,
        uint256 amount,
        uint256 price
    ) external {
        IChainpassTickets ticketContract = IChainpassTickets(ticketContractAddress);
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

    function setSecondaryAsks(
        address ticketContractAddress,
        uint256[] calldata tokenIds,
        uint256[] calldata prices
    ) external {
        require(tokenIds.length > 0, "At least one token is required.");
        require(tokenIds.length == prices.length, "Token ids and prices must match length.");

        IChainpassTickets ticketContract = IChainpassTickets(ticketContractAddress);
        address ticketOwner;
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            address a = ticketContract.ownerOf(tokenId);

            if (i == 0) {
                ticketOwner = a;
            
            } else {
                require(a == ticketOwner, "All tokens must be held by the same owner.");
            }
        }

        require(
            _msgSender() == ticketOwner || ticketContract.isApprovedForAll(_msgSender(), ticketOwner),
            "Only token owner or contract can set asks."
        );

        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 price = prices[i];

            secondaryAsks[ticketContractAddress][tokenId] = Ask(true, price);

            if (!primaryAsksOmittedTokenIds[ticketContractAddress][tokenId]) {
                primaryAsksOmittedTokenIds[ticketContractAddress][tokenId] = true;
            }

            emit SecondaryAskSet(ticketContractAddress, tokenId, price);
        }
    }

    function getAsk(address ticketContractAddress, uint256 tokenId) public view returns (Ask memory) {
        IChainpassTickets ticketContract = IChainpassTickets(ticketContractAddress);
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

    /*
     *  Buying tickets.
     */
    function buyTicketsWithChainpassWallet(
        address attendee,
        address ticketContractAddress,
        uint256[] calldata tokenIds,
        uint256 maxPrice
    ) external payable nonReentrant {
        // Validate that the msgSender() is the Chainpass wallet.
        require(_msgSender() == chainpassWallet(), "Only the Chainpass Wallet can call buyTicketsWithChainpassWallet.");

        // Time to buy the tickets.
        _buyTickets(
            attendee,
            _msgSender(),
            ticketContractAddress,
            tokenIds,
            maxPrice
        );
    }

    function buyTickets(
        address ticketContractAddress,
        uint256[] calldata tokenIds,
        uint256 maxPrice
    ) external nonReentrant {
        _buyTickets(
            _msgSender(),
            _msgSender(),
            ticketContractAddress,
            tokenIds, 
            maxPrice
        );
    }

    function _buyTickets(
        address attendee,
        address buyer,
        address ticketContractAddress,
        uint256[] calldata tokenIds,
        uint256 maxPrice
    ) private {
        require(tokenIds.length > 0, "There needs to be at least one tokenId.");

        IChainpassTickets ticketContract = IChainpassTickets(ticketContractAddress);

        (uint256 totalPrice, uint32[] memory sharePerToken) = getPrices(
            ticketContractAddress,
            tokenIds
        );

        require(totalPrice <= maxPrice, "Total price exceeds max.");

        // check that the buyer has enough usdc
        uint256 royaltyAmount;
        (address royaltyReceiver, uint256 royaltyBPS) = ticketContract.getRoyaltyReceiverAndFee();
        if (royaltyReceiver != address(0) && royaltyBPS != 0) {
            // transfer royalties
            royaltyAmount = (totalPrice * royaltyBPS) / 10_000;
            transferUSDC(buyer, royaltyReceiver, royaltyAmount);
        }
    
        // transfer the rest to the sellers
        tansferTicketsAndPaySellers(
            ticketContract,
            buyer,
            attendee,
            totalPrice - royaltyAmount,
            tokenIds,
            sharePerToken
        );


        emit TicketsBought(ticketContractAddress, tokenIds);
    }

    function getPrices(
        address ticketContractAddress,
        uint256[] calldata tokenIds
    ) private returns (uint256, uint32[] memory) {
        // sum up the total price and transfer each token
        uint256 totalPrice;
        uint32[] memory sharePerToken = new uint32[](tokenIds.length);
        uint256[] memory pricePerToken = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            Ask memory ask = getAsk(ticketContractAddress, tokenId);

            require(ask.exists, "Ticket is not for sale.");
            totalPrice += ask.price;

            pricePerToken[i] = ask.price;

            if (!primaryAsksOmittedTokenIds[ticketContractAddress][tokenId]) {
                primaryAsksOmittedTokenIds[ticketContractAddress][tokenId] = true;
            }

            if (secondaryAsks[ticketContractAddress][tokenId].exists) {
                secondaryAsks[ticketContractAddress][tokenId] = Ask(false, 0);
            }
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            sharePerToken[i] = uint32((10_000 * pricePerToken[i]) / totalPrice);
        }

        return (totalPrice, sharePerToken);
    }

    function tansferTicketsAndPaySellers(
        IChainpassTickets ticketContract,
        address buyer,
        address attendee,
        uint256 revenueMinusFees,
        uint256[] calldata tokenIds,
        uint32[] memory sharePerToken
    ) private {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint32 share = sharePerToken[i];
            address owner = ticketContract.ownerOf(tokenId);

            transferUSDC(buyer, owner, (revenueMinusFees * share) / 10_000);
            ticketContract.safeTransferFrom(owner, attendee, tokenId);
        }
    }

    /*
     *  Handling USDC
     */
    function transferUSDC(address from, address to, uint256 amount) private {
        IERC20 usdcContract = IERC20(registry().getUSDCContractAddress());
        usdcContract.transferFrom(from, to, amount);
    }

    /*
     *  Chainpass Protocol Contracts
     */
    address public chainpassRegistry;

    function registry() private view returns (IChainpassRegistry) {
        return IChainpassRegistry(chainpassRegistry);
    }

    function chainpassWallet() private view returns (address) {
        return registry().getChainpassWallet();
    }

    /*
     *  Context
     */
    function _msgSender() internal view override returns (address) {
        if (currentContextSigner != address(0)) {
            return currentContextSigner;
        }

        return msg.sender;
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.1.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";

struct Transaction {
    bytes32 nonce;
    bytes data;
}

abstract contract MetaTxMixin is Context {
    address internal currentContextSigner;
    mapping (bytes32 => bool) private txNoncesExecuted;

    function executeMetaTx(
        Transaction calldata transaction,
        bytes32 r, bytes32 s, uint8 v
    ) public {
        // Perform validation steps.
        require(currentContextSigner == address(0), "currentContextSigner is already overwritten.");
        require(!txNoncesExecuted[transaction.nonce], "Transaction nonce already used.");

        // ecrecover
        bytes32 msgHash = keccak256(
            abi.encode(
                transaction.nonce,
                address(this),
                transaction.data
            )
        );
        address signer = recoverSignature(msgHash, r, s, v);

        // Set the current context signer and the nonce.
        txNoncesExecuted[transaction.nonce] = true;
        currentContextSigner = signer;

        (bool didSucceed, bytes memory returnvalue) = address(this).delegatecall(transaction.data);
        require(didSucceed, string(abi.encodePacked("Transaction did not succeed: ", returnvalue)));

        // Set the current context signer back to the zero address.
        currentContextSigner = address(0);
    }

    function recoverSignature(
        bytes32 messageHash,
        bytes32 r,
        bytes32 s, 
        uint8 v
    ) internal pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes memory prefixedMessage = abi.encodePacked(prefix, messageHash);
        bytes32 hashedMessage = keccak256(prefixedMessage);
        return ecrecover(hashedMessage, v, r, s);
    }
}

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface IChainpassRegistry {
    function eventTicketTokenURI(address eventTicketContractAddress, uint256 tokenID) external view returns (string memory);
    function getEventFactoryContractAddress() external view returns (address);
    function getUSDCContractAddress() external view returns (address);
    function getChainpassWallet() external view returns (address);
    function getChainpassDefaultFee() external pure returns (uint32);
    function getMarketplaceContractAddress() external view returns (address);
    function getSplitsBaseContractAddress() external view returns (address);
    function getTicketsBaseContractAddress() external view returns (address);
}

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IERC2981Royalties.sol";
import "./IOwnable.sol";

interface IChainpassTickets is IERC721, IERC2981Royalties, IOwnable {
    function exists(uint256 tokenId) external view returns (bool);
    function getRoyaltyReceiverAndFee() external view returns (address, uint256);
    function getSplitsContractAddress() external view returns (address);
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

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface IOwnable {
    function owner() external returns (address);
    function transferOwnership(address addr) external;
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