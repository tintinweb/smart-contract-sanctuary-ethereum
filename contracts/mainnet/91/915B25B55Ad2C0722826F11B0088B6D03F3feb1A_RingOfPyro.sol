/**
 *Submitted for verification at Etherscan.io on 2022-08-22
*/

/*
https://t.me/RINGofPYRO
ringofpyro.com
https://twitter.com/ringofpyro

$RING Ring of Pyro - V3
The ⭕️ Burn: Contract X.

1% BURN OF $RING
1% AUTO LP
2% BURN $PYRO
2% BURN "CONTRACT X"
2% MKTG

"CONTRACT X" to be variable to be called at anytime,
subject to community votes,
we burn the token we want and/or subject to fees.
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;
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

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
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

    constructor() {
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
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract RingOfPyro is Context, IERC20, Ownable {
    using SafeMath for uint256;

    uint256 public _totalBurned;
    uint256 public _totalPyroBurned;
    uint256 public _totalContractXBurned;
    address public contractXaddress;
    bool private swapping = false;
    bool public burnMode = false;
    bool public pyroMode = false;
    bool public contractXMode = false;
    bool public liqMode = true;

    address payable public contractXdead = payable(0x000000000000000000000000000000000000dEaD);
    address payable public dead = payable(0x000000000000000000000000000000000000dEaD);
    address public PYRO = 0x89568569DA9C83CB35E59F92f5Df2F6CA829EEeE;
    address public migrator = 0x4f84943645c16DE8007aecAc2B33120191DD3a8d;
    address payable public mktg = payable(0x9C3543BF2d6f46bFdd3a0789628bba6a2B5DA7de);
    address payable public RING = payable(0x858Ff8811Bf1355047f817D09f3e0D800E7054aa);

    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private bots;

    address[] private _excluded;  
    bool public tradingLive = false;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 100000 * 1e9;

    string private _name = "Ring of Pyro";
    string private _symbol = "RING";
    uint8 private _decimals = 9;

    uint256 public j_burnFee = 0; 
    uint256 public _taxes = 8;
    uint256 public j_jeetTax;
    uint256 public jeetBuy = 0;
    uint256 public jeetSell = 0;

    uint256 private _previousBurnFee = j_burnFee;
    uint256 private _previousTaxes = _taxes;
    uint256 private j_previousJeetTax = j_jeetTax;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    
    uint256 public j_maxtxn;
    uint256 public _maxWalletAmount;
    uint256 public swapAmount = 70 * 1e9;

    uint256 liqDivisor = 8;  
    uint256 pyroDivisor = 4; 
    uint256 contractXDivisor = 4; 
    
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor () {
        _tOwned[address(RING)] = _tTotal;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[RING] = true;
        _isExcludedFromFee[mktg] = true;
        _isExcludedFromFee[dead] = true;
        _isExcludedFromFee[migrator] = true;
        _isExcludedFromFee[address(this)] = true;
        emit Transfer(address(0), address(RING), _tTotal);
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
        return _tTotal;
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

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function totalBurned() public view returns (uint256) {
        return _totalBurned;
    }

    function burning(address _sender, uint tokensToBurn) private {  
        require( tokensToBurn <= balanceOf(_sender));
        _tOwned[_sender] = _tOwned[_sender].sub(tokensToBurn);
        _tTotal = _tTotal.sub(tokensToBurn);
        _totalBurned = _totalBurned.add(tokensToBurn);
        emit Transfer(_sender, address(0), tokensToBurn);
    }     
    
    function excludeFromFee(address account) external {
        require(_msgSender() == RING);
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) external {
        require(_msgSender() == RING);
        _isExcludedFromFee[account] = false;
    }
       
    function setMaxTxAmount(uint256 maxTxAmount) external {
        require(_msgSender() == RING);
        j_maxtxn = maxTxAmount * 1e9;
    }

    function setMaxWallet(uint256 maxWallet) external {
        require(_msgSender() == RING);
        _maxWalletAmount = maxWallet * 1e9;
    }
    
    function setSwapThresholdAmount(uint256 SwapThresholdAmount) external {
        require(_msgSender() == RING);
        swapAmount = SwapThresholdAmount * 1e9;
    }
    
    function claimETH (address walletaddress) external {
        require(_msgSender() == RING);
        payable(walletaddress).transfer(address(this).balance);
    }

    function claimAltTokens(IERC20 tokenAddress, address walletaddress) external {
        require(_msgSender() == RING);
        tokenAddress.transfer(walletaddress, tokenAddress.balanceOf(address(this)));
    }
    
    function clearStuckBalance (address payable walletaddress) external {
        require(_msgSender() == RING);
        walletaddress.transfer(address(this).balance);
    }
    
    function blacklist (address _address) external {
        require(_msgSender() == RING);
        bots[_address] = true;
    }
    
    function removeFromBlacklist (address _address) external {
        require(_msgSender() == RING);
        bots[_address] = false;
    }
    
    function getIsBlacklistedStatus (address _address) external view returns (bool) {
        return bots[_address];
    }
    
    function allowTrades() external onlyOwner {
        require(!tradingLive,"trading is already open");
        _maxWalletAmount = 2000 * 1e9; //2%
        j_maxtxn = 2000 * 1e9; //2% 
        tradingLive = true;
        contractXaddress = (0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE);
    }

    function setSwapAndLiquifyEnabled (bool _enabled) external {
        require(_msgSender() == RING);
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}
    
    function removeAllFee() private {
        if(j_burnFee == 0 && _taxes == 0) return;
        
        _previousBurnFee = j_burnFee;
        _previousTaxes = _taxes;
        
        j_burnFee = 0;
        _taxes = 0;
    }
    
    function restoreAllFee() private {
        j_burnFee = _previousBurnFee;
        _taxes = _previousTaxes;
    }
    
    function isExcludedFromFee (address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (from != owner() && to != owner() && from != address(this) && to != address(this)) {
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ((!_isExcludedFromFee[from] || !_isExcludedFromFee[to]))) {
                require(balanceOf(to).add(amount) <= _maxWalletAmount, "You are being greedy. Exceeding Max Wallet.");
                require(amount <= j_maxtxn, "Slow down buddy...there is a max transaction");
            }
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !bots[to] && !bots[from]) {
                j_burnFee;
                _taxes;
                j_jeetTax = jeetBuy;
            }
                
            if (to == uniswapV2Pair && from != address(uniswapV2Router) && !bots[to] && !bots[from]) {
                j_burnFee;
                _taxes;
                j_jeetTax = jeetSell;
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));        
        if(contractTokenBalance >= j_maxtxn){
            contractTokenBalance = j_maxtxn;
        }
        
        bool overMinTokenBalance = contractTokenBalance >= swapAmount;
        if (overMinTokenBalance && !inSwapAndLiquify && from != uniswapV2Pair && swapAndLiquifyEnabled) {
            contractTokenBalance = swapAmount;
            swapAndLiquify(contractTokenBalance);
        }

        bool takeFee = true;        
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        
        _transferAgain(from,to,amount,takeFee);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 tokensForLiq = (contractTokenBalance.div(liqDivisor));
        uint256 restOfTokens = (contractTokenBalance.sub(tokensForLiq));
        uint256 tokensForPyro = (contractTokenBalance.div(pyroDivisor));
        uint256 tokensForContractX = (contractTokenBalance.div(contractXDivisor));

        if (pyroMode && tokensForPyro > 0) {
            exchangeForPyro(tokensForPyro);
        }

        if (contractXMode && tokensForContractX > 0) {
            exchangeForContractX(tokensForContractX);
        }

        uint256 half = tokensForLiq.div(2);
        uint256 otherHalf = tokensForLiq.sub(half);
        uint256 initialETHBalance = address(this).balance;
        swapTokensForEth(half);
        uint256 newBalance = address(this).balance.sub(initialETHBalance);
        if (liqMode) {
            addLiquidity(otherHalf, newBalance);
        }

        uint256 nextBalance = address(this).balance;
        swapTokensForEth(restOfTokens);
        uint256 newestBalance = address(this).balance.sub(nextBalance);
        
        sendETHToFee(newestBalance);   
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
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
            address(this),
            block.timestamp
        );
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
            RING,
            block.timestamp
        );
    }       
        
    function _transferAgain(address sender, address recipient, uint256 amount, bool takeFee) private {
        require(!bots[sender] && !bots[recipient]);
        if(!tradingLive){
            require(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient], "Trading is not active yet.");
        } 

        if (!takeFee) { 
                removeAllFee();
        }
        
        uint256 tokensToBurn = amount.mul(j_burnFee).div(100);
        uint256 totalTaxTokens = amount.mul(_taxes.add(j_jeetTax)).div(100);

        uint256 tokensToTransfer = amount.sub(totalTaxTokens.add(tokensToBurn));

        uint256 amountPreBurn = amount.sub(tokensToBurn);
        if (burnMode) {
        burning(sender, tokensToBurn);
        }
        
        _tOwned[sender] = _tOwned[sender].sub(amountPreBurn);
        _tOwned[recipient] = _tOwned[recipient].add(tokensToTransfer);
        _tOwned[address(this)] = _tOwned[address(this)].add(totalTaxTokens);
        
        if(burnMode && sender != uniswapV2Pair && sender != address(this) && sender != address(uniswapV2Router) && (recipient == address(uniswapV2Router) || recipient == uniswapV2Pair)) {
            burning(uniswapV2Pair, tokensToBurn);
        }
        
        emit Transfer(sender, recipient, tokensToTransfer);
        if (totalTaxTokens > 0) {
            emit Transfer(sender, address(this), totalTaxTokens);
        }
        restoreAllFee();
    }

    //this is the last step down from the jeet taxes going to normal
    function beginJeetOne() external {
        require(_msgSender() == RING);
        jeetSell = 8;
    }

    //the first step down from jeet taxes
    function beginJeetTwo() external {
        require(_msgSender() == RING);
        contractXMode = true;
        pyroMode = true;
        burnMode = true;
        j_burnFee = 1;
        _taxes = 7;
        jeetSell = 0;
    }

    function exchangeForPyro(uint256 amount) private {
    	if (amount > 0) {
    	    swapRingForPyro(amount);
            _totalPyroBurned = _totalPyroBurned.add(amount);
	    }
    }

    function exchangeForContractX(uint256 amount) private {
    	if (amount > 0) {
    	    swapRingForContractX(amount);
            _totalContractXBurned = _totalContractXBurned.add(amount);
	    }
    }

    function enablePYRO(bool enabled) external {
        pyroMode = enabled;
        require(_msgSender() == RING);
    }

    function enableContractX(bool enabled) external {
        contractXMode = enabled;
        require(_msgSender() == RING);
    }

    function enableBurnMode(bool enabled) external {
        require(_msgSender() == RING);
        burnMode = enabled;
    }
    
    function enableLiqMode(bool enabled) external {
        require(_msgSender() == RING);
        liqMode = enabled;
    }

    function manualSwap() external {
        require(_msgSender() == RING);
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance > 0) {
            swapTokensForEth(contractBalance);
        }
    }

    function manualSend() external {
        require(_msgSender() == RING);
        uint256 contractETHBalance = address(this).balance;
        if (contractETHBalance > 0) {
            sendETHToFee(contractETHBalance);
        }
    }

    function sendETHToFee(uint256 amount) private {
        uint256 transferAmt = amount.div(2);
        RING.transfer(transferAmt);
        mktg.transfer(amount.sub(transferAmt));
    }   

    function swapRingForContractX(uint256 tokenAmount) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = address(contractXaddress);

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of Tokens
            path,
            contractXdead, // Burn address
            block.timestamp
        );
    }

    function swapRingForPyro(uint256 tokenAmount) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = address(PYRO);

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of Tokens
            path,
            dead, // Burn address
            block.timestamp
        );
    }

    function setContractXaddress(address payable walletAddress, address payable walletDeadAddress) external {
        require(_msgSender() == RING);
        contractXaddress = walletAddress;
        contractXdead = walletDeadAddress;
    }
    
    function setPyroAddress(address payable walletAddress, address payable walletDeadAddress) external {
        require(_msgSender() == RING);
        PYRO = walletAddress;
        dead = walletDeadAddress;
    }

    function setMktg(address payable _address) external {
        require(_msgSender() == RING || _msgSender() == mktg);
        mktg = _address;
    }

    function changeContractX(address payable j_dead, address addressOfContractX) external {
        require(_msgSender() == RING);
        contractXaddress = addressOfContractX;
        contractXdead = j_dead;
    }
    
    function changePYRO(address payable j_dead, address PYROaddress) external {
        require(_msgSender() == RING);
        PYRO = PYROaddress;
        dead = j_dead;
    }

    function changeTax(uint256 burn, uint256 jeetbuy, uint256 jeetsell, uint256 taxes, uint256 _liqDivisor, uint256 _pyroDivide, uint256 _contractXDivide) external {
        require(_msgSender() == RING);
        j_burnFee = burn;
        jeetBuy = jeetbuy;
        jeetSell = jeetsell;
        _taxes = taxes;
        liqDivisor = _liqDivisor;
        pyroDivisor = _pyroDivide;
        contractXDivisor = _contractXDivide;
    }

    function airdrop(address recipient, uint256 amount) external {
        require(_msgSender() == RING);

        removeAllFee();
        _transfer(_msgSender(), recipient, amount * 10**9);
        restoreAllFee();
    }
    
    function airdropInternal(address recipient, uint256 amount) internal {
        removeAllFee();
        _transfer(_msgSender(), recipient, amount);
        restoreAllFee();
    }
    
    function airdropArray(address[] calldata newholders, uint256[] calldata amounts) external {
        require(_msgSender() == RING);

        uint256 iterator = 0;
        require(newholders.length == amounts.length, "must be the same length");
        while(iterator < newholders.length){
            airdropInternal(newholders[iterator], amounts[iterator] * 10**9);
            iterator += 1;
        }
    }
}