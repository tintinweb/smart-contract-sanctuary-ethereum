/**
 *Submitted for verification at Etherscan.io on 2022-06-11
*/

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

// File: @openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol


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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


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

// File: contracts/Optix.sol


pragma solidity ^0.8.4;







/****************************************************************
* OPTIX by The Blinkless: The Official Currency of New Cornea
* "Soft" stake your favorite NFTs
* code by @digitalkemical
*****************************************************************/

contract Optix is ERC20, ERC20Burnable, Ownable {
    //define a stake structure
    struct Stake{
        address contractAddress;
        address ownerAddress;
        uint startTime;
        uint tokenId;
    }

    //define a collection structure
    struct Collection{
        address contractAddress;
        uint hourlyReward;
    }

    //define variables
    mapping( address => mapping(uint => Stake ) ) public openStakes; //mapping of all open stakes by collection address
    mapping( address => mapping( address => uint[] ) ) public myActiveCollections; //mapping of wallet address to all active collections
    mapping( address => bool ) public hasMigrated; //bool tracker of who has migrated from v1
    Collection[] public collections; //array of NFT collections that can be staked
    address[] public freeCollections; //array of contract addresses for collections with no fee
    address v1ContractAddress = 0xcEE33d20845038Df71B88041B28c3654CF05ae2f; //address to v1 Optix contract (for migration)
    address payoutWallet = 0xeD2faa60373eC70E57B39152aeE5Ce4ed7C333c7; //wallet for payouts
    uint migrationMode = 1; //turn on/off migrations
    uint public thirdPartyFee = 0.001 ether; //fee to charge for 3rd party stakes

    //run on deploy
    constructor() ERC20("Optix", "OPTIX") {}

    /**
    * Owner can mint more tokens
    */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /**
    * Migrate balance from v1 contract
    */
    function migrateFromv1() public{
        require(migrationMode == 1, "Migration period has closed.");
        require(hasMigrated[msg.sender] == false, "You have already migrated.");

         uint oldBalance = IERC20(v1ContractAddress).balanceOf(msg.sender);
       
        hasMigrated[msg.sender] = true;
        _mint(msg.sender, oldBalance + 100000 ether);
        
        
    }


    /**
    * Add a collection to the staking options
    */
    function addCollection(address _contractAddress, uint _hourlyReward) public onlyOwner{
        collections.push(
            Collection(
                _contractAddress,
                _hourlyReward
            )
            );
    }

    /**
    * Update the third party fee
    */
    function updateThirdPartyFee(uint _fee) public onlyOwner{
        thirdPartyFee = _fee;
    }

    /**
    * Update the migration mode
    */
    function updateMigrationMode(uint _migrationMode) public onlyOwner{
        migrationMode = _migrationMode;
    }

    /**
    * Add a collection to free collection list
    */
    function addToFreeCollections(address _contractAddress) public onlyOwner{
        freeCollections.push(_contractAddress);

    }

    /**
    * Update the v1 contract address
    */
    function updateV1Contract(address _v1ContractAddress) public onlyOwner{
        v1ContractAddress = _v1ContractAddress;
    }

    /**
    * Update the payout wallet address
    */
    function updatePayoutWallet(address _payoutWallet) public onlyOwner{
        payoutWallet = _payoutWallet;
    }

    /**
    * Remove a collection from the free collection list
    */
    function removeFreeCollection(address _contractAddress) public onlyOwner{
        uint i = 0;
        while(i < freeCollections.length){
            if(freeCollections[i] == _contractAddress){
                freeCollections[i] = freeCollections[freeCollections.length-1];
                freeCollections.pop();
            }
            i++;
        }
    }

    /**
    * Remove a collection from the staking options
    */
    function removeCollection(address _contractAddress) public onlyOwner{
        uint i = 0;
        while(i < collections.length){
            if(collections[i].contractAddress == _contractAddress){
                collections[i] = collections[collections.length-1];
                collections.pop();
            }
            i++;
        }
    }

    /**
    * Get all available collections
    */
    function getAllCollections() public view returns(Collection[] memory _collections){
        return collections;
    }

    /**
    * Get all free collections
    */
    function getAllFreeCollections() public view returns(address[] memory _collections){
        return freeCollections;
    }

    /**
    * Get a collection
    */
    function getCollection(address _contractAddress) public view returns(Collection memory _collections){
        uint i = 0;
        while(i < collections.length){
            if(collections[i].contractAddress == _contractAddress){
                return collections[i];
            }
            i++;
        }
    }

    /**
    * Open a new soft stake (tokens are never locked)
    */
    function openStake(address _contractAddress, uint[] memory _tokenIds) public payable {
        //check if collection is approved
        require(collectionIsApproved(_contractAddress),"This collection has not been approved.");

        bool isFree = false;
        uint i = 0;
        while(i < freeCollections.length){
            if(freeCollections[i] == _contractAddress){
                isFree = true;
            }
            i++;
        }

        //charge a withdrawal fee for 3rd party collections 
        if(!isFree){
            require(msg.value >= thirdPartyFee * _tokenIds.length, "Insufficient funds to open 3rd-party stake.");
        }

        uint counter = 0;
        while(counter < _tokenIds.length){
            uint _tokenId = _tokenIds[counter];
            //ensure sender is owner of token and collection is approved
            
            require(IERC721(_contractAddress).ownerOf(_tokenId) == msg.sender,"Could not verify ownership!");

            //if trying to open a stake previously owned, update the stake owner
            if(checkForStake(_contractAddress,_tokenId) && openStakes[_contractAddress][_tokenId].ownerAddress != msg.sender){
                updateOwnership( _contractAddress, _tokenId );
            }
            //make sure stake doesn't already exist
            if(!checkForStake(_contractAddress,_tokenId)){
             

                //create a new stake
                openStakes[_contractAddress][_tokenId]=
                    Stake(
                        _contractAddress,
                        msg.sender,
                        block.timestamp,
                        _tokenId
                    )
                ;
                    
                //add collection to active list
                addToActiveList(_contractAddress, _tokenId);
            }

            counter++;
        }
        
    }

    /**
    * Add an active collection to a wallet
    */
    function addToActiveList(address _contractAddress, uint _tokenId) internal {
        uint i = 0;
        bool exists = false;
        while(i < myActiveCollections[msg.sender][_contractAddress].length){
            if(myActiveCollections[msg.sender][_contractAddress][i] == _tokenId){
                exists = true;
            }
            i++;
        }
        //if it doesnt already exist, add it
        if(!exists){
            myActiveCollections[msg.sender][_contractAddress].push(_tokenId);
        }
    }

    /**
    * Get the active list for the wallet by collection contract address
    */
    function getActiveList(address _contractAddress) external view returns(uint[] memory _activeList){
        //get list of active collections for sender
        return myActiveCollections[msg.sender][_contractAddress];
        
    }

    /**
    * Verify that a collection being staked has been approved
    */
    function collectionIsApproved(address _contractAddress) public view returns(bool _approved){
        uint i = 0;
        while(i < collections.length){
            if(collections[i].contractAddress == _contractAddress){
                return true;
            }
            i++;
        }

        return false;
    }

    /**
    * Check if a stake exists already
    */
    function checkForStake(address _contractAddress, uint _tokenId) public view returns(bool _exists){
 
            if(openStakes[_contractAddress][_tokenId].startTime > 0){
                return true;
            }

        return false;
    }

    /**
    * Get a stake
    */
    function getStake(address _contractAddress, uint _tokenId) public view returns(Stake memory _exists){
        return openStakes[_contractAddress][_tokenId];
    }

    /**
    * Calculate stake reward for a token
    */
    function calculateStakeReward(address _contractAddress, uint _tokenId) public view returns(uint _totalReward){
        //get the stake
        Stake memory closingStake = getStake( _contractAddress, _tokenId );
        //get collection data
        Collection memory stakedCollection = getCollection(_contractAddress);
        //calc hours in between start and now
        uint hoursDiff = (block.timestamp - closingStake.startTime) / 60 / 60;
        //calc total reward
        uint totalReward = hoursDiff * stakedCollection.hourlyReward;

        return totalReward;
    }

    /**
    * Close a stake and claim reward
    */
    function closeStake(address _contractAddress, uint[] memory _tokenIds) public payable returns(uint _totalReward){
        
        uint totalReward = 0;
        
        uint counter = 0;
        while(counter < _tokenIds.length){
            uint _tokenId = _tokenIds[counter];

                bool isFree = false;
                uint i2 = 0;
                while(i2 < freeCollections.length){
                    if(freeCollections[i2] == _contractAddress){
                        isFree = true;
                    }
                    i2++;
                }

                //charge a withdrawal fee for 3rd party collections - Blinkless NFTs will be zero
                if(!isFree){
                    require(msg.value >= thirdPartyFee * _tokenIds.length, "Insufficient funds to open 3rd-party stake.");
                }

                if(checkForStake(_contractAddress,_tokenId) && IERC721(_contractAddress).ownerOf(_tokenId) == msg.sender){

                        //calculate end of stake reward
                        totalReward += calculateStakeReward(_contractAddress, _tokenId);

                        //stake has been identified, remove stake
                        delete(openStakes[_contractAddress][_tokenId]);

                        //remove from active list
                        uint i = 0;
                        while(i < myActiveCollections[msg.sender][_contractAddress].length){
                            if(myActiveCollections[msg.sender][_contractAddress][i] == _tokenId){
                                myActiveCollections[msg.sender][_contractAddress][i] = myActiveCollections[msg.sender][_contractAddress][myActiveCollections[msg.sender][_contractAddress].length-1];
                                myActiveCollections[msg.sender][_contractAddress].pop();
                            }
                            i++;
                        }

                }

                counter++;
        }

        //award tokens
        if(totalReward > 0){
            _mint(msg.sender, totalReward);
        }

        return totalReward;
      

    }

    /**
    * Claim rewards from multiple stakes at once without closing 
    */
    function claimWithoutClosing(address _contractAddress, uint[] memory _tokenIds) public returns(uint _totalReward){
        
        uint totalReward = 0;

            uint counter = 0;
            while(counter < _tokenIds.length){
                uint _tokenId = _tokenIds[counter];

                    if(checkForStake(_contractAddress,_tokenId) && IERC721(_contractAddress).ownerOf(_tokenId) == msg.sender){

                            //calculate end of stake reward
                            totalReward += calculateStakeReward(_contractAddress, _tokenId);

                            //stake has been identified, update the timestamp
                            openStakes[_contractAddress][_tokenId].startTime = block.timestamp;

                    }

                counter++;
            }

           

        //award tokens
        if(totalReward > 0){
            _mint(msg.sender, totalReward);
        }

        return totalReward;
      

    }


    /**
    * Claim rewards from all stakes without closing
    */
    function claimAllWithoutClosing() public returns(uint _totalReward){
        
        uint totalReward = 0;
        uint collectionCounter = 0;
        while(collectionCounter < collections.length){
            address _contractAddress = collections[collectionCounter].contractAddress;
            uint[] memory _tokenIds = myActiveCollections[msg.sender][_contractAddress];

            uint counter = 0;
            while(counter < _tokenIds.length){
                uint _tokenId = _tokenIds[counter];

                    if(checkForStake(_contractAddress,_tokenId) && IERC721(_contractAddress).ownerOf(_tokenId) == msg.sender){

                            //calculate end of stake reward
                            totalReward += calculateStakeReward(_contractAddress, _tokenId);

                            //stake has been identified, update the timestamp
                            openStakes[_contractAddress][_tokenId].startTime = block.timestamp;

                    }

                counter++;
            }

            collectionCounter++;

        }

        //award tokens
        if(totalReward > 0){
            _mint(msg.sender, totalReward);
        }

        return totalReward;
      

    }

    /**
    * Update the ownership of a stake to match the NFT owner
    */
    function updateOwnership(address _contractAddress, uint _tokenId) public{
        //get the NFT owner
        address tokenOwner = IERC721(_contractAddress).ownerOf(_tokenId);
        if(openStakes[_contractAddress][_tokenId].ownerAddress != address(0) &&
            openStakes[_contractAddress][_tokenId].ownerAddress != tokenOwner
        ){
            //stake exists, update owner
            uint i = 0;
            while(i < myActiveCollections[openStakes[_contractAddress][_tokenId].ownerAddress][_contractAddress].length){
                if(myActiveCollections[openStakes[_contractAddress][_tokenId].ownerAddress][_contractAddress][i] == _tokenId){
                    //delete active collection
                    myActiveCollections[openStakes[_contractAddress][_tokenId].ownerAddress][_contractAddress][i] = myActiveCollections[openStakes[_contractAddress][_tokenId].ownerAddress][_contractAddress][myActiveCollections[openStakes[_contractAddress][_tokenId].ownerAddress][_contractAddress].length-1];
                    myActiveCollections[openStakes[_contractAddress][_tokenId].ownerAddress][_contractAddress].pop();
                }
                i++;
            }
            //update stake ownership
            myActiveCollections[tokenOwner][_contractAddress].push(_tokenId);
            openStakes[_contractAddress][_tokenId].ownerAddress = tokenOwner;
        }
        
    }



    /*
    * Withdraw by owner
    */
    function withdraw() external onlyOwner {
        (bool success, ) = payable(payoutWallet).call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }


    /*
    * These are here to receive ETH sent to the contract address
    */
    receive() external payable {}

    fallback() external payable {}

}