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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

interface IRandomNumberGenerator {
    function computerSeed(uint256) external view returns(uint256);
    function getResultNumber() external view returns(uint256, uint256, uint256);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../interfaces/IRandomNumberGenerator.sol";

contract PandoPotV2 is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;
    using Address for address;

    enum PRIZE_STATUS {AVAILABLE, CLAIMED, LIQUIDATED}
    // 0 : mega, 1 : minor, 2 : leaderboard
    struct PrizeInfo {
        uint256 USD;
        uint256 PSR;
        uint256 expire;
        uint256 nClaimed;
        uint256 totalWinning;
    }

    struct LeaderboardPrizeInfo {
        uint256 USD;
        uint256 PSR;
        uint256 expire;
        PRIZE_STATUS status;
    }

    struct RoundInfo {
        uint256 megaNumber;
        uint256 minorNumber1;
        uint256 minorNumber2;
        uint256 finishedAt;
        uint256 status; //0 : need Update prizeInfo
    }

    address public USD;
    address public PSR;
    address public randomNumberGenerator;

    uint256 public constant PRECISION = 10000000000;
    uint256 public constant unlockPeriod = 2 * 365 * 1 days;
    uint256 public constant ONE_HUNDRED_PERCENT = 10000;
    uint256 public timeBomb = 2 * 30 * 1 days;
    uint256 public prizeExpireTime = 14 * 1 days;
    uint256 public megaPrizePercentage = 2500;
    uint256 public minorPrizePercentage = 100;
    uint256 public roundDuration = 1 hours;

    uint256 public lastDistribute;
    uint256 public USDForCurrentPot;
    uint256 public PSRForCurrentPot;
    uint256 public totalPSRAllocated;
    uint256 public lastUpdatePot;

    uint256 public USDForPreviousPot;
    uint256 public PSRForPreviousPot;

    uint256 public currentRoundId;
    uint256 public currentDistributeId;

    //round => number => address => quantity
    mapping (uint256 => mapping (uint256 => mapping(address => uint))) public megaTickets;
    mapping (uint256 => mapping (uint256 => mapping(address => uint))) public minorTickets;

    mapping (uint256 => mapping (uint256 => mapping(address => uint))) public nMegaTicketsClaimed;
    mapping (uint256 => mapping (uint256 => mapping(address => uint))) public nMinorTicketsClaimed;

    //round => number => quantity
    mapping (uint256 => mapping(uint256 => uint256)) public nMegaTickets;
    mapping (uint256 => mapping(uint256 => uint256)) public nMinorTickets;
    //round => prize
    mapping (uint256 => PrizeInfo) public megaPrize;
    mapping (uint256 => PrizeInfo) public minorPrize;

    //round => address => prize
    mapping (uint256 => mapping(address => LeaderboardPrizeInfo)) public leaderboardPrize;
    mapping (uint256 => RoundInfo) public roundInfo;

    mapping (address => bool) public whitelist;
    uint256[] public seeds;

    uint256 public pendingUSD;

    uint256 public megaSampleSpace = 1e6;
    uint256 public minorSampleSpace = 1e4;

    uint256 public currentMegaNumber;
    uint256 public currentMinorNumber1;
    uint256 public currentMinorNumber2;

    /*----------------------------CONSTRUCTOR----------------------------*/
    constructor (address _USD, address _PSR, address _randomNumberGenerator) {
        //require(_USD.isContract() && _PSR.isContract() && _randomNumberGenerator.isContract() , "PandoPot: Must be valid contract address");
        USD = _USD;
        PSR = _PSR;
        randomNumberGenerator = _randomNumberGenerator;
        lastDistribute = block.timestamp;
        lastUpdatePot = block.timestamp;
        megaSampleSpace = 1e6;
        minorSampleSpace = 1e4;
        currentRoundId = 1;
        roundInfo[0].finishedAt = block.timestamp;
        roundInfo[0].status = 1;
    }

