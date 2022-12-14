// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173 } from '../../interfaces/IERC173.sol';

interface IOwnable is IERC173 {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173Internal } from '../../interfaces/IERC173Internal.sol';

interface IOwnableInternal is IERC173Internal {
    error Ownable__NotOwner();
    error Ownable__NotTransitiveOwner();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173 } from '../../interfaces/IERC173.sol';
import { IOwnable } from './IOwnable.sol';
import { OwnableInternal } from './OwnableInternal.sol';
import { OwnableStorage } from './OwnableStorage.sol';

/**
 * @title Ownership access control based on ERC173
 */
abstract contract Ownable is IOwnable, OwnableInternal {
    using OwnableStorage for OwnableStorage.Layout;

    /**
     * @inheritdoc IERC173
     */
    function owner() public view virtual returns (address) {
        return _owner();
    }

    /**
     * @inheritdoc IERC173
     */
    function transferOwnership(address account) public virtual onlyOwner {
        _transferOwnership(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173 } from '../../interfaces/IERC173.sol';
import { AddressUtils } from '../../utils/AddressUtils.sol';
import { IOwnableInternal } from './IOwnableInternal.sol';
import { OwnableStorage } from './OwnableStorage.sol';

abstract contract OwnableInternal is IOwnableInternal {
    using AddressUtils for address;
    using OwnableStorage for OwnableStorage.Layout;

    modifier onlyOwner() {
        if (msg.sender != _owner()) revert Ownable__NotOwner();
        _;
    }

    modifier onlyTransitiveOwner() {
        if (msg.sender != _transitiveOwner())
            revert Ownable__NotTransitiveOwner();
        _;
    }

    function _owner() internal view virtual returns (address) {
        return OwnableStorage.layout().owner;
    }

    function _transitiveOwner() internal view virtual returns (address) {
        address owner = _owner();

        while (owner.isContract()) {
            try IERC173(owner).owner() returns (address transitiveOwner) {
                owner = transitiveOwner;
            } catch {
                return owner;
            }
        }

        return owner;
    }

    function _transferOwnership(address account) internal virtual {
        OwnableStorage.layout().setOwner(account);
        emit OwnershipTransferred(msg.sender, account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library OwnableStorage {
    struct Layout {
        address owner;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.Ownable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setOwner(Layout storage l, address owner) internal {
        l.owner = owner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Set implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableSet {
    error EnumerableSet__IndexOutOfBounds();

    struct Set {
        bytes32[] _values;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct Bytes32Set {
        Set _inner;
    }

    struct AddressSet {
        Set _inner;
    }

    struct UintSet {
        Set _inner;
    }

    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }

    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    function indexOf(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, value);
    }

    function indexOf(AddressSet storage set, address value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, bytes32(uint256(uint160(value))));
    }

    function indexOf(UintSet storage set, uint256 value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, bytes32(value));
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    function toArray(Bytes32Set storage set)
        internal
        view
        returns (bytes32[] memory)
    {
        uint256 len = _length(set._inner);
        bytes32[] memory arr = new bytes32[](len);

        unchecked {
            for (uint256 index; index < len; ++index) {
                arr[index] = at(set, index);
            }
        }

        return arr;
    }

    function toArray(AddressSet storage set)
        internal
        view
        returns (address[] memory)
    {
        uint256 len = _length(set._inner);
        address[] memory arr = new address[](len);

        unchecked {
            for (uint256 index; index < len; ++index) {
                arr[index] = at(set, index);
            }
        }

        return arr;
    }

    function toArray(UintSet storage set)
        internal
        view
        returns (uint256[] memory)
    {
        uint256 len = _length(set._inner);
        uint256[] memory arr = new uint256[](len);

        unchecked {
            for (uint256 index; index < len; ++index) {
                arr[index] = at(set, index);
            }
        }

        return arr;
    }

    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        if (index >= set._values.length)
            revert EnumerableSet__IndexOutOfBounds();
        return set._values[index];
    }

    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    function _indexOf(Set storage set, bytes32 value)
        private
        view
        returns (uint256)
    {
        unchecked {
            return set._indexes[value] - 1;
        }
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            unchecked {
                bytes32 last = set._values[set._values.length - 1];

                // move last value to now-vacant index

                set._values[valueIndex - 1] = last;
                set._indexes[last] = valueIndex;
            }
            // clear last index

            set._values.pop();
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173Internal } from './IERC173Internal.sol';

/**
 * @title Contract ownership standard interface
 * @dev see https://eips.ethereum.org/EIPS/eip-173
 */
interface IERC173 is IERC173Internal {
    /**
     * @notice get the ERC173 contract owner
     * @return conrtact owner
     */
    function owner() external view returns (address);

    /**
     * @notice transfer contract ownership to new account
     * @param account address of new owner
     */
    function transferOwnership(address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC173 interface needed by internal functions
 */
interface IERC173Internal {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { UintUtils } from './UintUtils.sol';

library AddressUtils {
    using UintUtils for uint256;

    error AddressUtils__InsufficientBalance();
    error AddressUtils__NotContract();
    error AddressUtils__SendValueFailed();

    function toString(address account) internal pure returns (string memory) {
        return uint256(uint160(account)).toHexString(20);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable account, uint256 amount) internal {
        (bool success, ) = account.call{ value: amount }('');
        if (!success) revert AddressUtils__SendValueFailed();
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionCall(target, data, 'AddressUtils: failed low-level call');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory error
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, error);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                'AddressUtils: failed low-level call with value'
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) internal returns (bytes memory) {
        if (value > address(this).balance)
            revert AddressUtils__InsufficientBalance();
        return _functionCallWithValue(target, data, value, error);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) private returns (bytes memory) {
        if (!isContract(target)) revert AddressUtils__NotContract();

        (bool success, bytes memory returnData) = target.call{ value: value }(
            data
        );

        if (success) {
            return returnData;
        } else if (returnData.length > 0) {
            assembly {
                let returnData_size := mload(returnData)
                revert(add(32, returnData), returnData_size)
            }
        } else {
            revert(error);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title utility functions for uint256 operations
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library UintUtils {
    error UintUtils__InsufficientHexLength();

    bytes16 private constant HEX_SYMBOLS = '0123456789abcdef';

    function add(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? sub(a, -b) : a + uint256(b);
    }

    function sub(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? add(a, -b) : a - uint256(b);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0';
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

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0x00';
        }

        uint256 length = 0;

        for (uint256 temp = value; temp != 0; temp >>= 8) {
            unchecked {
                length++;
            }
        }

        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';

        unchecked {
            for (uint256 i = 2 * length + 1; i > 1; --i) {
                buffer[i] = HEX_SYMBOLS[value & 0xf];
                value >>= 4;
            }
        }

        if (value != 0) revert UintUtils__InsufficientHexLength();

        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {AllowList, AllowListStorage} from "../utils/AllowList/AllowList.sol";

import {EnumerableSet} from "@solidstate/contracts/data/EnumerableSet.sol";

contract AllowListFacet is AllowList {
    using AllowListStorage for AllowListStorage.Layout;
    using EnumerableSet for EnumerableSet.AddressSet;
    struct AllowListMap {
        address account;
        uint256 allowance;
    }

    function allowListEnabled() external view returns (bool enabled) {
        return AllowListStorage.layout().allowListEnabled;
    }

    function enableAllowList() external onlyOwner {
        _enableAllowList();
    }

    function disableAllowList() external onlyOwner {
        _disableAllowList();
    }

    function allowList()
        external
        view
        returns (AllowListMap[] memory allowListMap)
    {
        allowListMap = new AllowListMap[](
            AllowListStorage.layout().allowList.length()
        );
        uint256 allowListLength = AllowListStorage.layout().allowList.length();
        uint256 i = 0;
        for (; i < allowListLength; ) {
            address addressAtIndex = AllowListStorage.layout().allowList.at(i);
            allowListMap[i].account = addressAtIndex;
            allowListMap[i].allowance = AllowListStorage.layout().allowance[
                addressAtIndex
            ];
            ++i;
        }

        return allowListMap; // This is redundant but explicit. Keep or remove?
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {AllowListStorage} from "./AllowListStorage.sol";
import {AllowListInternal} from "./AllowListInternal.sol";
import {OwnableInternal} from "@solidstate/contracts/access/ownable/Ownable.sol";

contract AllowList is AllowListInternal, OwnableInternal {
    using AllowListStorage for AllowListStorage.Layout;

    function _enableAllowList() internal {
        if (AllowListStorage.layout().allowListEnabled) {
            revert AllowListEnabled();
        }

        AllowListStorage.layout().allowListEnabled = true;

        emit AllowListStatus(true);
    }

    function _disableAllowList() internal {
        if (!AllowListStorage.layout().allowListEnabled) {
            revert AllowListEnabled();
        }

        AllowListStorage.layout().allowListEnabled = false;

        emit AllowListStatus(false);
    }

    function addToAllowList(address account) external onlyOwner {
        _addToAllowList(account, 0);
    }

    function addToAllowList(
        address account,
        uint256 allowance
    ) external onlyOwner {
        _addToAllowList(account, allowance);
    }

    function addToAllowList(address[] calldata accounts) external onlyOwner {
        _addToAllowList(accounts, 0);
    }

    function addToAllowList(
        address[] calldata accounts,
        uint256 allowance
    ) external onlyOwner {
        _addToAllowList(accounts, allowance);
    }

    function removeFromAllowList(address account) external onlyOwner {
        _removeFromAllowList(account);
    }

    function removeFromAllowList(
        address[] calldata accounts
    ) external onlyOwner {
        _removeFromAllowList(accounts);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {AllowListStorage} from "./AllowListStorage.sol";
import {IAllowListInternal} from "./IAllowListInternal.sol";
import {EnumerableSet} from "@solidstate/contracts/data/EnumerableSet.sol";

contract AllowListInternal is IAllowListInternal {
    using AllowListStorage for AllowListStorage.Layout;
    using EnumerableSet for EnumerableSet.AddressSet;

    modifier allowListed(address account) {
        if (!AllowListStorage.layout().allowList.contains(account)) {
            revert AccountNotAllowListed();
        }

        _;
    }

    function allowListAllowance(
        address account
    ) internal view allowListed(account) returns (uint256) {
        return AllowListStorage.layout().allowance[account];
    }

    function _addToAllowList(address _account, uint256 _allowance) internal {
        // If the account is already in the allowList, we don't want to add it again.
        if (AllowListStorage.layout().allowList.contains(_account)) {
            revert AccountAlreadyAllowListed();
        }
        AllowListStorage.layout().allowList.add(_account);
        AllowListStorage.layout().allowance[_account] = _allowance;

        emit AllowListAdded(_account, _allowance);
    }

    function _addToAllowList(
        address[] calldata _accounts,
        uint256 _allowance
    ) internal {
        uint256 accountsLength = _accounts.length;
        uint256 i = 0;
        for (; i < accountsLength; ) {
            if (AllowListStorage.layout().allowList.contains(_accounts[i])) {
                revert AccountAlreadyAllowListed();
            }
            AllowListStorage.layout().allowList.add(_accounts[i]);
            AllowListStorage.layout().allowance[_accounts[i]] = _allowance;
            ++i;
        }

        emit AllowListAdded(_accounts, _allowance);
    }

    function _removeFromAllowList(address _account) internal {
        if (!AllowListStorage.layout().allowList.contains(_account)) {
            revert AccountNotAllowListed();
        }

        AllowListStorage.layout().allowList.remove(_account);
        delete AllowListStorage.layout().allowance[_account];

        emit AllowListRemoved(_account);
    }

    function _removeFromAllowList(address[] calldata _accounts) internal {
        uint256 accountsLength = _accounts.length;
        uint256 i = 0;
        for (; i < accountsLength; ) {
            if (!AllowListStorage.layout().allowList.contains(_accounts[i])) {
                revert AccountNotAllowListed();
            }

            AllowListStorage.layout().allowList.remove(_accounts[i]);
            delete AllowListStorage.layout().allowance[_accounts[i]];
            ++i;
        }

        emit AllowListRemoved(_accounts);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {EnumerableSet} from "@solidstate/contracts/data/EnumerableSet.sol";
import {Ownable, OwnableStorage} from "@solidstate/contracts/access/ownable/Ownable.sol";

library AllowListStorage {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct Layout {
        bool allowListEnabled;
        // mapping(address => bool) allowList;
        EnumerableSet.AddressSet allowList; // How many the user may mint
        mapping(address => uint256) allowance; // How many the user may mint
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("lively.contracts.storage.AllowList");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IAllowListInternal {
    error AccountNotAllowListed();
    error AccountAlreadyAllowListed();
    error AllowListEnabled();
    error AllowListDisabled();

    event AllowListStatus(bool status);
    event AllowListAdded(address account, uint256 allowance);
    event AllowListAdded(address[] accounts, uint256 allowance);
    event AllowListRemoved(address account);
    event AllowListRemoved(address[] accounts);
}