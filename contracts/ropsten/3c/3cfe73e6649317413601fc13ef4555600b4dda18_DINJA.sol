/**
 *Submitted for verification at Etherscan.io on 2022-01-31
*/

/**
 * 
 * $DINJA - DOGE NINJA SAMURAI
 *
 * 
 * 
 * 💻 Website: https://dinjatoken.com/
 * 💬 Telegram: http://t.me/dinjatoken
 * 🐦 Twitter: https://twitter.com/DinjaToken
 *
 *
 * ██████╗░██╗███╗░░██╗░░░░░██╗░█████╗░
 * ██╔══██╗██║████╗░██║░░░░░██║██╔══██╗
 * ██║░░██║██║██╔██╗██║░░░░░██║███████║
 * ██║░░██║██║██║╚████║██╗░░██║██╔══██║
 * ██████╔╝██║██║░╚███║╚█████╔╝██║░░██║
 * ╚═════╝░╚═╝╚═╝░░╚══╝░╚════╝░╚═╝░░╚═╝
 * 
 *          ▄              ▄    
 *         ▌▒█           ▄▀▒▌   
 *         ▌▒▒█        ▄▀▒▒▒▐   
 *        ▐▄█▒▒▀▀▀▀▄▄▄▀▒▒▒▒▒▐   
 *      ▄▄▀▒▒▒▒▒▒▒▒▒▒▒█▒▒▄█▒▐   
 *    ▄▀▒▒▒░░░▒▒▒░░░▒▒▒▀██▀▒▌   
 *   ▐▒▒▒▄▄▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▀▄▒▌  
 *   ▌░░▌█▀▒▒▒▒▒▄▀█▄▒▒▒▒▒▒▒█▒▐  
 *  ▐░░░▒▒▒▒▒▒▒▒▌██▀▒▒░░░▒▒▒▀▄▌ 
 *  ▌░▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░▒▒▒▒▌ 
 * ▌▒▒▒▄██▄▒▒▒▒▒▒▒▒░░░░░░░░▒▒▒▐ 
 * ▐▒▒▐▄█▄█▌▒▒▒▒▒▒▒▒▒▒░▒░▒░▒▒▒▒▌
 * ▐▒▒▐▀▐▀▒▒▒▒▒▒▒▒▒▒▒▒▒░▒░▒░▒▒▐ 
 *  ▌▒▒▀▄▄▄▄▄▄▒▒▒▒▒▒▒▒░▒░▒░▒▒▒▌ 
 *  ▐▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░▒░▒▒▄▒▒▐  
 *   ▀▄▒▒▒▒▒▒▒▒▒▒▒▒▒░▒░▒▄▒▒▒▒▌  
 *     ▀▄▒▒▒▒▒▒▒▒▒▒▄▄▄▀▒▒▒▒▄▀   
 *       ▀▄▄▄▄▄▄▀▀▀▒▒▒▒▒▄▄▀     
 *          ▀▀▀▀▀▀▀▀▀▀▀▀        
 *
 * 
 * Tokenomics:
 * 
 * Normal Buy Tax = 10% 
 * Normal Sell Tax = 10%
 * Early snipers/movers advantage will be limited.
 * Anti-dump Tokenomics where sell tax will be proportional to price impact
 * 
 * 10% of all taxes collected will be redistributed to reward the holders
 * 
 * 
 * 
 * 
 * SPDX-License-Identifier: UNLICENSED 
 * 
*/

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

