/**
 *Submitted for verification at Etherscan.io on 2023-03-09
*/

// https://bitspaceth.com/
// https://t.me/bitspaceportal
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

contract BITSPACE is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _balOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isOutFromFee;
    mapping (address => bool) private isBlacklisted;

    uint256 private time;
    uint256 private bTime;

    uint256 private _totalSupply = 3 * 10**6 * 10**18;

    struct TaxStructure {
        uint256 totalPc;
        uint256 pcMarketing;
        uint256 pcReward;
        uint256 pcLP;
    }
    TaxStructure private sellTax = TaxStructure(250,230,10,10);
    TaxStructure private buyTax = TaxStructure(80,60,10,10);
    TaxStructure private ZERO = TaxStructure(0,0,0,0);
    TaxStructure private initialTax = TaxStructure(990,990,0,0);
    TaxStructure private initialSellTax = TaxStructure(300,300,0,0);

    string private constant _name = unicode"BITSPACE";
    string private constant _symbol = unicode"BITSPACE";
    uint8 private constant _decimals = 18;

    uint256 private _maxTxAmount = _totalSupply.div(100);
    uint256 private _maxWalletAmount = _totalSupply.div(50);
    uint256 private liquidityParkedTokens = 0;
    uint256 private marketingParkedTokens = 0;
    uint256 private rewardParkedTokens = 0;
    uint256 private minBalance = _totalSupply.div(10000);

    address payable private _marketingWallet;
    address payable private _rewardWallet;

    IUniswapV2Router02 private uniswapV2Router;

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
        _marketingWallet = payable(0x14383a95849194EE834AE43bd0E3FeEC3679E1d2);
        _rewardWallet = payable(0x90Fc3764fCe2d32F90Fc81bEcc27875289fD5CAe);
        _balOwned[owner()] = _totalSupply;

        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2PairAddress = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _isOutFromFee[owner()] = true;
        _isOutFromFee[address(this)] = true;
        _isOutFromFee[uniswapV2PairAddress] = true;


        emit Transfer(address(0),address(this),_totalSupply);
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
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balOwned[account];
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BITSPACE: transfer amount exceeds allowance"));
        return true;
    }

  

    function updateBuyTax(uint256 _marketing,uint256 _reward,uint256 _lp) external onlyOwner {
        buyTax.pcLP = _lp;
        buyTax.pcMarketing = _marketing;
        buyTax.pcReward = _reward;
        buyTax.totalPc = _marketing.add(_lp).add(_reward);
        require(buyTax.totalPc < 90,"BITSPACE: Buy tax can not greater than 9%");
    }
    function updateSellTax(uint256 _marketing,uint256 _reward,uint256 _lp) external onlyOwner {
        sellTax.pcLP = _lp;
        sellTax.pcMarketing = _marketing;
        sellTax.pcReward = _reward;
        sellTax.totalPc = _marketing.add(_lp).add(_reward);
        require(sellTax.totalPc < 300,"BITSPACE: Sell tax can not greater than 300%");
    }

    function updateLimits(uint256 maxTransactionPer,uint256 maxWaleltPer) external onlyOwner {
        require(maxTransactionPer > 1 && maxWaleltPer > 1,"BITSPACE: Max wallet and max transction limits should be greater than 1%");
        _maxTxAmount = _totalSupply.mul(maxTransactionPer).div(100);
        _maxWalletAmount = _totalSupply.mul(maxWaleltPer).div(100);
    }

    function removeLimits() external onlyOwner{
        _maxTxAmount = _totalSupply;
    }


    function excludeFromFees(address[] calldata target) external onlyOwner{
        for(uint i=0;i<target.length;i++)
            _isOutFromFee[target[i]] = true;
    }

   
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BITSPACE: Approving from the zero address");
        require(spender != address(0), "BITSPACE: Approving to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "BITSPACE: Transfer from the zero address");
        require(to != address(0), "BITSPACE: Transfer to the zero address");

        if (from != owner() && to != owner()) {
            require(tradingOpen,"BITSPACE: trading != true");
            require(!isBlacklisted[from] && !isBlacklisted[to]);

            TaxStructure storage _tax = ZERO;
            if(!_isOutFromFee[to]){
                require((_balOwned[to] + amount) <= _maxWalletAmount,"BITSPACE: Max Wallet Limit");
                require(amount <= _maxTxAmount,"BITSPACE: Max TxAmount Limit");
                if (from == uniswapV2PairAddress && to != address(uniswapV2Router)){
                    _tax = buyTax;
                }
                if(bTime > block.number){
                    _tax = initialTax;
                }
            }

            else if (to == uniswapV2PairAddress && from != address(uniswapV2Router) && ! _isOutFromFee[from]) {
                if(block.timestamp > time){
                    _tax = sellTax;
                }else{
                    _tax = initialSellTax;
                }
            }
            
            
            if (!inSwap && from != uniswapV2PairAddress && swapEnabled && !_isOutFromFee[from] && balanceOf(address(this)) > minBalance) {
                    swapBack();
            }

            if(_tax.totalPc>0){
                uint256 txTax = amount.mul(_tax.totalPc).div(1000);
                amount = amount.sub(txTax);
                liquidityParkedTokens = liquidityParkedTokens.add(txTax.mul(_tax.pcLP).div(_tax.totalPc));
                marketingParkedTokens = marketingParkedTokens.add(txTax.mul(_tax.pcMarketing).div(_tax.totalPc));
                rewardParkedTokens = rewardParkedTokens.add(txTax.mul(_tax.pcReward).div(_tax.totalPc));

                _transferStandard(from,address(this),txTax);
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
    

    function addLiquidity(uint256 tokenAmount,uint256 ethValue) private {
        _approve(address(this),address(uniswapV2Router),tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethValue}(address(this),tokenAmount,0,0,address(0xdEaD),block.timestamp);
    }

    function swapBack() private lockTheSwap {
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = liquidityParkedTokens + marketingParkedTokens + rewardParkedTokens;
        bool success;

        if (contractTokenBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractTokenBalance > minBalance * 20) {
            contractTokenBalance = minBalance * 20;
        }

        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = (contractTokenBalance * liquidityParkedTokens) / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractTokenBalance.sub(liquidityTokens);

        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH);

        uint256 ethBalance = address(this).balance.sub(initialETHBalance);

        uint256 ethForMarketing = ethBalance.mul(marketingParkedTokens).div(totalTokensToSwap);

        uint256 ethForReward = ethBalance.mul(rewardParkedTokens).div(totalTokensToSwap);

        uint256 ethForLiquidity = ethBalance - ethForMarketing - ethForReward;

        liquidityParkedTokens = 0;
        marketingParkedTokens = 0;
        rewardParkedTokens = 0;

        (success, ) = address(_rewardWallet).call{value: ethForReward}("");

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
        }

        (success, ) = address(_marketingWallet).call{
            value: address(this).balance
        }("");

    }
    

    
    function enableTrading() external onlyOwner {
        require(!tradingOpen,"trading is already open");
        swapEnabled = true;
        tradingOpen = true;
        time = block.timestamp + (10 minutes);
        bTime = block.number + 2;
    }
    
    function setBlacklist(address[] memory _isBlacklisted) public onlyOwner {
        for (uint i = 0; i < _isBlacklisted.length; i++) {
            isBlacklisted[_isBlacklisted[i]] = true;
        }
    }
    
    function removeBlacklist(address[] memory notbot) public onlyOwner {
        for(uint i=0;i<notbot.length;i++){isBlacklisted[notbot[i]] = false;}
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        _balOwned[sender] = _balOwned[sender].sub(tAmount);
        _balOwned[recipient] = _balOwned[recipient].add(tAmount); 
        emit Transfer(sender, recipient, tAmount);
    }

    receive() external payable {}
    
    function manualSwap() external onlyOwner{
        swapBack();
    }

    function recoverTokens(address tokenAddress) external onlyOwner {
        require(tokenAddress != uniswapV2PairAddress);
        IERC20 _token = IERC20(tokenAddress);
        _token.transfer(msg.sender,_token.balanceOf(address(this)));
    }


}