/**
 *Submitted for verification at Etherscan.io on 2022-12-20
*/

/*
https://www.soulfiretoken.com/

https://t.me/SoulFireToken
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

library Address {
        
    function isContract(address account) internal view returns (bool) {
        
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
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

contract SoulFire is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    string private constant _name = "Soul Fire";
    string private constant _symbol = "SOUL";
    uint8 private constant _decimals = 6;
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 public _tTotal = 1000 * 1e3 * 1e6; //1,000,000

    uint256 public _maxWalletAmount = 20 * 1e3 * 1e6; //2%
    uint256 public j_maxtxn = 20 * 1e3 * 1e6; //2%
    uint256 public swapAmount = 7 * 1e2 * 1e6; //.07%
    uint256 private buyTyrantUpperLimit = 100 * 1e14; // 0.01

    // fees
    uint256 public j_liqBuy = 0; 
    uint256 public j_burnBuy = 0;
    uint256 public j_tyrantBuy = 3;
    uint256 public j_marketingBuy = 9;

    uint256 public j_liqSell = 0; 
    uint256 public j_burnSell = 0;
    uint256 public j_tyrantSell = 3;
    uint256 public j_marketingSell = 22;
 
    uint256 private j_previousLiqFee = j_liqFee;
    uint256 private j_previousBurnFee = j_burnFee;
    uint256 private j_previousTyrantFee = j_tyrantFee;
    uint256 private j_previousMarketingTax = j_marketingTax;
    
    uint256 private j_liqFee;
    uint256 private j_burnFee;
    uint256 private j_tyrantFee;
    uint256 private j_marketingTax;

    uint256 public _totalBurned;

    struct FeeBreakdown {
        uint256 tLiq;
        uint256 tBurn;
        uint256 tTyrant;
        uint256 tMarketing;
        uint256 tAmount;
    }

    mapping(address => bool) private bots;
    address payable private soulfireWallet = payable(0x58d8AA2C17a0C046E4fCa7e4b8Ac6245293D4802);
    address payable public dead = payable(0x000000000000000000000000000000000000dEaD);
    address TYRANT = 0x8EE325AE3E54e83956eF2d5952d3C8Bc1fa6ec27;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private swapping = false;
    bool public burnMode = false;

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
        _isExcludedFromFee[soulfireWallet] = true;
        _isExcludedFromFee[dead] = true;
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
        if (j_burnFee == 0 && j_liqFee == 0 && j_tyrantFee == 0 && j_marketingTax == 0) return;
        j_previousBurnFee = j_burnFee;
        j_previousLiqFee = j_liqFee;
        j_previousTyrantFee = j_tyrantFee;
        j_previousMarketingTax = j_marketingTax;

        j_burnFee = 0;
        j_liqFee = 0;
        j_tyrantFee = 0;
        j_marketingTax = 0;
    }
    
    function restoreAllFee() private {
        j_liqFee = j_previousLiqFee;
        j_burnFee = j_previousBurnFee;
        j_tyrantFee = j_previousTyrantFee;
        j_marketingTax = j_previousMarketingTax;
    }

    function reduceMarketingTax() external {
        require(_msgSender() == soulfireWallet);
        j_marketingSell = 3;
        j_marketingBuy = 3;
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
                require(balanceOf(to).add(amount) <= _maxWalletAmount, "You are being greedy. Exceeding Max Wallet.");
                require(amount <= j_maxtxn, "Slow down buddy...there is a max transaction");
            }

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !bots[to] && !bots[from]) {
                j_liqFee = j_liqBuy;
                j_burnFee = j_burnBuy;
                j_tyrantFee = j_tyrantBuy;
                j_marketingTax = j_marketingBuy;
            }
                
            if (to == uniswapV2Pair && from != address(uniswapV2Router) && !bots[to] && !bots[from]) {
                j_liqFee = j_liqSell;
                j_burnFee = j_burnSell;
                j_tyrantFee = j_tyrantSell;
                j_marketingTax = j_marketingSell;
            }
           
            if (!swapping && from != uniswapV2Pair) {

                uint256 contractTokenBalance = balanceOf(address(this));

                if (contractTokenBalance > swapAmount) {
                    swapAndLiquify(contractTokenBalance);
                }

                uint256 contractETHBalance = address(this).balance;
            
                if (!burnMode && (contractETHBalance > 0)) {
                    sendETHToFee(address(this).balance);
                } else if (burnMode && (contractETHBalance > buyTyrantUpperLimit)) {
                        uint256 buyAmount = (contractETHBalance.div(2));
                    buyTyrant(buyAmount);
                }                    
            }
        }

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        
        _transferAgain(from, to, amount, takeFee);
        restoreAllFee();
    }

    function setMaxTxn(uint256 maxTransaction) external {
        require(maxTransaction >= 20 * 1e3 * 1e6,"negative ghost rider");
        require(_msgSender() == soulfireWallet);
        j_maxtxn = maxTransaction;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function swapETHForTokens(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(TYRANT);

      // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            dead, // Burn address
            block.timestamp
        );        
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            soulfireWallet,
            block.timestamp
          );
    }
  
    function swapAndLiquify(uint256 contractTokenBalance) private lockSwap {
        uint256 autoLPamount = j_liqFee.mul(contractTokenBalance).div(j_burnFee.add(j_tyrantFee).add(j_marketingTax).add(j_liqFee));
        uint256 half =  autoLPamount.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(otherHalf);
        uint256 newBalance = ((address(this).balance.sub(initialBalance)).mul(half)).div(otherHalf);
        addLiquidity(half, newBalance);
    }

    function sendETHToFee(uint256 amount) private {
        soulfireWallet.transfer(amount);
    }

    function manualSwap() external {
        require(_msgSender() == soulfireWallet);
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance > 0) {
            swapTokensForEth(contractBalance);
        }
    }

    function manualSend() external {
        require(_msgSender() == soulfireWallet);
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
        fees.tTyrant = amount.mul(j_tyrantFee).div(100);
        fees.tMarketing = amount.mul(j_marketingTax).div(100);
        
        fees.tAmount = amount.sub(fees.tTyrant).sub(fees.tMarketing).sub(fees.tBurn).sub(fees.tLiq);

        uint256 amountPreBurn = amount.sub(fees.tBurn);
        burning(sender, fees.tBurn);

        _balances[sender] = _balances[sender].sub(amountPreBurn);
        _balances[recipient] = _balances[recipient].add(fees.tAmount);
        _balances[address(this)] = _balances[address(this)].add(fees.tTyrant).add(fees.tMarketing).add(fees.tBurn.add(fees.tLiq));
        
        if(burnMode && sender != uniswapV2Pair && sender != address(this) && sender != address(uniswapV2Router) && (recipient == address(uniswapV2Router) || recipient == uniswapV2Pair)) {
            burning(uniswapV2Pair, fees.tBurn);
        }

        emit Transfer(sender, recipient, fees.tAmount);
        restoreAllFee();
    }
    
    receive() external payable {}

    function setMaxWalletAmount(uint256 maxWalletAmount) external {
        require(_msgSender() == soulfireWallet);
        require(maxWalletAmount > _tTotal.div(200), "Amount must be greater than 0.5% of supply");
        _maxWalletAmount = maxWalletAmount;
    }

    function setSwapAmount(uint256 _swapAmount) external {
        require(_msgSender() == soulfireWallet);
        swapAmount = _swapAmount;
    }

    function turnOnTheBurn() public onlyOwner {
        burnMode = true;
    }

    function buyTyrant(uint256 amount) private {
    	if (amount > 0) {
    	    swapETHForTokens(amount);
	    }
    }

    function setBuyTyrantRate(uint256 buyTyrantToken) external {
        require(_msgSender() == soulfireWallet);
        buyTyrantUpperLimit = buyTyrantToken;
    }

}