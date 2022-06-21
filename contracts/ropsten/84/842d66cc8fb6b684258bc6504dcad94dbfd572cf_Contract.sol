/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

// SPDX-License-Identifier: Unlicensed 
// This contract is not open source and can not be used/forked without permission
// Created by https://TokensByGen.com/ and pre-verified on BSCScan using 'Similar Match Source Code'



pragma solidity 0.8.14;

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
        return a + b;}
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;}
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;}
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;}
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {require(b <= a, errorMessage);
            return a - b;}}
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {require(b > 0, errorMessage);
            return a / b;}}
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
        require(address(this).balance >= amount, "insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "unable to send, recipient reverted");
    }
    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "low-level call failed");
    }
    
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "low-level call with value failed");
    }
    
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "insufficient balance for call");
        require(isContract(target), "call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "low-level static call failed");
    }
    
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }


    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "low-level delegate call failed");
    }
    
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "delegate call to non-contract");
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







        










contract Contract is Context, IERC20 { 

    using SafeMath for uint256;
    using Address for address;

    // Contract Wallets
    address private _owner;                             // Contract Owner
    address public Wallet_Liquidity;                    // LP Token Collection Wallet for Auto LP 
    address public Wallet_Tokens;                       // Token Fee Collection Wallet
    address payable public Wallet_BNB;                  // BNB Fee Collection Wallet 
    address payable public Wallet_TBG_AFF;              // TokensByGEN Affiliate Wallet and Discount Code

    // Contract fee (1% ongoing if applicable) is sent to fee collection contract 
    address payable public feeCollector = payable(0xde491C65E507d281B6a3688d11e8fC222eee0975); 

    // Token Info
    string private  _name;
    string private  _symbol;
    uint256 private _decimals;
    uint256 private _tTotal;

    // Token social links will appear on BSCScan
    string private _Website;
    string private _Telegram;

    // Wallet and transaction limits
    uint256 private max_Hold;
    uint256 private max_Tran;

    // Fees - Set fees before opening trade
    uint256 public _Fee__Buy_Burn;
    uint256 public _Fee__Buy_Contract;
    uint256 public _Fee__Buy_Liquidity;
    uint256 public _Fee__Buy_BNB;
    uint256 public _Fee__Buy_Reflection;
    uint256 public _Fee__Buy_Tokens;

    uint256 public _Fee__Sell_Burn;
    uint256 public _Fee__Sell_Contract;
    uint256 public _Fee__Sell_Liquidity;
    uint256 public _Fee__Sell_BNB;
    uint256 public _Fee__Sell_Reflection;
    uint256 public _Fee__Sell_Tokens;

    // Upper limit for fee processing trigger
    uint256 private swap_Max;

    // Total fees that are processed on buys and sells for swap and liquify calculations
    uint256 private _SwapFeeTotal_Buy;
    uint256 private _SwapFeeTotal_Sell;

    // Track contract fee
    uint256 private ContractFee;

    // Supply Tracking for RFI
    uint256 private _rTotal;
    uint256 private _tFeeTotal;
    uint256 private constant MAX = ~uint256(0);


    // Affiliate Tracking
    IERC20 GEN = IERC20(0x7d7a7f452e04C2a5df792645e8bfaF529aDcCEcf); // GEN - For tracking affiliate level
    IERC20 AFF = IERC20(0x98A70E83A53544368D72940467b8bB05267632f4); // TokensByGEN Affiliate Tracker Token


    uint256 private Tier_2 =  500000 * 10**9;
    uint256 private Tier_3 = 1000000 * 10**9;


    // Set factory
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    constructor (string memory      _TokenName, 
                 string memory      _TokenSymbol,  
                 uint256            _TotalSupply, 
                 uint256            _Decimals, 
                 address payable    _OwnerWallet,
                 address payable    _DiscountCode, 
                 uint256            _ContractFee) {

    // Set owner
    _owner              = _OwnerWallet;

    // Set basic token details
    _name               = _TokenName;
    _symbol             = _TokenSymbol;
    _decimals           = _Decimals;
    _tTotal             = _TotalSupply * 10**_decimals;
    _rTotal             = (MAX - (MAX % _tTotal));
    
    // Wallet limits - Set limits after deploying
    max_Hold            = _tTotal;
    max_Tran            = _tTotal;

    // Contract sell limit when processing fees
    swap_Max            = _tTotal / 200;

    // Set BNB, tokens, and liquidity collection wallets to owner (can be updated later)
    Wallet_BNB          = _OwnerWallet;
    Wallet_Liquidity    = _OwnerWallet;
    Wallet_Tokens       = _OwnerWallet;

    // Set contract fee 
    ContractFee         = _ContractFee;

    // Transfer token supply to owner wallet
    _rOwned[_owner]     = _rTotal;

    // Set TokensByGEN affiliate from Discount Code
    Wallet_TBG_AFF      = _DiscountCode;

    // Set PancakeSwap Router Address
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    // Create initial liquidity pair with BNB on PancakeSwap factory
    uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
    uniswapV2Router = _uniswapV2Router;

    // Wallets that are excluded from holding limits
    _isLimitExempt[_owner] = true;
    _isLimitExempt[address(this)] = true;
    _isLimitExempt[Wallet_Burn] = true;
    _isLimitExempt[uniswapV2Pair] = true;
    _isLimitExempt[Wallet_Tokens] = true;

    // Wallets that are excluded from fees
    _isExcludedFromFee[_owner] = true;
    _isExcludedFromFee[address(this)] = true;
    _isExcludedFromFee[Wallet_Burn] = true;

    // Set the initial liquidity pair
    _isPair[uniswapV2Pair] = true;    

    // Exclude from Rewards
    _isExcluded[Wallet_Burn] = true;
    _isExcluded[uniswapV2Pair] = true;
    _isExcluded[address(this)] = true;

    // Push excluded wallets to array
    _excluded.push(Wallet_Burn);
    _excluded.push(uniswapV2Pair);
    _excluded.push(address(this));

    // Wallets granted access before trade is open
    _isWhiteListed[_owner] = true;

    // Emit Supply Transfer to Owner
    emit Transfer(address(0), _owner, _tTotal);

    // Emit ownership transfer
    emit OwnershipTransferred(address(0), _owner);

    }

    
    // Events
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event updated_mapping_isWhiteListed(address Wallet_Address, bool WhiteListed);
    event updated_mapping_isLimitExempt(address Wallet_Address, bool LimitExempt);
    event updated_mapping_isPair(address Wallet_Address, bool LiquidityPair);
    event updated_mapping_isExcludedFromFee(address Wallet_Address, bool ExcludedFromFee);
    event updated_BNB_Wallet(address indexed oldWallet, address indexed newWallet);
    event updated_Liquidity_Wallet(address indexed oldWallet, address indexed newWallet);
    event updated_Tokens_Wallet(address indexed oldWallet, address indexed newWallet);
    event updated_Wallet_Limits(uint256 max_Tran, uint256 max_Hold);
    event updated_Buy_fees(uint256 Marketing, uint256 Liquidity, uint256 Reflection, uint256 Tokens, uint256 Contract_Development_Fee);
    event updated_Sell_fees(uint256 Marketing, uint256 Liquidity, uint256 Reflection, uint256 Tokens, uint256 Contract_Development_Fee);
    event updated_swapTriggerCount(uint256 swapTrigger_Transaction_Count);
    event updated_SwapAndLiquify_Enabled(bool Swap_and_Liquify_Enabled);
    event updated_trade_Open(bool TradeOpen);
    event updated_DeflationaryBurn(bool Burn_Is_Deflationary);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event set_Contract_Fee(uint256 Contract_Development_Buy_Fee, uint256 Contract_Development_Sell_Fee);


    // Restrict function to contract owner only 
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


    // Lock function permanently
    modifier LockFunction {
        require(!Functions_Locked, "Function locked");
        _;
    }
    

    // Address mappings
    mapping (address => uint256) private _tOwned;                               // Tokens Owned
    mapping (address => uint256) private _rOwned;                               // Reflected balance
    mapping (address => mapping (address => uint256)) private _allowances;      // Allowance to spend another wallets tokens
    mapping (address => bool) public _isExcludedFromFee;                        // Wallets that do not pay fees
    mapping (address => bool) public _isExcluded;                               // Excluded from RFI rewards
    mapping (address => bool) public _isWhiteListed;                            // Wallets that have access before trade is open
    mapping (address => bool) public _isLimitExempt;                            // Wallets that are excluded from HOLD and TRANSFER limits
    mapping (address => bool) public _isPair;                                   // Address is liquidity pair
    address[] private _excluded;                                                // Array of wallets excluded from rewards


    // Token information 
    function Token_Information() external view returns(string memory Token_Name,
                                                       string memory Token_Symbol,
                                                       uint256 Number_of_Decimals,
                                                       address Owner_Wallet,
                                                       uint256 Transaction_Limit,
                                                       uint256 Max_Wallet,
                                                       uint256 Fee_When_Buying,
                                                       uint256 Fee_When_Selling,
                                                       string memory Website,
                                                       string memory Telegram,
                                                       string memory Liquidity_Lock_URL,
                                                       string memory Contract_Created_By) {

                                                           
        string memory Creator = "https://tokensbygen.com/";

        uint256 Total_buy =  _Fee__Buy_Burn         +
                             _Fee__Buy_Contract     +
                             _Fee__Buy_Liquidity    +
                             _Fee__Buy_BNB          +
                             _Fee__Buy_Reflection   +
                             _Fee__Buy_Tokens       ;

        uint256 Total_sell = _Fee__Sell_Burn        +
                             _Fee__Sell_Contract    +
                             _Fee__Sell_Liquidity   +
                             _Fee__Sell_BNB         +
                             _Fee__Sell_Reflection  +
                             _Fee__Sell_Tokens      ;

        // Return Token Data
        return (_name,
                _symbol,
                _decimals,
                _owner,
                max_Tran / 10 ** _decimals,
                max_Hold / 10 ** _decimals,
                Total_buy,
                Total_sell,
                _Website,
                _Telegram,
                _LP_Locker_URL,
                Creator);

    }
    

    // Burn (dead) address
    address public constant Wallet_Burn = 0x000000000000000000000000000000000000dEaD; 


    // Swap triggers
    uint256 private swapTrigger = 11;    // After 10 transactions with a fee swap will be triggered 
    uint256 private swapCounter = 1;     // Start at 1 not zero to save gas
    

    // SwapAndLiquify - Automatically processing fees and adding liquidity                                   
    bool public inSwapAndLiquify;
    bool public swapAndLiquifyEnabled; 


    // Launch settings
    bool public TradeOpen;


    // Deflationary Burn - Tokens Sent to Burn are removed from total supply if set to true
    bool public deflationaryBurn;

    // URL for Liquidity Tokens Locker
    string private _LP_Locker_URL;






    /* 

    Contract Setup Functions

    */




    /*

    Deflationary Burn Switch - By default this is set to false
    
    If you change this to true, when tokens are sent to the burn wallet 0x000000000000000000000000000000000000dEaD
    They will not arrive in the burn wallet, instead they will be removed from the senders balance and removed from the total supply

    When this is set to false, any tokens sent to the burn wallet will not be removed from total supply and will be added to the burn wallet balance.
    This is the default action on most contracts. 

    A truly deflationary burn can be confusing to some token tools and listing platforms!

    */

    function Deploy_1__Deflationary_Burn(bool true_or_false) external LockFunction onlyOwner {
        deflationaryBurn = true_or_false;
        emit updated_DeflationaryBurn(deflationaryBurn);
    }


    // Set up the pre-sale wallet 

    /*

    If you are doing a pre-sale, the pre-sale company will give you an address and tell you that it needs to be 'white listed'.
    Enter is here and it will be granted the required privileges.

    Do not continue with contract setup until the pre-sale has been finalized.

    */ 

    function Deploy_2__PreSale_Wallet (address PreSale_Wallet_Address) external LockFunction onlyOwner {

        _isLimitExempt[PreSale_Wallet_Address]      = true;
        _isExcludedFromFee[PreSale_Wallet_Address]  = true;
        _isWhiteListed[PreSale_Wallet_Address]      = true;

    }


    /* 

    -------------------------------------------------------------------------
    DO NOT CONTINUE WITH CONTRACT SETUP UNTIL THE PRE-SALE HAS BEEN FINALIZED
    -------------------------------------------------------------------------

    */







    /*

    FEES  

    To protect investors, buy and sell fees have a hard-coded limit of 20% 
    If the contract development fee was set to 1% of transactions, this is included in the limit.

    -------------
    How Fees Work
    -------------

    All fees are collected in tokens then added to the contract. 
    Fees accumulate (as tokens) on the contract until they are processed.

    When fees are processed, the contract sells the accumulated tokens for BNB (This shows as a sell on the chart)

    This process can only happen when a holder sells tokens.
    So when fees are processed, you will see 2 sells on the chart in the same second, the holders sell, and the contract sell.
    
    ----------------------------
    The Processing Trigger Count
    ----------------------------

    This counts the number of transactions with a fee. When it reaches the trigger number the contract will process the accumulated fees on the next sell. 
    (Remember, it is not possible to process the fees during a buy, only a sell. So fee processing needs to wait until the next sell.)

    Why would you need to change the Processing Trigger Count

    The default is 10, so the contract will process the accumulate fees on the next sell after 10 transactions.
    If your fee is 10%, the contract sell will be the average of the last 10 transaction, so it'll always be in keeping with the transaction amounts on your chart. 

    If your fees are more than 10% then the accumulated fees after 10 transaction will be greater than the average transaction.
    In this case, reducing the Trigger Count will cause the contract to process fees more frequently, reducing the size of the contract sell. 

    Similarly, if your fees are less than 10% then you can process the accumulated fees less frequently (increase the Trigger Count)
    This will cause larger contract sells, but they'll be less frequent.

    If you have a flurry of buys and nobody is selling, then the contract will not process the fees. 
    Fee processing can only be triggered by a sell. If you want to trigger it yourself, you can sell a token or use the 'Processing_Process_Now' function.

    */


    // Set Buy Fees
    function Deploy_3__Fees_on_Buy(uint256 BNB_on_BUY, 
                                           uint256 Liquidity_on_BUY, 
                                           uint256 Reflection_on_BUY, 
                                           uint256 Burn_on_BUY,  
                                           uint256 Tokens_on_BUY) external LockFunction onlyOwner {

        _Fee__Buy_Contract   = ContractFee;

        // Buyer protection: max fee can not be set over 20% (including the 1% contract fee if applicable)
        require (BNB_on_BUY          + 
                 Liquidity_on_BUY    + 
                 Reflection_on_BUY   + 
                 Burn_on_BUY         + 
                 Tokens_on_BUY       + 
                 _Fee__Buy_Contract <= 20, "Buy Fee limit 20%"); 

        // Update fees
        _Fee__Buy_BNB        = BNB_on_BUY;
        _Fee__Buy_Liquidity  = Liquidity_on_BUY;
        _Fee__Buy_Reflection = Reflection_on_BUY;
        _Fee__Buy_Burn       = Burn_on_BUY;
        _Fee__Buy_Tokens     = Tokens_on_BUY;

        // Fees that will need to be processed during swap and liquify
        _SwapFeeTotal_Buy    = _Fee__Buy_BNB + _Fee__Buy_Liquidity + _Fee__Buy_Contract;

        emit updated_Buy_fees(_Fee__Buy_BNB, _Fee__Buy_Liquidity, _Fee__Buy_Reflection, _Fee__Buy_Tokens, _Fee__Buy_Contract);
    }

    // Set Sell Fees
    function Deploy_4__Fees_on_Sell(uint256 BNB_on_SELL,
                                            uint256 Liquidity_on_SELL, 
                                            uint256 Reflection_on_SELL, 
                                            uint256 Burn_on_SELL,
                                            uint256 Tokens_on_SELL) external LockFunction onlyOwner {

        _Fee__Sell_Contract = ContractFee;

        // Buyer protection: max fee can not be set over 20% (including the 1% contract fee if applicable)
        require (BNB_on_SELL        + 
                 Liquidity_on_SELL  + 
                 Reflection_on_SELL + 
                 Burn_on_SELL       + 
                 Tokens_on_SELL     + 
                 _Fee__Sell_Contract <= 20, "Sell Fee limit 20%"); 

        // Update fees
        _Fee__Sell_BNB        = BNB_on_SELL;
        _Fee__Sell_Liquidity  = Liquidity_on_SELL;
        _Fee__Sell_Reflection = Reflection_on_SELL;
        _Fee__Sell_Burn       = Burn_on_SELL;
        _Fee__Sell_Tokens     = Tokens_on_SELL;

        // Fees that will need to be processed during swap and liquify
        _SwapFeeTotal_Sell   = _Fee__Sell_BNB + _Fee__Sell_Liquidity + _Fee__Sell_Contract;

        emit updated_Sell_fees(_Fee__Sell_BNB, _Fee__Sell_Liquidity, _Fee__Sell_Reflection, _Fee__Sell_Tokens, _Fee__Sell_Contract);
    }



    /*

    Wallet Limits

    To protect buyers, these values must be set to a minimum of 0.1% of the total supply

    Wallet limits are set as a number of tokens, not as a percent of supply!
    If you want to limit people to 2% of supply and your supply is 1,000,000 tokens then you 
    will need to enter 20000 (as this is 2% of 1,000,000)

    */

    // Wallet Holding and Transaction Limits (Enter token amount, excluding decimals)
    function Deploy_5__Wallet_Limits(

        uint256 Max_Tokens_Per_Transaction,
        uint256 Max_Total_Tokens_Per_Wallet 

        ) external LockFunction onlyOwner {

        // Buyer protection - Limits must be set to greater than 0.1% of total supply
        require(Max_Tokens_Per_Transaction >= _tTotal / 1000 / 10**_decimals, "Min Tx limit 0.1%");
        require(Max_Total_Tokens_Per_Wallet >= _tTotal / 1000 / 10**_decimals, "Min Hold limit 0.1%");
        
        max_Tran = Max_Tokens_Per_Transaction * 10**_decimals;
        max_Hold = Max_Total_Tokens_Per_Wallet * 10**_decimals;

        emit updated_Wallet_Limits(max_Tran, max_Hold);

    }



    /*

    Update Wallets

    The contract can process fees in the native token or BNB. 
    Processed fees are sent to external wallets (Wallet_Tokens and Wallet_BNB)

    Cake LP Tokens that are created when the contract makes Auto Liquidity are sent to this address
    Periodically, these tokens will need to be locked (or burned)

    During deployment, all external wallets are set to the owner wallet by default, but can be updated here. 

    Please check the project website for details of how fees are distributed. 

    */

    function Deploy_6__Set_Wallets(address Token_Fee_Wallet, address payable BNB_Fee_Wallet, address Liquidity_Collection_Wallet) external LockFunction onlyOwner {

        // Update Token Fee Wallet
        require(Token_Fee_Wallet != address(0), "Can not be 0 address");
        emit updated_Tokens_Wallet(Wallet_Tokens, Token_Fee_Wallet);
        Wallet_Tokens = Token_Fee_Wallet;
        // Make limit exempt
        _isLimitExempt[Token_Fee_Wallet] = true;

        // Update BNB Fee Wallet
        require(BNB_Fee_Wallet != address(0), "Can not be 0 address");
        emit updated_BNB_Wallet(Wallet_BNB, BNB_Fee_Wallet);
        Wallet_BNB = BNB_Fee_Wallet;

        // To send the auto liquidity tokens directly to burn update to 0x000000000000000000000000000000000000dEaD
        emit updated_Liquidity_Wallet(Wallet_Liquidity, Liquidity_Collection_Wallet);
        Wallet_Liquidity = Liquidity_Collection_Wallet;

    }


    /*

    -------------
    ADD LIQUIDITY
    -------------

    If you have done a pre-sale, the pre-sale company will most likely add the liquidity for you automatically.
    If you are not doing a pre-sale, but you plan to do a private sale, you must add the liquidity now, but do not open trade until the private sale is complete.
    

    To add your liquidity go to https://pancakeswap.finance/add/BNB and enter your contract address into the 'Select a currency' field.

    */





    /* 

    ------------
    PRIVATE SALE
    ------------

    Before whitelisting private sale wallets, set your transaction and holding limits, your buy and sell fees and add liquidity.

    You can whitelist several wallets at a time, comma separate wallets (with no spaces)

    NOTE - All functions that use a loop can fail due to running out of gas. If the transaction fails, break the list on wallet 
    addresses into smaller chunks and do them a few at a time.

    To whitelist wallets, add 1 or more wallet addresses and set the 'true_or_fale' bool as true.
    To remove whitelist status from a wallet, enter 1 or more wallet addresses and set the 'true_or_fale' bool as false.

    */

    function Deploy_7__Private_Sale_WhiteList(address[] calldata Whitelist_Wallets, bool true_or_false) external LockFunction onlyOwner {
        for (uint256 i; i < Whitelist_Wallets.length; ++i) {
        _isWhiteListed[Whitelist_Wallets[i]] = true_or_false;
        }
    }


    /*

    -----------------
    ADD PROJECT LINKS
    -----------------

    The information that you add here will appear on BSCScan, helping potential investors to find out more about your project.
    Be sure to enter the complete URL as many websites will automatically detect this, and add links to your token listing.

    */

    function Deploy_8__Update_Socials(string memory Website_URL, string memory Telegram_URL, string memory Liquidity_Locker_URL) external onlyOwner{

        _Website         = Website_URL;
        _Telegram        = Telegram_URL;
        _LP_Locker_URL   = Liquidity_Locker_URL;

    }

    /*

    ----------
    OPEN TRADE
    ----------

    */

    // Open trade: Buyer Protection - one way switch - trade can not be paused once opened
    function Deploy_9__OpenTrade() external LockFunction onlyOwner {

        // Can only use once!
        require(!TradeOpen, "Trade is already open!");
        TradeOpen = true;
        swapAndLiquifyEnabled = true;

        emit updated_trade_Open(TradeOpen);
        emit updated_SwapAndLiquify_Enabled(swapAndLiquifyEnabled);

        // Set the contract fee if required
        _Fee__Buy_Contract   = ContractFee;
        _Fee__Sell_Contract  = ContractFee;
        _SwapFeeTotal_Buy    = _Fee__Buy_Liquidity + _Fee__Buy_BNB + _Fee__Buy_Contract;
        _SwapFeeTotal_Sell   = _Fee__Sell_Liquidity + _Fee__Sell_BNB + _Fee__Sell_Contract;

        emit set_Contract_Fee(_Fee__Buy_Contract, _Fee__Sell_Contract);
    }






    /*

    Remove 1% Contract Fee for 2 BNB 

    If you opted for the 1% ongoing fee in your contract you can remove this at a cost of 2 BNB at any time.
    To do this, enter the number 2 into the field 

    */

    function Remove_Contract_Fee() external onlyOwner payable {

        require(msg.value == 2*10**18, "Enter a value of 2, and pay 2 BNB to remove the ongoing 1% fee."); 


        // Check Affiliate is genuine - (Holds the TokensByGEN Affiliate Token)
        if(AFF.balanceOf(Wallet_TBG_AFF) > 0){

                if(GEN.balanceOf(Wallet_TBG_AFF) >= Tier_3){

                // Tier 3 - Split 80% Contract, 20% Affiliate
                Wallet_TBG_AFF.transfer(msg.value * 20 / 100);
                feeCollector.transfer(msg.value * 80 / 100); 


                } else if (GEN.balanceOf(Wallet_TBG_AFF) >= Tier_2){

                // Tier 2 - Split 85% Contract, 15% Affiliate
                Wallet_TBG_AFF.transfer(msg.value * 15 / 100);
                feeCollector.transfer(msg.value * 85 / 100); 


                } else {

                // Tier 1 - Split 90% Contract, 10% Affiliate
                Wallet_TBG_AFF.transfer(msg.value * 10 / 100);
                feeCollector.transfer(msg.value * 90 / 100); 

                }

        } else {

        // Transfer Fee to Collector Wallet
        feeCollector.transfer(msg.value);

        }

        // Remove Contract Fee
        ContractFee              = 0;
        _Fee__Buy_Contract       = 0;
        _Fee__Sell_Contract      = 0;

        // Emit Contract Fee update
        emit set_Contract_Fee(_Fee__Buy_Contract, _Fee__Sell_Contract);

        // Update Swap Fees
        _SwapFeeTotal_Buy   = _Fee__Buy_Liquidity + _Fee__Buy_BNB;
        _SwapFeeTotal_Sell  = _Fee__Sell_Liquidity + _Fee__Sell_BNB;
    }






    /* 

    Owner Functions
    
    ----------------
    WHY NO RENOUNCE?
    ----------------

    The ownership of this contract can not be renounced as this would create a potential exploit.

    In order to have wallet to wallet transfers without a fee, we need to tell the contract when to apply a fee.
    We do this for any address that represents a liquidity pairs, so that the contract knows to apply a fee for transactions to or from these addresses. 
    
    Anybody can create a new liquidity pair on any token.

    So if the owner renounces the contract, and then somebody creates a new liquidity pair, buys and sells via that pair would not charge a fee, 
    and without access to the functions, the owner would not be able to tell the contract that the address is a pair.

    For this reason, the owner can never fully renounce this contract. But they can permanently lock other functions. 

    The contract includes a modifier called "LockFunction" any function with this modifier requires that the bool "Functions_Locked" is false. 
    This bool can be set to true using a one-way switch. Once set to true it can not be set back to false. 

    For all functions that include the LockFunction modifier, this works in exactly the same way as renouncing the contract.

    --------------------------------
    FUNCTIONS THAT CAN NOT BE LOCKED
    --------------------------------

    There are 4 functions that can not be locked. 

        1. The function that allows an address to be set as a liquidity pair.
        2. The function that allows the owner to remove the ongoing 1% contract fee (for a fee of 2 BNB)
        3. The function that allows the owner to remove random tokens that are accidentally sent to the contract.
        4. The function that allows the owner to update the URL of the Liquidity Token Locker, Website and Telegram Group

    None of these functions can be abused or used maliciously. However, locking them permanently is detrimental to holders. 
    If Functions_Locked is set to true, the owner is permanently locked out of all other functions. This can not be reversed. 
    
    */

    bool public Functions_Locked;

    // You can't renounce... but you can permanently lock most functions
    function Owner_Lock_Functions() public LockFunction onlyOwner {

        // Swap and liquify must be active when locked!
        swapAndLiquifyEnabled = true;

        // This is a one way switch! Once locked it can never be unlocked!
        Functions_Locked = true;

    }



    // Transfer the contract to to a new owner
    function Owner_Transfer_Ownership(address payable newOwner) public LockFunction onlyOwner {
        require(newOwner != address(0), "Can not be the 0 address");

        // Remove old owner status 
        _isLimitExempt[owner()]     = false;
        _isExcludedFromFee[owner()] = false;
        _isWhiteListed[owner()]       = false;


        // Emit ownership transfer
        emit OwnershipTransferred(_owner, newOwner);

        // Transfer owner
        _owner = newOwner;

    }








    /*

    Processing Fees Functions

    */



    // Default is True. Contract will process fees into Marketing and Liquidity etc. automatically
    function Processing_SwapAndLiquify_Enabled(bool true_or_false) external LockFunction onlyOwner {
        swapAndLiquifyEnabled = true_or_false;
        emit updated_SwapAndLiquify_Enabled(true_or_false);
    }

    // Manually process fees
    function Processing_Process_Now (uint256 Percent_of_Tokens_to_Process) external LockFunction onlyOwner {
        require(!inSwapAndLiquify, "Already in swap"); 
        if (Percent_of_Tokens_to_Process > 100){Percent_of_Tokens_to_Process == 100;}
        uint256 tokensOnContract = balanceOf(address(this));
        uint256 sendTokens = tokensOnContract * Percent_of_Tokens_to_Process / 100;
        swapAndLiquify(sendTokens);

    }


    // Set the number of transactions before fee processing is triggered (default 10)

    /*

    The contract will process the accumulated fees every 10 transaction, if your fees are set to 10% the
    contract sells will always be just under the average of the previous 10 transactions on the chart.
    
    (It's always less than the average because half of the Auto Liquidity is processed in tokens, and not sold to BNB)

    If you increase your fees above 10% then you should reduce this number so that the contract processes the fees more frequently.
    If your fees are lower than 10% then you can increase this number to reduce the number of contract sells on the chart. 

    */

    function Processing_Trigger_Count(uint256 Number_of_Transactions_to_Trigger_Processing) external LockFunction onlyOwner {

        // Add 1 to total as counter is reset to 1, not 0, to save gas
        swapTrigger = Number_of_Transactions_to_Trigger_Processing + 1;
        emit updated_swapTriggerCount(Number_of_Transactions_to_Trigger_Processing);
    }


    // Remove random tokens from the contract
    function Processing_Remove_Random_Tokens(address random_Token_Address, uint256 percent_of_Tokens) external onlyOwner returns(bool _sent){

            // Can not purge the native token!
            require (random_Token_Address != address(this), "Can not remove the native token");

            // Sanity check
            if (percent_of_Tokens > 100){percent_of_Tokens == 100;}

            // Get balance of random tokens and send to caller wallet
            uint256 totalRandom = IERC20(random_Token_Address).balanceOf(address(this));
            uint256 removeRandom = totalRandom * percent_of_Tokens / 100;
            _sent = IERC20(random_Token_Address).transfer(msg.sender, removeRandom);

    }







    /*

    ERC20/BEP20 Compliance and Standard Functions

    */

    function owner() public view returns (address) {
        return _owner;
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
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "Decreased allowance below zero"));
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
   
    function tokenFromReflection(uint256 _rAmount) internal view returns(uint256) {
        require(_rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return _rAmount / currentRate;
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply - _rOwned[_excluded[i]];
            tSupply = tSupply - _tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }


    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "Allowance exceeded"));
        return true;
    }




    /*

    Wallet Mappings

    */


    // Grants access when trade is closed - Default false (true for contract owner)
    function Wallet_Settings_Grant_PreLaunch_Access(address Wallet_Address, bool true_or_false) external LockFunction onlyOwner {    
        _isWhiteListed[Wallet_Address] = true_or_false;
        emit updated_mapping_isWhiteListed(Wallet_Address, true_or_false);
    }

    // Excludes wallet from transaction and holding limits - Default false
    function Wallet_Settings_Exempt_From_Limits(address Wallet_Address, bool true_or_false) external LockFunction onlyOwner {  
        _isLimitExempt[Wallet_Address] = true_or_false;
        emit updated_mapping_isLimitExempt(Wallet_Address, true_or_false);
    }

    // Excludes wallet from fees - Default false
    function Wallet_Settings_Exclude_From_Fees(address Wallet_Address, bool true_or_false) external LockFunction onlyOwner {
        _isExcludedFromFee[Wallet_Address] = true_or_false;
        emit updated_mapping_isExcludedFromFee(Wallet_Address, true_or_false);

    }


    /* 

    Setting an address as a liquidity pair

    This function can not be locked. 
    Anybody can add a new pair to a token. For this reason, we need to keep this function open, so that we can tell the contract that 
    an address represents a liquidity pair. This tells the contract that a fee is required when tokens move to or from the address.

    This feature is required for no-fee wallet to wallet transfers.

    The liquidity pair address also needs to be limit exempt, otherwise the pair is restricted by the contract transaction and holding limits and 
    will not function correctly.

    */
 
    function Wallet_Settings_Set_As_Liquidity_Pair(address Wallet_Address, bool true_or_false) external onlyOwner {
        _isPair[Wallet_Address] = true_or_false;
        _isLimitExempt[Wallet_Address] = true_or_false;
        emit updated_mapping_isPair(Wallet_Address, true_or_false);
    } 



    /*

    The following functions are used to exclude or include a wallet in the reflection rewards.
    By default, all wallets are included. 

    Wallets that are excluded:

            The Burn address 
            The Liquidity Pair
            The Contract Address

    --------------------------------
    WARNING - DoS 'OUT OF GAS' Risk!
    --------------------------------

    A reflections contract needs to loop through all excluded wallets to correctly process several functions. 
    This loop can break the contract if it runs out of gas before completion.

    To prevent this, keep the number of wallets that are excluded from rewards to an absolute minimum. 
    In addition to the default excluded wallets, you may need to exclude the address of any locked tokens.

    */


    // Wallet will not get reflections
    function Rewards_Exclude_Wallet(address account) public LockFunction onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }


    // Wallet will get reflections - DEFAULT
    function Rewards_Include_Wallet(address account) external LockFunction onlyOwner() {
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
    


   





    // Main transfer checks and settings 
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {


        // Allows owner to add liquidity safely, eliminating the risk of someone maliciously setting the price 
        if (!TradeOpen){
        require(_isWhiteListed[from] || _isWhiteListed[to], "Trade closed");
        }


        // Wallet Limit
        if (!_isLimitExempt[to] && from != owner())
            {
            uint256 heldTokens = balanceOf(to);
            require((heldTokens + amount) <= max_Hold, "Over max wallet limit");
            }


        // Transaction limit - To send over the transaction limit the sender AND the recipient must be limit exempt (or increase transaction limit)
        if (!_isLimitExempt[to] || !_isLimitExempt[from])
            {
            require(amount <= max_Tran, "Over max transaciton limit");
            }


        // Compliance and safety checks
        require(from != address(0), "Transfer from the 0 address");
        require(to != address(0), "Transfer to the 0 address");
        require(amount > 0, "Amount must be greater than 0");



        // Check number of transactions required to trigger fee processing - can only trigger on sells
        if( _isPair[to] &&
            !inSwapAndLiquify &&
            swapAndLiquifyEnabled
            )
            {

            // Check that enough transactions have passed since last swap
            if(swapCounter >= swapTrigger){

            // Check number of tokens on contract
            uint256 contractTokens = balanceOf(address(this));

            // Only trigger fee processing if there are tokens to swap!
            if (contractTokens > 0){

                // Limit number of tokens that can be swapped 
                if (contractTokens <= swap_Max){
                    swapAndLiquify (contractTokens);
                    } else {
                    swapAndLiquify (swap_Max);
                    }
            }
            }  
            }


        // Only charge a fee on buys and sells, no fee for wallet transfers
        bool takeFee = true;
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to] || (!_isPair[to] && !_isPair[from])){
            takeFee = false;
        }

        _tokenTransfer(from, to, amount, takeFee);

    }


    // Process fees
    function swapAndLiquify(uint256 Tokens) private {

        /*
        
        Fees are processed as an average of each buy/sell fee total      

        */

        // Lock swapAndLiquify function
        inSwapAndLiquify        = true;  

        uint256 _FeesTotal      = (_SwapFeeTotal_Buy + _SwapFeeTotal_Sell);
        uint256 LP_Tokens       = Tokens * (_Fee__Buy_Liquidity + _Fee__Sell_Liquidity) / _FeesTotal / 2;
        uint256 Swap_Tokens     = Tokens - LP_Tokens;

        // Swap tokens for BNB
        uint256 contract_BNB    = address(this).balance;
        swapTokensForBNB(Swap_Tokens);
        uint256 returned_BNB    = address(this).balance - contract_BNB;

        // Double fees instead of halving LP fee to prevent rounding errors if fee is an odd number
        uint256 fee_Split = _FeesTotal * 2 - (_Fee__Buy_Liquidity + _Fee__Sell_Liquidity);

        // Calculate the BNB values for each fee (excluding BNB wallet)
        uint256 BNB_Liquidity   = returned_BNB * (_Fee__Buy_Liquidity     + _Fee__Sell_Liquidity)       / fee_Split;
        uint256 BNB_Contract    = returned_BNB * (_Fee__Buy_Contract      + _Fee__Sell_Contract)    * 2 / fee_Split;

        // Add liquidity 
        if (LP_Tokens != 0){
            addLiquidity(LP_Tokens, BNB_Liquidity);
            emit SwapAndLiquify(LP_Tokens, BNB_Liquidity, LP_Tokens);
        }
   

        // Take developer fee
        if(BNB_Contract > 0){

        // Check Affiliate is genuine - (Holds the TokensByGEN Affiliate Token)
        if(AFF.balanceOf(Wallet_TBG_AFF) > 0){

                if(GEN.balanceOf(Wallet_TBG_AFF) >= Tier_3){

                // Tier 3 - Split 70% Contract, 20% Affiliate, 10% Fee Discount
                Wallet_TBG_AFF.transfer(BNB_Contract * 20 / 100);
                feeCollector.transfer(BNB_Contract * 70 / 100); 


                } else if (GEN.balanceOf(Wallet_TBG_AFF) >= Tier_2){

                // Tier 2 - Split 75% Contract, 15% Affiliate, 10% Fee Discount
                Wallet_TBG_AFF.transfer(BNB_Contract * 15 / 100);
                feeCollector.transfer(BNB_Contract * 75 / 100); 


                } else {

                // Tier 1 - Split 80% Contract, 10% Affiliate, 10% Fee Discount
                Wallet_TBG_AFF.transfer(BNB_Contract * 10 / 100);
                feeCollector.transfer(BNB_Contract * 80 / 100); 

                }

        } else {

            // No affiliate 100% of contract fee to fee collector 
            feeCollector.transfer(BNB_Contract); 
            }
        }

        
        // Send remaining BNB to BNB wallet (includes 10% fee discount if applicable)
        contract_BNB = address(this).balance;
        if(contract_BNB > 0){
        Wallet_BNB.transfer(contract_BNB); 
        }


        // Reset transaction counter (reset to 1 not 0 to save gas)
        swapCounter = 1;

        // Unlock swapAndLiquify function
        inSwapAndLiquify = false;
    }



    // Swap tokens for BNB
    function swapTokensForBNB(uint256 tokenAmount) private {

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



    // Add liquidity and send Cake LP tokens to liquidity collection wallet
    function addLiquidity(uint256 tokenAmount, uint256 BNBAmount) private {

        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: BNBAmount}(
            address(this),
            tokenAmount,
            0, 
            0,
            Wallet_Liquidity, 
            block.timestamp
        );
    } 







    /*

    TAKE FEES

    */


    // Take non-token fees and add to contract
    function _takeSwap(uint256 _tSwapFeeTotal, uint256 _rSwapFeeTotal) private {

        _rOwned[address(this)] += _rSwapFeeTotal;
        if(_isExcluded[address(this)])
        _tOwned[address(this)] += _tSwapFeeTotal;

    }


    // Take the Tokens fee
    function _takeTokens(uint256 _tTokens, uint256 _rTokens) private {

        _rOwned[Wallet_Tokens] += _rTokens;
        if(_isExcluded[Wallet_Tokens])
        _tOwned[Wallet_Tokens] += _tTokens;

    }

    // Adjust RFI for reflection balance
    function _takeReflect(uint256 _tReflect, uint256 _rReflect) private {

        _rTotal -= _rReflect;
        _tFeeTotal += _tReflect;

    }








    /*

    TRANSFER TOKENS AND CALCULATE FEES

    */


    uint256 private tAmount;
    uint256 private rAmount;

    uint256 private tBurn;
    uint256 private rBurn;
    uint256 private tReflect;
    uint256 private rReflect;
    uint256 private tTokens;
    uint256 private rTokens;
    uint256 private tSwapFeeTotal;
    uint256 private rSwapFeeTotal;
    uint256 private tTransferAmount;
    uint256 private rTransferAmount;

    

    // Transfer Tokens and Calculate Fees
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {

        // Calculate the transfer fees
        tAmount = amount;

        if (!takeFee){

            tBurn           = 0;    // Auto Burn Fee
            tTokens         = 0;    // Tokens to external wallet fee
            tReflect        = 0;    // Reflection Fee
            tSwapFeeTotal   = 0;    // BNB, Liquidity and Contract Fee

        } else {

        // Increase the transaction counter - only increase if required to save gas on buys when already in trigger zone
        if (swapCounter < swapTrigger){
            swapCounter++;
            }

        if(_isPair[sender]){

            // Buy fees
            tBurn           = tAmount * _Fee__Buy_Burn        / 100;
            tTokens         = tAmount * _Fee__Buy_Tokens      / 100;
            tReflect        = tAmount * _Fee__Buy_Reflection  / 100;
            tSwapFeeTotal   = tAmount * _SwapFeeTotal_Buy     / 100;

        } else {

            // Sell fees
            tBurn           = tAmount * _Fee__Sell_Burn       / 100;
            tTokens         = tAmount * _Fee__Sell_Tokens     / 100;
            tReflect        = tAmount * _Fee__Sell_Reflection / 100;
            tSwapFeeTotal   = tAmount * _SwapFeeTotal_Sell    / 100;

        }
        }

        // Calculate reflected fees for RFI
        uint256 RFI     = _getRate(); 

        rAmount         = tAmount       * RFI;
        rBurn           = tBurn         * RFI;
        rTokens         = tTokens       * RFI;
        rReflect        = tReflect      * RFI;
        rSwapFeeTotal   = tSwapFeeTotal * RFI;

        tTransferAmount = tAmount - (tBurn + tTokens + tReflect + tSwapFeeTotal);
        rTransferAmount = rAmount - (rBurn + rTokens + rReflect + rSwapFeeTotal);

        
        // Swap tokens based on RFI status of sender and recipient
        if (_isExcluded[sender] && !_isExcluded[recipient]) {

        _tOwned[sender] -= tAmount;
        _rOwned[sender] -= rAmount;

        if (deflationaryBurn && recipient == Wallet_Burn) {

        // Remove tokens from Total Supply 
        _tTotal -= tTransferAmount;
        _rTotal -= rTransferAmount;

        } else {

        _rOwned[recipient] += rTransferAmount;

        }

        emit Transfer(sender, recipient, tTransferAmount);

        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {

        _rOwned[sender] -= rAmount;

        if (deflationaryBurn && recipient == Wallet_Burn) {

        // Remove tokens from Total Supply 
        _tTotal -= tTransferAmount;
        _rTotal -= rTransferAmount;

        } else {

        _tOwned[recipient] += tTransferAmount;
        _rOwned[recipient] += rTransferAmount;

        }

        emit Transfer(sender, recipient, tTransferAmount);

        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {

        _rOwned[sender] -= rAmount;

        if (deflationaryBurn && recipient == Wallet_Burn) {

        // Remove tokens from Total Supply 
        _tTotal -= tTransferAmount;
        _rTotal -= rTransferAmount;

        } else {

        _rOwned[recipient] += rTransferAmount;

        }

        emit Transfer(sender, recipient, tTransferAmount);

        } else if (_isExcluded[sender] && _isExcluded[recipient]) {

        _tOwned[sender] -= tAmount;
        _rOwned[sender] -= rAmount;

        if (deflationaryBurn && recipient == Wallet_Burn) {

        // Remove tokens from Total Supply 
        _tTotal -= tTransferAmount;
        _rTotal -= rTransferAmount;

        } else {

        _tOwned[recipient] += tTransferAmount;
        _rOwned[recipient] += rTransferAmount;

        }

        emit Transfer(sender, recipient, tTransferAmount);

        } else {

        _rOwned[sender] -= rAmount;

        if (deflationaryBurn && recipient == Wallet_Burn) {

        // Remove tokens from Total Supply 
        _tTotal -= tTransferAmount;
        _rTotal -= rTransferAmount;

        } else {

        _rOwned[recipient] += rTransferAmount;

        }

        emit Transfer(sender, recipient, tTransferAmount);

        }



        // Take reflections
        if(tReflect != 0){_takeReflect(tReflect, rReflect);}

        // Take tokens
        if(tTokens != 0){_takeTokens(tTokens, rTokens);}

        // Take fees that require processing during swap and liquify
        if(tSwapFeeTotal != 0){_takeSwap(tSwapFeeTotal, rSwapFeeTotal);}

        // Remove Deflationary Burn from Total Supply
        if(tBurn != 0){

            _tTotal = _tTotal - tBurn;
            _rTotal = _rTotal - rBurn;

        }



    }


   

    // This function is required so that the contract can receive BNB during fee processing
    receive() external payable {}




}
















































// Contract Created by https://TokensByGEN.com/
// Not open source - Can not be used or forked without permission.