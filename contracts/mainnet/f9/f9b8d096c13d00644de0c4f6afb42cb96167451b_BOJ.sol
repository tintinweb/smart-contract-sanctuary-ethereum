/**
 *Submitted for verification at Etherscan.io on 2022-07-22
*/

/**
██████╗  █████╗ ███╗   ██╗██╗  ██╗     ██████╗ ███████╗         ██╗███████╗██╗    ██╗███████╗
██╔══██╗██╔══██╗████╗  ██║██║ ██╔╝    ██╔═══██╗██╔════╝         ██║██╔════╝██║    ██║██╔════╝
██████╔╝███████║██╔██╗ ██║█████╔╝     ██║   ██║█████╗           ██║█████╗  ██║ █╗ ██║███████╗
██╔══██╗██╔══██║██║╚██╗██║██╔═██╗     ██║   ██║██╔══╝      ██   ██║██╔══╝  ██║███╗██║╚════██║
██████╔╝██║  ██║██║ ╚████║██║  ██╗    ╚██████╔╝██║         ╚█████╔╝███████╗╚███╔███╔╝███████║
╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝     ╚═════╝ ╚═╝          ╚════╝ ╚══════╝ ╚══╝╚══╝ ╚══════╝
                                                                                             
The Bank of Jews will gather circumcised brothers from all over the word to make the most jewish investments.

*/
pragma solidity ^0.8.14;

// SPDX-License-Identifier: Unlicensed

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


contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    constructor () {
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

// pragma solidity >=0.6.2;

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


// pragma solidity >=0.6.2;

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


        

contract BOJ is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;


    struct RValuesStruct {
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rReflectionFee;
        uint256 rBurnFee;
        uint256 rmarketingTokenFee;
        uint256 rMarketingETHFee;
    }

    struct TValuesStruct {
        uint256 tTransferAmount;
        uint256 tReflectionFee;
        uint256 tBurnFee;
        uint256 tmarketingTokenFee;
        uint256 tMarketingETHFee;
    }

    struct ValuesStruct {
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rReflectionFee;
        uint256 rBurnFee;
        uint256 rmarketingTokenFee;
        uint256 rMarketingETHFee;
        uint256 tTransferAmount;
        uint256 tReflectionFee;
        uint256 tBurnFee;
        uint256 tmarketingTokenFee;
        uint256 tMarketingETHFee;
    }

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tReflectionFeeTotal;
    uint256 private _tBurnFeeTotal;

    string private _name = "Bank Of Jews";
    string private _symbol = "BOJ";
    uint8 private _decimals = 9;

    uint256 public _reflectionFee = 0;

    uint256 public _burnFee = 0;

    uint256 public _marketingTokenFee = 0;

    uint256 public _marketingETHFee = 3;

    address public marketingTokenFeeWallet = 0xB44a03c4705a6f817Be5a2D6D7C4B4f9d7b6B475;
    address public marketingETHFeeWallet = 0xB44a03c4705a6f817Be5a2D6D7C4B4f9d7b6B475;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    bool inMarketingEthSwap = false;
    bool public _marketingConverttoETH = true;
    bool public _tradingEnabled = false;
    
    uint256 public _maxTxAmount = 10000;
    uint256 private _numTokensSwapToETHForMarketing = 20000;

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
 
    modifier lockTheSwap {
        inMarketingEthSwap = true;
        _;
        inMarketingEthSwap = false;
    }

    constructor () {
        _rOwned[_msgSender()] = _rTotal;
 
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);  // Uniswap V2
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
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

    function totalReflectionFees() public view returns (uint256) {
        return _tReflectionFeeTotal;
    }

    function totalBurnFees() public view returns (uint256) {
        return _tBurnFeeTotal;
    }

    /**
     * @dev Returns the Number of tokens in contract that are needed to be reached before swapping to ETH and sending to Marketing Wallet. .
     */
    function numTokensSwapToETHForMarketing() public view returns (uint256) {
        return _numTokensSwapToETHForMarketing;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            uint256 rAmount = _getValues(tAmount).rAmount;
            return rAmount;
        } else {
            uint256 rTransferAmount = _getValues(tAmount).rTransferAmount;
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!_isExcluded[account], "Account already excluded");
        require(_excluded.length < 100, "Excluded list is too long");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _distributeFee(uint256 rReflectionFee, uint256 rBurnFee, uint256 rmarketingTokenFee, uint256 tReflectionFee, uint256 tBurnFee, uint256 tmarketingTokenFee) private {
        _rTotal = _rTotal.sub(rReflectionFee).sub(rBurnFee);
        _tReflectionFeeTotal = _tReflectionFeeTotal.add(tReflectionFee);
        _tTotal = _tTotal.sub(tBurnFee);
        _tBurnFeeTotal = _tBurnFeeTotal.add(tBurnFee);

        _rOwned[marketingTokenFeeWallet] = _rOwned[marketingTokenFeeWallet].add(rmarketingTokenFee);
        if (_isExcluded[marketingTokenFeeWallet]) {
            _tOwned[marketingTokenFeeWallet] = _tOwned[marketingTokenFeeWallet].add(tmarketingTokenFee);
        }
    }

    function _getValues(uint256 tAmount) private view returns (ValuesStruct memory) {
        TValuesStruct memory tvs = _getTValues(tAmount);
        RValuesStruct memory rvs = _getRValues(tAmount, tvs.tReflectionFee, tvs.tBurnFee, tvs.tmarketingTokenFee, tvs.tMarketingETHFee, _getRate());

        return ValuesStruct(
            rvs.rAmount,
            rvs.rTransferAmount,
            rvs.rReflectionFee,
            rvs.rBurnFee,
            rvs.rmarketingTokenFee,
            rvs.rMarketingETHFee,
            tvs.tTransferAmount,
            tvs.tReflectionFee,
            tvs.tBurnFee,
            tvs.tmarketingTokenFee,
            tvs.tMarketingETHFee
        );
    }

    function _getTValues(uint256 tAmount) private view returns (TValuesStruct memory) {
        uint256 tReflectionFee = calculateReflectionFee(tAmount);
        uint256 tBurnFee = calculateBurnFee(tAmount);
        uint256 tmarketingTokenFee = calculatemarketingTokenFee(tAmount);
        uint256 tMarketingETHFee = calculateMarketingETHFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tReflectionFee).sub(tBurnFee).sub(tmarketingTokenFee).sub(tMarketingETHFee);
        return TValuesStruct(tTransferAmount, tReflectionFee, tBurnFee, tmarketingTokenFee, tMarketingETHFee);
    }

    function _getRValues(uint256 tAmount, uint256 tReflectionFee, uint256 tBurnFee, uint256 tmarketingTokenFee, uint256 tMarketingETHFee, uint256 currentRate) private pure returns (RValuesStruct memory) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rReflectionFee = tReflectionFee.mul(currentRate);
        uint256 rBurnFee = tBurnFee.mul(currentRate);
        uint256 rmarketingTokenFee = tmarketingTokenFee.mul(currentRate);
        uint256 rMarketingETHFee = tMarketingETHFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rReflectionFee).sub(rMarketingETHFee).sub(rBurnFee).sub(rmarketingTokenFee);
        return RValuesStruct(rAmount, rTransferAmount, rReflectionFee, rBurnFee, rmarketingTokenFee, rMarketingETHFee);
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

    function _takeMarketingETHFee(uint256 rMarketingETHFee, uint256 tMarketingETHFee) private {
        _rOwned[address(this)] = _rOwned[address(this)].add(rMarketingETHFee);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tMarketingETHFee);
    }

    function calculateReflectionFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_reflectionFee).div(
            10**2
        );
    }

    function calculateBurnFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_burnFee).div(
            10**2
        );
    }

    function calculatemarketingTokenFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_marketingTokenFee).div(
            10**2
        );
    }

    function calculateMarketingETHFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_marketingETHFee).div(
            10**2
        );
    }

    function removeAllFee() private {
        _reflectionFee = 0;
        _marketingETHFee = 0;
        _burnFee = 0;
        _marketingTokenFee = 0;
    }

    function restoreAllFee() private {
        _reflectionFee = 0;
        _marketingETHFee = 5;
        _marketingTokenFee = 0;
        _burnFee = 0;
	}

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
		_allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        // block trading until owner has added liquidity and enabled trading
        if(!_tradingEnabled && from != owner()) {
            revert("Trading not yet enabled!");
        }
        
        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swaptoEth lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't SwapMarketingAndSendETH if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= _numTokensSwapToETHForMarketing;
        if (
            overMinTokenBalance &&
            !inMarketingEthSwap &&
            from != uniswapV2Pair &&
            _marketingConverttoETH
        ) {
            contractTokenBalance = _numTokensSwapToETHForMarketing;
            //Perform a Swap of Token for ETH Portion of Marketing Fees
            swapMarketingAndSendEth(contractTokenBalance);
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount);

    }

     function swapMarketingAndSendEth(uint256 tokenAmount) private lockTheSwap {
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
            marketingETHFeeWallet,
            block.timestamp
        );
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount) private {
        if(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]){
            removeAllFee();
        }
        else{
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        ValuesStruct memory vs = _getValues(amount);
        _takeMarketingETHFee(vs.rMarketingETHFee, vs.tMarketingETHFee);
        _distributeFee(vs.rReflectionFee, vs.rBurnFee, vs.rmarketingTokenFee, vs.tReflectionFee, vs.tBurnFee, vs.tmarketingTokenFee);

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount, vs);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, vs);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, vs);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount, vs);
        }

        if(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient])
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, ValuesStruct memory vs) private {
        _rOwned[sender] = _rOwned[sender].sub(vs.rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(vs.rTransferAmount);
        emit Transfer(sender, recipient, vs.tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, ValuesStruct memory vs) private {
        _rOwned[sender] = _rOwned[sender].sub(vs.rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(vs.tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(vs.rTransferAmount);
        emit Transfer(sender, recipient, vs.tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount, ValuesStruct memory vs) private {
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(vs.rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(vs.rTransferAmount);
        emit Transfer(sender, recipient, vs.tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount, ValuesStruct memory vs) private {
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(vs.rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(vs.tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(vs.rTransferAmount);
        emit Transfer(sender, recipient, vs.tTransferAmount);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function enableAllFees() external onlyOwner() {
        _reflectionFee = 0;
        _burnFee = 0;
        _marketingTokenFee = 0;
        _marketingETHFee = 5;
        _marketingConverttoETH = true;
    }

    function disableAllFees() external onlyOwner() {
        _reflectionFee = 0;
        _burnFee = 0;
        _marketingTokenFee = 0;
        _marketingETHFee = 0;
        _marketingConverttoETH = false;
    }

    function setMarketingETHWallet(address newWallet) external onlyOwner() {
        marketingETHFeeWallet = newWallet;
    }

    function setMarketingTokenWallet(address newWallet) external onlyOwner() {
        marketingTokenFeeWallet = newWallet;
    }

    function setMaxTxAmount(uint256 maxAmountInTokensWithDecimals) external onlyOwner() {
        require(maxAmountInTokensWithDecimals > 100 * 10**6 * 10**9, "Cannot set transaction amount less than 0.1 percent of initial Total Supply!");
        _maxTxAmount = maxAmountInTokensWithDecimals;
    }

    function enableTrading() public onlyOwner {
        require(!_tradingEnabled, "Trading already enabled!");
        _tradingEnabled = true;
    }

    function setmarketingConverttoETH(bool _enabled) public onlyOwner {
        _marketingConverttoETH = _enabled;
    }

    // Number of Tokens to Accrue before Selling To Add to Marketing
	function setnumTokensSwapToETHForMarketing(uint256 tokenAmount) external onlyOwner() {
       _numTokensSwapToETHForMarketing = tokenAmount;
    }

    /**
     * @dev Function to recover any ETH sent to Contract by Mistake.
    */	
    function recoverETHFromContract(uint256 weiAmount) external onlyOwner{
        require(address(this).balance >= weiAmount, "insufficient ETH balance");
        payable(owner()).transfer(weiAmount);
    }
       
    /**
     * @dev Function to recover any ERC20 Tokens sent to Contract by Mistake.
    */
    function recoverAnyERC20TokensFromContract(address _tokenAddr, address _to, uint _amount) public onlyOwner {
        IERC20(_tokenAddr).transfer(_to, _amount);
    }

}