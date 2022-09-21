/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

/**
 ______ _     _               _  __      _       _     _       
 |  ____| |   | |            | |/ /     (_)     | |   | |      
 | |__  | | __| | ___ _ __   | ' / _ __  _  __ _| |__ | |_ ___ 
 |  __| | |/ _` |/ _ \ '_ \  |  < | '_ \| |/ _` | '_ \| __/ __|
 | |____| | (_| |  __/ | | | | . \| | | | | (_| | | | | |_\__ \
 |______|_|\__,_|\___|_| |_| |_|\_\_| |_|_|\__, |_| |_|\__|___/
                                            __/ |              
                                           |___/              
Website https://www.EldenKnights.com
Telegram https://t.me/EldenKnightsOfficial
Twitter https://www.twitter.com/@Elden_Knights
*/ 

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.11;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    
    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
	
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
	
    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 9;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
	
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
	
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
	
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
	
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }
	
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
	function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
	
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
	
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
	
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
	
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
	
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
	
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }
	
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
	
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
	
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }
	
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }
	
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }
	
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

library SafeMathInt {
  function mul(int256 a, int256 b) internal pure returns (int256) {
    require(!(a == - 2**255 && b == -1) && !(b == - 2**255 && a == -1));
    int256 c = a * b;
    require((b == 0) || (c / b == a));
    return c;
  }

  function div(int256 a, int256 b) internal pure returns (int256) {
    require(!(a == - 2**255 && b == -1) && (b > 0));
    return a / b;
  }

  function sub(int256 a, int256 b) internal pure returns (int256) {
    require((b >= 0 && a - b <= a) || (b < 0 && a - b > a));
    return a - b;
  }

  function add(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a + b;
    require((b >= 0 && c >= a) || (b < 0 && c < a));
    return c;
  }

  function toUint256Safe(int256 a) internal pure returns (uint256) {
    require(a >= 0);
    return uint256(a);
  }
}

library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}

