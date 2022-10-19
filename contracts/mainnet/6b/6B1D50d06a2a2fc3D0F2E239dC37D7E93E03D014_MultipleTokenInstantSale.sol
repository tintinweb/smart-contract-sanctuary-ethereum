// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IMultipleToken} from "../token/IMultipleToken.sol";
import {IMetaUnitTracker} from "../../MetaUnit/Tracker/IMetaUnitTracker.sol";
import {Pausable} from "../../../Pausable.sol";

/**
 * @author MetaPlayerOne DAO
 * @title SingleTokenInstantSale
 * @notice Manages single ERC1155 token sales on MetaPlayerOne. 
 */
contract MultipleTokenInstantSale is Pausable {
    struct Item { uint256 uid; address token_address; uint256 token_id; uint256 amount; uint256 sold; address owner_of; uint256 price; bool is_canceled; }
    Item[] private _items;
    mapping(address => mapping(uint256 => bool)) private _active_items;
    address private _meta_unit_tracker_address;
    mapping(address => bool) private _royalty_receivers;

    /**
     * @dev setup metaunit address and owner of contract.
     */
    constructor(address owner_of_, address meta_unit_tracker_address_, address[] memory platform_token_addresses_) Pausable(owner_of_) {
        _meta_unit_tracker_address = meta_unit_tracker_address_;
        for (uint256 i = 0; i < platform_token_addresses_.length; i++) {
            _royalty_receivers[platform_token_addresses_[i]] = true;
        }
    }

    /**
     * @dev emits when new ERC1155 pushes to market.
     */
    event itemSold(uint256 uid, uint256 amount, address buyer);
    
    /**
     * @dev emits when order resolves
     */
    event itemAdded(uint256 uid, address token_address, uint256 token_id, uint256 amount, uint256 sold, address owner_of, uint256 price);

    /**
     * @dev emits when order revokes.
     */
    event itemRevoked(uint256 uid);

    /**
     * @dev emits when order edits.
     */
    event itemEdited(uint256 uid, uint256 value);
    /**
     * @dev allows you to put the ERC1155 token up for sale.
     * @param token_address address of token you pushes to market.
     * @param token_id id of token you pushes to market. 
     * @param price the minimum price for which a token can be bought.
     * @param amount amount of ERC1155 tokens.
     */
    function sale(address token_address, uint256 token_id, uint256 price, uint256 amount) public notPaused {
        IERC1155 token = IERC1155(token_address);
        require(token.balanceOf(msg.sender, token_id) >= amount, "You are not an owner");
        require(token.isApprovedForAll(msg.sender, address(this)), "Token is not approved to contact");
        uint256 newItemId = _items.length;
        _items.push(Item(newItemId, token_address, token_id, amount, 0, msg.sender, price, false));
        emit itemAdded(newItemId, token_address, token_id, amount, 0, msg.sender, price);
    }

    /**
     * @dev allows you to buy tokens.
     * @param uid unique order to be resolved.
     */
    function buy(uint256 uid, uint256 amount) public payable notPaused {
        Item memory item = _items[uid];
        require(item.price * amount <= msg.value, "Not enough funds send");
        require(msg.sender != item.owner_of, "You are an owner");
        require(item.sold + amount <= item.amount, "Limit exceeded");
        uint256 summ = 0;
        if (_royalty_receivers[item.token_address]) {
            IMultipleToken token = IMultipleToken(item.token_address);
            uint256 royalty = token.getRoyalty(item.token_id) * 10;
            address creator = token.getCreator(item.token_id);
            payable(creator).transfer((item.price * amount * royalty) / 1000);
            summ += royalty;
        }
        payable(_owner_of).transfer((item.price * amount * 25) / 1000);
        summ += 25;
        payable(item.owner_of).transfer(msg.value - ((item.price * amount * summ) / 1000));
        IMetaUnitTracker(_meta_unit_tracker_address).track(msg.sender, item.price * amount);
        IERC1155(item.token_address).safeTransferFrom(item.owner_of, msg.sender, item.token_id, amount, "");
        _items[uid].sold += amount;
        emit itemSold(uid, amount, msg.sender);
    }

    function revoke(uint256 uid) public {
        Item memory item = _items[uid];
        require(msg.sender == item.owner_of, "You are not an owner");
        require(_active_items[item.token_address][item.token_id], "Order does not exist");
        require(item.sold != item.amount, "Limit exceeded");
        _active_items[item.token_address][item.token_id] = false;
        _items[uid].is_canceled = true;
        emit itemRevoked(uid);
    }

    function edit(uint256 uid, uint256 value) public {
        Item memory item = _items[uid];
        require(msg.sender == item.owner_of, "You are not an owner");
        require(_active_items[item.token_address][item.token_id], "Order does not exist");
        require(!item.is_canceled, "Order has been canceled");
        require(item.sold != item.amount, "Limit exceeded");
        _active_items[item.token_address][item.token_id] = false;
        _items[uid].price = value;
        emit itemEdited(uid, value);
    }

    function update(address[] memory addresses) public {
        require(_owner_of == msg.sender, "Permission denied");
        for (uint256 i = 0; i < addresses.length; i++) {
            _royalty_receivers[addresses[i]] = true;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMetaUnitTracker {
    struct Transaction { address owner_of; uint256 value; uint256 timestamp; }

    function track(address eth_address_, uint256 value_) external;
    function getUserResalesSum(address eth_address_) external view returns(uint256);
    function getUserTransactionQuantity(address eth_address_) external view returns(uint256);
    function getTransactions() external view returns (Transaction[] memory);
    function getTransactionsForPeriod(uint256 from_, uint256 to_) external view returns (address[] memory, uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMultipleToken {
    function getRoyalty(uint256 tokenId) external returns (uint256);

    function getCreator(uint256 tokenId) external returns (address);

    function mint(string memory token_uri, uint256 amount, uint256 royalty) external;

    function burn(uint256 token_id, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @author MetaPlayerOne DAO
 * @title Pausable
 * @notice Contract which manages allocations in MetaPlayerOne.
 */
contract Pausable {
    address internal _owner_of;
    bool internal _paused = false;

    /**
    * @dev setup owner of this contract with paused off state.
    */
    constructor(address owner_of_) {
        _owner_of = owner_of_;
        _paused = false;
    }

    /**
    * @dev modifier which can be used on child contract for checking if contract services are paused.
    */
    modifier notPaused() {
        require(!_paused, "Contract is paused");
        _;
    }

    /**
    * @dev function which setup paused variable.
    * @param paused_ new boolean value of paused condition.
    */
    function setPaused(bool paused_) external {
        require(_paused == paused_, "Param has been asigned already");
        require(_owner_of == msg.sender, "Permission address");
        _paused = paused_;
    }

    /**
    * @dev function which setup owner variable.
    * @param owner_of_ new owner of contract.
    */
    function setOwner(address owner_of_) external {
        require(_owner_of == msg.sender, "Permission address");
        _owner_of = owner_of_;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155.sol)

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