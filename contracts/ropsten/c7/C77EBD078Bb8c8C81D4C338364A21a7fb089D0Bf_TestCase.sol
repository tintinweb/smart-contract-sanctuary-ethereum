// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract TestCase is Context {
    using Counters for Counters.Counter;

    Counters.Counter private _itemCount;
    Counters.Counter private _itemId;
    mapping(address => uint256) private _items;
    mapping(address => uint256) private _itemOrder;
    mapping(uint256 => bool) private _valueExist;

    event ItemCreated(address indexed key, uint256 value, address indexed committer);
    event ItemDeleted(address indexed key, uint256 value, address indexed committer);

    modifier onlyItemExists(address key) {
        require(isItemExists(key), "Item does not exist");
        _;
    }

    modifier onlyItemNotExists(address key) {
        require(!isItemExists(key), "Item already exists");
        _;
    }

    modifier onlyPositive(uint256 value) {
        require(value > 0, "Value must be greater than 0");
        _;
    }

    modifier onlyUnique(uint256 value) {
        require(!_valueExist[value], "Value must be unique");
        _;
    }

    modifier increaseItem() {
        _itemId.increment();
        _itemCount.increment();
        _;
    }

    modifier decreaseItem() {
        _itemCount.decrement();
        _;
    }

    function addItem(address key, uint256 value)
        external
        onlyPositive(value)
        onlyUnique(value)
        onlyItemNotExists(key)
        increaseItem
    {
        _items[key] = value;
        _valueExist[value] = true;
        _itemOrder[key] = _itemId.current();

        emit ItemCreated(key, value, _msgSender());
    }

    function deleteItem(address key) external onlyItemExists(key) decreaseItem {
        uint256 value = _items[key];

        delete _valueExist[value];
        delete _items[key];
        delete _itemOrder[key];

        emit ItemDeleted(key, value, _msgSender());
    }

    function getItemCount() external view returns (uint256 count) {
        count = _itemCount.current();
    }

    function getItemOrder(address key) external view onlyItemExists(key) returns (uint256 order) {
        order = _itemOrder[key];
    }

    function getItemValue(address key) external view onlyItemExists(key) returns (uint256 value) {
        value = _items[key];
    }

    function isItemExists(address key) public view returns (bool existence) {
        existence = _items[key] != 0;
    }

    function isValueExists(uint256 value)
        external
        view
        onlyPositive(value)
        returns (bool existence)
    {
        existence = _valueExist[value];
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