// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";

// import "hardhat/console.sol";

/*
    Author: chosta.eth (@chosta_eth)
 */
/*
    Inspired by: 0xInu's Martian Marketplace 0xFD8f4aC172457FD30Df92395BC69d4eF6d92eDd4
*/
/**
    Borrowed the core VendingItems functionality and amended it to work with the Founders token. 
    Additionally, an option to purchase an item in the form of erc1155 was added. The concept of having an 
    erc1155 token as a marketplace entry enables decentralized whitelisting where users can own the item, 
    trade, burn, or mint with it without having to go through discord admins and wallet collection.
 */
/* To draw a front-end interface:
    
        getWLVendingItemsAll() - Enumerate all vending items
        available for the contract. Supports over 1000 items in 1 call but
        if you get gas errors, use a pagination method instead.

        Pagination method: 
        getWLVendingItemsPaginated(uint256 start_, uint256 end_)
        for the start_, generally you can use 0, and for end_, inquire from function
        getWLVendingItemsLength()

    For interaction of users:

        purchaseWLVendingItem(uint256 index_) can be used
        and automatically populated to the correct buttons for each WLVendingItem
        for that, an ethers.js call is invoked for the user to call the function
        which will transfer their ERC20 token and add them to the purchasers list
        + ability to buy erc1155 compatible tokens used as WL entries

    For administration:

        addWLVendingItem(WLVendingItem memory WLVendingItem_) is used to create a new WLVendingItem

        modifyWLVendingItem(uint256 index_, 
        WLVendingItem memory WLVendingItem_) lets you modify a WLVendingItem.
        You have to pass in a tuple instead. Only use when necessary. Not
        recommended to use.

        deleteMostRecentWLVendingItem() we use a .pop() for this so
        it can only delete the most recent item. For some mistakes that you made and
        want to erase them.

        manageController(address operator_, bool bool_) is a special
        governance function which allows you to add controllers to the contract
        to do actions on your behalf. */

interface IToken {
    function owner() external view returns (address);

    function balanceOf(address address_) external view returns (uint256);

    function burn(address from_, uint256 amount_) external;
}

interface IMarketItem1155 {
    function safeTransferFrom(
        address from_,
        address to_,
        uint256 id_,
        uint256 amount_,
        bytes memory data_
    ) external;

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function burn(
        address from,
        uint256 id,
        uint256 value
    ) external;
}