    /*----------------------------INTERNAL FUNCTIONS----------------------------*/

    function _transferToken(address _token, address _receiver, uint256 _amount) internal {
        if (_amount > 0) {
            IERC20(_token).safeTransfer(_receiver, _amount);
        }
    }

    function _generateTicket(uint256 _rand, uint256 _sample, uint256 _nSeeds) internal view returns(uint256) {
        if (_nSeeds > 0) {   
            return (uint256(
            keccak256(
                abi.encodePacked(
                    (_rand * seeds[_rand % _nSeeds])
            )))% _sample);
        }
        return (_rand % _sample);
    }

    function _updateRound(uint256 _id) internal {
        RoundInfo storage _roundInfo = roundInfo[_id];
        if (_roundInfo.status == 0) {
            _roundInfo.status = 1;
            _updateLuckyNumber();
            _roundInfo.megaNumber = currentMegaNumber;
            _roundInfo.minorNumber1 = currentMinorNumber1;
            _roundInfo.minorNumber2 = currentMinorNumber2;
            _roundInfo.finishedAt = block.timestamp;

            (uint256 _megaUSD, uint256 _megaPSR) = _calcMegaPrize(_id, currentMegaNumber);
            (uint256 _minorUSD1, uint256 _minorPSR1) = _calcMinorPrize(_id, currentMinorNumber1);
            (uint256 _minorUSD2, uint256 _minorPSR2) = _calcMinorPrize(_id, currentMinorNumber2);
            emit RoundCompleted(_id, block.timestamp + prizeExpireTime, currentMegaNumber, currentMinorNumber1, currentMinorNumber2, _megaUSD, _megaPSR, _minorUSD1, _minorPSR1, _minorUSD2, _minorPSR2);
        }
    }

    function _updateLuckyNumber() internal {
        if (currentRoundId > 2) {
            seeds.push(currentMegaNumber);
            seeds.push(currentMinorNumber1);
            seeds.push(currentMinorNumber2);
        }
        (uint256 _megaNumber, uint256 _minorNumber1, uint256 _minorNumber2) = IRandomNumberGenerator(randomNumberGenerator).getResultNumber();
        currentMegaNumber = _megaNumber % megaSampleSpace;
        currentMinorNumber1 = _minorNumber1 % minorSampleSpace;
        currentMinorNumber2 = _minorNumber2 % minorSampleSpace;
    }

    function updateLuckupNumberForQC(uint256 _roundId, uint256 _megaNumber, uint256 _minorNumber1, uint256 _minorNumber2) external onlyOwner{
        if (currentRoundId > 0) {
            seeds.push(currentMegaNumber);
            seeds.push(currentMinorNumber1);
            seeds.push(currentMinorNumber2);
        }
        currentMegaNumber = _megaNumber % megaSampleSpace;
        currentMinorNumber1 = _minorNumber1 % minorSampleSpace;
        currentMinorNumber2 = _minorNumber2 % minorSampleSpace;
        RoundInfo storage _roundInfo = roundInfo[_roundId];
            _roundInfo.megaNumber = currentMegaNumber;
            _roundInfo.minorNumber1 = currentMinorNumber1;
            _roundInfo.minorNumber2 = currentMinorNumber2;
            (uint256 _megaUSD, uint256 _megaPSR) = _calcMegaPrize(_roundId , currentMegaNumber);
            (uint256 _minorUSD1, uint256 _minorPSR1) = _calcMinorPrize(_roundId, currentMinorNumber1);
            (uint256 _minorUSD2, uint256 _minorPSR2) = _calcMinorPrize(_roundId, currentMinorNumber2);
        emit RoundCompleted(_roundId, block.timestamp + prizeExpireTime, currentMegaNumber, currentMinorNumber1, currentMinorNumber2, _megaUSD, _megaPSR, _minorUSD1, _minorPSR1, _minorUSD2, _minorPSR2);
    }
    function _calcMegaPrize(uint256 _roundId, uint256 _megaNumber) internal returns(uint256, uint256) {
        PrizeInfo memory _prize = PrizeInfo({
            USD: 0,
            PSR: 0,
            expire: block.timestamp + prizeExpireTime,
            nClaimed: 0,
            totalWinning: nMegaTickets[_roundId][_megaNumber]
        });
        if (_prize.totalWinning > 0) {
            _prize.USD = USDForCurrentPot * megaPrizePercentage / ONE_HUNDRED_PERCENT;
            _prize.PSR = PSRForCurrentPot * megaPrizePercentage / ONE_HUNDRED_PERCENT;
            pendingUSD += _prize.USD;
            PSRForCurrentPot -= _prize.PSR;
        }
        megaPrize[_roundId] = _prize;
        return (_prize.USD, _prize.PSR);
    }

