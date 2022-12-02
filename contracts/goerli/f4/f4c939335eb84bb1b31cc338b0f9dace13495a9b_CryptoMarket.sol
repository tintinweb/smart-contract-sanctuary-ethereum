/**
 *Submitted for verification at Etherscan.io on 2022-12-02
*/

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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: logic.sol

// File: marketplace.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;




interface EIERC721 is IERC721 {
    function safeMint(address to, uint256 tokenId) external;
}

interface Storage {
    struct MarketToken {
    uint256 itemId;
     uint256 tokenId;
     string uri;
     address nftContract;
     address payable owner;
     address payable creater;
     address payable prev_owner;
     uint256 price;
     uint256 copyid;
     uint royalities;
     uint256 time;//this says the time for auction
     address payable bidder;
     bool sell; // this is bool statement to keep it for sale or not
     bool is_fixed;//this says that item is for fixed price or not
     bool is_single;//this says item is single or multiples
     bool is_timed;//this says that the item is for timed auction
     
}

    function create_market_items(
        uint256 tokenId,
        string memory uri,
        address nftContract,
        uint256 royalities,
        address owner_item,
        address creater,
        bool is_single,
        uint256 copyid
    ) external;

    function get_items() external view returns (MarketToken[] memory);

    function edit_market_items(uint256 i, MarketToken memory market_token)
        external;

    function get_items_by_id(uint256 item_id)
        external
        view
        returns (MarketToken memory);

    function update_owner(uint256 tokenId, address owner) external;

    function update_prev_owner(uint256 tokenId, address prev_owner) external;

    function update_price(uint256 tokenId, uint256 price) external;

    function update_royalities(uint256 tokenId, uint256 royalities) external;

    function update_time(uint256 tokenId, uint256 time) external;

    function update_bidder(uint256 tokenId, address bidder) external;

    function update_sell(uint256 tokenId, bool sell) external;

    function update_is_fixed(uint256 tokenId, bool is_fixed) external;

    function update_is_timed(uint256 tokenId, bool is_timed) external;

    function update_is_single(uint256 tokenId, bool is_single) external;
}

