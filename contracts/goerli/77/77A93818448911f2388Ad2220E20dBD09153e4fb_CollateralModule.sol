//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library AccessError {
    error Unauthorized(address addr);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library AddressError {
    error ZeroAddress();
    error NotAContract(address contr);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library InitError {
    error AlreadyInitialized();
    error NotInitialized();
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ParameterError {
    /**
     * @notice Thrown when an invalid parameter is used in a function.
     */
    error InvalidParameter(string parameter, string reason);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    error InsufficientAllowance(uint required, uint existing);
    error InsufficientBalance(uint required, uint existing);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function transfer(address to, uint amount) external returns (bool);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";

interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../errors/AccessError.sol";

library OwnableStorage {
    struct Data {
        bool initialized;
        address owner;
        address nominatedOwner;
    }

    function load() internal pure returns (Data storage store) {
        bytes32 s = keccak256(abi.encode("Ownable"));
        assembly {
            store.slot := s
        }
    }

    function onlyOwner() internal view {
        if (msg.sender != getOwner()) {
            revert AccessError.Unauthorized(msg.sender);
        }
    }

    function getOwner() internal view returns (address) {
        return OwnableStorage.load().owner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";

library ERC20Helper {
    error FailedTransfer(address from, address to, uint value);

    function safeTransfer(
        address token,
        address to,
        uint value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
            revert FailedTransfer(address(this), to, value);
        }
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value)
        );
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
            revert FailedTransfer(from, to, value);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Utility library used to represent "decimals" (fixed point numbers) with integers, with two different levels of precision.
 *
 * They are represented by N * UNIT, where UNIT is the number of decimals of precision in the representation.
 *
 * Examples:
 * 1) Given UNIT = 100
 * then if A = 50, A represents the decimal 0.50
 * 2) Given UNIT = 1000000000000000000
 * then if A = 500000000000000000, A represents the decimal 0.500000000000000000
 *
 * Note: An accompanying naming convention of the postfix "D<Precision>" is helpful with this utility. I.e. if a variable "myValue" represents a low resolution decimal, it should be named "myValueD18", and if it was a high resolution decimal "myValueD27". While scaling, intermediate precision decimals like "myValue45" could arise. Non-decimals should have no postfix, i.e. just "myValue".
 *
 * Important: Multiplication and division operations are currently not supported for high precision decimals. Using these operations on them will yield incorrect results and fail silently.
 */
library DecimalMath {
    // Numbers representing 1.0 (low precision).
    uint256 public constant UNIT = 1e18;
    int256 public constant UNIT_INT = int256(UNIT);
    uint128 public constant UNIT_UINT128 = uint128(UNIT);
    int128 public constant UNIT_INT128 = int128(UNIT_INT);

    // Numbers representing 1.0 (high precision).
    uint256 public constant UNIT_PRECISE = 1e27;
    int256 public constant UNIT_PRECISE_INT = int256(UNIT_PRECISE);
    int128 public constant UNIT_PRECISE_INT128 = int128(UNIT_PRECISE_INT);

    // Precision scaling, (used to scale down/up from one precision to the other).
    uint256 public constant PRECISION_FACTOR = 9; // 27 - 18 = 9 :)

    // -----------------
    // uint256
    // -----------------

    /**
     * @dev Multiplies two low precision decimals.
     *
     * Since the two numbers are assumed to be fixed point numbers,
     * (x * UNIT) * (y * UNIT) = x * y * UNIT ^ 2,
     * the result is divided by UNIT to remove double scaling.
     */
    function mulDecimal(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return (x * y) / UNIT;
    }

    /**
     * @dev Divides two low precision decimals.
     *
     * Since the two numbers are assumed to be fixed point numbers,
     * (x * UNIT) / (y * UNIT) = x / y (Decimal representation is lost),
     * x is first scaled up to end up with a decimal representation.
     */
    function divDecimal(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return (x * UNIT) / y;
    }

    /**
     * @dev Scales up a value.
     *
     * E.g. if value is not a decimal, a scale up by 18 makes it a low precision decimal.
     * If value is a low precision decimal, a scale up by 9 makes it a high precision decimal.
     */
    function upscale(uint x, uint factor) internal pure returns (uint) {
        return x * 10**factor;
    }

    /**
     * @dev Scales down a value.
     *
     * E.g. if value is a high precision decimal, a scale down by 9 makes it a low precision decimal.
     * If value is a low precision decimal, a scale down by 9 makes it a regular integer.
     *
     * Scaling down a regular integer would not make sense.
     */
    function downscale(uint x, uint factor) internal pure returns (uint) {
        return x / 10**factor;
    }

    // -----------------
    // uint128
    // -----------------

    // Note: Overloading doesn't seem to work for similar types, i.e. int256 and int128, uint256 and uint128, etc, so explicitly naming the functions differently here.

    /**
     * @dev See mulDecimal for uint256.
     */
    function mulDecimalUint128(uint128 x, uint128 y) internal pure returns (uint128) {
        return (x * y) / UNIT_UINT128;
    }

    /**
     * @dev See divDecimal for uint256.
     */
    function divDecimalUint128(uint128 x, uint128 y) internal pure returns (uint128) {
        return (x * UNIT_UINT128) / y;
    }

    /**
     * @dev See upscale for uint256.
     */
    function upscaleUint128(uint128 x, uint factor) internal pure returns (uint128) {
        return x * uint128(10**factor);
    }

    /**
     * @dev See downscale for uint256.
     */
    function downscaleUint128(uint128 x, uint factor) internal pure returns (uint128) {
        return x / uint128(10**factor);
    }

    // -----------------
    // int256
    // -----------------

    /**
     * @dev See mulDecimal for uint256.
     */
    function mulDecimal(int256 x, int256 y) internal pure returns (int256) {
        return (x * y) / UNIT_INT;
    }

    /**
     * @dev See divDecimal for uint256.
     */
    function divDecimal(int256 x, int256 y) internal pure returns (int256) {
        return (x * UNIT_INT) / y;
    }

    /**
     * @dev See upscale for uint256.
     */
    function upscale(int x, uint factor) internal pure returns (int) {
        return x * int(10**factor);
    }

    /**
     * @dev See downscale for uint256.
     */
    function downscale(int x, uint factor) internal pure returns (int) {
        return x / int(10**factor);
    }

    // -----------------
    // int128
    // -----------------

    /**
     * @dev See mulDecimal for uint256.
     */
    function mulDecimalInt128(int128 x, int128 y) internal pure returns (int128) {
        return (x * y) / UNIT_INT128;
    }

    /**
     * @dev See divDecimal for uint256.
     */
    function divDecimalInt128(int128 x, int128 y) internal pure returns (int128) {
        return (x * UNIT_INT128) / y;
    }

    /**
     * @dev See upscale for uint256.
     */
    function upscaleInt128(int128 x, uint factor) internal pure returns (int128) {
        return x * int128(int(10**factor));
    }

    /**
     * @dev See downscale for uint256.
     */
    function downscaleInt128(int128 x, uint factor) internal pure returns (int128) {
        return x / int128(int(10**factor));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Eth Heap
// Author: Zac Mitton
// License: MIT

library HeapUtil {
    // default max-heap

    uint private constant _ROOT_INDEX = 1;

    struct Data {
        uint128 idCount;
        Node[] nodes; // root is index 1; index 0 not used
        mapping(uint128 => uint) indices; // unique id => node index
    }
    struct Node {
        uint128 id; //use with another mapping to store arbitrary object types
        int128 priority;
    }

    //call init before anything else
    function init(Data storage self) internal {
        if (self.nodes.length == 0) self.nodes.push(Node(0, 0));
    }

    function insert(
        Data storage self,
        uint128 id,
        int128 priority
    ) internal returns (Node memory) {
        //√
        if (self.nodes.length == 0) {
            init(self);
        } // test on-the-fly-init

        Node memory n;

        // MODIFIED: support updates
        extractById(self, id);

        self.idCount++;
        self.nodes.push();
        n = Node(id, priority);
        _bubbleUp(self, n, self.nodes.length - 1);

        return n;
    }

    function extractMax(Data storage self) internal returns (Node memory) {
        //√
        return _extract(self, _ROOT_INDEX);
    }

    function extractById(Data storage self, uint128 id) internal returns (Node memory) {
        //√
        return _extract(self, self.indices[id]);
    }

    //view
    function dump(Data storage self) internal view returns (Node[] memory) {
        //note: Empty set will return `[Node(0,0)]`. uninitialized will return `[]`.
        return self.nodes;
    }

    function getById(Data storage self, uint128 id) internal view returns (Node memory) {
        return getByIndex(self, self.indices[id]); //test that all these return the emptyNode
    }

    function getByIndex(Data storage self, uint i) internal view returns (Node memory) {
        return self.nodes.length > i ? self.nodes[i] : Node(0, 0);
    }

    function getMax(Data storage self) internal view returns (Node memory) {
        return getByIndex(self, _ROOT_INDEX);
    }

    function size(Data storage self) internal view returns (uint) {
        return self.nodes.length > 0 ? self.nodes.length - 1 : 0;
    }

    function isNode(Node memory n) internal pure returns (bool) {
        return n.id > 0;
    }

    //private
    function _extract(Data storage self, uint i) private returns (Node memory) {
        //√
        if (self.nodes.length <= i || i <= 0) {
            return Node(0, 0);
        }

        Node memory extractedNode = self.nodes[i];
        delete self.indices[extractedNode.id];

        Node memory tailNode = self.nodes[self.nodes.length - 1];
        self.nodes.pop();

        if (i < self.nodes.length) {
            // if extracted node was not tail
            _bubbleUp(self, tailNode, i);
            _bubbleDown(self, self.nodes[i], i); // then try bubbling down
        }
        return extractedNode;
    }

    function _bubbleUp(
        Data storage self,
        Node memory n,
        uint i
    ) private {
        //√
        if (i == _ROOT_INDEX || n.priority <= self.nodes[i / 2].priority) {
            _insert(self, n, i);
        } else {
            _insert(self, self.nodes[i / 2], i);
            _bubbleUp(self, n, i / 2);
        }
    }

    function _bubbleDown(
        Data storage self,
        Node memory n,
        uint i
    ) private {
        //
        uint length = self.nodes.length;
        uint cIndex = i * 2; // left child index

        if (length <= cIndex) {
            _insert(self, n, i);
        } else {
            Node memory largestChild = self.nodes[cIndex];

            if (length > cIndex + 1 && self.nodes[cIndex + 1].priority > largestChild.priority) {
                largestChild = self.nodes[++cIndex]; // TEST ++ gets executed first here
            }

            if (largestChild.priority <= n.priority) {
                //TEST: priority 0 is valid! negative ints work
                _insert(self, n, i);
            } else {
                _insert(self, largestChild, i);
                _bubbleDown(self, n, cIndex);
            }
        }
    }

    function _insert(
        Data storage self,
        Node memory n,
        uint i
    ) private {
        //√
        self.nodes[i] = n;
        self.indices[n.id] = i;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeCast/SafeCastI128.sol";
import "./SafeCast/SafeCastI256.sol";
import "./SafeCast/SafeCastU128.sol";
import "./SafeCast/SafeCastU256.sol";

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Utility that avoids silent overflow errors.
 *
 */
library SafeCastI128 {
    error OverflowInt128ToUint128();

    function toUint(int128 x) internal pure returns (uint128) {
        // ----------------<==============o==============>-----------------
        // ----------------xxxxxxxxxxxxxxxo===============>----------------
        if (x < 0) {
            revert OverflowInt128ToUint128();
        }

        return uint128(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Utility that avoids silent overflow errors.
 *
 */
library SafeCastI256 {
    error OverflowInt256ToUint256();
    error OverflowInt256ToInt128();

    function to128(int256 x) internal pure returns (int128) {
        // ----<==========================o===========================>----
        // ----xxxxxxxxxxxx<==============o==============>xxxxxxxxxxxxx----
        if (x < int256(type(int128).min) || x > int256(type(int128).max)) {
            revert OverflowInt256ToInt128();
        }

        return int128(x);
    }

    function toUint(int256 x) internal pure returns (uint256) {
        // ----<==========================o===========================>----
        // ----xxxxxxxxxxxxxxxxxxxxxxxxxxxo===============================>
        if (x < 0) {
            revert OverflowInt256ToUint256();
        }

        return uint256(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Utility that avoids silent overflow errors.
 *
 */
library SafeCastU128 {
    error OverflowUint128ToInt128();

    function toInt(uint128 x) internal pure returns (int128) {
        // -------------------------------o===============>----------------
        // ----------------<==============o==============>x----------------
        if (x > uint128(type(int128).max)) {
            revert OverflowUint128ToInt128();
        }

        return int128(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Utility that avoids silent overflow errors.
 *
 */
library SafeCastU256 {
    error OverflowUint256ToUint128();
    error OverflowUint256ToInt256();

    // Note: Overloading doesn't seem to work for similar types, i.e. int256 and int128, uint256 and uint128, etc, so explicitly naming the functions differently here.

    function to128(uint256 x) internal pure returns (uint128) {
        // -------------------------------o===============================>
        // -------------------------------o===============>xxxxxxxxxxxxxxxx
        if (x > type(uint128).max) {
            revert OverflowUint256ToUint128();
        }

        return uint128(x);
    }

    function toInt(uint256 x) internal pure returns (int256) {
        // -------------------------------o===============================>
        // ----<==========================o===========================>xxxx
        if (x > uint256(type(int256).max)) {
            revert OverflowUint256ToInt256();
        }

        return int256(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SetUtil {
    // ----------------------------------------
    // Uint support
    // ----------------------------------------

    struct UintSet {
        Bytes32Set raw;
    }

    function add(UintSet storage set, uint value) internal {
        add(set.raw, bytes32(value));
    }

    function remove(UintSet storage set, uint value) internal {
        remove(set.raw, bytes32(value));
    }

    function replace(
        UintSet storage set,
        uint value,
        uint newValue
    ) internal {
        replace(set.raw, bytes32(value), bytes32(newValue));
    }

    function contains(UintSet storage set, uint value) internal view returns (bool) {
        return contains(set.raw, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint) {
        return length(set.raw);
    }

    function valueAt(UintSet storage set, uint position) internal view returns (uint) {
        return uint(valueAt(set.raw, position));
    }

    function positionOf(UintSet storage set, uint value) internal view returns (uint) {
        return positionOf(set.raw, bytes32(value));
    }

    function values(UintSet storage set) internal view returns (uint[] memory) {
        bytes32[] memory store = values(set.raw);
        uint[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // ----------------------------------------
    // Address support
    // ----------------------------------------

    struct AddressSet {
        Bytes32Set raw;
    }

    function add(AddressSet storage set, address value) internal {
        add(set.raw, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value) internal {
        remove(set.raw, bytes32(uint256(uint160(value))));
    }

    function replace(
        AddressSet storage set,
        address value,
        address newValue
    ) internal {
        replace(set.raw, bytes32(uint256(uint160(value))), bytes32(uint256(uint160(newValue))));
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return contains(set.raw, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) internal view returns (uint) {
        return length(set.raw);
    }

    function valueAt(AddressSet storage set, uint position) internal view returns (address) {
        return address(uint160(uint256(valueAt(set.raw, position))));
    }

    function positionOf(AddressSet storage set, address value) internal view returns (uint) {
        return positionOf(set.raw, bytes32(uint256(uint160(value))));
    }

    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = values(set.raw);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // ----------------------------------------
    // Core bytes32 support
    // ----------------------------------------

    error PositionOutOfBounds();
    error ValueNotInSet();
    error ValueAlreadyInSet();

    struct Bytes32Set {
        bytes32[] _values;
        mapping(bytes32 => uint) _positions; // Position zero is never used.
    }

    function add(Bytes32Set storage set, bytes32 value) internal {
        if (contains(set, value)) {
            revert ValueAlreadyInSet();
        }

        set._values.push(value);
        set._positions[value] = set._values.length;
    }

    function remove(Bytes32Set storage set, bytes32 value) internal {
        uint position = set._positions[value];
        if (position == 0) {
            revert ValueNotInSet();
        }

        uint index = position - 1;
        uint lastIndex = set._values.length - 1;

        // If the element being deleted is not the last in the values,
        // move the last element to its position.
        if (index != lastIndex) {
            bytes32 lastValue = set._values[lastIndex];

            set._values[index] = lastValue;
            set._positions[lastValue] = position;
        }

        // Remove the last element in the values.
        set._values.pop();
        delete set._positions[value];
    }

    function replace(
        Bytes32Set storage set,
        bytes32 value,
        bytes32 newValue
    ) internal {
        if (!contains(set, value)) {
            revert ValueNotInSet();
        }

        if (contains(set, newValue)) {
            revert ValueAlreadyInSet();
        }

        uint position = set._positions[value];
        uint index = position - 1;

        set._values[index] = newValue;
        set._positions[newValue] = position;
    }

    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return set._positions[value] != 0;
    }

    function length(Bytes32Set storage set) internal view returns (uint) {
        return set._values.length;
    }

    function valueAt(Bytes32Set storage set, uint position) internal view returns (bytes32) {
        if (position == 0 || position > set._values.length) {
            revert PositionOutOfBounds();
        }

        uint index = position - 1;

        return set._values[index];
    }

    function positionOf(Bytes32Set storage set, bytes32 value) internal view returns (uint) {
        if (!contains(set, value)) {
            revert ValueNotInSet();
        }

        return set._positions[value];
    }

    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return set._values;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@synthetixio/core-contracts/contracts/interfaces/IERC721Enumerable.sol";

/// @title NFT token identifying an Account
interface INftModule is IERC721Enumerable {
    /// @notice Returns if `initialize` has been called by the owner
    function isInitialized() external returns (bool);

    /// @notice Allows owner to initialize the token after attaching a proxy
    function initialize(
        string memory tokenName,
        string memory tokenSymbol,
        string memory uri
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@synthetixio/core-contracts/contracts/interfaces/IERC20.sol";

/// @title ERC20 token for snxUSD
interface ITokenModule is IERC20 {
    /// @notice returns if `initialize` has been called by the owner
    function isInitialized() external returns (bool);

    /// @notice allows owner to initialize the token after attaching a proxy
    function initialize(
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals
    ) external;

    /// @notice mints token amount to "to" address
    function mint(address to, uint amount) external;

    /// @notice burns token amount from "to" address
    function burn(address to, uint amount) external;

    /// @notice sets token amount allowance to spender by "from" address
    function setAllowance(
        address from,
        address spender,
        uint amount
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ITokenModule.sol";
import "../interfaces/INftModule.sol";
import "@synthetixio/core-contracts/contracts/errors/InitError.sol";

library AssociatedSystem {
    struct Data {
        address proxy;
        address impl;
        bytes32 kind;
    }

    error MismatchAssociatedSystemKind(bytes32 expected, bytes32 actual);

    function load(bytes32 id) internal pure returns (Data storage store) {
        bytes32 s = keccak256(abi.encode("AssociatedSystem", id));
        assembly {
            store.slot := s
        }
    }

    bytes32 public constant KIND_ERC20 = "erc20";
    bytes32 public constant KIND_ERC721 = "erc721";
    bytes32 public constant KIND_UNMANAGED = "unmanaged";

    function getAddress(Data storage self) internal view returns (address) {
        return self.proxy;
    }

    function asToken(Data storage self) internal view returns (ITokenModule) {
        expectKind(self, KIND_ERC20);
        return ITokenModule(self.proxy);
    }

    function asNft(Data storage self) internal view returns (INftModule) {
        expectKind(self, KIND_ERC721);
        return INftModule(self.proxy);
    }

    function set(
        Data storage self,
        address proxy,
        address impl,
        bytes32 kind
    ) internal {
        self.proxy = proxy;
        self.impl = impl;
        self.kind = kind;
    }

    function expectKind(Data storage self, bytes32 kind) internal view {
        bytes32 actualKind = self.kind;

        if (actualKind != kind && actualKind != KIND_UNMANAGED) {
            revert MismatchAssociatedSystemKind(kind, actualKind);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../storage/Node.sol";
import "../storage/NodeDefinition.sol";

/// @title Module for managing nodes
interface IOracleManagerModule {
    function registerNode(
        bytes32[] memory parents,
        NodeDefinition.NodeType nodeType,
        bytes memory parameters
    ) external returns (bytes32);

    function getNodeId(
        bytes32[] memory parents,
        NodeDefinition.NodeType nodeType,
        bytes memory parameters
    ) external returns (bytes32);

    function getNode(bytes32 nodeId) external view returns (NodeDefinition.Data memory);

    function process(bytes32 nodeId) external view returns (Node.Data memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Node {
    struct Data {
        int256 price;
        uint timestamp;
        uint volatilityScore;
        uint liquidityScore;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library NodeDefinition {
    enum NodeType {
        NONE,
        REDUCER,
        EXTERNAL,
        CHAINLINK,
        PYTH
    }

    struct Data {
        bytes32[] parents;
        NodeType nodeType;
        bytes parameters;
    }

    function load(bytes32 id) internal pure returns (Data storage data) {
        bytes32 s = keccak256(abi.encode("Node", id));
        assembly {
            data.slot := s
        }
    }

    function create(Data memory nodeDefinition) internal returns (NodeDefinition.Data storage self, bytes32 id) {
        id = getId(nodeDefinition);

        self = load(id);

        self.parents = nodeDefinition.parents;
        self.nodeType = nodeDefinition.nodeType;
        self.parameters = nodeDefinition.parameters;
    }

    function getId(Data memory nodeDefinition) internal pure returns (bytes32) {
        return keccak256(abi.encode(nodeDefinition.parents, nodeDefinition.nodeType, nodeDefinition.parameters));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Interface an aggregator needs to adhere.
interface IAggregatorV3Interface {
    /// @notice decimals used by the aggregator
    function decimals() external view returns (uint8);

    /// @notice aggregator's description
    function description() external view returns (string memory);

    /// @notice aggregator's version
    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    /// @notice get's round data for requested id
    function getRoundData(uint80 id)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    /// @notice get's latest round data
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@synthetixio/core-contracts/contracts/interfaces/IERC165.sol";

/// @title Interface a Market needs to adhere.
interface IMarket is IERC165 {
    /// @notice returns a human-readable name for a given market
    function name(uint128 marketId) external view returns (string memory);

    /// @notice returns amount of USD that the market would try to mint if everything was withdrawn
    function reportedDebt(uint128 marketId) external view returns (uint);

    /// @notice returns the amount of collateral which should (in addition to `reportedDebt`) be prevented from withdrawing from this market
    /// if your market does not require locking, set this to `0`
    function locked(uint128 marketId) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Interface a reward distributor.
interface IRewardDistributor {
    /// @notice Returns a human-readable name for the reward distributor
    function name() external returns (string memory);

    /// @notice This function should revert if msg.sender is not the Synthetix CoreProxy address.
    function payout(
        uint128 accountId,
        uint128 poolId,
        address collateralType,
        address sender,
        uint256 amount
    ) external returns (bool);

    /// @notice Address to ERC-20 token distributed by this distributor, for display purposes only
    /// @dev Return address(0) if providing non ERC-20 rewards
    function token() external returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../storage/CollateralConfiguration.sol";

/**
 * @title Module for managing user collateral.
 * @notice Allows users to deposit and withdraw collateral from the system.
 */
interface ICollateralModule {
    /**
     * @notice Emitted when `amount` of collateral of type `collateralType` is deposited to account `accountId` by `sender`.
     */
    event Deposited(uint128 indexed accountId, address indexed collateralType, uint tokenAmount, address indexed sender);

    /**
     * @notice Emitted when `amount` of collateral of type `collateralType` is withdrawn from account `accountId` by `sender`.
     */
    event Withdrawn(uint128 indexed accountId, address indexed collateralType, uint tokenAmount, address indexed sender);

    /**
     * @notice Deposits `amount` of collateral of type `collateralType` into account `accountId`.
     * @dev Anyone can deposit into anyone's active account without restriction.
     *
     * Emits a {CollateralDeposited} event.
     */
    function deposit(
        uint128 accountId,
        address collateralType,
        uint tokenAmount
    ) external;

    /**
     * @notice Withdraws `amount` of collateral of type `collateralType` from account `accountId`.
     *
     * Requirements:
     *
     * - `msg.sender` must be the owner of the account, have the `ADMIN` permission, or have the `WITHDRAW` permission.
     *
     * Emits a {CollateralWithdrawn} event.
     *
     */
    function withdraw(
        uint128 accountId,
        address collateralType,
        uint tokenAmount
    ) external;

    /**
     * @notice Returns the total values pertaining to account `accountId` for `collateralType`.
     */
    function getAccountCollateral(uint128 accountId, address collateralType)
        external
        view
        returns (
            uint totalDeposited,
            uint totalAssigned,
            uint totalLocked
            //uint totalEscrowed
        );

    /**
     * @notice Returns the amount of collateral of type `collateralType` deposited with account `accountId` that can be withdrawn or delegated to pools.
     */
    function getAccountAvailableCollateral(uint128 accountId, address collateralType) external view returns (uint);

    /**
     * @notice Clean expired locks from locked collateral arrays for an account/collateral type. It includes offset and items to prevent gas exhaustion. If both, offset and items, are 0 it will traverse the whole array (unlimited).
     */
    function cleanExpiredLocks(
        uint128 accountId,
        address collateralType,
        uint offset,
        uint items
    ) external;

    /**
     * @notice Create a new lock on the given account. you must have `admin` permission on the specified account to create a lock.
     * @dev A collateral lock does not affect withdrawals, but instead affects collateral delegation.
     * @dev There is currently no benefit to calling this function. it is simply for allowing pre-created accounts to have locks on them if your protocol requires it.
     */
    function createLock(
        uint128 accountId,
        address collateralType,
        uint amount,
        uint64 expireTimestamp
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@synthetixio/core-contracts/contracts/ownership/OwnableStorage.sol";
import "@synthetixio/core-contracts/contracts/token/ERC20Helper.sol";

import "../../interfaces/ICollateralModule.sol";

import "../../storage/Account.sol";
import "../../storage/CollateralConfiguration.sol";
import "../../storage/CollateralLock.sol";

import "@synthetixio/core-modules/contracts/storage/AssociatedSystem.sol";

/**
 * @title Module for managing user collateral.
 * @dev See ICollateralModule.
 */
contract CollateralModule is ICollateralModule {
    using SetUtil for SetUtil.AddressSet;
    using ERC20Helper for address;
    using CollateralConfiguration for CollateralConfiguration.Data;
    using Account for Account.Data;
    using AccountRBAC for AccountRBAC.Data;
    using Collateral for Collateral.Data;

    error OutOfBounds();
    error InsufficientAccountCollateral(uint amount);

    /**
     * @inheritdoc ICollateralModule
     */
    function deposit(
        uint128 accountId,
        address collateralType,
        uint tokenAmount
    ) public override {
        CollateralConfiguration.collateralEnabled(collateralType);

        Account.Data storage account = Account.load(accountId);

        address depositFrom = msg.sender;

        address self = address(this);

        uint allowance = IERC20(collateralType).allowance(depositFrom, self);
        if (allowance < tokenAmount) {
            revert IERC20.InsufficientAllowance(tokenAmount, allowance);
        }

        collateralType.safeTransferFrom(depositFrom, self, tokenAmount);

        account.collaterals[collateralType].deposit(
            CollateralConfiguration.load(collateralType).convertTokenToSystemAmount(tokenAmount)
        );

        emit Deposited(accountId, collateralType, tokenAmount, msg.sender);
    }

    /**
     * @inheritdoc ICollateralModule
     */
    function withdraw(
        uint128 accountId,
        address collateralType,
        uint tokenAmount
    ) public override {
        Account.onlyWithPermission(accountId, AccountRBAC._WITHDRAW_PERMISSION);

        Account.Data storage account = Account.load(accountId);

        uint systemAmount = CollateralConfiguration.load(collateralType).convertTokenToSystemAmount(tokenAmount);

        if (account.collaterals[collateralType].availableAmountD18 < systemAmount) {
            revert InsufficientAccountCollateral(systemAmount);
        }

        account.collaterals[collateralType].deductCollateral(systemAmount);

        collateralType.safeTransfer(msg.sender, tokenAmount);

        emit Withdrawn(accountId, collateralType, tokenAmount, msg.sender);
    }

    /**
     * @inheritdoc ICollateralModule
     */
    function getAccountCollateral(uint128 accountId, address collateralType)
        external
        view
        override
        returns (
            uint256 totalDeposited,
            uint256 totalAssigned,
            uint256 totalLocked
        )
    {
        return Account.load(accountId).getCollateralTotals(collateralType);
    }

    /**
     * @inheritdoc ICollateralModule
     */
    function getAccountAvailableCollateral(uint128 accountId, address collateralType) public view override returns (uint) {
        return Account.load(accountId).collaterals[collateralType].availableAmountD18;
    }

    /**
     * @inheritdoc ICollateralModule
     */
    function cleanExpiredLocks(
        uint128 accountId,
        address collateralType,
        uint offset,
        uint items
    ) external override {
        CollateralLock.Data[] storage locks = Account.load(accountId).collaterals[collateralType].locks;

        if (offset > locks.length || items > locks.length) {
            revert OutOfBounds();
        }

        uint64 currentTime = uint64(block.timestamp);

        if (offset == 0 && items == 0) {
            items = locks.length;
        }

        uint index = offset;
        while (index < locks.length) {
            if (locks[index].lockExpirationTime <= currentTime) {
                locks[index] = locks[locks.length - 1];
                locks.pop();
            } else {
                index++;
            }
        }
    }

    /**
     * @inheritdoc ICollateralModule
     */
    function createLock(
        uint128 accountId,
        address collateralType,
        uint amount,
        uint64 expireTimestamp
    ) external override {
        Account.onlyWithPermission(accountId, AccountRBAC._ADMIN_PERMISSION);

        Account.Data storage account = Account.load(accountId);

        (uint totalStaked, , uint totalLocked) = account.getCollateralTotals(collateralType);

        if (totalStaked - totalLocked < amount) {
            revert InsufficientAccountCollateral(amount);
        }

        account.collaterals[collateralType].locks.push(CollateralLock.Data(amount, expireTimestamp));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccountRBAC.sol";
import "./Collateral.sol";

import "./Pool.sol";

import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

library Account {
    using AccountRBAC for AccountRBAC.Data;
    using Pool for Pool.Data;
    using Collateral for Collateral.Data;
    using SetUtil for SetUtil.UintSet;

    using SafeCastU128 for uint128;
    using SafeCastU256 for uint256;
    using SafeCastI128 for int128;
    using SafeCastI256 for int256;

    error PermissionDenied(uint128 accountId, bytes32 permission, address target);
    error AccountNotFound(uint128 accountId);
    error InsufficientAccountCollateral(uint requestedAmount);

    struct Data {
        /**
         * @dev Numeric identifier for the account. Must be unique.
         * @dev There cannot be an account with id zero (See ERC721._mint()).
         */
        uint128 id;
        AccountRBAC.Data rbac;
        SetUtil.AddressSet activeCollaterals;
        mapping(address => Collateral.Data) collaterals;
    }

    function load(uint128 id) internal pure returns (Data storage data) {
        bytes32 s = keccak256(abi.encode("Account", id));
        assembly {
            data.slot := s
        }
    }

    function create(uint128 id, address owner) internal returns (Data storage self) {
        self = load(id);

        self.id = id;
        self.rbac.owner = owner;
    }

    function exists(uint128 id) internal view {
        if (load(id).rbac.owner == address(0)) {
            revert AccountNotFound(id);
        }
    }

    function getCollateralTotals(Data storage self, address collateralType)
        internal
        view
        returns (
            uint256 totalDepositedD18,
            uint256 totalAssignedD18,
            uint256 totalLockedD18
        )
    {
        totalAssignedD18 = getAssignedCollateral(self, collateralType);
        totalDepositedD18 = totalAssignedD18 + self.collaterals[collateralType].availableAmountD18;
        totalLockedD18 = self.collaterals[collateralType].getTotalLocked();
        //totalEscrowed = _getLockedEscrow(stakedCollateral.escrow);

        return (totalDepositedD18, totalAssignedD18, totalLockedD18); //, totalEscrowed);
    }

    function getAssignedCollateral(Data storage self, address collateralType) internal view returns (uint) {
        uint totalAssignedD18 = 0;

        SetUtil.UintSet storage pools = self.collaterals[collateralType].pools;

        for (uint i = 1; i <= pools.length(); i++) {
            uint128 poolIdx = pools.valueAt(i).to128();

            Pool.Data storage pool = Pool.load(poolIdx);

            (uint collateralAmountD18, ) = pool.currentAccountCollateral(collateralType, self.id);
            totalAssignedD18 += collateralAmountD18;
        }

        return totalAssignedD18;
    }

    /**
     * @dev Requires that the given account has the specified permission.
     */
    function onlyWithPermission(uint128 accountId, bytes32 permission) internal view {
        if (!Account.load(accountId).rbac.authorized(permission, msg.sender)) {
            revert PermissionDenied(accountId, permission, msg.sender);
        }
    }

    /**
     * Ensure that the account has the required amount of collateral funds remaining
     */
    function requireSufficientCollateral(
        uint128 accountId,
        address collateralType,
        uint amountD18
    ) internal view {
        if (Account.load(accountId).collaterals[collateralType].availableAmountD18 < amountD18) {
            revert InsufficientAccountCollateral(amountD18);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@synthetixio/core-contracts/contracts/utils/SetUtil.sol";
import "@synthetixio/core-contracts/contracts/errors/AddressError.sol";

library AccountRBAC {
    using SetUtil for SetUtil.Bytes32Set;
    using SetUtil for SetUtil.AddressSet;

    bytes32 internal constant _ADMIN_PERMISSION = "ADMIN";
    bytes32 internal constant _WITHDRAW_PERMISSION = "WITHDRAW";
    bytes32 internal constant _DELEGATE_PERMISSION = "DELEGATE";
    bytes32 internal constant _MINT_PERMISSION = "MINT";
    bytes32 internal constant _REWARDS_PERMISSION = "REWARDS";

    error InvalidPermission();

    struct Data {
        address owner;
        mapping(address => SetUtil.Bytes32Set) permissions;
        SetUtil.AddressSet permissionAddresses;
    }

    function setOwner(Data storage self, address owner) internal {
        self.owner = owner;
    }

    function grantPermission(
        Data storage self,
        bytes32 permission,
        address target
    ) internal {
        if (target == address(0)) {
            revert AddressError.ZeroAddress();
        }

        if (permission == "") {
            revert InvalidPermission();
        }

        if (!self.permissionAddresses.contains(target)) {
            self.permissionAddresses.add(target);
        }

        self.permissions[target].add(permission);
    }

    function revokePermission(
        Data storage self,
        bytes32 permission,
        address target
    ) internal {
        self.permissions[target].remove(permission);

        if (self.permissions[target].length() == 0) {
            self.permissionAddresses.remove(target);
        }
    }

    function revokeAllPermissions(Data storage self, address user) internal {
        bytes32[] memory permissions = self.permissions[user].values();

        for (uint i = 1; i <= permissions.length; i++) {
            revokePermission(self, permissions[i - 1], user);
        }
    }

    function hasPermission(
        Data storage self,
        bytes32 permission,
        address target
    ) internal view returns (bool) {
        return target != address(0) && self.permissions[target].contains(permission);
    }

    function authorized(
        Data storage self,
        bytes32 permission,
        address target
    ) internal view returns (bool) {
        return ((target == self.owner) ||
            hasPermission(self, _ADMIN_PERMISSION, target) ||
            hasPermission(self, permission, target));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@synthetixio/core-contracts/contracts/utils/SetUtil.sol";

import "./CollateralLock.sol";
import "./Pool.sol";

/**
 * @title Stores information about a deposited asset for a given account.
 *
 * Each account will have one of these objects for each type of collateral it deposited in the system.
 */
library Collateral {
    struct Data {
        /**
         * @dev Indicates if the collateral is set, i.e. not empty.
         */
        bool isSet;
        /**
         * @dev The amount that can be withdrawn or delegated in this collateral.
         */
        uint256 availableAmountD18;
        /**
         * @dev The pools to which this collateral delegates to.
         */
        SetUtil.UintSet pools;
        /**
         * @dev Marks portions of the collateral as locked,
         * until a given unlock date.
         *
         * Note: Locks apply to collateral delegation (see VaultModule), and not to withdrawing collateral.
         */
        CollateralLock.Data[] locks;
    }

    /**
     * @dev Increments the entry's availableCollateral.
     */
    function deposit(Data storage self, uint amountD18) internal {
        if (!self.isSet) {
            self.isSet = true;
            self.availableAmountD18 = amountD18;
        } else {
            self.availableAmountD18 += amountD18;
        }
    }

    /**
     * @dev Decrements the entry's availableCollateral.
     */
    function deductCollateral(Data storage self, uint amountD18) internal {
        self.availableAmountD18 -= amountD18;
    }

    /**
     * @dev Returns the total amount in this collateral entry that is locked.
     *
     * Sweeps through all existing locks and accumulates their amount,
     * if their unlock date is in the future.
     */
    function getTotalLocked(Data storage self) internal view returns (uint) {
        uint64 currentTime = uint64(block.timestamp);

        uint256 lockedD18;
        for (uint i = 0; i < self.locks.length; i++) {
            CollateralLock.Data storage lock = self.locks[i];

            if (lock.lockExpirationTime > currentTime) {
                lockedD18 += lock.amountD18;
            }
        }

        return lockedD18;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@synthetixio/core-contracts/contracts/utils/SetUtil.sol";
import "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";
import "@synthetixio/core-contracts/contracts/errors/ParameterError.sol";
import "@synthetixio/oracle-manager/contracts/interfaces/IOracleManagerModule.sol";
import "@synthetixio/oracle-manager/contracts/storage/Node.sol";
import "@synthetixio/core-contracts/contracts/interfaces/IERC20.sol";

import "./OracleManager.sol";

import "../interfaces/external/IAggregatorV3Interface.sol";

library CollateralConfiguration {
    using SetUtil for SetUtil.AddressSet;
    using DecimalMath for uint256;

    error CollateralNotFound();
    error CollateralDepositDisabled(address collateralType);
    error InsufficientCollateralRatio(uint collateralValue, uint debt, uint ratio, uint minRatio);
    error InsufficientDelegation(uint minDelegation);

    struct Data {
        /// must be true for staking or collateral delegation
        bool depositingEnabled;
        /// accounts cannot mint sUSD if their debt brings their cratio below this value
        uint issuanceRatioD18;
        /// accounts below the ratio specified here are immediately liquidated
        uint liquidationRatioD18;
        /// amount of token to award when an account is liquidated with this collateral type
        uint liquidationRewardD18;
        /// address which reports the current price of the collateral
        bytes32 oracleNodeId;
        /// address which should be used for transferring this collateral
        address tokenAddress;
        /// minimum delegation amount (other than 0), to prevent sybil/attacks on the system due to new entries.
        uint minDelegationD18;
    }

    function load(address token) internal pure returns (Data storage data) {
        bytes32 s = keccak256(abi.encode("CollateralConfiguration", token));
        assembly {
            data.slot := s
        }
    }

    function loadAvailableCollaterals() internal pure returns (SetUtil.AddressSet storage data) {
        bytes32 s = keccak256(abi.encode("CollateralConfiguration_availableCollaterals"));
        assembly {
            data.slot := s
        }
    }

    function set(Data memory config) internal {
        SetUtil.AddressSet storage collateralTypes = loadAvailableCollaterals();

        if (!collateralTypes.contains(config.tokenAddress)) {
            collateralTypes.add(config.tokenAddress);
        }

        if (config.minDelegationD18 < config.liquidationRewardD18) {
            revert ParameterError.InvalidParameter("minDelegation", "must be greater than liquidationReward");
        }

        Data storage storedConfig = load(config.tokenAddress);

        storedConfig.tokenAddress = config.tokenAddress;
        storedConfig.issuanceRatioD18 = config.issuanceRatioD18;
        storedConfig.liquidationRatioD18 = config.liquidationRatioD18;
        storedConfig.oracleNodeId = config.oracleNodeId;
        storedConfig.liquidationRewardD18 = config.liquidationRewardD18;
        storedConfig.minDelegationD18 = config.minDelegationD18;
        storedConfig.depositingEnabled = config.depositingEnabled;
    }

    function collateralEnabled(address token) internal view {
        if (!load(token).depositingEnabled) {
            revert CollateralDepositDisabled(token);
        }
    }

    function requireSufficientDelegation(address token, uint amountD18) internal view {
        CollateralConfiguration.Data storage config = load(token);

        uint minDelegationD18 = config.minDelegationD18;

        if (minDelegationD18 == 0) {
            minDelegationD18 = config.liquidationRewardD18;
        }

        if (amountD18 < minDelegationD18) {
            revert InsufficientDelegation(minDelegationD18);
        }
    }

    function getCollateralPrice(Data storage self) internal view returns (uint) {
        OracleManager.Data memory oracleManager = OracleManager.load();
        Node.Data memory node = IOracleManagerModule(oracleManager.oracleManagerAddress).process(self.oracleNodeId);

        return uint(node.price);
    }

    function verifyIssuanceRatio(
        Data storage self,
        uint debtD18,
        uint collateralValueD18
    ) internal view {
        if (debtD18 != 0 && collateralValueD18.divDecimal(debtD18) < self.issuanceRatioD18) {
            revert InsufficientCollateralRatio(
                collateralValueD18,
                debtD18,
                collateralValueD18.divDecimal(debtD18),
                self.issuanceRatioD18
            );
        }
    }

    function convertTokenToSystemAmount(Data storage self, uint tokenAmount) internal view returns (uint) {
        // this extra condition is to prevent potentially malicious untrusted code from being executed on the next statement
        if (self.tokenAddress == address(0)) {
            revert CollateralNotFound();
        }

        return (tokenAmount * DecimalMath.UNIT) / (10**IERC20(self.tokenAddress).decimals());
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@synthetixio/core-contracts/contracts/utils/SetUtil.sol";

/**
 * @title Represents a given amount of collateral locked until a given date.
 */
library CollateralLock {
    struct Data {
        /**
         * @dev The amount of collateral that has been locked.
         */
        uint256 amountD18;
        /**
         * @dev The date when the locked amount becomes unlocked.
         */
        uint64 lockExpirationTime;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";
import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";
import "@synthetixio/core-contracts/contracts/errors/ParameterError.sol";

import "./DistributionActor.sol";

/**
 * @title Data structure that allows you to track some global value, distributed amongst a set of actors.
 *
 * The total value can be scaled with a valuePerShare multiplier, and individual actor shares can be calculated as their amount of shares times this multiplier.
 *
 * Furthermore, changes in the value of individual actors can be tracked since their last update, by keeping track of the value of the multiplier, per user, upon each interaction. See DistributionActor.lastValuePerShare.
 *
 * A distribution is similar to a ScalableMapping, but it has the added functionality of being able to remember the previous value of the scalar multiplier for each actor.
 *
 * Whenever the shares of an actor of the distribution is updated, you get information about how the actor's total value changed since it was last updated.
 */
library Distribution {
    using SafeCastU128 for uint128;
    using SafeCastU256 for uint256;
    using SafeCastI128 for int128;
    using SafeCastI256 for int256;
    using DecimalMath for int256;

    /**
     * @dev Thrown when an attempt is made to distribute value to a distribution
     * with no shares.
     */
    error EmptyDistribution();

    struct Data {
        /**
         * @dev The total number of shares in the distribution.
         */
        uint128 totalSharesD18;
        /**
         * @dev The value per share of the distribution, represented as a high precision decimal.
         */
        int128 valuePerShareD27;
        /**
         * @dev Tracks individual actor information, such as how many shares an actor has, their lastValuePerShare, etc.
         */
        mapping(bytes32 => DistributionActor.Data) actorInfo;
    }

    /**
     * @dev Inflates or deflates the total value of the distribution by the given value.
     *
     * The value being distributed ultimately modifies the distribution's valuePerShare.
     */
    function distributeValue(Data storage dist, int valueD18) internal {
        if (valueD18 == 0) {
            return;
        }

        uint totalSharesD18 = dist.totalSharesD18;

        if (totalSharesD18 == 0) {
            revert EmptyDistribution();
        }

        int valueD45 = valueD18 * DecimalMath.UNIT_PRECISE_INT;
        int deltaValuePerShareD27 = valueD45 / totalSharesD18.toInt();

        dist.valuePerShareD27 += deltaValuePerShareD27.to128();
    }

    /**
     * @dev Updates an actor's number of shares in the distribution to the specified amount.
     *
     * Whenever an actor's shares are changed in this way, we record the distribution's current valuePerShare into the actor's lastValuePerShare record.
     *
     * Returns the the amount by which the actors value changed since the last update.
     */
    function setActorShares(
        Data storage dist,
        bytes32 actorId,
        uint newActorSharesD18
    ) internal returns (int valueChangeD18) {
        valueChangeD18 = _getActorValueChange(dist, actorId);

        DistributionActor.Data storage actor = dist.actorInfo[actorId];

        uint128 sharesUint128D18 = newActorSharesD18.to128();
        dist.totalSharesD18 = dist.totalSharesD18 + sharesUint128D18 - actor.sharesD18;

        actor.sharesD18 = sharesUint128D18;

        actor.lastValuePerShareD27 = newActorSharesD18 == 0 ? int128(0) : dist.valuePerShareD27;
    }

    /**
     * @dev Updates an actor's lastValuePerShare to the distribution's current valuePerShare, and
     * returns the change in value for the actor, since their last update.
     */
    function accumulateActor(Data storage dist, bytes32 actorId) internal returns (int valueChangeD18) {
        return setActorShares(dist, actorId, getActorShares(dist, actorId));
    }

    /**
     * @dev Calculates how much an actor's value has changed since its shares were last updated.
     *
     * This change is calculated as:
     * Since `value = valuePerShare * shares`,
     * then `delta_value = valuePerShare_now * shares - valuePerShare_then * shares`,
     * which is `(valuePerShare_now - valuePerShare_then) * shares`,
     * or just `delta_valuePerShare * shares`.
     */
    function _getActorValueChange(Data storage dist, bytes32 actorId) private view returns (int valueChangeD18) {
        DistributionActor.Data storage actor = dist.actorInfo[actorId];
        int deltaValuePerShareD27 = dist.valuePerShareD27 - actor.lastValuePerShareD27;

        int changedValueD45 = deltaValuePerShareD27 * actor.sharesD18.toInt();
        valueChangeD18 = changedValueD45 / DecimalMath.UNIT_PRECISE_INT;
    }

    /**
     * @dev Returns the number of shares owned by an actor in the distribution.
     */
    function getActorShares(Data storage dist, bytes32 actorId) internal view returns (uint sharesD18) {
        return dist.actorInfo[actorId].sharesD18;
    }

    function getValuePerShare(Data storage self) internal view returns (int) {
        return int(self.valuePerShareD27).downscale(DecimalMath.PRECISION_FACTOR);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Stores information for specific actors in a Distribution.
 */
library DistributionActor {
    struct Data {
        /**
         * @dev The actor's current number of shares in the associated distribution.
         */
        uint128 sharesD18;
        /**
         * @dev The value per share that the associated distribution had at the time that the actor's number of shares was last modified.
         *
         * Note: This is also a high precision decimal. See Distribution.valuePerShare.
         */
        int128 lastValuePerShareD27;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";
import "@synthetixio/core-contracts/contracts/errors/ParameterError.sol";
import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

import "./Distribution.sol";

library DistributionEntry {
    using DecimalMath for int256;
    using SafeCastU128 for uint128;
    using SafeCastU256 for uint256;
    using SafeCastI128 for int128;
    using SafeCastI256 for int256;

    struct Data {
        // amount which should be applied at the given time below, or
        int128 scheduledValueD18;
        // set to <= block.timestamp to distribute immediately to currently staked users
        uint64 start;
        uint32 duration;
        uint32 lastUpdate;
    }

    /**
     * this function allows for more special cases such as distributing at a future date or distributing over time.
     * if you want to apply the distribution to the pool, call `distribute` with the return value. Otherwise, you can
     * record this independently as well
     */
    function distribute(
        Data storage entry,
        Distribution.Data storage dist,
        int amountD18,
        uint64 start,
        uint32 duration
    ) internal returns (int diffD18) {
        uint totalSharesD18 = dist.totalSharesD18;

        if (totalSharesD18 == 0) {
            revert ParameterError.InvalidParameter("amount", "can't distribute to empty distribution");
        }

        int curTime = block.timestamp.toInt().to128();

        // ensure any previously active distribution has applied
        diffD18 += updateEntry(entry, dist.totalSharesD18);

        if (start + duration <= curTime.toUint()) {
            // update any rewards which may have accrued since last run

            // instant distribution--immediately disperse amount
            diffD18 += amountD18.divDecimal(totalSharesD18.toInt());

            entry.lastUpdate = 0;
            entry.start = 0;
            entry.duration = 0;
            entry.scheduledValueD18 = 0;
        } else {
            // set distribution schedule
            entry.scheduledValueD18 = amountD18.to128();

            entry.start = start;
            entry.duration = duration;

            // the amount is actually the amount distributed already *plus* whatever has been specified now
            entry.lastUpdate = 0;

            diffD18 += updateEntry(entry, dist.totalSharesD18);
        }
    }

    /**
     * call every time before `totalShares` changes
     */
    function updateEntry(Data storage entry, uint totalSharesAmountD18) internal returns (int) {
        if (entry.scheduledValueD18 == 0 || totalSharesAmountD18 == 0) {
            // cannot process distributed rewards if a pool is empty.
            return 0;
        }

        int128 curTime = block.timestamp.toInt().to128();

        int valuePerShareChangeD18 = 0;

        if (curTime < int64(entry.start)) {
            return 0;
        }

        // determine whether this is an instant distribution or a delayed distribution
        if (entry.duration == 0 && entry.lastUpdate < entry.start) {
            valuePerShareChangeD18 = int(entry.scheduledValueD18).divDecimal(totalSharesAmountD18.toInt());
        } else if (entry.lastUpdate < entry.start + entry.duration) {
            // find out what is "newly" distributed
            int lastUpdateDistributedD18 = entry.lastUpdate < entry.start
                ? int128(0)
                : (entry.scheduledValueD18 * int64(entry.lastUpdate - entry.start)) / int32(entry.duration);

            int curUpdateDistributedD18 = entry.scheduledValueD18;
            if (curTime < int64(entry.start + entry.duration)) {
                curUpdateDistributedD18 = (curUpdateDistributedD18 * (curTime - int64(entry.start))) / int32(entry.duration);
            }

            valuePerShareChangeD18 = (curUpdateDistributedD18 - lastUpdateDistributedD18).divDecimal(
                totalSharesAmountD18.toInt()
            );
        }

        entry.lastUpdate = uint32(int32(curTime));

        return valuePerShareChangeD18;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@synthetixio/core-contracts/contracts/utils/SetUtil.sol";
import "@synthetixio/core-contracts/contracts/utils/HeapUtil.sol";

import "./Distribution.sol";
import "./CollateralConfiguration.sol";
import "./MarketPoolInfo.sol";

import "../interfaces/external/IMarket.sol";

/**
 * @title Connects external contracts that implement the `IMarket` interface to the system.
 *
 * Pools provide credit capacity (collateral) to the markets, and are reciprocally exposed to the associated market's debt.
 *
 * The Market object's main responsibility is to track collateral provided by the pools that support it, and to trace their debt back to such pools.
 */
library Market {
    using Distribution for Distribution.Data;
    using HeapUtil for HeapUtil.Data;
    using DecimalMath for uint256;
    using DecimalMath for uint128;
    using DecimalMath for int256;
    using DecimalMath for int128;

    using SafeCastU256 for uint256;
    using SafeCastU128 for uint128;
    using SafeCastI256 for int256;
    using SafeCastI128 for int128;

    error MarketNotFound(uint128 marketId);

    struct Data {
        /**
         * @dev Numeric identifier for the market. Must be unique.
         * @dev There cannot be a market with id zero (See MarketCreator.create()). Id zero is used as a null market reference.
         */
        uint128 id;
        /**
         * @dev Address for the external contract that implements the `IMarket` interface, which this Market objects connects to.
         *
         * Note: This object is how the system tracks the market. The actual market is external to the system, i.e. its own contract.
         */
        address marketAddress;
        /**
         * @dev Issuance can be seen as how much USD the Market "has issued", printed, or has asked the system to mint on its behalf.
         *
         * More precisely it can be seen as the net difference between the USD burnt and the USD minted by the market.
         *
         * More issuance means that the market owes more USD to the system.
         *
         * A market burns USD when users deposit it in exchange for some asset that the market offers.
         * The Market object calls `MarketManager.depositUSD()`, which burns the USD, and decreases its issuance.
         *
         * A market mints USD when users return the asset that the market offered and thus withdraw their USD.
         * The Market object calls `MarketManager.withdrawUSD()`, which mints the USD, and increases its issuance.
         *
         * Instead of burning, the Market object could transfer USD to and from the MarketManager, but minting and burning takes the USD out of circulation, which doesn't affect `totalSupply`, thus simplifying accounting.
         *
         * How much USD a market can mint depends on how much credit capacity is given to the market by the pools that support it, and reflected in `Market.capacity`.
         *
         */
        int128 netIssuanceD18;
        /**
         * @dev The total amount of USD that the market could withdraw if it were to immediately unwrap all its positions.
         *
         * The Market's credit capacity increases when the market burns USD, i.e. when it deposits USD in the MarketManager.
         *
         * It decreases when the market mints USD, i.e. when it withdraws USD from the MarketManager.
         *
         * The Market's credit capacity also depends on how much credit is given to it by the pools that support it.
         *
         * The Market's credit capacity also has a dependency on the external market reported debt as it will respond to that debt (and hence change the credit capacity if it increases or decreases)
         *
         */
        uint128 creditCapacityD18;
        /**
         * @dev The total balance that the market had the last time that its debt was distributed.
         *
         * A Market's debt is distributed when the reported debt of its associated external market is rolled into the pools that provide credit capacity to it.
         */
        int128 lastDistributedMarketBalanceD18;
        /**
         * @dev A heap of pools for which the market has not yet hit its maximum credit capacity.
         *
         * The heap is ordered according to this market's max value per share setting in the pools that provide credit capacity to it. See `MarketConfiguration.maxDebtShareValue`.
         *
         * The heap's getMax() and extractMax() functions allow us to retrieve the pool with the lowest `maxDebtShareValue`, since its elements are inserted and prioritized by negating their `maxDebtShareValue`.
         *
         * Lower max values per share are on the top of the heap. I.e. the heap could look like this:
         *  .    -1
         *      / \
         *     /   \
         *    -2    \
         *   / \    -3
         * -4   -5
         *
         * TL;DR: This data structure allows us to easily find the pool with the lowest or "most vulnerable" max value per share and process it if its actual value per share goes beyond this limit.
         */
        HeapUtil.Data inRangePools;
        /**
         * @dev A heap of pools for which the market has hit its maximum credit capacity.
         *
         * Used to reconnect pools to the market, when it falls back below its maximum credit capacity.
         *
         * See inRangePools for why a heap is used here.
         */
        HeapUtil.Data outRangePools;
        /**
         * @dev A market's debt distribution connects markets to the debt distribution chain, in this case pools. Pools are actors in the market's debt distribution, where the amount of shares they possess depends on the amount of collateral they provide to the market. The value per share of this distribution depends on the total debt or balance of the market (netIssuance + reportedDebt).
         *
         * The debt distribution chain will move debt from the market into its connected pools.
         *
         * Actors: Pools.
         * Shares: The USD denominated credit capacity that the pool provides to the market.
         * Value per share: Debt per dollar of credit that the associated external market accrues.
         *
         */
        Distribution.Data poolsDebtDistribution;
        /**
         * @dev Additional info needed to remember pools when they are removed from the distribution (or subsequently re-added).
         */
        mapping(uint128 => MarketPoolInfo.Data) pools;
        /**
         * @dev Array of entries of market provided collateral.
         *
         * Markets may obtain additional liquidity, beyond that coming from stakers, by providing their own collateral.
         *
         */
        DepositedCollateral[] depositedCollateral;
        /**
         * @dev The maximum amount of market provided collateral, per type, that this market can deposit.
         */
        mapping(address => uint) maximumDepositableD18;
    }

    /**
     * @dev Data structure that allows the Market to track the amount of market provided collateral, per type.
     */
    struct DepositedCollateral {
        address collateralType;
        uint amountD18;
    }

    /**
     * @dev Returns the market stored at the specified market id.
     */
    function load(uint128 id) internal pure returns (Data storage data) {
        bytes32 s = keccak256(abi.encode("Market", id));
        assembly {
            data.slot := s
        }
    }

    /**
     * @dev Queries the external market contract for the amount of debt it has issued.
     *
     * The reported debt of a market represents the amount of USD that the market would ask the system to mint, if all of its positions were to be immediately closed.
     *
     * The reported debt of a market is collateralized by the assets in the pools which back it.
     *
     * See the `IMarket` interface.
     */
    function getReportedDebt(Data storage self) internal view returns (uint) {
        return IMarket(self.marketAddress).reportedDebt(self.id);
    }

    /**
     * @dev Queries the market for the amount of collateral which should be prevented from withdrawal.
     */
    function getLockedCreditCapacity(Data storage self) internal view returns (uint) {
        return IMarket(self.marketAddress).locked(self.id);
    }

    /**
     * @dev Returns the total debt of the market.
     *
     * A market's total debt represents its debt plus its issuance, and thus represents the total outstanding debt of the market.
     *
     * Note: it also takes into account the deposited collateral value. See note in  getDepositedCollateralValue()
     *
     * Example:
     * (1 EUR = 1.11 USD)
     * If an Euro market has received 100 USD to mint 90 EUR, its reported debt is 90 EUR or 100 USD, and its issuance is -100 USD.
     * Thus, its total balance is 100 USD of reported debt minus 100 USD of issuance, which is 0 USD.
     *
     * Additionally, the market's totalDebt might be affected by price fluctuations via reportedDebt, or fees.
     *
     */
    function totalDebt(Data storage self) internal view returns (int) {
        return getReportedDebt(self).toInt() + self.netIssuanceD18 - getDepositedCollateralValue(self).toInt();
    }

    /**
     * @dev Returns the USD value for the total amount of collateral provided by the market itself.
     *
     * Note: This is not credit capacity provided by stakers through pools.
     */
    function getDepositedCollateralValue(Data storage self) internal view returns (uint) {
        uint totalDepositedCollateralValueD18 = 0;

        // Sweep all DepositedCollateral entries and aggregate their USD value.
        for (uint i = 0; i < self.depositedCollateral.length; i++) {
            DepositedCollateral memory entry = self.depositedCollateral[i];
            CollateralConfiguration.Data storage collateralConfiguration = CollateralConfiguration.load(
                entry.collateralType
            );

            uint priceD18 = CollateralConfiguration.getCollateralPrice(collateralConfiguration);

            totalDepositedCollateralValueD18 += priceD18.mulDecimal(entry.amountD18);
        }

        return totalDepositedCollateralValueD18;
    }

    /**
     * @dev Returns the amount of credit capacity that a certain pool provides to the market.

     * This credit capacity is obtained by reading the amount of shares that the pool has in the market's debt distribution, which represents the amount of USD denominated credit capacity that the pool has provided to the market.
     */
    function getPoolCreditCapacity(Data storage self, uint128 poolId) internal view returns (uint) {
        return self.poolsDebtDistribution.getActorShares(bytes32(uint(poolId)));
    }

    /**
     * @dev Given an amount of shares that represent USD credit capacity from a pool, and a maximum value per share, returns the potential contribution to credit capacity that these shares could accrue, if their value per share was to hit the maximum.
     *
     * The resulting value is calculated multiplying the amount of creditCapacity provided by the pool by the delta between the maxValue per share vs current value.
     *
     * This function is used when the Pools are rebalanced to adjust each pool credit capacity based on a change in the amount of shares provided and/or a new maxValue per share
     *
     */
    function getCreditCapacityContribution(
        Data storage self,
        uint creditCapacitySharesD18,
        int maxShareValueD18
    ) internal view returns (uint contributionD18) {
        // Determine how much the current value per share deviates from the maximum.
        uint deltaValuePerShareD18 = (maxShareValueD18 - self.poolsDebtDistribution.getValuePerShare()).toUint();

        return deltaValuePerShareD18.mulDecimal(creditCapacitySharesD18);
    }

    /**
     * @dev Returns true if the market's current capacity is below the amount of locked capacity.
     *
     */
    function isCapacityLocked(Data storage self) internal view returns (bool) {
        return self.creditCapacityD18 < getLockedCreditCapacity(self);
    }

    /**
     * @dev Gets any outstanding debt. Do not call this method except in tests
     *
     * Note: This function should only be used in tests!
     */
    // solhint-disable-next-line private-vars-leading-underscore, func-name-mixedcase
    function _testOnly_getOutstandingDebt(Data storage self, uint128 poolId) internal returns (int debtChangeD18) {
        return self.pools[poolId].pendingDebtD18.toInt() + self.poolsDebtDistribution.accumulateActor(bytes32(uint(poolId)));
    }

    /**
     * @dev Returns the debt value per share
     */
    function getDebtPerShare(Data storage self) internal view returns (int debtPerShareD18) {
        return self.poolsDebtDistribution.getValuePerShare();
    }

    /**
     * @dev Wrapper that adjusts a pool's shares in the market's credit capacity, making sure that the market's outstanding debt is first passed on to its connected pools.
     *
     * Called by a pool when it distributes its debt.
     *
     */
    function rebalancePools(
        uint128 marketId,
        uint128 poolId,
        int maxDebtShareValueD18, // (in USD)
        uint newCreditCapacityD18 // in collateralValue (USD)
    ) internal returns (int debtChangeD18) {
        Data storage self = load(marketId);

        if (self.marketAddress == address(0)) {
            revert MarketNotFound(marketId);
        }

        // Iter avoids griefing - MarketManager can call this with user specified iters and thus clean up a grieved market.
        distributeDebtToPools(self, 9999999999);

        return adjustPoolShares(self, poolId, newCreditCapacityD18, maxDebtShareValueD18);
    }

    /**
     * @dev Called by pools when they modify the credit capacity provided to the market, as well as the maximum value per share they tolerate for the market.
     *
     * These two settings affect the market in the following ways:
     * - Updates the pool's shares in `poolsDebtDistribution`.
     * - Moves the pool in and out of inRangePools/outRangePools.
     * - Updates the market credit capacity property.
     */
    function adjustPoolShares(
        Data storage self,
        uint128 poolId,
        uint newCreditCapacityD18,
        int newPoolMaxShareValueD18
    ) internal returns (int debtChangeD18) {
        uint oldCreditCapacityD18 = getPoolCreditCapacity(self, poolId);
        int oldPoolMaxShareValueD18 = -self.inRangePools.getById(poolId).priority;

        // Sanity checks
        // require(oldPoolMaxShareValue == 0, "value is not 0");
        // require(newPoolMaxShareValue == 0, "new pool max share value is in fact set");

        self.pools[poolId].creditCapacityAmountD18 = newCreditCapacityD18.to128();

        int128 valuePerShareD18 = self.poolsDebtDistribution.getValuePerShare().to128();

        if (newPoolMaxShareValueD18 < valuePerShareD18) {
            // this will ensure calculations below can correctly gauge shares changes
            newCreditCapacityD18 = 0;
            self.inRangePools.extractById(poolId);
            self.outRangePools.insert(poolId, newPoolMaxShareValueD18.to128());
        } else {
            self.inRangePools.insert(poolId, -newPoolMaxShareValueD18.to128());
            self.outRangePools.extractById(poolId);
        }

        int changedValueD18 = self.poolsDebtDistribution.setActorShares(bytes32(uint(poolId)), newCreditCapacityD18);
        debtChangeD18 = self.pools[poolId].pendingDebtD18.toInt() + changedValueD18;
        self.pools[poolId].pendingDebtD18 = 0;

        // recalculate market capacity
        if (newPoolMaxShareValueD18 > valuePerShareD18) {
            self.creditCapacityD18 += getCreditCapacityContribution(self, newCreditCapacityD18, newPoolMaxShareValueD18)
                .to128();
        }

        if (oldPoolMaxShareValueD18 > valuePerShareD18) {
            self.creditCapacityD18 -= getCreditCapacityContribution(self, oldCreditCapacityD18, oldPoolMaxShareValueD18)
                .to128();
        }
    }

    /**
     * @dev Moves debt from the market into the pools that connect to it.
     *
     * This function should be called before any of the pools' shares are modified in `poolsDebtDistribution`.
     *
     * Note: The parameter `maxIter` is used as an escape hatch to discourage griefing.
     */
    function distributeDebtToPools(Data storage self, uint maxIter) internal {
        // Get the current and last distributed market balances.
        // Note: The last distributed balance will be cached within this function's execution.
        int256 targetBalanceD18 = totalDebt(self);
        int256 outstandingBalanceD18 = targetBalanceD18 - self.lastDistributedMarketBalanceD18;

        (, bool exhausted) = _bumpPools(self, outstandingBalanceD18, maxIter);

        if (!exhausted && self.poolsDebtDistribution.totalSharesD18 > 0) {
            // cannot use `outstandingBalance` here because `self.lastDistributedMarketBalance`
            // may have changed after calling the bump functions above
            self.poolsDebtDistribution.distributeValue(targetBalanceD18 - self.lastDistributedMarketBalanceD18);
            self.lastDistributedMarketBalanceD18 = targetBalanceD18.to128();
        }
    }

    /**
     * @dev Determine the target valuePerShare of the poolsDebtDistribution, given the value that is yet to be distributed.
     */
    function _getTargetValuePerShare(Market.Data storage self, int valueToDistributeD18)
        private
        view
        returns (int targetValuePerShareD18)
    {
        return
            self.poolsDebtDistribution.getValuePerShare() +
            valueToDistributeD18.divDecimal(self.poolsDebtDistribution.totalSharesD18.toInt());
    }

    /**
     * @dev Finds pools for which this market's max value per share limit is hit, distributes their debt, and disconnects the market from them.
     *
     * The debt is distributed up to the limit of the max value per share that the pool tolerates on the market.
     */
    function _bumpPools(
        Data storage self,
        int maxDistributedD18,
        uint maxIter
    ) private returns (int actuallyDistributedD18, bool exhausted) {
        if (maxDistributedD18 == 0 || self.poolsDebtDistribution.totalSharesD18 == 0) {
            return (0, false);
        }

        // Determine the direction based on the amount to be distributed.
        int128 k;
        HeapUtil.Data storage fromHeap;
        HeapUtil.Data storage toHeap;
        if (maxDistributedD18 > 0) {
            k = 1;
            fromHeap = self.inRangePools;
            toHeap = self.outRangePools;
        } else {
            k = -1;
            fromHeap = self.outRangePools;
            toHeap = self.inRangePools;
        }

        // Note: This loop should rarely execute its main body. When it does, it only executes once for each pool that exceeds the limit since `distributeValue` is not run for most pools. Thus, market users are not hit with any overhead as a result of this.
        uint iters;
        for (iters = 0; iters < maxIter; iters++) {
            // Exit if there are no in range pools.
            if (fromHeap.size() == 0) {
                break;
            }

            // Identify the pool with the lowest maximum value per share.
            HeapUtil.Node memory edgePool = fromHeap.getMax();

            // Exit if the lowest max value per share does not hit the limit.
            // Note: `-edgePool.priority` is actually the max value per share limit of the pool
            if (-edgePool.priority >= k * _getTargetValuePerShare(self, (maxDistributedD18 - actuallyDistributedD18))) {
                break;
            }

            // The pool has hit its maximum value per share and needs to be removed.
            // Note: No need to update capacity because pool max share value = valuePerShare when this happens.
            _togglePool(fromHeap, toHeap);

            // Distribute the market's debt to the limit, i.e. for that which exceeds the maximum value per share.
            int debtToLimitD18 = self.poolsDebtDistribution.totalSharesD18.toInt().mulDecimal(
                -k * edgePool.priority - self.poolsDebtDistribution.getValuePerShare() // Diff between current value and max value per share.
            );
            self.poolsDebtDistribution.distributeValue(debtToLimitD18);

            // Update the global distributed and outstanding balances with the debt that was just distributed.
            actuallyDistributedD18 += debtToLimitD18;

            // Detach the market from this pool by removing the pool's shares from the market.
            // The pool will remain "detached" until the pool manager specifies a new poolsDebtDistribution.
            if (maxDistributedD18 > 0) {
                require(
                    self.poolsDebtDistribution.getActorShares(bytes32(uint(edgePool.id))) > 0,
                    "no shares before actor removal"
                );

                uint newPoolDebtD18 = self.poolsDebtDistribution.setActorShares(bytes32(uint(edgePool.id)), 0).toUint();
                self.pools[edgePool.id].pendingDebtD18 += newPoolDebtD18.to128();
            } else {
                require(
                    self.poolsDebtDistribution.getActorShares(bytes32(uint(edgePool.id))) == 0,
                    "actor has shares before add"
                );

                self.poolsDebtDistribution.setActorShares(
                    bytes32(uint(edgePool.id)),
                    self.pools[edgePool.id].creditCapacityAmountD18
                );
            }
        }

        // Record the accumulated distributed balance.
        self.lastDistributedMarketBalanceD18 += actuallyDistributedD18.to128();

        exhausted = iters == maxIter;
    }

    /**
     * @dev Moves a pool from one heap into another.
     */
    function _togglePool(HeapUtil.Data storage from, HeapUtil.Data storage to) private {
        HeapUtil.Node memory node = from.extractMax();
        to.insert(node.id, -node.priority);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@synthetixio/core-contracts/contracts/utils/SetUtil.sol";

/**
 * @title Tracks a market's weight within a Pool, and its maximum debt.
 *
 * Each pool has an array of these, with one entry per market managed by the pool.
 *
 * A market's weight determines how much liquidity the pool provides to the market, and how much debt exposure the market gives the pool.
 *
 * Weights are used to calculate percentages by adding all the weights in the pool and dividing the market's weight by the total weights.
 *
 * A market's maximum debt in a pool is indicated with a maximum debt value per share.
 */
library MarketConfiguration {
    struct Data {
        /**
         * @dev Numeric identifier for the pool.
         *
         * Must be unique.
         */
        uint128 marketId;
        /**
         * @dev The ratio of each market's `weight` to the pool's `totalWeights` determines the pro-rata share of the market to the pool's total liquidity.
         */
        uint128 weightD18;
        /**
         * @dev Maximum value per share that a pool will tolerate for this market.
         *
         * If the the limit is met, the markets exceeding debt will be distributed, and it will be disconnected from the pool that no longer provides credit to it.
         *
         * Note: This value will have no effect if the system wide limit is hit first. See `PoolConfiguration.minLiquidityRatioD18`.
         */
        int128 maxDebtShareValueD18;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Stores information for specific actors in a Distribution.
 */
library MarketPoolInfo {
    struct Data {
        /**
         * @dev . Needed to re-add the pool to the distribution when going back in range
         */
        uint128 creditCapacityAmountD18;
        /**
         * @dev The amount of debt the pool has which hasn't been passed down the debt distribution chain yet
         */
        uint128 pendingDebtD18;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Represents Oracle Manager
 */
library OracleManager {
    struct Data {
        /**
         * @dev The oracle manager address.
         */
        address oracleManagerAddress;
    }

    function load() internal pure returns (Data storage data) {
        bytes32 s = keccak256(abi.encode("OracleManager"));
        assembly {
            data.slot := s
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Distribution.sol";
import "./MarketConfiguration.sol";
import "./Vault.sol";
import "./Market.sol";
import "./SystemPoolConfiguration.sol";

import "@synthetixio/core-contracts/contracts/errors/AccessError.sol";

import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

/**
 * @title Aggregates collateral from multiple users in order to provide liquidity to a configurable set of markets.
 *
 * The set of markets is configured as an array of MarketConfiguration objects, where the weight of the market can be specified. This weight, and the aggregated total weight of all the configured markets, determines how much collateral from the pool each market has, as well as in what proportion the market passes on debt to the pool and thus to all its users.
 *
 * The pool tracks the collateral provided by users using an array of Vaults objects, for which there will be one per collateral type. Each vault tracks how much collateral each user has delegated to this pool, how much debt the user has because of minting USD, as well as how much corresponding debt the pool has passed on to the user.
 */
library Pool {
    using CollateralConfiguration for CollateralConfiguration.Data;
    using Market for Market.Data;
    using Vault for Vault.Data;
    using Distribution for Distribution.Data;
    using DecimalMath for uint256;
    using DecimalMath for int256;
    using DecimalMath for int128;

    using SafeCastU128 for uint128;
    using SafeCastU256 for uint256;
    using SafeCastI128 for int128;
    using SafeCastI256 for int256;

    error PoolNotFound(uint128 poolId);
    error PoolAlreadyExists(uint128 poolId);

    struct Data {
        /**
         * @dev Numeric identifier for the pool. Must be unique.
         * @dev A pool with id zero exists! (See Pool.exists()). Users can delegate to this pool to be able to mint USD without being exposed to fluctuating debt.
         */
        uint128 id;
        /**
         * @dev Text identifier for the pool.
         *
         * Not required to be unique.
         */
        string name;
        /**
         * @dev Creator of the pool, which has configuration access rights for the pool.
         *
         * See onlyPoolOwner.
         */
        address owner;
        /**
         * @dev Allows the current pool owner to nominate a new owner, and thus transfer pool configuration credentials.
         */
        address nominatedOwner;
        /**
         * @dev Sum of all market weights.
         *
         * Market weights are tracked in `MarketConfiguration.weight`, one for each market. The ratio of each market's `weight` to the pool's `totalWeights` determines the pro-rata share of the market to the pool's total liquidity.
         *
         * Reciprocally, this pro-rata share also determines how much the pool is exposed to each market's debt.
         */
        uint128 totalWeightsD18;
        /**
         * @dev Accumulated cache value of all vault collateral debts
         */
        int128 totalVaultDebtsD18;
        /**
         * @dev Array of markets connected to this pool, and their configurations. I.e. weight, etc.
         *
         * See totalWeights.
         */
        MarketConfiguration.Data[] marketConfigurations;
        /**
         * @dev A pool's debt distribution connects pools to the debt distribution chain, i.e. vaults and markets. Vaults are actors in the pool's debt distribution, where the amount of shares they possess depends on the amount of collateral each vault delegates to the pool.
         *
         * The debt distribution chain will move debt from markets into this pools, and then from pools to vaults.
         *
         * Actors: Vaults.
         * Shares: USD value, proportional to the amount of collateral that the vault delegates to the pool.
         * Value per share: Debt per dollar of collateral. Depends on aggregated debt of connected markets.
         *
         */
        Distribution.Data vaultsDebtDistribution;
        /**
         * @dev Reference to all the vaults that provide liquidity to this pool.
         *
         * Each collateral type will have its own vault, specific to this pool. I.e. if two pools both use SNX collateral, each will have its own SNX vault.
         *
         * Vaults track user collateral and debt using a debt distribution, which is connected to the debt distribution chain.
         */
        mapping(address => Vault.Data) vaults;
    }

    /**
     * @dev Returns the pool stored at the specified pool id.
     */
    function load(uint128 id) internal pure returns (Data storage data) {
        bytes32 s = keccak256(abi.encode("Pool", id));
        assembly {
            data.slot := s
        }
    }

    /**
     * @dev Creates a pool for the given pool id, and assigns the caller as its owner.
     *
     * Reverts if the specified pool already exists.
     */
    function create(uint128 id, address owner) internal returns (Pool.Data storage self) {
        if (Pool.exists(id)) {
            revert PoolAlreadyExists(id);
        }

        self = load(id);

        self.id = id;
        self.owner = owner;
    }

    /**
     * @dev Ticker function that updates the debt distribution chain downwards, from markets into the pool, according to each market's weight.
     *
     * It updates the chain by performing these actions:
     * - Splits the pool's total liquidity of the pool into each market, pro-rata. The amount of shares that the pool has on each market depends on how much liquidity the pool provides to the market.
     * - Accumulates the change in debt value from each market into the pools own vault debt distribution's value per share.
     */
    function distributeDebtToVaults(Data storage self) internal {
        uint totalWeightsD18 = self.totalWeightsD18;

        if (totalWeightsD18 == 0) {
            return; // Nothing to rebalance.
        }

        // Read from storage once, before entering the loop below.
        // These values should not change while iterating through each market.
        uint totalCreditCapacityD18 = self.vaultsDebtDistribution.totalSharesD18;
        int128 totalDebtD18 = self.totalVaultDebtsD18;

        int cumulativeDebtChangeD18 = 0;

        // Loop through the pool's markets, applying market weights, and tracking how this changes the amount of debt that this pool is responsible for.
        // This debt extracted from markets is then applied to the pool's vault debt distribution, which thus exposes debt to the pool's vaults.
        for (uint i = 0; i < self.marketConfigurations.length; i++) {
            MarketConfiguration.Data storage marketConfiguration = self.marketConfigurations[i];

            uint weightD18 = marketConfiguration.weightD18;

            // Calculate each market's pro-rata USD liquidity.
            // Note: the factor `(weight / totalWeights)` is not deduped in the operations below to maintain numeric precision.

            uint marketCreditCapacityD18 = (totalCreditCapacityD18 * weightD18) / totalWeightsD18;
            int marketDebtD18 = (totalDebtD18 * weightD18.toInt()) / totalWeightsD18.toInt();

            Market.Data storage marketData = Market.load(marketConfiguration.marketId);

            // Contain the pool imposed market's maximum debt share value.
            // Imposed by system.
            int effectiveMaxShareValueD18 = getSystemMaxValuePerShare(
                self,
                marketData.id,
                marketCreditCapacityD18,
                marketDebtD18
            );
            // Imposed by pool.
            int configuredMaxShareValueD18 = marketConfiguration.maxDebtShareValueD18;
            effectiveMaxShareValueD18 = effectiveMaxShareValueD18 < configuredMaxShareValueD18
                ? effectiveMaxShareValueD18
                : configuredMaxShareValueD18;

            // Update each market's corresponding credit capacity.
            // The returned value represents how much the market's debt changed after changing the shares of this pool actor, which is aggregated to later be passed on the pools debt distribution.
            cumulativeDebtChangeD18 += Market.rebalancePools(
                marketConfiguration.marketId,
                self.id,
                effectiveMaxShareValueD18,
                marketCreditCapacityD18
            );
        }

        // Passes on the accumulated debt changes from the markets, into the pool, so that vaults can later access this debt.
        self.vaultsDebtDistribution.distributeValue(cumulativeDebtChangeD18);
    }

    /**
     * @dev Implements a system-wide fail safe to prevent a market from taking too much debt.
     *
     * Note: There is a non-system-wide fail safe for each market at `MarketConfiguration.maxDebtShareValue`.
     *
     * See `SystemPoolConfiguration.minLiquidityRatio`.
     */
    function getSystemMaxValuePerShare(
        Data storage self,
        uint128 marketId, // we are keeping this value as a uint128 for now for testability reasons
        uint creditCapacityD18,
        int debtD18
    ) internal view returns (int) {
        Market.Data storage marketData = Market.load(marketId);
        uint minLiquidityRatioD18 = SystemPoolConfiguration.load().minLiquidityRatioD18;

        // Calculate the margin of debt that the market could incur to hit the system wide limit.
        uint totalSharesD18 = self.vaultsDebtDistribution.totalSharesD18;
        int valuePerShareD18 = marketData.poolsDebtDistribution.getValuePerShare();

        if (minLiquidityRatioD18 == 0) {
            // If minLiquidityRatioD18 is zero, then set limit to 100%.
            return valuePerShareD18 + int(DecimalMath.UNIT);
        } else if (totalSharesD18 == 0) {
            // margin = credit / systemLimit, per share
            return valuePerShareD18;
        } else {
            uint marginD18 = creditCapacityD18.divDecimal(minLiquidityRatioD18).divDecimal(totalSharesD18);

            return
                marketData.poolsDebtDistribution.getValuePerShare() +
                marginD18.toInt() -
                debtD18.divDecimal(totalSharesD18.toInt());
        }
    }

    /**
     * @dev Returns true if a pool with the specified id exists.
     *
     * Note: Pool zero always exists, see "Pool.id".
     */
    function exists(uint128 id) internal view returns (bool) {
        return id == 0 || load(id).id == id;
    }

    /**
     * @dev Returns true if the pool is exposed to the specified market.
     */
    function hasMarket(Data storage self, uint128 marketId) internal view returns (bool) {
        for (uint i = 0; i < self.marketConfigurations.length; i++) {
            if (self.marketConfigurations[i].marketId == marketId) {
                return true;
            }
        }

        return false;
    }

    /**
     * @dev Ticker function that updates the debt distribution chain for a specific collateral type downwards, from the pool into the corresponding the vault, according to changes in the collateral's price.
     *
     * It updates the chain by performing these actions:
     * - Collects the latest price of the corresponding collateral and updates the vault's liquidity.
     * - Updates the vaults shares in the pool's debt distribution, according to the collateral provided by the vault.
     * - Updates the value per share of the vault's debt distribution.
     */
    function recalculateVaultCollateral(Data storage self, address collateralType)
        internal
        returns (uint collateralPriceD18)
    {
        // Update each market's pro-rata liquidity and collect accumulated debt into the pool's debt distribution.
        distributeDebtToVaults(self);

        // Transfer the debt change from the pool into the vault.
        bytes32 actorId = bytes32(uint(uint160(collateralType)));
        self.vaults[collateralType].distributeDebtToAccounts(self.vaultsDebtDistribution.accumulateActor(actorId));

        // Get the latest collateral price.
        collateralPriceD18 = CollateralConfiguration.load(collateralType).getCollateralPrice();

        // Changes in price update the corresponding vault's total collateral value as well as its liquidity (collateral - debt).
        (uint usdWeightD18, , int deltaDebtD18) = self.vaults[collateralType].updateCreditCapacity(collateralPriceD18);

        // Update the vault's shares in the pool's debt distribution, according to the value of its collateral.
        self.vaultsDebtDistribution.setActorShares(actorId, usdWeightD18);

        // Accumulate the change in total liquidity, from the vault, into the pool.
        self.totalVaultDebtsD18 = self.totalVaultDebtsD18 + deltaDebtD18.to128();

        // Distribute debt again because the market credit capacity may have changed, so we should ensure the vaults have the most up to date capacities
        distributeDebtToVaults(self);
    }

    /**
     * @dev Updates the debt distribution chain for this pool, and consolidates the given account's debt.
     */
    function updateAccountDebt(
        Data storage self,
        address collateralType,
        uint128 accountId
    ) internal returns (int debtD18) {
        recalculateVaultCollateral(self, collateralType);

        return self.vaults[collateralType].consolidateAccountDebt(accountId);
    }

    /**
     * @dev Clears all vault data for the specified collateral type.
     */
    function resetVault(Data storage self, address collateralType) internal {
        // Creates a new epoch in the vault, effectively zeroing out all values.
        self.vaults[collateralType].reset();

        // Ensure that the vault's values update the debt distribution chain.
        recalculateVaultCollateral(self, collateralType);
    }

    /**
     * @dev Calculates the collateralization ratio of the vault that tracks the given collateral type.
     *
     * The c-ratio is the vault's share of the total debt of the pool, divided by the collateral it delegates to the pool.
     *
     * Note: This is not a view function. It updates the debt distribution chain before performing any calculations.
     */
    function currentVaultCollateralRatio(Data storage self, address collateralType) internal returns (uint) {
        recalculateVaultCollateral(self, collateralType);

        int debtD18 = self.vaults[collateralType].currentDebt();
        (, uint collateralValueD18) = currentVaultCollateral(self, collateralType);

        return debtD18 > 0 ? debtD18.toUint().divDecimal(collateralValueD18) : 0;
    }

    /**
     * @dev Finds a connected market whose credit capacity has reached its locked limit.
     *
     * Note: Returns market zero (null market) if none is found.
     */
    function findMarketWithCapacityLocked(Data storage self) internal view returns (Market.Data storage lockedMarketId) {
        for (uint i = 0; i < self.marketConfigurations.length; i++) {
            Market.Data storage market = Market.load(self.marketConfigurations[i].marketId);

            if (market.isCapacityLocked()) {
                return market;
            }
        }

        // Market zero = null market.
        return Market.load(0);
    }

    /**
     * @dev Returns the debt of the vault that tracks the given collateral type.
     *
     * The vault's debt is the vault's share of the total debt of the pool, or its share of the total debt of the markets connected to the pool. The size of this share depends on how much collateral the pool provides to the pool.
     *
     * Note: This is not a view function. It updates the debt distribution chain before performing any calculations.
     */
    function currentVaultDebt(Data storage self, address collateralType) internal returns (int) {
        recalculateVaultCollateral(self, collateralType);

        return self.vaults[collateralType].currentDebt();
    }

    /**
     * @dev Returns the total amount and value of the specified collateral delegated to this pool.
     */
    function currentVaultCollateral(Data storage self, address collateralType)
        internal
        view
        returns (uint collateralAmountD18, uint collateralValueD18)
    {
        uint collateralPriceD18 = CollateralConfiguration.load(collateralType).getCollateralPrice();

        collateralAmountD18 = self.vaults[collateralType].currentCollateral();
        collateralValueD18 = collateralPriceD18.mulDecimal(collateralAmountD18);
    }

    /**
     * @dev Returns the amount and value of collateral that the specified account has delegated to this pool.
     */
    function currentAccountCollateral(
        Data storage self,
        address collateralType,
        uint128 accountId
    ) internal view returns (uint collateralAmountD18, uint collateralValueD18) {
        uint collateralPriceD18 = CollateralConfiguration.load(collateralType).getCollateralPrice();

        collateralAmountD18 = self.vaults[collateralType].currentAccountCollateral(accountId);
        collateralValueD18 = collateralPriceD18.mulDecimal(collateralAmountD18);
    }

    /**
     * @dev Returns the specified account's collateralization ratio (collateral / debt).
     */
    function currentAccountCollateralizationRatio(
        Data storage self,
        address collateralType,
        uint128 accountId
    ) internal returns (uint) {
        (, uint getPositionCollateralValueD18) = currentAccountCollateral(self, collateralType, accountId);
        int getPositionDebtD18 = updateAccountDebt(self, collateralType, accountId);

        // if they have a credit, just treat their debt as 0
        return getPositionCollateralValueD18.divDecimal(getPositionDebtD18 < 0 ? 0 : getPositionDebtD18.toUint());
    }

    /**
     * @dev Reverts if the specified pool does not exist.
     */
    function requireExists(uint128 poolId) internal view {
        if (!Pool.exists(poolId)) {
            revert PoolNotFound(poolId);
        }
    }

    /**
     * @dev Reverts if the caller is not the owner of the specified pool.
     */
    function onlyPoolOwner(uint128 poolId, address caller) internal view {
        if (Pool.load(poolId).owner != caller) {
            revert AccessError.Unauthorized(caller);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/external/IRewardDistributor.sol";

import "./DistributionEntry.sol";
import "./RewardDistributionStatus.sol";

library RewardDistribution {
    struct Data {
        // 3rd party smart contract which holds/mints the pools
        IRewardDistributor distributor;
        DistributionEntry.Data entry;
        uint128 rewardPerShareD18;
        mapping(uint256 => RewardDistributionStatus.Data) actorInfo;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library RewardDistributionStatus {
    struct Data {
        uint128 lastRewardPerShareD18;
        uint128 pendingSendD18;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";
import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

import "./DistributionActor.sol";

/**
 * @title Data structure that wraps a mapping with a scalar multiplier.
 *
 * If you wanted to modify all the values in a mapping by the same amount, you would normally have to loop through each entry in the mapping. This object allows you to modify all of them at once, by simply modifying the scalar multiplier.
 *
 * I.e. a regular mapping represents values like this:
 * value = mapping[id]
 *
 * And a scalable mapping represents values like this:
 * value = mapping[id] * scalar
 *
 * This reduces the number of computations needed for modifying the balances of N users from O(n) to O(1).

 * Note: Notice how users are tracked by a generic bytes32 id instead of an address. This allows the actors of the mapping not just to be addresses. They can be anything, for example a pool id, an account id, etc.
 *
 * *********************
 * Conceptual Examples
 * *********************
 *
 * 1) Socialization of collateral during a liquidation.
 *
 * Scalable mappings are very useful for "socialization" of collateral, that is, the re-distribution of collateral when an account is liquidated. Suppose 1000 ETH are liquidated, and would need to be distributed amongst 1000 stakers. With a regular mapping, every staker's balance would have to be modified in a loop that iterates through every single one of them. With a scalable mapping, the scalar would simply need to be incremented so that the total value of the mapping increases by 1000 ETH.
 *
 * 2) Socialization of debt during a liquidation.
 *
 * Similar to the socialization of collateral during a liquidation, the debt of the position that is being liquidated can be re-allocated using a scalable mapping with a single action. Supposing a scalable mapping tracks each user's debt in the system, and that 1000 sUSD has to be distributed amongst 1000 stakers, the debt data structure's scalar would simply need to be incremented so that the total value or debt of the distribution increments by 1000 sUSD.
 *
 */
library ScalableMapping {
    using SafeCastU128 for uint128;
    using SafeCastU256 for uint256;
    using SafeCastI128 for int128;
    using SafeCastI256 for int256;
    using DecimalMath for int256;
    using DecimalMath for uint256;

    error InsufficientMappedAmount(int scaleModifier);

    struct Data {
        uint128 totalSharesD18;
        int128 scaleModifierD27;
        mapping(bytes32 => uint) sharesD18;
    }

    /**
     * @dev Inflates or deflates the total value of the distribution by the given value.
     *
     * The value being distributed ultimately modifies the distribution's scaleModifier.
     */
    function scale(Data storage self, int valueD18) internal {
        if (valueD18 == 0) {
            return;
        }

        uint totalSharesD18 = self.totalSharesD18;

        int valueD45 = valueD18 * DecimalMath.UNIT_PRECISE_INT;
        int deltaScaleModifierD27 = valueD45 / totalSharesD18.toInt();

        self.scaleModifierD27 += deltaScaleModifierD27.to128();

        if (self.scaleModifierD27 < -DecimalMath.UNIT_PRECISE_INT) {
            revert InsufficientMappedAmount(-self.scaleModifierD27);
        }
    }

    /**
     * @dev Updates an actor's individual value in the distribution to the specified amount.
     *
     * The change in value is manifested in the distribution by changing the actor's number of shares in it, and thus the distribution's total number of shares.
     *
     * Returns the resulting amount of shares that the actor has after this change in value.
     */
    function set(
        Data storage self,
        bytes32 actorId,
        uint newActorValueD18
    ) internal returns (uint resultingSharesD18) {
        // Represent the actor's change in value by changing the actor's number of shares,
        // and keeping the distribution's scaleModifier constant.

        resultingSharesD18 = _getSharesForAmount(self, newActorValueD18);

        // Modify the total shares with the actor's change in shares.
        self.totalSharesD18 = (self.totalSharesD18 + resultingSharesD18 - self.sharesD18[actorId]).to128();

        self.sharesD18[actorId] = resultingSharesD18.to128();
    }

    /**
     * @dev Returns the value owned by the actor in the distribution.
     *
     * i.e. actor.shares * scaleModifier
     */
    function get(Data storage self, bytes32 actorId) internal view returns (uint valueD18) {
        uint totalSharesD18 = self.totalSharesD18;
        if (self.totalSharesD18 == 0) {
            return 0;
        }

        return (self.sharesD18[actorId] * totalAmount(self)) / totalSharesD18;
    }

    /**
     * @dev Returns the total value held in the distribution.
     *
     * i.e. totalShares * scaleModifier
     */
    function totalAmount(Data storage self) internal view returns (uint valueD18) {
        return
            ((self.scaleModifierD27 + DecimalMath.UNIT_PRECISE_INT).toUint() * self.totalSharesD18) /
            DecimalMath.UNIT_PRECISE;
    }

    function _getSharesForAmount(Data storage self, uint amountD18) private view returns (uint sharesD18) {
        sharesD18 =
            (amountD18 * DecimalMath.UNIT_PRECISE) /
            (self.scaleModifierD27 + DecimalMath.UNIT_PRECISE_INT128).toUint();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@synthetixio/core-contracts/contracts/utils/SetUtil.sol";

/**
 * @title System wide configuration for pools.
 */
library SystemPoolConfiguration {
    struct Data {
        /**
         * @dev Owner specified system-wide limiting factor that prevents markets from minting too much debt, similar to the issuance ratio to a collateral type.
         *
         * Note: If zero, then this value defaults to 100%.
         */
        uint minLiquidityRatioD18;
        /**
         * @dev Id of the main pool set by the system owner.
         */
        uint preferredPool;
        /**
         * @dev List of pools approved by the system owner.
         */
        SetUtil.UintSet approvedPools;
    }

    /**
     * @dev Returns the configuration singleton.
     */
    function load() internal pure returns (Data storage data) {
        bytes32 s = keccak256(abi.encode("PoolConfiguration"));
        assembly {
            data.slot := s
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./VaultEpoch.sol";
import "./RewardDistribution.sol";

import "./CollateralConfiguration.sol";

import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

/**
 * @title Tracks collateral and debt distributions in a pool, for a specific collateral type.
 *
 * I.e. if a pool supports SNX and ETH collaterals, it will have an SNX Vault, and an ETH Vault.
 *
 * The Vault data structure is itself split into VaultEpoch sub-structures. This facilitates liquidations,
 * so that whenever one occurs, a clean state of all data is achieved by simply incrementing the epoch index.
 *
 * It is recommended to understand VaultEpoch before understanding this object.
 */
library Vault {
    using VaultEpoch for VaultEpoch.Data;
    using Distribution for Distribution.Data;
    using DistributionEntry for DistributionEntry.Data;
    using ScalableMapping for ScalableMapping.Data;
    using DecimalMath for uint256;
    using DecimalMath for int128;
    using DecimalMath for int256;
    using SafeCastU128 for uint128;
    using SafeCastU256 for uint256;
    using SafeCastI128 for int128;
    using SafeCastI256 for int256;
    using SetUtil for SetUtil.Bytes32Set;

    struct Data {
        /**
         * @dev The vault's current epoch number.
         *
         * Vault data is divided into epochs. An epoch changes when an entire vault is liquidated.
         */
        uint epoch;
        /**
         * @dev Unused property, maintained for backwards compatibility in storage layout.
         */
        // solhint-disable-next-line private-vars-leading-underscore
        uint128 __slotAvailableForFutureUse;
        /**
         * @dev The previous debt of the vault, when `updateCreditCapacity` was last called by the Pool.
         */
        int128 prevTotalDebtD18;
        /**
         * @dev Vault data for all the liquidation cycles divided into epochs.
         */
        mapping(uint => VaultEpoch.Data) epochData;
        /**
         * @dev Tracks available rewards, per user, for this vault.
         */
        mapping(bytes32 => RewardDistribution.Data) rewards;
        /**
         * @dev Tracks reward, ids, for this vault.
         */
        SetUtil.Bytes32Set rewardIds;
    }

    /**
     * @dev Return's the VaultEpoch data for the current epoch.
     */
    function currentEpoch(Data storage self) internal view returns (VaultEpoch.Data storage) {
        return self.epochData[self.epoch];
    }

    /**
     * @dev Updates the vault's credit capacity as the value of its collateral minus its debt.
     *
     * Called as a ticker when users interact with pools, allowing pools to set
     * vaults' credit capacity shares within the them.
     *
     * Returns the amount of collateral that this vault is providing in net USD terms.
     */
    function updateCreditCapacity(Data storage self, uint collateralPriceD18)
        internal
        returns (
            uint usdWeightD18,
            int totalDebtD18,
            int deltaDebtD18
        )
    {
        VaultEpoch.Data storage epochData = currentEpoch(self);

        uint scaleModifier = (epochData.collateralAmounts.scaleModifierD27 + int(DecimalMath.UNIT_PRECISE)).toUint();
        usdWeightD18 = ((uint(epochData.accountsDebtDistribution.totalSharesD18) * scaleModifier) / 1e27).mulDecimal(
            collateralPriceD18
        );

        totalDebtD18 = epochData.totalDebt();

        deltaDebtD18 = totalDebtD18 - self.prevTotalDebtD18;

        self.prevTotalDebtD18 = totalDebtD18.to128();
    }

    /**
     * @dev Updated the value per share of the current epoch's incoming debt distribution.
     */
    function distributeDebtToAccounts(Data storage self, int debtChangeD18) internal {
        currentEpoch(self).distributeDebtToAccounts(debtChangeD18);
    }

    /**
     * @dev Consolidates an accounts debt.
     */
    function consolidateAccountDebt(Data storage self, uint128 accountId) internal returns (int) {
        return currentEpoch(self).consolidateAccountDebt(accountId);
    }

    /**
     * @dev Traverses available rewards for this vault, and updates an accounts
     * claim on them according to the amount of debt shares they have.
     */
    function updateRewards(Data storage self, uint128 accountId) internal returns (uint[] memory, address[] memory) {
        uint[] memory rewards = new uint[](self.rewardIds.length());
        address[] memory distributors = new address[](self.rewardIds.length());
        for (uint i = 0; i < self.rewardIds.length(); i++) {
            RewardDistribution.Data storage dist = self.rewards[self.rewardIds.valueAt(i + 1)];

            if (address(dist.distributor) == address(0)) {
                continue;
            }

            rewards[i] = updateReward(self, accountId, self.rewardIds.valueAt(i + 1));
            distributors[i] = address(dist.distributor);
        }

        return (rewards, distributors);
    }

    /**
     * @dev Traverses available rewards for this vault and the reward id, and updates an accounts
     * claim on them according to the amount of debt shares they have.
     */
    function updateReward(
        Data storage self,
        uint128 accountId,
        bytes32 rewardId
    ) internal returns (uint) {
        uint totalSharesD18 = currentEpoch(self).accountsDebtDistribution.totalSharesD18;
        uint actorSharesD18 = currentEpoch(self).accountsDebtDistribution.getActorShares(bytes32(uint(accountId)));

        RewardDistribution.Data storage dist = self.rewards[rewardId];

        if (address(dist.distributor) == address(0)) {
            revert("No distributor");
        }

        dist.rewardPerShareD18 += dist.entry.updateEntry(totalSharesD18).toUint().to128();

        dist.actorInfo[accountId].pendingSendD18 += actorSharesD18
            .mulDecimal(dist.rewardPerShareD18 - dist.actorInfo[accountId].lastRewardPerShareD18)
            .to128();

        dist.actorInfo[accountId].lastRewardPerShareD18 = dist.rewardPerShareD18;

        return dist.actorInfo[accountId].pendingSendD18;
    }

    /**
     * @dev Increments the current epoch index, effectively producing a
     * completely blank new VaultEpoch data structure in the vault.
     */
    function reset(Data storage self) internal {
        self.epoch++;
    }

    /**
     * @dev Returns the vault's combined debt (consolidated and unconsolidated),
     * for the current epoch.
     */
    function currentDebt(Data storage self) internal view returns (int) {
        return currentEpoch(self).totalDebt();
    }

    /**
     * @dev Returns the total value in the Vault's collateral distribution, for the current epoch.
     */
    function currentCollateral(Data storage self) internal view returns (uint) {
        return currentEpoch(self).collateralAmounts.totalAmount();
    }

    /**
     * @dev Returns an account's collateral value in this vault's current epoch.
     */
    function currentAccountCollateral(Data storage self, uint128 accountId) internal view returns (uint) {
        return currentEpoch(self).getAccountCollateral(accountId);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Distribution.sol";
import "./ScalableMapping.sol";

import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

/**
 * @title Tracks collateral and debt distributions in a pool, for a specific collateral type, in a given epoch.
 *
 * Collateral is tracked with a distribution as opposed to a regular mapping because liquidations cause collateral to be socialized. If collateral was tracked using a regular mapping, such socialization would be difficult and require looping through individual balances, or some other sort of complex and expensive mechanism. Distributions make socialization easy.
 *
 * Debt is also tracked in a distribution for the same reason, but it is additionally split in two distributions: incoming and consolidated debt.
 *
 * Incoming debt is modified when a liquidations occurs.
 * Consolidated debt is updated when users interact with the system.
 */
library VaultEpoch {
    using Distribution for Distribution.Data;
    using DecimalMath for uint256;
    using SafeCastU128 for uint128;
    using SafeCastU256 for uint256;
    using SafeCastI128 for int128;
    using SafeCastI256 for int256;

    using ScalableMapping for ScalableMapping.Data;

    struct Data {
        /**
         * @dev Amount of debt in this Vault that is yet to be consolidated.
         *
         * E.g. when a given amount of debt is socialized during a liquidation, but it yet hasn't been rolled into
         * the consolidated debt distribution.
         */
        int128 unconsolidatedDebtD18;
        /**
         * @dev Amount of debt in this Vault that has been consolidated.
         */
        int128 totalConsolidatedDebtD18;
        /**
         * @dev Tracks incoming debt for each user.
         *
         * The value of shares in this distribution change as the associate market changes, i.e. price changes in an asset in
         * a spot market.
         *
         * Also, when debt is socialized in a liquidation, it is done onto this distribution. As users
         * interact with the system, their independent debt is consolidated or rolled into consolidatedDebtDist.
         */
        Distribution.Data accountsDebtDistribution;
        /**
         * @dev Tracks collateral delegated to this vault, for each user.
         *
         * Uses a distribution instead of a regular market because of the way collateral is socialized during liquidations.
         *
         * A regular mapping would require looping over the mapping of each account's collateral, or moving the liquidated
         * collateral into a place where it could later be claimed. With a distribution, liquidated collateral can be
         * socialized very easily.
         */
        ScalableMapping.Data collateralAmounts;
        /**
         * @dev Tracks consolidated debt for each user.
         *
         * Updated when users interact with the system, consolidating changes from the fluctuating accountsDebtDistribution,
         * and directly when users mint or burn USD, or repay debt.
         */
        mapping(uint => int) consolidatedDebtAmountsD18;
    }

    /**
     * @dev Updates the value per share of the incoming debt distribution.
     * Used for socialization during liquidations, and to bake in market changes.
     *
     * Called from:
     * - LiquidationModule.liquidate
     * - Pool.recalculateVaultCollateral (ticker)
     */
    function distributeDebtToAccounts(Data storage self, int debtChangeD18) internal {
        self.accountsDebtDistribution.distributeValue(debtChangeD18);

        // Cache total debt here.
        // Will roll over to individual users as they interact with the system.
        self.unconsolidatedDebtD18 += debtChangeD18.to128();
    }

    function assignDebtToAccount(
        Data storage self,
        uint128 accountId,
        int amountD18
    ) internal returns (int newDebtD18) {
        int currentDebtD18 = self.consolidatedDebtAmountsD18[accountId];
        self.consolidatedDebtAmountsD18[accountId] += amountD18.to128();
        self.totalConsolidatedDebtD18 += amountD18.to128();
        return currentDebtD18 + amountD18;
    }

    /**
     * @dev Consolidates user debt as they interact with the system.
     *
     * Fluctuating debt is moved from incoming to consolidated debt.
     *
     * Called as a ticker from various parts of the system, usually whenever the
     * real debt of a user needs to be known.
     */
    function consolidateAccountDebt(Data storage self, uint128 accountId) internal returns (int currentDebtD18) {
        bytes32 actorId = bytes32(uint(accountId));

        int newDebtD18 = self.accountsDebtDistribution.accumulateActor(actorId);

        currentDebtD18 = assignDebtToAccount(self, accountId, newDebtD18);
        self.unconsolidatedDebtD18 -= newDebtD18.to128();
    }

    /**
     * @dev Updates a user's collateral value, and sets their exposure to debt
     * according to the collateral they delegated and the leverage used.
     *
     * Called whenever a user's collateral changes.
     */
    function updateAccountPosition(
        Data storage self,
        uint128 accountId,
        uint collateralAmountD18,
        uint leverageD18
    ) internal {
        bytes32 actorId = bytes32(uint(accountId));

        // Ensure account debt is consolidated before we do next things.
        consolidateAccountDebt(self, accountId);

        self.collateralAmounts.set(actorId, collateralAmountD18);
        self.accountsDebtDistribution.setActorShares(
            actorId,
            self.collateralAmounts.sharesD18[actorId].mulDecimal(leverageD18)
        );
    }

    /**
     * @dev Returns the vault's total debt in this epoch, including the debt
     * that hasn't yet been consolidated into individual accounts.
     */
    function totalDebt(Data storage self) internal view returns (int) {
        return self.unconsolidatedDebtD18 + self.totalConsolidatedDebtD18;
    }

    /**
     * @dev Returns an account's value in the Vault's collateral distribution.
     */
    function getAccountCollateral(Data storage self, uint128 accountId) internal view returns (uint amountD18) {
        return self.collateralAmounts.get(bytes32(uint(accountId)));
    }
}