/**
 *Submitted for verification at Etherscan.io on 2022-08-15
*/

// SPDX-License-Identifier: GPL-3.0-or-later
// Sources flattened with hardhat v2.6.1 https://hardhat.org

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


// File libraries/UncheckedMath.sol

pragma solidity 0.8.10;

library UncheckedMath {
    function uncheckedInc(uint256 a) internal pure returns (uint256) {
        unchecked {
            return a + 1;
        }
    }

    function uncheckedAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            return a + b;
        }
    }

    function uncheckedSub(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            return a - b;
        }
    }

    function uncheckedDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            return a / b;
        }
    }
}


// File interfaces/access/IGovernanceTimelock.sol

pragma solidity 0.8.10;

interface IGovernanceTimelock {
    struct Call {
        uint64 id;
        uint64 prepared;
        address target;
        bytes4 selector;
        bytes data;
    }

    function prepareCall(
        address target_,
        bytes calldata data_,
        bool validateCall_
    ) external;

    function executeCall(uint64 id_) external;

    function cancelCall(uint64 id_) external;

    function quickExecuteCall(address target_, bytes calldata data_) external;

    function setDelay(
        address target_,
        bytes4 selector_,
        uint64 delay_
    ) external;

    function updateDelay(
        address target_,
        bytes4 selector_,
        uint64 delay_
    ) external;

    function pendingCalls() external view returns (Call[] memory calls);

    function executedCalls() external view returns (Call[] memory calls);

    function cancelledCalls() external view returns (Call[] memory calls);

    function readyCalls() external view returns (Call[] memory calls);

    function notReadyCalls() external view returns (Call[] memory calls);

    function pendingCallIndex(uint64 id_) external view returns (uint256 index);

    function pendingCall(uint64 id_) external view returns (Call memory call);

    function pendingCallDelay(uint64 id_) external view returns (uint64);

    function delays(address target_, bytes4 selector_) external view returns (uint64);
}


// File contracts/access/GovernanceTimelock.sol

pragma solidity 0.8.10;



