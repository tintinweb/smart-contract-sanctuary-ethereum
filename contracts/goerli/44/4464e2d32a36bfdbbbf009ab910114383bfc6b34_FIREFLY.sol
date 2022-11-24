/**
 *Submitted for verification at Etherscan.io on 2022-11-24
*/

pragma solidity 0.8.15;

// SPDX-License-Identifier: Unlicensed

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

     function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
}

contract Ownable is Context {
    address private _owner;
  
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
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
	function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
}

contract FIREFLY is Context, IERC20, Ownable {
	using SafeMath for uint256;
	
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) public _isExcludedFromFee;
    mapping (address => bool) public _isExcludedFromReward;
	mapping (address => bool) public _automatedMarketMakerPairs;
	
    address[] private _excluded;
	
    address public marketingWallet = 0x38de9e7f51A14DACc46F1E68C620C6f00E4966F4;
	address public constant burnWallet = 0x000000000000000000000000000000000000dEaD;
	address public constant USDT = 0xC2C527C0CACF457746Bd31B2a698Fe89de2b6d49;
	
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 100000000000 * (10**6);
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "Firefly";
    string private _symbol = "FIREFLY V4";
    uint8  private _decimals = 6;
	
	uint256[] public liquidityFee;
	uint256[] public marketingFee;
	uint256[] public reflectionFee;
	uint256[] public burnFee;
	
	uint256 private _liquidityFee;
	uint256 private _marketingFee;
	uint256 private _reflectionFee;
	uint256 private _burnFee;
	
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
	
	bool private swapping;
    bool public swapAndLiquifyEnabled = true;
	
    uint256 public swapTokensAtAmount = 100000000 * (10**6);
    
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
	event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
	
    constructor () {
        _rOwned[_msgSender()] = _rTotal;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), address(USDT));

        uniswapV2Router = _uniswapV2Router;
		
		_setAutomatedMarketMakerPair(uniswapV2Pair, true);
		
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
		
		_isExcludedFromReward[burnWallet] = true;
		_isExcludedFromReward[uniswapV2Pair] = true;
		
		liquidityFee.push(300);
		liquidityFee.push(200);
		liquidityFee.push(100);
		liquidityFee.push(200);
		liquidityFee.push(0);
		
		marketingFee.push(300);
		marketingFee.push(200);
		marketingFee.push(200);
		marketingFee.push(100);
		marketingFee.push(0);
		
		reflectionFee.push(100);
		reflectionFee.push(100);
		reflectionFee.push(100);
		reflectionFee.push(100);
		reflectionFee.push(0);
		
		burnFee.push(300);
		burnFee.push(200);
		burnFee.push(100);
		burnFee.push(300);
		burnFee.push(0);
		
		IERC20(USDT).approve(address(uniswapV2Router), type(uint256).max);
        IERC20(USDT).approve(address(uniswapV2Pair), type(uint256).max);
        IERC20(USDT).approve(address(this), type(uint256).max);
		
	    _approve(address(this), address(uniswapV2Router), type(uint256).max);
		_approve(address(this), address(uniswapV2Pair), type(uint256).max);
		_approve(address(this), address(this), type(uint256).max);
		
        emit Transfer(address(0), _msgSender(), _tTotal);
    }
	
	receive() external payable {}
	
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcludedFromReward[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
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
	
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcludedFromReward[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcludedFromReward[account] = true;
        _excluded.push(account);
    }
	
    function includeInReward(address account) external onlyOwner() {
        require(_isExcludedFromReward[account], "Account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcludedFromReward[account] = false;
                _excluded.pop();
                break;
            }
        }
    }
	
	function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
	
	function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "The pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }

    function excludeFromFee(address account) public onlyOwner {
		_isExcludedFromFee[account] = true;
	}

	function includeInFee(address account) public onlyOwner {
		_isExcludedFromFee[account] = false;
	}	
	
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(_automatedMarketMakerPairs[pair] != value, "Automated market maker pair is already set to that value");
        _automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }
	
	function setmarketingWallet(address _marketingWallet) external onlyOwner{
	   require(_marketingWallet != address(0), "Zero address");
	   marketingWallet = _marketingWallet;
    }
	
	function setSwapTokensAtAmount(uint256 amount) external onlyOwner {
  	     require(amount <= totalSupply(), "Amount cannot be over the total supply.");
		 swapTokensAtAmount = amount;
  	}
	
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, tMarketing, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity, tMarketing);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tFee = calculateReflectionFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tMarketing = calculateMarketingFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity).sub(tMarketing);
        return (tTransferAmount, tFee, tLiquidity, tMarketing);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rMarketing = tMarketing.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity).sub(rMarketing);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcludedFromReward[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }
	
    function _takeMarketing(uint256 tMarketing) private {
        uint256 currentRate =  _getRate();
        uint256 rMarketing = tMarketing.mul(currentRate);
        _rOwned[marketingWallet] = _rOwned[marketingWallet].add(rMarketing);
        if(_isExcludedFromReward[marketingWallet])
            _tOwned[marketingWallet] = _tOwned[marketingWallet].add(tMarketing);
    }
	
	function _takeBurn(uint256 tBurn) private {
        uint256 currentRate =  _getRate();
        uint256 rBurn = tBurn.mul(currentRate);
        _rOwned[burnWallet] = _rOwned[burnWallet].add(rBurn);
        if(_isExcludedFromReward[burnWallet])
            _tOwned[burnWallet] = _tOwned[burnWallet].add(tBurn);
    }
	
    function calculateReflectionFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_reflectionFee).div(10**4);
    }
	
    function calculateMarketingFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_marketingFee).div(10**4);
    }
	
    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(10**4);
    }
	
	function calculateBurnFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_burnFee).div(10**4);
    }
	
    function removeAllFee() private {
       _reflectionFee = 0;
       _marketingFee = 0;
       _liquidityFee = 0;
	   _burnFee = 0;
    }
	
    function applyBuyFeeTierOne() private {
	   _reflectionFee = reflectionFee[0];
       _marketingFee = marketingFee[0];
       _liquidityFee = liquidityFee[0];
	   _burnFee = burnFee[0];
    }
	
	function applyBuyFeeTierTwo() private {
	   _reflectionFee = reflectionFee[1];
       _marketingFee = marketingFee[1];
       _liquidityFee = liquidityFee[1];
	   _burnFee = burnFee[1];
    }
	
	function applyBuyFeeTierThree() private {
	   _reflectionFee = reflectionFee[2];
       _marketingFee = marketingFee[2];
       _liquidityFee = liquidityFee[2];
	   _burnFee = burnFee[2];
    }
	
	function applySellFee() private {
	   _reflectionFee = reflectionFee[3];
       _marketingFee = marketingFee[3];
       _liquidityFee = liquidityFee[3];
	   _burnFee = burnFee[3];
    }
	
	function applyP2PFee() private {
	   _reflectionFee = reflectionFee[4];
       _marketingFee = marketingFee[4];
       _liquidityFee = liquidityFee[4];
	   _burnFee = burnFee[4];
    }
	
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
		
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
		
        uint256 contractTokenBalance = balanceOf(address(this));
		bool canSwap = contractTokenBalance >= swapTokensAtAmount;
		
        if (canSwap && !swapping && _automatedMarketMakerPairs[to] && swapAndLiquifyEnabled) 
		{
		    swapping = true;
			
			uint256 half = swapTokensAtAmount.div(2);
			uint256 otherHalf = swapTokensAtAmount - half;
			
			swapTokensForUSDT(half);
			uint256 newBalance = IERC20(USDT).balanceOf(address(this));
			
			if(newBalance > 0)
			{
			   addLiquidityUSDT(otherHalf, newBalance);
			}
			
			swapping = false;
        }
		
        bool takeFee = true;
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to])
		{
            takeFee = false;
        }
		
        _tokenTransfer(from,to,amount,takeFee);
    }
	
    function swapTokensForUSDT(uint256 tokenAmount) private {
		address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(USDT);
		
        uniswapV2Router.swapExactTokensForTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
	
    function addLiquidityUSDT(uint256 tokenAmount, uint256 USDTAmount) private {
        uniswapV2Router.addLiquidity(
            address(this),
			USDT,
            tokenAmount,
			USDTAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }
	
    function getQuotes(uint256 amountIn) public view returns (uint256){
	   address[] memory path = new address[](2);
       path[0] = address(this);
	   path[1] = address(USDT);
	   
	   uint256[] memory USDTRequired = uniswapV2Router.getAmountsOut(amountIn, path);
	   return USDTRequired[1];
    }
	
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
		if(!takeFee) 
		{
		    removeAllFee();
		}
		else if(!_automatedMarketMakerPairs[sender] && !_automatedMarketMakerPairs[recipient])
		{
			applyP2PFee();
		}
		else if(_automatedMarketMakerPairs[recipient])
		{
		    applySellFee();
		}
		else
		{
		    uint256 USDTRequired = getQuotes(amount);
			
			if(USDTRequired >= 20000 * 10**6)
			{
			    applyBuyFeeTierThree();
			}
			else if(USDTRequired >= 10000 * 10**6)
			{
			    applyBuyFeeTierTwo();
			}
			else
			{
			    applyBuyFeeTierOne();
			}
		}
		
		uint256 tBurn = calculateBurnFee(amount);
		                _takeBurn(tBurn);
						
        if (_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) 
		{
            _transferFromExcluded(sender, recipient, amount.sub(tBurn));
        } 
		else if (!_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) 
		{
            _transferToExcluded(sender, recipient, amount.sub(tBurn));
        } 
		else if (!_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) 
		{
            _transferStandard(sender, recipient, amount.sub(tBurn));
        } 
		else if (_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) 
		{
            _transferBothExcluded(sender, recipient, amount.sub(tBurn));
        } 
		else 
		{
            _transferStandard(sender, recipient, amount.sub(tBurn));
        }
    }
	
    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _takeMarketing(tMarketing);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeLiquidity(tLiquidity);
        _takeMarketing(tMarketing);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeLiquidity(tLiquidity);
        _takeMarketing(tMarketing);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
	
	function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeLiquidity(tLiquidity);
        _takeMarketing(tMarketing);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
}