/**
 *Submitted for verification at Etherscan.io on 2022-05-10
*/

/**
 *Submitted for verification at polygonscan.com on 2022-04-22
*/

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;


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


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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


// File contracts/LenderPool/interface/ILenderPool.sol

pragma solidity ^0.8.12;

interface ILenderPool {
    struct Lender {
        uint16 round;
        uint40 startPeriod;
        uint pendingRewards;
        uint deposit;
    }

    struct RoundInfo {
        uint16 apy;
        uint40 startTime;
        uint40 endTime;
    }

    /**
     * @notice Emits when new fund is added to the Lender Pool
     * @dev Emitted when funds are deposited by the `lender`.
     * @param lender, address of the lender
     * @param amount, stable token deposited by the lender
     */
    event Deposit(address indexed lender, uint amount);

    /**
     * @notice Emits when fund is withdrawn by the lender
     * @dev Emitted when tStable token are withdrawn by the `lender`.
     * @param lender, address of the lender
     * @param amount, tStable token withdrawn by the lender
     */
    event Withdraw(address indexed lender, uint amount);

    /**
     * @notice Emits when new rewardAPY is set
     * @dev Emitted when new rewardAPY is set by the owner
     * @param rewardAPY, new value of rewardAPY
     */
    event NewRewardAPY(uint16 rewardAPY);

    /**
     * @notice Deposit stable token to smart contract
     * @dev Transfers the approved stable token from msg.sender to lender pool
     * @param amount, the number of stable token to be deposited
     *
     * Requirements:
     *
     * - `amount` should be greater than zero
     * - `amount` must be approved from the stable token contract for the LenderPool contract
     *
     * Emits {Deposit} event
     */
    function deposit(uint amount) external;

    /**
     * @notice converts all the deposited stable token into tStable token and transfers to the lender
     * @dev calculates the tStable token lender can claim and transfers it to the lender
     */
    function withdrawAllTStable() external;

    /**
     * @notice converts the given amount of stable token into tStable token and transfers to lender
     * @dev checks the required condition and converts stable token to tStable and transfers to lender
     * @param amount, total amount of stable token to be converted to tStable token
     */
    function withdrawTStable(uint amount) external;

    /**
     * @notice send lender all the reward
     * @dev update the pendingReward and mint tStable token and send to lender
     *
     * Emits {Withdraw} event
     */
    function claimRewards() external;

    /**
     * @notice adds a new round
     * @dev increment currentRound and adds a new round, only owner can call
     * @param _rewardAPY, new value of new round.apy
     *
     * Emits {NewRewardAPY} event
     */
    function setAPY(uint16 _rewardAPY) external;

    /**
     * @notice exchanges tStable token for the stable token
     * @dev calls toStable function from RedeemPool smart contract
     * @param amount, the number of tokens to be exchanged
     */
    function convertToStable(uint amount) external;

    /**
     * @notice returns value of APY of current round
     * @return returns value of APY of current round
     */
    function getAPY() external view returns (uint16);

    /**
     * @notice returns amount of stable token deposited by the lender
     * @param lender, address of lender
     * @return returns amount of stable token deposited by the lender
     */
    function getDeposit(address lender) external view returns (uint);
}


// File contracts/Token/interface/IToken.sol

pragma solidity ^0.8.12;

/**
 * @author Polytrade
 * @title Token
 */
interface IToken is IERC20 {
    /**
     * @notice mints ERC20 token
     * @dev creates `amount` tokens and assigns them to `to`, increasing the total supply.
     * @param to, receiver address of the ERC20 address
     * @param amount, amount of ERC20 token minted
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function mint(address to, uint amount) external;

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint amount) external;
}


// File contracts/RedeemPool/interface/IRedeemPool.sol

pragma solidity ^0.8.12;

interface IRedeemPool {
    /**
     * @notice Emits when tStable token is exchanged for stable token
     * @param amount, the number of tokens exchanged
     */
    event StableWithdrawn(uint amount);

    /**
     * @notice Emits when stable token is added to the Redeem Pool
     * @param amount, the number of stable token deposited
     */
    event StableDeposited(uint amount);

    /**
     * @notice Deposit stable token to smart contract
     * @dev Transfers the approved stable token from msg.sender to Redeem Pool
     * @param amount, the number of stable token deposited
     *
     * Requirements:
     *
     * - `amount` should be greater than zero
     * - `amount` must be approved from the stable token contract for the RedeemPool contract
     *
     * Emits {StableDeposited} event
     */
    function depositStable(uint amount) external;

