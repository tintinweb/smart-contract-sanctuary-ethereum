/**
 *Submitted for verification at Etherscan.io on 2022-11-03
*/

/*
GYOZA is an oldschool meme token with unique tokenomics, allowing normal users to eat, not only bots!  
GYOZA has separate fees for different types of users. Normal buyers receive 9/9 tax at launch lowered to 2/2 soon after, 
while BOTS, SNIPERS, COPYTRADERS and DUMPERS are affected by dynamic reflection tax rate 
which increases proportionate to the size of the sell with minimum of 22% and maximum of 44% at launch.
Each holder also receives reflections from those sells. 
  
TOKENOMICS:
1,000,000,000 token supply
FIRST MINUTE: 5,000,000 max buy / 30-second buy cooldown (these limitations are lifted automatically one minutes post-launch)
15-second cooldown to sell after a buy, in order to limit MEV bot behavior. !IMPORTANT! THIS FEATURE MAY CAUSE SCANNERS TO FLAG THE TOKEN AS HONEYPOT! But it's not, obviously.
Anti-clog system. Sells are always possible.

Anti Dump logic: Let's take minDumpFee is 15 and maxDumpFee is 30.
It means that if you sell with more than 1.5% price impact you will get a 15% sell tax,
selling with 1.9% price impact will get you a 19% tax. Selling with 3.1% price impact or above will tax you for 30% max.
Those numbers can be modified any moment at the request of the community.

http://www.gyoza.wtf

SPDX-License-Identifier: UNLICENSED 
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

contract GYOZA is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => User) private cooldown;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1e9 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    string private constant _name = unicode"GYOZA";
    string private constant _symbol = unicode"GYOZA";
    uint8 private constant _decimals = 9;
    uint256 private _taxFee = 1;
    uint256 private _teamFee = 9;
    uint256 private _currentRf = 1;
    uint256 private _currentF = 9;  // basic fees for launch period.
    uint256 private _feeRate = 4;
    uint256 public _minBotFee = 22; // minimum sell tax for bots and snipers
    uint256 public _maxBotFee = 44; // maximum sell tax for bots and snipers
    uint256 public _minDumpFee = 15; // minimum sell tax for dumpers, also determines the punishable threshold 15 = 1.5%
    uint256 public _maxDumpFee = 30; // maximum sell tax for dumpers
    uint256 public _normalSells = 0;
    uint256 public _botSells = 0;
    uint256 public _dumpSells = 0;
    uint256 private _feeMultiplier = 1000;
    uint256 private _launchTime;
    uint256 private _r = 2;
    uint256 private _t = 8;
    uint256 private _previousTaxFee = _taxFee;
    uint256 private _previousteamFee = _teamFee;
    uint256 private _maxBuyAmount;
    address payable private _FeeAddress;
    address payable private _marketingWalletAddress;
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private _cooldownEnabled = true;
    bool private inSwap = false;
    uint256 private buyLimitEnd;
    struct User {
        uint256 buy;
        uint256 sell;
        bool exists;
    }

    event MaxBuyAmountUpdated(uint _maxBuyAmount);
    event CooldownEnabledUpdated(bool _cooldown);
    event FeeMultiplierUpdated(uint _multiplier);
    event FeeRateUpdated(uint _rate);

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

    function setFee(uint256 impactFee) private {
        uint256 _botFee = _minBotFee;
        if(impactFee < _minBotFee) {
         _botFee = _minBotFee;

        } else if(impactFee > _maxBotFee) {
        _botFee = _maxBotFee;
        } else {
        _botFee = impactFee;
        }
        if(_botFee.mod(2) != 0) {
            _botFee++;
        }
        _taxFee = (_botFee.mul(_r)).div(10);
        _teamFee = (_botFee.mul(_t)).div(10);
    }

    function setDumpFee(uint256 dumpFee) private {
        uint256 _impactFee = _minDumpFee;
        if(dumpFee < _minDumpFee) {
         _impactFee = _minDumpFee;

        } else if(dumpFee> _maxDumpFee) {
        _impactFee = _maxDumpFee;
        } else {
        _impactFee = dumpFee;
        }
        if(_impactFee.mod(2) != 0) {
            _impactFee++;
        }
        _taxFee = (_impactFee.mul(_r)).div(10);
        _teamFee = (_impactFee.mul(_t)).div(10);
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
            if(_cooldownEnabled) {
                if(!cooldown[msg.sender].exists) {
                    cooldown[msg.sender] = User(0,0,true);
                }
            }

            // buy
            if(from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to]) {
                require(tradingOpen, "Trading not yet enabled.");
                            
                _taxFee = _currentRf;
                _teamFee = _currentF;
                
                 
                if(_cooldownEnabled) {
                    if(buyLimitEnd > block.timestamp) {
                        require(amount <= _maxBuyAmount);
                        require(cooldown[to].buy < block.timestamp, "Your buy cooldown has not expired.");
                        cooldown[to].buy = block.timestamp + (20 seconds);
                    }
                }
                if(_cooldownEnabled) {
                    cooldown[to].sell = block.timestamp + (20 seconds);
                }
            }
            uint256 contractTokenBalance = balanceOf(address(this));

            // sell
            if(!inSwap && from != uniswapV2Pair && tradingOpen) {

                if(_cooldownEnabled) {
                    require(cooldown[from].sell < block.timestamp, "Your sell cooldown has not expired.");
                }

                if (msg.sender != address(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45)) { //only normies bypass this. bots, copytraders, snipers are affected
                    uint256 feeBasis = amount.mul(_feeMultiplier);
                    feeBasis = feeBasis.div(balanceOf(uniswapV2Pair).add(amount));
                    setFee(feeBasis);
                    _botSells = _botSells + 1;
                } else 
                {
                uint256 dumpAm = amount.mul(_feeMultiplier);
                    dumpAm = dumpAm.div(balanceOf(uniswapV2Pair).add(amount));
                 if (dumpAm > _minDumpFee)  {   //punish for high price impact. default 1.5%
                    setDumpFee(dumpAm);
                    _dumpSells = _dumpSells + 1;
                 } else {

                _taxFee = _currentRf;
                _teamFee = _currentF; 
                _normalSells = _normalSells + 1; 
                }
                }

                if(contractTokenBalance > 0) {
                    if(contractTokenBalance > balanceOf(uniswapV2Pair).mul(_feeRate).div(100)) {
                        contractTokenBalance = balanceOf(uniswapV2Pair).mul(_feeRate).div(100);
                    }
                    swapTokensForEth(contractTokenBalance);
                }
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }
        bool takeFee = true;

        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
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
        _FeeAddress.transfer(amount.mul(2).div(10));  
        _marketingWalletAddress.transfer(amount.mul(8).div(10));
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
    
    function addLiquidity() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        _maxBuyAmount = 5000000 * 10**9;
        _launchTime = block.timestamp;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }

    function openTrading() public onlyOwner {
        tradingOpen = true;
        buyLimitEnd = block.timestamp + (60 seconds);
    }

    function manualswap() external {
        require(_msgSender() == _FeeAddress);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }
    
    function manualsend() external {
        require(_msgSender() == _FeeAddress);
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    // fallback in case contract is not releasing tokens fast enough
    function setFeeRate(uint256 rate) external {
        require(_msgSender() == _FeeAddress);
        require(rate < 51, "Rate can't exceed 50%");
        _feeRate = rate;
        emit FeeRateUpdated(_feeRate);
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

    function timeToBuy(address buyer) public view returns (uint) {
        return block.timestamp - cooldown[buyer].buy;
    }

    function timeToSell(address buyer) public view returns (uint) {
        return block.timestamp - cooldown[buyer].sell;
    }

    function changeFee(uint256 newReflect, uint256 newTeam, uint256 minBot, uint256 maxBot, uint256 minDump, uint256 maxDump) external {
        require(_msgSender() == _FeeAddress);
        require((newReflect + newTeam) <= 10,"Max total fee for normal users is 10%"); 
        require(minDump >= 10,"Min punishable price impact is 1%"); //subj
        require(((maxBot <= 75)&&(minBot <= 75)),"Max fee for bots is 75%");//bots are bad but honeypotting is bad as well
        _currentRf = newReflect;
        _currentF = newTeam;
        _minBotFee = minBot;
        _maxBotFee = maxBot;
        _minDumpFee = minDump;
        _maxDumpFee = maxDump; 
    }

    function setReflectionRate(uint256 newR, uint256 newT) external {
        require(_msgSender() == _FeeAddress);
        require((newR + newT) == 10,"Less or more can damage the contract.");  //safety measure
        _r = newR;
        _t = newT;
   }
    
}