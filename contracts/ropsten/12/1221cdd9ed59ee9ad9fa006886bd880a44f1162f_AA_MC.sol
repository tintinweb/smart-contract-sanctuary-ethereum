/**
 *Submitted for verification at Etherscan.io on 2022-02-08
*/

// SPDX-License-Identifier: Unlicensed 
// Unlicensed SPDX-License-Identifier is not Open Source 
// This contract can not be used/forked without permission 

/*

TEST MC

*/

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



abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = 0x627C95B6fD9026E00Ab2c373FB08CC47E02629a0;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view virtual returns (address) {
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






contract AA_MC is Context, IERC20, Ownable { 
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isExcludedFromFee; 
    mapping (address => bool) public _isExcluded; 
    mapping (address => bool) public _isSnipe;
    mapping (address => bool) public _preLaunchAccess;
    mapping (address => bool) public _limitExempt;
    mapping (address => bool) public _isPair;

    

    address[] private _excluded; // Excluded from rewards
    address payable public Wallet_Marketing = payable(0x406D07C7A547c3dA0BAcFcC710469C63516060f0); // - 2
    address payable public Wallet_Dev1 = payable(0x406D07C7A547c3dA0BAcFcC710469C63516060f0); // -
    address payable public Wallet_Dev2 = payable(0x406D07C7A547c3dA0BAcFcC710469C63516060f0); // -
    address payable public Wallet_LP = payable(0x406D07C7A547c3dA0BAcFcC710469C63516060f0); // -
    address payable public constant Wallet_Burn = payable(0x000000000000000000000000000000000000dEaD); // - 
    
   




    uint256 private constant MAX = ~uint256(0);
    uint256   private constant _decimals = 9;
    uint256 private _tTotal = 10**12 * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    string private constant _name = "AA_MC"; 
    string private constant _symbol = "AA_MC"; 

    // Counter for liquify trigger
    uint8 private txCount = 0;
    uint8 private swapTrigger = 10; 

    // Setting the initial fees
    uint256 public _FeeReflection = 2; 
    uint256 public _FeeLiquidity = 1;
    uint256 public _FeeMarketing = 6;
    uint256 public _FeeDev = 1; 

    // 'Previous fees' are used to keep track of fee settings when removing and restoring fees
    uint256 private _previousFeeReflection = _FeeReflection;
    uint256 private _previousFeeLiquidity = _FeeLiquidity;
    uint256 private _previousFeeMarketing = _FeeMarketing;
    uint256 private _previousFeeDev = _FeeDev; 


    uint8 public constant _FeeMaxPossible = 12; 



    

    // The following settings are used to calculate fee splits when distributing bnb to liquidity and external wallets
    uint256 private _promoFee = _FeeMarketing+_FeeDev;
    uint256 public _FeesTotal = _FeeMarketing+_FeeDev+_FeeLiquidity+_FeeReflection;

    // Fee for the auto LP and the all bnb wallets - used to process fees 
    uint256 private _liquidityAndPromoFee = _FeeMarketing+_FeeDev+_FeeLiquidity;


    uint256 private rReflect; //Reflections
    uint256 private rLiquidity; //LP
    uint256 private rTransferAmount; //After deducting fees
    uint256 private rAmount; //total tokens sent for transfer

    uint256 private tReflect; //Reflections
    uint256 private tLiquidity; //LP
    uint256 private tTransferAmount; //After deducting fees



    uint256 private launchBlock;
    uint256 private swapBlock;
    bool public launchPhase = true;
    bool public TradeOpen;




   

    // Wallet limits 
    

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
    
    event SwapAndLiquifyEnabledUpdated(bool enabled);
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
        _rOwned[owner()] = _rTotal;
        
        //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // MAINNET BSC
        //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); // TESTNET BSC
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // ETH
      
        

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

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint256) {
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

        rAmount = tAmount.mul(_getRate()); 
        
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }



  


    function tokenFromReflection(uint256 _rAmount) public view returns(uint256) {
        require(_rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return _rAmount.div(currentRate);
    }






    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }





    function includeInReward(address account) external onlyOwner() {
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
    }
    




    

    // Set a wallet address so that it does not have to pay transaction fees
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    // Set a wallet address so that it has to pay transaction fees
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }





    /*

    Manually set mappings

    */


    // Pre Launch Access - able to buy and sell before the trade is open 
    function mapping_preLaunchAccess(address account, bool true_or_false) external onlyOwner() {    
        _preLaunchAccess[account] = true_or_false;
    }

    // Add wallet to snipe list - Check for snippers here: https://poocoin.app/sniper-watcher 
    function mapping_isSnipe(address account, bool true_or_false) external onlyOwner() {  
        _isSnipe[account] = true_or_false;
    }


    // Set as pair 
    function mapping_isPair(address wallet, bool true_or_false) external onlyOwner {
        _isPair[wallet] = true_or_false;
    }





    
    /*

    FEES  

    */

    function _set_Fees(uint256 Liquidity, uint256 Marketing, uint256 Reflection) external onlyOwner() {

        // Buyer protection - The fees can never be set above the max possible (12%)
        require((Liquidity+Marketing+Reflection+_FeeDev) <= _FeeMaxPossible, "Total fees set to high!");


          _FeeLiquidity = Liquidity;
          _FeeMarketing = Marketing;
          _FeeReflection = Reflection;

        // For calculations and processing 

          _promoFee = _FeeMarketing+_FeeDev;
          _liquidityAndPromoFee = _FeeLiquidity+_FeeMarketing+_FeeDev;
          _FeesTotal = _FeeMarketing+_FeeDev+_FeeLiquidity+_FeeReflection;

    }




    /*

    Updating Wallets

    */

    

    //Update the marketing wallet
    function Wallet_Update_Marketing(address payable wallet) external onlyOwner() {
        // Can't be zero address
        require(wallet != address(0), "new wallet is the zero address");

        // Update Mappins on old wallet
        _isExcludedFromFee[Wallet_Marketing] = false; 

        Wallet_Marketing = wallet;
        // Update Mappins on new wallet
        _isExcludedFromFee[Wallet_Marketing] = true;
    }

    //Update the LP wallet
    function Wallet_Update_Auto_LP_Tokens(address payable wallet) external onlyOwner() {
        // To send the Auto LP tokens to Burn change this to 0x000000000000000000000000000000000000dEaD
        Wallet_LP = wallet;
    }
   
    
    /*

    SwapAndLiquify Switches

    */
    
    // Toggle on and off to activate auto liquidity and the promo wallet 
    function set_Swap_And_Liquify_Enabled(bool true_or_false) public onlyOwner {
        swapAndLiquifyEnabled = true_or_false;
        emit SwapAndLiquifyEnabledUpdated(true_or_false);
    }

    // This will set the number of transactions required before the 'swapAndLiquify' function triggers
    function set_Number_Of_Transactions_Before_Liquify_Trigger(uint8 number_of_transactions) public onlyOwner {
        swapTrigger = number_of_transactions;
    }
    


    // This function is required so that the contract can receive BNB from pancakeswap
    receive() external payable {}




    /*

    SafeLaunch Features

    Wallet Limits

    Wallets are limited in two ways. The amount of tokens that can be purchased in one transaction
    and the total amount of tokens a wallet can buy. Limiting a wallet prevents one wallet from holding too
    many tokens, which can scare away potential buyers that worry that a whale might dump!

    Wallet limits must be a whole number.

    */


    // Wallet Holding and Transaction Limits

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

    }

    
    // Open Trade - ONE WAY SWITCH! - Buyer Protection! 
    function openTrade() external onlyOwner() {
        TradeOpen = true;
        launchBlock = block.number;
    }


    // End Launch Phase - ONE WAY SWITCH - Buyer Protection!
    function end_LaunchPhase() external onlyOwner() {
        launchPhase = false;
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
    


    function _takeLiquidity(uint256 _tLiquidity, uint256 _rLiquidity) private {
        
        _rOwned[address(this)] = _rOwned[address(this)].add(_rLiquidity);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(_tLiquidity);
    }



    function _takeReflection(uint256 _rReflect, uint256 _tReflect) private {
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








    function _approve(address owner, address spender, uint256 amount) private {

        require(owner != address(0) && spender != address(0), "ERR: zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);

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
        require(amount > 0, "Token value must be higher than zero.");


        

        // SwapAndLiquify is triggered after every X transactions - this number can be adjusted using swapTrigger
        

        if(
            txCount >= swapTrigger && 
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled &&
            block.number > swapBlock
            )
        {  
            
            
            uint256 contractTokenBalance = balanceOf(address(this));
            if(contractTokenBalance > _max_Swap_Tokens) {contractTokenBalance = _max_Swap_Tokens;}
            txCount = 0;
            swapAndLiquify(contractTokenBalance);
            swapBlock = block.number;
        }
        



        
        bool takeFee = true;
         
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
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
            Wallet_LP,
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
            } else {
                txCount++;
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
        _takeReflection(rReflect, tReflect);

        if(recipient == Wallet_Burn){

        _tTotal = _tTotal.sub(tTransferAmount);
        _rTotal = _rTotal.sub(rTransferAmount);

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
        _takeReflection(rReflect, tReflect);

        if(recipient == Wallet_Burn){

        _tTotal = _tTotal.sub(tTransferAmount);
        _rTotal = _rTotal.sub(rTransferAmount);

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

        _tTotal = _tTotal.sub(tTransferAmount);
        _rTotal = _rTotal.sub(rTransferAmount);

        }

        _takeLiquidity(tLiquidity, rLiquidity);
        _takeReflection(rReflect, tReflect);

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

        _tTotal = _tTotal.sub(tTransferAmount);
        _rTotal = _rTotal.sub(rTransferAmount);

        }

        _takeLiquidity(tLiquidity, rLiquidity);
        _takeReflection(rReflect, tReflect);

        emit Transfer(sender, recipient, tTransferAmount);
    }

}


// Contract by www.GenTokens.com for https://www.bashitoken.com/