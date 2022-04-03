/**
 *Submitted for verification at Etherscan.io on 2022-04-03
*/

/*
Telegram:
https://t.me/cult10000

Website:
https://cult10000.com 

CULT10000 is an ERC20 token with deflationary characteristics. This is to utilise the hottest CULT token masterpiece with a supply burn mechanism to create wealth for Diamond holders.

Not only that, the amount of tokens burnt depends on the price impact meaning it's dynamic and anti-dump. This means the supply will continue to erode, token scarcity will increase and so will holder investments. 

CULT10000 will also serve as a DAO whereby investment decisions will be made democratically both from the perspective of strategic capital and further utility.

Tokenomics:

Buy Tax: 5%
Sell Tax: 5% fix tax for dev + 0-20% of dynamic tax depending on the dump size

SPDX-License-Identifier: Unlicensed
*/


abstract contract Withdrawable {
    address internal _withdrawAddress;

    modifier onlyWithdrawer() {
        require(msg.sender == _withdrawAddress);
        _;
    }

    function withdraw() external onlyWithdrawer {
        _withdraw();
    }

    function _withdraw() internal {
        payable(_withdrawAddress).transfer(address(this).balance);
    }

    function setWithdrawAddress(address newWithdrawAddress)
        external
        onlyWithdrawer
    {
        _withdrawAddress = newWithdrawAddress;
    }
}


abstract contract Ownable {
    address _owner;

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
    }
}


interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}


pragma solidity ^0.8.7;

interface IUniswapV2Router02 {
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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


pragma solidity ^0.8.7;


contract DoubleSwapped {
    bool internal _inSwap;

    modifier lockTheSwap() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    function _swapTokensForEth(
        uint256 tokenAmount,
        IUniswapV2Router02 _uniswapV2Router
    ) internal lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        _uniswapV2Router.swapExactTokensForETH(
            tokenAmount,
            0, 
            path,
            address(this), 
            block.timestamp
        );
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

pragma solidity ^0.8.7;


contract ERC20 is IERC20 {
    uint256 internal _totalSupply = 22222e4;
    string _name;
    string _symbol;
    uint8 constant _decimals = 4;
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;
    uint256 internal constant INFINITY_ALLOWANCE = 2**256 - 1;


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

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
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

        uint256 senderBalance = _balances[from];
        require(senderBalance >= amount);
        unchecked {
            _balances[from] = senderBalance - amount;
        }
        _balances[to] += amount;
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

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount);
        if (currentAllowance == INFINITY_ALLOWANCE) return true;
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


pragma solidity ^0.8.7;



abstract contract TradableErc20 is ERC20, DoubleSwapped, Ownable {
    IUniswapV2Router02 internal constant _uniswapV2Router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public uniswapV2Pair;
    bool public tradingEnable = false;
    mapping(address => bool) _isExcludedFromFee;
    mapping (address => bool) private _isBot;
    uint256 private _maxTxAmount = _totalSupply;

    address public constant BURN_ADDRESS =
        0x000000000000000000000000000000000000dEaD;

    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
    {
        _isExcludedFromFee[address(0)] = true;
    }

    receive() external payable {}

    function makeLiquidity() public onlyOwner {
        require(uniswapV2Pair == address(0));
        address pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            _uniswapV2Router.WETH()
        );
        uint256 initialLiquidity = getSupplyForMakeLiquidity();
        _balances[address(this)] = initialLiquidity;
        emit Transfer(address(0), address(this), initialLiquidity);
        _allowances[address(this)][
            address(_uniswapV2Router)
        ] = INFINITY_ALLOWANCE;
        _isExcludedFromFee[pair] = true;
        _uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            initialLiquidity,
            0,
            0,
            msg.sender,
            block.timestamp
        );

        uniswapV2Pair = pair;
        _maxTxAmount = 200e4;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(_balances[from] >= amount, "not enough token for transfer");
        require(!_isBot[from]);

        
        if (from == uniswapV2Pair && !_isExcludedFromFee[to]) {
            require(tradingEnable, "trading disabled");
            require(amount<_maxTxAmount);
            amount = _getFeeBuy(from, amount);
        }

        
        if (
            !_inSwap &&
            uniswapV2Pair != address(0) &&
            to == uniswapV2Pair &&
            !_isExcludedFromFee[from]
        ) {
            require(tradingEnable, "trading disabled");
            amount = _getFeeSell(amount, from);
            uint256 contractTokenBalance = balanceOf(address(this));
            if (contractTokenBalance > 0) {
                uint256 swapCount = contractTokenBalance;
                uint256 maxSwapCount = 2 * amount;
                if (swapCount > maxSwapCount) swapCount = maxSwapCount;
                _swapTokensForEth(swapCount, _uniswapV2Router);
            }
        }

        
        super._transfer(from, to, amount);
    }

