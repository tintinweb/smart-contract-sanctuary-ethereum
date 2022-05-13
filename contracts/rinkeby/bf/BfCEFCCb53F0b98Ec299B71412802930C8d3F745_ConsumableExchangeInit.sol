/*
 * Copyright (c) 2021 The Paypr Company, LLC
 *
 * This file is part of Paypr Ethereum Contracts.
 *
 * Paypr Ethereum Contracts is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Paypr Ethereum Contracts is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Paypr Ethereum Contracts.  If not, see <https://www.gnu.org/licenses/>.
 */

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.4;

import '../ERC20Impl.sol';
import '../IConsumableHooks.sol';

contract ConsumableExchangeInit {
  struct ExchangeData {
    IConsumableHooks exchangeConsumableHooks;
  }

  function initialize(ExchangeData calldata exchangeData) external {
    ERC20Impl.addHooks(exchangeData.exchangeConsumableHooks);
  }
}

/*
 * Copyright (c) 2021 The Paypr Company, LLC
 *
 * This file is part of Paypr Ethereum Contracts.
 *
 * Paypr Ethereum Contracts is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Paypr Ethereum Contracts is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Paypr Ethereum Contracts.  If not, see <https://www.gnu.org/licenses/>.
 */

/*
 * Implementation based on OpenZeppelin Contracts ERC20:
 * https://openzeppelin.com/contracts/
 */

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '../../utils/HookUtils.sol';
import '../access/AccessCheckSupport.sol';
import '../access/RoleSupport.sol';
import '../context/ContextSupport.sol';
import './IConsumableHooks.sol';

