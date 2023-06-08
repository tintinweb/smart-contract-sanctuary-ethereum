/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC1155/IERC1155.sol)

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
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;



/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;


/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
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
}

// File: contracts/PROJECTS/TicketMarket.sol

//SPDX-License-Identifier:MIT
pragma solidity  ^0.8.18;




library Counters {
    struct Counter {
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

contract TicketMarket is ERC1155Holder {
    using Counters for Counters.Counter;
    //counters start at 0
    Counters.Counter private _ticketCount;
    Counters.Counter private _eventIds;
    Counters.Counter private _resaleIds;

    mapping(address => EventOrganizer) private eventOrganizer;
    mapping(uint256 => MarketEvent) private idToMarketEvent;
    mapping(uint256 => MarketTicket) private idToMarketTicket;
    mapping(uint256 => ResaleTicket) private idToResaleTicket;
    mapping(uint256 => mapping(address => bool)) private idToValidated;


    struct EventOrganizer {
        string name;
        string email;
        string phone;
        address payable owner;
    }

    struct MarketEvent {
        uint256 eventId;
        string uri;
        uint64 startDate;
        uint256 ticketTotal;
        uint256 ticketsSold;
        address payable owner;
    }

    struct MarketTicket {
        uint256 tokenId;
        uint256 eventId;
        uint256 price;
        uint256 purchaseLimit;
        uint256 totalSupply;
        uint256 royaltyFee;
        uint256 maxResalePrice;
    }

    struct ResaleTicket {
        uint256 resaleId;
        uint256 tokenId;
        address payable seller;
        uint256 resalePrice;
        bool sold;
    }

    event EventOrganizerCreated(
        string name,
        string email,
        string phone,
        address owner
    );

    event MarketEventCreated(
        uint256 indexed eventId,
        string uri,
        uint64 startDate,
        uint256 ticketTotal,
        uint256 ticketsSold,
        address owner
    );

    event MarketTicketCreated(
        uint256 indexed tokenId,
        uint256 indexed eventId,
        uint256 price,
        uint256 purchaseLimit,
        uint256 totalSupply,
        uint256 royaltyFee,
        uint256 maxResalePrice
    );

    event ResaleTicketCreated(
        uint256 indexed resaleId,
        uint256 indexed tokenId,
        address seller,
        uint256 resalePrice,
        bool sold
    );

    event TicketValidated(uint256 indexed tokenId, address ownerAddress);

    function createEventOrganizer(
        string memory name,
        string memory email,
        string memory phone
    )
        public
    {
        // check if thic fucntion caller is not an zero address account
        require(msg.sender != address(0));

        eventOrganizer[msg.sender] = EventOrganizer(
            name,
            email,
            phone,
            payable(msg.sender)
        );

        emit EventOrganizerCreated(name, email, phone, msg.sender);
    }

    /* Places an item for sale on the marketplace */
    function createEvent(string memory uri, uint64 startDate)
        public
        returns (uint256)
    {
        // check if thic fucntion caller is not an zero address account
        require(msg.sender != address(0));
        require(
            (uint64(block.timestamp) <= startDate),
            "Date has already passed"
        );
        _eventIds.increment();

        uint256 eventId = _eventIds.current();

        idToMarketEvent[eventId] = MarketEvent(
            eventId,
            uri,
            startDate,
            0,
            0,
            payable(msg.sender)
        );

        emit MarketEventCreated(eventId, uri, startDate, 0, 0, msg.sender);

        return eventId;
    }

    /* Places a ticket for sale on the marketplace */
    function createMarketTicket(
        uint256 eventId,
        uint256 tokenId,
        address nftContract,
        uint256 purchaseLimit,
        uint256 totalSupply,
        uint256 price,
        uint256 royaltyFee,
        uint256 maxResalePrice
    ) public {
        require(price > 0, "Price must be at least 1 wei");
        //check user owns NFT before listing it on the market
        require(
            IERC1155(nftContract).balanceOf(msg.sender, tokenId) >= totalSupply,
            "You do not own the NFT ticket you are trying to list"
        );
        //check msg sender owns event
        require(
            idToMarketEvent[eventId].owner == msg.sender,
            "You do not own this event"
        );
        //Check event has not already passed
        require(
            (uint64(block.timestamp) <= idToMarketEvent[eventId].startDate),
            "Event has already passed"
        );
        require(
            royaltyFee <= 100,
            "Royalty fee must be a percentage, therefore it can't be more than 100"
        );

        _ticketCount.increment();

        idToMarketTicket[tokenId] = MarketTicket(
            tokenId,
            eventId,
            price,
            purchaseLimit,
            totalSupply,
            royaltyFee,
            maxResalePrice
        );

        IERC1155(nftContract).safeTransferFrom(
            msg.sender,
            address(this),
            tokenId,
            totalSupply,
            ""
        );
        idToMarketEvent[eventId].ticketTotal =
            idToMarketEvent[eventId].ticketTotal +
            totalSupply;

        emit MarketTicketCreated(
            tokenId,
            eventId,
            price,
            purchaseLimit,
            totalSupply,
            royaltyFee,
            maxResalePrice
        );
    }

    function addMoreTicketsToMarket(
        address nftContract,
        uint256 tokenId,
        uint256 amount
    ) public {
        uint256 eventId = idToMarketTicket[tokenId].eventId;
        //check user owns NFT before listing it on the market
        require(
            IERC1155(nftContract).balanceOf(msg.sender, tokenId) >= amount,
            "You do not own the NFT ticket you are trying to list"
        );
        //check msg sender owns event
        require(
            idToMarketEvent[eventId].owner == msg.sender,
            "You do not own this event"
        );
        //Check event has not already passed
        require(
            (uint64(block.timestamp) <= idToMarketEvent[eventId].startDate),
            "Event has already passed"
        );

        IERC1155(nftContract).safeTransferFrom(
            msg.sender,
            address(this),
            tokenId,
            amount,
            ""
        );
        idToMarketEvent[eventId].ticketTotal =
            idToMarketEvent[eventId].ticketTotal +
            amount;
        idToMarketTicket[tokenId].totalSupply =
            idToMarketTicket[tokenId].totalSupply +
            amount;
    }

    function buyTicket(
        address nftContract,
        uint256 tokenId,
        uint256 amount
    ) public payable {
        uint256 price = idToMarketTicket[tokenId].price;
        uint256 limit = idToMarketTicket[tokenId].purchaseLimit;
        uint256 eventId = idToMarketTicket[tokenId].eventId;
        address eventOwner = idToMarketEvent[eventId].owner;
        require(
            amount <= IERC1155(nftContract).balanceOf(address(this), tokenId),
            "Not enough tickets remaining on the marketplace"
        );
        require(
            amount <=
                limit - IERC1155(nftContract).balanceOf(msg.sender, tokenId),
            "You have exceeded the maximum amount of tickets you are allowed to purchase"
        );
        require(
            msg.value == price * amount,
            "Correct amount of money was not sent"
        );
        //make sure the event hasn't started
        require(
            (uint64(block.timestamp) <= idToMarketEvent[eventId].startDate),
            "Event has already passed"
        );

        idToValidated[tokenId][msg.sender] = false;

        IERC1155(nftContract).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId,
            amount,
            ""
        );
        idToMarketEvent[eventId].ticketsSold =
            idToMarketEvent[eventId].ticketsSold +
            amount;
        payable(eventOwner).transfer(msg.value);
    }

    function buyResaleTicket(address nftContract, uint256 _resaleId)
        public
        payable
    {
        uint256 price = idToResaleTicket[_resaleId].resalePrice;
        uint256 tokenId = idToResaleTicket[_resaleId].tokenId;
        uint256 limit = idToMarketTicket[tokenId].purchaseLimit;
        uint256 eventId = idToMarketTicket[tokenId].eventId;
        address seller = idToResaleTicket[_resaleId].seller;
        address eventOwner = idToMarketEvent[eventId].owner;
        uint256 royaltyPercentage = idToMarketTicket[tokenId].royaltyFee;
        require(
            !idToResaleTicket[_resaleId].sold,
            "This ticket is not currently being resold on the market"
        );
        require(
            limit - IERC1155(nftContract).balanceOf(msg.sender, tokenId) > 0,
            "You have exceeded the maximum amount of tickets you are allowed to purchase"
        );
        require(msg.value == price, "Correct amount of money was not sent");
        //make sure the event hasn't started
        require(
            (uint64(block.timestamp) <= idToMarketEvent[eventId].startDate),
            "Event has already passed"
        );

        idToValidated[tokenId][msg.sender] = false;

        IERC1155(nftContract).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId,
            1,
            ""
        );
        idToResaleTicket[_resaleId].sold == true;

        uint256 _royaltyFee = (price / 100) * royaltyPercentage;
        uint256 _sellerFee = price - _royaltyFee;

        payable(seller).transfer(_sellerFee);
        payable(eventOwner).transfer(_royaltyFee);

        idToResaleTicket[_resaleId].sold = true;
    }

    function validateTicket(
        address nftContract,
        uint256 tokenId,
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public returns (address) {
        //Only event owner can validate ticket
        require(
            idToMarketEvent[idToMarketTicket[tokenId].eventId].owner ==
                msg.sender,
            "You do not the own the event for the ticket trying to be validated"
        );

        //Get address from signature
        bytes32 messageDigest = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );

        address signatureAddress = ecrecover(messageDigest, v, r, s);

        //user must own token
        require(
            IERC1155(nftContract).balanceOf(signatureAddress, tokenId) > 0,
            "Address does not own token"
        );
        //Stops user from entering their ticket twice
        require(
            idToValidated[tokenId][signatureAddress] == false,
            "User has already validated ticket"
        );

        idToValidated[tokenId][signatureAddress] = true;

        emit TicketValidated(tokenId, signatureAddress);

        return signatureAddress;
    }

    function listOnResale(
        address nftContract,
        uint256 _tokenId,
        uint256 price
    ) public returns (uint256) {
        require(
            IERC1155(nftContract).balanceOf(msg.sender, _tokenId) > 0,
            "You do not own the ticket you are trying to list"
        );
        require(
            price <= idToMarketTicket[_tokenId].maxResalePrice,
            "Resale price should not exceed the max resale price for this ticket"
        );
        require(
            idToValidated[_tokenId][msg.sender] == false,
            "This ticket has already been used for event"
        );

        uint256 resaleId;
        uint256 totalIdCount = _resaleIds.current();

        uint256 currentIndex = 1;
        bool noSoldIds = true;

        //We loop through resaleMarket, if a resale item is sold, we use that id as the id for our new resale item and overwrite the old item
        while (noSoldIds && currentIndex <= totalIdCount) {
            if (idToResaleTicket[currentIndex].sold == true) {
                noSoldIds = false;
                resaleId = currentIndex;
            }
            currentIndex++;
        }
        if (noSoldIds) {
            _resaleIds.increment();
            resaleId = _resaleIds.current();
        }

        idToResaleTicket[resaleId] = ResaleTicket(
            resaleId,
            _tokenId,
            payable(msg.sender),
            price,
            false
        );

        IERC1155(nftContract).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId,
            1,
            ""
        );

        emit ResaleTicketCreated(resaleId, _tokenId, msg.sender, price, false);

        return resaleId;
    }

    /* Getters */

    function getEvent(uint256 _eventId)
        public
        view
        returns (MarketEvent memory)
    {
        require(
            idToMarketEvent[_eventId].eventId > 0,
            "This event does not exist"
        );
        return idToMarketEvent[_eventId];
    }

    /* Returns only events that a user has created */
    function getMyEvents() public view returns (MarketEvent[] memory) {
        uint256 totalEventCount = _eventIds.current();
        uint256 eventCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalEventCount; i++) {
            if (idToMarketEvent[i + 1].owner == msg.sender) {
                eventCount += 1;
            }
        }

        MarketEvent[] memory userEvents = new MarketEvent[](eventCount);
        for (uint256 i = 0; i < totalEventCount; i++) {
            if (idToMarketEvent[i + 1].owner == msg.sender) {
                uint256 currentId = i + 1;
                MarketEvent storage currentEvent = idToMarketEvent[currentId];
                userEvents[currentIndex] = currentEvent;
                currentIndex += 1;
            }
        }
        return userEvents;
    }

    function getAllEvents() public view returns (MarketEvent[] memory) {
        uint256 totalEventCount = _eventIds.current();
        uint256 eventCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalEventCount; i++) {
            if ((uint64(block.timestamp) <= idToMarketEvent[i + 1].startDate)) {
                eventCount += 1;
            }
        }
        MarketEvent[] memory userEvents = new MarketEvent[](eventCount);
        for (uint256 i = 0; i < totalEventCount; i++) {
            if ((uint64(block.timestamp) <= idToMarketEvent[i + 1].startDate)) {
                uint256 currentId = i + 1;
                MarketEvent storage currentEvent = idToMarketEvent[currentId];
                userEvents[currentIndex] = currentEvent;
                currentIndex += 1;
            }
        }
        return userEvents;
    }

    function getEventTickets(uint256 _eventId)
        public
        view
        returns (MarketTicket[] memory)
    {
        uint256 totalTicketCount = _ticketCount.current();
        uint256 ticketCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalTicketCount; i++) {
            if (idToMarketTicket[i + 1].eventId == _eventId) {
                ticketCount += 1;
            }
        }

        MarketTicket[] memory userTickets = new MarketTicket[](ticketCount);
        for (uint256 i = 0; i < totalTicketCount; i++) {
            if (idToMarketTicket[i + 1].eventId == _eventId) {
                uint256 currentId = i + 1;
                MarketTicket storage currentTicket = idToMarketTicket[
                    currentId
                ];
                userTickets[currentIndex] = currentTicket;
                currentIndex += 1;
            }
        }
        return userTickets;
    }

    function getMyTickets(address nftContract)
        public
        view
        returns (MarketTicket[] memory)
    {
        uint256 totalTicketCount = _ticketCount.current();
        uint256 ticketCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalTicketCount; i++) {
            if (
                IERC1155(nftContract).balanceOf(address(msg.sender), i + 1) >= 1
            ) {
                ticketCount += 1;
            }
        }

        MarketTicket[] memory userTickets = new MarketTicket[](ticketCount);
        for (uint256 i = 0; i < totalTicketCount; i++) {
            if (
                IERC1155(nftContract).balanceOf(address(msg.sender), i + 1) >= 1
            ) {
                uint256 currentId = i + 1;
                MarketTicket storage currentTicket = idToMarketTicket[
                    currentId
                ];
                userTickets[currentIndex] = currentTicket;
                currentIndex += 1;
            }
        }
        return userTickets;
    }

    function getMyResaleListings() public view returns (ResaleTicket[] memory) {
        uint256 totalTicketCount = _resaleIds.current();
        uint256 ticketCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalTicketCount; i++) {
            if (
                idToResaleTicket[i + 1].seller == msg.sender &&
                idToResaleTicket[i + 1].sold == false
            ) {
                ticketCount += 1;
            }
        }

        ResaleTicket[] memory resaleTickets = new ResaleTicket[](ticketCount);
        for (uint256 i = 0; i < totalTicketCount; i++) {
            if (
                idToResaleTicket[i + 1].seller == msg.sender &&
                idToResaleTicket[i + 1].sold == false
            ) {
                uint256 currentId = i + 1;
                ResaleTicket storage currentTicket = idToResaleTicket[
                    currentId
                ];
                resaleTickets[currentIndex] = currentTicket;
                currentIndex += 1;
            }
        }
        return resaleTickets;
    }

    function getResaleTickets(uint256 _tokenId)
        public
        view
        returns (ResaleTicket[] memory)
    {
        uint256 totalTicketCount = _resaleIds.current();
        uint256 ticketCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalTicketCount; i++) {
            if (
                idToResaleTicket[i + 1].tokenId == _tokenId &&
                idToResaleTicket[i + 1].sold == false
            ) {
                ticketCount += 1;
            }
        }

        ResaleTicket[] memory resaleTickets = new ResaleTicket[](ticketCount);
        for (uint256 i = 0; i < totalTicketCount; i++) {
            if (
                idToResaleTicket[i + 1].tokenId == _tokenId &&
                idToResaleTicket[i + 1].sold == false
            ) {
                uint256 currentId = i + 1;
                ResaleTicket storage currentTicket = idToResaleTicket[
                    currentId
                ];
                resaleTickets[currentIndex] = currentTicket;
                currentIndex += 1;
            }
        }
        return resaleTickets;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Receiver)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}