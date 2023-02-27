/**
 *Submitted for verification at Etherscan.io on 2023-02-27
*/

/*

██╗    ██╗███████╗██╗     ██╗     ███╗   ██╗███████╗███████╗███████╗    ██╗███╗   ██╗██╗   ██╗
██║    ██║██╔════╝██║     ██║     ████╗  ██║██╔════╝██╔════╝██╔════╝    ██║████╗  ██║██║   ██║
██║ █╗ ██║█████╗  ██║     ██║     ██╔██╗ ██║█████╗  ███████╗███████╗    ██║██╔██╗ ██║██║   ██║
██║███╗██║██╔══╝  ██║     ██║     ██║╚██╗██║██╔══╝  ╚════██║╚════██║    ██║██║╚██╗██║██║   ██║
╚███╔███╔╝███████╗███████╗███████╗██║ ╚████║███████╗███████║███████║    ██║██║ ╚████║╚██████╔╝

https://www.wellnessinu.app/
Telegram: https://t.me/WellnessInu
Twitter: @WellnessInu 
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }
    modifier onlyOwner() {
        _checkOwner();
        _;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(

        address from,

        address to,

        uint256 amount

    ) external returns (bool);

}

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract ERC20 is Context, IERC20, IERC20Metadata {

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;

    string private _symbol;

    constructor(string memory name_, string memory symbol_) {

        _name = name_;

        _symbol = symbol_;

    }

    function name() public view virtual override returns (string memory) {

        return _name;

    }

    function symbol() public view virtual override returns (string memory) {

        return _symbol;

    }

    function decimals() public view virtual override returns (uint8) {

        return 18;

    }

    function totalSupply() public view virtual override returns (uint256) {

        return _totalSupply;

    }

    function balanceOf(address account) public view virtual override returns (uint256) {

        return _balances[account];

    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {

        address owner = _msgSender();

        transfer(owner, to, amount);

        return true;

    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {

        return _allowances[owner][spender];

    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {

        address owner = _msgSender();

        _approve(owner, spender, amount);

        return true;

    }

    function transferFrom(

        address from,

        address to,

        uint256 amount

    ) public virtual override returns (bool) {

        address spender = _msgSender();

        _spendAllowance(from, spender, amount);

        transfer(from, to, amount);

        return true;

    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {

        address owner = _msgSender();

        _approve(owner, spender, allowance(owner, spender) + addedValue);

        return true;

    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {

        address owner = _msgSender();

        uint256 currentAllowance = allowance(owner, spender);

        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");

        unchecked {

            _approve(owner, spender, currentAllowance - subtractedValue);

        }

        return true;

    }

    function transfer(

        address from,

        address to,

        uint256 amount

    ) internal virtual {

        require(from != address(0), "ERC20: transfer from the zero address");

        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];

        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        unchecked {

            _balances[from] = fromBalance - amount;

            _balances[to] += amount;

        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);

    }

    function _mint(address account, uint256 amount) internal virtual {

        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;

        unchecked {

            _balances[account] += amount;

        }

        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);

    }

    function _burn(address account, uint256 amount) internal virtual {

        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];

        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");

        unchecked {

            _balances[account] = accountBalance - amount;

            _totalSupply -= amount;

        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);

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

    function _spendAllowance(

        address owner,

        address spender,

        uint256 amount

    ) internal virtual {

        uint256 currentAllowance = allowance(owner, spender);

        if (currentAllowance != type(uint256).max) {

            require(currentAllowance >= amount, "ERC20: insufficient allowance");

            unchecked {

                _approve(owner, spender, currentAllowance - amount);

            }

        }

    }

    function _beforeTokenTransfer(

        address from,

        address to,

        uint256 amount

    ) internal virtual {}

    function _afterTokenTransfer(

        address from,

        address to,

        uint256 amount

    ) internal virtual {}

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

    event Mint(address indexed sender, uint amount0, uint amount1);

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

    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;

}
    contract WellnessInu is Context, ERC20, Ownable {
    using SafeMath for uint256; 

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public constant deadAddress = address(0xdead);
    address public devWallet = (0x9DCFD8DdBc2E394e282a007c8f85E90DD0106b68);

    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedMaxTransactionAmount;
    mapping(address => bool) private _bot; 

    bool public limitsInEffect = true;
    bool public tradingOpen = false;
    bool public swapEnabled = false;
    bool private swapping;

    string public constant _name = "Wellness Inu";
    string public constant _symbol = "WNI";
    uint8 constant _decimals = 9;

    uint256 public swapTokensAtAmount;
    uint256 public _maxWalletAmount;
    uint256 public _maxTxAmount;
    uint256 public _buyFee; //10% initial tax, to be decreased to 5%
    uint256 public _sellFee; //20% intial tax, to be decreased to 5%

    uint256 public botPenaltyPeriod;
    uint256 public activeTradingBlock;

    event SwapETHForTokens(uint256 amountIn, address[] path);

    event SwapTokensForETH(uint256 amountIn, address[] path);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );
    
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    
    event excludeFromFees(address _isExcludedFromFees);
    
    event isBot(address indexed _bot);
    
    event removedBot(address indexed notBot);

 constructor() ERC20("Wellness Inu", "WNI") {

    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    uniswapV2Router = _uniswapV2Router;
    uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
    _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

    uint256 totalSupply = (1*1e12)*1e18; //1 Trillion

    _maxWalletAmount = (totalSupply * 5)/1000; //0.5% initial max, to be increased to 1%
    _maxTxAmount = (totalSupply * 5)/1000; //0.5% initial max, to be increased to 1%

    _buyFee = 10;
    _sellFee = 10;

    _isExcludedFromFees[owner()] = true;
    _isExcludedFromFees[address(this)] = true;
    _isExcludedFromFees[devWallet] = true;
    _isExcludedMaxTransactionAmount[owner()] = true;
    _isExcludedMaxTransactionAmount[address(this)] = true;
    _isExcludedMaxTransactionAmount[devWallet] = true;

    _mint(msg.sender, totalSupply);

    swapTokensAtAmount = (totalSupply * 5) / 10000; // 0.05% swap wallet

 }
 receive() external payable {}

    function enableTrading() external onlyOwner {
        tradingOpen = true;
        swapEnabled = true;
        activeTradingBlock = block.number;
        botPenaltyPeriod = block.timestamp + 7000 hours;
    }
    //Emergency use i.e. in case of withdrawing stuck eth
    function updateSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }
    function removeLimits() external onlyOwner returns (bool) {
        limitsInEffect = false;
        return true;
    }
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if(!tradingOpen){
            require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active yet.");
        }
        
        if(limitsInEffect){
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping
            ){
                if(to != uniswapV2Pair) {
                require(balanceOf(to) + amount < _maxWalletAmount, "Balance exceeds max wallet amount!");
            }
                if(from != owner() && to != uniswapV2Pair && block.number == activeTradingBlock){
                    _bot[to] = true;
                    emit isBot(to);
                }
                 if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to] || automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]){
                        require(amount <= _maxTxAmount, "Transfer amount exceeds max.");
                } 
               
            }
        }
        
        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;

            swapping = false;
        }

        bool takeFee = !swapping;
        //No fee on transfers. Bots cannot transfer tokens out except to owner/contract/devWallet
        if ((_isExcludedFromFees[from] || _isExcludedFromFees[to]) || (from != uniswapV2Pair && to != uniswapV2Pair)) {
            require(!_bot[from],"Hey bot, feel free to send your tokens back to contract as you cannot transfer anywhere else.");
            takeFee = false;
        }

        uint256 fees = 0;
       
        if (takeFee) {
            //SELL - increased sell tax for bots
            if (_bot[from] && automatedMarketMakerPairs[to] && botPenaltyPeriod > block.timestamp){
                     fees = amount.mul(_sellFee * 5).div(100);
            }
            else if (automatedMarketMakerPairs[to] && _sellFee > 0) {
                fees = amount.mul(_sellFee).div(100);
            }
            //BUY
            else if (automatedMarketMakerPairs[from] && _buyFee > 0) {
                fees = amount.mul(_buyFee).div(100);
            }
            if (fees > 0) {
                _transfer(from, address(this), fees);
            }

            amount -= fees;
        }

            _transfer(from, to, amount);
    }
    
    function updateSwapTokensAtAmount(uint256 newAmount)
        external
        onlyOwner
        returns (bool)
    {
        require(
            newAmount >= (totalSupply() * 1) / 100000,
            "Swap amount cannot be lower than 0.001% total supply."
        );
        require(
            newAmount <= (totalSupply() * 5) / 1000,
            "Swap amount cannot be higher than 0.5% total supply."
        );
        swapTokensAtAmount = newAmount;
        return true;
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(
            pair != uniswapV2Pair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function removeisBot(address account) external onlyOwner {
        _bot[account] = false;
        emit removedBot(account);
    }

    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFees[account] = true;
        emit excludeFromFees(account);
    }

    function updateFees(
        uint256 UpdatedBuyFee,
        uint256 UpdatedSellFee
    ) external onlyOwner {
        _buyFee = UpdatedBuyFee;
        _sellFee = UpdatedSellFee;
     require((UpdatedBuyFee + UpdatedSellFee) <= 30, "Fees cannot be more than 30%");
    }

    function updateMaxWalletAmount(uint256 newMaxWallet) external onlyOwner {
    _maxWalletAmount = newMaxWallet;
    require(newMaxWallet <= 10, "Max wallet 1%"); //denominator 1000*
    }

    function updateMaxTx(uint256 newMaxTx) external onlyOwner {
      _maxTxAmount = newMaxTx;
     require(newMaxTx <= 10, "Max transacation 1%"); //denominator 1000*
    }
 
    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
  }
  // function to withdraw stuck Eth, max withdrawal amount = maxTxAmount
    function withdrawStuckEth(uint256 amount) external payable onlyOwner {
        require((amount <= _maxTxAmount), "Error");
        payable(msg.sender).transfer(address(this).balance);
}
}