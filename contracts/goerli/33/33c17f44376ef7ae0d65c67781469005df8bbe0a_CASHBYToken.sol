/**
 *Submitted for verification at Etherscan.io on 2022-12-30
*/

pragma solidity ^0.8.4;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

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
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
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
    function _transfer(address from, address to, uint256 amount) internal virtual {
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

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
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

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


contract CASHBYToken is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("CASH Token", "CASH") public {
        // Set the max supply to 100,000,000
        _mint(msg.sender, 100000000 * (10 ** 18));
    }

    bool public tradingEnabled = true;

    // Mapping to store the maximum number of tokens that a wallet can hold
    mapping(address => uint256) public maxWallet;

    // Set the maximum wallet percentage to 0.1% of the total supply
    uint256 public maxWalletPercentage = 100000;

    // Mapping to store the maximum number of tokens that a wallet can sell in a single transaction
    mapping(address => uint256) public maxSell;

    // Set the maximum sell percentage to 25% of the wallet's total holding
    uint256 public maxSellPercentage = 25;

    // Mapping to store the NFT contract address for each wallet
    mapping(address => address) public nftContract;

    // Mapping to store the number of NFTs owned by each wallet
    mapping(address => uint256) public nftCount;

    // Mapping to store the sell tax percentage for each wallet
    mapping(address => uint256) public sellTax;

    // Set the default sell tax percentage to 9%
    uint256 public defaultSellTax = 9;

    // Set the sell tax percentage reduction for each NFT owned
    uint256 public nftSellTaxReduction = 1;

    // Set the maximum number of NFTs that can be owned to reduce the sell tax percentage
    uint256 public maxNFTsForReduction = 5;

    // Set the liquidity percentage to 3%
    uint256 public liquidityPercentage = 3;

    // Set the burn percentage to 3%
    uint256 public burnPercentage = 3;

    // Set the company revenue percentage to 3%
    uint256 public companyRevenuePercentage = 3;

    // Set the BNB conversion rate to 1 BNB per 10 GIG
    uint256 public bnbConversionRate = 10;

    // Mapping to store the whitelisted wallets
    mapping(address => bool) public whitelist;

    // Mapping to store the green hearts list wallets
    mapping(address => bool) public greenHeartsList;

    // Set the green hearts list sell tax percentage to 3%
    uint256 public greenHeartsListSellTax = 3;

    // Set the green hearts list liquidity percentage to 1%
    uint256 public greenHeartsListLiquidityPercentage = 1;

    // Set the green hearts list burn percentage to 1%
    uint256 public greenHeartsListBurnPercentage = 1;

    // Set the green hearts list company revenue percentage to 1%
    uint256 public greenHeartsListCompanyRevenuePercentage = 1;

    // Mapping to store the merchants list wallets
    mapping(address => bool) public merchantsList;

    // Set the merchants list sell tax percentage to 2%
    uint256 public merchantsListSellTax = 2;

    // Set the merchants list burn percentage to 1%
    uint256 public merchantsListBurnPercentage = 1;

    // Set the merchants list company revenue percentage to 1%
    uint256 public merchantsListCompanyRevenuePercentage = 1;

    // Mapping to store the blacklisted wallets
    mapping(address => bool) public blacklist;

    // Function to change the owner of the contract
    function changeOwner(address newOwner) public onlyOwner {
        // Transfer the ownership to the new owner
        _transferOwnership(newOwner);
    }

    // Function to enable trading
    function enableTrading() public onlyOwner {
        // Set the tradingEnabled flag to true
        tradingEnabled = true;
    }

    // Function to mint tokens
    function mint(address to, uint256 amount) public onlyOwner {
        // Call the ERC20 mint function
        _mint(to, amount);
    }

    // Function to set the maximum wallet percentage
    function setMaxWalletPercentage(uint256 percentage) public onlyOwner {
        // Set the max wallet percentage to the specified value
        maxWalletPercentage = percentage;
    }

    // Function to set the maximum sell percentage
    function setMaxSellPercentage(uint256 percentage) public onlyOwner {
        // Set the max sell percentage to the specified value
        maxSellPercentage = percentage;
    }

    // Function to set the NFT contract address for a wallet
    function setNFTContract(address nftContractAddress) public onlyOwner {
        // Set the NFT contract address for the caller's wallet
        nftContract[msg.sender] = nftContractAddress;
    }

    // Function to add a wallet to the whitelist
    function addToWhitelist(address wallet) public onlyOwner {
        // Add the wallet to the whitelist
        whitelist[wallet] = true;
    }

    // Function to remove a wallet from the whitelist
    function removeFromWhitelist(address wallet) public onlyOwner {
        // Remove the wallet from the whitelist
        delete whitelist[wallet];
    }

    // Function to add a wallet to the green hearts list
    function addToGreenHeartsList(address wallet) public onlyOwner {
        // Add the wallet to the green hearts list
        greenHeartsList[wallet] = true;
    }

    // Function to remove a wallet from the green hearts list
    function removeFromGreenHeartsList(address wallet) public onlyOwner {
        // Remove the wallet from the green hearts list
        delete greenHeartsList[wallet];
    }

    // Function to add a wallet to the merchants list
    function addToMerchantsList(address wallet) public onlyOwner {
        // Add the wallet to the merchants list
        merchantsList[wallet] = true;
    }

    // Function to remove a wallet from the merchants list
    function removeFromMerchantsList(address wallet) public onlyOwner {
        // Remove the wallet from the merchants list
        delete merchantsList[wallet];
    }

    // Function to add a wallet to the blacklist
    function addToBlacklist(address wallet) public onlyOwner {
        // Add the wallet to the blacklist
        blacklist[wallet] = true;
    }

    // Function to remove a wallet from the blacklist
    function removeFromBlacklist(address wallet) public onlyOwner {
        // Remove the wallet from the blacklist
        delete blacklist[wallet];
    }

    // Override the ERC20 transfer function to implement the specified functionality
    function transfer(address to, uint256 value) public virtual override returns (bool) {
        // Check if the trading is enabled
        require(tradingEnabled, "Trading is not enabled");

        // Check if the sender is whitelisted
        require(!whitelist[msg.sender], "The sender is whitelisted and is not allowed to transfer tokens");

        // Check if the recipient is whitelisted
        require(!whitelist[to], "The recipient is whitelisted and is not allowed to receive tokens");

        // Check if the sender is blacklisted
        require(!blacklist[msg.sender], "The sender is blacklisted and is not allowed to transfer tokens");

        // Check if the recipient is blacklisted
        require(!blacklist[to], "The recipient is blacklisted and is not allowed to receive tokens");

        // Check if the sender has enough balance
        require(balanceOf(msg.sender) >= value, "The sender does not have enough balance");

        // Check if the sender is not exceeding the maximum sell limit
        require(value <= maxSell[msg.sender], "The sender is exceeding the maximum sell limit");

        // Calculate the sell tax percentage for the sender
        uint256 sellTaxPercentage = getSellTaxPercentage(msg.sender);

        // Calculate the amount of sell tax
        uint256 sellTaxAmount = (sellTaxPercentage * value) / 100;

        // Calculate the amount of liquidity
        uint256 liquidityAmount = (liquidityPercentage * sellTaxAmount) / 100;

        // Calculate the amount of burn
        uint256 burnAmount = (burnPercentage * sellTaxAmount) / 100;

        // Calculate the amount of company revenue
        uint256 companyRevenueAmount = (companyRevenuePercentage * sellTaxAmount) / 100;

        // Calculate the BNB conversion amount
        uint256 bnbAmount = companyRevenueAmount / bnbConversionRate;

        // Transfer the value to the recipient
        _transfer(msg.sender, to, value);

        // Transfer the liquidity amount to the contract owner
        _transfer(msg.sender, owner(), liquidityAmount);

        

        // Update the maximum sell limit for the sender
        updateMaxSellLimit(msg.sender);
        return true;
    }

    // Function to calculate the sell tax
    function updateMaxSellLimit(address wallet) private {
        // Calculate the maximum sell limit for the wallet
        maxSell[wallet] = (balanceOf(wallet) * maxSellPercentage) / 100;
    }

    // Function to calculate the sell tax percentage for a wallet
    function getSellTaxPercentage(address wallet) private returns (uint256) {
        // Check if the wallet is on the green hearts list
        if (greenHeartsList[wallet]) {
            // Return the green hearts list sell tax percentage
            return greenHeartsListSellTax;
        }

        // Check if the wallet is on the merchants list
        if (merchantsList[wallet]) {
            // Return the merchants list sell tax percentage
            return merchantsListSellTax;
        }

        // Check if the wallet owns any NFTs
        if (nftCount[wallet] > 0) {
            // Calculate the sell tax percentage reduction for the wallet
            uint256 sellTaxReduction = nftSellTaxReduction * nftCount[wallet];

            // Check if the sell tax percentage reduction is greater than the default sell tax percentage
            if (sellTaxReduction > defaultSellTax) {
                // Set the sell tax percentage to 0
                sellTax[wallet] = 0;
            } else {
                // Calculate the sell tax percentage for the wallet
                sellTax[wallet] = defaultSellTax - sellTaxReduction;
            }
        } else {
            // Set the sell tax percentage to the default value
            sellTax[wallet] = defaultSellTax;
        }

        // Return the sell tax percentage for the wallet
        return sellTax[wallet];
    }

    
}