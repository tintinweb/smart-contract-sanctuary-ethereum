/**
 *Submitted for verification at Etherscan.io on 2022-07-15
*/

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


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

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
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[owner][spender];
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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
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

// File: contracts/EMTToken.sol


/*
*
* EMTRI Corporation, incorporated and registered in California, USA; 'EMTRI'.
*
* EMTRI empowers the Farmers, Cultivators, Strain Producers and Distributors 
* (clients) who work to bring quality medical-grade & premium adult-use cannabis 
* to the market.
*
* EMTRI clients use Ethereum blockchain technologies to attest to their crop 
* cultivations. In return for attesting to crop lifecycle events using blockchain, 
* EMTRI rewards its clients with EMT tokens, the 'mint'.
*
* EMTRI introduces clients to cannabis distributors that sell the attested-to
* cannabis to wholesale and retail customers, who actually pay a cash premium to 
* EMTRI because the cannabis their clients produce is attestested to using blockchain.
*
* Up to 50% of the cash premium paid to EMTRI is used to buyback EMT tokens on the
* Uniswap decentralized token exchange, the 'burn'. 

* So, EMTs are minted only as cultivator and distributor rewards, and then bought
* back upon the sale of the client cannabis, thereby creating the Uniswap marketplace.
*
*
* https://abbey.ch/         -- Abbey Technology GmbH, Zug, Switzerland
* 
* ABBEY DEFI
* ========== 
* 1. Decentralized Finance (DeFi) is designed to be globally inclusive. 
* 2. Centralized finance is based around private share sales to wealthy individuals or
*    the trading of shares on national stock markets, both have high barriers to entry. 
* 3. The Abbey DeFi methodology offers public and private companies exposure to DeFi.
*
* Abbey is a Uniswap-based DeFi service provider that allows companies to offer people a 
* novel way to participate in the success a business may have in a decentralized manner.
* 
* The premise is both elegant and simple, the company commits to a token buyback based on 
* its revenues.
* 
* Using Abbey as a Uniswap DeFi management agency, the company spends some revenues 
* buying one side of a bespoke Uniswap trading pair. The other side of the Uniswap pair 
* is the EMT token.
* 
* DeFi traders wishing to participate in the success a business may have deposit USDC in return 
* for EMT tokens. The Uniswap Automated Market Maker ensures DeFi market liquidity and
* legitimate price discovery. The more USDC that the company deposits in buy backs over time, 
* the higher the value of the EMT token, as held by DeFi speculators.
*
*/

pragma solidity 0.8.15;



/**
 * @title EMT Token contract for Uniswap v3.
 * @author Abbey Technology GmbH
 * @notice Token contract for use with Uniswap. Enforces restrictions outlined on the website.
 */
