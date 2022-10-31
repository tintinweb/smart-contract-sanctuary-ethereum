/**
 *Submitted for verification at Etherscan.io on 2022-10-31
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17; 

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


interface IDexFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDexRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}





contract FLM is ERC20, Ownable {
    IDexRouter public constant ROUTER = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public immutable pair;
    address public marketingWallet;
    address public charityWallet;

    uint256 public buyTax = 500;
    uint256 public sellTax = 500;
    uint256 public transferTax;
    uint256 private constant TAX_DENOMINATOR = 10000;

    uint256 public marketingShare = 300;
    uint256 public charityShare = 300;
    uint256 public liquidityShare = 200;
    uint256 public burnShare = 200;
    uint256 public totalSwapShares = 800;
    uint256 public totalShares = 1000;

    uint256 public maxBalance = 10**6 * 10**18;
    uint256 public transferGas = 25000;
    uint256 public launchBlock;

    uint256 public swapThreshold = 1;
    bool public swapWholeStorage = true;
    bool public swapEnabled = true;
    bool private inSwap;

    mapping (address => bool) public isTaxExempt;
    mapping (address => bool) public isLimitExempt;

    event ETHRecovered(uint256 amount);
    event ERC20Recovered(IERC20 token, address recipient, uint256 amount);
    event TaxExemptUpdated(address account, bool exempt);
    event LimitExemptUpdated(address account, bool exempt);
    event MaxBalanceUpdated(uint256 amount);
    event TaxesUpdated(uint256 buyTax, uint256 sellTax, uint256 transferTax);
    event SharesUpdated(uint256 liquidityShare, uint256 marketingShare, uint256 charityShare, uint256 burnShare);
    event SwapBackSettingsUpdated(bool enabled, bool swapAll, uint256 tokenAmount);
    event TransferGasUpdated(uint256 transferGas);
    event MarketingWalletUpdated(address marketingWallet);
    event CharityWalletUpdated(address charityWallet);

    modifier swapping() { 
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(address marketing, address charity) ERC20("Frog Lives Matter", "FLM") {
        require(marketing != address(0) && charity != address(0), "Parameters can't be zero address");

        pair = IDexFactory(ROUTER.factory()).createPair(address(this), ROUTER.WETH());
        marketingWallet = marketing;
        charityWallet = charity;

        isTaxExempt[_msgSender()] = true;
        isLimitExempt[_msgSender()] = true;

        isLimitExempt[pair] = true;
        isLimitExempt[address(0xdead)] = true;
        isLimitExempt[address(ROUTER)] = true;

        _mint(_msgSender(), 10**8 * 10**18);
    }

    receive() external payable {
        require(inSwap, "Can't receive ETH");
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        if (recipient == pair && launchBlock == 0) {
            launchBlock = block.number;
        }

        if (inSwap) {
            super._transfer(sender, recipient, amount);
            return;
        }

        require(recipient != address(this), "Can't receive FLM");

        if (!isLimitExempt[recipient]) {
            require(balanceOf(recipient) + amount <= maxBalance, "Max balance limit");
        }

        uint256 amountAfterTax = _takeTax(sender, recipient, amount);

        if (_shouldSwapBack(recipient)) {
            uint256 swapAmount = swapWholeStorage ? balanceOf(address(this)) : swapThreshold;
            _swapBack(swapAmount);
        }

        super._transfer(sender, recipient, amountAfterTax);
    }

    function _takeTax(address sender, address recipient, uint256 amount) private returns (uint256) {
        if (isTaxExempt[sender] || isTaxExempt[recipient] || amount == 0) {
            return amount;
        }

        uint256 taxAmount = amount * _getTotalTax(sender, recipient) / TAX_DENOMINATOR;
        if (taxAmount > 0) {
            uint256 burnAmount = taxAmount * burnShare / totalShares;
            if (burnAmount > 0) {
                super._transfer(sender, address(0xdead), burnAmount);
            }

            uint256 tokensToSwap = taxAmount - burnAmount;
            if (tokensToSwap > 0) {
                super._transfer(sender, address(this), tokensToSwap);
            }
        }

        return amount - taxAmount;
    }

    function _getTotalTax(address sender, address recipient) private view returns (uint256) {
        if (block.number < launchBlock + 5) { return 9900; }

        if (sender == pair) {
            return buyTax;
        } else if (recipient == pair) {
            return sellTax;
        } else {
            return transferTax;
        }
    }

    function _shouldSwapBack(address recipient) private view returns (bool) {
        return recipient == pair && swapEnabled && balanceOf(address(this)) >= swapThreshold && totalSwapShares > 0;
    }

    function _swapBack(uint256 amount) private swapping {
        uint256 liquidityTokens = amount * liquidityShare / totalSwapShares / 2;
        uint256 amountToSwap = amount - liquidityTokens;

        uint256 receivedETH = _swapTokens(amountToSwap);
        uint256 totalETHShares = totalSwapShares - liquidityShare / 2;

        uint256 liquidityETH = receivedETH * liquidityShare / totalETHShares / 2;
        uint256 marketingETH = receivedETH * marketingShare / totalETHShares;
        uint256 charityETH = receivedETH * charityShare / totalETHShares;

        if (marketingETH > 0) {
            (bool success,) = payable(marketingWallet).call{value: marketingETH, gas: transferGas}("");
            success; // suppress compiler warning
        }

        if (charityETH > 0) {
            (bool success,) = payable(charityWallet).call{value: charityETH, gas: transferGas}("");
            success; // suppress compiler warning
        }

        if (liquidityTokens > 0) {
            _addLiquidity(liquidityTokens, liquidityETH);
        }
    }

    function _swapTokens(uint256 amount) private returns (uint256) {
        uint256 balanceBefore = address(this).balance;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = ROUTER.WETH();

        _approve(address(this), address(ROUTER), amount);
        try ROUTER.swapExactTokensForETH(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        ) {} catch {}

        return address(this).balance - balanceBefore;
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(ROUTER), tokenAmount);
        try ROUTER.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            address(this),
            block.timestamp
        ) {} catch {}
    }

    // Maintenance

    function recoverETH() external onlyOwner {
        uint256 amount = address(this).balance;
        (bool sent,) = payable(_msgSender()).call{value: amount}("");
        require(sent, "Tx failed");
        emit ETHRecovered(amount);
    }

    function recoverERC20(IERC20 token) external onlyOwner {
        require(address(token) != address(this), "Can't withdraw this token");
        uint256 amount = token.balanceOf(address(this));
        token.transfer(_msgSender(), amount);
        emit ERC20Recovered(token, _msgSender(), amount);
    }

    function setIsTaxExempt(address account, bool exempt) external onlyOwner {
        isTaxExempt[account] = exempt;
        emit TaxExemptUpdated(account, exempt);
    }

    function setIsLimitExempt(address account, bool exempt) external onlyOwner {
        require(account != pair && account != address(0xdead), "Can't modify pair or burn address");
        isLimitExempt[account] = exempt;
        emit LimitExemptUpdated(account, exempt);
    }

    function setMaxBalance(uint256 amount) external onlyOwner {
        require(amount >= 10**6 * decimals(), "Max balance too low");
        maxBalance = amount;
        emit MaxBalanceUpdated(amount);
    }

    function setTaxes(uint256 newBuyTax, uint256 newSellTax, uint256 newTransferTax) external onlyOwner {
        require(newBuyTax <= 1000 && newSellTax <= 1000 && newTransferTax <= 1000, "Too high taxes");
        buyTax = newBuyTax;
        sellTax = newSellTax;
        transferTax = newTransferTax;
        emit TaxesUpdated(buyTax, sellTax, transferTax);
    }

    function setShares(
        uint256 newLiquidityShare,
        uint256 newMarketingShare,
        uint256 newCharityShare,
        uint256 newBurnShare
    ) external onlyOwner {
        liquidityShare = newLiquidityShare;
        marketingShare = newMarketingShare;
        charityShare = newCharityShare;
        burnShare = newBurnShare;

        totalSwapShares = liquidityShare + marketingShare + charityShare;
        totalShares = totalSwapShares + burnShare;
        require(totalShares > 0, "totalShares must be a positive number");
        emit SharesUpdated(liquidityShare, marketingShare, charityShare, burnShare);
    }

    function setSwapBackSettings(
        bool enabled,
        bool swapAll,
        uint256 amount
    ) external onlyOwner {
        uint256 tokenAmount = amount * 10**decimals();
        swapEnabled = enabled;
        swapWholeStorage = swapAll;
        swapThreshold = tokenAmount;
        emit SwapBackSettingsUpdated(enabled, swapAll, tokenAmount);
    }

    function triggerSwapBack(bool swapAll, uint256 amount) external onlyOwner {
        uint256 tokenAmount = swapAll ? balanceOf(address(this)) : amount * 10**decimals();
        _swapBack(tokenAmount);
    }

    function setTransferGas(uint256 newGas) external onlyOwner {
        require(newGas >= 21000 && newGas <= 50000, "New gas out of bounds");
        transferGas = newGas;
        emit TransferGasUpdated(transferGas);
    }

    function setMarketingWallet(address newMarketingWallet) external onlyOwner {
        require(newMarketingWallet != address(0), "Marketing can't be zero address");
        marketingWallet = newMarketingWallet;
        emit MarketingWalletUpdated(marketingWallet);
    }

    function setCharityWallet(address newCharityWallet) external onlyOwner {
        require(newCharityWallet != address(0), "Charity can't be zero address");
        charityWallet = newCharityWallet;
        emit CharityWalletUpdated(charityWallet);
    } 
}