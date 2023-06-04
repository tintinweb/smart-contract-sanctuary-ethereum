// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IDIVAOwnershipMain} from "./interfaces/IDIVAOwnershipMain.sol";

/**
 * @notice Contract that stores the DIVA owner and implements a decentralized mechanism (a so-called
 * decentralized protocol takeover mechanism) to elect a new owner.
 * The reason for outsourcing the owner logic into a separate contract allows the owner to inherit all
 * future versions of DIVA protocol and other related contracts by referencing this contract.
 * The owner election logic is specific to the main chain. Tellor protocol is used to communicate
 * the owner to secondary chains.
 * 
 * Decentralized protocol takeover mechanism:
 * The owner is elected by DIVA Token holders which express their support for a candidate (incl. current owner) 
 * by staking DIVA tokens towards that candidate. If a candidate accumulates more stake than the current owner,
 * they can trigger an election cycle which is split into the following two successive periods:
 *   1. Showdown period (30 days): DIVA token holders continue to stake/unstake during that period to express
 *   their support for their preferred candidate. At the end of the period, a snapshot of the stakes is taken
 *   via a manual ownership claim submission process (see second period below) which determines the outcome of the
 *   election cycle.
 *   2. Ownership claim submission period (7 days): any candidate that has a higher stake than the current owner
 *   can submit a claim on the ownership by calling the `submitOwnershipClaim` function. 
 *   Staking/unstaking are disabled during that period. This manual ownership claim submission process has been
 *   implemented to avoid costly max calculations / loops inside the smart contract.
 */
