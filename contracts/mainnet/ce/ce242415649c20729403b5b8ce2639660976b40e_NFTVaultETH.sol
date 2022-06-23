/**
 *Submitted for verification at Etherscan.io on 2022-06-23
*/

// File: contracts/IWETH9.sol

// contracts/IEIP4626.sol

// Teahouse Finance

pragma solidity ^0.8.0;

interface IWETH9 {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);

    function deposit() external payable;
    function withdraw(uint wad) external;

}

// File: contracts/IEIP4626.sol

// contracts/IEIP4626.sol

// Teahouse Finance

pragma solidity ^0.8.0;

interface IEIP4626 {

    function asset() external view returns (address assetTokenAddress);
    function totalAssets() external view returns (uint256 totalManagedAssets);

    function convertToShares(uint256 assets) external view returns (uint256 shares);
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    function maxDeposit(address receiver) external view returns (uint256 maxAssets);
    function previewDeposit(uint256 assets) external view returns (uint256 shares);
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    function maxMint(address receiver) external view returns (uint256 maxShares);
    function previewMint(uint256 shares) external view returns (uint256 assets);
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    function maxWithdraw(address owner) external view returns (uint256 maxAssets);
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);

    function maxRedeem(address owner) external view returns (uint256 maxShares);
    function previewRedeem(uint256 shares) external view returns (uint256 assets);
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);

    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);
    event Withdraw(address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares);

}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
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
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
        }
        _balances[to] += amount;

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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/NFTVault.sol

// contracts/NFTVault.sol

// Teahouse Finance

pragma solidity ^0.8.0;








error ReceiverDoNotHasNFT();
error NFTNotEnabled();
error IncorrectReceiverAddress();
error IncorrectFundStage();
error ExceedMaxSupply();
error IncorrectFundValue();