library ERC20Impl {
  using EnumerableSet for EnumerableSet.AddressSet;

  bytes32 private constant ERC20_STORAGE_POSITION = keccak256('paypr.erc20.storage');

  struct ERC20Storage {
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;
    uint256 totalSupply;
    EnumerableSet.AddressSet hooks;
  }

  //noinspection NoReturn
  function _erc20Storage() private pure returns (ERC20Storage storage ds) {
    bytes32 position = ERC20_STORAGE_POSITION;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      ds.slot := position
    }
  }

  function checkMinter() internal view {
    AccessCheckSupport.checkRole(RoleSupport.MINTER_ROLE);
  }

  function decimals() internal pure returns (uint8) {
    return 18;
  }

  function totalSupply() internal view returns (uint256) {
    return _erc20Storage().totalSupply;
  }

  function balanceOf(address account) internal view returns (uint256) {
    return _erc20Storage().balances[account];
  }

  function myBalance() internal view returns (uint256) {
    return balanceOf(ContextSupport.msgSender());
  }

  function transfer(address recipient, uint256 amount) internal {
    _transfer(ContextSupport.msgSender(), recipient, amount);
  }

  function allowance(address owner, address spender) internal view returns (uint256) {
    return _erc20Storage().allowances[owner][spender];
  }

  function myAllowance(address owner) internal view returns (uint256) {
    return allowance(owner, ContextSupport.msgSender());
  }

  function approve(address spender, uint256 amount) internal {
    _approve(ContextSupport.msgSender(), spender, amount);
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) internal {
    _transfer(sender, recipient, amount);

    uint256 currentAllowance = _erc20Storage().allowances[sender][ContextSupport.msgSender()];
    require(currentAllowance >= amount, 'ERC20: transfer amount exceeds allowance');

    _approve(sender, ContextSupport.msgSender(), currentAllowance - amount);
  }

  function increaseAllowance(address spender, uint256 addedValue) internal {
    _approve(
      ContextSupport.msgSender(),
      spender,
      _erc20Storage().allowances[ContextSupport.msgSender()][spender] + addedValue
    );
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) internal {
    uint256 currentAllowance = _erc20Storage().allowances[ContextSupport.msgSender()][spender];
    require(currentAllowance >= subtractedValue, 'ERC20: decreased allowance below zero');

    _approve(ContextSupport.msgSender(), spender, currentAllowance - subtractedValue);
  }

  /**
   * @dev Moves tokens `amount` from `sender` to `recipient`.
   *
   * This is internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */
  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal {
    require(sender != address(0), 'ERC20: transfer from the zero address');
    require(recipient != address(0), 'ERC20: transfer to the zero address');

    _beforeTokenTransfer(sender, recipient, amount);

    ERC20Storage storage erc20Storage = _erc20Storage();

    uint256 senderBalance = erc20Storage.balances[sender];
    require(senderBalance >= amount, 'ERC20: transfer amount exceeds balance');
    erc20Storage.balances[sender] = senderBalance - amount;
    erc20Storage.balances[recipient] += amount;

    _afterTokenTransfer(sender, recipient, amount);

    emit Transfer(sender, recipient, amount);
  }

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   */
  function mint(address account, uint256 amount) internal {
    require(account != address(0), 'ERC20: mint to the zero address');

    _beforeMint(account, amount);

    ERC20Storage storage erc20Storage = _erc20Storage();

    erc20Storage.totalSupply += amount;
    erc20Storage.balances[account] += amount;

    _afterMint(account, amount);

    emit Transfer(address(0), account, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  function burn(address account, uint256 amount) internal {
    require(account != address(0), 'ERC20: burn from the zero address');

    _beforeBurn(account, amount);

    ERC20Storage storage erc20Storage = _erc20Storage();

    uint256 accountBalance = erc20Storage.balances[account];
    require(accountBalance >= amount, 'ERC20: burn amount exceeds balance');
    erc20Storage.balances[account] = accountBalance - amount;
    erc20Storage.totalSupply -= amount;

    _afterBurn(account, amount);

    emit Transfer(account, address(0), amount);
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
   *
   * This internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal {
    require(owner != address(0), 'ERC20: approve from the zero address');
    require(spender != address(0), 'ERC20: approve to the zero address');

    _erc20Storage().allowances[owner][spender] = amount;

    emit Approval(owner, spender, amount);
  }

  function addHooks(IConsumableHooks consumableHooks) internal {
    require(address(consumableHooks) != address(0), 'ERC20: adding hook of the zero address');

    _erc20Storage().hooks.add(address(consumableHooks));
  }

  function removeHooks(IConsumableHooks consumableHooks) internal {
    require(address(consumableHooks) != address(0), 'ERC20: removing hook of the zero address');

    _erc20Storage().hooks.remove(address(consumableHooks));
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal {
    bytes memory callData = abi.encodeWithSelector(IConsumableHooks.beforeTokenTransfer.selector, from, to, amount);
    _executeHooks(callData);
  }

  function _afterTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal {
    bytes memory callData = abi.encodeWithSelector(IConsumableHooks.afterTokenTransfer.selector, from, to, amount);
    _executeHooks(callData);
  }

  function _beforeMint(address account, uint256 amount) private {
    bytes memory callData = abi.encodeWithSelector(IConsumableHooks.beforeMint.selector, account, amount);
    _executeHooks(callData);

    _beforeTokenTransfer(address(0), account, amount);
  }

  function _afterMint(address account, uint256 amount) private {
    _afterTokenTransfer(address(0), account, amount);

    bytes memory callData = abi.encodeWithSelector(IConsumableHooks.afterMint.selector, account, amount);
    _executeHooks(callData);
  }

  function _beforeBurn(address account, uint256 amount) private {
    bytes memory callData = abi.encodeWithSelector(IConsumableHooks.beforeBurn.selector, account, amount);
    _executeHooks(callData);

    _beforeTokenTransfer(account, address(0), amount);
  }

  function _afterBurn(address account, uint256 amount) private {
    _afterTokenTransfer(account, address(0), amount);

    bytes memory callData = abi.encodeWithSelector(IConsumableHooks.afterBurn.selector, account, amount);
    _executeHooks(callData);
  }

  function _executeHooks(bytes memory callData) private {
    EnumerableSet.AddressSet storage hooks = _erc20Storage().hooks;
    HookUtils.executeHooks(hooks, callData);
  }

  // have to redeclare here even though they are already declared in IERC20
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/*
 * Copyright (c) 2021 The Paypr Company, LLC
 *
 * This file is part of Paypr Ethereum Contracts.
 *
 * Paypr Ethereum Contracts is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Paypr Ethereum Contracts is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Paypr Ethereum Contracts.  If not, see <https://www.gnu.org/licenses/>.
 */

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.4;

interface IConsumableHooks {
  /**
   * @dev Hook that is called before any transfer of tokens. This includes
   * minting and burning.
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
   * will be to transferred to `to`.
   * - when `from` is zero, `amount` tokens will be minted for `to`.
   * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
   * - `from` and `to` are never both zero.
   */
  function beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) external;

  /**
   * @dev Hook that is called after any transfer of tokens. This includes
   * minting and burning. Called before Transfer event sent.
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
   * will be to transferred to `to`.
   * - when `from` is zero, `amount` tokens will be minted for `to`.
   * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
   * - `from` and `to` are never both zero.
   */
  function afterTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) external;

  /**
   * @dev Hook that is called before minting tokens. Called before any beforeTokenTransfer hooks.
   */
  function beforeMint(address account, uint256 amount) external;

  /**
   * @dev Hook that is called after minting tokens. Called after any afterTokenTransfer hooks.
   */
  function afterMint(address account, uint256 amount) external;

  /**
   * @dev Hook that is called before burning tokens. Called before any beforeTokenTransfer hooks.
   */
  function beforeBurn(address account, uint256 amount) external;

  /**
   * @dev Hook that is called after burning tokens. Called after any afterTokenTransfer hooks.
   */
  function afterBurn(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

/*
 * Copyright (c) 2021 The Paypr Company, LLC
 *
 * This file is part of Paypr Ethereum Contracts.
 *
 * Paypr Ethereum Contracts is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Paypr Ethereum Contracts is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Paypr Ethereum Contracts.  If not, see <https://www.gnu.org/licenses/>.
 */

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

library HookUtils {
  using EnumerableSet for EnumerableSet.AddressSet;

  function executeHooks(EnumerableSet.AddressSet storage hooks, bytes memory callData) internal {
    uint256 hooksLength = hooks.length();

    for (uint256 hookIndex = 0; hookIndex < hooksLength; hookIndex++) {
      address hook = hooks.at(hookIndex);

      // solhint-disable-next-line avoid-low-level-calls
      (bool success, bytes memory error) = address(hook).delegatecall(callData);
      if (!success) {
        if (error.length > 0) {
          // bubble up the error
          // solhint-disable-next-line no-inline-assembly
          assembly {
            let ptr := mload(0x40)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            revert(ptr, size)
          }
        } else {
          revert(string(abi.encodePacked('Hook function failed: ', Strings.toHexString(uint160(hook)))));
        }
      }
    }
  }
}

/*
 * Copyright (c) 2021 The Paypr Company, LLC
 *
 * This file is part of Paypr Ethereum Contracts.
 *
 * Paypr Ethereum Contracts is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Paypr Ethereum Contracts is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Paypr Ethereum Contracts.  If not, see <https://www.gnu.org/licenses/>.
 */

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/Strings.sol';
import './IAccessControl.sol';
import './IAccessCheck.sol';
import '../context/ContextSupport.sol';

library AccessCheckSupport {
  /**
   * @dev Revert with a standard message if message sender is missing the admin role for `role`.
   *
   * See {buildMissingRoleMessage(bytes32, address)} for the revert reason format
   */
  function checkAdminRole(bytes32 role) internal view {
    bytes32 adminRole = (IAccessControl(address(this)).getRoleAdmin(role));

    checkRole(adminRole);
  }

  /**
   * @dev Revert with a standard message if message sender is missing `role`.
   *
   * See {buildMissingRoleMessage(bytes32, address)} for the revert reason format
   */
  function checkRole(bytes32 role) internal view {
    address account = ContextSupport.msgSender();

    if (IAccessCheck(address(this)).hasRole(role, account)) {
      return;
    }

    revert(buildMissingRoleMessage(role, account));
  }

  /**
   * Builds a revert reason in the following format:
   *   AccessControl: account {account} is missing role {role}
   */
  function buildMissingRoleMessage(bytes32 role, address account) internal pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          'AccessCheck: account ',
          Strings.toHexString(uint160(account), 20),
          ' is missing role ',
          Strings.toHexString(uint256(role), 32)
        )
      );
  }
}

/*
 * Copyright (c) 2021 The Paypr Company, LLC
 *
 * This file is part of Paypr Ethereum Contracts.
 *
 * Paypr Ethereum Contracts is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Paypr Ethereum Contracts is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Paypr Ethereum Contracts.  If not, see <https://www.gnu.org/licenses/>.
 */

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.4;

library RoleSupport {
  bytes32 public constant SUPER_ADMIN_ROLE = 0x00;
  bytes32 public constant ADMIN_ROLE = keccak256('paypr.Admin');
  bytes32 public constant DELEGATE_ADMIN_ROLE = keccak256('paypr.DelegateAdmin');
  bytes32 public constant DIAMOND_CUTTER_ROLE = keccak256('paypr.DiamondCutter');
  bytes32 public constant DISABLER_ROLE = keccak256('paypr.Disabler');
  bytes32 public constant LIMITER_ROLE = keccak256('paypr.Limiter');
  bytes32 public constant MINTER_ROLE = keccak256('paypr.Minter');
  bytes32 public constant TRANSFER_AGENT_ROLE = keccak256('paypr.Transfer');
}

/*
 * Copyright (c) 2021 The Paypr Company, LLC
 *
 * This file is part of Paypr Ethereum Contracts.
 *
 * Paypr Ethereum Contracts is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Paypr Ethereum Contracts is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Paypr Ethereum Contracts.  If not, see <https://www.gnu.org/licenses/>.
 */

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.4;

library ContextSupport {
  function msgSender() internal view returns (address) {
    return msg.sender;
  }

  function msgData() internal pure returns (bytes memory) {
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

/*
 * Copyright (c) 2021 The Paypr Company, LLC
 *
 * This file is part of Paypr Ethereum Contracts.
 *
 * Paypr Ethereum Contracts is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Paypr Ethereum Contracts is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Paypr Ethereum Contracts.  If not, see <https://www.gnu.org/licenses/>.
 */

/*
 * Concept and implementation based on OpenZeppelin Contracts AccessControl:
 * https://openzeppelin.com/contracts/
 */

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.4;

import './IAccessCheck.sol';

/**
 * @dev Supports implementations of role-based access control mechanisms.
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
 * Complex role relationships can be created by using {setRoleAdmin}.
 */
interface IAccessControl {
  /**
   * @notice Returns the admin role that controls `role`. See {grantRole} and {revokeRole}.
   *
   * To change a role's admin, use {setRoleAdmin}.
   */
  function getRoleAdmin(bytes32 role) external view returns (bytes32);

  /**
   * @notice Grants `role` to `account`.
   *
   * If `account` had not been already granted `role`, emits a {RoleGranted} event.
   *
   * Requirements:
   *
   * - the caller must have ``role``'s admin role.
   */
  function grantRole(bytes32 role, address account) external;

  /**
   * @notice Revokes `role` from `account`.
   *
   * If `account` had been granted `role`, emits a {RoleRevoked} event.
   *
   * Requirements:
   *
   * - the caller must have ``role``'s admin role.
   */
  function revokeRole(bytes32 role, address account) external;

  /**
   * @notice Revokes `role` from the calling account.
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
  function renounceRole(bytes32 role) external;

  /**
   * @notice Sets `adminRole` as ``role``'s admin role.
   *
   * Emits a {RoleAdminChanged} event.
   *
   * Requirements:
   *
   * - the caller must have ``role``'s admin role.
   */
  function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

  /**
   * @notice Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
   *
   * `sender` is the account that originated the contract call, an admin role bearer
   */
  event RoleAdminChanged(
    bytes32 indexed role,
    bytes32 previousAdminRole,
    bytes32 indexed newAdminRole,
    address indexed sender
  );

  /**
   * @notice Emitted when `account` is granted `role`.
   *
   * `sender` is the account that originated the contract call, an admin role bearer
   */
  event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

  /**
   * @notice Emitted when `account` is revoked `role`.
   *
   * `sender` is the account that originated the contract call:
   *   - if using `revokeRole`, it is the admin role bearer
   *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
   */
  event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
}

/*
 * Copyright (c) 2021 The Paypr Company, LLC
 *
 * This file is part of Paypr Ethereum Contracts.
 *
 * Paypr Ethereum Contracts is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Paypr Ethereum Contracts is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Paypr Ethereum Contracts.  If not, see <https://www.gnu.org/licenses/>.
 */

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.4;

interface IAccessCheck {
  /**
   * @notice Returns `true` if `account` has been granted `role`.
   */
  function hasRole(bytes32 role, address account) external view returns (bool);
}