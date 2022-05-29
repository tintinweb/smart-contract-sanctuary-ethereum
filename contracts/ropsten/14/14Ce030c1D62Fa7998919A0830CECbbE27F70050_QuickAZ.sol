pragma solidity ^0.8.13;
/**
 *Submitted for verification at BscScan.com on 2022-03-21
*/
// SPDX-License-Identifier: MIT

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
        unchecked 
        {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked 
        {
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

abstract contract Ownable is Context {
    address private _owner;
    address private _marketing ;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () 
    {
      
       //_owner=  0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;   //Local
       _owner=  0x81bE1F2616f12a3a0D1e869211E63568b5A7FFF2;   //testnet
         emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public  view virtual returns (address) { 
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}
contract QuickAZ is Context, IERC20, Ownable
{
    using SafeMath for uint256;
    using Address for address; 
    address private _owner;
    address private _previousOwner;
       

    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public automatedMarketMakerPairs;

    string private  _name = "LIQLN";
    string private  _symbol = "LNQ";
    
    uint8  private  _decimals = 0;
            uint256 private _taxFee = 3;
            uint256 private _previousTaxFee = _taxFee;
            uint256 private _developmentFee = 3;
            uint256 private _previousDevelopmentFee = _developmentFee;
            uint256 private _liquidityFee = 2;
            uint256 private _previousLiquidityFee = _liquidityFee;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    uint256 private _tTotal = 100000 * 10**_decimals;//
    uint256 private numTokensSellToAddToLiquidity = 1000 *10**_decimals;
    uint256 public _maxwalletamount =10000;
    uint256 public _maxTxAmount = 1000000 * 10**_decimals;
  //  address private _marketingAddress = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2; //local
    address private _marketingAddress = 0x95cB9e688B5d444B75D7112D6d520A38508f73dA; //TestNet
    address public constant deadAddress = 0x000000000000000000000000000000000000dEaD;
    IUniswapV2Router02 public  uniswapV2Router;
    address public uniswapV2Pair;
    IERC20 public WETH;
    bool private inSwap = false;
    uint256 public _tokenAmountForMarketingTax;
    uint256 public _tokenAmountForLiquidityTax;
    bool inSwapAndLiquify=true;
    bool public swapAndLiquifyEnabled = true;
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
      constructor ()
     {
       IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
      //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
     //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3 ); 
       
       uniswapV2Router = _uniswapV2Router;
       _approve(address(this), address(uniswapV2Router), _tTotal);
       uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
       IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        _tOwned[owner()]=_tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_marketingAddress] = true;
         emit Transfer(address(0), owner(), _tTotal);
    } 

    receive() external payable {}
     
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
  
    function name() public view  returns (string memory) {
        return _name;
    }

    function symbol() public view  returns (string memory) {
        return _symbol;
    }

    function decimals() public view  returns (uint8) {
        return _decimals;
    }
function setTxLimit(uint256 amount) external onlyOwner { _maxTxAmount = amount.div(100); }

     function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function totalSupply() public view  returns (uint256) {
        return _tTotal;
    }
  
     function balanceOf(address account) public view   returns (uint256) {
        return _tOwned[account];
    }

    function transfer(address recipient, uint256 amount) public   returns (bool)
     {
        
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function contractName() public view returns (address)
    {
        return address(this);

    }

     function contractBalance() public view returns (uint256)
    {
        return address(this).balance;

    }
    function contractBalanceOf() public view  returns (uint256) {
        return  balanceOf(address(this));
    }

      function tOwnedcontractBalance() public view returns (uint256)
    {
        return _tOwned[address(this)];
    }

    
  function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function Pahlaaddress() public view returns (uint256)
    {
        return balanceOf (address(this));
        
        
    }

    function onlyaddress() public view returns (address)
    {
        return address(this);
        
    }
    function getCirculatingSupply() public view returns (uint256) 
    {
            return _tTotal.sub(_tOwned[deadAddress]);
    }

        function getRouterAddress() public view returns (address)
        {

            return address(uniswapV2Router);
        }
  
        function getRouterBalance() public view returns (uint256)
        {
                return address(uniswapV2Router).balance;
        }
    function _transfer(address from,address to,uint256 amount)
       private 
        {
        require(from != address(0), "Sender Account Sould not Zero");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        bool takeFee = true;
         uint256 contractTokenBalance = balanceOf(address(this));
        //    if(_isExcludedFromFee[from] || _isExcludedFromFee[to])
        //    {
        //         takeFee = false;
        //    }

            if (contractTokenBalance >=_maxTxAmount)
            {
                 contractTokenBalance = _maxTxAmount;
            }

           bool  isSwapstarted=contractTokenBalance >=numTokensSellToAddToLiquidity;
            if (isSwapstarted && from != uniswapV2Pair && inSwapAndLiquify &&  swapAndLiquifyEnabled)
            {
                    contractTokenBalance = numTokensSellToAddToLiquidity;
                    swapAndLiquify(contractTokenBalance);
            }
            
           
            //uint256 amountETH;
            //    if (_getRateTokenAndETH() > 0) {
            //        amountETH = (amount * 10 ** _decimals).div(_getRateTokenAndETH());
            //     } else {
            //        amountETH = 0; 
            //    }
            //        emit checkAmountETHBal(amountETH);
            _tokenTransfer(from,to,amount,takeFee);
           
        }
      function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap 
       {
      
         
    //uint256 totalTokenAmount =   _tokenAmountForLiquidityTax + _tokenAmountForMarketingTax ;
    //uint256 tokenForMarketing = contractTokenBalance * (_tokenAmountForMarketingTax) / totalTokenAmount;
    //uint256 tokenForLiquidity = contractTokenBalance * (_tokenAmountForLiquidityTax) / totalTokenAmount;
      
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(half);
        uint256 newBalance = address(this).balance.sub(initialBalance);
        addLiquidity(otherHalf, newBalance);
        emit SwapAndLiquify(half, newBalance, otherHalf);
    
    
    
    //    uint256 tokenAmountForSwap = tokenForMarketing + half; 
    //    swapTokensForEth(tokenAmountForSwap); 

    //    uint256 newBalance = address(this).balance.sub(initialBalance);
    //    uint256 ethForLiquidity = newBalance * half / tokenAmountForSwap;
    //    uint256 ethForMarketing = newBalance * tokenForMarketing / tokenAmountForSwap;
       // transferToAddressETH(payable(_marketingAddress), ethForMarketing.mul(90).div(100));
    //    addLiquidity(otherHalf, ethForLiquidity);
       
    //    _tokenAmountForLiquidityTax = 0;
    //    _tokenAmountForMarketingTax = 0;
    //    emit SwapAndLiquify(half, newBalance, otherHalf);

    }
             

 function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
       function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private 
         {
       
            takeFee=false;
            removeAllFee();
           _transferStandard(sender, recipient, amount);
      
          // if(!takeFee)
             restoreAllFee();
       }
  function  _transferStandard
  (
        address from,
        address to,
        uint256 amount
    ) private {
      //  require(from != address(0), "ERC20: transfer from the zero address");
        //require(to != address(0), "ERC20: transfer to the zero address");
        //require(amount > 0, "Transfer amount must be greater than zero");
        _tOwned[from] -= amount;
        uint256 transferAmount = amount;
        // if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to]){
        //     transferAmount = _getValues(amount);
        // } 
        transferAmount = _getValues(amount);
         _tOwned[to] += transferAmount;
        emit Transfer(from, to, transferAmount);
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

        function _approve(address owner, address spender, uint256 amount) private {
            require(owner != address(0), "ERC20: approve from the zero address");
            require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
            emit Approval(owner, spender, amount);
        }
   function removeAllFee() private  {
   
        if(_taxFee == 0 && _liquidityFee == 0 && _developmentFee==0) return;
        _previousTaxFee = _taxFee;
        _previousDevelopmentFee = _developmentFee;
        _previousLiquidityFee = _liquidityFee;
        _taxFee = 0;
        _developmentFee = 0;
        _liquidityFee = 0;
    }

    function restoreAllFee() private
     {
    
        _taxFee = _previousTaxFee;
        _developmentFee = _previousDevelopmentFee;
        _liquidityFee = _previousLiquidityFee;
    }

 
        function _getValues(uint256 amount) private returns (uint256) 
        {
            _taxFee = amount * _previousTaxFee / 100;
            _developmentFee = amount * _previousDevelopmentFee/100;
            _liquidityFee = amount * _previousLiquidityFee/100;
            _tOwned[address(this)] += _taxFee + _developmentFee +  _liquidityFee;
            return (amount - _taxFee - _developmentFee  - _liquidityFee);
        }

    
          event afterburn (address indexed sender , address indexed deadaddress, uint256 amout);
            function burn (uint56 Amount) external 
            {
            address sender = _msgSender();
            require(sender!=address(0),"Address Needed");
            require(sender != address(deadAddress), "ERC20: burn from the burn address");
            require(_tOwned[sender] >= Amount,"No Token Vailable");
            _tOwned[sender]=_tOwned[sender].sub(Amount);
            _tOwned[deadAddress] = _tOwned[deadAddress].add(Amount);
            emit afterburn (sender ,deadAddress,Amount);
            }
    
            // function transferToAddressETH(address payable recipient, uint256 amount) private 
            // {
            //     recipient.transfer(amount);
            // }

//Liquiduty pair adding start


 
    event _swapToenETH(address indexed thisAddre , address routr , uint256 amnt);
    event _addLiq(uint256 toknAmount , uint256 ETHamount);
    function swapTokensForEth(uint256 tokenAmount) internal {

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


    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) public  {
       _approve(address(this), address(uniswapV2Router), tokenAmount);
       emit _addLiq(tokenAmount, ethAmount);
       uniswapV2Router.addLiquidityETH{value: ethAmount}(
           address(this),
           tokenAmount,
           0, // slippage is unavoidable
           0, // slippage is unavoidable
           owner(),
           block.timestamp
       );
    }

    //   function _getRateTokenAndETH() public view returns(uint256)
    //   {
    //    uint256 amountToken = balanceOf(uniswapV2Pair);
    //    uint256 amountETH = WETH.balanceOf(uniswapV2Pair);
    //    uint256 rateTokenAndETH;
    //    if(amountETH == 0) {
    //        rateTokenAndETH = 0;
    //    } else {
    //        rateTokenAndETH = (amountToken).div(amountETH);
    //    }
    //    return rateTokenAndETH;
    // }
}