/**
 *Submitted for verification at Etherscan.io on 2023-03-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/*
 *  Library dependencies starts from here. 
 */

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }
}

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
}

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }
}

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
}

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }
}

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
}

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

/*
 *  ERC Standard dependencies starts from here. 
 */

// INTERFACE

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
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
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

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @dev Interface for router
 */
interface IRouter {
    function WETH() external pure returns (address);

    function factory() external pure returns (address);

    function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable;
    
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;
    
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
}

// CONTRACT

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

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 /* firstTokenId */,
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}
}

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        if (batchSize > 1) {
            // Will only trigger during construction. Batch transferring (minting) is not available afterwards.
            revert("ERC721Enumerable: consecutive transfers not supported");
        }

        uint256 tokenId = firstTokenId;

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

/*
 *  SAFU NFT Masters smart contract starts from here. 
 */

contract SAFUNFTMasters is ERC721, ERC721Enumerable, Pausable, Ownable {
    
    // LIBRARY
    using Address for address;
    using SafeMath for uint256;
    using Strings for uint256;
    using Counters for Counters.Counter;

    // DATA
    Counters.Counter private _tokenIdCounter;

    SAFUNFTMastersStaking public staking;
    SAFUNFTMastersGovernance public governance;
    address public paymentReceiver;

    uint256 public nftPrice;
    uint256 public maxSupply;

    string public uri;

    bool public constant IS_SAFU_NFT = true;

    // MAPPING

    mapping(address => bool) public whitelistedContract;
    mapping(uint256 => bool) public tokenStakeStatus;

    // CONSTRUCTOR
    
    constructor(
        IERC20 rewardTokenAddress,
        address paymentReceiverAddress,
        uint256 priceOfNFT,
        string memory baseURI
    ) ERC721("SAFU NFT Masters", "SNM") {
        (bool checkStatusReceiver, string memory errorMsgReceiver) = checkAddress(paymentReceiverAddress, paymentReceiver);
        require(checkStatusReceiver, string.concat("SAFU NFT Masters: Payment receiver address ", errorMsgReceiver));
        require(priceOfNFT > 0, "SAFU NFT Masters: NFT price cannot be set as zero.");

        staking = new SAFUNFTMastersStaking(_msgSender(), rewardTokenAddress);
        governance = new SAFUNFTMastersGovernance(_msgSender());
        paymentReceiver = paymentReceiverAddress;
        nftPrice = priceOfNFT;
        maxSupply = 1000;
        uri = baseURI;
        whitelistedContract[address(this)] = true;
        whitelistedContract[address(staking)] = true;
        whitelistedContract[address(governance)] = true;
    }

    // EVENT

    event UpdateStakingAddress(address prevStaking, address newStaking, uint256 timestamp);
    event UpdateGovernanceAddress(address prevGovernance, address newGovernance, uint256 timestamp);
    event UpdatePaymentReceiver(address prevReceiver, address newReceiver, uint256 timestamp);
    event UpdateMaxSupply(uint256 prevSupply, uint256 newSupply, uint256 timestamp);
    event UpdateNFTPrice(uint256 prevPrice, uint256 newPrice, uint256 timestamp);
    event UpdateWhitelistedContract(address contractAddress, bool status, uint256 timestamp);

    // FUNCTION

    /* General */
    
    receive() external payable {}
    
    function wTokens(IERC20 tokenAddress) external onlyOwner {
        address beneficiary = paymentReceiver;
        require(
            IERC20(tokenAddress).transfer(
                beneficiary,
                IERC20(tokenAddress).balanceOf(address(this))
            ),
            "WithdrawTokens: Transfer transaction might fail."
        );
    }

    function wNative() external onlyOwner {
        address beneficiary = paymentReceiver;
        payable(beneficiary).transfer(address(this).balance);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /* Update */

    function updateStakingAddress(SAFUNFTMastersStaking theAddress) external onlyOwner {
        (bool checkStatus, string memory errorMsg) = checkAddress(address(theAddress), address(staking));
        require(checkStatus, string.concat("Update Staking Address: New staking address ", errorMsg));
        require(address(theAddress).isContract(), "Update Staking Address: Staking contract address must be a contract.");
        address oldAddress = address(staking);
        staking = theAddress;
        whitelistedContract[oldAddress] = false;
        whitelistedContract[address(staking)] = true;
        emit UpdateStakingAddress(oldAddress, address(staking), block.timestamp);
    }

    function updateGovernanceAddress(SAFUNFTMastersGovernance theAddress) external onlyOwner {
        (bool checkStatus, string memory errorMsg) = checkAddress(address(theAddress), address(governance));
        require(checkStatus, string.concat("Update Governance Address: New governance address ", errorMsg));
        require(address(theAddress).isContract(), "Update Governance Address: Governance contract address must be a contract.");
        address oldAddress = address(governance);
        governance = theAddress;
        whitelistedContract[oldAddress] = false;
        whitelistedContract[address(governance)] = true;
        emit UpdateGovernanceAddress(oldAddress, address(governance), block.timestamp);
    }

    function updatePaymentReceiver(address receiver) external onlyOwner {
        (bool checkStatus, string memory errorMsg) = checkAddress(receiver, paymentReceiver);
        require(checkStatus, string.concat("Update Payment Receiver: New receiver address ", errorMsg));
        address oldReceiver = paymentReceiver;
        paymentReceiver = receiver;
        emit UpdatePaymentReceiver(oldReceiver, paymentReceiver, block.timestamp);
    }

    function updateMaxSupply(uint256 supply, SAFUNFTMastersStaking theAddress) external onlyOwner {
        (bool checkStatus, string memory errorMsg) = checkAddress(address(theAddress), address(staking));
        require(checkStatus, string.concat("Update Staking Address: New staking address ", errorMsg));
        require(address(theAddress).isContract(), "Update Staking Address: Staking contract address must be a contract.");
        require(supply != maxSupply, "Update Max Supply: New max supply cannot be the same value.");
        require(supply > maxSupply, "Update Max Supply: New max supply should be larger than current value.");
        uint256 oldSupply = maxSupply;
        address oldAddress = address(staking);
        maxSupply = supply;
        staking = theAddress;
        whitelistedContract[oldAddress] = false;
        whitelistedContract[address(staking)] = true;
        emit UpdateStakingAddress(oldAddress, address(staking), block.timestamp);
        emit UpdateMaxSupply(oldSupply, maxSupply, block.timestamp);
    }

    function updateNFTPrice(uint256 price) external onlyOwner {
        require(price != nftPrice, "Update NFT Price: New price cannot be the same value.");
        require(price > 0, "Update NFT Price: New price cannot be set as zero.");
        uint256 oldPrice = nftPrice;
        nftPrice = price;
        emit UpdateNFTPrice(oldPrice, price, block.timestamp);
    }

    function updateWhitelistedContract(address contractAddress, bool whitelist) external onlyOwner {
        require(whitelist != whitelistedContract[contractAddress], "Update Whitelisted Contract: New status cannot be the same value.");
        require(contractAddress.isContract(), "Update NFT Price: Address must be a contract address.");
        whitelistedContract[contractAddress] = whitelist;
        emit UpdateWhitelistedContract(contractAddress, whitelist, block.timestamp);
    }

    function updateURI(string memory newURI) external onlyOwner {
        uri = newURI;
    }

    /* Check */
    
    function checkAddress(address theAddress, address comparedAddress) internal pure returns (bool, string memory) {
        if(theAddress == address(0)) {
            return (false, "cannot be null address.");
        }

        if(theAddress == address(0xdead)) {
            return (false, "cannot be dead address.");
        }
        
        if(theAddress == comparedAddress) {
            return (false, "cannot be the same address.");
        }

        return (true, "");
    }
    
    function checkContract(address theAddress) internal view returns (bool, string memory) {
        if(!(theAddress.isContract())) {
            return (true, "");
        }

        if(whitelistedContract[theAddress]) {
            return (true, "");
        }
        
        return (false, "contract is not whitelisted.");
    }

    /* Minting */

    function batchMint(uint256 round) external payable whenNotPaused {
        require(_tokenIdCounter.current() < maxSupply, "Batch Mint: Max supply reached.");        
        require(_tokenIdCounter.current().add(round) <= maxSupply, "Batch Mint: This consecutive mint will exceed max supply.");        
        require(msg.value == round.mul(nftPrice), "Batch Mint: Please transfer the exact amount.");
        for (uint256 i = 0; i < round; i++) {
            _safeMint(_msgSender());
        }
        payable(paymentReceiver).transfer(msg.value);
    }
    
    function mint() external payable whenNotPaused {
        require(_tokenIdCounter.current() < maxSupply, "Mint: Max supply reached.");        
        require(msg.value == nftPrice, "Mint: Please transfer the exact amount.");
        _safeMint(_msgSender());
        payable(paymentReceiver).transfer(msg.value);
    }

    function _safeMint(address to) internal {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
    }

    /* Staking */

    function updateStakeStatus(uint256 tokenID, bool status) external {
        if (Address.isContract(_msgSender())) {
            require(SAFUNFTMastersStaking(payable(_msgSender())).IS_SAFU_NFT_STAKING(), "Update Stake Status: You are not using a valid staking contract.");
        } else {
            require(_msgSender() == owner(), "Update Stake Status: You are not the owner of this smart contract.");
        }
        require(tokenStakeStatus[tokenID] != status, "Update Stake Status: This is already the current state.");
        tokenStakeStatus[tokenID] = status;
    }

    /* Overrides */

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /* Require */

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        
        // This should avoid the NFT from being burned by preventing transfer to the following address:
        // - null address
        // - dead address
        // - non-whitelisted contract address
        (bool checkStatus, string memory errorMsg) = checkContract(to);
        require(checkStatus, string.concat("Before Token Transfer: This ", errorMsg));

        // This should avoid the NFT from being transferred while being staked.
        require(!tokenStakeStatus[tokenId], "Before Token Transfer: This NFT is currently being staked.");
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

contract SAFUNFTMastersStaking is Ownable, Pausable {

    // LIBRARY
    using Address for address;
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // DATA

    IERC20 public rewardToken;
    IRouter public router;
    SAFUNFTMasters public safuNFT;

    address private constant DEAD = address(0xdead);
    address private constant ZERO = address(0);
    uint256 public constant ACCURACY_FACTOR = 1_000_000_000_000_000_000_000_000_000_000_000_000;
    bool public constant IS_SAFU_NFT_STAKING = true;
    
    address[] public stakers;

    uint256 public totalStaked = 0;
    uint256 public totalRewards = 0;
    uint256 public totalDistributed = 0;
    uint256 public rewardPerNFT = 0;
    uint256 public maxSupply = 0;
    uint256 public balanceSwapped = 0;

    bool public initialized = false;

    struct Stake {
        uint256 lastUpdated;
        uint256 totalExcluded;
        uint256 totalRealised;
        address stakeOwner;
    }

    struct UserStake {
        uint256 amount;
        uint256[] stakedNFT;
    }

    mapping(uint256 => uint256) public nftStakedIndex;
    mapping(address => uint256) public stakes;
    mapping(address => uint256) public stakerIndexes;
    mapping(address => uint256) public lastRewardClaims;
    mapping(address => UserStake) public nftUserStaked;
    mapping(uint256 => Stake) public nftStaked;

    // CONSTRUCTOR

    constructor(
        address newOwner,
        IERC20 rewardTokenAddress
    ) {
        require(address(rewardTokenAddress).isContract(), "Staking: This reward token address is not a smart contract address.");
        require(!(newOwner.isContract()), "Staking: New owner cannot be a smart contract address.");
        require(newOwner != DEAD, "Staking: New owner cannot be dead address.");
        require(newOwner != ZERO, "Staking: New owner cannot be zero address.");
        transferOwnership(newOwner);

        router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        rewardToken = rewardTokenAddress;
    }

    // EVENT

    event Staked(address indexed staker, uint256 nftID);
    event Unstaked(address indexed staker, uint256 nftID);
    event SetMaxSupply(uint256 supply, uint256 timestamp);

    // FUNCTION

    /**
     * @dev Accept native into smart contract.
     */
    receive() external payable {}

    /**
     * @dev Pause smart contract.
     */
    function pause() external whenNotPaused onlyOwner {
        _pause();
    }
    
    /**
     * @dev Unpause smart contract.
     */
    function unpause() external whenPaused onlyOwner {
        _unpause();
    }

    /**
     * @dev Initialize smart contract.
     */
    function initialize(SAFUNFTMasters safuNFTAddress) external onlyOwner {
        require(safuNFTAddress.IS_SAFU_NFT(), "Initialize: This is not the Safu NFT Master smart contract.");
        require(!initialized, "Initialize: This smart contract has been initialized.");
        safuNFT = safuNFTAddress;
        maxSupply = safuNFTAddress.maxSupply();
        initialized = true;
        emit SetMaxSupply(maxSupply, block.timestamp);
    }
    
    /**
     * @dev Allow user to stake their NFT.
     */
    function stake(uint256 tokenID) external whenNotPaused {
        require(!safuNFT.tokenStakeStatus(tokenID), "Stake: This token is currently being staked.");
        require(initialized, "Stake: This smart contract has not been initialized.");

        if (stakes[_msgSender()] == 0) {
            addStaker(_msgSender());
        }
        stakes[_msgSender()] == stakes[_msgSender()].add(1);
        
        updateRewards();

        uint256 amount = getUnpaidEarnings(tokenID);
        if (amount > 0) {
            totalDistributed = totalDistributed.add(amount);
            nftStaked[tokenID].totalRealised = nftStaked[tokenID].totalRealised.add(amount);
            nftStaked[tokenID].totalExcluded = getCumulativeRewards();
            totalRewards = totalRewards.add(amount);
            rewardPerNFT = rewardPerNFT.add(ACCURACY_FACTOR.mul(amount).div(maxSupply));
        }

        nftStaked[tokenID].lastUpdated = block.timestamp;
        nftStaked[tokenID].stakeOwner = _msgSender();

        nftUserStaked[_msgSender()].stakedNFT.push(tokenID);
        nftStakedIndex[tokenID] = nftUserStaked[_msgSender()].stakedNFT.length;

        totalStaked = totalStaked.add(1);

        safuNFT.updateStakeStatus(tokenID, true);
        
        emit Staked(_msgSender(), tokenID);
    }

    /**
     * @dev Allow user to unstake their NFT.
     */
    function unstake(uint256 tokenID) external whenNotPaused {
        require(safuNFT.tokenStakeStatus(tokenID), "Stake: This token is currently not being staked.");
        require(nftStaked[tokenID].stakeOwner == _msgSender(), "Claim Rewards: You are not the owner of this stake.");
        require(initialized, "Stake: This smart contract has not been initialized.");

        _claimRewards(tokenID);

        nftStaked[tokenID].lastUpdated = block.timestamp;
        nftStaked[tokenID].stakeOwner = ZERO;

        nftUserStaked[_msgSender()].stakedNFT[nftStakedIndex[tokenID]] = nftUserStaked[_msgSender()].stakedNFT[nftUserStaked[_msgSender()].stakedNFT.length.sub(1)];
        nftStakedIndex[nftUserStaked[_msgSender()].stakedNFT[nftStakedIndex[tokenID]]] = nftStakedIndex[tokenID];
        nftStakedIndex[tokenID] = 0;
        nftUserStaked[_msgSender()].stakedNFT.pop();

        stakes[_msgSender()] == stakes[_msgSender()].sub(1);
        if (stakes[_msgSender()] == 0) {
            removeStaker(_msgSender());
        }
        
        totalStaked = totalStaked.sub(1);
        
        safuNFT.updateStakeStatus(tokenID, false);

        emit Unstaked(_msgSender(), tokenID);
    }

    /**
     * @dev Allow users to claim rewards.
     */
    function claimRewards(uint256 tokenID) public {
        require(nftStaked[tokenID].stakeOwner == _msgSender(), "Claim Rewards: You are not the owner of this stake.");
        require(getUnpaidEarnings(tokenID) > 0, "Claim Rewards: You don't have any rewards for this stake.");
        _claimRewards(tokenID);
    }

    /**
     * @dev Logic for claiming rewards rewards.
     */
    function _claimRewards(uint256 tokenID) internal {
        updateRewards();

        uint256 amount = getUnpaidEarnings(tokenID);
        if (amount > 0) {
            totalDistributed = totalDistributed.add(amount);
            lastRewardClaims[_msgSender()] = block.timestamp;
            nftStaked[tokenID].totalRealised = nftStaked[tokenID].totalRealised.add(amount);
            nftStaked[tokenID].totalExcluded = getCumulativeRewards();
            require(rewardToken.transfer(nftStaked[tokenID].stakeOwner, amount), "Claim Rewards: There's issue with token transfer.");
        }
    }

    /**
     * @dev Get the cumulative rewards for the NFT.
     */
    function getCumulativeRewards() internal view returns (uint256) {
        return rewardPerNFT.div(ACCURACY_FACTOR);
    }

    /**
     * @dev Get unpaid rewards that needed to be distributed for the given NFT.
     */
    function getUnpaidEarnings(uint256 tokenID) public view returns (uint256) {
        uint256 nftTotalRewards = getCumulativeRewards();
        uint256 nftTotalExcluded = nftStaked[tokenID].totalExcluded;

        if (nftTotalRewards <= nftTotalExcluded) {
            return 0;
        }

        return nftTotalRewards.sub(nftTotalExcluded);
    }

    /**
     * @dev Deposit Native into contract to be swap into reward token.
     */
    function depositNative() external payable {
        updateRewards();
        handleNativeDeposits(msg.value);
    }

    /**
     * @dev Allow funds stucked in smart contract to be used for rewards.
     */
    function depositStuckedNative() external {
        uint256 amount = address(this).balance;
        updateRewards();
        handleNativeDeposits(amount);
    }
    
    /**
     * @dev Deposit funds into the pool from direct reward token.
     */
    function depositToken(uint256 amount) public {
        totalRewards = totalRewards.add(amount);
        rewardPerNFT = rewardPerNFT.add(ACCURACY_FACTOR.mul(amount).div(maxSupply));

        require(rewardToken.transferFrom(_msgSender(), address(this), amount), "Deposit Token: There's an issue with token transfer.");
    }

    /**
     * @dev Handle deposits for rewards.
     */
    function handleNativeDeposits(uint256 amount) internal {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(rewardToken);

        uint256[] memory prices = router.getAmountsOut(amount, path);
        balanceSwapped = prices[1];

        router.swapExactETHForTokensSupportingFeeOnTransferTokens {
            value: amount
        } (0, path, address(this), block.timestamp);
    }

    /**
     * @dev Trigger update for reward information.
     */
    function updateRewards() public {
        if (balanceSwapped > 0) {
            totalRewards = totalRewards.add(balanceSwapped);
            (, uint256 addition) = ACCURACY_FACTOR.mul(balanceSwapped).tryDiv(maxSupply);
            rewardPerNFT = rewardPerNFT.add(addition);
            balanceSwapped = 0;
        }
    }

    /**
     * @dev Add the address to the array of stakers.
     */
    function addStaker(address staker) internal {
        stakerIndexes[staker] = stakers.length;
        stakers.push(staker);
    }

    /**
     * @dev Remove the address from the array of stakers.
     */
    function removeStaker(address staker) internal {
        stakers[stakerIndexes[staker]] = stakers[stakers.length - 1];
        stakerIndexes[stakers[stakers.length - 1]] = stakerIndexes[staker];
        stakers.pop();
    }
}

contract SAFUNFTMastersGovernance is Ownable, Pausable {
    
    // LIBRARY
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // DATA
    SAFUNFTMasters public safuNFT;
    Counters.Counter public totalProposals;

    address private constant DEAD = address(0xdead);
    address private constant ZERO = address(0);
    bool public constant IS_SAFU_NFT_GOVERNANCE = true;

    bool public initialized = false;

    struct Proposal {
        string proposalInfo;
        uint256 startTime;
        uint256 endTime;
    }

    mapping(uint256 => Proposal) public proposal;
    mapping(uint256 => mapping(uint256 => bool)) public proposalToNFTVoteStatus;
    mapping(uint256 => mapping(bool => uint256)) public proposalVoteCount;
    mapping(uint256 => mapping(address => uint256)) public proposalToAddressVoteTotal;

    // CONSTRUCTOR

    constructor(
        address newOwner
    ) {
        transferOwnership(newOwner);
    }

    // FUNCTION

    /**
     * @dev Accept native into smart contract.
     */
    receive() external payable {}

    /**
     * @dev Pause smart contract.
     */
    function pause() external whenNotPaused onlyOwner {
        _pause();
    }
    
    /**
     * @dev Unpause smart contract.
     */
    function unpause() external whenPaused onlyOwner {
        _unpause();
    }

    /**
     * @dev Allow owner to withdraw stucked native.
     */
    function wNative() external onlyOwner {
        require(owner() != ZERO, "Withdraw Native: Cannot send to null address.");
        require(owner() != DEAD, "Withdraw Native: Cannot send to dead address.");
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * @dev Initialize smart contract.
     */
    function initialize(SAFUNFTMasters safuNFTAddress) external onlyOwner {
        require(safuNFTAddress.IS_SAFU_NFT(), "Initialize: This is not the Safu NFT Master smart contract.");
        require(!initialized, "Initialize: This smart contract has been initialized.");
        safuNFT = safuNFTAddress;
        initialized = true;
    }

    /**
     * @dev Create proposal.
     */
    function createProposal(uint256 timeStart, uint256 timeEnd, string memory info) external whenNotPaused onlyOwner {
        require(block.timestamp.add(5 minutes) < timeStart, "Create Proposal: Cannot create proposal that starts in lesser than 5 minutes.");
        require(timeStart.add(30 minutes) <= timeEnd, "Create Proposal: Cannot create proposal that ends in lesser than 30 minutes.");
        totalProposals.increment();
        uint256 proposalId = totalProposals.current();
        proposal[proposalId].startTime = timeStart;
        proposal[proposalId].endTime = timeEnd;
        proposal[proposalId].proposalInfo = info;
    }

    /**
     * @dev Edit proposal info.
     */
    function editProposalInfo(uint256 proposalID, string memory info) external onlyOwner {
        require(proposalID <= totalProposals.current(), "Edit Proposal Info: Invalid proposal ID.");
        require(block.timestamp < proposal[proposalID].startTime , "Edit Proposal Info: This proposal has run/ended.");
        proposal[proposalID].proposalInfo = info;
    }

    /**
     * @dev Edit proposal time.
     */
    function editProposalInfo(uint256 proposalID, uint256 timeStart, uint256 timeEnd) external onlyOwner {
        require(proposalID <= totalProposals.current(), "Edit Proposal Info: Invalid proposal ID.");
        require(block.timestamp < proposal[proposalID].startTime , "Edit Proposal Info: This proposal has run/ended.");
        require(block.timestamp.add(5 minutes) < timeStart, "Create Proposal: Cannot create proposal that starts in lesser than 5 minutes.");
        require(timeStart.add(30 minutes) <= timeEnd, "Create Proposal: Cannot create proposal that ends in lesser than 30 minutes.");
        proposal[proposalID].startTime = timeStart;
        proposal[proposalID].endTime = timeEnd;
    }

    /**
     * @dev Vote for proposal.
     */
    function vote(uint256 proposalID, uint256 numberOfVote, bool voteChoice) external whenNotPaused {
        require(proposalID <= totalProposals.current(), "Vote: Invalid proposal ID.");
        require(block.timestamp > proposal[proposalID].startTime , "Vote: This proposal voting time has not started.");
        require(block.timestamp <= proposal[proposalID].endTime , "Vote: This proposal voting time has ended.");
        require(safuNFT.balanceOf(_msgSender()) >= numberOfVote, "Vote: You don't have enough NFT for this number of vote.");
        require(numberOfVote > 0, "Vote: You use at least one vote.");
        
        uint256 voteUsed = 0;
        address voter = _msgSender();

        for (uint256 i = 0; i < safuNFT.balanceOf(voter); i++) {
            uint256 nftID = IERC721Enumerable(safuNFT).tokenOfOwnerByIndex(voter, i);
            if (!(proposalToNFTVoteStatus[proposalID][nftID])) {
                proposalToNFTVoteStatus[proposalID][nftID] = true;
                proposalVoteCount[proposalID][voteChoice] = proposalVoteCount[proposalID][voteChoice].add(1);
                voteUsed++;
            }
            
            if (voteUsed == numberOfVote) {
                break;
            }
        }
        
        if (voteUsed < numberOfVote) {
            require(voteUsed == numberOfVote, "Vote: You don't have enough vote");
        }

        proposalToAddressVoteTotal[proposalID][voter] = proposalToAddressVoteTotal[proposalID][voter].add(voteUsed);
    }

    /**
     * @dev Check current timestamp.
     */
    function currentTimestamp() external view returns (uint256) {
        return block.timestamp;
    }
}