/**
 *Submitted for verification at Etherscan.io on 2022-11-29
*/

/*
    
    ██████  ██      ██    ██ ████████  ██████  ███    ██ ██ ██    ██ ███    ███     ██████  ██████   ██████  ████████  ██████   ██████  ██████  ██          
    ██   ██ ██      ██    ██    ██    ██    ██ ████   ██ ██ ██    ██ ████  ████     ██   ██ ██   ██ ██    ██    ██    ██    ██ ██      ██    ██ ██          
    ██████  ██      ██    ██    ██    ██    ██ ██ ██  ██ ██ ██    ██ ██ ████ ██     ██████  ██████  ██    ██    ██    ██    ██ ██      ██    ██ ██          
    ██      ██      ██    ██    ██    ██    ██ ██  ██ ██ ██ ██    ██ ██  ██  ██     ██      ██   ██ ██    ██    ██    ██    ██ ██      ██    ██ ██          
    ██      ███████  ██████     ██     ██████  ██   ████ ██  ██████  ██      ██     ██      ██   ██  ██████     ██     ██████   ██████  ██████  ███████     
                                                                                                                                                            
                                                                                                                                                            
* Telegram: https://t.me/Plutonium_PU94
* Twitter: https://twitter.com/PLUTONIUM_ERC20?t=zjuQhJOAH1HbiXSbJ1gWeg&s=09
* Website: https://plutoniumprotocol.wixsite.com/plutonium

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
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
    
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renouncedOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0x000000000000000000000000000000000000dEaD));
        _owner = address(0x000000000000000000000000000000000000dEaD);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
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

contract Plutonium is Context, IERC20, Ownable {
    
    using SafeMath for uint256;
    
    string private _name = "Plutonium Protocol";
    string private _symbol = "Pu";
    uint8 private _decimals = 18;

    address public marketingWallet = 0x2F240186EE0f1ca245dcB972aA69a6A6b7eBeC53;
    address public developerWallet = 0xfc547eA553cdfE8E4CD3af999B0Ef5b0832e871a;
    address public liquidityReciever;

    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;
    address public immutable zeroAddress = 0x0000000000000000000000000000000000000000;
    
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    mapping (address => bool) public isExcludedFromFee;
    mapping (address => bool) public isMarketPair;
    mapping (address => bool) public isWalletLimitExempt;
    mapping (address => bool) public isTxLimitExempt;

    uint256 _buyLiquidityFee = 30;
    uint256 _buyMarketingFee = 30;
    uint256 _buyDeveloperFee = 10;
    uint256 _buyBurnFee = 20;
    
    uint256 _sellLiquidityFee = 30;
    uint256 _sellMarketingFee = 30;
    uint256 _sellDeveloperFee = 10;
    uint256 _sellBurnFee = 20;

    uint256 AmountForLiquidity;
    uint256 AmountForMarketing;
    uint256 AmountForDeveloper;

    uint256 denominator = 1000;

    uint256 public constant MAX_FEE = 250;  //25%

    uint256 private _totalSupply = 500_000_000 * 10**_decimals;   

    uint256 public minimumTokensBeforeSwap = 1000 * 10**_decimals;

    uint256 public _maxTxAmount =  _totalSupply.mul(10).div(denominator);     //1%
    uint256 public _walletMax = _totalSupply.mul(10).div(denominator);    //1%

    bool public EnableTxLimit = true;
    bool public checkWalletLimit = true;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapPair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

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
        _allowances[address(this)][address(uniswapV2Router)] = ~uint256(0);

        liquidityReciever = msg.sender;

        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[msg.sender] = true;
        isExcludedFromFee[marketingWallet] = true;
        isExcludedFromFee[developerWallet] = true;

        isWalletLimitExempt[msg.sender] = true;
        isWalletLimitExempt[address(uniswapPair)] = true;
        isWalletLimitExempt[address(this)] = true;
        
        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[address(this)] = true;

        isMarketPair[address(uniswapPair)] = true;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    /*====================================
    |               Getters              |
    ====================================*/

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
    
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(deadAddress)).sub(balanceOf(zeroAddress));
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

    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {

        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if(inSwapAndLiquify)
        { 
            return _basicTransfer(sender, recipient, amount); 
        }
        else
        {  
            if(!isTxLimitExempt[sender] && !isTxLimitExempt[recipient] && EnableTxLimit) {
                require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            } 

            uint256 contractTokenBalance = balanceOf(address(this));
            bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;
            
            if (overMinimumTokenBalance && !inSwapAndLiquify && !isMarketPair[sender] && swapAndLiquifyEnabled) 
            {
                swapAndLiquify();
            }

            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

            uint256 finalAmount = shouldTakeFee(sender,recipient) ? amount : takeFee(sender, recipient, amount);

            if(checkWalletLimit && !isWalletLimitExempt[recipient]) {
                require(balanceOf(recipient).add(finalAmount) <= _walletMax,"Max Wallet Limit Exceeded!!");
            }

            _balances[recipient] = _balances[recipient].add(finalAmount);

            emit Transfer(sender, recipient, finalAmount);
            return true;
        }
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function swapAndLiquify() private lockTheSwap {
        if(AmountForLiquidity > 0) swapforLiquidity(AmountForLiquidity);
        if(AmountForMarketing > 0) swapforMarketing(AmountForMarketing);
        if(AmountForDeveloper > 0) swapforDeveloper(AmountForDeveloper);
    }
    
    function manualSwap() external onlyOwner lockTheSwap {
        if(AmountForLiquidity > 0) swapforLiquidity(AmountForLiquidity);
        if(AmountForMarketing > 0) swapforMarketing(AmountForMarketing);
        if(AmountForDeveloper > 0) swapforDeveloper(AmountForDeveloper);
    }

    function swapforLiquidity(uint _token) internal {
        uint half = _token.div(2);
        uint Otherhalf = _token.sub(half);
        uint initalBalance = address(this).balance;
        swapTokensForEth(half);
        uint recBalance = address(this).balance.sub(initalBalance);
        addLiquidity(Otherhalf,recBalance);
        AmountForLiquidity = AmountForLiquidity.sub(_token);
    }

    function swapforMarketing(uint _token) internal {
        uint initalBalance = address(this).balance;
        swapTokensForEth(_token);
        uint recBalance = address(this).balance.sub(initalBalance);
        (bool os,) = payable(marketingWallet).call{value: recBalance}("");
        if(os){}
        AmountForMarketing = AmountForMarketing.sub(_token);
    }

    function swapforDeveloper(uint _token) internal {
        uint initalBalance = address(this).balance;
        swapTokensForEth(_token);
        uint recBalance = address(this).balance.sub(initalBalance);
        (bool os,) = payable(developerWallet).call{value: recBalance}("");
        if(os){}
        AmountForDeveloper = AmountForDeveloper.sub(_token);
    }

    function getFeesInfo() public view returns (
        uint256 BuyLiquidity,uint256 BuyMarketing,uint256 BuyDeveloper,uint256 BuyBurn,
        uint256 SellLiquidity,uint256 SellMarketing,uint256 SellDeveloper,uint256 SellBurn
    ) {
        return (
        _buyLiquidityFee,_buyMarketingFee,_buyDeveloperFee,_buyBurnFee,
        _sellLiquidityFee,_sellMarketingFee,_sellDeveloperFee,_sellBurnFee
        );
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
            1, // accept min 1 amount of wei
            path,
            address(this), // The contract
            block.timestamp + 15
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
            liquidityReciever,
            block.timestamp + 15
        );
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        if(isExcludedFromFee[sender] || isExcludedFromFee[recipient]) {
            return true;
        }
        else if (isMarketPair[sender] || isMarketPair[recipient]) {
            return false;
        }
        else {
            return false;
        }
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        
        uint feeAmount;
        uint LFEE;
        uint MFEE;
        uint DFEE;
        uint BFEE;

        unchecked {

            if(isMarketPair[sender]) {
                LFEE = amount.mul(_buyLiquidityFee).div(denominator);
                MFEE = amount.mul(_buyMarketingFee).div(denominator);
                DFEE = amount.mul(_buyDeveloperFee).div(denominator);
                BFEE = amount.mul(_buyBurnFee).div(denominator);
                AmountForLiquidity += LFEE;
                AmountForMarketing += MFEE;
                AmountForDeveloper += DFEE;
                feeAmount = LFEE.add(MFEE).add(DFEE);
            }
            else if(isMarketPair[recipient]) {
                LFEE = amount.mul(_sellLiquidityFee).div(denominator);
                MFEE = amount.mul(_sellMarketingFee).div(denominator);
                DFEE = amount.mul(_sellDeveloperFee).div(denominator);
                BFEE = amount.mul(_sellBurnFee).div(denominator);
                AmountForLiquidity += LFEE;
                AmountForMarketing += MFEE;
                AmountForDeveloper += DFEE;
                feeAmount = LFEE.add(MFEE).add(DFEE);
            }     

            if(BFEE > 0) {
                _balances[address(deadAddress)] = _balances[address(deadAddress)].add(BFEE);
                emit Transfer(sender, address(deadAddress), BFEE);
            }

            if(feeAmount > 0) {
                _balances[address(this)] = _balances[address(this)].add(feeAmount);
                emit Transfer(sender, address(this), feeAmount);
            }

            return amount.sub(feeAmount).sub(BFEE);
        }
        
    }

    /*====================================
    |               Setters              |
    ====================================*/

    //To Rescue Stucked Balance
    function withdrawFunds() public onlyOwner { 
        (bool os,) = payable(msg.sender).call{value: address(this).balance}("");
        require(os,"Transaction Failed!!");
    }

    //To Rescue Stucked Tokens
    function withdrawTokens(IERC20 adr,address recipient,uint amount) public onlyOwner {
        adr.transfer(recipient,amount);
    }

    function enableTxLimit(bool _status) public onlyOwner {
        EnableTxLimit = _status;
    }

    function enableWalletLimit(bool _status) public onlyOwner {
        checkWalletLimit = _status;
    }

    function setBuyFee(uint _newLP , uint _newMarket , uint _newDeveloper, uint _newBurn) public onlyOwner { 
        uint subtotal = _newLP.add(_newMarket).add(_newDeveloper).add(_newBurn);
        require(subtotal <= MAX_FEE,"Error: Max Tax 25% Limit Exceeded");
        _buyLiquidityFee = _newLP;
        _buyMarketingFee = _newMarket;
        _buyDeveloperFee = _newDeveloper;
        _buyBurnFee = _newBurn;
    }

    function setSellFee(uint _newLP , uint _newMarket , uint _newDeveloper, uint _newBurn) public onlyOwner {        
        uint subtotal = _newLP.add(_newMarket).add(_newDeveloper).add(_newBurn);
        require(subtotal <= MAX_FEE,"Error: Max Tax 25% Limit Exceeded");
        _sellLiquidityFee = _newLP;
        _sellMarketingFee = _newMarket;
        _sellDeveloperFee = _newDeveloper;
        _sellBurnFee = _newBurn;
    }

    function setMarketingWallets(address _market) public onlyOwner {
        marketingWallet = _market;
    }

    function setDeveloperWallets(address _developer) public onlyOwner {
        developerWallet = _developer;
    }

    function setLiquidityWallets(address _liquidityRec) public onlyOwner {
        liquidityReciever = _liquidityRec;
    }

    function setExcludeFromFee(address _adr,bool _status) public onlyOwner {
        require(isExcludedFromFee[_adr] != _status,"Not Changed!!");
        isExcludedFromFee[_adr] = _status;
    }

    function ExcludeWalletLimit(address _adr,bool _status) public onlyOwner {
        require(isWalletLimitExempt[_adr] != _status,"Not Changed!!");
        isWalletLimitExempt[_adr] = _status;
    }

    function ExcludeTxLimit(address _adr,bool _status) public onlyOwner {
        require(isTxLimitExempt[_adr] != _status,"Not Changed!!");
        isTxLimitExempt[_adr] = _status;
    }

    function setNumTokensBeforeSwap(uint256 newLimit) external onlyOwner() {
        minimumTokensBeforeSwap = newLimit;
    }

    function setMaxWalletLimit(uint256 newLimit) external onlyOwner() {
        _walletMax = newLimit;
    }

    function setTxLimit(uint256 newLimit) external onlyOwner() {
        _maxTxAmount = newLimit;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function changeRouterVersion(address newRouterAddress) public onlyOwner returns(address newPairAddress) {

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(newRouterAddress); 

        newPairAddress = IUniswapV2Factory(_uniswapV2Router.factory()).getPair(address(this), _uniswapV2Router.WETH());

        if(newPairAddress == address(0)) //Create If Doesnt exist
        {
            newPairAddress = IUniswapV2Factory(_uniswapV2Router.factory())
                .createPair(address(this), _uniswapV2Router.WETH());
        }

        uniswapPair = newPairAddress; //Set new pair address
        uniswapV2Router = _uniswapV2Router; //Set new router address

        isMarketPair[address(uniswapPair)] = true;
    }

}