// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// Thrown when a caller is not an owner
error NotAnOwner(address caller);

/// Thown when address(0) is encountered
error ZeroAddress();

/// Thrown when amount exceeds ticketsAvailable
error AmountExceedsTicketsAvailable(uint256 amount, uint256 ticketsAvailable);

/// Thrown when amount exceeds balance
error InsufficientBalance(uint256 amount, uint256 balance);

/// Thrown when amount exceeds allowance
error InsufficientAllowance(uint256 amount, uint256 allowance);

/// Thrown when purchase is prohibited in phase
error PurchaseProhibited(uint256 phase);

/// Thrown when amount is below the minimum purchase amount
error InsufficientAmount(uint256 amount, uint256 minimum);

/// Thrown when the user is not whitelisted
error NotWhitelisted(address user);

/// Thrown when removal is prohibited in phase
error RemovalProhibited(uint256 phase);

/*
 * Allow users to purchase outputToken using inputToken via the medium of tickets
 * Purchasing tickets with the inputToken is mediated by the INPUT_RATE and
 * withdrawing tickets for the outputToken is mediated by the OUTPUT_RATE
 * 
 * Purchasing occurs over 2 purchase phases:
 *  1: purchases are limited to whitelisted addresses
 *  2: purchases are open to any address
 * 
 * Withdrawals of tokens equivalent in value to purchased tickets occurs immediately
 * upon completion of purchase transaction
 */
