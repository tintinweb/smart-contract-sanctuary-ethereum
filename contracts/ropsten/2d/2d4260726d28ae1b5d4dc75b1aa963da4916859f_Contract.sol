/**
 *Submitted for verification at Etherscan.io on 2022-06-15
*/

// SPDX-License-Identifier: Unlicensed 
// This contract is not open source and can not be used/forked without permission

/*

1. Deploy to contract 
2. Add LP directly from contract
3. Burn Cake Tokens
4. Renounce ownership 


NEXT TRY

All check on and off with adding liqudidty 
exclude contract from rewards and check adding LP


*/





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

/*
contract TokensByGEN_Factory is Context {

    // Factory Switch
    bool public Factory_Active = true;

    // Affiliate Tracking
    IERC20 GEN = IERC20(0x7d7a7f452e04C2a5df792645e8bfaF529aDcCEcf); // GEN - For tracking affiliate level
    IERC20 AFF = IERC20(0x98A70E83A53544368D72940467b8bB05267632f4); // TokensByGEN Affiliate Tracker Token

    // Fee Collector Contract - For sending token creation fee
    address payable private FeeCollectorContract = payable(0xde491C65E507d281B6a3688d11e8fC222eee0975);


    uint256 private Tier_2 =  500000 * 10**9; 
    uint256 private Tier_3 = 1000000 * 10**9; 

    uint256 public PayNowFEE = 1*10**18; 

    function CreateToken_PaymentOption(string memory Token_Name, 
                                       string memory Token_Symbol, 
                                       uint256 Total_Supply, 
                                       uint256 Number_Of_Decimals, 
                                       address payable Owner_Wallet_Address, 
                                       address payable Discount_Code) public payable {

    // Check is Factory is Active
    require(Factory_Active, "Sorry, the factory is not currently active, check website");

    // Payment for contract 1BNB or 1% of future transactions
    require((msg.value == PayNowFEE) || (msg.value == 0),"Fee must be 1 BNB or 0 BNB");

    // If paying 1 BNB up front, check affiliate status
    if (msg.value == PayNowFEE){
                // Check Affiliate is genuine - (Holds the TokensByGEN Affiliate Token)
                if(AFF.balanceOf(Discount_Code) > 0){


                        if(GEN.balanceOf(Discount_Code) >= Tier_3){

                        // Tier 3 - Split 70% Contract, 20% Affiliate, 10% Refund to Client
                        Owner_Wallet_Address.transfer(msg.value * 10 / 100);
                        Discount_Code.transfer(msg.value * 20 / 100);
                        FeeCollectorContract.transfer(msg.value * 70 / 100); 


                        } else if (GEN.balanceOf(Discount_Code) >= Tier_2){

                        // Tier 2 - Split 75% Contract, 15% Affiliate, 10% Refund to Client
                        Owner_Wallet_Address.transfer(msg.value * 10 / 100);
                        Discount_Code.transfer(msg.value * 15 / 100);
                        FeeCollectorContract.transfer(msg.value * 75 / 100); 


                        } else {

                        // Tier 1 - Split 80% Contract, 10% Affiliate, 10% Refund to Client
                        Owner_Wallet_Address.transfer(msg.value * 10 / 100);
                        Discount_Code.transfer(msg.value * 10 / 100);
                        FeeCollectorContract.transfer(msg.value * 80 / 100); 

                        }

                } else {

                // Transfer Fee to Collector Wallet
                FeeCollectorContract.transfer(msg.value);

                }
    }

    // Set ongoing contract fee to 1% if not paying up front
    uint256 SetContractFee;
    if (msg.value == 0) {SetContractFee = 1;} else {SetContractFee = 0;}
  
    new Contract(Token_Name,
                 Token_Symbol,
                 Total_Supply, 
                 Number_Of_Decimals, 
                 Owner_Wallet_Address, 
                 Discount_Code, 
                 SetContractFee);

    }

    // Allow contract to receive payment 
    receive() external payable {}

    // Purge BNB
    function Purge_BNB() external {
    FeeCollectorContract.transfer(address(this).balance);
    }

    // Purge Tokens
    function Purge_Tokens(address random_Token_Address, uint256 percent_of_Tokens) external {
        uint256 totalRandom = IERC20(random_Token_Address).balanceOf(address(this));
        uint256 removeRandom = totalRandom * percent_of_Tokens / 100;
        IERC20(random_Token_Address).transfer(FeeCollectorContract, removeRandom);
    }

    // Pause Factory 
    function Pause_Factory(bool PauseFactory) external {
        // Function locked to GEN wallet
        require(msg.sender == 0xD05895EDF847e1712721Cc9e0427Aa26289A6Bc5, "Only GEN can do this!");
        Factory_Active = PauseFactory;

    }

}


*/


