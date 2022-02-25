/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

// Sources flattened with hardhat v2.8.2 https://hardhat.org

// File @openzeppelin/contracts/security/Reentrancy[email protected]

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

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


// File contracts/Payments.sol

pragma solidity ^0.8.7;



contract Payments is ReentrancyGuard {
    event TimelockedPaymentCreated(
        uint _paymentId,
        address _from,
        address _to,
        uint _value,
        uint64 time,
        bool _isToken
    );
    event TimeLockedWithdraw(uint _paymentId, address _to, uint _value, bool _isToken);

    event MultiSigPaymentCreated(
        uint _paymentId,
        address _from,
        address _to,
        uint _numApprovalsRequired,
        address[] approvers,
        uint _value,
        bool _isToken
    );
    event MultiSigApproved(uint _paymentId, address _approver);
    event MultiSigExecuted(uint _paymentId, address _to, uint _value);

    event StreamPaymentCreated(
        uint _paymentId,
        address _from,
        address _to,
        uint _value,
        uint64 start,
        uint64 duration,
        bool _isToken
    );
    event VestedWithdraw(uint _paymentId, address _to, uint _value, bool _isToken);

    IERC20 public _token;

    uint private _paymentId;
    uint private _multiSigPaymentId;
    uint private _streamPaymentId;

    struct TimeLockedPayment {
        uint amount;
        uint64 time;
        address beneficiary;
        bool paid;
        bool isToken;
    }

    struct MultiSigPayment {
        uint amount;
        uint numApprovalsRequired;
        uint numApprovals;
        address beneficiary;
        address[] approvers;
        bool executed;
        bool isToken;
    }

    struct StreamPayment {
        uint amount;
        uint released;
        uint64 start;
        uint64 duration;
        address beneficiary;
        bool isToken;
    }

    mapping(uint => TimeLockedPayment) private _timelockedPayments;

    mapping(uint => MultiSigPayment) private _multiSigPayments;
    mapping(uint => mapping(address => bool)) private _isApprover;
    mapping(uint => mapping(address => bool)) private _isApproved;

    mapping(uint => StreamPayment) private _streamPayments;

    modifier noZeroAddress(address add) {
        require(add != address(0), "Invalid address");
        _;
    }

    modifier paymentExists(uint id, uint maxProductId) {
        require(id < maxProductId, "Payment does not exist");
        _;
    }

    modifier approved(uint id) {
        require(
            _multiSigPayments[id].numApprovalsRequired <= _multiSigPayments[id].numApprovals,
            "Not enough confirmations"
        );
        _;
    }

    modifier canWithdrawTimelocked(uint id) {
        require(_timelockedPayments[id].paid == false, "Already withdrawn");
        require(_timelockedPayments[id].beneficiary == msg.sender, "Action not allowed");
        require(_timelockedPayments[id].time < block.timestamp, "Time has not passed");
        _;
    }

    modifier futureTime(uint time) {
        require(time > block.timestamp, "Time has already passed");
        _;
    }

    constructor(IERC20 token) {
        _token = token;
    }

    function createTimelockedPayment(address beneficiary, uint64 time) public payable {
        _createTimelockedPayment(beneficiary, time, msg.value, false);
    }

    function createTimelockedPaymentToken(address beneficiary, uint64 time, uint amount) public {
        _createTimelockedPayment(beneficiary, time, amount, true);
    }

    function withdrawTimePayment(uint id) external
        nonReentrant paymentExists(id, _paymentId) canWithdrawTimelocked(id) {
        _timelockedPayments[id].paid = true;

        if (_timelockedPayments[id].isToken) {
            _token.transfer(msg.sender, _timelockedPayments[id].amount);
        }
        else {
            Address.sendValue(payable(msg.sender), _timelockedPayments[id].amount);
        }

        emit TimeLockedWithdraw(id, msg.sender, _timelockedPayments[id].amount, _timelockedPayments[id].isToken);
    }

    function createMultiSigPayment(
        address beneficiary,
        uint numApprovalsRequired,
        address[] memory approvers
    ) public payable noZeroAddress(beneficiary) {
        _createMultiSigPayment(
            beneficiary,
            numApprovalsRequired,
            approvers,
            msg.value,
            false
        );
    }

    function createMultiSigPaymentToken(
        address beneficiary,
        uint numApprovalsRequired,
        address[] memory approvers,
        uint amount
    ) public noZeroAddress(beneficiary) {
        _createMultiSigPayment(
            beneficiary,
            numApprovalsRequired,
            approvers,
            amount,
            true
        );
    }

    function approve(uint id) public paymentExists(id, _multiSigPaymentId) {
        require(_isApprover[id][msg.sender], "Not an approver");
        require(!_isApproved[id][msg.sender], "Already approved");

        _multiSigPayments[id].numApprovals++;
        emit MultiSigApproved(id, msg.sender);
    }

    function executeMultiSigPayment(uint id) external
        paymentExists(id, _multiSigPaymentId)
        approved(id)
        nonReentrant {
        require(_multiSigPayments[id].beneficiary == msg.sender, "Action not allowed");
        require(_multiSigPayments[id].executed == false, "Already executed");

        _multiSigPayments[id].executed = true;

        if (_multiSigPayments[id].isToken) {
            _token.transfer(msg.sender, _multiSigPayments[id].amount);
        }
        else {
            Address.sendValue(payable(msg.sender), _multiSigPayments[id].amount);
        }

        emit MultiSigExecuted(id, msg.sender, _multiSigPayments[id].amount);
    }

    function createStreamPayment(address beneficiary, uint64 start, uint64 duration) public payable {
        _createStreamPayment(beneficiary, start, duration, msg.value, false);
    }

    function createStreamPaymentToken(address beneficiary, uint64 start, uint64 duration, uint amount) public {
        _createStreamPayment(beneficiary, start, duration, amount, true);
    }

    function withdrawVested(uint id) external nonReentrant paymentExists(id, _streamPaymentId) {
        require(_streamPayments[id].beneficiary == msg.sender, "Action not allowed");
        require(_streamPayments[id].start > block.timestamp, "Vesting has not started, yet");

        uint amountForPeriod = _vestingSchedule(uint64(block.timestamp), _streamPayments[id]);
        uint releasable = amountForPeriod - _streamPayments[id].released;
        _streamPayments[id].released += releasable;

        if (_streamPayments[id].isToken) {
            _token.transfer(msg.sender, releasable);
        }
        else {
            Address.sendValue(payable(msg.sender), releasable);
        }

        emit VestedWithdraw(id, msg.sender, releasable, _streamPayments[id].isToken);
    }

    function _vestingSchedule(
        uint64 timestamp,
        StreamPayment memory payment
    ) internal view virtual returns (uint) {
        if (timestamp < payment.start) {
            return 0;
        } else if (timestamp > payment.start + payment.duration) {
            return payment.amount;
        } else {
            return (payment.amount * (timestamp - payment.start)) / payment.duration;
        }
    }

    function _createTimelockedPayment(address beneficiary, uint64 time, uint amount, bool isToken)
        private noZeroAddress(beneficiary) futureTime(time) {
        _timelockedPayments[_paymentId] = TimeLockedPayment(amount, time, beneficiary, false, isToken);

        if (isToken) {
            _token.transferFrom(msg.sender, address(this), amount);
        }

        emit TimelockedPaymentCreated(_paymentId, msg.sender, beneficiary, amount, time, isToken);

        _paymentId++;
    }

    function _createMultiSigPayment(
        address beneficiary,
        uint numApprovalsRequired,
        address[] memory approvers,
        uint amount,
        bool isToken
    ) private {
        for (uint i = 0; i < approvers.length; i++) {
            address approver = approvers[i];

            require(approver != address(0), "invalid approver");
            require(!_isApprover[_multiSigPaymentId][approver], "approver not unique");

            _isApprover[_multiSigPaymentId][approver] = true;
        }

        _multiSigPayments[_multiSigPaymentId] = MultiSigPayment({
            amount: amount,
            numApprovalsRequired: numApprovalsRequired,
            numApprovals: 0,
            beneficiary: beneficiary,
            approvers: approvers,
            executed: false,
            isToken: isToken
        });

        if (isToken) {
            _token.transferFrom(msg.sender, address(this), amount);
        }

        emit MultiSigPaymentCreated(
            _multiSigPaymentId,
            msg.sender,
            beneficiary,
            numApprovalsRequired,
            approvers,
            amount,
            isToken
        );

        _multiSigPaymentId++;
    }

    function _createStreamPayment(address beneficiary, uint64 start, uint64 duration, uint amount, bool isToken)
        private noZeroAddress(beneficiary) futureTime(start) {
        _streamPayments[_streamPaymentId] = StreamPayment(amount, 0, start, duration, beneficiary, isToken);

        if (isToken) {
            _token.transferFrom(msg.sender, address(this), amount);
        }

        emit StreamPaymentCreated(
            _streamPaymentId,
            msg.sender,
            beneficiary,
            amount,
            start,
            duration,
            isToken
        );

        _streamPaymentId++;
    }
}