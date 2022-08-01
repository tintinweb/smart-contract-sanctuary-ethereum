/**
 *Submitted for verification at Etherscan.io on 2022-08-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/*

*/



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

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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



// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


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

/*
                    __________   _____     ______       ____     __________
                   |___    ___| |     \   |   ___|     /    \   |___    ___|
                       |  |     |  |_| |  |  |___     /  /\  \      |  |
                       |  |     |     <   |   ___|   /  ___   \     |  | 
                       |  |     |  |\  \  |  |___   /  /    \  \    |  |
                       |__|     |__| \__\ |______| /__/      \__\   |__|

       _______   __________     ____        __    __    __________   ______   __      ______
     /  ______/ |___    ___|   /    \      |   | /  /  |___    ___| |      \ |  |   /   __   \
    |  /            |  |      /  /\  \     |   |/  /       |  |     |   __  \|  |  /  /    \__|
    |  \___         |  |     /  ___   \    |      <        |  |     |  |  \     | |  |     ____
     \_____  \      |  |    /  /    \  \   |   _   \       |  |     |  |   \    | |  |    |    |
    _______|  |     |  |   /  /      \  \  |  | \   \   ___|  |___  |  |    \   |  \  \ __ /  /
    \________/      |__|  /__/        \__\ |__|   \__\ |__________| |__|     \__|   \ ______ /



                            Contract provided By B.A.S.S Studios 
                            (Blockchain and Software Solutions)
*/

pragma solidity ^0.8.7;

//Tasties NFT Staking 

interface INFTContract {
    function balanceOf(address _user) external view returns (uint256);
  
}

contract stakingTastiesNFT is ERC20Burnable, Ownable {

    uint256 public constant NFT_BASE_RATE = 10000000000000000000; // 10 per Day
    address public constant NFT_ADDRESS = 0xd4d1f32c280056f107AD4ADf8e16BC02f2C5B339;//TastiesNFT Collection

    bool public stakingLive = false;
    bool public airdropToAll=true;
    bool public returnLock=false;

    mapping(uint256 => uint256) internal NftTokenIdTimeStaked;
    mapping(uint256 => address) internal NftTokenIdToStaker;
    mapping(address => uint256[]) internal stakerToNftTokenIds;
    //map token id to bool for if staked //fb
    mapping(uint256=>bool) public nftStaked;

    //trait type mapping token id to traid type   //fb
    //Trait types 1,2,3,4,5,6
    mapping(uint256 => uint256) private _traitType;

    //uint type multipliers to implement different payouts for different trait rarities (value must be 10x percentage desired)
    uint256 type1Multiplier=10;
    uint256 type2Multiplier=12;
    uint256 type3Multiplier=14;
    uint256 type4Multiplier=20;
    uint256 type5Multiplier=30;
    uint256 type6Multiplier=200;
    
    IERC721Enumerable private constant _NftIERC721 = IERC721Enumerable(NFT_ADDRESS);


    constructor() ERC20("Treat Token", "TREAT") {
    }

    function getTokenIDsStaked(address staker) public view returns (uint256[] memory) {
        return stakerToNftTokenIds[staker];
    }
    
    function getStakedCount(address staker) public view returns (uint256) {
        return stakerToNftTokenIds[staker].length;
    }

    function removeSpecificTokenIdFromArray(uint256[] storage array, uint256 tokenId) internal {
        uint256 length = array.length;
        for (uint256 i = 0; i < length; i++) {
            if (array[i] == tokenId) {
                length--;
                if (i < length) {
                    array[i] = array[length];
                }
                array.pop();
                break;
            }
        }
    }
// covers single staking and multiple
    function stakeNftsByTokenIds(uint256[] memory tokenIds) public  {
     require(stakingLive, "STAKING NOT LIVE");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            require(_NftIERC721.ownerOf(id) == msg.sender && NftTokenIdToStaker[id] == address(0), "TOKEN NOT YOURS");
            //NFT transfer 
            _NftIERC721.transferFrom(msg.sender, address(this), id);
            //Track data
            stakerToNftTokenIds[msg.sender].push(id);
            NftTokenIdTimeStaked[id] = block.timestamp;
            NftTokenIdToStaker[id] = msg.sender;
            nftStaked[id]=true;
        }
       
    }