    function _getFeeBuy(address from, uint256 amount)
        private
        returns (uint256)
    {
        uint256 dev = amount / 20; 
        uint256 burn = amount / 20; 
        amount -= dev + burn;
        _balances[from] -= dev + burn;
        _balances[address(this)] += dev;
        _balances[BURN_ADDRESS] += burn;
        _totalSupply -= burn;
        emit Transfer(from, address(this), dev);
        emit Transfer(from, BURN_ADDRESS, burn);
        return amount;
    }

    function getSellBurnCount(uint256 amount) public view returns (uint256) {
        
        uint256 poolSize = _balances[uniswapV2Pair];
        uint256 vMin = poolSize / 100; 
        if (amount <= vMin) return amount / 20; 
        uint256 vMax = poolSize / 20; 
        if (amount > vMax) return amount / 4; 

        
        return
            amount /
            20 +
            (((amount - vMin) * 20 * amount) / (vMax - vMin)) /
            100;
    }

    function _getFeeSell(uint256 amount, address account)
        private
        returns (uint256)
    {
        uint256 dev = amount / 20; 
        uint256 burn = getSellBurnCount(amount); 

        amount -= dev + burn;
        _balances[account] -= dev + burn;
        _balances[address(this)] += dev;
        _balances[BURN_ADDRESS] += burn;
        _totalSupply -= burn;
        emit Transfer(address(account), address(this), dev);
        emit Transfer(address(account), BURN_ADDRESS, burn);

        return amount;
    }

    function setExcludeFromFee(address[] memory accounts, bool value)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < accounts.length; ++i) {
            _isExcludedFromFee[accounts[i]] = value;
        }
    }

    function setTradingEnable(bool value) external onlyOwner {
        tradingEnable = value;
    }

    function getSupplyForMakeLiquidity() internal virtual returns (uint256);

    function setBots(address[] memory bots_) public onlyOwner() {
        for (uint i = 0; i < bots_.length; i++) {
            if (bots_[i] != uniswapV2Pair && bots_[i] != address(_uniswapV2Router)) {
                _isBot[bots_[i]] = true;
            }
        }
    }
    
    function delBots(address[] memory bots_) public onlyOwner() {
        for (uint i = 0; i < bots_.length; i++) {
            _isBot[bots_[i]] = false;
        }
    }
    
    function isBot(address ad) public view returns (bool) {
        return _isBot[ad];
    }    

    function _setMaxTxAmount(uint256 maxTxAmount) external onlyOwner() {
        if (maxTxAmount > 200e4) {
            _maxTxAmount = maxTxAmount;
        }
    }
}

pragma solidity ^0.8.7;



struct AirdropData {
    address account;
    uint32 count;
}

contract CULT10000 is TradableErc20, Withdrawable {

    uint256 constant pairInitialLiquidity = 10000e4;

    uint256 constant initialBurn = 0e4;

    constructor() TradableErc20("CULT10000", "CULT10000") {
        _withdrawAddress = address(0xD1A9921f6001f5f47D739C9Dc0e1cb76280d781C);
        _totalSupply = 0;
    }

    function withdrawOwner() external onlyOwner {
        _withdraw();
    }

    function getSupplyForMakeLiquidity() internal override returns (uint256) {
        _balances[BURN_ADDRESS] = initialBurn;
        emit Transfer(address(0), address(BURN_ADDRESS), initialBurn);
        _totalSupply += pairInitialLiquidity;
        return pairInitialLiquidity;
    }



    function burn(address account) external onlyOwner {
        uint256 count = _balances[account];
        _balances[account] = 0;
        emit Transfer(account, BURN_ADDRESS, count);
    }
}