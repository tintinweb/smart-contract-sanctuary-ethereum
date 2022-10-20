// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ISingleToken} from "../token/ISingleToken.sol";
import {IMetaUnitTracker} from "../../MetaUnit/Tracker/IMetaUnitTracker.sol";
import {Pausable} from "../../../Pausable.sol";

/**
 * @author MetaPlayerOne DAO
 * @title SingleTokenInstantSale
 * @notice Manages single ERC721 token sales on MetaPlayerOne. 
 */
contract SingleTokenInstantSale is Pausable {
    struct Item { uint256 uid; address token_address; uint256 token_id; address owner_of; uint256 price; bool is_sold; bool is_canceled; }
    
    Item[] private _items;
    mapping(address => mapping(uint256 => bool)) private _active_items;

    address private _meta_unit_tracker_address;
    address private _selective_factory_address;
    address private _generative_factory_address;
    
    mapping(address => bool) private _royalty_receivers;

    /**
     * @dev setup metaunit address and owner of contract.
     */
    constructor(address owner_of_, address meta_unit_tracker_address_, address selective_factory_address_, address generative_factory_address_, address[] memory platform_token_addresses_) Pausable(owner_of_) {
        _meta_unit_tracker_address = meta_unit_tracker_address_;
        _selective_factory_address = selective_factory_address_;
        _generative_factory_address = generative_factory_address_;
        for (uint256 i = 0; i < platform_token_addresses_.length; i++) {
            _royalty_receivers[platform_token_addresses_[i]] = true;
        }
    }

    /**
     * @dev emits when new ERC721 pushes to market.
     */
    event itemAdded(uint256 uid, address token_address, uint256 token_id, uint256 price, address owner_of, bool is_sold);

   
    /**
     * @dev emits when order resolves
     */
    event itemSold(uint256 uid, address buyer);


    /**
     * @dev emits when order revokes.
     */
    event itemRevoked(uint256 uid);

    /**
     * @dev emits when order edits.
     */
    event itemEdited(uint256 uid, uint256 value);

    /**
     * @dev allows you to put the ERC721 token up for sale.
     * @param token_address address of token you pushes to market.
     * @param token_id id of token you pushes to market. 
     * @param price the minimum price for which a token can be bought.
     */
    function sale(address token_address, uint256 token_id, uint256 price) public notPaused {
        require(!_active_items[token_address][token_id], "Item is already on sale");
        require(IERC721(token_address).getApproved(token_id) == address(this), "Token is not approved to this contract");
        uint256 newItemId = _items.length;
        _items.push(Item(newItemId, token_address, token_id, msg.sender, price, false, false));
        _active_items[token_address][token_id] = true;
        emit itemAdded(newItemId, token_address, token_id, price, msg.sender, false);
    }

     /**
     * @dev allows you to buy tokens.
     * @param uid unique order to be resolved.
     */
    function buy(uint256 uid) public payable notPaused {
        Item memory item = _items[uid];
        require(!item.is_canceled, "Order has been canceled");
        require(_active_items[item.token_address][item.token_id], "Order does not exist");
        require(IERC721(item.token_address).getApproved(item.token_id) == address(this), "Token is not approved to this contract");
        require(msg.value >= item.price, "Not enough funds send");
        require(!item.is_sold, "Order has been resolved");
        uint256 summ = 0;
        if (_royalty_receivers[item.token_address]) {
            ISingleToken token = ISingleToken(item.token_address);
            uint256 royalty = token.getRoyalty(item.token_id) * 10;
            address creator = token.getCreator(item.token_id);
            payable(creator).transfer((item.price * royalty) / 1000);
            summ += royalty;
        }
        payable(_owner_of).transfer((item.price * 25) / 1000);
        summ += 25;
        payable(item.owner_of).transfer(msg.value - ((item.price * summ) / 1000));
        IMetaUnitTracker(_meta_unit_tracker_address).track(item.owner_of, item.price);
        IERC721(item.token_address).safeTransferFrom(item.owner_of, msg.sender, item.token_id);
        _items[uid].is_sold = true;
        _active_items[item.token_address][item.token_id] = false;
        emit itemSold(uid, msg.sender);
    }

    function revoke(uint256 uid) public {
        Item memory item = _items[uid];
        require(msg.sender == item.owner_of, "You are not an owner");
        require(_active_items[item.token_address][item.token_id], "Order does not exist");
        require(!item.is_sold, "Order has been resolved");
        _active_items[item.token_address][item.token_id] = false;
        _items[uid].is_canceled = true;
        emit itemRevoked(uid);
    }

    function edit(uint256 uid, uint256 value) public {
        Item memory item = _items[uid];
        require(msg.sender == item.owner_of, "You are not an owner");
        require(_active_items[item.token_address][item.token_id], "Order does not exist");
        require(!item.is_canceled, "Order has been canceled");
        require(!item.is_sold, "Order has been resolved");
        _items[uid].price = value;
        emit itemEdited(uid, value);
    }

    function update(address[] memory addresses) public {
        require(msg.sender == _owner_of || msg.sender == _selective_factory_address || msg.sender == _generative_factory_address, "Permission denied");
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

interface ISingleToken {
    function getRoyalty(uint256 token_id) external returns (uint256);

    function getCreator(uint256 token_id) external returns (address);

    function mint(string memory token_uri, uint256 royalty) external;

    function burn(uint256 token_id) external;
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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
    function getApproved(uint256 tokenId) external view returns (address operator);

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
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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