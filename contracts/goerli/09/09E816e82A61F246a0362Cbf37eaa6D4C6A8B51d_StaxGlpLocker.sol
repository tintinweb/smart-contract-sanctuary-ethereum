pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (investments/gmx/StaxGlpLocker.sol)

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../../interfaces/common/IWrappedToken.sol";
import "../../interfaces/common/IMintableToken.sol";
import "../../interfaces/investments/gmx/IStaxGmxManager.sol";
import "../../interfaces/investments/gmx/IStaxGmxDepositor.sol";
import "../../interfaces/staking/IStaxStaking.sol";
import "../../common/CommonEventsAndErrors.sol";

/// @title STAX GLP Locker
/// @notice Users purchase stxGLP with whitelisted tokens or ETH, 1:1 as if they were purchasing via GMX.io directly.
/// Staked GLP can also be used to purchase stxGLP.
/// Staked stxGLP will earn boosted ETH/AVAX & stxGMX rewards.
contract StaxGlpLocker is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeERC20 for IMintableToken;
    using Address for address payable;

    /// @notice The ETH (Arbitrum) or AVAX (Avalanche) native token which can be used for buying and selling stxGLP
    address public immutable wrappedNativeToken;

    /// @notice The contract GMX provides to transfer staked GLP
    IERC20 public immutable stakedGlp;

    /// @notice $stxGLP - The STAX liquid wrapper token over $GLP
    /// Users get stxGLP for initial $GLP deposits.
    IMintableToken public immutable stxGlpToken;

    /// @notice The STAX staking contract
    IStaxStaking public staxStaking;

    /// @notice The STAX contract managing the holdings of GMX/GLP
    IStaxGmxManager public staxGmxManager;

    /// @notice The STAX contract holding the staked GMX/GLP/multiplier points/esGMX
    IStaxGmxDepositor public depositor;

    error InvalidSender(address caller);

    event BoughtStxGlp(address indexed user, uint256 fromAmount, address indexed fromToken, uint256 stxGlpAmountOut, bool staked);
    event SoldStxGlp(address indexed user, uint256 stxGlpAmountIn, address indexed toToken, uint256 amountOut, address indexed recipient);
    event StaxGmxManagerSet(address staxGmxManager);
    event StaxStakingSet(address staxStaking);

    constructor(
        address _stxGlpToken,
        address _staxGmxManager,
        address _stakedGlp,
        address _staxStaking
    ) {
        stxGlpToken = IMintableToken(_stxGlpToken);
        staxGmxManager = IStaxGmxManager(_staxGmxManager);
        depositor = staxGmxManager.depositor();
        stakedGlp = IERC20(_stakedGlp);
        wrappedNativeToken = staxGmxManager.wrappedNativeToken();
        staxStaking = IStaxStaking(_staxStaking);
    }

    /// @dev Only the wrappedNativeToken contract (eg weth) can send us ETH, when we withdraw to pay out
    /// a user liquidation.
    receive() external payable {
        if (msg.sender != wrappedNativeToken) revert InvalidSender(msg.sender);
    }

    /// @notice Set the STAX staking contract.
    function setStaxStaking(address _staxStaking) external onlyOwner {
        if (_staxStaking == address(0)) revert CommonEventsAndErrors.InvalidAddress(address(0));
        staxStaking = IStaxStaking(_staxStaking);
        emit StaxStakingSet(_staxStaking);
    }

    /// @notice Set the Stax GMX Manager contract used to apply GMX to earn rewards.
    function setStaxGmxManager(address _staxGmxManager) external onlyOwner {
        if (_staxGmxManager == address(0)) revert CommonEventsAndErrors.InvalidAddress(address(0));
        staxGmxManager = IStaxGmxManager(_staxGmxManager);
        depositor = staxGmxManager.depositor();
        emit StaxGmxManagerSet(_staxGmxManager);
    }

    /// @notice The set of whitelisted tokens which can be used to buy stxGLP
    /// @dev Native tokens (ETH/AVAX) and using staked GLP can also be used and are
    /// not included in this list.
    function whitelistedTokens() external view returns (address[] memory) {
        return staxGmxManager.whitelistedTokens();
    }

    /// @notice Get a quote to buy stxGLP (1:1 with GLP) using one of the whitelisted tokens. 
    /// Can also use the zero address (0x) for a quote of the native ETH/AVAX.
    /// @dev This quote includes any fees GMX.io takes when purchasing GLP.
    function buyStxGlpQuote(uint256 _amount, address _token) external view returns (uint256 feeBasisPoints, uint256 usdgAmountOut, uint256 glpAmountOut) {
        address tokenIn = (_token == address(0)) ? wrappedNativeToken : _token;
        return staxGmxManager.buyStxGlpQuote(_amount, tokenIn);
    }

    /// @notice The GLP Locker can mint stxGLP for users, and optionally immediately stake it on their behalf
    function mintStxGlp(address _for, uint256 _amount, bool _stake) internal {
        if (_stake) {
            stxGlpToken.mint(address(this), _amount);
            stxGlpToken.safeIncreaseAllowance(address(staxStaking), _amount);
            staxStaking.stakeFor(_for, _amount);
        } else {
            stxGlpToken.mint(_for, _amount);
        }
    }

    /** 
      * @notice User buys stxGlp with an amount of (GMX whitelisted) tokens. STAX mints stxGLP 1:1 to the amount of GLP bought.
      * @param _amount How much of token to spend to purchase on GMX
      * @param _token What token to purchase with. This must be a whitelisted GMX asset.
      * @param _stake If true, immediately stake the resulting stxGLP
      * @param _minUsdg The minimum amount of USDG to expect when purchasing. Use buyGlpQuote() to get this number (and expect some slippage)
      * @param _minGlp The minimum amount of GLP to expect when purchasing. Use buyGlpQuote() to get this number (and expect some slippage)
      */
    function buyStxGlpWithToken(
        uint256 _amount, address _token, bool _stake, uint256 _minUsdg, uint256 _minGlp
    ) external returns (uint256 amountOut) {
        if (_amount == 0) revert CommonEventsAndErrors.ExpectedNonZero();

        // Pull tokens from the user and send directly to the STAX contract which purhcases GLP on GMX.io
        IERC20(_token).safeTransferFrom(msg.sender, address(depositor), _amount);
        amountOut = depositor.mintAndStakeGlp(
            _amount, _token, _minUsdg, _minGlp
        );

        // Mint and optionally stake the stxGLP for the user
        mintStxGlp(msg.sender, amountOut, _stake);
        emit BoughtStxGlp(msg.sender, _amount, _token, amountOut, _stake);
    }

    /** 
      * @notice User buys stxGlp with an amount of native ETH/AVAX. STAX mints stxGLP 1:1 to the amount of GLP bought.
      * msg.value is used as the amount to purchase with.
      * @param _stake If true, immediately stake the resulting stxGLP
      * @param _minUsdg The minimum amount of USDG to expect when purchasing. Use buyGlpQuote() to get this number (and expect some slippage)
      * @param _minGlp The minimum amount of GLP to expect when purchasing. Use buyGlpQuote() to get this number (and expect some slippage)
      */
    function buyStxGlpWithNative(
        bool _stake, uint256 _minUsdg, uint256 _minGlp
    ) external payable nonReentrant returns (uint256 amountOut) {
        if (msg.value == 0) revert CommonEventsAndErrors.ExpectedNonZero();

        // Convert the native to the wrapped token (eg weth)
        IWrappedToken(wrappedNativeToken).deposit{value: msg.value}();

        // Send directly to the STAX contract which purhcases GLP on GMX.io
        IERC20(wrappedNativeToken).safeTransfer(address(depositor), msg.value);
        amountOut = depositor.mintAndStakeGlp(
            msg.value, wrappedNativeToken, _minUsdg, _minGlp
        );

        // Mint and optionally stake the stxGLP for the user
        mintStxGlp(msg.sender, amountOut, _stake);
        emit BoughtStxGlp(msg.sender, msg.value, address(0), amountOut, _stake);
    }

    /** 
      * @notice User buys stxGlp with an amount of (GMX whitelisted) tokens. STAX mints stxGLP 1:1 to the amount of GLP bought.
      * @param _amount How much of token to use to purchase GLP on GMX.io
      * @param _stake If true, immediately stake the resulting stxGlp
      */
    function buyStxGlpWithStakedGlp(
        uint256 _amount, bool _stake
    ) external returns (uint256) {
        if (_amount == 0) revert CommonEventsAndErrors.ExpectedNonZero();

        // Pull tokens from the user and send directly to the STAX deposit contract.
        // This is a special GMX contract which unstakes from the user and restakes to the STAX depositor
        stakedGlp.safeTransferFrom(msg.sender, address(depositor), _amount);

        // Mint and optionally stake the stxGLP for the user
        mintStxGlp(msg.sender, _amount, _stake);
        emit BoughtStxGlp(msg.sender, _amount, address(stakedGlp), _amount, _stake);
        return _amount;
    }

    /// @notice Get a quote to sell stxGLP to one of the whitelisted tokens. 
    /// Can also use the zero address (0x) for a quote of the native ETH/AVAX.
    /// @dev This quote includes any fees GMX.io takes when purchasing GLP, and also STAX withdrawal fees.
    function sellStxGlpQuote(uint256 _stxGmxAmount, address _toToken) external view returns (uint256 feeBasisPoints, uint256 tokenAmountOut) {
        address tokenOut = (_toToken == address(0)) ? wrappedNativeToken : _toToken;
        return staxGmxManager.sellStxGlpQuote(_stxGmxAmount, tokenOut); 
    }

    /** 
      * @notice Sell stxGLP to one of the whitelisted tokens. Note STAX may retain a percentage of fees on liquidation.
      * @param _amount How much stxGlp to sell
      * @param _toToken What token to receive. This must be a whitelisted GMX asset.
      * @param _minAmountOut The minimum amount of `_toToken` to expect when purchasing. Use sellStxGlpQuote() to get this number (and expect some slippage)
      * @param _recipient The receiving address of the `_toToken`
      */
    function sellStxGlpToToken(uint256 _amount, address _toToken, uint256 _minAmountOut, address _recipient) external returns (uint256 amountOut) {
        amountOut = staxGmxManager.sellStxGlp(msg.sender, _amount, _toToken, _minAmountOut, _recipient);
        emit SoldStxGlp(msg.sender, _amount, _toToken, amountOut, _recipient);
    }

    /** 
      * @notice Sell stxGLP to the native (eg ETH/AVAX). Note STAX may retain a percentage of fees on liquidation.
      * @param _amount How much stxGlp to sell
      * @param _minAmountOut The minimum amount of `_toToken` to expect when purchasing. Use sellStxGlpQuote() to get this number (and expect some slippage)
      * @param _recipient The receiving address of the `_toToken`
      */
    function sellStxGlpToNative(uint256 _amount, uint256 _minAmountOut, address payable _recipient) external nonReentrant returns (uint256 amountOut) {
        // Sell the stxGLP back to the wrapped native token (eg weth), to this contract.
        amountOut = staxGmxManager.sellStxGlp(msg.sender, _amount, wrappedNativeToken, _minAmountOut, address(this));

        // Convert the wrapped native token (weth/wavax) to the native token (ETH/AVAX)
        IWrappedToken(wrappedNativeToken).withdraw(amountOut);
        _recipient.sendValue(amountOut);

        emit SoldStxGlp(msg.sender, _amount, address(0), amountOut, _recipient);
    }

    /** 
      * User sells stxGlp to an amount of staked GLP. Note STAX may retain a percentage of fees on liquidation.
      * @param _amount How much stxGlp to sell
      * @param _recipient The receiving address of the `_toToken`
      */
    function sellStxGlpToStakedGlp(uint256 _amount, address _recipient) external returns (uint256 amountOut) {
        amountOut = staxGmxManager.sellStxGlpToStakedGlp(msg.sender, _amount, _recipient);
        emit SoldStxGlp(msg.sender, _amount, address(stakedGlp), amountOut, _recipient);
    }

    /// @notice Owner can recover tokens
    function recoverToken(address _token, address _to, uint256 _amount) external onlyOwner {
        IERC20(_token).safeTransfer(_to, _amount);
        emit CommonEventsAndErrors.TokenRecovered(_to, _token, _amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/common/IWrappedToken.sol)

interface IWrappedToken {
    function deposit() external payable;
    function withdraw(uint256) external;
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/common/IMintableToken.sol)

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMintableToken is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(address account, uint256 amount) external;
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/investments/gmx/IStaxGmxManager.sol)

