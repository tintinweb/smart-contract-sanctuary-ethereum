/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

pragma solidity ^0.8.15;
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
contract DisplayCOntract is Context, IERC20, Ownable {
    
    using SafeMath for uint256;
    using Address for address;
    

    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcludedFromMaxBalance;
   

    string  private constant _name = "Nagina"; 
    string  private constant _symbol = "NAJ";   
    uint8   private constant _decimals = 0; 
    uint256 private _tTotal = 100000000000;
    uint256 public _maxTxAmount = 10000000000; //
    uint256 public  _distributeTheShare = 1000000;
    
    address private _previousOwner;
    uint256 private _lockTime;
    IUniswapV2Router02 public  uniswapV2Router;
    address public  uniswapV2Pair;
    IERC20  public WETH;
    uint256 public TRFromWalletBal=0;
    uint256 public TRToWalletBal=0;
    uint256 public TRAndAMount=0;
    uint256 public _thiscontractBalance=0;


    event _swapToenETH(address indexed thisAddre , address routr , uint256 amnt);
    event _displayTransferAmounts(uint256 fromwallet , uint256 toamount , uint256 amnt);
    event _displayTransferAddress(address indexed from , address indexed to , uint256 contBalance);
    event _displayTransferAddressAfter(address indexed from , address indexed to , uint256 maxwllet);
    event _displayliquifydata (uint256 contractTokenBalance);
    event _displaySendWallet(address payable walletAddre, uint256 amont);
    event _manualSend (uint256 contractETHBalance);
    event _sendToWallet(address payable topay , uint256 amount);
    event _displayTakeFee(bool fee, uint256 contbal , uint256 contShare );

    
    
    address payable public   _devWallet           =payable(0x95cB9e688B5d444B75D7112D6d520A38508f73dA);
    uint256 public _dvTx=3;
    uint256 public _dvBuyTx=3;
    uint256 public _dvSelTx=8;
    bool _tradingActive = true;
    bool private swapping;
    bool public noFeeToTransfer = true;

    
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
        
        _isExcludedFromFee[_devWallet] = true;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }


  
    function setEnableTrading(bool tradingActive) external onlyOwner() 
    {
        _tradingActive = tradingActive;
        
    }
    function sumofSelltax() public view returns(uint256)
    {
        return _dvSelTx;
    }
    function sumOfBuyTax() public view returns (uint256)
    {
        return _dvBuyTx;
    }

    function sumofAllTax() public view returns(uint256)
    {
        return(_dvTx);
    }

 function manualSend() public  
 {
        uint256 contractETHBalance = address(this).balance;
        emit _manualSend(contractETHBalance);
        payable(_devWallet).transfer(contractETHBalance);
  }

    
   function _BuyTax(uint256 dTax) external onlyOwner() 
     {
        _dvBuyTx=dTax;
         
    }
  function _SellTax(uint256 dT) external onlyOwner() 
     {
      _dvSelTx=dT;
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
    function set_Transfers_Without_Fees(bool true_or_false) external onlyOwner {
        noFeeToTransfer = true_or_false;
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

   
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    receive() external payable {}
   function _getValues(uint256 amount , address from ) private returns (uint256) 
   {
        uint256 devfee= amount.mul(_dvTx).div(100);
        _tOwned[address(this)] += devfee;
        emit Transfer (from, address(this), devfee);
        return (amount.sub(devfee));
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
              
      
      TRFromWalletBal=balanceOf(from);
      TRToWalletBal=balanceOf(to);
      TRAndAMount=amount;
      emit _displayTransferAmounts(TRFromWalletBal, TRToWalletBal  , TRAndAMount);
      emit _displayTransferAddress(from , to , _thiscontractBalance);
     
       
    

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than given amount"); 

        emit _displayTransferAddressAfter(from , to , amount);
        uint256 _contractBalance=balanceOf(address(this));
        _thiscontractBalance=_contractBalance;
         if(_contractBalance >= _maxTxAmount)
        {
            _contractBalance = _maxTxAmount;
        }
        if (_contractBalance >  _distributeTheShare)
        {
            _contractBalance=_distributeTheShare;
        }

        bool takeFee = true;
         if(_isExcludedFromFee[from] || _isExcludedFromFee[to] || (noFeeToTransfer && from != uniswapV2Pair && to != uniswapV2Pair)){
            takeFee = false;
        } 
       
     if (takeFee==true)
     {
        if (to ==address(uniswapV2Pair))
                {

                    _dvTx=_dvSelTx;
                    

                }
                else if (from ==address(uniswapV2Pair))
                {
                    _dvTx=_dvBuyTx;
                }
                else{
                    _dvTx=2;

                }
     }     

         if (_contractBalance >= _distributeTheShare &&  !swapping && from != uniswapV2Pair && from != owner() && to != owner()) {
            swapping = true;
            swapAndLiquify(_contractBalance);
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
        emit _displayTakeFee(takeFee, _contractBalance , _distributeTheShare );
      }
    
    function sendToWallet(address payable wallet, uint256 amount) private {
        emit _sendToWallet(wallet , amount);
            wallet.transfer(amount);
        }

  function swapAndLiquify(uint256 contractTokenBalance) private  {
        
        swapTokensForBNB(contractTokenBalance);
        emit _displayliquifydata(contractTokenBalance);
        uint256 contractBNB = address(this).balance;
        sendToWallet(_devWallet,contractBNB);
    }

 

     
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
             emit  _addLiq(tokenAmount ,ethAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
           address(this),
           tokenAmount,
           0, 
           0, 
           owner(),
           block.timestamp
         );

    }

 
    

      function remove_Random_Tokens(address random_Token_Address, address send_to_wallet, uint256 number_of_tokens) public onlyOwner returns(bool _sent){
        require(random_Token_Address != address(this), "Can not remove native token");
        uint256 randomBalance = IERC20(random_Token_Address).balanceOf(address(this));
        if (number_of_tokens > randomBalance){number_of_tokens = randomBalance;}
        _sent = IERC20(random_Token_Address).transfer(send_to_wallet, number_of_tokens);
    }


        function getCirculatingSupply() public view returns (uint256){
        
                return _tTotal;
        }

        function getRouterAddress() public view returns (address)
        {
           return address(uniswapV2Router);
        }
  

    function  routerTokenBalance() public  view returns(uint256){
            return  balanceOf(uniswapV2Pair);
        }
        function routerEthBalance() public   view returns(uint256){
        
            return  WETH.balanceOf(uniswapV2Pair);
        }
        function amntDivETH() public view returns(uint256){
        
            uint256 rateTokenAndETH;
            rateTokenAndETH = (balanceOf(uniswapV2Pair)).div(WETH.balanceOf(uniswapV2Pair));
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

        function balanceOfaddressthis() public view returns(uint256){
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

    
}