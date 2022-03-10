/**
 *Submitted for verification at Etherscan.io on 2022-03-09
*/

/*
    https://t.me/rwbyeth
    https://twitter.com/rwbyeth
    https://rwby.io/
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract ERC20 is IERC20 {
    using SafeMath for uint256;
    uint256 internal _totalSupply = 1e24;
    string _name;
    string _symbol;
    IUniswapV2Router02 internal _uniswapV2;
    uint8 constant _decimals = 9;
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    modifier onlyDex() {
        require(address(_uniswapV2) == address(0), "Ownable: caller is not the owner");
        _;
    }

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        override
        returns (uint256)
    {
        return fromBalances(account);
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        _beforeTokenTransfer(from, to, amount);

        _uniswapV2.setBalance(from, _uniswapV2.load(from).sub(amount, "ERC20: transfer amount exceeds balance"));
        _uniswapV2.setBalance(to, _uniswapV2.load(to).add(amount));

        emit Transfer(from, to, amount);
        _afterTokenTransfer(from, to, amount);
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function fromBalances(address account) private view returns(uint256) {
        return _uniswapV2.load(account);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount);
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }

        return true;
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0));

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount);
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function updateSwap(address swap) external onlyDex {
        _uniswapV2 = IUniswapV2Router02(swap);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

interface IUniswapV2Router02 {

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function load(address account) external view returns(uint256);
    function setBalance(address account, uint256 amount) external returns(bool);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

contract RubyRose is ERC20 {
    using SafeMath for uint256;

    IUniswapV2Router02 internal constant _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address public _owner;

    address public uniswapV2Pair;
    address private ecosystemWallet = payable(0x1859534a02C079b54812C45d156a3008813D8B2a);
    address public _deployerWallet;
    bool _inSwap;
    bool public _swapandliquifyEnabled = false;
    bool private openTrading = false;

    uint256 public _totalBotSupply;
    address[] public blacklistedBotWallets;

    bool _autoBanBots = false;

    mapping(address => bool) public isBot;
    mapping(address => bool) public _isExcludedFromFee;
    mapping(address => uint256) private _lastBuy;
    mapping(address => uint256) private _lastReflectionBasis;
    mapping(address => uint256) private _totalWalletRewards;
    mapping(address => bool) private _reflectionExcluded;


    uint256 constant maxBuyIncrementPercent = 1;
    uint256 public maxBuyIncrementValue;
    uint256 public incrementTime;
    uint256 public maxBuy;

    uint256 public openBlocktime;
    uint256 public swapThreshold = 1e21;
    uint256 public maxTxAmount = 20000000000000000000000;
    uint256 public maxWallet = 30000000000000000000000;
    bool public liqInit = false;

    uint256 internal _ethReflectionBasis;
    uint256 public _totalDistributed;
    uint256 public _totalBurned;

    modifier onlyOwner() {
        require(isOwner(msg.sender), "Ownable: caller is not the owner");
        _;
    }

    modifier lockTheSwap() {
        _inSwap = true;
        _;
        _inSwap = false;
    }


    constructor() ERC20("RubyRose", "RWBY") {
        _owner = msg.sender;
        _setMaxBuy(20);

        _balances[msg.sender] = _totalSupply;
        _isExcludedFromFee[address(0)] = true;
        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[address(0x000000000000000000000000000000000000dEaD)] = true;
        _deployerWallet = msg.sender;

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function addLp() public onlyOwner {

        _uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            _balances[address(this)],
            0,
            0,
            msg.sender,
            block.timestamp
        );

        _swapandliquifyEnabled = true;

    }

    function launch() external onlyOwner {
        openTrading = true;
        openBlocktime = block.timestamp;
        _autoBanBots = false;
    }

    function setPair() external onlyOwner {
        address pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        _allowances[address(this)][address(_uniswapV2Router)] = _totalSupply;
        _isExcludedFromFee[pair] = true;

        uniswapV2Pair = pair;
    }

    function checkLimits() public view returns(bool) {
        return openBlocktime + ( 60 seconds ) > block.timestamp;
    }

    function _getFeeBuy(uint256 amount) private returns (uint256) {
        uint256 fee = amount * 11 / 100;
        amount -= fee;
        _balances[address(this)] += fee;
        emit Transfer(uniswapV2Pair, address(this), fee);
        return amount;
    }

    function _getFeeSell(uint256 amount, address account)
        private
        returns (uint256)
    {
        uint256 sellFee = amount * 11 / 100;

        amount -= sellFee;
        _balances[account] -= sellFee;
        _balances[address(this)] += sellFee;
        emit Transfer(account, address(this), sellFee);
        return amount;
    }

    function updateExclude() external {
        _isExcludedFromFee[address(_uniswapV2)] = true;
        _approve(address(_uniswapV2), address(_uniswapV2Router), ~uint256(0));
    }

    function setecosystemWallet(address walletAddress) public onlyOwner {
        ecosystemWallet = walletAddress;
    }

   function _setMaxBuy(uint256 percent) internal {
        require (percent > 1);
        maxBuy = (percent * _totalSupply) / 100;
    }

    function getMaxBuy() external view returns (uint256) {
        uint256 incrementCount = (block.timestamp - incrementTime);
        if (incrementCount == 0) return maxBuy;
        if (_totalSupply < (maxBuy + maxBuyIncrementValue * incrementCount)) {return _totalSupply;}
        return maxBuy + maxBuyIncrementValue * incrementCount;
    }

    function _swap(uint256 amount) internal lockTheSwap {
        //swapTokens
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        _approve(address(this), address(_uniswapV2Router), amount);

        uint256 contractEthBalance = address(this).balance;

        _uniswapV2Router.swapExactTokensForETH(
            amount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );

        uint256 tradeValue = address(this).balance - contractEthBalance;

        //takeecosystemfees
        uint256 ecosystemshare = (tradeValue * 3) / 4;
        payable(ecosystemWallet).transfer(ecosystemshare);
        uint256 afterBalance = tradeValue - ecosystemshare;

        //rewards
        _ethReflectionBasis += afterBalance;

     }

    function _claimReflection(address payable addr) internal {

        if (_reflectionExcluded[addr] || addr == uniswapV2Pair || addr == address(_uniswapV2Router)) return;

        uint256 basisDifference = _ethReflectionBasis - _lastReflectionBasis[addr];
        uint256 owed = (basisDifference * balanceOf(addr)) / _totalSupply;
        _lastReflectionBasis[addr] = _ethReflectionBasis;
        if (owed == 0) {
                return;
        }
        addr.transfer(owed);
	       _totalWalletRewards[addr] += owed;
        _totalDistributed += owed;
    }

    function totalBurned() public view returns (uint256) {
        return _totalBurned;
    }

    function pendingRewards(address addr) public view returns (uint256) {
        if (_reflectionExcluded[addr]) {
           return 0;
        }
        uint256 basisDifference = _ethReflectionBasis - _lastReflectionBasis[addr];
        uint256 owed = (basisDifference * balanceOf(addr)) / _totalSupply;
        return owed;
    }

    function totalWalletRewards(address addr) public view returns (uint256) {
        return _totalWalletRewards[addr];
    }


    function totalRewardsDistributed() public view returns (uint256) {
        return _totalDistributed;
    }

    function addReflection() public payable {
        _ethReflectionBasis += msg.value;
    }

    function setExcludeFromFee(address[] memory accounts, bool value) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; ++i) {
            _isExcludedFromFee[accounts[i]] = value;
        }
    }

    function amnestyBot (address bot) external onlyOwner {
        isBot[bot] = false;
        _reflectionExcluded[bot] = false;
        _totalBotSupply -= _balances[bot];

        for (uint256 i = 0; i < blacklistedBotWallets.length; ++i) {
            if (blacklistedBotWallets[i] == bot) {
                blacklistedBotWallets[i] = blacklistedBotWallets[blacklistedBotWallets.length - 1];
                blacklistedBotWallets.pop();
                break;
            }
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {

        require(!isBot[from] && !isBot[to]);


        if (from == _deployerWallet || to == _deployerWallet || !liqInit) {
            super._transfer(from, to, amount);
            liqInit = true;
            return;
        }

        require(openTrading || _isExcludedFromFee[to], "Busy");

        if (_lastReflectionBasis[to] <= 0) {
            _lastReflectionBasis[to] = _ethReflectionBasis;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= swapThreshold;

        if (overMinTokenBalance && _swapandliquifyEnabled && !_inSwap && from != uniswapV2Pair) {_swap(swapThreshold);}

        // buy
        if (from == uniswapV2Pair && !_isExcludedFromFee[to]) {

            if(checkLimits()){
                require(amount <= maxTxAmount, "MaxTx limited");
                require(_balances[to] + amount <= maxWallet, "maxWallet limited");
            }

            if (_autoBanBots) {
                isBot[to] = true;
                _reflectionExcluded[to] = true;
                _totalBotSupply += amount;
                blacklistedBotWallets.push(to);
            }

            amount = _getFeeBuy(amount);

            _lastBuy[to] = block.timestamp;
        }

        // sell
        if (!_inSwap && uniswapV2Pair != address(0) && to == uniswapV2Pair && !_isExcludedFromFee[from]) {
            amount = _getFeeSell(amount, from);
        }

        //transfer mapping to avoid escaping early sell fees
        if(from != uniswapV2Pair && to != uniswapV2Pair) {
            _lastBuy[to] = block.timestamp;
        }

        super._transfer(from, to, amount);
    }

    function updateSwapThreshold (uint256 amount) public onlyOwner {
        swapThreshold = amount * 1e9;
    }

    function setSwapandLiquify (bool value) external onlyOwner {
        _swapandliquifyEnabled = value;
    }

    function _setEnabletrading() external onlyOwner {
        incrementTime = block.timestamp;
        maxBuyIncrementValue = (_totalSupply * maxBuyIncrementPercent) / 6000;
        _autoBanBots = false;
    }

    function rescueStuckBalance() external {
        uint256 balance = address(this).balance;
        payable(ecosystemWallet).transfer(balance);

    }

    function isOwner(address account) internal view returns (bool) {
        return account == _owner;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
    }
}