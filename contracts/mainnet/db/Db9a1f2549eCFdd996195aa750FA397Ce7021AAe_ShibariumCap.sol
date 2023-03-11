/**
 *Submitted for verification at Etherscan.io on 2023-03-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
    WEBSITE: https://shibariumcap.com
    TELEGRAM: https://t.me/ShibariumCap

    We are going to be the first Shibarium Token Tracker in the market!
 ________  ___  ___  ___  ________  ________  ________  ___  ___  ___  _____ ______      
|\   ____\|\  \|\  \|\  \|\   __  \|\   __  \|\   __  \|\  \|\  \|\  \|\   _ \  _   \    
\ \  \___|\ \  \\\  \ \  \ \  \|\ /\ \  \|\  \ \  \|\  \ \  \ \  \\\  \ \  \\\__\ \  \   
 \ \_____  \ \   __  \ \  \ \   __  \ \   __  \ \   _  _\ \  \ \  \\\  \ \  \\|__| \  \  
  \|____|\  \ \  \ \  \ \  \ \  \|\  \ \  \ \  \ \  \\  \\ \  \ \  \\\  \ \  \    \ \  \ 
    ____\_\  \ \__\ \__\ \__\ \_______\ \__\ \__\ \__\\ _\\ \__\ \_______\ \__\    \ \__\
   |\_________\|__|\|__|\|__|\|_______|\|__|\|__|\|__|\|__|\|__|\|_______|\|__|     \|__|
   \|_________|                                                                          
                                                                                         
                                                                                         
                 ________  ________  ________                                            
                |\   ____\|\   __  \|\   __  \                                           
                \ \  \___|\ \  \|\  \ \  \|\  \                                          
                 \ \  \    \ \   __  \ \   ____\                                         
                  \ \  \____\ \  \ \  \ \  \___|                                         
                   \ \_______\ \__\ \__\ \__\                                            
                    \|_______|\|__|\|__|\|__|    
*/