import "../../staking/IStaxInvestmentManager.sol";
import "./IStaxGmxDepositor.sol";

interface IStaxGmxManager {
    function harvestableRewards(bool glpTrackerRewards) external view returns (uint256[] memory amounts);
    function projectedRewardRates(bool glpTrackerRewards) external view returns (uint256[] memory amounts);
    function harvestRewards() external;
    function rewardTokensList() external view returns (address[] memory tokens);

    function wrappedNativeToken() external view returns (address);
    function depositor() external view returns (IStaxGmxDepositor);

    function sellStxGmx(
        address _seller, 
        uint256 _sellAmount,
        address _recipient
    ) external returns (uint256 amountOut);

    function whitelistedTokens() external view returns (address[] memory);
    function buyStxGlpQuote(uint256 _amount, address _token) external view returns (uint256 feeBasisPoints, uint256 usdgAmountOut, uint256 glpAmountOut);
    function sellStxGlpQuote(uint256 _stxGmxAmount, address _toToken) external view returns (uint256 feeBasisPoints, uint256 tokenAmountOut);
    function sellStxGlp(
        address _seller, 
        uint256 _sellAmount,
        address _toToken,
        uint256 _minAmountOut,
        address _recipient
    ) external returns (uint256 amountOut);
    function sellStxGlpToStakedGlp(
        address _seller,
        uint256 _sellAmount,
        address _recipient
    ) external returns (uint256 amountOut);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/investments/gmx/IStaxGmxDepositor.sol)