contract CryptoMarket is ReentrancyGuard {
    uint256 public n;
    uint256 public commission_for_marketplace;
    address payable public owner;
    address public storage_addr = 0xd9145CCE52D386f254917e481eB44e9943F39138;
    Storage public storage_contract = Storage(storage_addr);

    constructor() {
        owner = payable(msg.sender);
        n = 0;
        commission_for_marketplace = 0;
    }
    function change_storage(address addr) public {
        require(msg.sender == owner);
        storage_addr = addr;
    }
    function transferOwner(address beneficiary) public {
        require(msg.sender == owner);
        owner = payable(beneficiary);
    }

    function setCommission(uint256 fee) public {
        require(msg.sender == owner);
        commission_for_marketplace = fee;
    }

    event create_market_items_for_erc721(
        uint256 indexed itemId,
        address,
        uint256
    );
    event create_market_items_for_erc1155(
        uint256 indexed itemId,
        address,
        uint256,
        uint256
    );
    event create_market_sale(
        uint256 indexed,
        uint256,
        address indexed,
        address indexed
    );
    event keep_for_sale(uint256 indexed itemId, uint256);
    event keep_for_timed_auction(uint256 indexed itemId, uint256, uint256);
    event keep_for_open_bid(uint256 indexed itemId, uint256);
    event bid(uint256 indexed itemId, uint256, address indexed);
    event burn_token(uint256 indexed);
    event cancel_sale(uint256 indexed);
    event makeoffer(uint256 indexed, uint256, address indexed);
    event claimoffer(
        uint256 indexed,
        uint256,
        address indexed,
        address indexed
    );
    event approveoffer(
        uint256 indexed,
        uint256,
        address indexed,
        address indexed
    );

    function create_market_item_for_erc721(
        uint256 tokenId,
        string memory uri,
        address nftContract,
        uint256 royalities
    ) public {
        storage_contract.create_market_items(
            tokenId,
            uri,
            nftContract,
            royalities,
            msg.sender,
            msg.sender,
            true,
            0
        );
        // EIERC721(nftContract).safeMint(payable(msg.sender), tokenId);
        emit create_market_items_for_erc721(n, nftContract, royalities);
    }

    function createMarketSale_erc721(uint256 itemId)
        public
        payable
        nonReentrant
    {
        uint256 price = storage_contract.get_items_by_id(itemId).price;
        uint256 royality = storage_contract.get_items_by_id(itemId).royalities;

        uint256 commission = commission_for_marketplace;

        require(
            msg.value >= price,
            "Please submit the asking price in order to continuee the transcation"
        );

        require(
            storage_contract.get_items_by_id(itemId).sell == true,
            "this is not for sale"
        );

        require(
            storage_contract.get_items_by_id(itemId).is_single == true,
            "this is not erc1155 token"
        );

        if (storage_contract.get_items_by_id(itemId).is_fixed == true) {
            storage_contract.update_prev_owner(itemId,storage_contract.get_items_by_id(itemId).owner) ;

            storage_contract.get_items_by_id(itemId).owner.transfer(
                (price / 10000) * (10000 - commission - royality)
            );

            storage_contract.get_items_by_id(itemId).creater.transfer(
                (price / 10000) * royality
            );

            owner.transfer((price / 10000) * (commission));

            storage_contract.update_owner(itemId, payable( msg.sender)) ;
            storage_contract.update_sell(itemId, false);

            storage_contract.update_price(itemId, 0);

            EIERC721(storage_contract.get_items_by_id(itemId).nftContract)
                .safeTransferFrom(
                    storage_contract.get_items_by_id(itemId).prev_owner,
                    msg.sender,
                    storage_contract.get_items_by_id(itemId).tokenId
                );
        } else {
            require(
                msg.sender == storage_contract.get_items_by_id(itemId).bidder,
                "your not a auction winner"
            );

            storage_contract.update_prev_owner(itemId, storage_contract.get_items_by_id(itemId).owner);

            storage_contract.get_items_by_id(itemId).owner.transfer(
                (price / 10000) * (10000 - commission - royality)
            );

            storage_contract.get_items_by_id(itemId).creater.transfer(
                (price / 10000) * royality
            );

            owner.transfer((price / 10000) * (commission));

            storage_contract.update_owner(itemId, payable( msg.sender));

            storage_contract.update_sell(itemId, !true);

            storage_contract.update_owner(itemId, payable(0x00));

            storage_contract.update_price(itemId, 0) ;

            EIERC721(storage_contract.get_items_by_id(itemId).nftContract)
                .safeTransferFrom(
                    storage_contract.get_items_by_id(itemId).prev_owner,
                    msg.sender,
                    storage_contract.get_items_by_id(itemId).tokenId
                );
        }

        emit create_market_sale(
            itemId,
            price,
            msg.sender,
            storage_contract.get_items_by_id(itemId).prev_owner
        );
    }

    function keepForSale(uint256 itemId, uint256 price) public {
        require(storage_contract.get_items_by_id(itemId).is_fixed == false);

        require(
            msg.sender == storage_contract.get_items_by_id(itemId).owner,
            "your are not owner of nfts"
        );

        require(
            storage_contract.get_items_by_id(itemId).sell == false,
            "it is already in sale"
        );

        storage_contract.update_price(itemId, price);

        storage_contract.update_sell(itemId, true);

        storage_contract.update_is_fixed(itemId, true);

        storage_contract.update_is_timed(itemId, !true);

        emit keep_for_sale(itemId, price);
    }

    function create_market_items_erc1155(
        uint256 tokenId,
        string memory uri,
        address nftContract,
        uint256 royalities,
        uint256 copies
    ) public {
        for (uint256 i = 1; copies >= i; i++) {
            storage_contract.create_market_items(
                tokenId,
                uri,
                nftContract,
                royalities,
                payable(msg.sender),
                payable(msg.sender),
                true,
                i
            );
            emit create_market_items_for_erc1155(
                n,
                nftContract,
                royalities,
                copies
            );
        }
    }

    function createMarketSale_erc1155(uint256 itemId)
        public
        payable
        nonReentrant
    {
        uint256 price = storage_contract.get_items_by_id(itemId).price;

        uint256 royality = storage_contract.get_items_by_id(itemId).royalities;

        uint256 commission = commission_for_marketplace;

        require(
            msg.value >= price,
            "Please submit the asking price in order to continuee the transcation"
        );

        require(
            storage_contract.get_items_by_id(itemId).sell == true,
            "this is not for sale"
        );

        require(
            storage_contract.get_items_by_id(itemId).is_single == false,
            "this is not erc1155 token"
        );

        if (storage_contract.get_items_by_id(itemId).is_fixed == true) {
            storage_contract.update_prev_owner(itemId,storage_contract.get_items_by_id(itemId).owner) ;

            storage_contract.get_items_by_id(itemId).owner.transfer(
                (price / 10000) * (10000 - commission - royality)
            );

            storage_contract.get_items_by_id(itemId).creater.transfer(
                (price / 10000) * royality
            );

            owner.transfer((price / 10000) * (commission));

            storage_contract.update_owner(itemId, payable( msg.sender)) ;

            storage_contract.update_sell(itemId, !true);

            storage_contract.update_price(itemId, 0) ;

            IERC1155(storage_contract.get_items_by_id(itemId).nftContract)
                .safeTransferFrom(
                    storage_contract.get_items_by_id(itemId).prev_owner,
                    msg.sender,
                    storage_contract.get_items_by_id(itemId).tokenId,
                    1,
                    "0X00"
                );
        } else {
            require(
                msg.sender == storage_contract.get_items_by_id(itemId).bidder,
                "your not a auction winner"
            );

            storage_contract.update_prev_owner(itemId,storage_contract.get_items_by_id(itemId).owner) ;

            storage_contract.get_items_by_id(itemId).owner.transfer(
                (price / 10000) * (10000 - commission - royality)
            );

            storage_contract.get_items_by_id(itemId).creater.transfer(
                (price / 10000) * royality
            );

            owner.transfer((price / 10000) * (commission));

            storage_contract.update_owner(itemId, payable( msg.sender));

            storage_contract.update_sell(itemId, !true) ;

            storage_contract.update_price(itemId, 0);

            storage_contract.update_owner(itemId, payable(0x00));

            IERC1155(storage_contract.get_items_by_id(itemId).nftContract)
                .safeTransferFrom(
                    storage_contract.get_items_by_id(itemId).prev_owner,
                    msg.sender,
                    storage_contract.get_items_by_id(itemId).tokenId,
                    1,
                    "0X00"
                );
        }

        emit create_market_sale(
            itemId,
            price,
            msg.sender,
            storage_contract.get_items_by_id(itemId).prev_owner
        );
    }

    function timed_bid(uint256 itemId, uint256 price) public {
        require(
            msg.sender != storage_contract.get_items_by_id(itemId).owner ||
                storage_contract.get_items_by_id(itemId).owner != payable(0x00)
        );

        require(storage_contract.get_items_by_id(itemId).sell == true);

        require(check_auction_completed(itemId) == false);

        require(
            storage_contract.get_items_by_id(itemId).is_fixed == false,
            "not for timed auction"
        );

        require(storage_contract.get_items_by_id(itemId).is_timed == true);

        require(
            storage_contract.get_items_by_id(itemId).price < price,
            "bid for higher price"
        );

        storage_contract.update_price(itemId, price) ;

        storage_contract.update_owner(itemId, payable(msg.sender)) ;

        emit bid(itemId, price, msg.sender);
    }

    function open_bid(uint256 itemId, uint256 price) public {
        require(
            msg.sender != storage_contract.get_items_by_id(itemId).owner ||
                storage_contract.get_items_by_id(itemId).owner != payable(0x00)
        );

        require(storage_contract.get_items_by_id(itemId).sell == true);

        require(
            storage_contract.get_items_by_id(itemId).is_fixed == false,
            "not for auction"
        );

        require(storage_contract.get_items_by_id(itemId).is_timed == false);

        require(
            (storage_contract.get_items_by_id(itemId).price) < price,
            "bid for higher price"
        );

        storage_contract.update_price(itemId, price);

        storage_contract.update_owner(itemId, payable(msg.sender)) ;

        emit bid(itemId, price, msg.sender);
    }

    function check_auction_completed(uint256 itemId)
        public
        view
        returns (bool)
    {
        require(storage_contract.get_items_by_id(itemId).sell == true);

        require(storage_contract.get_items_by_id(itemId).is_fixed == false);

        require(storage_contract.get_items_by_id(itemId).is_timed == true);

        if (storage_contract.get_items_by_id(itemId).time <= block.timestamp) {
            return true;
        } else {
            return false;
        }
    }

    function keep_for_timedauction(
        uint256 itemId,
        uint256 time,
        uint256 price
    ) public {
        require(
            storage_contract.get_items_by_id(itemId).owner == msg.sender,
            "you can't annonce for auction"
        );

        require(
            storage_contract.get_items_by_id(itemId).sell == false,
            "it is already in sell"
        );

        storage_contract.update_is_timed(itemId, true);

        storage_contract.update_owner(itemId, payable(0x00)) ;

        storage_contract.update_sell(itemId, true);

        storage_contract.update_time(itemId, time);

        storage_contract.update_is_fixed(itemId, !true);

        storage_contract.update_price(itemId, price);

        emit keep_for_timed_auction(itemId, price, time);
    }

    function keep_for_openbid(uint256 itemId, uint256 price) public {
        require(
            storage_contract.get_items_by_id(itemId).owner == msg.sender,
            "you can't annonce for auction"
        );

        require(
            storage_contract.get_items_by_id(itemId).sell == false,
            "it is already in sell"
        );

        storage_contract.update_owner(itemId, payable(0x00));

        storage_contract.update_sell(itemId, true);

        storage_contract.update_is_timed(itemId, !true);

        storage_contract.update_is_fixed(itemId, !true);

        storage_contract.update_price(itemId, price);

        emit keep_for_open_bid(itemId, price);
    }

    function burn(uint256 itemId) public {
        require(
            msg.sender == storage_contract.get_items_by_id(itemId).owner ||
                msg.sender == address(this),
            "your are not owner of token"
        );

        storage_contract.update_owner(itemId, payable(0x00));

        storage_contract.update_owner(itemId, payable(0x00));

        storage_contract.update_price(itemId, 0) ;

        storage_contract.update_sell(itemId, !true);

        emit burn_token(itemId);
    }

    function cancelsale(uint256 itemId) public {
        require(
            msg.sender == storage_contract.get_items_by_id(itemId).owner,
            "your are not owner of token"
        );

        require(
            storage_contract.get_items_by_id(itemId).sell == true,
            "it is already not in sale"
        );
        storage_contract.update_sell(itemId, !true) ;
        storage_contract.update_owner(itemId, payable(0x00));
        storage_contract.update_price(itemId, 0) ;
        emit cancel_sale(itemId);
    }
}