    function _calcMinorPrize(uint256 _roundId, uint256 _minorNumber) internal returns(uint256, uint256) {
        PrizeInfo storage _prize = minorPrize[_roundId];
        uint256 _totalWinning = nMinorTickets[_roundId][_minorNumber];
        if ( _totalWinning > 0) {
            _prize.USD += USDForCurrentPot * minorPrizePercentage / ONE_HUNDRED_PERCENT;
            _prize.PSR += PSRForCurrentPot * minorPrizePercentage / ONE_HUNDRED_PERCENT;
            _prize.totalWinning += _totalWinning;
            pendingUSD += _prize.USD;
            PSRForCurrentPot -= _prize.PSR;
        }
        _prize.expire = block.timestamp + prizeExpireTime;
        _prize.nClaimed = 0;
        return (_prize.USD, _prize.PSR);
    }

    function _liquidate(uint256 _type, uint256 _roundId, address _owner) internal {
        uint256 _totalUSD = 0;
        uint256 _totalPSR = 0;

        if (_type == 0 || _type == 1) {
            PrizeInfo memory _megaPrize = megaPrize[_roundId];
            PrizeInfo memory _minorPrize = minorPrize[_roundId];
            require(_megaPrize.expire < block.timestamp || _minorPrize.expire < block.timestamp, 'PandoPot: !expire');
            require(_megaPrize.totalWinning != 0 || _minorPrize.totalWinning != 0, 'PandoPot: Divine zero');

            _totalUSD = _megaPrize.USD * (_megaPrize.totalWinning - _megaPrize.nClaimed) / _megaPrize.totalWinning +
                        _minorPrize.USD * (_minorPrize.totalWinning - _minorPrize.nClaimed) / _minorPrize.totalWinning;

            _totalPSR = _megaPrize.PSR * (_megaPrize.totalWinning - _megaPrize.nClaimed) / _megaPrize.totalWinning +
                        _minorPrize.PSR * (_minorPrize.totalWinning - _minorPrize.nClaimed) / _minorPrize.totalWinning;
        } else {
            LeaderboardPrizeInfo storage _prize = leaderboardPrize[_roundId][_owner];
            require(_prize.expire > block.timestamp, 'PandoPot: !expire');
            _prize.status = PRIZE_STATUS.LIQUIDATED;
            _totalUSD = _prize.USD;
            _totalPSR = _prize.PSR;
        }
        pendingUSD -= _totalUSD;
        PSRForCurrentPot += _totalPSR;
        emit Liquidated(_type, _roundId, _owner);
    }

    /*----------------------------EXTERNAL FUNCTIONS----------------------------*/

    function getRoundDuration() external view returns(uint256) {
        return roundDuration;
    }

