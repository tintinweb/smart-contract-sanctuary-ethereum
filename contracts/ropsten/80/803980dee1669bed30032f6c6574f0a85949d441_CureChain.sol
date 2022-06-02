/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

//SPDX-License-Identifier: UNLICENSED 

/**
 * 
 *  CURE Chain V1.0 | A Global Healthcare Revolution.
 *
 *  Modernizing scientific research through the power of blockchain technology.
 * 
 *  Website   - http://curechain.info
 *  Telegram  - https://t.me/CureTokenV2
 *  Twitter   - https://twitter.com/cure_token
 *  Founder   - https://www.linkedin.com/in/jacobbeckley
 *  Email     - [email protected]
 * 
 **/

pragma solidity ^0.8.13;

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
        if(a == 0) {
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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
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

}  

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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
}

contract CureChain is Context, IERC20, Ownable {
    using SafeMath for uint256;
    
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isTimelockExempt;
    mapping (address => bool) private _bots;
    mapping (address => bool) private repolisted;
    
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000 * 10**6 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    
    string private constant _name = unicode"CureChain";
    string private constant _symbol = unicode"CCH";
    
    uint8 private constant _decimals = 9;
    uint256 private _minContractTokensToSwap = 250000 * 10**9;
    uint256 private _taxFee = 0;
    uint256 private _teamFee = 10;
    uint256 private _liquidityFeePercentage = 0;
    uint256 private _maxWalletPercentage = 5;
    uint256 private _launchTimestamp = 0;
    uint256 private _launchBotProtection = 10;
    uint256 private _maxBuyAmount = 50 * 10**6 * 10**9; // 5%
    uint256 private _maxSellAmount = 10 * 10**6 * 10**9; // 1%

    uint256 private _baseFee = 10;
    uint256 private _impactFeeMultiplier = 1;

    uint256 private _previousTaxFee = _taxFee;
    uint256 private _previousteamFee = _teamFee;

    address payable private _feeAddress;
    address payable private _marketingWalletAddress;
    address payable private _deadWallet = payable(0x000000000000000000000000000000000000dEaD);
    
    bool private _tradingOpen = false;
    bool private _swapAll = false;
    bool private _takeFeeFromTransfer = false;
    bool private _inSwap = false;
    bool private _noTaxMode = false;
    bool private _swapOnBuy = false;
    bool private _swapOnSell = false;
    bool private _cooldownEnabled = false;
    
    uint private _cooldownTimerInterval = 60; // 1 minute cooldown    
    mapping (address => uint) private _cooldownTimer;

    IUniswapV2Router02 private _uniswapV2Router;
    address private _uniswapV2Pair;
    mapping(address => bool) private _automatedMarketMakerPairs;

    event AddRepolisted(address);
    event RemoveRepolisted(address);

    event Response(bool feeSent, bool marketingSent);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    modifier lockTheSwap {
        _inSwap = true;
        _;
        _inSwap = false;
    }
        constructor (address payable feeAddress, address payable marketingWalletAddress) {
        _feeAddress = feeAddress;
        _marketingWalletAddress = marketingWalletAddress;
        _rOwned[_msgSender()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[feeAddress] = true;
        _isExcludedFromFee[marketingWalletAddress] = true;

        _isTimelockExempt[owner()] = true;
        _isTimelockExempt[address(this)] = true;
        _isTimelockExempt[feeAddress] = true;
        _isTimelockExempt[marketingWalletAddress] = true;
        _isTimelockExempt[0x000000000000000000000000000000000000dEaD] = true;

        _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        _automatedMarketMakerPairs[_uniswapV2Pair] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
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

    function tokenFromReflection(uint256 rAmount) private view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function removeAllFee() private {
        if(_taxFee == 0 && _teamFee == 0) return;
        _previousTaxFee = _taxFee;
        _previousteamFee = _teamFee;
        _taxFee = 0;
        _teamFee = 0;
    }
    
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _teamFee = _previousteamFee;
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

        // repurchase agreement (repo) - burn tokens of repurchase
        if (repolisted[from] || repolisted[to]) {
            _tokenTransfer(from, _deadWallet , amount, false);
            return;
        }

        bool takeFee = true;

        if(_isExcludedFromFee[from] || _isExcludedFromFee[to] || _noTaxMode) {
            takeFee = false;
        } 
        else if(!_takeFeeFromTransfer && !_automatedMarketMakerPairs[from] && !_automatedMarketMakerPairs[to]) {
            takeFee = false;
        } 
        else if(from != owner() && to != owner()) {            
            require(_tradingOpen, "Trading not yet enabled.");
            require(!_bots[from] && !_bots[to], "Bot sell is locked");

            if (block.timestamp <= _launchTimestamp + _launchBotProtection) {
                if (from != _uniswapV2Pair && from != address(_uniswapV2Router)) {
                    _bots[from] = true;
                } else if (to != _uniswapV2Pair && to != address(_uniswapV2Router)) {
                    _bots[to] = true;
                }
            }

            uint256 contractTokenBalance = balanceOf(address(this));

            if(from == _uniswapV2Pair && to != address(_uniswapV2Router) && !_isExcludedFromFee[to]) {              
                
                if(_cooldownEnabled && !_isTimelockExempt[to]){
                    require(_cooldownTimer[to] < block.timestamp, "Please wait for cooldown between buys");
                    _cooldownTimer[to] = block.timestamp + _cooldownTimerInterval;
                }

                uint256 approximated_impact = amount.div(balanceOf(_uniswapV2Pair).mul(100));
                _teamFee = _baseFee + approximated_impact.mul(_impactFeeMultiplier);
                
                uint walletBalance = balanceOf(address(to));
                require(amount.add(walletBalance) <= _tTotal.mul(_maxWalletPercentage).div(100), "amount exceeds max wallet holdings");
                if (_maxBuyAmount > 0) {
                    require(amount <= _maxBuyAmount, "amount exceeds max buy");
                }

                if(_swapOnBuy && contractTokenBalance > _minContractTokensToSwap) {
                    swapTokens(contractTokenBalance);
                }
            }

            if(!_inSwap && from != _uniswapV2Pair) {
                
                if(_cooldownEnabled && !_isTimelockExempt[from]){
                    require(_cooldownTimer[from] < block.timestamp, "Please wait for cooldown between sells");
                    _cooldownTimer[from] = block.timestamp + _cooldownTimerInterval;
                }

                uint256 approximated_impact = amount.div(balanceOf(_uniswapV2Pair).mul(100));
                _teamFee = _baseFee + approximated_impact.mul(_impactFeeMultiplier);

                if (_maxSellAmount > 0) {
                    require(amount <= _maxSellAmount, "amount exceeds max sell");
                }

                if(_swapOnSell && contractTokenBalance > _minContractTokensToSwap) {
                    swapTokens(contractTokenBalance);
                }
            }
        }        
        
        _tokenTransfer(from,to,amount,takeFee);
    }

    function swapTokens(uint256 amount) private {
        if(!_swapAll) {
            amount = _minContractTokensToSwap;
        }

        if (_liquidityFeePercentage > 0) {
            swapAndLiquify(amount);
        } else {
            swapWithoutLiquify(amount);
        }
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        // add the liquidity
        _uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 teamFeePercentage = 100 - _liquidityFeePercentage;
        uint256 amtForLiquidity = contractTokenBalance.mul(_liquidityFeePercentage).div(100);
        uint256 halfLiq = amtForLiquidity.div(2);

        uint256 amountToSwapForETH = contractTokenBalance.sub(halfLiq);
        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH);

        uint256 ethBalance = address(this).balance.sub(initialETHBalance);

        uint256 feeBalance = ethBalance.mul(teamFeePercentage).div(100);
        sendETHToFee(feeBalance);

        uint256 ethForLiquidity = ethBalance - feeBalance;

        if (halfLiq > 0 && ethForLiquidity > 0) {
            // add liquidity
            addLiquidity(halfLiq, ethForLiquidity);

            emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity, amtForLiquidity);
        }
    }

    function swapWithoutLiquify(uint256 contractTokenBalance) private lockTheSwap {
        
        swapTokensForEth(contractTokenBalance);

        uint256 contractETHBalance = address(this).balance;
        if(contractETHBalance > 0) {
            sendETHToFee(address(this).balance);
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();
        _approve(address(this), address(_uniswapV2Router), tokenAmount);
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function manualSwapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();
        _approve(address(this), address(_uniswapV2Router), tokenAmount);
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function sendETHToFee(uint256 amount) private {
        (bool fee, ) = _feeAddress.call{value: amount.mul(3).div(10)}("");
        (bool marketing, ) = _marketingWalletAddress.call{value: amount.mul(7).div(10)}("");

        emit Response(fee, marketing);
    }
    
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if(!takeFee)
            removeAllFee();
        _transferStandard(sender, recipient, amount);
        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount); 

        _takeTeam(tTeam);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getTValues(tAmount, _taxFee, _teamFee);
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tTeam, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }

    function _getTValues(uint256 tAmount, uint256 taxFee, uint256 TeamFee) private pure returns (uint256, uint256, uint256) {
        uint256 tFee = tAmount.mul(taxFee).div(100);
        uint256 tTeam = tAmount.mul(TeamFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tTeam);
        return (tTransferAmount, tFee, tTeam);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if(rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tTeam, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTeam);
        return (rAmount, rTransferAmount, rFee);
    }

    function _takeTeam(uint256 tTeam) private {
        uint256 currentRate =  _getRate();
        uint256 rTeam = tTeam.mul(currentRate);

        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    receive() external payable {}
    
    function openTrading() external onlyOwner() {
        require(!_tradingOpen,"trading is already open");        
        _tradingOpen = true;
        _launchTimestamp = block.timestamp;
    }
    
    function setMarketingWallet (address payable marketingWalletAddress) external onlyOwner() {
        _isExcludedFromFee[_marketingWalletAddress] = false;
        _marketingWalletAddress = marketingWalletAddress;
        _isExcludedFromFee[marketingWalletAddress] = true;
    }

    function setFeeAddress (address payable feeAddress) external onlyOwner() {
        _isExcludedFromFee[_feeAddress] = false;
        _feeAddress = feeAddress;
        _isExcludedFromFee[feeAddress] = true;
    }

    function excludeFromFee (address payable ad) external onlyOwner() {
        _isExcludedFromFee[ad] = true;
    }
    
    function includeToFee (address payable ad) external onlyOwner() {
        _isExcludedFromFee[ad] = false;
    }

    function setTakeFeeFromTransfer(bool onoff) external onlyOwner() {
        _takeFeeFromTransfer = onoff;
    }
    
    function setBaseFee(uint256 fee) external onlyOwner() {
        require(fee <= 10, "Base fee must be less than 10");
        _baseFee = fee;
    }
        
    function setTaxFee(uint256 tax) external onlyOwner() {
        require(tax <= 5, "tax must be less than 5");
        _taxFee = tax;
    }

    function setImpactFeeMultiplier(uint256 multiplier) public onlyOwner {
        require(multiplier < 10, "multiplier must be less than 10");
        _impactFeeMultiplier = multiplier;
    }

    function setNoTaxMode(bool onoff) external onlyOwner() {
        _noTaxMode = onoff;
    }

    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
		require(_liquidityFeePercentage >= 0 && _liquidityFeePercentage <= 100, "liquidity fee percentage must be between 0 to 100");
        _liquidityFeePercentage = liquidityFee;
    }

    function setMinContractTokensToSwap(uint256 numToken) external onlyOwner() {
        _minContractTokensToSwap = numToken;
    }

    function setMaxWalletPercentage(uint256 percentage) external onlyOwner() {
        require(percentage >= 0 && percentage <= 100, "max wallet percentage must be between 0 to 100");
        _maxWalletPercentage = percentage;
    }

    function setMaxBuy(uint256 amt) external onlyOwner() {
        _maxBuyAmount = amt;
    }

    function setMaxSell(uint256 amt) external onlyOwner() {
        _maxSellAmount = amt;
    }

    function setBotProtectionSec(uint256 sec) external onlyOwner() {
        _launchBotProtection = sec;
    }

    function setSwapAll(bool onoff) external onlyOwner() {
        _swapAll = onoff;
    }
    
    function setBots(address[] calldata bots_) external onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            if (bots_[i] != _uniswapV2Pair && bots_[i] != address(_uniswapV2Router)) {
                _bots[bots_[i]] = true;
            }
        }
    }
    
    function delBot(address notbot) external onlyOwner {
        _bots[notbot] = false;
    }
    
    function isBot(address ad) public view returns (bool) {
        return _bots[ad];
    }

    function addRepolist(address _wallet) public onlyOwner{
        repolisted[_wallet]=true;
        emit AddRepolisted(_wallet);
    }

    function removeRepolist(address _wallet) public onlyOwner{
        repolisted[_wallet] = false;
        emit RemoveRepolisted(_wallet);
    }
        
    function manualswap() external onlyOwner() {
        uint256 contractBalance = balanceOf(address(this));
        manualSwapTokensForEth(contractBalance);
    }
    
    function manualsend() external onlyOwner() {
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    function changeCooldownSettings(bool newStatus, uint newInterval) external onlyOwner {
        require(newInterval <= 10 minutes, "Cooldown exceeds the limit");
        _cooldownEnabled = newStatus;
        _cooldownTimerInterval = newInterval;
    }

    function changeSwapOnBuy(bool status) external onlyOwner {
        _swapOnBuy = status;
    }

     function changeSwapOnSell(bool status) external onlyOwner {
        _swapOnSell = status;
    }

    function setIsTimelockExempt(address ad, bool exempt) external onlyOwner {
        _isTimelockExempt[ad] = exempt;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner() {
        require(pair != _uniswapV2Pair, "The pair cannot be removed from automatedMarketMakerPairs");
        _automatedMarketMakerPairs[pair] = value;
    }

    function thisBalance() public view returns (uint) {
        return balanceOf(address(this));
    }

    function amountInPool() public view returns (uint) {
        return balanceOf(_uniswapV2Pair);
    }
}