contract Contract is Context, IERC20 { 

    using SafeMath for uint256;
    using Address for address;

    address private _owner;
    address private Initial_Owner;

    // Wallets
    address public Wallet_Tokens;
    address payable public Wallet_BNB;

    // Affiliate Wallet
    address payable public TokensByGEN_Affiliate;

    // Only used if the 1% transaction fee option is chosen 
    address payable public feeCollector = payable(0xde491C65E507d281B6a3688d11e8fC222eee0975); 

    // Basic token info
    string private _name;
    string private _symbol;
    uint256 private _decimals;
    uint256 private _tTotal;

    // Wallet and transaction limits we be locked at 1% of total supply at launch
    uint256 private max_Hold;
    uint256 private max_Tran;

    // Fees - Set fees before opening trade
    uint256 public _Fee_Buy_Burn            = 0;
    uint256 public _Fee_Buy_Contract        = 0;
    uint256 public _Fee_Buy_Liquidity       = 0;
    uint256 public _Fee_Buy_BNB             = 0;
    uint256 public _Fee_Buy_Reflection      = 0;
    uint256 public _Fee_Buy_Tokens          = 0;

    uint256 public _Fee_Sell_Burn           = 0;
    uint256 public _Fee_Sell_Contract       = 0;
    uint256 public _Fee_Sell_Liquidity      = 0;
    uint256 public _Fee_Sell_BNB            = 0;
    uint256 public _Fee_Sell_Reflection     = 0;
    uint256 public _Fee_Sell_Tokens         = 0;

    // Upper limit for fee processing trigger
    uint256 private swap_Max = _tTotal / 200;

    // Total fees that are processed on buys and sells for swap and liquify calculations
    uint256 private _SwapFeeTotal_Buy       = 0;
    uint256 private _SwapFeeTotal_Sell      = 0;

    // Track contract fee
    uint256 private ContractFee;

    // Supply Tracking for RFI
    uint256 private _rTotal;
    uint256 private _tFeeTotal;
    uint256 private constant MAX = ~uint256(0);

    // Launch tracking
    uint256 private LaunchBlock = 0;
    bool private LaunchPhase = false;


    // Token social link will appear on BSCScan
    string private Project_Link;



    // Affiliate Tracking
    IERC20 GEN = IERC20(0x7d7a7f452e04C2a5df792645e8bfaF529aDcCEcf); // GEN - For tracking affiliate level
    IERC20 AFF = IERC20(0x98A70E83A53544368D72940467b8bB05267632f4); // TokensByGEN Affiliate Tracker Token


    uint256 private Tier_2 =  500000 * 10**9;
    uint256 private Tier_3 = 1000000 * 10**9;


    // Set router on PCS
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;






/*



    constructor (string memory      _TokenName, 
                 string memory      _TokenSymbol,  
                 uint256            _TotalSupply, 
                 uint256            _Decimals, 
                 address payable    _OwnerWallet,
                 address payable    _Discount_Code, 
                 uint256            _ContractFee) {
    

    // Set owner
    _owner                  = _OwnerWallet;
    Initial_Owner           = _OwnerWallet;

    // Set affiliate
    TokensByGEN_Affiliate   = _Discount_Code;

    // Set basic token details
    _name                   = _TokenName;
    _symbol                 = _TokenSymbol;
    _decimals               = _Decimals;
    _tTotal                 = _TotalSupply * 10**_decimals;
    _rTotal                 = (MAX - (MAX % _tTotal));

    // Set BNB and Token wallets (can be updated later)
    Wallet_BNB              = _OwnerWallet;
    Wallet_Tokens           = _OwnerWallet;

    // Set Wallet limits to 1%
    max_Hold                = _tTotal / 100;
    max_Tran                = _tTotal / 100;

    // Set contract fee 
    ContractFee             = _ContractFee;

*/
    constructor (){

         // Set owner
    _owner                  = 0x627C95B6fD9026E00Ab2c373FB08CC47E02629a0;
    Initial_Owner           = 0x627C95B6fD9026E00Ab2c373FB08CC47E02629a0;

    // Set affiliate
    TokensByGEN_Affiliate   = payable(0x627C95B6fD9026E00Ab2c373FB08CC47E02629a0);

    // Set basic token details
    _name                   = "Test";
    _symbol                 = "Test";
    _decimals               = 4;
    _tTotal                 = 1000000 * 10**_decimals;
    _rTotal                 = (MAX - (MAX % _tTotal));

    // Set BNB and Token wallets (can be updated later)
    Wallet_BNB              = payable(0x627C95B6fD9026E00Ab2c373FB08CC47E02629a0);
    Wallet_Tokens           = 0x627C95B6fD9026E00Ab2c373FB08CC47E02629a0;

    // Set Wallet limits to 1%
    max_Hold                = _tTotal / 100;
    max_Tran                = _tTotal / 100;

    // Set contract fee 
    ContractFee             = 1;









    // Set PancakeSwap Router Address
   ///  IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); 
 ///   IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); 
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);  // ETH





    // Create initial liquidity pair with BNB on PancakeSwap factory
    uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
    uniswapV2Router = _uniswapV2Router;

    // Wallet that are excluded from holding limits
    _isLimitExempt[address(this)] = true;
    _isLimitExempt[Wallet_Burn] = true;
    _isLimitExempt[uniswapV2Pair] = true;

    // Wallets that are excluded from fees
    _isExcludedFromFee[address(this)] = true; 
    _isExcludedFromFee[Wallet_Burn] = true;


    // Exclude from Rewards
    _isExcluded[Wallet_Burn] = true;
    _isExcluded[uniswapV2Pair] = true;
    //_isExcluded[address(this)] = true;

    // Push excluded wallets to array
    _excluded.push(Wallet_Burn);
    _excluded.push(uniswapV2Pair);
    //_excluded.push(address(this));


    // Transfer token supply to contract
    _tOwned[address(this)]  = _tTotal;
    _rOwned[address(this)]  = _rTotal;

    // Emit Supply Transfer to Contract
    emit Transfer(address(0), address(this), _tTotal);

    // Emit ownership transfer
    emit OwnershipTransferred(address(0), _owner);

    }


    
    // Events
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event updated_Wallet_BNB(address indexed oldWallet, address indexed newWallet);
    event updated_Wallet_Tokens(address indexed oldWallet, address indexed newWallet);
    event updated_Buy_Fees(uint256 BNB, uint256 Liquidity, uint256 Reflection, uint256 Tokens, uint256 Contract_Development_Fee);
    event updated_Sell_Fees(uint256 BNB, uint256 Liquidity, uint256 Reflection, uint256 Tokens, uint256 Contract_Development_Fee);
    event updated_SwapAndLiquify_Enabled(bool Swap_and_Liquify_Enabled);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);

    // Restrict function to contract owner only 
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    // Address mappings
    mapping (address => uint256) private _tOwned;                               // Tokens Owned
    mapping (address => uint256) private _rOwned;                               // Reflected balance
    mapping (address => mapping (address => uint256)) private _allowances;      // Allowance to spend another wallets tokens
    mapping (address => bool) public _isExcludedFromFee;                        // Wallets that do not pay fees
    mapping (address => bool) public _isExcluded;                               // Excluded from RFI rewards
    mapping (address => bool) public _isLimitExempt;                            // Wallets that are excluded from HOLD and TRANSFER limits
    mapping (address => bool) public _isSnipe;                                  // Sniper!
    mapping (address => bool) public _isBlacklisted;                            // Blacklist wallet - can only be added pre-launch!
    address[] private _excluded;                                                // Array of wallets excluded from rewards

    // Burn (dead) address
    address public constant Wallet_Burn = 0x000000000000000000000000000000000000dEaD; 

    // Swap triggers
    uint256 private swapCounter = 1;     // Start at 1 not zero to save gas
    
    // SwapAndLiquify - Automatically processing fees and adding liquidity                                   
    bool public inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;




    // Token information 
    function Token_Information() external view returns(string memory Token_Name,
                                                       string memory Token_Symbol,
                                                       uint256 Number_of_Decimals,
                                                       address Owner_at_Launch,
                                                       address BNB_Wallet,
                                                       address Token_Wallet,
                                                       uint256 Transaction_Limit,
                                                       uint256 Max_Wallet,
                                                       uint256 Fee_When_Buying,
                                                       uint256 Fee_When_Selling,
                                                       string memory Project_Website,
                                                       string memory Contract_Created_By) {
                                             
        string memory Creator = "https://tokensbygen.com/";

        // Return Token Data
        return (_name,
                _symbol,
                _decimals,
                Initial_Owner,
                Wallet_BNB,
                Wallet_Tokens,
                max_Tran / 10 ** _decimals,
                max_Hold / 10 ** _decimals,
                (_SwapFeeTotal_Buy + _Fee_Buy_Burn + _Fee_Buy_Reflection + _Fee_Buy_Tokens),
                (_SwapFeeTotal_Sell + _Fee_Sell_Burn + _Fee_Sell_Reflection + _Fee_Sell_Tokens),
                Project_Link,
                Creator);

    }

    function Liquidity_Status() external view returns(uint256 Total_Liquidity,
                                                      uint256 Burned_Liquidity,
                                                      uint256 Percent_Burned) {

        // LP that has been burned
        uint256 BurnedLP = IERC20(uniswapV2Pair).balanceOf(Wallet_Burn);

        // Total LP Tokens
        uint256 TotalLP = IERC20(uniswapV2Pair).totalSupply();

        // Percent of LP burned
        uint256 PercentLP = 0;
        if (BurnedLP == TotalLP){PercentLP = 100;} else {
        PercentLP = (BurnedLP * 100 / TotalLP);}

        return (TotalLP,
                BurnedLP,
                PercentLP
                );

    }

    



    /* 

    -------------------------------
    CONTRACT SET UP - STEP-BY-STEP!
    -------------------------------
    
    -----------------------
    1. Set External Wallets
    -----------------------
    
    During deployment, all wallets were set to the owner wallet, but you can update them here if required.
    You can keep all 3 wallets the same, there is no need to update them. 

    Once the contract has deployed the wallets can never be changed. So be extremely careful with your private key and pass phrase. 
    Don't use these wallets for anything outside of this project and never connect them to a website that you do not 100% trust.

    Remember, after deploying, your fees can not be changed, and these wallets can not be changed. 
    You definitely do not want a scammer gaining access to the wallet that receives your marketing funds! 

    ----------
    BNB_Wallet
    ----------

    The BNB_Wallet will receive BNB when the contract processes the tokenomics. 
    This is usually used for marketing, but it will depend on the needs of your project.

    Please be sure to explain how you plan to use these funds on your website. So long as you are fully transparent, 
    you can use the BNB for anything! It could be used to pay your team, cover marketing expenses, donate to charity, etc.

    This contact requires a minimum of 1 BNB in liquidity to launch, and that is automatically sent to the burn address
    to protect your investors. If you paid the initial liquidity out of your own pocket, you may want to reimburse that 
    expense from the BNB wallet gradually until it is fully recovered. 

    The golden rule is to tell people. Be honest and fully transparent about how you plan to use this money.

    ------------
    Token_Wallet 
    ------------

    The token wallet is often a better choice than the BNB wallet for taking a fee. 
    This fee is sent to an external wallet in tokens, so it doesn't have a negative impact on your chart. 
    Team members that believe the project will be successful often prefer to get paid in tokens, as their payment will increase in value over time. 

    Tokens collected in this wallet can be used to fund various utilities for your token, such as staking pools, giveaway events,
    and adding additional liquidity etc.

    Again, be fully transparent. Let people know how you plan to use these tokens.

    The token wallet is not excluded from limits, so if your token wallet is full it will not receive any more tokens.
    If this happens, the fee that feeds the token wallet will be set to 0 until there is enough space in the wallet again. 


    */

    function Step_1__Set_External_Wallets(address payable BNB_Wallet, address Token_Wallet) external onlyOwner {

        require(BNB_Wallet != address(0), "BNB Wallet can not be 0x0");
        emit updated_Wallet_BNB(Wallet_BNB, BNB_Wallet);
        Wallet_BNB = BNB_Wallet;

        require(Token_Wallet != address(0), "Token Wallet can not be 0x0");
        emit updated_Wallet_Tokens(Wallet_Tokens, Token_Wallet);
        Wallet_Tokens = Token_Wallet;

    }



    /*

    ------------------------
    2. Set Contract Buy Fees
    ------------------------

    Your buy and sell fees can be set independently. However, both are limited to a maximum of 12% 
    If you chose the 1% ongoing contract fee it is included in the max fee limit, so the rest of the fees can not be over 9.

    Because this contract will auto-renounce, we can not provide wallet to wallet transfers for free. This feature requires an active owner to 
    update liquidity pairs, so any movement of tokens will incur a fee. This sounds unfair, but it is the default for most contracts. 

    Most developers choose to set the buy fee lower than the sell fee, for this reason, moving tokens when not buying or selling will use
    the buy fee amounts.

    */


    // Set Buy Fees - Max possible 12% (including 1% contract fee if applicable)
    function Step_2__Set_Fees_on_Buy(uint256 BNB_on_BUY, 
                                     uint256 Liquidity_on_BUY, 
                                     uint256 Reflection_on_BUY, 
                                     uint256 Burn_on_BUY,  
                                     uint256 Tokens_on_BUY) external onlyOwner {

        _Fee_Buy_Contract = ContractFee;

        // Buyer protection - max fee can not be set over 12% (including possible 1% contract fee if chosen)
        require(BNB_on_BUY + Liquidity_on_BUY + Reflection_on_BUY + Burn_on_BUY + Tokens_on_BUY + _Fee_Buy_Contract <= 12, "Buy Fees too high"); 

        // Update fees
        _Fee_Buy_BNB        = BNB_on_BUY;
        _Fee_Buy_Liquidity  = Liquidity_on_BUY;
        _Fee_Buy_Reflection = Reflection_on_BUY;
        _Fee_Buy_Burn       = Burn_on_BUY;
        _Fee_Buy_Tokens     = Tokens_on_BUY;

        // Fees that will need to be processed during swap and liquify
        _SwapFeeTotal_Buy   = _Fee_Buy_BNB + _Fee_Buy_Liquidity + _Fee_Buy_Contract;

        emit updated_Buy_Fees(_Fee_Buy_BNB, _Fee_Buy_Liquidity, _Fee_Buy_Reflection, _Fee_Buy_Tokens, _Fee_Buy_Contract);
    }







    /*

    -------------------------
    3. Set Contract Sell Fees
    -------------------------
    
    Remember that the total sell fee is limited to 12% and includes the 1% contract fee if applicable.

    */

    // Set Sell Fees - Max possible 12% (including 1% contract fee if applicable)
    function Step_3__Set_Fees_on_Sell(uint256 BNB_on_SELL,
                                      uint256 Liquidity_on_SELL, 
                                      uint256 Reflection_on_SELL, 
                                      uint256 Burn_on_SELL,
                                      uint256 Tokens_on_SELL) external onlyOwner {

        _Fee_Sell_Contract = ContractFee;

        // Buyer protection - max fee can not be set over 12% (including possible 1% contract fee if chosen)
        require(BNB_on_SELL + Liquidity_on_SELL + Reflection_on_SELL + Burn_on_SELL + Tokens_on_SELL + _Fee_Sell_Contract <= 12, "Sell Fees too high"); 

        // Update fees
        _Fee_Sell_BNB        = BNB_on_SELL;
        _Fee_Sell_Liquidity  = Liquidity_on_SELL;
        _Fee_Sell_Reflection = Reflection_on_SELL;
        _Fee_Sell_Burn       = Burn_on_SELL;
        _Fee_Sell_Tokens     = Tokens_on_SELL;

        // Fees that will need to be processed during swap and liquify
        _SwapFeeTotal_Sell   = _Fee_Sell_BNB + _Fee_Sell_Liquidity + _Fee_Sell_Contract;

        emit updated_Sell_Fees(_Fee_Sell_BNB, _Fee_Sell_Liquidity, _Fee_Sell_Reflection, _Fee_Sell_Tokens, _Fee_Sell_Contract);
    }




    /*

    ------------------------
    4. Add your Project Link
    ------------------------
    
    Adding a link to your project (preferably your website, but at the very least your Telegram group!) will help people to find your project.
    Many people buy tokens when they see them on BSC or even the APE tool on PooCoin, without a link to your project it's very difficult for them
    to find your community. 

    Obviously, you'll want to include all of your social links on your website, as well as information about your project, so that is always the 
    best link to provide.

    Be sure to add the complete link, including the http as some websites will recognize this and include the link with your token.

    */

    // Enter the website (or Telegram Group Link) for your project 
    function Step_4__Add_Project_URL(string memory Project_URL) external onlyOwner{

        Project_Link = Project_URL;

    }







    /* 

    -----------------
    5. Blacklist Bots
    -----------------

    Your contract includes code that will help to protect it from sniper bots, but if you know a wallet is using a bot, it's much better to block them completely.
    When you blacklist a wallet address, that person can never buy your token (or be sent) your token. If they are already holding it they can't sell it
    nor move it to another wallet. 

    Obviously, we are blacklisting wallets before we launch, so they'll never be able to get your token under any circumstances.

    PooCoin have a very handy tool that you can use to see wallet addresses that are actively using sniper bots. It's a good idea to grab those wallets
    and blacklist them. You can access the tool at https://poocoin.app/sniper-watcher

    You might also want to look at other recent tokens that you know got attacked by bots at launch, check the transactions in the first block and it'll be
    clear which are bots. Real people can't buy in the very first second multiple times! Collect up those addresses to and add them to your blacklist.

    -------------
    Anti-Bot Code
    -------------

    Your contract does a pretty good job of protecting itself from sniper bots, but it's not 100% bot-proof (nothing is!)
    The problem is that using code to protect a contract exposes the code, so a bot creator can code a bot to bypass your protection. 
    But 'bot creators' aren't the main problem. Most bot users have no idea how to create a bot, or update one to bypass anti-bot code!
    most bot users bought the bot online and have no idea how it works under the hood. Your contract is pretty well protected from these, but manual blacklisting 
    known bots is always a good idea too. 

    How the Anti-Bot code works 

    Most sniper bots try to buy in the very first second. People can't do that. The tools we use to buy are much too slow to get a transaction to go through that
    quickly. So your contract automatically tags wallets that buy in the first block as bots. It doesn't block them, it allows them to buy, but it very aggressively
    limits how much they can buy. They will only be able to buy 0.01% of total supply. 

    By allowing the bot to buy a tiny amount, it's possible to tag it and prevent it from buying again. So we block the bot for about a minute. Giving real people
    the chance to buy and increase the price so that when the bot can buy again it's no longer interested. 

    I've done a lot of testing with various ways to control bots, and of all the methods I've tried, this is one of the more successful ways of protecting 
    your contract without doing anything too dodgy. Bot users are real people. You can't ethically (and probably legally) just take their money. A lot of devs
    increase fees to 90% if they detect a bot. That's not a good solution, it could get you into trouble and often catches non-bot users by mistake.

    ---------------------
    How to blacklist bots
    ---------------------

    To blacklist wallets, don't do too many at once. Loops require gas and too many wallets will run out of gas! You should be able to do well over 100 
    wallets at a time, but if you have problems, just run the function again with less wallets. 

    You'll likely only need to blacklist 5 or 10 wallets maximum. 

    Obviously, you can not blacklist the contract itself, the liquidity pair or any of the external wallets, that'd break the contract. So we have require statements
    in place to protect against this. If the function keeps failing, double check that you are not accidentally trying to block one of these wallets. It happens 
    more often than you'd expect!

    When adding wallets, keep them comma separated, but without any spaces.

    Remember, once added to the blacklist, they can never be removed!!

    */


    // Blacklist known bot users (comma separate wallets with no spaces!)
    function Step_5__Blacklist_Bots(address[] calldata Wallets) external onlyOwner {
      
        for (uint256 i; i < Wallets.length; ++i) {

            // Can not blacklist any of the contract wallets!
            require(Wallets[i] != _owner);
            require(Wallets[i] != Wallet_BNB);
            require(Wallets[i] != Wallet_Burn);
            require(Wallets[i] != uniswapV2Pair);
            require(Wallets[i] != Wallet_Tokens);
            require(Wallets[i] != address(this));

            _isBlacklisted[Wallets[i]] = true;

      }

    }



    /*
    
    ------------------------------------------------
    6. Add Liquidity, Renounce Ownership and Launch!
    ------------------------------------------------
    
    When you run this function there is no turning back! Your contract will be live... and your liquidity will already be burned!

    This contract is all about protecting buyers. So it's much more restrictive than most, 100% of your supply will be added to the initial
    liquidity (no exceptions!) along with a minimum of 1 BNB.

    When you add your liquidity and deploy, the contract automatically burns the liquidity. So it's basically locked forever.
    It's the safest option for your holders, but it does mean that you can never get it back, under any circumstances. 
    
    -------------
    Auto Renounce
    -------------

    When you deploy, the contract auto renounces ownership. This means that you can no longer make any changes. Access to all external 
    functions will be lost as soon as you run this function. 
    
    ------------------------------------
    Requires 1 BNB Minimum for Liquidity
    ------------------------------------

    The contract requires a minimum of 1 BNB for the initial liquidity. If you don't have 1 BNB, you can't launch. If you 
    don't have 1 BNB, you really shouldn't be making a token! 

    The 1 BNB (hopefully a lot more) that is added to the initial liquidity is not recoverable. And it shouldn't be! There really is 
    no good reason for the liquidity to ever be removed from any token. However, burning it often seems like a waste to some people, so I'd 
    like to offer the following for you to think about...

    Whatever you put into the initial liquidity will be burned. You can't ever get it back.
    Which is kinda similar to spending money on marketing! You spend your money and you don't get it back! 

    By burning all of your initial Liquidity (and your auto liquidity too) you'll dramatically increase buyer confidence, which will ultimately 
    attract more investors... many more investors than any marketing campaign is likely to attract! Marketing is expensive. An AMA in YouTube will usually
    cost $2k or more. Yet the impact that an AMA can have on your chart will not be as powerful as the impact that burning 100% of your liquidity
    will have. 

    So don't think of it as lost money. It isn't. It's a very savvy investment.
    
    ------------------------------
    Automatic and Free Advertising
    ------------------------------

    Tokens that have been created using this contract are automatically featured on my website. We have a growing number of followers
    that are waiting for safe tokens (like this one) to invest in. Obviously, we can not guarantee that your token will be a success, but we can guarantee 
    that it's much safer than 90% of tokens out there! 

    Just by using this contract, investors will buy your token that otherwise wouldn't have. That's definitely worth burning the liquidity... which, as we
    said before, really should never be removed anyway! 
    
    --------------
    No Going Back!
    --------------
    
    Remember, this is it. When you run this function your contract can not be changed again in any way. So make sure you have everything exactly as you 
    want it before you continue. 

    */




    // Add a minimum of 1 BNB for liquidity, burn the initial LP, launch, and renounce the contract!
    function Step_6__Add_Liquidity_Launch_and_Renounce() payable external onlyOwner {

        // Remove limits
        max_Hold = _tTotal;
        max_Tran = _tTotal;

        uint256 BNBAmount = msg.value;
        
        // Initial LP must be 1 BNB or more!
    /////  require (BNBAmount >= 1*10**18, "1 BNB Minimum for LP");

        // Create initial liquidity pool and burn the Cake LP tokens
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Router.addLiquidityETH{value: BNBAmount}(
            address(this),
            _tTotal,
            0, 
            0,
            Wallet_Burn,
            block.timestamp
        );

        // Set limits to 1% of Total Supply
        max_Hold = _tTotal / 100;
        max_Tran = _tTotal / 100;

        // Set Launch info for Anti-Bot Code and Reflection Fee Update
        LaunchBlock = block.number;
        LaunchPhase = true;

        // Renounce the contract
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);

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












  //////// START OF TEST FUNCTIONS


