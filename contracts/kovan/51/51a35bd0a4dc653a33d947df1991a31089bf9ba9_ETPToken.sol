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


interface ETC {
    function totalSupply() external view returns (uint256);
 
    function balanceOf(address account) external view returns (uint256);
 
    function transfer(address recipient, uint256 amount) external returns (bool);
 
    function allowance(address owner, address spender) external view returns (uint256);
 
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function casting(uint256 taxes,address _caller)  external  returns(bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
 
    event Approval(address indexed owner, address indexed spender, uint256 value);

}





interface fomo {
    function deposit(address _user) external;
    function getFomo(address _user) external view returns(uint _bonus,uint _award,uint _expiration);
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
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
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


    function getAmountsOut(uint amountIn, address[] memory path)
        external
        view returns  (uint[] memory amounts);
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



interface DAOPoolDividend {
    function countDaoUsdtIn(uint256 usdtValue_) external ;
    event countDaoUsdtInLog(address indexed caller_, uint256 usdtValue_,uint256 days_);
}

interface LpPoolDividend{
    function countLpUsdtIn(uint256 usdtValue_) external ;
    event countLpUsdtInLog(address indexed caller_,uint256 usdtValue_,uint256 days_);

}
 
contract ETPToken is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
 
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
 
    mapping (address => bool) private _isExcludedFromFee;
   
    uint256 private _decimals = 18;
    uint256 private _tTotal = 100000000 * 10**18;
 
    string private _name = "ETP";
    string private _symbol = "ETP";
    
    // uint256 public _buyFee = 80;
    mapping(uint256 => uint256) public _buyFee;
    // uint256 public _sellFee = 90;
    mapping(uint256 => uint256) public _sellFee;

    uint256 public PERSENT =  1000;

    uint256 public feeRate = 1;
    bool public isUpdateFeeRate = true;


 
    // uint256 public _buyBurnFee = 30;
    // uint256 public _sellBurnFee = 30;


    mapping(uint256 => uint256 ) public etpPriceOrical;
   
    // uint256 public validAddrValue = 0;
    
 
    //uint256 public sellUpperLimit = 90;
 
   
  
 
    IUniswapV2Router02 public  uniswapV2Router;
    address public  uniswapV2Pair;
 
    mapping(address => bool) public ammPairs;
    
    bool inSwapAndLiquify;
    
    // uint256 public _maxTxAmount = 1 * 10**9;
    
    address public usdt;    
 
    address public holder;
 
    address constant public rootAddress = address(0x000000000000000000000000000000000000dEaD);
    
    mapping (address => address) public _recommerMapping;




    mapping(uint256 => address) public totalUserAddres;

    uint256 public userTotal = 0;

   uint256 public startTime;
   uint256 private startTime_utc8;

   uint256 public superNodeAmount = 0;
   uint256 public nodeAmount = 0 ;

    //============ update ==============
   address public daoAddress = 0xEa1E0FdD85205fdf1D637F9D14336Bb3b362ecAc;
   address public etcPoolAddress = 0xEa1E0FdD85205fdf1D637F9D14336Bb3b362ecAc;
   address public lpPoolAddress = 0xEa1E0FdD85205fdf1D637F9D14336Bb3b362ecAc;
   address public fom3dAddress = 0xEa1E0FdD85205fdf1D637F9D14336Bb3b362ecAc;
   //============ update ===============
   
    address public lpPoolContractAddress;
    address public daoContractAddress;
  
    address public busd;

   bool public swapLock = true;
    mapping(address => bool) public    whitelist;

 
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }



    constructor (
        address usdt_
    )  {

    
        holder = msg.sender;         
        _recommerMapping[rootAddress] = address(0xdeaddead);
        _recommerMapping[holder] = rootAddress;
        userTotal++;
        totalUserAddres[userTotal] = holder;
 
        _tOwned[holder] = _tTotal;
        
        startTime = block.timestamp;
        startTime_utc8 = startTime.div(1 days).mul(1 days);

        whitelist[holder] =  true;

      
        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xcaa594A2Ac434e36e5D10a41aEe4a932EB52363B);
        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        busd = usdt_;

        // IERC20(busd).approve(address(this),1e36);

