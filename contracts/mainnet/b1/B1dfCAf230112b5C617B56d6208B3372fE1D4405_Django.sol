/**
 *Submitted for verification at Etherscan.io on 2022-04-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
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
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

contract Django is Context, IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = "Django";
    string private constant _symbol = "DJANGO";
    uint8 private constant _decimals = 9;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 private constant totalTokens = 100 * 1e11 * 1e9; 
    uint256 public _maxWalletAmount = 3 * 1e11 * 1e9;
    uint256 public thresholdSwap = 1 * 1e11 * 1e9;
    uint256 public _maxTxAmount = 3 * 1e11 * 1e9;
    uint256 public liqBuys = 0; 
    uint256 public taxBuy = 6; 
    uint256 public liqSells = 6; 
    uint256 public taxSell = 0; 
    uint256 private _previousLiqFee = liqFee;
    uint256 private _previousProjectFee = projectTax;
    uint256 private liqFee;
    uint256 private projectTax;

    struct FeeBreakdown {
        uint256 tLiquidity;
        uint256 tMarketing;
        uint256 tAmount;
    }

    mapping(address => bool) private bots;
    address payable private ProjectWallet = payable(0x24c9500c8da6c935827bc99ddcfC9e12b75881c2);
    address payable private deployWallet = payable(0x69a6235D0b6617BC4EEdaeaF4162F2C8Ce638125);
    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;
    bool private inSwap = false;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), totalTokens);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router),type(uint256).max);
        _balances[_msgSender()] = totalTokens;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[ProjectWallet] = true;
        _isExcludedFromFee[deployWallet] = true;
        _isExcludedFromFee[address(this)] = true;
        emit Transfer(address(0), _msgSender(), totalTokens);
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

    function totalSupply() external pure override returns (uint256) {
        return totalTokens;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender,_msgSender(),_allowances[sender][_msgSender()].sub(amount,"ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function removeAllFee() private {
        if (projectTax == 0 && liqFee == 0) return;
        _previousProjectFee = projectTax;
        _previousLiqFee = liqFee;
        projectTax = 0;
        liqFee = 0;
    }
    
    function restoreAllFee() private {
        liqFee = _previousLiqFee;
        projectTax = _previousProjectFee;
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
        require(amount > 0, "Transfer amount must be greater than zero");

        bool takeFee = !inSwap;

        if(from != owner() && to != owner() && ! _isExcludedFromFee[to] && ! _isExcludedFromFee[from]){
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        if (from != owner() && to != owner() && from != address(this) && to != address(this)) {

            if (from == uniswapV2Pair && to != address(uniswapV2Router)) {
                require(balanceOf(to).add(amount) <= _maxWalletAmount, "wallet balance after transfer must be less than max wallet amount");  
            }

            if (from == uniswapV2Pair && to != address(uniswapV2Router)) {
                liqFee = liqBuys;
                projectTax = taxBuy;
            }
                
            if (to == uniswapV2Pair && from != address(uniswapV2Router)) {
                require(!bots[from] && !bots[to]);
                liqFee = liqSells;
                projectTax = taxSell;
            }
            
            if (!inSwap && from != uniswapV2Pair) {

                uint256 contractTokenBalance = balanceOf(address(this));

                if (contractTokenBalance > thresholdSwap) {
                    swapAndLiquify(contractTokenBalance);
                }

                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
                    
            }
        }

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        
        _tokenTransfer(from, to, amount, takeFee);
        restoreAllFee();
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            deployWallet,
              block.timestamp
          );
    }
  
    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 autoLPamount = liqFee.mul(contractTokenBalance).div(projectTax.add(liqFee));
        uint256 half =  autoLPamount.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(otherHalf);
        uint256 newBalance = ((address(this).balance.sub(initialBalance)).mul(half)).div(otherHalf);
        addLiquidity(half, newBalance);
    }

    function setSwappingThreshold(uint256 _thresholdSwap) external {
        require(_msgSender() == deployWallet);
        thresholdSwap = _thresholdSwap;
    }

    function sendETHToFee(uint256 amount) private {
        ProjectWallet.transfer(amount);
    }

    function manualSwap() external {
        require(_msgSender() == deployWallet);
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance > 0) {
            swapTokensForEth(contractBalance);
        }
    }

    function manualSend() external {
        require(_msgSender() == deployWallet);
        uint256 contractETHBalance = address(this).balance;
        if (contractETHBalance > 0) {
            sendETHToFee(contractETHBalance);
        }
    }

    function blacklist(address _address) external onlyOwner() {
        bots[_address] = true;
    }
    
    function removeFromBlacklist(address _address) external onlyOwner() {
        bots[_address] = false;
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) { 
                removeAllFee();
        }
        _transferStandard(sender, recipient, amount);
        restoreAllFee();
    }

    function MaxTxAmount(uint256 maxTxAmount) external {
        require(_msgSender() == deployWallet);
        require(maxTxAmount > 1 * 1e11 * 1e9);
        _maxTxAmount = maxTxAmount;
    }

    function _transferStandard(address sender, address recipient, uint256 amount) private {
        FeeBreakdown memory fees;
        fees.tMarketing = amount.mul(projectTax).div(100);
        fees.tLiquidity = amount.mul(liqFee).div(100);
        fees.tAmount = amount.sub(fees.tMarketing).sub(fees.tLiquidity);
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(fees.tAmount);
        _balances[address(this)] = _balances[address(this)].add(fees.tMarketing.add(fees.tLiquidity));
        emit Transfer(sender, recipient, fees.tAmount);
    }
    
    receive() external payable {}

    function setMaxWalletAmount(uint256 maxWalletAmount) external {
        require(_msgSender() == deployWallet);
        require(maxWalletAmount > totalTokens.div(200), "Amount must be greater than 0.5% of supply");
        require(maxWalletAmount <= totalTokens, "Amount must be less than or equal to totalSupply");
        _maxWalletAmount = maxWalletAmount;
    }
}