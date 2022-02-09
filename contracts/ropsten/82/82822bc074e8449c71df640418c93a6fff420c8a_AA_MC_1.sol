/**
 *Submitted for verification at Etherscan.io on 2022-02-08
*/

// SPDX-License-Identifier: Unlicensed 
// "Unlicensed" is NOT Open Source 
// This contract can not be used/forked without permission 

pragma solidity 0.8.10;


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
    function decimals() external pure returns (uint256);
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






contract AA_MC_1 is Context, IERC20 { 
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => uint256) private _swapCount;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isExcludedFromFee; 
    mapping (address => bool) public _isExcluded; 
    mapping (address => bool) public _isSnipe;
    mapping (address => bool) public _preLaunchAccess;
    mapping (address => bool) public _limitExempt;
    mapping (address => bool) public _isPair;


    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   
    
    function owner() public view virtual returns (address) {
        return _owner;
    }


    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }





    // Safe launch protocols
    bool public launchPhase = true;
    bool public TradeOpen = true;  //XXXX 


    address[] private _excluded; // Excluded from rewards
    address payable public Wallet_Marketing = payable(0x406D07C7A547c3dA0BAcFcC710469C63516060f0); // XXXXXXXXXX
    address payable public Wallet_Dev1 = payable(0x406D07C7A547c3dA0BAcFcC710469C63516060f0); // Solidity Developer 
    address payable public Wallet_Dev2 = payable(0x406D07C7A547c3dA0BAcFcC710469C63516060f0); // Marketing Team
    address payable public Wallet_CakeLP = payable(0x406D07C7A547c3dA0BAcFcC710469C63516060f0); //  XXXXXXXX
    address payable public constant Wallet_Burn = payable(0x000000000000000000000000000000000000dEaD); 
    address payable public constant Wallet_swapCount = payable(0x0123447F813F9AB49cf749ad57CdD2051A6C4604); // Swap Counter Wallet
    

    
    uint256 private constant MAX = ~uint256(0);
    uint256   private constant _decimals = 9;
    uint256 private _tTotal = 10**12 * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    string  private constant _name = "AA_MC_1"; 
    string  private constant _symbol = "AA_MC_1";  


    // Setting the initial fees
    uint256 public _FeeReflection = 2; 
    uint256 public _FeeLiquidity = 1;
    uint256 public _FeeMarketing = 6;
    uint256 public _FeeDev = 1; 

    uint256 public constant _FeeMaxPossible = 20;

    // 'Previous fees' are used to keep track of fee settings when removing and restoring fees
    uint256 private _previousFeeReflection = _FeeReflection;
    uint256 private _previousFeeLiquidity = _FeeLiquidity;
    uint256 private _previousFeeMarketing = _FeeMarketing;
    uint256 private _previousFeeDev = _FeeDev; 

    // The following settings are used to calculate fee splits when distributing Eth to liquidity and external wallets
    uint256 private _promoFee = _FeeMarketing+_FeeDev;
    uint256 public _FeesTotal = _FeeMarketing+_FeeDev+_FeeLiquidity+_FeeReflection;

    // Fee for the auto LP and the all Eth wallets - used to process fees 
    uint256 private _liquidityAndPromoFee = _FeeMarketing+_FeeDev+_FeeLiquidity;


    uint256 private rReflect; // Reflections
    uint256 private rLiquidity; // Includes LP and Marketing Fees
    uint256 private rTransferAmount; // After deducting fees
    uint256 private rAmount; // Total tokens sent for transfer

    uint256 private tReflect; // Reflections
    uint256 private tLiquidity; // Includes LP and Marketing Fees
    uint256 private tTransferAmount; // After deducting fees


    /*

    Max wallet holding is limited to 0.05% for the first block - Anti Snipe

    */

    // Max wallet holding  (0.05% at launch)
    uint256 public _max_Hold_Tokens = _tTotal*5/10000;

    // Maximum transaction 0.5% 
    uint256 public _max_Tran_Tokens = _tTotal/200;

    // Max tokens for swap 0.5%
    uint256 public _max_Swap_Tokens = _tTotal/200;


    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    bool public inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
        
    );
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor () {

        _owner = 0x627C95B6fD9026E00Ab2c373FB08CC47E02629a0;
        emit OwnershipTransferred(address(0), _owner);

        _rOwned[owner()] = _rTotal;
        
        //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // MAINNET BSC
        //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); // TESTNET BSC
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // ETH
      

        // Create Pair
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;


        /*

        Set initial wallet mappings

        */

        // Wallet that are excluded from fees
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[Wallet_Marketing] = true; 
        _isExcludedFromFee[Wallet_Burn] = true;

        // Wallets that are not restricted by transaction and holding limits
        _limitExempt[owner()] = true;
        _limitExempt[Wallet_Burn] = true;
        _limitExempt[Wallet_Marketing] = true; 

        // Wallets granted access before trade is oopen
        _preLaunchAccess[owner()] = true;

        // Exclude from Rewards
        _isExcluded[Wallet_Burn] = true;
        _isExcluded[uniswapV2Pair] = true;
        _isExcluded[address(this)] = true;

        _excluded.push(Wallet_Burn);
        _excluded.push(uniswapV2Pair);
        _excluded.push(address(this));


        // Set up uniswapV2 address
        _limitExempt[uniswapV2Pair] = true;
        _isPair[uniswapV2Pair] = true; //XXX

        emit Transfer(address(0), owner(), _tTotal);
    }


    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint256) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
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

    function allowance(address theOwner, address spender) external view override returns (uint256) {
        return _allowances[theOwner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) external view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }

    function transferOwnership(address newOwner) external onlyOwner {

        // can't be zero address
        require(newOwner != address(0), "Ownable: new owner is the zero address");

        // remove old mappings
        _isExcludedFromFee[owner()] = false;
        _limitExempt[owner()] = false;
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;

        // Update new mappings
        _isExcludedFromFee[owner()] = false;
        _limitExempt[owner()] = false;
    }


    /*
    
    When sending tokens to another wallet (not buying or selling) if noFeeToTransfer is true there will be no fee

    */

    bool public noFeeToTransfer = true;
        
    
    event E_noFeeToTransfer(bool true_or_false);
    function set_Transfers_Without_Fees(bool true_or_false) external onlyOwner {
        noFeeToTransfer = true_or_false;
        emit E_noFeeToTransfer(true_or_false);
    }

    




    function tokenFromReflection(uint256 _rAmount) public view returns(uint256) {
        require(_rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return _rAmount.div(currentRate);
    }









    /*

    Swap Counter set up

    */

    function checkSwap(address account) internal view returns (uint256) {
       return _swapCount[account];
    }

    // Update the number of transactions needed to trigger swap
    event E_Swap_Trigger_Count(uint256 swapTrigger);
    function Swap_Trigger_Count(uint256 number_of_transactions) external onlyOwner {

        // Add 1 due to reset of mapping counter being 1 not 0 (to reduce gas on next allocation)
        swapTrigger = number_of_transactions + 1;
        emit E_Swap_Trigger_Count(swapTrigger);
    }

    uint256 public swapTrigger = 2; // Number of transactions with a fee until swap is triggered  XXXXX













    /*

    Address Mappings

    */


    // Limit except - used to allow a wallet to hold more than the max limit - for locking tokens etc
    event E_limitExempt(address account, bool true_or_false);
    function mapping_limitExempt(address account, bool true_or_false) external onlyOwner() {    
        _limitExempt[account] = true_or_false;
        emit E_limitExempt(account, true_or_false);
    }

    // Pre Launch Access - able to buy and sell before the trade is open 
    event E_preLaunchAccess(address account, bool true_or_false);
    function mapping_preLaunchAccess(address account, bool true_or_false) external onlyOwner() {    
        _preLaunchAccess[account] = true_or_false;
        emit E_preLaunchAccess(account, true_or_false);
    }

    // Add wallet to snipe list 
    event E_isSnipe(address account, bool true_or_false);
    function mapping_isSnipe(address account, bool true_or_false) external onlyOwner() {  
        _isSnipe[account] = true_or_false;
        emit E_isSnipe(account, true_or_false);
    }

    // Set as pair 
    event E_isPair(address wallet, bool true_or_false);
    function mapping_isPair(address wallet, bool true_or_false) external onlyOwner {
        _isPair[wallet] = true_or_false;
        emit E_isPair(wallet, true_or_false);
    }





    /*

    "OUT OF GAS" LOOP WARNING!

    Wallets that are excluded from rewards need to be added to an array.
    Many function need to loop through this array - This requires gas!
    If too many wallets are excluded from rewards there is a risk on an 'Out of Gas' error

    ONLY exclude wallets if absolutely necessary

    Wallets that should be excluded - Tokens added to lockers, contract address, burn address. 

    */

    // Wallet will not get reflections
    event E_ExcludeFromRewards(address account);
    function Rewards_Exclude_Wallet(address account) external onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
        emit E_ExcludeFromRewards(account);
    }





    // Wallet will get reflections - DEFAULT
    event E_IncludeInRewards(address account);
    function Rewards_Include_Wallets(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
        emit E_IncludeInRewards(account);
    }
    




    

    // Set a wallet address so that it does not have to pay transaction fees
    event E_ExcludeFromFee(address account);
    function Fees_Exclude_Wallet(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
        emit E_ExcludeFromFee(account);
    }
    
    // Set a wallet address so that it has to pay transaction fees - DEFAULT
    event E_IncludeInFee(address account);
    function Fees_Include_Wallet(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
        emit E_IncludeInFee(account);
    }




    

    
    /*

    FEES  

    */

    event E_set_Fees(uint256 Liquidity, uint256 Marketing, uint256 Reflection);
    event E_Total_Fee(uint256 _FeesTotal);


    function _set_Fees(uint256 Liquidity, uint256 Marketing, uint256 Reflection) external onlyOwner() {

        // Buyer protection - The fees can never be set above the max possible
        require((Liquidity+Marketing+Reflection+_FeeDev) <= _FeeMaxPossible, "Total fees set to high!");

        // Set the fees
          _FeeLiquidity = Liquidity;
          _FeeMarketing = Marketing;
          _FeeReflection = Reflection;

        // For calculations and processing 
          _promoFee = _FeeMarketing + _FeeDev;
          _liquidityAndPromoFee = _FeeLiquidity + _promoFee;
          _FeesTotal = _FeeMarketing + _FeeDev + _FeeLiquidity + _FeeReflection;

        emit E_set_Fees(Liquidity,Marketing,Reflection);
        emit E_Total_Fee(_FeesTotal);

    }




    
    /*

    Updating Wallets

    */


    event E_Wallet_Update_Marketing(address indexed oldWallet, address indexed newWallet);
    event E_Wallet_Update_Dev1(address indexed oldWallet, address indexed newWallet);
    event E_Wallet_Update_Dev2(address indexed oldWallet, address indexed newWallet);
    event E_Wallet_Update_CakeLP(address indexed oldWallet, address indexed newWallet);
    

    //Update the marketing wallet
    function Wallet_Update_Marketing(address payable wallet) external onlyOwner() {
        // Can't be zero address
        require(wallet != address(0), "new wallet is the zero address");

        // Update mapping on old wallet
        _isExcludedFromFee[Wallet_Marketing] = false; 
        _limitExempt[Wallet_Marketing] = false;
        emit E_Wallet_Update_Marketing(Wallet_Marketing,wallet);
        Wallet_Marketing = wallet;
        // Update mapping on new wallet
        _isExcludedFromFee[Wallet_Marketing] = true;
        _limitExempt[Wallet_Marketing] = true;
    }

    //Update the Dev1 Wallet - Solidity developer
    function Wallet_Update_Dev1(address payable wallet) external {
        require(wallet != address(0), "new wallet is the zero address");
        require(msg.sender == Wallet_Dev1, "Only the owner of this wallet can update it");
        emit E_Wallet_Update_Dev1(Wallet_Dev1,wallet);
        Wallet_Dev1 = wallet;
    }

    //Update the Dev2 Wallet - Marketing Team
    function Wallet_Update_Dev2(address payable wallet) external {
        require(wallet != address(0), "new wallet is the zero address");
        require(msg.sender == Wallet_Dev2, "Only the owner of this wallet can update it");
        emit E_Wallet_Update_Dev2(Wallet_Dev2,wallet);
        Wallet_Dev2 = wallet;
    }

    //Update the cake LP wallet
    function Wallet_Update_CakeLP(address payable wallet) external onlyOwner() {
        // To send Cake LP tokens, update this wallet to 0x000000000000000000000000000000000000dEaD
        require(wallet != address(0), "new wallet is the zero address");
        emit E_Wallet_Update_CakeLP(Wallet_CakeLP,wallet);
        Wallet_CakeLP = wallet;
    }

   
    
    /*

    SwapAndLiquify Switches

    */

    event E_SwapAndLiquifyEnabledUpdated(bool true_or_false);
    // Toggle on and off to activate auto liquidity and the promo wallet 
    function set_Swap_And_Liquify_Enabled(bool true_or_false) external onlyOwner {
        swapAndLiquifyEnabled = true_or_false;
        emit E_SwapAndLiquifyEnabledUpdated(true_or_false);
    }



    // This function is required so that the contract can receive Eth from pancakeswap
    receive() external payable {}
    



    /*

    Wallet Limits

    Wallets are limited in two ways. The amount of tokens that can be purchased in one transaction
    and the total amount of tokens a wallet can buy. Limiting a wallet prevents one wallet from holding too
    many tokens, which can scare away potential buyers that worry that a whale might dump!

    max_Swap_Tokens sets the maximum amount of tokens that the contract can swap during swap and liquify. 


    */

    // Wallet Holding and Transaction Limits

    event E_max_Tran_Tokens(uint256 _max_Tran_Tokens);
    event E_max_Hold_Tokens(uint256 _max_Hold_Tokens);

    function set_Limits_For_Wallets(

        uint256 max_Tran_Tokens,
        uint256 max_Hold_Tokens,
        uint256 max_Swap_Tokens

        ) external onlyOwner() {

        require(max_Hold_Tokens > 0, "Must be greater than zero!");
        require(max_Tran_Tokens > 0, "Must be greater than zero!");
        
        _max_Hold_Tokens = max_Hold_Tokens * 10**_decimals;
        _max_Tran_Tokens = max_Tran_Tokens * 10**_decimals;
        _max_Swap_Tokens = max_Swap_Tokens * 10**_decimals;

        emit E_max_Tran_Tokens(_max_Hold_Tokens);
        emit E_max_Hold_Tokens(_max_Tran_Tokens);

    }

  

    uint256 private launchBlock;


    
    // Open Trade - ONE WAY SWITCH! - Buyer Protection! 

    event E_openTrade(bool TradeOpen);
    function openTrade() external onlyOwner() {
        TradeOpen = true;
        launchBlock = block.number;
        emit E_openTrade(TradeOpen);

    }




    // End Launch Phase 

    event E_end_LaunchPhase(bool launchPhase);
    function end_LaunchPhase() external onlyOwner() {
        launchPhase = false;
        emit E_end_LaunchPhase(launchPhase);

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
    




    // Take the tokens for Liquidity and Marketing

    function _takeLiquidity(uint256 _tLiquidity, uint256 _rLiquidity) private {
        _rOwned[address(this)] = _rOwned[address(this)].add(_rLiquidity);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(_tLiquidity);
    }




    // Take the tokens for RFI Rewards

    function _takeReflection(uint256 _tReflect, uint256 _rReflect) private {
        _rTotal = _rTotal.sub(_rReflect);
        _tFeeTotal = _tFeeTotal.add(_tReflect);
    }
    





    // Remove all fees

    function removeAllFee() private {
        if(_FeeReflection == 0 && _FeeLiquidity == 0 && _FeeMarketing == 0 && _FeeDev == 0) return;
        
        _previousFeeReflection = _FeeReflection;
        _previousFeeLiquidity = _FeeLiquidity;
        _previousFeeMarketing = _FeeMarketing;
        _previousFeeDev = _FeeDev;
        
        _FeeReflection = 0;
        _liquidityAndPromoFee = 0;
        _FeeLiquidity = 0;
        _FeeMarketing = 0;
        _FeeDev = 0;
        _promoFee = 0;
        _FeesTotal = 0;
    }
    
    // Restore all fees

    function restoreAllFee() private {

        _FeeReflection = _previousFeeReflection;
        _FeeLiquidity = _previousFeeLiquidity;
        _FeeMarketing = _previousFeeMarketing;
        _FeeDev = _previousFeeDev;

        _FeesTotal = _FeeMarketing+_FeeDev+_FeeLiquidity+_FeeReflection;
        _promoFee = _FeeMarketing+_FeeDev;
        _liquidityAndPromoFee = _FeeMarketing+_FeeDev+_FeeLiquidity;
    }




    function _approve(address theOwner, address spender, uint256 amount) private {

        require(theOwner != address(0) && spender != address(0), "ERR: zero address");
        _allowances[theOwner][spender] = amount;
        emit Approval(theOwner, spender, amount);

    }



    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {


        if (!TradeOpen){
            require(_preLaunchAccess[from] || _preLaunchAccess[to], "Trade is not open yet, please come back later");
        }





        /*

        LAUNCH PHASE 

        */

        // Blocks snipe bots for first 20 Blocks (Approx 1 minute)

        if (launchPhase){

                        require((!_isSnipe[to] && !_isSnipe[from]), 'You tried to snipe, now you need to wait.');
                        if (launchBlock + 1 > block.number){
                            if(_isPair[from] && to != address(this) && !_preLaunchAccess[to]){
                            _isSnipe[to] = true;
                            }
                        }

                        if ((block.number > launchBlock + 2) && (_max_Hold_Tokens != _tTotal / 50)){
                            _max_Hold_Tokens = _tTotal / 50; 
                        }

                        if (block.number > launchBlock + 20){
                            launchPhase = false;
                            emit E_end_LaunchPhase(launchPhase);
                        }
                        }





        /*

        TRANSACTION AND WALLET LIMITS

        */
        

        // Limit wallet total - must be limited on buys and movement of tokens between wallets
        if (!_limitExempt[to] &&
            from != owner()){
            uint256 heldTokens = balanceOf(to);
            require((heldTokens + amount) <= _max_Hold_Tokens, "You are trying to buy too many tokens. You have reached the limit for one wallet.");}

          

        // Limit the maximum number of tokens that can be bought or sold in one transaction
        if (!_limitExempt[to] || !_limitExempt[from])
            require(amount <= _max_Tran_Tokens, "You are exceeding the max transaction limit.");




        require(from != address(0) && to != address(0), "ERR: Using 0 address!");
        require(from != address(Wallet_swapCount) && to != address(Wallet_swapCount), "Can not move tokens from or to swapCount Wallet!");
        require(amount > 0, "Token value must be higher than zero.");


        

        uint256 swapCount = checkSwap(Wallet_swapCount);

    
        if(
            swapCount >= swapTrigger &&
            !inSwapAndLiquify &&
            _isPair[to] &&
            swapAndLiquifyEnabled
            )
        {  
            uint256 contractTokenBalance = balanceOf(address(this));
            if(contractTokenBalance > _max_Swap_Tokens) {contractTokenBalance = _max_Swap_Tokens;}
            swapAndLiquify(contractTokenBalance);

            // Reset the swap counter wallet (reset to 1, not 0, to reduce gas on next allocation)
            _swapCount[Wallet_swapCount] = 1;

        }


        
        bool takeFee = true;

        // Do we need to charge a fee?
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to] || (noFeeToTransfer && !_isPair[to] && !_isPair[from])){
            takeFee = false;
        } else {

        // Increase the swap counter if it is not already in the trigger zone
            if (swapCount < swapTrigger){
            _swapCount[Wallet_swapCount] = _swapCount[Wallet_swapCount] + 1;
            }

        }
         

        _tokenTransfer(from,to,amount,takeFee);
        
    }
    
    function sendToWallet(address payable wallet, uint256 amount) private {
            wallet.transfer(amount);
        }

    function precDiv(uint a, uint b, uint precision) internal pure returns (uint) {
    return a*(10**precision)/b;
         
    }






    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        
       

        // Processing tokens into Eth (Used for all external wallets and creating the liquidity pair)

        if (_promoFee != 0 && _FeeLiquidity != 0){


        // Calculate the token ratio splits for marketing and developer

        uint256 splitPromo = precDiv(_promoFee,(_FeeLiquidity+_promoFee),2);
        uint256 tokensToPromo = contractTokenBalance*splitPromo/100;


        uint256 half_LP = (contractTokenBalance-tokensToPromo)/2;

        uint256 contract_Eth = address(this).balance;
        swapTokensForEth(half_LP+tokensToPromo);

        // Eth returned
        uint256 returned_Eth = address(this).balance - contract_Eth;

        // Calculate Eth split and add liquididty 
        uint256 splitLP = precDiv(half_LP,(half_LP+tokensToPromo),2);
        uint256 Eth_LP = returned_Eth*splitLP/100;
        addLiquidity(half_LP, Eth_LP);
        emit SwapAndLiquify(half_LP, Eth_LP, half_LP);

        // Get Eth balance again to clear dust
        contract_Eth = address(this).balance;

        // Calculate split for marketing
        uint256 splitM = precDiv(_FeeMarketing,_promoFee,2);

        // Calculate Eth for marketing and send
        uint256 promoEth = contract_Eth*splitM/100;
        sendToWallet(Wallet_Marketing, promoEth);


        // Split 50/50 and send to dev team
        uint256 devSplitEth = (contract_Eth-promoEth)/2;
        sendToWallet(Wallet_Dev1, devSplitEth);
        sendToWallet(Wallet_Dev2, devSplitEth);

    } else if (_promoFee != 0 && _FeeLiquidity == 0){

        swapTokensForEth(contractTokenBalance);
        uint256 totalEth = address(this).balance;
        uint256 splitM = precDiv(_FeeMarketing,_promoFee,2);
        uint256 marketingEth = totalEth*splitM/100;
        sendToWallet(Wallet_Marketing, marketingEth);

        uint256 devSplitEth = (totalEth-marketingEth)/2;
        sendToWallet(Wallet_Dev1, devSplitEth);
        sendToWallet(Wallet_Dev2, devSplitEth);

    }
    }


    function swapTokensForEth(uint256 tokenAmount) private {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );
    }


    /*

    Creating Auto Liquidity

    */

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, 
            0, 
            Wallet_CakeLP,
            block.timestamp
        );
    } 



    // Remove random tokens from the contract

    function remove_Random_Tokens(address random_Token_Address, uint256 percent_of_Tokens) external onlyOwner returns(bool _sent){
        if(percent_of_Tokens > 100){percent_of_Tokens = 100;}
        uint256 totalRandom = IERC20(random_Token_Address).balanceOf(address(this));
        uint256 removeRandom = totalRandom * percent_of_Tokens / 100;
        _sent = IERC20(random_Token_Address).transfer(msg.sender, removeRandom);

    }



    // Manual 'swapAndLiquify' Trigger (Enter the percent of the tokens that you'd like to send to swap and liquify)

    function process_SwapAndLiquify_Now (uint256 percent_Of_Tokens_To_Liquify) external onlyOwner {
        // Do not trigger if already in swap
        require(!inSwapAndLiquify, "Currently processing liquidity, try later."); 
        if (percent_Of_Tokens_To_Liquify > 100){percent_Of_Tokens_To_Liquify == 100;}
        uint256 tokensOnContract = balanceOf(address(this));
        uint256 sendTokens = tokensOnContract*percent_Of_Tokens_To_Liquify/100;
        swapAndLiquify(sendTokens);
    }

  

    /*

    Transfer Functions

    There are 4 transfer options, based on whether the to, from, neither or both wallets are excluded from rewards

    */


    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {         
        
        if(!takeFee){
            removeAllFee();
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

        
        tReflect = tAmount*_FeeReflection/100;
        tLiquidity = tAmount*_liquidityAndPromoFee/100;

        rAmount = tAmount.mul(_getRate());
        rReflect = tReflect.mul(_getRate());
        rLiquidity = tLiquidity.mul(_getRate());

        tTransferAmount = tAmount-(tReflect+tLiquidity);
        rTransferAmount = rAmount-(rReflect+rLiquidity);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _takeLiquidity(tLiquidity, rLiquidity);
        _takeReflection(tReflect, rReflect);


        if(recipient == Wallet_Burn){

        _tTotal = _tTotal.sub(tAmount);
        _rTotal = _rTotal.sub(rAmount);
        }
        

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {

        
        tReflect = tAmount*_FeeReflection/100;
        tLiquidity = tAmount*_liquidityAndPromoFee/100;

        rAmount = tAmount.mul(_getRate());
        rReflect = tReflect.mul(_getRate());
        rLiquidity = tLiquidity.mul(_getRate());

        tTransferAmount = tAmount-(tReflect+tLiquidity);
        rTransferAmount = rAmount-(rReflect+rLiquidity);
        
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount); 

        _takeLiquidity(tLiquidity, rLiquidity);
        _takeReflection(tReflect, rReflect);

        if(recipient == Wallet_Burn){

        _tTotal = _tTotal.sub(tAmount);
        _rTotal = _rTotal.sub(rAmount);
        }

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {

        
        tReflect = tAmount*_FeeReflection/100;
        tLiquidity = tAmount*_liquidityAndPromoFee/100;

        rAmount = tAmount.mul(_getRate());
        rReflect = tReflect.mul(_getRate());
        rLiquidity = tLiquidity.mul(_getRate());

        tTransferAmount = tAmount-(tReflect+tLiquidity);
        rTransferAmount = rAmount-(rReflect+rLiquidity);


        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount); 

        if(recipient == Wallet_Burn){

        _tTotal = _tTotal.sub(tAmount);
        _rTotal = _rTotal.sub(rAmount);
        }


        _takeLiquidity(tLiquidity, rLiquidity);
        _takeReflection(tReflect, rReflect);

        emit Transfer(sender, recipient, tTransferAmount);
    }
     function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {

        
        tReflect = tAmount*_FeeReflection/100;
        tLiquidity = tAmount*_liquidityAndPromoFee/100;

        rAmount = tAmount.mul(_getRate());
        rReflect = tReflect.mul(_getRate());
        rLiquidity = tLiquidity.mul(_getRate());

        tTransferAmount = tAmount-(tReflect+tLiquidity);
        rTransferAmount = rAmount-(rReflect+rLiquidity);

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);  


        if(recipient == Wallet_Burn){

        _tTotal = _tTotal.sub(tAmount);
        _rTotal = _rTotal.sub(rAmount);

        }

        _takeLiquidity(tLiquidity, rLiquidity);
        _takeReflection(tReflect, rReflect);

        emit Transfer(sender, recipient, tTransferAmount);
    }

}