    function enter(address _receiver, uint256 _rand, uint256 _quantity) external whenNotPaused nonReentrant onlyWhitelist() {
        uint256 _megaTicket;
        uint256 _minorTicket;
        uint256 _currentRoundId = currentRoundId;
        uint256[] memory _megaTickets = new uint[](_quantity);
        uint256[] memory _minorTickets = new uint[](_quantity);
        uint256 _sampleSpace = megaSampleSpace;
        uint256 _minorSpace = minorSampleSpace;
        uint256 _nSeeds = seeds.length;
        uint256 _salt = block.timestamp;
        for (uint256 i = 0; i < _quantity; i++) {
            _megaTicket = _generateTicket(_rand, _sampleSpace, _nSeeds);
            _minorTicket = _generateTicket(_rand, _minorSpace, _nSeeds);

            megaTickets[_currentRoundId][_megaTicket][_receiver]++;
            minorTickets[_currentRoundId][_minorTicket][_receiver]++;

            nMegaTickets[_currentRoundId][_megaTicket]++;
            nMinorTickets[_currentRoundId][_minorTicket]++;
            _megaTickets[i] = _megaTicket;
            _minorTickets[i] = _minorTicket;
            _rand = uint256(
            keccak256(
                abi.encodePacked(
                    _salt
                    + _rand + i
                ) 
            )
        ) % _sampleSpace;
        }
        emit NewMegaTicket(_currentRoundId, _receiver, _megaTickets);
        emit NewMinorTicket(_currentRoundId, _receiver, _minorTickets);
    }

    function enterForQC(address _receiver, uint256[] memory ticketsMinor, uint256[] memory ticketsMega) external whenNotPaused nonReentrant onlyWhitelist() {
        uint256 _megaTicket;
        uint256 _minorTicket;
        uint256 _currentRoundId = currentRoundId;
        uint256[] memory _megaTickets = new uint[](ticketsMega.length);
        uint256[] memory _minorTickets = new uint[](ticketsMinor.length);
        for (uint256 i = 0; i < ticketsMega.length; i++) {
            _megaTicket = ticketsMega[i];
            _minorTicket = ticketsMinor[i];

            megaTickets[_currentRoundId][_megaTicket][_receiver]++;
            minorTickets[_currentRoundId][_minorTicket][_receiver]++;

            nMegaTickets[_currentRoundId][_megaTicket]++;
            nMinorTickets[_currentRoundId][_minorTicket]++;
            _megaTickets[i] = _megaTicket;
            _minorTickets[i] = _minorTicket;
        }
        emit NewMegaTicket(_currentRoundId, _receiver, _megaTickets);
        emit NewMinorTicket(_currentRoundId, _receiver, _minorTickets);
    }


    //0 : mega
    //1 : minor
    //2 : distribute

