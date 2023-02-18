//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Library for access related errors.
 */
library AccessError {
    /**
     * @dev Thrown when an address tries to perform an unauthorized action.
     * @param addr The address that attempts the action.
     */
    error Unauthorized(address addr);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Library for errors related with expected function parameters.
 */
library ParameterError {
    /**
     * @dev Thrown when an invalid parameter is used in a function.
     * @param parameter The name of the parameter.
     * @param reason The reason why the received parameter is invalid.
     */
    error InvalidParameter(string parameter, string reason);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title ERC165 interface for determining if a contract supports a given interface.
 */
interface IERC165 {
    /**
     * @notice Determines if the contract in question supports the specified interface.
     * @param interfaceID XOR of all selectors in the contract.
     * @return True if the contract supports the specified interface.
     */
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title ERC20 token implementation.
 */
interface IERC20 {
    /**
     * @notice Emitted when tokens have been transferred.
     * @param from The address that originally owned the tokens.
     * @param to The address that received the tokens.
     * @param amount The number of tokens that were transferred.
     */
    event Transfer(address indexed from, address indexed to, uint amount);

    /**
     * @notice Emitted when a user has provided allowance to another user for transferring tokens on its behalf.
     * @param owner The address that is providing the allowance.
     * @param spender The address that received the allowance.
     * @param amount The number of tokens that were added to `spender`'s allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint amount);

    /**
     * @notice Thrown when the address interacting with the contract does not have sufficient allowance to transfer tokens from another contract.
     * @param required The necessary allowance.
     * @param existing The current allowance.
     */
    error InsufficientAllowance(uint required, uint existing);

    /**
     * @notice Thrown when the address interacting with the contract does not have sufficient tokens.
     * @param required The necessary balance.
     * @param existing The current balance.
     */
    error InsufficientBalance(uint required, uint existing);

    /**
     * @notice Retrieves the name of the token, e.g. "Synthetix Network Token".
     * @return A string with the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @notice Retrieves the symbol of the token, e.g. "SNX".
     * @return A string with the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @notice Retrieves the number of decimals used by the token. The default is 18.
     * @return The number of decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @notice Returns the total number of tokens in circulation (minted - burnt).
     * @return The total number of tokens.
     */
    function totalSupply() external view returns (uint);

    /**
     * @notice Returns the balance of a user.
     * @param owner The address whose balance is being retrieved.
     * @return The number of tokens owned by the user.
     */
    function balanceOf(address owner) external view returns (uint);

    /**
     * @notice Returns how many tokens a user has allowed another user to transfer on its behalf.
     * @param owner The user who has given the allowance.
     * @param spender The user who was given the allowance.
     * @return The amount of tokens `spender` can transfer on `owner`'s behalf.
     */
    function allowance(address owner, address spender) external view returns (uint);

    /**
     * @notice Transfer tokens from one address to another.
     * @param to The address that will receive the tokens.
     * @param amount The amount of tokens to be transferred.
     * @return A boolean which is true if the operation succeeded.
     */
    function transfer(address to, uint amount) external returns (bool);

    /**
     * @notice Allows users to provide allowance to other users so that they can transfer tokens on their behalf.
     * @param spender The address that is receiving the allowance.
     * @param amount The amount of tokens that are being added to the allowance.
     * @return A boolean which is true if the operation succeeded.
     */
    function approve(address spender, uint amount) external returns (bool);

    /**
     * @notice Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    /**
     * @notice Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    /**
     * @notice Allows a user who has been given allowance to transfer tokens on another user's behalf.
     * @param from The address that owns the tokens that are being transferred.
     * @param to The address that will receive the tokens.
     * @param amount The number of tokens to transfer.
     * @return A boolean which is true if the operation succeeded.
     */
    function transferFrom(address from, address to, uint amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title ERC721 non-fungible token (NFT) contract.
 */
interface IERC721 {
    /**
     * @notice Thrown when an address attempts to provide allowance to itself.
     * @param addr The address attempting to provide allowance.
     */
    error CannotSelfApprove(address addr);

    /**
     * @notice Thrown when attempting to transfer a token to an address that does not satisfy IERC721Receiver requirements.
     * @param addr The address that cannot receive the tokens.
     */
    error InvalidTransferRecipient(address addr);

    /**
     * @notice Thrown when attempting to specify an owner which is not valid (ex. the 0x00000... address)
     */
    error InvalidOwner(address addr);

    /**
     * @notice Thrown when attempting to operate on a token id that does not exist.
     * @param id The token id that does not exist.
     */
    error TokenDoesNotExist(uint256 id);

    /**
     * @notice Thrown when attempting to mint a token that already exists.
     * @param id The token id that already exists.
     */
    error TokenAlreadyMinted(uint256 id);

    /**
     * @notice Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @notice Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @notice Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @notice Returns the number of tokens in ``owner``'s account.
     *
     * Requirements:
     *
     * - `owner` must be a valid address
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @notice Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @notice Safely transfers `tokenId` token from `from` to `to`.
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
     * @notice Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @notice Transfers `tokenId` token from `from` to `to`.
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
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @notice Gives permission to `to` to transfer `tokenId` token to another account.
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
     * @notice Approve or remove `operator` as an operator for the caller.
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
     * @notice Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @notice Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./IERC721.sol";

/**
 * @title ERC721 extension with helper functions that allow the enumeration of NFT tokens.
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @notice Thrown calling *ByIndex function with an index greater than the number of tokens existing
     * @param requestedIndex The index requested by the caller
     * @param length The length of the list that is being iterated, making the max index queryable length - 1
     */
    error IndexOverrun(uint requestedIndex, uint length);

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     *
     * Requirements:
     * - `owner` must be a valid address
     * - `index` must be less than the balance of the tokens for the owner
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     *
     * Requirements:
     * - `index` must be less than the total supply of the tokens
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./SafeCast.sol";

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
    using SafeCastU256 for uint256;
    using SafeCastI256 for int256;

    // solhint-disable numcast/safe-cast

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

    // solhint-enable numcast/safe-cast

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
        return x * 10 ** factor;
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
        return x / 10 ** factor;
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
        return x * (10 ** factor).to128();
    }

    /**
     * @dev See downscale for uint256.
     */
    function downscaleUint128(uint128 x, uint factor) internal pure returns (uint128) {
        return x / (10 ** factor).to128();
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
        return x * (10 ** factor).toInt();
    }

    /**
     * @dev See downscale for uint256.
     */
    function downscale(int x, uint factor) internal pure returns (int) {
        return x / (10 ** factor).toInt();
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
        return x * ((10 ** factor).toInt()).to128();
    }

    /**
     * @dev See downscale for uint256.
     */
    function downscaleInt128(int128 x, uint factor) internal pure returns (int128) {
        return x / ((10 ** factor).toInt().to128());
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../interfaces/IERC165.sol";

library ERC165Helper {
    function safeSupportsInterface(
        address candidate,
        bytes4 interfaceID
    ) internal returns (bool supportsInterface) {
        (bool success, bytes memory response) = candidate.call(
            abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceID)
        );

        if (!success) {
            return false;
        }

        if (response.length == 0) {
            return false;
        }

        assembly {
            supportsInterface := mload(add(response, 32))
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

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

    function insert(Data storage self, uint128 id, int128 priority) internal returns (Node memory) {
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

    function _bubbleUp(Data storage self, Node memory n, uint i) private {
        //√
        if (i == _ROOT_INDEX || n.priority <= self.nodes[i / 2].priority) {
            _insert(self, n, i);
        } else {
            _insert(self, self.nodes[i / 2], i);
            _bubbleUp(self, n, i / 2);
        }
    }

    function _bubbleDown(Data storage self, Node memory n, uint i) private {
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

    function _insert(Data storage self, Node memory n, uint i) private {
        //√
        self.nodes[i] = n;
        self.indices[n.id] = i;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * Utilities that convert numeric types avoiding silent overflows.
 */
import "./SafeCast/SafeCastU32.sol";
import "./SafeCast/SafeCastI32.sol";
import "./SafeCast/SafeCastI24.sol";
import "./SafeCast/SafeCastU56.sol";
import "./SafeCast/SafeCastI56.sol";
import "./SafeCast/SafeCastU64.sol";
import "./SafeCast/SafeCastI128.sol";
import "./SafeCast/SafeCastI256.sol";
import "./SafeCast/SafeCastU128.sol";
import "./SafeCast/SafeCastU160.sol";
import "./SafeCast/SafeCastU256.sol";
import "./SafeCast/SafeCastAddress.sol";
import "./SafeCast/SafeCastBytes32.sol";

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastAddress {
    function toBytes32(address x) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(x)));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastBytes32 {
    function toAddress(bytes32 x) internal pure returns (address) {
        return address(uint160(uint256(x)));
    }

    function toUint(bytes32 x) internal pure returns (uint) {
        return uint(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastI128 {
    error OverflowInt128ToUint128();
    error OverflowInt128ToInt32();

    function toUint(int128 x) internal pure returns (uint128) {
        // ----------------<==============o==============>-----------------
        // ----------------xxxxxxxxxxxxxxxo===============>----------------
        if (x < 0) {
            revert OverflowInt128ToUint128();
        }

        return uint128(x);
    }

    function to256(int128 x) internal pure returns (int256) {
        return int256(x);
    }

    function to32(int128 x) internal pure returns (int32) {
        // ----------------<==============o==============>-----------------
        // ----------------xxxxxxxxxxxx<==o==>xxxxxxxxxxxx-----------------
        if (x < int(type(int32).min) || x > int(type(int32).max)) {
            revert OverflowInt128ToInt32();
        }

        return int32(x);
    }

    function zero() internal pure returns (int128) {
        return int128(0);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastI24 {
    function to256(int24 x) internal pure returns (int256) {
        return int256(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastI256 {
    error OverflowInt256ToUint256();
    error OverflowInt256ToInt128();
    error OverflowInt256ToInt24();

    function to128(int256 x) internal pure returns (int128) {
        // ----<==========================o===========================>----
        // ----xxxxxxxxxxxx<==============o==============>xxxxxxxxxxxxx----
        if (x < int256(type(int128).min) || x > int256(type(int128).max)) {
            revert OverflowInt256ToInt128();
        }

        return int128(x);
    }

    function to24(int256 x) internal pure returns (int24) {
        // ----<==========================o===========================>----
        // ----xxxxxxxxxxxxxxxxxxxx<======o=======>xxxxxxxxxxxxxxxxxxxx----
        if (x < int256(type(int24).min) || x > int256(type(int24).max)) {
            revert OverflowInt256ToInt24();
        }

        return int24(x);
    }

    function toUint(int256 x) internal pure returns (uint256) {
        // ----<==========================o===========================>----
        // ----xxxxxxxxxxxxxxxxxxxxxxxxxxxo===============================>
        if (x < 0) {
            revert OverflowInt256ToUint256();
        }

        return uint256(x);
    }

    function zero() internal pure returns (int256) {
        return int256(0);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastI32 {
    error OverflowInt32ToUint32();

    function toUint(int32 x) internal pure returns (uint32) {
        // ----------------------<========o========>----------------------
        // ----------------------xxxxxxxxxo=========>----------------------
        if (x < 0) {
            revert OverflowInt32ToUint32();
        }

        return uint32(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastI56 {
    error OverflowInt56ToInt24();

    function to24(int56 x) internal pure returns (int24) {
        // ----------------------<========o========>-----------------------
        // ----------------------xxx<=====o=====>xxx-----------------------
        if (x < int(type(int24).min) || x > int(type(int24).max)) {
            revert OverflowInt56ToInt24();
        }

        return int24(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastU128 {
    error OverflowUint128ToInt128();

    function to256(uint128 x) internal pure returns (uint256) {
        return uint256(x);
    }

    function toInt(uint128 x) internal pure returns (int128) {
        // -------------------------------o===============>----------------
        // ----------------<==============o==============>x----------------
        if (x > uint128(type(int128).max)) {
            revert OverflowUint128ToInt128();
        }

        return int128(x);
    }

    function toBytes32(uint128 x) internal pure returns (bytes32) {
        return bytes32(uint256(x));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastU160 {
    function to256(uint160 x) internal pure returns (uint256) {
        return uint256(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastU256 {
    error OverflowUint256ToUint128();
    error OverflowUint256ToInt256();
    error OverflowUint256ToUint64();
    error OverflowUint256ToUint32();
    error OverflowUint256ToUint160();

    function to128(uint256 x) internal pure returns (uint128) {
        // -------------------------------o===============================>
        // -------------------------------o===============>xxxxxxxxxxxxxxxx
        if (x > type(uint128).max) {
            revert OverflowUint256ToUint128();
        }

        return uint128(x);
    }

    function to64(uint256 x) internal pure returns (uint64) {
        // -------------------------------o===============================>
        // -------------------------------o======>xxxxxxxxxxxxxxxxxxxxxxxxx
        if (x > type(uint64).max) {
            revert OverflowUint256ToUint64();
        }

        return uint64(x);
    }

    function to32(uint256 x) internal pure returns (uint32) {
        // -------------------------------o===============================>
        // -------------------------------o===>xxxxxxxxxxxxxxxxxxxxxxxxxxxx
        if (x > type(uint32).max) {
            revert OverflowUint256ToUint32();
        }

        return uint32(x);
    }

    function to160(uint256 x) internal pure returns (uint160) {
        // -------------------------------o===============================>
        // -------------------------------o==================>xxxxxxxxxxxxx
        if (x > type(uint160).max) {
            revert OverflowUint256ToUint160();
        }

        return uint160(x);
    }

    function toBytes32(uint256 x) internal pure returns (bytes32) {
        return bytes32(x);
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
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastU32 {
    error OverflowUint32ToInt32();

    function toInt(uint32 x) internal pure returns (int32) {
        // -------------------------------o=========>----------------------
        // ----------------------<========o========>x----------------------
        if (x > uint32(type(int32).max)) {
            revert OverflowUint32ToInt32();
        }

        return int32(x);
    }

    function to256(uint32 x) internal pure returns (uint256) {
        return uint256(x);
    }

    function to56(uint32 x) internal pure returns (uint56) {
        return uint56(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastU56 {
    error OverflowUint56ToInt56();

    function toInt(uint56 x) internal pure returns (int56) {
        // -------------------------------o=========>----------------------
        // ----------------------<========o========>x----------------------
        if (x > uint56(type(int56).max)) {
            revert OverflowUint56ToInt56();
        }

        return int56(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastU64 {
    error OverflowUint64ToInt64();

    function toInt(uint64 x) internal pure returns (int64) {
        // -------------------------------o=========>----------------------
        // ----------------------<========o========>x----------------------
        if (x > uint64(type(int64).max)) {
            revert OverflowUint64ToInt64();
        }

        return int64(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./SafeCast.sol";

library SetUtil {
    using SafeCastAddress for address;
    using SafeCastBytes32 for bytes32;
    using SafeCastU256 for uint256;

    // ----------------------------------------
    // Uint support
    // ----------------------------------------

    struct UintSet {
        Bytes32Set raw;
    }

    function add(UintSet storage set, uint value) internal {
        add(set.raw, value.toBytes32());
    }

    function remove(UintSet storage set, uint value) internal {
        remove(set.raw, value.toBytes32());
    }

    function replace(UintSet storage set, uint value, uint newValue) internal {
        replace(set.raw, value.toBytes32(), newValue.toBytes32());
    }

    function contains(UintSet storage set, uint value) internal view returns (bool) {
        return contains(set.raw, value.toBytes32());
    }

    function length(UintSet storage set) internal view returns (uint) {
        return length(set.raw);
    }

    function valueAt(UintSet storage set, uint position) internal view returns (uint) {
        return valueAt(set.raw, position).toUint();
    }

    function positionOf(UintSet storage set, uint value) internal view returns (uint) {
        return positionOf(set.raw, value.toBytes32());
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
        add(set.raw, value.toBytes32());
    }

    function remove(AddressSet storage set, address value) internal {
        remove(set.raw, value.toBytes32());
    }

    function replace(AddressSet storage set, address value, address newValue) internal {
        replace(set.raw, value.toBytes32(), newValue.toBytes32());
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return contains(set.raw, value.toBytes32());
    }

    function length(AddressSet storage set) internal view returns (uint) {
        return length(set.raw);
    }

    function valueAt(AddressSet storage set, uint position) internal view returns (address) {
        return valueAt(set.raw, position).toAddress();
    }

    function positionOf(AddressSet storage set, address value) internal view returns (uint) {
        return positionOf(set.raw, value.toBytes32());
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

    function replace(Bytes32Set storage set, bytes32 value, bytes32 newValue) internal {
        if (!contains(set, value)) {
            revert ValueNotInSet();
        }

        if (contains(set, newValue)) {
            revert ValueAlreadyInSet();
        }

        uint position = set._positions[value];
        delete set._positions[value];

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
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/interfaces/IERC721Enumerable.sol";

/**
 * @title Module wrapping an ERC721 token implementation.
 */
interface INftModule is IERC721Enumerable {
    /**
     * @notice Returns wether the token has been initialized.
     * @return A boolean with the result of the query.
     */
    function isInitialized() external returns (bool);

    /**
     * @notice Initializes the token with name, symbol, and uri.
     */
    function initialize(
        string memory tokenName,
        string memory tokenSymbol,
        string memory uri
    ) external;

    /**
     * @notice Allows the owner to mint tokens.
     * @param to The address to receive the newly minted tokens.
     * @param tokenId The ID of the newly minted token
     */
    function mint(address to, uint tokenId) external;

    /**
     * @notice Allows the owner to mint tokens. Verifies that the receiver can receive the token
     * @param to The address to receive the newly minted token.
     * @param tokenId The ID of the newly minted token
     * @param data any data which should be sent to the receiver
     */
    function safeMint(address to, uint256 tokenId, bytes memory data) external;

    /**
     * @notice Allows the owner to burn tokens.
     * @param tokenId The token to burn
     */
    function burn(uint tokenId) external;

    /**
     * @notice Allows an address that holds tokens to provide allowance to another.
     * @param tokenId The token which should be allowed to spender
     * @param spender The address that is given allowance.
     */
    function setAllowance(uint tokenId, address spender) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/interfaces/IERC20.sol";

/**
 * @title Module wrapping an ERC20 token implementation.
 */
interface ITokenModule is IERC20 {
    /**
     * @notice Returns wether the token has been initialized.
     * @return A boolean with the result of the query.
     */
    function isInitialized() external returns (bool);

    /**
     * @notice Initializes the token with name, symbol, and decimals.
     */
    function initialize(
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals
    ) external;

    /**
     * @notice Allows the owner to mint tokens.
     * @param to The address to receive the newly minted tokens.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint amount) external;

    /**
     * @notice Allows the owner to burn tokens.
     * @param to The address whose tokens will be burnt.
     * @param amount The amount of tokens to burn.
     */
    function burn(address to, uint amount) external;

    /**
     * @notice Allows an address that holds tokens to provide allowance to another.
     * @param from The address that is providing allowance.
     * @param spender The address that is given allowance.
     * @param amount The amount of allowance being given.
     */
    function setAllowance(address from, address spender, uint amount) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../interfaces/ITokenModule.sol";
import "../interfaces/INftModule.sol";

library AssociatedSystem {
    struct Data {
        address proxy;
        address impl;
        bytes32 kind;
    }

    error MismatchAssociatedSystemKind(bytes32 expected, bytes32 actual);

    function load(bytes32 id) internal pure returns (Data storage store) {
        bytes32 s = keccak256(abi.encode("io.synthetix.core-modules.AssociatedSystem", id));
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

    function set(Data storage self, address proxy, address impl, bytes32 kind) internal {
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
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/utils/SetUtil.sol";

library FeatureFlag {
    using SetUtil for SetUtil.AddressSet;

    error FeatureUnavailable(bytes32 which);

    struct Data {
        bytes32 name;
        bool allowAll;
        bool denyAll;
        SetUtil.AddressSet permissionedAddresses;
        address[] deniers;
    }

    function load(bytes32 featureName) internal pure returns (Data storage store) {
        bytes32 s = keccak256(abi.encode("io.synthetix.core-modules.FeatureFlag", featureName));
        assembly {
            store.slot := s
        }
    }

    function ensureAccessToFeature(bytes32 feature) internal view {
        if (!hasAccess(feature, msg.sender)) {
            revert FeatureUnavailable(feature);
        }
    }

    function hasAccess(bytes32 feature, address value) internal view returns (bool) {
        Data storage store = FeatureFlag.load(feature);

        if (store.denyAll) {
            return false;
        }

        return store.allowAll || store.permissionedAddresses.contains(value);
    }

    function isDenier(Data storage self, address possibleDenier) internal view returns (bool) {
        for (uint i = 0; i < self.deniers.length; i++) {
            if (self.deniers[i] == possibleDenier) {
                return true;
            }
        }

        return false;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../storage/NodeOutput.sol";
import "../storage/NodeDefinition.sol";

/// @title Module for managing nodes
interface INodeModule {
    /**
     * @notice Thrown when the specified nodeId has not been registered in the system.
     */
    error NodeNotRegistered(bytes32 nodeId);

    /**
     * @notice Thrown when a node is registered without a valid definition.
     */
    error InvalidNodeDefinition(NodeDefinition.Data nodeType);

    /**
     * @notice Thrown when a node cannot be processed
     */
    error UnprocessableNode(bytes32 nodeId);

    /**
     * @notice Thrown when a node is registered with an invalid external node
     */
    error IncorrectExternalNodeInterface(address externalNode);

    /**
     * @notice Emitted when `registerNode` is called.
     * @param nodeId The id of the registered node.
     * @param nodeType The nodeType assigned to this node.
     * @param parameters The parameters assigned to this node.
     * @param parents The parents assigned to this node.
     */
    event NodeRegistered(
        bytes32 nodeId,
        NodeDefinition.NodeType nodeType,
        bytes parameters,
        bytes32[] parents
    );

    /**
     * @notice Registers a node
     * @param nodeType The nodeType assigned to this node.
     * @param parameters The parameters assigned to this node.
     * @param parents The parents assigned to this node.
     * @return The id of the registered node.
     */
    function registerNode(
        NodeDefinition.NodeType nodeType,
        bytes memory parameters,
        bytes32[] memory parents
    ) external returns (bytes32);

    /**
     * @notice Returns the ID of a node, whether or not it has been registered.
     * @param parents The parents assigned to this node.
     * @param nodeType The nodeType assigned to this node.
     * @param parameters The parameters assigned to this node.
     * @return The id of the node.
     */
    function getNodeId(
        NodeDefinition.NodeType nodeType,
        bytes memory parameters,
        bytes32[] memory parents
    ) external returns (bytes32);

    /**
     * @notice Returns a node's definition (type, parameters, and parents)
     * @param nodeId The node ID
     * @return The node's definition data
     */
    function getNode(bytes32 nodeId) external view returns (NodeDefinition.Data memory);

    /**
     * @notice Returns a node current output data
     * @param nodeId The node ID
     * @return The node's output data
     */
    function process(bytes32 nodeId) external view returns (NodeOutput.Data memory);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

library NodeDefinition {
    enum NodeType {
        NONE,
        REDUCER,
        EXTERNAL,
        CHAINLINK,
        UNISWAP,
        PYTH,
        PRICE_DEVIATION_CIRCUIT_BREAKER,
        STALENESS_CIRCUIT_BREAKER
    }

    struct Data {
        NodeType nodeType;
        bytes parameters;
        bytes32[] parents;
    }

    function load(bytes32 id) internal pure returns (Data storage node) {
        bytes32 s = keccak256(abi.encode("io.synthetix.oracle-manager.Node", id));
        assembly {
            node.slot := s
        }
    }

    function create(
        Data memory nodeDefinition
    ) internal returns (NodeDefinition.Data storage node, bytes32 id) {
        id = getId(nodeDefinition);

        node = load(id);

        node.nodeType = nodeDefinition.nodeType;
        node.parameters = nodeDefinition.parameters;
        node.parents = nodeDefinition.parents;
    }

    function getId(Data memory nodeDefinition) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    nodeDefinition.nodeType,
                    nodeDefinition.parameters,
                    nodeDefinition.parents
                )
            );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

library NodeOutput {
    struct Data {
        int256 price;
        uint256 timestamp;
        // solhint-disable-next-line private-vars-leading-underscore
        uint256 __slotAvailableForFutureUse1;
        // solhint-disable-next-line private-vars-leading-underscore
        uint256 __slotAvailableForFutureUse2;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/interfaces/IERC165.sol";

/// @title Interface a Market needs to adhere.
interface IMarket is IERC165 {
    /// @notice returns a human-readable name for a given market
    function name(uint128 marketId) external view returns (string memory);

    /// @notice returns amount of USD that the market would try to mint256 if everything was withdrawn
    function reportedDebt(uint128 marketId) external view returns (uint256);

    /// @notice returns the amount of collateral which should (in addition to `reportedDebt`) be prevented from withdrawing from this market
    /// if your market does not require locking, set this to `0`
    function locked(uint128 marketId) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title System-wide entry point for the management of markets connected to the system.
 */
interface IMarketManagerModule {
    /**
     * @notice Thrown when a market does not have enough liquidity for a withdrawal.
     */
    error NotEnoughLiquidity(uint128 marketId, uint256 amount);

    /**
     * @notice Thrown when an attempt to register a market that does not conform to the IMarket interface is made.
     */
    error IncorrectMarketInterface(address market);

    /**
     * @notice Emitted when a new market is registered in the system.
     * @param market The address of the external market that was registered in the system.
     * @param marketId The id with which the market was registered in the system.
     * @param sender The account that trigger the registration of the market.
     */
    event MarketRegistered(
        address indexed market,
        uint128 indexed marketId,
        address indexed sender
    );

    /**
     * @notice Emitted when a market deposits snxUSD in the system.
     * @param marketId The id of the market that deposited snxUSD in the system.
     * @param target The address of the account that provided the snxUSD in the deposit.
     * @param amount The amount of snxUSD deposited in the system, denominated with 18 decimals of precision.
     * @param market The address of the external market that is depositing.
     */
    event MarketUsdDeposited(
        uint128 indexed marketId,
        address indexed target,
        uint256 amount,
        address indexed market
    );

    /**
     * @notice Emitted when a market withdraws snxUSD from the system.
     * @param marketId The id of the market that withdrew snxUSD from the system.
     * @param target The address of the account that received the snxUSD in the withdrawal.
     * @param amount The amount of snxUSD withdrawn from the system, denominated with 18 decimals of precision.
     * @param market The address of the external market that is withdrawing.
     */
    event MarketUsdWithdrawn(
        uint128 indexed marketId,
        address indexed target,
        uint256 amount,
        address indexed market
    );

    /**
     * @notice Connects an external market to the system.
     * @dev Creates a Market object to track the external market, and returns the newly created market id.
     * @param market The address of the external market that is to be registered in the system.
     * @return newMarketId The id with which the market will be registered in the system.
     */
    function registerMarket(address market) external returns (uint128 newMarketId);

    /**
     * @notice Allows an external market connected to the system to deposit USD in the system.
     * @dev The system burns the incoming USD, increases the market's credit capacity, and reduces its issuance.
     * @dev See `IMarket`.
     * @param marketId The id of the market in which snxUSD will be deposited.
     * @param target The address of the account on who's behalf the deposit will be made.
     * @param amount The amount of snxUSD to be deposited, denominated with 18 decimals of precision.
     */
    function depositMarketUsd(uint128 marketId, address target, uint256 amount) external;

    /**
     * @notice Allows an external market connected to the system to withdraw snxUSD from the system.
     * @dev The system mints the requested snxUSD (provided that the market has sufficient credit), reduces the market's credit capacity, and increases its net issuance.
     * @dev See `IMarket`.
     * @param marketId The id of the market from which snxUSD will be withdrawn.
     * @param target The address of the account that will receive the withdrawn snxUSD.
     * @param amount The amount of snxUSD to be withdraw, denominated with 18 decimals of precision.
     */
    function withdrawMarketUsd(uint128 marketId, address target, uint256 amount) external;

    /**
     * @notice Returns the total withdrawable snxUSD amount for the specified market.
     * @param marketId The id of the market whose withdrawable USD amount is being queried.
     * @return withdrawableD18 The total amount of snxUSD that the market could withdraw at the time of the query, denominated with 18 decimals of precision.
     */
    function getWithdrawableMarketUsd(
        uint128 marketId
    ) external view returns (uint256 withdrawableD18);

    /**
     * @notice Returns the net issuance of the specified market (snxUSD withdrawn - snxUSD deposited).
     * @param marketId The id of the market whose net issuance is being queried.
     * @return issuanceD18 The net issuance of the market, denominated with 18 decimals of precision.
     */
    function getMarketNetIssuance(uint128 marketId) external view returns (int128 issuanceD18);

    /**
     * @notice Returns the reported debt of the specified market.
     * @param marketId The id of the market whose reported debt is being queried.
     * @return reportedDebtD18 The market's reported debt, denominated with 18 decimals of precision.
     */
    function getMarketReportedDebt(
        uint128 marketId
    ) external view returns (uint256 reportedDebtD18);

    /**
     * @notice Returns the total debt of the specified market.
     * @param marketId The id of the market whose debt is being queried.
     * @return totalDebtD18 The total debt of the market, denominated with 18 decimals of precision.
     */
    function getMarketTotalDebt(uint128 marketId) external view returns (int256 totalDebtD18);

    /**
     * @notice Returns the total snxUSD value of the collateral for the specified market.
     * @param marketId The id of the market whose collateral is being queried.
     * @return valueD18 The market's total snxUSD value of collateral, denominated with 18 decimals of precision.
     */
    function getMarketCollateral(uint128 marketId) external view returns (uint256 valueD18);

    /**
     * @notice Returns the value per share of the debt of the specified market.
     * @dev This is not a view function, and actually updates the entire debt distribution chain.
     * @param marketId The id of the market whose debt per share is being queried.
     * @return debtPerShareD18 The market's debt per share value, denominated with 18 decimals of precision.
     */
    function getMarketDebtPerShare(uint128 marketId) external returns (int256 debtPerShareD18);

    /**
     * @notice Returns wether the capacity of the specified market is locked.
     * @param marketId The id of the market whose capacity is being queried.
     * @return isLocked A boolean that is true if the market's capacity is locked at the time of the query.
     */
    function isMarketCapacityLocked(uint128 marketId) external view returns (bool isLocked);

    /**
     * @notice Update a market's current debt registration with the system.
     * This function is provided as an escape hatch for pool griefing, preventing
     * overwhelming the system with a series of very small pools and creating high gas
     * costs to update an account.
     * @param marketId the id of the market that needs pools bumped
     * @return finishedDistributing whether or not all bumpable pools have been bumped and target price has been reached
     */
    function distributeDebtToPools(
        uint128 marketId,
        uint256 maxIter
    ) external returns (bool finishedDistributing);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-modules/contracts/interfaces/ITokenModule.sol";

/**
 * @title Module for managing the snxUSD token as an associated system.
 */
interface IUSDTokenModule is ITokenModule {
    /**
     * @notice Allows the core system to burn snxUSD held by the `from` address, provided that it has given allowance to `spender`.
     * @param from The address that holds the snxUSD to be burned.
     * @param spender The address to which the holder has given allowance to.
     * @param amount The amount of snxUSD to be burned, denominated with 18 decimals of precision.
     */
    function burnWithAllowance(address from, address spender, uint256 amount) external;

    /**
     * @notice Allows users to transfer tokens cross-chain using CCIP. This is disabled until _CCIP_CHAINLINK_SEND is set in UtilsModule. This is currently included for testing purposes. Functionality will change, including fee collection, as CCIP continues development.
     * @param destChainId The id of the chain where tokens are to be transferred to.
     * @param to The destination address in the target chain.
     * @param amount The amount of tokens to be transferred, denominated with 18 decimals of precision.
     * @return feesPaidD18 The amount of fees paid in the cross-chain transfer, denominated with 18 decimals of precision.
     */
    function transferCrossChain(
        uint256 destChainId,
        address to,
        uint256 amount
    ) external returns (uint256 feesPaidD18);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../../interfaces/IMarketManagerModule.sol";
import "../../interfaces/IUSDTokenModule.sol";
import "../../interfaces/external/IMarket.sol";

import "@synthetixio/core-contracts/contracts/errors/AccessError.sol";
import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";
import "@synthetixio/core-contracts/contracts/utils/ERC165Helper.sol";

import "../../storage/Market.sol";
import "../../storage/MarketCreator.sol";

import "@synthetixio/core-modules/contracts/storage/AssociatedSystem.sol";
import "@synthetixio/core-modules/contracts/storage/FeatureFlag.sol";

/**
 * @title System-wide entry point for the management of markets connected to the system.
 * @dev See IMarketManagerModule.
 */
contract MarketManagerModule is IMarketManagerModule {
    using SafeCastU128 for uint128;
    using SafeCastU256 for uint256;
    using SafeCastI128 for int128;
    using SafeCastI256 for int256;
    using Market for Market.Data;
    using AssociatedSystem for AssociatedSystem.Data;

    bytes32 private constant _USD_TOKEN = "USDToken";
    bytes32 private constant _MARKET_FEATURE_FLAG = "registerMarket";
    bytes32 private constant _DEPOSIT_MARKET_FEATURE_FLAG = "depositMarketUsd";
    bytes32 private constant _WITHDRAW_MARKET_FEATURE_FLAG = "withdrawMarketUsd";

    /**
     * @inheritdoc IMarketManagerModule
     */
    function registerMarket(address market) external override returns (uint128 marketId) {
        FeatureFlag.ensureAccessToFeature(_MARKET_FEATURE_FLAG);

        if (!ERC165Helper.safeSupportsInterface(market, type(IMarket).interfaceId)) {
            revert IncorrectMarketInterface(market);
        }

        marketId = MarketCreator.create(market).id;

        emit MarketRegistered(market, marketId, msg.sender);

        return marketId;
    }

    /**
     * @inheritdoc IMarketManagerModule
     */
    function getWithdrawableMarketUsd(uint128 marketId) public view override returns (uint256) {
        int256 withdrawable = Market.load(marketId).creditCapacityD18 +
            Market.load(marketId).getDepositedCollateralValue().toInt();

        return withdrawable < 0 ? 0 : withdrawable.toUint();
    }

    /**
     * @inheritdoc IMarketManagerModule
     */
    function getMarketNetIssuance(uint128 marketId) external view override returns (int128) {
        return Market.load(marketId).netIssuanceD18;
    }

    /**
     * @inheritdoc IMarketManagerModule
     */
    function getMarketReportedDebt(uint128 marketId) external view override returns (uint256) {
        return Market.load(marketId).getReportedDebt();
    }

    /**
     * @inheritdoc IMarketManagerModule
     */
    function getMarketCollateral(uint128 marketId) external view override returns (uint256) {
        return Market.load(marketId).poolsDebtDistribution.totalSharesD18;
    }

    /**
     * @inheritdoc IMarketManagerModule
     */
    function getMarketTotalDebt(uint128 marketId) external view override returns (int256) {
        return Market.load(marketId).totalDebt();
    }

    /**
     * @inheritdoc IMarketManagerModule
     */
    function getMarketDebtPerShare(uint128 marketId) external override returns (int256) {
        Market.Data storage market = Market.load(marketId);

        market.distributeDebtToPools(999999999);

        return market.getDebtPerShare();
    }

    /**
     * @inheritdoc IMarketManagerModule
     */
    function isMarketCapacityLocked(uint128 marketId) external view override returns (bool) {
        return Market.load(marketId).isCapacityLocked();
    }

    /**
     * @inheritdoc IMarketManagerModule
     */
    function depositMarketUsd(uint128 marketId, address target, uint256 amount) external override {
        FeatureFlag.ensureAccessToFeature(_DEPOSIT_MARKET_FEATURE_FLAG);
        Market.Data storage market = Market.load(marketId);

        // Call must come from the market itself.
        if (msg.sender != market.marketAddress) revert AccessError.Unauthorized(msg.sender);

        // verify if the market is authorized to burn the USD for the target
        ITokenModule usdToken = AssociatedSystem.load(_USD_TOKEN).asToken();

        // Adjust accounting.
        market.creditCapacityD18 += amount.toInt().to128();
        market.netIssuanceD18 -= amount.toInt().to128();

        // Burn the incoming USD.
        // Note: Instead of burning, we could transfer USD to and from the MarketManager,
        // but minting and burning takes the USD out of circulation,
        // which doesn't affect `totalSupply`, thus simplifying accounting.
        IUSDTokenModule(address(usdToken)).burnWithAllowance(target, msg.sender, amount);

        emit MarketUsdDeposited(marketId, target, amount, msg.sender);
    }

    /**
     * @inheritdoc IMarketManagerModule
     */
    function withdrawMarketUsd(uint128 marketId, address target, uint256 amount) external override {
        FeatureFlag.ensureAccessToFeature(_WITHDRAW_MARKET_FEATURE_FLAG);
        Market.Data storage marketData = Market.load(marketId);

        // Call must come from the market itself.
        if (msg.sender != marketData.marketAddress) revert AccessError.Unauthorized(msg.sender);

        // Ensure that the market's balance allows for this withdrawal.
        if (amount > getWithdrawableMarketUsd(marketId))
            revert NotEnoughLiquidity(marketId, amount);

        // Adjust accounting.
        marketData.creditCapacityD18 -= amount.toInt().to128();
        marketData.netIssuanceD18 += amount.toInt().to128();

        // Mint the requested USD.
        AssociatedSystem.load(_USD_TOKEN).asToken().mint(target, amount);

        emit MarketUsdWithdrawn(marketId, target, amount, msg.sender);
    }

    /**
     * @inheritdoc IMarketManagerModule
     */
    function distributeDebtToPools(
        uint128 marketId,
        uint256 maxIter
    ) external override returns (bool) {
        return Market.load(marketId).distributeDebtToPools(maxIter);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/utils/SetUtil.sol";
import "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";
import "@synthetixio/core-contracts/contracts/errors/ParameterError.sol";
import "@synthetixio/oracle-manager/contracts/interfaces/INodeModule.sol";
import "@synthetixio/oracle-manager/contracts/storage/NodeOutput.sol";
import "@synthetixio/core-contracts/contracts/interfaces/IERC20.sol";
import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

import "./OracleManager.sol";

/**
 * @title Tracks system-wide settings for each collateral type, as well as helper functions for it, such as retrieving its current price from the oracle manager.
 */
library CollateralConfiguration {
    bytes32 private constant _SLOT_AVAILABLE_COLLATERALS =
        keccak256(
            abi.encode("io.synthetix.synthetix.CollateralConfiguration_availableCollaterals")
        );

    using SetUtil for SetUtil.AddressSet;
    using DecimalMath for uint256;
    using SafeCastI256 for int256;

    /**
     * @dev Thrown when the token address of a collateral cannot be found.
     */
    error CollateralNotFound();

    /**
     * @dev Thrown when deposits are disabled for the given collateral type.
     * @param collateralType The address of the collateral type for which depositing was disabled.
     */
    error CollateralDepositDisabled(address collateralType);

    /**
     * @dev Thrown when collateral ratio is not sufficient in a given operation in the system.
     * @param collateralValue The net USD value of the position.
     * @param debt The net USD debt of the position.
     * @param ratio The collateralization ratio of the position.
     * @param minRatio The minimum c-ratio which was not met. Could be issuance ratio or liquidation ratio, depending on the case.
     */
    error InsufficientCollateralRatio(
        uint256 collateralValue,
        uint256 debt,
        uint256 ratio,
        uint256 minRatio
    );

    /**
     * @dev Thrown when the amount being delegated is less than the minimum expected amount.
     * @param minDelegation The current minimum for deposits and delegation set to this collateral type.
     */
    error InsufficientDelegation(uint256 minDelegation);

    /**
     * @dev Thrown when attempting to convert a token to the system amount and the conversion results in a loss of precision.
     * @param tokenAmount The amount of tokens that were attempted to be converted.
     * @param decimals The number of decimals of the token that was attempted to be converted.
     */
    error PrecisionLost(uint tokenAmount, uint8 decimals);

    struct Data {
        /**
         * @dev Allows the owner to control deposits and delegation of collateral types.
         */
        bool depositingEnabled;
        /**
         * @dev System-wide collateralization ratio for issuance of snxUSD.
         * Accounts will not be able to mint snxUSD if they are below this issuance c-ratio.
         */
        uint256 issuanceRatioD18;
        /**
         * @dev System-wide collateralization ratio for liquidations of this collateral type.
         * Accounts below this c-ratio can be immediately liquidated.
         */
        uint256 liquidationRatioD18;
        /**
         * @dev Amount of tokens to award when an account is liquidated.
         */
        uint256 liquidationRewardD18;
        /**
         * @dev The oracle manager node id which reports the current price for this collateral type.
         */
        bytes32 oracleNodeId;
        /**
         * @dev The token address for this collateral type.
         */
        address tokenAddress;
        /**
         * @dev Minimum amount that accounts can delegate to pools.
         * Helps prevent spamming on the system.
         * Note: If zero, liquidationRewardD18 will be used.
         */
        uint256 minDelegationD18;
    }

    /**
     * @dev Loads the CollateralConfiguration object for the given collateral type.
     * @param token The address of the collateral type.
     * @return collateralConfiguration The CollateralConfiguration object.
     */
    function load(address token) internal pure returns (Data storage collateralConfiguration) {
        bytes32 s = keccak256(abi.encode("io.synthetix.synthetix.CollateralConfiguration", token));
        assembly {
            collateralConfiguration.slot := s
        }
    }

    /**
     * @dev Loads all available collateral types configured in the system.
     * @return availableCollaterals An array of addresses, one for each collateral type supported by the system.
     */
    function loadAvailableCollaterals()
        internal
        pure
        returns (SetUtil.AddressSet storage availableCollaterals)
    {
        bytes32 s = _SLOT_AVAILABLE_COLLATERALS;
        assembly {
            availableCollaterals.slot := s
        }
    }

    /**
     * @dev Configures a collateral type.
     * @param config The CollateralConfiguration object with all the settings for the collateral type being configured.
     */
    function set(Data memory config) internal {
        SetUtil.AddressSet storage collateralTypes = loadAvailableCollaterals();

        if (!collateralTypes.contains(config.tokenAddress)) {
            collateralTypes.add(config.tokenAddress);
        }

        if (config.minDelegationD18 < config.liquidationRewardD18) {
            revert ParameterError.InvalidParameter(
                "minDelegation",
                "must be greater than liquidationReward"
            );
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

    /**
     * @dev Shows if a given collateral type is enabled for deposits and delegation.
     * @param token The address of the collateral being queried.
     */
    function collateralEnabled(address token) internal view {
        if (!load(token).depositingEnabled) {
            revert CollateralDepositDisabled(token);
        }
    }

    /**
     * @dev Reverts if the amount being delegated is insufficient for the system.
     * @param token The address of the collateral type.
     * @param amountD18 The amount being checked for sufficient delegation.
     */
    function requireSufficientDelegation(address token, uint256 amountD18) internal view {
        CollateralConfiguration.Data storage config = load(token);

        uint256 minDelegationD18 = config.minDelegationD18;

        if (minDelegationD18 == 0) {
            minDelegationD18 = config.liquidationRewardD18;
        }

        if (amountD18 < minDelegationD18) {
            revert InsufficientDelegation(minDelegationD18);
        }
    }

    /**
     * @dev Returns the price of this collateral configuration object.
     * @param self The CollateralConfiguration object.
     * @return The price of the collateral with 18 decimals of precision.
     */
    function getCollateralPrice(Data storage self) internal view returns (uint256) {
        OracleManager.Data memory oracleManager = OracleManager.load();
        NodeOutput.Data memory node = INodeModule(oracleManager.oracleManagerAddress).process(
            self.oracleNodeId
        );

        return node.price.toUint();
    }

    /**
     * @dev Reverts if the specified collateral and debt values produce a collateralization ratio which is below the amount required for new issuance of snxUSD.
     * @param self The CollateralConfiguration object whose collateral and settings are being queried.
     * @param debtD18 The debt component of the ratio.
     * @param collateralValueD18 The collateral component of the ratio.
     */
    function verifyIssuanceRatio(
        Data storage self,
        uint256 debtD18,
        uint256 collateralValueD18
    ) internal view {
        if (
            debtD18 != 0 &&
            (collateralValueD18 == 0 ||
                collateralValueD18.divDecimal(debtD18) < self.issuanceRatioD18)
        ) {
            revert InsufficientCollateralRatio(
                collateralValueD18,
                debtD18,
                collateralValueD18.divDecimal(debtD18),
                self.issuanceRatioD18
            );
        }
    }

    /**
     * @dev Converts token amounts with non-system decimal precisions, to 18 decimals of precision.
     * E.g: $TOKEN_A uses 6 decimals of precision, so this would upscale it by 12 decimals.
     * E.g: $TOKEN_B uses 20 decimals of precision, so this would downscale it by 2 decimals.
     * @param self The CollateralConfiguration object corresponding to the collateral type being converted.
     * @param tokenAmount The token amount, denominated in its native decimal precision.
     * @return amountD18 The converted amount, denominated in the system's 18 decimal precision.
     */
    function convertTokenToSystemAmount(
        Data storage self,
        uint256 tokenAmount
    ) internal view returns (uint256 amountD18) {
        // this extra condition is to prevent potentially malicious untrusted code from being executed on the next statement
        if (self.tokenAddress == address(0)) {
            revert CollateralNotFound();
        }

        /// @dev this try-catch block assumes there is no malicious code in the token's fallback function
        try IERC20(self.tokenAddress).decimals() returns (uint8 decimals) {
            if (decimals == 18) {
                amountD18 = tokenAmount;
            } else if (decimals < 18) {
                amountD18 = (tokenAmount * DecimalMath.UNIT) / (10 ** decimals);
            } else {
                // ensure no precision is lost when converting to 18 decimals
                if (tokenAmount % (10 ** (decimals - 18)) != 0) {
                    revert PrecisionLost(tokenAmount, decimals);
                }

                // this will scale down the amount by the difference between the token's decimals and 18
                amountD18 = (tokenAmount * DecimalMath.UNIT) / (10 ** decimals);
            }
        } catch {
            // if the token doesn't have a decimals function, assume it's 18 decimals
            amountD18 = tokenAmount;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";
import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

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
    function distributeValue(Data storage self, int256 valueD18) internal {
        if (valueD18 == 0) {
            return;
        }

        uint256 totalSharesD18 = self.totalSharesD18;

        if (totalSharesD18 == 0) {
            revert EmptyDistribution();
        }

        int256 valueD45 = valueD18 * DecimalMath.UNIT_PRECISE_INT;
        int256 deltaValuePerShareD27 = valueD45 / totalSharesD18.toInt();

        self.valuePerShareD27 += deltaValuePerShareD27.to128();
    }

    /**
     * @dev Updates an actor's number of shares in the distribution to the specified amount.
     *
     * Whenever an actor's shares are changed in this way, we record the distribution's current valuePerShare into the actor's lastValuePerShare record.
     *
     * Returns the the amount by which the actors value changed since the last update.
     */
    function setActorShares(
        Data storage self,
        bytes32 actorId,
        uint256 newActorSharesD18
    ) internal returns (int valueChangeD18) {
        valueChangeD18 = getActorValueChange(self, actorId);

        DistributionActor.Data storage actor = self.actorInfo[actorId];

        uint128 sharesUint128D18 = newActorSharesD18.to128();
        self.totalSharesD18 = self.totalSharesD18 + sharesUint128D18 - actor.sharesD18;

        actor.sharesD18 = sharesUint128D18;
        _updateLastValuePerShare(self, actor, newActorSharesD18);
    }

    /**
     * @dev Updates an actor's lastValuePerShare to the distribution's current valuePerShare, and
     * returns the change in value for the actor, since their last update.
     */
    function accumulateActor(
        Data storage self,
        bytes32 actorId
    ) internal returns (int valueChangeD18) {
        DistributionActor.Data storage actor = self.actorInfo[actorId];
        return _updateLastValuePerShare(self, actor, actor.sharesD18);
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
    function getActorValueChange(
        Data storage self,
        bytes32 actorId
    ) internal view returns (int valueChangeD18) {
        return _getActorValueChange(self, self.actorInfo[actorId]);
    }

    /**
     * @dev Returns the number of shares owned by an actor in the distribution.
     */
    function getActorShares(
        Data storage self,
        bytes32 actorId
    ) internal view returns (uint256 sharesD18) {
        return self.actorInfo[actorId].sharesD18;
    }

    /**
     * @dev Returns the distribution's value per share in normal precision (18 decimals).
     * @param self The distribution whose value per share is being queried.
     * @return The value per share in 18 decimal precision.
     */
    function getValuePerShare(Data storage self) internal view returns (int) {
        return self.valuePerShareD27.to256().downscale(DecimalMath.PRECISION_FACTOR);
    }

    function _updateLastValuePerShare(
        Data storage self,
        DistributionActor.Data storage actor,
        uint256 newActorShares
    ) private returns (int valueChangeD18) {
        valueChangeD18 = _getActorValueChange(self, actor);

        actor.lastValuePerShareD27 = newActorShares == 0
            ? SafeCastI128.zero()
            : self.valuePerShareD27;
    }

    function _getActorValueChange(
        Data storage self,
        DistributionActor.Data storage actor
    ) private view returns (int valueChangeD18) {
        int256 deltaValuePerShareD27 = self.valuePerShareD27 - actor.lastValuePerShareD27;

        int256 changedValueD45 = deltaValuePerShareD27 * actor.sharesD18.toInt();
        valueChangeD18 = changedValueD45 / DecimalMath.UNIT_PRECISE_INT;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

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
pragma solidity >=0.8.11 <0.9.0;

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

    /**
     * @dev Thrown when a specified market is not found.
     */
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
         * The credit capacity can go negative if all of the collateral provided by pools is exhausted, and there is market provided collateral available to consume. in this case, the debt is still being
         * appropriately assigned, but the market has a dynamic cap based on deposited collateral types.
         *
         */
        int128 creditCapacityD18;
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
         * Markets may obtain additional liquidity, beyond that coming from depositors, by providing their own collateral.
         *
         */
        DepositedCollateral[] depositedCollateral;
        /**
         * @dev The maximum amount of market provided collateral, per type, that this market can deposit.
         */
        mapping(address => uint256) maximumDepositableD18;
    }

    /**
     * @dev Data structure that allows the Market to track the amount of market provided collateral, per type.
     */
    struct DepositedCollateral {
        address collateralType;
        uint256 amountD18;
    }

    /**
     * @dev Returns the market stored at the specified market id.
     */
    function load(uint128 id) internal pure returns (Data storage market) {
        bytes32 s = keccak256(abi.encode("io.synthetix.synthetix.Market", id));
        assembly {
            market.slot := s
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
    function getReportedDebt(Data storage self) internal view returns (uint256) {
        return IMarket(self.marketAddress).reportedDebt(self.id);
    }

    /**
     * @dev Queries the market for the amount of collateral which should be prevented from withdrawal.
     */
    function getLockedCreditCapacity(Data storage self) internal view returns (uint256) {
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
    function totalDebt(Data storage self) internal view returns (int256) {
        return
            getReportedDebt(self).toInt() +
            self.netIssuanceD18 -
            getDepositedCollateralValue(self).toInt();
    }

    /**
     * @dev Returns the USD value for the total amount of collateral provided by the market itself.
     *
     * Note: This is not credit capacity provided by depositors through pools.
     */
    function getDepositedCollateralValue(Data storage self) internal view returns (uint256) {
        uint256 totalDepositedCollateralValueD18 = 0;

        // Sweep all DepositedCollateral entries and aggregate their USD value.
        for (uint256 i = 0; i < self.depositedCollateral.length; i++) {
            DepositedCollateral memory entry = self.depositedCollateral[i];
            CollateralConfiguration.Data storage collateralConfiguration = CollateralConfiguration
                .load(entry.collateralType);

            if (entry.amountD18 == 0) {
                continue;
            }

            uint256 priceD18 = CollateralConfiguration.getCollateralPrice(collateralConfiguration);

            totalDepositedCollateralValueD18 += priceD18.mulDecimal(entry.amountD18);
        }

        return totalDepositedCollateralValueD18;
    }

    /**
     * @dev Returns the amount of credit capacity that a certain pool provides to the market.

     * This credit capacity is obtained by reading the amount of shares that the pool has in the market's debt distribution, which represents the amount of USD denominated credit capacity that the pool has provided to the market.
     */
    function getPoolCreditCapacity(
        Data storage self,
        uint128 poolId
    ) internal view returns (uint256) {
        return self.poolsDebtDistribution.getActorShares(poolId.toBytes32());
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
        uint256 creditCapacitySharesD18,
        int256 maxShareValueD18
    ) internal view returns (int256 contributionD18) {
        // Determine how much the current value per share deviates from the maximum.
        uint256 deltaValuePerShareD18 = (maxShareValueD18 -
            self.poolsDebtDistribution.getValuePerShare()).toUint();

        return deltaValuePerShareD18.mulDecimal(creditCapacitySharesD18).toInt();
    }

    /**
     * @dev Returns true if the market's current capacity is below the amount of locked capacity.
     *
     */
    function isCapacityLocked(Data storage self) internal view returns (bool) {
        return self.creditCapacityD18 < getLockedCreditCapacity(self).toInt();
    }

    /**
     * @dev Gets any outstanding debt. Do not call this method except in tests
     *
     * Note: This function should only be used in tests!
     */
    // solhint-disable-next-line private-vars-leading-underscore, func-name-mixedcase
    function _testOnly_getOutstandingDebt(
        Data storage self,
        uint128 poolId
    ) internal returns (int256 debtChangeD18) {
        return
            self.pools[poolId].pendingDebtD18.toInt() +
            self.poolsDebtDistribution.accumulateActor(poolId.toBytes32());
    }

    /**
     * Returns the number of pools currently active in the market
     *
     * Note: this is test only
     */
    // solhint-disable-next-line private-vars-leading-underscore, func-name-mixedcase
    function _testOnly_inRangePools(Data storage self) internal view returns (uint256) {
        return self.inRangePools.size();
    }

    /**
     * Returns the number of pools currently active in the market
     *
     * Note: this is test only
     */
    // solhint-disable-next-line private-vars-leading-underscore, func-name-mixedcase
    function _testOnly_outRangePools(Data storage self) internal view returns (uint256) {
        return self.outRangePools.size();
    }

    /**
     * @dev Returns the debt value per share
     */
    function getDebtPerShare(Data storage self) internal view returns (int256 debtPerShareD18) {
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
        int256 maxDebtShareValueD18, // (in USD)
        uint256 newCreditCapacityD18 // in collateralValue (USD)
    ) internal returns (int256 debtChangeD18) {
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
        uint256 newCreditCapacityD18,
        int256 newPoolMaxShareValueD18
    ) internal returns (int256 debtChangeD18) {
        uint256 oldCreditCapacityD18 = getPoolCreditCapacity(self, poolId);
        int256 oldPoolMaxShareValueD18 = -self.inRangePools.getById(poolId).priority;

        // Sanity checks
        // require(oldPoolMaxShareValue == 0, "value is not 0");
        // require(newPoolMaxShareValue == 0, "new pool max share value is in fact set");

        self.pools[poolId].creditCapacityAmountD18 = newCreditCapacityD18.to128();

        int128 valuePerShareD18 = self.poolsDebtDistribution.getValuePerShare().to128();

        if (newCreditCapacityD18 == 0) {
            self.inRangePools.extractById(poolId);
            self.outRangePools.extractById(poolId);
        } else if (newPoolMaxShareValueD18 < valuePerShareD18) {
            // this will ensure calculations below can correctly gauge shares changes
            newCreditCapacityD18 = 0;
            self.inRangePools.extractById(poolId);
            self.outRangePools.insert(poolId, newPoolMaxShareValueD18.to128());
        } else {
            self.inRangePools.insert(poolId, -newPoolMaxShareValueD18.to128());
            self.outRangePools.extractById(poolId);
        }

        int256 changedValueD18 = self.poolsDebtDistribution.setActorShares(
            poolId.toBytes32(),
            newCreditCapacityD18
        );
        debtChangeD18 = self.pools[poolId].pendingDebtD18.toInt() + changedValueD18;
        self.pools[poolId].pendingDebtD18 = 0;

        // recalculate market capacity
        if (newPoolMaxShareValueD18 > valuePerShareD18) {
            self.creditCapacityD18 += getCreditCapacityContribution(
                self,
                newCreditCapacityD18,
                newPoolMaxShareValueD18
            ).to128();
        }

        if (oldPoolMaxShareValueD18 > valuePerShareD18) {
            self.creditCapacityD18 -= getCreditCapacityContribution(
                self,
                oldCreditCapacityD18,
                oldPoolMaxShareValueD18
            ).to128();
        }
    }

    /**
     * @dev Moves debt from the market into the pools that connect to it.
     *
     * This function should be called before any of the pools' shares are modified in `poolsDebtDistribution`.
     *
     * Note: The parameter `maxIter` is used as an escape hatch to discourage griefing.
     */
    function distributeDebtToPools(
        Data storage self,
        uint256 maxIter
    ) internal returns (bool fullyDistributed) {
        // Get the current and last distributed market balances.
        // Note: The last distributed balance will be cached within this function's execution.
        int256 targetBalanceD18 = totalDebt(self);
        int256 outstandingBalanceD18 = targetBalanceD18 - self.lastDistributedMarketBalanceD18;

        (, bool exhausted) = bumpPools(self, outstandingBalanceD18, maxIter);

        if (!exhausted && self.poolsDebtDistribution.totalSharesD18 > 0) {
            // cannot use `outstandingBalance` here because `self.lastDistributedMarketBalance`
            // may have changed after calling the bump functions above
            self.poolsDebtDistribution.distributeValue(
                targetBalanceD18 - self.lastDistributedMarketBalanceD18
            );
            self.lastDistributedMarketBalanceD18 = targetBalanceD18.to128();
        }

        return !exhausted;
    }

    /**
     * @dev Determine the target valuePerShare of the poolsDebtDistribution, given the value that is yet to be distributed.
     */
    function getTargetValuePerShare(
        Market.Data storage self,
        int256 valueToDistributeD18
    ) internal view returns (int256 targetValuePerShareD18) {
        return
            self.poolsDebtDistribution.getValuePerShare() +
            (
                self.poolsDebtDistribution.totalSharesD18 > 0
                    ? valueToDistributeD18.divDecimal(
                        self.poolsDebtDistribution.totalSharesD18.toInt()
                    ) // solhint-disable-next-line numcast/safe-cast
                    : int256(0)
            );
    }

    /**
     * @dev Finds pools for which this market's max value per share limit is hit, distributes their debt, and disconnects the market from them.
     *
     * The debt is distributed up to the limit of the max value per share that the pool tolerates on the market.
     */
    function bumpPools(
        Data storage self,
        int256 maxDistributedD18,
        uint256 maxIter
    ) internal returns (int256 actuallyDistributedD18, bool exhausted) {
        if (maxDistributedD18 == 0) {
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
        uint256 iters;
        for (iters = 0; iters < maxIter; iters++) {
            // Exit if there are no pools that can be moved
            if (fromHeap.size() == 0) {
                break;
            }

            // Identify the pool with the lowest maximum value per share.
            HeapUtil.Node memory edgePool = fromHeap.getMax();

            // 2 cases where we want to break out of this loop
            if (
                // If there is no pool in range, and we are going down
                (maxDistributedD18 - actuallyDistributedD18 > 0 &&
                    self.poolsDebtDistribution.totalSharesD18 == 0) ||
                // If there is a pool in ragne, and the lowest max value per share does not hit the limit, exit
                // Note: `-edgePool.priority` is actually the max value per share limit of the pool
                (self.poolsDebtDistribution.totalSharesD18 > 0 &&
                    -edgePool.priority >=
                    k * getTargetValuePerShare(self, (maxDistributedD18 - actuallyDistributedD18)))
            ) {
                break;
            }

            // The pool has hit its maximum value per share and needs to be removed.
            // Note: No need to update capacity because pool max share value = valuePerShare when this happens.
            togglePool(fromHeap, toHeap);

            // Distribute the market's debt to the limit, i.e. for that which exceeds the maximum value per share.
            if (self.poolsDebtDistribution.totalSharesD18 > 0) {
                int256 debtToLimitD18 = self
                    .poolsDebtDistribution
                    .totalSharesD18
                    .toInt()
                    .mulDecimal(
                        -k * edgePool.priority - self.poolsDebtDistribution.getValuePerShare() // Diff between current value and max value per share.
                    );
                self.poolsDebtDistribution.distributeValue(debtToLimitD18);

                // Update the global distributed and outstanding balances with the debt that was just distributed.
                actuallyDistributedD18 += debtToLimitD18;
            } else {
                self.poolsDebtDistribution.valuePerShareD27 = (-k * edgePool.priority)
                    .to256()
                    .upscale(DecimalMath.PRECISION_FACTOR)
                    .to128();
            }

            // Detach the market from this pool by removing the pool's shares from the market.
            // The pool will remain "detached" until the pool manager specifies a new poolsDebtDistribution.
            if (maxDistributedD18 > 0) {
                // the below requires are only for sanity
                require(
                    self.poolsDebtDistribution.getActorShares(edgePool.id.toBytes32()) > 0,
                    "no shares before actor removal"
                );

                uint256 newPoolDebtD18 = self
                    .poolsDebtDistribution
                    .setActorShares(edgePool.id.toBytes32(), 0)
                    .toUint();
                self.pools[edgePool.id].pendingDebtD18 += newPoolDebtD18.to128();
            } else {
                require(
                    self.poolsDebtDistribution.getActorShares(edgePool.id.toBytes32()) == 0,
                    "actor has shares before add"
                );

                self.poolsDebtDistribution.setActorShares(
                    edgePool.id.toBytes32(),
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
    function togglePool(HeapUtil.Data storage from, HeapUtil.Data storage to) internal {
        HeapUtil.Node memory node = from.extractMax();
        to.insert(node.id, -node.priority);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./Market.sol";

/**
 * @title Encapsulates market creation logic
 */
library MarketCreator {
    bytes32 private constant _SLOT_MARKET_CREATOR =
        keccak256(abi.encode("io.synthetix.synthetix.Markets"));

    struct Data {
        /**
         * @dev Tracks an array of market ids for each external IMarket address.
         */
        mapping(address => uint128[]) marketIdsForAddress;
        /**
         * @dev Keeps track of the last market id created.
         * Used for easily creating new markets.
         */
        uint128 lastCreatedMarketId;
    }

    /**
     * @dev Returns the singleton market store of the system.
     */
    function getMarketStore() internal pure returns (Data storage marketStore) {
        bytes32 s = _SLOT_MARKET_CREATOR;
        assembly {
            marketStore.slot := s
        }
    }

    /**
     * @dev Given an external contract address representing an `IMarket`, creates a new id for the market, and tracks it internally in the system.
     *
     * The id used to track the market will be automatically assigned by the system according to the last id used.
     *
     * Note: If an external `IMarket` contract tracks several market ids, this function should be called for each market it tracks, resulting in multiple ids for the same address.
     */
    function create(address marketAddress) internal returns (Market.Data storage market) {
        Data storage marketStore = getMarketStore();

        uint128 id = marketStore.lastCreatedMarketId;
        id++;

        market = Market.load(id);

        market.id = id;
        market.marketAddress = marketAddress;

        marketStore.lastCreatedMarketId = id;

        loadIdsByAddress(marketAddress).push(id);
    }

    /**
     * @dev Returns an array of market ids representing the markets linked to the system at a particular external contract address.
     *
     * Note: A contract implementing the `IMarket` interface may represent more than just one market, and thus several market ids could be associated to a single external contract address.
     */
    function loadIdsByAddress(address marketAddress) internal view returns (uint128[] storage ids) {
        return getMarketStore().marketIdsForAddress[marketAddress];
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Stores information regarding a pool's relationship to a market, such that it can be added or removed from a distribution
 */
library MarketPoolInfo {
    struct Data {
        /**
         * @dev The credit capacity that this pool is providing to the relevant market. Needed to re-add the pool to the distribution when going back in range.
         */
        uint128 creditCapacityAmountD18;
        /**
         * @dev The amount of debt the pool has which hasn't been passed down the debt distribution chain yet.
         */
        uint128 pendingDebtD18;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Represents Oracle Manager
 */
library OracleManager {
    bytes32 private constant _SLOT_ORACLE_MANAGER =
        keccak256(abi.encode("io.synthetix.synthetix.OracleManager"));

    struct Data {
        /**
         * @dev The oracle manager address.
         */
        address oracleManagerAddress;
    }

    /**
     * @dev Loads the singleton storage info about the oracle manager.
     */
    function load() internal pure returns (Data storage oracleManager) {
        bytes32 s = _SLOT_ORACLE_MANAGER;
        assembly {
            oracleManager.slot := s
        }
    }
}