bool public check_1 = true;
bool public check_2 = true;
bool public check_3 = true;
bool public check_4 = true;
bool public check_5 = true;
bool public check_6 = true;

function AA_CHECK_1(bool true_or_false) public {check_1 = true_or_false;}
function AA_CHECK_2(bool true_or_false) public {check_2 = true_or_false;}
function AA_CHECK_3(bool true_or_false) public {check_3 = true_or_false;}
function AA_CHECK_4(bool true_or_false) public {check_4 = true_or_false;}
function AA_CHECK_5(bool true_or_false) public {check_5 = true_or_false;}
function AA_CHECK_6(bool true_or_false) public {check_6 = true_or_false;}


    // Wallet will not get reflections
    function AA_REWARDS_NO(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }


    // Wallet will get reflections - DEFAULT
    function AA_REWARDS_YES(address account) external onlyOwner() {
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

    ///////////// END OF TEST FUNCTIONS




    // Main transfer checks and settings 
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {


if (check_1){

        // Launch Phase
        if (LaunchPhase && to != address(this) && to != uniswapV2Pair)
            {
            require(!_isSnipe[to], "Can not buy until block 20");
            if (block.number == LaunchBlock) {
                require(amount <= _tTotal / 10000, "Over launch limit");
                _isSnipe[to] = true;
                }
            // End Launch Phase after 20 blocks
            if (block.number > LaunchBlock + 20){LaunchPhase = false;}
        }

}
if (check_2){

        // No blacklisted wallets permitted! 
        require(!_isBlacklisted[to],"Wallet is blacklisted");
        require(!_isBlacklisted[from],"Wallet is blacklisted");

}
if (check_3){

        // Wallet Limit
        if (!_isLimitExempt[to])
            {
            uint256 heldTokens = balanceOf(to);
            require((heldTokens + amount) <= max_Hold, "Over max permitted wallet limit");
            }

}
if (check_4){

        // Transaction limit - To send over the transaction limit the sender AND the recipient must be limit exempt
        if (!_isLimitExempt[to] || !_isLimitExempt[from])
            {
            require(amount <= max_Tran, "Over max permitted transaction");
            }
}
if (check_5){

        // Compliance and safety checks
        require(to != address(0), "ERC20: transfer to the zero address");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than 0");

}
if (check_6){


        // Check number of transactions required to trigger fee processing - can only trigger on sells
        if (to == uniswapV2Pair &&
            !inSwapAndLiquify &&
            swapAndLiquifyEnabled
            )
            {

            // Check that enough transactions have passed since last swap
            if(swapCounter >= 11){

            // Check number of tokens on contract
            uint256 contractTokens = balanceOf(address(this));

            // Send contract tokens for processing
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

}

        // Check if fee is required
        bool takeFee = true;
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }

        _tokenTransfer(from, to, amount, takeFee);

    }


    // Process fees
    function swapAndLiquify(uint256 Tokens) private {

        /*
        
        Fees are processed as an average over all buys and sells         

        */

        // Lock Fee Processing
        inSwapAndLiquify        = true;  

        uint256 _FeesTotal      = (_SwapFeeTotal_Buy + _SwapFeeTotal_Sell);
        uint256 LP_Tokens       = Tokens * (_Fee_Buy_Liquidity + _Fee_Sell_Liquidity) / _FeesTotal / 2;
        uint256 Swap_Tokens     = Tokens - LP_Tokens;

        // Swap tokens for BNB
        uint256 contract_BNB    = address(this).balance;
        swapTokensForBNB(Swap_Tokens);
        uint256 returned_BNB    = address(this).balance - contract_BNB;

        // Double fees instead of halving LP fee to prevent rounding errors if fee is an odd number
        uint256 fee_Split = _FeesTotal * 2 - (_Fee_Buy_Liquidity + _Fee_Sell_Liquidity);

        // Calculate the BNB values for each fee
        uint256 BNB_Liquidity   = returned_BNB * (_Fee_Buy_Liquidity     + _Fee_Sell_Liquidity)       / fee_Split;
        uint256 BNB_Contract    = returned_BNB * (_Fee_Buy_Contract      + _Fee_Sell_Contract)    * 2 / fee_Split;

        // Add liquidity 
        if (LP_Tokens != 0){
            addLiquidity(LP_Tokens, BNB_Liquidity);
            emit SwapAndLiquify(LP_Tokens, BNB_Liquidity, LP_Tokens);
        }
   

        // Take developer fee
        if(BNB_Contract > 0){


            contract_BNB = address(this).balance; ////
            if(contract_BNB > 0){Wallet_BNB.transfer(contract_BNB);}  /////
            

            /*

            // Check Affiliate is genuine - (Holds the TokensByGEN Affiliate Token)
            if(AFF.balanceOf(TokensByGEN_Affiliate) > 0){

                        if(GEN.balanceOf(TokensByGEN_Affiliate) >= Tier_3){

                            // Tier 3 - Split 70% Contract, 20% Affiliate, 10% Client
                            TokensByGEN_Affiliate.transfer(BNB_Contract * 20 / 100);
                            feeCollector.transfer(BNB_Contract * 70 / 100); 


                        } else if (GEN.balanceOf(TokensByGEN_Affiliate) >= Tier_2){

                            // Tier 2 - Split 75% Contract, 15% Affiliate, 10% Client
                            TokensByGEN_Affiliate.transfer(BNB_Contract * 15 / 100);
                            feeCollector.transfer(BNB_Contract * 75 / 100); 


                        } else {

                            // Tier 1 - Split 80% Contract, 10% Affiliate, 10% Client
                            TokensByGEN_Affiliate.transfer(BNB_Contract * 10 / 100);
                            feeCollector.transfer(BNB_Contract * 80 / 100); 

                        }

                } else {

                        // No affiliate, 100% of contract fee to fee collector 
                        feeCollector.transfer(BNB_Contract); 
            }
            
            // Send remaining BNB to BNB wallet
            contract_BNB = address(this).balance;
            if(contract_BNB > 0){
            Wallet_BNB.transfer(contract_BNB); 
            }

            */

    }

        // Reset transaction counter (reset to 1 not 0 to save gas)
        swapCounter = 1;

        // Unlock Fee Processing
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


    // Add liquidity and send Cake LP tokens to burn wallet
    function addLiquidity(uint256 tokenAmount, uint256 BNBAmount) private {

        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: BNBAmount}(
            address(this),
            tokenAmount,
            0, 
            0,
            Wallet_Burn, 
            block.timestamp
        );
    } 








    /*

    TAKE FEES

    */


    // Take fees that require processing and add to contract
    function _takeSwap(uint256 _tSwapFeeTotal, uint256 _rSwapFeeTotal) private {

        _rOwned[address(this)] += _rSwapFeeTotal;
        if(_isExcluded[address(this)]){_tOwned[address(this)] += _tSwapFeeTotal;}

    }

    // Take the Tokens fee and send to token wallet
    function _takeTokens(uint256 _tTokens, uint256 _rTokens) private {

        _rOwned[Wallet_Tokens] += _rTokens;
        if(_isExcluded[Wallet_Tokens]){_tOwned[Wallet_Tokens] += _tTokens;}
                   
    }

    // Adjust RFI for reflection balances
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

            tBurn           = 0;    // Deflationary Burn
            tTokens         = 0;    // Tokens to external wallet
            tReflect        = 0;    // Reflection Rewards to Holders
            tSwapFeeTotal   = 0;    // BNB to external wallet

        } else {

        // Increase the transaction counter - only increase if required to save gas on buys when already in trigger zone
        if (swapCounter < 11){
            swapCounter++;
            }

        if(recipient == uniswapV2Pair){

            // Sell fees
            tBurn           = tAmount * _Fee_Sell_Burn       / 100;
            tTokens         = tAmount * _Fee_Sell_Tokens     / 100;
            tReflect        = tAmount * _Fee_Sell_Reflection / 100;
            tSwapFeeTotal   = tAmount * _SwapFeeTotal_Sell   / 100;

                // Check balance of token wallet and don't let it go over max
                uint256 CurrentTokens = balanceOf(Wallet_Tokens);
                if (CurrentTokens + tTokens > max_Hold){

                    // Remove the token fee if the token wallet is at max
                    tTokens = 0;
                }

        } else {

            // Buy fees
            tBurn           = tAmount * _Fee_Buy_Burn        / 100;
            tTokens         = tAmount * _Fee_Buy_Tokens      / 100;
            tReflect        = tAmount * _Fee_Buy_Reflection  / 100;
            tSwapFeeTotal   = tAmount * _SwapFeeTotal_Buy    / 100;

                // Check balance of token wallet and don't let it go over max
                uint256 CurrentTokens = balanceOf(Wallet_Tokens);
                if (CurrentTokens + tTokens > max_Hold){

                    // Remove the token fee if the token wallet is at max
                    tTokens = 0;
                }

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

        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;

        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        

        emit Transfer(sender, recipient, tTransferAmount);

        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {

        _rOwned[sender] = _rOwned[sender] - rAmount;

        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;

        emit Transfer(sender, recipient, tTransferAmount);

        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {

        _rOwned[sender]     = _rOwned[sender] - rAmount;

        _rOwned[recipient]  = _rOwned[recipient] + rTransferAmount;

        emit Transfer(sender, recipient, tTransferAmount);

        } else if (_isExcluded[sender] && _isExcluded[recipient]) {

        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;

        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;

        emit Transfer(sender, recipient, tTransferAmount);

        } else {

        _rOwned[sender]     = _rOwned[sender] - rAmount;

        _rOwned[recipient]  = _rOwned[recipient] + rTransferAmount;

        emit Transfer(sender, recipient, tTransferAmount);

        }

        // Remove Deflationary Burn from Total Supply
        if(tBurn != 0){

            _tTotal -= tBurn;
            _rTotal -= rBurn;

        }

        // Update reflections
        if(tReflect != 0){_takeReflect(tReflect, rReflect);}


        // Take token fee
        if(tTokens != 0){_takeTokens(tTokens, rTokens);}


        // Take fees that require processing during swap and liquify
        if(tSwapFeeTotal != 0){_takeSwap(tSwapFeeTotal, rSwapFeeTotal);}


    }

    // This function is required so that the contract can receive BNB during fee processing
    receive() external payable {}




}