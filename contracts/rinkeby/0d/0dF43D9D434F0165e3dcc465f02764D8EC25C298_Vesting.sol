// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Vesting is Ownable, Pausable {
    using SafeERC20 for IERC20;
    using Address for address;
    using Counters for Counters.Counter;

    enum SchemeType {
        investor,
        member
    }

    enum DurationType {
        HOUR,
        DAY
    }

    uint256 constant day = 86400;
    uint256 constant month = 2592000;
    uint256 constant dayForTest = 120;
    uint256 constant monthForTest = 120 * 30;

    struct Scheme {
        string name;
        uint256 cliffTime;
        uint256 vestingDuration;
        uint256 period;
        bool isActive;
        SchemeType schemeType;
    }

    struct Subscription {
        uint256 schemeId;
        address wallet;
        uint256 startTime;
        uint256 startTimeVesting;
        uint256 endTimeVesting;
        uint256 vestedAmount;
        uint256 nextTimeClaim;
        uint256 totalAmount;
        mapping(uint256 => uint256) depositAmountByRound;
    }

    IERC20 public erc20Token;
    Counters.Counter private schemeCount;
    Counters.Counter private subscriptionCount;
    Counters.Counter private roundCount;
    //@dev epoch time and in seconds
    uint256 public tge;
    uint256 public contractDeploymentTime;

    mapping(uint256 => Scheme) private _schemes;
    mapping(uint256 => Subscription) private _subscriptions;
    mapping(address => bool) private _operators;

    constructor(address gameStateToken) {
        erc20Token = IERC20(gameStateToken);
        setOperator(msg.sender, true);
        contractDeploymentTime = block.timestamp;
        tge = (block.timestamp / day) * day;
    }

    event SchemeCreated(
        uint256 schemeId,
        string name,
        uint256 cliffTime,
        uint256 vestingDuration,
        uint256 period,
        SchemeType SchemeType,
        bool isActive
    );

    event SubscriptionAdded(
        uint256 subscriptionID,
        uint256 schemeId,
        address wallet,
        uint256 startTime,
        uint256 startTimeVesting,
        uint256 endTimeVesting,
        uint256 totalAmount
    );

    event Deposit(
        uint256 subscriptionID,
        uint256 amount,
        uint256 timeDeposit,
        uint256 round
    );

    event ClaimSucceeded(
        address wallet,
        uint256 claimAvaliable,
        uint256 vestedAmount,
        uint256 totalAmount,
        uint256 timeClaim,
        uint256 nextTimeClaim
    );
    event VestingContractConfigured(address erc20Contract);
    event OperatorAdded(address operator, bool isOperator);
    event TokenGenerationEventConfigured(uint256 time);

    modifier onlyOperator() {
        _onlyOperator();
        _;
    }

    modifier schemeExist(uint256 schemeId) {
        _schemeExist(schemeId);
        _;
    }

    modifier subcriptionExits(uint256 subscriptionId) {
        _subscription(subscriptionId);
        _;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setERC20Token(address erc20Contract) external onlyOwner {
        require(
            erc20Contract.isContract() && erc20Contract != address(0),
            "ERC20 address must be a smart contract"
        );
        erc20Token = IERC20(erc20Contract);
        emit VestingContractConfigured(erc20Contract);
    }

    function setTGE(uint256 time) external onlyOwner {
        require(tge == 0, "Can only be initialized once");
        require(time > 0, "Time must be greater than zero");
        tge = time;
        emit TokenGenerationEventConfigured(tge);
    }

    function addScheme(
        string memory name,
        uint256 cliffTime,
        uint256 vestingDuration,
        uint256 period,
        SchemeType schemeType
    ) external onlyOperator {
        require(bytes(name).length > 0, "Name must not be empty");

        require(
            period > 0 && period < vestingDuration,
            "Period must be greater than zero and less than duration"
        );
        require(
            vestingDuration % period == 0,
            "Duration must be divisible by period"
        );
        require(
            cliffTime >= (getSecondsOfDuration(DurationType.DAY, 90)),
            "invalid cliff time"
        );
        require(
            vestingDuration >= (getSecondsOfDuration(DurationType.DAY, 720)),
            "Duration must be greater than zero"
        );

        schemeCount.increment();
        uint256 schemeId = schemeCount.current();
        Scheme storage scheme = _schemes[schemeId];

        scheme.name = name;
        scheme.cliffTime = cliffTime;
        scheme.vestingDuration = vestingDuration;
        scheme.period = period;
        scheme.isActive = true;
        scheme.schemeType = schemeType;

        emit SchemeCreated(
            schemeId,
            scheme.name,
            scheme.cliffTime,
            scheme.vestingDuration,
            scheme.period,
            scheme.schemeType,
            scheme.isActive
        );
    }

    function addSubscription(
        uint256 schemeId,
        address wallet,
        uint256 startTime,
        uint256 totalAmount
    ) external whenNotPaused onlyOperator schemeExist(schemeId) {
        Scheme memory scheme = _schemes[schemeId];
        require(_schemes[schemeId].isActive == true, "Scheme is not active");
        require(wallet != address(0), "invalid address");
        require(startTime >= tge, "Start timestamp must be greater than TGE");
        subscriptionCount.increment();

        uint256 subscriptionID = subscriptionCount.current();
        Subscription storage subscription = _subscriptions[subscriptionID];

        subscription.schemeId = schemeId;
        subscription.startTime = startTime;

        if (totalAmount > 0) {
            require(
                scheme.schemeType == SchemeType.investor,
                "totalAmount only for investor"
            );
            // subscription.startTimeVesting =
            //     ((contractDeploymentTime + scheme.cliffTime) / day) *
            //     day;
            //! for test
            subscription.startTimeVesting = (contractDeploymentTime +
                scheme.cliffTime);
            erc20Token.transferFrom(msg.sender, address(this), totalAmount);
            subscription.totalAmount = totalAmount;
        } else {
            require(
                scheme.schemeType == SchemeType.member,
                "investor don't have totalAmount"
            );
            // subscription.startTimeVesting =
            //     ((startTime + scheme.cliffTime) / day) *
            //     day;
            //! for test
            subscription.startTimeVesting = (startTime + scheme.cliffTime);
        }

        subscription.endTimeVesting =
            subscription.startTimeVesting +
            scheme.vestingDuration;
        subscription.wallet = wallet;
        subscription.vestedAmount = 0;
        subscription.nextTimeClaim = subscription.startTimeVesting;

        emit SubscriptionAdded(
            subscriptionID,
            subscription.schemeId,
            subscription.wallet,
            subscription.startTime,
            subscription.startTimeVesting,
            subscription.endTimeVesting,
            subscription.totalAmount
        );
    }

    function deposit(
        uint256 subscriptionID,
        uint256 round,
        uint256 amount
    ) external whenNotPaused onlyOperator subcriptionExits(subscriptionID) {
        Subscription storage subscription = _subscriptions[subscriptionID];
        Scheme memory scheme = _schemes[subscription.schemeId];

        uint256 totalRound = scheme.vestingDuration / monthForTest;
        require(
            scheme.schemeType == SchemeType.member,
            "deposit only for member"
        );
        require(round <= totalRound, "invalid round");

        require(
            subscription.depositAmountByRound[round] == 0,
            "this round was deposited"
        );

        subscription.depositAmountByRound[round] = amount;
        subscription.totalAmount += amount;
        erc20Token.transfer(address(this), amount);
        emit Deposit(subscriptionID, amount, block.timestamp, round);
    }

    event getValues(uint256 claimAvalible, uint256 currentTotalDays);

    function claim(uint256 subscriptionID) external whenNotPaused {
        Subscription storage subscription = _subscriptions[subscriptionID];
        Scheme memory scheme = _schemes[subscription.schemeId];

        require(subscriptionID > 0, "Requiring at least one subscription ID");
        require(
            msg.sender == subscription.wallet,
            "you're not owner of subscription"
        );

        require(
            block.timestamp > subscription.nextTimeClaim,
            "It's not time to claim"
        );

        if (scheme.schemeType == SchemeType.investor) {
            uint256 currentTotalDays = calculateDaySPassed(
                subscription.endTimeVesting,
                block.timestamp
            );
            uint256 claimAvalible = calculateClaimAvalible(
                subscription.totalAmount,
                currentTotalDays
            );

            erc20Token.transfer(msg.sender, claimAvalible);
            subscription.vestedAmount += claimAvalible;
            // subscription.nextTimeClaim += day;
            //! for test
            subscription.nextTimeClaim += dayForTest;
            subscription.totalAmount -= claimAvalible;
            emit ClaimSucceeded(
                msg.sender,
                claimAvalible,
                subscription.vestedAmount,
                subscription.totalAmount,
                block.timestamp,
                subscription.nextTimeClaim
            );
        } else {
            uint256 currentTotalDays = calculateDaySPassed(
                subscription.endTimeVesting,
                block.timestamp
            );

            uint256 claimAvailable = calculateClaimAvalible(
                subscription.totalAmount,
                currentTotalDays
            );

            erc20Token.transfer(msg.sender, claimAvailable);
            subscription.vestedAmount += claimAvailable;
            subscription.totalAmount -= claimAvailable;
            // subscription.nextTimeClaim += day;
            //! for test
            subscription.nextTimeClaim += dayForTest;
            emit ClaimSucceeded(
                msg.sender,
                claimAvailable,
                subscription.vestedAmount,
                subscription.totalAmount,
                block.timestamp,
                subscription.nextTimeClaim
            );
        }
    }

    function isOperator(address operator) external view returns (bool) {
        return _operators[operator];
    }

    function getScheme(uint256 schemeId)
        external
        view
        returns (
            string memory name,
            uint256 cliffTime,
            uint256 vestingDuration,
            uint256 period,
            bool isActive,
            SchemeType schemeType
        )
    {
        Scheme memory scheme = _schemes[schemeId];
        name = scheme.name;
        cliffTime = scheme.cliffTime;
        vestingDuration = scheme.vestingDuration;
        period = scheme.period;
        isActive = scheme.isActive;
        schemeType = scheme.schemeType;
    }

    function getSubscription(uint256 subscriptionID, uint256 round)
        external
        view
        returns (
            uint256 schemeId,
            uint256 startTimeVesting,
            uint256 endTimeVesting,
            address wallet,
            uint256 vestedAmount,
            uint256 totalAmount,
            uint256 depositAmount,
            uint256 nextTimeClaim
        )
    {
        Subscription storage subScription = _subscriptions[subscriptionID];
        schemeId = subScription.schemeId;
        startTimeVesting = subScription.startTimeVesting;
        endTimeVesting = subScription.endTimeVesting;
        wallet = subScription.wallet;
        vestedAmount = subScription.vestedAmount;
        totalAmount = subScription.totalAmount;
        depositAmount = subScription.depositAmountByRound[round];
        nextTimeClaim = subScription.nextTimeClaim;
    }

    function calculateClaimAvalible(uint256 totalAmount, uint256 totalDays)
        internal
        pure
        returns (uint256 claimAvalible)
    {
        claimAvalible = (totalAmount / totalDays);
    }

    function calculateDaySPassed(uint256 endTime, uint256 nowTime)
        internal
        pure
        returns (uint256 currentTotalDays)
    {
        // currentTotalDays = (endTime - nowTime) / day + 1;
        //! for test
        currentTotalDays = (endTime - nowTime) / dayForTest + 1;
    }

    function setOperator(address operator, bool isOperator_) public onlyOwner {
        _operators[operator] = isOperator_;
        emit OperatorAdded(operator, isOperator_);
    }

    function _onlyOperator() private view {
        require(_operators[_msgSender()], "Vesting: Sender is not operator");
    }

    function _subscription(uint256 subscriptionId) private view {
        require(
            subscriptionId >= 1 &&
                subscriptionId <= subscriptionCount.current(),
            "Subscription is not exits"
        );
    }

    function _schemeExist(uint256 schemeId) private view {
        require(
            schemeId >= 1 && schemeId <= schemeCount.current(),
            "Scheme is not exists"
        );
    }

    function getSecondsOfDuration(DurationType durationType, uint256 duration)
        internal
        pure
        returns (uint256 inSeconds)
    {
        if (durationType == DurationType.HOUR) {
            // inSeconds = duration * 3600;
            inSeconds = duration * 5; // For testing 1 hour = 5 seconds
        } else if (durationType == DurationType.DAY) {
            // inSeconds = duration * 24 * 3600;
            inSeconds = duration * 120; // For testing 1 day = 120 seconds
        }
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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