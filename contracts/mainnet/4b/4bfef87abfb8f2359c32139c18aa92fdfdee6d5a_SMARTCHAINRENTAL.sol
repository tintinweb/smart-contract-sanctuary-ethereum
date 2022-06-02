/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

// SPDX-License-Identifier: UNLICENSED

/*

.......$$$$$..................................................................................................
.......$:::$..................................................................................................
...$$$$$:::$$$$$$.TTTTTTTTTTTTTTTTTTTTTTTEEEEEEEEEEEEEEEEEEEEEENNNNNNNN........NNNNNNNNTTTTTTTTTTTTTTTTTTTTTTT
.$$::::::::::::::$T:::::::::::::::::::::TE::::::::::::::::::::EN:::::::N.......N::::::NT:::::::::::::::::::::T
$:::::$$$$$$$::::$T:::::::::::::::::::::TE::::::::::::::::::::EN::::::::N......N::::::NT:::::::::::::::::::::T
$::::$.......$$$$$T:::::TT:::::::TT:::::TEE::::::EEEEEEEEE::::EN:::::::::N.....N::::::NT:::::TT:::::::TT:::::T
$::::$............TTTTTT..T:::::T..TTTTTT..E:::::E.......EEEEEEN::::::::::N....N::::::NTTTTTT..T:::::T..TTTTTT
$::::$....................T:::::T..........E:::::E.............N:::::::::::N...N::::::N........T:::::T........
$:::::$$$$$$$$$...........T:::::T..........E::::::EEEEEEEEEE...N:::::::N::::N..N::::::N........T:::::T........
.$$::::::::::::$$.........T:::::T..........E:::::::::::::::E...N::::::N.N::::N.N::::::N........T:::::T........
...$$$$$$$$$:::::$........T:::::T..........E:::::::::::::::E...N::::::N..N::::N:::::::N........T:::::T........
............$::::$........T:::::T..........E::::::EEEEEEEEEE...N::::::N...N:::::::::::N........T:::::T........
............$::::$........T:::::T..........E:::::E.............N::::::N....N::::::::::N........T:::::T........
$$$$$.......$::::$........T:::::T..........E:::::E.......EEEEEEN::::::N.....N:::::::::N........T:::::T........
$::::$$$$$$$:::::$......TT:::::::TT......EE::::::EEEEEEEE:::::EN::::::N......N::::::::N......TT:::::::TT......
$::::::::::::::$$.......T:::::::::T......E::::::::::::::::::::EN::::::N.......N:::::::N......T:::::::::T......
.$$$$$$:::$$$$$.........T:::::::::T......E::::::::::::::::::::EN::::::N........N::::::N......T:::::::::T......
......$:::$.............TTTTTTTTTTT......EEEEEEEEEEEEEEEEEEEEEENNNNNNNN.........NNNNNNN......TTTTTTTTTTT......
......$$$$$...................................................................................................

                                        https://t.me/smartchainrentalportal
                                        https://smartchain.rentals/
                                        https://twitter.com/SCRtoken

*/

pragma solidity ^0.8.5;
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

contract SMARTCHAINRENTAL is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private bots;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 10000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    
    uint256 private _tfee;
    uint256 private _mfee;
    uint256 private _sellFee;
    uint256 private _buyFee;
    address payable private _feeAddress;
    
    string private constant _name = "SmartChain Rental";
    string private constant _symbol = "TENT";
    uint8 private constant _decimals = 9;
    
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingStarted;
    bool private inSwap = false;
    bool private swapEnable = false;
    bool private removeMaxTxn = false;
    uint256 private _maxTxAmount = _tTotal;
    uint256 private _maxHeldAmount = _tTotal;       
    event MaxTxAmountUpdated(uint _maxHeldAmount);       
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor () {
        _buyFee = 12;
        _sellFee = 12;
        _feeAddress = payable(_msgSender());
        _rOwned[address(this)] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_feeAddress] = true;
        emit Transfer(address(0), address(this), _tTotal);
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

    function setRemoveMaxTxn(bool onoff) external onlyOwner() {
        removeMaxTxn = onoff;
    }

    function tokenFromReflection(uint256 rAmount) private view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
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
        require(!bots[from]);

        if (!_isExcludedFromFee[from] 
            && !_isExcludedFromFee[to] ) {
            _tfee = 0;
            _mfee = _buyFee;
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFee[to] && removeMaxTxn) {
                uint walletBalance = balanceOf(address(to));
                require(amount <= _maxTxAmount);
                require(amount.add(walletBalance) <= _maxHeldAmount);       
            }
            
            
            if (to == uniswapV2Pair && from != address(uniswapV2Router) && ! _isExcludedFromFee[from]) {
                _tfee = 0;
                _mfee = _sellFee;
            }
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && from != uniswapV2Pair && swapEnable) {
                swapTokensForEth(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }
		
        _tokenTransfer(from,to,amount);
    }


    function _setMaxTxAmount(uint256 maxTxAmount , uint256 maxHeldAmount) external onlyOwner() {
        if (maxTxAmount > 10000000 * 10**9) {
            _maxTxAmount = maxTxAmount;
            _maxHeldAmount = maxHeldAmount;
        }
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
        _feeAddress.transfer(amount);
    }

    function newPair() external onlyOwner(){
        require(!tradingStarted,"trading is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

    }
    
    function startTrading() external onlyOwner() {
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        swapEnable = true;
        removeMaxTxn = true;
        _maxTxAmount = 200000000 * 10**9;
        _maxHeldAmount = 200000000 * 10**9;
        tradingStarted = true;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }

    
    function addBots(address[] memory bots_) public onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }
    
    function delBots(address notbot) public onlyOwner {
        bots[notbot] = false;
    }
        
    function _tokenTransfer(address sender, address recipient, uint256 amount) private {
        _transferStandard(sender, recipient, amount);
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount); 
        _takeTeam(tTeam);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
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
    
    function manualswap() public onlyOwner() {
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }
    
    function manualsend() public onlyOwner() {
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }
    

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getTValues(tAmount, _tfee, _mfee);
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

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tTeam, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTeam);
        return (rAmount, rTransferAmount, rFee);
    }

	function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function setFee(uint256 buyFee, uint256 sellFee)external onlyOwner() {

        if (sellFee <= 15 && buyFee <= 15) {
            _buyFee = buyFee;
            _sellFee = sellFee;
        }
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
}