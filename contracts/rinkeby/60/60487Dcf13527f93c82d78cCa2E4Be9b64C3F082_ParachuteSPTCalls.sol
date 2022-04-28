// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './interfaces/Decimals.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './interfaces/IWETH.sol';
import './interfaces/ISPT.sol';
import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IUniswapV2Pair.sol';
import './interfaces/UniswapV2Library.sol';


contract ParachuteSPTCalls is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    address public asset;
    address public pymtCurrency;
    address public spt; //special purpose token address
    uint public assetDecimals;
    address public paymentPair;
    address public assetPair;
    address payable public weth;
    uint public c = 1;
    address public uniFactory;
    bool public cashCloseOn;
    

    constructor(address _asset, address _pymtCurrency, address _spt, address payable _weth, address _uniFactory) {
        asset = _asset;
        pymtCurrency = _pymtCurrency;
        spt = _spt;
        weth = _weth;
        uniFactory = _uniFactory;
        assetDecimals = Decimals(_asset).decimals();
        paymentPair = IUniswapV2Factory(uniFactory).getPair(weth, pymtCurrency);
        assetPair = IUniswapV2Factory(uniFactory).getPair(weth, asset);
        if (paymentPair != address(0x0) && assetPair != address(0x0)){
            //if neither of the currencies is weth then we can test if both asset and payment have a pair with weth
            cashCloseOn = true;
        } else {
            cashCloseOn = false;
        }
    }
    
    struct Call {
        address payable short;
        uint assetAmt;
        uint strike;
        uint totalPurch;
        uint price;
        uint expiry;
        bool open;
        bool tradeable;
        address payable long;
        bool exercised;
    }

    
    mapping (uint256 => Call) public calls;
    /// @dev enumerations
    uint256[] public newCalls;
    mapping(uint256 => uint256) public newCallsIndex;
    // uint256[] public openCalls;
    // mapping(uint256 => uint256) public openCallsIndex;

    function getAllNewCalls() public view returns (Call[] memory) {
        Call[] memory _calls = new Call[](newCalls.length);
        for (uint256 i = 0; i < newCalls.length; i++) {
            //returns the callId at the index
            uint256 callId = newCalls[i];
            //add to array
            //Call memory call = calls[callId];
            _calls[i] = calls[callId];
        }
        return _calls;
    }

    function getNewCallsByDetails(uint256 _assetAmount, uint256 _strike, uint256 _price, uint256 _expiry) public view returns (uint256[] memory) {
        uint256[] memory _calls = new uint256[](newCalls.length);
        for (uint256 i = 0; i < newCalls.length; i++) {
            //returns the callId on the given index
            uint256 callId = newCalls[i];
            Call memory call = calls[callId];
            //check the conditions if met
            if (call.assetAmt == _assetAmount && call.strike == _strike && call.price == _price && call.expiry == _expiry) {
                _calls[i] = callId;
            } else {
                _calls[i] = 0;
            }
        }
        return _calls;
    }

    /// @dev balance function for long open calls
    mapping(address => uint256) private balances;
    /// @dev mappings for the long positions of the calls
    mapping(address => mapping(uint256 => uint256)) private ownedCalls;
    mapping(uint256 => uint256) private ownedCallsIndex;

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function callofOwnerByIndex(address _owner, uint callIndex) public view returns (uint256) {
        return ownedCalls[_owner][callIndex];
    }

    function getAllOwnersCalls(address _owner) public view returns (Call[] memory) {
        require(balanceOf(_owner) > 0, "no owned calls");
        Call[] memory _calls = new Call[](balanceOf(_owner));
        for (uint256 i = 0; i < balanceOf(_owner); i++) {
            uint256 callId = callofOwnerByIndex(_owner, i);
            _calls[i] = calls[callId];
        }
        return _calls;
    }
    
    function addToNewCallsArray(uint256 _c) internal {
        newCalls.push(_c);
        newCallsIndex[_c] = newCalls.length - 1;
    }

    function removeFromNewCallsArray(uint256 _c) internal {
        uint256 lastCallIndex = newCalls.length - 1;
        uint256 callIndex = newCallsIndex[_c];
        uint256 lastCallId = newCalls[lastCallIndex];
        /// @dev updates the lastcall into the slot of the to be deleted call
        newCalls[callIndex] = lastCallId;
        newCallsIndex[lastCallId] = callIndex;
        newCalls[lastCallIndex] = _c;
        /// @dev now we have overwritten the call to be removed, so we can simply delete and pop the duplicate entry 
        /// in the last position of the array
        delete newCallsIndex[_c];
        newCalls.pop();
    }


    function addCallToOwnerIndex(address _to, uint256 _c) internal {
        uint256 bal = balances[_to];
        /// @dev puts the newest call at the last index mapping
        ownedCalls[_to][bal] = _c;
        ownedCallsIndex[_c] = bal;
        balances[_to]++; // add one more to the balance
    }

    function removeCallOwner(address _from, uint256 _c) internal {
        balances[_from]--;
        uint256 lastCallIndex = balances[_from];
        uint256 callIndex = ownedCallsIndex[_c];
        if (lastCallIndex != callIndex) {
            uint256 lastCallId = ownedCalls[_from][lastCallIndex];
            //update the mapping of the last one to the one to be deleted;
            ownedCalls[_from][_c] = lastCallId;
            ownedCallsIndex[lastCallId] = callIndex;
        }
        delete ownedCallsIndex[_c];
        delete ownedCalls[_from][lastCallIndex];
    }

    receive() external payable {    
    }

    function depositPymt(address _token, address _sender, uint256 _amt) internal {
        SafeERC20.safeTransferFrom(IERC20(_token), _sender, address(this), _amt);
    }

    function withdrawPymt(address _token, address payable to, uint256 _amt) internal {
        SafeERC20.safeTransfer(IERC20(_token), to, _amt);
    }

    function transferPymt(address _token, address from, address payable to, uint256 _amt) internal {
        SafeERC20.safeTransferFrom(IERC20(_token), from, to, _amt);         
    
    }

    //function to write a new call
    function newAsk(uint _assetAmt, uint _strike, uint _price, uint _expiry) public onlyOwner {
        uint _totalPurch = (_assetAmt * _strike) / (10 ** assetDecimals);
        require(_totalPurch > 0, "totalPurchase error: too small amount");
        uint balCheck = IERC20(asset).balanceOf(msg.sender);
        require(balCheck >= _assetAmt, "not enough to sell this call option");
        depositPymt(asset, msg.sender, _assetAmt);
        addToNewCallsArray(c);
        calls[c++] = Call(payable(msg.sender), _assetAmt, _strike, _totalPurch, _price, _expiry, false, true, payable(msg.sender), false);
        emit NewAsk(c -1, _assetAmt, _strike, _price, _expiry);
    }

    function bulkNewAsk(uint[] memory _assetAmt, uint[] memory _strike, uint[] memory _price, uint[] memory _expiry) public onlyOwner {
        require(_assetAmt.length == _strike.length && _strike.length == _price.length &&  _strike.length== _expiry.length);
        uint totalAmt;
        for (uint i = 0; i < _assetAmt.length; i++) {
            totalAmt += _assetAmt[i];
            uint _totalPurch = (_assetAmt[i] * _strike[i]) / (10 ** assetDecimals);
            addToNewCallsArray(c);
            calls[c++] = Call(payable(msg.sender), _assetAmt[i], _strike[i], _totalPurch, _price[i], _expiry[i], false, true, payable(msg.sender), false);
            emit NewAsk(c -1, _assetAmt[i], _strike[i], _price[i], _expiry[i]);
        }
        /// @dev bulk deposit the total amount
        depositPymt(asset, msg.sender, totalAmt);
    }

    function cancelNewAsk(uint _c) public nonReentrant onlyOwner {
        Call storage call = calls[_c];
        require(msg.sender == call.short && msg.sender == call.long, "only short can change an ask");
        require(!call.open, "call already open");
        require(!call.exercised, "call already exercised");
        call.tradeable = false;
        call.exercised = true;
        withdrawPymt(asset, call.short, call.assetAmt);
        /// @dev remove from the newCalls array
        removeFromNewCallsArray(_c);
        emit OptionCancelled(_c);
    }

    //function to purchase a new call that hasn't changed hands yet
    function buyNewOption(uint _c) public {
        Call storage call = calls[_c];
        require(msg.sender != call.short, "this is your lost chicken");
        require(call.short != address(0x0) && call.short == call.long, "not your chicken");
        require(call.expiry > block.timestamp, "This call is already expired");
        require(!call.exercised, "This has already been exercised");
        require(call.tradeable, "This isnt tradeable yet");
        require(!call.open, "This call is already open");
        uint balCheck = IERC20(spt).balanceOf(msg.sender); //pulls SPT instead of payment currency
        require(balCheck >= call.price, "not enough to buy this call option");
        ISPT(spt).burn(msg.sender, call.price); //burns the tokens  
        call.open = true;
        call.long = payable(msg.sender);
        call.tradeable = false;
        removeFromNewCallsArray(_c);
        //addToOpenCallsArray(_c);
        addCallToOwnerIndex(msg.sender, _c);
        emit NewOptionBought(_c);
    }

    function exercise(uint _c) public nonReentrant {
        Call storage call = calls[_c];
        require(call.open, "This isnt open");
        require(call.expiry >= block.timestamp, "This call is already expired");
        require(!call.exercised, "This has already been exercised!");
        require(msg.sender == call.long, "You dont own this call");
        uint balCheck = IERC20(pymtCurrency).balanceOf(msg.sender);
        require(balCheck >= call.totalPurch, "not enough to exercise this call option");
        call.exercised = true;
        call.open = false;
        call.tradeable = false;
        transferPymt(pymtCurrency, msg.sender, call.short, call.totalPurch);   
        withdrawPymt(asset, call.long, call.assetAmt);
        //removeFromOpenCallsArray(_c);
        removeCallOwner(msg.sender, _c);
        emit OptionExercised(_c, false);
    }

    //this is the exercise alternative for ppl who want to receive payment currency instead of the underlying asset
    function cashClose(uint _c, bool cashBack) public nonReentrant {
        require(cashCloseOn, "c: this pair cannot be cash closed");
        Call storage call = calls[_c];
        require(call.open, "c: This isnt open");
        require(call.expiry >= block.timestamp, "c: This call is already expired");
        require(!call.exercised, "c: This has already been exercised!");
        require(msg.sender == call.long, "c: You dont own this call");
        (uint assetIn,) = getTo(call.totalPurch);
        require(assetIn < (call.assetAmt), "c: Underlying is not in the money");
        call.exercised = true;
        call.open = false;
        call.tradeable = false;
        //swap(asset, call.totalPurch, assetIn, call.short);
        swapTo(call.totalPurch, call.short);     
        call.assetAmt -= assetIn;
        if (cashBack) {
            swapFrom(call.assetAmt, call.long);
        } else {
            withdrawPymt(asset, call.long, call.assetAmt);
        }
        //removeFromOpenCallsArray(_c);
        removeCallOwner(msg.sender, _c);
        emit OptionExercised(_c, true);
    }

    function returnExpired(uint _c) public nonReentrant onlyOwner {
        Call storage call = calls[_c];
        require(!call.exercised, "This has been exercised");
        require(call.expiry < block.timestamp, "Not expired yet"); 
        require(msg.sender == call.short, "You cant do that");
        call.tradeable = false;
        call.open = false;
        call.exercised = true;
        withdrawPymt(asset, call.short, call.assetAmt);
        //removeFromOpenCallsArray(_c);
        removeCallOwner(call.long, _c);
        emit OptionReturned(_c);
    }


    //************SWAP SPECIFIC FUNCTIONS USED FOR THE CASH CLOSE METHODS***********************/

    //primary function to swap asset into pymtCurrency to payoff the short
    function swapTo(uint amountOut, address to) internal {
        (uint tokenIn, uint wethIn) = getTo(amountOut);
        swap(assetPair, asset, wethIn, tokenIn, address(this)); //sends asset token into the pair, and delivers weth to us
        swap(paymentPair, weth, amountOut, wethIn, to); //swaps to send the just received wethIn and finally gets the USD Out
    }

    //secondary function to convert profit from remaining asset into pymtCurrency
    function swapFrom(uint amountIn, address to) internal {
        (uint cashOut, uint wethOut) = getFrom(amountIn);
        swap(assetPair, asset, wethOut, amountIn, address(this)); //send it to this address
        swap(paymentPair, weth, cashOut, wethOut, to); 
    }


    //function to swap from this contract to uniswap pool
    function swap(address pair, address token, uint out, uint _in, address to) internal {
        SafeERC20.safeTransfer(IERC20(token), pair, _in); //sends the asset amount in to the swap
        address token0 = IUniswapV2Pair(pair).token0();
        if (token == token0) {
            IUniswapV2Pair(pair).swap(0, out, to, new bytes(0));
        } else {
            IUniswapV2Pair(pair).swap(out, 0, to, new bytes(0));
        }
        
    }

    //primary function to get the amounts in required to pay off the short position total purchase
    //amount out is the total purchase necessary
    function getTo(uint amountOut) public view returns (uint amountIn, uint wethIn) {
        wethIn = estIn(amountOut, paymentPair, pymtCurrency);       
        amountIn = estIn(wethIn, assetPair, weth);

    }

    //secondary function to pay off the remaining profit to the long position
    function getFrom(uint amountIn) public view returns (uint cashOut, uint wethOut) {
        wethOut = estCashOut(amountIn, assetPair, weth);
        cashOut = estCashOut(wethOut, paymentPair, pymtCurrency);
    }

    

    function estCashOut(uint amountIn, address pair, address token) public view returns (uint amountOut) {
        (uint resA, uint resB,) = IUniswapV2Pair(pair).getReserves();
        address token1 = IUniswapV2Pair(pair).token1();
        amountOut = (token1 == token) ? UniswapV2Library.getAmountOut(amountIn, resA, resB) : UniswapV2Library.getAmountOut(amountIn, resB, resA);
    }

    function estIn(uint amountOut, address pair, address token) public view returns (uint amountIn) {
        (uint resA, uint resB,) = IUniswapV2Pair(pair).getReserves();
        address token1 = IUniswapV2Pair(pair).token1();
        amountIn = (token1 == token) ? UniswapV2Library.getAmountIn(amountOut, resA, resB) : UniswapV2Library.getAmountIn(amountOut, resB, resA);
    }



    event NewAsk(uint _i, uint _assetAmt, uint _strike, uint _price, uint _expiry);
    event NewOptionBought(uint _i);
    event OptionExercised(uint _i, bool cashClosed);
    event OptionReturned(uint _i);
    event OptionCancelled(uint _i);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

/// @dev this interface is a critical addition that is not part of the standard ERC-20 specifications
/// @dev this is required to do the calculation of the total price required, when pricing things in the payment currency
/// @dev only the payment currency is required to have a decimals impelementation on the ERC20 contract, otherwise it will fail
interface Decimals {
  function decimals() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

pragma solidity ^0.8.13;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

pragma solidity ^0.8.13;

interface ISPT {
    function burn(address, uint256) external;
}

pragma solidity ^0.8.0;

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

pragma solidity ^0.8.0;

interface IUniswapV2Pair {
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    
}

pragma solidity ^0.8.0;

import './IUniswapV2Pair.sol';

library UniswapV2Library {


    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn * 998;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = (reserveIn * 1000) + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = (reserveIn * amountOut) * 1000;
        uint denominator = (reserveOut - amountOut) * 998;
        amountIn = (numerator / denominator) + 1;
    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}