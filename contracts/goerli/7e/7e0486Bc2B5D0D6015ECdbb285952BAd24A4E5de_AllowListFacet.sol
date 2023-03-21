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

    function at(
        Bytes32Set storage set,
        uint256 index
    ) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    function at(
        AddressSet storage set,
        uint256 index
    ) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function at(
        UintSet storage set,
        uint256 index
    ) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    function contains(
        Bytes32Set storage set,
        bytes32 value
    ) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function contains(
        AddressSet storage set,
        address value
    ) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(
        UintSet storage set,
        uint256 value
    ) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function indexOf(
        Bytes32Set storage set,
        bytes32 value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, value);
    }

    function indexOf(
        AddressSet storage set,
        address value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, bytes32(uint256(uint160(value))));
    }

    function indexOf(
        UintSet storage set,
        uint256 value
    ) internal view returns (uint256) {
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

    function add(
        Bytes32Set storage set,
        bytes32 value
    ) internal returns (bool) {
        return _add(set._inner, value);
    }

    function add(
        AddressSet storage set,
        address value
    ) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(
        Bytes32Set storage set,
        bytes32 value
    ) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function remove(
        AddressSet storage set,
        address value
    ) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(
        UintSet storage set,
        uint256 value
    ) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function toArray(
        Bytes32Set storage set
    ) internal view returns (bytes32[] memory) {
        return set._inner._values;
    }

    function toArray(
        AddressSet storage set
    ) internal view returns (address[] memory) {
        bytes32[] storage values = set._inner._values;
        address[] storage array;

        assembly {
            array.slot := values.slot
        }

        return array;
    }

    function toArray(
        UintSet storage set
    ) internal view returns (uint256[] memory) {
        bytes32[] storage values = set._inner._values;
        uint256[] storage array;

        assembly {
            array.slot := values.slot
        }

        return array;
    }

    function _at(
        Set storage set,
        uint256 index
    ) private view returns (bytes32) {
        if (index >= set._values.length)
            revert EnumerableSet__IndexOutOfBounds();
        return set._values[index];
    }

    function _contains(
        Set storage set,
        bytes32 value
    ) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _indexOf(
        Set storage set,
        bytes32 value
    ) private view returns (uint256) {
        unchecked {
            return set._indexes[value] - 1;
        }
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _add(
        Set storage set,
        bytes32 value
    ) private returns (bool status) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            status = true;
        }
    }

    function _remove(
        Set storage set,
        bytes32 value
    ) private returns (bool status) {
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

            status = true;
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

    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
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

    /**
     * @notice execute arbitrary external call with limited gas usage and amount of copied return data
     * @dev derived from https://github.com/nomad-xyz/ExcessivelySafeCall (MIT License)
     * @param target recipient of call
     * @param gasAmount gas allowance for call
     * @param value native token value to include in call
     * @param maxCopy maximum number of bytes to copy from return data
     * @param data encoded call data
     * @return success whether call is successful
     * @return returnData copied return data
     */
    function excessivelySafeCall(
        address target,
        uint256 gasAmount,
        uint256 value,
        uint16 maxCopy,
        bytes memory data
    ) internal returns (bool success, bytes memory returnData) {
        returnData = new bytes(maxCopy);

        assembly {
            // execute external call via assembly to avoid automatic copying of return data
            success := call(
                gasAmount,
                target,
                value,
                add(data, 0x20),
                mload(data),
                0,
                0
            )

            // determine whether to limit amount of data to copy
            let toCopy := returndatasize()

            if gt(toCopy, maxCopy) {
                toCopy := maxCopy
            }

            // store the length of the copied bytes
            mstore(returnData, toCopy)

            // copy the bytes from returndata[0:toCopy]
            returndatacopy(add(returnData, 0x20), 0, toCopy)
        }
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

    function toHexString(
        uint256 value,
        uint256 length
    ) internal pure returns (string memory) {
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
pragma solidity ^0.8.18;

import {AllowList, AllowListStorage} from "../utils/AllowList/AllowList.sol";
import {EnumerableSet} from "@solidstate/contracts/data/EnumerableSet.sol";

contract AllowListFacet is AllowList {
    using AllowListStorage for AllowListStorage.Layout;
    using EnumerableSet for EnumerableSet.AddressSet;

    string constant NAME = "AllowListFacet2";

    struct AllowListMap {
        address account;
        uint256 allowance;
    }

    /// 721's can use tokenId 0
    function allowListEnabled(
        uint256 _tokenId
    ) external view returns (bool enabled) {
        enabled = AllowListStorage.layout().allowListEnabled[_tokenId];
    }

    /// 721's can use tokenId 0
    function enableAllowList(uint256 _tokenId) external onlyOwner {
        _enableAllowList(_tokenId);
    }

    /// 721's can use tokenId 0
    function disableAllowList(uint256 _tokenId) external onlyOwner {
        _disableAllowList(_tokenId);
    }

    /// 721's can use tokenId 0
    function allowList(
        uint256 _tokenId
    ) external view returns (AllowListMap[] memory allowListMap) {
        AllowListStorage.Layout storage als = AllowListStorage.layout();
        uint256 allowListLength = als.allowList[_tokenId].length();
        allowListMap = new AllowListMap[](allowListLength);
        uint256 i = 0;
        for (; i < allowListLength; ) {
            address addressAtIndex = als.allowList[_tokenId].at(i);
            allowListMap[i].account = addressAtIndex;
            allowListMap[i].allowance = als.allowance[_tokenId][addressAtIndex];
            ++i;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AllowListStorage} from "./AllowListStorage.sol";
import {AllowListInternal} from "./AllowListInternal.sol";
import {
    OwnableInternal
} from "@solidstate/contracts/access/ownable/Ownable.sol";
import {EnumerableSet} from "@solidstate/contracts/data/EnumerableSet.sol";

contract AllowList is AllowListInternal, OwnableInternal {
    using AllowListStorage for AllowListStorage.Layout;

    function _enableAllowList(uint256 tokenId) internal {
        AllowListStorage.Layout storage als = AllowListStorage.layout();

        if (als.allowListEnabled[tokenId]) revert AllowListEnabled();

        als.allowListEnabled[tokenId] = true;

        emit AllowListStatus(tokenId, true);
    }

    function _disableAllowList(uint256 tokenId) internal {
        AllowListStorage.Layout storage als = AllowListStorage.layout();

        if (!als.allowListEnabled[tokenId]) revert AllowListEnabled();

        als.allowListEnabled[tokenId] = false;

        emit AllowListStatus(tokenId, false);
    }

    function addToAllowList(
        uint256 tokenId,
        address account
    ) external onlyOwner {
        _addToAllowList(tokenId, account, 0, 0);
    }

    function addToAllowList(
        uint256 tokenId,
        address account,
        uint256 allowance
    ) external onlyOwner {
        _addToAllowList(tokenId, account, allowance, 0);
    }

    function addToAllowList(
        uint256 tokenId,
        address account,
        uint256 allowance,
        uint256 allowTime
    ) external onlyOwner {
        _addToAllowList(tokenId, account, allowance, allowTime);
    }

    function addToAllowList(
        uint256 tokenId,
        address[] calldata accounts
    ) external onlyOwner {
        _addToAllowList(tokenId, accounts, 0, 0);
    }

    function addToAllowList(
        uint256 tokenId,
        address[] calldata accounts,
        uint256 allowance
    ) external onlyOwner {
        _addToAllowList(tokenId, accounts, allowance, 0);
    }

    function addToAllowList(
        uint256 tokenId,
        address[] calldata accounts,
        uint256 allowance,
        uint256 allowTime
    ) external onlyOwner {
        _addToAllowList(tokenId, accounts, allowance, allowTime);
    }

    function removeFromAllowList(
        uint256 tokenId,
        address account
    ) external onlyOwner {
        _removeFromAllowList(tokenId, account);
    }

    function removeFromAllowList(
        uint256 tokenId,
        address[] calldata accounts
    ) external onlyOwner {
        _removeFromAllowList(tokenId, accounts);
    }

    function allowListContains(
        uint256 tokenId,
        address account
    ) external view returns (bool contains) {
        return _allowListContains(tokenId, account);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AllowListStorage} from "./AllowListStorage.sol";
import {IAllowListInternal} from "./IAllowListInternal.sol";
import {EnumerableSet} from "@solidstate/contracts/data/EnumerableSet.sol";

contract AllowListInternal is IAllowListInternal {
    // using AllowListStorage for AllowListStorage.Layout;
    using EnumerableSet for EnumerableSet.AddressSet;

    modifier allowListed(uint256 tokenId, address account) {
        if (!AllowListStorage.layout().allowList[tokenId].contains(account)) {
            revert AccountNotAllowListed();
        }

        _;
    }

    function isAllowListed(
        uint256 tokenId,
        address account
    ) internal view returns (bool) {
        return AllowListStorage.layout().allowList[tokenId].contains(account);
    }

    function _allowListAllowance(
        uint256 tokenId,
        address account
    ) internal view allowListed(tokenId, account) returns (uint256) {
        return AllowListStorage.layout().allowance[tokenId][account];
    }

    function _addToAllowList(
        uint256 tokenId,
        address _account,
        uint256 _allowance,
        uint256 _allowTime
    ) internal {
        // If the account is already in the allowList, we don't want to add it again.
        AllowListStorage.Layout storage als = AllowListStorage.layout();

        if (als.allowList[tokenId].contains(_account)) {
            revert AccountAlreadyAllowListed();
        }

        als.allowList[tokenId].add(_account);
        als.allowance[tokenId][_account] = _allowance;
        als.allowTime[tokenId][_account] = _allowTime;

        emit AllowListAdded(tokenId, _account, _allowance);
    }

    function _addToAllowList(
        uint256 tokenId,
        address[] calldata _accounts,
        uint256 _allowance
    ) internal {
        AllowListStorage.Layout storage als = AllowListStorage.layout();

        uint256 accountsLength = _accounts.length;
        uint256 i = 0;
        for (; i < accountsLength; ) {
            if (als.allowList[tokenId].contains(_accounts[i])) {
                revert AccountAlreadyAllowListed();
            }
            als.allowList[tokenId].add(_accounts[i]);
            als.allowance[tokenId][_accounts[i]] = _allowance;
            ++i;
        }

        emit AllowListAdded(tokenId, _accounts, _allowance);
    }

    function _addToAllowList(
        uint256 tokenId,
        address[] calldata _accounts,
        uint256 _allowance,
        uint256 _allowTime
    ) internal {
        AllowListStorage.Layout storage als = AllowListStorage.layout();
        uint256 accountsLength = _accounts.length;
        uint256 i = 0;
        for (; i < accountsLength; ) {
            if (als.allowList[tokenId].contains(_accounts[i])) {
                revert AccountAlreadyAllowListed();
            }
            als.allowList[tokenId].add(_accounts[i]);
            als.allowance[tokenId][_accounts[i]] = _allowance;
            als.allowTime[tokenId][_accounts[i]] = _allowTime;
            ++i;
        }

        emit AllowListAdded(tokenId, _accounts, _allowance);
    }

    function _removeFromAllowList(uint256 tokenId, address _account) internal {
        AllowListStorage.Layout storage als = AllowListStorage.layout();

        if (!als.allowList[tokenId].contains(_account)) {
            revert AccountNotAllowListed();
        }

        als.allowList[tokenId].remove(_account);
        delete als.allowance[tokenId][_account];

        emit AllowListRemoved(tokenId, _account);
    }

    function _removeFromAllowList(
        uint256 tokenId,
        address[] calldata _accounts
    ) internal {
        AllowListStorage.Layout storage als = AllowListStorage.layout();

        uint256 accountsLength = _accounts.length;
        uint256 i = 0;
        for (; i < accountsLength; ) {
            if (!als.allowList[tokenId].contains(_accounts[i])) {
                revert AccountNotAllowListed();
            }

            als.allowList[tokenId].remove(_accounts[i]);
            delete als.allowance[tokenId][_accounts[i]];
            ++i;
        }

        emit AllowListRemoved(tokenId, _accounts);
    }

    function _allowListContains(
        uint256 tokenId,
        address _account
    ) internal view returns (bool) {
        return AllowListStorage.layout().allowList[tokenId].contains(_account);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {EnumerableSet} from "@solidstate/contracts/data/EnumerableSet.sol";
import {
    Ownable,
    OwnableStorage
} from "@solidstate/contracts/access/ownable/Ownable.sol";

library AllowListStorage {
    using EnumerableSet for EnumerableSet.AddressSet;
    // struct AllowListStruct {
    //     bool allowListEnabled;
    //     EnumerableSet.AddressSet allowList; // Users who may mint
    //     mapping(address => uint256) allowance; // How many the user may mint
    //     mapping(address => uint256) allowTime; // When the user may mint
    //     mapping(address => uint256) minted; // How many the user has minted
    // }

    /**
     * @dev Before protocal publication we can remove these deprecated items but for upgradeability we need to keep them
     */
    struct Layout {
        mapping(uint256 => bool) allowListEnabled;
        mapping(uint256 => EnumerableSet.AddressSet) allowList;
        mapping(uint256 => mapping(address => uint256)) allowance;
        mapping(uint256 => mapping(address => uint256)) allowTime;
        mapping(uint256 => mapping(address => uint256)) minted;
        // mapping(uint256 => AllowListStruct) allowLists; // Mapping between tokenId and allowList
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
pragma solidity ^0.8.18;

interface IAllowListInternal {
    error AccountNotAllowListed();
    error AccountAlreadyAllowListed();
    error AllowListEnabled();
    error AllowListDisabled();
    error MintNotOpen();
    error NotOnAllowList();
    error AllowListAmountExceeded();
    error AllowListMintUnopened();

    event AllowListStatus(bool status);
    event AllowListAdded(address account, uint256 allowance);
    event AllowListAdded(address[] accounts, uint256 allowance);
    event AllowListRemoved(address account);
    event AllowListRemoved(address[] accounts);

    event AllowListStatus(uint256 tokenId, bool status);
    event AllowListAdded(uint256 tokenId, address account, uint256 allowance);
    event AllowListAdded(
        uint256 tokenId,
        address[] accounts,
        uint256 allowance
    );
    event AllowListRemoved(uint256 tokenId, address account);
    event AllowListRemoved(uint256 tokenId, address[] accounts);
}