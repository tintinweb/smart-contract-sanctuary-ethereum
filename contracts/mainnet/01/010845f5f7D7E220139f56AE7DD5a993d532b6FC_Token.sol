/**
 *Submitted for verification at Etherscan.io on 2023-05-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(address(msg.sender));
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

   
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }


    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }


    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
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
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor ()  {
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
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router {
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

contract Token is Context, IERC20, Ownable {

    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;
    using Address for address;
    using SafeERC20 for IERC20;
    
    address constant dead = 0x000000000000000000000000000000000000dEaD;
    address constant zero = 0x000000000000000000000000000000000000dEaD;
    
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping(address => bool) public isExcludedFromMaxTxn;
    mapping(address => bool) public isExcludedFromMaxHoldLimit;
    
    mapping (address => bool) public AutomaticMarketPair;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
    
    address public router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    
    uint256 private constant MAX = ~uint256(0);
    
    uint256 private _tFeeTotal;

    string public constant _name ="BagelBank";
    string public constant _symbol = "$BAGEL";
    uint8 private constant _decimals = 9;

    uint256 public _tTotal = 500_000_000_000_000_000 * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    uint256 public numTokensSellToAddToLiquidity = _tTotal.mul(5).div(1e4); //0.05% 
    bool public swapByLimit = false;

    uint256 public maxbageltransaction = _tTotal.mul(5).div(1000);      // 0.5% for max transaction
    uint256 public maxbagelbalance = _tTotal.mul(10).div(1000);         // 1% for max bag

    uint256 private _taxFee = 0;                           
    uint256 private _previousTaxFee = _taxFee;

    uint256 private _LiquidityFee = 0;
    uint256 private _previousLiquidityFee = _LiquidityFee;    

    uint256 private _DevFee = 0;
    uint256 private _previousDevFee = _DevFee;

    address public liquidityReciever;
    address public developmentWallet = address(0xd3048Db210D398A9be9810162F75E8423DFB20B3);

    struct BuyFee{
        uint256 setTaxFee;
        uint256 setLiquidityFee;
        uint256 setDevFee;     
    }

    struct SellFee{
        uint256 setTaxFee;
        uint256 setLiquidityFee;
        uint256 setDevFee;     
    }

    BuyFee public buyFee;
    SellFee public sellFee;

    IUniswapV2Router public pcsV2Router;
    address public pcsV2Pair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;    
    bool public iswalletLimit = true;
    bool public isTxLimit = true;
    
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

    constructor ()  {       
        
        _rOwned[msg.sender] = _rTotal;

        liquidityReciever = msg.sender;

        buyFee.setTaxFee = 20;
        buyFee.setLiquidityFee = 20;
        buyFee.setDevFee = 5;
        
        sellFee.setTaxFee = 20;
        sellFee.setLiquidityFee = 20;
        sellFee.setDevFee = 5;
                
        IUniswapV2Router _pcsV2Router = IUniswapV2Router(router);
            
        pcsV2Pair = IUniswapV2Factory(_pcsV2Router.factory())
            .createPair(address(this), _pcsV2Router.WETH());

        pcsV2Router = _pcsV2Router;

        _allowances[address(this)][address(pcsV2Router)] = MAX;

        AutomaticMarketPair[pcsV2Pair] = true;

        //exclude owner and this contract from fee
        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[address(_pcsV2Router)] = true;
        _isExcludedFromFee[address(dead)] = true;

        //exclude owner and this contract from txn limit
        isExcludedFromMaxTxn[msg.sender] = true;
        isExcludedFromMaxTxn[address(this)] = true;
        isExcludedFromMaxTxn[address(_pcsV2Router)] = true;

        // exclude addresses from max tx
        isExcludedFromMaxHoldLimit[msg.sender] = true;
        isExcludedFromMaxHoldLimit[address(this)] = true;
        isExcludedFromMaxHoldLimit[address(_pcsV2Router)] = true;
        isExcludedFromMaxHoldLimit[pcsV2Pair] = true;

        emit Transfer(address(0), msg.sender, _tTotal);
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
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
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

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amt must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amt must be less than tot refl");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    //to recieve ETH from pcsV2Router when swaping
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);

    }
    
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10**3
        );
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_LiquidityFee + _DevFee).div(
            10**3
        );
    }
    
    function removeAllFee() private {
        if(_taxFee == 0 && _LiquidityFee == 0 && _DevFee == 0) return; 
        
        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _LiquidityFee;
        _previousDevFee = _DevFee;
        
        _taxFee = 0;
        _LiquidityFee = 0;
        _DevFee = 0;
    }
    
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _LiquidityFee = _previousLiquidityFee;
        _DevFee = _previousDevFee;
    }

    function setBuy() private {
        _taxFee = buyFee.setTaxFee;
        _LiquidityFee = buyFee.setLiquidityFee;
        _DevFee = buyFee.setDevFee;
    }
    
    function setSell() private {
        _taxFee = sellFee.setTaxFee;
        _LiquidityFee = sellFee.setLiquidityFee;
        _DevFee = sellFee.setDevFee;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _checkMaxWalletAmount(address to, uint256 amount) private view {
        if (  !isExcludedFromMaxHoldLimit[to] && iswalletLimit) {
            require(
                balanceOf(to).add(amount) <= maxbagelbalance,
                "ERC20: amount exceed max holding limit"
            );
        }
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from zero address");
        require(spender != address(0), "ERC20: approve to zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from zero address");
        require(to != address(0), "ERC20: transfer to zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (!isExcludedFromMaxTxn[from] && !isExcludedFromMaxTxn[to] && isTxLimit ) {
            require(amount <= maxbageltransaction, "ERC20: max txn limit exceeds");
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            !inSwapAndLiquify &&
            overMinTokenBalance &&
            AutomaticMarketPair[to] &&
            swapAndLiquifyEnabled
        ) {
            
            swapAndUpdate(contractTokenBalance);
            
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }

        _tokenTransfer(from,to,amount,takeFee);
    }

    function swapAndUpdate(uint _contractBalance) private lockTheSwap {

        if(_contractBalance == 0) return;
        if(swapByLimit) _contractBalance = numTokensSellToAddToLiquidity;
        uint liquidityShare = buyFee.setLiquidityFee.add(sellFee.setLiquidityFee);
        uint DevShare = buyFee.setDevFee.add(sellFee.setDevFee);
        uint totalShares = liquidityShare.add(DevShare);
        if(totalShares == 0) return;
        uint tokensForLP = _contractBalance.mul(liquidityShare).div(totalShares).div(2);
        uint tokensForSwap = _contractBalance.sub(tokensForLP);
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(tokensForSwap);
        uint256 totalETHFee = totalShares.sub(liquidityShare.div(2));
        uint256 amountReceived = address(this).balance.sub(initialBalance);
        uint256 amountETHLiquidity = amountReceived.mul(liquidityShare).div(totalETHFee).div(2);
        uint256 amountETHDev = amountReceived.sub(amountETHLiquidity);
        if(amountETHDev > 0) payable(developmentWallet).transfer(amountETHDev);
        if(amountETHLiquidity > 0 && tokensForLP > 0) addLiquidity(tokensForLP, amountETHLiquidity);
    }


    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pcsV2Router.WETH();

        _approve(address(this), address(pcsV2Router), tokenAmount);

        // make the swap
        pcsV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
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
        _approve(address(this), address(pcsV2Router), tokenAmount);

        // add the liquidity
        pcsV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityReciever,
            block.timestamp
        );
    }
   
    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        
            removeAllFee();

            if (takeFee){
                if (AutomaticMarketPair[sender]) {
                    setBuy();
                }
                if (AutomaticMarketPair[recipient]) {
                    setSell();
                }
            } 
        
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        
        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _checkMaxWalletAmount(recipient, tTransferAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _checkMaxWalletAmount(recipient, tTransferAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _checkMaxWalletAmount(recipient, tTransferAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _checkMaxWalletAmount(recipient, tTransferAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _tokenTransferNoFee(address sender, address recipient, uint256 amount) private {
        uint256 currentRate =  _getRate();  
        uint256 rAmount = amount.mul(currentRate);   

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rAmount); 
        
        if (_isExcluded[sender]) {
            _tOwned[sender] = _tOwned[sender].sub(amount);
        } 
        if (_isExcluded[recipient]) {
            _tOwned[recipient] = _tOwned[recipient].add(amount);
        } 
        emit Transfer(sender, recipient, amount);
    }

    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded from reward");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }
    
    function excludeFromFee(address account) external onlyOwner() {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) external onlyOwner() {
        _isExcludedFromFee[account] = false;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setSwapByLimit(bool _enabled) external onlyOwner {
        swapByLimit = _enabled;
    }

    function setLiquidityWallet(address newWallet) external onlyOwner {
        liquidityReciever = newWallet;
    }

    function setDevWallet(address newWallet) external onlyOwner {
        developmentWallet = newWallet;
    }
    
    function setMaxWalletEnabled(bool _enabled) external onlyOwner {
        iswalletLimit = _enabled;
    }

    function setMaxTxEnabled(bool _enabled) external onlyOwner {
        isTxLimit = _enabled;
    }

    function setMaxBagelLimit(uint _value) external onlyOwner {
        maxbagelbalance = _value;
    }

    function setMaxTxLimit(uint _value) external onlyOwner {
        maxbageltransaction = _value;
    }

    function excludeFromMaxTransaction(address _user,bool _status) external onlyOwner {
        isExcludedFromMaxTxn[_user] = _status;
    }

    function excludeFromMaxBag(address _user,bool _status) external onlyOwner {
        isExcludedFromMaxHoldLimit[_user] = _status;
    }

    function setNumTokensSellToAddToLiquidity(uint _value) public onlyOwner {
        numTokensSellToAddToLiquidity = _value;
    }

    function setBuyFee(uint _newtax, uint _newLiquidity, uint _newDev) public onlyOwner {
        buyFee.setTaxFee = _newtax;
        buyFee.setLiquidityFee = _newLiquidity;
        buyFee.setDevFee = _newDev;
    }

    function setSellFee(uint _newtax, uint _newLiquidity, uint _newDev) public onlyOwner {      
        sellFee.setTaxFee = _newtax;
        sellFee.setLiquidityFee = _newLiquidity;
        sellFee.setDevFee = _newDev;
    }

    function addNewRouterAddress(address newAddress) public onlyOwner {
        IUniswapV2Router _pcsV2Router = IUniswapV2Router(newAddress);
            // Create a uniswap pair for this new token
        address _np = IUniswapV2Factory(_pcsV2Router.factory())
            .createPair(address(this), _pcsV2Router.WETH());
        _allowances[address(this)][address(_pcsV2Router)] = MAX;
        AutomaticMarketPair[_np] = true;    
    }

    function setRouterAddress(address newAddress) public onlyOwner {
        IUniswapV2Router _pcsV2Router = IUniswapV2Router(newAddress);
        pcsV2Router = _pcsV2Router;
        _allowances[address(this)][address(pcsV2Router)] = MAX;
    }

    function setMarketPair(address _pair, bool _status) public onlyOwner {
        AutomaticMarketPair[_pair] = _status;
    }

    function recoverFunds() public onlyOwner {
        (bool os,) = payable(msg.sender).call{value: address(this).balance}("");
        require(os);
    }

    function recoverBEP20(address tokenAddress, uint256 tokenAmount) public onlyOwner {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }

}