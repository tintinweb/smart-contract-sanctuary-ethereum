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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IRandomNumberGenerator {
    /**
     * Requests randomness from a user-provided seed
     */
    struct RandomInfo {
        uint256 lotteryId; // ID for lotto
        uint256 randomValue; // Status for lotto
        uint256 roundSize; // Number of players
    }

    function requestRandomNumber(
        uint256 lotteryId,
        uint256 _round_size
    ) external returns (uint256 requestId);

    function getRandomInfo(
        uint256 requestId
    ) external view returns (RandomInfo memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// Random number
import "./IRandomNumberGenerator.sol";

contract Lottery is Ownable, Initializable {
    using Address for address;

    // State variables
    // Instance of xx token (collateral currency for lotto)
    IERC20 internal token_;
    // Treasury Address
    address private treasuryAddress_;
    // Storing of the randomness generator
    IRandomNumberGenerator internal randomGenerator_;
    // Counter for lottery IDs
    uint256 private lotteryIdCounter_;
    // Counter for ticket ids
    uint256 private ticketIdCounter_;
    // Lottery size
    uint8 private sizeOfLottery_;
    // maximum number of chosen number
    uint32 private maximumChosenNumber_;
    // ticket price
    uint256 private ticketPrice_;
    // winner percentage
    uint8 private winnerRatio_;
    // treasury percentage
    uint8 private treasuryRatio_;
    // affiliate percentage
    uint8 private affiliateRatio_;
    // all ticket in current round
    uint256[] private currentTickets_;
    // all affiliate in current round
    uint256 private sizeOfAffiliate_;

    // Represents the status of the lottery
    enum Status {
        Open, // The lottery is open for ticket purchases
        Closed, // The lottery is no longer open for ticket purchases
        Completed // The lottery has been closed and the numbers drawn
    }

    // All the needed info for lottery
    struct LotteryInfo {
        uint256 lotteryId; // ID for lotto
        Status lotteryStatus; // Status for lotto
        address tokenAddress; // $token in current round
        uint8 sizeOfLottery; // Show how many tickets there are in one prize round
        uint32 maximumChosenNumber; //  maximum number of chosen number
        uint256 ticketPrice; // Cost per ticket in $token
        uint256 winningTicketId; // Winning ticketId of current lotto
        PrizeDistributionRatio prizeDistributionRatio; // The distribution of pool
    }

    struct PrizeDistributionRatio {
        uint8 winner;
        uint8 treasury;
        uint8 affiliate;
    }

    struct Ticket {
        uint256 number;
        address owner;
        bool claimed;
        uint256 lotteryId;
    }

    // Lottery ID's to info
    mapping(uint256 => LotteryInfo) internal allLotteries_;
    // Ticket ID's to info
    mapping(uint256 => Ticket) internal allTickets_;
    // User address => Lottery ID => Ticket IDs
    mapping(address => mapping(uint256 => uint256[])) internal userTickets_;
    // Affiliate address => Lottery ID => Ticket Count
    mapping(address => mapping(uint256 => uint256)) internal allAffiliate_;
    // Lottery ID's to treasury amount
    mapping(uint256 => uint256) internal allTreasuryAmount_;

    //-------------------------------------------------------------------------
    // EVENTS
    //-------------------------------------------------------------------------

    event NewBatchBuy(
        address indexed minter,
        uint256 lotteryId,
        uint256[] ticketIds,
        uint256 totalCost
    );

    event RequestWinningNumbers(uint256 lotteryId, uint256 requestId);

    event FullfilWinningNumber(
        uint256 lotteryId,
        uint256 ticketId,
        uint256 ticketNumber
    );

    event ConfigLottery(
        address token,
        uint8 sizeOfLottery,
        uint32 maximumChosenNumber,
        uint256 ticketPrice,
        uint8 winnerRatio,
        uint8 treasuryRatio,
        uint8 affiliateRatio
    );

    event LotteryOpen(uint256 lotteryId);

    event LotteryClose(uint256 lotteryId);

    event Affiliate(
        address affiliateAddress,
        uint256 lotteryId,
        uint256 ticketCount
    );

    event ClaimReward(
        address winnerAddress,
        uint256 ticketId,
        uint256 lotteryId
    );

    event ClaimAffiliate(address affiliateAddress, uint256[] lotteryIds);

    event ClaimTreasury(address affiliateAddress, uint256[] lotteryIds);

    //-------------------------------------------------------------------------
    // MODIFIERS
    //-------------------------------------------------------------------------

    modifier notContract() {
        require(!address(msg.sender).isContract(), "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    modifier onlyRandomGenerator() {
        require(
            msg.sender == address(randomGenerator_),
            "Only random generator"
        );
        _;
    }

    //-------------------------------------------------------------------------
    // CONSTRUCTOR
    //-------------------------------------------------------------------------

    constructor(
        address _token,
        uint8 _sizeOfLotteryNumbers,
        uint32 _maximumChosenNumber,
        uint256 _ticketPrice,
        address _treasuryAddress,
        uint8 _treasuryRatio,
        uint8 _affiliateRatio,
        uint8 _winnerRatio
    ) {
        require(_token != address(0), "Contracts cannot be 0 address");
        require(_sizeOfLotteryNumbers != 0, "Lottery setup cannot be 0");
        require(
            _treasuryRatio + _affiliateRatio + _winnerRatio == 100,
            "Ratio must be 100"
        );

        require(
            _treasuryRatio + _affiliateRatio <= 5,
            "owner ratio can not exceed 5"
        );

        token_ = IERC20(_token);
        treasuryAddress_ = _treasuryAddress;
        sizeOfLottery_ = _sizeOfLotteryNumbers;
        maximumChosenNumber_ = _maximumChosenNumber;
        ticketPrice_ = _ticketPrice;
        ticketIdCounter_ = 1;
        lotteryIdCounter_ = 0;
        winnerRatio_ = _winnerRatio;
        treasuryRatio_ = _treasuryRatio;
        affiliateRatio_ = _affiliateRatio;

        PrizeDistributionRatio
            memory prizeDistributionRatio = PrizeDistributionRatio(
                winnerRatio_,
                treasuryRatio_,
                affiliateRatio_
            );

        // init first lotto
        LotteryInfo memory newLottery = LotteryInfo(
            lotteryIdCounter_,
            Status.Completed,
            address(token_),
            sizeOfLottery_,
            maximumChosenNumber_,
            ticketPrice_,
            0,
            prizeDistributionRatio
        );

        allLotteries_[lotteryIdCounter_] = newLottery;
        // Emitting important information around new lottery.
        emit LotteryOpen(lotteryIdCounter_);
    }

    function initialize(
        address _IRandomNumberGenerator
    ) external initializer onlyOwner {
        require(
            _IRandomNumberGenerator != address(0),
            "Contracts cannot be 0 address"
        );
        randomGenerator_ = IRandomNumberGenerator(_IRandomNumberGenerator);
    }

    function costToBuyTickets(
        uint256 _lotteryId,
        uint256 _numberOfTickets
    ) external view returns (uint256 totalCost) {
        uint256 ticketPrice = allLotteries_[_lotteryId].ticketPrice;
        totalCost = ticketPrice * _numberOfTickets;
    }

    function getCurrentLottery() external view returns (uint256) {
        return lotteryIdCounter_;
    }

    // get lottery information
    function getLottery(
        uint256 _lotteryId
    ) external view returns (LotteryInfo memory) {
        return (allLotteries_[_lotteryId]);
    }

    /**
     * @param   _ticketId: The unique ID of the ticket
     * @return  address: Owner of ticket
     */
    function getOwnerOfTicket(
        uint256 _ticketId
    ) external view returns (address) {
        return allTickets_[_ticketId].owner;
    }

    // get ticket information
    function getTicket(
        uint256 _ticketId
    ) external view returns (Ticket memory) {
        return allTickets_[_ticketId];
    }

    // get ticket information for a specific user
    function getUserTickets(
        uint256 _lotteryId,
        address _user
    ) external view returns (uint256[] memory) {
        return userTickets_[_user][_lotteryId];
    }

    // check available tickets for current round
    function getAvailableTicketQty() public view returns (uint256) {
        return sizeOfLottery_ - currentTickets_.length;
    }

    // get quantity of tickets that are available for claim affiliate
    function getAffiliateTicketQty(
        uint256[] memory _lotteryId
    ) external view returns (uint256[] memory, uint256[] memory) {
        uint256[] memory lotteryIds = new uint256[](_lotteryId.length);
        uint256[] memory ticketCount = new uint256[](_lotteryId.length);
        for (uint256 i = 0; i < _lotteryId.length; i++) {
            lotteryIds[i] = _lotteryId[i];
            ticketCount[i] = allAffiliate_[msg.sender][_lotteryId[i]];
        }
        return (lotteryIds, ticketCount);
    }

    // get amount of token that owner can claim for specific lotteryId
    function getUnclaimedTreasuryQty(
        uint256[] memory _lotteryId
    ) external view onlyOwner returns (uint256[] memory, uint256[] memory) {
        uint256[] memory lotteryIds = new uint256[](_lotteryId.length);
        uint256[] memory amounts = new uint256[](_lotteryId.length);
        for (uint256 i = 0; i < _lotteryId.length; i++) {
            lotteryIds[i] = _lotteryId[i];
            amounts[i] = allTreasuryAmount_[_lotteryId[i]];
        }
        return (lotteryIds, amounts);
    }

    function createNewLottery() external onlyOwner returns (uint256) {
        require(
            allLotteries_[lotteryIdCounter_].lotteryStatus == Status.Completed,
            "Cannot be created if the current lotto are not finished."
        );
        // reset currentTickets_
        currentTickets_ = new uint256[](0);

        // Incrementing lottery ID
        lotteryIdCounter_ += 1;

        PrizeDistributionRatio
            memory prizeDistributionRatio = PrizeDistributionRatio(
                winnerRatio_,
                treasuryRatio_,
                affiliateRatio_
            );

        // Saving data in struct
        LotteryInfo memory lottery = LotteryInfo(
            lotteryIdCounter_,
            Status.Open,
            address(token_),
            sizeOfLottery_,
            maximumChosenNumber_,
            ticketPrice_,
            0,
            prizeDistributionRatio
        );

        allLotteries_[lotteryIdCounter_] = lottery;
        // Emitting important information around new lottery.
        emit LotteryOpen(lotteryIdCounter_);
        return lotteryIdCounter_;
    }

    function configNewLottery(
        address _token,
        uint8 _sizeOfLottery,
        uint32 _maximumChosenNumber,
        uint256 _ticketPrice,
        uint8 _winnerRatio,
        uint8 _treasuryRatio,
        uint8 _affiliateRatio
    ) external onlyOwner {
        require(
            allLotteries_[lotteryIdCounter_].lotteryStatus == Status.Completed,
            "Cannot be config if the current lotto are not finished."
        );

        require(_sizeOfLottery != 0, "Lottery size cannot be 0");
        require(_ticketPrice != 0, "Ticket price cannot be 0");
        require(_token != address(0), "Token address cannot be 0");
        require(
            _treasuryRatio + _affiliateRatio + _winnerRatio == 100,
            "Ratio must be 100"
        );
        require(
            _treasuryRatio + _affiliateRatio <= 5,
            "Owner ratio can not exceed 5"
        );

        token_ = IERC20(_token);
        sizeOfLottery_ = _sizeOfLottery;
        ticketPrice_ = _ticketPrice;
        winnerRatio_ = _winnerRatio;
        treasuryRatio_ = _treasuryRatio;
        affiliateRatio_ = _affiliateRatio;
        maximumChosenNumber_ = _maximumChosenNumber;

        emit ConfigLottery(
            _token,
            sizeOfLottery_,
            maximumChosenNumber_,
            ticketPrice_,
            winnerRatio_,
            treasuryRatio_,
            affiliateRatio_
        );
    }

    /**
     * @param  _ticketQty: The quantity of the ticket
     * @param  _chosenNumbersForEachTicket: Number of each ticket
     * @param  _affiliateAddress: will be use when _isAffiliate == true
     * @param  _isAffiliate: ticket buy with aff or not
     */
    function batchBuyTicket(
        uint8 _ticketQty,
        uint32[] calldata _chosenNumbersForEachTicket,
        address payable _affiliateAddress,
        bool _isAffiliate
    ) external payable notContract {
        require(
            allLotteries_[lotteryIdCounter_].lotteryStatus == Status.Open,
            "Lottery status incorrect for buy"
        );
        require(
            _ticketQty <=
                (allLotteries_[lotteryIdCounter_].sizeOfLottery -
                    currentTickets_.length),
            "Batch buy too large"
        );
        require(
            _chosenNumbersForEachTicket.length == _ticketQty,
            "The quantity of the _chosenNumbersForEachTicket is not equal with _ticketQty"
        );

        // Batch mints the user their tickets
        uint256[] memory ticketIds = new uint256[](_ticketQty);
        for (uint8 i = 0; i < _ticketQty; i++) {
            require(
                _chosenNumbersForEachTicket[i] <= maximumChosenNumber_,
                "Chosen number out of range"
            );
            currentTickets_.push(ticketIdCounter_);
            // Storing the ticket information
            ticketIds[i] = ticketIdCounter_;
            allTickets_[ticketIdCounter_] = Ticket(
                _chosenNumbersForEachTicket[i],
                msg.sender,
                false,
                lotteryIdCounter_
            );
            userTickets_[msg.sender][lotteryIdCounter_].push(ticketIdCounter_);
            // Incrementing the tokenId counter
            ticketIdCounter_ += 1;
            // set affiliate address
            if (_isAffiliate) {
                allAffiliate_[_affiliateAddress][lotteryIdCounter_] += 1;
                // add affiliate size
                sizeOfAffiliate_ += 1;
                emit Affiliate(
                    _affiliateAddress,
                    lotteryIdCounter_,
                    allAffiliate_[_affiliateAddress][lotteryIdCounter_]
                );
            }
        }
        uint256 totalCost = ticketPrice_ * _ticketQty;
        // Transfers the required token to this contract
        token_.transferFrom(msg.sender, address(this), totalCost);

        // Emitting batch buy ticket with all information
        emit NewBatchBuy(msg.sender, lotteryIdCounter_, ticketIds, msg.value);

        // check for drawing win ticket
        if (
            currentTickets_.length ==
            allLotteries_[lotteryIdCounter_].sizeOfLottery
        ) {
            allLotteries_[lotteryIdCounter_].lotteryStatus = Status.Closed;
            emit LotteryClose(lotteryIdCounter_);
            requestWinningNumber();
        }
    }

    /**
     * @param  _randomIndex: the index of winner's ticket
     */
    function fullfilWinningNumber(
        uint256 _lotteryId,
        uint256 _randomIndex
    ) external onlyRandomGenerator {
        allLotteries_[_lotteryId].winningTicketId = currentTickets_[
            _randomIndex
        ];

        allLotteries_[_lotteryId].lotteryStatus = Status.Completed;

        // Send token to treasury address (treasuryEquity = treasury equity + unowned affiliate)
        uint256 treasuryEquity = ((sizeOfLottery_ *
            ticketPrice_ *
            treasuryRatio_) +
            ((sizeOfLottery_ - sizeOfAffiliate_) *
                ticketPrice_ *
                affiliateRatio_)) / 100;
        sizeOfAffiliate_ = 0;
        allTreasuryAmount_[_lotteryId] = treasuryEquity;

        emit FullfilWinningNumber(
            _lotteryId,
            currentTickets_[_randomIndex],
            allTickets_[currentTickets_[_randomIndex]].number
        );
    }

    // For player to claim reward
    function claimReward(
        uint256 _lotteryId,
        uint256 _ticketId
    ) external payable {
        require(allLotteries_[_lotteryId].lotteryId != 0, "Invalid lotteryId.");

        require(allTickets_[_ticketId].number != 0, "Invalid ticketId.");

        // Checks lottery numbers have not already been drawn
        require(
            allLotteries_[_lotteryId].lotteryStatus == Status.Completed,
            "Can't claim reward from unfinished round"
        );

        require(
            msg.sender == allTickets_[_ticketId].owner,
            "You are not ticket's owner."
        );

        require(
            allTickets_[_ticketId].claimed == false,
            "The reward was claimed."
        );
        allTickets_[_ticketId].claimed = true;

        IERC20 token = IERC20(allLotteries_[_lotteryId].tokenAddress);
        token.transfer(
            address(msg.sender),
            (allLotteries_[_lotteryId].ticketPrice *
                allLotteries_[_lotteryId].sizeOfLottery *
                winnerRatio_) / 100
        );

        emit ClaimReward(msg.sender, _ticketId, _lotteryId);
    }

    /**
     * @param  _listOfLotterryId: all LotteryId that want to claim reward
     */
    function claimAffiliate(
        uint16[] calldata _listOfLotterryId
    ) external payable {
        uint256[] memory claimedLotteryIds = new uint256[](
            _listOfLotterryId.length
        );
        for (uint256 i = 0; i < _listOfLotterryId.length; i++) {
            require(
                allLotteries_[_listOfLotterryId[i]].lotteryStatus ==
                    Status.Completed,
                "Can't claim affiliate from unfinished round"
            );

            // totalClaimed = ticket count * ticket price * ratio / 100
            uint256 totalClaimed = ((allAffiliate_[msg.sender][
                _listOfLotterryId[i]
            ] * allLotteries_[_listOfLotterryId[i]].ticketPrice) *
                allLotteries_[_listOfLotterryId[i]]
                    .prizeDistributionRatio
                    .affiliate) / 100;

            if (totalClaimed > 0) {
                IERC20 token = IERC20(
                    allLotteries_[_listOfLotterryId[i]].tokenAddress
                );
                token.transfer(msg.sender, totalClaimed);
                // reset ticket count of lottery id index i to 0
                allAffiliate_[msg.sender][_listOfLotterryId[i]] = 0;
                claimedLotteryIds[i] = _listOfLotterryId[i];
            }
        }
        emit ClaimAffiliate(msg.sender, claimedLotteryIds);
    }

    /**
     * @param  _listOfLotterryId: all LotteryId that want to claim token
     */
    function claimTreasury(
        uint256[] calldata _listOfLotterryId
    ) external payable onlyOwner {
        uint256[] memory claimedLotteryIds = new uint256[](
            _listOfLotterryId.length
        );
        for (uint256 i = 0; i < _listOfLotterryId.length; i++) {
            require(
                allLotteries_[_listOfLotterryId[i]].lotteryStatus ==
                    Status.Completed,
                "Can't claim treasury from unfinished round"
            );

            if (allTreasuryAmount_[_listOfLotterryId[i]] > 0) {
                IERC20 token = IERC20(
                    allLotteries_[_listOfLotterryId[i]].tokenAddress
                );
                uint256 treasuryAmount = allTreasuryAmount_[
                    _listOfLotterryId[i]
                ];
                token.transfer(msg.sender, treasuryAmount);
                // reset treasuryAmount of  lottery id index i to 0
                allTreasuryAmount_[_listOfLotterryId[i]] = 0;
                // reset ticket count of lottery id index i to 0
                allAffiliate_[msg.sender][_listOfLotterryId[i]] = 0;
                claimedLotteryIds[i] = _listOfLotterryId[i];
            }
        }
        emit ClaimTreasury(msg.sender, claimedLotteryIds);
    }

    receive() external payable {}

    function requestWinningNumber() private returns (uint256 requestId) {
        // Requests a request number from the generator
        requestId = randomGenerator_.requestRandomNumber(
            lotteryIdCounter_,
            sizeOfLottery_
        );

        emit RequestWinningNumbers(lotteryIdCounter_, requestId);
    }
}