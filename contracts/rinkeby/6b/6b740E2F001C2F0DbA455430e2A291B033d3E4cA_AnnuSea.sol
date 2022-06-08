// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
contract AnnuSea {
    address private owner;
    address public annuAddr;
    uint256 public constant ANNUTOKEN = 1;
    //fee成交佣金,rng 0~10000=0%~100%,250=2.5% 所以token至少要高於 10000wei
    uint256 private constant maxFee = 10000;
    uint256 public fee = 500; //5%
    enum ItemState {
        Inactive,
        Created,
        Selled
    } //下架時清空，也就是設回0，下次又上架，又使用這個位址
    //items
    //Item[] private items;
    mapping(uint256 => Item) public items;
    struct Item {
        ItemState state; //0sell 1buy 2invaild
        address seller;
        address buyer;
        uint256 price;
        //uint8 category; //沒辦法 因為從這裡去1155抓metadata這件事，我做不到
        uint256 endAt;
    }
    event Log(string func, address sender, uint256 value, bytes data);
    event sellOnEvent(uint256 tokenId, uint256 price, uint256 endAt);
    event sellDownEvent(uint256 tokenId);
    event buyEvent(uint256 tokenId,address indexed seller,address indexed buyer , uint256 fee);
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlySeller(uint256 tokenId) {
        require(
            items[tokenId].seller == msg.sender,
            "Ownable: caller is not the seller"
        );
        _;
    }
    modifier onlyNotSeller(uint256 tokenId) {
        require(
            items[tokenId].seller != msg.sender,
            "can't buy self"
        );
        _;
    }
    modifier inTime(uint256 tokenId) {
        require(
            block.timestamp < items[tokenId].endAt,
            "time out"
        );
        _;
    }
    modifier checkState(uint256 tokenId, ItemState state) {
        require(
            items[tokenId].state == state,
            "StateError"
        );
        _;
    }
    modifier canBuy(uint256 tokenId) {
        require(available(tokenId), "can't buy");
        _;
    }

    constructor() {
        owner = msg.sender;
    }
    function setAnnuAddr(address _annuAddr) public onlyOwner {
        annuAddr = _annuAddr;
    }
    function setFee(uint256 _fee) public onlyOwner {
        fee = _fee;
    }

    function sellOn(uint256 tokenId, uint256 price)
        public
        checkState(tokenId, ItemState.Inactive)
    {
        uint256 balance = IERC1155(annuAddr).balanceOf(msg.sender, tokenId);
        if (balance > 0) {
            uint256 endAt = block.timestamp + 5 * 1 minutes;
            items[tokenId].seller=msg.sender;
            items[tokenId].price=price;
            items[tokenId].state=ItemState.Created;
            items[tokenId].endAt=endAt;
            emit sellOnEvent(tokenId, price, endAt);
        }
        else
        {
            revert("no nft");
        }
    }

    function available(uint256 tokenId) private view returns (bool) {
        if (items[tokenId].state != ItemState.Created) return false;
        if (items[tokenId].seller == msg.sender) return false;
        if (block.timestamp > items[tokenId].endAt) return false;
        return true;
    }

    function buy(uint256 tokenId) public payable checkState(tokenId, ItemState.Created) onlyNotSeller(tokenId) inTime(tokenId) {
        //檢查錢夠不夠
        uint256 balance = IERC1155(annuAddr).balanceOf(msg.sender, ANNUTOKEN);
        require(balance >= items[tokenId].price, "annu token not enough");
        uint256 _fee = (items[tokenId].price / maxFee) * fee;
        items[tokenId].state = ItemState.Selled;
        items[tokenId].buyer = msg.sender;
        IERC1155(annuAddr).safeTransferFrom(
            msg.sender,
            items[tokenId].seller,
            ANNUTOKEN,
            items[tokenId].price - _fee,
            "0x"
        );
        IERC1155(annuAddr).safeTransferFrom(
            items[tokenId].seller,
            owner,
            ANNUTOKEN,
            _fee,
            "0x"
        );
        IERC1155(annuAddr).safeTransferFrom(
            items[tokenId].seller,
            msg.sender,
            tokenId,
            1,
            "0x"
        );
        //發送成交event
        emit buyEvent(
            tokenId,
            items[tokenId].seller,
            items[tokenId].buyer,
            _fee
        );
    }

    function sellDown(uint256 tokenId) checkState(tokenId, ItemState.Created) onlySeller(tokenId) public {
        items[tokenId].state = ItemState.Inactive;
        emit sellDownEvent(tokenId);
    }

    fallback() external payable {
        emit Log("fallback", msg.sender, msg.value, msg.data);
    }

    receive() external payable {
        emit Log("receive", msg.sender, msg.value, "");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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