    /**
     * @notice exchange tStable token for the stable token
     * @dev users can directly call this function using EOA
     * @param amount, the number of tokens to be exchanged
     */
    function convertToStable(uint amount) external;

    /**
     * @notice exchange tStable token for the stable token
     * @dev this function can be called using another smart contract
     * @param amount, the number of tokens to be exchanged
     */
    function toStable(uint amount, address account) external;
}


// File contracts/LenderPool/LenderPool.sol

pragma solidity ^0.8.12;





/**
 * @author Polytrade
 * @title LenderPool V2
 */
contract LenderPool is ILenderPool, Ownable {
    using SafeERC20 for IToken;

    mapping(address => Lender) private _lender;
    mapping(uint16 => RoundInfo) public round;

    IToken public immutable stable;
    IToken public immutable tStable;
    IRedeemPool public immutable redeemPool;

    uint16 public currentRound = 0;

    constructor(
        address _stableAddress,
        address _tStableAddress,
        address _redeemPool
    ) {
        stable = IToken(_stableAddress);
        tStable = IToken(_tStableAddress);
        redeemPool = IRedeemPool(_redeemPool);
    }

    /**
     * @notice Deposit stable token to smart contract
     * @dev Transfers the approved stable token from msg.sender to lender pool
     * @param amount, the number of stable token to be deposited
     *
     * Requirements:
     *
     * - `amount` should be greater than zero
     * - `amount` must be approved from the stable token contract for the LenderPool contract
     *
     * Emits {Deposit} event
     */
    function deposit(uint amount) external {
        require(amount > 0, "Lending amount is 0");
        uint allowance = stable.allowance(msg.sender, address(this));
        require(allowance >= amount, "Not enough allowance");
        if (_lender[msg.sender].startPeriod > 0) {
            _updatePendingReward(msg.sender);
        } else {
            _lender[msg.sender].startPeriod = uint40(block.timestamp);
        }
        _lender[msg.sender].deposit += amount;
        _lender[msg.sender].round = currentRound;
        emit Deposit(msg.sender, amount);
        stable.safeTransferFrom(msg.sender, address(this), amount);
    }

    /**
     * @notice converts all the deposited stable token into tStable token and transfers to the lender
     * @dev calculates the tStable token lender can claim and transfers it to the lender
     */
    function withdrawAllTStable() external {
        _withdraw(_lender[msg.sender].deposit);
    }

    /**
     * @notice converts the given amount of stable token into tStable token and transfers to lender
     * @dev checks the required condition and converts stable token to tStable and transfers to lender
     * @param amount, total amount of stable token to be converted to tStable token
     */
    function withdrawTStable(uint amount) external {
        _withdraw(amount);
    }

    /**
     * @notice send lender all the reward
     * @dev update the pendingReward and mint tStable token and send to lender
     *
     * Emits {Withdraw} event
     */
    function claimRewards() external {
        _updatePendingReward(msg.sender);
        uint totalReward = _lender[msg.sender].pendingRewards;
        _lender[msg.sender].pendingRewards = 0;
        emit Withdraw(msg.sender, totalReward);
        tStable.mint(msg.sender, totalReward);
    }

    /**
     * @notice adds a new round
     * @dev increment currentRound and adds a new round, only owner can call
     * @param _rewardAPY, new value of new round.apy
     *
     * Emits {NewRewardAPY} event
     */
    function setAPY(uint16 _rewardAPY) external onlyOwner {
        if (currentRound > 0) {
            round[currentRound].endTime = uint40(block.timestamp);
        }
        currentRound += 1;
        round[currentRound] = RoundInfo(
            _rewardAPY,
            uint40(block.timestamp),
            type(uint40).max
        );
        emit NewRewardAPY(round[currentRound].apy);
    }

    /**
     * @notice exchanges tStable token for the stable token
     * @dev calls toStable function from RedeemPool smart contract
     * @param amount, the number of tokens to be exchanged
     */
    function convertToStable(uint amount) external {
        redeemPool.toStable(amount, msg.sender);
    }

    /**
     * @notice returns value of APY of current round
     * @return returns value of APY of current round
     */
    function getAPY() external view returns (uint16) {
        return round[currentRound].apy;
    }

    /**
     * @notice returns amount of stable token deposited by the lender
     * @param lender, address of lender
     * @return returns amount of stable token deposited by the lender
     */
    function getDeposit(address lender) external view returns (uint) {
        return _lender[lender].deposit;
    }

    /**
     * @notice returns the total pending reward
     * @dev returns the total pending reward of msg.sender
     * @return returns the total pending reward
     */
    function rewardOf(address lender) external view returns (uint) {
        if (_lender[lender].round < currentRound) {
            return
                _lender[lender].pendingRewards +
                _calculateFromPreviousRounds(lender);
        } else {
            return
                _lender[lender].pendingRewards + _calculateCurrentRound(lender);
        }
    }

    /**
     * @notice converts the deposited stable token of quantity `amount` into tStable token and send to the lender
     * @param amount, to be sent to the msg.sender
     *
     * Requirements:
     *
     * - deposited amount must be greater than amount requested
     * - `amount` should be greater than zero
     *
     * Emits {Withdraw} event
     */
    function _withdraw(uint amount) private {
        require(amount > 0, "Cannot withdraw 0 amount");
        require(
            _lender[msg.sender].deposit >= amount,
            "Invalid amount requested"
        );
        if (currentRound > 0) {
            _updatePendingReward(msg.sender);
        }
        _lender[msg.sender].deposit -= amount;
        emit Withdraw(msg.sender, amount);
        tStable.mint(msg.sender, amount);
    }

    /**
     * @notice updates round, pendingRewards and startTime of the lender
     * @dev compares the lender round with currentRound and updates _lender accordingly
     * @param lender, address of the lender
     */
    function _updatePendingReward(address lender) private {
        if (_lender[lender].round == currentRound) {
            _lender[lender].pendingRewards += _calculateCurrentRound(lender);
        }

        if (_lender[lender].round < currentRound) {
            _lender[lender].pendingRewards += _calculateFromPreviousRounds(
                lender
            );
            _lender[lender].round = currentRound;
        }
        _lender[lender].startPeriod = uint40(block.timestamp);
    }

    /**
     * @notice return the total reward when lender round is equal to currentRound
     * @param lender, address of the lender
     * @return returns total pending reward
     */
    function _calculateCurrentRound(address lender)
        private
        view
        returns (uint)
    {
        uint reward = _calculateReward(
            _lender[lender].deposit,
            _max(_lender[lender].startPeriod, round[currentRound].startTime),
            _min(uint40(block.timestamp), round[currentRound].endTime),
            round[currentRound].apy
        );
        return reward;
    }

    /**
     * @notice return the total reward when lender round is less than currentRound
     * @param lender, address of the lender
     * @return returns total pending reward
     */
    function _calculateFromPreviousRounds(address lender)
        private
        view
        returns (uint)
    {
        uint reward = 0;
        for (uint16 i = _lender[lender].round; i <= currentRound; i++) {
            if (i == 0) {
                continue;
            }

            reward += _calculateReward(
                _lender[lender].deposit,
                _max(_lender[lender].startPeriod, round[i].startTime),
                _min(uint40(block.timestamp), round[i].endTime),
                round[i].apy
            );
        }
        return reward;
    }

    /**
     * @notice calculates the reward
     * @dev calculates the reward using simple interest formula
     * @param amount, principal amount
     * @param start, start of the tenure for reward
     * @param end, end of the tenure for reward
     * @param apy, Annual percentage yield received during the tenure
     * @return returns reward
     */
    function _calculateReward(
        uint amount,
        uint40 start,
        uint40 end,
        uint16 apy
    ) private pure returns (uint) {
        uint oneYear = (10000 * 365 days);
        return (((end - start) * apy * amount) / oneYear);
    }

    /**
     * @notice returns maximum among two uint40 variables
     * @dev compares two uint40 variables a and b and return maximum between them
     * @param a, value of uint40 variable
     * @param b, value of uint40 variable
     * @return returns maximum between a and b
     */
    function _max(uint40 a, uint40 b) private pure returns (uint40) {
        return a > b ? a : b;
    }

    /**
     * @notice returns minimum among two uint40 variables
     * @dev compares two uint40 variables a and b and return minimum between them
     * @param a, value of uint40 variable
     * @param b, value of uint40 variable
     * @return returns minimum between a and b
     */
    function _min(uint40 a, uint40 b) private pure returns (uint40) {
        return a > b ? b : a;
    }
}