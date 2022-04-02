/**
 *Submitted for verification at Etherscan.io on 2022-04-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

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
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

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
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

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
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

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
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

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

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol

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
     * by making the `nonReentrant` function external, and make it call a
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

// For future use to allow buyers to receive a discount depending on staking or other rules.
interface IDiscountManager {
    function getDiscount(address buyer)
        external
        view
        returns (uint256 discount);
}

contract ShiryoMarket is IERC1155Receiver, ReentrancyGuard {
    using SafeMath for uint256;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     modifier onlyClevel() {
        require(msg.sender == walletA || msg.sender == walletB || msg.sender == owner);
    _;
    }

    address walletA;
    address walletB;
    uint256 walletBPercentage = 20;

    using Counters for Counters.Counter;
    Counters.Counter public _itemIds; // Id for each individual item
    Counters.Counter private _itemsSold; // Number of items sold
    Counters.Counter private _itemsCancelled; // Number of items sold
    Counters.Counter private _offerIds; // Tracking offers

    address payable public owner; // The owner of the market contract
    address public discountManager = address(0x0); // a contract that can be callled to discover if there is a discount on the transaction fee.

    uint256 public saleFeePercentage = 5; // Percentage fee paid to team for each sale
    uint256 public accumulatedFee = 0;

    uint256 public volumeTraded = 0; // Total amount traded

    enum TokenType {
        ERC721, //0
        ERC1155, //1
        ERC20 //2
    }

    constructor() {
        owner = payable(msg.sender);
    }

    struct MarketOffer {
        uint256 offerId;
        uint256 itemId;
        address payable bidder;
        uint256 offerAmount;
        uint256 offerTime;
        bool cancelled;
        bool accepted;
    }

    struct MarketItem {
        uint256 itemId;
        address tokenContract;
        TokenType tokenType;
        uint256 tokenId; // 0 If token is ERC20
        uint256 amount; // 1 unless QTY of ERC20
        address payable seller;
        address payable buyer;
        string category;
        uint256 price;
        bool isSold;
        bool cancelled;
    }

    mapping(uint256 => MarketItem) public idToMarketItem;

    mapping(uint256 => uint256[]) public itemIdToMarketOfferIds;

    mapping(uint256 => MarketOffer) public offerIdToMarketOffer;

    mapping(address => uint256[]) public bidderToMarketOfferIds;

    mapping(address => bool) public approvedSourceContracts;

    event MarketItemCreated(
        uint256 indexed itemId,
        address indexed tokenContract,
        uint256 indexed tokenId,
        uint256 amount,
        address seller,
        address owner,
        string category,
        uint256 price
    );

    event MarketSaleCreated(
        uint256 indexed itemId,
        address indexed tokenContract,
        uint256 indexed tokenId,
        address seller,
        address buyer,
        string category,
        uint256 price
    );

    event ItemOfferCreated(
        uint256 indexed itemId,
        address indexed tokenContract,
        address owner,
        address bidder,
        uint256 bidAmount
    );

    // transfers one of the token types to/from the contracts
    function transferAnyToken(
        TokenType _tokenType,
        address _tokenContract,
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _amount
    ) internal {
        // type = 0
        if (_tokenType == TokenType.ERC721) {
            //IERC721(_tokenContract).approve(address(this), _tokenId);
            IERC721(_tokenContract).transferFrom(_from, _to, _tokenId);
            return;
        }

        // type = 1
        if (_tokenType == TokenType.ERC1155) {
            IERC1155(_tokenContract).safeTransferFrom(
                _from,
                _to,
                _tokenId,
                1,
                ""
            ); // amount - only 1 of an ERC1155 per item
            return;
        }

        // type = 2
        if (_tokenType == TokenType.ERC20) {
            if (_from==address(this)){
                IERC20(_tokenContract).approve(address(this), _amount);
            }
            IERC20(_tokenContract).transferFrom(_from, _to, _amount); // amount - ERC20 can be multiple tokens per item (bundle)
            return;
        }
    }

   // market item functions
    
    // creates a market item by transferring it from the originating contract
    // the amount will be 1 for ERC721 or ERC1155
    // amount could be more for ERC20
    function createMarketItem(
        address _tokenContract,
        TokenType _tokenType,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _price,
        string calldata _category
    ) public nonReentrant {
        require(_price > 0, "No item for free here");
        require(_amount > 0, "At least one token");
        require(approvedSourceContracts[_tokenContract]==true,"Token contract not approved");

        _itemIds.increment();
        uint256 itemId = _itemIds.current();
        idToMarketItem[itemId] = MarketItem(
            itemId,
            _tokenContract,
            _tokenType,
            _tokenId,
            _amount,
            payable(msg.sender),
            payable(address(0)), // No owner for the item
            _category,
            _price,
            false,
            false
        );

        transferAnyToken(
            _tokenType,
            _tokenContract,
            msg.sender,
            address(this),
            _tokenId,
            _amount
        );

        emit MarketItemCreated(
            itemId,
            _tokenContract,
            _tokenId,
            _amount,
            msg.sender,
            address(0),
            _category,
            _price
        );
    }

    // cancels a market item that's for sale
    function cancelMarketItem(uint256 itemId) public {
        require(itemId <= _itemIds.current());
        require(idToMarketItem[itemId].seller == msg.sender);
        require(
            idToMarketItem[itemId].cancelled == false &&
                idToMarketItem[itemId].isSold == false
        );

        idToMarketItem[itemId].cancelled = true;
        _itemsCancelled.increment();

        transferAnyToken(
            idToMarketItem[itemId].tokenType,
            idToMarketItem[itemId].tokenContract,
            address(this),
            msg.sender,
            idToMarketItem[itemId].tokenId,
            idToMarketItem[itemId].amount
        );
    }

    // buys an item at it's current sale value

    function createMarketSale(uint256 itemId) public payable nonReentrant {
        uint256 price = idToMarketItem[itemId].price;
        uint256 tokenId = idToMarketItem[itemId].tokenId;
        require(
            msg.value == price,
            "Not the correct message value"
        );
        require(
            idToMarketItem[itemId].isSold == false,
            "This item is already sold."
        );
        require(
            idToMarketItem[itemId].cancelled == false,
            "This item is not for sale."
        );
        require(
            idToMarketItem[itemId].seller != msg.sender,
            "Cannot buy your own item."
        );

        // take fees and transfer the balance to the seller (TODO)
        uint256 fees = SafeMath.div(price, 100).mul(saleFeePercentage);

        if (discountManager != address(0x0)) {
            // how much discount does this user get?
            uint256 feeDiscountPercent = IDiscountManager(discountManager)
                .getDiscount(msg.sender);
            fees = fees.div(100).mul(feeDiscountPercent);
        }

        uint256 saleAmount = price.sub(fees);
        idToMarketItem[itemId].seller.transfer(saleAmount);
        accumulatedFee+=fees;

        transferAnyToken(
            idToMarketItem[itemId].tokenType,
            idToMarketItem[itemId].tokenContract,
            address(this),
            msg.sender,
            tokenId,
            idToMarketItem[itemId].amount
        );

        idToMarketItem[itemId].isSold = true;
        idToMarketItem[itemId].buyer = payable(msg.sender);

        _itemsSold.increment();
        volumeTraded = volumeTraded.add(price);

        emit MarketSaleCreated(
            itemId,
            idToMarketItem[itemId].tokenContract,
            tokenId,
            idToMarketItem[itemId].seller,
            msg.sender,
            idToMarketItem[itemId].category,
            price
        );
    }

    function getMarketItemsByPage(uint256 _from, uint256 _to) external view returns (MarketItem[] memory) {
        require(_from < _itemIds.current() && _to <= _itemIds.current(), "Page out of range.");

        uint256 itemCount;
        for (uint256 i = _from; i <= _to; i++) {
            if (
                idToMarketItem[i].buyer == address(0) &&
                idToMarketItem[i].cancelled == false &&
                idToMarketItem[i].isSold == false
            ){
                itemCount++;
            }
        }

        uint256 currentIndex = 0;
        MarketItem[] memory marketItems = new MarketItem[](itemCount);
        for (uint256 i = _from; i <= _to; i++) {

             if (
                idToMarketItem[i].buyer == address(0) &&
                idToMarketItem[i].cancelled == false &&
                idToMarketItem[i].isSold == false
            ){
                uint256 currentId = idToMarketItem[i].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                marketItems[currentIndex] = currentItem;
                currentIndex += 1;
            }

        }
        return marketItems;
    }

    // returns all of the current items for sale
    function getMarketItems() external view returns (MarketItem[] memory) {
        uint256 itemCount = _itemIds.current();
        uint256 unsoldItemCount = _itemIds.current() -
            (_itemsSold.current() + _itemsCancelled.current());
        uint256 currentIndex = 0;

        MarketItem[] memory marketItems = new MarketItem[](unsoldItemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            if (
                idToMarketItem[i + 1].buyer == address(0) &&
                idToMarketItem[i + 1].cancelled == false &&
                idToMarketItem[i + 1].isSold == false
            ) {
                uint256 currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                marketItems[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return marketItems;
    }

    // returns all itemsby seller and
    function getMarketItemsBySeller(address _seller)
        external
        view
        returns (MarketItem[] memory)
    {
        uint256 totalItemCount = _itemIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (
                idToMarketItem[i + 1].seller == _seller &&
                idToMarketItem[i + 1].cancelled == false &&
                idToMarketItem[i + 1].isSold == false //&&
                //idToMarketItem[i + 1].tokenContract == _tokenContract
            ) {
                itemCount += 1; // No dynamic length. Predefined length has to be made
            }
        }

        MarketItem[] memory marketItems = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (
                idToMarketItem[i + 1].seller == _seller &&
                idToMarketItem[i + 1].cancelled == false &&
                idToMarketItem[i + 1].isSold == false //&&
                //idToMarketItem[i + 1].tokenContract == _tokenContract
            ) {
                uint256 currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                marketItems[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return marketItems;
    }

       // returns all itemsby seller and
    function getMarketItemsBySellerByPage(address _seller, uint256 _from , uint256 _to)
        external
        view
        returns (MarketItem[] memory)
    {
        require(_from < _itemIds.current() && _to <= _itemIds.current(), "Page out of range.");

        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = _from; i <= _to; i++) {
            if (
                idToMarketItem[i].seller == _seller &&
                idToMarketItem[i].cancelled == false &&
                idToMarketItem[i].isSold == false //&&
            ) {
                itemCount += 1; // No dynamic length. Predefined length has to be made
            }
        }

        MarketItem[] memory marketItems = new MarketItem[](itemCount);
        for (uint256 i =  _from; i <= _to; i++) {
            if (
                idToMarketItem[i].seller == _seller &&
                idToMarketItem[i].cancelled == false &&
                idToMarketItem[i].isSold == false //&&
            ) {
                uint256 currentId = idToMarketItem[i].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                marketItems[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return marketItems;
    }

    // Get items by category
    // This could be used with different collections
    function getItemsByCategory(string calldata category)
        external
        view
        returns (MarketItem[] memory)
    {
        uint256 totalItemCount = _itemIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (
                keccak256(abi.encodePacked(idToMarketItem[i + 1].category)) ==
                keccak256(abi.encodePacked(category)) &&
                idToMarketItem[i + 1].buyer == address(0) &&
                idToMarketItem[i + 1].cancelled == false &&
                idToMarketItem[i + 1].isSold == false
            ) {
                itemCount += 1;
            }
        }

        MarketItem[] memory marketItems = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (
                keccak256(abi.encodePacked(idToMarketItem[i + 1].category)) ==
                keccak256(abi.encodePacked(category)) &&
                idToMarketItem[i + 1].buyer == address(0) &&
                idToMarketItem[i + 1].cancelled == false &&
                idToMarketItem[i + 1].isSold == false
            ) {
                uint256 currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                marketItems[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return marketItems;
    }

       // returns the total number of items sold
    function getItemsSold() external view returns (uint256) {
        return _itemsSold.current();
    }

    // returns the current number of listed items
    function numberOfItemsListed() external view returns (uint256) {
        uint256 unsoldItemCount = _itemIds.current() -
            (_itemsSold.current() + _itemsCancelled.current());
        return unsoldItemCount;
    }



    // Offers functions
    // make offer
    // cancel offer
    // accept offer
    // offersByItem
    // offersByBidder


    function makeItemOffer(uint256 _itemId) public payable nonReentrant {
        require(
            idToMarketItem[_itemId].tokenContract != address(0x0) &&
                idToMarketItem[_itemId].isSold == false &&
                idToMarketItem[_itemId].cancelled == false,
            "Invalid item id."
        );
        require(msg.value > 0, "Can't offer nothing.");

        _offerIds.increment();
        uint256 offerId = _offerIds.current();

        MarketOffer memory offer = MarketOffer(
            offerId,
            _itemId,
            payable(msg.sender),
            msg.value,
            block.timestamp,
            false,
            false
        );

        offerIdToMarketOffer[offerId] = offer;
        itemIdToMarketOfferIds[_itemId].push(offerId);
        bidderToMarketOfferIds[msg.sender].push(offerId);

        emit ItemOfferCreated(
            _itemId,
            idToMarketItem[_itemId].tokenContract,
            idToMarketItem[_itemId].seller,
            msg.sender,
            msg.value
        );
    }

    function acceptItemOffer(uint256 _offerId) public nonReentrant {
        uint256 itemId = offerIdToMarketOffer[_offerId].itemId;

        require(idToMarketItem[itemId].seller == msg.sender, "Not item seller");

        require(
            offerIdToMarketOffer[_offerId].accepted == false &&
                offerIdToMarketOffer[_offerId].cancelled == false,
            "Already accepted or cancelled."
        );

        uint256 price = offerIdToMarketOffer[_offerId].offerAmount;
        address bidder = payable(offerIdToMarketOffer[_offerId].bidder);

        uint256 fees = SafeMath.div(price, 100).mul(saleFeePercentage);

        // fees and payment
        if (discountManager != address(0x0)) {
            // how much discount does this user get?
            uint256 feeDiscountPercent = IDiscountManager(discountManager)
                .getDiscount(msg.sender);
            fees = fees.div(100).mul(feeDiscountPercent);
        }

        uint256 saleAmount = price.sub(fees);
        payable(msg.sender).transfer(saleAmount);
        if (fees > 0) {
            accumulatedFee+=fees;
        }

        transferAnyToken(
            idToMarketItem[itemId].tokenType,
            idToMarketItem[itemId].tokenContract,
            address(this),
            offerIdToMarketOffer[_offerId].bidder,
            idToMarketItem[itemId].tokenId,
            idToMarketItem[itemId].amount
        );

        offerIdToMarketOffer[_offerId].accepted = true;
        
        idToMarketItem[itemId].isSold = true;
        idToMarketItem[itemId].buyer = offerIdToMarketOffer[_offerId].bidder;

        _itemsSold.increment();

        emit MarketSaleCreated(
            itemId,
            idToMarketItem[itemId].tokenContract,
            idToMarketItem[itemId].tokenId,
            msg.sender,
            bidder,
            idToMarketItem[itemId].category,
            price
        );

        volumeTraded = volumeTraded.add(price);
    }

    function canceItemOffer(uint256 _offerId) public nonReentrant {
        require(
            offerIdToMarketOffer[_offerId].bidder == msg.sender &&
                offerIdToMarketOffer[_offerId].cancelled == false,
            "Wrong bidder or offer is already cancelled"
        );
        require(
            offerIdToMarketOffer[_offerId].accepted == false,
            "Already accepted."
        );

        address bidder = offerIdToMarketOffer[_offerId].bidder;

        offerIdToMarketOffer[_offerId].cancelled = true;
        payable(bidder).transfer(offerIdToMarketOffer[_offerId].offerAmount);

        //TODO emit
    }

     function getOffersByBidder(address _bidder)
        external
        view
        returns (MarketOffer[] memory)
    {
        uint256 openOfferCount = 0;
        uint256[] memory itemOfferIds = bidderToMarketOfferIds[_bidder];

        for (uint256 i = 0; i < itemOfferIds.length; i++) {
            if (
                offerIdToMarketOffer[itemOfferIds[i]].accepted == false &&
                offerIdToMarketOffer[itemOfferIds[i]].cancelled == false
            ) {
                openOfferCount++;
            }
        }

        MarketOffer[] memory openOffers = new MarketOffer[](openOfferCount);
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < itemOfferIds.length; i++) {
            if (
                offerIdToMarketOffer[itemOfferIds[i]].accepted == false &&
                offerIdToMarketOffer[itemOfferIds[i]].cancelled == false
            ) {
                MarketOffer memory currentItem = offerIdToMarketOffer[
                    itemOfferIds[i]
                ];
                openOffers[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return openOffers;
    }

     function getTotalOffersMadeByBidder(address _bidder) external view returns (uint256){
         return bidderToMarketOfferIds[_bidder].length;
     }

     function getOpenOffersByBidderByPage(address _bidder, uint256 _from , uint256 _to)
        external
        view
        returns (MarketOffer[] memory)
    {
        uint256 openOfferCount = 0;
        uint256[] memory itemOfferIds = bidderToMarketOfferIds[_bidder];

        for (uint256 i = _from; i <= _to; i++) {
            if (
                offerIdToMarketOffer[itemOfferIds[i]].accepted == false &&
                offerIdToMarketOffer[itemOfferIds[i]].cancelled == false
            ) {
                openOfferCount++;
            }
        }

        MarketOffer[] memory openOffers = new MarketOffer[](openOfferCount);
        uint256 currentIndex = 0;
        for (uint256 i = _from; i <= _to; i++) {
            if (
                offerIdToMarketOffer[itemOfferIds[i]].accepted == false &&
                offerIdToMarketOffer[itemOfferIds[i]].cancelled == false
            ) {
                MarketOffer memory currentItem = offerIdToMarketOffer[
                    itemOfferIds[i]
                ];
                openOffers[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return openOffers;
    }

    function getItemOffers(uint256 _itemId)
        external
        view
        returns (MarketOffer[] memory)
    {
        uint256 openOfferCount = 0;
        uint256[] memory itemOfferIds = itemIdToMarketOfferIds[_itemId];

        for (uint256 i = 0; i < itemOfferIds.length; i++) {
            if (
                offerIdToMarketOffer[itemOfferIds[i]].accepted == false &&
                offerIdToMarketOffer[itemOfferIds[i]].cancelled == false
            ) {
                openOfferCount++;
            }
        }

        MarketOffer[] memory openOffers = new MarketOffer[](openOfferCount);
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < itemOfferIds.length; i++) {
            if (
                offerIdToMarketOffer[itemOfferIds[i]].accepted == false &&
                offerIdToMarketOffer[itemOfferIds[i]].cancelled == false
            ) {
                MarketOffer memory currentItem = offerIdToMarketOffer[
                    itemOfferIds[i]
                ];
                openOffers[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return openOffers;
    }

    // administration functions
    function setSalePercentageFee(uint256 _amount) public onlyOwner {
        require(_amount <= 5, "5% maximum fee allowed.");
        saleFeePercentage = _amount;
    }

    function setOwner(address _owner) public onlyOwner {
        require(_owner != address(0x0), "0x0 address not permitted");
        owner = payable(_owner);
    }

    function setDiscountManager(address _discountManager) public onlyOwner {
        require(_discountManager != address(0x0), "0x0 address not permitted");
        discountManager = _discountManager;
    }

    function setSourceContractApproved(address _tokenContract, bool _approved) external onlyOwner {
        approvedSourceContracts[_tokenContract]=_approved;
    }


    // IERC1155Receiver implementations

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }


    function supportsInterface(bytes4 interfaceId) override external pure returns (bool){
            return interfaceId == type(IERC1155Receiver).interfaceId
            || true;
    }

    function withdraw_all() external onlyClevel {
        require (accumulatedFee > 0);
        uint256 amountB = SafeMath.div(accumulatedFee,100).mul(walletBPercentage);
        uint256 amountA = accumulatedFee.sub(amountB);
        accumulatedFee = 0;
        payable(walletA).transfer(amountA);
        payable(walletB).transfer(amountB);
    }

    function setWalletA(address _walletA) external onlyOwner {
        require (_walletA != address(0x0), "Invalid wallet");
        walletA = _walletA;
    }

    function setWalletB(address _walletB) external onlyOwner {
        require (_walletB != address(0x0), "Invalid wallet.");
        walletB = _walletB;
    }

    function setWalletBPercentage(uint256 _percentage) external onlyOwner {
        require (_percentage>walletBPercentage && _percentage<=100, "Invalid new slice.");
        walletBPercentage = _percentage;
    }

}

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

library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
     * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}