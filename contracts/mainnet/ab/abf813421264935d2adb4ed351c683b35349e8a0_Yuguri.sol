/**
 *Submitted for verification at Etherscan.io on 2022-08-14
*/

/*

E̵̞͖͑̾͠v̵̘̺̘̒͠e̵̼͔͊̾̽n̴̦̝̺̔͛͋i̴̻̦̟̽͊̚n̵͖̟̻͒͛̀g̴͍̺͔͊͆͠ M̸̢̺̟̔̈́̈́ḯ̸̡̞͇͛̈́s̵̡̘̙̈́͌̚ẗ̴̫͚̙́͌͠ (̵̡̘́͒͆͜Y̵̫͎̓́͆ū̵̺̐̈́̽͜g̵͓̻̦͐̈́͝í̵̡̻̼̓͆r̴̠͉̟͊͊̾ḯ̸̫͖͇͆̓)̸͖̺̻͋͐͘,̸̢̟͌̈́͌͜
 
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

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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

contract Yuguri is Context, IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = "EveningMist";
    string private constant _symbol = "Yuguri";
    uint8 private constant _decimals = 6;
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 public _tTotal = 1000 * 1e3 * 1e6; //1,000,000

    uint256 public _maxWalletAmount = 20 * 1e3 * 1e6; //2%
    uint256 public swapAmount = 7 * 1e3 * 1e6; //.07%

    // fees
    uint256 public j_liqBuy = 2; 
    uint256 public j_burnBuy = 1; 

    uint256 public j_liqSell = 2; 
    uint256 public j_burnSell = 1; 
    
    uint256 private j_previousLiqFee = j_liqFee;
    uint256 private j_previousBurnFee = j_burnFee;
    uint256 private j_liqFee;
    uint256 private j_burnFee;

    uint256 public _totalBurned;

    struct FeeBreakdown {
        uint256 tLiq;
        uint256 tBurn;
        uint256 tAmount;
    }

    mapping(address => bool) private bots;
    address payable private liqAddress = payable(0xa165774E487C0e35E7529EefDC1C5D3805c29236);

    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;

    bool private swapping = false;
    bool public burnMode = true;

    modifier lockSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[liqAddress] = true;
        _isExcludedFromFee[address(this)] = true;
        emit Transfer(address(0), _msgSender(), _tTotal);
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
        return _tTotal;
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

    function totalBurned() public view returns (uint256) {
        return _totalBurned;
    }

    function burning(address _account, uint _amount) private {  
        require( _amount <= balanceOf(_account));
        _balances[_account] = _balances[_account].sub(_amount);
        _tTotal = _tTotal.sub(_amount);
        _totalBurned = _totalBurned.add(_amount);
        emit Transfer(_account, address(0), _amount);
    }

    function removeAllFee() private {
        if (j_burnFee == 0 && j_liqFee == 0) return;
        j_previousBurnFee = j_burnFee;
        j_previousLiqFee = j_liqFee;

        j_burnFee = 0;
        j_liqFee = 0;
    }
    
    function restoreAllFee() private {
        
        j_liqFee = j_previousLiqFee;
        j_burnFee = j_previousBurnFee;
    }

    function updateFees(uint256 liqSell) external onlyOwner {
        j_liqSell = liqSell;
        
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
        require(!bots[from] && !bots[to]);

        bool takeFee = true;

        if (from != owner() && to != owner() && from != address(this) && to != address(this)) {

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ((!_isExcludedFromFee[from] || !_isExcludedFromFee[to]))) {
                require(balanceOf(to).add(amount) <= _maxWalletAmount, "wallet balance after transfer must be less than max wallet amount");
                
            }

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !bots[to] && !bots[from]) {
                j_liqFee = j_liqBuy;
                j_burnFee = j_burnBuy;
            }
                
            if (to == uniswapV2Pair && from != address(uniswapV2Router) && !bots[to] && !bots[from]) {
                j_liqFee = j_liqSell;
                j_burnFee = j_burnSell;
            }
           
            if (!swapping && from != uniswapV2Pair) {

                uint256 contractTokenBalance = balanceOf(address(this));

                if (contractTokenBalance > swapAmount) {
                    swapAndLiquify(contractTokenBalance);
                }

                //uint256 contractETHBalance = address(this).balance;
                //if (contractETHBalance > 0) {
                //    sendETHToFee(address(this).balance);
                //}
                    
            }
        }

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        
        _transferAgain(from, to, amount, takeFee);
        restoreAllFee();
    }

    function swapTokensForEth(uint256 tokenAmount) private lockSwap {
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
            liqAddress,
            block.timestamp
          );
    }
  
    function swapAndLiquify(uint256 contractTokenBalance) private lockSwap {
        uint256 autoLPamount = j_liqFee.mul(contractTokenBalance).sub(j_burnFee.mul(contractTokenBalance));

        // split the contract balance into halves
        uint256 half =  autoLPamount.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(otherHalf); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = ((address(this).balance.sub(initialBalance)).mul(half)).div(otherHalf);

        addLiquidity(half, newBalance);
    }

    function sendETHToFee(uint256 amount) private {
        liqAddress.transfer(amount);
    }

    function manualSwap() external {
        require(_msgSender() == liqAddress);
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance > 0) {
            swapTokensForEth(contractBalance);
        }
    }

    function manualSend() external {
        require(_msgSender() == liqAddress);
        uint256 contractETHBalance = address(this).balance;
        if (contractETHBalance > 0) {
            sendETHToFee(contractETHBalance);
        }
    }

    function _transferAgain(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) { 
                removeAllFee();
        }
        
    
        FeeBreakdown memory fees;
        fees.tBurn = amount.mul(j_burnFee).div(100);
        fees.tLiq = amount.mul(j_liqFee).div(100);
        
        fees.tAmount = amount.sub(fees.tBurn).sub(fees.tLiq);

        uint256 amountPreBurn = amount.sub(fees.tBurn);
        burning(sender, fees.tBurn);

        _balances[sender] = _balances[sender].sub(amountPreBurn);
        _balances[recipient] = _balances[recipient].add(fees.tAmount);
        _balances[address(this)] = _balances[address(this)].add(fees.tBurn.add(fees.tLiq));
        

        if(burnMode && sender != uniswapV2Pair && sender != address(this) && sender != address(uniswapV2Router) && (recipient == address(uniswapV2Router) || recipient == uniswapV2Pair)) {
            burning(uniswapV2Pair, fees.tBurn);
        }

        emit Transfer(sender, recipient, fees.tAmount);
        restoreAllFee();
    }
    
    receive() external payable {}

    function setMaxWalletAmount(uint256 maxWalletAmount) external {
        require(_msgSender() == liqAddress);
        require(maxWalletAmount > _tTotal.div(200), "Amount must be greater than 0.5% of supply");
        _maxWalletAmount = maxWalletAmount;
    }

    function setSwapAmount(uint256 _swapAmount) external {
        require(_msgSender() == liqAddress);
        swapAmount = _swapAmount;

    }

}