/// @title A crowd funding vault for NFT investments
/// @author Teahouse Finance
contract NFTVault is Ownable, ReentrancyGuard, ERC20, IEIP4626 {

    using SafeERC20 for IERC20;

    /// @notice funding stages
    /// @notice Funding: initial funding stage, available for depositing
    /// @notice Onging: investment stage, not available for both depositing and withdrawal
    /// @notice Closed: closed stage, available for withdrawal
    enum FundStages { Funding, Ongoing, Closed }

    address internal assetToken;

    uint256 public initialPrice;
    uint256 public priceDenominator;
    uint256 public maxSupply;
    uint256 internal nominalValue;

    address[] public nftEnabled;
    FundStages public fundStage;

    event NFTEnabled(address indexed caller, address[] nfts);
    event FundFunding(address indexed caller, uint256 initialPrice, uint256 priceDenominator, uint256 maxSupply);
    event FundOngoing(address indexed caller, address indexed receiver, uint256 initialFundValue);
    event FundClosed(address indexed caller, uint256 finalFundValue);
    event FundValueChanged(address indexed caller, uint256 nominalValue);

    /// @param _name name of the vault token
    /// @param _symbol symbol of the vault token
    /// @param _asset address of the asset token
    /// @param _initialPrice initial price for each vault token in asset token
    /// @param _priceDenominator price denominator (actual price = _initialPrice / _priceDenominator)
    /// @param _maxSupply max supply of vault token
    constructor(
        string memory _name,
        string memory _symbol,
        address _asset,
        uint256 _initialPrice,
        uint256 _priceDenominator,
        uint256 _maxSupply)
        ERC20(_name, _symbol) {
        assetToken = _asset;
        initialPrice = _initialPrice;
        priceDenominator = _priceDenominator;
        maxSupply = _maxSupply;

        fundStage = FundStages.Funding;

        emit FundFunding(msg.sender, _initialPrice, _priceDenominator, _maxSupply);
    }

    /// @notice Set the list of NFTs for allowing depositing
    /// @param _nfts addresses of the NFTs
    function setEnabledNFTs(address[] memory _nfts) external onlyOwner {
        nftEnabled = _nfts;

        emit NFTEnabled(msg.sender, _nfts);
    }

    /// @notice Enter "Ongoing" stage.
    /// @notice can only do so when in "Funding" stage
    /// @notice will withdraw all asset tokens from the vault
    /// @param _receiver address to receive funds
    function enterOngoingStage(address _receiver) external nonReentrant onlyOwner {
        if (_receiver == address(0)) revert IncorrectReceiverAddress();
        if (fundStage != FundStages.Funding) revert IncorrectFundStage();

        uint256 balance = IERC20(assetToken).balanceOf(address(this));
        IERC20(assetToken).safeTransfer(_receiver, balance);
        fundStage = FundStages.Ongoing;

        emit FundOngoing(msg.sender, _receiver, nominalValue);
    }

    /// @notice Enter "Closed" stage.
    /// @notice will transfer asset tokens to the vault
    /// @param _finalFundValue final fund value in asset token
    /// @notice if going directly from "Funding" stages to "Closed" stages, _finalFundValue must be 0
    function enterClosedStage(uint256 _finalFundValue) external nonReentrant onlyOwner {
        if (fundStage == FundStages.Closed) revert IncorrectFundStage();
        
        if (fundStage == FundStages.Ongoing) {
            IERC20(assetToken).safeTransferFrom(msg.sender, address(this), _finalFundValue);
            nominalValue = _finalFundValue;
        }
        else {
            if (_finalFundValue != 0) revert IncorrectFundValue();
        }

        fundStage = FundStages.Closed;

        emit FundClosed(msg.sender, nominalValue);
    }

    /// @notice Update current nominalValue, for displying purpose only
    /// @notice only works in "Ongoing" stage
    /// @param _nominalValue nominal value in asset tokens
    function updateNominalValue(uint256 _nominalValue) external onlyOwner {
        if (fundStage != FundStages.Ongoing) revert IncorrectFundStage();

        nominalValue = _nominalValue;

        emit FundValueChanged(msg.sender, nominalValue);
    }

    /// @return assetTokenAddress address of the asset token
    function asset() external override view returns (address assetTokenAddress) {
        return assetToken;
    }

    /// @return totalManagedAssets amount of asset tokens under management
    function totalAssets() external override view returns (uint256 totalManagedAssets) {
        return nominalValue;
    }

    /// @notice convert amount of assets to shares
    /// @param _assets amount of asset tokens
    /// @return shares amount of vault tokens
    function convertToShares(uint256 _assets) external override view returns (uint256 shares) {
        if (totalSupply() == 0) {
            // no assets deposited, use initialPrice
            return _assets * priceDenominator / initialPrice;
        }
        else {
            return totalSupply() * _assets / nominalValue;
        }
    }

    /// @notice convert amount of shares to assets
    /// @param _shares amount of vault tokens
    /// @return assets amount of asset tokens
    function convertToAssets(uint256 _shares) external override view returns (uint256 assets) {
        if (totalSupply() == 0) {
            // no assets deposited, use initialPrice
            return _shares * initialPrice / priceDenominator;
        }
        else {
            return (nominalValue * _shares) / totalSupply();
        }
    }

    /// @notice Get maximum amount of asset tokens possible for deposit
    /// @param _receiver address of the receiver
    /// @return maxAssets maximum amount of assets allowed to be deposited
    function maxDeposit(address _receiver) external override view returns (uint256 maxAssets) {
        if (fundStage != FundStages.Funding) {
            return 0;
        }

        if (!_hasNFT(_receiver)) {
            // can't deposit if _receiver has no NFT
            return 0;
        }

        return (maxSupply - totalSupply()) * initialPrice / priceDenominator;
    }

    /// @notice Preview how much vault tokens will be received when depositing
    /// @param _assets amount of asset tokens to deposit
    /// @return shares estimated amount of vault tokens received
    function previewDeposit(uint256 _assets) public override view returns (uint256 shares) {
        if (fundStage != FundStages.Funding) revert IncorrectFundStage();

        return _assets * priceDenominator / initialPrice;           // round down
    }

    /// @notice Deposit into the vault
    /// @notice only works in "Funding" stage
    /// @param _assets amount of asset tokens to deposit
    /// @param _receiver address of the receiver
    /// @return shares amount of vault tokens received
    function deposit(uint256 _assets, address _receiver) external override nonReentrant returns (uint256 shares) {
        shares = previewDeposit(_assets);
        _internalMint(shares, _assets, true, _receiver);
    }

    /// @notice Get maximum amount of vault tokens possible for deposit
    /// @param _receiver address of the receiver
    /// @return maxShares maximum amount of vault tokens allowed to be received
    function maxMint(address _receiver) external override view returns (uint256 maxShares) {
        if (fundStage != FundStages.Funding) {
            return 0;
        }

        if (!_hasNFT(_receiver)) {
            // can't deposit if _receiver has no NFT
            return 0;
        }

        return maxSupply - totalSupply();
    }

    /// @notice Preview how much asset tokens will be required when depositing
    /// @param _shares amount of vault tokens to receive
    /// @return assets estimated amount of asset tokens required
    function previewMint(uint256 _shares) public override view returns (uint256 assets) {
        if (fundStage != FundStages.Funding) revert IncorrectFundStage();

        return (_shares * initialPrice + priceDenominator - 1) / priceDenominator;      // round up
    }

    /// @notice Deposit into the vault
    /// @notice only works in "Funding" stage
    /// @param _shares amount of vault tokens to receive
    /// @param _receiver address of the receiver
    /// @return assets amount of asset tokens required
    function mint(uint256 _shares, address _receiver) external override nonReentrant returns (uint256 assets) {
        assets = previewMint(_shares);
        _internalMint(_shares, assets, true, _receiver);
    }

    /// @notice Get maximum amount of assets tokens possible for withdrawal
    /// @param _owner address of the owner
    /// @return maxAssets maximum amount of asset tokens can be received from withdrawal
    function maxWithdraw(address _owner) external override view returns (uint256 maxAssets) {
        if (fundStage != FundStages.Closed) {
            return 0;
        }

        return balanceOf(_owner) * nominalValue / totalSupply();
    }

    /// @notice Preview how much vault tokens will be required when withdrawing
    /// @param _assets amount of asset tokens to receive
    /// @return shares estimated amount of vault tokens required
    function previewWithdraw(uint256 _assets) public override view returns (uint256 shares) {
        if (fundStage != FundStages.Closed) revert IncorrectFundStage();

        return (totalSupply() * _assets + nominalValue - 1) / nominalValue;
    }

    /// @notice Withdraw from the vault
    /// @notice only works in "Closed" stage
    /// @param _assets amount of asset tokens to receive
    /// @param _receiver address of the receiver
    /// @param _owner address of the owner
    /// @return shares amount of vault tokens required
    /// @notice if the caller is not owner, owner must approved the caller for spending the vault tokens
    function withdraw(uint256 _assets, address _receiver, address _owner) external override nonReentrant returns (uint256 shares) {
        shares = previewWithdraw(_assets);
        _internalRedeem(shares, _assets, true, _receiver, _owner);
    }

    /// @notice Get maximum amount of vault tokens possible for withdrawal
    /// @param _owner address of the owner
    /// @return maxShares maximum amount of vault tokens allowed for withdrawal
    function maxRedeem(address _owner) external override view returns (uint256 maxShares) {
        if (fundStage != FundStages.Closed) {
            return 0;
        }

        return balanceOf(_owner);
    }

    /// @notice Preview how much asset tokens will be received from withdrawing
    /// @param _shares amount of vault tokens to withdraw
    /// @return assets estimated amount of asset tokens received
    function previewRedeem(uint256 _shares) public override view returns (uint256 assets) {
        if (fundStage != FundStages.Closed) revert IncorrectFundStage();

        return (nominalValue * _shares) / totalSupply();
    }

    /// @notice Withdraw from the vault
    /// @notice only works in "Closed" stage
    /// @param _shares amount of vault tokens to withdraw
    /// @param _receiver address of the receiver
    /// @param _owner address of the owner
    /// @return assets amount of asset tokens received
    /// @notice if the caller is not owner, owner must approved the caller for spending the vault tokens
    function redeem(uint256 _shares, address _receiver, address _owner) external override nonReentrant returns (uint256 assets) {
        assets = previewRedeem(_shares);
        _internalRedeem(_shares, assets, true, _receiver, _owner);
    }

    /// @notice internal mint helper
    /// @param _shares vault tokens to mint
    /// @param _assets asset tokens used for minting
    /// @param _transfer true to transfer the asset tokens, false if no transfer is needed
    /// @param _receiver address of the receiver
    function _internalMint(uint256 _shares, uint256 _assets, bool _transfer, address _receiver) internal {
        if (fundStage != FundStages.Funding) revert IncorrectFundStage();
        if (!_hasNFT(_receiver)) revert ReceiverDoNotHasNFT();
        if (_shares + totalSupply() > maxSupply) revert ExceedMaxSupply();

        if (_transfer) {
            IERC20(assetToken).safeTransferFrom(msg.sender, address(this), _assets);   
        }

        _mint(_receiver, _shares);
        nominalValue += _shares * initialPrice / priceDenominator;
        emit Deposit(msg.sender, _receiver, _assets, _shares);
    }

    /// @notice internal redeem helper
    /// @param _shares vault tokens to redeem
    /// @param _assets asset tokens received for redeeming
    /// @param _transfer true to transfer the asset tokens, false if no transfer is needed
    /// @param _receiver address of the receiver
    /// @param _owner address of the owner
    function _internalRedeem(uint256 _shares, uint256 _assets, bool _transfer, address _receiver, address _owner) internal {
        if (_receiver == address(0)) revert IncorrectReceiverAddress();
        if (fundStage != FundStages.Closed) revert IncorrectFundStage();
        if (_owner != msg.sender) {
            _spendAllowance(_owner, msg.sender, _shares);
        }

        _burn(_owner, _shares);
        nominalValue -= _assets;

        if (_transfer) {
            IERC20(assetToken).safeTransfer(_receiver, _assets);   
        }

        emit Withdraw(msg.sender, _receiver, _owner, _assets, _shares);
    }

    /// @notice internal NFT checker
    /// @param _receiver address of the receiver
    /// @return hasNFT true if the receiver has at least one of the NFT, false if not
    function _hasNFT(address _receiver) internal view returns (bool hasNFT) {
        uint256 i;
        for (i = 0; i < nftEnabled.length; i++) {
            if (IERC721(nftEnabled[i]).balanceOf(_receiver) > 0) {
                break;
            }
        }

        return i < nftEnabled.length;
    }
}