        //==================== update ==========================================
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        address _uniswapV2Pair  = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), busd);

        daoAddress = 0xEa1E0FdD85205fdf1D637F9D14336Bb3b362ecAc;         //dao usdt mananger asset(in)
        lpPoolAddress = 0xEa1E0FdD85205fdf1D637F9D14336Bb3b362ecAc;      // lppool usdt manager asset(in)    
        

        lpPoolContractAddress = 0x388D329f6B1Cc7B7cf696dB87E5f203775a77E35;   //lp dividend contract 
        daoContractAddress = 0x586c8483062FB260630078617F3a08A745dc2336;        //dao dividend contract

        etcPoolAddress = 0xEa1E0FdD85205fdf1D637F9D14336Bb3b362ecAc;    //etc token contract
        fom3dAddress = 0xEa1E0FdD85205fdf1D637F9D14336Bb3b362ecAc;     //fomo3d contract
      
        //==================== update ==========================================
        
        uniswapV2Pair = _uniswapV2Pair;
 
        ammPairs[uniswapV2Pair] = true;
 
        _isExcludedFromFee[holder] = true;
        _isExcludedFromFee[address(this)] = true;
        // _isExcludedFromFee[address(_uniswapV2Router)] = true;
        

        // address[] memory accounts_ = new address[](6);
        // accounts_[0] = daoAddress;
        // accounts_[1] = lpPoolAddress;
        // accounts_[2] = lpPoolContractAddress;
        // accounts_[3] = daoContractAddress;
        // accounts_[4] = etcPoolAddress;
        // accounts_[5] = fom3dAddress;
        // excludeFromFees(accounts_);
       
        _owner = msg.sender;

        _buyFee[1] =80;
        _buyFee[2] =160;
        _buyFee[0] = 0 ;
        _sellFee[1] = 90;
        _sellFee[2] =180;
        _sellFee[2] =270;

        emit Transfer(address(0), holder, _tTotal);
    }


    function setUsdtAddress(address usdt_) public onlyOwner{
        busd = usdt_;
    }

    function setisUpdateFeeRate() public onlyOwner{
        if(isUpdateFeeRate){
            isUpdateFeeRate = false;
        }else{
            isUpdateFeeRate = true;
        }
        
    }

    function setFeeRate(uint256 n_) public onlyOwner{
        feeRate = n_;
    }

    function setlpPoolContractAddress(address lpPoolContractAddress_)public onlyOwner{
        lpPoolContractAddress = lpPoolContractAddress_;
        excludeFromFee(lpPoolContractAddress);

    }

    function setdaoContractAddress(address daoContractAddress_)public onlyOwner{
        daoContractAddress = daoContractAddress_;

    }

    function setSuperAddress(address snaddr) external onlyOwner{
        daoAddress = snaddr;
    }
    function setdaoAddress(address naddr) external onlyOwner{
        daoAddress = naddr;
    }

    function setEtcPoolAddress(address etcPoolAddress_) public onlyOwner{
        etcPoolAddress = etcPoolAddress_;
    }

    function setlpPoolAddress(address lpPoolAddress_) public onlyOwner{
        lpPoolAddress = lpPoolAddress_;
    }

    function setfom3dAddress (address fom3dAddress_) public onlyOwner{
        fom3dAddress = fom3dAddress_;
        excludeFromFee(fom3dAddress_);
    }



    function setWhilteList(address _addr) external onlyOwner{
        whitelist[_addr] =  true;

    }
   
 
    function setSwapLock ()  external onlyOwner{
        if(swapLock){
            swapLock = false;
        }else{
             swapLock = true;
        }
    }


    function getDay() public view returns (uint256) {
        return (block.timestamp - startTime)/1 days;
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
 
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
 
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
 
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
 

    event burn(address indexed from,address  to,uint256 amount);

    event log(address indexed user,address to, uint256 id,uint256 value,string s_);
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
   
         
      
        
        uint256 pretBalanceU = IERC20(busd).balanceOf(holder);
        
        bool takeFee = true;
 
        if( _isExcludedFromFee[from] || _isExcludedFromFee[to] || from ==  address(uniswapV2Router)){
            takeFee = false;
        }
              

        
        uint256 tTransferAmount;
        emit log(from, to,1,amount,"mairu");
 
         if( takeFee ){           
           if( ammPairs[from]){  // buy or removeLiquidity

                uint256 day_ =  block.timestamp.sub(startTime_utc8).div(1 days);
                etpPriceOrical[day_] = getETPPrice(1e18);

                if(getETPPrice(amount) > 100e18){
                    fomo(fom3dAddress).deposit(to);
                }

                uint256 feeValue = amount.mul(_buyFee[feeRate]).div(PERSENT);

                tTransferAmount = amount.sub(feeValue);

               
               emit log(from, to,2,feeValue,"mairu");
                if(feeValue > 0 ){

                    _takeFee(to,feeValue);

                    // swapTokensForTokens(feeValue,holder);
                    // uint256 curenttBalanceU = IERC20(busd).balanceOf(holder);


                    // uint256 balU =  curenttBalanceU.sub(pretBalanceU);
                    
                    // IERC20(busd).transferFrom(holder,address(this),balU); 




                    // TransferHelper.safeTransfer(busd,etcPoolAddress,balU.mul(6).div(8));

                    
                    // if(!_isContract(to)){
                    //     ETC(etcPoolAddress).casting(balU.mul(6).div(8),to);
                    // }


                    // IERC20(busd).transfer(daoAddress,balU.mul(1).div(8));
                    // IERC20(busd).transfer(lpPoolAddress,balU.mul(1).div(8));



                    // LpPoolDividend(lpPoolContractAddress).countLpUsdtIn(balU.mul(1).div(8));
                    // DAOPoolDividend(daoContractAddress).countDaoUsdtIn(balU.mul(1).div(8));


                }

               


                if(feeRate != 1 && day_ > 0){
                    if(etpPriceOrical[day_] >= etpPriceOrical[(day_-1)] && isUpdateFeeRate){
                        
                        feeRate = 1;
                    }else{                     
                       if(etpPriceOrical[day_.sub(1)].mul(80).div(100) < etpPriceOrical[day_] && isUpdateFeeRate){
                          feeRate = 1; 
                       }
                    }
                }
                
 

           }
        //    else{
 
           if( ammPairs[to]){//sell or addLiquidity
                uint256 day_ =  block.timestamp.sub(startTime_utc8).div(1 days);
                etpPriceOrical[day_] = getETPPrice(1e18);

                uint256 feeValue = amount.mul(_sellFee[feeRate]).div(PERSENT);

                _takeFee(from,feeValue);
               
               
                tTransferAmount = amount.sub(feeValue);

                swapTokensForTokens(feeValue,holder);
                uint256 curenttBalanceU_ = IERC20(busd).balanceOf(holder);
                uint256 balU_ =  curenttBalanceU_.sub(pretBalanceU);
                IERC20(busd).transferFrom(holder,address(this),balU_); 

                if(feeRate == 3){
                    TransferHelper.safeTransfer(busd,etcPoolAddress,balU_);
                }else{
                    TransferHelper.safeTransfer(busd,etcPoolAddress,balU_.mul(6).div(9));

                    
                    if(!_isContract(to)){
                        ETC(etcPoolAddress).casting(balU_.mul(6).div(9),to);
                        
                    }

                    IERC20(busd).transfer(daoAddress,balU_.mul(1).div(9));
                    IERC20(busd).transfer(lpPoolAddress,balU_.mul(1).div(9));
                
                    TransferHelper.safeTransfer(busd,fom3dAddress,balU_.mul(1).div(9));


                    LpPoolDividend(lpPoolContractAddress).countLpUsdtIn(balU_.mul(1).div(9));
                    DAOPoolDividend(daoContractAddress).countDaoUsdtIn(balU_.mul(1).div(9));
                    
                }
                if(day_ > 0 ){
                    uint256 priceDown80 =  etpPriceOrical[day_.sub(1)].mul(80).div(100); 
                    uint256 priceDown40 =  etpPriceOrical[day_.sub(1)].mul(60).div(100); 
                    if(etpPriceOrical[day_] < priceDown40){
                        if(feeRate != 3 && isUpdateFeeRate){
                            feeRate= 3;
                        }
                    }else if(etpPriceOrical[day_] <  priceDown80){
                         if(feeRate != 2 && isUpdateFeeRate){
                            feeRate= 2;
                        }
                    }
                }   

           }
 
           if( !ammPairs[from] && !ammPairs[to]){

                
                tTransferAmount = amount.mul(91).div(100);
              
                if(balanceOf(address(0)) < _tTotal.mul(99).div(100)){
                    _tOwned[address(0)] = _tOwned[address(0)].add(amount.mul(9).div(100));
                    emit burn(from,to,amount.mul(9).div(100));
                }
           }
        }else{
            tTransferAmount = amount;      
        }
        _tokenTransfer(from,to,amount,tTransferAmount);
    }
 

 
    function swapTokensForTokens(uint256 tokenAmount,address to) private {
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = busd;
 
        _approve(address(this), address(uniswapV2Router), tokenAmount);
       
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            to,
            block.timestamp
        );
    }
 
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        IERC20(busd).approve(address(uniswapV2Router),ethAmount);
        // uint256 hb = IERC20(busd).balanceOf(holder);
        IERC20(busd).transferFrom(holder,address(this), ethAmount);
       

        uniswapV2Router.addLiquidity(
            address(this),
            busd,
            tokenAmount,
            ethAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            holder,
            block.timestamp
        );
    }
    



    function getETPPrice(uint total) public view returns (uint amount1){

            address[] memory path = new address[](2);
           
            path[0] = address(this);
            path[1] = busd;

            uint[] memory amounts  = uniswapV2Router.getAmountsOut(total,path);

            return amounts[1];
        
    }   

 
    function _tokenTransfer(address sender, address recipient, uint256 tAmount,uint256 _tTransferAmount) private {
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _tOwned[recipient] = _tOwned[recipient].add(_tTransferAmount);
         emit Transfer(sender, recipient,_tTransferAmount);
    }

    event TakeFeeLog(address indexed sender,uint256 feeValue);
    function _takeFee(address sender,uint256 fee_) private{
         _tOwned[address(this)] = _tOwned[address(this)].add(fee_);
         emit TakeFeeLog(sender,fee_);
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