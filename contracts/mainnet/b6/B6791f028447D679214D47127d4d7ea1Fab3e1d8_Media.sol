//SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "./interfaces/IERC721Minter.sol";
import "./interfaces/IERC1155Minter.sol";
import "./interfaces/IMarket.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Media is Ownable {
    IMarket private epikoMarket;
    IERC1155Minter private epikoErc1155;
    IERC721Minter private epikoErc721;

    uint256 private constant PERCENTAGE_DENOMINATOR = 10000;

    /// @dev mapping from uri to bool
    mapping(string => bool) private _isUriExist;

    event Mint(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event MarketItemCreated(
        address indexed nftAddress,
        address indexed seller,
        uint256 price,
        uint256 indexed tokenId,
        uint256 quantity
    );
    event AuctionCreated(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 price,
        uint256 quantity,
        uint256 startTime,
        uint256 endTime
    );

    constructor(
        address erc721Address,
        address erc1155Address,
        address marketAddress
    ) {
        require(erc721Address != address(0), "Media: address Zero provided");
        require(erc1155Address != address(0), "Media: address Zero provided");
        require(marketAddress != address(0), "Media: address Zero provided");

        epikoErc721 = IERC721Minter(erc721Address);
        epikoErc1155 = IERC1155Minter(erc1155Address);
        epikoMarket = IMarket(marketAddress);
    }

    /* Mint nft */
    function mint(
        uint256 amount,
        uint256 royaltyFraction,
        string memory uri,
        bool isErc721
    ) external {
        require(amount > 0, "Media: amount zero provided");
        require(
            royaltyFraction <= PERCENTAGE_DENOMINATOR,
            "Media: invalid royaltyFraction provided"
        );
        require(_isUriExist[uri] != true, "Media: uri already exist");

        address _user = msg.sender;
        if (isErc721) {
            require(amount == 1, "Media: amount must be 1");
            uint256 id = epikoErc721.mint(_user, royaltyFraction, uri);
            emit Mint(address(0), _user, id);
        } else {
            require(amount > 0, "Media: amount must greater than 0");

            uint256 id = epikoErc1155.mint(
                _user,
                amount,
                royaltyFraction,
                uri,
                "0x00"
            );
            emit Mint(address(0), _user, id);
        }
        _isUriExist[uri] = true;
    }

    /* Burn nft (only contract Owner)*/
    function burn(uint256 tokenId) external onlyOwner {
        require(tokenId > 0, "Media: Not valid tokenId");

        epikoErc721.burn(tokenId);
        // delete _isUriExist[]
    }

    /* Burn nft (only contract Owner)*/
    function burn(
        address from,
        uint256 tokenId,
        uint256 amount
    ) external onlyOwner {
        require(tokenId > 0, "Not valid tokenId");

        epikoErc1155.burn(from, tokenId, amount);
    }

    /* Places item for sale on the marketplace */
    function sellitem(
        address nftAddress,
        address erc20Token,
        uint256 tokenId,
        uint256 amount,
        uint256 price
    ) external {
        require(nftAddress != address(0), "Media: Address zero provided");
        require(
            tokenId > 0 && price > 0 && amount > 0,
            "Media: not valid id or price or quantity"
        );

        epikoMarket.sellitem(
            nftAddress,
            erc20Token,
            msg.sender,
            tokenId,
            amount,
            price
        );
    }

    function buyItem(
        address nftAddress,
        address seller,
        uint256 tokenId,
        uint256 quantity
    ) external payable {
        validator(nftAddress, seller, tokenId);
        require(quantity > 0, "Media: Not Valid NFT id");
        require(seller != msg.sender, "Media: Owner not Allowed");
        epikoMarket.buyItem{value: msg.value}(
            nftAddress,
            seller,
            msg.sender,
            tokenId,
            quantity
        );
    }

    function createAuction(
        address nftAddress,
        address erc20Token,
        uint256 tokenId,
        uint256 amount,
        uint256 basePrice,
        uint256 endTime
    ) external {
        require(nftAddress != address(0), "Media: Address zero provided");
        require(tokenId > 0, "Media: Not Valid NFT id");
        require(amount > 0, "Media: Not Valid Quantity");
        require(basePrice > 0, "Media: BasePrice must be greater than 0");
        require(
            endTime > block.timestamp,
            "Media: endtime must be greater then current time"
        );
        uint256 startTime = block.timestamp;

        epikoMarket.createAuction(
            nftAddress,
            erc20Token,
            msg.sender,
            tokenId,
            amount,
            basePrice,
            endTime
        );
        emit AuctionCreated(
            nftAddress,
            tokenId,
            msg.sender,
            basePrice,
            amount,
            startTime,
            endTime
        );
    }

    function placeBid(
        address nftAddress,
        address seller,
        uint256 tokenId,
        uint256 price
    ) external payable {
        validator(nftAddress, seller, tokenId);
        epikoMarket.placeBid{value: msg.value}(
            nftAddress,
            msg.sender,
            seller,
            tokenId,
            price
        );
    }

    function approveBid(
        address nftAddress,
        address seller,
        uint256 tokenId,
        address bidder
    ) external {
        validator(nftAddress, seller, tokenId);

        epikoMarket.approveBid(nftAddress, seller, tokenId, bidder);
    }

    function claimNft(
        address nftAddress,
        address seller,
        uint256 tokenId
    ) external {
        validator(nftAddress, seller, tokenId);

        epikoMarket.claimNft(nftAddress, msg.sender, seller, tokenId);
    }

    function cancelBid(
        address nftAddress,
        address seller,
        uint256 tokenId
    ) external {
        validator(nftAddress, seller, tokenId);

        epikoMarket.cancelBid(nftAddress, msg.sender, seller, tokenId);
    }

    function revokeAuction(address nftAddress, uint256 tokenId) external {
        require(nftAddress != address(0), "Media: address zero provided");
        require(tokenId > 0, "Media: invalid tokenId");
        epikoMarket.revokeAuction(nftAddress, msg.sender, tokenId);
    }

    function cancelSell(address nftAddress, uint256 tokenId) external {
        validator(nftAddress, msg.sender, tokenId);

        epikoMarket.cancelSell(nftAddress, msg.sender, tokenId);
    }

    function cancelAuction(address nftAddress, uint256 tokenId) external {
        validator(nftAddress, msg.sender, tokenId);

        epikoMarket.cancelAuction(nftAddress, msg.sender, tokenId);
    }

    function validator(
        address nftAddress,
        address seller,
        uint256 tokenId
    ) internal pure {
        require(nftAddress != address(0), "Media: address zero provided");
        require(seller != address(0), "Media: address zero provided");
        require(tokenId > 0, "Media: provide valid tokenid");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

interface IMarket {
    struct Sale {
        uint256 itemId;
        uint256 tokenId;
        uint256 price;
        uint256 quantity;
        uint256 time;
        address nftContract;
        address erc20Token;
        address buyer;
        address seller;
        bool sold;
    }

    struct Auction {
        uint256 itemId;
        uint256 tokenId;
        uint256 startTime;
        uint256 endTime;
        uint256 basePrice;
        uint256 quantity;
        uint256 time;
        Bid[] bids;
        address seller;
        address nftContract;
        address erc20Token;
        bool sold;
        Bid highestBid;
    }

    struct Bid {
        address bidder;
        uint256 bid;
    }

    event Mint(address from, address to, uint256 indexed tokenId);
    event PlaceBid(
        address nftAddress,
        address bidder,
        uint256 price,
        uint256 tokenId
    );
    event MarketItemCreated(
        address indexed nftAddress,
        address indexed seller,
        uint256 price,
        uint256 indexed tokenId,
        uint256 quantity
    );
    event Buy(
        address indexed seller,
        address bidder,
        uint256 indexed price,
        uint256 indexed tokenId,
        uint256 quantity
    );
    event AuctionCreated(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 price,
        uint256 quantity,
        uint256 startTime,
        uint256 endTime
    );
    event CancelBid(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed bidder
    );

    function sellitem(
        address nftAddress,
        address erc20Token,
        address seller,
        uint256 tokenId,
        uint256 amount,
        uint256 price
    ) external;

    function buyItem(
        address nftAddress,
        address seller,
        address buyer,
        uint256 tokenId,
        uint256 quantity
    ) external payable;

    function createAuction(
        address nftAddress,
        address erc20Token,
        address seller,
        uint256 tokenId,
        uint256 amount,
        uint256 basePrice,
        uint256 endTime
    ) external;

    function placeBid(
        address nftAddress,
        address bidder,
        address seller,
        uint256 tokenId,
        uint256 price
    ) external payable;

    function approveBid(
        address nftAddress,
        address seller,
        uint256 tokenId,
        address bidder
    ) external;

    function claimNft(
        address nftAddress,
        address bidder,
        address seller,
        uint256 tokenId
    ) external;

    function cancelBid(
        address nftAddress,
        address _bidder,
        address seller,
        uint256 tokenId
    ) external;

    function cancelSell(
        address nftAddress,
        address seller,
        uint256 tokenId
    ) external;

    function cancelAuction(
        address nftAddress,
        address seller,
        uint256 tokenId
    ) external;

    function revokeAuction(
        address nftAddress,
        address seller,
        uint256 tokenId
    ) external;
}

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

interface IERC1155Minter is IERC1155,IERC2981{
    function getArtist(uint256 tokenId) external view returns(address);
    function burn(address from, uint256 id, uint256 amounts) external; 
    function mint(address to, uint256 amount, uint256 _royaltyFraction, string memory uri,bytes memory data)external returns(uint256);
    function _isExist(uint256 tokenId) external returns(bool);
}

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

interface IERC721Minter is IERC721,IERC2981{
    function mint(address to, uint256 royaltyFraction, string memory _uri)external returns(uint256);
    function burn(uint256 tokenId) external;
    function _isExist(uint256 tokenId)external view returns(bool);
    function isApprovedOrOwner(address spender, uint256 tokenId)external view returns(bool);
    function getArtist(uint256 tokenId)external view returns(address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}