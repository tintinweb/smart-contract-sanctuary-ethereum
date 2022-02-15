// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IwsTT} from "./interfaces/IwsTT.sol";
import {IStaking} from "./interfaces/IStaking.sol";

contract Escrow is Ownable {
    using SafeERC20 for IERC20;
    using SafeERC20 for IwsTT;

    error InvalidState();
    error AlreadyRedeemed();
    error DepositLimit();
    error ChoiceChange();
    error BadChoice();
    error AlreadyWithdrawn();

    IERC20 public immutable tenderToken;
    IERC20 public immutable unstakedTenderToken;
    IERC20 public immutable dai;
    IERC20 public immutable gOHM;
    IwsTT public immutable wsTenderToken;
    IStaking public immutable staking;
    AggregatorV3Interface internal immutable priceFeed;
    AggregatorV3Interface internal immutable indexFeed;

    /// DAI per tender token if depositing BEFORE decision (18 decimals)
    uint256 public daiExchangeRate;
    /// DAI per tender token if depositing AFTER decision (18 decimals)
    uint256 public daiLaggardExchangeRate;
    /// gOHM per tender token if depositing BEFORE decision (18 decimals)
    uint256 public gohmExchangeRate;
    /// gOHM per tender token if depositing AFTER decision (18 decimals)
    uint256 public gohmLaggardExchangeRate;
    /// value to adjust tender token decimals to match DAI and gOHM
    uint256 internal immutable decimalAdjuster;

    enum State { PENDING, FAILED, PASSED }
    State public state; // the current state of the takeover

    enum RedemptionChoice { DAI, GOHM }
    enum DepositToken { UNSTAKED, STAKED, WRAPPED }
    struct Deposit {
        uint256 amount; // amount of wrapped staked tender tokens (18 decimals)
        uint256 index; // OHM index
        uint256 ohmPrice; // OHM / USD price
        RedemptionChoice choice; // 0 - DAI, 1 - gOHM
        bool didRedeem;
        bool isLaggard; // deposit happened after takeover decision
    }
    mapping (address => Deposit) public deposits;
    uint256 public totalDeposits; // total amount of wrapped tender tokens deposited (18 decimals)
    uint256 public immutable maxDeposits; // max allowable wrapped tender tokens (18 decimals)

    uint256 public totalRedemptions; // total number of wrapped tokens redeemed (18 decimals)

    uint256 public daiDistributed; // DAI distributed via redemptions (18 decimals)
    uint256 public gOHMDistributed; // gOHM distributed vai redemptions (18 decimals)

    constructor(
        IERC20[] memory _tokens,
        address[] memory _auxContracts,
        address _chainlinkPriceFeed,
        address _chainlinkIndexFeed,
        uint256 _daiExchangeRate,
        uint256 _daiLaggardExchangeRate,
        uint256 _gohmExchangeRate,
        uint256 _gohmLaggardExchangeRate,
        uint256 _maxDeposits,
        uint256 _tenderDecimals
    ) {
        require(address(_tokens[0]) != address(0), "0x0 tender token");
        require(address(_tokens[1]) != address(0), "0x0 unstaked tender token");
        require(address(_tokens[2]) != address(0), "0x0 DAI");
        require(address(_tokens[3]) != address(0), "0x0 gOHM");
        require(_maxDeposits <= IwsTT(_auxContracts[0]).totalSupply(), "max deposit too big");

        maxDeposits = _maxDeposits;
        tenderToken = _tokens[0];
        unstakedTenderToken = _tokens[1];
        dai = _tokens[2];
        gOHM = _tokens[3];
        wsTenderToken = IwsTT(_auxContracts[0]);
        staking = IStaking(_auxContracts[1]);
        priceFeed = AggregatorV3Interface(_chainlinkPriceFeed);
        indexFeed = AggregatorV3Interface(_chainlinkIndexFeed);
        daiExchangeRate = _daiExchangeRate;
        daiLaggardExchangeRate = _daiLaggardExchangeRate;
        gohmExchangeRate = _gohmExchangeRate;
        gohmLaggardExchangeRate = _gohmLaggardExchangeRate;
        decimalAdjuster = 1e18 / _tenderDecimals; // calculates what value you have to multiply tender token amounts by
    }

    /**
     * @notice deposits tender tokens. Includes the desired redemption currency
     * if the takeover bid succeeds. Locks in the price and index of gOHM at time
     * of deposit.
     * Subsequent deposits can be made, but the must include the same redemption
     * choice as before.
     * Will do the necessary steps to stake and wrap tokens.
     * - Depositing wrapped tokens just transfers
     * - Depositing staked tokens will transfer then wrap
     * - Depositing unstaked tokens will transfer, stake, then wrap
     * @dev tenderToken should be approved for _amount before calling this
     * @param _amount the about of tender tokens to deposit (9 decimals)
     * @param _choice the redemption choice (see: RedemptionChoice)
     * @param _depositToken 0 - unstaked, 1 - staked, 2 - wrapped
     */
    function deposit(uint256 _amount, RedemptionChoice _choice, DepositToken _depositToken) external {
        if (state == State.FAILED) revert InvalidState();
        uint256 wrappedAmount = wsTenderToken.sOHMTowOHM(_amount);
        uint256 depositAmount = _depositToken == DepositToken.WRAPPED ? _amount : wrappedAmount;
        if (totalDeposits + depositAmount > maxDeposits) revert DepositLimit();
        Deposit memory prev = deposits[msg.sender];
        if (prev.amount > 0 && prev.choice != _choice) revert ChoiceChange();

        if (prev.amount > 0) {
            // pushed a new deposit, only update amount
            deposits[msg.sender].amount += depositAmount;
        } else {
            deposits[msg.sender] = Deposit(
                depositAmount,
                getLatestOHMIndex(),
                getLatestOHMPrice(),
                _choice,
                false,
                state == State.PASSED
            );
        }
        totalDeposits += depositAmount;

        if (_depositToken == DepositToken.WRAPPED) {
            wsTenderToken.safeTransferFrom(msg.sender, address(this), _amount);
        } else if (_depositToken == DepositToken.STAKED) {
            tenderToken.safeTransferFrom(msg.sender, address(this), _amount);
            tenderToken.safeApprove(address(wsTenderToken), _amount);
            wsTenderToken.wrap(_amount);
        } else if (_depositToken == DepositToken.UNSTAKED) {
            unstakedTenderToken.safeTransferFrom(msg.sender, address(this), _amount);
            unstakedTenderToken.safeApprove(address(staking), _amount);
            staking.stake(_amount, address(this));
            staking.claim(address(this));
            tenderToken.safeApprove(address(wsTenderToken), _amount);
            wsTenderToken.wrap(_amount);
        }
    }

    /**
     * @notice withdraw all tender tokens after a failed takeover
     */
    function withdraw() external {
        if (state != State.FAILED) revert InvalidState();
        Deposit memory deposit_ = deposits[msg.sender];
        if (deposit_.amount == 0) revert AlreadyWithdrawn();
        deposits[msg.sender].amount  = 0;
        totalDeposits -= deposit_.amount;
        wsTenderToken.safeTransfer(msg.sender, deposit_.amount);
    }

    /**
     * @notice redeems the tender tokens for the depositors chosen currency
     * @dev Since the target token is in 9 decimals
     */
    function redeem() external {
        Deposit memory deposit_ = deposits[msg.sender];
        if (state != State.PASSED) revert InvalidState();
        if (deposit_.didRedeem) revert AlreadyRedeemed();

        totalRedemptions += deposit_.amount;
        uint256 unwrappedAmount = wsTenderToken.wOHMTosOHM(deposit_.amount);

        if (deposit_.choice == RedemptionChoice.DAI) {
            uint256 daiRate = deposit_.isLaggard ? daiLaggardExchangeRate : daiExchangeRate;
            uint256 daiAmount = unwrappedAmount * decimalAdjuster * daiRate / 1e18;
            daiDistributed += daiAmount;
            deposits[msg.sender].didRedeem = true;

            dai.safeTransfer(msg.sender, daiAmount);
        } else if (deposit_.choice == RedemptionChoice.GOHM) {
            uint256 gOHMExchangeRate = getGohmExchangeRate(deposit_.index, deposit_.ohmPrice, deposit_.isLaggard);
            uint256 gOHMAmount = unwrappedAmount * decimalAdjuster * gOHMExchangeRate / 1e18;
            gOHMDistributed += gOHMAmount;
            deposits[msg.sender].didRedeem = true;

            gOHM.safeTransfer(msg.sender, gOHMAmount);
        } else {
            revert BadChoice(); // can this be hit?
        }
    }

    /**
     * @notice set the takeover state to passed. Allows depositors to redeem
     */
    function setPassed() external onlyOwner {
       state = State.PASSED;
    }

    /**
     * @notice set takeover state to failed. Allows depositors to withdraw
     */
    function setFailed() external onlyOwner {
       state = State.FAILED;
    }

    /**
     * @notice set the takeover state back to pending. Useful on testnets
     */
    function setPending() external onlyOwner {
       state = State.PENDING;
    }

    /**
     * @notice allows owner to withdraw arbitratry ERC20 tokens to msg.sender. Must be called
     * by the owner
     * @param _token the token's address
     * @param _amount the amount of `_token` to recover
     */
    function recoverERC20(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    /*******************
     * UTILITIES
     ******************/

     /**
        @notice Gets lates OHM price from Chainlink Oracle
        @return most recent OHM price in 8 decimals from Chainlink
      */
     function getLatestOHMPrice() public view returns (uint256) {
        (,int256 answer,,,) = priceFeed.latestRoundData();
        return uint256(answer);
     }

     /**
        @notice Gets lates OHM index from Chainlink Oracle
        @return most recent OHM index in 9 decimals from Chainlink
      */
     function getLatestOHMIndex() public view returns (uint256) {
        (,int256 answer,,,) = indexFeed.latestRoundData();
        return uint256(answer);
     }

     /**
        @notice Returns what gOHM amount represents the tender offer exchange rate
        @dev 1e17 is to compensate for Chainlink oracle decimals of 9 for _index and 8 for _ohmPrice
      */
     function getGohmExchangeRate(uint256 _index, uint256 _ohmPrice, bool isLaggard) public view returns (uint256) {
        uint256 gohmRate = isLaggard ? gohmLaggardExchangeRate : gohmExchangeRate;
        return (gohmRate * 1e17) / (_index * _ohmPrice);
     }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.10;

interface IStaking {
	function stake(uint256 _amount, address _recipient) external returns(bool);

	function claim(address _recipient) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IwsTT is IERC20 {
	function wrap( uint _amount ) external returns ( uint );

	function wOHMTosOHM(uint256 _amount) external view returns(uint256);

	function sOHMTowOHM(uint256 _amount) external view returns(uint256);
}