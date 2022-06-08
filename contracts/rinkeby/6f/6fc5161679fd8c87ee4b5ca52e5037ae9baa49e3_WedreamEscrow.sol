// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WedreamEscrow is IERC721Receiver, Ownable {
    using Counters for Counters.Counter;

    // counter for tracking current token id
    Counters.Counter public tokenRegistryId;

    uint256 public withdrawalLockedUntil;
    uint256 public auctionStartsAt;
    uint256 public auctionEndsAt;

    mapping(uint256 => TokenRegistryEntry) public tokenRegistry;
    mapping(address => uint256[]) public tokenIdsByAddress;
    mapping(address => uint256) public tokenCountByAddress;

    struct TokenRegistryEntry {
        address tokenContract;
        uint256 tokenIdentifier;
        address tokenOwner;
        uint256 minimumPrice;
    }

    struct Bid {
        address tokenContract;
        uint256 tokenIdentifier;
        uint256 tokenRegistryId;
        uint256 amount;
    }

    //events
    event TokenWithdrawal(
        uint256 tokenRegistryId,
        address tokenContract,
        uint256 tokenIdentifier,
        address withdrawalInitiator,
        address withdrawalReceiver
    );

    event MinmumPriceChange(
        uint256 tokenRegistryId,
        uint256 oldMiniumPrice,
        uint256 newMiniumPrice,
        address priceChanger
    );

    event FulfillBid(
        uint256 tokenRegistryId,
        address tokenContract,
        uint256 tokenIdentifier,
        address tokenReceiver,
        uint256 minimumPrice,
        uint256 paidAmount
    );

    constructor() public {
        // TODO: What needs to be in the constructor
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}. Also registers token in our TokenRegistry.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address, // operator not required
        address tokenOwnerAddress,
        uint256 tokenIdentifier,
        bytes memory
    ) public virtual override returns (bytes4) {
        tokenRegistryId.increment();
        tokenRegistry[tokenRegistryId.current()] = TokenRegistryEntry(
            msg.sender,
            tokenIdentifier,
            tokenOwnerAddress,
            0
        );
        tokenIdsByAddress[msg.sender].push(tokenRegistryId.current());
        tokenCountByAddress[msg.sender]++;
        return this.onERC721Received.selector;
    }

    /**
     * @dev Function withdrawal a specific token from the registry.
     * Requirements:
     * - Token must be owned by this contract.
     * - Token was owned by msg.sender before.
     * - It is allowed to withdrawal tokens at this moment.
     *
     * @param _tokenRegistryId id in the token registry.
     */
    function withdrawalToken(
        uint256 _tokenRegistryId,
        address _tokenContract,
        uint256 _tokenIdentifier
    ) public virtual {
        require(
            tokenRegistry[_tokenRegistryId].tokenOwner == msg.sender,
            "WedreamEscrow: Invalid Sender"
        );

        require(
            tokenRegistry[_tokenRegistryId].tokenIdentifier ==
                _tokenIdentifier &&
                tokenRegistry[_tokenRegistryId].tokenContract == _tokenContract,
            "WedreamEscrow: Invalid Registry Entry"
        );

        require(
            (block.timestamp < auctionStartsAt ||
                withdrawalLockedUntil < block.timestamp),
            "WedreamEscrow: Withdrawal currently not allowed"
        );

        transferToken(
            tokenRegistry[_tokenRegistryId].tokenContract,
            tokenRegistry[_tokenRegistryId].tokenIdentifier,
            tokenRegistry[_tokenRegistryId].tokenOwner
        );

        emit TokenWithdrawal(
            _tokenRegistryId,
            tokenRegistry[_tokenRegistryId].tokenContract,
            tokenRegistry[_tokenRegistryId].tokenIdentifier,
            msg.sender,
            tokenRegistry[_tokenRegistryId].tokenOwner
        );

        // TODO remove from tokenIdsByAddress
        delete tokenRegistry[_tokenRegistryId];
    }

    /**
     * @dev Function to set the token on sale and add a minimum price. Tokens
     * with minimum Price 0 are not allowed to be sold.
     *
     * Requirements:
     * - `msg.sender` needs to be owner of token in our registry
     */
    function setMinimumPrice(
        uint256 _tokenRegistryId,
        address _tokenContract,
        uint256 _tokenIdentifier,
        uint256 minimumPrice
    ) external {
        require(
            tokenRegistry[_tokenRegistryId].tokenOwner == msg.sender,
            "WedreamEscrow: Invalid Sender"
        );
        require(
            tokenRegistry[_tokenRegistryId].tokenIdentifier ==
                _tokenIdentifier &&
                tokenRegistry[_tokenRegistryId].tokenContract == _tokenContract,
            "WedreamEscrow: Invalid Registry Entry"
        );
        require(
            (block.timestamp < auctionStartsAt ||
                withdrawalLockedUntil < block.timestamp),
            "WedreamEscrow: Minimum Price Change is currently not allowed"
        );

        uint256 oldPrice = tokenRegistry[_tokenRegistryId].minimumPrice;
        tokenRegistry[_tokenRegistryId].minimumPrice = minimumPrice;

        emit MinmumPriceChange(
            _tokenRegistryId,
            oldPrice,
            minimumPrice,
            msg.sender
        );
    }

    /**
     * @dev Function to set the token on sale and add a minimum price. Tokens
     * with minimum Price 0 are not allowed to be sold. This is a Emergency Function.
     *
     * Requirements:
     * - `msg.sender` needs to admin of contract
     */
    function adminSetMinimumPrice(
        uint256 _tokenRegistryId,
        address _tokenContract,
        uint256 _tokenIdentifier,
        uint256 minimumPrice
    ) external onlyOwner {
        require(
            tokenRegistry[_tokenRegistryId].tokenIdentifier ==
                _tokenIdentifier &&
                tokenRegistry[_tokenRegistryId].tokenContract == _tokenContract,
            "WedreamEscrow: Invalid Registry Entry"
        );

        uint256 oldPrice = tokenRegistry[_tokenRegistryId].minimumPrice;
        tokenRegistry[_tokenRegistryId].minimumPrice = minimumPrice;

        emit MinmumPriceChange(
            _tokenRegistryId,
            oldPrice,
            minimumPrice,
            msg.sender
        );
    }

    /**
     * @dev TODO
     * Requirements:
     * - `msg.sender` needs to admin of contract
     */
    function adminChangePeriods(
        uint256 _auctionStartsAt,
        uint256 _auctionEndsAt,
        uint256 _withdrawalLockedUntil
    ) external onlyOwner {
        auctionStartsAt = _auctionStartsAt;
        auctionEndsAt = _auctionEndsAt;
        withdrawalLockedUntil = _withdrawalLockedUntil;
    }

    /**
     * @dev Withrawal all Funds sent to the contract to Owner.
     * Should never happen but just in case something gets stuck...
     *
     * Requirements:
     * - `msg.sender` needs to be Owner and payable
     */
    function adminWithdrawalEth() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    /**
     * @dev Emergency Admin function to withdrawal a specific token from the registry.
     * Requirements:
     * - Token must be owned by this contract.
     * - msg.sender is owner.
     *
     * @param _tokenRegistryId id in the token registry.
     */
    function adminWithdrawalToken(
        uint256 _tokenRegistryId,
        address _tokenContract,
        uint256 _tokenIdentifier
    ) public virtual onlyOwner {
        require(
            tokenRegistry[_tokenRegistryId].tokenIdentifier ==
                _tokenIdentifier &&
                tokenRegistry[_tokenRegistryId].tokenContract == _tokenContract,
            "WedreamEscrow: Invalid Registry Entry"
        );

        transferToken(
            tokenRegistry[_tokenRegistryId].tokenContract,
            tokenRegistry[_tokenRegistryId].tokenIdentifier,
            tokenRegistry[_tokenRegistryId].tokenOwner
        );

        emit TokenWithdrawal(
            _tokenRegistryId,
            tokenRegistry[_tokenRegistryId].tokenContract,
            tokenRegistry[_tokenRegistryId].tokenIdentifier,
            msg.sender,
            tokenRegistry[_tokenRegistryId].tokenOwner
        );

        // TODO remove from tokenIdsByAddress
        delete tokenRegistry[_tokenRegistryId];
    }

    /**
     * @dev Function for auction winner to fulfill the bid
     * Requirements:
     * - TODO
     *
     * @param acceptedBidSignature signed bid by escrowServiceWallet
     * @param bidData Struct of Bid
     * @param _tokenRegistryId id in the token registry.
     */
    function fulfillBid(
        bytes memory acceptedBidSignature,
        Bid memory bidData,
        uint256 _tokenRegistryId
    ) public payable {
        // TODO validate bid and bid signature
        // require(
        //     tokenRegistry[_tokenRegistryId],
        //     "WedreamEscrow: Invalid _tokenRegistryId"
        // );
        // TODO check with wedream if required. user needs to set any minimum price to put it on sale
        require(false, "WedreamEscrow: Function not implemented yet");
        require(
            tokenRegistry[_tokenRegistryId].minimumPrice > 0,
            "WedreamEscrow: Token is not on Sale"
        );
        require(
            msg.value >= tokenRegistry[_tokenRegistryId].minimumPrice,
            "WedreamEscrow: Reserve Price not met"
        );
        require(
            msg.value == bidData.amount,
            "WedreamEscrow: Amount send does not match bid"
        );
        require(
            tokenRegistry[_tokenRegistryId].tokenContract ==
                bidData.tokenContract,
            "WedreamEscrow: Mismatch of Token Data (Contract)"
        );
        require(
            tokenRegistry[_tokenRegistryId].tokenIdentifier ==
                bidData.tokenIdentifier,
            "WedreamEscrow: Mismatch of Token Data (Identifier)"
        );

        // TODO take wedream shared
        // TODO maybe take care about royalities

        transferToken(
            tokenRegistry[_tokenRegistryId].tokenContract,
            tokenRegistry[_tokenRegistryId].tokenIdentifier,
            msg.sender
        );

        emit FulfillBid(
            _tokenRegistryId,
            tokenRegistry[_tokenRegistryId].tokenContract,
            tokenRegistry[_tokenRegistryId].tokenIdentifier,
            msg.sender,
            tokenRegistry[_tokenRegistryId].minimumPrice,
            msg.value
        );
        // TODO remove from tokenIdsByAddress
        delete tokenRegistry[_tokenRegistryId];
    }

    /**
     * @dev Function to send a Token owned by this contract to an address
     * Requirements:
     * - Token must be owned by this contract.
     *
     * @param tokenContractAddress ERC721 Contract Address
     * @param tokenIdentifier Identifier on the token contract
     * @param tokenReceiver Receiver of the NFT
     */
    function transferToken(
        address tokenContractAddress,
        uint256 tokenIdentifier,
        address tokenReceiver
    ) private {
        require(
            IERC721(tokenContractAddress).ownerOf(tokenIdentifier) ==
                address(this),
            "WedreamEscrow: NFT is not owned by Escrow Contract"
        );

        IERC721(tokenContractAddress).safeTransferFrom(
            address(this),
            tokenReceiver,
            tokenIdentifier
        );
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