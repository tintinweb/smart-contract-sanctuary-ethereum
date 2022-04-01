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

pragma solidity 0.8.11;

import "./interfaces/ISpoolOwner.sol";

abstract contract SpoolOwnable {
    ISpoolOwner private immutable spoolOwner;
    
    constructor(ISpoolOwner _spoolOwner) {
        require(
            address(_spoolOwner) != address(0),
            "SpoolOwnable::constructor: Spool owner contract cannot be 0 address"
        );

        spoolOwner = _spoolOwner;
    }

    function isSpoolOwner() internal view returns(bool) {
        return spoolOwner.isSpoolOwner(msg.sender);
    }

    function _onlyOwner() private view {
        require(isSpoolOwner(), "SpoolOwnable::_onlyOwner: Caller is not the Spool owner");
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface ISpoolOwner {
    function isSpoolOwner(address user) external view returns(bool);
}

// SPDX-License-Identifier: MIT

import "../external/@openzeppelin/token/ERC20/IERC20.sol";

pragma solidity 0.8.11;

interface IERC20Mintable is IERC20 {
    function mint(address, uint256) external;

    function burn(address, uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

/* ========== STRUCTS ========== */

/** @notice Vest struct
*   @param amount amount currently vested for user. changes as they claim, or if their vest is transferred to another address
*   @param lastClaim timestamp of the last time the user claimed. is initially set to 0.
*/
struct Vest {
    uint192 amount;
    uint64 lastClaim;
}

/** @notice Member struct
*   @param prev address to transfer vest from
*   @param next address to transfer vest to
*/
struct Member {
    address prev;
    address next;
}

/**
 * @notice {IBaseVesting} interface.
 *
 * @dev See {BaseVesting} for function descriptions.
 *
 */
interface IBaseVesting {
    /* ========== FUNCTIONS ========== */

    function total() external view returns (uint256);

    function begin() external;

    /* ========== EVENTS ========== */

    event VestingInitialized(uint256 duration);

    event Vested(address indexed from, uint256 amount);

    event Transferred(Member indexed members, uint256 amount);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./IBaseVesting.sol";
import "../IERC20Mintable.sol";

/**
 * @notice {ISpoolPreDAOVesting} interface.
 *
 * @dev See {SpoolPreDAOVesting} for function descriptions.
 *
 */
interface ISpoolPreDAOVesting is IBaseVesting {
    function setVests(
        address[] calldata members,
        uint192[] calldata amounts
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "../external/spool-core/SpoolOwnable.sol";
import "../external/@openzeppelin/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/vesting/IBaseVesting.sol";

/**
 * @notice Implementation of the {IBaseVesting} interface.
 *
 * @dev This contract is inherited by the other *Vesting.sol contracts in this folder.
 *      It implements common functions for all of them.
 */
contract BaseVesting is SpoolOwnable, IBaseVesting {
    /* ========== LIBRARIES ========== */

    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    /// @notice the length of time (in seconds) the vesting is to last for.
    uint256 public immutable vestingDuration;

    /// @notice SPOOL token contract address, the token that is being vested.
    IERC20 public immutable spoolToken;

    /// @notice timestamp of vesting start
    uint256 public start;

    /// @notice timestamp of vesting end
    uint256 public end;

    /// @notice total amount of SPOOL token vested
    uint256 public override total;

    /// @notice map of member to Vest struct (see IBaseVesting)
    mapping(address => Vest) public userVest;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @notice sets the contracts initial values
     *
     * @dev 
     *
     *  Requirements:
     *  - _spoolToken must not be the zero address
     *
     * @param spoolOwnable the spool owner contract that owns this contract
     * @param _spoolToken SPOOL token contract address, the token that is being vested.
     * @param _vestingDuration the length of time (in seconds) the vesting is to last for.
     */
    constructor(ISpoolOwner spoolOwnable, IERC20 _spoolToken, uint256 _vestingDuration) SpoolOwnable(spoolOwnable) {
        require(_spoolToken != IERC20(address(0)), "BaseVesting::constructor: Incorrect Token");

        spoolToken = _spoolToken;
        vestingDuration = _vestingDuration;
    }

    /* ========== VIEWS ========== */

    /**
     * @notice Returns the amount a user can claim at a given point in time.
     *
     * @dev
     *
     * Requirements:
     * - the vesting period has started
     */
    function getClaim()
        external
        view
        hasStarted(true)
        returns (uint256 vestedAmount)
    {
        Vest memory vest = userVest[msg.sender];
        return _getClaim(vest.amount, vest.lastClaim);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Allows a user to claim their pending vesting amount.
     *
     * @dev
     *
     * Requirements:
     *
     * - the vesting period has started
     * - the caller must have a non-zero vested amount
     */
    function claim() external hasStarted(true) returns(uint256 vestedAmount) {
        Vest memory vest = userVest[msg.sender];
        vestedAmount = _getClaim(vest.amount, vest.lastClaim);
        require(vestedAmount != 0, "BaseVesting::claim: Nothing to claim");
        _claim(msg.sender, vestedAmount, vest);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * @notice Allows the vesting period to be initiated.
     *
     * @dev  the storage variable "total" contains the total amount of the SPOOL token that is being vested.
     * this is transferred from the SPOOL owner here.
     * 
     * Emits a {VestingInitialized} event from which the start and
     * end can be calculated via it's attached timestamp.
     * 
     * Requirements:
     *
     * - the caller must be the owner
     * - owner has given allowance for "total" to this contract
     */
    function begin() external override onlyOwner hasStarted(false) {
        spoolToken.safeTransferFrom(msg.sender, address(this), total);

        start = block.timestamp;
        end = block.timestamp + vestingDuration;

        emit VestingInitialized(vestingDuration);
    }

    /**
     * @notice Allows owner to transfer all or part of a vest from one address to another
     *
     * @dev It allows for transfer of vest to any other address. However, in the case that the receiving address has any vested
     * amount, it first checks for that, and if so, claims on behalf of that user, sending them any pending vested amount.
     * This has to be done to ensure the vesting is fairly distributed.
     *
     * Emits a {Transferred} event indicating the members who were involved in the transfer
     * as well as the amount that was transferred.
     *
     * Requirements:
     * - the vesting period has started
     * - specified transferAmount is not more than the previous member's vested amount
     * 
     * @param members members list - "prev" for member to transfer from, "next" for member to transfer to
     * @param transferAmount amount of SPOOL token to transfer
     */
    function transferVest(Member calldata members, uint256 transferAmount)
        external
        onlyOwner 
        hasStarted(true)
    {
        uint256 prevAmount = uint256(userVest[members.prev].amount);
        require(transferAmount <= prevAmount && transferAmount > 0, "BaseVesting::transferVest: invalid amount specified for transferring vest");

        /** 
         * NOTE 
         * We check if the member has any pending vest amount. 
         * if so: call claim with their address
         * if not: update lastClaim (otherwise, is done inside _claim)
         */
        Vest memory newVest = userVest[members.next];
        uint vestedAmount = _getClaim(newVest.amount, newVest.lastClaim);
        if(vestedAmount != 0) {
            _claim(members.next, vestedAmount, newVest);            
        } else {
            userVest[members.next].lastClaim = uint64(block.timestamp);
        }

        _transferVest(members, transferAmount);

        emit Transferred(members, transferAmount);  
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @notice Allows a user to claim their pending vesting amount (internal function)
     *
     * @dev Only accessible via the external "claim" function (in which case, msg.sender is used) or the transferVest function,
     * which is only callable by the SPOOL owner
     *
     * Emits a {Vested} event indicating the user who claimed their vested tokens
     * as well as the amount that was vested.
     *
     * @param member address to claim for
     * @param vestedAmount amount to claim
     * @param vest vesting info for "member"
     */
    function _claim(address member, uint256 vestedAmount, Vest memory vest) internal {

        _claimVest(member, vestedAmount, vest);

        emit Vested(member, vestedAmount);

        spoolToken.safeTransfer(member, vestedAmount);

    }

    /**
     * @notice allows owner to set the vesting members and amounts (internal function)
     *
     * @dev Only accessible via the external setVests function located in the inheriting vesting contract.
     *
     * Requirements:
     *
     * - vesting must not already have started
     * - input member and amount arrays must be the same size
     * - values in amounts array must be greater than 0
     *
     * @param members array of addresses to set vesting for
     * @param amounts array of SPOOL token vesting amounts to to be set for each address
     */
    function _setVests(address[] memory members, uint192[] memory amounts)
        internal
        hasStarted(false)
    {
        require(
            members.length == amounts.length,
            "BaseVesting::_setVests: Incorrect Arguments"
        );

        for(uint i = 0; i < members.length; i++){
            for(uint j = (i+1); j < members.length; j++) {
                require(members[i] != members[j], "BaseVesting::_setVests: Members Not Unique");
            }
        }

        int192 totalDiff;
        for (uint i = 0; i < members.length; i++) {
            totalDiff += _setVest(members[i], amounts[i]);
        }

        // if the difference from the previous totals for these members is less than zero, subtract from total.
        if(totalDiff < 0) {
            total -= abs(totalDiff);
        } else {
            total += abs(totalDiff);
        }
    }

    /**
     * @notice allows owner to set the vesting amount for a member (internal function)
     *
     * @dev Only accessible via the internal _setVests function.
     * This is a virtual function, it can be overriden by the inheriting vesting contracts.
     *
     * Requirements:
     *
     * - amount must be less than uint192 max (the maximum value that can be stored for amount)
     *
     * @param user the user to set vesting for
     * @param amount the SPOOL token vesting amount to be set for this user
     *
     */
    function _setVest(address user, uint192 amount)
        internal
        virtual
        returns (int192 diff)
    {
        diff = int192(amount) - int192(userVest[user].amount);
        userVest[user].amount = amount;
    }

    /**
     * @notice Allows a user to claim their pending vesting amount (internal, virtual function)
     *
     * @dev Only accessible via the internal _claimVest function.
     * This is a virtual function, it can be overriden by the inheriting vesting contracts.
     *
     * @param member address to claim for
     * @param vestedAmount amount to claim
     * @param vest vesting info for "member"
     */
    function _claimVest(address member, uint256 vestedAmount, Vest memory vest)
        internal
        virtual
    {
        vest.amount -= uint192(vestedAmount);
        vest.lastClaim = uint64(block.timestamp);

        userVest[member] = vest;
    }

    /**
     * @notice Allows owner to transfer all or part of a vest from one address to another (internal, virtual function)
     *
     * @dev Only accessible via the transferVest function.
     * This is a virtual function, it can be overriden by the inheriting vesting contracts.
     *
     * @param members members list - "prev" for member to transfer from, "next" for member to transfer to
     * @param transferAmount amount of SPOOL token to transfer
     */
    function _transferVest(Member memory members, uint256 transferAmount) 
        internal 
        virtual
    {
        userVest[members.prev].amount -= uint192(transferAmount);
        userVest[members.next].amount += uint192(transferAmount); 
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    /**
     * @notice Calculates the amount a user's vest is due. 
     * 
     * @dev
     * To calculate, the following formula is utilized:
     *
     * - (remainingAmount * timeElapsed) / timeUntilEnd
     *
     * Each variable is described as follows:
     *
     * - remainingAmount (amount): Vesting amount remaining. Each claim subtracts from
     * this amount to ensure calculations are properly conducted.
     *
     * - timeElapsed (block.timestamp.sub(lastClaim)): Time that has elapsed since the
     * last claim.
     *
     * - timeUntilEnd (end.sub(lastClaim)): Time remaining for the particular vesting
     * member's total duration.
     *
     * Vesting calculations are relative and always update the last
     * claim timestamp as well as remaining amount whenever they
     * are claimed.
     * 
     * @param amount SPOOL token amount to claim
     * @param lastClaim timestamp of the last time the user claimed
     */
    function _getClaim(uint256 amount, uint256 lastClaim)
        private
        view
        returns (uint256)
    {
        uint256 _end = end;

        if (block.timestamp >= _end) return amount;
        if (lastClaim == 0) lastClaim = start;

        return (amount * (block.timestamp - lastClaim)) / (_end - lastClaim);
    }

    /** @notice check if the vesting has or has not started
     * 
     * @dev uses the "start" storage variable to check if the vesting has started or not (ie. if begin() has been successfully called)
     *
     * @param check boolean to validate if the vesting has or has not started
     */
    function _checkStarted(bool check) private view {                                  
        require(
            check ? start != 0 
                   : start == 0,
            check ? "BaseVesting::_checkStarted: Vesting hasn't started yet" 
                   : "BaseVesting::_checkStarted: Vesting has already started"
        );
    }

    /* ========== HELPERS ========== */
    
    /** 
     * @notice get absolute value of an int192 value
     *
     * @param a signed integer to get absolute value of
     *
     * @return absolute value of input
     */
    function abs(int192 a) internal pure returns (uint192) {
        return uint192(a < 0 ? -a : a);
    }

    /* ========== MODIFIERS ========== */

    /**
     * @notice hasStarted modifier
     *
     * @dev 
     * 
     * calls _checkStarted private function and continues execution
     *
     * @param check boolean to validate if the vesting has or has not started
     */
    modifier hasStarted(bool check) {
        _checkStarted(check);
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./BaseVesting.sol";

import "../interfaces/vesting/ISpoolPreDAOVesting.sol";

/**
 * @notice Implementation of the {ISpoolPreDAOVesting} interface.
 *
 * @dev This contract inherits BaseVesting, this is where most of the functionality is located.
 *      It overrides some functions where necessary.
 */
contract SpoolPreDAOVesting is BaseVesting, ISpoolPreDAOVesting {
    IERC20Mintable public immutable voSPOOL;

    /**
     * @notice sets the contracts initial values
     *
     * @param spoolOwnable the spool owner contract that owns this contract
     * @param _voSPOOL Voting SPOOL token contract
     * @param _spool SPOOL token contract address, the token that is being vested.
     * @param _vestingDuration the length of time (in seconds) the vesting is to last for.
     */
    constructor(ISpoolOwner spoolOwnable, IERC20Mintable _voSPOOL, IERC20 _spool, uint256 _vestingDuration)        
        BaseVesting(spoolOwnable, _spool, _vestingDuration)
    {
        voSPOOL = _voSPOOL;
    }

    /**
     * @notice Allows vests to be set. 
     *
     * @dev
     * internally calls _setVests function on BaseVesting.                        
     *                                                                            
     * Can be called an arbitrary number of times before `begin()` is called 
     * on the base contract.                                               
     * 
     * Requirements:
     *
     * - the caller must be the owner
     *
     * @param members array of addresses to set vesting for
     * @param amounts array of SPOOL token vesting amounts to to be set for each address
     */
    function setVests(
        address[] calldata members,
        uint192[] calldata amounts
    ) external onlyOwner {

        _setVests(members, amounts);
    }

    /**
     * @notice allows owner to set the vesting amount for a member (internal, override function)
     *
     * @dev overrides BaseVesting _setVest function. mints "amount" voting SPOOL tokens to user 
     * before calling _setVest in BaseVesting.
     *
     * If user has a previous vest amount set, we need to burn that amount of voSPOOL also. Then 
     * the current vest amount is minted in voSPOOL.
     *
     * @param user the user to set vesting for
     * @param amount the SPOOL token vesting amount to be set for this user
     *
     */
    function _setVest(address user, uint192 amount)
        internal
        override
        returns (int192)
    {
        uint192 previousAmount = userVest[user].amount;
        if(previousAmount > 0) 
        { 
            voSPOOL.burn(user, previousAmount);
        }
        voSPOOL.mint(user, amount);
        return BaseVesting._setVest(user, amount);
    }

    /**
     * @notice Allows a user to claim their pending vesting amount (internal, override function)
     *
     * @dev overrides BaseVesting _claimVest function. burns "amount" voting SPOOL tokens from user 
     * before calling _claimVest in BaseVesting.
     *
     * @param member address to claim for
     * @param vestedAmount amount to claim
     * @param vest vesting info for "member"
     */
    function _claimVest(address member, uint256 vestedAmount, Vest memory vest)
        internal
        override
    {
        voSPOOL.burn(member, vestedAmount);
        BaseVesting._claimVest(member, vestedAmount, vest);
    }

    /**
     * @notice Allows owner to transfer all or part of a vest from one address to another (internal, override function)
     *
     * @dev 
     * overrides BaseVesting _transferVest function. burns "transferAmount" voting SPOOL tokens from previous user, 
     * mints same amount to next user, and calls  _transferVest in BaseVesting.
     *
     * @param members members list - "prev" for member to transfer from, "next" for member to transfer to
     * @param transferAmount amount of SPOOL token to transfer
     */
    function _transferVest(Member memory members, uint256 transferAmount) 
        internal 
        override
    {
        voSPOOL.burn(members.prev, transferAmount);
        voSPOOL.mint(members.next, transferAmount);
        BaseVesting._transferVest(members, transferAmount);
    }
}