contract PublicPresale is Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /**
     * Purchase phase determines ticket purchase eligiblity
     *  0: is the default on contract creation
     *     purchases are prohibited
     *  1: manually set by the owner
     *     purchases are limited to whitelisted addresses
     *  2: begins automatically PURCHASE_PHASE_DURATION after the start of WhitelistOnly
     *     purchases are open to any address
     */
    enum PurchasePhase {
        NoPurchase,
        WhitelistOnly,
        Purchase
    }

    /// Maximum number of tickets available for purchase at the start of the sale
    uint256 public constant TICKET_MAX = 2000;

    /// Minimum number of tickets that can be purchased at a time
    uint256 public constant MINIMUM_TICKET_PURCHASE = 1;

    /// Unsold tickets available for purchase
    /// ticketsAvailable = TICKET_MAX - (sum(user.purchased) for user in whitelist)
    /// where user.purchased is in range [0, user.maxTicket] for user in whitelist
    uint256 public ticketsAvailable;

    /// Token exchanged to purchase tickets, i.e. USDC
    IERC20 public inputToken;

    /// Number of tickets a user gets per `inputToken`
    uint256 public INPUT_RATE;

    /// Token being sold in presale and redeemable by exchanging tickets, i.e. HELIX
    IERC20 public outputToken;

    /// Number of `outputTokens` a user gets per ticket
    uint256 public OUTPUT_RATE;

    /// Number of decimals on the `inputToken` used for calculating ticket exchange rates
    uint256 public constant INPUT_TOKEN_DECIMALS = 1e6;

    /// Number of decimals on the `outputToken` used for calculating ticket exchange rates
    uint256 public constant OUTPUT_TOKEN_DECIMALS = 1e18;

    /// Address that receives `inputToken`s sold in exchange for tickets
    address public treasury;

    /// Current PurchasePhase
    PurchasePhase public purchasePhase;

    /// Length of purchase phases > 0 (in seconds), 86400 == 1 day
    uint256 public immutable PURCHASE_PHASE_DURATION;

    /// Timestamp after which the current PurchasePhase has ended
    uint256 public purchasePhaseEndTimestamp;

    /// Owners who can whitelist users
    address[] public owners;

    /// true if address is an owner and false otherwise
    mapping(address => bool) public isOwner;

    /// true if user can purchase tickets during WhitelistOnly PurchasePhase and false otherwise
    mapping(address => bool) public whitelist;

    /// Emitted when a user purchases amount of tickets
    event Purchased(address indexed user, uint256 amount);

    /// Emitted when an owner burns amount of tickets
    event Burned(uint256 amount);

    /// Emitted when a user withdraws amount of tickets
    event Withdrawn(address indexed user, uint256 amount);

    /// Emitted when an existing owner adds a new owner
    event OwnerAdded(address indexed owner, address indexed newOwner);

    /// Emitted when the purchase phase is set
    event SetPurchasePhase(
        PurchasePhase purchasePhase, 
        uint256 startTimestamp, 
        uint256 endTimestamp
    );

    modifier onlyOwner() {
        if (!isOwner[msg.sender]) revert NotAnOwner(msg.sender);
        _;
    }

    modifier onlyValidAddress(address _address) {
        if (_address == address(0)) revert ZeroAddress();
        _;
    }

    modifier onlyValidAmount(uint256 _amount) {
        if (_amount > ticketsAvailable) {
            revert AmountExceedsTicketsAvailable(_amount, ticketsAvailable);
        }
        _;
    }

    constructor(
        address _inputToken,
        address _outputToken, 
        address _treasury,
        uint256 _INPUT_RATE, 
        uint256 _OUTPUT_RATE,
        uint256 _PURCHASE_PHASE_DURATION
    ) 
        onlyValidAddress(_inputToken)
        onlyValidAddress(_outputToken)
        onlyValidAddress(_treasury)
    {
        inputToken = IERC20(_inputToken);
        outputToken = IERC20(_outputToken);

        INPUT_RATE = _INPUT_RATE;
        OUTPUT_RATE = _OUTPUT_RATE;

        treasury = _treasury;

        isOwner[msg.sender] = true;
        owners.push(msg.sender);

        ticketsAvailable = TICKET_MAX;

        PURCHASE_PHASE_DURATION = _PURCHASE_PHASE_DURATION;
    }

    /// Purchase _amount of tickets
    function purchase(uint256 _amount) 
        external 
        whenNotPaused
        nonReentrant 
        onlyValidAmount(_amount) 
    {
        // Want to be in the latest phase
        updatePurchasePhase();
   
        // Proceed only if the purchase is valid
        _validatePurchase(msg.sender, _amount);

        // Update the contract's remaining tickets
        ticketsAvailable -= _amount;
        
        // Get the `inputTokenAmount` in `inputToken` to purchase `amount` of tickets
        uint256 inputTokenAmount = getAmountOut(_amount, inputToken); 

        // Pay for the `amount` of tickets
        uint256 balance = inputToken.balanceOf(msg.sender);
        if (inputTokenAmount > balance) revert InsufficientBalance(inputTokenAmount, balance);
    
        uint256 allowance = inputToken.allowance(msg.sender, address(this));
        if (inputTokenAmount > allowance) {
            revert InsufficientAllowance(inputTokenAmount, allowance);
        }

        // Pay for the tickets by withdrawing inputTokenAmount from caller
        inputToken.safeTransferFrom(msg.sender, treasury, inputTokenAmount);
        
        // Get the amount of tokens caller can purchase for `amount`
        uint256 outputTokenAmount = getAmountOut(_amount, outputToken);
        
        // Transfer `amount` of tickets to caller
        outputToken.safeTransfer(msg.sender, outputTokenAmount);

        emit Purchased(msg.sender, _amount);
    }

    /// Return the address array of registered owners
    function getOwners() external view returns(address[] memory) {
        return owners;
    }

    /// Return true if _amount is removable by owner
    function isRemovable(uint256 _amount) external view onlyOwner returns (bool) {
        return _amount <= ticketsAvailable;
    }

    /// Used to destroy _outputToken equivalant in value to _amount of tickets
    function burn(uint256 _amount) external onlyOwner { 
        _remove(_amount);

        uint256 tokenAmount = getAmountOut(_amount, outputToken);
        outputToken.burn(address(this), tokenAmount);

        emit Burned(_amount);
    }

    /// Used to withdraw _outputToken equivalent in value to _amount of tickets to owner
    function withdraw(uint256 _amount) external onlyOwner {
        _remove(_amount);

        // transfer to `to` the `tokenAmount` equivalent in value to `amount` of tickets
        uint256 tokenAmount = getAmountOut(_amount, outputToken);
        outputToken.safeTransfer(msg.sender, tokenAmount);

        emit Withdrawn(msg.sender, _amount);
    }

    /// Called externally by the owner to manually set the _purchasePhase
    function setPurchasePhase(PurchasePhase _purchasePhase) external onlyOwner {
        _setPurchasePhase(_purchasePhase);
    }

    /// Called externally to grant multiple _users permission to purchase tickets during 
    /// WithdrawOnly phase
    function whitelistAdd(address[] calldata _users) external onlyOwner {
        uint256 length = _users.length;
        for (uint256 i = 0; i < length; i++) {
            address user = _users[i]; 
            whitelist[user] = true;
        }
    }

    /// Revoke permission for _user to purchase tickets
    function whitelistRemove(address _user) external onlyOwner {
        delete whitelist[_user];
    }

    /// Add a new _owner to the contract, only callable by an existing owner
    function addOwner(address _owner) external onlyOwner onlyValidAddress(_owner) {
        if (isOwner[_owner]) return;
        isOwner[_owner] = true;
        owners.push(_owner);

        emit OwnerAdded(msg.sender, _owner);
    }

    // remove an existing owner from the contract, only callable by an owner
    function removeOwner(address owner) external onlyValidAddress(owner) onlyOwner {
        require(isOwner[owner], "VipPresale: NOT AN OWNER");
        isOwner[owner] = false;

        // array remove by swap 
        for (uint i = 0; i < owners.length; i++) {
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                owners.pop();
            }
        }
    }

    /// Called by the owner to pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    /// Called by the owner to unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    /// Called periodically and, if sufficient time has elapsed, update the PurchasePhase
    function updatePurchasePhase() public {
        if (purchasePhase == PurchasePhase.WhitelistOnly && 
            block.timestamp >= purchasePhaseEndTimestamp
        ) {
            _setPurchasePhase(PurchasePhase.Purchase);
        }
    }

    /// Get _amountOut of _tokenOut for _amountIn of tickets
    function getAmountOut(uint256 _amountIn, IERC20 _tokenOut) 
        public 
        view 
        returns (uint256 amountOut
    ) {
        if (address(_tokenOut) == address(inputToken)) {
            amountOut = _amountIn * INPUT_RATE * INPUT_TOKEN_DECIMALS;
        } else if (address(_tokenOut) == address(outputToken)) {
            amountOut = _amountIn * OUTPUT_RATE * OUTPUT_TOKEN_DECIMALS;
        }
        // else default to 0
    }

    // Called internally to update the _purchasePhase
    function _setPurchasePhase(PurchasePhase _purchasePhase) private {
        purchasePhase = _purchasePhase;
        purchasePhaseEndTimestamp = block.timestamp + PURCHASE_PHASE_DURATION;
        emit SetPurchasePhase(_purchasePhase, block.timestamp, purchasePhaseEndTimestamp);
    }

    // Validate whether _user is eligible to purchase _amount of tickets
    function _validatePurchase(address _user, uint256 _amount) 
        private 
        view 
        onlyValidAddress(_user)
    {
        if (purchasePhase == PurchasePhase.NoPurchase) {
            revert PurchaseProhibited(uint(purchasePhase));
        }
        if (_amount < MINIMUM_TICKET_PURCHASE) {
            revert InsufficientAmount(_amount, MINIMUM_TICKET_PURCHASE);
        }
        if (purchasePhase == PurchasePhase.WhitelistOnly) { 
            if (!whitelist[_user]) revert NotWhitelisted(_user);
        }
    }

    // Used internally to remove _amount of tickets from circulation and transfer an 
    // amount of _outputToken equivalent in value to _amount to owner
    function _remove(uint256 _amount) private onlyValidAmount(_amount) {
        // proceed only if the removal is valid
        // note that only owners can make removals
        if (purchasePhase != PurchasePhase.NoPurchase) {
            revert RemovalProhibited(uint(purchasePhase));
        }

        // decrease the tickets available by the amount being removed
        ticketsAvailable -= _amount;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity >=0.8.0;

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

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function burn(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity >=0.8.0;

import "../interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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