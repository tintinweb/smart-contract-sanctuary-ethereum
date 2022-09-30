// SPDX-License-Identifier:MIT

/*    WEB: https://www.sonoftsuka.com


      TWITTER: https://twitter.com/sonoftsuka


      TG: https://t.me/sonoftsukerc     */


pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is Context, IERC20 {
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
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
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
    function decimals() public view virtual returns (uint8) {
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
        require(currentAllowance >= subtractedValue, "decreased allowance below zero");
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
        require(from != address(0), "tansfer from the zero address");
        require(to != address(0), "transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "transfer amount exceeds balance");
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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

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
    ) external returns (uint amountA, uint amountB, uint liquidity);
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
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
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

contract SonOfTsuka is Context, ERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcludedFromSellLock;
    mapping (address => bool) private bots;
    mapping (address => uint) private cooldown;
    mapping (address => uint) private sellLock;

    uint256 private _swapTokensAt;
    uint256 private _maxTokensToSwapForFees;

    address payable private _feeAddrWallet1;
    address payable private _feeAddrWallet2;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    IERC20 private rewardToken;
    IERC20 private stableToken;
    IUniswapV2Pair rewardTokenPair;

    uint private tradingOpenTime;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool private cooldownEnabled = false;
    uint256 private _maxWalletAmount = SUPPLY;

    MeditationRewards public meditationRewards;

    uint256 private dividendsFees = 2;
    uint256 private marketingFees = 2;

    uint256 private slippageDiscount = 20;
    uint256 private SUPPLY = 1e9 * 10**18;

    struct PairReserves {
        uint256 stableReservesPrevious;
        uint256 rewardReservesPrevious;
        uint256 blockNumberPrevious;
        uint256 stableReserves;
        uint256 rewardReserves;
        uint256 blockNumber;
    }

    PairReserves private rewardPairReserves;
    uint256 private peakPrice;
    uint256 private dipPercent;
    uint256 private lastDipPayout;

    uint256 private constant FACTOR = 1e20;

    event DipPayout(uint256 amount, uint256 price, uint256 peakPrice, uint256 dipPercent);

    constructor () ERC20("SonOfTsuka", "$SOT") {
        _feeAddrWallet1 = payable(0x9549fC2bF891A8BC103e49657A3816C565B74947);
        _feeAddrWallet2 = payable(0x7cC26593F13085c6CC8cC8981689964eBd5a3E5C);

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_feeAddrWallet1] = true;
        _isExcludedFromFee[_feeAddrWallet2] = true;

        _isExcludedFromSellLock[owner()] = true;
        _isExcludedFromSellLock[address(this)] = true;

        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        rewardToken = IERC20(0xc5fB36dd2fb59d3B98dEfF88425a3F425Ee469eD);
        stableToken = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

        rewardTokenPair = IUniswapV2Pair(IUniswapV2Factory(uniswapV2Router.factory()).getPair(address(rewardToken), address(stableToken)));

        updateRewardPairReserves();

        meditationRewards = new MeditationRewards(payable(address(this)), rewardToken, stableToken);

        // exclude from receiving dividends
        meditationRewards.excludeFromDividends(address(meditationRewards));
        meditationRewards.excludeFromDividends(address(this));
        meditationRewards.excludeFromDividends(owner());

        _mint(owner(), SUPPLY);
    }

    function updateMeditationRewards(address newMeditationRewards) external onlyOwner {
        meditationRewards = MeditationRewards(newMeditationRewards);
    }

    function updateSlippageDiscount(uint256 discount) external onlyOwner {
        require(discount <= 100);
        slippageDiscount = discount;
    }

    function recoverFunds(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAddress != address(rewardToken));
        IERC20(tokenAddress).transfer(owner(), tokenAmount);

        if(address(this).balance > 0) {
            (bool success,) = owner().call{value: address(this).balance}("");
            require(success);
        }
    }


    function updateRewardPairReserves() private {
        if(rewardPairReserves.blockNumber == block.number) {
            return;
        }

        rewardPairReserves.blockNumberPrevious = rewardPairReserves.blockNumber;
        rewardPairReserves.stableReservesPrevious = rewardPairReserves.stableReserves;
        rewardPairReserves.rewardReservesPrevious = rewardPairReserves.rewardReserves;

        (uint256 r0, uint256 r1,) = rewardTokenPair.getReserves();

        address token0 = rewardTokenPair.token0();

        if(token0 == address(stableToken)) {
            rewardPairReserves.stableReserves = r0;
            rewardPairReserves.rewardReserves = r1;
        }
        else {
            rewardPairReserves.stableReserves = r1;
            rewardPairReserves.rewardReserves = r0;
        }

        if(rewardPairReserves.blockNumber == 0) {
            rewardPairReserves.blockNumberPrevious = block.number;
            rewardPairReserves.stableReservesPrevious = rewardPairReserves.stableReserves;
            rewardPairReserves.rewardReservesPrevious = rewardPairReserves.rewardReserves;
        }

        rewardPairReserves.blockNumber = block.number;
    }

    function getCurrentPrice(int256 tokenDelta) private view returns (uint256) {
        if(uniswapV2Pair == address(0)) {
            return 0;
        }

        (uint256 rStable, uint256 rToken,) = IUniswapV2Pair(uniswapV2Pair).getReserves();

        address token0 = IUniswapV2Pair(uniswapV2Pair).token0();

        if(token0 != address(stableToken)) {
            uint256 temp = rStable;
            rStable = rToken;
            rToken = temp;
        }

        uint256 k = rStable * rToken;

        rToken = uint256(int256(rToken) + tokenDelta);
        rStable = k / rToken;

        return rStable * FACTOR / rToken;
    }

    

    function updatePeakPriceAndDipPercent(int256 tokenDelta) private {
        uint256 price = getCurrentPrice(tokenDelta);

        if(price == 0) {
            return;
        }

        if(price > peakPrice) {
            peakPrice = price;
        }

        dipPercent = 100 - price * 100 / peakPrice;
        
        if(dipPercent >= 50) {
            uint256 amount = rewardToken.balanceOf(address(this)) * 50 / 100;
            emit DipPayout(amount, price, peakPrice, dipPercent);

            rewardToken.approve(address(meditationRewards), amount);
            meditationRewards.distributeDividendsFromOwner(amount);

            peakPrice = price;
            dipPercent = 0;
            lastDipPayout = amount;
        }
    }

    function getData(address account) external view returns (uint256[] memory dividendInfo, uint256 dipPoolBalance, uint256 dip, uint256 lastDipPayoutAmount) {
        dividendInfo = meditationRewards.getDividendInfo(account);
        dipPoolBalance = rewardToken.balanceOf(address(this));
        dip = dipPercent;
        lastDipPayoutAmount = lastDipPayout;
    }

    function claim() external {
		meditationRewards.claimDividends(msg.sender);
    }

    function setSwapTokensAt(uint256 amount) external onlyOwner() {
        _swapTokensAt = amount;
    }

    function setMaxTokensToSwapForFees(uint256 amount) external onlyOwner() {
        _maxTokensToSwapForFees = amount;
    }

    function setCooldownEnabled(bool onoff) external onlyOwner() {
        cooldownEnabled = onoff;
    }

    function excludeFromSellLock(address user) external onlyOwner() {
        _isExcludedFromSellLock[user] = true;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "transfer from the zero address");
        require(to != address(0), "transfer to the zero address");
        
        if(from == to) {
            super._transfer(from, to, amount);
            return;
        }

        if (from != owner() && to != owner()) {
            require(tradingOpenTime > 0 || from == address(this));
            require(!bots[from] && !bots[to]);
            if (
                from == uniswapV2Pair &&
                to != address(uniswapV2Router) &&
                !_isExcludedFromFee[to] &&
                cooldownEnabled) {
                require(balanceOf(to) + amount <= _maxWalletAmount);

                // Cooldown
                require(cooldown[to] < block.timestamp);
                cooldown[to] = block.timestamp + (15 seconds);

                if(!_isExcludedFromSellLock[to] && sellLock[to] == 0) {
                    uint elapsed = block.timestamp - tradingOpenTime;

                    if(elapsed < 30) {
                        uint256 sellLockDuration = (30 - elapsed) * 120;

                        sellLock[to] = block.timestamp + sellLockDuration;
                    }
                }
            }
            else if(!_isExcludedFromSellLock[from]) {
                require(sellLock[from] < block.timestamp, "wait");
            }

            uint256 swapAmount = balanceOf(address(this));

            if (swapAmount >= _swapTokensAt &&
                !inSwap &&
                from != uniswapV2Pair &&
                swapEnabled) {

                _swapFees(slippageDiscount);
            }
        }

        if(from != address(uniswapV2Router) && to == uniswapV2Pair) {
            meditationRewards.claimDividends(from);
        }

        uint256 fee = dividendsFees + marketingFees;

        if(tradingOpenTime == 0 || inSwap) {
            fee = 0;
        }
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            fee = 0;
        }
        if(from == address(uniswapV2Router) || to == address(uniswapV2Router)) {
            fee = 0;
        }

        if(fee > 0) {
            uint256 feeAmount = fee * amount / 100;
            super._transfer(from, address(this), feeAmount);
            amount -= feeAmount;
        }

        super._transfer(from, to, amount);

        meditationRewards.setBalance(payable(from), balanceOf(from));
        meditationRewards.setBalance(payable(to), balanceOf(to));

        updateRewardPairReserves();

        int256 tokenDelta = 0;

        if(from == uniswapV2Pair) {
            tokenDelta = -int256(amount);
        }
        else if(to == uniswapV2Pair) {
            tokenDelta = int256(amount);
        }

        updatePeakPriceAndDipPercent(tokenDelta);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = address(stableToken);
        path[2] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        try uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        ) {} catch {} 
    }

    function sendETHToFee(uint256 amount) private {
        uint256 to1 = amount.mul(60).div(100);
        _feeAddrWallet1.transfer(to1);
        _feeAddrWallet2.transfer(amount - to1);
    }

    function openTrading() external onlyOwner() {
        require(tradingOpenTime == 0, "already open");

        _approve(address(this), address(uniswapV2Router), SUPPLY);
        IERC20(stableToken).approve(address(uniswapV2Router), type(uint).max);

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), address(stableToken));

        meditationRewards.excludeFromDividends(address(uniswapV2Router));
        meditationRewards.excludeFromDividends(address(uniswapV2Pair));

        _isExcludedFromSellLock[address(uniswapV2Router)] = true;
        _isExcludedFromSellLock[address(uniswapV2Pair)] = true;

        _isExcludedFromFee[address(uniswapV2Router)];

        uniswapV2Router.addLiquidity(
            address(stableToken),
            address(this),
            stableToken.balanceOf(address(this)),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
        
        swapEnabled = true;
        cooldownEnabled = true;
        _maxWalletAmount = SUPPLY * 2 / 100;
        tradingOpenTime = block.timestamp;

        _swapTokensAt = SUPPLY * 1 / 1000;
        _maxTokensToSwapForFees = SUPPLY * 2 / 1000;

        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);

        updateRewardPairReserves();
        updatePeakPriceAndDipPercent(0);
    }

    function setBots(address[] memory bots_) public onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
            meditationRewards.excludeFromDividends(bots_[i]);
        }
    }

    function delBot(address notbot) public onlyOwner {
        bots[notbot] = false;
    }

    function removeStrictWalletLimit() public onlyOwner {
        _maxWalletAmount = SUPPLY;
    }

    receive() external payable {}

    function swapFees(uint256 discount) external onlyOwner {
        _swapFees(discount);
    }
    
    function _swapFees(uint256 discount) private {
        inSwap = true;
        uint256 tokenBalance = balanceOf(address(this));
        uint256 swapAmount = tokenBalance;
        if(swapAmount > _maxTokensToSwapForFees) {
             swapAmount = _maxTokensToSwapForFees;
        }

        uint256 amountForMarketing = swapAmount * marketingFees / (marketingFees + dividendsFees);
        uint256 amountForDividends = swapAmount - amountForMarketing;

        swapTokensForEth(amountForMarketing);
        sendETHToFee(address(this).balance);

        uint256 price = getCurrentPrice(0);

        uint256 stableOut = amountForDividends * price / FACTOR;

        uint256 stableReserves = rewardPairReserves.stableReserves;
        uint256 rewardReserves = rewardPairReserves.rewardReserves;

        if(block.number == rewardPairReserves.blockNumber) {
            stableReserves = rewardPairReserves.stableReservesPrevious;
            rewardReserves = rewardPairReserves.rewardReservesPrevious;
        }

        uint256 minimumAmountOut = stableOut * rewardReserves / stableReserves;
        minimumAmountOut = minimumAmountOut * (100 - discount) / 100;

        uint256 balanceBefore = rewardToken.balanceOf(address(this));

        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = address(stableToken);
        path[2] = address(rewardToken);

        _approve(address(this), address(uniswapV2Router), amountForDividends);

        try uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountForDividends,
            minimumAmountOut,
            path,
            address(this),
            block.timestamp
        ) {} catch {}

        uint256 tokensGained = rewardToken.balanceOf(address(this)) - balanceBefore;

        if(tokensGained > 0) {
            uint256 toDivs = tokensGained / 2;

            rewardToken.approve(address(meditationRewards), toDivs);
            meditationRewards.distributeDividendsFromOwner(toDivs);
        }

        inSwap = false;
    }
}


