/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/Context.sol

pragma solidity ^0.8.4;
pragma abicoder v2;

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

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

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
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts/utils/Address.sol

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
        assembly {
            size := extcodesize(account)
        }
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
        (bool success, ) = recipient.call{value: amount}("");
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol

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
        // solhint-disable-next-line max-line-length
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
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/interfaces/IJackpotApeRandomGenerator.sol

interface IJackpotApeRandomGenerator {
    /**
     * Requests randomness from a user-provided seed
     */
    function getRandomNumber() external;

    /**
     * View latest lotteryId numbers
     */
    function viewLatestLotteryId() external view returns (uint256);

    /**
     * Views random result
     */
    function viewRandomResult() external view returns (uint256);
}

// File: contracts/interfaces/IJackpotApeLottery.sol

interface IJackpotApeLottery {
    /**
     * @notice Get free tickets for the current lottery
     * @param _lotteryId: lotteryId
     * @param _ticketNumbers: array of ticket numbers between 1,000,000,000,000 and 1,494,949,494,949
     * @dev Callable by users
     */
    function getFreeTickets(uint256 _lotteryId, uint256[] calldata _ticketNumbers) external;

    /**
     * @notice Buy tickets for the current lottery
     * @param _lotteryId: lotteryId
     * @param _ticketNumbers: array of ticket numbers between 1,000,000,000,000 and 1,494,949,494,949
     * @dev Callable by users
     */
    function buyTickets(uint256 _lotteryId, uint256[] calldata _ticketNumbers) external payable;

    /**
     * @notice Claim a set of winning tickets for a lottery
     * @param _lotteryId: lottery id
     * @param _ticketIds: array of ticket ids
     * @dev Callable by users only, not contract!
     */
    function claimTickets(
        uint256 _lotteryId,
        uint256[] calldata _ticketIds
    ) external;

    /**
     * @notice Close lottery
     * @param _lotteryId: lottery id
     * @dev Callable by operator
     */
    function closeLottery(uint256 _lotteryId) external;

    /**
     * @notice Draw the final number, calculate reward in TICKET per group, and make lottery claimable
     * @param _lotteryId: lottery id
     * @dev Callable by operator
     */
    function drawFinalNumberAndMakeLotteryClaimable(uint256 _lotteryId) external;

    /**
     * @notice Start the lottery
     * @dev Callable by operator
     * @param _endTime: endTime of the lottery
     * @param _priceTicket: price of a ticket in Ticket Token
     * @param _discountDivisor: the divisor to calculate the discount magnitude for bulks
     * @param _rewardsBreakdown: breakdown of rewards per bracket (must sum to 10,000)
     * @param _rewardAmount: reward amount to winners
     */
    function startLottery(
        uint256 _endTime,
        uint256 _priceTicket,
        uint256 _discountDivisor,
        uint256[6] calldata _rewardsBreakdown,
        uint256 _rewardAmount
    ) external;

    /**
     * @notice View current lottery id
     */
    function viewCurrentLotteryId() external returns (uint256);
}

// File: contracts/JackpotApeLottery.sol

/** @title JackpotApe Lottery.
 * @notice It is a contract for a lottery system using
 * randomness provided externally.
 */