    function claim(uint256 _type, uint256 _roundId, uint256 _ticketNumber, address _receiver) external whenNotPaused nonReentrant {
        updatePandoPot();
        RoundInfo memory _roundInfo = roundInfo[_roundId];
        require(_roundInfo.status == 1, 'PandoPot: round dont finish');
        uint256 _USDAmount = 0;
        uint256 _PSRAmount = 0;
        if (_type == 0) {
            require(megaTickets[_roundId][_ticketNumber][msg.sender] > 0 && _roundInfo.megaNumber == _ticketNumber, 'PandoPot: no prize');
            require(megaTickets[_roundId][_ticketNumber][msg.sender] > nMegaTicketsClaimed[_roundId][_ticketNumber][msg.sender], 'Pandot: claimed');
            nMegaTicketsClaimed[_roundId][_ticketNumber][msg.sender]++;

            PrizeInfo storage _prizeInfo = megaPrize[_roundId];
            if (_prizeInfo.expire >= block.timestamp) {
                uint256 _nWiningTicket = megaTickets[_roundId][_ticketNumber][msg.sender];
                uint256 _totalWinningTicket = _prizeInfo.totalWinning;
                _USDAmount = _prizeInfo.USD * _nWiningTicket / _totalWinningTicket;
                _PSRAmount = _prizeInfo.PSR * _nWiningTicket / _totalWinningTicket;
                _prizeInfo.nClaimed++;
            } else {
                _liquidate(_type, _roundId, msg.sender);
            }
        } else {
            if (_type == 1) {
                require(minorTickets[_roundId][_ticketNumber][msg.sender] > 0 &&
                    (_roundInfo.minorNumber1 == _ticketNumber || _roundInfo.minorNumber2 == _ticketNumber), 'PandoPot: no prize');
                require(minorTickets[_roundId][_ticketNumber][msg.sender] > nMinorTicketsClaimed[_roundId][_ticketNumber][msg.sender], 'Pandot: claimed');
                nMinorTicketsClaimed[_roundId][_ticketNumber][msg.sender]++;

                PrizeInfo storage _prizeInfo = minorPrize[_roundId];
                if (_prizeInfo.expire >= block.timestamp) {
                    uint256 _nWiningTicket = minorTickets[_roundId][_ticketNumber][msg.sender];
                    uint256 _totalWinningTicket = _prizeInfo.totalWinning;
                    _USDAmount = _prizeInfo.USD * _nWiningTicket / _totalWinningTicket;
                    _PSRAmount = _prizeInfo.PSR * _nWiningTicket / _totalWinningTicket;
                    _prizeInfo.nClaimed++;
                } else {
                    _liquidate(_type, _roundId, msg.sender);
                }
            } else {
                if (_type == 2) {
                    LeaderboardPrizeInfo storage _prize = leaderboardPrize[_roundId][msg.sender];
                    require(_prize.USD + _prize.PSR > 0, 'PandoPot: no prize');
                    require(_prize.status == PRIZE_STATUS.AVAILABLE, 'PandoPot: prize not available');
                    if (_prize.expire >= block.timestamp) {
                        _prize.status = PRIZE_STATUS.CLAIMED;
                        _USDAmount = _prize.USD;
                        _PSRAmount = _prize.PSR;
                    } else {
                        _prize.status = PRIZE_STATUS.LIQUIDATED;
                        _liquidate(_type, _roundId, msg.sender);
                    }
                }
            }
        }

        _transferToken(USD, _receiver, _USDAmount);
        _transferToken(PSR, _receiver, _PSRAmount);
        pendingUSD -= _USDAmount;
        emit Claimed(_type, _roundId, _ticketNumber, _USDAmount, _PSRAmount, _receiver);
    }

    function distribute(address[] memory _leaderboards, uint256[] memory ratios) external onlyWhitelist whenNotPaused {
        require(_leaderboards.length == ratios.length, 'PandoPot: leaderboards != ratios');
        require(block.timestamp - lastDistribute >= timeBomb, 'PandoPot: not enough timebomb');
        uint256 _cur = 0;
        for (uint256 i = 0; i < ratios.length; i++) {
            _cur += ratios[i];
        }
        require(_cur == PRECISION, 'PandoPot: ratios incorrect');
        currentDistributeId++;
        updatePandoPot();
        uint256 _nRatios = ratios.length;
        uint256[] memory _usdAmounts = new uint256[](_nRatios);
        uint256[] memory _psrAmounts = new uint256[](_nRatios);

        for (uint256 i = 0; i < _leaderboards.length; i++) {
            
            uint256 _USDAmount = ratios[i] / PRECISION;
            uint256 _PSRAmount = PSRForPreviousPot * ratios[i] / PRECISION;

            LeaderboardPrizeInfo memory _prize = LeaderboardPrizeInfo({
                USD : _USDAmount,
                PSR : _PSRAmount,
                expire : block.timestamp + prizeExpireTime,
                status : PRIZE_STATUS.AVAILABLE
            });
            leaderboardPrize[currentDistributeId][_leaderboards[i]] = _prize;
            _usdAmounts[i] = _USDAmount;
            _psrAmounts[i] = _PSRAmount;
        }
        pendingUSD += USDForPreviousPot;
        USDForPreviousPot = 0;
        PSRForPreviousPot = 0;
        lastDistribute = block.timestamp;
        emit Distributed(currentDistributeId, _leaderboards, _usdAmounts, _psrAmounts);
    }