contract EMTToken is ERC20 {

    /**
     * @notice The details of a future company cashout.
     */
    struct Notice {
        // The maximum number of tokens proposed for sale.
        uint256 amount;

        // The date after which company tokens can be swapped.
        uint256 releaseDate;
    }

    // Event fired when a restricted wallet gives notice of a potential future trade.
    event NoticeGiven(address indexed who, uint256 amount, uint256 releaseDate);

    /**
     * @notice Notice must be given to the public before treasury tokens can be swapped.
     */
    Notice public noticeTreasury;

    /**
     * @notice Notice must be given to the public before Liquidity Tokens can be removed from the pool.
     */
    Notice public noticeLiquidity;

    /**
    * @notice The account that created this contract, also functions as the liquidity provider.
    */
    address public owner;

    /**
     * @notice Holder of the company's tokens.  Must give notice before tokens are moved.
     */
    address public treasury;

    /**
     * @notice The account that performs the buyback of tokens, all bought tokens are burned.
     * @dev They cannot be autoburned during transfer as the Uniswap client prevents the transaction.
     */
    address public buyback;

    /**
     * @notice The account that facilitates moving tokens between Mainnet and Efixii L2.
     */
    address public flip;    

    /**
     * @notice The address of the Uniswap Pool ERC20 contract holding the Liquidity Pool tokens.
     */
    address public poolAddress;

    /**
     * @notice The address of the Uniswap NFT ERC721 Positions contract that tracks ownership of liquidity pools.
     */
    address public positionsAddress;

    /**
     * @notice The NFT id of the Liquidity Pool in the Uniswap Positions contract.
     */
    uint256 public nftId;    

    /**
     * @notice The minimum duration notice given (to give the public a chance to act and to prevent a rug pull).
     */
    uint256 private MinimumNotice = 7 days;

    /**
     * @notice Restrict functionaly to the contract owner.
     */
    modifier onlyOwner {
        require(_msgSender() == owner, "You are not Owner.");
        _;
    }

    /**
     * @notice Create the contract setting already known values that are unlikely to change.  The tokens for the Uniswap
     *         liquidity pool are also created.
     * 
     * @param initialSupply The number of tokens to create the Uniswap pool.
     * @param name          The name of the token.
     * @param symbol        The short symbol for this token.
     * @param treasuryAddr  The address of the treasury wallet.
     * @param buybackAddr   The wallet that performs buybacks and optional burns of tokens.
     * @param flipAddr      The wallet used to move tokens between L2 and Mainnet.
     */
    constructor(uint256 initialSupply, string memory name, string memory symbol, address treasuryAddr, address buybackAddr, address flipAddr, address positionsAddr) ERC20(name, symbol) {
        owner = _msgSender();

        treasury = treasuryAddr;
        buyback = buybackAddr;
        flip = flipAddr;
        positionsAddress = positionsAddr;

        _mint(owner, initialSupply);
    }

    /**
     * @notice Set the address of the account holding EMT tokens on behalf of the company.
     */
    function setTreasury(address who) public onlyOwner {
        require(who != address(0x0), "Cannot assign to null address");

        _migrateTokens(treasury, who);
        treasury = who;
    }

    /**
     * @notice Set the address of the company account that buys tokens to increase the token price.
     */
    function setBuyback(address who) public onlyOwner {
        require(who != address(0x0), "Cannot assign to null address");

        _migrateTokens(buyback, who);
        buyback = who;
    }

    /**
     * @notice Set the address of the account that allows moving tokens between L2 and Mainnet.
     */
    function setFlip(address who) public onlyOwner {
        require(who != address(0x0), "Cannot assign to null address");

        _migrateTokens(flip, who);
        flip = who;
    }

    /**
     * When changing the address of a role in the contract move all tokens to the new
     * address - the tokens are restricted by role so need to move with the role address
     * change.
     */
    function _migrateTokens(address from, address to) private {
        if(from != address(0x0) && balanceOf(from) > 0)
            _transfer(from, to, balanceOf(from));
    }

    /**
     * @notice Set the address of the Uniswap Pool contract.
     */
    function setPoolAddress(address who) public onlyOwner {
        poolAddress = who;
    }

    /**
     * @notice Set the address of the Uniswap NFT contract that tracks Liquidity Pool ownership.
     */
    function setPositionsAddress(address who) public onlyOwner {
        positionsAddress = who;
    }

    /**
     * @notice Set the id of the position token that determines ownership of the Liquidity Pool.
     */
    function setNftId(uint256 id) public onlyOwner {
        nftId = id;
    }

    /**
     * @notice Treasury tokens must give advanced notice to the public before they can be used.
     * A public announcement will be made at the same time this notice is set in the contract.
     *
     * @param who The treasury address.
     * @param amount The maximum number of tokens (in wei).
     * @param numSeconds The number of seconds the tokens are held before being acted on.
     */
    function treasuryTransferNotice(address who, uint256 amount, uint256 numSeconds) public onlyOwner {
        require(who == treasury, "Specified address is not Treasury.");
        require(numSeconds >= MinimumNotice, "Not enough notice given.");

        uint256 when = block.timestamp + (numSeconds * 1 seconds);

        require(noticeTreasury.releaseDate == 0 || block.timestamp >= noticeTreasury.releaseDate, "Cannot overwrite an active existing notice.");
        require(amount <= balanceOf(who), "Can't give notice for more EMT tokens than owned.");
        noticeTreasury = Notice(amount, when);
        emit NoticeGiven(who, amount, when);
    }

    /**
     * @notice Liquidity Pool tokens must give advanced notice to the public before they can be used.
     * A public announcement will be made at the same time this notice is set in the contract.     
     *
     * @param who The owner of the Uniswap Positions NFT token.
     * @param amount The maximum number of tokens (in wei).
     * @param numSeconds The number of seconds the tokens are held before being acted on.
     */
    function liquidityRedemptionNotice(address who, uint256 amount, uint256 numSeconds) public onlyOwner {
        require(positionsAddress != address(0), "Uniswap Position Manager must be set.");
        require(numSeconds >= MinimumNotice, "Not enough notice given.");
        require(nftId != 0, "Uniswap Position NFT Id must be set.");
        require(poolAddress != address(0), "The Uniswap Pool contract address must be set.");

        IERC721 positions = IERC721(positionsAddress);
        address lpOwner = positions.ownerOf(nftId);
        require(who == lpOwner, "The specified address does not own the Positions NFT Token.");

        uint256 when = block.timestamp + (numSeconds * 1 seconds);

        require(noticeLiquidity.releaseDate == 0 || block.timestamp >= noticeLiquidity.releaseDate, "Cannot overwrite an active existing notice.");
        require(amount <= balanceOf(poolAddress), "Can't give notice for more Liquidity Tokens than owned.");
        noticeLiquidity = Notice(amount, when);
        emit NoticeGiven(who, amount, when);
    }

    /**
     * @notice Enforce rules around the company accounts:
     * - Once buyback buys tokens they can never be moved, the only real option is to burn.
     * - Two key accounts: treasury and the owner of the liquidity pool are restricted.
     * - A public announcement of the company's intent along with a time locked notice set in this contract before any token movement.
     * - Only after the deadline can these restricted tokens move.
     * - No restrictions are in place for any other wallet.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(sender != buyback, "Buyback cannot transfer tokens, it can only burn.");
        if(sender == treasury) {
            require(noticeTreasury.releaseDate != 0 && block.timestamp >= noticeTreasury.releaseDate, "Notice period has not been set or has not expired.");
            require(amount <= noticeTreasury.amount, "Treasury can't transfer more tokens than given notice for.");

            // Clear the remaining notice balance, this prevents giving notice on all tokens and
            // trickling them out.
            noticeTreasury = Notice(0, 0);
        }
        else if(nftId != 0) { // Check if the receiver is the Liquidity Pool owner.
            IERC721 positions = IERC721(positionsAddress);
            address lpOwner = positions.ownerOf(nftId);
            if(recipient == lpOwner) {
                require(noticeLiquidity.releaseDate != 0 && block.timestamp >= noticeLiquidity.releaseDate, "LP notice period has not been set or has not expired.");
                require(amount <= noticeLiquidity.amount, "LP can't transfer more tokens than given notice for.");

                // Clear the remaining notice balance, this prevents giving notice on all tokens and
                // trickling them out.
                noticeLiquidity = Notice(0, 0);
            }
        }

        super._transfer(sender, recipient, amount);
    }

    /**
     * @notice mint is only called when EMT tokens are burned on the L2 side of the EMT bridge 
     * and are then minted one-for-one to this contract on the Mainnet L1 side of the EMT bridge.
     * Once minted, EMTs are ready to trade on Uniswap.
     *
     * @param who The address to mint to the tokens to.
     * @param quantity The number of tokens to create, in wei.
     */
    function mint(address who, uint256 quantity) public onlyOwner {
        _mint(who, quantity);
    }

    /**
     * @notice Tokens are burned here on Mainnet to reduce total supply available to trade on Uniswap.
     *
     * @param quantity The number of tokens to destroy, in wei.
     */
    function burn(uint256 quantity) public {
        _burn(_msgSender(), quantity);
    }
}