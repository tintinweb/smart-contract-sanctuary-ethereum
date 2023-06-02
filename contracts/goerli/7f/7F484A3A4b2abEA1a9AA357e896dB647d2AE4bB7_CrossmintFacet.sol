// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {CoinSwapper} from "../../shared/libraries/CoinSwapper.sol";
import {
    ISolidStateERC20
} from "@solidstate/contracts/token/ERC20/ISolidStateERC20.sol";
import {
    ERC1155,
    ERC1155Storage,
    OwnableStorage
} from "../abstracts/ERC1155.sol";
import {LibDiamond} from "../../shared/libraries/LibDiamond.sol";
import {ERC1155Facet} from "./ERC1155Facet.sol";

contract CrossmintFacet is ERC1155 {
    string private constant CONTRACT_VERSION = "0.0.1";

    ISolidStateERC20 private immutable usdc;

    error NotCrossmintUSDCToken();

    constructor() payable {
        usdc = ISolidStateERC20(CoinSwapper.getUSDCAddress());
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        MintType mintType
    ) external {
        // if (mintType == MintType.SINGLE) {
        //     ERC1155Facet(address(this)).mint{value: msg.value}(
        //         account,
        //         id,
        //         amount
        //     );
        // } else if (mintType == MintType.PACK) {
        //     ERC1155Facet(address(this)).packMint.mint{value: msg.value}(
        //         account,
        //         id,
        //         amount
        //     );
        // } else

        if (mintType == MintType.CROSSMINT_USDC_SINGLE) {
            crossmintMint(account, id, amount);
        } else if (mintType == MintType.CROSSMINT_USDC_PACK) {
            crossmintPackMint(account, id, amount);
        } else {
            revert InvalidMintType();
        }
    }

    function crossmintMint(
        address account,
        uint256 id,
        uint256 amount
    ) public validTokenID(id) validQuantity(id, amount) validTime(id, amount) {
        ERC1155Storage.TokenStructure memory l = ERC1155Storage
            .layout()
            .tokenData[id];
        if (!l.isCrossmintUSDC) revert NotCrossmintUSDCToken();

        usdc.transferFrom(
            msg.sender,
            address(this),
            l.price * amount * 10 ** 4
        );

        _mint(account, id, amount, "");
    }

    function crossmintPackMint(
        address account,
        uint256 packId,
        uint256 amount
    ) public {
        ERC1155Storage.Layout storage l = ERC1155Storage.layout();
        ERC1155Storage.PackStructure storage pack = l.packData[packId];

        uint256 batchLength = pack.tokenIds.length;
        uint256[] memory amounts = new uint256[](batchLength);

        // Check valid quantity TODO: Move to modifier
        uint256 i;
        uint256 tokenId;
        uint256 tokensMaxSupply;
        for (; i < batchLength; ++i) {
            tokenId = pack.tokenIds[i];
            tokensMaxSupply = l.tokenData[tokenId].maxSupply;

            if (tokensMaxSupply > 0)
                if (_totalSupply(tokenId) + amount > tokensMaxSupply)
                    revert ExceedsMaxSupply();
        }

        // Check batch start time TODO: Move to modifier
        if (msg.sender != OwnableStorage.layout().owner) {
            if (block.timestamp < pack.startTime) revert MintNotOpen();
        }

        // Build amounts array
        for (i = 0; i < batchLength; ) {
            amounts[i] = amount;
            ++i;
        }

        // Price check not necessary as this will fail if msg.sender has not authorized enough USDC
        usdc.transferFrom(
            msg.sender,
            address(this),
            pack.price * amount * 10 ** 4
        );

        _mintBatch(account, pack.tokenIds, amounts, "");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64Upgradeable {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

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

import { IERC165 } from './IERC165.sol';
import { IERC1155Internal } from './IERC1155Internal.sol';

/**
 * @title ERC1155 interface
 * @dev see https://github.com/ethereum/EIPs/issues/1155
 */
interface IERC1155 is IERC1155Internal, IERC165 {
    /**
     * @notice query the balance of given token held by given address
     * @param account address to query
     * @param id token to query
     * @return token balance
     */
    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256);

    /**
     * @notice query the balances of given tokens held by given addresses
     * @param accounts addresss to query
     * @param ids tokens to query
     * @return token balances
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    /**
     * @notice query approval status of given operator with respect to given address
     * @param account address to query for approval granted
     * @param operator address to query for approval received
     * @return whether operator is approved to spend tokens held by account
     */
    function isApprovedForAll(
        address account,
        address operator
    ) external view returns (bool);

    /**
     * @notice grant approval to or revoke approval from given operator to spend held tokens
     * @param operator address whose approval status to update
     * @param status whether operator should be considered approved
     */
    function setApprovalForAll(address operator, bool status) external;

    /**
     * @notice transfer tokens between given addresses, checking for ERC1155Receiver implementation if applicable
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     * @param data data payload
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @notice transfer batch of tokens between given addresses, checking for ERC1155Receiver implementation if applicable
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param ids list of token IDs
     * @param amounts list of quantities of tokens to transfer
     * @param data data payload
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

pragma solidity ^0.8.8;

/**
 * @title Partial ERC1155 interface needed by internal functions
 */
interface IERC1155Internal {
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165 } from './IERC165.sol';

/**
 * @title ERC1155 transfer receiver interface
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @notice validate receipt of ERC1155 transfer
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param id token ID received
     * @param value quantity of tokens received
     * @param data data payload
     * @return function's own selector if transfer is accepted
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @notice validate receipt of ERC1155 batch transfer
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param ids token IDs received
     * @param values quantities of tokens received
     * @param data data payload
     * @return function's own selector if transfer is accepted
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title ERC165 interface registration interface
 * @dev see https://eips.ethereum.org/EIPS/eip-165
 */
interface IERC165 {
    /**
     * @notice query whether contract has registered support for given interface
     * @param interfaceId interface id
     * @return bool whether interface is supported
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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

import { IERC20Internal } from './IERC20Internal.sol';

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 is IERC20Internal {
    /**
     * @notice query the total minted token supply
     * @return token supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice query the token balance of given account
     * @param account address to query
     * @return token balance
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice query the allowance granted from given holder to given spender
     * @param holder approver of allowance
     * @param spender recipient of allowance
     * @return token allowance
     */
    function allowance(
        address holder,
        address spender
    ) external view returns (uint256);

    /**
     * @notice grant approval to spender to spend tokens
     * @dev prefer ERC20Extended functions to avoid transaction-ordering vulnerability (see https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729)
     * @param spender recipient of allowance
     * @param amount quantity of tokens approved for spending
     * @return success status (always true; otherwise function should revert)
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @notice transfer tokens to given recipient
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @notice transfer tokens to given recipient on behalf of given holder
     * @param holder holder of tokens prior to transfer
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function transferFrom(
        address holder,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC20 interface needed by internal functions
 */
interface IERC20Internal {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165 } from '../interfaces/IERC165.sol';
import { ERC165Storage } from './ERC165Storage.sol';

/**
 * @title ERC165 implementation
 */
abstract contract ERC165 is IERC165 {
    using ERC165Storage for ERC165Storage.Layout;

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return ERC165Storage.layout().isSupportedInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ERC165Storage {
    error ERC165Storage__InvalidInterfaceId();

    struct Layout {
        mapping(bytes4 => bool) supportedInterfaces;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC165');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function isSupportedInterface(
        Layout storage l,
        bytes4 interfaceId
    ) internal view returns (bool) {
        return l.supportedInterfaces[interfaceId];
    }

    function setSupportedInterface(
        Layout storage l,
        bytes4 interfaceId,
        bool status
    ) internal {
        if (interfaceId == 0xffffffff)
            revert ERC165Storage__InvalidInterfaceId();
        l.supportedInterfaces[interfaceId] = status;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { PausableStorage } from './PausableStorage.sol';

/**
 * @title Internal functions for Pausable security control module.
 */
abstract contract PausableInternal {
    using PausableStorage for PausableStorage.Layout;

    error Pausable__Paused();
    error Pausable__NotPaused();

    event Paused(address account);
    event Unpaused(address account);

    modifier whenNotPaused() {
        if (_paused()) revert Pausable__Paused();
        _;
    }

    modifier whenPaused() {
        if (!_paused()) revert Pausable__NotPaused();
        _;
    }

    /**
     * @notice query the contracts paused state.
     * @return true if paused, false if unpaused.
     */
    function _paused() internal view virtual returns (bool) {
        return PausableStorage.layout().paused;
    }

    /**
     * @notice Triggers paused state, when contract is unpaused.
     */
    function _pause() internal virtual whenNotPaused {
        PausableStorage.layout().paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @notice Triggers unpaused state, when contract is paused.
     */
    function _unpause() internal virtual whenPaused {
        PausableStorage.layout().paused = false;
        emit Unpaused(msg.sender);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library PausableStorage {
    struct Layout {
        bool paused;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.Pausable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155 } from '../../../interfaces/IERC1155.sol';
import { IERC1155Receiver } from '../../../interfaces/IERC1155Receiver.sol';
import { IERC1155Base } from './IERC1155Base.sol';
import { ERC1155BaseInternal, ERC1155BaseStorage } from './ERC1155BaseInternal.sol';

/**
 * @title Base ERC1155 contract
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
abstract contract ERC1155Base is IERC1155Base, ERC1155BaseInternal {
    function balanceOf(
        address account,
        uint256 id
    ) public view virtual returns (uint256) {
        return _balanceOf(account, id);
    }

    /**
     * @inheritdoc IERC1155
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) public view virtual returns (uint256[] memory) {
        if (accounts.length != ids.length)
            revert ERC1155Base__ArrayLengthMismatch();

        mapping(uint256 => mapping(address => uint256))
            storage balances = ERC1155BaseStorage.layout().balances;

        uint256[] memory batchBalances = new uint256[](accounts.length);

        unchecked {
            for (uint256 i; i < accounts.length; i++) {
                if (accounts[i] == address(0))
                    revert ERC1155Base__BalanceQueryZeroAddress();
                batchBalances[i] = balances[ids[i]][accounts[i]];
            }
        }

        return batchBalances;
    }

    /**
     * @inheritdoc IERC1155
     */
    function isApprovedForAll(
        address account,
        address operator
    ) public view virtual returns (bool) {
        return ERC1155BaseStorage.layout().operatorApprovals[account][operator];
    }

    /**
     * @inheritdoc IERC1155
     */
    function setApprovalForAll(address operator, bool status) public virtual {
        if (msg.sender == operator) revert ERC1155Base__SelfApproval();
        ERC1155BaseStorage.layout().operatorApprovals[msg.sender][
            operator
        ] = status;
        emit ApprovalForAll(msg.sender, operator, status);
    }

    /**
     * @inheritdoc IERC1155
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual {
        if (from != msg.sender && !isApprovedForAll(from, msg.sender))
            revert ERC1155Base__NotOwnerOrApproved();
        _safeTransfer(msg.sender, from, to, id, amount, data);
    }

    /**
     * @inheritdoc IERC1155
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        if (from != msg.sender && !isApprovedForAll(from, msg.sender))
            revert ERC1155Base__NotOwnerOrApproved();
        _safeTransferBatch(msg.sender, from, to, ids, amounts, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155Receiver } from '../../../interfaces/IERC1155Receiver.sol';
import { AddressUtils } from '../../../utils/AddressUtils.sol';
import { IERC1155BaseInternal } from './IERC1155BaseInternal.sol';
import { ERC1155BaseStorage } from './ERC1155BaseStorage.sol';

/**
 * @title Base ERC1155 internal functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
abstract contract ERC1155BaseInternal is IERC1155BaseInternal {
    using AddressUtils for address;

    /**
     * @notice query the balance of given token held by given address
     * @param account address to query
     * @param id token to query
     * @return token balance
     */
    function _balanceOf(
        address account,
        uint256 id
    ) internal view virtual returns (uint256) {
        if (account == address(0))
            revert ERC1155Base__BalanceQueryZeroAddress();
        return ERC1155BaseStorage.layout().balances[id][account];
    }

    /**
     * @notice mint given quantity of tokens for given address
     * @dev ERC1155Receiver implementation is not checked
     * @param account beneficiary of minting
     * @param id token ID
     * @param amount quantity of tokens to mint
     * @param data data payload
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        if (account == address(0)) revert ERC1155Base__MintToZeroAddress();

        _beforeTokenTransfer(
            msg.sender,
            address(0),
            account,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        ERC1155BaseStorage.layout().balances[id][account] += amount;

        emit TransferSingle(msg.sender, address(0), account, id, amount);
    }

    /**
     * @notice mint given quantity of tokens for given address
     * @param account beneficiary of minting
     * @param id token ID
     * @param amount quantity of tokens to mint
     * @param data data payload
     */
    function _safeMint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        _mint(account, id, amount, data);

        _doSafeTransferAcceptanceCheck(
            msg.sender,
            address(0),
            account,
            id,
            amount,
            data
        );
    }

    /**
     * @notice mint batch of tokens for given address
     * @dev ERC1155Receiver implementation is not checked
     * @param account beneficiary of minting
     * @param ids list of token IDs
     * @param amounts list of quantities of tokens to mint
     * @param data data payload
     */
    function _mintBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        if (account == address(0)) revert ERC1155Base__MintToZeroAddress();
        if (ids.length != amounts.length)
            revert ERC1155Base__ArrayLengthMismatch();

        _beforeTokenTransfer(
            msg.sender,
            address(0),
            account,
            ids,
            amounts,
            data
        );

        mapping(uint256 => mapping(address => uint256))
            storage balances = ERC1155BaseStorage.layout().balances;

        for (uint256 i; i < ids.length; ) {
            balances[ids[i]][account] += amounts[i];
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, address(0), account, ids, amounts);
    }

    /**
     * @notice mint batch of tokens for given address
     * @param account beneficiary of minting
     * @param ids list of token IDs
     * @param amounts list of quantities of tokens to mint
     * @param data data payload
     */
    function _safeMintBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        _mintBatch(account, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(
            msg.sender,
            address(0),
            account,
            ids,
            amounts,
            data
        );
    }

    /**
     * @notice burn given quantity of tokens held by given address
     * @param account holder of tokens to burn
     * @param id token ID
     * @param amount quantity of tokens to burn
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        if (account == address(0)) revert ERC1155Base__BurnFromZeroAddress();

        _beforeTokenTransfer(
            msg.sender,
            account,
            address(0),
            _asSingletonArray(id),
            _asSingletonArray(amount),
            ''
        );

        mapping(address => uint256) storage balances = ERC1155BaseStorage
            .layout()
            .balances[id];

        unchecked {
            if (amount > balances[account])
                revert ERC1155Base__BurnExceedsBalance();
            balances[account] -= amount;
        }

        emit TransferSingle(msg.sender, account, address(0), id, amount);
    }

    /**
     * @notice burn given batch of tokens held by given address
     * @param account holder of tokens to burn
     * @param ids token IDs
     * @param amounts quantities of tokens to burn
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        if (account == address(0)) revert ERC1155Base__BurnFromZeroAddress();
        if (ids.length != amounts.length)
            revert ERC1155Base__ArrayLengthMismatch();

        _beforeTokenTransfer(msg.sender, account, address(0), ids, amounts, '');

        mapping(uint256 => mapping(address => uint256))
            storage balances = ERC1155BaseStorage.layout().balances;

        unchecked {
            for (uint256 i; i < ids.length; i++) {
                uint256 id = ids[i];
                if (amounts[i] > balances[id][account])
                    revert ERC1155Base__BurnExceedsBalance();
                balances[id][account] -= amounts[i];
            }
        }

        emit TransferBatch(msg.sender, account, address(0), ids, amounts);
    }

    /**
     * @notice transfer tokens between given addresses
     * @dev ERC1155Receiver implementation is not checked
     * @param operator executor of transfer
     * @param sender sender of tokens
     * @param recipient receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     * @param data data payload
     */
    function _transfer(
        address operator,
        address sender,
        address recipient,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        if (recipient == address(0))
            revert ERC1155Base__TransferToZeroAddress();

        _beforeTokenTransfer(
            operator,
            sender,
            recipient,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        mapping(uint256 => mapping(address => uint256))
            storage balances = ERC1155BaseStorage.layout().balances;

        unchecked {
            uint256 senderBalance = balances[id][sender];
            if (amount > senderBalance)
                revert ERC1155Base__TransferExceedsBalance();
            balances[id][sender] = senderBalance - amount;
        }

        balances[id][recipient] += amount;

        emit TransferSingle(operator, sender, recipient, id, amount);
    }

    /**
     * @notice transfer tokens between given addresses
     * @param operator executor of transfer
     * @param sender sender of tokens
     * @param recipient receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     * @param data data payload
     */
    function _safeTransfer(
        address operator,
        address sender,
        address recipient,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        _transfer(operator, sender, recipient, id, amount, data);

        _doSafeTransferAcceptanceCheck(
            operator,
            sender,
            recipient,
            id,
            amount,
            data
        );
    }

    /**
     * @notice transfer batch of tokens between given addresses
     * @dev ERC1155Receiver implementation is not checked
     * @param operator executor of transfer
     * @param sender sender of tokens
     * @param recipient receiver of tokens
     * @param ids token IDs
     * @param amounts quantities of tokens to transfer
     * @param data data payload
     */
    function _transferBatch(
        address operator,
        address sender,
        address recipient,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        if (recipient == address(0))
            revert ERC1155Base__TransferToZeroAddress();
        if (ids.length != amounts.length)
            revert ERC1155Base__ArrayLengthMismatch();

        _beforeTokenTransfer(operator, sender, recipient, ids, amounts, data);

        mapping(uint256 => mapping(address => uint256))
            storage balances = ERC1155BaseStorage.layout().balances;

        for (uint256 i; i < ids.length; ) {
            uint256 token = ids[i];
            uint256 amount = amounts[i];

            unchecked {
                uint256 senderBalance = balances[token][sender];

                if (amount > senderBalance)
                    revert ERC1155Base__TransferExceedsBalance();

                balances[token][sender] = senderBalance - amount;

                i++;
            }

            // balance increase cannot be unchecked because ERC1155Base neither tracks nor validates a totalSupply
            balances[token][recipient] += amount;
        }

        emit TransferBatch(operator, sender, recipient, ids, amounts);
    }

    /**
     * @notice transfer batch of tokens between given addresses
     * @param operator executor of transfer
     * @param sender sender of tokens
     * @param recipient receiver of tokens
     * @param ids token IDs
     * @param amounts quantities of tokens to transfer
     * @param data data payload
     */
    function _safeTransferBatch(
        address operator,
        address sender,
        address recipient,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        _transferBatch(operator, sender, recipient, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            sender,
            recipient,
            ids,
            amounts,
            data
        );
    }

    /**
     * @notice wrap given element in array of length 1
     * @param element element to wrap
     * @return singleton array
     */
    function _asSingletonArray(
        uint256 element
    ) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;
        return array;
    }

    /**
     * @notice revert if applicable transfer recipient is not valid ERC1155Receiver
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     * @param data data payload
     */
    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector)
                    revert ERC1155Base__ERC1155ReceiverRejected();
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert ERC1155Base__ERC1155ReceiverNotImplemented();
            }
        }
    }

    /**
     * @notice revert if applicable transfer recipient is not valid ERC1155Receiver
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param ids token IDs
     * @param amounts quantities of tokens to transfer
     * @param data data payload
     */
    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver.onERC1155BatchReceived.selector
                ) revert ERC1155Base__ERC1155ReceiverRejected();
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert ERC1155Base__ERC1155ReceiverNotImplemented();
            }
        }
    }

    /**
     * @notice ERC1155 hook, called before all transfers including mint and burn
     * @dev function should be overridden and new implementation must call super
     * @dev called for both single and batch transfers
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param ids token IDs
     * @param amounts quantities of tokens to transfer
     * @param data data payload
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ERC1155BaseStorage {
    struct Layout {
        mapping(uint256 => mapping(address => uint256)) balances;
        mapping(address => mapping(address => bool)) operatorApprovals;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC1155Base');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155 } from '../../../interfaces/IERC1155.sol';
import { IERC1155BaseInternal } from './IERC1155BaseInternal.sol';

/**
 * @title ERC1155 base interface
 */
interface IERC1155Base is IERC1155BaseInternal, IERC1155 {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155Internal } from '../../../interfaces/IERC1155Internal.sol';

/**
 * @title ERC1155 base interface
 */
interface IERC1155BaseInternal is IERC1155Internal {
    error ERC1155Base__ArrayLengthMismatch();
    error ERC1155Base__BalanceQueryZeroAddress();
    error ERC1155Base__NotOwnerOrApproved();
    error ERC1155Base__SelfApproval();
    error ERC1155Base__BurnExceedsBalance();
    error ERC1155Base__BurnFromZeroAddress();
    error ERC1155Base__ERC1155ReceiverRejected();
    error ERC1155Base__ERC1155ReceiverNotImplemented();
    error ERC1155Base__MintToZeroAddress();
    error ERC1155Base__TransferExceedsBalance();
    error ERC1155Base__TransferToZeroAddress();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { EnumerableSet } from '../../../data/EnumerableSet.sol';
import { ERC1155BaseInternal } from '../base/ERC1155BaseInternal.sol';
import { IERC1155Enumerable } from './IERC1155Enumerable.sol';
import { ERC1155EnumerableInternal, ERC1155EnumerableStorage } from './ERC1155EnumerableInternal.sol';

/**
 * @title ERC1155 implementation including enumerable and aggregate functions
 */
abstract contract ERC1155Enumerable is
    IERC1155Enumerable,
    ERC1155EnumerableInternal
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    /**
     * @inheritdoc IERC1155Enumerable
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply(id);
    }

    /**
     * @inheritdoc IERC1155Enumerable
     */
    function totalHolders(uint256 id) public view virtual returns (uint256) {
        return _totalHolders(id);
    }

    /**
     * @inheritdoc IERC1155Enumerable
     */
    function accountsByToken(
        uint256 id
    ) public view virtual returns (address[] memory) {
        return _accountsByToken(id);
    }

    /**
     * @inheritdoc IERC1155Enumerable
     */
    function tokensByAccount(
        address account
    ) public view virtual returns (uint256[] memory) {
        return _tokensByAccount(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { EnumerableSet } from '../../../data/EnumerableSet.sol';
import { ERC1155BaseInternal, ERC1155BaseStorage } from '../base/ERC1155BaseInternal.sol';
import { ERC1155EnumerableStorage } from './ERC1155EnumerableStorage.sol';

/**
 * @title ERC1155Enumerable internal functions
 */
abstract contract ERC1155EnumerableInternal is ERC1155BaseInternal {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    /**
     * @notice query total minted supply of given token
     * @param id token id to query
     * @return token supply
     */
    function _totalSupply(uint256 id) internal view virtual returns (uint256) {
        return ERC1155EnumerableStorage.layout().totalSupply[id];
    }

    /**
     * @notice query total number of holders for given token
     * @param id token id to query
     * @return quantity of holders
     */
    function _totalHolders(uint256 id) internal view virtual returns (uint256) {
        return ERC1155EnumerableStorage.layout().accountsByToken[id].length();
    }

    /**
     * @notice query holders of given token
     * @param id token id to query
     * @return list of holder addresses
     */
    function _accountsByToken(
        uint256 id
    ) internal view virtual returns (address[] memory) {
        EnumerableSet.AddressSet storage accounts = ERC1155EnumerableStorage
            .layout()
            .accountsByToken[id];

        address[] memory addresses = new address[](accounts.length());

        unchecked {
            for (uint256 i; i < accounts.length(); i++) {
                addresses[i] = accounts.at(i);
            }
        }

        return addresses;
    }

    /**
     * @notice query tokens held by given address
     * @param account address to query
     * @return list of token ids
     */
    function _tokensByAccount(
        address account
    ) internal view virtual returns (uint256[] memory) {
        EnumerableSet.UintSet storage tokens = ERC1155EnumerableStorage
            .layout()
            .tokensByAccount[account];

        uint256[] memory ids = new uint256[](tokens.length());

        unchecked {
            for (uint256 i; i < tokens.length(); i++) {
                ids[i] = tokens.at(i);
            }
        }

        return ids;
    }

    /**
     * @notice ERC1155 hook: update aggregate values
     * @inheritdoc ERC1155BaseInternal
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from != to) {
            ERC1155EnumerableStorage.Layout storage l = ERC1155EnumerableStorage
                .layout();
            mapping(uint256 => EnumerableSet.AddressSet)
                storage tokenAccounts = l.accountsByToken;
            EnumerableSet.UintSet storage fromTokens = l.tokensByAccount[from];
            EnumerableSet.UintSet storage toTokens = l.tokensByAccount[to];

            for (uint256 i; i < ids.length; ) {
                uint256 amount = amounts[i];

                if (amount > 0) {
                    uint256 id = ids[i];

                    if (from == address(0)) {
                        l.totalSupply[id] += amount;
                    } else if (_balanceOf(from, id) == amount) {
                        tokenAccounts[id].remove(from);
                        fromTokens.remove(id);
                    }

                    if (to == address(0)) {
                        l.totalSupply[id] -= amount;
                    } else if (_balanceOf(to, id) == 0) {
                        tokenAccounts[id].add(to);
                        toTokens.add(id);
                    }
                }

                unchecked {
                    i++;
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { EnumerableSet } from '../../../data/EnumerableSet.sol';

library ERC1155EnumerableStorage {
    struct Layout {
        mapping(uint256 => uint256) totalSupply;
        mapping(uint256 => EnumerableSet.AddressSet) accountsByToken;
        mapping(address => EnumerableSet.UintSet) tokensByAccount;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC1155Enumerable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155BaseInternal } from '../base/IERC1155BaseInternal.sol';

/**
 * @title ERC1155 enumerable and aggregate function interface
 */
interface IERC1155Enumerable is IERC1155BaseInternal {
    /**
     * @notice query total minted supply of given token
     * @param id token id to query
     * @return token supply
     */
    function totalSupply(uint256 id) external view returns (uint256);

    /**
     * @notice query total number of holders for given token
     * @param id token id to query
     * @return quantity of holders
     */
    function totalHolders(uint256 id) external view returns (uint256);

    /**
     * @notice query holders of given token
     * @param id token id to query
     * @return list of holder addresses
     */
    function accountsByToken(
        uint256 id
    ) external view returns (address[] memory);

    /**
     * @notice query tokens held by given address
     * @param account address to query
     * @return list of token ids
     */
    function tokensByAccount(
        address account
    ) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155Base } from './base/IERC1155Base.sol';
import { IERC1155Enumerable } from './enumerable/IERC1155Enumerable.sol';
import { IERC1155Metadata } from './metadata/IERC1155Metadata.sol';

interface ISolidStateERC1155 is
    IERC1155Base,
    IERC1155Enumerable,
    IERC1155Metadata
{}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { UintUtils } from '../../../utils/UintUtils.sol';
import { IERC1155Metadata } from './IERC1155Metadata.sol';
import { ERC1155MetadataInternal } from './ERC1155MetadataInternal.sol';
import { ERC1155MetadataStorage } from './ERC1155MetadataStorage.sol';

/**
 * @title ERC1155 metadata extensions
 */
abstract contract ERC1155Metadata is IERC1155Metadata, ERC1155MetadataInternal {
    using UintUtils for uint256;

    /**
     * @notice inheritdoc IERC1155Metadata
     */
    function uri(uint256 tokenId) public view virtual returns (string memory) {
        ERC1155MetadataStorage.Layout storage l = ERC1155MetadataStorage
            .layout();

        string memory tokenIdURI = l.tokenURIs[tokenId];
        string memory baseURI = l.baseURI;

        if (bytes(baseURI).length == 0) {
            return tokenIdURI;
        } else if (bytes(tokenIdURI).length > 0) {
            return string(abi.encodePacked(baseURI, tokenIdURI));
        } else {
            return string(abi.encodePacked(baseURI, tokenId.toString()));
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155MetadataInternal } from './IERC1155MetadataInternal.sol';
import { ERC1155MetadataStorage } from './ERC1155MetadataStorage.sol';

/**
 * @title ERC1155Metadata internal functions
 */
abstract contract ERC1155MetadataInternal is IERC1155MetadataInternal {
    /**
     * @notice set base metadata URI
     * @dev base URI is a non-standard feature adapted from the ERC721 specification
     * @param baseURI base URI
     */
    function _setBaseURI(string memory baseURI) internal {
        ERC1155MetadataStorage.layout().baseURI = baseURI;
    }

    /**
     * @notice set per-token metadata URI
     * @param tokenId token whose metadata URI to set
     * @param tokenURI per-token URI
     */
    function _setTokenURI(uint256 tokenId, string memory tokenURI) internal {
        ERC1155MetadataStorage.layout().tokenURIs[tokenId] = tokenURI;
        emit URI(tokenURI, tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title ERC1155 metadata extensions
 */
library ERC1155MetadataStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC1155Metadata');

    struct Layout {
        string baseURI;
        mapping(uint256 => string) tokenURIs;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155MetadataInternal } from './IERC1155MetadataInternal.sol';

/**
 * @title ERC1155Metadata interface
 */
interface IERC1155Metadata is IERC1155MetadataInternal {
    /**
     * @notice get generated URI for given token
     * @return token URI
     */
    function uri(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC1155Metadata interface needed by internal functions
 */
interface IERC1155MetadataInternal {
    event URI(string value, uint256 indexed tokenId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { ERC165 } from '../../introspection/ERC165.sol';
import { ERC1155Base, ERC1155BaseInternal } from './base/ERC1155Base.sol';
import { ERC1155Enumerable } from './enumerable/ERC1155Enumerable.sol';
import { ERC1155EnumerableInternal } from './enumerable/ERC1155EnumerableInternal.sol';
import { ERC1155Metadata } from './metadata/ERC1155Metadata.sol';
import { ISolidStateERC1155 } from './ISolidStateERC1155.sol';

/**
 * @title SolidState ERC1155 implementation
 */
abstract contract SolidStateERC1155 is
    ISolidStateERC1155,
    ERC1155Base,
    ERC1155Enumerable,
    ERC1155Metadata,
    ERC165
{
    /**
     * @inheritdoc ERC1155BaseInternal
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        virtual
        override(ERC1155BaseInternal, ERC1155EnumerableInternal)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20 } from '../../../interfaces/IERC20.sol';
import { IERC20BaseInternal } from './IERC20BaseInternal.sol';

/**
 * @title ERC20 base interface
 */
interface IERC20Base is IERC20BaseInternal, IERC20 {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20Internal } from '../../../interfaces/IERC20Internal.sol';

/**
 * @title ERC20 base interface
 */
interface IERC20BaseInternal is IERC20Internal {
    error ERC20Base__ApproveFromZeroAddress();
    error ERC20Base__ApproveToZeroAddress();
    error ERC20Base__BurnExceedsBalance();
    error ERC20Base__BurnFromZeroAddress();
    error ERC20Base__InsufficientAllowance();
    error ERC20Base__MintToZeroAddress();
    error ERC20Base__TransferExceedsBalance();
    error ERC20Base__TransferFromZeroAddress();
    error ERC20Base__TransferToZeroAddress();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20ExtendedInternal } from './IERC20ExtendedInternal.sol';

/**
 * @title ERC20 extended interface
 */
interface IERC20Extended is IERC20ExtendedInternal {
    /**
     * @notice increase spend amount granted to spender
     * @param spender address whose allowance to increase
     * @param amount quantity by which to increase allowance
     * @return success status (always true; otherwise function will revert)
     */
    function increaseAllowance(
        address spender,
        uint256 amount
    ) external returns (bool);

    /**
     * @notice decrease spend amount granted to spender
     * @param spender address whose allowance to decrease
     * @param amount quantity by which to decrease allowance
     * @return success status (always true; otherwise function will revert)
     */
    function decreaseAllowance(
        address spender,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20BaseInternal } from '../base/IERC20BaseInternal.sol';

/**
 * @title ERC20 extended internal interface
 */
interface IERC20ExtendedInternal is IERC20BaseInternal {
    error ERC20Extended__ExcessiveAllowance();
    error ERC20Extended__InsufficientAllowance();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20Base } from './base/IERC20Base.sol';
import { IERC20Extended } from './extended/IERC20Extended.sol';
import { IERC20Metadata } from './metadata/IERC20Metadata.sol';
import { IERC20Permit } from './permit/IERC20Permit.sol';

interface ISolidStateERC20 is
    IERC20Base,
    IERC20Extended,
    IERC20Metadata,
    IERC20Permit
{}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20MetadataInternal } from './IERC20MetadataInternal.sol';

/**
 * @title ERC20 metadata interface
 */
interface IERC20Metadata is IERC20MetadataInternal {
    /**
     * @notice return token name
     * @return token name
     */
    function name() external view returns (string memory);

    /**
     * @notice return token symbol
     * @return token symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @notice return token decimals, generally used only for display purposes
     * @return token decimals
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title ERC20 metadata internal interface
 */
interface IERC20MetadataInternal {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20Metadata } from '../metadata/IERC20Metadata.sol';
import { IERC2612 } from './IERC2612.sol';
import { IERC20PermitInternal } from './IERC20PermitInternal.sol';

// TODO: note that IERC20Metadata is needed for eth-permit library

interface IERC20Permit is IERC20PermitInternal, IERC2612 {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC2612Internal } from './IERC2612Internal.sol';

interface IERC20PermitInternal is IERC2612Internal {
    error ERC20Permit__ExpiredDeadline();
    error ERC20Permit__InvalidSignature();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC2612Internal } from './IERC2612Internal.sol';

/**
 * @title ERC2612 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-2612.
 */
interface IERC2612 is IERC2612Internal {
    /**
     * @notice return the EIP-712 domain separator unique to contract and chain
     * @return domainSeparator domain separator
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32 domainSeparator);

    /**
     * @notice get the current ERC2612 nonce for the given address
     * @return current nonce
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @notice approve spender to transfer tokens held by owner via signature
     * @dev this function may be vulnerable to approval replay attacks
     * @param owner holder of tokens and signer of permit
     * @param spender beneficiary of approval
     * @param amount quantity of tokens to approve
     * @param v secp256k1 'v' value
     * @param r secp256k1 'r' value
     * @param s secp256k1 's' value
     */
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

interface IERC2612Internal {}

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IERC1155Facet} from "../interfaces/IERC1155Facet.sol";
import {ERC1155Storage} from "../utils/ERC1155/ERC1155Storage.sol";
import {ERC1155Lib} from "../libraries/ERC1155Lib.sol";
import {PriceConsumer} from "../../shared/libraries/PriceConsumer.sol";
import {EnumerableSet} from "@solidstate/contracts/data/EnumerableSet.sol";
import {CoinSwapper} from "../../shared/libraries/CoinSwapper.sol";
import {
    PausableInternal
} from "@solidstate/contracts/security/PausableInternal.sol";
import {
    ERC1155BaseStorage
} from "@solidstate/contracts/token/ERC1155/base/ERC1155BaseStorage.sol";
import {
    IERC1155Metadata
} from "@solidstate/contracts/token/ERC1155/metadata/IERC1155Metadata.sol";
import {
    ERC1155MetadataStorage
} from "@solidstate/contracts/token/ERC1155/metadata/ERC1155MetadataStorage.sol";
import {
    ERC1155EnumerableStorage
} from "@solidstate/contracts/token/ERC1155/enumerable/ERC1155EnumerableStorage.sol";
import {
    SolidStateERC1155
} from "@solidstate/contracts/token/ERC1155/SolidStateERC1155.sol";
import {
    ISolidStateERC20
} from "@solidstate/contracts/token/ERC20/ISolidStateERC20.sol";
import {
    AllowListStorage,
    AllowListInternal
} from "../../shared/utils/AllowList/AllowListInternal.sol";
import {IERC1155Facet} from "../interfaces/IERC1155Facet.sol";
import {OwnableStorage} from "@solidstate/contracts/access/ownable/Ownable.sol";

abstract contract ERC1155 is
    SolidStateERC1155,
    IERC1155Facet,
    PausableInternal,
    AllowListInternal
{
    string private constant CONTRACT_VERSION = "0.0.1";

    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using ERC1155Storage for ERC1155Storage.Layout;
    using ERC1155EnumerableStorage for ERC1155EnumerableStorage.Layout;

    enum MintType {
        SINGLE,
        PACK,
        CROSSMINT_USDC_SINGLE,
        CROSSMINT_USDC_PACK
    }

    modifier validTokenID(uint256 _tokenId) {
        if (ERC1155Storage.layout().tokenData[_tokenId].creator == address(0))
            revert InvalidTokenID();

        _;
    }

    modifier validQuantity(uint256 _id, uint256 _amount) {
        uint256 maxSupply = ERC1155Storage.layout().tokenData[_id].maxSupply;

        if (maxSupply > 0)
            if (totalSupply(_id) + _amount > maxSupply)
                revert ExceedsMaxSupply();

        _;
    }

    modifier validTime(uint256 _id, uint256 amount) {
        bool failCheck = true; // If this is false by the end, revert.
        uint256 _startTime = ERC1155Storage.layout().tokenData[_id].startTime;

        if (
            msg.sender == OwnableStorage.layout().owner ||
            _startTime < block.timestamp
        ) {
            // Ignore checks for owner, there is no start time (0 will always be
            // less than block.timestamp), or start time has passed.
            failCheck = false;
            _;
        } else if (AllowListStorage.layout().allowListEnabled[_id]) {
            AllowListStorage.Layout storage als = AllowListStorage.layout();
            // Only happens if the allow list is enabled and the main start time has not passed

            // Check is sender is even in the list
            if (!EnumerableSet.contains(als.allowList[_id], msg.sender)) {
                revert AccountNotAllowListed();
            }

            // Check if allow list start time has passed for this particular account
            if (block.timestamp > als.allowTime[_id][msg.sender])
                revert AllowListMintUnopened();

            // Check if the amount being minted is less than or equal to the amount allowed
            if (amount >= als.minted[_id][msg.sender])
                revert AllowListAmountExceeded();

            // Passed all checks for allow list
            failCheck = false;
            _;
        }

        // Not owner, time hasn't passed (after checking AllowList for it to continue)
        if (failCheck) revert MintNotOpen();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IERC1155Facet} from "../interfaces/IERC1155Facet.sol";
import {ERC1155Storage} from "../utils/ERC1155/ERC1155Storage.sol";
import {ERC1155Lib} from "../libraries/ERC1155Lib.sol";
import {PriceConsumer} from "../../shared/libraries/PriceConsumer.sol";
import {IERC1155} from "@solidstate/contracts/interfaces/IERC1155.sol";
import {EnumerableSet} from "@solidstate/contracts/data/EnumerableSet.sol";
import {CoinSwapper} from "../../shared/libraries/CoinSwapper.sol";
import {
    OwnableInternal
} from "@solidstate/contracts/access/ownable/Ownable.sol";
import {
    PausableInternal
} from "@solidstate/contracts/security/PausableInternal.sol";
import {
    MetadataInternal,
    MetadataStorage
} from "../utils/Metadata/MetadataInternal.sol";
import {
    DefaultOperatorFilterer
} from "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import {
    ERC1155BaseStorage
} from "@solidstate/contracts/token/ERC1155/base/ERC1155BaseStorage.sol";
import {
    IERC1155Metadata
} from "@solidstate/contracts/token/ERC1155/metadata/IERC1155Metadata.sol";
import {
    ERC1155MetadataStorage
} from "@solidstate/contracts/token/ERC1155/metadata/ERC1155MetadataStorage.sol";
import {
    ERC1155EnumerableStorage
} from "@solidstate/contracts/token/ERC1155/enumerable/ERC1155EnumerableStorage.sol";
import {
    SolidStateERC1155,
    ERC1155Base,
    ERC1155Metadata
} from "@solidstate/contracts/token/ERC1155/SolidStateERC1155.sol";
import {
    AllowListStorage,
    AllowListInternal
} from "../../shared/utils/AllowList/AllowListInternal.sol";
import {ERC1155} from "../abstracts/ERC1155.sol";

contract ERC1155Facet is OwnableInternal, DefaultOperatorFilterer, ERC1155 {
    string private constant CONTRACT_VERSION = "0.0.1";

    using EnumerableSet for EnumerableSet.UintSet;
    using ERC1155Storage for ERC1155Storage.Layout;
    using EnumerableSet for EnumerableSet.AddressSet;
    using MetadataStorage for MetadataStorage.Layout;
    using ERC1155MetadataStorage for ERC1155MetadataStorage.Layout;
    using ERC1155EnumerableStorage for ERC1155EnumerableStorage.Layout;

    /// Checks if valid value was sent.
    /// @notice Checks if the amount sent is greater than or equal to the price of the token. If the sender is the owner, it will bypass this check allowing the owner to mint or airdrop for free.
    /// @param _id The token ID
    /// @param _amount The amount of tokens being minted
    modifier validValueSent(uint256 _id, uint256 _amount) {
        uint256 totalPrice = price(_id) * _amount;

        if (msg.sender != _owner())
            if (msg.value < totalPrice) revert InvalidAmount();

        _;
    }

    /// Mint a batch of tokens.
    function packMint(
        address account,
        uint256 packId,
        uint256 amount
    ) public payable {
        ERC1155Storage.Layout storage l = ERC1155Storage.layout();
        ERC1155Storage.PackStructure storage pack = l.packData[packId];

        uint256 batchLength = pack.tokenIds.length;
        uint256[] memory amounts = new uint256[](batchLength);

        uint256 i;
        for (; i < batchLength; ) {
            amounts[i] = amount;
            ++i;
        }

        // Check valid quantity TODO: Move to modifier
        uint256 tokenId;
        uint256 tokensMaxSupply;
        for (i = 0; i < batchLength; ++i) {
            tokenId = pack.tokenIds[i];
            tokensMaxSupply = l.tokenData[tokenId].maxSupply;

            if (tokensMaxSupply > 0)
                if (_totalSupply(tokenId) + amount > tokensMaxSupply)
                    revert ExceedsMaxSupply();
        }

        // Check price TODO: Move to modifier
        uint256 totalPrice = pack.price * amount;
        if (msg.sender != _owner())
            if (msg.value < totalPrice) revert InvalidAmount();

        // Check batch start time TODO: Move to modifier
        if (msg.sender != _owner()) {
            if (pack.startTime > block.timestamp) revert MintNotOpen();
        }

        _mintBatch(account, pack.tokenIds, amounts, "");

        emit PaymentReceived(msg.sender, msg.value);

        if (ERC1155Storage.layout().automaticUSDConversion) {
            CoinSwapper.convertEthToUSDC();
        }
    }

    function packCreate(
        uint256[] calldata _tokenIds,
        uint256 _price,
        uint256 _startTime
    ) external onlyOwner {
        ERC1155Storage.Layout storage l = ERC1155Storage.layout();

        uint256 currentPackId = l.getCurrentPackId();
        l.packData[currentPackId] = ERC1155Storage.PackStructure(
            _price,
            _startTime,
            _tokenIds
        );
        l.incrementPackId();
    }

    /// Get price for a pack
    function packPrice(uint256 _packId) external view returns (uint256) {
        return ERC1155Storage.layout().packData[_packId].price;
    }

    /// Get startTime for a pack
    function packStartTime(uint256 _packId) external view returns (uint256) {
        return ERC1155Storage.layout().packData[_packId].startTime;
    }

    /// Get tokenIds for a pack
    function packTokenIds(
        uint256 _packId
    ) external view returns (uint256[] memory) {
        return ERC1155Storage.layout().packData[_packId].tokenIds;
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount
    )
        external
        payable
        validTime(id, amount)
        validTokenID(id)
        validQuantity(id, amount)
        validValueSent(id, amount)
    {
        _mint(account, id, amount, "");
        emit PaymentReceived(msg.sender, msg.value);

        if (ERC1155Storage.layout().automaticUSDConversion) {
            CoinSwapper.convertEthToUSDC();
        }
    }

    /// Mint function used by owner for airdrops.
    /// @notice Mints to multiple accounts at once, used by owner for airdrops.
    /// @param accounts Array of accounts to send to.
    /// @param id ID of token to airdrop.
    /// @param amount The amount of tokens being minted to each account.
    function mint(
        address[] calldata accounts,
        uint256 id,
        uint256 amount
    ) external validTokenID(id) validQuantity(id, amount) onlyOwner {
        uint256 accountsLength = accounts.length;
        uint256 i;
        address to;
        ERC1155EnumerableStorage.Layout storage l = ERC1155EnumerableStorage
            .layout();
        ERC1155BaseStorage.Layout storage lb = ERC1155BaseStorage.layout();

        for (; i < accountsLength; ) {
            to = accounts[i];
            if (to == address(0)) revert ERC1155Base__MintToZeroAddress();

            if (lb.balances[id][to] == 0) {
                l.accountsByToken[id].add(to);
                l.tokensByAccount[to].add(id);
            }

            unchecked {
                l.totalSupply[id] += amount;
                lb.balances[id][to] += amount;
                ++i;
            }

            emit TransferSingle(msg.sender, address(0), to, id, amount);
        }
    }

    function uri(
        uint256 tokenId
    )
        public
        view
        override(ERC1155Metadata, IERC1155Metadata)
        returns (string memory)
    {
        string memory uniqueTokenURI = ERC1155Storage
            .layout()
            .tokenData[tokenId]
            .tokenUri;

        if (bytes(uniqueTokenURI).length > 0) {
            return uniqueTokenURI;
        }

        return
            string(
                abi.encodePacked(
                    ERC1155MetadataStorage.layout().baseURI,
                    _toString(tokenId)
                )
            );
    }

    function maxSupply(uint256 _id) public view returns (uint256) {
        return ERC1155Storage.layout().tokenData[_id].maxSupply;
    }

    function setMaxSupply(
        uint256 _id,
        uint256 _maxSupply
    ) external validTokenID(_id) onlyOwner {
        if (_maxSupply < totalSupply(_id)) revert InvalidMaxSupply();

        ERC1155Storage.layout().tokenData[_id].maxSupply = _maxSupply;
    }

    /// Creates a new token edition.
    /// @dev remove onlyOwner if you want third parties to create new tokens on your contract (which may change your IDs)
    /// @param _tokenData The token data
    /// @return _id The newly created token ID
    function create(
        ERC1155Storage.TokenStructure memory _tokenData
    ) public onlyOwner returns (uint256 _id) {
        _id = ERC1155Lib.create(_tokenData);
    }

    /// Creates a new token editions in one transaction. All editions will have the same settings.
    /// If you need individual settings (diffrent URIs, prices, etc), use the other batchCreate function.
    /// @dev remove onlyOwner if you want third parties to create new tokens on your contract (which may change your IDs)
    /// @param _amount Amount of new token to create with these settings.
    /// @param _tokenData The token data
    /// @return success Whether or not the batch creation was successful.
    function batchCreate(
        uint256 _amount,
        ERC1155Storage.TokenStructure calldata _tokenData
    ) external onlyOwner returns (bool success) {
        success = ERC1155Lib.batchCreate(_amount, _tokenData);
    }

    /// Creates a set of new editions in one transaction.
    /// Editions are passed as an array so this is useful if they require very different settings.
    /// If they're all similar, using the other batchCreate function might be easier.
    /// @dev remove onlyOwner if you want third parties to create new tokens on your contract (which may change your IDs)
    /// @param _tokenData The token data
    /// @return success Bool of success
    function batchCreate(
        ERC1155Storage.TokenStructure[] calldata _tokenData
    ) external onlyOwner returns (bool success) {
        success = ERC1155Lib.batchCreate(_tokenData);
    }

    /// @dev Returns whether the specified token exists by checking to see if it has a creator
    /// @param _tokenId uint256 ID of the token to query the existence of
    /// @return bool whether the token exists
    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    function _exists(uint256 _id) internal view returns (bool) {
        return ERC1155Storage.layout().tokenData[_id].creator != address(0);
    }

    /// @dev calculates the next token ID based on value of _currentTokenID
    /// @return uint256 for the next token ID
    function _getNextTokenID() private view returns (uint256) {
        unchecked {
            return ERC1155Storage.layout().currentTokenId + 1;
        }
    }

    /// @dev increments the value of _currentTokenID
    function _incrementTokenTypeId() private {
        unchecked {
            ++ERC1155Storage.layout().currentTokenId;
        }
    }

    function burn(
        address account,
        uint256 id,
        uint256 amount
    ) external validTokenID(id) onlyOwner {
        _burn(account, id, amount);
    }

    /// @dev Pause beforeTransfer for security
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /// OpenSea Compliance
    function setApprovalForAll(
        address operator,
        bool status
    )
        public
        override(ERC1155Base, IERC1155)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, status);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id, // tokenId
        uint256 amount,
        bytes memory data
    ) public override(ERC1155Base, IERC1155) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override(ERC1155Base, IERC1155) onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /// @dev Converts a uint256 to its ASCII string decimal representation.
    function _toString(
        uint256 value
    ) internal pure virtual returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 0x80 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 0x20 + 3/// 0x20 = 0x80.
            str := add(mload(0x40), 0x80)
            // Update the free memory pointer to allocate.
            mstore(0x40, str)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }

    /// Get price for certain edition
    function price(
        uint256 _id
    ) public view validTokenID(_id) returns (uint256) {
        ERC1155Storage.Layout storage l = ERC1155Storage.layout();
        uint256 tokenPrice = l.tokenData[_id].price;

        return
            l.isPriceUSD
                ? PriceConsumer.convertUSDtoWei(tokenPrice)
                : tokenPrice;
    }

    /// Set price for certain edition
    function setPrice(
        uint256 _id,
        uint256 _price
    ) external validTokenID(_id) onlyOwner {
        ERC1155Storage.layout().tokenData[_id].price = _price;
    }

    /// @dev Name/symbol needed for certain sites like OpenSea
    function name() public view returns (string memory) {
        return ERC1155Storage.layout().name;
    }

    function symbol() public view returns (string memory) {
        return ERC1155Storage.layout().symbol;
    }

    function setName(string calldata _name) external onlyOwner {
        ERC1155Storage.layout().name = _name;
    }

    function setSymbol(string calldata _symbol) external onlyOwner {
        ERC1155Storage.layout().symbol = _symbol;
    }

    /// Function to get the start time of a specific token
    function startTime(
        uint256 _id
    ) external view validTokenID(_id) returns (uint256) {
        return ERC1155Storage.layout().tokenData[_id].startTime;
    }

    /// Function to change the start time of a specific token
    function setStartTime(
        uint256 _id,
        uint256 _startTime
    ) external validTokenID(_id) onlyOwner {
        ERC1155Storage.layout().tokenData[_id].startTime = _startTime;
    }

    /// Get tokenData
    function tokenData(
        uint256 id
    ) external view returns (ERC1155Storage.TokenStructure memory) {
        return ERC1155Storage.layout().tokenData[id];
    }

    /// Set tokenData
    function setTokenData(
        uint256 _id,
        ERC1155Storage.TokenStructure calldata _tokenData
    ) external validTokenID(_id) onlyOwner {
        ERC1155Storage.layout().tokenData[_id] = _tokenData;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

abstract contract IERC1155Facet {
    string private constant CONTRACT_VERSION = "0.0.1";

    error ExceedsMaxSupply();
    error InvalidTokenID();
    error InvalidAmount();
    error InvalidMaxSupply();
    error ArrayLengthsDiffer();
    error InvalidMintType();

    event PaymentReceived(address from, uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {OwnableStorage} from "@solidstate/contracts/access/ownable/Ownable.sol";
import {ERC1155Storage} from "../utils/ERC1155/ERC1155Storage.sol";
import {
    ERC1155EnumerableStorage
} from "@solidstate/contracts/token/ERC1155/enumerable/ERC1155Enumerable.sol";

library ERC1155Lib {
    string private constant CONTRACT_VERSION = "0.0.1";

    error ArrayLengthsDiffer();
    error NotOwner();

    event URI(string _value, uint256 indexed _id);

    /**
     * @dev Creates a new token type
     * NOTE: remove onlyOwner if you want third parties to create new tokens on your contract (which may change your IDs)
     * @param _tokenData The token data.
     * @return _id The newly created token ID
     */
    function create(
        ERC1155Storage.TokenStructure memory _tokenData
    ) internal returns (uint256 _id) {
        if (msg.sender != OwnableStorage.layout().owner) revert NotOwner();

        ERC1155Storage.Layout storage s = ERC1155Storage.layout();
        _id = s.currentTokenId;

        if (_tokenData.creator == address(0)) _tokenData.creator = msg.sender;

        s.tokenData[_id] = _tokenData;

        _incrementTokenTypeId();

        if (bytes(_tokenData.tokenUri).length > 0)
            emit URI(_tokenData.tokenUri, _id);
    }

    /**
     * @dev Creates a new token types in batch (with different settings)
     * NOTE: remove onlyOwner if you want third parties to create new tokens on your contract (which may change your IDs)
     * @param _amount Amount of new token to create with these settings.
     * @param _tokenData The token data.
     * @return success Bool of success
     */
    function batchCreate(
        uint256 _amount,
        ERC1155Storage.TokenStructure memory _tokenData
    ) internal returns (bool success) {
        if (msg.sender != OwnableStorage.layout().owner) revert NotOwner();

        ERC1155Storage.Layout storage s = ERC1155Storage.layout();

        if (_tokenData.creator == address(0)) _tokenData.creator = msg.sender;

        uint256 i;
        uint256 _id;
        for (; i < _amount; ) {
            _id = s.currentTokenId;

            s.tokenData[_id] = _tokenData;

            if (bytes(_tokenData.tokenUri).length > 0)
                emit URI(_tokenData.tokenUri, _id);

            _incrementTokenTypeId();
            ++i;
        }

        success = true;
    }

    /**
     * @dev Creates a new token types in batch
     * NOTE: remove onlyOwner if you want third parties to create new tokens on your contract (which may change your IDs)
     * @param _tokenData The token data.
     * @return success True if the batch creation was successful.
     */
    function batchCreate(
        ERC1155Storage.TokenStructure[] calldata _tokenData
    ) internal returns (bool success) {
        if (msg.sender != OwnableStorage.layout().owner) revert NotOwner();

        ERC1155Storage.Layout storage s = ERC1155Storage.layout();

        uint256 i;
        uint256 _id;
        uint256 amount = _tokenData.length;
        for (; i < amount; ) {
            _id = s.currentTokenId;

            s.tokenData[_id] = _tokenData[i];

            if (_tokenData[i].creator == address(0))
                s.tokenData[_id].creator = msg.sender;

            if (bytes(_tokenData[i].tokenUri).length > 0)
                emit URI(_tokenData[i].tokenUri, _id);

            _incrementTokenTypeId();

            ++i;
        }

        success = true;
    }

    function _incrementTokenTypeId() internal {
        unchecked {
            ++ERC1155Storage.layout().currentTokenId;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";

library TokenMetadata {
    string private constant CONTRACT_VERSION = "0.0.1";

    using StringsUpgradeable for uint256;
    using StringsUpgradeable for address;
    using Base64Upgradeable for bytes;
    using TokenMetadata for TokenType;
    using TokenMetadata for Attribute[];

    enum TokenType {
        ERC20,
        ERC1155,
        ERC721
    }

    struct Attribute {
        string name;
        string displayType;
        string value;
        bool isNumber;
    }

    function toBase64(
        string memory json
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    bytes(json).encode()
                )
            );
    }

    function makeMetadataJSON(
        uint256 tokenId,
        address owner,
        string memory name,
        string memory imageURI,
        string memory description,
        Attribute[] memory // attributes
    ) internal pure returns (string memory) {
        string memory metadataJSON = makeMetadataString(
            tokenId,
            owner,
            name,
            imageURI,
            description
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64Upgradeable.encode(
                        abi.encodePacked(
                            "{",
                            metadataJSON,
                            // attributes.toJSONString(),
                            "}"
                        )
                    )
                )
            );
    }

    function makeMetadataString(
        uint256, // tokenId
        address, // owner
        string memory name,
        string memory imageURI,
        string memory description
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '"name":"',
                    name,
                    '",',
                    // '"tokenId":"',
                    // tokenId.toString(),
                    // '",',
                    '"image":"',
                    imageURI,
                    '",',
                    '"description":"',
                    description //,
                    // '",',
                    // '"owner":"',
                    // owner.toHexString() //,
                    // '",'
                )
            );
    }

    function toJSONString(
        Attribute[] memory attributes
    ) internal pure returns (string memory) {
        string memory attributeString = "";
        for (uint256 i = 0; i < attributes.length; i++) {
            string memory comma = i == (attributes.length - 1) ? "" : ",";
            string memory quote = attributes[i].isNumber ? "" : '"';
            string memory value = string(
                abi.encodePacked(quote, attributes[i].value, quote)
            );
            string memory displayType = bytes(attributes[i].displayType)
                .length == 0
                ? ""
                : string(
                    abi.encodePacked(
                        '"display_type":"',
                        attributes[i].displayType,
                        '",'
                    )
                );
            string memory newAttributeString = string(
                abi.encodePacked(
                    attributeString,
                    '{"trait_type":"',
                    attributes[i].name,
                    '",',
                    displayType,
                    '"value":',
                    value,
                    "}",
                    comma
                )
            );
            attributeString = newAttributeString;
        }
        return string(abi.encodePacked('"attributes":[', attributeString, "]"));
    }

    function toString(
        TokenType tokenType
    ) internal pure returns (string memory) {
        return
            tokenType == TokenType.ERC721
                ? "ERC721"
                : tokenType == TokenType.ERC1155
                ? "ERC1155"
                : "ERC20";
    }

    function makeContractURI(
        string memory name,
        string memory description,
        string memory imageURL,
        string memory externalLinkURL,
        uint256 sellerFeeBasisPoints,
        address feeRecipient
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '{"name":"',
                    name,
                    '",',
                    '"description":"',
                    description,
                    '",',
                    '"image":"',
                    imageURL,
                    '",',
                    '"external_link":"',
                    externalLinkURL,
                    '",',
                    '"seller_fee_basis_points":',
                    sellerFeeBasisPoints.toString(),
                    ",",
                    '"fee_recipient":"',
                    feeRecipient.toHexString(),
                    '"}'
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library ERC1155Storage {
    string private constant CONTRACT_VERSION = "0.0.1";

    struct TokenStructure {
        uint256 maxSupply;
        uint256 price;
        address creator;
        string tokenUri; // Optional, baseUri is set in ERC1155MetadataStorage (https://sample.com/{id}.json) would be valid)
        bool allowListEnabled;
        uint256 startTime;
        bool isCrossmintUSDC;
    }

    struct PackStructure {
        uint256 price;
        uint256 startTime;
        uint256[] tokenIds;
    }

    struct Layout {
        uint256 currentTokenId;
        bool airdrop;
        string name;
        string symbol;
        string contractURI;
        mapping(uint256 => uint256) maxSupply;
        mapping(uint256 => uint256) price;
        mapping(uint256 => address) creator;
        mapping(uint256 => string) tokenUri;
        mapping(uint256 => bool) allowListEnabled;
        mapping(uint256 => TokenStructure) tokenData;
        bool isPriceUSD;
        bool automaticUSDConversion;
        uint256 currentPackId;
        mapping(uint256 => PackStructure) packData;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("lively.contracts.storage.ERC1155");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function tokenData(
        uint256 _tokenId
    ) internal view returns (TokenStructure storage) {
        return layout().tokenData[_tokenId];
    }

    function packData(
        uint256 _packId
    ) internal view returns (PackStructure storage) {
        return layout().packData[_packId];
    }

    function incrementPackId(Layout storage l) internal {
        l.currentPackId++;
    }

    function getCurrentPackId(
        Layout storage l
    ) internal view returns (uint256) {
        return l.currentPackId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {MetadataStorage} from "./MetadataStorage.sol";
import {TokenMetadata} from "../../libraries/TokenMetadata.sol";
import {
    OwnableInternal
} from "@solidstate/contracts/access/ownable/OwnableInternal.sol";

contract MetadataInternal is OwnableInternal {
    string private constant CONTRACT_VERSION = "0.0.1";

    using MetadataStorage for MetadataStorage.Layout;

    function _setMetadata(
        uint256 _tokenId,
        MetadataStorage.Metadata calldata _metadata
    ) internal onlyOwner {
        MetadataStorage.Layout storage metadataStore = MetadataStorage.layout();

        metadataStore.metadata[_tokenId].description = _metadata.description;
        metadataStore.metadata[_tokenId].external_url = _metadata.external_url;
        metadataStore.metadata[_tokenId].image = _metadata.image;
        metadataStore.metadata[_tokenId].name = _metadata.name;
        metadataStore.metadata[_tokenId].animation_url = _metadata
            .animation_url;
        // metadata.attributes = _metadata.attributes;

        uint256 attributesLength = _metadata.attributes.length;
        uint256 i = 0;
        while (i < attributesLength) {
            metadataStore.metadata[_tokenId].attributes.push(
                _metadata.attributes[i]
            );
            i++;
        }
    }

    function _getMetadata(
        uint256 _tokenId
    ) internal view returns (string memory) {
        return
            TokenMetadata.makeMetadataJSON(
                _tokenId,
                msg.sender,
                MetadataStorage.layout().metadata[_tokenId].name,
                MetadataStorage.layout().metadata[_tokenId].image,
                MetadataStorage.layout().metadata[_tokenId].description,
                MetadataStorage.layout().metadata[_tokenId].attributes
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {TokenMetadata} from "../../libraries/TokenMetadata.sol";

library MetadataStorage {
    string private constant CONTRACT_VERSION = "0.0.1";

    // struct Attribute {
    //     string trait_type;
    //     string value;
    // }
    struct Metadata {
        string description; // "Umphrey's McGee Nashville, TN 12/15/2020. Collection of all songs in the Lively NFT player and the ability to mint out all the songs into individual NFTs."
        string external_url; // https://golive.ly
        string image; // https://golive.ly/metadata/1155/images/{id}.png
        string name; // UM Tour Dec 15th, 22 - Nashville
        string animation_url; // https://golive.ly/metadata/1155/animations/{id}.mp4
        TokenMetadata.Attribute[] attributes; // [{ "trait_type": "Artist", "value": "Umphrey's McGee"}]
    }

    struct Layout {
        mapping(uint256 => Metadata) metadata;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("lively.contracts.storage.MetadataStorage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.18;

import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";

interface IWETH9 is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {LibDiamond} from "./LibDiamond.sol";
import {IWETH9} from "../interfaces/IWETH9.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

library CoinSwapper {
    string private constant CONTRACT_VERSION = "0.0.1";

    uint256 constant localId = 31337;
    uint256 constant ethereumId = 1;
    uint256 constant goerliId = 5;
    uint256 constant polygonId = 137;
    uint256 constant mumbaiId = 80001;

    ISwapRouter public constant swapRouter =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564); // Same on all Nets SwapRouter address

    // Returns the appropriate WETH9 token address for the given network id.
    function getWETH9Address()
        internal
        view
        returns (address priceFeedAddress)
    {
        if (block.chainid == ethereumId || block.chainid == localId) {
            return 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        } else if (block.chainid == polygonId) {
            return 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
        } else if (block.chainid == goerliId) {
            return 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
        } else if (block.chainid == mumbaiId) {
            return 0xA6FA4fB5f76172d178d61B04b0ecd319C5d1C0aa;
        }
    }

    // Returns the appropriate USDC token address for the given network id.
    function getUSDCAddress() internal view returns (address priceFeedAddress) {
        if (block.chainid == ethereumId || block.chainid == localId) {
            return 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        } else if (block.chainid == polygonId) {
            return 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
        } else if (block.chainid == goerliId) {
            return 0x98339D8C260052B7ad81c28c16C0b98420f2B46a;
        } else if (block.chainid == mumbaiId) {
            return 0xFEca406dA9727A25E71e732F9961F680059eF1F9;
        }
    }

    /** @dev Shortcut function to swap ETH for USDC */
    function convertEthToUSDC() internal {
        wrapMsgEth();
        convertWETHtoUSDC();
    }

    /** @dev Wraps the entire balance of the contract in WETH9 */
    function wrapEth() internal {
        address WETH9 = getWETH9Address();
        IWETH9(WETH9).deposit{value: address(this).balance}();
    }

    /** @dev Wraps the entire balance of the contract in WETH9 */
    function wrapMsgEth() internal {
        address WETH9 = getWETH9Address();
        IWETH9(WETH9).deposit{value: msg.value}();
    }

    /** @dev Converts all WETH owned by contract to USDC */
    function convertWETHtoUSDC() internal {
        address USDC = getUSDCAddress();
        address WETH9 = getWETH9Address();
        uint256 currentBlance = IWETH9(WETH9).balanceOf(address(this));

        // For this example, we will set the pool fee to 0.3%.
        uint24 poolFee = 3000;

        TransferHelper.safeTransferFrom(
            WETH9,
            address(this),
            address(this),
            currentBlance
        );

        TransferHelper.safeApprove(WETH9, address(swapRouter), currentBlance);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: WETH9,
                tokenOut: USDC,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: currentBlance,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        swapRouter.exactInputSingle(params);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

error InitializationFunctionReverted(
    address _initializationContractAddress,
    bytes _calldata
);

library LibDiamond {
    string private constant CONTRACT_VERSION = "0.0.1";

    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    struct DiamondStorage {
        // maps function selectors to the facets that execute the functions.
        // and maps the selectors to their position in the selectorSlots array.
        // func selector => address facet, selector position
        mapping(bytes4 => bytes32) facets;
        // array of slots of function selectors.
        // each slot holds 8 function selectors.
        mapping(uint256 => bytes32) selectorSlots;
        // The number of function selectors in selectorSlots
        uint16 selectorCount;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    bytes32 constant CLEAR_ADDRESS_MASK =
        bytes32(uint256(0xffffffffffffffffffffffff));
    bytes32 constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));

    // Internal function version of diamondCut
    // This code is almost the same as the external diamondCut,
    // except it is using 'Facet[] memory _diamondCut' instead of
    // 'Facet[] calldata _diamondCut'.
    // The code is duplicated to prevent copying calldata to memory which
    // causes an error for a two dimensional array.
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        DiamondStorage storage ds = diamondStorage();
        uint256 originalSelectorCount = ds.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;
        // Check if last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8"
        if (selectorCount & 7 > 0) {
            // get last selectorSlot
            // "selectorSlot >> 3" is a gas efficient division by 8 "selectorSlot / 8"
            selectorSlot = ds.selectorSlots[selectorCount >> 3];
        }
        // loop through diamond cut
        for (
            uint256 facetIndex;
            facetIndex < _diamondCut.length;
            facetIndex++
        ) {
            (selectorCount, selectorSlot) = addReplaceRemoveFacetSelectors(
                selectorCount,
                selectorSlot,
                _diamondCut[facetIndex].facetAddress,
                _diamondCut[facetIndex].action,
                _diamondCut[facetIndex].functionSelectors
            );
        }
        if (selectorCount != originalSelectorCount) {
            ds.selectorCount = uint16(selectorCount);
        }
        // If last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8"
        if (selectorCount & 7 > 0) {
            // "selectorSlot >> 3" is a gas efficient division by 8 "selectorSlot / 8"
            ds.selectorSlots[selectorCount >> 3] = selectorSlot;
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addReplaceRemoveFacetSelectors(
        uint256 _selectorCount,
        bytes32 _selectorSlot,
        address _newFacetAddress,
        IDiamondCut.FacetCutAction _action,
        bytes4[] memory _selectors
    ) internal returns (uint256, bytes32) {
        DiamondStorage storage ds = diamondStorage();
        require(
            _selectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        if (_action == IDiamondCut.FacetCutAction.Add) {
            enforceHasContractCode(
                _newFacetAddress,
                "LibDiamondCut: Add facet has no code"
            );
            for (
                uint256 selectorIndex;
                selectorIndex < _selectors.length;
                selectorIndex++
            ) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                require(
                    address(bytes20(oldFacet)) == address(0),
                    "LibDiamondCut: Can't add function that already exists"
                );
                // add facet for selector
                ds.facets[selector] =
                    bytes20(_newFacetAddress) |
                    bytes32(_selectorCount);
                // "_selectorCount & 7" is a gas efficient modulo by eight "_selectorCount % 8"
                // " << 5 is the same as multiplying by 32 ( * 32)
                uint256 selectorInSlotPosition = (_selectorCount & 7) << 5;
                // clear selector position in slot and add selector
                _selectorSlot =
                    (_selectorSlot &
                        ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) |
                    (bytes32(selector) >> selectorInSlotPosition);
                // if slot is full then write it to storage
                if (selectorInSlotPosition == 224) {
                    // "_selectorSlot >> 3" is a gas efficient division by 8 "_selectorSlot / 8"
                    ds.selectorSlots[_selectorCount >> 3] = _selectorSlot;
                    _selectorSlot = 0;
                }
                _selectorCount++;
            }
        } else if (_action == IDiamondCut.FacetCutAction.Replace) {
            enforceHasContractCode(
                _newFacetAddress,
                "LibDiamondCut: Replace facet has no code"
            );
            for (
                uint256 selectorIndex;
                selectorIndex < _selectors.length;
                selectorIndex++
            ) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                address oldFacetAddress = address(bytes20(oldFacet));
                // only useful if immutable functions exist
                require(
                    oldFacetAddress != address(this),
                    "LibDiamondCut: Can't replace immutable function"
                );
                require(
                    oldFacetAddress != _newFacetAddress,
                    "LibDiamondCut: Can't replace function with same function"
                );
                require(
                    oldFacetAddress != address(0),
                    "LibDiamondCut: Can't replace function that doesn't exist"
                );
                // replace old facet address
                ds.facets[selector] =
                    (oldFacet & CLEAR_ADDRESS_MASK) |
                    bytes20(_newFacetAddress);
            }
        } else if (_action == IDiamondCut.FacetCutAction.Remove) {
            require(
                _newFacetAddress == address(0),
                "LibDiamondCut: Remove facet address must be address(0)"
            );
            // "_selectorCount >> 3" is a gas efficient division by 8 "_selectorCount / 8"
            uint256 selectorSlotCount = _selectorCount >> 3;
            // "_selectorCount & 7" is a gas efficient modulo by eight "_selectorCount % 8"
            uint256 selectorInSlotIndex = _selectorCount & 7;
            for (
                uint256 selectorIndex;
                selectorIndex < _selectors.length;
                selectorIndex++
            ) {
                if (_selectorSlot == 0) {
                    // get last selectorSlot
                    selectorSlotCount--;
                    _selectorSlot = ds.selectorSlots[selectorSlotCount];
                    selectorInSlotIndex = 7;
                } else {
                    selectorInSlotIndex--;
                }
                bytes4 lastSelector;
                uint256 oldSelectorsSlotCount;
                uint256 oldSelectorInSlotPosition;
                // adding a block here prevents stack too deep error
                {
                    bytes4 selector = _selectors[selectorIndex];
                    bytes32 oldFacet = ds.facets[selector];
                    require(
                        address(bytes20(oldFacet)) != address(0),
                        "LibDiamondCut: Can't remove function that doesn't exist"
                    );
                    // only useful if immutable functions exist
                    require(
                        address(bytes20(oldFacet)) != address(this),
                        "LibDiamondCut: Can't remove immutable function"
                    );
                    // replace selector with last selector in ds.facets
                    // gets the last selector
                    // " << 5 is the same as multiplying by 32 ( * 32)
                    lastSelector = bytes4(
                        _selectorSlot << (selectorInSlotIndex << 5)
                    );
                    if (lastSelector != selector) {
                        // update last selector slot position info
                        ds.facets[lastSelector] =
                            (oldFacet & CLEAR_ADDRESS_MASK) |
                            bytes20(ds.facets[lastSelector]);
                    }
                    delete ds.facets[selector];
                    uint256 oldSelectorCount = uint16(uint256(oldFacet));
                    // "oldSelectorCount >> 3" is a gas efficient division by 8 "oldSelectorCount / 8"
                    oldSelectorsSlotCount = oldSelectorCount >> 3;
                    // "oldSelectorCount & 7" is a gas efficient modulo by eight "oldSelectorCount % 8"
                    // " << 5 is the same as multiplying by 32 ( * 32)
                    oldSelectorInSlotPosition = (oldSelectorCount & 7) << 5;
                }
                if (oldSelectorsSlotCount != selectorSlotCount) {
                    bytes32 oldSelectorSlot = ds.selectorSlots[
                        oldSelectorsSlotCount
                    ];
                    // clears the selector we are deleting and puts the last selector in its place.
                    oldSelectorSlot =
                        (oldSelectorSlot &
                            ~(CLEAR_SELECTOR_MASK >>
                                oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                    // update storage with the modified slot
                    ds.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
                } else {
                    // clears the selector we are deleting and puts the last selector in its place.
                    _selectorSlot =
                        (_selectorSlot &
                            ~(CLEAR_SELECTOR_MASK >>
                                oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                }
                if (selectorInSlotIndex == 0) {
                    delete ds.selectorSlots[selectorSlotCount];
                    _selectorSlot = 0;
                }
            }
            _selectorCount = selectorSlotCount * 8 + selectorInSlotIndex;
        } else {
            revert("LibDiamondCut: Incorrect FacetCutAction");
        }
        return (_selectorCount, _selectorSlot);
    }

    function initializeDiamondCut(
        address _init,
        bytes memory _calldata
    ) internal {
        if (_init == address(0)) {
            return;
        }
        enforceHasContractCode(
            _init,
            "LibDiamondCut: _init address has no code"
        );
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up error
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(_init, _calldata);
            }
        }
    }

    function enforceHasContractCode(
        address _contract,
        string memory _errorMessage
    ) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConsumer {
    string private constant CONTRACT_VERSION = "0.0.1";

    uint256 constant localId = 31337;
    uint256 constant ethereumId = 1;
    uint256 constant rinkebyId = 4;
    uint256 constant goerliId = 5;
    uint256 constant polygonId = 137;
    uint256 constant mumbaiId = 80001;

    // Returns the appropriate oracle address for the given network id.
    function getPriceFeedAddress()
        internal
        view
        returns (address priceFeedAddress)
    {
        uint256 chainId = block.chainid;

        if (chainId == ethereumId || chainId == localId) {
            return 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
        } else if (chainId == rinkebyId) {
            return 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;
        } else if (chainId == goerliId) {
            return 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e;
        } else if (chainId == polygonId) {
            return 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0;
        } else if (chainId == mumbaiId) {
            return 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada;
        }
    }

    /**
     * @notice Returns the latest price
     *
     * @return latest price
     */
    function getLatestPrice() internal view returns (uint256) {
        AggregatorV3Interface priceFeed = getPriceFeed();
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 newPrice = uint256(price);

        return newPrice;
    }

    /**
     * @notice Returns the Price Feed address
     *
     * @return Price Feed address
     */
    function getPriceFeed() internal view returns (AggregatorV3Interface) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            getPriceFeedAddress()
        );

        return priceFeed;
    }

    function convertUSDtoWei(uint256 _price) internal view returns (uint256) {
        return (1e18 / (getLatestPrice() / 1e6)) * _price;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AllowListStorage} from "./AllowListStorage.sol";
import {IAllowListInternal} from "./IAllowListInternal.sol";
import {EnumerableSet} from "@solidstate/contracts/data/EnumerableSet.sol";

contract AllowListInternal is IAllowListInternal {
    string private constant CONTRACT_VERSION = "0.0.1";

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
    string private constant CONTRACT_VERSION = "0.0.1";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OperatorFilterer} from "./OperatorFilterer.sol";

/**
 * @title  DefaultOperatorFilterer
 * @notice Inherits from OperatorFilterer and automatically subscribes to the default OpenSea subscription.
 */
abstract contract DefaultOperatorFilterer is OperatorFilterer {
    address constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    constructor() OperatorFilterer(DEFAULT_SUBSCRIPTION, true) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);
    function register(address registrant) external;
    function registerAndSubscribe(address registrant, address subscription) external;
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;
    function unregister(address addr) external;
    function updateOperator(address registrant, address operator, bool filtered) external;
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;
    function subscribe(address registrant, address registrantToSubscribe) external;
    function unsubscribe(address registrant, bool copyExistingEntries) external;
    function subscriptionOf(address addr) external returns (address registrant);
    function subscribers(address registrant) external returns (address[] memory);
    function subscriberAt(address registrant, uint256 index) external returns (address);
    function copyEntriesOf(address registrant, address registrantToCopy) external;
    function isOperatorFiltered(address registrant, address operator) external returns (bool);
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);
    function filteredOperators(address addr) external returns (address[] memory);
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);
    function isRegistered(address addr) external returns (bool);
    function codeHashOf(address addr) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "./IOperatorFilterRegistry.sol";

/**
 * @title  OperatorFilterer
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 */
abstract contract OperatorFilterer {
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry public constant OPERATOR_FILTER_REGISTRY =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    constructor(address subscriptionOrRegistrantToCopy, bool subscribe) {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (subscribe) {
                OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    OPERATOR_FILTER_REGISTRY.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    OPERATOR_FILTER_REGISTRY.register(address(this));
                }
            }
        }
    }

    modifier onlyAllowedOperator(address from) virtual {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    function _checkFilterOperator(address operator) internal view virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}