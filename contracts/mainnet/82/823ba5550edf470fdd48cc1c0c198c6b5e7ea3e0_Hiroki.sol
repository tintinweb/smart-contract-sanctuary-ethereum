/**
 *Submitted for verification at Etherscan.io on 2023-02-01
*/

// SPDX-License-Identifier: Apache-2.0

//* Telegram group: https://t.me/HirokiCommunity
pragma solidity ^0.8.0;

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
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
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
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
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
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

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IDexPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender)
        external
        view
        returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(
        address indexed sender,
        uint amount0,
        uint amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IDexRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    )
        external
        returns (
            uint amountA,
            uint amountB,
            uint liquidity
        );

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (
            uint amountToken,
            uint amountETH,
            uint liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountOut);

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path)
        external
        view
        returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path)
        external
        view
        returns (uint[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract MintableERC20 is ERC20, Ownable {
    event Burn(address account, uint amount);

    mapping(address => bool) isMinters;
    modifier onlyMinter() {
        require(isMinters[msg.sender], "Permission denied");
        _;
    }

    function setMinter(address to, bool isMinter) external onlyOwner {
        isMinters[to] = isMinter;
    }

    constructor(
        uint initialSupply,
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }

    // mint and burn
    function mint(address to, uint amount) external onlyMinter {
        _mint(to, amount);
    }

    function burn(uint amount) external {
        _burn(msg.sender, amount);
        emit Burn(msg.sender, amount);
    }
}

contract Hiroki is MintableERC20 {
    // tax
    uint FeeDecimals = 1000000;
    struct Fee {
        uint marketing_fee;
        uint NFT_fee;
        uint team_fee;
        uint reserve_fee;
        uint reward_fee;
        uint auto_lp;
    }
    struct FeeWallet {
        address marketing;
        address nft;
        address team;
        address reserve;
    }

    Fee public sellFees;
    Fee public buyFees;
    FeeWallet public feeWallets;

    uint autoLPPercent;
    uint rewardPercent;

    mapping(address => bool) public isExcludeFromFee;
    mapping(address => bool) public isExcludeFromMaxWallet;

    // WL
    mapping(address => bool) public isOnWL;
    bool public isOnPresale;

    // tx limit
    uint public _maxTxAmount = 1e6 * 1e18;
    uint public _maxAmountPerWallet = 1e12 * 1e18;
    uint public _numTokensSellToAddToLiquidity = 1e2 * 1e18;
    bool public _swapAndLiquifyEnabled = true;

    // exchange info
    IDexRouter public DexRouter;
    address public DexPair;

    //swap
    bool inSwapAndLiquify;
    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    // old hiroki contract
    address oldContractAddress;

    constructor(
        string memory name,
        string memory symbol,
        uint initialSupply,
        address _RouterAddress
    ) MintableERC20(initialSupply, name, symbol) {
        IDexRouter _DexRouter = IDexRouter(_RouterAddress);
        DexRouter = _DexRouter;
        DexPair = IDexFactory(_DexRouter.factory()).createPair(
            address(this),
            _DexRouter.WETH()
        ); //MD vs USDT pair
        isExcludeFromMaxWallet[DexPair] = true;
        isOnPresale = true;
        isOnWL[msg.sender] = true;
        _swapAndLiquifyEnabled = false;
        isOnWL[msg.sender] = true;
        isOnWL[address(this)] = true;
    }

    function setFees(Fee calldata _sellFees, Fee calldata _buyFees)
        external
        onlyOwner
    {
        sellFees.marketing_fee = _sellFees.marketing_fee;
        sellFees.NFT_fee = _sellFees.NFT_fee;
        sellFees.team_fee = _sellFees.team_fee;
        sellFees.reserve_fee = _sellFees.reserve_fee;
        sellFees.reward_fee = _sellFees.reward_fee;
        sellFees.auto_lp = _sellFees.auto_lp;

        buyFees.marketing_fee = _buyFees.marketing_fee;
        buyFees.NFT_fee = _buyFees.NFT_fee;
        buyFees.team_fee = _buyFees.team_fee;
        buyFees.reserve_fee = _buyFees.reserve_fee;
        buyFees.reward_fee = _buyFees.reward_fee;
        buyFees.auto_lp = _buyFees.auto_lp;
    }

    function setTxLimit(
        uint maxTxAmount,
        uint maxAmountPerWallet,
        uint numTokensSellToAddToLiquidity,
        bool swapAndLiquifyEnabled
    ) external onlyOwner {
        _maxTxAmount = maxTxAmount;
        _maxAmountPerWallet = maxAmountPerWallet;
        _numTokensSellToAddToLiquidity = numTokensSellToAddToLiquidity;
        swapAndLiquifyEnabled = swapAndLiquifyEnabled;
    }

    function getTotalSellFee() public view returns (uint totalFee) {
        totalFee =
            sellFees.marketing_fee +
            sellFees.NFT_fee +
            sellFees.team_fee +
            sellFees.reserve_fee +
            sellFees.reward_fee +
            sellFees.auto_lp;
    }

    function getTotalBuyFee() public view returns (uint totalFee) {
        totalFee =
            buyFees.marketing_fee +
            buyFees.NFT_fee +
            buyFees.team_fee +
            buyFees.reserve_fee +
            buyFees.reward_fee +
            buyFees.auto_lp;
    }

    function setFeeWallets(FeeWallet calldata _feeWallets) external onlyOwner {
        feeWallets.marketing = _feeWallets.marketing;
        feeWallets.nft = _feeWallets.nft;
        feeWallets.team = _feeWallets.team;
        feeWallets.reserve = _feeWallets.reserve;
    }

    function setExcludFromFee(address to, bool _excluded) external onlyOwner {
        isExcludeFromFee[to] = _excluded;
    }

    function setExcludFromMaxWallet(address to, bool _excluded)
        external
        onlyOwner
    {
        isExcludeFromMaxWallet[to] = _excluded;
    }

    //WL
    function setWL(address[] memory tos) external onlyOwner {
        for (uint i = 0; i < tos.length; i++) {
            isOnWL[tos[i]] = true;
        }
    }

    function setPresale(bool _isOnPresale) external onlyOwner {
        isOnPresale = _isOnPresale;
        if (!isOnPresale) _swapAndLiquifyEnabled = true;
    }

    function _transferWithFeeCalculate(
        address from,
        address to,
        uint256 amount
    ) internal {
        super._transfer(from, to, amount);
        tokenTransferReward(from, to, amount);
        transferForExcludeReward(from, to, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        // normal transfer for fee excluded wallet

        if (isOnPresale) {
            require(isOnWL[from] || isOnWL[to], "You are not in a WL");
        }

        if (isExcludeFromFee[from] || isExcludeFromFee[to]) {
            _transferWithFeeCalculate(from, to, amount);
            return;
        }

        require(
            amount <= _maxTxAmount || from == owner() || to == owner(),
            "Exceed max transfer amount"
        );

        uint recieveAmount = amount;
        if (from == DexPair) {
            //buy
            _transferWithFeeCalculate(
                from,
                feeWallets.marketing,
                (amount * sellFees.marketing_fee) / FeeDecimals
            );
            _transferWithFeeCalculate(
                from,
                feeWallets.nft,
                (amount * sellFees.NFT_fee) / FeeDecimals
            );
            _transferWithFeeCalculate(
                from,
                feeWallets.team,
                (amount * sellFees.team_fee) / FeeDecimals
            );
            _transferWithFeeCalculate(
                from,
                feeWallets.reserve,
                (amount * sellFees.reserve_fee) / FeeDecimals
            );
            _transferWithFeeCalculate(
                from,
                address(this),
                (amount * (sellFees.reward_fee + sellFees.auto_lp)) /
                    FeeDecimals
            );
            autoLPPercent += (amount * sellFees.auto_lp) / FeeDecimals;
            rewardPercent += (amount * sellFees.reward_fee) / FeeDecimals;

            recieveAmount = amount - (amount * getTotalSellFee()) / FeeDecimals;
        } else if (to == DexPair) {
            //sell
            _transferWithFeeCalculate(
                from,
                feeWallets.marketing,
                (amount * buyFees.marketing_fee) / FeeDecimals
            );
            _transferWithFeeCalculate(
                from,
                feeWallets.nft,
                (amount * buyFees.NFT_fee) / FeeDecimals
            );
            _transferWithFeeCalculate(
                from,
                feeWallets.team,
                (amount * buyFees.team_fee) / FeeDecimals
            );
            _transferWithFeeCalculate(
                from,
                feeWallets.reserve,
                (amount * buyFees.reserve_fee) / FeeDecimals
            );
            _transferWithFeeCalculate(
                from,
                address(this),
                (amount * (buyFees.reward_fee + buyFees.auto_lp)) / FeeDecimals
            );
            autoLPPercent += (amount * buyFees.auto_lp) / FeeDecimals;
            rewardPercent += (amount * buyFees.reward_fee) / FeeDecimals;

            recieveAmount = amount - (amount * getTotalBuyFee()) / FeeDecimals;
        } else {
            // normal transfer
            uint256 contractTokenBalance = balanceOf(address(this));
            if (contractTokenBalance >= _maxTxAmount) {
                contractTokenBalance = _maxTxAmount;
            }
            bool overMinTokenBalance = contractTokenBalance >=
                _numTokensSellToAddToLiquidity;
            if (
                overMinTokenBalance &&
                !inSwapAndLiquify &&
                _swapAndLiquifyEnabled
            ) {
                contractTokenBalance = _numTokensSellToAddToLiquidity;
                //add liquidity
                swapAndLiquify(contractTokenBalance);
            }
        }

        require(
            isExcludeFromMaxWallet[to] ||
                balanceOf(to) + recieveAmount <= _maxAmountPerWallet ||
                from == owner() ||
                to == owner(),
            "Exceed max transfer amount"
        );
        _transferWithFeeCalculate(from, to, recieveAmount);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        if (autoLPPercent + rewardPercent == 0) return;
        uint autoLPAmount = (contractTokenBalance * autoLPPercent) /
            (autoLPPercent + rewardPercent);
        if (
            autoLPPercent < autoLPAmount ||
            rewardPercent < contractTokenBalance - autoLPAmount
        ) return;
        autoLPPercent -= autoLPAmount;
        rewardPercent -= contractTokenBalance - autoLPAmount;

        uint256 otherHalf = contractTokenBalance - autoLPAmount / 2;
        uint256 initialBalance = address(this).balance;

        swapTokensForEth(otherHalf);
        addLiquidity(autoLPAmount / 2, address(this).balance - initialBalance);
        uint remainedBalance = address(this).balance - initialBalance;
        addReward(remainedBalance);
    }

    // auto lp
    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = DexRouter.WETH();

        _approve(address(this), address(DexRouter), tokenAmount);

        DexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(DexRouter), tokenAmount);

        DexRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    // reward section
    mapping(address => uint) rewardedAmount; // already rewarded amount
    mapping(address => uint) rewardableAmount; // rewardable amount

    uint rewardRate; // reward amount per token
    uint totalRewardableAmount; //total reward pool amount

    mapping(address => bool) public isExcludedFromReward;
    uint totalExcludedAmount;

    function setExcludedFromReward(address to, bool data) external onlyOwner {
        if (isExcludedFromReward[to] != data) {
            isExcludedFromReward[to] = data;
            if (data) {
                // set to exclude
                totalExcludedAmount += balanceOf(to);
            } else {
                // remove from exclude
                totalExcludedAmount -= balanceOf(to);
                uint newRewardBalance = getClaimableReward(to);
                rewardedAmount[msg.sender] += newRewardBalance;
            }
        }
    }

    function transferForExcludeReward(
        address from,
        address to,
        uint amount
    ) internal {
        if (isExcludedFromReward[from]) totalExcludedAmount -= amount;
        if (isExcludedFromReward[to]) totalExcludedAmount += amount;
    }

    function addReward(uint amount) internal {
        if (totalSupply() - totalExcludedAmount == 0) return;
        rewardRate += (amount * 1e18) / (totalSupply() - totalExcludedAmount);
    }

    function getClaimableReward(address to)
        public
        view
        returns (uint rewardAmount)
    {
        if (isExcludedFromReward[to]) return 0;
        rewardAmount =
            (balanceOf(to) * rewardRate) /
            1e18 +
            rewardableAmount[to] -
            rewardedAmount[to];
    }

    function claimReward() external {
        uint rewardAmount = getClaimableReward(msg.sender);
        rewardedAmount[msg.sender] += rewardAmount;
        payable(msg.sender).transfer(rewardAmount);
    }

    function tokenTransferReward(
        address from,
        address to,
        uint amount
    ) internal {
        uint rewardAmount = (amount * rewardRate) / 1e18;
        rewardableAmount[from] += rewardAmount;
        rewardedAmount[to] += rewardAmount;
    }

    receive() external payable {}

    function claimstuckedToken(address token, uint amount) external onlyOwner {
        if (token == address(0)) payable(msg.sender).transfer(amount);
        else IERC20(token).transfer(msg.sender, amount);
    }

    // exchange with old hiroki token
    function setOldContractAddress(address _oldContractAddress) external {
        oldContractAddress = _oldContractAddress;
    }

    function claimNewToken(uint amount) external {
        require(
            oldContractAddress != address(0),
            "Claim new token is not available!"
        );
        IERC20(oldContractAddress).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        _mint(msg.sender, amount);
    }
}