contract FFMarketplace is
    ReentrancyGuard,
    ERC1155Holder,
    Pausable,
    AccessControl
{
    enum VendingItemType {
        ERC1155,
        WL,
        RAFFLE,
        LOOTBOX,
        NFT,
        MERCH,
        IRL,
        MISC
    }

    struct WLVendingItem {
        uint256 tokenId; // ERC1155 token id
        VendingItemType itemType;
        bool active; // frontend help - use to hide items
        string title;
        string imageUri;
        string description;
        uint32 amountAvailable;
        uint32 amountPurchased;
        uint256 startTime;
        uint256 endTime;
        uint256 price;
        string discord;
        string twitter;
    }

    IToken public token;
    IMarketItem1155 public marketItem;
    WLVendingItem[] public toWLVendingItems;
    mapping(uint256 => address[]) public toWLPurchasers;
    mapping(uint256 => mapping(address => bool)) public toWLPurchased;
    // On Chain Discord Directory
    // Inspired by 0xInuarashi's OnChainDiscordDirectory
    mapping(address => string) public addressToDiscord;

    event WLVendingItemAdded(address indexed operator_, WLVendingItem item_);
    event WLVendingItemModified(
        address indexed operator_,
        WLVendingItem before_,
        WLVendingItem after_
    );
    event WLVendingItemRemoved(address indexed operator_, WLVendingItem item_);
    event WLVendingItemPurchased(
        address indexed purchaser_,
        uint256 index_,
        WLVendingItem item_
    );
    event WLVendingItemGifted(
        address indexed gifted_,
        uint256 index_,
        WLVendingItem item_
    );
    event DiscordDirectoryUpdated(address indexed setter_, string discordTag_);

    bytes32 public constant MARKETPLACE_ADMIN = keccak256("MARKETPLACE_ADMIN");

    constructor(address _token, address _marketItem) {
        token = IToken(_token);
        marketItem = IMarketItem1155(_marketItem);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MARKETPLACE_ADMIN, msg.sender);
    }

    // override needed for AccessControl and ERC1155Receiver (receiver part of ERC1155Holder)
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC1155Receiver)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /** ###########
        Admin stuff
     */
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /* 
        Changing the erc1155 contract should be fine but it invalidates any previously
        created erc1155 vending items
     */
    function updateMarketItemContract(address marketItem_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        marketItem = IMarketItem1155(marketItem_);
    }

    function addWLVendingItem(WLVendingItem memory WLVendingItem_)
        external
        onlyRole(MARKETPLACE_ADMIN)
    {
        require(
            bytes(WLVendingItem_.title).length > 0,
            "you must specify a title"
        );
        require(
            uint256(WLVendingItem_.endTime) > block.timestamp,
            "already expired timestamp"
        );
        require(
            WLVendingItem_.endTime > WLVendingItem_.startTime,
            "endTime < startTime"
        );
        // Make sure that the token id for non erc1155 is 0
        if (WLVendingItem_.itemType != VendingItemType.ERC1155) {
            WLVendingItem_.tokenId = 0;
        } else {
            require(WLVendingItem_.tokenId > 0, "token id must be > 0");
            // if adding an erc1155 -> check for the amount available
            require(
                WLVendingItem_.amountAvailable <=
                    marketItem.balanceOf(address(this), WLVendingItem_.tokenId),
                "insufficient erc1155 tokens"
            );
        }

        // Make sure that amountPurchased on adding is always 0
        WLVendingItem_.amountPurchased = 0;

        // Push the item to the database array
        toWLVendingItems.push(WLVendingItem_);

        emit WLVendingItemAdded(msg.sender, WLVendingItem_);
    }

    function modifyWLVendingItem(
        uint256 index_,
        WLVendingItem memory WLVendingItem_
    ) external onlyRole(MARKETPLACE_ADMIN) {
        WLVendingItem memory _item = toWLVendingItems[index_];

        require(bytes(_item.title).length > 0, "item does not exist");
        require(
            bytes(WLVendingItem_.title).length > 0,
            "you must specify a title"
        );
        require(
            uint256(WLVendingItem_.endTime) > block.timestamp,
            "already expired timestamp"
        );
        require(
            WLVendingItem_.endTime > WLVendingItem_.startTime,
            "endTime < startTime"
        );
        require(
            WLVendingItem_.amountAvailable >= _item.amountPurchased,
            "available must be >= purchased"
        );

        if (WLVendingItem_.itemType != VendingItemType.ERC1155) {
            WLVendingItem_.tokenId = 0;
        } else {
            require(WLVendingItem_.tokenId > 0, "token id must be > 0");
            require(
                WLVendingItem_.amountAvailable <=
                    marketItem.balanceOf(address(this), WLVendingItem_.tokenId),
                "insufficient erc1155 tokens"
            );
        }

        toWLVendingItems[index_] = WLVendingItem_;

        emit WLVendingItemModified(msg.sender, _item, WLVendingItem_);
    }

    function deleteMostRecentWLVendingItem()
        external
        onlyRole(MARKETPLACE_ADMIN)
    {
        uint256 _lastIndex = toWLVendingItems.length - 1;

        WLVendingItem memory _item = toWLVendingItems[_lastIndex];

        require(_item.amountPurchased == 0, "goods already bought");

        toWLVendingItems.pop();
        emit WLVendingItemRemoved(msg.sender, _item);
    }

    /* in case we have some unused or erroneous erc1155s */
    function burnERC1155Tokens(uint256 tokenId_, uint256 amount_)
        external
        onlyRole(MARKETPLACE_ADMIN)
    {
        marketItem.burn(address(this), tokenId_, amount_);
    }

    function giftPurchaserAsMarketAdmin(uint256 index_, address giftedAddress_)
        external
        onlyRole(MARKETPLACE_ADMIN)
    {
        WLVendingItem memory _item = getWLVendingItem(index_);

        require(bytes(_item.title).length > 0, "object does not exist");
        require(
            _item.amountAvailable > _item.amountPurchased,
            "no more items remaining"
        );
        require(!toWLPurchased[index_][giftedAddress_], "already added");

        if (_item.itemType == VendingItemType.ERC1155) {
            transferERC1155(_item.tokenId, giftedAddress_);
        }

        toWLPurchased[index_][giftedAddress_] = true;
        toWLPurchasers[index_].push(giftedAddress_);

        toWLVendingItems[index_].amountPurchased++;

        emit WLVendingItemGifted(giftedAddress_, index_, _item);
    }

    /* ### 
        User actions
     */
    function purchaseWLVendingItem(uint256 index_) external nonReentrant {
        // Load the WLVendignItem to Memory
        WLVendingItem memory _item = toWLVendingItems[index_];

        // Check the necessary requirements to purchase
        require(bytes(_item.title).length > 0, "object does not exist");
        require(
            _item.amountAvailable > _item.amountPurchased,
            "no more items remaining"
        );

        require(_item.startTime <= block.timestamp, "not started yet");
        require(_item.endTime >= block.timestamp, "past deadline");
        require(!toWLPurchased[index_][msg.sender], "already purchased");
        require(_item.price != 0, "no price for item");
        require(
            token.balanceOf(msg.sender) >= _item.price,
            "not enough tokens"
        );

        token.burn(msg.sender, _item.price);
        // Pay for the WL (burning do)
        // token.transferFrom(msg.sender, burnAddress, _item.price);

        // handle erc1155
        if (_item.itemType == VendingItemType.ERC1155) {
            transferERC1155(_item.tokenId, msg.sender);
        }

        // Add the address into the WL List
        toWLPurchased[index_][msg.sender] = true;
        toWLPurchasers[index_].push(msg.sender);

        // Increment Amount Purchased
        toWLVendingItems[index_].amountPurchased++;

        emit WLVendingItemPurchased(msg.sender, index_, _item);
    }

    // a handy util function to map discord tags to purchaser addresses
    function setDiscordIdentity(string calldata discordTag_) external {
        addressToDiscord[msg.sender] = discordTag_;

        emit DiscordDirectoryUpdated(msg.sender, discordTag_);
    }

    /** #####
        Internal
    */
    function transferERC1155(uint256 tokenId_, address sender_) internal {
        require(
            marketItem.balanceOf(address(this), tokenId_) > 0,
            "no more erc1155"
        );
        marketItem.safeTransferFrom(
            address(this),
            sender_,
            tokenId_,
            1,
            "item transferred"
        );
    }

    /** #####
        Views 
    */
    // raw
    function getWLVendingItemsAll()
        public
        view
        returns (WLVendingItem[] memory)
    {
        return toWLVendingItems;
    }

    function getWLVendingItem(uint256 index_)
        public
        view
        returns (WLVendingItem memory)
    {
        WLVendingItem memory _item = toWLVendingItems[index_];
        return _item;
    }

    function getWLPurchasersOf(uint256 index_)
        public
        view
        returns (address[] memory)
    {
        return toWLPurchasers[index_];
    }

    function getFixedPriceOfItem(uint256 index_)
        external
        view
        returns (uint256)
    {
        return toWLVendingItems[index_].price;
    }

    function getWLVendingItemsLength() public view returns (uint256) {
        return toWLVendingItems.length;
    }

    function getWLVendingItemsPaginated(uint256 start_, uint256 end_)
        public
        view
        returns (WLVendingItem[] memory)
    {
        uint256 _arrayLength = end_ - start_ + 1;
        WLVendingItem[] memory _items = new WLVendingItem[](_arrayLength);
        uint256 _index;

        for (uint256 i = 0; i < _arrayLength; i++) {
            _items[_index++] = toWLVendingItems[start_ + i];
        }

        return _items;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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