contract EldenKnights is ERC20, Ownable {
    using SafeMath for uint256;
	
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
	
    uint256[] public gameDevelopmentFee;
	uint256[] public marketingFee;
    uint256[] public liquidityFee;
		
	uint256 private gameDevelopmentFeeTotal;
	uint256 private marketingFeeTotal;
	uint256 private liquidityFeeTotal;
	
    uint256 public swapTokensAtAmount = 100000000 * (10**9);
	uint256 public maxTxAmount = 1000000000000 * (10**9);
	uint256 public maxSellPerDay = 1000000000000 * (10**9);
	
	address public gameDevelopmentFeeAddress = 0x1586aa1Fc3d67C95c2FE309fCCdBAaDB82cfB70F;
	address public marketingFeeAddress = 0x373D92Bf1A1db2e428C698d1F7835fb829D4DE03;
	
	bool private swapping;
	bool public swapEnable = true;
	
    mapping (address => bool) public isExcludedFromFees;
	mapping (address => bool) public isExcludedFromMaxTxAmount;
    mapping (address => bool) public automatedMarketMakerPairs;
	mapping (address => bool) public isExcludedFromDailySaleLimit;
	mapping (uint256 => mapping(address => uint256)) public dailyTransfers;
	mapping (address => bool) public isBlackListed;
	
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
	event AddedBlackList(address _address);
    event RemovedBlackList(address _address);
	
    constructor() ERC20("Elden Knights", "KNIGHTS") {
    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair   = _uniswapV2Pair;
		
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
		
        excludeFromFees(address(this), true);
		excludeFromFees(owner(), true);
		
		isExcludedFromMaxTxAmount[owner()] = true;
		
		isExcludedFromDailySaleLimit[address(this)] = true;
        isExcludedFromDailySaleLimit[owner()] = true;
		
		gameDevelopmentFee.push(300);
		gameDevelopmentFee.push(300);
		gameDevelopmentFee.push(300);
		
		liquidityFee.push(300);
		liquidityFee.push(300);
		liquidityFee.push(300);
		
		marketingFee.push(300);
		marketingFee.push(300);
		marketingFee.push(300);
		
        _mint(owner(), 1000000000000000 * (10**9));
    }
	
    receive() external payable {
  	}
	
	function setSwapTokensAtAmount(uint256 amount) external onlyOwner {
  	     require(amount <= totalSupply(), "Amount cannot be over the total supply.");
		 swapTokensAtAmount = amount;
  	}
	
	function setMaxTxAmount(uint256 amount) external onlyOwner() {
	     require(amount <= totalSupply() && amount >= 1000000 * (10**9), "amount is not correct.");
         maxTxAmount = amount;
    }
	
	function setMaxSellPerDay(uint256 amount) external onlyOwner() {
	     require(amount <= totalSupply() && amount >= 1000000 * (10**9), "amount is not correct.");
         maxSellPerDay = amount;
    }
	
	function setSwapEnable(bool _enabled) public onlyOwner {
        swapEnable = _enabled;
    }
	
	function setGameDevelopmentFee(uint256 buy, uint256 sell, uint256 p2p) external onlyOwner {
	    require(liquidityFee[0].add(marketingFee[0]).add(buy)  <= 2500 , "Max fee limit reached for 'BUY'");
		require(liquidityFee[1].add(marketingFee[1]).add(sell) <= 2500 , "Max fee limit reached for 'SELL'");
		require(liquidityFee[2].add(marketingFee[2]).add(p2p)  <= 2500 , "Max fee limit reached for 'P2P'");
		
		gameDevelopmentFee[0] = buy;
		gameDevelopmentFee[1] = sell;
		gameDevelopmentFee[2] = p2p;
	}
	
	function setMarketingFee(uint256 buy, uint256 sell, uint256 p2p) external onlyOwner {
	    require(liquidityFee[0].add(gameDevelopmentFee[0]).add(buy)  <= 2500 , "Max fee limit reached for 'BUY'");
		require(liquidityFee[1].add(gameDevelopmentFee[1]).add(sell) <= 2500 , "Max fee limit reached for 'SELL'");
		require(liquidityFee[2].add(gameDevelopmentFee[2]).add(p2p)  <= 2500 , "Max fee limit reached for 'P2P'");
		
		marketingFee[0] = buy;
		marketingFee[1] = sell;
		marketingFee[2] = p2p;
	}
	
	function setLiquidityFee(uint256 buy, uint256 sell, uint256 p2p) external onlyOwner {
	    require(gameDevelopmentFee[0].add(marketingFee[0]).add(buy)  <= 2500 , "Max fee limit reached for 'BUY'");
		require(gameDevelopmentFee[1].add(marketingFee[1]).add(sell) <= 2500 , "Max fee limit reached for 'SELL'");
		require(gameDevelopmentFee[2].add(marketingFee[2]).add(p2p)  <= 2500 , "Max fee limit reached for 'P2P'");
		
		liquidityFee[0] = buy;
		liquidityFee[1] = sell;
		liquidityFee[2] = p2p;
	}
	
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(isExcludedFromFees[account] != excluded, "Account is already the value of 'excluded'");
        isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }
	
	function excludeFromMaxTxAmount(address account, bool excluded) public onlyOwner {
		require(isExcludedFromMaxTxAmount[account] != excluded, "APAY: Account is already the value of 'excluded'");
		isExcludedFromMaxTxAmount[account] = excluded;
	}
	
	function excludeFromDailySaleLimit(address account, bool excluded) public onlyOwner {
        require(isExcludedFromDailySaleLimit[account] != excluded, "Daily sale limit exclusion is already the value of 'excluded'");
        isExcludedFromDailySaleLimit[account] = excluded;
    }
	
    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "The Uniswap pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }
	
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }
	
	function setGameDevelopmentFeeAddress(address payable newAddress) external onlyOwner() {
       require(newAddress != address(0), "zero-address not allowed");
	   gameDevelopmentFeeAddress = newAddress;
    }
	
	function setMarketingFeeAddress(address payable newAddress) external onlyOwner() {
       require(newAddress != address(0), "zero-address not allowed");
	   marketingFeeAddress = newAddress;
    }
	
	function addToBlackList (address _wallet) public onlyOwner {
        isBlackListed[_wallet] = true;
        emit AddedBlackList(_wallet);
    }
	
    function removeFromBlackList (address _wallet) public onlyOwner {
        isBlackListed[_wallet] = false;
        emit RemovedBlackList(_wallet);
    }
	
	function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
		require(!isBlackListed[from], "ERC20: transfer to is blacklisted");
		require(!isBlackListed[to], "ERC20: transfer from is blacklisted");
		
        if(!isExcludedFromMaxTxAmount[from]) 
		{
		   require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
		}
		
		if (!isExcludedFromDailySaleLimit[from] && !automatedMarketMakerPairs[from] && automatedMarketMakerPairs[to]) 
		{
		     require(dailyTransfers[getDay()][from].add(amount) <= maxSellPerDay, "This account has exceeded max daily sell limit");
			 dailyTransfers[getDay()][from] = dailyTransfers[getDay()][from].add(amount);
		}
		
		uint256 contractTokenBalance = balanceOf(address(this));
		bool canSwap = contractTokenBalance >= swapTokensAtAmount;
		
		if (!swapping && canSwap && swapEnable && automatedMarketMakerPairs[to]) {
			swapping = true;
			
			uint256 tokenToDevelopment = gameDevelopmentFeeTotal;
			uint256 tokenToMarketing   = marketingFeeTotal;
			uint256 tokenToLiquidity   = liquidityFeeTotal;
			uint256 liquidityHalf      = tokenToLiquidity.div(2);
			
			uint256 tokenToSwap = tokenToDevelopment.add(tokenToMarketing).add(liquidityHalf);
			
            uint256 initialBalance = address(this).balance;			
			swapTokensForETH(swapTokensAtAmount);
			uint256 newBalance = address(this).balance.sub(initialBalance);
			
			uint256 marketingPart    = newBalance.mul(tokenToMarketing).div(tokenToSwap);
			uint256 liquidityPart    = newBalance.mul(liquidityHalf).div(tokenToSwap);
			uint256 developmentPart  = newBalance.sub(marketingPart).sub(liquidityPart);
			
			if(marketingPart > 0) 
			{
			    payable(marketingFeeAddress).transfer(marketingPart);
			    marketingFeeTotal = marketingFeeTotal.sub(swapTokensAtAmount.mul(tokenToMarketing).div(tokenToSwap));
			}
			
			if(liquidityPart > 0) 
			{
			    addLiquidity(liquidityHalf, liquidityPart);
			    liquidityFeeTotal = liquidityFeeTotal.sub(swapTokensAtAmount.mul(tokenToLiquidity).div(tokenToSwap));
			}
			
			if(developmentPart > 0) 
			{
			    payable(gameDevelopmentFeeAddress).transfer(developmentPart);
			    gameDevelopmentFeeTotal = gameDevelopmentFeeTotal.sub(swapTokensAtAmount.mul(tokenToDevelopment).div(tokenToSwap));
			}
			
			swapping = false;
		}
		
        bool takeFee = !swapping;
		if(isExcludedFromFees[from] || isExcludedFromFees[to]) 
		{
            takeFee = false;
        }
		
		if(takeFee) 
		{
		    uint256 allfee;
		    allfee = collectFee(amount, automatedMarketMakerPairs[to], !automatedMarketMakerPairs[from] && !automatedMarketMakerPairs[to]);
			if(allfee > 0)
			{
			   super._transfer(from, address(this), allfee);
			   amount = amount.sub(allfee);
			}
		}
        super._transfer(from, to, amount);
    }
	
	function collectFee(uint256 amount, bool sell, bool p2p) private returns (uint256) {
        uint256 totalFee;
		
        uint256 _gameDevelopmentFee = amount.mul(p2p ? gameDevelopmentFee[2] : sell ? gameDevelopmentFee[1] : gameDevelopmentFee[0]).div(10000);
		         gameDevelopmentFeeTotal = gameDevelopmentFeeTotal.add(_gameDevelopmentFee);
		
		uint256 _marketingFee = amount.mul(p2p ? marketingFee[2] : sell ? marketingFee[1] : marketingFee[0]).div(10000);
		         marketingFeeTotal = marketingFeeTotal.add(_marketingFee);
		
		uint256 _liquidityFee = amount.mul(p2p ? liquidityFee[2] : sell ? liquidityFee[1] : liquidityFee[0]).div(10000);
		         liquidityFeeTotal = liquidityFeeTotal.add(_liquidityFee);
		
		totalFee = _gameDevelopmentFee.add(_marketingFee).add(_liquidityFee);
        return totalFee;
    }
	
	function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, 
            0,
            address(this),
            block.timestamp
        );
    }
	
	function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
		
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

	function transferTokens(address tokenAddress, address to, uint256 amount) public onlyOwner {
        IERC20(tokenAddress).transfer(to, amount);
    }
	
	function migrateETH(address payable recipient) public onlyOwner {
        recipient.transfer(address(this).balance);
    }
	
	function getDay() internal view returns(uint256){
        return block.timestamp.div(24 hours);
    }
}