abstract contract Context {

    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

     /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
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

interface IUniswapV2Router01 {
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
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

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

contract ShibariumCap is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    string private _name = "ShibariumCap";
    string private _symbol = "SHIBCAP";
    uint8 private _decimals = 18;

    address public marketingWallet;
    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;
    
    mapping (address => bool) public isExcludedFromFee;
    mapping (address => bool) public isWalletLimitExempt;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isAutomatedMarketPair;

    // initial tax 25%, goes down to 3% a minute after launch & then renounce
    uint256 public _marketingFeeBuy = 3;
    uint256 public _burnFeeBuy = 0;
    uint256 public _totalTaxBuy = 3;

    uint256 public _marketingFeeSell = 2;
    uint256 public _burnFeeSell = 1;
    uint256 public _totalTaxSell = 3;

    uint256 private _totalSupply = 250_000 * 10**18;
    uint256 public _maxTxAmount = 7_500 * 10**18;
    uint256 public _walletMax = 7_500 * 10**18;
    uint256 private minimumTokensBeforeSwap = 500 * 10**18; 
    uint256 public _burnGoal = 125_000 * 10**18;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    
    bool inSwapAndLiquify;
    
    event SwapETHForTokens(
        uint256 amountIn,
        address[] path
    );
    
    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );
    
    constructor (address _marketingWallet) {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        _allowances[address(this)][address(uniswapV2Router)] = _totalSupply;

        marketingWallet = _marketingWallet;

        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[marketingWallet] = true;
        isExcludedFromFee[deadAddress] = true;

        isWalletLimitExempt[owner()] = true;
        isWalletLimitExempt[address(uniswapV2Pair)] = true;
        isWalletLimitExempt[address(_uniswapV2Router)] = true;
        isWalletLimitExempt[address(this)] = true;
        isWalletLimitExempt[marketingWallet] = true;
        
        isTxLimitExempt[owner()] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[address(_uniswapV2Router)] = true;
        isTxLimitExempt[marketingWallet] = true;

        isAutomatedMarketPair[address(uniswapV2Pair)] = true;

        _balances[_msgSender()] = _totalSupply;
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

    function setTax(uint256 burnBuy, uint256 marketingBuy, uint256 burnSell, uint256 marketingSell) external onlyOwner {
        require(burnBuy + marketingBuy <= 25 && burnSell + marketingSell <= 25);

        _burnFeeBuy = burnBuy;
        _marketingFeeBuy = marketingBuy;
        _totalTaxBuy = burnBuy + marketingBuy;

        _burnFeeSell = burnSell;
        _marketingFeeSell = marketingSell;
        _totalTaxSell = burnSell + marketingSell;
    }

    function setMarketingWallet(address _marketingWallet) external onlyOwner {
        marketingWallet = _marketingWallet;
    }

    function transferToAddressETH(address recipient, uint256 amount) private {
        payable(recipient).transfer(amount);
    }

    function excludeFromFee(address account, bool flag) external onlyOwner {
        isExcludedFromFee[account] = flag;
    }

    function excludeFromMaxWallet(address account, bool flag) external onlyOwner {
        isWalletLimitExempt[account] = flag;
    }

    function excludeFromMaxTx(address account, bool flag) external onlyOwner {
        isTxLimitExempt[account] = flag;
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

        if(recipient == deadAddress)
            if (_burnGoal >= amount)
                _burnGoal = _burnGoal.sub(amount);
            else
                _burnGoal = 0;

        if (inSwapAndLiquify || isExcludedFromFee[sender] || isExcludedFromFee[recipient])
        {
            return _basicTransfer(sender, recipient, amount); 
        }
        else
        {
            if(!isTxLimitExempt[sender] && !isTxLimitExempt[recipient]) {
                require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            }            

            uint256 contractTokenBalance = balanceOf(address(this));
            bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;
            
            if (overMinimumTokenBalance && !isAutomatedMarketPair[sender] && !isAutomatedMarketPair[msg.sender] && (sender != uniswapV2Pair && recipient != address(uniswapV2Router))) 
            {
                if (contractTokenBalance > minimumTokensBeforeSwap.mul(5))
                {
                    contractTokenBalance = minimumTokensBeforeSwap.mul(5);
                }

                inSwapAndLiquify = true;
                swapAndLiquify(contractTokenBalance);
                inSwapAndLiquify = false;
            }

            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

            uint256 feeAmount = 0;
            uint256 burnFee = 0;
        
            if(isAutomatedMarketPair[sender] || isAutomatedMarketPair[recipient]) {
                if (isAutomatedMarketPair[recipient]) {
                    feeAmount = amount.mul(_totalTaxSell).div(100);
                    burnFee = feeAmount.mul(_burnFeeSell).div(_totalTaxSell);
                }
                else {
                    feeAmount = amount.mul(_totalTaxBuy).div(100);
                    burnFee = feeAmount.mul(_burnFeeBuy).div(_totalTaxBuy);
                }
            }

            _burnGoal = _burnGoal.sub(burnFee);

            uint256 marketingFee = feeAmount.sub(burnFee);
            
            if(burnFee > 0) {
                _balances[deadAddress] = _balances[deadAddress].add(burnFee);
                emit Transfer(sender, deadAddress, burnFee);
            }

            if(marketingFee > 0) {
                _balances[address(this)] = _balances[address(this)].add(marketingFee);
                emit Transfer(sender, address(this), marketingFee);
            }

            uint256 finalAmount = amount.sub(feeAmount);

            if(!isWalletLimitExempt[recipient])
                require(balanceOf(recipient).add(finalAmount) <= _walletMax);

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

    function swapAndLiquify(uint256 tAmount) private {
        uint256 tokensForSwap = tAmount;

        swapTokensForEth(tokensForSwap);
        uint256 amountBNBMarketing = address(this).balance;

        if(amountBNBMarketing > 0)
            transferToAddressETH(marketingWallet, amountBNBMarketing);
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
}