contract JackpotApeLottery is ReentrancyGuard, IJackpotApeLottery, Ownable {
    using SafeERC20 for IERC20;

    address public operatorAddress;
    address public treasuryAddress;

    uint256 public currentLotteryId;
    uint256 public currentTicketId;

    uint256 public maxNumberTicketsPerBuyOrClaim = 100;

    uint256 public maxPriceTicket = 50 ether;
    uint256 public minPriceTicket = 0.0005 ether;

    uint256 public pendingInjectionNextLottery;

    // uint256 public constant MIN_DISCOUNT_DIVISOR = 300;
    uint256 public constant MIN_DISCOUNT_DIVISOR = 0;
    // uint256 public constant MIN_LENGTH_LOTTERY = 4 hours - 5 minutes; // 4 hours
    uint256 public constant MIN_LENGTH_LOTTERY = 3 minutes; // 4 hours
    uint256 public constant MAX_LENGTH_LOTTERY = 4 days + 5 minutes; // 4 days
    uint256 public constant MAX_TREASURY_FEE = 3000; // 30%

    IJackpotApeRandomGenerator public randomGenerator;

    enum Status {
        Pending,
        Open,
        Close,
        Claimable
    }

    struct Lottery {
        Status status;
        uint256 startTime;
        uint256 endTime;
        uint256 priceTicket;
        uint256 discountDivisor;
        uint256[6] rewardsBreakdown; // 0: 1 matching number // 5: 6 matching numbers
        uint256[6] ticketRewardPerBracket;
        uint256[6] countWinnersPerBracket;
        uint256 firstTicketId;
        uint256 firstTicketIdNextLottery;
        uint256 amountTotalReward;
        uint256[6] finalNumbers;
    }

    struct Ticket {
        uint256 number;
        address owner;
    }

    // Mapping are cheaper than arrays
    mapping(uint256 => Lottery) private _lotteries;
    mapping(uint256 => Ticket) private _tickets;

    IERC20 public freeTicketToken;
    uint256 public freeTicketTokenPrice;
    // free tickets amount to take free tickets for lottery
    // lotteryId => account => ticket amount
    mapping(uint256 => mapping(address => uint256)) _numberFreeTicketsPerLotteryId;

    uint256 public extraFreeTicketAmount = 1;
    address[] public extraFreeTicketTokens;
    mapping(address => uint256) public extraFreeTicketTokenPrice;

    bool private success_finalNumbers;
    mapping(uint256 => bool) private _checkDuplicated;

    // check lottery number exists in ticket of current lottery
    // lotteryId => ticketId => lotteryNumber => bool
    mapping(uint256 => mapping(uint256 => mapping(uint256 => bool))) private _existLotteryNumberInTicket;

    // Keep track of user ticket ids for a given lotteryId
    mapping(address => mapping(uint256 => uint256[])) private _userTicketIdsPerLotteryId;

    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operatorAddress, "Not operator");
        _;
    }

    event AdminTokenRecovery(address token, uint256 amount);
    event LotteryClose(uint256 indexed lotteryId, uint256 firstTicketIdNextLottery);
    event LotteryInjection(uint256 indexed lotteryId, uint256 injectedAmount);
    event LotteryOpen(
        uint256 indexed lotteryId,
        uint256 startTime,
        uint256 endTime,
        uint256 priceTicket,
        uint256 firstTicketId,
        uint256 injectedAmount
    );
    event LotteryNumberDrawn(uint256 indexed lotteryId, uint256 countWinningTickets);
    event NewOperatorAndTreasuryAndInjectorAddresses(address operator, address treasury);
    event NewRandomGenerator(address indexed randomGenerator);
    event FreeTicketsPurchase(address indexed buyer, uint256 indexed lotteryId, uint256 numberTickets);
    event TicketsPurchase(address indexed buyer, uint256 indexed lotteryId, uint256 numberTickets);
    event TicketsClaim(address indexed claimer, uint256 amount, uint256 indexed lotteryId, uint256 numberTickets);

    /**
     * @notice Constructor
     * @dev RandomNumberGenerator must be deployed prior to this contract
     * @param _randomGeneratorAddress: address of the RandomGenerator contract used to work with ChainLink VRF
     */
    constructor(address _randomGeneratorAddress) {
        randomGenerator = IJackpotApeRandomGenerator(_randomGeneratorAddress);

        operatorAddress = msg.sender;
        treasuryAddress = msg.sender;
    }

    /**
     * @notice Buy tickets for the current lottery
     * @param _lotteryId: lotteryId
     * @param _ticketNumbers: array of ticket numbers between 1,000,000 and 1,999,999
     * @dev Callable by users
     */
    function getFreeTickets(uint256 _lotteryId, uint256[] calldata _ticketNumbers)
        external
        override
        notContract
        nonReentrant
    {
        require(_ticketNumbers.length != 0, "No ticket specified");
        require(_ticketNumbers.length <= maxNumberTicketsPerBuyOrClaim, "Too many tickets");

        require(_lotteries[_lotteryId].status == Status.Open, "Lottery is not open");
        require(block.timestamp < _lotteries[_lotteryId].endTime, "Lottery is over");

        uint256 _freeTickets = calculateFreeTickets(msg.sender, _lotteryId);
        require(_freeTickets >= _ticketNumbers.length, "Insufficient free tickets");

        for (uint256 i = 0; i < _ticketNumbers.length; i++) {
            uint256 thisTicketNumber = _ticketNumbers[i];

            require((thisTicketNumber >= 1000000000000) && (thisTicketNumber <= 1494949494949), "Outside range");

            _userTicketIdsPerLotteryId[msg.sender][_lotteryId].push(currentTicketId);

            _tickets[currentTicketId] = Ticket({number: thisTicketNumber, owner: msg.sender});

            for(uint256 j = 0; j < 6; j++) {
                uint256 lotteryNumber = thisTicketNumber % 100;
                thisTicketNumber = thisTicketNumber / 100;
                require(lotteryNumber <= 49, "Wrong number");
                _existLotteryNumberInTicket[_lotteryId][currentTicketId][lotteryNumber] = true;
            }

            // Increase lottery ticket number
            currentTicketId++;
        }
        
        _numberFreeTicketsPerLotteryId[_lotteryId][msg.sender] = _numberFreeTicketsPerLotteryId[_lotteryId][msg.sender] + _ticketNumbers.length;

        emit FreeTicketsPurchase(msg.sender, _lotteryId, _ticketNumbers.length);
    }

    /**
     * @notice Buy tickets for the current lottery
     * @param _lotteryId: lotteryId
     * @param _ticketNumbers: array of ticket numbers between 1,000,000 and 1,999,999
     * @dev Callable by users
     */
    function buyTickets(uint256 _lotteryId, uint256[] calldata _ticketNumbers)
        external
        override
        payable
        notContract
        nonReentrant
    {
        require(_ticketNumbers.length > 0, "No ticket specified");
        require(_ticketNumbers.length <= maxNumberTicketsPerBuyOrClaim, "Too many tickets");

        require(_lotteries[_lotteryId].status == Status.Open, "Lottery is not open");
        require(block.timestamp < _lotteries[_lotteryId].endTime, "Lottery is over");

        uint256 _extraFreeTickets = calculateExtraFreeTickets(msg.sender);
        
        // Calculate number of TICKET to this contract
        uint256 amountTicketPrice;
        if (_ticketNumbers.length > _extraFreeTickets) {
            amountTicketPrice = _calculateTotalPriceForBulkTickets(
                _lotteries[_lotteryId].discountDivisor,
                _lotteries[_lotteryId].priceTicket,
                _ticketNumbers.length - _extraFreeTickets
            );
        }
        else {
            amountTicketPrice = _calculateTotalPriceForBulkTickets(
                _lotteries[_lotteryId].discountDivisor,
                _lotteries[_lotteryId].priceTicket,
                _ticketNumbers.length
            );
        }

        // Check the price
        require(msg.value >= amountTicketPrice, "Price is wrong");

        for (uint256 i = 0; i < _ticketNumbers.length; i++) {
            uint256 thisTicketNumber = _ticketNumbers[i];

            require((thisTicketNumber >= 1000000000000) && (thisTicketNumber <= 1494949494949), "Outside range");

            _userTicketIdsPerLotteryId[msg.sender][_lotteryId].push(currentTicketId);

            _tickets[currentTicketId] = Ticket({number: thisTicketNumber, owner: msg.sender});

            for(uint256 j = 0; j < 6; j++) {
                uint256 lotteryNumber = thisTicketNumber % 100;
                thisTicketNumber = thisTicketNumber / 100;
                require(lotteryNumber <= 49, "Wrong number");
                _existLotteryNumberInTicket[_lotteryId][currentTicketId][lotteryNumber] = true;
            }

            // Increase lottery ticket number
            currentTicketId++;
        }

        // Transfer ticket tokens to this contract
        (bool success, ) = treasuryAddress.call{value: amountTicketPrice}("");
        require(success, "Error to send ticket cost.");

        emit TicketsPurchase(msg.sender, _lotteryId, _ticketNumbers.length);
    }

    /**
     * @notice Claim a set of winning tickets for a lottery
     * @param _lotteryId: lottery id
     * @param _ticketIds: array of ticket ids
     * @dev Callable by users only, not contract!
     */
    function claimTickets(
        uint256 _lotteryId,
        uint256[] calldata _ticketIds
    ) external override notContract nonReentrant {
        require(_ticketIds.length != 0, "Length must be >0");
        require(_ticketIds.length <= maxNumberTicketsPerBuyOrClaim, "Too many tickets");
        require(_lotteries[_lotteryId].status == Status.Claimable, "Lottery not claimable");

        // Initializes the rewardInTicketTokenToTransfer
        uint256 rewardInTicketTokenToTransfer;

        for (uint256 i = 0; i < _ticketIds.length; i++) {
            uint256 thisTicketId = _ticketIds[i];

            require(_lotteries[_lotteryId].firstTicketIdNextLottery > thisTicketId, "TicketId too high");
            require(_lotteries[_lotteryId].firstTicketId <= thisTicketId, "TicketId too low");
            require(msg.sender == _tickets[thisTicketId].owner, "Not the owner");

            // Update the lottery ticket owner to 0x address
            _tickets[thisTicketId].owner = address(0);

            uint256 rewardForTicketId = _calculateRewardsForTicketId(_lotteryId, thisTicketId);

            // Check user is claiming the correct bracket
            require(rewardForTicketId != 0, "No prize for this bracket");

            // Increment the reward to transfer
            rewardInTicketTokenToTransfer += rewardForTicketId;
        }

        require(address(this).balance >= rewardInTicketTokenToTransfer, "Insufficient balance");

        // Transfer money to msg.sender
        (bool success, ) = msg.sender.call{value: rewardInTicketTokenToTransfer}("");
        require(success, "Error to claim reward.");

        emit TicketsClaim(msg.sender, rewardInTicketTokenToTransfer, _lotteryId, _ticketIds.length);
    }

    /**
     * @notice Close lottery
     * @param _lotteryId: lottery id
     * @dev Callable by operator
     */
    function closeLottery(uint256 _lotteryId) external override onlyOperator nonReentrant {
        require(_lotteries[_lotteryId].status == Status.Open, "Lottery not open");
        // require(block.timestamp > _lotteries[_lotteryId].endTime, "Lottery not over");
        _lotteries[_lotteryId].firstTicketIdNextLottery = currentTicketId;

        // Request a random number from the generator based on a seed
        randomGenerator.getRandomNumber();

        _lotteries[_lotteryId].status = Status.Close;

        emit LotteryClose(_lotteryId, currentTicketId);
    }

    /**
     * @notice Request random number when chainlink VRF doesn't work properly.
     * @param _lotteryId: lottery id
     * @dev Callable by owner
     */
    function requestRandomNumber(uint256 _lotteryId) external onlyOwner {
        require(_lotteries[_lotteryId].status == Status.Close, "Lottery not close");
        require(_lotteryId != randomGenerator.viewLatestLotteryId(), "Numbers already generated");

        // Request a random number from the generator based on a seed
        randomGenerator.getRandomNumber();
    }

    function _generateFinalNumbers(uint256 _lotteryId, uint256 randomWord, uint256 denominator) private {
        uint256 count = 0;
        uint256 randomNumber = randomWord;
        uint256[] memory finalNumbers = new uint256[](6);
        success_finalNumbers = false;
        do {
            uint256 lotteryNumber = randomNumber % 100 % 49 + 1;
            randomNumber = randomNumber / denominator;
            
            if (!_checkDuplicated[lotteryNumber]) {
                finalNumbers[count] = lotteryNumber;
                _checkDuplicated[lotteryNumber] = true;
                count ++;
            }
        } while (count < 6 && randomNumber > denominator);

        for (uint256 i = 0; i < count; i ++) {
            _checkDuplicated[finalNumbers[i]] = false;
        }

        if (count == 6) {
            _lotteries[_lotteryId].finalNumbers[0] = finalNumbers[0];
            _lotteries[_lotteryId].finalNumbers[1] = finalNumbers[1];
            _lotteries[_lotteryId].finalNumbers[2] = finalNumbers[2];
            _lotteries[_lotteryId].finalNumbers[3] = finalNumbers[3];
            _lotteries[_lotteryId].finalNumbers[4] = finalNumbers[4];
            _lotteries[_lotteryId].finalNumbers[5] = finalNumbers[5];

            success_finalNumbers = true;
        }
        else {
            if (denominator > 10000000000) {
                success_finalNumbers = false;
            }
            else {
                _generateFinalNumbers(_lotteryId, randomWord, denominator*10);
            }
        }
    }

    /**
     * @notice Draw the final number, calculate reward in TICKET per group, and make lottery claimable
     * @param _lotteryId: lottery id
     * @dev Callable by operator
     */
    function drawFinalNumberAndMakeLotteryClaimable(uint256 _lotteryId)
        external
        override
        onlyOperator
        nonReentrant
    {
        require(_lotteries[_lotteryId].status == Status.Close, "Lottery not close");
        require(_lotteryId == randomGenerator.viewLatestLotteryId(), "Numbers not drawn");

        // Calculate the finalNumber based on the randomResult generated by ChainLink's fallback
        uint256 randomResult = randomGenerator.viewRandomResult();
        _generateFinalNumbers(_lotteryId, randomResult, 10);

        require(success_finalNumbers, "Failed to generate finalNumber");

        // Calculate the amount to share winners
        uint256 amountToShareToWinners = _lotteries[_lotteryId].amountTotalReward;

        // Initialize a number to count addresses in the previous bracket
        uint256 numberAddressesInBracket;

        for (uint256 _ticketId = _lotteries[_lotteryId].firstTicketId; _ticketId < _lotteries[_lotteryId].firstTicketIdNextLottery; _ticketId++) {
            uint256 count = 0;
            for (uint256 j = 0; j < 6; j++) {
                uint256 _lotteryNumber = _lotteries[_lotteryId].finalNumbers[j];
                if (_existLotteryNumberInTicket[_lotteryId][_ticketId][_lotteryNumber]) {
                    count ++;
                }
            }

            if (count > 0) {
                _lotteries[_lotteryId].countWinnersPerBracket[count-1]++;
                numberAddressesInBracket++;
            }
        }

        for (uint256 i = 0; i < 6; i ++) {
            if (_lotteries[_lotteryId].countWinnersPerBracket[i] != 0) {
                if (_lotteries[_lotteryId].rewardsBreakdown[i] != 0) {
                    _lotteries[_lotteryId].ticketRewardPerBracket[i] = ((_lotteries[_lotteryId].rewardsBreakdown[i] * amountToShareToWinners) /
                        _lotteries[_lotteryId].countWinnersPerBracket[i]) 
                        / 10000;
                }
            }
            else {
                _lotteries[_lotteryId].ticketRewardPerBracket[i] = 0;
            }
        }
        
        _lotteries[_lotteryId].status = Status.Claimable;

        emit LotteryNumberDrawn(currentLotteryId, numberAddressesInBracket);
    }

    function setFreeTicketToken(address _freeTicketTokenAddress, uint256 _freeTicketTokenPrice) external onlyOwner {
        freeTicketToken = IERC20(_freeTicketTokenAddress);
        freeTicketTokenPrice = _freeTicketTokenPrice;
    }

    function calculateFreeTickets(address account, uint256 _lotteryId) public view returns (uint256) {
        uint256 tickets = 0;
        if (address(freeTicketToken) != address(0) && freeTicketTokenPrice > 0) {
            tickets = freeTicketToken.balanceOf(account) / freeTicketTokenPrice;
        }

        return tickets - _numberFreeTicketsPerLotteryId[_lotteryId][account];
    }

    function setExtraFreeTicketToken(address _tokenAddress, uint256 _price) external onlyOwner {
        if (extraFreeTicketTokenPrice[_tokenAddress] == 0 && _price > 0) {
            extraFreeTicketTokens.push(_tokenAddress);
        }
        extraFreeTicketTokenPrice[_tokenAddress] = _price;
    }

    function calculateExtraFreeTickets(address account) public view returns (uint256) {
        uint256 extraTickets = 0;
        if (extraFreeTicketTokens.length > 0) {
            for(uint256 i = 0; i < extraFreeTicketTokens.length; i ++) {
                if (extraFreeTicketTokenPrice[extraFreeTicketTokens[i]] > 0 && IERC20(extraFreeTicketTokens[i]).balanceOf(account) >= extraFreeTicketTokenPrice[extraFreeTicketTokens[i]]) {
                    extraTickets = extraFreeTicketAmount;
                    break;
                }
            }
        }

        return extraTickets;
    }

    /**
     * @notice Change the random generator
     * @dev The calls to functions are used to verify the new generator implements them properly.
     * It is necessary to wait for the VRF response before starting a round.
     * Callable only by the contract owner
     * @param _randomGeneratorAddress: address of the random generator
     */
    function changeRandomGenerator(address _randomGeneratorAddress) external onlyOwner {
        require(_lotteries[currentLotteryId].status == Status.Claimable, "Lottery not in claimable");

        // Request a random number
        IJackpotApeRandomGenerator(_randomGeneratorAddress).getRandomNumber();

        // Calculate the finalNumber based on the randomResult generated by ChainLink's fallback
        IJackpotApeRandomGenerator(_randomGeneratorAddress).viewRandomResult();

        randomGenerator = IJackpotApeRandomGenerator(_randomGeneratorAddress);

        emit NewRandomGenerator(_randomGeneratorAddress);
    }

    /**
     * @notice Start the lottery
     * @dev Callable by operator
     * @param _endTime: endTime of the lottery
     * @param _priceTicket: price of a ticket in TICKET
     * @param _discountDivisor: the divisor to calculate the discount magnitude for bulks
     * @param _rewardsBreakdown: breakdown of rewards per bracket (must sum to 10,000)
     * @param _rewardAmount: reward amount to winners
     */
    function startLottery(
        uint256 _endTime,
        uint256 _priceTicket,
        uint256 _discountDivisor,
        uint256[6] calldata _rewardsBreakdown,
        uint256 _rewardAmount
    ) external override onlyOperator {
        require(
            (currentLotteryId == 0) || (_lotteries[currentLotteryId].status == Status.Claimable),
            "Not time to start lottery"
        );

        require(
            ((_endTime - block.timestamp) > MIN_LENGTH_LOTTERY) && ((_endTime - block.timestamp) < MAX_LENGTH_LOTTERY),
            "Lottery length outside of range"
        );

        require(
            (_priceTicket >= minPriceTicket) && (_priceTicket <= maxPriceTicket),
            "Outside of limits"
        );

        require(_discountDivisor >= MIN_DISCOUNT_DIVISOR, "Discount divisor too low");
        // require(_treasuryFee <= MAX_TREASURY_FEE, "Treasury fee too high");

        require(
            (_rewardsBreakdown[0] +
                _rewardsBreakdown[1] +
                _rewardsBreakdown[2] +
                _rewardsBreakdown[3] +
                _rewardsBreakdown[4] +
                _rewardsBreakdown[5]) == 10000,
            "Rewards must equal 10000"
        );

        currentLotteryId++;

        _lotteries[currentLotteryId] = Lottery({
            status: Status.Open,
            startTime: block.timestamp,
            endTime: _endTime,
            priceTicket: _priceTicket,
            discountDivisor: _discountDivisor,
            rewardsBreakdown: _rewardsBreakdown,
            ticketRewardPerBracket: [uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)],
            countWinnersPerBracket: [uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)],
            firstTicketId: currentTicketId,
            firstTicketIdNextLottery: currentTicketId,
            amountTotalReward: _rewardAmount,
            finalNumbers: [uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)]
        });

        emit LotteryOpen(
            currentLotteryId,
            block.timestamp,
            _endTime,
            _priceTicket,
            currentTicketId,
            _rewardAmount
        );
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of token amount to withdraw
     * @dev Only callable by owner.
     */
    function withdrawTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);

        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    function withdrawEth(uint256 _amount) external onlyOwner {
        require(_amount <= address(this).balance, "No enough balance");

        (bool success, ) = treasuryAddress.call{value: _amount}("");

        require(success, "Unable to send eth");
    }

    /**
     * @notice Set TICKET price ticket upper/lower limit
     * @dev Only callable by owner
     * @param _minPriceTicket: minimum price of a ticket in TICKET
     * @param _maxPriceTicket: maximum price of a ticket in TICKET
     */
    function setMinAndMaxTicketPriceInTicketToken(uint256 _minPriceTicket, uint256 _maxPriceTicket)
        external
        onlyOwner
    {
        require(_minPriceTicket <= _maxPriceTicket, "minPrice must be < maxPrice");

        minPriceTicket = _minPriceTicket;
        maxPriceTicket = _maxPriceTicket;
    }

    /**
     * @notice Set max number of tickets
     * @dev Only callable by owner
     */
    function setMaxNumberTicketsPerBuy(uint256 _maxNumberTicketsPerBuy) external onlyOwner {
        require(_maxNumberTicketsPerBuy != 0, "Must be > 0");
        maxNumberTicketsPerBuyOrClaim = _maxNumberTicketsPerBuy;
    }

    /**
     * @notice Set operator and treasury addresses
     * @dev Only callable by owner
     * @param _operatorAddress: address of the operator
     * @param _treasuryAddress: address of the treasury
     */
    function setOperatorAndTreasuryAndInjectorAddresses(
        address _operatorAddress,
        address _treasuryAddress
    ) external onlyOwner {
        require(_operatorAddress != address(0), "Cannot be zero address");
        require(_treasuryAddress != address(0), "Cannot be zero address");

        operatorAddress = _operatorAddress;
        treasuryAddress = _treasuryAddress;

        emit NewOperatorAndTreasuryAndInjectorAddresses(_operatorAddress, _treasuryAddress);
    }

    /**
     * @notice Calculate price of a set of tickets
     * @param _discountDivisor: divisor for the discount
     * @param _priceTicket price of a ticket (in TICKET)
     * @param _numberTickets number of tickets to buy
     */
    function calculateTotalPriceForBulkTickets(
        uint256 _discountDivisor,
        uint256 _priceTicket,
        uint256 _numberTickets
    ) external pure returns (uint256) {
        require(_discountDivisor >= MIN_DISCOUNT_DIVISOR, "Must be >= MIN_DISCOUNT_DIVISOR");
        require(_numberTickets != 0, "Number of tickets must be > 0");

        return _calculateTotalPriceForBulkTickets(_discountDivisor, _priceTicket, _numberTickets);
    }

    /**
     * @notice View current lottery id
     */
    function viewCurrentLotteryId() external view override returns (uint256) {
        return currentLotteryId;
    }

    /**
     * @notice View lottery information
     * @param _lotteryId: lottery id
     */
    function viewLottery(uint256 _lotteryId) external view returns (Lottery memory) {
        return _lotteries[_lotteryId];
    }

    /**
     * @notice View ticker statuses and numbers for an array of ticket ids
     * @param _ticketIds: array of _ticketId
     */
    function viewNumbersAndStatusesForTicketIds(uint256[] calldata _ticketIds)
        external
        view
        returns (uint256[] memory, bool[] memory)
    {
        uint256 length = _ticketIds.length;
        uint256[] memory ticketNumbers = new uint256[](length);
        bool[] memory ticketStatuses = new bool[](length);

        for (uint256 i = 0; i < length; i++) {
            ticketNumbers[i] = _tickets[_ticketIds[i]].number;
            if (_tickets[_ticketIds[i]].owner == address(0)) {
                ticketStatuses[i] = true;
            } else {
                ticketStatuses[i] = false;
            }
        }

        return (ticketNumbers, ticketStatuses);
    }

    /**
     * @notice View rewards for a given ticket, providing a bracket, and lottery id
     * @dev Computations are mostly offchain. This is used to verify a ticket!
     * @param _lotteryId: lottery id
     * @param _ticketId: ticket id
     */
    function viewRewardsForTicketId(
        uint256 _lotteryId,
        uint256 _ticketId
    ) external view returns (uint256) {
        // Check lottery is in claimable status
        if (_lotteries[_lotteryId].status != Status.Claimable) {
            return 0;
        }

        // Check ticketId is within range
        if (
            (_lotteries[_lotteryId].firstTicketIdNextLottery < _ticketId) &&
            (_lotteries[_lotteryId].firstTicketId >= _ticketId)
        ) {
            return 0;
        }

        return _calculateRewardsForTicketId(_lotteryId, _ticketId);
    }

    /**
     * @notice View user ticket ids, numbers, and statuses of user for a given lottery
     * @param _user: user address
     * @param _lotteryId: lottery id
     * @param _cursor: cursor to start where to retrieve the tickets
     * @param _size: the number of tickets to retrieve
     */
    function viewUserInfoForLotteryId(
        address _user,
        uint256 _lotteryId,
        uint256 _cursor,
        uint256 _size
    )
        external
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            bool[] memory,
            uint256
        )
    {
        uint256 length = _size;
        uint256 numberTicketsBoughtAtLotteryId = _userTicketIdsPerLotteryId[_user][_lotteryId].length;

        if (length > (numberTicketsBoughtAtLotteryId - _cursor)) {
            length = numberTicketsBoughtAtLotteryId - _cursor;
        }

        uint256[] memory lotteryTicketIds = new uint256[](length);
        uint256[] memory ticketNumbers = new uint256[](length);
        bool[] memory ticketStatuses = new bool[](length);

        for (uint256 i = 0; i < length; i++) {
            lotteryTicketIds[i] = _userTicketIdsPerLotteryId[_user][_lotteryId][i + _cursor];
            ticketNumbers[i] = _tickets[lotteryTicketIds[i]].number;

            // True = ticket claimed
            if (_tickets[lotteryTicketIds[i]].owner == address(0)) {
                ticketStatuses[i] = true;
            } else {
                // ticket not claimed (includes the ones that cannot be claimed)
                ticketStatuses[i] = false;
            }
        }

        return (lotteryTicketIds, ticketNumbers, ticketStatuses, _cursor + length);
    }

    /**
     * @notice Calculate rewards for a given ticket
     * @param _lotteryId: lottery id
     * @param _ticketId: ticket id
     */
    function _calculateRewardsForTicketId(
        uint256 _lotteryId,
        uint256 _ticketId
    ) internal view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < 6; i ++) {
            if (_existLotteryNumberInTicket[_lotteryId][_ticketId][_lotteries[_lotteryId].finalNumbers[i]]) {
                count ++;
            }
        }

        // Confirm that the two transformed numbers are the same, if not throw
        if (count > 0) {
            return _lotteries[_lotteryId].ticketRewardPerBracket[count-1];
        } else {
            return 0;
        }
    }

    /**
     * @notice Calculate final price for bulk of tickets
     * @param _discountDivisor: divisor for the discount (the smaller it is, the greater the discount is)
     * @param _priceTicket: price of a ticket
     * @param _numberTickets: number of tickets purchased
     */
    function _calculateTotalPriceForBulkTickets(
        uint256 _discountDivisor,
        uint256 _priceTicket,
        uint256 _numberTickets
    ) internal pure returns (uint256) {
        if (_discountDivisor > 0) {
            return (_priceTicket * _numberTickets * (_discountDivisor + 1 - _numberTickets)) / _discountDivisor;
        } else {
            return _priceTicket * _numberTickets;
        }
    }

    /**
     * @notice Check if an address is a contract
     */
    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    receive() external payable {}
}