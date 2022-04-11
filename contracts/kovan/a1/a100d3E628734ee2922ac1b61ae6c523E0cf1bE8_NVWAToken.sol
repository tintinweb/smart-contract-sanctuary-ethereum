/**
 *Submitted for verification at Etherscan.io on 2022-04-10
*/

/**
 *Submitted for verification at BscScan.com on 2022-02-25
*/
 
// SPDX-License-Identifier: MIT
 
pragma solidity ^0.6.12;
 
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
        return msg.sender;
    }
 
    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
 
library Address {
 
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
    address internal _owner;
 
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 
    function owner() public view returns (address) {
        return _owner;
    }
 
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
 
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
 
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}
 
interface IUniswapV2Router02 {
    function factory() external pure returns (address);
 
    function WETH() external pure returns (address);
 
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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
     function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );
}
 
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }
 
    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }
 
    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
 
    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}
 
contract NVWAToken is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
 
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
 
    mapping (address => bool) private _isExcludedFromFee;
   
    uint256 private _decimals = 18;
    uint256 private _tTotal = 16000 * 10**18;
 
    string private _name = "NVWA";
    string private _symbol = "NVWA";
    
    uint256 public _buyLiquidityFee = 40;
    uint256 public _sellLiquidityFee = 40;
    uint256 public _transferLiquidityFee = 40;
 
    uint256 public _buyBurnFee = 40;
    uint256 public _sellBurnFee = 40;
    uint256 public _transferBurnFee = 40;
 
    uint256 public _sellMarketFee = 50;

 
 
  
 
    uint256 public totalBuyFee = 80;
    uint256 public totalSellFee = 80;
    uint256 public totalTransferFee = 80;
 
    uint256 public transferFee = 80;


    uint256 public validAddrValue = 1;
    uint256[4] internal holdingLimit = [1200*10**18,2500*10**18,5000*10**18,10000*10**18];
 
    //uint256 public sellUpperLimit = 90;
 
   
  
 
    IUniswapV2Router02 public  uniswapV2Router;
    address public  uniswapV2Pair;
 
    mapping(address => bool) public ammPairs;
    
    bool inSwapAndLiquify;
    
    uint256 public _maxTxAmount = 1 * 10**9;
    
    address public wbnb;    
 
    address public holder;
 
    address constant public rootAddress = address(0x000000000000000000000000000000000000dEaD);
    
    mapping (address => address) public _recommerMapping;


    mapping(uint256 => address) public totalUserAddres;

    uint256 public userTotal = 0;

   uint256 public startTime;

 
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor () public {
        
    
        holder = msg.sender;

        _recommerMapping[rootAddress] = address(0xdeaddead);
        _recommerMapping[holder] = rootAddress;
        userTotal++;
        totalUserAddres[userTotal] = holder;
 
        _tOwned[holder] = _tTotal;
        
        startTime = block.timestamp;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
       
        address _uniswapV2Pair  = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        wbnb = _uniswapV2Router.WETH();
      
 
        
        uniswapV2Pair = _uniswapV2Pair;
 
        ammPairs[uniswapV2Pair] = true;
 
        _isExcludedFromFee[holder] = true;
        _isExcludedFromFee[address(this)] = true;
 
        _owner = msg.sender;
 
        emit Transfer(address(0), holder, _tTotal);
    }
   
    function setMaxTx(uint256 maxTx) external onlyOwner{
        _maxTxAmount = maxTx;
    }


    function setViladAddrValue(uint value) external onlyOwner{
        validAddrValue = value;
    }
 

 
    function setAmmPair(address pair,bool hasPair)external onlyOwner{
        ammPairs[pair] = hasPair;
    }
 
    function name() public view returns (string memory) {
        return _name;
    }
 
    function symbol() public view returns (string memory) {
        return _symbol;
    }
 
    function decimals() public view returns (uint256) {
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
    
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
 
    function excludeFromFees(address[] memory accounts) public onlyOwner{
        uint len = accounts.length;
        for( uint i = 0; i < len; i++ ){
            _isExcludedFromFee[accounts[i]] = true;
        }
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    receive() external payable {}
 
    function _take(uint256 tValue,address from,address to) private {
        _tOwned[to] = _tOwned[to].add(tValue);
        emit Transfer(from, to, tValue);
    }
    
    function getForefathers(address owner,uint num) internal view returns(address[] memory fathers){
        fathers = new address[](num);
        address parent  = owner;
        for( uint i = 0; i < num; i++){
            parent = _recommerMapping[parent];
            if( parent == rootAddress || parent == address(0) ) break;
            fathers[i] = parent;
        }
    }
 
    // function _takeShare(uint tShare,address from,address user) private {
 
    //     address[] memory farthers = getForefathers(user,8);
 
    //     uint len = farthers.length;
 
    //     uint sended = 0;
    //     for( uint i = 0; i < len; i++ ){
 
    //         address parent = farthers[i];
 
    //         if( parent == address(0)) break;
 
    //         uint tv = tShare * shareConfig[i] / 70;
 
    //         _tOwned[parent] = _tOwned[parent].add(tv);
    //         emit Transfer(from, parent, tv);
    //         sended += tv;
    //     }  
        
    //     if( tShare > sended ){
    //         _take(tShare - sended,from,marketAddress1);
    //     }
    // }
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
 
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
 
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
 
    function addRelationEx(address recommer,address user) internal {
        if( 
            recommer != user 
            && _recommerMapping[user] == address(0x0) 
            && _recommerMapping[recommer] != address(0x0) ){
                _recommerMapping[user] = recommer;
                userTotal++;
                totalUserAddres[userTotal] = user;
        }       
    }
 
    struct Param{
        bool takeFee;
        uint tTransferAmount;
        uint tLiquidity;
        uint tBurn;
        uint tMarket;
        uint tShare;
        address user;
        address mkAddress;
    }


    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
 
        if( 
            !_isContract(to) 
            && _recommerMapping[to] == address(0) ){
            
            if( ammPairs[from]  ){
                addRelationEx(holder,to);
            }else{
                addRelationEx(from,to);
            }
        }
         
        uint256 contractTokenBalance = balanceOf(address(this));
        
        if( 
            contractTokenBalance >= _maxTxAmount 
            && !inSwapAndLiquify 
            && !ammPairs[from] 
            && IERC20(uniswapV2Pair).totalSupply() > 1000 ){
 
            swapAndLiquify(contractTokenBalance);
        }
        
        bool takeFee = true;
 
        if( _isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        
        Param memory param;
 
        if( takeFee ){
           param.takeFee = true;
           if( ammPairs[from]){
               _getBuyParam(amount,param);
               param.user = to;
             
    

                    require((balanceOf(to) + amount) < holdingLimit[validAddrValue],"hold more than the limit");

       
              
           }
 
           if( ammPairs[to]){
                _getSellParam(amount,param);
               param.user = from;
              

           
             
           }
 
           if( !ammPairs[from] && !ammPairs[to]){
                _getTransferParam(amount,param);
                param.user = to;
                require((balanceOf(to) + amount) < holdingLimit[validAddrValue],"hold more than the limit");

           }
        }else{
            param.tTransferAmount = amount;
        }
 
   
        _tokenTransfer(from,to,amount,param);
    }
 

 
    function _getBuyParam(uint256 tAmount,Param memory param) private view  {
        param.tLiquidity = tAmount * _buyLiquidityFee / 1000;
        param.tBurn = tAmount * _buyBurnFee / 1000;
        // param.tShare = tAmount * _shareFee / 1000;
        uint tFee = tAmount * totalBuyFee / 1000;
        param.tTransferAmount = tAmount.sub(tFee);
    }
 
    function _getSellParam(uint256 tAmount,Param memory param) private view  {
        // param.tMarket = tAmount * _sellMarketFee / 1000;
        param.tLiquidity = tAmount * _sellLiquidityFee / 1000;
        param.tBurn = _sellBurnFee / 1000;
        uint tFee = tAmount * totalSellFee / 1000;
        param.tTransferAmount = tAmount.sub(tFee);
    }
 
    function _getTransferParam(uint256 tAmount,Param memory param) private view {
        // param.tMarket = tAmount * transferFee / 1000;
        // param.mkAddress = marketAddress3;
        // param.tTransferAmount = tAmount.sub(param.tMarket);
        param.tLiquidity = tAmount * _transferLiquidityFee / 1000;
        param.tBurn = tAmount * _transferBurnFee / 1000;
        // param.tShare = tAmount * _shareFee / 1000;
        uint tFee = tAmount * totalTransferFee / 1000;
        param.tTransferAmount = tAmount.sub(tFee);
    }
 
    function swapAndLiquify(uint256 contractTokenBalance) private  lockTheSwap{
        
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);
 
        uint256 initialBalance = address(this).balance;
 
        swapTokensForEth(half,address(this)); 
 
        uint256 newBalance = address(this).balance.sub(initialBalance);
 
        addLiquidity(otherHalf, newBalance);
    }
 
    function swapTokensForEth(uint256 tokenAmount,address to) private {
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = wbnb;
 
        _approve(address(this), address(uniswapV2Router), tokenAmount);
 
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            to,
            block.timestamp
        );
    }
 
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        
        _approve(address(this), address(uniswapV2Router), tokenAmount);
 
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            holder,
            block.timestamp
        );
    }
 
    function _takeFee(Param memory param,address from)private {
        if( param.tBurn > 0 ){
            _take(param.tBurn, from, address(0));
        }
        if( param.tLiquidity > 0 ){
            _take(param.tLiquidity, from, address(this));
        }
        // if( param.tMarket > 0 ){
        //     _take(param.tMarket, from, param.mkAddress);
        // }
        // if( param.tShare > 0 ){
        //      _takeShare(param.tShare,from,param.user);
        // }
    }
 
    function _tokenTransfer(address sender, address recipient, uint256 tAmount,Param memory param) private {
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _tOwned[recipient] = _tOwned[recipient].add(param.tTransferAmount);
         emit Transfer(sender, recipient, param.tTransferAmount);
        if(param.takeFee){
            _takeFee(param,sender);
        }
    }
 
    function donateDust(address addr, uint256 amount) external onlyOwner {
        TransferHelper.safeTransfer(addr, _msgSender(), amount);
    }
 
    function donateEthDust(uint256 amount) external onlyOwner {
        TransferHelper.safeTransferETH(_msgSender(), amount);
    }
 
     function _isContract(address a) internal view returns(bool){
        uint256 size;
        assembly {size := extcodesize(a)}
        return size > 0;
    }
    
 
}