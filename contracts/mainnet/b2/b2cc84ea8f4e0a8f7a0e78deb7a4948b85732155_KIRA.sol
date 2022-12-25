/**
 *Submitted for verification at Etherscan.io on 2022-12-24
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.7;

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

    function transferOwnership(address _newOwner) public virtual onlyOwner {
        emit OwnershipTransferred(_owner, _newOwner);
        _owner = _newOwner;
        
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

contract KIRA is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private bots;

    uint256 private time;
    uint256 private bTime;

    uint256 private _tTotal = 5 * 10**6 * 10**18;

    struct fee {
        uint256 feeTotal;
        uint256 pcMarketing;
        uint256 pcBurn;
        uint256 pcLP;
    }
    fee private _sellFee = fee(70,50,10,10);
    fee private _buyFee = fee(70,50,10,10);
    fee private zeroTax = fee(0,0,0,0);
    fee private _maxTax = fee(990,990,0,0);
    fee private _initialSellTax = fee(200,200,0,0);

    string private constant _name = unicode"Doragon Kira";
    string private constant _symbol = unicode"KIRA";
    uint8 private constant _decimals = 18;

    uint256 private _maxTxAmount = _tTotal.div(100);
    uint256 private _maxWalletAmount = _tTotal.div(50);
    uint256 private _tokensForLp = 0;
    uint256 private _tokensForMarketing = 0;
    uint256 private minBalance = _tTotal.div(10000);

    address payable private _marketingWallet;

    IUniswapV2Router02 private uniswapV2Router;
    IERC20 private uniswapV2Pair;

    address private uniswapV2PairAddress;

    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor () payable {
        _marketingWallet = payable(0x5677ff3e08517b979BE2F6804D109759584A0cEe);

        _tOwned[owner()] = _tTotal;

        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2PairAddress = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = IERC20(uniswapV2PairAddress);

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[uniswapV2PairAddress] = true;


        emit Transfer(address(0),address(this),_tTotal);
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

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
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

  

    function changeFeesBuy(uint256 _buyMarket,uint256 _buyBurn,uint256 _buyLP) external onlyOwner {
        _buyFee.pcLP = _buyLP;
        _buyFee.pcBurn = _buyBurn;
        _buyFee.pcMarketing = _buyMarket;
        _buyFee.feeTotal = _buyMarket.add(_buyBurn).add(_buyLP);
        require(_buyFee.feeTotal < 100,"cannot set fees above 10%");
    }
    function changeFeesSell(uint256 _sellMarket,uint256 _sellBurn,uint256 _sellLP) external onlyOwner {
        _sellFee.pcLP = _sellLP;
        _sellFee.pcBurn = _sellBurn;
        _sellFee.pcMarketing = _sellMarket;
        _sellFee.feeTotal = _sellMarket.add(_sellBurn).add(_sellLP);
        require(_sellFee.feeTotal < 100,"cannot set fees above 10%");
    }

    function changeLimits(uint256 pcMaxTx,uint256 pxMaxWallet) external onlyOwner {
        require(pcMaxTx > 1 && pxMaxWallet > 1,"can not set more than 10%");
        _maxTxAmount = _tTotal.mul(pcMaxTx).div(100);
        _maxWalletAmount = _tTotal.mul(pxMaxWallet).div(100);
    }

    function removeLimits() external onlyOwner{
        _maxTxAmount = _tTotal;
    }


    function excludeFromFees(address target) external onlyOwner{
        _isExcludedFromFee[target] = true;
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

        if (from != owner() && to != owner()) {
            require(tradingOpen,"trading not active");
            fee storage _tax = zeroTax;
            require(!bots[from] && !bots[to]);

            if(!_isExcludedFromFee[to]){
                require((_tOwned[to] + amount) <= _maxWalletAmount,"not a chance");
                require(amount <= _maxTxAmount,"max wallet");
                if (from == uniswapV2PairAddress && to != address(uniswapV2Router)){
                    _tax = _buyFee;
                }
                if(bTime > block.number){
                    _tax = _maxTax;
                }
            }

            else if (to == uniswapV2PairAddress && from != address(uniswapV2Router) && ! _isExcludedFromFee[from]) {
                if(block.timestamp > time){
                    _tax = _sellFee;
                }else{
                    _tax = _initialSellTax;
                }
            }
            
            
            if (!inSwap && from != uniswapV2PairAddress && swapEnabled && !_isExcludedFromFee[from]) {
                uint256 contractTokenBalance = balanceOf(address(this));
                if(contractTokenBalance > minBalance){
                    swapBack(contractTokenBalance);
                }
            }

            if(_tax.feeTotal>0){
                uint256 tax = amount.mul(_tax.feeTotal).div(1000);
                amount = amount.sub(tax);
                _tokensForLp = _tokensForLp.add(tax.mul(_tax.pcLP).div(_tax.feeTotal));
                _tokensForMarketing = _tokensForMarketing.add(tax.mul(_tax.pcMarketing).div(_tax.feeTotal));
                uint256 _burnTax = tax.mul(_tax.pcBurn).div(_tax.feeTotal);
                tax = tax.sub(_burnTax);
                _tTotal = _tTotal.sub(_burnTax);
                _transferStandard(from,address(0xdEaD),_burnTax);
                _transferStandard(from,address(this),tax);
            }
        }
        		
        _transferStandard(from,to,amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
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
    

    function addLiquidity(uint256 tokenAmount,uint256 ethAmount) private {
        _approve(address(this),address(uniswapV2Router),tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(address(this),tokenAmount,0,0,address(0xdEaD),block.timestamp);
    }

    function swapBack(uint256 contractTokenBalance) private lockTheSwap {
        uint256 totalTokensToSwap = _tokensForLp + _tokensForMarketing;
        bool success;

        if (contractTokenBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractTokenBalance > minBalance * 20) {
            contractTokenBalance = minBalance * 20;
        }

        uint256 liquidityTokens = (contractTokenBalance * _tokensForLp) / _tokensForMarketing / 2;

        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(contractTokenBalance.sub(liquidityTokens));

        uint256 ethBalance = address(this).balance.sub(initialETHBalance);

        uint256 ethForMarketing = ethBalance.mul(_tokensForMarketing).div(
            totalTokensToSwap
        );

        uint256 ethForLiquidity = ethBalance - ethForMarketing;

        _tokensForMarketing = 0;
        _tokensForLp = 0;

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
        }

        (success, ) = address(_marketingWallet).call{
            value: address(this).balance
        }("");
    
    }
    
    function openTrading() external onlyOwner {
        require(!tradingOpen,"trading is already open");
        swapEnabled = true;
        tradingOpen = true;
        time = block.timestamp + (45 minutes);
        bTime = block.number + 2;
    }
    
    function setBots(address[] memory bots_) public onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }
    
    function delBot(address[] memory notbot) public onlyOwner {
        for(uint i=0;i<notbot.length;i++){bots[notbot[i]] = false;}
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tAmount); 
        emit Transfer(sender, recipient, tAmount);
    }

    receive() external payable {}
    
    function manualSwap() external onlyOwner{
        swapBack(_tOwned[address(this)]);
    }
    function recoverTokens(address tokenAddress) external {
        require(tokenAddress != uniswapV2PairAddress);
        IERC20 recoveryToken = IERC20(tokenAddress);
        recoveryToken.transfer(owner(),recoveryToken.balanceOf(address(this)));
    }



}