// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import the NPM modules (Remix/Truffle compliant)

import "../node_modules/@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/utils/Counters.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

contract MarketplaceETH is Ownable {
  
    struct MarketplaceItem {
        uint256 id;
        address tokenAddress;
        uint256 tokenId;
        address payable seller;
        uint256 askingPriceETH;
        uint256 askingPriceUSDT;
        bool isSold;
    }

    // Define the token address of the UIM currency

    address public USDT_CONTRACT;
    address payable public TAX_COLLECTOR;

    MarketplaceItem[] public itemsForSale;

    mapping(address => mapping(uint256 => bool)) activeItems;
    mapping(address => bool) acceptedNftContracts;

    event ItemAddedForSale(
        uint256 id,
        uint256 tokenId,
        address tokenAddress,
        uint256 askingPriceETH,
        uint256 askingPriceUSDT
    );

    event ItemSold(uint256 id, address buyer);
    event ItemSoldETH(uint256 id, address buyer, uint256 sellerCut, uint256 fee);
    event ItemSoldUSDT(uint256 id, address buyer, uint256 sellerCut, uint256 fee);

    constructor(
        address _USDT_CONTRACT,
        address payable _TAX_COLLECTOR
    ) {
        USDT_CONTRACT = _USDT_CONTRACT;
        TAX_COLLECTOR = _TAX_COLLECTOR;
    }

    // Make sure only the NFT owner can execute operations

    modifier OnlyItemOwner(address tokenAddress, uint256 tokenId) {
        IERC721 tokenContract = IERC721(tokenAddress);
        require(tokenContract.ownerOf(tokenId) == msg.sender);
        _;
    }

    // Make sure the NFT owner has transfer approval for the said NFT

    modifier HasTransferApproval(address tokenAddress, uint256 tokenId) {
        IERC721 tokenContract = IERC721(tokenAddress);
        require(tokenContract.getApproved(tokenId) == address(this));
        _;
    }

    // Make sure the itemsForSale struct array contains the item UID

    modifier ItemExists(uint256 id) {
        require(
            id < itemsForSale.length && itemsForSale[id].id == id,
            "Could not find item"
        );
        _;
    }

    // Make sure the item is actually for sale and not sold

    modifier isForSale(uint256 id) {
        require(itemsForSale[id].isSold == false, "Item is already sold");
        _;
    }

    function modifyAcceptedContractAddress(address contractAddress, bool value)
        external
        onlyOwner
    {
        acceptedNftContracts[contractAddress] = value;
    }

    // In order to not start deleting stuff from the array, when removing an item from the marketplace it is instead marked as Sold without any transferring events and emits an ItemSold event so that Moralis flags the respective item as sold and hides it from the "Buy" page

    function removeUidFromMarket(uint256 uidListing) external returns (bool) {
        require(
            itemsForSale[uidListing].isSold == false,
            "Item is already sold/removed"
        );

        require(
            itemsForSale[uidListing].seller == msg.sender,
            "Only the seller can remove a item from listing"
        );

        itemsForSale[uidListing].isSold = true;

        activeItems[itemsForSale[uidListing].tokenAddress][
            itemsForSale[uidListing].tokenId
        ] = false;

        emit ItemSold(uidListing, msg.sender);

        return true;
    }

    function addItemToMarket(
        uint256 tokenId,
        address tokenAddress,
        uint256 askingPriceETH,
        uint256 askingPriceUSDT
    )
        external
        OnlyItemOwner(tokenAddress, tokenId)
        HasTransferApproval(tokenAddress, tokenId)
        returns (uint256 id)
    {
        require(
            acceptedNftContracts[tokenAddress] == true,
            "This token contract is not whitelisted on the marketplace"
        );

        // Check if item is not already for sale

        require(
            activeItems[tokenAddress][tokenId] == false,
            "Item is already for sale"
        );

        // Create the new ID for the itemsForSale

        uint256 newItemId = itemsForSale.length;

        // Pus the new MarketplaceItem to the itemsForSale struct array

        itemsForSale.push(
            MarketplaceItem(
                newItemId,
                tokenAddress,
                tokenId,
                payable(msg.sender),
                askingPriceETH,
                askingPriceUSDT,
                false
            )
        );

        // Mark this NFT as active

        activeItems[tokenAddress][tokenId] = true;

        // Check if the last item pushed in the itemsForSale

        assert(itemsForSale[newItemId].id == newItemId);

        emit ItemAddedForSale(
            newItemId,
            tokenId,
            tokenAddress,
            askingPriceETH,
            askingPriceUSDT
        );
        return newItemId;
    }

    // Calculate x * y / scale rounding down.
    function mulScale(
        uint256 x,
        uint256 y,
        uint128 scale
    ) internal pure returns (uint256) {
        uint256 a = x / scale;
        uint256 b = x % scale;
        uint256 c = y / scale;
        uint256 d = y % scale;

        return a * c * scale + a * d + b * c + (b * d) / scale;
    }

    function buyItemETH(uint256 id)
        external
        payable
        ItemExists(id)
        isForSale(id)
        HasTransferApproval(
            itemsForSale[id].tokenAddress,
            itemsForSale[id].tokenId
        )
        returns (bool)
    {
        // Prevent the seller from buying his own item

        require(msg.sender != itemsForSale[id].seller);

        // Mark the item as sold

        itemsForSale[id].isSold = true;

        // Mark the item as inactive

        activeItems[itemsForSale[id].tokenAddress][
            itemsForSale[id].tokenId
        ] = false;

        // Transfer the NFT from the seller to the buyer based on the previous approval

        IERC721(itemsForSale[id].tokenAddress).safeTransferFrom(
            itemsForSale[id].seller,
            msg.sender,
            itemsForSale[id].tokenId
        );

        // Transfer the ETH to the buyer from the seller and the fee to the TAX Collector

        uint256 fee = mulScale(25, itemsForSale[id].askingPriceETH, 1000);
        uint256 sellerRemaining = itemsForSale[id].askingPriceETH - fee;

         (bool sent, bytes memory data) = itemsForSale[id].seller.call{value: sellerRemaining}("");
        require(sent, "Failed to send Ether for seller");


         (bool sent1, bytes memory data2) = TAX_COLLECTOR.call{value: fee}("");
        require(sent, "Failed to send Ether for tax");
        


        emit ItemSoldETH(id, msg.sender, sellerRemaining, fee);
    }

    function buyItemUSDT(uint256 id)
        external
        
        ItemExists(id)
        isForSale(id)
        HasTransferApproval(
            itemsForSale[id].tokenAddress,
            itemsForSale[id].tokenId
        )
    {
        require(msg.sender != itemsForSale[id].seller);

        itemsForSale[id].isSold = true;

        activeItems[itemsForSale[id].tokenAddress][
            itemsForSale[id].tokenId
        ] = false;

        uint256 fee = mulScale(25, itemsForSale[id].askingPriceUSDT, 1000);
        uint256 sellerRemaining = itemsForSale[id].askingPriceUSDT - fee;

        IERC20(USDT_CONTRACT).transferFrom(
            msg.sender,
            itemsForSale[id].seller,
            sellerRemaining
        );

        IERC20(USDT_CONTRACT).transferFrom(
            msg.sender,
            TAX_COLLECTOR,
            fee
        );

        IERC721(itemsForSale[id].tokenAddress).safeTransferFrom(
            itemsForSale[id].seller,
            msg.sender,
            itemsForSale[id].tokenId
        );

        emit ItemSoldUSDT(id, msg.sender, sellerRemaining, fee);
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