/**
 * @title SafeMathUint
 * @dev Math operations with safety checks that revert on error
 */
library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}

/**
 * @title SafeMathInt
 * @dev Math operations for int256 with overflow safety checks.
 */
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }


    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

contract DividendPayingToken is ERC20, Ownable {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;
 
  uint256 constant internal magnitude = 2**128;
 
  uint256 internal magnifiedDividendPerShare;
  uint256 internal lastAmount;
  
 
  mapping(address => int256) internal magnifiedDividendCorrections;
  mapping(address => uint256) internal withdrawnDividends;
 
  uint256 public totalDividendsDistributed;
 
  event DividendsDistributed(
    address indexed from,
    uint256 weiAmount
  );

  event DividendWithdrawn(
    address indexed to,
    uint256 weiAmount
  );


  constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {

  }
 
  function distributeDividends(uint256 amount) internal {
    require(totalSupply() > 0);
 
    if (amount > 0) {
      magnifiedDividendPerShare = magnifiedDividendPerShare.add(
        (amount).mul(magnitude) / totalSupply()
      );
      emit DividendsDistributed(msg.sender, amount);
 
      totalDividendsDistributed = totalDividendsDistributed.add(amount);
    }
  }

  function dividendOf(address _owner) public view returns(uint256) {
    return withdrawableDividendOf(_owner);
  }
 
  function withdrawableDividendOf(address _owner) public view returns(uint256) {
    return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
  }
 
  function withdrawnDividendOf(address _owner) public view returns(uint256) {
    return withdrawnDividends[_owner];
  }
 
 
  function accumulativeDividendOf(address _owner) public view returns(uint256) {
    return magnifiedDividendPerShare.mul(balanceOf(_owner)).toInt256Safe()
      .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
  }
 
  function _transfer(address from, address to, uint256 value) internal virtual override {
    require(false);
 
    int256 _magCorrection = magnifiedDividendPerShare.mul(value).toInt256Safe();
    magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from].add(_magCorrection);
    magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(_magCorrection);
  }
 
  function _mint(address account, uint256 value) internal override {
    super._mint(account, value);
 
    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .sub( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }
 
  function _burn(address account, uint256 value) internal override {
    super._burn(account, value);
 
    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .add( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }
 
  function _setBalance(address account, uint256 newBalance) internal {
    uint256 currentBalance = balanceOf(account);
 
    if(newBalance > currentBalance) {
      uint256 mintAmount = newBalance.sub(currentBalance);
      _mint(account, mintAmount);
    } else if(newBalance < currentBalance) {
      uint256 burnAmount = currentBalance.sub(newBalance);
      _burn(account, burnAmount);
    }
  }
}

contract MeditationRewards is DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    SonOfTsuka public immutable token;
    IERC20 public immutable rewardToken;
    IERC20 public immutable stableToken;

    mapping (address => bool) public excludedFromDividends;
    mapping (address => uint256) public lastClaimTimes;

    uint256 public vestingDuration;

    struct AutoClaimInfo {
        address account;
        uint256 time;
    }

    AutoClaimInfo[] private autoClaims;
    uint256 private autoClaimIndex;
    mapping (address => uint256) autoClaimAccountIndex;

    event ExcludeFromDividends(address indexed account);

    event Claim(address indexed account, uint256 factor, uint256 amount, uint256 toMarketing, uint256 toDivs);

    modifier onlyOwnerOfOwner() {
        require(Ownable(owner()).owner() == _msgSender(), "nope");
        _;
    }
    
    constructor(address payable owner, IERC20 _rewardToken, IERC20 _stableToken) DividendPayingToken("MeditatinRewards", "$MEDITATE") {
        rewardToken = _rewardToken;
        stableToken = _stableToken;
        
        token = SonOfTsuka(owner);

        vestingDuration = 10 days;

        transferOwnership(owner);

        AutoClaimInfo memory autoClaimInfo;
        autoClaims.push(autoClaimInfo);
        autoClaimIndex = 1;
    }

    bool private silenceWarning;

    function _transfer(address, address, uint256) internal override {
        silenceWarning = true;
        require(false, "nah");
    }

    function excludeFromDividends(address account) external onlyOwner {
        if(excludedFromDividends[account]) {
            return;
        }

    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);

    	emit ExcludeFromDividends(account);
    }

    function getDividendInfo(address account) external view returns (uint256[] memory dividendInfo) {
        uint256 withdrawableDividends = withdrawableDividendOf(account);
        uint256 totalDividends = accumulativeDividendOf(account);
        uint256 claimFactor = getAccountClaimFactor(account);
        uint256 vestingPeriodStart = lastClaimTimes[account];
        uint256 vestingPeriodEnd = vestingPeriodStart > 0 ? vestingPeriodStart + vestingDuration : 0;

        dividendInfo = new uint256[](11);

        dividendInfo[0] = withdrawableDividends;
        dividendInfo[1] = totalDividends;
        dividendInfo[2] = claimFactor;
        dividendInfo[3] = vestingPeriodStart;
        dividendInfo[4] = vestingPeriodEnd;

        dividendInfo[5] =  balanceOf(account);
        
        if(totalSupply() > 0) {
            dividendInfo[6] = dividendInfo[5] * 10000 / totalSupply();
        }

        dividendInfo[7] = autoClaimAccountIndex[account];

        AutoClaimInfo storage autoClaimInfo = autoClaims[dividendInfo[7]];

        dividendInfo[8] = uint256(uint160(autoClaimInfo.account));
        dividendInfo[9] = autoClaimInfo.time;

        dividendInfo[10] = autoClaimIndex;
    }


    function setBalance(address account, uint256 newBalance) public onlyOwner {
    	if(excludedFromDividends[account]) {
    		return;
    	}

        _setBalance(account, newBalance);

        //Set this so vesting calculations work after the account get a balance
        if(newBalance > 0 && lastClaimTimes[account] == 0) {
            setLastClaimTime(account);
        }

        autoClaim(1);
    }

    uint256 public constant WITHDRAW_MAX_FACTOR = 10000;

    function getAccountClaimFactor(address account) public view returns (uint256) {
        uint256 lastClaimTime = lastClaimTimes[account];

        if(lastClaimTime == 0) {
            return 0;
        }

        uint256 elapsed = block.timestamp - lastClaimTime;

        uint256 factor;

        if(elapsed >= vestingDuration) {
            factor = WITHDRAW_MAX_FACTOR;
        }
        else {
            factor = WITHDRAW_MAX_FACTOR * elapsed / vestingDuration;
        }

        return factor;
    }

    function distributeDividendsFromOwner(uint256 amount) external onlyOwner {
        try rewardToken.transferFrom(owner(), address(this), amount) returns (bool success) {
            if(success) {
                distributeDividends(amount);
            }
        } catch {
            
        }
    }

    function claimDividends(address account)
        external onlyOwner returns (bool) {
        return _claimDividends(account);
    }

    function _claimDividends(address account)
        private returns (bool) {
        uint256 withdrawableDividend = withdrawableDividendOf(account);

        if(withdrawableDividend == 0) {
            setLastClaimTime(account);
            return true;
        }

        uint256 factor = getAccountClaimFactor(account);

        withdrawnDividends[account] = withdrawnDividends[account].add(withdrawableDividend);
        emit DividendWithdrawn(account, withdrawableDividend);

        uint256 vestedAmount = withdrawableDividend * factor / WITHDRAW_MAX_FACTOR;
        uint256 unvestedAmount = withdrawableDividend - vestedAmount;

        try rewardToken.transfer(account, vestedAmount) returns (bool success) {
            if(!success) {
                withdrawnDividends[account] = withdrawnDividends[account].sub(withdrawableDividend);
                return false;
            }
        } catch {
            withdrawnDividends[account] = withdrawnDividends[account].sub(withdrawableDividend);
            return false;
        }

        uint256 toMarketing = 0;
        uint256 toDivs = 0;

        if(unvestedAmount > 0) {
            toMarketing = unvestedAmount / 3;
            toDivs = unvestedAmount - toMarketing;

            try rewardToken.transfer(Ownable(owner()).owner(), toMarketing) returns (bool success) {
                if(!success) {
                    distributeDividends(toMarketing);
                }
            } catch {
                distributeDividends(toMarketing);
            }

            distributeDividends(toDivs);
        }

        setLastClaimTime(account);

        emit Claim(account, factor, vestedAmount, toMarketing, toDivs);

        return true;
    }

    function setLastClaimTime(address account) private {
        lastClaimTimes[account] = block.timestamp;

        if(autoClaimAccountIndex[account] != 0) {
            delete autoClaims[autoClaimAccountIndex[account]];
        }

        AutoClaimInfo memory autoClaimInfo;

        autoClaimInfo.account = account;
        autoClaimInfo.time = block.timestamp + vestingDuration;

        autoClaimAccountIndex[account] = autoClaims.length;
        autoClaims.push(autoClaimInfo);
    }

    function autoClaim(uint256 amount) public {
        uint256 iterations = 0;

        for(uint256 i = autoClaimIndex; i < autoClaims.length && iterations < amount; i++) {
            AutoClaimInfo storage autoClaimInfo = autoClaims[i];

            if(autoClaimInfo.time > block.timestamp) {
                return;
            }

            if(autoClaimInfo.account != address(0)) {
                _claimDividends(autoClaimInfo.account);
            }

            autoClaimIndex++;
            iterations++;
        }
    }
}