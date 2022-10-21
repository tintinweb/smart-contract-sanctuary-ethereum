/**
 *Submitted for verification at Etherscan.io on 2022-10-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

error Unauthorized();
error InsufficientBalance();
error NonContractCall();
error NeedLiquidity();
error MaxTaxExceeded(uint8 _MAX_TAX);
error BlacklistTimerExceeded();
error AlreadyBlacklisted();
error AlreadyUnblacklisted();
error AlreadyMaxTier();
error AlreadyBaseTier();
error MaxBuyExceeded(uint256 _maxBuy);
error MaxSellExceeded(uint256 _maxSell);
error MaxBalanceExceeded(uint256 _maxBalance);
error UserBlacklisted();
error LiquidityLocked(uint256 unlockInSeconds);
error InvalidInput();

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IUniSwapERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IUniSwapFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniSwapRouter01 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getamountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getamountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getamountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getamountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniSwapRouter02 is IUniSwapRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function _onlyOwner() private view {
        if (owner() != msg.sender) revert Unauthorized();
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) revert InsufficientBalance();
        (bool success, ) = recipient.call{value: amount}("");
        require(success);
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        if (address(this).balance < value) revert InsufficientBalance();
        if (!isContract(target)) revert NonContractCall();
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (!isContract(target)) revert NonContractCall();
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        if (!isContract(target)) revert NonContractCall();
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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
        mapping(bytes32 => uint256) _indexes;
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

    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        require(
            set._values.length > index,
            "EnumerableSet: index out of bounds"
        );
        return set._values[index];
    }

    struct Bytes32Set {
        Set _inner;
    }

    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }
}

contract Baby$DIE is IERC20, Ownable {
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public isBlacklisted;
    mapping(address => bool) public isWhitelisted;
    mapping(address => bool) public taxExempt;
    mapping(address => bool) public limitExempt;
    mapping(address => bool) public tier2;
    mapping(address => bool) public tier3;

    // add mapping store all holder information
    uint256 public totalTokenHolderHistory = 0;  
    mapping (uint256=> address ) public tokenHolderHistory;
    mapping (address=> bool ) public addedToTokenHolderHistory; 

    EnumerableSet.AddressSet private _excluded;
    EnumerableSet.AddressSet private _excludedFromStaking;

    string private _name = "Baby $DIE";
    string private _symbol = "BDIE";
    uint256 private constant INITIAL_SUPPLY = 1_000_000_000 * 10**TOKEN_DECIMALS;
    uint256 private _circulatingSupply;
    uint8 private constant TOKEN_DECIMALS = 18;
    uint8 public constant MAX_TAX = 10; //Team can never set tax higher than this value
    address private constant BURN_ADDRESS =
        0x000000000000000000000000000000000000dEaD;

    struct TaxRatios {
        uint8 burn;
        uint8 buyback;
        uint8 Team;
        uint8 liquidity;
        uint8 Events;
        uint8 Marketing;
        uint8 rewards;
    }

    struct TaxWallets {
        address Team;
        address Events;
        address Marketing;
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

    struct TierTaxes {
        uint8 first;
        uint8 second;
        uint8 third;
    }

    TierTaxes public _buyTaxes = TierTaxes({first: 5, second: 5, third: 5});

    TierTaxes public _sellTaxes = TierTaxes({first: 5, second: 5, third: 5});


    TaxRatios public _taxRatios =
        TaxRatios({
            burn: 0,
            buyback: 0,
            Team: 0,
            liquidity: 40,
            Events: 0,
            Marketing: 60,
            rewards: 0
            //@Team. These are ratios and the divisor will  be set automatically
        });

    TaxWallets public _taxWallet =
        TaxWallets({
            Team: 0x0d7D4e9Bbe63c1FE7888EF65A1Bd4F34163857A8,
            Events: 0x0d7D4e9Bbe63c1FE7888EF65A1Bd4F34163857A8,
            Marketing: 0x0d7D4e9Bbe63c1FE7888EF65A1Bd4F34163857A8
        });

    MaxLimits public _limits;

    LimitRatios public _limitRatios =
        LimitRatios({wallet: 4, sell: 4, buy: 4, divisor: 200});

    uint8 private totalTaxRatio;
    uint8 private totalSwapRatio;
    uint8 private distributeRatio;

    //launchTransferTax -- used to stop transfer of whitelisted tokens
    uint256 launchTransferTax = 99;

    //these values must add up to 100
    uint8 private mainRewardSplit = 100;
    uint8 private miscRewardSplit = 0;

    uint256 private _liquidityUnlockTime;

    //Antibot variables
    bool public isLaunched;
    uint256 private launchBlock;
    uint256 private launchTime;
    uint256 private blacklistWindow = 24 hours;
    uint8 private constant BLACKLIST_BLOCKS = 0; //number of blocks that will be included in auto blacklist
    uint8 private snipersRekt; //variable to track number of snipers auto blacklisted
    bool private blacklistEnabled = true; //blacklist can be enabled/disabled in case something goes wrong
    bool private revertSameBlock = true; //block same block buys

    bool private dynamicBurn = false;
    //dynamicBurn = true will burn all extra sell tax from dynamicSells
    //dynamicBurn = false will divert all extra sell tax to swaps

    bool private dynamicSellsEnabled = false;
    //dynamic sells will increase tax based on price impact
    //any sells over 1% price impact will incur extra sell tax
    //max extra sell tax is 10% when price impact >= 10%

    bool private dynamicLimits = false;
    //dynamicLimits = true will change MaxLimits based on circulating supply rather than total supply

    bool private dynamicLiqEnabled = false;
    //dynamicLiqEnabled = true will stop autoLP if targetLiquidityRatio is met
    //tax meant for liquidity will be redirected to other swap taxes in this case

    uint16 private targetLiquidityRatio = 20; //target liquidity out of 100

    uint16 public swapThreshold = 25; //threshold that contract will swap. out of 1000
    bool public manualSwap;

    //change this address to desired reward token. miscReward is custom chosen by holder
    address public mainReward = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address public _uniswapPairAddress;
    IUniSwapRouter02 private _uniswapRouter;
    address public UniSwapRouter;

    /////////////////////////////   Events  /////////////////////////////////////////
    event AdjustedDynamicSettings(
        bool burn,
        bool limits,
        bool liquidity,
        bool sells
    );
    event AccountExcluded(address account);
    event ChangeMainReward(address newMainReward);
    event ClaimToken(uint256 amount, address token, address recipient);
    event ClaimETH(address from, address to, uint256 amount);
    event EnableBlacklist(bool enabled);
    event EnableManualSwap(bool enabled);
    event ExcludedAccountFromFees(address account, bool exclude);
    event ExcludeFromStaking(address account, bool excluded);
    event ExtendLiquidityLock(uint256 extendedLockTime);
    event UpdateTaxes(uint8 buyTax, uint8 sellTax, uint8 transferTax);
    event RatiosChanged(
        uint8 newBurn,
        uint8 newBuyback,
        uint8 newTeam,
        uint8 newLiquidity,
        uint8 newEvents,
        uint8 newMarketing,
        uint8 newRewards
    );
    event UpdateTeamWallet(address newTeamWallet);
    event UpdateEventsWallet(address newEventsWallet);
    event UpdateMarketingWallet(address newMarketingWallet);
    event UpdateRewardSplit(uint8 newMainSplit, uint8 newMiscSplit);
    event UpdateSwapThreshold(uint16 newThreshold);
    event UpdateTargetLiquidity(uint16 target);

    /////////////////////////////   MODIFIERS  /////////////////////////////////////////

    modifier authorized() {
        _isAuthorized();
        _;
    }

    modifier lockTheSwap() {
        _isSwappingContractModifier = true;
        _;
        _isSwappingContractModifier = false;
    }

    /////////////////////////////   CONSTRUCTOR  /////////////////////////////////////////

    constructor() {
        if (block.chainid == 1) {
            UniSwapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        } else if (block.chainid == 5) {
            UniSwapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        } else revert();
        _uniswapRouter = IUniSwapRouter02(UniSwapRouter);
        _uniswapPairAddress = IUniSwapFactory(_uniswapRouter.factory())
            .createPair(address(this), _uniswapRouter.WETH());
        _addToken(msg.sender, INITIAL_SUPPLY);
        emit Transfer(address(0), msg.sender, INITIAL_SUPPLY);
        _allowances[address(this)][address(_uniswapRouter)] = type(uint256).max;

        //setup ratio divisors based on Team's chosen ratios
        totalTaxRatio =
            _taxRatios.burn +
            _taxRatios.buyback +
            _taxRatios.Team +
            _taxRatios.liquidity +
            _taxRatios.Events +
            _taxRatios.Marketing +
            _taxRatios.rewards;

        totalSwapRatio = totalTaxRatio - _taxRatios.burn;
        distributeRatio = totalSwapRatio - _taxRatios.liquidity;

        //circulating supply begins as initial supply
        _circulatingSupply = INITIAL_SUPPLY;

        //setup _limits
        _limits = MaxLimits({
            maxWallet: (INITIAL_SUPPLY * _limitRatios.wallet) /
                _limitRatios.divisor,
            maxSell: (INITIAL_SUPPLY * _limitRatios.sell) /
                _limitRatios.divisor,
            maxBuy: (INITIAL_SUPPLY * _limitRatios.buy) / _limitRatios.divisor
        });

        _excluded.add(msg.sender);
        _excluded.add(_taxWallet.Marketing);
        _excluded.add(_taxWallet.Team);
        _excluded.add(_taxWallet.Events);
        _excluded.add(address(this));
        _excluded.add(BURN_ADDRESS);
        _excludedFromStaking.add(address(this));
        _excludedFromStaking.add(BURN_ADDRESS);
        _excludedFromStaking.add(address(_uniswapRouter));
        _excludedFromStaking.add(_uniswapPairAddress);

        _approve(address(this), address(_uniswapRouter), type(uint256).max);
    }

    receive() external payable {}

    //allows Team to change token name and symbol.
    function updateTokenDetails(string memory newName, string memory newSymbol)
        external
        authorized
    {
        _name = newName;
        _symbol = newSymbol;
    }

    function decimals() external pure override returns (uint8) {
        return TOKEN_DECIMALS;
    }

    function getOwner() external view override returns (address) {
        return owner();
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function totalSupply() external view override returns (uint256) {
        return _circulatingSupply;
    }

    function _isAuthorized() private view {
        if (!_authorized(msg.sender)) revert Unauthorized();
    }

    function _authorized(address addr) private view returns (bool) {
        return
            addr == owner() ||
            addr == _taxWallet.Marketing ||
            addr == _taxWallet.Team ||
            addr == _taxWallet.Events;
    }

    function allowance(address _owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "Approve from zero");
        require(spender != address(0), "Approve to zero");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "<0 allowance");

        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender] + addedValue
        );
        return true;
    }
    
    // Method to log holders to looping of distribution
    function addAddressToHolderHistoryList(address _account) private {      
        
        if(!addedToTokenHolderHistory[_account]){
            tokenHolderHistory[totalTokenHolderHistory] = _account;
            addedToTokenHolderHistory[_account] = true;
            totalTokenHolderHistory++;
        }
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Transfer > allowance");

        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

    ///// FUNCTIONS CALLABLE BY ANYONE /////

    //Claims reward set by Team
    function ClaimMainReward() external {
        if (mainReward == _uniswapRouter.WETH()) {
            claimETHTo(
                msg.sender,
                msg.sender,
                getStakeBalance(msg.sender, true),
                true
            );
        } else claimToken(msg.sender, mainReward, 0, true);
    }

    //Claims reward chosen by holder. Differentiates between ETH and other ERC20 tokens
    function ClaimMiscReward(address tokenAddress) external {
        if (tokenAddress == _uniswapRouter.WETH()) {
            claimETHTo(
                msg.sender,
                msg.sender,
                getStakeBalance(msg.sender, false),
                false
            );
        } else claimToken(msg.sender, tokenAddress, 0, false);
    }

    //Allows holders to include themselves back into staking if excluded
    //ExcludeFromStaking function should be used for contracts(CEX, pair, address(this), etc.)
    function IncludeMeToStaking() external {
        includeToStaking(msg.sender);
        emit ExcludeFromStaking(msg.sender, false);
    }

    ///// AUTHORIZED FUNCTIONS /////

    //Allows Team to change reward
    function changeMainReward(address newReward) external onlyOwner {
        mainReward = newReward;
        emit ChangeMainReward(newReward);
    }

    //Manually perform a contract swap
    function createLPandETH(uint16 permilleOfUniSwap, bool ignoreLimits)
        external
        onlyOwner
    {
        _swapContractToken(permilleOfUniSwap, ignoreLimits);
    }

    //Toggle blacklist on and off
    function enableBlacklist(bool enabled) external onlyOwner {
        blacklistEnabled = enabled;
        emit EnableBlacklist(enabled);
    }

    //Toggle dynamic features on and off
    function dynamicSettings(
        bool burn,
        bool limits,
        bool liquidity,
        bool sells
    ) external onlyOwner {
        dynamicBurn = burn;
        dynamicLimits = limits;
        dynamicLiqEnabled = liquidity;
        dynamicSellsEnabled = sells;
        emit AdjustedDynamicSettings(burn, limits, liquidity, sells);
    }

    //Mainly used for addresses such as CEX, presale, etc
    function excludeAccountFromFees(address account, bool exclude)
        external
        onlyOwner
    {
        if (exclude == true) _excluded.add(account);
        else _excluded.remove(account);
        emit ExcludedAccountFromFees(account, exclude);
    }

    //Mainly used for addresses such as CEX, presale, etc
    function setStakingExclusionStatus(address addr, bool exclude)
        external
        onlyOwner
    {
        if (exclude) excludeFromStaking(addr);
        else includeToStaking(addr);
        emit ExcludeFromStaking(addr, exclude);
    }

    //Toggle manual swap on and off
    function enableManualSwap(bool enabled) external onlyOwner {
        manualSwap = enabled;
        emit EnableManualSwap(enabled);
    }

    function launch() external onlyOwner {
        if (IERC20(_uniswapPairAddress).totalSupply() == 0)
            revert NeedLiquidity();
        isLaunched = true;
        launchBlock = block.number;
        launchTime = block.timestamp;
    }

    //Toggle whether multiple buys in a block from a single address can be performed
    function sameBlockRevert(bool enabled) external onlyOwner {
        revertSameBlock = enabled;
    }

    function addBlacklist(address addr) external authorized {
        if (block.timestamp > (launchTime + blacklistWindow))
            revert BlacklistTimerExceeded();
        if (isBlacklisted[addr]) revert AlreadyBlacklisted();
        isBlacklisted[addr] = true;
    }

    function removeBlacklist(address addr) external authorized {
        if (!isBlacklisted[addr]) revert AlreadyUnblacklisted();
        isBlacklisted[addr] = false;
    }

    function setTier1(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; ++i) {
            tier2[addresses[i]] = false;
            tier3[addresses[i]] = false;
        }
    }

    function setTier2(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; ++i) {
            tier2[addresses[i]] = true;
            tier3[addresses[i]] = false;
        }
    }

    function setTier3(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; ++i) {
            tier2[addresses[i]] = false;
            tier3[addresses[i]] = true;
        }
    }

    //indepedently set whether wallet is exempt from taxes
    function setTaxExemptionStatus(address account, bool exempt)
        external
        onlyOwner
    {
        taxExempt[account] = exempt;
    }

    //independtly set whether wallet is exempt from limits
    function setLimitExemptionStatus(address account, bool exempt)
        external
        onlyOwner
    {
        limitExempt[account] = exempt;
    }

    function setWhitelistStatus(address[] calldata addresses, bool status)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; ++i) {
            isWhitelisted[addresses[i]] = status;
        }
    }

    //Performs a buyback and automatically burns tokens
    function triggerBuyback(uint256 amount) external authorized {
        buybackToken(amount, address(this));
    }

    //Update limit ratios. ofCurrentSupply = true will set max wallet based on current supply. False will use initial supply
    function updateLimits(
        uint16 newMaxWalletRatio,
        uint16 newMaxSellRatio,
        uint16 newMaxBuyRatio,
        uint16 newDivisor,
        bool ofCurrentSupply
    ) external onlyOwner {
        uint256 supply = INITIAL_SUPPLY;
        if (ofCurrentSupply) supply = _circulatingSupply;
        uint256 minLimit = supply / 1000;
        uint256 newMaxWallet = (supply * newMaxWalletRatio) / newDivisor;
        uint256 newMaxSell = (supply * newMaxSellRatio) / newDivisor;
        uint256 newMaxBuy = (supply * newMaxBuyRatio) / newDivisor;

        //Team can never set sells below 0.1% of circulating/initial supply
        if (newMaxWallet < minLimit || newMaxSell < minLimit)
            revert InvalidInput();

        _limits = MaxLimits(newMaxWallet, newMaxSell, newMaxBuy);

        _limitRatios = LimitRatios(
            newMaxWalletRatio,
            newMaxSellRatio,
            newMaxBuyRatio,
            newDivisor
        );
    }

    //update launch tax ratios
    function updateLaunchTransferTax(
        uint8 newLaunchTransferTax
    ) external onlyOwner {
        require(launchTransferTax > 0, "Launch Transfer Tax has been removed and cannot be re-enabled");
        launchTransferTax = newLaunchTransferTax;
    }

    //update tax ratios
    function updateRatios(
        uint8 newBurn,
        uint8 newBuyback,
        uint8 newTeam,
        uint8 newLiquidity,
        uint8 newEvents,
        uint8 newMarketing,
        uint8 newRewards
    ) external onlyOwner {
        _taxRatios = TaxRatios(
            newBurn,
            newBuyback,
            newTeam,
            newLiquidity,
            newEvents,
            newMarketing,
            newRewards
        );

        totalTaxRatio =
            newBurn +
            newBuyback +
            newTeam +
            newLiquidity +
            newEvents +
            newMarketing +
            newRewards;
        totalSwapRatio = totalTaxRatio - newBurn;
        distributeRatio = totalSwapRatio - newLiquidity;

        emit RatiosChanged(
            newBurn,
            newBuyback,
            newTeam,
            newLiquidity,
            newEvents,
            newMarketing,
            newRewards
        );
    }

    //update allocation of mainReward and miscReward
    function updateRewardSplit(uint8 mainSplit, uint8 miscSplit)
        external
        onlyOwner
    {
        uint8 totalSplit = mainSplit + miscSplit;
        if (totalSplit != 100) revert InvalidInput();
        mainRewardSplit = mainSplit;
        miscRewardSplit = miscSplit;
        emit UpdateRewardSplit(mainSplit, miscSplit);
    }

    //update threshold that triggers contract swaps
    function updateSwapThreshold(uint16 threshold) external onlyOwner {
        if (threshold < 0 || threshold > 50) revert InvalidInput();
        swapThreshold = threshold;
        emit UpdateSwapThreshold(threshold);
    }

    //targetLiquidity is out of 100
    function updateTargetLiquidity(uint16 target) external onlyOwner {
        if (target > 100) revert InvalidInput();
        targetLiquidityRatio = target;
        emit UpdateTargetLiquidity(target);
    }

    function updateBuyTaxes(
        uint8 first,
        uint8 second,
        uint8 third
    ) external onlyOwner {
        if (first > MAX_TAX || second > MAX_TAX || third > MAX_TAX)
            revert MaxTaxExceeded(MAX_TAX);
        _buyTaxes = TierTaxes(first, second, third);
    }

    function updateSellTaxes(
        uint8 first,
        uint8 second,
        uint8 third
    ) external onlyOwner {
        if (first > MAX_TAX || second > MAX_TAX || third > MAX_TAX)
            revert MaxTaxExceeded(MAX_TAX);
        _sellTaxes = TierTaxes(first, second, third);
    }

    function withdrawTeam() external authorized {
        uint256 remaining = address(this).balance -
            TeamBalance -
            EventsBalance -
            MarketingBalance -
            buybackBalance -
            getTotalUnclaimed();
        bool lostBalance = remaining > 0;
        uint256 amount = lostBalance ? TeamBalance + remaining : TeamBalance;
        TeamBalance = 0;
        _sendETH(_taxWallet.Team, amount);
    }

    function withdrawEvents() external authorized {
        uint256 amount = EventsBalance;
        EventsBalance = 0;
        _sendETH(_taxWallet.Events, amount);
    }

    function withdrawMarketing() external authorized {
        uint256 amount = MarketingBalance;
        MarketingBalance = 0;
        _sendETH(_taxWallet.Marketing, amount);
    }

    //liquidity can only be extended
    function lockLiquidityTokens(uint256 lockTimeInSeconds)
        external
        authorized
    {
        setUnlockTime(lockTimeInSeconds + block.timestamp);
        emit ExtendLiquidityLock(lockTimeInSeconds);
    }

    //recovers stuck ETH to make sure it isnt burnt/lost
    //only callablewhen liquidity is unlocked
    function recoverETH() external authorized {
        if (block.timestamp < _liquidityUnlockTime)
            revert LiquidityLocked(_liquidityUnlockTime - block.timestamp);
        _liquidityUnlockTime = block.timestamp;
        _sendETH(msg.sender, address(this).balance);
    }

    //Can only be used to recover miscellaneous tokens accidentally sent to contract
    //Can't pull liquidity or native token using this function
    function recoverMiscToken(address tokenAddress) external authorized {
        if (
            tokenAddress == _uniswapPairAddress || tokenAddress == address(this)
        ) revert InvalidInput();
        IERC20 token = IERC20(tokenAddress);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    //Impossible to release LP unless LP lock time is zero
    function releaseLP() external authorized {
        if (block.timestamp < _liquidityUnlockTime)
            revert LiquidityLocked(_liquidityUnlockTime - block.timestamp);
        IUniSwapERC20 liquidityToken = IUniSwapERC20(_uniswapPairAddress);
        uint256 amount = liquidityToken.balanceOf(address(this));
        liquidityToken.transfer(msg.sender, amount);
    }

    //Impossible to remove LP unless lock time is zero
    function removeLP() external authorized {
        if (block.timestamp < _liquidityUnlockTime)
            revert LiquidityLocked(_liquidityUnlockTime - block.timestamp);
        _liquidityUnlockTime = block.timestamp;
        IUniSwapERC20 liquidityToken = IUniSwapERC20(_uniswapPairAddress);
        uint256 amount = liquidityToken.balanceOf(address(this));
        liquidityToken.approve(address(_uniswapRouter), amount);
        _uniswapRouter.removeLiquidityETHSupportingFeeOnTransferTokens(
            address(this),
            amount,
            0,
            0,
            address(this),
            block.timestamp
        );
        _sendETH(msg.sender, address(this).balance);
    }

    function setTeamWallet(address payable addr) external authorized {
        address prevTeam = _taxWallet.Team;
        _excluded.remove(prevTeam);
        _taxWallet.Team = addr;
        _excluded.add(_taxWallet.Team);
        emit UpdateTeamWallet(addr);
    }

    function setEventsWallet(address payable addr) external authorized {
        address prevEvents = _taxWallet.Events;
        _excluded.remove(prevEvents);
        _taxWallet.Events = addr;
        _excluded.add(_taxWallet.Events);
        emit UpdateEventsWallet(addr);
    }

    function setMarketingWallet(address payable addr) external authorized {
        address prevMarketing = _taxWallet.Marketing;
        _excluded.remove(prevMarketing);
        _taxWallet.Marketing = addr;
        _excluded.add(_taxWallet.Marketing);
        emit UpdateMarketingWallet(addr);
    }

    ////// VIEW FUNCTIONS /////

    function getBlacklistInfo()
        external
        view
        returns (
            uint256 _launchBlock,
            uint8 _blacklistBlocks,
            uint8 _snipersRekt,
            bool _blacklistEnabled,
            bool _revertSameBlock
        )
    {
        return (
            launchBlock,
            BLACKLIST_BLOCKS,
            snipersRekt,
            blacklistEnabled,
            revertSameBlock
        );
    }

    function getDynamicInfo()
        external
        view
        returns (
            bool _dynamicBurn,
            bool _dynamicLimits,
            bool _dynamicLiquidity,
            bool _dynamicSells,
            uint16 _targetLiquidity
        )
    {
        return (
            dynamicBurn,
            dynamicLimits,
            dynamicLiqEnabled,
            dynamicSellsEnabled,
            targetLiquidityRatio
        );
    }

    function getLiquidityRatio() public view returns (uint256) {
        uint256 ratio = (100 * _balances[_uniswapPairAddress]) /
            _circulatingSupply;
        return ratio;
    }

    function getLiquidityUnlockInSeconds() external view returns (uint256) {
        if (block.timestamp < _liquidityUnlockTime) {
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

    function getSupplyInfo()
        external
        view
        returns (
            uint256 initialSupply,
            uint256 circulatingSupply,
            uint256 burntTokens
        )
    {
        uint256 tokensBurnt = INITIAL_SUPPLY - _circulatingSupply;
        return (INITIAL_SUPPLY, _circulatingSupply, tokensBurnt);
    }

    function getTotalUnclaimed() public view returns (uint256) {
        uint256 amount = totalRewards - totalPayouts;
        return amount;
    }

    function getWithdrawBalances()
        external
        view
        returns (
            uint256 buyback,
            uint256 Team,
            uint256 Events,
            uint256 Marketing
        )
    {
        return (buybackBalance, TeamBalance, EventsBalance, MarketingBalance);
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
    uint256 private constant DISTRIBUTION_MULTI = 2**64;
    uint256 private _totalShares = INITIAL_SUPPLY;
    uint256 private buybackBalance;
    uint256 private TeamBalance;
    uint256 private EventsBalance;
    uint256 private MarketingBalance;
    uint256 private mainRewardShare;
    uint256 private miscRewardShare;
    uint256 public totalPayouts;
    uint256 public totalRewards;
    bool private _isSwappingContractModifier;
    bool private _isWithdrawing;
    bool private _isBurning;

    function _addLiquidity(uint256 tokenamount, uint256 ETHAmount) private {
        _approve(address(this), address(_uniswapRouter), tokenamount);
        _uniswapRouter.addLiquidityETH{value: ETHAmount}(
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

        // add history to holder list
        addAddressToHolderHistoryList(addr);
    }

    function _calculateTierTax(address addr, bool isBuy)
        private
        view
        returns (uint8)
    {
        if (!tier2[addr] && !tier3[addr]) {
            return isBuy ? _buyTaxes.first : _sellTaxes.first;
        } else if (tier3[addr]) {
            return isBuy ? _buyTaxes.third : _sellTaxes.third;
        } else {
            return isBuy ? _buyTaxes.second : _sellTaxes.second;
        }
    }

    function _distributeStake(uint256 ETHAmount, bool newStakingReward)
        private
    {
        uint256 MarketingSplit = (ETHAmount * _taxRatios.Marketing) /
            distributeRatio;
        uint256 TeamSplit = (ETHAmount * _taxRatios.Team) / distributeRatio;
        uint256 buybackSplit = (ETHAmount * _taxRatios.buyback) /
            distributeRatio;
        uint256 stakingSplit = (ETHAmount * _taxRatios.rewards) /
            distributeRatio;
        uint256 EventsSplit = (ETHAmount * _taxRatios.Events) / distributeRatio;
        uint256 mainAmount = (stakingSplit * mainRewardSplit) / 100;
        uint256 miscAmount = (stakingSplit * miscRewardSplit) / 100;
        MarketingBalance += MarketingSplit;
        TeamBalance += TeamSplit;
        buybackBalance += buybackSplit;
        EventsBalance += EventsSplit;
        if (stakingSplit > 0) {
            if (newStakingReward) totalRewards += stakingSplit;
            uint256 totalShares = getTotalShares();
            if (totalShares == 0) MarketingBalance += stakingSplit;
            else {
                mainRewardShare += ((mainAmount * DISTRIBUTION_MULTI) /
                    totalShares);
                miscRewardShare += ((miscAmount * DISTRIBUTION_MULTI) /
                    totalShares);
            }
        }
    }

    function _feelessTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        if (_balances[sender] < amount) revert InsufficientBalance();
        _removeToken(sender, amount);
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
        (bool sent, ) = account.call{value: (amount)}("");
        require(sent, "withdraw failed");
    }

    function _swapContractToken(uint16 permilleOfUniSwap, bool ignoreLimits)
        private
        lockTheSwap
    {
        require(permilleOfUniSwap <= 500);
        if (totalSwapRatio == 0) return;
        uint256 contractBalance = _balances[address(this)];

        uint256 tokenToSwap = (_balances[_uniswapPairAddress] *
            permilleOfUniSwap) / 1000;
        if (tokenToSwap > _limits.maxSell && !ignoreLimits)
            tokenToSwap = _limits.maxSell;

        bool notEnoughToken = contractBalance < tokenToSwap;
        if (notEnoughToken) {
            if (ignoreLimits) tokenToSwap = contractBalance;
            else return;
        }
        if (_allowances[address(this)][address(_uniswapRouter)] < tokenToSwap)
            _approve(address(this), address(_uniswapRouter), type(uint256).max);

        uint256 dynamicLiqRatio;
        if (dynamicLiqEnabled && getLiquidityRatio() >= targetLiquidityRatio)
            dynamicLiqRatio = 0;
        else dynamicLiqRatio = _taxRatios.liquidity;

        uint256 tokenForLiquidity = (tokenToSwap * dynamicLiqRatio) /
            totalSwapRatio;
        uint256 remainingToken = tokenToSwap - tokenForLiquidity;
        uint256 liqToken = tokenForLiquidity / 2;
        uint256 liqETHToken = tokenForLiquidity - liqToken;
        uint256 swapToken = liqETHToken + remainingToken;
        uint256 initialETHBalance = address(this).balance;
        _swapTokenForETH(swapToken);
        uint256 newETH = (address(this).balance - initialETHBalance);
        uint256 liqETH = (newETH * liqETHToken) / swapToken;
        if (liqToken > 0) _addLiquidity(liqToken, liqETH);
        uint256 distributeETH = (address(this).balance -
            initialETHBalance -liqETH
            );
        _distributeStake(distributeETH, true);
    }

    function _swapTokenForETH(uint256 amount) private {
        _approve(address(this), address(_uniswapRouter), amount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapRouter.WETH();
        _uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _taxedTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool isBuy,
        bool isSell
    ) private {
        if (_balances[sender] < amount) revert InsufficientBalance();

        uint8 tax;
        bool extraSellTax = false;        
        uint256 launchTransferTaxAmount;

        if (isSell) {
            if (blacklistEnabled) {
                if (isBlacklisted[sender]) revert UserBlacklisted();
            }

            if (amount > _limits.maxSell && !limitExempt[sender])
                revert MaxSellExceeded(_limits.maxSell);

            tax = _calculateTierTax(sender, false);
            if (dynamicSellsEnabled) extraSellTax = true;
        } else if (isBuy) {
            if (!isLaunched && !isWhitelisted[recipient]) {
                isBlacklisted[recipient] = true;
            }

            if (launchBlock > 0) {
                if (block.number - launchBlock < BLACKLIST_BLOCKS) {
                    isBlacklisted[recipient] = true;
                    ++snipersRekt;
                }
            }

            if (revertSameBlock) {
                require(tradeBlock[recipient] != block.number);
                tradeBlock[recipient] = block.number;
            }

            if (
                (_balances[recipient] + amount) > _limits.maxWallet &&
                !limitExempt[recipient]
            ) revert MaxBalanceExceeded(_limits.maxWallet);
            if (amount > _limits.maxBuy && !limitExempt[recipient])
                revert MaxBuyExceeded(_limits.maxBuy);
            tax = _calculateTierTax(recipient, true);
        } else {

            if (blacklistEnabled) {
                if (isBlacklisted[sender]) revert UserBlacklisted();
            }

            if (amount <= 10**(TOKEN_DECIMALS)) {
                //transfer less than 1 token to ClaimETH
                if (mainReward == _uniswapRouter.WETH())
                    claimETHTo(
                        msg.sender,
                        msg.sender,
                        getStakeBalance(msg.sender, true),
                        true
                    );
                else claimToken(msg.sender, mainReward, 0, true);
                return;
            }

            if (
                (_balances[recipient] + amount) > _limits.maxWallet &&
                !limitExempt[recipient]
            ) revert MaxBalanceExceeded(_limits.maxWallet);

            // on transfer during launch apply tax
            if (launchTransferTax > 0) {
                launchTransferTaxAmount = (amount * launchTransferTax) / 100;
            }
            
        }

        if (
            (sender != _uniswapPairAddress) &&
            (!manualSwap) &&
            (!_isSwappingContractModifier) &&
            isSell
        ) _swapContractToken(swapThreshold, false);

        if (taxExempt[sender] || taxExempt[recipient]) {
            tax = 0;
            extraSellTax = false;
        }

        uint256 taxedAmount;
        uint256 tokensToBeBurnt;
        uint256 contractToken;

        if (tax > 0) {
            taxedAmount = (amount * tax) / 100;
            tokensToBeBurnt = (taxedAmount * _taxRatios.burn) / totalTaxRatio;
            contractToken = taxedAmount - tokensToBeBurnt;
        }

        if (extraSellTax) {
            uint256 extraTax = dynamicSellTax(amount);
            taxedAmount += extraTax;
            if (dynamicBurn) tokensToBeBurnt += extraTax;
            else contractToken += extraTax;
        }

        // check for launch tax amount
        if(launchTransferTaxAmount > 0){
            taxedAmount += launchTransferTaxAmount;
        }

        uint256 receiveAmount = amount - taxedAmount;
        _removeToken(sender, amount);
        _addToken(address(this), contractToken);
        _circulatingSupply -= tokensToBeBurnt;
        _addToken(recipient, receiveAmount);
        emit Transfer(sender, recipient, receiveAmount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "Transfer from zero");
        require(recipient != address(0), "Transfer to zero");

        if (recipient == BURN_ADDRESS) {
            burnTransfer(sender, amount);
            return;
        }

        if (dynamicLimits) getNewLimits();

        bool isExcluded = (_excluded.contains(sender) ||
            _excluded.contains(recipient));

        bool isContractTransfer = (sender == address(this) ||
            recipient == address(this));
        address uniswapRouter = address(_uniswapRouter);
        bool isLiquidityTransfer = ((sender == _uniswapPairAddress &&
            recipient == uniswapRouter) ||
            (recipient == _uniswapPairAddress && sender == uniswapRouter));

        bool isSell = recipient == _uniswapPairAddress ||
            recipient == uniswapRouter;
        bool isBuy = sender == _uniswapPairAddress || sender == uniswapRouter;

        if (isContractTransfer || isLiquidityTransfer || isExcluded) {
            _feelessTransfer(sender, recipient, amount);
        } else {
            _taxedTransfer(sender, recipient, amount, isBuy, isSell);
        }
    }

    function burnTransfer(address account, uint256 amount) private {
        require(amount <= _balances[account]);
        require(!_isBurning);
        _isBurning = true;
        _removeToken(account, amount);
        _circulatingSupply -= amount;
        emit Transfer(account, BURN_ADDRESS, amount);
        _isBurning = false;
    }

    function buybackToken(uint256 amount, address token) private {
        if (amount > buybackBalance) revert InsufficientBalance();
        buybackBalance -= amount;

        address[] memory path = new address[](2);
        path[0] = _uniswapRouter.WETH();
        path[1] = token;

        _uniswapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amount
        }(0, path, BURN_ADDRESS, block.timestamp);
    }

    function claimToken(
        address addr,
        address token,
        uint256 payableAmount,
        bool main
    ) private {
        require(!_isWithdrawing);
        _isWithdrawing = true;
        uint256 amount;
        if (_excludedFromStaking.contains(addr)) {
            if (main) {
                amount = toERCaidMain[addr];
                toERCaidMain[addr] = 0;
            } else {
                amount = toERCaidMisc[addr];
                toERCaidMisc[addr] = 0;
            }
        } else {
            uint256 newAmount = newStakeOf(addr, main);
            if (main) {
                alreadyPaidMain[addr] = mainRewardShare * _balances[addr];
                amount = toERCaidMain[addr] + newAmount;
                toERCaidMain[addr] = 0;
            } else {
                alreadyPaidMisc[addr] = miscRewardShare * _balances[addr];
                amount = toERCaidMisc[addr] + newAmount;
                toERCaidMisc[addr] = 0;
            }
        }

        if (amount == 0 && payableAmount == 0) {
            _isWithdrawing = false;
            return;
        }

        totalPayouts += amount;
        accountTotalClaimed[addr] += amount;
        amount += payableAmount;
        address[] memory path = new address[](2);
        path[0] = _uniswapRouter.WETH();
        path[1] = token;

        _uniswapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amount
        }(0, path, addr, block.timestamp);

        emit ClaimToken(amount, token, addr);
        _isWithdrawing = false;
    }

    function claimETHTo(
        address from,
        address to,
        uint256 amountWei,
        bool main
    ) private {
        require(!_isWithdrawing);
        {
            require(amountWei != 0);
            _isWithdrawing = true;
            subtractStake(from, amountWei, main);
            totalPayouts += amountWei;
            accountTotalClaimed[to] += amountWei;
            _sendETH(to, amountWei);
        }
        _isWithdrawing = false;
        emit ClaimETH(from, to, amountWei);
    }

    function dynamicSellTax(uint256 amount) private view returns (uint256) {
        uint256 value = _balances[_uniswapPairAddress];
        uint256 vMin = value / 100;
        uint256 vMax = value / 10;
        if (amount <= vMin) return amount = 0;

        if (amount > vMax) return (amount * 10) / 100;

        return (((amount - vMin) * 10 * amount) / (vMax - vMin)) / 100;
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

    function getNewLimits() private {
        _limits.maxBuy =
            (_circulatingSupply * _limitRatios.buy) /
            _limitRatios.divisor;
        _limits.maxSell =
            (_circulatingSupply * _limitRatios.sell) /
            _limitRatios.divisor;
        _limits.maxWallet =
            (_circulatingSupply * _limitRatios.wallet) /
            _limitRatios.divisor;
    }

    function subtractStake(
        address addr,
        uint256 amount,
        bool main
    ) private {
        if (amount == 0) return;
        if (amount > getStakeBalance(addr, main)) revert InsufficientBalance();

        if (_excludedFromStaking.contains(addr)) {
            if (main) toERCaidMain[addr] -= amount;
            else toERCaidMisc[addr] -= amount;
        } else {
            uint256 newAmount = newStakeOf(addr, main);
            if (main) {
                alreadyPaidMain[addr] = mainRewardShare * _balances[addr];
                toERCaidMain[addr] += newAmount;
                toERCaidMain[addr] -= amount;
            } else {
                alreadyPaidMisc[addr] = miscRewardShare * _balances[addr];
                toERCaidMisc[addr] += newAmount;
                toERCaidMisc[addr] -= amount;
            }
        }
    }

    function getStakeBalance(address addr, bool main)
        private
        view
        returns (uint256)
    {
        if (main) {
            if (_excludedFromStaking.contains(addr)) return toERCaidMain[addr];
            return newStakeOf(addr, true) + toERCaidMain[addr];
        } else {
            if (_excludedFromStaking.contains(addr)) return toERCaidMisc[addr];
            return newStakeOf(addr, false) + toERCaidMisc[addr];
        }
    }

    function getTotalShares() private view returns (uint256) {
        return _totalShares - INITIAL_SUPPLY;
    }

    function setUnlockTime(uint256 newUnlockTime) private {
        // require new unlock time to be longer than old one
        require(newUnlockTime > _liquidityUnlockTime);
        _liquidityUnlockTime = newUnlockTime;
    }

    function newStakeOf(address staker, bool main)
        private
        view
        returns (uint256)
    {
        if (main) {
            uint256 fullPayout = mainRewardShare * _balances[staker];
            if (fullPayout < alreadyPaidMain[staker]) return 0;
            return (fullPayout - alreadyPaidMain[staker]) / DISTRIBUTION_MULTI;
        } else {
            uint256 fullPayout = miscRewardShare * _balances[staker];
            if (fullPayout < alreadyPaidMisc[staker]) return 0;
            return (fullPayout - alreadyPaidMisc[staker]) / DISTRIBUTION_MULTI;
        }
    }
}