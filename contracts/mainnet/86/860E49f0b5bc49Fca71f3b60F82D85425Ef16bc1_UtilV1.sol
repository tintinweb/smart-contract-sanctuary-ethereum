// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
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
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
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
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
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
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
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
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
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
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
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
        uint256, /* firstTokenId */
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
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
    function setApprovalForAll(address operator, bool _approved) external;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

  /*$$$$$  /$$$$$$$  /$$$$$$$$
 /$$__  $$| $$__  $$|__  $$__/
| $$  \ $$| $$  \ $$   | $$
| $$$$$$$$| $$$$$$$/   | $$
| $$__  $$| $$__  $$   | $$
| $$  | $$| $$  \ $$   | $$
| $$  | $$| $$  | $$   | $$
|__/  |__/|__/  |__/   |_*/

interface ArtMeta {
    function tokenCount() external view returns (uint);
    function tokenData(uint tokenId) external view returns (string memory);
    function tokenImage(uint tokenId) external view returns (string memory);
    function tokenImageURI(uint tokenId) external view returns (string memory);
    function tokenDataURI(uint tokenId) external view returns (string memory);
}

struct ArtParams {
    address minter;
    address delegate;
    string name;
    string symbol;
    string description;
    uint32 color1;
    uint32 color2;
}

struct ArtUpdate {
    uint id;
    string name;
    string symbol;
    string description;
    uint32 color1;
    uint32 color2;
}

struct Art {
    uint id;
    ArtMeta meta;
    address delegate;
    string name;
    string symbol;
    string description;
    uint32 color1;
    uint32 color2;
    uint createdAt;
}

