/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

// File: Moontest_flat_flat.sol


// File: Moontest_flat.sol


// File: Moontest.sol


pragma solidity ^0.8.4;
 
interface IERC20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
/**
 * SafeMath
 */
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
 
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
 
    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
 
/**
 * @dev Collection of functions related to the address type
 */
library Address {
 
    function isContract(address account) internal view returns (bool) {
 
        return account.code.length > 0;
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
 
    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
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
 
/**
 * Basic access control mechanism
 */
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;
 
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
 
/**
 * DEX Interfaces
 */
interface IPancakeRouter01 {
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
 
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getamountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getamountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getamountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getamountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
interface IPancakeRouter02 is IPancakeRouter01 {
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
interface IPancakeERC20 {
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
}
interface IPancakeFactory {
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
 

contract MoonTube is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
   
    event OwnerUpdateTaxes(uint8 reflectionTax,uint8 secondaryTax);
    event OwnerRemoveLPPercent(uint8 LPPercent);
    event OwnerExtendLPLock(uint256 timeSeconds);
    event OwnerLockLP(uint256 liquidityUnlockSeconds);
    event OwnerUpdateSwapThreshold(uint8 _swapThreshold);
    event OwnerTriggerSwap(uint8 _swapThreshold,bool ignoreLimits);
    event OwnerCreateLP(uint256 LPtokens,uint256 amountWei);
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 liquidityTokens,uint256 LPETH);
    // Mappings
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    mapping(address=>bool) private _blacklisted;
    mapping(address=>bool)private _marketMakers;
    // Basic Contract Info
    address[] private _excluded;
    string private _name = "MoonTube";
    string private _symbol = "MTUBE";
    uint8 private _decimals = 18;
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 100_000_000_000_000*(10**_decimals); // 100 T, 18 decimals
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    // Wallets
    address public burnWallet=0x000000000000000000000000000000000000dEaD;
    address public marketingWallet=0xC2cAc95654f701931FF9d59Ed39b82aa4AFc3838;
    
    uint256 public totalLPETH;
    uint256 public totalMarketingETH;
    
    uint256 public _reflectFee=5;
    uint256 private _previousReflectFee=_reflectFee;
    uint256 public _secondaryTax=10;
    uint256 private _previousSecondaryFee=_secondaryTax;
    // Max Transaction
    uint256 private _maxTransaction=2_000_000_000_000*(10**_decimals);
    // Max Wallets
    uint256 private maxWallet = 0;
    // Taxes
    Taxes private _taxes;
    struct Taxes {
        uint8 liquidityTax;
        uint8 marketingTax;
    }
    // PancakeSwap
    IPancakeRouter02 private _pancakeRouter;
    address public _pancakeRouterAddress=0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public _pancakePairAddress;
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    uint8 private swapThreshold=5;
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    constructor () {
        _rOwned[msg.sender]=_rTotal;
        emit Transfer(address(0),msg.sender,_tTotal);
        _isExcludedFromFee[msg.sender]=_isExcludedFromFee[burnWallet]=_isExcludedFromFee[address(this)]=true;
        _taxes.liquidityTax=40;
        _taxes.marketingTax=60;
        _pancakeRouter=IPancakeRouter02(_pancakeRouterAddress);
        _pancakePairAddress=IPancakeFactory(_pancakeRouter.factory()).createPair(address(this),_pancakeRouter.WETH());
        _approve(address(this),address(_pancakeRouter),type(uint256).max);
        excludeFromReward(address(_pancakePairAddress));
        excludeFromReward(address(burnWallet));
        excludeFromReward(address(this));
        _marketMakers[_pancakePairAddress]=true;
    }
    // Basic Internal Functions
    function name() public view override returns (string memory) {
        return _name;
    }
    function symbol() public view override returns (string memory) {
        return _symbol;
    }
    function decimals() public view override returns (uint8) {
        return _decimals;
    }
    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }
    function getOwner() external view override returns (address) { return owner();}
 
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
 
    receive() external payable {
        require(msg.sender==owner()||msg.sender==_pancakeRouterAddress);
    }
 
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
 
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
 
    // Reflections
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tSecondary) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tSecondary, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tSecondary);
    }
    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateReflectFee(tAmount);
        uint256 tSecondary = calculateSecondaryFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tSecondary);
        return (tTransferAmount, tFee, tSecondary);
    }
    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tSecondary, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rSecondary = tSecondary.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rSecondary);
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
 
    // Taxes
    function calculateReflectFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_reflectFee).div(
            10**2
        );
    }
    function calculateSecondaryFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_secondaryTax).div(
            10**2
        );
    }
    function removeAllFee() private {
        if(_reflectFee == 0 && _secondaryTax == 0) return;
 
        _previousReflectFee = _reflectFee;
        _previousSecondaryFee = _secondaryTax;
 
        _reflectFee = 0;
        _secondaryTax = 0;
    }
    function restoreAllFee() private {
        _reflectFee = _previousReflectFee;
        _secondaryTax = _previousSecondaryFee;
    }
    function _takeFees(uint256 tSecondary, uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
        uint256 currentRate =  _getRate();
        uint256 rSecondary = tSecondary.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rSecondary);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tSecondary);
    }

    function changeMaxTrans(uint256 newMaxTransaction) public onlyOwner {
        _maxTransaction = newMaxTransaction;
    }

    function setMaxWallet(uint256 _maxWallet) public onlyOwner {
        maxWallet = _maxWallet;    }


 
    // Swap and distribution
    function swapAndLiquify(uint8 _swapThreshold,bool ignoreLimits) private lockTheSwap {
        uint256 toSwap=_swapThreshold*balanceOf(_pancakePairAddress)/1000;
        // Get balance of contract
        uint256 contractBalance = balanceOf(address(this));
        // 1% of 100T
        uint256 maxSwapSize=(100_000_000_000_000*(10**_decimals))/100;
        // toSwap cannot exceed 1 %
        toSwap = toSwap > maxSwapSize ? maxSwapSize : toSwap;
        //
        if (contractBalance < toSwap) {
            if (ignoreLimits)
                toSwap = contractBalance;
            else return;
        }
        uint256 totalLiquidityTokens=toSwap*_taxes.liquidityTax/100;
        uint256 tokensLeft=toSwap-totalLiquidityTokens;
        uint256 liquidityTokens=totalLiquidityTokens/2;
        uint256 liquidityETHTokens=totalLiquidityTokens-liquidityTokens;
        toSwap=liquidityETHTokens+tokensLeft;
        uint256 oldETH=address(this).balance;
        uint256 newETH = address(this).balance-oldETH;
        uint256 LPETH = (newETH*liquidityETHTokens)/toSwap;
        addLiquidity(liquidityTokens, LPETH);
        uint256 remainingETH=address(this).balance-oldETH;
        payable(marketingWallet).transfer(remainingETH);
        emit SwapAndLiquify(liquidityTokens,LPETH);
    }
    function swapTokensForBNB(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        // WBNB
        path[1] = _pancakeRouter.WETH();
        _pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            // Receiver address
            address(this),
            block.timestamp
        );
    }
 
    function addLiquidity(uint256 tokenAmount, uint256 amountWei) private {
        totalLPETH+=amountWei;
        _pancakeRouter.addLiquidityETH{value: amountWei}(
            // Liquidity Tokens are sent from contract, NOT OWNER!
            address(this),
            tokenAmount,
            0,
            0,
            // contract receives CAKE-LP, NOT OWNER!
            address(this),
            block.timestamp
        );
    }
    function _removeLiquidityPercent(uint8 percent) private {
        IPancakeERC20 lpToken = IPancakeERC20(_pancakePairAddress);
        uint256 amount = lpToken.balanceOf(address(this)) * percent / 100;
        lpToken.approve(address(_pancakeRouter), amount);
        _pancakeRouter.removeLiquidityETHSupportingFeeOnTransferTokens(
            address(this),
            amount,
            0,
            0,
            // Receiver address
            address(this),
            block.timestamp
        );
    }
 
    // Transfer
    function _transfer(address from,address to,uint256 amount) private {
        bool isBuy=_marketMakers[from];
        bool isSell=_marketMakers[to];
        bool takeFee = true;
        if(_isExcludedFromFee[from]||_isExcludedFromFee[to]){
            takeFee = false;
        } else {
            if(isBuy||isSell) {
                require(amount<=_maxTransaction);
                if(isSell&&!inSwapAndLiquify&&swapAndLiquifyEnabled)
                    swapAndLiquify(swapThreshold,false);
            }
        }
        _tokenTransfer(from,to,amount,takeFee);
    }
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!takeFee)
            removeAllFee();
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
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tSecondary) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeFees(tSecondary, rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tSecondary) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeFees(tSecondary, rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tSecondary) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeFees(tSecondary, rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tSecondary) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeFees(tSecondary, rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    // View Functions
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }
    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount / (currentRate);
    }
    // Owner Functions
    function excludeFromReward(address account) public onlyOwner {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }
    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account], "Account is already excluded");
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
    // Use this incase new marketing wallet
    function ownerChangeMarketingWallet(address newWallet) public onlyOwner {
        marketingWallet=newWallet;
    }
    function excludeFromFee(address account,bool excluded) public onlyOwner {
        _isExcludedFromFee[account]=excluded;
    }
    function ownerWithdrawMarketingBNB() public onlyOwner {
        (bool success,) = marketingWallet.call{value: (address(this).balance)}("");
        require(success);
    }
    function ownerUpdateTaxes(uint8 reflectFee, uint8 secondaryTaxFee) public onlyOwner {
        require((reflectFee+secondaryTaxFee)<=15);
        _reflectFee=reflectFee;
        _secondaryTax=secondaryTaxFee;
        emit OwnerUpdateTaxes(reflectFee,secondaryTaxFee);
    }
    // Cannot withdraw token, or LP-token from contract
    function ownerWithdrawCakeLP(address cakeLP) public onlyOwner {
        require(cakeLP!=address(this));
        IERC20 token=IERC20(cakeLP);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
    function ownerTriggerSwap(uint8 _swapThreshold,bool ignoreLimits) public onlyOwner {
        swapAndLiquify(_swapThreshold,ignoreLimits);
        emit OwnerTriggerSwap(_swapThreshold,ignoreLimits);
    }
    function ownerSwitchSwapAndLiquify(bool enabled) public onlyOwner {
        swapAndLiquifyEnabled=enabled;
        emit SwapAndLiquifyEnabledUpdated(enabled);
    }
    function ownerUpdateAMM(address marketMaker,bool enabled) public onlyOwner {
        _marketMakers[marketMaker]=enabled;
        // excludeFromRewards when adding new AMM
    }
    function ownerUpdateSecondaryTaxes(uint8 marketingTax,uint8 liquidityTax) public onlyOwner {
        require((liquidityTax+marketingTax)<=100);
        _taxes.liquidityTax=liquidityTax;
        _taxes.marketingTax=marketingTax;
    }
    function ownerUpdateSwapThreshold(uint8 _swapThreshold) public onlyOwner {
        require(_swapThreshold<=50);
        swapThreshold=_swapThreshold;
        emit OwnerUpdateSwapThreshold(_swapThreshold);
    }
}