// unstake and claims for tokens

    function unstakeAll() public {
        require(getStakedCount(msg.sender) > 0, "Need at least 1 staked to unstake");
        uint256 totalRewards = 0;

        for (uint256 i = stakerToNftTokenIds[msg.sender].length; i > 0; i--) {
            uint256 tokenId = stakerToNftTokenIds[msg.sender][i - 1];

            _NftIERC721.transferFrom(address(this), msg.sender, tokenId);
            //add calculated value of the token id by its type //fb
            totalRewards += calculateRewardsByTokenId(tokenId);
            //pop used to save more gas and counting from end of the stored ids to index 0 //fb
            stakerToNftTokenIds[msg.sender].pop();
            NftTokenIdToStaker[tokenId] = address(0);
            nftStaked[tokenId]=false;
            //after gathering total rewards set token token id time staked to 0 //fb
            NftTokenIdTimeStaked[tokenId] = 0;
        }
        _mint(msg.sender, totalRewards);
    }

    function unstakeNftsByTokenIds(uint256[] memory tokenIds) public {
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            require(NftTokenIdToStaker[id] == msg.sender, "NOT the staker");

            _NftIERC721.transferFrom(address(this), msg.sender, id);
             //add calculated value of the token id by its type //fb
            totalRewards += calculateRewardsByTokenId(id);
            //remove specific id from stored ids (less gas efficient than unstake all   //fb
            removeSpecificTokenIdFromArray(stakerToNftTokenIds[msg.sender], id);
            NftTokenIdToStaker[id] = address(0);
             nftStaked[id]=false;
             //after gathering total rewards set token id time staked to 0 //fb
            NftTokenIdTimeStaked[id] = 0;
        }

        _mint(msg.sender, totalRewards);
      
    }
    

    function claimTokensByTokenId(uint256 tokenId) public {
        require(NftTokenIdToStaker[tokenId] == msg.sender, "NOT the staker");
          //add calculated value of the token id by its type //fb
        _mint(msg.sender, (calculateRewardsByTokenId(tokenId)));
        NftTokenIdTimeStaked[tokenId] = block.timestamp;
    }
    
   
    function claimAllTokens() public {
        uint256 totalRewards = 0;

        uint256[] memory TokenIds = stakerToNftTokenIds[msg.sender];
        for (uint256 i = 0; i < TokenIds.length; i++) {
            uint256 id = TokenIds[i];
            require(NftTokenIdToStaker[id] == msg.sender, "NOT_STAKED_BY_YOU");
             //add calculated value of the token id by its type //fb
            totalRewards += calculateRewardsByTokenId(id);
            NftTokenIdTimeStaked[id] = block.timestamp;
        }
        
        
        _mint(msg.sender, totalRewards);
    }
//returning the total reward payout per address
    function getAllRewards(address staker) public view returns (uint256) {
        uint256 totalRewards = 0;
        uint256[] memory tokenIds = stakerToNftTokenIds[staker];
        for (uint256 i = 0; i < tokenIds.length; i++) {
             //add calculated value of the token id by its type //fb
            totalRewards += (calculateRewardsByTokenId(tokenIds[i]));
        } 
      

        return totalRewards;
    }

    function getRewardsByNftTokenId(uint256 tokenId) public view returns (uint256) {
        require(NftTokenIdToStaker[tokenId] != address(0), "TOKEN_NOT_STAKED");

          //add calculated value of the token id by its type //fb
        return calculateRewardsByTokenId(tokenId);
    }
    

    function getNftStaker(uint256 tokenId) public view returns (address) {
        return NftTokenIdToStaker[tokenId];
    }
    
    //return public is token id staked in contract
    function isStaked(uint256 tokenId) public view returns (bool) {
        return(nftStaked[tokenId]);
    }

    function toggle() external onlyOwner {
        stakingLive = !stakingLive;
    }

  //trait rarity list fuctions
  //set single token id type for multiplier fixes or possible future rewarding of specific tokens
  function setTypeList(uint256 tokenIdTemp, uint256 typeNumber) external onlyOwner {
       
            _traitType[tokenIdTemp] = typeNumber;
           
    }
  //set a full tokenId to type list can only map to one type at a time (maps all in list to the same trait number)
  function setFullTypeList(uint[] calldata idList, uint256 traitNum) external onlyOwner {
    for (uint256 i = 0; i < idList.length; i++) {
        _traitType[idList[i]] = traitNum;
    
    }
    
 }
