/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

/*

https://t.me/RINGofPYRO
ringofpyro.com
https://twitter.com/ringofpyro

$RING Ring of Pyro
The ⭕️ Burn: Contract X.

1% BURN OF $RING
1% AUTO LP
2% BURN $PYRO
2% BURN "CONTRACT X"
2% MKTG

At launch
1% max wallet
0.5% max txn

"CONTRACT X" to be variable to be called at anytime,
subject to community votes,
we burn the token we want and/or subject to fees.
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

contract RingOfPyro is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    string private constant _name = "Ring Of Pyro";
    string private constant _symbol = "RING";
    uint8 private constant _decimals = 9;
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 public _tTotal = 1000 * 1e2 * 1e9; //100,000

    uint256 public _maxWalletAmount;
    uint256 public j_maxtxn;
    uint256 public swapAmount = 70 * 1e9; //.07%
    uint256 private buyPyroUpperLimit = 25 * 1e17; // 0.25 ETH
    uint256 private buyContractXUpperLimit = 25 * 1e17; // 0.25 ETH
    // fees
    uint256 public j_liqBuy = 1; 
    uint256 public j_burnBuy = 1;
    uint256 public j_pyroBuy = 0; //turns on after launch is stable
    uint256 public j_jeetBuy = 6; //marketing & dev tax with jeet name for simplicity
    uint256 public j_contractXBuy = 0; //turns on after contract launch

    uint256 public j_liqSell = 1; 
    uint256 public j_burnSell = 1;
    uint256 public j_pyroSell = 0;
    uint256 public j_jeetSell = 23;
    uint256 public j_contractXSell = 0;

    uint256 private j_previousLiqFee = j_liqFee;
    uint256 private j_previousBurnFee = j_burnFee;
    uint256 private j_previousPyroFee = j_pyroFee;
    uint256 private j_previousJeetTax = j_jeetTax;
    uint256 private j_previousContractXTax = j_contractXTax;

    uint256 private j_liqFee;
    uint256 private j_burnFee;
    uint256 private j_pyroFee;
    uint256 private j_jeetTax;
    uint256 private j_contractXTax;

    uint256 public _totalBurned;
    uint256 public _totalPyroBurned;
    uint256 public _totalContractXBurned;

    struct FeeBreakdown {
        uint256 tLiq;
        uint256 tBurn;
        uint256 tPyro;
        uint256 tJeet;
        uint256 tContractX;
        uint256 tAmount;
    }

    mapping(address => bool) private bots;
    address payable private RING = payable(0x858Ff8811Bf1355047f817D09f3e0D800E7054aa); //0x858Ff8811Bf1355047f817D09f3e0D800E7054aa
    address payable private mktg = payable(0x9C3543BF2d6f46bFdd3a0789628bba6a2B5DA7de); //0x9C3543BF2d6f46bFdd3a0789628bba6a2B5DA7de
    address public contractXaddress;

    address payable public contractXdead = payable(0x000000000000000000000000000000000000dEaD);
    address payable public dead = payable(0x000000000000000000000000000000000000dEaD);
    address PYRO = 0x89568569DA9C83CB35E59F92f5Df2F6CA829EEeE; //0x89568569DA9C83CB35E59F92f5Df2F6CA829EEeE

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private swapping = false;
    bool public burnMode = true;
    bool public pyroMode = false;
    bool public contractXMode = false;
    bool public tradingLive = false;

    event ExcludeFromFee(address excludedAddress);   
    event IncludeInFee(address includedAddress);
    
    modifier lockSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor() {
        _balances[address(this)] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[RING] = true;
        _isExcludedFromFee[mktg] = true;
        _isExcludedFromFee[dead] = true;
        _isExcludedFromFee[address(this)] = true;
        emit Transfer(address(0), address(this), _tTotal);
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
        if (j_contractXTax == 0 && j_burnFee == 0 && j_liqFee == 0 && j_pyroFee == 0 && j_jeetTax == 0) return;
        j_previousBurnFee = j_burnFee;
        j_previousLiqFee = j_liqFee;
        j_previousPyroFee = j_pyroFee;
        j_previousJeetTax = j_jeetTax;
        j_previousContractXTax = j_contractXTax;

        j_burnFee = 0;
        j_liqFee = 0;
        j_pyroFee = 0;
        j_jeetTax = 0;
        j_contractXTax = 0;

    }
    
    function restoreAllFee() private {
        j_liqFee = j_previousLiqFee;
        j_burnFee = j_previousBurnFee;
        j_pyroFee = j_previousPyroFee;
        j_jeetTax = j_previousJeetTax;
        j_contractXTax = j_previousContractXTax;
    }

    function changeBuyTax(uint256 burn, uint256 liq, uint256 pyro, uint256 jeet, uint256 contractX) external {
        require(_msgSender() == RING);
        j_burnBuy = burn;
        j_liqBuy = liq;
        j_pyroBuy = pyro;
        j_jeetBuy = jeet;
        require (jeet >= 10);
        j_contractXBuy = contractX;
    }

    function changeSellTax(uint256 burn, uint256 liq, uint256 pyro, uint256 jeet, uint256 contractX) external {
        require(_msgSender() == RING);
        j_burnSell = burn;
        j_liqSell = liq;
        j_pyroSell = pyro;
        j_jeetSell = jeet;
        require (jeet >= 10);
        j_contractXSell = contractX;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function startTheRing() external onlyOwner {

        require(!tradingLive,"trading is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        _maxWalletAmount = 10 * 1e2 * 1e9; //1%
        j_maxtxn = 5 * 1e2 * 1e9; //0.5%

        tradingLive = true;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }

    
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!bots[from] && !bots[to]);
        if(!tradingLive){
            require(_isExcludedFromFee[from] || _isExcludedFromFee[to], "Trading is not active yet.");
        }
        bool takeFee = true;

        if (from != owner() && to != owner() && from != address(this) && to != address(this)) {

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ((!_isExcludedFromFee[from] || !_isExcludedFromFee[to]))) {
                require(balanceOf(to).add(amount) <= _maxWalletAmount, "You are being greedy. Exceeding Max Wallet.");
                require(amount <= j_maxtxn, "Slow down buddy...there is a max transaction");
            }
            
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !bots[to] && !bots[from]) {
                j_liqFee = j_liqBuy;
                j_burnFee = j_burnBuy;
                j_pyroFee = j_pyroBuy;
                j_jeetTax = j_jeetBuy;
                j_contractXTax = j_contractXBuy;
            }
                
            if (to == uniswapV2Pair && from != address(uniswapV2Router) && !bots[to] && !bots[from]) {
                j_liqFee = j_liqSell;
                j_burnFee = j_burnSell;
                j_pyroFee = j_pyroSell;
                j_jeetTax = j_jeetSell;
                j_contractXTax = j_contractXSell;
            }
           
            if (!swapping && from != uniswapV2Pair) {

                uint256 contractTokenBalance = balanceOf(address(this));

                if (contractTokenBalance > swapAmount) {
                    swapAndLiquify(contractTokenBalance);
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
        require(maxTransaction >= 5 * 1e2 * 1e9,"negative ghost rider");
        require(_msgSender() == RING);
        j_maxtxn = maxTransaction;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function swapETHforPyroTokens(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(PYRO);

      // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            dead, // Burn address
            block.timestamp
        );        
    }

    function swapETHforContractXTokens(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(contractXaddress);

      // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            contractXdead, // Burn address
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
            RING,
            block.timestamp
          );
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockSwap {
        uint256 totalFees = (j_burnFee.add(j_pyroFee).add(j_jeetTax).add(j_liqFee).add(j_contractXTax));
        uint256 amountForLiq = j_liqFee.mul(contractTokenBalance).div(totalFees);
        uint256 tokensForMktg = j_jeetTax.mul(contractTokenBalance).div(totalFees);

        uint256 tokensForLiq =  amountForLiq.div(2);
        uint256 tokensForETH = contractTokenBalance.sub(tokensForLiq);
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(tokensForETH);
        uint256 ethForLiq = ((address(this).balance.sub(initialBalance)).mul(tokensForLiq)).div(tokensForETH);
        addLiquidity(tokensForLiq, ethForLiq);

        uint256 tokensForPyro = j_pyroFee.mul(contractTokenBalance).div(totalFees);
        uint256 ethForPyro = ((address(this).balance.sub(initialBalance)).mul(tokensForPyro)).div(tokensForETH);
        if(pyroMode && ethForPyro > 0) {
            buyPyro(ethForPyro);
        }

        uint256 tokensForContractX = j_contractXTax.mul(contractTokenBalance).div(totalFees);
        uint256 ethForContractX = ((address(this).balance.sub(initialBalance)).mul(tokensForContractX)).div(tokensForETH);
        if(contractXMode && ethForContractX > 0) {
            buyContractX(ethForContractX);
        }

        uint256 ethForMktg = ((address(this).balance.sub(initialBalance)).mul(tokensForMktg)).div(tokensForETH);
        sendETHToFee(ethForMktg);
    }

    function sendETHToFee(uint256 amount) private {
        RING.transfer((amount).div(2));
        mktg.transfer((amount).div(2));
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

    function _transferAgain(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) { 
                removeAllFee();
        }
        
        FeeBreakdown memory fees;
        fees.tBurn = amount.mul(j_burnFee).div(100);
        fees.tLiq = amount.mul(j_liqFee).div(100);
        fees.tPyro = amount.mul(j_pyroFee).div(100);
        fees.tJeet = amount.mul(j_jeetTax).div(100);
        fees.tContractX = amount.mul(j_contractXTax).div(100);
        
        fees.tAmount = amount.sub(fees.tPyro).sub(fees.tJeet).sub(fees.tBurn).sub(fees.tLiq).sub(fees.tContractX);

        uint256 amountPreBurn = amount.sub(fees.tBurn);
        burning(sender, fees.tBurn);

        _balances[sender] = _balances[sender].sub(amountPreBurn);
        _balances[recipient] = _balances[recipient].add(fees.tAmount);
        _balances[address(this)] = _balances[address(this)].add(fees.tPyro).add(fees.tJeet).add(fees.tBurn).add(fees.tLiq).add(fees.tContractX);
        
        if(burnMode && sender != uniswapV2Pair && sender != address(this) && sender != address(uniswapV2Router) && (recipient == address(uniswapV2Router) || recipient == uniswapV2Pair)) {
            burning(uniswapV2Pair, fees.tBurn);
        }

        emit Transfer(sender, recipient, fees.tAmount);
        restoreAllFee();
    }
    
    receive() external payable {}

    function setMaxWalletAmount(uint256 maxWalletAmount) external {
        require(_msgSender() == RING);
        require(maxWalletAmount > _tTotal.div(200), "Amount must be greater than 0.5% of supply");
        _maxWalletAmount = maxWalletAmount;
    }

    function setSwapAmount(uint256 _swapAmount) external {
        require(_msgSender() == RING);
        swapAmount = _swapAmount;
    }

    function endJeet() external {
        require(_msgSender() == RING);
        j_pyroBuy = 2;
        j_pyroSell = 2;
        j_jeetSell = 10;
        j_jeetBuy = 2;
        j_contractXBuy = 2;
        j_contractXSell = 2;
        contractXaddress = (0x8901ceAC9DD796a98DAa32e2fc55dC68fEcDA01A); //0x8901ceAC9DD796a98DAa32e2fc55dC68fEcDA01A
        contractXdead = dead;
        contractXMode = true;
        pyroMode = true;
    }

    function lastJeet() external {
        require(_msgSender() == RING);
        j_jeetSell = 2;
    }

    function changeContractX(uint256 buyContractXTax, uint256 sellContractXTax, address payable j_dead, address addressOfContractX) external {
        require(_msgSender() == RING);
        require(buyContractXTax + sellContractXTax <= 6);
        contractXaddress = addressOfContractX;
        j_contractXBuy = buyContractXTax;
        j_contractXSell = sellContractXTax;
        contractXdead = j_dead;
    }

    function buyPyro(uint256 amount) private {
    	if (amount > 0) {
    	    swapETHforPyroTokens(amount);
            _totalPyroBurned = _totalPyroBurned.add(amount);
	    }
    }

    function buyContractX(uint256 amount) private {
    	if (amount > 0) {
    	    swapETHforContractXTokens(amount);
            _totalContractXBurned = _totalContractXBurned.add(amount);
	    }
    }

    function setBuyPyroRate(uint256 buyPyroToken) external {
        require(_msgSender() == RING);
        buyPyroUpperLimit = buyPyroToken;
    }

    function setBuyContractXRate(uint256 buyContractXToken) external {
        require(_msgSender() == RING);
        buyContractXUpperLimit = buyContractXToken;
    }

    function setMktg(address payable _address) external {
        require(_msgSender() == RING || _msgSender() == mktg);
        mktg = _address;
    }

    function setContractXdead(address payable walletAddress) external {
        require(_msgSender() == RING);

        contractXdead = walletAddress;
    }

    function setContractXaddress(address payable walletAddress) external {
        require(_msgSender() == RING);
        contractXaddress = walletAddress;
    }

    function excludeFromFee(address account) external {
        require(_msgSender() == RING);
        _isExcludedFromFee[account] = true;
        emit ExcludeFromFee(account);
    }

    function includeInFee(address account) external {
        require(_msgSender() == RING);
        _isExcludedFromFee[account] = false;
        emit IncludeInFee(account);
    }

    function isExcludedFromFee(address account) external view returns (bool) {
        return _isExcludedFromFee[account];
    }

}