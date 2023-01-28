/**
 *Submitted for verification at Etherscan.io on 2023-01-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


interface IDEXRouter{
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

interface IDEXFactory{
	event PairCreated(address indexed token0, address indexed token1, address pair, uint);
	function getPair(address tokenA, address tokenB) external view returns (address pair);
	function createPair(address tokenA, address tokenB) external returns (address pair);
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

interface IREWARD {
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function claimReward(address shareHolder) external;
}

contract PE is Context, IERC20, Ownable {

    using SafeMath for uint256;

    string private _name = "Platinum Eth";
    string private _symbol = "PE";
    uint8 private _decimals = 18;

    uint256 public buyLiquidityFee = 10;
    uint256 public buyETHFee = 40;

    uint256 public sellLiquidityFee = 0;
    uint256 public sellETHFee = 50;

    uint256 public totalBuy;
    uint256 public totalSell;

    uint256 public feeDenominator = 1000;

    address public liquidityReciever;

    address private constant deadWallet = 0x000000000000000000000000000000000000dEaD;
    address private constant ZeroWallet = 0x0000000000000000000000000000000000000000;

    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isWalletLimitExempt;
    mapping (address => bool) public automatedMarketMakerPairs;
    mapping(address => bool) public isDividendExempt;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;  

    uint256 public _totalSupply = 100_000_000 * (10 ** _decimals);
    uint256 public swapTokensAtAmount = _totalSupply.mul(5).div(1e5); //0.05%

    uint256 public MaxWalletLimit = _totalSupply.mul(15).div(feeDenominator);  //1.5%
    uint256 public MaxTxLimit = _totalSupply.mul(10).div(feeDenominator);      //1%

    bool public EnableTransactionLimit = true;
    bool public checkWalletLimit = true;

    bool public _autoSwapBack = true;

    IREWARD public rewardDividend;
    IDEXRouter public router;
    bool inSwap = false;
    
    modifier validRecipient(address to) {
        require(to != address(0x0));
        _;
    }

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(address _div) {

        rewardDividend = IREWARD(_div);

        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 

        address pair = IDEXFactory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );

        liquidityReciever = msg.sender;

        _allowances[address(this)][address(router)] = ~uint256(0);

        automatedMarketMakerPairs[pair] = true;

        isDividendExempt[msg.sender] = true;
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[deadWallet] = true;
        isDividendExempt[ZeroWallet] = true;

        isWalletLimitExempt[msg.sender] = true;
        isWalletLimitExempt[pair] = true;
        isWalletLimitExempt[address(this)] = true;

        _isExcludedFromFees[msg.sender] = true;
        _isExcludedFromFees[address(this)] = true;

        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[address(this)] = true;

        totalBuy = buyLiquidityFee.add(buyETHFee);
        totalSell = sellLiquidityFee.add(sellETHFee);

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0x0), msg.sender, _totalSupply);
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

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
   
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner_, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner_][spender];
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(_balances[deadWallet]).sub(_balances[ZeroWallet]);
    }

    function isNotInSwap() external view returns (bool) {
        return !inSwap;
    }

    function checkFeeExempt(address _addr) external view returns (bool) {
        return _isExcludedFromFees[_addr];
    }

    function approve(address spender, uint256 value)
        external
        override
        returns (bool)
    {
        _approve(msg.sender,spender,value);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transfer(address to, uint256 value)
        external
        override
        validRecipient(to)
        returns (bool)
    {
        _transferFrom(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override validRecipient(to) returns (bool) {
        
        if (_allowances[from][msg.sender] != ~uint256(0)) {
            _allowances[from][msg.sender] = _allowances[from][
                msg.sender
            ].sub(value, "Insufficient Allowance");
        }
        _transferFrom(from, to, value);
        return true;
    }

    function _basicTransfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount);
        return true;
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {

        if(!isTxLimitExempt[sender] && !isTxLimitExempt[recipient] && EnableTransactionLimit) {
            require(amount <= MaxTxLimit, "Transfer amount exceeds the maxTxAmount.");
        }

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (shouldSwapBack()) {
            swapBack();
        }
        
        _balances[sender] = _balances[sender].sub(amount);
        
        uint256 AmountReceived = shouldTakeFee(sender, recipient)
            ? takeFee(sender, recipient, amount)
            : amount;

        if(checkWalletLimit && !isWalletLimitExempt[recipient]) {
            require(balanceOf(recipient).add(AmountReceived) <= MaxWalletLimit);
        }
        
        _balances[recipient] = _balances[recipient].add(AmountReceived);

        if(!isDividendExempt[sender]){ try rewardDividend.setShare(sender, balanceOf(sender)) {} catch {} }
        if(!isDividendExempt[recipient]){ try rewardDividend.setShare(recipient, balanceOf(recipient)) {} catch {} }

        emit Transfer(sender,recipient,AmountReceived);

        return true;
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 amount
    ) internal  returns (uint256) {

        uint256 feeAmount;
        
        if(automatedMarketMakerPairs[sender]){
            feeAmount = amount.mul(totalBuy).div(feeDenominator);
        }
        else if(automatedMarketMakerPairs[recipient]){
            feeAmount = amount.mul(totalSell).div(feeDenominator);
        }

        if(feeAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        }

        return amount.sub(feeAmount);
    }

    function swapBack() internal swapping {

        uint256 contractBalance = balanceOf(address(this));

        uint totalShares = totalBuy.add(totalSell);

        if(totalShares == 0) return;

        uint _liquidityShare = buyLiquidityFee.add(sellLiquidityFee);
        // uint _EthShare = buyETHFee.add(sellETHFee);

        uint256 tokensForLP = contractBalance.mul(_liquidityShare).div(totalShares).div(2);
        uint256 tokensForSwap = contractBalance.sub(tokensForLP);

        uint initalBalance = address(this).balance;
        swapTokensForEth(tokensForSwap);
        uint amountReceived = address(this).balance.sub(initalBalance);
       
        uint256 totalETHFee = totalShares.sub(_liquidityShare.div(2));

        uint256 amountETHLiquidity = amountReceived.mul(_liquidityShare).div(totalETHFee).div(2);
        uint256 amountETHReward = amountReceived.sub(amountETHLiquidity);

        if(amountETHReward > 0) {
            try rewardDividend.deposit { value: amountETHReward } () {} catch {}             
        }
        if(amountETHLiquidity > 0 && tokensForLP > 0) {
            addLiquidity(tokensForLP, amountETHLiquidity);
        }
    }

    function shouldTakeFee(address from, address to)
        internal
        view
        returns (bool)
    {
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]){
            return false;
        }        
        else{
            return (automatedMarketMakerPairs[from] || automatedMarketMakerPairs[to]);
        }
    }

    function shouldSwapBack() internal view returns (bool) {

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        return
            canSwap &&
            _autoSwapBack &&
            !inSwap &&
            !automatedMarketMakerPairs[msg.sender]; 
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        uint256 oldValue = _allowances[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowances[msg.sender][spender] = 0;
        } else {
            _allowances[msg.sender][spender] = oldValue.sub(
                subtractedValue
            );
        }
        emit Approval(
            msg.sender,
            spender,
            _allowances[msg.sender][spender]
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool)
    {
        _allowances[msg.sender][spender] = _allowances[msg.sender][
            spender
        ].add(addedValue);
        emit Approval(
            msg.sender,
            spender,
            _allowances[msg.sender][spender]
        );
        return true;
    }

    function enableDisableTxLimit(bool _status) external onlyOwner {
        EnableTransactionLimit = _status;
    }

    function enableDisableWalletLimit(bool _status) external onlyOwner {
        checkWalletLimit = _status;
    }

    function setAutoSwapBack(bool _flag) external onlyOwner {
        _autoSwapBack = _flag;
    }

    function setLiquidityWallet(address _newWallet) external onlyOwner {
        liquidityReciever = _newWallet;
    }

    function setMaxWalletLimit(uint _value) external onlyOwner {
        MaxWalletLimit = _value;
    }

    function setMaxTxLimit(uint _value) external onlyOwner {
        MaxTxLimit = _value; 
    }

    function setRewardDividend(address _dividend) external onlyOwner {
        rewardDividend = IREWARD(_dividend); 
    }

    function setBuyFee(
            uint _newLiquidity,
            uint _newReward
        ) external onlyOwner {
        buyLiquidityFee = _newLiquidity;
        buyETHFee = _newReward;
        totalBuy = buyLiquidityFee.add(buyETHFee);
    }

    function setSellFee(
            uint _newLiquidity,
            uint _newReward
        ) external onlyOwner {
        sellLiquidityFee = _newLiquidity;
        sellETHFee = _newReward;
        totalSell = sellLiquidityFee.add(sellETHFee);
    }

    function setAutomaticPairMarket(address _addr,bool _status) external onlyOwner {
        if(_status) {
            require(!automatedMarketMakerPairs[_addr],"Pair Already Set!!");
        }
        automatedMarketMakerPairs[_addr] = _status;
        isWalletLimitExempt[_addr] = true;
        isDividendExempt[_addr] = true;
    }

    function excludeDividend(address _addr,bool _status) external onlyOwner {
        if(_status) {
            rewardDividend.setShare(_addr,0);
        }
        else {
            rewardDividend.setShare(_addr,balanceOf(_addr));
        }
        isDividendExempt[_addr] = _status;
    }   

    function enableFee(address _addr,bool _status) external onlyOwner {
        _isExcludedFromFees[_addr] = _status;
    }

    function enableTxLimit(address _addr,bool _status) external onlyOwner {
        isTxLimitExempt[_addr] = _status;
    }

    function enableWalletLimit(address _addr,bool _status) external onlyOwner {
        isWalletLimitExempt[_addr] = _status;
    }

    function setMinSwapAmount(uint _value) external onlyOwner {
        swapTokensAtAmount = _value;
    }  

    function claimReward() external {
        rewardDividend.claimReward(msg.sender);
    }

    function rescueFunds() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function rescueToken(address _token, uint _value) external onlyOwner {
        IERC20(_token).transfer(msg.sender,_value);
    }
    
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);

        // add the liquidity
        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityReciever,
            block.timestamp
        );
    }

   
    receive() external payable {}

}