//reward calculation multiplier applied before reaking down to a a daily value
  function calculateRewardsByTokenId(uint256 givenId) public view returns (uint256 _rewards){

       uint256 totalRewards = 0; 
       uint256 tempRewards=(block.timestamp -NftTokenIdTimeStaked[givenId]);
            if(_traitType[givenId]==1){
                tempRewards = (tempRewards* type1Multiplier)/10;
            }
             if(_traitType[givenId]==2){
                tempRewards = (tempRewards* type2Multiplier)/10;
            }
             if(_traitType[givenId]==3){
                tempRewards = (tempRewards* type3Multiplier)/10;
            }
             if(_traitType[givenId]==4){
                tempRewards = (tempRewards* type4Multiplier)/10;
            }
             if(_traitType[givenId]==5){
                tempRewards = (tempRewards* type5Multiplier)/10;
            }
                if(_traitType[givenId]==6){
                tempRewards = (tempRewards* type6Multiplier)/10;
            }
      totalRewards += ((tempRewards* NFT_BASE_RATE/86400));
      return(totalRewards);

  }
//return the trait type of the token id (returned value must be divided by 10 with 1 decimal place to get correct value)
 function getTypeByTokenId(uint256 givenId) public view returns (uint256 _rewards){

            if(_traitType[givenId]==1){
               return type1Multiplier;
            }
             if(_traitType[givenId]==2){
                return type2Multiplier;
            }
             if(_traitType[givenId]==3){
               return type3Multiplier;
            }
             if(_traitType[givenId]==4){
               return type4Multiplier;
            }
             if(_traitType[givenId]==5){
                return type5Multiplier;
            }
                if(_traitType[givenId]==6){
                return type6Multiplier;
            }

  }
//type multipliers access functions
    function setType1Multiplier(uint256 _newMultiplier) external onlyOwner{
        type1Multiplier=_newMultiplier;
    }
        function setType2Multiplier(uint256 _newMultiplier) external onlyOwner{
        type2Multiplier=_newMultiplier;
    }
        function setType3Multiplier(uint256 _newMultiplier) external onlyOwner{
        type3Multiplier=_newMultiplier;
    }
        function setType4Multiplier(uint256 _newMultiplier) external onlyOwner{
        type4Multiplier=_newMultiplier;
    }
        function setType5Multiplier(uint256 _newMultiplier) external onlyOwner{
        type5Multiplier=_newMultiplier;
    }
        function setType6Multiplier(uint256 _newMultiplier) external onlyOwner{
        type6Multiplier=_newMultiplier;
    }

//Return All Staked (emergency use to return all holders assets) use of this function may require redeployment
//NOTE this function does not remove token ids from the stakers array of staked tokens
//NOTE block time stamp is also not reset
//NOTE token id staker address not reset to address 0
//NOTE nft staked bool not reset to false
    function ReturnAllStakedNFTs() external payable onlyOwner{
    require(returnLock==true,"lock is on");
    uint256 currSupply=_NftIERC721.totalSupply();
        for(uint256 i=0;i<currSupply;i++){
            if(nftStaked[i]==true){
                 address sendAddress= NftTokenIdToStaker[i];
                _NftIERC721.transferFrom(address(this), sendAddress, i);
          
            }
        }
    }

//return lock change
    function returnLockToggle() public onlyOwner{
        returnLock=!returnLock;
    }
//only owner mint 
 function MintTokensOwner(address[] memory holders, uint256 amount) public onlyOwner {
  
        uint256 totalRewards=amount;
        for(uint256 i=0;i<holders.length;i++){
         _mint(holders[i], totalRewards);

        }
    }

//airdrop toggle
    function airdropToggle(bool choice)public onlyOwner{
        airdropToAll=choice;
    }
//airdrop to all holders
    function AirdropToHolders(uint256 tokenAmount) public payable onlyOwner{
        uint256 totalAmount= _NftIERC721.totalSupply();
        if(airdropToAll==true){
        for(uint256 j=0;j<totalAmount;j++){
            address ownerCurr =_NftIERC721.ownerOf(j);
            _mint(ownerCurr,tokenAmount);
        }
        }
        //airdrop to staked holders only
        if(airdropToAll==false){
        for(uint256 k=0; k<totalAmount;k++){
            if(nftStaked[k]==true){
                address ownerCurrent =_NftIERC721.ownerOf(k);
                _mint(ownerCurrent,tokenAmount);
            }
        }
        }
    }



}