contract GovernanceTimelock is IGovernanceTimelock, Ownable {
    using UncheckedMath for uint256;
    using Address for address;

    Call[] internal _pendingCalls; // Calls that have not yet been executed or cancelled
    Call[] internal _executedCalls; // Calls that have been executed
    Call[] internal _cancelledCalls; // Calls that have been cancelled

    uint64 public totalCalls; // The total number of calls that have been prepared, executed, or cancelled
    mapping(address => mapping(bytes4 => uint64)) public delays; // The delay for each target and selector

    event CallPrepared(uint64 id); // Emitted when a call is prepared
    event CallExecuted(uint64 id); // Emitted when a call is executed
    event CallCancelled(uint64 id); // Emitted when a call is cancelled
    event CallQuickExecuted(address target, bytes data); // Emitted when a call is executed without a delay
    event DelaySet(address target, bytes4 selector, uint64 delay); // Emitted when a delay is set
    event DelayUpdated(address target, bytes4 selector, uint64 delay); // Emitted when a delay is updated

    modifier onlySelf() {
        require(msg.sender == address(this), "Must be called via timelock");
        _;
    }

    /**
     * @notice Used for validating if a call is valid.
     * @dev Can only be called internally, do not use.
     */
    function testCall(Call memory call_) external {
        require(msg.sender == address(this), "Only callable by this contract");
        _executeCall(call_);
        revert("OK");
    }

    /**
     * @notice Prepares a call for being executed.
     * @param target_ The contract to call.
     * @param data_ The data for the call.
     * @param validateCall_ If the call should be validated (i.e. checks if it will revert when executing).
     */
    function prepareCall(
        address target_,
        bytes calldata data_,
        bool validateCall_
    ) public override onlyOwner {
        Call memory call_ = _createCall(target_, data_);
        if (validateCall_) _validateCallIsExecutable(call_);
        _pendingCalls.push(call_);
        totalCalls++;
        emit CallPrepared(call_.id);
    }

    /**
     * @notice Executes a call.
     * @param id_ The id of the call to execute.
     */
    function executeCall(uint64 id_) public override {
        uint256 index_ = pendingCallIndex(id_);
        Call memory call_ = _pendingCalls[index_];
        require(call_.prepared + _getDelay(call_) <= block.timestamp, "Call not ready");
        _executeCall(call_);
        _removePendingCall(index_);
        _executedCalls.push(call_);
        emit CallExecuted(id_);
    }

    /**
     * @notice Cancels a call.
     * @param id_ The id of the call to cancel.
     */
    function cancelCall(uint64 id_) public override onlyOwner {
        uint256 index_ = pendingCallIndex(id_);
        Call memory call_ = _pendingCalls[index_];
        _removePendingCall(index_);
        _cancelledCalls.push(call_);
        emit CallCancelled(id_);
    }

    /**
     * @notice Executes a call without a delay.
     * @param target_ The contract to call.
     * @param data_ The data for the call.
     */
    function quickExecuteCall(address target_, bytes calldata data_) public override onlyOwner {
        Call memory call_ = _createCall(target_, data_);
        require(_getDelay(call_) == 0, "Call has a delay");
        _executeCall(call_);
        emit CallQuickExecuted(target_, data_);
    }

    /**
     * @notice Sets the delay for a given target and selector.
     * @param target_ The contract to set the delay for.
     * @param selector_ The selector to set the delay for.
     * @param delay_ The delay to set.
     */
    function setDelay(
        address target_,
        bytes4 selector_,
        uint64 delay_
    ) public override onlyOwner {
        require(delays[target_][selector_] == 0, "Delay already set");
        _updateDelay(target_, selector_, delay_);
        emit DelaySet(target_, selector_, delay_);
    }

    /**
     * @notice Updates the delay for a given target and selector.
     * @param target_ The contract to update the delay for.
     * @param selector_ The selector to update the delay for.
     * @param delay_ The delay to update.
     */
    function updateDelay(
        address target_,
        bytes4 selector_,
        uint64 delay_
    ) public override onlySelf {
        require(delays[target_][selector_] != 0, "Delay not already set");
        _updateDelay(target_, selector_, delay_);
        emit DelayUpdated(target_, selector_, delay_);
    }

    /**
     * @notice Returns the list of pending calls.
     * @return calls The list of pending calls.
     */
    function pendingCalls() public view override returns (Call[] memory calls) {
        return _pendingCalls;
    }

    /**
     * @notice Returns the list of executed calls.
     * @return calls The list of executed calls.
     */
    function executedCalls() public view override returns (Call[] memory calls) {
        return _executedCalls;
    }

    /**
     * @notice Returns the list of cancelled calls.
     * @return calls The list of cancelled calls.
     */
    function cancelledCalls() public view override returns (Call[] memory calls) {
        return _cancelledCalls;
    }

    /**
     * @notice Returns the list of ready calls.
     * @dev View is expensive, best to only call for off-chain use.
     * @return calls The list of ready calls.
     */
    function readyCalls() public view override returns (Call[] memory calls) {
        Call[] memory calls_ = new Call[](_pendingCalls.length);
        uint256 readyCount_;
        for (uint256 i = 0; i < _pendingCalls.length; i++) {
            Call memory call_ = _pendingCalls[i];
            if (call_.prepared + _getDelay(call_) <= block.timestamp) {
                calls_[i] = call_;
                readyCount_++;
            }
        }
        return _shortenCalls(calls_, readyCount_);
    }

    /**
     * @notice Returns the list of not-ready calls.
     * @dev View is expensive, best to only call for off-chain use.
     * @return calls The list of not-ready calls.
     */
    function notReadyCalls() public view override returns (Call[] memory calls) {
        Call[] memory calls_ = new Call[](_pendingCalls.length);
        uint256 readyCount_;
        for (uint256 i = 0; i < _pendingCalls.length; i++) {
            Call memory call_ = _pendingCalls[i];
            if (call_.prepared + _getDelay(call_) > block.timestamp) {
                calls_[i] = call_;
                readyCount_++;
            }
        }
        return _shortenCalls(calls_, readyCount_);
    }

    /**
     * @notice Returns the index of a given pending call id.
     * @param id_ The id of the pending call to return the index for.
     * @return index The index of the given pending call id.
     */
    function pendingCallIndex(uint64 id_) public view override returns (uint256 index) {
        for (uint256 i; i < _pendingCalls.length; i = i.uncheckedInc()) {
            if (_pendingCalls[i].id == id_) return i;
        }
        revert("Call not found");
    }

    /**
     * @notice Returns the call of a given pending call id.
     * @param id_ The id of the pending call to return the call for.
     * @return call The call of the given pending call id.
     */
    function pendingCall(uint64 id_) public view override returns (Call memory call) {
        return _pendingCalls[pendingCallIndex(id_)];
    }

    /**
     * @notice Returns the delay of a given pending call id.
     * @param id_ The id of the pending call to return the delay for.
     * @return call The delay of the given pending call id.
     */
    function pendingCallDelay(uint64 id_) public view override returns (uint64) {
        return _getDelay(pendingCall(id_));
    }

    function _validateCallIsExecutable(Call memory call_) internal {
        uint256 size;
        address target_ = call_.target;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(target_)
        }
        if (size == 0) revert("Call would revert when executed: invalid contract");
        try this.testCall(call_) {
            revert("Error validating call");
        } catch Error(string memory msg_) {
            if (keccak256(abi.encodePacked(msg_)) == keccak256(abi.encodePacked("OK"))) return;
            revert(string(abi.encodePacked("Call would revert when executed: ", msg_)));
        }
    }

    function _executeCall(Call memory call_) internal {
        call_.target.functionCall(call_.data);
    }

    function _removePendingCall(uint256 index_) internal {
        _pendingCalls[index_] = _pendingCalls[_pendingCalls.length - 1];
        _pendingCalls.pop();
    }

    function _updateDelay(
        address target_,
        bytes4 selector_,
        uint64 delay_
    ) internal {
        require(target_ != address(0), "Zero address not allowed");
        delays[target_][selector_] = delay_;
    }

    function _createCall(address target_, bytes calldata data_)
        internal
        view
        returns (Call memory)
    {
        require(target_ != address(0), "Zero address not allowed");
        bytes4 selector_ = bytes4(data_[:4]);
        _validatePendingCallIsUnique(target_, selector_);
        Call memory call_ = Call({
            id: totalCalls,
            prepared: uint64(block.timestamp),
            target: target_,
            selector: selector_,
            data: data_
        });
        return call_;
    }

    function _validatePendingCallIsUnique(address target_, bytes4 selector_) internal view {
        if (target_ == address(this)) return;
        for (uint256 i; i < _pendingCalls.length; i = i.uncheckedInc()) {
            if (_pendingCalls[i].target != target_) continue;
            if (_pendingCalls[i].selector != selector_) continue;
            revert("Call already pending");
        }
    }

    function _getDelay(Call memory call_) internal view returns (uint64) {
        address target = call_.target;
        bytes4 selector = call_.selector;

        if (call_.selector == this.updateDelay.selector) {
            bytes memory callData = call_.data;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                target := mload(add(callData, 36)) // skip bytes length and selector
                selector := mload(add(callData, 68)) // skip bytes length, selector, and target
            }
        }

        return delays[target][selector];
    }

    function _shortenCalls(Call[] memory calls_, uint256 length_)
        internal
        pure
        returns (Call[] memory)
    {
        Call[] memory shortened_ = new Call[](length_);
        for (uint256 i; i < length_; i = i.uncheckedInc()) {
            shortened_[i] = calls_[i];
        }
        return shortened_;
    }
}