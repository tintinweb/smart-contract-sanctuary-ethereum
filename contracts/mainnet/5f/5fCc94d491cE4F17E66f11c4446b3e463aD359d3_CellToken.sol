/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;



// Part: OpenZeppelin/[email protected]/Context

/*
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

// Part: OpenZeppelin/[email protected]/IERC165

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

// Part: OpenZeppelin/[email protected]/IERC20

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// Part: OpenZeppelin/[email protected]/IERC20Metadata

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

// Part: OpenZeppelin/[email protected]/IERC721

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// Part: OpenZeppelin/[email protected]/Ownable

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// Part: OpenZeppelin/[email protected]/ERC20

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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

// Part: OpenZeppelin/[email protected]/IERC721Enumerable

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// Part: ISheetFighterToken

interface ISheetFighterToken is IERC721Enumerable {

    /// @notice Update the address of the CellToken contract
    /// @param _contractAddress Address of the CellToken contract
    function setCellTokenAddress(address _contractAddress) external;

    /// @notice Update the address which signs the mint transactions
    /// @dev    Used for ensuring GPT-3 values have not been altered
    /// @param  _mintSigner New address for the mintSigner
    function setMintSigner(address _mintSigner) external;

    /// @notice Update the address of the bridge
    /// @dev Used for authorization
    /// @param  _bridge New address for the bridge
    function setBridge(address _bridge) external;

    /// @dev Withdraw funds as owner
    function withdraw() external;

    /// @notice Set the sale state: options are 0 (closed), 1 (presale), 2 (public sale) -- only owner can call
    /// @dev    Implicitly converts int argument to TokenSaleState type -- only owner can call
    /// @param  saleStateId The id for the sale state: 0 (closed), 1 (presale), 2 (public sale)
    function setSaleState(uint256 saleStateId) external;

    /// @notice Mint up to 20 Sheet Fighters
    /// @param  numTokens Number of Sheet Fighter tokens to mint (1 to 20)
    function mint(uint256 numTokens) external payable;

    /// @notice "Print" a Sheet. Adds GPT-3 flavor text and attributes
    /// @dev    This function requires signature verification
    /// @param  _tokenIds Array of tokenIds to print
    /// @param  _flavorTexts Array of strings with flavor texts concatonated with a pipe character
    /// @param  _signature Signature verifying _flavorTexts are unmodified
    function print(
        uint256[] memory _tokenIds,
        string[] memory _flavorTexts,
        bytes memory _signature
    ) external;

    /// @notice Bridge the Sheets
    /// @dev Transfers Sheets to bridge
    /// @param tokenOwner Address of the tokenOwner who is bridging their tokens
    /// @param tokenIds Array of tokenIds that tokenOwner is bridging
    function bridgeSheets(address tokenOwner, uint256[] calldata tokenIds) external;

    /// @notice Update the sheet to sync with actions that occured on otherside of bridge
    /// @param tokenId Id of the SheetFighter
    /// @param HP New HP value
    /// @param luck New luck value
    /// @param heal New heal value
    /// @param defense New defense value
    /// @param attack New attack value
    function syncBridgedSheet(
        uint256 tokenId,
        uint8 HP,
        uint8 luck,
        uint8 heal,
        uint8 defense,
        uint8 attack
    ) external;

    /// @notice Return true if token is printed, false otherwise
    /// @param _tokenId Id of the SheetFighter NFT
    /// @return bool indicating whether or not sheet is printed
    function isPrinted(uint256 _tokenId) external view returns(bool);

    /// @notice Returns the token metadata and SVG artwork
    /// @dev    This generates a data URI, which contains the metadata json, encoded in base64
    /// @param _tokenId The tokenId of the token whos metadata and SVG we want
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

// Part: OpenZeppelin/[email protected]/ERC20Burnable

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
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}

// File: CellToken.sol

/// @title  Contract creating fungible in-game utility tokens for the Sheet Fighter game
/// @author Overlord Paper Co
/// @notice This defines in-game utility tokens that are used for the Sheet Fighter game
/// @notice This contract is HIGHLY adapted from the Anonymice $CHEETH contract
/// @notice Thank you MouseDev for writing the original $CHEETH contract!
contract CellToken is ERC20Burnable, Ownable {

    uint256 public constant MAX_WALLET_STAKED = 10;
    uint256 public constant EMISSIONS_RATE = 115_740_740_740_741; // 10 $CELL per day = (10*1e18)/(60*60*24)
    uint256 public constant MAX_CELL = 1e26;

    /// @notice Address of SheetFighterToken contract
    address public sheetFighterTokenAddress;

    /// @notice Map SheetFighter id to timestamp staked
    mapping(uint256 => uint256) public tokenIdToTimeStamp;

    /// @notice Map SheetFighter id to staker's address
    mapping(uint256 => address) public tokenIdToStaker;

    /// @notice Map staker's address to array the ids of all the SheetFighters they're staking
    mapping(address => uint256[]) public stakerToTokenIds;

    /// @notice Address of the Polygon bridge
    address public bridge;

    /// @notice Construct CellToken contract for the in-game utility token for the Sheet Fighter game
    /// @dev    Set sheetFighterTokenAddress, ERC20 name and symbol, and implicitly execute Ownable contructor
    constructor(address _sheetFighterTokenAddress) ERC20('Cell', 'CELL') Ownable() {
        sheetFighterTokenAddress = _sheetFighterTokenAddress;
    }

    /// @notice Update the address of the SheetFighterToken contract
    /// @param _contractAddress Address of the SheetFighterToken contract
    function setSheetFighterTokenAddress(address _contractAddress) external onlyOwner {
        sheetFighterTokenAddress = _contractAddress;
    }

    /// @notice Update the address of the bridge
    /// @dev Used for authorization
    /// @param  _bridge New address for the bridge
    function setBridge(address _bridge) external onlyOwner {
        bridge = _bridge;
    }

    /// @notice Stake multiple Sheets by providing their Ids
    /// @param tokenIds Array of SheetFighterToken ids to stake
    function stakeByIds(uint256[] calldata tokenIds) external {
        require(
            stakerToTokenIds[msg.sender].length + tokenIds.length <= MAX_WALLET_STAKED,
            "Must have less than 10 Sheets staked!"
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                ISheetFighterToken(sheetFighterTokenAddress).ownerOf(tokenIds[i]) == msg.sender, 
                "You don't own this Sheet!"
            );
            require(tokenIdToStaker[tokenIds[i]] == address(0), "Token is already being staked!");

            // Transfer SheetFighterToken to this (CellToken) contract
            ISheetFighterToken(sheetFighterTokenAddress).transferFrom(
                msg.sender,
                address(this),
                tokenIds[i]
            );

            // Update staking variables in storage
            stakerToTokenIds[msg.sender].push(tokenIds[i]);
            tokenIdToTimeStamp[tokenIds[i]] = block.timestamp;
            tokenIdToStaker[tokenIds[i]] = msg.sender;
        }
    }

    /// @notice Unstake all of your SheetFighterTokens and get your rewards
    /// @notice This function is more gas efficient than calling unstakeByIds(...) for all ids
    /// @dev Tokens are iterated over in REVERSE order, due to the implementation of _remove(...)
    function unstakeAll() external {
        require(
            stakerToTokenIds[msg.sender].length > 0,
            "You have no tokens staked!"
        );
        uint256 totalRewards = 0;

        // Iterate over staked tokens from the BACK of the array, because
        // the _remove() function, which is called by _removeTokenIdFromStaker(),
        // is far more gas efficient when called on elements further back
        for (uint256 i = stakerToTokenIds[msg.sender].length; i > 0; i--) {
            
            uint256 tokenId = stakerToTokenIds[msg.sender][i - 1];

            // Transfer SheetFighterToken back to staker
            ISheetFighterToken(sheetFighterTokenAddress).transferFrom(
                address(this),
                msg.sender,
                tokenId
            );

            // Add rewards for the current token
            totalRewards =
                totalRewards + (
                    (block.timestamp - tokenIdToTimeStamp[tokenId]) *
                    EMISSIONS_RATE
                );

            // Remove the token from the staker in storage variables
            _removeTokenIdFromStaker(msg.sender, tokenId);
            delete tokenIdToStaker[tokenId];
        }

        // Mint CellTokens to reward staker
        _mint(msg.sender, _getMaximumRewards(totalRewards));
    }

    /// @notice Unstake SheetFighterTokens, given by ids, and get your rewards
    /// @notice Use unstakeAll(...) instead if unstaking all tokens for gas efficiency
    /// @param tokenIds Array of SheetFighterToken ids to unstake
    function unstakeByIds(uint256[] memory tokenIds) external {
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokenIdToStaker[tokenIds[i]] == msg.sender,
                "You're not staking this Sheet!"
            );

            // Transfer SheetFighterToken back to staker
            ISheetFighterToken(sheetFighterTokenAddress).transferFrom(
                address(this),
                msg.sender,
                tokenIds[i]
            );

            // Add rewards for the current token
            totalRewards =
                totalRewards + (
                    (block.timestamp - tokenIdToTimeStamp[tokenIds[i]]) *
                    EMISSIONS_RATE
                );

            // Remove the token from the staker in storage variables
            _removeTokenIdFromStaker(msg.sender, tokenIds[i]);
            delete tokenIdToStaker[tokenIds[i]];
        }

        // Mint CellTokens to reward staker
        _mint(msg.sender, _getMaximumRewards(totalRewards));
    }

    /// @notice Claim $CELL tokens as reward for staking a SheetFighterTokens, given by an id
    /// @notice This function does not unstake your Sheets
    /// @param tokenId SheetFighterToken id
    function claimByTokenId(uint256 tokenId) external {
        require(
            tokenIdToStaker[tokenId] == msg.sender,
            "You're not staking this Sheet!"
        );

        _mint(
            msg.sender,
            _getMaximumRewards((block.timestamp - tokenIdToTimeStamp[tokenId]) * EMISSIONS_RATE)
        );

        tokenIdToTimeStamp[tokenId] = block.timestamp;
    }

    /// @notice Claim $CELL tokens as reward for all SheetFighterTokens staked
    /// @notice This function does not unstake your Sheets
    function claimAll() external {
        uint256[] memory tokenIds = stakerToTokenIds[msg.sender];
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokenIdToStaker[tokenIds[i]] == msg.sender,
                "Token is not claimable by you!"
            );

            totalRewards =
                totalRewards +
                ((block.timestamp - tokenIdToTimeStamp[tokenIds[i]]) *
                    EMISSIONS_RATE);

            tokenIdToTimeStamp[tokenIds[i]] = block.timestamp;
        }

        _mint(msg.sender, _getMaximumRewards(totalRewards));
    }

    /// @notice Mint tokens when bridging
    /// @dev This function is only used for bridging to mint tokens on one end
    /// @param to Address to send new tokens to
    /// @param value Number of new tokens to mint
    function bridgeMint(address to, uint256 value) external {
        require(bridge != address(0), "Bridge is not set");
        require(msg.sender == bridge, "Only bridge can do this");
        _mint(to, _getMaximumRewards(value));
    }

    /// @notice Burn tokens when bridging
    /// @dev This function is only used for bridging to burn tokens on one end
    /// @param from Address to burn tokens from
    /// @param value Number of tokens to burn
    function bridgeBurn(address from, uint256 value) external {
        require(bridge != address(0), "Bridge is not set");
        require(msg.sender == bridge, "Only bridge can do this");
        _burn(from, value);
    }

    /// @notice View all rewards claimable by a staker
    /// @param staker Address of the staker
    /// @return Number of $CELL claimable by the staker
    function getAllRewards(address staker) external view returns (uint256) {
        uint256[] memory tokenIds = stakerToTokenIds[staker];
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            totalRewards =
                totalRewards +
                ((block.timestamp - tokenIdToTimeStamp[tokenIds[i]]) *
                    EMISSIONS_RATE);
        }

        return _getMaximumRewards(totalRewards);
    }

    /// @notice View rewards claimable for a specific SheetFighterToken
    /// @param tokenId Id of the SheetFightToken
    /// @return Number of $CELL claimable by the staker for this Sheet
    function getRewardsByTokenId(uint256 tokenId) external view returns (uint256) {
        require(tokenIdToStaker[tokenId] != address(0), "Sheet is not staked!");

        uint256 rewards = (block.timestamp - tokenIdToTimeStamp[tokenId]) * EMISSIONS_RATE;

        return _getMaximumRewards(rewards);
    }

    /// @notice Get all the token Ids staked by a staker
    /// @param staker Address of the staker
    /// @return Array of tokens staked
    function getTokensStaked(address staker) external view returns (uint256[] memory) {
        return stakerToTokenIds[staker];
    }

    /// @notice Remove a token, given by an index, from a staker in staking storage variables
    /// @dev This function is significantly more gas efficient the greater the index is
    /// @param staker Address of the staker
    /// @param index Index of the SheetFighterToken in stakeToTokenIds[staker] being removed
    function _remove(address staker, uint256 index) internal {
        if (index >= stakerToTokenIds[staker].length) return;

        // Reset all 
        for (uint256 i = index; i < stakerToTokenIds[staker].length - 1; i++) {
            stakerToTokenIds[staker][i] = stakerToTokenIds[staker][i + 1];
        }
        stakerToTokenIds[staker].pop();
    }

    /// @notice Remove a token, given by an id, from a staker in staking storage variables
    /// @param staker Address of the staker
    /// @param tokenId SheetFighterToken id
    function _removeTokenIdFromStaker(address staker, uint256 tokenId) internal {

        // Find index of SheetFighterToken in stakerToTokenIds[staker] array
        for (uint256 i = 0; i < stakerToTokenIds[staker].length; i++) {
            if (stakerToTokenIds[staker][i] == tokenId) {
                // This is the tokenId to remove
                // Now, remove it
                _remove(staker, i);
            }
        }
    }

    /// @dev Returns the maximum amount of rewards the user can get, when considering the max token cap
    /// @param calculatedRewards The rewards the user would receive, if there were no token cap
    /// @return How much the owner can claim
    function _getMaximumRewards(uint256 calculatedRewards) internal view returns(uint256) {
        uint256 totalCellAvailable = MAX_CELL - totalSupply();
        return totalCellAvailable > calculatedRewards ? calculatedRewards : totalCellAvailable;
    }
}