contract DIVAOwnershipMain is IDIVAOwnershipMain, ReentrancyGuard {
    using SafeERC20 for IERC20Metadata;

    // `_owner` variable is equal to candidate that submitted a valid ownership claim during
    // the ownership claim submission period. `_owner` is returned as the new owner by the 
    // `getCurrentOwner()`function after the end of the election cycle.
    // Initialized in the constructor at contract deployment.
    address private _owner;

    // Previous owner is updated with the current owner when an election cycle is triggered.
    // `_previousOwner` is initialized to zero address at contract deployment.
    // Initialized to zero address at contract deployment.
    address private _previousOwner;

    // DIVA token address used for staking
    IERC20Metadata private immutable _DIVA_TOKEN;

    // Staking related storage variables
    mapping(address => uint256) private _candidateToStakedAmount;
    mapping(address => mapping(address => uint256)) private _voterToCandidateToStakedAmount;
    mapping(address => mapping(address => uint256)) private _voterToTimestampLastStakedForCandidate; 

    // Election cycle related end times. Initialized to zero ad contract deployment.
    uint256 private _showdownPeriodEnd;
    uint256 private _submitOwnershipClaimPeriodEnd;
    uint256 private _cooldownPeriodEnd;
    
    // Relevant period lengths
    uint256 private constant _SHOWDOWN_PERIOD = 30 days;
    uint256 private constant _SUBMIT_OWNERSHIP_CLAIM_PERIOD = 7 days;
    uint256 private constant _COOLDOWN_PERIOD = 7 days;
    uint256 private constant _MIN_STAKING_PERIOD = 7 days;

    constructor(
        address _initialOwner,
        IERC20Metadata _divaToken
    ) payable {
        if (_initialOwner == address(0)) {
            revert ZeroOwnerAddress();
        }
        if (address(_divaToken) == address(0)) {
            revert ZeroDIVATokenAddress();
        }

        _owner = _initialOwner;
        _DIVA_TOKEN = _divaToken;
    }

    function stake(address _candidate, uint256 _amount) external override nonReentrant {
        // Ensure that call is not within the ownership claim submission period
        if (_isWithinSubmitOwnershipClaimPeriod()) {
            revert WithinSubmitOwnershipClaimPeriod(block.timestamp, _submitOwnershipClaimPeriodEnd);
        }
        
        // Transfer DIVA token from `msg.sender` to `this`. Requires prior approval
        // from `msg.sender` to succeed. No security risk of executing this external function as 
        // `_DIVA_TOKEN` is initialized in the constructor and the functionality is known.
        _DIVA_TOKEN.safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
                
        // Store timestamp of staking operation for the minimum staking period check in
        // `unstake` function
        _voterToTimestampLastStakedForCandidate[msg.sender][_candidate] = block.timestamp;

        // Increase `msg.sender`'s staked amount for candidate
        _voterToCandidateToStakedAmount[msg.sender][_candidate] += _amount;

        // Increase staked amount for candidate
        _candidateToStakedAmount[_candidate] += _amount;

        // Log candidate and amount
        emit Staked(msg.sender, _candidate, _amount);        
    }

    function triggerElectionCycle() external override {    
        // Confirm that there is no on-going election cycle
        if (_isWithinElectionCycle()) {
            revert WithinElectionCycle(block.timestamp, _submitOwnershipClaimPeriodEnd);
        }

        // Confirm that at least 7 days have passed since the last election cycle end
        if (_isWithinCooldownPeriod()) {
            revert WithinCooldownPeriod(block.timestamp, _cooldownPeriodEnd);
        }

        // Confirm that `msg.sender` has strictly more support than the current owner
        if (_candidateToStakedAmount[msg.sender] <= _candidateToStakedAmount[_owner]) {
            revert InsufficientStakingSupport();
        }

        // Store the current owner in `_previousOwner` variable which is returned as the current owner
        // by `getCurrentOwner()` function during an election cycle.
        _previousOwner = _owner;
        
        // Set end times for election cycle related periods
        _showdownPeriodEnd = block.timestamp + _SHOWDOWN_PERIOD;
        _submitOwnershipClaimPeriodEnd = _showdownPeriodEnd + _SUBMIT_OWNERSHIP_CLAIM_PERIOD;
        _cooldownPeriodEnd = _submitOwnershipClaimPeriodEnd + _COOLDOWN_PERIOD;

        // Log account that triggered the election cycle as well as the block timestamp
        emit ElectionCycleTriggered(msg.sender, block.timestamp);
    }
    
    function submitOwnershipClaim() external override {
        // Check that called within the ownership claim submission period
        if (!_isWithinSubmitOwnershipClaimPeriod()) {
            revert NotWithinSubmitOwnershipClaimPeriod() ;
        }

        // Check that `msg.sender` has strictly more stake than current leading candidate
        if (_candidateToStakedAmount[msg.sender] <= _candidateToStakedAmount[_owner]) {
                revert NotLeader();
        }        

        // Update `_owner` variable. Returned as owner inside `getCurrentOwner()`
        // after election cycle end.
        _owner = msg.sender;

        // Log candidate that submitted an ownership claim
        emit OwnershipClaimSubmitted(msg.sender);
    }

    function unstake(address _candidate, uint256 _amount) external override nonReentrant {
        // Check whether the 7 day minimum staking period has been respected
        uint _minStakingPeriodEnd =
            _voterToTimestampLastStakedForCandidate[msg.sender][_candidate] + _MIN_STAKING_PERIOD;
        if (block.timestamp < _minStakingPeriodEnd) {
            revert MinStakingPeriodNotExpired(block.timestamp, _minStakingPeriodEnd);
        }

        // Check that outside of ownership claim submission period
        if (_isWithinSubmitOwnershipClaimPeriod()) {
            revert WithinSubmitOwnershipClaimPeriod(block.timestamp, _submitOwnershipClaimPeriodEnd);
        }
 
        // Update staking balances. Both operations will revert on underflow as
        // Solidity version > 0.8.0 is used
        _voterToCandidateToStakedAmount[msg.sender][_candidate] -= _amount;
        _candidateToStakedAmount[_candidate] -= _amount;
        
        // Transfer DIVA token to `msg.sender`
        _DIVA_TOKEN.safeTransfer(msg.sender, _amount);

        // Log candidate and amount
        emit Unstaked(msg.sender, _candidate, _amount);
    }

    function getStakedAmount(
        address _voter,
        address _candidate
    ) 
        external
        view
        override returns (uint256)
    {
        return _voterToCandidateToStakedAmount[_voter][_candidate];
    }

    function getStakedAmount(address _candidate) external view override returns (uint256) {
        return _candidateToStakedAmount[_candidate];
    }

    function getCurrentOwner() public view override returns (address owner)
    {
        // During an election cycle, the current owner is stored inside the `_previousOwner` variable
        return _isWithinElectionCycle() ? _previousOwner : _owner;
    }

    function getTimestampLastStakedForCandidate(
        address _user,
        address _candidate
    ) external view override returns (uint256) {
        return _voterToTimestampLastStakedForCandidate[_user][_candidate];
    }

    function getShowdownPeriodEnd() external view override returns (uint256) {
        return _showdownPeriodEnd;
    }

    function getSubmitOwnershipClaimPeriodEnd() external view override returns (uint256) {
        return _submitOwnershipClaimPeriodEnd;
    }

    function getCooldownPeriodEnd() external view override returns (uint256) {
        return _cooldownPeriodEnd;
    }

    function getDIVAToken() external view override returns (address) {
        return address(_DIVA_TOKEN);
    }

    function getShowdownPeriod() external pure returns (uint256) {
        return _SHOWDOWN_PERIOD;
    }

    function getSubmitOwnershipClaimPeriod() external pure returns (uint256) {
        return _SUBMIT_OWNERSHIP_CLAIM_PERIOD;
    }

    function getCooldownPeriod() external pure returns (uint256) {
        return _COOLDOWN_PERIOD;
    }

    function getMinStakingPeriod() external pure returns (uint256) {
        return _MIN_STAKING_PERIOD;
    }

    function _isWithinSubmitOwnershipClaimPeriod() private view returns (bool) {
        return (block.timestamp > _showdownPeriodEnd &&  
            block.timestamp <= _submitOwnershipClaimPeriodEnd);
    }

    function _isWithinElectionCycle() private view returns (bool) {
        return (block.timestamp <= _submitOwnershipClaimPeriodEnd);
    }

    function _isWithinCooldownPeriod() private view returns (bool) {
        return (_submitOwnershipClaimPeriodEnd < block.timestamp &&
            block.timestamp <= _cooldownPeriodEnd);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import {IDIVAOwnershipShared} from "../interfaces/IDIVAOwnershipShared.sol";

interface IDIVAOwnershipMain is IDIVAOwnershipShared {
    // Thrown in constructor if zero address is provided for initial owner.
    error ZeroOwnerAddress();

    // Thrown in constructor if zero address is provided for the DIVA Token.
    error ZeroDIVATokenAddress();
    
    // Thrown in `stake` or `unstake` if called during the ownership claim
    // submission period
    error WithinSubmitOwnershipClaimPeriod(
        uint256 _timestampBlock,
        uint256 _submitOwnershipClaimPeriodEnd
    );

    // Thrown in `submitOwnershipClaim` if called outside of the ownership
    // claim submission period
    error NotWithinSubmitOwnershipClaimPeriod();

    // Thrown in `triggerElectionCycle` if called during an on-going election cycle
    error WithinElectionCycle(
        uint256 _timestampBlock,
        uint256 _submitOwnershipClaimPeriodEnd
    );

    // Thrown in `triggerElectionCycle` if called during the cooldown period (7 days
    // following the election cycle end)
    error WithinCooldownPeriod(
        uint256 _timestampBlock,
        uint256 _cooldownPeriodEnd
    );

    // Thrown in `unstake` if minimum staking period has not expired yet
    error MinStakingPeriodNotExpired(
        uint256 _timestampBlock,
        uint256 _minStakingPeriodEnd
    );

    // Thrown in `triggerElectionCycle` if `msg.sender` has not strictly more stake
    // than the current owner
    error InsufficientStakingSupport();

    // Thrown in `submitOwnershipClaim` if another candidate has more stake or
    // was already triggered by another candidate that has the same stake
    error NotLeader();

    /**
     * @notice Emitted when a user stakes for a candidate.
     * @param by The address of the user that staked.
     * @param candidate The address of the candidate that was staked for.
     * @param amount The voting token amount staked.
     */
    event Staked(address indexed by, address indexed candidate, uint256 amount);

    /**
     * @notice Emitted when a user reduces his stake for a candidate.
     * @param by The address of the user that unstaked.
     * @param candidate The address of the candidate that stake was reduced for.
     * @param amount The voting token amount unstaked.
     */
    event Unstaked(address indexed by, address indexed candidate, uint256 amount);

    /**
     * @notice Emitted when a candidate triggers the election cycle.
     * @param candidate The address that triggered the election cycle.
     * @param startTime Start time of the election cycle.
     */
    event ElectionCycleTriggered(address indexed candidate, uint256 startTime);

    /**
     * @notice Emitted when a candidate submits an ownership claim.
     * @param candidate The address of the candidate that submitted the
     * ownership claim.
     */
    event OwnershipClaimSubmitted(address indexed candidate);

    /**
     * @notice Function to stake voting tokens for a contract owner candidate. Requires
     * prior approval from `msg.sender` to transfer voting token.
     * @dev To protect against flash loans triggering voting rounds,
     * a minimum staking period of 7 days has been implemented. Staking is
     * disabled during ownership claim submission periods.
     * @param _candidate Address of contract owner candidate to stake fore.
     * @param _amount Incremental boting token amount to stake.
     */
    function stake(address _candidate, uint256 _amount) external;

    /**
     * @notice Function to reduce the stake for a contract owner candidate.
     * @param _candidate Address of candidate to reduce stake for.
     * @param _amount Staking amount to reduce.
     */
    function unstake(address _candidate, uint256 _amount) external;

    /**
     * @notice Function to trigger an election cycle. Can be triggered by anyone
     * that has strictly more stake than the current contract owner.
     */
    function triggerElectionCycle() external;

    /**
     * @notice Function for candidates to submit their ownership claim.
     * Reverts if `msg.sender`'s stake is smaller than the current leading candidate's one.
     * Note that in the event that the existing contract owner maintains the majority,
     * it is not necessary to trigger this function as they are set as the leading
     * candidate when `triggerElectionCycle` is triggered.
     */
    function submitOwnershipClaim() external;

    /**
     * @notice Function to return the amount staked by a given `_voter` for a given `_candidate`.
     * @param _voter Voter address.
     * @param _candidate Candidate address.
     * @return Staked amount for `_candidate` by `_voter`.
     */
    function getStakedAmount(address _voter, address _candidate)
        external
        view
        returns (uint256);

    /**
     * @notice Function to return the amount staked for a given `_candidate`.
     * @param _candidate Candidate address.
     * @return Staked amount for `_candidate`.
     */
    function getStakedAmount(address _candidate)
        external
        view
        returns (uint256);

    /**
     * @notice Function to get the timestamp of the last stake operation for a
     * given `_user` and `candidate`.
     * @return Timestamp in seconds since epoch.
     */
    function getTimestampLastStakedForCandidate(
        address _user,
        address _candidate
    )
        external
        view
        returns (uint256);

    /**
     * @notice Function to return the showdown period end.
     * @return Timestamp in seconds since epoch.
     */
    function getShowdownPeriodEnd() external view returns (uint256);

    /**
     * @notice Function to return the ownership claim submission period end.
     * @return Timestamp in seconds since epoch.
     */
    function getSubmitOwnershipClaimPeriodEnd() external view returns (uint256);

    /**
     * @notice Function to return the cooldown period end.
     * @return Timestamp in seconds since epoch.
     */
    function getCooldownPeriodEnd() external view returns (uint256);

    /**
     * @notice Function to return the DIVA token address that is used for voting.
     * @return The address of the DIVA token.
     */
    function getDIVAToken() external view returns (address);

    /**
     * @notice Function to return the showdown period length in seconds (30 days).
     * @return Period length in seconds.
     */
    function getShowdownPeriod() external pure returns (uint256);

    /**
     * @notice Function to return the ownership claim submission period length
     * in seconds (7 days).
     * @return Period length in seconds.
     */
    function getSubmitOwnershipClaimPeriod() external pure returns (uint256);

    /**
     * @notice Function to return the cooldown period length in seconds (7 days)
     * during which no new election cycle can be triggered following the end of an
     * election cycle.
     * @return Period length in seconds.
     */
    function getCooldownPeriod() external pure returns (uint256);

    /**
     * @notice Function to return the minimum staking period (7 days).
     * @return Period length in seconds.
     */
    function getMinStakingPeriod() external pure returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

interface IDIVAOwnershipShared {
    /**
     * @notice Function to return the current DIVA Protocol owner address.
     * @return Current owner address. On main chain, equal to the existing owner
     * during an on-going election cycle and equal to the new owner afterwards. On secondary
     * chain, equal to the address reported via Tellor oracle.
     */
    function getCurrentOwner() external view returns (address);
}