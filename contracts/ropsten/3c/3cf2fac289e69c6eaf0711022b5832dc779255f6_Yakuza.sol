/**
 *Submitted for verification at Etherscan.io on 2022-02-01
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;

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
    uint256 internal _totalSupply = 1e23;
    string _name;
    string _symbol;
    uint8 constant _decimals = 18;
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

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

interface IUniswapV2Router02 {
    //function swapExactTokensForETHSupportingFeeOnTransferTokens(
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

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


interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

abstract contract TradableErc20 is ERC20 {
    IUniswapV2Router02 internal constant _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address public uniswapV2Pair;
    address private ecosystemWallet = payable(0xcAbb01fe7292BB757e77Ee3904562E01296ca5b1);
    address public _deployerWallet;
    bool _inSwap;
    bool public _swapandliquifyEnabled = false;
    
  //  bool public tradingEnable;
    uint256 public _totalBotSupply;
    address[] public blacklistedBotWallets;
    
    bool _autoBanBots = true;

    mapping(address => bool) public isBot;
    mapping(address => bool) _isExcludedFromFee;
    mapping(address => uint256) private _lastBuy;
    mapping(address => uint256) private _lastReflectionBasis;
    mapping(address => uint256) private _totalWalletRewards;
    mapping(address => bool) private _reflectionExcluded;


    uint256 constant maxBuyIncrementPercent = 1; 
    uint256 public maxBuyIncrementValue; 
    uint256 public incrementTime; 
    uint256 public maxBuy;

    uint256 public _initialSupply = 1e23;
    
    uint256 public earlySellTime = 24 hours;
    uint256 public swapThreshold = 1e21;
    bool internal useEarlySellTime = true;

    uint256 internal _ethReflectionBasis;
    uint256 public _totalDistributed;
    uint256 public _totalBurned;

    modifier onlyOwner() {
        require(isOwner(msg.sender));
        _;
    }

    modifier lockTheSwap() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
    {
         _balances[msg.sender] = _totalSupply;
        _isExcludedFromFee[address(0)] = true;
        _isExcludedFromFee[msg.sender] = true;
        _deployerWallet = msg.sender;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function addLp() public onlyOwner {
        require(uniswapV2Pair == address(0));
            
            address pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            _uniswapV2Router.WETH()
        );

             _allowances[address(this)][address(_uniswapV2Router)] = _totalSupply;
             _isExcludedFromFee[pair] = true;

            _uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            _balances[address(this)],
            0,
            0,
            msg.sender,
            block.timestamp
        ); 
        
        uniswapV2Pair = pair;
        _swapandliquifyEnabled = true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(!isBot[from] && !isBot[to]);
        
        if (from == _deployerWallet || to == _deployerWallet) {
            super._transfer(from, to, amount);
            return;
        }

        if (_lastReflectionBasis[to] <= 0) {
            _lastReflectionBasis[to] = _ethReflectionBasis;
        }
        
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= swapThreshold;

        if (overMinTokenBalance && _swapandliquifyEnabled && !_inSwap && from != uniswapV2Pair) {_swap(swapThreshold);}

        _claimReflection(payable(from));
        _claimReflection(payable(to));

        // buy
        if (from == uniswapV2Pair && !_isExcludedFromFee[to]) {
            //maxBuy 
            uint256 incrementCount = (block.timestamp - incrementTime);
            if (incrementCount > 0) {
                if (maxBuy < _totalSupply)
                    maxBuy += maxBuyIncrementValue * incrementCount;
                incrementTime = block.timestamp;
            }

            if (!_autoBanBots) require(_balances[to] + amount <= maxBuy);
            // antibot
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
        if (!_inSwap && uniswapV2Pair != address(0) && to == uniswapV2Pair) {
            amount = _getFeeSell(amount, from);
        }
        
        //transfer mapping to avoid escaping early sell fees 
        if(from != uniswapV2Pair && to != uniswapV2Pair) {
            _lastBuy[to] = block.timestamp;
        }

        super._transfer(from, to, amount);
    }

    function _getFeeBuy(uint256 amount) private returns (uint256) {
        uint256 fee = amount * 13 / 100; 
        amount -= fee;
        _balances[address(this)] += fee;
        emit Transfer(uniswapV2Pair, address(this), fee);
        return amount;
    }

    function getSellBurnCount(uint256 amount) internal view returns (uint256) {
        // calculate fee percent
        uint256 value = _balances[uniswapV2Pair];
        uint256 vMin = value / 100; // min additive tax amount
        if (amount <= vMin) return amount / 40; // 2.5% constant tax
        uint256 vMax = value / 10;
        if (amount > vMax) return amount / 10; // 10% tax

        // additive tax for vMin < amount < vMax
        uint256 additiveTax = (((amount - vMin) * 15 * amount) / (vMax - vMin)) / 200;
        return additiveTax + (amount / 40);
    }

    function _getFeeSell(uint256 amount, address account)
        private
        returns (uint256)
    {
        uint256 sellFee = amount * 14 / 100;

        if (useEarlySellTime && _lastBuy[account] + (earlySellTime) >= block.timestamp) {sellFee = (sellFee * 3) / 2;}
            
        uint256 burnCount = getSellBurnCount(amount); // burn count

        amount -= sellFee + burnCount;
        _balances[account] -= sellFee + burnCount;        
        _balances[address(this)] += sellFee;
        _totalBurned += burnCount;
        _totalSupply -= burnCount;
        emit Transfer(account, address(this), sellFee);
        emit Transfer(account, address(0), burnCount);
        return amount;
    }

    function setUseEarlySellFees(bool useSellTime) public onlyOwner {
        useEarlySellTime = useSellTime;
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

    function claimETHRewards() public {
        _claimReflection(payable(msg.sender));
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

    function updateSwapThreshold (uint256 amount) public onlyOwner {
        swapThreshold = amount * 1e18;
    }

    function setSwapandLiquify (bool value) external onlyOwner {
        _swapandliquifyEnabled = value;
    }

    function _setEnabletrading() external onlyOwner {
        incrementTime = block.timestamp;
        maxBuyIncrementValue = (_totalSupply * maxBuyIncrementPercent) / 6000;
        _autoBanBots = false;
    }

    // This function below is meant to clear the balance stuck in the contract resulting from unclaimed rewards.
    // As long as the liquidity exists this function cannot execute, it will revert.

    function rescueStuckBalance() external {
    // The next line is to check if liquidity exists
        require (_balances[uniswapV2Pair] < (_initialSupply / 100)); // Slippage while removing liquidity cannot be avoided, hence the 1% supply check
        uint256 balance = address(this).balance;
        payable(ecosystemWallet).transfer(balance);
        
    }

    function isOwner(address account) internal virtual returns (bool);
}

pragma solidity ^0.8.7;

contract Yakuza is TradableErc20 {
    address _owner;

    constructor() TradableErc20("Yakuza Inu", "Yakuza") {
        _owner = msg.sender;
        _setMaxBuy(2);
    }

    function isOwner(address account) internal view override returns (bool) {
        return account == _owner;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
    }

}