    function updatePandoPot() public {
        _updateRound(currentRoundId - 1);
        USDForCurrentPot = IERC20(USD).balanceOf(address(this)) - USDForPreviousPot - pendingUSD;
        PSRForCurrentPot += totalPSRAllocated * (block.timestamp - lastUpdatePot) / unlockPeriod;

        if (block.timestamp - lastDistribute >= timeBomb) {
            if (PSRForPreviousPot == 0 && USDForPreviousPot == 0) {
                USDForPreviousPot = USDForCurrentPot * megaPrizePercentage / ONE_HUNDRED_PERCENT;
                PSRForPreviousPot = PSRForCurrentPot * megaPrizePercentage / ONE_HUNDRED_PERCENT;
                PSRForCurrentPot -= PSRForPreviousPot;
            }
        }
        lastUpdatePot = block.timestamp;
    }

    function liquidate(uint256 _type, uint256 _roundId, address _owner) external whenNotPaused {
        require(_type < 3, 'PandoPot: invalid type');
        _liquidate(_type, _roundId, _owner);
        updatePandoPot();
    }

    function currentPot() external view returns(uint256, uint256) {
        uint256 _USD = IERC20(USD).balanceOf(address(this)) - USDForPreviousPot - pendingUSD;
        uint256 _PSR = totalPSRAllocated * (block.timestamp - lastUpdatePot) / unlockPeriod + PSRForCurrentPot;
        return (_USD, _PSR);
    }

    function finishRound() external onlyRNG {
        require(block.timestamp > roundDuration + roundInfo[currentRoundId - 1].finishedAt, 'PandoPot: < roundDuration');
        roundInfo[currentRoundId].finishedAt = block.timestamp;
        currentRoundId++;
        emit RoundIdUpdated(currentRoundId);
    }

    // 0: wrong
    // 1: valid
    // 2: expired
    // 3: claimed
    function checkTicketStatus(uint256 _roundId, uint256 _type, address _owner, uint256 _ticketNumber) external view returns (uint256) {
        if (_type == 0) {
            if (roundInfo[_roundId].megaNumber == _ticketNumber) {
                if (roundInfo[_roundId].finishedAt + prizeExpireTime < block.timestamp) {
                    return 2;
                }
                if (megaTickets[_roundId][_ticketNumber][_owner] > nMegaTicketsClaimed[_roundId][_ticketNumber][_owner]) {
                    return 1;
                }
                return 3;
            }
        } else {
            if (_type == 1) {
                if (roundInfo[_roundId].minorNumber1 == _ticketNumber || roundInfo[_roundId].minorNumber2 == _ticketNumber) {
                    if (roundInfo[_roundId].finishedAt + prizeExpireTime < block.timestamp) {
                        return 2;
                    }
                    if (megaTickets[_roundId][_ticketNumber][_owner] > nMegaTicketsClaimed[_roundId][_ticketNumber][_owner]) {
                        return 1;
                    }
                    return 3;
                }
            }
        }
        return 0;
    }

    /*----------------------------RESTRICTED FUNCTIONS----------------------------*/

    modifier onlyWhitelist() {
        require(whitelist[msg.sender], 'PandoPot: caller is not in the whitelist');
        _;
    }

    modifier onlyRNG() {
        require(msg.sender == randomNumberGenerator, 'PandoPot: !RNG');
        _;
    }

    function toggleWhitelist(address _addr) external onlyOwner {
        whitelist[_addr] = !whitelist[_addr];
        emit WhitelistChanged(_addr, whitelist[_addr]);
    }

    function allocatePSR(uint256 _amount) external onlyOwner {
        totalPSRAllocated += _amount;
        IERC20(PSR).safeTransferFrom(msg.sender, address(this), _amount);
        emit PSRAllocated(_amount);
    }