contract DINJA is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _bots;
    mapping (address => User) private trader;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    string private constant _name = unicode"DOGE NINJA SAMURAI";
    string private constant _symbol = unicode"DINJA";
    uint8 private constant _decimals = 9;
    uint256 private _taxFee = 1;
    uint256 private _teamFee = 6;
    uint256 private _launchTime;
    uint256 private _previousTaxFee = _taxFee;
    uint256 private _previousteamFee = _teamFee;
    uint256 private _maxBuyAmount;
    address payable private _FeeAddress;
    address payable private _marketingWalletAddress;
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen = false;
    bool private _cooldownEnabled = true;
    bool private _communityMode = false;
    bool private inSwap = false;
    uint256 private _launchBlock = 0;
    uint256 private buyLimitEnd;
    uint256 private _snipersTaxed = 0;
    uint256 private _transactionCount = 0;
    uint256 private _impactMultiplier = 1000;
    bool public swapAndLiquifyEnabled = true;
    uint256 private discountTaxFee = 0;

    //Keep it 0.5% of the supply
    uint256 public _maxTxAmount = 5000000000 * 10**9;
    uint256 public numTokensSellToAddToLiquidity = 2000000000 * 10**9;


    struct User {
        uint256 buyCD;
        bool exists;
    }

    event MaxBuyAmountUpdated(uint _maxBuyAmount);
    event CooldownEnabledUpdated(bool _cooldown);
    event FeeMultiplierUpdated(uint _multiplier);
    event FeeRateUpdated(uint _rate);

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor (address payable FeeAddress, address payable marketingWalletAddress) {
        _FeeAddress = FeeAddress;
        _marketingWalletAddress = marketingWalletAddress;
        _rOwned[_msgSender()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[FeeAddress] = true;
        _isExcludedFromFee[marketingWalletAddress] = true;
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

    function snipersTaxed() public view returns (uint256) {
        return _snipersTaxed;
    }

    function taxDiscount() public view returns (uint256) {
        return discountTaxFee;
    }

    function transactionCount() public view returns (uint256) {
        return _transactionCount;
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
        if(from != owner() && to != owner()) {
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            require(!_bots[from] && !_bots[to]);
            
            if(!trader[msg.sender].exists) {
                trader[msg.sender] = User(0,true);
            }
            uint256 totalFee = 10;
            // buy
            if(from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to]) {
                require(tradingOpen, "Trading not yet enabled.");
                
                if(block.number < _launchBlock + 2) {
                    totalFee = 80;
                    _snipersTaxed++;
                } else if(block.timestamp > _launchTime + (2 minutes)) {
                    totalFee = 10;
                } else if (block.timestamp > _launchTime + (45 seconds)) {
                    totalFee = 20;
                } else {
                    totalFee = 40;
                }
                if (discountTaxFee <= 8) {
                    totalFee = totalFee - discountTaxFee;
                }
                _taxFee = (totalFee).div(10);
                _teamFee = (totalFee.mul(9)).div(10);
                
                if(_cooldownEnabled) {
                    if(buyLimitEnd > block.timestamp) {
                        require(amount <= _maxBuyAmount);
                        require(trader[to].buyCD < block.timestamp, "Your buy cooldown has not expired.");
                        trader[to].buyCD = block.timestamp + (45 seconds);
                    }
                }
            
                
            }
            uint256 contractTokenBalance = balanceOf(address(this));

            // sell
            if(!inSwap && from != uniswapV2Pair && tradingOpen) {

                //price impact based sell tax
                uint256 amountImpactMultiplier = amount.mul(_impactMultiplier);
                uint256 priceImpact = amountImpactMultiplier.div(balanceOf(uniswapV2Pair).add(amount));
                
                if (priceImpact <= 10) {
                    totalFee = 10;
                } else if (priceImpact >= 40) {
                    totalFee = 40;
                } else if (priceImpact.mod(2) != 0) {
                    totalFee = ++priceImpact;
                } else {
                    totalFee = priceImpact;
                }
                
                if (discountTaxFee <= 8) {
                    totalFee = totalFee - discountTaxFee;
                }

                _taxFee = (totalFee).div(10);
                _teamFee = (totalFee.mul(9)).div(10);

                //To limit big dumps by the contract before the sells
                if(contractTokenBalance >= _maxTxAmount) {
                    contractTokenBalance = _maxTxAmount;
                }

                bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;

                if (
                    overMinTokenBalance &&
                    !inSwap &&
                    from != uniswapV2Pair &&
                    swapAndLiquifyEnabled
                ) {
                    contractTokenBalance = numTokensSellToAddToLiquidity;
                    swapAndLiquify(contractTokenBalance);
                }

                // uint256 contractETHBalance = address(this).balance;
                // if(contractETHBalance > 0) {
                //     sendETHToFee(address(this).balance);
                // }
            }
        }
        bool takeFee = true;

        if(_isExcludedFromFee[from] || _isExcludedFromFee[to] || _communityMode){
            takeFee = false;
        }
        
        _tokenTransfer(from,to,amount,takeFee);
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
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
        
    function sendETHToFee(uint256 amount) private {
        _marketingWalletAddress.transfer(amount);
    }
    
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if(!takeFee)
            removeAllFee();
        _transferStandard(sender, recipient, amount);
        if(!takeFee)
            restoreAllFee();
        _transactionCount++;
        if (_transactionCount.mod(400) == 0) {
            discountTaxFee++;
        }
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
        require(!tradingOpen,"trading is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        _maxBuyAmount = 5000000000 * 10**9;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        tradingOpen = true;
        buyLimitEnd = block.timestamp + (20 seconds);
        _launchTime = block.timestamp;
        _launchBlock = block.number;
    }

    function setMarketingWallet (address payable marketingWalletAddress) external {
        require(_msgSender() == _FeeAddress);
        _isExcludedFromFee[_marketingWalletAddress] = false;
        _marketingWalletAddress = marketingWalletAddress;
        _isExcludedFromFee[marketingWalletAddress] = true;
    }

    function upliftTxAmount() external onlyOwner() {
        _maxTxAmount = 1000000000000 * 10**9;
    }

    function setSwapThresholdAmount(uint256 SwapThresholdAmount) external onlyOwner() {
        require(SwapThresholdAmount > 69000000, "Swap Threshold Amount cannot be less than 69 Million");
        numTokensSellToAddToLiquidity = SwapThresholdAmount * 10**9;
    }
    
    function claimTokens () public onlyOwner {
        payable(_marketingWalletAddress).transfer(address(this).balance);
    }
    
    function claimOtherTokens(IERC20 tokenAddress, address walletaddress) external onlyOwner() {
        tokenAddress.transfer(walletaddress, tokenAddress.balanceOf(address(this)));
    }
    
    function clearStuckBalance (address payable walletaddress) external onlyOwner() {
        walletaddress.transfer(address(this).balance);
    }

    function excludeFromFee (address payable ad) external {
        require(_msgSender() == _FeeAddress);
        _isExcludedFromFee[ad] = true;
    }
    
    function includeToFee (address payable ad) external {
        require(_msgSender() == _FeeAddress);
        _isExcludedFromFee[ad] = false;
    }
    
    function setBots(address[] memory bots_) public onlyOwner {
        //Cannot set bots after 20 minutes of launch time to ensure contract is SAFU without renounce as well
        if (block.timestamp < _launchTime + (20 minutes)) {
            for (uint i = 0; i < bots_.length; i++) {
                if (bots_[i] != uniswapV2Pair && bots_[i] != address(uniswapV2Router)) {
                    _bots[bots_[i]] = true;
                }
            }
        }
    }
    
    function delBot(address notbot) public onlyOwner {
        _bots[notbot] = false;
    }
    
    function isBot(address ad) public view returns (bool) {
        return _bots[ad];
    }
    
    function setCooldownEnabled(bool onoff) external onlyOwner() {
        _cooldownEnabled = onoff;
        emit CooldownEnabledUpdated(_cooldownEnabled);
    }

    function thisBalance() public view returns (uint) {
        return balanceOf(address(this));
    }

    function cooldownEnabled() public view returns (bool) {
        return _cooldownEnabled;
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        // add the marketing wallet
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);
        //90
        uint256 marketingshare = newBalance.mul(80).div(100);
        payable(_marketingWalletAddress).transfer(marketingshare);
        newBalance -= marketingshare;
        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function timeToBuy(address buyer) public view returns (uint) {
        return block.timestamp - trader[buyer].buyCD;
    }
    
    function amountInPool() public view returns (uint) {
        return balanceOf(uniswapV2Pair);
    }
}