// File: contracts/NFTVaultETH.sol

// contracts/NFTVaultETH.sol

// Teahouse Finance

pragma solidity ^0.8.0;




error AssetNotWETH9();
error NotEnoughETH();
error NotAcceptingETH();

/// @title A crowd funding vault for NFT investments accepting ETH
/// @notice using WETH as the ERC20 token
/// @author Teahouse Finance
contract NFTVaultETH is NFTVault {

    constructor(
        string memory _name,
        string memory _symbol,
        address _weth9,
        uint256 _initialPrice,
        uint256 _priceDenominator,
        uint256 _maxSupply)
        NFTVault(_name, _symbol, _weth9, _initialPrice, _priceDenominator, _maxSupply) {
        // check _weth9 is actually WETH
        if (keccak256(abi.encode(IWETH9(_weth9).symbol())) != keccak256(abi.encode("WETH"))) revert AssetNotWETH9();
    }

    receive() external payable {
        // only accepts ETH from weth9
        if (msg.sender != assetToken) revert NotAcceptingETH();
    }

    /// @notice Enter "Ongoing" stage, using ETH
    /// @notice can only do so when in "Funding" stage
    /// @notice will withdraw all asset tokens and convert to ETH from the vault
    /// @param _receiver address to receive funds
    function enterOngoingStageETH(address payable _receiver) external nonReentrant onlyOwner {
        if (_receiver == address(0)) revert IncorrectReceiverAddress();
        if (fundStage != FundStages.Funding) revert IncorrectFundStage();

        uint256 balance = IERC20(assetToken).balanceOf(address(this));
        IWETH9(assetToken).withdraw(balance);
        Address.sendValue(_receiver, balance);
        fundStage = FundStages.Ongoing;

        emit FundOngoing(msg.sender, _receiver, nominalValue);
    }

    /// @notice Enter "Closed" stage.
    /// @notice will transfer ETH to the vault and convert to asset token
    /// @param _finalFundValue final fund value in ETH
    /// @notice if going directly from "Funding" stages to "Closed" stages, _finalFundValue must be 0
    function enterClosedStageETH(uint256 _finalFundValue) external payable nonReentrant onlyOwner {
        if (fundStage == FundStages.Closed) revert IncorrectFundStage();

        if (fundStage == FundStages.Ongoing) {
            if (msg.value != _finalFundValue) revert NotEnoughETH();
            IWETH9(assetToken).deposit{ value: msg.value }();
            nominalValue = _finalFundValue;
        }
        else {
            if (_finalFundValue != 0 || msg.value != 0) revert IncorrectFundValue();
        }
    
        fundStage = FundStages.Closed;

        emit FundClosed(msg.sender, nominalValue);
    }    

    /// @notice Deposit into the vault, in ETH
    /// @notice only works in "Funding" stage
    /// @param _assets amount of ETH to deposit
    /// @param _receiver address of the receiver
    /// @return shares amount of vault tokens received
    function depositETH(uint256 _assets, address _receiver) external payable nonReentrant returns (uint256 shares) {
        if (msg.value != _assets) revert NotEnoughETH();
        IWETH9(assetToken).deposit{ value: msg.value }();
        shares = previewDeposit(_assets);
        _internalMint(shares, _assets, false, _receiver);
    }

    /// @notice Deposit into the vault, in ETH
    /// @notice only works in "Funding" stage
    /// @param _shares amount of vault tokens to receive
    /// @param _receiver address of the receiver
    /// @return assets amount of asset tokens required
    function mintETH(uint256 _shares, address _receiver) external payable nonReentrant returns (uint256 assets) {
        assets = previewMint(_shares);
        if (msg.value < assets) revert NotEnoughETH();
        uint256 remain = msg.value - assets;
        if (remain > 0) {
            // send remaining ETH back to the sender
            Address.sendValue(payable(msg.sender), remain);
        }

        IWETH9(assetToken).deposit{ value: assets }();       
        _internalMint(_shares, assets, false, _receiver);
    }

    /// @notice Withdraw from the vault, in ETH
    /// @notice only works in "Closed" stage
    /// @param _assets amount of asset tokens to receive
    /// @param _receiver address of the receiver
    /// @param _owner address of the owner
    /// @return shares amount of vault tokens required
    /// @notice if the caller is not owner, owner must approved the caller for spending the vault tokens
    function withdrawETH(uint256 _assets, address payable _receiver, address _owner) external nonReentrant returns (uint256 shares) {
        shares = (totalSupply() * _assets + nominalValue - 1) / nominalValue;
        _internalRedeem(shares, _assets, false, _receiver, _owner);
        IWETH9(assetToken).withdraw(_assets);
        Address.sendValue(_receiver, _assets);
    }

    /// @notice Withdraw from the vault, in ETH
    /// @notice only works in "Closed" stage
    /// @param _shares amount of vault tokens to withdraw
    /// @param _receiver address of the receiver
    /// @param _owner address of the owner
    /// @return assets amount of asset tokens received
    /// @notice if the caller is not owner, owner must approved the caller for spending the vault tokens
    function redeemETH(uint256 _shares, address payable _receiver, address _owner) external nonReentrant returns (uint256 assets) {
        assets = (nominalValue * _shares) / totalSupply();
        _internalRedeem(_shares, assets, false, _receiver, _owner);
        IWETH9(assetToken).withdraw(assets);
        Address.sendValue(_receiver, assets);
    }
}