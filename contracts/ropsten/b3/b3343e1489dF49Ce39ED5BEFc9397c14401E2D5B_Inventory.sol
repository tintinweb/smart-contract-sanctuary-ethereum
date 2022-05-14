//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import 'hardhat/console.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";



enum Status {LOCKED, ACTIVE, INACTIVE, DRAFT, PLACEHOLDER}
struct Item {
    bool deleted;
    uint32 id;          // Generated off-chain
    uint price;
    uint burn;
    uint release;
    address custodian;
    Status status;
    string kind;
}
struct Bulk {
    uint32 id;
    uint price;
    uint burn;
    uint release;
    string kind;
}

interface IWhitelist {
    function has_access(string memory _name, address _address) external view returns (bool);
}

// TODO: Bulk replace of placeholders

contract Inventory is Ownable, Pausable {
    mapping(uint32 => Item) public items;
    uint32[] private _active_items;
    IWhitelist public whitelist;
    uint32 public lastid;

    constructor(address _whitelist_address) {
        set_whitelist(_whitelist_address);

        // Bundles
        add_item(1, 10 ether, 0, 0, Status.ACTIVE, 'bundle');
        add_item(2, 10 ether, 0, 0, Status.ACTIVE, 'bundle');
        add_item(3, 20 ether, 0, 0, Status.ACTIVE, 'bundle');
        add_item(4, 20 ether, 0, 0, Status.ACTIVE, 'bundle');

        add_item(5, 25 ether, 0, 0, Status.ACTIVE, 'bundle');
        add_item(6, 25 ether, 0, 0, Status.ACTIVE, 'bundle');
        add_item(7, 30 ether, 0, 0, Status.ACTIVE, 'bundle');
        add_item(8, 30 ether, 0, 0, Status.ACTIVE, 'bundle');
        add_item(9, 50 ether, 0, 0, Status.ACTIVE, 'bundle');
        add_item(10, 50 ether, 0, 0, Status.ACTIVE, 'bundle');
        add_item(11, 1 ether, 0, 0, Status.ACTIVE, 'bundle');
        add_item(12, 1 ether, 0, 0, Status.ACTIVE, 'bundle');

        add_item(13, .1 ether, 0, 0, Status.ACTIVE, 'bundle');
        add_item(14, .2 ether, 0, 0, Status.ACTIVE, 'bundle');
        add_item(15, .3 ether, 0, 0, Status.ACTIVE, 'bundle');
        add_item(16, .4 ether, 0, 0, Status.ACTIVE, 'bundle');
        lastid = 16;

        // COMMENT OUT ON DEPLOYMENT: Test item w/ buyer
        add_item(1234561, 10 ether, 0, 0, Status.ACTIVE, 'bundle');
        add_item(1234562, 10 ether, 0, 0, Status.ACTIVE, 'bundle');
        add_item(1234563, 10 ether, 10 ether - 1, 10 ether + 1, Status.ACTIVE, 'land');
        add_item(1234564, 10 ether, 10 ether - 1, 10 ether + 1, Status.ACTIVE, 'land');

        add_item(1234565, 10 ether, 10 ether - 1, 10 ether + 1, Status.ACTIVE, 'land');
        add_item(1234566, 10 ether, 10 ether - 1, 10 ether + 1, Status.ACTIVE, 'land');
        add_item(1234567, 10 ether, 10 ether - 1, 10 ether + 1, Status.ACTIVE, 'land');
        add_item(1234568, 10 ether, 10 ether - 1, 10 ether + 1, Status.ACTIVE, 'land');
        update_status(1234565, Status.LOCKED);
        update_status(1234566, Status.DRAFT);
        update_status(1234567, Status.INACTIVE);
        update_delete(1234568, true);
    }

    modifier onlyStaff {
        require(
            whitelist.has_access('STAFF', _msgSender()) ||
            whitelist.has_access('DAYZERO', _msgSender()),
            'Staff: You shall not pass!'
        );
        _;
    }

    modifier onlyAdmin {
        require(whitelist.has_access('DAYZERO', _msgSender()), 'Admin: You shall not pass!');
        _;
    }

    modifier onlyStore {
        require(
            whitelist.has_access('STORECONTRACT', _msgSender()) ||
            whitelist.has_access('DAYZERO', _msgSender()) ||
            whitelist.has_access('STAFF', _msgSender()),
            'Store: You shall not pass!'
        );
        _;
    }

    function add_item(
        uint32 _item_id, uint _price, uint _burn, uint _release,
        Status _status, string memory _kind
    ) public onlyStaff {
        require(_item_id > 0 && items[_item_id].deleted == false, 'Invalid ID');
        require(items[_item_id].id == 0, 'Item exists');
        require(_price >= 0.1 ether, 'Invalid price');
        require(_burn < _price, 'Invalid burn');

        if(_burn > 0) {
            require(_release > _price, 'Invalid release');
        }
        else {
            require(_release == 0, 'Invalid release');
        }

        items[_item_id] = Item(false, _item_id, _price, _burn, _release, address(0), _status, _kind);
        _active_items.push(_item_id);
    }

    function drop_item(uint32 _item_id) external onlyAdmin {
        Item memory item = items[_item_id];
        require(item.id > 0, 'Item not exists');
        require(item.deleted == false, 'Item not exists');
        item.deleted = true;
        items[_item_id] = item;
    }

    function replace_item(Item calldata _item) external onlyAdmin {
        require(items[_item.id].id > 0, 'Item not exists');
        items[_item.id] = _item;
    }

    // TODO: Make external before deployment
    function update_status(uint32 _item_id, Status _status) public onlyStore {
        require(items[_item_id].id > 0, 'Item not exists');
        items[_item_id].status = _status;
    }

    function update_custodian(uint32 _item_id, address _custodian) external onlyStore {
        require(items[_item_id].id > 0, 'Item not exists');
        items[_item_id].custodian = _custodian;
    }

    // TEST: For testing
    // TODO: Make external before deployment
    function update_delete(uint32 _item_id, bool _delete) public onlyStore {
        require(items[_item_id].id > 0, 'Item not exists');
        items[_item_id].deleted = _delete;
    }

    function bulk_import(Bulk[] calldata _bulk) external onlyStaff {
        uint len = _bulk.length;
        uint32 _last;

        for(uint i; i < len; i++) {
            Bulk memory b = _bulk[i];
            add_item(b.id, b.price, b.burn, b.release, Status.ACTIVE, b.kind);
            _last = b.id;
        }
        lastid = _last;
    }

    function bulk_export() external onlyStaff view returns (Item[] memory) {
        uint len = _active_items.length;
        Item[] memory arr = new Item[](len);

        for(uint i; i < len; i++) {
            arr[i] = items[_active_items[i]];
        }
        return arr;
    }

    function get_item(uint32 _item_id) public whenNotPaused onlyStore view returns (Item memory) {
        return items[_item_id];
    }

    function set_whitelist(address _address) public onlyOwner {
        require(_address != address(0), 'Cannot add null address');
        whitelist = IWhitelist(_address);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
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