import "../../../common/FractionalAmount.sol";

interface IStaxGmxDepositor {
    function rewardRates(bool glpTrackerRewards) external view returns (uint256 wrappedNativeTokensPerSec, uint256 esGmxTokensPerSec);
    function harvestableRewards(bool glpTrackerRewards) external view returns (
        uint256 wrappedNativeAmount, 
        uint256 esGmxAmount
    );
    function harvestRewards(FractionalAmount.Data calldata _esGmxVestingRate) external returns (
        uint256 wrappedNativeClaimedFromGmx,
        uint256 wrappedNativeClaimedFromGlp,
        uint256 esGmxClaimedFromGmx,
        uint256 esGmxClaimedFromGlp,
        uint256 vestedGmxClaimed
    );

    function stakeGmx(uint256 _amount) external;
    function unstakeGmx(uint256 _maxAmount) external;

    function mintAndStakeGlp(
        uint256 fromAmount,
        address fromToken,
        uint256 minUsdg,
        uint256 minGlp
    ) external returns (uint256);
    function unstakeAndRedeemGlp(
        uint256 glpAmount, 
        address toToken, 
        uint256 minOut, 
        address receiver
    ) external returns (uint256);
    function transferStakedGlp(uint256 glpAmount, address receiver) external;
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/staking/IStaxStaking.sol)

