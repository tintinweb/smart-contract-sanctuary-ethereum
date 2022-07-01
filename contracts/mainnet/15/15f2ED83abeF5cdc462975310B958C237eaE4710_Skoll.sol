/**
 *Submitted for verification at Etherscan.io on 2022-07-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Pair {
    function sync() external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;
}

abstract contract RibeToken
{
    function buyFeePercentage() external view virtual returns(uint);
    function onBuyFeeCollected(address tokenAddress, uint amount) external virtual;
    function sellFeePercentage() external view virtual returns(uint);
    function onSellFeeCollected(address tokenAddress, uint amount) external virtual;
}


contract Skoll is Context, IERC20, IERC20Metadata, Ownable, RibeToken {
    // Openzeppelin variables
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    // My variables

    bool private inSwap;
    uint256 internal _treasuryFeeCollected;
    uint256 internal _nftHoldersFeeCollected;
    uint256 internal _deployerFeeCollected;

    uint256 public minTokensBeforeSwap;
    
    address public treasury_wallet;
    address public nft_holders_wallet;
    address public deployer_wallet;

    address public usdcAddress;
    address public hatiAddress;

    IUniswapV2Router02 public router;
    address public uniswapPair;
    address public ribeswapPair;

    uint public _feeDecimal = 2;
    // index 0 = buy fee, index 1 = sell fee, index 2 = p2p fee
    uint[] public _treasuryFee;
    uint[] public _nftHoldersFee;
    uint[] public _deployerFee;

    bool public swapEnabled = true;
    bool public isFeeActive = false;

    mapping(address => bool) public isTaxless;

    event Swap(uint swaped, uint sentToTreasury, uint sentToNFTHolders, uint sentToDeployer);
    event AutoLiquify(uint256 amountETH, uint256 amountTokens);

    // Ribe Compatibility variables
    uint public treasuryUSDAmount;
    uint public minTreasuryUSDCBeforeSwap;
    uint public ribeBuyFeePercentage = 400;
    uint public ribeSellFeePercentage = 400;
    uint public ribeTreasuryPercentage = 5000;
    uint public ribeNFTHoldersPercentage = 2500;
    uint public ribeDeployerPercentage = 2500;

    bool public isLaunched = false;

    // Anti bots
    mapping(address => uint256) public _blockNumberByAddress;
    bool public antiBotsActive = false;
    mapping(address => bool) public isContractExempt;
    uint public blockCooldownAmount;
    // End anti bots

    // Openzeppelin functions

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor() {
        // Editable
        string memory e_name = "SKOLL";
        string memory e_symbol = "SKOLL";
        treasury_wallet = 0x21D585b52B802C5fcA579f68b359F77EE6Fc342d;
        nft_holders_wallet = 0xa414518f7cBdAA6D1C2F4A06E1Aebff5209B6806;
        deployer_wallet = 0xf0Bc35eFCc611eb89181cC73EB712650FCdC9087;
        uint e_totalSupply = 333_333_333_333_333 ether;
        blockCooldownAmount = 5;
        minTokensBeforeSwap = (_totalSupply * 100) / 10000; // Autoswap on Uni 1% of Skoll Supply
        minTreasuryUSDCBeforeSwap = 2_000_000_000;           // Autoswap on Ribe 2000 USDC by default
        // End editable

        usdcAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        hatiAddress = 0x251457b7c5d85251Ca1aB384361c821330bE2520;
 
        _name = e_name;
        _symbol = e_symbol;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapPair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), usdcAddress);
        ribeswapPair = IUniswapV2Factory(0x5ACcFe50F9D5A9F3cdAB8864943250b1074146b1).createPair(address(this), usdcAddress);
        router = _uniswapV2Router;

        _treasuryFee.push(100);
        _treasuryFee.push(100);
        _treasuryFee.push(0);

        _nftHoldersFee.push(100);
        _nftHoldersFee.push(100);
        _nftHoldersFee.push(0);

        _deployerFee.push(100);
        _deployerFee.push(100);
        _deployerFee.push(0);

        isTaxless[msg.sender] = true;
        isTaxless[address(this)] = true;
        isTaxless[treasury_wallet] = true;
        isTaxless[nft_holders_wallet] = true;
        isTaxless[deployer_wallet] = true;
        isTaxless[address(0)] = true;

        isContractExempt[address(this)] = true;

        _mint(msg.sender, e_totalSupply);
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

        // My implementation
        require(isLaunched || from == owner() || (to!=uniswapPair && to!=ribeswapPair), "Please wait to add liquidity!");

        if(from!=ribeswapPair && to!=ribeswapPair)
        {
            // Anti bots
            if(antiBotsActive)
            {
                if(!isContractExempt[from] && !isContractExempt[to])
                {
                    address human = ensureOneHuman(from, to);
                    ensureMaxTxFrequency(human);
                    _blockNumberByAddress[human] = block.number;
                }
            }
            // End anti bots

            if (swapEnabled && !inSwap && from != uniswapPair) {
                swap();
            }

            uint256 feesCollected;
            if (isFeeActive && !isTaxless[from] && !isTaxless[to] && !inSwap) {
                bool sell = to == uniswapPair;
                bool p2p = from != uniswapPair && to != uniswapPair;
                feesCollected = calculateFee(p2p ? 2 : sell ? 1 : 0, amount);
            }

            amount -= feesCollected;
            _balances[from] -= feesCollected;
            _balances[address(this)] += feesCollected;
        }
        // End my implementation

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

    // My functions

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    function sendViaCall(address payable _to, uint amount) private {
        (bool sent, bytes memory data) = _to.call{value: amount}("");
        data;
        require(sent, "Failed to send Ether");
    }

    function swap() private lockTheSwap {
        // How much are we swaping?
        uint totalCollected = _treasuryFeeCollected + _nftHoldersFeeCollected + _deployerFeeCollected;

        if(minTokensBeforeSwap > totalCollected) return;

        // Let's swap for USDC now
        address[] memory sellPath = new address[](2);
        sellPath[0] = address(this);
        sellPath[1] = usdcAddress;

        address[] memory sellPathHati = new address[](3);
        sellPathHati[0] = address(this);
        sellPathHati[1] = usdcAddress;
        sellPathHati[2] = hatiAddress;    

        _approve(address(this), address(router), totalCollected);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _treasuryFeeCollected,
            0,
            sellPathHati,
            treasury_wallet,
            block.timestamp
        );
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _nftHoldersFeeCollected,
            0,
            sellPath,
            nft_holders_wallet,
            block.timestamp
        );
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _deployerFeeCollected,
            0,
            sellPath,
            deployer_wallet,
            block.timestamp
        );
        
        _treasuryFeeCollected = 0;
        _nftHoldersFeeCollected = 0;
        _deployerFeeCollected = 0;

        emit Swap(totalCollected, _treasuryFeeCollected, _nftHoldersFeeCollected, _deployerFeeCollected);
    }

    function calculateFee(uint256 feeIndex, uint256 amount) internal returns(uint256) {
        uint256 treasuryFee = (amount * _treasuryFee[feeIndex]) / (10**(_feeDecimal + 2));
        uint256 nftHoldersFee = (amount * _nftHoldersFee[feeIndex]) / (10**(_feeDecimal + 2));
        uint256 deployerFee = (amount * _deployerFee[feeIndex]) / (10**(_feeDecimal + 2));
        
        _treasuryFeeCollected += treasuryFee;
        _nftHoldersFeeCollected += nftHoldersFee;
        _deployerFeeCollected += deployerFee;
        return treasuryFee + nftHoldersFee + deployerFee;
    }

    function setMinTokensBeforeSwap(uint256 amount) external onlyOwner {
        minTokensBeforeSwap = amount;
    }

    function setTreasuryWallet(address wallet)  external onlyOwner {
        treasury_wallet = wallet;
    }

    function setNFTHoldersWallet(address wallet)  external onlyOwner {
        nft_holders_wallet = wallet;
    }

    function setDeployerWallet(address wallet)  external onlyOwner {
        deployer_wallet = wallet;
    }

    function setTreasuryFees(uint256 buy, uint256 sell, uint256 p2p) external onlyOwner {
        _treasuryFee[0] = buy;
        _treasuryFee[1] = sell;
        _treasuryFee[2] = p2p;
    }

    function setNFTHoldersFees(uint256 buy, uint256 sell, uint256 p2p) external onlyOwner {
        _nftHoldersFee[0] = buy;
        _nftHoldersFee[1] = sell;
        _nftHoldersFee[2] = p2p;
    }

    function setDeployerFees(uint256 buy, uint256 sell, uint256 p2p) external onlyOwner {
        _deployerFee[0] = buy;
        _deployerFee[1] = sell;
        _deployerFee[2] = p2p;
    }

    function setSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }

    function setFeeActive(bool value) external onlyOwner {
        isFeeActive = value;
    }

    function setTaxless(address account, bool value) external onlyOwner {
        isTaxless[account] = value;
    }

    // Anti bots
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function ensureOneHuman(address _to, address _from) internal virtual returns (address) {
        require(!isContract(_to) || !isContract(_from), "No bots allowed!");
        if (isContract(_to)) return _from;
        else return _to;
    }

    function ensureMaxTxFrequency(address addr) internal virtual {
        bool isAllowed = _blockNumberByAddress[addr] == 0 ||
            ((_blockNumberByAddress[addr] + blockCooldownAmount) < (block.number + 1));
        require(isAllowed, "Max tx frequency exceeded!");
    }

    function setAntiBotsActive(bool value) external onlyOwner {
        antiBotsActive = value;
    }

    function setBlockCooldown(uint value) external onlyOwner {
        blockCooldownAmount = value;
    }

    function setContractExempt(address account, bool value) external onlyOwner {
        isContractExempt[account] = value;
    }
    // End anti bots

    // Ribe Functions

    function baseTokenOwnerWithdraw(address destination, address token, uint amount) public onlyOwner {
        IERC20(token).transfer(destination, amount);
    }

    function calculateRibeFee(uint256 amount, uint256 feePercentage, uint256 feeDecimal) internal pure returns(uint256) {
        return (amount * feePercentage) / (10**(feeDecimal + 2));
    }

    function buyFeePercentage() external view override returns(uint)
    {
        return ribeBuyFeePercentage;
    }

    function sellFeePercentage() external view override returns(uint)
    {
        return ribeSellFeePercentage;
    }

    function setMinTreasuryUSDCBeforeSwap(uint amount) public onlyOwner
    {
        minTreasuryUSDCBeforeSwap = amount;
    }

    function setRibeBuyFeePercentage(uint amount) public onlyOwner
    {
        ribeBuyFeePercentage = amount;
    }

    function setRibeSellFeePercentage(uint amount) public onlyOwner
    {
        ribeSellFeePercentage = amount;
    }

    function setRibeTreasuryPercentage(uint amount) public onlyOwner
    {
        ribeTreasuryPercentage = amount;
    }


    function setRibeNFTHoldersPercentage(uint amount) public onlyOwner
    {
        ribeNFTHoldersPercentage = amount;
    }


    function setRibeDeployerPercentage(uint amount) public onlyOwner
    {
        ribeDeployerPercentage = amount;
    }

    function launch() public onlyOwner
    {
        isLaunched = true;
    }

    function swapTreasuryUSDForRibe() public
    {
        address[] memory sellPath = new address[](2);
        sellPath[0] = usdcAddress;
        sellPath[1] = hatiAddress;

        IERC20(usdcAddress).approve(address(router), treasuryUSDAmount);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            treasuryUSDAmount,
            0,
            sellPath,
            treasury_wallet,
            block.timestamp
        );
        treasuryUSDAmount = 0;
    }

    function processRibeFees(address tokenAddress, uint amount) internal
    {
        if(tokenAddress == usdcAddress)
        {
            treasuryUSDAmount += calculateRibeFee(amount, ribeTreasuryPercentage, 2);
            uint nft_holders_amount = calculateRibeFee(amount, ribeNFTHoldersPercentage, 2);
            uint deployer_amount = calculateRibeFee(amount, ribeDeployerPercentage, 2);

            if(treasuryUSDAmount > minTreasuryUSDCBeforeSwap)
            {
                swapTreasuryUSDForRibe();
            }
            if(nft_holders_amount > 0)
                IERC20(tokenAddress).transfer(nft_holders_wallet, nft_holders_amount);
            if(deployer_amount > 0)
                IERC20(tokenAddress).transfer(deployer_wallet, deployer_amount);
        }else
        {
            IERC20(tokenAddress).transfer(owner(), amount);
        }
    }

    function onBuyFeeCollected(address tokenAddress, uint amount) external override
    {
        processRibeFees(tokenAddress, amount);
    }

    function onSellFeeCollected(address tokenAddress, uint amount) external override
    {
        processRibeFees(tokenAddress, amount);
    }

    fallback() external payable {}
    receive() external payable {}
}