    function changeTimeBomb(uint256 _second) external onlyOwner {
        uint256 oldSecond = timeBomb;
        timeBomb = _second;
        emit TimeBombChanged(oldSecond, _second);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function emergencyWithdraw() external onlyOwner whenPaused {
        IERC20 _USD = IERC20(USD);
        IERC20 _PSR = IERC20(PSR);
        uint256 _USDAmount = _USD.balanceOf(address(this));
        uint256 _PSRAmount = _PSR.balanceOf(address(this));
        _USD.safeTransfer(owner(), _USDAmount);
        _PSR.safeTransfer(owner(), _PSRAmount);
        emit EmergencyWithdraw(owner(), _USDAmount, _PSRAmount);
    }

    function changeRewardExpireTime(uint256 _newExpireTime) external onlyOwner whenPaused {
        uint256 _oldExpireTIme = prizeExpireTime;
        prizeExpireTime = _newExpireTime;
        emit RewardExpireTimeChanged(_oldExpireTIme, _newExpireTime);
    }

    function changePrizePercent(uint256 _mega, uint256 _minor) external onlyOwner whenPaused {
        require(_mega <= ONE_HUNDRED_PERCENT && _minor < ONE_HUNDRED_PERCENT, 'PandoPot: prize percent invalid');
        uint256 _oldMega = megaPrizePercentage;
        uint256 _oldMinor = minorPrizePercentage;
        megaPrizePercentage = _mega;
        minorPrizePercentage = _minor;
        emit PricePercentageChanged(_oldMega, _oldMinor, _mega, _minor);
    }

    function changeRandomNumberGenerator(address _rng) external onlyOwner whenPaused {
        require(_rng.isContract(), "PandoPot: Must be valid contract address");
        address _oldRNG = randomNumberGenerator;
        randomNumberGenerator = _rng;
        emit RandomNumberGeneratorChanged(_oldRNG, _rng);
    }

    function changeRoundDuration(uint256 _newDuration) external onlyOwner whenPaused {
        uint256 _oldDuration = roundDuration;
        roundDuration = _newDuration;
        emit RoundDurationChanged(_oldDuration, _newDuration);
    }

    /*----------------------------EVENTS----------------------------*/

    event NewMegaTicket(uint256 roundId, address user, uint256[] numbers);
    event NewMinorTicket(uint256 roundId, address user, uint256[] numbers);

    event Claimed(uint256 _type, uint256 roundId, uint256 ticketNumber, uint256 USD, uint256 PSR, address receiver);
    event Liquidated(uint256 _type, uint256 id, address owner);
    event WhitelistChanged(address indexed whitelist, bool status);
    event PSRAllocated(uint256 amount);
    event TimeBombChanged(uint256 oldValueSecond, uint256 newValueSecond);
    event EmergencyWithdraw(address owner, uint256 USD, uint256 PSR);
    event RewardExpireTimeChanged(uint256 oldExpireTime, uint256 newExpireTime);
    event PricePercentageChanged(uint256 oldMegaPercentage, uint256 oldMinorPercentage, uint256 megaPercentage, uint256 minorPercentage);
    event RandomNumberGeneratorChanged(address indexed _oldRNG, address indexed _RNG);
    event RoundCompleted(uint256 roundId, uint256 expireTime, uint256 megaNumber, uint256 minorNumber1, uint256 minorNumber2, uint256 megaUSD, uint256 megaPSR, uint256 minorUSD1, uint256 minorPSR1, uint256 minorUSD2, uint256 minorPSR2);
    event RoundIdUpdated(uint256 newRoundId);
    event Distributed(uint256 distributeId, address[] leaderboards, uint256[] usdAmounts, uint[] psrAmounts);
    event RoundDurationChanged(uint256 oldDuration, uint256 newDuration);
}