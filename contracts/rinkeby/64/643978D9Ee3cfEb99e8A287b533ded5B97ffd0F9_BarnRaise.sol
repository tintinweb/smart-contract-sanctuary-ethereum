// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ISwapRouter.sol";
import "./IWETH.sol";

/**
 * @author publius
 * @title Barn Raiser 
 */

interface IERC20D {
    function decimals() external view returns (uint8);
}

contract BarnRaise is Ownable, ReentrancyGuard {

    event CreateBarnRaise(
        uint256 bidStart, 
        uint256 bonusPerDay, 
        uint256 start, 
        uint256 length, 
        uint256 weatherStep, 
        uint256 target
    );
    event Sow(address indexed account, uint256 amount, uint256 weather);
    event CreateBid(
        address indexed account,
        uint256 amount,
        uint256 weather,
        uint256 idx,
        uint256 bonus
    );
    event UpdateBid(
        address indexed account,
        uint256 alteredAmount,
        uint256 addedAmount,
        uint256 prevWeather,
        uint256 prevIdx,
        uint256 newWeather,
        uint256 newIdx,
        uint256 newBonus
    );

    event Contribution(
        address token,
        uint256 amount
    );

    using SafeERC20 for IERC20;

    /////////////////////// TESTING //////////////////////
    address constant public custodian = 0x925753106FCdB6D2f30C3db295328a0A1c5fD1D1; // Temporary: BF Multi-sig
    uint256 constant public bidStart = 1650891600;

    /////////////////////// TESTING //////////////////////

    // Bid Period Settings
    // uint256 constant public bidStart      = 1651496400; // 5/2 9 AM PST
    uint256 constant public bonusPerDay   = 3;
    uint256 constant public bidDays       = 7;
    uint256 constant public secondsPerDay = 86400;

    // Barn Raise Settings
    uint256 constant public start       = bidStart + bidDays * secondsPerDay; // 5/9 9 AM PST
    uint256 constant public length      = 259200; // 3 days denominated in seconds. 3*24*60*60
    uint256 constant public baseWeather = 20; // Start at 20% Weather
    uint256 constant public step        = 600; // 10 minutes denominated in seconds.
    uint256 constant public maxWeather  = 452;

    // Raise Settings
    // address constant public custodian = 0x21DE18B6A8f78eDe6D16C50A167f6B222DC08DF7; // Temporary: BF Multi-sig
    uint256 constant target           = 77_000_000 * 1e18;
    uint256 constant decimals         = 6;

    // Uniswap Settings
    address constant SWAP_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address constant WETH        = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant USDC        = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    uint24 constant POOL_FEE     = 500;

    uint256 public funded = 0; // A variable indicating if the Barn Raise as been fully funded.
    mapping(address => uint256) whitelisted; // A mapping specifying whether a token is whitelisted or not.

    // Farmer => Weather => idx => amount We need to add idx in the case where a Farmer posts 2 Bids at the same Weather.
    mapping(bytes32 => uint256) bids;

    constructor(address[] memory tokens) {
        for (uint256 i = 0; i < tokens.length; i++) {
            whitelisted[tokens[i]] = 10 ** (IERC20D(tokens[i]).decimals() - decimals);
        }
        _transferOwnership(_msgSender());
        emit CreateBarnRaise(bidStart, bonusPerDay, start, length, step, target);
    }

    ////////////////////////////////////////// SOW ////////////////////////////////////////////////

    function buyAndSow(uint256 minBuyAmount, uint256 amount) external payable nonReentrant {
        uint256 amountOut = buy(minBuyAmount);
        _sow(amount + amountOut);
        sendToken(USDC, amount);
        emit Contribution(USDC, amount + amountOut);
    }

    function sow(address token, uint256 amount) external nonReentrant {
        _sow(amount / whitelisted[token]);
        sendToken(token, amount);
        emit Contribution(token, amount);
    }

    function _sow(uint256 amount) private {
        require(started() && !ended(), "Barn Raise: Not active.");
        emit Sow(msg.sender, amount, getWeather());
    }

    ///////////////////////////////////// CREATE BID //////////////////////////////////////////////

    function buyAndCreateBid(uint256 minBuyAmount, uint256 amount, uint256 weather) external payable nonReentrant {
        uint256 amountOut = buy(minBuyAmount);
        sendToken(USDC, amount);
        _createBid(amount + minBuyAmount, weather);
        emit Contribution(USDC, amount + amountOut);
    }

    function createBid(address token, uint256 amount, uint256 weather) external nonReentrant {
        _createBid(amount / whitelisted[token], weather);
        sendToken(token, amount);
        emit Contribution(token, amount);
    }

    function _createBid(uint256 amount, uint256 weather) private {
        uint256 bonus;
        (weather, bonus) = checkBid(weather);
        uint256 idx = saveBid(amount, weather);
        emit CreateBid(msg.sender, amount, weather, idx, bonus);
    }

    ///////////////////////////////////// UPDATE BID //////////////////////////////////////////////

    function buyAndUpdateBid(
        uint256 minBuyAmount, 
        uint256 newAmount, 
        uint256 prevWeather, 
        uint256 prevIdx, 
        uint256 newWeather
    ) external payable nonReentrant {
        uint256 amountOut = buy(minBuyAmount);
        newAmount = _updateBid(newAmount, amountOut, prevWeather, prevIdx, newWeather);
        emit Contribution(USDC, newAmount + amountOut);
        if (newAmount > 0) sendToken(USDC, newAmount);
    }

    function updateBid(
        address token, 
        uint256 newAmount, 
        uint256 prevWeather, 
        uint256 prevIdx, 
        uint256 newWeather
    ) external nonReentrant {
        newAmount = _updateBid(newAmount, 0, prevWeather, prevIdx, newWeather);
        if (newAmount > 0) {
            emit Contribution(token, newAmount);
            sendToken(token, newAmount * whitelisted[token]);
        }
    }

    function _updateBid(
        uint256 newAmount,
        uint256 extraAmount,
        uint256 prevWeather, 
        uint256 prevIdx, 
        uint256 newWeather
    ) private returns (uint256 transferAmount) {
        uint256 bonus;
        (newWeather, bonus) = checkBid(newWeather);
        require(newWeather < prevWeather, "Barn Raise: Weather not valid.");
        uint256 prevAmount = deleteBid(newAmount, prevWeather, prevIdx);
        uint256 newIdx = saveBid(newAmount + extraAmount, newWeather);
        transferAmount = newAmount - prevAmount;
        emit UpdateBid(msg.sender, prevAmount, transferAmount + extraAmount, prevWeather, prevIdx, newWeather, newIdx, bonus);
    }

    ///////////////////////////////////// Barn Raise //////////////////////////////////////////////

    function setFunded(uint256 f) external onlyOwner {
        funded = f;
    }

    function started() public view returns (bool) {
        return block.timestamp >= start;
    }

    function ended() public view returns (bool) {
        return block.timestamp > start + length || funded > 0;
    }

    function getWeather() public view returns (uint256 w) {
        if (!started()) return 0;
        w = (block.timestamp - start) / step + baseWeather;
    }

    ///////////////////////////////////// Bid Period //////////////////////////////////////////////

    function bid(bytes32 idx) external view returns (uint256) {
        return bids[idx];
    }

    function getBonus() public view returns (uint256 b) {
        if (started()) return 0;
        b = ((start - block.timestamp - 1) / secondsPerDay + 1) * bonusPerDay;
    }

    function biddingStarted() public view returns (bool) {
        return block.timestamp >= bidStart;
    }

    function checkBid(uint256 weather) private view returns (uint256 w, uint256 b) {
        require(biddingStarted() && !ended(), "Barn Raise: Bidding not active.");
        require(weather <= maxWeather, "Barn Raise: Weather too high.");
         w = getWeather();
        if (weather > w) w = weather;
        b = getBonus();
    }

    function saveBid(uint256 amount, uint256 weather) private returns (uint256 idx) {
        idx = block.timestamp;
        bytes32 hashId = createBidId(msg.sender, weather, idx);
        while (bids[hashId] > 0) {
            ++idx;
            hashId = createBidId(msg.sender, weather, idx);
        }
        bids[hashId] = amount;
    }

    function deleteBid(uint256 amount, uint256 weather, uint256 idx) private returns (uint256 prevAmount) {
        bytes32 hashId = createBidId(msg.sender, weather, idx);
        prevAmount = bids[hashId];
        require(prevAmount > 0, "Barn Raise: Bid not valid.");
        if (amount < prevAmount) prevAmount = amount;
        bids[hashId] -= prevAmount;
    }

    function createBidId(address account, uint256 w, uint256 idx) private pure returns (bytes32 id) {
        id = keccak256(abi.encodePacked(account, w, idx));
    }

    ///////////////////////////////////// Contributing //////////////////////////////////////////////

    function isWhitelisted(address token) public view returns (bool) {
        return whitelisted[token] > 0;
    }

    function sendToken(address token, uint256 amount) private {
        require(isWhitelisted(token), "Barn Raise: not whitelisted.");
        IERC20(token).safeTransferFrom(msg.sender, custodian, amount);
    }

    function buy(uint256 minAmountOut) private returns (uint256 amountOut) {
        IWETH(WETH).deposit{value: msg.value}();
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: WETH,
                tokenOut: USDC,
                fee: POOL_FEE,
                recipient: custodian,
                deadline: block.timestamp,
                amountIn: msg.value,
                amountOutMinimum: minAmountOut,
                sqrtPriceLimitX96: 0
            });
        amountOut = ISwapRouter(SWAP_ROUTER).exactInputSingle(params);
    }
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }
}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @author Publius
 * @title WETH Interface
**/
interface IWETH is IERC20 {

    function deposit() external payable;
    function withdraw(uint) external;

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