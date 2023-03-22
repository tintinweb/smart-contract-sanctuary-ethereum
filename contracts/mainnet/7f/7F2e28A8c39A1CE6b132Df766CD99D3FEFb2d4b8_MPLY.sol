/**
 *Submitted for verification at Etherscan.io on 2023-03-21
*/

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.10;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address _account) external view returns (uint256);
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any _account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IUniSwapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniSwapPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniSwapRouter {
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
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract MPLY is Context, IERC20, Ownable {

    using SafeMath for uint256;

    string private _name = "Moonopoly"; // token name
    string private _symbol = "MPLY"; // token ticker
    uint8 private _decimals = 18; // token decimals

    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;
    address public immutable zeroAddress = 0x0000000000000000000000000000000000000000;

    uint256 _buyLiquidityFee = 3;
    uint256 _buyMarketingFee = 2;

    uint256 _sellLiquidityFee = 8;
    uint256 _sellMarketingFee = 8;

    uint256 public totalBuyFee;
    uint256 public totalSellFee;

    address public marketingWallet = address(0xc372f1f1299eeD2225f27d12D499608654e1f245);
    address public liquidityReciever = address(0x9eeFC7E6f44970FfFc4CD140f0afd2c8Ee4CB73E);
    address private FundsRescueWallet;
    
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) public isExcludedFromFee;
    mapping (address => bool) public isMarketPair;
    mapping (address => bool) public isWalletLimitExempt;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isBot;

    uint256 private _totalSupply = 50_000_000 * 10**_decimals;

    uint256 denominator = 100;

    uint256 public minimumTokensBeforeSwap = 30_000 * 10**_decimals;
    uint256 public _maxTxAmount =  _totalSupply.mul(1).div(denominator);     //1%
    uint256 public _walletMax = _totalSupply.mul(1).div(denominator);    //1%

    bool public transferFeeEnabled = true;
    uint256 public initalTransferFee = 99; // 99% max fees limit on inital transfer
    uint256 public launchedAt; 
    uint256 public snipingTime = 60 seconds; //1 min snipping time
    bool public trading; 

    bool public EnableTxLimit = true;
    bool public checkWalletLimit = true;

    event SwapAndLiquifyEnabledUpdated(bool enabled);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );

    modifier onlyGuard() {
        require(msg.sender == FundsRescueWallet,"Error: Guarded!");
        _;
    }

    IUniSwapRouter public uniswapRouter;
    address public uniswapPair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() {

        // //uniswap Swap
        IUniSwapRouter _dexRouter = IUniSwapRouter(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        uniswapPair = IUniSwapFactory(_dexRouter.factory()).createPair(
            address(this),
            _dexRouter.WETH()
        );

        uniswapRouter = _dexRouter;

        _allowances[address(this)][address(uniswapRouter)] = ~uint256(0);

        FundsRescueWallet = msg.sender;

        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[msg.sender] = true;
        isExcludedFromFee[address(uniswapRouter)] = true;

        isWalletLimitExempt[msg.sender] = true;
        isWalletLimitExempt[address(uniswapPair)] = true;
        isWalletLimitExempt[address(uniswapRouter)] = true;
        isWalletLimitExempt[address(this)] = true;
        
        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[address(uniswapRouter)] = true;

        isMarketPair[address(uniswapPair)] = true;

        totalBuyFee = _buyLiquidityFee.add(_buyMarketingFee);
        totalSellFee = _sellLiquidityFee.add(_sellMarketingFee);

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
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
    
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(deadAddress)).sub(balanceOf(zeroAddress));
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
        
        require(!isBot[sender], "ERC20: Bot detected");
        require(!isBot[msg.sender], "ERC20: Bot detected");
        require(!isBot[tx.origin], "ERC20: Bot detected");

        if(inSwapAndLiquify) {
            return _basicTransfer(sender, recipient, amount);
        }
        else {

            if (!isExcludedFromFee[sender] && !isExcludedFromFee[recipient]) {
                require(trading, "ERC20: trading not enable yet");

                if (
                    block.timestamp < launchedAt + snipingTime &&
                    sender != address(uniswapRouter)
                ) {
                    if (uniswapPair == sender) {
                        isBot[recipient] = true;
                    } else if (uniswapPair == recipient) {
                        isBot[sender] = true;
                    }
                }
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;
            
            if (overMinimumTokenBalance && !inSwapAndLiquify && !isMarketPair[sender] && swapAndLiquifyEnabled) 
            {
                swapAndLiquify(contractTokenBalance);
            }

            if(!isTxLimitExempt[sender] && !isTxLimitExempt[recipient] && EnableTxLimit) {
                require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            } 
            
            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

            uint256 finalAmount = shouldNotTakeFee(sender,recipient) ? amount : takeFee(sender, recipient, amount);

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
    
    function shouldNotTakeFee(address sender, address recipient) internal view returns (bool) {
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

        unchecked {

            if(isMarketPair[sender]) { //buy
                feeAmount = amount.mul(totalBuyFee).div(denominator);
            } 
            else if(isMarketPair[recipient]) { //sell
                feeAmount = amount.mul(totalSellFee).div(denominator);
            }
            else {
                if(transferFeeEnabled) {
                    feeAmount = amount.mul(initalTransferFee).div(denominator);
                }
            }

            if(feeAmount > 0) {
                _balances[address(this)] = _balances[address(this)].add(feeAmount);
                emit Transfer(sender, address(this), feeAmount);
            }

            return amount.sub(feeAmount);
        }
        
    }

    function swapAndLiquify(uint contractBalance) private lockTheSwap {

        uint256 totalShares = totalBuyFee.add(totalSellFee);

        if(totalShares == 0) return;

        uint256 _liquidityShare = _buyLiquidityFee.add(_sellLiquidityFee);
        // uint256 _MarketingShare = _buyMarketingFee.add(_sellMarketingFee);

        uint256 tokensForLP = contractBalance.mul(_liquidityShare).div(totalShares).div(2);
        uint256 tokensForSwap = contractBalance.sub(tokensForLP);

        uint256 initialBalance = address(this).balance;
        swapTokensForEth(tokensForSwap);
        uint256 amountReceived = address(this).balance.sub(initialBalance);

        uint256 totalETHFee = totalShares.sub(_liquidityShare.div(2));
        
        uint256 amountETHLiquidity = amountReceived.mul(_liquidityShare).div(totalETHFee).div(2);
        uint256 amountETHMarketing = amountReceived.sub(amountETHLiquidity);

        if(amountETHMarketing > 0)
            payable(marketingWallet).transfer(amountETHMarketing);

        if(amountETHLiquidity > 0 && tokensForLP > 0)
            addLiquidity(tokensForLP, amountETHLiquidity);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();

        _approve(address(this), address(uniswapRouter), tokenAmount);

        // make the swap
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
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
        _approve(address(this), address(uniswapRouter), tokenAmount);

        // add the liquidity
        uniswapRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityReciever,
            block.timestamp
        );
    }

    function enableSwapAndLiquifiy(bool _status) external onlyOwner {
        swapAndLiquifyEnabled = _status;
        emit SwapAndLiquifyEnabledUpdated(_status);
    }

    function setSwapThreshold(uint _newLimit) external onlyOwner {
        minimumTokensBeforeSwap = _newLimit;
    }

    function setBuyFee(uint _newLp, uint _newMarketing) external onlyOwner {
        _buyLiquidityFee = _newLp;
        _buyMarketingFee = _newMarketing;
        totalBuyFee = _buyLiquidityFee.add(_buyMarketingFee);
    }

    function setSellFee(uint _newLp, uint _newMarketing) external onlyOwner {
        _sellLiquidityFee = _newLp;
        _sellMarketingFee = _newMarketing;
        totalSellFee = _sellLiquidityFee.add(_sellMarketingFee);
    }

    function setMarketingWl(address _newWl) external onlyOwner {
        marketingWallet = _newWl;
    }

    function setLiquidityWl(address _newWl) external onlyOwner {
        liquidityReciever = _newWl;
    }

    function startTrading() external onlyOwner {
        require(!trading, "ERC20: Already Enabled");
        trading = true;
        launchedAt = block.timestamp;
    }

    //To Rescue Stucked Balance
    function rescueFunds() external onlyGuard { 
        (bool os,) = payable(msg.sender).call{value: address(this).balance}("");
        require(os,"Transaction Failed!!");
    }

    //To Rescue Stucked Tokens
    function rescueTokens(IERC20 adr,address recipient,uint amount) external onlyGuard {
        adr.transfer(recipient,amount);
    }

    function addOrRemoveBots(address[] calldata accounts, bool value)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            isBot[accounts[i]] = value;
        }
    }

    function disableTransferFee(bool _status) external onlyOwner {
        transferFeeEnabled = _status;
    }

    function enableTxLimit(bool _status) external onlyOwner {
        EnableTxLimit = _status;
    }

    function enableWalletLimit(bool _status) external onlyOwner {
        checkWalletLimit = _status;
    }

    function excludeFromFee(address _adr,bool _status) external onlyOwner {
        isExcludedFromFee[_adr] = _status;
    }

    function excludeWalletLimit(address _adr,bool _status) external onlyOwner {
        isWalletLimitExempt[_adr] = _status;
    }

    function excludeTxLimit(address _adr,bool _status) external onlyOwner {
        isTxLimitExempt[_adr] = _status;
    }

    function setMaxWalletLimit(uint256 newLimit) external onlyOwner() {
        _walletMax = newLimit;
    }

    function setTxLimit(uint256 newLimit) external onlyOwner() {
        _maxTxAmount = newLimit;
    }

    function setMarketPair(address _pair, bool _status) external onlyOwner {
        isMarketPair[_pair] = _status;
    }

    function setRouter(address _newRouter) external onlyOwner {
        uniswapRouter = IUniSwapRouter(_newRouter);
    }

}