contract ArtData is ArtMeta, ERC721 {
    uint private _tokenCount;

    mapping(uint => Art) private _art;

    event CreateArt(
        uint indexed id,
        ArtMeta indexed meta,
        address indexed minter,
        address delegate,
        string name,
        string symbol,
        string description,
        uint32 color1,
        uint32 color2,
        uint timestamp
    );

    event UpdateArt(
        uint indexed id,
        string name,
        string symbol,
        string description,
        uint32 color1,
        uint32 color2,
        uint timestamp
    );

    event DelegateArt(
        uint indexed id,
        address indexed delegate,
        uint timestamp
    );

    function getArt(uint tokenId) external view returns (Art memory) {
        return _requireArt(tokenId);
    }

    function delegateOf(uint artId) public view returns (address) {
        return _requireArt(artId).delegate;
    }

    function tokenCount() external view returns (uint) {
        return _tokenCount;
    }

    function tokenURI(uint tokenId) public view virtual override returns (string memory) {
        return _requireArt(tokenId).meta.tokenDataURI(tokenId);
    }

    function tokenData(uint tokenId) external view returns (string memory) {
        return _requireArt(tokenId).meta.tokenData(tokenId);
    }

    function tokenImage(uint tokenId) external view returns (string memory) {
        return _requireArt(tokenId).meta.tokenImage(tokenId);
    }

    function tokenDataURI(uint tokenId) external view returns (string memory) {
        return _requireArt(tokenId).meta.tokenDataURI(tokenId);
    }

    function tokenImageURI(uint tokenId) external view returns (string memory) {
        return _requireArt(tokenId).meta.tokenImageURI(tokenId);
    }

    function _requireArt(uint tokenId) internal view returns (Art memory) {
        require(
            tokenId > 0 && tokenId <= _tokenCount,
            "Art not found"
        );
        return _art[tokenId];
    }

     /*$$$$$$   /$$$$$$  /$$$$$$$$ /$$$$$$
    | $$__  $$ /$$__  $$|__  $$__//$$__  $$
    | $$  \ $$| $$  \ $$   | $$  | $$  \ $$
    | $$  | $$| $$$$$$$$   | $$  | $$$$$$$$
    | $$  | $$| $$__  $$   | $$  | $$__  $$
    | $$  | $$| $$  | $$   | $$  | $$  | $$
    | $$$$$$$/| $$  | $$   | $$  | $$  | $$
    |_______/ |__/  |__/   |__/  |__/  |_*/

    function createArt(ArtParams memory params, ArtMeta meta) external returns (uint) {
        Art storage art = _art[++_tokenCount];

        art.id = _tokenCount;
        art.meta = meta;
        art.name = params.name;
        art.symbol = params.symbol;
        art.description = params.description;
        art.color1 = params.color1;
        art.color2 = params.color2;
        art.delegate = params.delegate;
        art.createdAt = block.timestamp;

        _safeMint(
            params.minter,
            art.id,
            new bytes(0)
        );

        emit CreateArt(
            art.id,
            art.meta,
            params.minter,
            art.delegate,
            art.name,
            art.symbol,
            art.description,
            art.color1,
            art.color2,
            block.timestamp
        );

        return _tokenCount;
    }

    function updateArt(ArtUpdate calldata params) external returns (uint) {
        Art storage art = _art[params.id];

        require(
            msg.sender == ownerOf(params.id),
            "Caller is not the owner"
        );

        art.name = params.name;
        art.symbol = params.symbol;
        art.description = params.description;
        art.color1 = params.color1;
        art.color2 = params.color2;

        emit UpdateArt(
            art.id,
            art.name,
            art.symbol,
            art.description,
            art.color1,
            art.color2,
            block.timestamp
        );

        return params.id;
    }

    function delegateArt(uint artId, address delegate) external returns (uint) {
        require(
            msg.sender == ownerOf(artId)
            || msg.sender == delegateOf(artId),
            "Caller is not the owner or delegate"
        );

        Art storage art = _art[artId];
        art.delegate = delegate;

        emit DelegateArt(
            artId,
            delegate,
            block.timestamp
        );

        return artId;
    }

    function _afterTokenTransfer(
        address from, address, uint tokenId, uint
    ) internal virtual override {
        if (from != address(0)) {
            Art storage art = _art[tokenId];
            art.delegate = address(0);
        }
    }

    constructor() ERC721("Art", "ART") {}
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import { Strings } from '@openzeppelin/contracts/utils/Strings.sol';

library EncoderV1 {
    using Strings for uint;

    function encodeDecimals(uint num) internal pure returns (bytes memory) {
        bytes memory decimals = bytes((num % 1e18).toString());
        uint length = decimals.length;

        for (uint i = length; i < 18; i += 1) {
            decimals = abi.encodePacked('0', decimals);
        }

        return abi.encodePacked(
            (num / 1e18).toString(),
            '.',
            decimals
        );
    }

    function encodeAddress(address addr) internal pure returns (bytes memory) {
        if (addr == address(0)) {
            return 'null';
        }

        return abi.encodePacked(
            '"', uint(uint160(addr)).toHexString(), '"'
        );
    }

    function encodeColorValue(uint8 colorValue) internal pure returns (bytes memory) {
        bytes memory hexValue = new bytes(2);
        bytes memory hexChars = "0123456789abcdef";
        hexValue[0] = hexChars[colorValue / 16];
        hexValue[1] = hexChars[colorValue % 16];
        return hexValue;
    }

    function encodeColor(uint color) internal pure returns (bytes memory) {
        uint8 r = uint8(color >> 24);
        uint8 g = uint8(color >> 16);
        uint8 b = uint8(color >> 8);
        // uint8 a = uint8(color);

        return abi.encodePacked(
            '#',
             encodeColorValue(r),
             encodeColorValue(g),
             encodeColorValue(b)
        );
    }

    function encodeUintArray(uint[] memory arr) internal pure returns (string memory) {
        bytes memory values;
        uint total = arr.length;

        for (uint i = 0; i < total; i += 1) {
            uint v = arr[i];
            if (i == total - 1) {
                values = abi.encodePacked(values, v.toString());
            } else {
                values = abi.encodePacked(values, v.toString(), ',');
            }
        }

        return string(abi.encodePacked('[', values ,']'));
    }

    function encodeDecimalArray(uint[] memory arr) internal pure returns (string memory) {
        bytes memory values;
        uint total = arr.length;

        for (uint i = 0; i < total; i += 1) {
            uint v = arr[i];
            if (i == total - 1) {
                values = abi.encodePacked(values, encodeDecimals(v));
            } else {
                values = abi.encodePacked(values, encodeDecimals(v), ',');
            }
        }

        return string(abi.encodePacked('[', values ,']'));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import { Strings } from '@openzeppelin/contracts/utils/Strings.sol';
import "../foundation/FoundNote.sol";
import "../money/Found.sol";
import "./EncoderV1.sol";

contract UtilV1 {
    using Strings for uint;

    Found private _found;
    FoundNote private _note;

    function profile(address addr) external view returns (string memory) {
        return string(abi.encodePacked(
            '{"address":"', EncoderV1.encodeAddress(addr), '"',
            _encodeBalance(addr),
            '}'
        ));
    }

    function noteStats() external view returns (string memory) {
        uint currentDay = _note.currentDay();

        return string(abi.encodePacked(
            '{"currentDay":', currentDay.toString(),
            _encodeTime(),
            _encodeConstants(),
            _encodeCash(currentDay),
            _encodeNotes(),
            _encodeFound(),
            '}'
        ));
    }

    function _encodeBalance(address addr) internal virtual view returns (bytes memory) {
        return abi.encodePacked(
            ',"foundBalance":', EncoderV1.encodeDecimals(_found.balanceOf(addr)),
            ',"balance":', EncoderV1.encodeDecimals(address(addr).balance)
        );
    }

    function _encodeTime() internal virtual view returns (bytes memory) {
        return abi.encodePacked(
            ',"timestamp":', block.timestamp.toString(),
            ',"startTime":', _note.startTime().toString(),
            ',"leapSeconds":', _note.leapSeconds().toString()
        );
    }

    function _encodeConstants() internal virtual view returns (bytes memory) {
        return abi.encodePacked(
            ',"dayLength":', _note.DAY_LENGTH().toString(),
            ',"lateDuration":', _note.LATE_DURATION().toString(),
            ',"earnWindow":', _note.EARN_WINDOW().toString()
        );
    }

    function _encodeCash(uint currentDay) internal virtual view returns (bytes memory) {
        return abi.encodePacked(
            ',"cashNow":', EncoderV1.encodeDecimals(_note.coinRevenue(currentDay)),
            ',"cashDaily":', EncoderV1.encodeDecimals(_note.coinRevenue(currentDay - 1)),
            ',"cashWeekly":', EncoderV1.encodeDecimals(_note.averageRevenue()),
            ',"dailyBonus":', EncoderV1.encodeDecimals(_note.dailyBonus()),
            ',"treasuryBalance":', EncoderV1.encodeDecimals(_note.treasuryBalance())
        );
    }

    function _encodeNotes() internal virtual view returns (bytes memory) {
        return abi.encodePacked(
            ',"totalNotes":', _note.tokenCount().toString(),
            ',"totalShares":', EncoderV1.encodeDecimals(_note.totalShares()),
            ',"totalDeposits":', EncoderV1.encodeDecimals(_note.totalDeposits()),
            ',"totalEarnings":', EncoderV1.encodeDecimals(_note.totalEarnings()),
            ',"totalFunding":', EncoderV1.encodeDecimals(_note.totalFunding())
        );
    }

    function _encodeFound() internal virtual view returns (bytes memory) {
        return abi.encodePacked(
            ',"foundRate":', EncoderV1.encodeDecimals(_found.convert(1 ether)),
            ',"foundClaim":', EncoderV1.encodeDecimals(_found.totalClaim()),
            ',"foundSupply":', EncoderV1.encodeDecimals(_found.totalSupply())
        );
    }

    constructor(Found found_, FoundNote note_) {
        _found = found_;
        _note = note_;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import "../art/ArtData.sol";
import "../money/Bank.sol";
import "../money/Coin.sol";

 /*$$$$$$$ /$$$$$$ /$$      /$$ /$$$$$$$$
|__  $$__/|_  $$_/| $$$    /$$$| $$_____/
   | $$     | $$  | $$$$  /$$$$| $$
   | $$     | $$  | $$ $$/$$ $$| $$$$$
   | $$     | $$  | $$  $$$| $$| $$__/
   | $$     | $$  | $$\  $ | $$| $$
   | $$    /$$$$$$| $$ \/  | $$| $$$$$$$$
   |__/   |______/|__/     |__/|_______*/

interface FoundBase {
    function currentDay() external view returns (uint coin);
    function dayLength()  external view returns (uint coin);
    function weekLength()  external view returns (uint coin);
    function coinToArt(uint coin) external view returns (uint art);
}

contract DailyMint is CoinBank {
    using Strings for uint;

    ArtData private _data;
    FoundBase private _base;
    address private _admin;

    uint public constant AMPLITUDE = 10;

    mapping(uint => Coin) private _coins;

    event MintCoin(
        address to,
        uint coinId,
        uint amount,
        uint timestamp
    );

    event DeployCoin(
        uint indexed coinId,
        Coin to,
        uint timestamp
    );

    function data() external view returns (ArtData) {
        return _data;
    }

    function base() external view returns (FoundBase) {
        return _base;
    }

    function admin() external view returns (address) {
        return _admin;
    }

    modifier onlyAdmin() {
        require(
            msg.sender == address(_admin),
            "Caller is not based"
        );
        _;
    }

      /*$$$$$  /$$$$$$$  /$$$$$$$$  /$$$$$$  /$$$$$$$$ /$$$$$$$$  /$$$$$$
     /$$__  $$| $$__  $$| $$_____/ /$$__  $$|__  $$__/| $$_____/ /$$__  $$
    | $$  \__/| $$  \ $$| $$      | $$  \ $$   | $$   | $$      | $$  \__/
    | $$      | $$$$$$$/| $$$$$   | $$$$$$$$   | $$   | $$$$$   |  $$$$$$
    | $$      | $$__  $$| $$__/   | $$__  $$   | $$   | $$__/    \____  $$
    | $$    $$| $$  \ $$| $$      | $$  | $$   | $$   | $$       /$$  \ $$
    |  $$$$$$/| $$  | $$| $$$$$$$$| $$  | $$   | $$   | $$$$$$$$|  $$$$$$/
     \______/ |__/  |__/|________/|__/  |__/   |__/   |________/ \_____*/

    function artOf(uint coinId) external view returns (Art memory) {
        uint artId = _base.coinToArt(coinId);
        return _data.getArt(artId);
    }

    function addressOf(uint coinId) external view returns (Coin) {
        return _coins[coinId];
    }

    function nameOf(uint coinId) override public view returns (string memory) {
        uint artId = _base.coinToArt(coinId);
        return _data.getArt(artId).name;
    }

    function symbolOf(uint coinId) override public view returns (string memory) {
        uint artId = _base.coinToArt(coinId);
        return _data.getArt(artId).symbol;
    }

    function tokenURI(uint coinId) external view returns (string memory) {
        uint artId = _base.coinToArt(coinId);
        return _data.tokenURI(artId);
    }

    function decimals() override public pure returns (uint8) {
        return 18;
    }

    function convertCoin(uint coinId, uint amount) public view returns (uint) {
        uint total = totalSupply();
        if (total == 0) return amount;

        uint current = _base.currentDay();
        if (current == 1) return amount;

        uint reserve = total - totalSupplyOf(current);
        uint average = reserve / (current - 1);
        uint supply = totalSupplyOf(coinId);

        if (supply > average * AMPLITUDE) {
            return amount / AMPLITUDE;
        }

        if (average > supply * AMPLITUDE) {
            return amount * AMPLITUDE;
        }

        return amount * average / supply;
    }

     /*$      /$$  /$$$$$$  /$$   /$$ /$$$$$$$$ /$$     /$$
    | $$$    /$$$ /$$__  $$| $$$ | $$| $$_____/|  $$   /$$/
    | $$$$  /$$$$| $$  \ $$| $$$$| $$| $$       \  $$ /$$/
    | $$ $$/$$ $$| $$  | $$| $$ $$ $$| $$$$$     \  $$$$/
    | $$  $$$| $$| $$  | $$| $$  $$$$| $$__/      \  $$/
    | $$\  $ | $$| $$  | $$| $$\  $$$| $$          | $$
    | $$ \/  | $$|  $$$$$$/| $$ \  $$| $$$$$$$$    | $$
    |__/     |__/ \______/ |__/  \__/|________/    |_*/

    function mintCoin(
        address to,
        uint coinId,
        uint amount
    ) external onlyAdmin {
        _mint(
            to,
            coinId,
            amount,
            new bytes(0)
        );

        emit MintCoin(
            to,
            coinId,
            amount,
            block.timestamp
        );
    }

    function deployCoin(uint coinId) external returns (Coin) {
        require(
            coinId > 0 && coinId <= _base.currentDay(),
            "Coin is not yet deployable"
        );

        require(
            address(_coins[coinId]) == address(0),
            "Coin has already been deployed"
        );

        Coin coin = new Coin(
            CoinBank(this),
            coinId
        );

        _coins[coinId] = coin;

        emit DeployCoin(
            coinId,
            coin,
            block.timestamp
        );

        return _coins[coinId];
    }

    function transferFromDeployed(
        address operator,
        address from,
        address to,
        uint coinId,
        uint amount
    ) external override {
        _requireCoinCaller(coinId);
        _transferFrom(
            operator,
            from,
            to,
            coinId,
            amount,
            new bytes(0)
        );
    }

    function approveDeployed(
        address operator,
        address spender,
        uint coinId,
        uint amount
    ) external override {
        _requireCoinCaller(coinId);
        _approve(
            operator,
            spender,
            coinId,
            amount
        );
    }

    function _requireCoinCaller(uint coinId) internal view {
        address coin = address(_coins[coinId]);
        require(
            coin == msg.sender && coin != address(0),
            "Caller is not the coin contract"
        );
    }

    constructor(
        address admin_,
        ArtData data_,
        FoundBase base_
    ) Bank() {
        _admin = admin_;
        _data = data_;
        _base = base_;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../art/ArtData.sol";
import "./DailyMint.sol";

 /*$   /$$  /$$$$$$  /$$$$$$$$ /$$$$$$$$  /$$$$$$
| $$$ | $$ /$$__  $$|__  $$__/| $$_____/ /$$__  $$
| $$$$| $$| $$  \ $$   | $$   | $$      | $$  \__/
| $$ $$ $$| $$  | $$   | $$   | $$$$$   |  $$$$$$
| $$  $$$$| $$  | $$   | $$   | $$__/    \____  $$
| $$\  $$$| $$  | $$   | $$   | $$       /$$  \ $$
| $$ \  $$|  $$$$$$/   | $$   | $$$$$$$$|  $$$$$$/
|__/  \__/ \______/    |__/   |________/ \_____*/

interface IFound is IERC20 {}

struct CoinVote {
    address payer;
    address minter;
    uint artId;
    uint amount;
}

struct MintCoin {
    address payer;
    address minter;
    uint coinId;
    uint amount;
}

struct ClaimCoin {
    address minter;
    uint coinId;
    uint amount;
}

struct CreateNote {
    address payer;
    address minter;
    address delegate;
    address payee;
    uint fund;
    uint amount;
    uint duration;
    string memo;
    bytes data;
}

struct Note {
    uint id;
    uint artId;
    uint coinId;
    uint fund;
    uint reward;
    uint expiresAt;
    uint createdAt;
    uint collectedAt;
    uint shares;
    uint principal;
    uint penalty;
    uint earnings;
    uint funding;
    uint duration;
    uint dailyBonus;
    address delegate;
    address payee;
    bool closed;
    string memo;
    bytes data;
}

struct WithdrawNote {
    address payee;
    uint noteId;
    uint target;
}

struct DelegateNote {
    uint noteId;
    address delegate;
    address payee;
    string memo;
}

contract FoundNote is FoundBase {
    using Strings for uint;

    IFound private _money;
    address private _bank;
    ArtData private _data;

    uint private _tokenCount;
    uint private _totalShares;
    uint private _totalDeposits;
    uint private _totalEarnings;
    uint private _totalFunding;
    uint private _leap;
    uint private _start;

    uint public constant BASIS_POINTS = 10000;
    uint public constant BID_INCREMENT = 100;
    uint public constant DAY_BUFFER = 301 seconds;
    uint public constant DAY_LENGTH = 25 hours + 20 minutes;
    uint public constant DAYS_PER_WEEK = 7;
    uint public constant MAX_DAYS = 7300;
    uint public constant EARN_WINDOW = 30 * DAY_LENGTH;
    uint public constant LATE_DURATION = 60 * DAY_LENGTH;
    uint public constant MAX_DURATION = MAX_DAYS * DAY_LENGTH;
    uint public constant MIN_DURATION = DAY_LENGTH - 1 hours;

    mapping(uint => mapping(uint => uint)) private _votesOnArt;
    mapping(uint => uint) private _artToCoin;
    mapping(uint => uint) private _coinToArt;
    mapping(uint => Note) private _deposits;
    mapping(uint => uint) private _revenue;
    mapping(uint => uint) private _shares;
    mapping(uint => uint) private _claims;
    mapping(uint => uint) private _locks;

    event CoinCreated(
        uint indexed coinId,
        uint indexed artId,
        uint amount,
        uint timestamp
    );

    event CoinUpdated(
        uint indexed coinId,
        uint indexed from,
        uint indexed to,
        uint timestamp
    );

    event LeapDay(
        uint indexed day,
        uint dayLight,
        uint nightTime,
        uint leapSeconds,
        uint timestamp
    );

      /*$$$$$  /$$$$$$$$ /$$$$$$  /$$$$$$$  /$$$$$$$$
     /$$__  $$|__  $$__//$$__  $$| $$__  $$| $$_____/
    | $$  \__/   | $$  | $$  \ $$| $$  \ $$| $$
    |  $$$$$$    | $$  | $$  | $$| $$$$$$$/| $$$$$
     \____  $$   | $$  | $$  | $$| $$__  $$| $$__/
     /$$  \ $$   | $$  | $$  | $$| $$  \ $$| $$
    |  $$$$$$/   | $$  |  $$$$$$/| $$  | $$| $$$$$$$$
     \______/    |__/   \______/ |__/  |__/|_______*/

    modifier onlyAdmin() {
        require(
            msg.sender == address(_bank),
            "Caller is not based"
        );
        _;
    }

    function cash() external view returns (IFound) {
        return _money;
    }

    function data() external view returns (ArtData) {
        return _data;
    }

    function bank() external view returns (address) {
        return _bank;
    }

    function startTime() external view returns (uint) {
        return _start;
    }

    function leapSeconds() external view returns (uint) {
        return _leap;
    }

    function currentDay() external view returns (uint) {
        return _currentDay();
    }

    function timeToCoin(uint timestamp) external view returns (uint) {
        return _timeToCoin(timestamp);
    }

    function tokenCount() external view returns (uint) {
        return _tokenCount;
    }

    function totalShares() external view returns (uint) {
        return _totalShares;
    }

    function totalDeposits() external view returns (uint) {
        return _totalDeposits;
    }

    function totalEarnings() external view returns (uint) {
        return _totalEarnings;
    }

    function totalFunding() external view returns (uint) {
        return _totalFunding;
    }

    function getShares(uint noteId) external view returns (uint) {
        return _shares[noteId];
    }

    function getClaim(uint coinId) external view returns (uint) {
        return _claims[coinId];
    }

    function getLock(uint artId) external view returns (uint) {
        return _locks[artId];
    }

    function getNote(uint noteId) external view returns (Note memory) {
        return _requireNote(noteId);
    }

    function getCoin(uint coinId) external view returns (Art memory) {
        return _data.getArt(_artToCoin[coinId]);
    }

    function artToCoin(uint artId) external view returns (uint coinId) {
        return _artToCoin[artId];
    }

    function coinToArt(uint coinId) external view returns (uint artId) {
        return _coinToArt[coinId];
    }

    function coinRevenue(uint coinId) external view returns (uint amount) {
        return _revenue[coinId];
    }

    function votesOnArt(uint coinId, uint artId) external view returns (uint amount) {
        return _votesOnArt[coinId][artId];
    }

    function dayLength() external pure returns (uint) {
        return DAY_LENGTH;
    }

    function weekLength() external pure returns (uint) {
        return DAY_LENGTH * DAYS_PER_WEEK;
    }

    function _currentDay() internal view returns (uint) {
        return _timeToCoin(block.timestamp);
    }

    function _timeToCoin(uint timestamp) internal view returns (uint) {
        uint time = timestamp - _start + _leap;
        return time / DAY_LENGTH + 1;
    }

    function collectVote(CoinVote calldata params) external onlyAdmin returns (uint) {
        uint artId = params.artId;

        require(
            artId > 0 && artId <= _data.tokenCount(),
            "Art not found"
        );

        uint coinId = _currentDay();
        uint existing = _artToCoin[artId];

        require(
            existing == 0 || existing == coinId,
            "Art is already a coin"
        );

        uint leaderId = _coinToArt[coinId];
        uint leaderBid = _votesOnArt[coinId][leaderId];

        _revenue[coinId] += params.amount;
        _votesOnArt[coinId][artId] += params.amount;

        if (leaderId == 0 || leaderBid == 0) {
            _coinToArt[coinId] = artId;
            _artToCoin[artId] = coinId;

            emit CoinCreated(
                coinId,
                artId,
                params.amount,
                block.timestamp
            );
        }

        if (leaderId != artId) {
            uint minimum = leaderBid + leaderBid * BID_INCREMENT / BASIS_POINTS;

            if (_votesOnArt[coinId][artId] >= minimum) {
                _artToCoin[leaderId] = 0;
                _coinToArt[coinId] = artId;
                _artToCoin[artId] = coinId;

                emit CoinUpdated(
                    coinId,
                    leaderId,
                    artId,
                    block.timestamp
                );

                uint time = block.timestamp - _start + _leap;
                uint left = DAY_LENGTH - time % DAY_LENGTH;

                if (left < DAY_BUFFER) {
                    uint next = block.timestamp + left + DAY_BUFFER;
                    _leap += DAY_BUFFER;

                    emit LeapDay(
                        coinId,
                        left,
                        next,
                        _leap,
                        block.timestamp
                    );
                }
            }
        }

        return coinId;
    }

    function collectMint(
        uint supply,
        MintCoin calldata params
    ) external onlyAdmin returns (uint) {
        require(
            params.amount > 0,
            "Mint more than 0"
        );

        uint artId = _requireFoundArt(params.coinId);
        _requireUnlockedArt(artId, supply + params.amount);

        _revenue[params.coinId] += params.amount;
        return artId;
    }

    function collectClaim(
        address from,
        uint supply,
        ClaimCoin calldata params
    ) external onlyAdmin returns (uint) {
        require(
            params.amount > 0,
            "Claim more than 0"
        );

        require(
            params.coinId < _currentDay(),
            "Coin is not yet claimable"
        );

        uint artId = _requireFoundArt(params.coinId);
        _requireOwnerOrDelegate(artId, from);

        _requireUnlockedArt(artId, supply + params.amount);

        uint claim = _claims[params.coinId];
        uint limit = (supply - claim) / 10;

        require(
            limit >= params.amount + claim,
            "Claim exceeds allowance"
        );

        _claims[params.coinId] += params.amount;

        return artId;
    }

    function collectLock(
        address from,
        uint coinId,
        uint amount
    ) external onlyAdmin {
        require(
            coinId < _currentDay(),
            "Coin is not yet lockable"
        );

        uint artId = _requireFoundArt(coinId);
        _requireOwnerOrDelegate(artId, from);

        _locks[artId] = amount;
    }

      /*$$$$$  /$$   /$$  /$$$$$$  /$$$$$$$   /$$$$$$  /$$$$$$$  /$$       /$$$$$$$$
     /$$__  $$| $$  | $$ /$$__  $$| $$__  $$ /$$__  $$| $$__  $$| $$      | $$_____/
    | $$  \__/| $$  | $$| $$  \ $$| $$  \ $$| $$  \ $$| $$  \ $$| $$      | $$
    |  $$$$$$ | $$$$$$$$| $$$$$$$$| $$$$$$$/| $$$$$$$$| $$$$$$$ | $$      | $$$$$
     \____  $$| $$__  $$| $$__  $$| $$__  $$| $$__  $$| $$__  $$| $$      | $$__/
     /$$  \ $$| $$  | $$| $$  | $$| $$  \ $$| $$  | $$| $$  \ $$| $$      | $$
    |  $$$$$$/| $$  | $$| $$  | $$| $$  | $$| $$  | $$| $$$$$$$/| $$$$$$$$| $$$$$$$$
     \______/ |__/  |__/|__/  |__/|__/  |__/|__/  |__/|_______/ |________/|_______*/

    function collectDeposit(
        CreateNote calldata params,
        uint reward
    ) external onlyAdmin returns (Note memory) {
        require(
            params.amount > 0,
            "Deposit more than 0"
        );

        uint coinId = _currentDay() - 1;
        require(coinId > 0, "Staking begins tomorrow");

        uint artId = _coinToArt[coinId];
        require(artId > 0, "No art from yesterday");

        uint shares; uint bonus;
        (shares, bonus) = calculateShares(
            coinId,
            params.amount,
            params.duration
        );

        Note storage note = _deposits[++_tokenCount];
        note.id = _tokenCount;
        note.data = params.data;
        note.memo = params.memo;
        note.artId = artId;
        note.coinId = coinId;
        note.fund = params.fund;
        note.reward = reward;
        note.delegate = params.delegate;
        note.payee = params.payee;
        note.principal = params.amount;
        note.duration = params.duration;
        note.expiresAt = block.timestamp + params.duration;
        note.createdAt = block.timestamp;
        note.dailyBonus = bonus;
        note.shares = shares;

        _totalShares += shares;
        _totalDeposits += note.principal;

        return note;
    }

    function collectNote(
        address sender,
        address owner,
        uint noteId,
        address payee,
        uint target
    ) external onlyAdmin returns (Note memory) {
        require(
            noteId > 0 && noteId <= _tokenCount,
            "Deposit not found"
        );

        Note storage note = _deposits[noteId];

        require(
            note.collectedAt == 0,
            "Deposit already collected"
        );

        uint timestamp = block.timestamp;
        uint closeAt = note.expiresAt + EARN_WINDOW + LATE_DURATION;

        if (timestamp <= closeAt) {
            bool isOwner = sender == owner;

            require(
                isOwner || sender == note.delegate,
                "Caller is not the deposit owner or delegate"
            );

            require(
                isOwner || note.payee == address(0) || note.payee == payee,
                "Delegated payees do not match"
            );

            (
                note.earnings,
                note.funding,
                note.penalty
            ) = _calculateEarnings(note, timestamp);

            _totalEarnings += note.earnings;
            _totalFunding += note.funding;
        } else {
            note.penalty = note.principal;
            note.closed = true;
        }

        require(
            target == 0 || note.earnings >= target,
            "Earnings missed the target"
        );

        note.collectedAt = timestamp;

        _totalDeposits -= note.principal;
        _totalShares -= note.shares;

        return note;
    }

    function collectDelegate(
        address sender,
        address owner,
        DelegateNote memory params
    ) external onlyAdmin returns (Note memory) {
        uint noteId = params.noteId;
        require(
            noteId > 0 && noteId <= _tokenCount,
            "Deposit not found"
        );

        bool isOwner = sender == owner;
        Note storage note = _deposits[noteId];

        require(
            isOwner || sender == note.delegate,
            "Caller is not the owner or delegate"
        );

        require(
            isOwner || params.payee == note.payee,
            "Only the owner may update the payee"
        );

        require(
            isOwner || params.delegate != address(0),
            "Only the owner may remove the delegate"
        );

        note.memo = params.memo;
        note.delegate = params.delegate;

        if (params.delegate == address(0)) {
            note.payee = address(0);
        } else {
            note.payee = params.payee;
        }

        return note;
    }

    function afterTransfer(uint noteId) external onlyAdmin {
        Note storage note = _deposits[noteId];
        note.delegate = address(0);
        note.payee = address(0);
    }

    function averageRevenue() external view returns (uint) {
        return _calculateAverageRevenue(_currentDay() - 1);
    }

    function calculateAverageRevenue(uint coinId) external view returns (uint) {
        return _calculateAverageRevenue(coinId);
    }

    function _calculateAverageRevenue(uint coinId) internal view returns (uint) {
        uint limit = DAYS_PER_WEEK > coinId ? coinId : DAYS_PER_WEEK;
        uint total = 0;

        if (limit == 0) return 0;

        for (uint i = 0; i < limit; i += 1) {
            total += _revenue[coinId - i];
        }

        return total / limit;
    }

    function treasuryBalance() external view returns (uint) {
        return _treasuryBalance();
    }

    function _treasuryBalance() internal view returns (uint) {
        return _money.balanceOf(address(_bank)) - _totalDeposits;
    }

    function depositBalance(uint noteId) external view returns (uint) {
        return _depositBalance(_requireNote(noteId).shares);
    }

    function _depositBalance(uint shares) internal view returns (uint) {
        return _treasuryBalance() * shares / _totalShares;
    }

    function dailyBonus() external view returns (uint) {
        return _calculateDailyBonus(_currentDay() - 1, 1 ether);
    }

    function calculateDailyBonus(uint coinId, uint amount) external view returns (uint) {
        return _calculateDailyBonus(coinId, amount);
    }

    function _calculateDailyBonus(uint coinId, uint amount) internal view returns (uint) {
        uint current = _revenue[coinId];
        uint average = _calculateAverageRevenue(coinId);
        uint maximum = amount / 20;

        if (average == 0) return 0;
        if (current == 0) return maximum;
        if (current > average) return 0;
        if (average > current * 2) return maximum;

        return maximum * average / current - maximum;
    }

     /*$$$$$$  /$$$$$$$$ /$$    /$$ /$$$$$$$$ /$$   /$$ /$$   /$$ /$$$$$$$$
    | $$__  $$| $$_____/| $$   | $$| $$_____/| $$$ | $$| $$  | $$| $$_____/
    | $$  \ $$| $$      | $$   | $$| $$      | $$$$| $$| $$  | $$| $$
    | $$$$$$$/| $$$$$   |  $$ / $$/| $$$$$   | $$ $$ $$| $$  | $$| $$$$$
    | $$__  $$| $$__/    \  $$ $$/ | $$__/   | $$  $$$$| $$  | $$| $$__/
    | $$  \ $$| $$        \  $$$/  | $$      | $$\  $$$| $$  | $$| $$
    | $$  | $$| $$$$$$$$   \  $/   | $$$$$$$$| $$ \  $$|  $$$$$$/| $$$$$$$$
    |__/  |__/|________/    \_/    |________/|__/  \__/ \______/ |_______*/

    function calculateShares(uint coinId, uint amount, uint duration) public view returns (uint, uint) {
        require(duration >= MIN_DURATION, "Treasury note is too short");
        require(duration <= MAX_DURATION, "Treasury note is too long");

        uint totalDays = duration / DAY_LENGTH;
        uint bonus = _calculateDailyBonus(coinId, amount);
        uint longer = totalDays * totalDays;

        uint baseShares = amount + bonus;
        uint dailyShares = baseShares * totalDays;
        uint bonusShares = 4 * baseShares * longer / MAX_DAYS;

        uint shares = dailyShares + bonusShares;
        return (shares, bonus);
    }

    function calculateEarnings(
        uint noteId, uint timestamp
    ) external view returns (uint earnings, uint funding, uint penalty) {
        return _calculateEarnings(_requireNote(noteId), timestamp);
    }

    function _calculateEarnings(Note memory note, uint timestamp) internal view returns (uint, uint, uint) {
        uint penalty = _calculatePenalty(note, timestamp);

        if (penalty > 0) {
            return (0, 0, penalty);
        }

        uint balance = _depositBalance(note.shares);
        uint funding = balance * note.reward / BASIS_POINTS;

        return (balance - funding, funding, 0);
    }

    function calculatePenalty(uint noteId, uint timestamp) external view returns (uint) {
        return _calculatePenalty(_requireNote(noteId), timestamp);
    }

    function _calculatePenalty(Note memory note, uint timestamp) internal pure returns (uint) {
        uint expiresAt = note.expiresAt;
        uint principal = note.principal;

        if (timestamp < expiresAt) {
            uint createdAt = note.createdAt;
            uint remaining = expiresAt - timestamp;
            uint duration = expiresAt - createdAt;

            if (remaining >= duration) {
                return principal;
            }

            return principal * remaining / duration;
        }

        uint lateAt = expiresAt + EARN_WINDOW;

        if (timestamp > lateAt) {
            uint late = timestamp - lateAt;

            if (LATE_DURATION > late) {
                return principal * late / LATE_DURATION;
            }

            return principal;
        }

        return 0;
    }

    function _requireNote(uint noteId) internal view returns (Note memory) {
        require(
            noteId > 0 && noteId <= _tokenCount,
            "Note not found"
        );
        return _deposits[noteId];
    }

    function _requireUnlockedArt(uint artId, uint targetSupply) internal view {
        uint lock = _locks[artId];
        require(
            lock == 0 || lock >= targetSupply,
            "Coin supply has been locked"
        );
    }

    function _requireFoundArt(uint coinId) internal view returns (uint artId) {
        require(
            coinId > 0 && coinId < _currentDay(),
            "Coin art has not been choosen"
        );

        require(
            _revenue[coinId] > 0,
            "Coin was not created"
        );

        return _coinToArt[coinId];
    }

    function _requireOwnerOrDelegate(
        uint artId,
        address addr
    ) internal view returns (address, address) {
        address owner = _data.ownerOf(artId);
        address delegate = _data.delegateOf(artId);

        require(
            delegate == addr || owner == addr,
            "Caller is not the owner or delegate"
        );

        return (owner, delegate);
    }

    constructor(
        address bank_,
        ArtData data_,
        IFound money_
    ) {
        _bank = bank_;
        _money = money_;
        _data = data_;
        _start = block.timestamp;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "../shared/ERC1155.sol";

  /*$$$$$  /$$        /$$$$$$  /$$$$$$$   /$$$$$$  /$$
 /$$__  $$| $$       /$$__  $$| $$__  $$ /$$__  $$| $$
| $$  \__/| $$      | $$  \ $$| $$  \ $$| $$  \ $$| $$
| $$ /$$$$| $$      | $$  | $$| $$$$$$$ | $$$$$$$$| $$
| $$|_  $$| $$      | $$  | $$| $$__  $$| $$__  $$| $$
| $$  \ $$| $$      | $$  | $$| $$  \ $$| $$  | $$| $$
|  $$$$$$/| $$$$$$$$|  $$$$$$/| $$$$$$$/| $$  | $$| $$$$$$$$
 \______/ |________/ \______/ |_______/ |__/  |__/|_______*/

abstract contract Bank is ERC1155 {
    uint private _supply;

    mapping(uint => uint) _supplies;
    mapping(address => mapping(address => mapping(uint => uint))) private _allowances;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint indexed coinId,
        uint value
    );

    function nameOf(uint coinId) virtual public view returns (string memory);

    function symbolOf(uint coinId) virtual public view returns (string memory);

    function decimals() virtual public view returns (uint8);

    function totalSupply() public view returns (uint) {
        return _supply;
    }

    function totalSupplyOf(uint coinId) public view returns (uint) {
        return _supplies[coinId];
    }

    function allowance(
        address owner,
        address spender,
        uint coinId
    ) external view returns (uint) {
        return _allowances[owner][spender][coinId];
    }

    function safeTransferFrom(
        address from,
        address to,
        uint id,
        uint amount,
        bytes memory data
    ) public override {
        _transferFrom(msg.sender, from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint[] memory ids,
        uint[] memory amounts,
        bytes memory data
    ) public override {
        uint length = ids.length;

        require(
            length == amounts.length,
            "Bank: ids and amounts length mismatch"
        );

        bool approved = isApprovedForAll(from, msg.sender);

        if (!approved && from != msg.sender) {
            for (uint i = 0; i < length; i += 1) {
                _spendAllowance(from, msg.sender, ids[i], amounts[i]);
            }
        }

        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function approve(
        address spender,
        uint coinId,
        uint amount
    ) external {
        _approve(msg.sender, spender, coinId, amount);
    }

    function approveBatch(
        address spender,
        uint[] memory amounts,
        uint[] memory coins
    ) external {
        uint length = amounts.length;

        require(
            length == coins.length,
            "Bank: Mismatch between amounts and coins lengths"
        );

        for (uint i = 0; i < length; i += 1) {
            _approve(msg.sender, spender, coins[i], amounts[i]);
        }
    }

     /*$       /$$$$$$$$ /$$$$$$$   /$$$$$$  /$$$$$$$$ /$$$$$$$
    | $$      | $$_____/| $$__  $$ /$$__  $$| $$_____/| $$__  $$
    | $$      | $$      | $$  \ $$| $$  \__/| $$      | $$  \ $$
    | $$      | $$$$$   | $$  | $$| $$ /$$$$| $$$$$   | $$$$$$$/
    | $$      | $$__/   | $$  | $$| $$|_  $$| $$__/   | $$__  $$
    | $$      | $$      | $$  | $$| $$  \ $$| $$      | $$  \ $$
    | $$$$$$$$| $$$$$$$$| $$$$$$$/|  $$$$$$/| $$$$$$$$| $$  | $$
    |________/|________/|_______/  \______/ |________/|__/  |_*/

    function _transferFrom(
        address operator,
        address from,
        address to,
        uint id,
        uint amount,
        bytes memory data
    ) internal {
        bool approved = isApprovedForAll(from, operator);

        if (!approved && from != operator) {
            _spendAllowance(from, operator, id, amount);
        }

        _safeTransferFrom(from, to, id, amount, data);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint coinId,
        uint amount
    ) internal virtual {
        uint currentAllowance = _allowances[owner][spender][coinId];
        if (currentAllowance != type(uint).max) {
            require(currentAllowance >= amount, "Bank: insufficient allowance");
            _approve(owner, spender, coinId, currentAllowance - amount);
        }
    }

    function _approve(
        address owner,
        address spender,
        uint coinId,
        uint amount
    ) internal {
        require(owner != address(0), "Bank: Cannot approve from the zero address");
        require(spender != address(0), "Bank: Cannot approve to the zero address");
        _allowances[owner][spender][coinId] = amount;
        emit Approval(owner, spender, coinId, amount);
    }

    function _afterTokenTransfer(
        address,
        address from,
        address to,
        uint[] memory ids,
        uint[] memory amounts,
        bytes memory
    ) internal override {
        uint length = ids.length;

        if (from == address(0)) {
            for (uint i = 0; i < length; i++) {
                _supplies[ids[i]] += amounts[i];
                _supply += amounts[i];
            }
        } else if (to == address(0)) {
            for (uint i = 0; i < length; i++) {
                _supplies[ids[i]] -= amounts[i];
                _supply -= amounts[i];
            }
        }
    }

    constructor() ERC1155() {}
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Bank.sol";

  /*$$$$$   /$$$$$$  /$$$$$$ /$$   /$$  /$$$$$$   /$$$$$$  /$$$$$$$$
 /$$__  $$ /$$__  $$|_  $$_/| $$$ | $$ /$$__  $$ /$$__  $$| $$_____/
| $$  \__/| $$  \ $$  | $$  | $$$$| $$| $$  \ $$| $$  \__/| $$
| $$      | $$  | $$  | $$  | $$ $$ $$| $$$$$$$$| $$ /$$$$| $$$$$
| $$      | $$  | $$  | $$  | $$  $$$$| $$__  $$| $$|_  $$| $$__/
| $$    $$| $$  | $$  | $$  | $$\  $$$| $$  | $$| $$  \ $$| $$
|  $$$$$$/|  $$$$$$/ /$$$$$$| $$ \  $$| $$  | $$|  $$$$$$/| $$$$$$$$
 \______/  \______/ |______/|__/  \__/|__/  |__/ \______/ |_______*/

abstract contract CoinBank is Bank {
    function transferFromDeployed(
        address operator,
        address from,
        address to,
        uint id,
        uint amount
    ) external virtual;

    function approveDeployed(
        address operator,
        address spender,
        uint coinId,
        uint amount
    ) external virtual;
}

contract Coin is IERC20 {
    uint private _coin;
    CoinBank private _bank;

    function id() external view returns (uint) {
        return _coin;
    }

    function bank() external view returns (CoinBank) {
        return _bank;
    }

    function name() external view returns (string memory) {
        return _bank.nameOf(_coin);
    }

    function symbol() external view returns (string memory) {
        return _bank.symbolOf(_coin);
    }

    function decimals() external view returns (uint8) {
        return _bank.decimals();
    }

    function totalSupply() external view returns (uint) {
        return _bank.totalSupplyOf(_coin);
    }

    function balanceOf(address account) external view returns (uint) {
        return _bank.balanceOf(account, _coin);
    }

    function allowance(address account, address spender) external view returns (uint) {
        return _bank.allowance(account, spender, _coin);
    }

    function approve(address spender, uint amount) external returns (bool) {
        _bank.approveDeployed(msg.sender, spender, _coin, amount);
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint amount) external returns (bool) {
        _bank.transferFromDeployed(msg.sender, msg.sender, to, _coin, amount);
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint amount) external returns (bool) {
        _bank.transferFromDeployed(msg.sender, from, to, _coin, amount);
        emit Transfer(from, to, amount);
        return true;
    }

    constructor(CoinBank bank_, uint coin_) {
        _bank = bank_;
        _coin = coin_;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

 /*$$$$$$$ /$$$$$$  /$$   /$$ /$$   /$$ /$$$$$$$
| $$_____//$$__  $$| $$  | $$| $$$ | $$| $$__  $$
| $$     | $$  \ $$| $$  | $$| $$$$| $$| $$  \ $$
| $$$$$  | $$  | $$| $$  | $$| $$ $$ $$| $$  | $$
| $$__/  | $$  | $$| $$  | $$| $$  $$$$| $$  | $$
| $$     | $$  | $$| $$  | $$| $$\  $$$| $$  | $$
| $$     |  $$$$$$/|  $$$$$$/| $$ \  $$| $$$$$$$/
|__/      \______/  \______/ |__/  \__/|______*/

contract Found is Ownable, ERC20 {
    address private _origin;
    uint private _claim;

    event Mint(
        address indexed to,
        uint amount,
        uint timestamp
    );

    event MintAndApprove(
        address indexed to,
        uint amount,
        address indexed spender,
        uint allowance,
        uint timestamp
    );

    event Claim(
        address indexed to,
        uint amount,
        uint timestamp
    );

    event Swap(
        address indexed from,
        address indexed to,
        uint foundAmount,
        uint etherAmount,
        uint timestamp
    );

    function reserves() external view returns (uint) {
        return address(this).balance;
    }

    function convert(uint found) public view returns (uint) {
        uint total = totalSupply();
        if (total == 0) return 0;

        require(total >= found, "Swap exceeds total supply");
        return total - found <= _claim
            ? found * address(this).balance / total
            : found / 10000;
    }

    function swap(address from, address to, uint found) external {
        require(found > 0, "Please swap more than 0");
        uint value = convert(found);

        _burn(from, found);
        (bool success, ) = to.call{value:value}("");
        require(success, "Swap failed");

        emit Swap(
            from,
            to,
            found,
            value,
            block.timestamp
        );
    }

    function mint(address to) external payable {
        uint amount = msg.value * 10000;

        _mint(to, amount);

        emit Mint(
            to,
            amount,
            block.timestamp
        );
    }

    function mintAndApprove(address to, address spender, uint allowance) external payable {
        uint amount = msg.value * 10000;

        _mint(to, amount);
        _approve(msg.sender, spender, allowance);

        emit MintAndApprove(
            to,
            amount,
            spender,
            allowance,
            block.timestamp
        );
    }

    modifier onlyOrigin {
        require(
            msg.sender == owner() || msg.sender == _origin,
            "Caller is not the owner or origin"
        );
        _;
    }

    function claim(address to, uint amount) external onlyOrigin {
        uint limit = (totalSupply() - _claim) / 10;

        require(
            limit >= amount + _claim,
            "Claim exceeds allowance"
        );

        _claim += amount;
        _mint(to, amount);

        emit Claim(
            to,
            amount,
            block.timestamp
        );
    }

    function totalClaim() external view returns (uint) {
        return _claim;
    }

    function origin() external view returns (address) {
        return _origin;
    }

    function setOrigin(address origin_) external onlyOrigin {
        _origin = origin_;
    }

    constructor(address origin_) ERC20("FOUND", "FOUND") {
        _origin = origin_;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)
// Note: removed ERC1155Receiver

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155 {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}