import "./IStaxRewardsDistributor.sol";

interface IStaxStaking {
    function stakeFor(address _for, uint256 _amount) external;
    function updateRewards(address _addr, bool _forceHarvest) external;
    function distributor() external view returns (IStaxRewardsDistributor);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (common/CommonEventsAndErrors.sol)

/// @notice A collection of common errors thrown within the STAX contracts
library CommonEventsAndErrors {
    error InsufficientBalance(address token, uint256 required, uint256 balance);
    error InvalidToken(address token);
    error InvalidParam();
    error InvalidAddress(address addr);
    error OnlyOwner(address caller);
    error OnlyOwnerOrOperators(address caller);
    error ExpectedNonZero();

    event TokenRecovered(address indexed to, address indexed token, uint256 amount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/staking/IStaxInvestmentManager.sol)

interface IStaxInvestmentManager {
    function rewardTokensList() external view returns (address[] memory tokens);
    function harvestRewards() external returns (uint256[] memory amounts);
    function harvestableRewards() external view returns (uint256[] memory amounts);
    function projectedRewardRates() external view returns (uint256[] memory amounts);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (common/FractionalAmount.sol)

import "./CommonEventsAndErrors.sol";

/// @notice Utilities to operate on fractional amounts of an input
/// - eg to calculate the split of rewards for fees.
library FractionalAmount {
    struct Data {
        uint128 numerator;
        uint128 denominator;
    }

    /// @notice Helper to set the storage value with safety checks.
    function set(Data storage self, uint128 _numerator, uint128 _denominator) internal {
        if (_denominator == 0 || _numerator > _denominator) revert CommonEventsAndErrors.InvalidParam();
        self.numerator = _numerator;
        self.denominator = _denominator;
    }

    /// @notice Split an amount into two parts based on a fractional ratio
    /// eg: 333/1000 (33.3%) can be used to split an input amount of 600 into: (199, 401).
    /// @dev The numerator amount is truncated if necessary
    function split(Data storage self, uint256 inputAmount) internal view returns (uint256 numeratorAmount, uint256 denominatorAmount) {
        if (self.numerator == 0) {
            return (0, inputAmount);
        }
        unchecked {
            numeratorAmount = (inputAmount * self.numerator) / self.denominator;
            denominatorAmount = inputAmount - numeratorAmount;
        }
    }

    /// @notice Split an amount into two parts based on a fractional ratio
    /// eg: 333/1000 (33.3%) can be used to split an input amount of 600 into: (199, 401).
    /// @dev Overloaded version of the above, using calldata/pure to avoid a copy from storage in some scenarios
    function split(Data calldata self, uint256 inputAmount) internal pure returns (uint256 numeratorAmount, uint256 denominatorAmount) {
        if (self.numerator == 0 || self.denominator == 0) {
            return (0, inputAmount);
        }
        unchecked {
            numeratorAmount = (inputAmount * self.numerator) / self.denominator;
            denominatorAmount = inputAmount - numeratorAmount;
        }
    }
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/staking/IStaxRewardsDistributor.sol)

interface IStaxRewardsDistributor {
    function allRewardTokens() external view returns (address[] memory);
    function harvestRewards() external;
    function pendingRewards() external view returns (uint256[] memory pendingAmounts);
    function distribute(bool forceHarvest) external returns (uint256[] memory distributedAmounts);
    function projectedRewardRates() external view returns (uint256[] memory amounts);
    function latestActualRewardRates() external view returns (uint256[] memory amounts);
    function setStaking(address _staking) external;
}