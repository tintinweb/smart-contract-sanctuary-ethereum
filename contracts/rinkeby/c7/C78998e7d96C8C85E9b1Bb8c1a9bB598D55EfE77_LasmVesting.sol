//SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

/*
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

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol

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
     * by making the `nonReentrant` function external, and make it call a
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an FTM balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

contract LasmVesting is ReentrancyGuard, Ownable {
    // Allocation distribution of the total supply.
    uint256 private constant E18                         = 10 ** 18;

    uint256 private constant LOCKED_ALLOCATION           = 160_000_000 * E18;
    uint256 private constant PUBLIC_SALE_ALLOCATION      =  80_000_000 * E18;
    uint256 private constant TEAM_ALLOCATION_1           = 110_000_000 * E18;
    uint256 private constant TEAM_ALLOCATION_2           =  10_000_000 * E18;
    uint256 private constant PARTNERS_ALLOCATION         =  40_000_000 * E18;
    uint256 private constant MARKETING_ALLOCATION        =  40_000_000 * E18;
    uint256 private constant DEVELOPMENT_ALLOCATION      =  80_000_000 * E18;
    uint256 private constant STAKING_ALLOCATION          = 240_000_000 * E18;
    uint256 private constant AIRDROP_ALLOCATION          =  40_000_000 * E18;

    // vesting wallets
    address private constant lockedWallet            = address(0x2C4C168A2fE4CaB8E32d1B2A119d4Aa8BdA377e7);
    address private constant managerWallet           = address(0x2FA55Dbd664e801f43503E056A011aD3fE18bE6a);
    address private constant teamWallet              = address(0x2FA55Dbd664e801f43503E056A011aD3fE18bE6a);
    address private constant partnersWallet          = address(0x3d08E83e16Fe8B5EEb85EBF7fc6343Af26e00705);
    address private constant marketingWallet         = address(0x2FA55Dbd664e801f43503E056A011aD3fE18bE6a);
    address private constant developmentWallet       = address(0x2FA55Dbd664e801f43503E056A011aD3fE18bE6a);
    address private constant stakingRewardsWallet    = address(0x3d08E83e16Fe8B5EEb85EBF7fc6343Af26e00705);
    address private constant airdropWallet           = address(0x91A68719a38B229891AAa4C964aC7B6a8c4E7C4f);

    uint256 private constant VESTING_END_AT = 4 * 365 days;  // 48 months

    address public vestingToken;   // ERC20 token that get vested.

    event TokenSet(address vestingToken);
    event Claimed(address indexed beneficiary, uint256 amount);

    struct Schedule {
        // Name of the template
        string templateName;

        // Tokens that were already claimed
        uint256 claimedTokens;

        // Start time of the schedule
        uint256 startTime;

        // Total amount of tokens
        uint256 allocation;

        // Schedule duration (How long the schedule will last)
        uint256 duration;

        // Cliff of the schedule.
        uint256 cliff;

        // Linear period of the schedule.
        uint256 linear;

        // Last time of Claimed
        uint256 lastClaimTime;
    }

    struct ClaimedEvent {
        // Index of the schedule list
        uint8 scheduleIndex;

        // Tokens that were only unlocked in this event
        uint256 claimedTokens;

        // Tokens that were already unlocked
        uint256 unlockedTokens;

        // Tokens that are locked yet
        uint256 lockedTokens;

        // Time of the current event
        uint256 eventTime;
    }

    Schedule[] public schedules;
    ClaimedEvent[] public scheduleEvents;

    mapping (address => uint8[]) public schedulesByOwner;
    mapping (string => uint8) public schedulesByName;
    mapping (string => address) public beneficiary;

    mapping (address => uint8[]) public eventsByScheduleBeneficiary;
    mapping (string => uint8[]) public eventsByScheduleName;

    constructor() {
    }

    /**
     * @dev Allow owner to set the token address that get vested.
     * @param tokenAddress Address of the BEP-20 token.
     */
    function setToken(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(0), "Vesting: ZERO_ADDRESS_NOT_ALLOWED");
        require(vestingToken == address(0), "Vesting: ALREADY_SET");

        vestingToken = tokenAddress;

        emit TokenSet(tokenAddress);
    }

    /**
     * @dev Allow owner to initiate the vesting schedule
     */
    function initVestingSchedule() public onlyOwner {
        // For Locked allocation
        _createSchedule(lockedWallet, Schedule({
            templateName         :  "Locked",
            claimedTokens        :  uint256(0),
            startTime            :  block.timestamp,
            allocation           :  LOCKED_ALLOCATION,
            duration             :  93312000,     // 36 Months (36 * 30 * 24 * 60 * 60)
            cliff                :  62208000,     // 24 Months (24 * 30 * 24 * 60 * 60)
            linear               :  31104000,     // 12 Months (12 * 30 * 24 * 60 * 60)
            lastClaimTime        :  0
        }));

        // For Public sale allocation
        _createSchedule(managerWallet, Schedule({
            templateName         :  "PublicSale",
            claimedTokens        :  uint256(0),
            startTime            :  block.timestamp,
            allocation           :  PUBLIC_SALE_ALLOCATION,
            duration             :  18144000,     // 7 Months (7 * 30 * 24 * 60 * 60)
            cliff                :   7776000,     // 3 Months (4 * 30 * 24 * 60 * 60)
            linear               :  10368000,     // 4 Months (4 * 30 * 24 * 60 * 60)
            lastClaimTime        :  0
        }));

        // For Team allocation_1
        _createSchedule(teamWallet, Schedule({
            templateName         :  "Team_1",
            claimedTokens        :  uint256(0),
            startTime            :  block.timestamp,
            allocation           :  TEAM_ALLOCATION_1,
            duration             :  93312000,    // 36 Months (36 * 30 * 24 * 60 * 60)
            cliff                :   7776000,    //  3 Months ( 3 * 30 * 24 * 60 * 60)
            linear               :  85536000,    // 33 Months (33 * 30 * 24 * 60 * 60)
            lastClaimTime        :  0
        }));

        // For Team allocation_2
        _createSchedule(teamWallet, Schedule({
            templateName         :  "Team_2",
            claimedTokens        :  uint256(0),
            startTime            :  block.timestamp + 93312000,     // After 36 Months of closing the Team Allocation_1
            allocation           :  TEAM_ALLOCATION_2,
            duration             :  31104000,    // 12 Months (12 * 30 * 24 * 60 * 60)
            cliff                :  0,
            linear               :  31104000,    // 12 Months (12 * 30 * 24 * 60 * 60)
            lastClaimTime        :  0
        }));

        // For Partners & Advisors allocation
        _createSchedule(partnersWallet, Schedule({
            templateName         :  "Partners",
            claimedTokens        :  uint256(0),
            startTime            :  block.timestamp,
            allocation           :  PARTNERS_ALLOCATION,
            duration             :  62208000,     // 24 Months (24 * 30 * 24 * 60 * 60)
            cliff                :  31104000,     // 12 Months (12 * 30 * 24 * 60 * 60)
            linear               :  31104000,     // 12 Months (12 * 30 * 24 * 60 * 60)
            lastClaimTime        :  0
        }));

        // For Marketing allocation
        _createSchedule(marketingWallet, Schedule({
            templateName         :  "Marketing",
            claimedTokens        :  uint256(0),
            startTime            :  block.timestamp,
            allocation           :  MARKETING_ALLOCATION,
            duration             :  0,            // 0 Months
            cliff                :  0,            // 0 Months
            linear               :  0,            // 0 Months
            lastClaimTime        :  0
        }));

        // For Development allocation
        _createSchedule(developmentWallet, Schedule({
            templateName         :  "Development",
            claimedTokens        :  uint256(0),
            startTime            :  block.timestamp,
            allocation           :  DEVELOPMENT_ALLOCATION,
            duration             :  0,            // 0 Month
            cliff                :  0,            // 0 Month
            linear               :  0,            // 0 Month
            lastClaimTime        :  0
        }));

        // For P2E & Staking rewards allocation
        _createSchedule(stakingRewardsWallet, Schedule({
            templateName         :  "Staking",
            claimedTokens        :  uint256(0),
            startTime            :  block.timestamp,
            allocation           :  STAKING_ALLOCATION,
            duration             :  85536000,     // 33 Months (33 * 30 * 24 * 60 * 60)
            cliff                :   7776000,     //  3 Months ( 3 * 30 * 24 * 60 * 60)
            linear               :  77760000,     // 30 Months (30 * 30 * 24 * 60 * 60)
            lastClaimTime        :  0
        }));

        // For Airdrop allocation
        _createSchedule(airdropWallet, Schedule({
            templateName         :  "Airdrop",
            claimedTokens        :  uint256(0),
            startTime            :  block.timestamp,
            allocation           :  AIRDROP_ALLOCATION,
            duration             :  0,            // 0 Month
            cliff                :  0,            // 0 Month
            linear               :  0,            // 0 Month
            lastClaimTime        :  0
        }));
    }

    function _createSchedule(address _beneficiary, Schedule memory _schedule) internal {
        schedules.push(_schedule);

        uint8 index = uint8(schedules.length) - 1;

        schedulesByOwner[_beneficiary].push(index);
        schedulesByName[_schedule.templateName] = index;
        beneficiary[_schedule.templateName] = _beneficiary;
    }

    /**
     * @dev Check the amount of claimable token of the beneficiary.
     */
    function pendingTokensByScheduleBeneficiary(address _account) public view returns (uint256) {
        uint8[] memory _indexs = schedulesByOwner[_account];
        require(_indexs.length != uint256(0), "Vesting: NOT_AUTORIZE");

        uint256 amount = 0;
        for (uint8 i = 0; i < _indexs.length; i++) {
            string memory _templateName = schedules[_indexs[i]].templateName;
            amount += pendingTokensByScheduleName(_templateName);
        }

        return amount;
    }

    /**
     * @dev Check the amount of claimable token of the schedule.
     */
    function pendingTokensByScheduleName(string memory _templateName) public view returns (uint256) {
        uint8 index = schedulesByName[_templateName];
        require(index >= 0 && index < schedules.length, "Vesting: NOT_SCHEDULE");

        Schedule memory schedule = schedules[index];
        uint256 vestedAmount = 0;
        if (
            schedule.startTime + schedule.cliff >= block.timestamp 
            || schedule.claimedTokens == schedule.allocation) {
            return 0;
        }

        if (schedule.duration == 0 && schedule.startTime <= block.timestamp) {
            vestedAmount = schedule.allocation;
        }
        else if (schedule.startTime + schedule.duration <= block.timestamp) {
            vestedAmount = schedule.allocation;
        } 
        else {
            if (block.timestamp > schedule.startTime + schedule.cliff && schedule.linear > 0) {
                uint256 timePeriod            = block.timestamp - schedule.startTime - schedule.cliff;
                uint256 unitPeriodAllocation  = schedule.allocation / schedule.linear;

                vestedAmount = timePeriod * unitPeriodAllocation;
            }
            else 
                return 0;
        }

        return vestedAmount - schedule.claimedTokens;
    }

    /**
     * @dev Allow the respective addresses claim the vested tokens.
     */
    function claimByScheduleBeneficiary() external nonReentrant {
        require(vestingToken != address(0), "Vesting: VESTINGTOKEN_NO__SET");

        uint8[] memory _indexs = schedulesByOwner[msg.sender];
        require(_indexs.length != uint256(0), "Vesting: NOT_AUTORIZE");

        uint256 amount = 0;
        uint8 index;
        for (uint8 i = 0; i < _indexs.length; i++) {
            index = _indexs[i];

            string memory _templateName = schedules[index].templateName;
            uint256 claimAmount = pendingTokensByScheduleName(_templateName);

            if (claimAmount == 0)
                continue;

            schedules[index].claimedTokens += claimAmount;
            schedules[index].lastClaimTime = block.timestamp;
            amount += claimAmount;

            registerEvent(msg.sender, index, claimAmount);
        }

        require(amount > uint256(0), "Vesting: NO_VESTED_TOKENS");

        SafeERC20.safeTransfer(IERC20(vestingToken), msg.sender, amount);

        emit Claimed(msg.sender, amount);
    }

    /**
     * @dev Allow the respective addresses claim the vested tokens of the schedule.
     */
    function claimByScheduleName(string memory _templateName) external nonReentrant {
        require(vestingToken != address(0), "Vesting: VESTINGTOKEN_NO__SET");

        uint8 index = schedulesByName[_templateName];
        require(index >= 0 && index < schedules.length, "Vesting: NOT_SCHEDULE");
        require(beneficiary[_templateName] == msg.sender, "Vesting: NOT_AUTORIZE");

        uint256 claimAmount = pendingTokensByScheduleName(_templateName);

        require(claimAmount > uint256(0), "Vesting: NO_VESTED_TOKENS");

        schedules[index].claimedTokens += claimAmount;
        schedules[index].lastClaimTime = block.timestamp;

        SafeERC20.safeTransfer(IERC20(vestingToken), msg.sender, claimAmount);

        registerEvent(msg.sender, index, claimAmount);

        emit Claimed(beneficiary[_templateName], claimAmount);
    }

    function registerEvent(address _account, uint8 _scheduleIndex, uint256 _claimedTokens) internal {
        Schedule memory schedule = schedules[_scheduleIndex];

        scheduleEvents.push(ClaimedEvent({
            scheduleIndex: _scheduleIndex,
            claimedTokens: _claimedTokens,
            unlockedTokens: schedule.claimedTokens,
            lockedTokens: schedule.allocation - schedule.claimedTokens,
            eventTime: schedule.lastClaimTime
        }));

        eventsByScheduleBeneficiary[_account].push(uint8(scheduleEvents.length) - 1);
        eventsByScheduleName[schedule.templateName].push(uint8(scheduleEvents.length) - 1);
    }

    /**
     * @dev Allow owner to withdraw the token from the contract.
     * @param tokenAddress Address of the BEP-20 token.
     * @param amount       Amount of token that get skimmed out of the contract.
     * @param destination  Whom token amount get transferred to.
     */
    function withdraw(address tokenAddress, uint256 amount, address destination) external onlyOwner {
        require(vestingToken != address(0), "Vesting: VESTINGTOKEN_NO__SET");
        require(block.timestamp > VESTING_END_AT, "Vesting: NOT_ALLOWED");
        require(destination != address(0),        "Vesting: ZERO_ADDRESS_NOT_ALLOWED");
        require(amount <= IERC20(tokenAddress).balanceOf(address(this)), "Insufficient balance");

        SafeERC20.safeTransfer(IERC20(tokenAddress), destination, amount);
    }
}