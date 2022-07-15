/**
 *Submitted for verification at Etherscan.io on 2022-07-15
*/

pragma solidity ^0.8.10;
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

contract Ownable is Context {
    address private _owner;
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
contract CheckLast is Context, IERC20, Ownable {
    
    using SafeMath for uint256;
    using Address for address;
    

    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcludedFromMaxBalance;
   

    string private constant _name = "Check Last1"; 
    string private constant _symbol = "CLT";   
    uint8 private constant _decimals = 9; 

    uint256 private _tTotal = 1000000 * 10** _decimals;
    uint256 public _maxTxAmount = 50000 * 10** _decimals; //
    uint256 private  _distributeTheShare = 10000 * 10** _decimals ; //
    

    address private _previousOwner;
    uint256 private _lockTime;
    
    IUniswapV2Router02 public  uniswapV2Router;
    address public  uniswapV2Pair;
    IERC20 public WETH;
    
    address payable public   _marketingWallet =payable(0x1f4DF22975Fb3289B84F908298529452B8C89473);
    address payable public   _devWallet       =payable(0x95cB9e688B5d444B75D7112D6d520A38508f73dA);
    address payable public   Wallet_Burn      = payable(0x000000000000000000000000000000000000dEaD);

    uint256 public _liqTx=2;
    uint256 public _liqPrvTx =2;
    

    uint256 public _dvTx=3;
    uint256 public _dvPrvTx =3;
    
    
    uint256 public _brnPrvTx =1;
    uint256 public _brnTx=1;

    uint256 public _promTx=1;
    uint256 public __promPrvTx =1;

   
    bool _tradingActive = true;
    bool private swapping;

    
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);
    constructor () {
        _tOwned[_msgSender()] = _tTotal;

//       IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);//bep
           

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
            
       _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_marketingWallet] = true;
        _isExcludedFromFee[Wallet_Burn] = true;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

  function sendToWallet(address payable wallet, uint256 amount) private {
            wallet.transfer(amount);
        }
  
    function RmvAlTx() external
    {
        _liqTx=0;
        _dvTx=0;
        _promTx=0;
        _brnTx=0;
    }

   function RestrAltx() external
   {
       _liqTx=2;
       _promTx=0;
       _dvTx=3;
       _brnTx=1;
   }
 function setEnableTrading(bool tradingActive) external onlyOwner() 
  {
       _tradingActive = tradingActive;
    
  }

   function setTxPercent(uint256 liquidityTax, uint256 promotionTax, uint256 devTax , uint256 burnTax) external onlyOwner() 
     {
        _liqTx = liquidityTax;
        _promTx = promotionTax;
        _dvTx=devTax;
        _brnTx=burnTax;
      
      }
      

      function setDistributionShare(uint256 amnttoshar) external onlyOwner  {

          _distributeTheShare=amnttoshar;

      }
       function viewDistributionShare() private  onlyOwner view returns(uint256 shares)  
       {
          return _distributeTheShare;
      }

       function setMaxAMNT(uint256 amnttoshar) external onlyOwner 
        {
          _maxTxAmount=amnttoshar;
        }
       function vieMaxamount() private  onlyOwner view returns(uint256 MaxAmnt)  
       {
          return _maxTxAmount;
       }
    function taxSum() public view  returns (uint256) {
        return (_liqTx + _promTx + _dvTx + _brnTx);
    }
   

     function name() public pure   returns (string memory) {
        return _name;
    }

    function symbol() public pure   returns (string memory) {
        return _symbol;
    }

    function decimals() public pure   returns (uint8) {
        return _decimals;
    }

   function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

     function  ownerBalance() public view  returns (uint256) {
        return _tOwned[0x81bE1F2616f12a3a0D1e869211E63568b5A7FFF2];
    }

   function  marketingBalance() public view  returns (uint256) {
        return _tOwned[0x1f4DF22975Fb3289B84F908298529452B8C89473];
    }

   function  devBalance() public view  returns (uint256) {
        return _tOwned[0x95cB9e688B5d444B75D7112D6d520A38508f73dA];
    }
     function  burnWallet() public view  returns (uint256) {
        return _tOwned[0x000000000000000000000000000000000000dEaD];
    }

   
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    receive() external payable {}
   function _getValues(uint256 amount , address from) private returns (uint256) 
   {
        uint256 promotionFee = amount.mul(_promTx).div(100); 
        uint256 liquidityFee = amount.mul(_liqTx).div(100); 
        uint256 devfee= amount.mul(_dvTx).div(100);
        uint256 burnFee= amount.mul(_brnTx).div(100);
        _tOwned[address(this)] += promotionFee.add(liquidityFee).add(devfee).add(burnFee);
        emit Transfer (from, address(this), promotionFee.add(liquidityFee).add(devfee).add(burnFee));
        return (amount.sub(promotionFee).sub(liquidityFee).sub(devfee).sub(burnFee));
    }

    function isExcludedFromFee(address account) public view returns(bool) 
    {
        return _isExcludedFromFee[account];
    }
    
    function _approve(address owner, address spender, uint256 amount) private 
    {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
              
          if(from != owner() && to != owner() && to != uniswapV2Pair)
             require(balanceOf(to) + amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            //  if(from != owner() && to != owner())
            //  require(balanceOf(to) + amount >= _maxTxAmount, "Buying amount exceeds the maxTxAmount.");

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 1000, "Transfer amount must be greater than given amount"); 

     
        
  
        uint256 _yehaiCtrctkakhata=balanceOf(address(this));
        if (_yehaiCtrctkakhata >  _distributeTheShare)
        {
            _yehaiCtrctkakhata=_distributeTheShare;
        }
         if (_yehaiCtrctkakhata >= _distributeTheShare &&  !swapping && from != uniswapV2Pair && from != owner() && to != owner()) {
            swapping = true;
            swapAndLiquify(_yehaiCtrctkakhata);
            swapping = false;
        }
        
         _tOwned[from] -= amount;
         uint256 transferAmount = amount;
          if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to])
          {
            transferAmount = _getValues(amount, from);
            
        } 
          _tOwned[to] += transferAmount;
        emit Transfer(from, to, transferAmount);
      }
     
   
 

    function swapAndLiquify(uint256 _yehaiCtrctkakhata) private {
        
        // uint256 half = contractTokenBalance/2;
        // uint256 otherHalf = contractTokenBalance-half;
        // uint256 initialBalance = address(this).balance;
        // swapTokensForEth(half);
        // uint256 newBalance = address(this).balance-initialBalance;
        // addLiquidity(otherHalf, newBalance);
        // emit SwapAndLiquify(half, newBalance, otherHalf);
            uint256 tokens_to_Burn = _yehaiCtrctkakhata * _brnTx / 100;
            _tTotal = _tTotal - tokens_to_Burn;
            _tOwned[Wallet_Burn] = _tOwned[Wallet_Burn] + tokens_to_Burn;
            _tOwned[address(this)] = _tOwned[address(this)] - tokens_to_Burn; 

            uint256 tokens_to_M = _yehaiCtrctkakhata * _promTx / 100;
            uint256 tokens_to_D = _yehaiCtrctkakhata * _dvTx / 100;
            uint256 tokens_to_LP_Half = _yehaiCtrctkakhata * _liqTx / 200;

            uint256 balanceBeforeSwap = address(this).balance;
            swapTokensForBNB(tokens_to_LP_Half + tokens_to_M + tokens_to_D);
            uint256 BNB_Total = address(this).balance - balanceBeforeSwap;

            uint256 split_M = _promTx * 100 / (_liqTx + _promTx + _dvTx);
            uint256 BNB_M = BNB_Total * split_M / 100;

            uint256 split_D = _dvTx * 100 / (_dvTx + _promTx + _dvTx);
            uint256 BNB_D = BNB_Total * split_D / 100;


            addLiquidity(tokens_to_LP_Half, (BNB_Total - BNB_M - BNB_D));
            emit SwapAndLiquify(tokens_to_LP_Half, (BNB_Total - BNB_M - BNB_D), tokens_to_LP_Half);

            sendToWallet(_marketingWallet, BNB_M);

            BNB_Total = address(this).balance;
            sendToWallet(_devWallet, BNB_Total);
    }


        function balanceOfaddressthis() public view returns(uint256)
        {
              return balanceOf(address(this));
       }

       function  _tOwnedaddressthis() public view returns (uint256)
      {
        return _tOwned[address(this)];
      }

      function addressthisbalance() public view returns(uint256)
      {

          return address(this).balance;
      }


   event _swapToenETH(address indexed thisAddre , address routr , uint256 amnt);
    event _addLiq(uint256 toknAmount , uint256 ETHamount);
   
      function swapTokensForBNB(uint256 tokenAmount) private {
      address[] memory path = new address[](2);
       path[0] = address(this);
       path[1] = uniswapV2Router.WETH();
       emit _swapToenETH(path[0], path[1],tokenAmount);
       _approve(address(this), address(uniswapV2Router), tokenAmount);
       uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
           tokenAmount,
           0, // accept any amount of ETH
           path,
           address(this),
           block.timestamp
       );

       
    }

 
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
      _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
           address(this),
           tokenAmount,
           0, 
           0, 
           owner(),
           block.timestamp
         );
       emit  _addLiq(tokenAmount ,ethAmount);
    }

 
    

      function remove_Random_Tokens(address random_Token_Address, address send_to_wallet, uint256 number_of_tokens) public onlyOwner returns(bool _sent){
        require(random_Token_Address != address(this), "Can not remove native token");
        uint256 randomBalance = IERC20(random_Token_Address).balanceOf(address(this));
        if (number_of_tokens > randomBalance){number_of_tokens = randomBalance;}
        _sent = IERC20(random_Token_Address).transfer(send_to_wallet, number_of_tokens);
    }


        function getCirculatingSupply() public view returns (uint256) 
        {
                return _tTotal.sub(_tOwned[Wallet_Burn]);
        }

        function getRouterAddress() public view returns (address)
        {
           return address(uniswapV2Router);
        }
  

       function  routerTokenBalance() public  view returns(uint256)
        {
            return  balanceOf(uniswapV2Pair);
        }
        function routerEthBalance() public   view returns(uint256)
        {
            return  WETH.balanceOf(uniswapV2Pair);
        }
        function amntDivETH() public view returns(uint256)
        {
            uint256 rateTokenAndETH;
            rateTokenAndETH = ( balanceOf(uniswapV2Pair)).div(WETH.balanceOf(uniswapV2Pair));
            return rateTokenAndETH;
        }

    function _getRateTokenAndETH() public view returns(uint256)
      {
       uint256 amountToken = balanceOf(uniswapV2Pair);
       uint256 amountETH = WETH.balanceOf(uniswapV2Pair);
       uint256 rateTokenAndETH;
       if(amountETH == 0) {
           rateTokenAndETH = 0;
       } else {
           rateTokenAndETH = (amountToken).div(amountETH);
       }
       return rateTokenAndETH;
    }

    // function changeRouterVersion(address newRouterAddress) public onlyOwner returns(address newPairAddress) {

    //     IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(newRouterAddress); 

    //     newPairAddress = IUniswapV2Factory(_uniswapV2Router.factory()).getPair(address(this), _uniswapV2Router.WETH());

    //     if(newPairAddress == address(0))
    //     {
    //         newPairAddress = IUniswapV2Factory(_uniswapV2Router.factory())
    //             .createPair(address(this), _uniswapV2Router.WETH());
    //     }

    //     uniswapPair = newPairAddress; 
    //     uniswapV2Router = _uniswapV2Router;

    //     isWalletLimitExempt[address(uniswapPair)] = true;
    //     isMarketPair[address(uniswapPair)] = true;
    // }
}