pragma solidity 0.8.2;

// SPDX-License-Identifier: Unlicensed

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IUniswapV2Factory {
   function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router {
   function factory() external pure returns (address);
   function WETH() external pure returns (address);
   function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
   function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
   function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

interface IStaking {
   function updatePool(uint256 amount) external;
}

interface ILiquidityProvider {
   function provideLiquidity(uint256 USDCAmount, uint256 TGCAmount) external;
   function transferReward(address sender) external;
   function transferUSDT(address marketing, uint256 amount) external;
}

contract LiquidityProvider is ILiquidityProvider {
	using SafeMath for uint256;
	
	address public immutable TGCToken;
	address public constant USDC = address(0x07865c6E87B9F70255377e024ace6630C1Eaa37F);
	IUniswapV2Router public uniswapV2Router;
	
    modifier onlyToken() {
       require(msg.sender == TGCToken, "!TGCToken"); _;
    }
	
    constructor () {
       TGCToken = msg.sender;
	   uniswapV2Router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    }
	
	function provideLiquidity(uint256 USDCAmount, uint256 TGCAmount) external override onlyToken {
		IERC20(USDC).approve(address(uniswapV2Router), USDCAmount);
		IERC20(TGCToken).approve(address(uniswapV2Router), TGCAmount);
		
		uniswapV2Router.addLiquidity(
			address(USDC),
			address(TGCToken),
			USDCAmount,
			TGCAmount,
			0,
			0,
			address(this),
			block.timestamp
	   );	
	}
	
	function transferReward(address sender) external override onlyToken {
	   IERC20(USDC).transfer(address(sender), IERC20(USDC).balanceOf(address(this)));
	}
	
	function transferUSDT(address marketing, uint256 amount) external override onlyToken {
	   IERC20(USDC).transfer(address(marketing), amount);
	}
}

contract TGC is Ownable, ERC20 {
	using SafeMath for uint256;
	
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
	mapping (address => uint256) public lockedAmount;
    mapping (address => bool) public _isExcludedFromFee;
	mapping (address => bool) public _isExcludedFromMaxBuyPerWallet;
    mapping (address => bool) public _isExcludedFromReward;
	mapping (address => bool) public _automatedMarketMakerPairs;
	
    address[] private _excluded;
	
	address public constant burnWallet = address(0x000000000000000000000000000000000000dEaD);
	address public constant USDC = address(0x07865c6E87B9F70255377e024ace6630C1Eaa37F);
	IStaking public stakingContract;
	address public marketingWallet = address(0x38de9e7f51A14DACc46F1E68C620C6f00E4966F4);
	address public LPProviderAddress;
	
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000000000 * (10**18);
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
	
	uint256 public liquidityFeeTotal;
    uint256 public marketingFeeTotal;

	uint256[] public liquidityFee;
	uint256[] public marketingFee;
	uint256[] public reflectionFee;
	uint256[] public stakingFee;
	uint256[] public burnFee;
	
	uint256 private _liquidityFee;
	uint256 private _marketingFee;
	uint256 private _reflectionFee;
	uint256 private _stakingFee;
	uint256 private _burnFee;
	
    IUniswapV2Router public uniswapV2Router;
    address public uniswapV2Pair;
	LiquidityProvider public LPProvider;
	
	bool private swapping;
    bool public swapAndLiquifyEnabled = true;
	
    uint256 public swapTokensAtAmount = 500 * (10**18);
	uint256 public maxBuyPerWallet = 20000000 * (10**18);
	
	event LockToken(uint256 amount, address user);
	event UnLockToken(uint256 amount, address user);
	event MigrateTokens(address token, address receiver, uint256 amount);
	event TransferTokens(address receiver, uint256 amount);
	event TransferETH(address recipient, uint256 amount);
	event MaxBuyPerWalletUpdated(uint256 amount);
	event SwapTokensAmountUpdated(uint256 amount);
	event MarketingWalletUpdated(address marketingWallet);
	event SwapAndLiquifyStatusUpdated(bool status);
	event WalletExcludeFromBuyLimit(address account);
    event WalletIncludeInBuyLimit(address account);
	
    constructor () ERC20("The Grays Currency", "TGC") {
        _rOwned[_msgSender()] = _rTotal;
        
        uniswapV2Router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), address(USDC));
		
		LPProvider = new LiquidityProvider();
		LPProviderAddress = address(LPProvider);
		
		_setAutomatedMarketMakerPair(uniswapV2Pair, true);
		
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
		_isExcludedFromFee[address(LPProviderAddress)] = true;
		
		_isExcludedFromReward[burnWallet] = true;
		_isExcludedFromReward[address(uniswapV2Pair)] = true;
		_isExcludedFromReward[address(this)] = true;
		_isExcludedFromReward[address(LPProviderAddress)] = true;
		
		_isExcludedFromMaxBuyPerWallet[address(uniswapV2Pair)] = true;
		_isExcludedFromMaxBuyPerWallet[address(this)] = true;
		_isExcludedFromMaxBuyPerWallet[owner()] = true;
		_isExcludedFromMaxBuyPerWallet[address(LPProviderAddress)] = true;
		
		liquidityFee.push(50);
		liquidityFee.push(0);
		liquidityFee.push(0);
		liquidityFee.push(50);
		liquidityFee.push(0);
		
		marketingFee.push(250);
		marketingFee.push(150);
		marketingFee.push(100);
		marketingFee.push(200);
		marketingFee.push(0);
		
		reflectionFee.push(200);
		reflectionFee.push(100);
		reflectionFee.push(100);
		reflectionFee.push(500);
		reflectionFee.push(0);
		
		stakingFee.push(200);
		stakingFee.push(200);
		stakingFee.push(200);
		stakingFee.push(300);
		stakingFee.push(0);
		
		burnFee.push(300);
		burnFee.push(200);
		burnFee.push(100);
		burnFee.push(250);
		burnFee.push(0);
		
        emit Transfer(address(0), _msgSender(), _tTotal);
    }
	
	receive() external payable {}

    function totalSupply() public override pure returns (uint256) {
        return _tTotal;
    }
	
    function balanceOf(address account) public override view returns (uint256) {
        if (_isExcludedFromReward[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
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
		emit SwapAndLiquifyStatusUpdated(_enabled);
    }
	
	function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "The pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }

    function excludeFromFee(address account) public onlyOwner {
	   require(!_isExcludedFromFee[account], "Account is already the value of 'true'");
	   _isExcludedFromFee[account] = true;
	}

	function includeInFee(address account) public onlyOwner {
		require(_isExcludedFromFee[account], "Account is already the value of 'false'");
		_isExcludedFromFee[account] = false;
	}

    function excludeFromMaxBuyPerWallet(address account) public onlyOwner {
		require(!_isExcludedFromMaxBuyPerWallet[account], "Account is already the value of 'true'");
		_isExcludedFromMaxBuyPerWallet[account] = true;
		
		emit WalletExcludeFromBuyLimit(account);
	}

    function includeInBuyPerWallet(address account) public onlyOwner {
		require(_isExcludedFromMaxBuyPerWallet[account], "Account is already the value of 'false'");
		_isExcludedFromMaxBuyPerWallet[account] = false;
		
		emit WalletIncludeInBuyLimit(account);
	}	
	
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(_automatedMarketMakerPairs[pair] != value, "Automated market maker pair is already set to that value");
        _automatedMarketMakerPairs[pair] = value;
    }
	
	function setMarketingWallet(address _marketingWallet) external onlyOwner{
	   require(_marketingWallet != address(0), "Zero address");
	   marketingWallet = _marketingWallet;
	   
	   emit MarketingWalletUpdated(marketingWallet);
    }
	
	function setStakingContract(IStaking contractAddress) external onlyOwner{
	   require(address(contractAddress) != address(0), "Zero address");
	   require(address(stakingContract) == address(0), "Staking contract already set");
	   
	   _isExcludedFromReward[address(stakingContract)] = false;
	   _isExcludedFromFee[address(stakingContract)] = false;
	   
	   stakingContract = IStaking(contractAddress);
	   
	   _isExcludedFromReward[address(stakingContract)] = true;
	   _isExcludedFromFee[address(stakingContract)] = true;
    }
	
	function setSwapTokensAtAmount(uint256 amount) external onlyOwner {
  	     require(amount <= totalSupply(), "Amount cannot be over the total supply.");
		 swapTokensAtAmount = amount;
		 
		 emit SwapTokensAmountUpdated(amount);
  	}
	
	function setMaxBuyPerWallet(uint256 amount) public onlyOwner {
		require(amount <= totalSupply(), "Amount cannot be over the total supply.");
		maxBuyPerWallet = amount;
		
		emit MaxBuyPerWalletUpdated(amount);
	}
	
	function lockToken(uint256 amount, address user) public {
	   require(msg.sender == address(stakingContract), "sender not allowed");
	   
	   uint256 unlockBalance = balanceOf(user) - lockedAmount[user];
	   require(unlockBalance >= amount, "locking amount exceeds balance");
	   lockedAmount[user] += amount;
	   emit LockToken(amount, user);
    }
	
	function unlockToken(address user) public {
	   require(msg.sender == address(stakingContract), "sender not allowed");
	   
	   uint256 amount = lockedAmount[user];
	   lockedAmount[user] = 0;
	   emit UnLockToken(amount, user);
    }
	
	function airdropToken(uint256 amount) external {
       require(amount > 0, "Transfer amount must be greater than zero");
	   require(balanceOf(msg.sender) - lockedAmount[msg.sender] >= amount, "transfer amount exceeds balance");
	   
	   _tokenTransfer(msg.sender, address(this), amount, true, true);
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
        _rOwned[address(this)] = _rOwned[address(this)].add(rMarketing);
        if(_isExcludedFromReward[address(this)])
           _tOwned[address(this)] = _tOwned[address(this)].add(tMarketing);
    }
	
	function _takeStaking(uint256 tStaking) private {
        uint256 currentRate =  _getRate();
        uint256 rStaking = tStaking.mul(currentRate);
        _rOwned[address(stakingContract)] = _rOwned[address(stakingContract)].add(rStaking);
        if(_isExcludedFromReward[address(stakingContract)])
            _tOwned[address(stakingContract)] = _tOwned[address(stakingContract)].add(tStaking);
    }
	
	function _takeBurn(uint256 tBurn) private {
        uint256 currentRate =  _getRate();
        uint256 rBurn = tBurn.mul(currentRate);
        _rOwned[burnWallet] = _rOwned[burnWallet].add(rBurn);
        if(_isExcludedFromReward[burnWallet])
            _tOwned[burnWallet] = _tOwned[burnWallet].add(tBurn);
    }
	
    function calculateReflectionFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_reflectionFee).div(10000);
    }
	
    function calculateMarketingFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_marketingFee).div(10000);
    }
	
	function calculateStakingFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_stakingFee).div(10000);
    }
	
    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(10000);
    }
	
	function calculateBurnFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_burnFee).div(10000);
    }
	
    function removeAllFee() private {
       _reflectionFee = 0;
	   _stakingFee = 0;
       _marketingFee = 0;
       _liquidityFee = 0;
	   _burnFee = 0;
    }
	
    function applyBuyFeeTierOne() private {
	   _reflectionFee = reflectionFee[0];
	   _stakingFee = stakingFee[0];
       _marketingFee = marketingFee[0];
       _liquidityFee = liquidityFee[0];
	   _burnFee = burnFee[0];
    }
	
	function applyBuyFeeTierTwo() private {
	   _reflectionFee = reflectionFee[1];
	   _stakingFee = stakingFee[1];
       _marketingFee = marketingFee[1];
       _liquidityFee = liquidityFee[1];
	   _burnFee = burnFee[1];
    }
	
	function applyBuyFeeTierThree() private {
	   _reflectionFee = reflectionFee[2];
	   _stakingFee = stakingFee[2];
       _marketingFee = marketingFee[2];
       _liquidityFee = liquidityFee[2];
	   _burnFee = burnFee[2];
    }
	
	function applySellFee() private {
	   _reflectionFee = reflectionFee[3];
	   _stakingFee = stakingFee[3];
       _marketingFee = marketingFee[3];
       _liquidityFee = liquidityFee[3];
	   _burnFee = burnFee[3];
    }
	
	function applyP2PFee() private {
	   _reflectionFee = reflectionFee[4];
	   _stakingFee = stakingFee[4];
       _marketingFee = marketingFee[4];
       _liquidityFee = liquidityFee[4];
	   _burnFee = burnFee[4];
    }
	
	function applyAirdropFee() private {
	   _reflectionFee = 10000;
	   _stakingFee = 0;
       _marketingFee = 0;
       _liquidityFee = 0;
	   _burnFee = 0;
    }
	
    function _transfer(address from, address to, uint256 amount) internal override{
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
		require(balanceOf(from) - lockedAmount[from] >= amount, "transfer amount exceeds balance");
		
		if(!_isExcludedFromMaxBuyPerWallet[to] && _automatedMarketMakerPairs[from])
		{
           uint256 balanceRecepient = balanceOf(to);
           require(balanceRecepient + amount <= maxBuyPerWallet, "Exceeds maximum buy per wallet limit");
        }
		
        uint256 contractTokenBalance = balanceOf(address(this));
		bool canSwap = contractTokenBalance >= swapTokensAtAmount;
		
        if (canSwap && !swapping && _automatedMarketMakerPairs[to] && swapAndLiquifyEnabled) 
		{
		    uint256 tokenToLiqudity = liquidityFeeTotal.div(2);
			uint256 tokenToMarketing = marketingFeeTotal;
			uint256 tokenToSwap = tokenToLiqudity.add(tokenToMarketing);
			
			if(tokenToSwap >= swapTokensAtAmount) 
			{
			    swapping = true;
				
				address[] memory path = new address[](2);
				path[0] = address(this);
				path[1] = address(USDC);
				
				uint256 USDCInitial = IERC20(USDC).balanceOf(address(LPProviderAddress));
				_approve(address(this), address(uniswapV2Router), swapTokensAtAmount);
				uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
					swapTokensAtAmount,
					0,
					path,
					address(LPProviderAddress),
					block.timestamp.add(300)
				);
				
				uint256 USDCFinal = IERC20(USDC).balanceOf(address(LPProviderAddress)) - USDCInitial;
				uint256 liqudityPart = USDCFinal.mul(tokenToLiqudity).div(tokenToSwap);
				uint256 marketingPart = USDCFinal - liqudityPart;
				
				if(liqudityPart > 0)
				{
				    uint256 liqudityToken = swapTokensAtAmount.mul(tokenToLiqudity).div(tokenToSwap);
				    IERC20(address(this)).transfer(address(LPProviderAddress), liqudityToken);
					LPProvider.provideLiquidity(liqudityPart, liqudityToken);
					liquidityFeeTotal = liquidityFeeTotal.sub(liqudityToken).sub(liqudityToken);
				}
				if(marketingPart > 0) 
				{
				    LPProvider.transferUSDT(address(marketingWallet), marketingPart);
					marketingFeeTotal = marketingFeeTotal.sub(swapTokensAtAmount.mul(tokenToMarketing).div(tokenToSwap));
				}
				swapping = false;
			}
        }
		
        bool takeFee = true;
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to])
		{
            takeFee = false;
        }
		
        _tokenTransfer(from,to,amount,takeFee,false);
    }
	
    function getQuotes(uint256 amountIn) public view returns (uint256){
	   address[] memory path = new address[](2);
       path[0] = address(this);
	   path[1] = address(USDC);
	   
	   uint256[] memory USDCRequired = uniswapV2Router.getAmountsOut(amountIn, path);
	   return USDCRequired[1];
    }
	
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee, bool airdrop) private {
		if(!takeFee) 
		{
		    removeAllFee();
		}
		else if(airdrop)
		{
		    applyAirdropFee();
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
		    uint256 USDCRequired = getQuotes(amount);
			if(USDCRequired >= 20000 * 10**6)
			{
			    applyBuyFeeTierThree();
			}
			else if(USDCRequired >= 10000 * 10**6)
			{
			    applyBuyFeeTierTwo();
			}
			else
			{
			    applyBuyFeeTierOne();
			}
		}
		
		uint256 tBurn = calculateBurnFee(amount);
		if(tBurn > 0)
		{
		   _takeBurn(tBurn);
		   emit Transfer(sender, address(burnWallet), tBurn);
		}
		
		uint256 tStaking = calculateStakingFee(amount);
		if(tStaking > 0) 
		{
		    _takeStaking(tStaking);
		    stakingContract.updatePool(tStaking);
		    emit Transfer(sender, address(stakingContract), tStaking);
		}
		
        if (_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) 
		{
            _transferFromExcluded(sender, recipient, amount.sub(tBurn).sub(tStaking));
        } 
		else if (!_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) 
		{
            _transferToExcluded(sender, recipient, amount.sub(tBurn).sub(tStaking));
        } 
		else if (!_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) 
		{
            _transferStandard(sender, recipient, amount.sub(tBurn).sub(tStaking));
        } 
		else if (_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) 
		{
            _transferBothExcluded(sender, recipient, amount.sub(tBurn).sub(tStaking));
        } 
		else 
		{
            _transferStandard(sender, recipient, amount.sub(tBurn).sub(tStaking));
        }
    }
	
    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _takeMarketing(tMarketing);
        _reflectFee(rFee, tFee);
		
		liquidityFeeTotal += tLiquidity;
        marketingFeeTotal += tMarketing;
		
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
		
		liquidityFeeTotal += tLiquidity;
        marketingFeeTotal += tMarketing;
		
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
		
		liquidityFeeTotal += tLiquidity;
        marketingFeeTotal += tMarketing;
		
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
		
		liquidityFeeTotal += tLiquidity;
        marketingFeeTotal += tMarketing;
		
        emit Transfer(sender, recipient, tTransferAmount);
    }
	
	function migrateTokens(address token, address receiver, uint256 amount) external onlyOwner{
       require(token != address(0), "Zero address");
	   require(receiver != address(0), "Zero address");
	   if(address(token) == address(this))
	   {
	       require(IERC20(address(this)).balanceOf(address(this)).sub(liquidityFeeTotal).sub(marketingFeeTotal) >= amount, "Insufficient balance on contract");
	   }
	   else
	   {
	       require(IERC20(token).balanceOf(address(this)) >= amount, "Insufficient balance on contract");
	   }
	   IERC20(token).transfer(address(receiver), amount);
       emit MigrateTokens(token, receiver, amount);
    }
	
	function migrateETH(address payable recipient) public onlyOwner {
	   require(recipient != address(0), "Zero address");
	   
	   emit TransferETH(recipient, address(this).balance);
       recipient.transfer(address(this).balance);
    }
	
	function transferLPReward() public onlyOwner {
       LPProvider.transferReward(msg.sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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